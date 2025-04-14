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
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No

#include "hwgui.ch"

#define DIALOG_1    1
#define IDC_1     101

FUNCTION main()

   LOCAL o

   INIT WINDOW o MAIN

   @   1,2 nicebutton [ola]        of o id 100 size 40,40 red 52  green 10  blue 60
   @ 50,20 nicebutton [Rafael]     of o id 101 size 60,40 red 215 green 76  blue 108
   @ 80,40 nicebutton [Culik]      of o id 102 size 40,40 red 136 green 157 blue 234 on click {||hwg_EndWindow()}
   @ 80,80 nicebutton [guimaraes]  of o id 102 size 60,60 red 198 green 045 blue 215 on click {||hwg_EndWindow()}
   ACTIVATE WINDOW o CENTER

RETURN Nil

* ============================= EOF of nice.prg ==============================

