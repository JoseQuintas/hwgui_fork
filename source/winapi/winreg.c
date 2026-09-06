/*
 * $Id$
 *
 * Harbour Project source code:
 * Registry functions for Harbour
 *
 * Copyright 2001-2002 Luiz Rafael Culik<culikr@uol.com.br>
 * www - http://www.harbour-project.org
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

#include "hwingui.h"
#include <shlobj.h>

#include "hbvm.h"
#include "hbstack.h"
#include "hbapiitm.h"
#include "winreg.h"

/*=============================================================================
 * HWG_REGOPENKEYEX()
 * Opens a registry key
 * 
 * Parameters:
 *   1 - Parent key handle (HKEY)
 *   2 - Subkey name (string)
 *   3 - Reserved (not used)
 *   4 - Reserved (not used)
 *   5 - Output: opened key handle (by reference)
 * 
 * Returns:
 *   0 on success, -1 on error
 * 
 * Example (Harbour):
 *   hKey := 0
 *   IF HWG_REGOPENKEYEX( HKEY_LOCAL_MACHINE, "SOFTWARE\Microsoft", , , @hKey ) == 0
 *      // Use hKey
 *      HWG_REGCLOSEKEY( hKey )
 *   ENDIF
 *===========================================================================*/
HB_FUNC( HWG_REGOPENKEYEX )
{
   HKEY hwKey = ( HKEY ) hb_parnl( 1 );
   void *hValue;
   LPCTSTR lpValue = HB_PARSTR( 2, &hValue, NULL );  // TCHAR for Unicode support
   LONG lError;
   HKEY phwHandle;

   // Attempt to open the registry key with full access
   lError = RegOpenKeyEx( hwKey, lpValue, 0, KEY_ALL_ACCESS, &phwHandle );

   if( lError == ERROR_SUCCESS )
   {
      // Store the opened handle in the output parameter (by reference)
      hb_stornl( ( LONG ) phwHandle, 5 );
      hb_retni( 0 );  // Success
   }
   else
   {
      hb_retni( -1 );  // Failure
   }

   hb_strfree( hValue );  // Free the temporary string buffer
}

/*=============================================================================
 * HWG_REGQUERYVALUEEX()
 * Queries a registry value
 * 
 * Parameters:
 *   1 - Key handle (HKEY)
 *   2 - Value name (string)
 *   3 - Reserved (not used)
 *   4 - Type (output, by reference) - REG_SZ, REG_DWORD, etc.
 *   5 - Data (output, by reference) - actual value data
 * 
 * Returns:
 *   0 on success, -1 on error
 * 
 * Example (Harbour):
 *   cValue := SPACE(255)
 *   nType := 0
 *   IF HWG_REGQUERYVALUEEX( hKey, "Version", , @nType, @cValue ) == 0
 *      ? "Value:", cValue
 *      ? "Type:", nType
 *   ENDIF
 *===========================================================================*/
HB_FUNC( HWG_REGQUERYVALUEEX )
{
   HKEY hwKey = ( HKEY ) hb_parnl( 1 );
   LONG lError;
   DWORD lpType = hb_parnl( 4 );
   DWORD lpcbData = 0;
   void *hValue;
   LPCTSTR lpValue = HB_PARSTR( 2, &hValue, NULL );

   // First call: get required buffer size
   lError = RegQueryValueEx( hwKey, lpValue, NULL, &lpType, NULL, &lpcbData );

   if( lError == ERROR_SUCCESS && lpcbData > 0 )
   {
      // Allocate buffer for the data (+1 for null terminator)
      BYTE *lpData = ( BYTE * ) hb_xgrab( lpcbData + 1 );

      if( lpData == NULL )  // Memory allocation failed
      {
         hb_strfree( hValue );
         hb_retni( -1 );
         return;
      }

      memset( lpData, 0, lpcbData + 1 );  // Zero-initialize buffer

      // Second call: retrieve the actual data
      lError = RegQueryValueEx( hwKey, lpValue, NULL, &lpType, lpData, &lpcbData );

      if( lError == ERROR_SUCCESS )
      {
         // Store data as TCHAR string (supports Unicode)
         HB_STORSTR( ( TCHAR * ) lpData, 5 );
         hb_retni( 0 );  // Success
      }
      else
      {
         hb_retni( -1 );  // Failure
      }

      hb_xfree( lpData );  // Free allocated buffer
   }
   else
   {
      hb_retni( -1 );  // Key not found or empty
   }

   hb_strfree( hValue );
}

/*=============================================================================
 * HWG_REGENUMKEYEX()
 * Enumerates subkeys of a registry key
 * 
 * Parameters:
 *   1 - Key handle (HKEY)
 *   2 - Index (0-based) - which subkey to retrieve
 *   3 - Buffer (output, by reference) - subkey name
 *   4 - Buffer size (output, by reference) - length of name
 *   5 - Reserved (not used)
 *   6 - Class name (output, by reference) - optional class string
 *   7 - Class size (output, by reference)
 * 
 * Returns:
 *   ERROR_SUCCESS on success, error code on failure
 * 
 * Example (Harbour):
 *   FOR i := 0 TO 10
 *      cSubKey := SPACE(255)
 *      nSize := 255
 *      IF HWG_REGENUMKEYEX( hKey, i, @cSubKey, @nSize, , , ) == ERROR_SUCCESS
 *         ? i, cSubKey, nSize
 *      ELSE
 *         EXIT
 *      ENDIF
 *   NEXT
 *===========================================================================*/
HB_FUNC( HWG_REGENUMKEYEX )
{
   FILETIME ft;
   LONG nErr;
   DWORD dwBuffSize;
   DWORD dwClassSize;
   LPTSTR pBuffer = NULL;
   LPTSTR pClass = NULL;
   DWORD dwMaxLen;

   // First call: get required buffer sizes
   dwBuffSize = 0;
   dwClassSize = 0;
   nErr = RegEnumKeyEx( ( HKEY ) hb_parnl( 1 ), hb_parnl( 2 ),
                        NULL, &dwBuffSize, NULL, NULL, &dwClassSize, &ft );

   if( nErr == ERROR_SUCCESS )
   {
      // Allocate buffer for subkey name (TCHAR for Unicode support)
      dwMaxLen = dwBuffSize + 1;
      pBuffer = ( LPTSTR ) hb_xgrab( dwMaxLen * sizeof( TCHAR ) );
      if( pBuffer == NULL )
      {
         hb_retnl( ERROR_OUTOFMEMORY );
         return;
      }

      // Allocate buffer for class name
      dwMaxLen = dwClassSize + 1;
      pClass = ( LPTSTR ) hb_xgrab( dwMaxLen * sizeof( TCHAR ) );
      if( pClass == NULL )
      {
         hb_xfree( pBuffer );
         hb_retnl( ERROR_OUTOFMEMORY );
         return;
      }

      dwBuffSize = dwBuffSize + 1;
      dwClassSize = dwClassSize + 1;

      // Second call: retrieve the actual data
      nErr = RegEnumKeyEx( ( HKEY ) hb_parnl( 1 ), hb_parnl( 2 ),
                           pBuffer, &dwBuffSize, NULL, pClass, &dwClassSize, &ft );

      if( nErr == ERROR_SUCCESS )
      {
         // Store results in Harbour variables (by reference)
         HB_STORSTR( pBuffer, 3 );              // Subkey name
         hb_stornl( ( LONG ) dwBuffSize, 4 );   // Actual length
         HB_STORSTR( pClass, 6 );               // Class name
         hb_stornl( ( LONG ) dwClassSize, 7 );  // Class length
      }

      hb_xfree( pBuffer );
      hb_xfree( pClass );
   }

   hb_retnl( nErr );  // Return Windows error code
}

/*=============================================================================
 * HWG_REGSETVALUEEX()
 * Sets a registry value
 * 
 * Parameters:
 *   1 - Key handle (HKEY)
 *   2 - Value name (string)
 *   3 - Reserved (not used)
 *   4 - Type (REG_SZ, REG_DWORD, REG_BINARY, etc.)
 *   5 - Data (string or binary data)
 * 
 * Returns:
 *   ERROR_SUCCESS on success, error code on failure
 * 
 * Example (Harbour):
 *   HWG_REGSETVALUEEX( hKey, "Version", , REG_SZ, "1.0" )
 *   HWG_REGSETVALUEEX( hKey, "Count", , REG_DWORD, 123 )
 *===========================================================================*/
HB_FUNC( HWG_REGSETVALUEEX )
{
   void *hValue;
   LPCTSTR lpValue = HB_PARSTR( 2, &hValue, NULL );
   LONG lResult;
   DWORD dwSize;

   // Determine data size based on type
   if( HB_ISCHAR( 5 ) )
      dwSize = hb_parclen( 5 ) + 1;  // String: include null terminator
   else
      dwSize = hb_parni( 5 );         // Binary: use as-is

   // Write the value to the registry
   lResult = RegSetValueEx( ( HKEY ) hb_parnl( 1 ),
                            lpValue, 0,
                            hb_parnl( 4 ),                    // Type
                            ( const BYTE * ) hb_parcx( 5 ),   // Data
                            dwSize );

   hb_retnl( lResult );
   hb_strfree( hValue );
}

/*=============================================================================
 * HWG_REGCREATEKEYEX()
 * Creates a registry key
 * 
 * Parameters:
 *   1 - Parent key handle (HKEY)
 *   2 - Subkey name (string)
 *   3 - Reserved (not used)
 *   4 - Class name (string, optional)
 *   5 - Options (REG_OPTION_NON_VOLATILE, etc.)
 *   6 - Security access (KEY_ALL_ACCESS, etc.)
 *   7 - Security attributes (pointer, optional)
 *   8 - Output: created key handle (by reference)
 *   9 - Output: disposition (by reference) - REG_CREATED_NEW_KEY or REG_OPENED_EXISTING_KEY
 * 
 * Returns:
 *   ERROR_SUCCESS on success, error code on failure
 * 
 * Example (Harbour):
 *   hNewKey := 0
 *   nDisposition := 0
 *   IF HWG_REGCREATEKEYEX( HKEY_CURRENT_USER, "Software\MyApp", , , , , , @hNewKey, @nDisposition ) == ERROR_SUCCESS
 *      // Key created or opened
 *      HWG_REGCLOSEKEY( hNewKey )
 *   ENDIF
 *===========================================================================*/
HB_FUNC( HWG_REGCREATEKEYEX )
{
   HKEY hkResult;
   DWORD dwDisposition;
   LONG nErr;
   SECURITY_ATTRIBUTES *sa = NULL;
   void *hValue, *hClass;
   LPCTSTR lpValue = HB_PARSTR( 2, &hValue, NULL );
   LPTSTR lpClass = HB_PARSTR( 4, &hClass, NULL );

   // SECURITY_ATTRIBUTES is passed as a pointer (if provided)
   if( HB_ISNUM( 7 ) && hb_parnl( 7 ) != 0 )
   {
      sa = ( SECURITY_ATTRIBUTES * ) hb_parptr( 7 );
   }

   // Create or open the registry key
   nErr = RegCreateKeyEx( ( HKEY ) hb_parnl( 1 ),
                          lpValue,
                          0,                           // Reserved
                          lpClass,                     // Class name
                          ( DWORD ) hb_parnl( 5 ),    // Options
                          ( DWORD ) hb_parnl( 6 ),    // Security access
                          sa,
                          &hkResult,
                          &dwDisposition );

   if( nErr == ERROR_SUCCESS )
   {
      // Store the created key handle and disposition
      hb_stornl( ( LONG ) hkResult, 8 );
      hb_stornl( ( LONG ) dwDisposition, 9 );
   }

   hb_retnl( nErr );
   hb_strfree( hValue );
   hb_strfree( hClass );
}

/*=============================================================================
 * HWG_REGDELETEKEY()
 * Deletes a registry key
 * 
 * Parameters:
 *   1 - Parent key handle (HKEY)
 *   2 - Subkey name (string)
 * 
 * Returns:
 *   0 on success, -1 on error
 * 
 * Example (Harbour):
 *   IF HWG_REGDELETEKEY( HKEY_CURRENT_USER, "Software\MyApp" ) == 0
 *      ? "Key deleted successfully"
 *   ENDIF
 *===========================================================================*/
HB_FUNC( HWG_REGDELETEKEY )
{
   void *hValue;
   LPCTSTR lpValue = HB_PARSTR( 2, &hValue, NULL );

   hb_retni( RegDeleteKey( ( HKEY ) hb_parnl( 1 ),
               lpValue ) == ERROR_SUCCESS ? 0 : -1 );
   hb_strfree( hValue );
}

/*=============================================================================
 * HWG_REGDELETEVALUE()
 * Deletes a registry value
 * 
 * Parameters:
 *   1 - Key handle (HKEY)
 *   2 - Value name (string)
 * 
 * Returns:
 *   0 on success, -1 on error
 * 
 * Example (Harbour):
 *   IF HWG_REGDELETEVALUE( hKey, "Version" ) == 0
 *      ? "Value deleted successfully"
 *   ENDIF
 *===========================================================================*/
HB_FUNC( HWG_REGDELETEVALUE )
{
   void *hValue;
   LPCTSTR lpValue = HB_PARSTR( 2, &hValue, NULL );

   hb_retni( RegDeleteValue( ( HKEY ) hb_parnl( 1 ),
               lpValue ) == ERROR_SUCCESS ? 0 : -1 );
   hb_strfree( hValue );
}

/*=============================================================================
 * HWG_REGCLOSEKEY()
 * Closes a registry key handle
 * 
 * Parameters:
 *   1 - Key handle (HKEY)
 * 
 * Returns:
 *   ERROR_SUCCESS on success, -1 on error
 * 
 * Example (Harbour):
 *   HWG_REGCLOSEKEY( hKey )
 *===========================================================================*/
HB_FUNC( HWG_REGCLOSEKEY )
{
   HKEY hwHandle = ( HKEY ) hb_parnl( 1 );

   if( RegCloseKey( hwHandle ) == ERROR_SUCCESS )
   {
      hb_retnl( ERROR_SUCCESS );
   }
   else
   {
      hb_retnl( -1 );
   }
}