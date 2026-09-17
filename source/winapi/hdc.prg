/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPAINTDC and HDC Classes
 *
 * Copyright 2005 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
*/

#include "hbclass.ch"
#include "hwgui.ch"

CLASS HPAINTDC FROM HDC

   DATA m_ps

   METHOD NEW( nWnd )
   METHOD END ()

   HIDDEN:
   DATA m_hWnd

ENDCLASS

METHOD NEW( nWnd ) CLASS HPAINTDC

   ::Super:new()
   ::m_ps   := hwg_Definepaintstru()
   ::m_hWnd := nWnd
   ::Attach( hwg_Beginpaint( ::m_hWnd, ::m_ps ) )

   RETURN Self

METHOD END () CLASS HPAINTDC

   hwg_Endpaint( ::m_hWnd, ::m_ps )
   ::m_hDC       := NIL
   ::m_hAttribDC := NIL

   RETURN NIL

CLASS HDC

   DATA m_hDC
   DATA m_hAttribDC

   METHOD NEW( )
   METHOD SetAttribDC( hDC )
   METHOD ATTACH( hDc )
   METHOD Moveto( x1, y1 )
   METHOD Lineto( x1, y1 )
   METHOD fillsolidrect( lpRect, clr )
   METHOD Fillrect( lpRect, clr )
   METHOD Selectcliprgn( pRgn )
   METHOD Settextcolor( xColor )
   METHOD Setbkmode( xMode )
   METHOD Setbkcolor(  clr ) INLINE    hwg_Setbkcolor( ::m_hDC, clr )
   METHOD Selectobject( xMode )  && xObject
   METHOD Drawtext( strText, Rect, dwFlags )
   METHOD Createcompatibledc( x )
   METHOD Patblt( a, s, d, f, g ) INLINE hwg_Patblt( ::m_hDc, a, s, d, f, g )
   METHOD Savedc()
   METHOD Restoredc( nSavedDC )
   METHOD Setmapmode( nMapMode )
   METHOD SetWindowOrg( x, y )
   METHOD SetWindowExt( x, y )
   METHOD SetViewportOrg( x, y )
   METHOD SetViewportExt( x, y )
   METHOD Setarcdirection( nArcDirection )
   METHOD Gettextmetric() INLINE hwg_Gettextmetric( ::m_hDC )
   METHOD Setrop2( nDrawMode )
   METHOD Bitblt( x,  y,  nWidth,  nHeight,  pSrcDC,  xSrc, ySrc,  dwRop ) INLINE    hwg_Bitblt( ::m_hDc, x, y, nWidth, nHeight,  pSrcDC,       xSrc,  ySrc,  dwRop )

   METHOD Pie( arect, apt1, apt2 )
   METHOD Deletedc()

ENDCLASS

METHOD NEW( ) CLASS HDC

   ::m_hDC       := NIL
   ::m_hAttribDC := NIL

   RETURN Self

METHOD Moveto( x1, y1 ) CLASS HDC

   hwg_Moveto( ::m_hDC, x1, y1 )

   RETURN Self

METHOD Lineto( x1, y1 ) CLASS HDC

   hwg_Lineto( ::m_hDC, x1, y1 )

   RETURN Self

METHOD Attach( hDC ) CLASS HDC

   IF Empty( hDC )
      RETURN .F.
   ENDIF

   ::m_hDC := hDC

   ::SetAttribDC( ::m_hDC )

   RETURN .T.

METHOD Deletedc(  ) CLASS HDC

   hwg_Deletedc( ::m_hDC )
   ::m_hDC := nil
   ::m_hAttribDC := nil

   RETURN nil

METHOD SetAttribDC( hDC ) CLASS HDC

   ::m_hAttribDC := hDC

   RETURN NIL

METHOD Selectcliprgn( pRgn ) CLASS HDC

   LOCAL nRetVal := - 1

   IF ( ::m_hDC != ::m_hAttribDC )
      nRetVal := hwg_Selectcliprgn( ::m_hDC, pRgn )
   ENDIF

   IF ! Empty( ::m_hAttribDC  )
      nRetVal := hwg_Selectcliprgn( ::m_hAttribDC, pRgn )
   ENDIF

   RETURN nRetVal

METHOD fillsolidrect( lpRect, clr ) CLASS HDC

   hwg_Setbkcolor( ::m_hDC, clr )
   hwg_Exttextout( ::m_hDC, 0, 0, lpRect[ 1 ], lpRect[ 2 ], lpRect[ 3 ], lpRect[ 4 ], NIL )

   RETURN NIL

METHOD Settextcolor( xColor ) CLASS HDC

   RETURN hwg_Settextcolor( ::m_hDc, xColor )

METHOD Setbkmode( xMode ) CLASS HDC

   RETURN hwg_Setbkmode( ::m_hDc, xMode )

METHOD Selectobject( xMode ) CLASS HDC

   RETURN hwg_Selectobject( ::m_hDc, xMode )

METHOD Drawtext( strText, Rect, dwFlags ) CLASS HDC

   hwg_Drawtext( ::m_hDC, strText, Rect[ 1 ], Rect[ 2 ], Rect[ 3 ], Rect[ 4 ], dwFlags )

   RETURN NIL

METHOD Fillrect( lpRect, clr ) CLASS HDC

   hwg_Fillrect( ::m_hDC, lpRect[ 1 ], lpRect[ 2 ], lpRect[ 3 ], lpRect[ 4 ], clr )

   RETURN NIL

METHOD Createcompatibledc( x ) CLASS HDC

   RETURN ::Attach( hwg_Createcompatibledc( x ) )

METHOD Savedc() CLASS HDC

   LOCAL nRetVal := 0

   IF ( ! Empty( ::m_hAttribDC ) )
      nRetVal := hwg_Savedc( ::m_hAttribDC )
   ENDIF
   IF ( ::m_hDC != ::m_hAttribDC .and. hwg_Savedc( ::m_hDC ) != 0 )
      nRetVal := - 1   // -1 is the only valid restore value for complex DCs
   ENDIF

   RETURN nRetVal

METHOD Restoredc( nSavedDC ) CLASS HDC

   // if two distinct DCs, nSavedDC can only be -1

   LOCAL bRetVal := .T.

   IF ( ::m_hDC != ::m_hAttribDC )
      bRetVal := hwg_Restoredc( ::m_hDC, nSavedDC )
   ENDIF
   IF ( ! Empty( ::m_hAttribDC ) )
      bRetVal := ( bRetVal .and. hwg_Restoredc( ::m_hAttribDC, nSavedDC ) )
   ENDIF

   RETURN bRetVal

METHOD Setmapmode( nMapMode ) CLASS HDC

   LOCAL nRetVal := 0

   // FIXED: era ::Setmapmode( ::m_hDC, nMapMode ) - chamava o proprio
   // metodo (recursao infinita / stack overflow). Deve chamar a funcao
   // de nivel C, como os metodos irmaos (Setrop2, Setarcdirection, etc).
   IF ( ::m_hDC != ::m_hAttribDC )
      nRetVal := hwg_Setmapmode( ::m_hDC, nMapMode )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      nRetVal := hwg_Setmapmode( ::m_hAttribDC, nMapMode )
   ENDIF

   RETURN nRetVal

METHOD SetWindowOrg( x, y ) CLASS HDC

   LOCAL point

   IF ( ::m_hDC != ::m_hAttribDC )
      hwg_Setwindoworgex( ::m_hDC, x, y, @point )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      hwg_Setwindoworgex( ::m_hAttribDC, x, y, @point )
   ENDIF

   RETURN point

METHOD SetWindowExt( x, y ) CLASS HDC

   LOCAL point

   IF ( ::m_hDC != ::m_hAttribDC )
      hwg_Setwindowextex( ::m_hDC, x, y, @point )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      hwg_Setwindowextex( ::m_hAttribDC, x, y, @point )
   ENDIF

   RETURN point

METHOD SetViewportOrg( x, y ) CLASS HDC

   LOCAL point

   IF ( ::m_hDC != ::m_hAttribDC )
      hwg_Setviewportorgex( ::m_hDC, x, y, @point )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      hwg_Setviewportorgex( ::m_hAttribDC, x, y, @point )
   ENDIF

   RETURN point

METHOD SetViewportExt( x, y ) CLASS HDC

   LOCAL point

   IF ( ::m_hDC != ::m_hAttribDC )
      hwg_Setviewportextex( ::m_hDC, x, y, @point )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      hwg_Setviewportextex( ::m_hAttribDC, x, y, @point )
   ENDIF

   RETURN point

METHOD Setarcdirection( nArcDirection )

   LOCAL nResult := 0

   IF ( ::m_hDC != ::m_hAttribDC )
      nResult = hwg_Setarcdirection( ::m_hDC, nArcDirection )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      nResult = hwg_Setarcdirection( ::m_hAttribDC, nArcDirection )
   ENDIF

   RETURN nResult

METHOD Pie( arect, apt1, apt2 )

   RETURN hwg_Pie( ::m_hdc, arect[ 1 ], arect[ 2 ], arect[ 3 ], arect[ 4 ], apt1[ 1 ], apt1[ 2 ], apt2[ 1 ], apt2[ 2 ] )

METHOD Setrop2( nDrawMode )

   LOCAL nRetVal := 0

   IF ( ::m_hDC != ::m_hAttribDC )
      nRetVal := hwg_Setrop2( ::m_hDC, nDrawMode )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      nRetVal := hwg_Setrop2( ::m_hAttribDC, nDrawMode )
   ENDIF

   RETURN nRetVal

CLASS HCLIENTDC FROM HDC

   METHOD NEW( nWnd )
   METHOD END ()

   HIDDEN:
   DATA m_hWnd

ENDCLASS

METHOD NEW( nWnd ) CLASS HCLIENTDC

   ::Super:new()
   ::m_hWnd := nWnd
   ::Attach( hwg_Getdc( ::m_hWnd ) )

   RETURN Self

METHOD END () CLASS HCLIENTDC

   hwg_Releasedc( ::m_hWnd, ::m_hDC )
   ::m_hDC       := NIL
   ::m_hAttribDC := NIL

   RETURN NIL
