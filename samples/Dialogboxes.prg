/*
 * $Id$
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

 */

#include "hwgui.ch"


FUNCTION Main()

   LOCAL oWinMain

   INIT WINDOW oWinMain ;
      MAIN  ;
      TITLE "Sample program new progbar" ;
      AT 0, 0 ;
      SIZE 600,400;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&File"
          MENUITEM "&Exit"              ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Test"
         MENUITEM "Start test"     ACTION Test()
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oWinMain CENTER

RETURN Nil

FUNCTION Test()

   LOCAL oDlg, oFont, oFontSay, oFontC, oSay3, oSay4, oSay5, oSay6, oSay7, y1 := 50
   LOCAL nChoic, cRes, arr := {"White","Blue","Green","Red"}

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
   PREPARE FONT oFontSay NAME "MS Sans Serif" WIDTH 0 HEIGHT -13 WEIGHT 700
   PREPARE FONT oFontC NAME "Georgia" WIDTH 0 HEIGHT -15

   INIT DIALOG oDlg ;
      TITLE "Standard dialogs" ;
      AT 100, 100 ;
      SIZE 340, 440 ;
      FONT oFont

   @ 20,12 SAY "Press any button to see a dialog" ;
      SIZE 260, 24 ;
      FONT oFontSay ;
      COLOR 8404992

   @ 20,y1 BUTTON "hwg_MsgInfo()" ;
      SIZE 180,28 ;
      ON CLICK {||hwg_MsgInfo("Info dialog","Tutorial")}

   y1 += 30

   @ 20,y1 BUTTON "hwg_MsgStop()" ;
      SIZE 180,28 ;
      ON CLICK {||hwg_MsgStop("Error message","Tutorial")}

   y1 += 30

   @ 20,y1 BUTTON "hwg_MsgYesNo()" ;
      SIZE 180,28 ;
      ON CLICK {||oSay3:SetText( Iif( hwg_MsgYesNo("Do you like it?","Tutorial"), "Yes","No" ) )}

   @ 230,y1 SAY oSay3 ;
      CAPTION "" ;
      SIZE 80,24 ;
      COLOR 8404992

   y1 += 30

   @ 20,y1 BUTTON "hwg_MsgOkCancel()" ;
      SIZE 180,28 ;
      ON CLICK {||hwg_MsgOkCancel("Confirm action","Tutorial")}

   y1 += 30

#ifndef __GTK__
   @ 20,y1 BUTTON "hwg_MsgNoYes()" ;
      SIZE 180,28 ;
      ON CLICK {||oSay4:SetText( Iif( hwg_MsgNoYes("Do you like it?","Tutorial"), "Yes","No" ) )}

   @ 230,y1 SAY oSay4 ;
      CAPTION "" ;
      SIZE 80,24 COLOR 8404992

   y1 += 30

   @ 20,y1 BUTTON "hwg_MsgRetryCancel()" ;
      SIZE 180,28 ;
      ON CLICK {||hwg_MsgRetryCancel("Retry action","Tutorial")}

   y1 += 30
#endif

   @ 20,y1 BUTTON "hwg_MsgYesNoCancel()" ;
      SIZE 180,28 ;
      ON CLICK {||oSay5:SetText( Ltrim(Str(hwg_MsgYesNoCancel("Do you like it?","Tutorial"))) )}

   @ 230,y1 SAY oSay5 CAPTION "" ;
      SIZE 80,24 ;
      COLOR 8404992

   y1 += 30

   @ 20,y1 BUTTON "hwg_MsgExclamation()" ;
      SIZE 180,28 ;
      ON CLICK {||hwg_MsgExclamation("Happy birthday!","Tutorial")}

   y1 += 30

   @ 20,y1 BUTTON "hwg_MsgGet()" ;
      SIZE 180,28 ;
      ON CLICK {||oSay6:SetText( Iif( (cRes := hwg_MsgGet("Input something","Tutorial")) == Nil, "", cRes ) )}

   @ 230,y1 SAY oSay6 ;
      CAPTION "" ;
      SIZE 80,24 ;
      COLOR 8404992

   y1 += 30

   @ 20,y1 BUTTON "hwg_WChoice()" ;
      SIZE 180,28 ;
      ON CLICK {||oSay7:SetText( Iif( (nChoic := hwg_WChoice(arr,"Tutorial",,,oFontC,,,,,"Ok","Cancel")) == 0, "", arr[nChoic] ) )}

   @ 230,y1 SAY oSay7 CAPTION "" ;
      SIZE 80,24 ;
      COLOR 8404992

   @ 20, y1+50 LINE LENGTH 300

   @ 120,oDlg:nHeight-40 BUTTON "Close" ;
      SIZE 100,30 ;
      ON CLICK {||oDlg:Close()}


   ACTIVATE DIALOG oDlg

RETURN Nil

* ============================= EOF of Dialogboxes.prg ===========================
