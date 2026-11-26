module RX_FSM ( //הגדרת מודול יחידת בקרה (מכונת מצבים) 
    input wire clk, //הגדרת אות שעון
    input wire rx_clr,//הגדרת אות איפוס
    input wire fifo_empty, //ריק FIFOכניסה שאומרת האם ה
    input wire [1:0] adrs, //כניסה שאומרת באיזו מילה אנו נמצאים כרגע
    output wire wr, //RAMאות יציאה לכתיבה לזיכרון ה
    output wire shr, //אות האומר להזיז ביט ימינה לאוגר
    output wire inc, //אות שליטה למונה הכתובות לקדם באחד
    output wire rd_enable, //FIFOאות האומר לקרוא ביט חדש מה
    output wire rx_finish //אות סיום קליטת כל ארבעת המילים
);

//Moore הגדרת שמות למצבים השונים במכונת 
localparam ST_IDLE         = 3'b000; //מצב אפס: מוכן וממתין לשידור
localparam ST_READ_FIFO    = 3'b001; //FIFOםמצב אחד: בקשת קריאת ביט מה
localparam ST_SHIFT_BIT    = 3'b010; //מצב שתיים: קליטת הביט שיצא והזזתו לתוך האוגר
localparam ST_WRITE_RAM    = 3'b011; //מצב שלוש: כותב את המילה השלמה לזיכרון
localparam ST_NEXT_WORD    = 3'b100; //מצב ארבע: התקדמות למילה הבאה בזיכרון
localparam ST_DONE         = 3'b101; //מצב חמש: סיום קליטת כל המילים

//משתנים ששומרים את המצב הנוכחי ואת המצב הבא
reg [2:0] current_state;
reg [2:0] next_state;

//מונה ספירה מאפס עד שבע שנדע מתי קלטנו 8 ביטים שלמים
reg [2:0] bit_cnt;   

//בלוק 1: המעבר הפיזי בין המצבים
always @(posedge clk) begin //בכל עליית שעון או איפוס 
    if (rx_clr) begin //אם יש איפוס אז
        current_state <= ST_IDLE; //חוזרים למצב המתנה
        bit_cnt       <= 3'd0; //מאפסים את מונה הביטים ל-0 
    end //סיום תנאי
    else begin //אם אין איפוס אז עובדים לפי שעון
        current_state <= next_state; //מחליפים את המצב הנוכחי במצב הבא שחושב
        
        if (current_state == ST_SHIFT_BIT) begin //אם אנחנו מכניסים ביט לאוגר עכשיו
            bit_cnt <= bit_cnt + 1'b1; //נוסיף אחד למונה בכל קליטה בפועל
        end //סיום התנאי
        else if (current_state == ST_WRITE_RAM) begin //אם סיימנו מילה וכותבים לזיכרון אז 
            bit_cnt <= 3'd0; //מאפסים את מונה הביטים ומכינים למילה הבאה
        end //סיום התנאי
    end //סיום תנאי
end //סיום הבלוק

//בלוק 2: קביעת המצב הבא בלי תלות בשעון
always @(*) begin //הוראה לביצוע בכל פעם שהמשתנים בפנים משתנים
    case (current_state) //בדיקה באיזו תחנה נמצאים
        
        ST_IDLE: begin //אם במצב המתנה אז
            if (!fifo_empty) next_state = ST_READ_FIFO; //אם התור לא ריק ויש מה לקרוא, נתחיל קריאה
            else             next_state = ST_IDLE; //אם התור ריק, נמשיך להמתין
        end //סיום תנאי	
        
        ST_READ_FIFO: begin //אם אנחנו שולחים בקשת קריאה אז
            next_state = ST_SHIFT_BIT; //במחזור השעון הבא נעבור לקלוט פיזית את הביט לאוגר
        end //סיום תנאי	

        ST_SHIFT_BIT: begin //אם קלטנו ביט והזזנו אותו באוגר אז
            if (bit_cnt == 3'd7) next_state = ST_WRITE_RAM; //אם קלטנו כבר 8 ביטים, נעבור לשמור אותם בזיכרון
            else                 next_state = ST_IDLE; //ריק או שיש ביט חדש שמחכה FIFOאם עדיין אין 8 ביטים חוזרים לבדוק אם ה
        end //סיום תנאי	
        
        ST_WRITE_RAM: begin //אם אנחנו כותבים לזיכרון
            next_state = ST_NEXT_WORD; //במחזור שעון הבא נעבור אוטומטית לשלב בו מקדמים מילים
        end //סיום תנאי	
        
        ST_NEXT_WORD: begin //אם נמצאים במצב התקדמות למילה הבאה אז
            if (adrs == 2'd3) next_state = ST_DONE; //בדיקה האם נמצא במילה האחרונה-אם כן אז תעבור למצב סיום
            else              next_state = ST_IDLE; //אם לא חוזרים למצב המתנה למילה חדשה
        end //סיום תנאי	
        
        ST_DONE: begin //אם סיימנו לקלוט הכל
            next_state = ST_DONE; //נשאר פה באופן קבוע עד שילחץ איפוס
        end //סיום תנאי	
        
        default: next_state = ST_IDLE; //חזרה למצב התחלה במקרה של תקלה
    endcase //סיום הגדרת מצבים
end //סיום בלוק 2

//(מכונת Moore)בלוק 3: הגדרת יציאות המכונה לפי תחנות 
assign rd_enable = (current_state == ST_READ_FIFO); //רק בתחנת קריאה FIFOשולח בקשת קריאה מה
assign shr = (current_state == ST_SHIFT_BIT); //מדליק הזזת ביט רק בתחנת קליטת הביט בפועל
assign wr  = (current_state == ST_WRITE_RAM); //מדליק כתיבה לזיכרון רק בתחנת הכתיבה
assign inc = (current_state == ST_NEXT_WORD); //מדליק קידום כתובת רק בתחנת קידום
assign rx_finish = (current_state == ST_DONE); //מדליק את האות סיום רק בתחנת הסיום

endmodule //סיום המודול