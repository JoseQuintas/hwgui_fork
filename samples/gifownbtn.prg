/*
 * demo_gif.prg
 * Minimal example: HOwnButton with animated GIF using HOwnButton
 * (HOwnButton must already support SetGifPath() - see hownbtn.prg)
 */

#include "hwgui.ch"

#define GIF_PATH "C:\dev\hwgui\image\hwgui_64x64.gif"

STATIC oMain, oPanel, oBtnGif

FUNCTION Main()

   LOCAL oFont

   PREPARE FONT oFont NAME "Segoe UI" WIDTH 0 HEIGHT -11 WEIGHT 400

   INIT WINDOW oMain MAIN ;
      TITLE "Animated GIF Demo" ;
      AT 200, 150 SIZE 400, 220 ;
      FONT oFont

   // Panel to hold the button
   @ 0, 0 PANEL oPanel OF oMain SIZE 400, 220

   // The button with animated GIF
   @ 20, 20 OWNERBUTTON oBtnGif OF oPanel ;
      ON CLICK {|| hwg_MsgInfo( "Clicked!" ) } ;
      SIZE 120, 120 ;
      FLAT ;
      TEXT "Hwgui GIF" ;
      COORDINATES 0, 100, 120, 120 ;
      FONT oFont ;
      BITMAP GIF_PATH ;
      TRANSPARENT ;
      COORDINATES 0, 0, 64, 64 ;
      TOOLTIP "Animated GIF button"

   // The trick: SetGifPath AFTER creating the button, because the
   // @...OWNERBUTTON macro converts the string path to an HBitmap
   // before calling HOwnButton:New()

   oBtnGif:SetGifSpeed( 1.0 ) // 0.75 25% Fine-tune downwards
   oBtnGif:SetGifPath( GIF_PATH )

   ACTIVATE WINDOW oMain CENTER

   RETURN Nil
