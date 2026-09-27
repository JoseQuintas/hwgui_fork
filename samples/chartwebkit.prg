/*
 * chartweb.prg
 *
 * Renders the same chart data with Chart.js inside a WebKitWebView.
 * Compare with the Cairo HChart: the browser engine handles
 * gradients, shadows, tooltips and animations for free.
 *
 * Build:
 *     hbmk2 chartweb.prg ../hwguiGTK4.hbc
 */

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDlg, oWv, cHTML

   cHTML := ChartHTML( ;
      { "Jan", "Feb", "Mar", "Apr", "May", "Jun" }, ;
      { { "Sales 2025", { 120, 150, 180, 140, 210, 175 }, "#4A90D9" }, ;
        { "Sales 2026", {  80,  95, 110, 130, 155, 140 }, "#E67E22" } } )

   INIT DIALOG oDlg TITLE "WebKit chart" AT 100, 100 SIZE 900, 620

   oWv := HWebView():New( oDlg, 0, 0, 20, 20, 860, 560, cHTML )

   ACTIVATE DIALOG oDlg CENTER

   HB_SYMBOL_UNUSED( oWv )

   RETURN Nil

/*
 * Build the HTML that Chart.js consumes.  All visual decisions --
 * grid colour, gradient, shadow, dark/light theme -- are done in CSS
 * and Chart.js options, not in C code.
 */
STATIC FUNCTION ChartHTML( aLabels, aSeries )

   LOCAL cLabels := "[", cDatasets := "[", i, j, s
   LOCAL cBG, cFG

   /* Detect dark theme roughly the same way the HWGUI charts do.
    * In a real app this can come from a Harbour call; here we keep
    * it simple and let the page match the container background. */
   cBG := "#1e1e1e"
   cFG := "#e0e0e0"

   FOR i := 1 TO Len( aLabels )
      cLabels += '"' + aLabels[i] + '"'
      IF i < Len( aLabels )
         cLabels += ","
      ENDIF
   NEXT
   cLabels += "]"

   FOR i := 1 TO Len( aSeries )
      cDatasets += "{"
      cDatasets += 'label:"' + aSeries[i,1] + '",'
      cDatasets += "data:["
      FOR j := 1 TO Len( aSeries[i,2] )
         cDatasets += LTrim( Str( aSeries[i,2,j] ) )
         IF j < Len( aSeries[i,2] )
            cDatasets += ","
         ENDIF
      NEXT
      cDatasets += "],"
      cDatasets += 'backgroundColor:"' + aSeries[i,3] + '",'
      cDatasets += "borderRadius:6,"
      cDatasets += "borderSkipped:false"
      cDatasets += "}"
      IF i < Len( aSeries )
         cDatasets += ","
      ENDIF
   NEXT
   cDatasets += "]"

   s := '<!DOCTYPE html><html><head><meta charset="utf-8">'
   s += '<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>'
   s += '<style>'
   s += 'body{margin:0;background:' + cBG + ';color:' + cFG + ';'
   s += 'font-family:Noto Sans,sans-serif}'
   s += 'canvas{max-height:540px}'
   s += '</style></head><body>'
   s += '<canvas id="c"></canvas>'
   s += '<script>'
   s += 'new Chart(document.getElementById("c"),{'
   s += 'type:"bar",'
   s += 'data:{labels:' + cLabels + ',datasets:' + cDatasets + '},'
   s += 'options:{responsive:true,maintainAspectRatio:false,'
   s += 'plugins:{legend:{labels:{color:"' + cFG + '"}}},'
   s += 'scales:{'
   s += 'x:{ticks:{color:"' + cFG + '"},grid:{color:"rgba(255,255,255,0.08)"}},'
   s += 'y:{ticks:{color:"' + cFG + '"},grid:{color:"rgba(255,255,255,0.08)"}}'
   s += '}}});'
   s += '</script></body></html>'

   RETURN s
