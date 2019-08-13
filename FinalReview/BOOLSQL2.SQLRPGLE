         // Book Report file
         DCL-F BookRpt2 PRINTER OFLIND(*IN01);

         // Two Stand alone fields
         DCL-S GenreH Char(20);
         DCL-S EndOfFile IND;

         DCL-DS AudibleBksRec;
           Genre     Char(20);
           Book      Char(50);
           Duration  Time;
           Author    Char(30);
           BookId    Zoned(7:0);
           Price     Packed(5:2);
         END-DS;

         // *** MAIN ROUTINE *** //
         // DETERMINE THE DATE & SERVER
         EXEC SQL
           SELECT Current Date, Current Server
             INTO :ReportDate, :SystemName
             FROM SYSIBM/SYSDUMMY1;

             EXSR PrepareFiles;

             Write Title;
             Write ColHdg;

             EXSR GetRow;
             Write GenreRec;
             GenreH = Genre;

             DOW NOT EndOfFile;
               IF *IN01 = *ON;
                 Write Title;
                 Write ColHdg;
                 *IN01 = *OFF;
               ENDIF;

               If GenreH = Genre;
                 Write Detail;
                 TotalBooks = TotalBooks + 1;
                 TotalPrice = TotalPrice + Price;
               Else;
                 Write Totals;
                 GenreH = Genre;
                 Write GenreRec;
                 Write Detail;
                 TotalBooks = 1;
                 TotalPrice = Price;
               ENDIF;

               EXSR GetRow;
             ENDDO;

             EXSR WRAPUP;
             Write Totals;
             *INLR = *ON;
             RETURN;

             // *** OPENFILES SUBROUTINE *** //
             BEGSR PrepareFiles;
               EXEC SQL
                 DECLARE BookGenres CURSOR
                   FOR
                   SELECT GENRE, BOOK, DURATION, AUTHOR, BOOKID, PRICE
                   FROM AUDIBLEBKS
                   WHERE GENRE = 'Sci Fi/Fantasy' or
                         GENRE = 'Thriller/Mystery'
                   ORDER BY GENRE, DURATION
                   FOR READ ONLY;

               // A TEMPORARY RESULT TABLE IS CREATED
               EXEC SQL
                 OPEN BookGenres;
               IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
                 EndOfFile = *ON;
               ENDIF;
             ENDSR;

             // *** GET ROW SUBROUTINE *** //
             BEGSR GETROW;
               EXEC SQL
                 FETCH NEXT
                   FROM BookGenres
                   INTO :AudibleBksRec;

               IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
                 EndOfFile = *ON;
               ENDIF;
             ENDSR;

             // *** WRAPUP SUBROUTINE *** //
             BEGSR WRAPUP;
               EXEC SQL
                 CLOSE BookGenres;
               If (SQLCODE <> 0) OR (SQLWN0 = 'W');
                 EndOfFile = *ON;
               ENDIF;
             ENDSR; 
