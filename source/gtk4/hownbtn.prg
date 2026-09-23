/*
 * $Id: hownbtn.prg 3346 2023-10-03 13:27:29Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HOwnButton class, which implements owner drawn buttons
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4, *but* it depends on a C-side
 * behaviour that has to be preserved in window.c:
 *
 *     MouseMove() detects "the pointer just entered the widget" via
 *     the bit 0x10 of wParam on WM_MOUSEMOVE.  In GTK2 this bit was
 *     set by the GDK_ENTER_NOTIFY handler.  In GTK4 it must be set
 *     explicitly by the "enter" signal of GtkEventControllerMotion.
 *
 *     Without that, the OBTN_MOUSOVER state is never reached and the
 *     button shows no hover feedback.
 *
 * See window.c: cb_motion_enter() and hwg_install_widget_events().
 */

#include "inkey.ch"
#include "hbclass.ch"
#include "hwgui.ch"

CLASS HOwnButton INHERIT HControl

   CLASS VAR cPath SHARED
   DATA winclass   INIT "OWNBTN"
   DATA lFlat
   DATA aStyle
   DATA state
   DATA bClick
   DATA lPress   INIT .F.
   DATA lCheck  INIT .F.
   DATA oFont, xt, yt, widtht, heightt
   DATA oBitmap, xb, yb, widthb, heightb
   DATA oPen1, oPen2
   DATA lTransp  INIT .F.
   DATA trColor
   DATA lEnabled INIT .T.
   DATA nOrder
   DATA oTimer
   DATA nPeriod  INIT 0

   METHOD New( oWndParent, nId, aStyles, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bClick, lflat,              ;
      cText, color, font, xt, yt, widtht, heightt,        ;
      bmp, lResour, xb, yb, widthb, heightb, lTr, trColor, ;
      cTooltip, lEnabled, lCheck, bColor )

   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint()
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
      cText, color, font, xt, yt, widtht, heightt,       ;
      bmp, lResour, xb, yb, widthb, heightb, lTr, trColor, ;
      cTooltip, lEnabled, lCheck, bColor  ) CLASS HOwnButton

   ::Super:New( oWndParent, nId,, nLeft, nTop, nWidth, nHeight, font, bInit, ;
      bSize, bPaint, cTooltip )

   ::lFlat   := Iif( lFlat == Nil, .F. , lFlat )
   ::bClick  := bClick
   ::state   := OBTN_INIT
   ::nOrder  := Iif( oWndParent == nil, 0, Len( oWndParent:aControls ) )

   ::aStyle  := aStyles
   ::title   := cText
   ::tcolor  := Iif( color == Nil, 0, color )
   IF bColor != Nil
      ::bcolor := bcolor
      ::brush  := HBrush():Add( bcolor )
   ENDIF
   ::xt      := xt
   ::yt      := yt
   ::widtht  := widtht
   ::heightt := heightt

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
         * otherwise load from file or resource container
         ::oBitmap := Iif( ( lResour != Nil .AND. lResour ) .OR. ValType( bmp ) == "N", ;
            HBitmap():AddResource( bmp ), ;
            HBitmap():AddFile( Iif( ::cPath != Nil,::cPath + bmp,bmp ) ) )
      ENDIF
      IF ::oBitmap != Nil .AND. lTr != Nil .AND. lTr
         ::lTransp := .T.
      ENDIF
   ENDIF
   ::xb      := xb
   ::yb      := yb
   ::widthb  := widthb
   ::heightb := heightb
   ::trColor := Iif( trColor != Nil, trColor, 16777215 )

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HOwnButton

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createownbtn( ::oParent:handle, ::id, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
      IF !::lEnabled
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
   ELSEIF msg == WM_LBUTTONDOWN
      ::MDown()
      h := hwg_Setfocus( ::handle )
   ELSEIF msg == WM_LBUTTONDBLCLK
      /* Asmith 2017-06-06 workaround for touch terminals */
      IF ::bClick != Nil .AND. Empty( ::oTimer )
         Eval( ::bClick, Self, 0 )
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      ::MUp()
      hwg_Setfocus( h )
   ELSEIF msg == WM_MOUSEMOVE
      ::MouseMove( wParam, lParam )

   ELSEIF msg == WM_MOUSELEAVE
      IF ::state != OBTN_INIT
         IF !Empty( ::oTimer )
            OwnBtnTimerProc( Self, 2 )
            ::oTimer:End()
            ::oTimer := Nil
         ENDIF
         IF !::lPress
            ::state := OBTN_NORMAL
            hwg_Redrawwindow( ::handle )
         ENDIF
     ENDIF

   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

   RETURN 0

METHOD Init() CLASS HOwnButton

   LOCAL bColor
   IF !::lInit
      bColor := ::bColor
      ::bColor := Nil
      ::Super:Init()
      ::bColor := bColor
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD Paint() CLASS HOwnButton

   LOCAL hDC := hwg_Getdc( ::handle )
   LOCAL aCoors, aMetr, x1, y1, x2, y2, n
   LOCAL nwidthb  && for ::widthb

   aCoors := hwg_Getclientrect( ::handle )

   IF !Empty( ::aStyle )
      n := Len( ::aStyle )
      n := Iif( ::state == OBTN_MOUSOVER, Iif( n > 2, 3, 1 ), ;
            Iif( ::state == OBTN_PRESSED, Iif( n > 1, 2, 1 ), 1 ) )
      ::aStyle[n]:Draw( hDC, 0, 0, aCoors[3], aCoors[4] )

   ELSEIF ::lFlat
      IF ::state == OBTN_NORMAL
         hwg_Drawbutton( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], 0 )
      ELSEIF ::state == OBTN_MOUSOVER
         hwg_Drawbutton( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], 1 )
      ELSEIF ::state == OBTN_PRESSED
         hwg_Drawbutton( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], 2 )
      ENDIF
   ELSE
      IF ::state == OBTN_NORMAL
         hwg_Drawbutton( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], 5 )
      ELSEIF ::state == OBTN_PRESSED
         hwg_Drawbutton( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], 6 )
      ENDIF
   ENDIF

   IF !Empty( ::brush )
      hwg_Fillrect( hDC, aCoors[ 1 ] + 2, aCoors[ 2 ] + 2, aCoors[ 3 ] - 2, aCoors[ 4 ] - 2, ::brush:handle )
   ENDIF

   IF ::oBitmap != Nil
      IF ::widthb == Nil .OR. ::widthb == 0
         ::widthb := ::oBitmap:nWidth
         ::heightb := ::oBitmap:nHeight
      ENDIF
      * DF7BE bugfix: crashes here at bitmap resource, so added this:
      IF ::widthb == NIL
         nwidthb := 0
      ELSE
         nwidthb := ::widthb
      ENDIF

      x1 := Iif( ::xb != Nil .AND. ::xb != 0, ::xb, ;
         Round( ( aCoors[3] - aCoors[1] - nwidthb ) / 2, 0 ) )
      y1 := Iif( ::yb != Nil .AND. ::yb != 0, ::yb, ;
         Round( ( aCoors[4] - aCoors[2] - nwidthb ) / 2, 0 ) )
      IF ::lEnabled
         IF ::lTransp
            hwg_Drawtransparentbitmap( hDC, ::oBitmap:handle, x1, y1, ::trColor )
         ELSE
            hwg_Drawbitmap( hDC, ::oBitmap:handle, , x1, y1 )
         ENDIF
      ELSE
         hwg_Drawgraybitmap( hDC, ::oBitmap:handle, x1, y1 )
      ENDIF
   ENDIF

   IF ::title != Nil
      IF ::oFont != Nil
         hwg_Selectobject( hDC, ::oFont:handle )
      ELSEIF ::oParent:oFont != Nil
         hwg_Selectobject( hDC, ::oParent:oFont:handle )
      ENDIF
      aMetr := hwg_Gettextmetric( hDC )
      IF ::lEnabled
         hwg_Settextcolor( hDC, ::tcolor )
      ELSE
         hwg_Settextcolor( hDC, 0 )
      ENDIF
      x1 := Iif( ::xt != Nil .AND. ::xt != 0, ::xt, aCoors[1] + 2 )
      y1 := Iif( ::yt != Nil .AND. ::yt != 0, ::yt, ;
         Round( ( aCoors[4] - aCoors[2] - aMetr[1] ) / 2, 0 ) )
      x2 := Iif( ::widtht != Nil .AND. ::widtht != 0, ;
         ::xt + ::widtht - 1, aCoors[3] - 2 )
      y2 := Iif( ::heightt != Nil .AND. ::heightt != 0, ;
         ::yt + ::heightt - 1, y1 + aMetr[1] )
      hwg_Drawtext( hDC, ::title, x1, y1, x2, y2, Iif( ::xt != Nil .AND. ::xt != 0,DT_LEFT,DT_CENTER ) )
   ENDIF
   hwg_Releasedc( ::handle, hDC )

   RETURN Nil

METHOD MouseMove( wParam, lParam )  CLASS HOwnButton

   LOCAL lEnter := ( hwg_BitAnd( wParam,16 ) > 0 )

   HB_SYMBOL_UNUSED(lParam)

   IF ::state != OBTN_INIT
      IF lEnter .AND. ::state == OBTN_NORMAL
         ::state := OBTN_MOUSOVER
         hwg_Redrawwindow( ::handle )
      ENDIF
   ENDIF

   RETURN Nil

METHOD MDown()  CLASS HOwnButton

   IF ::state != OBTN_PRESSED
      ::state := OBTN_PRESSED
      hwg_Redrawwindow( ::handle )
      IF ::nPeriod > 0
         ::oTimer := HTimer():New( Self,, ::nPeriod, {|o|OwnBtnTimerProc(o,1)} )
         OwnBtnTimerProc( Self, 0 )
      ENDIF
   ENDIF

   RETURN Nil

METHOD MUp() CLASS HOwnButton

   IF ::state == OBTN_PRESSED
      IF !::lPress
         ::state := OBTN_NORMAL
      ENDIF
      IF ::lCheck
         IF ::lPress
            ::Release()
         ELSE
            ::Press()
         ENDIF
      ENDIF
      IF !Empty( ::oTimer )
         OwnBtnTimerProc( Self, 2 )
         ::oTimer:End()
         ::oTimer := Nil
      ELSE
         IF ::bClick != Nil
            Eval( ::bClick, Self )
         ENDIF
      ENDIF
      hwg_Redrawwindow( ::handle )
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
   hwg_Redrawwindow( ::handle )

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

   RETURN Nil

METHOD Enable() CLASS HOwnButton

   hwg_Enablewindow( ::handle, .T. )
   ::lEnabled := .T.
   hwg_Redrawwindow( ::handle )

   RETURN Nil

METHOD Disable() CLASS HOwnButton

   ::state   := OBTN_INIT
   ::lEnabled := .F.
   hwg_Redrawwindow( ::handle )
   hwg_Enablewindow( ::handle, .F. )

   RETURN Nil

STATIC FUNCTION OwnBtnTimerProc( oBtn, nType )

   IF oBtn:bClick != Nil
      Eval( oBtn:bClick, oBtn, nType )
   ENDIF

   RETURN Nil
