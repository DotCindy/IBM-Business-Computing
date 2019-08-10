       //**************************************************************************
       //* THIS PROGRAM USES A CURSOR TO LOAD A TEMPORARY RESULT TABLE THAT JOINS T
       //* ORDERLINE, CUSTOMER, PART AND SALESREP TABLES.  ORDER NUMBER IS USED AS
       //* FIELD WHERE CUSTOMER TOTALS ARE PRINTED ON NEW ORDER NUMBERS
       //*
       //**************************************************************************
           DCL-F PROVREPORT PRINTER OFLIND(*IN01) ;
           DCL-S ProvinceH    Char(10);
           DCL-S EndOfFile    IND;
           DCL-S TotalRecords PACKED(5:0) ;
             // LowLimit is passed to the program
           DCL-PI Main extPgm('PROVSQL');
             LowLimit Zoned(7:2);
           END-PI;
             // All Host Variables available under a single name
           DCL-DS CustomerRecord;
             CustId   Char(6);
             FullName Char(31);
             City     Char(20);
             Purchase Packed (7:2);
             PDate    Date;
             Province Char(10);
        End-Ds CustomerRecord;
     C/EJECT
     C**************************************************************************
     C*                        ***   M A I N   R O U T I N E   ***
     C**************************************************************************
      /FREE
                EXSR PrepareFiles;
                Write Title;
                Write HEADINGS;
                EXSR GetRow;
                Write NewProv;
                ProvinceH = Province;
                DOW NOT EndOfFile;
                    IF *IN01 = *ON;
                        Write Title;
                        Write HEADINGS;
                       *IN01 = *OFF;
                    ENDIF;
                    // Province may change
                    IF ProvinceH = Province;
                      Write Detail;
                    ELSE;
                      ProvinceH = Province;
                      Write Totals;
                      TotalPurch = 0;
                      Write NewProv;
                      Write Detail;
                    ENDIF;

                    TotalPurch     = TotalPurch     + Purchase;
                    TotalRecords= TotalRecords + 1;
                    EXSR GetRow;
                ENDDO;
                Write Totals;
                EXSR   WRAPUP;
                Write UnderLimit;
                *INLR = *ON;
                RETURN;
        //**********************************************************************
        // O P E N F I L E S   S U B R O U T I N E
        //**********************************************************************
         BEGSR  PrepareFiles;
        // S E T   U P   T H E   T E M P O R A R Y   R E S U L T  STRUCTURE
         EXEC SQL
           DECLARE ALLPROVCURSOR CURSOR
             FOR
             SELECT CUSTID, TRIM(FNAME) || ' ' || LNAME,
                    CITY, PURCHASE, PDATE,
                    'Ontario' AS PROVINCE
             FROM BCI433LIB/ONTARIO
             WHERE PURCHASE > :LowLimit
             UNION ALL
             SELECT CUSTID, TRIM(FNAME) || ' ' || LNAME,
                    CITY, PURCHASE, PDATE,
                    'Quebec' AS PROVINCE
             FROM BCI433LIB/QUEBEC
             WHERE PURCHASE > :LowLimit
             UNION ALL
             SELECT CUSTID, TRIM(FNAME) || ' ' || LNAME,
                    CITY, PURCHASE, PDATE,
                    'Manitoba' AS PROVINCE
             FROM BCI433LIB/MANITOBA
             WHERE PURCHASE > :LowLimit;

        // A   T E M P O R A R Y   R E S U L T   T A B L E   I S   C R E A T E D
             EXEC SQL
               OPEN ALLPROVCURSOR;
                 IF SQLCODE <> 0 OR SQLWN0 = 'W';
                   EndOfFile = *ON;
                 ENDIF;
            ENDSR;
        //**********************************************************************
        //   G E T     R O W    S U B R O U T I N E
        //**********************************************************************
            BEGSR     GETROW;
              EXEC SQL
                FETCH NEXT
                  FROM ALLPROVCURSOR
                  INTO :CustomerRecord;

              IF SQLCODE <> 0 OR SQLWN0 = 'W';
                EndOfFile = *ON;
              ENDIF;
             ENDSR;
        //**********************************************************************
        // W R A P U P     S U B R O U T I N E
        //**********************************************************************
           BEGSR WRAPUP;
             EXEC SQL
               CLOSE ALLPROVCURSOR;

             IF SQLCODE <> 0 OR SQLWN0 = 'W';
               EndOfFile = *ON;
             ENDIF;

             EXEC SQL
               SELECT COUNT(*) INTO :ONTTOTAL
                 FROM BCI433LIB/ONTARIO
                 WHERE PURCHASE <= :LowLimit;

             IF SQLCODE <> 0 OR SQLWN0 = 'W';
               ONTTOTAL = -999;
             ENDIF;

             EXEC SQL
               SELECT COUNT(*) INTO :QUETOTAL
                 FROM BCI433LIB/QUEBEC
                 WHERE PURCHASE <= :LowLimit;

             IF SQLCODE <> 0 OR SQLWN0 = 'W';
               QUETOTAL = -999;
             ENDIF;

             EXEC SQL
               SELECT COUNT(*) INTO :MANTOTAL
                 FROM BCI433LIB/MANITOBA
                 WHERE PURCHASE <= :LowLimit;

             IF SQLCODE <> 0 OR SQLWN0 = 'W';
               MANTOTAL = -999;
             ENDIF;
          ENDSR;














 
