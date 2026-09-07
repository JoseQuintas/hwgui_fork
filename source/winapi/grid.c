/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGrid class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
 * Extended function Copyright 2006 Luiz Rafael Culik Guimaraes <luiz@xharbour.com.br>
 */

#include "hwingui.h"
#include <commctrl.h>

/* REMOVED: Obsolete compiler support
 * #if defined(__POCC__) || defined(__XCC__)
 * #include <unknwn.h>
 * #endif
 * #if defined(__DMC__)
 * #include "missing.h"
 * #endif
 */

#include <shlobj.h>
#include "hbapiitm.h"

#if ( defined(__MINGW32__) || defined(__MINGW64__) ) && !defined(CDRF_NOTIFYSUBITEMDRAW)
#define CDRF_NOTIFYSUBITEMDRAW  0x00000020
#endif

#ifndef LVM_SORTITEMSEX
#define LVM_SORTITEMSEX          (LVM_FIRST + 81)
#endif

#ifndef ListView_SortItemsEx
#define ListView_SortItemsEx(hwndLV, _pfnCompare, _lPrm) \
  (BOOL)SNDMSG((hwndLV), LVM_SORTITEMSEX, (WPARAM)(LPARAM)(_lPrm), (LPARAM)(PFNLVCOMPARE)(_pfnCompare))
#endif

typedef struct tagSortInfo
{
   HWND pListControl;
   int nColumnNo;
   BOOL nAscendingSortOrder;
} SortInfo, *PSORTINFO;

LRESULT ProcessCustomDraw( LPARAM lParam, PHB_ITEM pColor );

/*=============================================================================
 * HWG_LISTVIEW_CREATE()
 * Creates a ListView control
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_CREATE )
{
   HWND hwnd = ( HWND ) HB_PARHANDLE( 1 );
   HWND handle;
   int style = LVS_SHOWSELALWAYS | hb_parni( 7 );

   if( hb_parl( 8 ) )
      style = style | LVS_NOCOLUMNHEADER;

   if( hb_parl( 9 ) )
      style = style | LVS_NOSCROLL;

   handle = CreateWindowEx( WS_EX_CLIENTEDGE, WC_LISTVIEW, NULL,
         style,
         hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ),
         hwnd, ( HMENU )(UINT_PTR) hb_parni( 2 ), GetModuleHandle( NULL ), NULL );

   HB_RETHANDLE( handle );
}

/*=============================================================================
 * HWG_LISTVIEW_INIT()
 * Initializes ListView extended styles
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_INIT )
{
   int style = 0;

   if( !hb_parl( 3 ) )
      style = style | LVS_EX_GRIDLINES;

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ),
         LVM_SETEXTENDEDLISTVIEWSTYLE, 0,
         LVS_EX_FULLROWSELECT |
         LVS_EX_HEADERDRAGDROP | LVS_EX_FLATSB | style );

   ListView_SetItemCount( ( HWND ) HB_PARHANDLE( 1 ), hb_parnl( 2 ) );
}

/*=============================================================================
 * HWG_LISTVIEW_SETITEMCOUNT()
 * Sets item count
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_SETITEMCOUNT )
{
   ListView_SetItemCount( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) );
}

/*=============================================================================
 * HWG_LISTVIEW_ADDCOLUMN()
 * Adds a column to ListView
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_ADDCOLUMN )
{
   LV_COLUMN COL;
   int iImage = hb_parni( 6 );
   void *hText;

   COL.mask = LVCF_WIDTH | LVCF_TEXT | LVCF_FMT | LVCF_SUBITEM;
   COL.cx = hb_parni( 3 );
   /* FIXED: HB_PARSTRDEF -> HB_PARSTR for Unicode support */
   COL.pszText = ( LPTSTR ) HB_PARSTR( 4, &hText, NULL );
   COL.iSubItem = hb_parni( 2 ) - 1;
   COL.fmt = hb_parni( 5 );
   if( iImage > 0 )
   {
      COL.mask = COL.mask | LVCF_IMAGE;
      COL.iImage = hb_parni( 2 ) - 1;
   }
   else
      COL.iImage = -1;

   ListView_InsertColumn( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) - 1,
         &COL );

   RedrawWindow( ( HWND ) HB_PARHANDLE( 1 ), NULL, NULL,
         RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW |
         RDW_UPDATENOW );
   hb_strfree( hText );
}

/*=============================================================================
 * HWG_LISTVIEW_DELETECOLUMN()
 * Deletes a column
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_DELETECOLUMN )
{
   ListView_DeleteColumn( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) - 1 );
   RedrawWindow( ( HWND ) HB_PARHANDLE( 1 ), NULL, NULL,
         RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW |
         RDW_UPDATENOW );
}

/*=============================================================================
 * HWG_LISTVIEW_SETBKCOLOR()
 * Sets background color
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_SETBKCOLOR )
{
   ListView_SetBkColor( ( HWND ) HB_PARHANDLE( 1 ),
         ( COLORREF ) hb_parni( 2 ) );
}

/*=============================================================================
 * HWG_LISTVIEW_SETTEXTBKCOLOR()
 * Sets text background color
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_SETTEXTBKCOLOR )
{
   ListView_SetTextBkColor( ( HWND ) HB_PARHANDLE( 1 ),
         ( COLORREF ) hb_parni( 2 ) );
}

/*=============================================================================
 * HWG_LISTVIEW_SETTEXTCOLOR()
 * Sets text color
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_SETTEXTCOLOR )
{
   ListView_SetTextColor( ( HWND ) HB_PARHANDLE( 1 ),
         ( COLORREF ) hb_parni( 2 ) );
}

/*=============================================================================
 * HWG_LISTVIEW_GETFIRSTITEM()
 * Gets first selected item
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_GETFIRSTITEM )
{
   hb_retni( ListView_GetNextItem( ( HWND ) HB_PARHANDLE( 1 ), -1,
               LVNI_ALL | LVNI_SELECTED ) + 1 );
}

/*=============================================================================
 * HWG_LISTVIEW_GETDISPINFO()
 * Gets display info from notification
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_GETDISPINFO )
{
   LV_DISPINFO *pDispInfo = ( LV_DISPINFO * ) HB_PARHANDLE( 1 );

   int iItem = pDispInfo->item.iItem;
   int iSubItem = pDispInfo->item.iSubItem;

   hb_reta( 2 );
   hb_storvni( iItem + 1, -1, 1 );
   hb_storvni( iSubItem + 1, -1, 2 );
}

/*=============================================================================
 * HWG_LISTVIEW_SETDISPINFO()
 * Sets display info from notification
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_SETDISPINFO )
{
   LV_DISPINFO *pDispInfo = ( LV_DISPINFO * ) HB_PARHANDLE( 1 );

   if( pDispInfo->item.mask & LVIF_TEXT )
   {
      HB_ITEMCOPYSTR( hb_param( 2, HB_IT_ANY ), pDispInfo->item.pszText,
            pDispInfo->item.cchTextMax );
      pDispInfo->item.pszText[pDispInfo->item.cchTextMax - 1] = 0;
   }
   if( pDispInfo->item.iSubItem == 0 )
      pDispInfo->item.state = 2;
}

/*=============================================================================
 * HWG_LISTVIEW_GETGRIDKEY()
 * Gets key from LV_KEYDOWN notification
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_GETGRIDKEY )
{
#define pnm ((LV_KEYDOWN *) HB_PARHANDLE(1) )
   hb_retnl( ( LPARAM ) ( pnm->wVKey ) );
#undef pnm
}

/*=============================================================================
 * HWG_LISTVIEW_GETTOPINDEX()
 * Gets top visible index
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_GETTOPINDEX )
{
   hb_retnl( ListView_GetTopIndex( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_LISTVIEW_REDRAWITEMS()
 * Redraws items range
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_REDRAWITEMS )
{
   hb_retnl( ListView_RedrawItems( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ),
               hb_parni( 3 ) ) );
}

/*=============================================================================
 * HWG_LISTVIEW_GETCOUNTPERPAGE()
 * Gets items per page
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_GETCOUNTPERPAGE )
{
   hb_retnl( ListView_GetCountPerPage( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_LISTVIEW_UPDATE()
 * Updates an item
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_UPDATE )
{
   ListView_Update( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) - 1 );
}

/*=============================================================================
 * HWG_LISTVIEW_SCROLL()
 * Scrolls ListView
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_SCROLL )
{
   ListView_Scroll( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) - 1,
         hb_parni( 3 ) - 1 );
}

/*=============================================================================
 * HWG_LISTVIEW_HITTEST()
 * Hit test on ListView
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_HITTEST )
{
   POINT point;
   LVHITTESTINFO lvhti;

   point.y = hb_parni( 2 );
   point.x = hb_parni( 3 );

   lvhti.pt = point;

   ListView_SubItemHitTest( ( HWND ) HB_PARHANDLE( 1 ), &lvhti );

   if( lvhti.flags & LVHT_ONITEM )
   {
      hb_reta( 2 );
      hb_storvni( lvhti.iItem + 1, -1, 1 );
      hb_storvni( lvhti.iSubItem + 1, -1, 2 );
   }
   else
   {
      hb_reta( 2 );
      hb_storvni( 0, -1, 1 );
      hb_storvni( 0, -1, 2 );
   }
}

/*=============================================================================
 * HWG_LISTVIEW_SETIMAGELIST()
 * Sets image list
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_SETIMAGELIST )
{
   HWND hList = ( HWND ) HB_PARHANDLE( 1 );
   HIMAGELIST p = ( HIMAGELIST ) HB_PARHANDLE( 2 );

   SendMessage( hList, LVM_SETIMAGELIST, ( WPARAM ) p,
         ( LPARAM ) LVSIL_NORMAL );
   SendMessage( hList, LVM_SETIMAGELIST, ( WPARAM ) p,
         ( LPARAM ) LVSIL_SMALL );
}

/*=============================================================================
 * HWG_LISTVIEW_SETVIEW()
 * Sets view style
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_SETVIEW )
{
   HWND hWndListView = ( HWND ) HB_PARHANDLE( 1 );
   DWORD dwView = hb_parnl( 2 );
   DWORD dwStyle = GetWindowLong( hWndListView, GWL_STYLE );

   if( ( dwStyle & LVS_TYPEMASK ) != dwView )
   {
      SetWindowLongPtr( hWndListView,
            GWL_STYLE, ( dwStyle & ~LVS_TYPEMASK ) | dwView );
   }
}

/*=============================================================================
 * HWG_LISTVIEW_ADDCOLUMNEX()
 * Adds a column with extended options
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_ADDCOLUMNEX )
{
   HWND hwndListView = ( HWND ) HB_PARHANDLE( 1 );
   LONG lCol = hb_parnl( 2 ) - 1;
   void *hText;
   int iImage = hb_parni( 6 );
   LVCOLUMN lvcolumn;
   int iResult;

   memset( &lvcolumn, 0, sizeof( lvcolumn ) );

   if( iImage > 0 )
      lvcolumn.mask = LVCF_FMT | LVCF_TEXT | LVCF_SUBITEM | LVCF_IMAGE | LVCF_WIDTH;
   else
      lvcolumn.mask = LVCF_FMT | LVCF_TEXT | LVCF_SUBITEM | LVCF_WIDTH;

   /* FIXED: HB_PARSTRDEF -> HB_PARSTR for Unicode support */
   lvcolumn.pszText = ( LPTSTR ) HB_PARSTR( 3, &hText, NULL );
   lvcolumn.iSubItem = lCol;
   lvcolumn.cx = hb_parni( 4 );
   lvcolumn.fmt = hb_parni( 5 );
   lvcolumn.iImage = iImage > 0 ? lCol : -1;

   if( SendMessage( ( HWND ) hwndListView, ( UINT ) LVM_INSERTCOLUMN,
               ( WPARAM ) ( int ) lCol, ( LPARAM ) & lvcolumn ) == -1 )
      iResult = 0;
   else
      iResult = 1;

   RedrawWindow( hwndListView, NULL, NULL,
         RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW |
         RDW_UPDATENOW );

   hb_retnl( iResult );
   hb_strfree( hText );
}

/*=============================================================================
 * HWG_LISTVIEW_INSERTITEMEX()
 * Inserts an item
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEW_INSERTITEMEX )
{
   HWND hwndListView = ( HWND ) HB_PARHANDLE( 1 );
   LONG lLin = hb_parnl( 2 ) - 1;
   LONG lCol = hb_parnl( 3 ) - 1;
   int iSubItemYesNo = lCol == 0 ? 0 : 1;
   void *hText;
   int iBitMap = hb_parni( 5 );
   LVITEM lvi;
   int iResult = 0;
   RECT rect;

   GetClientRect( hwndListView, &rect );

   memset( &lvi, 0, sizeof( lvi ) );

   if( iBitMap >= 0 )
      lvi.mask = LVIF_TEXT | LVIF_IMAGE | LVIF_STATE;
   else
      lvi.mask = LVIF_TEXT | LVIF_STATE;

   lvi.iImage = iBitMap >= 0 ? lCol : -1;
   lvi.state = 0;
   lvi.stateMask = 0;
   /* FIXED: HB_PARSTRDEF -> HB_PARSTR for Unicode support */
   lvi.pszText = ( LPTSTR ) HB_PARSTR( 4, &hText, NULL );
   lvi.iItem = lLin;
   lvi.iSubItem = lCol;

   switch ( iSubItemYesNo )
   {
      case 0:
         if( SendMessage( ( HWND ) hwndListView, ( UINT ) LVM_INSERTITEM,
                     ( WPARAM ) 0, ( LPARAM ) & lvi ) == -1 )
            iResult = 0;
         else
            iResult = 1;
         break;

      case 1:
         if( SendMessage( ( HWND ) hwndListView, ( UINT ) LVM_SETITEM,
                     ( WPARAM ) 0, ( LPARAM ) & lvi ) == FALSE )
            iResult = 0;
         else
            iResult = 1;
         break;
   }

   InvalidateRect( hwndListView, &rect, TRUE );
   hb_retni( iResult );
   hb_strfree( hText );
}

/*=============================================================================
 * HWG_LISTVIEWSELECTALL()
 * Selects all items
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEWSELECTALL )
{
   HWND hList = ( HWND ) HB_PARHANDLE( 1 );

   ListView_SetItemState( hList, -1, 0, LVIS_SELECTED );
   SendMessage( hList, LVM_ENSUREVISIBLE, ( WPARAM ) - 1, FALSE );
   ListView_SetItemState( hList, -1, LVIS_SELECTED, LVIS_SELECTED );
   hb_retl( 1 );
}

/*=============================================================================
 * HWG_LISTVIEWSELECTLASTITEM()
 * Selects last item
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEWSELECTLASTITEM )
{
   HWND hList = ( HWND ) HB_PARHANDLE( 1 );
   int items;

   items = SendMessage( hList, LVM_GETITEMCOUNT, ( WPARAM ) 0, ( LPARAM ) 0 );
   items--;
   ListView_SetItemState( hList, -1, 0, LVIS_SELECTED );
   SendMessage( hList, LVM_ENSUREVISIBLE, ( WPARAM ) items, FALSE );
   ListView_SetItemState( hList, items, LVIS_SELECTED, LVIS_SELECTED );
   ListView_SetItemState( hList, items, LVIS_FOCUSED, LVIS_FOCUSED );
   hb_retl( 1 );
}

/*=============================================================================
 * ProcessCustomDraw()
 * Processes custom draw notification
 *===========================================================================*/
LRESULT ProcessCustomDraw( LPARAM lParam, PHB_ITEM pArray )
{
   LPNMLVCUSTOMDRAW lplvcd = ( LPNMLVCUSTOMDRAW ) lParam;
   PHB_ITEM pColor;

   switch ( lplvcd->nmcd.dwDrawStage )
   {
      case CDDS_PREPAINT:
         return CDRF_NOTIFYITEMDRAW;

      case CDDS_ITEMPREPAINT:
         return CDRF_NOTIFYSUBITEMDRAW;

      case CDDS_SUBITEM | CDDS_ITEMPREPAINT:
         /* FIXED: Added validation before accessing array */
         pColor = hb_arrayGetItemPtr( pArray, lplvcd->iSubItem + 1 );
         if( pColor && HB_IS_ARRAY( pColor ) && hb_arrayLen( pColor ) >= 2 )
         {
            COLORREF ColorText = ( COLORREF ) hb_arrayGetNL( pColor, 1 );
            COLORREF ColorBack = ( COLORREF ) hb_arrayGetNL( pColor, 2 );
            lplvcd->clrText = ColorText;
            lplvcd->clrTextBk = ColorBack;
            return CDRF_NEWFONT;
         }
         return CDRF_DODEFAULT;
   }
   return CDRF_DODEFAULT;
}

/*=============================================================================
 * HWG_PROCESSCUSTU()
 * Calls ProcessCustomDraw from Harbour
 *===========================================================================*/
HB_FUNC( HWG_PROCESSCUSTU )
{
   LPARAM lParam = ( LPARAM ) HB_PARHANDLE( 2 );
   PHB_ITEM pColor = hb_param( 3, HB_IT_ARRAY );

   hb_retnl( ( LONG ) ProcessCustomDraw( lParam, pColor ) );
}

/*=============================================================================
 * HWG_LISTVIEWGETITEM()
 * Gets item text
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEWGETITEM )
{
   HWND hList = ( HWND ) HB_PARHANDLE( 1 );
   int Index = hb_parni( 2 );
   int Index2 = hb_parni( 3 );
   LVITEM Item;
   TCHAR Buffer[256] = { 0 };

   memset( &Item, '\0', sizeof( Item ) );

   Item.mask = LVIF_TEXT | LVIF_PARAM;
   Item.iItem = Index;
   Item.iSubItem = Index2;
   Item.pszText = Buffer;
   Item.cchTextMax = HB_SIZEOFARRAY( Buffer );

   if( ListView_GetItem( hList, &Item ) )
      HB_RETSTR( Buffer );
   else
      hb_retc( NULL );
}

/*=============================================================================
 * CompareFunc()
 * Comparison function for sorting
 *===========================================================================*/
int CALLBACK CompareFunc( LPARAM lParam1, LPARAM lParam2, LPARAM lParamSort )
{
   PSORTINFO pSortInfo = ( PSORTINFO ) lParamSort;
   int nColumnNo = pSortInfo->nColumnNo;
   HWND pListControl = pSortInfo->pListControl;
   BOOL nAscendingSortOrder = pSortInfo->nAscendingSortOrder;
   TCHAR szA[256] = { 0 };
   TCHAR szB[256] = { 0 };
   int rc;

   ListView_GetItemText( pListControl, ( INT ) lParam1, nColumnNo, szA,
         HB_SIZEOFARRAY( szA ) );
   ListView_GetItemText( pListControl, ( INT ) lParam2, nColumnNo, szB,
         HB_SIZEOFARRAY( szB ) );

   /* FIXED: Use lstrcmpi for case-insensitive, or wcscmp for Unicode */
#ifdef UNICODE
   rc = wcscmp( szA, szB );
#else
   rc = lstrcmp( szA, szB );
#endif

   if( !nAscendingSortOrder )
      rc = -rc;

   return rc;
}

/*=============================================================================
 * HWG_LISTVIEWSORTINFONEW()
 * Creates a new SortInfo structure
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEWSORTINFONEW )
{
   PSORTINFO p;

   /* FIXED: Removed incorrect HB_ISPOINTER check */
   p = ( PSORTINFO ) hb_xgrab( sizeof( SortInfo ) );

   if( p )
   {
      p->pListControl = NULL;
      p->nColumnNo = -1;
      p->nAscendingSortOrder = FALSE;
   }
   hb_retptr( ( void * ) p );
}

/*=============================================================================
 * HWG_LISTVIEWSORTINFOFREE()
 * Frees a SortInfo structure
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEWSORTINFOFREE )
{
   PSORTINFO p = ( PSORTINFO ) hb_parptr( 3 );

   if( p )
      hb_xfree( p );
}

/*=============================================================================
 * HWG_LISTVIEWSORT()
 * Sorts ListView items
 *===========================================================================*/
HB_FUNC( HWG_LISTVIEWSORT )
{
   PSORTINFO p = ( PSORTINFO ) hb_parptr( 3 );
   LPNMLISTVIEW phdNotify = ( LPNMLISTVIEW ) HB_PARHANDLE( 2 );

   if( phdNotify->iSubItem == p->nColumnNo )
      p->nAscendingSortOrder = !p->nAscendingSortOrder;
   else
      p->nAscendingSortOrder = TRUE;

   p->nColumnNo = phdNotify->iSubItem;
   p->pListControl = ( HWND ) HB_PARHANDLE( 1 );
   ListView_SortItemsEx( ( HWND ) HB_PARHANDLE( 1 ), CompareFunc, p );
}

/* ========================= EOF of grid.c ======================== */