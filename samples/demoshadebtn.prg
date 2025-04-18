/*
 * $Id: testshadebtn.prg,v 1.1 2006/12/29 10:18:55 alkresin Exp $
 * Shade buttons sample
 *
*/

#include "hwgui.ch"

#ifdef __USING_MENU__
   FUNCTION DemoShadeBtn()
#else
   FUNCTION Main()
#endif

   LOCAL oMainWindow, oFont
   LOCAL oIco1 := HIcon():AddFile("..\image\ok.ico")
   LOCAL oIco2 := HIcon():AddFile("..\image\cancel.ico")

   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT 20 WEIGHT 400

   INIT WINDOW oMainWindow ;
      TITLE "DEMOSHADEBTN - Shade Buttons" ;
      AT 200,0 ;
      SIZE 480,220 ;
      SYSCOLOR COLOR_3DLIGHT+1

   @ 10,10 SHADEBUTTON ;
      SIZE 100,36 ;
      TEXT "Metal" ;
      FONT oFont ;
      EFFECT SHS_METAL PALETTE PAL_METAL

   @ 10,50 SHADEBUTTON ;
      SIZE 100,36 ;
      TEXT "Softbump" ;
      FONT oFont ;
      EFFECT SHS_SOFTBUMP PALETTE PAL_METAL

   @ 10,90 SHADEBUTTON ;
      SIZE 100,36 ;
      TEXT "Noise" ;
      FONT oFont ;
      EFFECT SHS_NOISE  PALETTE PAL_METAL GRANULARITY 33

   @ 10,130 SHADEBUTTON ;
      SIZE 100,36 ;
      TEXT "Hardbump" ;
      FONT oFont ;
      EFFECT SHS_HARDBUMP PALETTE PAL_METAL

   @ 120,10 SHADEBUTTON ;
      SIZE 100,36 ;
      TEXT "HShade" ;
      FONT oFont ;
      EFFECT SHS_HSHADE PALETTE PAL_METAL

   @ 120,50 SHADEBUTTON ;
      SIZE 100,36 ;
      TEXT "VShade" ;
      FONT oFont EFFECT SHS_VSHADE PALETTE PAL_METAL

   @ 120,90 SHADEBUTTON ;
      SIZE 100,36 ;
      TEXT "DiagShade" ;
      FONT oFont ;
      EFFECT SHS_DIAGSHADE  PALETTE PAL_METAL

   @ 120,130 SHADEBUTTON ;
      SIZE 100,36 ;
      TEXT "HBump" ;
      FONT oFont ;
      EFFECT SHS_HBUMP  PALETTE PAL_METAL

   // @ 128,0 GROUPBOX "" SIZE 94,75

   @ 230,10 SHADEBUTTON ;
      SIZE 100,40 ;
      FLAT ;
      BITMAP oIco1 COORDINATES 2,0,0,0 ;
      TEXT "Yes" ;
      COLOR 4259584 ;
      FONT oFont COORDINATES 56,0 ;
      EFFECT SHS_VSHADE  PALETTE PAL_METAL HIGHLIGHT 12

   @ 230,50 SHADEBUTTON ;
      SIZE 100,40 ;
      FLAT ;
      BITMAP oIco2 COORDINATES 2,0,0,0 ;
      EFFECT SHS_VSHADE  PALETTE PAL_METAL HIGHLIGHT 12

   @ 230,90 SHADEBUTTON ;
      SIZE 100,40 ;
      FLAT ;
      EFFECT SHS_VSHADE  PALETTE PAL_METAL HIGHLIGHT 12

   @ 230,130 SHADEBUTTON ;
      SIZE 100,40 ;
      FLAT ;
      TEXT "Flat" ;
      COLOR 4259584 ;
      FONT oFont ;
      EFFECT SHS_VSHADE  PALETTE PAL_METAL HIGHLIGHT 12

   @ 340,10 SHADEBUTTON ;
      SIZE 100,36 ;
      EFFECT SHS_METAL  PALETTE PAL_METAL GRANULARITY 33 ;
      HIGHLIGHT 20 ;
      TEXT "Close" ;
      FONT oFont ;
      ON CLICK {||oMainWindow:Close()}

   @ 340,50 SHADEBUTTON ;
      SIZE 100,36 ;
      EFFECT SHS_SOFTBUMP  PALETTE PAL_METAL GRANULARITY 33 HIGHLIGHT 20

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

