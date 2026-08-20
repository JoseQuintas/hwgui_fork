/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level richedit control functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwingui.h"
#if defined(__MINGW32__) || defined(__MINGW64__) || defined(__WATCOMC__)
#include <prsht.h>
#endif
#include <commctrl.h>
#define _RICHEDIT_VER	0x0200
#include <richedit.h>
#if defined(__DMC__)
#define GetWindowLongPtr GetWindowLong
#endif
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbdate.h"

#include "incomp_pointer.h"

LRESULT APIENTRY RichSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );

static HINSTANCE hRichEd = 0;
static WNDPROC wpOrigRichProc;

HB_FUNC( HWG_INITRICHEDIT )
{
   if( !hRichEd )
      hRichEd = LoadLibrary( TEXT( "riched20.dll" ) );
}

HB_FUNC( HWG_CREATERICHEDIT )
{
   HWND hCtrl;
   void *hText;
   LPCTSTR lpText;

   if( !hRichEd )
      hRichEd = LoadLibrary( TEXT( "riched20.dll" ) );

   hCtrl = CreateWindowEx( 0,   /* extended style    */
#ifdef UNICODE
         TEXT( "RichEdit20W" ), /* predefined class  */
#else
         TEXT( "RichEdit20A" ), /* predefined class  */
#endif
         NULL,                  /* title   */
         WS_CHILD | WS_VISIBLE | hb_parnl( 3 ), /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y   */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU )(UINT_PTR) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   lpText = HB_PARSTR( 8, &hText, NULL );
   if( lpText )
      SendMessage( hCtrl, WM_SETTEXT, 0, ( LPARAM ) lpText );
   hb_strfree( hText );

   HB_RETHANDLE( hCtrl );
}

/*
 * re_SetCharFormat( hCtrl, n1, n2, nColor, cName, nHeight, lBold, lItalic, 
           lUnderline, nCharset, lSuperScript/lSubscript(.T./.F.), lProtected )
 */
HB_FUNC( HWG_RE_SETCHARFORMAT )
{
   HWND hCtrl = ( HWND ) HB_PARHANDLE( 1 );
   CHARRANGE chrOld, chrNew;
   CHARFORMAT2 cf;
   PHB_ITEM pArr;

   SendMessage( hCtrl, EM_EXGETSEL, 0, ( LPARAM ) & chrOld );
   SendMessage( hCtrl, EM_HIDESELECTION, 1, 0 );

   if( HB_ISARRAY( 2 ) )
   {
      ULONG ul, ulLen, ulLen1;
      PHB_ITEM pArr1;
      pArr = hb_param( 2, HB_IT_ARRAY );
      ulLen = hb_arrayLen( pArr );
      for( ul = 1; ul <= ulLen; ul++ )
      {
         pArr1 = hb_arrayGetItemPtr( pArr, ul );
         ulLen1 = hb_arrayLen( pArr1 );
         chrNew.cpMin = hb_arrayGetNL( pArr1, 1 ) - 1;
         chrNew.cpMax = hb_arrayGetNL( pArr1, 2 ) - 1;
         SendMessage( hCtrl, EM_EXSETSEL, 0, ( LPARAM ) & chrNew );

         memset( &cf, 0, sizeof( CHARFORMAT2 ) );
         cf.cbSize = sizeof( CHARFORMAT2 );
         if( hb_itemType( hb_arrayGetItemPtr( pArr1, 3 ) ) != HB_IT_NIL )
         {
            cf.crTextColor = ( COLORREF ) hb_arrayGetNL( pArr1, 3 );
            cf.dwMask |= CFM_COLOR;
         }
         if( ulLen1 > 3 &&
               hb_itemType( hb_arrayGetItemPtr( pArr1, 4 ) ) != HB_IT_NIL )
         {
            HB_ITEMCOPYSTR( hb_arrayGetItemPtr( pArr1, 4 ),
                  cf.szFaceName, HB_SIZEOFARRAY( cf.szFaceName ) );
            cf.szFaceName[HB_SIZEOFARRAY( cf.szFaceName ) - 1] = '\0';
            cf.dwMask |= CFM_FACE;
         }
         if( ulLen1 > 4 &&
               hb_itemType( hb_arrayGetItemPtr( pArr1, 5 ) ) != HB_IT_NIL )
         {
            cf.yHeight = hb_arrayGetNL( pArr1, 5 );
            cf.dwMask |= CFM_SIZE;
         }
         if( ulLen1 > 5 &&
               hb_itemType( hb_arrayGetItemPtr( pArr1, 6 ) ) != HB_IT_NIL &&
               hb_arrayGetL( pArr1, 6 ) )
         {
            cf.dwEffects |= CFE_BOLD;
         }
         if( ulLen1 > 6 &&
               hb_itemType( hb_arrayGetItemPtr( pArr1, 7 ) ) != HB_IT_NIL &&
               hb_arrayGetL( pArr1, 7 ) )
         {
            cf.dwEffects |= CFE_ITALIC;
         }
         if( ulLen1 > 7 &&
               hb_itemType( hb_arrayGetItemPtr( pArr1, 8 ) ) != HB_IT_NIL &&
               hb_arrayGetL( pArr1, 8 ) )
         {
            cf.dwEffects |= CFE_UNDERLINE;
         }
         if( ulLen1 > 8 &&
               hb_itemType( hb_arrayGetItemPtr( pArr1, 9 ) ) != HB_IT_NIL )
         {
            cf.bCharSet = ( BYTE ) hb_arrayGetNL( pArr1, 9 );
            cf.dwMask |= CFM_CHARSET;
         }
         if( ulLen1 > 9 &&
               hb_itemType( hb_arrayGetItemPtr( pArr1, 10 ) ) != HB_IT_NIL )
         {
            if( hb_arrayGetL( pArr1, 10 ) )
               cf.dwEffects |= CFE_SUPERSCRIPT;
            else
               cf.dwEffects |= CFE_SUBSCRIPT;
            cf.dwMask |= CFM_SUPERSCRIPT;
         }
         if( ulLen1 > 10 &&
               hb_itemType( hb_arrayGetItemPtr( pArr1, 11 ) ) != HB_IT_NIL &&
               hb_arrayGetL( pArr1, 11 ) )
         {
            cf.dwEffects |= CFE_PROTECTED;
         }
         cf.dwMask |=
               ( CFM_BOLD | CFM_ITALIC | CFM_UNDERLINE | CFM_PROTECTED );
         SendMessage( hCtrl, EM_SETCHARFORMAT, SCF_SELECTION,
               ( LPARAM ) & cf );
      }
   }
   else
   {
      /*   Set new selection   */
      chrNew.cpMin = hb_parnl( 2 ) - 1;
      chrNew.cpMax = hb_parnl( 3 ) - 1;
      SendMessage( hCtrl, EM_EXSETSEL, 0, ( LPARAM ) & chrNew );

      memset( &cf, 0, sizeof( CHARFORMAT2 ) );
      cf.cbSize = sizeof( CHARFORMAT2 );

      if( !HB_ISNIL( 4 ) )
      {
         cf.crTextColor = ( COLORREF ) hb_parnl( 4 );
         cf.dwMask |= CFM_COLOR;
      }
      if( !HB_ISNIL( 5 ) )
      {
         HB_ITEMCOPYSTR( hb_param( 5, HB_IT_ANY ),
               cf.szFaceName, HB_SIZEOFARRAY( cf.szFaceName ) );
         cf.szFaceName[HB_SIZEOFARRAY( cf.szFaceName ) - 1] = '\0';
         cf.dwMask |= CFM_FACE;
      }
      if( !HB_ISNIL( 6 ) )
      {
         cf.yHeight = hb_parnl( 6 );
         cf.dwMask |= CFM_SIZE;
      }
      if( !HB_ISNIL( 7 ) )
      {
         cf.dwEffects |= ( hb_parl( 7 ) ) ? CFE_BOLD : 0;
         cf.dwMask |= CFM_BOLD;
      }
      if( !HB_ISNIL( 8 ) )
      {
         cf.dwEffects |= ( hb_parl( 8 ) ) ? CFE_ITALIC : 0;
         cf.dwMask |= CFM_ITALIC;
      }
      if( !HB_ISNIL( 9 ) )
      {
         cf.dwEffects |= ( hb_parl( 9 ) ) ? CFE_UNDERLINE : 0;
         cf.dwMask |= CFM_UNDERLINE;
      }
      if( !HB_ISNIL( 10 ) )
      {
         cf.bCharSet = ( BYTE ) hb_parnl( 10 );
         cf.dwMask |= CFM_CHARSET;
      }
      if( !HB_ISNIL( 11 ) )
      {
         if( hb_parl( 9 ) )
            cf.dwEffects |= CFE_SUPERSCRIPT;
         else
            cf.dwEffects |= CFE_SUBSCRIPT;
         cf.dwMask |= CFM_SUPERSCRIPT;
      }
      if( !HB_ISNIL( 12 ) )
      {
         cf.dwEffects |= CFE_PROTECTED;
         cf.dwMask |= CFM_PROTECTED;
      }

      SendMessage( hCtrl, EM_SETCHARFORMAT, SCF_SELECTION, ( LPARAM ) & cf );
   }

   /*   Restore selection   */
   SendMessage( hCtrl, EM_EXSETSEL, 0, ( LPARAM ) & chrOld );
   SendMessage( hCtrl, EM_HIDESELECTION, 0, 0 );

}

/*
 * re_SetDefault( hCtrl, nColor, cName, nHeight, lBold, lItalic, lUnderline, nCharset )
 */
HB_FUNC( HWG_RE_SETDEFAULT )
{
   HWND hCtrl = ( HWND ) HB_PARHANDLE( 1 );
   CHARFORMAT2 cf;

   memset( &cf, 0, sizeof( CHARFORMAT2 ) );
   cf.cbSize = sizeof( CHARFORMAT2 );

   if( HB_ISNUM( 2 ) )
   {
      cf.crTextColor = ( COLORREF ) hb_parnl( 2 );
      cf.dwMask |= CFM_COLOR;
   }
   if( HB_ISCHAR( 3 ) )
   {
      HB_ITEMCOPYSTR( hb_param( 3, HB_IT_ANY ),
            cf.szFaceName, HB_SIZEOFARRAY( cf.szFaceName ) );
      cf.szFaceName[HB_SIZEOFARRAY( cf.szFaceName ) - 1] = '\0';
      cf.dwMask |= CFM_FACE;
   }

   if( HB_ISNUM( 4 ) )
   {
      cf.yHeight = hb_parnl( 4 );
      cf.dwMask |= CFM_SIZE;
   }

   if( !HB_ISNIL( 5 ) )
   {
      cf.dwEffects |= ( hb_parl( 5 ) ) ? CFE_BOLD : 0;
   }
   if( !HB_ISNIL( 6 ) )
   {
      cf.dwEffects |= ( hb_parl( 6 ) ) ? CFE_ITALIC : 0;
   }
   if( !HB_ISNIL( 7 ) )
   {
      cf.dwEffects |= ( hb_parl( 7 ) ) ? CFE_UNDERLINE : 0;
   }

   if( HB_ISNUM( 8 ) )
   {
      cf.bCharSet = ( BYTE ) hb_parnl( 8 );
      cf.dwMask |= CFM_CHARSET;
   }

   cf.dwMask |= ( CFM_BOLD | CFM_ITALIC | CFM_UNDERLINE );
   SendMessage( hCtrl, EM_SETCHARFORMAT, SCF_ALL, ( LPARAM ) & cf );


}

/*
 * re_CharFromPos( hEdit, xPos, yPos ) --> nPos
 */
HB_FUNC( HWG_RE_CHARFROMPOS )
{
   HWND hCtrl = ( HWND ) HB_PARHANDLE( 1 );
   int x = hb_parni( 2 );
   int y = hb_parni( 3 );
   ULONG ul;
   POINTL pp;

   pp.x = x;
   pp.y = y;
   ul = SendMessage( hCtrl, EM_CHARFROMPOS, 0, ( LPARAM ) & pp );
   hb_retnl( ul );
}

/*
 * re_GetTextRange( hEdit, n1, n2 )
 */
HB_FUNC( HWG_RE_GETTEXTRANGE )
{
   HWND hCtrl = ( HWND ) HB_PARHANDLE( 1 );
   TEXTRANGE tr;
   ULONG ul;

   tr.chrg.cpMin = hb_parnl( 2 ) - 1;
   tr.chrg.cpMax = hb_parnl( 3 ) - 1;

   tr.lpstrText = ( LPTSTR ) hb_xgrab( ( tr.chrg.cpMax - tr.chrg.cpMin + 2 ) *
         sizeof( TCHAR ) );
   ul = SendMessage( hCtrl, EM_GETTEXTRANGE, 0, ( LPARAM ) & tr );
   HB_RETSTRLEN( tr.lpstrText, ul );
   hb_xfree( tr.lpstrText );

}

/*
 * re_GetLine( hEdit, nLine )
 */
HB_FUNC( HWG_RE_GETLINE )
{
   HWND hCtrl = ( HWND ) HB_PARHANDLE( 1 );
   int nLine = hb_parni( 2 );
   ULONG uLineIndex = SendMessage( hCtrl, EM_LINEINDEX, ( WPARAM ) nLine, 0 );
   ULONG ul = SendMessage( hCtrl, EM_LINELENGTH, ( WPARAM ) uLineIndex, 0 );
   LPTSTR lpBuf = ( LPTSTR ) hb_xgrab( ( ul + 4 ) * sizeof( TCHAR ) );

   *( ( ULONG * ) lpBuf ) = ul;
   ul = SendMessage( hCtrl, EM_GETLINE, nLine, ( LPARAM ) lpBuf );
   HB_RETSTRLEN( lpBuf, ul );
   hb_xfree( lpBuf );
}

HB_FUNC( HWG_RE_INSERTTEXT )
{
   void *hString;
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), EM_REPLACESEL, 0,
         ( LPARAM ) HB_PARSTR( 2, &hString, NULL ) );
   hb_strfree( hString );
}

/*
 * re_FindText( hEdit, cFind, nStart, bCase, bWholeWord, bSearchUp )
 */
HB_FUNC( HWG_RE_FINDTEXT )
{
   HWND hCtrl = ( HWND ) HB_PARHANDLE( 1 );
   FINDTEXTEX ft;
   LONG lPos;
   LONG lFlag = ( ( HB_ISNIL( 4 ) || !hb_parl( 4 ) ) ? 0 : FR_MATCHCASE ) |
         ( ( HB_ISNIL( 5 ) || !hb_parl( 5 ) ) ? 0 : FR_WHOLEWORD ) |
         ( ( HB_ISNIL( 6 ) || !hb_parl( 6 ) ) ? FR_DOWN : 0 );
   void *hString;

   ft.chrg.cpMin = ( HB_ISNIL( 3 ) ) ? 0 : hb_parnl( 3 );
   ft.chrg.cpMax = -1;
   ft.lpstrText = ( LPTSTR ) HB_PARSTR( 2, &hString, NULL );

   lPos = ( LONG ) SendMessage( hCtrl, EM_FINDTEXTEX, ( WPARAM ) lFlag,
         ( LPARAM ) & ft );
   hb_strfree( hString );
   hb_retnl( lPos );
}

HB_FUNC( HWG_RE_SETZOOM )
{
   HWND hwnd = ( HWND ) HB_PARHANDLE( 1 );
   int nNum = hb_parni( 2 );
   int nDen = hb_parni( 3 );
   hb_retnl( ( BOOL ) SendMessage( hwnd, EM_SETZOOM, nNum, nDen ) );
}


HB_FUNC( HWG_RE_ZOOMOFF )
{
   HWND hwnd = ( HWND ) HB_PARHANDLE( 1 );
   hb_retnl( ( BOOL ) SendMessage( hwnd, EM_SETZOOM, 0, 0L ) );
}

HB_FUNC( HWG_RE_GETZOOM )
{
   HWND hwnd = ( HWND ) HB_PARHANDLE( 1 );
   int nNum = hb_parni( 2 );
   int nDen = hb_parni( 3 );
   hb_retnl( ( BOOL ) SendMessage( hwnd, EM_GETZOOM, ( WPARAM ) & nNum,
               ( LPARAM ) & nDen ) );
   hb_storni( nNum, 2 );
   hb_storni( nDen, 3 );
}

HB_FUNC( HWG_PRINTRTF )
{
   HWND hwnd = ( HWND ) HB_PARHANDLE( 1 );
   HDC hdc = ( HDC ) HB_PARHANDLE( 2 );
   FORMATRANGE fr;
   BOOL fSuccess = TRUE;
   int cxPhysOffset = GetDeviceCaps( hdc, PHYSICALOFFSETX );
   int cyPhysOffset = GetDeviceCaps( hdc, PHYSICALOFFSETY );
   int cxPhys = GetDeviceCaps( hdc, PHYSICALWIDTH );
   int cyPhys = GetDeviceCaps( hdc, PHYSICALHEIGHT );
   int ppi_x = GetDeviceCaps( hdc, LOGPIXELSX );
   int ppi_y = GetDeviceCaps( hdc, LOGPIXELSX );
   int cpMin;

   SendMessage( hwnd, EM_SETTARGETDEVICE, ( WPARAM ) hdc, cxPhys / 2 );
   fr.hdc = hdc;
   fr.hdcTarget = hdc;
   fr.rc.left = 1440 * cxPhysOffset / ppi_x;
   fr.rc.right = 1440 * ( cxPhysOffset + cxPhys ) / ppi_x;
   fr.rc.top = 1440 * cyPhysOffset / ppi_y;
   fr.rc.bottom = 1440 * ( cyPhysOffset + cyPhys ) / ppi_y;

   SendMessage( hwnd, EM_SETSEL, 0, ( LPARAM ) - 1 );
   SendMessage( hwnd, EM_EXGETSEL, 0, ( LPARAM ) & fr.chrg );
   while( fr.chrg.cpMin < fr.chrg.cpMax && fSuccess )
   {
      fSuccess = StartPage( hdc ) > 0;
      if( !fSuccess )
         break;
      cpMin = SendMessage( hwnd, EM_FORMATRANGE, TRUE, ( LPARAM ) & fr );
      if( cpMin <= fr.chrg.cpMin )
      {
         fSuccess = FALSE;
         break;
      }
      fr.chrg.cpMin = cpMin;
      fSuccess = EndPage( hdc ) > 0;
   }
   SendMessage( hwnd, EM_FORMATRANGE, FALSE, 0 );
   SendMessage( hwnd, EM_EXSETSEL, 0, ( LPARAM ) & fr.chrg );
   SendMessage( hwnd, EM_HIDESELECTION, 0, 0 );
   hb_retnl( ( BOOL ) fSuccess );
}

HB_FUNC( HWG_INITRICHPROC )
{
   wpOrigRichProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) RichSubclassProc );
}

LRESULT APIENTRY RichSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
      hb_vmPushLong( ( LONG ) lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( CallWindowProc( wpOrigRichProc, hWnd, message, wParam,
                     lParam ) );
      else
         return res;
   }
   else
      return ( CallWindowProc( wpOrigRichProc, hWnd, message, wParam,
                  lParam ) );
}

static DWORD CALLBACK RichStreamOutCallback( DWORD_PTR dwCookie, LPBYTE pbBuff,
      LONG cb, LONG * pcb )
{
   HANDLE pFile = ( HANDLE ) dwCookie;
   DWORD dwW;
   HB_SYMBOL_UNUSED( pcb );

   if( pFile == INVALID_HANDLE_VALUE )
      return 0;

   WriteFile( pFile, pbBuff, cb, &dwW, NULL );
   return 0;
}

static DWORD CALLBACK EditStreamCallback( DWORD_PTR dwCookie, LPBYTE lpBuff,
      LONG cb, PLONG pcb )
{
   HANDLE hFile = ( HANDLE ) dwCookie;
   return !ReadFile( hFile, lpBuff, cb, ( DWORD * ) pcb, NULL );
}

HB_FUNC( HWG_SAVERICHEDIT )
{

   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HANDLE hFile;
   EDITSTREAM es;
   void *hFileName;
   LPCTSTR lpFileName;
   HB_SIZE nSize;

   lpFileName = HB_PARSTR( 2, &hFileName, &nSize );
   hFile =
         CreateFile( lpFileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS,
         FILE_ATTRIBUTE_NORMAL, NULL );
   if( hFile == INVALID_HANDLE_VALUE )
   {
      hb_retni( 0 );
      return;
   }
   es.dwCookie = ( DWORD_PTR ) hFile;
   es.pfnCallback = RichStreamOutCallback;

   SendMessage( hWnd, EM_STREAMOUT, ( WPARAM ) SF_RTF, ( LPARAM ) & es );
   CloseHandle( hFile );
   HB_RETHANDLE( hFile );

}

HB_FUNC( HWG_LOADRICHEDIT )
{

   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HANDLE hFile;
   EDITSTREAM es;
   void *hFileName;
   LPCTSTR lpFileName;
   HB_SIZE nSize;

   lpFileName = HB_PARSTR( 2, &hFileName, &nSize );
   hFile =
         CreateFile( lpFileName, GENERIC_READ, FILE_SHARE_READ, 0,
         OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL );
   if( hFile == INVALID_HANDLE_VALUE )
   {
      hb_retni( 0 );
      return;
   }
   es.dwCookie = ( DWORD_PTR ) hFile;
   es.pfnCallback = EditStreamCallback;
   SendMessage( hWnd, EM_STREAMIN, ( WPARAM ) SF_RTF, ( LPARAM ) & es );
   CloseHandle( hFile );
   HB_RETHANDLE( hFile );
}

/* =============================== EOF of richedit.c ================================ */

