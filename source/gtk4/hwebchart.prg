/*
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HWebChart class
 *
 * GTK4 port — target: GTK 4.24+
 *
 * NOTES
 * -----
 *  High-level wrapper that turns aData (same layout as HChart) into
 *  a Chart.js page rendered inside a WebKitWebView.
 *
 *      aData := { { cLabel, nValue [, nValue2 [, ...]] }, ... }
 *
 *  Series type is chosen by nType:
 *
 *      CHART_BAR   ->  Chart.js "bar"
 *      CHART_LINE  ->  Chart.js "line"
 *      CHART_PIE   ->  Chart.js "doughnut"
 *
 *  All the visual chrome (dark theme, rounded cards, hover, tooltips,
 *  animations) comes from the HTML generated in BuildHTML().  Data
 *  and palette come from Harbour.
 */

#include "hbclass.ch"
#include "hwgui.ch"

CLASS HWebChart INHERIT HWebView

   DATA   nType      INIT CHART_BAR
   DATA   aData      INIT {}
   DATA   cTitle     INIT ""
   DATA   aColors
   DATA   cExtraJS   INIT ""       // appended to the chart options
   DATA   lDark      INIT .T.      // dark (T) or light (F) theme
   DATA   lAnimated  INIT .T.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      nType, aData, cTitle, aColors, cExtraJS, lDark )
   METHOD SetData( aData )
   METHOD SetColors( aColors )
   METHOD SetTitle( cTitle )
   METHOD Refresh()
   METHOD BuildHTML()
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      nType, aData, cTitle, aColors, cExtraJS, lDark ) CLASS HWebChart

   ::nType    := iif( nType   == Nil, CHART_BAR,        nType )
   ::aData    := iif( aData   == Nil, {},               aData )
   ::cTitle   := iif( cTitle  == Nil, "",               cTitle )
   ::aColors  := iif( aColors == Nil, WebChartPalette(), aColors )
   ::cExtraJS := iif( cExtraJS == Nil, "",              cExtraJS )
   ::lDark    := iif( lDark   == Nil, .T.,              lDark )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      ::BuildHTML() )

   RETURN Self

METHOD SetData( aData ) CLASS HWebChart

   IF aData != Nil .AND. ValType( aData ) == "A"
      ::aData := aData
      ::Refresh()
   ENDIF

   RETURN Nil

METHOD SetColors( aColors ) CLASS HWebChart

   IF aColors != Nil .AND. ValType( aColors ) == "A"
      ::aColors := aColors
      ::Refresh()
   ENDIF

   RETURN Nil

METHOD SetTitle( cTitle ) CLASS HWebChart

   IF cTitle != Nil
      ::cTitle := cTitle
      ::Refresh()
   ENDIF

   RETURN Nil

METHOD Refresh() CLASS HWebChart

   ::LoadHTML( ::BuildHTML() )

   RETURN Nil

METHOD BuildHTML() CLASS HWebChart

   LOCAL cLabels, cDatasets, cChartType
   LOCAL cBG, cFG, cCardBG, cBorder, cGrid
   LOCAL i, j, nRows, nCols, nColor, cHex

   nRows := Len( ::aData )
   nCols := WebChartMaxValues( ::aData )

   /* Chart.js type name.  Pie is drawn as a doughnut -- same layout,
    * but with the modern cut-out centre. */
   DO CASE
   CASE ::nType == CHART_LINE
      cChartType := "line"
   CASE ::nType == CHART_PIE
      cChartType := "doughnut"
   OTHERWISE
      cChartType := "bar"
   ENDCASE

   /* Theme palette: the whole page follows it.  Two variants so the
    * same class can serve a light and a dark app. */
   IF ::lDark
      cBG     := "#1e1e1e"
      cFG     := "#e6e8eb"
      cCardBG := "linear-gradient(160deg,#1e2128 0%,#171a20 100%)"
      cBorder := "rgba(255,255,255,0.06)"
      cGrid   := "rgba(255,255,255,0.06)"
   ELSE
      cBG     := "#f5f7fa"
      cFG     := "#1f2933"
      cCardBG := "linear-gradient(160deg,#ffffff 0%,#f8fafc 100%)"
      cBorder := "rgba(0,0,0,0.06)"
      cGrid   := "rgba(0,0,0,0.06)"
   ENDIF

   /* Labels: first column of every row. */
   cLabels := "["
   FOR i := 1 TO nRows
      cLabels += '"' + WebChartEscape( AllTrim( ::aData[i,1] ) ) + '"'
      IF i < nRows
         cLabels += ","
      ENDIF
   NEXT
   cLabels += "]"

   /* Datasets.
    *
    * Bar and line: one dataset per value column.  Pie: one dataset
    * with all values, since Chart.js wants pie/doughnut data in a
    * single array with per-slice colours. */
   IF ::nType == CHART_PIE
      cDatasets := "[{"
      cDatasets += 'data:['
      FOR i := 1 TO nRows
         cDatasets += LTrim( Str( WebChartValue( ::aData[i], 1 ) ) )
         IF i < nRows
            cDatasets += ","
         ENDIF
      NEXT
      cDatasets += "],"
      cDatasets += "backgroundColor:["
      FOR i := 1 TO nRows
         nColor := ::aColors[ (( i - 1 ) % Len( ::aColors )) + 1 ]
         cDatasets += '"' + WebChartHexColor( nColor ) + '"'
         IF i < nRows
            cDatasets += ","
         ENDIF
      NEXT
      cDatasets += "],"
      cDatasets += 'borderColor:"' + iif( ::lDark, "#171a20", "#ffffff" ) + '",'
      cDatasets += "borderWidth:4,"
      cDatasets += "hoverOffset:8"
      cDatasets += "}]"
   ELSE
      cDatasets := "["
      FOR j := 1 TO nCols
         nColor := ::aColors[ (( j - 1 ) % Len( ::aColors )) + 1 ]
         cHex   := WebChartHexColor( nColor )

         cDatasets += "{"
         cDatasets += 'label:"Série ' + LTrim( Str( j ) ) + '",'
         cDatasets += "data:["
         FOR i := 1 TO nRows
            cDatasets += LTrim( Str( WebChartValue( ::aData[i], j ) ) )
            IF i < nRows
               cDatasets += ","
            ENDIF
         NEXT
         cDatasets += "],"

         IF ::nType == CHART_LINE
            cDatasets += 'borderColor:"' + cHex + '",'
            cDatasets += "borderWidth:3,"
            cDatasets += "tension:0.35,"
            cDatasets += "fill:true,"
            cDatasets += 'backgroundColor:"' + WebChartFadeColor( cHex, 0.20 ) + '",'
            cDatasets += 'pointBackgroundColor:"' + cHex + '",'
            cDatasets += "pointRadius:3,"
            cDatasets += "pointHoverRadius:6"
         ELSE
            cDatasets += 'backgroundColor:"' + cHex + '",'
            cDatasets += "borderRadius:6,"
            cDatasets += "borderSkipped:false"
         ENDIF

         cDatasets += "}"
         IF j < nCols
            cDatasets += ","
         ENDIF
      NEXT
      cDatasets += "]"
   ENDIF

   /* The complete page.  Layout mirrors the dashboard sample but
    * every knob is set from here, so the caller only sees Harbour
    * data. */
   RETURN WebChartPage( cBG, cFG, cCardBG, cBorder, cGrid, ;
                        ::cTitle, cChartType, cLabels, cDatasets, ;
                        ::cExtraJS, ::lDark, ::nType )

METHOD End() CLASS HWebChart

   ::Super:End()

   RETURN Nil


/* ---------------------------------------------------------------- */
/*  Helpers                                                          */
/* ---------------------------------------------------------------- */

/* Modern palette tuned for both light and dark backgrounds.  Kept
 * separate from HChart's palette so the browser version can use
 * slightly lighter tones that read better against a dark canvas. */
STATIC FUNCTION WebChartPalette()

   RETURN { ;
      0x5DADE2, ;   // lighter blue
      0xF5B041, ;   // lighter orange
      0x52BE80, ;   // lighter green
      0xEC7063, ;   // lighter red
      0xAF7AC5, ;   // lighter purple
      0x48C9B0, ;   // lighter teal
      0xF7DC6F, ;   // lighter yellow
      0xAAB7B8 }    // lighter gray

STATIC FUNCTION WebChartMaxValues( aData )

   LOCAL n := 0

   IF Len( aData ) > 0
      n := Len( aData[1] ) - 1
   ENDIF

   RETURN iif( n < 1, 1, n )

STATIC FUNCTION WebChartValue( aRow, nCol )

   IF nCol + 1 <= Len( aRow ) .AND. ValType( aRow[nCol+1] ) == "N"
      RETURN aRow[nCol+1]
   ENDIF

   RETURN 0

/* HWGUI COLORREF (0x00BBGGRR) -> "#rrggbb". */
STATIC FUNCTION WebChartHexColor( nColor )

   LOCAL r, g, b

   r :=   nColor         % 256
   g := Int( nColor /  256 ) % 256
   b := Int( nColor / 65536 ) % 256

   RETURN "#" + WebChartHex2( r ) + WebChartHex2( g ) + WebChartHex2( b )

STATIC FUNCTION WebChartHex2( n )

   LOCAL cHex := "0123456789abcdef"
   LOCAL n1 := Int( n / 16 )
   LOCAL n2 := n % 16

   RETURN SubStr( cHex, n1 + 1, 1 ) + SubStr( cHex, n2 + 1, 1 )

/* Turn "#rrggbb" into "rgba(r,g,b,alpha)".  Used for line fills. */
STATIC FUNCTION WebChartFadeColor( cHex, nAlpha )

   LOCAL r, g, b

   r := WebChartHexVal( SubStr( cHex, 2, 1 ) ) * 16 + WebChartHexVal( SubStr( cHex, 3, 1 ) )
   g := WebChartHexVal( SubStr( cHex, 4, 1 ) ) * 16 + WebChartHexVal( SubStr( cHex, 5, 1 ) )
   b := WebChartHexVal( SubStr( cHex, 6, 1 ) ) * 16 + WebChartHexVal( SubStr( cHex, 7, 1 ) )

   RETURN "rgba(" + LTrim( Str( r ) ) + "," + LTrim( Str( g ) ) + "," + ;
                  LTrim( Str( b ) ) + "," + LTrim( Str( nAlpha, 4, 2 ) ) + ")"

STATIC FUNCTION WebChartHexVal( c )

   c := Lower( c )

   IF c >= "0" .AND. c <= "9"
      RETURN Asc( c ) - Asc( "0" )
   ENDIF

   RETURN Asc( c ) - Asc( "a" ) + 10

/* Escape a Harbour string for safe inclusion in a JS string literal.
 * Only the double quote and the backslash need escaping in practice;
 * quotes in labels are the only realistic risk. */
STATIC FUNCTION WebChartEscape( cText )

   IF cText == Nil
      RETURN ""
   ENDIF

   cText := StrTran( cText, "\", "\\" )
   cText := StrTran( cText, '"', '\"' )

   RETURN cText

/* Compose the whole HTML page.  One function, one string -- easier to
 * inspect than assembling it in the caller. */
STATIC FUNCTION WebChartPage( cBG, cFG, cCardBG, cBorder, cGrid, ;
                              cTitle, cChartType, cLabels, cDatasets, ;
                              cExtraJS, lDark, nType )

   LOCAL s

   s := '<!DOCTYPE html><html><head><meta charset="utf-8">'
   s += '<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>'
   s += '<style>'
   s += '* { box-sizing: border-box; margin: 0; padding: 0; }'
   s += 'html, body { height: 100%; }'
   s += 'body {'
   s += '  background: ' + cBG + ';'
   s += '  color: ' + cFG + ';'
   s += '  font-family: "Noto Sans", system-ui, sans-serif;'
   s += '  padding: 14px;'
   s += '  overflow: hidden;'
   s += '}'
   s += '.card {'
   s += '  background: ' + cCardBG + ';'
   s += '  border: 1px solid ' + cBorder + ';'
   s += '  border-radius: 12px;'
   s += '  padding: 16px 18px;'
   s += '  box-shadow:'
   s += '    0 10px 20px rgba(0,0,0,' + iif( lDark, "0.45", "0.08" ) + '),'
   s += '    0 2px 4px rgba(0,0,0,' + iif( lDark, "0.35", "0.06" ) + '),'
   s += '    inset 0 1px 0 rgba(255,255,255,' + iif( lDark, "0.05", "0.60" ) + ');'
   s += '  height: 100%;'
   s += '  display: flex;'
   s += '  flex-direction: column;'
   s += '}'
   s += '.title {'
   s += '  font-size: 12px;'
   s += '  font-weight: 600;'
   s += '  letter-spacing: 0.7px;'
   s += '  text-transform: uppercase;'
   s += '  color: ' + iif( lDark, "#8f97a6", "#5a6672" ) + ';'
   s += '  margin-bottom: 12px;'
   s += '}'
   s += '.chart-wrap {'
   s += '  flex: 1;'
   s += '  position: relative;'
   s += '  min-height: 0;'
   s += '}'
   s += 'canvas { display: block; }'
   s += '</style></head><body>'

   s += '<div class="card">'
   IF !Empty( cTitle )
      s += '<div class="title">' + cTitle + '</div>'
   ENDIF
   s += '<div class="chart-wrap"><canvas id="chart"></canvas></div>'
   s += '</div>'

   s += '<script>'
   s += 'Chart.defaults.color = ' + '"' + iif( lDark, "#b6bcc8", "#4a5568" ) + '";'
   s += 'Chart.defaults.font.family = "Noto Sans, sans-serif";'

   s += 'new Chart(document.getElementById("chart"), {'
   s += '  type: "' + cChartType + '",'
   s += '  data: { labels: ' + cLabels + ', datasets: ' + cDatasets + ' },'
   s += '  options: {'

   IF nType == CHART_PIE
      s += '    cutout: "68%",'
      s += '    plugins: { legend: { position: "right", labels: { color: "' + ;
           iif( lDark, "#b6bcc8", "#4a5568" ) + '" } } },'
   ELSE
      s += '    responsive: true, maintainAspectRatio: false,'
      s += '    plugins: { legend: { display: ' + ;
           iif( nType == CHART_BAR .AND. WebChartSeriesCount( cDatasets ) > 1, "true", "false" ) + ;
           ', labels: { color: "' + iif( lDark, "#b6bcc8", "#4a5568" ) + '" } } },'
      s += '    scales: {'
      s += '      x: { grid: { color: "' + cGrid + '" } },'
      s += '      y: { grid: { color: "' + cGrid + '" }, beginAtZero: true }'
      s += '    },'
      IF nType == CHART_LINE
         s += '    tension: 0.35,'
         s += '    interaction: { intersect: false, mode: "index" },'
      ENDIF
      s += '    animation: { duration: 900, easing: "easeOutQuart" }'
   ENDIF

   IF !Empty( cExtraJS )
      s += ',' + cExtraJS
   ENDIF

   s += '  }'
   s += '});'
   s += '</script></body></html>'

   RETURN s

/* Quick check: count the number of datasets in the JSON we built.
 * Only used to decide whether to show the legend. */
STATIC FUNCTION WebChartSeriesCount( cDatasets )

   LOCAL n := 0, i

   FOR i := 1 TO Len( cDatasets )
      IF SubStr( cDatasets, i, 1 ) == "{"
         n++
      ENDIF
   NEXT

   RETURN n
