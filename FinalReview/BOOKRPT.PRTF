         // FILES
         DCL-F BkCustomer Disk(*EXT) Rename(BkCustomer:BkCustR);
         DCL-F BookRpt Printer OFLIND(*IN01);

         // PASSED PARAMETER
         DCL-PI MAIN EXTPGM('BOOKSQL');
           ReportTitle Char(15);
         END-PI;

         // GET FIELDS FROM THE TABLE ACCESSED WITH EMBEDDED SQL
         DCL-DS AudibleBks EXT END-DS;

         // VARIABLES (FOR UNKNOWN VALUES AND DUMMY)
         DCL-S IndGenre BINDEC(4:0);
         DCL-S Dummy Zoned(1:0);


         //  *** MAIN ROUTINE *** //
         EXSR SummaryInfo;
         Write Title;
         Write ColHdg;
         Read BkCustomer;

         DOW NOT %EOF;   // LOOP
           EXSR SQLSelect;
           If *IN01 = *ON;
             WRITE TITLE;
             WRITE ColHdg;
             *IN01 = *OFF;
           ENDIF;
           TOTQTY = TOTQTY + QTY;
           Write Detail;
           Read BkCustomer;
         ENDDO;
         Write Totals;
         *INLR = *ON;
         RETURN;


         // *** SQLSELECT SUBROUTINE *** //
         BEGSR SQLSelect;
           EXEC SQL
             SELECT Book, Genre, Price
             INTO :Book, :Genre :IndGenre, :Price
             FROM BCI433LIB/AudibleBks
             WHERE BookId = :BookPur#;

             SELECT;
               WHEN SQLSTATE = '00000';
                 Dummy = 0;
               WHEN SQLSTATE = '02000';
                 Book = 'Not Found';
               WHEN %Subst(SQLSTATE:1:2) = '01';
                 Book = 'Warning';
               OTHER;
                 Book = 'Error';
             ENDSL;
             If IndGenre = -1;
               Genre = 'Unknown Genre';
             ENDIF;

             SELECT;
               When Discount <> 0;
                 EVAL(H) DisPrice = Price - (Price * Discount);
               Other;
                 DisPrice = Price;
             ENDSL;
             ExPrice = DisPrice * Qty;
         ENDSR;

         // *** SUMMARYINFO SUBROUTINE *** //
         BEGSR SummaryInfo;
           // DETERMINE TOTALS FOR BkCustomer
           EXEC SQL
             SELECT COUNT(*) INTO :BkCustTot
               FROM BCI433LIB/BkCustomer;

           IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
             BkCustTot = -999;
           ENDIF;

           // DETERMINE Highest Quantity Customer Purchase
           EXEC SQL
             SELECT Max(Qty) INTO :MostBooks
             FROM BCI433LIB/BkCustomer;

           IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
             MostBooks = -99;
           ENDIF;

           // DETERMINE Total Quantity books purchased for all Customers


           // DETERMINE THE SERVER & DATE
           EXEC SQL
             SELECT Current Date, Current Server
               INTO :ReportDate, :SystemName
               FROM SYSIBM/SYSDUMMY1;
         ENDSR; 
