/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level resource functions
 *
 * Copyright 2003 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
*/

#include "hwingui.h"

/* REMOVED: Unnecessary header
 * #if defined(__MINGW32__) || defined(__MINGW64__) || defined(__WATCOMC__)
 * #include <prsht.h>
 * #endif
 */

#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbinit.h"

#include "incomp_pointer.h"

HMODULE hModule;

/*=============================================================================
 * HWG_GETRESOURCES()
 * Returns the current module handle
 *===========================================================================*/
HB_FUNC( HWG_GETRESOURCES )
{
   HB_RETHANDLE( hModule );
}

/*=============================================================================
 * HWG_LOADSTRING()
 * Loads a string resource from the current module
 *===========================================================================*/
HB_FUNC( HWG_LOADSTRING )
{
   TCHAR buffer[ 2048 ];
   int iBuffRet;

   iBuffRet = LoadString( ( HINSTANCE ) hModule, ( UINT ) hb_parnl( 2 ),
                          buffer, HB_SIZEOFARRAY( buffer ) );

   if( iBuffRet > 0 )
      HB_RETSTRLEN( buffer, iBuffRet );
   else
      hb_retc( "" );
}

/*=============================================================================
 * HWG_LOADRESOURCE()
 * Loads a module (DLL/EXE) for resource access
 * 
 * Parameters:
 *   1 - Module name (string)
 * 
 * Returns:
 *   Module handle (HMODULE) on success, NULL on error
 *===========================================================================*/
HB_FUNC( HWG_LOADRESOURCE )
{
   void * hString;
   HMODULE hMod;

   hMod = GetModuleHandle( HB_PARSTR( 1, &hString, NULL ) );
   hb_strfree( hString );

   if( hMod )
   {
      hModule = hMod;
      HB_RETHANDLE( hMod );
   }
   else
      HB_RETHANDLE( NULL );
}

/*=============================================================================
 * hb_resourcemodules()
 * Startup initialization: sets default module handle
 *===========================================================================*/
void hb_resourcemodules( void * cargo )
{
   HB_SYMBOL_UNUSED( cargo );
   hModule = GetModuleHandle( NULL );
}

HB_CALL_ON_STARTUP_BEGIN( _hwgui_module_init_ )
   hb_vmAtInit( hb_resourcemodules, NULL );
HB_CALL_ON_STARTUP_END( _hwgui_module_init_ )

#if defined( HB_PRAGMA_STARTUP )
   #pragma startup _hwgui_module_init_
#elif defined( HB_DATASEG_STARTUP )
   #define HB_DATASEG_BODY    HB_DATASEG_FUNC( _hwgui_module_init_ )
   #include "hbiniseg.h"
#elif defined( HB_MSC_STARTUP )
   #if defined( HB_OS_WIN_64 )
      #pragma section( HB_MSC_START_SEGMENT, long, read )
   #endif
   #pragma data_seg( HB_MSC_START_SEGMENT )
   static HB_$INITSYM hb_vm_auto_hwgui_module_init_ = _hwgui_module_init_;
   #pragma data_seg()
#endif

/*=============================================================================
 * HWG_FINDRESOURCE()
 * Finds a resource in a module
 * 
 * Parameters:
 *   1 - Module name (string) or NULL for current module
 *   2 - Resource ID (numeric) or name (string)
 *   3 - Resource type (numeric) or name (string)
 * 
 * Returns:
 *   Handle to the resource (HRSRC) on success, NULL on error
 *===========================================================================*/
HB_FUNC( HWG_FINDRESOURCE )
{
   HRSRC hHRSRC = NULL;
   void *hModuleName, *hResName, *hResType;
   HMODULE hMod = NULL;

   /* FIXED: Get module handle */
   if( !HB_ISNIL( 1 ) )
   {
      hMod = GetModuleHandle( HB_PARSTR( 1, &hModuleName, NULL ) );
      hb_strfree( hModuleName );
   }
   else
      hMod = hModule;

   if( !hMod )
   {
      HB_RETHANDLE( NULL );
      return;
   }

   /* FIXED: Determine if resource name is numeric or string */
   if( HB_ISNUM( 2 ) )
   {
      int iName = hb_parni( 2 );
      hResName = ( LPTSTR ) MAKEINTRESOURCE( iName );
   }
   else
   {
      hResName = ( LPTSTR ) HB_PARSTR( 2, &hResName, NULL );
   }

   /* FIXED: Determine if resource type is numeric or string */
   if( HB_ISNUM( 3 ) )
   {
      int iType = hb_parni( 3 );
      hResType = ( LPTSTR ) MAKEINTRESOURCE( iType );
   }
   else
   {
      hResType = ( LPTSTR ) HB_PARSTR( 3, &hResType, NULL );
   }

   hHRSRC = FindResource( hMod, hResName, hResType );

   /* FIXED: Free string resources if they were allocated */
   if( HB_ISCHAR( 2 ) )
      hb_strfree( hResName );
   if( HB_ISCHAR( 3 ) )
      hb_strfree( hResType );

   HB_RETHANDLE( hHRSRC );
}