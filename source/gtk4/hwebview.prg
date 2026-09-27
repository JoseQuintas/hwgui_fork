/*
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HWebView class
 *
 * GTK4 port — target: GTK 4.24+
 *
 * NOTES
 * -----
 *  Thin wrapper around WebKitGTK 6.0's WebKitWebView.  The widget is
 *  a full browser engine, so anything HTML5/CSS3/JavaScript can do
 *  is available: Chart.js, D3, Plotly, ECharts, plain HTML reports.
 *
 *  Requires libwebkitgtk-6.0-dev at build time; the HWGUI library
 *  must be linked against it (see hwguiGTK4.hbp).
 */

#include "hbclass.ch"
#include "hwgui.ch"

CLASS HWebView INHERIT HControl

   CLASS VAR winclass  INIT "WEBVIEW"

   DATA   cHTML      INIT ""
   DATA   lLoaded    INIT .F.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cHTML, bInit, bSize )
   METHOD Activate()
   METHOD Init()
   METHOD LoadHTML( cHTML )
   METHOD RunJS( cJS )
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cHTML, bInit, bSize ) CLASS HWebView

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      Nil, bInit, bSize )

   ::cHTML := iif( cHTML == Nil, "", cHTML )

   ::Activate()

   IF !Empty( ::cHTML )
      ::LoadHTML( ::cHTML )
   ENDIF

   RETURN Self

METHOD Activate() CLASS HWebView

   IF !Empty( ::oParent:handle )
      ::handle := hwg_CreateWebView( ::oParent:handle, ::id, ::style, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD Init() CLASS HWebView

   IF !::lInit
      ::Super:Init()
   ENDIF

   RETURN Nil

METHOD LoadHTML( cHTML ) CLASS HWebView

   IF cHTML == Nil
      RETURN Nil
   ENDIF

   ::cHTML   := cHTML
   ::lLoaded := .T.

   hwg_WebViewLoadHTML( ::handle, cHTML )

   RETURN Nil

METHOD RunJS( cJS ) CLASS HWebView

   IF cJS != Nil
      hwg_WebViewRunJS( ::handle, cJS )
   ENDIF

   RETURN Nil

METHOD End() CLASS HWebView

   hwg_ReleaseObject( ::handle )
   ::Super:End()

   RETURN Nil
