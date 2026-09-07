/*
 * $Id$
*/

/*----------------------------------------------------------------------------
 MINIGUI - Harbour Win32 GUI library source code

 Copyright 2002 Roberto Lopez <roblez@ciudad.com.ar>
 http://www.geocities.com/harbour_minigui/

 This program is free software; you can redistribute it and/or modify it under 
 the terms of the GNU General Public License as published by the Free Software 
 Foundation; either version 2 of the License, or (at your option) any later 
 version. 

 This program is distributed in the hope that it will be useful, but WITHOUT 
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with
 this software; see the file COPYING. If not, write to the Free Software 
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA (or 
 visit the web site http://www.gnu.org/).

 As a special exception, you have permission for additional uses of the text
 contained in this release of Harbour Minigui.

 The exception is that, if you link the Harbour Minigui library with other
 files to produce an executable, this does not by itself cause the resulting
 executable to be covered by the GNU General Public License.
 Your use of that executable is in no way restricted on account of linking the 
 Harbour-Minigui library code into it.

 Parts of this project are based upon:

	"Harbour GUI framework for Win32"
 	Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 	Copyright 2001 Antonio Linares <alinares@fivetech.com>
	www - http://www.harbour-project.org

	"Harbour Project"
	Copyright 1999-2003, http://www.harbour-project.org/
---------------------------------------------------------------------------*/

#include "hwingui.h"
#include <shlobj.h>

#include "winreg.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbapiitm.h"

/* REMOVED: Unnecessary headers for obsolete compilers
 * #if defined(__POCC__) || defined(__XCC__)
 * #include <unknwn.h>
 * #endif
 * #if defined(__DMC__)
 * #include "missing.h"
 * #endif
 */

/*=============================================================================
 * External function declarations
 * HWG_INITCOMMONCONTROLSEX() is defined in control.c
 *===========================================================================*/
extern void HWG_INITCOMMONCONTROLSEX( void );

/*=============================================================================
 * HWG_INITIPADDRESS()
 * Creates an IP Address control
 * 
 * Parameters:
 *   1 - Parent window handle (HWND)
 *   2 - Control ID
 *   3 - Style flags (optional)
 *   4-7 - Position and size (x, y, width, height)
 * 
 * Returns:
 *   Handle to the IP Address control, or NULL on error
 *===========================================================================*/
HB_FUNC( HWG_INITIPADDRESS )
{
   HWND hIpAddress;

   /* Initialize common controls (IP Address is a common control) */
   HWG_INITCOMMONCONTROLSEX();

   hIpAddress = CreateWindowEx( WS_EX_CLIENTEDGE, WC_IPADDRESS, TEXT( "" ),
         hb_parni( 3 ),
         hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ), ( HMENU )(UINT_PTR) hb_parni( 2 ),
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hIpAddress );
}

/*=============================================================================
 * HWG_SETIPADDRESS()
 * Sets the IP address value
 * 
 * Parameters:
 *   1 - IP Address control handle (HWND)
 *   2-5 - IP address octets (v1, v2, v3, v4)
 *===========================================================================*/
HB_FUNC( HWG_SETIPADDRESS )
{
   BYTE v1, v2, v3, v4;

   v1 = ( BYTE ) hb_parni( 2 );
   v2 = ( BYTE ) hb_parni( 3 );
   v3 = ( BYTE ) hb_parni( 4 );
   v4 = ( BYTE ) hb_parni( 5 );

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), IPM_SETADDRESS, 0,
         MAKEIPADDRESS( v1, v2, v3, v4 ) );
}

/*=============================================================================
 * HWG_GETIPADDRESS()
 * Retrieves the IP address value
 * 
 * Parameters:
 *   1 - IP Address control handle (HWND)
 * 
 * Returns:
 *   Four numeric values (v1, v2, v3, v4) on the Harbour stack
 *===========================================================================*/
HB_FUNC( HWG_GETIPADDRESS )
{
   DWORD pdwAddr;
   BYTE v1, v2, v3, v4;

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), IPM_GETADDRESS, 0,
         ( LPARAM ) ( LPDWORD ) & pdwAddr );

   v1 = ( BYTE ) FIRST_IPADDRESS( pdwAddr );
   v2 = ( BYTE ) SECOND_IPADDRESS( pdwAddr );
   v3 = ( BYTE ) THIRD_IPADDRESS( pdwAddr );
   v4 = ( BYTE ) FOURTH_IPADDRESS( pdwAddr );

   hb_reta( 4 );
   hb_storvni( ( INT ) v1, -1, 1 );
   hb_storvni( ( INT ) v2, -1, 2 );
   hb_storvni( ( INT ) v3, -1, 3 );
   hb_storvni( ( INT ) v4, -1, 4 );
}

/*=============================================================================
 * HWG_CLEARIPADDRESS()
 * Clears the IP address control
 * 
 * Parameters:
 *   1 - IP Address control handle (HWND)
 *===========================================================================*/
HB_FUNC( HWG_CLEARIPADDRESS )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), IPM_CLEARADDRESS, 0, 0 );
}