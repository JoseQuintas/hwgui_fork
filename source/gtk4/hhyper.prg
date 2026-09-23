/*
 * $Id: hhyper.prg 3339 2023-09-28 08:36:01Z alkresin $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HStaticLink class
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It relies exclusively on the
 * hwg_* abstraction layer:
 *
 *   - hwg_Createownbtn()          → GtkDrawingArea with draw_func (control.c)
 *   - hwg_Loadcursor(GDK_HAND2)   → translated to CSS "pointer" by
 *                                    HWG_LOADCURSOR in control.c
 *   - hwg_Beginpaint/Endpaint     → bridge to the live cairo_t (draw.c)
 *   - hwg_Drawtext/Settextcolor   → Pango/Cairo (drawtext.c)
 *
 * The WM_ERASEBKGND branch is dead code — the GDK expose event never
 * mapped to it, in GTK2 as in GTK4.  It is kept for source-compatibility.
 *
 * hwg_Shellexecute is implemented in the C side and is unchanged by the
 * GTK version (it uses system()/g_spawn_* rather than GTK APIs).
*/

#include "hbclass.ch"
#include "common.ch"
#include "hwgui.ch"

#define LBL_INIT           0
#define LBL_NORMAL         1
#define LBL_VISITED        2
#define LBL_MOUSEOVER      3

CLASS HStaticLink FROM HSTATIC

   DATA state
   DATA m_bFireChild INIT .F.

   DATA m_hHyperCursor

   DATA m_bMouseOver INIT .F.
   DATA m_bVisited   INIT .F.

   DATA m_oTextFont
   DATA m_csUrl
   DATA dc
   DATA dwFlags      INIT 0

   DATA m_sHoverColor
   DATA m_sLinkColor
   DATA m_sVisitedColor

   CLASS VAR winclass INIT "STATIC"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, cLink, vColor, lColor, hColor )
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD GoToLinkUrl( csLink )
   METHOD SetLinkUrl( csUrl )
   METHOD GetLinkUrl()
   METHOD SetVisitedColor( sVisitedColor )
   METHOD SetHoverColor( cHoverColor )
   METHOD SetFireChild( lFlag )  INLINE ::m_bFireChild := lFlag
   METHOD OnClicked()
   METHOD SetLinkColor( sLinkColor )
   METHOD Paint()
   METHOD OnMouseMove( wParam )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, cLink, vColor, lColor, hColor ) CLASS HStaticLink

   LOCAL oPrevFont, n

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp )

   DEFAULT vColor TO hwg_ColorRgb2N( 5, 34, 143 )
   DEFAULT lColor TO hwg_ColorRgb2N( 0, 0, 255 )
   DEFAULT hColor TO hwg_ColorRgb2N( 255, 0, 0 )
   ::m_csUrl := cLink
   ::m_sHoverColor   := hColor
   ::m_sLinkColor    := lColor
   ::m_sVisitedColor := vColor
   ::m_hHyperCursor  := hwg_Loadcursor( GDK_HAND2 )

   ::state := LBL_INIT
   ::title := iif( cCaption == Nil, "", cCaption )

   IF ::oFont == NIL
      IF ::oParent:oFont != NIL
         ::oFont := HFont():Add( ::oParent:oFont:name, ::oParent:oFont:width, ::oParent:oFont:height, ;
            ::oParent:oFont:weight, ::oParent:oFont:charset, ::oParent:oFont:italic, 1, ::oParent:oFont:StrikeOut,,.T. )
      ELSE
         ::oFont := HFont():Add( "Serif", 0, 12,,,,,,,.T. )
      ENDIF
   ELSE
      IF ::oFont:Underline  == 0
         oPrevFont := ::oFont
         ::oFont:Release()
         ::oFont := HFont():Add( oPrevFont:name, oPrevFont:width, oPrevFont:height, ;
            oPrevFont:weight, oPrevFont:charset, oPrevFont:italic, 1, oPrevFont:StrikeOut,,.T. )
      ENDIF
   ENDIF

   IF ( n := hwg_bitAnd( ::style, SS_TYPEMASK ) ) == SS_RIGHT
      ::dwFlags := hwg_bitOr( DT_RIGHT, DT_WORDBREAK )
   ELSEIF n == SS_CENTER
      ::dwFlags := hwg_bitOr( SS_CENTER, DT_WORDBREAK )
   ELSEIF n == SS_LEFTNOWORDWRAP
      ::dwFlags := DT_LEFT
   ELSE
      ::dwFlags := hwg_bitOr( DT_LEFT, DT_WORDBREAK )
   ENDIF

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HStaticLink

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createownbtn( ::oParent:handle, ::id, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Init() CLASS HStaticLink

   IF ! ::lInit
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HStaticLink

   * Parameters not used
   HB_SYMBOL_UNUSED(lParam)

   IF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_ERASEBKGND
      RETURN 1
   ELSEIF msg == WM_MOUSEMOVE
      hwg_SetCursor( ::m_hHyperCursor, ::handle )
      ::OnMouseMove( wParam )
   ELSEIF msg == WM_LBUTTONDOWN
      hwg_SetCursor( ::m_hHyperCursor, ::handle )
      ::OnClicked()
   ENDIF

   RETURN -1

METHOD GoToLinkUrl( csLink ) CLASS HStaticLink

   RETURN hwg_Shellexecute( csLink )

METHOD SetLinkUrl( csUrl ) CLASS HStaticLink

   ::m_csUrl := csUrl

   RETURN NIL

METHOD GetLinkUrl() CLASS HStaticLink

   RETURN ::m_csUrl

METHOD SetVisitedColor( sVisitedColor ) CLASS HStaticLink

   ::m_sVisitedColor := sVisitedColor

   RETURN NIL

METHOD SetHoverColor( cHoverColor ) CLASS HStaticLink

   ::m_sHoverColor := cHoverColor

   RETURN NIL

METHOD OnClicked() CLASS HStaticLink

   ::GoToLinkUrl( ::m_csUrl )

   ::m_bVisited := .T.

   ::state := LBL_NORMAL
   hwg_Invalidaterect( ::handle, 0 )
   hwg_Setfocus( ::handle )

   RETURN NIL

METHOD SetLinkColor( sLinkColor ) CLASS HStaticLink

   ::m_sLinkColor := sLinkColor

   RETURN NIL

METHOD OnMouseMove( wParam ) CLASS HStaticLink

   LOCAL lEnter := ( hwg_BitAnd( wParam,16 ) > 0 )

   IF ::state != LBL_INIT

      IF !lEnter

         ::state := LBL_NORMAL
         hwg_Invalidaterect( ::handle, 0 )
      ELSEIF ::state == LBL_NORMAL

         ::state := LBL_MOUSEOVER
         hwg_Invalidaterect( ::handle, 0 )
      ENDIF

   ENDIF

   RETURN 0

METHOD Paint() CLASS HStaticLink

   LOCAL pps, hDC, aCoors

   IF ::state == LBL_INIT
      ::State := LBL_NORMAL
   ENDIF

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( ::handle, pps )
   aCoors := hwg_Getclientrect( ::handle )

   hwg_Selectobject( hDC, ::oFont:handle )
   hwg_Settextcolor( hDC, Iif( ::state == LBL_NORMAL, ;
         Iif( ::m_bVisited, ::m_sVisitedColor, ::m_sLinkColor ), ::m_sHoverColor ) )

   hwg_Drawtext( hDC, ::Title, aCoors[1], aCoors[2], aCoors[3], aCoors[4], ::dwFlags )

   hwg_Endpaint( ::handle, pps )

   RETURN 0
