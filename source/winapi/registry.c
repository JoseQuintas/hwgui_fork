/*
 * HWGUI - Harbour Win32 GUI library source code:
 * Registry handling functions
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://kresin.ru
 */

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
#define OEMRESOURCE
#include <windows.h>

#include "guilib.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbapistr.h"

/*=============================================================================
 * HWG_REGCREATEKEY()
 * Creates a registry key (simplified version)
 * 
 * Parameters:
 *   1 - Parent key handle (HKEY)
 *   2 - Subkey name (string)
 * 
 * Returns:
 *   Handle to created/opened key, or NULL on error
 * 
 * Note: This is a simplified wrapper; use HWG_REGCREATEKEYEX() for more options
 *===========================================================================*/
HB_FUNC( HWG_REGCREATEKEY )
{
   HKEY hKey = NULL;

#if defined( UNICODE )
   #if defined( __XHARBOUR__ )
      /* xHarbour: uses UTF-8 internally, convert to UTF-16 for Windows API */
      void *pSubKey = NULL;
      const char *pszSubKey = hb_parstr_utf8( 2, &pSubKey, NULL );
      
      if( pszSubKey )
      {
         int nWideLen = MultiByteToWideChar( CP_UTF8, 0, pszSubKey, -1, NULL, 0 );
         if( nWideLen > 0 )
         {
            wchar_t *pWide = (wchar_t*) hb_xgrab( nWideLen * sizeof(wchar_t) );
            MultiByteToWideChar( CP_UTF8, 0, pszSubKey, -1, pWide, nWideLen );
            
            if( RegCreateKeyExW( (HKEY) HB_PARHANDLE(1), pWide, 0, NULL,
                                 0, KEY_ALL_ACCESS, NULL, &hKey, NULL ) == ERROR_SUCCESS )
            {
               HB_RETHANDLE( hKey );
            }
            else
            {
               HB_RETHANDLE( NULL );
            }
            hb_xfree( pWide );
         }
         else
         {
            HB_RETHANDLE( NULL );
         }
         hb_xfree( pSubKey );
      }
      else
      {
         HB_RETHANDLE( NULL );
      }
   #else
      /* Harbour: use hb_parstr_u16() directly for UTF-16 strings */
      void *pSubKey = NULL;
      LPCWSTR lpSubKey = (LPCWSTR) hb_parstr_u16( 2, HB_CDP_ENDIAN_NATIVE, &pSubKey, NULL );
      
      if( RegCreateKeyExW( (HKEY) HB_PARHANDLE(1), lpSubKey, 0, NULL,
                           0, KEY_ALL_ACCESS, NULL, &hKey, NULL ) == ERROR_SUCCESS )
      {
         HB_RETHANDLE( hKey );
      }
      else
      {
         HB_RETHANDLE( NULL );
      }
      if( pSubKey ) hb_xfree( pSubKey );
   #endif
#else
   /* ANSI build - works on both Harbour and xHarbour */
   if( RegCreateKeyExA( (HKEY) HB_PARHANDLE(1), hb_parc(2), 0, NULL,
                        0, KEY_ALL_ACCESS, NULL, &hKey, NULL ) == ERROR_SUCCESS )
   {
      HB_RETHANDLE( hKey );
   }
   else
   {
      HB_RETHANDLE( NULL );
   }
#endif
}

/*=============================================================================
 * HWG_REGOPENKEY()
 * Opens a registry key (simplified version)
 * 
 * Parameters:
 *   1 - Parent key handle (HKEY)
 *   2 - Subkey name (string)
 * 
 * Returns:
 *   Handle to opened key, or NULL on error
 *===========================================================================*/
HB_FUNC( HWG_REGOPENKEY )
{
   HKEY hKey = NULL;

#if defined( UNICODE )
   #if defined( __XHARBOUR__ )
      /* xHarbour: convert UTF-8 to UTF-16 for Windows API */
      void *pSubKey = NULL;
      const char *pszSubKey = hb_parstr_utf8( 2, &pSubKey, NULL );
      
      if( pszSubKey )
      {
         int nWideLen = MultiByteToWideChar( CP_UTF8, 0, pszSubKey, -1, NULL, 0 );
         if( nWideLen > 0 )
         {
            wchar_t *pWide = (wchar_t*) hb_xgrab( nWideLen * sizeof(wchar_t) );
            MultiByteToWideChar( CP_UTF8, 0, pszSubKey, -1, pWide, nWideLen );
            
            if( RegOpenKeyExW( (HKEY) HB_PARHANDLE(1), pWide, 0,
                                KEY_ALL_ACCESS, &hKey ) == ERROR_SUCCESS )
            {
               HB_RETHANDLE( hKey );
            }
            else
            {
               HB_RETHANDLE( NULL );
            }
            hb_xfree( pWide );
         }
         else
         {
            HB_RETHANDLE( NULL );
         }
         hb_xfree( pSubKey );
      }
      else
      {
         HB_RETHANDLE( NULL );
      }
   #else
      /* Harbour: use hb_parstr_u16() directly */
      void *pSubKey = NULL;
      LPCWSTR lpSubKey = (LPCWSTR) hb_parstr_u16( 2, HB_CDP_ENDIAN_NATIVE, &pSubKey, NULL );
      
      if( RegOpenKeyExW( (HKEY) HB_PARHANDLE(1), lpSubKey, 0,
                          KEY_ALL_ACCESS, &hKey ) == ERROR_SUCCESS )
      {
         HB_RETHANDLE( hKey );
      }
      else
      {
         HB_RETHANDLE( NULL );
      }
      if( pSubKey ) hb_xfree( pSubKey );
   #endif
#else
   /* ANSI build */
   if( RegOpenKeyExA( (HKEY) HB_PARHANDLE(1), hb_parc(2), 0,
                       KEY_ALL_ACCESS, &hKey ) == ERROR_SUCCESS )
   {
      HB_RETHANDLE( hKey );
   }
   else
   {
      HB_RETHANDLE( NULL );
   }
#endif
}

/*=============================================================================
 * HWG_REGSETSTRING()
 * Sets a string value in the registry
 * 
 * Parameters:
 *   1 - Key handle (HKEY)
 *   2 - Value name (string)
 *   3 - String data
 * 
 * Returns:
 *   TRUE on success, FALSE on error
 *===========================================================================*/
HB_FUNC( HWG_REGSETSTRING )
{
   LPBYTE lpData = ( LPBYTE ) hb_parcx( 3 );
   DWORD cbData = ( DWORD ) hb_parclen( 3 );
   LONG lResult = ERROR_BAD_ARGUMENTS;

#if defined( UNICODE )
   #if defined( __XHARBOUR__ )
      /* xHarbour: convert value name from UTF-8 to UTF-16 */
      void *pValueName = NULL;
      const char *pszValueName = hb_parstr_utf8( 2, &pValueName, NULL );
      
      if( pszValueName )
      {
         int nWideLen = MultiByteToWideChar( CP_UTF8, 0, pszValueName, -1, NULL, 0 );
         if( nWideLen > 0 )
         {
            wchar_t *pWide = (wchar_t*) hb_xgrab( nWideLen * sizeof(wchar_t) );
            MultiByteToWideChar( CP_UTF8, 0, pszValueName, -1, pWide, nWideLen );
            lResult = RegSetValueExW( (HKEY) HB_PARHANDLE(1), pWide, 0,
                                       REG_SZ, lpData, cbData );
            hb_xfree( pWide );
         }
         hb_xfree( pValueName );
      }
   #else
      /* Harbour: use hb_parstr_u16() directly */
      void *pValueName = NULL;
      LPCWSTR lpValueName = (LPCWSTR) hb_parstr_u16( 2, HB_CDP_ENDIAN_NATIVE, &pValueName, NULL );
      lResult = RegSetValueExW( (HKEY) HB_PARHANDLE(1), lpValueName, 0,
                                 REG_SZ, lpData, cbData );
      if( pValueName ) hb_xfree( pValueName );
   #endif
#else
   /* ANSI build */
   lResult = RegSetValueExA( (HKEY) HB_PARHANDLE(1), hb_parc(2), 0,
                              REG_SZ, lpData, cbData );
#endif

   hb_retl( lResult == ERROR_SUCCESS );
}

/*=============================================================================
 * HWG_REGSETBINARY()
 * Sets a binary value in the registry
 * 
 * Parameters:
 *   1 - Key handle (HKEY)
 *   2 - Value name (string)
 *   3 - Binary data
 * 
 * Returns:
 *   TRUE on success, FALSE on error
 *===========================================================================*/
HB_FUNC( HWG_REGSETBINARY )
{
   LPBYTE lpData = ( LPBYTE ) hb_parcx( 3 );
   DWORD cbData = ( DWORD ) hb_parclen( 3 );
   LONG lResult = ERROR_BAD_ARGUMENTS;

#if defined( UNICODE )
   #if defined( __XHARBOUR__ )
      /* xHarbour: convert value name from UTF-8 to UTF-16 */
      void *pValueName = NULL;
      const char *pszValueName = hb_parstr_utf8( 2, &pValueName, NULL );
      
      if( pszValueName )
      {
         int nWideLen = MultiByteToWideChar( CP_UTF8, 0, pszValueName, -1, NULL, 0 );
         if( nWideLen > 0 )
         {
            wchar_t *pWide = (wchar_t*) hb_xgrab( nWideLen * sizeof(wchar_t) );
            MultiByteToWideChar( CP_UTF8, 0, pszValueName, -1, pWide, nWideLen );
            lResult = RegSetValueExW( (HKEY) HB_PARHANDLE(1), pWide, 0,
                                       REG_BINARY, lpData, cbData );
            hb_xfree( pWide );
         }
         hb_xfree( pValueName );
      }
   #else
      /* Harbour: use hb_parstr_u16() directly */
      void *pValueName = NULL;
      LPCWSTR lpValueName = (LPCWSTR) hb_parstr_u16( 2, HB_CDP_ENDIAN_NATIVE, &pValueName, NULL );
      lResult = RegSetValueExW( (HKEY) HB_PARHANDLE(1), lpValueName, 0,
                                 REG_BINARY, lpData, cbData );
      if( pValueName ) hb_xfree( pValueName );
   #endif
#else
   /* ANSI build */
   lResult = RegSetValueExA( (HKEY) HB_PARHANDLE(1), hb_parc(2), 0,
                              REG_BINARY, lpData, cbData );
#endif

   hb_retl( lResult == ERROR_SUCCESS );
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
 *===========================================================================*/
HB_FUNC( HWG_REGCLOSEKEY )
{
   if( RegCloseKey( (HKEY) HB_PARHANDLE(1) ) == ERROR_SUCCESS )
   {
      hb_retnl( ERROR_SUCCESS );
   }
   else
   {
      hb_retnl( -1 );
   }
}

/*=============================================================================
 * HWG_REGGETVALUE()
 * Retrieves a registry value
 * 
 * Parameters:
 *   1 - Key handle (HKEY)
 *   2 - Value name (string)
 *   3 - Type (output, by reference) - optional
 * 
 * Returns:
 *   Value data as Harbour string, or NIL on error
 *===========================================================================*/
HB_FUNC( HWG_REGGETVALUE )
{
   HKEY hKey = (HKEY) HB_PARHANDLE(1);
   DWORD lpType = 0;
   LPBYTE lpData = NULL;
   DWORD lpcbData = 0;
   LONG lResult;
   int length;

#if defined( UNICODE )
   #if defined( __XHARBOUR__ )
      /* xHarbour: convert value name from UTF-8 to UTF-16 */
      void *pValueName = NULL;
      const char *pszValueName = hb_parstr_utf8( 2, &pValueName, NULL );
      
      if( !pszValueName )
      {
         if( pValueName ) hb_xfree( pValueName );
         hb_ret();
         return;
      }

      int nWideLen = MultiByteToWideChar( CP_UTF8, 0, pszValueName, -1, NULL, 0 );
      if( nWideLen == 0 )
      {
         if( pValueName ) hb_xfree( pValueName );
         hb_ret();
         return;
      }

      wchar_t *pWideName = (wchar_t*) hb_xgrab( nWideLen * sizeof(wchar_t) );
      MultiByteToWideChar( CP_UTF8, 0, pszValueName, -1, pWideName, nWideLen );

      /* First call: get required buffer size */
      lResult = RegQueryValueExW( hKey, pWideName, NULL, NULL, NULL, &lpcbData );
      if( lResult != ERROR_SUCCESS )
      {
         hb_xfree( pWideName );
         if( pValueName ) hb_xfree( pValueName );
         hb_ret();
         return;
      }

      /* Allocate buffer for the data (+2 for null terminator safety) */
      length = (int) lpcbData;
      lpData = (LPBYTE) hb_xgrab( length + sizeof(WCHAR) );
      if( lpData == NULL )
      {
         hb_xfree( pWideName );
         if( pValueName ) hb_xfree( pValueName );
         hb_ret();
         return;
      }

      memset( lpData, 0, length + sizeof(WCHAR) );

      /* Second call: retrieve the actual data */
      lResult = RegQueryValueExW( hKey, pWideName, NULL, &lpType, lpData, &lpcbData );

      if( lResult == ERROR_SUCCESS )
      {
         if( lpType == REG_SZ || lpType == REG_MULTI_SZ || lpType == REG_EXPAND_SZ )
         {
            /* String types - ensure null termination */
            int nChars = lpcbData / sizeof(WCHAR);
            if( nChars > 0 )
               ((WCHAR*)lpData)[nChars - 1] = 0;
            hb_retstr_u16( HB_CDP_ENDIAN_NATIVE, (WCHAR*)lpData );
         }
         else
         {
            /* Binary types - return as-is */
            hb_retclen( (char*)lpData, lpcbData );
         }

         /* Return type if requested */
         if( hb_pcount() > 2 )
            hb_stornl( (LONG) lpType, 3 );
      }
      else
      {
         hb_ret();
      }

      hb_xfree( lpData );
      hb_xfree( pWideName );
      if( pValueName ) hb_xfree( pValueName );

   #else
      /* Harbour: use hb_parstr_u16() directly */
      void *pValueName = NULL;
      LPCWSTR lpValueName = (LPCWSTR) hb_parstr_u16( 2, HB_CDP_ENDIAN_NATIVE, &pValueName, NULL );

      if( !lpValueName )
      {
         if( pValueName ) hb_xfree( pValueName );
         hb_ret();
         return;
      }

      /* First call: get required buffer size */
      lResult = RegQueryValueExW( hKey, lpValueName, NULL, NULL, NULL, &lpcbData );

      if( lResult != ERROR_SUCCESS )
      {
         if( pValueName ) hb_xfree( pValueName );
         hb_ret();
         return;
      }

      /* Allocate buffer for the data (+2 for null terminator safety) */
      length = (int) lpcbData;
      lpData = (LPBYTE) hb_xgrab( length + sizeof(WCHAR) );

      if( lpData == NULL )
      {
         if( pValueName ) hb_xfree( pValueName );
         hb_ret();
         return;
      }

      memset( lpData, 0, length + sizeof(WCHAR) );

      /* Second call: retrieve the actual data */
      lResult = RegQueryValueExW( hKey, lpValueName, NULL, &lpType, lpData, &lpcbData );

      if( lResult == ERROR_SUCCESS )
      {
         if( lpType == REG_SZ || lpType == REG_MULTI_SZ || lpType == REG_EXPAND_SZ )
         {
            /* String types - ensure null termination */
            int nChars = lpcbData / sizeof(WCHAR);
            if( nChars > 0 )
               ((WCHAR*)lpData)[nChars - 1] = 0;
            hb_retstr_u16( HB_CDP_ENDIAN_NATIVE, (WCHAR*)lpData );
         }
         else
         {
            /* Binary types - return as-is */
            hb_retclen( (char*)lpData, lpcbData );
         }

         /* Return type if requested */
         if( hb_pcount() > 2 )
            hb_stornl( (LONG) lpType, 3 );
      }
      else
      {
         hb_ret();
      }

      hb_xfree( lpData );
      if( pValueName ) hb_xfree( pValueName );
   #endif

#else
   /* ANSI build - works on both Harbour and xHarbour */
   LPCSTR lpValueName = hb_parc(2);

   if( !lpValueName )
   {
      hb_ret();
      return;
   }

   /* First call: get required buffer size */
   lResult = RegQueryValueExA( hKey, lpValueName, NULL, NULL, NULL, &lpcbData );

   if( lResult != ERROR_SUCCESS )
   {
      hb_ret();
      return;
   }

   /* Allocate buffer for the data (+1 for null terminator) */
   length = (int) lpcbData;
   lpData = (LPBYTE) hb_xgrab( length + 1 );

   if( lpData == NULL )
   {
      hb_ret();
      return;
   }

   memset( lpData, 0, length + 1 );

   /* Second call: retrieve the actual data */
   lResult = RegQueryValueExA( hKey, lpValueName, NULL, &lpType, lpData, &lpcbData );

   if( lResult == ERROR_SUCCESS )
   {
      if( lpType == REG_SZ || lpType == REG_MULTI_SZ || lpType == REG_EXPAND_SZ )
      {
         /* String types - ensure null termination */
         if( lpcbData > 0 )
            lpData[lpcbData - 1] = 0;
         hb_retclen( (char*)lpData, lpcbData - 1 );
      }
      else
      {
         /* Binary types - return as-is */
         hb_retclen( (char*)lpData, lpcbData );
      }

      /* Return type if requested */
      if( hb_pcount() > 2 )
         hb_stornl( (LONG) lpType, 3 );
   }
   else
   {
      hb_ret();
   }

   hb_xfree( lpData );
#endif
}