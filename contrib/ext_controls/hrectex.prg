/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level class HRect (Panel)
 *
 * Copyright 2004 Ricardo de Moura Marques <ricardo.m.marques@caixa.gov.br>
*/

#include "hwgui.ch"
#include "hbclass.ch"
#include "common.ch"

#DEFINE TRANSPARENT 1

//Contribution   Luis Fernando Basso

CLASS HContainerEx INHERIT HControl, HScrollArea

   CLASS VAR winclass   INIT "STATIC"
   DATA oPen
   DATA ncStyle   INIT 3
   DATA nBorder
   DATA lnoBorder INIT .T.
   DATA bLoad
   DATA bClick, bDblClick
   DATA lCreate   INIT .F.
   DATA BackStyle       INIT OPAQUE
   DATA bRefresh
   DATA xVisible  INIT .T. HIDDEN
   DATA lTABSTOP INIT .F. HIDDEN

   METHOD New( oWndParent, nId, nstyle, nLeft, nTop, nWidth, nHeight, ncStyle, bSize,;
         lnoBorder, bInit, nBackStyle, tcolor, bcolor, bLoad, bRefresh, bOther)  //, bClick, bDblClick)
   METHOD Activate()
   METHOD Init()
   METHOD Create( ) INLINE ::lCreate := .T.
   METHOD onEvent( msg, wParam, lParam )
   METHOD Paint( lpDis )
   METHOD Visible( lVisibled ) SETGET
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ncStyle, bSize,;
      lnoBorder, bInit, nBackStyle, tcolor, bcolor, bLoad, bRefresh, bOther) CLASS HContainerEx

   ::lTABSTOP :=  nStyle = WS_TABSTOP
   ::bPaint   := { | o, p | o:paint( p ) }
   nStyle := SS_OWNERDRAW + IIF( nStyle = WS_TABSTOP, WS_TABSTOP , 0 ) + Hwg_Bitand( nStyle, SS_NOTIFY )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, , ;
         bInit, bSize, ::bPaint,, tcolor, bColor )

   //::title := ""
   ::ncStyle := IIF( ncStyle = NIL .AND. nStyle < WS_TABSTOP, 3, ncStyle )
   ::lnoBorder := IIF( lnoBorder = NIL, .F., lnoBorder )
   ::backStyle := IIF( nbackStyle = NIL, OPAQUE, nbackStyle ) // OPAQUE DEFAULT
   ::bLoad := bLoad
   ::bRefresh := bRefresh
   ::bOther := bOther
   ::SetColor( ::tColor, ::bColor )
   ::Activate()
   IF ::bLoad != NIL
      // SET ENVIRONMENT
      Eval( ::bLoad,Self )
   ENDIF
   ::oPen := HPen():Add( PS_SOLID, 1, hwg_Getsyscolor( COLOR_3DHILIGHT ) )

  RETURN Self

//---------------------------------------------------------------------------
METHOD Activate() CLASS HContainerEx
   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ::style, ;
            ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   IF ! ::lCreate
      ::Create()
      ::lCreate := .T.
   ENDIF
RETURN NIL

METHOD Init() CLASS HContainerEx

   IF ! ::lInit
      ::Super:init()
      hwg_Addtooltip( ::handle, ::handle, "" )
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitStaticProc( ::handle )
      //hwg_Setwindowpos( ::Handle, HWND_BOTTOM, 0, 0, 0, 0 , SWP_NOSIZE + SWP_NOMOVE + SWP_NOZORDER)
   ENDIF

   RETURN  NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HContainerEx
   LOCAL nEval

   IF ::bOther != NIL
      IF ( nEval := Eval( ::bOther,Self,msg,wParam,lParam ) ) != NIL .AND. nEval != -1
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_PAINT
      RETURN - 1
   ELSEIF msg == WM_ERASEBKGND
      RETURN 0
   ENDIF
   IF ::lTABSTOP
      IF msg == WM_SETFOCUS
         hwg_GetSkip( ::oparent, ::handle, ::nGetSkip )
      ELSEIF msg == WM_KEYUP
         IF wParam = VK_DOWN
            hwg_GetSkip( ::oparent, ::handle, 1 )
         ELSEIF  wParam = VK_UP
            hwg_GetSkip( ::oparent, ::handle, -1 )
         ELSEIF wParam = VK_TAB
            hwg_GetSkip( ::oParent, ::handle, iif( hwg_IsCtrlShift(.f., .t.), -1, 1) )
         ENDIF
         RETURN 0
      ELSEIF msg = WM_SYSKEYUP
      ENDIF
   ENDIF

   RETURN ::Super:onEvent( msg, wParam, lParam )

METHOD Visible( lVisibled ) CLASS HContainerEx

   IF lVisibled != NIL
      IF lVisibled
         ::Show()
      ELSE
         ::Hide()
      ENDIF
      ::xVisible := lVisibled
   ENDIF

   RETURN ::xVisible

//---------------------------------------------------------------------------
METHOD Paint( lpdis ) CLASS HContainerEx
   LOCAL drawInfo, hDC
   LOCAL x1, y1, x2, y2

   drawInfo := hwg_Getdrawiteminfo( lpdis )
   hDC := drawInfo[ 3 ]
   x1  := drawInfo[ 4 ]
   y1  := drawInfo[ 5 ]
   x2  := drawInfo[ 6 ]
   y2  := drawInfo[ 7 ]

   hwg_Selectobject( hDC, ::oPen:handle )

   IF ::ncStyle != NIL
      hwg_Setbkmode( hDC, ::backStyle )
      IF ! ::lnoBorder
         IF ::ncStyle == 0      // RAISED
            hwg_Drawedge( hDC, x1, y1, x2, y2,BDR_RAISED,BF_LEFT+BF_TOP+BF_RIGHT+BF_BOTTOM)  // raised  forte      8
         ELSEIF ::ncStyle == 1  // sunken
            hwg_Drawedge( hDC, x1, y1, x2, y2,BDR_SUNKEN,BF_LEFT+BF_TOP+BF_RIGHT+BF_BOTTOM ) // sunken mais forte
         ELSEIF ::ncStyle == 2  // FRAME
            hwg_Drawedge( hDC, x1, y1, x2, y2,BDR_RAISED+BDR_RAISEDOUTER,BF_LEFT+BF_TOP+BF_RIGHT+BF_BOTTOM) // FRAME
         ELSE                   // FLAT
            hwg_Drawedge( hDC, x1, y1, x2, y2,BDR_SUNKENINNER,BF_TOP)
            hwg_Drawedge( hDC, x1, y1, x2, y2,BDR_RAISEDOUTER,BF_BOTTOM)
            hwg_Drawedge( hDC, x1, y2, x2, y1,BDR_SUNKENINNER,BF_LEFT)
            hwg_Drawedge( hDC, x1, y2, x2, y1,BDR_RAISEDOUTER,BF_RIGHT)
         ENDIF
      ELSE
         hwg_Drawedge( hDC, x1, y1, x2, y2,0,0)
      ENDIF
      IF ::backStyle != TRANSPARENT
         IF ::Brush != NIL
            hwg_Fillrect( hDC, x1 + 2, y1 + 2, x2 - 2, y2 - 2 , ::brush:handle )
         ENDIF
      ELSE
         hwg_Fillrect( hDC, x1 + 2, y1 + 2, x2 - 2, y2 - 2 , hwg_Getstockobject( 5 ) )
      ENDIF
      //hwg_Setbkmode( hDC, 0 )
   ENDIF

   RETURN 1

   METHOD END() CLASS HContainerEx
   IF ::oPen != NIL
      ::oPen:Release()
      ::oPen := NIL
   ENDIF
   RETURN ::Super:END()

