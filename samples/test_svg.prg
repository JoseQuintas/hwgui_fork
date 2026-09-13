/*
 * demo_svg.prg - SVG demo with menu, using static BITMAP controls.
 * Works on HWGui 2.23 where bPaint of HMainWindow is not honored.
 *
 * Build: hbmk2 demo_svg.prg C:\dev\hwgui\hwgui.hbp C:\dev\hwgui\svg.hbc
 */

#include "hwgui.ch"

#define WIN_W      800
#define WIN_H      600
#define SVG_LOGO   "..\image\svg\hwgui.svg"
#define SVG_TEST   "..\image\svg\info.svg"

STATIC oMain
STATIC oImgLogo, oImgTest
STATIC oFont
STATIC oLogoCtrl, oTestCtrl

FUNCTION Main()

   LOCAL hSvg

   PREPARE FONT oFont NAME "Segoe UI" WIDTH 0 HEIGHT -11 WEIGHT 400

   /* ---- Load the SVGs ---- */
   hSvg := hwg_LoadSvg( SVG_LOGO, 400, 215 )
   IF ! Empty( hSvg )
      oImgLogo := HBitmap():New()
      oImgLogo:AddHandle( hSvg )
   ELSE
      hwg_MsgInfo( "Failed to load: " + SVG_LOGO )
   ENDIF

   hSvg := hwg_LoadSvg( SVG_TEST, 200, 200 )
   IF ! Empty( hSvg )
      oImgTest := HBitmap():New()
      oImgTest:AddHandle( hSvg )
   ELSE
      hwg_MsgInfo( "Failed to load: " + SVG_TEST )
   ENDIF

   /* ---- Window ---- */
   INIT WINDOW oMain MAIN ;
      TITLE "SVG Demo - HWGui + librsvg" ;
      AT 100, 50 SIZE WIN_W, WIN_H ;
      FONT oFont

   /* ---- Menu ---- */
   MENU OF oMain
      MENU TITLE "&File"
         MENUITEM "Show &Logo HWGui"     ACTION ShowLogo()
         MENUITEM "Show &Test"           ACTION ShowTest()
         SEPARATOR
         MENUITEM "&Clear screen"        ACTION ClearScreen()
         SEPARATOR
         MENUITEM "E&xit"                ACTION oMain:Close()
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About..." ACTION hwg_MsgInfo( "SVG Demo" + Chr(10) + ;
                                                  "HWGui + librsvg" )
      ENDMENU
   ENDMENU

   /* ---- Two static bitmaps, both centered, both hidden at start.
      Visibility is toggled instead of using bPaint. ---- */
   IF oImgLogo != Nil
      @ ( WIN_W - 400 ) / 2, ( WIN_H - 215 ) / 2 BITMAP oImgLogo ;
         OF oMain ;
         SIZE 400, 215 ;
         ID 1001
      oLogoCtrl := oMain:aControls[ Len( oMain:aControls ) ]
      oLogoCtrl:Hide()
   ENDIF

   IF oImgTest != Nil
      @ ( WIN_W - 200 ) / 2, ( WIN_H - 200 ) / 2 BITMAP oImgTest ;
         OF oMain ;
         SIZE 200, 200 ;
         ID 1002
      oTestCtrl := oMain:aControls[ Len( oMain:aControls ) ]
      oTestCtrl:Hide()
   ENDIF

   ACTIVATE WINDOW oMain CENTER

   IF oImgLogo != Nil
      oImgLogo:RELEASE()
   ENDIF
   IF oImgTest != Nil
      oImgTest:RELEASE()
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

STATIC FUNCTION ShowLogo()

   IF oLogoCtrl == Nil
      hwg_MsgInfo( "Logo not loaded" )
      RETURN Nil
   ENDIF

   IF oTestCtrl != Nil
      oTestCtrl:Hide()
   ENDIF
   oLogoCtrl:Show()

   RETURN Nil

/* ------------------------------------------------------------------ */

STATIC FUNCTION ShowTest()

   IF oTestCtrl == Nil
      hwg_MsgInfo( "Test image not loaded" )
      RETURN Nil
   ENDIF

   IF oLogoCtrl != Nil
      oLogoCtrl:Hide()
   ENDIF
   oTestCtrl:Show()

   RETURN Nil

/* ------------------------------------------------------------------ */

STATIC FUNCTION ClearScreen()

   IF oLogoCtrl != Nil
      oLogoCtrl:Hide()
   ENDIF
   IF oTestCtrl != Nil
      oTestCtrl:Hide()
   ENDIF

   RETURN Nil
