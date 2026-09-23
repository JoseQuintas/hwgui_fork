/*
 * $Id: hsplit.prg 3339 2023-09-28 08:36:01Z alkresin $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HSplitter class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It relies exclusively on the
 * hwg_* abstraction layer:
 *
 *   - hwg_Createsplitter       → GtkDrawingArea with draw_func (control.c)
 *   - hwg_Loadcursor(GDK_SIZING) → needs case 120 in HWG_LOADCURSOR
 *                                  (control.c); the previous mapping was
 *                                  missing it, causing the resize cursor
 *                                  to fall back to "default".
 *   - hwg_MoveWidget           → gtk_fixed_move + set_size_request
 *   - hwg_SetCursor            → gtk_widget_set_cursor
 *   - hwg_Getdc / hwg_Releasedc→ bridge to live cairo_t (draw.c)
 *   - hwg_Drawbutton / hwg_Getclientrect
 *                              → draw.c
 *
 * The whole "drag-follow-cursor" logic in ::Drag() is plain Harbour and
 * is unaffected by the toolkit.
 */

#include "hbclass.ch"
#include "hwgui.ch"

CLASS HSplitter INHERIT HControl

   CLASS VAR winclass INIT "STATIC"

   DATA aLeft
   DATA aRight
   DATA lVertical
   DATA oStyle
   DATA lRepaint    INIT .F.
   DATA nFrom, nTo
   DATA hCursor
   DATA lCaptured   INIT .F.
   DATA lMoved      INIT .F.
   DATA bEndDrag

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
      bSize, bDraw, color, bcolor, aLeft, aRight, nFrom, nTo, oStyle )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint()
   METHOD Drag( xPos, yPos )
   METHOD DragAll( xPos, yPos )

ENDCLASS

/* bPaint ==> bDraw */
METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
      bSize, bDraw, color, bcolor, aLeft, aRight, nFrom, nTo, oStyle ) CLASS HSplitter

   ::Super:New( oWndParent, nId, WS_CHILD + WS_VISIBLE + SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, , , ;
      bSize, bDraw, , iif( color == Nil, 0, color ), bcolor )

   ::title  := ""
   ::aLeft  := iif( aLeft == Nil, {}, aLeft )
   ::aRight := iif( aRight == Nil, {}, aRight )
   ::lVertical := ( ::nHeight > ::nWidth )
   ::nFrom  := nFrom
   ::nTo    := nTo
   ::oStyle := oStyle

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HSplitter

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createsplitter( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HSplitter

   HB_SYMBOL_UNUSED( wParam )

   IF msg == WM_MOUSEMOVE
      IF ::hCursor == Nil
         ::hCursor := hwg_Loadcursor( GDK_SIZING )
      ENDIF
      Hwg_SetCursor( ::hCursor, ::handle )
      IF ::lCaptured
         IF ::lRepaint
            ::DragAll( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
         ELSE
            ::Drag( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
         ENDIF
      ENDIF
   ELSEIF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_LBUTTONDOWN
      Hwg_SetCursor( ::hCursor, ::handle )
      ::lCaptured := .T.
   ELSEIF msg == WM_LBUTTONUP
      ::DragAll()
      ::lCaptured := .F.
      IF ::bEndDrag != Nil
         Eval( ::bEndDrag, Self )
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

   Return - 1

METHOD Init() CLASS HSplitter

   IF !::lInit
      ::Super:Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD Paint() CLASS HSplitter

   LOCAL hDC, aCoors

   IF ::bPaint != Nil
      Eval( ::bPaint, Self )
   ELSE
      hDC := hwg_Getdc( ::handle )
      IF ::oStyle == Nil
         hwg_Drawbutton( hDC, 0, 0, ::nWidth - 1, ::nHeight - 1, 6 )
      ELSE
         aCoors := hwg_Getclientrect( ::handle )
         ::oStyle:Draw( hDC, 0, 0, aCoors[3], aCoors[4] )
      ENDIF
   hwg_Releasedc( ::handle, hDC )
   ENDIF

   RETURN Nil

METHOD Drag( xPos, yPos ) CLASS HSplitter

   LOCAL nFrom, nTo

   nFrom := iif( ::nFrom == Nil, 1, ::nFrom )
   nTo := iif( ::nTo == Nil, iif( ::lVertical,::oParent:nWidth - 1,::oParent:nHeight - 1 ), ::nTo )
   IF ::lVertical
      IF xPos > 32000
         xPos -= 65535
      ENDIF
      IF ( xPos := ( ::nLeft + xPos ) ) >= nFrom .AND. xPos <= nTo
         ::nLeft := xPos
      ENDIF
   ELSE
      IF yPos > 32000
         yPos -= 65535
      ENDIF
      IF ( yPos := ( ::nTop + yPos ) ) >= nFrom .AND. yPos <= nTo
         ::nTop := yPos
      ENDIF
   ENDIF
   hwg_MoveWidget( ::handle, ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ::lMoved := .T.

   RETURN Nil

METHOD DragAll( xPos, yPos ) CLASS HSplitter

   LOCAL i, oCtrl, nDiff, wold, hold

   IF xPos != Nil .OR. yPos != Nil
      ::Drag( xPos, yPos )
   ENDIF
   FOR i := 1 TO Len( ::aRight )
      oCtrl := ::aRight[i]
      wold := oCtrl:nWidth
      hold := oCtrl:nHeight
      IF ::lVertical
         nDiff := ::nLeft + ::nWidth - oCtrl:nLeft
         oCtrl:Move( oCtrl:nLeft + nDiff, , oCtrl:nWidth - nDiff )
      ELSE
         nDiff := ::nTop + ::nHeight - oCtrl:nTop
         oCtrl:Move( , oCtrl:nTop + nDiff, , oCtrl:nHeight - nDiff )
      ENDIF
      hwg_onAnchor( oCtrl, wold, hold, oCtrl:nWidth, oCtrl:nHeight )
   NEXT
   FOR i := 1 TO Len( ::aLeft )
      oCtrl := ::aLeft[i]
      wold := oCtrl:nWidth
      hold := oCtrl:nHeight
      IF ::lVertical
         nDiff := ::nLeft - ( oCtrl:nLeft + oCtrl:nWidth )
         oCtrl:Move( , , oCtrl:nWidth + nDiff )
      ELSE
         nDiff := ::nTop - ( oCtrl:nTop + oCtrl:nHeight )
         oCtrl:Move( , , , oCtrl:nHeight + nDiff )
      ENDIF
      hwg_onAnchor( oCtrl, wold, hold, oCtrl:nWidth, oCtrl:nHeight )
   NEXT
   ::lMoved := .F.

   RETURN Nil
