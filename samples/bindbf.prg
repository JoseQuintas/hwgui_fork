/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  bindbf.prg
 *
 * Sample program for usage of images from
 * Binary DBF container
 *
 * Copyright 2022 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No

* --------- Instructions -------------
*
* 1.) Compile the Utility "Binary DBF container manager".
*     Path is "utils\bincnt".
*
* 2.) Start the manager with "bindbf.exe"
*     The exe file is stored in the recent directory.
*
* 3.) Create new a container file with menu
*     "File/Create", enter name
*     of new file without extension !
*     A pair of dbf/dbt files (memo's used)
*     are created.
*
* 4.) Add images to the container with menu
*     "Container/Add File"
*     Before this you can do, open the DBF file.
*
* You find a sample container "bindbf.dbf/dbt"
* in directory "image", this is used by this sample program.
* It contains all images used by this sample.
*
* Every item was listed by:
* Name and type.
*
* See HWGUI documentation for supported image types
* for used terms of commands like BITMAP:
* Windows only *.BMP, *.JPG
*
* Info for GTK:
* Take care of different designs.
*
* Bugfix on LINUX:
* Error DBCMD/2001  Workarea not in use: DBGOTOP
* Called from (b)HWG_ERRSYS(19)
* Called from DBGOTOP(0)
* Called from DBFCNT_SEARCH(390)
* Called from BINDBF_GETIMAGE(323)
* Called from MAIN(200)

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oIcon, oBitmap , oToolbar , oFileOpen , oQuit , oMainW , oFontMain
   LOCAL htab, nbut , oBMPExit , ojpeg , oBtnjpeg
   LOCAL oastrobmp
   //LOCAL cDirSep := hwg_GetDirSep()
   * For design differences Windows and GTK/LINUX
   LOCAL nxowb, nyowb, nlowb
   LOCAL nx1, ny1 , nx2, ny2
#ifndef __PLATFORM__WINDOWS
   LOCAL oBtnDoor, oPngDoor
#endif
#ifdef __GTK__
   LOCAL oSayImg1 , oSayImg2, oAstroPng

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

   * Check for existung container, if not existing
   * no error message and image does not appear.
   * Then it is useful, to display an error message
   * to user and terminate the program.
   CHECK_FILE("bindbf.dbf")
   CHECK_FILE("bindbf.dbt")

   * Open container
   USE bindbf

   * Debug (is container openend ?)
   // hwg_MsgInfo("Alias=" + ALIAS() )
   // hwg_MsgInfo("USED=" + IIF(USED() , ".T.",".F.") )

   * Load contents from container into image objects.
   * oIcon := HIcon():AddResource( "ok" )        && ico (old)
   // oIcon := HIcon():AddResource( "hwgui_48x48" ) && ico
   * oIcon := HIcon():AddFile( SAMPLE_IMAGEPATH + "hwgui_32x32.ico" ) && icon from file (Test)
   *
   // oBitmap := HBitmap():AddResource("open")      && bmp
   // oBMPExit := HBitmap():AddResource("exit")     && bmp
   // oPNGDoor := HBitmap():AddResource("door")     && png
   // ojpeg  := HBitmap():AddResource("next")       && jpg
   // oastropng := HBitmap():AddResource("astro")   && png
   // oastrobmp := HBitmap():AddResource("astro2")  && bmp

   oIcon := bindbf_getimage( "hwgui_48x48", "ico" )

   oBitmap   := bindbf_getimage( "open", "bmp" )
   oBMPExit  := bindbf_getimage( "exit", "bmp" )
   ojpeg     := bindbf_getimage( "next", "jpg" )
   oastrobmp := bindbf_getimage( "astro2", "bmp" )

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFontMain NAME "MS Sans Serif" WIDTH 0 HEIGHT -14
#else
   PREPARE FONT oFontMain NAME "Sans" WIDTH 0 HEIGHT 12
#endif

   * Close the binary DBF container
   * (all image objects are created)
//   USE

   * Now you can open your own database(s) with the use command

   INIT WINDOW oMainW  ;
      FONT oFontMain  ;
      TITLE "Bitmap container sample" ;
      AT 0,0 ;
      SIZE 500 , 500 ;
      ICON oIcon STYLE WS_POPUP +  WS_CAPTION + WS_SYSMENU

   * GTK + Toolbar : If used, the Ownerbuttons are not visible !
#ifdef __GTK__
   @ 0, 0 TOOLBAR oToolbar ;
      OF oMainW ;
      SIZE  499 , 50
#else
   @ 0, 0 PANEL oToolbar ;
      OF oMainW ;
      SIZE 499 , 50 ;
      ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS
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

   @ htab+(nbut * nlowb), 3 OWNERBUTTON oFileOpen  ;
      OF oToolbar  ;
      ON CLICK { | | FileOpen()} ;
      SIZE nxowb,nyowb  FLAT  ;
      BITMAP oBitmap ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
      TOOLTIP "Open File"

   nbut += 1

   @ htab+(nbut * nlowb),3 OWNERBUTTON oQuit ;
      OF oToolbar  ;
      ON CLICK { | | oMainW:Close() } ;
      SIZE nxowb,nyowb /* FLAT */ ;
      BITMAP oBMPExit ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
      TOOLTIP "Terminate Program"

      nbut += 1
#endif


   * !!!!! PNG not supported on Windows
#ifndef __PLATFORM__WINDOWS
   oPNGDoor := bindbf_getimage("door","png")

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

   @ htab+(nbut * nlowb),3 OWNERBUTTON oBtnjpeg  ;
      OF oToolbar  ;
      ON CLICK { | | ClickJpeg()} ;
      SIZE nxowb,nyowb  ;
      FLAT  ;
      BITMAP ojpeg ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
      TOOLTIP "JPEG image"

#endif

   nx2 := hwg_GetBitmapWidth ( oastrobmp:handle )
   ny2 := hwg_GetBitmapHeight( oastrobmp:handle )

#ifdef __GTK__
   oastropng := bindbf_getimage("astro","png")

   nx1 := hwg_GetBitmapWidth ( oastropng:handle )
   ny1 := hwg_GetBitmapHeight( oastropng:handle )

   * Attention !
   * The parameters oSayImg.. , nx.. , ny.. and "OF oDialog/oMainW"
   * are on GTK mandatory, otherwise the image does not appear !

   @ 60 , 100 SAY "astro.png" SIZE 100, 20
   @ 60 , 150 BITMAP oSayImg1 ;
      SHOW oastropng ;
      OF oMainW ;
      SIZE nx1, ny1 && 100, 20

   @ 60 , 300 SAY "astro2.bmp" SIZE 100, 20
   // @ 60 , 350 BITMAP oastrobmp && not displayed
   @ 60 , 350 BITMAP oSayImg2 ;
      SHOW oastrobmp ;
      OF oMainW ;
      SIZE nx2, ny2
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


* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* ~  Functions for DBF binary container ~
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FUNCTION bindbf_getimage( cfile,ctype )

   * Get image object (all supported image types)
   * ==============================================

   LOCAL obmp , oldsel

   FIELD BIN_CITEM , BIN_CTYPE , BIN_MITEM

   oldsel := SELECT()

   // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   // SELECT 2   && Modify to your own needs
   // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   * Seek to desired image
   IF dbfcnt_search( cfile, ctype ) < 1
      RETURN NIL   && No match
   ENDIF

   obmp := bindbf_obitmap(BIN_CITEM , BIN_CTYPE , BIN_MITEM)

   * Return to previos area
   SELECT ( oldsel )

   IF obmp == Nil
      RETURN Nil
   ENDIF

RETURN obmp

FUNCTION bindbf_obitmap( citem, ctype, mitem )

   * ~~~~~~~~~~~~ universal ~~~~~~~~~~~~~~~~~~~~~~~
   * Get a bitmap opject from container
   * The record pointer must show to the
   * record with the element to extract.
   * Supported type see HWGUI documentation
   * "doc/hwgdoc_classes.html", classes
   * HBitmap and HIcon
   * ==============================================

   LOCAL obmp,mm

   citem := ALLTRIM( citem )
   ctype := ALLTRIM( ctype )

   * Check for supported image types
   * On Windows only bmp and jpg

   DO CASE
   CASE ctype  == "bmp"
      mm := hwg_cHex2Bin(mitem)
      obmp := HBitmap():AddString( citem, mm )
   CASE ctype  == "jpg"
      mm := hwg_cHex2Bin(mitem)
      obmp := HBitmap():AddString( citem, mm )
   CASE ctype  == "ico"
      mm := hwg_cHex2Bin(mitem)
      obmp := HIcon():AddString( citem, mm )
#ifndef __PLATFORM__WINDOWS
   CASE ctype  == "png"
      mm := hwg_cHex2Bin(mitem)
      obmp := HBitmap():AddString( citem, mm )
#endif
   OTHERWISE
      RETURN Nil
   ENDCASE

RETURN obmp

FUNCTION dbfcnt_search( cfile, ctype )

   * Searches element in an binary DBF container
   * Returns the number of the record with match
   * 0, if not found.
   * ==============================================

   LOCAL noldrec
   FIELD BIN_CITEM,  BIN_CTYPE

   noldrec := RECNO()

   GO TOP

   * Database empty: no match
   IF LASTREC() == 0
      RETURN 0
   ENDIF

   IF INDEXORD() == 0
      *  Without index
      LOCATE FOR ( ALLTRIM(cfile) == ALLTRIM(BIN_CITEM)  ) .AND. ;
             ( ALLTRIM(ctype) == ALLTRIM(BIN_CTYPE)  )
   ELSE
      * With  index
      SET SOFTSEEK OFF
      * Exakt seek
      SEEK PADR(cfile + ctype,LEN(cfile + ctype ))
   ENDIF

   IF FOUND()
      RETURN RECNO()
   ENDIF

   GO noldrec

RETURN 0

* ============================= EOF of bindbf.prg ==================================
