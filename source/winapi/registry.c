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

/*
 * Regcreatekey( handle, cKeyName ) --> handle
 */
HB_FUNC( HWG_REGCREATEKEY )
{
      HKEY hKey = NULL;

   #if defined( HB_WIN_UNICODE )
      void * pSubKey;
      LPCWSTR lpSubKey = hb_parstr_u16( 2, &pSubKey, NULL );
      if( RegCreateKeyExW( (HKEY) HB_PARHANDLE(1), lpSubKey, 0, NULL, 0, KEY_ALL_ACCESS,
            NULL, &hKey, NULL ) == ERROR_SUCCESS )
      {
            hb_strfreev( pSubKey );
            HB_RETHANDLE( hKey );
      }
      else
      {
            hb_strfreev( pSubKey );
            HB_RETHANDLE( NULL );
      }
   #else
      if( RegCreateKeyExA( (HKEY) HB_PARHANDLE(1), hb_parc(2), 0, NULL, 0, KEY_ALL_ACCESS,
            NULL, &hKey, NULL ) == ERROR_SUCCESS )
      {
            HB_RETHANDLE( hKey );
      }
      else
      {
            HB_RETHANDLE( NULL );
      }
   #endif
}

HB_FUNC( HWG_REGOPENKEY )
{
      HKEY hKey = NULL;

   #if defined( HB_WIN_UNICODE )
      void * pSubKey;
      LPCWSTR lpSubKey = hb_parstr_u16( 2, &pSubKey, NULL );
      if( RegOpenKeyExW( (HKEY) HB_PARHANDLE(1), lpSubKey, 0, KEY_ALL_ACCESS, &hKey ) == ERROR_SUCCESS )
      {
            hb_strfreev( pSubKey );
            HB_RETHANDLE( hKey );
      }
      else
      {
            hb_strfreev( pSubKey );
            HB_RETHANDLE( NULL );
      }
   #else
      if( RegOpenKeyExA( (HKEY) HB_PARHANDLE(1), hb_parc(2), 0, KEY_ALL_ACCESS, &hKey ) == ERROR_SUCCESS )
      {
            HB_RETHANDLE( hKey );
      }
      else
      {
            HB_RETHANDLE( NULL );
      }
   #endif
}

HB_FUNC( HWG_REGSETSTRING )
{
      LPBYTE lpData = ( LPBYTE ) hb_parc( 3 );
      DWORD cbData = ( DWORD ) hb_parclen( 3 );

   #if defined( HB_WIN_UNICODE )
      void * pValueName;
      LPCWSTR lpValueName = hb_parstr_u16( 2, &pValueName, NULL );
      if( RegSetValueExW( (HKEY) HB_PARHANDLE(1), lpValueName, 0, REG_SZ, lpData, cbData ) == ERROR_SUCCESS )
      {
            hb_strfreev( pValueName );
            hb_retl( 1 );
      }
      else
      {
            hb_strfreev( pValueName );
            hb_retl( 0 );
      }
   #else
      if( RegSetValueExA( (HKEY) HB_PARHANDLE(1), hb_parc(2), 0, REG_SZ, lpData, cbData ) == ERROR_SUCCESS )
      {
            hb_retl( 1 );
      }
      else
      {
            hb_retl( 0 );
      }
   #endif
}

HB_FUNC( HWG_REGSETBINARY )
{
      LPBYTE lpData = ( LPBYTE ) hb_parc( 3 );
      DWORD cbData = ( DWORD ) hb_parclen( 3 );

   #if defined( HB_WIN_UNICODE )
      void * pValueName;
      LPCWSTR lpValueName = hb_parstr_u16( 2, &pValueName, NULL );
      if( RegSetValueExW( (HKEY) HB_PARHANDLE(1), lpValueName, 0, REG_BINARY, lpData, cbData ) == ERROR_SUCCESS )
      {
            hb_strfreev( pValueName );
            hb_retl( 1 );
      }
      else
      {
            hb_strfreev( pValueName );
            hb_retl( 0 );
      }
   #else
      if( RegSetValueExA( (HKEY) HB_PARHANDLE(1), hb_parc(2), 0, REG_BINARY, lpData, cbData ) == ERROR_SUCCESS )
      {
            hb_retl( 1 );
      }
      else
      {
            hb_retl( 0 );
      }
   #endif
}

/*
 * RegCloseKey( handle )
 */
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

HB_FUNC( HWG_REGGETVALUE )
{
      HKEY hKey = (HKEY) HB_PARHANDLE(1);
      DWORD lpType = 0;
      LPBYTE lpData;
      DWORD lpcbData;
      int length;

   #if defined( HB_WIN_UNICODE )
      void * pValueName;
      LPCWSTR lpValueName = hb_parstr_u16( 2, &pValueName, NULL );

      if( RegQueryValueExW( hKey, lpValueName, NULL, NULL, NULL, &lpcbData ) == ERROR_SUCCESS )
      {
            length = (int) lpcbData;
            lpData = (LPBYTE)hb_xgrab( length + 2 );
            if( RegQueryValueExW( hKey, lpValueName, NULL, &lpType, lpData, &lpcbData ) == ERROR_SUCCESS )
            {
                  int iAdjust = (lpType == REG_SZ || lpType == REG_MULTI_SZ || lpType == REG_EXPAND_SZ) ? 1 : 0;
                  if( lpType == REG_SZ || lpType == REG_MULTI_SZ || lpType == REG_EXPAND_SZ )
                  {
                        ((WCHAR*)lpData)[(length / sizeof(WCHAR)) - iAdjust] = 0;
                        hb_retstr_u16( HB_CDP_ENDIAN_NATIVE, (WCHAR*)lpData );
                  }
                  else
                  {
                        hb_retclen( (char*)lpData, length );
                  }
                  if( hb_pcount() > 2 )
                        hb_stornl( (LONG) lpType, 3 );
            }
            else
            {
                  hb_ret();
            }
            hb_xfree( lpData );
      }
      else
      {
            hb_ret();
      }
      hb_strfreev( pValueName );
   #else
      LPCSTR lpValueName = hb_parc(2);

      if( RegQueryValueExA( hKey, lpValueName, NULL, NULL, NULL, &lpcbData ) == ERROR_SUCCESS )
      {
            length = (int) lpcbData;
            lpData = (LPBYTE)hb_xgrab( length + 1 );
            if( RegQueryValueExA( hKey, lpValueName, NULL, &lpType, lpData, &lpcbData ) == ERROR_SUCCESS )
            {
                  hb_retclen( (char*)lpData, (lpType == REG_SZ || lpType == REG_MULTI_SZ || lpType == REG_EXPAND_SZ) ? length - 1 : length );
                  if( hb_pcount() > 2 )
                        hb_stornl( (LONG) lpType, 3 );
            }
            else
            {
                  hb_ret();
            }
            hb_xfree( lpData );
      }
      else
      {
            hb_ret();
      }
   #endif
}

/* ============================== EOF of registry.c ============================ */
