/*
 * demonice.prg
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

FUNCTION DemoNice( lWithDialog, oDlg, aInitList )

   LOCAL bCode

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demonice.prg - nice button" ;
         SIZE 640, 480 ;
         ON INIT { || Eval( bCode ) }
   ENDIF

   ButtonForSample( "demonice.prg", oDlg )

   bCode := { ||
   @ 100, 100 nicebutton [ola] ;
      of oDlg ;
      ;//id 100 ;
      size 40,40 ;
      red 52  green 10  blue 60 ;
      ON CLICK { || hwg_MsgInfo( "test" ) }

   @ 100, 150 nicebutton [Rafael] ;
      of oDlg ;
      ;//id 101 ;
      size 60,40 ;
      red 215 green 76  blue 108

   @ 300, 150 nicebutton [Culik] ;
      of oDlg ;
      ;//id 102 ;
      size 40,40 ;
      red 136 green 157 blue 234 ;
      on click { || oDlg:Close() }

   @ 100, 200 nicebutton [guimaraes] ;
      of oDlg ;
      ;//id 102 ;
      size 150, 40 ;
      red 198 green 045 blue 215 ;
      on click { || oDlg:Close() }

   @ 300, 200 NICEBUTTON  [NICEBUTT] ;
      OF odlg ;
      ID IDC_1 ;
      SIZE 100, 40  && See demonice.prg

   RETURN Nil
      }

   @ 100, 300 SAY "On DIALOG need to be on INIT, use OWNERBUTTON to best result"

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ELSE
      AAdd( aInitList, bCode )
   ENDIF

RETURN Nil

#include "demo.ch"
* ============================= EOF of demonice.prg ==============================

