/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Shell API wrappers
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwingui.h"
#include <shlobj.h>

#include "hbapi.h"
#include "hbapiitm.h"

#include "incomp_pointer.h"

#define  ID_NOTIFYICON   1
#define  WM_NOTIFYICON   WM_USER+1000

#ifndef BIF_USENEWUI
#ifndef BIF_NEWDIALOGSTYLE
#define BIF_NEWDIALOGSTYLE     0x0040
#endif
#define BIF_USENEWUI           (BIF_NEWDIALOGSTYLE | BIF_EDITBOX)
#endif
#ifndef BIF_EDITBOX
#define BIF_EDITBOX            0x0010
#endif

/*=============================================================================
 * BrowseCallbackProc()
 * Callback for SHBrowseForFolder
 *===========================================================================*/
static int CALLBACK BrowseCallbackProc( HWND hwnd, UINT uMsg,
      LPARAM lParam, LPARAM lpData )
{
      HB_SYMBOL_UNUSED(lParam);

   switch ( uMsg )
   {
      case BFFM_INITIALIZED:
      {
         if( lpData != ( LPARAM ) NULL )
         {
            SendMessage( hwnd, BFFM_SETSELECTION, (WPARAM)TRUE, lpData );
         }
      }
      break;
   }
   return 0;
}

/*=============================================================================
 * HWG_SELECTFOLDER()
 * Displays a folder selection dialog
 * 
 * Parameters:
 *   1 - Dialog title (string)
 *   2 - Initial folder path (string, optional)
 * 
 * Returns:
 *   Selected folder path as string, or empty on cancel
 *===========================================================================*/
HB_FUNC( HWG_SELECTFOLDER )
{
   BROWSEINFO bi;
   TCHAR lpBuffer[MAX_PATH];
   LPCTSTR lpResult = NULL;
   LPITEMIDLIST pidlBrowse;
   void *hTitle;
   void *hFolderName;
   LPCTSTR lpFolderName;

   lpFolderName = HB_PARSTR( 2, &hFolderName, NULL );

   bi.hwndOwner = GetActiveWindow();
   bi.pidlRoot = NULL;
   bi.pszDisplayName = lpBuffer;
   /* FIXED: HB_PARSTRDEF -> HB_PARSTR for Unicode support */
   bi.lpszTitle = HB_PARSTR( 1, &hTitle, NULL );
   bi.ulFlags = BIF_USENEWUI | BIF_NEWDIALOGSTYLE;
   bi.lpfn = BrowseCallbackProc;
   bi.lParam = lpFolderName ? ( LPARAM ) lpFolderName : 0;
   bi.iImage = 0;

   pidlBrowse = SHBrowseForFolder( &bi );
   if( pidlBrowse != NULL )
   {
      if( SHGetPathFromIDList( pidlBrowse, lpBuffer ) )
         lpResult = lpBuffer;
      CoTaskMemFree( pidlBrowse );
   }

   HB_RETSTR( lpResult );
   hb_strfree( hTitle );
   hb_strfree( hFolderName );
}

/*=============================================================================
 * HWG_SHELLNOTIFYICON()
 * Adds or removes an icon from the system tray
 * 
 * Parameters:
 *   1 - Add (TRUE) or Remove (FALSE)
 *   2 - Window handle (HWND)
 *   3 - Icon handle (HICON)
 *   4 - Tooltip text (string)
 *===========================================================================*/
HB_FUNC( HWG_SHELLNOTIFYICON )
{
   NOTIFYICONDATA tnid;

   memset( ( void * ) &tnid, 0, sizeof( NOTIFYICONDATA ) );

   tnid.cbSize = sizeof( NOTIFYICONDATA );
   tnid.hWnd = ( HWND ) HB_PARHANDLE( 2 );
   tnid.uID = ID_NOTIFYICON;
   tnid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
   tnid.uCallbackMessage = WM_NOTIFYICON;
   tnid.hIcon = ( HICON ) HB_PARHANDLE( 3 );

   /* FIXED: Only copy tooltip if parameter is a string */
   if( HB_ISCHAR( 4 ) )
   {
      HB_ITEMCOPYSTR( hb_param( 4, HB_IT_ANY ), tnid.szTip,
            HB_SIZEOFARRAY( tnid.szTip ) );
   }
   else
   {
      tnid.szTip[0] = 0;
      tnid.uFlags &= ~NIF_TIP;
   }

   if( ( BOOL ) hb_parl( 1 ) )
      Shell_NotifyIcon( NIM_ADD, &tnid );
   else
      Shell_NotifyIcon( NIM_DELETE, &tnid );
}

/*=============================================================================
 * HWG_SHELLMODIFYICON()
 * Modifies an existing system tray icon
 * 
 * Parameters:
 *   1 - Window handle (HWND)
 *   2 - Icon handle (HICON, optional)
 *   3 - Tooltip text (string, optional)
 *===========================================================================*/
HB_FUNC( HWG_SHELLMODIFYICON )
{
   NOTIFYICONDATA tnid;

   memset( ( void * ) &tnid, 0, sizeof( NOTIFYICONDATA ) );

   tnid.cbSize = sizeof( NOTIFYICONDATA );
   tnid.hWnd = ( HWND ) HB_PARHANDLE( 1 );
   tnid.uID = ID_NOTIFYICON;
   tnid.uFlags = 0;

   if( HB_ISNUM( 2 ) || HB_ISPOINTER( 2 ) )
   {
      tnid.uFlags |= NIF_ICON;
      tnid.hIcon = ( HICON ) HB_PARHANDLE( 2 );
   }

   if( HB_ISCHAR( 3 ) )
   {
      tnid.uFlags |= NIF_TIP;
      HB_ITEMCOPYSTR( hb_param( 3, HB_IT_ANY ),
            tnid.szTip, HB_SIZEOFARRAY( tnid.szTip ) );
   }

   Shell_NotifyIcon( NIM_MODIFY, &tnid );
}

/*=============================================================================
 * HWG_SHELLEXECUTE()
 * Executes a file or command using ShellExecute
 * 
 * Parameters:
 *   1 - File or document to open (string)
 *   2 - Operation (e.g., "open", "print") (string, optional)
 *   3 - Parameters (string, optional)
 *   4 - Working directory (string, optional)
 *   5 - Window show flag (int, optional)
 * 
 * Returns:
 *   ShellExecute result (int) - >32 on success, error code on failure
 *===========================================================================*/
HB_FUNC( HWG_SHELLEXECUTE )
{
#if defined( HB_OS_WIN_CE )
   hb_retni( -1 );
#else
   void *hOperation;
   void *hFile;
   void *hParameters;
   void *hDirectory;
   LPCTSTR lpDirectory;
   HINSTANCE hResult;

   lpDirectory = HB_PARSTR( 4, &hDirectory, NULL );

   /* FIXED: HB_PARSTRDEF -> HB_PARSTR for Unicode support */
   hResult = ShellExecute( GetActiveWindow(),
               HB_PARSTR( 2, &hOperation, NULL ),
               HB_PARSTR( 1, &hFile, NULL ),
               HB_PARSTR( 3, &hParameters, NULL ),
               lpDirectory,
               HB_ISNUM( 5 ) ? hb_parni( 5 ) : SW_SHOWNORMAL );

   /* FIXED: Return as integer (ShellExecute returns HINSTANCE as value) */
   hb_retnint( ( HB_MAXINT ) hResult );

   hb_strfree( hOperation );
   hb_strfree( hFile );
   hb_strfree( hParameters );
   hb_strfree( hDirectory );
#endif
}
