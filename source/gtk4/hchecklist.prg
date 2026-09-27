/*
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HCheckList class
 *
 * GTK4 port — target: GTK 4.24+
 *
 * NOTES
 * -----
 *  A check list is a vertical list of GtkCheckButton rows, each
 *  independently toggled, inside a GtkScrolledWindow.  It replaces
 *  the Win32 pattern of a ListView with LVS_EX_CHECKBOXES for cases
 *  where each row is just a label and a boolean.
 *
 *  aItems stores one entry per row.  Each entry is an array of the
 *  form { cLabel, lChecked, xUserValue }.  xUserValue is an opaque
 *  value (index, code, object) the caller wants to retrieve later
 *  through GetCheckedValues().
 *
 *  The internal notification HWG_MSGLIST_CHECKED is defined in
 *  windows.ch; it fires on the scrolled window when the user toggles
 *  a row, with wParam = 1-based row index and lParam = 1 (checked)
 *  or 0 (unchecked).  See HCheckList:onEvent below and
 *  cb_checklist_toggle in control.c.
 */

#include "hbclass.ch"
#include "hwgui.ch"

CLASS HCheckList INHERIT HControl

   CLASS VAR winclass  INIT "CHECKLIST"

   DATA   aItems    INIT {}
   DATA   bSetGet
   DATA   bChange
   DATA   bValid

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      aItems, oFont, bInit, bSize, bPaint, bChange, cTooltip, tcolor, ;
      bcolor, bValid, bSetGet )
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD AddItem( cLabel, lChecked, xValue )
   METHOD SetItems( aItems )
   METHOD Clear()
   METHOD GetCount()
   METHOD IsChecked( nIndex )
   METHOD SetChecked( nIndex, lChecked )
   METHOD GetChecked()
   METHOD GetCheckedItems()
   METHOD GetCheckedValues()
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      aItems, oFont, bInit, bSize, bPaint, bChange, cTooltip, tcolor, ;
      bcolor, bValid, bSetGet ) CLASS HCheckList

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, cTooltip, tcolor, bcolor )

   ::aItems  := {}
   ::bChange := bChange
   ::bValid  := bValid
   ::bSetGet := bSetGet

   ::Activate()

   IF aItems != Nil .AND. ValType( aItems ) == "A"
      ::SetItems( aItems )
   ENDIF

   RETURN Self

METHOD Activate() CLASS HCheckList

   IF !Empty( ::oParent:handle )
      ::handle := hwg_CreateCheckList( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init() CLASS HCheckList

   IF !::lInit
      ::Super:Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HCheckList

   IF msg == HWG_MSGLIST_CHECKED
      IF ::bChange != Nil
         Eval( ::bChange, Self, wParam, ( lParam == 1 ) )
      ENDIF
      IF ::bSetGet != Nil
         Eval( ::bSetGet, ::GetChecked(), Self )
      ENDIF
      RETURN 0
   ENDIF

   RETURN -1

METHOD AddItem( cLabel, lChecked, xValue ) CLASS HCheckList

   LOCAL nIdx

   IF lChecked == Nil ; lChecked := .F. ; ENDIF

   nIdx := hwg_CheckListAddItem( ::handle, cLabel, lChecked )
   AAdd( ::aItems, { cLabel, lChecked, xValue } )

   RETURN nIdx

METHOD SetItems( aItems ) CLASS HCheckList

   LOCAL i, item, cLabel, lChecked, xValue

   ::Clear()

   FOR i := 1 TO Len( aItems )
      item := aItems[i]
      IF ValType( item ) == "A"
         cLabel   := item[1]
         lChecked := iif( Len( item ) >= 2, item[2], .F. )
         xValue   := iif( Len( item ) >= 3, item[3], Nil )
      ELSE
         cLabel   := item
         lChecked := .F.
         xValue   := Nil
      ENDIF
      ::AddItem( cLabel, lChecked, xValue )
   NEXT

   RETURN Nil

METHOD Clear() CLASS HCheckList

   hwg_CheckListClear( ::handle )
   ::aItems := {}

   RETURN Nil

METHOD GetCount() CLASS HCheckList

   RETURN hwg_CheckListGetCount( ::handle )

METHOD IsChecked( nIndex ) CLASS HCheckList

   RETURN hwg_CheckListIsChecked( ::handle, nIndex )

METHOD SetChecked( nIndex, lChecked ) CLASS HCheckList

   IF nIndex >= 1 .AND. nIndex <= Len( ::aItems )
      ::aItems[nIndex, 2] := lChecked
   ENDIF
   hwg_CheckListSetChecked( ::handle, nIndex, lChecked )

   RETURN Nil

METHOD GetChecked() CLASS HCheckList

   LOCAL aIdx := hwg_CheckListGetChecked( ::handle ), i

   /* Refresh the internal copy of the state from the widget, then
    * return the indexes the C side reports as checked. */
   FOR i := 1 TO Len( ::aItems )
      ::aItems[i, 2] := AScan( aIdx, i ) > 0
   NEXT

   RETURN aIdx

METHOD GetCheckedItems() CLASS HCheckList

   LOCAL aIdx := ::GetChecked(), aOut := {}, i

   FOR i := 1 TO Len( aIdx )
      AAdd( aOut, ::aItems[ aIdx[i], 1 ] )
   NEXT

   RETURN aOut

METHOD GetCheckedValues() CLASS HCheckList

   LOCAL aIdx := ::GetChecked(), aOut := {}, i

   FOR i := 1 TO Len( aIdx )
      AAdd( aOut, ::aItems[ aIdx[i], 3 ] )
   NEXT

   RETURN aOut

METHOD End() CLASS HCheckList

   hwg_ReleaseObject( ::handle )
   ::Super:End()

   RETURN Nil
