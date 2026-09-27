/*
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HChart class
 *
 * GTK4 port — target: GTK 4.24+
 *
 * NOTES
 * -----
 *  Charts are painted on a GtkDrawingArea created by HWG_CREATEBOARD
 *  (control.c).  Every cairo primitive used here — lines, filled
 *  rectangles, gradients, text — is already exposed by draw.c.
 *
 *  Styling:
 *
 *    - The widget background and border come from CSS.  A CSS class
 *      "hwg-chart" is applied in New() (see hwg_install_entry_css in
 *      window.c); its rule uses @theme_base_color, so the frame
 *      follows the current light/dark palette.  Paint() must not
 *      overwrite it.
 *
 *    - The text color comes from the theme, read once at New()
 *      through hwg_GetWidgetColor(::handle).  Axis labels, title and
 *      value text therefore follow the desktop's palette without a
 *      hardcoded table.
 *
 *    - Series colors (bars, lines, pie slices) come from the internal
 *      palette (aColors).  They are chart content, not chrome, so
 *      they are not derived from the theme.
 *
 *  Data layout, shared by every chart type:
 *
 *      aData := { { cLabel, nValue [, nValue2 [, ...]] }, ... }
 *
 *  A single value per row for Bar and Pie.  Multiple values per row
 *  for Line, where each column is a separate series.
 */

#include "hbclass.ch"
#include "hwgui.ch"

CLASS HChart INHERIT HControl

   CLASS VAR winclass  INIT "CHART"

   DATA   nType      INIT CHART_BAR
   DATA   aData      INIT {}
   DATA   cTitle     INIT ""
   DATA   aColors
   DATA   nBarGap    INIT 4
   DATA   nBorder    INIT 8
   DATA   lShowGrid  INIT .T.
   DATA   lShowValue INIT .T.
   DATA   lGradient  INIT .T.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      nType, aData, cTitle, oFont, bInit, bSize, bPaint, tcolor, ;
      bcolor, aColors, lShowGrid, lShowValue )
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD SetData( aData )
   METHOD SetColors( aColors )
   METHOD Paint()
   METHOD DrawBar( hDC )
   METHOD DrawLine( hDC )
   METHOD DrawPie( hDC )
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      nType, aData, cTitle, oFont, bInit, bSize, bPaint, tcolor, ;
      bcolor, aColors, lShowGrid, lShowValue ) CLASS HChart

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint )

   IF oFont == Nil
      ::oFont := ::oParent:oFont
   ENDIF

   ::nType      := iif( nType == Nil, CHART_BAR, nType )
   ::aData      := iif( aData == Nil, {}, aData )
   ::cTitle     := iif( cTitle == Nil, "", cTitle )
   ::aColors    := iif( aColors == Nil, DefaultPalette(), aColors )
   ::lShowGrid  := iif( lShowGrid == Nil, .T., lShowGrid )
   ::lShowValue := iif( lShowValue == Nil, .T., lShowValue )

   ::Activate()

   /* CSS: the widget paints its own background and border through
    * the .hwg-chart rule.  Paint() does not fill the background
    * any more.  Applied after Activate(), when ::handle exists. */
   hwg_AddCssClass( ::handle, "hwg-chart" )

   /* Read the resolved theme color for text.  If the caller passed
    * an explicit tcolor, honour it; otherwise follow the desktop. */
   IF tcolor == Nil
      ::tcolor := hwg_GetWidgetColor( ::handle )
   ELSE
      ::tcolor := tcolor
   ENDIF

   /* bcolor is kept only as the "fade target" for gradients.  The
    * background itself comes from CSS. */
   ::bcolor := iif( bcolor == Nil, hwg_GetThemeColors()[1], bcolor )

   RETURN Self

METHOD Activate() CLASS HChart

   IF !Empty( ::oParent:handle )
      ::handle := hwg_CreateBoard( ::oParent:handle, ::id, ::style, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD Init() CLASS HChart

   IF !::lInit
      ::Super:Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HChart

   HB_SYMBOL_UNUSED( wParam )
   HB_SYMBOL_UNUSED( lParam )

   IF msg == WM_PAINT
      ::Paint()
      RETURN 0
   ENDIF

   RETURN -1

METHOD SetData( aData ) CLASS HChart

   ::aData := iif( aData == Nil, {}, aData )
   IF ::handle != Nil
      hwg_Redrawwindow( ::handle )
   ENDIF

   RETURN Nil

METHOD SetColors( aColors ) CLASS HChart

   IF aColors != Nil .AND. ValType( aColors ) == "A"
      ::aColors := aColors
      IF ::handle != Nil
         hwg_Redrawwindow( ::handle )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Paint() CLASS HChart

   LOCAL hDC, aCoors, nCorner := 6

   IF Empty( ::aData )
      RETURN Nil
   ENDIF

   hDC := hwg_Getdc( ::handle )
   IF ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
   ENDIF

   aCoors := hwg_Getclientrect( ::handle )

   /* Frame drawn in Cairo: GtkDrawingArea does not render CSS --
    * its snapshot override calls draw_func and skips the CSS pass
    * of GtkWidget.  So background, border and rounded corners must
    * be painted here. */
   hwg_Fillrect( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], ;
      HBrush():Add( ::bcolor ):handle )

   hwg_Selectobject( hDC, HPen():Add( PS_SOLID, 1, ;
      MixColor( ::tcolor, 0, 0.65 ) ):handle )
   hwg_RoundRect( hDC, ;
      aCoors[1] + 1, aCoors[2] + 1, ;
      aCoors[3] - 1, aCoors[4] - 1, nCorner )

   hwg_Settextcolor( hDC, ::tcolor )

   IF !Empty( ::cTitle )
      hwg_Drawtext( hDC, ::cTitle, aCoors[1], aCoors[2] + 4, ;
         aCoors[3], aCoors[2] + 26, DT_CENTER )
   ENDIF

   DO CASE
   CASE ::nType == CHART_BAR
      ::DrawBar( hDC )
   CASE ::nType == CHART_LINE
      ::DrawLine( hDC )
   CASE ::nType == CHART_PIE
      ::DrawPie( hDC )
   ENDCASE

   hwg_Releasedc( ::handle, hDC )

   RETURN Nil

METHOD DrawBar( hDC ) CLASS HChart

   LOCAL aCoors := hwg_Getclientrect( ::handle )
   LOCAL nTop := aCoors[2] + iif( Empty( ::cTitle ), ::nBorder, 30 )
   LOCAL nBottom := aCoors[4] - 24
   LOCAL nLeft := aCoors[1] + ::nBorder + 40
   LOCAL nRight := aCoors[3] - ::nBorder
   LOCAL nRows := Len( ::aData )
   LOCAL nBarW, nMax, i, j, nVal, nH, x, y, nColor
   LOCAL nCols := MaxValues( ::aData )
   LOCAL nSeriesW, nSeriesX

   IF nRows == 0 .OR. nRight <= nLeft .OR. nBottom <= nTop
      RETURN Nil
   ENDIF

   nMax := MaxValue( ::aData )
   IF nMax <= 0
      RETURN Nil
   ENDIF

   hwg_Settextcolor( hDC, ::tcolor )

   IF ::lShowGrid
      hwg_Selectobject( hDC, HPen():Add( PS_SOLID, 1, ;
         MixColor( ::tcolor, 0, 0.80 ) ):handle )
      FOR i := 0 TO 4
         y := nBottom - Int( ( nBottom - nTop ) * i / 4 )
         hwg_Drawline( hDC, nLeft, y, nRight, y )
      NEXT
   ENDIF

   FOR i := 0 TO 4
      y := nBottom - Int( ( nBottom - nTop ) * i / 4 )
      nVal := Int( nMax * i / 4 )
      hwg_Drawtext( hDC, Ltrim( Str( nVal ) ), ;
         aCoors[1] + ::nBorder, y - 8, nLeft - 4, y + 8, DT_RIGHT )
   NEXT

   nBarW := Int( ( nRight - nLeft ) / nRows )
   IF nBarW < 4
      nBarW := 4
   ENDIF
   nSeriesW := Int( ( nBarW - ::nBarGap ) / nCols )

   FOR i := 1 TO nRows
      x := nLeft + ( i - 1 ) * nBarW + ::nBarGap / 2

      FOR j := 1 TO nCols
         nVal := DataValue( ::aData[i], j )
         nH := Int( ( nBottom - nTop ) * nVal / nMax )
         nSeriesX := x + ( j - 1 ) * nSeriesW
         nColor := ColorAt( ::aColors, j )

         IF ::lGradient .AND. nSeriesW > 2
            /* Stronger contrast so the gradient is visible. */
            hwg_DrawGradient( hDC, nSeriesX, nBottom - nH, ;
                              nSeriesX + nSeriesW - 1, nBottom, ;
                              1, ;
                              { Lighten( nColor, 110 ), Darken( nColor, 55 ) }, ;
                              { 0.0, 1.0 } )

            /* Top highlight: a thin translucent white band makes the
             * bar read as a 3D cylinder without leaving the colour. */
            hwg_FillRectAlpha( hDC, nSeriesX, nBottom - nH, ;
               nSeriesX + nSeriesW - 1, nBottom - nH + 3, ;
               0xFFFFFF, 0.35 )
         ELSE
            hwg_Fillrect( hDC, nSeriesX, nBottom - nH, ;
               nSeriesX + nSeriesW - 1, nBottom, ;
               HBrush():Add( nColor ):handle )
         ENDIF

         IF ::lShowValue .AND. nCols == 1
            hwg_Drawtext( hDC, Ltrim( Str( nVal ) ), ;
               nSeriesX, nBottom - nH - 20, ;
               nSeriesX + nSeriesW, nBottom - nH - 2, DT_CENTER )
         ENDIF
      NEXT

      hwg_Drawtext( hDC, AllTrim( ::aData[i,1] ), ;
         x, nBottom + 2, x + nBarW, nBottom + 20, DT_CENTER )
   NEXT

   hwg_Selectobject( hDC, HPen():Add( PS_SOLID, 1, ::tcolor ):handle )
   hwg_Drawline( hDC, nLeft, nBottom, nRight, nBottom )
   hwg_Drawline( hDC, nLeft, nTop,    nLeft,  nBottom )

   RETURN Nil

METHOD DrawLine( hDC ) CLASS HChart

   LOCAL aCoors := hwg_Getclientrect( ::handle )
   LOCAL nTop := aCoors[2] + iif( Empty( ::cTitle ), ::nBorder, 30 )
   LOCAL nBottom := aCoors[4] - 24
   LOCAL nLeft := aCoors[1] + ::nBorder + 40
   LOCAL nRight := aCoors[3] - ::nBorder
   LOCAL nRows := Len( ::aData )
   LOCAL nCols := MaxValues( ::aData )
   LOCAL nMax, i, j, x, y, xPrev, yPrev, nVal, nStep, nColor
   LOCAL aPoints

   IF nRows < 2 .OR. nRight <= nLeft .OR. nBottom <= nTop
      RETURN Nil
   ENDIF

   nMax := MaxValue( ::aData )
   IF nMax <= 0
      RETURN Nil
   ENDIF

   hwg_Settextcolor( hDC, ::tcolor )

   IF ::lShowGrid
      hwg_Selectobject( hDC, HPen():Add( PS_SOLID, 1, ;
         MixColor( ::tcolor, 0, 0.80 ) ):handle )
      FOR i := 0 TO 4
         y := nBottom - Int( ( nBottom - nTop ) * i / 4 )
         hwg_Drawline( hDC, nLeft, y, nRight, y )
      NEXT
   ENDIF

   FOR i := 0 TO 4
      y := nBottom - Int( ( nBottom - nTop ) * i / 4 )
      hwg_Drawtext( hDC, Ltrim( Str( Int( nMax * i / 4 ) ) ), ;
         aCoors[1] + ::nBorder, y - 8, nLeft - 4, y + 8, DT_RIGHT )
   NEXT

   nStep := Int( ( nRight - nLeft ) / ( nRows - 1 ) )

   FOR j := 1 TO nCols
      nColor := ColorAt( ::aColors, j )

      /* Area fill under the line: one polygon per series, from the
       * curve down to the axis.  A single Cairo path means the
       * gradient runs continuously from the top of the curve to the
       * bottom of the area, with no seams between segments. */
      aPoints := {}
      FOR i := 1 TO nRows
         nVal := DataValue( ::aData[i], j )
         x    := nLeft + ( i - 1 ) * nStep
         y    := nBottom - Int( ( nBottom - nTop ) * nVal / nMax )
         AAdd( aPoints, { x, y } )
      NEXT
      /* Close the polygon along the axis line. */
      AAdd( aPoints, { nLeft + ( nRows - 1 ) * nStep, nBottom } )
      AAdd( aPoints, { nLeft, nBottom } )

      hwg_FillPolygonGradient( hDC, aPoints, ;
         FadeColor( nColor, 0.55 ), ::bcolor )

      /* The curve itself, drawn on top of the area. */
      hwg_Selectobject( hDC, HPen():Add( PS_SOLID, 2, nColor ):handle )

      xPrev := nLeft
      yPrev := 0

      FOR i := 1 TO nRows
         nVal := DataValue( ::aData[i], j )
         x := nLeft + ( i - 1 ) * nStep
         y := nBottom - Int( ( nBottom - nTop ) * nVal / nMax )

         IF i > 1
            hwg_Drawline( hDC, xPrev, yPrev, x, y )
         ENDIF
         hwg_Fillrect( hDC, x - 3, y - 3, x + 3, y + 3, ;
            HBrush():Add( nColor ):handle )

         xPrev := x
         yPrev := y
      NEXT
   NEXT

   FOR i := 1 TO nRows
      IF i == 1 .OR. i == nRows .OR. i == Int( nRows / 2 ) + 1
         x := nLeft + ( i - 1 ) * nStep
         hwg_Drawtext( hDC, AllTrim( ::aData[i,1] ), ;
            x - 30, nBottom + 2, x + 30, nBottom + 20, DT_CENTER )
      ENDIF
   NEXT

   hwg_Selectobject( hDC, HPen():Add( PS_SOLID, 1, ::tcolor ):handle )
   hwg_Drawline( hDC, nLeft, nBottom, nRight, nBottom )
   hwg_Drawline( hDC, nLeft, nTop,    nLeft,  nBottom )

   RETURN Nil

METHOD DrawPie( hDC ) CLASS HChart

   LOCAL aCoors := hwg_Getclientrect( ::handle )
   LOCAL nTop := aCoors[2] + iif( Empty( ::cTitle ), ::nBorder, 30 )
   LOCAL nBottom := aCoors[4] - ::nBorder
   LOCAL nLeft := aCoors[1] + ::nBorder
   LOCAL nRight := aCoors[3] - ::nBorder
   LOCAL nRows := Len( ::aData )
   LOCAL nTotal := 0, i, nVal, nAngle, nAngleEnd
   LOCAL nCx, nCy, nRadius, nTextY, nColor

   IF nRows == 0
      RETURN Nil
   ENDIF

   nRadius := Min( ( nRight - nLeft - 140 ) / 2, ( nBottom - nTop ) / 2 ) - 10
   IF nRadius < 20
      nRadius := 20
   ENDIF
   nCx := nLeft + nRadius + 20
   nCy := nTop + ( nBottom - nTop ) / 2

   FOR i := 1 TO nRows
      nTotal += DataValue( ::aData[i], 1 )
   NEXT
   IF nTotal <= 0
      RETURN Nil
   ENDIF

   hwg_Settextcolor( hDC, ::tcolor )

   /* Drop shadow: a translucent black disc offset a few pixels
    * down-right, drawn before the slices.  Slightly stronger
    * opacity and offset so the effect is visible against the dark
    * theme -- 0.25 / +4 reads as almost nothing under @theme_base_color. */
      hwg_Settextcolor( hDC, ::tcolor )

   /* Drop shadow: three concentric ellipses with decreasing alpha,
    * painted before the slices.  Cairo has no blur, so the soft edge
    * is approximated by stacking translucent circles. */
   hwg_EllipseAlpha( hDC, ;
      nCx - nRadius + 3, nCy - nRadius + 3, ;
      nCx + nRadius + 3, nCy + nRadius + 3, ;
      0x000000, 0.20 )

   hwg_EllipseAlpha( hDC, ;
      nCx - nRadius + 6, nCy - nRadius + 6, ;
      nCx + nRadius + 6, nCy + nRadius + 6, ;
      0x000000, 0.15 )

   hwg_EllipseAlpha( hDC, ;
      nCx - nRadius + 9, nCy - nRadius + 9, ;
      nCx + nRadius + 9, nCy + nRadius + 9, ;
      0x000000, 0.10 )

   nAngle := -90.0

   FOR i := 1 TO nRows
      nVal := DataValue( ::aData[i], 1 )
      nAngleEnd := nAngle + 360.0 * nVal / nTotal
      nColor := ColorAt( ::aColors, (( i - 1 ) % Len( ::aColors )) + 1 )

      hwg_DrawPie( hDC, nCx, nCy, nRadius, nAngle, nAngleEnd, ;
         HBrush():Add( nColor ):handle )

      nTextY := nTop + ( i - 1 ) * 22 + 10
      hwg_Fillrect( hDC, nRight - 130, nTextY, nRight - 116, nTextY + 14, ;
         HBrush():Add( nColor ):handle )
      hwg_Drawtext( hDC, AllTrim( ::aData[i,1] ) + " (" + ;
         Ltrim( Str( Int( 100 * nVal / nTotal ) ) ) + "%)", ;
         nRight - 110, nTextY - 1, nRight - 6, nTextY + 16, DT_LEFT )

      nAngle := nAngleEnd
   NEXT

   RETURN Nil

METHOD End() CLASS HChart

   ::Super:End()

   RETURN Nil


/* ---------------------------------------------------------------- */
/*  Helpers                                                          */
/* ---------------------------------------------------------------- */

STATIC FUNCTION DefaultPalette()

   RETURN { ;
      0x4A90D9, ;
      0xE67E22, ;
      0x27AE60, ;
      0xC0392B, ;
      0x8E44AD, ;
      0x16A085, ;
      0xF39C12, ;
      0x7F8C8D }

STATIC FUNCTION MaxValue( aData )

   LOCAL i, j, nMax := 0, nVal

   FOR i := 1 TO Len( aData )
      FOR j := 2 TO Len( aData[i] )
         nVal := aData[i,j]
         IF ValType( nVal ) == "N" .AND. nVal > nMax
            nMax := nVal
         ENDIF
      NEXT
   NEXT

   RETURN nMax

STATIC FUNCTION MaxValues( aData )

   LOCAL n := 0

   IF Len( aData ) > 0
      n := Len( aData[1] ) - 1
   ENDIF

   RETURN iif( n < 1, 1, n )

STATIC FUNCTION DataValue( aRow, nCol )

   IF nCol + 1 <= Len( aRow ) .AND. ValType( aRow[nCol+1] ) == "N"
      RETURN aRow[nCol+1]
   ENDIF

   RETURN 0

STATIC FUNCTION ColorAt( aColors, n )

   IF Empty( aColors )
      RETURN 0x4A90D9
   ENDIF

   RETURN aColors[ (( n - 1 ) % Len( aColors )) + 1 ]

STATIC FUNCTION Lighten( nColor, nDelta )

   RETURN MixColor( nColor, 255, nDelta / 255.0 )

STATIC FUNCTION Darken( nColor, nDelta )

   RETURN MixColor( nColor, 0, nDelta / 255.0 )

STATIC FUNCTION FadeColor( nColor, nAmount )

   /* Blend toward white.  nAmount is 0..1; higher means lighter. */
   RETURN MixColor( nColor, 255, nAmount )

STATIC FUNCTION MixColor( nColor, nTarget, nAmount )

   LOCAL r, g, b, t

   r :=   nColor         % 256
   g := Int( nColor /  256 ) % 256
   b := Int( nColor / 65536 ) % 256

   t := iif( nTarget == 0, 0, 255 )
   r := Int( r + ( t - r ) * nAmount )
   g := Int( g + ( t - g ) * nAmount )
   b := Int( b + ( t - b ) * nAmount )

   r := Max( 0, Min( 255, r ) )
   g := Max( 0, Min( 255, g ) )
   b := Max( 0, Min( 255, b ) )

   RETURN r + g * 256 + b * 65536
