/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Theme related functions
 *
 * Copyright 2007 Luiz Rafael Culik Guimaraes <luiz at xharbour.com.br >
 * www - http://sites.uol.com.br/culikr/
*/

#include "hwingui.h"
#include <commctrl.h>
#include <uxtheme.h>
#if defined(__DMC__)
#include "missing.h"
#endif
#include "hbapiitm.h"
#include "hbapicdp.h"

/* Tickets #74,36,41 */
#include "incomp_pointer.h"

#if defined( _MSC_VER )
   /* Link against uxtheme.lib directly - Windows 2000 support (which
      predates UxTheme) was dropped, so the dynamic LoadLibrary() +
      GetProcAddress() indirection this file used to need for every
      single theme API is gone; see hb_OpenThemeData() and friends
      below, which now call the real Win32 functions directly. GCC/
      Clang/MinGW builds need "-luxtheme" added to their link command
      instead - #pragma comment(lib) is a MSVC-only extension. */
   #pragma comment( lib, "uxtheme.lib" )
#endif

//#include <tmschema.h>
#ifndef BS_TYPEMASK
#define BS_TYPEMASK SS_TYPEMASK
#endif
#ifndef BP_PUSHBUTTON
#define BP_PUSHBUTTON 1
#define PBS_NORMAL    1
#define PBS_HOT       2
#define PBS_PRESSED   3
#define PBS_DISABLED  4
#define PBS_DEFAULTED 5
#define TMT_CONTENTMARGINS 3602
#define ODS_NOFOCUSRECT     0x0200
#endif

#ifndef CDRF_DODEFAULT
#define CDRF_DODEFAULT  0x00000000
#define CDRF_NEWFONT  0x00000002
#define CDRF_SKIPDEFAULT  0x00000004
#define CDRF_NOTIFYPOSTPAINT  0x00000010
#define CDRF_NOTIFYITEMDRAW  0x00000020
#define CDRF_NOTIFYSUBITEMDRAW  0x00000020
#define CDRF_NOTIFYPOSTERASE  0x00000040
#define CDDS_PREPAINT  0x00000001
#define CDDS_POSTPAINT  0x00000002
#define CDDS_PREERASE  0x00000003
#define CDDS_POSTERASE  0x00000004
#define CDDS_ITEM  0x00010000
#define CDDS_ITEMPREPAINT  (CDDS_ITEM|CDDS_PREPAINT)
#define CDDS_ITEMPOSTPAINT  (CDDS_ITEM|CDDS_POSTPAINT)
#define CDDS_ITEMPREERASE  (CDDS_ITEM|CDDS_PREERASE)
#define CDDS_ITEMPOSTERASE  (CDDS_ITEM|CDDS_POSTERASE)
#define CDDS_SUBITEM  0x00020000
#define CDIS_SELECTED  0x0001
#define CDIS_GRAYED  0x0002
#define CDIS_DISABLED  0x0004
#define CDIS_CHECKED  0x0008
#define CDIS_FOCUS  0x0010
#define CDIS_DEFAULT  0x0020
#define CDIS_HOT  0x0040
#define CDIS_MARKED  0x0080
#define CDIS_INDETERMINATE  0x0100
#endif

#define ST_ALIGN_HORIZ       0  // Icon/bitmap on the left, text on the right
#define ST_ALIGN_VERT        1  // Icon/bitmap on the top, text on the bottom
#define ST_ALIGN_HORIZ_RIGHT 2  // Icon/bitmap on the right, text on the left
#define ST_ALIGN_OVERLAP     3  // Icon/bitmap on the same space as text
#define STATE_GWL_OFFSET  0
#define HFONT_GWL_OFFSET  (sizeof(LONG))
#define HIMAGE_GWL_OFFSET (HFONT_GWL_OFFSET+sizeof(HFONT))
#define NB_EXTRA_BYTES    (HIMAGE_GWL_OFFSET+sizeof(HANDLE))
#define BUTTON_UNCHECKED       0x00
#define BUTTON_CHECKED         0x01
#define BUTTON_3STATE          0x02
#define BUTTON_HIGHLIGHTED     0x04
#define BUTTON_HASFOCUS        0x08
#define BUTTON_NSTATES         0x0F
#define BUTTON_BTNPRESSED      0x40
#define BUTTON_UNKNOWN2        0x20
#define BUTTON_UNKNOWN3        0x10

BOOL Themed = FALSE;
BOOL ThemeLibLoaded = FALSE;

void draw_bitmap( HDC hDC, const RECT * Rect, DWORD style, HWND m_hWnd );
void draw_icon( HDC hDC, const RECT * Rect, DWORD style, HWND m_hWnd );

static int image_top( int cy, const RECT * Rect, DWORD style );
static int image_left( int cx, const RECT * Rect, DWORD style );

HTHEME hb_OpenThemeData( HWND hwnd, LPCWSTR pszClassList )
{
   return OpenThemeData( hwnd, pszClassList );
}

HRESULT hb_CloseThemeData( HTHEME hTheme )
{
   return CloseThemeData( hTheme );
}

HRESULT hb_DrawThemeBackground( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pRect, const RECT * pClipRect )
{
   return DrawThemeBackground( hTheme, hdc, iPartId, iStateId, pRect, pClipRect );
}

HRESULT hb_DrawThemeText( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, LPCWSTR pszText, int iCharCount, DWORD dwTextFlags,
      DWORD dwTextFlags2, const RECT * pRect )
{
   return DrawThemeText( hTheme, hdc, iPartId, iStateId, pszText, iCharCount, dwTextFlags, dwTextFlags2, pRect );
}

HRESULT hb_GetThemeBackgroundContentRect( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pBoundingRect,
      RECT * pContentRect )
{
   return GetThemeBackgroundContentRect( hTheme, hdc, iPartId, iStateId, pBoundingRect, pContentRect );
}

HRESULT hb_GetThemeBackgroundExtent( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pContentRect,
      RECT * pExtentRect )
{
   return GetThemeBackgroundExtent( hTheme, hdc, iPartId, iStateId, pContentRect, pExtentRect );
}

HRESULT hb_GetThemePartSize( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, RECT * pRect, int eSize, SIZE * psz )
{
   return GetThemePartSize( hTheme, hdc, iPartId, iStateId, pRect, eSize, psz );
}

HRESULT hb_GetThemeTextExtent( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, LPCWSTR pszText, int iCharCount,
      DWORD dwTextFlags, const RECT * pBoundingRect, RECT * pExtentRect )
{
   return GetThemeTextExtent( hTheme, hdc, iPartId, iStateId, pszText, iCharCount, dwTextFlags, pBoundingRect, pExtentRect );
}

HRESULT hb_GetThemeTextMetrics( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, TEXTMETRIC * ptm )
{
   return GetThemeTextMetrics( hTheme, hdc, iPartId, iStateId, ptm );
}

HRESULT hb_GetThemeBackgroundRegion( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pRect, HRGN * pRegion )
{
   return GetThemeBackgroundRegion( hTheme, hdc, iPartId, iStateId, pRect, pRegion );
}

HRESULT hb_HitTestThemeBackground( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, DWORD dwOptions, const RECT * pRect, HRGN hrgn,
      POINT ptTest, WORD * pwHitTestCode )
{
   return HitTestThemeBackground( hTheme, hdc, iPartId, iStateId, dwOptions, pRect, hrgn, ptTest, pwHitTestCode );
}

HRESULT hb_DrawThemeEdge( HTHEME hTheme, HDC hdc, int iPartId, int iStateId,
      const RECT * pDestRect, UINT uEdge, UINT uFlags, RECT * pContentRect )
{
   return DrawThemeEdge( hTheme, hdc, iPartId, iStateId, pDestRect, uEdge, uFlags, pContentRect );
}

HRESULT hb_DrawThemeIcon( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, const RECT * pRect, HIMAGELIST himl, int iImageIndex )
{
   return DrawThemeIcon( hTheme, hdc, iPartId, iStateId, pRect, himl, iImageIndex );
}

BOOL hb_IsThemePartDefined( HTHEME hTheme, int iPartId, int iStateId )
{
   return IsThemePartDefined( hTheme, iPartId, iStateId );
}

BOOL hb_IsThemeBackgroundPartiallyTransparent( HTHEME hTheme,
      int iPartId, int iStateId )
{
   return IsThemeBackgroundPartiallyTransparent( hTheme, iPartId, iStateId );
}

HRESULT hb_GetThemeColor( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, COLORREF * pColor )
{
   return GetThemeColor( hTheme, iPartId, iStateId, iPropId, pColor );
}

HRESULT hb_GetThemeMetric( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, int iPropId, int *piVal )
{
   return GetThemeMetric( hTheme, hdc, iPartId, iStateId, iPropId, piVal );
}

HRESULT hb_GetThemeString( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, LPWSTR pszBuff, int cchMaxBuffChars )
{
   return GetThemeString( hTheme, iPartId, iStateId, iPropId, pszBuff, cchMaxBuffChars );
}

HRESULT hb_GetThemeBool( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, BOOL * pfVal )
{
   return GetThemeBool( hTheme, iPartId, iStateId, iPropId, pfVal );
}

HRESULT hb_GetThemeInt( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, int *piVal )
{
   return GetThemeInt( hTheme, iPartId, iStateId, iPropId, piVal );
}

HRESULT hb_GetThemeEnumValue( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, int *piVal )
{
   return GetThemeEnumValue( hTheme, iPartId, iStateId, iPropId, piVal );
}

HRESULT hb_GetThemePosition( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, POINT * pPoint )
{
   return GetThemePosition( hTheme, iPartId, iStateId, iPropId, pPoint );
}

HRESULT hb_GetThemeFont( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, int iPropId, LOGFONT * pFont )
{
   return GetThemeFont( hTheme, hdc, iPartId, iStateId, iPropId, pFont );
}

HRESULT hb_GetThemeRect( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, RECT * pRect )
{
   return GetThemeRect( hTheme, iPartId, iStateId, iPropId, pRect );
}

HRESULT hb_GetThemeMargins( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, int iPropId, RECT * prc, MARGINS * pMargins )
{
   return GetThemeMargins( hTheme, hdc, iPartId, iStateId, iPropId, prc, pMargins );
}

HRESULT hb_GetThemeIntList( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, INTLIST * pIntList )
{
   return GetThemeIntList( hTheme, iPartId, iStateId, iPropId, pIntList );
}

HRESULT hb_GetThemePropertyOrigin( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, int *pOrigin )
{
   return GetThemePropertyOrigin( hTheme, iPartId, iStateId, iPropId, pOrigin );
}

HRESULT hb_SetWindowTheme( HWND hwnd, LPCWSTR pszSubAppName,
      LPCWSTR pszSubIdList )
{
   return SetWindowTheme( hwnd, pszSubAppName, pszSubIdList );
}

HRESULT hb_GetThemeFilename( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, LPWSTR pszThemeFileName,
      int cchMaxBuffChars )
{
   return GetThemeFilename( hTheme, iPartId, iStateId, iPropId, pszThemeFileName, cchMaxBuffChars );
}

COLORREF hb_GetThemeSysColor( HTHEME hTheme, int iColorId )
{
   return GetThemeSysColor( hTheme, iColorId );
}

HBRUSH hb_GetThemeSysColorBrush( HTHEME hTheme, int iColorId )
{
   return GetThemeSysColorBrush( hTheme, iColorId );
}

BOOL hb_GetThemeSysBool( HTHEME hTheme, int iBoolId )
{
   return GetThemeSysBool( hTheme, iBoolId );
}

int hb_GetThemeSysSize( HTHEME hTheme, int iSizeId )
{
   return GetThemeSysSize( hTheme, iSizeId );
}

HRESULT hb_GetThemeSysFont( HTHEME hTheme, int iFontId, LOGFONT * plf )
{
   return GetThemeSysFont( hTheme, iFontId, plf );
}

HRESULT hb_GetThemeSysString( HTHEME hTheme, int iStringId,
      LPWSTR pszStringBuff, int cchMaxStringChars )
{
   return GetThemeSysString( hTheme, iStringId, pszStringBuff, cchMaxStringChars );
}

HRESULT hb_GetThemeSysInt( HTHEME hTheme, int iIntId, int *piValue )
{
   return GetThemeSysInt( hTheme, iIntId, piValue );
}

BOOL hb_IsThemeActive( void )
{
   return IsThemeActive();
}

BOOL hb_IsAppThemed( void )
{
   return IsAppThemed();
}

HTHEME hb_GetWindowTheme( HWND hwnd )
{
   return GetWindowTheme( hwnd );
}

HRESULT hb_EnableThemeDialogTexture( HWND hwnd, DWORD dwFlags )
{
   return EnableThemeDialogTexture( hwnd, dwFlags );
}

BOOL hb_IsThemeDialogTextureEnabled( HWND hwnd )
{
   return IsThemeDialogTextureEnabled( hwnd );
}

DWORD hb_GetThemeAppProperties( void )
{
   return GetThemeAppProperties();
}

void hb_SetThemeAppProperties( DWORD dwFlags )
{
   SetThemeAppProperties( dwFlags );
}

HRESULT hb_GetCurrentThemeName( LPWSTR pszThemeFileName, int cchMaxNameChars,
      LPWSTR pszColorBuff, int cchMaxColorChars,
      LPWSTR pszSizeBuff, int cchMaxSizeChars )
{
   return GetCurrentThemeName( pszThemeFileName, cchMaxNameChars, pszColorBuff, cchMaxColorChars, pszSizeBuff, cchMaxSizeChars );
}

HRESULT hb_GetThemeDocumentationProperty( LPCWSTR pszThemeName,
      LPCWSTR pszPropertyName, LPWSTR pszValueBuff, int cchMaxValChars )
{
   return GetThemeDocumentationProperty( pszThemeName, pszPropertyName, pszValueBuff, cchMaxValChars );
}

HRESULT hb_DrawThemeParentBackground( HWND hwnd, HDC hdc, RECT * prc )
{
   return DrawThemeParentBackground( hwnd, hdc, prc );
}

HRESULT hb_EnableTheming( BOOL fEnable )
{
   return EnableTheming( fEnable );
}

LRESULT OnNotifyCustomDraw( LPARAM pNotifyStruct )
{
   LPNMCUSTOMDRAW pCustomDraw = ( LPNMCUSTOMDRAW ) pNotifyStruct;
   HWND m_hWnd = pCustomDraw->hdr.hwndFrom;
   DWORD style = ( DWORD ) GetWindowLong( m_hWnd, GWL_STYLE );

   if( ( style & ( BS_BITMAP | BS_ICON ) ) == 0 || !hb_IsAppThemed(  ) ||
         !hb_IsThemeActive(  ) )
   {
      // not icon or bitmap button, or themes not active - draw normally
      return CDRF_DODEFAULT;
   }

   if( pCustomDraw->dwDrawStage == CDDS_PREERASE )
   {
      // erase background (according to parent window's themed background
      hb_DrawThemeParentBackground( m_hWnd, pCustomDraw->hdc,
            &pCustomDraw->rc );
   }

   if( pCustomDraw->dwDrawStage == CDDS_PREERASE ||
         pCustomDraw->dwDrawStage == CDDS_PREPAINT )
   {
      // get theme handle
      HTHEME hTheme = hb_OpenThemeData( m_hWnd, L"BUTTON" );
      int state_id;
      RECT content_rect;
//    ASSERT (hTheme != NULL);

      if( hTheme == NULL )
      {
         // fail gracefully
         return CDRF_DODEFAULT;
      }

      // determine state for DrawThemeBackground()
      // note: order of these tests is significant
      state_id = PBS_NORMAL;

      if( style & WS_DISABLED )
         state_id = PBS_DISABLED;
      else if( pCustomDraw->uItemState & CDIS_SELECTED )
         state_id = PBS_PRESSED;
      else if( pCustomDraw->uItemState & CDIS_HOT )
         state_id = PBS_HOT;
      else if( style & BS_DEFPUSHBUTTON )
         state_id = PBS_DEFAULTED;

      // draw themed button background appropriate to button state
      hb_DrawThemeBackground( hTheme,
            pCustomDraw->hdc, BP_PUSHBUTTON,
            state_id, &pCustomDraw->rc, NULL );

      // get content rectangle (space inside button for image)
      content_rect = pCustomDraw->rc;

      hb_GetThemeBackgroundContentRect( hTheme,
            pCustomDraw->hdc, BP_PUSHBUTTON,
            state_id, &pCustomDraw->rc, &content_rect );

      // we're done with the theme
      hb_CloseThemeData( hTheme );

      // draw the image
      if( style & BS_BITMAP )
      {
         draw_bitmap( pCustomDraw->hdc, &content_rect, style, m_hWnd );
      }
      else
      {
//       ASSERT (style & BS_ICON);       // since we bailed out at top otherwise
         draw_icon( pCustomDraw->hdc, &content_rect, style, m_hWnd );
      }

      // finally, draw the focus rectangle if needed
      if( pCustomDraw->uItemState & CDIS_FOCUS )
      {
         // draw focus rectangle
         DrawFocusRect( pCustomDraw->hdc, &content_rect );
      }

      return CDRF_SKIPDEFAULT;
   }

   // we should never get here, since we should only get CDDS_PREERASE or CDDS_PREPAINT
   return CDRF_DODEFAULT;
}

// draw_bitmap () - Draw a bitmap
void draw_bitmap( HDC hDC, const RECT * Rect, DWORD style, HWND m_hWnd )
{
   HBITMAP hBitmap =
         ( HBITMAP ) SendMessage( m_hWnd, BM_GETIMAGE, IMAGE_BITMAP, 0L );
   int x, y;
   BITMAPINFO bmi;

   if( !hBitmap )
      return;

   // determine size of bitmap image

   memset( &bmi, 0, sizeof( BITMAPINFO ) );
   bmi.bmiHeader.biSize = sizeof( BITMAPINFOHEADER );
   GetDIBits( hDC, hBitmap, 0, 0, NULL, &bmi, DIB_RGB_COLORS );

   // determine position of top-left corner of bitmap (positioned according to style)
   x = image_left( bmi.bmiHeader.biWidth, Rect, style );
   y = image_top( bmi.bmiHeader.biHeight, Rect, style );

   // Draw the bitmap
   DrawState( hDC, NULL, NULL, ( LPARAM ) hBitmap, 0, x, y,
         bmi.bmiHeader.biWidth, bmi.bmiHeader.biHeight,
         ( style & WS_DISABLED ) !=
         0 ? ( DST_BITMAP | DSS_DISABLED ) : ( DST_BITMAP | DSS_NORMAL ) );
}

// draw_icon () - Draw an icon
void draw_icon( HDC hDC, const RECT * Rect, DWORD style, HWND m_hWnd )
{
   HICON hIcon = ( HICON ) SendMessage( m_hWnd, BM_GETIMAGE, IMAGE_ICON, 0L );
   ICONINFO ii;
   BITMAPINFO bmi;
   int cx;
   int cy;
   int x;
   int y;

   if( !hIcon )
      return;

   // determine size of icon image
   GetIconInfo( hIcon, &ii );
   memset( &bmi, 0, sizeof( BITMAPINFO ) );
   bmi.bmiHeader.biSize = sizeof( BITMAPINFOHEADER );

   if( ii.hbmColor != NULL )
   {
      // icon has separate image and mask bitmaps - use size directly
      GetDIBits( hDC, ii.hbmColor, 0, 0, NULL, &bmi, DIB_RGB_COLORS );
      cx = bmi.bmiHeader.biWidth;
      cy = bmi.bmiHeader.biHeight;
   }
   else
   {
      // icon has single mask bitmap which is twice as high as icon
      GetDIBits( hDC, ii.hbmMask, 0, 0, NULL, &bmi, DIB_RGB_COLORS );
      cx = bmi.bmiHeader.biWidth;
      cy = bmi.bmiHeader.biHeight / 2;
   }

   // determine position of top-left corner of icon
   x = image_left( cx, Rect, style );
   y = image_top( cy, Rect, style );
   // Draw the icon
   DrawState( hDC, NULL, NULL, ( LPARAM ) hIcon, 0, x, y, cx, cy,
         ( style & WS_DISABLED ) !=
         0 ? ( DST_ICON | DSS_DISABLED ) : ( DST_ICON | DSS_NORMAL ) );
}

// calcultate the left position of the image so it is drawn on left, right or centred (the default)
// as dictated by the style settings.
static int image_left( int cx, const RECT * Rect, DWORD style )
{
   int x;

   if( cx > Rect->right - Rect->left )
      cx = Rect->right - Rect->left;

   if( ( style & BS_CENTER ) == BS_LEFT )
      x = Rect->left;
   else if( ( style & BS_CENTER ) == BS_RIGHT )
      x = Rect->right - cx;
   else
      x = Rect->left + ( ( Rect->right - Rect->left ) - cx ) / 2;

   return ( x );
}

// calcultate the top position of the image so it is drawn on top, bottom or vertically centred (the default)
// as dictated by the style settings.
static int image_top( int cy, const RECT * Rect, DWORD style )
{
   int y;

   if( cy > Rect->bottom - Rect->top )
      cy = Rect->bottom - Rect->top;

   if( ( style & BS_VCENTER ) == BS_TOP )
      y = Rect->top;
   else if( ( style & BS_VCENTER ) == BS_BOTTOM )
      y = Rect->bottom - cy;
   else
      y = Rect->top + ( ( Rect->bottom - Rect->top ) - cy ) / 2;

   return ( y );
}

HB_FUNC( HWG_INITTHEMELIB )
{
   /* UxTheme is now statically linked (see the #pragma comment(lib,...)
      near the top of this file for MSVC; GCC/Clang/MinGW builds need
      "-luxtheme" on the link command) since Windows 2000 support - which
      predates UxTheme entirely - was dropped. There is nothing left to
      dynamically load here; ThemeLibLoaded simply reflects that the
      theme APIs are available. */
   ThemeLibLoaded = TRUE;
}

HB_FUNC( HWG_ENDTHEMELIB )
{
   ThemeLibLoaded = FALSE;
}

HB_FUNC( HWG_ONNOTIFYCUSTOMDRAW )
{
   /* Use hb_parnint to get full 64-bit LPARAM on 64-bit builds */
   LPARAM lParam = ( LPARAM ) hb_parnint( 1 );
   /* OnNotifyCustomDraw returns LRESULT (64-bit on x64) - use hb_retnint */
   hb_retnint( ( HB_MAXINT ) OnNotifyCustomDraw( lParam ) );
}

void Calc_iconWidthHeight( HWND m_hWnd, DWORD * ccx, DWORD * ccy, HDC hDC,
      HICON hIcon )
{
   ICONINFO ii;
   BITMAPINFO bmi;
   int cx;
   int cy;

   HB_SYMBOL_UNUSED( m_hWnd );

   if( !hIcon )
   {
      *ccx = 0;
      *ccy = 0;
      return;
   }

   // determine size of icon image
   GetIconInfo( hIcon, &ii );
   memset( &bmi, 0, sizeof( BITMAPINFO ) );
   bmi.bmiHeader.biSize = sizeof( BITMAPINFOHEADER );

   if( ii.hbmColor != NULL )
   {
      // icon has separate image and mask bitmaps - use size directly
      GetDIBits( hDC, ii.hbmColor, 0, 0, NULL, &bmi, DIB_RGB_COLORS );
      cx = bmi.bmiHeader.biWidth;
      cy = bmi.bmiHeader.biHeight;
   }
   else
   {
      // icon has single mask bitmap which is twice as high as icon
      GetDIBits( hDC, ii.hbmMask, 0, 0, NULL, &bmi, DIB_RGB_COLORS );
      cx = bmi.bmiHeader.biWidth;
      cy = bmi.bmiHeader.biHeight / 2;
   }

   // determine position of top-left corner of icon
   *ccx = cx;
   *ccy = cy;
}

void Calc_bitmapWidthHeight( HWND m_hWnd, DWORD * ccx, DWORD * ccy, HDC hDC,
      HBITMAP hBitmap )
{
   // int x,y;
   BITMAPINFO bmi;

   HB_SYMBOL_UNUSED( m_hWnd );

   if( !hBitmap )
   {
      *ccy = 0;
      *ccx = 0;
      return;
   }

   memset( &bmi, 0, sizeof( BITMAPINFO ) );
   bmi.bmiHeader.biSize = sizeof( BITMAPINFOHEADER );
   GetDIBits( hDC, hBitmap, 0, 0, NULL, &bmi, DIB_RGB_COLORS );

   *ccx = bmi.bmiHeader.biWidth;
   *ccy = bmi.bmiHeader.biHeight;
}

/*
    case ST_ALIGN_HORIZ:
      if (bHasTitle == FALSE)
      {
        // Center image horizontally
        rpImage->left += ((rpImage->Width() - (long)dwWidth)/2);
      }
      else
      {
        // Image must be placed just inside the focus rect
        rpImage->left += m_ptImageOrg.x;
        rpTitle->left += dwWidth + m_ptImageOrg.x;
      }
      // Center image vertically
      rpImage->top += ((rpImage->Height() - (long)dwHeight)/2);
      break;

    case ST_ALIGN_HORIZ_RIGHT:
      GetClientRect(&rBtn);
      if (bHasTitle == FALSE)
      {
        // Center image horizontally
        rpImage->left += ((rpImage->Width() - (long)dwWidth)/2);
      }
      else
      {
        // Image must be placed just inside the focus rect
        rpTitle->right = rpTitle->Width() - dwWidth - m_ptImageOrg.x;
        rpTitle->left = m_ptImageOrg.x;
        rpImage->left = rBtn.right - dwWidth - m_ptImageOrg.x;
        // Center image vertically
        rpImage->top += ((rpImage->Height() - (long)dwHeight)/2);
      }
      break;

    case ST_ALIGN_VERT:
      // Center image horizontally
      rpImage->left += ((rpImage->Width() - (long)dwWidth)/2);
      if (bHasTitle == FALSE)
      {
        // Center image vertically
        rpImage->top += ((rpImage->Height() - (long)dwHeight)/2);
      }
      else
      {
        rpImage->top = m_ptImageOrg.y;
        rpTitle->top += dwHeight;
      }
      break;

    case ST_ALIGN_OVERLAP:
      break;
  } // switch

*/

static void PrepareImageRect( HWND hButtonWnd, BOOL bHasTitle, RECT * rpItem,
      RECT * rpTitle, BOOL bIsPressed, DWORD dwWidth, DWORD dwHeight,
      RECT * rpImage, int m_byAlign )
{
   RECT rBtn;
   //LONG rpImageHeight;
   //LONG rpImageWidth;

   CopyRect( rpImage, rpItem );

   switch ( m_byAlign )
   {
      case ST_ALIGN_HORIZ:
         if( bHasTitle == FALSE )
         {
            // Center image horizontally
            rpImage->left +=
                  ( ( ( rpImage->right - rpImage->left ) -
                        ( long ) dwWidth ) / 2 );
         }
         else
         {
            // Image must be placed just inside the focus rect
            rpImage->left += 3;
            rpTitle->left += dwWidth + 3;
         }
         // Center image vertically
         rpImage->top +=
               ( ( ( rpImage->bottom - rpImage->top ) -
                     ( long ) dwHeight ) / 2 );
         break;

      case ST_ALIGN_HORIZ_RIGHT:
         GetClientRect( hButtonWnd, &rBtn );
         if( bHasTitle == FALSE )
         {
            // Center image horizontally
            rpImage->left +=
                  ( ( rpImage->right - rpImage->left ) -
                  ( long ) dwWidth ) / 2;
         }
         else
         {
            // Image must be placed just inside the focus rect
            rpTitle->right = ( rpTitle->right - rpTitle->left ) - dwWidth - 3;
            rpTitle->left = 3;
            rpImage->left = rBtn.right - dwWidth - 3;
            // Center image vertically
            rpImage->top +=
                  ( ( rpImage->bottom - rpImage->top ) -
                  ( long ) dwHeight ) / 2;
         }
         break;

      case ST_ALIGN_VERT:
         // Center image horizontally
         rpImage->left +=
               ( ( ( rpImage->right - rpImage->left ) -
                     ( long ) dwWidth ) / 2 );
         if( bHasTitle == FALSE )
         {
            // Center image vertically
            rpImage->top +=
                  ( ( ( rpImage->bottom - rpImage->top ) -
                        ( long ) dwHeight ) / 2 );
         }
         else
         {
            rpImage->top = 3;
            rpTitle->top += dwHeight;
         }
         break;

      case ST_ALIGN_OVERLAP:
         break;
   }                            // switch

   // If button is pressed then press image also
   if( bIsPressed && !Themed )
      OffsetRect( rpImage, 1, 1 );
//    rpItem=rpImage;

}                               // End of PrepareImageRect

static void DrawTheIcon( HWND hButtonWnd, HDC dc, BOOL bHasTitle,
      RECT * rpItem, RECT * rpTitle, BOOL bIsPressed, BOOL bIsDisabled,
      HICON hIco, HBITMAP hBitmap, int iStyle )
{
   RECT rImage;
   DWORD cx = 0;
   DWORD cy = 0;

   if( hIco )
      Calc_iconWidthHeight( hButtonWnd, &cx, &cy, dc, hIco );

   if( hBitmap )
   {
//      SetBkColor(dc,RGB(255,255,255));

      Calc_bitmapWidthHeight( hButtonWnd, &cx, &cy, dc, hBitmap );
   }
   PrepareImageRect( hButtonWnd, bHasTitle, rpItem, rpTitle, bIsPressed, cx,
         cy, &rImage, iStyle );

   if( hIco )
      DrawState( dc,
            NULL,
            NULL,
            ( LPARAM ) hIco,
            0,
            rImage.left,
            rImage.top,
            ( rImage.right - rImage.left ),
            ( rImage.bottom - rImage.top ),
            ( bIsDisabled ? DSS_DISABLED : DSS_NORMAL ) | DST_ICON );

   if( hBitmap )
      DrawState( dc,
            NULL,
            NULL,
            ( LPARAM ) hBitmap,
            0,
            rImage.left,
            rImage.top,
            ( rImage.right - rImage.left ),
            ( rImage.bottom - rImage.top ),
            ( bIsDisabled ? DSS_DISABLED : DSS_NORMAL ) | DST_BITMAP );

}                               // End of DrawTheIcon

HB_FUNC( HWG_OPENTHEMEDATA )
{
   HWND hwnd = ( HWND ) HB_PARHANDLE( 1 );
   HTHEME p;
#if !defined( __XHARBOUR__ )
   /* Respect the VM's configured codepage - e.g. UTF-8 set via
      HWG_SETUTF8 - instead of assuming the system ANSI codepage. */
   void *output;

   hb_parstr_u16( 2, HB_CDP_ENDIAN_NATIVE, &output, NULL );
   p = hb_OpenThemeData( hwnd, ( LPCWSTR ) output );
   hb_strfree( output );
#else
   {
      LPCSTR pText = hb_parc( 2 );
      int mlen = MultiByteToWideChar( CP_ACP, MB_PRECOMPOSED, pText, -1, NULL, 0 );
      WCHAR *woutput = ( WCHAR * ) hb_xgrab( mlen * sizeof( WCHAR ) );

      MultiByteToWideChar( CP_ACP, MB_PRECOMPOSED, pText, -1, woutput, mlen );
      p = hb_OpenThemeData( hwnd, woutput );
      hb_xfree( woutput );
   }
#endif
   if( p )
      Themed = TRUE;
   hb_retptr( ( void * ) p );
}

HB_FUNC( HWG_ISTHEMEDLOAD )
{
   hb_retl( ThemeLibLoaded );
}

HB_FUNC( HWG_DRAWTHEMEBACKGROUND )
{
   HTHEME hTheme = ( HTHEME ) hb_parptr( 1 );
   HDC hdc = ( HDC ) HB_PARHANDLE( 2 );
   int iPartId = hb_parni( 3 );
   int iStateId = hb_parni( 4 );
   RECT pRect = {0};
   RECT pClipRect = {0};

   if( HB_ISARRAY( 5 ) )
      Array2Rect( hb_param( 5, HB_IT_ARRAY ), &pRect );
   if( HB_ISARRAY( 6 ) )
      Array2Rect( hb_param( 6, HB_IT_ARRAY ), &pClipRect );

   hb_retnl( hb_DrawThemeBackground( hTheme, hdc,
               iPartId, iStateId, &pRect, NULL ) );
}

HB_FUNC( HWG_DRAWTHEICON )
{
   HWND hButtonWnd = ( HWND ) HB_PARHANDLE( 1 );
   HDC dc = ( HDC ) HB_PARHANDLE( 2 );
   BOOL bHasTitle = hb_parl( 3 );
   RECT rpItem = {0};
   RECT rpTitle = {0};
   BOOL bIsPressed = hb_parl( 6 );
   BOOL bIsDisabled = hb_parl( 7 );
   HICON hIco = ( HB_ISNUM( 8 ) ||
         HB_ISPOINTER( 8 ) ) ? ( HICON ) HB_PARHANDLE( 8 ) : NULL;
   HBITMAP hBit = ( HB_ISNUM( 9 ) ||
         HB_ISPOINTER( 9 ) ) ? ( HBITMAP ) HB_PARHANDLE( 9 ) : NULL;
   int iStyle = hb_parni( 10 );

   if( HB_ISARRAY( 4 ) )
      Array2Rect( hb_param( 4, HB_IT_ARRAY ), &rpItem );
   if( HB_ISARRAY( 5 ) )
      Array2Rect( hb_param( 5, HB_IT_ARRAY ), &rpTitle );

   DrawTheIcon( hButtonWnd, dc, bHasTitle, &rpItem, &rpTitle, bIsPressed,
         bIsDisabled, hIco, hBit, iStyle );
   hb_storvni( rpItem.left, 4, 1 );
   hb_storvni( rpItem.top, 4, 2 );
   hb_storvni( rpItem.right, 4, 3 );
   hb_storvni( rpItem.bottom, 4, 4 );
   hb_storvni( rpTitle.left, 5, 1 );
   hb_storvni( rpTitle.top, 5, 2 );
   hb_storvni( rpTitle.right, 5, 3 );
   hb_storvni( rpTitle.bottom, 5, 4 );

}

/*
//PrepareImageRect( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, ::hIcon, ::hbitmap, ::iStyle )
*/

HB_FUNC( HWG_PREPAREIMAGERECT )
{

   HWND hButtonWnd = (HWND) HB_PARHANDLE( 1 ) ;
   HDC dc = (HDC) HB_PARHANDLE( 2 ) ;
   BOOL bHasTitle = hb_parl( 3 );
   RECT rpItem = {0};
   RECT rpTitle = {0};
   //
   RECT  rImage = {0};
   DWORD cx =0 ;
   DWORD cy =0 ;
   //
   BOOL bIsPressed = hb_parl( 6 );
   HICON   hIco = (HB_ISNUM( 7 ) ||
         HB_ISPOINTER( 7 ) ) ? ( HICON ) HB_PARHANDLE( 7 ) : NULL;
   HBITMAP hBitmap = (HB_ISNUM( 8 ) ||
         HB_ISPOINTER( 8 ) ) ? ( HBITMAP ) HB_PARHANDLE( 8 ) : NULL;
   int iStyle = hb_parni( 9 );

   if( HB_ISARRAY( 4 ) )
      Array2Rect( hb_param( 4, HB_IT_ARRAY ), &rpItem );
   if( HB_ISARRAY( 5 ) )
      Array2Rect( hb_param( 5, HB_IT_ARRAY ), &rpTitle );

   if ( hIco )
      Calc_iconWidthHeight( hButtonWnd, &cx, &cy, dc, hIco );
   if (hBitmap)
   {
      Calc_bitmapWidthHeight( hButtonWnd, &cx, &cy, dc, hBitmap );
   }
   PrepareImageRect( hButtonWnd, bHasTitle,&rpItem, &rpTitle, bIsPressed, cx, cy, &rImage, iStyle );

   hb_storvni( rpItem.left   , 4 , 1);
   hb_storvni( rpItem.top    , 4 , 2);
   hb_storvni( rpItem.right  , 4 , 3);
   hb_storvni( rpItem.bottom , 4 , 4);
   hb_storvni( rpTitle.left   , 5 , 1);
   hb_storvni( rpTitle.top    , 5 , 2);
   hb_storvni( rpTitle.right  , 5 , 3);
   hb_storvni( rpTitle.bottom , 5 , 4);

   /* hb_itemReturn already returns the item; do NOT call hb_itemRelease. */
   hb_itemReturn( Rect2Array( &rImage ) ); 
}

HB_FUNC( HWG_DRAWTHEMETEXT )
{
   HTHEME hTheme = ( HTHEME ) hb_parptr( 1 );
   HDC hdc = ( HDC ) HB_PARHANDLE( 2 );
   int iPartId = hb_parni( 3 );
   int iStateId = hb_parni( 4 );
   DWORD dwTextFlags = ( DWORD ) hb_parnl( 6 );
   DWORD dwTextFlags2 = ( DWORD ) hb_parnl( 7 );
   RECT pRect = {0};
#if !defined( __XHARBOUR__ )
   /* Respect the VM's configured codepage - e.g. UTF-8 set via
      HWG_SETUTF8 - instead of assuming the system ANSI codepage. */
   void *output;
   HB_SIZE nLen = 0;

   hb_parstr_u16( 5, HB_CDP_ENDIAN_NATIVE, &output, &nLen );

   if( HB_ISARRAY( 8 ) )
      Array2Rect( hb_param( 8, HB_IT_ARRAY ), &pRect );
   hb_DrawThemeText( hTheme, hdc, iPartId,
                     iStateId, ( LPCWSTR ) output, ( int ) nLen, dwTextFlags,
                     dwTextFlags2, &pRect );
   hb_strfree( output );
#else
   {
      LPCSTR pText = hb_parc( 5 );
      int mlen = MultiByteToWideChar( CP_ACP, MB_PRECOMPOSED, pText, -1, NULL, 0 );
      WCHAR *output = ( WCHAR * ) hb_xgrab( mlen * sizeof( WCHAR ) );

      if( HB_ISARRAY( 8 ) )
         Array2Rect( hb_param( 8, HB_IT_ARRAY ), &pRect );
      MultiByteToWideChar( CP_ACP, MB_PRECOMPOSED, pText, -1, output, mlen );
      hb_DrawThemeText( hTheme, hdc, iPartId,
                        iStateId, output, mlen - 1, dwTextFlags,
                        dwTextFlags2, &pRect );
      hb_xfree( output );
   }
#endif
}

HB_FUNC( HWG_CLOSETHEMEDATA )
{
   HTHEME hTheme = ( HTHEME ) hb_parptr( 1 );
   hb_CloseThemeData( hTheme );
}

HB_FUNC( HWG_TRACKMOUSEVENT )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );
   DWORD dwFlags = ( DWORD ) hb_parnl( 2 );
   DWORD dwHoverTime = ( DWORD ) hb_parnl( 3 );
   TRACKMOUSEEVENT csTME;

   csTME.cbSize = sizeof( csTME );
   csTME.dwFlags = hb_pcount() == 2 ? dwFlags : TME_LEAVE ;
   csTME.hwndTrack = m_hWnd;
   csTME.dwHoverTime = hb_pcount() == 3 ? dwHoverTime : HOVER_DEFAULT ;
   _TrackMouseEvent( &csTME );
}

HB_FUNC( HWG_BUTTONEXONSETSTYLE )
{
   WPARAM wParam = ( WPARAM ) hb_parnint( 1 );
   LPARAM lParam = ( LPARAM ) hb_parnint( 2 );
   HWND h = ( HWND ) HB_PARHANDLE( 3 );

   UINT nNewType = ( wParam & BS_TYPEMASK );

   // Update default state flag
   if( nNewType == BS_DEFPUSHBUTTON )
   {
      //m_bIsDefault = TRUE;
      hb_storl( TRUE, 4 );
   }                            // if
   else if( nNewType == BS_PUSHBUTTON )
   {
      // Losing default state always allowed

      hb_storl( FALSE, 4 );
   }                            // if

   // Can't change control type after owner-draw is set.
   // Let the system process changes to other style bits
   // and redrawing, while keeping owner-draw style
   hb_retnint( ( HB_MAXINT ) DefWindowProc( h, BM_SETSTYLE,
               ( wParam & ~BS_TYPEMASK ) | BS_OWNERDRAW, lParam ) );
}                               // End of OnSetStyle


HB_FUNC( HWG_GETTHESTYLE )
{
   LONG nBS = hb_parnl( 1 );
   LONG nBS1 = hb_parnl( 2 );
   hb_retnl( nBS & nBS1 );
}

HB_FUNC( HWG_MODSTYLE )
{
   LONG nbs = hb_parnl( 1 );
   LONG b = hb_parnl( 2 );
   LONG c = hb_parnl( 3 );
   hb_retnl( ( nbs & ~b ) | c );
}

HB_FUNC( HWG_DRAWTHEMEPARENTBACKGROUND )
{
   HWND hTheme = ( HWND ) HB_PARHANDLE( 1 );
   HDC hdc = ( HDC ) HB_PARHANDLE( 2 );
   RECT pRect = {0};

   if( HB_ISARRAY( 3 ) )
      Array2Rect( hb_param( 3, HB_IT_ARRAY ), &pRect );

   hb_retnl( hb_DrawThemeParentBackground( hTheme, hdc, &pRect ) );
}

HB_FUNC( HWG_ISTHEMEACTIVE )
{
   hb_retl( hb_IsThemeActive(  ) );
}


HB_FUNC( HWG_GETTHEMESYSCOLOR )
{
   HWND hTheme = ( HWND ) HB_PARHANDLE( 1 );
   int iColor = ( int ) hb_parnl( 2 );

   /* COLORREF is a 32-bit value, not a handle. Return as integer. */
   hb_retnint( ( HB_MAXINT ) hb_GetThemeSysColor( hTheme, iColor ) );
}


/* NANDO  18/09/2011 */

HB_FUNC( HWG_SETWINDOWTHEME)
{
   HWND hwnd = (HWND) HB_PARHANDLE( 1 ) ;
   int ienable = hb_parni(2);

   /* SetWindowTheme() has been safely callable on any Windows version
      since XP - no need to gate it behind a GetVersionEx() check. The
      old check (dwMajorVersion>=5 && dwMinorVersion==1) only ever
      matched Windows XP (5.1, and accidentally 7's 6.1 too), so on
      Windows 8/10/11 - 32 or 64-bit - this silently did nothing. */
   if ( ienable == 0 )
      hb_SetWindowTheme( hwnd, L" ", L" " ) ; // pszSubAppName, pszSubIdList
   else
      hb_SetWindowTheme( hwnd, NULL, NULL) ;
}

HB_FUNC( HWG_GETWINDOWTHEME )
{
   /* See HWG_SETWINDOWTHEME above - GetWindowTheme() needs no OS-version
      gating either. */
   HTHEME hTheme = hb_GetWindowTheme( (HWND) HB_PARHANDLE( 1 ) );
   HB_RETHANDLE ( hTheme );
}

/* ========================= EOF of theme.c ============================= */