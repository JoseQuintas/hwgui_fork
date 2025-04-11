*
* HWGUI - Harbour Win32 and Linux (GTK) GUI library
*
* sample.prg
*
* $Id$
*
* Sample for demonstrate the HWGUI debugger
*
* For details read file "readme.eng".
* Copyright 2020 Wilfried Brunken, DF7BE
* https://sourceforge.net/projects/cllog/
*

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No
*
* Summary:
*
* 1.) Set Environment for your preferred compiler
*
* 2.) Build debugger:
*     hbmk2 hwgdebug.hbp
*
* 3.) Build this sample program with -b option, already set in hbp file:
*     hbmk2 sample.hbp
*
* 4,) 2 Alternatives:
*     - Run hwgdebug.exe , load source code and run the exe file from menu.
*     - Run sample.exe, starts also the debugger.
*

#include "hwgui.ch"
// #ifdef __GTK__
// #include "gtk.ch"
// #endif
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

* --------------------------------------------
Function Main
* --------------------------------------------
   Local oMainWindow

   * Some vars to inspect
   LOCAL aArray := { 1 , "2", .T. , 8.3 }
   LOCAL nValue := 1234.5678
   LOCAL cValue := "Teststring"
   LOCAL lValue := .T.
   LOCAL iValie := 1234


   INIT WINDOW oMainWindow MAIN TITLE "Debugger sample program" ;
     AT 0,0 SIZE 600, 500


   MENU OF oMainWindow
      MENU TITLE "&Exit"
        MENUITEM "&Quit" ACTION oMainWindow:Close()
      ENDMENU
      MENU TITLE "&Test"
        MENUITEM "&Get values" ACTION Teste()
      ENDMENU
   ENDMENU


   ACTIVATE WINDOW oMainWindow
Return Nil

FUNCTION Teste
   LOCAL oDlg
   LOCAL cTexto := Space(20), cTexto2 := Space(20), GetList := {}

   INIT DIALOG oDlg ;
    TITLE "Debugger test sample, Function Teste" ;
    AT 0 , 0  SIZE 300, 200

   @ 20 , 20 GET cTexto   SIZE 260, 25
   @ 20 , 80 GET cTexto2  SIZE 260, 25


   @ 20 , 150  BUTTON "OK" SIZE 100, 32 ON CLICK {|| oDlg:Close() }

    ACTIVATE DIALOG oDlg

Return Nil

* ================= EOF of sample.prg =================
