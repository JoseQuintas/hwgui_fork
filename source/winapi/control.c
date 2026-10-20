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
#include "hbapicls.h"
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

/* Dark-mode helpers used by hwg_theme_init_once() near the top of this
 * file.  The actual implementations live much further below; these are
 * just forward declarations so the compiler accepts the calls. */
#define HWG_LOCAL_APPMODE_FORCEDARK  2
BOOL hwg_should_apps_use_dark_mode( void );
HBRUSH hwg_get_dark_brush( int nKind );

int  hwg_set_preferred_app_mode( int nMode );

static void CALLBACK s_timerProc( HWND, UINT, UINT_PTR, DWORD );

/* Forward declaration: defined further below in this file. */
static void s_InitCommonControls( void );

static HWND hWndTT = 0;
static BOOL lInitCmnCtrl = 0;
static BOOL lToolTipBalloon = FALSE;    // added by MAG
static WNDPROC wpOrigEditProc, wpOrigTrackProc, wpOrigTabProc, wpOrigListProc, wpOrigUpDownProc, wpOrigDatePickerProc,  wpOrigTreeViewProc;
static LONG_PTR wpOrigButtonProc;

/*=============================================================================
 * hwg_GetControlBrush
 *
 * Returns the HBRUSH stored on the HWGUI object attached to hWnd, or
 * NULL if the window has no PRG object / no brush set.
 *
 * HControl stores its background brush as ::brush (an HBrush object).
 * Older subclasses also used ::hBrush (numeric handle), so we probe both.
 *===========================================================================*/
static HBRUSH hwg_GetControlBrush( HWND hWnd )
{
      PHB_ITEM pObj;
      PHB_ITEM pBrush;
      PHB_ITEM pHandle;
      HBRUSH   hBr = NULL;
      static PHB_DYNS s_pSymHandle = NULL;

      if( hWnd == NULL ) return NULL;

      /* Get the HWGUI object attached to the window */
      pObj = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

      /* Safety check: if the object was released (theme change), return NULL */
      if( pObj == NULL || !HB_IS_OBJECT( pObj ) )
            return NULL;

      /* Try to read the DATA ::brush */
      pBrush = GetObjectVar( pObj, "BRUSH" );
      if( pBrush == NULL )
            return NULL;

      if( HB_IS_NUMERIC( pBrush ) )
      {
            hBr = ( HBRUSH ) ( HB_PTRUINT ) hb_itemGetNInt( pBrush );
      }
      else if( HB_IS_POINTER( pBrush ) )
      {
            hBr = ( HBRUSH ) hb_itemGetPtr( pBrush );
      }
      else if( HB_IS_OBJECT( pBrush ) )
      {
            /* It's an HBrush object. Verify the ::handle DATA exists before reading */
            if( s_pSymHandle == NULL )
                  s_pSymHandle = hb_dynsymFindName( "HANDLE" );

            if( s_pSymHandle != NULL && hb_objHasMessage( pBrush, s_pSymHandle ) )
            {
                  pHandle = GetObjectVar( pBrush, "HANDLE" );
                  if( pHandle != NULL )
                  {
                        if( HB_IS_NUMERIC( pHandle ) )
                              hBr = ( HBRUSH ) ( HB_PTRUINT ) hb_itemGetNInt( pHandle );
                        else if( HB_IS_POINTER( pHandle ) )
                              hBr = ( HBRUSH ) hb_itemGetPtr( pHandle );
                  }
            }
      }

      return hBr;
}

/*=============================================================================
 * hwg_GetEffectiveBrush
 *
 * Returns a valid background brush for an owner-draw control by
 * walking up the parent chain until a non-NULL brush is found.
 * Falls back to WHITE_BRUSH (or dark brush) so owner-draw controls
 * never paint pure black inside tabs or nested containers.
 *===========================================================================*/
HBRUSH hwg_GetEffectiveBrush( HWND hWnd )
{
      HWND   hParent;
      HBRUSH hBr;
      int    nDepth = 0;

      if( hWnd == NULL )
      {
            if( hwg_should_apps_use_dark_mode() )
                  return hwg_get_dark_brush( 0 );

            return ( HBRUSH ) GetSysColorBrush( COLOR_3DFACE );
      }

      hParent = GetParent( hWnd );

      while( hParent != NULL && nDepth++ < 32 )
      {
            hBr = hwg_GetControlBrush( hParent );
            if( hBr != NULL )
                  return hBr;

            hParent = GetParent( hParent );
      }

      if( hwg_should_apps_use_dark_mode() )
            return hwg_get_dark_brush( 0 );

      return ( HBRUSH ) GetSysColorBrush( COLOR_3DFACE );
}

/*=============================================================================
 * HWG_GETEFFECTIVEBRUSH()
 *
 * PRG-visible wrapper around hwg_GetEffectiveBrush().
 *   1 - HWND of the control whose owner-draw paint needs a brush
 * Returns a valid HBRUSH (never 0).
 *===========================================================================*/
HB_FUNC( HWG_GETEFFECTIVEBRUSH )
{
      HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );

      hb_retnint( ( HB_PTRUINT ) hwg_GetEffectiveBrush( hWnd ) );
}

static void s_InitCommonControls( void )
{
      if( !lInitCmnCtrl )
      {
            INITCOMMONCONTROLSEX i;
            i.dwSize = sizeof( INITCOMMONCONTROLSEX );
            i.dwICC  = ICC_STANDARD_CLASSES | ICC_WIN95_CLASSES |
            ICC_DATE_CLASSES     | ICC_INTERNET_CLASSES |
            ICC_BAR_CLASSES      | ICC_LISTVIEW_CLASSES  |
            ICC_TAB_CLASSES      | ICC_TREEVIEW_CLASSES  |
            ICC_PROGRESS_CLASS   | ICC_UPDOWN_CLASS      ;
            InitCommonControlsEx( &i );
            lInitCmnCtrl = 1;
      }
}

/*=============================================================================
 * HWG_INITCOMMONCONTROLSEX()
 * Initializes Windows common controls
 * Called once to load all common control classes
 *===========================================================================*/
HB_FUNC( HWG_INITCOMMONCONTROLSEX )
{
      s_InitCommonControls();
}

/*=============================================================================
 * hwg_theme_init_once()
 * Ensures common controls are initialized exactly once, at application
 * startup, *before* any window/dialog is created.  Without this, the
 * first window created (usually the main window) is not themed and the
 * application stays stuck in the legacy look for its whole lifetime.
 *===========================================================================*/
BOOL hwg_theme_init_once( void )
{
      s_InitCommonControls();
      return TRUE;
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
 * HWG_PANEL_GETRECT()
 *
 * Returns the screen rectangle of a window as { left, top, right, bottom }.
 * Empty array if the handle is invalid.  Used by HPanel to save and
 * restore positions of owned dialogs when the sidebar is collapsed.
 *===========================================================================*/
HB_FUNC( HWG_PANEL_GETRECT )
{
      HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
      RECT rc;
      PHB_ITEM pArr = hb_itemArrayNew( 4 );

      if( hWnd != NULL && GetWindowRect( hWnd, &rc ) )
      {
            hb_arraySetNI( pArr, 1, rc.left   );
            hb_arraySetNI( pArr, 2, rc.top    );
            hb_arraySetNI( pArr, 3, rc.right  );
            hb_arraySetNI( pArr, 4, rc.bottom );
      }
      hb_itemReturnRelease( pArr );
}

/*=============================================================================
 * HWG_PANEL_ENUMOWNED()
 *
 * Returns an array of HWNDs of top-level windows owned by hOwner and
 * currently visible.  Used by HPanel to shift module dialogs when the
 * sidebar is collapsed or expanded.
 *
 * "Owned" here means GetWindow(hWnd, GW_OWNER) == hOwner, which is the
 * standard relationship set by CreateWindowEx when the parent is passed
 * as the owner.  HWGUI dialogs created with "OF oFormMain" fall into
 * this category.
 *===========================================================================*/
HB_FUNC( HWG_PANEL_ENUMOWNED )
{
      HWND hOwner = ( HWND ) HB_PARHANDLE( 1 );
      PHB_ITEM pArr = hb_itemArrayNew( 0 );
      HWND hWnd;
      PHB_ITEM pItem;

      if( hOwner != NULL )
      {
            hWnd = GetWindow( hOwner, GW_HWNDFIRST );
            while( hWnd != NULL )
            {
                  if( hWnd != hOwner &&
                        GetWindow( hWnd, GW_OWNER ) == hOwner &&
                        IsWindowVisible( hWnd ) )
                  {
                        /* Store the handle as a numeric instead of a pointer.
                         * hb_itemPutPtr() maps a NULL HWND to Nil in some
                         * Harbour builds, and comparing a pointer item with a
                         * numeric 0 in PRG raises "Argument error: ==".
                         * HWND fits in HB_PTRUINT, so a number is safe. */
                        pItem = hb_itemPutNInt( NULL, ( HB_PTRUINT ) hWnd );
                        hb_arrayAdd( pArr, pItem );
                        hb_itemRelease( pItem );
                  }
                  hWnd = GetWindow( hWnd, GW_HWNDNEXT );
            }
      }

      hb_itemReturnRelease( pArr );
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
 * HWG_SETWINDOWLONG()
 *
 * Thin wrapper around SetWindowLongPtr for use from the PRG side.
 *
 * The 32-bit variant SetWindowLong is not usable here because HWND and
 * LONG_PTR are pointer-sized: on 64-bit Windows, using the 32-bit call
 * would truncate the parent HWND and corrupt the window hierarchy.
 * SetWindowLongPtr is the correct call on both architectures.
 *
 * Parameters:
 *   1 - HWND of the target window
 *   2 - index (e.g. GWLP_HWNDPARENT = -8, GWL_STYLE = -16,
 *       GWL_EXSTYLE = -20)
 *   3 - new value (numeric; a handle or a style mask)
 *
 * Returns:
 *   The previous value, or 0 on error.
 *
 * Typical use from HWGUI PRG code:
 *   // Set oFormMain as the owner of a newly created dialog so it
 *   // participates in HPanel collapse / expand tracking.
 *   hwg_SetWindowLong( oDlg:handle, GWLP_HWNDPARENT, oFormMain:handle )
 *===========================================================================*/
HB_FUNC( HWG_SETWINDOWLONG )
{
      HWND      hWnd = ( HWND ) HB_PARHANDLE( 1 );
      int       nIdx = hb_parni( 2 );
      LONG_PTR  v    = ( LONG_PTR ) hb_parnint( 3 );

      hb_retnint( ( HB_PTRUINT ) SetWindowLongPtr( hWnd, nIdx, v ) );
}

/*=============================================================================
 * HWG_CREATEBUTTON()
 * Creates a button control
 *===========================================================================*/
HB_FUNC( HWG_CREATEBUTTON )
{
      void * hStr;
      ULONG ulStyle = hb_parnl( 3 );
      ULONG ulExStyle = 0;

      /* FIX: For GroupBoxes, ensure it is transparent (no grey bg) and
       * add WS_CLIPCHILDREN so it doesn't paint over the GETs inside it. */
      if( ( ulStyle & 0x0F ) == BS_GROUPBOX )
      {
            ulExStyle |= WS_EX_TRANSPARENT;
            ulStyle   |= WS_CLIPCHILDREN;
      }

      HWND hBtn = CreateWindowEx( ulExStyle,
                                  TEXT( "BUTTON" ),
                                  HB_PARSTR( 8, &hStr, NULL ),
                                  WS_CHILD | WS_VISIBLE | ulStyle,
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
 * HWG_GETDRAWITEMHWND()
 * Returns the control HWND stored in the DRAWITEMSTRUCT.
 *
 * Needed because onDrawItem must locate the target control by its
 * window handle: the CtlID field is not unique (several HStatic
 * controls default to id 0), and FindControl by id would then hit
 * the wrong control.
 *===========================================================================*/
HB_FUNC( HWG_GETDRAWITEMHWND )
{
      DRAWITEMSTRUCT * lpDis = ( DRAWITEMSTRUCT * ) HB_PARHANDLE( 1 );

      if( lpDis )
            HB_RETHANDLE( lpDis->hwndItem );
      else
            HB_RETHANDLE( NULL );
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
 * Timer registry
 *
 * HWG_SETTIMER used to accept only (hWnd, nId, nElapse) and route the
 * tick through a fixed global PRG function HWG_TIMERPROC.  That is
 * fine for one-shot applications but useless for a library, because
 * HPanel (and any other control that wants its own timer) needs to
 * receive a private callback.
 *
 * This registry keeps a small table of (hWnd, nId, codeblock) entries.
 * When the timer fires, s_timerProcBlock looks up the entry and
 * evaluates its codeblock in the PRG VM.
 *
 * Notes:
 *   - The callback runs on the same thread that installed the timer,
 *     which is the main UI thread.  No cross-thread access, no lock
 *     contention in practice.  The critical section is only here to
 *     protect against KillTimer / SetTimer being called from the PRG
 *     while a tick is in flight.
 *   - Each entry owns a reference to its codeblock (hb_itemNew).  That
 *     reference is released in HWG_KILLTIMER and in hwg_timersExit.
 *===========================================================================*/

#define HWG_MAX_TIMERS 128

typedef struct {
      HWND     hWnd;
      UINT_PTR nId;
      PHB_ITEM pBlock;
} HWG_TIMER_ENTRY;

static HWG_TIMER_ENTRY s_timers[HWG_MAX_TIMERS];
static CRITICAL_SECTION s_timersCS;
static BOOL s_timersInit = FALSE;

static void s_timersEnsureInit( void )
{
      if( !s_timersInit )
      {
            InitializeCriticalSection( &s_timersCS );
            s_timersInit = TRUE;
      }
}

static int s_timerFind( HWND hWnd, UINT_PTR nId )
{
      int i;

      for( i = 0; i < HWG_MAX_TIMERS; i++ )
      {
            if( s_timers[i].pBlock != NULL &&
                  s_timers[i].hWnd   == hWnd &&
                  s_timers[i].nId    == nId )
                  return i;
      }
      return -1;
}

static int s_timerFindFree( void )
{
      int i;
      for( i = 0; i < HWG_MAX_TIMERS; i++ )
            if( s_timers[i].pBlock == NULL )
                  return i;
      return -1;
}

/* Callback installed for every codeblock-based timer.  Looks up the
 * entry and evaluates the stored codeblock with no arguments. */
static void CALLBACK s_timerProcBlock( HWND hWnd, UINT message, UINT_PTR nId, DWORD dwTime )
{
      PHB_ITEM pBlock = NULL;
      PHB_ITEM pRet;
      int      i;

      HB_SYMBOL_UNUSED( message );
      HB_SYMBOL_UNUSED( dwTime );

      EnterCriticalSection( &s_timersCS );
      i = s_timerFind( hWnd, nId );
      if( i >= 0 )
            pBlock = s_timers[i].pBlock;
      LeaveCriticalSection( &s_timersCS );

      if( pBlock != NULL )
      {
            pRet = hb_itemDo( pBlock, 0 );
            if( pRet != NULL )
                  hb_itemRelease( pRet );
      }
}

/*=============================================================================
 * HWG_SETTIMER()
 * Installs a timer.
 *
 * Parameters:
 *   1 - HWND of the window that owns the timer
 *   2 - numeric timer id (unique per window)
 *   3 - interval in milliseconds
 *   4 - optional codeblock {|| ... } evaluated on every tick
 *
 * Behaviour:
 *   - With a codeblock: the callback is stored in the registry and
 *     evaluated on the main thread by s_timerProcBlock.  Use this
 *     form for control-owned timers (HPanel:SetAutoCollapse, etc.).
 *   - Without a codeblock (3 params): the tick is routed through the
 *     legacy global PRG function HWG_TIMERPROC / HWG_PANEL_TIMERPROC,
 *     kept for backwards compatibility.
 *   - With any other 4th parameter (e.g. .T.): treated as "no
 *     codeblock, no callback" - the OS posts WM_TIMER to the window,
 *     matching the historical behaviour.
 *===========================================================================*/
HB_FUNC( HWG_SETTIMER )
{
      HWND       hWnd     = ( HWND ) HB_PARHANDLE( 1 );
      UINT_PTR   nId      = ( UINT_PTR ) hb_parni( 2 );
      UINT       nElapse  = ( UINT ) hb_parni( 3 );
      PHB_ITEM   pBlock   = hb_param( 4, HB_IT_BLOCK );
      TIMERPROC  pProc    = NULL;
      UINT_PTR   nRes;
      int        i;

      s_timersEnsureInit();

      if( pBlock != NULL )
      {
            EnterCriticalSection( &s_timersCS );
            i = s_timerFind( hWnd, nId );
            if( i >= 0 )
            {
                  hb_itemRelease( s_timers[i].pBlock );
                  s_timers[i].pBlock = hb_itemNew( pBlock );
            }
            else
            {
                  i = s_timerFindFree();
                  if( i >= 0 )
                  {
                        s_timers[i].hWnd   = hWnd;
                        s_timers[i].nId    = nId;
                        s_timers[i].pBlock = hb_itemNew( pBlock );
                  }
            }
            LeaveCriticalSection( &s_timersCS );

            if( i < 0 )
            {
                  hb_retni( 0 );
                  return;
            }

            pProc = s_timerProcBlock;
      }
      else if( hb_pcount() == 3 )
      {
            /* Legacy path: global dispatcher. */
            pProc = s_timerProc;
      }
      /* else: 4th parameter present but not a codeblock -> pProc = NULL,
       *      Windows posts WM_TIMER to the window. */

      nRes = SetTimer( hWnd, nId, nElapse, pProc );

      hb_retni( ( int ) nRes );
}

/*=============================================================================
 * HWG_KILLTIMER()
 * Removes a timer and releases its codeblock reference, if any.
 *===========================================================================*/
HB_FUNC( HWG_KILLTIMER )
{
      HWND     hWnd = ( HWND ) HB_PARHANDLE( 1 );
      UINT_PTR nId  = ( UINT_PTR ) hb_parni( 2 );
      int      i;
      BOOL     res;

      s_timersEnsureInit();

      EnterCriticalSection( &s_timersCS );
      i = s_timerFind( hWnd, nId );
      if( i >= 0 )
      {
            hb_itemRelease( s_timers[i].pBlock );
            s_timers[i].pBlock = NULL;
            s_timers[i].hWnd   = NULL;
            s_timers[i].nId    = 0;
      }
      LeaveCriticalSection( &s_timersCS );

      res = KillTimer( hWnd, nId );
      hb_retl( res );
}

/*=============================================================================
 * hwg_timersExit()
 * Called from HWG_EXITPROC.  Releases any codeblock still held by the
 * registry so the PRG VM can shut down cleanly.
 *===========================================================================*/
void hwg_timersExit( void )
{
      int i;

      if( !s_timersInit )
            return;

      EnterCriticalSection( &s_timersCS );
      for( i = 0; i < HWG_MAX_TIMERS; i++ )
      {
            if( s_timers[i].pBlock != NULL )
            {
                  hb_itemRelease( s_timers[i].pBlock );
                  s_timers[i].pBlock = NULL;
            }
      }
      LeaveCriticalSection( &s_timersCS );

      DeleteCriticalSection( &s_timersCS );
      s_timersInit = FALSE;
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
static void CALLBACK s_timerProc( HWND hWnd, UINT message, UINT_PTR idTimer, DWORD dwTime )
{
      static PHB_DYNS s_pSymPanel  = NULL;
      static PHB_DYNS s_pSymLegacy = NULL;
      PHB_DYNS pSym = NULL;

      HB_SYMBOL_UNUSED( message );
      HB_SYMBOL_UNUSED( dwTime );

      if( s_pSymPanel == NULL )
            s_pSymPanel  = hb_dynsymGetCase( "HWG_PANEL_TIMERPROC" );
      if( s_pSymLegacy == NULL )
            s_pSymLegacy = hb_dynsymGetCase( "HWG_TIMERPROC" );

      /* Prefer the panel-specific dispatcher; fall back to the legacy
       * generic name for code that already defined HWG_TIMERPROC. */
      if( s_pSymPanel != NULL && hb_dynsymIsFunction( s_pSymPanel ) )
            pSym = s_pSymPanel;
      else if( s_pSymLegacy != NULL && hb_dynsymIsFunction( s_pSymLegacy ) )
            pSym = s_pSymLegacy;

      if( pSym != NULL )
      {
            hb_vmPushDynSym( pSym );
            hb_vmPushNil();
            HB_PUSHITEM( hWnd );
            hb_vmPushLong( ( LONG ) idTimer );   /* UINT_PTR -> LONG, safe for ids */
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
 *
 * The original window procedure is stored as a window property, keyed
 * by the control handle, instead of a single global.  This is required
 * because an application typically creates many STATIC controls (every
 * SAY is one), and a shared global would be overwritten on each new
 * creation, causing the wrong proc to be restored by a previously
 * subclassed control.
 *
 * Also guards against double-subclassing: calling this twice on the
 * same handle is a no-op, so HStatic:Init() can call it safely.
 *===========================================================================*/
HB_FUNC( HWG_INITSTATICPROC )
{
      HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
      WNDPROC pOld;

      if( !IsWindow( hWnd ) )
            return;

      if( GetProp( hWnd, TEXT( "HWGUI_OLD_STATIC_PROC" ) ) != NULL )
            return;

      pOld = ( WNDPROC ) SetWindowLongPtr( hWnd, GWLP_WNDPROC,
                                           ( LONG_PTR ) StaticSubclassProc );
      SetProp( hWnd, TEXT( "HWGUI_OLD_STATIC_PROC" ), ( HANDLE ) pOld );
}

/*=============================================================================
 * StaticSubclassProc()
 * Static control subclass procedure
 *
 * Forwards every message to the Harbour object's onEvent().  If
 * onEvent() returns -1 the message is passed to the original window
 * procedure, which is fetched per-handle from the window property
 * instead of the old shared global.
 *===========================================================================*/
LRESULT APIENTRY StaticSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
                                     LPARAM lParam )
{
      long int res;
      PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );
      WNDPROC  pOld    = ( WNDPROC ) GetProp( hWnd, TEXT( "HWGUI_OLD_STATIC_PROC" ) );

      /* DEBUG: show only for mouse messages to avoid screen flood */
      if( message == WM_LBUTTONDOWN || message == WM_LBUTTONDBLCLK ||
            message == WM_LBUTTONUP )

      if( pOld == NULL )
            pOld = DefWindowProc;

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
                  return ( LRESULT ) HB_PARHANDLE( -1 );
            else
            {
                  res = hb_parnl( -1 );
                  if( res == -1 )
                        return CallWindowProc( pOld, hWnd, message, wParam, lParam );
                  else
                        return res;
            }
      }
      else
            return CallWindowProc( pOld, hWnd, message, wParam, lParam );
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

#define HWG_DARKEDIT_BORDER_RGB   RGB( 90, 90, 90 )

/*=============================================================================
 * hwg_dark_edit_ncpaint()
 *
 * HWGUI creates GETs with WS_EX_CLIENTEDGE: a 2px sunken edge that, on a dark
 * window, shows up as a bright white double line.  In dark mode this paints
 * the non-client border ourselves, keeping the SAME 2px so layout does not
 * change: the outer pixel in a muted grey and the inner pixel in the edit
 * background colour - the result looks like a thin, soft 1px border.
 *
 * Returns TRUE when the border was painted (caller returns 0 from
 * WM_NCPAINT).  Returns FALSE - and the default painting runs - when not in
 * dark mode, when the edit has no client edge, or when it has scroll bars
 * (the default procedure must keep drawing those).
 *===========================================================================*/
static BOOL hwg_dark_edit_ncpaint( HWND hWnd )
{
      LONG   lStyle, lExStyle;
      HDC    hdc;
      RECT   rcw, rcc, r;
      int    nB, i;
      HBRUSH hBorder;

      if( !hwg_should_apps_use_dark_mode() )
            return FALSE;

      lStyle   = GetWindowLong( hWnd, GWL_STYLE );
      lExStyle = GetWindowLong( hWnd, GWL_EXSTYLE );

      if( !( lExStyle & WS_EX_CLIENTEDGE ) ||
            ( lStyle & ( WS_VSCROLL | WS_HSCROLL ) ) )
            return FALSE;

      GetWindowRect( hWnd, &rcw );
      OffsetRect( &rcw, -rcw.left, -rcw.top );
      GetClientRect( hWnd, &rcc );

      /* Border thickness = (window width - client width) / 2 */
      nB = ( rcw.right - rcc.right ) / 2;
      if( nB < 1 )
            return FALSE;
      if( nB > 8 )
            nB = 8;

      hdc = GetWindowDC( hWnd );
      if( !hdc )
            return FALSE;

      hBorder = CreateSolidBrush( HWG_DARKEDIT_BORDER_RGB );

      r = rcw;
      FrameRect( hdc, &r, hBorder );                       /* outer pixel */
      for( i = 1; i < nB; i++ )
      {
            InflateRect( &r, -1, -1 );
            FrameRect( hdc, &r, hwg_get_dark_brush( 2 ) ); /* inner pixel(s) */
      }

      DeleteObject( hBorder );
      ReleaseDC( hWnd, hdc );

      return TRUE;
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

   /* ADDED FIX: When the GET becomes visible (e.g., switching tabs),
    * force the non-client area (border) to be redrawn immediately.
    * This ensures the dark border appears on GETs inside GroupBoxes without
    * needing to hover the mouse over them. */
   if( message == WM_SHOWWINDOW && wParam )
   {
         SetWindowPos( hWnd, NULL, 0, 0, 0, 0,
                       SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED );
   }

   if( message == WM_NCPAINT && hwg_dark_edit_ncpaint( hWnd ) )
       return 0;

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
 *===========================================================================*/
HB_FUNC( HWG_INITTABPROC )
{
      HWND     hTab  = ( HWND ) HB_PARHANDLE( 1 );
      LONG_PTR style = GetWindowLongPtr( hTab, GWL_STYLE );

      /* WS_CLIPCHILDREN is required so that repainting the tab area
       * does not erase the child controls (buttons, edits, etc.) */
      style |= WS_CLIPCHILDREN;
      SetWindowLongPtr( hTab, GWL_STYLE, style );

      /* Apply the native Windows theme to the TabControl headers */
      if( hwg_should_apps_use_dark_mode() )
      {
            /* Enable dark mode for this specific window (Windows 10 1809+). */
            typedef BOOL ( WINAPI * HWG_PFN_ALLOWDARKMODEFORWINDOW )( HWND, BOOL );
            HWG_PFN_ALLOWDARKMODEFORWINDOW pfnAllowDark = NULL;
            HMODULE hUx = LoadLibrary( TEXT( "uxtheme.dll" ) );
            if( hUx )
            {
                  pfnAllowDark = ( HWG_PFN_ALLOWDARKMODEFORWINDOW ) GetProcAddress( hUx, MAKEINTRESOURCEA( 133 ) );
                  if( pfnAllowDark )
                        pfnAllowDark( hTab, TRUE );
                  FreeLibrary( hUx );
            }
            SetWindowTheme( hTab, L"DarkMode_Explorer", NULL );
      }
      else
      {
            SetWindowTheme( hTab, L"", L"" );
      }

      wpOrigTabProc = ( WNDPROC ) SetWindowLongPtr( hTab,
                                                    GWLP_WNDPROC,
                                                    ( LONG_PTR ) TabSubclassProc );
}

#define HWG_DARKTAB_LINE_RGB   RGB( 90, 90, 90 )

/*=============================================================================
 * hwg_tab_hline()
 *===========================================================================*/
/*
static void hwg_tab_hline( HDC hdc, int x1, int x2, int y, HBRUSH hBr,
                           int xs1, int xs2 )
{
      RECT r;

      if( x2 <= x1 ) return;

      if( xs2 <= xs1 || xs2 <= x1 || xs1 >= x2 )
      {
            SetRect( &r, x1, y, x2, y + 1 );
            FillRect( hdc, &r, hBr );
            return;
      }

      if( xs1 > x1 )
      {
            SetRect( &r, x1, y, xs1, y + 1 );
            FillRect( hdc, &r, hBr );
      }
      if( xs2 < x2 )
      {
            SetRect( &r, xs2, y, x2, y + 1 );
            FillRect( hdc, &r, hBr );
      }
}
*/
/*=============================================================================
 * hwg_tab_soften_edges()
 *===========================================================================*/
/*
static void hwg_tab_soften_edges( HWND hTab, HDC hdc )
{
      RECT   rc, rcItem, rcSel, r;
      int    nCount, nSel, i, pass, yb = 0;
      BOOL   bHaveSel = FALSE, bHaveBase = FALSE;
      HBRUSH hBrLine, hBrFill;

      nCount = TabCtrl_GetItemCount( hTab );
      if( nCount <= 0 ) return;

      GetClientRect( hTab, &rc );
      nSel = TabCtrl_GetCurSel( hTab );
      SetRect( &rcSel, 0, 0, 0, 0 );

      hBrLine = CreateSolidBrush( HWG_DARKTAB_LINE_RGB );
      hBrFill = hwg_get_dark_brush( 0 );

      r = rc;
      InflateRect( &r, -1, -1 );
      FrameRect( hdc, &r, hBrFill );

      for( i = 0; i < nCount; i++ )
      {
            if( !TabCtrl_GetItemRect( hTab, i, &rcItem ) ) continue;
            if( i == nSel )
            {
                  rcSel = rcItem;
                  bHaveSel = TRUE;
            }
            else if( !bHaveBase )
            {
                  yb = rcItem.bottom;
                  bHaveBase = TRUE;
            }
      }

      if( bHaveBase )
      {
            hwg_tab_hline( hdc, rc.left + 1, rc.right - 1, yb, hBrLine,
                           bHaveSel ? rcSel.left : 0, bHaveSel ? rcSel.right : 0 );
            hwg_tab_hline( hdc, rc.left + 1, rc.right - 1, yb + 1, hBrFill,
                           bHaveSel ? rcSel.left : 0, bHaveSel ? rcSel.right : 0 );
      }

      for( pass = 0; pass < 2; pass++ )
      {
            for( i = 0; i < nCount; i++ )
            {
                  BOOL bSelTab  = ( i == nSel );
                  BOOL bLast    = ( i == nCount - 1 );
                  BOOL bPrevSel = ( i > 0 && ( i - 1 ) == nSel );

                  if( ( pass == 0 ) == bSelTab ) continue;
                  if( !TabCtrl_GetItemRect( hTab, i, &rcItem ) ) continue;

                  SetRect( &r, rcItem.left, rcItem.top, rcItem.right, rcItem.top + 1 );
                  FillRect( hdc, &r, hBrLine );
                  SetRect( &r, rcItem.left + 1, rcItem.top + 1, rcItem.right - 1, rcItem.top + 2 );
                  FillRect( hdc, &r, hBrFill );

                  SetRect( &r, rcItem.left, rcItem.top, rcItem.left + 1, rcItem.bottom );
                  FillRect( hdc, &r, ( bSelTab || !bPrevSel ) ? hBrLine : hBrFill );
                  SetRect( &r, rcItem.left + 1, rcItem.top + 1, rcItem.left + 2, rcItem.bottom );
                  FillRect( hdc, &r, hBrFill );

                  SetRect( &r, rcItem.right - 1, rcItem.top, rcItem.right, rcItem.bottom );
                  FillRect( hdc, &r, ( bSelTab || bLast ) ? hBrLine : hBrFill );
                  SetRect( &r, rcItem.right - 2, rcItem.top + 1, rcItem.right - 1, rcItem.bottom );
                  FillRect( hdc, &r, hBrFill );
            }
      }

      DeleteObject( hBrLine );
}
*/
/*=============================================================================
 * hwg_tab_background_brush()
 * 1. Developer custom brush (from parent or tab itself)
 * 2. Dark theme brush
 * 3. Windows theme color (COLOR_WINDOW)
 *===========================================================================*/
static HBRUSH hwg_tab_background_brush( HWND hWnd )
{
      /* 1. Try the tab's own brush first.
       * It will contain the developer's custom BACKCOLOR,
       * or the default White/Dark brush created in HTab:Init(). */
      HBRUSH hBg = hwg_GetControlBrush( hWnd );

      /* 2. Fallback to the parent's brush only if the tab has none
       * (e.g., during a transition or if created outside the PRG class). */
      if( !hBg ) hBg = hwg_GetControlBrush( GetParent( hWnd ) );

      if( hBg )
            return hBg;

      /* 3. Last resort: standard system colors */
      if( hwg_should_apps_use_dark_mode() )
            return hwg_get_dark_brush( 0 );

      return ( HBRUSH ) GetSysColorBrush( COLOR_WINDOW );
}

/*=============================================================================
 * TabUpDownSubclassProc()
 *===========================================================================*/
static LRESULT CALLBACK TabUpDownSubclassProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{
      WNDPROC pOld = ( WNDPROC ) GetProp( hWnd, TEXT( "HWGUI_OLD_UPDOWN_PROC" ) );
      if( !pOld ) return DefWindowProc( hWnd, message, wParam, lParam );

      if( message == WM_ERASEBKGND )
      {
            return 1; /* Blocks the white background erase */
      }

      if( message == WM_NCPAINT )
      {
            return 0; /* Prevents the white border from appearing */
      }

      if( message == WM_PAINT || message == WM_PRINTCLIENT )
      {
            HDC hdc;
            PAINTSTRUCT ps;
            RECT rc;
            BOOL bPrint = (message == WM_PRINTCLIENT);
            HBRUSH hBg;
            BOOL bIsDarkBg = FALSE;
            LOGBRUSH lb;

            if( bPrint )
                  hdc = ( HDC ) wParam;
            else
                  hdc = BeginPaint( hWnd, &ps );

            GetClientRect( hWnd, &rc );

            /* Fill background with the tab's color to avoid the white background */
            hBg = hwg_tab_background_brush( GetParent( hWnd ) );
            if( hBg )
            {
                  FillRect( hdc, &rc, hBg );

                  if( GetObject( hBg, sizeof( lb ), &lb ) && lb.lbStyle == BS_SOLID )
                  {
                        COLORREF cr = lb.lbColor;
                        if( GetRValue(cr) < 128 && GetGValue(cr) < 128 && GetBValue(cr) < 128 )
                              bIsDarkBg = TRUE;
                  }
            }
            else if( hwg_should_apps_use_dark_mode() )
            {
                  bIsDarkBg = TRUE;
            }

            if( bIsDarkBg )
            {
                  /* Draw a subtle border around the UpDown control to retain visual structure */
                  HBRUSH hBorder = CreateSolidBrush( HWG_DARKTAB_LINE_RGB );
                  FrameRect( hdc, &rc, hBorder );
                  DeleteObject( hBorder );
            }

            if( GetWindowLong( hWnd, GWL_STYLE ) & UDS_HORZ )
            {
                  int mid = ( rc.left + rc.right ) / 2;
                  RECT r1 = rc, r2 = rc;
                  r1.right = mid;
                  r2.left = mid;

                  if( bIsDarkBg )
                  {
                        HBRUSH hArrow = CreateSolidBrush( RGB( 220, 220, 220 ) );
                        HBRUSH hOldBr = SelectObject( hdc, hArrow );
                        HPEN hOldPen = SelectObject( hdc, GetStockObject( NULL_PEN ) );
                        POINT pt[3];

                        int cx_left  = ( rc.left + mid ) / 2;
                        int cx_right = ( mid + rc.right ) / 2;
                        int cy       = ( rc.top + rc.bottom ) / 2;
                        int size     = 6; /* Increased size for better visibility */

                        /* Left arrow */
                        pt[0].x = cx_left - size; pt[0].y = cy;
                        pt[1].x = cx_left + size; pt[1].y = cy - size;
                        pt[2].x = cx_left + size; pt[2].y = cy + size;
                        Polygon( hdc, pt, 3 );

                        /* Right arrow */
                        pt[0].x = cx_right + size; pt[0].y = cy;
                        pt[1].x = cx_right - size; pt[1].y = cy - size;
                        pt[2].x = cx_right - size; pt[2].y = cy + size;
                        Polygon( hdc, pt, 3 );

                        SelectObject( hdc, hOldPen );
                        SelectObject( hdc, hOldBr );
                        DeleteObject( hArrow );
                  }
                  else
                  {
                        DrawFrameControl( hdc, &r1, DFC_SCROLL, DFCS_SCROLLLEFT | DFCS_TRANSPARENT );
                        DrawFrameControl( hdc, &r2, DFC_SCROLL, DFCS_SCROLLRIGHT | DFCS_TRANSPARENT );
                  }
            }
            else
            {
                  int mid = ( rc.top + rc.bottom ) / 2;
                  RECT r1 = rc, r2 = rc;
                  r1.bottom = mid;
                  r2.top = mid;

                  if( bIsDarkBg )
                  {
                        HBRUSH hArrow = CreateSolidBrush( RGB( 220, 220, 220 ) );
                        HBRUSH hOldBr = SelectObject( hdc, hArrow );
                        HPEN hOldPen = SelectObject( hdc, GetStockObject( NULL_PEN ) );
                        POINT pt[3];

                        int cy_top    = ( rc.top + mid ) / 2;
                        int cy_bottom = ( mid + rc.bottom ) / 2;
                        int cx        = ( rc.left + rc.right ) / 2;
                        int size      = 6; /* Increased size for better visibility */

                        /* Up arrow */
                        pt[0].x = cx; pt[0].y = cy_top - size;
                        pt[1].x = cx - size; pt[1].y = cy_top + size;
                        pt[2].x = cx + size; pt[2].y = cy_top + size;
                        Polygon( hdc, pt, 3 );

                        /* Down arrow */
                        pt[0].x = cx; pt[0].y = cy_bottom + size;
                        pt[1].x = cx - size; pt[1].y = cy_bottom - size;
                        pt[2].x = cx + size; pt[2].y = cy_bottom - size;
                        Polygon( hdc, pt, 3 );

                        SelectObject( hdc, hOldPen );
                        SelectObject( hdc, hOldBr );
                        DeleteObject( hArrow );
                  }
                  else
                  {
                        DrawFrameControl( hdc, &r1, DFC_SCROLL, DFCS_SCROLLUP | DFCS_TRANSPARENT );
                        DrawFrameControl( hdc, &r2, DFC_SCROLL, DFCS_SCROLLDOWN | DFCS_TRANSPARENT );
                  }
            }

            if( !bPrint )
                  EndPaint( hWnd, &ps );
            return 0;
      }

      return CallWindowProc( pOld, hWnd, message, wParam, lParam );
}

static BOOL s_bTabPainting = FALSE;

/*=============================================================================
 * hwg_tab_paint_to_dc()
 *===========================================================================*/
static void hwg_tab_paint_to_dc( HWND hWnd, HDC hdc )
{
      RECT    rc, rcItem, rcBody, rcUpDown, rcRight, rT;
      HBRUSH  hBg, hLine, hTabBg;
      HRGN    hTabRgn;
      HWND    hUpDown;
      int     nCount, i, nHeaderBottom = 0;
      int     nSavedDC, nSel;

      GetClientRect( hWnd, &rc );
      if( rc.right <= rc.left || rc.bottom <= rc.top ) return;

      hBg = hwg_tab_background_brush( hWnd );
      if( !hBg ) hBg = ( HBRUSH ) GetSysColorBrush( COLOR_WINDOW );

      /* 1. Background */
      FillRect( hdc, &rc, hBg );

      nCount  = TabCtrl_GetItemCount( hWnd );
      hUpDown = FindWindowEx( hWnd, NULL, UPDOWN_CLASS, NULL );
      nSel    = TabCtrl_GetCurSel( hWnd );

      if( hwg_should_apps_use_dark_mode() )
      {
            /* --- DARK MODE: Draw tabs manually to enforce dark background,
             * soft white text, and correct borders. --- */
            hTabBg = hwg_get_dark_brush( 0 );
            hLine  = CreateSolidBrush( HWG_DARKTAB_LINE_RGB );

            for( i = 0; i < nCount; i++ )
            {
                  if( TabCtrl_GetItemRect( hWnd, i, &rcItem ) )
                  {
                        BOOL bSel     = ( i == nSel );
                        BOOL bPrevSel = ( i > 0 && ( i - 1 ) == nSel );

                        /* Draw background */
                        FillRect( hdc, &rcItem, hTabBg );

                        /* Draw top border */
                        SetRect( &rT, rcItem.left, rcItem.top, rcItem.right, rcItem.top + 1 );
                        FillRect( hdc, &rT, hLine );

                        /* Draw left border (skip if previous is selected to merge them) */
                        if( !bPrevSel || i == 0 )
                        {
                              SetRect( &rT, rcItem.left, rcItem.top, rcItem.left + 1, rcItem.bottom );
                              FillRect( hdc, &rT, hLine );
                        }

                        /* Draw right border */
                        SetRect( &rT, rcItem.right - 1, rcItem.top, rcItem.right, rcItem.bottom );
                        FillRect( hdc, &rT, hLine );

                        /* Draw bottom border (skip for selected tab so it merges with the body) */
                        if( !bSel )
                        {
                              SetRect( &rT, rcItem.left, rcItem.bottom - 1, rcItem.right, rcItem.bottom );
                              FillRect( hdc, &rT, hLine );
                        }

                        /* Draw text */
                        TCITEM tie;
                        TCHAR  szText[ 256 ];
                        ZeroMemory( &tie, sizeof( tie ) );
                        tie.mask = TCIF_TEXT;
                        tie.pszText = szText;
                        tie.cchTextMax = 256;

                        if( TabCtrl_GetItem( hWnd, i, &tie ) )
                        {
                              SetBkMode( hdc, TRANSPARENT );
                              SetTextColor( hdc, bSel ? RGB( 255, 255, 255 ) : RGB( 180, 180, 180 ) );
                              DrawText( hdc, szText, -1, &rcItem, DT_CENTER | DT_VCENTER | DT_SINGLELINE );
                        }
                  }
            }
            DeleteObject( hLine );
      }
      else
      {
            /* --- LIGHT MODE: Native drawing --- */
            nSavedDC = SaveDC( hdc );
            CallWindowProc( wpOrigTabProc, hWnd, WM_PRINTCLIENT,
                            ( WPARAM ) hdc, ( LPARAM ) PRF_CLIENT );
            RestoreDC( hdc, nSavedDC );
      }

      SetRect( &rcUpDown, 0, 0, 0, 0 );
      if( hUpDown )
      {
            GetWindowRect( hUpDown, &rcUpDown );
            MapWindowPoints( NULL, hWnd, ( LPPOINT ) &rcUpDown, 2 );
      }

      if( nCount > 0 && TabCtrl_GetItemRect( hWnd, 0, &rcItem ) )
            nHeaderBottom = rcItem.bottom;
      if( hUpDown && rcUpDown.bottom > nHeaderBottom )
            nHeaderBottom = rcUpDown.bottom;

      /* 3. Body (except tabs) */
      if( nCount > 0 )
      {
            hTabRgn = CreateRectRgn( rc.left, rc.top, rc.right, rc.bottom );
            for( i = 0; i < nCount; i++ )
            {
                  RECT rcT;
                  if( TabCtrl_GetItemRect( hWnd, i, &rcT ) )
                  {
                        InflateRect( &rcT, 1, 1 );
                        HRGN hR = CreateRectRgn( rcT.left, rcT.top,
                                                 rcT.right, rcT.bottom );
                        CombineRgn( hTabRgn, hTabRgn, hR, RGN_DIFF );
                        DeleteObject( hR );
                  }
            }
            FillRgn( hdc, hTabRgn, hBg );
            DeleteObject( hTabRgn );
      }
      else
      {
            RECT rcB = rc;
            if( hUpDown ) rcB.top = rcUpDown.bottom;
            FillRect( hdc, &rcB, hBg );
      }

      /* 4. Right column - always */
      if( hUpDown )
      {
            rcRight = rc;
            rcRight.left = rcUpDown.left;
            FillRect( hdc, &rcRight, hBg );
      }

      /* 5. Frame */
      if( nCount > 0 )
      {
            rcBody.left   = rc.left + 1;
            rcBody.top    = nHeaderBottom + 1; /* Starts below the tabs and arrows */
            rcBody.bottom = rc.bottom - 1;
            rcBody.right  = rc.right - 1;

            if( hwg_should_apps_use_dark_mode() )
            {
                  HBRUSH hBrLine = CreateSolidBrush( HWG_DARKTAB_LINE_RGB );
                  FrameRect( hdc, &rcBody, hBrLine );
                  DeleteObject( hBrLine );
            }
            else
            {
                  DrawEdge( hdc, &rcBody, EDGE_SUNKEN, BF_RECT );
            }
      }

      /* 6. Scroll arrows */
      if( hUpDown )
      {
            POINT ptOld;
            SetViewportOrgEx( hdc, rcUpDown.left, rcUpDown.top, &ptOld );
            SendMessage( hUpDown, WM_PRINTCLIENT, ( WPARAM ) hdc, PRF_CLIENT );
            SetViewportOrgEx( hdc, ptOld.x, ptOld.y, NULL );
      }

      hwg_tab_draw_disabled_captions( hWnd, hdc );
}

/*=============================================================================
 * hwg_ForceChildFrames()
 * Recursively forces all visible child windows to redraw their non-client
 * area (borders) immediately. This ensures GET borders are drawn on top of
 * GroupBoxes after a Tab change.
 *===========================================================================*/
static void hwg_ForceChildFrames( HWND hParent )
{
      HWND hChild = GetWindow( hParent, GW_CHILD );
      while( hChild )
      {
            if( IsWindowVisible( hChild ) )
            {
                  /* RDW_UPDATENOW forces immediate WM_NCPAINT.
                   * RDW_NOERASE prevents the background from being erased again. */
                  RedrawWindow( hChild, NULL, NULL, RDW_FRAME | RDW_INVALIDATE | RDW_UPDATENOW | RDW_NOERASE );
            }
            hwg_ForceChildFrames( hChild );
            hChild = GetWindow( hChild, GW_HWNDNEXT );
      }
}

/*=============================================================================
 * hwg_ForceEditBorders()
 * Recursively finds all Edit controls and forces their non-client frame
 * to be drawn immediately. This is required because when switching tabs,
 * the Tab and GroupBox paint over the Edit's border, making it invisible
 * until the mouse hovers over it.
 *===========================================================================*/
static void hwg_ForceEditBorders( HWND hParent )
{
      HWND hChild = GetWindow( hParent, GW_CHILD );
      while( hChild )
      {
            TCHAR szClass[ 32 ];
            GetClassName( hChild, szClass, HB_SIZEOFARRAY( szClass ) - 1 );

            /* If it's an Edit control, force the frame to redraw */
            if( lstrcmpi( szClass, TEXT( "Edit" ) ) == 0 )
            {
                  /* RDW_FRAME sends WM_NCPAINT. RDW_UPDATENOW makes it happen immediately. */
                  RedrawWindow( hChild, NULL, NULL, RDW_FRAME | RDW_INVALIDATE | RDW_UPDATENOW );
            }

            /* Recursively check children (for Edit controls inside GroupBoxes) */
            hwg_ForceEditBorders( hChild );

            hChild = GetWindow( hChild, GW_HWNDNEXT );
      }
}

/*=============================================================================
 * TabSubclassProc()
 *===========================================================================*/
LRESULT APIENTRY TabSubclassProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{
      long int res;
      PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

      if( message == WM_LBUTTONDOWN || message == WM_LBUTTONDBLCLK || message == WM_LBUTTONUP )
      {
            TCHITTESTINFO ht;
            int iTab;
            ht.pt.x = GET_X_LPARAM( lParam );
            ht.pt.y = GET_Y_LPARAM( lParam );
            ht.flags = 0;
            iTab = TabCtrl_HitTest( hWnd, &ht );

            if( iTab >= 0 && hwg_tab_is_disabled( hWnd, iTab + 1 ) ) return 0;
            if( iTab >= 0 )
            {
                  int iCur = TabCtrl_GetCurSel( hWnd );
                  if( iCur == iTab ) return 0;
                  /* Removido o RedrawWindow daqui, pois a aba ainda não mudou */
            }
      }

      /* Trata a borda não-cliente do TabControl para não ficar branca (DARK MODE ONLY) */
      if( message == WM_NCPAINT )
      {
            if( !hwg_should_apps_use_dark_mode() )
                  return CallWindowProc( wpOrigTabProc, hWnd, message, wParam, lParam );

            HDC hdc = GetWindowDC( hWnd );
            RECT rc;
            HBRUSH hBg = hwg_tab_background_brush( hWnd );
            GetWindowRect( hWnd, &rc );
            OffsetRect( &rc, -rc.left, -rc.top );
            if( hBg )
            {
                  FillRect( hdc, &rc, hBg );
            }
            ReleaseDC( hWnd, hdc );
            return 0;
      }

      if( message == WM_PAINT )
      {
            HWND        hUpDown = FindWindowEx( hWnd, NULL, UPDOWN_CLASS, NULL );
            PAINTSTRUCT ps;
            HDC         hdc;

            if( hUpDown && GetProp( hUpDown, TEXT( "HWGUI_OLD_UPDOWN_PROC" ) ) == NULL )
            {
                  WNDPROC pOld = ( WNDPROC ) SetWindowLongPtr( hUpDown, GWLP_WNDPROC, ( LONG_PTR ) TabUpDownSubclassProc );
                  SetProp( hUpDown, TEXT( "HWGUI_OLD_UPDOWN_PROC" ), ( HANDLE ) pOld );

                  if( hwg_should_apps_use_dark_mode() )
                        SetWindowTheme( hUpDown, L"DarkMode_Explorer", NULL );
                  else
                        SetWindowTheme( hUpDown, L"", L"" );
            }

            hdc = BeginPaint( hWnd, &ps );
            if( hdc )
            {
                  BOOL bOld = s_bTabPainting;
                  s_bTabPainting = TRUE;
                  hwg_tab_paint_to_dc( hWnd, hdc );
                  s_bTabPainting = bOld;
                  EndPaint( hWnd, &ps );

                  /* ADDED FIX: Force the borders of all Edit controls to be painted
                   * AFTER the Tab and GroupBox have finished painting. */
                  hwg_ForceEditBorders( hWnd );
            }
            return 0;
      }
      else if( message == WM_ERASEBKGND )
      {
            if( !hwg_should_apps_use_dark_mode() )
                  return CallWindowProc( wpOrigTabProc, hWnd, message, wParam, lParam );

            HBRUSH hBg = hwg_tab_background_brush( hWnd );
            RECT   rcClip;
            HDC    hdcErase = ( HDC ) wParam;

            if( hBg && hdcErase && GetClipBox( hdcErase, &rcClip ) != ERROR )
            {
                  FillRect( hdcErase, &rcClip, hBg );
                  return 1;
            }
      }
      else if( message == WM_PRINTCLIENT )
      {
            HDC hdcPrint = ( HDC ) wParam;

            if( hdcPrint && !s_bTabPainting && ( lParam & PRF_CLIENT ) )
            {
                  s_bTabPainting = TRUE;
                  hwg_tab_paint_to_dc( hWnd, hdcPrint );
                  s_bTabPainting = FALSE;
                  return 0;
            }
            else
            {
                  LRESULT lr = CallWindowProc( wpOrigTabProc, hWnd, message, wParam, lParam );
                  if( hdcPrint ) hwg_tab_draw_disabled_captions( hWnd, hdcPrint );
                  return lr;
            }
      }

      if( !pSym_onEvent ) pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

      if( pSym_onEvent && pObject )
      {
            hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
            hb_vmPush( pObject );
            hb_vmPushLong( ( LONG ) message );
            HB_PUSHITEM( wParam );
            HB_PUSHITEM( lParam );
            hb_vmSend( 3 );

            /* FIX: After HWGUI processes the tab change (TCN_SELCHANGE),
             * we force the Tab and its children to paint synchronously.
             * Then we force the borders of the GETs to be redrawn on top,
             * ensuring dark borders appear even inside GroupBoxes. */
            if( message == WM_NOTIFY )
            {
                  LPNMHDR pnmh = ( LPNMHDR ) lParam;
                  if( pnmh && pnmh->code == TCN_SELCHANGE )
                  {
                        UpdateWindow( hWnd );
                        hwg_ForceChildFrames( hWnd );
                  }
            }

            if( HB_ISPOINTER( -1 ) )
                  return (LRESULT) HB_PARHANDLE( -1 );
            else
            {
                  res = hb_parnl( -1 );
                  if( res == -1 )
                        return ( CallWindowProc( wpOrigTabProc, hWnd, message, wParam, lParam ) );
                  else
                        return res;
            }
      }
      else
            return ( CallWindowProc( wpOrigTabProc, hWnd, message, wParam, lParam ) );
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
      ULONG ulCount, ulID;
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

/*=============================================================================
 * Theme support (Windows XP+) — see hwingui.h / include/uxtheme.h
 *
 * IsThemeActive()  : a visual theme is present on the system.
 * IsAppThemed()    : *this process* is themed (manifest is active).
 *                    If this returns FALSE while IsThemeActive() is TRUE,
 *                    the executable is missing the comctl32 v6 manifest.
 * SetWindowTheme() : apply/remove a theme on a specific HWND.
 * EnableThemeDialogTexture() : give a dialog the same textured background
 *                    as its tab control (fixes the classic "flat gray
 *                    behind the tab" issue with ETDT_ENABLETAB).
 *===========================================================================*/

HB_FUNC( HWG_ISTHEMEACTIVE )
{
      hb_retl( IsThemeActive() );
}

HB_FUNC( HWG_ISAPPTHEMED )
{
      hb_retl( IsAppThemed() );
}

/*
 * hwg_SetWindowTheme( hWnd, cSubApp, cSubId )
 *
 *   hwg_SetWindowTheme( hWnd, "Explorer", Nil )  -> force Explorer look
 *   hwg_SetWindowTheme( hWnd, " ", " " )         -> remove theme
 *   hwg_SetWindowTheme( hWnd, Nil, Nil )         -> restore default
 *
 * Returns HRESULT (0 == S_OK).
 */
HB_FUNC( HWG_SETWINDOWTHEME )
{
      HWND     hWnd   = ( HWND ) HB_PARHANDLE( 1 );
      void    *hApp   = NULL, *hId = NULL;
      LPCTSTR  lpszApp = HB_PARSTR( 2, &hApp, NULL );
      LPCTSTR  lpszId  = HB_PARSTR( 3, &hId,  NULL );
      HRESULT  hr;

      hr = SetWindowTheme( hWnd, lpszApp, lpszId );

      hb_strfree( hApp );
      hb_strfree( hId );

      hb_retnl( ( LONG ) hr );
}

HB_FUNC( HWG_ENABLEDIALOGTHEME )
{
      HWND  hDlg   = ( HWND ) HB_PARHANDLE( 1 );
      DWORD dwFlag = ( DWORD ) hb_parnl( 2 );

      hb_retnl( ( LONG ) EnableThemeDialogTexture( hDlg, dwFlag ) );
}

HB_FUNC( HWG_ISTHEMEDIALOGTEXTUREENABLED )
{
      hb_retl( IsThemeDialogTextureEnabled( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_OPENWINDOWTHEME )
{
      void   *hCls    = NULL;
      LPCTSTR lpszCls = HB_PARSTR( 2, &hCls, NULL );
      HTHEME  h       = OpenThemeData( ( HWND ) HB_PARHANDLE( 1 ), lpszCls );

      hb_strfree( hCls );
      HB_RETHANDLE( h );
}

HB_FUNC( HWG_CLOSEWINDOWTHEME )
{
      CloseThemeData( ( HTHEME ) HB_PARHANDLE( 1 ) );
}

/*=============================================================================
 * Dark mode support (Windows 10 1809+)
 *
 * uxtheme.dll exports two undocumented but stable functions:
 *   - ShouldAppsUseDarkMode  (ordinal 132) - user preference
 *   - SetPreferredAppMode    (ordinal 135) - per-process mode
 * Both are loaded dynamically so the build keeps working on older
 * Windows versions (LoadLibrary returns NULL -> functions safely
 * fall back to light mode).
 *===========================================================================*/

#define HWG_ORD_SHOULDAPPSUSEDARKMODE   132
#define HWG_ORD_SETPREFERREDAPPMODE     135

/* Values accepted by SetPreferredAppMode */
#define HWG_APPMODE_DEFAULT     0
#define HWG_APPMODE_ALLOWDARK   1
#define HWG_APPMODE_FORCEDARK   2
#define HWG_APPMODE_FORCELIGHT  3

typedef BOOL ( WINAPI * HWG_PFN_SHOULDAPPSUSEDARKMODE )( void );
typedef int  ( WINAPI * HWG_PFN_SETPREFERREDAPPMODE )( int );

/* uxtheme ordinal 133 - enables per-window dark mode on Windows 10
 * 1809+.  Required before SetWindowTheme("DarkMode_Explorer") on
 * checkboxes, radio buttons and group boxes; without it those controls
 * keep the light palette even with the theme applied.  Windows 11
 * ignores the call, so it is safe to invoke on both. */
static HMODULE s_hUxTheme        = NULL;
static HWG_PFN_SHOULDAPPSUSEDARKMODE s_pfnShouldAppsUseDarkMode = NULL;
static HWG_PFN_SETPREFERREDAPPMODE   s_pfnSetPreferredAppMode   = NULL;

#define HWG_ORD_ALLOWDARKMODEFORWINDOW      133
typedef BOOL ( WINAPI * HWG_PFN_ALLOWDARKMODEFORWINDOW )( HWND, BOOL );
static HWG_PFN_ALLOWDARKMODEFORWINDOW s_pfnAllowDarkModeForWindow = NULL;

static void s_LoadDarkModeProcs( void )
{
      if( s_hUxTheme )
            return;

      s_hUxTheme = LoadLibrary( TEXT( "uxtheme.dll" ) );
      if( !s_hUxTheme )
            return;

      s_pfnShouldAppsUseDarkMode = ( HWG_PFN_SHOULDAPPSUSEDARKMODE )
      GetProcAddress( s_hUxTheme, MAKEINTRESOURCEA( HWG_ORD_SHOULDAPPSUSEDARKMODE ) );
      s_pfnSetPreferredAppMode   = ( HWG_PFN_SETPREFERREDAPPMODE )
      GetProcAddress( s_hUxTheme, MAKEINTRESOURCEA( HWG_ORD_SETPREFERREDAPPMODE ) );
      s_pfnAllowDarkModeForWindow = ( HWG_PFN_ALLOWDARKMODEFORWINDOW )
      GetProcAddress( s_hUxTheme, MAKEINTRESOURCEA( HWG_ORD_ALLOWDARKMODEFORWINDOW ) );
}

/* C-pure helpers - safe to call from other .c files in this module. */
/*=============================================================================
 * hwg_should_apps_use_dark_mode
 *
 * Returns TRUE when the user prefers dark mode for applications.
 *
 * Primary source:  HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\
 *                  Personalize\AppsUseLightTheme
 *                      0x1 -> apps in light mode
 *                      0x0 -> apps in dark mode
 *
 * Fallback:        uxtheme ShouldAppsUseDarkMode() (ordinal 132), used only
 *                  when the registry value is absent (rare - some Windows
 *                  Server SKUs).
 *
 * The value is read ONCE, on the first call, and cached for the whole
 * lifetime of the process.  This eliminates all registry access from the
 * paint path: every control on every paint simply reads s_bResult.
 *
 * Trade-off: if the user changes the theme while the application is
 * running, it will not be reflected until the application is restarted.
 *===========================================================================*/
BOOL hwg_should_apps_use_dark_mode( void )
{
      static int s_iInitialized = 0;   /* 0 = not read yet, 1 = cached */
      static BOOL s_bResult     = FALSE;

      /* Fast path: value already cached - return immediately. */
      if( s_iInitialized )
            return s_bResult;

      /* Slow path: first call only - read the registry. */
      {
            HKEY  hKey;
            DWORD dwValue = 0;
            DWORD dwSize  = sizeof( dwValue );
            DWORD dwType  = 0;
            BOOL  lFromRegistry = FALSE;

            if( RegOpenKeyEx( HKEY_CURRENT_USER,
                  TEXT("Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize"),
                              0, KEY_READ, &hKey ) == ERROR_SUCCESS )
            {
                  if( RegQueryValueEx( hKey, TEXT("AppsUseLightTheme"), NULL,
                        &dwType, ( LPBYTE ) &dwValue, &dwSize ) == ERROR_SUCCESS )
                  {
                        lFromRegistry = TRUE;
                  }
                  RegCloseKey( hKey );
            }

            if( !lFromRegistry )
            {
                  s_LoadDarkModeProcs();
                  s_bResult = s_pfnShouldAppsUseDarkMode
                  ? ( s_pfnShouldAppsUseDarkMode() ? TRUE : FALSE )
                  : FALSE;
            }
            else
                  s_bResult = ( dwValue == 0 ) ? TRUE : FALSE;

            s_iInitialized = 1;
      }

      return s_bResult;
}

int hwg_set_preferred_app_mode( int nMode )
{
      s_LoadDarkModeProcs();
      return s_pfnSetPreferredAppMode ? s_pfnSetPreferredAppMode( nMode ) : -1;
}

/*=============================================================================
 * HWG_SHOULDAPPSUSEDARKMODE()
 * PRG-visible wrapper around hwg_should_apps_use_dark_mode().
 * The C helper reads the registry (AppsUseLightTheme) instead of the
 * uxtheme API, which is unreliable on some Windows 10/11 builds.
 *===========================================================================*/
HB_FUNC( HWG_SHOULDAPPSUSEDARKMODE )
{
      hb_retl( hwg_should_apps_use_dark_mode() );
}

/*=============================================================================
 * HWG_SETPREFERREDAPPMODE( nMode )
 * Tells Windows how this process wants to be themed.
 *   0 = default, 1 = allow dark, 2 = force dark, 3 = force light
 * Must be called BEFORE any window is created to have full effect.
 * Returns the previous mode, or -1 on failure.
 *===========================================================================*/
HB_FUNC( HWG_SETPREFERREDAPPMODE )
{
      int nMode = hb_parni( 1 );
      s_LoadDarkModeProcs();
      if( s_pfnSetPreferredAppMode )
            hb_retni( s_pfnSetPreferredAppMode( nMode ) );
      else
            hb_retni( -1 );
}

/*=============================================================================
 * HWG_SETDARKTITLEBAR( hWnd, lDark )
 *   Applies or removes the immersive dark title bar via DWM.
 *   Requires Windows 10 1809+ (build 17763).  Safe no-op on older.
 *===========================================================================*/
HB_FUNC( HWG_SETDARKTITLEBAR )
{
      HWND  hWnd  = ( HWND ) HB_PARHANDLE( 1 );
      BOOL  lDark = hb_parl( 2 );
      BOOL  bResult = FALSE;
      HMODULE hDwm;
      typedef HRESULT ( WINAPI * HWG_PFN_DWMSETWINDOWATTRIBUTE )( HWND, DWORD, LPCVOID, DWORD );
      HWG_PFN_DWMSETWINDOWATTRIBUTE pfn = NULL;
      DWORD dwAttr;
      BOOL  bValue = lDark;

      hDwm = LoadLibrary( TEXT( "dwmapi.dll" ) );
      if( !hDwm )
      {
            hb_retl( FALSE );
            return;
      }

      pfn = ( HWG_PFN_DWMSETWINDOWATTRIBUTE )
      GetProcAddress( hDwm, "DwmSetWindowAttribute" );
      if( !pfn )
      {
            FreeLibrary( hDwm );
            hb_retl( FALSE );
            return;
      }

      /* Attribute ID changed from 19 to 20 in Windows 10 20H1.
       * Try 20 first, fall back to 19 if it fails. */
      dwAttr = 20;
      if( FAILED( pfn( hWnd, dwAttr, &bValue, sizeof( bValue ) ) ) )
      {
            dwAttr = 19;
            if( SUCCEEDED( pfn( hWnd, dwAttr, &bValue, sizeof( bValue ) ) ) )
                  bResult = TRUE;
      }
      else
            bResult = TRUE;

      FreeLibrary( hDwm );

      hb_retl( bResult );
}


#ifndef DT_HIDEPREFIX
#define DT_HIDEPREFIX  0x00100000
#endif

#define HWG_DARKGROUP_PROP         TEXT( "HWGUI_OLD_DARKGROUP_PROC" )
#define HWG_DARKGROUP_FRAME_RGB    RGB(  85,  85,  85 )   /* frame line       */
#define HWG_DARKGROUP_TEXT_RGB     RGB( 235, 235, 235 )   /* caption          */
#define HWG_DARKGROUP_TEXTOFF_RGB  RGB( 130, 130, 130 )   /* caption disabled */

/*=============================================================================
 * hwg_DarkGroupProc()
 *
 * Window procedure used for group boxes in dark mode.  Without a visual
 * theme the classic group box frame is an etched edge (white highlight +
 * grey shadow), which is far too bright on a dark window.  Here the frame
 * is drawn as a single 1px line in a muted grey and the caption in the dark
 * palette.  Only the frame and the caption are painted; the inside of the
 * group box stays untouched, so controls placed over it are not affected.
 *
 * The original procedure is kept in a window property (same approach as
 * HWG_INITSTATICPROC), so this can be installed on any number of group
 * boxes.
 *===========================================================================*/
static LRESULT CALLBACK hwg_DarkGroupProc( HWND hWnd, UINT message,
                                           WPARAM wParam, LPARAM lParam )
{
      WNDPROC pOld = ( WNDPROC ) GetProp( hWnd, HWG_DARKGROUP_PROP );

      if( pOld == NULL )
            return DefWindowProc( hWnd, message, wParam, lParam );

      /* Handle background erasing to prevent grey artifacts/stripes */
      if( message == WM_ERASEBKGND )
      {
            HDC hdc = ( HDC ) wParam;
            RECT rc;
            GetClientRect( hWnd, &rc );
            FillRect( hdc, &rc, hwg_GetEffectiveBrush( hWnd ) );
            return 1;
      }

      if( message == WM_PAINT )
      {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint( hWnd, &ps );

            if( hdc )
            {
                  RECT   rc, rcText;
                  TCHAR  szText[ 256 ];
                  SIZE   szH;
                  int    nLen, nCapW = 0, nTop;
                  HFONT  hFont, hOldFont = NULL;
                  HPEN   hPen, hOldPen;
                  HBRUSH hOldBr, hBg;
                  BOOL   bDark = hwg_should_apps_use_dark_mode();

                  /* Dynamic colors for Light or Dark Mode */
                  COLORREF crFrame   = bDark ? HWG_DARKGROUP_FRAME_RGB : GetSysColor( COLOR_3DSHADOW );
                  COLORREF crText    = bDark ? HWG_DARKGROUP_TEXT_RGB  : GetSysColor( COLOR_BTNTEXT );
                  COLORREF crTextOff = bDark ? HWG_DARKGROUP_TEXTOFF_RGB : GetSysColor( COLOR_GRAYTEXT );

                  GetClientRect( hWnd, &rc );

                  hFont = ( HFONT ) SendMessage( hWnd, WM_GETFONT, 0, 0 );
                  if( hFont )
                        hOldFont = ( HFONT ) SelectObject( hdc, hFont );

                  nLen = GetWindowText( hWnd, szText, HB_SIZEOFARRAY( szText ) );
                  GetTextExtentPoint32( hdc, TEXT( "Ag" ), 2, &szH );

                  if( nLen > 0 )
                  {
                        SetRect( &rcText, 0, 0, 0, 0 );
                        DrawText( hdc, szText, nLen, &rcText,
                                  DT_SINGLELINE | DT_LEFT | DT_TOP | DT_CALCRECT );
                        nCapW = rcText.right - rcText.left;
                  }

                  /* Frame: the top line runs through the middle of the caption. */
                  nTop = szH.cy / 2;
                  hPen    = CreatePen( PS_SOLID, 1, crFrame );
                  hOldPen = ( HPEN ) SelectObject( hdc, hPen );
                  hOldBr  = ( HBRUSH ) SelectObject( hdc, GetStockObject( NULL_BRUSH ) );

                  Rectangle( hdc, rc.left, rc.top + nTop, rc.right, rc.bottom );

                  SelectObject( hdc, hOldBr );
                  SelectObject( hdc, hOldPen );
                  DeleteObject( hPen );

                  /* Caption: cut a gap in the line and write the text. */
                  if( nLen > 0 )
                  {
                        hBg = hwg_GetEffectiveBrush( hWnd );
                        SetRect( &rcText, 8, 0, 8 + nCapW + 4, szH.cy );
                        FillRect( hdc, &rcText, hBg ); /* Use effective brush to blend with Tab */
                        rcText.left += 2;
                        SetBkMode( hdc, TRANSPARENT );
                        SetTextColor( hdc, IsWindowEnabled( hWnd ) ? crText : crTextOff );
                        DrawText( hdc, szText, nLen, &rcText,
                                  DT_SINGLELINE | DT_LEFT | DT_TOP | DT_HIDEPREFIX );
                  }

                  if( hOldFont )
                        SelectObject( hdc, hOldFont );

                  EndPaint( hWnd, &ps );
            }
            return 0;
      }

      if( message == WM_NCDESTROY )
      {
            SetWindowLongPtr( hWnd, GWLP_WNDPROC, ( LONG_PTR ) pOld );
            RemoveProp( hWnd, HWG_DARKGROUP_PROP );
      }

      return CallWindowProc( pOld, hWnd, message, wParam, lParam );
}

/*=============================================================================
 * HWG_DARKENCONTROL( hWnd )
 *   Applies dark rendering to a single control.
 *
 *   - Push buttons: untouched (HWGUI paints them with its own palette).
 *
 *   - Check boxes, radio buttons and group boxes, in dark mode: the visual
 *     theme is REMOVED from the control (SetWindowTheme with empty strings).
 *     A themed BUTTON draws its text with the theme colour and ignores the
 *     SetTextColor() done in WM_CTLCOLORSTATIC / WM_CTLCOLORBTN, and it
 *     erases its background through the parent (a tab control paints it
 *     light).  Without the theme the control is drawn by classic GDI, which
 *     does honour the text colour and the background brush returned by
 *     onCtlColor() (hcwindow.prg), so these controls get light text on a
 *     dark background.  Group boxes additionally get hwg_DarkGroupProc() to
 *     replace the bright etched frame by a soft grey line.
 *
 *   - Everything else: "DarkMode_Explorer", as before.
 *===========================================================================*/
HB_FUNC( HWG_DARKENCONTROL )
{
      HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
      TCHAR szClass[ 64 ];
      BOOL bDark = hwg_should_apps_use_dark_mode();

      if( !hWnd )
            return;

      szClass[ 0 ] = 0;
      GetClassName( hWnd, szClass, HB_SIZEOFARRAY( szClass ) - 1 );

      if( lstrcmpi( szClass, TEXT( "Button" ) ) == 0 )
      {
            LONG lStyle = GetWindowLong( hWnd, GWL_STYLE ) & 0x0F;

            /* Push buttons: HWGUI paints them with its own soft palette. */
            if( lStyle == BS_PUSHBUTTON || lStyle == BS_DEFPUSHBUTTON )
                  return;

            /* GroupBoxes: always subclass them to override the grey background
             * and prevent stripes in both Light and Dark modes. */
            if( lStyle == BS_GROUPBOX )
            {
                  if( GetProp( hWnd, HWG_DARKGROUP_PROP ) == NULL )
                  {
                        WNDPROC pOld = ( WNDPROC ) SetWindowLongPtr( hWnd, GWLP_WNDPROC,
                                                                     ( LONG_PTR ) hwg_DarkGroupProc );
                        SetProp( hWnd, HWG_DARKGROUP_PROP, ( HANDLE ) pOld );
                  }
                  InvalidateRect( hWnd, NULL, TRUE );
                  return;
            }

            /* Check boxes and radio buttons: apply native drawing only in Dark Mode */
            if( bDark && (
                  lStyle == BS_CHECKBOX      || lStyle == BS_AUTOCHECKBOX  ||
                  lStyle == BS_3STATE        || lStyle == BS_AUTO3STATE    ||
                  lStyle == BS_RADIOBUTTON   || lStyle == BS_AUTORADIOBUTTON ) )
            {
                  SetWindowTheme( hWnd, L"", L"" );
                  InvalidateRect( hWnd, NULL, TRUE );
                  return;
            }
      }

      /* For other controls, apply the DarkMode theme only if bDark is true */
      if( bDark )
      {
            s_LoadDarkModeProcs();
            if( s_pfnAllowDarkModeForWindow )
                  s_pfnAllowDarkModeForWindow( hWnd, TRUE );

            SetWindowTheme( hWnd, L"DarkMode_Explorer", NULL );
      }
}

/*=============================================================================
 * HWG_DARKENCOMBOBOX( hCombo )
 *
 * A Win32 ComboBox is a composite control:
 *   - The main HWND   : the visible box (edit + dropdown button).
 *   - hwndItem        : internal edit or static (child).
 *   - hwndList        : the dropdown list (ComboLBox, top-level popup
 *                       owned by the combo, NOT a child).
 *
 * SetWindowTheme() on the main HWND does not reach the dropdown, and
 * FindWindowEx() does not find it either (the dropdown is not a child
 * in the WS_CHILD sense).  The correct way to get its HWND is
 * GetComboBoxInfo(), which returns hwndList for exactly this purpose.
 *
 * Theme name: ComboBox uses "DarkMode_CFD" (Common File Dialog), not
 * "DarkMode_Explorer" (which is for TreeView / ListView / Edit).
 *===========================================================================*/
HB_FUNC( HWG_DARKENCOMBOBOX )
{
      HWND hCombo = ( HWND ) HB_PARHANDLE( 1 );
      COMBOBOXINFO cbi;

      if( !hCombo )
            return;

      /* Main combo HWND - ComboBox-specific dark theme. */
      SetWindowTheme( hCombo, L"DarkMode_CFD", NULL );

      /* Ask Windows for the internal HWNDs (edit box and dropdown list). */
      memset( &cbi, 0, sizeof( cbi ) );
      cbi.cbSize = sizeof( cbi );

      if( GetComboBoxInfo( hCombo, &cbi ) )
      {
            if( cbi.hwndItem )
                  SetWindowTheme( cbi.hwndItem, L"DarkMode_CFD", NULL );

            if( cbi.hwndList )
                  SetWindowTheme( cbi.hwndList, L"DarkMode_CFD", NULL );
      }
}

/*=============================================================================
 * HWG_DARKTHEMECOLOR( nColorIndex )
 *
 * Returns the RGB value for one of the standard dark-theme colors used
 * by the Windows 10+ dark mode palette.
 *
 *   0 = background  (dialog / window background)
 *   1 = foreground  (text on top of the background)
 *   2 = edit bg     (edit control background)
 *   3 = edit fg     (edit control text)
 *
 * The exact values match the ones used by the Windows 10 20H1+ shell,
 * so custom-painted dialogs visually match system dialogs.
 *===========================================================================*/
HB_FUNC( HWG_DARKTHEMECOLOR )
{
      int nIdx = hb_parni( 1 );
      COLORREF cr;

      switch( nIdx )
      {
            case 0:  cr = RGB(  32,  32,  32 ); break;   /* dialog background */
            case 1:  cr = RGB( 235, 235, 235 ); break;   /* text on dark bg   */
            case 2:  cr = RGB(  45,  45,  48 ); break;   /* edit background   */
            case 3:  cr = RGB( 235, 235, 235 ); break;   /* edit text         */
            default: cr = RGB(  32,  32,  32 );
      }
      /* HWGUI stores colors internally as 0x00BBGGRR (BGR order). */
      hb_retni( ( int ) ( ( ( cr & 0x000000FF ) << 16 ) |
      ( cr & 0x0000FF00 )        |
      ( ( cr & 0x00FF0000 ) >> 16 ) ) );
}

/*=============================================================================
 * Dark-theme brushes
 *
 * Windows expects WM_CTLCOLORDLG / WM_CTLCOLORSTATIC / WM_CTLCOLOREDIT to
 * return an HBRUSH that will be used to paint the control's background.
 * These brushes are created lazily and cached for the process lifetime;
 * they are never freed explicitly (the OS reclaims them on exit).
 *===========================================================================*/

static HBRUSH s_hDarkBrushDlg  = NULL;
static HBRUSH s_hDarkBrushEdit = NULL;

HBRUSH hwg_get_dark_brush( int nKind )
{
      /* nKind: 2 = edit control, anything else = dialog / static */
      if( nKind == 2 )
      {
            if( !s_hDarkBrushEdit )
                  s_hDarkBrushEdit = CreateSolidBrush( RGB( 45, 45, 48 ) );
            return s_hDarkBrushEdit;
      }
      if( !s_hDarkBrushDlg )
            s_hDarkBrushDlg = CreateSolidBrush( RGB( 32, 32, 32 ) );
      return s_hDarkBrushDlg;
}

/*=============================================================================
 * HWG_GETDARKBRUSH( nKind )
 *   0 = dialog / static background brush
 *   2 = edit control background brush
 * Returns a valid HBRUSH (never NULL).
 *===========================================================================*/
HB_FUNC( HWG_GETDARKBRUSH )
{
      HB_RETHANDLE( hwg_get_dark_brush( hb_parni( 1 ) ) );
}

/*=============================================================================
 * HWG_GETSTOCKBRUSH( nIndex )
 *   Returns a stock brush (see GetStockObject for the index values).
 *   Common indices:
 *     0 = WHITE_BRUSH
 *     1 = LTGRAY_BRUSH
 *     2 = GRAY_BRUSH
 *     3 = DKGRAY_BRUSH
 *     4 = BLACK_BRUSH
 *     5 = NULL_BRUSH  (a.k.a. HOLLOW_BRUSH)
 *===========================================================================*/
HB_FUNC( HWG_GETSTOCKBRUSH )
{
      HB_RETHANDLE( GetStockObject( hb_parni( 1 ) ) );
}

/* ====================== EOF of control.c ======================= */
