/*
 * $Id$

 * QHTM wrappers for Harbour/HwGUI
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su/
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
#include <windows.h>

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "qhtm.h"
#include "hwingui.h"

extern BOOL WINAPI QHTM_Initialize( HINSTANCE hInst );
extern int WINAPI QHTM_MessageBox( HWND hwnd, LPCTSTR lpText,
      LPCTSTR lpCaption, UINT uType );

typedef BOOL( WINAPI * QHTM_INITIALIZE ) ( HINSTANCE hInst );
typedef int ( WINAPI * QHTM_MESSAGEBOX ) ( HWND hwnd, LPCTSTR lpText,
      LPCTSTR lpCaption, UINT uType );
typedef QHTMCONTEXT( WINAPI * QHTM_PRINTCREATECONTEXT ) ( UINT uZoomLevel );
typedef BOOL( WINAPI * QHTM_ENABLECOOLTIPS ) ( void );
typedef BOOL( WINAPI * QHTM_SETHTMLBUTTON ) ( HWND hwndButton );
typedef BOOL( WINAPI * QHTM_PRINTSETTEXT ) ( QHTMCONTEXT ctx,
      LPCTSTR pcszText );
typedef BOOL( WINAPI * QHTM_PRINTSETTEXTFILE ) ( QHTMCONTEXT ctx,
      LPCTSTR pcszText );
typedef BOOL( WINAPI * QHTM_PRINTSETTEXTRESOURCE ) ( QHTMCONTEXT ctx,
      HINSTANCE hInst, LPCTSTR pcszName );
typedef BOOL( WINAPI * QHTM_PRINTLAYOUT ) ( QHTMCONTEXT ctx, HDC dc,
      LPCRECT pRect, LPINT nPages );
typedef BOOL( WINAPI * QHTM_PRINTPAGE ) ( QHTMCONTEXT ctx, HDC hDC,
      UINT nPage, LPCRECT prDest );
typedef void ( WINAPI * QHTM_PRINTDESTROYCONTEXT ) ( QHTMCONTEXT );

static HINSTANCE s_hQhtmDll = NULL;

static BOOL s_qhtmInit( LPCTSTR lpLibname )
{
   if( !s_hQhtmDll )
   {
      if( !lpLibname )
         lpLibname = TEXT( "qhtm.dll" );
      s_hQhtmDll = LoadLibrary( lpLibname );
      if( s_hQhtmDll )
      {
         QHTM_INITIALIZE pFunc =
               ( QHTM_INITIALIZE ) GetProcAddress( s_hQhtmDll,
               "QHTM_Initialize" );
         if( pFunc )
            return ( pFunc( GetModuleHandle( NULL ) ) ) ? 1 : 0;
      }
      else
      {
         MessageBox( GetActiveWindow(), TEXT( "Library not loaded" ), lpLibname,
                     MB_OK | MB_ICONSTOP );
         return 0;
      }
   }
   return 1;
}

HB_FUNC( QHTM_INIT )
{
   void * hLibName;
   hb_retl( s_qhtmInit( HB_PARSTR( 1, &hLibName, NULL ) ) );
   hb_strfree( hLibName );
}

HB_FUNC( QHTM_END )
{
   if( s_hQhtmDll )
   {
      FreeLibrary( s_hQhtmDll );
      s_hQhtmDll = NULL;
   }
}

/*
   CreateQHTM( hParentWindow, nID, nStyle, x1, y1, nWidth, nHeight )
*/
HB_FUNC( CREATEQHTM )
{
   if( s_qhtmInit( NULL ) )
   {
      HWND handle = CreateWindow( TEXT( "QHTM_Window_Class_001" ), /* predefined class  */
            NULL,               /* no window title   */
            WS_CHILD | WS_VISIBLE | (DWORD) hb_parnl( 3 ),      /* style  */
            hb_parni( 4 ), hb_parni( 5 ),       /* x, y       */
            hb_parni( 6 ), hb_parni( 7 ),       /* nWidth, nHeight */
            ( HWND ) HB_PARHANDLE( 1 ),     /* parent window    */
            ( HMENU ) (INT_PTR) hb_parni( 2 ),    /* control ID  */
            GetModuleHandle( NULL ),
            NULL );

      HB_RETHANDLE( handle );
   }
   else
      hb_retnl( 0 );
}

HB_FUNC( QHTM_GETNOTIFY )
{
   LPNMQHTM pnm = ( LPNMQHTM ) HB_PARHANDLE( 1 );

   HB_RETSTR( pnm->pcszLinkText );
}

HB_FUNC( QHTM_SETRETURNVALUE )
{
   LPNMQHTM pnm = ( LPNMQHTM ) HB_PARHANDLE( 1 );
   pnm->resReturnValue = hb_parl( 2 );
}

void CALLBACK FormCallback( HWND hWndQHTM, LPQHTMFORMSubmit pFormSubmit,
                            LPARAM lParam )
{
   PHB_DYNS pSymTest;
   PHB_ITEM aMetr = hb_itemArrayNew( pFormSubmit->uFieldCount );
   PHB_ITEM temp;
   int i;

   for( i = 0; i < ( int ) pFormSubmit->uFieldCount; i++ )
   {
      temp = hb_itemArrayNew( 2 );

      HB_ARRAYSETSTR( temp, 1, ( pFormSubmit->parrFields + i )->pcszName );
      HB_ARRAYSETSTR( temp, 2, ( pFormSubmit->parrFields + i )->pcszValue );

      hb_itemArrayPut( aMetr, i + 1, temp );
      hb_itemRelease( temp );
   }

   HB_SYMBOL_UNUSED( lParam );

   if( ( pSymTest = hb_dynsymFind( "QHTMFORMPROC" ) ) != NULL )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSymTest ) );
      hb_vmPushNil();
      hb_vmPushPointer( hWndQHTM );
      temp = HB_ITEMPUTSTR( NULL, pFormSubmit->pcszMethod );
      hb_vmPush( temp );
      hb_vmPush( HB_ITEMPUTSTR( temp, pFormSubmit->pcszAction ) );
      if( pFormSubmit->pcszName )
         hb_vmPush( HB_ITEMPUTSTR( temp, pFormSubmit->pcszName ) );
      else
         hb_vmPushNil();
      hb_itemRelease( temp );
      hb_vmPush( aMetr );
      hb_vmDo( 5 );
   }
   hb_itemRelease( aMetr );
}

// Wrappers to QHTM Functions

HB_FUNC( QHTM_MESSAGE )
{
   if( s_qhtmInit( NULL ) )
   {
      QHTM_MESSAGEBOX pFunc =
            ( QHTM_MESSAGEBOX ) GetProcAddress( s_hQhtmDll,
                                                "QHTM_MessageBox" );

      if( pFunc )
      {
         void * hText, * hTitle;
         UINT uType = ( hb_pcount() < 3 ) ? MB_OK : ( UINT ) hb_parni( 3 );

         pFunc( GetActiveWindow(), HB_PARSTR( 1, &hText, NULL ),
                HB_PARSTRDEF( 2, &hTitle, NULL ), uType );
         hb_strfree( hText );
         hb_strfree( hTitle );
      }
   }
}

HB_FUNC( QHTM_LOADFILE )
{
   if( s_qhtmInit( NULL ) )
   {
      hb_retl( SendMessage( ( HWND ) HB_PARHANDLE( 1 ), QHTM_LOAD_FROM_FILE, 0,
                            ( LPARAM ) hb_parc( 2 ) ) );
   }
}

HB_FUNC( QHTM_LOADRES )
{
   if( s_qhtmInit( NULL ) )
   {
      hb_retl( SendMessage( ( HWND ) HB_PARHANDLE( 1 ), QHTM_LOAD_FROM_RESOURCE,
                            ( WPARAM ) GetModuleHandle( NULL ),
                            ( LPARAM ) hb_parc( 2 ) ) );
   }
}

HB_FUNC( QHTM_ADDHTML )
{
   if( s_qhtmInit( NULL ) )
   {
      SendMessage( ( HWND ) HB_PARHANDLE( 1 ), QHTM_ADD_HTML, 0,
                   ( LPARAM ) hb_parc( 2 ) );
   }
}

HB_FUNC( QHTM_GETTITLE )
{
   if( s_qhtmInit( NULL ) )
   {
      TCHAR szBuffer[256] = { 0 };
      SendMessage( ( HWND ) HB_PARHANDLE( 1 ), QHTM_GET_HTML_TITLE, 256,
                   ( LPARAM ) szBuffer );
      HB_RETSTR( szBuffer );
   }
}

HB_FUNC( QHTM_GETSIZE )
{
   if( s_qhtmInit( NULL ) )
   {
      SIZE size;

      if( SendMessage( ( HWND ) HB_PARHANDLE( 1 ), QHTM_GET_DRAWN_SIZE, 0,
                  ( LPARAM ) & size ) )
      {
         PHB_ITEM aMetr = hb_itemArrayNew( 2 );
         PHB_ITEM temp;

         temp = hb_itemPutNL( NULL, size.cx );
         hb_itemArrayPut( aMetr, 1, temp );
         hb_itemRelease( temp );

         temp = hb_itemPutNL( NULL, size.cy );
         hb_itemArrayPut( aMetr, 2, temp );
         hb_itemRelease( temp );

         hb_itemReturn( aMetr );
         hb_itemRelease( aMetr );
      }
      else
         hb_ret();
   }
}

HB_FUNC( QHTM_FORMCALLBACK )
{
   if( s_qhtmInit( NULL ) )
   {
      hb_retl( SendMessage( ( HWND ) HB_PARHANDLE( 1 ), QHTM_SET_OPTION,
                  ( WPARAM ) QHTM_OPT_SET_FORM_SUBMIT_CALLBACK,
                  ( LPARAM ) FormCallback ) );
   }
   else
      hb_retl( 0 );
}

HB_FUNC( QHTM_ENABLECOOLTIPS )
{
   if( s_qhtmInit( NULL ) )
   {
      QHTM_ENABLECOOLTIPS pFunc =
            ( QHTM_ENABLECOOLTIPS ) GetProcAddress( s_hQhtmDll,
            "QHTM_EnableCooltips" );
      if( pFunc )
         pFunc();
      else
         hb_retl( 0 );
   }
   else
      hb_retl( 0 );
}

HB_FUNC( QHTM_SETHTMLBUTTON )
{
   if( s_qhtmInit( NULL ) )
   {
      QHTM_SETHTMLBUTTON pFunc =
            ( QHTM_SETHTMLBUTTON ) GetProcAddress( s_hQhtmDll,
            "QHTM_SetHTMLButton" );
      if( pFunc )
         hb_retl( pFunc( ( HWND ) HB_PARHANDLE( 1 ) ) );
      else
         hb_retl( 0 );
   }
   else
      hb_retl( 0 );
}

HB_FUNC( QHTM_PRINTCREATECONTEXT )
{
   if( s_qhtmInit( NULL ) )
   {
      QHTM_PRINTCREATECONTEXT pFunc =
            ( QHTM_PRINTCREATECONTEXT ) GetProcAddress( s_hQhtmDll,
            "QHTM_PrintCreateContext" );
      /* Return as numeric handle (may be 64-bit) */
      hb_retnll( (LONG64) pFunc( ( hb_pcount() == 0 ) ? 1 : ( UINT ) hb_parni( 1 ) ) );
   }
   else
      hb_retnll( 0 );
}

HB_FUNC( QHTM_PRINTSETTEXT )
{
   if( s_qhtmInit( NULL ) )
   {
      void * hText;

      QHTM_PRINTSETTEXT pFunc =
            ( QHTM_PRINTSETTEXT ) GetProcAddress( s_hQhtmDll,
            "QHTM_PrintSetText" );
      hb_retl( pFunc( ( QHTMCONTEXT ) hb_parnll( 1 ),
                      HB_PARSTR( 2, &hText, NULL ) ) );
      hb_strfree( hText );
   }
   else
      hb_retl( 0 );
}

HB_FUNC( QHTM_PRINTSETTEXTFILE )
{
   if( s_qhtmInit( NULL ) )
   {
      void * hText;

      QHTM_PRINTSETTEXTFILE pFunc =
            ( QHTM_PRINTSETTEXTFILE ) GetProcAddress( s_hQhtmDll,
            "QHTM_PrintSetTextFile" );
      hb_retl( pFunc( ( QHTMCONTEXT ) hb_parnll( 1 ),
                      HB_PARSTR( 2, &hText, NULL ) ) );
      hb_strfree( hText );
   }
   else
      hb_retl( 0 );
}

HB_FUNC( QHTM_PRINTSETTEXTRESOURCE )
{
   if( s_qhtmInit( NULL ) )
   {
      void * hText;

      QHTM_PRINTSETTEXTRESOURCE pFunc =
            ( QHTM_PRINTSETTEXTRESOURCE ) GetProcAddress( s_hQhtmDll,
            "QHTM_PrintSetTextResource" );
      hb_retl( pFunc( ( QHTMCONTEXT ) hb_parnll( 1 ), GetModuleHandle( NULL ),
                      HB_PARSTR( 2, &hText, NULL ) ) );
      hb_strfree( hText );
   }
   else
      hb_retl( 0 );
}

HB_FUNC( QHTM_PRINTLAYOUT )
{
   if( s_qhtmInit( NULL ) )
   {
      HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
      QHTMCONTEXT qhtmCtx = ( QHTMCONTEXT ) hb_parnll( 2 );
      RECT rcPage;
      int nNumberOfPages;
      QHTM_PRINTLAYOUT pFunc =
            ( QHTM_PRINTLAYOUT ) GetProcAddress( s_hQhtmDll,
            "QHTM_PrintLayout" );

      rcPage.left = rcPage.top = 0;
      rcPage.right = GetDeviceCaps( hDC, HORZRES );
      rcPage.bottom = GetDeviceCaps( hDC, VERTRES );

      pFunc( qhtmCtx, hDC, &rcPage, &nNumberOfPages );
      hb_retni( nNumberOfPages );
   }
   else
      hb_retnl( 0 );
}

HB_FUNC( QHTM_PRINTPAGE )
{
   if( s_qhtmInit( NULL ) )
   {
      HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
      QHTMCONTEXT qhtmCtx = ( QHTMCONTEXT ) hb_parnll( 2 );
      RECT rcPage;
      QHTM_PRINTPAGE pFunc =
            ( QHTM_PRINTPAGE ) GetProcAddress( s_hQhtmDll,
                                               "QHTM_PrintPage" );

      rcPage.left = rcPage.top = 0;
      rcPage.right = GetDeviceCaps( hDC, HORZRES );
      rcPage.bottom = GetDeviceCaps( hDC, VERTRES );

      hb_retl( pFunc( qhtmCtx, hDC, hb_parni( 3 ) - 1, &rcPage ) );
   }
   else
      hb_retl( 0 );
}

HB_FUNC( QHTM_PRINTDESTROYCONTEXT )
{
   if( s_qhtmInit( NULL ) )
   {
      QHTM_PRINTDESTROYCONTEXT pFunc =
            ( QHTM_PRINTDESTROYCONTEXT ) GetProcAddress( s_hQhtmDll,
            "QHTM_PrintDestroyContext" );
      pFunc( ( QHTMCONTEXT ) hb_parnll( 1 ) );
   }
}