/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  demolistboxsub.prg
 *
 * Sample for substite of listbox usage:
 * Use BROWSE of an array instead for
 * multi platform use.
 *
 * Copyright 2020 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 * Copied from sample "demolistbox.prg".
 */

   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

#include "hwgui.ch"
// #include "listbox.ch"

FUNCTION Main()

   LOCAL oMainWindow

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "DEMOLISTBOXSUB - Listbox substitute" ;
      AT 0,0 ;
      SIZE 600, 400
   // MENUITEM in main menu on GTK/Linux does not start the desired action
   // Submenu needed
   MENU OF oMainWindow
      MENU TITLE "&Exit"
        MENUITEM "&Quit" ACTION oMainWindow:Close()
      ENDMENU
      MENU TITLE "&Teste"
        MENUITEM "&Do it" ACTION Teste()
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

STATIC FUNCTION Teste()

   LOCAL oModDlg, oFont, obrowsbox1, nPosi, cResult
   LOCAL oList, oItemso := { { "Item01" } , { "Item02" } , { "Item03" } , { "Item04" } }
   // Array oItemso is a 2 dimensional array with one "column".

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
   PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12 && vorher 13
#endif

   INIT DIALOG oModDlg ;
      TITLE "Test"  ;
      AT 0,0  ;
      SIZE 450,350   ;
      FONT oFont

   // Please dimensionize size of BROWSE window so that it is enough space to display
   // all items in oItemso with additional reserve about 20 pixels.
   @ 34,56  BROWSE obrowsbox1  ARRAY oList SIZE 210, 220 FONT oFont  ;
      STYLE WS_BORDER  // NO VSCROLL
   obrowsbox1:aArray := ConvItems( oItemso ) // Fill browse box with all items
   obrowsbox1:AddColumn( HColumn():New( "Listbox", { | v, o | (v), o:aArray[ o:nCurrent, 1 ]}, "C", 10, 0 ) )
   obrowsbox1:lEditable := .F.
   obrowsbox1:lDispHead := .F. // No Header
   obrowsbox1:active := .T.

   @  10,280 BUTTON "Ok" ;
      ID IDOK  ;
      SIZE 50, 32

   ACTIVATE DIALOG oModDlg CENTER

   oFont:Release()

   // Get result
   nPosi   := obrowsbox1:nCurrent
   cResult := obrowsbox1:aArray[ nPosi, 1 ]
   // show result
   hwg_msgInfo("Position: " + STR( nPosi ) + " Value: " + cResult, "Result of Listbox selection" )

   IF oModDlg:lResult
   ENDIF

RETURN Nil

STATIC FUNCTION ConvItems( ap )
* areal value, not a pointer

   LOCAL a

   a := ap

RETURN a

* ==================== EOF of demolistboxsub.prg =========================
