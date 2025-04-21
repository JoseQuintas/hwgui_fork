/*
 demobrowsedbf.prg
 browse dbf

 called from demomenumt.prg
 called from all.prg

*/

#include "hwgui.ch"

FUNCTION DemoBrowseDbf( lWithDialog, oDlg )

   LOCAL oBrowse, aList, aItem

   hb_Default( @lWithDialog, .T. )

   CreateDBF( "test" )
   USE test SHARED

   aList := { ;
      { "Name",   { || field->Name } }, ;
      { "Adress", { || field->Address } } }

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demobrowsedbf.prg - BROWSE DBF" ;
         AT 0,0 ;
         SIZE 800, 600
   ENDIF

   @ 3, 30 SAY "demobrowsedbf.prg" ;
      SIZE 500, 30

   @ 20, 80 BROWSE oBrowse ;
      OF oDlg ;
      DATABASE ;
      SIZE 500, 350 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   oBrowse:oStyleHead := HStyle():New( { 0xffffff, 0xbbbbbb }, 1 )

   FOR EACH aItem IN aList
      ADD COLUMN aItem[ 2 ] TO oBrowse HEADER aItem[ 1 ] LENGTH 30
   NEXT

   @ 500, 450 BUTTON "Browse nCurrent" ;
      SIZE 180,36 ;
      ON CLICK { || hwg_MsgInfo( "Browse Current:" + Ltrim( Str( oBrowse:nCurrent ) ) ) } // will close all

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      CLOSE DATABASES
   ENDIF

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
