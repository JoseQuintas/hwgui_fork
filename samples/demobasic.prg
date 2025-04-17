/*
Source code using parts from hwgui tutorial  hwgui/utils/tutorial

on source code, divide commands on more lines to a best view of parameters/options
*/

#include "hwgui.ch"

#ifdef __GTK__
   #include "gtk.ch"
#endif

FUNCTION Main()


   LOCAL oTab, oDlg, oBtn1, oBtn2, oBtn3, oBrowse, oDate, oCombo
   LOCAL aComboList  := { "White", "Blue", "Red", "Black" }
   LOCAL aBrowseList := { ;
      { "Alex",   17, 12600 }, ;
      { "Victor", 42, 1600 }, ;
      { "John",   31, 15000 } }

#ifndef __PLATFORM__WINDOWS
   LOCAL oCombo2
#endif

   INIT DIALOG oDlg TITLE "demobasic.prg" ;
      AT    0, 0 ;
      SIZE  600, 400 ;
      FONT  HFont():Add( "MS Sans Serif",0,-15 )
      // STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_CAPTION + WS_SYSMENU

   @ 0, 10 OWNERBUTTON oBtn1 ;
      OF       oDlg ;
      SIZE     60, 24;
      TEXT     "But1" ;
      ON CLICK { || hwg_MsgInfo( "Button 1" ) }

   @ 64, 10 OWNERBUTTON oBtn2 ;
      OF       oDlg ;
      SIZE     60, 24 ;
      TEXT     "Values" ;
      ON CLICK { || ShowValues( oBrowse, oDate, oCombo ) }

   @ 128, 10 OWNERBUTTON oBtn3 ;
      OF       oDlg ;
      SIZE     60, 24 ;
      TEXT      "Exit" ;
      ON CLICK { || oDlg:Close() }

   @ 30, 50 TAB oTab ;
      ITEMS {} ;
      SIZE  500, 300

   BEGIN PAGE "say" ;
      OF oTab

      @ 10, 50 SAY "a text" ;
         SIZE 80, 30

      @ 10, 100 SAY "Need SIZE (*)" ;
         SIZE 300, 30

   END PAGE OF oTab

   BEGIN PAGE "dateselect" ;
      OF oTab

      @ 10, 50 SAY "Date" ;
         SIZE 80, 30

      @ 100, 50 DATESELECT oDate ;
         SIZE 120,28

   END PAGE OF oTab

   BEGIN PAGE "combobox" ;
      OF oTab

#ifndef __PLATFORM__WINDOWS
      @ 10, 50 COMBOBOX oCombo ;
         ITEMS aComboList ;
         SIZE  100, 25              // size for GTK
#else
      @ 10, 50 COMBOBOX oCombo ;
         ITEMS aComboList ;
         SIZE  100, 100             // size for GTK

      @ 100, 50 COMBOBOX oCombo ;
         ITEMS   aComboList ;
         SIZE    100, 100 ;
         EDIT                       // crash on GTK
#endif

      @ 10, 200 SAY "size height include list height on win" ;
         SIZE 300, 30

   END PAGE OF oTab

   BEGIN PAGE "browse array" ;
      OF oTab

      @ 10, 30 BROWSE oBrowse ARRAY ;
         SIZE  450, 250 ;
         STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

      // array stored on browse aArray, and codeblocks using it
      oBrowse:aArray := aBrowseList
      oBrowse:AddColumn( HColumn():New( "Name",  { | v, o | (v), o:aArray[ o:nCurrent, 1 ] }, "C", 16, 0 ) )
      oBrowse:AddColumn( HColumn():New( "Age",   { | v, o | (v), o:aArray[ o:nCurrent, 2 ] }, "N", 6, 0 ) )
      oBrowse:AddColumn( HColumn():New( "Number",{ | v, o | (v), o:aArray[ o:nCurrent, 3 ] }, "N", 8, 0 ) )

   END PAGE OF oTab

   // A STATUS PANEL may be used instead of a standard STATUS control
   ADD STATUS PANEL ;
      TO     oDlg ;
      HEIGHT 30 ;
      PARTS  80, 200, 0

   hwg_WriteStatus( oDlg, 1, "hello", .F. )
   hwg_WriteStatus( oDlg, 2, hwg_Version(), .F. )
   hwg_WriteStatus( oDlg, 3, "See more on hwgui tutorial", .F. )

   ACTIVATE DIALOG oDlg ;
      CENTER

   RETURN Nil

STATIC FUNCTION ShowValues( oBrowse, oDate, oCombo )

   hwg_MsgInfo( ;
      "oBrowse:nCurrent " + Ltrim( Str( oBrowse:nCurrent ) ) + hb_Eol() + ;
      "oDate:Value " + Transform( oDate:Value, "" ) + hb_Eol() + ;
      "oCombo:Value " + Ltrim( Str( oCombo:Value ) ) ;
      )

   RETURN Nil

* ============================== EOF of demobasic.prg ========================
