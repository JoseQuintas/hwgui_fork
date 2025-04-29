/*
 *
 * imageview.prg
 *
 * Imageviewer with zoom
 *
 * $Id$
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Copyright 2022 DF7BE

*/
   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No

/*
 Supported image formats:
 Windows: bmp, jpg
 LINUX: bmp, jpg, png, ico
*/

#include "hwgui.ch"

MEMVAR nZoom

FUNCTION MAIN()

   LOCAL oMain

   PUBLIC nZoom

   nZoom := 1

   INIT WINDOW oMain ;
      MAIN ;
      TITLE "HWGUI image viewer with zoom" ;
      AT 0,0 ;
      SIZE 800, 600

   MENU OF oMain
      MENU TITLE "&Exit"
         MENUITEM "&Quit" ACTION oMain:Close()
      ENDMENU
      MENU TITLE "&Load"
         MENUITEM "&Bitmap" ACTION ViewImg("bmp",nZoom)
         MENUITEM "&JPEG" ACTION ViewImg("jpg",nZoom)
         MENUITEM "&PNG" ACTION ViewImg("png",nZoom)
         MENUITEM "&ICON" ACTION ViewImg("ico",nZoom)
      ENDMENU
      MENU TITLE "&Resize"
         MENUITEM "&Set zoom factor" ACTION ZoomImg()
      ENDMENU
      MENU TITLE "&?"
         MENUITEM "&About" ACTION About()
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMain CENTER

RETURN Nil

FUNCTION ViewImg( ctype, nresize )

   * Open image file and show image

   LOCAL odlg, oSayImg , oImg
   LOCAL cs := hwg_GetDirSep()
   LOCAL fname , mypath , nWidth , nHeight , cstr , noHeight , noWidth // oSay

   IF nresize == NIL
      nresize := 1
   ENDIF

   * Assemble full path
   mypath :=  cs + CURDIR() + IIF( EMPTY( CURDIR() ), "", cs ) + ".." + cs + "image" + cs

   * Open image file
   fname := hwg_Selectfile( "Image files( *." +  ctype + " )", "*." + ctype , mypath )
   IF EMPTY( fname )
      RETURN NIL
   ENDIF

   IF .NOT. IMGEXIST( fname )
      RETURN NIL
   ENDIF

   oImg := HBitmap():AddFile(fname)

   * Get image size
   nWidth  := oImg:nWidth
   nHeight := oImg:nHeight

   * Remember original size

   noWidth  := nWidth
   noHeight := nHeight

   * Resize with factor

   IF nresize > 1
      nWidth  := nWidth * nresize
      nHeight := nHeight * nresize
   ENDIF

   cstr := "Height = " + ASTR(nHeight) + " Width = " + ASTR(nWidth) + " Zoom factor = " + ASTR(nresize)

   IF nresize > 1
      cstr := cstr + " Original size : Y = " + ASTR(noHeight) + " X = " + ASTR(noWidth)
   ENDIF

   INIT Dialog oDlg ;
      AT 0,0 ;
      TITLE cstr ;
      SIZE 500,400 ;
      CLIPPER ;
      NOEXIT ;
      NOEXITESC

   * BITMAP:
   * Supported formats on Windows: bmp, jpg

   @ 30, 10 BITMAP oSayImg ;
      SHOW oImg ;
      OF oDlg ;
      SIZE nWidth, nHeight

   @ 20, 370 BUTTON "OK"      ;
      SIZE 75,25 ;
      ON CLICK {|| oDlg:Close() }

   ACTIVATE Dialog oDlg CENTER

RETURN Nil

FUNCTION ASTR( ninp )

RETURN ALLTRIM( STR( ninp, 10, 0 ) )

FUNCTION ZoomImg()

   LOCAL oForm , aItems , lcancel , nCombo , oCombo1

   MEMVAR nZoom

   aItems := {"1","2","4","8"}
   lcancel := .T.

   nCombo := ComboRet(nZoom)

   INIT DIALOG oForm ;
      CLIPPER ;
      NOEXIT ;
      TITLE "Select zoom factor" ;
      AT 0, 0 ;
      SIZE 200, 200 ;
      STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU

   @ 20, 20 GET COMBOBOX oCombo1 ;
      VAR nCombo ;
      ITEMS aItems ;
      SIZE 100, 150

   @ 20, 170 BUTTON "OK" ;
      SIZE 75,25 ;
      ON CLICK {|| lcancel := .F. , nZoom := ComboTr(nCombo) , oForm:Close() }

   @ 100, 170 BUTTON "Cancel"   ;
      SIZE 75,25 ;
      ON CLICK {|| oForm:Close() }

   ACTIVATE DIALOG oForm

   IF .NOT. lcancel
      hwg_MsgInfo("Zoom factor set to " +  ALLTRIM(STR(nZoom)) )
   ENDIF

RETURN Nil

FUNCTION ComboTr( nitem )

RETURN 2 ^ ( nitem - 1 )

FUNCTION ComboRet( nitem )

   LOCAL nret

   DO CASE
   CASE nitem == 1
      nret := 1
   CASE nitem == 2
      nret := 2
   CASE nitem == 4
      nret := 3
   CASE nitem == 8
      nret := 4
   OTHERWISE
     nret := 1
   ENDCASE

RETURN nret

FUNCTION About()

   hwg_MsgInfo("HWGUI Image Viewer by DF7BE")

RETURN Nil

FUNCTION IMGEXIST( nameimg )

   IF .NOT. FILE( nameimg )
      hwg_msgStop("File >" + nameimg + "< not found","Error" )
      RETURN .F.
   ENDIF

RETURN .T.

* ================ EOF of imageview.prg ===========================
