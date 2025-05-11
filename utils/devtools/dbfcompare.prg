*
* dbfcompare.prg
*
* $Id$
*
* HWGUI - Harbour Win32 and Linux/MacOS (GTK) GUI library
*
* This program compares two DBF's
* with same structure and order
* and writes modifications into a
* text file.
*
* It is a helpful tool for regression tests,
* see full description above.
*
 * Copyright 2024 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
*
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/MacOS:  Yes
    *  GTK/Win  :  No

/*
  Main purpose:
  ~~~~~~~~~~~~~
  Regression test mean,
  that you compare the modification
  done by your (automatic) processing
  and return back to the previous
  data to start the processing again
  after code modifications
  until you are pleased by the correct
  result.

  Detailed instructions:
  ~~~~~~~~~~~~~~~~~~~~~~

  1.) Make a backup copy of your *.dbf file
      and the *.dbt file, if memo fields are existing.
      Be shure, that the database to copy is really closed.

  2.) Start your processing and close your application, if done.
      Now start this tool.
      In the main menu you find the item
      Compare ==> Start.
      First the modified database is queried (database 1),
      by the second query you must select the
      backup copy of your modified database (database 2).
      All modifications are written into the log file
      "dbfcompare.log"
      The number of records read and modified are
      also reported.

   3.)If you want to repeat the processing with
      modified program code:
      Copy the backup database to modified database,
      getting the previous data.
      Recreate index files, if existing.
      Now start the next run of your processing.
      Repeat 2.) and 3.), if you have the desired result.

    More information:
    - The compare process does not use index files,
      it compares record for record ascending by
      record number started at top.
    - Do not pack one of the databases, so
      the compare will fail, because the
      order differs.
    - New records are appended at end of file,
      added records are only reported with number.
    - Only modified fields are reported,
      so the data size get reduced.
    - The contents of a memo field is not
      reported, only the fact, that the
      memo differs. This avoids to much output.
    - The compare process is aborted, if:
      1.) The structure of both databases differ,
      2.) the original database (second selection)
          has more records than the database with
          modified record (first selection),
      3.) one or both databases are empty.

      Demo task:
      Open databases "sample.dbf" and "sampleori.dbf"
      (in this order) and the result in file "dbfcompare.log" is:

Database 1 openend: sample alias=SAMPLE
Database 2 openend: sampleori alias=SAMPLEORI
Compare databases C:\CLLOG\src\sample.dbf with C:\CLLOG\src\sampleori.dbf
Date: 2024.10.11 time: 17:53:35 (local)
Primary structure:
{ "FLD_N" , "N" , 10 , 0 }  , ;
{ "FLD_C" , "C" , 15 , 0 }  , ;
{ "FLD_D" , "D" , 8 , 0 }  , ;
{ "FLD_L" , "L" , 1 , 0 }  , ;
{ "FLD_M" , "M" , 10 , 0 }   ;
Secondary structure:
{ "FLD_N" , "N" , 10 , 0 }  , ;
{ "FLD_C" , "C" , 15 , 0 }  , ;
{ "FLD_D" , "D" , 8 , 0 }  , ;
{ "FLD_L" , "L" , 1 , 0 }  , ;
{ "FLD_M" , "M" , 10 , 0 }   ;
Database 1 has 153 records
Database 2 has 152 records
Record number: 4 FLD_N: >9999< / >4<
Record number: 5 FLD_M: memo differs
Record number: 6 FLD_C: >modified text< / ><
Record number: 7 FLD_C: >modified date< / >< FLD_D: >2024.10.05< / >.  .<
Record number: 8 FLD_C: >modified bool< / >< FLD_L: >T< / >F<
Record number: 9 FLD_C: >modified memo2< / >< FLD_M: memo differs
Record number: 10 Deleted : T/F FLD_C: >deleted record< / ><
Record number: 152 FLD_M: memo differs
Record number: 153 new record

Summary:
Compare completed.
Number of records read: 153
Number of records differs: 9




Table with modifications:

RECNO : FLD_N      ! FLD_C         ! FLD_D    ! FLD_L ! FLD_M

   4  :        9999!               !  .  .    !  F    !  <Memo>
   5  :           5!               !  .  .    !  F    !  <Memo>  (only memo differs)
   6  :           6!modified text  !  .  .    !  F    !  <Memo>
   7  :           7!modified date  !05.10.2024!  F    !  <Memo>
   8  :           8!modified bool  !  .  .    !  T    !  <Memo>
   9  :           9!modified memo2 !  .  .    !  F    !  <Memo>
  10  :          10!deleted record !
 151  :         98 !               !          !  F    !  <Memo>  both memo' empty ==> equal
 152  :        999 !               !          !  F    !  <Memo>  memo not empty  in ori
 153  : 9999999999 !               !          !  F    !  <Memo>  new record


*/



* Uncomment this define out,
* if only the field name that differs is reported and
* not the contents.
#define COMP_VALUES

* Uncomment this define out, if
* reported values will not ALLTRIMed before
* writing to the output line(s).
#define COMP_ALLTRIM

* Uncomment out for DEBUG mode
* and use function DEBUG_SEL() to write selects and aliases
* into the logfile.
* #define DEBUG_MODE

#include "hwgui.ch"


* Codepages, modify to your own needs:
* Windows codepage
REQUEST HB_CODEPAGE_DEWIN
#ifdef __LINUX__
* LINUX Codepage
REQUEST HB_CODEPAGE_UTF8EX
#endif

FUNCTION Main()

   LOCAL oWndMain

* Date settings, modify to your own needs:
SET CENTURY ON
SET DATE ANSI

* Important !
* For memo compare (see sample program demomemocomp.prg)

  INIT WINDOW oWndMain MAIN TITLE "DBF compare untility" AT 200,100 SIZE 300,300

   MENU OF oWndMain
      MENU TITLE "&File"
        MENUITEM "&Exit" ACTION oWndMain:Close()
      ENDMENU
      MENU TITLE "&Compare"
        MENUITEM "&Start" ACTION START_CMP()
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oWndMain

RETURN Nil

* ---------------------------------------
FUNCTION START_CMP()
* This function query the file names for two dbf's to compare
* and starts the compare process.
* ---------------------------------------
LOCAL colddir,cdbfmod,cdbfori, aselect
LOCAL cfield,coutline,nlc,nfc,nindex,lstructdif,ldelete,nlc2,cfield2, nxrecno
LOCAL ngelesen, ndiffers, lmodified, xtempf, cftypex, nlstrec1, nlstrec2
LOCAL afnames1, adtypes1, afleng1, adecimal1, afnames2, adtypes2, afleng2, adecimal2
LOCAL nfcntf, caliasn1, caliasn2

LOCAL atest

IF FILE("dbfcompare.log")
  DELETE FILE dbfcompare.log
 ENDIF

* Query file/databases and open them
*
* 1 : modified database
aselect := select_dbffile("xBase databases modified( *.dbf )")


cdbfmod  := aselect[1]
colddir := aselect[2]

IF EMPTY(cdbfmod)
  * Cancel
  hwg_ChDir(hwg_CleanPathname(colddir))
  RETURN NIL
ENDIF

 caliasn1 := hwg_BaseName(hwg_ProcFileExt(cdbfmod,""))
 SELECT 1
 USE &caliasn1
 hwg_ChDir(hwg_CleanPathname(colddir))

 LOGGING("Database 1 openend: " + caliasn1 + " alias="+ ALIAS() )


* 2 : original database
aselect := select_dbffile("xBase databases original( *.dbf )")

cdbfori  := aselect[1]
IF EMPTY(cdbfori)
  * Cancel
  hwg_ChDir(hwg_CleanPathname(colddir))
  CMP_CLOSALL()
  RETURN NIL
ENDIF

 caliasn2 := hwg_BaseName(hwg_ProcFileExt(cdbfori,""))

* The open database number 1 is detected on Windows in
* the file selection dialog, if same file is selected !
 IF cdbfori == cdbfmod
  hwg_MsgStop("Selected database names are identical, aborted","DBF compare")
  CMP_CLOSALL()
  RETURN NIL
ENDIF


 SELECT 2
 USE &caliasn2
 hwg_ChDir(hwg_CleanPathname(colddir))

 LOGGING("Database 2 openend: " + caliasn2 + " alias="+ ALIAS() )


 hwg_MsgInfo("Compare databases " + cdbfmod +  " with " + cdbfori)
 LOGGING("Compare databases " + cdbfmod +  " with " + cdbfori)
 LOGGING("Date: " + DTOC(DATE()) + " time: " + TIME() + " (local)")

 afnames1  := {}
 adtypes1  := {}
 afleng1   := {}
 adecimal1 := {}
 afnames2  := {}
 adtypes2  := {}
 afleng2  := {}
 adecimal2  := {}

 lstructdif := .F.

 ngelesen := 0
 ndiffers := 0
 lmodified := .F.

 SELECT 1




* Get structures and check for same,
* split all structure parameters in extra arrays
* and report the primary structure
LOGGING("Primary structure:")
nlc2 := 0
nlc := 0
nfc := FCOUNT()
FOR EACH cfield IN dbStruct()
 coutline := "{ " + CHR(34) + cfield[ 1 ] + CHR(34) + ;
   " , " + CHR(34) +  cfield[ 2 ]  + CHR(34) + ;
   " , " + ALLTRIM(STR (cfield[ 3 ] )) + ;
   " , " + ALLTRIM(STR (cfield[ 4 ] )) + " } "
   nlc := nlc + 1
   *
   AADD(afnames1 ,cfield[ 1 ] )
   AADD(adtypes1 ,cfield[ 2 ] )
   AADD(afleng1  ,cfield[ 3 ] )
   AADD(adecimal1,cfield[ 4 ] )
   * if last field detected, do not write comma
   IF nlc == nfc
      coutline := coutline + "  ;"
   ELSE
      coutline := coutline + " , ;"
   ENDIF
   LOGGING(coutline)
NEXT

 SELECT 2
* DEBUG_SEL()


 * Report second structure
 LOGGING("Secondary structure:")
 FOR EACH cfield2 IN dbStruct()
  coutline := "{ " + CHR(34) + cfield2[ 1 ] + CHR(34) + ;
   " , " + CHR(34) +  cfield2[ 2 ]  + CHR(34) + ;
   " , " + ALLTRIM(STR (cfield2[ 3 ] )) + ;
   " , " + ALLTRIM(STR (cfield2[ 4 ] )) + " } "
    nlc2 := nlc2 + 1
   AADD(afnames2 ,cfield2[ 1 ] )
   AADD(adtypes2 ,cfield2[ 2 ] )
   AADD(afleng2  ,cfield2[ 3 ] )
   AADD(adecimal2,cfield2[ 4 ] )
  IF nlc2 == FCOUNT()
      coutline := coutline + "  ;"
   ELSE
      coutline := coutline + " , ;"
   ENDIF
   LOGGING(coutline)
 NEXT

* Now compare the structure

 SELECT 2


 IF nfc != FCOUNT()
   hwg_MsgStop("Structures are not identical, compare aborted","DBF compare")
   LOGGING("Structures are not identical, compare aborted: Number of fields differ: " + ;
   ALLTRIM(STR(nlc)) + " / " + ALLTRIM(STR(nlc2)) )
   CMP_CLOSALL()
   RETURN NIL
 ENDIF

 FOR nindex := 1 TO hwg_Array_Len(afnames2)  && for every field name
   IF afnames1 [nindex] != afnames2 [nindex]
      lstructdif := .T.
      EXIT
   ENDIF
 NEXT

 IF lstructdif
   hwg_MsgStop("Structures are not identical, compare aborted","DBF compare")
   LOGGING("Structures are not identical, compare aborted")
   CMP_CLOSALL()
   RETURN NIL
 ENDIF



* Get number of records
 SELECT 2

 nlstrec2 := LASTREC()


 SELECT 1

 nfcntf := FCOUNT()
 nlstrec1 := LASTREC()

 LOGGING("Database 1 has " + ALLTRIM(STR(nlstrec1 )) + " records" )
 LOGGING("Database 2 has " + ALLTRIM(STR(nlstrec2 )) + " records" )

* Check for conflicts of last record numbers

  IF nlstrec1 < 1
      hwg_MsgStop("The first database is empty, nothing to compare","DBF compare")
      CMP_CLOSALL()
      RETURN NIL
  ENDIF

  IF nlstrec2 < 1
      hwg_MsgStop("The second database is empty, nothing to compare","DBF compare")
      CMP_CLOSALL()
      RETURN NIL
  ENDIF

  IF nlstrec2 > nlstrec1
   hwg_MsgStop("The second database has more records than the first, cannot compare them", ;
             "DBF compare")
   CMP_CLOSALL()
   RETURN NIL
  ENDIF

* Now structures are identical, start compare of contents


 GO TOP

 * Here forever go with SELECT 1 into the loop (caliasn1)
 DO WHILE .NOT. EOF()
   lmodified := .F.
    ngelesen := ngelesen + 1   && Count records read
    nxrecno := RECNO()
 * Look for apendended (new) record
   IF nlstrec2 < RECNO()
     * New record
     coutline := "Record number: " + ALLTRIM(STR(RECNO())) + " new record"
     LOGGING(coutline)
     lmodified := .T.
   ELSE && appended records
     * Recent record number
     coutline := "Record number: " + ALLTRIM(STR(RECNO()))

     * First check for deleted
     ldelete := DELETED()
     SELECT 2

     GO nxrecno   && same record as SELECT 1

     IF ldelete != DELETED()
       lmodified := .T.
       coutline := coutline + " Deleted : " + deleted2char(ldelete) + "/" + deleted2char(DELETED())
     ENDIF

     SELECT 1

     * Now compare field for field of a record
     FOR nindex := 1 TO nfcntf

     SELECT 1

       xtempf  := FieldGet(nindex)   && xtempf contains the field content of 1st database
       cftypex := adtypes1[nindex]

       SELECT 2

       * Special handling of memos
        IF cftypex == "M"

            IF .NOT. (  EMPTY(xtempf) .AND. EMPTY(FieldGet(nindex))  )
              * Both memo empty ==> equal
              * otherwise:
              * Compare memo contents

              IF .NOT. ( xtempf == FieldGet(nindex) )
                  lmodified := .T.
                 coutline := coutline + " " + ALLTRIM(afnames1[nindex]) + ":" + " memo differs"
              ENDIF
           ENDIF
        ELSE  && not memo
           * Here compare the field contents
           IF xtempf != FieldGet(nindex)  && xtempf != &afnames1[nindex] <== this crashes
              lmodified := .T.
              * Handle specific of data type (for output):
              * "Character","Numeric","Date","Logical", "Memo" == > see above
              DO CASE
                CASE cftypex == "C"
                     coutline := coutline + " " + ALLTRIM(afnames1[nindex]) + ":" + ;
                     CMP_VALUES(xtempf,FieldGet(nindex))
                CASE cftypex == "N"
                     * N data types are always ALLTRIM'ed
                     coutline := coutline + " " + ALLTRIM(afnames1[nindex]) + ":" + ;
                     CMP_VALUES(ALLTRIM(STR(xtempf)),ALLTRIM(STR(FieldGet(nindex)) ) ) && &afnames1[nindex]
                CASE cftypex == "D"
                     coutline := coutline + " " + ALLTRIM(afnames1[nindex]) + ":" + ;
                     CMP_VALUES(DTOC(xtempf),DTOC(FieldGet(nindex)) )
                CASE cftypex == "L"
                     coutline := coutline + " " + ALLTRIM(afnames1[nindex]) + ":" + ;
                     CMP_VALUES( IIF(xtempf,"T","F"), IIF(FieldGet(nindex),"T","F") )
                // CASE cftypex == "M" && memo handling see above
              ENDCASE
            ENDIF  && field content differs
        ENDIF  && Memo
      NEXT  && for every field
    ENDIF  && New record

    SELECT 1


  * Write result to log file, if record modified
    IF lmodified
    * Count modified records for summary
     ndiffers := ndiffers + 1
    * ... and report differences in log file
      LOGGING(coutline)
    ENDIF  && modified
//   ENDIF && last rec's
    SKIP
 ENDDO  && not EOF



   hwg_MsgInfo("Compare completed." + CHR(10) + ;
  "Number of records read: " + ALLTRIM(STR(ngelesen)) + CHR(10) + ;
  "Number of records differs: " + ALLTRIM(STR(ndiffers)) , "DBF compare result")
  * and into log file ...
  LOGGING(" ")
  LOGGING("Summary:")
  LOGGING("Compare completed.")
  LOGGING("Number of records read: " + ALLTRIM(STR(ngelesen)) )
  LOGGING("Number of records differs: " + ALLTRIM(STR(ndiffers)) )
  * Close databases before return to main window
  CMP_CLOSALL()
RETURN NIL

* ================================================================= *
FUNCTION select_dbffile(cloctext)
* Select a DBF database and return the
* filename choiced. Empty string, if cancelled.
* An array with 2 elements is returned:
* 1: The selected file/database
* 2: The previous directory before the file is choiced.
*    After opening the selected file or database,
*    need to change directory to the previous directory.
* ================================================================= *

LOCAL fname, cstartvz, clocmsk, clocallf, areturn

   * Get current directory as start directory
   cstartvz := hwg_CurDir()

   IF cloctext == NIL
    cloctext := "xBase databases( *.dbf )"
   ENDIF

   clocmsk  := "*.dbf"
   clocallf := "All files"
   areturn := {}

#ifdef __GTK__
   fname := hwg_SelectFileEx(,,{{ cloctext,clocmsk },{ clocallf ,"*"}} )
#else
   fname := hwg_Selectfile(cloctext , clocmsk, cstartvz )
#endif
   * Return to previous directory

   * Check for cancel
   IF EMPTY( fname )
      * action aborted
      RETURN { "" , cstartvz }
   ENDIF
   AADD(areturn,fname)
   AADD(areturn,cstartvz)
RETURN areturn

* ================================================================= *
FUNCTION PWD()
* Returns the current directory with trailing \ or /
* so you can add a file name after the returned value:
* fullpath := PWD() + "FILE.EXT"
* ================================================================= *

LOCAL oDir
#ifdef __PLATFORM__WINDOWS
  * Usage of hwg_CleanPathname() avoids C:\\
  oDir := hwg_CleanPathname(HB_curdrive() + ":\" + Curdir() + "\")
#else
  oDir := hwg_CleanPathname("/"+Curdir()+"/")
#endif

RETURN oDir

* ================================================================= *
FUNCTION LOGGING(cmessage)
* Writes a line into the message log file
* (append mode)
* Fixed name is "dbfcompare.log"
* ================================================================= *
hwg_WriteLog(cmessage,"dbfcompare.log")
RETURN NIL


* ================================================================= *
FUNCTION deleted2char(lgeloescht)
* Returns boolean text of deleted or not deleted
* ================================================================= *
RETURN IIF(lgeloescht,"T","F")


* ================================================================= *
FUNCTION CMP_ALLTR(ctotrim)
* ================================================================= *
#ifdef COMP_ALLTRIM
RETURN ALLTRIM(ctotrim)
#else
RETURN ctotrim
#endif

* ================================================================= *
FUNCTION CMP_VALUES(xval1, xval2)
* ================================================================= *
* Suppress both values, if not define is set
* Depending on data type, the values of xval1 and xval2
* must be converted to type "C".
#ifdef COMP_VALUES
LOCAL coutput
coutput := " >" + CMP_ALLTR(xval1) + "< / >" + CMP_ALLTR(xval2) + "<"
RETURN coutput
#else
RETURN " "
#endif


* ================================================================= *
FUNCTION CMP_CLOSALL()
* Closes the both databases after compare process
* (so make ready for next action)
* ================================================================= *
SELECT 1
USE
SELECT 2
USE
SELECT 1
RETURN NIL


* ----------------------------------------
FUNCTION DEBUG_SEL(ccomment)
* Write DELECT and ALIAS into logfile, if
* debug define is set.
* ccomment: An additional comment, if
* not NIL, written at begin of line.
* ----------------------------------------
#ifdef DEBUG_MODE
IF ccomment == NIL
  ccomment := ""
ENDIF
LOGGING(ccomment + " SELECT : "+ ALLTRIM(STR(SELECT())) + " ALIAS=" + ALIAS() )
#else
 HB_SYMBOL_UNUSED(ccomment)
#endif
RETURN NIL



* ====================== EOF of dbfcompare.prg ======================
