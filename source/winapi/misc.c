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

/* FIXED: Added VersionHelpers for modern Windows version detection */
#include <versionhelpers.h>

#include "hbmath.h"
#include "hbapi.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbset.h"

/* REMOVED: Obsolete header
 * #include "missing.h"
 */

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

/*=============================================================================
 * HWG_SETDLGRESULT()
 * Sets dialog result
 *===========================================================================*/
HB_FUNC( HWG_SETDLGRESULT )
{
   SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ), DWLP_MSGRESULT,
         hb_parni( 2 ) );
}

/*=============================================================================
 * HWG_SETCAPTURE()
 * Sets mouse capture
 *===========================================================================*/
HB_FUNC( HWG_SETCAPTURE )
{
   HB_RETHANDLE( SetCapture( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_RELEASECAPTURE()
 * Releases mouse capture
 *===========================================================================*/
HB_FUNC( HWG_RELEASECAPTURE )
{
   hb_retl( ReleaseCapture(  ) );
}

/*=============================================================================
 * HWG_COPYSTRINGTOCLIPBOARD()
 * Copies a string to the clipboard
 *===========================================================================*/
HB_FUNC( HWG_COPYSTRINGTOCLIPBOARD )
{
   if( OpenClipboard( GetActiveWindow(  ) ) )
   {
      HGLOBAL hglbCopy;
      LPTSTR lptstrCopy;
      void *hStr;
      HB_SIZE nLen;
      LPCTSTR lpStr;

      EmptyClipboard(  );

      /* FIXED: HB_PARSTRDEF -> HB_PARSTR for Unicode support */
      lpStr = HB_PARSTR( 1, &hStr, &nLen );
      hglbCopy = GlobalAlloc( GMEM_DDESHARE, ( nLen + 1 ) * sizeof( TCHAR ) );
      if( hglbCopy != NULL )
      {
         lptstrCopy = ( LPTSTR ) GlobalLock( hglbCopy );
         memcpy( lptstrCopy, lpStr, nLen * sizeof( TCHAR ) );
         lptstrCopy[nLen] = 0;
         GlobalUnlock( hglbCopy );
         hb_strfree( hStr );

#ifdef UNICODE
         SetClipboardData( CF_UNICODETEXT, hglbCopy );
#else
         SetClipboardData( CF_TEXT, hglbCopy );
#endif
      }
      CloseClipboard(  );
   }
}

/*=============================================================================
 * HWG_GETCLIPBOARDTEXT()
 * Retrieves text from the clipboard
 *===========================================================================*/
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

/*=============================================================================
 * HWG_GETSTOCKOBJECT()
 * Gets a stock GDI object
 *===========================================================================*/
HB_FUNC( HWG_GETSTOCKOBJECT )
{
   HB_RETHANDLE( GetStockObject( hb_parni( 1 ) ) );
}

/*=============================================================================
 * HWG_LOWORD()
 * Extracts low-order word from a 32-bit value
 *===========================================================================*/
HB_FUNC( HWG_LOWORD )
{
   hb_retni( ( int ) ( ( HB_ISPOINTER( 1 ) ?
   PtrToUlong( hb_parptr( 1 ) ) :
                              ( ULONG ) hb_parnl( 1 ) ) & 0xFFFF ) );
}

/*=============================================================================
 * HWG_HIWORD()
 * Extracts high-order word from a 32-bit value
 *===========================================================================*/
HB_FUNC( HWG_HIWORD )
{
  ULONG ulValue;

  if( HB_ISPOINTER( 1 ) )
    ulValue = ( ULONG ) ( HB_PTRUINT ) hb_parptr( 1 );
  else
    ulValue = ( ULONG ) hb_parnint( 1 );

  hb_retni( ( int ) ( ( ulValue >> 16 ) & 0xFFFF ) );
}

/*=============================================================================
 * HWG_BITOR()
 * Bitwise OR
 *===========================================================================*/
HB_FUNC( HWG_BITOR )
{
  hb_retnint( hb_parnint( 1 ) | hb_parnint( 2 ) );
}

/*=============================================================================
 * HWG_BITOR_INT()
 * Bitwise OR (int)
 *===========================================================================*/
HB_FUNC( HWG_BITOR_INT )
{
  hb_retni( hb_parni( 1 ) | hb_parni( 2 ) );
}

/*=============================================================================
 * HWG_BITAND()
 * Bitwise AND
 *===========================================================================*/
HB_FUNC( HWG_BITAND )
{
  hb_retnint( hb_parnint( 1 ) & hb_parnint( 2 ) );
}

/*=============================================================================
 * HWG_BITANDINVERSE()
 * Bitwise AND with inverse
 *===========================================================================*/
HB_FUNC( HWG_BITANDINVERSE )
{
  hb_retnint( hb_parnint( 1 ) & ( ~hb_parnint( 2 ) ) );
}

/*=============================================================================
 * HWG_SETBIT()
 * Sets or clears a bit in a numeric value
 *===========================================================================*/
HB_FUNC( HWG_SETBIT )
{
  int nBit = hb_parni( 2 );

  if( nBit < 1 || nBit > ( int ) ( sizeof( HB_MAXINT ) * 8 ) )
  {
    hb_retnint( hb_parnint( 1 ) );
    return;
  }

  if( hb_pcount() < 3 || hb_parni( 3 ) )
    hb_retnint( hb_parnint( 1 ) | ( ( HB_MAXINT ) 1 << ( nBit - 1 ) ) );
  else
    hb_retnint( hb_parnint( 1 ) & ~( ( HB_MAXINT ) 1 << ( nBit - 1 ) ) );
}

/*=============================================================================
 * HWG_SETBITBYTE()
 * Sets or clears a bit in a byte
 *===========================================================================*/
HB_FUNC( HWG_SETBITBYTE )
{
  int para3;
  int nBit;

  if( hb_pcount() < 3 )
  {
    hb_retni( hb_parni( 1 ) );
    return;
  }

  para3 = hb_parni( 3 );
  if( para3 < 0 || para3 > 1 )
  {
    hb_retni( hb_parni( 1 ) );
    return;
  }

  nBit = hb_parni( 2 );
  if( nBit < 1 || nBit > ( int ) ( sizeof( int ) * 8 ) )
  {
    hb_retni( hb_parni( 1 ) );
    return;
  }

  if( para3 == 1 )
    hb_retni( hb_parni( 1 ) | ( 1 << ( nBit - 1 ) ) );
  else
    hb_retni( hb_parni( 1 ) & ~( 1 << ( nBit - 1 ) ) );
}

/*=============================================================================
 * HWG_CHECKBIT()
 * Checks if a bit is set
 *===========================================================================*/
HB_FUNC( HWG_CHECKBIT )
{
  int nBit = hb_parni( 2 );

  if( nBit < 1 || nBit > ( int ) ( sizeof( HB_MAXINT ) * 8 ) )
  {
    hb_retl( HB_FALSE );
    return;
  }

  hb_retl( hb_parnint( 1 ) & ( ( HB_MAXINT ) 1 << ( nBit - 1 ) ) );
}

/*=============================================================================
 * HWG_SIN()
 * Sine function
 *===========================================================================*/
HB_FUNC( HWG_SIN )
{
   hb_retnd( sin( hb_parnd( 1 ) ) );
}

/*=============================================================================
 * HWG_COS()
 * Cosine function
 *===========================================================================*/
HB_FUNC( HWG_COS )
{
   hb_retnd( cos( hb_parnd( 1 ) ) );
}

/*=============================================================================
 * HWG_CLIENTTOSCREEN()
 * Converts client coordinates to screen coordinates
 *===========================================================================*/
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

/*=============================================================================
 * HWG_SCREENTOCLIENT()
 * Converts screen coordinates to client coordinates
 *===========================================================================*/
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

/*=============================================================================
 * HWG_GETCURSORPOS()
 * Gets cursor position
 *===========================================================================*/
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

/*=============================================================================
 * HWG_SETCURSORPOS()
 * Sets cursor position
 *===========================================================================*/
HB_FUNC( HWG_SETCURSORPOS )
{
   int x, y;

   x = hb_parni( 1 );
   y = hb_parni( 2 );

   SetCursorPos( x, y );
}

/*=============================================================================
 * HWG_GETCURRENTDIR()
 * Gets current directory
 *===========================================================================*/
HB_FUNC( HWG_GETCURRENTDIR )
{
   TCHAR buffer[HB_PATH_MAX];

   GetCurrentDirectory( HB_PATH_MAX, buffer );
   HB_RETSTR( buffer );
}

/*=============================================================================
 * HWG_WINEXEC()
 * Executes a command (using CreateProcess)
 *===========================================================================*/
HB_FUNC( HWG_WINEXEC )
{
   void *hStr;
   LPCTSTR lpCmd = HB_PARSTR( 1, &hStr, NULL );
   STARTUPINFO si;
   PROCESS_INFORMATION pi;
   BOOL bResult;

   ZeroMemory( &si, sizeof(si) );
   si.cb = sizeof(si);
   si.dwFlags = STARTF_USESHOWWINDOW;
   si.wShowWindow = ( hb_parni(2) == SW_HIDE ) ? SW_HIDE : SW_SHOWNORMAL;

   /* FIXED: WinExec replaced with CreateProcess */
   bResult = CreateProcess( NULL, (LPTSTR)lpCmd, NULL, NULL, FALSE,
                            CREATE_NEW_CONSOLE, NULL, NULL, &si, &pi );

   if( bResult )
   {
      CloseHandle( pi.hProcess );
      CloseHandle( pi.hThread );
   }

   hb_retni( bResult ? 33 : 0 );   /* 33 = success (WinExec returns >31) */
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_GETKEYBOARDSTATE()
 * Gets keyboard state
 *===========================================================================*/
HB_FUNC( HWG_GETKEYBOARDSTATE )
{
   BYTE lpbKeyState[256];
   GetKeyboardState( lpbKeyState );
   lpbKeyState[255] = '\0';
   hb_retclen( ( char * ) lpbKeyState, 255 );
}

/*=============================================================================
 * HWG_GETKEYSTATE()
 * Gets key state
 *===========================================================================*/
HB_FUNC( HWG_GETKEYSTATE )
{
   hb_retni( GetKeyState( hb_parni( 1 ) ) );
}

/*=============================================================================
 * HWG_GETKEYNAMETEXT()
 * Gets key name text
 *===========================================================================*/
HB_FUNC( HWG_GETKEYNAMETEXT )
{
   TCHAR cText[MAX_PATH];
   int iRet = GetKeyNameText( hb_parnl( 1 ), cText, MAX_PATH );

   if( iRet )
      HB_RETSTRLEN( cText, iRet );
}

/*=============================================================================
 * HWG_ACTIVATEKEYBOARDLAYOUT()
 * Activates keyboard layout
 *===========================================================================*/
HB_FUNC( HWG_ACTIVATEKEYBOARDLAYOUT )
{
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

/*=============================================================================
 * HWG_PTS2PIX()
 * Converts points to pixels
 *===========================================================================*/
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

/* Functions Contributed By Luiz Rafael Culik Guimaraes( culikr@uol.com.br) */

/*=============================================================================
 * HWG_GETWINDOWSDIR()
 * Gets Windows directory
 *===========================================================================*/
HB_FUNC( HWG_GETWINDOWSDIR )
{
   TCHAR szBuffer[MAX_PATH + 1] = { 0 };

   GetWindowsDirectory( szBuffer, MAX_PATH );
   HB_RETSTR( szBuffer );
}

/*=============================================================================
 * HWG_GETSYSTEMDIR()
 * Gets System directory
 *===========================================================================*/
HB_FUNC( HWG_GETSYSTEMDIR )
{
   TCHAR szBuffer[MAX_PATH + 1] = { 0 };

   GetSystemDirectory( szBuffer, MAX_PATH );
   HB_RETSTR( szBuffer );
}

/*=============================================================================
 * HWG_GETTEMPDIR()
 * Gets Temp directory
 *===========================================================================*/
HB_FUNC( HWG_GETTEMPDIR )
{
   TCHAR szBuffer[MAX_PATH + 1] = { 0 };

   GetTempPath( MAX_PATH, szBuffer );
   HB_RETSTR( szBuffer );
}

/*=============================================================================
 * HWG_POSTQUITMESSAGE()
 * Posts quit message
 *===========================================================================*/
HB_FUNC( HWG_POSTQUITMESSAGE )
{
   PostQuitMessage( hb_parni( 1 ) );
}

/*=============================================================================
 * HWG_SHELLABOUT()
 * Displays ShellAbout dialog
 *===========================================================================*/
HB_FUNC( HWG_SHELLABOUT )
{
   void *hStr1, *hStr2;

   /* FIXED: HB_PARSTRDEF -> HB_PARSTR for Unicode support */
   hb_retni( ShellAbout( 0,
               HB_PARSTR( 1, &hStr1, NULL ),
               HB_PARSTR( 2, &hStr2, NULL ),
               ( HB_ISNIL( 3 ) ? NULL : ( HICON ) HB_PARHANDLE( 3 ) ) ) );
   hb_strfree( hStr1 );
   hb_strfree( hStr2 );
}

/*=============================================================================
 * HWG_GETDESKTOPWIDTH()
 * Gets desktop width
 *===========================================================================*/
HB_FUNC( HWG_GETDESKTOPWIDTH )
{
   hb_retni( GetSystemMetrics( SM_CXSCREEN ) );
}

/*=============================================================================
 * HWG_GETDESKTOPHEIGHT()
 * Gets desktop height
 *===========================================================================*/
HB_FUNC( HWG_GETDESKTOPHEIGHT )
{
   hb_retni( GetSystemMetrics( SM_CYSCREEN ) );
}

/*=============================================================================
 * HWG_GETWORKAREA()
 * Gets work area rectangle
 *===========================================================================*/
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

/*=============================================================================
 * HWG_GETHELPDATA()
 * Gets help data handle
 *===========================================================================*/
HB_FUNC( HWG_GETHELPDATA )
{
   HB_RETHANDLE( ( ( HELPINFO FAR * ) HB_PARHANDLE( 1 ) )->hItemHandle );
}

/*=============================================================================
 * HWG_WINHELP()
 * Displays Windows Help
 *===========================================================================*/
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

/*=============================================================================
 * HWG_GETNEXTDLGTABITEM()
 * Gets next tab item
 *===========================================================================*/
HB_FUNC( HWG_GETNEXTDLGTABITEM )
{
   HB_RETHANDLE( GetNextDlgTabItem( ( HWND ) HB_PARHANDLE( 1 ),
               ( HWND ) HB_PARHANDLE( 2 ), hb_parl( 3 ) ) );
}

/*=============================================================================
 * HWG_SLEEP()
 * Sleep for specified milliseconds
 *===========================================================================*/
HB_FUNC( HWG_SLEEP )
{
   if( hb_parinfo( 1 ) )
      Sleep( hb_parnl( 1 ) );
}

/*=============================================================================
 * HWG_KEYB_EVENT()
 * Simulates keyboard events
 *===========================================================================*/
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

/*=============================================================================
 * HWG_SETSCROLLINFO()
 * Sets scroll info
 *===========================================================================*/
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

   SetScrollInfo( ( HWND ) HB_PARHANDLE( 1 ),
         hb_parni( 2 ),
         &si, hb_parni( 3 ) );
}

/*=============================================================================
 * HWG_GETSCROLLRANGE()
 * Gets scroll range
 *===========================================================================*/
HB_FUNC( HWG_GETSCROLLRANGE )
{
   int MinPos, MaxPos;

   GetScrollRange( ( HWND ) HB_PARHANDLE( 1 ),
         hb_parni( 2 ),
         &MinPos,
         &MaxPos );
   if( hb_pcount(  ) > 2 )
   {
      hb_storni( MinPos, 3 );
      hb_storni( MaxPos, 4 );
   }
   hb_retni( MaxPos - MinPos );
}

/*=============================================================================
 * HWG_SETSCROLLRANGE()
 * Sets scroll range
 *===========================================================================*/
HB_FUNC( HWG_SETSCROLLRANGE )
{
   hb_retl( SetScrollRange( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ),
               hb_parni( 3 ), hb_parni( 4 ), hb_parl( 5 ) ) );
}

/*=============================================================================
 * HWG_GETSCROLLPOS()
 * Gets scroll position
 *===========================================================================*/
HB_FUNC( HWG_GETSCROLLPOS )
{
   hb_retni( GetScrollPos( ( HWND ) HB_PARHANDLE( 1 ),
               hb_parni( 2 ) ) );
}

/*=============================================================================
 * HWG_SETSCROLLPOS()
 * Sets scroll position
 *===========================================================================*/
HB_FUNC( HWG_SETSCROLLPOS )
{
   SetScrollPos( ( HWND ) HB_PARHANDLE( 1 ),
         hb_parni( 2 ),
         hb_parni( 3 ), TRUE );
}

/*=============================================================================
 * HWG_SHOWSCROLLBAR()
 * Shows or hides scroll bar
 *===========================================================================*/
HB_FUNC( HWG_SHOWSCROLLBAR )
{
   ShowScrollBar( ( HWND ) HB_PARHANDLE( 1 ),
         hb_parni( 2 ),
         hb_parl( 3 ) );
}

/*=============================================================================
 * HWG_SCROLLWINDOW()
 * Scrolls window
 *===========================================================================*/
HB_FUNC( HWG_SCROLLWINDOW )
{
   ScrollWindow( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ),
         NULL, NULL );
}

/*=============================================================================
 * HWG_ISCAPSLOCKACTIVE()
 * Checks if Caps Lock is active
 *===========================================================================*/
HB_FUNC( HWG_ISCAPSLOCKACTIVE )
{
   hb_retl( GetKeyState( VK_CAPITAL ) );
}

/*=============================================================================
 * HWG_ISNUMLOCKACTIVE()
 * Checks if Num Lock is active
 *===========================================================================*/
HB_FUNC( HWG_ISNUMLOCKACTIVE )
{
   hb_retl( GetKeyState( VK_NUMLOCK ) );
}

/*=============================================================================
 * HWG_ISSCROLLLOCKACTIVE()
 * Checks if Scroll Lock is active
 *===========================================================================*/
HB_FUNC( HWG_ISSCROLLLOCKACTIVE )
{
   hb_retl( GetKeyState( VK_SCROLL ) );
}

/* Added By Sandro Freire sandrorrfreire_nospam_yahoo.com.br*/

/*=============================================================================
 * HWG_CREATEDIRECTORY()
 * Creates a directory
 *===========================================================================*/
HB_FUNC( HWG_CREATEDIRECTORY )
{
   void *hStr;
   CreateDirectory( HB_PARSTR( 1, &hStr, NULL ), NULL );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_REMOVEDIRECTORY()
 * Removes a directory
 *===========================================================================*/
HB_FUNC( HWG_REMOVEDIRECTORY )
{
   void *hStr;
   hb_retl( RemoveDirectory( HB_PARSTR( 1, &hStr, NULL ) ) );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_SETCURRENTDIRECTORY()
 * Sets current directory
 *===========================================================================*/
HB_FUNC( HWG_SETCURRENTDIRECTORY )
{
   void *hStr;
   SetCurrentDirectory( HB_PARSTR( 1, &hStr, NULL ) );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_DELETEFILE()
 * Deletes a file
 *===========================================================================*/
HB_FUNC( HWG_DELETEFILE )
{
   void *hStr;
   hb_retl( DeleteFile( HB_PARSTR( 1, &hStr, NULL ) ) );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_GETFILEATTRIBUTES()
 * Gets file attributes
 *===========================================================================*/
HB_FUNC( HWG_GETFILEATTRIBUTES )
{
   void *hStr;
   hb_retnl( ( LONG ) GetFileAttributes( HB_PARSTR( 1, &hStr, NULL ) ) );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_SETFILEATTRIBUTES()
 * Sets file attributes
 *===========================================================================*/
HB_FUNC( HWG_SETFILEATTRIBUTES )
{
   void *hStr;
   hb_retl( SetFileAttributes( HB_PARSTR( 1, &hStr, NULL ),
               ( DWORD ) hb_parnl( 2 ) ) );
   hb_strfree( hStr );
}

/* Add by Richard Roesnadi (based on What32) */

/*=============================================================================
 * HWG_GETCOMPUTERNAME()
 * Gets computer name
 *===========================================================================*/
HB_FUNC( HWG_GETCOMPUTERNAME )
{
   TCHAR cText[64] = { 0 };
   DWORD nSize = HB_SIZEOFARRAY( cText );
   GetComputerName( cText, &nSize );
   HB_RETSTR( cText );
   hb_stornl( nSize, 1 );
}

/*=============================================================================
 * HWG_GETUSERNAME()
 * Gets user name
 *===========================================================================*/
HB_FUNC( HWG_GETUSERNAME )
{
   TCHAR cText[64] = { 0 };
   DWORD nSize = HB_SIZEOFARRAY( cText );
   GetUserName( cText, &nSize );
   HB_RETSTR( cText );
   hb_stornl( nSize, 1 );
}

/* FIXED: Corrected RECT pointer usage */
HB_FUNC( HWG_EDIT1UPDATECTRL )
{
   HWND hChild = ( HWND ) HB_PARHANDLE( 1 );
   HWND hParent = ( HWND ) HB_PARHANDLE( 2 );
   RECT rect;   // FIXED: Stack variable instead of NULL pointer

   GetWindowRect( hChild, &rect );
   ScreenToClient( hParent, ( LPPOINT ) &rect );
   ScreenToClient( hParent, ( ( LPPOINT ) &rect ) + 1 );
   InflateRect( &rect, -2, -2 );
   InvalidateRect( hParent, &rect, TRUE );
   UpdateWindow( hParent );
}

/* FIXED: Corrected RECT pointer usage */
HB_FUNC( HWG_BUTTON1GETSCREENCLIENT )
{
   HWND hChild = ( HWND ) HB_PARHANDLE( 1 );
   HWND hParent = ( HWND ) HB_PARHANDLE( 2 );
   RECT rect;   // FIXED: Stack variable instead of NULL pointer

   GetWindowRect( hChild, &rect );
   ScreenToClient( hParent, ( LPPOINT ) &rect );
   ScreenToClient( hParent, ( ( LPPOINT ) &rect ) + 1 );
   hb_itemRelease( hb_itemReturn( Rect2Array( &rect ) ) );
}

/* FIXED: Added stock brush check */
HB_FUNC( HWG_HEDITEX_CTLCOLOR )
{
   HDC hdc = ( HDC ) HB_PARHANDLE( 1 );
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

   /* FIXED: Only delete if not a stock brush */
   if( hBrush && !( (ULONG_PTR)hBrush >= 0x80000000 ) )
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

/*=============================================================================
 * HWG_GETKEYBOARDCOUNT()
 * Gets keyboard count from lParam
 *===========================================================================*/
HB_FUNC( HWG_GETKEYBOARDCOUNT )
{
   LPARAM lParam = ( LPARAM ) hb_parnl( 1 );

   hb_retni( ( WORD ) lParam );
}

/*=============================================================================
 * HWG_GETNEXTDLGGROUPITEM()
 * Gets next dialog group item
 *===========================================================================*/
HB_FUNC( HWG_GETNEXTDLGGROUPITEM )
{
   HB_RETHANDLE( GetNextDlgGroupItem( ( HWND ) HB_PARHANDLE( 1 ),
               ( HWND ) HB_PARHANDLE( 2 ), hb_parl( 3 ) ) );
}

/*=============================================================================
 * HWG_PTRTOULONG()
 * Converts pointer to unsigned long
 *===========================================================================*/
HB_FUNC( HWG_PTRTOULONG )
{
  if( HB_ISPOINTER( 1 ) )
  {
    hb_retnint( ( HB_MAXINT ) ( HB_PTRUINT ) hb_parptr( 1 ) );
  }
  else
  {
    hb_retnint( ( HB_MAXINT ) hb_parnint( 1 ) );
  }
}

/*=============================================================================
 * HWG_ISPTREQ()
 * Compares two handles for equality
 *===========================================================================*/
HB_FUNC( HWG_ISPTREQ )
{
   hb_retl( HB_PARHANDLE( 1 ) == HB_PARHANDLE( 2 ) );
}

/*=============================================================================
 * HWG_OUTPUTDEBUGSTRING()
 * Outputs debug string
 *===========================================================================*/
HB_FUNC( HWG_OUTPUTDEBUGSTRING )
{
   void *hStr;
   /* FIXED: HB_PARSTRDEF -> HB_PARSTR for Unicode support */
   OutputDebugString( HB_PARSTR( 1, &hStr, NULL ) );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_GETSYSTEMMETRICS()
 * Gets system metrics
 *===========================================================================*/
HB_FUNC( HWG_GETSYSTEMMETRICS )
{
   hb_retni( GetSystemMetrics( hb_parni( 1 ) ) );
}

/*=============================================================================
 * HWG_LASTKEY()
 * Gets last key pressed
 *===========================================================================*/
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

/*=============================================================================
 * HWG_ISWIN7()
 * Checks if running on Windows 7 or later
 *===========================================================================*/
HB_FUNC( HWG_ISWIN7 )
{
   hb_retl( IsWindows7OrGreater() );
}

/*=============================================================================
 * HWG_ISWIN10()
 * Checks if running on Windows 10 or later
 *===========================================================================*/
HB_FUNC( HWG_ISWIN10 )
{
   hb_retl( IsWindows10OrGreater() );
}

/*=============================================================================
 * HWG_GETWINMAJORVERS()
 * Gets Windows major version
 *===========================================================================*/
HB_FUNC( HWG_GETWINMAJORVERS )
{
   OSVERSIONINFOEX ovi;
   ovi.dwOSVersionInfoSize = sizeof(ovi);
   ovi.dwMajorVersion = 0;
   GetVersionEx( (OSVERSIONINFO*)&ovi );
   hb_retni( ovi.dwMajorVersion );
}

/*=============================================================================
 * HWG_GETWINMINORVERS()
 * Gets Windows minor version
 *===========================================================================*/
HB_FUNC( HWG_GETWINMINORVERS )
{
   OSVERSIONINFOEX ovi;
   ovi.dwOSVersionInfoSize = sizeof(ovi);
   ovi.dwMinorVersion = 0;
   GetVersionEx( (OSVERSIONINFO*)&ovi );
   hb_retni( ovi.dwMinorVersion );
}

/*=============================================================================
 * HWG_COLORRGB2N()
 * Converts RGB to numeric color
 *===========================================================================*/
HB_FUNC( HWG_COLORRGB2N )
{
   hb_retnl( hb_parni( 1 ) + hb_parni( 2 ) * 256 + hb_parni( 3 ) * 65536 );
}

/*=============================================================================
 * HWG_PROCESSRUN()
 * Runs a process and captures output
 *===========================================================================*/
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

   /* FIXED: HB_PARSTR for Unicode support */
   LPCTSTR lpFileName = HB_PARSTR( 1, &hStr, NULL );
   hOut = CreateFile( lpFileName, GENERIC_WRITE, 0, &sa,
      CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0 );

   hb_strfree( hStr );
   ZeroMemory( &si, sizeof(si) );
   si.cb = sizeof(si);
   si.wShowWindow = SW_HIDE;
   si.dwFlags = STARTF_USESHOWWINDOW | STARTF_USESTDHANDLES;
   si.hStdOutput = si.hStdError = hOut;

   ZeroMemory( &pi, sizeof(pi) );

   /* FIXED: HB_PARSTR for Unicode support and proper cast */
   LPCTSTR lpCmd = HB_PARSTR( 1, &hStr, NULL );
   if( !CreateProcess( NULL, (LPTSTR)lpCmd, NULL, NULL, TRUE,
       CREATE_NEW_CONSOLE, NULL, NULL, &si, &pi ) )
   {
       hb_strfree( hStr );
       hb_ret();
       return;
   }

   hb_strfree( hStr );
   WaitForSingleObject( pi.hProcess, INFINITE );

   CloseHandle( pi.hProcess );
   CloseHandle( pi.hThread );
   CloseHandle( hOut );
   hb_retc( "Ok" );
}

/*=============================================================================
 * HWG_RUNAPP()
 * Runs an application
 *===========================================================================*/
HB_FUNC( HWG_RUNAPP )
{
   void * hStr;
   LPCTSTR lpCmd = HB_PARSTR( 1, &hStr, NULL );

   if( HB_ISNIL(3) || !hb_parl(3) )
   {
      /* FIXED: WinExec replaced with CreateProcess */
      STARTUPINFO si;
      PROCESS_INFORMATION pi;
      BOOL bResult;

      ZeroMemory( &si, sizeof(si) );
      si.cb = sizeof(si);
      si.dwFlags = STARTF_USESHOWWINDOW;
      si.wShowWindow = (HB_ISNIL(2)) ? SW_SHOW : (UINT) hb_parni(2);

      bResult = CreateProcess( NULL, (LPTSTR)lpCmd, NULL, NULL, FALSE,
                                CREATE_NEW_CONSOLE, NULL, NULL, &si, &pi );

      if( bResult )
      {
         CloseHandle( pi.hProcess );
         CloseHandle( pi.hThread );
      }

      hb_retni( bResult ? 33 : 0 );
   }
   else
   {
      STARTUPINFO si;
      PROCESS_INFORMATION pi;

      ZeroMemory( &si, sizeof(si) );
      si.cb = sizeof(si);
      si.wShowWindow = SW_SHOW;
      si.dwFlags = STARTF_USESHOWWINDOW;
      ZeroMemory( &pi, sizeof(pi) );

      CreateProcess( NULL, (LPTSTR)lpCmd, NULL, NULL, FALSE,
                      CREATE_NEW_CONSOLE, NULL, NULL, &si, &pi );
   }

   hb_strfree( hStr );
}

/*=============================================================================
 * hb_itemEqual() - for xHarbour compatibility
 *===========================================================================*/
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

/*=============================================================================
 * HWG_GETCENTURY()
 * Gets century setting
 *===========================================================================*/
HB_FUNC( HWG_GETCENTURY )
{
  HB_BOOL centset = hb_setGetCentury();
  hb_retl(centset);
}

/*=============================================================================
 * HWG_ALERT_DISABLECLOSEBUTTON()
 * Disables close button
 *===========================================================================*/
HB_FUNC( HWG_ALERT_DISABLECLOSEBUTTON )
{
    DeleteMenu( GetSystemMenu( (HWND) hb_parptr( 1 ), FALSE ), SC_CLOSE, MF_BYCOMMAND );
    DrawMenuBar( (HWND) hb_parptr( 1 ) );
}

/*=============================================================================
 * HWG_ALERT_GETWINDOW()
 * Gets window
 *===========================================================================*/
HB_FUNC( HWG_ALERT_GETWINDOW )
{
   hb_retptr( (HWND) GetWindow( (HWND) hb_parptr(1), (UINT) hb_parni( 2 ) ) );
}

/*=============================================================================
 * HWG_STOD()
 * Converts string to date (ANSI format YYYYMMDD)
 *===========================================================================*/
HB_FUNC( HWG_STOD )
{
   PHB_ITEM pDateString = hb_param( 1, HB_IT_STRING );

   hb_retds( hb_itemGetCLen( pDateString ) >= 7 ? hb_itemGetCPtr( pDateString ) : NULL );
}

/*=============================================================================
 * hwg_hexbin()
 * Converts hex character to integer
 *===========================================================================*/
int hwg_hexbin(int cha)
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

/*=============================================================================
 * HWG_BIN2DC()
 * Converts hex string to decimal (double)
 *===========================================================================*/
HB_FUNC( HWG_BIN2DC )
{
    double pbyNumber;
    int i;
    unsigned char o;
    unsigned char bu[8];
    unsigned char szHex[17];
    int p;
    int c;
    int od;
    HB_USHORT uiWidth;
    HB_USHORT uiDec;
    const char *name;

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

    uiWidth = ( HB_USHORT ) hb_parni( 2 );
    uiDec = ( HB_USHORT ) hb_parni( 3 );

    name = hb_parc( 1 );
    memcpy(&szHex,name,16);
    szHex[16] = '\0';

    for ( i = 0 ; i < 16; i++ )
     {
          c = hwg_hexbin(szHex[i]);
          if ( c  != -1 )
          {
            if ( od == 1 )
            {
                od = 0;
            }
            else
            {
                od = 1;
            }
            if ( od == 1)
            {
              p = c;
            }
            else
            {
              p = ( p * 16 ) + c;
              o = (unsigned char) p;
              bu[ i / 2 ] = o;
            }
          }
        }

    memcpy(&pbyNumber,bu,sizeof(pbyNumber));
    hb_retndlen( pbyNumber , uiWidth , uiDec );
}

/*=============================================================================
 * GetFileMtimeU()
 * Gets file modification time (UTC)
 *===========================================================================*/
static void GetFileMtimeU(const char * filePath)
{
 struct stat attrib;
 char date[18];
 stat (filePath, &attrib);

 strftime(date, sizeof(date) , "%Y%m%d-%H:%M:%S", gmtime(&(attrib.st_mtime)));
 hb_retc(date);
}

/*=============================================================================
 * GetFileMtime()
 * Gets file modification time (local)
 *===========================================================================*/
static void GetFileMtime(const char * filePath)
{
 struct stat attrib;
 char date[18];
 stat (filePath, &attrib);
 strftime(date, sizeof(date) , "%Y%m%d-%H:%M:%S", localtime(&(attrib.st_mtime)));
 hb_retc(date);
}

/*=============================================================================
 * HWG_FILEMODTIMEU()
 * Gets file modification time (UTC)
 *===========================================================================*/
HB_FUNC( HWG_FILEMODTIMEU )
{
   /* FIXED: HB_PARSTR for Unicode support */
   void *hStr;
   LPCTSTR lpPath = HB_PARSTR( 1, &hStr, NULL );
#ifdef UNICODE
   char szPathA[ MAX_PATH ];
   WideCharToMultiByte( CP_ACP, 0, lpPath, -1, szPathA, MAX_PATH, NULL, NULL );
   GetFileMtimeU( szPathA );
#else
   GetFileMtimeU( ( const char * ) lpPath );
#endif
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_FILEMODTIME()
 * Gets file modification time (local)
 *===========================================================================*/
HB_FUNC( HWG_FILEMODTIME )
{
   void *hStr;
   LPCTSTR lpPath = HB_PARSTR( 1, &hStr, NULL );
#ifdef UNICODE
   char szPathA[ MAX_PATH ];
   WideCharToMultiByte( CP_ACP, 0, lpPath, -1, szPathA, MAX_PATH, NULL, NULL );
   GetFileMtime( szPathA );
#else
   GetFileMtime( ( const char * ) lpPath );
#endif
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_TOGGLE_HALFBYTE_C()
 * Toggles half byte
 *===========================================================================*/
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

/*=============================================================================
 * HWG_GUITYPE()
 * Returns GUI type
 *===========================================================================*/
HB_FUNC( HWG_GUITYPE )
{
  hb_retc( "WinAPI" );
}

/* ========= EOF of misc.c ============ */