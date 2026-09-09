/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCombo class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCheckComboEx class
 *
 * Copyright 2007 Luiz Rafale Culik Guimaraes (Luiz at xharbour.com.br)
 * www - http://kresin.belgorod.su
*/

#include "hwgui.ch"
#include "hbclass.ch"
#include "common.ch"

#DEFINE CB_SHOWDROPDOWN             335
#define CB_GETDROPPEDSTATE          343
#define CB_FINDSTRINGEXACT          344
#define CB_SETCUEBANNER             5891
#define TRANSPARENT        1

#pragma begindump
#include "hwingui.h"
#include "hbapiitm.h"
#include "hbvm.h"

static WNDPROC wpOrigComboProc;

HB_FUNC( COPYDATA )
{
   /* lParam is the real buffer address Windows passed via WM_GETTEXT -
      it is a pointer, so it must be read pointer-safely (hb_parnint),
      not truncated to a 32-bit LONG via hb_parnl(), which corrupts the
      address on 64-bit builds and makes lstrcpyn() write to the wrong
      memory. */
   LPARAM lParam = ( LPARAM ) hb_parnint( 1 ) ;
   void * hText;
   LPCTSTR m_strText = HB_PARSTR( 2, &hText, NULL );
   WPARAM wParam = ( WPARAM ) hb_parnint( 3 ) ;

   lstrcpyn( ( LPTSTR ) lParam, m_strText, ( INT ) wParam ) ;
   hb_strfree( hText );
}

LRESULT APIENTRY ComboSubclassProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      /* wParam/lParam are pointer-sized (WPARAM/LPARAM) - some messages
         this proc receives (WM_CTLCOLOREDIT, WM_CTLCOLORLISTBOX) carry a
         real HDC in wParam and expect a HBRUSH handle back, so both must
         round-trip through the VM without truncation. See s_MainWndProc
         in window.c for the same pattern. */
      HB_PUSHITEM( wParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      if( HB_ISPOINTER( -1 ) )
         return ( LRESULT ) HB_PARHANDLE( -1 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( CallWindowProc( wpOrigComboProc, hWnd, message, wParam,
                     lParam ) );
      else
         return res;
   }
   else
      return ( CallWindowProc( wpOrigComboProc, hWnd, message, wParam,
                  lParam ) );
}

HB_FUNC( HWG_INITCOMBOPROC )
{
   wpOrigComboProc = ( WNDPROC ) SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
         GWLP_WNDPROC, ( LONG_PTR ) ComboSubclassProc );
}

#pragma enddump

#ifndef __XHARBOUR__
   #xtranslate RAScan([<x,...>])        => hb_RAScan(<x>)
#endif

CLASS HComboBoxEx INHERIT HControl

   CLASS VAR winclass INIT "COMBOBOX"
   DATA aItems
   DATA aItemsBound
   DATA bSetGet
   DATA value INIT 1
   DATA valueBound INIT 1
   DATA cDisplayValue HIDDEN
   DATA columnBound INIT 1 HIDDEN
   DATA xrowsource INIT { , } HIDDEN

   DATA bChangeSel
   DATA bChangeInt
   DATA bValid
   DATA bSelect

   DATA lText INIT .F.
   DATA lEdit INIT .F.
   DATA SelLeght INIT 0
   DATA SelStart INIT 0
   DATA SelText INIT ""
   DATA nDisplay
   DATA nhItem
   DATA ncWidth
   DATA nHeightBox
   DATA lResource INIT .F.
   DATA ldropshow INIT .F.
   DATA nMaxLength     INIT Nil


   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      aItems, oFont, bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, ;
      bcolor, bLFocus, bIChange, nDisplay, nhItem, ncWidth, nMaxLength )
   METHOD Activate()
   METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, bChange, ctooltip, bGFocus, bLFocus, bIChange, nDisplay, nMaxLength, ledit, ltext,aCheck )
   METHOD INIT()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Requery( aItems, xValue )
   METHOD Refresh()
   METHOD Setitem( nPos )
   METHOD SetValue( xItem )
   METHOD GetValue()
   METHOD AddItem( cItem, cItemBound, nPos )
   METHOD DeleteItem( xIndex )
   METHOD Valid( )
   METHOD When( )
   METHOD onSelect()
   METHOD InteractiveChange( )
   METHOD onChange( lForce )
   METHOD Populate()
   METHOD GetValueBound( xItem )
   METHOD RowSource( xSource ) SETGET
   METHOD DisplayValue( cValue ) SETGET
   METHOD onDropDown( ) INLINE ::ldropshow := .T.
   METHOD SetCueBanner( cText, lShowFoco )
   METHOD MaxLength( nMaxLength ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
      bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, bLFocus, ;
      bIChange, nDisplay, nhItem, ncWidth, nMaxLength ) CLASS HComboBoxEx

   IF !Empty( nDisplay ) .AND. nDisplay > 0
      nStyle := Hwg_BitOr( nStyle, CBS_NOINTEGRALHEIGHT  + WS_VSCROLL )
   ELSE
      nDisplay := 6
   ENDIF
   nHeight := iif( Empty( nHeight ), 24,  nHeight )
   ::nHeightBox := Int( nHeight * 0.75 )
   nHeight := nHeight + ( iif( Empty( nhItem ), 16.250, ( nhItem += 0.10 ) ) * nDisplay )

   IF lEdit == Nil
      lEdit := .F.
   ENDIF

   nStyle := Hwg_BitOr( iif( nStyle == Nil, 0, nStyle ), iif( lEdit, CBS_DROPDOWN, CBS_DROPDOWNLIST ) + WS_TABSTOP )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor )

   IF lText == Nil
      lText := .F.
   ENDIF

   ::nDisplay := nDisplay
   ::nhItem   := nhItem
   ::ncWidth  := ncWidth

   ::lEdit := lEdit
   ::lText := lText

   IF lEdit
      ::lText := .T.
      IF nMaxLength != Nil
         ::MaxLength := nMaxLength
      ENDIF
   ENDIF

   IF ::lText
      ::value := iif( vari == Nil .OR. ValType( vari ) != "C", "", vari )
   ELSE
      ::value := iif( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
   ENDIF

   aItems        := iif( aItems = Nil, {}, AClone( aItems ) )
   ::RowSource( aItems )
   ::aItemsBound   := {}
   ::bSetGet       := bSetGet

   ::Activate()

   ::bChangeSel := bChange
   ::bGetFocus  := bGFocus
   ::bLostFocus := bLFocus

   IF bSetGet != Nil
      IF bGFocus != Nil
         // ::lnoValid := .T.
         ::oParent:AddEvent( CBN_SETFOCUS, ::id, { | o, id | ::When( o:FindControl( id ) ) } )
      ENDIF
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 03/06/2006
      ::oParent:AddEvent( CBN_KILLFOCUS, ::id, { | o, id | ::Valid( o:FindControl( id ) ) } )
      //---------------------------------------------------------------------------
   ELSE
      IF bGFocus != Nil
         //::lnoValid := .T.
         ::oParent:AddEvent( CBN_SETFOCUS, ::id, { | o, id | ::When( o:FindControl( id ) ) } )
      ENDIF
      ::oParent:AddEvent( CBN_KILLFOCUS, ::id, { | o, id | ::Valid( o:FindControl( id ) ) } )
   ENDIF
   IF bChange != Nil .OR. bSetGet != Nil
      ::oParent:AddEvent( CBN_SELCHANGE, ::id, { | o, id | ::onChange( o:FindControl( id ) ) } )
   ENDIF

   IF bIChange != Nil .AND. ::lEdit
      ::bchangeInt := bIChange
      ::oParent:AddEvent( CBN_EDITUPDATE, ::id, { | o, id | ::InteractiveChange( o:FindControl( id ) ) } )
   ENDIF
   ::oParent:AddEvent( CBN_SELENDOK, ::id, { | o, id | ::onSelect( o:FindControl( id ) ) } )
   ::oParent:AddEvent( CBN_DROPDOWN, ::id, { | o, id | ::onDropDown( o:FindControl( id ) ) } )
   ::oParent:AddEvent( CBN_CLOSEUP, ::id, { || ::ldropshow := .F. } )

   RETURN Self

METHOD Activate() CLASS HComboBoxEx

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createcombo( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
      ::nHeight := Int( ::nHeightBox / 0.75 )
   ENDIF

   RETURN Nil

METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
      bChange, ctooltip, bGFocus, bLFocus, bIChange, nDisplay, nMaxLength, ledit, ltext,aCheck  ) CLASS HComboBoxEx

   HB_SYMBOL_UNUSED( bLFocus )
   IF lEdit == Nil
      lEdit := .F.
   ENDIF
   IF lText == Nil
      lText := .F.
   ENDIF

   ::lEdit := lEdit
   ::lText := lText
   ::acheck := acheck

   IF !Empty( nDisplay ) .AND. nDisplay > 0
      ::Style := Hwg_BitOr( ::Style, CBS_NOINTEGRALHEIGHT )
   ELSE
      nDisplay := 6
   ENDIF
   ::lResource := .T.
   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint, ctooltip )

   ::nDisplay := nDisplay

   IF ::lText
      ::value := iif( vari == Nil .OR. ValType( vari ) != "C", "", vari )
   ELSE
      ::value := iif( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
   ENDIF
   IF nMaxLength != Nil
      ::MaxLength := nMaxLength
   ENDIF

   aItems        := iif( aItems = Nil, {}, AClone( aItems ) )
   ::RowSource( aItems )
   ::aItemsBound   := {}
   ::bSetGet := bSetGet


   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::bGetFocus  := bGFocus
      ::oParent:AddEvent( CBN_SETFOCUS, ::id, { | o, id | ::When( o:FindControl( id ) ) } )
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 04/06/2006
      IF ::bSetGet <> nil
         ::oParent:AddEvent( CBN_SELCHANGE, ::id, { | o, id | ::Valid( o:FindControl( id ) ) } )
      ELSEIF ::bChangeSel != NIL
         ::oParent:AddEvent( CBN_SELCHANGE, ::id, { | o, id | ::Valid( o:FindControl( id ) ) } )
      ENDIF
   ELSEIF bChange != Nil .AND. ::lEdit
      ::bChangeSel := bChange
      ::oParent:AddEvent( CBN_SELCHANGE, ::id, { | o, id | ::onChange( o:FindControl( id ) ) } )
   ENDIF

   IF bGFocus != Nil .AND. bSetGet == Nil
      ::oParent:AddEvent( CBN_SETFOCUS, ::id, { | o, id | ::When( o:FindControl( id ) ) } )
   ENDIF
   IF bIChange != Nil .AND. ::lEdit
      ::bchangeInt := bIChange
      ::oParent:AddEvent( CBN_EDITUPDATE, ::id, { | o, id | ::InteractiveChange( o:FindControl( id ) ) } )
   ENDIF

   ::oParent:AddEvent( CBN_SELENDOK, ::id, { | o, id | ::onSelect( o:FindControl( id ) ) } )
   ::oParent:AddEvent( CBN_DROPDOWN, ::id, { | o, id | ::onDropDown( o:FindControl( id ) ) } )
   ::oParent:AddEvent( CBN_CLOSEUP, ::id, { || ::ldropshow := .F. } )

   RETURN Self

METHOD INIT() CLASS HComboBoxEx

   LOCAL LongComboWidth
   LOCAL NewLongComboWidth, avgWidth, nHeightBox

   IF !::lInit
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      HWG_INITCOMBOPROC( ::handle )
      IF ::aItems != Nil .AND. !Empty( ::aItems )
         ::RowSource( ::aItems )
         LongComboWidth := ::Populate()

         IF ::lText
            IF ::lEdit
               hwg_Setdlgitemtext( hwg_GetModalHandle(), ::id, ::value )
               hwg_Sendmessage( ::handle, CB_SELECTSTRING, - 1, ::value )
               hwg_Sendmessage( ::handle, CB_SETEDITSEL , - 1, 0 )
            ELSE
               hwg_Combosetstring( ::handle, AScan( ::aItems, ::value, , , .T.  ) )
            ENDIF
            hwg_Setwindowtext( ::handle, ::value )
         ELSE
            hwg_Combosetstring( ::handle, ::value )
         ENDIF
         avgwidth          := hwg_Getfontdialogunits( ::oParent:handle ) + 0.75
         NewLongComboWidth := ( LongComboWidth - 2 ) * avgwidth
         hwg_Sendmessage( ::handle, CB_SETDROPPEDWIDTH, NewLongComboWidth + 50, 0 )
      ENDIF
      ::Super:Init()
      IF !::lResource
         // HEIGHT Items
         IF !Empty( ::nhItem )
            hwg_Sendmessage( ::handle, CB_SETITEMHEIGHT, 0, ::nhItem + 0.10 )
         ELSE
            ::nhItem := hwg_Sendmessage( ::handle, CB_GETITEMHEIGHT, 0, 0 ) + 0.10
         ENDIF
         nHeightBox := hwg_Sendmessage( ::handle, CB_GETITEMHEIGHT, - 1, 0 ) //+ 0.750
         //  WIDTH  Items
         IF !Empty( ::ncWidth )
            hwg_Sendmessage( ::handle, CB_SETDROPPEDWIDTH, ::ncWidth, 0 )
         ENDIF
         ::nHeight := Int( nHeightBox / 0.75 + ( ::nhItem * ::nDisplay ) ) + 3
      ENDIF
   ENDIF
   IF !::lResource
      hwg_Movewindow( ::handle, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      // HEIGHT COMBOBOX
      hwg_Sendmessage( ::handle, CB_SETITEMHEIGHT, - 1, ::nHeightBox )
   ENDIF
   ::Refresh()
   IF ::lEdit
      hwg_Sendmessage( ::handle, CB_SETEDITSEL , - 1, 0 )
      hwg_Sendmessage( ::handle, WM_SETREDRAW, 1 , 0 )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HComboBoxEx
   LOCAL oCtrl

   IF ::bOther != Nil
      IF Eval( ::bOther, Self, msg, wParam, lParam ) != - 1
         RETURN 0
      ENDIF
   ENDIF
   IF msg = WM_MOUSEWHEEL .AND. ::oParent:nScrollBars != - 1 .AND. ::oParent:bScroll = Nil
      hwg_ScrollHV( ::oParent, msg, wParam, lParam )
      RETURN 0
   ELSEIF msg = CB_SHOWDROPDOWN
      ::ldropshow := iif( wParam = 1, .T. , ::ldropshow )
   ENDIF

   IF ::bSetGet != Nil .OR. hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
      IF msg == WM_CHAR .AND. ( hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE .OR. ;
            ! hwg_GetParentForm( Self ) :lModal )
         IF wParam = VK_TAB
            hwg_GetSkip( ::oParent, ::handle, , iif( hwg_IsCtrlShift( .F. , .T. ), - 1, 1 ) )
            RETURN 0
         ELSEIF wParam == VK_RETURN .AND. ;
               ( hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE .OR. ;
               ! hwg_GetParentForm( Self ):lModal )
               //! hwg_ProcOkCancel( Self, wParam, hwg_GetParentForm( Self ):Type >= WND_DLG_RESOURCE ) .AND. ;
            hwg_GetSkip( ::oParent, ::handle, , 1 )
            RETURN 0
         ENDIF
      ELSEIF msg == WM_GETDLGCODE
         IF wParam = VK_RETURN
            RETURN DLGC_WANTMESSAGE
         ELSEIF wParam = VK_ESCAPE  .AND. ;
               ( oCtrl := hwg_GetParentForm( Self ):FindControl( IDCANCEL ) ) != Nil .AND. ! oCtrl:IsEnabled()
            RETURN DLGC_WANTMESSAGE
         ENDIF
         RETURN  DLGC_WANTCHARS + DLGC_WANTARROWS

      ELSEIF msg = WM_KEYDOWN
         IF wparam =  VK_RIGHT .OR. wParam == VK_RETURN
            hwg_GetSkip( ::oParent, ::handle, , 1 )
            RETURN 0
         ELSEIF wparam =  VK_LEFT
            hwg_GetSkip( ::oParent, ::handle, , - 1 )
            RETURN 0
         ELSEIF wParam = VK_ESCAPE .AND. hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
            RETURN 0
         ENDIF

      ELSEIF msg = WM_KEYUP
         //hwg_ProcKeyList( Self, wParam )        //working in MDICHILD AND DIALOG
      ELSEIF msg =  WM_COMMAND  .AND. ::lEdit  .AND. ! ::ldropshow
         IF hwg_Getkeystate( VK_DOWN ) + hwg_Getkeystate( VK_UP ) < 0 .AND. hwg_Getkeystate( VK_SHIFT ) > 0 .AND. hwg_Hiword( wParam ) = 1
            RETURN 0
         ENDIF
      ELSEIF msg = CB_GETDROPPEDSTATE  .AND. ! ::ldropshow
         IF hwg_Getkeystate( VK_RETURN ) < 0
            ::GetValue()
         ENDIF
         IF ( hwg_Getkeystate( VK_RETURN ) < 0 .OR. hwg_Getkeystate( VK_ESCAPE ) < 0 ) .AND. ( hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE .OR. ;
               ! hwg_GetParentForm( Self ):lModal )
            //hwg_ProcOkCancel( Self, iif( hwg_Getkeystate( VK_RETURN ) < 0, VK_RETURN, VK_ESCAPE ) )
         ENDIF
         IF hwg_Getkeystate( VK_TAB ) + hwg_Getkeystate( VK_DOWN ) < 0 .AND. hwg_Getkeystate( VK_SHIFT ) > 0
            IF ::oParent:oParent = Nil
            ENDIF
            hwg_GetSkip( ::oParent, ::handle, , 1 )
            RETURN 0
         ELSEIF hwg_Getkeystate( VK_UP ) < 0 .AND.  hwg_Getkeystate( VK_SHIFT ) > 0
            IF ::oParent:oParent = Nil
            ENDIF
            hwg_GetSkip( ::oParent, ::handle, , - 1 )
            RETURN 0
         ENDIF
         IF ( hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE .OR. ! hwg_GetParentForm( Self ):lModal )
            RETURN 1
         ENDIF
      ENDIF
   ENDIF

   RETURN - 1

METHOD MaxLength( nMaxLength ) CLASS HComboBoxEx

   IF nMaxLength != Nil .AND. ::lEdit
      hwg_Sendmessage( ::handle, CB_LIMITTEXT, nMaxLength, 0 )
      ::nMaxLength := nMaxLength
   ENDIF

   RETURN ::nMaxLength

METHOD Requery( aItems, xValue ) CLASS HComboBoxEx

   hwg_Sendmessage( ::handle, CB_RESETCONTENT, 0, 0 )
   IF aItems != Nil
      ::aItems := aItems
   ENDIF
   ::Populate()
   IF xValue != Nil
      ::SetValue( xValue )
   ELSEIF  Empty( ::Value ) .AND. Len( ::aItems ) > 0 .AND. ::bSetGet = Nil  .AND. ! ::lEdit
      ::SetItem( 1 )
   ENDIF

   RETURN Nil

METHOD Refresh() CLASS HComboBoxEx
   LOCAL vari

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet, , Self )
      IF ::columnBound = 2
         vari := ::GetValueBound( vari )
      ENDIF
      IF  ::columnBound = 1
         IF ::lText
            ::value := iif( vari == Nil .OR. ValType( vari ) != "C", "", vari )
         ELSE
            ::value := iif( vari == Nil .OR. ValType( vari ) != "N", 1 , vari )
         ENDIF
      ENDIF
   ENDIF

   IF ::lText
      IF ::lEdit
         hwg_Setdlgitemtext( hwg_GetModalHandle(), ::id, ::value )
         hwg_Sendmessage( ::handle, CB_SETEDITSEL, 0, ::SelStart )
      ENDIF
      hwg_Combosetstring( ::handle, AScan( ::aItems, ::value, , , .T.  ) )
   ELSE
      hwg_Combosetstring( ::handle, ::value )
   ENDIF
   ::valueBound := ::GetValueBound()

   RETURN Nil

METHOD SetItem( nPos ) CLASS HComboBoxEx

   IF ::lText
      IF nPos > 0
         ::value := ::aItems[nPos]
         ::ValueBound := ::GetValueBound()
      ELSE
         ::value := ""
         ::valueBound := iif( ::bSetGet != Nil, Eval( ::bSetGet,, Self ), ::valueBound )
      ENDIF
   ELSE
      ::value := nPos
      ::ValueBound := ::GetValueBound()
   ENDIF

   hwg_Combosetstring( ::handle, nPos )

   IF ::bSetGet != Nil
      IF ::columnBound = 1
         Eval( ::bSetGet, ::value, Self )
      ELSE
         Eval( ::bSetGet, ::valuebound, Self )
      ENDIF
   ENDIF

   RETURN Nil

METHOD SetValue( xItem ) CLASS HComboBoxEx
   LOCAL nPos

   IF ::lText .AND. ValType( xItem ) = "C"
      IF ::columnBound = 2
         nPos := AScan( ::aItemsBound, xItem )
      ELSE
         nPos := AScan( ::aItems, xItem )
      ENDIF
      hwg_Combosetstring( ::handle, nPos )
   ELSE
      nPos := iif( ::columnBound = 2, AScan( ::aItemsBound, xItem ), xItem )
   ENDIF
   ::setItem( nPos )

   RETURN Nil

METHOD GetValue() CLASS HComboBoxEx
   LOCAL nPos := hwg_Sendmessage( ::handle, CB_GETCURSEL, 0, 0 ) + 1

   IF ::lText
      IF ( ::lEdit .OR. ValType( ::Value ) != "C" ) .AND. nPos <= 1
         ::Value := hwg_Getwindowtext( ::handle )
         nPos := hwg_Sendmessage( ::handle, CB_FINDSTRINGEXACT, - 1, ::value ) + 1
      ELSEIF nPos > 0
         ::value := ::aItems[ nPos ]
      ENDIF
      ::cDisplayValue := ::Value
      ::value := iif( nPos > 0, ::aItems[ nPos ], iif( ::lEdit, "", ::value ) )
   ELSE
      ::value := nPos
   ENDIF
   ::ValueBound := iif( nPos > 0, ::GetValueBound(), ::ValueBound )
   IF ::bSetGet != Nil
      IF ::columnBound = 1
         Eval( ::bSetGet, ::value, Self )
      ELSE
         Eval( ::bSetGet, ::ValueBound, Self )
      ENDIF
   ENDIF

   RETURN ::value

METHOD GetValueBound( xItem ) CLASS HComboBoxEx
   LOCAL nPos := hwg_Sendmessage( ::handle, CB_GETCURSEL, 0, 0 ) + 1

   IF ::columnBound = 1
      RETURN Nil
   ENDIF
   IF xItem = Nil
      IF ::lText
         nPos := iif( ::Value = Nil, 0,  AScan( ::aItems, ::value, , , .T.  ) )
      ENDIF
   ELSE
      nPos := AScan( ::aItemsBound, xItem, , , .T. )
      ::setItem( nPos )
      RETURN iif( nPos > 0, ::aItems[ nPos ], xItem )
   ENDIF
   IF nPos > 0 .AND. nPos <=  Len( ::aItemsBound )
      ::ValueBound := ::aItemsBound[ nPos ]
   ENDIF

   RETURN ::ValueBound

METHOD DisplayValue( cValue ) CLASS HComboBoxEx

   IF cValue != Nil
      IF ::lEdit .AND. ValType( cValue ) = "C"
         hwg_Setdlgitemtext( ::oParent:handle, ::id, cValue )
         ::cDisplayValue := cValue
      ENDIF
   ENDIF

   RETURN iif( ! ::lEdit, hwg_Getwindowtext( ::handle ), ::cDisplayValue )

METHOD DeleteItem( xIndex ) CLASS HComboBoxEx
   LOCAL nIndex

   IF ::lText .AND. ValType( xIndex ) = "C"
      nIndex := hwg_Sendmessage( ::handle, CB_FINDSTRINGEXACT, - 1, xIndex ) + 1
   ELSE
      nIndex := xIndex
   ENDIF
   IF hwg_Sendmessage( ::handle, CB_DELETESTRING, nIndex - 1, 0 ) > 0
      ADel( ::Aitems, nIndex )
      ASize( ::Aitems, Len( ::aitems ) - 1 )
      IF Len( ::AitemsBound ) > 0
         ADel( ::AitemsBound, nIndex )
         ASize( ::AitemsBound, Len( ::aitemsBound ) - 1 )
      ENDIF
      RETURN .T.
   ENDIF

   RETURN .F.

METHOD AddItem( cItem, cItemBound, nPos ) CLASS HComboBoxEx

   LOCAL nCount

   nCount := hwg_Sendmessage( ::handle, CB_GETCOUNT, 0, 0 ) + 1
   IF Len( ::Aitems ) == Len( ::AitemsBound ) .AND. cItemBound != NIL
      IF nCount = 1
         ::RowSource(  { { cItem,  cItemBound } } )
         ::Aitems := { }
      ENDIF
      IF nPos != Nil .AND. nPos > 0 .AND. nPos < nCount
         ASize( ::AitemsBound, nCount + 1 )
         AIns( ::AitemsBound, nPos, cItemBound )
      ELSE
         AAdd( ::AitemsBound, cItemBound )
      ENDIF
      ::columnBound := 2
   ENDIF
   IF nPos != Nil .AND. nPos > 0 .AND. nPos < nCount
      ASize( ::Aitems, nCount + 1 )
      AIns( ::Aitems, nPos, cItem )
   ELSE
      AAdd( ::Aitems, cItem )
   ENDIF
   IF nPos != Nil .AND. nPos > 0 .AND. nPos < nCount
      hwg_Comboinsertstring( ::handle, nPos - 1, cItem )
   ELSE
      hwg_Comboaddstring( ::handle, cItem )
   ENDIF

   RETURN nCount

METHOD SetCueBanner( cText, lShowFoco ) CLASS HComboBoxEx
   LOCAL lRet := .F.

   IF ::lEdit
      lRet := hwg_Sendmessage( ::Handle, CB_SETCUEBANNER, ;
         iif( Empty( lShowFoco ), 0, 1 ), hwg_Ansitounicode( cText ) )
   ENDIF

   RETURN lRet

METHOD InteractiveChange( ) CLASS HComboBoxEx

   LOCAL npos := hwg_Sendmessage( ::handle, CB_GETEDITSEL, 0, 0 )

   ::SelStart := nPos
   ::cDisplayValue := hwg_Getwindowtext( ::handle )
   //::oparent:lSuspendMsgsHandling := .T.
   Eval( ::bChangeInt, ::value, Self )
   //::oparent:lSuspendMsgsHandling := .F.

   hwg_Sendmessage( ::handle, CB_SETEDITSEL, 0, ::SelStart )

   RETURN Nil

METHOD onSelect() CLASS HComboBoxEx

   IF ::bSelect != Nil
      // ::oparent:lSuspendMsgsHandling := .T.
      Eval( ::bSelect, ::value, Self )
      // ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN .T.

METHOD onChange( lForce ) CLASS HComboBoxEx

   IF ! hwg_Selffocus( ::handle ) .AND. Empty( lForce )
      RETURN Nil
   ENDIF
   IF  ! hwg_Iswindowvisible( ::handle )
      ::SetItem( ::Value )
      RETURN Nil
   ENDIF

   ::SetItem( hwg_Sendmessage( ::handle, CB_GETCURSEL, 0, 0 ) + 1 )
   IF ::bChangeSel != Nil
      // ::oparent:lSuspendMsgsHandling := .T.
      Eval( ::bChangeSel, ::Value, Self )
      // ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN Nil

METHOD When( ) CLASS HComboBoxEx
   LOCAL res := .T. , oParent, nSkip

   //IF !hwg_CheckFocus( Self, .F. )
   //   RETURN .T.
   //ENDIF

   nSkip := iif( hwg_Getkeystate( VK_UP ) < 0 .OR. ( hwg_Getkeystate( VK_TAB ) < 0 .AND. hwg_Getkeystate( VK_SHIFT ) < 0 ), - 1, 1 )
   IF ::bGetFocus != Nil
      IF ::bSetGet != Nil
         res := Eval( ::bGetFocus, Eval( ::bSetGet,, Self ), Self )
      ELSE
         res := Eval( ::bGetFocus, ::value, Self )
      ENDIF
      IF ValType( res ) = "L" .AND. ! res
         oParent := hwg_GetParentForm( Self )
         IF Self == ATail( oParent:GetList )
            nSkip := - 1
         ELSEIF Self == oParent:getList[ 1 ]
            nSkip := 1
         ENDIF
         //hwg_WhenSetFocus( Self, nSkip )
      ENDIF
   ENDIF

   // Suppress warning: nSkip is kept for future reactivation of hwg_WhenSetFocus
   HB_SYMBOL_UNUSED( nSkip )

   RETURN res

METHOD RowSource( xSource ) CLASS HComboBoxEx

   IF xSource != Nil
      IF ValType( xSource ) = "A"
         IF Len( xSource ) > 0 .AND. ! hb_IsArray( xSource[ 1 ] ) .AND. Len( xSource ) <= 2 .AND. "->" $ xSource[ 1 ] // COLUMNS MAX = 2
            ::xrowsource := { xSource[ 1 ] , iif( Len( xSource ) > 1, xSource[ 2 ], Nil ) }
         ENDIF
      ELSE
         ::xrowsource := { xSource, Nil }
      ENDIF
      ::aItems := xSource
   ENDIF

   RETURN ::xRowSource

METHOD Populate() CLASS HComboBoxEx
   LOCAL cAlias, nRecno, value, cValueBound
   LOCAL i, numofchars, LongComboWidth := 0
   LOCAL xRowSource

   IF Empty( ::aItems )
      RETURN Nil
   ENDIF
   xRowSource := iif( hb_IsArray( ::xRowSource[ 1 ] ), ::xRowSource[ 1, 1 ], ::xRowSource[ 1 ] )
   IF xRowSource != Nil .AND. ( i := At( "->", xRowSource ) ) > 0
      cAlias := AllTrim( Left( xRowSource, i - 1 ) )
      IF SELECT( cAlias ) = 0 .AND. ( i := At( "(", cAlias ) ) > 0
         cAlias := LTrim( SubStr( cAlias, i + 1 ) )
      ENDIF
      value  := StrTran( xRowSource, calias + "->", , , 1, 1 )
      cAlias := iif( ValType( xRowSource ) == "U",  Nil, cAlias )
      cValueBound := iif( ::xrowsource[ 2 ]  != Nil  .AND. cAlias != Nil, StrTran( ::xrowsource[ 2 ] , calias + "->" ), Nil )
   ELSE
      cValueBound := iif( ValType( ::aItems[ 1 ] ) == "A" .AND. Len(  ::aItems[ 1 ] ) > 1, ::aItems[ 1, 2 ], NIL )
   ENDIF
   ::columnBound := iif( cValueBound = Nil, 1 , 2 )
   IF ::value == Nil
      IF ::lText
         ::value := iif( cAlias = Nil, ::aItems[1], ( cAlias ) -> ( &( value ) ) )
      ELSE
         ::value := 1
      ENDIF
   ELSEIF ::lText .AND. !::lEdit .AND. Empty ( ::value )
      ::value := iif( cAlias = Nil, ::aItems[1], ( cAlias ) -> ( &( value ) ) )
   ENDIF
   hwg_Sendmessage( ::handle, CB_RESETCONTENT, 0, 0 )
   ::AitemsBound := {}
   IF cAlias != Nil .AND. Select( cAlias ) > 0
      ::aItems := {}
      nRecno := ( cAlias ) -> ( RecNo() )
      ( cAlias ) -> ( DBGOTOP() )
      i := 1
      DO WHILE !( cAlias ) -> ( Eof() )
         AAdd( ::Aitems, ( cAlias ) -> ( &( value ) ) )
         IF !Empty( cvaluebound )
            AAdd( ::AitemsBound, ( cAlias ) -> ( &( cValueBound ) ) )
         ENDIF
         hwg_Comboaddstring( ::handle, ::aItems[ i ] )
         numofchars := hwg_Sendmessage( ::handle, CB_GETLBTEXTLEN, i - 1, 0 )
         IF  numofchars > LongComboWidth
            LongComboWidth := numofchars
         ENDIF
         ( cAlias ) -> ( dbSkip() )
         i ++
      ENDDO
      IF nRecno > 0
         ( cAlias ) -> ( dbGoto( nRecno ) )
      ENDIF
   ELSE
   tracelog(valtoprg( ::aItems ))
      FOR i := 1 TO Len( ::aItems )
         IF ::columnBound > 1
            IF ValType( ::aItems[ i ] ) = "A" .AND. Len(  ::aItems[ i ] ) > 1
               AAdd( ::AitemsBound, ::aItems[i, 2 ] )
            ELSE
               AAdd( ::AitemsBound, Nil )
            ENDIF
            ::aItems[ i ] := ::aItems[ i, 1 ]
            hwg_Comboaddstring( ::handle, ::aItems[ i ] )
         ELSE
            hwg_Comboaddstring( ::handle, ::aItems[ i ] )
         ENDIF
         numofchars := hwg_Sendmessage( ::handle, CB_GETLBTEXTLEN, i - 1, 0 )
         IF  numofchars > LongComboWidth
            LongComboWidth := numofchars
         ENDIF
      NEXT
   ENDIF
   ::ValueBound := ::GetValueBound()

   RETURN LongComboWidth



CLASS HCheckComboBox INHERIT HComboBoxEx

   CLASS VAR winclass  INIT "COMBOBOX"
   DATA m_bTextUpdated INIT .F.

   DATA m_bItemHeightSet INIT .F.
   DATA m_hListBox   INIT 0
   DATA aCheck
   DATA nWidthCheck  INIT 0
   DATA m_strText    INIT ""

   DATA lCheck
   DATA nCurPos      INIT 0
   DATA aHimages, aImages

   METHOD onGetText( wParam, lParam )
   METHOD OnGetTextLength( wParam, lParam )

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      aItems, oFont, bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, ;
      tcolor, bcolor, bValid, acheck, nDisplay, nhItem, ncWidth, aImages )

   METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
      bChange, ctooltip, bGFocus, acheck, aImages )
   METHOD INIT()
   METHOD Requery()
   METHOD Refresh()
   METHOD Paint( lpDis )
   METHOD SetCheck( nIndex, bFlag )
   METHOD RecalcText()

   METHOD GetCheck( nIndex )

   METHOD SelectAll( bCheck )
   METHOD MeasureItem( l )

   METHOD onEvent( msg, wParam, lParam )
   METHOD GetAllCheck()

   METHOD EnabledItem( nItem, lEnabled )
   METHOD SkipItems( nNav )

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
      bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, ;
      bValid, acheck, nDisplay, nhItem, ncWidth, aImages ) CLASS hCheckComboBox

   ::acheck := iif( acheck == Nil, {}, acheck )
   ::lCheck := iif( aImages == Nil, .T. , .F. )
   ::aImages := aImages

   IF ValType( nStyle ) == "N"
      nStyle := hwg_multibitor( nStyle, CBS_DROPDOWNLIST, CBS_OWNERDRAWVARIABLE, CBS_HASSTRINGS )
   ELSE
      nStyle := hwg_multibitor( CBS_DROPDOWNLIST, CBS_OWNERDRAWVARIABLE, CBS_HASSTRINGS )
   ENDIF

   bPaint := { | o, p | o:paint( p ) }

   ::Super:New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
      bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, ;
      bValid, , nDisplay, nhItem, ncWidth )

   RETURN Self

METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
      bChange, ctooltip, bGFocus, acheck, aImages ) CLASS hCheckComboBox
      bPaint := { | o, p | o:paint( p ) }
     ::acheck := iif( acheck == Nil, {}, acheck )
     ::lCheck := iif( aImages == Nil, .T. , .F. )
     ::aImages := aImages
     ::Super:Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
      bChange, ctooltip, bGFocus,, , , , , ,aCheck )

   ::lResource := .T.


   RETURN Self

METHOD INIT() CLASS hCheckComboBox
   LOCAL i, nSize, hImage

   IF !::lInit
      ::Super:Init()

      IF Len( ::acheck ) > 0
         AEval( ::aCheck, { | a ,v| ::Setcheck(v, a ) } )
      ENDIF
      IF !Empty( ::aItems ) .AND. !Empty( ::nhItem )
         FOR i := 1 TO Len( ::aItems )
            hwg_Sendmessage( ::handle, CB_SETITEMHEIGHT , i - 1, ::nhItem )
         NEXT
      ENDIF
      ::nCurPos := hwg_Sendmessage( ::handle, CB_GETCURSEL, 0, 0 )
      // LOAD IMAGES COMBO
      IF ::aImages != Nil .AND. Len( ::aImages ) > 0
         ::aHImages := {}
         nSize := hwg_Sendmessage( ::handle, CB_GETITEMHEIGHT, - 1, 0 ) - 5
         FOR i := 1 TO Len( ::aImages )
            hImage := 0
            IF ( ValType( ::aImages[ i ] ) == "C" .OR. ::aImages[ i ] > 1 ) .AND. ! Empty( ::aImages[ i ] )
               IF ValType( ::aImages[ i ] ) == "C" .AND. At( ".", ::aImages[ i ] ) != 0
                  IF File( ::aImages[ i ] )
                     hImage := HBITMAP():AddfILE( ::aImages[ i ], , .T. , 16, nSize ):handle
                  ENDIF
               ELSE
                  hImage := HBitmap():AddResource( ::aImages[ i ], , , 16, nSize ):handle
               ENDIF
            ENDIF
            AAdd( ::aHImages,  hImage )
         NEXT
      ENDIF
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS hCheckComboBox
   LOCAL nIndex
   LOCAL rcItem, rcClient
   LOCAL pt
   LOCAL nItemHeight
   LOCAL nTopIndex
   LOCAL nPos

   IF msg == WM_RBUTTONDOWN
   ELSEIF msg == LB_GETCURSEL
      RETURN - 1

   ELSEIF msg == WM_MEASUREITEM
      ::MeasureItem( lParam )
      RETURN 0
   ELSEIF msg == WM_GETTEXT
      RETURN ::OnGetText( wParam, lParam )

   ELSEIF msg == WM_GETTEXTLENGTH
      RETURN ::OnGetTextLength( wParam, lParam )

   ELSEIF msg = WM_MOUSEWHEEL
      RETURN ::SkipItems( iif( hwg_Hiword( wParam ) > 32768, 1, - 1 ) )

   ELSEIF msg = WM_COMMAND
      IF hwg_Hiword( wParam ) = CBN_SELCHANGE
         nPos := hwg_Sendmessage( ::handle, CB_GETCURSEL, 0, 0 )
         IF Left( ::Title, 2 ) == "\]" .OR. Left( ::Title, 2 ) == "\-"
            RETURN 0
         ELSE
            ::nCurPos := nPos
         ENDIF
      ENDIF

   ELSEIF msg == WM_CHAR

      IF ( wParam == VK_SPACE )
         nIndex := hwg_Sendmessage( ::handle, CB_GETCURSEL, wParam, lParam ) + 1
         rcItem := hwg_Combogetitemrect( ::handle, nIndex - 1 )
         hwg_Invalidaterect( ::handle, .F. , rcItem[ 1 ], rcItem[ 2 ], rcItem[ 3 ], rcItem[ 4 ] )
         ::SetCheck( nIndex, !::GetCheck( nIndex ) )
         hwg_Sendmessage( ::oParent:handle, WM_COMMAND, hwg_Makelong( ::id, CBN_SELCHANGE ), ::handle )
      ENDIF
      IF ( hwg_GetParentForm( Self ) :Type < WND_DLG_RESOURCE .OR. !hwg_GetParentForm( Self ) :lModal )
         IF wParam = VK_TAB
            hwg_GetSkip( ::oParent, ::handle, , iif( hwg_IsCtrlShift( .F. , .T. ), - 1, 1 ) )
            RETURN 0
         ELSEIF wParam == VK_RETURN
            hwg_GetSkip( ::oParent, ::handle, , 1 )
            RETURN 0
         ENDIF
      ENDIF
      RETURN 0
   ELSEIF msg = WM_KEYDOWN

      IF wParam = VK_HOME .OR. wParam = VK_END
         nPos := iif( wParam = VK_HOME, ;
            Ascan( ::aItems, { | a | ! Left( a[ 1 ], 2 ) $ "\-" + Chr( 0 ) + "\]" } , , ) , ;
            RAscan( ::aItems, { | a | ! Left( a[ 1 ], 2 ) $ "\-" + Chr( 0 ) + "\]" } , , ) )
         IF nPos - 1 != ::nCurPos
            hwg_Setfocus( Nil )
            hwg_Sendmessage( ::handle, CB_SETCURSEL, nPos - 1, 0 )
            hwg_Sendmessage( ::oParent:handle, WM_COMMAND, hwg_Makelong( ::id, CBN_SELCHANGE ), ::handle )
            ::nCurPos := nPos - 1
            RETURN 0
         ENDIF
      ELSEIF ( wParam = VK_UP .OR. wParam = VK_DOWN )
         RETURN ::SkipItems( iif( wParam = VK_DOWN, 1, - 1 ) )
      ENDIF
      //hwg_ProcKeyList( Self, wParam )

   ELSEIF msg = WM_KEYUP
      IF ( wParam = VK_DOWN .OR. wParam = VK_UP )
         IF Left( ::Title, 2 ) == "\]" .OR. Left( ::Title, 2 ) == "\-"
            RETURN 0
         ENDIF
      ENDIF


   ELSEIF msg == WM_LBUTTONDOWN

      rcClient := hwg_Getclientrect( ::handle )

      pt := { , }
      pt[ 1 ] = hwg_Loword( lParam )
      pt[ 2 ] = hwg_Hiword( lParam )

      IF ( hwg_Ptinrect( rcClient, pt ) )

         nItemHeight := hwg_Sendmessage( ::handle, LB_GETITEMHEIGHT, 0, 0 )
         nTopIndex   := hwg_Sendmessage( ::handle, LB_GETTOPINDEX, 0, 0 )

         // Compute which index to check/uncheck
         nIndex := ( nTopIndex + pt[ 2 ] / nItemHeight ) + 1
         rcItem := hwg_Combogetitemrect( ::handle, nIndex - 1 )

         IF pt[ 1 ] < ::nWidthCheck
            // Invalidate this window
            hwg_Invalidaterect( ::handle, .F. , rcItem[ 1 ], rcItem[ 2 ], rcItem[ 3 ], rcItem[ 4 ] )
            nIndex := hwg_Sendmessage( ::handle, CB_GETCURSEL, wParam, lParam ) + 1
            ::SetCheck( nIndex, !::GetCheck( nIndex ) )

            // Notify that selection has changed

            hwg_Sendmessage( ::oParent:handle, WM_COMMAND, hwg_Makelong( ::id, CBN_SELCHANGE ), ::handle )

         ENDIF
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      RETURN - 1
   ENDIF

   RETURN - 1

METHOD Requery() CLASS hCheckComboBox
   LOCAL i

   ::Super:Requery()
   IF Len( ::acheck ) > 0
      AEval( ::aCheck, { | a ,v| ::Setcheck( v,a ) } )
   ENDIF
   IF !Empty( ::aItems ) .AND. !Empty( ::nhItem )
      FOR i := 1 TO Len( ::aItems )
         hwg_Sendmessage( ::handle, CB_SETITEMHEIGHT , i - 1, ::nhItem )
      NEXT
   ENDIF

   RETURN Nil

METHOD Refresh() CLASS hCheckComboBox

   ::Super:refresh()

   RETURN Nil

METHOD SetCheck( nIndex, bFlag ) CLASS hCheckComboBox

   LOCAL nResult := hwg_Comboboxsetitemdata( ::handle, nIndex - 1, bFlag )

   IF ( nResult < 0 )
      RETURN nResult
   ENDIF

   ::m_bTextUpdated := FALSE

   // Redraw the window
   hwg_Invalidaterect( ::handle, 0 )

   RETURN nResult

METHOD GetCheck( nIndex ) CLASS hCheckComboBox

   LOCAL l := hwg_Comboboxgetitemdata( ::handle, nIndex - 1 )

   RETURN iif( l == 1, .T. , .F. )

METHOD SelectAll( bCheck ) CLASS hCheckComboBox

   LOCAL nCount
   LOCAL i

   DEFAULT bCheck TO .T.

   nCount := hwg_Sendmessage( ::handle, CB_GETCOUNT, 0, 0 )

   FOR i := 1 TO nCount
      ::SetCheck( i, bCheck )
   NEXT

   RETURN nil

METHOD RecalcText() CLASS hCheckComboBox
   LOCAL strtext
   LOCAL ncount
   LOCAL strSeparator
   LOCAL i
   LOCAL stritem

   IF ( !::m_bTextUpdated )

      // Get the list count
      ncount := hwg_Sendmessage( ::handle, CB_GETCOUNT, 0, 0 )

      // Get the list separator

      strSeparator := hwg_Getlocaleinfo()

      // If none found, the the ''
      IF Len( strSeparator ) == 0
         strSeparator := ''
      ENDIF

      strSeparator := RTrim( strSeparator )

      strSeparator += ' '

      FOR i := 1 TO ncount

         IF ( hwg_Comboboxgetitemdata( ::handle, i ) ) = 1

            hwg_Comboboxgetlbtext( ::handle, i, @stritem )

            IF !Empty( strtext )
               strtext += strSeparator
            ENDIF
            //strtext += stritem     // error
         ENDIF
      NEXT

      // Set the text
      ::m_strText := strtext

      ::m_bTextUpdated := TRUE
   ENDIF

   RETURN Self

METHOD Paint( lpDis ) CLASS hCheckComboBox

   LOCAL drawInfo := hwg_Getdrawiteminfo( lpDis )

   LOCAL dc := drawInfo[ 3 ]

   LOCAL rcBitmap := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] }
   LOCAL rcText   := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] }
   LOCAL strtext  := "", cTmp
   LOCAL ncheck   := 0
   LOCAL metrics
   LOCAL nstate
   LOCAL iStyle  := ST_ALIGN_HORIZ
   LOCAL nIndent
   LOCAL hbitmap := 0, bmpRect
   LOCAL lDroped := hwg_Sendmessage( ::handle, CB_GETDROPPEDSTATE, 0, 0 ) > 0

   IF ( drawInfo[ 1 ] < 0 )

      ::RecalcText()

      strtext := ::m_strText


      ncheck := 0

   ELSE
      hwg_Comboboxgetlbtext( ::handle, drawInfo[ 1 ], @strtext )

      IF  ::lCheck
         ncheck := 1 + ( hwg_Comboboxgetitemdata( ::handle, drawInfo[ 1 ] ) )
         metrics := hwg_Gettextmetric( dc )
         rcBitmap[ 1 ] := 0
         rcBitmap[ 3 ] := rcBitmap[ 1 ] + metrics[ 1 ] + metrics[ 4 ] + 6
         rcBitmap[ 2 ] += 1
         rcBitmap[ 4 ] -= 1

         rcText[ 1 ]   := rcBitmap[ 3 ]
         ::nWidthCheck := rcBitmap[ 3 ]

      ELSEIF ::aHImages != Nil .AND. DrawInfo[ 1 ] + 1 <= Len( ::aHImages ) .AND. ;
            ! Empty( ::aHImages[ DrawInfo[ 1 ] + 1 ] )
         nIndent := iif( ! lDroped, 1, ( Len( strText ) - Len( LTrim( strText ) ) ) * hwg_TxtRect( "a", Self, ::oFont )[ 1 ] )
         strtext := LTrim( strtext )
         hbitmap := ::aHImages[ DrawInfo[ 1 ] + 1 ]
         rcBitmap[ 1 ] := nIndent
         bmpRect := hwg_Prepareimagerect( ::handle, dc, .T. , @rcBitmap, @rcText, , , hbitmap, iStyle )
         rcText[ 1 ] :=  iif( iStyle = ST_ALIGN_HORIZ, nIndent + hwg_Getbitmapsize( hbitmap )[ 1 ] + iif( lDroped, 3, 4 ) , 1 )
      ENDIF

   ENDIF

   // Erase and draw
   IF Empty( strtext )
      strtext := ""
   ENDIF
   ::Title := strtext
   cTmp := Left( ::Title, 2 )

   IF cTmp == "\]" .OR. cTmp == "\-"
      IF ! lDroped
         hwg_Exttextout( dc, 0, 0, iif( ::lCheck, rcText[ 1 ], 0 ), rcText[ 2 ], rcText[ 3 ], rcText[ 4 ] )
         RETURN 0
      ENDIF
   ENDIF
   IF ( ncheck > 0 ) .AND. cTmp != "\-"
      hwg_Setbkcolor( dc, hwg_Getsyscolor( COLOR_WINDOW ) )
      hwg_Settextcolor( dc, hwg_Getsyscolor( COLOR_WINDOWTEXT ) )

      nstate := DFCS_BUTTONCHECK

      IF ( ncheck > 1 )
         nstate := hwg_bitor( nstate, DFCS_CHECKED )
      ENDIF

      // Draw the checkmark using DrawFrameControl
      hwg_Drawframecontrol( dc, rcBitmap, DFC_BUTTON, nstate )
   ENDIF

   IF ( hwg_Bitand( drawInfo[ 9 ], ODS_SELECTED ) != 0 )
      hwg_Setbkcolor( dc, hwg_Getsyscolor( COLOR_HIGHLIGHT ) )
      hwg_Settextcolor( dc, hwg_Getsyscolor( COLOR_HIGHLIGHTTEXT ) )
   ELSE
      hwg_Setbkcolor( dc, hwg_Getsyscolor( COLOR_WINDOW ) )
      hwg_Settextcolor( dc, hwg_Getsyscolor( COLOR_WINDOWTEXT ) )
   ENDIF

   IF cTmp == "\]"
      hwg_Settextcolor( dc, hwg_Getsyscolor( COLOR_GRAYTEXT ) )
      strtext := SubStr( strText, 3 )
   ENDIF
   IF cTmp == "\-"
      hwg_Drawline( DC, 1, rcText[ 2 ] + ( rcText[ 4 ] - rcText[ 2 ] ) / 2 , ;
         rcText[ 3 ] - 1, ;
         rcText[ 2 ] + ( rcText[ 4 ] - rcText[ 2 ] ) / 2 )
   ELSE
      hwg_Exttextout( dc, 0, 0, iif( ::lCheck, rcText[ 1 ], 0 ), rcText[ 2 ], rcText[ 3 ], rcText[ 4 ] )
      hwg_Drawtext( dc, ' ' + strtext, rcText[ 1 ], rcText[ 2 ], rcText[ 3 ], rcText[ 4 ], DT_SINGLELINE + DT_VCENTER + DT_END_ELLIPSIS )
   ENDIF
   IF hbitmap != 0
      hwg_Setbkmode( dc, TRANSPARENT )
      IF cTmp == "\]"
         hwg_Drawgraybitmap( dc, hbitmap, bmpRect[ 1 ]  , bmpRect[ 2 ] + 1 )
      ELSE
         hwg_Drawtransparentbitmap( dc, hbitmap, bmpRect[ 1 ]  , bmpRect[ 2 ] + 1 )
      ENDIF
   ENDIF
   IF ( ( hwg_Bitand( DrawInfo[ 9 ], ODS_FOCUS + ODS_SELECTED ) ) == ( ODS_FOCUS + ODS_SELECTED ) )
      IF  cTmp != "\-"  .AND. ! lDroped
         hwg_Drawfocusrect( dc, iif( ::lCheck, rcText , rcBitmap ) )
      ENDIF
   ENDIF

   RETURN Self

METHOD MeasureItem( l ) CLASS hCheckComboBox
   LOCAL dc                  := HCLIENTDC():new( ::handle )
   LOCAL lpMeasureItemStruct := hwg_Getmeasureiteminfo( l )
   LOCAL metrics
   LOCAL pFont

   pFont := dc:Selectobject( iif( ValType( ::oFont ) == "O", ::oFont:handle, ;
      iif( ValType( ::oParent:oFont ) == "O", ::oParent:oFont:handle, ) ) )

   IF !Empty( pFont )

      metrics := dc:Gettextmetric()

      lpMeasureItemStruct[ 5 ] := metrics[ 1 ] + metrics[ 4 ]

      lpMeasureItemStruct[ 5 ] += 2

      IF ( !::m_bItemHeightSet )
         ::m_bItemHeightSet := .T.
         hwg_Sendmessage( ::handle, CB_SETITEMHEIGHT, - 1, hwg_Makelong( lpMeasureItemStruct[ 5 ], 0 ) )
      ENDIF

      dc:Selectobject( pFont )
      dc:END()
   ENDIF

   RETURN Self

METHOD OnGetText( wParam, lParam ) CLASS hCheckComboBox

   ::RecalcText()

   IF ( lParam == 0 )
      RETURN 0
   ENDIF

   // Copy the 'fake' window text
   copydata( lParam, ::m_strText, wParam )

   RETURN iif( Empty( ::m_strText ), 0, Len( ::m_strText ) )

METHOD OnGetTextLength( WPARAM, LPARAM ) CLASS hCheckComboBox

   HB_SYMBOL_UNUSED( WPARAM )
   HB_SYMBOL_UNUSED( LPARAM )

   ::RecalcText()

   RETURN iif( Empty( ::m_strText ), 0, Len( ::m_strText ) )

METHOD GetAllCheck() CLASS hCheckComboBox
   LOCAL aCheck := { }
   LOCAL n

   FOR n := 1 TO Len( ::aItems )
      IF ::GetCheck( n )
         AAdd( aCheck, n )
      ENDIF
   NEXT

   RETURN aCheck

METHOD EnabledItem( nItem, lEnabled ) CLASS hCheckComboBox
   LOCAL cItem

   IF lEnabled != Nil
      IF nItem != Nil .AND. nItem > 0
         IF lEnabled .AND. Left( ::aItems[ nItem ], 2 ) == "\]"
            cItem := SubStr( ::aItems[ nItem ], 3 )
         ELSEIF ! lEnabled .AND. Left( ::aItems[ nItem ], 2 ) != "\]" .AND. Left( ::aItems[ nItem ], 2 ) != "\-"
            cItem := "\]" + ::aItems[ nItem ]
         ENDIF
         IF !Empty( cItem )
            ::aItems[ nItem ] := cItem
            hwg_Sendmessage( ::Handle, CB_DELETESTRING, nItem - 1, 0 )
            hwg_Comboinsertstring( ::handle, nItem - 1, cItem )
         ENDIF
      ENDIF
   ENDIF

   RETURN  ! Left( ::aItems[ nItem ], 2 ) == "\]"

METHOD SkipItems( nNav ) CLASS hCheckComboBox
   LOCAL nPos
   LOCAL strText := ""

   hwg_Comboboxgetlbtext( ::handle, ::nCurPos + nNav, @strText ) // NEXT
   IF Left( strText, 2 ) == "\]" .OR. Left( strText, 2 ) == "\-"
      nPos := iif( nNav > 0, ;
         Ascan(  ::aItems, { | a | ! Left( a[ 1 ], 2 ) $ "\-" + Chr( 0 ) + "\]" }, ::nCurPos + 2  ), ;
         RAscan( ::aItems, { | a | ! Left( a[ 1 ], 2 ) $ "\-" + Chr( 0 ) + "\]" }, ::nCurPos - 1, ) )
      nPos := iif( nPos = 0, ::nCurPos , nPos - 1 )
      hwg_Setfocus( Nil )
      hwg_Sendmessage( ::handle, CB_SETCURSEL, nPos , 0 )
      IF nPos != ::nCurPos
         hwg_Sendmessage( ::oParent:handle, WM_COMMAND, hwg_Makelong( ::id, CBN_SELCHANGE ), ::handle )
      ENDIF
      ::nCurPos := nPos
      RETURN 0
   ENDIF

   RETURN - 1

FUNCTION hwg_multibitor( ... )

   LOCAL aArgumentList := HB_AParams()
   LOCAL nItem
   LOCAL result        := 0

   FOR EACH nItem IN aArgumentList
      IF ValType( nItem ) != "N"
         hwg_Msginfo( "hwg_multibitor parameter not numeric set to zero", "Possible error" )
         nItem := 0
      ENDIF
      result := hwg_bitor( result, nItem )
   NEXT

   RETURN result
