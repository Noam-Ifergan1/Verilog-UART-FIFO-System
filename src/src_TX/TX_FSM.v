module TX_FSM ( //הגדרת מודול יחידת בקרה
input wire clk, //הגדרת אות שעון
input wire tx_clr, //הגדרת אות איפוס
input wire fifo_full, //מלא וצריך לעצור FIFOכניסה שאומרת האם ה
input wire [1:0] adrs, //כניסה שאומרת באיזה מילה אנו נמצאים כרגע
output wire rd, //אות יציאה לקריאה מהזיכרון
output wire ld, //אות יציאה לטעינה לאוגר
output wire shr, //אות שליטה להזזה ימינה באוגר
output wire inc, //אות שליטה למונה הכתובות לקדם באחד
output wire wr_enable, //FIFO-אות פקודה חדש לכתיבה לתוך ה
output wire tx_finish //אות סיום שידור כל ארבעת המילים
);

//Moore הגדרת שמות למצבים השונים במכונת 
localparam ST_IDLE      = 3'b000; //מצב אפס: המתנה
localparam ST_READ_ROM  = 3'b001; //מצב אחד: קריאה מהזיכרון
localparam ST_LOAD_TBUF = 3'b010; //מצב שתיים: טעינה לרגיסטר הזזה
localparam ST_SEND_BITS = 3'b011; //FIFO-מצב שלוש : שליחת ביטים הזזה וכתיבה ל
localparam ST_NEXT_WORD = 3'b100; //מצב ארבע: התקדמות למילה הבאה
localparam ST_DONE      = 3'b101; //מצב חמש: סיום כל המילים

//משתנים ששומרים את המצב הנוכחי ואת המצב הבא
reg [2:0] current_state;
reg [2:0] next_state;

//מונה ספירה מאפס עד שבע שנדע מתי שידרנו 8 ביטים שלמים
reg [2:0] bit_cnt;   

//בלוק 1: המעבר הפיזי בין המצבים
always @(posedge clk) begin //בכל עליית שעון או איפוס 
    if (tx_clr) begin //אם יש איפוס אז
        current_state <= ST_IDLE; //חוזרים למצב המתנה
        bit_cnt       <= 3'd0; //מאפסים את מונה הביטים ל0
    end //סיום תנאי
    else begin //אם אין איפוס אז עובדים לפי שעון
        current_state <= next_state; //מחליפים את המצב הנוכחי במצב הבא שחושב
        
        //לא מלא אז FIFOאם נמצאים במצב שידור ביטים וגם ה
        if (current_state == ST_SEND_BITS && !fifo_full) begin 
            bit_cnt <= bit_cnt + 1'b1; //נוסיף אחד למונה בכל פעימה
        end //סיום תנאי
        else if (current_state != ST_SEND_BITS) begin //אם לא במצב שידור אז
            bit_cnt <= 3'd0; //מאפסים את המונה
        end //סיום תנאי
    end //סיום תנאי
end //סיום הבלוק

//בלוק 2: קביעת המצב הבא בלי תלות בשעון
always @(*) begin //הוראה לביצוע בכל פעם שהמשתנים בפנים משתנים
    case (current_state) //בדיקה באיזה תחנה נמצאים
        
        ST_IDLE: begin //אם במצב המתנה אז
            next_state = ST_READ_ROM; //התחלת עבודה אוטמוטית כי לא תלוי במקלט
        end //סיום תנאי	
        
        ST_READ_ROM: begin //אם נמצאים במצב קריאה מהזיכרון אז
            next_state = ST_LOAD_TBUF; //במחזור הבא נעבור לטעינת האוגר
        end //סיום תנאי	
        
        ST_LOAD_TBUF: begin //אם נמצאים במצב טעינה לאוגר אז
            next_state = ST_SEND_BITS; //במחזור הבא נתחיל לשדר את הביטים
        end //סיום תנאי	
        
        ST_SEND_BITS: begin //אם נמצאים במצב שידור ביטים אז
            if (!fifo_full) begin //פנוי FIFOבדיקה אם ה
                if (bit_cnt == 3'd7) next_state = ST_NEXT_WORD; //בדיקה אם סיים לשדר 8 ביטים - אם כן למילה הבאה
                else                 next_state = ST_SEND_BITS; //אם לא סיים לשדר 8 ביטים - ימשיך לשדר
            end //סיום תנאי
            else begin //מלא FIFOאם ה
                next_state = ST_SEND_BITS; //נשאר פה וממתין עד שיתפנה מקום
            end //סיום תנאי
        end //סיום תנאי	
        
        ST_NEXT_WORD: begin //אם נמצאים במצב התקדמות למילה הבאה אז
            if (adrs == 2'd3) next_state = ST_DONE; //בדיקה האם נמצא במילה האחרונה - אם כן אז מעבר למצב סיום
            else              next_state = ST_IDLE; //אם לא, חוזרים למצב המתנה
        end //סיום תנאי	
        
        ST_DONE: begin //אם נמצאים במצב סיום כל המצבים אז
            next_state = ST_DONE; //נשאר פה באופן קבוע עד שילחץ איפוס
        end //סיום תנאי	
        
        default: next_state = ST_IDLE; //הגדרת מצב דיפולט לביטחון - חזרה למצב התחלה והמתנה
    endcase //סיום הגדרת מצבים
end //סיום בלוק 2

//בלוק 3: הגדרת יציאות המכונה לפי תחנות
//שולח ביט אחד רק אם נמצאים בתחנה הנכונה
assign rd = (current_state == ST_READ_ROM); //מדליק קריאה מהזכרון רק בתחנת קריאה
assign ld = (current_state == ST_LOAD_TBUF); //מדליק טעינה רק בתחנת טעינה
assign shr = (current_state == ST_SEND_BITS) && (!fifo_full); //פנוי FIFOמפעיל הזזת ביט באוגר רק אם ה
assign wr_enable = (current_state == ST_SEND_BITS) && (!fifo_full); //רק אם הוא פנוי FIFOנותן פקודת כתיבה ל
assign inc = (current_state == ST_NEXT_WORD); //מדליק קידום הכתובת רק בתחנת קידום
assign tx_finish = (current_state == ST_DONE); //מדליק את האות סיום רק בתחנת הסיום

endmodule //סיום המודול