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

/* Tickets #74,36,41 */
#include "incomp_pointer.h"

/* Macro to safely cast function pointers to FARPROC without
   triggering -Wcast-function-type-mismatch warnings in Clang/GCC.
   Converts to integer of pointer size first, then to FARPROC. */
#define FPROC(pfn) ((FARPROC)(HB_PTRUINT)(pfn))

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
HMODULE m_hThemeDll;
BOOL ThemeLibLoaded = FALSE;

void draw_bitmap( HDC hDC, const RECT * Rect, DWORD style, HWND m_hWnd );
void draw_icon( HDC hDC, const RECT * Rect, DWORD style, HWND m_hWnd );

static int image_top( int cy, const RECT * Rect, DWORD style );
static int image_left( int cx, const RECT * Rect, DWORD style );

typedef HTHEME( __stdcall * PFNOPENTHEMEDATA ) ( HWND hwnd,
      LPCWSTR pszClassList );

typedef HRESULT( __stdcall * PFNCLOSETHEMEDATA ) ( HTHEME hTheme );

typedef HRESULT( __stdcall * PFNDRAWTHEMEBACKGROUND ) ( HTHEME hTheme,
      HDC hdc, int iPartId, int iStateId, const RECT * pRect,
      const RECT * pClipRect );

typedef HRESULT( __stdcall * PFNDRAWTHEMETEXT ) ( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, LPCWSTR pszText, int iCharCount,
      DWORD dwTextFlags, DWORD dwTextFlags2, const RECT * pRect );

typedef HRESULT( __stdcall *
      PFNGETTHEMEBACKGROUNDCONTENTRECT ) ( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pBoundingRect,
      RECT * pContentRect );
typedef HRESULT( __stdcall * PFNGETTHEMEBACKGROUNDEXTENT ) ( HTHEME hTheme,
      HDC hdc, int iPartId, int iStateId, const RECT * pContentRect,
      RECT * pExtentRect );

typedef HRESULT( __stdcall * PFNGETTHEMEPARTSIZE ) ( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, RECT * pRect, int eSize, SIZE * psz );

typedef HRESULT( __stdcall * PFNGETTHEMETEXTEXTENT ) ( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, LPCWSTR pszText, int iCharCount,
      DWORD dwTextFlags, const RECT * pBoundingRect, RECT * pExtentRect );

typedef HRESULT( __stdcall * PFNGETTHEMETEXTMETRICS ) ( HTHEME hTheme,
      HDC hdc, int iPartId, int iStateId, TEXTMETRIC * ptm );

typedef HRESULT( __stdcall * PFNGETTHEMEBACKGROUNDREGION ) ( HTHEME hTheme,
      HDC hdc, int iPartId, int iStateId, const RECT * pRect,
      HRGN * pRegion );

typedef HRESULT( __stdcall * PFNHITTESTTHEMEBACKGROUND ) ( HTHEME hTheme,
      HDC hdc, int iPartId, int iStateId, DWORD dwOptions, const RECT * pRect,
      HRGN hrgn, POINT ptTest, WORD * pwHitTestCode );

typedef HRESULT( __stdcall * PFNDRAWTHEMEEDGE ) ( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pDestRect, UINT uEdge,
      UINT uFlags, RECT * pContentRect );

typedef HRESULT( __stdcall * PFNDRAWTHEMEICON ) ( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pRect, HIMAGELIST himl,
      int iImageIndex );

typedef BOOL( __stdcall * PFNISTHEMEPARTDEFINED ) ( HTHEME hTheme,
      int iPartId, int iStateId );

typedef BOOL( __stdcall *
      PFNISTHEMEBACKGROUNDPARTIALLYTRANSPARENT ) ( HTHEME hTheme, int iPartId,
      int iStateId );
typedef HRESULT( __stdcall * PFNGETTHEMECOLOR ) ( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, COLORREF * pColor );

typedef HRESULT( __stdcall * PFNGETTHEMEMETRIC ) ( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, int iPropId, int *piVal );

typedef HRESULT( __stdcall * PFNGETTHEMESTRING ) ( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, LPWSTR pszBuff, int cchMaxBuffChars );
typedef HRESULT( __stdcall * PFNGETTHEMEBOOL ) ( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, BOOL * pfVal );

typedef HRESULT( __stdcall * PFNGETTHEMEINT ) ( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, int *piVal );

typedef HRESULT( __stdcall * PFNGETTHEMEENUMVALUE ) ( HTHEME hTheme,
      int iPartId, int iStateId, int iPropId, int *piVal );

typedef HRESULT( __stdcall * PFNGETTHEMEPOSITION ) ( HTHEME hTheme,
      int iPartId, int iStateId, int iPropId, POINT * pPoint );
typedef HRESULT( __stdcall * PFNGETTHEMEFONT ) ( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, int iPropId, LOGFONT * pFont );
typedef HRESULT( __stdcall * PFNGETTHEMERECT ) ( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, RECT * pRect );
typedef HRESULT( __stdcall * PFNGETTHEMEMARGINS ) ( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, int iPropId, RECT * prc,
      MARGINS * pMargins );

typedef HRESULT( __stdcall * PFNGETTHEMEINTLIST ) ( HTHEME hTheme,
      int iPartId, int iStateId, int iPropId, INTLIST * pIntList );

typedef HRESULT( __stdcall * PFNGETTHEMEPROPERTYORIGIN ) ( HTHEME hTheme,
      int iPartId, int iStateId, int iPropId, int *pOrigin );

typedef HRESULT( __stdcall * PFNSETWINDOWTHEME ) ( HWND hwnd,
      LPCWSTR pszSubAppName, LPCWSTR pszSubIdList );

typedef HRESULT( __stdcall * PFNGETTHEMEFILENAME ) ( HTHEME hTheme,
      int iPartId, int iStateId, int iPropId, LPWSTR pszThemeFileName,
      int cchMaxBuffChars );
typedef COLORREF( __stdcall * PFNGETTHEMESYSCOLOR ) ( HTHEME hTheme,
      int iColorId );

typedef HBRUSH( __stdcall * PFNGETTHEMESYSCOLORBRUSH ) ( HTHEME hTheme,
      int iColorId );

typedef BOOL( __stdcall * PFNGETTHEMESYSBOOL ) ( HTHEME hTheme, int iBoolId );
typedef int ( __stdcall * PFNGETTHEMESYSSIZE ) ( HTHEME hTheme, int iSizeId );
typedef HRESULT( __stdcall * PFNGETTHEMESYSFONT ) ( HTHEME hTheme,
      int iFontId, LOGFONT * plf );

typedef HRESULT( __stdcall * PFNGETTHEMESYSSTRING ) ( HTHEME hTheme,
      int iStringId, LPWSTR pszStringBuff, int cchMaxStringChars );
typedef HRESULT( __stdcall * PFNGETTHEMESYSINT ) ( HTHEME hTheme, int iIntId,
      int *piValue );

typedef BOOL( __stdcall * PFNISTHEMEACTIVE ) ( void );

typedef BOOL( __stdcall * PFNISAPPTHEMED ) ( void );
typedef HTHEME( __stdcall * PFNGETWINDOWTHEME ) ( HWND hwnd );
typedef HRESULT( __stdcall * PFNENABLETHEMEDIALOGTEXTURE ) ( HWND hwnd,
      DWORD dwFlags );
typedef BOOL( __stdcall * PFNISTHEMEDIALOGTEXTUREENABLED ) ( HWND hwnd );
typedef DWORD( __stdcall * PFNGETTHEMEAPPPROPERTIES ) ( void );

typedef void ( __stdcall * PFNSETTHEMEAPPPROPERTIES ) ( DWORD dwFlags );

typedef HRESULT( __stdcall *
      PFNGETCURRENTTHEMENAME ) ( LPWSTR pszThemeFileName, int cchMaxNameChars,
      LPWSTR pszColorBuff, int cchMaxColorChars, LPWSTR pszSizeBuff,
      int cchMaxSizeChars );
typedef HRESULT( __stdcall *
      PFNGETTHEMEDOCUMENTATIONPROPERTY ) ( LPCWSTR pszThemeName,
      LPCWSTR pszPropertyName, LPWSTR pszValueBuff, int cchMaxValChars );

typedef HRESULT( __stdcall * PFNDRAWTHEMEPARENTBACKGROUND ) ( HWND hwnd,
      HDC hdc, RECT * prc );
typedef HRESULT( __stdcall * PFNENABLETHEMING ) ( BOOL fEnable );

static HRESULT EnableThemingFail( BOOL fenable )        // fenable
{
   HB_SYMBOL_UNUSED( fenable );
   return E_FAIL;
}

static HRESULT DrawThemeBackgroundFail( HTHEME a, HDC s, int d, int f, const RECT * g, const RECT * h ) //HTHEME a, HDC s, int d, int f, const RECT * , const RECT *
{
   HB_SYMBOL_UNUSED( a );
   HB_SYMBOL_UNUSED( s );
   HB_SYMBOL_UNUSED( d );
   HB_SYMBOL_UNUSED( f );
   HB_SYMBOL_UNUSED( g );
   HB_SYMBOL_UNUSED( h );
   return E_FAIL;
}

static HRESULT CloseThemeDataFail( HTHEME s )   //s
{
   HB_SYMBOL_UNUSED( s );
   return E_FAIL;
}

static HTHEME OpenThemeDataFail( HWND s, LPCWSTR d )    //s d
{
   HB_SYMBOL_UNUSED( s );
   HB_SYMBOL_UNUSED( d );
   return NULL;
}

static HRESULT DrawThemeTextFail( HTHEME a, HDC s, int d, int f, LPCWSTR g,
      int h, DWORD j, DWORD k, const RECT * z )
{
   HB_SYMBOL_UNUSED( a );
   HB_SYMBOL_UNUSED( s );
   HB_SYMBOL_UNUSED( d );
   HB_SYMBOL_UNUSED( f );
   HB_SYMBOL_UNUSED( g );
   HB_SYMBOL_UNUSED( h );
   HB_SYMBOL_UNUSED( j );
   HB_SYMBOL_UNUSED( k );
   HB_SYMBOL_UNUSED( z );
   return E_FAIL;
}

static HRESULT GetThemeBackgroundContentRectFail( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pBoundingRect,
      RECT * pContentRect )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( pBoundingRect );
   HB_SYMBOL_UNUSED( pContentRect );
   return E_FAIL;
}

static HRESULT GetThemeBackgroundExtentFail( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pContentRect,
      RECT * pExtentRect )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( pContentRect );
   HB_SYMBOL_UNUSED( pExtentRect );
   return E_FAIL;
}

static HRESULT GetThemePartSizeFail( HTHEME a, HDC s, int d, int f, RECT * g,
      int h, SIZE * j )
{
   HB_SYMBOL_UNUSED( a );
   HB_SYMBOL_UNUSED( s );
   HB_SYMBOL_UNUSED( d );
   HB_SYMBOL_UNUSED( f );
   HB_SYMBOL_UNUSED( g );
   HB_SYMBOL_UNUSED( h );
   HB_SYMBOL_UNUSED( j );
   return E_FAIL;
}

static HRESULT GetThemeTextExtentFail( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, LPCWSTR pszText, int iCharCount,
      DWORD dwTextFlags, const RECT * pBoundingRect, RECT * pExtentRect )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( pszText );
   HB_SYMBOL_UNUSED( iCharCount );
   HB_SYMBOL_UNUSED( dwTextFlags );
   HB_SYMBOL_UNUSED( pBoundingRect );
   HB_SYMBOL_UNUSED( pExtentRect );
   return E_FAIL;
}

static HRESULT GetThemeTextMetricsFail( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, TEXTMETRIC * ptm )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( ptm );
   return E_FAIL;
}

static HRESULT GetThemeBackgroundRegionFail( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pRect, HRGN * pRegion )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( pRect );
   HB_SYMBOL_UNUSED( pRegion );
   return E_FAIL;
}

static HRESULT HitTestThemeBackgroundFail( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, DWORD dwOptions, const RECT * pRect,
      HRGN hrgn, POINT ptTest, WORD * pwHitTestCode )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( dwOptions );
   HB_SYMBOL_UNUSED( pRect );
   HB_SYMBOL_UNUSED( hrgn );
#if !defined(__POCC__)
   HB_SYMBOL_UNUSED( ptTest );
#endif
   HB_SYMBOL_UNUSED( pwHitTestCode );
   return E_FAIL;
}

static HRESULT DrawThemeEdgeFail( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, const RECT * pDestRect, UINT uEdge, UINT uFlags,
      RECT * pContentRect )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( pDestRect );
   HB_SYMBOL_UNUSED( uEdge );
   HB_SYMBOL_UNUSED( uFlags );
   HB_SYMBOL_UNUSED( pContentRect );
   return E_FAIL;
}

static HRESULT DrawThemeIconFail( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, const RECT * pRect, HIMAGELIST himl, int iImageIndex )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( pRect );
   HB_SYMBOL_UNUSED( himl );
   HB_SYMBOL_UNUSED( iImageIndex );
   return E_FAIL;
}

static BOOL IsThemePartDefinedFail( HTHEME hTheme, int iPartId, int iStateId )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   return E_FAIL;
}

static BOOL IsThemeBackgroundPartiallyTransparentFail( HTHEME hTheme,
      int iPartId, int iStateId )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   return E_FAIL;
}

static HRESULT GetThemeColorFail( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, COLORREF * pColor )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( pColor );
   return E_FAIL;
}

static HRESULT GetThemeMetricFail( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, int iPropId, int *piVal )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( piVal );
   return E_FAIL;
}

static HRESULT GetThemeStringFail( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, LPWSTR pszBuff, int cchMaxBuffChars )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( pszBuff );
   HB_SYMBOL_UNUSED( cchMaxBuffChars );
   return E_FAIL;
}

static HRESULT GetThemeBoolFail( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, BOOL * pfVal )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( pfVal );
   return E_FAIL;
}

static HRESULT GetThemeIntFail( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, int *piVal )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( piVal );
   return E_FAIL;
}

static HRESULT GetThemeEnumValueFail( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, int *piVal )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( piVal );
   return E_FAIL;
}

static HRESULT GetThemePositionFail( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, POINT * pPoint )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( pPoint );
   return E_FAIL;
}

static HRESULT GetThemeFontFail( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, int iPropId, LOGFONT * pFont )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( pFont );
   return E_FAIL;
}

static HRESULT GetThemeRectFail( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, RECT * pRect )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( pRect );
   return E_FAIL;
}

static HRESULT GetThemeMarginsFail( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, int iPropId, RECT * prc, MARGINS * pMargins )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( prc );
   HB_SYMBOL_UNUSED( pMargins );
   return E_FAIL;
}

static HRESULT GetThemeIntListFail( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, INTLIST * pIntList )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( pIntList );
   return E_FAIL;
}

static HRESULT GetThemePropertyOriginFail( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, int *pOrigin )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( pOrigin );
   return E_FAIL;
}

static HRESULT SetWindowThemeFail( HWND hwnd, LPCWSTR pszSubAppName,
      LPCWSTR pszSubIdList )
{
   HB_SYMBOL_UNUSED( hwnd );
   HB_SYMBOL_UNUSED( pszSubAppName );
   HB_SYMBOL_UNUSED( pszSubIdList );
   return E_FAIL;
}

static HRESULT GetThemeFilenameFail( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, LPWSTR pszThemeFileName,
      int cchMaxBuffChars )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iPartId );
   HB_SYMBOL_UNUSED( iStateId );
   HB_SYMBOL_UNUSED( iPropId );
   HB_SYMBOL_UNUSED( pszThemeFileName );
   HB_SYMBOL_UNUSED( cchMaxBuffChars );
   return E_FAIL;
}

static HRESULT GetThemeSysFontFail( HTHEME hTheme, int iFontId,
      LOGFONT * plf )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iFontId );
   HB_SYMBOL_UNUSED( plf );
   return E_FAIL;
}

static COLORREF GetThemeSysColorFail( HTHEME hTheme, int iColorId )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iColorId );
   return RGB( 255, 255, 255 );
}

static HBRUSH GetThemeSysColorBrushFail( HTHEME hTheme, int iColorId )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iColorId );
   return NULL;
}

static BOOL GetThemeSysBoolFail( HTHEME hTheme, int iBoolId )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iBoolId );
   return FALSE;
}

static int GetThemeSysSizeFail( HTHEME hTheme, int iSizeId )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iSizeId );
   return 0;
}

static HRESULT GetThemeSysStringFail( HTHEME hTheme, int iStringId,
      LPWSTR pszStringBuff, int cchMaxStringChars )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iStringId );
   HB_SYMBOL_UNUSED( pszStringBuff );
   HB_SYMBOL_UNUSED( cchMaxStringChars );
   return E_FAIL;
}

static HRESULT GetThemeSysIntFail( HTHEME hTheme, int iIntId, int *piValue )
{
   HB_SYMBOL_UNUSED( hTheme );
   HB_SYMBOL_UNUSED( iIntId );
   HB_SYMBOL_UNUSED( piValue );
   return E_FAIL;
}

static BOOL IsThemeActiveFail( void )
{
   return FALSE;
}

static BOOL IsAppThemedFail( void )
{
   return FALSE;
}

static HTHEME GetWindowThemeFail( HWND hwnd )
{
   HB_SYMBOL_UNUSED( hwnd );
   return NULL;
}

static HRESULT EnableThemeDialogTextureFail( HWND hwnd, DWORD dwFlags )
{
   HB_SYMBOL_UNUSED( hwnd );
   HB_SYMBOL_UNUSED( dwFlags );
   return E_FAIL;
}

static BOOL IsThemeDialogTextureEnabledFail( HWND hwnd )
{
   HB_SYMBOL_UNUSED( hwnd );
   return FALSE;
}

static DWORD GetThemeAppPropertiesFail( void )
{
   return 0;
}

static void SetThemeAppPropertiesFail( DWORD dwFlags )
{
   HB_SYMBOL_UNUSED( dwFlags );
   return;
}

static HRESULT GetCurrentThemeNameFail( LPWSTR pszThemeFileName,
      int cchMaxNameChars, LPWSTR pszColorBuff, int cchMaxColorChars,
      LPWSTR pszSizeBuff, int cchMaxSizeChars )
{
   HB_SYMBOL_UNUSED( pszThemeFileName );
   HB_SYMBOL_UNUSED( cchMaxNameChars );
   HB_SYMBOL_UNUSED( pszColorBuff );
   HB_SYMBOL_UNUSED( cchMaxColorChars );
   HB_SYMBOL_UNUSED( pszSizeBuff );
   HB_SYMBOL_UNUSED( cchMaxSizeChars );
   return E_FAIL;
}

static HRESULT GetThemeDocumentationPropertyFail( LPCWSTR pszThemeName,
      LPCWSTR pszPropertyName, LPWSTR pszValueBuff, int cchMaxValChars )
{
   HB_SYMBOL_UNUSED( pszThemeName );
   HB_SYMBOL_UNUSED( pszPropertyName );
   HB_SYMBOL_UNUSED( pszValueBuff );
   HB_SYMBOL_UNUSED( cchMaxValChars );
   return E_FAIL;
}

static HRESULT DrawThemeParentBackgroundFail( HWND hwnd, HDC hdc, RECT * prc )
{
   HB_SYMBOL_UNUSED( hwnd );
   HB_SYMBOL_UNUSED( hdc );
   HB_SYMBOL_UNUSED( prc );
   return E_FAIL;
}

static FARPROC GetProc( LPCSTR lpProc, FARPROC pfnFail )
{
   if( m_hThemeDll != NULL )
   {
      FARPROC pProcAddr = GetProcAddress( m_hThemeDll, lpProc );

      if( pProcAddr )
         return pProcAddr;
   }
   return pfnFail;
}

HTHEME hb_OpenThemeData( HWND hwnd, LPCWSTR pszClassList )
{
   PFNOPENTHEMEDATA pfnOpenThemeData =
         ( PFNOPENTHEMEDATA ) GetProc( "OpenThemeData",
         FPROC( OpenThemeDataFail ) );
   return ( *pfnOpenThemeData ) ( hwnd, pszClassList );
}

HRESULT hb_CloseThemeData( HTHEME hTheme )
{
   PFNCLOSETHEMEDATA pfnCloseThemeData =
         ( PFNCLOSETHEMEDATA ) GetProc( "CloseThemeData",
         FPROC( CloseThemeDataFail ) );
   return ( *pfnCloseThemeData ) ( hTheme );
}

HRESULT hb_DrawThemeBackground( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pRect, const RECT * pClipRect )
{
   PFNDRAWTHEMEBACKGROUND pfnDrawThemeBackground =
         ( PFNDRAWTHEMEBACKGROUND ) GetProc( "DrawThemeBackground",
         FPROC( DrawThemeBackgroundFail ) );
   return ( *pfnDrawThemeBackground ) ( hTheme, hdc, iPartId, iStateId, pRect,
         pClipRect );
}

HRESULT hb_DrawThemeText( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, LPCWSTR pszText, int iCharCount, DWORD dwTextFlags,
      DWORD dwTextFlags2, const RECT * pRect )
{
   PFNDRAWTHEMETEXT pfn =
         ( PFNDRAWTHEMETEXT ) GetProc( "DrawThemeText",
         FPROC( DrawThemeTextFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, pszText, iCharCount,
         dwTextFlags, dwTextFlags2, pRect );
}

HRESULT hb_GetThemeBackgroundContentRect( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pBoundingRect,
      RECT * pContentRect )
{
   PFNGETTHEMEBACKGROUNDCONTENTRECT pfn =
         ( PFNGETTHEMEBACKGROUNDCONTENTRECT )
         GetProc( "GetThemeBackgroundContentRect",
         FPROC( GetThemeBackgroundContentRectFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, pBoundingRect,
         pContentRect );
}

HRESULT hb_GetThemeBackgroundExtent( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pContentRect,
      RECT * pExtentRect )
{
   PFNGETTHEMEBACKGROUNDEXTENT pfn =
         ( PFNGETTHEMEBACKGROUNDEXTENT ) GetProc( "GetThemeBackgroundExtent",
         FPROC( GetThemeBackgroundExtentFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, pContentRect,
         pExtentRect );
}

HRESULT hb_GetThemePartSize( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, RECT * pRect, int eSize, SIZE * psz )
{
   PFNGETTHEMEPARTSIZE pfnGetThemePartSize =
         ( PFNGETTHEMEPARTSIZE ) GetProc( "GetThemePartSize",
         FPROC( GetThemePartSizeFail ) );
   return ( *pfnGetThemePartSize ) ( hTheme, hdc, iPartId, iStateId, pRect,
         eSize, psz );
}

HRESULT hb_GetThemeTextExtent( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, LPCWSTR pszText, int iCharCount,
      DWORD dwTextFlags, const RECT * pBoundingRect, RECT * pExtentRect )
{
   PFNGETTHEMETEXTEXTENT pfn =
         ( PFNGETTHEMETEXTEXTENT ) GetProc( "GetThemeTextExtent",
         FPROC( GetThemeTextExtentFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, pszText, iCharCount,
         dwTextFlags, pBoundingRect, pExtentRect );
}

HRESULT hb_GetThemeTextMetrics( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, TEXTMETRIC * ptm )
{
   PFNGETTHEMETEXTMETRICS pfn =
         ( PFNGETTHEMETEXTMETRICS ) GetProc( "GetThemeTextMetrics",
         FPROC( GetThemeTextMetricsFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, ptm );
}

HRESULT hb_GetThemeBackgroundRegion( HTHEME hTheme, HDC hdc,
      int iPartId, int iStateId, const RECT * pRect, HRGN * pRegion )
{
   PFNGETTHEMEBACKGROUNDREGION pfn =
         ( PFNGETTHEMEBACKGROUNDREGION ) GetProc( "GetThemeBackgroundRegion",
         FPROC( GetThemeBackgroundRegionFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, pRect, pRegion );
}

HRESULT hb_HitTestThemeBackground( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, DWORD dwOptions, const RECT * pRect, HRGN hrgn,
      POINT ptTest, WORD * pwHitTestCode )
{
   PFNHITTESTTHEMEBACKGROUND pfn =
         ( PFNHITTESTTHEMEBACKGROUND ) GetProc( "HitTestThemeBackground",
         FPROC( HitTestThemeBackgroundFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, dwOptions, pRect, hrgn,
         ptTest, pwHitTestCode );
}

HRESULT hb_DrawThemeEdge( HTHEME hTheme, HDC hdc, int iPartId, int iStateId,
      const RECT * pDestRect, UINT uEdge, UINT uFlags, RECT * pContentRect )
{
   PFNDRAWTHEMEEDGE pfn =
         ( PFNDRAWTHEMEEDGE ) GetProc( "DrawThemeEdge",
         FPROC( DrawThemeEdgeFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, pDestRect, uEdge, uFlags,
         pContentRect );
}

HRESULT hb_DrawThemeIcon( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, const RECT * pRect, HIMAGELIST himl, int iImageIndex )
{
   PFNDRAWTHEMEICON pfn =
         ( PFNDRAWTHEMEICON ) GetProc( "DrawThemeIcon",
         FPROC( DrawThemeIconFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, pRect, himl,
         iImageIndex );
}

BOOL hb_IsThemePartDefined( HTHEME hTheme, int iPartId, int iStateId )
{
   PFNISTHEMEPARTDEFINED pfn =
         ( PFNISTHEMEPARTDEFINED ) GetProc( "IsThemePartDefined",
         FPROC( IsThemePartDefinedFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId );
}

BOOL hb_IsThemeBackgroundPartiallyTransparent( HTHEME hTheme,
      int iPartId, int iStateId )
{
   PFNISTHEMEBACKGROUNDPARTIALLYTRANSPARENT pfn =
         ( PFNISTHEMEBACKGROUNDPARTIALLYTRANSPARENT )
         GetProc( "IsThemeBackgroundPartiallyTransparent",
         FPROC( IsThemeBackgroundPartiallyTransparentFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId );
}

HRESULT hb_GetThemeColor( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, COLORREF * pColor )
{
   PFNGETTHEMECOLOR pfn =
         ( PFNGETTHEMECOLOR ) GetProc( "GetThemeColor",
         FPROC( GetThemeColorFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId, iPropId, pColor );
}

HRESULT hb_GetThemeMetric( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, int iPropId, int *piVal )
{
   PFNGETTHEMEMETRIC pfn =
         ( PFNGETTHEMEMETRIC ) GetProc( "GetThemeMetric",
         FPROC( GetThemeMetricFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, iPropId, piVal );
}

HRESULT hb_GetThemeString( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, LPWSTR pszBuff, int cchMaxBuffChars )
{
   PFNGETTHEMESTRING pfn =
         ( PFNGETTHEMESTRING ) GetProc( "GetThemeString",
         FPROC( GetThemeStringFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId, iPropId, pszBuff,
         cchMaxBuffChars );
}

HRESULT hb_GetThemeBool( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, BOOL * pfVal )
{
   PFNGETTHEMEBOOL pfn =
         ( PFNGETTHEMEBOOL ) GetProc( "GetThemeBool",
         FPROC( GetThemeBoolFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId, iPropId, pfVal );
}

HRESULT hb_GetThemeInt( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, int *piVal )
{
   PFNGETTHEMEINT pfn =
         ( PFNGETTHEMEINT ) GetProc( "GetThemeInt",
         FPROC( GetThemeIntFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId, iPropId, piVal );
}

HRESULT hb_GetThemeEnumValue( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, int *piVal )
{
   PFNGETTHEMEENUMVALUE pfn =
         ( PFNGETTHEMEENUMVALUE ) GetProc( "GetThemeEnumValue",
         FPROC( GetThemeEnumValueFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId, iPropId, piVal );
}

HRESULT hb_GetThemePosition( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, POINT * pPoint )
{
   PFNGETTHEMEPOSITION pfn =
         ( PFNGETTHEMEPOSITION ) GetProc( "GetThemePosition",
         FPROC( GetThemePositionFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId, iPropId, pPoint );
}

HRESULT hb_GetThemeFont( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, int iPropId, LOGFONT * pFont )
{
   PFNGETTHEMEFONT pfn =
         ( PFNGETTHEMEFONT ) GetProc( "GetThemeFont",
         FPROC( GetThemeFontFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, iPropId, pFont );
}

HRESULT hb_GetThemeRect( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, RECT * pRect )
{
   PFNGETTHEMERECT pfn =
         ( PFNGETTHEMERECT ) GetProc( "GetThemeRect",
         FPROC( GetThemeRectFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId, iPropId, pRect );
}

HRESULT hb_GetThemeMargins( HTHEME hTheme, HDC hdc, int iPartId,
      int iStateId, int iPropId, RECT * prc, MARGINS * pMargins )
{
   PFNGETTHEMEMARGINS pfn =
         ( PFNGETTHEMEMARGINS ) GetProc( "GetThemeMargins",
         FPROC( GetThemeMarginsFail ) );
   return ( *pfn ) ( hTheme, hdc, iPartId, iStateId, iPropId, prc, pMargins );
}

HRESULT hb_GetThemeIntList( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, INTLIST * pIntList )
{
   PFNGETTHEMEINTLIST pfn =
         ( PFNGETTHEMEINTLIST ) GetProc( "GetThemeIntList",
         FPROC( GetThemeIntListFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId, iPropId, pIntList );
}

HRESULT hb_GetThemePropertyOrigin( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, int *pOrigin )
{
   PFNGETTHEMEPROPERTYORIGIN pfn =
         ( PFNGETTHEMEPROPERTYORIGIN ) GetProc( "GetThemePropertyOrigin",
         FPROC( GetThemePropertyOriginFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId, iPropId, pOrigin );
}

HRESULT hb_SetWindowTheme( HWND hwnd, LPCWSTR pszSubAppName,
      LPCWSTR pszSubIdList )
{
   PFNSETWINDOWTHEME pfn =
         ( PFNSETWINDOWTHEME ) GetProc( "SetWindowTheme",
         FPROC( SetWindowThemeFail ) );
   return ( *pfn ) ( hwnd, pszSubAppName, pszSubIdList );
}

HRESULT hb_GetThemeFilename( HTHEME hTheme, int iPartId,
      int iStateId, int iPropId, LPWSTR pszThemeFileName,
      int cchMaxBuffChars )
{
   PFNGETTHEMEFILENAME pfn =
         ( PFNGETTHEMEFILENAME ) GetProc( "GetThemeFilename",
         FPROC( GetThemeFilenameFail ) );
   return ( *pfn ) ( hTheme, iPartId, iStateId, iPropId, pszThemeFileName,
         cchMaxBuffChars );
}

COLORREF hb_GetThemeSysColor( HTHEME hTheme, int iColorId )
{
   PFNGETTHEMESYSCOLOR pfn =
         ( PFNGETTHEMESYSCOLOR ) GetProc( "GetThemeSysColor",
         FPROC( GetThemeSysColorFail ) );
   return ( *pfn ) ( hTheme, iColorId );
}

HBRUSH hb_GetThemeSysColorBrush( HTHEME hTheme, int iColorId )
{
   PFNGETTHEMESYSCOLORBRUSH pfn =
         ( PFNGETTHEMESYSCOLORBRUSH ) GetProc( "GetThemeSysColorBrush",
         FPROC( GetThemeSysColorBrushFail ) );
   return ( *pfn ) ( hTheme, iColorId );
}

BOOL hb_GetThemeSysBool( HTHEME hTheme, int iBoolId )
{
   PFNGETTHEMESYSBOOL pfn =
         ( PFNGETTHEMESYSBOOL ) GetProc( "GetThemeSysBool",
         FPROC( GetThemeSysBoolFail ) );
   return ( *pfn ) ( hTheme, iBoolId );
}

int hb_GetThemeSysSize( HTHEME hTheme, int iSizeId )
{
   PFNGETTHEMESYSSIZE pfn =
         ( PFNGETTHEMESYSSIZE ) GetProc( "GetThemeSysSize",
         FPROC( GetThemeSysSizeFail ) );
   return ( *pfn ) ( hTheme, iSizeId );
}

HRESULT hb_GetThemeSysFont( HTHEME hTheme, int iFontId, LOGFONT * plf )
{
   PFNGETTHEMESYSFONT pfn =
         ( PFNGETTHEMESYSFONT ) GetProc( "GetThemeSysFont",
         FPROC( GetThemeSysFontFail ) );
   return ( *pfn ) ( hTheme, iFontId, plf );
}

HRESULT hb_GetThemeSysString( HTHEME hTheme, int iStringId,
      LPWSTR pszStringBuff, int cchMaxStringChars )
{
   PFNGETTHEMESYSSTRING pfn =
         ( PFNGETTHEMESYSSTRING ) GetProc( "GetThemeSysString",
         FPROC( GetThemeSysStringFail ) );
   return ( *pfn ) ( hTheme, iStringId, pszStringBuff, cchMaxStringChars );
}

HRESULT hb_GetThemeSysInt( HTHEME hTheme, int iIntId, int *piValue )
{
   PFNGETTHEMESYSINT pfn =
         ( PFNGETTHEMESYSINT ) GetProc( "GetThemeSysInt",
         FPROC( GetThemeSysIntFail ) );
   return ( *pfn ) ( hTheme, iIntId, piValue );
}

BOOL hb_IsThemeActive( void )
{
   PFNISTHEMEACTIVE pfn =
         ( PFNISTHEMEACTIVE ) GetProc( "IsThemeActive",
         FPROC( IsThemeActiveFail ) );
   return ( *pfn ) (  );
}

BOOL hb_IsAppThemed( void )
{
   PFNISAPPTHEMED pfnIsAppThemed =
         ( PFNISAPPTHEMED ) GetProc( "IsAppThemed",
         FPROC( IsAppThemedFail ) );
   return ( *pfnIsAppThemed ) (  );
}

HTHEME hb_GetWindowTheme( HWND hwnd )
{
   PFNGETWINDOWTHEME pfn =
         ( PFNGETWINDOWTHEME ) GetProc( "GetWindowTheme",
         FPROC( GetWindowThemeFail ) );
   return ( *pfn ) ( hwnd );
}

HRESULT hb_EnableThemeDialogTexture( HWND hwnd, DWORD dwFlags )
{
   PFNENABLETHEMEDIALOGTEXTURE pfn =
         ( PFNENABLETHEMEDIALOGTEXTURE ) GetProc( "EnableThemeDialogTexture",
         FPROC( EnableThemeDialogTextureFail ) );
   return ( *pfn ) ( hwnd, dwFlags );
}

BOOL hb_IsThemeDialogTextureEnabled( HWND hwnd )
{
   PFNISTHEMEDIALOGTEXTUREENABLED pfn =
         ( PFNISTHEMEDIALOGTEXTUREENABLED )
         GetProc( "IsThemeDialogTextureEnabled",
         FPROC( IsThemeDialogTextureEnabledFail ) );
   return ( *pfn ) ( hwnd );
}

DWORD hb_GetThemeAppProperties( void )
{
   PFNGETTHEMEAPPPROPERTIES pfn =
         ( PFNGETTHEMEAPPPROPERTIES ) GetProc( "GetThemeAppProperties",
         FPROC( GetThemeAppPropertiesFail ) );
   return ( *pfn ) (  );
}

void hb_SetThemeAppProperties( DWORD dwFlags )
{
   PFNSETTHEMEAPPPROPERTIES pfn =
         ( PFNSETTHEMEAPPPROPERTIES ) GetProc( "SetThemeAppProperties",
         FPROC( SetThemeAppPropertiesFail ) );
   ( *pfn ) ( dwFlags );
}

HRESULT hb_GetCurrentThemeName( LPWSTR pszThemeFileName, int cchMaxNameChars,
      LPWSTR pszColorBuff, int cchMaxColorChars,
      LPWSTR pszSizeBuff, int cchMaxSizeChars )
{
   PFNGETCURRENTTHEMENAME pfn =
         ( PFNGETCURRENTTHEMENAME ) GetProc( "GetCurrentThemeName",
         FPROC( GetCurrentThemeNameFail ) );
   return ( *pfn ) ( pszThemeFileName, cchMaxNameChars, pszColorBuff,
         cchMaxColorChars, pszSizeBuff, cchMaxSizeChars );
}

HRESULT hb_GetThemeDocumentationProperty( LPCWSTR pszThemeName,
      LPCWSTR pszPropertyName, LPWSTR pszValueBuff, int cchMaxValChars )
{
   PFNGETTHEMEDOCUMENTATIONPROPERTY pfn =
         ( PFNGETTHEMEDOCUMENTATIONPROPERTY )
         GetProc( "GetThemeDocumentationProperty",
         FPROC( GetThemeDocumentationPropertyFail ) );
   return ( *pfn ) ( pszThemeName, pszPropertyName, pszValueBuff,
         cchMaxValChars );
}

HRESULT hb_DrawThemeParentBackground( HWND hwnd, HDC hdc, RECT * prc )
{
   PFNDRAWTHEMEPARENTBACKGROUND pfn =
         ( PFNDRAWTHEMEPARENTBACKGROUND )
         GetProc( "DrawThemeParentBackground",
         FPROC( DrawThemeParentBackgroundFail ) );
   return ( *pfn ) ( hwnd, hdc, prc );
}

HRESULT hb_EnableTheming( BOOL fEnable )
{
   PFNENABLETHEMING pfn =
         ( PFNENABLETHEMING ) GetProc( "EnableTheming",
         FPROC( EnableThemingFail ) );
   return ( *pfn ) ( fEnable );
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
   m_hThemeDll = LoadLibrary( TEXT( "UxTheme.dll" ) );

   if( m_hThemeDll )
      ThemeLibLoaded = TRUE;
}

HB_FUNC( HWG_ENDTHEMELIB )
{
   if( m_hThemeDll != NULL )
      FreeLibrary( m_hThemeDll );

   m_hThemeDll = NULL;
   ThemeLibLoaded = FALSE;
}

HB_FUNC( HWG_ONNOTIFYCUSTOMDRAW )
{
   /* Use hb_parnint to get full 64-bit LPARAM on 64-bit builds */
   LPARAM lParam = ( LPARAM ) hb_parnint( 1 );
   /* OnNotifyCustomDraw returns LRESULT (64-bit on x64) - use hb_retnint */
   hb_retnint( ( HB_MAXINT ) OnNotifyCustomDraw( lParam ) );
}

/*

LRESULT OnButtonDraw( LPARAM  lParam)
{
      LPDRAWITEMSTRUCT lpDIS = (LPDRAWITEMSTRUCT) lParam;

//            if(lpDIS->CtlID != IDC_OWNERDRAW_BTN)
//                return (0);

      HDC dc = lpDIS->hDC;
            HTHEME hTheme = hb_OpenThemeData (m_hWnd, L"BUTTON");

      // button state
      BOOL bIsPressed = (lpDIS->itemState & ODS_SELECTED);
      BOOL bIsFocused  = (lpDIS->itemState & ODS_FOCUS);
      BOOL bIsDisabled = (lpDIS->itemState & ODS_DISABLED);
      BOOL bDrawFocusRect = !(lpDIS->itemState & ODS_NOFOCUSRECT);
      char sTitle[100];

            RECT captionRect ;

            BOOL bHasTitle ;


      RECT itemRect = lpDIS->rcItem;
            if(hTheme)
               Themed = TRUE;


      SetBkMode(dc, TRANSPARENT);

      // Prepare draw... paint button background

      if(Themed)
      {
        DWORD state = (bIsPressed)?PBS_PRESSED:PBS_NORMAL;

        if(state == PBS_NORMAL)
          {
          if(bIsFocused)
            state = PBS_DEFAULTED;
          if(bMouseOverButton)
            state = PBS_HOT;
          }
                hb_DrawThemeBackground(hTheme, dc, BP_PUSHBUTTON, state, &itemRect, NULL);
      }
      else
      {

                COLORREF crColor ;

                HBRUSH  brBackground ;

        if (bIsFocused)
          {
          HBRUSH br = CreateSolidBrush(RGB(0,0,0));
          FrameRect(dc, &itemRect, br);
          InflateRect(&itemRect, -1, -1);
          DeleteObject(br);
          } // if

                crColor = GetSysColor(COLOR_BTNFACE);

                brBackground = CreateSolidBrush(crColor);

        FillRect(dc, &itemRect, brBackground);

        DeleteObject(brBackground);

        // Draw pressed button
        if (bIsPressed)
        {
          HBRUSH brBtnShadow = CreateSolidBrush(GetSysColor(COLOR_BTNSHADOW));
          FrameRect(dc, &itemRect, brBtnShadow);
          DeleteObject(brBtnShadow);
        }

                else
        {
            UINT uState = DFCS_BUTTONPUSH |
                          ((bMouseOverButton) ? DFCS_HOT : 0) |
                          ((bIsPressed) ? DFCS_PUSHED : 0);

          DrawFrameControl(dc, &itemRect, DFC_BUTTON, uState);
        } // else
      }
      // Read the button's title

      GetWindowText(GetDlgItem(hDlg, IDC_OWNERDRAW_BTN), sTitle, 100);

      captionRect = lpDIS->rcItem;

      // Draw the icon
      bHasTitle = (sTitle[0] != '\0');

      DrawTheIcon(GetDlgItem(hDlg, IDC_OWNERDRAW_BTN), &dc, bHasTitle, &lpDIS->rcItem, &captionRect, bIsPressed, bIsDisabled, iStyle);

      // Write the button title (if any)
      if (bHasTitle)
      {   // Draw the button's title
          // If button is pressed then "press" title also
          if (bIsPressed && !Themed)
             OffsetRect(&captionRect, 1, 1);

        // Center text
        RECT centerRect = captionRect;
        DrawText(dc, sTitle, -1, &captionRect, DT_WORDBREAK | DT_CENTER | DT_CALCRECT);
        LONG captionRectWidth = captionRect.right - captionRect.left;
        LONG captionRectHeight = captionRect.bottom - captionRect.top;
        LONG centerRectWidth = centerRect.right - centerRect.left;
        LONG centerRectHeight = centerRect.bottom - centerRect.top;
        OffsetRect(&captionRect, (centerRectWidth - captionRectWidth)/2, (centerRectHeight - captionRectHeight)/2);

        if(Themed)
        {
          // convert title to UNICODE obviously you don't need to do this if you are a UNICODE app.
          int nTextLen = strlen(sTitle);
          int mlen = MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, sTitle, nTextLen + 1, NULL, 0);
          WCHAR* output = new WCHAR[mlen];
          if(output)
          {
            MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, sTitle, nTextLen + 1, output, mlen);
                        hb_DrawThemeText( hTheme, dc, BP_PUSHBUTTON, PBS_NORMAL,
                    output, wcslen(output),
                    DT_CENTER | DT_VCENTER | DT_SINGLELINE,
                    0, &captionRect);
            delete output;
          }
        }
        else
        {
          SetBkMode(dc, TRANSPARENT);

          if (bIsDisabled)
            {
            OffsetRect(&captionRect, 1, 1);
            SetTextColor(dc, ::GetSysColor(COLOR_3DHILIGHT));
            DrawText(dc, sTitle, -1, &captionRect, DT_WORDBREAK | DT_CENTER);
            OffsetRect(&captionRect, -1, -1);
            SetTextColor(dc, ::GetSysColor(COLOR_3DSHADOW));
            DrawText(dc, sTitle, -1, &captionRect, DT_WORDBREAK | DT_CENTER);
            } // if
          else
            {
            SetTextColor(dc, ::GetSysColor(COLOR_BTNTEXT));
            SetBkColor(dc, ::GetSysColor(COLOR_BTNFACE));
            DrawText(dc, sTitle, -1, &captionRect, DT_WORDBREAK | DT_CENTER);
            } // if
          } // if
      }

      // Draw the focus rect
      if (bIsFocused && bDrawFocusRect)
        {
        RECT focusRect = itemRect;
        InflateRect(&focusRect, -3, -3);
        DrawFocusRect(dc, &focusRect);
        } // if
      return (TRUE);
      }
  */

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
   LPCSTR pText = hb_parc( 2 );
   HTHEME p;
   int mlen = MultiByteToWideChar( CP_ACP, MB_PRECOMPOSED, pText, -1, NULL, 0 );
   WCHAR *output = ( WCHAR * ) hb_xgrab( mlen * sizeof( WCHAR ) );

   MultiByteToWideChar( CP_ACP, MB_PRECOMPOSED, pText, -1, output, mlen );
   p = hb_OpenThemeData( hwnd, output );
   hb_xfree( output );
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
   LPCSTR pText = hb_parc( 5 );
   DWORD dwTextFlags = ( DWORD ) hb_parnl( 6 );
   DWORD dwTextFlags2 = ( DWORD ) hb_parnl( 7 );
   RECT pRect = {0};
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
   //LPCWSTR pszSubAppName = hb_parc(2);
   //LPCWSTR pszSubIdList = hb_parc(3);
   int ienable = hb_parni(2);
   //HRESULT hres ;
   //BOOL ret = FALSE;
   OSVERSIONINFO ovi;
   ovi.dwOSVersionInfoSize = sizeof ovi;
   ovi.dwMajorVersion = 0;
   ovi.dwMinorVersion = 0;
   GetVersionEx(&ovi);
   if (ovi.dwMajorVersion >= 5 && ovi.dwMinorVersion==1 )
      {
      //Windows XP detected
      if ( ienable == 0 )
         hb_SetWindowTheme( hwnd, L" ", L" " ) ; // pszSubAppName,L pszSubIdList) ;
      else 
         hb_SetWindowTheme( hwnd, NULL, NULL) ;
      }   
}

HB_FUNC( HWG_GETWINDOWTHEME )
{
   //BOOL ret = FALSE;
   OSVERSIONINFO ovi ;
   ovi.dwOSVersionInfoSize = sizeof ovi;
   ovi.dwMajorVersion = 0;
   ovi.dwMinorVersion = 0;
   GetVersionEx(&ovi);
   if (ovi.dwMajorVersion >= 5 && ovi.dwMinorVersion==1 )
   {
     //Windows XP detected
      HTHEME hTheme; // = (HTHEME) hb_parptr(1) ;
      hTheme = hb_GetWindowTheme( (HWND) HB_PARHANDLE( 1 ) );
      HB_RETHANDLE ( hTheme );
   }
   else
      HB_RETHANDLE ( 0 );
}

/* ========================= EOF of theme.c ============================= */