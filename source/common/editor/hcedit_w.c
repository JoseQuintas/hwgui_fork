/*
 * $Id$
 */

/*
 * HWGUI - Harbour Win32 GUI library source code:
 * The Edit control - C level
 *
 * Copyright 2013 Alexander Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version, with one exception:
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#define _WIN32_WINNT 0x400
#include <windows.h>
#include <tchar.h>

#include "hwingui.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapifs.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbapicdp.h"
#include "guilib.h"

extern void hwg_regboard( void );
LRESULT CALLBACK WinCtrlProc( HWND, UINT, WPARAM, LPARAM );

typedef struct
{
   COLORREF fg;                 // foreground colour
   COLORREF bg;                 // background colour
   int iFont;                  // possible font-styling information

} TEDATTR;

typedef struct
{
   // Windows font information
   HFONT hFont;
   TEXTMETRIC tm;

   int iWidth;

} TEDFONT;

typedef struct
{
   int  x1;
   int  x2;
   int  y1;
   int  y2;
} TEDBLOCK;

typedef struct
{
   HWND          handle;
   TEDFONT *  pFontsScr;
   TEDFONT *  pFontsPrn;
   int           iFonts;
   int       iFontsCurr;
   TEDATTR *      pattr;
   int         iAttrLen;
   int     *     pattrf;
   HDC           hDCScr;
   HDC           hDCPrn;
   double        dKoeff;
   int           iWidth;
   int        iDocWidth;
   short int      bWrap;
   COLORREF          fg;
   COLORREF          bg;
   COLORREF     fg_curr;
   COLORREF     bg_curr;
   int               x1;
   int               x2;
   int             ypos;
   int       ixCaretPos;
   int       iyCaretPos;
   int     iCaretHeight;
   int        iCaretSet;
   int          nBorder;
   COLORREF  lBorderClr;
} TEDIT;

#define  NUMBER_OF_FONTS  32
#define  TEDATTR_MAX    1024
#define  TEDATTRF_MAX     32

char * szDelimiters = " .,-";

/*
int hced_utf8bytes( char * szText, int iLen )
{
  HB_SIZE nLen, ul;
  int n;
  HB_WCHAR wc;

  for( ul = 0; ul < nLen && iLen; )
  {
     if( hb_cdpUTF8ToU16NextChar( szText[ ul ], &n, &wc ) )
        ++ul;
     if( n == 0 )
        --iLen;
  }
  return (int) ul;
}
*/

TEDFONT * ted_setfont( TEDIT * pted, HFONT hFont, int iNum, short int bPrn  )
{
   TEDFONT * pFont;
   HDC hDC;
   HANDLE hold;
   SIZE sz;

   if( iNum < 0 ) {
      iNum = pted->iFontsCurr;
      pted->iFontsCurr++;
   }
   if( iNum >= pted->iFonts )
   {
      pted->iFonts += NUMBER_OF_FONTS;
      pted->pFontsScr = ( TEDFONT * ) hb_xrealloc( pted->pFontsScr, sizeof( TEDFONT ) * pted->iFonts );
      pted->pFontsPrn = ( TEDFONT * ) hb_xrealloc( pted->pFontsPrn, sizeof( TEDFONT ) * pted->iFonts );
   }

   pFont = ( (bPrn)? pted->pFontsPrn : pted->pFontsScr ) + iNum;

   hDC = GetDC( 0 );
   hold = SelectObject( hDC, hFont );
   GetTextMetrics( hDC, &(pFont->tm) );
   GetTextExtentPoint32( hDC, TEXT("aA"), 2, &sz );
   pFont->iWidth = sz.cx / 2;

   SelectObject( hDC, hold );
   ReleaseDC( 0, hDC );

   pFont->hFont = hFont;

   return pFont;
}

/*
 * ted_CalcItemWidth() returns the text width in pixels,
 * writes to the 4 parameter (iRealLen) the width in chars
 */

#ifdef UNICODE
int ted_CalcItemWidth( TEDIT * pted, LPCTSTR szText, TEDATTR * pattr, int *iRealLen,
      int iWidth, short int bWrap, short int bLastInFew )
#else
int ted_CalcItemWidth( TEDIT * pted, char *szText, TEDATTR * pattr, int *iRealLen,
      int iWidth, short int bWrap, short int bLastInFew )
#endif
{
   int i, i1, iReal, xpos;
   SIZE sz;
   TEDFONT *font = pted->pFontsScr + pattr->iFont;

   SelectObject( pted->hDCScr, font->hFont );

   iReal = iWidth / font->iWidth;
   if( iReal > *iRealLen )
      iReal = *iRealLen;
   GetTextExtentPoint32( pted->hDCScr, szText, iReal, &sz );
   //hwg_writelog( NULL, "bLastInFew: %d iReal: %d iRealLen: %d iWidth: %d sz.cx %d\r\n",bLastInFew,iReal,*iRealLen,iWidth,sz.cx );
   if( sz.cx > iWidth )
   {
      for( i = iReal - 1; i > 0; i-- )
      {
         if( bWrap )
         {
            i1 = i;
            while( i > 0 && !strchr( szDelimiters,*(szText+i) ) ) i --;
            if( !i && !bLastInFew )
            //if( !i )
            {
               i = i1;
               break;
            }
         }
         GetTextExtentPoint32( pted->hDCScr, szText, i, &sz );
         if( sz.cx <= iWidth )
            break;
      }
      xpos = sz.cx;
      *iRealLen = i;
      //hwg_writelog( NULL, "> iRealLen: %d sz.cx %d\r\n",*iRealLen,sz.cx );
   }
   else
   {
      xpos = sz.cx;
      i1 = iReal;

      if( bWrap && iReal < *iRealLen )
      {
         i = i1;
         while( i && !strchr( szDelimiters,*(szText+i) ) &&
               !strchr( szDelimiters,*(szText+i-1) ) ) i --;
         if( i || bLastInFew )
         //if( i )
            i1 = i;
      }
      for( i = iReal + 1; i <= *iRealLen; i++ )
      {
         if( bWrap )
         {
            while( i < *iRealLen && !strchr( szDelimiters,*(szText+i) ) ) i ++;
         }
         GetTextExtentPoint32( pted->hDCScr, szText, i, &sz );
         if( sz.cx > iWidth )
            break;

         xpos = sz.cx;
         i1 = i;
      }
      *iRealLen = i1;
      //hwg_writelog( NULL, ">> iRealLen: %d sz.cx %d\r\n",*iRealLen,sz.cx );
   }

   return xpos;
}

#ifdef UNICODE
int ted_CalcLineWidth( TEDIT * pted, LPCTSTR szText, int iLen, int iWidth, int * iRealWidth, short int bWrap )
#else
int ted_CalcLineWidth( TEDIT * pted, char *szText, int iLen, int iWidth, int * iRealWidth, short int bWrap )
#endif
{
   TEDATTR *pattr = pted->pattr;
   int i, lasti, iRealLen, iPrinted = 0;

   *iRealWidth = 0;
   for( i = 0, lasti = 0; i <= iLen; i++ )
   {
      // if the color or font changes, then need to output
      if( i == iLen || ( pattr + i )->iFont != ( pattr + lasti )->iFont )
      {
         iRealLen = i - lasti;
         //hwg_writelog( NULL, "Lineout-1a %d %d %d \r\n", iRealLen, i, lasti );
         *iRealWidth += ted_CalcItemWidth( pted, szText + lasti, pattr + lasti, &iRealLen,
               iWidth - *iRealWidth, bWrap, (short int)lasti );
         iPrinted += iRealLen;
         if( iRealLen < i - lasti )
            break;
         lasti = i;
      }
   }
   //hwg_writelog( NULL, "Lineout-2 %d\r\n", iPrinted );
   return iPrinted;
}

#ifdef UNICODE
int ted_TextOut( TEDIT * pted, int xpos, int ypos, int iHeight,
      int iMaxAscent, LPCTSTR szText, TEDATTR * pattr, int iLen )
#else
int ted_TextOut( TEDIT * pted, int xpos, int ypos, int iHeight,
      int iMaxAscent, char *szText, TEDATTR * pattr, int iLen )
#endif
{
   RECT rect;
   SIZE sz;
   COLORREF fg, bg;
   HDC hDC = (pted->hDCPrn)? pted->hDCPrn : pted->hDCScr;
   TEDFONT *font = ( (pted->hDCPrn)? pted->pFontsPrn : pted->pFontsScr ) + pattr->iFont;

   SelectObject( hDC, font->hFont );

   fg = ( pattr->fg == pattr->bg )? pted->fg : pattr->fg;
   bg = ( pattr->fg == pattr->bg )? pted->bg : pattr->bg;
   if( fg != pted->fg_curr )
   {
      SetTextColor( hDC, fg );
      pted->fg_curr = fg;
   }
   if( bg != pted->bg_curr )
   {
      SetBkColor( hDC, bg );
      pted->bg_curr = bg;
   }

   // get size of text
   GetTextExtentPoint32( hDC, szText, iLen, &sz );

   SetRect( &rect, xpos, ypos, xpos + sz.cx, ypos + iHeight );

   // draw the text and erase it's background at the same time
   ExtTextOut( hDC, xpos, ypos + (iMaxAscent - font->tm.tmAscent), ETO_OPAQUE, &rect, szText, iLen, 0 );
   //DrawText( hDC, szText, iLen, &rect, 0 );
   //hwg_writelog( NULL, "len: %d text: %c%c%c \r\n", iLen, *( (char*)szText ), *( ((char*)szText) + 1), *( ((char*)szText) + 2) );

   return sz.cx;
}

#ifdef UNICODE
int ted_LineOut( TEDIT * pted, int x1, int ypos, LPCTSTR szText, int iPrinted, int iHeight, int iMaxAscent, int iRight )
#else
int ted_LineOut( TEDIT * pted, int x1, int ypos, char *szText, int iPrinted, int iHeight, int iMaxAscent, int iRight )
#endif
{
   TEDATTR *pattr = pted->pattr;
   int i, lasti, iRealLen;

   if( pted->hDCPrn )
      x1 = (int) ( x1 * pted->dKoeff );

   if( iPrinted )
      for( i = 0, lasti = 0; i <= iPrinted; i++ )
      {
         // if the color or font changes, then need to output
         if( i == iPrinted ||
               ( pattr + i )->fg != ( pattr + lasti )->fg ||
               ( pattr + i )->bg != ( pattr + lasti )->bg ||
               ( pattr + i )->iFont != ( pattr + lasti )->iFont )
         {
            if( i < iPrinted )
               iRealLen = i - lasti;
            else
               iRealLen = iPrinted - lasti;
            x1 += ted_TextOut( pted, x1, ypos, iHeight, iMaxAscent,
                     szText + lasti, pattr + lasti, iRealLen );
            if( iRealLen != ( i - lasti ) )
               break;
            lasti = i;
         }
      }

   if( !pted->hDCPrn )
   {
      RECT rect;
      //SetRect( &rect, x1, ypos, (pted->iDocWidth)? pted->iDocWidth : pted->iWidth, ypos + iHeight );
      SetRect( &rect, x1, ypos, iRight, ypos + iHeight );
      if( pted->bg != pted->bg_curr )
      {
         SetBkColor( pted->hDCScr, pted->bg );
         pted->bg_curr = pted->bg;
      }
      ExtTextOut( pted->hDCScr, 0, 0, ETO_OPAQUE, &rect, 0, 0, 0 );
   }

   return x1;
}

void ted_ClearAttr( TEDIT *pted )
{
   memset( pted->pattr, 0, sizeof( TEDATTR ) * pted->iAttrLen );
   memset( pted->pattrf, 0, sizeof( int ) * TEDATTRF_MAX );
}

TEDIT * ted_init( void )
{
   TEDIT *pted = ( TEDIT * ) hb_xgrab( sizeof( TEDIT ) );

   hwg_regboard();

   memset( pted, 0, sizeof( TEDIT ) );

   pted->iFonts = NUMBER_OF_FONTS;
   pted->pFontsScr =
         ( TEDFONT * ) hb_xgrab( sizeof( TEDFONT ) * NUMBER_OF_FONTS );
   pted->pFontsPrn =
         ( TEDFONT * ) hb_xgrab( sizeof( TEDFONT ) * NUMBER_OF_FONTS );

   pted->iAttrLen = TEDATTR_MAX;
   pted->pattr = ( TEDATTR * ) hb_xgrab( sizeof( TEDATTR ) * TEDATTR_MAX );
   pted->pattrf = ( int * ) hb_xgrab( sizeof( int ) * TEDATTRF_MAX );
   ted_ClearAttr( pted );

   return pted;
}

HWND ted_create( HWND hwndParent, int id, DWORD dwStyle, int x, int y,
                 int iWidth, int iHeight )
{
      #if defined( HB_WIN_UNICODE ) || defined( UNICODE )
      return CreateWindowEx(
            ( dwStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0,
                            L"HBOARD", L"", dwStyle,
                            x, y, iWidth, iHeight, hwndParent, ( HMENU )(UINT_PTR) id,
                            GetModuleHandle( 0 ), 0 );
      #else
      return CreateWindowEx(
            ( dwStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0,
                            "HBOARD", "", dwStyle,
                            x, y, iWidth, iHeight, hwndParent, ( HMENU )(UINT_PTR) id,
                            GetModuleHandle( 0 ), 0 );
      #endif
}


HB_FUNC( HCED_INITTEXTEDIT )
{
   HB_RETHANDLE( ted_init() );
}

HB_FUNC( HCED_CREATETEXTEDIT )
{
   HB_RETHANDLE( ted_create( ( HWND ) HB_PARHANDLE( 1 ),
          hb_parni( 2 ), ( DWORD ) hb_parnl( 3 ), hb_parni( 4 ),
          hb_parni( 5 ), hb_parni( 6 ), hb_parni( 7 ) ) );
}

HB_FUNC( HCED_SETHANDLE )
{
   // HB_RETHANDLE( ( void * ) ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->handle );
   ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->handle = ( HWND ) HB_PARHANDLE( 2 );
}

HB_FUNC( HCED_RELEASE )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   hb_xfree( pted->pFontsScr );
   hb_xfree( pted->pFontsPrn );
   hb_xfree( pted->pattr );
   hb_xfree( pted->pattrf );
   hb_xfree( pted );
}

HB_FUNC( HCED_CLEARFONTS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   pted->iFontsCurr = 0;
}

HB_FUNC( HCED_ADDFONT )
{
   ted_setfont( ( TEDIT * ) HB_PARHANDLE( 1 ), ( HFONT ) HB_PARHANDLE( 2 ), -1, 0 );
}

HB_FUNC( HCED_SETFONT )
{
   int iFont = hb_parni(3);

   if( iFont > 0 ) iFont --;
   ted_setfont( ( TEDIT * ) HB_PARHANDLE( 1 ), ( HFONT ) HB_PARHANDLE( 2 ),
         iFont, (short int)((HB_ISNIL(4))? 0 : hb_parl(4)) );
}

HB_FUNC( HCED_SETCOLOR )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   if( HB_ISNUM(2) )
   {
      pted->fg = (COLORREF) hb_parnl(2);
      SetTextColor( pted->hDCScr, pted->fg );
      pted->fg_curr = pted->fg;
   }
   if( HB_ISNUM(3) )
   {
      pted->bg = (COLORREF) hb_parnl(3);
      SetBkColor( pted->hDCScr, pted->bg );
      pted->bg_curr = pted->bg;
   }
}

HB_FUNC( HCED_CLEARATTR )
{
   ted_ClearAttr( ( ( TEDIT * ) HB_PARHANDLE( 1 ) ) );
}

/*
 * hced_setAttr( ::hEdit, nPos, nLen, nFont, tColor, bColor )
 */
HB_FUNC( HCED_SETATTR )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   int iPos = hb_parni(2), i = hb_parni(3), iLen;
   int iFont = hb_parni(4)-1;
   COLORREF fg = (COLORREF) hb_parnl(5);
   COLORREF bg = (COLORREF) hb_parnl(6);
   TEDATTR * pattr;

   //hwg_writelog( NULL, "%lu %lu\r\n", hb_parni(2),i );

   if( iPos + i >= pted->iAttrLen )
   {
      iLen = pted->iAttrLen;
      pted->iAttrLen = iPos + i + 128;
      //hwg_writelog( NULL, "realloc %lu %lu\r\n", iLen,pted->iAttrLen );
      pted->pattr = ( TEDATTR * ) hb_xrealloc( pted->pattr,
            sizeof(TEDATTR) * pted->iAttrLen );
      memset( pted->pattr + iLen, 0, sizeof( TEDATTR ) * ( pted->iAttrLen-iLen ) );
      //hwg_writelog( NULL, "realloc - Ok\r\n" );
   }

   pattr = pted->pattr + iPos - 1;
   for( ; i; i--,pattr++ )
   {
      pattr->fg = fg;
      pattr->bg = bg;
      if( iFont >= 0 )
         pattr->iFont = iFont;
   }
   //hwg_writelog( NULL, "SetAttr - end\r\n" );
}

HB_FUNC( HCED_ADDATTRFONT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   int i = 0, iFont = hb_parni(2);

   while( i < TEDATTRF_MAX && *( pted->pattrf+i ) )
   {
      if( *( pted->pattrf+i ) == iFont )
         return;
      i ++;
   }
   *( pted->pattrf+i ) = iFont;
}

/*
 * hed_setvscroll( hTEdit, nPos, nPartsInPage, nPages )
 */
HB_FUNC( HCED_SETVSCROLL )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   SCROLLINFO si;
   int iPages = hb_parni(4);

   si.cbSize = sizeof( SCROLLINFO );
   si.fMask = SIF_PAGE | SIF_POS | SIF_RANGE | SIF_DISABLENOSCROLL;

   si.nPos  = hb_parni(2);
   si.nPage = hb_parni(3);
   si.nMin  = 0;
   si.nMax  = hb_parni(3) * ( (iPages)? iPages-1:iPages );

   SetScrollInfo( pted->handle, SB_VERT, &si, TRUE );
}

HB_FUNC( HCED_SETPAINT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   pted->hDCScr = (HB_ISNIL(2))? NULL : (HDC) HB_PARHANDLE( 2 );
   pted->hDCPrn = (HB_ISNIL(3))? NULL : (HDC) HB_PARHANDLE( 3 );

   if( !HB_ISNIL(4) )
      pted->iWidth = hb_parni( 4 );
   if( !HB_ISNIL(5) )
      pted->bWrap = (short int)hb_parl( 5 );
   if( !HB_ISNIL(7) )
      pted->iDocWidth = hb_parni( 7 );

   //SelectObject( pted->hDCScr, pted->pFontsScr->hFont );
   SetTextColor( pted->hDCScr, pted->fg );
   SetBkColor( pted->hDCScr, pted->bg );
   pted->fg_curr = pted->fg;
   pted->bg_curr = pted->bg;
   if( pted->hDCPrn && !HB_ISNIL(6) )
   {
      pted->dKoeff = ( GetDeviceCaps( pted->hDCPrn,HORZRES ) / hb_parnd(6) ) / GetDeviceCaps( pted->hDCPrn,HORZSIZE );
   }

}

HB_FUNC( HCED_SETWIDTH )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   if( !HB_ISNIL(2) )
      pted->iWidth = hb_parni( 2 );
   if( !HB_ISNIL(3) )
      pted->iDocWidth = hb_parl( 3 );
}

HB_FUNC( HCED_FILLRECT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   RECT rect;

   if( !pted->hDCPrn )
   {
      SetRect( &rect, (HB_ISNIL(2))? 0:hb_parni(2), hb_parni(3),
            (HB_ISNIL(4))? pted->iWidth:hb_parni(4), hb_parni(5) );
      if( pted->bg != pted->bg_curr )
      {
         SetBkColor( pted->hDCScr, pted->bg );
         pted->bg_curr = pted->bg;
      }
      ExtTextOut( pted->hDCScr, 0, 0, ETO_OPAQUE, &rect, 0, 0, 0 );
   }
}

HB_FUNC( HCED_SHOWCARET )
{
   ShowCaret( ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->handle );
}

HB_FUNC( HCED_HIDECARET )
{
   HideCaret( ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->handle );
}

HB_FUNC( HCED_INITCARET )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   if( !pted->iCaretSet )
      CreateCaret( pted->handle, (HBITMAP)NULL, 2, pted->pFontsScr->tm.tmHeight );
   pted->iCaretSet = 1;
   ShowCaret( pted->handle );
   SetCaretPos( 0,0 );
   pted->iCaretHeight = pted->pFontsScr->tm.tmHeight;
   InvalidateRect( pted->handle, NULL, 0 );
}

HB_FUNC( HCED_KILLCARET )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   HideCaret( pted->handle );
   DestroyCaret();
   pted->iCaretSet = 0;
   InvalidateRect( pted->handle, NULL, 0 );
}

HB_FUNC( HCED_GETXCARETPOS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   hb_retni( pted->ixCaretPos );
}

HB_FUNC( HCED_GETYCARETPOS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   hb_retni( pted->iyCaretPos );
}

HB_FUNC( HCED_GETCARETHEIGHT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   hb_retni( pted->iCaretHeight );
}

HB_FUNC( HCED_SETCARETPOS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   pted->ixCaretPos = hb_parni(2);
   pted->iyCaretPos = hb_parni(3);
   SetCaretPos( pted->ixCaretPos, pted->iyCaretPos );
}

/*
 * hced_ExactCaretPos( ::hEdit, cLine, x1, xPos, y1, bSet, nShiftL )
 */
HB_FUNC( HCED_EXACTCARETPOS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   TEDATTR *pattr = pted->pattr;
#ifdef UNICODE
   void *hText;
   HB_SIZE iLen;
   LPCTSTR szText = HB_PARSTR( 2, &hText, &iLen );
#else
   char * szText = ( char * ) hb_parc(2);
   int iLen = hb_parclen(2);
#endif
   int x1 = hb_parni(3), xpos = hb_parni(4), y1 = hb_parni(5);
   short int bSet = (short int)((HB_ISNIL(6))? 1 : hb_parl(6));
   int iShiftL = ( HB_ISNIL(7)? 0 : hb_parni(7) );
   int iPrinted = 0, iRealWidth;
   SIZE sz;

   if( iLen > 0 )
   {
      pted->hDCScr = GetDC( 0 );
      if( xpos < 0 )
         xpos = pted->iWidth + iShiftL + 1;
      if( xpos < x1 )
         xpos = x1;

      iPrinted = ted_CalcLineWidth( pted, szText, (int)iLen, xpos-x1, &iRealWidth, 0 );
      x1 += iRealWidth;

      if( xpos <= pted->iWidth + iShiftL )
         if( *(szText+iPrinted) )
         {
            GetTextExtentPoint32( pted->hDCScr, szText+iPrinted, 1, &sz );

            if( (x1 + sz.cx - xpos) < ( xpos - x1 ) )
            {
               x1 += sz.cx;
               iPrinted ++;
            }
         }
      ReleaseDC( 0, pted->hDCScr );
   }
#ifdef UNICODE
   hb_strfree( hText );
#endif
   iPrinted ++;
   if( bSet )
   {
      int iCaretHeight = ( pted->pFontsScr + (pattr+iPrinted-1)->iFont )->tm.tmHeight;
      if( iCaretHeight != pted->iCaretHeight )
      {
         HideCaret( pted->handle );
         DestroyCaret();
         pted->iCaretHeight = iCaretHeight;
         CreateCaret( pted->handle, (HBITMAP)NULL, 2, iCaretHeight );
         ShowCaret( pted->handle );
      }
      x1 -= iShiftL;
      SetCaretPos( x1, y1 );
      pted->ixCaretPos = x1;
      pted->iyCaretPos = y1;
   }

   hb_retni( iPrinted );

}

HB_FUNC( HCED_INVALIDATERECT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   RECT rc;

   if( hb_pcount(  ) > 2 )
   {
      rc.left = hb_parni( 3 );
      rc.top = hb_parni( 4 );
      rc.right = hb_parni( 5 );
      rc.bottom = hb_parni( 6 );
   }

   InvalidateRect( pted->handle,  // handle of window with changed update region
         ( hb_pcount(  ) > 2 ) ? &rc : NULL,    // address of rectangle coordinates
         hb_parni( 2 )          // erase-background flag
          );
}
/*
HB_FUNC( HCED_SETFOCUS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   SetFocus( ( HWND ) pted->handle );
}
*/
/*
 * hced_LineOut( ::hEdit, @x1, @yPos, @x2, cLine, Len(cLine), nAlign, lPaint, lCalc )
 */
HB_FUNC( HCED_LINEOUT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   TEDFONT *font;
#ifdef UNICODE
   void *hText;
   LPCTSTR szText = HB_PARSTR( 5, &hText, NULL );
#else
   char *szText = ( char * )hb_parc( 5 );
#endif
   int iRight = (HB_ISNIL(8))? 0 : hb_parni(8);
   short int bCalc = (short int) ( (HB_ISNIL(9))? 1 : hb_parl(9) );
   int x1 = hb_parni( 2 ), ypos = hb_parni( 3 ), x2 = hb_parni( 4 ), iLen = hb_parni( 6 );
   int iPrinted, iCalculated = 0, iAlign = hb_parni( 7 );
   int iRealWidth, i, iFont;
   int iHeight = 0, iMaxAscent = 0;

   if( iLen )
   {
      if( bCalc )
      {
         if( pted->iDocWidth )
         {
            iPrinted = ted_CalcLineWidth( pted, szText, iLen, pted->iDocWidth-x1, &iRealWidth, pted->bWrap );
            //hwg_writelog( NULL, "iWidth: %d iDocWidth: %d iRealWidth %d iPrinted %d \r\n", x2, pted->iDocWidth, iRealWidth, iPrinted );
            //iPrinted = ted_CalcLineWidth( pted, szText, iCalculated, x2-x1, &iRealWidth, 0 );
         }
         else
            iPrinted = ted_CalcLineWidth( pted, szText, iLen, x2-x1, &iRealWidth, pted->bWrap );
      }
      else
         iPrinted = ted_CalcLineWidth( pted, szText, iLen, 30000, &iRealWidth, 0 );
   }
   else
      iPrinted = iRealWidth = 0;

   if( iAlign )
   {
      if( iAlign == 1 )
         x1 += (x2 - x1 - iRealWidth) / 2;
      else if( iAlign == 2 )
         x1 += x2 - x1 - iRealWidth;
   }
   pted->x1 = x1;
   pted->x2 = x1 + iRealWidth;

   i = 0;
   while( i < TEDATTRF_MAX )
   {
      iFont = *( pted->pattrf + i );
      font = ( (pted->hDCPrn)? pted->pFontsPrn : pted->pFontsScr ) +
            (iFont? iFont-1 : 0) ;
      iHeight = max( iHeight, font->tm.tmHeight + font->tm.tmExternalLeading ) + 1;
      iMaxAscent = max( iMaxAscent, font->tm.tmAscent );
      if( ! *( pted->pattrf+i ) )
         break;
      i ++;
   }
   iHeight ++;
   //hwg_writelog( NULL, "x1: %d iRight: %d ypos: %d iHeight: %d iLen %d iPrinted %d bCalc %d\r\n", x1, iRight, ypos, iHeight, iLen, iPrinted, bCalc );
   if( iRight )
   {
      pted->x2 = ted_LineOut( pted, x1, ypos, szText, iPrinted, iHeight, iMaxAscent, iRight );
   }
#ifdef UNICODE
   hb_strfree( hText );
#endif
   hb_storni( pted->x1, 2 );
   hb_storni( pted->x2, 4 );
   pted->ypos = ypos + iHeight;
   hb_storni( pted->ypos, 3 );
   hb_retni( (iCalculated)? iCalculated : iPrinted );
}

HB_FUNC( HCED_SETBORDER )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   if( HB_ISNUM(2) )
      pted->nBorder = hb_parnl(2);
   if( HB_ISNUM(3) )
      pted->lBorderClr = (COLORREF) hb_parnl(3);
}

HB_FUNC( HCED_DRAWBORDER )
{
}

HB_FUNC( HCED_COLOR2X )
{
   char s[8];
   int i;
   long int n = hb_parnl(1);

   sprintf(s,"#%2X%2X%2X", (unsigned int)(n%256), (unsigned int)((n/256)%256), (unsigned int)((n/65536)%256) );
   for( i=0; i<7; i++ )
      if( s[i] == ' ' )
         s[i] = '0';
   hb_retclen( s,7 );
}

HB_FUNC( HCED_X2COLOR )
{
   int i1, i2, i3;

   sscanf( hb_parc(1),"#%2X%2X%2X", &i1, &i2, &i3 );
   hb_retnl( i3*65536 + i2*256 + i1 );
}
