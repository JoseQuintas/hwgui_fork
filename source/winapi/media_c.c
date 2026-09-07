/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level media functions
 *
 * Copyright 2003 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwingui.h"
#include <commctrl.h>

#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"

/*=============================================================================
 * HWG_PLAYSOUND()
 * Plays a sound using Windows PlaySound API
 * 
 * Parameters:
 *   1 - Sound file name or resource (string)
 *   2 - Synchronous flag (TRUE = wait, FALSE = async)
 *   3 - Loop flag (TRUE = loop)
 * 
 * Returns:
 *   TRUE on success, FALSE on error
 *===========================================================================*/
HB_FUNC( HWG_PLAYSOUND )
{
   void *hSound;
   LPCTSTR lpSound = HB_PARSTR( 1, &hSound, NULL );
   HMODULE hmod = NULL;
   DWORD fdwSound = SND_NODEFAULT | SND_FILENAME;

   if( hb_parl( 2 ) )
      fdwSound |= SND_SYNC;
   else
      fdwSound |= SND_ASYNC;

   if( hb_parl( 3 ) )
      fdwSound |= SND_LOOP;
   if( !lpSound )
      fdwSound |= SND_PURGE;

   hb_retl( PlaySound( lpSound, hmod, fdwSound ) != 0 );
   hb_strfree( hSound );
}

/*=============================================================================
 * HWG_MCISENDSTRING()
 * Sends a string command to MCI device
 * 
 * Parameters:
 *   1 - Command string
 *   2 - Return buffer (by reference, optional)
 *   3 - Window handle for notifications (optional)
 * 
 * Returns:
 *   MCI error code (0 = success)
 *===========================================================================*/
HB_FUNC( HWG_MCISENDSTRING )
{
    void *hCommand;
    LPCTSTR lpCommand = HB_PARSTR( 1, &hCommand, NULL );
    HWND hWnd = ( HB_ISNIL( 3 ) ) ? GetActiveWindow() : ( HWND ) HB_PARHANDLE( 3 );
    LONG lResult;

    /* First call to get required buffer size - but mciSendString doesn't support querying size */
    lResult = ( LONG ) mciSendString( lpCommand, NULL, 0, hWnd );
    if( lResult != 0 )
    {
        hb_retnl( lResult );
        hb_strfree( hCommand );
        return;
    }

    /* FIXED: Dynamic buffer allocation */
    #define MCI_RETURN_BUFFER_SIZE 2048
    TCHAR *cBuffer = ( TCHAR * ) hb_xgrab( MCI_RETURN_BUFFER_SIZE * sizeof( TCHAR ) );
    if( cBuffer )
    {
        memset( cBuffer, 0, MCI_RETURN_BUFFER_SIZE * sizeof( TCHAR ) );
        lResult = ( LONG ) mciSendString( lpCommand, cBuffer, MCI_RETURN_BUFFER_SIZE - 1, hWnd );
        if( !HB_ISNIL( 2 ) )
            HB_STORSTR( cBuffer, 2 );
        hb_xfree( cBuffer );
    }
    else
        lResult = -1;

    hb_retnl( lResult );
    hb_strfree( hCommand );
    #undef MCI_RETURN_BUFFER_SIZE
}

/*=============================================================================
 * HWG_MCISENDCOMMAND()
 * Sends a command to MCI device with a parameter block
 * 
 * Parameters:
 *   1 - Device ID
 *   2 - Command message
 *   3 - Flags
 *   4 - Parameter block pointer (structure)
 * 
 * Returns:
 *   MCI error code (0 = success)
 *===========================================================================*/
HB_FUNC( HWG_MCISENDCOMMAND )
{
   /* FIXED: Use hb_parptr() to get the pointer to the parameter block */
   LPVOID lpParams = ( LPVOID ) hb_parptr( 4 );

   hb_retnl( mciSendCommand( ( UINT ) hb_parni( 1 ),
               ( UINT ) hb_parni( 2 ),
               ( DWORD ) hb_parnl( 3 ),
               ( DWORD_PTR ) lpParams ) );
}

/*=============================================================================
 * HWG_MCIGETERRORSTRING()
 * Retrieves the error string for an MCI error code
 * 
 * Parameters:
 *   1 - Error code (returned by mciSendCommand/mciSendString)
 *   2 - Buffer (by reference) to receive error string
 * 
 * Returns:
 *   TRUE on success, FALSE on error
 *===========================================================================*/
HB_FUNC( HWG_MCIGETERRORSTRING )
{
   TCHAR cBuffer[256] = { 0 };

   BOOL bResult = mciGetErrorString( ( DWORD ) hb_parnl( 1 ),
               cBuffer, HB_SIZEOFARRAY( cBuffer ) );

   HB_STORSTR( cBuffer, 2 );
   hb_retl( bResult );
}

/*=============================================================================
 * HWG_NMCIOPEN()
 * Opens an MCI device
 * 
 * Parameters:
 *   1 - Device type (string, e.g., "waveaudio", "mpegvideo")
 *   2 - Element name (string, e.g., filename)
 *   3 - Device ID (by reference, output)
 * 
 * Returns:
 *   MCI error code (0 = success)
 *===========================================================================*/
HB_FUNC( HWG_NMCIOPEN )
{
   MCI_OPEN_PARMS mciOpenParms;
   DWORD dwFlags = 0;
   void *hDevice, *hName;

   memset( &mciOpenParms, 0, sizeof( MCI_OPEN_PARMS ) );

   mciOpenParms.lpstrDeviceType = HB_PARSTR( 1, &hDevice, NULL );
   mciOpenParms.lpstrElementName = HB_PARSTR( 2, &hName, NULL );

   /* FIXED: Correct flag logic */
   if( mciOpenParms.lpstrDeviceType )
      dwFlags |= MCI_OPEN_TYPE;
   if( mciOpenParms.lpstrElementName )
      dwFlags |= MCI_OPEN_ELEMENT;

   LONG lResult = mciSendCommand( 0, MCI_OPEN, dwFlags,
               ( DWORD_PTR ) ( LPMCI_OPEN_PARMS ) & mciOpenParms );

   hb_storni( mciOpenParms.wDeviceID, 3 );
   hb_retnl( lResult );

   hb_strfree( hDevice );
   hb_strfree( hName );
}

/*=============================================================================
 * HWG_NMCIPLAY()
 * Plays the current MCI device
 * 
 * Parameters:
 *   1 - Device ID
 *   2 - From position (optional, in milliseconds)
 *   3 - To position (optional, in milliseconds)
 * 
 * Returns:
 *   MCI error code (0 = success)
 *===========================================================================*/
HB_FUNC( HWG_NMCIPLAY )
{
   MCI_PLAY_PARMS mciPlayParms;
   DWORD dwFlags = 0;

   memset( &mciPlayParms, 0, sizeof( MCI_PLAY_PARMS ) );

   if( ( mciPlayParms.dwFrom = ( DWORD ) hb_parnl( 2 ) ) != 0 )
      dwFlags |= MCI_FROM;

   if( ( mciPlayParms.dwTo = ( DWORD ) hb_parnl( 3 ) ) != 0 )
      dwFlags |= MCI_TO;

   hb_retnl( mciSendCommand( ( UINT ) hb_parni( 1 ),
               MCI_PLAY, dwFlags,
               ( DWORD_PTR ) ( LPMCI_PLAY_PARMS ) & mciPlayParms ) );
}

/*=============================================================================
 * HWG_NMCIWINDOW()
 * Sets the window for MCI video playback
 * 
 * Parameters:
 *   1 - Device ID
 *   2 - Window handle (HWND)
 * 
 * Returns:
 *   MCI error code (0 = success)
 *===========================================================================*/
HB_FUNC( HWG_NMCIWINDOW )
{
   MCI_ANIM_WINDOW_PARMS mciWindowParms;
   HWND hWnd = ( HWND ) HB_PARHANDLE( 2 );

   mciWindowParms.hWnd = hWnd;

   hb_retnl( mciSendCommand( ( UINT ) hb_parni( 1 ), MCI_WINDOW,
               MCI_ANIM_WINDOW_HWND | MCI_ANIM_WINDOW_DISABLE_STRETCH,
               ( DWORD_PTR ) ( LPMCI_ANIM_WINDOW_PARMS ) & mciWindowParms ) );
}
