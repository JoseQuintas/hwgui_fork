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

FUNCTION Main()

   LOCAL oMainWindow
   LOCAL oSplash, csplashimg , cDirSep

   cDirSep := hwg_GetDirSep()
   * Name and path of splash image
   * Formats can be: jpg, bmp
   csplashimg := ".." + cDirSep + "image" + cDirSep + "astro.jpg"
   * csplashimg := ".." + cDirSep + "image" + cDirSep + "logo.bmp"
   *csplashimg := "hwgui.bmp"

   * Check, if splash image exists,
   * otherwise the program freezes
   IF .NOT. FILE( csplashimg )
      Hwg_MsgStop( "Image >" + csplashimg  + "< not found !" + CHR(10) + ;
         "Program will be terminated", "Splash image file" )
      QUIT
   ENDIF

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "Example" ;
      AT 0,0 ;
      SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION oMainWindow:Close()
   ENDMENU

   //oSplash := HSplash():Create( "Hwgui.bmp",2000)
   SPLASH oSplash TO csplashimg TIME 2000

   ACTIVATE WINDOW oMainWindow CENTER

   (oSplash) // -w3 -es2

RETURN Nil
