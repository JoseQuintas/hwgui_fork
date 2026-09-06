/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HDialog class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

#define  WM_PSPNOTIFY         WM_USER+1010

STATIC aSheet := Nil
STATIC aMessModalDlg := { ;
      { WM_COMMAND, { |o,w,l|hwg_DlgCommand( o,w,l ) } },     ;
      { WM_SYSCOMMAND, { |o,w,l| onSysCommand( o, w, l ) } }, ;
      { WM_SIZE, { |o,w,l|hwg_onWndSize( o,w,l ) } },         ;
      { WM_ERASEBKGND, { |o,w|onEraseBk( o,w ) } },           ;
      { WM_PSPNOTIFY, { |o,w,l|onPspNotify( o,w,l ) } },      ;
      { WM_HELP, { |o,w,l|onHelp( o,w,l ) } },                ;
      { WM_ACTIVATE, { |o,w,l|onActivate( o,w,l ) } },        ;
      { WM_INITDIALOG, { |o,w,l|InitModalDlg( o,w,l ) } },    ;
      { WM_DESTROY, { |o|hwg_onDestroy( o ) } }               ;
      }

#ifdef HB_GUI_MT_EXPERIMENTAL
THREAD STATIC aDialogs := {}
THREAD STATIC aModalDialogs := {}

FUNCTION aDialogs()

   RETURN aDialogs

FUNCTION aModalDialogs()

   RETURN aModalDialogs
#endif

   // Class HDialog

CLASS HDialog INHERIT HWindow

#ifdef HB_GUI_MT_EXPERIMENTAL
   METHOD aDialogs          INLINE aDialogs()
   METHOD aModalDialogs     INLINE aModalDialogs()
#else
   CLASS VAR aDialogs       SHARED INIT {}
   CLASS VAR aModalDialogs  SHARED INIT {}
#endif

   DATA lModal   INIT .T.
   DATA lResult  INIT .F.     // Becomes TRUE if the OK button is pressed
   DATA lExitOnEnter INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
   // Added by Sandro Freire
   DATA lExitOnEsc   INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
   // Added by Sandro Freire
   DATA lRouteCommand  INIT .F.
   DATA xResourceID
   DATA lClosable    INIT .T.
   DATA nInitState

   METHOD New( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
      bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, xResourceID, lExitOnEsc, bColor, lNoClosable )
   METHOD Activate( lNoModal, lMaximized, lMinimized, lCentered, bActivate )
   METHOD onEvent( msg, wParam, lParam )
   METHOD AddItem()      INLINE AAdd( Iif( ::lModal,::aModalDialogs,::aDialogs ), Self )
   METHOD DelItem()
   METHOD FindDialog( hWnd )
   METHOD GetActive()
   METHOD Close()    INLINE hwg_EndDialog( ::handle )

ENDCLASS

METHOD New( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
      bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, xResourceID, lExitOnEsc, bColor, lNoClosable ) CLASS HDialog

   IF nStyle == Nil
      ::style := WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX
   ELSEIF nStyle < 0 .AND. nStyle > -0x1000
      ::style := WS_POPUP + WS_VISIBLE
      IF hwg_Bitand( Abs(nStyle), Abs(WND_NOTITLE) ) = 0
         ::style += WS_CAPTION
      ENDIF
      IF hwg_Bitand( Abs(nStyle), WND_NOSYSMENU ) = 0
         ::style += WS_SYSMENU
      ENDIF
      IF hwg_Bitand( Abs(nStyle), WND_NOSIZEBOX ) = 0
         ::style += WS_SIZEBOX
      ENDIF
   ELSE
      ::style := nStyle
   ENDIF
   ::oDefaultParent := Self
   ::xResourceID := xResourceID
   ::type     := lType
   ::title    := cTitle
   ::oBmp     := oBmp
   ::oIcon    := oIcon
   ::nTop     := Iif( y == Nil, 0, y )
   ::nLeft    := Iif( x == Nil, 0, x )
   ::nWidth   := Iif( width == Nil, 0, width )
   ::nWidth   := Iif( width == Nil, 0, width )
   ::nHeight  := Iif( height == Nil, 0, Abs(height) )
   IF ::nWidth < 0
      ::nWidth   := Abs( ::nWidth )
      //::nAdjust := 1
   ENDIF
   ::oFont    := oFont
   ::bInit    := bInit
   ::bDestroy := bExit
   ::bSize    := bSize
   ::bPaint   := bPaint
   ::bGetFocus  := bGFocus
   ::bLostFocus := bLFocus
   ::bOther     := bOther
   ::lClipper   := Iif( lClipper == Nil, .F. , lClipper )
   ::lExitOnEnter := Iif( lExitOnEnter == Nil, .T. , !lExitOnEnter )
   ::lExitOnEsc := Iif( lExitOnEsc == Nil, .T. , !lExitOnEsc )
   ::lClosable  := Iif( lNoClosable == Nil, .T. , !lNoClosable )

   IF bColor != Nil
      ::brush := HBrush():Add( bColor )
   ENDIF
   IF nHelpId != nil
      ::HelpId := nHelpId
   ENDIF
   IF Hwg_Bitand( ::style,WS_HSCROLL ) > 0
      ::nScrollBars ++
   ENDIF
   IF  Hwg_Bitand( ::style,WS_VSCROLL ) > 0
      ::nScrollBars += 2
   ENDIF

   RETURN Self

METHOD Activate( lNoModal, lMaximized, lMinimized, lCentered, bActivate ) CLASS HDialog

   LOCAL oWnd, hParent
   //LOCAL aCoors, aRect

   IF bActivate != Nil
      ::bActivate := bActivate
   ENDIF

   IF ::oParent == Nil
      ::oParent := hwg_GetModalDlg()
   ENDIF
   hwg_CreateGetList( Self )
   hParent := Iif( ::oParent != Nil .AND. ;
      __ObjHasMsg( ::oParent, "HANDLE" ) .AND. !Empty( ::oParent:handle ), ;
      ::oParent:handle, Iif( ( oWnd := HWindow():GetMain() ) != Nil,  ;
      oWnd:handle, hwg_Getactivewindow() ) )

   ::nInitState := Iif( !Empty(lMaximized), SW_SHOWMAXIMIZED, ;
         Iif( !Empty(lMinimized), SW_SHOWMINIMIZED, Iif( !Empty(lCentered), 16, 0 ) ) )
   IF ::type == WND_DLG_RESOURCE
      IF lNoModal == Nil .OR. !lNoModal
         ::lModal := .T.
         ::AddItem()
         Hwg_DialogBox( hParent, Self )
      ELSE
         ::lModal  := .F.
         ::handle  := 0
         ::lResult := .F.
         ::AddItem()
         Hwg_CreateDialog( hParent, Self )
      ENDIF
   ELSEIF ::type == WND_DLG_NORESOURCE
      IF lNoModal == Nil .OR. !lNoModal
         ::lModal := .T.
         ::AddItem()
         Hwg_DlgBoxIndirect( hParent, Self, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
         IF Empty( ::handle )                 // a janela nunca chegou a existir
            ::DelItem()                       // remove o órfão da pilha AGORA, não deixa propagar
            RETURN Nil
         ENDIF
      ELSE
         ::lModal  := .F.
         ::handle  := 0
         ::lResult := .F.
         ::AddItem()
         Hwg_CreateDlgIndirect( hParent, Self, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
      ENDIF
   ENDIF
   IF !::lModal
      IF ::nInitState == SW_SHOWMINIMIZED
         ::Minimize()
      ELSEIF ::nInitState == SW_SHOWMAXIMIZED
         ::Maximize()
      ELSEIF ::nInitState == 16
         ::Center()
      ENDIF
      /*
      IF ::nAdjust == 1
         ::nAdjust := 2
         aCoors := hwg_Getwindowrect( ::handle )
         aRect := hwg_GetClientRect( ::handle )
         ::Move( ,, ::nWidth + (aCoors[3]-aCoors[1]-(aRect[3]-aRect[1])), ::nHeight + (aCoors[4]-aCoors[2]-(aRect[4]-aRect[2])) )
      ENDIF
      */
      IF ::bActivate != Nil
         Eval( ::bActivate, Self )
         ::bActivate := Nil
      ENDIF
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HDialog

   LOCAL i
   LOCAL oTab
   LOCAL nPos

   //hwg_writelog( str(msg) + str(hwg_PtrToUlong(wParam)) + str(hwg_PtrToUlong(lParam)) )
   IF ( i := Ascan( aMessModalDlg, { |a|a[1] == msg } ) ) != 0
      IF ::lRouteCommand .AND. ( msg == WM_COMMAND .OR. msg == WM_NOTIFY )

         nPos := ascan( ::aControls, { |x| x:className() == "HTAB" } )
         IF nPos > 0
            oTab := ::aControls[ nPos ]
            IF Len( oTab:aPages ) > 0
               Eval( aMessModalDlg[i,2], oTab:aPages[oTab:GetActivePage(),1], wParam, lParam )
               RETURN Eval( aMessModalDlg[i,2], Self, wParam, lParam )
            ELSE
               RETURN Eval( aMessModalDlg[i,2], Self, wParam, lParam )
            ENDIF
         ENDIF
         RETURN Eval( aMessModalDlg[i,2], Self, wParam, lParam )
      ENDIF
      RETURN Eval( aMessModalDlg[i,2], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .OR. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != - 1  .AND. ::bScroll = Nil
            hwg_ScrollHV( Self, msg, wParam, lParam )
         ENDIF
         hwg_onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      Return ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN 0

METHOD DelItem() CLASS HDialog

   LOCAL i

   IF ::lModal
      IF ( i := Ascan( ::aModalDialogs,{ |o|o == Self } ) ) > 0
         ADel( ::aModalDialogs, i )
         ASize( ::aModalDialogs, Len( ::aModalDialogs ) - 1 )
      ENDIF
   ELSE
      IF ( i := Ascan( ::aDialogs,{ |o|o == Self } ) ) > 0
         ADel( ::aDialogs, i )
         ASize( ::aDialogs, Len( ::aDialogs ) - 1 )
      ENDIF
   ENDIF

   RETURN Nil

METHOD FindDialog( hWnd ) CLASS HDialog

   LOCAL i

   i := Ascan( ::aModalDialogs, { |o|hwg_Isptreq( o:handle, hWnd ) } )
   IF i > 0
      RETURN ::aModalDialogs[i]
   ENDIF

   i := Ascan( ::aDialogs, { |o|hwg_Isptreq( o:handle, hWnd ) } )
   RETURN Iif( i == 0, Nil, ::aDialogs[i] )

METHOD GetActive() CLASS HDialog

   LOCAL handle := hwg_Getfocus()
   LOCAL i := Ascan( ::Getlist, { |o|hwg_Isptreq( o:handle,handle ) } )

   RETURN Iif( i == 0, Nil, ::Getlist[i] )


STATIC FUNCTION InitModalDlg( oDlg, wParam, lParam )

   LOCAL nReturn := 1
   LOCAL aCoors //, aRect

  * Parameters not used
    HB_SYMBOL_UNUSED(wParam)
    HB_SYMBOL_UNUSED(lParam)

   IF ValType( oDlg:menu ) == "A"
      hwg__SetMenu( oDlg:handle, oDlg:menu[5] )
   ENDIF
   hwg_InitControls( oDlg, .T. )
   IF oDlg:oIcon != Nil
      hwg_Sendmessage( oDlg:handle, WM_SETICON, 1, oDlg:oIcon:handle )
   ENDIF
   IF oDlg:Title != NIL
      hwg_Setwindowtext( oDlg:Handle, oDlg:Title )
   ENDIF
   IF oDlg:oFont != Nil
      hwg_Sendmessage( oDlg:handle, WM_SETFONT, oDlg:oFont:handle, 0 )
   ENDIF
   IF !oDlg:lClosable
      hwg_Enablemenusystemitem( oDlg:handle, SC_CLOSE, .F. )
   ENDIF

   IF oDlg:nInitState == SW_SHOWMINIMIZED
      oDlg:Minimize()
   ELSEIF oDlg:nInitState == SW_SHOWMAXIMIZED
      oDlg:Maximize()
   ELSEIF oDlg:nInitState == 16
      oDlg:Center()
   ENDIF

   IF oDlg:bInit != Nil
      IF ValType( nReturn := Eval( oDlg:bInit, oDlg ) ) != "N"
         nReturn := 1
      ENDIF
   ENDIF

/*
   IF oDlg:nAdjust == 1
      oDlg:nAdjust := 2
      aCoors := hwg_Getwindowrect( oDlg:handle )
      aRect := hwg_GetClientRect( oDlg:handle )
      hwg_writelog( str(oDlg:nHeight) + "/" + str(aCoors[4]-aCoors[2]) + "/" + str(aRect[4]) )
      oDlg:Move( ,, oDlg:nWidth + (aCoors[3]-aCoors[1]-aRect[3]), oDlg:nHeight + (aCoors[4]-aCoors[2]-aRect[4]) )
   ELSE
*/
      aCoors := hwg_Getwindowrect( oDlg:handle )
      oDlg:nWidth  := aCoors[3] - aCoors[1]
      oDlg:nHeight := aCoors[4] - aCoors[2]
//   ENDIF

   RETURN nReturn

STATIC FUNCTION onEraseBk( oDlg, hDC )

   LOCAL aCoors

   IF __ObjHasMsg( oDlg, "OBMP" )
      IF oDlg:oBmp != Nil
         IF oDlg:lBmpSpread
            hwg_Spreadbitmap( hDC, oDlg:oBmp:handle )
         ELSE
            aCoors := hwg_Getclientrect( oDlg:handle )
            hwg_Drawbitmap( hDC, oDlg:oBmp:handle,, 0, 0, aCoors[3], aCoors[4] )
         ENDIF
         RETURN 1
      ELSE
         aCoors := hwg_Getclientrect( oDlg:handle )
         IF oDlg:brush != Nil
            IF ValType( oDlg:brush ) != "N"
               hwg_Fillrect( hDC, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, oDlg:brush:handle )
            ENDIF
         ELSE
            hwg_Fillrect( hDC, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, COLOR_3DFACE + 1 )
         ENDIF
         RETURN 1
      ENDIF
   ENDIF

   RETURN 0

#define  FLAG_CHECK      2

FUNCTION hwg_DlgCommand( oDlg, wParam, lParam )


   LOCAL iParHigh := hwg_Hiword( wParam ), iParLow := hwg_Loword( wParam )
   LOCAL aMenu, i, hCtrl

    * Parameters not used
    HB_SYMBOL_UNUSED(lParam)

   // WriteLog( Str(iParHigh,10)+"|"+Str(iParLow,10)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   IF iParHigh == 0
      IF iParLow == IDOK
         hCtrl := hwg_Getfocus()
         FOR i := Len( oDlg:GetList ) TO 1 STEP - 1
            IF !oDlg:GetList[i]:lHide .AND. hwg_Iswindowenabled( oDlg:Getlist[i]:Handle )
               EXIT
            ENDIF
         NEXT
         IF i != 0 .AND. oDlg:GetList[i]:handle == hCtrl
            IF __ObjHasMsg( oDlg:GetList[i], "BVALID" )
               IF oDlg:lExitOnEnter .AND. ;
                     Eval( oDlg:GetList[i]:bValid, oDlg:GetList[i] )
                  oDlg:GetList[i]:bLostFocus := Nil
                  oDlg:lResult := .T.
                  hwg_EndDialog( oDlg:handle )
               ENDIF
               RETURN 1
            ENDIF
         ENDIF
         IF oDlg:lClipper
            IF !hwg_GetSkip( oDlg, hCtrl, 1 )
               IF oDlg:lExitOnEnter
                  oDlg:lResult := .T.
                  hwg_EndDialog( oDlg:handle )
               ENDIF
            ENDIF
            RETURN 1
         ENDIF
      ELSEIF iParLow == IDCANCEL .AND. oDlg:lExitOnEsc
         oDlg:nLastKey := 27
      ENDIF
   ENDIF

   IF oDlg:aEvents != Nil .AND. ;
         ( i := Ascan( oDlg:aEvents, { |a|a[1] == iParHigh .AND. a[2] == iParLow } ) ) > 0
      Eval( oDlg:aEvents[ i,3 ], oDlg, iParLow )
   ELSEIF iParHigh == 0 .AND. ( ;
         ( iParLow == IDOK .AND. oDlg:FindControl( IDOK ) != Nil ) .OR. ;
         iParLow == IDCANCEL )
      IF iParLow == IDOK
         oDlg:lResult := .T.
      ENDIF
      //Replaced by Sandro
      IF oDlg:lExitOnEsc .OR. hwg_Getkeystate( VK_ESCAPE ) >= 0
         hwg_EndDialog( oDlg:handle )
      ENDIF
   ELSEIF __ObjHasMsg( oDlg, "MENU" ) .AND. ValType( oDlg:menu ) == "A" .AND. ;
         ( aMenu := Hwg_FindMenuItem( oDlg:menu,iParLow,@i ) ) != Nil
      IF Hwg_BitAnd( aMenu[ 1,i,4 ], FLAG_CHECK ) > 0
         hwg_Checkmenuitem( , aMenu[1,i,3], !hwg_Ischeckedmenuitem( ,aMenu[1,i,3] ) )
      ENDIF
      IF aMenu[ 1,i,1 ] != Nil
         Eval( aMenu[ 1,i,1 ] )
      ENDIF
   ELSEIF __ObjHasMsg( oDlg, "OPOPUP" ) .AND. oDlg:oPopup != Nil .AND. ;
         ( aMenu := Hwg_FindMenuItem( oDlg:oPopup:aMenu,iParLow,@i ) ) != Nil ;
         .AND. aMenu[ 1,i,1 ] != Nil
      Eval( aMenu[ 1,i,1 ] )
   ENDIF

   RETURN 1

STATIC FUNCTION onActivate( oDlg, wParam, lParam )

   LOCAL iParLow := hwg_Loword( wParam ), b

    * Parameters not used
    HB_SYMBOL_UNUSED(lParam)

   IF oDlg:bActivate != Nil
      b := oDlg:bActivate
      oDlg:bActivate := Nil
      Eval( b, oDlg )
   ENDIF
   IF iParLow > 0 .AND. oDlg:bGetFocus != Nil
      Eval( oDlg:bGetFocus, oDlg )
   ELSEIF iParLow == 0 .AND. oDlg:bLostFocus != Nil
      Eval( oDlg:bLostFocus, oDlg )
   ENDIF

   RETURN 0

STATIC FUNCTION onHelp( oDlg, wParam, lParam )

   LOCAL oCtrl, nHelpId, oParent

     * Parameters not used
    HB_SYMBOL_UNUSED(wParam)


   IF ! Empty( hwg_SetHelpFileName() )
      oCtrl := oDlg:FindControl( nil, hwg_Gethelpdata( lParam ) )
      IF oCtrl != nil
         nHelpId := oCtrl:HelpId
         IF Empty( nHelpId )
            oParent := oCtrl:oParent
            nHelpId := oParent:HelpId
         ENDIF

         hwg_Winhelp( oDlg:handle, hwg_SetHelpFileName(), Iif( Empty(nHelpId ), 3, 1 ), nHelpId )

      ENDIF
   ENDIF

   RETURN 0

STATIC FUNCTION onPspNotify( oDlg, wParam, lParam )

   LOCAL nCode := hwg_Getnotifycode( lParam ), res := .T.

     * Parameters not used
    HB_SYMBOL_UNUSED(wParam)


   IF nCode == PSN_SETACTIVE
      IF oDlg:bGetFocus != Nil
         res := Eval( oDlg:bGetFocus, oDlg )
      ENDIF
      // 'res' should be 0(Ok) or -1
      Hwg_SetDlgResult( oDlg:handle, Iif( res,0, - 1 ) )
      RETURN 1
   ELSEIF nCode == PSN_KILLACTIVE
      IF oDlg:bLostFocus != Nil
         res := Eval( oDlg:bLostFocus, oDlg )
      ENDIF
      // 'res' should be 0(Ok) or 1
      Hwg_SetDlgResult( oDlg:handle, Iif( res,0,1 ) )
      RETURN 1
   ELSEIF nCode == PSN_RESET
   ELSEIF nCode == PSN_APPLY
      IF oDlg:bDestroy != Nil
         res := Eval( oDlg:bDestroy, oDlg )
         res := Iif( Valtype(res)=="L", res, .T. )
      ENDIF
      // 'res' should be 0(Ok) or 2
      Hwg_SetDlgResult( oDlg:handle, Iif( res,0,2 ) )
      IF res
         oDlg:lResult := .T.
      ENDIF
      RETURN 1
   ELSE
      IF oDlg:bOther != Nil
         res := Eval( oDlg:bOther, oDlg, WM_NOTIFY, 0, lParam )
         Hwg_SetDlgResult( oDlg:handle, Iif( res,0,1 ) )
         RETURN 1
      ENDIF
   ENDIF

   RETURN 0

FUNCTION hwg_PropertySheet( hParentWindow, aPages, cTitle, x1, y1, width, height, ;
      lModeless, lNoApply, lWizard )

   LOCAL hSheet, i, aHandles := Array( Len( aPages ) ), aTemplates := Array( Len( aPages ) )

   aSheet := Array( Len( aPages ) )
   FOR i := 1 TO Len( aPages )
      IF aPages[i]:type == WND_DLG_RESOURCE
         aHandles[i] := hwg__createpropertysheetpage( aPages[i] )
      ELSE
         aTemplates[i] := hwg_Createdlgtemplate( aPages[i], x1, y1, width, height, WS_CHILD + WS_VISIBLE + WS_BORDER )
         aHandles[i] := hwg__createpropertysheetpage( aPages[i], aTemplates[i] )
      ENDIF
      aSheet[i] := { aHandles[i], aPages[i] }
   NEXT
   hSheet := hwg__propertysheet( hParentWindow, aHandles, Len( aHandles ), cTitle, ;
      lModeless, lNoApply, lWizard )
   FOR i := 1 TO Len( aPages )
      IF aPages[i]:type != WND_DLG_RESOURCE
         hwg_Releasedlgtemplate( aTemplates[i] )
      ENDIF
   NEXT

   RETURN hSheet

FUNCTION hwg_EndDialog( handle )

   LOCAL oDlg, lRes, lModal, hWindow

   IF handle == Nil
      IF ( oDlg := Atail( HDialog():aModalDialogs ) ) == Nil
         RETURN Nil
      ENDIF
   ELSE
      /* First check in the modal dialogs stack, then search the general active dialog list */
      IF ( ( oDlg := Atail( HDialog():aModalDialogs ) ) == Nil .OR. ;
            oDlg:handle != handle ) .AND. ;
            ( oDlg := HDialog():FindDialog( handle ) ) == Nil
         RETURN Nil
      ENDIF
   ENDIF

   lModal := oDlg:lModal
   hWindow := oDlg:handle

   IF oDlg:bDestroy != Nil
      lRes := Eval( oDlg:bDestroy, oDlg )
      IF Valtype( lRes ) == "L" .AND. !lRes
         RETURN Nil
      ENDIF
   ENDIF

   /* CRITICAL 64-BIT SHIELD:
      Break circular references to prevent the Harbour VM from crashing
      when returning from the final WM_COMMAND evaluation loop. */
   IF !lModal
      /* 1. Safely break and nullify event triggers */
      oDlg:bDestroy := Nil

      /* 2. Empty the control arrays to clear object reference counters */
      IF Valtype( oDlg:aControls ) == "A"
         AFill( oDlg:aControls, Nil )
         oDlg:aControls := {}
      ENDIF

      /* 3. Instruct Windows core to clear handles first */
      hwg_Destroywindow( hWindow )

      /* 4. Finally detach the dialogue definition from the active engine list */
      oDlg:DelItem()
      lRes := .T.
   ELSE
      lRes := Hwg__EndDialog( hWindow )

      /* Detach from ::aModalDialogs *now*. EndDialog() only schedules the
         window's actual destruction - it only completes later, when
         Windows unwinds its own internal DialogBox[Indirect]Param() loop.
         Unlike the !lModal branch above, nothing here ever called
         DelItem(), so a modal dialog stayed in ::aModalDialogs forever
         after it closed. hwg_GetModalDlg() (used by HDialog:Activate() to
         pick a new dialog's owner) returns Atail( ::aModalDialogs ), so
         once stale entries pile up, a *later*, unrelated dialog can
         inherit one of them as its parent. Combined with Windows freely
         recycling HWND values once a window is destroyed, IsWindow() can
         even report that stale handle as valid again (now belonging to a
         completely different window), silently re-parenting the new
         dialog to the wrong owner and breaking its z-order relative to
         the dialog that actually opened it - exactly the "next dialog
         falls behind the first one" symptom seen after repeating the
         same open/close sequence. */
      oDlg:DelItem()
   ENDIF

   RETURN lRes


STATIC FUNCTION onSysCommand( oDlg, wParam )

   wParam := hwg_PtrToUlong( wParam )
   IF wParam == SC_CLOSE
      IF !oDlg:lClosable
         RETURN 1
      ENDIF
   ENDIF

   RETURN - 1

