/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * ActiveX container
 *
 * Original author - Jeff Glatt
 * Modified for using with HwGUI by Alexander S.Kresin <alex@kresin.ru>
 * www - http://kresin.ru
 *
 * ======================================================================
 * 2026-09-07: Refactored for 64-bit safety, memory management consistency,
 *             and compiler warning suppression. Replaced GlobalAlloc/GlobalFree
 *             with hb_xgrab/hb_xfree for custom COM structures; fixed pointer
 *             truncation in SetEmbedded/GetEmbedded by using hb_itemPutPtr/
 *             hb_itemGetPtr; now uses GetWindowLongPtr/SetWindowLongPtr
 *             unconditionally; added HB_SYMBOL_UNUSED and error checks.
 * ======================================================================
 */

#include <windows.h>
#include <tchar.h>
#include "htmlcore.h"

/* Suppress warnings for GCC/Clang */
#if defined(__GNUC__) && !defined(__INTEL_COMPILER) && !defined(__clang__)
#pragma GCC diagnostic ignored "-Wpragmas"
#pragma GCC diagnostic ignored "-Wsign-compare"
#endif

/* Borland C++ specific VARIANT field names */
#if !defined(__BORLANDC__)
#define DEF_VT  vt
#define DEF_BSTRVAL  bstrVal
#define DEF_PDISPVAL  pdispVal
#define DEF_BOOLVAL  boolVal
#define DEF_LVAL  lVal
#else
#define DEF_VT  n1.n2.vt
#define DEF_BSTRVAL  n1.n2.n3.bstrVal
#define DEF_PDISPVAL  n1.n2.n3.pdispVal
#define DEF_BOOLVAL  n1.n2.n3.boolVal
#define DEF_LVAL  n1.n2.n3.lVal
#endif

/* ============================== SHARED DATA ============================== */
static const wchar_t AppUrl[] = { L"app:" };
static const wchar_t Blank[] = { L"about:blank" };
static const SAFEARRAYBOUND ArrayBound = { 1, 0 };

static unsigned char _IID_IHTMLWindow3[] =
      { 0xae, 0xf4, 0x50, 0x30, 0xb5, 0x98, 0xcf, 0x11, 0xbb, 0x82, 0x00,
         0xaa, 0x00, 0xbd, 0xce, 0x0b };

unsigned char COM_init = 0;

/* ============================== FORWARD DECLARATIONS ============================== */
/* IOleInPlaceFrame functions */
HRESULT STDMETHODCALLTYPE Frame_QueryInterface( IOleInPlaceFrame *, REFIID, LPVOID * );
ULONG STDMETHODCALLTYPE Frame_AddRef( IOleInPlaceFrame * );
ULONG STDMETHODCALLTYPE Frame_Release( IOleInPlaceFrame * );
HRESULT STDMETHODCALLTYPE Frame_GetWindow( IOleInPlaceFrame *, HWND * );
HRESULT STDMETHODCALLTYPE Frame_ContextSensitiveHelp( IOleInPlaceFrame *, BOOL );
HRESULT STDMETHODCALLTYPE Frame_GetBorder( IOleInPlaceFrame *, LPRECT );
HRESULT STDMETHODCALLTYPE Frame_RequestBorderSpace( IOleInPlaceFrame *, LPCBORDERWIDTHS );
HRESULT STDMETHODCALLTYPE Frame_SetBorderSpace( IOleInPlaceFrame *, LPCBORDERWIDTHS );
HRESULT STDMETHODCALLTYPE Frame_SetActiveObject( IOleInPlaceFrame *, IOleInPlaceActiveObject *, LPCOLESTR );
HRESULT STDMETHODCALLTYPE Frame_InsertMenus( IOleInPlaceFrame *, HMENU, LPOLEMENUGROUPWIDTHS );
HRESULT STDMETHODCALLTYPE Frame_SetMenu( IOleInPlaceFrame *, HMENU, HOLEMENU, HWND );
HRESULT STDMETHODCALLTYPE Frame_RemoveMenus( IOleInPlaceFrame *, HMENU );
HRESULT STDMETHODCALLTYPE Frame_SetStatusText( IOleInPlaceFrame *, LPCOLESTR );
HRESULT STDMETHODCALLTYPE Frame_EnableModeless( IOleInPlaceFrame *, BOOL );
HRESULT STDMETHODCALLTYPE Frame_TranslateAccelerator( IOleInPlaceFrame *, LPMSG, WORD );

/* IOleClientSite functions */
HRESULT STDMETHODCALLTYPE Site_QueryInterface( IOleClientSite *, REFIID, void ** );
ULONG STDMETHODCALLTYPE Site_AddRef( IOleClientSite * );
ULONG STDMETHODCALLTYPE Site_Release( IOleClientSite * );
HRESULT STDMETHODCALLTYPE Site_SaveObject( IOleClientSite * );
HRESULT STDMETHODCALLTYPE Site_GetMoniker( IOleClientSite *, DWORD, DWORD, IMoniker ** );
HRESULT STDMETHODCALLTYPE Site_GetContainer( IOleClientSite *, LPOLECONTAINER * );
HRESULT STDMETHODCALLTYPE Site_ShowObject( IOleClientSite * );
HRESULT STDMETHODCALLTYPE Site_OnShowWindow( IOleClientSite *, BOOL );
HRESULT STDMETHODCALLTYPE Site_RequestNewObjectLayout( IOleClientSite * );

/* IDocHostUIHandler functions */
HRESULT STDMETHODCALLTYPE UI_QueryInterface( IDocHostUIHandler *, REFIID, void ** );
ULONG STDMETHODCALLTYPE UI_AddRef( IDocHostUIHandler * );
ULONG STDMETHODCALLTYPE UI_Release( IDocHostUIHandler * );
HRESULT STDMETHODCALLTYPE UI_ShowContextMenu( IDocHostUIHandler *, DWORD, POINT *, IUnknown *, IDispatch * );
HRESULT STDMETHODCALLTYPE UI_GetHostInfo( IDocHostUIHandler *, DOCHOSTUIINFO * );
HRESULT STDMETHODCALLTYPE UI_ShowUI( IDocHostUIHandler *, DWORD, IOleInPlaceActiveObject *, IOleCommandTarget *, IOleInPlaceFrame *, IOleInPlaceUIWindow * );
HRESULT STDMETHODCALLTYPE UI_HideUI( IDocHostUIHandler * );
HRESULT STDMETHODCALLTYPE UI_UpdateUI( IDocHostUIHandler * );
HRESULT STDMETHODCALLTYPE UI_EnableModeless( IDocHostUIHandler *, BOOL );
HRESULT STDMETHODCALLTYPE UI_OnDocWindowActivate( IDocHostUIHandler *, BOOL );
HRESULT STDMETHODCALLTYPE UI_OnFrameWindowActivate( IDocHostUIHandler *, BOOL );
HRESULT STDMETHODCALLTYPE UI_ResizeBorder( IDocHostUIHandler *, LPCRECT, IOleInPlaceUIWindow *, BOOL );
HRESULT STDMETHODCALLTYPE UI_TranslateAccelerator( IDocHostUIHandler *, LPMSG, const GUID *, DWORD );
HRESULT STDMETHODCALLTYPE UI_GetOptionKeyPath( IDocHostUIHandler *, LPOLESTR *, DWORD );
HRESULT STDMETHODCALLTYPE UI_GetDropTarget( IDocHostUIHandler *, IDropTarget *, IDropTarget ** );
HRESULT STDMETHODCALLTYPE UI_GetExternal( IDocHostUIHandler *, IDispatch ** );
HRESULT STDMETHODCALLTYPE UI_TranslateUrl( IDocHostUIHandler *, DWORD, OLECHAR *, OLECHAR ** );
HRESULT STDMETHODCALLTYPE UI_FilterDataObject( IDocHostUIHandler *, IDataObject *, IDataObject ** );

/* IOleInPlaceSite functions */
HRESULT STDMETHODCALLTYPE InPlace_QueryInterface( IOleInPlaceSite *, REFIID, void ** );
ULONG STDMETHODCALLTYPE InPlace_AddRef( IOleInPlaceSite * );
ULONG STDMETHODCALLTYPE InPlace_Release( IOleInPlaceSite * );
HRESULT STDMETHODCALLTYPE InPlace_GetWindow( IOleInPlaceSite *, HWND * );
HRESULT STDMETHODCALLTYPE InPlace_ContextSensitiveHelp( IOleInPlaceSite *, BOOL );
HRESULT STDMETHODCALLTYPE InPlace_CanInPlaceActivate( IOleInPlaceSite * );
HRESULT STDMETHODCALLTYPE InPlace_OnInPlaceActivate( IOleInPlaceSite * );
HRESULT STDMETHODCALLTYPE InPlace_OnUIActivate( IOleInPlaceSite * );
HRESULT STDMETHODCALLTYPE InPlace_GetWindowContext( IOleInPlaceSite *, LPOLEINPLACEFRAME *, LPOLEINPLACEUIWINDOW *, LPRECT, LPRECT, LPOLEINPLACEFRAMEINFO );
HRESULT STDMETHODCALLTYPE InPlace_Scroll( IOleInPlaceSite *, SIZE );
HRESULT STDMETHODCALLTYPE InPlace_OnUIDeactivate( IOleInPlaceSite *, BOOL );
HRESULT STDMETHODCALLTYPE InPlace_OnInPlaceDeactivate( IOleInPlaceSite * );
HRESULT STDMETHODCALLTYPE InPlace_DiscardUndoState( IOleInPlaceSite * );
HRESULT STDMETHODCALLTYPE InPlace_DeactivateAndUndo( IOleInPlaceSite * );
HRESULT STDMETHODCALLTYPE InPlace_OnPosRectChange( IOleInPlaceSite *, LPCRECT );

/* IDispatch functions (event sink) */
HRESULT STDMETHODCALLTYPE Dispatch_QueryInterface( IDispatch *, REFIID, void ** );
ULONG STDMETHODCALLTYPE Dispatch_AddRef( IDispatch * );
ULONG STDMETHODCALLTYPE Dispatch_Release( IDispatch * );
HRESULT STDMETHODCALLTYPE Dispatch_GetTypeInfoCount( IDispatch *, unsigned int * );
HRESULT STDMETHODCALLTYPE Dispatch_GetTypeInfo( IDispatch *, unsigned int, LCID, ITypeInfo ** );
HRESULT STDMETHODCALLTYPE Dispatch_GetIDsOfNames( IDispatch *, REFIID, OLECHAR **, unsigned int, LCID, DISPID * );
HRESULT STDMETHODCALLTYPE Dispatch_Invoke( IDispatch *, DISPID, REFIID, LCID, WORD, DISPPARAMS *, VARIANT *, EXCEPINFO *, unsigned int * );

/* ============================== VTABLE DEFINITIONS ============================== */

static IOleInPlaceFrameVtbl MyIOleInPlaceFrameTable = {
   Frame_QueryInterface,
   Frame_AddRef,
   Frame_Release,
   Frame_GetWindow,
   Frame_ContextSensitiveHelp,
   Frame_GetBorder,
   Frame_RequestBorderSpace,
   Frame_SetBorderSpace,
   Frame_SetActiveObject,
   Frame_InsertMenus,
   Frame_SetMenu,
   Frame_RemoveMenus,
   Frame_SetStatusText,
   Frame_EnableModeless,
   Frame_TranslateAccelerator
};

static IOleClientSiteVtbl MyIOleClientSiteTable = {
   Site_QueryInterface,
   Site_AddRef,
   Site_Release,
   Site_SaveObject,
   Site_GetMoniker,
   Site_GetContainer,
   Site_ShowObject,
   Site_OnShowWindow,
   Site_RequestNewObjectLayout
};

static IDocHostUIHandlerVtbl MyIDocHostUIHandlerTable = {
   UI_QueryInterface,
   UI_AddRef,
   UI_Release,
   UI_ShowContextMenu,
   UI_GetHostInfo,
   UI_ShowUI,
   UI_HideUI,
   UI_UpdateUI,
   UI_EnableModeless,
   UI_OnDocWindowActivate,
   UI_OnFrameWindowActivate,
   UI_ResizeBorder,
   UI_TranslateAccelerator,
   UI_GetOptionKeyPath,
   UI_GetDropTarget,
   UI_GetExternal,
   UI_TranslateUrl,
   UI_FilterDataObject
};

static IOleInPlaceSiteVtbl MyIOleInPlaceSiteTable = {
   InPlace_QueryInterface,
   InPlace_AddRef,
   InPlace_Release,
   InPlace_GetWindow,
   InPlace_ContextSensitiveHelp,
   InPlace_CanInPlaceActivate,
   InPlace_OnInPlaceActivate,
   InPlace_OnUIActivate,
   InPlace_GetWindowContext,
   InPlace_Scroll,
   InPlace_OnUIDeactivate,
   InPlace_OnInPlaceDeactivate,
   InPlace_DiscardUndoState,
   InPlace_DeactivateAndUndo,
   InPlace_OnPosRectChange
};

static IDispatchVtbl MyIDispatchVtbl = {
   Dispatch_QueryInterface,
   Dispatch_AddRef,
   Dispatch_Release,
   Dispatch_GetTypeInfoCount,
   Dispatch_GetTypeInfo,
   Dispatch_GetIDsOfNames,
   Dispatch_Invoke
};

/* ============================== CUSTOM STRUCTURES (internal) ============================== */

/* Extended IOleInPlaceFrame with extra data (HWND) */
typedef struct
{
   IOleInPlaceFrame frame;
   HWND window;
} _IOleInPlaceFrameEx;

/* Extended IOleInPlaceSite with extra data (frame) */
typedef struct
{
   IOleInPlaceSite inplace;
   _IOleInPlaceFrameEx frame;
} _IOleInPlaceSiteEx;

/* Extended IDocHostUIHandler (no extra data) */
typedef struct
{
   IDocHostUIHandler ui;
} _IDocHostUIHandlerEx;

/* Extended IOleClientSite containing all above */
typedef struct
{
   IOleClientSite client;
   _IOleInPlaceSiteEx inplace;
   _IDocHostUIHandlerEx ui;
} _IOleClientSiteEx;

/* ============================== HARBOUR INTEGRATION ============================== */

#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"

PHB_ITEM GetObjectVar( PHB_ITEM pObject, char *varname );
void SetObjectVar( PHB_ITEM pObject, char *varname, PHB_ITEM pValue );
extern void writelog( char *s );

/*
 * SetEmbedded - Stores the IOleObject* pointer in the Harbour object associated
 * with the given window handle. This replaces the original code that used
 * GWL_USERDATA directly.
 */
void SetEmbedded( HWND handle, IOleObject ** obj )
{
   PHB_ITEM pObject, pEmbed, temp;
   pObject = ( PHB_ITEM ) GetWindowLongPtr( handle, GWLP_USERDATA );
   if( !pObject ) return;
   pEmbed = hb_itemNew( GetObjectVar( pObject, "OEMBEDDED" ) );
   temp = hb_itemPutPtr( NULL, obj );
   SetObjectVar( pEmbed, "_HANDLE", temp );
   hb_itemRelease( temp );
   hb_itemRelease( pEmbed );
}

/*
 * GetEmbedded - Retrieves the IOleObject* pointer stored by SetEmbedded.
 */
IOleObject **GetEmbedded( HWND handle )
{
   PHB_ITEM pObject, pEmbed;
   IOleObject **result = NULL;
   pObject = ( PHB_ITEM ) GetWindowLongPtr( handle, GWLP_USERDATA );
   if( !pObject ) return NULL;
   pEmbed = hb_itemNew( GetObjectVar( pObject, "OEMBEDDED" ) );
   result = ( IOleObject ** ) hb_itemGetPtr( GetObjectVar( pEmbed, "HANDLE" ) );
   hb_itemRelease( pEmbed );
   return result;
}

/* ============================== HELPER FUNCTIONS ============================== */

#define NOTIMPLEMENTED return(E_NOTIMPL)

/*
 * Converts an OLECHAR string of digits (base 10) to a DWORD.
 */
DWORD asciiToNumW( OLECHAR * val )
{
   OLECHAR chr;
   DWORD len = 0;
   while( *val == ' ' || *val == 0x09 ) val++;
   while( *val )
   {
      chr = *( val )++ - '0';
      if( ( DWORD ) chr > 9 ) break;
      len += ( len + ( len << 3 ) + chr );
   }
   return len;
}

/* ============================== IDocHostUIHandler IMPLEMENTATION ============================== */

HRESULT STDMETHODCALLTYPE UI_QueryInterface( IDocHostUIHandler * This, REFIID riid, LPVOID * ppvObj )
{
   /* Delegate to Site_QueryInterface of the containing _IOleClientSiteEx */
   return Site_QueryInterface(
         ( IOleClientSite * ) ( ( char * ) This - sizeof( IOleClientSite ) - sizeof( _IOleInPlaceSiteEx ) ),
         riid, ppvObj );
}

ULONG STDMETHODCALLTYPE UI_AddRef( IDocHostUIHandler * This )
{
   HB_SYMBOL_UNUSED(This);
   return 1;
}

ULONG STDMETHODCALLTYPE UI_Release( IDocHostUIHandler * This )
{
   HB_SYMBOL_UNUSED(This);
   return 1;
}

HRESULT STDMETHODCALLTYPE UI_ShowContextMenu( IDocHostUIHandler * This, DWORD dwID, POINT * ppt,
                                              IUnknown * pcmdtReserved, IDispatch * pdispReserved )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(dwID);
   HB_SYMBOL_UNUSED(ppt);
   HB_SYMBOL_UNUSED(pcmdtReserved);
   HB_SYMBOL_UNUSED(pdispReserved);
   /* Tell IE not to show its context menu */
   return S_FALSE;
}

HRESULT STDMETHODCALLTYPE UI_GetHostInfo( IDocHostUIHandler * This, DOCHOSTUIINFO * pInfo )
{
   HB_SYMBOL_UNUSED(This);
   pInfo->cbSize = sizeof(DOCHOSTUIINFO);
   pInfo->dwFlags = DOCHOSTUIFLAG_NO3DBORDER;
   pInfo->dwDoubleClick = DOCHOSTUIDBLCLK_DEFAULT;
   return S_OK;
}

HRESULT STDMETHODCALLTYPE UI_ShowUI( IDocHostUIHandler * This, DWORD dwID,
                                     IOleInPlaceActiveObject * pActiveObject,
                                     IOleCommandTarget * pCommandTarget,
                                     IOleInPlaceFrame * pFrame,
                                     IOleInPlaceUIWindow * pDoc )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(dwID);
   HB_SYMBOL_UNUSED(pActiveObject);
   HB_SYMBOL_UNUSED(pCommandTarget);
   HB_SYMBOL_UNUSED(pFrame);
   HB_SYMBOL_UNUSED(pDoc);
   /* We already have our own UI, so tell IE not to show its menus/toolbars */
   return S_OK;
}

HRESULT STDMETHODCALLTYPE UI_HideUI( IDocHostUIHandler * This )
{
   HB_SYMBOL_UNUSED(This);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE UI_UpdateUI( IDocHostUIHandler * This )
{
   HB_SYMBOL_UNUSED(This);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE UI_EnableModeless( IDocHostUIHandler * This, BOOL fEnable )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(fEnable);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE UI_OnDocWindowActivate( IDocHostUIHandler * This, BOOL fActivate )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(fActivate);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE UI_OnFrameWindowActivate( IDocHostUIHandler * This, BOOL fActivate )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(fActivate);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE UI_ResizeBorder( IDocHostUIHandler * This, LPCRECT prcBorder,
                                           IOleInPlaceUIWindow * pUIWindow, BOOL fRameWindow )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(prcBorder);
   HB_SYMBOL_UNUSED(pUIWindow);
   HB_SYMBOL_UNUSED(fRameWindow);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE UI_TranslateAccelerator( IDocHostUIHandler * This, LPMSG lpMsg,
                                                   const GUID * pguidCmdGroup, DWORD nCmdID )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(lpMsg);
   HB_SYMBOL_UNUSED(pguidCmdGroup);
   HB_SYMBOL_UNUSED(nCmdID);
   /* Block all accelerators (disable context menu etc.) */
   return S_FALSE;
}

HRESULT STDMETHODCALLTYPE UI_GetOptionKeyPath( IDocHostUIHandler * This, LPOLESTR * pchKey, DWORD dw )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(pchKey);
   HB_SYMBOL_UNUSED(dw);
   return S_FALSE;
}

HRESULT STDMETHODCALLTYPE UI_GetDropTarget( IDocHostUIHandler * This,
                                            IDropTarget * pDropTarget,
                                            IDropTarget ** ppDropTarget )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(pDropTarget);
   *ppDropTarget = NULL;
   return S_FALSE;
}

HRESULT STDMETHODCALLTYPE UI_GetExternal( IDocHostUIHandler * This, IDispatch ** ppDispatch )
{
   HB_SYMBOL_UNUSED(This);
   *ppDispatch = NULL;
   return S_FALSE;
}

HRESULT STDMETHODCALLTYPE UI_TranslateUrl( IDocHostUIHandler * This, DWORD dwTranslate,
                                           OLECHAR * pchURLIn, OLECHAR ** ppchURLOut )
{
   unsigned short *src, *dest;
   DWORD len;
   HB_SYMBOL_UNUSED(dwTranslate);

   src = pchURLIn;
   while( *src )
      src++;
   --src;
   len = src - pchURLIn;

   /* Handle "app:" custom protocol */
   if( len >= 4 && !_wcsnicmp( pchURLIn, ( WCHAR * ) &AppUrl[0], 4 ) )
   {
      if( ( dest = ( OLECHAR * ) CoTaskMemAlloc( 12 << 1 ) ) != NULL )
      {
         HWND hwnd = ( ( _IOleInPlaceSiteEx * ) ( ( char * ) This -
                     sizeof( _IOleInPlaceSiteEx ) ) )->frame.window;
         *ppchURLOut = dest;
         CopyMemory( dest, &Blank[0], 12 << 1 );
         len = asciiToNumW( pchURLIn + 4 );
         PostMessage( hwnd, WM_APP, ( WPARAM ) len, 0 );
         return S_OK;
      }
   }

   *ppchURLOut = NULL;
   return S_FALSE;
}

HRESULT STDMETHODCALLTYPE UI_FilterDataObject( IDocHostUIHandler * This,
                                               IDataObject * pDO,
                                               IDataObject ** ppDORet )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(pDO);
   *ppDORet = NULL;
   return S_FALSE;
}

/* ============================== IOleClientSite IMPLEMENTATION ============================== */

HRESULT STDMETHODCALLTYPE Site_QueryInterface( IOleClientSite * This, REFIID riid, void **ppvObject )
{
   _IOleClientSiteEx *pEx = (_IOleClientSiteEx*)This;

   if( !memcmp( riid, &IID_IUnknown, sizeof( GUID ) ) ||
       !memcmp( riid, &IID_IOleClientSite, sizeof( GUID ) ) )
      *ppvObject = &pEx->client;
   else if( !memcmp( riid, &IID_IOleInPlaceSite, sizeof( GUID ) ) )
      *ppvObject = &pEx->inplace;
   else if( !memcmp( riid, &IID_IDocHostUIHandler, sizeof( GUID ) ) )
      *ppvObject = &pEx->ui;
   else
   {
      *ppvObject = NULL;
      return E_NOINTERFACE;
   }
   return S_OK;
}

ULONG STDMETHODCALLTYPE Site_AddRef( IOleClientSite * This )
{
   HB_SYMBOL_UNUSED(This);
   return 1;
}

ULONG STDMETHODCALLTYPE Site_Release( IOleClientSite * This )
{
   HB_SYMBOL_UNUSED(This);
   return 1;
}

HRESULT STDMETHODCALLTYPE Site_SaveObject( IOleClientSite * This )
{
   HB_SYMBOL_UNUSED(This);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE Site_GetMoniker( IOleClientSite * This, DWORD dwAssign, DWORD dwWhichMoniker, IMoniker ** ppmk )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(dwAssign);
   HB_SYMBOL_UNUSED(dwWhichMoniker);
   HB_SYMBOL_UNUSED(ppmk);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE Site_GetContainer( IOleClientSite * This, LPOLECONTAINER * ppContainer )
{
   HB_SYMBOL_UNUSED(This);
   *ppContainer = NULL;
   return E_NOINTERFACE;
}

HRESULT STDMETHODCALLTYPE Site_ShowObject( IOleClientSite * This )
{
   HB_SYMBOL_UNUSED(This);
   return NOERROR;
}

HRESULT STDMETHODCALLTYPE Site_OnShowWindow( IOleClientSite * This, BOOL fShow )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(fShow);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE Site_RequestNewObjectLayout( IOleClientSite * This )
{
   HB_SYMBOL_UNUSED(This);
   NOTIMPLEMENTED;
}

/* ============================== IOleInPlaceSite IMPLEMENTATION ============================== */

HRESULT STDMETHODCALLTYPE InPlace_QueryInterface( IOleInPlaceSite * This, REFIID riid, LPVOID * ppvObj )
{
   /* Delegate to Site_QueryInterface of the containing _IOleClientSiteEx */
   return Site_QueryInterface(
         ( IOleClientSite * ) ( ( char * ) This - sizeof( IOleClientSite ) ),
         riid, ppvObj );
}

ULONG STDMETHODCALLTYPE InPlace_AddRef( IOleInPlaceSite * This )
{
   HB_SYMBOL_UNUSED(This);
   return 1;
}

ULONG STDMETHODCALLTYPE InPlace_Release( IOleInPlaceSite * This )
{
   HB_SYMBOL_UNUSED(This);
   return 1;
}

HRESULT STDMETHODCALLTYPE InPlace_GetWindow( IOleInPlaceSite * This, HWND * lphwnd )
{
   *lphwnd = ( ( _IOleInPlaceSiteEx * ) This )->frame.window;
   return S_OK;
}

HRESULT STDMETHODCALLTYPE InPlace_ContextSensitiveHelp( IOleInPlaceSite * This, BOOL fEnterMode )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(fEnterMode);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE InPlace_CanInPlaceActivate( IOleInPlaceSite * This )
{
   HB_SYMBOL_UNUSED(This);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE InPlace_OnInPlaceActivate( IOleInPlaceSite * This )
{
   HB_SYMBOL_UNUSED(This);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE InPlace_OnUIActivate( IOleInPlaceSite * This )
{
   HB_SYMBOL_UNUSED(This);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE InPlace_GetWindowContext( IOleInPlaceSite * This,
                                                    LPOLEINPLACEFRAME * lplpFrame,
                                                    LPOLEINPLACEUIWINDOW * lplpDoc,
                                                    LPRECT lprcPosRect,
                                                    LPRECT lprcClipRect,
                                                    LPOLEINPLACEFRAMEINFO lpFrameInfo )
{
   _IOleInPlaceSiteEx *pSite = (_IOleInPlaceSiteEx*)This;
   HB_SYMBOL_UNUSED(lprcPosRect);
   HB_SYMBOL_UNUSED(lprcClipRect);

   *lplpFrame = (LPOLEINPLACEFRAME)&pSite->frame;
   *lplpDoc = NULL;
   lpFrameInfo->fMDIApp = FALSE;
   lpFrameInfo->hwndFrame = pSite->frame.window;
   lpFrameInfo->haccel = NULL;
   lpFrameInfo->cAccelEntries = 0;
   return S_OK;
}

HRESULT STDMETHODCALLTYPE InPlace_Scroll( IOleInPlaceSite * This, SIZE scrollExtent )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(scrollExtent);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE InPlace_OnUIDeactivate( IOleInPlaceSite * This, BOOL fUndoable )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(fUndoable);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE InPlace_OnInPlaceDeactivate( IOleInPlaceSite * This )
{
   HB_SYMBOL_UNUSED(This);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE InPlace_DiscardUndoState( IOleInPlaceSite * This )
{
   HB_SYMBOL_UNUSED(This);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE InPlace_DeactivateAndUndo( IOleInPlaceSite * This )
{
   HB_SYMBOL_UNUSED(This);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE InPlace_OnPosRectChange( IOleInPlaceSite * This, LPCRECT lprcPosRect )
{
   IOleObject *browserObject;
   IOleInPlaceObject *inplace;

   /* Retrieve the browser object pointer stored before our _IOleClientSiteEx */
   browserObject = *( ( IOleObject ** ) ( ( char * ) This - sizeof( IOleObject * ) -
                                          sizeof( IOleClientSite ) ) );
   if( browserObject && !browserObject->lpVtbl->QueryInterface( browserObject, &IID_IOleInPlaceObject,
                                                                 ( void ** ) &inplace ) )
   {
      inplace->lpVtbl->SetObjectRects( inplace, lprcPosRect, lprcPosRect );
      inplace->lpVtbl->Release( inplace );
   }
   return S_OK;
}

/* ============================== IOleInPlaceFrame IMPLEMENTATION ============================== */

HRESULT STDMETHODCALLTYPE Frame_QueryInterface( IOleInPlaceFrame * This, REFIID riid, LPVOID * ppvObj )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(riid);
   HB_SYMBOL_UNUSED(ppvObj);
   NOTIMPLEMENTED;
}

ULONG STDMETHODCALLTYPE Frame_AddRef( IOleInPlaceFrame * This )
{
   HB_SYMBOL_UNUSED(This);
   return 1;
}

ULONG STDMETHODCALLTYPE Frame_Release( IOleInPlaceFrame * This )
{
   HB_SYMBOL_UNUSED(This);
   return 1;
}

HRESULT STDMETHODCALLTYPE Frame_GetWindow( IOleInPlaceFrame * This, HWND * lphwnd )
{
   *lphwnd = ( ( _IOleInPlaceFrameEx * ) This )->window;
   return S_OK;
}

HRESULT STDMETHODCALLTYPE Frame_ContextSensitiveHelp( IOleInPlaceFrame * This, BOOL fEnterMode )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(fEnterMode);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE Frame_GetBorder( IOleInPlaceFrame * This, LPRECT lprectBorder )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(lprectBorder);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE Frame_RequestBorderSpace( IOleInPlaceFrame * This,
                                                    LPCBORDERWIDTHS pborderwidths )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(pborderwidths);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE Frame_SetBorderSpace( IOleInPlaceFrame * This,
                                                LPCBORDERWIDTHS pborderwidths )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(pborderwidths);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE Frame_SetActiveObject( IOleInPlaceFrame * This,
                                                 IOleInPlaceActiveObject * pActiveObject,
                                                 LPCOLESTR pszObjName )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(pActiveObject);
   HB_SYMBOL_UNUSED(pszObjName);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE Frame_InsertMenus( IOleInPlaceFrame * This, HMENU hmenuShared,
                                             LPOLEMENUGROUPWIDTHS lpMenuWidths )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(hmenuShared);
   HB_SYMBOL_UNUSED(lpMenuWidths);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE Frame_SetMenu( IOleInPlaceFrame * This, HMENU hmenuShared,
                                         HOLEMENU holemenu, HWND hwndActiveObject )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(hmenuShared);
   HB_SYMBOL_UNUSED(holemenu);
   HB_SYMBOL_UNUSED(hwndActiveObject);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE Frame_RemoveMenus( IOleInPlaceFrame * This, HMENU hmenuShared )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(hmenuShared);
   NOTIMPLEMENTED;
}

HRESULT STDMETHODCALLTYPE Frame_SetStatusText( IOleInPlaceFrame * This, LPCOLESTR pszStatusText )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(pszStatusText);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE Frame_EnableModeless( IOleInPlaceFrame * This, BOOL fEnable )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(fEnable);
   return S_OK;
}

HRESULT STDMETHODCALLTYPE Frame_TranslateAccelerator( IOleInPlaceFrame * This, LPMSG lpmsg, WORD wID )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(lpmsg);
   HB_SYMBOL_UNUSED(wID);
   NOTIMPLEMENTED;
}

/* ============================== IDispatch IMPLEMENTATION (Event Sink) ============================== */

/* The _IDispatchEx structure is defined in htmlcore.h - we use it here. */
/* Forward declare the constant strings used for event attachment. */
static const BSTR OnBeforeOnLoad = L"onbeforeunload";
static const WCHAR BeforeUnload[] = L"beforeunload";

HRESULT STDMETHODCALLTYPE Dispatch_QueryInterface( IDispatch * This, REFIID riid, void **ppvObject )
{
   *ppvObject = NULL;
   if( !memcmp( riid, &IID_IUnknown, sizeof( GUID ) ) ||
       !memcmp( riid, &IID_IDispatch, sizeof( GUID ) ) )
   {
      *ppvObject = ( void * ) This;
      Dispatch_AddRef( This );
      return S_OK;
   }
   return E_NOINTERFACE;
}

ULONG STDMETHODCALLTYPE Dispatch_AddRef( IDispatch * This )
{
   return InterlockedIncrement( (volatile LONG*) &( ( _IDispatchEx * ) This )->refCount );
}

ULONG STDMETHODCALLTYPE Dispatch_Release( IDispatch * This )
{
   _IDispatchEx *pThis = (_IDispatchEx*)This;
   if( InterlockedDecrement( (volatile LONG*) &pThis->refCount ) == 0 )
   {
      /* Release extra data before freeing */
      if( pThis->object )
         pThis->object->lpVtbl->Release( pThis->object );
      if( pThis->htmlWindow2 )
         pThis->htmlWindow2->lpVtbl->Release( pThis->htmlWindow2 );
      hb_xfree( ( char * ) pThis - pThis->extraSize );
      return 0;
   }
   return pThis->refCount;
}

HRESULT STDMETHODCALLTYPE Dispatch_GetTypeInfoCount( IDispatch * This, unsigned int *pctinfo )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(pctinfo);
   return E_NOTIMPL;
}

HRESULT STDMETHODCALLTYPE Dispatch_GetTypeInfo( IDispatch * This, unsigned int iTInfo,
                                                LCID lcid, ITypeInfo ** ppTInfo )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(iTInfo);
   HB_SYMBOL_UNUSED(lcid);
   HB_SYMBOL_UNUSED(ppTInfo);
   return E_NOTIMPL;
}

HRESULT STDMETHODCALLTYPE Dispatch_GetIDsOfNames( IDispatch * This, REFIID riid,
                                                  OLECHAR ** rgszNames, unsigned int cNames,
                                                  LCID lcid, DISPID * rgDispId )
{
   HB_SYMBOL_UNUSED(This);
   HB_SYMBOL_UNUSED(riid);
   HB_SYMBOL_UNUSED(rgszNames);
   HB_SYMBOL_UNUSED(cNames);
   HB_SYMBOL_UNUSED(lcid);
   HB_SYMBOL_UNUSED(rgDispId);
   return S_OK;
}

static void webDetach( _IDispatchEx * lpDispatchEx )
{
   IHTMLWindow3 *htmlWindow3 = NULL;
   if( lpDispatchEx->htmlWindow2 )
   {
      if( !lpDispatchEx->htmlWindow2->lpVtbl->QueryInterface( lpDispatchEx->htmlWindow2,
               ( GUID * ) &_IID_IHTMLWindow3[0],
               ( void ** ) &htmlWindow3 ) && htmlWindow3 )
      {
         htmlWindow3->lpVtbl->detachEvent( htmlWindow3, OnBeforeOnLoad,
                                           ( LPDISPATCH ) lpDispatchEx );
         htmlWindow3->lpVtbl->Release( htmlWindow3 );
      }
   }
   if( lpDispatchEx->object )
   {
      lpDispatchEx->object->lpVtbl->Release( lpDispatchEx->object );
      lpDispatchEx->object = NULL;
   }
}

HRESULT STDMETHODCALLTYPE Dispatch_Invoke( IDispatch * This, DISPID dispIdMember, REFIID riid,
                                           LCID lcid, WORD wFlags, DISPPARAMS * pDispParams,
                                           VARIANT * pVarResult, EXCEPINFO * pExcepInfo,
                                           unsigned int *puArgErr )
{
   _IDispatchEx *pThis = (_IDispatchEx*)This;
   WEBPARAMS webParams;
   BSTR strType = NULL;
   IHTMLEventObj *htmlEvent = NULL;

   HB_SYMBOL_UNUSED(dispIdMember);
   HB_SYMBOL_UNUSED(riid);
   HB_SYMBOL_UNUSED(lcid);
   HB_SYMBOL_UNUSED(wFlags);
   HB_SYMBOL_UNUSED(pDispParams);
   HB_SYMBOL_UNUSED(pVarResult);
   HB_SYMBOL_UNUSED(pExcepInfo);
   HB_SYMBOL_UNUSED(puArgErr);

   if( !pThis->htmlWindow2 )
      return S_OK;

   if( pThis->htmlWindow2->lpVtbl->get_event( pThis->htmlWindow2, &htmlEvent ) || !htmlEvent )
      return S_OK;

   if( htmlEvent->lpVtbl->get_type( htmlEvent, &strType ) || !strType )
   {
      htmlEvent->lpVtbl->Release( htmlEvent );
      return S_OK;
   }

   webParams.nmhdr.hwndFrom = pThis->hwnd;
   webParams.nmhdr.idFrom = 0;
   webParams.nmhdr.code = lstrcmpW( strType, &BeforeUnload[0] ) ? 1 : 0; /* 0 = beforeunload */

   if( pThis->id < 0 )
   {
      /* Use userdata directly */
      webParams.eventStr = ( LPCTSTR ) pThis->userdata;
   }
   else if( webParams.nmhdr.code != 0 ) /* not beforeunload */
   {
      if( !IsWindowUnicode( webParams.nmhdr.hwndFrom ) )
      {
         DWORD size = WideCharToMultiByte( CP_ACP, 0, (WCHAR*)strType, -1, NULL, 0, NULL, NULL );
         webParams.eventStr = ( LPCTSTR ) hb_xgrab( size );
         WideCharToMultiByte( CP_ACP, 0, (WCHAR*)strType, -1, (char*)webParams.eventStr, size, NULL, NULL );
      }
      else
      {
         webParams.eventStr = ( LPCTSTR ) strType; /* BSTR is already wide */
      }
   }

   /* Send notification to the host window */
   SendMessage( webParams.nmhdr.hwndFrom, WM_NOTIFY, ( WPARAM ) This, ( LPARAM ) &webParams );

   /* Clean up */
   if( webParams.nmhdr.code != 0 && webParams.eventStr && !IsWindowUnicode( webParams.nmhdr.hwndFrom ) )
   {
      hb_xfree( (void*)webParams.eventStr );
   }
   if( strType )
      SysFreeString( strType );

   htmlEvent->lpVtbl->Release( htmlEvent );

   /* If this was the "beforeunload" event, detach and release our sink */
   if( webParams.nmhdr.code == 0 )
   {
      webDetach( pThis );
   }

   return S_OK;
}

/* ============================== EXPORTED FUNCTIONS ============================== */

/*
 * CreateWebEvtHandler - Creates an event handler to attach to web page events.
 */
IDispatch *WINAPI CreateWebEvtHandler( HWND hwnd, IHTMLDocument2 * htmlDoc2,
                                       DWORD extraData, long id, IUnknown * obj,
                                       void *userdata )
{
   _IDispatchEx *lpDispatchEx;
   IHTMLWindow2 *htmlWindow2 = NULL;
   IHTMLWindow3 *htmlWindow3 = NULL;
   VARIANT varDisp;

   if( !htmlDoc2 )
      return NULL;

   if( htmlDoc2->lpVtbl->get_parentWindow( htmlDoc2, &htmlWindow2 ) || !htmlWindow2 )
      return NULL;

   VariantInit( &varDisp );
   varDisp.DEF_VT = VT_DISPATCH;

   DWORD totalSize = sizeof( _IDispatchEx ) + extraData;
   lpDispatchEx = (_IDispatchEx*) hb_xgrab( totalSize );
   if( !lpDispatchEx )
   {
      htmlWindow2->lpVtbl->Release( htmlWindow2 );
      if( obj ) obj->lpVtbl->Release( obj );
      return NULL;
   }

   ZeroMemory( lpDispatchEx, totalSize );
   /* Adjust pointer to point to the start of _IDispatchEx (after extraData) */
   lpDispatchEx = (_IDispatchEx*)( (char*)lpDispatchEx + extraData );

   /* Fill in the _IDispatchEx */
   lpDispatchEx->dispatchObj.lpVtbl = &MyIDispatchVtbl;
   lpDispatchEx->hwnd = hwnd;
   lpDispatchEx->htmlWindow2 = htmlWindow2;
   lpDispatchEx->id = (short)id;
   lpDispatchEx->extraSize = (unsigned short)extraData;
   lpDispatchEx->object = obj;
   lpDispatchEx->userdata = userdata;
   lpDispatchEx->refCount = 0;

   /* Attach to the "onbeforeunload" event so we get notified when the page unloads */
   if( htmlWindow2->lpVtbl->QueryInterface( htmlWindow2, (GUID*)&_IID_IHTMLWindow3[0],
                                            (void**)&htmlWindow3 ) || !htmlWindow3 )
   {
      /* Failed to get IHTMLWindow3; cleanup and return NULL */
      hb_xfree( (char*)lpDispatchEx - extraData );
      htmlWindow2->lpVtbl->Release( htmlWindow2 );
      if( obj ) obj->lpVtbl->Release( obj );
      return NULL;
   }

   varDisp.DEF_PDISPVAL = (IDispatch*)lpDispatchEx;

   if( htmlWindow3->lpVtbl->attachEvent( htmlWindow3, OnBeforeOnLoad,
                                         (LPDISPATCH)lpDispatchEx,
                                         (VARIANT_BOOL*)&varDisp ) )
   {
      /* attachEvent failed */
      htmlWindow3->lpVtbl->Release( htmlWindow3 );
      hb_xfree( (char*)lpDispatchEx - extraData );
      htmlWindow2->lpVtbl->Release( htmlWindow2 );
      if( obj ) obj->lpVtbl->Release( obj );
      return NULL;
   }

   htmlWindow3->lpVtbl->Release( htmlWindow3 );
   /* Note: htmlWindow2 is now owned by lpDispatchEx and will be released in Dispatch_Release */

   return (IDispatch*)lpDispatchEx;
}

/*
 * FreeWebEvtHandler - Manually detaches and frees an event handler.
 */
void WINAPI FreeWebEvtHandler( IDispatch * lpDispatch )
{
   if( lpDispatch )
      webDetach( (_IDispatchEx*)lpDispatch );
}

/*
 * GetWebSrcElement - Retrieves the IHTMLElement from an event object.
 */
IHTMLElement *WINAPI GetWebSrcElement( IHTMLEventObj * htmlEvent )
{
   IHTMLElement *htmlElement = NULL;
   if( htmlEvent )
      htmlEvent->lpVtbl->get_srcElement( htmlEvent, &htmlElement );
   return htmlElement;
}

/*
 * SetWebReturnValue - Sets the return value for an event (e.g., cancelling onsubmit).
 */
HRESULT WINAPI SetWebReturnValue( IHTMLEventObj * htmlEvent, BOOL returnVal )
{
   VARIANT varResult;
   VariantInit( &varResult );
   varResult.DEF_VT = VT_BOOL;
   varResult.DEF_BOOLVAL = returnVal ? VARIANT_TRUE : VARIANT_FALSE;
   return htmlEvent->lpVtbl->put_returnValue( htmlEvent, varResult );
}

/*
 * GetWebPtrs - Retrieves IWebBrowser2 and/or IHTMLDocument2 pointers.
 */
HRESULT WINAPI GetWebPtrs( HWND hwnd, IWebBrowser2 ** webBrowser2Result,
                           IHTMLDocument2 ** htmlDoc2Result )
{
   IOleObject *browserObject;
   IWebBrowser2 *webBrowser2 = NULL;

   if( !webBrowser2Result && !htmlDoc2Result ) return E_FAIL;
   if( !IsWindow( hwnd ) ) return E_FAIL;

   browserObject = *GetEmbedded( hwnd );
   if( !browserObject ) return E_FAIL;

   if( browserObject->lpVtbl->QueryInterface( browserObject, &IID_IWebBrowser2,
                                              (void**)&webBrowser2 ) )
      return E_FAIL;

   if( htmlDoc2Result )
   {
      LPDISPATCH lpDispatch = NULL;
      *htmlDoc2Result = NULL;
      if( !webBrowser2->lpVtbl->get_Document( webBrowser2, &lpDispatch ) && lpDispatch )
      {
         if( lpDispatch->lpVtbl->QueryInterface( lpDispatch, &IID_IHTMLDocument2,
                                                 (void**)htmlDoc2Result ) )
         {
            lpDispatch->lpVtbl->Release( lpDispatch );
            webBrowser2->lpVtbl->Release( webBrowser2 );
            return E_FAIL;
         }
         lpDispatch->lpVtbl->Release( lpDispatch );
      }
   }

   if( webBrowser2Result )
      *webBrowser2Result = webBrowser2;
   else
      webBrowser2->lpVtbl->Release( webBrowser2 );

   return S_OK;
}

/*
 * TStr2BStr - Converts a TCHAR string to a BSTR.
 */
#ifdef UNICODE
BSTR WINAPI TStr2BStr( HWND hwnd, const WCHAR * string )
#else
BSTR WINAPI TStr2BStr( HWND hwnd, const char *string )
#endif
{
   BSTR bstr;
   if( !IsWindowUnicode( hwnd ) )
   {
      WCHAR *buffer;
      DWORD size = MultiByteToWideChar( CP_ACP, 0, ( char * ) string, -1, NULL, 0 );
      if( ( buffer = ( WCHAR * ) hb_xgrab( sizeof( WCHAR ) * size ) ) == NULL )
         return NULL;
      MultiByteToWideChar( CP_ACP, 0, ( char * ) string, -1, buffer, size );
      bstr = SysAllocString( buffer );
      hb_xfree( buffer );
   }
   else
   {
      bstr = SysAllocString( ( WCHAR * ) string );
   }
   return bstr;
}

/*
 * BStr2TStr - Converts a BSTR to a TCHAR string.
 */
void *WINAPI BStr2TStr( HWND hwnd, BSTR strIn )
{
   DWORD size;
   void *strOut;
   if( !IsWindowUnicode( hwnd ) )
   {
      size = WideCharToMultiByte( CP_ACP, 0, ( WCHAR * ) strIn, -1, NULL, 0, NULL, NULL );
      if( ( strOut = hb_xgrab( size ) ) != NULL )
         WideCharToMultiByte( CP_ACP, 0, ( WCHAR * ) strIn, -1, ( char * ) strOut, size, NULL, NULL );
   }
   else
   {
      size = ( ( *( ( short * ) strIn ) + 1 ) * sizeof( wchar_t ) ) + 2;
      if( ( strOut = hb_xgrab( size ) ) != NULL )
         CopyMemory( strOut, strIn, size );
   }
   return strOut;
}

/*
 * GetWebElement - Retrieves an IHTMLElement by name/id.
 */
#ifdef UNICODE
IHTMLElement *WINAPI GetWebElement( HWND hwnd, IHTMLDocument2 * htmlDoc2,
                                    const WCHAR * name, INT nIndex )
#else
IHTMLElement *WINAPI GetWebElement( HWND hwnd, IHTMLDocument2 * htmlDoc2,
                                    const char *name, INT nIndex )
#endif
{
   IHTMLElementCollection *htmlCollection = NULL;
   IHTMLElement *htmlElem = NULL;
   LPDISPATCH lpDispatch = NULL;
   VARIANT varName, varIndex;

   if( !htmlDoc2 && GetWebPtrs( hwnd, NULL, &htmlDoc2 ) )
      return NULL;

   if( htmlDoc2->lpVtbl->get_all( htmlDoc2, &htmlCollection ) || !htmlCollection )
      return NULL;

   VariantInit( &varName );
   varName.DEF_VT = VT_BSTR;
   varName.DEF_BSTRVAL = TStr2BStr( hwnd, name );
   if( varName.DEF_BSTRVAL )
   {
      VariantInit( &varIndex );
      varIndex.DEF_VT = VT_I4;
      varIndex.DEF_LVAL = nIndex;

      htmlCollection->lpVtbl->item( htmlCollection, varName, varIndex, &lpDispatch );

      VariantClear( &varName );
      VariantClear( &varIndex );
   }
   htmlCollection->lpVtbl->Release( htmlCollection );

   if( lpDispatch )
   {
      if( !lpDispatch->lpVtbl->QueryInterface( lpDispatch, &IID_IHTMLElement,
                                               (void**)&htmlElem ) )
      {
         /* success */
      }
      lpDispatch->lpVtbl->Release( lpDispatch );
   }

   return htmlElem;
}

/*
 * doEvents - Pumps messages for the given window.
 */
static void doEvents( HWND hwnd )
{
   MSG msg;
   while( PeekMessage( &msg, hwnd, 0, 0, PM_REMOVE ) )
   {
      TranslateMessage( &msg );
      DispatchMessage( &msg );
   }
}

/*
 * WaitOnReadyState - Waits for the browser to reach a certain ready state.
 */
HRESULT WINAPI WaitOnReadyState( HWND hwnd, READYSTATE rs, DWORD timeout,
                                 IWebBrowser2 * webBrowser2 )
{
   READYSTATE rsi;
   DWORD dwStart;
   unsigned char releaseOnComplete = 0;

   if( !webBrowser2 )
   {
      if( GetWebPtrs( hwnd, &webBrowser2, NULL ) )
         return WORS_DESTROYED;
      releaseOnComplete = 1;
   }

   webBrowser2->lpVtbl->get_ReadyState( webBrowser2, &rsi );
   if( rsi >= rs )
   {
      if( releaseOnComplete ) webBrowser2->lpVtbl->Release( webBrowser2 );
      return WORS_SUCCESS;
   }

   dwStart = GetTickCount();
   do
   {
      doEvents( hwnd );
      if( !IsWindow( hwnd ) )
      {
         if( releaseOnComplete ) webBrowser2->lpVtbl->Release( webBrowser2 );
         return WORS_DESTROYED;
      }
      webBrowser2->lpVtbl->get_ReadyState( webBrowser2, &rsi );
      if( rsi >= rs )
      {
         if( releaseOnComplete ) webBrowser2->lpVtbl->Release( webBrowser2 );
         return WORS_SUCCESS;
      }
      Sleep( 10 );
   }
   while( !timeout || ( GetTickCount() - dwStart ) <= timeout );

   if( releaseOnComplete ) webBrowser2->lpVtbl->Release( webBrowser2 );
   return WORS_TIMEOUT;
}

/*
 * UnEmbedBrowserObject - Detaches the browser object from the window.
 */
void WINAPI UnEmbedBrowserObject( HWND hwnd )
{
   IOleObject **browserHandle = GetEmbedded( hwnd );
   if( browserHandle && *browserHandle )
   {
      IOleObject *browserObject = *browserHandle;
      browserObject->lpVtbl->Close( browserObject, OLECLOSE_NOSAVE );
      browserObject->lpVtbl->Release( browserObject );
      SetEmbedded( hwnd, NULL );
   }
}

/*
 * DisplayHTMLStr - Displays an HTML string in the browser.
 */
#ifdef UNICODE
long WINAPI DisplayHTMLStr( HWND hwnd, const WCHAR * string )
#else
long WINAPI DisplayHTMLStr( HWND hwnd, const char *string )
#endif
{
   IHTMLDocument2 *htmlDoc2 = NULL;
   IWebBrowser2 *webBrowser2 = NULL;
   SAFEARRAY *sfArray = NULL;
   VARIANT myURL;
   VARIANT *pVar = NULL;

   VariantInit( &myURL );
   myURL.DEF_VT = VT_BSTR;

   if( GetWebPtrs( hwnd, &webBrowser2, NULL ) )
      return -1;

   /* Navigate to blank page */
   myURL.DEF_BSTRVAL = SysAllocString( &Blank[0] );
   webBrowser2->lpVtbl->Navigate2( webBrowser2, &myURL, 0, 0, 0, 0 );
   SysFreeString( myURL.DEF_BSTRVAL );

   if( WaitOnReadyState( hwnd, READYSTATE_COMPLETE, 1000, webBrowser2 ) == WORS_DESTROYED )
   {
      webBrowser2->lpVtbl->Release( webBrowser2 );
      return -1;
   }

   if( GetWebPtrs( hwnd, NULL, &htmlDoc2 ) )
   {
      webBrowser2->lpVtbl->Release( webBrowser2 );
      return -1;
   }

   sfArray = SafeArrayCreate( VT_VARIANT, 1, (SAFEARRAYBOUND*)&ArrayBound );
   if( sfArray && !SafeArrayAccessData( sfArray, (void**)&pVar ) )
   {
      pVar->DEF_VT = VT_BSTR;
      pVar->DEF_BSTRVAL = TStr2BStr( hwnd, string );
      if( pVar->DEF_BSTRVAL )
      {
         htmlDoc2->lpVtbl->write( htmlDoc2, sfArray );
         htmlDoc2->lpVtbl->close( htmlDoc2 );
      }
      SafeArrayDestroy( sfArray );
   }

   htmlDoc2->lpVtbl->Release( htmlDoc2 );
   webBrowser2->lpVtbl->Release( webBrowser2 );
   return 0;
}

/*
 * DisplayHTMLPage - Displays a URL or file in the browser.
 */
#ifdef UNICODE
long WINAPI DisplayHTMLPage( HWND hwnd, const WCHAR * webPageName )
#else
long WINAPI DisplayHTMLPage( HWND hwnd, const char *webPageName )
#endif
{
   IWebBrowser2 *webBrowser2 = NULL;
   VARIANT myURL;

   if( GetWebPtrs( hwnd, &webBrowser2, NULL ) )
      return -5;

   VariantInit( &myURL );
   myURL.DEF_VT = VT_BSTR;
   myURL.DEF_BSTRVAL = TStr2BStr( hwnd, webPageName );
   if( !myURL.DEF_BSTRVAL )
   {
      webBrowser2->lpVtbl->Release( webBrowser2 );
      return -6;
   }

   webBrowser2->lpVtbl->Navigate2( webBrowser2, &myURL, 0, 0, 0, 0 );
   VariantClear( &myURL );
   webBrowser2->lpVtbl->Release( webBrowser2 );
   return 0;
}

/*
 * DoPageAction - Performs navigation actions (Back, Forward, etc.).
 */
void WINAPI DoPageAction( HWND hwnd, DWORD action )
{
   IWebBrowser2 *webBrowser2 = NULL;
   if( GetWebPtrs( hwnd, &webBrowser2, NULL ) )
      return;

   switch( action )
   {
      case WEBPAGE_GOBACK:     webBrowser2->lpVtbl->GoBack( webBrowser2 ); break;
      case WEBPAGE_GOFORWARD:  webBrowser2->lpVtbl->GoForward( webBrowser2 ); break;
      case WEBPAGE_GOHOME:     webBrowser2->lpVtbl->GoHome( webBrowser2 ); break;
      case WEBPAGE_SEARCH:     webBrowser2->lpVtbl->GoSearch( webBrowser2 ); break;
      case WEBPAGE_REFRESH:    webBrowser2->lpVtbl->Refresh( webBrowser2 ); break;
      case WEBPAGE_STOP:       webBrowser2->lpVtbl->Stop( webBrowser2 ); break;
   }
   webBrowser2->lpVtbl->Release( webBrowser2 );
}

/*
 * ResizeBrowser - Resizes the browser control.
 */
void WINAPI ResizeBrowser( HWND hwnd, DWORD width, DWORD height )
{
   IWebBrowser2 *webBrowser2 = NULL;
   if( GetWebPtrs( hwnd, &webBrowser2, NULL ) )
      return;

   webBrowser2->lpVtbl->put_Width( webBrowser2, width );
   webBrowser2->lpVtbl->put_Height( webBrowser2, height );
   webBrowser2->lpVtbl->Release( webBrowser2 );
}

/*
 * EmbedBrowserObject - Embeds the browser object in the specified window.
 */
long WINAPI EmbedBrowserObject( HWND hwnd )
{
   IOleObject *browserObject = NULL;
   IWebBrowser2 *webBrowser2 = NULL;
   RECT rect;
   _IOleClientSiteEx *pSite = NULL;
   IOleObject **ppBrowser = NULL;
   HRESULT hr;

   size_t totalSize = sizeof( _IOleClientSiteEx ) + sizeof( IOleObject * );
   char *ptr = (char*) hb_xgrab( totalSize );
   if( !ptr ) return -1;

   ppBrowser = (IOleObject**) ptr;
   *ppBrowser = NULL;

   pSite = (_IOleClientSiteEx*)( ptr + sizeof( IOleObject * ) );
   ZeroMemory( pSite, sizeof( _IOleClientSiteEx ) );

   pSite->client.lpVtbl = &MyIOleClientSiteTable;
   pSite->inplace.inplace.lpVtbl = &MyIOleInPlaceSiteTable;
   pSite->inplace.frame.frame.lpVtbl = &MyIOleInPlaceFrameTable;
   pSite->inplace.frame.window = hwnd;
   pSite->ui.ui.lpVtbl = &MyIDocHostUIHandlerTable;

   hr = CoCreateInstance( &CLSID_WebBrowser, NULL, CLSCTX_INPROC,
                          &IID_IWebBrowser2, (void**)&webBrowser2 );
   if( FAILED(hr) )
   {
      hb_xfree( ptr );
      return -2;
   }

   hr = webBrowser2->lpVtbl->QueryInterface( webBrowser2, &IID_IOleObject,
                                             (void**)&browserObject );
   if( FAILED(hr) || !browserObject )
   {
      webBrowser2->lpVtbl->Release( webBrowser2 );
      hb_xfree( ptr );
      return -3;
   }

   *ppBrowser = browserObject;
   SetWindowLongPtr( hwnd, GWLP_USERDATA, (LONG_PTR)ptr );

   hr = browserObject->lpVtbl->SetClientSite( browserObject, (IOleClientSite*)pSite );
   if( FAILED(hr) )
   {
      SetWindowLongPtr( hwnd, GWLP_USERDATA, 0 );
      browserObject->lpVtbl->Release( browserObject );
      webBrowser2->lpVtbl->Release( webBrowser2 );
      hb_xfree( ptr );
      return -4;
   }

   GetClientRect( hwnd, &rect );
   hr = browserObject->lpVtbl->DoVerb( browserObject, OLEIVERB_INPLACEACTIVATE,
                                       NULL, (IOleClientSite*)pSite, 0, hwnd, &rect );
   if( FAILED(hr) )
   {
      SetWindowLongPtr( hwnd, GWLP_USERDATA, 0 );
      browserObject->lpVtbl->Release( browserObject );
      webBrowser2->lpVtbl->Release( webBrowser2 );
      hb_xfree( ptr );
      return -4;
   }

   webBrowser2->lpVtbl->put_Left( webBrowser2, 0 );
   webBrowser2->lpVtbl->put_Top( webBrowser2, 0 );
   webBrowser2->lpVtbl->put_Width( webBrowser2, rect.right );
   webBrowser2->lpVtbl->put_Height( webBrowser2, rect.bottom );

   webBrowser2->lpVtbl->Release( webBrowser2 );
   SetEmbedded( hwnd, ppBrowser );

   return 0;
}