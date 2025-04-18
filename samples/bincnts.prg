/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  bincnts.prg
 *
 * Sample program for usage of images from
 * Binary container
 *
 * Copyright 2020 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No

* --------- Instructions -------------
*
* 1.) Compile the Utility "Binary container manager".
*     Path is "utils\bincnt".
*
* 2.) Start the manager with "bincnt.exe"
*     The exe file is stored in the "bin" directory.
*
* 3.) Create new a container file with menu
*     "File/Create", enter full name
*     of new file with extension .bin !
*
* 4.) Add images to the container with menu
*     "Container/Add Item"
*
* You find a sample container "sample.bin"
* in directory "image", this is used by this sample program.
* It contains all images used by this sample.
*
* Every item was listed by:
* Name, Type and size.
*
* See HWGUI documentation for supported image types
* for used terms of commands like BITMAP:
* Windows only *.BMP, *.JPG
*
* Info for GTK:
* Take care of different designs.
*

#include "hwgui.ch"

FUNCTION Main()

   LOCAL cImageDir, cppath , oIcon, oBitmap , oToolbar , oFileOpen , oQuit , oMainW , oFontMain
   LOCAL htab, nbut , oBMPExit , ojpeg , oBtnjpeg
   LOCAL oastrobmp
   LOCAL cDirSep := hwg_GetDirSep()
   * For design differences Windows and GTK/LINUX
   LOCAL nxowb, nyowb, nlowb
   LOCAL nx1, ny1 , nx2, ny2
#ifdef  __GTK__
   LOCAL oSayImg1, oSayImg2, oAstroPng, oPngDoor
#endif
#ifndef __PLATFORM__WINDOWS
   LOCAL oBtnDoor
#endif
#ifdef __GTK__
   nxowb := 24  && size x
   nyowb := 24  && size y
   nlowb := 32  && at x
#else
   nxowb := 18
   nyowb := 24
   nlowb := 32
#endif

   htab := 0
   nbut := 0

   * Path to container
   cppath := "."
   cImageDir := cppath + cDirSep + "image" + cDirSep

   * Check for existung container, if not existing
   * no error message and image does not appear.
   * Then it is useful, to display an error message
   * to user and terminate the program.

   CHECK_FILE(cImageDir + "sample.bin")

   * Open container
   hwg_SetResContainer( cImageDir + "sample.bin" )

   * Is container open ?
   IF .NOT. hwg_GetResContainerOpen()
      hwg_MsgStop("Container is not open")
      QUIT
   ENDIF

   * Load contents from container into image objects.
   * oIcon := HIcon():AddResource( "ok" )        && ico (old)

   oIcon := HIcon():AddResource( "hwgui_48x48" ) && ico
   * oIcon := HIcon():AddFile( "image" + cDirSep + "hwgui_32x32.ico" ) && icon from file (Test)

   oBitmap := HBitmap():AddResource("open")      && bmp
   oBMPExit := HBitmap():AddResource("exit")     && bmp
   ojpeg  := HBitmap():AddResource("next")       && jpg
   oastrobmp := HBitmap():AddResource("astro2")  && bmp

#ifdef __PLATFORM__WINDOWS
    PREPARE FONT oFontMain NAME "MS Sans Serif" WIDTH 0 HEIGHT -14
#else
   oPNGDoor := HBitmap():AddResource("door")     && png
   oastropng := HBitmap():AddResource("astro")   && png
    PREPARE FONT oFontMain NAME "Sans" WIDTH 0 HEIGHT 12
#endif

   INIT WINDOW oMainW  ;
      FONT oFontMain  ;
      TITLE "Bitmap container sample" AT 0,0 ;
      SIZE 500 , 500 ;
      ICON oIcon STYLE WS_POPUP +  WS_CAPTION + WS_SYSMENU

* GTK + Toolbar : If used, the Ownerbuttons are not visible !
#ifdef __GTK__
   @ 0, 0 TOOLBAR oToolbar OF oMainW SIZE  499 , 50
#else
   @ 0, 0 PANEL oToolbar OF oMainW SIZE 499 , 50 ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS
#endif

* For ownerbuttons:
* - Coordinates: pass the real size of image (old 0,4,0,0 for all)
*   ==> 3rd and fourth parameter
*   Set 1st and 2nd to centered image in the ownerbutton.
* - GTK: Remove "OF oToolbar" and "FLAT"


#ifdef __GTK__

   @ htab+(nbut * nlowb), 3 OWNERBUTTON oFileOpen /* OF oToolbar */ ;
      ON CLICK { | | FileOpen()} ;
      SIZE nxowb,nyowb  /* FLAT */  ;
      BITMAP oBitmap ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,0,16,16 ;
      TOOLTIP "Open File"

      nbut += 1

   @ htab+(nbut * nlowb),3 OWNERBUTTON oQuit /* OF oToolbar */ ;
      ON CLICK { | | oMainW:Close()} ;
      SIZE nxowb,nyowb /* FLAT */ ;
      BITMAP oBMPExit ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,0,17,17 ;
      TOOLTIP "Terminate Program"

      nbut += 1

#else

* If "OF oToolbar" is not added, the ON CLICK function does not work !

   @ htab+(nbut * nlowb), 3 OWNERBUTTON oFileOpen  OF oToolbar  ;
      ON CLICK { | | FileOpen()} ;
      SIZE nxowb,nyowb  FLAT  ;
      BITMAP oBitmap ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
      TOOLTIP "Open File"

      nbut += 1


   @ htab+(nbut * nlowb),3 OWNERBUTTON oQuit OF oToolbar  ;
      ON CLICK { | | oMainW:Close()} ;
      SIZE nxowb,nyowb /* FLAT */ ;
      BITMAP oBMPExit ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
      TOOLTIP "Terminate Program"

      nbut += 1
#endif


* !!!!! PNG not supported on Windows
#ifndef __PLATFORM__WINDOWS
   @ htab+(nbut * nlowb ),3 OWNERBUTTON oBtnDoor /* OF oToolbar */ ;
      ON CLICK { | | OpenDoor()} ;
      SIZE nxowb,nyowb /* FLAT */ ;
      BITMAP oPNGDoor ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,0,13,16 ;
      TOOLTIP "Open the door"

     nbut += 1
#endif

#ifdef __GTK__

   @ htab+(nbut * nlowb),3 OWNERBUTTON oBtnjpeg /* OF oToolbar */ ;
      ON CLICK { | | ClickJpeg()} ;
      SIZE nxowb,nyowb /* FLAT */ ;
      BITMAP ojpeg ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,5,20,16 ;
      TOOLTIP "JPEG image"
#else

   @ htab+(nbut * nlowb),3 OWNERBUTTON oBtnjpeg  OF oToolbar  ;
      ON CLICK { | | ClickJpeg()} ;
      SIZE nxowb,nyowb  FLAT  ;
      BITMAP ojpeg ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
      TOOLTIP "JPEG image"

#endif

   nx2 := hwg_GetBitmapWidth ( oastrobmp:handle )
   ny2 := hwg_GetBitmapHeight( oastrobmp:handle )

#ifdef __GTK__

   nx1 := hwg_GetBitmapWidth ( oastropng:handle )
   ny1 := hwg_GetBitmapHeight( oastropng:handle )

* Attention !
* The parameters oSayImg.. , nx.. , ny.. and "OF oDialog/oMainW"
* are on GTK mandatory, otherwise the image does not appear !

     @ 60 , 100 SAY "astro.png" SIZE 100, 20
     @ 60 , 150 BITMAP oSayImg1 SHOW oastropng OF oMainW SIZE nx1, ny1 && 100, 20

     @ 60 , 300 SAY "astro2.bmp" SIZE 100, 20
     // @ 60 , 350 BITMAP oastrobmp && not displayed
     @ 60 , 350 BITMAP oSayImg2 SHOW oastrobmp OF oMainW SIZE nx2, ny2
#else

   nx1 := 0
   ny1 := 0

   @ 60 , 100 SAY "astro2.bmp" SIZE 100, 20
   @ 60 , 150 BITMAP oastrobmp
#endif

   hwg_MsgInfo( "nx1=" + ALLTRIM(STR(nx1)) + " ny1=" + ALLTRIM(STR(ny1)) + CHR(10) + ;
                "nx2=" + ALLTRIM(STR(nx2)) + " ny2=" + ALLTRIM(STR(ny2)) )

   oMainW:Activate()

RETURN Nil

FUNCTION FileOpen()

   hwg_msginfo("You have clicked >FileOpen<")

RETURN Nil

FUNCTION OpenDoor()

   hwg_msginfo("You have clicked >Open the door<")

RETURN Nil

FUNCTION ClickJpeg()

   hwg_msginfo("You have clicked >JPEG image<")

RETURN Nil

FUNCTION CHECK_FILE( cfi )

   * Check, if file exist, otherwise terminate program
   IF .NOT. FILE( cfi )
      Hwg_MsgStop("File >" + cfi + "< not found, program terminated","File ERROR !")
      QUIT
   ENDIF

RETURN Nil

* ============================= EOF of bincnts.prg ==================================
