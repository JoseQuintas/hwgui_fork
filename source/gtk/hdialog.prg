/*
 *$Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HDialog class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

REQUEST HWG_ENDWINDOW

STATIC aMessModalDlg := { ;
      { WM_COMMAND, { |o,w,l|hwg_DlgCommand( o,w,l ) } },     ;
      { WM_SIZE, { |o,w,l|hwg_onWndSize( o,w,l ) } },         ;
      { WM_MOVE, { |o,w,l|hwg_onMove( o,w,l ) } },            ;
      { WM_INITDIALOG, { |o,w,l|InitModalDlg( o,w,l ) } },    ;
      { WM_DESTROY, { |o|onDestroy( o ) } },                  ;
      { WM_SETFOCUS, { |o,w,l|onGetFocus( o,w,l ) } },        ;
      { WM_KILLFOCUS, { |o,w,l|onKillFocus( o,w,l ) } }       ;
      }

STATIC FUNCTION onDestroy( oDlg )

   LOCAL i, lRes

   IF oDlg:bDestroy != Nil
      IF ValType( lRes := Eval( oDlg:bDestroy, oDlg ) ) == "L" .AND. !lRes
         RETURN .F.
      ENDIF
      oDlg:bDestroy := Nil
   ENDIF

   IF ( i := Ascan( HTimer():aTimers,{ |o|hwg_Isptreq( o:oParent:handle,oDlg:handle ) } ) ) != 0
      HTimer():aTimers[i]:End()
   ENDIF

   oDlg:Super:onEvent( WM_DESTROY )
   HDialog():DelItem( oDlg, .T. )
   IF oDlg:lModal
      hwg_gtk_exit()
   ENDIF

   RETURN .T.

   // Class HDialog

CLASS HDialog INHERIT HWindow

   CLASS VAR aDialogs       SHARED INIT {}
   CLASS VAR aModalDialogs  SHARED INIT {}

   DATA fbox
   DATA lResult  INIT .F.     // Becomes TRUE if the OK button is pressed
   DATA lUpdated INIT .F.     // TRUE, if any GET is changed
   DATA lExitOnEnter INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
   // Added by Sandro Freire
   DATA lExitOnEsc   INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
   // Added by Sandro Freire
   DATA oIcon, oBmp
   DATA xResourceID
   DATA lModal
//   DATA handle

   METHOD New( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
      bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, xResourceID, lExitOnEsc, bColor )
   METHOD Activate( lNoModal , lMaximized, lMinimized, lCentered, bActivate )
   METHOD onPAINT( wParam, lParam )
   METHOD onEvent( msg, wParam, lParam )
   METHOD AddItem( oWnd, lModal )
   METHOD DelItem( oWnd, lModal )
   METHOD FindDialog( hWnd )
   METHOD GetActive()
   METHOD CLOSE()    INLINE hwg_EndDialog( ::handle )

ENDCLASS

METHOD New( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
      bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, xResourceID, lExitOnEsc, bColor ) CLASS HDialog

   * Parameters not used
   HB_SYMBOL_UNUSED(nHelpId)

   ::oDefaultParent := Self
   ::xResourceID := xResourceID
   ::type     := lType
   ::title    := cTitle
   ::style    := iif( nStyle == Nil, 0, nStyle )
   ::bColor   := bColor
   ::oBmp     := oBmp
   ::oIcon    := oIcon
   ::nTop     := iif( y == Nil, 0, y )
   ::nLeft    := iif( x == Nil, 0, x )
   ::nWidth   := iif( width == Nil, 0, width )
   ::nHeight  := iif( height == Nil, 0, Abs( height ) )
   IF ::nWidth < 0
      ::nWidth  := Abs( ::nWidth )
      ::nAdjust := 1
   ENDIF
   ::oFont    := oFont
   ::bInit    := bInit
   ::bDestroy := bExit
   ::bSize    := bSize
   ::bPaint   := bPaint
   ::bGetFocus  := bGFocus
   ::bLostFocus := bLFocus
   ::bOther     := bOther
   ::lClipper   := iif( lClipper == Nil, .F. , lClipper )
   ::lExitOnEnter := iif( lExitOnEnter == Nil, .T. , !lExitOnEnter )
   ::lExitOnEsc  := iif( lExitOnEsc == Nil, .T. , !lExitOnEsc )

   IF ::style > 0 .AND. hwg_BitAnd( ::style, DS_CENTER ) > 0
      ::nLeft := Int( ( hwg_Getdesktopwidth() - ::nWidth ) / 2 )
      ::nTop  := Int( ( hwg_Getdesktopheight() - ::nHeight ) / 2 )
   ENDIF
   ::handle := Hwg_CreateDlg( Self, Iif( !Empty(::oIcon), ::oIcon:handle, Nil ), ;
      Iif( !Empty(::oBmp), ::oBmp:handle, Nil ) )

   RETURN Self

/* Added: lMaximized, lMinimized, lCentered, bActivate */
METHOD Activate( lNoModal, lMaximized, lMinimized, lCentered, bActivate ) CLASS HDialog

   LOCAL hParent, oWnd, aCoors, aRect

   hwg_CreateGetList( Self )

   IF lNoModal == Nil ; lNoModal := .F. ; ENDIF
   ::lModal := !lNoModal
   ::lResult := .F.
   IF ::oParent == Nil
      ::oParent := hwg_GetModalDlg()
   ENDIF
   ::AddItem( Self, !lNoModal )

   IF !lNoModal
      hParent := iif( ::oParent != Nil .AND. __ObjHasMsg( ::oParent,"HANDLE" ) ;
         .AND. !Empty( ::oParent:handle ), ::oParent:handle, ;
         iif( ( oWnd := HWindow():GetMain() ) != Nil, oWnd:handle, Nil ) )
      hwg_Set_Modal( ::handle, hParent )
   ENDIF

   IF ::style < 0 .AND. hwg_Bitand( Abs(::style), Abs(WND_NOTITLE) ) != 0
      hwg_WindowSetDecorated( ::handle, 0 )
   ENDIF

   hwg_ShowAll( ::handle )
   InitModalDlg( Self )
   ::lActivated := .T.

   IF ::style < 0 .AND. hwg_Bitand( Abs(::style), Abs(WND_NOSIZEBOX) ) != 0
      hwg_WindowSetResize( ::handle, 0 )
   ENDIF

   IF ::nAdjust == 1
      ::nAdjust := 2
      aCoors := hwg_Getwindowrect( ::handle )
      aRect := hwg_GetClientRect( ::handle )

      // RESTORED: Fixed the bracket indexing for coordinates calculation
      IF aCoors[4] - aCoors[2] == aRect[4]
         ::nAdjust := 0
      ELSE
         ::Move( , , ::nWidth + ( aCoors[3] - aCoors[1] - aRect[3] ), ::nHeight + ( aCoors[4] - aCoors[2] - aRect[4] ) )
      ENDIF
   ENDIF
   IF !Empty( lMinimized )
      ::Minimize()
   ELSEIF !Empty( lMaximized )
      ::Maximize()
   ELSEIF !Empty( lCentered ) .OR. ( ::style > 0 .AND. hwg_BitAnd( ::style, DS_CENTER ) > 0 )
      ::Center()
   ELSEIF ::oParent != Nil .AND. __ObjHasMsg( ::oParent, "nLeft" )
      hwg_MoveWindow( ::handle, ::oParent:nLeft + ::nLeft, ::oParent:nTop + ::nTop )
   ENDIF
   IF HB_ISBLOCK( bActivate )
      ::bActivate := bActivate
   ENDIF
   IF ::bActivate != Nil
      Eval( ::bActivate, Self )
   ENDIF

   hwg_HideHidden( Self )
   hwg_ActivateDialog( ::handle, lNoModal  )
   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HDialog

   LOCAL i

   // DIRECT INTERCEPTION: Route the generated simulated WM_PAINT from window.c core directly
   IF msg == WM_PAINT
      ::onPAINT( wParam, lParam )
      RETURN 0
   ENDIF

   // FIX: Comparing a[1] instead of 'a' fixes the BASE/1070 parameter error
   IF ( i := Ascan( aMessModalDlg, { |a| a[1] == msg } ) ) != 0
      RETURN Eval( aMessModalDlg[i,2], Self, wParam, lParam )
   ELSE
      RETURN ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN 0


METHOD onPAINT( wParam, lParam ) CLASS HDialog

   // 1. Call the GTK2 C helper function to clear the window safely
   HWG_PAINTWINDOW( ::handle )

   // 2. Evaluate the custom block code assigned inside the ON PAINT command
   IF ::bPaint != Nil
      Eval( ::bPaint, Self, wParam, lParam )
   ENDIF

   // 3. Force GTK2 to redraw all the child controls on top of the background canvas
   IF ::fbox != Nil
      hwg_InvalidateRect( ::handle, , .T. )
   ENDIF

RETURN 0


METHOD AddItem( oWnd, lModal ) CLASS HDialog

   AAdd( iif( lModal, ::aModalDialogs, ::aDialogs ), oWnd )

   RETURN Nil

METHOD DelItem( oWnd, lModal ) CLASS HDialog

   LOCAL i

   IF lModal
      IF ( i := Ascan( ::aModalDialogs, { |o|o == oWnd } ) ) > 0
         ADel( ::aModalDialogs, i )
         ASize( ::aModalDialogs, Len( ::aModalDialogs ) - 1 )
      ENDIF
   ELSE
      IF ( i := Ascan( ::aDialogs, { |o|o == oWnd } ) ) > 0
         ADel( ::aDialogs, i )
         ASize( ::aDialogs, Len( ::aDialogs ) - 1 )
      ENDIF
   ENDIF

   RETURN Nil

METHOD FindDialog( hWnd ) CLASS HDialog

   RETURN hwg_Getwindowobject( hWnd )

METHOD GetActive() CLASS HDialog

   LOCAL handle := hwg_Getfocus()
   LOCAL i := Ascan( ::Getlist, { |o|o:handle == handle } )

   RETURN iif( i == 0, Nil, ::Getlist[i] )

   // End of class
   // ------------------------------------

STATIC FUNCTION InitModalDlg( oDlg )

   IF ValType( oDlg:menu ) == "A"
      hwg__SetMenu( oDlg:handle, oDlg:menu )
   ENDIF
   IF oDlg:Title != NIL
      hwg_Setwindowtext( oDlg:Handle, oDlg:Title )
   ENDIF
   IF oDlg:bColor != Nil
      hwg_SetBgColor( oDlg:handle, oDlg:bColor )
   ENDIF
   IF oDlg:bInit != Nil
      Eval( oDlg:bInit, oDlg )
   ENDIF

   RETURN 1

FUNCTION hwg_DlgCommand( oDlg, wParam, lParam )

   LOCAL iParHigh := hwg_Hiword( wParam ), iParLow := hwg_Loword( wParam )
   LOCAL aMenu, i, hCtrl

   HB_SYMBOL_UNUSED( lParam )

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
               IF Eval( oDlg:GetList[i]:bValid, oDlg:GetList[i] ) .AND. ;
                     oDlg:lExitOnEnter
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
      ( i := Ascan( oDlg:aEvents, { |a| a[1] == iParHigh .AND. a[2] == iParLow } ) ) > 0
      Eval( oDlg:aEvents[ i,3 ], oDlg, iParLow )
   ELSEIF iParHigh == 0 .AND. ( ;
         ( iParLow == IDOK .AND. oDlg:FindControl( IDOK ) != Nil ) .OR. ;
         iParLow == IDCANCEL )
      IF iParLow == IDOK
         oDlg:lResult := .T.
      ENDIF
      IF oDlg:lExitOnEsc
         hwg_EndDialog( oDlg:handle )
      ENDIF
   ELSEIF __ObjHasMsg( oDlg, "MENU" ) .AND. ValType( oDlg:menu ) == "A" .AND. ;
         ( aMenu := Hwg_FindMenuItem( oDlg:menu, iParLow, @i ) ) != Nil ;
         .AND. aMenu[ 1,i,1 ] != Nil
      Eval( aMenu[ 1,i,1 ] )
   ELSEIF __ObjHasMsg( oDlg, "OPOPUP" ) .AND. oDlg:oPopup != Nil .AND. ;
         ( aMenu := Hwg_FindMenuItem( oDlg:oPopup:aMenu, wParam, @i ) ) != Nil ;
         .AND. aMenu[ 1,i,1 ] != Nil
      Eval( aMenu[ 1,i,1 ] )
   ENDIF

   RETURN 1

STATIC FUNCTION onGetFocus( oDlg, w, l )

   HB_SYMBOL_UNUSED( w )
   HB_SYMBOL_UNUSED( l )

   IF oDlg:bGetFocus != Nil
      Eval( oDlg:bGetFocus, oDlg )
   ENDIF

   RETURN 0

STATIC FUNCTION onKillFocus( oDlg, w, l )

   HB_SYMBOL_UNUSED( w )
   HB_SYMBOL_UNUSED( l )

   IF oDlg:bLostFocus != Nil
      Eval( oDlg:bLostFocus, oDlg )
   ENDIF

   RETURN 0

FUNCTION hwg_EndDialog( handle )

   LOCAL oDlg

   IF handle == Nil
      IF ( oDlg := Atail( HDialog():aModalDialogs ) ) == Nil
         RETURN Nil
      ENDIF
   ELSE
      oDlg := hwg_Getwindowobject( handle )
   ENDIF

   IF !onDestroy( oDlg )
      RETURN .F.
   ENDIF

   RETURN hwg_DestroyWindow( oDlg:handle )

