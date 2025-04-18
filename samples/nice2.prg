/*
 * nice2.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library
 *
 *  nice2.prg
 *
 * Demo of NICEBUTTON
 * (Windows only)
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * Advice:
 * The better way is to use "@ <x>,<y> OWNERBUTTON",
 * instead of NICEBUTTON and with advantage
 * of multi platform usage !!!!
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No


#include "hwgui.ch"
// #include "nice.h"
// REQUEST hwg_NICEBUTTPROC

#define DIALOG_1    1
#define IDC_1     101

FUNCTION Main()

   LOCAL oWinMain

   INIT WINDOW oWinMain ;
      MAIN  ;
      SYSCOLOR COLOR_3DLIGHT+1 ;
      TITLE "Sample program NICEBUTTON" AT 0, 0 ;
      SIZE 600,400;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&Exit"
         MENUITEM "&Quit"    ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Test"
         MENUITEM "&Start"     ACTION _Testen()
      ENDMENU
   ENDMENU

   //   oWinMain:Activate()
   ACTIVATE WINDOW oWinMain CENTER

RETURN Nil

STATIC FUNCTION _Testen()

   LOCAL odlg
   //LOCAL o1
   LOCAL oFont

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT 8

* from resource DIALOG_1
   INIT DIALOG odlg ;
      TITLE "nice button test" ;
      AT 6, 15 ;
      SIZE 161, 127 ;
      FONT oFont ;
      STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_THICKFRAME + WS_MINIMIZEBOX + WS_MAXIMIZEBOX

// Also bug: The caption of the nicebutton is not visible
//   @ 10 ,10 NICEBUTTON o1 CAPTION "NICEBUTT" OF odlg ID IDC_1 SIZE 40,40
   @ 10 ,10 NICEBUTTON  [NICEBUTT] ;
      OF odlg ;
      ID IDC_1 ;
      SIZE 40,40  && See nice.prg

   * redefine nicebutton o1  caption "teste" of odlg id IDC_1 Red 125 Green 201 blue 36 ;
   *  STYLE WS_CHILD+WS_VISIBLE

//   ACTIVATE DIALOG odlg   && ==> this causes the crash above listed,
//   it is obscure !!!!!
    ACTIVATE WINDOW odlg CENTER

RETURN Nil

/*
Error BASE/1070  Argument error: ==
Called from source\winapi/guimain.prg->(b)HWG_FINDPARENT(52)
Called from ->ASCAN(0)
Called from source\winapi/guimain.prg->HWG_FINDPARENT(52)
Called from source\winapi/guimain.prg->HWG_FINDSELF(73)
Called from source\winapi/hnice.prg->HWG_NICEBUTTPROC(134)
Called from ->HWG_DLGBOXINDIRECT(0)
Called from source\winapi/hdialog.prg->HDIALOG:ACTIVATE(156)
Called from nice2.prg->_TESTEN(72)
Called from nice2.prg->(b)MAIN(46)
Called from source\winapi/hwindow.prg->ONCOMMAND(648)
Called from source\winapi/hwindow.prg->(b)HMAINWINDOW(305)
Called from source\winapi/hwindow.prg->HMAINWINDOW:ONEVENT(411)
Called from ->HWG_ACTIVATEMAINWINDOW(0)
Called from source\winapi/hwindow.prg->HMAINWINDOW:ACTIVATE(400)
Called from nice2.prg->MAIN(50)
*/

/*
DIALOG_1 DIALOG 6, 15, 161, 127
STYLE WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
CAPTION "DIALOG_1"
FONT 8, "MS Sans Serif"
{
 CONTROL "Teste", IDC_1, "NICEBUTT", 0 | WS_CHILD | WS_VISIBLE, 32, 36, 20, 20
}
*/

* ============================ EOF of nice2.prg ===============================
