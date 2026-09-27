/*
 *$Id: hcombo.prg 3445 2024-02-29 11:01:28Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HComboBox class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port -- target: GTK 4.24+
 *
 * NOTES
 * -----
 *  - Focus tracking is done by the GtkEventControllerFocus installed
 *    on the combo (and on its internal entry when editable) by
 *    HWG_CREATECOMBO / hwg_install_widget_events() in control.c.
 *    The legacy "focus_in_event" / "focus_out_event" signals no longer
 *    exist in GTK4 and are not used here.
 *
 *  - GtkComboBox has no "changed" signal in GTK4.  hwg_SetSignal(
 *    "changed") is translated inside set_signal() (window.c) to the
 *    "notify::active" signal, which serves the same purpose.
 *
 *  - The internal GtkEntry of an editable combo receives focus; the
 *    same focus controller is installed on it and HWG_SETWINDOWOBJECT
 *    mirrors the Harbour object onto it so events propagate normally.
 *
 *  - DisplayCount: on GTK4 the dropdown popup is a GtkPopover that
 *    contains a GtkScrolledWindow.  Setting its "max-content-height"
 *    limits the number of visible rows, matching the Win32 behaviour.
 *    See HWG_COMBOSETDISPLAYCOUNT in control.c.  The value is applied
 *    on notify::popup-shown so it survives theme changes and popup
 *    re-layouts.  GTK2 ignored this attribute; GTK4 now honours it.
 */

#include "hbclass.ch"
#include "hwgui.ch"

#ifndef CBN_SELCHANGE
#define CBN_SELCHANGE       1
#endif
#ifndef CBN_EDITCHANGE
#define CBN_EDITCHANGE      5
#endif

CLASS HComboBox INHERIT HControl

   CLASS VAR winclass   INIT "COMBOBOX"
   DATA  aItems
   DATA  bSetGet
   DATA  bValid
   DATA  xValue    INIT 1
   DATA  bChangeSel
   DATA  lText    INIT .F.
   DATA  lEdit    INIT .F.
   DATA  hEdit
   DATA  DisplayCount INIT 0

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      aItems, oFont, bInit, bSize, bPaint, bChange, cToolt, lEdit, lText, bGFocus, tcolor, bcolor, bValid, nDisplayCount )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Refresh( xVal )
   METHOD Setitem( nPos )
   METHOD GetValue( nItem )
   METHOD GetText() INLINE iif( ::lEdit, hwg_ComboGetText( ::handle ), ::GetValue() )
   METHOD Value ( xValue ) SETGET
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
      bInit, bSize, bPaint, bChange, cToolt, lEdit, lText, bGFocus, tcolor, bcolor, bValid, nDisplayCount ) CLASS HComboBox

   IF lEdit == Nil; lEdit := .F. ; ENDIF
   IF lText == Nil; lText := .F. ; ENDIF

   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), iif( lEdit,CBS_DROPDOWN,CBS_DROPDOWNLIST ) + WS_TABSTOP )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, ctoolt, tcolor, bcolor )

   ::lEdit := lEdit
   ::lText := lText

   IF lEdit
      ::lText := .T.
   ENDIF

   IF ::lText
      ::xValue := iif( vari == Nil .OR. ValType( vari ) != "C", "", vari )
   ELSE
      ::xValue := iif( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
   ENDIF

   IF bSetGet != Nil
      ::bSetGet := bSetGet
      Eval( ::bSetGet, ::xValue, self )
   ENDIF

   ::aItems  := aItems

   /* GTK4 honours DisplayCount by sizing the popup scrolled window.
      On Win32 the same attribute is honoured natively. */
   ::DisplayCount := iif( nDisplayCount == Nil, 0, nDisplayCount )

   ::Activate()
   ::bValid := bValid
   ::bGetFocus := bGFocus
   ::bChangeSel := bChange

   /* GTK4: focus is tracked by the event controller installed in
      HWG_CREATECOMBO.  Only the value-change signal is wired here:
      set_signal() translates "changed" to notify::active. */
   hwg_SetSignal( ::handle, "changed", CBN_SELCHANGE, 0, 0 )

   IF Left( ::oParent:ClassName(), 6 ) == "HPANEL" .AND. hwg_BitAnd( ::oParent:style, SS_OWNERDRAW ) != 0
      ::oParent:oPaintCB := HPaintCB():New()
      ::oParent:oPaintCB:Set( PAINT_ITEM, {|o,h|HB_SYMBOL_UNUSED(o),iif( !::lHide,hwg__DrawCombo(h,::nLeft + ::nWidth - 22,::nTop,::nLeft + ::nWidth - 1,::nTop + ::nHeight - 1 ), .T. ) }, "hc" + LTrim( Str(::id ) ) )
   ENDIF

   RETURN Self

METHOD Activate() CLASS HComboBox

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createcombo( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HComboBox

   LOCAL i

   HB_SYMBOL_UNUSED(lParam)

   IF msg == WM_SETFOCUS
      IF ::bSetGet == Nil
         IF ::bGetFocus != Nil
            i := hwg_ComboGet( ::handle )
            Eval( ::bGetFocus, iif( ValType(::aItems[1] ) == "A", ::aItems[i,1], ::aItems[i] ), Self )
         ENDIF
      ELSE
         __When( Self )
      ENDIF
   ELSEIF msg == WM_KILLFOCUS
      IF ::bSetGet == Nil
         IF ::bLostFocus != Nil
            i := hwg_ComboGet( ::handle )
            Eval( ::bLostFocus, iif( ValType(::aItems[1] ) == "A", ::aItems[i,1], ::aItems[i] ), Self )
         ENDIF
      ELSE
         __Valid( Self )
      ENDIF

   ELSEIF msg == WM_KEYDOWN
      IF wParam == GDK_Return .OR. wParam == GDK_KP_Enter
         /* ENTER advances focus to the next control, matching the
          * HEdit behaviour (see hedit.prg).  The trailing .T. asks
          * hwg_GetSkip to run the control's Valid chain before
          * moving; if Valid returns .F., the focus stays put. */
         hwg_GetSkip( ::oParent, ::handle, 1, .T. )
         RETURN 0
      ENDIF

   ELSEIF msg == CBN_SELCHANGE
      ::GetValue()
      IF ::bChangeSel != Nil
         Eval( ::bChangeSel, ::xValue, Self )
      ENDIF
   ELSEIF msg == CBN_EDITCHANGE
      IF ::lEdit
         hwg_ComboSeekPrefix( ::handle, hwg_ComboGetText( ::handle ) )
      ENDIF
   ENDIF

   RETURN 0

METHOD Init() CLASS HComboBox

   IF !::lInit
      ::Super:Init()
      IF !Empty( ::aItems )
         hwg_ComboSetArray( ::handle, ::aItems )
         IF Empty( ::xValue )
            IF ::lText
               ::xValue := iif( ValType( ::aItems[1] ) == "A", ::aItems[1,1], ::aItems[1] )
            ELSE
               ::xValue := 1
            ENDIF
         ENDIF
         ::Value := ::xValue
         IF ::bSetGet != Nil
            Eval( ::bSetGet, ::xValue, Self )
         ENDIF
      ENDIF

      IF ::DisplayCount > 0
         hwg_ComboSetDisplayCount( ::handle, ::DisplayCount )
      ENDIF

      /* GTK4 type-ahead.  Hook the internal entry's "changed" so that
       * as the user types, the active item jumps to the first list
       * entry that starts with the typed prefix -- Win32 behaviour.
       * Only makes sense for editable combos. */
      IF ::lEdit
         hwg_SetSignal( hwg_ComboEntry( ::handle ), "changed", CBN_EDITCHANGE, 0, 0 )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Refresh( xVal ) CLASS HComboBox

   LOCAL vari, i

   IF Empty( ::aItems )
      RETURN Nil
   ENDIF

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet, , Self )
   ENDIF
   hwg_ComboSetArray( ::handle, ::aItems )

   IF xVal != Nil
      ::xValue := xVal
   ELSEIF ::bSetGet != Nil
      IF ::lText
         ::xValue := iif( vari == Nil .OR. ValType( vari ) != "C", "", vari )
      ELSE
         ::xValue := iif( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
      ENDIF
   ENDIF

   IF ::lText
#ifdef __XHARBOUR__
      i := Iif( ValType( ::aItems[1] ) == "A", AScan( ::aItems, {|a|a[1] == ::xValue } ), AScan( ::aItems, {|s|s == ::xValue } ) )
#else
      i := Iif( ValType( ::aItems[1] ) == "A", AScan( ::aItems, {|a|a[1] == ::xValue } ), hb_AScan( ::aItems, ::xValue,,,.T. ) )
#endif
      hwg_ComboSet( ::handle, i )
   ELSE
      hwg_ComboSet( ::handle, ::xValue )
   ENDIF

   RETURN Nil

METHOD SetItem( nPos ) CLASS HComboBox

   IF nPos == 0 .OR. nPos > Len( ::aItems )
      RETURN Nil
   ENDIF
   IF ::lText
      ::xValue := iif( ValType( ::aItems[nPos] ) == "A", ::aItems[nPos,1], ::aItems[nPos] )
   ELSE
      ::xValue := nPos
   ENDIF

   hwg_ComboSet( ::handle, nPos )

   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::xValue, self )
   ENDIF

   IF ::bChangeSel != Nil
      Eval( ::bChangeSel, ::xValue, Self )
   ENDIF

   RETURN Nil

METHOD GetValue( nItem ) CLASS HComboBox

   LOCAL nPos := hwg_ComboGet( ::handle )
   LOCAL vari := iif( !Empty( ::aItems ) .AND. nPos > 0, ;
      iif( ValType( ::aItems[1] ) == "A", ::aItems[nPos,1], ::aItems[nPos] ), "" )
   LOCAL l := nPos > 0 .AND. ValType( ::aItems[nPos] ) == "A"

   ::xValue := iif( ::lText, vari, nPos )
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::xValue, Self )
   ENDIF

   RETURN iif( l .AND. nItem != Nil, iif( nItem > 0 .AND. nItem <= Len(::aItems[nPos] ), ::aItems[nPos,nItem], Nil ), ::xValue )

METHOD Value ( xValue ) CLASS HComboBox

   IF xValue != Nil
      IF ValType( xValue ) == "C"
#ifdef __XHARBOUR__
         xValue := iif( ValType( ::aItems[1] ) == "A", AScan( ::aItems, { |a|a[1] == xValue } ), AScan( ::aItems, { |s|s == xValue } ) )
#else
         xValue := iif( ValType( ::aItems[1] ) == "A", AScan( ::aItems, { |a|a[1] == xValue } ), hb_AScan( ::aItems, xValue,,, .T. ) )
#endif
      ENDIF
      ::SetItem( xValue )

      RETURN ::xValue
   ENDIF

   RETURN ::GetValue()

METHOD End() CLASS HComboBox

   hwg_ReleaseObject( ::handle )
   ::Super:End()

   RETURN Nil

STATIC FUNCTION __Valid( oCtrl )

   oCtrl:GetValue()
   IF oCtrl:bValid != NIL
      IF !Eval( oCtrl:bValid, oCtrl )
         hwg_Setfocus( oCtrl:handle )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.

STATIC FUNCTION __When( oCtrl )

   LOCAL res

   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )
      IF !res
         hwg_GetSkip( oCtrl:oParent, oCtrl:handle, 1 )
      ENDIF
      RETURN res
   ENDIF

   RETURN .T.
