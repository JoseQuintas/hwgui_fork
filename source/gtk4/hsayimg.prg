/*
 * $Id: hsayimg.prg 3535 2025-02-23 17:40:46Z df7be $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HSayImage class
 *
 * Copyright 2003 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * HSayBmp uses SS_OWNERDRAW → GtkDrawingArea; the ::Paint() call reaches
 * the live cairo_t through the hwg_current_cr bridge (draw.c).
 *
 * HSayIcon uses SS_ICON → GtkImage (added in control.c's HWG_CREATESTATIC
 * for GTK4).  The pixbuf is attached by hwg_StaticSetImage() right after
 * the widget is created — see the Activate() override below.
 */

#include "hbclass.ch"
#include "hwgui.ch"

   //- HSayImage

CLASS HSayImage INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA  oImage
   DATA bClick, bDblClick
   DATA lNoRelease      INIT .F.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, ;
      bSize, ctoolt, bClick, bDblClick, bColor )
   METHOD Activate()
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, ;
      bSize, ctoolt, bClick, bDblClick, bColor ) CLASS HSayImage

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, ;
      Iif( nWidth != Nil, nWidth, 0 ), iif( nHeight != Nil, nHeight, 0 ),, ;
      bInit, bSize,, ctoolt,, bColor )

   ::title := ""

   ::bClick := bClick
   ::bDblClick := bDblClick

   RETURN Self

METHOD Activate() CLASS HSayImage

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD End() CLASS HSayImage

   IF !::lNoRelease
      IF ::oImage != Nil
         ::oImage:Release()
         ::oImage := Nil
      ENDIF
   ENDIF

   RETURN ::Super:End()

   //- HSayBmp

CLASS HSayBmp INHERIT HSayImage

   DATA nOffsetV  INIT 0
   DATA nOffsetH  INIT 0
   DATA nZoom
   DATA lTransp, trcolor
   DATA nStretch
   DATA nBorder, oPen

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctoolt, bClick, bDblClick, lTransp, nStretch, trcolor, bColor )
   METHOD INIT
   METHOD onEvent( msg, wParam, lParam )
   METHOD Paint()
   METHOD ReplaceBitmap( Image, lRes )

   METHOD Refresh() INLINE hwg_Redrawwindow( ::handle )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctoolt, bClick, bDblClick, lTransp, nStretch, trcolor, bColor ) CLASS HSayBmp

   * Parameters not used
   HB_SYMBOL_UNUSED(nStretch)

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, ;
         bInit, bSize, ctoolt, bClick, bDblClick, bColor )

   ::lTransp := Iif( lTransp = Nil, .F. , lTransp )
   ::trcolor := Iif( trcolor = Nil, 16777215, trcolor )
   ::nBorder := 0
   ::tColor := 0

   IF Image != Nil
      IF Valtype( Image ) == "O"
         ::oImage := Image
         ::lNoRelease := .T.
      ELSE
         ::oImage := Iif( !Empty(lRes) .OR. ValType( Image ) == "N", ;
            HBitmap():AddResource( Image ),   ;
            Iif( ValType( Image ) == "C",     ;
            HBitmap():AddFile( Image ), Nil ) )
         IF Empty( ::oImage )
            RETURN Nil
         ENDIF
      ENDIF
      IF nWidth == Nil .OR. nHeight == Nil
         ::nWidth  := ::oImage:nWidth
         ::nHeight := ::oImage:nHeight
      ENDIF
   ENDIF
   ::Activate()

   RETURN Self

METHOD INIT() CLASS HSayBmp

   IF !::lInit
      ::Super:Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HSayBmp

   * Parameters not used
   HB_SYMBOL_UNUSED(wParam)
   HB_SYMBOL_UNUSED(lParam)

   IF msg == WM_PAINT
      ::Paint()
   ENDIF

   RETURN 0

METHOD Paint() CLASS HSayBmp

   LOCAL hDC := hwg_Getdc( ::handle )

   IF ::brush != Nil
      hwg_Fillrect( hDC, ::nOffsetH, ::nOffsetV, ::nWidth, ::nHeight, ::brush:handle )
   ENDIF
   IF ::oImage != Nil
      IF ::nZoom == Nil
         IF ::lTransp
            hwg_Drawtransparentbitmap( hDC, ::oImage:handle, ::nOffsetH, ;
               ::nOffsetV, ::trColor, ::nWidth, ::nHeight )
         ELSE
            hwg_Drawbitmap( hDC, ::oImage:handle, , ::nOffsetH, ;
               ::nOffsetV, ::nWidth, ::nHeight )
         ENDIF
      ELSE
         hwg_Drawbitmap( hDC, ::oImage:handle, , ::nOffsetH, ;
            ::nOffsetV, ::oImage:nWidth * ::nZoom, ::oImage:nHeight * ::nZoom )
      ENDIF
   ENDIF
   IF ::nBorder > 0
      IF ::oPen == Nil
         ::oPen := HPen():Add( BS_SOLID, ::nBorder, ::tColor )
      ENDIF
      hwg_Selectobject( hDC, ::oPen:handle )
      hwg_Rectangle( hDC, ::nOffsetH, ::nOffsetV, ::nOffsetH+::nWidth-1-::nBorder, ::nOffsetV+::nHeight-1-::nBorder )
   ENDIF
   hwg_Releasedc( ::handle, hDC )

   RETURN Nil

METHOD ReplaceBitmap( Image, lRes ) CLASS HSayBmp

   IF ::oImage != Nil .AND. !::lNoRelease
      ::oImage:Release()
      ::oImage := Nil
   ENDIF
   IF !Empty( Image )
      IF Valtype( Image ) == "O"
         ::oImage := Image
         ::lNoRelease := .T.
      ELSE
         ::oImage := Iif( !Empty(lRes) .OR. ValType( Image ) == "N",  ;
            HBitmap():AddResource( Image ), ;
            Iif( ValType( Image ) == "C", HBitmap():AddFile( Image ), Nil ) )
         ::lNoRelease := .F.
      ENDIF
   ENDIF

   RETURN Nil

   //- HSayIcon

CLASS HSayIcon INHERIT HSayImage

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctoolt )
   METHOD Activate()

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctoolt ) CLASS HSayIcon

   ::Super:New( oWndParent, nId, SS_ICON, nLeft, nTop, nWidth, nHeight, bInit, bSize, ctoolt )

   IF Valtype( Image ) == "O"
      ::oImage := Image
      ::lNoRelease := .T.
   ELSE
      ::oImage := Iif( !Empty(lRes) .OR. ValType( Image ) == "N", ;
         HIcon():AddResource( Image , nWidth, nHeight ),  ;
         Iif( ValType( Image ) == "C",  ;
         HIcon():AddFile( Image , nWidth, nHeight ), Nil ) )
   ENDIF

   ::Activate()

   RETURN Self

/*
 * GTK4: HWG_CREATESTATIC with SS_ICON now creates a GtkImage.  We attach
 * the pixbuf right after creation via hwg_StaticSetImage().
 */
METHOD Activate() CLASS HSayIcon

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
      IF ::oImage != Nil
         hwg_StaticSetImage( ::handle, ::oImage:handle )
      ENDIF
   ENDIF

   RETURN Nil


FUNCTION hwg_GetBitmapHeight( handle )

   LOCAL aBmpSize

   aBmpSize  := hwg_Getbitmapsize( handle )

   RETURN aBmpSize[2]

FUNCTION hwg_GetBitmapWidth( handle )

   LOCAL aBmpSize

   aBmpSize  := hwg_Getbitmapsize( handle )

   RETURN aBmpSize[1]
