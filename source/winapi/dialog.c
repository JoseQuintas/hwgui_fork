/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level dialog boxes functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

// #define OEMRESOURCE
#include "hwingui.h"

#if defined(__MINGW32__) || defined(__MINGW64__) || defined(__WATCOMC__)
#include <prsht.h>
#endif
#if defined(__DMC__)
#define GetWindowLongPtr GetWindowLong
#endif

#include "hbapiitm.h"
#include "hbvm.h"

#include "incomp_pointer.h"

#define  WM_PSPNOTIFY         WM_USER+1010

static LRESULT CALLBACK s_ModalDlgProc( HWND, UINT, WPARAM, LPARAM );
static LRESULT CALLBACK s_DlgProc( HWND, UINT, WPARAM, LPARAM );
static LRESULT CALLBACK s_PSPProc( HWND, UINT, WPARAM, LPARAM );
static LRESULT CALLBACK s_PSPProcRelease( HWND, UINT, LPPROPSHEETPAGE );

#define	WND_DLG_RESOURCE       10
#define	WND_DLG_NORESOURCE     11

HWND *aDialogs = NULL;
static int s_nDialogs = 0;
int iDialogs = 0;

HB_FUNC( HWG_DIALOGBOX )
{
   PHB_ITEM pObject = hb_param( 2, HB_IT_OBJECT );
   PHB_ITEM pData = GetObjectVar( pObject, "XRESOURCEID" );
   void *hResource;
   LPCTSTR lpResource = HB_ITEMGETSTR( pData, &hResource, NULL );

   if( !lpResource && HB_IS_NUMERIC( pData ) )
      lpResource = MAKEINTRESOURCE( hb_itemGetNI( pData ) );

   DialogBoxParam( hModule, lpResource,
         ( HWND ) HB_PARHANDLE( 1 ), ( DLGPROC ) s_ModalDlgProc,
         ( LPARAM ) pObject );

   hb_strfree( hResource );
}

/*  Creates modeless dialog
    CreateDialog( hParentWindow, aDialog )
*/
HB_FUNC( HWG_CREATEDIALOG )
{
   PHB_ITEM pObject = hb_param( 2, HB_IT_OBJECT );
   HWND hDlg;
   PHB_ITEM pData = GetObjectVar( pObject, "XRESOURCEID" );
   void *hResource;
   LPCTSTR lpResource = HB_ITEMGETSTR( pData, &hResource, NULL );

   if( !lpResource && HB_IS_NUMERIC( pData ) )
      lpResource = MAKEINTRESOURCE( hb_itemGetNI( pData ) );

   hDlg = CreateDialogParam( hModule, lpResource,
         ( HWND ) HB_PARHANDLE( 1 ), ( DLGPROC ) s_DlgProc,
         ( LPARAM ) pObject );
   hb_strfree( hResource );

   ShowWindow( hDlg, SW_SHOW );
   HB_RETHANDLE( hDlg );
}

HB_FUNC( HWG__ENDDIALOG )
{
   EndDialog( ( HWND ) HB_PARHANDLE( 1 ), TRUE );
}

HB_FUNC( HWG_GETDLGITEM )
{
   HWND hWnd = GetDlgItem( ( HWND ) HB_PARHANDLE( 1 ),  // handle of dialog box
         hb_parni( 2 )          // identifier of control
          );
   HB_RETHANDLE( hWnd );
}

HB_FUNC( HWG_GETDLGCTRLID )
{
   hb_retni( GetDlgCtrlID( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_SETDLGITEMTEXT )
{
   void *hText;

   SetDlgItemText( ( HWND ) HB_PARHANDLE( 1 ),  // handle of dialog box
         hb_parni( 2 ),         // identifier of control
         HB_PARSTR( 3, &hText, NULL )   // text to set
          );
   hb_strfree( hText );
}

HB_FUNC( HWG_SETDLGITEMINT )
{
   SetDlgItemInt( ( HWND ) HB_PARHANDLE( 1 ),   // handle of dialog box
         hb_parni( 2 ),         // identifier of control
         ( UINT ) hb_parni( 3 ),        // text to set
         ( hb_pcount(  ) < 4 || HB_ISNIL( 4 ) || !hb_parl( 4 ) ) ? 0 : 1 );
}

HB_FUNC( HWG_GETDLGITEMTEXT )
{
   USHORT uiLen = hb_parni( 3 );
   LPTSTR lpText = ( LPTSTR ) hb_xgrab( ( uiLen + 1 ) * sizeof( TCHAR ) );

   GetDlgItemText( ( HWND ) HB_PARHANDLE( 1 ),  // handle of dialog box
         hb_parni( 2 ),         // identifier of control
         lpText,                // address of buffer for text
         uiLen                  // maximum size of string
          );
   HB_RETSTR( lpText );
   hb_xfree( lpText );
}

HB_FUNC( HWG_GETEDITTEXT )
{
   HWND hDlg = ( HWND ) HB_PARHANDLE( 1 );
   int id = hb_parni( 2 );
   USHORT uiLen =
         ( USHORT ) SendMessage( GetDlgItem( hDlg, id ), WM_GETTEXTLENGTH, 0,
         0 );
   LPTSTR lpText = ( LPTSTR ) hb_xgrab( ( uiLen + 2 ) * sizeof( TCHAR ) );

   GetDlgItemText( hDlg,        // handle of dialog box
         id,                    // identifier of control
         lpText,                // address of buffer for text
         uiLen + 1              // maximum size of string
          );
   HB_RETSTR( lpText );
   hb_xfree( lpText );
}

HB_FUNC( HWG_CHECKDLGBUTTON )
{
   CheckDlgButton( ( HWND ) HB_PARHANDLE( 1 ),  // handle of dialog box
         hb_parni( 2 ),         // identifier of control
         ( hb_parl( 3 ) ) ? BST_CHECKED : BST_UNCHECKED // value to set
          );
}

HB_FUNC( HWG_CHECKRADIOBUTTON )
{
   CheckRadioButton( ( HWND ) HB_PARHANDLE( 1 ),        // handle of dialog box
         hb_parni( 2 ),         // identifier of first radio button in group
         hb_parni( 3 ),         // identifier of last radio button in group
         hb_parni( 4 )          // identifier of radio button to select
          );
}

HB_FUNC( HWG_ISDLGBUTTONCHECKED )
{
   UINT nRes = IsDlgButtonChecked( ( HWND ) HB_PARHANDLE( 1 ),  // handle of dialog box
         hb_parni( 2 )          // button identifier
          );
   hb_retl( nRes == BST_CHECKED );
}

HB_FUNC( HWG_COMBOADDSTRING )
{
   void *hText;

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), CB_ADDSTRING, 0,
         ( LPARAM ) HB_PARSTR( 2, &hText, NULL ) );
   hb_strfree( hText );
}

HB_FUNC( HWG_COMBOINSERTSTRING )
{
   void *hText;

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), CB_INSERTSTRING,
         ( WPARAM ) hb_parni( 2 ), ( LPARAM ) HB_PARSTR( 3, &hText, NULL ) );
   hb_strfree( hText );
}


HB_FUNC( HWG_COMBOSETSTRING )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), CB_SETCURSEL,
         ( WPARAM ) hb_parni( 2 ) - 1, 0 );
}

HB_FUNC( HWG_GETNOTIFYCODE )
{
   hb_retnl( ( LONG ) ( ( ( NMHDR * ) HB_PARHANDLE( 1 ) )->code ) );
}


/*
   Support Ticket #55 (October 2022):
   GCC >= 11 uses full 64 bit pointer,
   otherwise program crashes.
   
   Helper routine.
   Take an input pointer, return closest
*  pointer that is aligned on a DWORD (4 byte) boundary.
*/
static LPWORD s_lpwAlign( LPWORD lpIn )
{

#if defined(__GNUC__) && (__GNUC__ >= 11)
   ULONGLONG ul;
   ul = ( ULONGLONG ) lpIn;
#else
   ULONG ul;
   ul = ( ULONG ) lpIn;   
#endif
   ul += 3;
   ul >>= 2;
   ul <<= 2;
   return ( LPWORD ) ul;
}


static HB_SIZE s_nCopyAnsiToWideChar( LPWORD lpWCStr, PHB_ITEM pItem,
      HB_SIZE size )
{
#if defined( HB_HAS_STR_FUNC )
   return hb_itemCopyStrU16( pItem, HB_CDP_ENDIAN_NATIVE,
         ( HB_WCHAR * ) lpWCStr, size ) + 1;
#else
   return MultiByteToWideChar( GetACP(  ), 0, hb_itemGetCPtr( pItem ), -1,
         ( LPWSTR ) lpWCStr, size );
#endif
}

static int s_nWideStringLen( PHB_ITEM pItem )
{
#if defined( HB_HAS_STR_FUNC )
   return hb_itemCopyStrU16( pItem, HB_CDP_ENDIAN_NATIVE, NULL, 0 ) + 1;
#else
   return MultiByteToWideChar( GetACP(  ), 0, hb_itemGetCPtr( pItem ), -1,
         NULL, 0 );
#endif
}

static LPDLGTEMPLATE s_CreateDlgTemplate( PHB_ITEM pObj, int x1, int y1,
      int dwidth, int dheight, ULONG ulStyle )
{
   HGLOBAL hgbl;
   PWORD p, pend;
   PHB_ITEM pControls, pControl, temp;
   LONG baseUnit = GetDialogBaseUnits(  );
   int baseunitX = LOWORD( baseUnit ), baseunitY = HIWORD( baseUnit );
   long lTemplateSize = 15;
   LONG lExtStyle;
   ULONG ul, ulControls;

   x1 = ( x1 * 4 ) / baseunitX;
   dwidth = ( dwidth * 4 ) / baseunitX;
   y1 = ( y1 * 8 ) / baseunitY;
   dheight = ( dheight * 8 ) / baseunitY;

   /* clear styles which needs different dialog template */
   ulStyle &= ~( DS_SETFONT | DS_SHELLFONT );

   pControls = hb_itemNew( GetObjectVar( pObj, "ACONTROLS" ) );
   ulControls = hb_arrayLen( pControls );

   lTemplateSize += s_nWideStringLen( GetObjectVar( pObj, "TITLE" ) );
   lTemplateSize += lTemplateSize & 1;

   for( ul = 1; ul <= ulControls; ul++ )
   {
      pControl = hb_arrayGetItemPtr( pControls, ul );
      lTemplateSize += 13;
      lTemplateSize +=
            s_nWideStringLen( GetObjectVar( pControl, "WINCLASS" ) );
      lTemplateSize += s_nWideStringLen( GetObjectVar( pControl, "TITLE" ) );
      lTemplateSize += lTemplateSize & 1;
   }
   lTemplateSize += 2;          /* 2 to keep DWORD boundary block size */

   hgbl = GlobalAlloc( GMEM_ZEROINIT, lTemplateSize * sizeof( WORD ) );
   if( !hgbl )
      return NULL;

   p = ( PWORD ) GlobalLock( hgbl );
   pend = p + lTemplateSize;

   *p++ = 1;                    // DlgVer
   *p++ = 0xFFFF;               // Signature
   *p++ = 0;                    // LOWORD HelpID
   *p++ = 0;                    // HIWORD HelpID
   *p++ = 0;                    // LOWORD (lExtendedStyle)
   *p++ = 0;                    // HIWORD (lExtendedStyle)
   *p++ = LOWORD( ulStyle );
   *p++ = HIWORD( ulStyle );
   *p++ = ( UINT ) ulControls;  // NumberOfItems
   *p++ = x1;                   // x
   *p++ = y1;                   // y
   *p++ = dwidth;               // cx
   *p++ = dheight;              // cy
   *p++ = 0;                    // Menu
   *p++ = 0;                    // Class

   // Copy the title of the dialog box.
   p += s_nCopyAnsiToWideChar( p, GetObjectVar( pObj, "TITLE" ), pend - p );

   for( ul = 1; ul <= ulControls; ul++ )
   {
      pControl = hb_arrayGetItemPtr( pControls, ul );

      temp = HB_PUTHANDLE( NULL, -1 );
      SetObjectVar( pControl, "_HANDLE", temp );
      hb_itemRelease( temp );

      p = s_lpwAlign( p );

      ulStyle = ( ULONG ) hb_itemGetNL( GetObjectVar( pControl, "STYLE" ) );
      lExtStyle = hb_itemGetNL( GetObjectVar( pControl, "EXTSTYLE" ) );
      x1 = ( hb_itemGetNI( GetObjectVar( pControl,
                        "NLEFT" ) ) * 4 ) / baseunitX;
      dwidth =
            ( hb_itemGetNI( GetObjectVar( pControl,
                        "NWIDTH" ) ) * 4 ) / baseunitX;
      y1 = ( hb_itemGetNI( GetObjectVar( pControl,
                        "NTOP" ) ) * 8 ) / baseunitY;
      dheight =
            ( hb_itemGetNI( GetObjectVar( pControl,
                        "NHEIGHT" ) ) * 8 ) / baseunitY;

      *p++ = 0;                 // LOWORD (lHelpID)
      *p++ = 0;                 // HIWORD (lHelpID)
      *p++ = LOWORD( lExtStyle );       // LOWORD (lExtendedStyle)
      *p++ = HIWORD( lExtStyle );       // HIWORD (lExtendedStyle)
      *p++ = LOWORD( ulStyle );
      *p++ = HIWORD( ulStyle );
      *p++ = x1;                // x
      *p++ = y1;                // y
      *p++ = dwidth;            // cx
      *p++ = dheight;           // cy
      *p++ = hb_itemGetNI( GetObjectVar( pControl, "ID" ) );    // LOWORD (Control ID)
      *p++ = 0;                 // HOWORD (Control ID)

      // class name
      p += s_nCopyAnsiToWideChar( p, GetObjectVar( pControl, "WINCLASS" ),
            pend - p );

      // Caption
      p += s_nCopyAnsiToWideChar( p, GetObjectVar( pControl, "TITLE" ),
            pend - p );

      *p++ = 0;                 // Advance pointer over nExtraStuff WORD.
   }

   p = s_lpwAlign( p );
   *p = 0;                      // Number of bytes of extra data.

   hb_itemRelease( pControls );

   GlobalUnlock( hgbl );

   return ( LPDLGTEMPLATE ) hgbl;
}

static void s_ReleaseDlgTemplate( LPDLGTEMPLATE pdlgtemplate )
{
   GlobalFree( ( HGLOBAL ) pdlgtemplate );
}

HB_FUNC( HWG_CREATEDLGTEMPLATE )
{
   hb_retnl( ( LONG ) s_CreateDlgTemplate( hb_param( 1, HB_IT_OBJECT ),
               hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ),
               ( ULONG ) hb_parnd( 6 ) ) );
}

HB_FUNC( HWG_RELEASEDLGTEMPLATE )
{
   s_ReleaseDlgTemplate( ( LPDLGTEMPLATE ) hb_parnl( 1 ) );
}

/* ~~~~~~~~~~~~~~~ Property sheets ~~~~~~~~~~~~~~~~~~~~~~~~~ */
/* Test them with
   samples\propsh.prg
*/   

/*
 * Creates a single property sheet 
 *
 *  _CreatePropertySheetPage( aDlg, x1, y1, nWidth, nHeight, nStyle ) --> hPage
 */
HB_FUNC( HWG__CREATEPROPERTYSHEETPAGE )
{
   PROPSHEETPAGE psp;
   PHB_ITEM pObj = hb_param( 1, HB_IT_OBJECT ), temp;
   void *hTitle = NULL;
   LPDLGTEMPLATE pdlgtemplate;
   HPROPSHEETPAGE h;

   memset( ( void * ) &psp, 0, sizeof( PROPSHEETPAGE ) );

   psp.dwSize = sizeof( PROPSHEETPAGE );
   psp.hInstance = ( HINSTANCE ) NULL; 
   psp.pszTitle = NULL;
   psp.pfnDlgProc = ( DLGPROC ) s_PSPProc;
   psp.lParam = ( LPARAM ) hb_itemNew( pObj );
   psp.pfnCallback = ( LPFNPSPCALLBACK ) s_PSPProcRelease;
   psp.pcRefParent = 0;
   /* Added by DF7BE */
   psp.dwFlags = PSP_DLGINDIRECT | PSP_USECALLBACK;
   

#if !defined(__BORLANDC__) ||  (__BORLANDC__ > 1424)
   psp.hIcon = 0;
#else
   psp.DUMMYUNIONNAME2.hIcon = 0;
#endif

   if( hb_itemGetNI( GetObjectVar( pObj, "TYPE" ) ) == WND_DLG_RESOURCE )
   {
      LPCTSTR lpTitle;

      psp.dwFlags = 0 | PSP_USECALLBACK;

      temp = GetObjectVar( pObj, "XRESOURCEID" );
      if( HB_IS_STRING( temp ) )
         lpTitle = HB_ITEMGETSTR( temp, &hTitle, NULL );
      else if( HB_IS_NUMERIC( temp ) )
         lpTitle = MAKEINTRESOURCE( hb_itemGetNL( temp ) );
      else
         lpTitle = NULL;
#if !defined(__BORLANDC__) ||  (__BORLANDC__ > 1424)
      psp.pszTemplate = lpTitle;
#else
      psp.DUMMYUNIONNAME.pszTemplate = lpTitle;
#endif
   }
   else
   {
      pdlgtemplate = ( LPDLGTEMPLATE ) hb_parnl( 2 );

      psp.dwFlags = PSP_DLGINDIRECT | PSP_USECALLBACK;
#if !defined(__BORLANDC__) ||  (__BORLANDC__ > 1424)
      psp.pResource = pdlgtemplate;
#else
      psp.DUMMYUNIONNAME.pResource = pdlgtemplate;
#endif
   }

   h = CreatePropertySheetPage( &psp );
   HB_RETHANDLE( h );
   //if( pdlgtemplate )
   //   s_ReleaseDlgTemplate( pdlgtemplate );
   hb_strfree( hTitle );
}

/*
 * _PropertySheet( hWndParent, aPageHandles, nPageHandles, cTitle, 
 *                [ lModeless ], [ lNoApply ], [ lWizard ] ) --> hPropertySheet
 */
HB_FUNC( HWG__PROPERTYSHEET )
{
   PHB_ITEM pArr = hb_param( 2, HB_IT_ARRAY );
   int nPages = hb_parni( 3 ), i;
   HPROPSHEETPAGE psp[10];
   PROPSHEETHEADER psh;
   void *hCaption;
   DWORD dwFlags = ( hb_pcount(  ) < 5 || HB_ISNIL( 5 ) ||
         !hb_parl( 5 ) ) ? 0 : PSH_MODELESS;

   if( hb_pcount(  ) > 5 && !HB_ISNIL( 6 ) && hb_parl( 6 ) )
      dwFlags |= PSH_NOAPPLYNOW;
   if( hb_pcount(  ) > 6 && !HB_ISNIL( 7 ) && hb_parl( 7 ) )
      dwFlags |= PSH_WIZARD;
   for( i = 0; i < nPages; i++ )
      psp[i] = ( HPROPSHEETPAGE ) hb_arrayGetNL( pArr, i + 1 );

   psh.dwSize = sizeof( PROPSHEETHEADER );
   psh.dwFlags = dwFlags;
   psh.hwndParent = ( HWND ) HB_PARHANDLE( 1 );
   psh.hInstance = ( HINSTANCE ) NULL;
#if !defined(__BORLANDC__) ||  (__BORLANDC__ > 1424)
   psh.pszIcon = NULL;
#else
   psh.DUMMYUNIONNAME.pszIcon = NULL;
#endif
   psh.pszCaption = HB_PARSTR( 4, &hCaption, NULL );
   psh.nPages = nPages;
#if !defined(__BORLANDC__)||  (__BORLANDC__ > 1424)
   psh.nStartPage = 0;
   psh.phpage = psp;
#else
   psh.DUMMYUNIONNAME2.nStartPage = 0;
   psh.DUMMYUNIONNAME3.phpage = psp;
#endif
   psh.pfnCallback = NULL;

   HB_RETHANDLE( PropertySheet( &psh ) );
   hb_strfree( hCaption );
}

/* Hwg_CreateDlgIndirect( hParentWnd, pArray, x1, y1, nWidth, nHeight, nStyle )
*/

HB_FUNC( HWG_CREATEDLGINDIRECT )
{
   LPDLGTEMPLATE pdlgtemplate;
   PHB_ITEM pObject = hb_param( 2, HB_IT_OBJECT );
   BOOL fFree = FALSE;

   if( hb_pcount(  ) > 7 && !HB_ISNIL( 8 ) )
      pdlgtemplate = ( LPDLGTEMPLATE ) hb_parnl( 8 );
   else
   {
      ULONG ulStyle = ( ( hb_pcount(  ) > 6 && !HB_ISNIL( 7 ) ) ? ( ULONG ) hb_parnd( 7 ) : WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU | WS_SIZEBOX );     // | DS_SETFONT;

      pdlgtemplate =
            s_CreateDlgTemplate( pObject, hb_parni( 3 ), hb_parni( 4 ),
            hb_parni( 5 ), hb_parni( 6 ), ulStyle );
      fFree = TRUE;
   }

   CreateDialogIndirectParam( hModule, pdlgtemplate,
         ( HWND ) HB_PARHANDLE( 1 ), ( DLGPROC ) s_DlgProc,
         ( LPARAM ) pObject );

   if( fFree )
      s_ReleaseDlgTemplate( pdlgtemplate );
}

/* Hwg_DlgBoxIndirect( hParentWnd, pArray, x1, y1, nWidth, nHeight, nStyle )
*/

HB_FUNC( HWG_DLGBOXINDIRECT )
{
   PHB_ITEM pObject = hb_param( 2, HB_IT_OBJECT );
   ULONG ulStyle = ( ( hb_pcount(  ) > 6 && !HB_ISNIL( 7 ) ) ? ( ULONG ) hb_parnd( 7 ) : WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU );     // | DS_SETFONT;
   int x1 = hb_parni( 3 ), y1 = hb_parni( 4 ),
         dwidth = hb_parni( 5 ), dheight = hb_parni( 6 );
   LPDLGTEMPLATE pdlgtemplate =
         s_CreateDlgTemplate( pObject, x1, y1, dwidth, dheight, ulStyle );

   DialogBoxIndirectParam( hModule, pdlgtemplate,
         ( HWND ) HB_PARHANDLE( 1 ), ( DLGPROC ) s_ModalDlgProc,
         ( LPARAM ) pObject );
   s_ReleaseDlgTemplate( pdlgtemplate );
}

HB_FUNC( HWG_DIALOGBASEUNITS )
{
   hb_retnl( GetDialogBaseUnits(  ) );
}

static LRESULT CALLBACK s_ModalDlgProc( HWND hDlg, UINT uMsg, WPARAM wParam,
      LPARAM lParam )
{
   // PHB_DYNS pSymTest;
   long int res;
   PHB_ITEM pObject;

   if( uMsg == WM_INITDIALOG )
   {
      PHB_ITEM temp;

      temp = hb_itemPutNL( NULL, 1 );
      SetObjectVar( ( PHB_ITEM ) lParam, "_NHOLDER", temp );
      hb_itemRelease( temp );

      temp = HB_PUTHANDLE( NULL, hDlg );
      SetObjectVar( ( PHB_ITEM ) lParam, "_HANDLE", temp );
      hb_itemRelease( temp );

      SetWindowObject( hDlg, ( PHB_ITEM ) lParam );
   }
   pObject = ( PHB_ITEM ) GetWindowLongPtr( hDlg, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) uMsg );
//      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG )  lParam );
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return (LRESULT) HB_PARHANDLE( -1 );
      else
      {
         res = hb_parnl( -1 );
         if( res == -1 )
            return FALSE;
         else
            return res;
      }
   }
   else
      return FALSE;

}

static LRESULT CALLBACK s_DlgProc( HWND hDlg, UINT uMsg, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject;

   if( uMsg == WM_INITDIALOG )
   {
      PHB_ITEM temp;

      temp = hb_itemPutNL( NULL, 1 );
      SetObjectVar( ( PHB_ITEM ) lParam, "_NHOLDER", temp );
      hb_itemRelease( temp );

      temp = HB_PUTHANDLE( NULL, hDlg );
      SetObjectVar( ( PHB_ITEM ) lParam, "_HANDLE", temp );
      hb_itemRelease( temp );

      SetWindowObject( hDlg, ( PHB_ITEM ) lParam );

      if( iDialogs == s_nDialogs )
      {
         s_nDialogs += 16;
         if( s_nDialogs == 16 )
            aDialogs = ( HWND * ) hb_xgrab( sizeof( HWND ) * s_nDialogs );
         else
            aDialogs =
                  ( HWND * ) hb_xrealloc( aDialogs,
                  sizeof( HWND ) * s_nDialogs );
      }
      aDialogs[iDialogs++] = hDlg;
   }
   else if( uMsg == WM_DESTROY )
   {
      int i;
      for( i = 0; i < iDialogs; i++ )
         if( aDialogs[i] == hDlg )
            break;
      iDialogs--;
      for( ; i < iDialogs; i++ )
         aDialogs[i] = aDialogs[i + 1];
   }

   pObject = ( PHB_ITEM ) GetWindowLongPtr( hDlg, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) uMsg );
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
            return FALSE;
         else
            return res;
      }
   }
   else
      return FALSE;

}

static LRESULT CALLBACK s_PSPProc( HWND hDlg, UINT uMsg, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject;

   if( uMsg == WM_INITDIALOG )
   {
      PHB_ITEM pObj, temp;

      pObj = ( PHB_ITEM ) ( ( ( PROPSHEETPAGE * ) lParam )->lParam );

      temp = hb_itemPutNL( NULL, 1 );
      SetObjectVar( pObj, "_NHOLDER", temp );
      hb_itemRelease( temp );

      temp = HB_PUTHANDLE( NULL, hDlg );
      SetObjectVar( pObj, "_HANDLE", temp );
      hb_itemRelease( temp );

      SetWindowObject( hDlg, pObj );

      if( iDialogs == s_nDialogs )
      {
         s_nDialogs += 16;
         if( s_nDialogs == 16 )
            aDialogs = ( HWND * ) hb_xgrab( sizeof( HWND ) * s_nDialogs );
         else
            aDialogs =
                  ( HWND * ) hb_xrealloc( aDialogs,
                  sizeof( HWND ) * s_nDialogs );
      }
      aDialogs[iDialogs++] = hDlg;
      // hb_itemRelease( pObj );
   }
   else if( uMsg == WM_NOTIFY )
      uMsg = WM_PSPNOTIFY;
   else if( uMsg == WM_DESTROY )
   {
      int i;
      for( i = 0; i < iDialogs; i++ )
         if( aDialogs[i] == hDlg )
            break;
      iDialogs--;
      for( ; i < iDialogs; i++ )
         aDialogs[i] = aDialogs[i + 1];
   }

   pObject = ( PHB_ITEM ) GetWindowLongPtr( hDlg, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) uMsg );
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
            return FALSE;
         else
            return res;
      }
   }
   else
      return FALSE;

}

static LRESULT CALLBACK s_PSPProcRelease( HWND hwnd, UINT uMsg,
      LPPROPSHEETPAGE ppsp )
{
   HB_SYMBOL_UNUSED( hwnd );
   if( PSPCB_CREATE == uMsg )
   {
      return 1;
   }
   if( PSPCB_RELEASE == uMsg )
   {
      hb_itemRelease( ( PHB_ITEM ) ppsp->lParam );
   }

   return 0;
}

HB_FUNC( HWG_GETNOTIFYCODEFROM )
{
   HB_RETHANDLE( ( ( ( NMHDR * ) HB_PARHANDLE( 1 ) )->hwndFrom ) );
}

HB_FUNC( HWG_GETNOTIFYIDFROM )
{
   hb_retnl( ( LONG ) ( ( ( NMHDR * ) HB_PARHANDLE( 1 ) )->idFrom ) );
}

/* ========================== EOF of dialog.c ====================== */

