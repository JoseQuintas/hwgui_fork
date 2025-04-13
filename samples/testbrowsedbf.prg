/*
 * testbrowsedbf.prg
 * browse dbf
*/

#include "hwgui.ch"

#ifdef __USING_MENU__
   FUNCTION TestBrowseDbf( nCont )
#else
   FUNCTION Main( nCont )
#endif

   LOCAL oDlg, oBrowse, aList, aItem

   SET EXCLUSIVE OFF

   hb_Default( @nCont, 1 )

   CreateDBF( "test" )
   USE test

   aList := { ;
      { "Name",   { || field->Name } }, ;
      { "Adress", { || field->Address } } }

   INIT DIALOG oDlg TITLE "TESTBROWSEDBF - BROWSE DBF " + Ltrim( Str( nCont ) ) AT 0,0 SIZE 1024,600


   @ 20,10 BROWSE oBrowse DATABASE SIZE 780, 500 STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   FOR EACH aItem IN aList
      ADD COLUMN aItem[ 2 ] TO oBrowse HEADER aItem[ 1 ] LENGTH 30
   NEXT

   @ 500,540 BUTTON "Close" SIZE 180,36 ;
      ON CLICK { || hwg_EndDialog() } // will close all


   ACTIVATE DIALOG oDlg
   CLOSE DATABASES

   RETURN Nil

STATIC FUNCTION CreateDbf( cFileName )

   LOCAL aList

   IF hb_vfExists( cFileName + ".dbf" )
      RETURN NIL
   ENDIF

   aList := { ;
      { "NAME", "C", 30, 0 }, ;
      { "ADDRESS", "C", 30, 0 } }

   dbCreate( cFileName , aList )

   USE ( cFileName )
   APPEND BLANK
   REPLACE field->name WITH "DBF_AAAA", field->address WITH "DBF_AAAA"
   APPEND BLANK
   REPLACE field->name WITH "DBF_BBBB", field->address WITH "DBF_BBBB"
   APPEND BLANK
   REPLACE field->name WITH "DBF_CCCC", field->address WITH "DBF_CCCC"
   USE

   RETURN NIL
