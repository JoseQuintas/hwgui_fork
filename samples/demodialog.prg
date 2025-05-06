/*
 * $Id$
 *
 * ( Harbour + HWGUI )
 *
 * Main file
 *
 * Copyright 2019 DF7BE
 * www - http://www.z02.de
 *
 * Status:
 *  WinAPI   :  Yes
 *  GTK/Linux:  Yes
 *  GTK/Win  :  Yes
*/

#include "hwgui.ch"

FUNCTION DemoDialog( lWithDialog, oDlg )

#ifndef __GTK__
   hwg_Settooltipballoon(.t.)
#endif

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demodialog.prg - Default title"  ;
         AT 200,100 ;
         SIZE 800, 600
         // ON EXIT { || hwg_MsgYesNo("OK to quit ?" ) }
   ENDIF

   ButtonForSample( "demodialog.prg" )

   @ 30, 100 BUTTON "Change title" ;
      SIZE 100, 24 ;
      ON CLICK { || Dialog1() }

   @ 150, 100 BUTTON "BackColor" ;
      SIZE 100, 24 ;
      ON CLICK { || Dialog2() }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

// modifying title

STATIC FUNCTION Dialog1()

   LOCAL oDlg

   INIT DIALOG oDlg ;
      TITLE "change title"  ;
      AT 0, 0 ;
      SIZE 500, 500

   @ 30, 100 BUTTON "Title to new test" ;
      SIZE 100, 24 ;
      ON CLICK { || oDlg:SetTitle( "Title changed to new test" ) }

   @ 30, 150 BUTTON "previous title" ;
      SIZE 100, 24 ;
      ON CLICK { || oDlg:SetTitle( "change title" ) }

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil

// backcolor

STATIC FUNCTION Dialog2()

   LOCAL oDlg

   INIT DIALOG oDlg ;
      TITLE "change title"  ;
      AT 0, 0 ;
      SIZE 500, 500 ;
      BACKCOLOR 16772062 ;
      ON EXIT { || hwg_MsgYesNo( "OK to quit ?" ) }

   @ 30, 100 BUTTON "Title to new test" ;
      SIZE 100, 24 ;
      ON CLICK { || oDlg:SetTitle( "Title changed to new test" ) }

   @ 30, 150 BUTTON "previous title" ;
      SIZE 100, 24 ;
      ON CLICK { || oDlg:SetTitle( "change title" ) }

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil

#include "demo.ch"

* ======== EOF of demodialog.prg =============
