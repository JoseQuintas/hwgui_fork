/*
 * $Id: testshadebtn.prg,v 1.1 2006/12/29 10:18:55 alkresin Exp $
 * Shade buttons sample
 *
*/

#include "hwgui.ch"
#include "sampleinc.ch"

#ifndef __PLATFORM__WINDOWS
   FUNCTION DemoShadeBtn()

      hwg_MsgInfo( "Available on Windows only" )

      RETURN Nil
#else
FUNCTION DemoShadeBtn( lWithDialog, oDlg )

   LOCAL oFont
   LOCAL oIco1 := HIcon():AddFile( SAMPLE_IMAGEPATH + "ok.ico")
   LOCAL oIco2 := HIcon():AddFile( SAMPLE_IMAGEPATH + "cancel.ico")

   hb_Default( @lWithDialog, .T. )

   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT 20 WEIGHT 400

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demoshadebtn.prg - Shade Buttons" ;
         AT 0, 0 ;
         SIZE 600, 400
         // SYSCOLOR COLOR_3DLIGHT+1
   ENDIF

// on demo.ch
   ButtonForSample( "demoshadebtn.prg", oDlg )

   @ 10, 60 SHADEBUTTON ;
      SIZE  100, 36 ;
      TEXT  "Metal" ;
      FONT  oFont ;
      EFFECT SHS_METAL PALETTE PAL_METAL

   @ 10, 100 SHADEBUTTON ;
      SIZE 100, 36 ;
      TEXT "Softbump" ;
      FONT oFont ;
      EFFECT SHS_SOFTBUMP PALETTE PAL_METAL

   @ 10, 140 SHADEBUTTON ;
      SIZE 100, 36 ;
      TEXT "Noise" ;
      FONT oFont ;
      EFFECT SHS_NOISE  PALETTE PAL_METAL GRANULARITY 33

   @ 10, 180 SHADEBUTTON ;
      SIZE 100, 36 ;
      TEXT "Hardbump" ;
      FONT oFont ;
      EFFECT SHS_HARDBUMP PALETTE PAL_METAL

   @ 120, 60 SHADEBUTTON ;
      SIZE 100, 36 ;
      TEXT "HShade" ;
      FONT oFont ;
      EFFECT SHS_HSHADE PALETTE PAL_METAL

   @ 120, 100 SHADEBUTTON ;
      SIZE 100, 36 ;
      TEXT "VShade" ;
      FONT oFont EFFECT SHS_VSHADE PALETTE PAL_METAL

   @ 120, 140 SHADEBUTTON ;
      SIZE 100, 36 ;
      TEXT "DiagShade" ;
      FONT oFont ;
      EFFECT SHS_DIAGSHADE  PALETTE PAL_METAL

   @ 120, 180 SHADEBUTTON ;
      SIZE 100, 36 ;
      TEXT "HBump" ;
      FONT oFont ;
      EFFECT SHS_HBUMP  PALETTE PAL_METAL

   // @ 128,0 GROUPBOX "" SIZE 94,75

   @ 230, 60 SHADEBUTTON ;
      SIZE 100, 40 ;
      FLAT ;
      BITMAP oIco1 COORDINATES 2,0,0,0 ;
      TEXT "Yes" ;
      COLOR 4259584 ;
      FONT oFont COORDINATES 56,0 ;
      EFFECT SHS_VSHADE  PALETTE PAL_METAL HIGHLIGHT 12

   @ 230, 100 SHADEBUTTON ;
      SIZE 100, 40 ;
      FLAT ;
      BITMAP oIco2 COORDINATES 2,0,0,0 ;
      EFFECT SHS_VSHADE  PALETTE PAL_METAL HIGHLIGHT 12

   @ 230, 140 SHADEBUTTON ;
      SIZE 100, 40 ;
      FLAT ;
      EFFECT SHS_VSHADE  PALETTE PAL_METAL HIGHLIGHT 12

   @ 230, 180 SHADEBUTTON ;
      SIZE 100, 40 ;
      FLAT ;
      TEXT "Flat" ;
      COLOR 4259584 ;
      FONT oFont ;
      EFFECT SHS_VSHADE  PALETTE PAL_METAL HIGHLIGHT 12

   @ 340, 60 SHADEBUTTON ;
      SIZE 100, 36 ;
      EFFECT SHS_METAL  PALETTE PAL_METAL GRANULARITY 33 ;
      HIGHLIGHT 20 ;
      TEXT "Close" ;
      FONT oFont ;
      ON CLICK { || iif( lWithDialog, oDlg:Close(), hwg_MsgInfo( "No action here" ) ) }

   @ 340, 100 SHADEBUTTON ;
      SIZE 100, 36 ;
      EFFECT SHS_SOFTBUMP  PALETTE PAL_METAL GRANULARITY 33 HIGHLIGHT 20

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil
#endif

// show buttons and source code
#include "demo.ch"
