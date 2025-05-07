/*
demobrowsearray.prg
*/

#include "hwgui.ch"

FUNCTION DemoBrowseArray( lWithDialog, oDlg )

   LOCAL oBrowse
   LOCAL aBrowseList := { ;
      { "Alex",   17, 12600 }, ;
      { "Victor", 42, 1600 }, ;
      { "John",   31, 15000 } }

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demoall.prg - Show Samples on screen, and others on menu" ;
         AT 0,0 ;
         SIZE 1024, 768 ;
         BACKCOLOR 16772062 ;
         STYLE WS_POPUP + WS_CAPTION + WS_MAXIMIZEBOX + WS_MINIMIZEBOX + WS_SYSMENU
   ENDIF

   ButtonForSample( "demobrowsearray.prg" )

   @ 30, 100 BROWSE oBrowse ;
      ARRAY ;
      SIZE  450, 250 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   // array stored on browse aArray, and codeblocks using it
   oBrowse:aArray := aBrowseList
   oBrowse:AddColumn( HColumn():New( "Name",  { | v, o | (v), o:aArray[ o:nCurrent, 1 ] }, "C", 16, 0 ) )
   oBrowse:AddColumn( HColumn():New( "Age",   { | v, o | (v), o:aArray[ o:nCurrent, 2 ] }, "N", 6, 0 ) )
   oBrowse:AddColumn( HColumn():New( "Number",{ | v, o | (v), o:aArray[ o:nCurrent, 3 ] }, "N", 8, 0 ) )

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

   RETURN Nil

// end of source code
#include "demo.ch"
