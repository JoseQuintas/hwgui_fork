/*
 *$Id: hradio.prg 3308 2023-08-31 07:33:05Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HRadioButton class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It relies on:
 *
 *   - hwg_Createbutton      → control.c (GtkRadioButton)
 *   - hwg_CheckButton       → control.c (gtk_toggle_button_set_active)
 *   - hwg_SetSignal("released") → see below
 *
 * The signal name "released" used here is a historical artifact: it was
 * never a real GTK signal (not in GTK2, GTK3 or GTK4).  To make the
 * radio button's release handler actually fire, set_signal() (window.c)
 * must map both "clicked" and "released" on GtkCheckButton / GtkRadioButton
 * to the GTK4 "toggled" signal.
 *
 * Without that mapping, HRadioButton:onEvent never sees WM_LBUTTONUP and
 * __Valid() is never called — the group's nValue would not update.
 */

#include "hwgui.ch"
#include "hbclass.ch"

CLASS HRadioGroup INHERIT HObject

   CLASS VAR oGroupCurrent
   DATA handle INIT 0
   DATA aButtons
   DATA nValue  INIT 1
   DATA bSetGet
   DATA oHGroup

   METHOD New( vari, bSetGet )
   METHOD NewRg( oWndParent, nId, nStyle, vari, bSetGet, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, tcolor, bColor )
   METHOD EndGroup( nSelected )
   METHOD Value( nValue ) SETGET
   METHOD Refresh()   INLINE iif( ::bSetGet != Nil, ::Value := Eval(::bSetGet ), .T. )

ENDCLASS

METHOD New( vari, bSetGet ) CLASS HRadioGroup

   ::oGroupCurrent := Self
   ::aButtons := {}

   IF vari != Nil
      IF ValType( vari ) == "N"
         ::nValue := vari
      ENDIF
      ::bSetGet := bSetGet
   ENDIF

   RETURN Self

METHOD NewRg( oWndParent, nId, nStyle, vari, bSetGet, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, tcolor, bColor ) CLASS HRadioGroup

   ::oGroupCurrent := Self
   ::aButtons := {}

   ::oHGroup := HGroup():New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
      oFont, bInit, bSize, , tcolor, bColor )

   IF vari != NIL
      IF ValType( vari ) == "N"
         ::nValue := vari
      ENDIF
      ::bSetGet := bSetGet
   ENDIF

   RETURN Self

METHOD EndGroup( nSelected )  CLASS HRadioGroup

   LOCAL nLen

   IF ::oGroupCurrent != Nil .AND. ( nLen := Len( ::oGroupCurrent:aButtons ) ) > 0

      nSelected := iif( nSelected != Nil .AND. nSelected <= nLen .AND. nSelected > 0, ;
         nSelected, ::oGroupCurrent:nValue )
      IF nSelected != 0 .AND. nSelected <= nlen
         hwg_CheckButton( ::oGroupCurrent:aButtons[nSelected]:handle, .T. )
      ENDIF
   ENDIF
   ::oGroupCurrent := Nil

   RETURN Nil

METHOD Value( nValue ) CLASS HRadioGroup

   LOCAL nLen

   IF nValue != Nil
      IF ( nLen := Len( ::aButtons ) ) > 0 .AND. nValue > 0 .AND. nValue <= nLen
         hwg_CheckButton( ::aButtons[nValue]:handle, .T. )
         ::nValue := nValue
         IF ::bSetGet != NIL
            Eval( ::bSetGet, nValue, Self )
         ENDIF
      ENDIF
   ENDIF

   RETURN ::nValue

CLASS HRadioButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   DATA  oGroup
   DATA bClick

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
      bInit, bSize, bPaint, bClick, ctoolt, tcolor, bcolor )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD SetText( value ) INLINE hwg_button_SetText( ::handle, ::title := value )
   METHOD GetText() INLINE hwg_button_GetText( ::handle )
   METHOD Value( lValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
      bInit, bSize, bPaint, bClick, ctoolt, tcolor, bcolor ) CLASS HRadioButton

     * Parameters not used
    HB_SYMBOL_UNUSED(bcolor)

   ::oParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )
   ::id      := iif( nId == Nil, ::NewId(), nId )
   ::title   := cCaption
   ::oGroup  := HRadioGroup():oGroupCurrent
   ::style   := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), BS_AUTORADIOBUTTON + ;
      WS_CHILD + WS_VISIBLE + ;
      iif( ::oGroup != Nil .AND. Empty( ::oGroup:aButtons ), WS_GROUP, 0 ) )
   ::oFont   := oFont
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::bInit   := bInit
   IF ValType( bSize ) == "N"
      ::Anchor := bSize
   ELSE
      ::bSize   := bSize
   ENDIF
   ::bPaint  := bPaint
   ::tooltip := ctoolt
   ::tcolor  := tcolor

   ::Activate()
   ::oParent:AddControl( Self )
   ::bClick := bClick
   IF bClick != Nil .AND. ( ::oGroup == Nil .OR. ::oGroup:bSetGet == Nil )
      hwg_SetSignal( ::handle, "released", WM_LBUTTONUP, 0, 0 )
   ENDIF
   IF ::oGroup != Nil
      AAdd( ::oGroup:aButtons, Self )
      IF ::oGroup:bSetGet != Nil
         hwg_SetSignal( ::handle, "released", WM_LBUTTONUP, 0, 0 )
      ENDIF
   ENDIF

   IF Left( ::oParent:ClassName(),6 ) == "HPANEL" .AND. hwg_BitAnd( ::oParent:style,SS_OWNERDRAW ) != 0
      ::oParent:oPaintCB := HPaintCB():New()
      ::oParent:oPaintCB:Set( PAINT_ITEM, {|o,h|HB_SYMBOL_UNUSED(o),Iif(!::lHide,hwg__DrawRadioBtn(h,::nLeft,::nTop,::nLeft+::nWidth-1,::nTop+::nHeight-1,hwg_isButtonChecked(::handle),::title),.T.)}, "rb"+Ltrim(Str(::id)) )
   ENDIF

   RETURN Self

METHOD Activate() CLASS HRadioButton

   LOCAL groupHandle := ::oGroup:handle

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createbutton( ::oParent:handle, @groupHandle, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::oGroup:handle := groupHandle
      hwg_Setwindowobject( ::handle, Self )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HRadioButton

   * Parameters not used
   HB_SYMBOL_UNUSED(wParam)
   HB_SYMBOL_UNUSED(lParam)

   IF msg == WM_LBUTTONUP
      IF ::oGroup:bSetGet == Nil
         Eval( ::bClick, Self, ::oGroup:nValue )
      ELSE
         __Valid( Self )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Value( lValue ) CLASS HRadioButton

   IF lValue != Nil
      hwg_CheckButton( ::handle, .T. )
   ENDIF

   RETURN hwg_isButtonChecked( ::handle )

STATIC FUNCTION __Valid( oCtrl )

   oCtrl:oGroup:nValue := Ascan( oCtrl:oGroup:aButtons, { |o|o:id == oCtrl:id } )
   IF oCtrl:oGroup:bSetGet != Nil
      Eval( oCtrl:oGroup:bSetGet, oCtrl:oGroup:nValue )
   ENDIF
   IF oCtrl:bClick != Nil
      Eval( oCtrl:bClick, oCtrl, oCtrl:oGroup:nValue )
   ENDIF

   RETURN .T.
