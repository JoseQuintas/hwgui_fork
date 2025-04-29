/*
 * $Id$ demodlgbox.prg
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 * This sample demonstrates few ready to use dialog boxes
 *
 * Copyright 2006 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Copyright 2021 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

/*

   It is an extract vom the tutorial:
   ==> Getting started / Standard dialogs
   
  April 2025: Bugfix on LINUX:
  ../samples/demo.ch(7) Warning W0003  Variable 'OSAY4' declared but not used in function
  'DEMODLGBOX(32)'

 */

#include "hwgui.ch"


FUNCTION DemoDlgBox( lWithDialog, oDlg )

   LOCAL oFont, oFontC, oSay3, oSay5, oSay6, oSay7
   LOCAL nChoic, cRes, arr := {"White","Blue","Green","Red"}
   
#ifndef __GTK__   
   LOCAL oSay4
#endif   

   hb_Default( @lWithDialog, .T. )

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
   PREPARE FONT oFontC NAME "Georgia" WIDTH 0 HEIGHT -15

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demodlgbox.prg - Standard dialogs" ;
         AT 100, 100 ;
         SIZE 640, 480 ;
         FONT oFont
   ENDIF

   ButtonForSample( "demodlgbox.prg" )

   @ 20, 100 BUTTON "hwg_MsgInfo()" ;
      SIZE 180,28 ;
      ON CLICK {||hwg_MsgInfo("Info dialog","Tutorial")}

   @ 20, 160 BUTTON "hwg_MsgYesNo()" ;
      SIZE 180,28 ;
      ON CLICK {||oSay3:SetText( Iif( hwg_MsgYesNo("Do you like it?","Tutorial"), "Yes","No" ) )}

   @ 230, 160 SAY oSay3 ;
      CAPTION "" ;
      SIZE 80,24 ;
      COLOR 8404992

#ifndef __GTK__
   @ 20, 220 BUTTON "hwg_MsgNoYes()" ;
      SIZE 180,28 ;
      ON CLICK {||oSay4:SetText( Iif( hwg_MsgNoYes("Do you like it?","Tutorial"), "Yes","No" ) )}

   @ 230, 220 SAY oSay4 ;
      CAPTION "" ;
      SIZE 80,24 COLOR 8404992
#endif

   @ 20, 280 BUTTON "hwg_MsgYesNoCancel()" ;
      SIZE 180, 28 ;
      ON CLICK {||oSay5:SetText( Ltrim(Str(hwg_MsgYesNoCancel("Do you like it?","Tutorial"))) )}

   @ 230, 280 SAY oSay5 CAPTION "" ;
      SIZE 80, 24 ;
      COLOR 8404992

   @ 20, 340 BUTTON "hwg_MsgGet()" ;
      SIZE 180, 28 ;
      ON CLICK {||oSay6:SetText( Iif( (cRes := hwg_MsgGet("Input something","Tutorial")) == Nil, "", cRes ) )}

   @ 230, 340 SAY oSay6 ;
      CAPTION "" ;
      SIZE 80, 24 ;
      COLOR 8404992

   @ 300, 100 BUTTON "hwg_MsgStop()" ;
      SIZE 180,28 ;
      ON CLICK {||hwg_MsgStop("Error message","Tutorial")}

   @ 300, 160 BUTTON "hwg_MsgOkCancel()" ;
      SIZE 180,28 ;
      ON CLICK {||hwg_MsgOkCancel("Confirm action","Tutorial")}

   @ 300, 220 BUTTON "hwg_MsgExclamation()" ;
      SIZE 180, 28 ;
      ON CLICK {||hwg_MsgExclamation("Happy birthday!","Tutorial")}

#ifndef __GTK__
   @ 300, 280 BUTTON "hwg_MsgRetryCancel()" ;
      SIZE 180,28 ;
      ON CLICK {||hwg_MsgRetryCancel("Retry action","Tutorial")}
#endif

   @ 300, 340 BUTTON "hwg_WChoice()" ;
      SIZE 180, 28 ;
      ON CLICK {||oSay7:SetText( Iif( (nChoic := hwg_WChoice(arr,"Tutorial",,,oFontC,,,,,"Ok","Cancel")) == 0, "", arr[nChoic] ) )}

   @ 500, 340 SAY oSay7 CAPTION "" ;
      SIZE 80, 24 ;
      COLOR 8404992

   @ 20, 430 LINE LENGTH 300

IF lWithDialog
   ACTIVATE DIALOG oDlg CENTER
ENDIF

RETURN Nil

#include "demo.ch"

* ============================= EOF of demodlgbox.prg ===========================
