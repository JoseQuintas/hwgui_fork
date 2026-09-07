/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level menu functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#define OEMRESOURCE
#include "hwingui.h"
#include <commctrl.h>

/* REMOVED: Obsolete Digital Mars C support
 * #ifdef __DMC__
 * #define MIIM_BITMAP     0x00000080
 * #endif
 */

#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"

#define  FLAG_DISABLED   1

/*=============================================================================
 * HWG__CREATEMENU()
 * Creates a new menu
 *===========================================================================*/
HB_FUNC( HWG__CREATEMENU )
{
   HMENU hMenu = CreateMenu();
   HB_RETHANDLE( hMenu );
}

/*=============================================================================
 * HWG__CREATEPOPUPMENU()
 * Creates a popup menu
 *===========================================================================*/
HB_FUNC( HWG__CREATEPOPUPMENU )
{
   HMENU hMenu = CreatePopupMenu();
   HB_RETHANDLE( hMenu );
}

/*=============================================================================
 * HWG__ADDMENUITEM()
 * Adds an item to a menu
 *===========================================================================*/
HB_FUNC( HWG__ADDMENUITEM )
{
   UINT uFlags = MF_BYPOSITION;
   void *hNewItem;
   LPCTSTR lpNewItem;
   int nPos;
   MENUITEMINFO mii;

   if( !HB_ISNIL( 6 ) && ( hb_parni( 6 ) & FLAG_DISABLED ) )
      uFlags |= MFS_DISABLED;

   lpNewItem = HB_PARSTR( 2, &hNewItem, NULL );
   if( lpNewItem )
   {
      BOOL lString = 0;
      LPCTSTR ptr = lpNewItem;
      while( *ptr )
      {
         if( *ptr != ' ' && *ptr != '-' )
         {
            lString = 1;
            break;
         }
         ptr++;
      }
      uFlags |= ( lString ) ? MF_STRING : MF_SEPARATOR;
   }
   else
      uFlags |= MF_SEPARATOR;

   if( !HB_ISNIL( 7 ) && hb_parl( 7 ) )
   {
      HMENU hSubMenu = CreateMenu();
      uFlags |= MF_POPUP;
      InsertMenu( ( HMENU ) HB_PARHANDLE( 1 ), hb_parni( 3 ), uFlags,
            ( UINT_PTR ) hSubMenu, lpNewItem );
      HB_RETHANDLE( hSubMenu );

      nPos = GetMenuItemCount( ( HMENU ) HB_PARHANDLE( 1 ) );
      mii.cbSize = sizeof( MENUITEMINFO );
      mii.fMask = MIIM_ID;
      if( GetMenuItemInfo( ( HMENU ) HB_PARHANDLE( 1 ), nPos - 1, TRUE, &mii ) )
      {
         mii.wID = hb_parni( 5 );
         SetMenuItemInfo( ( HMENU ) HB_PARHANDLE( 1 ), nPos - 1, TRUE, &mii );
      }
   }
   else
   {
      InsertMenu( ( HMENU ) HB_PARHANDLE( 1 ), hb_parni( 3 ), uFlags,
            ( UINT_PTR ) hb_parni( 5 ), lpNewItem );
      hb_retnl( 0 );
   }
   hb_strfree( hNewItem );
}

/*=============================================================================
 * HWG__CREATESUBMENU()
 * Creates a submenu
 *===========================================================================*/
HB_FUNC( HWG__CREATESUBMENU )
{
   MENUITEMINFO mii;
   HMENU hSubMenu = CreateMenu();

   mii.cbSize = sizeof( MENUITEMINFO );
   mii.fMask = MIIM_SUBMENU;
   mii.hSubMenu = hSubMenu;

   if( SetMenuItemInfo( ( HMENU ) HB_PARHANDLE( 1 ), hb_parni( 2 ), 0, &mii ) )
      HB_RETHANDLE( hSubMenu );
   else
      HB_RETHANDLE( NULL );
}

/*=============================================================================
 * HWG__SETMENU()
 * Sets a menu to a window
 *===========================================================================*/
HB_FUNC( HWG__SETMENU )
{
   hb_retl( SetMenu( ( HWND ) HB_PARHANDLE( 1 ), ( HMENU ) HB_PARHANDLE( 2 ) ) );
}

/*=============================================================================
 * HWG_GETMENUHANDLE()
 * Gets menu handle from a window
 *===========================================================================*/
HB_FUNC( HWG_GETMENUHANDLE )
{
   HWND handle = ( hb_pcount() > 0 && !HB_ISNIL( 1 ) ) ? ( HWND ) HB_PARHANDLE( 1 ) : aWindows[0];
   HB_RETHANDLE( GetMenu( handle ) );
}

/*=============================================================================
 * HWG_CHECKMENUITEM()
 * Checks or unchecks a menu item
 *===========================================================================*/
HB_FUNC( HWG_CHECKMENUITEM )
{
   HMENU hMenu;
   UINT uCheck = ( hb_pcount() < 3 || !HB_ISLOG( 3 ) || hb_parl( 3 ) ) ? MF_CHECKED : MF_UNCHECKED;

   if( HB_ISOBJECT( 1 ) )
   {
      PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
      PHB_ITEM pHandle = GetObjectVar( pObject, "HANDLE" );
      if( pHandle && !HB_IS_NIL( pHandle ) )
         hMenu = ( HMENU ) HB_GETHANDLE( pHandle );
      else
         hMenu = NULL;
   }
   else
   {
      HWND handle = ( hb_pcount() > 0 && !HB_ISNIL( 1 ) ) ? ( ( HWND ) HB_PARHANDLE( 1 ) ) : aWindows[0];
      hMenu = GetMenu( handle );
      if( !hMenu )
         hMenu = ( HMENU ) HB_PARHANDLE( 1 );
   }

   if( hMenu )
      CheckMenuItem( hMenu, hb_parni( 2 ), MF_BYCOMMAND | uCheck );
}

/*=============================================================================
 * HWG_ISCHECKEDMENUITEM()
 * Checks if a menu item is checked
 *===========================================================================*/
HB_FUNC( HWG_ISCHECKEDMENUITEM )
{
   HMENU hMenu;

   if( HB_ISOBJECT( 1 ) )
   {
      PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
      PHB_ITEM pHandle = GetObjectVar( pObject, "HANDLE" );
      if( pHandle && !HB_IS_NIL( pHandle ) )
         hMenu = ( HMENU ) HB_GETHANDLE( pHandle );
      else
      {
         hb_retl( 0 );
         return;
      }
   }
   else
   {
      HWND handle = ( hb_pcount() > 0 && !HB_ISNIL( 1 ) ) ? ( ( HWND ) HB_PARHANDLE( 1 ) ) : aWindows[0];
      hMenu = GetMenu( handle );
      if( !hMenu )
         hMenu = ( HMENU ) HB_PARHANDLE( 1 );
   }

   if( hMenu )
   {
      UINT uCheck = GetMenuState( hMenu, hb_parni( 2 ), MF_BYCOMMAND );
      hb_retl( uCheck & MF_CHECKED );
   }
   else
      hb_retl( 0 );
}

/*=============================================================================
 * HWG_ENABLEMENUITEM()
 * Enables or disables a menu item
 *===========================================================================*/
HB_FUNC( HWG_ENABLEMENUITEM )
{
   HMENU hMenu;
   UINT uEnable = ( hb_pcount() < 3 || !HB_ISLOG( 3 ) || hb_parl( 3 ) ) ? MF_ENABLED : MF_GRAYED;
   UINT uFlag = ( hb_pcount() < 4 || !HB_ISLOG( 4 ) || hb_parl( 4 ) ) ? MF_BYCOMMAND : MF_BYPOSITION;

   if( HB_ISOBJECT( 1 ) )
   {
      PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
      PHB_ITEM pHandle = GetObjectVar( pObject, "HANDLE" );
      if( pHandle && !HB_IS_NIL( pHandle ) )
         hMenu = ( HMENU ) HB_GETHANDLE( pHandle );
      else
      {
         hb_retl( FALSE );
         return;
      }
   }
   else
   {
      HWND handle = ( hb_pcount() > 0 && !HB_ISNIL( 1 ) ) ? ( ( HWND ) HB_PARHANDLE( 1 ) ) : aWindows[0];
      hMenu = GetMenu( handle );
      if( !hMenu )
         hMenu = ( HMENU ) HB_PARHANDLE( 1 );
   }

   if( hMenu )
      hb_retl( EnableMenuItem( hMenu, hb_parni( 2 ), uFlag | uEnable ) );
   else
      hb_retl( FALSE );
}

/*=============================================================================
 * HWG_ISENABLEDMENUITEM()
 * Checks if a menu item is enabled
 *===========================================================================*/
HB_FUNC( HWG_ISENABLEDMENUITEM )
{
   HMENU hMenu;
   UINT uFlag = ( hb_pcount() < 3 || !HB_ISLOG( 3 ) || hb_parl( 3 ) ) ? MF_BYCOMMAND : MF_BYPOSITION;

   if( HB_ISOBJECT( 1 ) )
   {
      PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
      PHB_ITEM pHandle = GetObjectVar( pObject, "HANDLE" );
      if( pHandle && !HB_IS_NIL( pHandle ) )
         hMenu = ( HMENU ) HB_GETHANDLE( pHandle );
      else
      {
         hb_retl( 0 );
         return;
      }
   }
   else
   {
      HWND handle = ( hb_pcount() > 0 && !HB_ISNIL( 1 ) ) ? ( ( HWND ) HB_PARHANDLE( 1 ) ) : aWindows[0];
      hMenu = GetMenu( handle );
      if( !hMenu )
         hMenu = ( HMENU ) HB_PARHANDLE( 1 );
   }

   if( hMenu )
   {
      UINT uCheck = GetMenuState( hMenu, hb_parni( 2 ), uFlag );
      hb_retl( !( uCheck & MF_GRAYED ) );
   }
   else
      hb_retl( 0 );
}

/*=============================================================================
 * HWG_DELETEMENU()
 * Deletes a menu item
 *===========================================================================*/
HB_FUNC( HWG_DELETEMENU )
{
   HMENU hMenu = ( hb_pcount() > 0 && !HB_ISNIL( 1 ) ) ? ( ( HMENU ) HB_PARHANDLE( 1 ) ) : GetMenu( aWindows[0] );

   if( hMenu )
      DeleteMenu( hMenu, hb_parni( 2 ), MF_BYCOMMAND );
}

/*=============================================================================
 * HWG_TRACKMENU()
 * Displays a context menu
 *===========================================================================*/
HB_FUNC( HWG_TRACKMENU )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 4 );
   SetForegroundWindow( hWnd );
   hb_retl( TrackPopupMenu( ( HMENU ) HB_PARHANDLE( 1 ),
               HB_ISNIL( 5 ) ? TPM_RIGHTALIGN : hb_parni( 5 ),
               hb_parni( 2 ), hb_parni( 3 ),
               0, hWnd, NULL ) );
   PostMessage( hWnd, 0, 0, 0 );
}

/*=============================================================================
 * HWG_DESTROYMENU()
 * Destroys a menu
 *===========================================================================*/
HB_FUNC( HWG_DESTROYMENU )
{
   hb_retl( DestroyMenu( ( HMENU ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_CREATEACCELERATORTABLE()
 * Creates an accelerator table
 *===========================================================================*/
HB_FUNC( HWG_CREATEACCELERATORTABLE )
{
   PHB_ITEM pArray = hb_param( 1, HB_IT_ARRAY ), pSubArr;
   LPACCEL lpaccl;
   ULONG ul, ulEntries = hb_arrayLen( pArray );
   HACCEL h;

   lpaccl = ( LPACCEL ) hb_xgrab( sizeof( ACCEL ) * ulEntries );

   for( ul = 1; ul <= ulEntries; ul++ )
   {
      pSubArr = hb_arrayGetItemPtr( pArray, ul );
      lpaccl[ul - 1].fVirt = ( BYTE ) hb_arrayGetNL( pSubArr, 1 ) | FNOINVERT | FVIRTKEY;
      lpaccl[ul - 1].key = ( WORD ) hb_arrayGetNL( pSubArr, 2 );
      lpaccl[ul - 1].cmd = ( WORD ) hb_arrayGetNL( pSubArr, 3 );
   }
   h = CreateAcceleratorTable( lpaccl, ( int ) ulEntries );

   hb_xfree( lpaccl );
   HB_RETHANDLE( h );
}

/*=============================================================================
 * HWG_DESTROYACCELERATORTABLE()
 * Destroys an accelerator table
 *===========================================================================*/
HB_FUNC( HWG_DESTROYACCELERATORTABLE )
{
   hb_retl( DestroyAcceleratorTable( ( HACCEL ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_DRAWMENUBAR()
 * Redraws the menu bar
 *===========================================================================*/
HB_FUNC( HWG_DRAWMENUBAR )
{
   hb_retl( ( BOOL ) DrawMenuBar( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_GETMENUCAPTION()
 * Gets the caption of a menu item
 *===========================================================================*/
HB_FUNC( HWG_GETMENUCAPTION )
{
   HMENU hMenu;

   if( HB_ISOBJECT( 1 ) )
   {
      PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
      PHB_ITEM pHandle = GetObjectVar( pObject, "HANDLE" );
      if( pHandle && !HB_IS_NIL( pHandle ) )
         hMenu = ( HMENU ) HB_GETHANDLE( pHandle );
      else
      {
         hb_retc( "" );
         return;
      }
   }
   else
   {
      HWND handle = ( hb_pcount() > 0 && !HB_ISNIL( 1 ) ) ? ( ( HWND ) HB_PARHANDLE( 1 ) ) : aWindows[0];
      hMenu = GetMenu( handle );
      if( !hMenu )
         hMenu = ( HMENU ) HB_PARHANDLE( 1 );
   }

   if( !hMenu )
   {
      hb_retc( "" );
      return;
   }

   MENUITEMINFO mii;
   LPTSTR lpBuffer;
   DWORD dwSize = 0;

   /* First call: get the required buffer size */
   memset( &mii, 0, sizeof( MENUITEMINFO ) );
   mii.cbSize = sizeof( MENUITEMINFO );
   mii.fMask = MIIM_STRING;
   mii.dwTypeData = NULL;
   mii.cch = 0;
   GetMenuItemInfo( hMenu, hb_parni( 2 ), 0, &mii );

   dwSize = mii.cch + 1;
   lpBuffer = ( LPTSTR ) hb_xgrab( dwSize * sizeof( TCHAR ) );
   if( !lpBuffer )
   {
      hb_retc( "" );
      return;
   }

   lpBuffer[0] = '\0';
   mii.dwTypeData = lpBuffer;
   mii.cch = dwSize;

   if( GetMenuItemInfo( hMenu, hb_parni( 2 ), 0, &mii ) )
      HB_RETSTR( lpBuffer );
   else
      hb_retc( "" );

   hb_xfree( lpBuffer );
}

/*=============================================================================
 * HWG_SETMENUCAPTION()
 * Sets the caption of a menu item
 *===========================================================================*/
HB_FUNC( HWG_SETMENUCAPTION )
{
   HMENU hMenu;

   if( HB_ISOBJECT( 1 ) )
   {
      PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
      PHB_ITEM pHandle = GetObjectVar( pObject, "HANDLE" );
      if( pHandle && !HB_IS_NIL( pHandle ) )
         hMenu = ( HMENU ) HB_GETHANDLE( pHandle );
      else
      {
         hb_retl( 0 );
         return;
      }
   }
   else
   {
      HWND handle = ( hb_pcount() > 0 && !HB_ISNIL( 1 ) ) ? ( ( HWND ) HB_PARHANDLE( 1 ) ) : aWindows[0];
      hMenu = GetMenu( handle );
      if( !hMenu )
         hMenu = ( HMENU ) HB_PARHANDLE( 1 );
   }

   if( !hMenu )
   {
      hb_retl( 0 );
      return;
   }

   MENUITEMINFO mii;
   void *hData;
   mii.cbSize = sizeof( MENUITEMINFO );
   mii.fMask = MIIM_STRING;
   mii.dwTypeData = ( LPTSTR ) HB_PARSTR( 3, &hData, NULL );

   hb_retl( SetMenuItemInfo( hMenu, hb_parni( 2 ), 0, &mii ) ? 1 : 0 );
   hb_strfree( hData );
}

/*=============================================================================
 * HWG__SETMENUITEMBITMAPS()
 * Sets bitmaps for a menu item
 *===========================================================================*/
HB_FUNC( HWG__SETMENUITEMBITMAPS )
{
   hb_retl( SetMenuItemBitmaps( ( HMENU ) HB_PARHANDLE( 1 ), hb_parni( 2 ),
               MF_BYCOMMAND, ( HBITMAP ) HB_PARHANDLE( 3 ),
               ( HBITMAP ) HB_PARHANDLE( 4 ) ) );
}

/*=============================================================================
 * HWG_GETMENUCHECKMARKDIMENSIONS()
 * Gets checkmark dimensions
 *===========================================================================*/
HB_FUNC( HWG_GETMENUCHECKMARKDIMENSIONS )
{
   hb_retnl( ( LONG ) GetMenuCheckMarkDimensions() );
}

/*=============================================================================
 * HWG_GETMENUBITMAPWIDTH()
 * Gets menu bitmap width
 *===========================================================================*/
HB_FUNC( HWG_GETMENUBITMAPWIDTH )
{
   hb_retni( GetSystemMetrics( SM_CXMENUSIZE ) );
}

/*=============================================================================
 * HWG_GETMENUBITMAPHEIGHT()
 * Gets menu bitmap height
 *===========================================================================*/
HB_FUNC( HWG_GETMENUBITMAPHEIGHT )
{
   hb_retni( GetSystemMetrics( SM_CYMENUSIZE ) );
}

/*=============================================================================
 * HWG_GETMENUCHECKMARKWIDTH()
 * Gets checkmark width
 *===========================================================================*/
HB_FUNC( HWG_GETMENUCHECKMARKWIDTH )
{
   hb_retni( GetSystemMetrics( SM_CXMENUCHECK ) );
}

/*=============================================================================
 * HWG_GETMENUCHECKMARKHEIGHT()
 * Gets checkmark height
 *===========================================================================*/
HB_FUNC( HWG_GETMENUCHECKMARKHEIGHT )
{
   hb_retni( GetSystemMetrics( SM_CYMENUCHECK ) );
}

/*=============================================================================
 * HWG_STRETCHBLT()
 * StretchBlt wrapper
 *===========================================================================*/
HB_FUNC( HWG_STRETCHBLT )
{
   hb_retl( StretchBlt( ( HDC ) HB_PARHANDLE( 1 ),
               hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ),
               ( HDC ) HB_PARHANDLE( 6 ),
               hb_parni( 7 ), hb_parni( 8 ), hb_parni( 9 ), hb_parni( 10 ),
               ( DWORD ) hb_parnl( 11 ) ) );
}

/*=============================================================================
 * HWG__INSERTBITMAPMENU()
 * Inserts a bitmap menu item
 *===========================================================================*/
HB_FUNC( HWG__INSERTBITMAPMENU )
{
   MENUITEMINFO mii;

   mii.cbSize = sizeof( MENUITEMINFO );
   mii.fMask = MIIM_ID | MIIM_BITMAP | MIIM_DATA;
   mii.hbmpItem = ( HBITMAP ) HB_PARHANDLE( 3 );

   hb_retl( ( LONG ) SetMenuItemInfo( ( HMENU ) HB_PARHANDLE( 1 ),
               hb_parni( 2 ), 0, &mii ) );
}

/*=============================================================================
 * HWG_MODIFYMENU()
 * Modifies a menu item
 *===========================================================================*/
HB_FUNC( HWG_MODIFYMENU )
{
   void *hStr;
   hb_retl( ModifyMenu( ( HMENU ) HB_PARHANDLE( 1 ), ( UINT ) hb_parni( 2 ),
               ( UINT ) hb_parni( 3 ), ( UINT ) hb_parni( 4 ),
               HB_PARSTR( 5, &hStr, NULL ) ) );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_ENABLEMENUSYSTEMITEM()
 * Enables/disables a system menu item
 *===========================================================================*/
HB_FUNC( HWG_ENABLEMENUSYSTEMITEM )
{
   HMENU hMenu;
   UINT uEnable = ( hb_pcount() < 3 || !HB_ISLOG( 3 ) || hb_parl( 3 ) ) ? MF_ENABLED : MF_GRAYED;
   UINT uFlag = ( hb_pcount() < 4 || !HB_ISLOG( 4 ) || hb_parl( 4 ) ) ? MF_BYCOMMAND : MF_BYPOSITION;

   hMenu = ( HMENU ) GetSystemMenu( ( HWND ) HB_PARHANDLE( 1 ), 0 );
   if( !hMenu )
      hb_retl( FALSE );
   else
      hb_retl( EnableMenuItem( hMenu, hb_parni( 2 ), uFlag | uEnable ) );
}

/*=============================================================================
 * HWG_SETMENUBACKCOLOR()
 * Sets menu background color
 *===========================================================================*/
HB_FUNC( HWG_SETMENUBACKCOLOR )
{
   HMENU hMenu;

   if( HB_ISOBJECT( 1 ) )
   {
      PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
      PHB_ITEM pHandle = GetObjectVar( pObject, "HANDLE" );
      if( pHandle && !HB_IS_NIL( pHandle ) )
         hMenu = ( HMENU ) HB_GETHANDLE( pHandle );
      else
         return;
   }
   else
   {
      HWND handle = ( hb_pcount() > 0 && !HB_ISNIL( 1 ) ) ? ( ( HWND ) HB_PARHANDLE( 1 ) ) : aWindows[0];
      hMenu = GetMenu( handle );
      if( !hMenu )
         hMenu = ( HMENU ) HB_PARHANDLE( 1 );
   }

   if( hMenu )
   {
      MENUINFO mi;
      HBRUSH hbrush = NULL;

      if( hb_pcount() > 1 && !HB_ISNIL( 2 ) )
         hbrush = CreateSolidBrush( ( COLORREF ) hb_parnl( 2 ) );

      mi.cbSize = sizeof( mi );
      mi.fMask = MIM_BACKGROUND | ( ( HB_ISLOG( 3 ) && !hb_parl( 3 ) ) ? 0 : MIM_APPLYTOSUBMENUS );
      mi.hbrBack = hbrush;
      SetMenuInfo( hMenu, &mi );

      /* FIXED: Delete the brush after use to prevent GDI leak */
      if( hbrush )
         DeleteObject( hbrush );
   }
}

/* REMOVED: Obsolete ChangeMenu function (16-bit)
 * HB_FUNC( HWG_CHANGEMENU ) { ... }
 */