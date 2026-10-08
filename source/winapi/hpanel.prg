/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPanel class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

/* hb_idleAdd callback id while auto-collapse is active (0 = off),
 * and timestamp of the last mouse check.  The idle callback fires
 * many times per second; nLastCheck throttles the real work to one
 * pass every ~200 ms. */
STATIC nAutoIdleId  := 0
STATIC nLastCheck   := 0
STATIC oAutoPanel   := Nil

CLASS HPanel INHERIT HControl

   DATA winclass Init "PANEL"
   DATA oEmbedded
   DATA bScroll
   DATA oStyle
   DATA oPaintCB    INIT {}         // HPaintCB object
   DATA lDragWin    INIT .F.
   DATA lCaptured   INIT .F.

   /* --- Collapse / expand support ------------------------------ */
   DATA lCollapsed     INIT .F.    // .T. when the panel is hidden
   DATA lAutoCollapse  INIT .F.    // .T. enables hover auto-collapse
   DATA nAutoTimer     INIT 0      // WM_TIMER id (0 = no timer)
   DATA nGraceMs       INIT 0      // accumulated mouse-away time
   DATA nGraceThresh   INIT 800    // ms of mouse-away before collapse
   DATA bOnCollapse    INIT Nil    // {|| ... } after Collapse()
   DATA bOnExpand      INIT Nil    // {|| ... } after Expand()
   DATA lLastSyncState INIT Nil    // previous ::lCollapsed value seen

   DATA hCursor
   DATA nOldX, nOldY HIDDEN
   DATA lResizeX, lResizeY, nSize HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bcolor, oStyle )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Redefine( oWndParent, nId, nWidth, nHeight, bInit, bSize, bPaint, bcolor )
   METHOD DrawItems( hDC, aCoors )
   METHOD Paint()
   METHOD BackColor( bcolor ) INLINE ::Setcolor( , bcolor, .T. )
   METHOD Hide()
   METHOD Show()
   //METHOD SetPaintCB( nId, block, cId )
   METHOD Drag( xPos, yPos )

   METHOD Collapse()
   METHOD Expand()
   METHOD ToggleCollapse()
   METHOD SetAutoCollapse( lOn )
   METHOD SyncTrackedWindows()
   METHOD OnAutoTimer()

   METHOD Release()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bcolor, oStyle ) CLASS HPanel

   LOCAL oParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, iif( nWidth == Nil, 0, nWidth ), ;
      iif( nHeight == Nil, 0, nHeight ), oParent:oFont, bInit, ;
      bSize, bPaint, , , bcolor )

   IF bcolor != NIL
      ::brush  := HBrush():Add( bcolor )
      ::bcolor := bcolor
   ENDIF
   ::oStyle := oStyle
   ::bPaint   := bPaint
   ::lResizeX := ( ::nWidth == 0 )
   ::lResizeY := ( ::nHeight == 0 )
   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:Type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] := ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] := ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] := ::nWidth
         ENDIF
      ENDIF
   ENDIF

   hwg_RegPanel()
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HPanel

   LOCAL handle := ::oParent:handle

   IF !Empty( handle )
      ::handle := hwg_Createpanel( handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HPanel

   IF msg == WM_MOUSEMOVE
      IF ::lDragWin .AND. ::lCaptured
         ::Drag( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
      ENDIF
   ELSEIF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_ERASEBKGND
      IF ::brush != Nil
         IF ValType( ::brush ) != "N"
            hwg_Fillrect( wParam, 0, 0, ::nWidth, ::nHeight, ::brush:handle )
         ENDIF
         RETURN 1
      ENDIF
   ELSEIF msg == WM_SIZE
      IF ::oEmbedded != Nil
         ::oEmbedded:Resize( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
      ENDIF
   ELSEIF msg == WM_DESTROY
      IF ::oEmbedded != Nil
         ::oEmbedded:END()
      ENDIF
      IF ::nAutoTimer != 0
         hwg_KillTimer( ::handle, ::nAutoTimer )
         ::nAutoTimer := 0
      ENDIF
      ::Super:onEvent( WM_DESTROY )
      RETURN 0
   ELSEIF msg == WM_LBUTTONDOWN
      IF ::lDragWin
         IF ::hCursor == Nil
            ::hCursor := hwg_Loadcursor( IDC_HAND )
         ENDIF
         Hwg_SetCursor( ::hCursor )
         hwg_Setcapture( ::handle )
         ::lCaptured := .T.
         ::nOldX := hwg_Loword( lParam )
         ::nOldY := hwg_Hiword( lParam )
      ENDIF
   ELSEIF msg == WM_LBUTTONUP
      IF ::lDragWin .AND. ::lCaptured
         hwg_Releasecapture()
         ::lCaptured := .F.
      ENDIF
   ELSEIF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .OR. msg == WM_MOUSEWHEEL
      hwg_onTrackScroll( Self, msg, wParam, lParam )
   ENDIF

   RETURN ::Super:onEvent( msg, wParam, lParam )

METHOD Init() CLASS HPanel

   IF !::lInit
      IF ::bSize == Nil .AND. Empty( ::Anchor )
         // Default resize logic that covers all four anchoring modes.
         //
         //   lResizeX = .T.  -> panel spans the full parent width
         //                      (TOP and BOTTOM panels)
         //   lResizeY = .T.  -> panel spans the full parent height
         //                      (LEFT and RIGHT panels)
         //   nLeft > 0       -> panel is anchored to the right edge
         //   nTop  > 0       -> panel is anchored to the bottom edge
         //
         // The previous formula used "x - ::nLeft" for the new left,
         // which only worked when ::nLeft was effectively the panel
         // width.  The correct value for a right-anchored panel is
         // "x - ::nWidth" so the panel keeps its distance from the
         // right edge of the parent.
         ::bSize := { | o, x, y | o:Move( ;
            iif( ::lResizeX .OR. ::nLeft == 0, 0, x - ::nWidth ), ;
            iif( ::lResizeY .OR. ::nTop  == 0, 0, y - ::nHeight ), ;
            iif( ::lResizeX, x, ::nWidth ), ;
            iif( ::lResizeY, y, ::nHeight ) ) }
      ENDIF

      ::Super:Init()
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitWinCtrl( ::handle )
   ENDIF

   RETURN Nil

METHOD Redefine( oWndParent, nId, nWidth, nHeight, bInit, bSize, bPaint, bcolor ) CLASS HPanel
   LOCAL oParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )

   ::Super:New( oWndParent, nId, 0, 0, 0, iif( nWidth == Nil, 0, nWidth ), ;
      iif( nHeight != Nil, nHeight, 0 ), oParent:oFont, bInit, ;
      bSize, bPaint, , , bcolor )

   IF bcolor != NIL
      ::brush  := HBrush():Add( bcolor )
      ::bcolor := bcolor
   ENDIF

   ::bPaint   := bPaint
   ::lResizeX := ( ::nWidth == 0 )
   ::lResizeY := ( ::nHeight == 0 )
   hwg_RegPanel()

   RETURN Self

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

   LOCAL pps, hDC, aCoors, block, oPenLight, oPenGray

   IF ::bPaint != Nil
      RETURN Eval( ::bPaint, Self )
   ENDIF

   pps    := hwg_Definepaintstru()
   hDC    := hwg_Beginpaint( ::handle, pps )
   aCoors := hwg_Getclientrect( ::handle )

   IF !Empty( ::oPaintCB ) .AND. !Empty( block := ::oPaintCB:Get( PAINT_BACK ) )
      Eval( block, Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
   ELSEIF ::oStyle == Nil
      oPenLight := HPen():Add( BS_SOLID, 1, hwg_Getsyscolor( COLOR_3DHILIGHT ) )
      hwg_Selectobject( hDC, oPenLight:handle )
      hwg_Drawline( hDC, 5, 1, aCoors[3] - 5, 1 )
      oPenGray := HPen():Add( BS_SOLID, 1, hwg_Getsyscolor( COLOR_3DSHADOW ) )
      hwg_Selectobject( hDC, oPenGray:handle )
      hwg_Drawline( hDC, 5, 0, aCoors[3] - 5, 0 )
   ELSE
      ::oStyle:Draw( hDC, 0, 0, aCoors[3], aCoors[4] )
   ENDIF
   ::DrawItems( hDC, aCoors )

   IF !Empty( oPenGray )
      oPenGray:Release()
      oPenLight:Release()
   ENDIF
   hwg_Endpaint( ::handle, pps )

   RETURN Nil

METHOD Release() CLASS HPanel

   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] -= ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] -= ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] -= ::nWidth
         ENDIF
      ENDIF
      hwg_Invalidaterect( ::oParent:handle, 0, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ENDIF
   hwg_Sendmessage( ::oParent:handle, WM_SIZE, 0, 0 )
   ::oParent:DelControl( Self )

   RETURN Nil

METHOD Hide() CLASS HPanel

   LOCAL i

   IF ::lHide
      RETURN Nil
   ENDIF
   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] -= ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] -= ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] -= ::nWidth
         ENDIF
      ENDIF
      hwg_Invalidaterect( ::oParent:handle, 0, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ENDIF
   ::nSize := ::nWidth
   FOR i := 1 TO Len( ::acontrols )
      ::acontrols[ i ]:hide()
   NEXT
   ::super:hide()
   //hwg_Sendmessage( ::oParent:Handle, WM_SIZE, 0, 0 )

   RETURN Nil

METHOD Show() CLASS HPanel

   LOCAL i

   IF !::lHide
      RETURN Nil
   ENDIF
   IF __ObjHasMsg( ::oParent, "AOFFSET" ) .AND. ::oParent:type == WND_MDI
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[ 2 ] += ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[ 1 ] += ::nWidth
         ELSE
            ::oParent:aOffset[ 3 ] += ::nWidth
         ENDIF
      ENDIF
      hwg_Invalidaterect( ::oParent:handle, 1, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ENDIF
   ::nWidth := ::nsize
   //hwg_Sendmessage( ::oParent:Handle, WM_SIZE, 0, 0 )
   ::super:Show()
   FOR i := 1 TO Len( ::aControls )
      ::aControls[ i ]:Show()
   NEXT
   hwg_Movewindow( ::Handle, ::nLeft, ::nTop, ::nWidth, ::nHeight )

   RETURN Nil
/*
METHOD SetPaintCB( nId, block, cId ) CLASS HPanel

   LOCAL i, nLen

   IF Empty( cId ); cId := "_"; ENDIF
   IF Empty( ::aPaintCB ); ::aPaintCB := {}; ENDIF

   nLen := Len( ::aPaintCB )
   FOR i := 1 TO nLen
      IF ::aPaintCB[i,1] == nId .AND. ::aPaintCB[i,2] == cId
         EXIT
      ENDIF
   NEXT
   IF Empty( block )
      IF i <= nLen
         ADel( ::aPaintCB, i )
         ::aPaintCB := ASize( ::aPaintCB, nLen-1 )
      ENDIF
   ELSE
      IF i > nLen
         Aadd( ::aPaintCB, { nId, cId, block } )
      ELSE
         ::aPaintCB[i,3] := block
      ENDIF
   ENDIF

   RETURN Nil
*/
METHOD Drag( xPos, yPos ) CLASS HPanel

   LOCAL oWnd := hwg_getParentForm( Self )

   IF xPos > 32000
      xPos -= 65535
   ENDIF
   IF yPos > 32000
      yPos -= 65535
   ENDIF

   IF Abs(xPos-::nOldX) > 1 .OR. Abs(yPos-::nOldY) > 1
      oWnd:Move( oWnd:nLeft + (xPos-::nOldX), oWnd:nTop + (yPos-::nOldY) )
   ENDIF

   RETURN Nil

/*===========================================================================
 * Collapse() / Expand() / ToggleCollapse()
 *
 * Hide or restore the panel and shift any top-level dialogs owned by
 * the parent form so they fill (or give back) the space occupied by
 * the sidebar.  Original positions are remembered per HWND, so manual
 * moves made while the panel is expanded are respected on the next
 * collapse cycle.
 *=========================================================================*/

METHOD Collapse() CLASS HPanel

   IF ::lCollapsed
      RETURN Nil
   ENDIF

   ::Hide()
   ::lCollapsed := .T.

   ::SyncTrackedWindows()

   IF ::bOnCollapse != Nil
      Eval( ::bOnCollapse, Self )
   ENDIF

   RETURN Nil

METHOD Expand() CLASS HPanel

   IF !::lCollapsed
      RETURN Nil
   ENDIF

   ::Show()
   ::lCollapsed := .F.

   ::SyncTrackedWindows()

   IF ::bOnExpand != Nil
      Eval( ::bOnExpand, Self )
   ENDIF

   RETURN Nil

METHOD ToggleCollapse() CLASS HPanel

   IF ::lCollapsed
      ::Expand()
   ELSE
      ::Collapse()
   ENDIF

   RETURN Nil

/*=============================================================================
 * SyncTrackedWindows
 *
 * Applies (or reverts) the horizontal shift on every top-level dialog
 * owned by the parent form when the panel collapsed state changes.
 *
 * This version is intentionally type-agnostic: it never compares HWNDs
 * across calls and never stores them in an array.  It only checks
 * whether ::lCollapsed changed since the last call, and if so shifts
 * each visible owned window by +-::nWidth using the delta rule:
 *
 *     nDelta = iif( ::lCollapsed, -::nWidth, +::nWidth )
 *     left   = left  + nDelta
 *     width  = width - nDelta
 *
 * The previous algorithm kept a per-HWND table of original positions
 * and looked up entries with AScan().  Depending on how the C helper
 * marshalled handles (pointer vs numeric), the comparison raised
 * "Argument error: ==".  The delta approach sidesteps that entirely.
 *===========================================================================*/
METHOD SyncTrackedWindows() CLASS HPanel

   LOCAL hParent, aWins, aRect, hWnd, nHandle, nDelta, i

   IF ::oParent == Nil
      RETURN Nil
   ENDIF

   hParent := ::oParent:handle
   IF ValType( hParent ) != "N" .OR. hParent == 0
      RETURN Nil
   ENDIF

   /* No state change since last sync: nothing to do.  This also
    * prevents double-shifting when the timer fires every 200 ms. */
   IF ::lLastSyncState != Nil .AND. ::lLastSyncState == ::lCollapsed
      RETURN Nil
   ENDIF
   ::lLastSyncState := ::lCollapsed

   /* Collapse: shift left, grow right.  Expand: shift right, shrink. */
   nDelta := iif( ::lCollapsed, -::nWidth, ::nWidth )

   aWins := hwg_Panel_EnumOwned( hParent )

   FOR i := 1 TO Len( aWins )

      hWnd := aWins[i]

      /* Normalise handle to numeric.  Accept either numeric or
       * pointer from the C side; never mix them in a comparison. */
      DO CASE
      CASE ValType( hWnd ) == "N"
         nHandle := hWnd
      CASE ValType( hWnd ) == "P"
         nHandle := Int( hWnd )
      OTHERWISE
         LOOP
      ENDCASE

      IF nHandle <= 0
         LOOP
      ENDIF

      aRect := hwg_Panel_GetRect( nHandle )
      IF ValType( aRect ) != "A" .OR. Len( aRect ) != 4
         LOOP
      ENDIF
      IF aRect[3] <= aRect[1] .OR. aRect[4] <= aRect[2]
         LOOP
      ENDIF

      hwg_MoveWindow( nHandle, ;
                      aRect[1] + nDelta, ;
                      aRect[2], ;
                      ( aRect[3] - aRect[1] ) - nDelta, ;
                      aRect[4] - aRect[2], ;
                      .T. )
   NEXT

   RETURN Nil

/*===========================================================================
 * SetAutoCollapse( lOn )
 *
 * Enables / disables the hover auto-collapse.  When enabled, a 200 ms
 * timer polls the cursor; if it stays away from the panel for longer
 * than ::nGraceThresh milliseconds the panel collapses automatically.
 * Moving the cursor to the left edge (x <= 4) expands it back.
 *
 * The timer is created lazily so panels that never opt in pay nothing.
 *=========================================================================*/
METHOD SetAutoCollapse( lOn ) CLASS HPanel

   lOn := ( ValType( lOn ) == "L" .AND. lOn )

   IF lOn == ::lAutoCollapse
      RETURN Nil
   ENDIF

   ::lAutoCollapse := lOn

   IF ::lAutoCollapse
      IF ::nAutoTimer == 0
         ::nAutoTimer := 100
         /* The codeblock is stored in the C-level timer registry and
          * evaluated on every tick by s_timerProcBlock.  No global
          * dispatcher name is looked up, so the timer works even when
          * HWG_TIMERPROC / HWG_PANEL_TIMERPROC are not defined. */
         hwg_SetTimer( ::handle, ::nAutoTimer, 200, {|| ::OnAutoTimer()} )
      ENDIF
   ELSE
      IF ::nAutoTimer != 0
         hwg_KillTimer( ::handle, ::nAutoTimer )
         ::nAutoTimer := 0
      ENDIF
      IF ::lCollapsed
         ::Expand()
      ENDIF
   ENDIF

   RETURN Nil

/*===========================================================================
 * OnAutoTimer()
 *
 * Timer callback: keeps the tracked windows in sync (so a dialog that
 * is opened while collapsed is immediately shifted) and, if auto-
 * collapse is on, decides whether to collapse or expand based on the
 * current cursor position.
 *=========================================================================*/
METHOD OnAutoTimer() CLASS HPanel

   LOCAL aPos, aRect, nX, nY, lInside

   ::SyncTrackedWindows()

   IF !::lAutoCollapse
      RETURN Nil
   ENDIF

   aPos := hwg_GetCursorPos()
   IF ValType( aPos ) != "A" .OR. Len( aPos ) < 2
      RETURN Nil
   ENDIF
   nX := aPos[1]
   nY := aPos[2]

   IF ::lCollapsed

      /* Expand when the cursor reaches the left edge of the screen. */
      IF nX <= 4
         ::Expand()
         ::nGraceMs := 0
      ENDIF

   ELSE

      /* Use the panel's real screen rect for the hit test.  The
       * previous version compared the cursor X against ::nWidth,
       * assuming the main window was at x = 0.  When the window is
       * centred (or moved), the panel's on-screen x is not 0 and
       * the check never matches.  A small tolerance on all four
       * sides prevents flicker when the cursor grazes the border. */
      aRect   := hwg_Panel_GetRect( ::handle )
      lInside := .F.

      IF ValType( aRect ) == "A" .AND. Len( aRect ) == 4
         lInside := ( nX >= aRect[1] - 20 .AND. nX <= aRect[3] + 20 .AND. ;
                      nY >= aRect[2]      .AND. nY <= aRect[4] + 40 )
      ENDIF

      IF !lInside
         ::nGraceMs += 200
         IF ::nGraceMs >= ::nGraceThresh
            ::Collapse()
            ::nGraceMs := 0
         ENDIF
      ELSE
         ::nGraceMs := 0
      ENDIF

   ENDIF

   RETURN Nil

CLASS HPanelStS INHERIT HPANEL

   DATA aParts
   DATA aText

   METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, bcolor, oStyle, aParts )
   METHOD Write( cText, nPart, lRedraw )
   METHOD SetText( cText )    INLINE ::Write( cText,, .T. )
   METHOD PaintText( hDC )
   METHOD Paint()

ENDCLASS

METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, bcolor, oStyle, aParts ) CLASS HPanelStS

   oWndParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )
   IF bColor == Nil
      bColor := 0xeeeeee
   ENDIF

/*
   ::Super:New( oWndParent, nId, SS_OWNERDRAW, 0, oWndParent:nHeight - nHeight, ;
      oWndParent:nWidth, nHeight, bInit, { |o, w, h|o:Move( 0, h - o:nHeight ) }, bPaint, bcolor )
    Block reverted to old value with HB_SYMBOL_UNUSED( w )
*/

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, 0, oWndParent:nHeight - nHeight, ;
      oWndParent:nWidth, nHeight, bInit, { |o, w, h| HB_SYMBOL_UNUSED( w ) ,  o:Move( 0, h - o:nHeight ) }, bPaint, bcolor )
   ::Anchor := ANCHOR_LEFTABS+ANCHOR_RIGHTABS

   ::oFont := Iif( oFont == Nil, ::oParent:oFont, oFont )
   ::oStyle := oStyle
   IF !Empty( aParts )
      ::aParts := aParts
   ELSE
      ::aParts := {0}
   ENDIF
   ::aText := Array( Len(::aParts) )
   AFill( ::aText, "" )

   RETURN Self

METHOD Write( cText, nPart, lRedraw ) CLASS HPanelStS

   ::aText[Iif(nPart==Nil,1,nPart)] := cText
   IF !::lHide .AND. (Valtype( lRedraw ) != "L" .OR. lRedraw)
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF

   RETURN Nil

METHOD PaintText( hDC ) CLASS HPanelStS

   LOCAL i, x1, x2, nWidth := ::nWidth, oldTColor

   IF ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
   ENDIF
   hwg_Settransparentmode( hDC, .T. )
   oldTColor  := hwg_Settextcolor( hDC, ::tcolor )
   FOR i := 1 TO Len( ::aParts )
      x1 := Iif( i == 1, 4, x2 + 4 )
      IF ::aParts[i] == 0
         x2 := x1 + Int( nWidth/(Len(::aParts)-i+1) )
      ELSE
         x2 := x1 + ::aParts[i]
      ENDIF
      nWidth -= ( x2-x1+1 )
      IF !Empty( ::aText[i] )
         hwg_Drawtext( hDC, ::aText[i], x1, 6, x2, ::nHeight-2, DT_LEFT + DT_VCENTER )
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

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( ::handle, pps )

   //IF !Empty( block := hwg_getPaintCB( ::aPaintCB, PAINT_BACK ) )
   IF !Empty( ::oPaintCB ) .AND. !Empty( block := ::oPaintCB:Get( PAINT_BACK ) )
      aCoors := hwg_Getclientrect( ::handle )
      Eval( block, Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
   ELSEIF Empty( ::oStyle )
      ::oStyle := HStyle():New( {::bColor}, 1,, 0.4, 0 )
   ENDIF
   ::oStyle:Draw( hDC, 0, 0, ::nWidth, ::nHeight )

   ::PaintText( hDC )
   ::DrawItems( hDC )

   hwg_Endpaint( ::handle, pps )

   RETURN Nil

CLASS HPanelHea INHERIT HPANEL

   DATA  xt, yt
   DATA  lMaximized   INIT .F.

   METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, tcolor, bcolor, oStyle, ;
      cText, xt, yt, lBtnClose, lBtnMax, lBtnMin )
   METHOD SetText( c )
   METHOD SetSysbtnColor( tColor, bColor )
   METHOD PaintText( hDC )
   METHOD Paint()

ENDCLASS

METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, tcolor, bcolor, oStyle, ;
   cText, xt, yt, lBtnClose, lBtnMax, lBtnMin ) CLASS HPanelHea

   LOCAL nBtnSize, btnClose, btnMax, btnMin, x1

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
   ::tColor := Iif( tColor==Nil, 0, tColor )
   ::lDragWin := .T.

   IF !Empty( lBtnClose ) .OR. !Empty( lBtnMax ) .OR. !Empty( lBtnMin )
      nBtnSize := Min( 24, ::nHeight )
      x1 := ::nWidth-nBtnSize-4

      IF !Empty( lBtnClose )
         @ x1, Int((::nHeight-nBtnSize)/2) OWNERBUTTON btnClose OF Self ;
            SIZE nBtnSize, nBtnSize ON PAINT {|o|fPaintBtn(o)} ;
            ON SIZE ANCHOR_RIGHTABS ON CLICK {||::oParent:Close()}
         x1 -= nBtnSize
      ENDIF
      IF !Empty( lBtnMax )
         @ x1, Int((::nHeight-nBtnSize)/2) OWNERBUTTON btnMax OF Self ;
            SIZE nBtnSize, nBtnSize ON PAINT {|o|fPaintBtn(o)} ;
            ON SIZE ANCHOR_RIGHTABS ;
            ON CLICK {||Iif(::lMaximized,::oParent:Restore(),::oParent:Maximize()),::lMaximized:=!::lMaximized}
         x1 -= nBtnSize
      ENDIF
      IF !Empty( lBtnMin )
         @ x1, Int((::nHeight-nBtnSize)/2) OWNERBUTTON btnMin OF Self ;
            SIZE nBtnSize, nBtnSize ON PAINT {|o|fPaintBtn(o)} ;
            ON SIZE ANCHOR_RIGHTABS ;
            ON CLICK {||::oParent:Minimize()}
      ENDIF
      ::SetSysbtnColor( 0, 0xededed )
   ENDIF

   RETURN Self

METHOD SetText( c ) CLASS HPanelHea

   ::title := c
   hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )

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

   LOCAL pps, hDC, block, aCoors, i

   IF ::bPaint != Nil
      RETURN Eval( ::bPaint, Self )
   ENDIF

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( ::handle, pps )

   //IF !Empty( block := hwg_getPaintCB( ::aPaintCB, PAINT_BACK ) )
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
   FOR i := 1 TO Len( ::aControls )
      hwg_Invalidaterect( ::aControls[i]:handle, 0 )
   NEXT

   RETURN Nil

#define OBTN_STATE1  5

STATIC FUNCTION fPaintBtn( oBtn )

   LOCAL pps, hDC, aCoors

   IF oBtn:state == OBTN_NORMAL
      oBtn:state := OBTN_STATE1
      hwg_Invalidaterect( oBtn:oParent:handle, 0, oBtn:nLeft, oBtn:nTop, ;
         oBtn:nLeft+oBtn:nWidth-1, oBtn:nTop+oBtn:nHeight-1 )
      RETURN Nil
   ELSEIF oBtn:state == OBTN_STATE1
      oBtn:state := OBTN_NORMAL
   ENDIF
   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( oBtn:handle, pps )
   aCoors := hwg_Getclientrect( oBtn:handle )

   IF oBtn:state == OBTN_MOUSOVER
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

/*===========================================================================
 * HPanelAutoTick
 *
 * Idle callback installed by HPanel:SetAutoCollapse().  Runs on the
 * main thread between window messages.  Throttled to one real check
 * every ~200 ms so it does not steal CPU from the UI.
 *
 * Using hb_idleAdd instead of a Windows timer or a background thread
 * avoids two problems:
 *   - HWG_SETTIMER with 4 parameters never reaches HPanel:onEvent in
 *     this build, so WM_TIMER is lost;
 *   - STATIC variables are not shared between Harbour threads, so a
 *     worker thread cannot see oPanel / lAutoCollapse reliably.
 *=========================================================================*/
FUNCTION HPanelAutoTick()

   LOCAL nNow
   hwg_MsgInfo( "tick" )   // TEMPORÁRIO

   IF oAutoPanel == Nil
      RETURN Nil
   ENDIF

   nNow := hb_MilliSeconds()
   IF nNow - nLastCheck < 200
      RETURN Nil
   ENDIF
   nLastCheck := nNow

   BEGIN SEQUENCE
      oAutoPanel:OnAutoTimer()
   RECOVER
      // swallow transient errors so the idle loop never dies
   END SEQUENCE

   RETURN Nil
