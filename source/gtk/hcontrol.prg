/*
 *$Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HControl, HStatus, HStatic, HButton, HGroup, HLine classes
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * ButtonEx class
 *
 * Copyright 2008 Luiz Rafael Culik Guimaraes <luiz at xharbour.com.br >
 * www - http://sites.uol.com.br/culikr/

*/

#include "hwgui.ch"
#include "hbclass.ch"

REQUEST HWG_ENDWINDOW

#define  CONTROL_FIRST_ID   34000

FUNCTION hwg_SetCtrlName( oCtrl, cName )

   LOCAL nPos

   IF !Empty( cName ) .AND. ValType( cName ) == "C" .AND. ! "[" $ cName
      IF ( nPos :=  RAt( ":", cName ) ) > 0 .OR. ( nPos :=  RAt( ">", cName ) ) > 0
         cName := SubStr( cName, nPos + 1 )
      ENDIF
      oCtrl:objName := Upper( cName )
      IF __ObjHasMsg( oCtrl, "ODEFAULTPARENT" )
         hwg_SetWidgetName( oCtrl:handle, oCtrl:objName )
      ENDIF
   ENDIF

   RETURN Nil

   //- HControl

CLASS HControl INHERIT HCustomWindow

   DATA id
   DATA tooltip
   DATA lInit    INIT .F.
   DATA Anchor   INIT 0

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, ctoolt, tcolor, bcolor )
   METHOD Init()
   METHOD NewId()

   METHOD Disable()
   METHOD Enable()
   METHOD Enabled( lEnabled )
   METHOD SetFont( oFont )

   METHOD Setfocus() INLINE hwg_SetFocus( ::handle )
   METHOD Move( x1, y1, width, height, lMoveParent )
   METHOD End()
   METHOD onAnchor( x, y, w, h )
   METHOD SetTooltip( cText )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, ctoolt, tcolor, bcolor ) CLASS HControl

   ::oParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )
   ::id      := iif( nId == Nil, ::NewId(), nId )
   ::style   := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), WS_VISIBLE + WS_CHILD )
   ::oFont   := oFont
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::bInit   := bInit
   IF ValType( bSize ) == "N"
      ::Anchor := bSize
   ELSE
      ::bSize   := bSize
   ENDIF
   ::bPaint  := bPaint
   ::tooltip := ctoolt
   ::tColor := tColor
   ::bColor := bColor

   ::oParent:AddControl( Self )

   RETURN Self

/* Removed:  lDop  */
METHOD NewId() CLASS HControl

   LOCAL nId := ::oParent:nChildId++

   RETURN nId

METHOD INIT() CLASS HControl

   LOCAL o

   IF !::lInit
      IF ::oFont != Nil
         ::SetFont( ::oFont )
         //hwg_SetCtrlFont( ::handle,, ::oFont:handle )
      ELSEIF ::oParent:oFont != Nil
         ::SetFont( ::oParent:oFont )
      ENDIF
      hwg_Addtooltip( ::handle, ::tooltip )
      IF HB_ISBLOCK( ::bInit )
         Eval( ::bInit, Self )
      ENDIF
      ::Setcolor( ::tcolor, ::bcolor )

      IF ( o := hwg_getParentForm( Self ) ) != Nil .AND. o:lActivated
         hwg_ShowAll( o:handle )
         hwg_HideHidden( o )
      ENDIF
      ::lInit := .T.
   ENDIF

   RETURN Nil

METHOD SetTooltip( cText ) CLASS HControl

   IF cText == NIL
      ::tooltip := ""
   ELSE
      ::tooltip := cText
   ENDIF
   hwg_Deltooltip( ::handle )
   IF .NOT. EMPTY(::tooltip)
      hwg_Addtooltip( ::handle, ::tooltip )
   ENDIF

   RETURN NIL

METHOD Disable() CLASS HControl

   hwg_Enablewindow( ::handle, .F. )

   RETURN NIL

METHOD Enable() CLASS HControl

   hwg_Enablewindow( ::handle, .T. )

   RETURN NIL

METHOD Enabled( lEnabled ) CLASS HControl

   IF lEnabled != Nil
      IF lEnabled
         hwg_Enablewindow( ::handle, .T. )
         RETURN .T.
      ELSE
         hwg_Enablewindow( ::handle, .F. )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN hwg_Iswindowenabled( ::handle )

METHOD SetFont( oFont )

   LOCAL oFontOld := ::oFont

   IF !Empty( oFont )
      ::oFont := oFont
      hwg_SetCtrlFont( ::handle,, ::oFont:handle )
   ENDIF

   RETURN oFontOld

/* Added: lMoveParent */
METHOD Move( x1, y1, width, height, lMoveParent )  CLASS HControl

   LOCAL lMove := .F. , lSize := .F.

   IF x1 != Nil .AND. x1 != ::nLeft
      ::nLeft := x1
      lMove := .T.
   ENDIF
   IF y1 != Nil .AND. y1 != ::nTop
      ::nTop := y1
      lMove := .T.
   ENDIF
   IF width != Nil .AND. width != ::nWidth
      ::nWidth := width
      lSize := .T.
   ENDIF
   IF height != Nil .AND. height != ::nHeight
      ::nHeight := height
      lSize := .T.
   ENDIF
   IF lMove .OR. lSize
      hwg_MoveWidget( ::handle, iif( lMove,::nLeft,Nil ), iif( lMove,::nTop,Nil ), ;
         iif( lSize, ::nWidth, Nil ), iif( lSize, ::nHeight, Nil ), lMoveParent )
   ENDIF

   RETURN Nil

METHOD End() CLASS HControl

   ::Super:End()
   IF ::tooltip != Nil
      // DelToolTip( ::oParent:handle,::handle )
      ::tooltip := Nil
   ENDIF

   RETURN Nil

METHOD onAnchor( x, y, w, h ) CLASS HControl
   RETURN hwg_resize_onAnchor( Self, x, y, w, h )

   //- HStatus

CLASS HStatus INHERIT HControl

   CLASS VAR winclass   INIT "msctls_statusbar32"
   DATA aParts
   METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint )
   METHOD Activate()
   METHOD Init()
   METHOD SetText( t ) INLINE  hwg_WriteStatus( ::oParent,, t )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint ) CLASS HStatus

   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), WS_CHILD + WS_VISIBLE + WS_OVERLAPPED + WS_CLIPSIBLINGS )
   ::Super:New( oWndParent, nId, nStyle, 0, 0, 0, 0, oFont, bInit, bSize, bPaint )

   ::aParts  := aParts
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HStatus
   * Variables not used
   * LOCAL aCoors

   IF !Empty( ::oParent:handle )

      ::handle := hwg_Createstatuswindow( ::oParent:handle, ::id )

      ::Init()
   ENDIF

   RETURN Nil

METHOD Init() CLASS HStatus

   IF !::lInit
      ::Super:Init()
   ENDIF

   RETURN  NIL

   //- HStatic

CLASS HStatic INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
      bSize, bPaint, ctoolt, tcolor, bcolor, lTransp )
   METHOD Activate()
   METHOD Init()
   METHOD SetText( value ) INLINE hwg_static_SetText( ::handle, ::title := value )
   METHOD GetText() INLINE hwg_static_GetText( ::handle )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
      bSize, bPaint, ctoolt, tcolor, bcolor, lTransp ) CLASS HStatic

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, ctoolt, tcolor, bcolor )

   ::title   := cCaption
   IF lTransp != Nil .AND. lTransp
      ::extStyle += WS_EX_TRANSPARENT
   ENDIF

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HStatic

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::extStyle, ::title )
      IF hwg_BitAnd( ::style, SS_OWNERDRAW ) != 0
         hwg_Setwindowobject( ::handle, Self )
      ENDIF
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init()  CLASS HStatic

   IF !::lInit
      ::Super:Init()
   ENDIF
   RETURN Nil

//- HButton

CLASS HButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"

   DATA  oImg
   DATA  bClick

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
      bInit, bSize, bPaint, bClick, ctoolt, tcolor, bcolor, oImg )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD SetText( c )
   METHOD GetText() INLINE hwg_button_GetText( ::handle )
   METHOD SetImage( oImg )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
      bInit, bSize, bPaint, bClick, ctoolt, tcolor, bcolor, oImg ) CLASS HButton

   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), BS_PUSHBUTTON )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, iif( nWidth == Nil,90,nWidth ), ;
      iif( nHeight == Nil, 30, nHeight ), oFont, bInit, ;
      bSize, bPaint, ctoolt, tcolor, bcolor )

   ::title := cCaption
   ::oImg  := oImg
   ::Activate()

   IF ::id == IDOK
      bClick := { ||::oParent:lResult := .T. , ::oParent:Close() }
   ELSEIF ::id == IDCANCEL
      bClick := { ||::oParent:Close() }
   ENDIF
   ::bClick := bClick
   hwg_SetSignal( ::handle, "clicked", WM_LBUTTONUP, 0, 0 )

   RETURN Self

METHOD Activate() CLASS HButton

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createbutton( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title, Iif( !Empty(::oImg), ::oImg:handle, Nil ) )
      hwg_Setwindowobject( ::handle, Self )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HButton

   * Parameters not used
   HB_SYMBOL_UNUSED(wParam)
   HB_SYMBOL_UNUSED(lParam)

   IF msg == WM_LBUTTONUP
      IF ::bClick != Nil
         Eval( ::bClick, Self )
      ENDIF
   ENDIF

   RETURN  NIL


METHOD SetText( c ) CLASS HButton

   hwg_button_SetText( ::handle, ::title := c )

   RETURN NIL

METHOD SetImage( oImg ) CLASS HButton

   hwg_button_SetImage( ::handle, oImg:handle )
   ::Refresh()

   RETURN NIL

   //- HGroup

CLASS HGroup INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
      oFont, bInit, bSize, bPaint, tcolor, bcolor )
   METHOD Activate()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
      oFont, bInit, bSize, bPaint, tcolor, bcolor ) CLASS HGroup

   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), BS_GROUPBOX )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, , tcolor, bcolor )

   ::title   := cCaption
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HGroup

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createbutton( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF

   RETURN Nil

   // hline

CLASS HLine INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA lVert

   METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize )
   METHOD Activate()

ENDCLASS

METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize ) CLASS HLine

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, , , , , bSize, { |o, lp|o:Paint( lp ) } )

   ::title := ""
   ::lVert := iif( lVert == Nil, .F. , lVert )
   IF ::lVert
      ::nWidth  := 10
      ::nHeight := iif( nLength == Nil, 20, nLength )
   ELSE
      ::nWidth  := iif( nLength == Nil, 20, nLength )
      ::nHeight := 10
   ENDIF

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HLine

   IF !Empty( ::oParent:handle )
      ::handle := hwg_CreateSep( ::oParent:handle, ::lVert, ::nLeft, ::nTop, ;
         ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

#define  STATE_NORMAL    0
#define  STATE_PRESSED   1
#define  STATE_MOVER     2
#define  STATE_UNPRESS   3

CLASS HBoard INHERIT HControl

   DATA winclass    INIT "HBOARD"
   DATA lMouseOver  INIT .F.
   DATA oInFocus
   DATA aDrawn      INIT {}
   DATA aSize

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint( hDC )
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor ) CLASS HBoard

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor )
   ::aSize := { ::nWidth, ::nHeight }

   IF ::bColor == Nil
      ::bColor := ::oParent:bColor
   ENDIF

   HDrawn():oDefParent := Self

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HBoard

   IF !Empty( ::oParent:handle )
      ::handle := hwg_CreateBoard( ::oParent:handle,,, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HBoard

   LOCAL nRes, o, o1, nPosX, nPosY

   IF ::bOther != Nil
      IF ( nRes := Eval( ::bOther, Self, msg, wParam, lParam ) ) == 0
         RETURN -1
      ELSEIF nRes == 1
         RETURN 1
      ENDIF
   ENDIF

   IF msg == WM_MOUSEMOVE
      IF !::lMouseOver
         ::lMouseOver := .T.
      ENDIF
      IF ( o := HDrawn():GetByPos( nPosX := hwg_Loword( lParam ), ;
         nPosY := hwg_Hiword( lParam ), Self ) ) != Nil
         o:SetState( STATE_MOVER, nPosX, nPosY )
         o:onMouseMove( nPosX, nPosY )
      ELSE
         HDrawn():GetByState( STATE_PRESSED, ::aDrawn, {|o|o:SetState(STATE_NORMAL,nPosX,nPosY)}, .T. )
         HDrawn():GetByState( STATE_MOVER, ::aDrawn, {|o|o:SetState(STATE_NORMAL,nPosX,nPosY)}, .T. )
      ENDIF

   ELSEIF msg == WM_PAINT
      ::Paint()

   ELSEIF msg == WM_MOUSELEAVE
      ::lMouseOver := .F.
      nPosX := hwg_Loword( lParam )
      nPosY := hwg_Hiword( lParam )
      HDrawn():GetByState( STATE_PRESSED, ::aDrawn, {|o|o:SetState(STATE_NORMAL,nPosX,nPosY)}, .T. )
      HDrawn():GetByState( STATE_MOVER, ::aDrawn, {|o|o:SetState(STATE_NORMAL,nPosX,nPosY)}, .T. )

   ELSEIF msg == WM_LBUTTONDOWN
      IF ( o := HDrawn():GetByPos( nPosX := hwg_Loword( lParam ), ;
         nPosY := hwg_Hiword( lParam ), Self ) ) != Nil .AND. !o:lHide
         IF !Empty( ::oInFocus ) .AND. !( o == ::oInFocus )
            ::oInFocus:onKillFocus()
            ::oInFocus := Nil
         ENDIF
         o:SetState( STATE_PRESSED, nPosX, nPosY )
         o:onButtonDown( msg, nPosX, nPosY )
      ELSEIF !Empty( ::oInFocus )
         ::oInFocus:onKillFocus()
         ::oInFocus := Nil
      ENDIF

   ELSEIF msg == WM_RBUTTONDOWN
      IF ( o := HDrawn():GetByPos( nPosX := hwg_Loword( lParam ), ;
         nPosY := hwg_Hiword( lParam ), Self ) ) != Nil .AND. !o:lHide
         IF !Empty( ::oInFocus ) .AND. !( o == ::oInFocus )
            ::oInFocus:onKillFocus()
            ::oInFocus := Nil
         ENDIF
         o:onButtonDown( msg, nPosX, nPosY )
      ELSEIF !Empty( ::oInFocus )
         ::oInFocus:onKillFocus()
         ::oInFocus := Nil
      ENDIF

   ELSEIF msg == WM_LBUTTONDBLCLK
      IF ( o := HDrawn():GetByPos( nPosX := hwg_Loword( lParam ), ;
         nPosY := hwg_Hiword( lParam ), Self ) ) != Nil .AND. !o:lHide
         o:onButtonDbl( nPosX, nPosY )
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      IF !Empty( o := HDrawn():GetByState( STATE_PRESSED, ::aDrawn ) ) .AND. !o:lHide
         o:SetState( 3, nPosX := hwg_Loword( lParam ), nPosY := hwg_Hiword( lParam ) )
         o:onButtonUp( nPosX, nPosY )
      ENDIF

   ELSEIF msg == WM_GETDLGCODE
      RETURN DLGC_WANTALLKEYS

   ELSEIF msg == WM_KEYDOWN .OR. msg == WM_CHAR
      IF !Empty( ::oInFocus ) .AND. !::oInFocus:lHide
         ::oInFocus:onKey( msg, wParam, lParam )
      ENDIF

   ELSEIF msg == WM_KILLFOCUS
      IF !Empty( ::oInFocus )
         ::oInFocus:onKillFocus()
         ::oInFocus := Nil
      ENDIF

   ELSEIF msg == WM_SIZE

      FOR EACH o IN ::aDrawn
         IF o:bSize != NIL
            Eval( o:bSize, o, hwg_Loword( lParam ), hwg_Hiword( lParam ) )
         ELSEIF o:Anchor != 0
            hwg_resize_onAnchor( o, ::aSize[1], ::aSize[2], hwg_Loword( lParam ), hwg_Hiword( lParam ) )
         ENDIF
         FOR EACH o1 IN o:aDrawn
            IF o1:bSize != NIL
               Eval( o1:bSize, o1, hwg_Loword( lParam ), hwg_Hiword( lParam ) )
            ELSEIF o1:Anchor != 0
               hwg_resize_onAnchor( o1, ::aSize[1], ::aSize[2], hwg_Loword( lParam ), hwg_Hiword( lParam ) )
            ENDIF
         NEXT
      NEXT
      ::aSize[1] := ::nWidth
      ::aSize[2] := ::nHeight
      ::Refresh()

   ELSE
      RETURN ::Super:onEvent( msg, wParam, lParam )

   ENDIF

   RETURN -1

METHOD Init() CLASS HBoard

   IF ! ::lInit
      ::Super:Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD Paint( hDC ) CLASS HBoard

   LOCAL i
   LOCAL pps, l := .F.

   IF hDC == Nil
      pps := hwg_Definepaintstru()
      hDC := hwg_Beginpaint( ::handle, pps )
      l := .T.
   ENDIF

   IF !Empty( ::bPaint )
      IF Eval( ::bPaint, Self, hDC ) == 0
         RETURN Nil
      ENDIF
   ELSEIF l .AND. !Empty( ::brush )
      hwg_Fillrect( hDC, 0, 0, ::nWidth, ::nHeight, ::brush:handle )
   ENDIF

   FOR i := 1 TO Len( ::aDrawn )
      ::aDrawn[i]:Paint( hDC )
   NEXT

   IF l
      hwg_Endpaint( ::handle, pps )
   ENDIF

   RETURN Nil

METHOD End() CLASS HBoard

   LOCAL i

   ::Super:End()
   FOR i := 1 TO Len( ::aDrawn )
      ::aDrawn[i]:End()
   NEXT

   RETURN Nil
