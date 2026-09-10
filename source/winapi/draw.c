/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level painting functions
 * Raw bitmap support
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

/*
~~~~~~~~~ Attention ~~~~~~~~~~
PNG support prepared for further Windows releases:
The recent Windows release do not support PNG images.

For further releases the following functions and methods
are inserted for test purposes, if the
WinAPI function LoadImage() will support PNGs:

METHOD AddPngString( name, cVal ) CLASS HIcon            of drawwidg.prg
METHOD AddPngFile( name , nWidth, nHeight) CLASS HIcon   of drawwidg.prg

HWG_LOADPNG()                                            of draw.c

DF7BE, September 2022
*/

#define OEMRESOURCE

/* REMOVED: Obsolete compiler support
 * #ifdef __DMC__
 * #define __DRAW_C__
 * #endif
 */

#include "hwingui.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"

/* REMOVED: Obsolete header
 * #include "missing.h"
 */

#include "math.h"

#include "incomp_pointer.h"

/* Includes for raw bitmap support */
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <malloc.h>

/* REMOVED: Borland C++ 5.5 obsolete support
 * #if defined( __BORLANDC__ ) && __BORLANDC__ == 0x0550
 * #ifdef __cplusplus
 * extern "C"
 * {
 *    STDAPI OleLoadPicture( LPSTREAM, LONG, BOOL, REFIID, PVOID * );
 * }
 * #else
 * #endif
 * #endif
 */

#ifdef __cplusplus
#ifdef CINTERFACE
#undef CINTERFACE
#endif
#endif

typedef int ( _stdcall * TRANSPARENTBLT ) ( HDC, int, int, int, int, HDC, int,
      int, int, int, int );

static TRANSPARENTBLT s_pTransparentBlt = NULL;

static void * bmp_fileimg ; /* Pointer to file image of a bitmap */

#define GRADIENT_MAX_COLORS 16

#ifndef GRADIENT_FILL_RECT_H

#define GRADIENT_FILL_RECT_H 0
#define GRADIENT_FILL_RECT_V 1

#if !defined(__WATCOMC__) && !defined(__MINGW32__) && !defined(__MINGW64__)
typedef struct _GRADIENT_RECT
{
   ULONG UpperLeft;
   ULONG LowerRight;
} GRADIENT_RECT;
#endif

#if defined(__DMC__)
typedef struct _TRIVERTEX
{
   LONG x;
   LONG y;
   USHORT Red;
   USHORT Green;
   USHORT Blue;
   USHORT Alpha;
} TRIVERTEX, *PTRIVERTEX;
#endif

#endif
#ifndef M_PI
#define M_PI             3.14159265358979323846
#endif
#ifndef M_TWOPI
#define M_TWOPI         (M_PI * 2.0)
#endif
#ifndef M_PI_2
#define M_PI_2           1.57079632679489661923
#endif
#ifndef M_PI_4
#define M_PI_4           0.78539816339744830962
#endif

/* Define fixed parameters for bitmap */

#ifdef __WATCOMC__
#define BMPFILEIMG_MAXSZ 65536
#else
#define BMPFILEIMG_MAXSZ 131072 /* Max file size of a bitmap (128 K) */
#endif

#define  _planes      1         /* Forever 1 */
#define  _compression 0         /* No compression */

#define HI_NIBBLE    0
#define LO_NIBBLE    1
#define MINIMUM(a, b) ((a) < (b) ? (a) : (b))

#if defined( __USE_GDIPLUS )

#include <gdiplus.h>
static GdiplusStartupInput gdiplusStartupInput;
static ULONG_PTR gdiplusToken = 0;
#endif

typedef int ( _stdcall * GRADIENTFILL ) ( HDC, PTRIVERTEX, int, PVOID, int, int );

static GRADIENTFILL FuncGradientFill = NULL;

/*=============================================================================
 * TransparentBmp()
 * Draws a transparent bitmap using TransparentBlt API
 *===========================================================================*/
void TransparentBmp( HDC hDC, int x, int y, int nWidthDest, int nHeightDest,
                     HDC dcImage, int bmWidth, int bmHeight, int trColor )
{
      // Safe initialization: load the library and function address only ONCE
      if( s_pTransparentBlt == NULL )
      {
            HMODULE hMsImg = GetModuleHandle( TEXT( "MSIMG32.DLL" ) );
            if( hMsImg == NULL )
            {
                  hMsImg = LoadLibrary( TEXT( "MSIMG32.DLL" ) );
            }

            if( hMsImg != NULL )
            {
                  s_pTransparentBlt = ( TRANSPARENTBLT ) GetProcAddress( hMsImg, "TransparentBlt" );
            }
      }

      // Strict safety check before calling the 64-bit function pointer
      if( s_pTransparentBlt != NULL )
      {
            s_pTransparentBlt( hDC, x, y, nWidthDest, nHeightDest, dcImage, 0, 0,
                               bmWidth, bmHeight, trColor );
      }
}

/*=============================================================================
 * Array2Rect()
 * Converts a Harbour array to a RECT structure
 *===========================================================================*/
BOOL Array2Rect( PHB_ITEM aRect, RECT * rc )
{
      if( HB_IS_ARRAY( aRect ) && hb_arrayLen( aRect ) == 4 )
      {
            rc->left = hb_arrayGetNL( aRect, 1 );
            rc->top = hb_arrayGetNL( aRect, 2 );
            rc->right = hb_arrayGetNL( aRect, 3 );
            rc->bottom = hb_arrayGetNL( aRect, 4 );
            return TRUE;
      }
      else
      {
            rc->left = rc->top = rc->right = rc->bottom = 0;
      }
      return FALSE;
}

/*=============================================================================
 * Rect2Array()
 * Converts a RECT structure to a Harbour array
 *===========================================================================*/
PHB_ITEM Rect2Array( RECT * rc )
{
      PHB_ITEM aRect = hb_itemArrayNew( 4 );
      PHB_ITEM element = hb_itemNew( NULL );

      // Safely assign coordinates by creating proper value instances
      hb_arraySet( aRect, 1, hb_itemPutNL( element, rc->left ) );
      hb_itemRelease( element );

      element = hb_itemNew( NULL );
      hb_arraySet( aRect, 2, hb_itemPutNL( element, rc->top ) );
      hb_itemRelease( element );

      element = hb_itemNew( NULL );
      hb_arraySet( aRect, 3, hb_itemPutNL( element, rc->right ) );
      hb_itemRelease( element );

      element = hb_itemNew( NULL );
      hb_arraySet( aRect, 4, hb_itemPutNL( element, rc->bottom ) );
      hb_itemRelease( element );

      return aRect;
}

/*=============================================================================
 * HWG_GETPPSRECT()
 * Gets paint structure rectangle
 *===========================================================================*/
HB_FUNC( HWG_GETPPSRECT )
{
      PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 1 );

      if( pps )
      {
            PHB_ITEM aMetr = Rect2Array( &pps->rcPaint );
            hb_itemReturn( aMetr );
            hb_itemRelease( aMetr );
      }
      else
      {
            hb_ret();
      }
}

/*=============================================================================
 * HWG_GETPPSERASE()
 * Gets paint structure erase flag
 *===========================================================================*/
HB_FUNC( HWG_GETPPSERASE )
{
      PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 1 );
      BOOL fErase = ( pps ) ? ( BOOL ) ( pps->fErase ) : FALSE;
      hb_retl( fErase );
}

/*=============================================================================
 * HWG_GETUPDATERECT()
 * Gets update rectangle
 *===========================================================================*/
HB_FUNC( HWG_GETUPDATERECT )
{
      HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
      BOOL fErase = GetUpdateRect( hWnd, NULL, 0 );
      hb_retl( fErase );
}

/*=============================================================================
 * HWG_INVALIDATERECT()
 * Invalidates a rectangle
 *===========================================================================*/
HB_FUNC( HWG_INVALIDATERECT )
{
      RECT rc;
      HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );

      BOOL bErase = HB_ISLOG( 2 ) ? ( BOOL ) hb_parl( 2 ) : ( BOOL ) hb_parni( 2 );

      if( hb_pcount(  ) > 2 )
      {
            rc.left   = hb_parni( 3 );
            rc.top    = hb_parni( 4 );
            rc.right  = hb_parni( 5 );
            rc.bottom = hb_parni( 6 );
      }

      InvalidateRect( hWnd, ( hb_pcount(  ) > 2 ) ? &rc : NULL, bErase );
}

/*=============================================================================
 * HWG_MOVETO()
 * Moves to a position
 *===========================================================================*/
HB_FUNC( HWG_MOVETO )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   MoveToEx( hDC, x1, y1, NULL );
}

/*=============================================================================
 * HWG_LINETO()
 * Draws a line to a position
 *===========================================================================*/
HB_FUNC( HWG_LINETO )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   LineTo( hDC, x1, y1 );
}

/*=============================================================================
 * HWG_DRAWLINE()
 * Draws a line between two points
 *===========================================================================*/
HB_FUNC( HWG_DRAWLINE )
{
   MoveToEx( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ), NULL );
   LineTo( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 4 ), hb_parni( 5 ) );
}

/*=============================================================================
 * HWG_TRIANGLE()
 * Draws a triangle
 *===========================================================================*/
HB_FUNC( HWG_TRIANGLE )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 ), x2 = hb_parni( 4 ), y2 = hb_parni( 5 );
   int x3 = hb_parni( 6 ), y3 = hb_parni( 7 );
   HPEN hPen = ( HB_ISNIL( 8 ) ) ? NULL : ( HPEN ) HB_PARHANDLE( 8 );
   HPEN hOldPen = NULL;

   if( hPen )
      hOldPen = (HPEN) SelectObject( hDC, hPen );

   MoveToEx( hDC, x1, y1, NULL );
   LineTo( hDC, x2, y2 );
   LineTo( hDC, x3, y3 );
   LineTo( hDC, x1, y1 );

   if( hOldPen )
      SelectObject( hDC, hOldPen );
}

/*=============================================================================
 * HWG_TRIANGLE_FILLED()
 * Draws a filled triangle
 *===========================================================================*/
HB_FUNC( HWG_TRIANGLE_FILLED )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   POINT apt[3];
   HPEN hPen = NULL, hOldPen = NULL;
   HBRUSH hBrush = ( HB_ISNIL( 9 ) ) ? NULL : (HBRUSH) HB_PARHANDLE( 9 );
   HBRUSH hOldBrush = NULL;
   int bNullPen = 0;

   if( !HB_ISNIL( 8 ) )
   {
      if( HB_ISLOG( 8 ) )
      {
         if( !hb_parl(8) )
         {
            hPen = (HPEN) GetStockObject( NULL_PEN );
            hOldPen = (HPEN) SelectObject( hDC, hPen );
            bNullPen = 1;
         }
      }
      else
      {
         hPen = ( HPEN ) HB_PARHANDLE( 8 );
         hOldPen = (HPEN) SelectObject( hDC, hPen );
      }
   }
   if( hBrush )
      hOldBrush = (HBRUSH) SelectObject( hDC, hBrush );

   apt[0].x = (long) hb_parni( 2 );
   apt[0].y = (long) hb_parni( 3 );
   apt[1].x = (long) hb_parni( 4 );
   apt[1].y = (long) hb_parni( 5 );
   apt[2].x = (long) hb_parni( 6 );
   apt[2].y = (long) hb_parni( 7 );

   Polygon( hDC, apt, 3 );

   if( hOldPen )
      SelectObject( hDC, hOldPen );
   if( bNullPen )
      DeleteObject( hPen );
   if( hOldBrush )
      SelectObject( hDC, hOldBrush );
}

/*=============================================================================
 * HWG_RECTANGLE()
 * Draws a rectangle
 *===========================================================================*/
HB_FUNC( HWG_RECTANGLE )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 ), x2 = hb_parni( 4 ), y2 = hb_parni( 5 );
   HPEN hPen = ( HB_ISNIL( 6 ) ) ? NULL : ( HPEN ) HB_PARHANDLE( 6 );
   HPEN hOldPen = NULL;

   if( hPen )
      hOldPen = (HPEN) SelectObject( hDC, hPen );

   MoveToEx( hDC, x1, y1, NULL );
   LineTo( hDC, x2, y1 );
   LineTo( hDC, x2, y2 );
   LineTo( hDC, x1, y2 );
   LineTo( hDC, x1, y1 );

   if( hOldPen )
      SelectObject( hDC, hOldPen );
}

/*=============================================================================
 * HWG_RECTANGLE_FILLED()
 * Draws a filled rectangle
 *===========================================================================*/
HB_FUNC( HWG_RECTANGLE_FILLED )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HPEN hPen = NULL, hOldPen = NULL;
   HBRUSH hBrush = ( HB_ISNIL( 7 ) ) ? NULL : (HBRUSH) HB_PARHANDLE( 7 );
   HBRUSH hOldBrush = NULL;
   int bNullPen = 0;

   if( !HB_ISNIL( 6 ) )
   {
      if( HB_ISLOG( 6 ) )
      {
         if( !hb_parl(6) )
         {
            hPen = (HPEN) GetStockObject( NULL_PEN );
            hOldPen = (HPEN) SelectObject( hDC, hPen );
            bNullPen = 1;
         }
      }
      else
      {
         hPen = ( HPEN ) HB_PARHANDLE( 6 );
         hOldPen = (HPEN) SelectObject( hDC, hPen );
      }
   }
   if( hBrush )
      hOldBrush = (HBRUSH) SelectObject( hDC, hBrush );

   Rectangle( hDC, hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ) );

   if( hOldPen )
      SelectObject( hDC, hOldPen );
   if( bNullPen )
      DeleteObject( hPen );
   if( hOldBrush )
      SelectObject( hDC, hOldBrush );
}

/*=============================================================================
 * HWG_ELLIPSE()
 * Draws an ellipse
 *===========================================================================*/
HB_FUNC( HWG_ELLIPSE )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HBRUSH hBrush = (HBRUSH) GetStockObject( NULL_BRUSH );
   HBRUSH hOldBrush = (HBRUSH) SelectObject( hDC, hBrush );
   HPEN hPen = ( HB_ISNIL( 6 ) ) ? NULL : ( HPEN ) HB_PARHANDLE( 6 );
   HPEN hOldPen = NULL;
   int res;

   if( hPen )
      hOldPen = (HPEN) SelectObject( hDC, hPen );

   res = Ellipse( hDC, hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ) );

   hb_retnl( res ? 0 : ( LONG ) GetLastError(  ) );
   if( hOldPen )
      SelectObject( hDC, hOldPen );
   SelectObject(hDC, hOldBrush);
   DeleteObject( hBrush );
}

/*=============================================================================
 * HWG_ELLIPSE_FILLED()
 * Draws a filled ellipse
 *===========================================================================*/
HB_FUNC( HWG_ELLIPSE_FILLED )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HBRUSH hBrush = ( HB_ISNIL( 7 ) ) ? NULL : (HBRUSH) HB_PARHANDLE( 7 );
   HBRUSH hOldBrush = NULL;
   HPEN hPen = NULL, hOldPen = NULL;
   int bNullPen = 0;
   int res;

   if( !HB_ISNIL( 6 ) )
   {
      if( HB_ISLOG( 6 ) )
      {
         if( !hb_parl(6) )
         {
            hPen = (HPEN) GetStockObject( NULL_PEN );
            hOldPen = (HPEN) SelectObject( hDC, hPen );
            bNullPen = 1;
         }
      }
      else
      {
         hPen = ( HPEN ) HB_PARHANDLE( 6 );
         hOldPen = (HPEN) SelectObject( hDC, hPen );
      }
   }
   if( hBrush )
      hOldBrush = (HBRUSH) SelectObject( hDC, hBrush );

   res = Ellipse( hDC, hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ) );

   hb_retnl( res ? 0 : ( LONG ) GetLastError(  ) );
   if( hOldPen )
      SelectObject( hDC, hOldPen );
   if( bNullPen )
      DeleteObject( hPen );
   if( hOldBrush )
      SelectObject( hDC, hOldBrush );
}

/*=============================================================================
 * HWG_ROUNDRECT()
 * Draws a rounded rectangle
 *===========================================================================*/
HB_FUNC( HWG_ROUNDRECT )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int iWidth = hb_parni( 6 );
   HBRUSH hBrush = (HBRUSH) GetStockObject( NULL_BRUSH );
   HBRUSH hOldBrush = (HBRUSH) SelectObject( hDC, hBrush );
   HPEN hPen = ( HB_ISNIL( 7 ) ) ? NULL : ( HPEN ) HB_PARHANDLE( 7 );
   HPEN hOldPen = NULL;

   if( hPen )
      hOldPen = (HPEN) SelectObject( hDC, hPen );

   hb_parl( RoundRect( hDC, hb_parni( 2 ), hb_parni( 3 ),
               hb_parni( 4 ), hb_parni( 5 ),
               iWidth * 2, iWidth * 2 ) );

   if( hOldPen )
      SelectObject( hDC, hOldPen );
   SelectObject(hDC, hOldBrush);
   DeleteObject(hBrush);
}

/*=============================================================================
 * HWG_ROUNDRECT_FILLED()
 * Draws a filled rounded rectangle
 *===========================================================================*/
HB_FUNC( HWG_ROUNDRECT_FILLED )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int iWidth = hb_parni( 6 );
   HBRUSH hBrush = ( HB_ISNIL( 8 ) ) ? NULL : ( HBRUSH ) HB_PARHANDLE( 8 );
   HBRUSH hOldBrush = NULL;
   HPEN hPen = NULL, hOldPen = NULL;
   int bNullPen = 0;

   if( !HB_ISNIL( 7 ) )
   {
      if( HB_ISLOG( 7 ) )
      {
         if( !hb_parl(7) )
         {
            hPen = (HPEN) GetStockObject( NULL_PEN );
            hOldPen = (HPEN) SelectObject( hDC, hPen );
            bNullPen = 1;
         }
      }
      else
      {
         hPen = ( HPEN ) HB_PARHANDLE( 7 );
         hOldPen = (HPEN) SelectObject( hDC, hPen );
      }
   }
   if( hBrush )
      hOldBrush = (HBRUSH) SelectObject( hDC, hBrush);

   hb_parl( RoundRect( hDC, hb_parni( 2 ), hb_parni( 3 ),
               hb_parni( 4 ), hb_parni( 5 ),
               iWidth * 2, iWidth * 2 ) );

   if( hOldPen )
      SelectObject( hDC, hOldPen );
   if( bNullPen )
      DeleteObject( hPen );
   if( hOldBrush )
      SelectObject( hDC, hOldBrush );
}

/*=============================================================================
 * HWG_CIRCLESECTOR()
 * Draws a circle sector
 *===========================================================================*/
HB_FUNC( HWG_CIRCLESECTOR )
{
   HDC hDC = (HDC) HB_PARHANDLE( 1 );
   int xc = hb_parni(2), yc = hb_parni(3);
   int radius = hb_parni(4);
   int iAngle1 = hb_parni(5), iAngle2 = hb_parni(6);
   HPEN hPen = ( HB_ISNIL( 7 ) ) ? NULL : ( HPEN ) HB_PARHANDLE( 7 );
   HPEN hOldPen = NULL;

   if( hPen )
      hOldPen = (HPEN) SelectObject( hDC, hPen );

   BeginPath( hDC );
   MoveToEx( hDC, xc, yc, (LPPOINT) NULL );
   AngleArc( hDC, xc, yc, radius, iAngle1, iAngle2 );
   LineTo( hDC, xc, yc );
   EndPath( hDC );
   StrokePath( hDC );

   if( hOldPen )
      SelectObject( hDC, hOldPen );
}

/*=============================================================================
 * HWG_CIRCLESECTOR_FILLED()
 * Draws a filled circle sector
 *===========================================================================*/
HB_FUNC( HWG_CIRCLESECTOR_FILLED )
{
   HDC hDC = (HDC) HB_PARHANDLE( 1 );
   int xc = hb_parni(2), yc = hb_parni(3);
   int radius = hb_parni(4);
   int iAngle1 = hb_parni(5), iAngle2 = hb_parni(6);
   HBRUSH hBrush = ( HB_ISNIL( 8 ) ) ? NULL : ( HBRUSH ) HB_PARHANDLE( 8 );
   HBRUSH hOldBrush = NULL;
   HPEN hPen = NULL, hOldPen = NULL;
   int bNullPen = 0;

   if( !HB_ISNIL( 7 ) )
   {
      if( HB_ISLOG( 7 ) )
      {
         if( !hb_parl(7) )
         {
            hPen = (HPEN) GetStockObject( NULL_PEN );
            hOldPen = (HPEN) SelectObject( hDC, hPen );
            bNullPen = 1;
         }
      }
      else
      {
         hPen = ( HPEN ) HB_PARHANDLE( 7 );
         hOldPen = (HPEN) SelectObject( hDC, hPen );
      }
   }
   if( hBrush )
      hOldBrush = (HBRUSH) SelectObject( hDC, hBrush);

   BeginPath( hDC );
   MoveToEx( hDC, xc, yc, (LPPOINT) NULL );
   AngleArc( hDC, xc, yc, radius, iAngle1, iAngle2 );
   LineTo( hDC, xc, yc );
   EndPath( hDC );
   StrokeAndFillPath( hDC );

   if( hOldPen )
      SelectObject( hDC, hOldPen );
   if( bNullPen )
      DeleteObject( hPen );
   if( hOldBrush )
      SelectObject( hDC, hOldBrush );
}

/*=============================================================================
 * HWG_PIE()
 * Draws a pie chart slice
 *===========================================================================*/
HB_FUNC( HWG_PIE )
{
   int res = Pie( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ),
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         hb_parni( 8 ), hb_parni( 9 ) );

   hb_retnl( res ? 0 : ( LONG ) GetLastError(  ) );
}

/*=============================================================================
 * HWG_FILLRECT()
 * Fills a rectangle with a brush
 *===========================================================================*/
HB_FUNC( HWG_FILLRECT )
{
   RECT rc;

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   FillRect( ( HDC ) HB_PARHANDLE( 1 ), &rc,
         HB_ISPOINTER( 6 ) ? ( HBRUSH )HB_PARHANDLE( 6 ) : ( HBRUSH )hb_parptr(6) );
}

/*=============================================================================
 * HWG_ARC()
 * Draws an arc
 *===========================================================================*/
HB_FUNC( HWG_ARC )
{
   HDC hDC = (HDC) HB_PARHANDLE( 1 );
   int xc = hb_parni(2), yc = hb_parni(3);
   int radius = hb_parni(4);
   int iAngle1 = hb_parni(5), iAngle2 = hb_parni(6);
   int x1, y1;

   iAngle1 = iAngle2 - iAngle1;
   iAngle2 = 360 - iAngle2;

   x1 = xc + radius * cos( iAngle2 * M_PI / 180 );
   y1 = yc - radius * sin( iAngle2 * M_PI / 180 );
   MoveToEx( hDC, x1, y1, (LPPOINT) NULL );
   AngleArc( hDC, xc, yc,
      (DWORD) radius,
      (FLOAT) iAngle2,
      (FLOAT) iAngle1 );
}

/*=============================================================================
 * HWG_REDRAWWINDOW()
 * Redraws a window
 *===========================================================================*/
HB_FUNC( HWG_REDRAWWINDOW )
{
   RECT rc;

   if( hb_pcount(  ) > 3 )
   {
      int x = ( hb_pcount(  ) > 3 && !HB_ISNIL( 3 ) ) ? hb_parni( 3 ) : 0;
      int y = ( hb_pcount(  ) >= 4 && !HB_ISNIL( 4 ) ) ? hb_parni( 4 ) : 0;
      int w = ( hb_pcount(  ) >= 5 && !HB_ISNIL( 5 ) ) ? hb_parni( 5 ) : 0;
      int h = ( hb_pcount(  ) >= 6 && !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : 0;
      rc.left = x - 1;
      rc.top = y - 1;
      rc.right = x + w + 1;
      rc.bottom = y + h + 1;
   }
   RedrawWindow( ( HWND ) HB_PARHANDLE( 1 ),
         ( hb_pcount(  ) > 3 ) ? &rc : NULL,
         NULL,
         ( UINT ) hb_parni( 2 ) );
}

/*=============================================================================
 * HWG_DRAWGRID()
 * Draws a grid pattern
 *===========================================================================*/
HB_FUNC( HWG_DRAWGRID )
{
   HDC hDC = (HDC) HB_PARHANDLE( 1 );
   int x1 = hb_parni(2), y1 = hb_parni(3), x2 = hb_parni(4), y2 = hb_parni(5);
   int n = ( HB_ISNIL( 6 ) ) ? 4 : hb_parni( 6 );
   COLORREF lColor = ( HB_ISNIL( 7 ) ) ? 0 : ( COLORREF ) hb_parnl( 7 );
   int i, j;

   for( i = x1+n; i < x2; i+=n )
      for( j = y1+n; j < y2; j+=n )
         SetPixel( hDC, i, j, lColor );
}

/*=============================================================================
 * HWG_DRAWBUTTON()
 * Draws a button
 *===========================================================================*/
HB_FUNC( HWG_DRAWBUTTON )
{
   RECT rc;
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   UINT iType = hb_parni( 6 );

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   if( iType == 0 )
      FillRect( hDC, &rc, ( HBRUSH ) ( COLOR_3DFACE + 1 ) );
   else
   {
      FillRect( hDC, &rc,
            ( HBRUSH ) ( INT_PTR ) ( ( ( iType & 2 ) ? COLOR_3DSHADOW : COLOR_3DHILIGHT ) + 1 ) );
      rc.left++;
      rc.top++;
      FillRect( hDC, &rc,
            ( HBRUSH ) ( INT_PTR ) ( ( ( iType & 2 ) ? COLOR_3DSHADOW : COLOR_3DHILIGHT ) + 1 ) );
      rc.right--;
      rc.bottom--;
      if( iType & 4 )
      {
         FillRect( hDC, &rc,
               ( HBRUSH ) ( INT_PTR ) ( ( ( iType & 2 ) ? COLOR_3DSHADOW : COLOR_3DHILIGHT ) + 1 ) );
         rc.left++;
         rc.top++;
         FillRect( hDC, &rc,
               ( HBRUSH ) ( INT_PTR ) ( ( ( iType & 2 ) ? COLOR_3DSHADOW : COLOR_3DHILIGHT ) + 1 ) );
         rc.right--;
         rc.bottom--;
      }
      FillRect( hDC, &rc, ( HBRUSH ) ( COLOR_3DFACE + 1 ) );
   }
}

/*=============================================================================
 * HWG_DRAWEDGE()
 * Draws an edge
 *===========================================================================*/
HB_FUNC( HWG_DRAWEDGE )
{
   RECT rc;
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   UINT edge = ( HB_ISNIL( 6 ) ) ? EDGE_RAISED : ( UINT ) hb_parni( 6 );
   UINT grfFlags = ( HB_ISNIL( 7 ) ) ? BF_RECT : ( UINT ) hb_parni( 7 );

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   hb_retl( DrawEdge( hDC, &rc, edge, grfFlags ) );
}

/*=============================================================================
 * HWG_LOADICON()
 * Loads an icon
 *===========================================================================*/
HB_FUNC( HWG_LOADICON )
{
      if( HB_ISNUM( 1 ) )
            HB_RETHANDLE( LoadIcon( NULL, MAKEINTRESOURCE( hb_parni( 1 ) ) ) );
      else
      {
            void *hString;
            LPCTSTR lpIconName = HB_PARSTR( 1, &hString, NULL );
            HB_RETHANDLE( LoadIcon( GetModuleHandle( NULL ), lpIconName ) );
            hb_strfree( hString );
      }
}

/*=============================================================================
 * HWG_LOADIMAGE()
 * Loads an image
 *===========================================================================*/
HB_FUNC( HWG_LOADIMAGE )
{
   void *hString = NULL;

   HB_RETHANDLE( LoadImage( HB_ISNIL( 1 ) ? GetModuleHandle( NULL ) : ( HINSTANCE ) hb_parptr( 1 ),
               HB_ISNUM( 2 ) ? MAKEINTRESOURCE( hb_parni( 2 ) ) : HB_PARSTR( 2, &hString, NULL ),
               ( UINT ) hb_parni( 3 ),
               hb_parni( 4 ),
               hb_parni( 5 ),
               ( UINT ) hb_parni( 6 ) ) );
   hb_strfree( hString );
}

/*=============================================================================
 * HWG_LOADBITMAP()
 * Loads a bitmap
 *===========================================================================*/
HB_FUNC( HWG_LOADBITMAP )
{
   if( HB_ISNUM( 1 ) )
   {
      if( !HB_ISNIL( 2 ) && hb_parl( 2 ) )
         HB_RETHANDLE( LoadBitmap( NULL, MAKEINTRESOURCE( hb_parni( 1 ) ) ) );
      else
         HB_RETHANDLE( LoadBitmap( GetModuleHandle( NULL ),
                     MAKEINTRESOURCE( hb_parni( 1 ) ) ) );
   }
   else
   {
      void *hString;
      HB_RETHANDLE( LoadBitmap( GetModuleHandle( NULL ), HB_PARSTR( 1,
                        &hString, NULL ) ) );
      hb_strfree( hString );
   }
}

/*=============================================================================
 * HWG_WINDOW2BITMAP()
 * Captures a window to a bitmap
 *===========================================================================*/
HB_FUNC( HWG_WINDOW2BITMAP )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HDC hDC = GetWindowDC( hWnd );
   HDC hDCmem = CreateCompatibleDC( hDC );
   HBITMAP hBitmap;
   int x1 = HB_ISNUM(2) ? hb_parni(2) : 0;
   int y1 = HB_ISNUM(3) ? hb_parni(3) : 0;
   int width = HB_ISNUM(4) ? hb_parni(4) : 0;
   int height = HB_ISNUM(5) ? hb_parni(5) : 0;
   RECT rc;

   if( width == 0 || height == 0 )
   {
      GetWindowRect( hWnd, &rc );
      width = rc.right - rc.left;
      height = rc.bottom - rc.top;
   }

   hBitmap = CreateCompatibleBitmap( hDC, width, height );

   HGDIOBJ hOldObj = SelectObject( hDCmem, hBitmap );

   BitBlt( hDCmem, 0, 0, width, height, hDC, x1, y1, SRCCOPY );

   SelectObject( hDCmem, hOldObj );

   DeleteDC( hDCmem );
   ReleaseDC( hWnd, hDC );

   HB_RETHANDLE( hBitmap );
}

/*=============================================================================
 * HWG_DRAWBITMAP()
 * Draws a bitmap
 *===========================================================================*/
HB_FUNC( HWG_DRAWBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );
   DWORD dwraster = ( HB_ISNIL( 3 ) ) ? SRCCOPY : ( DWORD ) hb_parnl( 3 );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 2 );
   BITMAP bitmap;
   int nWidthDest = ( hb_pcount(  ) >= 5 &&
   !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : 0;
   int nHeightDest = ( hb_pcount(  ) >= 6 &&
   !HB_ISNIL( 7 ) ) ? hb_parni( 7 ) : 0;

   HGDIOBJ hOldObj = SelectObject( hDCmem, hBitmap );

   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap );
   if( nWidthDest && ( nWidthDest != bitmap.bmWidth ||
         nHeightDest != bitmap.bmHeight ) )
   {
      SetStretchBltMode( hDC, COLORONCOLOR );
      StretchBlt( hDC, hb_parni( 4 ), hb_parni( 5 ), nWidthDest, nHeightDest,
                  hDCmem, 0, 0, bitmap.bmWidth, bitmap.bmHeight, dwraster );
   }
   else
   {
      BitBlt( hDC, hb_parni( 4 ), hb_parni( 5 ), bitmap.bmWidth,
              bitmap.bmHeight, hDCmem, 0, 0, dwraster );
   }

   SelectObject( hDCmem, hOldObj );
   DeleteDC( hDCmem );
}

/*=============================================================================
 * HWG_DRAWTRANSPARENTBITMAP()
 * Draws a transparent bitmap
 *===========================================================================*/
HB_FUNC( HWG_DRAWTRANSPARENTBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 2 );
   COLORREF trColor =
   ( HB_ISNIL( 5 ) ) ? 0x00FFFFFF : ( COLORREF ) hb_parnl( 5 );
   COLORREF crOldBack = SetBkColor( hDC, 0x00FFFFFF );
   COLORREF crOldText = SetTextColor( hDC, 0 );
   HBITMAP bitmapTrans = NULL;
   HBITMAP pOldBitmapImage = NULL, pOldBitmapTrans = NULL;
   BITMAP bitmap;
   HDC dcImage, dcTrans;
   int x = hb_parni( 3 );
   int y = hb_parni( 4 );
   int nWidthDest = ( hb_pcount(  ) >= 5 &&
   !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : 0;
   int nHeightDest = ( hb_pcount(  ) >= 6 &&
   !HB_ISNIL( 7 ) ) ? hb_parni( 7 ) : 0;

   dcImage = CreateCompatibleDC( hDC );
   dcTrans = CreateCompatibleDC( hDC );

   pOldBitmapImage = ( HBITMAP ) SelectObject( dcImage, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap );

   int maskWidth = ( nWidthDest ) ? nWidthDest : bitmap.bmWidth;
   int maskHeight = ( nHeightDest ) ? nHeightDest : bitmap.bmHeight;

   bitmapTrans = CreateBitmap( maskWidth, maskHeight, 1, 1, NULL );

   pOldBitmapTrans = ( HBITMAP ) SelectObject( dcTrans, bitmapTrans );

   SetBkColor( dcImage, trColor );
   if( nWidthDest && ( nWidthDest != bitmap.bmWidth ||
         nHeightDest != bitmap.bmHeight ) )
   {
      SetStretchBltMode( hDC, COLORONCOLOR );
      TransparentBmp( hDC, x, y, nWidthDest, nHeightDest, dcImage,
                      bitmap.bmWidth, bitmap.bmHeight, trColor );
   }
   else
   {
      TransparentBmp( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage,
                      bitmap.bmWidth, bitmap.bmHeight, trColor );
   }

   if( dcImage && pOldBitmapImage )
      SelectObject( dcImage, pOldBitmapImage );

   if( dcTrans && pOldBitmapTrans )
      SelectObject( dcTrans, pOldBitmapTrans );

   SetBkColor( hDC, crOldBack );
   SetTextColor( hDC, crOldText );

   if( bitmapTrans )
      DeleteObject( bitmapTrans );

   if( dcImage )
      DeleteDC( dcImage );

   if( dcTrans )
      DeleteDC( dcTrans );
}

/*=============================================================================
 * HWG_SPREADBITMAP()
 * Spreads a bitmap across a rectangle
 *===========================================================================*/
HB_FUNC( HWG_SPREADBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 2 );
   BITMAP bitmap;
   RECT rc;
   int nLeft, nWidth, nHeight;

   rc.left   = ( HB_ISNUM( 3 ) ) ? hb_parni( 3 ) : 0;
   rc.top    = ( HB_ISNUM( 4 ) ) ? hb_parni( 4 ) : 0;
   rc.right  = ( HB_ISNUM( 5 ) ) ? hb_parni( 5 ) : 0;
   rc.bottom = ( HB_ISNUM( 6 ) ) ? hb_parni( 6 ) : 0;

   HGDIOBJ hOldObj = SelectObject( hDCmem, hBitmap );

   if( GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap ) == 0 ||
         bitmap.bmWidth <= 0 || bitmap.bmHeight <= 0 )
   {
      SelectObject( hDCmem, hOldObj );
      DeleteDC( hDCmem );
      return;
   }

   if( rc.left == 0 && rc.right == 0 )
      GetClientRect( WindowFromDC( hDC ), &rc );

   nLeft = rc.left;
   while( rc.top < rc.bottom )
   {
      nHeight = ( rc.bottom - rc.top >= bitmap.bmHeight ) ? bitmap.bmHeight : rc.bottom - rc.top;
      while( rc.left < rc.right )
      {
         nWidth = ( rc.right - rc.left >= bitmap.bmWidth ) ? bitmap.bmWidth : rc.right - rc.left;
         BitBlt( hDC, rc.left, rc.top, nWidth, nHeight, hDCmem, 0, 0, SRCCOPY );
         rc.left += bitmap.bmWidth;
      }
      rc.left = nLeft;
      rc.top += bitmap.bmHeight;
   }

   SelectObject( hDCmem, hOldObj );
   DeleteDC( hDCmem );
}

/*=============================================================================
 * HWG_CENTERBITMAP()
 * Centers a bitmap in a window
 *===========================================================================*/
HB_FUNC( HWG_CENTERBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );
   DWORD dwraster = ( HB_ISNIL( 4 ) ) ? SRCCOPY : ( DWORD ) hb_parnl( 4 );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 3 );
   BITMAP bitmap;
   RECT rc;
   HBRUSH hBrush =
   ( HB_ISNIL( 5 ) ) ? ( HBRUSH ) ( uintptr_t ) ( COLOR_WINDOW +
   1 ) : ( HBRUSH ) HB_PARHANDLE( 5 );

   HGDIOBJ hOldObj = SelectObject( hDCmem, hBitmap );

   if( GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap ) == 0 ||
         bitmap.bmWidth <= 0 || bitmap.bmHeight <= 0 )
   {
      SelectObject( hDCmem, hOldObj );
      DeleteDC( hDCmem );
      return;
   }

   GetClientRect( ( HWND ) HB_PARHANDLE( 2 ), &rc );

   FillRect( hDC, &rc, hBrush );
   BitBlt( hDC, ( rc.right - bitmap.bmWidth ) / 2,
           ( rc.bottom - bitmap.bmHeight ) / 2, bitmap.bmWidth, bitmap.bmHeight,
           hDCmem, 0, 0, dwraster );

   SelectObject( hDCmem, hOldObj );
   DeleteDC( hDCmem );
}

/*=============================================================================
 * HWG_GETBITMAPSIZE()
 * Gets bitmap dimensions
 *===========================================================================*/
HB_FUNC( HWG_GETBITMAPSIZE )
{
   BITMAP bitmap;
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   PHB_ITEM temp = hb_itemNew( NULL );
   int nret;

   memset( &bitmap, 0, sizeof( BITMAP ) );

   nret = GetObject( ( HBITMAP ) HB_PARHANDLE( 1 ), sizeof( BITMAP ),
                     ( LPVOID ) & bitmap );

   hb_itemPutNL( temp, bitmap.bmWidth );
   hb_itemArrayPut( aMetr, 1, temp );

   hb_itemPutNL( temp, bitmap.bmHeight );
   hb_itemArrayPut( aMetr, 2, temp );

   hb_itemPutNL( temp, bitmap.bmBitsPixel );
   hb_itemArrayPut( aMetr, 3, temp );

   hb_itemPutNL( temp, nret );
   hb_itemArrayPut( aMetr, 4, temp );

   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

/*=============================================================================
 * HWG_GETICONSIZE()
 * Gets icon dimensions
 *===========================================================================*/
HB_FUNC( HWG_GETICONSIZE )
{
   ICONINFO iinfo;
   PHB_ITEM aMetr = hb_itemArrayNew( 3 );
   PHB_ITEM temp = hb_itemNew( NULL );
   int nret;

   memset( &iinfo, 0, sizeof( ICONINFO ) );

   nret = GetIconInfo( ( HICON ) HB_PARHANDLE( 1 ), &iinfo );

   hb_itemPutNL( temp, iinfo.xHotspot * 2 );
   hb_itemArrayPut( aMetr, 1, temp );

   hb_itemPutNL( temp, iinfo.yHotspot * 2 );
   hb_itemArrayPut( aMetr, 2, temp );

   hb_itemPutNL( temp, nret );
   hb_itemArrayPut( aMetr, 3, temp );

   hb_itemRelease( temp );

   if( nret )
   {
      if( iinfo.hbmColor )
         DeleteObject( iinfo.hbmColor );
      if( iinfo.hbmMask )
         DeleteObject( iinfo.hbmMask );
   }

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

/*=============================================================================
 * HWG_OPENBITMAP()
 * Opens a bitmap from file
 *===========================================================================*/
HB_FUNC( HWG_OPENBITMAP )
{
   BITMAPFILEHEADER bmfh;
   BITMAPINFOHEADER bmih;
   LPBITMAPINFO lpbmi;
   DWORD dwRead;
   LPVOID lpvBits;
   HGLOBAL hmem1, hmem2;
   HBITMAP hbm = NULL;
   HDC hDC = ( hb_pcount(  ) > 1 && !HB_ISNIL( 2 ) ) ?
   ( HDC ) HB_PARHANDLE( 2 ) : NULL;
   void *hString = NULL;
   HANDLE hfbm;
   #ifdef UNICODE
      char szFileA[ MAX_PATH ];
      LPCWSTR lpFile = HB_PARSTR( 1, &hString, NULL );
      WideCharToMultiByte( CP_ACP, 0, lpFile, -1, szFileA, MAX_PATH, NULL, NULL );
      hfbm = CreateFileA( szFileA, GENERIC_READ,
   #else
      hfbm = CreateFile( HB_PARSTR( 1, &hString, NULL ), GENERIC_READ,
   #endif
   FILE_SHARE_READ, ( LPSECURITY_ATTRIBUTES ) NULL, OPEN_EXISTING,
   FILE_ATTRIBUTE_READONLY, ( HANDLE ) NULL );
   if( hString ) hb_strfree( hString );

   if( hfbm == INVALID_HANDLE_VALUE )
      {
         HB_RETHANDLE( NULL );
         return;
       }

   ReadFile( hfbm, &bmfh, sizeof( BITMAPFILEHEADER ), &dwRead, NULL );
   ReadFile( hfbm, &bmih, sizeof( BITMAPINFOHEADER ), &dwRead, NULL );

   int colorCount = ( bmih.biBitCount < 24 ) ? ( 1 << bmih.biBitCount ) : 0;
   if( colorCount > 256 ) colorCount = 256;

   hmem1 = GlobalAlloc( GHND, sizeof( BITMAPINFOHEADER ) + ( colorCount * sizeof( RGBQUAD ) ) );
   if( hmem1 == NULL )
   {
      CloseHandle( hfbm );
      HB_RETHANDLE( NULL );
      return;
   }

   lpbmi = ( LPBITMAPINFO ) GlobalLock( hmem1 );

   lpbmi->bmiHeader.biSize = bmih.biSize;
   lpbmi->bmiHeader.biWidth = bmih.biWidth;
   lpbmi->bmiHeader.biHeight = bmih.biHeight;
   lpbmi->bmiHeader.biPlanes = bmih.biPlanes;
   lpbmi->bmiHeader.biBitCount = bmih.biBitCount;
   lpbmi->bmiHeader.biCompression = bmih.biCompression;
   lpbmi->bmiHeader.biSizeImage = bmih.biSizeImage;
   lpbmi->bmiHeader.biXPelsPerMeter = bmih.biXPelsPerMeter;
   lpbmi->bmiHeader.biYPelsPerMeter = bmih.biYPelsPerMeter;
   lpbmi->bmiHeader.biClrUsed = bmih.biClrUsed;
   lpbmi->bmiHeader.biClrImportant = bmih.biClrImportant;

   switch ( bmih.biBitCount )
   {
      case 1:
      case 4:
      case 8:
         ReadFile( hfbm, lpbmi->bmiColors, ( colorCount * sizeof( RGBQUAD ) ), &dwRead, ( LPOVERLAPPED ) NULL );
         break;
      case 16:
      case 32:
         if( bmih.biCompression == BI_BITFIELDS )
            ReadFile( hfbm, lpbmi->bmiColors, ( 3 * sizeof( RGBQUAD ) ), &dwRead, ( LPOVERLAPPED ) NULL );
      break;
      case 24:
         break;
   }

   DWORD bitsSize = bmfh.bfSize - bmfh.bfOffBits;
   hmem2 = ( bitsSize > 0 ) ? GlobalAlloc( GHND, bitsSize ) : NULL;

   if( hmem2 != NULL )
   {
      lpvBits = GlobalLock( hmem2 );
      ReadFile( hfbm, lpvBits, bitsSize, &dwRead, NULL );

      if( !hDC )
         hDC = GetDC( 0 );

      hbm = CreateDIBitmap( hDC, &bmih, CBM_INIT, lpvBits, lpbmi, DIB_RGB_COLORS );

      if( hb_pcount(  ) < 2 || HB_ISNIL( 2 ) )
         ReleaseDC( 0, hDC );

      GlobalUnlock( hmem2 );
      GlobalFree( hmem2 );
   }

   GlobalUnlock( hmem1 );
   GlobalFree( hmem1 );
   CloseHandle( hfbm );

   HB_RETHANDLE( hbm );
}

/*=============================================================================
 * HWG_SAVEBITMAP()
 * Saves a bitmap to file
 *===========================================================================*/
HB_FUNC( HWG_SAVEBITMAP )
{
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 2 );
   HDC hDC;
   int iBits;
   WORD wBitCount;
   DWORD dwPaletteSize = 0, dwBmBitsSize, dwDIBSize, dwWritten = 0;
   BITMAP Bitmap0;
   BITMAPFILEHEADER bmfHdr;
   BITMAPINFOHEADER bi;
   LPBITMAPINFOHEADER lpbi;
   HANDLE fh, hDib, hPal, hOldPal2 = NULL;
   void *hString;

   hDC = CreateIC( TEXT("DISPLAY"), NULL, NULL, NULL );
   if( hDC )
   {
      iBits = GetDeviceCaps( hDC, BITSPIXEL ) * GetDeviceCaps( hDC, PLANES );
      DeleteDC( hDC );
   }
   else
   {
      iBits = 24;
   }

   if( iBits <= 1 )
      wBitCount = 1;
   else if( iBits <= 4 )
      wBitCount = 4;
   else if( iBits <= 8 )
      wBitCount = 8;
   else
      wBitCount = 24;

   if( GetObject( hBitmap, sizeof( Bitmap0 ), ( LPSTR ) & Bitmap0 ) == 0 )
   {
      hb_retl( 0 );
      return;
   }

   memset( &bi, 0, sizeof( BITMAPINFOHEADER ) );
   bi.biSize = sizeof( BITMAPINFOHEADER );
   bi.biWidth = Bitmap0.bmWidth;
   bi.biHeight = -Bitmap0.bmHeight;
   bi.biPlanes = 1;
   bi.biBitCount = wBitCount;
   bi.biCompression = BI_RGB;

   dwBmBitsSize = ( ( Bitmap0.bmWidth * wBitCount + 31 ) & ~31 ) / 8 * Bitmap0.bmHeight;

   DWORD dwAllocSize = dwBmBitsSize + dwPaletteSize + sizeof( BITMAPINFOHEADER );
   hDib = GlobalAlloc( GHND, dwAllocSize );
   if( hDib == NULL )
   {
      hb_retl( 0 );
      return;
   }

   lpbi = ( LPBITMAPINFOHEADER ) GlobalLock( hDib );
   *lpbi = bi;

   hDC = GetDC( NULL );
   hPal = GetStockObject( DEFAULT_PALETTE );
   if( hPal && hDC )
   {
      hOldPal2 = SelectPalette( hDC, ( HPALETTE ) hPal, FALSE );
      RealizePalette( hDC );
   }

   GetDIBits( hDC, hBitmap, 0, ( UINT ) Bitmap0.bmHeight,
              ( LPSTR ) lpbi + sizeof( BITMAPINFOHEADER ) + dwPaletteSize,
              ( BITMAPINFO * ) lpbi, DIB_RGB_COLORS );

   if( hDC )
   {
      if( hOldPal2 )
      {
         SelectPalette( hDC, ( HPALETTE ) hOldPal2, TRUE );
         RealizePalette( hDC );
      }
      ReleaseDC( NULL, hDC );
   }

   fh = CreateFile( HB_PARSTR( 1, &hString, NULL ), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS,
                    FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL );
   hb_strfree( hString );

   if( fh == INVALID_HANDLE_VALUE )
   {
      GlobalUnlock( hDib );
      GlobalFree( hDib );
      hb_retl( 0 );
      return;
   }

   bmfHdr.bfType = 0x4D42;
   dwDIBSize = sizeof( BITMAPFILEHEADER ) + sizeof( BITMAPINFOHEADER ) + dwPaletteSize + dwBmBitsSize;
   bmfHdr.bfSize = dwDIBSize;
   bmfHdr.bfReserved1 = 0;
   bmfHdr.bfReserved2 = 0;
   bmfHdr.bfOffBits = ( DWORD ) sizeof( BITMAPFILEHEADER ) + ( DWORD ) sizeof( BITMAPINFOHEADER ) + dwPaletteSize;

   WriteFile( fh, ( LPSTR ) & bmfHdr, sizeof( BITMAPFILEHEADER ), &dwWritten, NULL );
   WriteFile( fh, ( LPSTR ) lpbi, dwAllocSize, &dwWritten, NULL );

   GlobalUnlock( hDib );
   GlobalFree( hDib );
   CloseHandle( fh );
   hb_retl( 1 );
}

/*=============================================================================
 * HWG_DRAWICONEX()
 * Draws an icon with extended options
 *===========================================================================*/
HB_FUNC( HWG_DRAWICONEX )
{
   DrawIconEx( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 3 ), hb_parni( 4 ),
         ( HICON ) HB_PARHANDLE( 2 ), hb_parni( 5 ), hb_parni( 6 ), 0, NULL, DI_NORMAL | DI_COMPAT );
}

/*=============================================================================
 * HWG_DRAWICON()
 * Draws an icon
 *===========================================================================*/
HB_FUNC( HWG_DRAWICON )
{
   DrawIcon( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 3 ), hb_parni( 4 ),
         ( HICON ) HB_PARHANDLE( 2 ) );
}

/*=============================================================================
 * HWG_GETSYSCOLOR()
 * Gets a system color
 *===========================================================================*/
HB_FUNC( HWG_GETSYSCOLOR )
{
   hb_retnl( ( HB_LONG ) GetSysColor( hb_parni( 1 ) ) );
}

/*=============================================================================
 * HWG_GETSYSCOLORBRUSH()
 * Gets a system color brush
 *===========================================================================*/
HB_FUNC( HWG_GETSYSCOLORBRUSH )
{
   HBRUSH hBrush = GetSysColorBrush( hb_parni( 1 ) );
   HB_RETHANDLE( hBrush );
}

/*=============================================================================
 * HWG_CREATEPEN()
 * Creates a pen
 *===========================================================================*/
HB_FUNC( HWG_CREATEPEN )
{
   HPEN hPen = CreatePen( hb_parni( 1 ), hb_parni( 2 ), ( COLORREF ) hb_parnl( 3 ) );
   HB_RETHANDLE( hPen );
}

/*=============================================================================
 * HWG_CREATESOLIDBRUSH()
 * Creates a solid brush
 *===========================================================================*/
HB_FUNC( HWG_CREATESOLIDBRUSH )
{
   HBRUSH hBrush = CreateSolidBrush( ( COLORREF ) hb_parnl( 1 ) );
   HB_RETHANDLE( hBrush );
}

/*=============================================================================
 * HWG_CREATEHATCHBRUSH()
 * Creates a hatch brush
 *===========================================================================*/
HB_FUNC( HWG_CREATEHATCHBRUSH )
{
   HBRUSH hBrush = CreateHatchBrush( hb_parni( 1 ), ( COLORREF ) hb_parnl( 2 ) );
   HB_RETHANDLE( hBrush );
}

/*=============================================================================
 * HWG_SELECTOBJECT()
 * Selects an object into a device context
 *===========================================================================*/
HB_FUNC( HWG_SELECTOBJECT )
{
   HGDIOBJ hOldObj = SelectObject( ( HDC ) HB_PARHANDLE( 1 ), ( HGDIOBJ ) HB_PARHANDLE( 2 ) );
   HB_RETHANDLE( hOldObj );
}

/*=============================================================================
 * HWG_DELETEOBJECT()
 * Deletes a GDI object
 *===========================================================================*/
HB_FUNC( HWG_DELETEOBJECT )
{
   hb_retl( DeleteObject( ( HGDIOBJ ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_GETDC()
 * Gets a device context
 *===========================================================================*/
HB_FUNC( HWG_GETDC )
{
   HDC hDC = GetDC( ( HWND ) HB_PARHANDLE( 1 ) );
   HB_RETHANDLE( hDC );
}

/*=============================================================================
 * HWG_RELEASEDC()
 * Releases a device context
 *===========================================================================*/
HB_FUNC( HWG_RELEASEDC )
{
   hb_retl( ReleaseDC( ( HWND ) HB_PARHANDLE( 1 ), ( HDC ) HB_PARHANDLE( 2 ) ) != 0 );
}

/*=============================================================================
 * HWG_GETDRAWITEMINFO()
 * Gets draw item info
 *===========================================================================*/
HB_FUNC( HWG_GETDRAWITEMINFO )
{
   DRAWITEMSTRUCT *lpdis = ( DRAWITEMSTRUCT * ) HB_PARHANDLE( 1 );
   PHB_ITEM aMetr = hb_itemArrayNew( 9 );
   PHB_ITEM temp = hb_itemNew( NULL );

   if( lpdis )
   {
      hb_itemPutNL( temp, ( LONG ) lpdis->itemID );
      hb_itemArrayPut( aMetr, 1, temp );

      hb_itemPutNL( temp, ( LONG ) lpdis->itemAction );
      hb_itemArrayPut( aMetr, 2, temp );

      hb_itemPutPtr( temp, ( void * ) lpdis->hDC );
      hb_itemArrayPut( aMetr, 3, temp );

      hb_itemPutNL( temp, ( LONG ) lpdis->rcItem.left );
      hb_itemArrayPut( aMetr, 4, temp );

      hb_itemPutNL( temp, ( LONG ) lpdis->rcItem.top );
      hb_itemArrayPut( aMetr, 5, temp );

      hb_itemPutNL( temp, ( LONG ) lpdis->rcItem.right );
      hb_itemArrayPut( aMetr, 6, temp );

      hb_itemPutNL( temp, ( LONG ) lpdis->rcItem.bottom );
      hb_itemArrayPut( aMetr, 7, temp );

      hb_itemPutPtr( temp, ( void * ) lpdis->hwndItem );
      hb_itemArrayPut( aMetr, 8, temp );

      hb_itemPutNInt( temp, ( HB_MAXINT ) lpdis->itemState );
      hb_itemArrayPut( aMetr, 9, temp );
   }

   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

/*=============================================================================
 * HWG_DRAWGRAYBITMAP()
 * Draws a grayscale bitmap
 *===========================================================================*/
HB_FUNC( HWG_DRAWGRAYBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 2 );
   HBITMAP bitmapgray = NULL;
   HBITMAP pOldBitmapImage = NULL, pOldbitmapgray = NULL;
   BITMAP bitmap;
   HDC dcImage, dcTrans;
   int x = hb_parni( 3 );
   int y = hb_parni( 4 );

   if( !hDC || !hBitmap )
      return;

   if( GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap ) == 0 ||
         bitmap.bmWidth <= 0 || bitmap.bmHeight <= 0 )
   {
      return;
   }

   COLORREF crOldBack = SetBkColor( hDC, GetSysColor( COLOR_BTNHIGHLIGHT ) );
   COLORREF crOldText = SetTextColor( hDC, GetSysColor( COLOR_BTNSHADOW ) );

   dcImage = CreateCompatibleDC( hDC );
   dcTrans = CreateCompatibleDC( hDC );

   pOldBitmapImage = ( HBITMAP ) SelectObject( dcImage, hBitmap );

   bitmapgray = CreateBitmap( bitmap.bmWidth, bitmap.bmHeight, 1, 1, NULL );

   pOldbitmapgray = ( HBITMAP ) SelectObject( dcTrans, bitmapgray );

   SetBkColor( dcImage, RGB( 255, 255, 255 ) );
   BitBlt( dcTrans, 0, 0, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCCOPY );

   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCINVERT );
   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcTrans, 0, 0, SRCAND );
   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCINVERT );

   if( dcImage && pOldBitmapImage )
      SelectObject( dcImage, pOldBitmapImage );

   if( dcTrans && pOldbitmapgray )
      SelectObject( dcTrans, pOldbitmapgray );

   SetBkColor( hDC, crOldBack );
   SetTextColor( hDC, crOldText );

   if( bitmapgray )
      DeleteObject( bitmapgray );

   if( dcImage )
      DeleteDC( dcImage );

   if( dcTrans )
      DeleteDC( dcTrans );
}

#include <olectl.h>
#include <ole2.h>
#include <ocidl.h>

/*=============================================================================
 * HWG_OPENIMAGE()
 * Opens an image from file or string
 *===========================================================================*/
HB_FUNC( HWG_OPENIMAGE )
{
      const char *cFileName = hb_parc( 1 );   // ANSI
      BOOL bString = ( HB_ISNIL( 2 ) ) ? 0 : hb_parl( 2 );
      int iType = ( HB_ISNIL( 3 ) ) ? IMAGE_BITMAP : hb_parni( 3 );
      int iFileSize;
      FILE *fp;
      LPPICTURE pPic = NULL;
      IStream *pStream = NULL;
      HGLOBAL hG;
      HBITMAP hRetResult = NULL;

      if( bString )
      {
            iFileSize = hb_parclen( 1 );
            hG = GlobalAlloc( GPTR, iFileSize );
            if( !hG )
            {
                  hb_retptr( NULL );
                  return;
            }
            memcpy( ( void * ) hG, ( void * ) cFileName, iFileSize );
      }
      else
      {
            fp = fopen( cFileName, "rb" );   // fopen aceita const char*
            if( !fp )
            {
                  hb_retptr( NULL );
                  return;
            }

            fseek( fp, 0, SEEK_END );
            iFileSize = ftell( fp );
            hG = GlobalAlloc( GPTR, iFileSize );
            if( !hG )
            {
                  fclose( fp );
                  hb_retptr( NULL );
                  return;
            }
            fseek( fp, 0, SEEK_SET );
            fread( ( void * ) hG, 1, iFileSize, fp );
            fclose( fp );
      }

      CreateStreamOnHGlobal( hG, 0, &pStream );

      if( !pStream )
      {
            GlobalFree( hG );
            hb_retptr( NULL );
            return;
      }

      #if defined(__cplusplus)
      OleLoadPicture( pStream, 0, 0, IID_IPicture, ( void ** ) &pPic );
      pStream->Release(  );
      #else
      OleLoadPicture( pStream, 0, 0, &IID_IPicture, ( void ** ) ( void * ) &pPic );
      pStream->lpVtbl->Release( pStream );
      #endif

      GlobalFree( hG );

      if( !pPic )
      {
            hb_retptr( NULL );
            return;
      }

      OLE_HANDLE oHnd = 0;

      if( iType == IMAGE_BITMAP )
      {
            #if defined(__cplusplus)
            pPic->get_Handle( &oHnd );
            #else
            pPic->lpVtbl->get_Handle( pPic, &oHnd );
            #endif
            if( oHnd )
                  hRetResult = ( HBITMAP ) CopyImage( ( HBITMAP ) ( uintptr_t ) oHnd, IMAGE_BITMAP, 0, 0, LR_COPYRETURNORG );
      }
      else if( iType == IMAGE_ICON )
      {
            #if defined(__cplusplus)
            pPic->get_Handle( &oHnd );
            #else
            pPic->lpVtbl->get_Handle( pPic, &oHnd );
            #endif
            if( oHnd )
                  hRetResult = ( HBITMAP ) CopyImage( ( HICON ) ( uintptr_t ) oHnd, IMAGE_ICON, 0, 0, 0 );
      }
      else
      {
            #if defined(__cplusplus)
            pPic->get_Handle( &oHnd );
            #else
            pPic->lpVtbl->get_Handle( pPic, &oHnd );
            #endif
            if( oHnd )
                  hRetResult = ( HBITMAP ) CopyImage( ( HCURSOR ) ( uintptr_t ) oHnd, IMAGE_CURSOR, 0, 0, 0 );
      }

      #if defined(__cplusplus)
      pPic->Release(  );
      #else
      pPic->lpVtbl->Release( pPic );
      #endif

      HB_RETHANDLE( hRetResult );
}

#if defined( __USE_GDIPLUS )

void hwg_GdiplusInit( void )
{
   if( !gdiplusToken )
   {
      memset( &gdiplusStartupInput, 0, sizeof( GdiplusStartupInput ) );
      gdiplusStartupInput.GdiplusVersion = 1;
      GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);
   }
}

void hwg_GdiplusExit( void )
{
   if( gdiplusToken )
      GdiplusShutdown(gdiplusToken);
   gdiplusToken = 0;
}

HBITMAP GpBitmapToHBITMAP(GpBitmap* bitmap)
{
   HBITMAP hBitmap = NULL;
   GpStatus status;
   GpGraphics* tempGraphics;

   status = GdipCreateFromHWND(NULL, &tempGraphics);

   if (status == Ok) {
         status = GdipCreateHBITMAPFromBitmap(bitmap, &hBitmap, 0);
         GdipDeleteGraphics(tempGraphics);
   }

   return hBitmap;
}

#endif

/*=============================================================================
 * HWG_GDIPLUSOPENIMAGE()
 * Opens an image using GDI+
 *===========================================================================*/
HB_FUNC( HWG_GDIPLUSOPENIMAGE )
{
   #if defined( __USE_GDIPLUS )
      GpBitmap* bitmap = NULL;
      HBITMAP hBitmap;
      void *hString;
      LPCTSTR cFileName = HB_PARSTR( 1, &hString, NULL );
      wchar_t* wcharString;

#ifdef UNICODE
      wcharString = (wchar_t*) cFileName;
#else
      int wstrSize = MultiByteToWideChar( CP_ACP, 0, cFileName, -1, NULL, 0 );
      if( wstrSize == 0 )
      {
         hb_retptr( NULL );
         hb_strfree( hString );
         return;
      }
      wcharString = (wchar_t*) malloc( sizeof(wchar_t) * wstrSize );
      if( wcharString == NULL )
      {
         hb_retptr( NULL );
         hb_strfree( hString );
         return;
      }
      MultiByteToWideChar( CP_ACP, 0, cFileName, -1, wcharString, wstrSize );
#endif

      hwg_GdiplusInit();
      GdipCreateBitmapFromFile( wcharString, &bitmap );

#ifndef UNICODE
      free((void*)wcharString);
#endif
      hb_strfree( hString );

      if( bitmap ) {
         hBitmap = GpBitmapToHBITMAP( bitmap );
         GdipDisposeImage(bitmap);
         if( hBitmap )
         {
            hb_retptr( hBitmap );
            return;
         }
      }
   #endif
   hb_retptr( NULL );
}

/*=============================================================================
 * HWG_PATBLT()
 * Pattern block transfer
 *===========================================================================*/
HB_FUNC( HWG_PATBLT )
{
   hb_retl( PatBlt( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ),
                    hb_parni( 4 ), hb_parni( 5 ), hb_parnl( 6 ) ) );
}

/*=============================================================================
 * HWG_SAVEDC()
 * Saves a device context
 *===========================================================================*/
HB_FUNC( HWG_SAVEDC )
{
   hb_retl( SaveDC( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_RESTOREDC()
 * Restores a device context
 *===========================================================================*/
HB_FUNC( HWG_RESTOREDC )
{
   hb_retl( RestoreDC( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ) ) );
}

/*=============================================================================
 * HWG_CREATECOMPATIBLEDC()
 * Creates a compatible device context
 *===========================================================================*/
HB_FUNC( HWG_CREATECOMPATIBLEDC )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );
   HB_RETHANDLE( hDCmem );
}

/*=============================================================================
 * HWG_SETMAPMODE()
 * Sets map mode
 *===========================================================================*/
HB_FUNC( HWG_SETMAPMODE )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   hb_retni( SetMapMode( hDC, hb_parni( 2 ) ) );
}

/*=============================================================================
 * HWG_SETWINDOWORGEX()
 * Sets window origin
 *===========================================================================*/
HB_FUNC( HWG_SETWINDOWORGEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   SetWindowOrgEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   if( hb_pcount() >= 4 )
      hb_stornl( 0, 4 );
}

/*=============================================================================
 * HWG_SETWINDOWEXTEX()
 * Sets window extents
 *===========================================================================*/
HB_FUNC( HWG_SETWINDOWEXTEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   SetWindowExtEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   if( hb_pcount() >= 4 )
      hb_stornl( 0, 4 );
}

/*=============================================================================
 * HWG_SETVIEWPORTORGEX()
 * Sets viewport origin
 *===========================================================================*/
HB_FUNC( HWG_SETVIEWPORTORGEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   SetViewportOrgEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   if( hb_pcount() >= 4 )
      hb_stornl( 0, 4 );
}

/*=============================================================================
 * HWG_SETVIEWPORTEXTEX()
 * Sets viewport extents
 *===========================================================================*/
HB_FUNC( HWG_SETVIEWPORTEXTEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   SetViewportExtEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   if( hb_pcount() >= 4 )
      hb_stornl( 0, 4 );
}

/*=============================================================================
 * HWG_SETARCDIRECTION()
 * Sets arc direction
 *===========================================================================*/
HB_FUNC( HWG_SETARCDIRECTION )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   hb_retni( SetArcDirection( hDC, hb_parni( 2 ) ) );
}

/*=============================================================================
 * HWG_SETROP2()
 * Sets ROP2 mode
 *===========================================================================*/
HB_FUNC( HWG_SETROP2 )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   hb_retni( SetROP2( hDC, hb_parni( 2 ) ) );
}

/*=============================================================================
 * HWG_BITBLT()
 * Bit block transfer
 *===========================================================================*/
HB_FUNC( HWG_BITBLT )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDC1 = ( HDC ) HB_PARHANDLE( 6 );

   hb_retl( BitBlt( hDC, hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ),
                    hb_parni( 5 ), hDC1, hb_parni( 7 ), hb_parni( 8 ),
                    hb_parnl( 9 ) ) );
}

/*=============================================================================
 * HWG_CREATECOMPATIBLEBITMAP()
 * Creates a compatible bitmap
 *===========================================================================*/
HB_FUNC( HWG_CREATECOMPATIBLEBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HBITMAP hBitmap = CreateCompatibleBitmap( hDC, hb_parni( 2 ), hb_parni( 3 ) );
   HB_RETHANDLE( hBitmap );
}

/*=============================================================================
 * HWG_INFLATERECT()
 * Inflates a rectangle
 *===========================================================================*/
HB_FUNC( HWG_INFLATERECT )
{
   RECT pRect;
   int x = hb_parni( 2 );
   int y = hb_parni( 3 );
   BOOL bResult = FALSE;

   memset( &pRect, 0, sizeof( RECT ) );

   if( HB_ISARRAY( 1 ) )
      Array2Rect( hb_param( 1, HB_IT_ARRAY ), &pRect );

   bResult = InflateRect( &pRect, x, y );

   hb_storvni( pRect.left, 1, 1 );
   hb_storvni( pRect.top, 1, 2 );
   hb_storvni( pRect.right, 1, 3 );
   hb_storvni( pRect.bottom, 1, 4 );

   hb_retl( bResult );
}

/*=============================================================================
 * HWG_FRAMERECT()
 * Frames a rectangle
 *===========================================================================*/
HB_FUNC( HWG_FRAMERECT )
{
   HDC hdc = ( HDC ) HB_PARHANDLE( 1 );
   HBRUSH hbr = ( HBRUSH ) HB_PARHANDLE( 3 );
   RECT pRect;

   memset( &pRect, 0, sizeof( RECT ) );

   if( HB_ISARRAY( 2 ) )
      Array2Rect( hb_param( 2, HB_IT_ARRAY ), &pRect );

   hb_retni( FrameRect( hdc, &pRect, hbr ) );
}

/*=============================================================================
 * HWG_DRAWFRAMECONTROL()
 * Draws a frame control
 *===========================================================================*/
HB_FUNC( HWG_DRAWFRAMECONTROL )
{
   HDC hdc = ( HDC ) HB_PARHANDLE( 1 );
   RECT pRect;
   UINT uType = hb_parni( 3 );
   UINT uState = hb_parni( 4 );

   memset( &pRect, 0, sizeof( RECT ) );

   if( HB_ISARRAY( 2 ) )
      Array2Rect( hb_param( 2, HB_IT_ARRAY ), &pRect );

   hb_retl( DrawFrameControl( hdc, &pRect, uType, uState ) );
}

/*=============================================================================
 * HWG_OFFSETRECT()
 * Offsets a rectangle
 *===========================================================================*/
HB_FUNC( HWG_OFFSETRECT )
{
   RECT pRect;
   int x = hb_parni( 2 );
   int y = hb_parni( 3 );
   BOOL bResult = FALSE;

   memset( &pRect, 0, sizeof( RECT ) );

   if( HB_ISARRAY( 1 ) )
      Array2Rect( hb_param( 1, HB_IT_ARRAY ), &pRect );

   bResult = OffsetRect( &pRect, x, y );

   hb_storvni( pRect.left, 1, 1 );
   hb_storvni( pRect.top, 1, 2 );
   hb_storvni( pRect.right, 1, 3 );
   hb_storvni( pRect.bottom, 1, 4 );

   hb_retl( bResult );
}

/*=============================================================================
 * HWG_DRAWFOCUSRECT()
 * Draws a focus rectangle
 *===========================================================================*/
HB_FUNC( HWG_DRAWFOCUSRECT )
{
   RECT pRect;
   HDC hc = ( HDC ) HB_PARHANDLE( 1 );

   memset( &pRect, 0, sizeof( RECT ) );

   if( HB_ISARRAY( 2 ) )
      Array2Rect( hb_param( 2, HB_IT_ARRAY ), &pRect );

   hb_retl( DrawFocusRect( hc, &pRect ) );
}

/*=============================================================================
 * Array2Point()
 * Converts an array to a POINT structure
 *===========================================================================*/
BOOL Array2Point( PHB_ITEM aPoint, POINT * pt )
{
   if( HB_IS_ARRAY( aPoint ) && hb_arrayLen( aPoint ) == 2 )
   {
      pt->x = hb_arrayGetNL( aPoint, 1 );
      pt->y = hb_arrayGetNL( aPoint, 2 );
      return TRUE;
   }
   return FALSE;
}

/*=============================================================================
 * HWG_PTINRECT()
 * Tests if a point is in a rectangle
 *===========================================================================*/
HB_FUNC( HWG_PTINRECT )
{
   POINT pt;
   RECT rect;

   memset( &rect, 0, sizeof( RECT ) );
   memset( &pt, 0, sizeof( POINT ) );

   if( HB_ISARRAY( 1 ) )
      Array2Rect( hb_param( 1, HB_IT_ARRAY ), &rect );

   if( HB_ISARRAY( 2 ) )
      Array2Point( hb_param( 2, HB_IT_ARRAY ), &pt );

   hb_retl( PtInRect( &rect, pt ) );
}

/*=============================================================================
 * HWG_GETMEASUREITEMINFO()
 * Gets measure item info
 *===========================================================================*/
HB_FUNC( HWG_GETMEASUREITEMINFO )
{
   MEASUREITEMSTRUCT *lpdis = ( MEASUREITEMSTRUCT * ) HB_PARHANDLE( 1 );
   PHB_ITEM aMetr = hb_itemArrayNew( 5 );
   PHB_ITEM temp = hb_itemNew( NULL );

   if( lpdis )
   {
      hb_itemPutNL( temp, lpdis->CtlType );
      hb_itemArrayPut( aMetr, 1, temp );

      hb_itemPutNL( temp, lpdis->CtlID );
      hb_itemArrayPut( aMetr, 2, temp );

      hb_itemPutNL( temp, lpdis->itemID );
      hb_itemArrayPut( aMetr, 3, temp );

      hb_itemPutNL( temp, lpdis->itemWidth );
      hb_itemArrayPut( aMetr, 4, temp );

      hb_itemPutNL( temp, lpdis->itemHeight );
      hb_itemArrayPut( aMetr, 5, temp );
   }

   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

/*=============================================================================
 * HWG_COPYRECT()
 * Copies a rectangle
 *===========================================================================*/
HB_FUNC( HWG_COPYRECT )
{
   RECT p;
   memset( &p, 0, sizeof( RECT ) );

   if( HB_ISARRAY( 1 ) )
      Array2Rect( hb_param( 1, HB_IT_ARRAY ), &p );

   PHB_ITEM aRect = Rect2Array( &p );
   hb_itemReturn( aRect );
   hb_itemRelease( aRect );
}

/*=============================================================================
 * HWG_GETWINDOWDC()
 * Gets window device context
 *===========================================================================*/
HB_FUNC( HWG_GETWINDOWDC )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HDC hDC = GetWindowDC( hWnd );
   HB_RETHANDLE( hDC );
}

/*=============================================================================
 * HWG_MODIFYSTYLE()
 * Modifies window style
 *===========================================================================*/
HB_FUNC( HWG_MODIFYSTYLE )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   if( hWnd )
   {
      DWORD dwStyle = GetWindowLongPtr( hWnd, GWL_STYLE );
      DWORD a = hb_parnl( 2 );
      DWORD b = hb_parnl( 3 );
      DWORD dwNewStyle = ( dwStyle & ~a ) | b;
      SetWindowLongPtr( hWnd, GWL_STYLE, dwNewStyle );
   }
}

#define SECTORS_NUM 100

/*=============================================================================
 * HWG_DRAWGRADIENT()
 * Draws a gradient fill
 *===========================================================================*/
HB_FUNC( HWG_DRAWGRADIENT )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 ), x2 = hb_parni( 4 ), y2 = hb_parni( 5 );
   int type = ( HB_ISNUM(6) ) ? hb_parni( 6 ) : 1;
   PHB_ITEM pArrColor = hb_param( 7, HB_IT_ARRAY );
   long int color;
   int red[GRADIENT_MAX_COLORS], green[GRADIENT_MAX_COLORS], blue[GRADIENT_MAX_COLORS], index;
   int cur_red, cur_green, cur_blue, section_len;
   double red_step, green_step, blue_step;
   PHB_ITEM pArrStop = hb_param( 8, HB_IT_ARRAY );
   double stop;
   int stop_x[GRADIENT_MAX_COLORS], stop_y[GRADIENT_MAX_COLORS], coord_stop;
   int isH = 0, isV = 0, isD = 0, is_5_6 = 0, isR = 0;
   int x_center = 0, y_center = 0, gr_radius = 0;
   PHB_ITEM pArrRadius = NULL;
   int iRadius = 0;
   int radius[4];
   double angle, angle_step, coord_x, coord_y, min_delta, delta;
   int user_colors_num, colors_num, user_stops_num, user_radiuses_num, i, j, k;
   HDC hDC_mem = NULL;
   HBITMAP bmp = NULL;
   HGDIOBJ hBmpOld = NULL;
   HPEN hPen;
   HGDIOBJ hPenOld;
   HBRUSH hBrush;
   HGDIOBJ hBrushOld = NULL;
   TRIVERTEX vertex[(GRADIENT_MAX_COLORS-1)*2];
   GRADIENT_RECT gRect[GRADIENT_MAX_COLORS-1];
   int fill_type;
   POINT polygon[(SECTORS_NUM+1)*4], coords[SECTORS_NUM+1], candidates[4], center[4], edge[4];
   int polygon_len = 0, nearest_coord = 0, cycle_start, cycle_stop, cycle_step;
   int convert[4][2] = { {-1,1}, {1,1}, {1,-1}, {-1,-1} };
   LONG x, y;

   if( HB_ISNUM(9) )
      iRadius = hb_parni(9);
   else
      pArrRadius = hb_param( 9, HB_IT_ARRAY );

   if ( !pArrColor || ( user_colors_num = hb_arrayLen( pArrColor ) ) == 0 )
      return;

   if ( x2 <= x1 || y2 <= y1 )
      return;

   if ( user_colors_num >= 2 )
   {
      colors_num = ( user_colors_num <= GRADIENT_MAX_COLORS ) ? user_colors_num : GRADIENT_MAX_COLORS;
      user_stops_num = ( pArrStop ) ? hb_arrayLen( pArrStop ) : 0;

      type = ( type >= 1 && type <= 9 ) ? type : 1;
      if ( type == 1 || type == 2 ) isV = 1;
      if ( type == 3 || type == 4 ) isH = 1;
      if ( type >= 5 && type <= 8 ) isD = 1;
      if ( type == 9 )
      {
         isR = 1;
         x_center = (x2 - x1) / 2 + x1;
         y_center = (y2 - y1) / 2 + y1;
         gr_radius = sqrt( pow((long double)(x2-x1),2) + pow((long double)(y2-y1),2) ) / 2;
      }

      for ( i = 0; i < colors_num; i++ )
      {
         stop = ( i < user_stops_num ) ? hb_arrayGetND( pArrStop, i+1 ) : 1. / (colors_num-1) * i;
         if ( isV )
         {
            coord_stop = floor( stop * (y2-y1+1) + 0.5 );
            if ( type == 1 )
               stop_y[i] = y1 + coord_stop;
            else
               stop_y[colors_num-1-i] = y2 + 1 - coord_stop;
         }
         if ( isH )
         {
            coord_stop = floor( stop * (x2-x1+1) + 0.5 );
            if ( type == 3 )
               stop_x[i] = x1 + coord_stop;
            else
               stop_x[colors_num-1-i] = x2 + 1 - coord_stop;
         }
         if ( isD )
         {
            coord_stop = floor( stop * 2*(x2-x1+1) + 0.5 );
            if ( type == 5 || type == 7 )
               stop_x[i] = 2*x1-x2-1 + coord_stop;
            else
               stop_x[colors_num-1-i] = x2 + 1 - coord_stop;
         }
         if ( isR )
            stop_x[i] = floor( stop * gr_radius + 0.5 );

         color = hb_arrayGetNL( pArrColor, i+1 );
         index = ( type == 2 || type == 4 || type == 6 || type == 8 ) ? colors_num-1-i : i;
         red[ index ]   = color % 256;
         green[ index ] = color / 256 % 256;
         blue[ index ]  = color / 256 / 256 % 256;
      }

      hDC_mem = CreateCompatibleDC( hDC );

      if ( type >= 1 && type <= 4 )
      {
         bmp = ( HBITMAP ) CreateCompatibleBitmap( hDC, x2+1, y2+1 );
         hBmpOld = SelectObject( hDC_mem, bmp );

         for ( i = 1; i < colors_num; i++ )
         {
            vertex[(i-1)*2].x     = ( isH ) ? stop_x[i-1] : x1;
            vertex[(i-1)*2].y     = ( isV ) ? stop_y[i-1] : y1;
            vertex[(i-1)*2].Red   = (COLOR16) (red[i-1] * 257);
            vertex[(i-1)*2].Green = (COLOR16) (green[i-1] * 257);
            vertex[(i-1)*2].Blue  = (COLOR16) (blue[i-1] * 257);
            vertex[(i-1)*2].Alpha = 0x0000;

            vertex[(i-1)*2+1].x     = ( isH ) ? stop_x[i] : x2 + 1;
            vertex[(i-1)*2+1].y     = ( isV ) ? stop_y[i] : y2 + 1;
            vertex[(i-1)*2+1].Red   = (COLOR16) (red[i] * 257);
            vertex[(i-1)*2+1].Green = (COLOR16) (green[i] * 257);
            vertex[(i-1)*2+1].Blue  = (COLOR16) (blue[i] * 257);
            vertex[(i-1)*2+1].Alpha = 0x0000;

            gRect[i-1].UpperLeft  = (i-1)*2;
            gRect[i-1].LowerRight = (i-1)*2+1;
         }

         if( FuncGradientFill == NULL )
         {
            FuncGradientFill = ( GRADIENTFILL )
            GetProcAddress( LoadLibrary( TEXT( "MSIMG32.DLL" ) ),
                            "GradientFill" );
         }

         fill_type = ( isV ) ? GRADIENT_FILL_RECT_V : GRADIENT_FILL_RECT_H;

         FuncGradientFill( hDC_mem, vertex, (colors_num-1)*2, gRect, (colors_num-1), fill_type );

         if( ( isV && stop_y[0] > y1 ) || ( isH && stop_x[0] > x1 ) )
         {
            hPen = CreatePen( PS_SOLID, 1, RGB(red[0], green[0], blue[0]) );
            hPenOld = SelectObject( hDC_mem, hPen );
            hBrush = CreateSolidBrush( RGB(red[0], green[0], blue[0]) );
            SelectObject( hDC_mem, hBrush );
            if ( isV )
               Rectangle( hDC_mem, x1, y1, x2 + 1, stop_y[0] );
            else
               Rectangle( hDC_mem, x1, y1, stop_x[0], y2 + 1 );

            SelectObject( hDC_mem, hPenOld );
            DeleteObject( hPen );
            SelectObject( hDC_mem, GetStockObject( NULL_BRUSH ) );
            DeleteObject( hBrush );
         }
         if ( ( isV && stop_y[colors_num-1] < y2 + 1 ) || ( isH && stop_x[colors_num-1] < x2 + 1 ) )
         {
            hPen = CreatePen( PS_SOLID, 1, RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            hPenOld = SelectObject( hDC_mem, hPen );
            hBrush = CreateSolidBrush( RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            SelectObject( hDC_mem, hBrush );
            if ( isV )
               Rectangle( hDC_mem, x1, stop_y[colors_num-1], x2 + 1, y2 + 1 );
            else
               Rectangle( hDC_mem, stop_x[colors_num-1], y1, x2 + 1, y2 + 1 );

            SelectObject( hDC_mem, hPenOld );
            DeleteObject( hPen );
            SelectObject( hDC_mem, GetStockObject( NULL_BRUSH ) );
            DeleteObject( hBrush );
         }

      }
      else if ( type >= 5 && type <= 8 )
      {
         bmp = ( HBITMAP ) CreateCompatibleBitmap( hDC, 2*x2-x1+2, y2+1 );
         hBmpOld = SelectObject( hDC_mem, bmp );

         if ( type == 5 || type == 6 ) is_5_6 = 1;

         for ( i = 1; i < colors_num; i++ )
         {
            section_len = stop_x[i] - stop_x[i-1];
            if ( section_len == 0 ) continue;
               red_step = (double)( red[i] - red[i-1] ) / section_len;
            green_step = (double)( green[i] - green[i-1] ) / section_len;
            blue_step = (double)( blue[i] - blue[i-1] ) / section_len;
            for ( j = stop_x[i-1], k = 0; j <= stop_x[i]; j++, k++ )
            {
               cur_red = floor( red[i-1] + k * red_step + 0.5 );
               cur_green = floor( green[i-1] + k * green_step + 0.5 );
               cur_blue = floor( blue[i-1] + k * blue_step + 0.5 );
               hPen = CreatePen( PS_SOLID, 1, RGB( cur_red, cur_green, cur_blue ) );
               hPenOld = SelectObject( hDC_mem, hPen );

               MoveToEx( hDC_mem, j, (is_5_6)?y1:y2, NULL );
               LineTo( hDC_mem, j + x2-x1+1, (is_5_6)?y2:y1 );
               SetPixel( hDC_mem, j + x2-x1+1, (is_5_6)?y2:y1, RGB( cur_red, cur_green, cur_blue ) );

               SelectObject( hDC_mem, hPenOld );
               DeleteObject( hPen );
            }
         }

         if ( stop_x[0] > 2*x1-x2-1 )
         {
            hPen = CreatePen( PS_SOLID, 1, RGB(red[0], green[0], blue[0]) );
            hPenOld = SelectObject( hDC_mem, hPen );
            hBrush = CreateSolidBrush( RGB(red[0], green[0], blue[0]) );
            SelectObject( hDC_mem, hBrush );

            edge[0].x = x1;
            edge[0].y = ( is_5_6 ) ? y2 : y1;
            edge[1].x = stop_x[0] + x2 - x1;
            edge[1].y = ( is_5_6 ) ? y2 : y1;
            edge[2].x = stop_x[0] - 1;
            edge[2].y = ( is_5_6 ) ? y1 : y2;
            edge[3].x = 2*x1 - x2 - 1;
            edge[3].y = ( is_5_6 ) ? y1 : y2;

            Polygon( hDC_mem, edge, 4 );

            SelectObject( hDC_mem, hPenOld );
            DeleteObject( hPen );
            SelectObject( hDC_mem, GetStockObject( NULL_BRUSH ) );
            DeleteObject( hBrush );
         }
         if ( stop_x[colors_num-1] < x2 )
         {
            hPen = CreatePen( PS_SOLID, 1, RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            hPenOld = SelectObject( hDC_mem, hPen );
            hBrush = CreateSolidBrush( RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            SelectObject( hDC_mem, hBrush );

            edge[0].x = x2;
            edge[0].y = ( is_5_6 ) ? y1 : y2;
            edge[1].x = stop_x[colors_num-1] + 1;
            edge[1].y = ( is_5_6 ) ? y1 : y2;
            edge[2].x = stop_x[colors_num-1] + x2 - x1 + 2;
            edge[2].y = ( is_5_6 ) ? y2 : y1;
            edge[3].x = 2*x2 - x1 + 1;
            edge[3].y = ( is_5_6 ) ? y2 : y1;

            Polygon( hDC_mem, edge, 4 );

            SelectObject( hDC_mem, hPenOld );
            DeleteObject( hPen );
            SelectObject( hDC_mem, GetStockObject( NULL_BRUSH ) );
            DeleteObject( hBrush );
         }

      }
      else if ( type == 9 )
      {
         bmp = ( HBITMAP ) CreateCompatibleBitmap( hDC, x2+1, y2+1 );
         hBmpOld = SelectObject( hDC_mem, bmp );

         if ( stop_x[colors_num-1] < gr_radius )
         {
            hPen = CreatePen( PS_SOLID, 1, RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            hPenOld = SelectObject( hDC_mem, hPen );
            hBrush = CreateSolidBrush( RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            SelectObject( hDC_mem, hBrush );

            Rectangle( hDC_mem, x1, y1, x2+1, y2+1);

            SelectObject( hDC_mem, hPenOld );
            DeleteObject( hPen );
            SelectObject( hDC_mem, GetStockObject( NULL_BRUSH ) );
            DeleteObject( hBrush );
         }

         for ( i = colors_num-1; i > 0; i-- )
         {
            section_len = stop_x[i] - stop_x[i-1];
            if ( section_len == 0 ) continue;
               red_step = (double)( red[i-1] - red[i] ) / section_len;
            green_step = (double)( green[i-1] - green[i] ) / section_len;
            blue_step = (double)( blue[i-1] - blue[i] ) / section_len;
            for ( j = stop_x[i], k = 0; j >= stop_x[i-1]; j--, k++ )
            {
               cur_red = floor( red[i] + k * red_step + 0.5 );
               cur_green = floor( green[i] + k * green_step + 0.5 );
               cur_blue = floor( blue[i] + k * blue_step + 0.5 );
               hPen = CreatePen( PS_SOLID, 1, RGB( cur_red, cur_green, cur_blue ) );
               hPenOld = SelectObject( hDC_mem, hPen );
               hBrush = CreateSolidBrush( RGB( cur_red, cur_green, cur_blue ) );
               SelectObject( hDC_mem, hBrush );

               Ellipse( hDC_mem, x_center - j, y_center - j, x_center + j+1, y_center + j+1 );

               SelectObject( hDC_mem, hPenOld );
               DeleteObject( hPen );
               SelectObject( hDC_mem, GetStockObject( NULL_BRUSH ) );
               DeleteObject( hBrush );
            }
         }

      }

   }

   if( pArrRadius ) {
      user_radiuses_num = ( pArrRadius ) ? hb_arrayLen( pArrRadius ) : 0;
      for ( i = 0; i < 4; i++ )
      {
         radius[i] = ( i < user_radiuses_num ) ? hb_arrayGetNI( pArrRadius, i+1 ) : 0;
         radius[i] = ( radius[i] >= 0 ) ? radius[i] : 0;
      }
   } else
      radius[0] = radius[1] = radius[2] = radius[3] = iRadius;

   center[0].x = x1 + radius[0];
   center[0].y = y1 + radius[0];
   center[1].x = x2 - radius[1];
   center[1].y = y1 + radius[1];
   center[2].x = x2 - radius[2];
   center[2].y = y2 - radius[2];
   center[3].x = x1 + radius[3];
   center[3].y = y2 - radius[3];

   for ( i = 0; i < 4; i++ )
   {
      if ( radius[i] == 0 )
      {
         polygon[ polygon_len ].x = center[i].x;
         polygon[ polygon_len ].y = center[i].y;
         polygon_len++;
      }
      else
      {
         if ( i == 0 || radius[i] != radius[i-1] )
         {
            coords[0].x = 0;
            coords[0].y = -radius[i];
            coords[ SECTORS_NUM ].x = radius[i];
            coords[ SECTORS_NUM ].y = 0;

            angle = -M_PI_2;
            angle_step = M_PI_2 / SECTORS_NUM;
            for( j = 1; j < SECTORS_NUM; j++ )
            {
               angle += angle_step;
               coord_x = cos( angle ) * radius[i];
               coord_y = sin( angle ) * radius[i];

               candidates[0].x = floor( coord_x );
               candidates[0].y = floor( coord_y );
               candidates[1].x = ceil( coord_x );
               candidates[1].y = floor( coord_y );
               candidates[2].x = floor( coord_x );
               candidates[2].y = ceil( coord_y );
               candidates[3].x = ceil( coord_x );
               candidates[3].y = ceil( coord_y );
               min_delta = 1000000;
               for( k = 0; k < 4; k++ )
               {
                  delta = pow( (long double)(candidates[k].x), 2 ) + pow( (long double)(candidates[k].y), 2 ) -
                  pow( (long double)(radius[i]), 2 );
                  if( delta < 0 ) delta = -delta;
                  if ( delta < min_delta )
                  {
                        nearest_coord = k;
                        min_delta = delta;
                  }
               }

               coords[j].x = candidates[ nearest_coord ].x;
               coords[j].y = candidates[ nearest_coord ].y;
            }
         }

         cycle_start = ( i%2 == 0 ) ? SECTORS_NUM : 0;
         cycle_stop = ( i%2 == 0 ) ? -1 : SECTORS_NUM + 1;
         cycle_step = ( i%2 == 0 ) ? -1 : 1;
         for( j = cycle_start; j != cycle_stop; j += cycle_step )
         {
            x = convert[ i ][ 0 ] * coords[ j ].x + center[ i ].x;
            y = convert[ i ][ 1 ] * coords[ j ].y + center[ i ].y;
            if ( polygon_len == 0 || x != polygon[ polygon_len-1 ].x || y != polygon[ polygon_len-1 ].y )
            {
               polygon[ polygon_len ].x = x;
               polygon[ polygon_len ].y = y;
               polygon_len++;
            }
         }
      }
   }

   if( user_colors_num >= 2 )
   {
      hPen = CreatePen( PS_NULL, 1, RGB( 0, 0, 0 ) );
      hBrush = CreatePatternBrush( bmp );
   }
   else
   {
      color = hb_arrayGetNL( pArrColor, 1 );
      hPen = CreatePen( PS_SOLID, 1, color );
      hBrush = CreateSolidBrush( color );
   }

   hPenOld = SelectObject( hDC, (HGDIOBJ) hPen );
   hBrushOld = SelectObject( hDC, hBrush );
   Polygon( hDC, polygon, polygon_len );

   if( user_colors_num >= 2 )
   {
      Rectangle( hDC, x2, y1+radius[1], x2+2, y2-radius[2]+2 );
      Rectangle( hDC, x1+radius[3], y2, x2-radius[2]+2, y2+2 );
   }

   SelectObject( hDC, hBrushOld );
   SelectObject( hDC, hPenOld );
   DeleteObject( hPen );
   DeleteObject( hBrush );

   if( user_colors_num >= 2 )
   {
      if( hDC_mem )
      {
         if( hBmpOld )
            SelectObject( hDC_mem, hBmpOld );
         DeleteDC( hDC_mem );
      }
      if( bmp )
         DeleteObject( bmp );
   }
}

/*=============================================================================
 * HWG_LOADPNG()
 * Placeholder for PNG loading
 *===========================================================================*/
HB_FUNC( HWG_LOADPNG )
{
}

/*=============================================================================
 * HWG_GDIPLUSSAVEPNG()
 * Saves a GpBitmap or converts an HBITMAP to a true PNG file via GDI+.
 * Natively supports 32-bit and 64-bit environments (Clang, MSVC, GCC).
 *===========================================================================*/
HB_FUNC( HWG_GDIPLUSSAVEPNG )
{
      #if defined( __USE_GDIPLUS )
      // CLSID for the native Windows PNG Encoder
      const CLSID pngClsid = { 0x557cf406, 0x1a04, 0x11d3, { 0x9a,0x73,0x00,0x00,0xf8,0x1e,0xf3,0x2e } };
      const char *cFileName = hb_parc( 1 );
      HBITMAP hBitmap = ( HBITMAP ) hb_parptr( 2 );
      GpBitmap* bitmap = NULL;
      wchar_t wcharString[MAX_PATH];

      if( !cFileName || !hBitmap )
      {
            hb_retl( 0 );
            return;
      }

      // Convert the target filename to Unicode (required by GDI+ API)
      MultiByteToWideChar( CP_ACP, 0, cFileName, -1, wcharString, MAX_PATH );

      // Instantiate a GDI+ Bitmap object from the HWGUI HBITMAP handle
      if ( GdipCreateBitmapFromHBITMAP( hBitmap, NULL, &bitmap ) == 0 && bitmap )
      {
            // Save the image file applying real binary PNG compression
            GpStatus status = GdipSaveImageToFile( (GpImage*)bitmap, wcharString, &pngClsid, NULL );
            GdipDisposeImage( bitmap );

            hb_retl( status == 0 );
            return;
      }
      #endif
      hb_retl( 0 );
}

/*=============================================================================
 * Raw bitmap support structures and functions
 *===========================================================================*/

#pragma pack(push,1)

typedef struct{
   uint8_t signature[2];
   uint32_t filesize;
   uint32_t reserved;
   uint32_t fileoffset_to_pixelarray;
} fileheader;

typedef struct{
   uint32_t dibheadersize;
   uint32_t width;
   uint32_t height;
   uint16_t planes;
   uint16_t bitsperpixel;
   uint32_t compression;
   uint32_t imagesize;
   uint32_t ypixelpermeter;
   uint32_t xpixelpermeter;
   uint32_t numcolorspallette;
   uint32_t mostimpcolor;
} bitmapinfoheader;

typedef struct {
   uint8_t b;
   uint8_t g;
   uint8_t r;
   uint8_t a;
} color;

typedef struct
{
   uint8_t b;
   uint8_t g;
   uint8_t r;
   uint8_t i;
}  pixel;

typedef struct {
   fileheader fileheader;
   bitmapinfoheader bitmapinfoheader;
} bitmapheader3x;

typedef struct {
   char Blue;
   char Green;
   char Red;
} Win2xPaletteElement ;

typedef struct {
   uint32_t RedMask;
   uint32_t GreenMask;
   uint32_t BlueMask;
   uint32_t AlphaMask;
   uint32_t CSType;
   uint32_t RedX;
   uint32_t RedY;
   uint32_t RedZ;
   uint32_t GreenX;
   uint32_t GreenY;
   uint32_t GreenZ;
   uint32_t BlueX;
   uint32_t BlueY;
   uint32_t BlueZ;
   uint32_t GammaRed;
   uint32_t GammaGreen;
   uint32_t GammaBlue;
} bitmapinfoheader4x;

typedef struct {
   uint32_t        intent;
   uint32_t        profile_data;
   uint32_t        profile_size;
   uint32_t        reserved;
} bitmapinfoheader5x;

typedef struct {
   bitmapheader3x bmp_header;
   pixel **pixel_data;
   color *palette;
}  BMPImage3x;

typedef struct {
   uint32_t  RedMask;
   uint32_t  GreenMask;
   uint32_t  BlueMask;
} WINNTBITFIELDSMASKS ;

typedef struct {
   pixel **pixel_data;
   color *palette;
}  imagedata;

typedef struct {
   fileheader fileheader;
   bitmapinfoheader bitmapinfoheader;
   bitmapinfoheader4x bitmapinfoheader4x;
} bitmap4x;

typedef struct
{
   bitmap4x bmp_header;
   pixel **pixel_data;
   color *palette;
}  BMPImage4x;

#pragma pack(pop)

static unsigned int cc_null(uint32_t wert)
{
   unsigned int zae ;
   zae = 0;
   if (! wert)
      return 0u;
   while (!(wert & 0x1))
   {
      ++zae;
      wert >>= 1;
   }
   return zae;
}

/*=============================================================================
 * hwg_BMPFileSizeC()
 * Calculates BMP file size
 *===========================================================================*/
uint32_t hwg_BMPFileSizeC(
   int bmp_width,
   int bmp_height,
   int bmp_bit_depth,
   unsigned int colors
)
{
   uint32_t image_size;
   uint32_t pad;
   uint32_t fileoffset_to_pixelarray;
   uint32_t filesize ;

   pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
   image_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad ) * bmp_height;
   fileoffset_to_pixelarray = sizeof (fileheader) + sizeof(bitmapinfoheader) + colors * 4 ;
   filesize = fileoffset_to_pixelarray + image_size ;
   return filesize;
}

/*=============================================================================
 * hwg_BMPNewImageC()
 * Creates a BMP image in memory
 *===========================================================================*/
void * hwg_BMPNewImageC(
   int pbmp_width,
   int pbmp_height,
   int pbmp_bit_depth,
   unsigned int colors,
   uint32_t xpixelpermeter,
   uint32_t ypixelpermeter )
{
   BMPImage3x pbitmap;
   uint32_t image_size;
   uint32_t pad;
   uint32_t fileoffset_to_pixelarray;
   uint32_t filesize ;
   uint32_t max_colors;
   uint32_t i,j;
   void * bmp_locpointer;
   uint8_t * bitmap_buffer;
   uint8_t * buf;
   uint8_t tmp;
   short bit;
   char csig[2];
   uint32_t bmp_width;
   uint32_t bmp_height;
   uint32_t bmp_bit_depth;
   uint8_t mask4[2];

   mask4[0] = 240,
   mask4[1] = 15;

   max_colors = (uint32_t) 1;
   csig[0] = 0x42;
   csig[1] = 0x4d;

   bmp_width = (uint32_t) pbmp_width;
   bmp_height = (uint32_t) pbmp_height;
   bmp_bit_depth = (uint32_t) pbmp_bit_depth;

   memset(&pbitmap, 0, sizeof (BMPImage3x));

   if (bmp_bit_depth != 1 && bmp_bit_depth != 4 && bmp_bit_depth != 8 && bmp_bit_depth != 16 && bmp_bit_depth != 24 )
      return NULL;

   if ( bmp_width < 1 || bmp_height < 1 )
      return NULL;

   for (i = 0; i < bmp_bit_depth; ++i)
      max_colors *= 2;

   if (colors > max_colors)
      return NULL;

   pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
   image_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad ) * bmp_height;
   fileoffset_to_pixelarray = sizeof (fileheader) + sizeof(bitmapinfoheader) + colors * 4 ;
   filesize = fileoffset_to_pixelarray + image_size ;

   /* Free any image left over from a previous call - HWG_BMPNEWIMAGE()
      overwrites this global pointer unconditionally, so without this a
      caller that forgets to call HWG_BMPDESTROY() between two images
      silently leaks the previous buffer. */
   if ( bmp_fileimg )
   {
      free( bmp_fileimg );
      bmp_fileimg = NULL;
   }

   bmp_fileimg = malloc(filesize);
   if (! bmp_fileimg)
      return NULL;

   memcpy( &pbitmap.bmp_header.fileheader.signature,csig,2);
   pbitmap.bmp_header.fileheader.filesize = filesize;
   pbitmap.bmp_header.fileheader.reserved = 0;
   pbitmap.bmp_header.fileheader.fileoffset_to_pixelarray = fileoffset_to_pixelarray;

   pbitmap.bmp_header.bitmapinfoheader.dibheadersize = (uint32_t) sizeof(bitmapinfoheader);
   pbitmap.bmp_header.bitmapinfoheader.width =  bmp_width;
   pbitmap.bmp_header.bitmapinfoheader.height = bmp_height;
   pbitmap.bmp_header.bitmapinfoheader.planes = (uint16_t) _planes;
   pbitmap.bmp_header.bitmapinfoheader.bitsperpixel = (uint16_t) bmp_bit_depth;
   pbitmap.bmp_header.bitmapinfoheader.compression = _compression;
   pbitmap.bmp_header.bitmapinfoheader.imagesize = (uint32_t) image_size;
   pbitmap.bmp_header.bitmapinfoheader.ypixelpermeter = ypixelpermeter ;
   pbitmap.bmp_header.bitmapinfoheader.xpixelpermeter = xpixelpermeter ;
   pbitmap.bmp_header.bitmapinfoheader.numcolorspallette = colors;
   pbitmap.bmp_header.bitmapinfoheader.mostimpcolor = colors;

   pbitmap.pixel_data = (pixel**) malloc(bmp_height * sizeof(pixel*) );
   if ( ! pbitmap.pixel_data)
   {
      free(bmp_fileimg);
      return NULL;
   }
   for (i = 0; i < bmp_height; ++i)
   {
      pbitmap.pixel_data[i] = (pixel*) calloc(bmp_width, sizeof (pixel));
      if (! pbitmap.pixel_data[i])
      {
         while (i > 0)
            free( pbitmap.pixel_data[--i]);
         free(pbitmap.pixel_data);
         free(bmp_fileimg);
         return NULL;
      }
   }

   pbitmap.palette = (color*) calloc(colors, sizeof (color));
   if (! pbitmap.palette && colors > 0)
   {
      for (i = 0; i < bmp_height; ++i)
         free( pbitmap.pixel_data[i]);
      free(pbitmap.pixel_data);
      free(bmp_fileimg);
      return NULL;
   }

   memcpy(bmp_fileimg, &pbitmap.bmp_header, sizeof(bitmapheader3x));

   bmp_locpointer = (void*) ( ((unsigned char*)bmp_fileimg) + fileoffset_to_pixelarray );

   bitmap_buffer = (uint8_t *) calloc(1, image_size);
   if (! bitmap_buffer)
   {
      for (i = 0; i < bmp_height; ++i)
         free( pbitmap.pixel_data[i]);
      free(pbitmap.pixel_data);
      free(pbitmap.palette);
      free(bmp_fileimg);
      return NULL;
   }
   buf = bitmap_buffer;

   switch (bmp_bit_depth)
   {
      case 1:
         for (i = 0; i < bmp_height; ++i)
         {
            j = 0;
            while (j < bmp_width)
            {
               tmp = 0;
               for (bit = 7; bit >= 0 && j < bmp_width; --bit)
               {
                  tmp |= (pbitmap.pixel_data[i][j].i == 0 ? 0u : 1u) << bit;
                  ++j;
               }
               *buf++ = tmp;
            }
            buf += pad;
         }
         break;

      case 4:
         for (i = 0; i < bmp_height; ++i)
         {
            for (j = 0; j < bmp_width; j += 2)
            {
               tmp = 0;
               tmp |= pbitmap.pixel_data[i][j].i << 4;
               if (j + 1 < bmp_width)
                  tmp |= pbitmap.pixel_data[i][j + 1].i & mask4[LO_NIBBLE];
               *buf++ = tmp;
            }
            buf += pad;
         }
         break;

      case 8:
         for (i = 0; i < bmp_height; ++i)
         {
            for (j = 0; j < bmp_width; ++j)
               *buf++ = pbitmap.pixel_data[i][j].i;
            buf += pad;
         }
         break;

      case 16:
         for (i = 0; i < bmp_height; ++i)
         {
            for (j = 0; j < bmp_width; ++j)
            {
               uint16_t *px = (uint16_t*) buf;
               *px =
               (pbitmap.pixel_data[i][j].b << cc_null(pbitmap.palette->b)) +
               (pbitmap.pixel_data[i][j].g << cc_null(pbitmap.palette->g)) +
               (pbitmap.pixel_data[i][j].r << cc_null(pbitmap.palette->r));
               buf += 2;
            }
            buf += pad;
         }
         break;

      case 24:
         for (i = 0; i < bmp_height; ++i)
         {
            for (j = 0; j < bmp_width; ++j)
            {
               *buf++ = pbitmap.pixel_data[i][j].b;
               *buf++ = pbitmap.pixel_data[i][j].g;
               *buf++ = pbitmap.pixel_data[i][j].r;
            }
            buf += pad;
         }
         break;
   }

   memcpy(bmp_locpointer, bitmap_buffer, image_size );
   free(bitmap_buffer);

   for (i = 0; i < bmp_height; ++i)
      free( pbitmap.pixel_data[i]);
   free(pbitmap.pixel_data);
   free(pbitmap.palette);

   return bmp_fileimg;
}

/*=============================================================================
 * hwg_BMPCalcOffsPixArrC()
 * Calculates offset to pixel array
 *===========================================================================*/
uint32_t hwg_BMPCalcOffsPixArrC(unsigned int colors)
{
   return (uint32_t)(sizeof(fileheader) + sizeof(bitmapinfoheader) + (colors * 4));
}

/*=============================================================================
 * hwg_BMPCalcOffsPalC()
 * Calculates offset to palette data
 *===========================================================================*/
uint32_t hwg_BMPCalcOffsPalC(int bmp_height)
{
   return (uint32_t)(sizeof(bitmapheader3x) + (bmp_height * sizeof(pixel*)));
}

/*=============================================================================
 * HWG_BMPNEWIMAGE()
 * Creates a new BMP image (Harbour interface)
 *===========================================================================*/
HB_FUNC( HWG_BMPNEWIMAGE )
{
   int bmp_width = hb_parni(1);
   int bmp_height = hb_parni(2);
   int bmp_bit_depth = hb_parni(3);
   unsigned int colors = hb_parni(4);
   uint32_t xpixelpermeter = hb_parnl(5);
   uint32_t ypixelpermeter = hb_parnl(6);
   void *rci;
   uint32_t filesize;

   rci = hwg_BMPNewImageC(bmp_width, bmp_height, bmp_bit_depth, colors, xpixelpermeter, ypixelpermeter);

   if ( !rci )
   {
      hb_retc("Error");
      return;
   }

   filesize = hwg_BMPFileSizeC(bmp_width, bmp_height, bmp_bit_depth, colors);

   if ( filesize > BMPFILEIMG_MAXSZ || filesize == 0 )
   {
      hb_retc("Error");
      return;
   }

   char *rcbuff = (char *) hb_xgrab(filesize);
   if ( rcbuff == NULL )
   {
      hb_retc("Error");
      return;
   }

   memcpy(rcbuff, rci, filesize);
   hb_retclen_buffer(rcbuff, filesize);
}

/*=============================================================================
 * HWG_BMPDESTROY()
 * Destroys a BMP image
 *===========================================================================*/
HB_FUNC( HWG_BMPDESTROY )
{
   if ( bmp_fileimg )
   {
      free(bmp_fileimg);
      bmp_fileimg = NULL;
   }
}

/*=============================================================================
 * HWG_BMPFILESIZE()
 * Calculates BMP file size
 *===========================================================================*/
HB_FUNC( HWG_BMPFILESIZE )
{
   uint32_t image_size;
   uint32_t pad;
   uint32_t fileoffset_to_pixelarray;
   uint32_t filesize;

   int bmp_width = hb_parni(1);
   int bmp_height = hb_parni(2);
   int bmp_bit_depth = hb_parni(3);
   unsigned int colors = hb_parni(4);

   pad = (4 - (bmp_bit_depth * bmp_width + 7) / 8 % 4) % 4;
   image_size = ((bmp_bit_depth * bmp_width + 7) / 8 + pad) * bmp_height;

   fileoffset_to_pixelarray = (uint32_t)(sizeof(fileheader) + sizeof(bitmapinfoheader) + (colors * 4));
   filesize = fileoffset_to_pixelarray + image_size;

   hb_retnl(filesize);
}

/*=============================================================================
 * HWG_BMPSZ3X()
 * Returns size of BMPImage3x structure
 *===========================================================================*/
HB_FUNC( HWG_BMPSZ3X )
{
   hb_retnl((uint32_t)sizeof(BMPImage3x));
}

/*=============================================================================
 * HWG_BMPMAXFILESZ()
 * Returns maximum BMP file size
 *===========================================================================*/
HB_FUNC( HWG_BMPMAXFILESZ )
{
   hb_retnl(BMPFILEIMG_MAXSZ);
}

/*=============================================================================
 * HWG_BMPCALCOFFSPIXARR()
 * Calculates offset to pixel array
 *===========================================================================*/
HB_FUNC( HWG_BMPCALCOFFSPIXARR )
{
   hb_retnl(hwg_BMPCalcOffsPixArrC(hb_parni(1)));
}

/*=============================================================================
 * HWG_BMPCALCOFFSPAL()
 * Calculates offset to palette data
 *===========================================================================*/
HB_FUNC( HWG_BMPCALCOFFSPAL )
{
   hb_retnl(hwg_BMPCalcOffsPalC(hb_parni(1)));
}

/*=============================================================================
 * HWG_BMPIMAGESIZE()
 * Calculates image size
 *===========================================================================*/
HB_FUNC( HWG_BMPIMAGESIZE )
{
   int bmp_width = hb_parni(1);
   int bmp_height = hb_parni(2);
   int bmp_bit_depth = hb_parni(3);
   uint32_t pad = (4 - (bmp_bit_depth * bmp_width + 7) / 8 % 4) % 4;
   uint32_t image_size = ((bmp_bit_depth * bmp_width + 7) / 8 + pad) * bmp_height;

   hb_retnl(image_size);
}

/*=============================================================================
 * HWG_BMPLINESIZE()
 * Calculates line size including padding
 *===========================================================================*/
HB_FUNC( HWG_BMPLINESIZE )
{
   int bmp_width = hb_parni(1);
   int bmp_bit_depth = hb_parni(2);
   uint32_t pad = (4 - (bmp_bit_depth * bmp_width + 7) / 8 % 4) % 4;
   uint32_t line_size = ((bmp_bit_depth * bmp_width + 7) / 8 + pad);

   hb_retnl(line_size);
}

/*=============================================================================
 * HWG_QRCODEZOOM_C()
 * Zooms a QR code image
 *===========================================================================*/
HB_FUNC( HWG_QRCODEZOOM_C )
{
   int i, j, leofq;
   int nzoom = ( HB_ISNIL( 3 ) ? 1 : hb_parni( 3 ) );
   int nlen = hb_parni( 2 );
   int cptr = 0, lptr = 0;
   const char *hString = hb_parc( 1 );

   if ( nzoom < 1 )
   {
      hb_retclen(hString, nlen);
      return;
   }

   char *cqrcode = (char *) hb_xgrab(16385);
   char *cout = (char *) hb_xgrab(16385);
   char *cLine = (char *) hb_xgrab(8192);

   if ( !cqrcode || !cout || !cLine )
   {
      if (cqrcode) hb_xfree(cqrcode);
      if (cout) hb_xfree(cout);
      if (cLine) hb_xfree(cLine);
      hb_retc("");
      return;
   }

   memset(cout, 0x00, 16385);
   memset(cLine, 0x00, 8192);
   memcpy(cqrcode, hString, (nlen > 16384) ? 16384 : nlen);

   leofq = 0;
   for (i = 0; i < nlen; i++)
   {
      if ( leofq == 0 )
      {
         if ( cqrcode[i] == 10 )
         {
            if ( !(cqrcode[i + 1] == 32) )
               leofq = 1;
            for (j = 1; j <= nzoom; j++)
            {
               if (cptr + lptr + 2 >= 16384) break;
               memcpy(&cout[cptr], cLine, lptr);
               cout[cptr + lptr + 1] = 10;
               cptr = cptr + lptr + 2;
            }
            lptr = 0;
            memset(cLine, 0x00, 8192);
         }
         else
         {
            for (j = 1; j <= nzoom; j++)
            {
               if (lptr >= 8190) break;
               cLine[lptr] = cqrcode[i];
               lptr++;
            }
            cLine[lptr] = 10;
         }
      }
   }

   if (lptr > 0 && cptr + lptr + 2 < 16384)
   {
      memcpy(&cout[cptr], cLine, lptr);
      cout[cptr + lptr + 1] = 10;
      cptr = cptr + lptr + 2;
   }

   if (cptr + 2 < 16384)
   {
      cout[cptr + 1] = 10;
      cptr += 2;
   }

   hb_retclen(cout, cptr);

   hb_xfree(cqrcode);
   hb_xfree(cout);
   hb_xfree(cLine);
}

/* ================== EOF of draw.c ========================== */
