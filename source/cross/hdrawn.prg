/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HDrawn class
 *
 * Copyright 2023 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

#define  STATE_NORMAL    0
#define  STATE_PRESSED   1
#define  STATE_MOVER     2
#define  STATE_UNPRESS   3

#define CLR_BLACK    0
#define CLR_LYELLOW  0xFFFFD9

CLASS HDrawn INHERIT HObject

   CLASS VAR oDefParent SHARED
   DATA oParent
   DATA title
   DATA nTop, nLeft, nWidth, nHeight
   DATA aMargin       INIT { 4,6,2,2 }
   DATA nTextStyle    INIT DT_CENTER
   DATA tcolor, bcolor, oBrush, oPen
   DATA tBorderColor  INIT Nil
   DATA nCorner       INIT 0
   DATA lHide         INIT .F.
   DATA lDisable      INIT .F.
   DATA lStatePaint   INIT .F.
   DATA nState        INIT 0
   DATA oFont
   DATA aStyles
   DATA aDrawn        INIT {}
   DATA xValue        INIT Nil
   DATA nMouseOn      INIT 0
   DATA cTooltip, oTooltip

   DATA bPaint, bPaintItem, bClick, bChgState, bSize
   DATA Anchor        INIT 0

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      title, oFont, bPaint, bClick, bChgState )
   METHOD Delete()
   METHOD GetParentBoard()
   METHOD GetByPos( xPos, yPos, oBoard )
   METHOD GetByState( nState, aDrawn, block, lAll )
   METHOD Paint( hDC )
   METHOD Move( x1, y1, width, height, lRefresh )
   METHOD SetState( nState, nPosX, nPosY )
   METHOD SetText( cText )
   METHOD Value( xValue ) SETGET
   METHOD Refresh( x1, y1, x2, y2 )
   METHOD onMouseMove( xPos, yPos )
   METHOD onMouseLeave()
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )     VIRTUAL
   METHOD onButtonDbl( xPos, yPos )  VIRTUAL
   METHOD onKey( msg, wParam, lParam ) VIRTUAL
   METHOD onKillFocus()  VIRTUAL
   METHOD End()          VIRTUAL

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
   title, oFont, bPaint, bClick, bChgState ) CLASS HDrawn

   ::oParent := Iif( oWndParent==Nil, ::oDefParent, oWndParent )
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::tcolor  := Iif( tcolor == Nil, 0, tcolor )
   ::bColor  := bColor
   ::aStyles := aStyles
   ::title   := title
   ::oFont   := Iif( oFont == Nil, ::oParent:oFont, oFont )
   ::bPaint  := bPaint
   ::bClick  := bClick
   ::bChgState := bChgState

   IF bColor != NIL
      ::oBrush := HBrush():Add( bColor )
   ENDIF

   AAdd( ::oParent:aDrawn, Self )

   RETURN Self

METHOD Delete() CLASS HDrawn

   LOCAL i

   FOR i := Len( ::oParent:aDrawn ) TO 1 STEP -1
      IF ::oParent:aDrawn[i] == Self
         ::oParent:aDrawn := hb_ADel( ::oParent:aDrawn, i, .T. )
         EXIT
      ENDIF
   NEXT

   RETURN Nil

METHOD GetParentBoard() CLASS HDrawn

   LOCAL oParent := ::oParent

   DO WHILE __ObjHasMsg( oParent, "GETPARENTBOARD" ); oParent := oParent:oParent; ENDDO

   RETURN oParent

METHOD GetByPos( xPos, yPos, oBoard ) CLASS HDrawn

   LOCAL aDrawn := Iif( !Empty( oBoard ), oBoard:aDrawn, ::aDrawn ), i, o

   FOR i := Len( aDrawn ) TO 1 STEP -1
      o := aDrawn[i]
      IF !o:lDisable .AND. xPos >= o:nLeft .AND. xPos < o:nLeft + o:nWidth .AND. ;
         yPos >= o:nTop .AND. yPos < o:nTop + o:nHeight
         RETURN o
      ENDIF
   NEXT

   RETURN Nil

METHOD GetByState( nState, aDrawn, block, lAll ) CLASS HDrawn

   LOCAL i, o

   IF Empty( aDrawn )
      aDrawn := ::aDrawn
   ENDIF
   IF lAll == Nil .OR. block == Nil; lAll := .F.; ENDIF

   FOR i := Len( aDrawn ) TO 1 STEP -1
      IF !aDrawn[i]:lDisable
         IF !Empty( aDrawn[i]:aDrawn )
            IF !Empty( o := aDrawn[i]:GetByState( nState,, block, lAll ) ) .AND. !lAll
               RETURN o
            ENDIF
         ENDIF
         IF aDrawn[i]:nState == nState
            IF block != Nil
               Eval( block, aDrawn[i] )
            ENDIF
            IF !lAll
               RETURN aDrawn[i]
            ENDIF
         ENDIF
      ENDIF
   NEXT

   RETURN Nil

METHOD Paint( hDC ) CLASS HDrawn

   LOCAL i, oStyle, arr, y

   IF ::lHide .OR. ::lDisable
      RETURN Nil
   ENDIF
   IF !Empty( ::bPaint )
      IF Eval( ::bPaint, Self, hDC ) == 0
         RETURN Nil
      ENDIF
   ELSE
      IF !Empty( ::aStyles )
        oStyle := Iif( Len(::aStyles) > ::nState, ::aStyles[::nState + 1], ATail(::aStyles) )
      ENDIF
      IF !Empty( oStyle )
         oStyle:Draw( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1 )
      ELSEIF !Empty( ::oBrush )
         IF Empty( ::oPen )
            ::oPen := HPen():Add( BS_SOLID, 1, Iif( ::tBorderColor == Nil, ::bcolor, ::tBorderColor ) )
         ENDIF
         IF ::nCorner > 0
            hwg_RoundRect_Filled( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1, ::nCorner, ::oPen:handle, ::oBrush:handle )
         ELSE
            hwg_Rectangle_Filled( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1, ::oPen:handle, ::oBrush:handle )
         ENDIF
      ELSEIF !( ::tBorderColor == Nil )
         IF Empty( ::oPen )
            ::oPen := HPen():Add( BS_SOLID, 1, ::tBorderColor )
         ENDIF
         IF ::nCorner > 0
            hwg_RoundRect( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1, ::nCorner, ::oPen:handle )
         ELSE
            hwg_Rectangle( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1, ::oPen:handle )
         ENDIF
      ENDIF

      IF !Empty( ::title )
         hwg_Settransparentmode( hDC, .T. )
         hwg_Settextcolor( hDC, ::tColor )
         IF !Empty( ::oFont )
            hwg_SelectObject( hDC, ::oFont:handle )
         ENDIF
         IF Chr(10) $ ::title
            arr := hb_ATokens( ::title, Chr(10) )
            y := ::nTop+::aMargin[2]
            i := 0
            DO WHILE ++i < Len( arr ) .AND. y < ::nTop+::nHeight-::aMargin[4]
               hwg_Drawtext( hDC, arr[i], ::nLeft+::aMargin[1], y, ;
                  ::nLeft+::nWidth-::aMargin[3], ::nTop+::nHeight-::aMargin[4], ::nTextStyle )
               y += hwg_GetTextSize( hDC, arr[i] )[2] + 2
            ENDDO
         ELSE
            hwg_Drawtext( hDC, ::title, ::nLeft+::aMargin[1], ::nTop+::aMargin[2], ;
               ::nLeft+::nWidth-::aMargin[3], ::nTop+::nHeight-::aMargin[4], ::nTextStyle )
         ENDIF
         hwg_Settransparentmode( hDC, .F. )
      ENDIF
      IF !Empty( ::bPaintItem )
         Eval( ::bPaintItem, Self, hDC )
      ENDIF
   ENDIF

   FOR i := 1 TO Len( ::aDrawn )
      ::aDrawn[i]:Paint( hDC )
   NEXT

   RETURN Nil

METHOD Move( x1, y1, width, height, lRefresh ) CLASS HDrawn

   LOCAL x10 := ::nLeft, y10 := ::nTop, x20 := ::nLeft + ::nWidth, y20 := ::nTop + ::nHeight

   IF x1 != Nil; ::nLeft := x1; ENDIF
   IF y1 != Nil; ::nTop := y1; ENDIF
   IF width != Nil; ::nWidth := width; ENDIF
   IF height != Nil; ::nHeight := height; ENDIF

   IF lRefresh == Nil .OR. lRefresh
      ::Refresh( Min(x10,::nLeft), Min(y10,::nTop), Max(x20,::nLeft+::nWidth), Max(y20,::nTop+::nHeight) )
   ENDIF

   RETURN Nil

METHOD SetState( nState, nPosX, nPosY ) CLASS HDrawn

   LOCAL o, nOldstate := ::nState, op

   IF !Empty( ::aDrawn )
      IF  !Empty( o := ::GetByPos( nPosX, nPosY ) )
         IF nOldstate != nState .AND. !Empty( ::bChgState ) .AND. Eval( ::bChgState, Self, nState ) == 0
            RETURN Nil
         ENDIF
         IF nState != STATE_PRESSED
            ::nState := nState
         ENDIF
         RETURN o:SetState( nState, nPosX, nPosY )
      ELSEIF !Empty( o := ::GetByState( STATE_MOVER ) ) .OR. !Empty( o := ::GetByState( STATE_PRESSED ) )
         o:SetState( STATE_NORMAL, nPosX, nPosY )
      ENDIF
   ENDIF
   IF nState != nOldstate
      IF !Empty( ::bChgState )
         IF Eval( ::bChgState, Self, nState ) == 0
            RETURN Nil
         ENDIF
      ENDIF
      IF nState == STATE_MOVER
         IF ( o := ::GetByState( STATE_MOVER, ::oParent:aDrawn ) ) != Nil
            o:SetState( STATE_NORMAL, nPosX, nPosY )
         ENDIF
         IF ::nState != STATE_PRESSED
            ::nState := STATE_MOVER
         ENDIF
      ELSEIF nState == STATE_NORMAL
         IF ::nState == STATE_MOVER .OR. ::nState == STATE_PRESSED
            ::onMouseLeave()
         ENDIF
         ::nState := STATE_NORMAL
      ELSEIF nState == STATE_PRESSED
         ::nState := STATE_PRESSED
      ELSEIF nState == STATE_UNPRESS
         op := HDrawn():GetByState( STATE_PRESSED, ::oParent:aDrawn )
         ::nState := Iif( nPosX >= ::nLeft .AND. nPosX < ::nLeft + ::nWidth .AND. ;
            nPosY >= ::nTop .AND. nPosY < ::nTop + ::nHeight, STATE_MOVER, STATE_NORMAL )
         IF Self == op
            IF !Empty( ::bClick )
               Eval( ::bClick, Self, nPosX, nPosY )
            ENDIF
         ELSEIF !Empty( op )
            op:nState := Iif( nPosX >= op:nLeft .AND. nPosX < op:nLeft + op:nWidth .AND. ;
               nPosY >= op:nTop .AND. nPosY < op:nTop + op:nHeight, STATE_MOVER, STATE_NORMAL )
         ENDIF
      ENDIF
      IF nOldstate != ::nState .AND. ( ::lStatePaint .OR. ( !Empty(::aStyles) .AND. Len(::aStyles) > 1 ) )
         ::Refresh()
      ENDIF
   ENDIF

   RETURN Nil

METHOD SetText( cText ) CLASS HDrawn

   ::title := cText
   ::Refresh()

   RETURN Nil

METHOD Value( xValue ) CLASS HDrawn

   IF xValue != Nil
      ::xValue := xValue
      ::Refresh()
      RETURN xValue
   ENDIF

   RETURN ::xValue

METHOD Refresh( x1, y1, x2, y2 ) CLASS HDrawn

   IF Empty( ::oBrush )
      ::GetParentBoard():Refresh( Iif( x1 == Nil, ::nLeft, x1 ), ;
         Iif( y1 == Nil, ::nTop, y1 ), Iif( x2 == Nil, ::nLeft+::nWidth, x2 ), ;
         Iif( y2 == Nil, ::nTop+::nHeight, y2 ) )
   ELSE
      hwg_Invalidaterect( ::GetParentBoard():handle, 0, Iif( x1 == Nil, ::nLeft, x1 ), ;
         Iif( y1 == Nil, ::nTop, y1 ), Iif( x2 == Nil, ::nLeft+::nWidth, x2 ), ;
         Iif( y2 == Nil, ::nTop+::nHeight, y2 ) )
   ENDIF
   RETURN Nil

METHOD onMouseMove( xPos, yPos ) CLASS HDrawn

   LOCAL o

   IF ( o := ::GetByPos( xPos, yPos ) ) != Nil
      RETURN o:onMouseMove( xPos, yPos )
   ELSEIF ::cToolTip != Nil
      IF ::nMouseOn == 0
         ::nMouseOn := Seconds()
         HTimer():New( ::GetParentBoard(),, 500, ;
            {||Iif(::nMouseOn>0.AND.::nMouseOn<90000,TTonTimer(Self,xPos,yPos),.T.)}, .T. )
      ENDIF
   ENDIF

   RETURN Nil

METHOD onMouseLeave() CLASS HDrawn

   ::nMouseOn := 0
   IF ::oToolTip != Nil
      ::oToolTip:Hide()
   ENDIF
   RETURN Nil

METHOD onButtonDown( msg, xPos, yPos ) CLASS HDrawn

   LOCAL o

   IF ( o := ::GetByPos( xPos, yPos ) ) != Nil .AND. !o:lHide
      o:onButtonDown( msg, xPos, yPos )
   ENDIF
   IF ::oToolTip != Nil
      ::nMouseOn := 90000
      ::oToolTip:Hide()
   ENDIF

   RETURN Nil

STATIC FUNCTION TTonTimer( o, xPos, yPos )

   IF o:nMouseOn == 0 .OR. o:nMouseOn > 86400
      RETURN Nil
   ELSEIF Empty( o:oTooltip )
      o:oTooltip := HDrawnTT():New( o )
   ENDIF
   o:oTooltip:Show( o:cTooltip, xPos, yPos )

   RETURN Nil

CLASS HDrawnTT INHERIT HDrawn

   CLASS VAR oFontDef  SHARED
   CLASS VAR tColorDef SHARED  INIT CLR_BLACK
   CLASS VAR bColorDef SHARED  INIT CLR_LYELLOW

   DATA  hBitmapTmp

   METHOD New( oWndParent, title, tcolor, bColor, oFont )
   METHOD Show( cText, xPos, yPos )
   METHOD Hide()
   METHOD Paint( hDC )
   METHOD onMouseLeave()

ENDCLASS

METHOD New( oWndParent, title, tcolor, bColor, oFont ) CLASS HDrawnTT

   ::aMargin[2] := 2
   ::Super:New( oWndParent:oParent, 0, 0, 0, 0, Iif( Empty(tcolor),::tColorDef,tcolor ), ;
      Iif( Empty(bcolor),::bColorDef,bcolor ),, title, Iif( Empty(oFont), ::oFontDef, oFont ) )
   ::Delete()
   IF !Empty( title )
      oWndParent:cTooltip := title
   ENDIF
   ::lHide := .T.

   RETURN Self

METHOD Show( cText, xPos, yPos ) CLASS HDrawnTT

   LOCAL oBoa := ::GetParentBoard()
   LOCAL hDC, arr, nw, nh
   LOCAL o, i, arrt

   IF !::lHide
      RETURN Nil
   ENDIF
   hDC := hwg_Getdc( oBoa:handle )
   IF Chr(10) $ cText
      arrt := hb_ATokens( cText, Chr(10) )
      nw := nh := 0
      FOR i := 1 TO Len( arrt )
         arr := hwg_GetTextSize( hDC, arrt[i] )
         nw := Max( nw, arr[1] + 8 ); nh := Max( nh, arr[2] + 4 )
      NEXT
      ::nHeight := (nh-2) * Len( arrt )
   ELSE
      arr := hwg_GetTextSize( hDC, cText )
      nw := arr[1] + 8; nh := arr[2] + 4
      ::nHeight := nh
   ENDIF
   ::nHeight := nh := ::nHeight + ::aMargin[2] + ::aMargin[4]
   nw += ::aMargin[1] + ::aMargin[3]
   hwg_Releasedc( oBoa:handle, hDC )

   FOR i := 1 TO Len( ::oParent:aDrawn )
      IF ::oParent:aDrawn[i]:oTooltip == Self
         o := ::oParent:aDrawn[i]
         EXIT
      ENDIF
   NEXT

   IF xPos + 2 + nw <= oBoa:nWidth
      ::nLeft := xPos + 2
   ELSEIF nw < oBoa:nWidth
      ::nLeft := oBoa:nWidth - nw
   ELSE
      ::nLeft := 2
      nw := oBoa:nWidth - 4
   ENDIF

   IF o:nTop + o:nHeight + nh <= oBoa:nHeight
      ::nTop := o:nTop + o:nHeight
   ELSEIF o:nTop - nh > 0
      ::nTop := o:nTop - nh
   ELSEIF yPos + 4 + nh <= oBoa:nHeight
      ::nTop := yPos + 4
   ELSEIF yPos - 4 - nh > 0
      ::nTop := yPos - 4 - nh
   ELSE
      ::nTop := o:nTop + 2
   ENDIF

   ::nWidth  := nw

   ::hBitmapTmp := hwg_Window2Bitmap( oBoa:handle, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   AAdd( oBoa:aDrawn, Self )
   ::lHide := .F.
   ::SetText( cText )

   RETURN Nil

METHOD Hide() CLASS HDrawnTT

   ::lHide := .T.
   ::Refresh()
   RETURN Nil

METHOD Paint( hDC ) CLASS HDrawnTT

   LOCAL i, arr, y

   IF ::lHide
      IF !Empty( ::hBitmapTmp )
         hwg_Drawbitmap( hDC, ::hBitmapTmp,, ::nLeft, ::nTop )
         hwg_Deleteobject( ::hBitmapTmp )
         ::hBitmapTmp := Nil
      ENDIF
     ::Delete()
   ELSE
      hwg_RoundRect_Filled( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1, 4, ;
         .F., ::oBrush:handle )
      hwg_Settransparentmode( hDC, .T. )
      hwg_Settextcolor( hDC, ::tColor )
      IF !Empty( ::oFont )
         hwg_SelectObject( hDC, ::oFont:handle )
      ENDIF
      IF Chr(10) $ ::title
         arr := hb_ATokens( ::title, Chr(10) )
         y := ::nTop+::aMargin[2]
         i := 0
         DO WHILE ++i < Len( arr ) .AND. y < ::nTop+::nHeight-::aMargin[4]
            hwg_Drawtext( hDC, ::title, ::nLeft+::aMargin[1], y, ;
               ::nLeft+::nWidth-::aMargin[3], ::nTop+::nHeight-::aMargin[4] )
            y += hwg_GetTextSize( hDC, arr[i] )[2] + 2
         ENDDO
      ELSE
         hwg_Drawtext( hDC, ::title, ::nLeft+::aMargin[1], ::nTop+::aMargin[2], ;
            ::nLeft+::nWidth-::aMargin[3], ::nTop+::nHeight-::aMargin[4] )
      ENDIF
      hwg_Settransparentmode( hDC, .F. )
   ENDIF
   //::Refresh()

   RETURN Nil

METHOD onMouseLeave() CLASS HDrawnTT

   IF !::lHide
      ::Hide()
   ENDIF
   RETURN Nil

CLASS HDrawnCheck INHERIT HDrawn

   DATA cForTitle   INIT 'x'

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      title, oFont, bPaint, bClick, bChgState )
   METHOD SetState( nState, nPosX, nPosY )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      title, oFont, bPaint, bClick, bChgState ) CLASS HDrawnCheck

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      ' ', oFont, bPaint, bClick, bChgState )

   IF !Empty( title )
      ::cForTitle := title
   ENDIF
   ::xValue := .F.

   RETURN Self

METHOD SetState( nState, nPosX, nPosY ) CLASS HDrawnCheck

   IF nState == STATE_UNPRESS .AND. ::nState == STATE_PRESSED
      ::xValue := !::xValue
      ::title := Iif( ::xValue, ::cForTitle, ' ' )
      ::Refresh()
   ENDIF

   RETURN ::Super:SetState( nState, nPosX, nPosY )

CLASS HDrawnRadio INHERIT HDrawn

   DATA cForTitle   INIT 'o'
   DATA xGroup

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      title, oFont, bPaint, bClick, bChgState, xGroup, lInitVal )
   METHOD SetState( nState, nPosX, nPosY )
   METHOD GetGroupValue()
   METHOD SetGroupValue( nVal )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      title, oFont, bPaint, bClick, bChgState, xGroup, lInitVal ) CLASS HDrawnRadio

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      ' ', oFont, bPaint, bClick, bChgState )

   IF !Empty( title )
      ::cForTitle := title
   ENDIF
   ::xValue := Iif( lInitVal == Nil, .F., lInitVal )
   IF !Empty( ::xValue )
      ::title := ::cForTitle
   ENDIF
   ::xGroup := xGroup

   RETURN Self

METHOD SetState( nState, nPosX, nPosY ) CLASS HDrawnRadio

   IF nState == STATE_UNPRESS .AND. ::nState == STATE_PRESSED .AND. !::xValue
      ::SetGroupValue()
      ::title := ::cForTitle
      ::Refresh()
   ENDIF

   RETURN ::Super:SetState( nState, nPosX, nPosY )

METHOD GetGroupValue() CLASS HDrawnRadio

   LOCAL i, aDrawn := ::oParent:aDrawn, xGroup := ::xGroup, nVal := 0

   FOR i := 1 TO Len( aDrawn )
      IF __ObjHasMsg( aDrawn[i], "XGROUP" ) .AND. Valtype(aDrawn[i]:xGroup) == Valtype(xGroup) ;
         .AND. aDrawn[i]:xGroup == xGroup
         nVal ++
         IF aDrawn[i]:xValue
            RETURN nVal
         ENDIF
      ENDIF
   NEXT

   RETURN 0

METHOD SetGroupValue( nVal ) CLASS HDrawnRadio

   LOCAL i, aDrawn := ::oParent:aDrawn, xGroup := ::xGroup, n := 0, o

   IF nVal != Nil .AND. ( Valtype( nVal ) != "N" .OR. nVal <= 0 )
      RETURN 0
   ENDIF
   FOR i := 1 TO Len( aDrawn )
      IF __ObjHasMsg( aDrawn[i], "XGROUP" ) .AND. Valtype(aDrawn[i]:xGroup) == Valtype(xGroup) ;
         .AND. aDrawn[i]:xGroup == xGroup
         n ++
         IF aDrawn[i]:xValue
            o := aDrawn[i]:xValue
         ENDIF
         IF nVal == Nil
            IF !(aDrawn[i] == Self) .AND. aDrawn[i]:xValue
               aDrawn[i]:xValue := .F.
               aDrawn[i]:title := ' '
               aDrawn[i]:Refresh()
            ENDIF
         ELSE
            IF aDrawn[i]:xValue != (n == nVal)
               aDrawn[i]:xValue := (n == nVal)
               aDrawn[i]:title := Iif( n == nVal, aDrawn[i]:cForTitle, ' ' )
               aDrawn[i]:Refresh()
            ENDIF
         ENDIF
      ENDIF
   NEXT
   IF nVal == Nil
      ::xValue := .T.
      ::title := ::cForTitle
      ::Refresh()
   ELSEIF n <= nVal .AND. !Empty( o )
      o:xValue := .T.
      o:title := o:cForTitle
      o:Refresh()
   ENDIF

   RETURN 0

CLASS HDrawnArrow INHERIT HDrawn

   DATA nDirection
   DATA oBrushArrow
   DATA nw, nh
   DATA bAct

   DATA  oTimer
   DATA  nPeriod      INIT 0

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      nDirection, nPeriod, bPaint, bClick, bChgState )
   METHOD Paint( hDC )
   METHOD onMouseMove( xPos, yPos )
   METHOD onMouseLeave()
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      nDirection, nPeriod, bPaint, bClick, bChgState ) CLASS HDrawnArrow

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      '',, bPaint,, bChgState )

   ::nDirection := Iif( Empty(nDirection) .OR. nDirection > 4, 1, nDirection )
   ::nPeriod := Iif( Empty(nPeriod), 0, nPeriod )
   ::oBrushArrow := HBrush():Add( ::tColor )
   ::bAct := bClick

   RETURN Self

METHOD Paint( hDC ) CLASS HDrawnArrow

   STATIC bPaintItem := { | o, h | PaintArrow( o, h ) }

   IF Empty( ::bPaintItem )
      ::bPaintItem := bPaintItem
   ENDIF
   ::Super:Paint( hDC )

   RETURN Nil

METHOD onMouseMove( xPos, yPos ) CLASS HDrawnArrow

   IF ::nState == STATE_PRESSED
      IF !( xPos > ::nLeft .AND. xPos < ::nLeft + ::nWidth .AND. ;
         yPos > ::nTop .AND. yPos < ::nTop + ::nHeight )
         ::nState := STATE_NORMAL
         ::Refresh()
         IF !Empty( ::oTimer )
            ::oTimer:End()
            ::oTimer := Nil
         ENDIF
      ENDIF
   ENDIF

   RETURN ::Super:onMouseMove( xPos, yPos )

METHOD onMouseLeave() CLASS HDrawnArrow

   ::onButtonUp()
   RETURN ::Super:onMouseLeave()

METHOD onButtonDown( msg, xPos, yPos ) CLASS HDrawnArrow

   IF msg == WM_LBUTTONDOWN
      IF xPos > ::nLeft .AND. xPos < ::nLeft + ::nWidth .AND. yPos > ::nTop .AND. ;
         yPos < ::nTop + ::nHeight
         ::nState := STATE_PRESSED

         IF !Empty( ::bAct )
            Eval( ::bAct, Self )
            IF ::nPeriod > 0
               ::oTimer := HTimer():New( ::GetParentBoard(),, ::nPeriod, ;
                  {|ot| HB_SYMBOL_UNUSED(ot),ArrowTimerProc(Self) } )
               ::oTimer:cargo := 4
            ENDIF
         ENDIF
      ENDIF
   ENDIF
   RETURN Nil

METHOD onButtonUp( xPos, yPos ) CLASS HDrawnArrow

   HB_SYMBOL_UNUSED(xPos)
   HB_SYMBOL_UNUSED(yPos)

   IF ::nState == STATE_PRESSED
      ::nState := STATE_NORMAL
      ::Refresh()
   ENDIF
   IF !Empty( ::oTimer )
      ::oTimer:End()
      ::oTimer := Nil
   ENDIF

   RETURN Nil

STATIC FUNCTION ArrowTimerProc( o )

   IF o:oTimer:cargo > 0
      o:oTimer:cargo --
      RETURN Nil
   ENDIF
   Eval( o:bAct, o )

   RETURN Nil

STATIC FUNCTION PaintArrow( o, h )

   LOCAL nh := Iif( Empty(o:nh), Max( 4, Int( Iif(o:nDirection==1.OR.o:nDirection==3,o:nWidth,o:nHeight)/2.4 ) ), o:nh )
   LOCAL nw := Iif( Empty(o:nw), Int(nh/1.2), Int(o:nw/2) )
   LOCAL nt, nl

   IF o:nDirection == 1 .OR. o:nDirection == 3
      nt := Int( o:nHeight/2 )
      nl := Int( (o:nWidth-nh)/2 )
      IF o:nDirection == 1
         hwg_Triangle_Filled( h, o:nLeft+nl, o:nTop+nt, o:nLeft+nl+nh, o:nTop+nt-nw, ;
            o:nLeft+nl+nh, o:nTop+nt+nw, .F., o:oBrushArrow:handle )
      ELSE
         hwg_Triangle_Filled( h, o:nLeft+o:nWidth-nl, o:nTop+nt, o:nLeft+o:nWidth-nl-nh, o:nTop+nt-nw, ;
            o:nLeft+o:nWidth-nl-nh, o:nTop+nt+nw, .F., o:oBrushArrow:handle )
      ENDIF
   ELSE
      nt := Int( o:nWidth/2 )
      nl := Int( (o:nHeight-nh)/2 )
      IF o:nDirection == 2
         hwg_Triangle_Filled( h, o:nLeft+nt, o:nTop+nl, o:nLeft+nt-nw, o:nTop+nl+nh, ;
            o:nLeft+nt+nw, o:nTop+nl+nh, .F., o:oBrushArrow:handle )
      ELSE
         hwg_Triangle_Filled( h, o:nLeft+nt, o:nTop+o:nHeight-nl, o:nLeft+nt-nw, o:nTop+o:nHeight-nl-nh, ;
            o:nLeft+nt+nw, o:nTop+o:nHeight-nl-nh, .F., o:oBrushArrow:handle )
      ENDIF
   ENDIF

   RETURN Nil