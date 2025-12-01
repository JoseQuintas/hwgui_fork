/*
 * $Id$
 */

/*
 * HWGUI - Harbour Win32 GUI library source code:
 * The Edit control
 *
 * Copyright 2013 Alexander Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version, with one exception:
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

/* Modifications by DF7BE:
 - Bugfix: AltGr key ignored, so very important characters like
   \@µ~{}[] and Euro Currency sign are not reached.
*/

#include "hbclass.ch"
#include "hwgui.ch"
#include "hxml.ch"

#ifdef __XHARBOUR__
#xtranslate HB_AT(<x,...>) => AT(<x>)
#xtranslate HB_RAT(<x,...>) => RAT(<x>)
#xtranslate HB_HASH([<x,...>]) => HASH([<x>])
#xtranslate HB_HHASKEY(<x,...>) => HHASKEY(<x>)
#endif

#define WM_MOUSEACTIVATE    33  // 0x0021
#define MA_ACTIVATE          1

#define P_LENGTH             2
#define P_X                  1
#define P_Y                  2

#define SETC_COORS           1
#define SETC_RIGHT           2
#define SETC_LEFT            3
#define SETC_XY              4
#define SETC_XFIRST          5
#define SETC_XCURR           6
#define SETC_XLAST           7
#define SETC_XYPOS           8

#define AL_LENGTH            8
#define AL_X1                1
#define AL_Y1                2
#define AL_X2                3
#define AL_Y2                4
#define AL_NCHARS            5
#define AL_LINE              6
#define AL_FIRSTC            7
#define AL_SUBL              8

#define SB_LINE              1
#define SB_LINES             2
#define SB_REST              3
#define SB_TEXT              4

#define HILIGHT_GROUPS  4
#define HILIGHT_KEYW    1
#define HILIGHT_FUNC    2
#define HILIGHT_QUOTE   3
#define HILIGHT_COMM    4

#define UNDO_LINE1      1
#define UNDO_POS1       2
#define UNDO_LINE2      3
#define UNDO_POS2       4
#define UNDO_OPER       5
#define UNDO_TEXT       6

#define STRING_MAX_LEN  1024

#define BOTTOM_HEIGHT   8

#define HTRACK_DEF_WIDTH  18

#ifdef __GTK__
#define GDK_CONTROL_MASK  2
#define GDK_MOD1_MASK     4
#endif

#ifndef __GTK__
static hCursor
#endif

STATIC cNewLine := e"\r\n"

* For multi OS request UTF8 forever
* #ifdef __GTK__
#ifdef __XHARBOUR__
REQUEST  HB_CODEPAGE_UTF8
#endif
* #endif

CLASS HCEdit INHERIT HControl

   CLASS VAR winclass  INIT "HBOARD"

   DATA   hEdit
   DATA   oTrack
   DATA   cFileName
   DATA   aText, nTextLen
   DATA   nMaxLines    INIT 0
   DATA   cp, cpSource
   DATA   lUtf8        INIT .F.
   DATA   aWrap, nLinesAll
   DATA   nDocFormat   INIT 0
   DATA   nDocOrient   INIT 0
   DATA   aDocMargins  INIT { 10,10,10,10 }
   DATA   nKoeffScr

   DATA   lShowNumbers INIT .F.
   DATA   lReadOnly    INIT .F.
   DATA   lUpdated     INIT .F.
   DATA   lInsert      INIT .T.
   DATA   lNoPaste     INIT .F.

   DATA   nShiftL      INIT 0
   DATA   nBoundL      INIT 0
   DATA   nBoundR
   DATA   nBoundT      INIT 0
   DATA   nMarginL     INIT 0
   DATA   nMarginR     INIT 0
   DATA   nMarginT     INIT 0
   DATA   nMarginB     INIT 0

   DATA   n4Number     INIT 0
   DATA   n4Separ      INIT 0
   DATA   bColorCur    INIT 16449510      // A bacground color for a current line
   DATA   tcolorSel    INIT 16777215
   DATA   bcolorSel    INIT 16744448
   DATA   nClrDesk     INIT 8421504
   DATA   nAlign       INIT 0             // 0 - Left, 1 - Center, 2 - Right
   DATA   nIndent      INIT 0
   DATA   nDefFont     INIT 0

   DATA   nLineF       INIT 1
   DATA   nPosF        INIT 1
   DATA   aLines, nLines, nLineC, nPosC

   DATA   nWCharF      INIT 1             // (:lWrap) a position in
                                          // :aText[::nLineF] - first line beginning
   DATA   nWSublF      INIT 1             // (:lWrap) a subline of ::nLineF - first line
   DATA   aFonts       INIT {}
   DATA   aFontsPrn    INIT {}
   DATA   oPenNum

   DATA   nCaret       INIT 0
   DATA   lChgCaret    INIT .F.
   DATA   lSetFocus    INIT .F.
   DATA   bChangePos, bKeyDown, bClickDoub, bRClick
   DATA   bAfter

   DATA   lMDown       INIT .F.
   DATA   aPointC, aPointM1, aPointM2

   DATA   nTabLen      INIT 4
   DATA   lTabs        INIT .F.
   DATA   lStripSpaces INIT .T.
   //DATA   lVScroll
   DATA   nTrackWidth  INIT 0
   DATA   nClientWidth
   DATA   nDocWidth
   DATA   nLastKey     INIT 0

#ifdef __GTK__
   DATA area
   DATA hScrollV  INIT Nil
   DATA hScrollH  INIT Nil
   DATA nScrollV  INIT 0
   DATA nScrollH  INIT 0
#endif

   DATA   nMaxUndo     INIT 10
   DATA   aUndo

   DATA   oHili
   DATA   aHili     PROTECTED
   DATA   lWrap     INIT .F. PROTECTED
   DATA   nPadding  INIT 0   PROTECTED
#ifdef __GTK__
   DATA   lPainted  INIT .F. PROTECTED
   DATA   lNeedScan INIT .F. PROTECTED
#endif
   DATA   lScan     INIT .F. PROTECTED
   // --- International Language Support for internal dialogs --
   DATA aLangTexts  INIT {}
   // Print Preview Dialog with sub dialog:
   // The messages and control text's are delivered by other classes, calling
   // the method Preview() in Parameter aTooltips as an array.
   // After call of Init method, you can update the array with messages in your
   // desired language.
   // Sample: Preview( , , aLangTexts, )
   // Structure of array look at
   // hwg_HPrinter_LangArray_EN() in file hprinter.prg
   // Copy your own language message array direct after
   // call of METHOD ::New()


   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, tcolor, bcolor, bGfocus, bLfocus, lNoVScroll, lNoBorder )
   METHOD DefaultLang()
   METHOD Open( cFileName, cPageIn, cPageOut )
   METHOD Activate()
   METHOD Init()
   METHOD SetHili( xGroup, oFont, tColor, bColor )
   METHOD onEvent( msg, wParam, lParam )
   METHOD Paint( lReal )
   METHOD PaintLine( hDC, yPos, nLine, lUse_aWrap, nRight )
   METHOD MarkLine( nLine, lReal, nSubLine, nWCharF, nLineC )
   METHOD End(  )
   METHOD Convert( cPageIn, cPageOut )
   METHOD SetText( xText, cPageIn, cPageOut )
   METHOD SAVE( cFileName , cpSou )
   METHOD AddFont( oFont, name, width, height , weight, ;
      CharSet, Italic, Underline, StrikeOut )
   METHOD SetFont( oFont )
   METHOD SetCaretPos( nType, p1, p2 )
   METHOD onKeyDown( nKeyCode, lParam, nCtrl )
   METHOD PutChar( nKeyCode )
   METHOD LineDown()
   METHOD LineUp(lChgPos)
   METHOD PageDown()
   METHOD PageUp()
   METHOD Top()
   METHOD Bottom()
   METHOD GOTO( nLine )
   //METHOD onVScroll( wParam )
   METHOD PCopy( Psource, Pdest )
   METHOD PCmp( P1, P2 )
   METHOD GetText( P1, P2, lTabs )
   METHOD InsText( aPoint, cText, lOver, lChgPos )
   METHOD DelText( P1, P2, lChgPos )
   METHOD AddLine( nLine )
   METHOD DelLine( nLine )
   METHOD Refresh()
   METHOD SetWrap( lWrap, lInit )
   METHOD SetPadding( nValue )
   METHOD SetBorder( nThick, nColor )
   METHOD Highlighter( oHili )
   METHOD Scan( nl1, nl2, hDC, nWidth, nHeight)
   METHOD Undo( nLine1, nPos1, nLine2, nPos2, nOper, cText )
   METHOD Print( nDocFormat, nDocOrient, nMarginL, nMarginR, nMarginT, nMarginB )
   METHOD PrintLine( oPrinter, yPos, nL )
   METHOD Move( x1, y1, width, height )
   METHOD ShowTrackBar( lShow, nTrackWidth )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, tcolor, bcolor, bGfocus, bLfocus, lNoVScroll, lNoBorder )  CLASS HCEdit

   ::DefaultLang()

   IF Valtype( lNoVScroll ) == "N"
      ::nTrackWidth := lNoVScroll
   ELSEIF Valtype( lNoVScroll ) == "L" .AND. lNoVScroll
      ::nTrackWidth := 0
   ELSE
      ::nTrackWidth := HTRACK_DEF_WIDTH
   ENDIF
   nStyle := Hwg_BitOr( Iif( nStyle == Nil,0,nStyle ), WS_CHILD + WS_VISIBLE +  ;
      Iif( lNoBorder = Nil .OR. !lNoBorder, WS_BORDER, 0 ) ) //+          ;

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, Iif( nWidth == Nil,0,nWidth ), ;
      Iif( nHeight == Nil, 0, nHeight ), oFont, bInit, bSize, bPaint, , ;
      Iif( tcolor == Nil, 0, tcolor ), Iif( bcolor == Nil, 16777215, bcolor ) )

   ::nBoundR := ::nClientWidth := ::nWidth - ::nTrackWidth

   IF ::oFont == Nil
      IF ::oParent:oFont == Nil
         PREPARE FONT ::oFont NAME "Courier New" WIDTH 0 HEIGHT - 17
      ELSE
         ::oFont := ::oParent:oFont
      ENDIF
   ENDIF

   ::bGetFocus  := bGFocus
   ::bLostFocus := bLFocus

   ::aLines   := Array( 64, AL_LENGTH )
   ::aPointC := ::PCopy()
   ::aPointM1 := ::PCopy()
   ::aPointM2 := ::PCopy()

   ::nTextLen := ::nLines := 0
   ::aHili := hb_Hash()

   ::hEdit := hced_InitTextEdit()

#ifdef __GTK__
   IF ::nTrackWidth > 0 .AND. Empty( ::oTrack )
      ::ShowTrackBar( .T., ::nTrackWidth )
   ENDIF
#else
   IF Empty( hCursor )
      hCursor := hwg_Loadcursor( IDC_IBEAM )
   ENDIF
#endif

   ::Activate()

   RETURN Self

METHOD DefaultLang() CLASS HCEdit
  ::aLangTexts := hwg_HPrinter_LangArray_EN()
RETURN NIL

METHOD Open( cFileName, cPageIn, cPageOut ) CLASS HCEdit

   ::SetText( MemoRead( cFileName ), cPageIn, cPageOut )
   ::cFileName := cFileName

   RETURN Nil

METHOD Activate() CLASS HCEdit

   IF !Empty( ::oParent:handle )
      ::handle := hwg_CreateBoard( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nClientWidth, ::nHeight, .T. )
#ifdef __GTK__
      IF hwg_bitand( ::style, WS_BORDER ) != 0
         ::SetBorder( 2 )
      ENDIF
#endif
      ::Init()

   ENDIF

   RETURN Nil

METHOD Init() CLASS HCEdit

   IF !::lInit
      ::Super:Init()
#ifndef __GTK__
      ::nHolder := 1
#endif
      hced_SetHandle( ::hEdit, ::handle )
      hwg_Setwindowobject( ::handle, Self )

      IF Empty( ::aFonts )
         ::AddFont( ::oFont )
      ENDIF
      IF Empty( ::aText )
         ::SetText()
      ENDIF
      hced_Setcolor( ::hEdit, ::tcolor, ::bcolor )
      ::oPenNum := HPen():Add( , 2, 7135852 )
      IF ::lWrap .AND. ::aWrap == Nil
         ::aWrap := Array( ::nTextLen )
         ::Scan()
      ENDIF

#ifndef __GTK__
      IF ::nTrackWidth > 0 .AND. Empty( ::oTrack )
         ::ShowTrackBar( .T., ::nTrackWidth )
      ENDIF
#endif
   ENDIF

   RETURN Nil

METHOD SetHili( xGroup, oFont, tColor, bColor ) CLASS HCEdit
   LOCAL arr

   IF !Empty( oFont ) .AND. Empty( ::aFonts )
      ::AddFont( ::oFont )
   ENDIF

   IF !hb_hHaskey( ::aHili, xGroup )
      ::aHili[xGroup] := Array( 3 )
   ENDIF
   arr := ::aHili[xGroup]

   arr[ 1 ] := Iif( ValType( oFont ) == "O", ::AddFont( oFont ), Iif( Empty(oFont), 0, oFont ) )
   arr[ 2 ] := tColor
   arr[ 3 ] := bColor

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HCEdit
   LOCAL n, lRes := - 1, x, aPointC[P_LENGTH], nLinesAll
   LOCAL n1 , n2, lctrls

   ::PCopy( ::aPointC, aPointC )
   IF ::bOther != Nil
      n := Eval( ::bOther,Self,msg,wParam,lParam )
      IF n != - 1
         RETURN n
      ENDIF
   ENDIF

   IF msg == WM_PAINT
      ::Paint()
      lRes := 0

   ELSEIF msg == WM_GETDLGCODE
      lRes := DLGC_WANTALLKEYS

   ELSEIF msg == WM_CHAR
      // If not readonly mode and Ctrl key isn't pressed
      // DF7BE: Message WM_CHAR not sent on LINUX/GTK, key codes handled in method OnKeyDown
      x := hwg_GetKeyboardState( lParam )

      /*
      ================================================================================
      DF7BE : Handle AltGr key for ~, greek micro and Euro currency sign ( and more )
      ================================================================================
      */

      // hwg_writelog(x)
      &&
      n :=  Iif( Asc( SubStr(x,0x12,1 ) ) >= 128, FCONTROL, Iif( Asc(SubStr(x,0x11,1 ) ) >= 128,FSHIFT,0 ) )
      &&                       18dec                                          17dec
      n1 := Iif( Asc( SubStr(x,19,1 ) ) >= 128, FCONTROL, 0 )
      n2 := Iif( Asc( SubStr(x,18,1 ) ) >= 128, FSHIFT ,0 )
      /*
        Keyboard buffer x has fixed length of 256 ( 0 ... 255 )
        FSHIFT=4,FCONTROL=8,FALT=16=0x10
        Table: values for Ctrl and AltGr key
        Position in keyboard buffer: 18 +  19
        AltGr + Euro : 81 + 81 (Euro currency sign)
        AltGr + ~    : 80 + 80 (Tilde)
        AltGr + mu   : 81 + 81 (Greek micro)
        AltGr + \    : 81 + 80 (Backslash)
        Logical assignment:
         AltGr + character pressed : n1 ==  FCONTROL  and n2 == FSHIFT  ==> lctrls := .T.
         Ctrl pressed              : n1 ==  FCONTROL  and n2 == 0       ==> lctrls := .F.
      */
      lctrls := .F.

      IF n != FCONTROL
       lctrls := .T.
      ENDIF

      IF ( n1 ==  FCONTROL) .AND. ( n2 == FSHIFT )
       lctrls := .T.
      ENDIF

      // hwg_writelog("n1=" + STR(n1) + " n2=" + STR(n2) )
      // IF n != FCONTROL
      IF lctrls   && Ctrl or AltGr key
#ifdef __GTK__
         x := wParam
#else
         x := hwg_PtrToUlong( wParam )
#endif
*
*        IF ::bKeyDown != Nil .AND. ( n := Eval( ::bKeyDown, Self, x, n, 1 ) ) != -1
         IF ::bKeyDown != Nil  && .AND.
          n := Eval( ::bKeyDown, Self, x, n, 1 )
          IF n != -1
             RETURN -1
          ENDIF
         ENDIF
         ::putChar( x )
      ENDIF

   ELSEIF msg == WM_KEYDOWN
#ifdef __GTK__
      lRes := ::onKeyDown( wParam, lParam )
#else
      lRes := ::onKeyDown( hwg_PtrToUlong( wParam ), lParam )
#endif
   ELSEIF msg == WM_LBUTTONDOWN .OR. msg == WM_RBUTTONDOWN
#ifdef __GTK__
      //hced_SetFocus( ::hEdit )
      hwg_SetFocus( ::handle )
#endif
      IF msg == WM_LBUTTONDOWN .AND. !Empty( ::aPointM2[P_Y] )
         ::PCopy( , ::aPointM2 )
         //hced_Invalidaterect( ::hEdit, 0, 0, 0, ::nClientWidth, ::nHeight )
         hwg_Invalidaterect( ::handle, 0, 0, 0, ::nClientWidth, ::nHeight )
      ENDIF
      hced_ShowCaret( ::hEdit )
      IF ::nCaret > 0 .AND. ::nLines > 0
         ::SetCaretPos( SETC_COORS, hwg_LoWord( lParam ), hwg_HiWord( lParam ) )
         IF msg == WM_LBUTTONDOWN
            ::lMDown := .T.
            ::PCopy( ::aPointC, ::aPointM1 )
         ENDIF
      ENDIF
      IF ::nCaret <= 0
         ::nCaret ++
      ENDIF
      IF msg == WM_RBUTTONDOWN .AND. !Empty( ::bRClick )
         Eval( ::bRClick, Self )
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      ::lMDown := .F.
      IF Empty( ::aPointM2[P_Y] ) .OR. ::PCmp( ::aPointM1, ::aPointM2 ) == 0
         hced_ShowCaret( ::hEdit )
      ENDIF

   ELSEIF msg == WM_MOUSEMOVE
#ifndef __GTK__
      Hwg_SetCursor( hCursor )
#endif
      IF ::lMDown
         IF ::nCaret > 0
            //::nCaret := 0
            //hced_HideCaret( ::hEdit )
         ENDIF
         n := ::nLineC
         ::SetCaretPos( SETC_COORS + 100, hwg_LoWord( lParam ), hwg_HiWord( lParam ) )
         IF ::PCmp( ::aPointM1, ::aPointC ) != 0
            ::PCopy( ::aPointC, ::aPointM2 )
         ENDIF
         IF ::nLineC >= n
            //hced_Invalidaterect( ::hEdit, 0, 0, ::aLines[n,AL_Y1], ::nClientWidth, ::aLines[::nLineC,AL_Y2] )
            hwg_Invalidaterect( ::handle, 0, 0, ::aLines[n,AL_Y1], ::nClientWidth, ::aLines[::nLineC,AL_Y2] )
         ELSE
            //hced_Invalidaterect( ::hEdit, 0, 0, ::aLines[::nLineC,AL_Y1], ::nClientWidth, ::aLines[n,AL_Y2] )
            hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ::nClientWidth, ::aLines[n,AL_Y2] )
         ENDIF
      ENDIF

   ELSEIF msg == WM_MOUSEWHEEL
      n := Iif( ( n := hwg_HiWord( wParam ) ) > 32768, n - 65535, n )
      IF Hwg_BitAnd( hwg_LoWord( wParam ), MK_MBUTTON ) != 0
         IF n > 0
            ::PageUp()
         ELSE
            ::PageDown()
         ENDIF
      ELSE
         IF n > 0
            ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), 2 )
            ::LineUp()
         ELSE
            ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), ::nHeight - 2 )
            ::LineDown()
         ENDIF
      ENDIF

   ELSEIF msg == WM_MOUSEACTIVATE
      //hced_SetFocus( ::hEdit )
      hwg_SetFocus( ::handle )
      lRes := MA_ACTIVATE

   ELSEIF msg == WM_SETFOCUS
      IF ::bGetFocus != Nil
         Eval( ::bGetFocus, Self )
      ENDIF
      hced_InitCaret( ::hEdit )
      ::nCaret ++
      ::SetCaretPos( SETC_XY )
      lRes := 0

   ELSEIF msg == WM_KILLFOCUS
      IF ::bLostFocus != Nil
         Eval( ::bLostFocus, Self )
      ENDIF
      hced_KillCaret( ::hEdit )
      ::nCaret := 0
      lRes := 0

   ELSEIF msg == WM_LBUTTONDBLCLK
      IF ::bClickDoub != Nil
         Eval( ::bClickDoub, Self )
      ENDIF

   ELSEIF msg == WM_SIZE
      IF ::nHeight > 0 .AND. ::nWidth > 0
         ::Scan()
         ::nWCharF := ::nWSublF := 1
#ifdef __GTK__
         IF ::lPainted
#endif
            ::Paint( .F. )

            x := ::aPointC[P_X]
            IF ( n := hced_P2Screen( Self, ::aPointC[P_Y], @x ) ) < 0
               n := 1; x := 1
            ELSEIF n > ::nLines
               n := ::nLines; x := 1
            ENDIF
            ::SetCaretPos( SETC_XYPOS, x, n )
#ifdef __GTK__
         ENDIF
#endif
         //hced_Invalidaterect( ::hEdit, 0, 0, 0, ::nClientWidth, ::nHeight )
         hwg_Invalidaterect( ::handle, 0, 0, 0, ::nClientWidth, ::nHeight )
      ENDIF

   ELSEIF msg == WM_DESTROY
      ::End( .T. )

   ENDIF

   IF aPointC[P_X] != ::aPointC[P_X] .OR. aPointC[P_Y] != ::aPointC[P_Y]
      IF !Empty( ::oTrack )
         n := Iif( ::nLines > 0, Int( ::nHeight/( ::aLines[1,AL_Y2] - ::aLines[1,AL_Y1] ) ), 0 )
         nLinesAll := ::nLinesAll - n + 2
         IF ::lWrap
            n := (hced_LineNum(Self,1)-1) / nLinesAll
         ELSE
            n := (::nLineF-1) / nLinesAll
         ENDIF
         ::oTrack:Value := n
      ENDIF
      IF ::bChangePos != Nil
         Eval( ::bChangePos, Self )
      ENDIF
   ENDIF

   IF ::bAfter != Nil
      n := Eval( ::bAfter,Self,msg,wParam,lParam )
      IF n != - 1
         RETURN n
      ENDIF
   ENDIF

   RETURN lRes

METHOD Paint( lReal ) CLASS HCEdit
   LOCAL pps, hDCReal, hDC, aCoors, nLine := 0, yPos := ::nBoundT, yNew, n4Separ := ::n4Separ
   LOCAL nDocWidth
#ifndef __GTK__
   LOCAL hBitmap
#endif

   IF Empty( ::nDocFormat )
      ::nDocWidth := nDocWidth := 0
   ELSE
      ::nMarginL := Round( ::aDocMargins[1] * ::nKoeffScr, 0 )
      ::nMarginR := Round( ::aDocMargins[2] * ::nKoeffScr, 0 )
      ::nDocWidth := nDocWidth := Int( ::nKoeffScr * HPrinter():aPaper[ ::nDocFormat, Iif(::nDocOrient==0,2,3) ] ) - ::nMarginR
   ENDIF

   IF lReal == Nil .OR. lReal
#ifdef __GTK__
      ::lPainted := .T.
      IF ::lNeedScan
         ::Scan()
      ENDIF
#endif
      pps := hwg_DefinePaintStru()
#ifdef __GTK__
      hDCReal := hwg_BeginPaint( ::handle, pps )
      aCoors := hwg_GetClientRect( ::handle )
      hDC := hDCReal
      IF ::nShiftL > 0
         hwg_cairo_translate( hDC, -::nShiftL, 0 )
      ENDIF
#else
      hDCReal := hwg_BeginPaint( ::handle, pps )
      aCoors := hwg_GetClientRect( ::handle )

      hDC := hwg_CreateCompatibleDC( hDCReal )
      hBitmap := hwg_CreateCompatibleBitmap( hDCReal, ;
            Iif( !Empty(nDocWidth), Max(nDocWidth,aCoors[3]-aCoors[1])+::nShiftL, aCoors[3]-aCoors[1] ), aCoors[4]-aCoors[2] )
      hwg_Selectobject( hDC, hBitmap )

#endif
      ::nClientWidth := aCoors[3] - aCoors[1]
      lReal := .T.
   ELSE
      hDCReal := hwg_Getdc( ::handle )
      hDC := hDCReal
   ENDIF

   ::nBoundR := Iif( !Empty(nDocWidth), nDocWidth, ::nClientWidth ) - ::nPadding
   hced_Setcolor( ::hEdit, ::tcolor, ::bColor )
   hced_SetPaint( ::hEdit, hDC,, ::nClientWidth, ::lWrap,, nDocWidth )
   IF lReal
      IF !Empty( nDocWidth )
         hced_Setcolor( ::hEdit,, ::nClrDesk )
         IF ::nBoundL > 0
            hced_FillRect( ::hEdit, 0, 0, ::nBoundL, ::nHeight )
         ENDIF
         IF ::nDocWidth+::nMarginR-::nShiftL < ::nClientWidth
            hced_FillRect( ::hEdit, nDocWidth+::nMarginR, 0, ::nClientWidth+::nShiftL, ::nHeight )
         ENDIF
         hced_Setcolor( ::hEdit,, ::bColor )
         hced_FillRect( ::hEdit, ::nBoundL, 0, Iif( ::nDocWidth+::nMarginR-::nShiftL < ::nClientWidth, ;
               nDocWidth+::nMarginR,::nClientWidth ), ::nHeight )
      ELSE
         hced_FillRect( ::hEdit, 0, 0, ::nClientWidth, ::nHeight )
      ENDIF
   ENDIF

   IF ::lShowNumbers
      ::n4Number := hwg_GetTextSize( hDC, "55555" )[1]
      ::n4Separ := ::n4Number + 8
   ELSE
      ::n4Number := ::n4Separ := 0
   ENDIF
   IF ::bPaint != Nil
      Eval( ::bPaint, Self, hDC )
   ENDIF

   ::nLines := 0
   IF !Empty( ::aText )
      DO WHILE ( ++nLine + ::nLineF - 1 ) <= ::nTextLen

         yNew := ::PaintLine( Iif( lReal, hDC, Nil ), yPos, nLine, .T., ::nBoundR )

         //IF yNew + ( ::aLines[nLine,AL_Y2] - ::aLines[nLine,AL_Y1] ) > ::nHeight
         IF yNew + BOTTOM_HEIGHT > ::nHeight
            EXIT
         ENDIF
         yPos := yNew
      ENDDO
   ENDIF

   IF lReal
      //hced_FillRect( ::hEdit, 0, yNew, ::nClientWidth, ::nHeight )
      IF ::n4Separ > 0
         hwg_Selectobject( hDC, ::oPenNum:handle )
         hwg_Drawline( hDC, ::nBoundL + ::nMarginL + ::n4Separ - 4, 4, ::nBoundL + ::nMarginL + ::n4Separ - 4, ::nHeight - 8 )
      ENDIF
   ENDIF

   IF lReal
#ifdef __GTK__
      //hced_drawBorder( ::hEdit, ::nWidth, ::nHeight )
      //hwg_BitBlt( hDCReal, 0, 0, aCoors[3] - aCoors[1], aCoors[4] - aCoors[2], hDC )
      //hwg_ReleaseDC( , hDC )
#else
      hwg_BitBlt( hDCReal, 0, 0, aCoors[3] - aCoors[1], aCoors[4] - aCoors[2], hDC, ::nShiftL, 0, SRCCOPY )
      hwg_DeleteDC( hDC )
      hwg_DeleteObject( hBitmap )
#endif
      hwg_EndPaint( ::handle, pps )
   ELSE
      hwg_Releasedc( ::handle, hDCReal )
   ENDIF
   IF ::lSetFocus
      //hced_SetFocus( ::hEdit )
      hwg_SetFocus( ::handle )
      ::lSetFocus := .F.
   ENDIF
   IF n4Separ != ::n4Separ
      ::SetCaretPos( SETC_XY )
   ENDIF

   RETURN Nil

/* Added: nRight */
METHOD PaintLine( hDC, yPos, nLine, lUse_aWrap, nRight ) CLASS HCEdit
   LOCAL lReal := !Empty( hDC ), i, nPrinted, x1, x2, cLine, aLine, nTextLine := ::nLineF+nLine-1
   LOCAL nWCharF := Iif( ::lWrap.AND.nLine==1, ::nWCharF, ::nPosF ), nWSublF := Iif( ::lWrap.AND.nLine==1, ::nWSublF, 1 ), num := ::nLines+1

   IF lUse_aWrap == Nil; lUse_aWrap := .F.; ENDIF
   IF nRight == Nil; nRight := ::nClientWidth; ENDIF

   DO WHILE .T.

      ::nLines ++
      x1 := ::nBoundL + ::nMarginL + ::n4Separ + Iif( nWSublF==1, ::nIndent, 0 )
      x2 := ::nBoundR - ::nMarginR

      IF ::nLines >= Len( ::aLines )
         ::aLines := ASize( ::aLines, Len( ::aLines ) + 16 )
         FOR i := 0 TO 15
            ::aLines[Len(::aLines)-i] := Array( AL_LENGTH )
         NEXT
      ENDIF

      IF lReal .AND. ::nLines == ::nLineC .AND. ::bColorCur != ::bColor
         hced_SetColor( ::hEdit, ::tcolor, ::bColorCur )
      ENDIF

      aLine := ::aLines[::nLines]
      aLine[AL_Y1] := yPos
      aLine[AL_LINE] := nTextLine
      aLine[AL_FIRSTC] := nWCharF
      IF ::lWrap .AND. ( lReal .OR. lUse_aWrap )
         nPrinted := hced_Len(Self,::aText[nTextLine])
         IF ::aWrap[nTextLine] != Nil
            nPrinted := Iif( Len(::aWrap[nTextLine])>=nWSublF,::aWrap[nTextLine,nWSublF],nPrinted+1 ) - ;
                  Iif( nWSublF==1,1,::aWrap[nTextLine,nWSublF-1] )
         ENDIF
         cLine := hced_Substr( Self, ::aText[nTextLine], nWCharF, nPrinted )
         ::MarkLine( nLine, lReal, nWSublF, nWCharF, ::nLines )
         hced_LineOut( ::hEdit, @x1, @yPos, @x2, cLine, nPrinted, ::nAlign, Iif(lReal,nRight,0), .F. )
      ELSE
         IF ::lWrap
            cLine := Iif( nWCharF == 1, ::aText[nTextLine], hced_Substr( Self, ::aText[nTextLine],nWCharF ) )
         ELSE
            cLine := Iif( ::nPosF == 1, ::aText[nTextLine], hced_Substr( Self, ::aText[nTextLine],::nPosF ) )
         ENDIF

         ::MarkLine( nLine, lReal, Iif( ::lWrap, nWSublF, Nil), nWCharF, ::nLines )
         nPrinted := hced_LineOut( ::hEdit, @x1, @yPos, @x2, cLine, hced_Len( Self, cLine ), ::nAlign, Iif(lReal,nRight,0) )
      ENDIF

      aLine[AL_X1] := x1
      aLine[AL_X2] := x2
      aLine[AL_NCHARS] := nPrinted
      aLine[AL_Y2] := yPos

      IF lReal .AND. x1 > 0
         //hced_FillRect( ::hEdit, ::nBoundL, aLine[AL_Y1], x1, yPos )
      ENDIF
      IF lReal .AND. ::bPaint != Nil
         Eval( ::bPaint, Self, hDC, nTextLine, aLine[AL_Y1], yPos  )
      ENDIF

      IF lReal .AND. ::nLines == ::nLineC .AND. ::bColorCur != ::bColor
         hced_SetColor( ::hEdit, ::tcolor, ::bColor )
      ENDIF

      IF ::lWrap
         aLine[AL_SUBL] := nWSublF
         IF nWCharF + nPrinted - 1 >= hced_Len( Self, ::aText[nTextLine] )
            EXIT
         ELSE
            nWCharF += nPrinted
            nWSublF ++
         ENDIF
         IF ::nLines > 1 .AND. yPos + BOTTOM_HEIGHT > ::nHeight
            EXIT
         ENDIF
      ELSE
         EXIT
      ENDIF
   ENDDO

   IF lReal .AND. ::lShowNumbers
      hwg_Selectobject( hDC, ::oFont:handle )
      hced_SetColor( ::hEdit, ::tcolor )
      hwg_Settransparentmode( hDC, .T. )
      hwg_Drawtext( hDC, Str( nTextLine,4 ), ::nBoundL + ::nMarginL, ;
         ::aLines[num,AL_Y1], ::nBoundL + ::nMarginL + ::n4Number, ;
         ::aLines[num,AL_Y2], DT_RIGHT )
      hwg_Settransparentmode( hDC, .F. )
   ENDIF

   RETURN yPos

/* Added: nWCharF, nLineC */
METHOD MarkLine( nLine, lReal, nSubLine, nWCharF, nLineC ) CLASS HCEdit
   LOCAL nPos1, nPos2, x1, x2, i, aStru, nL := ::nLineF + nLine - 1, P1, P2, aHili
   LOCAL bColor && := 0

   hced_ClearAttr( ::hEdit )

   IF nLineC == Nil; nLineC := 0; ENDIF
   nPos1 := Iif( nWCharF!=Nil, nWCharF, Iif( ::lWrap .AND. !Empty(::aWrap[nL]), ;
         Iif(nSubLine==1,1,::aWrap[nL,nSubline-1]), ::nPosF ) )
   nPos2 := Iif( ::lWrap .AND. !Empty(::aWrap[nL]).AND.nSubLine<Len(::aWrap[nL]), ;
         ::aWrap[nL,nSubline]-1, Min( hced_Len(Self,::aText[nL]),STRING_MAX_LEN ) )

   IF !Empty( ::oHili )
      IF Empty( nSubLine ) .OR. nSubLine == 1 .OR. nL != ::oHili:nLine
         ::oHili:Do( Self, nL )
      ENDIF
      IF ::nDefFont > 0
         hced_setAttr( ::hEdit, 1, nPos2, ::nDefFont, 0, 0 )
         hced_addAttrFont( ::hEdit, ::nDefFont )
      ENDIF
      IF ::oHili:nItems > 0
         aStru := ::oHili:aLineStru
         FOR i := 1 TO ::oHili:nItems
            IF aStru[i,2] > 0 .AND. hb_hHaskey( ::aHili,aStru[i,3] )
               aHili := ::aHili[aStru[i,3]]
               IF aHili[1] > 0
                  hced_addAttrFont( ::hEdit, aHili[1] )
               ENDIF
               IF aStru[i,2] >= nPos1 .AND. aStru[i,1] <= nPos2
                  x1 := Max( nPos1, aStru[i,1] ) - nPos1 + 1
                  x2 := Min( aStru[i,2],nPos2 ) - nPos1 + 1
                  bColor := Iif( nLineC == ::nLineC .AND. ::bColorCur != ::bColor, ;
                     ::bColorCur, Iif( aHili[3]==Nil, ::bColor, aHili[3] ) )
                  hced_setAttr( ::hEdit, x1, x2 - x1 + 1, aHili[1], ;
                     Iif( aHili[2]==Nil, ::tColor, aHili[2] ), bColor )
               ENDIF
            ENDIF
         NEXT
      ENDIF
   ENDIF

   IF lReal .AND. !Empty( ::aPointM2[P_Y] )
      nPos2 ++
      IF ::PCmp( ::aPointM1, ::aPointM2 ) >= 0
         P2 := ::PCopy( ::aPointM1 )
         P1 := ::PCopy( ::aPointM2 )
      ELSE
         P2 := ::PCopy( ::aPointM2 )
         P1 := ::PCopy( ::aPointM1 )
      ENDIF
      IF ( P2[P_Y] := hced_P2Screen( Self, P2[P_Y], @P2[P_X] ) ) <= 0
         RETURN Nil
      ENDIF
      IF ( P1[P_Y] := hced_P2Screen( Self, P1[P_Y], @P1[P_X] ) ) > ::nLines
         RETURN Nil
      ENDIF
      IF ::lWrap
         nLine := hced_P2Screen( Self, nL, @nPos1 )
      ENDIF
      IF ( P1[P_Y] == P2[P_Y] )
         IF P1[P_Y] == nLine
            x1 := P1[P_X] - ::nPosF + 1
            x2 := P2[P_X] - ::nPosF + 1
         ELSE
            RETURN Nil
         ENDIF
      ELSE
         IF P1[P_Y] == nLine
            x1 := P1[P_X] - nPos1 + 1
            x2 := nPos2 - nPos1 + 1
         ELSEIF P2[P_Y] == nLine
            x1 := 1
            x2 := P2[P_X] - nPos1 + 1
         ELSEIF P2[P_Y] > nLine .AND. nLine > P1[P_Y]
            x1 := 1
            x2 := nPos2 - nPos1 + 1
         ELSE
            RETURN Nil
         ENDIF
      ENDIF
      IF x1 <= Len( ::aText[nL] )
         IF x2 > Len( ::aText[nL] ) .OR. x2 <= 0
            x2 := Len( ::aText[nL] ) + 1
         ENDIF
         hced_setAttr( ::hEdit, x1, x2 - x1, - 1, ::tColorSel, ::bColorSel )
      ENDIF
   ENDIF

   RETURN Nil

METHOD End(  ) CLASS HCEdit

   //hwg_writelog( "-------" )
   //hwg_writelog( hwg_trace() )
   IF !Empty( ::oHili )
      ::oHili:End()
      ::oHili := Nil
   ENDIF
   IF /* !Empty( l ) .AND. */ !Empty( ::hEdit )
      hced_Release( ::hEdit )
      ::hEdit := Nil
   ENDIF

   RETURN Nil

METHOD Convert( cPageIn, cPageOut )
   LOCAL i
   LOCAL l := ( cPageIn != Nil .AND. !Empty( hb_cdpUniId( cPageIn ) ) .AND. ;
         cPageOut != Nil .AND. !Empty( hb_cdpUniId( cPageOut ) ) .AND. ;
         !( cPageIn == cPageOut ) )
   IF l .OR. ::lTabs
      FOR i := 1 TO ::nTextLen
         IF !Empty( ::aText[i] )
            IF l
               ::aText[i] := hb_Translate( ::aText[i], cPageIn, cPageOut )
            ENDIF
            IF ::lTabs .AND. Chr(9) $ ::aText[i]
               ::aText[i] := Strtran( ::aText[i], Chr(9), Space(::nTablen) )
            ENDIF
         ENDIF
      NEXT
      RETURN .T.
   ENDIF

   RETURN .F.

METHOD SetText( xText, cPageIn, cPageOut ) CLASS HCEdit

   LOCAL nPos, i, c

   ::nLines := ::nShiftL := 0

   IF Empty( xText )
      ::aText := { "" }
   ELSEIF Valtype( xText ) == "A"
      ::aText := xText
   ELSE
      IF ( nPos := At( Chr(10), xText ) ) == 0
         ::aText := hb_aTokens( xText, Chr(13) )
      ELSEIF Substr( xText,nPos-1,1 ) == Chr(13)
         ::aText := hb_aTokens( xText, cNewLine )
      ELSE
         ::aText := hb_aTokens( xText, Chr(10) )
      ENDIF
   ENDIF
   ::nTextLen := Len( ::aText )
   DO WHILE ::aText[::nTextLen] == Nil; ::nTextLen--; ENDDO

   FOR i := 1 TO ::nTextLen
      IF ( c := Right(::aText[i],1) ) == Chr(13) .OR. c == Chr(10)
         ::aText[i] := Left( ::aText[i],Len(::aText[i])-1 )
      ENDIF
      IF ( c := Left(::aText[i],1) ) == Chr(13) .OR. c == Chr(10)
         ::aText[i] := Substr( ::aText[i],2 )
      ENDIF
   NEXT

   ::nLinesAll := ::nTextLen
   ::aUndo := Nil

   ::SetWrap( ::lWrap, .T. )

#ifndef __PLATFORM__WINDOWS
   ::lUtf8 := .T.
   ::Convert( cPageIn := Iif( Empty(cPageIn), "UTF8",cPageIn ), cPageOut := "UTF8" )
#else
   ::Convert( cPageIn, cPageOut )
#endif
   ::cpSource := cPageIn
   ::cp := cPageOut

   ::nLineF := ::nLineC := ::nPosF := ::nPosC := ::nWCharF := ::nWSublF := 1
   ::PCopy( { ::nPosC, ::nLineC }, ::aPointC )
   ::PCopy( , ::aPointM1 )
   ::PCopy( , ::aPointM2 )
   IF !Empty( ::oTrack )
      ::oTrack:Value := 0
   ENDIF
   ::lSetFocus := .T.
   IF ::lInit
      //hwg_Invalidaterect( ::handle, 0 )
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF

   RETURN Nil

/* Added: cpSou */
METHOD Save( cFileName, cpSou ) CLASS HCEdit
   LOCAL nHand, i, cLine

   IF Empty( cFileName )
      cFileName := ::cFileName
   ELSE
      ::cFileName := cFileName
   ENDIF

   IF !Empty( cFileName )
      IF ( nHand := FCreate( ::cFileName := cFileName ) ) == -1
         RETURN .F.
      ENDIF

      IF Empty( cpSou )
         cpSou := ::cpSource
      ENDIF
      FOR i := 1 TO ::nTextLen
         cLine := Iif( ::lStripSpaces, Trim(::aText[i] ), ::aText[i] )
         FWrite( nHand, Iif( !Empty(cpSou), hb_Translate( cLine, ::cp, cpSou ), cLine )  + cNewLine )
      NEXT
      FClose( nHand )
   ENDIF

   RETURN Nil

METHOD AddFont( oFont, name, width, height , weight, ;
      CharSet, Italic, Underline, StrikeOut ) CLASS HCEdit
   LOCAL i

   IF oFont != Nil
      name := oFont:name
      width := oFont:width
      height := oFont:height
      weight := oFont:weight
      CharSet := oFont:CharSet
      Italic := oFont:Italic
      Underline := oFont:Underline
      StrikeOut := oFont:StrikeOut
   ENDIF

   IF Charset == Nil .AND. Len( ::aFonts ) > 0; Charset := ::aFonts[1]:CharSet; ENDIF
   FOR i := 1 TO Len( ::aFonts )
      IF ::aFonts[i]:name == name .AND.              ;
            ( ( Empty(::aFonts[i]:width) .AND. Empty(width) ) ;
            .OR. ::aFonts[i]:width == width ) .AND.  ;
            ::aFonts[i]:height == height .AND.       ;
            ( ::aFonts[i]:weight > 500 ) == ( weight > 500 ) .AND. ;
            ::aFonts[i]:CharSet == CharSet .AND.     ;
            ::aFonts[i]:Italic == Italic .AND.       ;
            ::aFonts[i]:Underline == Underline .AND. ;
            ::aFonts[i]:StrikeOut == StrikeOut
         RETURN i
      ENDIF
   NEXT

   IF oFont == Nil
      oFont := HFont():Add( name, width, height , weight, ;
         CharSet, Italic, Underline, StrikeOut,, .T. )
   ENDIF
   hced_AddFont( ::hEdit, oFont:handle )
   AAdd( ::aFonts, oFont )

   RETURN Len( ::aFonts )

METHOD SetFont( oFont ) CLASS HCEdit
   LOCAL i, oFont1, name, height

   IF Len( ::aFonts ) > 1
      FOR i := 2 TO Len( ::aFonts )
         name := Iif( ::oFont:name == ::aFonts[i]:name, oFont:name, ::aFonts[i]:name )
         height := Iif( ::oFont:height == ::aFonts[i]:height, oFont:height, Int( ::aFonts[i]:height*oFont:height/::oFont:height) )
         oFont1 := HFont():Add( name, ::aFonts[i]:width, height , ::aFonts[i]:weight, ;
            ::aFonts[i]:CharSet, ::aFonts[i]:Italic, ::aFonts[i]:Underline, ::aFonts[i]:StrikeOut,, .T. )
         ::aFonts[i] := oFont1
         hced_SetFont( ::hEdit, oFont1:handle, i )
      NEXT
   ENDIF
   IF Empty( ::aFonts )
      ::AddFont( ::oFont )
   ENDIF
   ::aFonts[1] := oFont
   hced_SetFont( ::hEdit, oFont:handle, 1 )
   ::oFont := oFont
   ::Refresh()

   RETURN Nil

METHOD SetCaretPos( nType, p1, p2 ) CLASS HCEdit
   LOCAL lSet := .T. , lInfo := .F., x1, y1, xPos, cLine, nLinePrev := ::nLineC

   //::lChgCaret := .T.
   IF Empty( nType ) .OR. Empty( ::nLines )
      hced_SetCaretPos( ::hEdit, ::nBoundL + ::nMarginL + ::n4Separ, 0 )
      RETURN Nil
   ENDIF
   IF nType > 200
      nType -= 100
      lInfo := .T.
   ENDIF
   IF nType > 100
      nType -= 100
      lSet := .F.
   ENDIF
   IF nType == SETC_COORS
      xPos := p1
      IF ( y1 := hced_Line4Pos( Self, p2 ) ) == 0
         RETURN Nil
      ENDIF
      ::nLineC := y1
   ELSEIF nType == SETC_RIGHT
      x1 := ::nPosC
   ELSEIF nType == SETC_LEFT
      x1 := ::nPosC - 2
   ELSEIF nType == SETC_XY
      x1 := ::nPosC - 1
   ELSEIF nType == SETC_XYPOS
      x1 := p1 - 1
      ::nLineC := p2
   ELSEIF nType == SETC_XFIRST
      x1 := 0
   ELSEIF nType == SETC_XCURR
      xPos := hced_GetXCaretPos( ::hEdit )
   ELSEIF nType == SETC_XLAST
      xPos := ::nClientWidth
   ENDIF
   //hwg_writelog( str(::nLineC)+" "+str(::nLineF)+ " "+valtype(::aLines[::nLineC,AL_LINE]) )
   ::MarkLine( Iif( ::lWrap, ::aLines[::nLineC,AL_LINE]-::nLineF+1, ::nLineC ), .F., Iif( ::lWrap, hced_SubLine( Self, ::nLineC ), Nil ) )
   IF x1 == Nil
      xPos += ::nShiftL
      cLine := hced_SubLine( Self, ::nLineC, SB_TEXT )
      IF ::nPosF > 1
         cLine := hced_Substr( Self, cLine, ::nPosF )
      ENDIF
      x1 := hced_ExactCaretPos( ::hEdit, cLine, ::aLines[::nLineC,AL_X1], ;
         Iif(Empty(xPos),::nBoundL,xPos), ::aLines[::nLineC,AL_Y1], lSet, ::nShiftL )
   ELSE
      cLine := Iif( x1 == 0, "", hced_Substr( Self, hced_SubLine( Self, ::nLineC, SB_TEXT ),::nPosF, x1 ) )
      x1 := hced_ExactCaretPos( ::hEdit, ;
         Iif( hced_Len( Self, cLine ) <= x1, cLine, hced_Left( Self, cLine, x1 ) ), ;
         ::aLines[::nLineC,AL_X1], - 1, ::aLines[::nLineC,AL_Y1], lSet, ::nShiftL )
   ENDIF
   ::nPosC := x1
   IF ::lWrap
      ::PCopy( { ::aLines[::nLineC,AL_FIRSTC] + ::nPosF + x1 - 2, ::aLines[::nLineC,AL_LINE] }, ::aPointC )
   ELSE
      ::PCopy( { ::nPosF + x1 - 1, ::nLineF + ::nLineC - 1 }, ::aPointC )
   ENDIF

   IF !lInfo
      IF nLinePrev != ::nLineC
         IF nLinePrev <= ::nLines
            //hced_Invalidaterect( ::hEdit, 0, 0, ::aLines[nLinePrev,AL_Y1], ::nClientWidth, ;
            //   ::aLines[nLinePrev,AL_Y2] )
            hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLinePrev,AL_Y1], ::nClientWidth, ;
               ::aLines[nLinePrev,AL_Y2] )
         ENDIF
         //hced_Invalidaterect( ::hEdit, 0, 0, ::aLines[::nLineC,AL_Y1], ::nClientWidth, ;
         //   ::aLines[::nLineC,AL_Y2] )
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ::nClientWidth, ;
            ::aLines[::nLineC,AL_Y2] )
#ifdef __GTK__
      ELSE
         //hced_Invalidaterect( ::hEdit, 0, 0, ::aLines[nLinePrev,AL_Y1], ::nClientWidth, ;
         //   ::aLines[nLinePrev,AL_Y2] )
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLinePrev,AL_Y1], ::nClientWidth, ;
            ::aLines[nLinePrev,AL_Y2] )
#endif
      ENDIF
   ENDIF

   RETURN Nil

#define FBITCTRL   4
#define FBITSHIFT  3
#define FBITALT    9
#define FBITALTGR  65027


METHOD onKeyDown( nKeyCode, lParam, nCtrl ) CLASS HCEdit
   LOCAL cLine, lUnsel := .T., lInvAll := .F., n, l, ntmp1, ntmp2
   LOCAL nLine, nDocWidth := ::nDocWidth
#ifdef __GTK__
   LOCAL ln1 , ln2, ln3, ln4
#endif

   // Store for last key (needed by memo edit)
   ::nLastKey := nKeyCode
   /*
    Shift L: 65505 = 0xFFE1
    Shift R: 65506 = 0xFFE2
    Ctrl   : 65207 = 0xFEB7
    Alt    : 65513 = 0xFFE9
    AltGr  : 65027 = 0xFE03

    AltGr + Euro : keydown:      65027 /          0 FFFF
    AltGr + ~    : keydown:         -1 /          0 TTTT

   */

   IF nCtrl == Nil
      cLine := hwg_Getkeyboardstate( lParam )
      nCtrl := Iif( Asc( SubStr(cLine,0x12,1 ) ) >= 128, FCONTROL, 0 ) + ;
            Iif( Asc(SubStr(cLine,0x11,1 ) ) >= 128,FSHIFT,0 )

   ENDIF

#ifdef __GTK__
   ln1 := Iif(hwg_checkBit( nKeyCode, FBITSHIFT ) , .T., .F. )
   ln2 := Iif(hwg_checkBit( nKeyCode, FBITCTRL  ) , .T., .F. )
   ln3 := Iif(hwg_checkBit( nKeyCode, FBITALT   ) , .T., .F. )
   ln4 := Iif(hwg_checkBit( nKeyCode, FBITALTGR ) , .T., .F. )
#endif


   /*
      Output of this command:
                     ln1   ln2, ln3 ln4
      nKeyCode nctrl Shift Ctrl Alt AltGr
   */
   // hwg_writelog( "keydown: " + str(nKeyCode) + " / " + str(nctrl) +" "+Iif(hwg_checkBit( nKeyCode,FBITSHIFT ),"T","F")+Iif(hwg_checkBit( nKeyCode, FBITCTRL ),"T","F") + Iif(hwg_checkBit( nKeyCode, FBITALT), "T","F" ) + Iif(hwg_checkBit( nKeyCode, FBITALTGR) ,"T","F") )


   ::lSetFocus := .T.
   IF ::bKeyDown != Nil .AND. ( nLine := Eval( ::bKeyDown, Self, nKeyCode, nCtrl, 0 ) ) != -1
      RETURN nLine
   ENDIF
   IF ::nLines <= 0
      RETURN 0
   ENDIF
   nLine := ::nLineC
   IF ::nCaret <= 0
      ::nCaret := 1
      hced_ShowCaret( ::hEdit )
   ENDIF
   IF hwg_checkBit( nctrl,FBITSHIFT ) .AND. Empty( ::aPointM2[P_Y] ) .AND. ;
         Ascan( { VK_RIGHT, VK_LEFT, VK_HOME, VK_END, VK_DOWN, VK_UP, VK_PRIOR, VK_NEXT }, nKeyCode ) != 0
      ::PCopy( ::aPointC, ::aPointM1 )
   ENDIF
   /* ===== Handle special keys ===== */
#ifdef __GTK__
   IF (nKeyCode == -1) .AND. ln1 .AND. ln2 .AND. ln3 .AND. ln4  // AltGr + ~ (Tilde)
       ::putChar( 126 )  && nKeyCode
   ELSEIF nKeyCode == VK_RIGHT
#else
// Cursor right : This block catches AltGr + ~ (Tilde) , so ignored, Bug fixed (DF7BE)
   IF nKeyCode == VK_RIGHT
#endif
      n := Iif( hwg_checkBit( nctrl,FBITCTRL ), ::aLines[nLine,AL_NCHARS] - ::nPosC, 1 )
      l := .F.
      DO WHILE --n >= 0
         IF ::lWrap .AND. ::nDocFormat > 0 .AND. ::nShiftL+::nClientWidth < nDocWidth .AND. ;
               hced_GetXCaretPos( ::hEdit ) > ( ::nClientWidth-::nMarginR-10 )
            ::nShiftL += Int(::nClientWidth/4)
            IF ::nShiftL+::nClientWidth > nDocWidth
               ::nShiftL := nDocWidth - ::nClientWidth
            ENDIF
            lInvAll := .T.
         ELSEIF ::nPosC > ::aLines[nLine,AL_NCHARS]
            IF ::lWrap //.AND. ::nDocFormat == 0
               RETURN 0
            ENDIF
            IF hced_GetXCaretPos( ::hEdit ) > ( ::nClientWidth-::nMarginR-10 )
               ::nPosF ++
               ::Paint( .F. )
               lInvAll := .T.
            ENDIF
         ENDIF
         ::SetCaretPos( SETC_RIGHT )
         IF hced_SubStr( Self, ::aText[::aPointC[P_Y]], ::nPosF + ::nPosC -1, 1 ) == ' '
            l := .T.
         ELSEIF l
            EXIT
         ENDIF
      ENDDO
      IF hwg_checkBit( nctrl,FBITSHIFT )
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         //hced_Invalidaterect( ::hEdit, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
         //   ::aLines[nLine,AL_Y2] )
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
            ::aLines[nLine,AL_Y2] )
      ENDIF

   ELSEIF nKeyCode == VK_LEFT  // Cursor left
      n := Iif( hwg_checkBit( nctrl,FBITCTRL ), ::nPosC, 1 )
      ntmp1 := ntmp2 := ::nPosC
      l := .F.
      DO WHILE --n >= 0
         IF ::lWrap .AND. ::nDocFormat > 0 .AND. ::nShiftL > 0 .AND. hced_GetXCaretPos( ::hEdit ) < ( ::nMarginL+6 )
            ::nShiftL -= Min( Int(::nClientWidth/4), ::nShiftL )
            lInvAll := .T.
         ELSEIF ::nPosC > 1
            ::SetCaretPos( SETC_LEFT )
         ELSEIF ::nPosF > 1
            ::nPosF --
            ::Paint( .F. )
            lInvAll := .T.
         ENDIF
         IF hced_SubStr( Self, ::aText[::aPointC[P_Y]], ::nPosF + ::nPosC -1, 1 ) == ' '
            l := .T.
         ELSEIF l
            IF ntmp2 < ntmp1
               ::nPosC := ntmp2 - 1
               ::SetCaretPos( SETC_RIGHT )
               EXIT
            ELSE
               l := .F.
               ntmp2 := ::nPosC
            ENDIF
         ELSE
            ntmp2 := ::nPosC
         ENDIF
      ENDDO
      IF hwg_checkBit( nctrl,FBITSHIFT )
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         //hced_Invalidaterect( ::hEdit, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
         //   ::aLines[nLine,AL_Y2] )
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
            ::aLines[nLine,AL_Y2] )
      ENDIF
   ELSEIF nKeyCode == VK_HOME  // Home
      IF ::nPosF > 1 .OR. ::nShiftL > 0
         ::nPosF := 1
         ::nShiftL := 0
         ::Paint( .F. )
         lInvAll := .T.
      ENDIF
      ::SetCaretPos( SETC_XFIRST )
      IF hwg_checkBit( nctrl,FBITSHIFT )
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
            ::aLines[nLine,AL_Y2] )
      ENDIF
   ELSEIF nKeyCode == VK_END   // End
      IF ::lWrap .AND. ::nDocFormat > 0 .AND. ::nShiftL+::nClientWidth < nDocWidth
         ::nShiftL := nDocWidth - ::nClientWidth
         lInvAll := .T.
      ELSEIF !::lWrap .AND. ::aLines[nLine,AL_NCHARS] < hced_Len( Self, ::aText[::aLines[nLine,AL_LINE]] )
         ::nPosF := Max( Int( ( ( hced_Len( Self, ::aText[::aLines[nLine,AL_LINE]] ) - ;
               ::aLines[nLine,AL_NCHARS] ) ) * 7 / 6 ), 1 )
         ::Paint( .F. )
         lInvAll := .T.
      ENDIF
      ::SetCaretPos( SETC_XLAST )
      IF hwg_checkBit( nctrl,FBITSHIFT )
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
            ::aLines[nLine,AL_Y2] )
      ENDIF
   ELSEIF nKeyCode == VK_UP     // Cursor up
      ::LineUp()
      IF hwg_checkBit( nctrl,FBITSHIFT )
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         IF Len( ::aLines ) > ::nLineC
            hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ::nClientWidth, ;
               ::aLines[::nLineC+1,AL_Y2] )
         ENDIF
      ENDIF
   ELSEIF nKeyCode == VK_DOWN   // Cursor down
      ::LineDown()
      IF hwg_checkBit( nctrl,FBITSHIFT ) .AND. ::nLineC > 1
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC-1,AL_Y1], ::nClientWidth, ;
            ::aLines[::nLineC,AL_Y2] )
      ENDIF
   ELSEIF nKeyCode == VK_NEXT    // Page Down
      IF hwg_checkBit( nctrl,FBITCTRL )
         ::Bottom()
      ELSE
         ::PageDown()
      ENDIF
      IF hwg_checkBit( nctrl,FBITSHIFT )
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         lInvAll := .T.
      ENDIF
   ELSEIF nKeyCode == VK_PRIOR    // Page Up
      IF hwg_checkBit( nctrl,FBITCTRL )
         ::Top()
      ELSE
         ::PageUp()
      ENDIF
      IF hwg_checkBit( nctrl,FBITSHIFT )
         ::PCopy( ::aPointC, ::aPointM2 )
         lUnSel := .F.
         lInvAll := .T.
      ENDIF
   ELSEIF nKeyCode == VK_DELETE   // Delete
      IF hwg_checkBit( nctrl,FBITSHIFT ) .AND. !Empty( ::aPointM2[P_Y] )
         cLine := ::GetText( ::aPointM1, ::aPointM2 )
         hwg_Copystringtoclipboard( cLine )
      ENDIF
      ::putChar( 7 )   // for to not interfere with '.'

   ELSEIF nKeyCode == VK_INSERT   // Insert
      IF nCtrl == 0
         ::lInsert := !::lInsert
         lUnSel := .F.

      ELSEIF hwg_checkBit( nctrl,FBITCTRL )
         IF !Empty( ::aPointM2[P_Y] )
            cLine := ::GetText( ::aPointM1, ::aPointM2 )
            hwg_Copystringtoclipboard( cLine )
         ENDIF
         lUnSel := .F.
      ELSEIF hwg_checkBit( nctrl,FBITSHIFT )
         IF !::lReadOnly .AND. !::lNoPaste
            cLine := hwg_Getclipboardtext()
            IF Chr(9) $ cLine
               cLine := Strtran( cLine, Chr(9), Space(::nTablen) )
            ENDIF
            ::InsText( ::aPointC, cLine )
            hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ;
               ::nHeight )
         ENDIF
      ENDIF

   ELSEIF ( nKeyCode == 89 .OR. nKeyCode == 121 ) .AND. hwg_checkBit( nctrl,FBITCTRL )  // 'Y'
      IF ::lWrap //.AND. ::aWrap[::nLineF+nLine-1] != Nil
         //::DelText( {::aWrap[nLine-1],::nLineF+nLine-1}, {1,::nLineF+nLine-1} )
      ELSE
         ::DelText( {1,::nLineF+nLine-1}, {1,::nLineF+nLine} )
      ENDIF
   ELSEIF ( nKeyCode == 65 .OR. nKeyCode == 97 ) .AND. hwg_checkBit( nctrl,FBITCTRL )   // 'A'
      ::Pcopy( { 1, 1 }, ::aPointM1 )
      ::Pcopy( { hced_Len( Self, ::aText[::nTextLen] ) + 1, ::nTextLen }, ::aPointM2 )
      lUnSel := .F.
      lInvAll := .T.
   ELSEIF ( nKeyCode == 67 .OR. nKeyCode == 99 ) .AND. hwg_checkBit( nctrl,FBITCTRL )   // 'C'
      IF !Empty( ::aPointM2[P_Y] )
         cLine := ::GetText( ::aPointM1, ::aPointM2 )
         hwg_Copystringtoclipboard( cLine )
         lUnSel := .F.
      ENDIF
   ELSEIF ( nKeyCode == 90 .OR. nKeyCode == 122 ) .AND. hwg_checkBit( nctrl,FBITCTRL )  // 'Z'
      ::Undo()
   ELSEIF ( nKeyCode == 86 .OR. nKeyCode == 118 ) .AND. hwg_checkBit( nctrl,FBITCTRL )  // 'V'
      IF !::lReadOnly .AND. !::lNoPaste
         cLine := hwg_Getclipboardtext()
         IF Chr(9) $ cLine
            cLine := Strtran( cLine, Chr(9), Space(::nTablen) )
         ENDIF
         ::InsText( ::aPointC, cLine )
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[nLine,AL_Y1], ::nClientWidth, ::nHeight )
      ENDIF
   ELSEIF ( nKeyCode == 88 .OR. nKeyCode == 120 ) .AND. hwg_checkBit( nctrl,FBITCTRL )  // 'X'
      IF !Empty( ::aPointM2[P_Y] )
         cLine := ::GetText( ::aPointM1, ::aPointM2 )
         hwg_Copystringtoclipboard( cLine )
         ::putChar( 7 )   // for to not interfere with '.'
      ENDIF
#ifdef __GTK__
   ELSEIF nKeyCode < 0xFE00 .OR. ( nKeyCode >= GDK_KP_Multiply .AND. nKeyCode <= GDK_KP_9 ) ;
         .OR. nKeyCode == VK_RETURN .OR. nKeyCode == VK_BACK .OR. nKeyCode == VK_TAB .OR. nKeyCode == VK_ESCAPE
      IF hwg_bitand( lParam, GDK_CONTROL_MASK+GDK_MOD1_MASK ) == 0
         IF nKeyCode >= GDK_KP_0
            nKeyCode -= ( GDK_KP_0 - 48 )
         ENDIF
         ::putChar( nKeyCode )
      ENDIF
#endif
   ENDIF
   IF !Empty( ::aPointM2[P_Y] ) .AND. nKeyCode >= 32 .AND. nKeyCode < 0xFF60 .AND. ;
         !( nKeyCode>=VK_F1 .AND. nKeyCode<=VK_F12 ) .AND. lUnSel
      nLine := ::aPointM2[P_Y]
      ::Pcopy( , ::aPointM2 )
      IF ::aPointM1[P_Y] < ::nLineF .OR. nLine - ::nLineF >= ::nLines
         lInvAll := .T.
      ENDIF
      IF !lInvAll
         hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::aPointM1[P_Y] - ::nLineF + 1, AL_Y1], ;
            ::nClientWidth, ::aLines[nLine - ::nLineF + 1, AL_Y2] )
      ENDIF
   ENDIF
   IF lInvAll
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF
   ::lSetFocus := .T.

   RETURN 0

METHOD PutChar( nKeyCode ) CLASS HCEdit
   LOCAL nLine, nPos
   * Variables not used
   * P1, x, y

   //hwg_writelog( "putchar: " + str(nKeyCode) )
   IF ::lReadOnly
      RETURN Nil
   ENDIF

   IF nKeyCode == VK_RETURN
      IF Empty( ::nMaxLines ) .OR. ::nMaxLines > ::nTextLen
         ::InsText( ::aPointC, cNewLine )
         ::nPosF := ::nPosC := 1
      ENDIF

   ELSEIF nKeyCode == VK_TAB
      IF ::lInsert
         ::InsText( ::aPointC, Space( ::nTabLen ) )
      ENDIF

   ELSEIF nKeyCode == VK_ESCAPE

   ELSEIF nKeyCode == VK_BACK .OR. nKeyCode == 7
      IF !Empty( ::aPointM2[P_Y] )  // there is text selected
         ::DelText( ::aPointM1, ::aPointM2 )
         ::Pcopy( , ::aPointM2 )
      ELSE
         nLine := ::aLines[::nLineC,AL_LINE]
         nPos := ::aLines[::nLineC,AL_FIRSTC] + ::nPosC - 1
         IF nKeyCode == VK_BACK
            IF nPos == 1
               IF --nLine <= 0
                  RETURN Nil
               ENDIF
               nPos := hced_Len( Self, ::aText[nLine] ) + 1
            ELSE
               nPos --
            ENDIF
         ENDIF
         IF nPos > hced_Len( Self, ::aText[nLine] )
            IF nLine < ::nTextLen
               ::DelText( { nPos, nLine }, { 1,nLine+1 } )
            ENDIF
         ELSE
            ::DelText( { nPos, nLine }, { nPos+1,nLine } )
         ENDIF
      ENDIF
   ELSE        // Insert or overwrite any character
      //hwg_writelog( str( nKeyCode ) + "/" + hced_Chr( Self,nKeyCode ) )
      ::InsText( ::aPointC, hced_Chr( Self,nKeyCode ), !::lInsert )
   ENDIF

   RETURN Nil

METHOD LineDown() CLASS HCEdit
   LOCAL y

   IF ::nLineC < ::nLines
      Return ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), ::aLines[::nLineC,AL_Y2] + 4 )
   ELSEIF !::lWrap .AND. ::nLineF + ::nLines - 1 < ::nTextLen
      ::nLineF ++
   ELSEIF ::lWrap .AND. ( ::aLines[::nLines,AL_LINE] < ::nTextLen .OR. ;
         ::aLines[::nLines,AL_FIRSTC]+::aLines[::nLines,AL_NCHARS] < hced_Len( Self,::aText[::nTextLen] ) )
      IF ::nLines > 1
         IF ::aLines[2,AL_FIRSTC] == 1
            ::nLineF ++
            ::nWCharF := ::nWSublF := 1
         ELSE
            ::nWCharF := ::aLines[2,AL_FIRSTC]
            ::nWSublF := hced_SubLine( Self, 2 )
         ENDIF
      ELSE
         ::nLineF ++
         ::nWCharF := ::nWSublF := 1
      ENDIF
   ELSE
      RETURN Nil
   ENDIF

   y := ::aLines[::nLineC,AL_Y2] - 4
   ::Paint( .F. )
   ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), y )
   hwg_Invalidaterect( ::handle, 0 )

   RETURN Nil

/* Added: lChgPos */
METHOD LineUp( lChgPos ) CLASS HCEdit
   LOCAL y
   * Variables not used
   *   i

   IF lChgPos == Nil; lChgPos := .T.; ENDIF

   IF ::nLineC > 1
      IF lChgPos
         ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), ::aLines[::nLineC,AL_Y1] - 4 )
      ENDIF
      RETURN Nil
   ELSEIF !::lWrap .AND. ::nLineF > 1
      ::nLineF --
   ELSEIF ::lWrap .AND. ( ::nLineF > 1 .OR. ::aLines[1,AL_SUBL] > 1 )
      IF ::aLines[1,AL_SUBL] == 1
         ::nLineF --
         IF !Empty( ::aWrap[::nLineF] )
            ::nWCharF := Atail( ::aWrap[::nLineF] )
            ::nWSublF := Len(::aWrap[::nLineF]) + 1
         ELSE
            ::nWCharF := ::nWSublF := 1
         ENDIF
      ELSE
         ::nWSublF --
         ::nWCharF := Iif( ::nWSublF==1, 1, ::aWrap[::nLineF,::nWSublF-1] )
      ENDIF
   ELSE
      RETURN Nil
   ENDIF

   IF lChgPos
      y := ::aLines[::nLineC,AL_Y2] - 4
      ::Paint( .F. )
      ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), y )
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF

   RETURN Nil

METHOD PageDown() CLASS HCEdit
   LOCAL y

   IF ::lWrap
      IF ::nLines == 1 .AND. ::nLineF + 1 < ::nTextLen
         ::nLineF ++
         ::nWCharF := ::nWSublF := 1
      ELSE
         //RETURN ::Bottom()

         ::nLineF := ::aLines[::nLines,AL_LINE]
         ::nWCharF := ::aLines[::nLines,AL_FIRSTC]
         ::nWSublF := ::aLines[::nLines,AL_SUBL]

      ENDIF
   ELSE
      IF ::aLines[::nLines,AL_LINE] < ::nTextLen
         ::nLineF += ::nLines - 1
      ELSE
         RETURN ::Bottom()
         //::nLineC := ::nLines
      ENDIF
   ENDIF
   y := ::aLines[::nLineC,AL_Y2] - 4
   ::Paint( .F. )
   ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), y )
   hwg_Invalidaterect( ::handle, 0 )

   RETURN Nil

METHOD PageUp() CLASS HCEdit
   LOCAL y, n, nWSublF

   IF ::nLineF > 1 .OR. ::nWSublF > 1

      n := Int( ::nHeight/ (::aLines[1,AL_Y2] - ::aLines[1,AL_Y1] ) )
      IF ::lWrap
         nWSublF := ::nWSublF
         FOR y := 1 TO n-1
            IF nWSublF > 1
               nWSublF --
            ELSEIF ::nLineF > 1
               ::nLineF --
               nWSublF := Iif( Empty(::aWrap[::nLineF]), 1, Len(::aWrap[::nLineF]) + 1 )
            ELSE
               EXIT
            ENDIF
         NEXT
         ::nWSublF := nWSublF
         ::nWCharF := Iif( Empty(::aWrap[::nLineF]) .OR. nWSublF==1, 1, ::aWrap[::nLineF,::nWSublF-1] )
      ELSE
         ::nLineF -= ( n - 1 )
         IF ::nLineF <= 0
            ::nLineF := 1
         ENDIF
      ENDIF

      y := ::aLines[::nLineC,AL_Y2] - 4
      ::Paint( .F. )
      ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), y )
      hwg_Invalidaterect( ::handle, 0 )
   ELSE
      ::Top()
   ENDIF

   RETURN Nil

METHOD Top() CLASS HCEdit

   IF ::nLineF != 1 .OR. ::nLineC != 1 .OR. ::nPosC != 1 .OR. ::nPosF != 1 .OR. ::nWCharF != 1
      ::nLineF := ::nLineC := ::nWCharF := ::nWSublF := 1
      ::nPosC := ::nPosF := 1

      ::Paint( .F. )

      ::SetCaretPos( SETC_COORS, 0, 0 )
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF

   RETURN Nil

METHOD Bottom() CLASS HCEdit
   LOCAL nNewF, nNewC, nWSublF, n, i

   n := Iif( ::nLines > 0, Max( 1, Int( ::nHeight/(::aLines[1,AL_Y2] - ::aLines[1,AL_Y1] ) ) ), 0 )
   IF n > ::nLinesAll
      nNewF := 1
      nNewC := ::nLinesAll
   ELSEIF ::lWrap
      nNewF := ::nTextLen
      nWSublF := Iif( Empty(::aWrap[nNewF]), 1, Len(::aWrap[nNewF]) + 1 )
      FOR i := 1 TO n-1
         IF nWSublF > 1
            nWSublF --
         ELSE
            nNewF --
            nWSublF := Iif( Empty(::aWrap[nNewF]), 1, Len(::aWrap[nNewF]) + 1 )
         ENDIF
      NEXT
      ::nWSublF := nWSublF
      ::nWCharF := Iif( Empty(::aWrap[nNewF]) .OR. nWSublF==1, 1, ::aWrap[nNewF,::nWSublF-1] )
      nNewC := n
   ELSE
      nNewF := Max( 1, ::nTextLen - n + 1 )
      nNewC := ::nTextLen - ::nLineF + 1
   ENDIF
   IF ::nLineF != nNewF .OR. ::nLineC != nNewC
      ::nLineF := nNewF
      ::nLineC := nNewC

      ::Paint( .F. )

      ::SetCaretPos( SETC_COORS, ::nClientWidth, ::nHeight )
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF

   RETURN Nil

METHOD GOTO( nLine ) CLASS HCEdit
   LOCAL n

   IF ::nLines <= 0 .AND. ::nTextLen > 2
      ::Paint( .F. )
   ENDIF
   IF ( n := Iif( ::nLines > 0, Int( ::nHeight/(::aLines[1,AL_Y2] - ::aLines[1,AL_Y1] ) ), 0 ) ) > 0
      ::nWCharF := ::nWSublF := 1
      IF ::lWrap
         ::nLineF := nLine
         ::nLineC := 1
         hwg_Invalidaterect( ::handle, 0 )
      ELSE
         IF nLine > ::nLineF .AND. nLine - ::nLineF + 1 < n
            hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ;
               ::nClientWidth, ::aLines[::nLineC,AL_Y2] )
            ::nLineC := nLine - ::nLineF + 1
            hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ;
               ::nClientWidth, ::aLines[::nLineC,AL_Y2] )
         ELSE
            ::nLineC := Min( Int( n/2 ), nLine )
            ::nLineF := nLine - ::nLineC + 1
            hwg_Invalidaterect( ::handle, 0 )
         ENDIF
      ENDIF
      ::SetCaretPos( SETC_XFIRST )
   ENDIF

   RETURN Nil

/*
METHOD onVScroll( wParam ) CLASS HCEdit
   LOCAL nCode := hwg_Loword( wParam ), nPos := hwg_Hiword( wParam )
   LOCAL n, nPages, i, nL

   IF ::nLines <= 0
      RETURN 0
   ENDIF
   IF nCode == SB_TOP
      ::Top()
   ELSEIF nCode == SB_BOTTOM
      ::Bottom()
   ELSEIF nCode == SB_LINEDOWN
      ::LineDown()
   ELSEIF nCode == SB_LINEUP
      ::LineUp()
   ELSEIF nCode == SB_PAGEDOWN
      ::PageDown()
   ELSEIF nCode == SB_PAGEUP
      ::PageUp()
   ELSEIF nCode = SB_THUMBPOSITION .OR. nCode = SB_THUMBTRACK
      n := Iif( ::nLines > 0, Int( ::nHeight/(::aLines[1,AL_Y2] - ::aLines[1,AL_Y1] ) ), 0 )
      IF n > 0
         nPages := Int( ::nLinesAll/n ) + 1
         //hwg_writelog( "    "+str(npos)+"/"+str(npages) )
         IF nPos == 0
            ::Top()
         ELSEIF nPos + 4 >= ( nPages-1 ) * 4
            ::Bottom()
         ELSE
            n := Min( Max( Int( nPos / ((nPages - 1 ) * 4 ) * ::nLinesAll ) - ::nLineC + 1, 1 ), ::nLinesAll )
            IF ::lWrap
               i := nL := 0
               DO WHILE ++i <= ::nTextLen
                  nL += Iif( Empty(::aWrap[i]), 1, Len(::aWrap[i])+1 )
                  IF nL >= n
                     EXIT
                  ENDIF
               ENDDO
               ::nLineF := i
               ::nWSublF := Iif( nL == n .OR. Empty(::aWrap[i]), 1, Len(::aWrap[i])-(nL-n)+2 )
               ::nWCharF := Iif( nL == n .OR. Empty(::aWrap[i]), 1, ::aWrap[i,Len(::aWrap[i])-(nL-n)+1] )
            ELSE
               ::nLineF := n
            ENDIF
            ::Paint( .F. )

            ::SetCaretPos( SETC_COORS, hced_GetXCaretPos( ::hEdit ), hced_GetYCaretPos( ::hEdit ) )
            hwg_Invalidaterect( ::handle, 0 )
         ENDIF
      ENDIF
   ENDIF

   RETURN 0
*/

METHOD PCopy( Psource, Pdest ) CLASS HCEdit

   IF Empty( Pdest )
      Pdest := Array( P_LENGTH )
   ENDIF
   IF !Empty( Psource )
      Pdest[P_X] := Psource[P_X]
      Pdest[P_Y] := Psource[P_Y]
   ELSE
      Pdest[P_X] := Pdest[P_Y] := 0
   ENDIF

   RETURN Pdest

METHOD PCmp( P1, P2 ) CLASS HCEdit

   IF P2[P_Y] > P1[P_Y] .OR. ( P2[P_Y] == P1[P_Y] .AND. P2[P_X] > P1[P_X] )
      RETURN - 1
   ELSEIF P1[P_Y] > P2[P_Y] .OR. ( P1[P_Y] == P2[P_Y] .AND. P1[P_X] > P2[P_X] )
      RETURN 1
   ENDIF

   RETURN 0

METHOD GetText( P1, P2, lTabs ) CLASS HCEdit
   LOCAL cText := "", Pstart, Pend, i, nPos1, cLine

   IF Empty( P1 )
      P1 := ::PCopy( {1,1}, P1 )
   ENDIF
   IF Empty( P2 )
      P2 := ::PCopy( {Len(::aText[::nTextLen])+1,::nTextLen}, P2 )
   ENDIF
   IF Empty( P1[P_Y] ) .OR. Empty( P2[P_Y] )
      RETURN ""
   ENDIF
   IF ::Pcmp( P1, P2 ) < 0
      Pstart := ::PCopy( P1, Pstart )
      Pend := ::PCopy( P2, Pend )
   ELSE
      Pstart := ::PCopy( P2, Pstart )
      Pend := ::PCopy( P1, Pend )
   ENDIF
   IF lTabs == Nil; lTabs := .F.; ENDIF
   FOR i := Pstart[P_Y] TO Pend[P_Y]
      cLine := hced_Substr( Self, ::aText[i], ;
         nPos1 := Iif( i == Pstart[P_Y], Pstart[P_X], 1 ), ;
         Iif( i == Pend[P_Y], Pend[P_X], hced_Len( Self, ::aText[i] ) + 1 ) - nPos1 )
      IF lTabs .AND. ::lTabs .AND. Space(::nTabLen) $ cLine
         cLine := Strtran( cLine, Space(::nTabLen), Chr(9) )
      ENDIF
      cText += cLine
      IF i != Pend[P_Y]
         cText += cNewLine
      ENDIF
   NEXT

   RETURN cText

METHOD DelText( P1, P2, lChgPos ) CLASS HCEdit
   LOCAL i, Pstart, Pend, cRest, nPos

   IF lChgPos == Nil; lChgPos := .T.; ENDIF
   IF ::Pcmp( P1, P2 ) < 0
      Pstart := ::PCopy( P1, Pstart )
      Pend := ::PCopy( P2, Pend )
   ELSE
      Pstart := ::PCopy( P2, Pstart )
      Pend := ::PCopy( P1, Pend )
   ENDIF

   ::Undo( Pstart[P_Y], Pstart[P_X], Pend[P_Y], Pend[P_X], 3, ::GetText( P1, P2 ) )
   IF !Empty( ::oHili )
      ::oHili:UpdSource( Pstart[P_Y], Pstart[P_X], Pend[P_Y], Pend[P_X], 3 )
   ENDIF

   IF Pstart[P_Y] == Pend[P_Y]
      i := Pstart[P_Y]
      ::aText[i] := hced_Left( Self, ::aText[i], Pstart[P_X] - 1 ) + hced_Substr( Self, ::aText[i], Pend[P_X] )
   ELSE
      FOR i := Pend[P_Y] TO Pstart[P_Y] STEP - 1
         IF i == Pstart[P_Y]
            IF Pstart[P_X] == 1
               ::DelLine( i )
            ELSE
               ::aText[i] := hced_Left( Self, ::aText[i], Pstart[P_X] - 1 ) + cRest
            ENDIF
         ELSEIF i == Pend[P_Y]
            IF Pstart[P_X] == 1
               cRest := ""
               ::aText[i] := hced_Substr( Self, ::aText[i], Pend[P_X] )
            ELSE
               cRest := hced_Substr( Self, ::aText[i], Pend[P_X] )
               ::aText[i] := ""
            ENDIF
         ELSE
            ::DelLine( i )
         ENDIF
      NEXT
   ENDIF
   ::Scan( Pstart[P_Y], Min( Pend[P_Y], ::nTextLen ) )
   IF ::lWrap
      i := hced_P2Screen( Self, P1[P_Y], P1[P_X] )
      nPos := hced_P2Screen( Self, P2[P_Y], P2[P_X] )
      IF i < 0 .OR. nPos < 0 .OR. i > ::nLines .OR. nPos > ::nLines
         ::GoTo( Pstart[P_Y] )
      ENDIF
   ENDIF
   ::Paint( .F. )

   IF lChgPos
      nPos := Pstart[P_X]
      IF ( i := hced_P2Screen( Self, Pstart[P_Y], @nPos ) ) <= 0
         ::nLineF := Pstart[P_Y]
         ::nWSublF := hced_P2SubLine( Self, Pstart[P_Y], Pstart[P_X] )
         ::nWCharF := Iif( ::nWSublF==1, 1, ::aWrap[Pstart[P_Y],::nWSublF-1] )
         ::nLineC := 1
      ELSE
         ::nLineC := i
      ENDIF
      ::nPosC := nPos - ::nPosF + 1
   ENDIF

   hwg_Invalidaterect( ::handle, 0, 0, ::aLines[::nLineC,AL_Y1], ;
      ::nClientWidth, ::nHeight )
   IF lChgPos
      ::SetCaretPos( SETC_XY )
   ENDIF
   ::lUpdated := .T.

   RETURN Nil

METHOD InsText( aPoint, cText, lOver, lChgPos ) CLASS HCEdit
   LOCAL aText, nLine := aPoint[P_Y], cRest, i, nPos, nSubl
   LOCAL nLineC := ::nLineC, nLineNew, nSub, nPos1, nPos2, lInvAll := .F., l := .F.
   LOCAL nTextLen, c

   IF ( nPos := At( Chr(10), cText ) ) == 0
      aText := hb_aTokens( cText, Chr(13) )
   ELSEIF Substr( cText,nPos-1,1 ) == Chr(13)
      aText := hb_aTokens( cText, cNewLine )
   ELSE
      aText := hb_aTokens( cText, Chr(10) )
   ENDIF
   nTextLen := Len( aText )
   FOR i := 1 TO nTextLen
      IF ( c := Right(aText[i],1) ) == Chr(13) .OR. c == Chr(10)
         aText[i] := Left( aText[i],Len(aText[i])-1 )
      ENDIF
      IF ( c := Left(aText[i],1) ) == Chr(13) .OR. c == Chr(10)
         aText[i] := Substr( aText[i],2 )
      ENDIF
   NEXT

   IF lChgPos == Nil; lChgPos := .T.; ENDIF
   nPos := nPos1 := aPoint[P_X]
   nSubl := Iif( ::lWrap .AND. ::aWrap[nLine] != Nil, Len(::aWrap[nLine]), 0 )

   nLineNew := nLine + nTextLen - 1
   nPos2 := Iif( Len(aText) == 1, nPos + hced_Len( Self, cText ), hced_Len( Self, Atail(aText) ) + 1 )
   ::Undo( nLine, nPos1, nLineNew, nPos2, Iif(lOver==Nil.OR.!lOver,1,2), cText )

   IF lOver == Nil .OR. !lOver
      IF nTextLen == 1
         ::aText[nLine] := hced_Stuff( Self, ::aText[nLine], nPos, 0, cText )
      ELSE
         cRest := hced_Substr( Self, ::aText[nLine], nPos )
         ::aText[nLine] := hced_Left( Self, ::aText[nLine], nPos - 1 ) + aText[1]
         IF Empty( ::aText[nLine] )
            // For properties of this paragraph (aStru) remained with it
            ::AddLine( nLine)
            ::aText[nLine] := ""
            l := .T.
         ENDIF
         FOR i := 2 TO nTextLen
            IF !l .OR. i < Len( aText )
               ::AddLine( nLine + i - 1 )
            ENDIF
            ::aText[nLine+i-1] := aText[i]
            IF i == Len( aText )
               ::aText[nLine+i-1] += cRest
            ENDIF
         NEXT
      ENDIF
      ::Scan( nLine, nLineNew )
   ELSE
      i := hced_Len( Self, cText )
      cRest := hced_Substr( Self, ::aText[nLine], nPos, i )
      ::aText[nLine] := hced_Stuff( Self, ::aText[nLine], nPos, i, cText )
      cText := cRest
   ENDIF
   nPos := nPos2

   IF !Empty( ::oHili )
      ::oHili:UpdSource( nLine, nPos1, nLineNew, nPos2, Iif(lOver==Nil.OR.!lOver,1,2), cText )
   ENDIF

   ::Paint( .F. )
   IF lChgPos
      nSub := ::nLinesAll + 1
      IF ( i := hced_P2Screen( Self, nLineNew, @nPos, @nSub ) ) > ::nLines .AND. ;
            Iif( ::nLines > 0, ::nHeight-::aLines[::nLines,AL_Y2]<=BOTTOM_HEIGHT, .T. )
         ::nLineF := nLineNew
         ::nWSublF := nSub
         ::nWCharF := Iif( nSub==1, 1, ::aWrap[nLineNew,nSub-1] )
         ::LineUp( .F. )
         ::nLineC := Min( 2, ::nTextLen - ::nLineF + 1 )
         ::Paint( .F. )
      ELSE
         ::nLineC := i
      ENDIF
   ENDIF

   IF lChgPos
      ::nPosC := nPos - ::nPosF + 1
      ::SetCaretPos( SETC_XY )
      IF !::lWrap .AND. ::nPosC < nPos - ::nPosF + 1
         ::nPosF += nPos - ::nPosF + 1 - ::nPosC
         ::aPointC[P_X] := ::nPosF + ::nPosC - 1
         lInvAll := .T.
      ENDIF
   ENDIF

   IF Len( aText ) > 1 .OR. lInvAll
      hwg_Invalidaterect( ::handle, 0, 0, 0, ::nClientWidth, ::nHeight )
   ELSE
      hwg_Invalidaterect( ::handle, 0, 0, ::aLines[Max(Min(::nLineC,nLineC)-1,1),AL_Y1], ;
         ::nClientWidth, Iif( ::nLineC==nLineC .AND. ;
         nSubl == Iif(::lWrap.AND.::aWrap[nLine]!=Nil,Len(::aWrap[nLine]),0), ;
         ::aLines[nLineC,AL_Y2], ::nHeight ) )
   ENDIF
   ::lUpdated := .T.

   RETURN Nil

METHOD AddLine( nLine ) CLASS HCEdit

   IF ::nTextLen == Len( ::aText )
      ASize( ::aText, Len( ::aText ) + 32 )
      IF ::lWrap
         ASize( ::aWrap, Len( ::aText ) )
      ENDIF
   ENDIF
   ::nTextLen ++
   ::nLinesAll ++
   AIns( ::aText, nLine )
   IF ::lWrap
      AIns( ::aWrap, nLine )
   ENDIF
   ::lUpdated := .T.

   RETURN Nil

METHOD DelLine( nLine ) CLASS HCEdit

   ADel( ::aText, nLine )
   IF ::lWrap
      ADel( ::aWrap, nLine )
   ENDIF
   ::nTextLen --
   ::nLinesAll --
   ::lUpdated := .T.

   RETURN Nil

METHOD Refresh() CLASS HCEdit

   hwg_Invalidaterect( ::handle, 0, 0, 0, ::nClientWidth, ::nHeight )

   RETURN Nil

METHOD SetWrap( lWrap, lInit ) CLASS HCEdit
   LOCAL lWrapOld := ::lWrap

   IF lWrap != Nil
      lInit := Iif( lInit==Nil, .F., lInit )
      ::lWrap := lWrap
      ::nLineC := 1
      ::nPosF := ::nPosC := 1
      ::PCopy( { ::nPosC, ::nLineC }, ::aPointC )
      ::SetCaretPos()

      IF lWrap
         IF !Empty( ::handle ) .AND. ( ::aWrap == Nil .OR. lInit )
            ::aWrap := Array( Len(::aText) )
            ::Scan()
         ENDIF
      ELSE
         ::aWrap := Nil
         ::nLinesAll := ::nTextLen
         ::nWCharF := ::nWSublF := 1
      ENDIF

      IF !Empty( ::handle ) .AND. !lInit
         ::Refresh()
      ENDIF

   ENDIF

   RETURN lWrapOld

METHOD SetPadding( nValue ) CLASS HCEdit

   LOCAL nPadding := ::nPadding

   IF nValue != Nil
      ::nBoundL := ::nBoundT := ::nPadding := nValue
   ENDIF

   RETURN nPadding

METHOD SetBorder( nThick, nColor ) CLASS HCEdit

#ifdef __GTK__
   IF nThick > 0
      IF ::nPadding <= 2
         ::SetPadding( nThick )
      ENDIF
   ENDIF
#endif
   hced_SetBorder( ::hEdit, nThick, nColor )
   RETURN Nil

METHOD Highlighter( oHili ) CLASS HCEdit

   IF oHili == Nil
      ::oHili := Nil
   ELSE
      ::oHili := oHili:Set( Self )
   ENDIF
   RETURN Nil

/* Added:  nl1, nl2, hDC, nWidth, nHeight */
METHOD Scan( nl1, nl2, hDC, nWidth, nHeight ) CLASS HCEdit
   LOCAL lNested := ::lScan, aCoors, yPos, yNew, nLine, nLines, i, n1, n2
   LOCAL nDocWidth
   //LOCAL hDCR, hBitmap
   LOCAL nLinesB := ::nLines, nLineF := ::nLineF, nLineC := ::nLineC, nWCharF := ::nWCharF, nWSublF := ::nWSublF

   IF Empty( ::aText ) .OR. Empty( ::aWrap ) .OR. !::lWrap
      RETURN Nil
   ENDIF

   IF !lNested
#ifdef __GTK__
      aCoors := hwg_GetClientRect( ::handle )
      IF !::lPainted
         ::lNeedScan := .T.
         RETURN Nil
      ENDIF
      hDC := hwg_Getdc( ::handle )
#else
      aCoors := hwg_GetClientRect( ::handle )
      hDC := hwg_Getdc( ::handle )
#endif
      IF Empty( ::nKoeffScr )
         i := hwg_Getdevicearea( hDC )
         ::nKoeffScr := ( i[1]/i[3] )
      ENDIF
      nWidth := ::nClientWidth := aCoors[3] - aCoors[1]
      IF Empty( ::nDocFormat )
         ::nDocWidth := nDocWidth := 0
      ELSE
         ::nMarginL := Round( ::aDocMargins[1] * ::nKoeffScr, 0 )
         ::nMarginR := Round( ::aDocMargins[2] * ::nKoeffScr, 0 )
         ::nDocWidth := nDocWidth := Int( ::nKoeffScr * HPrinter():aPaper[ ::nDocFormat, Iif(::nDocOrient==0,2,3) ] ) - ::nMarginR
      ENDIF
      ::nBoundR := Iif( !Empty(nDocWidth), nDocWidth, ::nClientWidth ) - ::nPadding
      nHeight := ::nHeight
      hced_SetPaint( ::hEdit, hDC,, nWidth, ::lWrap,, nDocWidth )
   ELSE
      hced_SetWidth( ::hEdit, nWidth, 0 )
   ENDIF
   ::lScan := .T.

   nl1 := Iif( nl1==Nil, 1, nl1 )
   nl2 := Iif( nl2==Nil, ::nTextLen, nl2 )
   IF nl1 != 1 .OR. nl2 != ::nTextLen
      FOR i := nl1 TO nl2
         ::nLinesAll -= Iif( Empty(::aWrap[i]), 1, Len(::aWrap[i])+1 )
      NEXT
   ELSE
      ::nLinesAll := 0
   ENDIF
   AFill( ::aWrap, Nil, nl1, nl2-nl1+1 )

   ::nLineF := nl1
   ::nLineC := -1
   ::nWSublF := ::nWCharF := 1
   nLine := 0
   DO WHILE ( nLine + ::nLineF - 1 ) < nl2

      ::nLines := 0
      yPos := ::nBoundT
      DO WHILE ( nLine + ::nLineF - 1 ) < nl2
         nLine ++
         nLines := ::nLines
         yNew := ::PaintLine( , yPos, nLine )
         IF nLine == 1 .AND. ::nWSublF > 1
            n2 := ::nLines - nLines
            IF ::aWrap[nLine+::nLineF-1] == Nil
               n1 := 0
               ::aWrap[nLine+::nLineF-1] := Array( n2 )
            ELSE
               n1 := Len(::aWrap[nLine+::nLineF-1])
               ::aWrap[nLine+::nLineF-1] := Asize( ::aWrap[nLine+::nLineF-1], ;
                     n1 + n2 )
            ENDIF
            FOR i := 1 TO n2
               ::aWrap[nLine+::nLineF-1,n1+i] := ::aLines[i,AL_FIRSTC]
            NEXT
         ELSE
            IF ::nLines - nLines > 1
               ::aWrap[nLine+::nLineF-1] := Array( ::nLines - nLines - 1 )
               FOR i := nLines+2 TO ::nLines
                  ::aWrap[nLine+::nLineF-1,i-nLines-1] := ::aLines[i,AL_FIRSTC]
               NEXT
            ELSE
               ::aWrap[nLine+::nLineF-1] := Nil
            ENDIF
         ENDIF
         IF yNew + ( ::aLines[nLine,AL_Y2] - ::aLines[nLine,AL_Y1] ) > nHeight
            EXIT
         ENDIF
         yPos := yNew
      ENDDO
      IF ( ::nWCharF := ::aLines[::nLines,AL_FIRSTC]+::aLines[::nLines,AL_NCHARS] ) ;
            < hced_Len( Self,::aText[nLine+::nLineF-1] )
         ::nWSublF := ::nLines - nLines + 1
         ::nLineF += nLine - 1
      ELSE
         ::nLineF += nLine
         ::nWCharF := ::nWSublF := 1
      ENDIF
      ::nLinesAll += ::nLines
      nLine := 0
   ENDDO

   IF !lNested
      ::lScan := .F.
#ifdef __GTK__
      hwg_Releasedc( ::handle, hDC )
#else
      //hwg_DeleteDC( hDC )
      //hwg_DeleteObject( hBitmap )
      //hwg_Releasedc( ::handle, hDCR )
      hwg_Releasedc( ::handle, hDC )
#endif
   ENDIF
   ::nLines := nLinesB
   ::nLineF := nLineF
   ::nLineC := nLineC
   ::nWCharF:= nWCharF
   ::nWSublF:= nWSublF
#ifdef __GTK__
   ::lNeedScan := .F.
#endif
   RETURN Nil

METHOD Undo( nLine1, nPos1, nLine2, nPos2, nOper, cText ) CLASS HCEdit
   LOCAL nUndo := Iif( Empty( ::aUndo ), 0, Len( ::aUndo ) ), nMax

   IF ::nMaxUndo == 0
      RETURN Nil
   ENDIF
   IF PCount() >= 5
      IF nUndo == 0
         ::aUndo := { { nLine1, nPos1, nLine2, nPos2, nOper, Iif(nOper>1,cText,Nil) } }
         RETURN Nil
      ELSE
         IF ::aUndo[nUndo,UNDO_OPER] == nOper ;
               .AND. ::aUndo[nUndo,UNDO_LINE2] == nLine1 .AND. ( ;
               ( nOper <= 2 .AND. ::aUndo[nUndo,UNDO_POS2] == nPos1 ) .OR. ;
               ( nOper == 3 .AND. ( ::aUndo[nUndo,UNDO_POS1] == nPos1 .OR. ::aUndo[nUndo,UNDO_POS1] == nPos1+1 ) ) )
            ::aUndo[nUndo,UNDO_LINE2] := nLine2
            ::aUndo[nUndo,UNDO_POS2] := nPos2
            IF nOper == 2
               ::aUndo[nUndo,UNDO_TEXT] += cText
            ELSEIF nOper == 3
               IF ::aUndo[nUndo,UNDO_POS1] == nPos1
                  ::aUndo[nUndo,UNDO_TEXT] += cText
               ELSE
                  ::aUndo[nUndo,UNDO_TEXT] := cText + ::aUndo[nUndo,UNDO_TEXT]
                  ::aUndo[nUndo,UNDO_POS1] := nPos1
               ENDIF
            ENDIF
         ELSE
            IF nUndo == ::nMaxUndo
               ADel( ::aUndo, 1 )
            ELSE
               Aadd( ::aUndo, Nil )
               nUndo ++
            ENDIF
            ::aUndo[nUndo] := { nLine1, nPos1, nLine2, nPos2, nOper, Iif(nOper>1,cText,Nil) }
         ENDIF
      ENDIF
   ELSEIF PCount() == 0 .AND. nUndo > 0
      nMax := ::nMaxUndo
      ::nMaxUndo := 0
      IF ::aUndo[nUndo,UNDO_OPER] == 1
         ::DelText( {::aUndo[nUndo,UNDO_POS1],::aUndo[nUndo,UNDO_LINE1]}, {::aUndo[nUndo,UNDO_POS2],::aUndo[nUndo,UNDO_LINE2]} )
      ELSEIF ::aUndo[nUndo,UNDO_OPER] == 2
         ::InsText( {::aUndo[nUndo,UNDO_POS1],::aUndo[nUndo,UNDO_LINE1]}, ::aUndo[nUndo,UNDO_TEXT], .T. )
      ELSE
         ::InsText( {::aUndo[nUndo,UNDO_POS1],::aUndo[nUndo,UNDO_LINE1]}, ::aUndo[nUndo,UNDO_TEXT] )
      ENDIF
      ::nMaxUndo := nMax
      ::aUndo := Iif( nUndo==1, Nil, ASize( ::aUndo, nUndo-1 ) )
   ENDIF
   RETURN Nil

METHOD Print( nDocFormat, nDocOrient, nMarginL, nMarginR, nMarginT, nMarginB ) CLASS HCEdit
   LOCAL nL, yPos, oPrinter
   LOCAL aWrapB := ::aWrap, aMargins := ::aDocMargins
   LOCAL lWrap := ::lWrap, nMargL := ::nMarginL, nMargR := ::nMarginR, nMargT := ::nMarginT, nMargB := ::nMarginB, nBoundL := ::nBoundL, nBoundR := ::nBoundR, nDocF := ::nDocFormat

   INIT PRINTER oPrinter NAME ".buffer" PIXEL

   IF nDocFormat == Nil
      nDocFormat := Iif( ::nDocFormat==0, 2, ::nDocFormat ); nDocOrient := ::nDocOrient
      nMarginL := ::aDocMargins[1]; nMarginR := ::aDocMargins[2]; nMarginT := ::aDocMargins[3]; nMarginB := ::aDocMargins[4]
   ENDIF

   ::nBoundL := ::nBoundR := 0
   ::nMarginL := nMarginL *oPrinter:nHRes
   ::nMarginR := nMarginR * oPrinter:nHRes
   yPos := ::nMarginT := nMarginT * oPrinter:nVRes
   ::nMarginB := (HPrinter():aPaper[nDocFormat,3] - nMarginB) * oPrinter:nVRes

   IF ::nDocFormat != nDocFormat .OR. ::nDocOrient != nDocOrient .OR. ;
         ::aDocMargins[1] != nMarginL .OR. ::aDocMargins[2] != nMarginR .OR. ;
         ::aDocMargins[3] != nMarginT .OR. ::aDocMargins[4] != nMarginB

      ::aDocMargins[1] := nMarginL; ::aDocMargins[2] := nMarginR; ::aDocMargins[3] := nMarginT; ::aDocMargins[4] := nMarginB

      ::nDocFormat := nDocFormat
      ::lWrap := .T.
      ::aWrap := Array( Len(::aText) )
      ::Scan()

   ENDIF
   IF ::nDocOrient == 1
      oPrinter:SetMode( 2 )
   ENDIF
   oPrinter:StartDoc()
   oPrinter:StartPage()
   FOR nL := 1 TO ::nTextLen
      yPos := ::PrintLine( oPrinter, yPos, nL )
   NEXT
   oPrinter:EndPage()
   oPrinter:EndDoc()
   oPrinter:Preview( , , ::aLangTexts, )
   oPrinter:End()

   ::nMarginL := nMargL; ::nMarginR := nMargR; ::nMarginT := nMargT; ::nMarginB := nMargB; ::nBoundL := nBoundL; ::nBoundR := nBoundR; ::nDocFormat := nDocF
   ::aWrap := aWrapB
   ::lWrap := lWrap
   ::aDocMargins := aMargins

   RETURN Nil

METHOD PrintLine( oPrinter, yPos, nL ) CLASS HCEdit
   LOCAL nPrinted, nSubl := 1, nPos1 := 1, cLine, cAttr, aStru, aHili, i, cTemp, nHeight, arrS
   LOCAL x1, x2, nLenOld, nMarginL, aTemp

   IF !Empty( ::oHili )
      ::oHili:Do( Self, nL )
   ENDIF
   DO WHILE .T.
      nLenOld := Len( oPrinter:aPages[oPrinter:nPage] )
      nMarginL := ::nMarginL + Iif( nSubl==1, ::nIndent, 0 )
      nPrinted := hced_Len( Self,::aText[nL] )
      IF ::aWrap[nL] != Nil
         nPos1 := Iif( nSubl == 1, 1, ::aWrap[nL,nSubl-1] )
         nPrinted := Iif( Len(::aWrap[nL])>=nSubl,::aWrap[nL,nSubl],nPrinted+1 ) - nPos1
      ENDIF
      IF nPrinted > 0
         cLine := hced_Substr( Self, ::aText[nL], nPos1, nPrinted )
         cAttr := Replicate( Chr( Iif(::nDefFont>0,::nDefFont,1) ), nPrinted )
         IF !Empty( ::oHili )
            IF ::oHili:nItems > 0
               aStru := ::oHili:aLineStru
               FOR i := 1 TO ::oHili:nItems
                  IF aStru[i,2] >= nPos1 .AND. aStru[i,1] <= nPos1+nPrinted-1 .AND. hb_hHaskey( ::aHili,aStru[i,3] )
                     aHili := ::aHili[aStru[i,3]]
                     IF !Empty(aHili[1]) .AND. aHili[1] > 1
                        x1 := Max( nPos1, aStru[i,1] ) - nPos1 + 1
                        x2 := Min( aStru[i,2],nPos1+nPrinted-1 ) - nPos1 + 1
                        cAttr := Stuff( cAttr, x1, x2-x1+1, Replicate( Chr(aHili[1]), x2-x1+1 ) )
                     ENDIF
                  ENDIF
               NEXT
            ENDIF
         ENDIF
         i := Left( cAttr,1 )
         x2 := 1; nHeight := 0; x1 := 2; aTemp := {}
         DO WHILE .T.
            IF x1 > Len(cAttr) .OR. i != Substr( cAttr,x1,1 )
               cTemp := hced_Substr( Self, cLine, x2, x1-x2 )

               hwg_Selectobject( oPrinter:hDCPrn, ::aFonts[Asc(i)]:handle )
               arrS := hwg_GetTextSize( oPrinter:hDCPrn, cTemp )
               nHeight := Max( nHeight, arrS[2] + 1 )

               //oPrinter:Say( cTemp, nMarginL, yPos, nMarginL+arrS[1], yPos+nHeight, ::nAlign, ::aFonts[Asc(i)] )
               //hwg_writelog( cTemp+"//-- "+str(::nMarginR)+" "+str(::nBoundR) )
               Aadd( aTemp, { cTemp, Asc(i), arrS[1]+2 } )
               nMarginL += arrS[1]
               IF x1 > Len(cAttr)
                  EXIT
               ELSE
                  i := Substr( cAttr,x1,1 )
                  x2 := x1
               ENDIF
            ENDIF
            x1 ++
         ENDDO
         x2 := ::nMarginL + Iif( nSubl==1, ::nIndent, 0 )
         x1 := nMarginL - x2
         nMarginL := x2
         x2 := Iif( Empty(::nBoundR), ::nDocWidth, ::nBoundR ) - ::nMarginR - ::nMarginL
         IF ::nAlign == DT_CENTER
            nMarginL += Round( ( x2 - x1 ) / 2, 0 )
         ELSEIF ::nAlign == DT_RIGHT
            nMarginL += x2 - x1
         ENDIF
         FOR i := 1 TO Len( aTemp )
            oPrinter:Say( aTemp[i,1], nMarginL, yPos, nMarginL+aTemp[i,3], yPos+nHeight,, ::aFonts[aTemp[i,2]] )
            nMarginL += aTemp[i,3]
         NEXT
      ELSE
         hwg_Selectobject( oPrinter:hDCPrn, ::aFonts[1]:handle )
         nHeight := hwg_GetTextSize( oPrinter:hDCPrn, "A" )[2]
      ENDIF
      IF yPos + nHeight > ::nMarginB
         oPrinter:aPages[oPrinter:nPage] := Left( oPrinter:aPages[oPrinter:nPage], nLenOld )
         oPrinter:EndPage()
         oPrinter:StartPage()
         yPos := ::nMarginT
      ELSE
         nSubl ++
         yPos += nHeight
         IF Empty( ::aWrap[nL] ) .OR. Len( ::aWrap[nL] ) < nSubl-1
            EXIT
         ENDIF
      ENDIF
   ENDDO

   RETURN yPos

METHOD Move( x1, y1, width, height ) CLASS HCEdit

   LOCAL nw := Iif( Empty(::oTrack).OR.::oTrack:lHide, 0, ;
      Iif( Valtype(::oTrack)=="N", ::oTrack, ::oTrack:nWidth ) )

   //hwg_writelog( "1> "+Iif(x1==nil,"nil",str(x1)) + " " + Iif(width==nil,"nil",str(width)) + " " + str(nw) + " " + str(::nWidth) )
   ::Super:Move( x1, y1, Iif(Empty(width),::nWidth,width)-nw, height )
   ::nWidth += nw
   IF !Empty(::oTrack) .AND. !::oTrack:lHide
      x1 := ::nLeft + ::nWidth - nw
      ::oTrack:Move( x1, y1, ::oTrack:nWidth, height )

   ENDIF

   RETURN Nil

METHOD ShowTrackBar( lShow, nTrackWidth ) CLASS HCEdit

   IF lShow
      IF Empty( ::oTrack )
         IF Empty( nTrackWidth ); nTrackWidth := HTRACK_DEF_WIDTH; ENDIF
         ::oTrack := HTrack():New( ::oParent,, ::nLeft+::nWidth-nTrackWidth, ::nTop, nTrackWidth, ;
            ::nHeight,,,,, 48,, HStyle():New( { 0x888888, 0xcccccc }, 3 ), .F. )
         ::oTrack:bChange := {|o,n| onTrack(Self,o,n) }
         //hwg_writelog( "CrTrack " + ::oParent:ClassName() )
      ELSE
         ::oTrack:Show()
      ENDIF
      IF !Empty( ::handle )
         ::Move( ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ENDIF
   ELSE
      IF !Empty( ::oTrack )
         ::oTrack:Hide()
         ::Move( ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ENDIF
   ENDIF

   RETURN Nil


/*  nL - A row on the screen ( 1 ... ::nLines )
 */
FUNCTION hced_LineNum( oEdit, nL )
   LOCAL i, n := 0, nLine

   IF oEdit:SetWrap()
      nLine := oEdit:aLines[nL,AL_LINE]
      FOR i := 1 TO nLine - 1
         n += Iif( Empty(oEdit:aWrap[i]), 1, Len(oEdit:aWrap[i]) + 1 )
      NEXT
      n += oEdit:aLines[nL,AL_SUBL]
   ELSE
      n := oEdit:nLineF + nL - 1
   ENDIF
   RETURN n

/*  nL - A row on the screen ( 1 ... ::nLines )
 *  nOper: SB_LINE (1) - an order of a subline,
 *  SB_LINES (2) - a number of sublines,
 *  SB_REST (3) - how many sublines after it
 *  SB_TEXT (4) - how many sublines after it
 */
STATIC FUNCTION hced_SubLine( oEdit, nL, nOper )
   LOCAL i, nLine := oEdit:aLines[nL,AL_LINE]
   LOCAL n   && := 0

   nOper := Iif( Empty(nOper), 1, nOper )
   IF oEdit:SetWrap() .AND. !Empty( oEdit:aWrap[nLine] )
      IF nOper == SB_LINES
         n := Len(oEdit:aWrap[nLine]) + 1
      ELSE
         FOR i := Len(oEdit:aWrap[nLine]) TO 1 STEP -1
            IF oEdit:aWrap[nLine,i] <= oEdit:aLines[nL,AL_FIRSTC]
               EXIT
            ENDIF
         NEXT
         n := i+1
         IF nOper == SB_REST
            n := Len(oEdit:aWrap[nLine]) + 1 - n
         ELSEIF nOper == SB_TEXT
            i := Iif( n == 1, 1, oEdit:aWrap[nLine,n-1] )
            n := hced_Substr( oEdit, oEdit:aText[nLine], i, ;
               Iif( n>Len(oEdit:aWrap[nLine]), hced_Len(oEdit,oEdit:aText[nLine])+1,oEdit:aWrap[nLine,n] ) - i )
         ENDIF
      ENDIF
   ELSE
      n := Iif( nOper==SB_LINE, 1, Iif( nOper==SB_LINES, 1, Iif( nOper==SB_REST, 0, oEdit:aText[nLine] ) ) )
   ENDIF
   RETURN n

STATIC FUNCTION hced_P2Screen( oEdit, y, x, nSub )
   LOCAL i, n, nL := oEdit:nLineF

   IF oEdit:SetWrap()
      IF y < nL
         RETURN -1
      ENDIF
      nSub := Iif( Empty(nSub), oEdit:nLines, nSub )
      n := 1
      IF !Empty( oEdit:aWrap[nL] )
         i := oEdit:nWSublF
         IF y == nL
            IF i > 1 .AND. oEdit:aWrap[nL,i-1] > x
               n := -1
            ELSE
               DO WHILE i <= Len(oEdit:aWrap[nL]) .AND. oEdit:aWrap[nL,i] <= x
                  i ++; n ++
               ENDDO
               IF i > 1
                  x := x - oEdit:aWrap[nL,i-1] + 1
               ENDIF
            ENDIF
         ELSE
            n := Len(oEdit:aWrap[nL]) - i + 2
         ENDIF
      ENDIF
      IF y == nL
         y := nSub := n
         RETURN n
      ENDIF
      DO WHILE ++nL < y .AND. n <= nSub
         n += Iif( Empty(oEdit:aWrap[nL]), 1, Len(oEdit:aWrap[nL])+1 )
      ENDDO
      IF nL == y .AND. n <= nSub
         n ++
         nSub := 1
         IF !Empty(oEdit:aWrap[nL])
            DO WHILE nSub <= Len(oEdit:aWrap[nL]) .AND. oEdit:aWrap[nL,nSub] <= x
               nSub ++; n ++
            ENDDO
            IF nSub > 1
               x := x - oEdit:aWrap[nL,nSub-1] + 1
            ENDIF
         ENDIF
      ENDIF
      y := n
      RETURN n
   ENDIF

   nSub := 1
   RETURN y - oEdit:nLineF + 1

STATIC FUNCTION hced_P2SubLine( oEdit, y, x )
   LOCAL i

   IF oEdit:SetWrap() .AND. !Empty( oEdit:aWrap[y] )
      FOR i := 1 TO Len( oEdit:aWrap[y] )
         IF oEdit:aWrap[y,i] > x
            RETURN i
         ENDIF
      NEXT
      RETURN i
   ENDIF
   RETURN 1

STATIC FUNCTION onTrack( oEdit, oTrack )

   LOCAL nInPage, nLine, nLinesAll, i, nL, nPos := oTrack:Value
   LOCAL nLineF, nWSublF, nWCharF, lChg := .F.

   nInPage := Iif( oEdit:nLines > 0, Int( oEdit:nHeight/(oEdit:aLines[1,AL_Y2] - oEdit:aLines[1,AL_Y1] ) ), 0 )
   nLinesAll := oEdit:nLinesAll - nInPage + 2
   // hwg_writelog( "1> nPos: " + str(nPos,7,4)+" nInPage: "+str(nInPage)+" nLines: "+str(oEdit:nLines) )
   IF oEdit:nLinesAll > nInPage //n > 0
      nLine := Min( nLinesAll, Max( 1, Int( nPos * nLinesAll ) ) )
      //hwg_writelog( "  2> nLine: " + str(nLine)+" nLinesAll: "+str(oEdit:nLinesAll) )
      IF oEdit:SetWrap()
         i := nL := 0
         DO WHILE ++i <= oEdit:nTextLen
            nL += Iif( Empty(oEdit:aWrap[i]), 1, Len(oEdit:aWrap[i])+1 )
            IF nL >= nLine
               EXIT
            ENDIF
         ENDDO
         nLineF := i
         nWSublF := Iif( nL == nLine .OR. Empty(oEdit:aWrap[i]), 1, Len(oEdit:aWrap[i])-(nL-nLine)+2 )
         nWCharF := Iif( nL == nLine .OR. Empty(oEdit:aWrap[i]), 1, oEdit:aWrap[i,Len(oEdit:aWrap[i])-(nL-nLine)+1] )
         IF nLineF != oEdit:nLineF .OR. nWSublF != oEdit:nWSublF .OR. nWCharF != oEdit:nWCharF
            oEdit:nLineF := nLineF
            oEdit:nWSublF := nWSublF
            oEdit:nWCharF := nWCharF
            lChg := .T.
         ENDIF
      ELSE
         nLineF := nLine
         IF nLineF != oEdit:nLineF
            oEdit:nLineF := nLineF
            lChg := .T.
         ENDIF
      ENDIF
      IF lChg
         oEdit:Paint( .F. )
         oEdit:SetCaretPos( SETC_COORS, hced_GetXCaretPos( oEdit:hEdit ), hced_GetYCaretPos( oEdit:hEdit ) )
         hwg_Invalidaterect( oEdit:handle, 0 )
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION hced_Line4Pos( oEdit, yPos )
   LOCAL y1
   FOR y1 := 1 TO oEdit:nLines
      IF yPos < oEdit:aLines[ y1,AL_Y2 ]
         EXIT
      ENDIF
   NEXT
   IF y1 > oEdit:nLines
      y1 --
   ENDIF
   RETURN y1

Function hced_Chr( oEdit, nCode )
#ifndef __XHARBOUR__
   IF hwg__isUnicode()
      IF oEdit:lUtf8; RETURN hwg_KeyToUtf8( nCode ); ELSE; RETURN hb_translate( hwg_KeyToUtf8(nCode),"UTF8",oEdit:cp ); ENDIF
   ENDIF
#endif
   RETURN Chr( nCode )

Function hced_Stuff( oEdit, cLine, nPos, nChars, cIns )
#ifndef __XHARBOUR__
   IF oEdit:lUtf8; RETURN hb_utf8Stuff( cLine, nPos, nChars, cIns ); ENDIF
#endif
   RETURN Stuff( cLine, nPos, nChars, cIns )

Function hced_Substr( oEdit, cLine, nPos, nChars )
#ifndef __XHARBOUR__
   IF oEdit:lUtf8; RETURN Iif( nChars==Nil, hb_utf8Substr( cLine, nPos ), hb_utf8Substr( cLine, nPos, nChars ) ); ENDIF
#endif
   RETURN Iif( nChars==Nil, Substr( cLine, nPos ), Substr( cLine, nPos, nChars ) )

Function hced_Left( oEdit, cLine, nPos )
#ifndef __XHARBOUR__
   IF oEdit:lUtf8; RETURN hb_utf8Left( cLine, nPos ); ENDIF
#endif
   RETURN Left( cLine, nPos  )

Function hced_Right( oEdit, cLine, nPos )
#ifndef __XHARBOUR__
   IF oEdit:lUtf8; RETURN hb_utf8Right( cLine, nPos ); ENDIF
#endif
   RETURN Right( cLine, nPos  )

Function hced_Len( oEdit, cLine )
#ifndef __XHARBOUR__
   IF oEdit:lUtf8; RETURN hb_utf8Len( cLine ); ENDIF
#endif
   RETURN Len( cLine )

Function hced_At( oEdit, cFind, cLine, nStart, nEnd )
#ifndef __XHARBOUR__
   IF oEdit:lUtf8; RETURN hb_utf8At( cFind, cLine, nStart, nEnd ); ENDIF
#endif
   RETURN hb_At( cFind, cLine, nStart, nEnd )

Function hced_RAt( oEdit, cFind, cLine, nStart, nEnd )
#ifndef __XHARBOUR__
   IF oEdit:lUtf8; RETURN hb_utf8RAt( cFind, cLine, nStart, nEnd ); ENDIF
#endif
   RETURN hb_RAt( cFind, cLine, nStart, nEnd )

Function hced_NextPos( oEdit, cLine, nPos )
#ifndef __XHARBOUR__
   IF oEdit:lUtf8; RETURN nPos + Len( hced_Substr( oEdit, cLine, nPos, 1 ) ); ENDIF
#endif
   RETURN nPos + 1

* ====================== EOF of hcedit.prg =====================

