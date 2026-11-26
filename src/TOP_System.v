module TOP_System ( //הגדרת מודול המערכת הכוללת
    input wire clk, //אות שעון ראשי למערכת כולה
    input wire reset, //אות איפוס ראשי למערכת כולה
    output wire tx_finish, //אות סיום שידור המגיע מהמשדר
    output wire rx_finish, //אות סיום קליטה המגיע מהמקלט
    output wire [7:0] rx_mem_dout //יציאת נתונים מהמקלט לתצוגה במסך הגלים
);

//הגדרת חוטים פנימיים המקשרים בין הבלוקים השונים
wire internal_wr_enable; //FIFOחוט פקודת כתיבה מהמשדר ל
wire internal_rd_enable; //FIFOחוט פקודת קריאה מהמקלט ל
wire internal_tx_data;   //(ביט אחד) FIFOחוט הנתונים מהמשדר ל 
wire internal_rx_data;   //למקלט (ביט אחד)  FIFOחוט הנתונים מה
wire internal_fifo_full; //למשדר שהתור מלא FIFOחוט חיווי מה
wire internal_fifo_empty;//למקלט שהתור ריק FIFOחוט חיווי מה

//חיבור בלוק המשדר אל המערכת הכוללת
    TX_block u_TX_block ( //יצירת עותק של המשדר
        .clk(clk),                   //חיבור שעון המערכת הראשי
        .tx_clr(reset),              //חיבור אות האיפוס הכללי
        .fifo_full(internal_fifo_full), //(מלא FIFOאל בקרה פנימית (עוצר כשה FIFOחיבור כניסת מלאי ה
        .tx_data(internal_tx_data),  //שליחת הנתון הטורי אל החוט הפנימי
        .wr_enable(internal_wr_enable), //שליחת פקודת כתיבה אל החוט הפנימי
        .tx_finish(tx_finish)        //הוצאת חיווי סיום החוצה מהמערכת
    );

//חיבור הנתונים אל המערכת הכוללת
    FIFO u_FIFO ( //FIFOיצירת עותק של ה
        .clk(clk),                   //חיבור שעון המערכת הראשי
        .reset(reset),               //חיבור אות האיפוס הכללי
        .wr_enable(internal_wr_enable), //קבלת פקודת כתיבה מהמשדר
        .rd_enable(internal_rd_enable), //קבלת פקודת קריאה מהמקלט
        .din(internal_tx_data),      //קבלת הנתון הטורי מהמשדר
        .dout(internal_rx_data),     //שליחת הנתון הטורי למקלט
        .full(internal_fifo_full),   //מלא אל החוט של המשדר (כדי להגיד לו לעצור)  FIFO חיבור יציאת האות המתריע על 
        .empty(internal_fifo_empty)  //ריק אל החוט של המקלט (כדי להגיד לו לחכות)  FIFO חיבור יציאת האות המתריע על 
    );

//חיבור בלוק המקלט אל המערכת הכוללת
    RX_block u_RX_block ( //יצירת עותק של המקלט
        .clk(clk),                   //חיבור שעון המערכת הראשי
        .rx_clr(reset),              //חיבור אות האיפוס הכללי
        .fifo_empty(internal_fifo_empty), //ריק FIFOקבלת חיווי שה
        .tx_data(internal_rx_data),  //FIFOקבלת הנתון הטורי מה
        .rd_enable(internal_rd_enable), //FIFOשליחת פקודת קריאה אל ה
        .rx_finish(rx_finish),       //הוצאת חיווי סיום החוצה מהמערכת
        .rx_mem_dout(rx_mem_dout)    //הוצאת תוכן הזיכרון להצגה
    );

endmodule //סיום המודול העליון