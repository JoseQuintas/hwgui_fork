/*
 * $Id: hpanel.prg 3386 2023-11-18 10:25:25Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HPanel class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It relies exclusively on the
 * hwg_* abstraction layer.  The only external dependency worth flagging:
 *
 *   - hwg_Loadcursor( GDK_HAND1 )  →  needs case 58: "grab" in
 *                                     HWG_LOADCURSOR (control.c).
 *                                     Without it the drag cursor falls
 *                                     back to "default" instead of the
 *                                     open-hand grip.
 *
 *   - HPanel:Hide / HPanel:Show rely on hwg_Hidewindow / hwg_Showwindow,
 *     which live in wintools.c and have to be ported to GTK4
 *     (gtk_widget_set_visible).
 */

#include "hbclass.ch"
#include "hwgui.ch"

CLASS HPanel INHERIT HControl

   DATA winclass   INIT "PANEL"
   DATA hBox
   DATA oStyle
   DATA oPaintCB              // HPaintCB object
   DATA lDragWin    INIT .F.
   DATA lCaptured   INIT .F.
   DATA hCursor
   DATA nOldX, nOldY HIDDEN
   DATA hScrollV  INIT Nil
   DATA hScrollH  INIT Nil
   DATA nScrollV  INIT 0
   DATA nScrollH  INIT 0
   DATA bVScroll, bHScroll
   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bColor, oStyle )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD DrawItems( hDC, aCoors )
   METHOD Paint()
   METHOD Move( x1, y1, width, height )
   METHOD Hide()
   METHOD Show()
   METHOD Drag( xPos, yPos )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bColor, oStyle ) CLASS HPanel

   LOCAL oParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )

   IF !Empty( bPaint ) .OR. bColor != Nil .OR. oStyle != Nil
      nStyle := Hwg_BitOr( nStyle, SS_OWNERDRAW )
   ENDIF
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, iif( nWidth == Nil,0,nWidth ), ;
      nHeight, oParent:oFont, bInit, ;
      bSize, bPaint, , , bColor )
   ::oStyle := oStyle
   ::bPaint  := bPaint
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HPanel

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createpanel( Self, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HPanel

   IF msg == WM_MOUSEMOVE
      IF ::lDragWin .AND. ::lCaptured
         ::Drag( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
      ENDIF
   ELSEIF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_HSCROLL
      IF ::bHScroll != Nil
         Eval( ::bHScroll, Self )
      ENDIF
   ELSEIF msg == WM_VSCROLL
      IF ::bVScroll != Nil
         Eval( ::bVScroll, Self )
      ENDIF
   ELSEIF msg == WM_LBUTTONDOWN
      IF ::lDragWin
         IF ::hCursor == Nil
            ::hCursor := hwg_Loadcursor( GDK_HAND1 )
         ENDIF
         Hwg_SetCursor( ::hCursor, ::handle )
         ::lCaptured := .T.
         ::nOldX := hwg_Loword( lParam )
         ::nOldY := hwg_Hiword( lParam )
      ENDIF
   ELSEIF msg == WM_LBUTTONUP
      ::lCaptured := .F.
      Hwg_SetCursor( Nil, ::handle )
   ENDIF

   RETURN ::Super:onEvent( msg, wParam, lParam )

METHOD Init() CLASS HPanel

   IF !::lInit
      IF ::bSize == Nil .AND. Empty( ::Anchor )
         IF ::nHeight != 0 .AND. ( ::nWidth > ::nHeight .OR. ::nWidth == 0 )
            ::bSize := { |o, x, y|o:Move( , iif( ::nTop > 0,y - ::nHeight,0 ), x, ::nHeight ) }
         ELSEIF ::nWidth != 0 .AND. ( ::nHeight > ::nWidth .OR. ::nHeight == 0 )
            ::bSize := { |o, x, y|o:Move( iif( ::nLeft > 0,x - ::nLeft,0 ), , ::nWidth, y ) }
         ENDIF
      ENDIF
      ::Super:Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD DrawItems( hDC, aCoors ) CLASS HPanel

   LOCAL i, aCB

   IF Empty( aCoors )
      aCoors := hwg_Getclientrect( ::handle )
   ENDIF

   IF !Empty( ::oPaintCB ) .AND. !Empty( aCB := ::oPaintCB:Get( PAINT_ITEM ) )
      FOR i := 1 TO Len( aCB )
         Eval( aCB[i], Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
      NEXT
   ENDIF

   RETURN Nil

METHOD Paint() CLASS HPanel

   LOCAL hDC, aCoors, block

   IF ::bPaint != Nil
      RETURN Eval( ::bPaint, Self )
   ENDIF

   hDC := hwg_Getdc( ::handle )
   aCoors := hwg_Getclientrect( ::handle )

   IF !Empty( ::oPaintCB ) .AND. !Empty( block := ::oPaintCB:Get( PAINT_BACK ) )
      Eval( block, Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
   ELSEIF ::oStyle == Nil
      hwg_Drawbutton( hDC, 0, 0, ::nWidth - 1, ::nHeight - 1, 5 )
   ELSE
      ::oStyle:Draw( hDC, 0, 0, aCoors[3], aCoors[4] )
   ENDIF
   ::DrawItems( hDC, aCoors )
   hwg_Releasedc( ::handle, hDC )

   RETURN Nil

METHOD Move( x1, y1, width, height )  CLASS HPanel

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
      hwg_MoveWidget( ::hbox, iif( lMove,::nLeft,Nil ), iif( lMove,::nTop,Nil ), ;
         iif( lSize, ::nWidth, Nil ), iif( lSize, ::nHeight, Nil ), .F. )
      IF lSize
         hwg_MoveWidget( ::handle, Nil, Nil, ::nWidth, ::nHeight, .F. )
         hwg_Redrawwindow( ::handle )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Hide() CLASS HPanel

   LOCAL i

   IF ::lHide
      RETURN Nil
   ENDIF

   FOR i := 1 TO Len( ::aControls )
      ::aControls[ i ]:Hide()
   NEXT
   ::Super:Hide()

   RETURN Nil

METHOD Show() CLASS HPanel

   LOCAL i

   IF !::lHide
      RETURN Nil
   ENDIF

   ::Super:Show()
   FOR i := 1 TO Len( ::aControls )
      ::aControls[ i ]:Show()
   NEXT

   RETURN Nil

METHOD Drag( xPos, yPos ) CLASS HPanel

   LOCAL oWnd := hwg_getParentForm( Self )

   IF xPos > 32000
      xPos -= 65535
   ENDIF
   IF yPos > 32000
      yPos -= 65535
   ENDIF
   IF Abs( xPos - ::nOldX ) > 1 .OR. Abs( yPos - ::nOldY ) > 1
      oWnd:Move( oWnd:nLeft + ( xPos - ::nOldX ), oWnd:nTop + ( yPos - ::nOldY ) )
   ENDIF

   RETURN Nil

CLASS HPanelStS INHERIT HPANEL

   DATA aParts
   DATA aText
   METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, bcolor, oStyle, aParts )
   METHOD Write( cText, nPart, lRedraw )
   METHOD SetText( cText )    INLINE ::Write( cText, , .T. )
   METHOD PaintText( hDC )
   METHOD Paint()

ENDCLASS

METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, bcolor, oStyle, aParts ) CLASS HPanelStS

   oWndParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )
   IF bColor == Nil
      bColor := 0xeeeeee
   ENDIF
   ::Super:New( oWndParent, nId, SS_OWNERDRAW, 0, oWndParent:nHeight - nHeight, ;
      oWndParent:nWidth, nHeight, bInit, {|o,w,h|o:Move(0,h-o:nHeight,w-2)}, bPaint, bcolor )

   ::oFont := iif( oFont == Nil, ::oParent:oFont, oFont )
   ::oStyle := oStyle
   IF !Empty( aParts )
      ::aParts := aParts
   ELSE
      ::aParts := { 0 }
   ENDIF
   ::aText := Array( Len( ::aParts ) )
   AFill( ::aText, "" )

   RETURN Self

METHOD Write( cText, nPart, lRedraw ) CLASS HPanelStS

   ::aText[Iif(nPart==Nil,1,nPart)] := cText
   IF ValType( lRedraw ) != "L" .OR. lRedraw
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF

   RETURN Nil

METHOD PaintText( hDC ) CLASS HPanelStS

   LOCAL i, x1, x2, nWidth := ::nWidth, oldTColor

   IF ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
   ENDIF
   hwg_Settransparentmode( hDC, .T. )
   oldTColor := hwg_Settextcolor( hDC, ::tcolor )
   FOR i := 1 TO Len( ::aParts )
      x1 := iif( i == 1, 4, x2 + 4 )
      IF ::aParts[i] == 0
         x2 := x1 + Int( nWidth/ (Len(::aParts ) - i + 1 ) )
      ELSE
         x2 := x1 + ::aParts[i]
      ENDIF
      nWidth -= ( x2 - x1 + 1 )
      IF !Empty( ::aText[i] )
         hwg_Drawtext( hDC, ::aText[i], x1, 6, x2, ::nHeight - 2, DT_LEFT + DT_VCENTER )
      ENDIF
   NEXT
   hwg_Settextcolor( hDC, oldTColor )
   hwg_Settransparentmode( hDC, .F. )

   RETURN Nil

METHOD Paint() CLASS HPanelStS

   LOCAL pps, hDC, block, aCoors

   IF ::bPaint != Nil
      RETURN Eval( ::bPaint, Self )
   ENDIF

   pps    := hwg_Definepaintstru()
   hDC    := hwg_Beginpaint( ::handle, pps )

   IF !Empty( ::oPaintCB ) .AND. !Empty( block := ::oPaintCB:Get( PAINT_BACK ) )
      aCoors := hwg_Getclientrect( ::handle )
      Eval( block, Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
   ELSEIF Empty( ::oStyle )
      ::oStyle := HStyle():New( { ::bColor }, 1, , 0.4, 0 )
   ENDIF

   ::oStyle:Draw( hDC, 0, 0, ::nWidth, ::nHeight )
   ::PaintText( hDC )
   ::DrawItems( hDC )

   hwg_Endpaint( ::handle, pps )

   RETURN Nil

CLASS HPanelHea INHERIT HPANEL

   DATA  xt, yt
   DATA  lMaximized   INIT .F.
   DATA  lPreDef      HIDDEN

   METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, tcolor, bcolor, oStyle, ;
      cText, xt, yt, lBtnClose, lBtnMax, lBtnMin )
   METHOD SetText( c )
   METHOD SetSysbtnColor( tColor, bColor )
   METHOD PaintText( hDC )
   METHOD Paint()

ENDCLASS

METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, tcolor, bcolor, oStyle, ;
   cText, xt, yt, lBtnClose, lBtnMax, lBtnMin ) CLASS HPanelHea

   LOCAL btnClose, btnMax, btnMin

   oWndParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )
   IF bColor == Nil
      bColor := 0xeeeeee
   ENDIF

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, 0, 0, ;
      oWndParent:nWidth, nHeight, bInit, ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS, ;
         bPaint, bcolor, oStyle )

   ::title := cText
   ::xt := xt
   ::yt := yt
   ::oFont := Iif( oFont == Nil, ::oParent:oFont, oFont )
   ::oStyle := oStyle
   ::tColor := Iif( tcolor==Nil, 0, tcolor )
   ::lDragWin := .T.
   ::lPreDef := .F.

   IF !Empty( lBtnClose ) .OR. !Empty( lBtnMax ) .OR. !Empty( lBtnMin )
      ::lPreDef := .T.

      IF !Empty( lBtnClose )
         @ 0, 0 OWNERBUTTON btnClose OF Self ;
            SIZE 1, 1 ON PAINT {|o|fPaintBtn(o)} ;
            ON CLICK {||::oParent:Close()}
      ENDIF
      IF !Empty( lBtnMax )
         @ 0, 0 OWNERBUTTON btnMax OF Self ;
            SIZE 1, 1 ON PAINT {|o|fPaintBtn(o)} ;
            ON CLICK {||Iif(::lMaximized,::oParent:Restore(),::oParent:Maximize()),::lMaximized:=!::lMaximized}
      ENDIF
      IF !Empty( lBtnMin )
         @ 0, 0 OWNERBUTTON btnMin OF Self ;
            SIZE 1, 1 ON PAINT {|o|fPaintBtn(o)} ;
            ON CLICK {||::oParent:Minimize()}
      ENDIF
      ::SetSysbtnColor( 0, 0xededed )
   ENDIF

   RETURN Self

METHOD SetText( c ) CLASS HPanelHea

   ::title := c
   hwg_RedrawWindow( ::handle )

   RETURN NIL

METHOD SetSysbtnColor( tColor, bColor )

   LOCAL oBtn, oPen1, oPen2

   oPen1 := HPen():Add( BS_SOLID, 2, tColor )
   oPen2 := HPen():Add( BS_SOLID, 1, tColor )

   IF !Empty( oBtn := ::FindControl( "btnclose" ) )
      oBtn:SetColor( tColor, bColor )
      oBtn:oPen1 := oPen1; oBtn:oPen2 := oPen2
   ENDIF
   IF !Empty( oBtn := ::FindControl( "btnmax" ) )
      oBtn:SetColor( tColor, bColor )
      oBtn:oPen1 := oPen1; oBtn:oPen2 := oPen2
   ENDIF
   IF !Empty( oBtn := ::FindControl( "btnmin" ) )
      oBtn:SetColor( tColor, bColor )
      oBtn:oPen1 := oPen1; oBtn:oPen2 := oPen2
   ENDIF
   RETURN Nil

METHOD PaintText( hDC ) CLASS HPanelHea

   LOCAL x1, y1, oldTColor

   IF ::title != Nil

      IF ::oFont != Nil
         hwg_Selectobject( hDC, ::oFont:handle )
      ENDIF
      hwg_Settransparentmode( hDC, .T. )
      oldTColor := hwg_Settextcolor( hDC, ::tcolor )
      x1 := Iif( ::xt==Nil, 4, ::xt )
      y1 := Iif( ::yt==Nil, 4, ::yt )
      hwg_Drawtext( hDC, ::title, x1, y1, ::nWidth-4, ::nHeight-4, DT_LEFT + DT_VCENTER )
      hwg_Settextcolor( hDC, oldTColor )
      hwg_Settransparentmode( hDC, .F. )
   ENDIF

   RETURN Nil

METHOD Paint() CLASS HPanelHea

   LOCAL pps, hDC, block, aCoors
   LOCAL oBtn, nBtnSize, x1, y1

   IF ::bPaint != Nil
      RETURN Eval( ::bPaint, Self )
   ENDIF

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( ::handle, pps )

   IF !Empty( ::oPaintCB ) .AND. !Empty( block := ::oPaintCB:Get( PAINT_BACK ) )
      aCoors := hwg_Getclientrect( ::handle )
      Eval( block, Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
   ELSEIF Empty( ::oStyle )
      ::oStyle := HStyle():New( {::bColor}, 1 )
   ENDIF
   ::oStyle:Draw( hDC, 0, 0, ::nWidth, ::nHeight )

   ::PaintText( hDC )
   ::DrawItems( hDC )

   hwg_Endpaint( ::handle, pps )

   IF ::lPreDef
      ::lPreDef := .F.
      nBtnSize := Min( 24, ::nHeight )
      x1 := ::nWidth-nBtnSize-4
      y1 := Int((::nHeight-nBtnSize)/2)
      IF !Empty( oBtn := ::FindControl( "btnclose" ) )
         oBtn:oBitmap := HBitmap():AddWindow( Self, x1, y1, nBtnSize, nBtnSize )
         oBtn:Move( x1, y1, nBtnSize, nBtnSize )
         oBtn:Anchor := ANCHOR_RIGHTABS
         x1 -= nBtnSize
      ENDIF
      IF !Empty( oBtn := ::FindControl( "btnmax" ) )
         oBtn:oBitmap := HBitmap():AddWindow( Self, x1, y1, nBtnSize, nBtnSize )
         oBtn:Move( x1, y1, nBtnSize, nBtnSize )
         oBtn:Anchor := ANCHOR_RIGHTABS
         x1 -= nBtnSize
      ENDIF
      IF !Empty( oBtn := ::FindControl( "btnmin" ) )
         oBtn:oBitmap := HBitmap():AddWindow( Self, x1, y1, nBtnSize, nBtnSize )
         oBtn:Move( x1, y1, nBtnSize, nBtnSize )
         oBtn:Anchor := ANCHOR_RIGHTABS
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION fPaintBtn( oBtn )

   LOCAL pps, hDC, aCoors

   IF oBtn:nWidth <= 1
      RETURN Nil
   ENDIF
   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( oBtn:handle, pps )
   aCoors := hwg_Getclientrect( oBtn:handle )

   IF oBtn:state == OBTN_NORMAL
      hwg_Drawbitmap( hDC, oBtn:oBitmap:handle, , 0, 0 )
   ELSEIF oBtn:state == OBTN_MOUSOVER
      hwg_Fillrect( hDC, 0, 0, aCoors[3]-1, aCoors[4]-1, oBtn:brush:handle )
   ELSEIF oBtn:state == OBTN_PRESSED
      hwg_Fillrect( hDC, 0, 0, aCoors[3]-1, aCoors[4]-1, oBtn:brush:handle )
      hwg_Selectobject( hDC, oBtn:oPen2:handle )
      hwg_Rectangle( hDC, 0, 0, aCoors[3]-1, aCoors[4]-1 )
   ENDIF

   hwg_Selectobject( hDC, oBtn:oPen1:handle )
   IF oBtn:objname == "BTNCLOSE"
      hwg_Drawline( hDC, 6, 6, aCoors[3] - 6, aCoors[4] - 6 )
      hwg_Drawline( hDC, aCoors[3] - 6, 6, 6, aCoors[4] - 6 )
   ELSEIF oBtn:objname == "BTNMAX"
      hwg_Drawline( hDC, 6, 6, aCoors[3] - 6, 6 )
      hwg_Drawline( hDC, 6, aCoors[4] - 6, aCoors[3] - 6, aCoors[4] - 6 )
      hwg_Selectobject( hDC, oBtn:oPen2:handle )
      hwg_Drawline( hDC, 6, 6, 6, aCoors[4] - 6 )
      hwg_Drawline( hDC, aCoors[3] - 6, 6, aCoors[3] - 6, aCoors[4] - 6 )
   ELSEIF oBtn:objname == "BTNMIN"
      hwg_Drawline( hDC, 6, aCoors[4] - 6, aCoors[3] - 12, aCoors[4] - 6 )
   ENDIF

   hwg_Endpaint( oBtn:handle, pps )

   RETURN Nil
