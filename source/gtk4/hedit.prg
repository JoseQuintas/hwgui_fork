/*
 *$Id: hedit.prg 3418 2023-12-16 06:21:23Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HEdit class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  Two things to be aware of:
 *
 * 1. hwg_SetEvent("focus_in_event" | "focus_out_event" | "key_press_event")
 *    are no-ops in GTK4 (those signals were removed).  The equivalent
 *    events arrive automatically because HWG_CREATEEDIT installs the
 *    shared event controllers (see window.c / control.c).
 *
 * 2. hwg_SetSignal("paste-clipboard" | "copy-clipboard") never fires in
 *    GTK4 (those signals were removed from GtkEntry).  The clipboard is
 *    still functional because the WM_KEYDOWN branch of onEvent handles
 *    Ctrl+V / Ctrl+C directly.
 */

#include "hbclass.ch"
#include "hblang.ch"
#include "hwgui.ch"

STATIC lColorinFocus := .F.
STATIC tColorinFocus := 0
STATIC bColorinFocus := 16777164

CLASS HEdit INHERIT HControl

   CLASS VAR winclass   INIT "EDIT"
   DATA lMultiLine   INIT .F.
   DATA cType INIT "C"
   DATA bSetGet
   DATA oPicture
   DATA bValid
   DATA bAnyEvent
   DATA lFirst       INIT .T.
   DATA lChanged     INIT .F.
   DATA nMaxLength   INIT Nil
   DATA nLastKey     INIT 0
   DATA lMouse       INIT .F.
   DATA aColorOld      INIT { 0,0 }
   DATA bColorBlock
   DATA bkeydown

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bGfocus, bLfocus, ctoolt, tcolor, bcolor, cPicture, lNoBorder, nMaxLength, lPassword )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD SetGet( value ) INLINE Eval( ::bSetGet, value, self )
   METHOD Refresh()
   METHOD Value ( xValue ) SETGET
   METHOD SetText( value ) INLINE hwg_edit_SetText( ::handle, ::title := value )
   METHOD GetText() INLINE hwg_edit_GetText( ::handle )

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bGfocus, bLfocus, ctoolt, ;
      tcolor, bcolor, cPicture, lNoBorder, nMaxLength, lPassword ) CLASS HEdit

   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), ;
      WS_TABSTOP + iif( lNoBorder == Nil .OR. !lNoBorder, WS_BORDER, 0 ) + ;
      iif( lPassword == Nil .OR. !lPassword, 0, ES_PASSWORD )  )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize,, ctoolt, Iif(tcolor==Nil,0,tcolor), Iif(bcolor==Nil,0xffffff,bcolor) )

   ::cType := ValType( vari )
   ::title := vari
   ::bSetGet := bSetGet

   IF Hwg_BitAnd( nStyle, ES_MULTILINE ) != 0
      ::style := Hwg_BitOr( ::style, ES_WANTRETURN )
      ::lMultiLine := .T.
   ENDIF

   IF !Empty( cPicture ) .OR. ::cType != "C" .OR. !Empty( bSetGet )
      ::oPicture := HPicture():New( cPicture, vari, nMaxLength )
      ::nMaxLength := ::oPicture:nMaxLength
   ENDIF

   ::Activate()

   ::bGetFocus := bGFocus
   ::bLostFocus := bLFocus

   /* These two are no-ops in GTK4 (focus signals removed); the shared
      event controllers installed by HWG_CREATEEDIT already dispatch
      WM_SETFOCUS / WM_KILLFOCUS to onEvent. */
   hwg_SetEvent( ::handle, "focus_in_event",  WM_SETFOCUS, 0, 0 )
   hwg_SetEvent( ::handle, "focus_out_event", WM_KILLFOCUS, 0, 0 )
   hwg_SetEvent( ::handle, "key_press_event", 0, 0, 0 )

   /* These two never fire in GTK4 (signals removed from GtkEntry), but
      the WM_KEYDOWN branch of onEvent handles Ctrl+V / Ctrl+C. */
   IF ::bSetGet != Nil
      hwg_SetSignal( ::handle, "paste-clipboard", WM_PASTE, 0, 0 )
      hwg_SetSignal( ::handle, "copy-clipboard",  WM_COPY,  0, 0 )
   ENDIF

   RETURN Self

METHOD Activate() CLASS HEdit

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createedit( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      hwg_Setwindowobject( ::handle, Self )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HEdit

   LOCAL oParent
   LOCAL nPos, i, cText

   IF ::bAnyEvent != Nil .AND. Eval( ::bAnyEvent, Self, msg, wParam, lParam ) != 0
      RETURN 0
   ENDIF

   IF msg == WM_SETFOCUS
      oParent := hwg_getParentForm( Self )

      IF lColorinFocus .OR. oParent:tColorinFocus >= 0 .OR. oParent:bColorinFocus >= 0 .OR. ::bColorBlock != Nil
         ::aColorOld[1] := ::tcolor
         ::aColorOld[2] := ::bcolor
         IF ::bColorBlock != Nil
            Eval( ::bColorBlock, Self )
         ELSE
            ::Setcolor( Iif( oParent:tColorinFocus >= 0, oParent:tColorinFocus, tColorinFocus ), ;
                  Iif( oParent:bColorinFocus >= 0, oParent:bColorinFocus, bColorinFocus ), .T. )
         ENDIF
      ENDIF
      IF ::lMouse
         ::lFirst := .F.
         ::lMouse := .F.
      ENDIF
      hwg_edit_set_Overmode( ::handle, !Set( _SET_INSERT ) )
      IF ::bSetGet == Nil
         IF ::bGetFocus != Nil
            Eval( ::bGetFocus, hwg_Edit_GetText( ::handle ), Self )
         ENDIF
      ELSE
         __When( Self )
      ENDIF
   ELSEIF msg == WM_KILLFOCUS
      oParent := hwg_getParentForm( Self )
      IF lColorinFocus .OR. oParent:tColorinFocus >= 0 .OR. oParent:bColorinFocus >= 0 .OR. ::bColorBlock != Nil
         ::Setcolor( ::aColorOld[1], ::aColorOld[2], .T. )
      ENDIF
      IF ::bSetGet == Nil
         IF ::bLostFocus != Nil
            Eval( ::bLostFocus, hwg_Edit_GetText( ::handle ), Self )
         ENDIF
      ELSE
         __Valid( Self )
      ENDIF
   ELSEIF msg == WM_LBUTTONDOWN .OR. msg == WM_RBUTTONDOWN
      ::lMouse := .T.
      IF ::cType != "N"
         ::lFirst := .F.
      ENDIF
   ELSEIF msg == WM_LBUTTONUP
      IF Empty( hwg_Edit_GetText( ::handle ) )
         hwg_edit_Setpos( ::handle, 1 )
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::End()
   ELSEIF msg == WM_PASTE
      DoPaste( Self )
      Eval( ::bSetGet, ::title, Self )
      RETURN 1
   ELSEIF msg == WM_COPY
      DoCopy( Self )
      RETURN 1
   ENDIF

   IF ::bSetGet == Nil
      ::Title := hwg_Edit_GetText( ::handle )
      RETURN 0
   ENDIF

   oParent := ::oParent
   IF !::lMultiLine
      IF msg == WM_KEYDOWN
         ::nLastKey := wParam
         IF wParam == GDK_BackSpace
            ::lFirst := .F.
            hwg_SetGetUpdated( Self )
            IF !Empty( ::oPicture ) .AND. ::oPicture:lPicComplex
               nPos := hwg_edit_GetPos( ::handle ) - 1
               IF nPos > 0
                  cText := ::oPicture:Delete( hwg_edit_GetText( ::handle ), @nPos )
                  IF nPos > 0
                     hwg_edit_Settext( ::handle, ::title := cText )
                     hwg_edit_Setpos( ::handle, nPos )
                  ENDIF
               ENDIF
               RETURN 1
            ENDIF
            RETURN 0
         ELSEIF wParam == GDK_Down
            IF lParam == 0
               hwg_GetSkip( oParent, ::handle, 1 )
               RETURN 1
            ENDIF
         ELSEIF wParam == GDK_Up
            IF lParam == 0
               hwg_GetSkip( oParent, ::handle, - 1 )
               RETURN 1
            ENDIF
         ELSEIF wParam == GDK_Right
            IF lParam == 0
               ::lFirst := .F.
               IF !Empty( ::oPicture )
                  IF ( nPos := ::oPicture:KeyRight( hwg_edit_Getpos( ::handle ) ) ) > 0
                     hwg_edit_Setpos( ::handle, nPos )
                  ENDIF
                  RETURN 1
               ENDIF
            ENDIF
         ELSEIF wParam == GDK_Left
            IF lParam == 0
               ::lFirst := .F.
               IF !Empty( ::oPicture )
                  IF ( nPos := ::oPicture:KeyLeft( hwg_edit_Getpos( ::handle ) ) ) > 0
                     hwg_edit_Setpos( ::handle, nPos )
                  ENDIF
                  RETURN 1
               ENDIF
            ENDIF
         ELSEIF wParam == GDK_Home
            IF lParam == 0
               ::lFirst := .F.
               IF !Empty( ::oPicture )
                  nPos := ::oPicture:KeyRight( 0 )
               ELSE
                  nPos := 1
               ENDIF
               hwg_edit_SetPos( ::handle, nPos )
               RETURN 1
            ENDIF
         ELSEIF wParam == GDK_End
            IF lParam == 0
               ::lFirst := .F.
               IF ::cType == "C"
                  nPos := Len( Trim( ::title ) ) + 1
                  hwg_edit_SetPos( ::handle, nPos )
                  RETURN 1
               ENDIF
            ENDIF
         ELSEIF wParam == GDK_Delete
            ::lFirst := .F.
            hwg_SetGetUpdated( Self )
            IF !Empty( ::oPicture ) .AND. ::oPicture:lPicComplex
               nPos := hwg_edit_GetPos( ::handle )
               cText := ::oPicture:Delete( hwg_edit_GetText( ::handle ), @nPos )
               IF nPos > 0
                  hwg_edit_Settext( ::handle, ::title := cText )
                  hwg_edit_Setpos( ::handle, nPos )
               ENDIF
               RETURN 1
            ENDIF
         ELSEIF wParam == GDK_Tab
            IF hwg_Checkbit( lParam, 1 )
               hwg_GetSkip( oParent, ::handle, - 1 )
            ELSE
               hwg_GetSkip( oParent, ::handle, 1 )
            ENDIF
            RETURN 1
         ELSEIF wParam == GDK_ISO_Left_Tab
            IF hwg_Checkbit( lParam, 1 )
               hwg_GetSkip( oParent, ::handle, - 1 )
            ENDIF
            RETURN 1
         ELSEIF wParam == GDK_Return .OR. wParam == GDK_KP_Enter
            IF !hwg_GetSkip( oParent, ::handle, 1, .T. ) .AND. ::bSetGet != Nil
               __Valid( Self )
            ENDIF
            RETURN 1
         ELSEIF ( hwg_checkBit( lParam,1 ) .AND. wParam == GDK_Insert ) .OR. ;
               ( hwg_checkBit( lParam,2 ) .AND. ( wParam == 86 .OR. wParam == 118 ) )
            IF ::bSetGet != Nil
               DoPaste( Self )
               RETURN 1
            ENDIF
         ELSEIF hwg_checkBit( lParam, 2 ) .AND. wParam == GDK_Insert .OR. ;
               ( hwg_checkBit( lParam,2 ) .AND. ( wParam == 67 .OR. wParam == 99 ) )
            IF ::bSetGet != Nil
               DoCopy( Self )
               RETURN 1
            ENDIF
         ELSEIF wParam == GDK_Insert
            IF lParam == 0
               SET( _SET_INSERT, ! Set( _SET_INSERT ) )
            ENDIF
         ELSEIF ( (wParam >= 32 .AND. wParam < 65000) .OR. (wParam >= GDK_KP_0 .AND. wParam <= GDK_KP_9) ) ;
               .AND. !hwg_Checkbit( lParam, 2 )
            IF wParam >=  GDK_KP_0
               wParam -= ( GDK_KP_0 - 48 )
            ENDIF
            IF !Empty( ::oPicture )
               nPos := i := hwg_edit_Getpos( ::handle )
               ::title := cText := hwg_edit_Gettext( ::handle )
               cText := ::oPicture:GetApplyKey( cText, @nPos, hwg_Chr(wParam), ::lFirst, Set( _SET_INSERT ) )
               ::lFirst := .F.
               IF !( cText == ::title )
                  hwg_edit_Settext( ::handle, ::title := cText )
                  hwg_SetGetUpdated( Self )
               ENDIF
               hwg_edit_SetPos( ::handle, nPos )
               IF ::cType != "N" .AND. !Set( _SET_CONFIRM ) .AND. ;
                  i == Len(::oPicture:cPicMask) .AND. !Empty( ::bSetGet )
                  IF !hwg_GetSkip( oParent := ::oParent, ::handle, 1 )
                     DO WHILE oParent != Nil .AND. !__ObjHasMsg( oParent, "GETLIST" )
                        oParent := oParent:oParent
                     ENDDO
                     hwg_DlgCommand( oParent, IDOK )
                  ENDIF
               ENDIF
               RETURN 1
            ENDIF
         ELSE
            RETURN 0
         ENDIF
      ENDIF
   ENDIF

   RETURN 0

METHOD Init()  CLASS HEdit

   IF !::lInit
      ::Super:Init()

      ::Refresh()
   ENDIF

   RETURN Nil

METHOD Refresh()  CLASS HEdit

   LOCAL vari

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet, , self )
   ELSE
      vari := ::title
   ENDIF
   IF !Empty( ::oPicture )
      vari := ::oPicture:Transform( vari )
   ELSE
      vari := iif( ::cType == "D", Dtoc( vari ), iif( ::cType == "N",Str(vari ),iif(::cType == "C",vari,"" ) ) )
   ENDIF
   ::title := vari
   hwg_Edit_SetText( ::handle, vari )
   IF ::bColorBlock != Nil .AND. hwg_Isptreq( ::handle, hwg_Getfocus() )
      Eval( ::bColorBlock, Self )
   ENDIF

   RETURN Nil

METHOD Value( xValue ) CLASS HEdit

   LOCAL vari

   IF xValue != Nil
      IF !Empty( ::oPicture )
         ::title := ::oPicture:Transform( xValue )
      ELSE
         ::title := xValue
      ENDIF
      hwg_Edit_SetText( ::handle, ::title )
      IF ::bSetGet != Nil
         Eval( ::bSetGet, xValue, Self )
      ENDIF
      RETURN xValue
   ENDIF

   vari := iif( Empty( ::handle ), ::title, hwg_Edit_GetText( ::handle ) )
   IF !Empty( ::oPicture )
      vari := ::oPicture:UnTransform( vari )
   ENDIF
   IF ::cType == "D"
      vari := CToD( vari )
   ELSEIF ::cType == "N"
      vari := Val( LTrim( vari ) )
   ELSEIF ::cType == "C" .AND. !Empty( ::nMaxLength )
      vari := PadR( vari, ::nMaxLength )
   ENDIF

   RETURN vari

STATIC FUNCTION __When( oCtrl )

   LOCAL res := .T.

   oCtrl:Refresh()
   oCtrl:lFirst := .T.
   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, oCtrl:title, oCtrl )
      IF !res
         hwg_GetSkip( oCtrl:oParent, oCtrl:handle, 1 )
      ENDIF
   ENDIF
   IF res .AND. !Empty( oCtrl:oPicture )
      oCtrl:oPicture:KeyRight( 0 )
   ENDIF

   RETURN res

STATIC FUNCTION __valid( oCtrl )

   LOCAL vari, oDlg

   IF oCtrl:bSetGet != Nil
      IF ( oDlg := hwg_getParentForm( oCtrl ) ) == Nil .OR. oDlg:nLastKey != 27
         vari := hwg_Edit_GetText( oCtrl:handle )
         oCtrl:title := vari := Iif( !Empty( oCtrl:oPicture ), oCtrl:oPicture:UnTransform( vari ), vari )
         IF oCtrl:cType == "D"
            IF IsBadDate( vari )
               hwg_Setfocus( oCtrl:handle )
               hwg_edit_SetPos( oCtrl:handle, 1 )
               RETURN .F.
            ENDIF
            vari := CToD( vari )
         ELSEIF oCtrl:cType == "N"
            vari := Val( LTrim( vari ) )
            oCtrl:title := Iif( Empty( oCtrl:oPicture), vari, oCtrl:oPicture:Transform( vari ) )
            hwg_edit_Settext( oCtrl:handle, oCtrl:title )
         ELSEIF oCtrl:cType == "C" .AND. !Empty( oCtrl:nMaxLength )
            oCtrl:title := vari := PadR( vari, oCtrl:nMaxLength )
         ENDIF
         Eval( oCtrl:bSetGet, vari, oCtrl )

         IF oDlg != Nil
            oDlg:nLastKey := 27
         ENDIF
         IF oCtrl:bLostFocus != Nil .AND. !Eval( oCtrl:bLostFocus, vari, oCtrl )
            hwg_Setfocus( oCtrl:handle )
            hwg_edit_SetPos( oCtrl:handle, 1 )
            IF oDlg != Nil
               oDlg:nLastKey := 0
            ENDIF
            RETURN .F.
         ENDIF
         IF oDlg != Nil
            oDlg:nLastKey := 0
         ENDIF
      ENDIF
   ENDIF

   RETURN .T.

STATIC FUNCTION IsBadDate( cBuffer )

   LOCAL i, nLen

   IF !Empty( CToD( cBuffer ) )
      RETURN .F.
   ENDIF
   nLen := Len( cBuffer )
   FOR i := 1 TO nLen
      IF IsDigit( SubStr( cBuffer,i,1 ) )
         RETURN .T.
      ENDIF
   NEXT

   RETURN .F.

STATIC FUNCTION DoCopy( oEdit )

   LOCAL cText := hwg_Edit_GetText( oEdit:handle )
   LOCAL aPos := hwg_Edit_GetSelPos( oEdit:handle )
   IF aPos != Nil .AND. aPos[2] > aPos[1] .AND.aPos[2] - aPos[1] < hwg_Len( cText )
      hwg_Copystringtoclipboard( hwg_SubStr( cText, aPos[1]+1, aPos[2]-aPos[1] ) )
   ELSE
      hwg_Copystringtoclipboard( Iif( Empty(oEdit:oPicture), cText, ;
         oEdit:oPicture:UnTransform( oEdit, cText ) ) )
   ENDIF

   RETURN Nil

STATIC FUNCTION DoPaste( oEdit )

   LOCAL cClipboardText := hwg_Getclipboardtext(), i, nPos, cText, nLen := hwg_Len( cClipboardText )

   IF ! Empty( cClipboardText )
      cText := hwg_edit_Gettext( oEdit:handle )
      nPos := hwg_edit_Getpos( oEdit:handle )
      FOR i := 1 TO nLen
         cText := oEdit:oPicture:GetApplyKey( cText, @nPos, hwg_SubStr( cClipboardText,i,1 ), oEdit:lFirst, Set( _SET_INSERT ) )
         oEdit:lFirst := .F.
      NEXT
      oEdit:title := Iif( Empty(oEdit:oPicture), cText, oEdit:oPicture:UnTransform( cText ) )
      hwg_edit_Settext( oEdit:handle, oEdit:title )
      hwg_SetGetUpdated( oEdit )
   ENDIF

   RETURN Nil

FUNCTION hwg_SetColorinFocus( lDef, tColor, bColor )

   IF ValType( lDef ) ==  "O"
      IF tColor != Nil
         lDef:tColorinFocus := tColor
      ENDIF
      IF bColor != Nil
         lDef:bColorinFocus := bColor
      ENDIF
   ELSEIF ValType( lDef ) == "L"
      lColorinFocus := lDef
      IF tColor != Nil
         tColorinFocus := tColor
      ENDIF
      IF bColor != Nil
         bColorinFocus := bColor
      ENDIF
   ENDIF

   RETURN .T.

FUNCTION hwg_Chr( nCode )

   RETURN Iif( hb_cdpSelect()=="UTF8", hwg_keyToUtf8( nCode ), Chr( nCode ) )

FUNCTION hwg_Substr( cString, nPos, nLen )

   RETURN Iif( hb_cdpSelect()=="UTF8", ;
      Iif( nLen==Nil, hb_utf8Substr( cString, nPos ), hb_utf8Substr( cString, nPos, nLen ) ), ;
      Iif( nLen==Nil, Substr( cString, nPos ), Substr( cString, nPos, nLen ) ) )

FUNCTION hwg_Left( cString, nLen )

   RETURN Iif( hb_cdpSelect()=="UTF8", hb_utf8Left( cString, nLen ), Left( cString, nLen ) )

FUNCTION hwg_Len( cString )

   RETURN Iif( hb_cdpSelect()=="UTF8", hb_utf8Len( cString ), Len( cString ) )


FUNCTION hwg_GET_Helper(cp_get,nlen)

   LOCAL c_get

   c_get := cp_get

#ifdef __GTK__
   IF EMPTY(c_get)
      c_get := ""
   ELSE
      IF nlen == NIL
         c_get := RTRIM(c_get)
      ELSE
         c_get := PADR(c_get,nlen)
      ENDIF
   ENDIF
#endif

RETURN c_get
