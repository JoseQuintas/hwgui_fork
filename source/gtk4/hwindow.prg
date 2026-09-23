/*
 *$Id: hwindow.prg 3381 2023-11-15 13:25:15Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HWindow class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It relies exclusively on the
 * hwg_* abstraction layer:
 *
 *   - Hwg_InitMainWindow / Hwg_ActivateMainWindow  → window.c
 *   - hwg_Getwindowrect                            → draw.c
 *   - hwg_Destroyacceleratortable                  → menu_c.c
 *   - hwg_SetBgColor                               → control.c
 *   - hwg_WindowSetDecorated / WindowSetResize     → window.c
 *
 * Pending (external dependencies still to be ported):
 *
 *   - hwg_Hidewindow    ┐
 *   - hwg_ShowAll       │
 *   - hwg_HideHidden    ├──  wintools.c
 *   - hwg_Getdesktopw/h ┘
 *
 * GTK4 limitation (not a bug): hwg_getwindowpos() returns always [0,0]
 * because neither Wayland nor GTK4's portable API expose the toplevel
 * position to the client.  HWindow:onMove() therefore leaves nLeft/nTop
 * at 0.  If absolute positioning is required, migrate the app to X11
 * and use gdk_x11_surface_get_geometry().
 */

#include "hbclass.ch"
#include "hwgui.ch"
REQUEST HWG_ENDWINDOW
#define  FIRST_MDICHILD_ID     501
#define  MAX_MDICHILD_WINDOWS   18
#define  WM_NOTIFYICON         WM_USER+1000
#define  ID_NOTIFYICON           1

FUNCTION hwg_onWndSize( oWnd, wParam, lParam )

   LOCAL aCoors := hwg_Getwindowrect( oWnd:handle )

   LOCAL w := aCoors[3] - aCoors[1], h := aCoors[4] - aCoors[2]
   IF oWnd:nWidth == w .AND. oWnd:nHeight == h
      RETURN 0
   ENDIF
   IF oWnd:nAdjust == 2
      oWnd:nAdjust := 0
   ELSEIF oWnd:nAdjust == 0
      hwg_onAnchor( oWnd, oWnd:nWidth, oWnd:nHeight, w, h )
   ENDIF
   oWnd:Super:onEvent( WM_SIZE, wParam, lParam )
   IF oWnd:nAdjust == 0
      oWnd:nWidth  := w
      oWnd:nHeight := h
   ENDIF
   IF HB_ISBLOCK( oWnd:bSize )
      Eval( oWnd:bSize, oWnd, hwg_Loword( lParam ), hwg_Hiword( lParam ) )
   ENDIF

   RETURN 0

FUNCTION hwg_onMove( oWnd )

   LOCAL apos := hwg_getwindowpos( oWnd:handle )

   oWnd:nLeft := apos[1]
   oWnd:nTop  := apos[2]

   RETURN 0

FUNCTION hwg_HideHidden( oWnd )

   LOCAL i, aControls := oWnd:aControls

   FOR i := 1 TO Len( aControls )
      IF !Empty( aControls[i]:aControls )
         hwg_HideHidden( aControls[i] )
      ENDIF
      IF aControls[i]:lHide
         hwg_Hidewindow( aControls[i]:handle )
      ENDIF
   NEXT

   RETURN Nil

STATIC FUNCTION onDestroy( oWnd )

   LOCAL i, lRes

   IF oWnd:bDestroy != Nil
      IF ValType( lRes := Eval( oWnd:bDestroy, oWnd ) ) == "L" .AND. !lRes
         RETURN .F.
      ENDIF
      oWnd:bDestroy := Nil
   ENDIF
   IF __ObjHasMsg( oWnd, "HACCEL" ) .AND. oWnd:hAccel != Nil
      hwg_Destroyacceleratortable( oWnd:hAccel )
   ENDIF
   IF ( i := Ascan( HTimer():aTimers,{ |o|hwg_Isptreq( o:oParent:handle,oWnd:handle ) } ) ) != 0
      HTimer():aTimers[i]:End()
   ENDIF
   oWnd:Super:onEvent( WM_DESTROY )
   HWindow():DelItem( oWnd )

   RETURN .T.

CLASS HWindow INHERIT HCustomWindow

   CLASS VAR aWindows   SHARED INIT {}
#ifdef ___GTK3___
   CLASS VAR szAppName  SHARED INIT "HwGUI.App"
#else
   CLASS VAR szAppName  SHARED INIT "HwGUI_App"
#endif
   CLASS VAR aKeysGlobal SHARED INIT {}
   DATA fbox
   DATA menu, oPopup, hAccel
   DATA oIcon, oBmp
   DATA lUpdated INIT .F.
   DATA lClipper INIT .F.
   DATA GetList  INIT {}
   DATA KeyList  INIT {}
   DATA nLastKey INIT 0
   DATA bActivate
   DATA lActivated  INIT .F.
   DATA nAdjust  INIT 0
   DATA tColorinFocus  INIT - 1
   DATA bColorinFocus  INIT - 1
   DATA aOffset
   METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
      bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, cAppName, oBmp, cHelp, nHelpId )
   METHOD AddItem( oWnd )
   METHOD DelItem( oWnd )
   METHOD FindWindow( hWnd )
   METHOD GetMain()
   METHOD EvalKeyList( nKey, nctrl )
   METHOD Center()   INLINE Hwg_CenterWindow( ::handle )
   METHOD RESTORE()  INLINE hwg_RestoreWindow( ::handle )
   METHOD Maximize() INLINE hwg_WindowMaximize( ::handle )
   METHOD Minimize() INLINE hwg_WindowMinimize( ::handle )
   METHOD CLOSE()    INLINE iif( !onDestroy( Self ), .F. , hwg_DestroyWindow( ::handle ) )
   METHOD SetTitle( cTitle ) INLINE hwg_Setwindowtext( ::handle, ::title := cTitle )

ENDCLASS

METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
      bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
      cAppName, oBmp, cHelp, nHelpId ) CLASS HWindow

   HB_SYMBOL_UNUSED(clr)
   HB_SYMBOL_UNUSED(cMenu)
   HB_SYMBOL_UNUSED(cHelp)

   ::oDefaultParent := Self
   ::title    := cTitle
   ::style    := iif( nStyle == Nil, 0, nStyle )
   ::oIcon    := oIcon
   ::oBmp     := oBmp
   ::nTop     := iif( y == Nil, 0, y )
   ::nLeft    := iif( x == Nil, 0, x )
   ::nWidth   := iif( width == Nil, 0, width )
   ::nHeight  := iif( height == Nil, 0, Abs( height ) )
   IF ::nWidth < 0
      ::nWidth   := Abs( ::nWidth )
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
   IF cAppName != Nil
      ::szAppName := cAppName
   ENDIF
   IF hwg_BitAnd( Abs( ::style ), DS_CENTER ) > 0
      ::nLeft := Int( ( hwg_Getdesktopwidth() - ::nWidth ) / 2 )
      ::nTop  := Int( ( hwg_Getdesktopheight() - ::nHeight ) / 2 )
   ENDIF
   IF nHelpId != nil
      ::HelpId := nHelpId
   END
   ::aOffset := Array( 4 )
   AFill( ::aOffset, 0 )
   ::AddItem( Self )

   RETURN Self

METHOD AddItem( oWnd ) CLASS HWindow

   AAdd( ::aWindows, oWnd )

   RETURN Nil

METHOD DelItem( oWnd ) CLASS HWindow

   LOCAL i

   IF ( i := Ascan( ::aWindows,{ |o|o == oWnd } ) ) > 0
      ADel( ::aWindows, i )
      ASize( ::aWindows, Len( ::aWindows ) - 1 )
   ENDIF

   RETURN Nil

METHOD FindWindow( hWnd ) CLASS HWindow

   RETURN hwg_Getwindowobject( hWnd )

METHOD GetMain() CLASS HWindow

   RETURN iif( Len( ::aWindows ) > 0,            ;
      iif( ::aWindows[1]:type == WND_MAIN, ;
      ::aWindows[1],                  ;
      iif( Len( ::aWindows ) > 1, ::aWindows[2], Nil ) ), Nil )

METHOD EvalKeyList( nKey, nctrl ) CLASS HWindow

   LOCAL nPos

   nctrl := iif( nctrl == 2, FCONTROL, iif( nctrl == 1, FSHIFT, iif( nctrl == 4,FALT,0 ) ) )
   IF !Empty( ::KeyList )
      IF ( nPos := Ascan( ::KeyList,{ |a|a[1] == nctrl .AND. a[2] == nKey } ) ) > 0
         Eval( ::KeyList[ nPos,3 ], ::FindControl( ,hwg_Getfocus() ), nKey, nctrl )
      ENDIF
   ENDIF
   IF !Empty( ::aKeysGlobal )
      IF ( nPos := Ascan( ::aKeysGlobal,{ |a|a[1] == nctrl .AND. a[2] == nKey } ) ) > 0
         Eval( ::aKeysGlobal[ nPos,3 ], ::FindControl( ,hwg_Getfocus() ), nKey, nctrl )
      ENDIF
   ENDIF

   RETURN .T.

CLASS HMainWindow INHERIT HWindow

   CLASS VAR aMessages INIT { ;
      { WM_COMMAND, WM_SETFOCUS, WM_MOVE, WM_SIZE, WM_CLOSE, WM_DESTROY }, ;
      { ;
      { |o, w, l|onCommand( o, w, l ) },        ;
      { |o, w, l|onGetFocus( o, w, l ) },       ;
      { |o, w, l|hwg_onMove( o, w, l ) },       ;
      { |o, w, l|hwg_onWndSize( o, w, l ) },    ;
      { |o|hwg_ReleaseAllWindows( o:handle ) }, ;
      { |o|onDestroy( o ) }                 ;
      } ;
      }
   DATA   nMenuPos
   DATA oNotifyIcon, bNotify, oNotifyMenu
   DATA lTray       INIT .F.
   METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
      oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
      cAppName, oBmp, cHelp, nHelpId, bColor, nExclude )
   METHOD Activate( lShow, lMaximize, lMinimize, lCentered, bActivate )
   METHOD onEvent( msg, wParam, lParam )
   METHOD InitTray()
   METHOD DEICONIFY()
   METHOD ICONIFY()

ENDCLASS

METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
      oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
      cAppName, oBmp, cHelp, nHelpId, bColor, nExclude ) CLASS HMainWindow

    LOCAL  hbackground

   HB_SYMBOL_UNUSED(nPos)
   HB_SYMBOL_UNUSED(nExclude)

   IF oBmp == NIL
      hbackground := NIL
   ELSE
      hbackground := oBmp:handle
   ENDIF

   ::Super:New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
      bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther,  ;
      cAppName, oBmp, cHelp, nHelpId )
   ::type := lType
   ::bColor := bColor
   IF lType == WND_MDI
   ELSEIF lType == WND_MAIN
      ::handle := Hwg_InitMainWindow( Self, ::szAppName, cTitle, cMenu, ;
         iif( oIcon != Nil, oIcon:handle, Nil ), ::Style, ::nLeft, ;
         ::nTop, ::nWidth, ::nHeight, hbackground )
   ENDIF
   IF ::bColor != Nil
      hwg_SetBgColor( ::handle, ::bColor )
   ENDIF
   IF ::bInit != Nil
      Eval( ::bInit, Self )
   ENDIF

   RETURN Self

METHOD Activate( lShow, lMaximize, lMinimize, lCentered, bActivate ) CLASS HMainWindow

   LOCAL aCoors, aRect

   HB_SYMBOL_UNUSED(lShow)

   hwg_CreateGetList( Self )

   IF ::type == WND_MAIN
      IF ::style < 0 .AND. hwg_Bitand( Abs( ::style ), Abs( WND_NOTITLE ) ) != 0
         hwg_WindowSetDecorated( ::handle, 0 )
      ENDIF
      hwg_ShowAll( ::handle )
      IF ::style < 0 .AND. hwg_Bitand( Abs( ::style ), Abs( WND_NOSIZEBOX ) ) != 0
         hwg_WindowSetResize( ::handle, 0 )
      ENDIF
      IF ::nAdjust == 1
         ::nAdjust := 2
         aCoors := hwg_Getwindowrect( ::handle )
         aRect := hwg_GetClientRect( ::handle )
         IF aCoors[4] - aCoors[2] == aRect[4]
            ::nAdjust := 0
         ELSE
            ::Move( , , ::nWidth + ( aCoors[3] - aCoors[1] - aRect[3] ), ::nHeight + ( aCoors[4] - aCoors[2] - aRect[4] ) )
         ENDIF
      ENDIF
      ::lActivated := .T.
      IF HB_ISBLOCK( bActivate )
         ::bActivate := bActivate
      ENDIF
      IF ::bActivate != Nil
         Eval( ::bActivate, Self )
      ENDIF
      IF !Empty( lMinimize )
         ::Minimize()
      ELSEIF !Empty( lMaximize )
         ::Maximize()
      ELSEIF !Empty( lCentered )
         ::Center()
      ENDIF
      hwg_HideHidden( Self )
      Hwg_ActivateMainWindow( ::handle )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HMainWindow

   LOCAL i

   IF ( i := Ascan( ::aMessages[1],msg ) ) != 0
      RETURN Eval( ::aMessages[2,i], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL
      ENDIF
      Return ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN 0

METHOD InitTray() CLASS HMainWindow

   RETURN Nil

METHOD DEICONIFY() CLASS HMainWindow
   hwg_deiconify(::handle)

   RETURN NIL

METHOD ICONIFY()  CLASS HMainWindow
   hwg_iconify(::handle)

   RETURN NIL

FUNCTION hwg_ReleaseAllWindows( hWnd )

   HB_SYMBOL_UNUSED(hWnd)

   RETURN -1

STATIC FUNCTION onCommand( oWnd, wParam, lParam )

   LOCAL iItem, iCont, aMenu, iParHigh, iParLow

   HB_SYMBOL_UNUSED(lParam)

   iParHigh := hwg_Hiword( wParam )
   iParLow := hwg_Loword( wParam )
   IF oWnd:aEvents != Nil .AND. ;
         ( iItem := Ascan( oWnd:aEvents, { |a|a[1] == iParHigh .AND. a[2] == iParLow } ) ) > 0
      Eval( oWnd:aEvents[ iItem,3 ], oWnd, iParLow )
   ELSEIF ValType( oWnd:menu ) == "A" .AND. ;
         ( aMenu := Hwg_FindMenuItem( oWnd:menu,iParLow,@iCont ) ) != Nil ;
         .AND. aMenu[ 1,iCont,1 ] != Nil
      Eval( aMenu[ 1,iCont,1 ] )
   ELSEIF oWnd:oPopup != Nil .AND. ;
         ( aMenu := Hwg_FindMenuItem( oWnd:oPopup:aMenu,wParam,@iCont ) ) != Nil ;
         .AND. aMenu[ 1,iCont,1 ] != Nil
      Eval( aMenu[ 1,iCont,1 ] )
   ELSEIF oWnd:oNotifyMenu != Nil .AND. ;
         ( aMenu := Hwg_FindMenuItem( oWnd:oNotifyMenu:aMenu,wParam,@iCont ) ) != Nil ;
         .AND. aMenu[ 1,iCont,1 ] != Nil
      Eval( aMenu[ 1,iCont,1 ] )
   ENDIF

   RETURN 0

STATIC FUNCTION onGetFocus( oDlg, w, l )

   HB_SYMBOL_UNUSED(w)
   HB_SYMBOL_UNUSED(l)

   IF oDlg:bGetFocus != Nil
      Eval( oDlg:bGetFocus, oDlg )
   ENDIF

   RETURN 0

* =================================== EOF of hwindow.prg ========================================
