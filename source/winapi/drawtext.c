/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level text functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#define OEMRESOURCE
#include "hwingui.h"
#include <commctrl.h>
#include "hbvm.h"
#include "hbstack.h"
#include "hbapiitm.h"

/* FIXED (HB_MT): the font-list state used to live in file-scope static
 * PHB_ITEM variables, shared by every thread. Two threads calling
 * hwg_GetFontsList() at the same time would corrupt each other's list.
 * EnumFontFamiliesEx() already provides a per-call context channel (the
 * lParam passed to the callback) - that channel is now used instead, so
 * each call gets its own private state on the stack. */
typedef struct _HWG_FONTENUM_CTX
{
   PHB_ITEM aFontsList;
   PHB_ITEM pFontsItem;
   PHB_ITEM pFontsItemLast;
} HWG_FONTENUM_CTX;

/*=============================================================================
 * HWG_DEFINEPAINTSTRU()
 * Allocates a PAINTSTRUCT structure
 *===========================================================================*/
HB_FUNC( HWG_DEFINEPAINTSTRU )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) hb_xgrab( sizeof( PAINTSTRUCT ) );
   HB_RETHANDLE( pps );
}

/*=============================================================================
 * HWG_BEGINPAINT()
 * Begins painting on a window
 *===========================================================================*/
HB_FUNC( HWG_BEGINPAINT )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 2 );
   HDC hDC = BeginPaint( ( HWND ) HB_PARHANDLE( 1 ), pps );
   HB_RETHANDLE( hDC );
}

/*=============================================================================
 * HWG_ENDPAINT()
 * Ends painting on a window
 *===========================================================================*/
HB_FUNC( HWG_ENDPAINT )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 2 );
   EndPaint( ( HWND ) HB_PARHANDLE( 1 ), pps );
   hb_xfree( pps );
}

/*=============================================================================
 * HWG_DELETEDC()
 * Deletes a device context
 *===========================================================================*/
HB_FUNC( HWG_DELETEDC )
{
   DeleteDC( ( HDC ) HB_PARHANDLE( 1 ) );
}

/*=============================================================================
 * HWG_TEXTOUT()
 * Outputs text at a specified position
 *===========================================================================*/
HB_FUNC( HWG_TEXTOUT )
{
   void *hText;
   HB_SIZE nLen;
   LPCTSTR lpText = HB_PARSTR( 4, &hText, &nLen );

   TextOut( ( HDC ) HB_PARHANDLE( 1 ),
         hb_parni( 2 ),
         hb_parni( 3 ),
         lpText,
         nLen );
   hb_strfree( hText );
}

/*=============================================================================
 * HWG_DRAWTEXT()
 * Draws formatted text in a rectangle
 *===========================================================================*/
HB_FUNC( HWG_DRAWTEXT )
{
   void *hText;
   HB_SIZE nLen;
   LPCTSTR lpText = HB_PARSTR( 2, &hText, &nLen );
   RECT rc;
   UINT uFormat = ( hb_pcount(  ) == 4 ? hb_parni( 4 ) : hb_parni( 7 ) );
   int heigh;

   if( hb_pcount(  ) > 4 )
   {
      rc.left = hb_parni( 3 );
      rc.top = hb_parni( 4 );
      rc.right = hb_parni( 5 );
      rc.bottom = hb_parni( 6 );
   }
   else
   {
      Array2Rect( hb_param( 3, HB_IT_ARRAY ), &rc );
   }

   heigh = DrawText( ( HDC ) HB_PARHANDLE( 1 ),
         lpText,
         nLen,
         &rc, uFormat );
   hb_strfree( hText );

   if( HB_ISARRAY( 8 ) )
   {
      hb_storvni( rc.left, 8, 1 );
      hb_storvni( rc.top, 8, 2 );
      hb_storvni( rc.right, 8, 3 );
      hb_storvni( rc.bottom, 8, 4 );
   }
   hb_retni( heigh );
}

/*=============================================================================
 * HWG_GETTEXTMETRIC()
 * Gets text metrics
 *===========================================================================*/
HB_FUNC( HWG_GETTEXTMETRIC )
{
   TEXTMETRIC tm;
   PHB_ITEM aMetr = hb_itemArrayNew( 8 );
   PHB_ITEM temp;

   GetTextMetrics( ( HDC ) HB_PARHANDLE( 1 ), &tm );

   temp = hb_itemPutNL( NULL, tm.tmHeight );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, tm.tmAveCharWidth );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, tm.tmMaxCharWidth );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, tm.tmExternalLeading );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, tm.tmInternalLeading );
   hb_itemArrayPut( aMetr, 5, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, tm.tmAscent );
   hb_itemArrayPut( aMetr, 6, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, tm.tmDescent );
   hb_itemArrayPut( aMetr, 7, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, tm.tmWeight );
   hb_itemArrayPut( aMetr, 8, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

/*=============================================================================
 * HWG_GETTEXTSIZE()
 * Gets text extent size
 *===========================================================================*/
HB_FUNC( HWG_GETTEXTSIZE )
{
   void *hText;
   HB_SIZE nLen;
   LPCTSTR lpText = HB_PARSTR( 2, &hText, &nLen );
   SIZE sz;
   PHB_ITEM aMetr = hb_itemArrayNew( 2 );
   PHB_ITEM temp;

   GetTextExtentPoint32( ( HDC ) HB_PARHANDLE( 1 ), lpText, nLen, &sz );
   hb_strfree( hText );

   temp = hb_itemPutNL( NULL, sz.cx );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, sz.cy );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

/*=============================================================================
 * HWG_GETCLIENTRECT()
 * Gets client rectangle
 *===========================================================================*/
HB_FUNC( HWG_GETCLIENTRECT )
{
   RECT rc;
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   PHB_ITEM temp;

   GetClientRect( ( HWND ) HB_PARHANDLE( 1 ), &rc );

   temp = hb_itemPutNL( NULL, rc.left );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.top );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.right );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.bottom );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

/*=============================================================================
 * HWG_GETWINDOWRECT()
 * Gets window rectangle
 *===========================================================================*/
HB_FUNC( HWG_GETWINDOWRECT )
{
   RECT rc;
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   PHB_ITEM temp;

   GetWindowRect( ( HWND ) HB_PARHANDLE( 1 ), &rc );

   temp = hb_itemPutNL( NULL, rc.left );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.top );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.right );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.bottom );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

/*=============================================================================
 * HWG_GETCLIENTAREA()
 * Gets client area from paint structure
 *===========================================================================*/
HB_FUNC( HWG_GETCLIENTAREA )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 1 );
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   PHB_ITEM temp;

   temp = hb_itemPutNL( NULL, pps->rcPaint.left );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pps->rcPaint.top );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pps->rcPaint.right );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pps->rcPaint.bottom );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

/*=============================================================================
 * HWG_SETTEXTCOLOR()
 * Sets text color
 *===========================================================================*/
HB_FUNC( HWG_SETTEXTCOLOR )
{
   COLORREF crColor = SetTextColor( ( HDC ) HB_PARHANDLE( 1 ),
         ( COLORREF ) hb_parnl( 2 ) );
   hb_retnl( ( LONG ) crColor );
}

/*=============================================================================
 * HWG_SETBKCOLOR()
 * Sets background color
 *===========================================================================*/
HB_FUNC( HWG_SETBKCOLOR )
{
   COLORREF crColor = SetBkColor( ( HDC ) HB_PARHANDLE( 1 ),
         ( COLORREF ) hb_parnl( 2 ) );
   hb_retnl( ( LONG ) crColor );
}

/*=============================================================================
 * HWG_SETTRANSPARENTMODE()
 * Sets transparent mode
 *===========================================================================*/
HB_FUNC( HWG_SETTRANSPARENTMODE )
{
   int iMode = SetBkMode( ( HDC ) HB_PARHANDLE( 1 ),
         ( hb_parl( 2 ) ) ? TRANSPARENT : OPAQUE );
   hb_retl( iMode == TRANSPARENT );
}

/*=============================================================================
 * HWG_GETTEXTCOLOR()
 * Gets text color
 *===========================================================================*/
HB_FUNC( HWG_GETTEXTCOLOR )
{
   hb_retnl( ( LONG ) GetTextColor( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_GETBKCOLOR()
 * Gets background color
 *===========================================================================*/
HB_FUNC( HWG_GETBKCOLOR )
{
   hb_retnl( ( LONG ) GetBkColor( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_EXTTEXTOUT()
 * Extended text output
 *===========================================================================*/
HB_FUNC( HWG_EXTTEXTOUT )
{
   RECT rc;
   void *hText;
   HB_SIZE nLen;
   LPCTSTR lpText = HB_PARSTR( 8, &hText, &nLen );

   rc.left = hb_parni( 4 );
   rc.top = hb_parni( 5 );
   rc.right = hb_parni( 6 );
   rc.bottom = hb_parni( 7 );

   ExtTextOut( ( HDC ) HB_PARHANDLE( 1 ),
         hb_parni( 2 ),
         hb_parni( 3 ),
         ETO_OPAQUE,
         &rc,
         lpText,
         nLen,
         NULL );
   hb_strfree( hText );
}

/*=============================================================================
 * HWG_WRITESTATUSWINDOW()
 * Writes to status window
 *===========================================================================*/
HB_FUNC( HWG_WRITESTATUSWINDOW )
{
   void *hString;
   HB_SIZE nLen;

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), SB_SETTEXT, hb_parni( 2 ),
                ( LPARAM ) HB_PARSTR( 3, &hString, &nLen ) );
   hb_strfree( hString );
}

/*=============================================================================
 * HWG_WINDOWFROMDC()
 * Gets window from device context
 *===========================================================================*/
HB_FUNC( HWG_WINDOWFROMDC )
{
   HB_RETHANDLE( WindowFromDC( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_CREATEFONT()
 * Creates a font
 *===========================================================================*/
HB_FUNC( HWG_CREATEFONT )
{
   HFONT hFont;
   int fnWeight = ( HB_ISNIL( 4 ) ) ? 0 : hb_parni( 4 );
   DWORD fdwCharSet = ( HB_ISNIL( 5 ) ) ? 0 : hb_parni( 5 );
   DWORD fdwItalic = ( HB_ISNIL( 6 ) ) ? 0 : hb_parni( 6 );
   DWORD fdwUnderline = ( HB_ISNIL( 7 ) ) ? 0 : hb_parni( 7 );
   DWORD fdwStrikeOut = ( HB_ISNIL( 8 ) ) ? 0 : hb_parni( 8 );
   void *hString;

   hFont = CreateFont( hb_parni( 3 ),
         hb_parni( 2 ),
         0,
         0,
         fnWeight,
         fdwItalic,
         fdwUnderline,
         fdwStrikeOut,
         fdwCharSet,
         0,
         0,
         0,
         0,
         HB_PARSTR( 1, &hString, NULL ) );
   hb_strfree( hString );
   HB_RETHANDLE( hFont );
}

/*=============================================================================
 * HWG_SETCTRLFONT()
 * Sets control font
 *===========================================================================*/
HB_FUNC( HWG_SETCTRLFONT )
{
   SendDlgItemMessage( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), WM_SETFONT,
         ( WPARAM ) HB_PARHANDLE( 3 ), 0L );
}

/*=============================================================================
 * HWG_CREATERECTRGN()
 * Creates a rectangular region
 *===========================================================================*/
HB_FUNC( HWG_CREATERECTRGN )
{
   HRGN reg;

   reg = CreateRectRgn( hb_parni( 1 ), hb_parni( 2 ), hb_parni( 3 ),
         hb_parni( 4 ) );

   HB_RETHANDLE( reg );
}

/*=============================================================================
 * HWG_CREATERECTRGNINDIRECT()
 * Creates a rectangular region from RECT
 *===========================================================================*/
HB_FUNC( HWG_CREATERECTRGNINDIRECT )
{
   HRGN reg;
   RECT rc;

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   reg = CreateRectRgnIndirect( &rc );
   HB_RETHANDLE( reg );
}

/*=============================================================================
 * HWG_EXTSELECTCLIPRGN()
 * Extends clip region
 *===========================================================================*/
HB_FUNC( HWG_EXTSELECTCLIPRGN )
{
   hb_retni( ExtSelectClipRgn( ( HDC ) HB_PARHANDLE( 1 ),
               ( HRGN ) HB_PARHANDLE( 2 ), hb_parni( 3 ) ) );
}

/*=============================================================================
 * HWG_SELECTCLIPRGN()
 * Selects clip region
 *===========================================================================*/
HB_FUNC( HWG_SELECTCLIPRGN )
{
   hb_retni( SelectClipRgn( ( HDC ) HB_PARHANDLE( 1 ),
               ( HRGN ) HB_PARHANDLE( 2 ) ) );
}

/*=============================================================================
 * HWG_CREATEFONTINDIRECT()
 * Creates a font from LOGFONT structure
 *===========================================================================*/
HB_FUNC( HWG_CREATEFONTINDIRECT )
{
   LOGFONT lf;
   HFONT f;
   memset( &lf, 0, sizeof( LOGFONT ) );
   lf.lfQuality = hb_parni( 4 );
   lf.lfHeight = hb_parni( 3 );
   lf.lfWeight = hb_parni( 2 );
   HB_ITEMCOPYSTR( hb_param( 1, HB_IT_ANY ), lf.lfFaceName,
         HB_SIZEOFARRAY( lf.lfFaceName ) );
   lf.lfFaceName[HB_SIZEOFARRAY( lf.lfFaceName ) - 1] = '\0';

   f = CreateFontIndirect( &lf );
   HB_RETHANDLE( f );
}

/*=============================================================================
 * GetFontsCallback()
 * Callback for enumerating fonts
 *===========================================================================*/
#if defined(HB_API_MACROS) || (__HARBOUR__ - 0 > 0x030000)
int CALLBACK GetFontsCallback( ENUMLOGFONTEX *lpelfe, NEWTEXTMETRICEX *lpntme,
      DWORD FontType, LPARAM lParam )
{
   /* FIXED (HB_MT): read/write the per-call context passed via lParam
    * instead of file-scope statics. */
   HWG_FONTENUM_CTX *pCtx = ( HWG_FONTENUM_CTX * ) lParam;

   HB_SYMBOL_UNUSED( lpntme );
   HB_SYMBOL_UNUSED( FontType );

   HB_ITEMPUTSTR( pCtx->pFontsItem, (LPCTSTR)lpelfe->elfFullName );
   if( !hb_itemEqual( pCtx->pFontsItem, pCtx->pFontsItemLast ) )
   {
      HB_ITEMPUTSTR( pCtx->pFontsItemLast, (LPCTSTR)lpelfe->elfFullName );
      hb_arrayAdd( pCtx->aFontsList, pCtx->pFontsItem );
   }
   return 1;
}

/*=============================================================================
 * HWG_GETFONTSLIST()
 * Gets list of available fonts
 *===========================================================================*/
HB_FUNC( HWG_GETFONTSLIST )
{
   LOGFONT lf;
   HDC hDC;
   /* FIXED (HB_MT): local (stack) context - one private copy per call/
    * per thread, instead of shared file-scope statics. */
   HWG_FONTENUM_CTX ctx;

   hDC = GetDC( GetDesktopWindow() );

   memset(&lf, 0, sizeof(lf));
   lf.lfCharSet = DEFAULT_CHARSET;
   ctx.aFontsList = hb_itemArrayNew( 0 );
   ctx.pFontsItem = hb_itemPutC( NULL, "" );
   ctx.pFontsItemLast = hb_itemPutC( NULL, "" );

   EnumFontFamiliesEx( hDC, &lf, (FONTENUMPROC)GetFontsCallback, ( LPARAM ) &ctx, 0 );

   ReleaseDC( GetDesktopWindow(), hDC );   /* FIXED: Release DC to prevent leak */

   hb_itemRelease( ctx.pFontsItem );
   hb_itemRelease( ctx.pFontsItemLast );
   hb_itemReturnRelease( ctx.aFontsList );
}
#endif
