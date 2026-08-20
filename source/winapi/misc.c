/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Miscellaneous functions
 *
 * Copyright 2003 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#define HB_MEM_NUM_LEN  8

#define OEMRESOURCE
#include "hwingui.h"
/* Standard C libraries */
#include <commctrl.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <malloc.h>
#include <time.h>
#include <sys/stat.h>


#include "hbmath.h"
#include "hbapi.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbset.h"

#include "missing.h"

#include "incomp_pointer.h"
#include "warnings.h"


void hwg_writelog( const char * sFile, const char * sTraceMsg, ... )
{
   FILE *hFile;

   if( sFile == NULL )
   {
      hFile = hb_fopen( "ac.log", "a" );
   }
   else
   {
      hFile = hb_fopen( sFile, "a" );
   }

   if( hFile )
   {
      va_list ap;

      va_start( ap, sTraceMsg );
      vfprintf( hFile, sTraceMsg, ap );
      va_end( ap );

      fclose( hFile );
   }

}

HB_FUNC( HWG_SETDLGRESULT )
{
   SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ), DWLP_MSGRESULT,
         hb_parni( 2 ) );
}

HB_FUNC( HWG_SETCAPTURE )
{
   HB_RETHANDLE( SetCapture( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_RELEASECAPTURE )
{
   hb_retl( ReleaseCapture(  ) );
}

HB_FUNC( HWG_COPYSTRINGTOCLIPBOARD )
{
   if( OpenClipboard( GetActiveWindow(  ) ) )
   {
      HGLOBAL hglbCopy;
      char *lptstrCopy;
      void *hStr;
      HB_SIZE nLen;
      LPCTSTR lpStr;

      EmptyClipboard(  );

      lpStr = HB_PARSTRDEF( 1, &hStr, &nLen );
      hglbCopy = GlobalAlloc( GMEM_DDESHARE, ( nLen + 1 ) * sizeof( TCHAR ) );
      if( hglbCopy != NULL )
      {
         // Lock the handle and copy the text to the buffer.
         lptstrCopy = ( char * ) GlobalLock( hglbCopy );
         memcpy( lptstrCopy, lpStr, nLen * sizeof( TCHAR ) );
         lptstrCopy[nLen * sizeof( TCHAR )] = 0;
         GlobalUnlock( hglbCopy );
         hb_strfree( hStr );

         // Place the handle on the clipboard.
#ifdef UNICODE
         SetClipboardData( CF_UNICODETEXT, hglbCopy );
#else
         SetClipboardData( CF_TEXT, hglbCopy );
#endif
      }
      CloseClipboard(  );
   }
}

HB_FUNC( HWG_GETCLIPBOARDTEXT )
{
   HWND hWnd = ( HWND ) hb_parptr( 1 );
   LPTSTR lpText = NULL;

   if( OpenClipboard( hWnd ) )
   {
#ifdef UNICODE
      HGLOBAL hglb = GetClipboardData( CF_UNICODETEXT );
#else
      HGLOBAL hglb = GetClipboardData( CF_TEXT );
#endif
      if( hglb )
      {
         LPVOID lpMem = GlobalLock( hglb );
         if( lpMem )
         {
            HB_SIZE nSize = ( HB_SIZE ) GlobalSize( hglb );
            if( nSize )
            {
               lpText = ( LPTSTR ) hb_xgrab( nSize + 1 );
               memcpy( lpText, lpMem, nSize );
               ((char*)lpText)[nSize] = 0;
            }
            ( void ) GlobalUnlock( hglb );
         }
      }
      CloseClipboard(  );
   }
   HB_RETSTR( lpText );
   if( lpText )
      hb_xfree( lpText );
}

HB_FUNC( HWG_GETSTOCKOBJECT )
{
   HB_RETHANDLE( GetStockObject( hb_parni( 1 ) ) );
}

HB_FUNC( HWG_LOWORD )
{
   hb_retni( ( int ) ( ( HB_ISPOINTER( 1 ) ?
   PtrToUlong( hb_parptr( 1 ) ) :
                              ( ULONG ) hb_parnl( 1 ) ) & 0xFFFF ) );
}

HB_FUNC( HWG_HIWORD )
{
   hb_retni( ( int ) ( ( ( HB_ISPOINTER( 1 ) ? PtrToUlong( hb_parptr( 1 ) ) :
                              ( ULONG ) hb_parnl( 1 ) ) >> 16 ) & 0xFFFF ) );
}

HB_FUNC( HWG_BITOR )
{
   hb_retnl( ( hb_parnl( 1 ) | hb_parnl( 2 ) ) );
}

HB_FUNC( HWG_BITOR_INT )
{
   hb_retni( ( hb_parni( 1 ) | hb_parni( 2 ) ) );
}

HB_FUNC( HWG_BITAND )
{
   hb_retnl( hb_parnl( 1 ) & hb_parnl( 2 ) );
}

HB_FUNC( HWG_BITANDINVERSE )
{
   hb_retnl( hb_parnl( 1 ) & ( ~hb_parnl( 2 ) ) );
}

HB_FUNC( HWG_SETBIT )
{
   if( hb_pcount(  ) < 3 || hb_parni( 3 ) )
      hb_retnl( hb_parnl( 1 ) | ( 1 << ( hb_parni( 2 ) - 1 ) ) );
   else
      hb_retnl( hb_parnl( 1 ) & ~( 1 << ( hb_parni( 2 ) - 1 ) ) );
}

HB_FUNC( HWG_SETBITBYTE )
{
  int para3;

   if ( hb_pcount() < 3 )
    {
      /* Return previous value */
      hb_retni( hb_parni(1) );
    }

    para3 = hb_parni( 3 );
    if ( para3 < 0 || para3 > 1 )
    {
      /* Return previous value */
      hb_retni( hb_parni(1) );
    }

   if ( para3 == 1 )
   {
   /* 0 to 1 */
    hb_retni( hb_parni(1) | ( 1 << (hb_parni(2) - 1) ) );
   }
   else
   {
   /* 1 to 0 */
   hb_retni( hb_parni(1) & ~( 1 << (hb_parni(2) - 1) ) );
   }
}

HB_FUNC( HWG_CHECKBIT )
{
   hb_retl( hb_parnl( 1 ) & ( 1 << ( hb_parni( 2 ) - 1 ) ) );
}

HB_FUNC( HWG_SIN )
{
   hb_retnd( sin( hb_parnd( 1 ) ) );
}

HB_FUNC( HWG_COS )
{
   hb_retnd( cos( hb_parnd( 1 ) ) );
}

HB_FUNC( HWG_CLIENTTOSCREEN )
{
   POINT pt;
   PHB_ITEM aPoint = hb_itemArrayNew( 2 );
   PHB_ITEM temp;

   pt.x = hb_parnl( 2 );
   pt.y = hb_parnl( 3 );
   ClientToScreen( ( HWND ) HB_PARHANDLE( 1 ), &pt );

   temp = hb_itemPutNL( NULL, pt.x );
   hb_itemArrayPut( aPoint, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pt.y );
   hb_itemArrayPut( aPoint, 2, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aPoint );
   hb_itemRelease( aPoint );
}

HB_FUNC( HWG_SCREENTOCLIENT )
{
   POINT pt;
   RECT R;
   PHB_ITEM aPoint = hb_itemArrayNew( 2 );
   PHB_ITEM temp;

   if( hb_pcount(  ) > 2 )
   {
      pt.x = hb_parnl( 2 );
      pt.y = hb_parnl( 3 );

      ScreenToClient( ( HWND ) HB_PARHANDLE( 1 ), &pt );
   }
   else
   {
      Array2Rect( hb_param( 2, HB_IT_ARRAY ), &R );
      ScreenToClient( ( HWND ) HB_PARHANDLE( 1 ), ( LPPOINT ) ( void * ) &R );
      ScreenToClient( ( HWND ) HB_PARHANDLE( 1 ),
            ( ( LPPOINT ) ( void * ) &R ) + 1 );
      hb_itemRelease( hb_itemReturn( Rect2Array( &R ) ) );
      return;
   }

   temp = hb_itemPutNL( NULL, pt.x );
   hb_itemArrayPut( aPoint, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pt.y );
   hb_itemArrayPut( aPoint, 2, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aPoint );
   hb_itemRelease( aPoint );

}

HB_FUNC( HWG_GETCURSORPOS )
{
   POINT pt;
   PHB_ITEM aPoint = hb_itemArrayNew( 2 );
   PHB_ITEM temp;

   GetCursorPos( &pt );
   temp = hb_itemPutNL( NULL, pt.x );
   hb_itemArrayPut( aPoint, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pt.y );
   hb_itemArrayPut( aPoint, 2, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aPoint );
   hb_itemRelease( aPoint );

}

HB_FUNC( HWG_SETCURSORPOS )
{
   int x, y;

   x = hb_parni( 1 );
   y = hb_parni( 2 );

   SetCursorPos( x, y );
}

HB_FUNC( HWG_GETCURRENTDIR )
{
   TCHAR buffer[HB_PATH_MAX];

   GetCurrentDirectory( HB_PATH_MAX, buffer );
   HB_RETSTR( buffer );
}

HB_FUNC( HWG_WINEXEC )
{
   hb_retni( WinExec( hb_parc( 1 ), ( UINT ) hb_parni( 2 ) ) );
}

HB_FUNC( HWG_GETKEYBOARDSTATE )
{
   BYTE lpbKeyState[256];
   GetKeyboardState( lpbKeyState );
   lpbKeyState[255] = '\0';
   hb_retclen( ( char * ) lpbKeyState, 255 );
}

HB_FUNC( HWG_GETKEYSTATE )
{
   hb_retni( GetKeyState( hb_parni( 1 ) ) );
}

HB_FUNC( HWG_GETKEYNAMETEXT )
{
   TCHAR cText[MAX_PATH];
   int iRet = GetKeyNameText( hb_parnl( 1 ), cText, MAX_PATH );

   if( iRet )
      HB_RETSTRLEN( cText, iRet );
}

HB_FUNC( HWG_ACTIVATEKEYBOARDLAYOUT )
{
   //LPTSTR m_PreviousLayout[KL_NAMELENGTH];
   TCHAR m_PreviousLayout[KL_NAMELENGTH];

   GetKeyboardLayoutName( m_PreviousLayout ); 

   if( HB_ISCHAR( 1 ) )
   {
      void *hLayout;
      LPCTSTR lpLayout = HB_PARSTR( 1, &hLayout, NULL );
      HKL curr = GetKeyboardLayout( 0 );
      TCHAR sBuff[KL_NAMELENGTH];
      UINT num = GetKeyboardLayoutList( 0, NULL ), i = 0;

      do
      {
         GetKeyboardLayoutName( sBuff );
         if( !lstrcmp( sBuff, lpLayout ) )
            break;
         ActivateKeyboardLayout( 0, 0 );
         i++;
      }

      while( i < num );
      if( i >= num )
         ActivateKeyboardLayout( curr, 0 );

      hb_strfree( hLayout );
   }

   HB_RETSTR( m_PreviousLayout );
}
/*
HB_FUNC( HWG_GETKEYBOARDLAYOUT ) 
{ 
   TCHAR m_PreviousLayout[KL_NAMELENGTH];

   GetKeyboardLayoutName( m_PreviousLayout ); 
   hb_retc( m_PreviousLayout );
} 
*/

/*
 * Pts2Pix( nPoints [,hDC] ) --> nPixels
 * Conversion from points to pixels, provided by Vic McClung.
 */

HB_FUNC( HWG_PTS2PIX )
{

   HDC hDC;
   BOOL lDC = 1;

   if( hb_pcount(  ) > 1 && !HB_ISNIL( 1 ) )
   {
      hDC = ( HDC ) HB_PARHANDLE( 2 );
      lDC = 0;
   }
   else
      hDC = CreateDC( TEXT( "DISPLAY" ), NULL, NULL, NULL );

   hb_retni( MulDiv( hb_parni( 1 ), GetDeviceCaps( hDC, LOGPIXELSY ), 72 ) );
   if( lDC )
      DeleteDC( hDC );
}

/* Functions Contributed  By Luiz Rafael Culik Guimaraes( culikr@uol.com.br) */

HB_FUNC( HWG_GETWINDOWSDIR )
{
   TCHAR szBuffer[MAX_PATH + 1] = { 0 };

   GetWindowsDirectory( szBuffer, MAX_PATH );
   HB_RETSTR( szBuffer );
}

HB_FUNC( HWG_GETSYSTEMDIR )
{
   TCHAR szBuffer[MAX_PATH + 1] = { 0 };

   GetSystemDirectory( szBuffer, MAX_PATH );
   HB_RETSTR( szBuffer );
}

HB_FUNC( HWG_GETTEMPDIR )
{
   TCHAR szBuffer[MAX_PATH + 1] = { 0 };

   GetTempPath( MAX_PATH, szBuffer );
   HB_RETSTR( szBuffer );
}

HB_FUNC( HWG_POSTQUITMESSAGE )
{
   PostQuitMessage( hb_parni( 1 ) );
}

/*
Contributed by Rodrigo Moreno rodrigo_moreno@yahoo.com base upon code minigui
*/

HB_FUNC( HWG_SHELLABOUT )
{
   void *hStr1, *hStr2;

   hb_retni( ShellAbout( 0,
               HB_PARSTRDEF( 1, &hStr1, NULL ),
               HB_PARSTRDEF( 2, &hStr2, NULL ),
               ( HB_ISNIL( 3 ) ? NULL : ( HICON ) HB_PARHANDLE( 3 ) ) ) );
   hb_strfree( hStr1 );
   hb_strfree( hStr2 );
}


HB_FUNC( HWG_GETDESKTOPWIDTH )
{
   hb_retni( GetSystemMetrics( SM_CXSCREEN ) );
}

HB_FUNC( HWG_GETDESKTOPHEIGHT )
{
   hb_retni( GetSystemMetrics( SM_CYSCREEN ) );
}

HB_FUNC( HWG_GETWORKAREA )
{
   PHB_ITEM aRect = hb_itemArrayNew( 4 );
   PHB_ITEM element = hb_itemNew( NULL );
   RECT rc;
   SystemParametersInfo( SPI_GETWORKAREA, 0, &rc, 0 );

   hb_arraySet( aRect, 1, hb_itemPutNL( element, rc.left ) );
   hb_arraySet( aRect, 2, hb_itemPutNL( element, rc.top ) );
   hb_arraySet( aRect, 3, hb_itemPutNL( element, rc.right ) );
   hb_arraySet( aRect, 4, hb_itemPutNL( element, rc.bottom ) );
   hb_itemRelease( element );
   hb_itemReturn( aRect );
   hb_itemRelease( aRect );

}

HB_FUNC( HWG_GETHELPDATA )
{
   HB_RETHANDLE( ( ( HELPINFO FAR * ) HB_PARHANDLE( 1 ) )->hItemHandle );
}

HB_FUNC( HWG_WINHELP )
{
   DWORD context;
   UINT style;
   void *hStr;

   switch ( hb_parni( 3 ) )
   {
      case 0:
         style = HELP_FINDER;
         context = 0;
         break;

      case 1:
         style = HELP_CONTEXT;
         context = hb_parni( 4 );
         break;

      case 2:
         style = HELP_CONTEXTPOPUP;
         context = hb_parni( 4 );
         break;

      default:
         style = HELP_CONTENTS;
         context = 0;
   }

   hb_retni( WinHelp( ( HWND ) HB_PARHANDLE( 1 ), HB_PARSTR( 2, &hStr, NULL ),
               style, context ) );
   hb_strfree( hStr );
}

HB_FUNC( HWG_GETNEXTDLGTABITEM )
{
   HB_RETHANDLE( GetNextDlgTabItem( ( HWND ) HB_PARHANDLE( 1 ),
               ( HWND ) HB_PARHANDLE( 2 ), hb_parl( 3 ) ) );
}

HB_FUNC( HWG_SLEEP )
{
   if( hb_parinfo( 1 ) )
      Sleep( hb_parnl( 1 ) );
}

HB_FUNC( HWG_KEYB_EVENT )
{
   DWORD dwFlags = ( !( HB_ISNIL( 2 ) ) &&
         hb_parl( 2 ) ) ? KEYEVENTF_EXTENDEDKEY : 0;
   int bShift = ( !( HB_ISNIL( 3 ) ) && hb_parl( 3 ) ) ? TRUE : FALSE;
   int bCtrl = ( !( HB_ISNIL( 4 ) ) && hb_parl( 4 ) ) ? TRUE : FALSE;
   int bAlt = ( !( HB_ISNIL( 5 ) ) && hb_parl( 5 ) ) ? TRUE : FALSE;

   if( bShift )
      keybd_event( VK_SHIFT, 0, 0, 0 );
   if( bCtrl )
      keybd_event( VK_CONTROL, 0, 0, 0 );
   if( bAlt )
      keybd_event( VK_MENU, 0, 0, 0 );

   keybd_event( ( BYTE ) hb_parni( 1 ), 0, dwFlags, 0 );
   keybd_event( ( BYTE ) hb_parni( 1 ), 0, dwFlags | KEYEVENTF_KEYUP, 0 );

   if( bShift )
      keybd_event( VK_SHIFT, 0, KEYEVENTF_KEYUP, 0 );
   if( bCtrl )
      keybd_event( VK_CONTROL, 0, KEYEVENTF_KEYUP, 0 );
   if( bAlt )
      keybd_event( VK_MENU, 0, KEYEVENTF_KEYUP, 0 );
}

/* SetScrollInfo( hWnd, nType, nRedraw, nPos, nPage, nmax )
*/
HB_FUNC( HWG_SETSCROLLINFO )
{
   SCROLLINFO si;
   UINT fMask = ( hb_pcount(  ) < 4 ) ? SIF_DISABLENOSCROLL : 0;

   if( hb_pcount(  ) > 3 && !HB_ISNIL( 4 ) )
   {
      si.nPos = hb_parni( 4 );
      fMask |= SIF_POS;
   }

   if( hb_pcount(  ) > 4 && !HB_ISNIL( 5 ) )
   {
      si.nPage = hb_parni( 5 );
      fMask |= SIF_PAGE;
   }

   if( hb_pcount(  ) > 5 && !HB_ISNIL( 6 ) )
   {
      si.nMin = 0;
      si.nMax = hb_parni( 6 );
      fMask |= SIF_RANGE;
   }

   si.cbSize = sizeof( SCROLLINFO );
   si.fMask = fMask;

   SetScrollInfo( ( HWND ) HB_PARHANDLE( 1 ),   // handle of window with scroll bar
         hb_parni( 2 ),         // scroll bar flags
         &si, hb_parni( 3 )     // redraw flag
          );
}

HB_FUNC( HWG_GETSCROLLRANGE )
{
   int MinPos, MaxPos;

   GetScrollRange( ( HWND ) HB_PARHANDLE( 1 ),  // handle of window with scroll bar
         hb_parni( 2 ),         // scroll bar flags
         &MinPos,               // address of variable that receives minimum position
         &MaxPos                // address of variable that receives maximum position
          );
   if( hb_pcount(  ) > 2 )
   {
      hb_storni( MinPos, 3 );
      hb_storni( MaxPos, 4 );
   }
   hb_retni( MaxPos - MinPos );
}

HB_FUNC( HWG_SETSCROLLRANGE )
{
   hb_retl( SetScrollRange( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ),
               hb_parni( 3 ), hb_parni( 4 ), hb_parl( 5 ) ) );
}


HB_FUNC( HWG_GETSCROLLPOS )
{
   hb_retni( GetScrollPos( ( HWND ) HB_PARHANDLE( 1 ),  // handle of window with scroll bar
               hb_parni( 2 )    // scroll bar flags
          ) );
}

HB_FUNC( HWG_SETSCROLLPOS )
{
   SetScrollPos( ( HWND ) HB_PARHANDLE( 1 ),    // handle of window with scroll bar
         hb_parni( 2 ),         // scroll bar flags
         hb_parni( 3 ), TRUE );
}

HB_FUNC( HWG_SHOWSCROLLBAR )
{
   ShowScrollBar( ( HWND ) HB_PARHANDLE( 1 ),   // handle of window with scroll bar
         hb_parni( 2 ),         // scroll bar flags
         hb_parl( 3 )           // scroll bar visibility
          );
}

HB_FUNC( HWG_SCROLLWINDOW )
{
   ScrollWindow( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ),
         NULL, NULL );
}


HB_FUNC( HWG_ISCAPSLOCKACTIVE )
{
   hb_retl( GetKeyState( VK_CAPITAL ) );
}

HB_FUNC( HWG_ISNUMLOCKACTIVE )
{
   hb_retl( GetKeyState( VK_NUMLOCK ) );
}

HB_FUNC( HWG_ISSCROLLLOCKACTIVE )
{
   hb_retl( GetKeyState( VK_SCROLL ) );
}

/* Added By Sandro Freire sandrorrfreire_nospam_yahoo.com.br*/

HB_FUNC( HWG_CREATEDIRECTORY )
{
   void *hStr;
   CreateDirectory( HB_PARSTR( 1, &hStr, NULL ), NULL );
   hb_strfree( hStr );
}

HB_FUNC( HWG_REMOVEDIRECTORY )
{
   void *hStr;
   hb_retl( RemoveDirectory( HB_PARSTR( 1, &hStr, NULL ) ) );
   hb_strfree( hStr );
}

HB_FUNC( HWG_SETCURRENTDIRECTORY )
{
   void *hStr;
   SetCurrentDirectory( HB_PARSTR( 1, &hStr, NULL ) );
   hb_strfree( hStr );
}

HB_FUNC( HWG_DELETEFILE )
{
   void *hStr;
   hb_retl( DeleteFile( HB_PARSTR( 1, &hStr, NULL ) ) );
   hb_strfree( hStr );
}

HB_FUNC( HWG_GETFILEATTRIBUTES )
{
   void *hStr;
   hb_retnl( ( LONG ) GetFileAttributes( HB_PARSTR( 1, &hStr, NULL ) ) );
   hb_strfree( hStr );
}

HB_FUNC( HWG_SETFILEATTRIBUTES )
{
   void *hStr;
   hb_retl( SetFileAttributes( HB_PARSTR( 1, &hStr, NULL ),
               ( DWORD ) hb_parnl( 2 ) ) );
   hb_strfree( hStr );
}

/* Add by Richard Roesnadi (based on What32) */
// GETCOMPUTERNAME( [@nLengthChar] ) -> cComputerName
HB_FUNC( HWG_GETCOMPUTERNAME )
{
   TCHAR cText[64] = { 0 };
   DWORD nSize = HB_SIZEOFARRAY( cText );
   GetComputerName( cText, &nSize );
   HB_RETSTR( cText );
   hb_stornl( nSize, 1 );
}


// GETUSERNAME( [@nLengthChar] ) -> cUserName
HB_FUNC( HWG_GETUSERNAME )
{
   TCHAR cText[64] = { 0 };
   DWORD nSize = HB_SIZEOFARRAY( cText );
   GetUserName( cText, &nSize );
   HB_RETSTR( cText );
   hb_stornl( nSize, 1 );
}

HB_FUNC( HWG_EDIT1UPDATECTRL )
{
   HWND hChild = ( HWND ) HB_PARHANDLE( 1 );
   HWND hParent = ( HWND ) HB_PARHANDLE( 2 );
   RECT *rect = NULL;

   GetWindowRect( hChild, rect );
   ScreenToClient( hParent, ( LPPOINT ) rect );
   ScreenToClient( hParent, ( ( LPPOINT ) rect ) + 1 );
   InflateRect( rect, -2, -2 );
   InvalidateRect( hParent, rect, TRUE );
   UpdateWindow( hParent );
}

HB_FUNC( HWG_BUTTON1GETSCREENCLIENT )
{
   HWND hChild = ( HWND ) HB_PARHANDLE( 1 );
   HWND hParent = ( HWND ) HB_PARHANDLE( 2 );
   RECT *rect = NULL;

   GetWindowRect( hChild, rect );
   ScreenToClient( hParent, ( LPPOINT ) rect );
   ScreenToClient( hParent, ( ( LPPOINT ) rect ) + 1 );
   hb_itemRelease( hb_itemReturn( Rect2Array( rect ) ) );
}

HB_FUNC( HWG_HEDITEX_CTLCOLOR )
{
   HDC hdc = ( HDC ) HB_PARHANDLE( 1 );
   //UINT h = hb_parni( 2 ) ;
   PHB_ITEM pObject = hb_param( 3, HB_IT_OBJECT );
   PHB_ITEM p, p1, p2, temp;
   LONG i;
   HBRUSH hBrush;
   COLORREF cColor;

   if( !pObject )
   {
      HB_RETHANDLE( GetStockObject( HOLLOW_BRUSH ) );
      SetBkMode( hdc, TRANSPARENT );
      return;
   }

   p = GetObjectVar( pObject, "M_BRUSH" );
   p2 = GetObjectVar( pObject, "M_TEXTCOLOR" );
   cColor = ( COLORREF ) hb_itemGetNL( p2 );
   hBrush = ( HBRUSH ) HB_GETHANDLE( p );

   DeleteObject( hBrush );

   p1 = GetObjectVar( pObject, "M_BACKCOLOR" );
   i = hb_itemGetNL( p1 );
   if( i == -1 )
   {
      hBrush = ( HBRUSH ) GetStockObject( HOLLOW_BRUSH );
      SetBkMode( hdc, TRANSPARENT );
   }
   else
   {
      hBrush = CreateSolidBrush( ( COLORREF ) i );
      SetBkColor( hdc, ( COLORREF ) i );
   }

   temp = HB_PUTHANDLE( NULL, hBrush );
   SetObjectVar( pObject, "_M_BRUSH", temp );
   hb_itemRelease( temp );

   SetTextColor( hdc, cColor );
   HB_RETHANDLE( hBrush );
}

HB_FUNC( HWG_GETKEYBOARDCOUNT )
{
   LPARAM lParam = ( LPARAM ) hb_parnl( 1 );

   hb_retni( ( WORD ) lParam );
}

HB_FUNC( HWG_GETNEXTDLGGROUPITEM )
{
   HB_RETHANDLE( GetNextDlgGroupItem( ( HWND ) HB_PARHANDLE( 1 ),
               ( HWND ) HB_PARHANDLE( 2 ), hb_parl( 3 ) ) );
}

HB_FUNC( HWG_PTRTOULONG )
{
   hb_retnl( HB_ISPOINTER( 1 ) ? ( LONG ) PtrToUlong( hb_parptr( 1 ) ) :
         hb_parnl( 1 ) );
}

HB_FUNC( HWG_ISPTREQ )
{
   hb_retl( HB_PARHANDLE( 1 ) == HB_PARHANDLE( 2 ) );
}

HB_FUNC( HWG_OUTPUTDEBUGSTRING )
{
   void *hStr;
   OutputDebugString( HB_PARSTRDEF( 1, &hStr, NULL ) );
   hb_strfree( hStr );
}

HB_FUNC( HWG_GETSYSTEMMETRICS )
{
   hb_retni( GetSystemMetrics( hb_parni( 1 ) ) );
}

// nando
HB_FUNC( HWG_LASTKEY )
{
   BYTE kbBuffer[256];
   int i;

   GetKeyboardState( kbBuffer );

   for( i = 0; i < 256; i++ )
      if( kbBuffer[i] & 0x80 )
      {
         hb_retni( i );
         return;
      }
   hb_retni( 0 );
}

HB_FUNC( HWG_ISWIN7 )
{
   OSVERSIONINFO ovi;
   ovi.dwOSVersionInfoSize = sizeof ovi;
   ovi.dwMajorVersion = 0;
   ovi.dwMinorVersion = 0;
   GetVersionEx( &ovi );
   hb_retl( ovi.dwMajorVersion >= 6 && ovi.dwMinorVersion == 1 );
}

HB_FUNC( HWG_COLORRGB2N )
{
   hb_retnl( hb_parni( 1 ) + hb_parni( 2 ) * 256 + hb_parni( 3 ) * 65536 );
}

/*
#include <windows.h>
#include <stdio.h>
#include <tchar.h>

HB_FUNC( HWG_PROCESSRUN )
{
    STARTUPINFO si;
    PROCESS_INFORMATION pi;

    ZeroMemory( &si, sizeof(si) );
    si.cb = sizeof(si);
    si.wShowWindow = SW_HIDE;
    si.dwFlags = STARTF_USESHOWWINDOW;

    ZeroMemory( &pi, sizeof(pi) );

    // Start the child process.
    if( !CreateProcess( NULL,   // No module name (use command line)
        hb_parc(1),        // Command line
        NULL,           // Process handle not inheritable
        NULL,           // Thread handle not inheritable
        FALSE,          // Set handle inheritance to FALSE
        CREATE_NEW_CONSOLE,   // No creation flags
        NULL,           // Use parent's environment block
        NULL,           // Use parent's starting directory
        &si,            // Pointer to STARTUPINFO structure
        &pi )           // Pointer to PROCESS_INFORMATION structure
    )
    {
        hb_ret();
        return;
    }

    // Wait until child process exits.
    WaitForSingleObject( pi.hProcess, INFINITE );

    // Close process and thread handles.
    CloseHandle( pi.hProcess );
    CloseHandle( pi.hThread );
    hb_retc( "Ok" );
}
*/

HB_FUNC( HWG_PROCESSRUN )
{
   STARTUPINFO si;
   PROCESS_INFORMATION pi;
   SECURITY_ATTRIBUTES sa;
   HANDLE hOut;
   void * hStr;

   sa.nLength = sizeof(SECURITY_ATTRIBUTES);
   sa.lpSecurityDescriptor = NULL;
   sa.bInheritHandle = TRUE;

   hOut = CreateFile( HB_PARSTR( 1, &hStr, NULL ), GENERIC_WRITE, 0, &sa,
      CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0 );

   hb_strfree( hStr );
   ZeroMemory( &si, sizeof(si) );
   si.cb = sizeof(si);
   si.wShowWindow = SW_HIDE;
   si.dwFlags = STARTF_USESHOWWINDOW | STARTF_USESTDHANDLES;
   si.hStdOutput = si.hStdError = hOut;

   ZeroMemory( &pi, sizeof(pi) );

   // Start the child process.
   if( !CreateProcess( NULL,   // No module name (use command line)
       (LPTSTR)HB_PARSTR( 1, &hStr, NULL ),  // Command line
       NULL,           // Process handle not inheritable
       NULL,           // Thread handle not inheritable
       TRUE,          // Set handle inheritance to FALSE
       CREATE_NEW_CONSOLE,   // No creation flags
       NULL,           // Use parent's environment block
       NULL,           // Use parent's starting directory
       &si,            // Pointer to STARTUPINFO structure
       &pi )           // Pointer to PROCESS_INFORMATION structure
   )
   {
       hb_strfree( hStr );
       hb_ret();
       return;
   }

   hb_strfree( hStr );
   // Wait until child process exits.
   WaitForSingleObject( pi.hProcess, INFINITE );

   // Close process and thread handles.
   CloseHandle( pi.hProcess );
   CloseHandle( pi.hThread );
   CloseHandle( hOut );
   hb_retc( "Ok" );
}

HB_FUNC( HWG_RUNAPP )
{
   if( HB_ISNIL(3) || !hb_parl(3) )
      hb_retni( WinExec( hb_parc( 1 ), (HB_ISNIL(2))? SW_SHOW : ( UINT ) hb_parni( 2 ) ) );
   else
   {
      STARTUPINFO si;
      PROCESS_INFORMATION pi;
      void * hStr;

      ZeroMemory( &si, sizeof(si) );
      si.cb = sizeof(si);
      si.wShowWindow = SW_SHOW;
      si.dwFlags = STARTF_USESHOWWINDOW;
      ZeroMemory( &pi, sizeof(pi) );

      CreateProcess( NULL,   // No module name (use command line)
          (LPTSTR)HB_PARSTR( 1, &hStr, NULL ),  // Command line
          NULL,           // Process handle not inheritable
          NULL,           // Thread handle not inheritable
          FALSE,          // Set handle inheritance to FALSE
          CREATE_NEW_CONSOLE,   // No creation flags
          NULL,           // Use parent's environment block
          NULL,           // Use parent's starting directory
          &si,            // Pointer to STARTUPINFO structure
          &pi );          // Pointer to PROCESS_INFORMATION structure
      hb_strfree( hStr );
   }
}


#if defined( __XHARBOUR__)
BOOL hb_itemEqual( PHB_ITEM pItem1, PHB_ITEM pItem2 )
{
   BOOL fResult = 0;

   if( HB_IS_NUMERIC( pItem1 ) )
   {
      if( HB_IS_NUMINT( pItem1 ) && HB_IS_NUMINT( pItem2 ) )
         fResult = HB_ITEM_GET_NUMINTRAW( pItem1 ) == HB_ITEM_GET_NUMINTRAW( pItem2 );
      else
         fResult = HB_IS_NUMERIC( pItem2 ) &&
                   hb_itemGetND( pItem1 ) == hb_itemGetND( pItem2 );
   }
   else if( HB_IS_STRING( pItem1 ) )
      fResult = HB_IS_STRING( pItem2 ) &&
                pItem1->item.asString.length == pItem2->item.asString.length &&
                memcmp( pItem1->item.asString.value,
                        pItem2->item.asString.value,
                        pItem1->item.asString.length ) == 0;

   else if( HB_IS_NIL( pItem1 ) )
      fResult = HB_IS_NIL( pItem2 );

   else if( HB_IS_DATETIME( pItem1 ) )
      if( HB_IS_TIMEFLAG( pItem1 ) && HB_IS_TIMEFLAG( pItem2 ) )
      fResult = HB_IS_DATETIME( pItem2 ) &&
                pItem1->item.asDate.value == pItem2->item.asDate.value &&
                pItem1->item.asDate.time == pItem2->item.asDate.time;
      else
      fResult = HB_IS_DATE( pItem2 ) &&
                pItem1->item.asDate.value == pItem2->item.asDate.value ;


   else if( HB_IS_LOGICAL( pItem1 ) )
      fResult = HB_IS_LOGICAL( pItem2 ) && ( pItem1->item.asLogical.value ?
                pItem2->item.asLogical.value : ! pItem2->item.asLogical.value );

   else if( HB_IS_ARRAY( pItem1 ) )
      fResult = HB_IS_ARRAY( pItem2 ) &&
                pItem1->item.asArray.value == pItem2->item.asArray.value;

   else if( HB_IS_HASH( pItem1 ) )
      fResult = HB_IS_HASH( pItem2 ) &&
                pItem1->item.asHash.value == pItem2->item.asHash.value;

   else if( HB_IS_POINTER( pItem1 ) )
      fResult = HB_IS_POINTER( pItem2 ) &&
                pItem1->item.asPointer.value == pItem2->item.asPointer.value;

   else if( HB_IS_BLOCK( pItem1 ) )
      fResult = HB_IS_BLOCK( pItem2 ) &&
                pItem1->item.asBlock.value == pItem2->item.asBlock.value;

   return fResult;
}
#endif

HB_FUNC( HWG_GETCENTURY )
{
  HB_BOOL centset = hb_setGetCentury();
  hb_retl(centset);
}


HB_FUNC( HWG_ISWIN10 )
{
   OSVERSIONINFO ovi;
   ovi.dwOSVersionInfoSize = sizeof ovi;
   ovi.dwMajorVersion = 0;
   ovi.dwMinorVersion = 0;
   GetVersionEx( &ovi );
   hb_retl( ovi.dwMajorVersion >= 6 && ovi.dwMinorVersion == 2 );
}

HB_FUNC( HWG_GETWINMAJORVERS )
{
   OSVERSIONINFO ovi;
   ovi.dwOSVersionInfoSize = sizeof ovi;
   ovi.dwMajorVersion = 0;
   ovi.dwMinorVersion = 0;
   GetVersionEx( &ovi );
   hb_retni( ovi.dwMajorVersion );
}

HB_FUNC( HWG_GETWINMINORVERS )
{
   OSVERSIONINFO ovi;
   ovi.dwOSVersionInfoSize = sizeof ovi;
   ovi.dwMajorVersion = 0;
   ovi.dwMinorVersion = 0;
   GetVersionEx( &ovi );
   hb_retni( ovi.dwMinorVersion );
}

HB_FUNC( HWG_ALERT_DISABLECLOSEBUTTON )
{
    DeleteMenu( GetSystemMenu( (HWND) hb_parptr( 1 ), FALSE ), SC_CLOSE, MF_BYCOMMAND );
    DrawMenuBar( (HWND) hb_parptr( 1 ) );
}


HB_FUNC( HWG_ALERT_GETWINDOW )
// Was former static
{
   hb_retptr( (HWND) GetWindow( (HWND) hb_parptr(1), (UINT) hb_parni( 2 ) ) );
}

/*
* ============================================
* FUNCTION hwg_STOD
* Extra implementation of STOD(),
* it is a Clipper tools function.
* For compatibilty purposes.
* Parameter 1: Date String
* in ANSI-Format YYYYMMDD.
* Result value is independant from
* SET DATE and SET CENTURY settings.
* Sample Call:
* ddate := hwg_STOD("20201108")
* ============================================
*/



HB_FUNC( HWG_STOD )
{
   PHB_ITEM pDateString = hb_param( 1, HB_IT_STRING );

   hb_retds( hb_itemGetCLen( pDateString ) >= 7 ? hb_itemGetCPtr( pDateString ) : NULL );
}

int hwg_hexbin(int cha)
/* converts single hex char to int, returns -1 , if not in range
   returns 0 - 15 (dec) , only a half byte */
{
    char gross;
    int o;

    gross = toupper(cha);
    switch (gross)
    {
     case 48:  /* 0 */
     o = 0;
     break;
     case 49:  /* 1 */
     o = 1;
     break;
     case 50:  /* 2 */
     o = 2;
     break;	
     case 51:  /* 3 */
     o = 3;
     break;
     case 52:  /* 4 */
     o = 4;
     break;
     case 53:  /* 5 */
     o = 5;
     break;
     case 54:  /* 6 */
     o = 6;
     break;	
     case 55:  /* 7 */
     o = 7	 ;
     break;
     case 56:  /* 8 */
     o = 8;
     break;	
     case 57:  /* 9 */
     o = 9;
     break;
     case 65:  /* A */
     o = 10;
     break;
     case 66:  /* B */
     o = 11;
     break;
     case 67:  /* C */
     o = 12;
     break;	
     case 68:  /* D */
     o = 13;
     break;
     case 69:  /* E */
     o = 14;
     break;	
     case 70:  /* F */
     o = 15;
     break;
     default:
     o = -1;
    }
    return o;
}

/*
   hwg_Bin2DC(cbin,nlen,ndec)
*/

HB_FUNC( HWG_BIN2DC )
{

    double pbyNumber;
    int i;
    unsigned char o;
    unsigned char bu[8];     /* Buffer with binary contents of double value */
    unsigned char szHex[17]; /* The hex string from parameter 1 + null byte*/


    int p;
    int c;      /* char with int value hex from hex */
    int od;     /* odd even sign / gerade - ungerade */

    /* For Borland C the variables must declare extra */
    HB_USHORT uiWidth;
    HB_USHORT uiDec;
    const char *name;

  /* init vars */

  pbyNumber = 0;

    szHex[0] = '\0';
    szHex[1] = '\0';
    szHex[2] = '\0';
    szHex[3] = '\0';
    szHex[4] = '\0';
    szHex[5] = '\0';
    szHex[6] = '\0';
    szHex[7] = '\0';
    szHex[8] = '\0';
    szHex[9] = '\0';
    szHex[10] = '\0';
    szHex[11] = '\0';
    szHex[12] = '\0';
    szHex[13] = '\0';
    szHex[14] = '\0';
    szHex[15] = '\0';
    szHex[16] = '\0';


    p = 0;
    c = 0;
    od = 0;

    // Internal I2BIN for Len

    uiWidth = ( HB_USHORT ) hb_parni( 2 );

    // Internal I2BIN for Dec

    uiDec = ( HB_USHORT ) hb_parni( 3 );


    name = hb_parc( 1 );

    // hwg_writelog(NULL,name);

    memcpy(&szHex,name,16);

    szHex[16] = '\0';

    // hwg_writelog(NULL,szHex);

    /* Convert hex to bin */

    for ( i = 0 ; i < 16; i++ )
     {

          c = hwg_hexbin(szHex[i]);
          /* ignore, if not in 0 ... 1, A ... F */
          if ( c  != -1 )
          {
           /* must be a pair of char,
              other values between the pairs of hex values are ignored */
            if ( od == 1 )
            {
                od = 0;
            }
            else
            {
                od = 1;
            }
            /* 1. Halbbyte zwischenspeichern / Store first half byte */
            if ( od == 1)
            {
              p = c;
            }
            else
            /* 2. Halbbyte verarbeiten, ganzes Byte ausspeichern
                / Process second half byte and store full byte */
            {
              p = ( p * 16 ) + c;
              o = (unsigned char) p;
              bu[ i / 2 ] = o;

/* Display some debug info */
//             printf("i=%d ", i);
//             printf("%d ", p);
//             printf("%s", " ");
//             printf("%c", o);
//             printf("%s", " ");
// 80  P 69  E 82  R 84  T 251  ยน 33  ! 9     64
// 50    45    52    54    FB     21    09    40

            }
          }
        }

    // hwg_writelog(NULL,szHex);

    /* Convert buffer to double */

    memcpy(&pbyNumber,bu,sizeof(pbyNumber));

    /* Return double value as type N */

    hb_retndlen( pbyNumber , uiWidth , uiDec );

}

static void GetFileMtimeU(const char * filePath)
{
/* Format: YYYYMMDD-HH:MM:SS  for example: 20211204-20:05:42 l= 17 + NULL byte */
 struct stat attrib;
 char date[18];
 stat (filePath, &attrib);

 strftime(date, sizeof(date) , "%Y%m%d-%H:%M:%S", gmtime(&(attrib.st_mtime)));
 hb_retc(date);
}

static void GetFileMtime(const char * filePath)
{
/* Format: YYYYMMDD-HH:MM:SS  for example: 20211204-20:05:42 l= 17 + NULL byte */
 struct stat attrib;
 char date[18];
 stat (filePath, &attrib);
 strftime(date, sizeof(date) , "%Y%m%d-%H:%M:%S", localtime(&(attrib.st_mtime)));
 hb_retc(date);
}


HB_FUNC( HWG_FILEMODTIMEU )
{
 GetFileMtimeU( ( const char * ) hb_parc(1) );
}


HB_FUNC( HWG_FILEMODTIME )
{
 GetFileMtime( ( const char * ) hb_parc(1) );
}


/* hwg_Toggle_HalfByte_C(n) */
HB_FUNC( HWG_TOGGLE_HALFBYTE_C )
{
 int i,k,l;

 i = hb_parni( 1 );
 k = i & 15;
 l = i & 240;

 k = k << 4;
 l = l >> 4;

 hb_retni( l | k );

}


HB_FUNC( HWG_GUITYPE )
{
  hb_retc( "WinAPI" );
}

/* ========= EOF of misc.c ============ */
