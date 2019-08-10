         // **************************************************************************
        //  CUSTOMER19 READ BY NATIVE LANGUAGE (ILE RPG)
        //  CONTACTW19 ROW RETRIEVED WITH EMBEDDED SQL
        //  DETAIL REPORT LINE INCLUDES INFORMATION FROM CUSTOMER19 AND CONTACTW19
        //  SUMMARRY REPORT INFORMATION RETRIEVED WITH EMBEDDED SQL STATEMENTS

           DCL-F PHNREPORT PRINTER OFLIND(*IN01) ;
           DCL-F CUSTOMER19 DISK(*EXT) KEYED USAGE(*INPUT)
                 RENAME(CUSTOMER19:CUSTR);
                      // data structure for host variables from CONTACTW19
           DCL-DS CONTACTW19 EXT END-DS;
                     // Standalone fields for indicator variables
           DCL-S INDLastCDate BINDEC(4:0);
           DCL-S INDNextCDate BINDEC(4:0);

           DCL-S Dummy  Zoned(1);

        //**************************************************************************
        //*                        ***   M A I N   R O U T I N E   ***
        //**************************************************************************

                EXSR SummaryInfo;
                WRITE HEADINGS;
                READ CUSTOMER19;
                DOW NOT %EOF;
                    EXSR SQLSelect;
                    IF PHNLDC = OLDESTDATE;
                      FLAG = '<-------';
                    ELSE;
                      FLAG = ' ';
                    ENDIF;
                    IF *IN01 = *ON;
                       Write HEADINGS;
                       *IN01 = *OFF;
                    ENDIF;
                    Write DETAIL;
                   READ CUSTOMER19;
                ENDDO;
                Write SUMMARY;
                *INLR = *ON;
                RETURN;
        //**********************************************************************
        //   S Q L S E L E C T   S U B R O U T I N E
   //   //********************************************************************
   //                  BEGSR    SQLSelect ;
   //    // A row from the contacts table that has the same customer number as t
   //    // read from the CUSTOMER19 file is retrieved to find out the last date
   //    // phone number, comments and the salesperson number.
   //
   //    //  The call back interval is added to the last date called to determin
   //    //  next date to call.  Since null values may be stored in the last dat
   //    // indicator variables are used.
             EXEC SQL
               SELECT PHNLDC + PHNCIT DAYS, PHNLDC,
                 CSTPHN, PHNCOM, CSTSLN
               INTO :NEXTCDATE :INDNEXTCDATE, :PHNLDC :INDLastCDate,
                 :CSTPHN, :PHNCOM, :CSTSLN
               FROM BCI433LIB/CONTACTW19
               WHERE CSTNUM = :CSTNUM;

               SELECT;
                 WHEN SQLSTATE = '00000';
                   Dummy = 0;
                 WHEN SQLSTATE = '02000';
                   CstPhn = 'Not found';
                   NEXTCDATE = D'9999-09-09';
                   PhnLDC = D'9999-09-09';
                   PhnCom = *ALL'*';
                   CstSln = *ALL'*';
                 WHEN %SubSt(SQLState:1:2) = '01';
                   CSTPHN = *ALL'*';
                   NEXTCDATE = D'9999-09-09';
                   PHNLDC = D'9999-09-09';
                   PHNCOM = *ALL'*';
                   CSTSLN = *ALL'*';
                 OTHER;
                   CSTPHN = *ALL'*';
                   NEXTCDATE = D'9999-09-09';
                   PHNLDC = D'9999-09-09';
                   PHNCOM = *ALL'*';
                   CSTSLN = *ALL'*';

               ENDSL;

               IF IndLastCDate = -1;
                 CSTPHN = 'Unknown Date';
                 NEXTCDATE = D'9999-09-09';
                 PHNLDC = D'9999-09-09';
               ELSE;
                 IF IndLastCDate <> 0;
                   CSTPHN = 'Uknown Date';
                   NEXTCDATE = D'9999-09-09';
                   PHNLDC = D'9999-09-09';
                 ENDIF;
               ENDIF;


                         ENDSR ;
        //**********************************************************************
        // S U M M A R Y I N F O   S U B R O U T I N E
        //**********************************************************************
                         BEGSR  SummaryInfo;
        //  D E T E R M I N E   T O T A L S   F O R   CONTACTW19 & CUSTOMER19
             Exec SQL
               SELECT COUNT(*) INTO :CONTACTT
                 FROM BCI433LIB/CONTACTW19;
               IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
                 CONTACTT = -99999;
               ENDIF;

             EXEC SQL
               SELECT COUNT(*) INTO :CUSTOMERT
                 FROM BCI433LIB/CUSTOMER19;
               IF (SQLCODE <> 0) OR (SQLWN0 = 'W');
                 CUSTOMERT = -99999;
               ENDIF;

        // D E T E R M I N E   N U M B E R   O F   U N K N O W N   LAST   DATE CALLED
             EXEC SQL
               SELECT COUNT(*)
                 INTO :UNKNOWNT
                 FROM BCI433LIB/CONTACTW19
                 WHERE CstLastCallDate IS NULL;
             IF NOT(SQLCODE = 0) OR (SQLWN0 = 'W');
               UNKNOWNT = -99999;
             ENDIF;

        //  D E T E R M I N E   O L D E S T   &  M O S T   R E C E N T  L A S T
             EXEC SQL
               SELECT MIN(PHNLDC) INTO :OldestDate
                 FROM BCI433LIB/CONTACTW19;

               IF (SQLCODE <> 0) OR (SQLWN0 = 'W') AND (SQLWN2 <> 'W');
                 OldestDate = D'9999-09-09';
               ENDIF;

             EXEC SQL
               SELECT MAX(PHNLDC) INTO :RecentDate
                 FROM BCI433LIB/CONTACTW19;

               IF (SQLCODE <> 0) OR (SQLWN0 = 'W') AND (SQLWN2 <> 'W');
                 RecentDate = D'9999-09-09';
               ENDIF;

       // D E T E R M I N E   T H E   U S E R   S E R V E R   &   T I M E S T A
             EXEC SQL
               SELECT USER, CURRENT TIMESTAMP, CURRENT SERVER
                 INTO :User, :TimeStamp, :Server
               FROM SYSIBM/SYSDUMMY1;
                         ENDSR; 
