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
    *  GTK/Linux:  No
    *  GTK/Win  :  No

* --------- Instructions -------------
*
* 1.) Compile the Utility "Binary container manager".
*     Path is "utils\bincnt".
*
* 2.) Start the manager with "bincnt.exe"
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
* for used terms of commands like BITMAP
* Here only *.BMP, *.JPG
*
* Info for GTK:
* At this time, the container cannot be used.
* Please load images from files.
* We will realize this as soon as posible.
*

#include "hwgui.ch"
#include "sampleinc.ch"

FUNCTION Main

LOCAL oIcon, oBitmap , oFileOpen , oMainW , oFontMain // oQuit oToolbar ,
LOCAL htab, nbut , oastropng // oBtnDoor , oBMPExit , oBtnjpeg, ojpeg , obtncnts ,oPNGDoor , obtncnt ,

htab := 0
nbut := 0



* Check for existung container, if not existing
* no error message and image does not appear.
* Then it is useful, to display an error message
* to user and terminate the program.
CHECK_FILE( SAMPLE_IMAGEPATH + "sample.bin")

* Open container
hwg_SetResContainer( SAMPLE_IMAGEPATH + "sample.bin" )

* Load contents from container into image objects.
oIcon := HIcon():AddResource( "ok" )
oBitmap := HBitmap():AddResource("open")
//oBMPExit := HBitmap():AddResource("exit")
//oPNGDoor := HBitmap():AddResource("door")
//ojpeg  := HBitmap():AddResource("next")
//obtncnt := HBitmap():AddResource("container")
oastropng := HBitmap():AddResource("astro")

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFontMain NAME "MS Sans Serif" WIDTH 0 HEIGHT -14
#else
   PREPARE FONT oFontMain NAME "Sans" WIDTH 0 HEIGHT 12
#endif

INIT WINDOW oMainW  ;
   FONT oFontMain  ;
   TITLE "Bitmap container sample" AT 0,0 SIZE 300 , 250 ;
   ICON oIcon STYLE WS_POPUP +  WS_CAPTION + WS_SYSMENU

* GTK + Toolbar : If used, the Ownerbuttons are not visible !
* @ 0, 0 TOOLBAR oToolbar OF oMainW SIZE  299 , 50
*  @ 0,0 PANEL oToolbar OF oMainW SIZE 300 , 50 ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

@ htab+(nbut*32), 3 OWNERBUTTON oFileOpen OF oMainW ; // OF oToolbar ;
   ON CLICK { | | FileOpen()} ;
   SIZE 28,24 FLAT ;
   BITMAP oBitmap ;
   TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
   TOOLTIP "Open File"

   //nbut += 1
/*
@ htab+(nbut*32),3 OWNERBUTTON oQuit OF oToolbar ;
   ON CLICK { | | oMainW:Close()} ;
   SIZE 28,24 FLAT ;
   BITMAP oBMPExit ;
   TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
   TOOLTIP "Terminate Program"

   nbut += 1

* !!!!! PNG not supported on Windows
@ htab+(nbut*32),3 OWNERBUTTON oBtnDoor OF oToolbar ;
   ON CLICK { | | OpenDoor()} ;
   SIZE 28,24 FLAT ;
   BITMAP oPNGDoor ;
   TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
   TOOLTIP "Open the door"

  nbut += 1

@ htab+(nbut*32),3 OWNERBUTTON oBtnjpeg OF oToolbar ;
   ON CLICK { | | ClickJpeg()} ;
   SIZE 28,24 FLAT ;
   BITMAP ojpeg ;
   TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
   TOOLTIP "JPEG image"

  nbut += 1

@ htab+(nbut*32),3 OWNERBUTTON obtncnts OF oToolbar ;
   ON CLICK { | | Clickcnt()} ;
   SIZE 28,24 FLAT ;
   BITMAP obtncnt ;
   TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
   TOOLTIP "Container image"
*/

 @ 60 , 100 SAY "astro.png" SIZE 100, 20
 @ 60 , 150 BITMAP oastropng


   oMainW:Activate()
RETURN NIL

FUNCTION FileOpen
 hwg_msginfo("You have clicked >FileOpen<")
RETURN NIL

FUNCTION OpenDoor
 hwg_msginfo("You have clicked >Open the door<")
RETURN NIL

FUNCTION ClickJpeg
 hwg_msginfo("You have clicked >JPEG image<")
RETURN NIL

FUNCTION Clickcnt
 hwg_msginfo("You have clicked >Container image<")
RETURN NIL

FUNCTION CHECK_FILE ( cfi )
* Check, if file exist, otherwise terminate program
 IF .NOT. FILE( cfi )
  Hwg_MsgStop("File >" + cfi + "< not found, program terminated","File ERROR !")
  QUIT
 ENDIF
RETURN Nil

* ============================= EOF of bincnts.prg ==================================
