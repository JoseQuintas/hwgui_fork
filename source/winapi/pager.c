/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level pager control functions
 *
 * Pager control (PagerCtrl) is used to scroll a child window
 * that is larger than the visible area.
*/

#include "hwingui.h"
#include <commctrl.h>

/* REMOVED: Obsolete compiler support
 * #if ( defined(__DMC__) || defined(__WATCOMC__) )
 * #include "missing.h"
 * #endif
 */

/*=============================================================================
 * HWG_PAGERSETCHILD()
 * Sets the child window for the pager control
 *===========================================================================*/
HB_FUNC( HWG_PAGERSETCHILD )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HWND hWnd = ( HWND ) HB_PARHANDLE( 2 );

   Pager_SetChild( m_hWnd, hWnd );
}

/*=============================================================================
 * HWG_PAGERRECALCSIZE()
 * Recalculates the pager control size
 *===========================================================================*/
HB_FUNC( HWG_PAGERRECALCSIZE )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );

   Pager_RecalcSize( m_hWnd );
}

/*=============================================================================
 * HWG_PAGERFORWARDMOUSE()
 * Forwards mouse messages to the pager control
 *===========================================================================*/
HB_FUNC( HWG_PAGERFORWARDMOUSE )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );
   BOOL bForward = hb_parl( 2 );

   Pager_ForwardMouse( m_hWnd, bForward );
}

/*=============================================================================
 * HWG_PAGERSETBKCOLOR()
 * Sets the background color of the pager control
 *===========================================================================*/
HB_FUNC( HWG_PAGERSETBKCOLOR )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );
   COLORREF clr = ( COLORREF ) hb_parnl( 2 );

   hb_retnl( ( LONG ) Pager_SetBkColor( m_hWnd, clr ) );
}

/*=============================================================================
 * HWG_PAGERGETBKCOLOR()
 * Gets the background color of the pager control
 *===========================================================================*/
HB_FUNC( HWG_PAGERGETBKCOLOR )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );

   hb_retnl( ( LONG ) Pager_GetBkColor( m_hWnd ) );
}

/*=============================================================================
 * HWG_PAGERSETBORDER()
 * Sets the border size of the pager control
 *===========================================================================*/
HB_FUNC( HWG_PAGERSETBORDER )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int iBorder = hb_parni( 2 );

   hb_retni( Pager_SetBorder( m_hWnd, iBorder ) );
}

/*=============================================================================
 * HWG_PAGERGETBORDER()
 * Gets the border size of the pager control
 *===========================================================================*/
HB_FUNC( HWG_PAGERGETBORDER )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );

   hb_retni( Pager_GetBorder( m_hWnd ) );
}

/*=============================================================================
 * HWG_PAGERSETPOS()
 * Sets the scroll position of the pager control
 *===========================================================================*/
HB_FUNC( HWG_PAGERSETPOS )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int iPos = hb_parni( 2 );

   hb_retni( Pager_SetPos( m_hWnd, iPos ) );
}

/*=============================================================================
 * HWG_PAGERGETPOS()
 * Gets the scroll position of the pager control
 *===========================================================================*/
HB_FUNC( HWG_PAGERGETPOS )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );

   hb_retni( Pager_GetPos( m_hWnd ) );
}

/*=============================================================================
 * HWG_PAGERSETBUTTONSIZE()
 * Sets the button size of the pager control
 *===========================================================================*/
HB_FUNC( HWG_PAGERSETBUTTONSIZE )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int iSize = hb_parni( 2 );

   hb_retni( Pager_SetButtonSize( m_hWnd, iSize ) );
}

/*=============================================================================
 * HWG_PAGERGETBUTTONSIZE()
 * Gets the button size of the pager control
 *===========================================================================*/
HB_FUNC( HWG_PAGERGETBUTTONSIZE )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );

   hb_retni( Pager_GetButtonSize( m_hWnd ) );
}

/*=============================================================================
 * HWG_PAGERGETBUTTONSTATE()
 * Gets the state of a pager button
 * 
 * Parameters:
 *   1 - Pager control handle (HWND)
 *   2 - Button index (0 = left/up, 1 = right/down)
 * 
 * Returns:
 *   Button state (PGF_INVISIBLE, PGF_NORMAL, PGF_GRAYED, PGF_DEPRESSED, PGF_HOT)
 *===========================================================================*/
HB_FUNC( HWG_PAGERGETBUTTONSTATE )
{
   HWND m_hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int iButton = hb_parni( 2 );   /* FIXED: Use second parameter for button index */

   hb_retnl( ( LONG ) Pager_GetButtonState( m_hWnd, iButton ) );
}

/*=============================================================================
 * HWG_PAGERONPAGERCALCSIZE()
 * Handles PGN_CALCSIZE notification
 *===========================================================================*/
HB_FUNC( HWG_PAGERONPAGERCALCSIZE )
{
   LPNMPGCALCSIZE pNMPGCalcSize = ( LPNMPGCALCSIZE ) HB_PARHANDLE( 1 );
   HWND hwndToolbar = ( HWND ) HB_PARHANDLE( 2 );
   SIZE size;

   SendMessage( hwndToolbar, TB_GETMAXSIZE, 0, ( LPARAM ) & size );

   switch ( pNMPGCalcSize->dwFlag )
   {
      case PGF_CALCWIDTH:
         pNMPGCalcSize->iWidth = size.cx;
         break;

      case PGF_CALCHEIGHT:
         pNMPGCalcSize->iHeight = size.cy;
         break;
   }

   hb_retnl( 0 );
}

/*=============================================================================
 * HWG_PAGERONPAGERSCROLL()
 * Handles PGN_SCROLL notification
 *===========================================================================*/
HB_FUNC( HWG_PAGERONPAGERSCROLL )
{
   LPNMPGSCROLL pNMPGScroll = ( LPNMPGSCROLL ) HB_PARHANDLE( 1 );

   switch ( pNMPGScroll->iDir )
   {
      case PGF_SCROLLLEFT:
      case PGF_SCROLLRIGHT:
      case PGF_SCROLLUP:
      case PGF_SCROLLDOWN:
         pNMPGScroll->iScroll = 20;
         break;
   }

   hb_retnl( 0 );
}