/*
 demobrowsedbf.prg
 browse dbf

 moved from demobrowseado.prg Itamar Lins

 called from demomenumt.prg
 called from demoall.prg
 called from demotab.prg

note:
oDlg may be a dialog or a tab page
*/

#include "hwgui.ch"

FUNCTION DemoBrowseDbf( lWithDialog, oDlg, aExitList )

   LOCAL oBrowse, aList, aItem

   hb_Default( @lWithDialog, .T. )
   hb_Default( @aExitList, {} )

   SELECT ( Select( "browsedbf" ) ) // if already open
   USE
   CreateDBF( "tmpbrowsedbf" )
   USE tmpbrowsedbf SHARED ALIAS browsedbf

   aList := { ;
      { "Name",   { || browsedbf->Name } }, ;
      { "Adress", { || browsedbf->Address } } }

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demobrowsedbf.prg - BROWSE DBF" ;
         AT 0,0 ;
         SIZE 800, 600
   ENDIF

// on demo.ch
   ButtonForSample( "demobrowsedbf.prg", oDlg )

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
      fErase( "tmpbrowsedbf.dbf" )
   ELSE
      AAdd( aExitList, { || fErase( "tmpbrowsedbf.dbf" ) } )
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

// show buttons and source code
#include "demo.ch"
