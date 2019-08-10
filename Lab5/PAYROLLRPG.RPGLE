         DCL-F CONFIRMPAY WORKSTN;
         DCL-F ALLSHIFT   USAGE(*INPUT) RENAME(ALLSHIFT:ALLSHIFTR);
         DCL-F SHIFTRATES DISK USAGE(*INPUT) RENAME(SHIFTRATES:SHIFTRATER);
         DCL-F PAYRPT     PRINTER OFLIND(*IN01);

         DCL-S HOURSOVER PACKED(3);

         READ SHIFTRATES;
         WRITE TITLE;
         WRITE COLHDG;
         READ ALLSHIFT;

         DOW NOT %EOF;
           EXSR PAYSR;
           IF *IN01;
             WRITE TITLE;
             WRITE COLHDG;
             *IN01=*OFF;
           ENDIF;
           WRITE EMPDETAIL;
           READ ALLSHIFT;
         ENDDO;

         TOTWKPAY = TOTREGPAY + TOTOVTPAY;
         WRITE TOTALS;
         EXFMT RECORD1;
         *INLR = *ON;
         RETURN;

         BEGSR PAYSR;
           SELECT;
             WHEN WORKSHIFT = 'D';
               HOURLYRATE = DAYRATE;
             WHEN WORKSHIFT = 'A';
               HOURLYRATE = AFTNRATE;
             WHEN WORKSHIFT = 'N';
               HOURLYRATE = NIGHTRATE;
           ENDSL;

           SELECT;
             WHEN PAYGRADE='1';
               EVAL(H) HOURLYRATE *= 1.072;
             WHEN PAYGRADE='2';
               EVAL(H) HOURLYRATE *= 1.056;
             WHEN PAYGRADE='3';
               EVAL(H) HOURLYRATE *= 0.966;
           ENDSL;

           HOURSOVER = HRSWORKED - 40;

           SELECT;
             WHEN (HOURSOVER > 0);
               REGULARPAY = 40 * HOURLYRATE;
               EVAL(H) OVERPAY = HOURSOVER * HOURLYRATE * 1.5;
               WEEKLYPAY = REGULARPAY + OVERPAY;
               TOTREGPAY += REGULARPAY;
               TOTOVTPAY += OVERPAY;
             OTHER;
               REGULARPAY = HRSWORKED * HOURLYRATE;
               WEEKLYPAY = REGULARPAY;
               OVERPAY = 0;
               TOTREGPAY += REGULARPAY;
           ENDSL;

         ENDSR;
 
