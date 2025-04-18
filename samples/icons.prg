/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  icons.prg
 *
 * Sample for icons and background
 * bitmaps
 *
 * Copyright 2020 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 *
 * GTK2, bug in windows.c, function hwg_CreateDlg(nhandle)
 * (need to fix):
 * (icons:12333): GdkPixbuf-CRITICAL **: 20:44:38.526: gdk_pixbuf_get_width: assertion 'GDK_IS_PIXBUF (pixbuf)' failed
 * Speicherzugriffsfehler
 *
 * This line returns invalid handle:
 *   PHB_ITEM pBmp = GetObjectVar( pObject, "OBMP" );
 *
 * Runs best on Windows 11
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes


#include "hwgui.ch"

FUNCTION Main()

   LOCAL oFormMain, oFontMain
   LOCAL cDirSep := hwg_GetDirSep()
   LOCAL cImageMain, cImagepath
   LOCAL oBmp
   LOCAL nPosX
   LOCAL nPosY
   LOCAL oIconEXE

   * Use this for full size
   * nPosX := hwg_Getdesktopwidth()
   * nPosY := hwg_Getdesktopheight()

   nPosX := 500
   nPosY := 400

* decides for samples/gtk_samples or samples/
// #ifdef __GTK__
//   cImagepath := ".."+ cDirSep + ".." + cDirSep + "image" + cDirSep
// #else
   cImagepath := ".."+ cDirSep + "image" + cDirSep
// #endif

//   cImageMain := cImagepath + "hwgui.png"
//   cImageMain := cImagepath + "hwgui_48x48.png"
     cImageMain := cImagepath + "hwgui.bmp"
   IF .NOT. FILE( cImageMain )
      hwg_msgstop( "File not existing: " + cImageMain )
      QUIT
   ENDIF
   oBmp := HBitmap():AddFile( cImageMain )
   oIconEXE := HIcon():AddFile( cImagepath + "ok.ico" )

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFontMain NAME "MS Sans Serif" WIDTH 0 HEIGHT -14
#else
   PREPARE FONT oFontMain NAME "Sans" WIDTH 0 HEIGHT 12
#endif

* The background image was tiled, if size is smaller than window.
   INIT WINDOW oFormMain ;
      MAIN ;
      APPNAME "Hwgui sample" ;
      FONT oFontMain BACKGROUND BITMAP oBmp ;   && HBitmap():AddFile( cImageMain ) ;
      TITLE "Icon sample" ;
      AT 0,0 ;
      SIZE nPosX,nPosY - 30 ;
      ICON oIconEXE STYLE WS_POPUP +  WS_CAPTION + WS_SYSMENU

   hwg_msginfo( cImageMain + CHR(10)+  cImagepath + "ok.ico" )

  MENU OF oFormMain
      MENU TITLE "&Exit"
         MENUITEM "&Quit" ACTION oFormMain:Close()
      ENDMENU
#ifdef __PLATFORM__WINDOWS
      MENU TITLE "&Dialog"
         MENUITEM "&With Background" ACTION Teste( cImagepath )  && Bug GTK
      ENDMENU
#endif
   ENDMENU

   oFormMain:Activate()

RETURN Nil

* Dialog with background
FUNCTION Teste( cimgpfad )

   LOCAL oModDlg, obg , obitmap , oIcon , cbitmap

   cbitmap := "astro.bmp"

   obitmap := HBitmap():AddFile(cimgpfad + cbitmap )
   oIcon := HIcon():AddFile( cimgpfad + "hwgui_24x24.ico" )

     hwg_msginfo( cimgpfad + cbitmap + CHR(10) +  cimgpfad + "hwgui_24x24.ico" )


   obg := NIL

   IF .NOT. FILE( cimgpfad + "astro.bmp" )
      hwg_msgStop( "File " + cimgpfad + "astro.bmp" + " not found" )
   ENDIF

   IF .NOT. FILE( cimgpfad + "hwgui_24x24.ico" )
      hwg_msgStop( "File " + cimgpfad + "hwgui_24x24.ico" + " not found" )
   ENDIF

   INIT DIALOG oModDlg ;
      TITLE "Dialog with background image" ;
      AT 210,10  ;
      SIZE 300,300 ;
      ICON oIcon ;
      BACKGROUND BITMAP obitmap  && HBitmap():AddFile(cimgpfad + "astro.bmp" )

   ACTIVATE DIALOG oModDlg

RETURN Nil

* ================================== EOF of icons.prg ==============================
