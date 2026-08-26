/*
 * $Id$
 * GTHWGUI, Video subsystem, based on HwGUI ( Winapi version )
 *
 * Copyright 2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * based on
 * Video subsystem for Windows using GDI windows instead of Console
 *     Copyright 2003 Peter Rees <peter@rees.co.nz>
 *                    Rees Software & Systems Ltd
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
 * along with this program; see the file LICENSE.txt.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA (or visit https://www.gnu.org/licenses/).
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
 * This exception does not however invalidate any other reasons why the
 * executable file might be covered by the GNU General Public License.
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

#include "hbsetup.h"

#include "windows.h"

#define HWG_DEFAULT_FONT_NAME  TEXT( "Courier New" )

#define HB_GT_NAME            HWGUI

#include "hbset.h"
#include "hbgtcore.h"
#include "hbinit.h"
#include "hbapicdp.h"
#include "hbapierr.h"
#include "hbapiitm.h"
#include "inkey.ch"
#include "error.ch"
#include "hbvm.h"
#include "hbthread.h"
#include "hbgfxdef.ch"
#include "hbwinuni.h"
/*
 # include "hbgtcore.h*"
 #include "hbinit.h"
 #include "hbapiitm.h"
 #include "hbvm.h"
 #include "hbwinuni.h"
 */
#include "gt_hwg.ch"

#define HWG_DEFAULT_ROWS         25
#define HWG_DEFAULT_COLS         80
#define HWG_DEFAULT_FONT_HEIGHT  20
#define HWG_DEFAULT_FONT_WIDTH   10
#define HWG_DEFAULT_FONT_ATTR     0

#define WM_MY_UPDATE_CARET  ( WM_USER + 0x0101 )
#define MSG_USER_SIZE  0x502

#define HWG_EXTKEY_FLAG              ( 1 << 24 )

#define BLACK            RGB( 0x00, 0x00, 0x00 )
#define BLUE             RGB( 0x00, 0x00, 0xAA )
#define GREEN            RGB( 0x00, 0xAA, 0x00 )
#define CYAN             RGB( 0x00, 0xAA, 0xAA )
#define RED              RGB( 0xAA, 0x00, 0x00 )
#define MAGENTA          RGB( 0xAA, 0x00, 0xAA )
#define BROWN            RGB( 0xAA, 0x55, 0x00 )
#define LIGHT_GRAY       RGB( 0xAA, 0xAA, 0xAA )
#define GRAY             RGB( 0x55, 0x55, 0x55 )
#define BRIGHT_BLUE      RGB( 0x55, 0x55, 0xFF )
#define BRIGHT_GREEN     RGB( 0x55, 0xFF, 0x55 )
#define BRIGHT_CYAN      RGB( 0x55, 0xFF, 0xFF )
#define BRIGHT_RED       RGB( 0xFF, 0x55, 0x55 )
#define BRIGHT_MAGENTA   RGB( 0xFF, 0x55, 0xFF )
#define YELLOW           RGB( 0xFF, 0xFF, 0x55 )
#define WHITE            RGB( 0xFF, 0xFF, 0xFF )

#define HB_KF_ALTGR          0x10

#ifndef WS_EX_COMPOSITED
#define WS_EX_COMPOSITED  0x02000000
#endif

#define AKEYS_LEN            128

#define VK__TILDA     192

typedef struct
{
      PHB_GT   pGT;            /* core GT pointer */
      HWND     hWnd;

      int      fontHeight;     /* requested font height */
      int      fontWidth;      /* requested font width */
      int      fontWeight;     /* Bold level */
      int      fontQuality;    /* requested font quality */
      int      fontAttribute;  /* font attribute: HB_GTI_FONTA_* */
      TCHAR    fontFace[ 48 ]; /* requested font face name LF_FACESIZE #defined in wingdi.h */
      HFONT    hFont;

      POINT    PTEXTSIZE;      /* size of the fixed width font */
      HB_BOOL  FixedFont;      /* HB_TRUE if current font is a fixed font */
      int *    FixedSize;      /* buffer for ExtTextOut() to emulate fixed pitch when Proportional font selected */
      int      MarginTop;
      int      MarginLeft;

      int      Keys[ 128 ];    /* Array to hold the characters & events */
      int      keyPointerIn;   /* Offset into key array for character to be placed */
      int      keyPointerOut;  /* Offset into key array of next character to read */
      int      keyLastPos;     /* last inkey code position in buffer */
      int      keyFlags;       /* keyboard modifiers */

      int      ROWS;           /* number of displayable rows in window */
      int      COLS;           /* number of displayable columns in window */
      TCHAR *  TextLine;
      COLORREF COLORS[ 16 ];   /* colors */

      HB_BOOL  CaretExist;     /* HB_TRUE if a caret has been created */
      HB_BOOL  CaretHidden;    /* HB_TRUE if a caret has been hiden */
      int      CaretSize;      /* Height of solid caret */
      int      CaretWidth;     /* Width of solid caret */

      POINT    MousePos;       /* the last mouse position */
      POINT    ExactMousePos;  /* the last mouse position in pixels*/

      int      CodePage;       /* Code page to use for display characters */

      int      CloseMode;
      HB_BOOL  IgnoreWM_SYSCHAR;

      void *   hWindowTitle;

      TCHAR szTitle[256];

} HB_GTHWG, * PHB_GTHWG;

extern void hwg_writelog( const char * sFile, const char * sTraceMsg, ... );

static PHB_GTHWG pHWGMain = NULL;
static HWND hWndMain = NULL;
static HWND hPaneMain = NULL;
static HFONT hFontMain = NULL;
static WNDPROC wpOrigWndProc;

static int iNewPosX = -1, iNewPosY = -1;
static int iNewWidth = -1, iNewHeight = -1;

static int s_GtId;
static HB_GT_FUNCS SuperTable;

static PHB_DYNS s_pSymTest_paint = NULL;

#define HB_GTSUPER   ( &SuperTable )
#define HB_GTID_PTR  ( &s_GtId )

extern void hwg_doEvents( void );

static void gthwg_SetWindowPos( HWND hWnd, int left, int top, int width, int height, unsigned int uiFlags )
{
      if( hPaneMain )
      {
            iNewWidth = width;
            iNewHeight = height;
            SendMessage( hWndMain, MSG_USER_SIZE, width, height );
      }
      else
            SetWindowPos( hWnd, NULL, left, top, width, height, uiFlags );
}

static void gthwg_GetWindowRect( HWND hWnd, LPRECT lpRect )
{
      GetWindowRect( hWnd, lpRect );
}

static void gthwg_GetClientRect( HWND hWnd, LPRECT lpRect )
{
      GetClientRect( hWnd, lpRect );
}

static int gthwg_GetDesktopWidth( void )
{
      return GetSystemMetrics( SM_CXSCREEN );
}

static int gthwg_GetDesktopHeight( void )
{
      return GetSystemMetrics( SM_CYSCREEN );
}

static void gthwg_InvalidateRect( HWND hWnd, LPRECT lpRect, int b )
{
      InvalidateRect( hWnd, lpRect, b );
}

static HFONT gthwg_GetFont( LPCTSTR lpFace, int iHeight, int iWidth, int iWeight, int iQuality, int iCodePage )
{
      static PHB_DYNS s_pSymTest = NULL;

      if( s_pSymTest == NULL )
            s_pSymTest = hb_dynsymGetCase( "GTHWG_ADDFONT" );

      if( hb_dynsymIsFunction( s_pSymTest ) )
      {
            PHB_ITEM pItem;

            //pItem = hb_itemPutC( NULL, (const char *) lpFace );
            pItem = HB_ITEMPUTSTR( NULL, lpFace );

            hb_vmPushDynSym( s_pSymTest );
            hb_vmPushNil();   /* places NIL at self */
            hb_vmPush( pItem );
            hb_vmPushLong( ( LONG ) iHeight );
            hb_vmPushLong( ( LONG ) iWidth );
            hb_vmPushLong( ( LONG ) iWeight );
            hb_vmPushLong( ( LONG ) iQuality );
            hb_vmPushLong( ( LONG ) iCodePage );
            hb_vmDo( 6 );     /* the number of pushed parameters */
            //hwg_writelog( NULL, "_getfont-10 \r\n" );
            return (HFONT) hb_parptr( -1 );
      }
      return NULL;
}

static int gthwg_PaintCB( HDC hdc )
{
      if( hb_dynsymIsFunction( s_pSymTest_paint ) )
      {
            hb_vmPushDynSym( s_pSymTest_paint );
            hb_vmPushNil();   /* places NIL at self */
            hb_vmPushPointer( ( void * ) hdc );
            hb_vmDo( 1 );
            return hb_parni( -1 );
      }
      return -1;
}

HB_FUNC( GTHWG_PAINT_SETCALLBACK )
{
      if( hb_pcount() > 0 && HB_ISCHAR(1) )
      {
            s_pSymTest_paint = hb_dynsymGetCase( hb_parc(1) );
      }
      else
      {
            s_pSymTest_paint = NULL;
      }
}

#if ! defined( UNICODE )
static int gthwg_key_ansi_to_oem( int c )
{
      BYTE pszSrc[ 2 ];
      wchar_t pszWide[ 1 ];
      BYTE pszDst[ 2 ];

      pszSrc[ 0 ] = ( CHAR ) c;
      pszSrc[ 1 ] =
      pszDst[ 0 ] =
      pszDst[ 1 ] = 0;

      if( MultiByteToWideChar( CP_ACP, MB_PRECOMPOSED, ( LPCSTR ) pszSrc, 1, ( LPWSTR ) pszWide, 1 ) &&
            WideCharToMultiByte( CP_OEMCP, 0, ( LPCWSTR ) pszWide, 1, ( LPSTR ) pszDst, 1, NULL, NULL ) )
            return pszDst[ 0 ];
      else
            return c;
}
#endif

static POINT gthwg_GetXYFromColRow( PHB_GTHWG pHWG, int col, int row )
{
      POINT xy;

      xy.x = col * pHWG->PTEXTSIZE.x + pHWG->MarginLeft;
      xy.y = row * pHWG->PTEXTSIZE.y + pHWG->MarginTop;

      return xy;
}

static RECT gthwg_GetXYFromColRowRect( PHB_GTHWG pHWG, RECT colrow )
{
      RECT xy;

      xy.left   = colrow.left * pHWG->PTEXTSIZE.x + pHWG->MarginLeft;
      xy.top    = colrow.top  * pHWG->PTEXTSIZE.y + pHWG->MarginTop;
      xy.right  = ( colrow.right  + 1 ) * pHWG->PTEXTSIZE.x + pHWG->MarginLeft;
      xy.bottom = ( colrow.bottom + 1 ) * pHWG->PTEXTSIZE.y + pHWG->MarginTop;

      return xy;
}

/*
 * get the row and column from xy pixel client coordinates
 * This works because we are using the FIXED system font
 */
static POINT gthwg_GetColRowFromXY( PHB_GTHWG pHWG, LONG x, LONG y )
{
      POINT colrow;

      colrow.x = ( x - pHWG->MarginLeft ) / pHWG->PTEXTSIZE.x;
      colrow.y = ( y - pHWG->MarginTop ) / pHWG->PTEXTSIZE.y;

      return colrow;
}

static RECT gthwg_GetColRowFromXYRect( PHB_GTHWG pHWG, RECT xy )
{
      RECT colrow;

      colrow.left   = xy.left   / pHWG->PTEXTSIZE.x;
      colrow.top    = xy.top    / pHWG->PTEXTSIZE.y;
      colrow.right  = xy.right  / pHWG->PTEXTSIZE.x -
      ( ( xy.right  % pHWG->PTEXTSIZE.x ) ? 0 : 1 ); /* Adjust for when rectangle */
      colrow.bottom = xy.bottom / pHWG->PTEXTSIZE.y -
      ( ( xy.bottom % pHWG->PTEXTSIZE.y ) ? 0 : 1 ); /* EXACTLY overlaps characters */

      return colrow;
}

static HB_BOOL gthwg_SetMousePos( PHB_GTHWG pHWG, int iRow, int iCol )
{
      if( pHWG->MousePos.y != iRow || pHWG->MousePos.x != iCol )
      {
            pHWG->MousePos.y = iRow;
            pHWG->MousePos.x = iCol;
            return HB_TRUE;
      }
      else
            return HB_FALSE;
}

static int gthwg_GetKeyFlags( void )
{
      int iFlags = 0;
      if( GetKeyState( VK_SHIFT ) & 0x8000 )
            iFlags |= HB_KF_SHIFT;
      if( GetKeyState( VK_CONTROL ) & 0x8000 )
            iFlags |= HB_KF_CTRL;
      if( GetKeyState( VK_LMENU ) & 0x8000 )
            iFlags |= HB_KF_ALT;
      if( GetKeyState( VK_RMENU ) & 0x8000 )
            iFlags |= HB_KF_ALTGR;

      return iFlags;
}

static int gthwg_UpdateKeyFlags( int iFlags )
{
      if( iFlags & HB_KF_ALTGR )
      {
            iFlags |= HB_KF_ALT;
            iFlags &= ~HB_KF_ALTGR;
      }

      return iFlags;
}

static void gthwg_AddCharToInputQueue( PHB_GTHWG pHWG, int iKey )
{
      int iPos = pHWG->keyPointerIn;

      if( pHWG->keyPointerIn != pHWG->keyPointerOut &&
            HB_INKEY_ISMOUSEPOS( iKey ) )
      {
            int iLastKey = pHWG->Keys[ pHWG->keyLastPos ];
            if( HB_INKEY_ISMOUSEPOS( iLastKey ) )
            {
                  pHWG->Keys[ pHWG->keyLastPos ] = iKey;
                  return;
            }
      }

      /*
       * When the buffer is full new event overwrite the last one
       * in the buffer - it's Clipper behavior, [druzus]
       */
      pHWG->Keys[ pHWG->keyLastPos = iPos ] = iKey;
      if( ++iPos >= AKEYS_LEN )
            iPos = 0;
      if( iPos != pHWG->keyPointerOut )
            pHWG->keyPointerIn = iPos;
}

static HB_BOOL gthwg_GetCharFromInputQueue( PHB_GTHWG pHWG, int * iKey )
{
      if( pHWG->keyPointerOut != pHWG->keyPointerIn )
      {
            *iKey = pHWG->Keys[ pHWG->keyPointerOut ];
            if( ++pHWG->keyPointerOut >= AKEYS_LEN )
                  pHWG->keyPointerOut = 0;

            return HB_TRUE;
      }

      *iKey = 0;
      return HB_FALSE;
}

static void gthwg_SetCloseButton( PHB_GTHWG pHWG )
{
      HMENU hSysMenu = GetSystemMenu( pHWG->hWnd, FALSE );

      if( hSysMenu )
            EnableMenuItem( hSysMenu, SC_CLOSE, MF_BYCOMMAND |
            ( pHWG->CloseMode < 2 ? MF_ENABLED : MF_GRAYED ) );
}

static void gthwg_MouseEvent( PHB_GTHWG pHWG, UINT message, WPARAM wParam, LPARAM lParam )
{
      SHORT keyCode = 0;
      POINT xy, colrow;

      xy.x = LOWORD( lParam );
      xy.y = HIWORD( lParam );

      if( message == WM_MOUSEWHEEL )
            ScreenToClient( pHWG->hWnd, &xy );

      pHWG->ExactMousePos.y = xy.y;
      pHWG->ExactMousePos.x = xy.x;

      colrow = gthwg_GetColRowFromXY( pHWG, xy.x, xy.y );
      if( gthwg_SetMousePos( pHWG, colrow.y, colrow.x ) )
      {
            gthwg_AddCharToInputQueue( pHWG,
                                       HB_INKEY_NEW_MPOS( pHWG->MousePos.x, pHWG->MousePos.y ) );
      }

      switch( message )
      {
            case WM_LBUTTONDBLCLK:
                  keyCode = K_LDBLCLK;
                  break;

            case WM_RBUTTONDBLCLK:
                  keyCode = K_RDBLCLK;
                  break;

            case WM_LBUTTONDOWN:
                  keyCode = K_LBUTTONDOWN;
                  break;

            case WM_RBUTTONDOWN:
                  keyCode = K_RBUTTONDOWN;
                  break;

            case WM_RBUTTONUP:
                  keyCode = K_RBUTTONUP;
                  break;

            case WM_LBUTTONUP:
                  keyCode = K_LBUTTONUP;
                  break;

            case WM_MBUTTONDOWN:
                  keyCode = K_MBUTTONDOWN;
                  break;

            case WM_MBUTTONUP:
                  keyCode = K_MBUTTONUP;
                  break;

            case WM_MBUTTONDBLCLK:
                  keyCode = K_MDBLCLK;
                  break;

            case WM_MOUSEMOVE:
                  break;

            case WM_MOUSEWHEEL:
                  keyCode = ( SHORT ) HIWORD( wParam ) > 0 ? K_MWFORWARD : K_MWBACKWARD;
                  break;
      }

      if( keyCode != 0 )
            gthwg_AddCharToInputQueue( pHWG,
                                       HB_INKEY_NEW_MKEY( keyCode,
                                                          gthwg_UpdateKeyFlags( gthwg_GetKeyFlags() ) ) );
}

static HB_BOOL gthwg_KeyEvent( PHB_GTHWG pHWG, UINT message, WPARAM wParam, LPARAM lParam )
{
      int iKey = 0, iFlags = pHWG->keyFlags, iKeyPad = 0;

      //hwg_writelog( NULL, "msg %d %lu %lu %d\r\n", message, (unsigned long) wParam, (unsigned long) lParam, gthwg_GetKeyFlags() );
      switch( message )
      {
            case WM_KEYDOWN:
            case WM_SYSKEYDOWN:
                  pHWG->IgnoreWM_SYSCHAR = HB_FALSE;
                  iFlags = gthwg_GetKeyFlags();
                  switch( wParam )
                  {
                        case VK_BACK:
                              pHWG->IgnoreWM_SYSCHAR = HB_TRUE;
                              iKey = HB_KX_BS;
                              break;
                        case VK_TAB:
                              pHWG->IgnoreWM_SYSCHAR = HB_TRUE;
                              iKey = HB_KX_TAB;
                              break;
                        case VK_RETURN:
                              pHWG->IgnoreWM_SYSCHAR = HB_TRUE;
                              iKey = HB_KX_ENTER;
                              if( lParam & HWG_EXTKEY_FLAG )
                                    iFlags |= HB_KF_KEYPAD;
                        break;
                        case VK_ESCAPE:
                              pHWG->IgnoreWM_SYSCHAR = HB_TRUE;
                              iKey = HB_KX_ESC;
                              break;

                        case VK_PRIOR:
                              iKeyPad = HB_KX_PGUP;
                              break;
                        case VK_NEXT:
                              iKeyPad = HB_KX_PGDN;
                              break;
                        case VK_END:
                              iKeyPad = HB_KX_END;
                              break;
                        case VK_HOME:
                              iKeyPad = HB_KX_HOME;
                              break;
                        case VK_LEFT:
                              iKeyPad = HB_KX_LEFT;
                              break;
                        case VK_UP:
                              iKeyPad = HB_KX_UP;
                              break;
                        case VK_RIGHT:
                              iKeyPad = HB_KX_RIGHT;
                              break;
                        case VK_DOWN:
                              iKeyPad = HB_KX_DOWN;
                              break;
                        case VK_INSERT:
                              iKeyPad = HB_KX_INS;
                              break;
                        case VK_DELETE:
                              iKey = HB_KX_DEL;
                              if( ( lParam & HWG_EXTKEY_FLAG ) == 0 )
                                    iFlags |= HB_KF_KEYPAD;
                        break;

                        case VK_F1:
                              iKey = HB_KX_F1;
                              break;
                        case VK_F2:
                              iKey = HB_KX_F2;
                              break;
                        case VK_F3:
                              iKey = HB_KX_F3;
                              break;
                        case VK_F4:
                              iKey = HB_KX_F4;
                              break;
                        case VK_F5:
                              iKey = HB_KX_F5;
                              break;
                        case VK_F6:
                              iKey = HB_KX_F6;
                              break;
                        case VK_F7:
                              iKey = HB_KX_F7;
                              break;
                        case VK_F8:
                              iKey = HB_KX_F8;
                              break;
                        case VK_F9:
                              iKey = HB_KX_F9;
                              break;
                        case VK_F10:
                              iKey = HB_KX_F10;
                              break;
                        case VK_F11:
                              iKey = HB_KX_F11;
                              break;
                        case VK_F12:
                              iKey = HB_KX_F12;
                              break;

                        case VK_SNAPSHOT:
                              iKey = HB_KX_PRTSCR;
                              break;
                        case VK_CANCEL:
                              if( ( lParam & HWG_EXTKEY_FLAG ) == 0 )
                                    break;
                        iFlags |= HB_KF_CTRL;
                        /* fallthrough */
                        case VK_PAUSE:
                              pHWG->IgnoreWM_SYSCHAR = HB_TRUE;
                              iKey = HB_KX_PAUSE;
                              break;

                        case VK_CLEAR:
                              iKeyPad = HB_KX_CENTER;
                              break;

                        case VK_NUMPAD0:
                        case VK_NUMPAD1:
                        case VK_NUMPAD2:
                        case VK_NUMPAD3:
                        case VK_NUMPAD4:
                        case VK_NUMPAD5:
                        case VK_NUMPAD6:
                        case VK_NUMPAD7:
                        case VK_NUMPAD8:
                        case VK_NUMPAD9:
                              if( iFlags & HB_KF_CTRL )
                              {
                                    pHWG->IgnoreWM_SYSCHAR = HB_TRUE;
                                    iKey = ( int ) wParam - VK_NUMPAD0 + '0';
                              }
                              else if( iFlags == HB_KF_ALT || iFlags == HB_KF_ALTGR )
                              {
                                    iFlags = 0; /* for ALT + <ASCII_VALUE_FROM_KEYPAD> */
                              }
                              iFlags |= HB_KF_KEYPAD;
                              break;
                        case VK_DECIMAL:
                        case VK_SEPARATOR:
                              iFlags |= HB_KF_KEYPAD;
                              if( iFlags & HB_KF_CTRL )
                              {
                                    pHWG->IgnoreWM_SYSCHAR = HB_TRUE;
                                    iKey = '.';
                              }
                              break;

                        case VK_DIVIDE:
                              iFlags |= HB_KF_KEYPAD;
                              if( iFlags & HB_KF_CTRL )
                                    iKey = '/';
                        break;
                        case VK_MULTIPLY:
                              iFlags |= HB_KF_KEYPAD;
                              if( iFlags & HB_KF_CTRL )
                                    iKey = '*';
                        break;
                        case VK_SUBTRACT:
                              iFlags |= HB_KF_KEYPAD;
                              if( iFlags & HB_KF_CTRL )
                                    iKey = '-';
                        break;
                        case VK_ADD:
                              iFlags |= HB_KF_KEYPAD;
                              if( iFlags & HB_KF_CTRL )
                                    iKey = '+';
                        break;
                        #ifdef VK_OEM_2
                        case VK_OEM_2:
                              if( ( iFlags & HB_KF_CTRL ) != 0 && ( iFlags & HB_KF_SHIFT ) != 0 )
                                    iKey = '?';
                        break;
                        #endif
                        #ifdef VK_APPS
                        case VK_APPS:
                              iKey = HB_K_MENU;
                              break;
                              #endif
                        case VK__TILDA:
                              if( iFlags & HB_KF_CTRL )
                                    iKey = VK__BACKQUOTE;
                        break;
                        case 48:
                              if( iFlags & HB_KF_CTRL )
                                    iKey = VK__CTRL_0;
                        break;
                        case 49:
                              if( iFlags & HB_KF_CTRL )
                                    iKey = VK__CTRL_1;
                        break;
                        case 50:
                              if( iFlags & HB_KF_CTRL )
                                    iKey = VK__CTRL_2;
                        break;
                        case 51:
                              if( iFlags & HB_KF_CTRL )
                                    iKey = VK__CTRL_3;
                        break;
                        case 53:
                              if( iFlags & HB_KF_CTRL )
                                    iKey = VK__CTRL_4;
                        break;
                        case 54:
                              if( iFlags & HB_KF_CTRL )
                                    iKey = VK__CTRL_5;
                        break;
                        case 55:
                              if( iFlags & HB_KF_CTRL )
                                    iKey = VK__CTRL_6;
                        break;
                        case 56:
                              if( iFlags & HB_KF_CTRL )
                                    iKey = VK__CTRL_7;
                        break;
                        case 57:
                              if( iFlags & HB_KF_CTRL )
                                    iKey = VK__CTRL_8;
                        break;
                        case 58:
                              if( iFlags & HB_KF_CTRL )
                                    iKey = VK__CTRL_9;
                        break;
                  }
                  if( iKeyPad != 0 )
                  {
                        iKey = iKeyPad;
                        if( ( lParam & HWG_EXTKEY_FLAG ) == 0 )
                        {
                              if( iFlags == HB_KF_ALT || iFlags == HB_KF_ALTGR )
                                    iFlags = iKey = 0; /* for ALT + <ASCII_VALUE_FROM_KEYPAD> */
                                    else
                                          iFlags |= HB_KF_KEYPAD;
                        }
                  }
                  pHWG->keyFlags = iFlags;
                  if( iKey != 0 )
                        iKey = HB_INKEY_NEW_KEY( iKey, gthwg_UpdateKeyFlags( iFlags ) );
            break;

                        case WM_CHAR:
                              if( ( ( iFlags & HB_KF_CTRL ) != 0 && ( iFlags & HB_KF_ALT ) != 0 ) ||
                                    ( iFlags & HB_KF_ALTGR ) != 0 )
                                    /* workaround for AltGR and some German/Italian keyboard */
                                    iFlags &= ~( HB_KF_CTRL | HB_KF_ALT | HB_KF_ALTGR );
                              /* fallthrough */
                              case WM_SYSCHAR:
                                    iFlags = gthwg_UpdateKeyFlags( iFlags );
                                    if( ! pHWG->IgnoreWM_SYSCHAR )
                                    {
                                          iKey = ( int ) wParam;

                                          if( ( iFlags & HB_KF_CTRL ) != 0 && iKey >= 0 && iKey < 32 )
                                          {
                                                iKey += 'A' - 1;
                                                iKey = HB_INKEY_NEW_KEY( iKey, iFlags );
                                          }
                                          else
                                          {
                                                if( message == WM_SYSCHAR && ( iFlags & HB_KF_ALT ) != 0 )
                                                {
                                                      switch( HIWORD( lParam ) & 0xFF )
                                                      {
                                                            case  2:
                                                                  iKey = '1';
                                                                  break;
                                                            case  3:
                                                                  iKey = '2';
                                                                  break;
                                                            case  4:
                                                                  iKey = '3';
                                                                  break;
                                                            case  5:
                                                                  iKey = '4';
                                                                  break;
                                                            case  6:
                                                                  iKey = '5';
                                                                  break;
                                                            case  7:
                                                                  iKey = '6';
                                                                  break;
                                                            case  8:
                                                                  iKey = '7';
                                                                  break;
                                                            case  9:
                                                                  iKey = '8';
                                                                  break;
                                                            case 10:
                                                                  iKey = '9';
                                                                  break;
                                                            case 11:
                                                                  iKey = '0';
                                                                  break;
                                                            case 13:
                                                                  iKey = '=';
                                                                  break;
                                                            case 14:
                                                                  iKey = HB_KX_BS;
                                                                  break;
                                                            case 16:
                                                                  iKey = 'Q';
                                                                  break;
                                                            case 17:
                                                                  iKey = 'W';
                                                                  break;
                                                            case 18:
                                                                  iKey = 'E';
                                                                  break;
                                                            case 19:
                                                                  iKey = 'R';
                                                                  break;
                                                            case 20:
                                                                  iKey = 'T';
                                                                  break;
                                                            case 21:
                                                                  iKey = 'Y';
                                                                  break;
                                                            case 22:
                                                                  iKey = 'U';
                                                                  break;
                                                            case 23:
                                                                  iKey = 'I';
                                                                  break;
                                                            case 24:
                                                                  iKey = 'O';
                                                                  break;
                                                            case 25:
                                                                  iKey = 'P';
                                                                  break;
                                                            case 30:
                                                                  iKey = 'A';
                                                                  break;
                                                            case 31:
                                                                  iKey = 'S';
                                                                  break;
                                                            case 32:
                                                                  iKey = 'D';
                                                                  break;
                                                            case 33:
                                                                  iKey = 'F';
                                                                  break;
                                                            case 34:
                                                                  iKey = 'G';
                                                                  break;
                                                            case 35:
                                                                  iKey = 'H';
                                                                  break;
                                                            case 36:
                                                                  iKey = 'J';
                                                                  break;
                                                            case 37:
                                                                  iKey = 'K';
                                                                  break;
                                                            case 38:
                                                                  iKey = 'L';
                                                                  break;
                                                            case 44:
                                                                  iKey = 'Z';
                                                                  break;
                                                            case 45:
                                                                  iKey = 'X';
                                                                  break;
                                                            case 46:
                                                                  iKey = 'C';
                                                                  break;
                                                            case 47:
                                                                  iKey = 'V';
                                                                  break;
                                                            case 48:
                                                                  iKey = 'B';
                                                                  break;
                                                            case 49:
                                                                  iKey = 'N';
                                                                  break;
                                                            case 50:
                                                                  iKey = 'M';
                                                                  break;
                                                      }
                                                }
                                                #if defined( UNICODE )
                                                //hwg_writelog( NULL, "Unicode\r\n" );
                                                if( iKey >= 127 )
                                                      iKey = HB_INKEY_NEW_UNICODEF( iKey, iFlags );
                                                else if( iFlags & ( HB_KF_CTRL | HB_KF_ALT ) )
                                                      iKey = HB_INKEY_NEW_KEY( iKey, iFlags );
                                                else
                                                      iKey = HB_INKEY_NEW_CHARF( iKey, iFlags );
                                                #else
                                                {
                                                      int u = HB_GTSELF_KEYTRANS( pHWG->pGT, iKey );
                                                      //hwg_writelog( NULL, "No Unicode\r\n" );
                                                      if( u )
                                                            iKey = HB_INKEY_NEW_UNICODEF( u, iFlags );
                                                      else if( iKey < 127 && ( iFlags & ( HB_KF_CTRL | HB_KF_ALT ) ) )
                                                            iKey = HB_INKEY_NEW_KEY( iKey, iFlags );
                                                      else
                                                      {
                                                            if( pHWG->CodePage == OEM_CHARSET )
                                                                  iKey = gthwg_key_ansi_to_oem( iKey );
                                                            iKey = HB_INKEY_NEW_CHARF( iKey, iFlags );
                                                      }
                                                }
                                                #endif
                                          }
                                    }
                                    pHWG->IgnoreWM_SYSCHAR = HB_FALSE;
                                    break;
      }

      if( iKey != 0 )
            gthwg_AddCharToInputQueue( pHWG, iKey );

      return 0;
}

static void gthwg_UpdateCaret( PHB_GTHWG pHWG )
{
      int iRow, iCol, iStyle, iCaretSize;

      HB_GTSELF_GETSCRCURSOR( pHWG->pGT, &iRow, &iCol, &iStyle );

      //hwg_writelog( NULL, "updCaret-1\r\n" );
      if( iRow < 0 || iCol < 0 || iRow >= pHWG->ROWS || iCol >= pHWG->COLS )
            iCaretSize = 0;
      else switch( iStyle )
      {
            case SC_INSERT:
                  iCaretSize = pHWG->PTEXTSIZE.y >> 1;
                  break;
            case SC_SPECIAL1:
                  iCaretSize = pHWG->PTEXTSIZE.y;
                  break;
            case SC_SPECIAL2:
                  iCaretSize = - ( pHWG->PTEXTSIZE.y >> 1 );
                  break;
            case SC_NORMAL:
                  iCaretSize = HB_MAX( ( pHWG->PTEXTSIZE.y >> 2 ) - 1, 1 );
                  break;
            default:
                  iCaretSize = 0;
                  break;
      }

      if( iCaretSize == 0 )
      {
            if( pHWG->CaretExist && ! pHWG->CaretHidden )
            {
                  HideCaret( pHWG->hWnd );
                  pHWG->CaretHidden = HB_TRUE;
            }
      }
      else
      {
            if( iCaretSize != pHWG->CaretSize || pHWG->PTEXTSIZE.x != pHWG->CaretWidth ||
                  ! pHWG->CaretExist )
            {
                  pHWG->CaretSize = iCaretSize;
                  pHWG->CaretWidth = pHWG->PTEXTSIZE.x;
                  pHWG->CaretExist = CreateCaret( pHWG->hWnd, NULL, pHWG->PTEXTSIZE.x,
                                                  pHWG->CaretSize < 0 ? - pHWG->CaretSize : pHWG->CaretSize );
            }
            if( pHWG->CaretExist )
            {
                  POINT xy;
                  xy = gthwg_GetXYFromColRow( pHWG, iCol, iRow );
                  SetCaretPos( xy.x, pHWG->CaretSize < 0 ?
                  xy.y : xy.y + pHWG->PTEXTSIZE.y - pHWG->CaretSize );
                  ShowCaret( pHWG->hWnd );
                  pHWG->CaretHidden = HB_FALSE;
            }
      }
      //hwg_writelog( NULL, "updCaret-10\r\n" );
}

static void gthwg_KillCaret( PHB_GTHWG pHWG )
{
      if( pHWG->CaretExist )
      {
            DestroyCaret();
            pHWG->CaretExist = HB_FALSE;
      }
}

static void gthwg_SetFont( HWND h, HFONT hf )
{
      HDC hdc = GetDC( h );
      TEXTMETRIC tm;

      SelectObject( hdc, hf );
      GetTextMetrics( hdc, &tm );
      ReleaseDC( h, hdc );
      //hwg_writelog( NULL, "checkf %d %d %lu\r\n", tm.tmHeight, tm.tmAveCharWidth, hf );
}

static void gthwg_ResetWindowSize( PHB_GTHWG pHWG )
{
      HDC        hdc;
      TEXTMETRIC tm;
      RECT       wi, ci;
      int        height, width, n;

      //hwg_writelog( NULL, "ResetSize-1\r\n" );
      hdc = GetDC( pHWG->hWnd );
      SelectObject( hdc, pHWG->hFont );
      GetTextMetrics( hdc, &tm );
      SetTextCharacterExtra( hdc, 0 ); /* do not add extra char spacing even if bold */
      ReleaseDC( pHWG->hWnd, hdc );

      pHWG->PTEXTSIZE.x = tm.tmAveCharWidth;
      pHWG->PTEXTSIZE.y = tm.tmHeight;

      pHWG->FixedFont = pHWG->fontWidth >= 0 &&
      ( tm.tmPitchAndFamily & TMPF_FIXED_PITCH ) == 0 &&
      ( pHWG->PTEXTSIZE.x == tm.tmMaxCharWidth );

      /* pHWG->FixedSize[] is used by ExtTextOut() to emulate
       fixed font whe*n a proportional font is used */
      for( n = 0; n < pHWG->COLS; n++ )
            pHWG->FixedSize[ n ] = pHWG->PTEXTSIZE.x;

      gthwg_GetWindowRect( pHWG->hWnd, &wi );
      gthwg_GetClientRect( pHWG->hWnd, &ci );

      height = ( int ) ( pHWG->PTEXTSIZE.y * pHWG->ROWS );
      width  = ( int ) ( pHWG->PTEXTSIZE.x * pHWG->COLS );

      width  += ( int ) ( wi.right - wi.left - ci.right );
      height += ( int ) ( wi.bottom - wi.top - ci.bottom );

      //hwg_writelog( NULL, "_resetsize-2 %d %d %d %d\r\n", pHWG->fontHeight, pHWG->PTEXTSIZE.y, pHWG->PTEXTSIZE.x, height );
      /* Will resize window without moving left/top origin */
      gthwg_SetWindowPos( pHWG->hWnd, wi.left, wi.top, width, height, SWP_NOZORDER );
      if( pHWG->CaretExist && ! pHWG->CaretHidden )
            gthwg_UpdateCaret( pHWG );
      //hwg_writelog( NULL, "ResetSize-10\r\n" );

}

static HB_BOOL gthwg_SetWindowSize( PHB_GTHWG pHWG, int iRows, int iCols )
{
      //hwg_writelog( NULL, "SetWindowSize-0\r\n" );
      if( HB_GTSELF_RESIZE( pHWG->pGT, iRows, iCols ) )
      {
            if( pHWG->COLS != iCols )
            {
                  pHWG->TextLine = ( TCHAR * ) hb_xrealloc( pHWG->TextLine,
                                                            iCols * sizeof( TCHAR ) );
                  pHWG->FixedSize = ( int * ) hb_xrealloc( pHWG->FixedSize, iCols * sizeof( int ) );
            }
            //if( pHWG->hWnd && ( iRows != pHWG->ROWS || iCols != pHWG->COLS ) )
            //   hb_gt_wvt_AddCharToInputQueue( pHWG, HB_K_RESIZE );

            pHWG->ROWS = iRows;
            pHWG->COLS = iCols;
            return HB_TRUE;
      }
      return HB_FALSE;
}

static void gthwg_TextOut( PHB_GTHWG pHWG, HDC hdc, int col, int row, int iColor, LPCTSTR lpString, UINT cbString )
{
      POINT xy;
      RECT  rClip;
      UINT  fuOptions = ETO_CLIPPED;

      //hwg_writelog( NULL, "_TextOut-1\r\n" );
      xy = gthwg_GetXYFromColRow( pHWG, col, row );
      SetRect( &rClip, xy.x, xy.y, xy.x + cbString * pHWG->PTEXTSIZE.x, xy.y + pHWG->PTEXTSIZE.y );
      fuOptions |= ETO_OPAQUE;

      /* set background color */
      SetBkColor( hdc, pHWG->COLORS[ ( iColor >> 4 ) & 0x0F ] );
      /* set foreground color */
      SetTextColor( hdc, pHWG->COLORS[ iColor & 0x0F ] );

      SetTextAlign( hdc, TA_LEFT );

      ExtTextOut( hdc, xy.x, xy.y, fuOptions, &rClip,
                  lpString, cbString, pHWG->FixedFont ? NULL : pHWG->FixedSize );
}

static void gthwg_PaintText( PHB_GTHWG pHWG )
{
      PAINTSTRUCT ps;
      HDC         hdc;
      RECT        rcRect;
      int         iRow;
      int         iColor, iOldColor = 0;
      HB_BYTE     bAttr;
      HB_BOOL     fFixMetric = 1;  //( pHWG->fontAttribute & HB_GTI_FONTA_FIXMETRIC ) != 0;

      hdc = BeginPaint( pHWG->hWnd, &ps );

      SelectObject( hdc, pHWG->hFont );
      rcRect = gthwg_GetColRowFromXYRect( pHWG, ps.rcPaint );

      //hwg_writelog( NULL, "_PaintText-1 %d %d\r\n", rcRect.top, rcRect.bottom );
      for( iRow = rcRect.top; iRow <= rcRect.bottom; ++iRow )
      {
            int iCol, startCol, len;

            iCol = startCol = rcRect.left;
            len = 0;

            while( iCol <= rcRect.right )
            {
                  #if defined( UNICODE )
                  HB_USHORT usChar;

                  if( ! HB_GTSELF_GETSCRCHAR( pHWG->pGT, iRow, iCol, &iColor, &bAttr, &usChar ) )
                        break;
                  if( ( pHWG->fontAttribute & HB_GTI_FONTA_CTRLCHARS ) == 0 )
                        usChar = hb_cdpGetU16Ctrl( usChar );

                  if( len == 0 )
                  {
                        iOldColor = iColor;
                        startCol = iCol;
                  }
                  else if( iColor != iOldColor || fFixMetric )
                  {
                        gthwg_TextOut( pHWG, hdc, startCol, iRow, iOldColor, pHWG->TextLine, ( UINT ) len );
                        iOldColor = iColor;
                        startCol = iCol;
                        len = 0;
                  }
                  pHWG->TextLine[ len++ ] = ( TCHAR ) usChar;
                  /*
                   i f( usChar *!= 32 )
                   {
                   hwg_writelog( NULL, "char: %d %u %u\r\n", usChar,
                   ((unsigned char*)pHWG->TextLine)[0], ((unsigned char*)pHWG->TextLine)[1] );
            }
            */
                  #else
                  HB_UCHAR uc;
                  if( ! HB_GTSELF_GETSCRUC( pHWG->pGT, iRow, iCol, &iColor, &bAttr, &uc, HB_TRUE ) )
                        break;
                  if( len == 0 )
                  {
                        iOldColor = iColor;
                  }
                  else if( iColor != iOldColor || fFixMetric )
                  {
                        gthwg_TextOut( pHWG, hdc, startCol, iRow, iOldColor, pHWG->TextLine, ( UINT ) len );
                        iOldColor = iColor;
                        startCol = iCol;
                        len = 0;
                  }
                  pHWG->TextLine[ len++ ] = ( TCHAR ) uc;
                  #endif
                  iCol++;
            }
            if( len > 0 )
                  gthwg_TextOut( pHWG, hdc, startCol, iRow, iOldColor, pHWG->TextLine, ( UINT ) len );
      }

      if( s_pSymTest_paint )
            gthwg_PaintCB( hdc );

      EndPaint( pHWG->hWnd, &ps );
}

LRESULT CALLBACK gthwg_WinProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{
      PHB_GTHWG pHWG = pHWGMain;
      //hwg_writelog( NULL, "Message: %u \r\n", message );
      if( pHWG && pHWG->hWnd )
      {
            switch( message )
            {
                  case WM_PAINT:
                        //if( HB_GTSELF_DISPCOUNT( pHWG->pGT ) == 0 )
                        if( GetUpdateRect( hWnd, NULL, FALSE ) )
                              gthwg_PaintText( pHWG );
                  SetFocus( hWnd );
                  return 0;

                  case WM_GETDLGCODE:
                        return DLGC_WANTALLKEYS;

                  case WM_ERASEBKGND:
                        return 0;

                  case WM_MY_UPDATE_CARET:
                        gthwg_UpdateCaret( pHWG );
                        return 0;

                  case WM_SETFOCUS:
                        gthwg_UpdateCaret( pHWG );
                        return 0;

                  case WM_KILLFOCUS:
                        gthwg_KillCaret( pHWG );
                        return 0;

                  case WM_KEYDOWN:
                  case WM_SYSKEYDOWN:
                  case WM_CHAR:
                  case WM_SYSCHAR:
                        return gthwg_KeyEvent( pHWG, message, wParam, lParam );

                  case WM_MOUSEMOVE:
                  case WM_NCMOUSEMOVE:
                        gthwg_MouseEvent( pHWG, message, wParam, lParam );
                        return 0;

                  case WM_RBUTTONDOWN:
                  case WM_LBUTTONDOWN:
                  case WM_RBUTTONUP:
                  case WM_LBUTTONUP:
                  case WM_RBUTTONDBLCLK:
                  case WM_LBUTTONDBLCLK:
                  case WM_MBUTTONDOWN:
                  case WM_MBUTTONUP:
                  case WM_MBUTTONDBLCLK:
                  case WM_MOUSEWHEEL:
                        gthwg_MouseEvent( pHWG, message, wParam, lParam );
                        SetFocus( hWnd );
                        return 0;

                  case WM_QUERYENDSESSION: /* check if we can shutdown or logoff */
                        return 1;

                        #if defined( WM_ENDSESSION )
                  case WM_ENDSESSION: /* shutdown started */
                        if( wParam )
                              hb_vmRequestQuit();
                  return 0;
                  #endif

                  case WM_CLOSE:  /* Clicked 'X' on system menu */
                        if( pHWG->CloseMode == 0 )
                              hb_vmRequestQuit();
                  return 0;

                  case WM_QUIT:
                        return ( wpOrigWndProc( hWnd, message, wParam, lParam ) );

                  case WM_DESTROY:
                        if( hPaneMain )
                              hb_vmRequestQuit();
                  return 0;
                  //return ( wpOrigWndProc( hWnd, message, wParam, lParam ) );

                  case WM_ENTERIDLE:
                        /* FSG - 2004-05-12 - Signal than i'm on idle */
                        hb_idleState();
                        return 0;

                  case WM_ACTIVATE:
                        gthwg_AddCharToInputQueue( pHWG, LOWORD( wParam ) == WA_INACTIVE ? HB_K_LOSTFOCUS : HB_K_GOTFOCUS );
                        return ( wpOrigWndProc( hWnd, message, wParam, lParam ) );

            }
            return ( wpOrigWndProc( hWnd, message, wParam, lParam ) );
      }
      else
            return ( DefWindowProc( hWnd, message, wParam, lParam ) );
}

HB_FUNC( GTHWG_SETWINDOW )
{
      HMENU hSysMenu;

      hWndMain = (HWND)hb_parptr( 1 );
      if( HB_ISNIL( 2 ) )
      {
            if( pHWGMain )
                  hFontMain = gthwg_GetFont( pHWGMain->fontFace, pHWGMain->fontHeight, pHWGMain->fontWidth, pHWGMain->fontWeight, pHWGMain->fontQuality, pHWGMain->CodePage );
      }
      else
            hFontMain = (HFONT)hb_parptr( 2 );

      //hwg_writelog( NULL, "_setwindow-1 %d\r\n", ((hWndMain)? 1:0) );
      if( pHWGMain )
      {
            hSysMenu = GetSystemMenu( hWndMain, FALSE );
            if( hSysMenu )
                  EnableMenuItem( hSysMenu, SC_CLOSE, MF_BYCOMMAND |
                  ( pHWGMain->CloseMode < 2 ? MF_ENABLED : MF_GRAYED ) );
      }
      ShowWindow( hWndMain, SW_SHOWNORMAL );
      SetWindowLong( hWndMain, GWL_STYLE, GetWindowLong(hWndMain, GWL_STYLE) & ~WS_MAXIMIZEBOX );

      //gthwg_ProcessMessages();
      hwg_doEvents();
      wpOrigWndProc = ( WNDPROC ) SetWindowLongPtr( hWndMain,
                                                    GWLP_WNDPROC, ( LONG_PTR ) gthwg_WinProc );

      if( iNewPosX != -1 )
      {
            RECT wi = { 0, 0, 0, 0 };

            gthwg_GetWindowRect( hWndMain , &wi );
            gthwg_SetWindowPos( hWndMain, iNewPosX, iNewPosY,
                                wi.right - wi.left, wi.bottom - wi.top, SWP_NOSIZE | SWP_NOZORDER );
            iNewPosX = iNewPosY = -1;
      }

      if( pHWGMain )
            gthwg_SetWindowSize( pHWGMain, pHWGMain->ROWS, pHWGMain->COLS );

      //hwg_writelog( NULL, "_setwindow-2 %d\r\n", ((hWndMain)? 1:0) );
}

HB_FUNC( GTHWG_SETPANEL )
{

      HMENU hSysMenu;

      hPaneMain = (HWND) hb_parptr( 1 );
      hWndMain = (HWND) hb_parptr( 2 );

      if( HB_ISNIL( 3 ) )
      {
            if( pHWGMain )
                  hFontMain = gthwg_GetFont( pHWGMain->fontFace, pHWGMain->fontHeight, pHWGMain->fontWidth, pHWGMain->fontWeight, pHWGMain->fontQuality, pHWGMain->CodePage );
            else
            {
                  //hwg_writelog( NULL, "_setwindow-0 %d\r\n", ((pHWGMain)? 1:0) );
            }
      }
      else
            hFontMain = (HFONT)hb_parptr( 3 );

      //hwg_writelog( NULL, "_setpanel-1\r\n" );
      wpOrigWndProc = ( WNDPROC ) SetWindowLongPtr( hPaneMain, GWLP_WNDPROC, ( LONG_PTR ) gthwg_WinProc );

      if( pHWGMain )
      {
            hSysMenu = GetSystemMenu( hWndMain, FALSE );
            if( hSysMenu )
                  EnableMenuItem( hSysMenu, SC_CLOSE, MF_BYCOMMAND |
                  ( pHWGMain->CloseMode < 2 ? MF_ENABLED : MF_GRAYED ) );
      }
      ShowWindow( hWndMain, SW_SHOWNORMAL );
      SetWindowLong( hWndMain, GWL_STYLE, GetWindowLong(hWndMain, GWL_STYLE) & ~WS_MAXIMIZEBOX );

      hwg_doEvents();

      if( iNewPosX != -1 )
      {
            RECT wi = { 0, 0, 0, 0 };

            gthwg_GetWindowRect( hWndMain , &wi );
            gthwg_SetWindowPos( hWndMain, iNewPosX, iNewPosY,
                                wi.right - wi.left, wi.bottom - wi.top, SWP_NOSIZE | SWP_NOZORDER );
            iNewPosX = iNewPosY = -1;
      }
      gthwg_SetWindowSize( pHWGMain, pHWGMain->ROWS, pHWGMain->COLS );

      //hwg_writelog( NULL, "_setpanel-2 %d\r\n", ((hWnd)? 1:0) );
}

HB_FUNC( GTHWG_CLOSEWINDOW )
{
      hWndMain = NULL;
      //hwg_writelog( NULL, "_closewindow\r\n" );
}

HB_FUNC( GTHWG_GETSIZE )
{
      PHB_ITEM aSize = hb_itemArrayNew( 2 );

      hb_itemPutNL( hb_arrayGetItemPtr( aSize, 1 ), iNewWidth );
      hb_itemPutNL( hb_arrayGetItemPtr( aSize, 2 ), iNewHeight );

      /* hb_itemReturn already returns the item; do NOT call hb_itemRelease. */
      hb_itemReturn( aSize );
}

static void hb_gt_hwg_Init( PHB_GT pGT, HB_FHANDLE hFilenoStdin, HB_FHANDLE hFilenoStdout, HB_FHANDLE hFilenoStderr )
{

      PHB_GTHWG pHWG = (PHB_GTHWG) hb_xgrab( sizeof( HB_GTHWG ) );
      memset( pHWG, 0, sizeof(HB_GTHWG) );

      //hwg_writelog( NULL, "_init-1\r\n" );
      pHWG->pGT = pGT;
      pHWGMain = pHWG;

      pHWG->PTEXTSIZE.x       = HWG_DEFAULT_FONT_WIDTH;
      pHWG->PTEXTSIZE.y       = HWG_DEFAULT_FONT_HEIGHT;
      pHWG->fontWidth         = HWG_DEFAULT_FONT_WIDTH;
      pHWG->fontHeight        = HWG_DEFAULT_FONT_HEIGHT;
      pHWG->fontWeight        = FW_NORMAL;
      pHWG->fontQuality       = DEFAULT_QUALITY;
      pHWG->fontAttribute     = HWG_DEFAULT_FONT_ATTR;

      HB_STRNCPY( pHWG->fontFace, HWG_DEFAULT_FONT_NAME, HB_SIZEOFARRAY( pHWG->fontFace ) - 1 );

      pHWG->MarginTop         = 0;
      pHWG->MarginLeft        = 0;

      pHWG->ROWS = HWG_DEFAULT_ROWS;
      pHWG->COLS = HWG_DEFAULT_COLS;

      pHWG->TextLine = ( TCHAR * ) hb_xgrab( pHWG->COLS * sizeof( TCHAR ) );
      pHWG->FixedSize = ( int * ) hb_xgrab( pHWG->COLS * sizeof( int ) );

      pHWG->COLORS[ 0 ]       = BLACK;
      pHWG->COLORS[ 1 ]       = BLUE;
      pHWG->COLORS[ 2 ]       = GREEN;
      pHWG->COLORS[ 3 ]       = CYAN;
      pHWG->COLORS[ 4 ]       = RED;
      pHWG->COLORS[ 5 ]       = MAGENTA;
      pHWG->COLORS[ 6 ]       = BROWN;
      pHWG->COLORS[ 7 ]       = LIGHT_GRAY;
      pHWG->COLORS[ 8 ]       = GRAY;
      pHWG->COLORS[ 9 ]       = BRIGHT_BLUE;
      pHWG->COLORS[ 10 ]      = BRIGHT_GREEN;
      pHWG->COLORS[ 11 ]      = BRIGHT_CYAN;
      pHWG->COLORS[ 12 ]      = BRIGHT_RED;
      pHWG->COLORS[ 13 ]      = BRIGHT_MAGENTA;
      pHWG->COLORS[ 14 ]      = YELLOW;
      pHWG->COLORS[ 15 ]      = WHITE;

      pHWG->keyPointerIn      = 0;
      pHWG->keyPointerOut     = 0;
      pHWG->keyLastPos        = 0;

      pHWG->IgnoreWM_SYSCHAR  = HB_FALSE;

      pHWG->CaretExist        = HB_FALSE;
      pHWG->CaretHidden       = HB_TRUE;
      pHWG->CaretSize         = 0;
      pHWG->CaretWidth        = 0;

      pHWG->CodePage          = OEM_CHARSET;     /* GetACP(); - set code page to default system */
      pHWG->CloseMode         = 0;

      HB_GTLOCAL( pGT ) = ( void * ) pHWG;
      HB_GTSUPER_INIT( pGT, hFilenoStdin, hFilenoStdout, hFilenoStderr );
      //hwg_writelog( NULL, "_init-10\r\n" );
}

static void hb_gt_hwg_Exit( PHB_GT pGT )
{

      PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );

      //hwg_writelog( NULL, "_exit\r\n" );

      if( pHWG )
      {
            if( pHWG->hWindowTitle )
                  hb_strfree( pHWG->hWindowTitle );

            if( pHWG->TextLine )
                  hb_xfree( pHWG->TextLine );

            if( pHWG->FixedSize )
                  hb_xfree( pHWG->FixedSize );

            hb_xfree( pHWG );
      }
      HB_GTSUPER_EXIT( pGT );

      /* TODO: */
}


static int hb_gt_hwg_ReadKey( PHB_GT pGT, int iEventMask )
{

      PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );
      int c = 0;
      HB_BOOL fKey;

      HB_SYMBOL_UNUSED( iEventMask );

      //hwg_writelog( NULL, "ReadKey-1\r\n" );
      if( pHWG->hWnd )
      {
            //hwg_writelog( NULL, "_readkey-1\r\n" );
            //gthwg_ProcessMessages();
            hwg_doEvents();
            fKey = gthwg_GetCharFromInputQueue( pHWG, &c );

            return fKey ? c : 0;
      }

      /* TODO: check the input queue (incoming mouse and keyboard events)
       and retu*rn the inkey code if any */

      return 0;
}

static const char * hb_gt_hwg_Version( PHB_GT pGT, int iType )
{

      HB_SYMBOL_UNUSED( pGT );

      if( iType == 0 )
            return HB_GT_DRVNAME( HB_GT_NAME );

      return "Terminal: (template)";
}

static HB_BOOL hb_gt_hwg_SetMode( PHB_GT pGT, int iRows, int iCols )
{

      PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );
      HB_BOOL fResult;

      //hwg_writelog( NULL, "Setmode-1\r\n" );
      if( pHWG->hWnd )
      {
            fResult = gthwg_SetWindowSize( pHWG, iRows, iCols );
            gthwg_ResetWindowSize( pHWG );
            HB_GTSELF_REFRESH( pGT );
      }
      else
      {
            fResult = gthwg_SetWindowSize( pHWG, iRows, iCols );
            HB_GTSELF_SEMICOLD( pGT );
      }

      return fResult;
}

static void hb_gt_hwg_Redraw( PHB_GT pGT, int iRow, int iCol, int iSize )
{
      PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );

      //hwg_writelog( NULL, "_redraw\r\n" );
      if( pHWG )
      {
            if( pHWG->hWnd )
            {
                  RECT rect;

                  rect.top = rect.bottom = iRow;
                  rect.left = iCol;
                  rect.right = iCol + iSize - 1;

                  rect = gthwg_GetXYFromColRowRect( pHWG, rect );

                  //hwg_writelog( NULL, "_redraw-2\r\n" );
                  gthwg_InvalidateRect( pHWG->hWnd, &rect, FALSE );
                  //hwg_writelog( NULL, "_redraw-3 %d %d %d %d\r\n", rect.top, rect.left, rect.bottom, rect.right );
            }
      }
      //hwg_writelog( NULL, "_redraw10\r\n" );
}

static void hb_gt_hwg_Refresh( PHB_GT pGT )
{

      PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );
      int iRow, iCol, iStyle;

      //hwg_writelog( NULL, "_refresh-0\r\n" );
      HB_GTSUPER_REFRESH( pGT );

      if( pHWG )
      {
            if( !pHWG->hWnd )
            {
                  //hwg_writelog( NULL, "_refresh-1\r\n" );
                  if( hPaneMain )
                  {
                        pHWG->hWnd = hPaneMain;
                        pHWG->hFont = hFontMain;
                        gthwg_ResetWindowSize( pHWG );
                  }
                  else if( hWndMain )
                  {
                        pHWG->hWnd = hWndMain;
                        pHWG->hFont = hFontMain;
                        gthwg_ResetWindowSize( pHWG );
                  }
            }
            if( pHWG->hWnd )
            {
                  if( hPaneMain || hWndMain )
                  {
                        SendNotifyMessage( pHWG->hWnd, WM_MY_UPDATE_CARET, 0, 0 );
                        hwg_doEvents();
                  }
                  else
                  {
                        pHWG->hWnd = NULL;
                  }
            }
      }

      HB_GTSELF_GETSCRCURSOR( pGT, &iRow, &iCol, &iStyle );
      HB_SYMBOL_UNUSED( iRow );
      HB_SYMBOL_UNUSED( iCol );
      HB_SYMBOL_UNUSED( iStyle );
      //hwg_writelog( NULL, "_refresh-10\r\n" );
      /* TODO: set cursor position and shape */
}


static HB_BOOL hb_gt_hwg_Info( PHB_GT pGT, int iType, PHB_GT_INFO pInfo )
{
      PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );
      int iVal;

      //hwg_writelog( NULL, "gt_hwg_Info_1\r\n" );
      switch( iType )
      {
            case HB_GTI_ISUNICODE:
                  #if defined( UNICODE )
                  pInfo->pResult = hb_itemPutL( pInfo->pResult, HB_TRUE );
                  #else
                  pInfo->pResult = hb_itemPutL( pInfo->pResult, HB_FALSE );
                  #endif
                  break;

            case HB_GTI_FONTSIZE:
                  pInfo->pResult = hb_itemPutNI( pInfo->pResult, pHWG->PTEXTSIZE.y );
                  iVal = hb_itemGetNI( pInfo->pNewVal );
                  if( iVal > 0 )
                  {
                        HFONT hFont = gthwg_GetFont( pHWG->fontFace, iVal, pHWG->fontWidth, pHWG->fontWeight, pHWG->fontQuality, pHWG->CodePage );
                        //hwg_writelog( NULL, "_gti_fontsize-1 %d\r\n", iVal );
                        if( hFont )
                        {
                              gthwg_SetFont( (hPaneMain)? hPaneMain : hWndMain, hFont );
                              pHWG->fontHeight = iVal;
                              pHWG->hFont = hFont;
                              hFontMain = hFont;
                              if( pHWG->hWnd )
                              {
                                    //hwg_writelog( NULL, "_gti_fontsize-3\r\n" );
                                    gthwg_ResetWindowSize( pHWG );
                                    HB_GTSELF_REFRESH( pGT );
                              }
                        }
                  }
                  break;

            case HB_GTI_FONTWIDTH:
                  pInfo->pResult = hb_itemPutNI( pInfo->pResult, pHWG->fontWidth );
                  iVal = hb_itemGetNI( pInfo->pNewVal );
                  if( iVal > 0 )
                  {
                        //hwg_writelog( NULL, "_gti_fontwidth-1 %d\r\n", iVal );
                        pHWG->fontWidth = iVal;  /* store font status for next operation on fontsize */
                  }
                  break;

            case HB_GTI_FONTNAME:
                  pInfo->pResult = HB_ITEMPUTSTR( pInfo->pResult, pHWG->fontFace );
                  if( hb_itemType( pInfo->pNewVal ) & HB_IT_STRING )
                  {
                        HB_ITEMCOPYSTR( pInfo->pNewVal, pHWG->fontFace, HB_SIZEOFARRAY( pHWG->fontFace ) );
                        pHWG->fontFace[ HB_SIZEOFARRAY( pHWG->fontFace ) - 1 ] = TEXT( '\0' );
                  }
                  break;

            case HB_GTI_SCREENHEIGHT:
                  pInfo->pResult = hb_itemPutNI( pInfo->pResult, pHWG->PTEXTSIZE.y * pHWG->ROWS );
                  iVal = hb_itemGetNI( pInfo->pNewVal );
                  if( iVal > 0 && pHWG->hWnd ) //&& ! pHWG->bMaximized && ! pHWG->bFullScreen  )  /* Don't allow if Maximized or FullScreen */
                  {
                        /* Now conforms to pHWG->ResizeMode setting, resize by FONT or ROWS as applicable [HVB] */
                        RECT ci;
                        gthwg_GetClientRect( pHWG->hWnd, &ci );
                        if( ci.bottom != iVal )
                        {
                              RECT wi;
                              gthwg_GetWindowRect( pHWG->hWnd, &wi );
                              iVal += wi.bottom - wi.top - ci.bottom;
                              gthwg_SetWindowPos( pHWG->hWnd, wi.left, wi.top, wi.right - wi.left, iVal, SWP_NOZORDER );
                        }
                  }
                  break;

            case HB_GTI_SCREENWIDTH:
                  pInfo->pResult = hb_itemPutNI( pInfo->pResult, pHWG->PTEXTSIZE.x * pHWG->COLS );
                  iVal = hb_itemGetNI( pInfo->pNewVal );
                  if( iVal > 0 && pHWG->hWnd ) //&& ! pHWG->bMaximized && ! pHWG->bFullScreen )  /* Don't allow if Maximized or FullScreen */
                  {
                        /* Now conforms to pHWG->ResizeMode setting, resize by FONT or ROWS as applicable [HVB] */
                        RECT ci;
                        gthwg_GetClientRect( pHWG->hWnd, &ci );
                        if( ci.right != iVal )
                        {
                              RECT wi;
                              gthwg_GetWindowRect( pHWG->hWnd, &wi );
                              iVal += wi.right - wi.left - ci.right;
                              gthwg_SetWindowPos( pHWG->hWnd, wi.left, wi.top, iVal, wi.bottom - wi.top, SWP_NOZORDER );
                        }
                  }
                  break;

            case HB_GTI_DESKTOPWIDTH:
            {
                  pInfo->pResult = hb_itemPutNI( pInfo->pResult, gthwg_GetDesktopWidth() );
                  break;
            }
            case HB_GTI_DESKTOPHEIGHT:
            {
                  pInfo->pResult = hb_itemPutNI( pInfo->pResult, gthwg_GetDesktopHeight() );
                  break;
            }
            case HB_GTI_DESKTOPCOLS:
            {
                  pInfo->pResult = hb_itemPutNI( pInfo->pResult,
                                                 gthwg_GetDesktopWidth() / pHWG->PTEXTSIZE.x );
                  break;
            }
            case HB_GTI_DESKTOPROWS:
            {
                  pInfo->pResult = hb_itemPutNI( pInfo->pResult,
                                                 gthwg_GetDesktopHeight() / pHWG->PTEXTSIZE.y );
                  break;
            }

            #if !defined(HB_OS_UNIX)
            case HB_GTI_CLIPBOARDDATA:
                  if( hb_itemType( pInfo->pNewVal ) & HB_IT_STRING )
                        #if defined( UNICODE )
                        hb_gt_winapi_setClipboard( CF_UNICODETEXT, pInfo->pNewVal );
            #else
            hb_gt_winapi_setClipboard( pHWG->CodePage == OEM_CHARSET ?
            CF_OEMTEXT : CF_TEXT, pInfo->pNewVal );
            #endif
            else
            {
                  if( pInfo->pResult == NULL )
                        pInfo->pResult = hb_itemNew( NULL );
                  #if defined( UNICODE )
                  hb_gt_winapi_getClipboard( CF_UNICODETEXT, pInfo->pResult );
                  #else
                  hb_gt_winapi_getClipboard( pHWG->CodePage == OEM_CHARSET ?
                  CF_OEMTEXT : CF_TEXT, pInfo->pResult );
                  #endif
            }
            break;
            #endif
            case HB_GTI_PALETTE:
                  if( hb_itemType( pInfo->pNewVal ) & HB_IT_NUMERIC )
                  {
                        int iIndex = hb_itemGetNI( pInfo->pNewVal );

                        if( iIndex >= 0 && iIndex < 16 )
                        {
                              pInfo->pResult = hb_itemPutNL( pInfo->pResult, pHWG->COLORS[ iIndex ] );

                              if( hb_itemType( pInfo->pNewVal2 ) & HB_IT_NUMERIC )
                              {
                                    pHWG->COLORS[ iIndex ] = hb_itemGetNL( pInfo->pNewVal2 );

                                    if( pHWG->hWnd )
                                          HB_GTSELF_EXPOSEAREA( pHWG->pGT, 0, 0, pHWG->ROWS, pHWG->COLS );
                              }
                        }
                  }
                  else
                  {
                        int i;
                        if( ! pInfo->pResult )
                              pInfo->pResult = hb_itemNew( NULL );
                        hb_arrayNew( pInfo->pResult, 16 );
                        for( i = 0; i < 16; i++ )
                              hb_arraySetNL( pInfo->pResult, i + 1, pHWG->COLORS[ i ] );

                        if( hb_itemType( pInfo->pNewVal ) & HB_IT_ARRAY )
                        {
                              if( hb_arrayLen( pInfo->pNewVal ) == 16 )
                              {
                                    for( i = 0; i < 16; i++ )
                                          pHWG->COLORS[ i ] = hb_arrayGetNL( pInfo->pNewVal, i + 1 );

                                    if( pHWG->hWnd )
                                          HB_GTSELF_EXPOSEAREA( pHWG->pGT, 0, 0, pHWG->ROWS, pHWG->COLS );
                              }
                        }
                  }
                  break;

            case HB_GTI_SETPOS_XY:
            case HB_GTI_SETPOS_ROWCOL:
            {
                  RECT wi = { 0, 0, 0, 0 };
                  int x = 0, y = 0;

                  if( pHWG->hWnd )
                  {
                        gthwg_GetWindowRect( pHWG->hWnd, &wi );
                        if( iType == HB_GTI_SETPOS_ROWCOL )
                        {
                              y = wi.left / pHWG->PTEXTSIZE.x;
                              x = wi.top / pHWG->PTEXTSIZE.y;
                        }
                        else
                        {
                              x = wi.left;
                              y = wi.top;
                        }
                  }

                  if( ! pInfo->pResult )
                        pInfo->pResult = hb_itemNew( NULL );
                  hb_arrayNew( pInfo->pResult, 2 );

                  hb_arraySetNI( pInfo->pResult, 1, x );
                  hb_arraySetNI( pInfo->pResult, 2, y );

                  if( ( hb_itemType( pInfo->pNewVal ) & HB_IT_NUMERIC ) &&
                        ( hb_itemType( pInfo->pNewVal2 ) & HB_IT_NUMERIC ) )
                  {
                        x = hb_itemGetNI( pInfo->pNewVal );
                        y = hb_itemGetNI( pInfo->pNewVal2 );
                  }
                  else if( ( hb_itemType( pInfo->pNewVal ) & HB_IT_ARRAY ) &&
                        hb_arrayLen( pInfo->pNewVal ) == 2 )
                  {
                        x = hb_arrayGetNI( pInfo->pNewVal, 1 );
                        y = hb_arrayGetNI( pInfo->pNewVal, 2 );
                  }
                  else
                        break;

                  if( iType == HB_GTI_SETPOS_ROWCOL )
                  {
                        int c = y;
                        y = x * pHWG->PTEXTSIZE.y;
                        x = c * pHWG->PTEXTSIZE.x;
                  }
                  if( pHWG->hWnd )
                  {
                        gthwg_SetWindowPos( pHWG->hWnd, x, y, wi.right - wi.left, wi.bottom - wi.top,
                                            SWP_NOSIZE | SWP_NOZORDER );
                  }
                  else
                  {
                        iNewPosX = x;
                        iNewPosY = y;
                  }
                  break;
            }

            case HB_GTI_MOUSEPOS_XY:
                  if( ! pInfo->pResult )
                        pInfo->pResult = hb_itemNew( NULL );
            hb_arrayNew( pInfo->pResult, 2 );
            hb_arraySetNI( pInfo->pResult, 1, pHWG->ExactMousePos.x );
            hb_arraySetNI( pInfo->pResult, 2, pHWG->ExactMousePos.y );
            break;

            case HB_GTI_WINHANDLE:
                  pInfo->pResult = hb_itemPutPtr( pInfo->pResult, pHWG->hWnd );
                  break;

            case HB_GTI_CLOSABLE:
                  pInfo->pResult = hb_itemPutL( pInfo->pResult, pHWG->CloseMode == 0 );
                  if( ( hb_itemType( pInfo->pNewVal ) & HB_IT_LOGICAL ) &&
                        ( hb_itemGetL( pInfo->pNewVal ) ? ( pHWG->CloseMode != 0 ) :
                        ( pHWG->CloseMode == 0 ) ) )
                  {
                        iVal = pHWG->CloseMode;
                        pHWG->CloseMode = iVal == 0 ? 1 : 0;
                        if( pHWG->hWnd )
                              gthwg_SetCloseButton( pHWG );
                  }
                  break;

            case HB_GTI_CLOSEMODE:
                  pInfo->pResult = hb_itemPutNI( pInfo->pResult, pHWG->CloseMode );
                  if( hb_itemType( pInfo->pNewVal ) & HB_IT_NUMERIC )
                  {
                        iVal = hb_itemGetNI( pInfo->pNewVal );
                        if( iVal >= 0 && iVal <= 2 && pHWG->CloseMode != iVal )
                        {
                              pHWG->CloseMode = iVal;
                              if( pHWG->hWnd )
                                    gthwg_SetCloseButton( pHWG );
                        }
                  }
                  break;

            case HB_GTI_WINTITLE:
                  GetWindowText( pHWG->hWnd, pHWG->szTitle, 128 );
                  pInfo->pResult = HB_ITEMPUTSTR( pInfo->pResult, pHWG->szTitle );
                  //HB_ITEMGETSTR( pHWG->szTitle, &pHWG->hWindowTitle, NULL ) );
                  if( hb_itemType( pInfo->pNewVal ) & HB_IT_STRING )
                  {
                        if( pHWG->hWnd )
                        {
                              if( pHWG->hWindowTitle )
                              {
                                    hb_strfree( pHWG->hWindowTitle );
                                    pHWG->hWindowTitle = 0;
                              }
                              SetWindowText( pHWG->hWnd, HB_ITEMGETSTR( pInfo->pNewVal, &pHWG->hWindowTitle, NULL ) );
                        }
                  }
                  break;

            default:
                  return HB_GTSUPER_INFO( pGT, iType, pInfo );

      }
      return HB_TRUE;
}

static HB_BOOL hb_gt_hwg_mouse_IsPresent( PHB_GT pGT )
{

      HB_SYMBOL_UNUSED( pGT );

      return HB_TRUE;
}

static void hb_gt_hwg_mouse_GetPos( PHB_GT pGT, int * piRow, int * piCol )
{

      PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );

      *piRow = pHWG->MousePos.y;
      *piCol = pHWG->MousePos.x;
}

static void hb_gt_hwg_mouse_SetPos( PHB_GT pGT, int iRow, int iCol )
{

      PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );

      gthwg_SetMousePos( pHWG, iRow, iCol );
}

static HB_BOOL hb_gt_hwg_mouse_ButtonState( PHB_GT pGT, int iButton )
{

      HB_SYMBOL_UNUSED( pGT );
      #if !defined( HB_OS_UNIX )
      switch( iButton )
      {
            case 0:
                  return ( GetKeyState( VK_LBUTTON ) & 0x8000 ) != 0;
            case 1:
                  return ( GetKeyState( VK_RBUTTON ) & 0x8000 ) != 0;
            case 2:
                  return ( GetKeyState( VK_MBUTTON ) & 0x8000 ) != 0;
      }
      #endif
      return HB_FALSE;
}

/* *********************************************************************** */

static HB_BOOL hb_gt_FuncInit( PHB_GT_FUNCS pFuncTable )
{
      //hwg_writelog( NULL, "FuncInit\r\n" );
      pFuncTable->Init    = hb_gt_hwg_Init;
      pFuncTable->Exit    = hb_gt_hwg_Exit;
      pFuncTable->ReadKey = hb_gt_hwg_ReadKey;
      pFuncTable->Version = hb_gt_hwg_Version;
      pFuncTable->SetMode = hb_gt_hwg_SetMode;
      pFuncTable->Redraw  = hb_gt_hwg_Redraw;
      pFuncTable->Refresh = hb_gt_hwg_Refresh;
      pFuncTable->Info    = hb_gt_hwg_Info;

      pFuncTable->MouseIsPresent    = hb_gt_hwg_mouse_IsPresent;
      pFuncTable->MouseGetPos       = hb_gt_hwg_mouse_GetPos;
      pFuncTable->MouseSetPos       = hb_gt_hwg_mouse_SetPos;
      pFuncTable->MouseButtonState  = hb_gt_hwg_mouse_ButtonState;

      return HB_TRUE;
}

#include "hbgtreg.h"
