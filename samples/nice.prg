/*
 * nice.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library
 *
 *
 * Demo of NICEBUTTON
 * (Windows only)
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * error if used on dialog 2025.04.30 Jose Quintas
 * use OWNERBUTTON
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No

#include "hwgui.ch"

#define DIALOG_1    1
#define IDC_1     101

FUNCTION main()

   LOCAL oDlg

   INIT WINDOW oDlg ;
      MAIN ;
      SIZE 640, 480

   @ 100, 100 nicebutton [ola] ;
      of oDlg ;
      id 100 ;
      size 40,40 ;
      red 52  green 10  blue 60

   @ 100, 150 nicebutton [Rafael] ;
      of oDlg ;
      id 101 ;
      size 60,40 ;
      red 215 green 76  blue 108

   @ 100, 200 nicebutton [Culik] ;
      of oDlg ;
      id 102 ;
      size 40,40 ;
      red 136 green 157 blue 234 ;
      on click { || oDlg:Close() }

   @ 100, 250 nicebutton [guimaraes] ;
      of oDlg ;
      id 102 ;
      size 60,60 ;
      red 198 green 045 blue 215 ;
      on click { || oDlg:Close() }

   @ 100, 300 SAY "Error if used on DIALOG, use OWNERBUTTON"

   ACTIVATE WINDOW oDlg CENTER

RETURN Nil

* ============================= EOF of nice.prg ==============================

