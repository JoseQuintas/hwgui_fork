/*
 * $Id: theme.c,v 1.1 2007-07-05 14:46:30 lculik Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Theme related functions
 *
 * Copyright 2007 Luiz Rafael Culik Guimaraes <luiz at xharbour.com.br >
 * www - http://sites.uol.com.br/culikr/
*/


#include <windows.h>
#include <commctrl.h>
#include <uxtheme.h>
//#include <tmschema.h>

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
#define ST_ALIGN_HORIZ       0           // Icon/bitmap on the left, text on the right
#define ST_ALIGN_VERT        1           // Icon/bitmap on the top, text on the bottom
#define ST_ALIGN_HORIZ_RIGHT 2           // Icon/bitmap on the right, text on the left
#define ST_ALIGN_OVERLAP     3           // Icon/bitmap on the same space as text
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


#include <hbapi.h>
    BOOL Themed = FALSE;
    HMODULE m_hThemeDll;
    BOOL ThemeLibLoaded = FALSE;
    extern PHB_ITEM Rect2Array( RECT *rc  );
    extern BOOL Array2Rect(PHB_ITEM aRect, RECT *rc )    ;
    void draw_bitmap (HDC hDC, const  RECT *Rect, DWORD style,HWND m_hWnd);
    void draw_icon (HDC hDC, const  RECT *Rect, DWORD style,HWND m_hWnd);
    static int image_top (int cy, const RECT *Rect, DWORD style);
    static int image_left (int cx, const RECT *Rect, DWORD style);

	void* GetProc(LPCSTR szProc, void* pfnFail);

    typedef HTHEME(__stdcall *PFNOPENTHEMEDATA)(HWND hwnd, LPCWSTR pszClassList);

	typedef HRESULT(__stdcall *PFNCLOSETHEMEDATA)(HTHEME hTheme);

	typedef HRESULT(__stdcall *PFNDRAWTHEMEBACKGROUND)(HTHEME hTheme, HDC hdc,
		int iPartId, int iStateId, const RECT *pRect,  const RECT *pClipRect);


	typedef HRESULT (__stdcall *PFNDRAWTHEMETEXT)(HTHEME hTheme, HDC hdc, int iPartId,
		int iStateId, LPCWSTR pszText, int iCharCount, DWORD dwTextFlags,
		DWORD dwTextFlags2, const RECT *pRect);

	typedef HRESULT (__stdcall *PFNGETTHEMEBACKGROUNDCONTENTRECT)(HTHEME hTheme,  HDC hdc,
		int iPartId, int iStateId,  const RECT *pBoundingRect,
		RECT *pContentRect);
	typedef HRESULT (__stdcall *PFNGETTHEMEBACKGROUNDEXTENT)(HTHEME hTheme,  HDC hdc,
		int iPartId, int iStateId, const RECT *pContentRect,
		RECT *pExtentRect);

	typedef HRESULT(__stdcall *PFNGETTHEMEPARTSIZE)(HTHEME hTheme, HDC hdc,
		int iPartId, int iStateId, RECT * pRect, enum THEMESIZE eSize,  SIZE *psz);

	typedef HRESULT (__stdcall *PFNGETTHEMETEXTEXTENT)(HTHEME hTheme, HDC hdc,
		int iPartId, int iStateId, LPCWSTR pszText, int iCharCount,
		DWORD dwTextFlags,  const RECT *pBoundingRect,
		RECT *pExtentRect);

	typedef HRESULT (__stdcall *PFNGETTHEMETEXTMETRICS)(HTHEME hTheme,  HDC hdc,
		int iPartId, int iStateId,  TEXTMETRIC* ptm);

	typedef HRESULT (__stdcall *PFNGETTHEMEBACKGROUNDREGION)(HTHEME hTheme,  HDC hdc,
		int iPartId, int iStateId, const RECT *pRect,  HRGN *pRegion);

	typedef HRESULT (__stdcall *PFNHITTESTTHEMEBACKGROUND)(HTHEME hTheme,  HDC hdc, int iPartId,
		int iStateId, DWORD dwOptions, const RECT *pRect,  HRGN hrgn,
		POINT ptTest,  WORD *pwHitTestCode);

	typedef HRESULT (__stdcall *PFNDRAWTHEMEEDGE)(HTHEME hTheme, HDC hdc, int iPartId, int iStateId,
		const RECT *pDestRect, UINT uEdge, UINT uFlags,   RECT *pContentRect);

	typedef HRESULT (__stdcall *PFNDRAWTHEMEICON)(HTHEME hTheme, HDC hdc, int iPartId,
		int iStateId, const RECT *pRect, HIMAGELIST himl, int iImageIndex);

	typedef BOOL (__stdcall *PFNISTHEMEPARTDEFINED)(HTHEME hTheme, int iPartId,
		int iStateId);

	typedef BOOL (__stdcall *PFNISTHEMEBACKGROUNDPARTIALLYTRANSPARENT)(HTHEME hTheme,
		int iPartId, int iStateId);
	typedef HRESULT (__stdcall *PFNGETTHEMECOLOR)(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  COLORREF *pColor);

	typedef HRESULT (__stdcall *PFNGETTHEMEMETRIC)(HTHEME hTheme,  HDC hdc, int iPartId,
		int iStateId, int iPropId,  int *piVal);

	typedef HRESULT (__stdcall *PFNGETTHEMESTRING)(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  LPWSTR pszBuff, int cchMaxBuffChars);
	typedef HRESULT (__stdcall *PFNGETTHEMEBOOL)(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  BOOL *pfVal);

	typedef HRESULT (__stdcall *PFNGETTHEMEINT)(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  int *piVal);

	typedef HRESULT (__stdcall *PFNGETTHEMEENUMVALUE)(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  int *piVal);

	typedef HRESULT (__stdcall *PFNGETTHEMEPOSITION)(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  POINT *pPoint);
	typedef HRESULT (__stdcall *PFNGETTHEMEFONT)(HTHEME hTheme,  HDC hdc, int iPartId,
		int iStateId, int iPropId,  LOGFONT *pFont);
	typedef HRESULT (__stdcall *PFNGETTHEMERECT)(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  RECT *pRect);
	typedef HRESULT (__stdcall *PFNGETTHEMEMARGINS)(HTHEME hTheme,  HDC hdc, int iPartId,
		int iStateId, int iPropId,  RECT *prc,  MARGINS *pMargins);

	typedef HRESULT (__stdcall *PFNGETTHEMEINTLIST)(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  INTLIST *pIntList);

	typedef HRESULT (__stdcall *PFNGETTHEMEPROPERTYORIGIN)(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  enum PROPERTYORIGIN *pOrigin);

	typedef HRESULT (__stdcall *PFNSETWINDOWTHEME)(HWND hwnd, LPCWSTR pszSubAppName,
		LPCWSTR pszSubIdList);

	typedef HRESULT (__stdcall *PFNGETTHEMEFILENAME)(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  LPWSTR pszThemeFileName, int cchMaxBuffChars);
	typedef COLORREF (__stdcall *PFNGETTHEMESYSCOLOR)(HTHEME hTheme, int iColorId);

	typedef HBRUSH (__stdcall *PFNGETTHEMESYSCOLORBRUSH)(HTHEME hTheme, int iColorId);

	typedef BOOL (__stdcall *PFNGETTHEMESYSBOOL)(HTHEME hTheme, int iBoolId);
	typedef int (__stdcall *PFNGETTHEMESYSSIZE)(HTHEME hTheme, int iSizeId);
	typedef HRESULT (__stdcall *PFNGETTHEMESYSFONT)(HTHEME hTheme, int iFontId,  LOGFONT *plf);

	typedef HRESULT (__stdcall *PFNGETTHEMESYSSTRING)(HTHEME hTheme, int iStringId,
		LPWSTR pszStringBuff, int cchMaxStringChars);
	typedef HRESULT (__stdcall *PFNGETTHEMESYSINT)(HTHEME hTheme, int iIntId, int *piValue);

	typedef BOOL (__stdcall *PFNISTHEMEACTIVE)(void);

	typedef BOOL(__stdcall *PFNISAPPTHEMED)(void);
	typedef HTHEME (__stdcall *PFNGETWINDOWTHEME)(HWND hwnd);
	typedef HRESULT (__stdcall *PFNENABLETHEMEDIALOGTEXTURE)(HWND hwnd, DWORD dwFlags);
	typedef BOOL (__stdcall *PFNISTHEMEDIALOGTEXTUREENABLED)(HWND hwnd);
	typedef DWORD (__stdcall *PFNGETTHEMEAPPPROPERTIES)(void);

	typedef void (__stdcall *PFNSETTHEMEAPPPROPERTIES)(DWORD dwFlags);

	typedef HRESULT (__stdcall *PFNGETCURRENTTHEMENAME)(
		LPWSTR pszThemeFileName, int cchMaxNameChars,
		LPWSTR pszColorBuff, int cchMaxColorChars,
		LPWSTR pszSizeBuff, int cchMaxSizeChars);
	typedef HRESULT (__stdcall *PFNGETTHEMEDOCUMENTATIONPROPERTY)(LPCWSTR pszThemeName,
		LPCWSTR pszPropertyName,  LPWSTR pszValueBuff, int cchMaxValChars);

	typedef HRESULT (__stdcall *PFNDRAWTHEMEPARENTBACKGROUND)(HWND hwnd, HDC hdc,  RECT* prc);
	typedef HRESULT (__stdcall *PFNENABLETHEMING)(BOOL fEnable);


	static HRESULT EnableThemingFail(BOOL fEnable)
	{return E_FAIL;}

    static HRESULT DrawThemeBackgroundFail(HTHEME a, HDC s, int d, int f, const RECT * g, const RECT * h)
	{return E_FAIL;}
    static HRESULT CloseThemeDataFail(HTHEME s)
	{return E_FAIL;}
    static HTHEME OpenThemeDataFail(HWND s , LPCWSTR d)
	{return NULL;}

    static HRESULT DrawThemeTextFail(HTHEME a, HDC s, int d, int f, LPCWSTR g, int h, DWORD j, DWORD k, const RECT* z)
	{return E_FAIL;}

	static HRESULT GetThemeBackgroundContentRectFail(HTHEME hTheme,  HDC hdc,
		int iPartId, int iStateId,  const RECT *pBoundingRect,
		RECT *pContentRect)
	{return E_FAIL;}

	static HRESULT GetThemeBackgroundExtentFail(HTHEME hTheme,  HDC hdc,
		int iPartId, int iStateId, const RECT *pContentRect,
		RECT *pExtentRect)
	{return E_FAIL;}

    static HRESULT GetThemePartSizeFail(HTHEME a, HDC s, int d, int f, RECT * g, enum THEMESIZE h, SIZE * j)
	{return E_FAIL;}

	static HRESULT GetThemeTextExtentFail(HTHEME hTheme, HDC hdc,
		int iPartId, int iStateId, LPCWSTR pszText, int iCharCount,
		DWORD dwTextFlags,  const RECT *pBoundingRect,
		RECT *pExtentRect)
	{return E_FAIL;}

	static HRESULT GetThemeTextMetricsFail(HTHEME hTheme,  HDC hdc,
		int iPartId, int iStateId,  TEXTMETRIC* ptm)
	{return E_FAIL;}

	static HRESULT GetThemeBackgroundRegionFail(HTHEME hTheme,  HDC hdc,
		int iPartId, int iStateId, const RECT *pRect,  HRGN *pRegion)
	{return E_FAIL;}

	static HRESULT HitTestThemeBackgroundFail(HTHEME hTheme,  HDC hdc, int iPartId,
		int iStateId, DWORD dwOptions, const RECT *pRect,  HRGN hrgn,
		POINT ptTest,  WORD *pwHitTestCode)
	{return E_FAIL;}

	static HRESULT DrawThemeEdgeFail(HTHEME hTheme, HDC hdc, int iPartId, int iStateId,
		const RECT *pDestRect, UINT uEdge, UINT uFlags,   RECT *pContentRect)
	{return E_FAIL;}

	static HRESULT DrawThemeIconFail(HTHEME hTheme, HDC hdc, int iPartId,
		int iStateId, const RECT *pRect, HIMAGELIST himl, int iImageIndex)
	{return E_FAIL;}

	static BOOL IsThemePartDefinedFail(HTHEME hTheme, int iPartId,
		int iStateId)
	{return FALSE;}

	static BOOL IsThemeBackgroundPartiallyTransparentFail(HTHEME hTheme,
		int iPartId, int iStateId)
	{return FALSE;}


	static HRESULT GetThemeColorFail(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  COLORREF *pColor)
	{return E_FAIL;}

	static HRESULT GetThemeMetricFail(HTHEME hTheme,  HDC hdc, int iPartId,
		int iStateId, int iPropId,  int *piVal)
	{return E_FAIL;}

	static HRESULT GetThemeStringFail(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  LPWSTR pszBuff, int cchMaxBuffChars)
	{return E_FAIL;}


	static HRESULT GetThemeBoolFail(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  BOOL *pfVal)
	{return E_FAIL;}

	static HRESULT GetThemeIntFail(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  int *piVal)
	{return E_FAIL;}

	static HRESULT GetThemeEnumValueFail(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  int *piVal)
	{return E_FAIL;}

	static HRESULT GetThemePositionFail(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  POINT *pPoint)
	{return E_FAIL;}


	static HRESULT GetThemeFontFail(HTHEME hTheme,  HDC hdc, int iPartId,
		int iStateId, int iPropId,  LOGFONT *pFont)
	{return E_FAIL;}


	static HRESULT GetThemeRectFail(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  RECT *pRect)
	{return E_FAIL;}

	static HRESULT GetThemeMarginsFail(HTHEME hTheme,  HDC hdc, int iPartId,
		int iStateId, int iPropId,  RECT *prc,  MARGINS *pMargins)
	{return E_FAIL;}

	static HRESULT GetThemeIntListFail(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  INTLIST *pIntList)
	{return E_FAIL;}

	static HRESULT GetThemePropertyOriginFail(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  enum PROPERTYORIGIN *pOrigin)
	{return E_FAIL;}

	static HRESULT SetWindowThemeFail(HWND hwnd, LPCWSTR pszSubAppName,
		LPCWSTR pszSubIdList)
	{return E_FAIL;}

	static HRESULT GetThemeFilenameFail(HTHEME hTheme, int iPartId,
		int iStateId, int iPropId,  LPWSTR pszThemeFileName, int cchMaxBuffChars)
	{return E_FAIL;}

	static HRESULT GetThemeSysFontFail(HTHEME hTheme, int iFontId,  LOGFONT *plf)
	{return E_FAIL;}

	static COLORREF GetThemeSysColorFail(HTHEME hTheme, int iColorId)
	{return RGB(255,255,255);}

	static HBRUSH GetThemeSysColorBrushFail(HTHEME hTheme, int iColorId)
	{return NULL;}

	static BOOL GetThemeSysBoolFail(HTHEME hTheme, int iBoolId)
	{return FALSE;}


	static int GetThemeSysSizeFail(HTHEME hTheme, int iSizeId)
	{return 0;}


	static HRESULT GetThemeSysStringFail(HTHEME hTheme, int iStringId,
		LPWSTR pszStringBuff, int cchMaxStringChars)
	{return E_FAIL;}

	static HRESULT GetThemeSysIntFail(HTHEME hTheme, int iIntId, int *piValue)
	{return E_FAIL;}

	static BOOL IsThemeActiveFail()
	{return FALSE;}

	static BOOL IsAppThemedFail()
	{return FALSE;}


	static HTHEME GetWindowThemeFail(HWND hwnd)
	{return NULL;}


	static HRESULT EnableThemeDialogTextureFail(HWND hwnd, DWORD dwFlags)
	{return E_FAIL;}

	static BOOL IsThemeDialogTextureEnabledFail(HWND hwnd)
	{return FALSE;}


	static DWORD GetThemeAppPropertiesFail()
	{return 0;}

	static void SetThemeAppPropertiesFail(DWORD dwFlags)
	{return;}

	static HRESULT GetCurrentThemeNameFail(
		LPWSTR pszThemeFileName, int cchMaxNameChars,
		LPWSTR pszColorBuff, int cchMaxColorChars,
		LPWSTR pszSizeBuff, int cchMaxSizeChars)
	{return E_FAIL;}


	static HRESULT GetThemeDocumentationPropertyFail(LPCWSTR pszThemeName,
		LPCWSTR pszPropertyName,  LPWSTR pszValueBuff, int cchMaxValChars)
	{return E_FAIL;}

	static HRESULT DrawThemeParentBackgroundFail(HWND hwnd, HDC hdc,  RECT* prc)
	{return E_FAIL;}




void* GetProc(LPCSTR szProc, void* pfnFail)
{
	void* pRet = pfnFail;
	if (m_hThemeDll != NULL)
		pRet = GetProcAddress(m_hThemeDll, szProc);
	return pRet;
}

HTHEME hb_OpenThemeData(HWND hwnd, LPCWSTR pszClassList)
{
	PFNOPENTHEMEDATA pfnOpenThemeData = (PFNOPENTHEMEDATA)GetProc("OpenThemeData", (void*)OpenThemeDataFail);
	return (*pfnOpenThemeData)(hwnd, pszClassList);
}

HRESULT hb_CloseThemeData(HTHEME hTheme)
{
	PFNCLOSETHEMEDATA pfnCloseThemeData = (PFNCLOSETHEMEDATA)GetProc("CloseThemeData", (void*)CloseThemeDataFail);
	return (*pfnCloseThemeData)(hTheme);
}

HRESULT hb_DrawThemeBackground(HTHEME hTheme, HDC hdc,
											 int iPartId, int iStateId, const RECT *pRect, const RECT *pClipRect)
{
	PFNDRAWTHEMEBACKGROUND pfnDrawThemeBackground =
		(PFNDRAWTHEMEBACKGROUND)GetProc("DrawThemeBackground", (void*)DrawThemeBackgroundFail);
	return (*pfnDrawThemeBackground)(hTheme, hdc, iPartId, iStateId, pRect, pClipRect);
}


HRESULT hb_DrawThemeText(HTHEME hTheme, HDC hdc, int iPartId,
									   int iStateId, LPCWSTR pszText, int iCharCount, DWORD dwTextFlags,
									   DWORD dwTextFlags2, const RECT *pRect)
{
	PFNDRAWTHEMETEXT pfn = (PFNDRAWTHEMETEXT)GetProc("DrawThemeText", (void*)DrawThemeTextFail);
	return (*pfn)(hTheme, hdc, iPartId, iStateId, pszText, iCharCount, dwTextFlags, dwTextFlags2, pRect);
}
HRESULT hb_GetThemeBackgroundContentRect(HTHEME hTheme,  HDC hdc,
													   int iPartId, int iStateId,  const RECT *pBoundingRect,
													   RECT *pContentRect)
{
	PFNGETTHEMEBACKGROUNDCONTENTRECT pfn = (PFNGETTHEMEBACKGROUNDCONTENTRECT)GetProc("GetThemeBackgroundContentRect", (void*)GetThemeBackgroundContentRectFail);
	return (*pfn)(hTheme,  hdc, iPartId, iStateId,  pBoundingRect, pContentRect);
}
HRESULT hb_GetThemeBackgroundExtent(HTHEME hTheme,  HDC hdc,
												  int iPartId, int iStateId, const RECT *pContentRect,
												  RECT *pExtentRect)
{
	PFNGETTHEMEBACKGROUNDEXTENT pfn = (PFNGETTHEMEBACKGROUNDEXTENT)GetProc("GetThemeBackgroundExtent", (void*)GetThemeBackgroundExtentFail);
	return (*pfn)(hTheme, hdc, iPartId, iStateId, pContentRect, pExtentRect);
}
HRESULT hb_GetThemePartSize(HTHEME hTheme, HDC hdc,
										  int iPartId, int iStateId, RECT * pRect, enum THEMESIZE eSize, SIZE *psz)
{
	PFNGETTHEMEPARTSIZE pfnGetThemePartSize =
		(PFNGETTHEMEPARTSIZE)GetProc("GetThemePartSize", (void*)GetThemePartSizeFail);
	return (*pfnGetThemePartSize)(hTheme, hdc, iPartId, iStateId, pRect, eSize, psz);
}

HRESULT hb_GetThemeTextExtent(HTHEME hTheme, HDC hdc,
											int iPartId, int iStateId, LPCWSTR pszText, int iCharCount,
											DWORD dwTextFlags,  const RECT *pBoundingRect,
											RECT *pExtentRect)
{
	PFNGETTHEMETEXTEXTENT pfn = (PFNGETTHEMETEXTEXTENT)GetProc("GetThemeTextExtent", (void*)GetThemeTextExtentFail);
	return (*pfn)(hTheme, hdc, iPartId, iStateId, pszText, iCharCount, dwTextFlags,  pBoundingRect, pExtentRect);
}

HRESULT hb_GetThemeTextMetrics(HTHEME hTheme,  HDC hdc,
											 int iPartId, int iStateId,  TEXTMETRIC* ptm)
{
	PFNGETTHEMETEXTMETRICS pfn = (PFNGETTHEMETEXTMETRICS)GetProc("GetThemeTextMetrics", (void*)GetThemeTextMetricsFail);
	return (*pfn)(hTheme, hdc, iPartId, iStateId,  ptm);
}

HRESULT hb_GetThemeBackgroundRegion(HTHEME hTheme,  HDC hdc,
												  int iPartId, int iStateId, const RECT *pRect,  HRGN *pRegion)
{
	PFNGETTHEMEBACKGROUNDREGION pfn = (PFNGETTHEMEBACKGROUNDREGION)GetProc("GetThemeBackgroundRegion", (void*)GetThemeBackgroundRegionFail);
	return (*pfn)(hTheme, hdc, iPartId, iStateId, pRect, pRegion);
}

HRESULT hb_HitTestThemeBackground(HTHEME hTheme,  HDC hdc, int iPartId,
												int iStateId, DWORD dwOptions, const RECT *pRect,  HRGN hrgn,
												POINT ptTest,  WORD *pwHitTestCode)
{
	PFNHITTESTTHEMEBACKGROUND pfn = (PFNHITTESTTHEMEBACKGROUND)GetProc("HitTestThemeBackground", (void*)HitTestThemeBackgroundFail);
	return (*pfn)(hTheme, hdc, iPartId, iStateId, dwOptions, pRect, hrgn, ptTest, pwHitTestCode);
}

HRESULT hb_DrawThemeEdge(HTHEME hTheme, HDC hdc, int iPartId, int iStateId,
									   const RECT *pDestRect, UINT uEdge, UINT uFlags,   RECT *pContentRect)
{
	PFNDRAWTHEMEEDGE pfn = (PFNDRAWTHEMEEDGE)GetProc("DrawThemeEdge", (void*)DrawThemeEdgeFail);
	return (*pfn)(hTheme, hdc, iPartId, iStateId, pDestRect, uEdge, uFlags, pContentRect);
}

HRESULT hb_DrawThemeIcon(HTHEME hTheme, HDC hdc, int iPartId,
									   int iStateId, const RECT *pRect, HIMAGELIST himl, int iImageIndex)
{
	PFNDRAWTHEMEICON pfn = (PFNDRAWTHEMEICON)GetProc("DrawThemeIcon", (void*)DrawThemeIconFail);
	return (*pfn)(hTheme, hdc, iPartId, iStateId, pRect, himl, iImageIndex);
}

BOOL hb_IsThemePartDefined(HTHEME hTheme, int iPartId,
										 int iStateId)
{
	PFNISTHEMEPARTDEFINED pfn = (PFNISTHEMEPARTDEFINED)GetProc("IsThemePartDefined", (void*)IsThemePartDefinedFail);
	return (*pfn)(hTheme, iPartId, iStateId);
}

BOOL hb_IsThemeBackgroundPartiallyTransparent(HTHEME hTheme,
															int iPartId, int iStateId)
{
	PFNISTHEMEBACKGROUNDPARTIALLYTRANSPARENT pfn = (PFNISTHEMEBACKGROUNDPARTIALLYTRANSPARENT)GetProc("IsThemeBackgroundPartiallyTransparent", (void*)IsThemeBackgroundPartiallyTransparentFail);
	return (*pfn)(hTheme, iPartId, iStateId);
}

HRESULT hb_GetThemeColor(HTHEME hTheme, int iPartId,
									   int iStateId, int iPropId,  COLORREF *pColor)
{
	PFNGETTHEMECOLOR pfn = (PFNGETTHEMECOLOR)GetProc("GetThemeColor", (void*)GetThemeColorFail);
	return (*pfn)(hTheme, iPartId, iStateId, iPropId, pColor);
}

HRESULT hb_GetThemeMetric(HTHEME hTheme,  HDC hdc, int iPartId,
										int iStateId, int iPropId,  int *piVal)
{
	PFNGETTHEMEMETRIC pfn = (PFNGETTHEMEMETRIC)GetProc("GetThemeMetric", (void*)GetThemeMetricFail);
	return (*pfn)(hTheme, hdc, iPartId, iStateId, iPropId, piVal);
}

HRESULT hb_GetThemeString(HTHEME hTheme, int iPartId,
										int iStateId, int iPropId,  LPWSTR pszBuff, int cchMaxBuffChars)
{
	PFNGETTHEMESTRING pfn = (PFNGETTHEMESTRING)GetProc("GetThemeString", (void*)GetThemeStringFail);
	return (*pfn)(hTheme, iPartId, iStateId, iPropId, pszBuff, cchMaxBuffChars);
}

HRESULT hb_GetThemeBool(HTHEME hTheme, int iPartId,
									  int iStateId, int iPropId,  BOOL *pfVal)
{
	PFNGETTHEMEBOOL pfn = (PFNGETTHEMEBOOL)GetProc("GetThemeBool", (void*)GetThemeBoolFail);
	return (*pfn)(hTheme, iPartId, iStateId, iPropId, pfVal);
}

HRESULT hb_GetThemeInt(HTHEME hTheme, int iPartId,
									 int iStateId, int iPropId,  int *piVal)
{
	PFNGETTHEMEINT pfn = (PFNGETTHEMEINT)GetProc("GetThemeInt", (void*)GetThemeIntFail);
	return (*pfn)(hTheme, iPartId, iStateId, iPropId, piVal);
}

HRESULT hb_GetThemeEnumValue(HTHEME hTheme, int iPartId,
										   int iStateId, int iPropId,  int *piVal)
{
	PFNGETTHEMEENUMVALUE pfn = (PFNGETTHEMEENUMVALUE)GetProc("GetThemeEnumValue", (void*)GetThemeEnumValueFail);
	return (*pfn)(hTheme, iPartId, iStateId, iPropId, piVal);
}

HRESULT hb_GetThemePosition(HTHEME hTheme, int iPartId,
										  int iStateId, int iPropId,  POINT *pPoint)
{
	PFNGETTHEMEPOSITION pfn = (PFNGETTHEMEPOSITION)GetProc("GetThemePosition", (void*)GetThemePositionFail);
	return (*pfn)(hTheme, iPartId, iStateId, iPropId, pPoint);
}

HRESULT hb_GetThemeFont(HTHEME hTheme,  HDC hdc, int iPartId,
									  int iStateId, int iPropId,  LOGFONT *pFont)
{
	PFNGETTHEMEFONT pfn = (PFNGETTHEMEFONT)GetProc("GetThemeFont", (void*)GetThemeFontFail);
	return (*pfn)(hTheme, hdc, iPartId, iStateId, iPropId, pFont);
}

HRESULT hb_GetThemeRect(HTHEME hTheme, int iPartId,
									  int iStateId, int iPropId,  RECT *pRect)
{
	PFNGETTHEMERECT pfn = (PFNGETTHEMERECT)GetProc("GetThemeRect", (void*)GetThemeRectFail);
	return (*pfn)(hTheme, iPartId, iStateId, iPropId, pRect);
}

HRESULT hb_GetThemeMargins(HTHEME hTheme,  HDC hdc, int iPartId,
										 int iStateId, int iPropId,  RECT *prc,  MARGINS *pMargins)
{
	PFNGETTHEMEMARGINS pfn = (PFNGETTHEMEMARGINS)GetProc("GetThemeMargins", (void*)GetThemeMarginsFail);
	return (*pfn)(hTheme, hdc, iPartId, iStateId, iPropId, prc, pMargins);
}

HRESULT hb_GetThemeIntList(HTHEME hTheme, int iPartId,
										 int iStateId, int iPropId,  INTLIST *pIntList)
{
	PFNGETTHEMEINTLIST pfn = (PFNGETTHEMEINTLIST)GetProc("GetThemeIntList", (void*)GetThemeIntListFail);
	return (*pfn)(hTheme, iPartId, iStateId, iPropId, pIntList);
}

HRESULT hb_GetThemePropertyOrigin(HTHEME hTheme, int iPartId,
												int iStateId, int iPropId,  enum PROPERTYORIGIN *pOrigin)
{
	PFNGETTHEMEPROPERTYORIGIN pfn = (PFNGETTHEMEPROPERTYORIGIN)GetProc("GetThemePropertyOrigin", (void*)GetThemePropertyOriginFail);
	return (*pfn)(hTheme, iPartId, iStateId, iPropId, pOrigin);
}

HRESULT hb_SetWindowTheme(HWND hwnd, LPCWSTR pszSubAppName,
										LPCWSTR pszSubIdList)
{
	PFNSETWINDOWTHEME pfn = (PFNSETWINDOWTHEME)GetProc("SetWindowTheme", (void*)SetWindowThemeFail);
	return (*pfn)(hwnd, pszSubAppName, pszSubIdList);
}

HRESULT hb_GetThemeFilename(HTHEME hTheme, int iPartId,
										  int iStateId, int iPropId,  LPWSTR pszThemeFileName, int cchMaxBuffChars)
{
	PFNGETTHEMEFILENAME pfn = (PFNGETTHEMEFILENAME)GetProc("GetThemeFilename", (void*)GetThemeFilenameFail);
	return (*pfn)(hTheme, iPartId, iStateId, iPropId,  pszThemeFileName, cchMaxBuffChars);
}

COLORREF hb_GetThemeSysColor(HTHEME hTheme, int iColorId)
{
	PFNGETTHEMESYSCOLOR pfn = (PFNGETTHEMESYSCOLOR)GetProc("GetThemeSysColor", (void*)GetThemeSysColorFail);
	return (*pfn)(hTheme, iColorId);
}

HBRUSH hb_GetThemeSysColorBrush(HTHEME hTheme, int iColorId)
{
	PFNGETTHEMESYSCOLORBRUSH pfn = (PFNGETTHEMESYSCOLORBRUSH)GetProc("GetThemeSysColorBrush", (void*)GetThemeSysColorBrushFail);
	return (*pfn)(hTheme, iColorId);
}

BOOL hb_GetThemeSysBool(HTHEME hTheme, int iBoolId)
{
	PFNGETTHEMESYSBOOL pfn = (PFNGETTHEMESYSBOOL)GetProc("GetThemeSysBool", (void*)GetThemeSysBoolFail);
	return (*pfn)(hTheme, iBoolId);
}

int hb_GetThemeSysSize(HTHEME hTheme, int iSizeId)
{
	PFNGETTHEMESYSSIZE pfn = (PFNGETTHEMESYSSIZE)GetProc("GetThemeSysSize", (void*)GetThemeSysSizeFail);
	return (*pfn)(hTheme, iSizeId);
}

HRESULT hb_GetThemeSysFont(HTHEME hTheme, int iFontId,  LOGFONT *plf)
{
	PFNGETTHEMESYSFONT pfn = (PFNGETTHEMESYSFONT)GetProc("GetThemeSysFont", (void*)GetThemeSysFontFail);
	return (*pfn)(hTheme, iFontId, plf);
}

HRESULT hb_GetThemeSysString(HTHEME hTheme, int iStringId,
										   LPWSTR pszStringBuff, int cchMaxStringChars)
{
	PFNGETTHEMESYSSTRING pfn = (PFNGETTHEMESYSSTRING)GetProc("GetThemeSysString", (void*)GetThemeSysStringFail);
	return (*pfn)(hTheme, iStringId, pszStringBuff, cchMaxStringChars);
}

HRESULT hb_GetThemeSysInt(HTHEME hTheme, int iIntId, int *piValue)
{
	PFNGETTHEMESYSINT pfn = (PFNGETTHEMESYSINT)GetProc("GetThemeSysInt", (void*)GetThemeSysIntFail);
	return (*pfn)(hTheme, iIntId, piValue);
}

BOOL hb_IsThemeActive(void)
{
	PFNISTHEMEACTIVE pfn = (PFNISTHEMEACTIVE)GetProc("IsThemeActive", (void*)IsThemeActiveFail);
	return (*pfn)();
}

BOOL hb_IsAppThemed(void)
{
	PFNISAPPTHEMED pfnIsAppThemed = (PFNISAPPTHEMED)GetProc("IsAppThemed", (void*)IsAppThemedFail);
	return (*pfnIsAppThemed)();
}

HTHEME hb_GetWindowTheme(HWND hwnd)
{
	PFNGETWINDOWTHEME pfn = (PFNGETWINDOWTHEME)GetProc("GetWindowTheme", (void*)GetWindowThemeFail);
	return (*pfn)(hwnd);
}

HRESULT hb_EnableThemeDialogTexture(HWND hwnd, DWORD dwFlags)
{
	PFNENABLETHEMEDIALOGTEXTURE pfn = (PFNENABLETHEMEDIALOGTEXTURE)GetProc("EnableThemeDialogTexture", (void*)EnableThemeDialogTextureFail);
	return (*pfn)(hwnd, dwFlags);
}

BOOL hb_IsThemeDialogTextureEnabled(HWND hwnd)
{
	PFNISTHEMEDIALOGTEXTUREENABLED pfn = (PFNISTHEMEDIALOGTEXTUREENABLED)GetProc("IsThemeDialogTextureEnabled", (void*)IsThemeDialogTextureEnabledFail);
	return (*pfn)(hwnd);
}

DWORD hb_GetThemeAppProperties()
{
	PFNGETTHEMEAPPPROPERTIES pfn = (PFNGETTHEMEAPPPROPERTIES)GetProc("GetThemeAppProperties", (void*)GetThemeAppPropertiesFail);
	return (*pfn)();
}

void hb_SetThemeAppProperties(DWORD dwFlags)
{
	PFNSETTHEMEAPPPROPERTIES pfn = (PFNSETTHEMEAPPPROPERTIES)GetProc("SetThemeAppProperties", (void*)SetThemeAppPropertiesFail);
	(*pfn)(dwFlags);
}

HRESULT hb_GetCurrentThemeName(
	LPWSTR pszThemeFileName, int cchMaxNameChars,
	LPWSTR pszColorBuff, int cchMaxColorChars,
	LPWSTR pszSizeBuff, int cchMaxSizeChars)
{
	PFNGETCURRENTTHEMENAME pfn = (PFNGETCURRENTTHEMENAME)GetProc("GetCurrentThemeName", (void*)GetCurrentThemeNameFail);
	return (*pfn)(pszThemeFileName, cchMaxNameChars, pszColorBuff, cchMaxColorChars, pszSizeBuff, cchMaxSizeChars);
}

HRESULT hb_GetThemeDocumentationProperty(LPCWSTR pszThemeName,
													   LPCWSTR pszPropertyName,  LPWSTR pszValueBuff, int cchMaxValChars)
{
	PFNGETTHEMEDOCUMENTATIONPROPERTY pfn = (PFNGETTHEMEDOCUMENTATIONPROPERTY)GetProc("GetThemeDocumentationProperty", (void*)GetThemeDocumentationPropertyFail);
	return (*pfn)(pszThemeName, pszPropertyName, pszValueBuff, cchMaxValChars);
}


HRESULT hb_DrawThemeParentBackground(HWND hwnd, HDC hdc,  RECT* prc)
{
	PFNDRAWTHEMEPARENTBACKGROUND pfn = (PFNDRAWTHEMEPARENTBACKGROUND)GetProc("DrawThemeParentBackground", (void*)DrawThemeParentBackgroundFail);
	return (*pfn)(hwnd, hdc, prc);
}

HRESULT hb_EnableTheming(BOOL fEnable)
{
	PFNENABLETHEMING pfn = (PFNENABLETHEMING)GetProc("EnableTheming", (void*)EnableThemingFail);
	return (*pfn)(fEnable);
}



LRESULT OnNotifyCustomDraw( LPARAM  pNotifyStruct)
{
	LPNMCUSTOMDRAW pCustomDraw = (LPNMCUSTOMDRAW) pNotifyStruct;
    HWND m_hWnd = pCustomDraw->hdr.hwndFrom;
    DWORD style = (DWORD)GetWindowLong(m_hWnd, GWL_STYLE);
	if ((style & (BS_BITMAP | BS_ICON)) == 0 || !hb_IsAppThemed () || !hb_IsThemeActive ())
	{
		// not icon or bitmap button, or themes not active - draw normally
        return CDRF_DODEFAULT;

	}

	if (pCustomDraw->dwDrawStage == CDDS_PREERASE)
	{
		// erase background (according to parent window's themed background
        hb_DrawThemeParentBackground (m_hWnd, pCustomDraw->hdc, &pCustomDraw->rc);
	}

	if (pCustomDraw->dwDrawStage == CDDS_PREERASE || pCustomDraw->dwDrawStage == CDDS_PREPAINT)
	{
		// get theme handle
        HTHEME hTheme = hb_OpenThemeData (m_hWnd, L"BUTTON");
        int state_id;
        RECT content_rect;
//      ASSERT (hTheme != NULL);
		if (hTheme == NULL)
		{
			// fail gracefully
            return CDRF_DODEFAULT;

		}

		// determine state for DrawThemeBackground()
		// note: order of these tests is significant
         state_id = PBS_NORMAL;
		if (style & WS_DISABLED)
			state_id = PBS_DISABLED;
		else if (pCustomDraw->uItemState & CDIS_SELECTED)
			state_id = PBS_PRESSED;
		else if (pCustomDraw->uItemState & CDIS_HOT)
			state_id = PBS_HOT;
		else if (style & BS_DEFPUSHBUTTON)
			state_id = PBS_DEFAULTED;

		// draw themed button background appropriate to button state
        hb_DrawThemeBackground (hTheme,
			pCustomDraw->hdc, BP_PUSHBUTTON,
			state_id,
			&pCustomDraw->rc, NULL);

		// get content rectangle (space inside button for image)
        content_rect = pCustomDraw->rc;
        hb_GetThemeBackgroundContentRect (hTheme,
			pCustomDraw->hdc, BP_PUSHBUTTON,
			state_id,
			&pCustomDraw->rc,
			&content_rect);
		// we're done with the theme
        hb_CloseThemeData(hTheme);

		// draw the image
		if (style & BS_BITMAP)
		{
            draw_bitmap (pCustomDraw->hdc, &content_rect, style,m_hWnd);
		}
		else
		{
//            ASSERT (style & BS_ICON);       // since we bailed out at top otherwise
            draw_icon (pCustomDraw->hdc, &content_rect, style,m_hWnd);
		}

		// finally, draw the focus rectangle if needed
		if (pCustomDraw->uItemState & CDIS_FOCUS)
		{
			// draw focus rectangle
			DrawFocusRect (pCustomDraw->hdc, &content_rect);
		}

        return CDRF_SKIPDEFAULT;

	}

	// we should never get here, since we should only get CDDS_PREERASE or CDDS_PREPAINT

    return CDRF_DODEFAULT;
}

// draw_bitmap () - Draw a bitmap
void draw_bitmap(HDC hDC, const RECT *Rect, DWORD style,HWND m_hWnd)
{
    HBITMAP hBitmap = (HBITMAP)SendMessage(m_hWnd, BM_GETIMAGE, IMAGE_BITMAP, 0L);
    int x,y;
    BITMAPINFO bmi;
    if (!hBitmap )
		return;

	// determine size of bitmap image

	memset (&bmi, 0, sizeof (BITMAPINFO));
	bmi.bmiHeader.biSize = sizeof (BITMAPINFOHEADER);
	GetDIBits(hDC, hBitmap, 0, 0, NULL, &bmi, DIB_RGB_COLORS);

	// determine position of top-left corner of bitmap (positioned according to style)
    x = image_left (bmi.bmiHeader.biWidth, Rect, style);
    y = image_top (bmi.bmiHeader.biHeight, Rect, style);

	// Draw the bitmap
	DrawState(hDC, NULL, NULL, (LPARAM) hBitmap, 0, x, y, bmi.bmiHeader.biWidth, bmi.bmiHeader.biHeight,
		(style & WS_DISABLED) != 0 ? (DST_BITMAP | DSS_DISABLED) : (DST_BITMAP | DSS_NORMAL));
}

// draw_icon () - Draw an icon
void draw_icon (HDC hDC, const RECT* Rect, DWORD style,HWND m_hWnd)
{
	HICON hIcon = (HICON)SendMessage(m_hWnd, BM_GETIMAGE, IMAGE_ICON, 0L);
	ICONINFO ii;
	BITMAPINFO bmi;
	int cx ;
	int cy ;
	int x;
	int y;

	if (!hIcon)
		return;

	// determine size of icon image
	GetIconInfo (hIcon, &ii);
	memset (&bmi, 0, sizeof (BITMAPINFO));
	bmi.bmiHeader.biSize = sizeof (BITMAPINFOHEADER);

	if (ii.hbmColor != NULL)
	{
		// icon has separate image and mask bitmaps - use size directly
		GetDIBits(hDC, ii.hbmColor, 0, 0, NULL, &bmi, DIB_RGB_COLORS);
		cx = bmi.bmiHeader.biWidth;
		cy = bmi.bmiHeader.biHeight;
	}
	else
	{
		// icon has singel mask bitmap which is twice as high as icon
		GetDIBits(hDC, ii.hbmMask, 0, 0, NULL, &bmi, DIB_RGB_COLORS);
		cx = bmi.bmiHeader.biWidth;
		cy = bmi.bmiHeader.biHeight/2;
	}

	// determine position of top-left corner of icon
	x = image_left (cx, Rect, style);
	y = image_top (cy, Rect, style);
	// Draw the icon
	DrawState(hDC, NULL, NULL, (LPARAM) hIcon, 0, x, y, cx, cy,
		(style & WS_DISABLED) != 0 ? (DST_ICON | DSS_DISABLED) : (DST_ICON | DSS_NORMAL));
}

// calcultate the left position of the image so it is drawn on left, right or centred (the default)
// as dictated by the style settings.
static int
image_left (int cx, const RECT *Rect, DWORD style)
{
    int x = Rect->left;
    if (cx > Rect->right-Rect->left )
        cx = Rect->right-Rect->left;
	else if ((style & BS_CENTER) == BS_LEFT)
        x = Rect->left;
	else if ((style & BS_CENTER) == BS_RIGHT)
        x = Rect->right - cx;
	else
        x = Rect->left + ((Rect->right-Rect->left) - cx)/2;
	return (x);
}

// calcultate the top position of the image so it is drawn on top, bottom or vertically centred (the default)
// as dictated by the style settings.
static int
image_top (int cy, const RECT *Rect, DWORD style)
{
    int y = Rect->top;
    if (cy > Rect->bottom-Rect->top )
        cy = Rect->bottom-Rect->top;
	if ((style & BS_VCENTER) == BS_TOP)
        y = Rect->top;
	else if ((style & BS_VCENTER) == BS_BOTTOM)
        y = Rect->bottom - cy;
	else
        y = Rect->top + ((Rect->bottom-Rect->top) - cy)/2;
	return (y);
}




HB_FUNC(INITTHEMELIB)
{
    m_hThemeDll = LoadLibrary("UxTheme.dll");
    if( m_hThemeDll )
       ThemeLibLoaded = TRUE;
}
HB_FUNC(ENDTHEMELIB)
{
	if (m_hThemeDll!=NULL)
		FreeLibrary(m_hThemeDll);

	m_hThemeDll = NULL;
   ThemeLibLoaded = FALSE;
}

HB_FUNC( ONNOTIFYCUSTOMDRAW )
{
   /* HWND hWnd = ( HWND ) hb_parnl( 1 ) ; */
   LPARAM lParam = ( LPARAM ) hb_parnl( 1 ) ;
//   PHB_ITEM pColor = hb_param( 3, HB_IT_ARRAY );

   hb_retnl( ( LONG ) OnNotifyCustomDraw( lParam ));
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
			BOOL bIsPressed =	(lpDIS->itemState & ODS_SELECTED);
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
			{// Draw the button's title
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
					int mlen = MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, (char *)sTitle, nTextLen + 1, NULL, 0);
					WCHAR* output = new WCHAR[mlen];
					if(output)
					{
						MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, (char *)sTitle, nTextLen + 1, output, mlen);
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


void Calc_iconWidthHeight (HWND m_hWnd, DWORD *ccx, DWORD *ccy,HDC hDC)
{
    HICON hIcon = (HICON)SendMessage(m_hWnd, BM_GETIMAGE, IMAGE_ICON, 0L);
	ICONINFO ii;
	BITMAPINFO bmi;
    int cx ;
    int cy ;


    if (!hIcon)
    {
	   *ccx =0;
	   *ccy = 0;
		return;
    }

	// determine size of icon image
	GetIconInfo (hIcon, &ii);
	memset (&bmi, 0, sizeof (BITMAPINFO));
	bmi.bmiHeader.biSize = sizeof (BITMAPINFOHEADER);

	if (ii.hbmColor != NULL)
	{
		// icon has separate image and mask bitmaps - use size directly
		GetDIBits(hDC, ii.hbmColor, 0, 0, NULL, &bmi, DIB_RGB_COLORS);
		cx = bmi.bmiHeader.biWidth;
		cy = bmi.bmiHeader.biHeight;
	}
	else
	{
		// icon has singel mask bitmap which is twice as high as icon
		GetDIBits(hDC, ii.hbmMask, 0, 0, NULL, &bmi, DIB_RGB_COLORS);
		cx = bmi.bmiHeader.biWidth;
		cy = bmi.bmiHeader.biHeight/2;
	}

	// determine position of top-left corner of icon
		*ccx = cx;
		*ccy = cy;
}

void Calc_bitmapWidthHeight(HWND m_hWnd,DWORD *ccx,DWORD *ccy,HDC hDC,HBITMAP hBitmap)
{
//    HBITMAP hBitmap = (HBITMAP)SendMessage(m_hWnd, BM_GETIMAGE, IMAGE_BITMAP, 0L);
    int x,y;
	BITMAPINFO bmi;
    if (!hBitmap )
    {
	   *ccy=0;
	   *ccx=0;
		return;
    }

	memset (&bmi, 0, sizeof (BITMAPINFO));
	bmi.bmiHeader.biSize = sizeof (BITMAPINFOHEADER);
	GetDIBits(hDC, hBitmap, 0, 0, NULL, &bmi, DIB_RGB_COLORS);


    *ccx =bmi.bmiHeader.biWidth;
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

static void PrepareImageRect(HWND hButtonWnd, BOOL bHasTitle, RECT* rpItem, RECT* rpTitle, BOOL bIsPressed, DWORD dwWidth, DWORD dwHeight, RECT* rpImage,int m_byAlign)
{
	RECT rBtn;
    LONG rpImageHeight;
    LONG rpImageWidth;

	CopyRect(rpImage, rpItem);

	switch (m_byAlign)
	{

		case ST_ALIGN_HORIZ:
			if (bHasTitle == FALSE)
			{
				// Center image horizontally
                rpImage->left += (((rpImage->right - rpImage->left)- (long)dwWidth)/2);
			}
			else
			{
				// Image must be placed just inside the focus rect
                rpImage->left += 3;
                rpTitle->left += dwWidth + 3;
			}
			// Center image vertically
            rpImage->top += (((rpImage->bottom - rpImage->top) - (long)dwHeight)/2);
			break;

        case ST_ALIGN_HORIZ_RIGHT:
            GetClientRect(hButtonWnd,&rBtn);
			if (bHasTitle == FALSE)
			{
				// Center image horizontally
                rpImage->left += (((rpImage->right - rpImage->left) - (long)dwWidth)/2);
			}
			else
			{
				// Image must be placed just inside the focus rect
                rpTitle->right = (rpTitle->right - rpTitle->left)- dwWidth - 3;
                rpTitle->left = 3;
                rpImage->left = rBtn.right - dwWidth - 3;
				// Center image vertically
                rpImage->top += (((rpImage->bottom - rpImage->top) - (long)dwHeight)/2);
			}
			break;
		case ST_ALIGN_VERT:
			// Center image horizontally
            rpImage->left += (((rpImage->right - rpImage->left) - (long)dwWidth)/2);
			if (bHasTitle == FALSE)
			{
				// Center image vertically
                rpImage->top += (((rpImage->bottom - rpImage->top) - (long)dwHeight)/2);
			}
			else
			{
                rpImage->top = 3;
				rpTitle->top += dwHeight;
			}
			break;

		case ST_ALIGN_OVERLAP:
			break;
	} // switch



/*
	GetClientRect(hButtonWnd, &rBtn);
	if (bHasTitle == FALSE)
	{
		// Center image horizontally
        rpImageWidth = rpImage->right - rpImage->left;
		rpImage->left += ((rpImageWidth - (long)dwWidth)/2);
	}
	else
	{
		// Image must be placed just inside the focus rect
		LONG rpTitleWidth = rpTitle->right - rpTitle->left;
		rpTitle->right = rpTitleWidth - dwWidth - 30;
		rpTitle->left = 30;
		rpImage->left = rBtn.right - dwWidth - 30;
		// Center image vertically
        rpImageHeight = rpImage->bottom - rpImage->top;
		rpImage->top += ((rpImageHeight - (long)dwHeight)/2);
	}

*/
	// If button is pressed then press image also
	if (bIsPressed && !Themed)
		OffsetRect(rpImage, 1, 1);
//    rpItem=rpImage;

} // End of PrepareImageRect

static void DrawTheIcon(HWND hButtonWnd, HDC dc, BOOL bHasTitle, RECT* rpItem, RECT* rpTitle, BOOL bIsPressed, BOOL bIsDisabled,HICON hIco,HBITMAP hBitmap ,int iStyle)
{
	RECT	rImage;
	DWORD cx =0 ;
	DWORD cy =0 ;
    if (hIco)
      Calc_iconWidthHeight(hButtonWnd,&cx,&cy,dc);
   if (hBitmap)
      Calc_bitmapWidthHeight(hButtonWnd,&cx,&cy,dc,hBitmap);


    PrepareImageRect(hButtonWnd, bHasTitle,rpItem, rpTitle, bIsPressed, cx, cy, &rImage,iStyle);

    if ( hIco )
    DrawState(  dc,
				NULL,
				NULL,
                (LPARAM)hIco,
				0,
				rImage.left,
				rImage.top,
				(rImage.right - rImage.left),
				(rImage.bottom - rImage.top),
				(bIsDisabled ? DSS_DISABLED : DSS_NORMAL) | DST_ICON);
    if ( hBitmap )
       DrawState(  dc,
				NULL,
				NULL,
                (LPARAM)hBitmap,
				0,
				rImage.left,
				rImage.top,
				(rImage.right - rImage.left),
				(rImage.bottom - rImage.top),
                (bIsDisabled ? DSS_DISABLED : DSS_NORMAL) | DST_BITMAP);

} // End of DrawTheIcon



HB_FUNC(HB_OPENTHEMEDATA)
{
   HWND hwnd = (HWND) hb_parnl( 1 ) ;
   LPCSTR pText = hb_parc(2);
   int nTextLen = strlen(pText);
   HTHEME p;
   int mlen = MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, (char *)pText, nTextLen + 1, NULL, 0);
   WCHAR* output =  (WCHAR*) hb_xgrab(mlen+10);
   if(output)
   {
      MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, (char *)pText, nTextLen + 1, output, mlen);
   }

   p=   hb_OpenThemeData(hwnd, output) ;
   hb_retptr( (void*)p );
   if(output)
     hb_xfree(output);
   if ( p )
     Themed = TRUE;

}



HB_FUNC(ISTHEMEDLOAD)
{
   hb_retl(ThemeLibLoaded) ;
}

HB_FUNC(HB_DRAWTHEMEBACKGROUND)
{

   HTHEME hTheme = (HTHEME) hb_parptr(1 ) ;
   HDC hdc = (HDC)hb_parnl( 2 ) ;
   int iPartId = hb_parni( 3 ) ;
   int iStateId = hb_parni( 4 ) ;
   RECT pRect ;
   RECT pClipRect;

   BOOL bRectOk = ( ISARRAY( 5 )  &&   Array2Rect( hb_param( 5, HB_IT_ARRAY ), &pRect ) ) ;
   BOOL bRectOk1 = ( ISARRAY( 6 )  &&   Array2Rect( hb_param( 6, HB_IT_ARRAY ), &pClipRect ) ) ;


	hb_retnl( hb_DrawThemeBackground(hTheme, hdc,
											 iPartId, iStateId, &pRect, NULL ) );

}


HB_FUNC(  DRAWTHEICON )
{
   HWND hButtonWnd = (HWND) hb_parnl( 1 ) ;
   HDC dc = (HDC) hb_parnl( 2 ) ;
   BOOL bHasTitle = hb_parl( 3 );
   RECT rpItem;
   RECT rpTitle;
   BOOL bIsPressed = hb_parl( 6 );
   BOOL bIsDisabled= hb_parl( 7 );
   BOOL bRectOk = ( ISARRAY( 4 )  &&   Array2Rect( hb_param( 4, HB_IT_ARRAY ), &rpItem ) ) ;
   BOOL bRectOk1 = ( ISARRAY( 5 )  &&   Array2Rect( hb_param( 5, HB_IT_ARRAY ), &rpTitle ) ) ;
   HICON   hIco = ISNUM(8) ? (HICON) hb_parnl( 8 ) : NULL;
   HBITMAP hBit = ISNUM(9) ? (HBITMAP) hb_parnl( 9 ) : NULL;
   int iStyle = hb_parni( 10 );

   DrawTheIcon(hButtonWnd, dc, bHasTitle, &rpItem, &rpTitle, bIsPressed, bIsDisabled, hIco, hBit,iStyle);
   hb_storni( rpItem.left   , 4 , 1);
   hb_storni( rpItem.top    , 4 , 2);
   hb_storni( rpItem.right  , 4 , 3);
   hb_storni( rpItem.bottom , 4 , 4);
   hb_storni( rpTitle.left   , 5 , 1);
   hb_storni( rpTitle.top    , 5 , 2);
   hb_storni( rpTitle.right  , 5 , 3);
   hb_storni( rpTitle.bottom , 5 , 4);

}


HB_FUNC(HB_DRAWTHEMETEXT)
{

  HTHEME hTheme = (HTHEME) hb_parptr(1) ;
  HDC hdc = (HDC) hb_parnl(2) ;
  int iPartId = hb_parni(3);
  int iStateId = hb_parni( 4 );
  LPCSTR pText = hb_parc( 5 );
  int iCharCount;
  DWORD dwTextFlags= hb_parnl( 6 ) ;
  DWORD dwTextFlags2 = hb_parnl( 7 ) ;

  RECT pRect ;
  BOOL bRectOk = ( ISARRAY( 8 )  &&   Array2Rect( hb_param( 8, HB_IT_ARRAY ), &pRect ) ) ;
  int nTextLen = strlen(pText);
  int mlen = MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, (char *)pText, nTextLen + 1, NULL, 0);
  WCHAR* output =  (WCHAR*) hb_xgrab(mlen+10);
  if(output)
  {
      MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, (char *)pText, nTextLen + 1, output, mlen);
  }


  hb_DrawThemeText(hTheme, hdc, iPartId,
                                       iStateId, output, wcslen(output), dwTextFlags,
                                       dwTextFlags2, &pRect);
  if(output)
  {
	 hb_xfree(output);
  }


}

HB_FUNC(HB_CLOSETHEMEDATA)
{
   HTHEME hTheme = (HTHEME) hb_parptr( 1 ) ;
   hb_CloseThemeData(hTheme);
}


HB_FUNC(TRACKMOUSEVENT)
{
   HWND m_hWnd = (HWND) hb_parnl( 1 );
   TRACKMOUSEEVENT     csTME;
   csTME.cbSize = sizeof( csTME );
   csTME.dwFlags = TME_LEAVE;
   csTME.hwndTrack = m_hWnd;
   _TrackMouseEvent(&csTME);
}
