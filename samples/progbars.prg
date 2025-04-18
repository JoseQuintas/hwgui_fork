/*
 * $Id: progbars.prg,v 1.2 2006/06/15 06:06:06 alkresin Exp $
 *
 * HWGUI - Harbour Win32 GUI library
 * Sample of using HProgressBar class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
*/

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes  ==> other sample
    *  GTK/Win  :  Yes  ==> other sample

#include "hwgui.ch"

STATIC oMain, oForm, oFont, oBar := Nil

FUNCTION Main()

   INIT WINDOW oMain ;
      MAIN ;
      TITLE "Progress Bar Sample"

   MENU OF oMain
      MENUITEM "&Exit" ACTION oMain:Close()
      MENUITEM "&Demo" ACTION Test()
   ENDMENU

   ACTIVATE WINDOW oMain CENTER // MAXIMIZED

RETURN Nil

FUNCTION Test()

   LOCAL cMsgErr := "Bar doesn't exist"

   PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

   INIT DIALOG oForm ;
      CLIPPER ;
      NOEXIT ;
      TITLE "Progress Bar Demo" ;
      FONT oFont ;
      AT 0, 0 ;
      SIZE 700, 425 ;
      STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU ;
      ON EXIT { || Iif( oBar == Nil, .T., ( oBar:Close(),.T. ) ) }

      @ 300, 395 BUTTON 'Reset Bar'  ;
         SIZE 75,25 ;
         ON CLICK { || Iif( oBar == Nil, hwg_Msgstop( cMsgErr ), oBar:Reset() ) }

      @ 380, 395 BUTTON 'Step Bar'   ;
         SIZE 75,25 ;
         ON CLICK { || Iif(oBar == Nil, hwg_Msgstop( cMsgErr ), oBar:Step() ) }

      @ 460, 395 BUTTON 'Create Bar' ;
         SIZE 75,25 ;
         ON CLICK { || oBar := HProgressBar():NewBox( "Testing ...",,,,, 10, 100 ) }

      @ 540, 395 BUTTON 'Close Bar'  ;
         SIZE 75,25 ;
         ON CLICK { || Iif( oBar == Nil, hwg_Msgstop( cMsgErr ), ( oBar:Close(), oBar := Nil ) ) }

      @ 620, 395 BUTTON 'Close'      ;
         SIZE 75,25 ;
         ON CLICK { || oForm:Close() }

      ACTIVATE DIALOG oForm

RETURN Nil

* ============================= EOF of progbars.prg =============================
