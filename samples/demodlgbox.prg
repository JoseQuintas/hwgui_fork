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

STATIC nColPos, nRowPos // do not initialize values here

FUNCTION DemoDlgBox( lWithDialog, oDlg )

   LOCAL oFont, oFontC, arr := { "White","Blue","Green","Red" }

   hb_Default( @lWithDialog, .T. )

   // do not initialize on STATIC declaration
   nRowPos := -1
   nColPos := -1

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
   PREPARE FONT oFontC NAME "Georgia" WIDTH 0 HEIGHT -15

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demodlgbox.prg - Standard dialogs" ;
         AT 100, 100 ;
         SIZE 800, 600 ;
         FONT oFont
   ENDIF

   ButtonForSample( "demodlgbox.prg" )

   @ ColPos(), nRowPos BUTTON "hwg_MsgInfo()" ;
      SIZE 180,28 ;
      ON CLICK { || hwg_MsgInfo("Info dialog","Tutorial" ) }

   @ ColPos(), nRowPos BUTTON "hwg_MsgYesNo()" ;
      SIZE 180,28 ;
      ON CLICK { |xValue| ;
         xValue := hwg_MsgYesNo( "Do you like it?","Tutorial" ), ;
         hwg_MsgInfo( "Value: " + hb_ValToExp( xValue ) ) }

#ifndef __GTK__
   @ ColPos(), nRowPos BUTTON "hwg_MsgNoYes()" ;
      SIZE 180,28 ;
      ON CLICK { |xValue| ;
         xValue := hwg_MsgNoYes( "Do you like it?", "Tutorial" ), ;
         hwg_MsgInfo( "Value: " + hb_ValToExp( xValue ) ) }
#endif

   @ ColPos(), nRowPos BUTTON "hwg_MsgYesNoCancel()" ;
      SIZE 180, 28 ;
      ON CLICK { |xValue| ;
         xValue := hwg_MsgYesNoCancel( "Do you like it?", "Tutorial" ), ;
         hwg_MsgInfo( "Value: " + hb_ValToExp( xValue ) ) }


   @ ColPos(), nRowPos BUTTON "hwg_MsgGet()" ;
      SIZE 180, 28 ;
      ON CLICK { |xValue| ;
         xValue := hwg_MsgGet( "Input something","Tutorial" ), ;
         hwg_MsgInfo( "Value: " + hb_ValToExp( xValue ) ) }

   @ ColPos(), nRowPos BUTTON "hwg_MsgStop()" ;
      SIZE 180,28 ;
      ON CLICK { || hwg_MsgStop( "Error message", "Tutorial" ) }

   @ ColPos(), nRowPos BUTTON "hwg_MsgOkCancel()" ;
      SIZE 180, 28 ;
      ON CLICK { || hwg_MsgOkCancel("Confirm action","Tutorial" ) }

   @ ColPos(), nRowPos BUTTON "hwg_MsgExclamation()" ;
      SIZE 180, 28 ;
      ON CLICK { || hwg_MsgExclamation( "Happy birthday!", "Tutorial" ) }

#ifndef __GTK__
   @ ColPos(), nRowPos BUTTON "hwg_MsgRetryCancel()" ;
      SIZE 180,28 ;
      ON CLICK { |xValue| ;
         xValue := hwg_MsgRetryCancel( "Retry action", "Tutorial" ), ;
         hwg_MsgInfo( "Value: " + hb_ValToExp( xValue ) ) }
#endif

   @ ColPos(), nRowPos BUTTON "hwg_WChoice()" ;
      SIZE 180, 28 ;
      ON CLICK { |xValue| ;
         xValue := hwg_WChoice( arr, "Tutorial",,,oFontC,,,,,"Ok","Cancel" ), ;
         hwg_MsgInfo( "xValue: " +  hb_ValToExp( xValue ) + hb_Eol() + ;
         " arr[ xValue ]: " + hb_ValToExp( arr[ xValue ] ) ) }

#ifdef __PLATFORM__WINDOWS
      #define DEMO_SHOW_MODAL .T.
#else
      #define DEMO_SHOW_MODAL .F.
#endif
   #define DEMO_SHOW_TEXT "this will a ready to use dialog"

   @ ColPos(), nRowPos BUTTON "hwg_ShowHelp()" ;
      SIZE 180, 28 ;
      ON CLICK { || hwg_ShowHelp( DEMO_SHOW_TEXT, "demo", "Close", , DEMO_SHOW_MODAL ) }

   @ ColPos(), nRowPos BUTTON "hwg_MsgGet()" ;
      SIZE 180, 28 ;
      ON CLICK { |xValue| ;
         xValue := hwg_MsgGet( "Input something","Tutorial" ), ;
         hwg_MsgInfo( "Value: " + hb_ValToExp( xValue ) ) }

   @ ColPos(), nRowPos BUTTON "hwg_SelectFile()" ;
      SIZE 180, 28 ;
      ON CLICK { |xValue| ;
         xValue := hwg_SelectFile( "Select File", "*.prg", hb_cwd() ), ;
         hwg_MsgInfo( "Value: " + hb_ValToExp( xValue ) ) }

#ifdef __GTK__
   @ ColPos(), nRowPos BUTTON "hwg_SelectFileEx()" ;
      SIZE 180, 28 ;
      ON CLICK { |xValue| ;
         xValue := hwg_SelectFileEx( ,,{{ "Select File", "*.prg", { hb_cwd(), "*" }} ), ;
         hwg_MsgInfo( "Value: " + hb_ValToExp( xValue ) ) }
#else
   @ ColPos(), nRowPos BUTTON "hwg_SaveFile()" ;
      SIZE 180, 28 ;
      ON CLICK { |xValue| ;
         xValue := hwg_SaveFile( "Enter filename", "Test text", "*.txt", hb_cwd(), "Save File" ), ;
         hwg_MsgInfo( "Value: " + hb_ValToExp( xValue ) ) }
#endif

   @ ColPos(), nRowPos BUTTON "hwg_SelectFolder()" ;
      SIZE 180, 28 ;
      ON CLICK { |xValue| ;
         xValue := hwg_SelectFolder( "Select folder" ), ;
         hwg_MsgInfo( "Value: " + hb_ValToExp( xValue ) ) }

IF lWithDialog
   ACTIVATE DIALOG oDlg CENTER
ENDIF

RETURN Nil

STATIC FUNCTION ColPos()

   IF nColPos == -1
      nColPos := 20
      nRowPos := 100
   ELSE
      nColPos += 250
      IF nColPos > 700
         nColPos := 20
         nRowPos += 50
      ENDIF
   ENDIF

   RETURN nColPos

#include "demo.ch"

* ============================= EOF of demodlgbox.prg ===========================
