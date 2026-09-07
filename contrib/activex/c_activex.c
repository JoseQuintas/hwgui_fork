/*
 * $Id$
 */
/*
 * ooHG source code:
 * ActiveX control
 *
 *  Marcelo Torres, Noviembre de 2006.
 *  TActiveX para [x]Harbour Minigui.
 *  Adaptacion del trabajo de:
 *  ---------------------------------------------
 *  Lira Lira Oscar Joel [oSkAr]
 *  Clase TActiveX_FreeWin para Fivewin
 *  Noviembre 8 del 2006
 *  email: oscarlira78@hotmail.com
 *  http://freewin.sytes.net
 *  @CopyRight 2006 Todos los Derechos Reservados
 *  ---------------------------------------------
 *  Implemented by ooHG team.
 *
 * + Soporte de Eventos para los controles activeX [oSkAr] 20070829
 *
 * + Ported to hwgui by FP 20080331
 *
 * ======================================================================
 * 2026-09-07: Major refactoring for modern compilers and Unicode support.
 *   - Replaced hb_parc() with HB_PARSTR() macro for TCHAR compatibility.
 *   - Fixed memory leaks in event sink (PHB_ITEM release).
 *   - Replaced GlobalAlloc/GlobalFree with hb_xgrab/hb_xfree.
 *   - Added error checking for AtlAxGetControl.
 *   - Removed __XHARBOUR__ conditional code.
 *   - Use VARIANT macros (V_VT, V_I2REF, etc.) with proper dereferencing.
 *   - Implemented manual argument pushing (no hb_itemPushList).
 *   - 32/64-bit safe.
 * ======================================================================
 */

#ifndef NONAMELESSUNION
#define NONAMELESSUNION
#endif

#ifndef _HB_API_INTERNAL_
#define _HB_API_INTERNAL_
#endif

#include <hbvmopt.h>
#include <windows.h>
#include <commctrl.h>
#include <hbapi.h>
#include <hbvm.h>
#include <hbstack.h>
#include <ocidl.h>
#include <oleauto.h>      /* for VARIANT macros */
#include <hbapiitm.h>

/* Harbour OLE support functions */
extern HB_EXPORT void        hb_oleVariantToItem( PHB_ITEM pItem, VARIANT * pVariant );
extern HB_EXPORT IDispatch * hb_oleItemGet( PHB_ITEM pItem );
extern HB_EXPORT PHB_ITEM    hb_oleItemPut( PHB_ITEM pItem, IDispatch * pDisp );

#include "guilib.h"

/* -------------------------------------------------------------------- */
/*  Macro for TCHAR string from Harbour parameter                       */
/* -------------------------------------------------------------------- */
#ifdef UNICODE
   #define HB_PARSTR(i)  hb_parwc(i)   /* returns const wchar_t* */
#else
   #define HB_PARSTR(i)  hb_parc(i)    /* returns const char* */
#endif

/* Suppress warnings for GCC/Clang */
#if defined(__GNUC__) && !defined(__INTEL_COMPILER) && !defined(__clang__)
#pragma GCC diagnostic ignored "-Wpragmas"
#pragma GCC diagnostic ignored "-Wsign-compare"
#endif

/* -------------------------------------------------------------------- */
/*  ATL function pointers                                               */
/* -------------------------------------------------------------------- */
typedef HRESULT (WINAPI * LPAtlAxWinInit)(void);
typedef HRESULT (WINAPI * LPAtlAxGetControl)(HWND, IUnknown **);
typedef HRESULT (WINAPI * LPAtlAxCreateControl)(LPCOLESTR, HWND, IStream *, IUnknown **);

static HMODULE hAtl = NULL;
static LPAtlAxWinInit    AtlAxWinInit    = NULL;
static LPAtlAxGetControl AtlAxGetControl = NULL;
static LPAtlAxCreateControl AtlAxCreateControl = NULL;

static void _Ax_Init(void)
{
   if (!hAtl)
   {
      hAtl = LoadLibrary(TEXT("Atl.Dll"));
      if (hAtl)
      {
         AtlAxWinInit = (LPAtlAxWinInit) GetProcAddress(hAtl, "AtlAxWinInit");
         AtlAxGetControl = (LPAtlAxGetControl) GetProcAddress(hAtl, "AtlAxGetControl");
         AtlAxCreateControl = (LPAtlAxCreateControl) GetProcAddress(hAtl, "AtlAxCreateControl");
         if (AtlAxWinInit)
            AtlAxWinInit();
      }
   }
}

/* -------------------------------------------------------------------- */
/*  HWG_CREATEACTIVEX - Create an ActiveX control window                */
/* -------------------------------------------------------------------- */
HB_FUNC(HWG_CREATEACTIVEX)
{
   HWND hWndCtrl;

   _Ax_Init();

   hWndCtrl = CreateWindowEx(
      HB_ISNIL(1) ? 0 : (DWORD) hb_parni(1),                     // exStyle
      HB_ISNIL(2) ? TEXT("A3434_CLASS") : (LPCTSTR) HB_PARSTR(2), // class name
      HB_ISNIL(3) ? TEXT("") : (LPCTSTR) HB_PARSTR(3),            // window text (ProgID)
      HB_ISNIL(4) ? WS_OVERLAPPEDWINDOW : (DWORD) hb_parni(4),    // style
      HB_ISNIL(5) ? CW_USEDEFAULT : hb_parni(5),                  // x
      HB_ISNIL(6) ? CW_USEDEFAULT : hb_parni(6),                  // y
      HB_ISNIL(7) ? 544 : hb_parni(7),                            // width
      HB_ISNIL(8) ? 375 : hb_parni(8),                            // height
      HB_ISNIL(9) ? HWND_DESKTOP : (HWND) HB_PARHANDLE(9),        // parent
      NULL,                                                       // menu handle
      GetModuleHandle(NULL),                                      // instance
      NULL                                                        // lpParam
   );

   HB_RETHANDLE(hWndCtrl);
}

/* -------------------------------------------------------------------- */
/*  HWG_ATLAXGETDISP - Retrieve IDispatch interface from ActiveX       */
/* -------------------------------------------------------------------- */
HB_FUNC(HWG_ATLAXGETDISP)
{
   IUnknown  *pUnk = NULL;
   IDispatch *pDisp = NULL;
   HWND hCtrl = (HWND) HB_PARHANDLE(1);

   _Ax_Init();

   if (AtlAxGetControl && SUCCEEDED(AtlAxGetControl(hCtrl, &pUnk)) && pUnk)
   {
      HRESULT hr = pUnk->lpVtbl->QueryInterface(pUnk, &IID_IDispatch, (void**)&pDisp);
      pUnk->lpVtbl->Release(pUnk);

      if (SUCCEEDED(hr) && pDisp)
      {
         PHB_ITEM pItem = hb_itemNew(NULL);
         hb_oleItemPut(pItem, pDisp);
         hb_itemReturn(pItem);
         hb_itemRelease(pItem);
         pDisp->lpVtbl->Release(pDisp);   // hb_oleItemPut already AddRef'ed
         return;
      }
   }

   /* return NIL */
   hb_itemReturn(hb_itemNew(NULL));
}

/* -------------------------------------------------------------------- */
/*  Event Sink implementation (IEventHandler / IDispatch)               */
/* -------------------------------------------------------------------- */

/* Forward declaration of our event handler interface */
#undef  INTERFACE
#define INTERFACE IEventHandler

DECLARE_INTERFACE_(IEventHandler, IDispatch)
{
   /* IUnknown and IDispatch methods are inherited */
   STDMETHOD(QueryInterface)(THIS_ REFIID, void**) PURE;
   STDMETHOD_(ULONG, AddRef)(THIS) PURE;
   STDMETHOD_(ULONG, Release)(THIS) PURE;
   STDMETHOD_(ULONG, GetTypeInfoCount)(THIS_ UINT*) PURE;
   STDMETHOD_(ULONG, GetTypeInfo)(THIS_ UINT, LCID, ITypeInfo**) PURE;
   STDMETHOD_(ULONG, GetIDsOfNames)(THIS_ REFIID, LPOLESTR*, UINT, LCID, DISPID*) PURE;
   STDMETHOD_(ULONG, Invoke)(THIS_ DISPID, REFIID, LCID, WORD, DISPPARAMS*, VARIANT*, EXCEPINFO*, UINT*) PURE;
};

/* Real object structure (hidden from external apps) */
typedef struct
{
   IEventHandler *lpVtbl;      /* pointer to vtable */
   DWORD count;
   IConnectionPoint *pIConnectionPoint;
   DWORD dwEventCookie;
   IID device_event_interface_iid;
   PHB_ITEM pEvents;        /* array of event definitions */
   PHB_ITEM pEventsExec;    /* parallel array of executors */
} MyRealIEventHandler;

/* ------------------------------------------------------------- */
/*  IEventHandler implementation                                  */
/* ------------------------------------------------------------- */

static HRESULT STDMETHODCALLTYPE QueryInterface(IEventHandler *this, REFIID riid, void **ppv)
{
   MyRealIEventHandler *pThis = (MyRealIEventHandler*)this;
   if (IsEqualIID(riid, &IID_IUnknown) ||
       IsEqualIID(riid, &IID_IDispatch) ||
       IsEqualIID(riid, &(pThis->device_event_interface_iid)))
   {
      *ppv = this;
      this->lpVtbl->AddRef(this);
      return S_OK;
   }
   *ppv = NULL;
   return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE AddRef(IEventHandler *this)
{
   return ++((MyRealIEventHandler*)this)->count;
}

static ULONG STDMETHODCALLTYPE Release(IEventHandler *this)
{
   MyRealIEventHandler *pThis = (MyRealIEventHandler*)this;
   ULONG ref = --pThis->count;
   if (ref == 0)
   {
      /* Release Harbour items stored in the sink */
      if (pThis->pEvents)
         hb_itemRelease(pThis->pEvents);
      if (pThis->pEventsExec)
         hb_itemRelease(pThis->pEventsExec);
      hb_xfree(pThis);
   }
   return ref;
}

static ULONG STDMETHODCALLTYPE GetTypeInfoCount(IEventHandler *this, UINT *pCount)
{
   HB_SYMBOL_UNUSED(this);
   HB_SYMBOL_UNUSED(pCount);
   return E_NOTIMPL;
}

static ULONG STDMETHODCALLTYPE GetTypeInfo(IEventHandler *this, UINT itinfo, LCID lcid, ITypeInfo **pTypeInfo)
{
   HB_SYMBOL_UNUSED(this);
   HB_SYMBOL_UNUSED(itinfo);
   HB_SYMBOL_UNUSED(lcid);
   HB_SYMBOL_UNUSED(pTypeInfo);
   return E_NOTIMPL;
}

static ULONG STDMETHODCALLTYPE GetIDsOfNames(IEventHandler *this, REFIID riid, LPOLESTR *rgszNames,
                                              UINT cNames, LCID lcid, DISPID *rgdispid)
{
   HB_SYMBOL_UNUSED(this);
   HB_SYMBOL_UNUSED(riid);
   HB_SYMBOL_UNUSED(rgszNames);
   HB_SYMBOL_UNUSED(cNames);
   HB_SYMBOL_UNUSED(lcid);
   HB_SYMBOL_UNUSED(rgdispid);
   return E_NOTIMPL;
}

static ULONG STDMETHODCALLTYPE Invoke(IEventHandler *this, DISPID dispid, REFIID riid,
                                      LCID lcid, WORD wFlags, DISPPARAMS *params,
                                      VARIANT *result, EXCEPINFO *pexcepinfo, UINT *puArgErr)
{
   MyRealIEventHandler *pThis = (MyRealIEventHandler*)this;
   PHB_ITEM pExec = NULL;
   PHB_ITEM *pItemArray = NULL;
   int iArg, i;
   PHB_ITEM Key = NULL;
   ULONG ulPos;

   HB_SYMBOL_UNUSED(riid);
   HB_SYMBOL_UNUSED(lcid);
   HB_SYMBOL_UNUSED(wFlags);
   HB_SYMBOL_UNUSED(result);
   HB_SYMBOL_UNUSED(pexcepinfo);
   HB_SYMBOL_UNUSED(puArgErr);

   if (!IsEqualIID(riid, &IID_NULL))
      return DISP_E_UNKNOWNINTERFACE;

   /* Lookup event by DISPID in the array */
   Key = hb_itemNew(NULL);
   hb_itemPutNL(Key, dispid);
   ulPos = hb_arrayScan(pThis->pEvents, Key, NULL, NULL, 0);
   hb_itemRelease(Key);

   if (ulPos)
   {
      PHB_ITEM pArray = hb_arrayGetItemPtr(pThis->pEventsExec, ulPos);
      if (pArray)
         pExec = hb_arrayGetItemPtr(pArray, 1);
   }

   if (!pExec)
      return S_OK;   /* event not handled */

   /* Prepare Harbour call */
   if (hb_vmRequestReenter())
   {
      /* Push function/block to execute */
      switch (hb_itemType(pExec))
      {
         case HB_IT_BLOCK:
            hb_vmPushSymbol(&hb_symEval);
            hb_vmPush(pExec);
            break;
         case HB_IT_STRING:
         {
            PHB_ITEM pObject = NULL;
            PHB_ITEM pArray = hb_arrayGetItemPtr(pThis->pEventsExec, ulPos);
            if (pArray)
               pObject = hb_arrayGetItemPtr(pArray, 2);

            hb_vmPushSymbol(hb_dynsymSymbol(hb_dynsymFindName(hb_itemGetCPtr(pExec))));
            if (HB_IS_OBJECT(pObject))
               hb_vmPush(pObject);
            else
               hb_vmPushNil();
            break;
         }
         case HB_IT_POINTER:
            hb_vmPushSymbol(((PHB_SYMB)pExec)->pDynSym->pSymbol);
            hb_vmPushNil();
            break;
         default:
            hb_vmRequestRestore();
            return S_OK;
      }

      /* Push arguments from DISPPARAMS - manual loop (no hb_itemPushList) */
      iArg = params->cArgs;
      if (iArg > 0)
      {
         pItemArray = (PHB_ITEM*) hb_xgrab(iArg * sizeof(PHB_ITEM));
         for (i = 0; i < iArg; i++)
         {
            pItemArray[i] = hb_itemNew(NULL);
            hb_oleVariantToItem(pItemArray[i], &(params->rgvarg[iArg - 1 - i]));
            /* push each argument */
            hb_vmPush(pItemArray[i]);
         }
      }

      /* Execute Harbour code */
      hb_vmDo((USHORT)iArg);

      /* Return by-reference parameters (simple types only) using VARIANT macros */
      for (i = 0; i < iArg; i++)
      {
         VARIANT *pVar = &(params->rgvarg[iArg - 1 - i]);
         if (V_VT(pVar) & VT_BYREF)
         {
            PHB_ITEM pItem = pItemArray[i];
            switch (V_VT(pVar) & ~VT_BYREF)
            {
               case VT_I2:  *V_I2REF(pVar) = (SHORT) hb_itemGetNI(pItem); break;
               case VT_I4:  *V_I4REF(pVar) = (LONG) hb_itemGetNL(pItem); break;
               case VT_R4:  *V_R4REF(pVar) = (FLOAT) hb_itemGetND(pItem); break;
               case VT_R8:  *V_R8REF(pVar) = (DOUBLE) hb_itemGetND(pItem); break;
               case VT_BOOL: *V_BOOLREF(pVar) = hb_itemGetL(pItem) ? VARIANT_TRUE : VARIANT_FALSE; break;
               default: break;
            }
         }
      }

      /* Release arguments */
      if (pItemArray)
      {
         for (i = 0; i < iArg; i++)
            hb_itemRelease(pItemArray[i]);
         hb_xfree(pItemArray);
      }

      hb_vmRequestRestore();
   }

   return S_OK;
}

/* VTable for IEventHandler */
static const IEventHandlerVtbl IEventHandler_Vtbl = {
   QueryInterface,
   AddRef,
   Release,
   GetTypeInfoCount,
   GetTypeInfo,
   GetIDsOfNames,
   Invoke
};

/* -------------------------------------------------------------------- */
/*  HWG_SETUPCONNECTIONPOINT - Connect event sink to ActiveX            */
/* -------------------------------------------------------------------- */
HB_FUNC(HWG_SETUPCONNECTIONPOINT)
{
   IConnectionPointContainer *pContainer = NULL;
   IUnknown *pUnk = NULL;
   IConnectionPoint *pPoint = NULL;
   IEnumConnectionPoints *pEnum = NULL;
   HRESULT hr = E_FAIL;
   IID iid = IID_IDispatch;
   IEventHandler *pSink = NULL;
   MyRealIEventHandler *pReal = NULL;
   DWORD dwCookie = 0;

   IDispatch *pDisp = hb_oleItemGet(hb_param(1, HB_IT_ANY));

   if (!pDisp)
   {
      hb_retnl(E_POINTER);
      return;
   }

   /* Allocate our event sink object */
   pReal = (MyRealIEventHandler*) hb_xgrab(sizeof(MyRealIEventHandler));
   if (!pReal)
   {
      hb_retnl(E_OUTOFMEMORY);
      return;
   }
   memset(pReal, 0, sizeof(MyRealIEventHandler));
   pReal->lpVtbl = (IEventHandler*)&IEventHandler_Vtbl;
   pReal->count = 1;   /* initial reference */
   pReal->device_event_interface_iid = IID_IDispatch;

   pSink = (IEventHandler*)pReal;

   /* Query sink for IUnknown */
   hr = pSink->lpVtbl->QueryInterface(pSink, &IID_IUnknown, (void**)&pUnk);
   if (FAILED(hr) || !pUnk)
      goto cleanup;

   /* Get connection point container from ActiveX object */
   hr = pDisp->lpVtbl->QueryInterface(pDisp, &IID_IConnectionPointContainer, (void**)&pContainer);
   if (FAILED(hr) || !pContainer)
      goto cleanup;

   /* Enumerate connection points to find matching IID */
   hr = pContainer->lpVtbl->EnumConnectionPoints(pContainer, &pEnum);
   if (SUCCEEDED(hr) && pEnum)
   {
      while (pEnum->lpVtbl->Next(pEnum, 1, &pPoint, NULL) == S_OK)
      {
         if (pPoint->lpVtbl->GetConnectionInterface(pPoint, &iid) == S_OK)
         {
            /* We accept any connection point – the sink will filter events by DISPID */
            break;
         }
         pPoint->lpVtbl->Release(pPoint);
         pPoint = NULL;
      }
      pEnum->lpVtbl->Release(pEnum);
   }

   /* If no point found, try FindConnectionPoint with IDispatch */
   if (!pPoint)
   {
      hr = pContainer->lpVtbl->FindConnectionPoint(pContainer, &IID_IDispatch, &pPoint);
      if (FAILED(hr) || !pPoint)
         goto cleanup;
   }

   /* Store event information */
   pReal->pIConnectionPoint = pPoint;
   pReal->device_event_interface_iid = iid;

   /* Advise connection */
   hr = pPoint->lpVtbl->Advise(pPoint, pUnk, &dwCookie);
   if (FAILED(hr))
      goto cleanup;

   pReal->dwEventCookie = dwCookie;

   /* Store Harbour event tables (arrays) */
   pReal->pEvents = hb_itemNew(hb_param(3, HB_IT_ANY));
   pReal->pEventsExec = hb_itemNew(hb_param(4, HB_IT_ANY));

   /* Return sink handle to Harbour */
   HB_STOREHANDLE(pReal, 2);
   hr = S_OK;

cleanup:
   if (pContainer) pContainer->lpVtbl->Release(pContainer);
   if (pUnk) pUnk->lpVtbl->Release(pUnk);
   if (FAILED(hr))
   {
      if (pPoint) pPoint->lpVtbl->Release(pPoint);
      if (pReal) hb_xfree(pReal);
   }

   hb_retnl(hr);
}

/* -------------------------------------------------------------------- */
/*  HWG_SHUTDOWNCONNECTIONPOINT - Disconnect event sink                 */
/* -------------------------------------------------------------------- */
HB_FUNC(HWG_SHUTDOWNCONNECTIONPOINT)
{
   MyRealIEventHandler *pThis = (MyRealIEventHandler*) HB_PARHANDLE(1);
   if (pThis)
   {
      if (pThis->pIConnectionPoint)
      {
         if (pThis->dwEventCookie)
            pThis->pIConnectionPoint->lpVtbl->Unadvise(pThis->pIConnectionPoint, pThis->dwEventCookie);
         pThis->pIConnectionPoint->lpVtbl->Release(pThis->pIConnectionPoint);
         pThis->pIConnectionPoint = NULL;
         pThis->dwEventCookie = 0;
      }
      /* The Harbour object still holds the handle; it will be released via Release() */
   }
}

/* -------------------------------------------------------------------- */
/*  HWG_RELEASEDISPATCH - Release an IDispatch object                   */
/* -------------------------------------------------------------------- */
HB_FUNC(HWG_RELEASEDISPATCH)
{
   IDispatch *pObj = hb_oleItemGet(hb_param(1, HB_IT_ANY));
   if (pObj)
      pObj->lpVtbl->Release(pObj);
}