/*
 * $Id: menu.prg 3205 2023-01-26 12:33:44Z josequintas $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Prg level menu functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTES
 * -----
 *  The public Harbour-level API of this file is unchanged: the internal
 *  data structure { aItems, cTitle, nId, nFlags, hHandle } keeps working
 *  because menu handles are opaque on both sides.
 *
 *  What *does* change is the meaning of the handle stored in position 5:
 *      - GTK2 : hHandle was a GtkMenuItem / GtkMenu
 *      - GTK4 : hHandle is a GMenuItem / GMenu (model object)
 *
 *  Consequences for the caller:
 *
 *    * hwg_DeleteMenuItem() in GTK4 only *disables* the underlying
 *      GSimpleAction.  GMenu has no "remove this item" call without the
 *      parent GMenu + index, which this Harbour layer does not track.
 *      To physically remove an item from the menu bar, rebuild the bar
 *      after ADel()-ing the array.
 *
 *    * hwg_SetMenuCaption() modifies the label stored inside the
 *      GMenuItem.  GtkPopoverMenuBar redraws on "items-changed"; in
 *      practice the rename propagates, but if a target GTK version
 *      stops emitting the signal after an in-place label change, the
 *      caller should rebuild the menu.
 *
 *    * _oWnd:hAccel now holds a GtkShortcutController, not a
 *      GtkAccelGroup.  Do not call gtk_window_remove_accel_group() on
 *      it directly — use hwg_DestroyAcceleratorTable().
 */

#include "hbclass.ch"
#include "hwgui.ch"

#define  MENU_FIRST_ID           32000
#define  CONTEXTMENU_FIRST_ID    32900
#define  FLAG_DISABLED           1
#define  FLAG_CHECK              2

STATIC _aMenuDef, _oWnd, _aAccel, _nLevel, _Id, _oMenu, _oBitmap, _lContext, hLast

CLASS HMenu INHERIT HObject

   DATA handle
   DATA aMenu
   METHOD New()  INLINE Self
   METHOD End()  INLINE Hwg_DestroyMenu( ::handle )
   METHOD Show( oWnd )

ENDCLASS

METHOD Show( oWnd ) CLASS HMenu

   IF !Empty( HWindow():GetMain() )
      oWnd := HWindow():GetMain()
   ENDIF
   oWnd:oPopup := Self

   /*
    * hwg_trackmenu() in GTK4 builds a GtkPopoverMenu on the fly and
    * pops it up over the active window (see menu_c.c).
    */
   Hwg_trackmenu( ::handle )

   RETURN Nil


FUNCTION Hwg_CreateMenu

   LOCAL hMenu

   IF ( Empty( hMenu := hwg__CreateMenu() ) )   // → GMenu
      RETURN Nil
   ENDIF

   RETURN { {}, , , hMenu }


FUNCTION Hwg_SetMenu( oWnd, aMenu )

   IF !Empty( oWnd:handle )
      IF hwg__SetMenu( oWnd:handle, aMenu[5] )
         oWnd:menu := aMenu
      ELSE
         RETURN .F.
      ENDIF
   ELSE
      oWnd:menu := aMenu
   ENDIF

   RETURN .T.


/*
 *  AddMenuItem( aMenu, cItem, nMenuId, lSubMenu, [bItem] [, nPos] [, hWnd] )
 *
 *  If nPos is omitted, the function adds the menu item to the end of the
 *  menu, otherwise it inserts it at position nPos.
 *
 *  GTK4: hwg__AddMenuItem() returns a GMenu when lSubMenu=.T. and a
 *        GMenuItem otherwise.  Both are stored opaquely in aMenu[1,nPos,5].
 */
FUNCTION Hwg_AddMenuItem( aMenu, cItem, nMenuId, lSubMenu, bItem, nPos, hWnd )

   LOCAL hSubMenu

   IF nPos == Nil
      nPos := Len( aMenu[1] ) + 1
   ENDIF

   hSubMenu := hLast := aMenu[5]
   hSubMenu := hwg__AddMenuItem( hSubMenu, cItem, nPos - 1, ;
      Iif( Empty(hWnd), 0, hWnd ), nMenuId, , lSubMenu )

   IF nPos > Len( aMenu[1] )
      IF Empty( lSubmenu )
         AAdd( aMenu[1], { bItem, cItem, nMenuId, 0, hSubMenu } )
      ELSE
         AAdd( aMenu[1], { {}, cItem, nMenuId, 0, hSubMenu } )
      ENDIF
      RETURN ATail( aMenu[1] )
   ELSE
      AAdd( aMenu[1], Nil )
      AIns( aMenu[1], nPos )
      IF Empty( lSubmenu )
         aMenu[ 1,nPos ] := { bItem, cItem, nMenuId, 0, hSubMenu }
      ELSE
         aMenu[ 1,nPos ] := { {}, cItem, nMenuId, 0, hSubMenu }
      ENDIF
      RETURN aMenu[ 1,nPos ]
   ENDIF

   RETURN Nil


FUNCTION Hwg_FindMenuItem( aMenu, nId, nPos )

   LOCAL nPos1, aSubMenu

   nPos := 1
   DO WHILE nPos <= Len( aMenu[1] )
      IF aMenu[ 1,npos,3 ] == nId
         RETURN aMenu
      ELSEIF ValType( aMenu[ 1,npos,1 ] ) == "A"
         IF ( aSubMenu := Hwg_FindMenuItem( aMenu[ 1,nPos ], nId, @nPos1 ) ) != Nil
            nPos := nPos1
            RETURN aSubMenu
         ENDIF
      ENDIF
      nPos ++
   ENDDO

   RETURN Nil


FUNCTION Hwg_GetSubMenuHandle( aMenu, nId )

   LOCAL aSubMenu := Hwg_FindMenuItem( aMenu, nId )

   RETURN iif( aSubMenu == Nil, 0, aSubMenu[5] )


FUNCTION hwg_BuildMenu( aMenuInit, hWnd, oWnd, nPosParent, lPopup )

   LOCAL hMenu, nPos, aMenu

   IF nPosParent == Nil
      IF lPopup == Nil .OR. !lPopup
         hMenu := hwg__CreateMenu()          // → GMenu
      ELSE
         hMenu := hwg__CreatePopupMenu()     // → GMenu
      ENDIF
      aMenu := { aMenuInit, , , , hMenu }
   ELSE
      hMenu := aMenuInit[5]                  // parent GMenu
      nPos  := Len( aMenuInit[1] )
      aMenu := aMenuInit[ 1,nPosParent ]

      /*
       * lSubMenu=.T. → the C side creates a new submenu GMenu inside the
       * parent GMenuItem and returns the *submenu* GMenu.
       */
      hMenu := hwg__AddMenuItem( hMenu, aMenu[2], nPos + 1, hWnd, aMenu[3], aMenu[4], .T. )
      IF Len( aMenu ) < 5
         AAdd( aMenu, hMenu )
      ELSE
         aMenu[5] := hMenu
      ENDIF
   ENDIF

   nPos := 1
   DO WHILE nPos <= Len( aMenu[1] )
      IF ValType( aMenu[ 1,nPos,1 ] ) == "A"
         hwg_BuildMenu( aMenu, hWnd, , nPos )
      ELSE
         IF aMenu[ 1,nPos,1 ] == Nil .OR. aMenu[ 1,nPos,2 ] != Nil
            IF Len( aMenu[1,npos] ) == 4
               AAdd( aMenu[1,npos], Nil )
            ENDIF
            /*
             * lSubMenu=.F. → the C side returns a GMenuItem.
             */
            aMenu[1,npos,5] := hwg__AddMenuItem( hMenu, aMenu[1,npos,2], ;
               nPos, hWnd, aMenu[1,nPos,3], aMenu[1,npos,4], .F. )
         ENDIF
      ENDIF
      nPos ++
   ENDDO

   IF Empty(_lContext) .AND. hWnd != Nil .AND. oWnd != Nil
      Hwg_SetMenu( oWnd, aMenu )
   ELSEIF _oMenu != Nil
      _oMenu:handle := aMenu[5]
      _oMenu:aMenu  := aMenu
   ENDIF

   RETURN Nil


FUNCTION Hwg_BeginMenu( oWnd, nId, cTitle )

   LOCAL aMenu, i

   IF oWnd != Nil
      _lContext := .F.
      _aMenuDef := {}
      _aAccel   := {}
      _oBitmap  := {}
      _oWnd     := oWnd
      _oMenu    := Nil
      _nLevel   := 0
      _Id       := iif( nId == Nil, MENU_FIRST_ID, nId )
   ELSE
      nId   := iif( nId == Nil, ++ _Id, nId )
      aMenu := _aMenuDef
      FOR i := 1 TO _nLevel
         aMenu := Atail( aMenu )[1]
      NEXT
      _nLevel ++
      IF !Empty( cTitle )
         cTitle := StrTran( cTitle, "\t", "" )
         cTitle := StrTran( cTitle, "&", "_" )
      ENDIF
      AAdd( aMenu, { {}, cTitle, nId, 0 } )
   ENDIF

   RETURN .T.


FUNCTION Hwg_ContextMenu()

   _lContext := .T.
   _aMenuDef := {}
   _oBitmap  := {}
   _oWnd     := Nil
   _nLevel   := 0
   _Id       := CONTEXTMENU_FIRST_ID
   _oMenu    := HMenu():New()

   RETURN _oMenu


FUNCTION Hwg_EndMenu()

   IF _nLevel > 0
      _nLevel --
   ELSE
      hwg_BuildMenu( AClone( _aMenuDef ), Iif( _oWnd != Nil, _oWnd:handle, 0 ), ;
         _oWnd, , _lContext )

      IF _oWnd != Nil .AND. !Empty( _aAccel )
         /*
          * GTK4: _oWnd:hAccel now holds a GtkShortcutController, not a
          * GtkAccelGroup.  See hwg_Createacceleratortable() below.
          */
         _oWnd:hAccel := hwg_Createacceleratortable( _oWnd )
      ENDIF

      _aMenuDef := Nil
      _oBitmap  := Nil
      _aAccel   := Nil
      _oWnd     := Nil
      _oMenu    := Nil
   ENDIF

   RETURN .T.


FUNCTION Hwg_DefineMenuItem( cItem, nId, bItem, lDisabled, accFlag, accKey, ;
                             lBitmap, lResource, lCheck )

   LOCAL aMenu, i, nFlag

   HB_SYMBOL_UNUSED( lBitmap )
   HB_SYMBOL_UNUSED( lResource )

   lCheck    := iif( lCheck    == Nil, .F., lCheck )
   lDisabled := iif( lDisabled == Nil, .T., !lDisabled )
   nFlag     := Hwg_BitOr( iif( lCheck, FLAG_CHECK, 0 ), ;
                           iif( lDisabled, 0, FLAG_DISABLED ) )

   aMenu := _aMenuDef
   FOR i := 1 TO _nLevel
      aMenu := Atail( aMenu )[1]
   NEXT

   nId := iif( nId == Nil .AND. cItem != Nil, ++ _Id, nId )

   IF !Empty( cItem )
      cItem := StrTran( cItem, "\t", "" )
      cItem := StrTran( cItem, "&", "_" )
   ENDIF

   AAdd( aMenu, { bItem, cItem, nId, nFlag, 0 } )

   IF accFlag != Nil .AND. accKey != Nil
      AAdd( _aAccel, { accFlag, accKey, nId } )
   ENDIF

   RETURN .T.


FUNCTION Hwg_DefineAccelItem( nId, bItem, accFlag, accKey )

   LOCAL aMenu, i

   aMenu := _aMenuDef
   FOR i := 1 TO _nLevel
      aMenu := Atail( aMenu )[1]
   NEXT

   nId := iif( nId == Nil, ++ _Id, nId )

   AAdd( aMenu,  { bItem, Nil, nId, .T., 0 } )
   AAdd( _aAccel, { accFlag, accKey, nId } )

   RETURN .T.


STATIC FUNCTION hwg_Createacceleratortable( oWnd )

   /*
    * GTK4: hwg__Createacceleratortable() returns a GtkShortcutController
    * attached to the window, and hwg__AddAccelerator() registers a
    * GtkShortcut with a GtkNamedAction pointing at the item's GAction.
    */
   LOCAL hTable := hwg__Createacceleratortable( oWnd:handle )
   LOCAL i, nPos, aSubMenu, nKey

   FOR i := 1 TO Len( _aAccel )
      IF ( aSubMenu := Hwg_FindMenuItem( oWnd:menu, _aAccel[i,3], @nPos ) ) != Nil
         IF ( nKey := _aAccel[i,2] ) >= 65 .AND. nKey <= 90
            nKey += 32
         ELSE
            nKey := hwg_gtk_convertkey( nKey )
         ENDIF
         hwg__AddAccelerator( hTable, aSubmenu[1,nPos,5], _aAccel[i,1], nKey )
      ENDIF
   NEXT

   RETURN hTable


STATIC FUNCTION GetMenuByHandle( hWnd )

   LOCAL i, aMenu, oDlg

   IF hWnd == Nil
      aMenu := HWindow():GetMain():menu
   ELSEIF Valtype( hWnd ) == "O"
      IF __ObjHasMsg( hWnd, "MENU" )
         RETURN hWnd:menu
      ELSEIF __ObjHasMsg( hWnd, "AMENU" )
         RETURN hWnd:amenu
      ENDIF
   ELSE
      IF ( oDlg := HDialog():FindDialog( hWnd ) ) != Nil
         aMenu := oDlg:menu
      ELSEIF ( i := Ascan( HDialog():aModalDialogs, ;
                 { |o| Valtype(o:handle)==Valtype(hwnd) .AND. o:handle == hWnd } ) ) != 0
         aMenu := HDialog():aModalDialogs[i]:menu
      ELSEIF ( i := Ascan( HWindow():aWindows, ;
                 { |o| Valtype(o:handle)==Valtype(hwnd) .AND. o:handle==hWnd } ) ) != 0
         aMenu := HWindow():aWindows[i]:menu
      ENDIF
   ENDIF

   RETURN aMenu


FUNCTION hwg_CheckMenuItem( hWnd, nId, lValue )

   LOCAL aMenu, aSubMenu, nPos

   aMenu := GetMenuByHandle( hWnd )
   IF aMenu != Nil
      IF ( aSubMenu := Hwg_FindMenuItem( aMenu, nId, @nPos ) ) != Nil
         hwg__CheckMenuItem( aSubmenu[1,nPos,5], lValue )
      ENDIF
   ENDIF

   RETURN Nil


FUNCTION hwg_IsCheckedMenuItem( hWnd, nId )

   LOCAL aMenu, aSubMenu, nPos, lRes := .F.

   aMenu := GetMenuByHandle( hWnd )
   IF aMenu != Nil
      IF ( aSubMenu := Hwg_FindMenuItem( aMenu, nId, @nPos ) ) != Nil
         lRes := hwg__IsCheckedMenuItem( aSubmenu[1,nPos,5] )
      ENDIF
   ENDIF

   RETURN lRes


FUNCTION hwg_EnableMenuItem( hWnd, nId, lValue )

   LOCAL aMenu, aSubMenu, nPos

   aMenu := GetMenuByHandle( hWnd )
   IF aMenu != Nil
      IF ( aSubMenu := Hwg_FindMenuItem( aMenu, nId, @nPos ) ) != Nil
         hwg__EnableMenuItem( aSubmenu[1,nPos,5], lValue )
      ENDIF
   ENDIF

   RETURN Nil


FUNCTION hwg_IsEnabledMenuItem( hWnd, nId )

   LOCAL aMenu, aSubMenu, nPos

   aMenu := GetMenuByHandle( hWnd )
   IF aMenu != Nil
      IF ( aSubMenu := Hwg_FindMenuItem( aMenu, nId, @nPos ) ) != Nil
         hwg__IsEnabledMenuItem( aSubmenu[1,nPos,5] )
      ENDIF
   ENDIF

   RETURN Nil


/*
 *  hwg_SetMenuCaption( hWnd, nId, cText )
 *
 *  GTK4 note: this updates the label stored inside the GMenuItem.  The
 *  GtkPopoverMenuBar should redraw on the resulting "items-changed".
 *  If a target GTK version does not propagate the change, the caller
 *  must rebuild the menu bar.
 */
FUNCTION hwg_SetMenuCaption( hWnd, nId, cText )

   LOCAL aMenu, aSubMenu, nPos

   aMenu := GetMenuByHandle( hWnd )
   IF aMenu != Nil
      IF ( aSubMenu := Hwg_FindMenuItem( aMenu, nId, @nPos ) ) != Nil
         hwg__SetMenuCaption( aSubmenu[1,nPos,5], cText )
      ENDIF
   ENDIF

   RETURN Nil


/*
 *  hwg_DeleteMenuItem( oWnd, nId )
 *
 *  GTK4 note: GMenu has no "remove item" API without knowing the parent
 *  GMenu and index.  The C-level hwg__DeleteMenu() therefore *disables*
 *  the item's GSimpleAction, and the Harbour-side array entry is removed.
 *
 *  The item visually disappears only after the menu bar is rebuilt.  To
 *  force a rebuild, call Hwg_SetMenu( oWnd, <rebuilt aMenu> ) again or
 *  invoke hwg_BuildMenu() with the modified array.
 */
FUNCTION hwg_DeleteMenuItem( oWnd, nId )

   LOCAL aSubMenu, nPos

   IF ( aSubMenu := Hwg_FindMenuItem( oWnd:menu, nId, @nPos ) ) != Nil
      hwg__DeleteMenu( aSubmenu[1,nPos,5], nId )
      ADel( aSubMenu[ 1 ], nPos )
      ASize( aSubMenu[ 1 ], Len( aSubMenu[ 1 ] ) - 1 )
   ENDIF

   RETURN Nil


FUNCTION hwg_gtk_convertkey( nKey )

   IF nKey >= 65 .AND. nKey <= 90
      nKey += 32
   ENDIF

   RETURN nKey
