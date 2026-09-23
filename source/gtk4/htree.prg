/*
 * $Id: htree.prg 3339 2023-09-28 08:36:01Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HBrowse class - browse databases and arrays
 *
 * Copyright 2013 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It relies exclusively on the
 * hwg_* abstraction layer:
 *
 *   - hwg_Createbrowse   → GtkDrawingArea + draw_func  (control.c)
 *   - hwg_Getdc/Releasedc→ bridge to the live cairo_t  (draw.c)
 *   - all drawing calls  → draw.c / drawtext.c
 *   - hwg_Redrawwindow   → gtk_widget_queue_draw       (draw.c)
 *
 * Pre-existing bug (not GTK4-related): HTree:Paint() calls
 * ::rowCount() as if it were a METHOD, but rowCount is a DATA member.
 * Change `::rowCount()` to `::rowCount` if the treeview fails to paint.
 */

#include "hwgui.ch"
#include "inkey.ch"
#include "dbstruct.ch"
#include "hbclass.ch"

#ifndef SB_HORZ
#define SB_HORZ             0
#define SB_VERT             1
#define SB_CTL              2
#define SB_BOTH             3
#endif

#define  CLR_WHITE      16777215
#define  CLR_MGREEN      8421440
#define  CLR_VDBLUE     10485760

STATIC crossCursor := nil
STATIC arrowCursor := nil
STATIC vCursor     := nil

CLASS HTreeNode INHERIT HObject

   DATA handle
   DATA oTree, oParent
   DATA nLevel
   DATA lExpanded   INIT .F.
   DATA title
   DATA aImages
   DATA aItems      INIT {}
   DATA bClick

   METHOD New( oTree, oParent, oPrev, oNext, cTitle, bClick, aImages )
   METHOD AddNode( cTitle, oPrev, oNext, bClick, aImages )
   METHOD DELETE(lInternal)
   METHOD GetText()  INLINE ::title
   METHOD SetText( cText ) INLINE ::title := cText
   METHOD getNodeIndex()
   METHOD PrevNode( nNode, lSkip )
   METHOD NextNode( nNode, lSkip )

ENDCLASS

METHOD New( oTree, oParent, oPrev, oNext, cTitle, bClick, aImages ) CLASS HTreeNode

   LOCAL aItems, i, h, op, nPos

   ::oTree := oTree
   ::oParent := oParent
   ::nLevel  := iif( __ObjHasMsg( oParent, "NLEVEL" ), oParent:nLevel + 1, 1 )
   ::bClick := bClick
   ::title := iif( Empty( cTitle ), "", cTitle )
   ::handle := ++ oTree:nNodeCount

   IF aImages != Nil .AND. !Empty( aImages )
      ::aImages := {}
      FOR i := 1 TO Len( aImages )
         AAdd( ::aImages, iif( oTree:Type, hwg_BmpFromRes( aImages[i] ), hwg_Openimage( AddPath( aImages[i],HBitmap():cPath ) ) ) )
      NEXT
   ENDIF

   nPos := iif( oPrev == Nil, 2, 0 )
   IF oPrev == Nil .AND. oNext != Nil
      op := iif( oNext:oParent == Nil, oNext:oTree, oNext:oParent )
      FOR i := 1 TO Len( op:aItems )
         IF op:aItems[ i ]:handle == oNext:handle
            EXIT
         ENDIF
      NEXT
      IF i > 1
         oPrev := op:aItems[ i - 1 ]
         nPos := 0
      ELSE
         nPos := 1
      ENDIF
   ENDIF

   aItems := iif( oParent == Nil, oTree:aItems, oParent:aItems )
   IF nPos == 2
      AAdd( aItems, Self )
   ELSEIF nPos == 1
      AAdd( aItems, Nil )
      AIns( aItems, 1 )
      aItems[ 1 ] := Self
   ELSE
      AAdd( aItems, Nil )
      h := oPrev:handle
      IF ( i := AScan( aItems, { | o | o:handle == h } ) ) == 0
         aItems[ Len( aItems ) ] := Self
      ELSE
         AIns( aItems, i + 1 )
         aItems[ i + 1 ] := Self
      ENDIF
   ENDIF

   RETURN Self

METHOD AddNode( cTitle, oPrev, oNext, bClick, aImages ) CLASS HTreeNode

   LOCAL oParent := Self
   LOCAL oNode := HTreeNode():New( ::oTree, oParent, oPrev, oNext, cTitle, bClick, aImages )

   RETURN oNode

METHOD DELETE( lInternal ) CLASS HTreeNode

   LOCAL h := ::handle, j, alen, aItems

   IF ! Empty( ::aItems )
      alen := Len( ::aItems )
      FOR j := 1 TO alen
         ::aItems[ j ]:Delete( .T. )
         ::aItems[ j ] := Nil
      NEXT
   ENDIF
   IF lInternal == Nil
      aItems := iif( ::oParent == Nil, ::oTree:aItems, ::oParent:aItems )
      j := AScan( aItems, { | o | o:handle == h } )
      ADel( aItems, j )
      ASize( aItems, Len( aItems ) - 1 )
   ENDIF

   RETURN Nil

METHOD getNodeIndex() CLASS HTreeNode

   LOCAL aItems := ::oParent:aItems, nNode

   FOR nNode := 1 TO Len( aItems )
      IF aItems[nNode] == Self
         EXIT
      ENDIF
   NEXT

   RETURN nNode

METHOD PrevNode( nNode, lSkip ) CLASS HTreeNode

   LOCAL oNode

   IF nNode == Nil
      nNode := ::getNodeIndex()
   ENDIF

   IF nNode == 1
      IF ::nLevel == 1
         RETURN Nil
      ELSE
         oNode := ::oParent
         nNode := oNode:getNodeIndex()
      ENDIF
   ELSE
      nNode --
      oNode := ::oParent:aItems[nNode]
      IF oNode:lExpanded .AND. Empty( lSkip )
         nNode := Len( oNode:aItems )
         oNode := oNode:aItems[nNode]
      ENDIF
   ENDIF

   RETURN oNode

METHOD NextNode( nNode, lSkip ) CLASS HTreeNode

   LOCAL oNode

   IF nNode == Nil
      nNode := ::getNodeIndex()
   ENDIF
   IF ::lExpanded .AND. Empty( lSkip )
      nNode := 1
      oNode := ::aItems[nNode]
   ELSEIF nNode < Len( ::oParent:aItems )
      oNode := ::oParent:aItems[++nNode]
   ELSEIF ::nLevel > 1
      nNode := ::oParent:getNodeIndex()
      oNode := ::oParent:NextNode( @nNode, .T. )
   ELSE
      RETURN Nil
   ENDIF

   RETURN oNode

CLASS HTree INHERIT HControl

   CLASS VAR winclass   INIT "SysTreeView32"

   DATA aItems INIT {}
   DATA nNodeCount  INIT 0
   DATA aScreen
   DATA oFirst
   DATA oSelected
   DATA aImages
   DATA bItemChange, bExpand, bRClick, bDblClick, bClick
   DATA lEmpty INIT .T.
   DATA area
   DATA width, height
   DATA rowCount              // Number of visible data rows
   DATA rowCurrCount  INIT 0
   DATA oPenLine, oPenPlus
   DATA nIndent   INIT 20
   DATA tcolorSel INIT CLR_WHITE
   DATA bcolorSel INIT CLR_VDBLUE
   DATA brushSel

   DATA hScrollV, hScrollH
   DATA nScrollV  INIT 0
   DATA nScrollH  INIT 0
   DATA bScrollPos

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, color, bcolor, aImages, lResour, lEditLabels, bClick, nBC )
   METHOD Init()
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD AddNode( cTitle, oPrev, oNext, bClick, aImages )
   METHOD GetSelected()   INLINE ::oSelected
   METHOD Expand( oNode ) BLOCK {|Self,o| o:lExpanded := .T., hwg_Redrawwindow( ::area ) }
   METHOD SELECT( oNode, lNoRedraw )
   METHOD Clean()
   METHOD Refresh()
   METHOD END()
   METHOD Paint()
   METHOD PaintNode( hDC, oNode, nNode, nLine )
   METHOD ButtonDown( lParam )
   METHOD ButtonUp( lParam )
   METHOD ButtonDbl( lParam )
   METHOD ButtonRDown( lParam )
   METHOD GoDown( n )
   METHOD GoUp( n )
   METHOD MouseWheel( nKeys, nDelta )
   METHOD DoHScroll()
   METHOD DoVScroll()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, color, bcolor, aImages, lResour, lEditLabels, bClick, nBC ) CLASS HTree

   LOCAL i

   * Parameters not used
   HB_SYMBOL_UNUSED(lEditLabels)
   HB_SYMBOL_UNUSED(nBC)

   IF color == Nil
      color := 0
   ENDIF
   IF bcolor == Nil
      bcolor := CLR_WHITE
   ENDIF
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, , , color, bcolor )

   ::title   := ""
   ::Type    := iif( lResour == Nil, .F. , lResour )
   ::bClick := bClick

   IF aImages != Nil .AND. !Empty( aImages )
      ::aImages := {}
      FOR i := 1 TO Len( aImages )
         AAdd( ::aImages, iif( ::Type, hwg_BmpFromRes( aImages[i] ), hwg_Openimage( AddPath( aImages[i],HBitmap():cPath ) ) ) )
      NEXT
   ENDIF

   ::oPenLine := HPen():Add( PS_DOT, 0.6, 7566195 )
   ::oPenPlus := HPen():Add( PS_SOLID, 2, 0 )

   ::Activate()

   RETURN Self

METHOD Init() CLASS HTree

   IF ! ::lInit
      ::Super:Init()
   ENDIF

   RETURN Nil

METHOD Activate() CLASS HTree

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createbrowse( Self )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HTree

   LOCAL retValue := - 1

   IF ::bOther != Nil
      Eval( ::bOther, Self, msg, wParam, lParam )
   ENDIF

   IF msg == WM_PAINT
      ::Paint()
      retValue := 1

   ELSEIF msg == WM_SETFOCUS
      IF ::bGetFocus != Nil
         Eval( ::bGetFocus, Self )
      ENDIF

   ELSEIF msg == WM_KILLFOCUS
      IF ::bLostFocus != Nil
         Eval( ::bLostFocus, Self )
      ENDIF

   ELSEIF msg == WM_HSCROLL
      ::DoHScroll()

   ELSEIF msg == WM_VSCROLL
      ::DoVScroll( wParam )

   ELSEIF msg == WM_KEYUP
      IF wParam == GDK_Control_L .OR. wParam == GDK_Control_R
         IF wParam == ::nCtrlPress
            ::nCtrlPress := 0
         ENDIF
      ENDIF
      retValue := 1
   ELSEIF msg == WM_KEYDOWN
      IF wParam == GDK_Down        // Down
         ::GoDown( 1 )
      ELSEIF wParam == GDK_Up    // Up
         ::GoUp( 1 )
      ELSEIF wParam == GDK_Page_Down    // PageDown
         ::GoDown( 2 )
      ELSEIF wParam == GDK_Page_Up    // PageUp
         ::GoUp( 2 )
      ENDIF
      retValue := 1

   ELSEIF msg == WM_LBUTTONDOWN
      ::ButtonDown( lParam )

   ELSEIF msg == WM_LBUTTONUP
      ::ButtonUp( lParam )

   ELSEIF msg == WM_LBUTTONDBLCLK
      ::ButtonDbl( lParam )

   ELSEIF msg == WM_RBUTTONDOWN
      ::ButtonRDown( lParam )

   ELSEIF msg == WM_MOUSEWHEEL
      ::MouseWheel( hwg_Loword( wParam ),      ;
         iif( hwg_Hiword( wParam ) > 32768, ;
         hwg_Hiword( wParam ) - 65535, hwg_Hiword( wParam ) ) )

   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

   RETURN retValue

METHOD AddNode( cTitle, oPrev, oNext, bClick, aImages ) CLASS HTree

   LOCAL oNode := HTreeNode():New( Self, Self, oPrev, oNext, cTitle, bClick, aImages )

   ::lEmpty := .F.

   RETURN oNode

METHOD SELECT( oNode, lNoRedraw ) CLASS HTree

   LOCAL oParent := oNode

   ::oSelected := oNode
   DO WHILE oParent:nLevel > 1
      ( oParent := oParent:oParent ):lExpanded := .T.
   ENDDO

   IF oNode:bClick != Nil
      Eval( oNode:bClick, oNode )
   ELSEIF ::bClick != Nil
      Eval( ::bClick, oNode )
   ENDIF

   IF Empty( lNoRedraw )
      hwg_Redrawwindow( ::area )
   ENDIF

   RETURN Nil

METHOD Clean() CLASS HTree

   ::lEmpty := .T.
   ReleaseTree( ::aItems, .T. )
   ::aItems := { }
   ::nNodeCount := 0
   ::aScreen := Nil
   ::oFirst := Nil
   hwg_Redrawwindow( ::area )

   RETURN Nil

METHOD Refresh() CLASS HTree

   hwg_Redrawwindow( ::area )

   RETURN Nil

METHOD Paint() CLASS HTree

   LOCAL hDC
   LOCAL aCoors, aMetr, y1, y2, oNode, nNode, nLine := 1

   hDC := hwg_Getdc( ::area )

   IF ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
   ENDIF
   IF ::brushSel == Nil
      ::brushSel := HBrush():Add( ::bcolorSel )
   ENDIF

   aCoors := hwg_Getclientrect( ::handle )
   hwg_Fillrect( hDC, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, ::brush:handle )
   hwg_gtk_drawedge( hDC, aCoors[1], aCoors[2], aCoors[3] - 1, aCoors[4] - 1, 6 )
   aMetr := hwg_Gettextmetric( hDC )

   IF Empty( ::aItems )
      RETURN Nil
   ELSEIF Empty( ::oFirst )
      ::oFirst := ::aItems[1]
   ENDIF

   ::width := aMetr[ 2 ]
   ::height := aMetr[ 1 ]
   y1 := aCoors[ 2 ] + 2
   y2 := aCoors[ 4 ] - 2

   ::rowCount := Int( ( y2 - y1 ) / ( ::height + 1 ) )
   IF Empty( ::aScreen ) .OR. Len( ::aScreen ) < ::rowCount
      ::aScreen := Array( ::rowCount + 5 )
   ENDIF

   oNode := ::oFirst
   nNode := oNode:getNodeIndex()

   DO WHILE .T.

      ::aScreen[nLine] := oNode
      ::PaintNode( hDC, oNode, nNode, nLine ++ )
      IF nLine > ::rowCount .OR. Empty( oNode := oNode:NextNode( @nNode ) )
         EXIT
      ENDIF
   ENDDO
   ::rowCurrCount := nLine - 1

   RETURN Nil

METHOD PaintNode( hDC, oNode, nNode, nLine ) CLASS HTree

   LOCAL y1 := ( ::height + 1 ) * ( nLine - 1 ) + 1, x1 := 10 + oNode:nLevel * ::nIndent
   LOCAL i, hBmp, aBmpSize, nTextWidth

   hwg_Selectobject( hDC, ::oPenLine:handle )
   hwg_Drawline( hDC, iif( Empty(oNode:aItems ),x1 + 5,x1 + 1 ), y1 + 9, x1 + ::nIndent - 4, y1 + 9 )
   IF nNode > 1 .OR. oNode:nLevel > 1
      hwg_Drawline( hDC, x1 + 5, y1, x1 + 5, iif( Empty(oNode:aItems ),y1 + 9,y1 + 4 ) )
   ENDIF
   IF nNode < Len( oNode:oParent:aItems )
      hwg_Drawline( hDC, x1 + 5, iif( Empty(oNode:aItems ),y1 + 9,y1 + 12 ), x1 + 5, y1 + ::height + 1 )
   ENDIF
   IF !Empty( oNode:aItems )
      hwg_Rectangle( hDC, x1, y1 + 4, x1 + 8, y1 + 12 )
      IF !oNode:lExpanded
         hwg_Selectobject( hDC, ::oPenPlus:handle )
         hwg_Drawline( hDC, x1 + 5, y1 + 5, x1 + 5, y1 + 12 )
         hwg_Drawline( hDC, x1 + 1, y1 + 9, x1 + 8, y1 + 9 )
         hwg_Selectobject( hDC, ::oPenLine:handle )
      ENDIF
   ENDIF

   IF !Empty( oNode:aImages )
      hBmp := iif( ::oSelected == oNode .AND. Len( oNode:aImages ) > 1, oNode:aImages[2], oNode:aImages[1] )
   ELSEIF !Empty( ::aImages )
      hBmp := iif( ::oSelected == oNode .AND. Len( ::aImages ) > 1, ::aImages[2], ::aImages[1] )
   ENDIF
   IF !Empty( hBmp )
      aBmpSize := hwg_Getbitmapsize( hBmp )
      hwg_Drawbitmap( hDC, hBmp, , x1 + ::nIndent, y1, aBmpSize[1], aBmpSize[2] )
   ENDIF

   nTextWidth := hwg_GetTextWidth( hDC, oNode:title )
   x1 += ::nIndent + iif( !Empty( aBmpSize ), aBmpSize[1] + 4, 0 )
   IF ::oSelected == oNode
      hwg_Settextcolor( hDC, ::tcolorSel )
      hwg_Fillrect( hDC, x1, y1, x1 + nTextWidth, y1 + ( ::height + 1 ), ::brushSel:handle )
   ELSE
      hwg_Fillrect( hDC, x1, y1, x1 + nTextWidth, y1 + ( ::height + 1 ), ::brush:handle )
   ENDIF
   hwg_Drawtext( hDC, oNode:title, x1, y1, ::nLeft+::nWidth-1, y1 + ( ::height + 1 ),,.T. )
   hwg_Settextcolor( hDC, ::tcolor )

   FOR i := oNode:nLevel - 1 TO 1 STEP - 1
      oNode := oNode:oParent
      IF !( oNode == Atail( oNode:oParent:aItems ) )
         x1 := 10 + oNode:nLevel * ::nIndent
         hwg_Drawline( hDC, x1 + 5, y1, x1 + 5, y1 + ::height + 1 )
      ENDIF
   NEXT

   RETURN Nil

METHOD ButtonDown( lParam )  CLASS HTree

   LOCAL nLine := Int( hwg_Hiword( lParam ) / ( ::height + 1 ) ) + 1
   LOCAL xm := hwg_Loword( lParam ), x1, hDC, oNode, nWidth, lRedraw := .F.

   IF nLine <= Len( ::aScreen ) .AND. !Empty( oNode := ::aScreen[ nLine ] )
      x1 := 10 + oNode:nLevel * ::nIndent
      hDC := hwg_Getdc( ::handle )
      IF !Empty( ::oFont )
         hwg_Selectobject( hDC, ::oFont:handle )
      ENDIF
      nWidth := hwg_GetTextWidth( hDC, oNode:title )
      hwg_Releasedc( ::handle, hDC )
      IF !Empty( oNode:aItems ) .AND.  xm >= x1 .AND. xm <= x1 + ::nIndent
         oNode:lExpanded := !oNode:lExpanded
         lRedraw := .T.
      ENDIF
      IF xm >= x1 .AND. xm <= x1 + ::nIndent + nWidth + 24
         ::Select( oNode, .T. )
         lRedraw := .T.
      ENDIF
      IF lRedraw
         hwg_Redrawwindow( ::area )
      ENDIF
   ENDIF

   RETURN 0

METHOD ButtonUp( lParam ) CLASS HTree

   HB_SYMBOL_UNUSED(lParam)

   RETURN 0

METHOD ButtonDbl( lParam ) CLASS HTree

   LOCAL nLine := Int( hwg_Hiword( lParam ) / ( ::height + 1 ) ) + 1
   LOCAL xm := hwg_Loword( lParam ), x1, hDC, oNode, nWidth

   IF nLine <= Len( ::aScreen ) .AND. !Empty( oNode := ::aScreen[ nLine ] )
      x1 := 10 + oNode:nLevel * ::nIndent
      hDC := hwg_Getdc( ::handle )
      IF !Empty( ::oFont )
         hwg_Selectobject( hDC, ::oFont:handle )
      ENDIF
      nWidth := hwg_GetTextWidth( hDC, oNode:title )
      hwg_Releasedc( ::handle, hDC )
      IF xm >= x1 .AND. xm <= x1 + ::nIndent + nWidth
         ::Select( oNode, .T. )
         IF ::bDblClick != Nil
            Eval( ::bDblClick, Self, oNode )
         ENDIF
         hwg_Redrawwindow( ::area )
      ENDIF
   ENDIF

   RETURN 0

METHOD ButtonRDown( lParam ) CLASS HTree

   LOCAL nLine := Int( hwg_Hiword( lParam ) / ( ::height + 1 ) ) + 1
   LOCAL xm := hwg_Loword( lParam ), x1, hDC, oNode, nWidth

   IF nLine <= Len( ::aScreen ) .AND. !Empty( oNode := ::aScreen[ nLine ] )
      x1 := 10 + oNode:nLevel * ::nIndent
      hDC := hwg_Getdc( ::handle )
      IF !Empty( ::oFont )
         hwg_Selectobject( hDC, ::oFont:handle )
      ENDIF
      nWidth := hwg_GetTextWidth( hDC, oNode:title )
      hwg_Releasedc( ::handle, hDC )
      IF xm >= x1 .AND. xm <= x1 + ::nIndent + nWidth
         ::Select( oNode, .T. )
         IF ::bRClick != Nil
            Eval( ::bRClick, Self, oNode )
         ENDIF
         hwg_Redrawwindow( ::area )
      ENDIF
   ENDIF

   RETURN 0

METHOD GoDown( n ) CLASS HTree

   IF Empty( ::aItems )
      RETURN 0
   ELSEIF Empty( ::oFirst )
      ::oFirst := ::aItems[1]
   ENDIF
   IF ::rowCurrCount < ::rowCount .OR. Empty( ::aScreen[::rowCurrCount]:NextNode() )
      RETURN 0
   ENDIF
   ::oFirst := iif( n == 1, ::oFirst:NextNode(), ::aScreen[::rowCurrCount] )
   hwg_Redrawwindow( ::area )

   RETURN 0

METHOD GoUp( n ) CLASS HTree

   IF Empty( ::aItems )
      RETURN 0
   ELSEIF Empty( ::oFirst )
      ::oFirst := ::aItems[1]
   ENDIF
   IF ::oFirst == ::aItems[1]
      RETURN 0
   ENDIF

   IF n == 1
      ::oFirst := ::oFirst:PrevNode()
   ELSE
   ENDIF
   hwg_Redrawwindow( ::area )

   RETURN 0

METHOD MouseWheel( nKeys, nDelta )  CLASS HTree

   IF Hwg_BitAnd( nKeys, MK_MBUTTON ) != 0
      IF nDelta > 0
         ::GoUp( 2 )
      ELSE
         ::GoDown( 2 )
      ENDIF
   ELSE
      IF nDelta > 0
         ::GoUp( 1 )
      ELSE
         ::GoDown( 1 )
      ENDIF
   ENDIF

   RETURN 0

METHOD DoHScroll() CLASS HTree

   RETURN 0

METHOD DoVScroll() CLASS HTree

   LOCAL nScrollV := hwg_getAdjValue( ::hScrollV )

   IF nScrollV - ::nScrollV == 1
      ::GoDown( 1 )
   ELSEIF nScrollV - ::nScrollV == - 1
      ::GoUp( 1 )
   ELSEIF nScrollV - ::nScrollV == 10
      ::GoDown( 2 )
   ELSEIF nScrollV - ::nScrollV == - 10
      ::GoUp( 2 )
   ELSE
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, SB_THUMBTRACK, .F. , nScrollV )
      ENDIF
   ENDIF
   ::nScrollV := nScrollV

   RETURN 0

METHOD End() CLASS HTree

   LOCAL j

   ::Super:END()
   IF !Empty( ::aImages )
      FOR j := 1 TO Len( ::aImages )
         IF !Empty( ::aImages[j] )
            hwg_Deleteobject( ::aImages[j] )
            ::aImages[j] := Nil
         ENDIF
      NEXT
   ENDIF
   ReleaseTree( ::aItems, .T. )
   IF ::brush != Nil
      ::brush:Release()
   ENDIF
   IF ::brushSel != Nil
      ::brushSel:Release()
   ENDIF

   RETURN Nil

STATIC PROCEDURE ReleaseTree( aItems, lDelImages )

   LOCAL i, j, iLen := Len( aItems )

   FOR i := 1 TO iLen
      IF lDelImages .AND. !Empty( aItems[i]:aImages )
         FOR j := 1 TO Len( aItems[i]:aImages )
            IF aItems[i]:aImages[j] != Nil
               hwg_Deleteobject( aItems[i]:aImages[j] )
               aItems[i]:aImages[j] := Nil
            ENDIF
         NEXT
      ENDIF
      ReleaseTree( aItems[i]:aItems, lDelImages )
   NEXT

   RETURN
