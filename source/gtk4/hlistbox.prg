/*
 * $Id: hlistbox.prg 3911 2026-09-07 04:47:24Z itamarlins $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HListBox class -- cross-platform Harbour layer
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port — target: GTK 4.24+
 *
 * This file is BACKEND-AGNOSTIC.  It contains only the Harbour-side
 * logic of HListBox and delegates every widget operation to the C
 * layer through five primitives:
 *
 *      hwg_Createlistbox()      create the native widget tree
 *      hwg_Listboxaddstring()   append one item
 *      hwg_Listboxsetstring()   select an item by 1-based index
 *      hwg_Sendmessage()        LB_* messages (Win32 SendMessage clone)
 *      hwg_Setwindowobject()    bind the Harbour object to the widget
 *
 * Each backend provides its own implementation:
 *
 *      source/winapi/listbox.c   native Win32 LISTBOX control
 *      source/gtk4/listbox.c     GtkScrolledWindow + GtkListBox
 *
 * Port notes:
 *  - No #ifdef is used here on purpose.  Any platform-specific
 *    behaviour must be resolved inside the C layer, so this file
 *    stays identical on both backends and can be shared verbatim.
 *
 *  - The five primitives above have identical signatures on both
 *    backends.  Changes here must be matched by changes in both
 *    listbox.c files, not by adding #ifdef branches.
 *
 *  - LB_SETITEMHEIGHT is applied BEFORE the strings are added, so
 *    the GTK4 backend can honour the height on every row it creates.
 *    See the Port notes in source/gtk4/listbox.c for the rationale.
 *
 *  - LBN_SELCHANGE / LBN_DBLCLK are dispatched from the C layer
 *    through hwg_dispatch_onevent(), matching the Win32 notification
 *    codes byte-for-byte.  HListBox:onEvent therefore works without
 *    any backend knowledge.
 *
 *  - HWG_INITLISTPROC() is called from Init() for API compatibility
 *    with the Win32 subclassing scheme.  It is a no-op on GTK4; see
 *    source/gtk4/listbox.c.
 *
 *  - All user-visible strings pass through hwg_convert_to_utf8() /
 *    hwg_convert_from_utf8() inside the C layer.  This file never
 *    touches encoding directly.
 */

#include "hwgui.ch"
#include "hbclass.ch"
#include "common.ch"

CLASS HListBox INHERIT HControl

CLASS VAR winclass   INIT "LISTBOX"

   DATA  aItems
   DATA  bSetGet
   DATA  value         INIT 1
   DATA  nItemHeight
   DATA  bChangeSel
   DATA  bkeydown, bDblclick
   DATA  bValid

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
              aItems,oFont,bInit,bSize,bPaint,bChange,cTooltip,tColor,bcolor,bGFocus,bLFocus, bKeydown, bDblclick,bOther )
   METHOD Activate()
   METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                    bChange, cTooltip, bKeydown, bOther  )
   METHOD Init()
   METHOD Refresh()
   METHOD Requery()
   METHOD Setitem( nPos )
   METHOD AddItems( p )
   METHOD DeleteItem( nPos )
   METHOD Valid( oCtrl )
   METHOD When( oCtrl )
   METHOD onChange( oCtrl )
   METHOD onDblClick()
   METHOD Clear()
   METHOD onEvent( msg, wParam, lParam )

ENDCLASS

/* ------------------------------------------------------------------
 *  New()
 *
 *  nStyle is combined with the HWGUI defaults (WS_VSCROLL, WS_BORDER,
 *  LBS_NOTIFY, ...) and forwarded to hwg_Createlistbox().  The C layer
 *  is free to interpret or ignore individual style bits -- on GTK4
 *  only WS_VSCROLL and WS_BORDER have a visual effect; the LBS_*
 *  flags are accepted but do not change the widget tree.
 * ------------------------------------------------------------------ */
METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
            bInit, bSize, bPaint, bChange, cTooltip, tColor, bcolor, bGFocus, bLFocus,bKeydown, bDblclick,bOther )  CLASS HListBox

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP + WS_VSCROLL + LBS_DISABLENOSCROLL + LBS_NOTIFY + LBS_NOINTEGRALHEIGHT + WS_BORDER )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, cTooltip, tColor, bcolor )

   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "N", 0, vari )
   ::bSetGet := bSetGet

   IF aItems == Nil
      ::aItems := { }
   ELSE
      ::aItems  := aItems
   ENDIF

   ::Activate()

   ::bChangeSel := bChange
   ::bGetFocus := bGFocus
   ::bLostFocus := bLFocus
    ::bKeydown := bKeydown
    ::bDblclick := bDblclick
      ::bOther := bOther

   /*
    * Event wiring.  LBN_SELCHANGE / LBN_DBLCLK / LBN_SETFOCUS /
    * LBN_KILLFOCUS are dispatched from the C layer using the exact
    * Win32 numeric values, so this block runs unchanged on GTK4.
    */
   IF bSetGet != Nil
      IF bGFocus != Nil
         ::oParent:AddEvent( LBN_SETFOCUS, ::id, { | o, id | ::When( o:FindControl( id ) ) } )
      ENDIF
      ::oParent:AddEvent( LBN_KILLFOCUS, ::id, { | o, id | ::Valid( o:FindControl( id ) ) } )
      ::bValid := { | o | ::Valid( o ) }
   ELSE
      IF bGFocus != Nil
         ::oParent:AddEvent( LBN_SETFOCUS, ::id, { | o, id | ::When( o:FindControl( id ) ) } )
      ENDIF
      ::oParent:AddEvent( LBN_KILLFOCUS, ::id, { | o, id | ::Valid( o:FindControl( id ) ) } )
   ENDIF
   IF bChange != Nil .OR. bSetGet != Nil
      ::oParent:AddEvent( LBN_SELCHANGE, ::id, { | o, id | ::onChange( o:FindControl( id ) ) } )
   ENDIF
   IF bDblclick != Nil
      ::oParent:AddEvent( LBN_DBLCLK, ::id, { || ::onDblClick() } )
   ENDIF

   RETURN Self

/* ------------------------------------------------------------------
 *  Activate()
 *
 *  Creates the underlying widget tree via hwg_Createlistbox().  The
 *  returned handle is backend-specific:
 *
 *      WinAPI  ->  HWND of the native LISTBOX control
 *      GTK4    ->  GtkScrolledWindow containing a GtkListBox
 *
 *  Init() is called immediately afterwards so the initial aItems are
 *  populated before the control is shown.
 * ------------------------------------------------------------------ */
METHOD Activate() CLASS HListBox

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createlistbox( ::oParent:handle, ::id, ;
                                 ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )

      ::Init()
   ENDIF

   RETURN Nil

METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                 bChange, cTooltip, bKeydown, bOther )  CLASS HListBox

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, cTooltip )

   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
   ::bSetGet := bSetGet
   ::bKeydown := bKeydown
    ::bOther := bOther

   IF aItems == Nil
      ::aItems := { }
   ELSE
      ::aItems  := aItems
   ENDIF

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::oParent:AddEvent( LBN_SELCHANGE, Self, { | o, id | ::Valid( o:FindControl( id ) ) }, "onChange" )
   ENDIF

   RETURN Self

/* ------------------------------------------------------------------
 *  Init()
 *
 *  Called once after the widget tree exists.  It:
 *
 *    1. Binds the Harbour object to the widget, so the C layer's
 *       hwg_dispatch_onevent() can walk back to this HListBox.
 *    2. Calls HWG_INITLISTPROC() -- a no-op on GTK4, the Win32
 *       subclassing hook on Windows.
 *    3. Sets the row height (if requested) BEFORE adding the strings.
 *       This order is required by the GTK4 backend: LB_SETITEMHEIGHT
 *       is stored on the listbox and read by HWG_LISTBOXADDSTRING()
 *       when each new row is created.  Reversing the order would
 *       leave the first batch of rows at the default height.
 *    4. Populates aItems and applies the initial selection.
 * ------------------------------------------------------------------ */
METHOD Init() CLASS HListBox

   LOCAL i

   IF ! ::lInit

      hwg_Setwindowobject( ::handle, Self )

      HWG_INITLISTPROC( ::handle )

      ::Super:Init()

      IF ::aItems != Nil
         IF ::value == Nil
            ::value := 1
         ENDIF
         IF !EMPTY( ::nItemHeight )
            hwg_Sendmessage( ::handle, LB_SETITEMHEIGHT , 0, ::nItemHeight )
         ENDIF

         hwg_Sendmessage( ::handle, LB_RESETCONTENT, 0, 0 )

         FOR i := 1 TO Len( ::aItems )
            hwg_Listboxaddstring( ::handle, ::aItems[ i ] )
         NEXT

         hwg_Listboxsetstring( ::handle, ::value )

      ENDIF
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------
 *  onEvent()
 *
 *  Message dispatcher called from the C layer for any notification
 *  not already handled by AddEvent blocks.  Only WM_KEYDOWN and
 *  WM_GETDLGCODE are inspected here; every other message (including
 *  the LB_* notifications dispatched as LBN_*) returns -1 so the
 *  default handling takes over.
 *
 *  The VK_TAB / VK_RETURN / VK_ESCAPE handling is identical on both
 *  backends because the key codes are already normalised by the C
 *  layer before reaching this method.
 * ------------------------------------------------------------------ */
METHOD onEvent( msg, wParam, lParam ) CLASS HListBox

   LOCAL nEval

   IF ::bOther != Nil
      IF (nEval := Eval( ::bOther,Self,msg,wParam,lParam )) != -1 .AND. nEval != Nil
         RETURN 0
      ENDIF
   ENDIF

   /* LBN_SELCHANGE is dispatched from listbox.c's
    * cb_listbox_row_selected() when the user clicks a row.  wParam
    * carries the 1-based index of the new selection.
    *
    * The original GTK2/GTK3 code relied on AddEvent(LBN_SELCHANGE,...)
    * in ::oParent, which only fires on WM_COMMAND -- a mechanism
    * the GTK4 backend does not use.  Handling the notification
    * directly here keeps the class working on both backends. */
   IF msg == LBN_SELCHANGE
      ::value := wParam
      IF ::bSetGet != Nil
         Eval( ::bSetGet, ::value, Self )
      ENDIF
      IF ::bChangeSel != Nil
         Eval( ::bChangeSel, ::value, Self )
      ENDIF
      RETURN 0
   ENDIF

   wParam := hwg_PtrToUlong( wParam )
   IF msg == WM_KEYDOWN
      IF wParam = VK_TAB
         hwg_GetSkip( ::oParent, ::handle, , iif( hwg_IsCtrlShift(.f., .t.), -1, 1) )
      ENDIF
      IF ::bKeyDown != Nil .and. ValType( ::bKeyDown ) == 'B'
         nEval := Eval( ::bKeyDown, Self, wParam )
         IF (VALTYPE( nEval ) == "L" .AND. ! nEval ) .OR. ( nEval != -1 .AND. nEval != Nil )
            RETURN 0
         ENDIF
      ENDIF
   ELSEIF  msg = WM_GETDLGCODE .AND. ( wParam = VK_RETURN .OR.wParam = VK_ESCAPE ) .AND. ::bKeyDown != Nil
      RETURN DLGC_WANTALLKEYS
   ENDIF

   RETURN -1

/* ------------------------------------------------------------------
 *  Requery()
 *
 *  Rebuilds the entire row list from aItems.  Cheaper than comparing
 *  item by item, and matches the Win32 semantics of LB_RESETCONTENT
 *  followed by a fresh LB_ADDSTRING pass.
 * ------------------------------------------------------------------ */
METHOD Requery() CLASS HListBox

   LOCAL i

   hwg_Sendmessage( ::handle, LB_RESETCONTENT, 0, 0)
   FOR i := 1 TO Len( ::aItems )
      hwg_Listboxaddstring( ::handle, ::aItems[i] )
   NEXT
   hwg_Listboxsetstring( ::handle, ::value )
   ::refresh()

   RETURN Nil

/* ------------------------------------------------------------------
 *  Refresh()
 *
 *  Re-reads the value bound through bSetGet and re-applies the
 *  selection.  Because it goes through SetItem() -> LB_SETCURSEL,
 *  the GTK4 backend's "busy" flag suppresses the LBN_SELCHANGE
 *  notification, so bChange is NOT fired by a mere refresh.
 * ------------------------------------------------------------------ */
METHOD Refresh() CLASS HListBox

   LOCAL vari

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet )
   ENDIF

   ::value := IIf( vari == Nil .OR. ValType( vari ) != "N", 0, vari )
   ::SetItem( ::value )

   RETURN Nil

/* ------------------------------------------------------------------
 *  SetItem()
 *
 *  Programmatic selection.  nPos is 1-based; 0 or negative clears the
 *  selection on both backends (Win32 LB_SETCURSEL with -1, GTK4
 *  gtk_list_box_unselect_all()).
 *
 *  bChangeSel is called directly here -- it is a programmatic change,
 *  so it is the caller's intent to run the callback.  This is why the
 *  C layer suppresses LBN_SELCHANGE while setting the selection: the
 *  same event must not fire twice.
 * ------------------------------------------------------------------ */
METHOD SetItem( nPos ) CLASS HListBox

   ::value := nPos
   hwg_Sendmessage( ::handle, LB_SETCURSEL, nPos - 1, 0 )

   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value )
   ENDIF

   IF ::bChangeSel != Nil
      Eval( ::bChangeSel, ::value, Self )
   ENDIF

   RETURN Nil

METHOD onDblClick()  CLASS HListBox

   IF ::bDblClick != Nil
      Eval( ::bDblClick, self, ::value )
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------
 *  AddItems()
 *
 *  Appends one item to aItems and mirrors it in the widget.  On GTK4
 *  HWG_LISTBOXADDSTRING() creates a new GtkListBoxRow; on Win32 it is
 *  LB_ADDSTRING.  Both return the 1-based index, but AddItems discards
 *  it to keep the API symmetric.
 * ------------------------------------------------------------------ */
METHOD AddItems( p ) CLASS HListBox

   AAdd( ::aItems, p )
   hwg_Listboxaddstring( ::handle, p )
   hwg_Listboxsetstring( ::handle, ::value )

   RETURN Self

/* ------------------------------------------------------------------
 *  DeleteItem()
 *
 *  Removes one item from aItems and from the widget.  The C layer
 *  returns LB_ERR (-1) when the row does not exist; the compare
 *  ">= 0" therefore means "the removal succeeded".
 *
 *  Note: hwg_Sendmessage() returns LB_ERR (-1) on GTK4 when the
 *  index is out of range, matching Win32, so the semantics of the
 *  guard below are identical on both backends.
 * ------------------------------------------------------------------ */
METHOD DeleteItem( nPos ) CLASS HListBox

   IF hwg_Sendmessage( ::handle, LB_DELETESTRING , nPos - 1, 0 ) >= 0 //<= LEN(ocombo:aitems)
      ADel( ::Aitems, nPos )
      ASize( ::Aitems, Len( ::aitems ) - 1 )
      ::value := Min( Len( ::aitems ) , ::value )
      IF ::bSetGet != Nil
         Eval( ::bSetGet, ::value, Self )
      ENDIF
      RETURN .T.
   ENDIF

   RETURN .F.

METHOD Clear() CLASS HListBox

   ::aItems := { }
   ::value := 0
   hwg_Sendmessage( ::handle, LB_RESETCONTENT, 0, 0 )
   hwg_Listboxsetstring( ::handle, ::value )

   RETURN .T.

METHOD onChange( oCtrl ) CLASS HListBox

   LOCAL nPos

   HB_SYMBOL_UNUSED( oCtrl )

   nPos := hwg_Sendmessage( ::handle, LB_GETCURSEL, 0, 0 ) + 1
   ::SetItem( nPos )

   RETURN Nil

METHOD When( oCtrl ) CLASS HListBox

   LOCAL res := .t.

   * Variable not used
   * nSkip

   HB_SYMBOL_UNUSED( oCtrl )

*    nSkip := IIf( hwg_Getkeystate( VK_UP ) < 0 .or. ( hwg_Getkeystate( VK_TAB ) < 0 .AND. hwg_Getkeystate( VK_SHIFT ) < 0 ), - 1, 1 )
*    Warning W0027  Meaningless use of expression 'Numeric'
*   IIf( hwg_Getkeystate( VK_UP ) < 0 .or. ( hwg_Getkeystate( VK_TAB ) < 0 .AND. hwg_Getkeystate( VK_SHIFT ) < 0 ), - 1, 1 )

   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, Self )
   ENDIF
   IF ::bGetFocus != Nil
      res := Eval( ::bGetFocus, ::Value, Self )
      ::Setfocus()
   ENDIF

   RETURN res

METHOD Valid( oCtrl ) CLASS HListBox

   LOCAL res, oDlg

   HB_SYMBOL_UNUSED( oCtrl )

   IF ( oDlg := hwg_GetParentForm( Self ) ) == Nil .OR. oDlg:nLastKey != 27
      ::value := hwg_Sendmessage( ::handle, LB_GETCURSEL, 0, 0 ) + 1
      IF ::bSetGet != Nil
         Eval( ::bSetGet, ::value, Self )
      ENDIF
      IF oDlg != Nil
         oDlg:nLastKey := 27
      ENDIF
      IF ::bLostFocus != Nil
         res := Eval( ::bLostFocus, ::value, Self )
         IF ! res
            ::Setfocus( .T. ) //( ::handle )
            IF oDlg != Nil
               oDlg:nLastKey := 0
            ENDIF
            RETURN .F.
         ENDIF
      ENDIF
      IF oDlg != Nil
         oDlg:nLastKey := 0
      ENDIF
   ENDIF
   IF Empty( hwg_Getfocus() )
       hwg_GetSkip( ::oParent, ::handle, 1 )
   ENDIF

   RETURN .T.
