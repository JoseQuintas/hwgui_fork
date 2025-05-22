/*
 *$Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 * tstsplash.prg - Splash sample, displays image at start as logo for n millisecs
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * Modified by DF7BE
 */
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No

#include "hwgui.ch"
#include "sampleinc.ch"

FUNCTION Main()

   LOCAL oMainWindow
   LOCAL oSplash, csplashimg

   * Name and path of splash image
   * Formats can be: jpg, bmp
   csplashimg := SAMPLE_IMAGEPATH + "astro.jpg"
   * csplashimg := SAMPLE_IMAGEPATH + "logo.bmp"
   *csplashimg := "hwgui.bmp"

   * Check, if splash image exists,
   * otherwise the program freezes
   IF .NOT. FILE( csplashimg )
      Hwg_MsgStop( "Image >" + csplashimg  + "< not found !" + CHR(10) + ;
         "Program will be terminated", "Splash image file" )
      QUIT
   ENDIF

   //oSplash := HSplash():Create( "Hwgui.bmp",2000)
   SPLASH oSplash TO csplashimg TIME 2000

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "Example" ;
      AT 0,0 ;
      SIZE 800, 600

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION oMainWindow:Close()
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

   (oSplash) // warning -w3 -es2

RETURN Nil
