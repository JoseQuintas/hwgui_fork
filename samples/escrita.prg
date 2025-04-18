*
* escrita.prg
*
* $Id$
*
* HWGUI sample program:
* Tool buttons with bitmaps
* "Teste da Acentuação"
*
* DF7BE:
* This sample program is derived from the sample in
* directory "gtk_samples" with same name.
* It is an alternative for multi platform usage.
* The commands "TOOLBAR" and "TOOLBUTTON" are GTK only, so they are
* substituted by "PANEL" and "OWNERBUTTON".
* The behaviour on LINUX/GTK is preserved by usage
* of the compiler switch "#ifdef __GTK__".
* Compiling of this program on Windows
* and GTK/LINUX, you can see the diffences
* in design and behavior.

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes


REQUEST HB_CODEPAGE_PTISO, HB_CODEPAGE_PT850

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oModDlg, oEditbox, onome, obar
   LOCAL meditbox := "", mnome := Space( 50 )
   LOCAL cbmppref
   LOCAL otool
   LOCAL nxowb, nyowb, nlowb, htab
   LOCAL noffset
   LOCAL cTitle

#ifndef __GTK__
   * Used by OWNERBUTTON's
   LOCAL oFileOpen , oBook, nBut
   LOCAL oBmpNew , oBmpbook , oIcoOK , oBmpdoor , oIcoCancel
#endif

#ifdef __GTK__
   * Use this for OWNERBUTTONS (for multi platform usage with GTK)
   nxowb := 24  && size x
   nyowb := 24  && size y
   nlowb := 32  && at x
   nbut := 0
#else
   * But recent usage on Windows
   nxowb := 50  && size x
   nyowb := 60  && size y
   nlowb := 55  && at x
#endif

   htab := 0

   cTitle := "Teste da Acentuação"  && ==> "Accent Test"

   cbmppref := ".." + hwg_GetDirSep() + "image" + hwg_GetDirSep()
   // cbmppref := ".." + hwg_GetDirSep() + ".." + hwg_GetDirSep() + "image" + hwg_GetDirSep()
   * Check, if all bitmaps are existing, otherwise the program crashes or freezes
   CHECK_FILE(cbmppref + "new.bmp")
   CHECK_FILE(cbmppref + "book.bmp")
   CHECK_FILE(cbmppref + "ok.ico")
   CHECK_FILE(cbmppref + "door.bmp")
   CHECK_FILE(cbmppref + "cancel.ico")

#ifndef __GTK__
   * Add object variables of resources:
   oBmpNew    := HBitmap():AddFile(cbmppref + "new.bmp")
   oBmpbook   := HBitmap():AddFile(cbmppref + "book.bmp")
   oIcoOK     :=   HIcon():AddFile(cbmppref + "ok.ico")
   oBmpdoor   := HBitmap():AddFile(cbmppref + "door.bmp")
   oIcoCancel :=   HIcon():AddFile(cbmppref + "cancel.ico")
#endif

#ifdef __GTK__
/*
  !!! Confusion !!!
  This works not: the TOOLBUTTONS (with images) are not visible.

   INIT WINDOW oModDlg TITLE  cTitle ;
      AT 210, 10  SIZE 300, 300  // ON INIT { ||otool:refresh(), hwg_Enablewindow( oTool:aItem[2,11], .F. ) }
* ON INIT crashes with "No exported method: REFRESH"
*/
/* But this works fime */
   INIT DIALOG oModDlg ;
      TITLE cTitle ;
      AT 210, 10  ;
      SIZE 300, 300 ;
      ON INIT { ||otool:refresh(), hwg_Enablewindow( oTool:aItem[2,11], .F. ) }
#else
   INIT WINDOW oModDlg ;
   TITLE  cTitle ;
   AT 210, 10  ;
   SIZE 501, 300
#endif

#ifdef __GTK__
   * Commands TOOLBAR and TOOLBUTTON are "GTK only"
   @ 0, 0 toolbar oTool ;
      of oModDlg ;
      size 50, 100 ;
      ID 700
#else
  * On Windows, the size must have other values (old 50 , 100)
  @ 0, 0 PANEL oTool ;
     OF oModDlg ;
     SIZE 500 , 60 ;
     ID 70 ;
     ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS
#endif

#ifdef __GTK__
   TOOLBUTTON  otool ;
      ID 701 ;
      BITMAP cbmppref + "new.bmp";
      STYLE 0;
      STATE 4;
      TEXT "teste1"  ;
      TOOLTIP "ola" ;
      ON CLICK { |x, y|hwg_Msginfo( "ola" ), hwg_Enablewindow( oTool:aItem[2,11], .T. ) , hwg_Enablewindow( oTool:aItem[1,11], .F. ) }

   TOOLBUTTON  otool ;
      ID 702 ;
      BITMAP cbmppref + "book.bmp";
      STYLE 0 ;
      STATE 4;
      TEXT "teste2"  ;
      TOOLTIP "ola2" ;
      ON CLICK { |x, y|hwg_Msginfo( "ola1" ), hwg_Enablewindow( oTool:aItem[1,11], .T. ), hwg_Enablewindow( oTool:aItem[2,11], .F. ) }

   TOOLBUTTON  otool ;
      ID 703 ;
      BITMAP cbmppref + "ok.ico";
      STYLE 0 ;
      STATE 4;
      TEXT "asdsa"  ;
      TOOLTIP "ola3" ;
      ON CLICK { |x, y|hwg_Msginfo( "ola2" ) }
   TOOLBUTTON  otool ;
      ID 702 ;
      STYLE 1 ;
      STATE 4;
      TEXT "teste2"  ;
      TOOLTIP "ola2" ;
      ON CLICK { |x, y|hwg_Msginfo( "ola3" ) }
   TOOLBUTTON  otool ;
      ID 702 ;
      BITMAP cbmppref + "door.bmp";  // DF7BE: tools.bmp does not exist, choose existing one
      STYLE 0 ;
      STATE 4;
      TEXT "teste2"  ;
      TOOLTIP "ola2" ;
      ON CLICK { |x, y|hwg_Msginfo( "ola4" ) }

   TOOLBUTTON  otool ;
      ID 702 ;
      BITMAP cbmppref + "cancel.ico";
      STYLE 0 ;
      STATE 4;
      TEXT "teste2"  ;
      TOOLTIP "ola2" ;
      ON CLICK { |x, y|hwg_Msginfo( "ola5" ) }

#else

* Additional instructions:
* - ! "OF oTool" not for GTK
* - The TEXT is displayed in the center
*   of the OWNERBUTTON, so choice the
*   size of the image smaller and check the
*   design finally.

* "new.bmp"

   @ htab+(nbut * nlowb), 3 OWNERBUTTON oFileOpen  ;
      OF oTool  ;
      SIZE nxowb,nyowb ;
      ON CLICK { | | hwg_Msginfo( "ola" )  }  ;
      TEXT "teste1"  ;
      BITMAP oBmpNew ; // cbmppref + "new.bmp" ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
      TOOLTIP "ola"

      nbut += 1

* "book.bmp"

   @ htab+(nbut * nlowb), 3 OWNERBUTTON oBook  ;
      OF oTool  ;
      SIZE nxowb,nyowb ;
      ON CLICK { | | hwg_Msginfo( "ola1" )  }  ;
      TEXT "teste2"  ;
      BITMAP oBmpbook ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
      TOOLTIP "ola2"

   nbut += 1


* "ok.ico"

   @ htab+(nbut * nlowb), 3 OWNERBUTTON oBook  ;
      OF oTool  ;
      SIZE nxowb,nyowb ;
      ON CLICK { | | hwg_Msginfo( "ola2" )  }  ;
      TEXT "asdsa"  ;
      BITMAP oIcoOK  ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
      TOOLTIP "ola3"

      nbut += 1

* "door.bmp"

   @ htab+(nbut * nlowb), 3 OWNERBUTTON oBook  ;
      OF oTool  ;
      SIZE nxowb,nyowb ;
      ON CLICK { | | hwg_Msginfo( "ola4" )  }  ;
      TEXT "teste2"  ;
      BITMAP oBmpdoor ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
      TOOLTIP "ola2"

   nbut += 1

* "cancel.ico"

   @ htab+(nbut * nlowb), 3 OWNERBUTTON oBook  ;
      OF oTool  ;
      SIZE nxowb,nyowb ;
      ON CLICK { | | hwg_Msginfo( "ola5" )  }  ;
      TEXT "teste2"  ;
      BITMAP oIcoCancel  ;
      TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") COORDINATES 0,4,0,0 ;
      TOOLTIP "ola5"

   //nbut += 1

#endif

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#ifdef __GTK__
   noffset := 0
#else
* Add an Y Offset for the last controls on Windows
   noffset := 55
#endif

   @ 20 , 35 + noffset EDITBOX oEditbox ;
      CAPTION ""    ;
      STYLE WS_DLGFRAME ;
      SIZE 260, 26

   @ 20 , 75  + noffset GET onome ;
      VAR mnome ;
      SIZE 260, 26

   @ 20 , 105  + noffset progressbar obar ;
      size 260, 26  ;
      barwidth 100


#ifdef __GTK__
   ACTIVATE DIALOG oModDlg CENTER
#else
   ACTIVATE WINDOW oModDlg CENTER
#endif

   hwg_Msginfo( meditbox , "Contents of variable meditbox")
   hwg_Msginfo( OEDITBOX:TITLE , "Title of OEDITBOX")
   hwg_Msginfo( mnome  , "Contents of variable mnome")

RETURN Nil

FUNCTION CHECK_FILE( cfi )

   * Check, if file exist, otherwise terminate program
   IF .NOT. FILE( cfi )
      Hwg_MsgStop("File >" + cfi + "< not found, program terminated","File ERROR !")
      QUIT
   ENDIF

RETURN Nil

* =================== EOF of escrita.prg ====================
