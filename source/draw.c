/*
 * $Id: draw.c,v 1.28 2007-08-20 14:56:57 lculik Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level painting functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0500
#define OEMRESOURCE
#include <windows.h>

#include "guilib.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"


BOOL Array2Rect(PHB_ITEM aRect, RECT *rc )
{
   if (HB_IS_ARRAY(aRect) && hb_arrayLen(aRect) == 4) {
      rc->left   = hb_arrayGetNL(aRect,1);
      rc->top    = hb_arrayGetNL(aRect,2);
      rc->right  = hb_arrayGetNL(aRect,3);
      rc->bottom = hb_arrayGetNL(aRect,4);
      return TRUE ;
   }
   return FALSE;
}

PHB_ITEM Rect2Array( RECT *rc  )
{
   PHB_ITEM aRect = hb_itemArrayNew(4);
   PHB_ITEM element = hb_itemNew(NULL);

   hb_arraySet(aRect, 1, hb_itemPutNL(element, rc->left));
   hb_arraySet(aRect, 2, hb_itemPutNL(element, rc->top));
   hb_arraySet(aRect, 3, hb_itemPutNL(element, rc->right));
   hb_arraySet(aRect, 4, hb_itemPutNL(element, rc->bottom));
   hb_itemRelease(element);
   return aRect;
}

HB_FUNC( INVALIDATERECT )
{
   RECT rc;

   if( hb_pcount() > 2 )
   {
      rc.left = hb_parni( 3 );
      rc.top = hb_parni( 4 );
      rc.right = hb_parni( 5 );
      rc.bottom = hb_parni( 6 );
   }

   InvalidateRect(
    (HWND) hb_parnl( 1 ),	// handle of window with changed update region
    ( hb_pcount() > 2 )? &rc:NULL,	// address of rectangle coordinates
    hb_parni( 2 )	// erase-background flag
   );
}

HB_FUNC( RECTANGLE )
{
   HDC hDC = (HDC) hb_parnl( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 ), x2 = hb_parni( 4 ), y2 = hb_parni( 5 );
   MoveToEx( hDC, x1, y1, NULL );
   LineTo( hDC, x2, y1 );
   LineTo( hDC, x2, y2 );
   LineTo( hDC, x1, y2 );
   LineTo( hDC, x1, y1 );
/*
   Rectangle(
    (HDC) hb_parnl( 1 ),	// handle of device context
    hb_parni( 2 ),	// x-coord. of bounding rectangle's upper-left corner
    hb_parni( 3 ),	// y-coord. of bounding rectangle's upper-left corner
    hb_parni( 4 ),	// x-coord. of bounding rectangle's lower-right corner
    hb_parni( 5 ) 	// y-coord. of bounding rectangle's lower-right corner
   );
*/
}

HB_FUNC( DRAWLINE )
{
   MoveToEx( (HDC) hb_parnl( 1 ), hb_parni( 2 ), hb_parni( 3 ), NULL );
   LineTo( (HDC) hb_parnl( 1 ), hb_parni( 4 ), hb_parni( 5 ) );
}

HB_FUNC( PIE )
{
   int res = Pie(
    (HDC) hb_parnl(1),	// handle to device context
    hb_parni(2),	// x-coord. of bounding rectangle's upper-left corner
    hb_parni(3),	// y-coord. of bounding rectangle's upper-left corner
    hb_parni(4),	// x-coord. of bounding rectangle's lower-right corner
    hb_parni(5), 	// y-coord. bounding rectangle's f lower-right corner
    hb_parni(6),	// x-coord. of first radial's endpoint
    hb_parni(7),	// y-coord. of first radial's endpoint
    hb_parni(8),	// x-coord. of second radial's endpoint
    hb_parni(9) 	// y-coord. of second radial's endpoint
   );
   if( !res )
     hb_retnl( (LONG) GetLastError() );
   else
     hb_retnl( 0 );
}

HB_FUNC( ELLIPSE )
{
   int res =  Ellipse(
    (HDC) hb_parnl(1),	// handle to device context
    hb_parni(2),	// x-coord. of bounding rectangle's upper-left corner
    hb_parni(3),	// y-coord. of bounding rectangle's upper-left corner
    hb_parni(4),	// x-coord. of bounding rectangle's lower-right corner
    hb_parni(5) 	// y-coord. bounding rectangle's f lower-right corner
   );
   if( !res )
     hb_retnl( (LONG) GetLastError() );
   else
     hb_retnl( 0 );
}

HB_FUNC( FILLRECT )
{
   RECT rc;

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   FillRect(
    (HDC) hb_parnl( 1 ),      // handle to device context
    &rc,                      // pointer to structure with rectangle
    (HBRUSH) hb_parnl( 6 )    // handle to brush
   );
}

HB_FUNC( ROUNDRECT )
{
   hb_parl( RoundRect(
    (HDC) hb_parnl( 1 ),   // handle of device context
    hb_parni( 2 ),         // x-coord. of bounding rectangle's upper-left corner
    hb_parni( 3 ),         // y-coord. of bounding rectangle's upper-left corner
    hb_parni( 4 ),         // x-coord. of bounding rectangle's lower-right corner
    hb_parni( 5 ),         // y-coord. of bounding rectangle's lower-right corner
    hb_parni( 6 ),         // width of ellipse used to draw rounded corners
    hb_parni( 7 )          // height of ellipse used to draw rounded corners
   ) );
}

HB_FUNC( REDRAWWINDOW )
{
   RedrawWindow(
    (HWND) hb_parnl( 1 ),  // handle of window
    NULL,                  // address of structure with update rectangle
    NULL,                  // handle of update region
    (UINT)hb_parni( 2 )    // array of redraw flags
   );
}

HB_FUNC( DRAWBUTTON )
{
   RECT rc;
   HDC hDC = (HDC) hb_parnl( 1 );
   UINT iType = hb_parni( 6 );

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   if( iType == 0 )
      FillRect( hDC, &rc, (HBRUSH) (COLOR_3DFACE+1) );
   else
   {
      FillRect( hDC, &rc, (HBRUSH) ( ( (iType & 2)? COLOR_3DSHADOW:COLOR_3DHILIGHT )+1) );
      rc.left ++; rc.top ++;
      FillRect( hDC, &rc, (HBRUSH) ( ( (iType & 2)? COLOR_3DHILIGHT:(iType & 4)? COLOR_3DDKSHADOW:COLOR_3DSHADOW )+1) );
      rc.right --; rc.bottom --;
      if( iType & 4 )
      {
         FillRect( hDC, &rc, (HBRUSH) ( ( (iType & 2)? COLOR_3DSHADOW:COLOR_3DLIGHT )+1) );
         rc.left ++; rc.top ++;
         FillRect( hDC, &rc, (HBRUSH) ( ( (iType & 2)? COLOR_3DLIGHT:COLOR_3DSHADOW )+1) );
         rc.right --; rc.bottom --;
      }
      FillRect( hDC, &rc, (HBRUSH) (COLOR_3DFACE+1) );
   }
}

/*
 * DrawEdge( hDC,x1,y1,x2,y2,nFlag,nBorder )
 */
HB_FUNC( DRAWEDGE )
{
   RECT rc;
   HDC hDC = (HDC) hb_parnl( 1 );
   UINT edge = (ISNIL(6))? EDGE_RAISED : (UINT) hb_parni(6);
   UINT grfFlags = (ISNIL(7))? BF_RECT : (UINT) hb_parni(7);

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   hb_retl( DrawEdge( hDC, &rc, edge, grfFlags ) );
}

HB_FUNC( LOADICON )
{
   if( ISNUM(1) )
      hb_retnl( (LONG) LoadIcon( NULL, (LPCTSTR) hb_parnl( 1 ) ) );
   else
      hb_retnl( (LONG) LoadIcon( GetModuleHandle( NULL ), (LPCTSTR) hb_parc( 1 ) ) );
}

HB_FUNC( LOADIMAGE )
{
   if ( ISNUM( 2 ) )
      hb_retnl( (LONG)
          LoadImage( ISNIL( 1 ) ? GetModuleHandle(NULL) : (HINSTANCE) hb_parnl( 1 ),    // handle of the instance that contains the image
                  (LPCTSTR)MAKEINTRESOURCE(hb_parnl(2)),          // name or identifier of image
                  (UINT) hb_parni(3),           // type of image
                  hb_parni(4),                  // desired width
                  hb_parni(5),                  // desired height
                  (UINT)hb_parni(6)             // load flags
     ) ) ;

   else
      hb_retnl( (LONG)
          LoadImage( (HINSTANCE)hb_parnl(1),    // handle of the instance that contains the image
                  (LPCTSTR)hb_parc(2),          // name or identifier of image
                  (UINT) hb_parni(3),           // type of image
                  hb_parni(4),                  // desired width
                  hb_parni(5),                  // desired height
                  (UINT)hb_parni(6)             // load flags
      ) );

}

HB_FUNC( LOADBITMAP )
{
   if( ISNUM(1) )
   {
      if( !ISNIL(2) && hb_parl(2) )
               hb_retnl( (LONG) LoadBitmap( GetModuleHandle( NULL ),  MAKEINTRESOURCE(hb_parnl( 1 ) )) );
//         hb_retnl( (LONG) LoadBitmap( NULL, (LPCTSTR) hb_parnl( 1 ) ) );
      else
         hb_retnl( (LONG) LoadBitmap( GetModuleHandle( NULL ), (LPCTSTR) hb_parnl( 1 ) ) );
   }
   else
      hb_retnl( (LONG) LoadBitmap( GetModuleHandle( NULL ), (LPCTSTR) hb_parc( 1 ) ) );
}

/*
 * Window2Bitmap( hWnd )
 */
HB_FUNC( WINDOW2BITMAP )
{
   HWND hWnd = (HWND) hb_parnl(1);
   BOOL lFull = ( ISNIL(2) )? 0 : (BOOL)hb_parl(2);
   HDC hDC = ( lFull )? GetWindowDC( hWnd ) : GetDC( hWnd );
   HDC hDCmem = CreateCompatibleDC( hDC );
   HBITMAP hBitmap;
   RECT rc;

   if( lFull )
      GetWindowRect( hWnd, &rc );
   else
      GetClientRect( hWnd, &rc );
   hBitmap = CreateCompatibleBitmap( hDC, rc.right-rc.left, rc.bottom-rc.top );
   SelectObject( hDCmem, hBitmap );

   BitBlt( hDCmem, 0, 0, rc.right-rc.left, rc.bottom-rc.top, hDC, 0, 0, SRCCOPY );

   DeleteDC( hDCmem );
   DeleteDC( hDC );
   hb_retnl( (LONG) hBitmap );
}

/*
 * DrawBitmap( hDC, hBitmap, style, x, y, width, height )
 */
HB_FUNC( DRAWBITMAP )
{
   HDC hDC = (HDC) hb_parnl( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );
   DWORD dwraster = (ISNIL(3))? SRCCOPY:hb_parnl(3);
   HBITMAP hBitmap = (HBITMAP) hb_parnl( 2 );
   BITMAP  bitmap;
   int nWidthDest = ( hb_pcount()>=5 && !ISNIL(6) )? hb_parni(6):0;
   int nHeightDest = ( hb_pcount()>=6 && !ISNIL(7) )? hb_parni(7):0;

   SelectObject( hDCmem, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) &bitmap );
   if( nWidthDest && ( nWidthDest != bitmap.bmWidth || nHeightDest != bitmap.bmHeight ))
   {
      StretchBlt( hDC, hb_parni(4), hb_parni(5), nWidthDest, nHeightDest, hDCmem,
                  0, 0, bitmap.bmWidth, bitmap.bmHeight, dwraster );
   }
   else
   {
      BitBlt( hDC, hb_parni(4), hb_parni(5), bitmap.bmWidth, bitmap.bmHeight, hDCmem, 0, 0, dwraster );
   }

   DeleteDC( hDCmem );
}

/*
 * DrawTransparentBitmap( hDC, hBitmap, x, y [,trColor] )
 */
HB_FUNC( DRAWTRANSPARENTBITMAP )
{
   HDC hDC = (HDC) hb_parnl( 1 );
   HBITMAP hBitmap = (HBITMAP) hb_parnl( 2 );
   COLORREF trColor = (ISNIL(5))? 0x00FFFFFF : (COLORREF)hb_parnl(5);
   COLORREF crOldBack = SetBkColor( hDC, 0x00FFFFFF );
   COLORREF crOldText = SetTextColor( hDC, 0 );
   HBITMAP bitmapTrans;
   HBITMAP pOldBitmapImage, pOldBitmapTrans;
   BITMAP  bitmap;
   HDC dcImage, dcTrans;
   int x = hb_parni( 3 );
   int y = hb_parni( 4 );

   // Create two memory dcs for the image and the mask
   dcImage = CreateCompatibleDC( hDC );
   dcTrans = CreateCompatibleDC( hDC );
   // Select the image into the appropriate dc
   pOldBitmapImage = (HBITMAP) SelectObject( dcImage, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) &bitmap );
   // Create the mask bitmap
   bitmapTrans = CreateBitmap( bitmap.bmWidth, bitmap.bmHeight, 1, 1, NULL);
   // Select the mask bitmap into the appropriate dc
   pOldBitmapTrans = (HBITMAP) SelectObject( dcTrans, bitmapTrans );
   // Build mask based on transparent colour
   SetBkColor( dcImage, trColor );
   BitBlt( dcTrans, 0, 0, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCCOPY );
   // Do the work - True Mask method - cool if not actual display
   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCINVERT );
   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcTrans, 0, 0, SRCAND );
   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCINVERT );
   // Restore settings
   SelectObject( dcImage, pOldBitmapImage);
   SelectObject( dcTrans, pOldBitmapTrans );
   SetBkColor( hDC,crOldBack );
   SetTextColor( hDC,crOldText );

   DeleteObject( bitmapTrans );
   DeleteDC( dcImage );
   DeleteDC( dcTrans );
}

/*  SpreadBitmap( hDC, hWnd, hBitmap, style )
*/
HB_FUNC( SPREADBITMAP )
{
   HDC hDC = (HDC) hb_parnl( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );
   DWORD dwraster = (ISNIL(4))? SRCCOPY:hb_parnl(4);
   HBITMAP hBitmap = (HBITMAP) hb_parnl( 3 );
   BITMAP  bitmap;
   RECT rc;

   SelectObject( hDCmem, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) &bitmap );
   GetClientRect( (HWND) hb_parnl( 2 ),	&rc );

   while( rc.top < rc.bottom )
   {
      while( rc.left < rc.right )
      {
         BitBlt( hDC, rc.left, rc.top, bitmap.bmWidth, bitmap.bmHeight, hDCmem, 0, 0, dwraster );
         rc.left += bitmap.bmWidth;
      }
      rc.left = 0;
      rc.top += bitmap.bmHeight;
   }

   DeleteDC( hDCmem );
}

HB_FUNC( GETBITMAPSIZE )
{
   BITMAP  bitmap;
   PHB_ITEM aMetr = hb_itemArrayNew( 3 );
   PHB_ITEM temp;

   GetObject( (HBITMAP) hb_parnl( 1 ), sizeof( BITMAP ), ( LPVOID ) &bitmap );

   temp = hb_itemPutNL( NULL, bitmap.bmWidth );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, bitmap.bmHeight );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, bitmap.bmBitsPixel );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( GETICONSIZE )
{
   ICONINFO iinfo;
   PHB_ITEM aMetr = hb_itemArrayNew( 2 );
   PHB_ITEM temp;

   GetIconInfo( (HICON) hb_parnl( 1 ), &iinfo );

   temp = hb_itemPutNL( NULL, iinfo.xHotspot * 2 );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, iinfo.yHotspot * 2 );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( OPENBITMAP )
{
   BITMAPFILEHEADER bmfh;
   BITMAPINFOHEADER bmih;
   LPBITMAPINFO lpbmi;
   DWORD dwRead;
   LPVOID lpvBits;
   HGLOBAL hmem1, hmem2;
   HBITMAP hbm;
   HDC hDC = (hb_pcount()>1 && !ISNIL(2))? (HDC)hb_parnl(2):NULL;
   HANDLE hfbm = CreateFile( hb_parc( 1 ), GENERIC_READ, FILE_SHARE_READ,
                   (LPSECURITY_ATTRIBUTES) NULL, OPEN_EXISTING,
                   FILE_ATTRIBUTE_READONLY, (HANDLE) NULL );

   if( ( (long int)hfbm ) <= 0 )
   {
      hb_retnl(0);
      return;
   }
   /* Retrieve the BITMAPFILEHEADER structure. */
   ReadFile( hfbm, &bmfh, sizeof(BITMAPFILEHEADER), &dwRead, NULL );

   /* Retrieve the BITMAPFILEHEADER structure. */
   ReadFile( hfbm, &bmih, sizeof(BITMAPINFOHEADER), &dwRead, NULL );

   /* Allocate memory for the BITMAPINFO structure. */

   hmem1 = GlobalAlloc( GHND, sizeof(BITMAPINFOHEADER) +
             ((1<<bmih.biBitCount) * sizeof(RGBQUAD)));
   lpbmi = (LPBITMAPINFO)GlobalLock( hmem1 );

   /*  Load BITMAPINFOHEADER into the BITMAPINFO  structure. */
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

   /*  Retrieve the color table.
    * 1 << bmih.biBitCount == 2 ^ bmih.biBitCount
   */
   switch(bmih.biBitCount)
   {
      case 1  :
      case 4  :
      case 8  : ReadFile(hfbm, lpbmi->bmiColors,
      ((1<<bmih.biBitCount) * sizeof(RGBQUAD)),
      &dwRead, (LPOVERLAPPED) NULL);
                break;
      case 16 :
      case 32 : if( bmih.biCompression == BI_BITFIELDS )
                   ReadFile(hfbm, lpbmi->bmiColors,
                   ( 3 * sizeof(RGBQUAD)),
                   &dwRead, (LPOVERLAPPED) NULL);
                break;
      case 24 : break;
   }

   /* Allocate memory for the required number of  bytes. */
   hmem2 = GlobalAlloc( GHND, (bmfh.bfSize - bmfh.bfOffBits) );
   lpvBits = GlobalLock(hmem2);

   /* Retrieve the bitmap data. */

   ReadFile(hfbm, lpvBits, (bmfh.bfSize - bmfh.bfOffBits), &dwRead, NULL );

   if( !hDC )
      hDC = GetDC( 0 );
  /* Create a bitmap from the data stored in the .BMP file.  */
   hbm = CreateDIBitmap( hDC, &bmih, CBM_INIT, lpvBits, lpbmi, DIB_RGB_COLORS );
   if( hb_pcount() < 2 || ISNIL(2) )
      ReleaseDC( 0, hDC );

  /* Unlock the global memory objects and close the .BMP file. */

   GlobalUnlock(hmem1);
   GlobalUnlock(hmem2);
   GlobalFree(hmem1);
   GlobalFree(hmem2);
   CloseHandle(hfbm);
   hb_retnl( (LONG) hbm );
}

HB_FUNC( DRAWICON )
{
   DrawIcon( (HDC)hb_parnl( 1 ), hb_parni( 3 ), hb_parni( 4 ), (HICON)hb_parnl( 2 ) );
}

HB_FUNC( GETSYSCOLOR )
{
   hb_retnl( (LONG) GetSysColor( hb_parni( 1 ) ) );
}

HB_FUNC( CREATEPEN )
{
   hb_retnl( (LONG) CreatePen(
               hb_parni( 1 ),	// pen style
               hb_parni( 2 ),	// pen width
               (COLORREF) hb_parnl( 3 ) 	// pen color
             ) );
}

HB_FUNC( CREATESOLIDBRUSH )
{
   hb_retnl( (LONG) CreateSolidBrush(
               (COLORREF) hb_parnl( 1 ) 	// brush color
             ) );
}

HB_FUNC( CREATEHATCHBRUSH )
{
   hb_retnl( (LONG) CreateHatchBrush(
               hb_parni(1), (COLORREF) hb_parnl(2) ) );
}

HB_FUNC( SELECTOBJECT )
{
   hb_retnl( (LONG) SelectObject(
              (HDC) hb_parnl( 1 ),	// handle of device context
              (HGDIOBJ) hb_parnl( 2 ) 	// handle of object
             ) );
}

HB_FUNC( DELETEOBJECT )
{
   DeleteObject(
      (HGDIOBJ) hb_parnl( 1 ) 	// handle of object
   );
}

HB_FUNC( GETDC )
{
   hb_retnl( (LONG) GetDC( (HWND) hb_parnl( 1 ) ) );
}

HB_FUNC( RELEASEDC )
{
   hb_retnl( (LONG) ReleaseDC( (HWND) hb_parnl( 1 ), (HDC) hb_parnl( 2 ) ) );
}

HB_FUNC( GETDRAWITEMINFO )
{
   DRAWITEMSTRUCT * lpdis = (DRAWITEMSTRUCT*)hb_parnl(1);
   PHB_ITEM aMetr = _itemArrayNew( 9 );
   PHB_ITEM temp;

   temp = _itemPutNL( NULL, lpdis->itemID );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->itemAction );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, (LONG)lpdis->hDC );
   _itemArrayPut( aMetr, 3, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->rcItem.left );
   _itemArrayPut( aMetr, 4, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->rcItem.top );
   _itemArrayPut( aMetr, 5, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->rcItem.right );
   _itemArrayPut( aMetr, 6, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->rcItem.bottom );
   _itemArrayPut( aMetr, 7, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, (LONG)lpdis->hwndItem );
   _itemArrayPut( aMetr, 8, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, (LONG)lpdis->itemState );
   _itemArrayPut( aMetr, 9, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );
}

/*
 * DrawGrayBitmap( hDC, hBitmap, x, y )
 */
HB_FUNC( DRAWGRAYBITMAP )
{
   HDC hDC = (HDC) hb_parnl( 1 );
   HBITMAP hBitmap = (HBITMAP) hb_parnl( 2 );
   HBITMAP bitmapgray;
   HBITMAP pOldBitmapImage, pOldbitmapgray;
   BITMAP  bitmap;
   HDC dcImage, dcTrans;
   int x = hb_parni( 3 );
   int y = hb_parni( 4 );

   SetBkColor( hDC, GetSysColor( COLOR_BTNHIGHLIGHT ) );
   SetTextColor( hDC, GetSysColor( COLOR_BTNFACE   ) );
   // Create two memory dcs for the image and the mask
   dcImage = CreateCompatibleDC( hDC );
   dcTrans = CreateCompatibleDC( hDC );
   // Select the image into the appropriate dc
   pOldBitmapImage = (HBITMAP) SelectObject( dcImage, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) &bitmap );
   // Create the mask bitmap
   bitmapgray = CreateBitmap( bitmap.bmWidth, bitmap.bmHeight, 1, 1, NULL);
   // Select the mask bitmap into the appropriate dc
   pOldbitmapgray = (HBITMAP) SelectObject( dcTrans, bitmapgray );
   // Build mask based on transparent colour
   SetBkColor( dcImage, RGB( 255, 255, 255 ) );
   BitBlt( dcTrans, 0, 0, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCCOPY );
   // Do the work - True Mask method - cool if not actual display
   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCINVERT );
   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcTrans, 0, 0, SRCAND );
   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCINVERT );
   // Restore settings
   SelectObject( dcImage, pOldBitmapImage);
   SelectObject( dcTrans, pOldbitmapgray );
   SetBkColor( hDC, GetPixel (hDC, 0, 0 ) );
   SetTextColor( hDC, 0 );

   DeleteObject( bitmapgray );
   DeleteDC( dcImage );
   DeleteDC( dcTrans );
}

#include <olectl.h>
#include <ole2.h>
#include <ocidl.h>

HB_FUNC( OPENIMAGE )
{
   char* cFileName = hb_parc(1);
   BOOL  lString = (ISNIL(2))? 0 : hb_parl(2);
   int iFileSize;
   FILE* fp;
   // IPicture * pPic;
   LPPICTURE pPic;
   IStream * pStream;
   HGLOBAL hG;
   HBITMAP hBitmap = 0;

   if( lString )
   {
      iFileSize = hb_parclen( 1 );
      hG = GlobalAlloc( GPTR,iFileSize );
      if( !hG )
      {
         hb_retnl(0);
         return;
      }
      memcpy( (void*)hG, (void*)cFileName,iFileSize );
   }
   else
   {
      fp = fopen( cFileName,"rb" );
      if( !fp )
      {
         hb_retnl(0);
         return;
      }

      fseek( fp,0,SEEK_END );
      iFileSize = ftell( fp );
      hG = GlobalAlloc( GPTR,iFileSize );
      if( !hG )
      {
         fclose( fp );
         hb_retnl(0);
         return;
      }
      fseek( fp,0,SEEK_SET );
      fread( (void*)hG, 1, iFileSize, fp );
      fclose( fp );
   }
   CreateStreamOnHGlobal( hG,0,&pStream );
   if( !pStream )
   {
      GlobalFree( hG );
      hb_retnl(0);
      return;
   }

#if !defined(__BORLANDC__) && !defined(__MINGW32__)  && !defined(__POCC__) && !defined(__XCC__) //&& !defined(_MSC_VER)
   OleLoadPicture( pStream,0,0,IID_IPicture,(void**)&pPic );
   pStream->Release();
#else
   OleLoadPicture( pStream,0,0,&IID_IPicture,(void**)&pPic );
   pStream->lpVtbl->Release( pStream );
#endif

   GlobalFree( hG );

   if( !pPic )
   {
      hb_retnl(0);
      return;
   }

#if !defined(__BORLANDC__) && !defined(__MINGW32__) && !defined(__POCC__) && !defined(__XCC__) //&& !defined(_MSC_VER)
   pPic->get_Handle( (OLE_HANDLE*)&hBitmap );
#else
   pPic->lpVtbl->get_Handle( pPic, (OLE_HANDLE*)&hBitmap );
#endif

   hb_retnl( (LONG) CopyImage( hBitmap,IMAGE_BITMAP,0,0,LR_COPYRETURNORG ) );
#if !defined(__BORLANDC__) && !defined(__MINGW32__) && !defined(__POCC__) && !defined(__XCC__) //&& !defined(_MSC_VER)
   pPic->Release();
#else
   pPic->lpVtbl->Release( pPic );
#endif
}

HB_FUNC(PATBLT)
{
   hb_retl( PatBlt( (HDC) hb_parnl( 1 ),hb_parni(2),hb_parni(3),hb_parni(4),hb_parni(5),hb_parnl(6)));
}

HB_FUNC(SAVEDC)
{
   hb_retl(SaveDC((HDC) hb_parnl( 1 )));
}

HB_FUNC(RESTOREDC)
{
   hb_retl( RestoreDC((HDC) hb_parnl( 1 ),hb_parni( 2 ) ));
}

HB_FUNC(CREATECOMPATIBLEDC)
{
   HDC hDC=(HDC)hb_parnl( 1 ) ;
   HDC hDCmem = CreateCompatibleDC( hDC );
   hb_retnl( (LONG) hDCmem );
}

HB_FUNC(SETMAPMODE)
{
   HDC hDC=(HDC)hb_parnl( 1 ) ;
   hb_retni(SetMapMode(hDC,hb_parni( 2 ) ) );
}


HB_FUNC(SETWINDOWORGEX)
{
   HDC hDC=(HDC)hb_parnl( 1 ) ;
   SetWindowOrgEx(hDC,hb_parni( 2 ), hb_parni( 3 ) , NULL);
   hb_stornl(0,4);
}


HB_FUNC(SETWINDOWEXTEX)
{
   HDC hDC=(HDC)hb_parnl( 1 ) ;
   SetWindowExtEx(hDC,hb_parni( 2 ), hb_parni( 3 ) , NULL);
   hb_stornl(0,4);
}


HB_FUNC(SETVIEWPORTORGEX)
{
   HDC hDC=(HDC)hb_parnl( 1 ) ;
   SetViewportOrgEx(hDC,hb_parni( 2 ), hb_parni( 3 ) , NULL);
   hb_stornl(0,4);
}


HB_FUNC(SETVIEWPORTEXTEX)
{
   HDC hDC=(HDC)hb_parnl( 1 ) ;
   SetViewportExtEx(hDC,hb_parni( 2 ), hb_parni( 3 ) , NULL);
   hb_stornl(0,4);
}

HB_FUNC(SETARCDIRECTION)
{
   HDC hDC=(HDC)hb_parnl( 1 ) ;
   hb_retni(SetArcDirection(hDC,hb_parni( 2 ) )) ;
}

HB_FUNC(SETROP2)
{
   HDC hDC=(HDC)hb_parnl( 1 ) ;
   hb_retni( SetROP2(hDC,hb_parni( 2 ) )) ;
}


HB_FUNC(BITBLT)
{
  HDC hDC=(HDC)hb_parnl( 1 ) ;
  HDC hDC1=(HDC)hb_parnl( 6 ) ;
  hb_retl( BitBlt(hDC,hb_parni(2), hb_parni(3),hb_parni(4), hb_parni(5), hDC1,
      hb_parni(7), hb_parni(8), hb_parnl(9)));
}

HB_FUNC(CREATECOMPATIBLEBITMAP)
{
  HDC hDC=(HDC)hb_parnl( 1 ) ;
  HBITMAP hBitmap;
  hBitmap = CreateCompatibleBitmap( hDC, hb_parni(2),hb_parni(3) );
  hb_retnl((LONG)hBitmap);

}

HB_FUNC( INFLATERECT )
{
	
   RECT pRect ;   
   BOOL bRectOk = ( ISARRAY( 1 )  &&   Array2Rect( hb_param( 1, HB_IT_ARRAY ), &pRect ) ) ;        
   int x = hb_parni( 2) ;
   int y = hb_parni( 3 );
   hb_retl( InflateRect( &pRect, x, y )) ;
   
   hb_storni( pRect.left   , 1 , 1);
   hb_storni( pRect.top    , 1 , 2);
   hb_storni( pRect.right  , 1 , 3);
   hb_storni( pRect.bottom , 1 , 4);   
}   

HB_FUNC( FRAMERECT )
{
	
   HDC hdc=   (HDC ) hb_parnl( 1 ) ;
   HBRUSH hbr = (HBRUSH) hb_parnl( 3 ) ;
   RECT pRect ;   

   BOOL bRectOk = ( ISARRAY( 2 )  &&   Array2Rect( hb_param( 2, HB_IT_ARRAY ), &pRect ) ) ;        

   hb_retni( FrameRect( hdc, &pRect, hbr )) ;
   
   
}   

HB_FUNC( DRAWFRAMECONTROL )
{
	
   HDC hdc=   (HDC ) hb_parnl( 1 ) ;   
   RECT pRect ;   
   BOOL bRectOk = ( ISARRAY( 2 )  &&   Array2Rect( hb_param( 2, HB_IT_ARRAY ), &pRect ) ) ;        
   UINT uType = hb_parni( 3 ) ;  // frame-control type
   UINT uState = hb_parni( 4 ) ;  // frame-control state
   hb_retl( DrawFrameControl( hdc, &pRect, uType, uState ) ) ;
   
   
}   

HB_FUNC( OFFSETRECT )
{
	
   RECT pRect ;   
   BOOL bRectOk = ( ISARRAY( 1 )  &&   Array2Rect( hb_param( 1, HB_IT_ARRAY ), &pRect ) ) ;        
   int x = hb_parni( 2) ;
   int y = hb_parni( 3 );
   hb_retl( OffsetRect( &pRect, x, y )) ;
   
   hb_storni( pRect.left   , 1 , 1);
   hb_storni( pRect.top    , 1 , 2);
   hb_storni( pRect.right  , 1 , 3);
   hb_storni( pRect.bottom , 1 , 4);   
}   

HB_FUNC(DRAWFOCUSRECT)

{
   RECT pRect ;
   HDC hc = (HDC) hb_parnl( 1) ;
   BOOL bRectOk = ( ISARRAY( 2 )  &&   Array2Rect( hb_param( 2, HB_IT_ARRAY ), &pRect ) ) ;        
   hb_retl( DrawFocusRect( hc,&pRect )) ;
}

BOOL Array2Point(PHB_ITEM aPoint, POINT *pt )
{
   if (HB_IS_ARRAY(aPoint) && hb_arrayLen(aPoint) == 2) {
      pt->x = hb_arrayGetNL(aPoint,1);
      pt->y = hb_arrayGetNL(aPoint,2);
      return TRUE ;
   }
   return FALSE;
}


HB_FUNC(PTINRECT)
{
   POINT pt;
   RECT rect;
   Array2Rect(hb_param(1,HB_IT_ARRAY), &rect );
   Array2Point(hb_param(2,HB_IT_ARRAY), &pt );
   hb_retl(PtInRect(&rect,pt));
}


HB_FUNC (GETMEASUREITEMINFO)
{
   MEASUREITEMSTRUCT * lpdis = (MEASUREITEMSTRUCT*)hb_parnl(1);
   PHB_ITEM aMetr = _itemArrayNew( 5 );
   PHB_ITEM temp;

   temp = _itemPutNL( NULL, lpdis->CtlType );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->CtlID);
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->itemID);
   _itemArrayPut( aMetr, 3, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->itemWidth );
   _itemArrayPut( aMetr, 4, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->itemHeight );
   _itemArrayPut( aMetr, 5, temp );
   _itemRelease( temp );
   _itemReturn( aMetr );
   _itemRelease( aMetr );
}
