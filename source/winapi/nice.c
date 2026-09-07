/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Nice button with gradient effects
 *
 * Copyright 2003 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
*/

#include "hwingui.h"
#include <commctrl.h>

#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"

#include "incomp_pointer.h"

/* REMOVED: Obsolete compiler support - GRADIENT_RECT and TRIVERTEX
 * are already defined in modern Windows headers (wingdi.h)
 * #if !defined(__WATCOMC__) && !defined(__MINGW32__) && !defined(__MINGW64__)
 * typedef struct _GRADIENT_RECT { ... } GRADIENT_RECT, ...
 * #endif
 * #if defined(__DMC__)
 * typedef struct _TRIVERTEX { ... } TRIVERTEX, ...
 * #endif
 */

typedef int ( _stdcall * GRADIENTFILL ) ( HDC, PTRIVERTEX, int, PVOID, int, int );
LRESULT CALLBACK NiceButtProc( HWND, UINT, WPARAM, LPARAM );

static GRADIENTFILL s_pGradientfill = NULL;

/*=============================================================================
 * Draw_Gradient()
 * Draws a gradient with a single color fading to white
 *===========================================================================*/
void Draw_Gradient( HDC hdc, int x, int y, int w, int h, int r, int g, int b )
{
   TRIVERTEX Vert[2];
   GRADIENT_RECT Rect;
   HB_SYMBOL_UNUSED( x );
   HB_SYMBOL_UNUSED( y );

   if( !s_pGradientfill )
      return;

   Vert[0].x = 0;
   Vert[0].y = 0;
   Vert[0].Red = 65535 - ( 65535 - ( r * 256 ) );
   Vert[0].Green = 65535 - ( 65535 - ( g * 256 ) );
   Vert[0].Blue = 65535 - ( 65535 - ( b * 256 ) );
   Vert[0].Alpha = 0;

   Vert[1].x = w;
   Vert[1].y = h / 2;
   Vert[1].Red = 65535 - ( 65535 - ( 255 * 256 ) );
   Vert[1].Green = 65535 - ( 65535 - ( 255 * 256 ) );
   Vert[1].Blue = 65535 - ( 65535 - ( 255 * 256 ) );
   Vert[1].Alpha = 0;

   Rect.UpperLeft = 0;
   Rect.LowerRight = 1;

   s_pGradientfill( hdc, Vert, 2, &Rect, 1, GRADIENT_FILL_RECT_V );

   Vert[0].x = 0;
   Vert[0].y = h / 2;
   Vert[0].Red = 65535 - ( 65535 - ( 255 * 256 ) );
   Vert[0].Green = 65535 - ( 65535 - ( 255 * 256 ) );
   Vert[0].Blue = 65535 - ( 65535 - ( 255 * 256 ) );
   Vert[0].Alpha = 0;

   Vert[1].x = w;
   Vert[1].y = h;
   Vert[1].Red = 65535 - ( 65535 - ( r * 256 ) );
   Vert[1].Green = 65535 - ( 65535 - ( g * 256 ) );
   Vert[1].Blue = 65535 - ( 65535 - ( b * 256 ) );
   Vert[1].Alpha = 0;

   Rect.UpperLeft = 0;
   Rect.LowerRight = 1;

   s_pGradientfill( hdc, Vert, 2, &Rect, 1, GRADIENT_FILL_RECT_V );
}

/*=============================================================================
 * Gradient()
 * Draws a gradient between two colors
 *===========================================================================*/
void Gradient( HDC hdc, int x, int y, int w, int h, int color1, int color2, int nmode )
{
   TRIVERTEX Vert[2];
   GRADIENT_RECT Rect;
   int r, g, b, r2, g2, b2;
   HB_SYMBOL_UNUSED( x );
   HB_SYMBOL_UNUSED( y );

   if( !s_pGradientfill )
      return;

   r = color1 % 256;
   g = color1 / 256 % 256;
   b = color1 / 256 / 256 % 256;
   r2 = color2 % 256;
   g2 = color2 / 256 % 256;
   b2 = color2 / 256 / 256 % 256;

   Vert[0].x = 0;
   Vert[0].y = 0;
   Vert[0].Red = 65535 - ( 65535 - ( r * 256 ) );
   Vert[0].Green = 65535 - ( 65535 - ( g * 256 ) );
   Vert[0].Blue = 65535 - ( 65535 - ( b * 256 ) );
   Vert[0].Alpha = 0;

   Vert[1].x = w;
   Vert[1].y = h;
   Vert[1].Red = 65535 - ( 65535 - ( r2 * 256 ) );
   Vert[1].Green = 65535 - ( 65535 - ( g2 * 256 ) );
   Vert[1].Blue = 65535 - ( 65535 - ( b2 * 256 ) );
   Vert[1].Alpha = 0;

   Rect.UpperLeft = 0;
   Rect.LowerRight = 1;

   s_pGradientfill( hdc, Vert, 2, &Rect, 1, nmode );
}

/*=============================================================================
 * NiceButtProc()
 * Window procedure for nice buttons
 *===========================================================================*/
LRESULT CALLBACK NiceButtProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_DYNS pSymTest;
   if( ( pSymTest = hb_dynsymFind( "HWG_NICEBUTTPROC" ) ) != NULL )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSymTest ) );
      hb_vmPushNil();
      HB_PUSHITEM( hWnd );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
      hb_vmPushLong( ( LONG ) lParam );
      hb_vmDo( 4 );
      res = hb_parl( -1 );
      if( res )
         return 0;
      else
         return ( DefWindowProc( hWnd, message, wParam, lParam ) );
   }
   else
      return ( DefWindowProc( hWnd, message, wParam, lParam ) );
}

/*=============================================================================
 * HWG_CREATEROUNDRECTRGN()
 * Creates a rounded rectangle region
 *===========================================================================*/
HB_FUNC( HWG_CREATEROUNDRECTRGN )
{
   HRGN Res = CreateRoundRectRgn( hb_parni( 1 ), hb_parni( 2 ), hb_parni( 3 ),
         hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ) );
   HB_RETHANDLE( Res );
}

/*=============================================================================
 * HWG_SETWINDOWRGN()
 * Sets window region
 *===========================================================================*/
HB_FUNC( HWG_SETWINDOWRGN )
{
   hb_retni( SetWindowRgn( ( HWND ) HB_PARHANDLE( 1 ), ( HRGN ) hb_parptr( 2 ),
               hb_parl( 3 ) ) );
}

/*=============================================================================
 * HWG_REGNICE()
 * Registers the nice button window class
 *===========================================================================*/
HB_FUNC( HWG_REGNICE )
{
   static LPCTSTR s_szAppName = TEXT( "NICEBUTT" );
   static BOOL s_bRegistered = 0;

   /* Load GradientFill from msimg32.dll */
   if( s_pGradientfill == NULL )
   {
      HMODULE hMsImg = LoadLibrary( TEXT( "MSIMG32.DLL" ) );
      if( hMsImg )
      {
         s_pGradientfill = ( GRADIENTFILL ) GetProcAddress( hMsImg, "GradientFill" );
      }
   }

   if( !s_bRegistered )
   {
      WNDCLASS wc;

      wc.style = CS_HREDRAW | CS_VREDRAW | CS_GLOBALCLASS;
      wc.hInstance = GetModuleHandle( 0 );
      wc.hbrBackground = ( HBRUSH ) ( COLOR_BTNFACE + 1 );
      wc.lpszClassName = s_szAppName;
      wc.lpfnWndProc = NiceButtProc;
      wc.cbClsExtra = 0;
      wc.cbWndExtra = 0;
      wc.hIcon = NULL;
      wc.hCursor = NULL;
      wc.lpszMenuName = 0;

      RegisterClass( &wc );
      s_bRegistered = 1;
   }
}

/*=============================================================================
 * HWG_CREATENICEBTN()
 * Creates a nice button control
 *===========================================================================*/
HB_FUNC( HWG_CREATENICEBTN )
{
   HWND hWndPanel;
   ULONG ulStyle =
         HB_ISNUM( 3 ) ? hb_parnl( 3 ) : WS_CLIPCHILDREN | WS_CLIPSIBLINGS;
   void *hTitle;

   hWndPanel = CreateWindowEx( hb_parni( 8 ), TEXT( "NICEBUTT" ),
         HB_PARSTR( 9, &hTitle, NULL ),
         WS_CHILD | WS_VISIBLE | ulStyle,
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )(UINT_PTR) hb_parni( 2 ),
         GetModuleHandle( NULL ), NULL );
   hb_strfree( hTitle );

   HB_RETHANDLE( hWndPanel );
}

/*=============================================================================
 * HWG_ISMOUSEOVER()
 * Checks if the mouse is over a window
 *===========================================================================*/
HB_FUNC( HWG_ISMOUSEOVER )
{
   RECT Rect;
   POINT Pt;
   GetWindowRect( ( HWND ) HB_PARHANDLE( 1 ), &Rect );
   GetCursorPos( &Pt );
   hb_retl( PtInRect( &Rect, Pt ) );
}

/*=============================================================================
 * HWG_DRAW_GRADIENT()
 * Draws a gradient using Draw_Gradient()
 *===========================================================================*/
HB_FUNC( HWG_DRAW_GRADIENT )
{
   Draw_Gradient( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ),
         hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ), hb_parni( 7 ),
         hb_parni( 8 ) );
}

/*=============================================================================
 * HWG_GRADIENT()
 * Draws a gradient between two colors
 *===========================================================================*/
HB_FUNC( HWG_GRADIENT )
{
   if( s_pGradientfill == NULL )
   {
      HMODULE hMsImg = LoadLibrary( TEXT( "MSIMG32.DLL" ) );
      if( hMsImg )
         s_pGradientfill = ( GRADIENTFILL ) GetProcAddress( hMsImg, "GradientFill" );
   }

   Gradient( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ),
         hb_parni( 4 ), hb_parni( 5 ),
         ( hb_pcount(  ) > 5 && !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : 16777215,
         ( hb_pcount(  ) > 6 && !HB_ISNIL( 7 ) ) ? hb_parni( 7 ) : 16777215,
         ( hb_pcount(  ) > 7 && !HB_ISNIL( 8 ) ) ? hb_parni( 8 ) : 0 );
}

/*=============================================================================
 * HWG_MAKELONG()
 * Creates a LONG from two WORDs
 *===========================================================================*/
HB_FUNC( HWG_MAKELONG )
{
   hb_retnl( ( LONG ) MAKELONG( ( WORD ) hb_parnl( 1 ),
               ( WORD ) hb_parnl( 2 ) ) );
}

/*=============================================================================
 * HWG_GETWINDOWLONG()
 * Gets window long (using GetWindowLongPtr for 64-bit safety)
 *===========================================================================*/
HB_FUNC( HWG_GETWINDOWLONG )
{
   /* FIXED: Use GetWindowLongPtr for 64-bit compatibility */
   hb_retnint( ( HB_MAXINT ) GetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) ) );
}

/*=============================================================================
 * HWG_SETBKMODE()
 * Sets background mode
 *===========================================================================*/
HB_FUNC( HWG_SETBKMODE )
{
   hb_retni( SetBkMode( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ) ) );
}

/* =========================== EOF of nice.c ========================== */