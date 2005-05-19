/*
 * $Id: freeimg.c,v 1.8 2005-05-19 19:54:21 lf_sfnet Exp $
 *
 * FreeImage wrappers for Harbour/HwGUI
 *
 * Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

/*
// How do I convert a HBITMAP to a FreeImage image ?

   HBITMAP hbmp;
   FIBITMAP *dib;
   if(hbmp) {
      BITMAP bm;
      GetObject(hbmp, sizeof(BITMAP), (LPSTR) &bm);
      dib = FreeImage_Allocate(bm.bmWidth, bm.bmHeight, bm.bmBitsPixel);
      HDC dc = GetDC(NULL);
      int Success = GetDIBits(dc, hbmp, 0, FreeImage_GetHeight(dib),
         FreeImage_GetBits(dib), FreeImage_GetInfo(dib), DIB_RGB_COLORS);
      ReleaseDC(NULL, dc);
   }
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
#include <windows.h>

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "freeimage.h"

typedef char * ( WINAPI *FREEIMAGE_GETVERSION )( void );
#if defined(__WATCOMC__)
typedef FIBITMAP* ( WINAPI *FREEIMAGE_LOAD)( FREE_IMAGE_FORMAT fif, char *filename, int flags );
#else
typedef FIBITMAP* ( WINAPI *FREEIMAGE_LOAD)( FREE_IMAGE_FORMAT fif, char *filename, int flags FI_DEFAULT(0) );
#endif
typedef void ( WINAPI *FREEIMAGE_UNLOAD )( FIBITMAP *dib );
#if defined(__WATCOMC__)
typedef BOOL ( WINAPI *FREEIMAGE_SAVE)( FREE_IMAGE_FORMAT fif, FIBITMAP* dib, char *filename, int flags );
typedef FIBITMAP* ( WINAPI *FREEIMAGE_ALLOCATE)( int width, int height, int bpp, unsigned red_mask, unsigned green_mask, unsigned blue_mask );
#else
typedef FIBITMAP* ( WINAPI *FREEIMAGE_ALLOCATE)( int width, int height, int bpp, unsigned red_mask FI_DEFAULT(0), unsigned green_mask FI_DEFAULT(0), unsigned blue_mask FI_DEFAULT(0) );
typedef BOOL ( WINAPI *FREEIMAGE_SAVE)( FREE_IMAGE_FORMAT fif, FIBITMAP* dib, char *filename, int flags FI_DEFAULT(0) );
#endif
typedef FREE_IMAGE_FORMAT ( WINAPI *FREEIMAGE_GETFIFFROMFILENAME)( char *filename);
typedef ULONG ( WINAPI *FREEIMAGE_GETWIDTH )( FIBITMAP *dib );
typedef ULONG ( WINAPI *FREEIMAGE_GETHEIGHT )( FIBITMAP *dib );
typedef BYTE * ( WINAPI *FREEIMAGE_GETBITS )( FIBITMAP *dib );
typedef BITMAPINFO * ( WINAPI *FREEIMAGE_GETINFO )( FIBITMAP *dib );
typedef BITMAPINFOHEADER * ( WINAPI *FREEIMAGE_GETINFOHEADER )( FIBITMAP *dib );
typedef FIBITMAP* ( WINAPI *FREEIMAGE_CONVERTFROMRAWBITS)(BYTE *bits, int width, int height, int pitch, unsigned bpp, unsigned red_mask, unsigned green_mask, unsigned blue_mask, BOOL topdown FI_DEFAULT(FALSE));
typedef FIBITMAP* ( WINAPI *FREEIMAGE_RESCALE )(FIBITMAP *dib, int dst_width, int dst_height, FREE_IMAGE_FILTER filter);
typedef RGBQUAD* ( WINAPI *FREEIMAGE_GETPALETTE ) (FIBITMAP *dib);
typedef ULONG ( WINAPI *FREEIMAGE_GETBPP ) (FIBITMAP *dib);
typedef BOOL ( WINAPI *FREEIMAGE_SETCHANNEL ) (FIBITMAP *dib, FIBITMAP *dib8, FREE_IMAGE_COLOR_CHANNEL channel);
typedef BYTE * ( WINAPI *FREEIMAGE_GETSCANLINE ) (FIBITMAP *dib, int scanline);
typedef void ( WINAPI *FREEIMAGE_CONVERTTORAWBITS )(BYTE *bits, FIBITMAP *dib, int pitch, unsigned bpp, unsigned red_mask, unsigned green_mask, unsigned blue_mask, BOOL topdown FI_DEFAULT(FALSE));
typedef unsigned ( WINAPI *FREEIMAGE_GETPITCH )(FIBITMAP *dib);
typedef short ( WINAPI *FREEIMAGE_GETIMAGETYPE )(FIBITMAP *dib);
typedef unsigned ( WINAPI *FREEIMAGE_GETCOLORSUSED )(FIBITMAP *dib);

static HINSTANCE hFreeImageDll = NULL;
static FREEIMAGE_LOAD pLoad = NULL;
static FREEIMAGE_UNLOAD pUnload = NULL;
static FREEIMAGE_ALLOCATE pAllocate = NULL;
static FREEIMAGE_SAVE pSave = NULL;
static FREEIMAGE_GETFIFFROMFILENAME pGetfiffromfile = NULL;
static FREEIMAGE_GETWIDTH pGetwidth = NULL;
static FREEIMAGE_GETHEIGHT pGetheight = NULL;
static FREEIMAGE_GETBITS pGetbits = NULL;
static FREEIMAGE_GETINFO pGetinfo = NULL;
static FREEIMAGE_GETINFOHEADER pGetinfoHead = NULL;
static FREEIMAGE_CONVERTFROMRAWBITS pConvertFromRawBits = NULL;
static FREEIMAGE_RESCALE pRescale = NULL;
static FREEIMAGE_GETPALETTE pGetPalette = NULL;
static FREEIMAGE_GETBPP pGetBPP = NULL;
static FREEIMAGE_SETCHANNEL pSetChannel = NULL;
static FREEIMAGE_GETSCANLINE pGetScanline = NULL;
static FREEIMAGE_CONVERTTORAWBITS pConvertToRawBits = NULL;
static FREEIMAGE_GETPITCH pGetPitch = NULL;
static FREEIMAGE_GETIMAGETYPE pGetImageType = NULL;
static FREEIMAGE_GETCOLORSUSED pGetColorsUsed = NULL;


BOOL FreeImgInit( void )
{
   if( !hFreeImageDll )
   {
      hFreeImageDll = LoadLibrary( (LPCTSTR)"FreeImage.dll" );
      if( !hFreeImageDll )
      {
         MessageBox( GetActiveWindow(), "Library not loaded", "FreeImage.dll", MB_OK | MB_ICONSTOP );
         return 0;
      }
   }
   return 1;
}

FARPROC GetFunction( FARPROC h, LPCSTR funcname )
{
   if( !h )
   {
      if( !hFreeImageDll && !FreeImgInit() )
      {
         return (FARPROC)NULL;
      }
      else
         return GetProcAddress( hFreeImageDll, funcname );
   }
   else
      return h;
}

HB_FUNC( FI_INIT )
{
   hb_retl( FreeImgInit() );
}

HB_FUNC( FI_END )
{
   if( hFreeImageDll )
   {
      FreeLibrary( hFreeImageDll );
      hFreeImageDll = NULL;
      pLoad = NULL;
      pUnload = NULL;
      pAllocate = NULL;
      pSave = NULL;
      pGetfiffromfile = NULL;
      pGetwidth = NULL;
      pGetheight = NULL;
      pGetbits = NULL;
      pGetinfo = NULL;
      pGetinfoHead = NULL;
      pConvertFromRawBits = NULL;
		pRescale = NULL;
		pGetPalette = NULL;
		pGetBPP = NULL;
		pSetChannel = NULL;
		pGetScanline = NULL;
		pConvertToRawBits = NULL;
		pGetPitch = NULL;
		pGetImageType = NULL;
		pGetColorsUsed = NULL;
   }
}


HB_FUNC( FI_VERSION )
{
   FREEIMAGE_GETVERSION pFunc =
     (FREEIMAGE_GETVERSION) GetFunction( NULL,"_FreeImage_GetVersion@0" );

   hb_retc( (pFunc)? pFunc() : "" );
}

HB_FUNC( FI_UNLOAD )
{
   pUnload = (FREEIMAGE_UNLOAD) GetFunction( (FARPROC)pUnload,"_FreeImage_Unload@4" );

   if( pUnload )
      pUnload( (FIBITMAP*)hb_parnl(1) );
}

HB_FUNC( FI_LOAD )
{
   pLoad = (FREEIMAGE_LOAD) GetFunction( (FARPROC)pLoad,"_FreeImage_Load@12" );
   pGetfiffromfile = (FREEIMAGE_GETFIFFROMFILENAME) GetFunction( (FARPROC)pGetfiffromfile,"_FreeImage_GetFIFFromFilename@4" );

   if( pGetfiffromfile && pLoad )
   {
      char *name = hb_parc( 1 );
      hb_retnl( (ULONG) pLoad( pGetfiffromfile(name), name, (hb_pcount()>1)? hb_parni(2) : 0 ) );
   }
   else
      hb_retnl( 0 );
}

HB_FUNC( FI_SAVE )
{
   pSave = (FREEIMAGE_SAVE) GetFunction( (FARPROC)pSave,"_FreeImage_Save@16" );
   pGetfiffromfile = (FREEIMAGE_GETFIFFROMFILENAME) GetFunction( (FARPROC)pGetfiffromfile,"_FreeImage_GetFIFFromFilename@4" );

   if( pGetfiffromfile && pSave )
   {
      char *name = hb_parc( 2 );
      hb_retl( (BOOL) pSave( pGetfiffromfile(name), (FIBITMAP*)hb_parnl(1), name, (hb_pcount()>2)? hb_parni(3) : 0 ) );
   }
   else
      hb_retnl( 0 );
}

HB_FUNC( FI_GETWIDTH )
{
   pGetwidth = (FREEIMAGE_GETWIDTH) GetFunction( (FARPROC)pGetwidth,"_FreeImage_GetWidth@4" );

   hb_retnl( ( pGetwidth )? pGetwidth( (FIBITMAP*)hb_parnl(1) ) : 0 );
}

HB_FUNC( FI_GETHEIGHT )
{
   pGetheight = (FREEIMAGE_GETHEIGHT) GetFunction( (FARPROC)pGetheight,"_FreeImage_GetHeight@4" );

   hb_retnl( ( pGetheight )? pGetheight( (FIBITMAP*)hb_parnl(1) ) : 0 );
}


HB_FUNC( FI_GETBPP )
{
   pGetBPP = (FREEIMAGE_GETBPP) GetFunction( (FARPROC)pGetBPP,"_FreeImage_GetBPP@4" );

   hb_retnl( ( pGetBPP )? pGetBPP( (FIBITMAP*)hb_parnl(1) ) : 0 );
}



HB_FUNC( FI_GETIMAGETYPE )
{
   pGetImageType = (FREEIMAGE_GETIMAGETYPE) GetFunction( (FARPROC)pGetImageType,"_FreeImage_GetImageType@4" );

   hb_retnl( ( pGetImageType )? pGetImageType( (FIBITMAP*)hb_parnl(1) ) : 0 );
}



HB_FUNC( FI_2BITMAP )
{
   FIBITMAP* dib = (FIBITMAP*) hb_parnl( 1 );
   HDC hDC = GetDC( 0 );

   pGetbits = (FREEIMAGE_GETBITS) GetFunction( (FARPROC)pGetbits,"_FreeImage_GetBits@4" );
   pGetinfo = (FREEIMAGE_GETINFO) GetFunction( (FARPROC)pGetinfo,"_FreeImage_GetInfo@4" );
   pGetinfoHead = (FREEIMAGE_GETINFOHEADER) GetFunction( (FARPROC)pGetinfoHead,"_FreeImage_GetInfoHeader@4" );

   hb_retnl( (LONG) CreateDIBitmap( hDC, pGetinfoHead( dib ),
      CBM_INIT, pGetbits( dib ), pGetinfo( dib ), DIB_RGB_COLORS) );

   ReleaseDC( 0,hDC );
}


/* 24/02/2005 - <maurilio.longo@libero.it>
	from internet, possibly code from win32 sdk
*/
static HANDLE CreateDIB(DWORD dwWidth, DWORD dwHeight, WORD wBitCount)
{
    BITMAPINFOHEADER    bi;             // bitmap header
    LPBITMAPINFOHEADER  lpbi;           // pointer to BITMAPINFOHEADER
    DWORD               dwLen;          // size of memory block
    HANDLE              hDIB;
    DWORD               dwBytesPerLine; // Number of bytes per scanline


    // Make sure bits per pixel is valid
    if (wBitCount <= 1)
        wBitCount = 1;
    else if (wBitCount <= 4)
        wBitCount = 4;
    else if (wBitCount <= 8)
        wBitCount = 8;
    else if (wBitCount <= 24)
        wBitCount = 24;
    else
        wBitCount = 4;  // set default value to 4 if parameter is bogus

    // initialize BITMAPINFOHEADER
    bi.biSize = sizeof(BITMAPINFOHEADER);
    bi.biWidth = dwWidth;         // fill in width from parameter
    bi.biHeight = dwHeight;       // fill in height from parameter
    bi.biPlanes = 1;              // must be 1
    bi.biBitCount = wBitCount;    // from parameter
    bi.biCompression = BI_RGB;
    bi.biSizeImage = 0;           // 0's here mean "default"
    bi.biXPelsPerMeter = 0;
    bi.biYPelsPerMeter = 0;
    bi.biClrUsed = 0;
    bi.biClrImportant = 0;

    // calculate size of memory block required to store the DIB.  This
    // block should be big enough to hold the BITMAPINFOHEADER, the color
    // table, and the bits
    dwBytesPerLine = (((wBitCount * dwWidth) + 31) / 32 * 4);

    /*  only 24 bit DIBs supported */
    dwLen = bi.biSize + 0 /* PaletteSize((LPSTR)&bi) */ + (dwBytesPerLine * dwHeight);

    /* 24/02/2005 - <maurilio.longo@libero.it>
    	 needed to copy bits afterward */
    bi.biSizeImage = dwBytesPerLine * dwHeight;

    // alloc memory block to store our bitmap
    hDIB = GlobalAlloc(GHND, dwLen);

    // major bummer if we couldn't get memory block
    if (!hDIB)
        return NULL;

    // lock memory and get pointer to it
    lpbi = (LPBITMAPINFOHEADER)GlobalLock(hDIB);

    // use our bitmap info structure to fill in first part of
    // our DIB with the BITMAPINFOHEADER
    *lpbi = bi;

    // Since we don't know what the colortable and bits should contain,
    // just leave these blank.  Unlock the DIB and return the HDIB.
    GlobalUnlock(hDIB);

    //return handle to the DIB
    return hDIB;
}


#define FI_RGBA_RED_MASK		0x00FF0000
#define FI_RGBA_GREEN_MASK		0x0000FF00
#define FI_RGBA_BLUE_MASK		0x000000FF

/* 24/02/2005 - <maurilio.longo@libero.it>
  	Converts a FIBITMAP into a DIB, woerks OK only for 24bpp images, though
*/
HB_FUNC( FI_2DIB )
{
   FIBITMAP* dib = (FIBITMAP*) hb_parnl( 1 );
   HANDLE hdib = NULL;
   LPBITMAPINFO  lpbi = NULL;

   pGetwidth = (FREEIMAGE_GETWIDTH) GetFunction( (FARPROC)pGetwidth,"_FreeImage_GetWidth@4" );
   pGetheight = (FREEIMAGE_GETHEIGHT) GetFunction( (FARPROC)pGetheight,"_FreeImage_GetHeight@4" );
	pGetBPP = (FREEIMAGE_GETBPP) GetFunction( (FARPROC)pGetBPP, "_FreeImage_GetBPP@4" );
	pGetPitch = (FREEIMAGE_GETPITCH) GetFunction( (FARPROC)pGetBPP, "_FreeImage_GetPitch@4" );
	pGetbits = (FREEIMAGE_GETBITS) GetFunction( (FARPROC)pGetbits,"_FreeImage_GetBits@4" );

	hdib = CreateDIB( pGetwidth( dib ), pGetheight( dib ),  pGetBPP( dib ) );

	if ( hdib ) {

		int scan_width = pGetPitch( dib );

		lpbi = (LPBITMAPINFO) GlobalLock( hdib );

		memcpy( (LPBYTE)( (BYTE*)lpbi ) + lpbi->bmiHeader.biSize, pGetbits( dib ), lpbi->bmiHeader.biSizeImage );

		GlobalUnlock( hdib );

		hb_retnl( hdib );

	} else {
		hb_retnl( 0 );
   }
}


/* 24/02/2005 - <maurilio.longo@libero.it>
	This comes straight from freeimage fipWinImage::copyToHandle()
	but doesn't work, maybe some casting issue.

HB_FUNC( FI_2DIBEX )
{
	FIBITMAP* _dib = (FIBITMAP*) hb_parnl( 1 );
   HANDLE hMem = NULL;

   pGetColorsUsed = (FREEIMAGE_GETCOLORSUSED) GetFunction( (FARPROC)pGetColorsUsed,"_FreeImage_GetColorsUsed@4" );
   pGetwidth = (FREEIMAGE_GETWIDTH) GetFunction( (FARPROC)pGetwidth,"_FreeImage_GetWidth@4" );
   pGetheight = (FREEIMAGE_GETHEIGHT) GetFunction( (FARPROC)pGetheight,"_FreeImage_GetHeight@4" );
	pGetBPP = (FREEIMAGE_GETBPP) GetFunction( (FARPROC)pGetBPP, "_FreeImage_GetBPP@4" );
	pGetPitch = (FREEIMAGE_GETPITCH) GetFunction( (FARPROC)pGetBPP, "_FreeImage_GetPitch@4" );
	pGetinfoHead = (FREEIMAGE_GETINFOHEADER) GetFunction( (FARPROC)pGetinfoHead,"_FreeImage_GetInfoHeader@4" );
	pGetinfo = (FREEIMAGE_GETINFO) GetFunction( (FARPROC)pGetinfo,"_FreeImage_GetInfo@4" );
	pGetbits = (FREEIMAGE_GETBITS) GetFunction( (FARPROC)pGetbits,"_FreeImage_GetBits@4" );
	pGetPalette = (FREEIMAGE_GETPALETTE) GetFunction( (FARPROC)pGetPalette, "_FreeImage_GetPalette@4" );

	if( _dib ) {

		// Get equivalent DIB size
		long dib_size = sizeof(BITMAPINFOHEADER);
		dib_size += pGetColorsUsed( _dib ) * sizeof(RGBQUAD);
		dib_size += pGetPitch( _dib ) * pGetheight( _dib );

		// Allocate a DIB
		hMem = GlobalAlloc(GHND, dib_size);
		BYTE *dib = (BYTE*)GlobalLock(hMem);

		memset(dib, 0, dib_size);

		BYTE *p_dib = (BYTE*)dib;

		// Copy the BITMAPINFOHEADER
		BITMAPINFOHEADER *bih = pGetinfoHead( _dib );
		memcpy(p_dib, bih, sizeof(BITMAPINFOHEADER));
		p_dib += sizeof(BITMAPINFOHEADER);

		// Copy the palette
		RGBQUAD *pal = pGetPalette(_dib);
		memcpy(p_dib, pal, pGetColorsUsed(_dib) * sizeof(RGBQUAD));
		p_dib += pGetColorsUsed(_dib) * sizeof(RGBQUAD);


		// Copy the bitmap
		BYTE *bits = pGetbits(_dib);
		memcpy(p_dib, bits, pGetPitch(_dib) * pGetheight(_dib));

		GlobalUnlock(hMem);
	}

	hb_retnl( hMem );
}
*/


HB_FUNC( FI_DRAW )
{
   FIBITMAP* dib = (FIBITMAP*) hb_parnl( 1 );
   HDC hDC = (HDC) hb_parnl( 2 );
   int nWidth = (int) hb_parnl( 3 ), nHeight = (int) hb_parnl( 4 );
   int nDestWidth, nDestHeight;
   POINT pp[2];
   // char cres[40];
   // BOOL l;

   if( hb_pcount() > 6 && !ISNIL( 7 ) )
   {
      nDestWidth  = hb_parni( 7 );
      nDestHeight = hb_parni( 8 );
   }
   else
   {
      nDestWidth  = nWidth;
      nDestHeight = nHeight;
   }

   pp[0].x = hb_parni( 5 );
   pp[0].y = hb_parni( 6 );
   pp[1].x = pp[0].x + nDestWidth;
   pp[1].y = pp[0].y + nDestHeight;
   // sprintf( cres,"\n %d %d %d %d",pp[0].x,pp[0].y,pp[1].x,pp[1].y );
   // writelog(cres);
   // l = DPtoLP( hDC, pp, 2 );
   // sprintf( cres,"\n %d %d %d %d %d",pp[0].x,pp[0].y,pp[1].x,pp[1].y,l );
   // writelog(cres);

   pGetbits = (FREEIMAGE_GETBITS) GetFunction( (FARPROC)pGetbits,"_FreeImage_GetBits@4" );
   pGetinfo = (FREEIMAGE_GETINFO) GetFunction( (FARPROC)pGetinfo,"_FreeImage_GetInfo@4" );

   if( pGetbits && pGetinfo )
   {
      SetStretchBltMode( hDC, COLORONCOLOR );
      StretchDIBits( hDC, pp[0].x, pp[0].y, pp[1].x-pp[0].x, pp[1].y-pp[0].y,
         0, 0, nWidth, nHeight,
         pGetbits( dib ), pGetinfo( dib ), DIB_RGB_COLORS, SRCCOPY );
   }
}

HB_FUNC( FI_BMP2FI )
{
   HBITMAP hbmp = (HBITMAP) hb_parnl(1);

   if( hbmp )
   {
      FIBITMAP *dib;
      BITMAP bm;

      pAllocate = (FREEIMAGE_ALLOCATE) GetFunction( (FARPROC)pAllocate,"_FreeImage_Allocate@24" );
      pGetbits = (FREEIMAGE_GETBITS) GetFunction( (FARPROC)pGetbits,"_FreeImage_GetBits@4" );
      pGetinfo = (FREEIMAGE_GETINFO) GetFunction( (FARPROC)pGetinfo,"_FreeImage_GetInfo@4" );
      pGetheight = (FREEIMAGE_GETHEIGHT) GetFunction( (FARPROC)pGetheight,"_FreeImage_GetHeight@4" );

      if( pAllocate && pGetbits && pGetinfo && pGetheight )
      {
         HDC hDC = GetDC( NULL );

         GetObject( hbmp, sizeof(BITMAP), (LPSTR) &bm );
         dib = pAllocate( bm.bmWidth, bm.bmHeight, bm.bmBitsPixel, 0, 0, 0 );
         GetDIBits( hDC, hbmp, 0, pGetheight( dib ),
            pGetbits( dib ), pGetinfo( dib ), DIB_RGB_COLORS );
         ReleaseDC( NULL, hDC );
         hb_retnl( (LONG) dib );
         return;
      }
   }
   hb_retnl( 0 );
}



/* Next three from EZTwain.c ( http://www.twain.org ) */
static int ColorCount(int bpp)
{
   return 0xFFF & (1 << bpp);
}


static int BmiColorCount(LPBITMAPINFOHEADER lpbi)
{
   if (lpbi->biSize == sizeof(BITMAPCOREHEADER)) {
      LPBITMAPCOREHEADER    lpbc = ((LPBITMAPCOREHEADER)lpbi);
      return 1 << lpbc->bcBitCount;
   } else if (lpbi->biClrUsed == 0) {
      return ColorCount(lpbi->biBitCount);
   } else {
      return (int)lpbi->biClrUsed;
   }
} // BmiColorCount



static int DibNumColors(VOID FAR *pv)
{
   return BmiColorCount((LPBITMAPINFOHEADER)pv);
} // DibNumColors



static LPBYTE DibBits(LPBITMAPINFOHEADER lpdib)
// Given a pointer to a locked DIB, return a pointer to the actual bits (pixels)
{
    DWORD dwColorTableSize = (DWORD)(DibNumColors(lpdib) * sizeof(RGBQUAD));
    LPBYTE lpBits = (LPBYTE)lpdib + lpdib->biSize + dwColorTableSize;

    return lpBits;
} // end DibBits



/* 19/05/2005 - <maurilio.longo@libero.it>
	Convert a windows DIB into a FIBITMAP
*/
HB_FUNC( FI_DIB2FI )
{
   HANDLE hdib = (HANDLE) hb_parnl( 1 );

   if( hdib )
   {
      FIBITMAP *dib;
      LPBITMAPINFOHEADER lpbi = GlobalLock( hdib );

      pConvertFromRawBits = (FREEIMAGE_CONVERTFROMRAWBITS) GetFunction( (FARPROC)pConvertFromRawBits, "_FreeImage_ConvertFromRawBits@36" );
      pGetPalette = (FREEIMAGE_GETPALETTE) GetFunction( (FARPROC)pGetPalette, "_FreeImage_GetPalette@4" );
      pGetBPP = (FREEIMAGE_GETBPP) GetFunction( (FARPROC)pGetBPP, "_FreeImage_GetBPP@4" );


      if( pConvertFromRawBits && lpbi )
      {
         //int pitch = (((( lpbi->biWidth * lpbi->biBitCount) + 31) &~31) >> 3);
         int pitch = ((((lpbi->biBitCount * lpbi->biWidth) + 31) / 32) * 4);

         dib = pConvertFromRawBits( DibBits(lpbi),
                                    lpbi->biWidth,
                                    lpbi->biHeight,
                                    pitch,
                                    lpbi->biBitCount,
                                    FI_RGBA_RED_MASK,
                                    FI_RGBA_GREEN_MASK,
                                    FI_RGBA_BLUE_MASK,
                                    hb_parl( 2 ) );


      	/* I can't print it with FI_DRAW, though, and I don't know why */
      	if( pGetBPP(dib) <= 8) {

      		// Convert palette entries
      		RGBQUAD *pal = pGetPalette(dib);
      		RGBQUAD *dibpal = (RGBQUAD *) (((LPBYTE)lpbi) + lpbi->biSize);

      		for (int i = 0; i < BmiColorCount( lpbi ); i++)	{
      			pal[i].rgbRed = dibpal[i].rgbRed;
      			pal[i].rgbGreen = dibpal[i].rgbGreen;
      			pal[i].rgbBlue = dibpal[i].rgbBlue;
      			pal[i].rgbReserved = 0;
      		}
      	}

			GlobalUnlock( hdib );
         hb_retnl( (LONG) dib );
         return;

      } else {
      	GlobalUnlock( hdib );
      }

   }
   hb_retnl( 0 );
}



HB_FUNC( FI_RESCALE )
{
   pRescale = (FREEIMAGE_RESCALE) GetFunction( (FARPROC)pRescale,"_FreeImage_Rescale@16" );

   hb_retnl( ( pRescale )? pRescale( (FIBITMAP*)hb_parnl(1), hb_parnl( 2 ), hb_parnl( 3 ), hb_parni( 4 ) ) : 0 );
}


/* Channel is an enumerated type from freeimage.h passed as second parameter */
HB_FUNC( FI_REMOVECHANNEL )
{
 	FIBITMAP * dib = (FIBITMAP*) hb_parnl( 1 );
 	FIBITMAP * dib8 = NULL;

	pAllocate = (FREEIMAGE_ALLOCATE) GetFunction( (FARPROC)pAllocate,"_FreeImage_Allocate@24" );
	pGetwidth = (FREEIMAGE_GETWIDTH) GetFunction( (FARPROC)pGetwidth,"_FreeImage_GetWidth@4" );
	pGetheight = (FREEIMAGE_GETHEIGHT) GetFunction( (FARPROC)pGetheight,"_FreeImage_GetHeight@4" );
	pSetChannel = (FREEIMAGE_SETCHANNEL) GetFunction( (FARPROC)pSetChannel,"_FreeImage_SetChannel@12" );
	pUnload = (FREEIMAGE_UNLOAD) GetFunction( (FARPROC)pUnload,"_FreeImage_Unload@4" );

	dib8 = pAllocate( pGetwidth( dib ), pGetheight( dib), 8, 0, 0, 0 );

	if ( dib8 ) {
		hb_retl( pSetChannel( dib, dib8, hb_parni( 2 ) ) );
		pUnload( dib8 );

	} else {
		hb_retl( FALSE );
	}
}


