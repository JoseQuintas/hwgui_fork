/*
 *$Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level messages functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwingui.h"
#include <commctrl.h>
#include <richedit.h>

/*=============================================================================
 * s_msgbox()
 * Internal function: displays a message box
 *===========================================================================*/
static int s_msgbox( UINT uType )
{
   void *hText, *hTitle;
   int iResult;

   /* FIXED: HB_PARSTRDEF -> HB_PARSTR for Unicode support */
   iResult = MessageBox( GetActiveWindow(),
         HB_PARSTR( 1, &hText, NULL ),
         HB_PARSTR( 2, &hTitle, NULL ), uType );
   hb_strfree( hText );
   hb_strfree( hTitle );

   return iResult;
}

/*=============================================================================
 * HWG_MSGINFO()
 * Displays an information message box
 *===========================================================================*/
HB_FUNC( HWG_MSGINFO )
{
   s_msgbox( MB_OK | MB_ICONINFORMATION );
}

/*=============================================================================
 * HWG_MSGSTOP()
 * Displays a stop/error message box
 *===========================================================================*/
HB_FUNC( HWG_MSGSTOP )
{
   s_msgbox( MB_OK | MB_ICONSTOP );
}

/*=============================================================================
 * HWG_MSGOKCANCEL()
 * Displays an OK/Cancel message box
 *===========================================================================*/
HB_FUNC( HWG_MSGOKCANCEL )
{
   hb_retni( s_msgbox( MB_OKCANCEL | MB_ICONQUESTION ) );
}

/*=============================================================================
 * HWG_MSGYESNO()
 * Displays a Yes/No message box
 *===========================================================================*/
HB_FUNC( HWG_MSGYESNO )
{
   hb_retl( s_msgbox( MB_YESNO | MB_ICONQUESTION ) == IDYES );
}

/*=============================================================================
 * HWG_MSGNOYES()
 * Displays a No/Yes message box (default button = No)
 *===========================================================================*/
HB_FUNC( HWG_MSGNOYES )
{
   hb_retl( s_msgbox( MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2 ) == IDYES );
}

/*=============================================================================
 * HWG_MSGYESNOCANCEL()
 * Displays a Yes/No/Cancel message box
 * Returns: 1=Yes, 2=No, 0=Cancel
 *===========================================================================*/
HB_FUNC( HWG_MSGYESNOCANCEL )
{
   int iResult = s_msgbox( MB_YESNOCANCEL | MB_ICONQUESTION );
   hb_retni( (iResult == 6) ? 1 : ( (iResult == 7) ? 2 : 0 ) );
}

/*=============================================================================
 * HWG_MSGEXCLAMATION()
 * Displays an exclamation message box
 *===========================================================================*/
HB_FUNC( HWG_MSGEXCLAMATION )
{
   s_msgbox( MB_ICONEXCLAMATION | MB_OK | MB_SYSTEMMODAL );
}

/*=============================================================================
 * HWG_MSGRETRYCANCEL()
 * Displays a Retry/Cancel message box
 *===========================================================================*/
HB_FUNC( HWG_MSGRETRYCANCEL )
{
   hb_retni( s_msgbox( MB_RETRYCANCEL | MB_ICONQUESTION ) );
}

/*=============================================================================
 * HWG_MSGBEEP()
 * Plays a system beep
 *===========================================================================*/
HB_FUNC( HWG_MSGBEEP )
{
   MessageBeep( ( hb_pcount() == 0 ) ? (UINT)-1 : (UINT) hb_parnl( 1 ) );
}

/*=============================================================================
 * HWG_MSGTEMP()
 * Debug function: displays some system constants
 *===========================================================================*/
HB_FUNC( HWG_MSGTEMP )
{
   TCHAR cres[128];

   /* FIXED: Use wsprintf for wide strings in Unicode builds */
   wsprintf( cres, TEXT( "WS_OVERLAPPEDWINDOW: %lx NM_FIRST: %d " ),
         ( LONG ) WS_OVERLAPPEDWINDOW, NM_FIRST );

   hb_retni( MessageBox( GetActiveWindow(), cres,
               TEXT( "DialogBaseUnits" ),
               MB_OKCANCEL | MB_ICONQUESTION ) );
}