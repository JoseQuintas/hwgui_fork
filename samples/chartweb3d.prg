/*
 * chartweb3d.prg
 *
 * Rich dashboard rendered inside a WebKitWebView.  Demonstrates what
 * the browser engine adds over the Cairo-based HChart:
 *
 *   - 3D bars via CSS transforms (perspective + rotateY) applied to
 *     the Chart.js canvas container.
 *   - Donut with a real gradient stroke and a soft drop shadow.
 *   - Animated gauge drawn with SVG and CSS animation.
 *   - Line chart with a glow (filter: drop-shadow) on the stroke.
 *   - CSS progress bar animated with keyframes.
 *
 * Everything is a single HTML string built in Harbour.  The purpose
 * is not to be the "best" dashboard but to show the range of effects
 * that are now one HTML tag away.
 *
 * Build:
 *     hbmk2 chartweb3d.prg
 * Run:
 *     ./chartweb3d
 */

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDlg, oWv, cHTML

   cHTML := DashboardHTML()

   INIT DIALOG oDlg TITLE "WebKit dashboard 3D" AT 80, 60 SIZE 1200, 800

   oWv := HWebView():New( oDlg, 0, 0, 10, 10, 1180, 750, cHTML )

   ACTIVATE DIALOG oDlg CENTER

   HB_SYMBOL_UNUSED( oWv )

   RETURN Nil


/*
 * Build the whole page as one string.  Keeping it in a single function
 * makes it easy to change the data later -- the layout, the palette
 * and the animations live here, not in C code.
 */
STATIC FUNCTION DashboardHTML()

   LOCAL s

   s := '<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8">'
   s += '<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>'
   s += '<style>'

   /* ---- Global: dark theme, typography, layout grid ---- */
   s += '* { box-sizing: border-box; margin: 0; padding: 0; }'
   s += 'body {'
   s += '  background: radial-gradient(circle at 20% 20%, #1a1d24 0%, #0f1115 60%);'
   s += '  color: #e6e8eb;'
   s += '  font-family: "Noto Sans", system-ui, sans-serif;'
   s += '  padding: 20px;'
   s += '  min-height: 100vh;'
   s += '}'

   s += '.grid {'
   s += '  display: grid;'
   s += '  grid-template-columns: repeat(3, 1fr);'
   s += '  grid-template-rows: auto auto auto;'
   s += '  gap: 16px;'
   s += '}'

   s += '.card {'
   s += '  background: linear-gradient(160deg, #1e2128 0%, #171a20 100%);'
   s += '  border: 1px solid rgba(255,255,255,0.06);'
   s += '  border-radius: 12px;'
   s += '  padding: 16px 18px;'
   s += '  box-shadow:'
   s += '    0 10px 20px rgba(0,0,0,0.45),'
   s += '    0 2px 4px rgba(0,0,0,0.35),'
   s += '    inset 0 1px 0 rgba(255,255,255,0.05);'
   s += '  transition: transform 220ms ease, box-shadow 220ms ease;'
   s += '}'
   s += '.card:hover {'
   s += '  transform: translateY(-3px);'
   s += '  box-shadow:'
   s += '    0 18px 32px rgba(0,0,0,0.55),'
   s += '    0 3px 6px rgba(0,0,0,0.40),'
   s += '    inset 0 1px 0 rgba(255,255,255,0.08);'
   s += '}'

   s += '.title {'
   s += '  font-size: 13px;'
   s += '  font-weight: 600;'
   s += '  letter-spacing: 0.6px;'
   s += '  text-transform: uppercase;'
   s += '  color: #8f97a6;'
   s += '  margin-bottom: 12px;'
   s += '}'

   /* ---- 3D bar chart: perspective applied to the canvas wrapper ---- */
   s += '.scene-3d {'
   s += '  perspective: 900px;'
   s += '  perspective-origin: 50% 40%;'
   s += '  height: 260px;'
   s += '}'
   s += '.bar3d {'
   s += '  transform: rotateX(12deg) rotateY(-14deg);'
   s += '  transform-style: preserve-3d;'
   s += '  filter: drop-shadow(-12px 14px 10px rgba(0,0,0,0.55));'
   s += '  height: 100%;'
   s += '}'

   /* ---- Donut with gradient stroke ---- */
   s += '.donut-wrap {'
   s += '  position: relative;'
   s += '  height: 260px;'
   s += '  display: flex;'
   s += '  align-items: center;'
   s += '  justify-content: center;'
   s += '}'
   s += '.donut-center {'
   s += '  position: absolute;'
   s += '  top: 50%; left: 50%;'
   s += '  transform: translate(-50%, -50%);'
   s += '  text-align: center;'
   s += '  pointer-events: none;'
   s += '}'
   s += '.donut-value {'
   s += '  font-size: 34px;'
   s += '  font-weight: 700;'
   s += '  color: #ffffff;'
   s += '  text-shadow: 0 0 14px rgba(93,173,226,0.65);'
   s += '}'
   s += '.donut-label {'
   s += '  font-size: 11px;'
   s += '  color: #8f97a6;'
   s += '  letter-spacing: 1px;'
   s += '  text-transform: uppercase;'
   s += '}'

   /* ---- Gauge: SVG with an animated progress arc ---- */
   s += '.gauge-wrap {'
   s += '  height: 260px;'
   s += '  display: flex;'
   s += '  align-items: center;'
   s += '  justify-content: center;'
   s += '}'
   s += '.gauge-track { stroke: rgba(255,255,255,0.08); }'
   s += '.gauge-fill {'
   s += '  stroke: url(#gaugeGrad);'
   s += '  stroke-linecap: round;'
   s += '  filter: drop-shadow(0 0 8px rgba(93,173,226,0.55));'
   s += '  stroke-dasharray: 314;'
   s += '  stroke-dashoffset: 314;'
   s += '  animation: fillGauge 1400ms cubic-bezier(0.22, 0.61, 0.36, 1) forwards;'
   s += '}'
   s += '@keyframes fillGauge {'
   s += '  to { stroke-dashoffset: 78; }'   /* 75% of 314 */
   s += '}'
   s += '.gauge-num {'
   s += '  font-size: 34px;'
   s += '  font-weight: 700;'
   s += '  fill: #ffffff;'
   s += '}'
   s += '.gauge-sub {'
   s += '  font-size: 11px;'
   s += '  fill: #8f97a6;'
   s += '  letter-spacing: 1px;'
   s += '}'

   /* ---- Line chart with glow ---- */
   s += '.scene-line {'
   s += '  height: 260px;'
   s += '  filter: drop-shadow(0 0 6px rgba(230,126,34,0.35));'
   s += '}'

   /* ---- Progress bars with CSS animation ---- */
   s += '.bars {'
   s += '  display: flex;'
   s += '  flex-direction: column;'
   s += '  gap: 14px;'
   s += '  padding-top: 8px;'
   s += '}'
   s += '.bar-item {'
   s += '  display: flex;'
   s += '  flex-direction: column;'
   s += '  gap: 6px;'
   s += '}'
   s += '.bar-head {'
   s += '  display: flex;'
   s += '  justify-content: space-between;'
   s += '  font-size: 12px;'
   s += '  color: #b6bcc8;'
   s += '}'
   s += '.bar-track {'
   s += '  height: 10px;'
   s += '  background: rgba(255,255,255,0.06);'
   s += '  border-radius: 6px;'
   s += '  overflow: hidden;'
   s += '  box-shadow: inset 0 1px 2px rgba(0,0,0,0.5);'
   s += '}'
   s += '.bar-fill {'
   s += '  height: 100%;'
   s += '  border-radius: 6px;'
   s += '  transform-origin: left center;'
   s += '  animation: grow 1200ms cubic-bezier(0.22, 0.61, 0.36, 1) forwards;'
   s += '}'
   s += '.bar-fill.b1 { width: 82%; background: linear-gradient(90deg, #5dade2, #3498db); }'
   s += '.bar-fill.b2 { width: 64%; background: linear-gradient(90deg, #f5b041, #e67e22); }'
   s += '.bar-fill.b3 { width: 91%; background: linear-gradient(90deg, #52be80, #27ae60); }'
   s += '.bar-fill.b4 { width: 47%; background: linear-gradient(90deg, #ec7063, #c0392b); }'
   s += '@keyframes grow { from { transform: scaleX(0); } to { transform: scaleX(1); } }'

   /* ---- KPI tiles ---- */
   s += '.kpi {'
   s += '  display: flex;'
   s += '  flex-direction: column;'
   s += '  gap: 6px;'
   s += '  padding: 22px 20px;'
   s += '}'
   s += '.kpi-num {'
   s += '  font-size: 40px;'
   s += '  font-weight: 700;'
   s += '  background: linear-gradient(120deg, #ffffff, #8f97a6);'
   s += '  -webkit-background-clip: text;'
   s += '  background-clip: text;'
   s += '  -webkit-text-fill-color: transparent;'
   s += '}'
   s += '.kpi-label {'
   s += '  font-size: 12px;'
   s += '  color: #8f97a6;'
   s += '  letter-spacing: 0.6px;'
   s += '  text-transform: uppercase;'
   s += '}'
   s += '.kpi-delta {'
   s += '  font-size: 12px;'
   s += '  font-weight: 600;'
   s += '}'
   s += '.kpi-delta.up { color: #52be80; }'
   s += '.kpi-delta.down { color: #ec7063; }'

   s += '</style></head><body>'

   s += '<div class="grid">'

   /* --------- Row 1 --------- */

   /* Card 1: 3D bar chart */
   s += '<div class="card">'
   s += '  <div class="title">Faturamento 3D</div>'
   s += '  <div class="scene-3d"><div class="bar3d"><canvas id="bar3d"></canvas></div></div>'
   s += '</div>'

   /* Card 2: donut */
   s += '<div class="card">'
   s += '  <div class="title">Share por região</div>'
   s += '  <div class="donut-wrap">'
   s += '    <canvas id="donut" width="220" height="220"></canvas>'
   s += '    <div class="donut-center">'
   s += '      <div class="donut-value">42%</div>'
   s += '      <div class="donut-label">Sudeste</div>'
   s += '    </div>'
   s += '  </div>'
   s += '</div>'

   /* Card 3: gauge */
   s += '<div class="card">'
   s += '  <div class="title">Meta do mês</div>'
   s += '  <div class="gauge-wrap">'
   s += '    <svg width="220" height="220" viewBox="0 0 220 220">'
   s += '      <defs>'
   s += '        <linearGradient id="gaugeGrad" x1="0%" y1="0%" x2="100%" y2="0%">'
   s += '          <stop offset="0%" stop-color="#5dade2"/>'
   s += '          <stop offset="100%" stop-color="#27ae60"/>'
   s += '        </linearGradient>'
   s += '      </defs>'
   s += '      <circle cx="110" cy="110" r="90" fill="none" stroke-width="16" class="gauge-track"/>'
   s += '      <circle cx="110" cy="110" r="90" fill="none" stroke-width="16" class="gauge-fill"'
   s += '              transform="rotate(-90 110 110)"/>'
   s += '      <text x="110" y="112" text-anchor="middle" class="gauge-num">75%</text>'
   s += '      <text x="110" y="140" text-anchor="middle" class="gauge-sub">R$ 187.500 / 250.000</text>'
   s += '    </svg>'
   s += '  </div>'
   s += '</div>'

   /* --------- Row 2 --------- */

   /* Card 4: line with glow (spans 2 cols) */
   s += '<div class="card" style="grid-column: span 2;">'
   s += '  <div class="title">Tendência 12 meses</div>'
   s += '  <div class="scene-line"><canvas id="lineGlow"></canvas></div>'
   s += '</div>'

   /* Card 5: CSS progress bars */
   s += '<div class="card">'
   s += '  <div class="title">Estoque por categoria</div>'
   s += '  <div class="bars">'
   s += '    <div class="bar-item">'
   s += '      <div class="bar-head"><span>Ferragens</span><span>82%</span></div>'
   s += '      <div class="bar-track"><div class="bar-fill b1"></div></div>'
   s += '    </div>'
   s += '    <div class="bar-item">'
   s += '      <div class="bar-head"><span>Ferramentas</span><span>64%</span></div>'
   s += '      <div class="bar-track"><div class="bar-fill b2"></div></div>'
   s += '    </div>'
   s += '    <div class="bar-item">'
   s += '      <div class="bar-head"><span>Elétrica</span><span>91%</span></div>'
   s += '      <div class="bar-track"><div class="bar-fill b3"></div></div>'
   s += '    </div>'
   s += '    <div class="bar-item">'
   s += '      <div class="bar-head"><span>Hidráulica</span><span>47%</span></div>'
   s += '      <div class="bar-track"><div class="bar-fill b4"></div></div>'
   s += '    </div>'
   s += '  </div>'
   s += '</div>'

   /* --------- Row 3: KPI tiles --------- */

   s += '<div class="card kpi">'
   s += '  <div class="kpi-num">R$ 1,24 M</div>'
   s += '  <div class="kpi-label">Faturamento do mês</div>'
   s += '  <div class="kpi-delta up">▲ 12,4% vs. mês anterior</div>'
   s += '</div>'

   s += '<div class="card kpi">'
   s += '  <div class="kpi-num">6.730</div>'
   s += '  <div class="kpi-label">SKUs ativos</div>'
   s += '  <div class="kpi-delta up">▲ 45 novos</div>'
   s += '</div>'

   s += '<div class="card kpi">'
   s += '  <div class="kpi-num">2,8%</div>'
   s += '  <div class="kpi-label">Taxa de devolução</div>'
   s += '  <div class="kpi-delta down">▼ 0,3 p.p.</div>'
   s += '</div>'

   s += '</div>'   /* .grid */

   /* --------- Chart.js wiring --------- */
   s += '<script>'

   s += 'Chart.defaults.color = "#b6bcc8";'
   s += 'Chart.defaults.font.family = "Noto Sans, sans-serif";'

   /* Bar 3D */
   s += 'new Chart(document.getElementById("bar3d"), {'
   s += '  type: "bar",'
   s += '  data: {'
   s += '    labels: ["Jan","Fev","Mar","Abr","Mai","Jun"],'
   s += '    datasets: [{'
   s += '      label: "2025",'
   s += '      data: [120,150,180,140,210,175],'
   s += '      backgroundColor: (ctx) => {'
   s += '        const g = ctx.chart.ctx.createLinearGradient(0,0,0,260);'
   s += '        g.addColorStop(0, "#5dade2");'
   s += '        g.addColorStop(1, "#1b4f72");'
   s += '        return g;'
   s += '      },'
   s += '      borderRadius: 6,'
   s += '      borderSkipped: false'
   s += '    }]'
   s += '  },'
   s += '  options: {'
   s += '    responsive: true, maintainAspectRatio: false,'
   s += '    plugins: { legend: { display: false } },'
   s += '    scales: {'
   s += '      x: { grid: { color: "rgba(255,255,255,0.04)" } },'
   s += '      y: { grid: { color: "rgba(255,255,255,0.06)" } }'
   s += '    }'
   s += '  }'
   s += '});'

   /* Donut with gradient */
   s += 'new Chart(document.getElementById("donut"), {'
   s += '  type: "doughnut",'
   s += '  data: {'
   s += '    labels: ["Sudeste","Sul","Nordeste","Centro-Oeste"],'
   s += '    datasets: [{'
   s += '      data: [42,27,18,13],'
   s += '      backgroundColor: ["#5dade2","#f5b041","#52be80","#af7ac5"],'
   s += '      borderColor: "#171a20",'
   s += '      borderWidth: 4,'
   s += '      hoverOffset: 8'
   s += '    }]'
   s += '  },'
   s += '  options: {'
   s += '    responsive: false,'
   s += '    cutout: "72%",'
   s += '    plugins: { legend: { display: false } }'
   s += '  }'
   s += '});'

   /* Line with glow */
   s += 'const lineGrad = document.getElementById("lineGlow").getContext("2d").createLinearGradient(0,0,0,260);'
   s += 'lineGrad.addColorStop(0, "rgba(230,126,34,0.55)");'
   s += 'lineGrad.addColorStop(1, "rgba(230,126,34,0.02)");'

   s += 'new Chart(document.getElementById("lineGlow"), {'
   s += '  type: "line",'
   s += '  data: {'
   s += '    labels: ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"],'
   s += '    datasets: [{'
   s += '      data: [120,150,180,140,210,175,190,230,220,245,260,240],'
   s += '      borderColor: "#e67e22",'
   s += '      borderWidth: 3,'
   s += '      tension: 0.35,'
   s += '      fill: true,'
   s += '      backgroundColor: lineGrad,'
   s += '      pointBackgroundColor: "#e67e22",'
   s += '      pointRadius: 3,'
   s += '      pointHoverRadius: 6'
   s += '    }]'
   s += '  },'
   s += '  options: {'
   s += '    responsive: true, maintainAspectRatio: false,'
   s += '    plugins: { legend: { display: false } },'
   s += '    scales: {'
   s += '      x: { grid: { color: "rgba(255,255,255,0.04)" } },'
   s += '      y: { grid: { color: "rgba(255,255,255,0.06)" } }'
   s += '    }'
   s += '  }'
   s += '});'

   s += '</script></body></html>'

   RETURN s
