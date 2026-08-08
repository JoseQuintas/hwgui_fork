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
#if defined(__DMC__)
#include "missing.h"
#endif

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

#if defined(__BORLANDC__) || (defined(_MSC_VER) && !defined(__XCC__) || defined(__WATCOMC__) || defined(__DMC__) )
HB_EXTERN_BEGIN
WINUSERAPI HWND WINAPI GetAncestor( HWND hwnd, UINT gaFlags );
HB_EXTERN_END
#endif

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

/*
#if _MSC_VER
#define snprintf _snprintf
#endif
*/

// LRESULT CALLBACK OwnBtnProc (HWND, UINT, WPARAM, LPARAM) ;
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
static WNDPROC wpOrigEditProc, wpOrigTrackProc, wpOrigTabProc, wpOrigStaticProc, wpOrigListProc, wpOrigUpDownProc, wpOrigDatePickerProc,  wpOrigTreeViewProc;     //wpOrigButtonProc
static LONG_PTR wpOrigButtonProc;

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

HB_FUNC( HWG_MOVEWINDOW )
{
   RECT rc;

   GetWindowRect( ( HWND ) HB_PARHANDLE( 1 ), &rc );
   MoveWindow( ( HWND ) HB_PARHANDLE( 1 ),      // handle of window
         ( HB_ISNIL( 2 ) ) ? rc.left : hb_parni( 2 ),      // horizontal position
         ( HB_ISNIL( 3 ) ) ? rc.top : hb_parni( 3 ),       // vertical position
         ( HB_ISNIL( 4 ) ) ? rc.right - rc.left : hb_parni( 4 ),   // width
         ( HB_ISNIL( 5 ) ) ? rc.bottom - rc.top : hb_parni( 5 ),   // height
         ( hb_pcount(  ) < 6 ) ? TRUE : hb_parl( 6 )    // repaint flag
          );
}

/*
   CreateProgressBar( hParentWindow, nRange )
*/
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

   hPBar = CreateWindowEx( 0, PROGRESS_CLASS, NULL, WS_CHILD | WS_VISIBLE | ulStyle,    /* style  */
         x1,                    /* x */
         y1,                    /* y */
         nwidth, nheight,       /* nWidth, nHeight */
         hParentWindow,         /* parent window    */
         ( HMENU ) NULL, GetModuleHandle( NULL ), NULL );

   SendMessage( hPBar, PBM_SETRANGE, 0, (MAKELPARAM( 0, hb_parni(2) )) );
   SendMessage( hPBar, PBM_SETSTEP, ( WPARAM ) 1, 0 );

   HB_RETHANDLE( hPBar );
}

/*
   UpdateProgressBar( hPBar )
*/
HB_FUNC( HWG_UPDATEPROGRESSBAR )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_STEPIT, 0, 0 );
}

/*
   ResetProgressBar( hPBar )
   Added by DF7BE
*/
HB_FUNC( HWG_RESETPROGRESSBAR )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_SETPOS,
         ( WPARAM ) 0 , 0 );
}

/*
   SetProgressBar( hPBar , nPercent )
*/
HB_FUNC( HWG_SETPROGRESSBAR )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_SETPOS,
         ( WPARAM ) hb_parni( 2 ), 0 );
}

HB_FUNC( HWG_SETRANGEPROGRESSBAR )
{

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_SETRANGE, 0, MAKELPARAM( 0, hb_parni( 2 ) ) );
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), PBM_SETSTEP, 1 , 0 );
}

/*
   CreatePanel( hParentWindow, nPanelControlID, nStyle, x1, y1, nWidth, nHeight )
*/
HB_FUNC( HWG_CREATEPANEL )
{
   HWND hWndPanel;
   hWndPanel = CreateWindow( TEXT( "PANEL" ),   /* predefined class  */
         NULL,                  /* no window title   */
         WS_CHILD | WS_VISIBLE | SS_GRAYRECT | SS_OWNERDRAW | CCS_TOP | hb_parnl( 3 ),  /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hWndPanel );
   // SS_ETCHEDHORZ
}

/*
   CreateOwnBtn( hParentWIndow, nBtnControlID, x, y, nWidth, nHeight )
*/
/*
HB_FUNC( HWG_CREATEOWNBTN )
{
   HWND hWndPanel;
   hWndPanel = CreateWindow( TEXT( "HBOARD" ),
         NULL,
         WS_CHILD | WS_VISIBLE | SS_GRAYRECT | SS_OWNERDRAW,
         hb_parni( 3 ), hb_parni( 4 ),
         hb_parni( 5 ), hb_parni( 6 ),
         ( HWND ) HB_PARHANDLE( 1 ),
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hWndPanel );
}
*/

/*
   CreateStatic( hParentWyndow, nControlID, nStyle, x, y, nWidth, nHeight )
*/
HB_FUNC( HWG_CREATESTATIC )
{
   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulExStyle =
         ( ( !HB_ISNIL( 8 ) ) ? hb_parnl( 8 ) : 0 ) | ( ( ulStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0 );
   HWND hWndCtrl = CreateWindowEx( ulExStyle,   /* extended style */
         TEXT( "STATIC" ),      /* predefined class  */
         NULL,                  /* title   */
         WS_CHILD | WS_VISIBLE | ulStyle,       /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ),
         NULL );

   /*
      if( hb_pcount() > 7 )
      {
         void * hStr;
         LPCTSTR lpText = HB_PARSTR( 8, &hStr, NULL );
         if( lpText )
            SendMessage( hWndEdit, WM_SETTEXT, 0, ( LPARAM ) lpText );
         hb_strfree( hStr );
      }
    */



   HB_RETHANDLE( hWndCtrl );

}

/*
   CreateButton( hParentWIndow, nButtonID, nStyle, x, y, nWidth, nHeight,
                 cCaption )
*/
HB_FUNC( HWG_CREATEBUTTON )
{
   void * hStr;
   HWND hBtn = CreateWindow( TEXT( "BUTTON" ),  /* predefined class  */
         HB_PARSTR( 8, &hStr, NULL ),           /* button text   */
         WS_CHILD | WS_VISIBLE | hb_parnl( 3 ), /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* button       ID  */
         GetModuleHandle( NULL ),
         NULL );
   hb_strfree( hStr );

   HB_RETHANDLE( hBtn );

}

/*
   CreateEdit( hParentWIndow, nEditControlID, nStyle, x, y, nWidth, nHeight,
               cInitialString )
*/
HB_FUNC( HWG_CREATEEDIT )
{
   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulStyleEx = ( ulStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0;
   HWND hWndEdit;

   if( ( ulStyle & WS_BORDER ) )        //&& ( ulStyle & WS_DLGFRAME ) )
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

/*
   CreateCombo( hParentWIndow, nComboID, nStyle, x, y, nWidth, nHeight,
                cInitialString )
*/
HB_FUNC( HWG_CREATECOMBO )
{
   HWND hCombo = CreateWindow( TEXT( "COMBOBOX" ),    /* predefined class  */
         TEXT( "" ),                    /*   */
         WS_CHILD | WS_VISIBLE | hb_parnl( 3 ), /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* combobox ID      */
         GetModuleHandle( NULL ),
         NULL );

   HB_RETHANDLE( hCombo );

}


/*
   CreateBrowse( hParentWIndow, nControlID, nStyle, x, y, nWidth, nHeight,
               cTitle )
*/
HB_FUNC( HWG_CREATEBROWSE )
{
   HWND hWndBrw;
   DWORD dwStyle = hb_parnl( 3 );
   void * hStr;

   hWndBrw = CreateWindowEx( ( dwStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0,    /* extended style */
         TEXT( "HBOARD" ),              /* predefined class */
         HB_PARSTR( 8, &hStr, NULL ),           /* button text   */
         WS_CHILD | WS_VISIBLE | dwStyle,       /* style */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y  */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );
   hb_strfree( hStr );

   HB_RETHANDLE( hWndBrw );

}

HB_FUNC( HWG_CREATEBOARD )
{
   HWND h;
   DWORD dwStyle = hb_parnl( 3 );

   h = CreateWindowEx( ( dwStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0,    /* extended style */
         TEXT( "HBOARD" ),              /* predefined class */
         NULL,
         WS_CHILD | WS_VISIBLE | dwStyle,
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y  */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( h );

}

HB_FUNC( HWG_TRACKMOUSEEVENT )
{
   TRACKMOUSEEVENT tme;

   tme.cbSize = sizeof(TRACKMOUSEEVENT);
   tme.dwFlags = TME_LEAVE;
   tme.hwndTrack = (HWND) HB_PARHANDLE( 1 );
   hb_retl( TrackMouseEvent( &tme ) );
}

/* CreateStatusWindow - creates a status window and divides it into
     the specified number of parts.
 Returns the handle to the status window.
 hwndParent - parent window for the status window
 nStatusID - child window identifier
 nParts - number of parts into which to divide the status window
 pArray - Array with Lengths of parts, if first item == 0, status window
          will be divided into equal parts.
*/
HB_FUNC( HWG_CREATESTATUSWINDOW )
{
   HWND hwndStatus, hwndParent = ( HWND ) HB_PARHANDLE( 1 );

   // Ensure that the common control DLL is loaded.
   InitCommonControls(  );

   // Create the status window.
   hwndStatus = CreateWindowEx( 0,      // style
         STATUSCLASSNAME,       // name of status window class
         NULL,                  // no text when first created
         SBARS_SIZEGRIP |       // includes a sizing grip
         WS_CHILD | WS_VISIBLE | WS_OVERLAPPED | WS_CLIPSIBLINGS,       // creates a child window
         0, 0, 0, 0,            // ignores size and position
         hwndParent,            // handle to parent window
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       // child window identifier
         GetModuleHandle( NULL ),       // handle to application instance
         NULL );                // no window creation data

   HB_RETHANDLE( hwndStatus );
}

HB_FUNC( HWG_INITSTATUS )
{
   HWND hParent = ( HWND ) HB_PARHANDLE( 1 );
   HWND hStatus = ( HWND ) HB_PARHANDLE( 2 );
   RECT rcClient;
   HLOCAL hloc;
   LPINT lpParts;
   int i, nWidth, j, nParts = hb_parni( 3 );
   PHB_ITEM pArray = hb_param( 4, HB_IT_ARRAY );

   // Allocate an array for holding the right edge coordinates.
   hloc = LocalAlloc( LHND, sizeof( int ) * nParts );
   lpParts = ( LPINT ) LocalLock( hloc );

   if( !pArray || hb_arrayGetNI( pArray, 1 ) == 0 )
   {
      // Get the coordinates of the parent window's client area.
      GetClientRect( hParent, &rcClient );
      // Calculate the right edge coordinate for each part, and
      // copy the coordinates to the array.
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

   // Tell the status window to create the window parts.
   SendMessage( hStatus, SB_SETPARTS, ( WPARAM ) nParts, ( LPARAM ) lpParts );

   // Free the array, and return.
   LocalUnlock( hloc );
   LocalFree( hloc );
}

HB_FUNC( HWG_GETNOTIFYSBPARTS )
{
   hb_retnl( ( LONG ) ((( NMMOUSE * ) HB_PARHANDLE( 1 ))->dwItemSpec ) );
}

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
      //ti.lpszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );
      ti.lpszText = ( LPTSTR ) HB_PARSTR( 2, &hStr, NULL );

      hb_retl( SendMessage( hWndTT, TTM_SETTOOLINFO, 0,
                            ( LPARAM ) ( LPTOOLINFO ) & ti ) );
      hb_strfree( hStr );
   }
}


HB_FUNC( HWG_CREATEUPDOWNCONTROL )
{
   HB_RETHANDLE( CreateUpDownControl( WS_CHILD | WS_BORDER | WS_VISIBLE |
               hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ),
               hb_parni( 7 ), ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ),
               GetModuleHandle( NULL ), ( HWND ) HB_PARHANDLE( 8 ),
               hb_parni( 9 ), hb_parni( 10 ), hb_parni( 11 ) ) );
}

HB_FUNC( HWG_SETUPDOWN )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), UDM_SETPOS, 0, hb_parnl( 2 ) );
}

HB_FUNC( HWG_GETUPDOWN )
{
   hb_retnl( SendMessage( ( HWND ) HB_PARHANDLE( 1 ), UDM_GETPOS, 0, 0 ) );
}

HB_FUNC( HWG_SETRANGEUPDOWN )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), UDM_SETRANGE32, hb_parnl( 2 ), hb_parnl( 3 ) );
}


HB_FUNC( HWG_GETNOTIFYDELTAPOS )
{
   int iItem = hb_parnl( 2 ) ;
   if ( iItem < 2 )
      hb_retni( (LONG) (((NMUPDOWN *) HB_PARHANDLE( 1 ) )->iPos ) );
   else
      hb_retni( (LONG) (((NMUPDOWN *) HB_PARHANDLE( 1 ) )->iDelta ) );
}

HB_FUNC( HWG_CREATEDATEPICKER )
{
   HWND hCtrl;
   LONG nStyle = hb_parnl( 7 ) | WS_CHILD | WS_VISIBLE | WS_TABSTOP;

   hCtrl = CreateWindowEx( WS_EX_CLIENTEDGE, TEXT( "SYSDATETIMEPICK32" ),
         NULL, nStyle,
         hb_parni( 3 ), hb_parni( 4 ),  /* x, y       */
         hb_parni( 5 ), hb_parni( 6 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hCtrl );
}

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

HB_FUNC( HWG_SETDATEPICKERNULL )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), DTM_SETSYSTEMTIME, GDT_NONE,
                ( LPARAM ) 0 );
}

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


HB_FUNC( HWG_GETTIMEPICKER )
{
   SYSTEMTIME st;
   char szTime[9];

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), DTM_GETSYSTEMTIME, 0,
                ( LPARAM ) & st );

   //sprintf( szTime, "%02d:%02d:%02d", st.wHour, st.wMinute, st.wSecond );
   hb_snprintf( szTime, 9, "%02d:%02d:%02d", st.wHour, st.wMinute, st.wSecond );
   hb_retc( szTime ) ;
}

HB_FUNC( HWG_CREATETABCONTROL )
{
   HWND hTab;

   hTab = CreateWindow( WC_TABCONTROL, NULL, WS_CHILD | WS_VISIBLE | hb_parnl( 3 ),     /* style  */
         hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ), hb_parni( 7 ), ( HWND ) HB_PARHANDLE( 1 ),        /* parent window    */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hTab );

}

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


/*
  hwg_AddTab(handle, npos, cCaption)
*/

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

HB_FUNC( HWG_DELETETAB )
{
   TabCtrl_DeleteItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) );
}


HB_FUNC( HWG_GETCURRENTTAB )
{
   hb_retni( TabCtrl_GetCurSel( ( HWND ) HB_PARHANDLE( 1 ) ) + 1 );
}

HB_FUNC( HWG_SETTABSIZE )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TCM_SETITEMSIZE, 0,
                MAKELPARAM( hb_parni( 2 ), hb_parni( 3 ) ) );
}

HB_FUNC( HWG_SETTABNAME )
{
   TC_ITEM tie;
   void * hStr;

   tie.mask = TCIF_TEXT;
   tie.pszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );

   TabCtrl_SetItem( ( HWND ) HB_PARHANDLE( 1 ), hb_parni(2)-1, &tie );
   hb_strfree( hStr );
}

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

/*
 * Returns TRUE if nTab (1-based) is marked disabled in HTab data.
 * Storage convention:
 *  - GWLP_USERDATA of hTab -> HTab Harbour object
 *  - HTab data var "aTabDisabled" is an array of .T./.F. flags
 */
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

/*
 * HWG_TABSETOWNERDRAW( hTab, lOn )
 * Enables/disables TCS_OWNERDRAWFIXED at runtime.
 */
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

      /* Refresh styles and repaint */
      SetWindowPos( hTab, NULL, 0, 0, 0, 0,
                    SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED );
      InvalidateRect( hTab, NULL, TRUE );
      UpdateWindow( hTab );

      hb_retl( TRUE );
}
/*
 * HWG_TABFORCEREFRESH( hTab )
 * Forces immediate repaint of the tab control (avoid waiting for mouse hover).
 */
HB_FUNC( HWG_TABFORCEREFRESH )
{
      HWND hTab = ( HWND ) HB_PARHANDLE( 1 );
      HWND hParent;

      if( !hTab )
      {
            hb_retl( FALSE );
            return;
      }

      /* Strong refresh: force immediate paint (avoid waiting for mouse hover) */
      InvalidateRect( hTab, NULL, TRUE );

      RedrawWindow( hTab, NULL, NULL,
                    RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW | RDW_ALLCHILDREN );

      /* Some themes repaint the tab header only when the parent repaints */
      hParent = GetParent( hTab );
      if( hParent )
            RedrawWindow( hParent, NULL, NULL,
                          RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW | RDW_ALLCHILDREN );

   /* Extra safety */
   UpdateWindow( hTab );

   hb_retl( TRUE );
}


/* -------------------------------------------------------------------------
 * Draw disabled tab captions in gray (Windows only)
 * - Does NOT require TCS_OWNERDRAWFIXED
 * - Works with nested tabs (tab inside tab)
 * ------------------------------------------------------------------------- */
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

      /* Use the same font used by the tab control (avoids blurry mismatch) */
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
                              /* Clear the text area first, otherwise we draw over the existing black text (blurry) */
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

HB_FUNC( HWG_GETNOTIFYKEYDOWN )
{
   hb_retni( ( WORD ) ( ( ( TC_KEYDOWN * ) HB_PARHANDLE( 1 ) )->wVKey ) );
}

HB_FUNC( HWG_CREATETREE )
{
   HWND hCtrl;

   hCtrl = CreateWindowEx( WS_EX_CLIENTEDGE, WC_TREEVIEW, 0,
         WS_CHILD | WS_VISIBLE | WS_TABSTOP | hb_parnl( 3 ),
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   if( !HB_ISNIL( 8 ) )
      SendMessage( hCtrl, TVM_SETTEXTCOLOR, 0, ( LPARAM ) ( hb_parnl( 8 ) ) );
   if( !HB_ISNIL( 9 ) )
      SendMessage( hCtrl, TVM_SETBKCOLOR, 0, ( LPARAM ) ( hb_parnl( 9 ) ) );

   HB_RETHANDLE( hCtrl );
}

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

/*
HB_FUNC( HWG_TREEDELNODE )
{

   hb_parl( TreeView_DeleteItem( (HWND)HB_PARHANDLE(1), (HTREEITEM)HB_PARHANDLE(2) ) );
}

HB_FUNC( HWG_TREEDELALLNODES )
{

   TreeView_DeleteAllItems( (HWND)HB_PARHANDLE(1) );
}
*/

HB_FUNC( HWG_TREEGETSELECTED )
{
   TV_ITEM TreeItem;

   memset( &TreeItem, 0, sizeof( TV_ITEM ) );
   TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
   TreeItem.hItem = TreeView_GetSelection( ( HWND ) HB_PARHANDLE( 1 ) );

   if( TreeItem.hItem )
   {
      PHB_ITEM oNode;           // = hb_itemNew( NULL );
      SendMessage( ( HWND ) HB_PARHANDLE( 1 ), TVM_GETITEM, 0,
            ( LPARAM ) ( &TreeItem ) );
      oNode = ( PHB_ITEM ) TreeItem.lParam;
      hb_itemReturn( oNode );
   }
}

/*
HB_FUNC( HWG_TREENODEHASCHILDREN )
{

   TV_ITEM TreeItem;

   memset( &TreeItem, 0, sizeof(TV_ITEM) );
   TreeItem.mask = TVIF_HANDLE | TVIF_CHILDREN;
   TreeItem.hItem = (HTREEITEM) HB_PARHANDLE(2);

   SendMessage( (HWND)HB_PARHANDLE(1), TVM_GETITEM, 0, (LPARAM)(&TreeItem) );
   hb_retni( TreeItem.cChildren );
}

*/

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
      PHB_ITEM oNode;           // = hb_itemNew( NULL );
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

/*
 * Tree_Hittest( hTree, x, y ) --> oNode
 */
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
      PHB_ITEM oNode;           // = hb_itemNew( NULL );
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

/*
 * CreateImagelist( array, cx, cy, nGrow, flags )
*/
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

HB_FUNC( HWG_IMAGELIST_ADD )
{
   hb_retnl( ImageList_Add( ( HIMAGELIST ) HB_PARHANDLE( 1 ),
               ( HBITMAP ) HB_PARHANDLE( 2 ), ( HBITMAP ) NULL ) );
}

HB_FUNC( HWG_IMAGELIST_ADDMASKED )
{
   hb_retnl( ImageList_AddMasked( ( HIMAGELIST ) HB_PARHANDLE( 1 ),
               ( HBITMAP ) HB_PARHANDLE( 2 ), ( COLORREF ) hb_parnl( 3 ) ) );
}

HB_FUNC( HWG_DESTROYIMAGELIST )
{
   HIMAGELIST h = ( HIMAGELIST ) HB_PARHANDLE( 1 );
   ImageList_Destroy( h );
}


/*
 *  SetTimer( hWnd, idTimer, i_MilliSeconds )
 */

/* 22/09/2005 - <maurilio.longo@libero.it>
      If I pass a fourth parameter as 0 (zero) I don't set
      the TimerProc, this way I can receive WM_TIMER messages
      inside an ON OTHER MESSAGES code block
*/
HB_FUNC( HWG_SETTIMER )
{
   SetTimer( ( HWND ) HB_PARHANDLE( 1 ), ( UINT ) hb_parni( 2 ),
             ( UINT ) hb_parni( 3 ),
             hb_pcount() == 3 ?  ( TIMERPROC ) ( UINT_PTR ) s_timerProc : ( TIMERPROC ) ( UINT_PTR )  NULL );
}

/*
 *  KillTimer( hWnd, idTimer )
 */

HB_FUNC( HWG_KILLTIMER )
{
   hb_retl( KillTimer( ( HWND ) HB_PARHANDLE( 1 ), ( UINT ) hb_parni( 2 ) ) );
}

HB_FUNC( HWG_GETPARENT )
{
   HB_RETHANDLE( GetParent( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_GETANCESTOR )
{
   HB_RETHANDLE( GetAncestor( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) ) );
}

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

/*       hwg_LoadCursorFromFile(ccurFname) */
HB_FUNC( HWG_LOADCURSORFROMFILE )
{
   void * hStr;
   HCURSOR hCursor;

   LPCTSTR ccurFname = HB_PARSTR( 1, &hStr, NULL );

   hCursor = LoadCursorFromFile(ccurFname);
   if (hCursor == NULL )
   /* in case of error return default cursor "Arrow" */
      HB_RETHANDLE( LoadCursor( NULL, IDC_ARROW ) );
   else
      HB_RETHANDLE(hCursor);

   hb_strfree( hStr );
}

HB_FUNC( HWG_SETCURSOR )
{
   HB_RETHANDLE( SetCursor( ( HCURSOR ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_GETCURSOR )
{
   HB_RETHANDLE( GetCursor() );
}

HB_FUNC( HWG_GETTOOLTIPHANDLE )
{
   HB_RETHANDLE( hWndTT );
}

HB_FUNC( HWG_SETTOOLTIPBALLOON )
{
   lToolTipBalloon = hb_parl( 1 );
   hWndTT = 0;
}

HB_FUNC( HWG_GETTOOLTIPBALLOON )
{
   hb_retl( lToolTipBalloon );
}

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

void hwg_regboard( void )
{
   static BOOL bRegistered = FALSE;

   WNDCLASS wndclass;

   if( !bRegistered )
   {
      wndclass.style = CS_DBLCLKS; // | CS_OWNDC | CS_VREDRAW | CS_HREDRAW;
      wndclass.lpfnWndProc = WinCtrlProc;
      wndclass.cbClsExtra = 0;
      wndclass.cbWndExtra = 0;
      wndclass.hInstance = GetModuleHandle( NULL );
      wndclass.hIcon = NULL;
      wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
      //wndclass.hbrBackground = ( HBRUSH ) ( COLOR_3DFACE + 1 );
      //wndclass.hCursor = LoadCursor( NULL, IDC_IBEAM );
      wndclass.hbrBackground = NULL;

      wndclass.lpszMenuName = NULL;
      wndclass.lpszClassName = TEXT( "HBOARD" );

      RegisterClass( &wndclass );
      bRegistered = TRUE;
   }
}

HB_FUNC( HWG_REGBOARD )
{
   hwg_regboard();
}

/*
HB_FUNC( HWG_REGBROWSE )
{

   static BOOL bRegistered = FALSE;

   if( !bRegistered )
   {
      WNDCLASS wndclass;

      wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
      wndclass.lpfnWndProc = WinCtrlProc;
      wndclass.cbClsExtra = 0;
      wndclass.cbWndExtra = 0;
      wndclass.hInstance = GetModuleHandle( NULL );
      wndclass.hIcon = NULL;
      wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
      wndclass.hbrBackground = ( HBRUSH ) ( COLOR_WINDOW + 1 );
      wndclass.lpszMenuName = NULL;
      wndclass.lpszClassName = TEXT( "BROWSE" );

      RegisterClass( &wndclass );
      bRegistered = TRUE;
   }
}
*/

static void CALLBACK s_timerProc( HWND hWnd, UINT message, UINT idTimer, DWORD dwTime )
  /* DWORD dwTime as last parameter unused */
{
   static PHB_DYNS s_pSymTest = NULL;

   HB_SYMBOL_UNUSED( message );
   HB_SYMBOL_UNUSED( dwTime );

   if( s_pSymTest == NULL )
      s_pSymTest = hb_dynsymGetCase( "HWG_TIMERPROC" );

   if( hb_dynsymIsFunction( s_pSymTest ) )
   {
      hb_vmPushDynSym( s_pSymTest );
      hb_vmPushNil();   /* places NIL at self */
//      hb_vmPushLong( (LONG ) hWnd );    /* pushes parameters on to the hvm stack */
      HB_PUSHITEM( hWnd );
      hb_vmPushLong( ( LONG ) idTimer );
      //hb_vmPushLong( ( LONG ) dwTime );
      hb_vmDo( 2 );             /* where iArgCount is the number of pushed parameters */
   }
}

/*
BOOL RegisterWinCtrl( void )    // Added by jamaj - Used by WinCtrl
{
   WNDCLASS wndclass;

   wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
   wndclass.lpfnWndProc = WinCtrlProc;
   wndclass.cbClsExtra = 0;
   wndclass.cbWndExtra = 0;
   wndclass.hInstance = GetModuleHandle( NULL );
   wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
   wndclass.hbrBackground = ( HBRUSH ) ( COLOR_3DFACE + 1 );
   wndclass.lpszMenuName = NULL;
   wndclass.lpszClassName = TEXT( "WINCTRL" );

   return RegisterClass( &wndclass );
}
*/

HB_FUNC( HWG_INITTREEVIEW )
{
   wpOrigTreeViewProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) TreeViewSubclassProc );
}

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
//      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
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

HB_FUNC( HWG_INITWINCTRL )
{
   SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) WinCtrlProc );
}

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
//      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
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

HB_FUNC( HWG_INITSTATICPROC )
{
   wpOrigStaticProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) StaticSubclassProc );
}

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
//      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
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


HB_FUNC( HWG_INITEDITPROC )
{
   wpOrigEditProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) EditSubclassProc );
}

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
//      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
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

HB_FUNC( HWG_INITBUTTONPROC )
{
//   wpOrigButtonProc = (WNDPROC) SetWindowLong( (HWND) HB_PARHANDLE(1),
//                                 GWL_WNDPROC, (LONG) ButtonSubclassProc );
   wpOrigButtonProc =
         ( LONG_PTR ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) ButtonSubclassProc );

}

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
//      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
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
//      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
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

HB_FUNC( HWG_INITLISTPROC )
{
   wpOrigListProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) ListSubclassProc );
}


HB_FUNC( HWG_INITUPDOWNPROC )
{
   wpOrigUpDownProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) UpDownSubclassProc );
}

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
//      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
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

HB_FUNC( HWG_INITDATEPICKERPROC )
{
   wpOrigDatePickerProc =
         ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ), GWLP_WNDPROC,
         ( LONG_PTR ) DatePickerSubclassProc );
}

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
//      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
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

HB_FUNC( HWG_INITTRACKPROC )
{
   wpOrigTrackProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) TrackSubclassProc );
}

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
//      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
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

HB_FUNC( HWG_INITTABPROC )
{
   wpOrigTabProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) TabSubclassProc );
}

LRESULT APIENTRY TabSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   /*
    * Click suppression on disabled tabs.
    * Without this, Windows still changes the selection briefly and the
    * application has to revert it, causing visible flicker.
    *
    * Additional PATCH:
    * - Clicking the already active tab does NOT let the tab steal focus from the current GET.
    */
   if( message == WM_LBUTTONDOWN || message == WM_LBUTTONDBLCLK || message == WM_LBUTTONUP )
   {
         TCHITTESTINFO ht;
         int iTab;

         ht.pt.x = GET_X_LPARAM( lParam );
         ht.pt.y = GET_Y_LPARAM( lParam );
         ht.flags = 0;
         iTab = TabCtrl_HitTest( hWnd, &ht ); /* 0-based */

         /* 1) If the tab is inactive: it consumes and does NOT steal focus */
         if( iTab >= 0 && hwg_tab_is_disabled( hWnd, iTab + 1 ) )
               return 0;

         /* 2) If the already active tab was clicked: consume the event to avoid stealing focus from the GET */
         if( iTab >= 0 )
         {
               int iCur = TabCtrl_GetCurSel( hWnd ); /* 0-based */
               if( iCur == iTab )
                     return 0;
         }
   }

   /* -----------------------------------------------------------------
    * Paint hook: overlay disabled captions in gray (Windows)
    * - Keeps default tab rendering (works with nested tabs)
    * ----------------------------------------------------------------- */
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
         /* First let the original draw */
         LRESULT lr = CallWindowProc( wpOrigTabProc, hWnd, message, wParam, lParam );

         /* Then overlay on provided DC */
         if( ( HDC ) wParam )
               hwg_tab_draw_disabled_captions( hWnd, ( HDC ) wParam );

         return lr;
   }
   //End add tab hide

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
//      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
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

#if ( defined(__MINGW32__) || defined(__MINGW64__) ) && !defined(LPNMTBGETINFOTIP)
typedef struct tagNMTBGETINFOTIPA
{
   NMHDR hdr;
   LPSTR pszText;
   int cchTextMax;
   int iItem;
   LPARAM lParam;
} NMTBGETINFOTIPA, *LPNMTBGETINFOTIPA;

typedef struct tagNMTBGETINFOTIPW
{
   NMHDR hdr;
   LPWSTR pszText;
   int cchTextMax;
   int iItem;
   LPARAM lParam;
} NMTBGETINFOTIPW, *LPNMTBGETINFOTIPW;

#ifdef UNICODE
#define LPNMTBGETINFOTIP        LPNMTBGETINFOTIPW
#else
#define LPNMTBGETINFOTIP        LPNMTBGETINFOTIPA
#endif

#endif

HB_FUNC( HWG_CREATETOOLBAR )
{

   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulExStyle =
         ( ( !HB_ISNIL( 8 ) ) ? hb_parnl( 8 ) : 0 ) | ( ( ulStyle & WS_BORDER ) ?
         WS_EX_CLIENTEDGE : 0 );

   HWND hWndCtrl = CreateWindowEx( ulExStyle,   /* extended style */
         TOOLBARCLASSNAME,      /* predefined class  */
         NULL,                  /* title   -   TBSTYLE_TRANSPARENT | */
         WS_CHILD | WS_OVERLAPPED | WS_VISIBLE | TBSTYLE_ALTDRAG | TBSTYLE_TOOLTIPS |  TBSTYLE_WRAPABLE | CCS_TOP | CCS_NORESIZE | ulStyle, /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ),
         NULL );

   HB_RETHANDLE( hWndCtrl );

}

/*
   hwg_Toolbaraddbuttons( handle, aItem, nLen )
   nLen : Set to Len(aItem )
*/

HB_FUNC( HWG_TOOLBARADDBUTTONS )
{

   HWND hWndCtrl = ( HWND ) HB_PARHANDLE( 1 );
   /* HWND hToolTip = ( HWND ) HB_PARHANDLE( 4 ) ; */
   PHB_ITEM pArray = hb_param( 2, HB_IT_ARRAY );
   int iButtons = hb_parni( 3 );
   TBBUTTON *tb =
         ( struct _TBBUTTON * ) hb_xgrab( iButtons * sizeof( TBBUTTON ) );
   PHB_ITEM pTemp;

   ULONG ulCount;
   ULONG ulID;
   DWORD style = GetWindowLong( hWndCtrl, GWL_STYLE );

   //SendMessage(hWndCtrl, CCM_SETVERSION, (WPARAM) 4, 0);

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
         tb[ulCount].iBitmap = ulID - 1;   //ulID > 0 ? ( int ) ulCount : -1 ;
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


HB_FUNC( HWG_TOOLBAR_SETBUTTONINFO )
{
   TBBUTTONINFO tb;
   HWND hWndCtrl = ( HWND ) HB_PARHANDLE( 1 );
   int iIDB = hb_parni( 2 );
   void * hStr;

   tb.cbSize = sizeof( tb );
   tb.dwMask = TBIF_TEXT;
   tb.pszText = ( LPTSTR ) HB_PARSTR( 3, &hStr, NULL );
   //tb.cchText = 1000  ;

   SendMessage( hWndCtrl, TB_SETBUTTONINFO, iIDB, ( LPARAM ) & tb );
}

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

HB_FUNC( HWG_TOOLBAR_LOADSTANDARTIMAGE )
{
   TBADDBITMAP tbab;
   HWND hWndCtrl = ( HWND ) HB_PARHANDLE( 1 );
   int iIDB = hb_parni( 2 );
   HIMAGELIST himl;

   tbab.hInst = HINST_COMMCTRL;
   tbab.nID = iIDB;             //IDB_HIST_SMALL_COLOR / IDB_VIEW_SMALL_COLOR / IDB_VIEW_SMALL_COLOR;

   SendMessage( hWndCtrl, TB_ADDBITMAP, 0, ( LPARAM ) & tbab );
   himl = ( HIMAGELIST ) SendMessage( hWndCtrl, TB_GETIMAGELIST, 0, 0 );
   hb_retni( ( int ) ImageList_GetImageCount( himl ) );
}

HB_FUNC( HWG_IMAGELIST_GETIMAGECOUNT )
{
   HIMAGELIST hWndCtrl = ( HIMAGELIST ) HB_PARHANDLE( 1 );
   hb_retni( ImageList_GetImageCount( hWndCtrl ) );
}

HB_FUNC( HWG_TOOLBAR_SETDISPINFO )
{
   //LPTOOLTIPTEXT pDispInfo = ( LPTOOLTIPTEXT ) HB_PARHANDLE( 1 );
   LPNMTTDISPINFO pDispInfo = ( LPNMTTDISPINFO ) HB_PARHANDLE( 1 );

   if( pDispInfo )
   {
      HB_ITEMCOPYSTR( hb_param( 2, HB_IT_ANY ), pDispInfo->szText,
                      HB_SIZEOFARRAY( pDispInfo->szText ) );
      pDispInfo->szText[ HB_SIZEOFARRAY( pDispInfo->szText ) - 1 ] = 0;
#if 0
      /* is it necessary? */
      if( !pDispInfo->hinst )
         pDispInfo->lpszText = pDispInfo->szText;
#endif
   }
}

HB_FUNC( HWG_TOOLBAR_GETDISPINFOID )
{
   //LPTOOLTIPTEXT pDispInfo = ( LPTOOLTIPTEXT ) hb_parnl( 1 );
   LPNMTTDISPINFO pDispInfo = ( LPNMTTDISPINFO ) HB_PARHANDLE( 1 );
   DWORD idButton = pDispInfo->hdr.idFrom;
   hb_retnl( idButton );
}

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

HB_FUNC( HWG_TOOLBAR_GETINFOTIPID )
{
   LPNMTBGETINFOTIP pDispInfo = ( LPNMTBGETINFOTIP ) HB_PARHANDLE( 1 );
   DWORD idButton = pDispInfo->iItem;
   hb_retnl( idButton );
}

HB_FUNC( HWG_TOOLBAR_IDCLICK )
{
   LPNMMOUSE pDispInfo = ( LPNMMOUSE ) HB_PARHANDLE( 1 );
   DWORD idButton = pDispInfo->dwItemSpec;
   hb_retnl( idButton );
}

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
   // tpm.rcExclude = rc;
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
   //rc.left, rc.bottom, g_hwndMain, &tpm);

   DestroyMenu( hMenuLoaded );

}

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
   //tpm.rcExclude = rc;
   tpm.rcExclude.left = rc.left;
   tpm.rcExclude.top = rc.top;
   tpm.rcExclude.bottom = rc.bottom;
   tpm.rcExclude.right = rc.right;
   TrackPopupMenuEx( hPopupMenu,
         TPM_LEFTALIGN | TPM_LEFTBUTTON | TPM_VERTICAL,
         rc.left, rc.bottom, g_hwndMain, &tpm );
   //rc.left, rc.bottom, g_hwndMain, &tpm);

}

HB_FUNC( HWG_TOOLBAR_SUBMENUEXGETID )
{

   LPNMTOOLBAR lpnmTB = ( LPNMTOOLBAR ) HB_PARHANDLE( 1 );
   hb_retnl( ( LONG ) lpnmTB->iItem );
}

HB_FUNC( HWG_CREATEPAGER )
{
   HWND hWndPanel;
   BOOL bVert = hb_parl( 8 );
   hWndPanel = CreateWindow( WC_PAGESCROLLER,   /* predefined class  */
         NULL,                  /* no window title   */
         WS_CHILD | WS_VISIBLE | bVert ? PGS_VERT : PGS_HORZ | hb_parnl( 3 ),   /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( hWndPanel );

}

HB_FUNC( HWG_CREATEREBAR )
{
   ULONG ulStyle = hb_parnl( 3 );
   ULONG ulExStyle =
         ( ( !HB_ISNIL( 8 ) ) ? hb_parnl( 8 ) : 0 ) | ( ( ulStyle & WS_BORDER ) ?
         WS_EX_CLIENTEDGE : 0 ) | WS_EX_TOOLWINDOW;
   HWND hWndCtrl = CreateWindowEx( ulExStyle,   /* extended style */
         REBARCLASSNAME,        /* predefined class  */
         NULL,                  /* title   */
         WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | WS_CLIPCHILDREN | RBS_VARHEIGHT | CCS_NODIVIDER | ulStyle,   /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU )( UINT_PTR ) hb_parni( 2 ),       /* control ID  */
         GetModuleHandle( NULL ),
         NULL );


   HB_RETHANDLE( hWndCtrl );

}

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

HB_FUNC( HWG_EDIT_GETPOS )
{

   hb_retni( ( ( SendMessage( ( HWND ) HB_PARHANDLE( 1 ), EM_GETSEL, 0, 0 ) >> 16 ) & 0xFFFF ) + 1 );
}

HB_FUNC( HWG_EDIT_SETPOS )
{
   int iPos = hb_parni(2) - 1;
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), EM_SETSEL, (WPARAM) iPos, (LPARAM) iPos );
}

HB_FUNC( HWG_COMBOGETITEMRECT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );

   int nIndex = hb_parnl( 2 );
   RECT rcItem;
   SendMessage( hWnd, LB_GETITEMRECT, nIndex, ( LPARAM) & rcItem );
   hb_itemRelease( hb_itemReturn( Rect2Array( &rcItem ) ) );
}

HB_FUNC( HWG_COMBOBOXGETITEMDATA )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int nIndex = hb_parnl( 2 );
   DWORD_PTR p;
   p = ( DWORD_PTR ) SendMessage( ( HWND ) hWnd, CB_GETITEMDATA, nIndex, 0 );
   hb_retnl( p );

}

HB_FUNC( HWG_COMBOBOXSETITEMDATA )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int nIndex = hb_parnl( 2 );
   DWORD_PTR dwItemData = ( DWORD_PTR ) hb_parnl( 3 );
   hb_retnl( SendMessage( ( HWND ) hWnd, CB_SETITEMDATA, nIndex,
               ( LPARAM ) dwItemData ) );
}

HB_FUNC( HWG_GETLOCALEINFO )
{
   TCHAR szBuffer[10] = { 0 };
   GetLocaleInfo( LOCALE_USER_DEFAULT, LOCALE_SLIST, szBuffer,
                  HB_SIZEOFARRAY( szBuffer ) );
   HB_RETSTR( szBuffer );
}


HB_FUNC( HWG_COMBOBOXGETLBTEXT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   int nIndex = hb_parnl( 2 );
   TCHAR lpszText[255] = { 0 };
   hb_retni( SendMessage( hWnd, CB_GETLBTEXT, nIndex,
                          ( LPARAM ) lpszText ) );
   HB_STORSTR( lpszText, 3 );
}

HB_FUNC( HWG_DEFWINDOWPROC )
{
//   WNDPROC wpProc = (WNDPROC) hb_parnl(1);
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   LONG message = hb_parnl( 2 );
   WPARAM wParam = ( WPARAM ) hb_parnl( 3 );
   LPARAM lParam = ( LPARAM ) hb_parnl( 4 );

   hb_retnl( DefWindowProc( hWnd, message, wParam, lParam ) );
}


HB_FUNC( HWG_CALLWINDOWPROC )
{
   WNDPROC wpProc = ( WNDPROC ) ( ULONG_PTR ) hb_parnl( 1 );
   HWND hWnd = ( HWND ) HB_PARHANDLE( 2 );
   LONG message = hb_parnl( 3 );
   WPARAM wParam = ( WPARAM ) hb_parnl( 4 );
   LPARAM lParam = ( LPARAM ) hb_parnl( 5 );

   hb_retnl( CallWindowProc( wpProc, hWnd, message, wParam, lParam ) );
}


HB_FUNC( HWG_BUTTONGETDLGCODE )
{
   LPARAM lParam = ( LPARAM ) HB_PARHANDLE( 1 );
   if( lParam )
   {
      MSG *pMsg = ( MSG * ) lParam;

      if( pMsg && ( pMsg->message == WM_KEYDOWN ) &&
            ( pMsg->wParam == VK_TAB ) )
      {
         // don't interfere with tab processing
         hb_retnl( 0 );
         return;
      }


   }
   hb_retnl( DLGC_WANTALLKEYS );        // we want all keys except TAB key
}


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

HB_FUNC( HWG_TABITEMPOS )
{
   RECT pRect;
   TabCtrl_GetItemRect( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), &pRect );
   hb_itemRelease( hb_itemReturn( Rect2Array( &pRect ) ) );
}

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

HB_FUNC( HWG_GETUTCTIMEDATE )
{
      SYSTEMTIME st;

   #if defined( HB_WIN_UNICODE )
      WCHAR cst[41] = { 0 };
      GetSystemTime( &st );
      swprintf( cst, L"%01d.%04d%02d%02d-%02d:%02d:%02d",
                st.wDayOfWeek, st.wYear, st.wMonth, st.wDay,
                st.wHour, st.wMinute, st.wSecond );
      HB_RETSTR( cst );
   #else
      char cst[41] = { 0 };
      GetSystemTime( &st );
      sprintf( cst, "%01d.%04d%02d%02d-%02d:%02d:%02d",
               st.wDayOfWeek, st.wYear, st.wMonth, st.wDay,
               st.wHour, st.wMinute, st.wSecond );
      hb_retc( cst );
   #endif
}

HB_FUNC( HWG_GETDATEANSI )
{
      SYSTEMTIME st;

   #if defined( HB_WIN_UNICODE )
      WCHAR cst[41] = { 0 };
      GetLocalTime( &st );
      swprintf( cst, L"%04d%02d%02d", st.wYear, st.wMonth, st.wDay );
      HB_RETSTR( cst );
   #else
      char cst[41] = { 0 };
      GetLocalTime( &st );
      sprintf( cst, "%04d%02d%02d", st.wYear, st.wMonth, st.wDay );
      hb_retc( cst );
   #endif
}

HB_FUNC( HWG_GETLOCALEINFON )
{
/* returns Windows LCID, type is int */
   int lio;
   lio = GetLocaleInfo( LOCALE_USER_DEFAULT, LOCALE_SLIST, NULL,
                  0 );
   hb_retni(lio);
}

HB_FUNC( HWG_DEFUSERLANG )
{
   #if defined( HB_WIN_UNICODE )
      WCHAR clang[10] = { 0 };
      GetLocaleInfoW( LOCALE_USER_DEFAULT, LOCALE_SABBREVLANGNAME, clang, 10 );
      HB_RETSTR( clang );
   #else
      char clang[10] = { 0 };
      GetLocaleInfoA( LOCALE_USER_DEFAULT, LOCALE_SABBREVLANGNAME, clang, 10 );
      hb_retc( clang );
   #endif
}

/*
 DF7BE : Ticket #64
 hwg_ShowCursor( lcursor )
*/
HB_FUNC( HWG_SHOWCURSOR )
{
  hb_retni(ShowCursor(hb_parl( 1 ) ) );
}

/* ====================== EOF of control.c ======================= */

