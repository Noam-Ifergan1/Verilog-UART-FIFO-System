`timescale 1ns / 1ps //הגדרת יחידות הזמן לסימולציה

module tb_TX_RX(); //הגדרת מודול סביבת הבדיקה

reg clk; //הגדרת משתנה שעון למערכת
reg sys_clr; //הגדרת משתנה לאות איפוס משותף לשניהם

//הגדרת חוטים המקשרים בין המשדר למקלט
wire serial_data_line; //הגדרת חוט נתונים טורי
wire data_valid_line; //חוט אות התקפות
wire receiver_ready_line; //חוט אות המוכנות
    
//חוטים למעקב שלנו לסביבת הבדיקה
wire tx_is_done; //חוט מעקב אחרי סיום המשדר
wire rx_is_done; //חוט מעקב אחרי סיום המקלט
wire [7:0] rx_memory_view; //חוט תצוגה לזיכרון של המקלט

//חיבור המשדר לסביבת הבדיקה
    TX_block u_TX (
        .clk(clk), //חיבור שעון
        .tx_clr(sys_clr), //חיבור איפוס ראשי
        .rx_rdy(receiver_ready_line), //חיבור חוט המוכנות 
        .tx_data(serial_data_line), //חיבור חוט הנתונים הטורי
        .tx_vld(data_valid_line), //חיבור חוט התקפות
        .tx_finish(tx_is_done) //חיבור חוט סיום המשדר
    );

//חיבור המקלט לסביבת הבדיקה
    RX_block u_RX (
        .clk(clk), //חיבור שעון
        .rx_clr(sys_clr), //חיבור איפוס ראשי
        .tx_vld(data_valid_line), //חיבור חוט התקפות שמגיע מהמשדר
        .tx_data(serial_data_line), //חיבור חוט הנתונים הטורי שמגיע מהמשדר
        .rx_rdy(receiver_ready_line), //חיבור חוט המוכנות שיוצא למשדר
        .rx_finish(rx_is_done), //חיבור חוט סיום המקלט
        .rx_mem_dout(rx_memory_view) //חיבור חוט התצוגה של הזיכרון
    );

    always begin //התחלת לולאה אינסופית המפעילה את שעון המערכת
        #5 clk = ~clk; //הערך של השעון מתהפך כל חמש ננו שניות
    end //סיום בלוק יצירת שעון

    initial begin //t=0 התחלת בלוק הרצה באופן חד פעמי שמתחיל בזמן 
        //הגדרת מצב התחלה
        clk = 0; //איפוס שעון
        sys_clr = 1; //הדלקת כפתור איפוס לאתחול המערכת

        $display("Start system simulation");

        #20 sys_clr = 0; //המתנה של 20 ננו שניות ואז עוזבים את האיפוס
        
        $display("System is running...");

        wait (rx_is_done == 1); //המתנה עד שהמקלט יסיים לקלוט הכל
        $display("All 4 words transferred");
        
        #50; //המתנה של 50 ננו שניות כדי לראות בבירור במסך הגלים
        $stop; //פקודה שעוצרת את הסימולטור
    end //סיום הבלוק

endmodule //סיום המודול