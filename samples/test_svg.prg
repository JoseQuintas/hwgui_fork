/*
 * test_svg.prg - SVG demo with menu, using static BITMAP controls.
 *
 * Works on both backends:
 *   - WinAPI : HWG_LOADSVG() via librsvg + Cairo, needs svg.hbc
 *   - GTK4   : HWG_LOADSVG() via GdkPixbuf, no extra dependency
 *              (SVG loader provided by the librsvg2 runtime package)
 *
 * Build (WinAPI):
 *     hbmk2 demo_svg.prg C:\dev\hwgui\hwgui.hbp C:\dev\hwgui\svg.hbc
 * Build (GTK4 / Linux):
 *     hbmk2 demo_svg.prg
 */

#include "hwgui.ch"

#define WIN_W      800
#define WIN_H      600
#define SVG_LOGO   "../image/svg/hwgui.svg"
#define SVG_TEST   "../image/svg/info.svg"

STATIC oMain
STATIC oImgLogo, oImgTest
STATIC oFont
STATIC oLogoCtrl, oTestCtrl

FUNCTION Main()

   LOCAL hSvg

   #ifdef __PLATFORM__WINDOWS
      PREPARE FONT oFont NAME "Segoe UI" WIDTH 0 HEIGHT -11 WEIGHT 400
   #else
      PREPARE FONT oFont NAME "Noto Sans" WIDTH 0 HEIGHT -11 WEIGHT 400
   #endif

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
      TITLE "SVG Demo - HWGui" ;
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
        #ifdef __PLATFORM__WINDOWS
            MENUITEM "&About..." ACTION hwg_MsgInfo( "SVG Demo" + Chr(10) + ;
                                          "HWGui + librsvg (WinAPI)" )
        #else
            MENUITEM "&About..." ACTION hwg_MsgInfo( "SVG Demo" + Chr(10) + ;
                                          "HWGui + GdkPixbuf (GTK4)" )
        #endif
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
