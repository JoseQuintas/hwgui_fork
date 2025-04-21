/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  stretch.prg
 *
 * Sample for resizing bitmaps (background)
 *
 * Copyright 2020 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 *
 * TNX to Itamar M. Lins Jr.
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

* Tiled: In German "gekachelt"

#include "hwgui.ch"

FUNCTION Main(lStretch)
LOCAL oFormMain
LOCAL nPosX
LOCAL nPosY
LOCAL oQuitButton

LOCAL cDirSep := hb_PS() //PATH SEPARATOR
LOCAL cImagePath := ".."+ cDirSep + ".." + cDirSep + "image" + cDirSep
LOCAL cImageMain := cImagePath + "hwgui.bmp"

LOCAL oBmp := HBitmap():AddFile(cImageMain,,.F.,hwg_Getdesktopwidth(),hwg_Getdesktopheight()-21)
 // Here default is resized image
 // But works only with WinAPI, not GTK.

nPosX := hwg_Getdesktopwidth()
nPosY := hwg_Getdesktopheight()

lStretch := IIF( lStretch == NIL, lStretch := .T.,lStretch := .F.)

* Display size of recent desktop, it is equal to the size of screen.
hwg_msginfo("X=" + STR(nPosX) + CHR(10) + "Y=" + STR(nPosY) + CHR(10) + ;
 "lStretch=" + IIF(lStretch,"True","False") )



IF lStretch
   INIT WINDOW oFormMain MAIN AT 0,0 SIZE nPosX , nPosY

   @ 0,0 BITMAP cImageMain SIZE nPosX - 10, nPosY - 100 // Here resize of background image (stretch)

   // Bug here: Error E0030  Syntax error "syntax error at 'SELF'"
   // @ 25,25 BUTTON oQuitButton CAPTION "Exit" SIZE 75,18 ;
   // ON CLICK { | | oFormMain::Close() }

   oFormMain:Activate()

ELSE
   INIT WINDOW oFormMain APPNAME "Agenda Hwgui" MAIN AT 0,0 SIZE nPosX,nPosY BACKGROUND BITMAP oBmp
   // Tiled: Side by side, not stretch

      // Bug here: Error E0030  Syntax error "syntax error at 'SELF'"
      // @ 25,25 BUTTON oQuitButton CAPTION "Exit" SIZE 75,18 ;
      // ON CLICK { | | oFormMain::Close() }


   oFormMain:Activate()
ENDIF
RETURN NIL

* ==================== EOF of stretch.prg ============
