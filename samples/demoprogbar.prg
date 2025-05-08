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

FUNCTION DemoProgbar( lWithDialog, oDlg, aEndList )

   LOCAL oFont, oBar := Nil
   LOCAL cMsgErr := "Bar doesn't exist"

   hb_Default( @lWithDialog, .T. )

   PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

   IF lWithDialog
      INIT DIALOG oDlg ;
         CLIPPER ;
         NOEXIT ;
         TITLE "demoprogbar.prg - Progress Bar Demo" ;
         FONT oFont ;
         AT 0, 0 ;
         SIZE 700, 425 ;
         STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU ;
         ON EXIT { || Iif( oBar == Nil, .T., ( oBar:Close(),.T. ) ) }
   ELSE
      AAdd( aEndList, { || Iif( oBar == Nil, Nil, oBar:Close() ) } )
   ENDIF

   ButtonForSample( "demoprogbar.prg", oDlg )

    @ 300, 395 BUTTON 'Reset Bar'  ;
      SIZE 75, 25 ;
      ON CLICK { || Iif( oBar == Nil, hwg_Msgstop( cMsgErr ), oBar:Reset() ) }

   @ 380, 395 BUTTON 'Step Bar'   ;
      SIZE 75, 25 ;
      ON CLICK { || Iif( oBar == Nil, hwg_Msgstop( cMsgErr ), oBar:Step() ) }

   @ 460, 395 BUTTON 'Create Bar' ;
      SIZE 75, 25 ;
      ON CLICK { || oBar := HProgressBar():NewBox( "Testing ...",,,,, 10, 100 ) }

   @ 540, 395 BUTTON 'Close Bar'  ;
      SIZE 75, 25 ;
      ON CLICK { || Iif( oBar == Nil, hwg_Msgstop( cMsgErr ), ( oBar:Close(), oBar := Nil ) ) }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

#include "demo.ch"

* ============================= EOF of demoprogbar.prg =============================
