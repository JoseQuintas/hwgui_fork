/*
demotab.prg
show tab

At momment using source code using parts from hwgui tutorial  hwgui/utils/tutorial

*/

#include "hwgui.ch"

FUNCTION DemoTab( lWithDialog, oDlg )

   LOCAL oTab

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demotab.prg" ;
         AT    0, 0 ;
         SIZE  800, 600 ;
         FONT  HFont():Add( "MS Sans Serif",0,-15 ) ;
         BACKCOLOR 16772062
   ENDIF

   @ 30, 30 SAY "demotab.prg" ;
      SIZE 500, 20 ;
      OF oDlg

   @ 30, 60 TAB oTab ;
      ITEMS {} ;
      SIZE  700, 500

   BEGIN PAGE "say" ;
      OF oTab

      DemoSay( .F. )

   END PAGE OF oTab

   BEGIN PAGE "dateselect" ;
      OF oTab

      DemoDateSelect( .F. )

   END PAGE OF oTab

   BEGIN PAGE "combobox" ;
      OF oTab

      DemoCombobox( .F. )

   END PAGE of oTab

   BEGIN PAGE "browse array" ;
      OF oTab

      DemoBrowseArray( .F. )

   END PAGE OF oTab

   BEGIN PAGE "browse dbf" ;
      OF oTab

      DemoBrowseDBF( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "button" ;
      OF oTab

      DemoButton( .F., oTab )

   END PAGE OF oTab

   IF lWithDialog
      // A STATUS PANEL may be used instead of a standard STATUS control
      ADD STATUS PANEL ;
         TO     oDlg ;
         HEIGHT 30 ;
         PARTS  80, 200, 0

      hwg_WriteStatus( oDlg, 1, "all.prg", .F. )
      hwg_WriteStatus( oDlg, 2, hwg_Version(), .F. )
      hwg_WriteStatus( oDlg, 3, "See more on hwgui tutorial", .F. )

      ACTIVATE DIALOG oDlg ;
         CENTER
   ENDIF

   RETURN Nil

// to be external
STATIC FUNCTION DemoSay()

   @ 10, 50 SAY "a text" ;
      SIZE 80, 30

   @ 10, 100 SAY "Need SIZE (*)" ;
      SIZE 300, 30

   RETURN Nil

// to be external
STATIC FUNCTION DemoDateSelect()

   LOCAL oDate

   @ 10, 50 SAY "Date" ;
      SIZE 80, 30

   @ 100, 50 DATESELECT oDate ;
      SIZE 120,28

   RETURN Nil

// to be external
STATIC FUNCTION DemoCombobox()

   LOCAL oCombo1, oCombo2
   LOCAL aComboList  := { "White", "Blue", "Red", "Black" }

#ifndef __PLATFORM__WINDOWS
   @ 10, 50 COMBOBOX oCombo1 ;
      ITEMS aComboList ;
      SIZE  100, 25              // size for GTK

   oCombo2 := Nil // ok, warning -w3 -es2 require value
   (oCombo2)      // ok, warning -w3 -es2 require use
#else
   @ 10, 50 COMBOBOX oCombo1 ;
      ITEMS aComboList ;
      SIZE  100, 100             // size for GTK

   @ 100, 50 COMBOBOX oCombo2 ;
      ITEMS   aComboList ;
      SIZE    100, 100 ;
      EDIT                       // crash on GTK
#endif

   @ 10, 200 SAY "size height include list height on win" ;
      SIZE 300, 30

   RETURN Nil

// to be external
STATIC FUNCTION DemoBrowseArray()

   LOCAL oBrowse
   LOCAL aBrowseList := { ;
      { "Alex",   17, 12600 }, ;
      { "Victor", 42, 1600 }, ;
      { "John",   31, 15000 } }

   @ 10, 30 BROWSE oBrowse ;
      ARRAY ;
      SIZE  450, 250 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   // array stored on browse aArray, and codeblocks using it
   oBrowse:aArray := aBrowseList
   oBrowse:AddColumn( HColumn():New( "Name",  { | v, o | (v), o:aArray[ o:nCurrent, 1 ] }, "C", 16, 0 ) )
   oBrowse:AddColumn( HColumn():New( "Age",   { | v, o | (v), o:aArray[ o:nCurrent, 2 ] }, "N", 6, 0 ) )
   oBrowse:AddColumn( HColumn():New( "Number",{ | v, o | (v), o:aArray[ o:nCurrent, 3 ] }, "N", 8, 0 ) )

   RETURN Nil

// to be external
STATIC FUNCTION DemoButton( lWithDialog, oDlg )

   LOCAL oBtn1, oBtn2, oBtn3
   LOCAL oStyleNormal  := HStyle():New( {16759929,16772062}, 1 )
   LOCAL oStylePressed := HStyle():New( {16759929}, 1,, 3, 0 )
   LOCAL oStyleOver    := HStyle():New( {16759929}, 1,, 2, 12164479 )
   LOCAL aBtn2Style    := { ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 2,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 2, 8421440 ) }

   @ 10, 50 OWNERBUTTON oBtn1 ;
      OF       oDlg ;
      SIZE     60, 24;
      TEXT     "But1" ;
      ON CLICK { || hwg_MsgInfo( "Button 1" ) }

   @ 74, 50 OWNERBUTTON oBtn2 ;
      OF       oDlg ;
      SIZE     60, 24 ;
      TEXT     "But.2" ;
      ON CLICK { || hwg_MsgInfo( "Button 2" ) }
   oBtn2:aStyle := aBtn2Style

   @ 138, 50 OWNERBUTTON oBtn3 ;
      OF       oDlg ;
      SIZE     60, 24 ;
      HSTYLES oStyleNormal, oStylePressed, oStyleOver ;
      TEXT     "But.3" ;
      ON CLICK { || hwg_MsgInfo( "Button 3" ) }

   (lWithDialog) // not used, warning -w3 -es2

   RETURN Nil

* ============================== EOF of demotab.prg ========================
