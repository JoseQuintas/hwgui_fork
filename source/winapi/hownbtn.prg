/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HOwnButton class, which implements owner drawn buttons
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "inkey.ch"
#include "hbclass.ch"
#include "common.ch"

CLASS HOwnButton INHERIT HControl

   CLASS VAR cPath SHARED
   DATA winclass   INIT "HBOARD"
   DATA lFlat
   DATA aStyle
   DATA state
   DATA bClick
   DATA lPress  INIT .F.
   DATA lCheck  INIT .F.
   DATA xt, yt, widtht, heightt
   DATA oBitmap, xb, yb, widthb, heightb, lTransp, trColor
   DATA oPen1, oPen2
   DATA lEnabled INIT .T.
   DATA nOrder
   DATA oTimer
   DATA nPeriod  INIT 0

   METHOD New( oWndParent, nId, aStyles, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bClick, lflat,                 ;
      cText, color, ofont, xt, yt, widtht, heightt,        ;
      bmp, lResour, xb, yb, widthb, heightb, lTr, trColor, ;
      cTooltip, lEnabled, lCheck, bColor )

   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Redefine( oWndParent, nId, bInit, bSize, bPaint, bClick, lflat, ;
      cText, color, font, xt, yt, widtht, heightt,     ;
      bmp, lResour, xb, yb, widthb, heightb, lTr,      ;
      cTooltip, lEnabled, lCheck )
   METHOD Paint()
   METHOD DrawItems( hDC )
   METHOD MouseMove( wParam, lParam )
   METHOD MDown()
   METHOD MUp()
   METHOD Press()   INLINE ( ::lPress := .T. , ::MDown() )
   METHOD SetTimer( nPeriod )
   METHOD RELEASE()
   METHOD End()
   METHOD Enable()
   METHOD Disable()

ENDCLASS

METHOD New( oWndParent, nId, aStyles, nLeft, nTop, nWidth, nHeight,   ;
      bInit, bSize, bPaint, bClick, lflat,             ;
      cText, color, oFont, xt, yt, widtht, heightt,       ;
      bmp, lResour, xb, yb, widthb, heightb, lTr, trColor, ;
      cTooltip, lEnabled, lCheck, bColor ) CLASS HOwnButton

   ::Super:New( oWndParent, nId,, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, cTooltip )

   IF oFont == Nil
      ::oFont := ::oParent:oFont
   ENDIF
   ::aStyle  := aStyles
   ::lflat   := iif( lflat == Nil, .F. , lflat )
   ::bClick  := bClick
   ::state   := OBTN_INIT
   ::nOrder  := Iif( oWndParent == nil, 0, Len( oWndParent:aControls ) )

   ::title   := cText
   ::tcolor  := Iif( color == Nil, hwg_Getsyscolor( COLOR_BTNTEXT ), color )
   IF bColor != Nil
      ::bcolor := bcolor
      ::brush  := HBrush():Add( bcolor )
   ENDIF
   ::xt      := iif( xt == Nil, 0, xt )
   ::yt      := iif( yt == Nil, 0, yt )
   ::widtht  := iif( widtht == Nil, 0, widtht )
   ::heightt := iif( heightt == Nil, 0, heightt )

   IF lEnabled != Nil
      ::lEnabled := lEnabled
   ENDIF
   IF lCheck != Nil
      ::lCheck := lCheck
   ENDIF
   IF bmp != Nil
      IF ValType( bmp ) == "O"
         * Valid bitmap object
         ::oBitmap := bmp
      ELSE
         ::oBitmap := iif( ( lResour != Nil .AND. lResour ) .OR. ValType( bmp ) == "N", ;
            HBitmap():AddResource( bmp ), ;
            HBitmap():AddFile( iif( ::cPath != Nil, ::cPath + bmp, bmp ) ) )
      ENDIF
   ENDIF
   ::xb      := xb
   ::yb      := yb
   ::widthb  := iif( widthb == Nil, 0, widthb )
   ::heightb := iif( heightb == Nil, 0, heightb )
   ::lTransp := iif( lTr != Nil, lTr, .F. )
   ::trColor := trColor

   hwg_RegBoard()
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HOwnButton

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_CreateBoard( ::oParent:handle, ::id, 0, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
      IF ! ::lEnabled
         hwg_Enablewindow( ::handle, .F. )
         ::Disable()
      ENDIF

   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HOwnButton

   STATIC h

   IF msg == WM_PAINT
      IF ::state == OBTN_INIT
         ::state := OBTN_NORMAL
      ENDIF
      IF ::bPaint != Nil
         Eval( ::bPaint, Self )
      ELSE
         ::Paint()
      ENDIF
   ELSEIF msg == WM_ERASEBKGND
      RETURN 1
   ELSEIF msg == WM_MOUSEMOVE
      IF ::MouseMove( wParam, lParam ) .AND. !Empty( h )
         hwg_Setfocus( h )
         h := Nil
      ENDIF
   ELSEIF msg == WM_LBUTTONDOWN
      h := hwg_Setfocus( ::handle )
      ::MDown()

   ELSEIF msg == WM_LBUTTONDBLCLK
      /* Asmith 2017-06-06 workaround for touch terminals */
      IF ::bClick != Nil .AND. Empty( ::oTimer )
         Eval( ::bClick, Self, 0 )
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      ::MUp()
      IF hwg_Isptreq( ::handle, hwg_Getfocus() ) .AND. !Empty( h )
         hwg_Setfocus( h )
      ENDIF
      h := Nil
   ELSEIF msg == WM_DESTROY
      ::End()
   ELSEIF msg == WM_SETFOCUS
      IF ! Empty( ::bGetfocus )
         Eval( ::bGetfocus, Self, msg, wParam, lParam )
      ENDIF
   ELSEIF msg == WM_KILLFOCUS
      ::release()
      IF ! Empty( ::bLostfocus )
         Eval( ::bLostfocus, Self, msg, wParam, lParam )
      ENDIF
   ELSE
      IF ! Empty( ::bOther )
         Eval( ::bOther, Self, msg, wParam, lParam )
      ENDIF
   ENDIF

   RETURN -1

METHOD Init() CLASS HOwnButton

   IF ! ::lInit
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      ::Super:Init()
   ENDIF

   RETURN Nil

METHOD Redefine( oWndParent, nId, bInit, bSize, bPaint, bClick, lflat, ;
      cText, color, font, xt, yt, widtht, heightt,     ;
      bmp, lResour, xb, yb, widthb, heightb, lTr,      ;
      cTooltip, lEnabled, lCheck ) CLASS HOwnButton

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, , bInit, bSize, bPaint, cTooltip )

   ::lflat   := iif( lflat == Nil, .F. , lflat )
   ::bClick  := bClick
   ::state   := OBTN_INIT

   ::title   := cText
   ::tcolor  := iif( color == Nil, hwg_Getsyscolor( COLOR_BTNTEXT ), color )
   ::ofont   := font
   ::xt      := iif( xt == Nil, 0, xt )
   ::yt      := iif( yt == Nil, 0, yt )
   ::widtht  := iif( widtht == Nil, 0, widtht )
   ::heightt := iif( heightt == Nil, 0, heightt )

   /* FIXED: Removed duplicate lEnabled check */
   IF lEnabled != Nil
      ::lEnabled := lEnabled
   ENDIF
   IF lCheck != Nil
      ::lCheck := lCheck
   ENDIF

   IF bmp != Nil
      IF ValType( bmp ) == "O"
         ::oBitmap := bmp
      ELSE
         ::oBitmap := iif( lResour, HBitmap():AddResource( bmp ), ;
            HBitmap():AddFile( bmp ) )
      ENDIF
   ENDIF
   ::xb      := xb
   ::yb      := yb
   ::widthb  := iif( widthb == Nil, 0, widthb )
   ::heightb := iif( heightb == Nil, 0, heightb )
   ::lTransp := iif( lTr != Nil, lTr, .F. )
   hwg_RegBoard()

   RETURN Self

METHOD Paint() CLASS HOwnButton

   LOCAL pps, hDC, aCoors, n

   pps := hwg_Definepaintstru()

   hDC := hwg_Beginpaint( ::handle, pps )

   aCoors := hwg_Getclientrect( ::handle )

   IF ::nWidth != aCoors[3] .OR. ::nHeight != aCoors[4]
      ::nWidth  := aCoors[3]
      ::nHeight := aCoors[4]
   ENDIF

   IF !Empty( ::aStyle )
      n := Len( ::aStyle )
      n := Iif( ::state == OBTN_MOUSOVER, Iif( n > 2, 3, 1 ), ;
         Iif( ::state == OBTN_PRESSED, Iif( n > 1, 2, 1 ), 1 ) )
      /* FIXED: Added Nil check before calling Draw */
      IF ::aStyle[n] != Nil
         ::aStyle[n]:Draw( hDC, 0, 0, aCoors[3], aCoors[4] )
      ENDIF

   ELSEIF ::lFlat
      IF ::state == OBTN_NORMAL
         IF ::handle != hwg_Getfocus()
            // NORM
            hwg_Drawbutton( hDC, 0, 0, aCoors[3], aCoors[4], 0 )
         ELSE
            hwg_Drawbutton( hDC, 0, 0, aCoors[3], aCoors[4], 1 )
         ENDIF
      ELSEIF ::state == OBTN_MOUSOVER
         hwg_Drawbutton( hDC, 0, 0, aCoors[3], aCoors[4], 1 )
      ELSEIF ::state == OBTN_PRESSED
         hwg_Drawbutton( hDC, 0, 0, aCoors[3], aCoors[4], 2 )
      ENDIF
   ELSE
      IF ::state == OBTN_NORMAL
         hwg_Drawbutton( hDC, 0, 0, aCoors[3], aCoors[4], 5 )
      ELSEIF ::state == OBTN_PRESSED
         hwg_Drawbutton( hDC, 0, 0, aCoors[3], aCoors[4], 6 )
      ENDIF
   ENDIF

   ::DrawItems( hDC )

   hwg_Endpaint( ::handle, pps )

   RETURN Nil

METHOD DrawItems( hDC ) CLASS HOwnButton

   LOCAL x1, y1, x2, y2, aCoors

   aCoors := hwg_Getclientrect( ::handle )
   IF !Empty( ::brush )
      hwg_Fillrect( hDC, aCoors[ 1 ] + 2, aCoors[ 2 ] + 2, aCoors[ 3 ] - 2, aCoors[ 4 ] - 2, ::brush:handle )
   ENDIF

   /* FIXED: Added Nil check for ::oBitmap */
   IF ::oBitmap != Nil
      IF ::widthb == 0
         ::widthb := ::oBitmap:nWidth
         ::heightb := ::oBitmap:nHeight
      ENDIF
      x1 := Iif( ::xb != Nil .AND. ::xb != 0, ::xb, ;
         Round( ( ::nWidth - ::widthb ) / 2, 0 ) )
      y1 := Iif( ::yb != Nil .AND. ::yb != 0, ::yb, ;
         Round( ( ::nHeight - ::heightb ) / 2, 0 ) )
      IF ::lEnabled
         /* FIXED: Added safety check for ClassName before calling */
         IF ::oBitmap:ClassName() == "HICON"
            hwg_DrawiconEx( hDC, ::oBitmap:handle, x1, y1, ::widthb, ::heightb )
         ELSE
            IF ::lTransp
               hwg_Drawtransparentbitmap( hDC, ::oBitmap:handle, x1, y1, ::trColor )
            ELSE
               hwg_Drawbitmap( hDC, ::oBitmap:handle, , x1, y1, ::widthb, ::heightb )
            ENDIF
         ENDIF
      ELSE
         hwg_Drawgraybitmap( hDC, ::oBitmap:handle, x1, y1 )
      ENDIF
   ENDIF

   IF ::title != Nil
      IF ::oFont != Nil
         hwg_Selectobject( hDC, ::oFont:handle )
      ENDIF
      IF ::lEnabled
         hwg_Settextcolor( hDC, ::tcolor )
      ELSE
         hwg_Settextcolor( hDC, hwg_ColorRgb2N( 255, 255, 255 ) )
      ENDIF
      x1 := iif( ::xt != 0, ::xt, 4 )
      y1 := iif( ::yt != 0, ::yt, 4 )
      x2 := ::nWidth - 4
      y2 := ::nHeight - 4
      hwg_Settransparentmode( hDC, .T. )
      hwg_Drawtext( hDC, ::title, x1, y1, x2, y2, ;
         iif( ::xt != 0, DT_LEFT, DT_CENTER ) + iif( ::yt != 0, DT_TOP, DT_VCENTER + DT_SINGLELINE ) )
      hwg_Settransparentmode( hDC, .F. )
   ENDIF

   RETURN Nil

METHOD MouseMove( wParam, lParam )  CLASS HOwnButton

   LOCAL xPos, yPos
   LOCAL res := .F.

   HB_SYMBOL_UNUSED( wParam )

   IF ::state != OBTN_INIT
      xPos := hwg_Loword( lParam )
      yPos := hwg_Hiword( lParam )
      IF xPos > ::nWidth .OR. yPos > ::nHeight
         hwg_Releasecapture()
         IF !Empty( ::oTimer )
            OwnBtnTimerProc( Self, 2 )
            ::oTimer:End()
            ::oTimer := Nil
         ENDIF
         res := .T.
      ENDIF

      IF res .AND. ! ::lPress
         ::state := OBTN_NORMAL
         hwg_Invalidaterect( ::handle, 0 )
      ENDIF
      IF ::state == OBTN_NORMAL .AND. ! res
         ::state := OBTN_MOUSOVER
         hwg_Invalidaterect( ::handle, 0 )
         hwg_Setcapture( ::handle )
      ENDIF
   ENDIF

   RETURN res

METHOD MDown()  CLASS HOwnButton

   IF ::state != OBTN_PRESSED
      ::state := OBTN_PRESSED
      hwg_Invalidaterect( ::handle, 0 )
      IF ::nPeriod > 0
         ::oTimer := HTimer():New( Self,, ::nPeriod, {|o|OwnBtnTimerProc(o,1)} )
         OwnBtnTimerProc( Self, 0 )
      ENDIF
   ENDIF

   RETURN Nil

METHOD MUp() CLASS HOwnButton

   IF ::state == OBTN_PRESSED
      IF ! ::lPress
         ::state := iif( ::lFlat, OBTN_MOUSOVER, OBTN_NORMAL )
      ENDIF
      IF ::lCheck
         IF ::lPress
            ::Release()
         ELSE
            ::Press()
         ENDIF
      ENDIF
      IF !Empty( ::oTimer )
         hwg_Releasecapture()
         OwnBtnTimerProc( Self, 2 )
         ::oTimer:End()
         ::oTimer := Nil
      ELSE
         IF ::bClick != Nil
            hwg_Releasecapture()
            Eval( ::bClick, Self )
         ENDIF
      ENDIF
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF

   RETURN Nil

METHOD SetTimer( nPeriod )  CLASS HOwnButton

   IF nPeriod == Nil
      IF !Empty( ::oTimer )
         OwnBtnTimerProc( Self, 2 )
         ::oTimer:End()
         ::oTimer := Nil
      ENDIF
      ::nPeriod := 0
   ELSE
      ::nPeriod := nPeriod
   ENDIF

   RETURN Nil

METHOD RELEASE()  CLASS HOwnButton

   ::lPress := .F.
   ::state := OBTN_NORMAL
   hwg_Invalidaterect( ::handle, 0 )

   RETURN Nil

METHOD End()  CLASS HOwnButton

   ::Super:End()
   ::oFont := Nil
   IF ::oBitmap != Nil
      ::oBitmap:Release()
      ::oBitmap := Nil
   ENDIF
   IF !Empty( ::oTimer )
      ::oTimer:End()
      ::oTimer := Nil
   ENDIF
   hwg_Postmessage( ::handle, WM_CLOSE, 0, 0 )

   RETURN Nil

METHOD Enable() CLASS HOwnButton

   hwg_Enablewindow( ::handle, .T. )
   ::lEnabled := .T.
   hwg_Invalidaterect( ::handle, 0 )

   RETURN Nil

METHOD Disable() CLASS HOwnButton

   ::state   := OBTN_INIT
   ::lEnabled := .F.
   hwg_Invalidaterect( ::handle, 0 )
   hwg_Enablewindow( ::handle, .F. )

   RETURN Nil

STATIC FUNCTION OwnBtnTimerProc( oBtn, nType )

   IF oBtn:bClick != Nil
      Eval( oBtn:bClick, oBtn, nType )
   ENDIF

   RETURN Nil