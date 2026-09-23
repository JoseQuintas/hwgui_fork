/*
 * $Id: hbrowse.prg 3852 2026-08-16 20:42:12Z itamarlins $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HBrowse class - browse databases and arrays
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTES
 * -----
 *  - This file is intentionally almost pure Harbour: all GTK interactions
 *    happen through the hwg_* C functions that have already been ported.
 *
 *  - The critical GTK4 change is *outside* this file: hwg_Getdc() must
 *    return the live cairo_t when it is called from inside a
 *    GtkDrawingArea draw_func (which is the case for HBrowse:Paint()).
 *    See draw.c for HWG_GETDC / HWG_RELEASEDC adjustments.
 *
 *  - hwg_Invalidaterect() in GTK4 ignores the rectangle and always
 *    redraws the whole widget (partial redraws were removed from GTK4).
 *    The behavioural consequence is that a scroll that used to repaint
 *    just two rows now repaints the entire browse. The visible result
 *    is the same.
 *
 *  - hwg_Redrawwindow() in GTK4 ignores the RDW_* flags.
 *
 *  - The "GTK2 SCROLL FIX" comments inherited from the previous port are
 *    still valid: the underlying issue (scrollbar allocation timing) is
 *    a property of GTK2/3/4 alike.
 */

#include "hwgui.ch"
#include "inkey.ch"
#include "dbinfo.ch"
#include "dbstruct.ch"
#include "hbclass.ch"

#ifndef WM_MOUSEWHEEL
#define WM_MOUSEWHEEL 522
#endif

#ifdef __XHARBOUR__
#xtranslate hb_tokenGet([<x>,<n>,<c>] ) =>  __StrToken(<x>,<n>,<c>)
#xtranslate hb_tokenPtr([<x>,<n>,<c>] ) =>  __StrTkPtr(<x>,<n>,<c>)
#endif

REQUEST DBGOTOP, DBGOTO, DBGOBOTTOM, DBSKIP, RECCOUNT, RECNO, EOF, BOF

/*
 * Scroll Bar Constants
 */
#ifndef SB_HORZ
#define SB_HORZ             0
#define SB_VERT             1
#define SB_CTL              2
#define SB_BOTH             3
#endif

   STATIC crossCursor := Nil
   STATIC arrowCursor := Nil
   STATIC vCursor     := Nil
   STATIC xDrag
   STATIC lInVldBrw   := .F.

CLASS HColumn INHERIT HObject

   DATA block, heading, footing, width, type
   DATA length INIT 0
   DATA dec
   DATA nJusHead, nJusLin
   DATA tcolor, bcolor, brush
   DATA oFont
   DATA lEditable  INIT .F.
   DATA lResizable INIT .T.
   DATA aList
   DATA oStyleHead
   DATA oStyleFoot
   DATA oStyleCell
   DATA oPaintCB
   DATA aBitmaps

   DATA bOnKeyDown, bValid, bWhen
   DATA bEdit
   DATA Picture

   DATA cGrid
   DATA lSpandHead INIT .F.
   DATA lSpandFoot INIT .F.

   DATA bHeadClick
   DATA bColorBlock
   METHOD New( cHeading, block, type, length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bOnKeyDOwn, bWhen, aItem, bColorBlock, bHeadClick )

ENDCLASS

METHOD New( cHeading, block, type, length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bOnKeyDOwn, bWhen, aItem, bColorBlock, bHeadClick ) CLASS HColumn

   ::heading    := iif( cHeading == Nil, "", cHeading )
   ::block      := block
   ::type       := type
   ::length     := length
   ::dec        := dec
   ::lEditable  := iif( lEditable != Nil, lEditable, .F. )
   ::nJusHead   := iif( nJusHead == Nil,  DT_LEFT , nJusHead )
   ::nJusLin    := iif( nJusLin  == Nil,  DT_LEFT , nJusLin  )
   ::picture    := cPict
   ::bOnKeyDown := bOnKeyDown
   ::bValid     := bValid
   ::bWhen      := bWhen
   IF !Empty( aItem )
      ::aList := aItem
      ::lEditable := .T.
   ENDIF
   ::bColorBlock := bColorBlock
   ::bHeadClick  := bHeadClick

   RETURN Self

CLASS HBrowse INHERIT HControl

   DATA winclass   INIT "BROWSE"
   DATA active     INIT .T.
   DATA lChanged   INIT .F.
   DATA lDispHead  INIT .T.
   DATA lDispSep   INIT .T.

   DATA lRefrLinesOnly INIT .F.
   DATA lRefrHead  INIT .T.

   DATA aColumns
   DATA nRowHeight INIT 0
   DATA nRowTextHeight
   DATA rowCount   INIT 2
   DATA rowPos     INIT 1
   DATA rowPosOld  INIT 1
   DATA rowCurrCount INIT 0
   DATA colPos     INIT 1
   DATA nColumns
   DATA nLeftCol
   DATA freeze
   DATA nRecords
   DATA nCurrent   INIT 1
   DATA aArray
   DATA recCurr    INIT 0
   DATA oStyleHead
   DATA oStyleFoot
   DATA oStyleCell
   DATA headColor
   DATA sepColor   INIT 12632256
   DATA oPenSep, oPenHdr, oPen3d
   DATA lSep3d     INIT .F.
   DATA aPadding   INIT { 4, 2, 4, 2 }
   DATA aHeadPadding   INIT { 4, 0, 4, 0 }
   DATA lInFocus   INIT .F.
   DATA varbuf
   DATA tcolorSel, bcolorSel, brushSel, htbColor, httColor
   DATA bSkip, bGoTo, bGoTop, bGoBot, bEof, bBof
   DATA bRcou, bRecno, bRecnoLog
   DATA bPosChanged, bLineOut
   DATA bScrollPos
   DATA bHScrollPos
   DATA bEnter, bKeyDown, bUpdate, bRClick
   DATA ALIAS
   DATA x1, y1, x2, y2, width, height   INIT 0
   DATA minHeight INIT 0
   DATA lEditable INIT .T.
   DATA lAppable  INIT .F.
   DATA lAppMode  INIT .F.
   DATA lAutoEdit INIT .F.
   DATA lUpdated  INIT .F.
   DATA lAppended INIT .F.
   DATA lEditing  INIT .F.
   DATA lAdjRight INIT .T.
   DATA nHeadRows INIT 1
   DATA nFootRows INIT 0
   DATA nCtrlPress INIT 0
   DATA aSelected
   DATA nPaintRow, nPaintCol

   DATA area
   DATA hScrollV  INIT Nil
   DATA hScrollH  INIT Nil
   DATA nScrollV  INIT 0
   DATA nScrollH  INIT 0
   DATA oGet, nGetRec
   DATA oEdit
   DATA lBtnDbl   INIT .F.
   DATA nCursor   INIT 0
   DATA lSetAdj   INIT .F.
   DATA nHCCharset INIT -1
   DATA cTextTitME INIT "Memo Edit"
   DATA cTextClose INIT "Close"
   DATA cTextSave  INIT "Save"
   DATA cTextMod   INIT "Memo was modified, save ?"
   DATA cTextLockRec INIT "Can't lock the record!"

   METHOD New( lType, oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, lNoBorder, ;
      lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect, bRClick )
   METHOD InitBrw( nType )
   METHOD Rebuild(hDC)
   METHOD Activate()
   METHOD Init()
   METHOD DefaultLang()
   METHOD onEvent( msg, wParam, lParam )
   METHOD AddColumn( oColumn )
   METHOD InsColumn( oColumn, nPos )
   METHOD DelColumn( nPos )
   METHOD Paint()
   METHOD LineOut(nstroka, vybfld, hDC, lSelected, lClear)
   METHOD DrawHeader( hDC, nColumn, x1, y1, x2, y2 )
   METHOD HeaderOut( hDC )
   METHOD FooterOut( hDC )
   METHOD SetColumn( nCol )
   METHOD DoHScroll( wParam )
   METHOD DoVScroll( wParam )
   METHOD LineDown( lMouse )
   METHOD LineUp(lMouse)
   METHOD PageUp(lMouse)
   METHOD PageDown(lMouse)
   METHOD Bottom( lPaint )
   METHOD Top()
   METHOD Home()  INLINE ::DoHScroll( SB_LEFT )
   METHOD ButtonDown( lParam )
   METHOD ButtonRDown( lParam )
   METHOD ButtonUp( lParam )
   METHOD ButtonDbl( lParam )
   METHOD MouseMove( wParam, lParam )
   METHOD MouseWheel()
   METHOD Edit( wParam )
   METHOD APPEND() INLINE ( ::Bottom( .F. ), ::LineDown() )
   METHOD RefreshLine()
   METHOD Refresh( lFull )
   METHOD Setfocus() INLINE hwg_SetFocus( ::area )
   METHOD Repaint()
   METHOD End()

ENDCLASS

METHOD New( lType, oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, ;
      lNoBorder, lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect, bRClick ) CLASS HBrowse

   /* GTK SCROLL FIX: Force both WS_VSCROLL and WS_HSCROLL to enable vertical
      and horizontal bars.  Behaviour is identical in GTK2/3/4. */
   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), WS_CHILD + WS_VISIBLE +  ;
      iif( lNoBorder = Nil .OR. !lNoBorder, WS_BORDER, 0 ) +            ;
      iif( lNoVScroll = Nil .OR. !lNoVScroll, WS_VSCROLL + WS_HSCROLL, WS_HSCROLL ) )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, iif( nWidth == Nil,0,nWidth ), ;
      iif( nHeight == Nil, 0, nHeight ), oFont, bInit, bSize, bPaint )

   ::type := lType
   IF oFont == Nil
      ::oFont := ::oParent:oFont
   ENDIF
   ::bEnter  := bEnter
   ::bRClick := bRClick
   ::bGetFocus   := bGFocus
   ::bLostFocus  := bLFocus

   ::lAppable    := iif( lAppend == Nil, .F. , lAppend )
   ::lAutoEdit   := iif( lAutoedit == Nil, .F. , lAutoedit )
   ::bUpdate     := bUpdate
   ::bKeyDown    := bKeyDown
   ::bPosChanged := bPosChg
   IF lMultiSelect != Nil .AND. lMultiSelect
      ::aSelected := {}
   ENDIF

   ::tcolor := 0
   ::bcolor := hwg_ColorC2N( "FFFFFF" )
   ::tcolorSel := ::httColor := hwg_ColorC2N( "FFFFFF" )
   ::bcolorSel := hwg_ColorC2N( "808080" )
   ::htbColor := 2896388

   ::InitBrw()
   ::Activate()

   RETURN Self


METHOD DefaultLang() CLASS HBrowse

   ::cTextTitME := "Memo Edit"
   ::cTextClose := "Close"
   ::cTextSave  := "Save"
   ::cTextMod   := "Memo was modified, save ?"
   ::cTextLockRec := "Can't lock the record!"

   RETURN Self

METHOD Activate() CLASS HBrowse

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createbrowse( Self )
      ::Init()
   ENDIF

   RETURN Self

/* Event handler */
METHOD onEvent( msg, wParam, lParam )  CLASS HBrowse

   LOCAL aCoors, retValue := - 1

   IF ::active .AND. !Empty( ::aColumns )

      IF ::bOther != NIL
         IF ValType( retValue := Eval( ::bOther, Self, msg, wParam, lParam ) ) != "N"
            retValue := Iif( ValType( retValue ) = "L" .AND. ! retValue, 0, - 1 )
         ENDIF
         IF retValue >= 0
            RETURN - 1
         ENDIF
      ENDIF

      IF msg == WM_PAINT
         ::Paint()
         /*
          * GTK4 note: cb_event returns this value straight to the
          * GtkDrawingArea draw_func caller.  0 == "keep going",
          * nonzero == "stop signal chain".  Returning 0 is correct.
          */
         retValue := 0

      ELSEIF msg == WM_ERASEBKGND
         IF ::brush != Nil
            aCoors := hwg_Getclientrect( ::handle )
            hwg_Fillrect( wParam, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, ::brush:handle )
            retValue := 0
         ENDIF

      ELSEIF msg == WM_SETFOCUS
         IF ::bGetFocus != Nil
            Eval( ::bGetFocus, Self )
         ENDIF

      ELSEIF msg == WM_KILLFOCUS
         IF ::bLostFocus != Nil
            Eval( ::bLostFocus, Self )
         ENDIF

      ELSEIF msg == WM_DESTROY
         ::End()

      ELSEIF msg == WM_COMMAND
         hwg_DlgCommand( Self, wParam, lParam )

      ELSEIF ::oGet == Nil

         IF msg == WM_HSCROLL
            ::DoHScroll()
            retValue := 0

         ELSEIF msg == WM_VSCROLL
            ::DoVScroll( wParam )
            retValue := 0

         ELSEIF msg == WM_MOUSEWHEEL
            IF wParam > 0
               ::LineUp()
            ELSE
               ::LineDown()
            ENDIF
            ::MouseWheel()
            retValue := 0

         ELSEIF msg == WM_KEYUP
            IF wParam == GDK_Control_L .OR. wParam == GDK_Control_R
               IF wParam == ::nCtrlPress
                  ::nCtrlPress := 0
               ENDIF
            ENDIF
            retValue := 1

         ELSEIF msg == WM_KEYDOWN //256

            IF ::bKeyDown != Nil
               IF !Eval( ::bKeyDown, Self, wParam )
                  RETURN 1
               ENDIF
            ENDIF

            IF wParam == GDK_Down
               ::LINEDOWN()
            ELSEIF wParam == GDK_Up
               ::LINEUP()
            ELSEIF wParam == GDK_Right
               LineRight( Self )
            ELSEIF wParam == GDK_Left
               LineLeft( Self )
            ELSEIF wParam == GDK_Home
               ::DoHScroll( SB_LEFT )
            ELSEIF wParam == GDK_End
               ::DoHScroll( SB_RIGHT )
            ELSEIF wParam == GDK_Page_Down
               IF ::nCtrlPress != 0
                  ::BOTTOM()
               ELSE
                  ::PageDown()
               ENDIF
            ELSEIF wParam == GDK_Page_Up
               IF ::nCtrlPress != 0
                  ::TOP()
               ELSE
                  ::PageUp()
               ENDIF
            ELSEIF wParam == GDK_Return .OR. wParam == GDK_KP_Enter
               ::Edit()
            ELSEIF wParam == GDK_Control_L .OR. wParam == GDK_Control_R
               IF ::nCtrlPress == 0
                  ::nCtrlPress := wParam
               ENDIF
            ELSEIF ::lAutoEdit .AND. wParam >= 33 .AND. wParam <= 126
               ::Edit( wParam )
            ENDIF
            retValue := 1

         ELSEIF msg == WM_LBUTTONDOWN
            ::ButtonDown( lParam )
            retValue := -1

         ELSEIF msg == WM_LBUTTONUP
            ::ButtonUp( lParam )
            retValue := -1

         ELSEIF msg == WM_LBUTTONDBLCLK
            ::ButtonDbl( lParam )
            retValue := -1

         ELSEIF msg == WM_RBUTTONDOWN
            ::ButtonRDown( lParam )
            retValue := -1

         ELSEIF msg == WM_MOUSEMOVE
            ::MouseMove( wParam, lParam )
            retValue := -1
         ENDIF

         IF msg == WM_KEYDOWN .and. wParam == GDK_Up .or. wParam == GDK_Down
            ::MouseWheel()
         ENDIF
      ENDIF
   ENDIF

   RETURN retValue


METHOD Init() CLASS HBrowse

   IF !::lInit
      ::Super:Init()

      /*
       * GTK SCROLL POINTER BRIDGE: Force the original class pointers
       * (hScrollV/hScrollH) to safely inherit the active dynamic adjustment
       * instances created by control.c (_HSCROLLV/_HSCROLLH).
       * Same pattern in GTK2/3/4.
       */
      IF __ObjHasMsg( Self, "_HSCROLLV" ) .AND. ::_HSCROLLV != Nil
         ::hScrollV := ::_HSCROLLV
      ENDIF

      IF __ObjHasMsg( Self, "_HSCROLLH" ) .AND. ::_HSCROLLH != Nil
         ::hScrollH := ::_HSCROLLH
      ENDIF

      IF ::handle != Nil
         ::Show()

         IF ::area != Nil
            hwg_RedrawWindow( ::area )
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

METHOD AddColumn( oColumn ) CLASS HBrowse

   LOCAL n, arr

   IF ValType( oColumn ) == "A"
      arr := oColumn
      n := Len( arr )
      oColumn := HColumn():New( iif( n > 0,arr[1],Nil ), iif( n > 1,arr[2],Nil ), ;
         iif( n > 2, arr[3], Nil ), iif( n > 3, arr[4], Nil ), iif( n > 4, arr[5], Nil ), iif( n > 5, arr[6], Nil ) )
   ENDIF
   AAdd( ::aColumns, oColumn )
   ::lChanged := .T.
   InitColumn( Self, oColumn, Len( ::aColumns ) )

   RETURN oColumn

METHOD InsColumn( oColumn, nPos ) CLASS HBrowse

   AAdd( ::aColumns, Nil )
   AIns( ::aColumns, nPos )
   ::aColumns[ nPos ] := oColumn
   ::lChanged := .T.
   InitColumn( Self, oColumn, nPos )

   RETURN oColumn

STATIC FUNCTION InitColumn( oBrw, oColumn, n )

   IF oColumn:type == Nil
      oColumn:type := ValType( Eval( oColumn:block,,oBrw,n ) )
   ENDIF
   IF oColumn:dec == Nil
      IF oColumn:type == "N" .AND. At( '.', Str( Eval( oColumn:block,,oBrw,n ) ) ) != 0
         oColumn:dec := Len( SubStr( Str( Eval( oColumn:block,,oBrw,n ) ), ;
            At( '.', Str( Eval( oColumn:block,,oBrw,n ) ) ) + 1 ) )
      ELSE
         oColumn:dec := 0
      ENDIF
   ENDIF
   IF oColumn:length == Nil
      IF oColumn:picture != Nil
         oColumn:length := Len( Transform( Eval( oColumn:block,,oBrw,n ), oColumn:picture ) )
      ELSE
         oColumn:length := 10
      ENDIF
      oColumn:length := Max( oColumn:length, Len( oColumn:heading ) )
   ENDIF
   IF oColumn:type == "D"
     IF hwg_getCentury()
      oColumn:length := Max(oColumn:length,12)
     ELSE
      oColumn:length := Max(oColumn:length,10)
     ENDIF
   ENDIF

   RETURN Nil

METHOD DelColumn( nPos ) CLASS HBrowse

   ADel( ::aColumns, nPos )
   ASize( ::aColumns, Len( ::aColumns ) - 1 )
   ::lChanged := .T.

   RETURN Nil

METHOD End() CLASS HBrowse

   hwg_ReleaseObject( ::area )
   IF ::hScrollV != Nil
      hwg_ReleaseObject( ::hScrollV )
   ENDIF
   IF ::hScrollH != Nil
      hwg_ReleaseObject( ::hScrollH )
   ENDIF

   ::Super:End()
   IF ::brush != Nil
      ::brush:Release()
      ::brush := Nil
   ENDIF
   IF ::brushSel != Nil
      ::brushSel:Release()
      ::brushSel := Nil
   ENDIF

   RETURN Nil

METHOD InitBrw( nType )  CLASS HBrowse

   IF nType != Nil
      ::type := nType
   ELSE
      ::aColumns := {}
      ::nRecords := 0
      ::nLeftCol := 1
      ::lRefrLinesOnly := .F.
      ::lRefrHead := .T.
      ::aArray   := Nil
      ::freeze := ::height := 0

      /*
       * GTK4: cursor creation via gdk_cursor_new_from_name() in control.c.
       * The legacy GDK_* numeric constants are mapped to CSS cursor names
       * inside HWG_LOADCURSOR.
       */
      IF Empty( crossCursor )
         crossCursor := hwg_Loadcursor( GDK_CROSS )
         arrowCursor := hwg_Loadcursor( GDK_LEFT_PTR )
         vCursor := hwg_Loadcursor( GDK_SB_V_DOUBLE_ARROW )
      ENDIF
   ENDIF
   ::rowPos := ::rowPosOld := ::nCurrent := ::colpos := 1

   IF ::type == BRW_DATABASE
      ::alias   := Alias()
      ::bSkip     :=  { |o, n| HB_SYMBOL_UNUSED( o ) , ( ::alias ) -> ( dbSkip( n ) ) }
      ::bGoTop    :=  { || ( ::alias ) -> ( DBGOTOP() ) }
      ::bGoBot    :=  { || ( ::alias ) -> ( dbGoBottom() ) }
      ::bEof      :=  { || ( ::alias ) -> ( Eof() ) }
      ::bBof      :=  { || ( ::alias ) -> ( Bof() ) }
      ::bRcou     :=  { || ( ::alias ) -> ( RecCount() ) }
      ::bRecnoLog := ::bRecno  := { ||( ::alias ) -> ( RecNo() ) }
      ::bGoTo     :=  { |o, n| HB_SYMBOL_UNUSED( o ) , ( ::alias ) -> ( dbGoto( n ) ) }
      ::bScrollPos := { |o, n, lEof, nPos| hwg_VScrollPos( o, n, lEof, nPos ) }

   ELSEIF ::type == BRW_ARRAY
      ::bSKip   := { | o, x | ARSKIP( o, x ) }
      ::bGoTop  := { | o | o:nCurrent := 1 }
      ::bGoBot  := { | o | o:nCurrent := o:nRecords }
      ::bEof    := { | o | o:nCurrent > o:nRecords }
      ::bBof    := { | o | o:nCurrent == 0 }
      ::bRcou   := { | o | Len( o:aArray ) }
      ::bRecnoLog := ::bRecno  := { | o | o:nCurrent }
      ::bGoTo   := { | o, n | o:nCurrent := n }
      ::bScrollPos := { |o, n, lEof, nPos|hwg_VScrollPos( o, n, lEof, nPos ) }

   ENDIF

   RETURN Nil

METHOD Rebuild( hDC ) CLASS HBrowse

   LOCAL i, j, oColumn, xSize, nColLen, nHdrLen, nCount, arr
   LOCAL nPadLeft, nPadRight

   IF ::oPenSep == Nil
      ::oPenSep := HPen():Add( PS_SOLID, 1, ::sepColor )
   ENDIF
   IF ::oPen3d == Nil
      ::oPen3d := HPen():Add( PS_SOLID, 1, hwg_Getsyscolor( COLOR_3DHILIGHT ) )
   ENDIF
   IF ::oPenHdr == Nil
      ::oPenHdr := HPen():Add( BS_SOLID, 1, 0 )
   ENDIF
   IF ::brush != Nil
      ::brush:Release()
   ENDIF
   IF ::brushSel != Nil
      ::brushSel:Release()
   ENDIF
   IF ::bcolor != Nil
      ::brush := HBrush():Add( ::bcolor )
   ENDIF
   IF ::bcolorSel != Nil
      ::brushSel  := HBrush():Add( ::bcolorSel )
   ENDIF
   ::nLeftCol  := ::freeze + 1
   ::lEditable := .F.
   ::minHeight := ::nRowTextHeight := ::width := 0

   FOR i := 1 TO Len( ::aColumns )

      oColumn := ::aColumns[i]

      IF oColumn:lEditable
         ::lEditable := .T.
      ENDIF

      IF oColumn:oFont != Nil
         hwg_Selectobject( hDC, oColumn:oFont:handle )
      ELSEIF ::oFont != Nil
         hwg_Selectobject( hDC, ::oFont:handle )
      ENDIF
      arr := hwg_GetTextMetric( hDC )
      ::nRowTextHeight := Max( ::nRowTextHeight, arr[1] )
      ::width := Max( ::width, Round( hwg_GetTextWidth( hDC, "abcdefghijklmnopqrstuvwxyz" ) / 26, 0 ) )

      nColLen := oColumn:length
      IF oColumn:heading != Nil
         oColumn:heading := CountToken( oColumn:heading, @nHdrLen, @nCount )
         IF ! oColumn:lSpandHead
            nColLen := Max( nColLen, nHdrLen )
         ENDIF
         ::nHeadRows := Max( ::nHeadRows, nCount )
      ENDIF
      IF oColumn:footing != Nil
         oColumn:footing := CountToken( oColumn:footing, @nHdrLen, @nCount )
         IF ! oColumn:lSpandFoot
            nColLen := Max( nColLen, nHdrLen )
         ENDIF
         ::nFootRows := Max( ::nFootRows, nCount )
      ENDIF

      IF oColumn:aBitmaps != Nil
         xSize := 0
         FOR j := 1 TO Len( oColumn:aBitmaps )
            IF ValType( oColumn:aBitmaps[j,2] ) == "O"
               xSize := Max( xSize, oColumn:aBitmaps[j,2]:nWidth + 2 )
               ::minHeight := Max( ::minHeight, oColumn:aBitmaps[j,2]:nHeight )
            ENDIF
         NEXT
      ELSE
         IF oColumn:type == Nil .AND. oColumn:block != Nil
            oColumn:type := ValType( Eval( oColumn:block,, Self, i ) )
         ENDIF
         xSize := Round( nColLen * ::width, 0 )
      ENDIF

      IF oColumn:length < 0
         oColumn:width := Abs( oColumn:length )
      ELSE
         IF oColumn:type == "D"
            oColumn:width := xSize - 6
         ELSE
            IF oColumn:length > 2
               nPadLeft  := Iif( ::aPadding[1] == Nil .OR. ::aPadding[1] < 4, 4, ::aPadding[1] )
               nPadRight := Iif( ::aPadding[3] == Nil .OR. ::aPadding[3] < 14, 14, ::aPadding[3] )
               oColumn:width := xSize + nPadLeft + nPadRight
            ELSE
               oColumn:width := xSize + ::aPadding[1] + ::aPadding[3]
            ENDIF
         ENDIF
      ENDIF

   NEXT

   ::lChanged := .F.

   IF ::handle != Nil
      /* GTK GEOMETRY FIX: skip hwg_Showall to avoid collapsing scrollbars. */
      hwg_RedrawWindow( ::handle )
   ENDIF

   RETURN Nil


METHOD Paint()  CLASS HBrowse

   LOCAL aCoors, i, l, tmp, nRows
   LOCAL hDC
   LOCAL nOrigRec

   IF !::active .OR. Empty( ::aColumns )
      RETURN Nil
   ENDIF

   /*
    * GTK4: hwg_Getdc() detects that we are inside the ::area draw_func and
    * returns the live cairo_t instead of an offscreen surface.
    */
   hDC := hwg_Getdc( ::area )

   IF ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
   ENDIF
   IF ::brush == Nil .OR. ::lChanged
      ::Rebuild( hDC )
   ENDIF
   IF ::oPenSep:color != ::sepColor
      ::oPenSep:Release()
      ::oPenSep := HPen():Add( PS_SOLID, 1, ::sepColor )
   ENDIF
   aCoors := hwg_Getclientrect( ::handle )

   IF hwg_BitAnd( ::style, WS_BORDER ) != 0
      hwg_gtk_drawedge( hDC, aCoors[1], aCoors[2], aCoors[3] - 1, aCoors[4] - 1, 6 )
      i := 1
   ELSE
      i := 0
   ENDIF

   ::height := iif( ::nRowHeight>0, ::nRowHeight, ;
         Max( ::nRowTextHeight, ::minHeight ) + 1 + ::aPadding[2] + ::aPadding[4] )
   ::x1 := aCoors[ 1 ] + i
   ::y1 := aCoors[ 2 ] + iif( ::lDispHead, ::nRowTextHeight * ::nHeadRows + ::aHeadPadding[2] + ::aHeadPadding[4], 0 ) + i
   ::x2 := aCoors[ 3 ] - i
   ::y2 := aCoors[ 4 ] - i
   ::nRecords := Eval( ::bRcou, Self )
   IF ::nCurrent > ::nRecords .AND. ::nRecords > 0
      ::nCurrent := ::nRecords
   ENDIF

   ::nColumns := FldCount( Self, ::x1 + 2, ::x2 - 2, ::nLeftCol )
   ::rowCount := Int( ( ::y2 - ::y1 ) / ( ::height + 1 ) ) - ::nFootRows
   nRows := Min( ::nRecords, ::rowCount )

   /* GTK Fix: align viewport to bottom row on init if DB is at EOF */
   IF ::rowCount > 0 .AND. ::rowPos < ::rowCount
      IF ::type == BRW_DATABASE .AND. !Empty( ::alias )
         nOrigRec := ( ::alias )->( RecNo() )
         ( ::alias )->( DbSkip( 1 ) )
         IF ( ::alias )->( Eof() )
            ::rowPos := nRows
            ::lRefrLinesOnly := .F.
         ENDIF
         ( ::alias )->( DbGoto( nOrigRec ) )
      ENDIF
   ENDIF

   /* GTK SCROLL FIX: read dynamic adjustment properties set by control.c */
   IF __ObjHasMsg( Self, "_HSCROLLV" ) .AND. ::_HSCROLLV != Nil
      tmp := Iif( ::nRecords < 100, ::nRecords, 100 )
      i := Iif( ::nRecords < 100, 1, ::nRecords/100 )
      IF hwg_SetAdjOptions( ::_HSCROLLV, , tmp + nRows, i, nRows, nRows )
         ::lSetAdj := .T.
      ENDIF
   ENDIF

   IF __ObjHasMsg( Self, "_HSCROLLH" ) .AND. ::_HSCROLLH != Nil
      tmp := Len( ::aColumns )
      hwg_SetAdjOptions( ::_HSCROLLH, , tmp + 1, 1, 1, 1 )
   ENDIF

   IF ::lRefrLinesOnly
      IF ::rowPos != ::rowPosOld .AND. !::lAppMode
         Eval( ::bSkip, Self, ::rowPosOld - ::rowPos )
         IF ::aSelected != Nil .AND. Ascan( ::aSelected, { |x| x == Eval( ::bRecno,Self ) } ) > 0
            ::LineOut( ::rowPosOld, 0, hDC, .T. )
         ELSE
            ::LineOut( ::rowPosOld, 0, hDC, .F. )
         ENDIF
         Eval( ::bSkip, Self, ::rowPos - ::rowPosOld )
      ENDIF
   ELSE
      /* GTK Fix: only force top positioning if the DB is genuinely empty */
      IF ( Eval( ::bEof, Self ) .OR. Eval( ::bBof, Self ) ) .AND. ::nRecords == 0
         Eval( ::bGoTop, Self )
         ::rowPos := 1
      ENDIF
      IF ::rowPos > nRows .AND. nRows > 0
         ::rowPos := nRows
      ENDIF
      tmp := Eval( ::bRecno, Self )
      IF ::rowPos > 1
         Eval( ::bSkip, Self, - ( ::rowPos - 1 ) )
      ENDIF
      i := 1
      l := .F.
      DO WHILE .T.
         IF Eval( ::bRecno, Self ) == tmp
            ::rowPos := i
            l := .T.
         ENDIF
         IF i > nRows .OR. Eval( ::bEof, Self )
            EXIT
         ENDIF
         IF l
            l := .F.
         ELSE
            IF ::aSelected != Nil .AND. Ascan( ::aSelected, { |x| x == Eval( ::bRecno,Self ) } ) > 0
               ::LineOut( i, 0, hDC, .T. )
            ELSE
               ::LineOut( i, 0, hDC, .F. )
            ENDIF
         ENDIF
         i ++
         Eval( ::bSkip, Self, 1 )
      ENDDO
      ::rowCurrCount := i - 1

      IF ::rowPos >= i
         ::rowPos := iif( i > 1, i - 1, 1 )
      ENDIF
      DO WHILE i <= nRows
         ::LineOut( i, 0, hDC, .F. , .T. )
         i ++
      ENDDO

      Eval( ::bGoTo, Self, tmp )

      hwg_Fillrect( hDC, ::x1, ::y1 + ( ::height + 1 ) * nRows, ;
         ::x2, ::y2, ::brush:handle )
   ENDIF

   IF ::lAppMode
      ::LineOut( nRows + 1, 0, hDC, .F. , .T. )
   ENDIF

   ::LineOut( ::rowPos, ::colpos, hDC, .T. )

   IF ::lRefrHead .OR. ::lAppMode .OR. ::lDispHead
      ::HeaderOut( hDC )
      IF ::nFootRows > 0
         ::FooterOut( hDC )
      ENDIF
   ENDIF

   hwg_Releasedc( ::area, hDC )
   ::lRefrHead := .T.
   ::lRefrLinesOnly := .F.
   ::rowPosOld := ::rowPos
   tmp := Eval( ::bRecno, Self )
   IF ::recCurr != tmp
      ::recCurr := tmp
      IF ::bPosChanged != Nil
         Eval( ::bPosChanged, Self, ::nCurrent )
      ENDIF
   ENDIF

   IF ::lAppMode
      ::Edit()
   ENDIF

   ::lAppMode := .F.

   RETURN Nil


METHOD DrawHeader( hDC, nColumn, x1, y1, x2, y2 ) CLASS HBrowse

   LOCAL cStr, oColumn := ::aColumns[nColumn], cNWSE, nLine, ya, yb
   LOCAL nHeight := ::nRowTextHeight, oCB := oColumn:oPaintCB, aCB, block, i

   IF !Empty( oCB ) .AND. !Empty( block := oCB:Get( PAINT_HEAD_ALL ) )
      RETURN Eval( block, oColumn, hDC, x1, y1, x2, y2, nColumn )
   ENDIF

   IF !Empty( oCB ) .AND. !Empty( block := oCB:Get( PAINT_HEAD_BACK ) )
      Eval( block, oColumn, hDC, x1, y1, x2, y2, nColumn )
   ELSEIF oColumn:oStyleHead != Nil
      oColumn:oStyleHead:Draw( hDC, x1, y1, x2, y2 )
   ELSEIF ::oStyleHead != Nil
      ::oStyleHead:Draw( hDC, x1, y1, x2, y2 )
   ELSE
      hwg_Drawbutton( hDC, x1, y1, x2, y2, iif( oColumn:cGrid == Nil, 5, 0 ) )
   ENDIF

   IF oColumn:cGrid != Nil
      hwg_Selectobject( hDC, ::oPenHdr:handle )
      cStr := oColumn:cGrid + ';'
      FOR nLine := 1 TO ::nHeadRows
         cNWSE := hb_tokenGet( @cStr, nLine, ';' )
         ya := y1 + nHeight * nLine + ::aHeadPadding[2] + iif( nLine == ::nHeadRows, ::aHeadPadding[4], 0 )
         yb := y1 + nHeight * ( nLine - 1 ) + iif( nLine == 1, 0, ::aHeadPadding[2] )
         IF At( 'S', cNWSE ) != 0
            hwg_Drawline( hDC, x1, ya, x2, ya )
         ENDIF
         IF At( 'N', cNWSE ) != 0
            hwg_Drawline( hDC, x1, yb, x2, yb )
         ENDIF
         IF At( 'E', cNWSE ) != 0
            hwg_Drawline( hDC, x2 - 1, yb + 1, x2 - 1, ya )
         ENDIF
         IF At( 'W', cNWSE ) != 0
            hwg_Drawline( hDC, x1, yb + 1, x1, ya )
         ENDIF
      NEXT
   ENDIF

   IF ValType( oColumn:heading ) == "C"
      hwg_Drawtext( hDC, oColumn:heading, x1 + 1 + ::aHeadPadding[1],    ;
         y1 + 1 + ::aHeadPadding[2], x2 + 1 + ::aHeadPadding[3], ;
         y1 + nHeight + ::aHeadPadding[2], oColumn:nJusHead )
   ELSE
      FOR nLine := 1 TO Len( oColumn:heading )
         IF !Empty( oColumn:heading[nLine] )
            hwg_Drawtext( hDC, oColumn:heading[nLine], x1 + 1 + ::aHeadPadding[1], ;
               y1 + nHeight * ( nLine - 1 ) + 1 + ::aHeadPadding[2], x2 - ::aHeadPadding[3], ;
               y1 + nHeight * nLine + ::aHeadPadding[2], ;
               oColumn:nJusHead  + iif( oColumn:lSpandHead, DT_NOCLIP, 0 ) )
         ENDIF
      NEXT
   ENDIF

   IF !Empty( oCB ) .AND. !Empty( aCB := oCB:Get( PAINT_HEAD_ITEM ) )
      FOR i := 1 TO Len( aCB )
         Eval( aCB[i], oColumn, hDC, x1, y1, x2, y2, nColumn )
      NEXT
   ENDIF

   RETURN Nil

METHOD HeaderOut( hDC ) CLASS HBrowse

   LOCAL i, x, y1, oldc, fif, xSize
   LOCAL nRows := ::rowCurrCount

   IF ::lDispSep
      hwg_Selectobject( hDC, ::oPenSep:handle )
   ENDIF

   x := ::x1
   y1 := ::y1 - ::nRowTextHeight * ::nHeadRows - ::aHeadPadding[2] - ::aHeadPadding[4]
   IF ::headColor != Nil
      oldc := hwg_Settextcolor( hDC, ::headColor )
   ENDIF
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE x < ::x2 - 2
      xSize := ::aColumns[fif]:width
      IF ::lAdjRight .AND. fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      ENDIF
      IF ::lDispHead
         ::DrawHeader( hDC, fif, x - 1, y1, x + xSize - 1, ::y1 + 1 )
      ENDIF
      hwg_Selectobject( hDC, ::oPenSep:handle )
      IF ::lDispSep .AND. x > ::x1
         IF ::lSep3d
            hwg_Selectobject( hDC, ::oPen3d:handle )
            hwg_Drawline( hDC, x - 1, ::y1 + 1, x - 1, ::y1 + ( ::height + 1 ) * nRows )
            hwg_Selectobject( hDC, ::oPenSep:handle )
            hwg_Drawline( hDC, x - 2, ::y1 + 1, x - 2, ::y1 + ( ::height + 1 ) * nRows )
         ELSE
            hwg_Drawline( hDC, x - 1, ::y1 + 1, x - 1, ::y1 + ( ::height + 1 ) * nRows )
         ENDIF
      ENDIF
      x += xSize
      IF ! ::lAdjRight .AND. fif == Len( ::aColumns )
         hwg_Drawline( hDC, x - 1, y1, x - 1, ::y1 + ( ::height + 1 ) * nRows )
      ENDIF
      fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         EXIT
      ENDIF
   ENDDO

   IF ::lDispSep
      FOR i := 1 TO nRows
         hwg_Drawline( hDC, ::x1, ::y1 + ( ::height + 1 ) * i, iif( ::lAdjRight, ::x2, x ), ::y1 + ( ::height + 1 ) * i )
      NEXT
   ENDIF
   IF ::headColor != Nil
      hwg_Settextcolor( hDC, oldc )
   ENDIF

   RETURN Nil

METHOD FooterOut( hDC ) CLASS HBrowse

   LOCAL i, x, x2, y1, y2, fif, xSize, nLine
   LOCAL oColumn, oCB, aCB, block

   IF ::lDispSep
      hwg_Selectobject( hDC, ::oPenSep:handle )
   ENDIF

   x := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   y1 := ::y2 - ::height
   y2 := ::y2
   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[fif]
      xSize := oColumn:width
      IF ::lAdjRight .AND. fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      ENDIF
      x2 := x + xSize - 1
      oCB := oColumn:oPaintCB
      IF !Empty( oCB ) .AND. !Empty( block := oCB:Get( PAINT_FOOT_ALL ) )
         RETURN Eval( block, oColumn, hDC, x, y1, x2, y2, fif )
      ELSE
         IF !Empty( oCB ) .AND. !Empty( block := oCB:Get( PAINT_FOOT_BACK ) )
            Eval( block, oColumn, hDC, x, y1, x2, y2, fif )
         ELSEIF oColumn:oStyleFoot != Nil
            oColumn:oStyleFoot:Draw( hDC, x, y1, x2, y2 )
         ELSEIF ::oStyleFoot != Nil
            ::oStyleFoot:Draw( hDC, x, y1, x2, y2 )
         ELSE
            hwg_Drawbutton( hDC, x, y1, x2, y2, 5 )
         ENDIF

         IF oColumn:footing != Nil
            hwg_Settransparentmode( hDC, .T. )
            IF ValType( oColumn:footing ) == "C"
               hwg_Drawtext( hDC, oColumn:footing, ;
                  x + ::aHeadPadding[1], y1 + ::aHeadPadding[2], ;
                  x2 - ::aHeadPadding[3], y2 - ::aHeadPadding[4], oColumn:nJusLin + iif( oColumn:lSpandFoot, DT_NOCLIP, 0 ) )
            ELSE
               FOR nLine := 1 TO Len( oColumn:footing )
                  IF !Empty( oColumn:footing[nLine] )
                     hwg_Drawtext( hDC, oColumn:footing[nLine], ;
                        x + ::aHeadPadding[1], y1 + ( nLine - 1 ) * ( ::height + 1 ) + 1, ;
                        x2 - ::aHeadPadding[3], ::y1 + nLine * ( ::height + 1 ), ;
                        oColumn:nJusLin + iif( oColumn:lSpandFoot, DT_NOCLIP, 0 ) )
                  ENDIF
               NEXT
            ENDIF
            hwg_Settransparentmode( hDC, .F. )
         ENDIF
         IF !Empty( oCB ) .AND. !Empty( aCB := oCB:Get( PAINT_FOOT_ITEM ) )
            FOR i := 1 TO Len( aCB )
               Eval( aCB[i], oColumn, hDC, x, y1, x2, y2, fif )
            NEXT
         ENDIF
      ENDIF
      hwg_Selectobject( hDC, ::oPenSep:handle )
      IF ::lDispSep .AND. x > ::x1
         IF ::lSep3d
            hwg_Selectobject( hDC, ::oPen3d:handle )
            hwg_Drawline( hDC, x - 1, y1+1, x - 1, y2-1 )
            hwg_Selectobject( hDC, ::oPenSep:handle )
            hwg_Drawline( hDC, x - 2, y1 + 1, x - 2, y2 - 1 )
         ELSE
            hwg_Drawline( hDC, x - 1, y1 + 1, x - 1, y2 - 1 )
         ENDIF
      ENDIF
      x += xSize
      fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         EXIT
      ENDIF
   ENDDO

   IF ::lDispSep
      hwg_Drawline( hDC, ::x1, y1, iif( ::lAdjRight, ::x2, x ), y1 )
   ENDIF

   RETURN Nil

METHOD LineOut( nstroka, vybfld, hDC, lSelected, lClear ) CLASS HBrowse

   LOCAL x, x2, y1, y2, i := 1, sviv, xSize, nCol
   LOCAL j, ob, bw, bh, hBReal
   LOCAL oldBkColor, oldTColor
   LOCAL oBrushLine := iif( lSelected, ::brushSel, ::brush )
   LOCAL oBrushSele := iif( vybfld >= 1, HBrush():Add( ::htbColor ), Nil )
   LOCAL lColumnFont := .F.
   LOCAL aCores, oColumn, oCB, aCB, block

   x := ::x1
   IF lClear == Nil ; lClear := .F. ; ENDIF

   IF ::bLineOut != Nil
      Eval( ::bLineOut, Self, lSelected )
   ENDIF
   IF ::nRecords > 0
      oldBkColor := hwg_Setbkcolor( hDC, iif( lSelected,::bcolorSel,::bcolor ) )
      oldTColor  := hwg_Settextcolor( hDC, iif( lSelected,::tcolorSel,::tcolor ) )
      nCol := ::nPaintCol := iif( ::freeze > 0, 1, ::nLeftCol )
      ::nPaintRow := nstroka

      WHILE x < ::x2 - 2
         oColumn := ::aColumns[nCol]
         IF oColumn:bColorBlock != Nil
            aCores := Eval( oColumn:bColorBlock, Self, nstroka, nCol )
            IF lSelected
               oColumn:tColor := iif( vybfld == i .AND. Len( aCores ) >= 5 .AND. aCores[5] != Nil, aCores[5], aCores[3] )
               oColumn:bColor := iif( vybfld == i .AND. Len( aCores ) >= 6 .AND. aCores[6] != Nil, aCores[6], aCores[4] )
            ELSE
               oColumn:tColor := aCores[1]
               oColumn:bColor := aCores[2]
            ENDIF
            oColumn:brush := HBrush():Add( oColumn:bColor   )
         ENDIF
         IF oColumn:bColor != Nil .AND. oColumn:brush == Nil
            oColumn:brush := HBrush():Add( oColumn:bColor )
         ENDIF

         xSize := oColumn:width
         IF ::lAdjRight .AND. nCol == Len( ::aColumns )
            xSize := Max( ::x2 - x, xSize )
         ENDIF

         oCB := oColumn:oPaintCB
         x2 := x + xSize - iif( ::lSep3d, 2, 1 )
         y1 := ::y1 + ( ::height + 1 ) * ( nstroka - 1 ) + 1
         y2 := ::y1 + ( ::height + 1 ) * nstroka
         IF !Empty( oCB ) .AND. !Empty( block := oCB:Get( PAINT_LINE_ALL ) )
            Eval( block, oColumn, hDC, x, y1, x2, y2, nCol )
         ELSE
            IF !Empty( oCB ) .AND. !Empty( block := oCB:Get( PAINT_LINE_BACK ) )
               Eval( block, oColumn, hDC, x, y1, x2, y2, nCol )
            ELSEIF oColumn:oStyleCell != Nil
               oColumn:oStyleCell:Draw( hDC, x, y1, x2, y2 )
            ELSEIF ::oStyleCell != Nil
               ::oStyleCell:Draw( hDC, x, y1, x2, y2 )
            ELSE
               hBReal := iif( oColumn:brush != Nil, ;
                  oColumn:brush:handle, iif( vybfld == i, oBrushSele, oBrushLine ):handle )
               hwg_Fillrect( hDC, x, y1, x2, y2, hBReal )
            ENDIF
            IF !lClear
               IF oColumn:aBitmaps != Nil .AND. !Empty( oColumn:aBitmaps )
                  FOR j := 1 TO Len( oColumn:aBitmaps )
                     IF Eval( oColumn:aBitmaps[j,1], Eval( oColumn:block,,Self,nCol ), lSelected )
                        IF !Empty( ob := oColumn:aBitmaps[j,2] )
                           IF ob:nHeight > ::height
                              bh := ::height
                              bw := Int( ob:nWidth * ( ob:nHeight / ::height ) )
                              hwg_Drawbitmap( hDC, ob:handle, , x + ::aPadding[1], y1 + ::aPadding[2], bw, bh )
                           ELSE
                               hwg_Drawtransparentbitmap( hDC, ob:handle, x + ::aPadding[1], ;
                                  Int( ( ::height - ob:nHeight )/2 ) + y1 + ::aPadding[2] )
                           ENDIF
                        ENDIF
                        EXIT
                     ENDIF
                  NEXT
               ELSE
                  hwg_Settextcolor( hDC, ;
                     iif( oColumn:tColor != Nil, oColumn:tColor, ;
                     iif( vybfld == i, ::httcolor, iif( lSelected,::tcolorSel,::tcolor ) ) ) )
                  hwg_Setbkcolor( hDC, ;
                     iif( oColumn:bColor != Nil, oColumn:bColor, ;
                     iif( vybfld == i, ::htbcolor, iif( lSelected,::bcolorSel,::bcolor ) ) ) )

                  IF oColumn:oFont != Nil
                     hwg_Selectobject( hDC, oColumn:oFont:handle )
                     lColumnFont := .T.
                  ELSEIF lColumnFont
                     IF ::oFont != Nil
                        hwg_Selectobject( hDC, ::oFont:handle )
                     ENDIF
                     lColumnFont := .F.
                  ENDIF

                  IF !Empty( sviv := AllTrim( FLDSTR( Self, nCol ) ) )
                     hwg_Drawtext( hDC, sviv, x + ::aPadding[1], y1 + ::aPadding[2], x2 - 1 - ::aPadding[3], y2 - 1 - ::aPadding[4], oColumn:nJusLin, .T. )
                  ENDIF
                  IF !Empty( oCB ) .AND. !Empty( aCB := oCB:Get( PAINT_LINE_ITEM ) )
                     FOR j := 1 TO Len( aCB )
                        Eval( aCB[j], oColumn, hDC, x, y1, x2, y2, nCol )
                     NEXT
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
         x += xSize
         nCol := ::nPaintCol := iif( nCol == ::freeze, ::nLeftCol, nCol + 1 )
         i ++
         IF ! ::lAdjRight .AND. nCol > Len( ::aColumns )
            EXIT
         ENDIF
      ENDDO
      hwg_Settextcolor( hDC, oldTColor )
      hwg_Setbkcolor( hDC, oldBkColor )
      IF lColumnFont
         hwg_Selectobject( hDC, ::oFont:handle )
      ENDIF
   ENDIF

   RETURN Nil

METHOD SetColumn( nCol ) CLASS HBrowse

   LOCAL nColPos, lPaint := .F.

   IF ::lEditable
      IF nCol != Nil .AND. nCol >= 1 .AND. nCol <= Len( ::aColumns )
         IF nCol <= ::freeze
            ::colpos := nCol
         ELSEIF nCol >= ::nLeftCol .AND. nCol <= ::nLeftCol + ::nColumns - ::freeze - 1
            ::colpos := nCol - ::nLeftCol + ::freeze + 1
         ELSE
            ::nLeftCol := nCol
            ::colpos := ::freeze + 1
            lPaint := .T.
         ENDIF
         ::lRefrBmp := .T.
         IF !lPaint
            ::RefreshLine()
         ELSE
             hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
         ENDIF
      ENDIF

      IF ::colpos <= ::freeze
         nColPos := ::colpos
      ELSE
         nColPos := ::nLeftCol + ::colpos - ::freeze - 1
      ENDIF
      RETURN nColPos

   ENDIF

   RETURN 1

STATIC FUNCTION LineRight( oBrw, lRefresh )
   LOCAL oldLeft := oBrw:nLeftCol
   LOCAL oldPos  := oBrw:colpos
   LOCAL nCols   := Len( oBrw:aColumns )

   IF oBrw:lEditable .AND. oBrw:colpos < oBrw:nColumns
      oBrw:colpos ++
   ELSEIF oBrw:nLeftCol + oBrw:nColumns - oBrw:freeze - 1 < nCols
      oBrw:nLeftCol ++
      oBrw:colpos := oBrw:nColumns
   ENDIF

   IF oBrw:nLeftCol != oldLeft .OR. oBrw:colpos != oldPos
      IF oBrw:hScrollH != Nil
         oBrw:nScrollH := oBrw:nLeftCol - 1
         hwg_SetAdjOptions( oBrw:hScrollH, oBrw:nScrollH )
      ENDIF
      IF lRefresh == Nil .OR. lRefresh
         IF oBrw:nLeftCol == oldLeft
            oBrw:lRefrLinesOnly := .T.
            hwg_Invalidaterect( oBrw:area, 0, oBrw:x1, oBrw:y1 + (oBrw:height+1)*oBrw:rowPosOld - oBrw:height, oBrw:x2, oBrw:y1 + (oBrw:height+1)*oBrw:rowPos )
         ELSE
            hwg_Invalidaterect( oBrw:area, 0 )
         ENDIF
      ENDIF
   ENDIF
   hwg_Setfocus( oBrw:area )
RETURN Nil

STATIC FUNCTION LineLeft( oBrw, lRefresh )
   LOCAL oldLeft := oBrw:nLeftCol
   LOCAL oldPos  := oBrw:colpos

   IF oBrw:lEditable .AND. oBrw:colpos > 1
      oBrw:colpos --
   ELSEIF oBrw:nLeftCol > oBrw:freeze + 1
      oBrw:nLeftCol --
      IF oBrw:lEditable
         oBrw:colpos := 1
      ENDIF
   ENDIF

   IF oBrw:colpos < 1
      oBrw:colpos := 1
   ENDIF

   IF oBrw:nLeftCol != oldLeft .OR. oBrw:colpos != oldPos
      IF oBrw:hScrollH != Nil
         oBrw:nScrollH := oBrw:nLeftCol - 1
         hwg_SetAdjOptions( oBrw:hScrollH, oBrw:nScrollH )
      ENDIF
      IF lRefresh == Nil .OR. lRefresh
         IF oBrw:nLeftCol == oldLeft
            oBrw:lRefrLinesOnly := .T.
            hwg_Invalidaterect( oBrw:area, 0, oBrw:x1, oBrw:y1 + (oBrw:height+1)*oBrw:rowPosOld - oBrw:height, oBrw:x2, oBrw:y1 + (oBrw:height+1)*oBrw:rowPos )
         ELSE
            hwg_Invalidaterect( oBrw:area, 0 )
         ENDIF
      ENDIF
   ENDIF
   hwg_Setfocus( oBrw:area )
RETURN Nil

METHOD DoVScroll( wParam ) CLASS HBrowse

   LOCAL nScrollV

   IF ::hScrollV == Nil
      RETURN 0
   ENDIF

   nScrollV := hwg_getAdjValue( ::hScrollV )

   HB_SYMBOL_UNUSED( wParam )

   IF ::lSetAdj
      ::lSetAdj := .F.
      RETURN 0
   ENDIF

   IF nScrollV - ::nScrollV == 1
      ::LINEDOWN( .T. )
   ELSEIF nScrollV - ::nScrollV == - 1
      ::LINEUP( .T. )
   ELSEIF nScrollV - ::nScrollV == 10
      ::PAGEDOWN( .T. )
   ELSEIF nScrollV - ::nScrollV == - 10
      ::PAGEUP( .T. )
   ELSE
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, SB_THUMBTRACK, .F. , nScrollV )
      ENDIF
   ENDIF
   ::nScrollV := nScrollV

   RETURN 0


METHOD DoHScroll( wParam ) CLASS HBrowse

   LOCAL nScrollH, nLeftCol, colpos

   IF ::hScrollH == Nil
      RETURN 0
   ENDIF

   IF wParam == Nil
      nScrollH := hwg_getAdjValue( ::hScrollH )
      IF nScrollH - ::nScrollH < 0
         LineLeft( Self )
      ELSEIF nScrollH - ::nScrollH > 0
         LineRight( Self )
      ENDIF
   ELSE
      IF wParam == SB_LINELEFT .OR. wParam == SB_PAGELEFT
         LineLeft( Self )

      ELSEIF wParam == SB_LINERIGHT .OR. wParam == SB_PAGERIGHT
         LineRight( Self )

      ELSEIF wParam == SB_LEFT
         nLeftCol := colPos := 0
         DO WHILE nLeftCol != ::nLeftCol .OR. colPos != ::colPos
            nLeftCol := ::nLeftCol
            colPos := ::colPos
            LineLeft( Self, .F. )
         ENDDO
      ELSE
         nLeftCol := colPos := 0
         DO WHILE nLeftCol != ::nLeftCol .OR. colPos != ::colPos
            nLeftCol := ::nLeftCol
            colPos := ::colPos
            LineRight( Self, .F. )
         ENDDO
      END
      hwg_Invalidaterect( ::area, 0 )
   ENDIF

   RETURN Nil

METHOD LINEDOWN( lMouse ) CLASS HBrowse

   LOCAL maxPos, nPos, colpos

   lMouse := iif( lMouse == Nil, .F. , lMouse )
   Eval( ::bSkip, Self, 1 )
   IF Eval( ::bEof, Self )
      Eval( ::bSkip, Self, - 1 )
      IF ::lAppable .AND. ::lEditable .AND. !lMouse .AND. ;
            ( ::type != BRW_DATABASE .OR. ( ::alias ) -> (Dbinfo(DBI_ISREADONLY)) != .T. )
         colpos := 1
         DO WHILE colpos <= Len( ::aColumns ) .AND. !::aColumns[colpos]:lEditable
            colpos ++
         ENDDO
         IF colpos <= Len( ::aColumns )
            ::lAppMode := .T.
         ENDIF
      ELSE
         hwg_Setfocus( ::area )
         RETURN Nil
      ENDIF
   ENDIF
   ::rowPos ++
   IF ::rowPos > ::rowCount
      ::rowPos := ::rowCount
      hwg_Invalidaterect( ::area, 0 )
   ELSE
      ::lRefrLinesOnly := .T.
      hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::rowPosOld - ::height, ::x2, ::y1 + ( ::height + 1 ) * ( ::rowPos ) )
   ENDIF
   IF ::lAppMode
      IF ::rowPos > 1
         ::rowPos --
      ENDIF
      ::colPos := ::nLeftCol := colpos
   ENDIF
   IF !lMouse .AND. ::hScrollV != Nil
   IF ::bScrollPos != Nil
      Eval( ::bScrollPos, Self, 1, .F. )
   ELSEIF !Empty( ::hScrollV )
      maxPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
      nPos := hwg_getAdjValue( ::hScrollV )
      nPos += Int( maxPos/ (::nRecords - 1 ) )
         IF hwg_SetAdjOptions( ::hScrollV, nPos )
            ::lSetAdj := .T.
         ENDIF
         ::nScrollV := nPos
      ENDIF
   ENDIF

   hwg_Setfocus( ::area )

   RETURN Nil

METHOD LINEUP( lMouse ) CLASS HBrowse

   LOCAL maxPos, nPos

   lMouse := iif( lMouse == Nil, .F. , lMouse )
   Eval( ::bSkip, Self, - 1 )
   IF Eval( ::bBof, Self )
      Eval( ::bGoTop, Self )
   ELSE
      ::rowPos --
      IF ::rowPos = 0
         ::rowPos := 1
         hwg_Invalidaterect( ::area, 0 )
      ELSE
         ::lRefrLinesOnly := .T.
         hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::rowPosOld - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::rowPosOld )
         hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::rowPos )
      ENDIF

      IF !lMouse .AND. ::hScrollV != Nil
         IF ::bScrollPos != Nil
            Eval( ::bScrollPos, Self, - 1, .F. )
         ELSEIF !Empty( ::hScrollV )
            maxPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
            nPos := hwg_getAdjValue( ::hScrollV )
            nPos -= Int( maxPos/ (::nRecords - 1 ) )
            IF hwg_SetAdjOptions( ::hScrollV, nPos )
               ::lSetAdj := .T.
            ENDIF
            ::nScrollV := nPos
         ENDIF
      ENDIF

   ENDIF
   hwg_Setfocus( ::area )

   RETURN Nil

METHOD PAGEUP( lMouse ) CLASS HBrowse

   LOCAL maxPos, nPos, step, lBof := .F.

   lMouse := iif( lMouse == Nil, .F. , lMouse )
   IF ::rowPos > 1
      step := ( ::rowPos - 1 )
      Eval( ::bSKip, Self, - step )
      ::rowPos := 1
   ELSE
      step := ::rowCurrCount
      Eval( ::bSkip, Self, - step )
      IF Eval( ::bBof, Self )
         Eval( ::bGoTop, Self )
         lBof := .T.
      ENDIF
   ENDIF

   IF !lMouse .AND. ::hScrollV != Nil
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, - step, lBof )
      ELSEIF !Empty( ::hScrollV )
         maxPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
         nPos := hwg_getAdjValue( ::hScrollV )
         nPos -= Int( maxPos/ (::nRecords - 1 ) )
         nPos := Max( nPos - Int( maxPos * step/(::nRecords - 1 ) ), 0 )
         IF hwg_SetAdjOptions( ::hScrollV, nPos )
            ::lSetAdj := .T.
         ENDIF
         ::nScrollV := nPos
      ENDIF
   ENDIF

   hwg_Invalidaterect( ::area, 0 )
   hwg_Setfocus( ::area )

   RETURN Nil

METHOD PAGEDOWN( lMouse ) CLASS HBrowse

   LOCAL maxPos, nPos, nRows := ::rowCurrCount
   LOCAL step := Iif( nRows > ::rowPos, nRows - ::rowPos + 1, nRows ), lEof

   lMouse := Iif( lMouse == Nil, .F. , lMouse )
   Eval( ::bSkip, Self, step )
   ::rowPos := Min( ::nRecords, nRows )
   lEof := Eval( ::bEof, Self )
   IF lEof .AND. ::bScrollPos == Nil
      Eval( ::bSkip, Self, - 1 )
   ENDIF

   IF !lMouse .AND. ::hScrollV != Nil
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, step, lEof )
      ELSE
         maxPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
         nPos := hwg_getAdjValue( ::hScrollV )
         IF lEof
            nPos := maxPos
         ELSE
            nPos := Min( nPos + Int( maxPos * step/(::nRecords - 1 ) ), maxPos )
         ENDIF
         IF hwg_SetAdjOptions( ::hScrollV, nPos )
            ::lSetAdj := .T.
         ENDIF
         ::nScrollV := nPos
      ENDIF
   ENDIF

   hwg_Invalidaterect( ::area, 0 )
   hwg_Setfocus( ::area )

   RETURN Nil

METHOD BOTTOM( lPaint ) CLASS HBrowse

   LOCAL nPos

   ::rowPos := LastRec()
   Eval( ::bGoBot, Self )
   ::rowPos := Min( ::nRecords, ::rowCount )

   IF ::hScrollV != Nil
      nPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
      IF hwg_SetAdjOptions( ::hScrollV, nPos )
         ::lSetAdj := .T.
      ENDIF
      ::nScrollV := nPos
   ENDIF

   hwg_Invalidaterect( ::area, 0 )

   IF lPaint == Nil .OR. lPaint
      hwg_Setfocus( ::area )
   ENDIF

   RETURN Nil

METHOD TOP() CLASS HBrowse

   LOCAL nPos

   ::rowPos := 1
   Eval( ::bGoTop, Self )

   IF ::hScrollV != Nil
      nPos := 0
      IF hwg_SetAdjOptions( ::hScrollV, nPos )
         ::lSetAdj := .T.
      ENDIF
      ::nScrollV := nPos
   ENDIF

   hwg_Invalidaterect( ::area, 0 )
   hwg_Setfocus( ::area )

   RETURN Nil

METHOD ButtonDown( lParam ) CLASS HBrowse

   LOCAL nLine
   LOCAL step, res := .F. , nrec
   LOCAL maxPos, nPos
   LOCAL ym := hwg_Hiword( lParam ), xm := hwg_Loword( lParam ), x1, fif

   nLine := iif( ym < ::y1, 0, Int( (ym - ::y1 ) / (::height + 1 ) ) + 1 )
   step := nLine - ::rowPos

   ::lBtnDbl := .F.
   x1  := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE fif < ( ::nLeftCol + ::nColumns ) .AND. fif <= Len(::aColumns) .AND. x1 + ::aColumns[fif]:width < xm
      x1 += ::aColumns[fif]:width
      fif := iif( fif == ::freeze, ::nLeftCol, fif + 1 )
   ENDDO
   IF fif > Len( ::aColumns ) .AND. ::lAdjRight
      fif := Len( ::aColumns )
   ENDIF

   IF nLine > 0 .AND. nLine <= ::rowCurrCount
      IF step != 0
         nrec := Eval( ::bRecno, Self )
         Eval( ::bSkip, Self, step )
         IF !Eval( ::bEof, Self )
            ::rowPos := nLine
            IF ::hScrollV != Nil
               IF ::bScrollPos != Nil
                  Eval( ::bScrollPos, Self, step, .F. )
               ELSE
                  nPos := hwg_getAdjValue( ::hScrollV )
                  maxPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
                  nPos := Min( nPos + Int( maxPos * step/(::nRecords - 1 ) ), maxPos )
                  IF hwg_SetAdjOptions( ::hScrollV, nPos )
                     ::lSetAdj := .T.
                  ENDIF
                  ::nScrollV := nPos
               ENDIF
            ENDIF
            res := .T.
         ELSE
            Eval( ::bGoTo, Self, nrec )
         ENDIF
      ENDIF
      IF ::lEditable
         IF ::colpos != fif - ::nLeftCol + 1 + :: freeze
            ::colpos := fif - ::nLeftCol + 1 + :: freeze
            IF ::hScrollH != Nil
               maxPos := hwg_getAdjValue( ::hScrollH, 1 ) - hwg_getAdjValue( ::hScrollH, 4 )
               nPos := Iif( fif == 1, 0, Iif( fif = Len(::aColumns ), maxpos, ;
                  Int( ( maxPos + 1 ) * fif/Len( ::aColumns ) ) ) )
               ::nScrollH := nPos
               hwg_SetAdjOptions( ::hScrollH, nPos )
            ENDIF
            res := .T.
         ENDIF
      ENDIF
      IF res
         hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::rowPosOld - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::rowPosOld )
         hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::rowPos )
      ENDIF

   ELSEIF nLine == 0 .AND. ::nCursor == 1
      ::nCursor := 2
      Hwg_SetCursor( vCursor, ::area )
      xDrag := hwg_Loword( lParam )

   ELSEIF ::lDispHead .AND. ;
         nLine >= - ::nHeadRows .AND. ;
         fif <= Len( ::aColumns ) .AND. ;
         ::aColumns[fif]:bHeadClick != Nil

      Eval( ::aColumns[fif]:bHeadClick, Self, fif, xm, ym )

   ENDIF
   hwg_Setfocus( ::area )
   RETURN Nil

METHOD ButtonRDown( lParam ) CLASS HBrowse

   LOCAL nLine
   LOCAL ym := hwg_Hiword( lParam ), xm := hwg_Loword( lParam ), x1, fif

   IF ::bRClick == Nil
      RETURN Nil
   ENDIF

   nLine := iif( ym < ::y1, 0, Int( (ym - ::y1 ) / (::height + 1 ) ) + 1 )
   x1  := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE fif < ( ::nLeftCol + ::nColumns ) .AND. x1 + ::aColumns[ fif ]:width < xm
      x1 += ::aColumns[ fif ]:width
      fif := iif( fif == ::freeze, ::nLeftCol, fif + 1 )
   ENDDO

   Eval( ::bRClick, Self, fif, nLine - ::rowPos + ::nCurrent )

   RETURN Nil

METHOD ButtonUp( lParam ) CLASS HBrowse

   LOCAL hBrw := ::handle
   LOCAL xPos := hwg_Loword( lParam ), x := ::x1, x1 := xPos, i

   IF ::lBtnDbl
      ::lBtnDbl := .F.
      RETURN Nil
   ENDIF
   IF ::nCursor == 2
      i := iif( ::freeze > 0, 1, ::nLeftCol )
      DO WHILE x < xDrag
         x += ::aColumns[i]:width
         IF Abs( x - xDrag ) < 10
            x1 := x - ::aColumns[i]:width
            EXIT
         ENDIF
         i := iif( i == ::freeze, ::nLeftCol, i + 1 )
      ENDDO
      IF xPos > x1
         ::aColumns[i]:width := xPos - x1
         Hwg_SetCursor( arrowCursor, ::area )
         ::nCursor := 0
         hwg_Invalidaterect( hBrw, 0 )
      ENDIF
   ELSEIF ::aSelected != Nil
      IF ::nCtrlPress == GDK_Control_L
         IF ( i := Ascan( ::aSelected, Eval( ::bRecno,Self ) ) ) > 0
            ADel( ::aSelected, i )
            ASize( ::aSelected, Len( ::aSelected ) - 1 )
         ELSE
            AAdd( ::aSelected, Eval( ::bRecno,Self ) )
         ENDIF
      ELSE
         IF Len( ::aSelected ) > 0
            ::aSelected := {}
            ::Refresh()
         ENDIF
      ENDIF
   ENDIF

   ::Refresh()
   hwg_Setfocus( ::area )

   RETURN Nil

METHOD ButtonDbl( lParam ) CLASS HBrowse

   LOCAL nLine
   LOCAL ym := hwg_Hiword( lParam )

   nLine := iif( ym < ::y1, 0, Int( (ym - ::y1 ) / (::height + 1 ) ) + 1 )
   IF nLine <= ::rowCurrCount
      ::ButtonDown( lParam )
      ::Edit()
   ENDIF
   ::lBtnDbl := .T.

   RETURN Nil

METHOD MouseMove( wParam, lParam ) CLASS HBrowse

   LOCAL xPos := hwg_Loword( lParam ), yPos := hwg_Hiword( lParam )
   LOCAL x := ::x1, i, res := .F. , nLen

   IF !::active .OR. Empty( ::aColumns ) .OR. ::x1 == Nil .OR. ::oGet != Nil
      RETURN Nil
   ENDIF

   IF ::lDispSep .AND. yPos <= ::height + 1
      IF wParam == 1 .AND. ::nCursor == 2
         Hwg_SetCursor( vCursor, ::area )
         res := .T.
      ELSE
         nLen := Len( ::aColumns ) - iif( ::lAdjRight, 1, 0 )
         i := iif( ::freeze > 0, 1, ::nLeftCol )
         DO WHILE x < ::x2 - 2 .AND. i <= nLen
            x += ::aColumns[i]:width
            IF Abs( x - xPos ) < 8
               IF ::aColumns[i]:lResizable
                  IF ::nCursor != 2
                     ::nCursor := 1
                  ENDIF
                  Hwg_SetCursor( Iif( ::nCursor == 1,crossCursor,vCursor ), ::area )
                  res := .T.
               ENDIF
               EXIT
            ENDIF
            i := iif( i == ::freeze, ::nLeftCol, i + 1 )
         ENDDO
      ENDIF
      IF !res .AND. ::nCursor != 0
         Hwg_SetCursor( arrowCursor, ::area )
         ::nCursor := 0
      ENDIF
   ENDIF

   ::Repaint()

   RETURN Nil

METHOD MouseWheel()  CLASS HBrowse

   ::Refresh()
   RETURN Nil

METHOD Edit( wParam ) CLASS HBrowse

   LOCAL fipos, lRes, x1, y1, fif, nWidth, rowPos, lAppM := ::lAppMode
   LOCAL oColumn, type
   LOCAL mvarbuff, bMemoMod, owb1, owb2, oModDlg, bclsbutt
   LOCAL lSaveMem

   lSaveMem := .T.
   bclsbutt := .T.

   fipos := ::colpos + ::nLeftCol - 1 - ::freeze

   oColumn := ::aColumns[fipos]
   IF ::bEnter == Nil .OR. ;
         ( ValType( lRes := Eval( ::bEnter, Self, fipos, ::nCurrent ) ) == 'L' .AND. !lRes )
      IF !oColumn:lEditable
         RETURN Nil
      ENDIF
      IF ::type == BRW_DATABASE
         IF ( ::alias ) -> (Dbinfo(DBI_ISREADONLY)) == .T.
            RETURN Nil
         ENDIF
         ::varbuf := ( ::alias ) -> ( Eval( oColumn:block,,Self,fipos ) )
      ELSE
         ::varbuf := Eval( oColumn:block, , Self, fipos )
      ENDIF
      type := iif( oColumn:type == "U" .AND. ::varbuf != Nil, ValType( ::varbuf ), oColumn:type )
      IF type != "O"
         IF oColumn:bWhen = Nil .OR. Eval( oColumn:bWhen )
            IF ::lAppMode
               IF type == "D"
                  ::varbuf := CToD( "" )
               ELSEIF type == "N"
                  ::varbuf := 0
               ELSEIF type == "L"
                  ::varbuf := .F.
               ELSE
                  ::varbuf := ""
               ENDIF
            ENDIF
         ELSE
            RETURN Nil
         ENDIF
         x1  := ::x1
         fif := iif( ::freeze > 0, 1, ::nLeftCol )
         DO WHILE fif < fipos
            x1 += ::aColumns[fif]:width
            fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
         ENDDO
         nWidth := Iif( ::lAdjRight.AND.fif==Len(::aColumns), ;
               ::x2 - x1 - 1, Min( ::aColumns[fif]:width, ::x2 - x1 - 1 ) )
         rowPos := ::rowPos - 1
         IF ::lAppMode .AND. ::nRecords != 0
            rowPos ++
         ENDIF
         y1 := ::y1 + ( ::height + 1 ) * rowPos
         ::nGetRec := Eval( ::bRecno, Self )
         ::lEditing := .T.

         y1 := y1 + ::nTop
         x1 := x1 + ::nLeft

         IF __objHasMethod( ::oParent, "GetActivePage" )
           y1 += ::oParent:nTop + 5
           x1 += ::oParent:nLeft + 5

           IF ::lAppMode
               y1 += ::height
           ENDIF
        ENDIF

        IF type <> "M"
            @ x1, y1 GET ::oGet VAR ::varbuf      ;
               OF  ::oParent:oParent ;
               SIZE nWidth, ::height + 1      ;
               STYLE ES_AUTOHSCROLL           ;
               FONT ::oFont                   ;
               PICTURE oColumn:picture        ;
               VALID { ||VldBrwEdit( Self, fipos, lAppM ) }
            ::oGet:Show()
            hwg_Setfocus( ::oGet:handle )
            hwg_edit_SetPos( ::oGet:handle, 1 )
            ::oGet:bAnyEvent := { |o, msg, c| HB_SYMBOL_UNUSED(o),  GetEventHandler( Self, msg, c ) }
            IF !Empty( wParam )
               ::oGet:onEvent( WM_KEYDOWN, wParam, 0 )
            ENDIF
         ELSE  // memo edit
            INIT DIALOG oModDlg title ::cTextTitME AT 0, 0 SIZE 610, 390
            mvarbuff := ::varbuf
               @ 0, 30 HCEDIT ::oEdit SIZE 600, 300 FONT ::oFont

               @ 200, 350 ownerbutton owb2 TEXT ::cTextSave  size 100, 30 ON Click { || bclsbutt := .F. , mvarbuff := ::oEdit , omoddlg:close(), oModDlg:lResult := .T. }
               @ 320, 350 ownerbutton owb1 TEXT ::cTextClose size 100, 30 ON CLICK { || mvarbuff := ::oEdit , omoddlg:close(), oModDlg:lResult := .T. }

                ::oEdit:SetText(mvarbuff)
            oModDlg:Activate(,,,.T.)
          bMemoMod := ::oEdit:lUpdated
          IF bMemoMod
            IF bclsbutt
             lSaveMem := hwg_Msgyesno( ::cTextMod , ::cTextTitME )
            ENDIF
            IF lSaveMem
             ::varbuf := ::oEdit:GetText()
             VldBrwEdit( Self, fipos, lAppM, .T. )
            ENDIF
           ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

METHOD Repaint() CLASS HBrowse

   ::Refresh()
   ::Setfocus()

RETURN Nil


STATIC FUNCTION GetEventHandler( oBrw, msg, cod )

   LOCAL nCol

   IF msg == WM_KEYDOWN .AND. cod == GDK_Escape

      /*
       * GTK4 note: in GTK2 and Win32, moving focus away from a
       * GtkEntry used to run the get's VALID automatically, and
       * VldBrwEdit was what removed the entry from the parent's
       * GetList.  On GTK4 the WM_KILLFOCUS path is delivered to
       * HEdit:onEvent -> __Valid(), which sees oDlg:nLastKey == 27
       * and intentionally SKIPS the save -- but __Valid does NOT
       * remove the control.  Only VldBrwEdit does that.
       *
       * So we call VldBrwEdit ourselves.  It detects the ESC
       * (bESCkey = .T.), skips the save, calls DelControl() and
       * clears ::oGet, then gives focus back to the browse area.
       */
      oBrw:oGet:nLastKey := GDK_Escape
      oBrw:lEditing := .F.

      nCol := oBrw:colpos + oBrw:nLeftCol - 1 - oBrw:freeze
      VldBrwEdit( oBrw, nCol, oBrw:lAppMode, .F. )

      RETURN 1
   ENDIF

   RETURN 0

STATIC FUNCTION VldBrwEdit( oBrw, fipos, lAppM, lMemo )
* Purpose: Store edited contents
* Parameter lMemo is .T. when the edit came from HCEdit (memo dialog),
* .F. (default) when it came from the inline HGet.

   LOCAL oColumn := oBrw:aColumns[fipos], nRec, fif
   LOCAL cErrMsgRecLock, bESCkey
   LOCAL nChoic := NIL
   LOCAL xRet

   IF lMemo == NIL
      lMemo := .F.
   ENDIF

   /*
    * Reentrancy guard.
    *
    * DelControl() below destroys the GtkEntry; on GTK4 that emits
    * another focus-out synchronously, which re-enters HEdit:onEvent
    * (WM_KILLFOCUS) and calls this function a second time.  By then
    * oBrw:oGet (or oBrw:oEdit) is already Nil, and reading
    * :nLastKey raises "BASE/1004 Method not exported: NLASTKEY",
    * whose error dialog itself runs inside the focus handler and
    * freezes the UI.
    *
    * If the get/edit is already gone, there is nothing left to do.
    */
   IF lMemo
      IF oBrw:oEdit == Nil
         RETURN .T.
      ENDIF
   ELSE
      IF oBrw:oGet == Nil
         RETURN .T.
      ENDIF
   ENDIF

   /* Mysterious behavior of Harbour on Ubuntu and LinuxMINT:
      Not ever found, that  ::cTextLockRec is not here
      reachable, this function not member of HBROWSE class */
     cErrMsgRecLock := oBrw:cTextLockRec

   // ESC key pressed ?
   IF lMemo
      bESCkey := iif( oBrw:oEdit:nLastKey != GDK_Escape , .F. , .T. ) /* Memo edit */
   ELSE
      bESCkey := iif( oBrw:oGet:nLastKey  != GDK_Escape , .F. , .T. ) /* GET */
   ENDIF

   IF .NOT. bESCkey

      /*
       * Windows and GTK2 tolerated any non-.F. return value from a
       * column VALID block (Nil, string, number were all accepted).
       * The GTK4 port used "!Eval(...)" which requires strictly
       * logical and raises BASE/1066 otherwise.  Restoring the
       * older semantic: only an explicit .F. vetoes the edit.
       */
      IF !Empty( oColumn:bValid )
         xRet := Eval( oColumn:bValid, oBrw:varbuf, oBrw:oGet )
         IF ValType( xRet ) == "L" .AND. !xRet
            RETURN .F.
         ENDIF
      ENDIF

      IF oColumn:aList != Nil
         IF ValType( oBrw:varbuf ) == 'N'
            oBrw:varbuf := nChoic
         ELSE
            oBrw:varbuf := oColumn:aList[nChoic]
         ENDIF
      ENDIF

      IF lAppM
         oBrw:lAppMode := .F.
         IF oBrw:type == BRW_DATABASE
            ( oBrw:alias ) -> ( dbAppend() )
            ( oBrw:alias ) -> ( Eval( oColumn:block,oBrw:varbuf,oBrw,fipos ) )
            ( oBrw:alias ) -> ( DbUnlock() )
         ELSE
            IF ValType( oBrw:aArray[1] ) == "A"
               AAdd( oBrw:aArray, Array( Len(oBrw:aArray[1] ) ) )
               FOR fif := 2 TO Len( ( oBrw:aArray[1] ) )
                  oBrw:aArray[Len(oBrw:aArray),fif] := ;
                     Iif( oBrw:aColumns[fif]:type == "D", CToD( Space(8 ) ), ;
                     Iif( oBrw:aColumns[fif]:type == "N", 0, "" ) )
               NEXT
            ELSE
               AAdd( oBrw:aArray, Nil )
            ENDIF
            oBrw:nCurrent := Len( oBrw:aArray )
            Eval( oColumn:block, oBrw:varbuf, oBrw, fipos )
         ENDIF
         IF oBrw:nRecords > 0
            oBrw:rowPos ++
         ENDIF
         oBrw:lAppended := .T.
         oBrw:Refresh()
      ELSE
         IF ( nRec := Eval( oBrw:bRecno,oBrw ) ) != oBrw:nGetRec
            Eval( oBrw:bGoTo, oBrw, oBrw:nGetRec )
         ENDIF
         IF oBrw:type == BRW_DATABASE
            IF ( oBrw:alias ) -> ( RLock() )
               ( oBrw:alias ) -> ( Eval( oColumn:block,oBrw:varbuf,oBrw,fipos ) )
               ( oBrw:alias ) -> ( DbUnlock() )
            ELSE
               hwg_Msgstop( cErrMsgRecLock )
            ENDIF
         ELSE
            Eval( oColumn:block, oBrw:varbuf, oBrw, fipos )
         ENDIF
         IF nRec != oBrw:nGetRec
            Eval( oBrw:bGoTo, oBrw, nRec )
         ENDIF
         oBrw:lUpdated := .T.
      ENDIF
   ENDIF  /* GDK_Escape key */

   oBrw:Refresh()

   IF ( .NOT. bESCkey ) .AND. oBrw:bUpdate != Nil
      Eval( oBrw:bUpdate, oBrw, fipos )
   ENDIF

   IF lMemo
     //oBrw:oParent:DelControl( oBrw:oEdit ) //Here Crash on GTK! Itamar Lins
     oBrw:oEdit := Nil
   ELSE
     oBrw:oParent:DelControl( oBrw:oGet )
     oBrw:oGet := Nil
   ENDIF
   hwg_Setfocus( oBrw:area )

   RETURN .T.

METHOD RefreshLine() CLASS HBrowse

   ::lRefrLinesOnly := .T.
   hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::rowPos )

   RETURN Nil

METHOD Refresh( lFull ) CLASS HBrowse

   IF lFull == Nil .OR. lFull
      ::lRefrHead := .T.
      ::lRefrLinesOnly := .F.
      /* GTK4: RDW_* flags are ignored by HWG_REDRAWWINDOW. */
      hwg_Redrawwindow( ::area, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   ELSE
      ::lRefrHead := .F.
      hwg_Invalidaterect( ::area, 0 )
   ENDIF

   RETURN Nil

STATIC FUNCTION FldStr( oBrw, numf )

   LOCAL cRes, vartmp, type
   LOCAL pict

   IF numf <= Len( oBrw:aColumns )

      IF oBrw:type == BRW_DATABASE
         vartmp := ( oBrw:alias ) -> ( Eval( oBrw:aColumns[numf]:block,,oBrw,numf ) )
      ELSE
         vartmp := Eval( oBrw:aColumns[numf]:block, , oBrw, numf )
      ENDIF

      pict := oBrw:aColumns[numf]:picture
      IF pict != Nil
         cRes := Transform( vartmp, pict )
      ELSE
         type := ( oBrw:aColumns[numf] ):type
         IF type == "U" .AND. vartmp != Nil
            type := ValType( vartmp )
         ENDIF
         IF type == "C"
            cRes := vartmp
         ELSEIF type == "N"
            cRes := Ltrim( Str( vartmp, 24, oBrw:aColumns[numf]:dec ) )
         ELSEIF type == "D"
            cRes := Dtoc( vartmp )
         ELSEIF type == "L"
            cRes := iif( vartmp, "T", "F" )
         ELSEIF type == "M"
            cRes := iif( Empty( vartmp ), "<memo>", "<MEMO>" )
         ELSEIF type == "O"
            cRes := "<" + vartmp:Classname() + ">"
         ELSEIF type == "A"
            cRes := "<Array>"
         ELSE
            cRes := " "
         ENDIF
      ENDIF
   ENDIF

   RETURN cRes

STATIC FUNCTION FLDCOUNT( oBrw, xstrt, xend, fld1 )

   LOCAL klf := 0, i := iif( oBrw:freeze > 0, 1, fld1 )

   WHILE .T.
      xstrt += oBrw:aColumns[i]:width
      IF xstrt > xend
         EXIT
      ENDIF
      klf ++
      i   := iif( i = oBrw:freeze, fld1, i + 1 )
      IF i > Len( oBrw:aColumns )
         EXIT
      ENDIF
   ENDDO

   RETURN iif( klf = 0, 1, klf )

FUNCTION hwg_CREATEARLIST( oBrw, arr )

   LOCAL i

   oBrw:type  := BRW_ARRAY
   oBrw:aArray := arr
   IF Len( oBrw:aColumns ) == 0
      IF ValType( arr[1] ) == "A"
         FOR i := 1 TO Len( arr[1] )
            oBrw:AddColumn( HColumn():New( ,hwg_ColumnArBlock() ) )
         NEXT
      ELSE
         oBrw:AddColumn( HColumn():New( ,{ |value,o| HB_SYMBOL_UNUSED(value) , o:aArray[ o:nCurrent ] } ) )
      ENDIF
   ENDIF
   Eval( oBrw:bGoTop, oBrw )
   oBrw:Refresh()

   RETURN Nil

PROCEDURE ARSKIP( oBrw, kolskip )

   LOCAL tekzp1

   IF oBrw:nRecords != 0
      tekzp1   := oBrw:nCurrent
      oBrw:nCurrent += kolskip + iif( tekzp1 = 0, 1, 0 )
      IF oBrw:nCurrent < 1
         oBrw:nCurrent := 0
      ELSEIF oBrw:nCurrent > oBrw:nRecords
         oBrw:nCurrent := oBrw:nRecords + 1
      ENDIF
   ENDIF

   RETURN

FUNCTION hwg_CreateList( oBrw, lEditable )

   LOCAL i
   LOCAL nArea := Select()
   LOCAL kolf := FCount()

   oBrw:alias   := Alias()

   oBrw:aColumns := {}
   FOR i := 1 TO kolf
      oBrw:AddColumn( HColumn():New( FieldName(i ), ;
         FieldWBlock( FieldName( i ), nArea ), ;
         dbFieldInfo( DBS_TYPE, i ),         ;
         dbFieldInfo( DBS_LEN, i ),          ;
         dbFieldInfo( DBS_DEC, i ),          ;
         lEditable ) )
   NEXT

   oBrw:Refresh()

   RETURN Nil

FUNCTION hwg_VScrollPos( oBrw, nType, lEof, nPos )

   LOCAL maxPos := hwg_getAdjValue( oBrw:hScrollV, 1 ) - hwg_getAdjValue( oBrw:hScrollV, 4 )
   LOCAL oldRecno, newRecno

   IF nPos == Nil
      IF nType > 0 .AND. lEof
         Eval( oBrw:bSkip, oBrw, - 1 )
      ENDIF
      nPos := Round( ( maxPos/(oBrw:nRecords - 1 ) ) * ( Eval( oBrw:bRecnoLog,oBrw ) - 1 ),0 )
      IF hwg_SetAdjOptions( oBrw:hScrollV, nPos )
          obrw:lSetAdj := .T.
      ENDIF
      oBrw:nScrollV := nPos
   ELSE
      oldRecno := Eval( oBrw:bRecnoLog, oBrw )
      newRecno := Round( ( oBrw:nRecords - 1 ) * nPos/ maxPos + 1, 0 )
      IF newRecno <= 0
         newRecno := 1
      ELSEIF newRecno > oBrw:nRecords
         newRecno := oBrw:nRecords
      ENDIF
      IF newRecno != oldRecno
         Eval( oBrw:bSkip, oBrw, newRecno - oldRecno )
         IF oBrw:rowCount - oBrw:rowPos > oBrw:nRecords - newRecno
            oBrw:rowPos := oBrw:rowCount - ( oBrw:nRecords - newRecno )
         ENDIF
         IF oBrw:rowPos > newRecno
            oBrw:rowPos := newRecno
         ENDIF
         oBrw:Refresh()
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION hwg_HScrollPos( oBrw, nType, lEof, nPos )

   HB_SYMBOL_UNUSED( nType )
   HB_SYMBOL_UNUSED( lEof )

   hwg_SetAdjOptions( oBrw:hScrollH, nPos )
   oBrw:nScrollH := nPos
   oBrw:Refresh()

   RETURN Nil

FUNCTION hwg_ColumnArBlock()

   RETURN { |value, o, n| iif( value == Nil, o:aArray[o:nCurrent,n], o:aArray[o:nCurrent,n] := value ) }

STATIC FUNCTION CountToken( cStr, nMaxLen, nCount )

   nMaxLen := nCount := 0
   IF ValType( cStr ) == "C"
      IF ( ';' $ cStr )
         cStr := hb_aTokens( cStr, ';' )
      ELSE
         nMaxLen := Len( cStr )
         nCount := 1
      ENDIF
   ENDIF
   IF ValType( cStr ) == "A"
      AEval( cStr, { |s|nMaxLen := Max( nMaxLen,Len(s ) ) } )
      nCount := Len( cStr )
   ENDIF

   RETURN cStr
