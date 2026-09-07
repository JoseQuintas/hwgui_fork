/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level controls functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#define HB_OS_WIN_32_USED

#define OEMRESOURCE
#include "hwingui.h"
#include <commctrl.h>
#include <winuser.h>
#include <windowsx.h>

/* REMOVED: Obsolete compiler support
 * #if defined(__DMC__)
 * #include "missing.h"
 * #endif
 */

#include "hbapiitm.h"
#include "hbvm.h"
#include "hbdate.h"
#include "hbtrace.h"
#ifdef __XHARBOUR__
   #include "hbfast.h"
#endif

#include <tchar.h>

/* Suppress compiler warnings */
#include "incomp_pointer.h"
#include "warnings.h"

/* -------------------------------------------------------------------------
 * MinGW/SDK compatibility:
 * Some environments may miss GET_X_LPARAM / GET_Y_LPARAM even with windowsx.h.
 * Provide safe fallbacks.
 * --------------------------------------------------------------------- */
#ifndef GET_X_LPARAM
   #define GET_X_LPARAM( lp )  ((int)(short)LOWORD( (DWORD_PTR)(lp) ))
#endif
#ifndef GET_Y_LPARAM
   #define GET_Y_LPARAM( lp )  ((int)(short)HIWORD( (DWORD_PTR)(lp) ))
#endif

/* REMOVED: Manual declaration of GetAncestor()
 * Modern Windows headers (winuser.h) already declare this function.
 * #if defined(__BORLANDC__) || (defined(_MSC_VER) && !defined(__XCC__) || defined(__WATCOMC__) || defined(__DMC__) )
 * HB_EXTERN_BEGIN
 * WINUSERAPI HWND WINAPI GetAncestor( HWND hwnd, UINT gaFlags );
 * HB_EXTERN_END
 * #endif
 */

#ifndef TTS_BALLOON
   #define TTS_BALLOON             0x40    // added by MAG
#endif
#ifndef CCM_SETVERSION
   #define CCM_SETVERSION (CCM_FIRST + 0x7)
#endif
#ifndef CCM_GETVERSION
   #define CCM_GETVERSION (CCM_FIRST + 0x8)
#endif
#ifndef TB_GETIMAGELIST
   #define TB_GETIMAGELIST         (WM_USER + 49)
#endif

LRESULT CALLBACK WinCtrlProc( HWND, UINT, WPARAM, LPARAM );
LRESULT APIENTRY SplitterProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY StaticSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY EditSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY ButtonSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY ListSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY UpDownSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY DatePickerSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY TrackSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY TabSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
LRESULT APIENTRY TreeViewSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam,
      LPARAM lParam );
static void CALLBACK s_timerProc( HWND, UINT, UINT, DWORD );

static HWND hWndTT = 0;
static BOOL lInitCmnCtrl = 0;
static BOOL lToolTipBalloon = FALSE;    // added by MAG
static WNDPROC wpOrigEditProc, wpOrigTrackProc, wpOrigTabProc, wpOrigStaticProc, wpOrigListProc, wpOrigUpDownProc, wpOrigDatePickerProc,  wpOrigTreeViewProc;
static LONG_PTR wpOrigButtonProc;

/*=============================================================================
 * HWG_INITCOMMONCONTROLSEX()
 * Initializes Windows common controls
 * Called once to load all common control classes
 *===========================================================================*/
HB_FUNC( HWG_INITCOMMONCONTROLSEX )
{
   if( !lInitCmnCtrl )
   {
      INITCOMMONCONTROLSEX i;

      i.dwSize = sizeof( INITCOMMONCONTROLSEX );
      i.dwICC =
            ICC_DATE_CLASSES | ICC_INTERNET_CLASSES | ICC_BAR_CLASSES |
            ICC_LISTVIEW_CLASSES | ICC_TAB_CLASSES | ICC_TREEVIEW_CLASSES;
      InitCommonControlsEx( &i );
      lInitCmnCtrl = 1;
   }
}

/*=============================================================================
 * HWG_MOVEWINDOW()
 * Moves or resizes a window
 *===========================================================================*/
HB_FUNC( HWG_MOVEWINDOW )
{
   RECT rc;

   GetWindowRect( ( HWND ) HB_PARHANDLE( 1 ), &rc );
   MoveWindow( ( HWND ) HB_PARHANDLE( 1 ),
         ( HB_ISNIL( 2 ) ) ? rc.left : hb_parni( 2 ),
         ( HB_ISNIL( 3 ) ) ? rc.top : hb_parni( 3 ),
         ( HB_ISNIL( 4 ) ) ? rc.right - rc.left : hb_parni( 4 ),
         ( HB_ISNIL( 5 ) ) ? rc.bottom - rc.top : hb_parni( 5 ),
         ( hb_pcount(  ) < 6 ) ? TRUE : hb_parl( 6 ) );
}

/*=============================================================================
 * HWG_CREATEPROGRESSBAR()
 * Creates a progress bar control
 *===========================================================================*/
HB_FUNC( HWG_CREATEPROGRESSBAR )
{
   HWND hPBar, hParentWindow = ( HWND ) HB_PARHANDLE( 1 );
   RECT rcClient;
   ULONG ulStyle ;
   int cyVScroll = GetSystemMetrics( SM_CYVSCROLL );
   int x1, y1, nwidth, nheight;

   if( hb_pcount(  ) > 2 )
   {
      ulStyle = hb_parnl( 3 );
      x1 = hb_parni( 4 );
      y1 = hb_parni( 5 );
      nwidth = hb_parni( 6 );
      nheight = hb_pcount(  ) > 6 && !HB_ISNIL( 7 ) ? hb_parni( 7 ) : cyVScroll ;
   }
   else
   {
      GetClientRect( hParentWindow, &rcClient );
      ulStyle = 0 ;
      x1 = rcClient.left;
      y1 = rcClient.bottom - cyVScroll;
      nwidth = rcClient.right;
      nheight = cyVScroll;
   }

   hPBar = CreateWindowEx( 0, PROGRESS_CLASS, NULL, WS_CHILD | WS_VISIBLE | ulStyle,
         x1, y1, nwidth, nheight,
         hParentWindow, ( HMENU ) NULL, GetModuleHandle( NULL ), NULL );

   SendMessage( hPBar, PBM_SETRANGE, 0, (MAKELPARAM( 0, hb_parni(2) )) );
   SendMessage( hPBar, PBM_SETSTEP, ( WPARAM ) 1, 0 );

   HB_RETHANDLE( hPBar );
}

/*=============================================================================
 * HWG_UPDATEPROGRESSBAR()
 * Advances progress bar by one step
 *===========================================================================*/
HB_FUNC( HWG_UPDATEPROGRESSBAR )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_STEPIT, 0, 0 );
}

/*=============================================================================
 * HWG_RESETPROGRESSBAR()
 * Resets progress bar to zero
 *===========================================================================*/
HB_FUNC( HWG_RESETPROGRESSBAR )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_SETPOS, ( WPARAM ) 0 , 0 );
}

/*=============================================================================
 * HWG_SETPROGRESSBAR()
 * Sets progress bar position
 *===========================================================================*/
HB_FUNC( HWG_SETPROGRESSBAR )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_SETPOS, ( WPARAM ) hb_parni( 2 ), 0 );
}

/*=============================================================================
 * HWG_SETRANGEPROGRESSBAR()
 * Sets progress bar range
 *===========================================================================*/
HB_FUNC( HWG_SETRANGEPROGRESSBAR )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_SETRANGE, 0, MAKELPARAM( 0, hb_parni( 2 ) ) );
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_SETSTEP, 1 , 0 );
}

/*=============================================================================
 * HWG_CREATEPANEL()
 * Creates a panel control
 *===========================================================================*/
HB_FUNC( HWG_CREATEPANEL )
{
   HWND hWndPanel;
   hWndPanel = CreateWindow( TEXT( "PANEL" ),
         NULL,
         WS_CHILD | WS_VISIBLE | SS_GRAYRECT | SS_OWNERDRAW | CCS_TOP | hb_parnl( 3 ),
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hWndPanel );
}

/*=============================================================================
 * HWG_CREATESTATIC()
 * Creates a static text control
 *===========================================================================*/
HB_FUNC( HWG_CREATESTATIC )
{
   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulExStyle =
         ( ( !HB_ISNIL( 8 ) ) ? hb_parnl( 8 ) : 0 ) | ( ( ulStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0 );
   HWND hWndCtrl = CreateWindowEx( ulExStyle,
         TEXT( "STATIC" ),
         NULL,
         WS_CHILD | WS_VISIBLE | ulStyle,
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ),
         NULL );

   HB_RETHANDLE( hWndCtrl );
}

/*=============================================================================
 * HWG_CREATEBUTTON()
 * Creates a button control
 *===========================================================================*/
HB_FUNC( HWG_CREATEBUTTON )
{
   void * hStr;
   HWND hBtn = CreateWindow( TEXT( "BUTTON" ),
         HB_PARSTR( 8, &hStr, NULL ),
         WS_CHILD | WS_VISIBLE | hb_parnl( 3 ),
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ),
         NULL );
   hb_strfree( hStr );

   HB_RETHANDLE( hBtn );
}

/*=============================================================================
 * HWG_CREATEEDIT()
 * Creates an edit control
 *===========================================================================*/
HB_FUNC( HWG_CREATEEDIT )
{
   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulStyleEx = ( ulStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0;
   HWND hWndEdit;

   if( ( ulStyle & WS_BORDER ) )
      ulStyle &= ~WS_BORDER;
   hWndEdit = CreateWindowEx( ulStyleEx,
         TEXT( "EDIT" ),
         NULL,
         WS_CHILD | WS_VISIBLE | ulStyle,
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ), GetModuleHandle( NULL ), NULL );

   if( hb_pcount() > 7 )
   {
      void * hStr;
      LPCTSTR lpText = HB_PARSTR( 8, &hStr, NULL );
      if( lpText )
         SendMessage( hWndEdit, WM_SETTEXT, 0, ( LPARAM ) lpText );
      hb_strfree( hStr );
   }

   HB_RETHANDLE( hWndEdit );
}

/*=============================================================================
 * HWG_CREATECOMBO()
 * Creates a combobox control
 *===========================================================================*/
HB_FUNC( HWG_CREATECOMBO )
{
   HWND hCombo = CreateWindow( TEXT( "COMBOBOX" ),
         TEXT( "" ),
         WS_CHILD | WS_VISIBLE | hb_parnl( 3 ),
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ),
         NULL );

   HB_RETHANDLE( hCombo );
}

/*=============================================================================
 * HWG_CREATEBROWSE()
 * Creates a browse (grid) control
 *===========================================================================*/
HB_FUNC( HWG_CREATEBROWSE )
{
   HWND hWndBrw;
   DWORD dwStyle = hb_parnl( 3 );
   void * hStr;

   hWndBrw = CreateWindowEx( ( dwStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0,
         TEXT( "HBOARD" ),
         HB_PARSTR( 8, &hStr, NULL ),
         WS_CHILD | WS_VISIBLE | dwStyle,
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ), NULL );
   hb_strfree( hStr );

   HB_RETHANDLE( hWndBrw );
}

/*=============================================================================
 * HWG_CREATEBOARD()
 * Creates a custom board control
 *===========================================================================*/
HB_FUNC( HWG_CREATEBOARD )
{
   HWND h;
   DWORD dwStyle = hb_parnl( 3 );

   h = CreateWindowEx( ( dwStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0,
         TEXT( "HBOARD" ),
         NULL,
         WS_CHILD | WS_VISIBLE | dwStyle,
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( h );
}

/*=============================================================================
 * HWG_TRACKMOUSEEVENT()
 * Tracks mouse leave events
 *===========================================================================*/
HB_FUNC( HWG_TRACKMOUSEEVENT )
{
   TRACKMOUSEEVENT tme;

   tme.cbSize = sizeof(TRACKMOUSEEVENT);
   tme.dwFlags = TME_LEAVE;
   tme.hwndTrack = (HWND) HB_PARHANDLE( 1 );
   hb_retl( TrackMouseEvent( &tme ) );
}

/*=============================================================================
 * HWG_CREATESTATUSWINDOW()
 * Creates a status bar window
 *===========================================================================*/
HB_FUNC( HWG_CREATESTATUSWINDOW )
{
   HWND hwndStatus, hwndParent = ( HWND ) HB_PARHANDLE( 1 );

   InitCommonControls(  );

   hwndStatus = CreateWindowEx( 0,
         STATUSCLASSNAME,
         NULL,
         SBARS_SIZEGRIP |
         WS_CHILD | WS_VISIBLE | WS_OVERLAPPED | WS_CLIPSIBLINGS,
         0, 0, 0, 0,
         hwndParent,
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ),
         NULL );

   HB_RETHANDLE( hwndStatus );
}

/*=============================================================================
 * HWG_INITSTATUS()
 * Initializes status bar parts
 *===========================================================================*/
HB_FUNC( HWG_INITSTATUS )
{
   HWND hParent = ( HWND ) HB_PARHANDLE( 1 );
   HWND hStatus = ( HWND ) HB_PARHANDLE( 2 );
   RECT rcClient;
   HLOCAL hloc;
   LPINT lpParts;
   int i, nWidth, j, nParts = hb_parni( 3 );
   PHB_ITEM pArray = hb_param( 4, HB_IT_ARRAY );

   hloc = LocalAlloc( LHND, sizeof( int ) * nParts );
   lpParts = ( LPINT ) LocalLock( hloc );

   if( !pArray || hb_arrayGetNI( pArray, 1 ) == 0 )
   {
      GetClientRect( hParent, &rcClient );
      nWidth = rcClient.right / nParts;
      for( i = 0; i < nParts; i++ )
      {
         lpParts[i] = nWidth;
         nWidth += nWidth;
      }
   }
   else
   {
      ULONG ul;
      nWidth = 0;
      for( ul = 1; ul <= ( ULONG ) nParts; ul++ )
      {
         j = hb_arrayGetNI( pArray, ul );
         if( ul == ( ULONG ) nParts && j == 0 )
            nWidth = -1;
         else
            nWidth += j;
         lpParts[ul - 1] = nWidth;
      }
   }

   SendMessage( hStatus, SB_SETPARTS, ( WPARAM ) nParts, ( LPARAM ) lpParts );

   LocalUnlock( hloc );
   LocalFree( hloc );
}

/*=============================================================================
 * HWG_GETNOTIFYSBPARTS()
 * Gets status bar notification part
 *===========================================================================*/
HB_FUNC( HWG_GETNOTIFYSBPARTS )
{
   hb_retnl( ( LONG ) ((( NMMOUSE * ) HB_PARHANDLE( 1 ))->dwItemSpec ) );
}

/*=============================================================================
 * HWG_ADDTOOLTIP()
 * Adds a tooltip to a control
 *===========================================================================*/
HB_FUNC( HWG_ADDTOOLTIP )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   TOOLINFO ti;
   int iStyle = 0;
   void * hStr;

   if( lToolTipBalloon )
   {
      iStyle = TTS_BALLOON;
   }

   if( !hWndTT )
      hWndTT = CreateWindow( TOOLTIPS_CLASS, NULL, WS_POPUP | TTS_ALWAYSTIP | iStyle,
            CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
            NULL, ( HMENU ) NULL, GetModuleHandle( NULL ), NULL );
   if( !hWndTT )
   {
      hb_retl( 0 );
      return;
   }
   memset( &ti, 0, sizeof( TOOLINFO ) );
   ti.cbSize = sizeof( TOOLINFO );
   ti.uFlags = TTF_SUBCLASS | TTF_IDISHWND;
   ti.hwnd = GetParent( ( HWND ) hWnd );
   ti.uId = ( UINT_PTR ) hWnd;
   ti.hinst = GetModuleHandle( NULL );
   ti.lpszText = ( LPTSTR ) HB_PARSTR( 2, &hStr, NULL );

   hb_retl( SendMessage( hWndTT, TTM_ADDTOOL, 0,
               ( LPARAM ) ( LPTOOLINFO ) & ti ) );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_DELTOOLTIP()
 * Removes a tooltip from a control
 *===========================================================================*/
HB_FUNC( HWG_DELTOOLTIP )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   TOOLINFO ti;

   if( hWndTT )
   {
      memset( &ti, 0, sizeof( TOOLINFO ) );
      ti.cbSize = sizeof( TOOLINFO );
      ti.uFlags = TTF_IDISHWND;
      ti.hwnd = GetParent( ( HWND ) hWnd );
      ti.uId = ( UINT_PTR ) hWnd;
      ti.hinst = GetModuleHandle( NULL );

      SendMessage( hWndTT, TTM_DELTOOL, 0, ( LPARAM ) ( LPTOOLINFO ) & ti );
   }
}

/*=============================================================================
 * HWG_SETTOOLTIPTITLE()
 * Sets tooltip title
 *===========================================================================*/
HB_FUNC( HWG_SETTOOLTIPTITLE )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );

   if( hWndTT )
   {
      TOOLINFO ti;
      void * hStr;

      ti.cbSize = sizeof( TOOLINFO );
      ti.uFlags = TTF_IDISHWND;
      ti.hwnd = GetParent( ( HWND ) hWnd );
      ti.uId = ( UINT_PTR ) hWnd;
      ti.hinst = GetModuleHandle( NULL );
      ti.lpszText = ( LPTSTR ) HB_PARSTR( 2, &hStr, NULL );

      hb_retl( SendMessage( hWndTT, TTM_SETTOOLINFO, 0,
                            ( LPARAM ) ( LPTOOLINFO ) & ti ) );
      hb_strfree( hStr );
   }
}

/*=============================================================================
 * HWG_CREATEUPDOWNCONTROL()
 * Creates an up-down control
 *===========================================================================*/
HB_FUNC( HWG_CREATEUPDOWNCONTROL )
{
   HB_RETHANDLE( CreateUpDownControl( WS_CHILD | WS_BORDER | WS_VISIBLE |
               hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ),
               hb_parni( 7 ), ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ),
               GetModuleHandle( NULL ), ( HWND ) HB_PARHANDLE( 8 ),
               hb_parni( 9 ), hb_parni( 10 ), hb_parni( 11 ) ) );
}

/*=============================================================================
 * HWG_SETUPDOWN()
 * Sets up-down control position
 *===========================================================================*/
HB_FUNC( HWG_SETUPDOWN )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), UDM_SETPOS, 0, hb_parnl( 2 ) );
}

/*=============================================================================
 * HWG_GETUPDOWN()
 * Gets up-down control position
 *===========================================================================*/
HB_FUNC( HWG_GETUPDOWN )
{
   hb_retnl( SendMessage( ( HWND ) HB_PARHANDLE( 1 ), UDM_GETPOS, 0, 0 ) );
}

/*=============================================================================
 * HWG_SETRANGEUPDOWN()
 * Sets up-down control range
 *===========================================================================*/
HB_FUNC( HWG_SETRANGEUPDOWN )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), UDM_SETRANGE32, hb_parnl( 2 ), hb_parnl( 3 ) );
}

/*=============================================================================
 * HWG_GETNOTIFYDELTAPOS()
 * Gets up-down notification delta position
 *===========================================================================*/
HB_FUNC( HWG_GETNOTIFYDELTAPOS )
{
   int iItem = hb_parnl( 2 ) ;
   if ( iItem < 2 )
      hb_retni( (LONG) (((NMUPDOWN *) HB_PARHANDLE( 1 ) )->iPos ) );
   else
      hb_retni( (LONG) (((NMUPDOWN *) HB_PARHANDLE( 1 ) )->iDelta ) );
}

/*=============================================================================
 * HWG_CREATEDATEPICKER()
 * Creates a date picker control
 *===========================================================================*/
HB_FUNC( HWG_CREATEDATEPICKER )
{
   HWND hCtrl;
   LONG nStyle = hb_parnl( 7 ) | WS_CHILD | WS_VISIBLE | WS_TABSTOP;

   hCtrl = CreateWindowEx( WS_EX_CLIENTEDGE, TEXT( "SYSDATETIMEPICK32" ),
         NULL, nStyle,
         hb_parni( 3 ), hb_parni( 4 ),
         hb_parni( 5 ), hb_parni( 6 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hCtrl );
}

/*=============================================================================
 * HWG_SETDATEPICKER()
 * Sets date picker value
 *===========================================================================*/
HB_FUNC( HWG_SETDATEPICKER )
{
   PHB_ITEM pDate = hb_param( 2, HB_IT_DATE );
   ULONG ulLen;
   long lSeconds = 0;

   if( pDate )
   {
      SYSTEMTIME sysTime, st;
#ifndef HARBOUR_OLD_VERSION
      int lYear, lMonth, lDay;
      int lHour, lMinute;
#else
      long lYear, lMonth, lDay;
      long lHour, lMinute;
#endif
      int lMilliseconds = 0;
#ifdef __XHARBOUR__
      double lSecond;
#else
      int lSecond;
#endif

      hb_dateDecode( hb_itemGetDL( pDate ), &lYear, &lMonth, &lDay );
      if ( hb_pcount(  ) < 3 )
      {
         GetLocalTime( &st );
         lHour = st.wHour;
         lMinute = st.wMinute;
         lSecond = st.wSecond;
      }
      else
      {
         const char * szTime =  hb_parc( 3 );
         if( szTime )
         {
            ulLen = strlen( szTime );
            if( ulLen >= 4 )
            {
               lSeconds = (LONG) hb_strVal( szTime, 2 ) * 3600 * 1000 +
                          (LONG) hb_strVal( szTime + 2, 2 ) * 60 * 1000 +
                          (LONG)(hb_strVal( szTime + 4, ulLen - 4 ) * 1000 );
            }
         }
         #ifdef __XHARBOUR__
            hb_timeDecode( lSeconds, &lHour, &lMinute, &lSecond );
         #else
            hb_timeDecode( lSeconds, &lHour, &lMinute, &lSecond, &lMilliseconds ) ;
         #endif
      }

      sysTime.wYear = ( unsigned short ) lYear;
      sysTime.wMonth = ( unsigned short ) lMonth;
      sysTime.wDay = ( unsigned short ) lDay;
      sysTime.wDayOfWeek = 0;
      sysTime.wHour = ( unsigned short ) lHour;
      sysTime.wMinute = ( unsigned short ) lMinute;
      sysTime.wSecond = (WORD)lSecond;
      sysTime.wMilliseconds = ( unsigned short ) lMilliseconds;

      SendMessage( ( HWND ) HB_PARHANDLE( 1 ), DTM_SETSYSTEMTIME, GDT_VALID,
                   ( LPARAM ) & sysTime );
   }
}

/*=============================================================================
 * HWG_SETDATEPICKERNULL()
 * Clears date picker value
 *===========================================================================*/
HB_FUNC( HWG_SETDATEPICKERNULL )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), DTM_SETSYSTEMTIME, GDT_NONE,
                ( LPARAM ) 0 );
}

/*=============================================================================
 * HWG_GETDATEPICKER()
 * Gets date picker value
 *===========================================================================*/
HB_FUNC( HWG_GETDATEPICKER )
{
   SYSTEMTIME st;
   int iret;
   WPARAM wParam = ( hb_pcount() > 1 ) ? hb_parnl( 2 ):GDT_VALID ;

   iret = SendMessage( ( HWND ) HB_PARHANDLE( 1 ), DTM_GETSYSTEMTIME,
                wParam, ( LPARAM ) & st );
   if ( wParam == GDT_VALID )
     hb_retd( st.wYear, st.wMonth, st.wDay );
   else
     hb_retni( iret );
}

/*=============================================================================
 * HWG_GETTIMEPICKER()
 * Gets time from date picker control
 *===========================================================================*/
HB_FUNC( HWG_GETTIMEPICKER )
{
   SYSTEMTIME st;
   char szTime[9];

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), DTM_GETSYSTEMTIME, 0,
                ( LPARAM ) & st );

   hb_snprintf( szTime, 9, "%02d:%02d:%02d", st.wHour, st.wMinute, st.wSecond );
   hb_retc( szTime ) ;
}

/*=============================================================================
 * HWG_CREATETABCONTROL()
 * Creates a tab control
 *===========================================================================*/
HB_FUNC( HWG_CREATETABCONTROL )
{
   HWND hTab;

   hTab = CreateWindow( WC_TABCONTROL, NULL, WS_CHILD | WS_VISIBLE | hb_parnl( 3 ),
         hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hTab );
}

/*=============================================================================
 * HWG_INITTABCONTROL()
 * Initializes tab control with items
 *===========================================================================*/
HB_FUNC( HWG_INITTABCONTROL )
{
   HWND hTab = ( HWND ) HB_PARHANDLE( 1 );
   PHB_ITEM pArr = hb_param( 2, HB_IT_ARRAY );
   int iItems = hb_parnl( 3 );
   TC_ITEM tie;
   ULONG ul, ulTabs = hb_arrayLen( pArr );

   tie.mask = TCIF_TEXT | TCIF_IMAGE;
   tie.iImage = iItems == 0 ? -1 : 0;

   for( ul = 1; ul <= ulTabs; ul++ )
   {
      void * hStr;

      tie.pszText = ( LPTSTR ) HB_ARRAYGETSTR( pArr, ul, &hStr, NULL );
      if( tie.pszText == NULL )
         tie.pszText = ( LPTSTR ) TEXT( "" );

      if( TabCtrl_InsertItem( hTab, ul - 1, &tie ) == -1 )
      {
         DestroyWindow( hTab );
         hTab = NULL;
      }
      hb_strfree( hStr );

      if( tie.iImage > -1 )
         tie.iImage++;
   }
}

/*=============================================================================
 * HWG_ADDTAB()
 * Adds a tab item
 *===========================================================================*/
HB_FUNC( HWG_ADDTAB )
{
   TC_ITEM tie;
   void * hStr;

   tie.mask = TCIF_TEXT | TCIF_IMAGE;
   tie.iImage = -1;
   tie.pszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );
   TabCtrl_InsertItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), &tie );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_ADDTABDIALOG()
 * Adds a tab item with dialog
 *===========================================================================*/
HB_FUNC( HWG_ADDTABDIALOG )
{
   TC_ITEM tie;
   void * hStr;
   HWND pWnd = ( HWND ) HB_PARHANDLE( 4 );

   tie.mask = TCIF_TEXT | TCIF_IMAGE | TCIF_PARAM;
   tie.lParam = ( LPARAM ) pWnd;
   tie.iImage = -1;
   tie.pszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );
   TabCtrl_InsertItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), &tie );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_DELETETAB()
 * Deletes a tab item
 *===========================================================================*/
HB_FUNC( HWG_DELETETAB )
{
   TabCtrl_DeleteItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) );
}

/*=============================================================================
 * HWG_GETCURRENTTAB()
 * Gets current selected tab
 *===========================================================================*/
HB_FUNC( HWG_GETCURRENTTAB )
{
   hb_retni( TabCtrl_GetCurSel( ( HWND ) HB_PARHANDLE( 1 ) ) + 1 );
}

/*=============================================================================
 * HWG_SETTABSIZE()
 * Sets tab control item size
 *===========================================================================*/
HB_FUNC( HWG_SETTABSIZE )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TCM_SETITEMSIZE, 0,
                MAKELPARAM( hb_parni( 2 ), hb_parni( 3 ) ) );
}

/*=============================================================================
 * HWG_SETTABNAME()
 * Sets tab item name
 *===========================================================================*/
HB_FUNC( HWG_SETTABNAME )
{
   TC_ITEM tie;
   void * hStr;

   tie.mask = TCIF_TEXT;
   tie.pszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );

   TabCtrl_SetItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni(2)-1, &tie );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_TAB_HITTEST()
 * Tests which tab is at a given point
 *===========================================================================*/
HB_FUNC( HWG_TAB_HITTEST )
{
   TC_HITTESTINFO ht;
   HWND hTab = ( HWND ) HB_PARHANDLE( 1 );
   int res;

   if( hb_pcount(  ) > 1 && HB_ISNUM( 2 ) && HB_ISNUM( 3 ) )
   {
      ht.pt.x = hb_parni( 2 );
      ht.pt.y = hb_parni( 3 );
   }
   else
   {
      GetCursorPos( &( ht.pt ) );
      ScreenToClient( hTab, &( ht.pt ) );
   }

   res = ( int ) SendMessage( hTab, TCM_HITTEST, 0, ( LPARAM ) & ht );

   hb_storni( ht.flags, 4 );
   hb_retni( res );
}

/*=============================================================================
 * hwg_tab_is_disabled()
 * Returns TRUE if nTab (1-based) is marked disabled
 *===========================================================================*/
static BOOL hwg_tab_is_disabled( HWND hTab, int nTab )
{
      PHB_ITEM pTabObj, pArr;

      if( !hTab || nTab <= 0 )
            return FALSE;

      pTabObj = ( PHB_ITEM ) GetWindowLongPtr( hTab, GWLP_USERDATA );
      if( !pTabObj )
            return FALSE;

      pArr = GetObjectVar( pTabObj, "ATABDISABLED" );
      if( pArr && HB_IS_ARRAY( pArr ) && hb_arrayLen( pArr ) >= ( HB_SIZE ) nTab )
            return hb_arrayGetL( pArr, nTab );

      return FALSE;
}

/*=============================================================================
 * HWG_TABSETOWNERDRAW()
 * Enables/disables TCS_OWNERDRAWFIXED at runtime
 *===========================================================================*/
HB_FUNC( HWG_TABSETOWNERDRAW )
{
      HWND hTab = ( HWND ) HB_PARHANDLE( 1 );
      BOOL lOn = hb_parl( 2 );
      LONG_PTR style;

      if( !hTab )
      {
            hb_retl( FALSE );
            return;
      }

      style = GetWindowLongPtr( hTab, GWL_STYLE );
      if( lOn )
            style |= ( LONG_PTR ) TCS_OWNERDRAWFIXED;
      else
            style &= ~( ( LONG_PTR ) TCS_OWNERDRAWFIXED );
      SetWindowLongPtr( hTab, GWL_STYLE, style );

      SetWindowPos( hTab, NULL, 0, 0, 0, 0,
                    SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED );
      InvalidateRect( hTab, NULL, TRUE );
      UpdateWindow( hTab );

      hb_retl( TRUE );
}

/*=============================================================================
 * HWG_TABFORCEREFRESH()
 * Forces immediate repaint of the tab control
 *===========================================================================*/
HB_FUNC( HWG_TABFORCEREFRESH )
{
      HWND hTab = ( HWND ) HB_PARHANDLE( 1 );
      HWND hParent;

      if( !hTab )
      {
            hb_retl( FALSE );
            return;
      }

      InvalidateRect( hTab, NULL, TRUE );

      RedrawWindow( hTab, NULL, NULL,
                    RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW | RDW_ALLCHILDREN );

      hParent = GetParent( hTab );
      if( hParent )
            RedrawWindow( hParent, NULL, NULL,
                          RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW | RDW_ALLCHILDREN );

      UpdateWindow( hTab );

      hb_retl( TRUE );
}

/*=============================================================================
 * hwg_tab_draw_disabled_captions()
 * Draw disabled tab captions in gray
 *===========================================================================*/
static void hwg_tab_draw_disabled_captions( HWND hTab, HDC hdc )
{
      int nCount, i;
      RECT rc, rcText;
      TCITEM tci;
      TCHAR szText[256];
      HFONT hFont, hOldFont = NULL;

      if( !hTab || !hdc )
            return;

      nCount = TabCtrl_GetItemCount( hTab );
      if( nCount <= 0 )
            return;

      hFont = (HFONT) SendMessage( hTab, WM_GETFONT, 0, 0 );
      if( hFont )
            hOldFont = (HFONT) SelectObject( hdc, hFont );

      SetBkMode( hdc, TRANSPARENT );

      for( i = 0; i < nCount; ++i )
      {
            if( hwg_tab_is_disabled( hTab, i + 1 ) )
            {
                  ZeroMemory( &tci, sizeof( tci ) );
                  ZeroMemory( szText, sizeof( szText ) );

                  tci.mask = TCIF_TEXT;
                  tci.pszText = szText;
                  tci.cchTextMax = (int)( sizeof( szText ) / sizeof( TCHAR ) ) - 1;

                  if( TabCtrl_GetItem( hTab, i, &tci ) )
                  {
                        if( TabCtrl_GetItemRect( hTab, i, &rc ) )
                        {
                              rcText = rc;
                              rcText.left  += 6;
                              rcText.right -= 6;
                              rcText.top   += 2;
                              rcText.bottom-= 2;

                              FillRect( hdc, &rcText, GetSysColorBrush( COLOR_BTNFACE ) );

                              {
                                    COLORREF oldColor = SetTextColor( hdc, RGB( 180, 180, 180 ) );

                                    DrawText( hdc, szText, -1, &rcText,
                                              DT_SINGLELINE | DT_VCENTER | DT_CENTER | DT_END_ELLIPSIS );

                                    SetTextColor( hdc, oldColor );
                              }
                        }
                  }
            }
      }

      if( hOldFont )
            SelectObject( hdc, hOldFont );
}

/*=============================================================================
 * HWG_GETNOTIFYKEYDOWN()
 * Gets key down notification
 *===========================================================================*/
HB_FUNC( HWG_GETNOTIFYKEYDOWN )
{
   hb_retni( ( WORD ) ( ( ( TC_KEYDOWN * ) HB_PARHANDLE( 1 ) )->wVKey ) );
}

/*=============================================================================
 * HWG_CREATETREE()
 * Creates a tree view control
 *===========================================================================*/
HB_FUNC( HWG_CREATETREE )
{
   HWND hCtrl;

   hCtrl = CreateWindowEx( WS_EX_CLIENTEDGE, WC_TREEVIEW, 0,
         WS_CHILD | WS_VISIBLE | WS_TABSTOP | hb_parnl( 3 ),
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ), NULL );

   if( !HB_ISNIL( 8 ) )
      SendMessage( hCtrl, TVM_SETTEXTCOLOR, 0, ( LPARAM ) ( hb_parnl( 8 ) ) );
   if( !HB_ISNIL( 9 ) )
      SendMessage( hCtrl, TVM_SETBKCOLOR, 0, ( LPARAM ) ( hb_parnl( 9 ) ) );

   HB_RETHANDLE( hCtrl );
}

/*=============================================================================
 * HWG_TREEADDNODE()
 * Adds a node to tree view
 *===========================================================================*/
HB_FUNC( HWG_TREEADDNODE )
{
   TV_ITEM tvi;
   TV_INSERTSTRUCT is;

   int nPos = hb_parni( 5 );
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
   void * hStr;

   tvi.iImage = 0;
   tvi.iSelectedImage = 0;

   tvi.mask = TVIF_TEXT | TVIF_PARAM;
   tvi.pszText = ( LPTSTR ) HB_PARSTR( 6, &hStr, NULL );
   tvi.lParam = ( LPARAM ) ( hb_itemNew( pObject ) );
   if( hb_pcount(  ) > 6 && !HB_ISNIL( 7 ) )
   {
      tvi.iImage = hb_parni( 7 );
      tvi.mask |= TVIF_IMAGE;
      if( hb_pcount(  ) > 7 && !HB_ISNIL( 8 ) )
      {
         tvi.iSelectedImage = hb_parni( 8 );
         tvi.mask |= TVIF_SELECTEDIMAGE;
      }
   }

#if !defined(__BORLANDC__) ||  (__BORLANDC__ > 1424)
   is.item = tvi;
#else
   is.DUMMYUNIONNAME.item = tvi;
#endif

   is.hParent = ( HB_ISNIL( 3 ) ? NULL : ( HTREEITEM ) HB_PARHANDLE( 3 ) );
   if( nPos == 0 )
      is.hInsertAfter = ( HTREEITEM ) HB_PARHANDLE( 4 );
   else if( nPos == 1 )
      is.hInsertAfter = TVI_FIRST;
   else if( nPos == 2 )
      is.hInsertAfter = TVI_LAST;

   HB_RETHANDLE( SendMessage( ( HWND ) HB_PARHANDLE( 2 ), TVM_INSERTITEM, 0,
               ( LPARAM ) ( &is ) ) );

   if( tvi.mask & TVIF_IMAGE )
      if ( tvi.iImage )
         DeleteObject( ( HGDIOBJ ) ( UINT_PTR ) tvi.iImage );
   if( tvi.mask & TVIF_SELECTEDIMAGE )
      if ( tvi.iSelectedImage )
         DeleteObject( ( HGDIOBJ ) ( UINT_PTR ) tvi.iSelectedImage );

   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_TREEGETSELECTED()
 * Gets selected tree node
 *===========================================================================*/
HB_FUNC( HWG_TREEGETSELECTED )
{
   TV_ITEM TreeItem;

   memset( &TreeItem, 0, sizeof( TV_ITEM ) );
   TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
   TreeItem.hItem = TreeView_GetSelection( ( HWND ) HB_PARHANDLE( 1 ) );

   if( TreeItem.hItem )
   {
      PHB_ITEM oNode;
      SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TVM_GETITEM, 0,
            ( LPARAM ) ( &TreeItem ) );
      oNode = ( PHB_ITEM ) TreeItem.lParam;
      hb_itemReturn( oNode );
   }
}

/*=============================================================================
 * HWG_TREEGETNODETEXT()
 * Gets tree node text
 *===========================================================================*/
HB_FUNC( HWG_TREEGETNODETEXT )
{
   TV_ITEM TreeItem;
   TCHAR ItemText[256] = { 0 };

   memset( &TreeItem, 0, sizeof( TV_ITEM ) );
   TreeItem.mask = TVIF_HANDLE | TVIF_TEXT;
   TreeItem.hItem = ( HTREEITEM ) HB_PARHANDLE( 2 );
   TreeItem.pszText = ItemText;
   TreeItem.cchTextMax = 256;

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TVM_GETITEM, 0,
                ( LPARAM ) ( &TreeItem ) );
   HB_RETSTR( TreeItem.pszText );
}

#define TREE_SETITEM_TEXT       1
#define TREE_SETITEM_CHECK      2

/*=============================================================================
 * HWG_TREESETITEM()
 * Sets tree item properties
 *===========================================================================*/
HB_FUNC( HWG_TREESETITEM )
{
   TV_ITEM TreeItem;
   int iType = hb_parni( 3 );
   void * hStr = NULL;

   memset( &TreeItem, 0, sizeof( TV_ITEM ) );
   TreeItem.mask = TVIF_HANDLE;
   TreeItem.hItem = ( HTREEITEM ) HB_PARHANDLE( 2 );

   if( iType == TREE_SETITEM_TEXT )
   {
      TreeItem.mask |= TVIF_TEXT;
      TreeItem.pszText = ( LPTSTR ) HB_PARSTR( 4, &hStr, NULL );
   }
   if( iType == TREE_SETITEM_CHECK )
   {
      TreeItem.mask |= TVIF_STATE;
      TreeItem.stateMask = TVIS_STATEIMAGEMASK;
      TreeItem.state =  hb_parni( 4 ) ;
      TreeItem.state = TreeItem.state << 12;
   }

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TVM_SETITEM, 0,
                ( LPARAM ) ( &TreeItem ) );
   hb_strfree( hStr );
}

#define TREE_GETNOTIFY_HANDLE       1
#define TREE_GETNOTIFY_PARAM        2
#define TREE_GETNOTIFY_EDIT         3
#define TREE_GETNOTIFY_EDITPARAM    4
#define TREE_GETNOTIFY_ACTION       5
#define TREE_GETNOTIFY_OLDPARAM     6

/*=============================================================================
 * HWG_TREEGETNOTIFY()
 * Gets tree notification data
 *===========================================================================*/
HB_FUNC( HWG_TREEGETNOTIFY )
{
   int iType = hb_parni( 2 );

   if( iType == TREE_GETNOTIFY_HANDLE )
      HB_RETHANDLE( ( HTREEITEM  ) ( ( ( NM_TREEVIEW * ) HB_PARHANDLE( 1 ) )->itemNew.
                  hItem ) );

   if( iType == TREE_GETNOTIFY_ACTION )
      hb_retni( ( UINT ) ( ( ( NM_TREEVIEW * ) HB_PARHANDLE( 1 ) )->
                  action ) );

   else if( iType == TREE_GETNOTIFY_PARAM ||
         iType == TREE_GETNOTIFY_EDITPARAM || iType == TREE_GETNOTIFY_OLDPARAM )
   {
      PHB_ITEM oNode;
      if( iType == TREE_GETNOTIFY_EDITPARAM )
         oNode =
               ( PHB_ITEM ) ( ( ( TV_DISPINFO * ) HB_PARHANDLE( 1 ) )->item.
               lParam );
      else if( iType == TREE_GETNOTIFY_OLDPARAM )
            oNode =
               ( PHB_ITEM ) ( ( ( NM_TREEVIEW * ) HB_PARHANDLE( 1 ) )->
               itemOld.lParam );
      else
         oNode =
               ( PHB_ITEM ) ( ( ( NM_TREEVIEW * ) HB_PARHANDLE( 1 ) )->
               itemNew.lParam );

      hb_itemReturn( oNode );

   }
   else if( iType == TREE_GETNOTIFY_EDIT )
   {
      TV_DISPINFO *tv;
      tv = ( TV_DISPINFO * ) HB_PARHANDLE( 1 );

      HB_RETSTR( ( tv->item.pszText ) ? tv->item.pszText : TEXT( "" ) );
   }
}

/*=============================================================================
 * HWG_TREEHITTEST()
 * Tests which node is at a given point
 *===========================================================================*/
HB_FUNC( HWG_TREEHITTEST )
{
   TV_HITTESTINFO ht;
   HWND hTree = ( HWND ) HB_PARHANDLE( 1 );

   if( hb_pcount(  ) > 1 && HB_ISNUM( 2 ) && HB_ISNUM( 3 ) )
   {
      ht.pt.x = hb_parni( 2 );
      ht.pt.y = hb_parni( 3 );
   }
   else
   {
      GetCursorPos( &( ht.pt ) );
      ScreenToClient( hTree, &( ht.pt ) );
   }

   SendMessage( hTree, TVM_HITTEST, 0, ( LPARAM ) & ht );

   if( ht.hItem )
   {
      PHB_ITEM oNode;
      TV_ITEM TreeItem;

      memset( &TreeItem, 0, sizeof( TV_ITEM ) );
      TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
      TreeItem.hItem = ht.hItem;

      SendMessage( hTree, TVM_GETITEM, 0, ( LPARAM ) ( &TreeItem ) );
      oNode = ( PHB_ITEM ) TreeItem.lParam;
      hb_itemReturn( oNode );
      if( hb_pcount(  ) > 3 )
         hb_storni( ( int ) ht.flags, 4 );
   }
   else
      hb_ret(  );
}

/*=============================================================================
 * HWG_TREERELEASENODE()
 * Releases a tree node
 *===========================================================================*/
HB_FUNC( HWG_TREERELEASENODE )
{
   TV_ITEM TreeItem;

   memset( &TreeItem, 0, sizeof( TV_ITEM ) );
   TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
   TreeItem.hItem = ( HTREEITEM ) HB_PARHANDLE( 2 );

   if( TreeItem.hItem )
   {
      SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TVM_GETITEM, 0,
            ( LPARAM ) ( &TreeItem ) );
      hb_itemRelease( ( PHB_ITEM ) TreeItem.lParam );
      TreeItem.lParam = 0;
      SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TVM_SETITEM, 0,
            ( LPARAM ) ( &TreeItem ) );
   }
}

/*=============================================================================
 * HWG_CREATEIMAGELIST()
 * Creates an image list
 *===========================================================================*/
HB_FUNC( HWG_CREATEIMAGELIST )
{
   PHB_ITEM pArray = hb_param( 1, HB_IT_ARRAY );
   UINT flags = ( HB_ISNIL( 5 ) ) ? ILC_COLOR : hb_parni( 5 );
   HIMAGELIST himl;
   ULONG ul, ulLen = hb_arrayLen( pArray );
   HBITMAP hbmp;

   himl = ImageList_Create( hb_parni( 2 ), hb_parni( 3 ), flags,
         ulLen, hb_parni( 4 ) );

   for( ul = 1; ul <= ulLen; ul++ )
   {
      hbmp = ( HBITMAP ) HB_GETPTRHANDLE( pArray, ul );
      ImageList_Add( himl, hbmp, ( HBITMAP ) NULL );
      DeleteObject( hbmp );
   }

   HB_RETHANDLE( himl );
}

/*=============================================================================
 * HWG_IMAGELIST_ADD()
 * Adds bitmap to image list
 *===========================================================================*/
HB_FUNC( HWG_IMAGELIST_ADD )
{
   hb_retnl( ImageList_Add( ( HIMAGELIST ) HB_PARHANDLE( 1 ),
               ( HBITMAP ) HB_PARHANDLE( 2 ), ( HBITMAP ) NULL ) );
}

/*=============================================================================
 * HWG_IMAGELIST_ADDMASKED()
 * Adds masked bitmap to image list
 *===========================================================================*/
HB_FUNC( HWG_IMAGELIST_ADDMASKED )
{
   hb_retnl( ImageList_AddMasked( ( HIMAGELIST ) HB_PARHANDLE( 1 ),
               ( HBITMAP ) HB_PARHANDLE( 2 ), ( COLORREF ) hb_parnl( 3 ) ) );
}

/*=============================================================================
 * HWG_DESTROYIMAGELIST()
 * Destroys an image list
 *===========================================================================*/
HB_FUNC( HWG_DESTROYIMAGELIST )
{
   HIMAGELIST h = ( HIMAGELIST ) HB_PARHANDLE( 1 );
   ImageList_Destroy( h );
}

/*=============================================================================
 * HWG_SETTIMER()
 * Sets a timer
 *===========================================================================*/
HB_FUNC( HWG_SETTIMER )
{
   SetTimer( ( HWND ) HB_PARHANDLE( 1 ), ( UINT ) hb_parni( 2 ),
             ( UINT ) hb_parni( 3 ),
             hb_pcount() == 3 ?  ( TIMERPROC ) ( UINT_PTR ) s_timerProc : ( TIMERPROC ) ( UINT_PTR )  NULL );
}

/*=============================================================================
 * HWG_KILLTIMER()
 * Kills a timer
 *===========================================================================*/
HB_FUNC( HWG_KILLTIMER )
{
   hb_retl( KillTimer( ( HWND ) HB_PARHANDLE( 1 ), ( UINT ) hb_parni( 2 ) ) );
}

/*=============================================================================
 * HWG_GETPARENT()
 * Gets parent window
 *===========================================================================*/
HB_FUNC( HWG_GETPARENT )
{
   HB_RETHANDLE( GetParent( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_GETANCESTOR()
 * Gets ancestor window
 *===========================================================================*/
HB_FUNC( HWG_GETANCESTOR )
{
   HB_RETHANDLE( GetAncestor( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) ) );
}

/*=============================================================================
 * HWG_LOADCURSOR()
 * Loads a cursor
 *===========================================================================*/
HB_FUNC( HWG_LOADCURSOR )
{
   void * hStr;
   LPCTSTR lpStr = HB_PARSTR( 1, &hStr, NULL );

   if( lpStr )
      HB_RETHANDLE( LoadCursor( GetModuleHandle( NULL ), lpStr ) );
   else
      HB_RETHANDLE( LoadCursor( NULL, MAKEINTRESOURCE( hb_parni( 1 ) ) ) );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_LOADCURSORFROMFILE()
 * Loads a cursor from file
 *===========================================================================*/
HB_FUNC( HWG_LOADCURSORFROMFILE )
{
   void * hStr;
   HCURSOR hCursor;

   LPCTSTR ccurFname = HB_PARSTR( 1, &hStr, NULL );

   hCursor = LoadCursorFromFile(ccurFname);
   if (hCursor == NULL )
      HB_RETHANDLE( LoadCursor( NULL, IDC_ARROW ) );
   else
      HB_RETHANDLE(hCursor);

   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_SETCURSOR()
 * Sets cursor
 *===========================================================================*/
HB_FUNC( HWG_SETCURSOR )
{
   HB_RETHANDLE( SetCursor( ( HCURSOR ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_GETCURSOR()
 * Gets cursor
 *===========================================================================*/
HB_FUNC( HWG_GETCURSOR )
{
   HB_RETHANDLE( GetCursor() );
}

/*=============================================================================
 * HWG_GETTOOLTIPHANDLE()
 * Gets tooltip window handle
 *===========================================================================*/
HB_FUNC( HWG_GETTOOLTIPHANDLE )
{
   HB_RETHANDLE( hWndTT );
}

/*=============================================================================
 * HWG_SETTOOLTIPBALLOON()
 * Sets tooltip balloon style
 *===========================================================================*/
HB_FUNC( HWG_SETTOOLTIPBALLOON )
{
   lToolTipBalloon = hb_parl( 1 );
   hWndTT = 0;
}

/*=============================================================================
 * HWG_GETTOOLTIPBALLOON()
 * Gets tooltip balloon style
 *===========================================================================*/
HB_FUNC( HWG_GETTOOLTIPBALLOON )
{
   hb_retl( lToolTipBalloon );
}

/*=============================================================================
 * HWG_REGPANEL()
 * Registers panel window class
 *===========================================================================*/
HB_FUNC( HWG_REGPANEL )
{
   static BOOL bRegistered = FALSE;

   if( !bRegistered )
   {
      WNDCLASS wndclass;

      wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
      wndclass.lpfnWndProc = DefWindowProc;
      wndclass.cbClsExtra = 0;
      wndclass.cbWndExtra = 0;
      wndclass.hInstance = GetModuleHandle( NULL );
      wndclass.hIcon = NULL;
      wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
      wndclass.hbrBackground = ( HBRUSH ) ( COLOR_3DFACE + 1 );
      wndclass.lpszMenuName = NULL;
      wndclass.lpszClassName = TEXT( "PANEL" );

      RegisterClass( &wndclass );
      bRegistered = TRUE;
   }
}

/*=============================================================================
 * hwg_regboard()
 * Registers board (HBOARD) window class
 *===========================================================================*/
void hwg_regboard( void )
{
   static BOOL bRegistered = FALSE;

   WNDCLASS wndclass;

   if( !bRegistered )
   {
      wndclass.style = CS_DBLCLKS;
      wndclass.lpfnWndProc = WinCtrlProc;
      wndclass.cbClsExtra = 0;
      wndclass.cbWndExtra = 0;
      wndclass.hInstance = GetModuleHandle( NULL );
      wndclass.hIcon = NULL;
      wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
      wndclass.hbrBackground = NULL;
      wndclass.lpszMenuName = NULL;
      wndclass.lpszClassName = TEXT( "HBOARD" );

      RegisterClass( &wndclass );
      bRegistered = TRUE;
   }
}

/*=============================================================================
 * HWG_REGBOARD()
 * Registers board (HBOARD) window class
 *===========================================================================*/
HB_FUNC( HWG_REGBOARD )
{
   hwg_regboard();
}

/*=============================================================================
 * s_timerProc()
 * Timer callback procedure
 *===========================================================================*/
static void CALLBACK s_timerProc( HWND hWnd, UINT message, UINT idTimer, DWORD dwTime )
{
   static PHB_DYNS s_pSymTest = NULL;

   HB_SYMBOL_UNUSED( message );
   HB_SYMBOL_UNUSED( dwTime );

   if( s_pSymTest == NULL )
      s_pSymTest = hb_dynsymGetCase( "HWG_TIMERPROC" );

   if( hb_dynsymIsFunction( s_pSymTest ) )
   {
      hb_vmPushDynSym( s_pSymTest );
      hb_vmPushNil();
      HB_PUSHITEM( hWnd );
      hb_vmPushLong( ( LONG ) idTimer );
      hb_vmDo( 2 );
   }
}

/*=============================================================================
 * HWG_INITTREEVIEW()
 * Subclasses tree view control
 *===========================================================================*/
HB_FUNC( HWG_INITTREEVIEW )
{
   wpOrigTreeViewProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) TreeViewSubclassProc );
}

/*=============================================================================
 * TreeViewSubclassProc()
 * Tree view subclass procedure
 *===========================================================================*/
LRESULT APIENTRY TreeViewSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return (LRESULT) HB_PARHANDLE( -1 );
      else
      {
         res = hb_parnl( -1 );
         if( res == -1 )
            return ( CallWindowProc( wpOrigTreeViewProc, hWnd, message, wParam,
                        lParam ) );
         else
            return res;
      }
   }
   else
      return ( CallWindowProc( wpOrigTreeViewProc, hWnd, message, wParam,
                  lParam ) );
}

/*=============================================================================
 * HWG_INITWINCTRL()
 * Subclasses window control
 *===========================================================================*/
HB_FUNC( HWG_INITWINCTRL )
{
   SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) WinCtrlProc );
}

/*=============================================================================
 * WinCtrlProc()
 * Window control procedure
 *===========================================================================*/
LRESULT CALLBACK WinCtrlProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return (LRESULT) HB_PARHANDLE( -1 );
      else
      {
         res = hb_parnl( -1 );
         if( res == -1 )
            return ( DefWindowProc( hWnd, message, wParam, lParam ) );
         else
            return res;
      }
   }
   else
      return ( DefWindowProc( hWnd, message, wParam, lParam ) );
}

/*=============================================================================
 * HWG_INITSTATICPROC()
 * Subclasses static control
 *===========================================================================*/
HB_FUNC( HWG_INITSTATICPROC )
{
   wpOrigStaticProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) StaticSubclassProc );
}

/*=============================================================================
 * StaticSubclassProc()
 * Static control subclass procedure
 *===========================================================================*/
LRESULT APIENTRY StaticSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return (LRESULT) HB_PARHANDLE( -1 );
      else
      {
         res = hb_parnl( -1 );
         if( res == -1 )
            return ( CallWindowProc( wpOrigStaticProc, hWnd, message, wParam,
                        lParam ) );
         else
            return res;
      }
   }
   else
      return ( CallWindowProc( wpOrigStaticProc, hWnd, message, wParam,
                  lParam ) );
}

/*=============================================================================
 * HWG_INITEDITPROC()
 * Subclasses edit control
 *===========================================================================*/
HB_FUNC( HWG_INITEDITPROC )
{
   wpOrigEditProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) EditSubclassProc );
}

/*=============================================================================
 * EditSubclassProc()
 * Edit control subclass procedure
 *===========================================================================*/
LRESULT APIENTRY EditSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return (LRESULT) HB_PARHANDLE( -1 );
      else
      {
         res = hb_parnl( -1 );
         if( res == -1 )
            return ( CallWindowProc( wpOrigEditProc, hWnd, message, wParam,
                        lParam ) );
         else
            return res;
      }
   }
   else
      return ( CallWindowProc( wpOrigEditProc, hWnd, message, wParam,
                  lParam ) );
}

/*=============================================================================
 * HWG_INITBUTTONPROC()
 * Subclasses button control
 *===========================================================================*/
HB_FUNC( HWG_INITBUTTONPROC )
{
   wpOrigButtonProc =
         ( LONG_PTR ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) ButtonSubclassProc );
}

/*=============================================================================
 * ButtonSubclassProc()
 * Button control subclass procedure
 *===========================================================================*/
LRESULT APIENTRY ButtonSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return (LRESULT) HB_PARHANDLE( -1 );
      else
      {
         res = hb_parnl( -1 );
         if( res == -1 )
            return ( CallWindowProc( ( WNDPROC ) wpOrigButtonProc, hWnd, message,
                        wParam, lParam ) );
         else
            return res;
      }
   }
   else
      return ( CallWindowProc( ( WNDPROC ) wpOrigButtonProc, hWnd, message,
                  wParam, lParam ) );
}

/*=============================================================================
 * ListSubclassProc()
 * List control subclass procedure
 *===========================================================================*/
LRESULT APIENTRY ListSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return (LRESULT) HB_PARHANDLE( -1 );
      else
      {
         res = hb_parnl( -1 );
         if( res == -1 )
            return ( CallWindowProc( wpOrigListProc, hWnd, message, wParam,
                        lParam ) );
         else
            return res;
      }
   }
   else
      return ( CallWindowProc( wpOrigListProc, hWnd, message, wParam,
                  lParam ) );
}

/*=============================================================================
 * HWG_INITLISTPROC()
 * Subclasses list control
 *===========================================================================*/
HB_FUNC( HWG_INITLISTPROC )
{
   wpOrigListProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) ListSubclassProc );
}

/*=============================================================================
 * HWG_INITUPDOWNPROC()
 * Subclasses up-down control
 *===========================================================================*/
HB_FUNC( HWG_INITUPDOWNPROC )
{
   wpOrigUpDownProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) UpDownSubclassProc );
}

/*=============================================================================
 * UpDownSubclassProc()
 * Up-down control subclass procedure
 *===========================================================================*/
LRESULT APIENTRY UpDownSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return (LRESULT) HB_PARHANDLE( -1 );
      else
      {
         res = hb_parnl( -1 );
         if( res == -1 )
            return ( CallWindowProc( wpOrigUpDownProc, hWnd, message, wParam,
                        lParam ) );
         else
            return res;
      }
   }
   else
      return ( CallWindowProc( wpOrigUpDownProc, hWnd, message, wParam,
                  lParam ) );
}

/*=============================================================================
 * HWG_INITDATEPICKERPROC()
 * Subclasses date picker control
 *===========================================================================*/
HB_FUNC( HWG_INITDATEPICKERPROC )
{
   wpOrigDatePickerProc =
         ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ), GWLP_WNDPROC,
         ( LONG_PTR ) DatePickerSubclassProc );
}

/*=============================================================================
 * DatePickerSubclassProc()
 * Date picker control subclass procedure
 *===========================================================================*/
LRESULT APIENTRY DatePickerSubclassProc( HWND hWnd, UINT message,
      WPARAM wParam, LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return (LRESULT) HB_PARHANDLE( -1 );
      else
      {
         res = hb_parnl( -1 );
         if( res == -1 )
            return ( CallWindowProc( wpOrigDatePickerProc, hWnd, message, wParam,
                        lParam ) );
         else
            return res;
      }
   }
   else
      return ( CallWindowProc( wpOrigDatePickerProc, hWnd, message, wParam,
                  lParam ) );
}

/*=============================================================================
 * HWG_INITTRACKPROC()
 * Subclasses trackbar control
 *===========================================================================*/
HB_FUNC( HWG_INITTRACKPROC )
{
   wpOrigTrackProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) TrackSubclassProc );
}

/*=============================================================================
 * TrackSubclassProc()
 * Trackbar control subclass procedure
 *===========================================================================*/
LRESULT APIENTRY TrackSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return (LRESULT) HB_PARHANDLE( -1 );
      else
      {
         res = hb_parnl( -1 );
         if( res == -1 )
            return ( CallWindowProc( wpOrigTrackProc, hWnd, message, wParam,
                        lParam ) );
         else
            return res;
      }
   }
   else
      return ( CallWindowProc( wpOrigTrackProc, hWnd, message, wParam,
                  lParam ) );
}

/*=============================================================================
 * HWG_INITTABPROC()
 * Subclasses tab control
 *===========================================================================*/
HB_FUNC( HWG_INITTABPROC )
{
   wpOrigTabProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) TabSubclassProc );
}

/*=============================================================================
 * TabSubclassProc()
 * Tab control subclass procedure with disabled tab support
 *===========================================================================*/
LRESULT APIENTRY TabSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   /* Click suppression on disabled tabs */
   if( message == WM_LBUTTONDOWN || message == WM_LBUTTONDBLCLK || message == WM_LBUTTONUP )
   {
         TCHITTESTINFO ht;
         int iTab;

         ht.pt.x = GET_X_LPARAM( lParam );
         ht.pt.y = GET_Y_LPARAM( lParam );
         ht.flags = 0;
         iTab = TabCtrl_HitTest( hWnd, &ht );

         /* 1) If the tab is inactive: consume and does NOT steal focus */
         if( iTab >= 0 && hwg_tab_is_disabled( hWnd, iTab + 1 ) )
               return 0;

         /* 2) If the already active tab was clicked: consume to avoid stealing focus */
         if( iTab >= 0 )
         {
               int iCur = TabCtrl_GetCurSel( hWnd );
               if( iCur == iTab )
                     return 0;
         }
   }

   /* Paint hook: overlay disabled captions in gray */
   if( message == WM_PAINT )
   {
         PAINTSTRUCT ps;
         HDC hdc = BeginPaint( hWnd, &ps );

         if( hdc )
         {
               RECT rc;
               HDC hdcMem;
               HBITMAP hbmMem;
               HBITMAP hbmOld;

               GetClientRect( hWnd, &rc );

               hdcMem = CreateCompatibleDC( hdc );
               hbmMem = CreateCompatibleBitmap( hdc, rc.right - rc.left, rc.bottom - rc.top );
               hbmOld = ( HBITMAP ) SelectObject( hdcMem, hbmMem );

               CallWindowProc( wpOrigTabProc, hWnd, WM_PRINTCLIENT, ( WPARAM ) hdcMem,
                               ( LPARAM ) ( PRF_CLIENT | PRF_ERASEBKGND ) );

               hwg_tab_draw_disabled_captions( hWnd, hdcMem );

               BitBlt( hdc, 0, 0, rc.right - rc.left, rc.bottom - rc.top, hdcMem, 0, 0, SRCCOPY );

               SelectObject( hdcMem, hbmOld );
               DeleteObject( hbmMem );
               DeleteDC( hdcMem );

               EndPaint( hWnd, &ps );
         }
         return 0;
   }

   else if( message == WM_PRINTCLIENT )
   {
         LRESULT lr = CallWindowProc( wpOrigTabProc, hWnd, message, wParam, lParam );
         if( ( HDC ) wParam )
               hwg_tab_draw_disabled_captions( hWnd, ( HDC ) wParam );
         return lr;
   }

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return (LRESULT) HB_PARHANDLE( -1 );
      else
      {
         res = hb_parnl( -1 );
         if( res == -1 )
            return ( CallWindowProc( wpOrigTabProc, hWnd, message, wParam,
                        lParam ) );
         else
            return res;
      }
   }
   else
      return ( CallWindowProc( wpOrigTabProc, hWnd, message, wParam,
                  lParam ) );
}

/*=============================================================================
 * HWG_CREATETOOLBAR()
 * Creates a toolbar control
 *===========================================================================*/
HB_FUNC( HWG_CREATETOOLBAR )
{
   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulExStyle =
         ( ( !HB_ISNIL( 8 ) ) ? hb_parnl( 8 ) : 0 ) | ( ( ulStyle & WS_BORDER ) ?
         WS_EX_CLIENTEDGE : 0 );

   HWND hWndCtrl = CreateWindowEx( ulExStyle,
         TOOLBARCLASSNAME,
         NULL,
         WS_CHILD | WS_OVERLAPPED | WS_VISIBLE | TBSTYLE_ALTDRAG | TBSTYLE_TOOLTIPS |  TBSTYLE_WRAPABLE | CCS_TOP | CCS_NORESIZE | ulStyle,
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ),
         NULL );

   HB_RETHANDLE( hWndCtrl );
}

/*=============================================================================
 * HWG_TOOLBARADDBUTTONS()
 * Adds buttons to toolbar
 *===========================================================================*/
HB_FUNC( HWG_TOOLBARADDBUTTONS )
{
      HWND hWndCtrl = ( HWND ) HB_PARHANDLE( 1 );
      PHB_ITEM pArray = hb_param( 2, HB_IT_ARRAY );
      int iButtons = hb_parni( 3 );
      TBBUTTON *tb =
      ( struct _TBBUTTON * ) hb_xgrab( iButtons * sizeof( TBBUTTON ) );
      PHB_ITEM pTemp;
      ULONG ulCount, ulID;   // <-- ADICIONADO: ulID declarado aqui
      DWORD style = GetWindowLong( hWndCtrl, GWL_STYLE );

      SetWindowLongPtr( hWndCtrl, GWL_STYLE,
                        style | TBSTYLE_TOOLTIPS | TBSTYLE_FLAT );

      SendMessage( hWndCtrl, TB_BUTTONSTRUCTSIZE, sizeof( TBBUTTON ), 0L );

      for( ulCount = 0; ( ulCount < hb_arrayLen( pArray ) ); ulCount++ )
      {
            pTemp = hb_arrayGetItemPtr( pArray, ulCount + 1 );
            ulID = hb_arrayGetNI( pTemp, 1 );
            if ( hb_arrayGetNI( pTemp, 4 ) == TBSTYLE_SEP )
                  tb[ulCount].iBitmap = 8 ;
            else
                  tb[ulCount].iBitmap = ulID - 1;
            tb[ulCount].idCommand = hb_arrayGetNI( pTemp, 2 );
            tb[ulCount].fsState = (BYTE)hb_arrayGetNI( pTemp, 3 );
            tb[ulCount].fsStyle = (BYTE)hb_arrayGetNI( pTemp, 4 );
            tb[ulCount].dwData = hb_arrayGetNI( pTemp, 5 );
            tb[ulCount].iString =
            hb_arrayGetCLen( pTemp, 6 ) > 0 ? ( INT_PTR ) hb_arrayGetCPtr( pTemp,
                                                                           6 ) : 0;
      }

      SendMessage( hWndCtrl, TB_ADDBUTTONS, ( WPARAM ) iButtons,
                   ( LPARAM ) ( LPTBBUTTON ) tb );
      SendMessage( hWndCtrl, TB_AUTOSIZE, 0, 0 );

      hb_xfree( tb );
}

/*=============================================================================
 * HWG_TOOLBAR_SETBUTTONINFO()
 * Sets toolbar button info
 *===========================================================================*/
HB_FUNC( HWG_TOOLBAR_SETBUTTONINFO )
{
   TBBUTTONINFO tb;
   HWND hWndCtrl = ( HWND ) HB_PARHANDLE( 1 );
   int iIDB = hb_parni( 2 );
   void * hStr;

   tb.cbSize = sizeof( tb );
   tb.dwMask = TBIF_TEXT;
   tb.pszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );

   SendMessage( hWndCtrl, TB_SETBUTTONINFO, iIDB, ( LPARAM ) & tb );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_TOOLBAR_LOADIMAGE()
 * Loads bitmap into toolbar
 *===========================================================================*/
HB_FUNC( HWG_TOOLBAR_LOADIMAGE )
{
   TBADDBITMAP tbab;
   HWND hWndCtrl = ( HWND ) HB_PARHANDLE( 1 );

   tbab.hInst = NULL;
   if ( HB_ISPOINTER( 2 ) )
      tbab.nID = ( UINT_PTR ) hb_parptr( 2 );
   else
      tbab.nID = ( UINT_PTR ) hb_parni( 2 );

   SendMessage( hWndCtrl, TB_ADDBITMAP, 0, ( LPARAM ) & tbab );
}

/*=============================================================================
 * HWG_TOOLBAR_LOADSTANDARTIMAGE()
 * Loads standard image into toolbar
 *===========================================================================*/
HB_FUNC( HWG_TOOLBAR_LOADSTANDARTIMAGE )
{
   TBADDBITMAP tbab;
   HWND hWndCtrl = ( HWND ) HB_PARHANDLE( 1 );
   int iIDB = hb_parni( 2 );
   HIMAGELIST himl;

   tbab.hInst = HINST_COMMCTRL;
   tbab.nID = iIDB;

   SendMessage( hWndCtrl, TB_ADDBITMAP, 0, ( LPARAM ) & tbab );
   himl = ( HIMAGELIST ) SendMessage( hWndCtrl, TB_GETIMAGELIST, 0, 0 );
   hb_retni( ( int ) ImageList_GetImageCount( himl ) );
}

/*=============================================================================
 * HWG_IMAGELIST_GETIMAGECOUNT()
 * Gets image count from image list
 *===========================================================================*/
HB_FUNC( HWG_IMAGELIST_GETIMAGECOUNT )
{
   HIMAGELIST hWndCtrl = ( HIMAGELIST ) HB_PARHANDLE( 1 );
   hb_retni( ImageList_GetImageCount( hWndCtrl ) );
}

/*=============================================================================
 * HWG_TOOLBAR_SETDISPINFO()
 * Sets toolbar display info
 *===========================================================================*/
HB_FUNC( HWG_TOOLBAR_SETDISPINFO )
{
   LPNMTTDISPINFO pDispInfo = ( LPNMTTDISPINFO ) HB_PARHANDLE( 1 );

   if( pDispInfo )
   {
      HB_ITEMCOPYSTR( hb_param( 2, HB_IT_ANY ), pDispInfo->szText,
                      HB_SIZEOFARRAY( pDispInfo->szText ) );
      pDispInfo->szText[ HB_SIZEOFARRAY( pDispInfo->szText ) - 1 ] = 0;
   }
}

/*=============================================================================
 * HWG_TOOLBAR_GETDISPINFOID()
 * Gets toolbar display info ID
 *===========================================================================*/
HB_FUNC( HWG_TOOLBAR_GETDISPINFOID )
{
   LPNMTTDISPINFO pDispInfo = ( LPNMTTDISPINFO ) HB_PARHANDLE( 1 );
   DWORD idButton = pDispInfo->hdr.idFrom;
   hb_retnl( idButton );
}

/*=============================================================================
 * HWG_TOOLBAR_GETINFOTIP()
 * Gets toolbar info tip
 *===========================================================================*/
HB_FUNC( HWG_TOOLBAR_GETINFOTIP )
{
   LPNMTBGETINFOTIP pDispInfo = ( LPNMTBGETINFOTIP ) HB_PARHANDLE( 1 );
   if( pDispInfo && pDispInfo->cchTextMax > 0 )
   {
      HB_ITEMCOPYSTR( hb_param( 2, HB_IT_ANY ), pDispInfo->pszText,
                      pDispInfo->cchTextMax );
      pDispInfo->pszText[ pDispInfo->cchTextMax - 1 ] = 0;
   }
}

/*=============================================================================
 * HWG_TOOLBAR_GETINFOTIPID()
 * Gets toolbar info tip ID
 *===========================================================================*/
HB_FUNC( HWG_TOOLBAR_GETINFOTIPID )
{
   LPNMTBGETINFOTIP pDispInfo = ( LPNMTBGETINFOTIP ) HB_PARHANDLE( 1 );
   DWORD idButton = pDispInfo->iItem;
   hb_retnl( idButton );
}

/*=============================================================================
 * HWG_TOOLBAR_IDCLICK()
 * Gets toolbar click ID
 *===========================================================================*/
HB_FUNC( HWG_TOOLBAR_IDCLICK )
{
   LPNMMOUSE pDispInfo = ( LPNMMOUSE ) HB_PARHANDLE( 1 );
   DWORD idButton = pDispInfo->dwItemSpec;
   hb_retnl( idButton );
}

/*=============================================================================
 * HWG_TOOLBAR_SUBMENU()
 * Displays toolbar submenu
 *===========================================================================*/
HB_FUNC( HWG_TOOLBAR_SUBMENU )
{
   LPNMTOOLBAR lpnmTB = ( LPNMTOOLBAR ) HB_PARHANDLE( 1 );
   RECT rc = { 0, 0, 0, 0 };
   TPMPARAMS tpm;
   HMENU hPopupMenu;
   HMENU hMenuLoaded;
   HWND g_hwndMain = ( HWND ) HB_PARHANDLE( 3 );
   HANDLE g_hinst = GetModuleHandle( 0 );

   SendMessage( lpnmTB->hdr.hwndFrom, TB_GETRECT,
         ( WPARAM ) lpnmTB->iItem, ( LPARAM ) & rc );

   MapWindowPoints( lpnmTB->hdr.hwndFrom, HWND_DESKTOP, ( LPPOINT ) ( void * ) &rc, 2 );

   tpm.cbSize = sizeof( TPMPARAMS );
   tpm.rcExclude.left = rc.left;
   tpm.rcExclude.top = rc.top;
   tpm.rcExclude.bottom = rc.bottom;
   tpm.rcExclude.right = rc.right;
   hMenuLoaded =
         LoadMenu( ( HINSTANCE ) g_hinst, MAKEINTRESOURCE( hb_parni( 2 ) ) );
   hPopupMenu =
         GetSubMenu( LoadMenu( ( HINSTANCE ) g_hinst,
               MAKEINTRESOURCE( hb_parni( 2 ) ) ), 0 );

   TrackPopupMenuEx( hPopupMenu,
         TPM_LEFTALIGN | TPM_LEFTBUTTON | TPM_VERTICAL,
         rc.left, rc.bottom, g_hwndMain, &tpm );

   DestroyMenu( hMenuLoaded );
}

/*=============================================================================
 * HWG_TOOLBAR_SUBMENUEX()
 * Displays toolbar submenu (extended)
 *===========================================================================*/
HB_FUNC( HWG_TOOLBAR_SUBMENUEX )
{
   LPNMTOOLBAR lpnmTB = ( LPNMTOOLBAR ) HB_PARHANDLE( 1 );
   RECT rc = { 0, 0, 0, 0 };
   TPMPARAMS tpm;
   HMENU hPopupMenu = ( HMENU ) HB_PARHANDLE( 2 );
   HWND g_hwndMain = ( HWND ) HB_PARHANDLE( 3 );

   SendMessage( lpnmTB->hdr.hwndFrom, TB_GETRECT,
         ( WPARAM ) lpnmTB->iItem, ( LPARAM ) & rc );

   MapWindowPoints( lpnmTB->hdr.hwndFrom, HWND_DESKTOP, ( LPPOINT ) ( void * ) &rc, 2 );

   tpm.cbSize = sizeof( TPMPARAMS );
   tpm.rcExclude.left = rc.left;
   tpm.rcExclude.top = rc.top;
   tpm.rcExclude.bottom = rc.bottom;
   tpm.rcExclude.right = rc.right;
   TrackPopupMenuEx( hPopupMenu,
         TPM_LEFTALIGN | TPM_LEFTBUTTON | TPM_VERTICAL,
         rc.left, rc.bottom, g_hwndMain, &tpm );
}

/*=============================================================================
 * HWG_TOOLBAR_SUBMENUEXGETID()
 * Gets toolbar submenu ID
 *===========================================================================*/
HB_FUNC( HWG_TOOLBAR_SUBMENUEXGETID )
{
   LPNMTOOLBAR lpnmTB = ( LPNMTOOLBAR ) HB_PARHANDLE( 1 );
   hb_retnl( ( LONG ) lpnmTB->iItem );
}

/*=============================================================================
 * HWG_CREATEPAGER()
 * Creates a pager control
 *===========================================================================*/
HB_FUNC( HWG_CREATEPAGER )
{
   HWND hWndPanel;
   BOOL bVert = hb_parl( 8 );
   hWndPanel = CreateWindow( WC_PAGESCROLLER,
         NULL,
         WS_CHILD | WS_VISIBLE | bVert ? PGS_VERT : PGS_HORZ | hb_parnl( 3 ),
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hWndPanel );
}

/*=============================================================================
 * HWG_CREATEREBAR()
 * Creates a rebar control
 *===========================================================================*/
HB_FUNC( HWG_CREATEREBAR )
{
   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulExStyle =
         ( ( !HB_ISNIL( 8 ) ) ? hb_parnl( 8 ) : 0 ) | ( ( ulStyle & WS_BORDER ) ?
         WS_EX_CLIENTEDGE : 0 ) | WS_EX_TOOLWINDOW;
   HWND hWndCtrl = CreateWindowEx( ulExStyle,
         REBARCLASSNAME,
         NULL,
         WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | WS_CLIPCHILDREN | RBS_VARHEIGHT | CCS_NODIVIDER | ulStyle,
         hb_parni( 4 ), hb_parni( 5 ),
         hb_parni( 6 ), hb_parni( 7 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ),
         NULL );

   HB_RETHANDLE( hWndCtrl );
}

/*=============================================================================
 * HWG_REBARSETIMAGELIST()
 * Sets rebar image list
 *===========================================================================*/
HB_FUNC( HWG_REBARSETIMAGELIST )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HIMAGELIST p = ( HB_ISNUM( 2 ) ||
         HB_ISPOINTER( 2 ) ) ? ( HIMAGELIST ) HB_PARHANDLE( 2 ) : NULL;
   REBARINFO rbi;

   memset( &rbi, '\0', sizeof( rbi ) );
   rbi.cbSize = sizeof( REBARINFO );
   rbi.fMask = ( HB_ISNUM( 2 ) || HB_ISPOINTER( 2 ) ) ? RBIM_IMAGELIST : 0;
   rbi.himl = ( HB_ISNUM( 2 ) ||
         HB_ISPOINTER( 2 ) ) ? ( HIMAGELIST ) p : ( HIMAGELIST ) NULL;
   SendMessage( hWnd, RB_SETBARINFO, 0, ( LPARAM ) & rbi );
}

/*=============================================================================
 * _AddBar()
 * Internal function to add band to rebar
 *===========================================================================*/
static BOOL _AddBar( HWND pParent, HWND pBar, REBARBANDINFO * pRBBI )
{
   SIZE size;
   RECT rect;
   BOOL bResult;

   pRBBI->cbSize = sizeof( REBARBANDINFO );
   pRBBI->fMask |= RBBIM_CHILD | RBBIM_CHILDSIZE;
   pRBBI->hwndChild = pBar;

   GetWindowRect( pBar, &rect );

   size.cx = rect.right - rect.left;
   size.cy = rect.bottom - rect.top;

   pRBBI->cxMinChild = size.cx;
   pRBBI->cyMinChild = size.cy;
   bResult =
         SendMessage( pParent, RB_INSERTBAND, ( WPARAM ) - 1,
         ( LPARAM ) pRBBI );

   return bResult;
}

/*=============================================================================
 * AddBar()
 * Internal function to add band with bitmap
 *===========================================================================*/
static BOOL AddBar( HWND pParent, HWND pBar, LPCTSTR pszText, HBITMAP pbmp,
      DWORD dwStyle )
{
   REBARBANDINFO rbBand;

   memset( &rbBand, '\0', sizeof( rbBand ) );

   rbBand.fMask = RBBIM_STYLE;
   rbBand.fStyle = dwStyle;
   if( pszText != NULL )
   {
      rbBand.fMask |= RBBIM_TEXT;
      rbBand.lpText = ( LPTSTR ) pszText;
   }
   if( pbmp != NULL )
   {
      rbBand.fMask |= RBBIM_BACKGROUND;
      rbBand.hbmBack = ( HBITMAP ) pbmp;
   }
   return _AddBar( pParent, pBar, &rbBand );
}

/*=============================================================================
 * AddBar1()
 * Internal function to add band with colors
 *===========================================================================*/
static BOOL AddBar1( HWND pParent, HWND pBar, COLORREF clrFore, COLORREF clrBack,
      LPCTSTR pszText, DWORD dwStyle )
{
   REBARBANDINFO rbBand;
   memset( &rbBand, '\0', sizeof( rbBand ) );
   rbBand.fMask = RBBIM_STYLE | RBBIM_COLORS;
   rbBand.fStyle = dwStyle;
   rbBand.clrFore = clrFore;
   rbBand.clrBack = clrBack;
   if( pszText != NULL )
   {
      rbBand.fMask |= RBBIM_TEXT;
      rbBand.lpText = ( LPTSTR ) pszText;
   }
   return _AddBar( pParent, pBar, &rbBand );
}

/*=============================================================================
 * HWG_ADDBARBITMAP()
 * Adds band with bitmap to rebar
 *===========================================================================*/
HB_FUNC( HWG_ADDBARBITMAP )
{
   HWND pParent = ( HWND ) HB_PARHANDLE( 1 );
   HWND pBar = ( HWND ) HB_PARHANDLE( 2 );
   void * hStr;
   LPCTSTR pszText = HB_PARSTR( 3, &hStr, NULL );
   HBITMAP pbmp = ( HBITMAP ) HB_PARHANDLE( 4 );
   DWORD dwStyle = hb_parnl( 5 );
   hb_retl( AddBar( pParent, pBar, pszText, pbmp, dwStyle ) );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_ADDBARCOLORS()
 * Adds band with colors to rebar
 *===========================================================================*/
HB_FUNC( HWG_ADDBARCOLORS )
{
   HWND pParent = ( HWND ) HB_PARHANDLE( 1 );
   HWND pBar = ( HWND ) HB_PARHANDLE( 2 );
   COLORREF clrFore = ( COLORREF ) hb_parnl( 3 );
   COLORREF clrBack = ( COLORREF ) hb_parnl( 4 );
   void * hStr;
   LPCTSTR pszText = HB_PARSTR( 5, &hStr, NULL );
   DWORD dwStyle = hb_parnl( 6 );

   hb_retl( AddBar1( pParent, pBar, clrFore, clrBack, pszText, dwStyle ) );
   hb_strfree( hStr );
}

/*=============================================================================
 * HWG_EDIT_GETPOS()
 * Gets edit control cursor position
 *===========================================================================*/
HB_FUNC( HWG_EDIT_GETPOS )
{
   hb_retni( ( ( SendMessage( ( HWND ) HB_PARHANDLE( 1 ), EM_GETSEL, 0, 0 ) >> 16 ) & 0xFFFF ) + 1 );
}

/*=============================================================================
 * HWG_EDIT_SETPOS()
 * Sets edit control cursor position
 *===========================================================================*/
HB_FUNC( HWG_EDIT_SETPOS )
{
   int iPos = hb_parni(2) - 1;
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), EM_SETSEL, (WPARAM) iPos, (LPARAM) iPos );
}

/*=============================================================================
 * HWG_COMBOGETITEMRECT()
 * Gets combobox item rectangle
 *===========================================================================*/
HB_FUNC( HWG_COMBOGETITEMRECT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int nIndex = hb_parnl( 2 );
   RECT rcItem;
   SendMessage( hWnd, LB_GETITEMRECT, nIndex, ( LPARAM) & rcItem );
   hb_itemRelease( hb_itemReturn( Rect2Array( &rcItem ) ) );
}

/*=============================================================================
 * HWG_COMBOBOXGETITEMDATA()
 * Gets combobox item data
 *===========================================================================*/
HB_FUNC( HWG_COMBOBOXGETITEMDATA )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int nIndex = hb_parnl( 2 );
   DWORD_PTR p;
   p = ( DWORD_PTR ) SendMessage( ( HWND ) hWnd, CB_GETITEMDATA, nIndex, 0 );
   hb_retnl( p );
}

/*=============================================================================
 * HWG_COMBOBOXSETITEMDATA()
 * Sets combobox item data
 *===========================================================================*/
HB_FUNC( HWG_COMBOBOXSETITEMDATA )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int nIndex = hb_parnl( 2 );
   DWORD_PTR dwItemData = ( DWORD_PTR ) hb_parnl( 3 );
   hb_retnl( SendMessage( ( HWND ) hWnd, CB_SETITEMDATA, nIndex,
               ( LPARAM ) dwItemData ) );
}

/*=============================================================================
 * HWG_GETLOCALEINFO()
 * Gets list separator character
 *===========================================================================*/
HB_FUNC( HWG_GETLOCALEINFO )
{
   TCHAR szBuffer[10] = { 0 };
   GetLocaleInfo( LOCALE_USER_DEFAULT, LOCALE_SLIST, szBuffer,
                  HB_SIZEOFARRAY( szBuffer ) );
   HB_RETSTR( szBuffer );
}

/*=============================================================================
 * HWG_COMBOBOXGETLBTEXT()
 * Gets combobox item text
 *===========================================================================*/
HB_FUNC( HWG_COMBOBOXGETLBTEXT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int nIndex = hb_parnl( 2 );
   TCHAR lpszText[255] = { 0 };
   hb_retni( SendMessage( hWnd, CB_GETLBTEXT, nIndex,
                          ( LPARAM ) lpszText ) );
   HB_STORSTR( lpszText, 3 );
}

/*=============================================================================
 * HWG_DEFWINDOWPROC()
 * Calls default window procedure
 *===========================================================================*/
HB_FUNC( HWG_DEFWINDOWPROC )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   LONG message = hb_parnl( 2 );
   WPARAM wParam = ( WPARAM ) hb_parnl( 3 );
   LPARAM lParam = ( LPARAM ) hb_parnl( 4 );

   hb_retnl( DefWindowProc( hWnd, message, wParam, lParam ) );
}

/*=============================================================================
 * HWG_CALLWINDOWPROC()
 * Calls window procedure
 *===========================================================================*/
HB_FUNC( HWG_CALLWINDOWPROC )
{
   WNDPROC wpProc = ( WNDPROC ) ( ULONG_PTR ) hb_parnl( 1 );
   HWND hWnd = ( HWND ) HB_PARHANDLE( 2 );
   LONG message = hb_parnl( 3 );
   WPARAM wParam = ( WPARAM ) hb_parnl( 4 );
   LPARAM lParam = ( LPARAM ) hb_parnl( 5 );

   hb_retnl( CallWindowProc( wpProc, hWnd, message, wParam, lParam ) );
}

/*=============================================================================
 * HWG_BUTTONGETDLGCODE()
 * Gets button dialog code
 *===========================================================================*/
HB_FUNC( HWG_BUTTONGETDLGCODE )
{
   LPARAM lParam = ( LPARAM ) HB_PARHANDLE( 1 );
   if( lParam )
   {
      MSG *pMsg = ( MSG * ) lParam;
      if( pMsg && ( pMsg->message == WM_KEYDOWN ) &&
            ( pMsg->wParam == VK_TAB ) )
      {
         hb_retnl( 0 );
         return;
      }
   }
   hb_retnl( DLGC_WANTALLKEYS );
}

/*=============================================================================
 * HWG_GETDLGMESSAGE()
 * Gets dialog message
 *===========================================================================*/
HB_FUNC( HWG_GETDLGMESSAGE )
{
   LPARAM lParam = ( LPARAM ) HB_PARHANDLE( 1 );
   if( lParam )
   {
      MSG *pMsg = ( MSG * ) lParam;
      if( pMsg )
      {
         hb_retnl( pMsg->message );
         return;
      }
   }
   hb_retnl( 0 );
}

/*=============================================================================
 * HWG_TABITEMPOS()
 * Gets tab item position
 *===========================================================================*/
HB_FUNC( HWG_TABITEMPOS )
{
   RECT pRect;
   TabCtrl_GetItemRect( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), &pRect );
   hb_itemRelease( hb_itemReturn( Rect2Array( &pRect ) ) );
}

/*=============================================================================
 * HWG_GETTABNAME()
 * Gets tab item name
 *===========================================================================*/
HB_FUNC( HWG_GETTABNAME )
{
   TC_ITEM tie;
   TCHAR d[255] = { 0 };

   tie.mask = TCIF_TEXT;
   tie.cchTextMax = HB_SIZEOFARRAY( d ) - 1;
   tie.pszText = d;
   TabCtrl_GetItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) - 1,
                    ( LPTCITEM ) &tie );
   HB_RETSTR( tie.pszText );
}

/*=============================================================================
 * HWG_GETUTCTIMEDATE()
 * Returns UTC time and date as a formatted string
 *
 * Returns: String in format "D.YYYYMMDD-HH:MM:SS"
 *===========================================================================*/
HB_FUNC( HWG_GETUTCTIMEDATE )
{
      SYSTEMTIME st;
      TCHAR cst[41] = { 0 };

      GetSystemTime( &st );

      #ifdef UNICODE
         swprintf( cst, HB_SIZEOFARRAY( cst ), L"%01d.%04d%02d%02d-%02d:%02d:%02d",
                 (int)st.wDayOfWeek, (int)st.wYear, (int)st.wMonth, (int)st.wDay,
                 (int)st.wHour, (int)st.wMinute, (int)st.wSecond );
         HB_RETSTR( cst );
      #else
         hb_snprintf( cst, HB_SIZEOFARRAY( cst ), "%01d.%04d%02d%02d-%02d:%02d:%02d",
                    (int)st.wDayOfWeek, (int)st.wYear, (int)st.wMonth, (int)st.wDay,
                    (int)st.wHour, (int)st.wMinute, (int)st.wSecond );
         hb_retc( cst );
      #endif
}

/*=============================================================================
 * HWG_GETDATEANSI()
 * Returns local date as ANSI formatted string
 *
 * Returns: String in format "YYYYMMDD"
 *===========================================================================*/
HB_FUNC( HWG_GETDATEANSI )
{
      SYSTEMTIME st;
      TCHAR cst[41] = { 0 };

      GetLocalTime( &st );

      #ifdef UNICODE
         swprintf( cst, HB_SIZEOFARRAY( cst ), L"%04d%02d%02d",
                  (int)st.wYear, (int)st.wMonth, (int)st.wDay );
         HB_RETSTR( cst );
      #else
         hb_snprintf( cst, HB_SIZEOFARRAY( cst ), "%04d%02d%02d",
                   (int)st.wYear, (int)st.wMonth, (int)st.wDay );
         hb_retc( cst );
      #endif
}

/*=============================================================================
 * HWG_GETLOCALEID()
 * Returns the Windows Locale ID (LCID) for the current user
 * 
 * Returns:
 *   Windows LCID (e.g., 1046 for Portuguese-Brazil, 1033 for English-US)
 *===========================================================================*/
HB_FUNC( HWG_GETLOCALEID )
{
   hb_retni( GetUserDefaultLCID() );
}

/*=============================================================================
 * HWG_GETLOCALEINFON()
 * Deprecated: Use HWG_GETLOCALEID() instead.
 * Returns the Windows Locale ID (LCID) for the current user
 * 
 * Returns:
 *   Windows LCID (e.g., 1046 for Portuguese-Brazil, 1033 for English-US)
 *===========================================================================*/
HB_FUNC( HWG_GETLOCALEINFON )
{
   hb_retni( GetUserDefaultLCID() );
}

/*=============================================================================
 * HWG_DEFUSERLANG()
 * Returns the user's default language abbreviation
 * 
 * Returns: Language code (e.g., "ENU", "PTB")
 *===========================================================================*/
HB_FUNC( HWG_DEFUSERLANG )
{
   TCHAR clang[10] = { 0 };

#ifdef UNICODE
   GetLocaleInfoW( LOCALE_USER_DEFAULT, LOCALE_SABBREVLANGNAME, clang, 10 );
   HB_RETSTR( clang );
#else
   GetLocaleInfoA( LOCALE_USER_DEFAULT, LOCALE_SABBREVLANGNAME, clang, 10 );
   hb_retc( clang );
#endif
}

/*=============================================================================
 * HWG_SHOWCURSOR()
 * Shows or hides the cursor
 *===========================================================================*/
HB_FUNC( HWG_SHOWCURSOR )
{
  hb_retni(ShowCursor(hb_parl( 1 ) ) );
}

/* ====================== EOF of control.c ======================= */
