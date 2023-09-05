/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HDrawnBrw class - browse databases and arrays
 *
 * Copyright 2023 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

#define DEF_ROW_HEIGHT  24
#define DEF_COL_WIDTH   80
#define DEF_CLRT_SELE   0xffffff
#define DEF_CLRB_SELE   0x909090
#define DEF_CLR_SELE    0xC0C0C0
#define DEF_HTT_SELE    0xffffff
#define DEF_HTB_SELE    0x505050

#define CLR_BLACK    0
#define CLR_WHITE    0xffffff
#define CLR_GRAY3    0xbbbbbb

CLASS HBrw INHERIT HBoard

   DATA oDrawn

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, oFont, ;
               bSize, bPaint, bClick )
   METHOD Move( x1, y1, width, height )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, oFont, ;
               bSize, bPaint, bClick ) CLASS HBrw

   ::Super:New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, oFont,, ;
              bSize, bPaint,, tcolor, bcolor )

   ::oDrawn := HDrawnBrw():New( Self, 0, 0, nWidth, nHeight, tcolor, bcolor,,, oFont, ;
               bPaint, bClick )

   RETURN Self

METHOD Move( x1, y1, width, height ) CLASS HBrw

   ::oDrawn:Move( 0, 0, width, height )
   ::Super:Move( x1, y1, width, height )

   RETURN Nil

CLASS HDrawnBrw INHERIT HDrawn

   DATA oData
   DATA aColumns      INIT {}

   DATA nHeightRow    INIT 0
   DATA nHeightHead   INIT 0
   DATA nHeightFoot   INIT 0
   DATA aRowPadding   INIT { 4, 2, 4, 2 }
   DATA aHeadPadding  INIT { 4, 0, 4, 0 }
   DATA aMargin       INIT { 0,0,0,0 }

   DATA tColorSel, bColorSel, oBrushSel, htbColor, httColor, oBrushHtb
   DATA sepColor      INIT DEF_CLR_SELE
   DATA oPenSep, oPenBorder
   DATA nBorder       INIT 0
   DATA nBorderColor  INIT 0
   DATA oFontHead
   DATA oPaintCB

   DATA oStyleHead                           // An HStyle object to draw the header
   DATA oStyleFoot                           // An HStyle object to draw the footer
   DATA oStyleCell                           // An HStyle object to draw the cell

   DATA aRows         INIT {}                // { { y1,y2 },... }
   DATA nRowCount     INIT 0                 // Number of visible data rows
   DATA nRowCurr      INIT 1                 // Row currently selected

   DATA nColCount     INIT 0                 // Number of visible data columns
   DATA nColCurr      INIT 1                 // Column currently selected
   DATA nColFirst     INIT 1                 // The leftmost column on the screen

   DATA bEnter
   DATA oEdit
   DATA lSeleCell     INIT .F.
   DATA lRebuild      INIT .T.

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, oFont, ;
               bPaint, bChgState )

   METHOD Rebuild( hDC )
   METHOD DoRebuild()  INLINE  (::lRebuild := .T., ::Refresh())
   METHOD Paint( hDC )
   METHOD RowOut( hDC, nRow, x1, y1, x2 )
   METHOD HeaderOut( hDC )
   METHOD FooterOut( hDC )
   METHOD Cell( iCol )

   METHOD AddColumn( cHead, block, nWidth, nAlignRow, nAlignHead, lEditable )
   METHOD Edit()
   METHOD onKey( msg, wParam, lParam )
   METHOD onMouseMove( xPos, yPos )
   METHOD onMouseLeave()
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )
   METHOD SetFocus()

   METHOD Selected( n )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, oFont, ;
            bPaint, bChgState ) CLASS HDrawnBrw

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, ;
      Iif( tcolor == Nil, CLR_BLACK, tcolor ), Iif( bColor == Nil, CLR_WHITE, bColor ),, ' ', ;
      oFont, bPaint, bChgState )

   ::tColorSel := DEF_CLRT_SELE
   ::bColorSel := DEF_CLRB_SELE
   ::httColor  := DEF_HTT_SELE
   ::htbColor  := DEF_HTB_SELE

   RETURN Self

METHOD Rebuild( hDC )

   LOCAL i, l

   IF Empty( ::oBrushSel )
      ::oBrushSel := HBrush():Add( ::bColorSel )
   ENDIF
   IF Empty( ::oBrushHtb )
      ::oBrushHtb := HBrush():Add( ::htbColor )
   ENDIF
   IF Empty( ::oPenSep )
      ::oPenSep := HPen():Add( PS_SOLID, 1, ::sepColor )
   ENDIF
   IF Empty( ::oPenBorder) .AND. ::nBorder > 0
      ::oPenBorder := HPen():Add( PS_SOLID, ::nBorder, ::nBorderColor )
      ::aMargin[1] := ::aMargin[2] := ::aMargin[3] := ::aMargin[4] := ::nBorder
   ENDIF
   IF Empty( ::oStyleHead )
      ::oStyleHead := HStyle():New( { CLR_WHITE, CLR_GRAY3 }, 1 )
   ENDIF

   IF ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
      ::nHeightRow := hwg_GetTextMetric( hDC )[1]
   ELSE
      ::nHeightRow := DEF_ROW_HEIGHT
   ENDIF
   ::nHeightRow += ::aRowPadding[2] + ::aRowPadding[4]

   l := .F.
   FOR i := 1 TO Len( ::aColumns )
      IF !Empty( ::aColumns[i]:cHead )
         l := .T.
      ENDIF
      IF ::aColumns[i]:lEditable
         ::lSeleCell := .T.
      ENDIF
   NEXT
   IF l
      IF ::oFontHead != Nil
         hwg_Selectobject( hDC, ::oFontHead:handle )
         ::nHeightHead := hwg_GetTextMetric( hDC )[1]
      ELSEIF ::oFont != Nil
         hwg_Selectobject( hDC, ::oFont:handle )
         ::nHeightHead := hwg_GetTextMetric( hDC )[1]
      ELSE
         ::nHeightHead := DEF_ROW_HEIGHT
      ENDIF
      ::nHeightHead += ::aHeadPadding[2] + ::aHeadPadding[4]
   ENDIF

   ::lRebuild := .F.

   RETURN Nil

METHOD Paint( hDC ) CLASS HDrawnBrw

   LOCAL x1, y1, x2, y2, x, nRow := 0
   LOCAL nRec, i

   IF Empty( ::oData )
      RETURN Nil
   ENDIF

   IF ::lRebuild
      ::Rebuild( hDC )
   ENDIF

   hwg_Selectobject( hDC, ::oFont:handle )

   IF ::nHeightHead > 0
      ::HeaderOut( hDC )
   ENDIF
   IF ::nHeightFoot > 0
      ::FooterOut( hDC )
   ENDIF
   x1 := ::nLeft + ::aMargin[1]
   y1 := ::nTop + ::aMargin[2] + ::nHeightHead
   x2 := ::nLeft + ::nWidth - ::aMargin[3]
   y2 := ::nTop + ::nHeight - ::nHeightFoot - ::aMargin[4] - ::nHeightRow + ::aRowPadding[4]
   //::nRowCount := Int( ( y2 - y1 ) / ( ::nHeightRow ) )
   //hwg_FillRect( hDC, x1, y1, x2, y2, ::oBrush:handle )

   nRec := ::oData:Recno()
   ::oData:Skip( -(::nRowCurr - 1) )
   DO WHILE y1 <= y2 .AND. !::oData:Eof()
      y1 := ::RowOut( hDC, ++nRow, x1, y1, x2, y2 )
      ::oData:Skip( 1 )
   ENDDO
   IF Len( ::aRows ) == nRow
      AAdd( ::aRows, { Nil, Nil } )
   ELSE
      ::aRows[nRow+1,1] := Nil
   ENDIF
   ::oData:Goto( nRec )
   ::nRowCount := nRow
   y2 += ::nHeightRow - ::aRowPadding[4]
   hwg_FillRect( hDC, x1, y1, x2, y2, ::oBrush:handle )

   hwg_SelectObject( hDC, ::oPenSep:handle )
   i := 0
   DO WHILE ++i <= Len( ::aRows ) .AND. ::aRows[i,1] != Nil
      hwg_DrawLine( hDC, x1, ::aRows[i,2], x2, ::aRows[i,2] )
   ENDDO
   i := ::nColFirst - 1; x := x1
   DO WHILE ++i < Len( ::aColumns ) .AND. x < x2
      x += ::aColumns[i]:nWidth
      hwg_DrawLine( hDC, x, ::nTop + ::aMargin[2] + ::nHeightHead, x, y1 )
   ENDDO
   IF !Empty( ::oPenBorder )
      hwg_Rectangle( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1, ::oPenBorder:handle )
   ENDIF

   IF !Empty( ::oEdit )
      ::oEdit:Paint( hDC )
   ENDIF

   RETURN Nil

METHOD RowOut( hDC, nRow, x1, y1, x2 ) CLASS HDrawnBrw

   LOCAL y2 := y1 + ::nHeightRow - 1, x := x1, iCol := ::nColFirst - 1, i := 0, nw
   LOCAL oCB, oCol, block

   IF Len( ::aRows ) < nRow
      AAdd( ::aRows, { y1, Nil } )
   ENDIF
   //hwg_writelog( "rout "+str(nRow) + " " + str(y1) + " " + str(y2) + " " + str(::nRowCurr) + " " + str(::nRowCount) )

   //hwg_FillRect( hDC, x1, y1, x2, y2, IIf( nRow == ::nRowCurr, ::oBrushSel:handle, ::oBrush:handle ) )
   hwg_Settransparentmode( hDC, .T. )
   hwg_Settextcolor( hDC, IIf( nRow == ::nRowCurr, ::tColorSel, ::tcolor ) )

   DO WHILE ++iCol <= Len( ::aColumns ) .AND. x < x2
      oCol := ::aColumns[iCol]
      nw := Iif( iCol < Len( ::aColumns ), oCol:nWidth, x2 - x )
      IF !Empty( oCB := oCol:oPaintCB ) .AND. !Empty( block := oCB:Get( PAINT_LINE_ALL ) )
         Eval( block, oCol, hDC, x, y1, x + nw, y2, iCol )
      ELSE
         IF !Empty( oCB ) .AND. !Empty( block := oCB:Get( PAINT_LINE_BACK ) )
            Eval( block, oCol, hDC, x, y1, x + oCol:nWidth, y2, iCol )
         ELSE
            hwg_FillRect( hDC, x, y1, x + nw, y2, IIf( nRow == ::nRowCurr, ;
               Iif( iCol == :: nColCurr .AND. ::lSeleCell, ::oBrushHtb:handle, ::oBrushSel:handle ), ::oBrush:handle ) )
         ENDIF
         hwg_Drawtext( hDC, ::Cell( iCol ), x+::aRowPadding[1], y1+::aRowPadding[2],  ;
            Min( x2, x+nw-1-::aRowPadding[3] ), ;
            y2-::aRowPadding[4], oCol:nAlignRow )
      ENDIF
      x += oCol:nWidth
      i ++
   ENDDO
   hwg_Settransparentmode( hDC, .F. )

   ::nColCount := i
   ::aRows[nRow,2] := y1 + ::nHeightRow
   RETURN ::aRows[nRow,2]

METHOD HeaderOut( hDC ) CLASS HDrawnBrw

   LOCAL y1 := ::nTop + ::aMargin[2], x1 := ::nLeft + ::aMargin[1]
   LOCAL y2 := y1 + ::nHeightHead - 1, x := x1, iCol := ::nColFirst - 1
   LOCAL x2 := ::nLeft + ::nWidth - ::aMargin[3]
   LOCAL oCB, aCB, oCol, block, i, nw

   //hwg_FillRect( hDC, x1, y1, x2, y2, ::oBrush:handle )
   hwg_Settransparentmode( hDC, .T. )
   hwg_Settextcolor( hDC, ::tcolor )

   DO WHILE ++iCol <= Len( ::aColumns ) .AND. x < x2
      oCol := ::aColumns[iCol]
      nw := Iif( iCol < Len( ::aColumns ), oCol:nWidth, x2 - x )
      IF !Empty( oCB := oCol:oPaintCB ) .AND. !Empty( block := oCB:Get( PAINT_HEAD_ALL ) )
         Eval( block, oCol, hDC, x, y1, x + nw, y2, iCol )
      ELSE
         IF !Empty( oCB ) .AND. !Empty( block := oCB:Get( PAINT_HEAD_BACK ) )
            Eval( block, oCol, hDC, x, y1, x + nw, y2, iCol )
         ELSE
            ::oStyleHead:Draw( hDC, x, y1, x + nw, y2 )
         ENDIF
         IF !Empty( oCol:cHead )
            hwg_Drawtext( hDC, oCol:cHead, x+::aHeadPadding[1], y1+::aHeadPadding[2],  ;
               Min( x2, x+nw-1-::aHeadPadding[3] ), ;
               y2-::aHeadPadding[4], oCol:nAlignHead )
         ENDIF
      ENDIF
      IF !Empty( oCB ) .AND. !Empty( aCB := oCB:Get( PAINT_HEAD_ITEM ) )
         FOR i := 1 TO Len( aCB )
            Eval( aCB[i], oCol, hDC, x, y1, x + nw, y2, iCol )
         NEXT
      ENDIF
      x += oCol:nWidth
   ENDDO
   hwg_Settransparentmode( hDC, .F. )

   RETURN Nil

METHOD FooterOut( hDC ) CLASS HDrawnBrw

   HB_SYMBOL_UNUSED(hDC)
   RETURN Nil

METHOD Cell( iCol ) CLASS HDrawnBrw

   LOCAL xVal := Eval( ::aColumns[iCol]:block,, ::oData ), cType := Valtype( xVal )

   IF cType == "C"
      RETURN xVal
   ELSEIF cType == "N"
      RETURN Ltrim(Str( xVal, 25, ::aColumns[iCol]:dec ))
   ELSEIF cType == "D"
      RETURN Dtoc( xVal )
   ELSEIF cType == "L"
      RETURN Iif( xVal, "T", "F" )
   ENDIF

   RETURN hb_ValToExp( xVal )

METHOD AddColumn( cHead, block, nWidth, nAlignRow, nAlignHead, lEditable ) CLASS HDrawnBrw

   LOCAL oColumn := HBrwCol():New( cHead, block, nWidth, nAlignRow, nAlignHead, lEditable )

   AAdd( ::aColumns, oColumn )

   RETURN oColumn

METHOD Edit() CLASS HDrawnBrw

   LOCAL lRes, oCol, i
   LOCAL x1, y1, nh, xVal

   oCol := ::aColumns[::nColCurr]
   IF ::bEnter != Nil .AND. ;
         ( ValType( lRes := Eval( ::bEnter, Self, ::nColCurr, ::nRowCurr ) ) != 'L' .OR. lRes )
      RETURN Nil
   ENDIF
   IF !oCol:lEditable
      RETURN Nil
   ENDIF

   xVal := Eval( oCol:block,, ::oData )
   y1 := ::aRows[::nRowCurr,1]
   nh := ::aRows[::nRowCurr,2] - ::aRows[::nRowCurr,1]
   i := ::nColFirst - 1; x1 := ::nLeft + ::aMargin[1]
   DO WHILE ++i < ::nColCurr
      x1 += ::aColumns[i]:nWidth
   ENDDO
   ::oEdit := HDrawnEdit():New( Self, x1, y1, oCol:nWidth, nh, CLR_BLACK, CLR_WHITE, ::oFont, xVal )
   ::oEdit:nBorder := 1
   ::Refresh()

   RETURN Nil

METHOD onKey( msg, wParam, lParam ) CLASS HDrawnBrw

   HB_SYMBOL_UNUSED(lParam)

   wParam := hwg_PtrToUlong( wParam )

   IF !Empty( ::oEdit )
      IF msg == WM_KEYDOWN .AND. wParam == VK_ESCAPE
         ::oEdit:End()
         ::oEdit := Nil
         ::Refresh()
      ELSEIF msg == WM_KEYDOWN .AND. wParam == VK_RETURN
         Eval( ::aColumns[::nColCurr]:block, ::oEdit:Value, ::oData )
         ::oEdit:End()
         ::oEdit := Nil
         ::Refresh()
      ELSEIF wParam != VK_TAB
         ::oEdit:onKey( msg, wParam, lParam )
      ENDIF
      RETURN Nil
   ENDIF

   IF msg == WM_KEYDOWN
      IF wParam == VK_DOWN
         ::oData:Skip( 1 )
         IF ::oData:Eof()
            ::oData:Skip( -1 )
         ELSEIF ::nRowCurr < ::nRowCount
            ::nRowCurr ++
         ENDIF
         ::Refresh()

      ELSEIF wParam == VK_UP
         ::oData:Skip( -1 )
         IF ::oData:Bof()
            ::oData:Top()
         ENDIF
         IF ::nRowCurr > 1
            ::nRowCurr --
         ENDIF
         ::Refresh()

      ELSEIF wParam == VK_HOME
         ::oData:Top()
         ::nRowCurr := 1
         ::Refresh()

      ELSEIF wParam == VK_END
         ::oData:Bottom()
         ::nRowCurr := Min( ::nRowCount, ::oData:Count() )
         ::Refresh()

      ELSEIF wParam == VK_RIGHT
         IF ::lSeleCell
            IF ::nColCurr < Len( ::aColumns )
               IF ++ ::nColCurr >= ::nColFirst + ::nColCount
                  ::nColFirst ++
               ENDIF
               ::Refresh()
            ENDIF
         ELSE
            IF ::nColFirst + ::nColCount < Len( ::aColumns )
               ::nColFirst ++
               ::Refresh()
            ENDIF
         ENDIF

      ELSEIF wParam == VK_LEFT
         IF ::lSeleCell
            IF ::nColCurr > 1
               IF -- ::nColCurr < ::nColFirst
                  ::nColFirst --
               ENDIF
               ::Refresh()
            ENDIF
         ELSE
            IF ::nColFirst > 1
               ::nColFirst --
               ::Refresh()
            ENDIF
         ENDIF

      ELSEIF wParam == VK_PRIOR
         ::oData:Skip( -::nRowCount )
         IF ::oData:Bof()
            ::oData:Top()
            ::nRowCurr := 1
         ENDIF

      ELSEIF wParam == VK_NEXT
         ::oData:Skip( ::nRowCount )
         IF ::oData:Eof()
            ::oData:Skip( -1 )
            ::nRowCurr := Min( ::nRowCount, ::oData:Count() )
         ENDIF

      ELSEIF wParam == VK_RETURN
         ::Edit()

      ENDIF
   ENDIF

   RETURN Nil

METHOD onMouseMove( xPos, yPos ) CLASS HDrawnBrw

   HB_SYMBOL_UNUSED(xPos)
   HB_SYMBOL_UNUSED(yPos)
   RETURN Nil

METHOD onMouseLeave() CLASS HDrawnBrw
   RETURN Nil

METHOD onButtonDown( msg, xPos, yPos ) CLASS HDrawnBrw

   LOCAL i := 0

   HB_SYMBOL_UNUSED(msg)
   HB_SYMBOL_UNUSED(xPos)

   ::SetFocus()
   IF !Empty( ::oEdit )
      RETURN Nil
   ENDIF
   DO WHILE ++i <= Len( ::aRows ) .AND. ::aRows[i,1] != Nil
      IF yPos > ::aRows[i,1] .AND. yPos < ::aRows[i,2] .AND. i != ::nRowCurr
         ::oData:Skip( i - ::nRowCurr )
         ::nRowCurr := i
         ::Refresh()
         EXIT
      ENDIF
   ENDDO

   RETURN Nil

METHOD onButtonUp( xPos, yPos ) CLASS HDrawnBrw

   HB_SYMBOL_UNUSED(xPos)
   HB_SYMBOL_UNUSED(yPos)
   RETURN Nil

METHOD SetFocus() CLASS HDrawnBrw

   LOCAL oBoard := ::GetParentBoard()

   hwg_SetFocus( oBoard:handle )
   oBoard:oInFocus := Self

   RETURN Nil

METHOD Selected( n ) CLASS HDrawnBrw

   RETURN Iif( Empty(n), ::oData:Recno(), Eval( ::aColumns[n]:block,, ::oData ) )

CLASS HBrwCol INHERIT HObject

   DATA block
   DATA cHead, cFoot
   DATA nWidth
   DATA dec        INIT 0
   DATA nAlignHead, nAlignRow
   DATA tcolor, bcolor, brush
   DATA oFont
   DATA lEditable  INIT .F.      // Is the column editable

   DATA oPaintCB                 // HPaintCB object

   DATA bHeadClick

   METHOD New( cHead, block, nWidth, nAlignRow, nAlignHead, lEditable )

ENDCLASS

METHOD New( cHead, block, nWidth, nAlignRow, nAlignHead, lEditable ) CLASS HBrwCol

   ::cHead      := iif( cHead == Nil, "", cHead )
   ::block      := block
   ::nWidth     := Iif( Empty( nWidth ), DEF_COL_WIDTH, nWidth )
   ::lEditable  := iif( lEditable != Nil, lEditable, .F. )
   ::nAlignHead := iif( nAlignHead == Nil,  DT_LEFT , nAlignHead )
   ::nAlignRow  := iif( nAlignRow  == Nil,  DT_LEFT , nAlignRow  )

   RETURN Self


CLASS HBrwData INHERIT HObject

   DATA nCurrent INIT 1

   METHOD New()  INLINE Self

   METHOD Bof()     VIRTUAL
   METHOD Eof()     VIRTUAL
   METHOD Top()     VIRTUAL
   METHOD Bottom()  VIRTUAL
   METHOD Recno()   VIRTUAL
   METHOD GoTo( n ) VIRTUAL
   METHOD Count()   VIRTUAL
   METHOD Skip( nSkip ) VIRTUAL

   METHOD Block( x )    VIRTUAL
ENDCLASS

CLASS HDataArray INHERIT HBrwData

   DATA   aData

   METHOD New( arr )

   METHOD Bof()     INLINE (::nCurrent == 0)
   METHOD Eof()     INLINE (::nCurrent > Len(::aData))
   METHOD Top()     INLINE ::nCurrent := 1
   METHOD Bottom()  INLINE ::nCurrent := Len(::aData)
   METHOD Recno()   INLINE ::nCurrent
   METHOD GoTo( n )
   METHOD Count()   INLINE Len(::aData)
   METHOD Skip( nSkip )
   METHOD Block( x )

ENDCLASS

METHOD New( arr ) CLASS HDataArray

   ::aData := arr

   RETURN ::Super:New()

METHOD GoTo( n ) CLASS HDataArray

   ::nCurrent := n
   IF ::nCurrent < 1
      ::nCurrent := 0
   ELSEIF ::nCurrent > Len( ::aData )
      ::nCurrent := Len( ::aData ) + 1
   ENDIF

   RETURN Nil

METHOD Skip( nSkip ) CLASS HDataArray

   ::nCurrent += nSkip + iif( ::nCurrent == 0, 1, 0 )
   IF ::nCurrent < 1
      ::nCurrent := 0
   ELSEIF ::nCurrent > Len( ::aData )
      ::nCurrent := Len( ::aData ) + 1
   ENDIF

   RETURN Nil

METHOD Block( x ) CLASS HDataArray

   IF ValType( ::aData[1] ) == "A"
      RETURN &( "{|v,o| iif( v == Nil, o:aData[o:nCurrent," + Ltrim(Str(x)) + ;
         "], o:aData[o:nCurrent," + Ltrim(Str(x)) + "] := v ) }" )
   ENDIF

   RETURN {|value,o| iif( value == Nil, o:aData[o:nCurrent], o:aData[o:nCurrent] := value ) }

CLASS HDataDbf INHERIT HBrwData

   DATA cAlias

   METHOD New( cAlias )

   METHOD Bof()     INLINE (::cAlias)->(Bof())
   METHOD Eof()     INLINE (::cAlias)->(Eof())
   METHOD Top()     INLINE (::cAlias)->(dbGoTop())
   METHOD Bottom()  INLINE (::cAlias)->(dbGoBottom())
   METHOD Recno()   INLINE (::cAlias)->(Recno())
   METHOD GoTo( n ) INLINE (::cAlias)->(dbGoTo(n))
   METHOD Count()   INLINE (::cAlias)->(RecCount())
   METHOD Skip( nSkip )  INLINE (::cAlias)->(dbSkip(nSkip))
   METHOD Block( x )

ENDCLASS

METHOD New( cAlias ) CLASS HDataDbf

   ::cAlias := cAlias

   RETURN ::Super:New()

METHOD Block( x ) CLASS HDataDbf

   RETURN FieldWBlock( Iif( Valtype(x) == "N", FieldName( x ), x ), Select( ::cAlias ) )
