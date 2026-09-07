/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HList class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Listbox class and accompanying code added Feb 22nd, 2004 by
 * Vic McClung
*/

#include "hwingui.h"

/* REMOVED: Unnecessary header for listbox operations
 * #if defined(__MINGW32__) || defined(__MINGW64__) || defined(__WATCOMC__)
 * #include <prsht.h>
 * #endif
 */

#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"

/*=============================================================================
 * HWG_LISTBOXADDSTRING()
 * Adds a string to a listbox
 * 
 * Parameters:
 *   1 - Listbox handle (HWND)
 *   2 - String to add
 * 
 * Returns:
 *   Index of the new item, or LB_ERR on error
 *===========================================================================*/
HB_FUNC( HWG_LISTBOXADDSTRING )
{
   void *hString;
   LRESULT lResult;

   lResult = SendMessage( ( HWND ) HB_PARHANDLE( 1 ), LB_ADDSTRING, 0,
                          ( LPARAM ) HB_PARSTR( 2, &hString, NULL ) );
   hb_strfree( hString );
   hb_retnl( ( LONG ) lResult );
}

/*=============================================================================
 * HWG_LISTBOXSETSTRING()
 * Sets the current selection in a listbox
 * 
 * Parameters:
 *   1 - Listbox handle (HWND)
 *   2 - Index (1-based) of item to select
 *===========================================================================*/
HB_FUNC( HWG_LISTBOXSETSTRING )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), LB_SETCURSEL,
                ( WPARAM ) hb_parni( 2 ) - 1, 0 );
}

/*=============================================================================
 * HWG_CREATELISTBOX()
 * Creates a listbox control
 * 
 * Parameters:
 *   1 - Parent window handle (HWND)
 *   2 - Control ID
 *   3 - Style flags
 *   4-7 - Position and size (x, y, width, height)
 * 
 * Returns:
 *   Handle to the listbox control, or NULL on error
 *===========================================================================*/
HB_FUNC( HWG_CREATELISTBOX )
{
   HWND hListbox = CreateWindow( TEXT( "LISTBOX" ),
         TEXT( "" ),
         WS_CHILD | WS_VISIBLE | hb_parnl( 3 ),
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )(UINT_PTR) hb_parni( 2 ),
         GetModuleHandle( NULL ),
         NULL );

   /* FIXED: Check if creation succeeded */
   if( !hListbox )
   {
      HB_RETHANDLE( NULL );
      return;
   }

   HB_RETHANDLE( hListbox );
}

/*=============================================================================
 * HWG_LISTBOXDELETESTRING()
 * Deletes an item from a listbox
 * 
 * Parameters:
 *   1 - Listbox handle (HWND)
 *   2 - Index (1-based) of item to delete
 * 
 * Returns:
 *   Count of remaining items, or LB_ERR on error
 *===========================================================================*/
HB_FUNC( HWG_LISTBOXDELETESTRING )
{
   LRESULT lResult;

   lResult = SendMessage( ( HWND ) HB_PARHANDLE( 1 ), LB_DELETESTRING,
                          ( WPARAM ) hb_parni( 2 ) - 1, 0 );
   hb_retnl( ( LONG ) lResult );
}

/* ============================ EOF of listbox.c =============================== */