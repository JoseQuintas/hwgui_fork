/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Prg level menu functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

#define  MENU_FIRST_ID   32000
#define  CONTEXTMENU_FIRST_ID   32900
#define  FLAG_DISABLED   1
#define  FLAG_CHECK      2

STATIC _aMenuDef, _oWnd, _aAccel, _nLevel, _Id, _oMenu, _oBitmap

CLASS HMenu INHERIT HObject

   DATA handle
   DATA aMenu
   METHOD New()  INLINE Self
   METHOD END()  INLINE Hwg_DestroyMenu( ::handle )
   METHOD Show( oWnd, xPos, yPos, lWnd )

ENDCLASS

METHOD Show( oWnd, xPos, yPos, lWnd ) CLASS HMenu

   LOCAL aCoor

   oWnd:oPopup := Self
   IF PCount() == 1 .OR. lWnd == Nil .OR. ! lWnd
      IF PCount() == 1
         aCoor := hwg_GetCursorPos()
         xPos  := aCoor[ 1 ]
         yPos  := aCoor[ 2 ]
      ENDIF
      Hwg_trackmenu( ::handle, xPos, yPos, oWnd:handle )
   ELSE
      aCoor := hwg_Clienttoscreen( oWnd:handle, xPos, yPos )
      Hwg_trackmenu( ::handle, aCoor[ 1 ], aCoor[ 2 ], oWnd:handle )
   ENDIF

   RETURN Nil

FUNCTION Hwg_CreateMenu

   LOCAL hMenu

   IF Empty( hMenu := hwg__CreateMenu() )
      RETURN Nil
   ENDIF

   RETURN { { },,, hMenu }

FUNCTION Hwg_SetMenu( oWnd, aMenu )

   IF ! Empty( oWnd:handle )
      IF hwg__SetMenu( oWnd:handle, aMenu[ 5 ] )
         oWnd:menu := aMenu
      ELSE
         RETURN .F.
      ENDIF
   ELSE
      oWnd:menu := aMenu
   ENDIF

   RETURN .T.

/*
 *  AddMenuItem( aMenu,cItem,nMenuId,lSubMenu,[bItem] [,nPos] ) --> aMenuItem
 *
 *  If nPos is omitted, the function adds menu item to the end of menu,
 *  else it inserts menu item in nPos position.
 */

FUNCTION Hwg_AddMenuItem( aMenu, cItem, nMenuId, lSubMenu, bItem, nPos )

   LOCAL hSubMenu

   IF nPos == Nil
      nPos := Len( aMenu[ 1 ] ) + 1
   ENDIF

   hSubMenu := aMenu[ 5 ]
   hSubMenu := hwg__AddMenuItem( hSubMenu, cItem, nPos - 1, .T., nMenuId,, lSubMenu )

   IF nPos > Len( aMenu[ 1 ] )
      IF Empty( lSubMenu )
         AAdd( aMenu[ 1 ], { bItem, cItem, nMenuId, 0 } )
      ELSE
         AAdd( aMenu[ 1 ], { { }, cItem, nMenuId, 0, hSubMenu } )
      ENDIF
      RETURN ATail( aMenu[ 1 ] )
   ELSE
      AAdd( aMenu[ 1 ], Nil )
      AIns( aMenu[ 1 ], nPos )
      IF Empty( lSubMenu )
         aMenu[ 1, nPos ] := { bItem, cItem, nMenuId, 0 }

      ELSE
         aMenu[ 1, nPos ] := { { }, cItem, nMenuId, 0, hSubMenu }
      ENDIF
      RETURN aMenu[ 1, nPos ]
   ENDIF

   RETURN Nil

FUNCTION Hwg_FindMenuItem( aMenu, nId, nPos )

   LOCAL nPos1, aSubMenu

   nPos := 1
   DO WHILE nPos <= Len( aMenu[ 1 ] )
      IF aMenu[ 1, nPos, 3 ] == nId
         RETURN aMenu
      ELSEIF Len( aMenu[ 1, nPos ] ) > 4
         IF ( aSubMenu := Hwg_FindMenuItem( aMenu[ 1, nPos ] , nId, @nPos1 ) ) != Nil
            nPos := nPos1
            RETURN aSubMenu
         ENDIF
      ENDIF
      nPos ++
   ENDDO

   RETURN Nil

FUNCTION Hwg_GetSubMenuHandle( aMenu, nId )

   LOCAL aSubMenu := Hwg_FindMenuItem( aMenu, nId )

   RETURN IIf( aSubMenu == Nil, 0, aSubMenu[ 5 ] )

FUNCTION hwg_BuildMenu( aMenuInit, hWnd, oWnd, nPosParent, lPopup )

   LOCAL hMenu, nPos, aMenu, oBmp

   IF nPosParent == Nil
      IF lPopup == Nil .OR. ! lPopup
         hMenu := hwg__CreateMenu()
      ELSE
         hMenu := hwg__CreatePopupMenu()
      ENDIF
      aMenu := { aMenuInit,,,, hMenu }
   ELSE
      hMenu := aMenuInit[ 5 ]
      nPos := Len( aMenuInit[ 1 ] )
      aMenu := aMenuInit[ 1, nPosParent ]
      /* This code just for sure menu runtime hfrmtmpl.prg is enable */
      IIf( ValType( aMenu[ 4 ] ) == "L", aMenu[ 4 ] := .f., )
      hMenu := hwg__AddMenuItem( hMenu, aMenu[ 2 ], nPos + 1, .T., aMenu[ 3 ], aMenu[ 4 ], .T. )
      IF Len( aMenu ) < 5
         AAdd( aMenu, hMenu )
      ELSE
         aMenu[ 5 ] := hMenu
      ENDIF
   ENDIF

   nPos := 1
   DO WHILE nPos <= Len( aMenu[ 1 ] )
      IF ValType( aMenu[ 1, nPos, 1 ] ) == "A"
         hwg_BuildMenu( aMenu,,, nPos )
      ELSE
         IF aMenu[ 1, nPos, 1 ] == Nil .OR. aMenu[ 1, nPos, 2 ] != Nil
            /* This code just for sure menu runtime hfrmtmpl.prg is enable */
            IIf( ValType( aMenu[ 1, nPos, 4 ] ) == "L", aMenu[ 1, nPos, 4 ] := .f., )
            hwg__AddMenuItem( hMenu, aMenu[ 1, nPos, 2 ], nPos, .T., ;
                              aMenu[ 1, nPos, 3 ], aMenu[ 1, nPos, 4 ], .F. )
            oBmp := SearchPosBitmap( aMenu[ 1, nPos, 3 ] )
            IF oBmp[ 1 ]
               hwg__Setmenuitembitmaps( hMenu, aMenu[ 1, nPos, 3 ], oBmp[ 2 ], "" )
            ENDIF

         ENDIF
      ENDIF
      nPos ++
   ENDDO
   IF hWnd != Nil .AND. oWnd != Nil
      Hwg_SetMenu( oWnd, aMenu )
   ELSEIF _oMenu != Nil
      _oMenu:handle := aMenu[ 5 ]
      _oMenu:aMenu := aMenu
   ENDIF

   RETURN Nil

FUNCTION Hwg_BeginMenu( oWnd, nId, cTitle )

   LOCAL aMenu, i

   IF oWnd != Nil
      _aMenuDef := { }
      _aAccel   := { }
      _oBitmap  := { }
      _oWnd     := oWnd
      _oMenu    := Nil
      _nLevel   := 0
      _Id       := IIf( nId == Nil, MENU_FIRST_ID, nId )
   ELSE
      nId   := IIf( nId == Nil, ++ _Id, nId )
      aMenu := _aMenuDef
      FOR i := 1 TO _nLevel
         aMenu := ATail( aMenu )[ 1 ]
      NEXT
      _nLevel ++
      AAdd( aMenu, { { }, cTitle, nId, 0 } )
   ENDIF

   RETURN .T.

FUNCTION Hwg_ContextMenu()

   _aMenuDef := { }
   _oBitmap  := { }
   _oWnd := Nil
   _nLevel := 0
   _Id := CONTEXTMENU_FIRST_ID
   _oMenu := HMenu():New()
   RETURN _oMenu

FUNCTION Hwg_EndMenu()

   IF _nLevel > 0
      _nLevel --
   ELSE
      hwg_BuildMenu( AClone( _aMenuDef ), IIf( _oWnd != Nil, _oWnd:handle, Nil ), ;
                 _oWnd,, IIf( _oWnd != Nil, .F., .T. ) )
      IF _oWnd != Nil .AND. _aAccel != Nil .AND. ! Empty( _aAccel )
         _oWnd:hAccel := hwg_Createacceleratortable( _aAccel )
      ENDIF
      _aMenuDef := Nil
      _oBitmap  := Nil
      _aAccel   := Nil
      _oWnd     := Nil
      _oMenu    := Nil
   ENDIF

   RETURN .T.

FUNCTION Hwg_DefineMenuItem( cItem, nId, bItem, lDisabled, accFlag, accKey, lBitmap, lResource, lCheck )

   LOCAL aMenu, i, oBmp, nFlag

   lCheck := IIf( lCheck == Nil, .F., lCheck )
   lDisabled := IIf( lDisabled == Nil, .f., lDisabled )
   nFlag := Hwg_BitOr( IIf( lCheck, FLAG_CHECK, 0 ), IIf( lDisabled, FLAG_DISABLED, 0 ) )

   aMenu := _aMenuDef
   FOR i := 1 TO _nLevel
      aMenu := ATail( aMenu )[ 1 ]
   NEXT
   IF ! Empty( cItem )
      cItem := StrTran( cItem, "\t", Chr( 9 ) )
   ENDIF
   nId := IIf( nId == Nil .AND. cItem != Nil, ++ _Id, nId )
   AAdd( aMenu, { bItem, cItem, nId, nFlag } )
   /* FIXED: era .OR., o que disparava o carregamento do bitmap mesmo
    * quando lBitmap era uma string vazia "" (nao Nil, porem vazia).
    * Com .AND. so tenta carregar quando ha de fato um valor informado
    * e nao-vazio. */
   IF lBitmap != Nil .AND. ! Empty( lBitmap )
      IF lResource == Nil ;lResource := .F. ; ENDIF
      IF ! lResource
         oBmp := HBitmap():AddFile( lBitmap )
      ELSE
         oBmp := HBitmap():AddResource( lBitmap )
      ENDIF
      AAdd( _oBitmap, { .t., oBmp:Handle, cItem, nId } )
   ELSE
      AAdd( _oBitmap, { .F., "", cItem, nId } )
   ENDIF
   IF accFlag != Nil .AND. accKey != Nil
      AAdd( _aAccel, { accFlag, accKey, nId } )
   ENDIF

   RETURN .T.

FUNCTION Hwg_DefineAccelItem( nId, bItem, accFlag, accKey )

   LOCAL aMenu, i

   aMenu := _aMenuDef
   FOR i := 1 TO _nLevel
      aMenu := ATail( aMenu )[ 1 ]
   NEXT
   nId := IIf( nId == Nil, ++ _Id, nId )
   AAdd( aMenu, { bItem, Nil, nId, 0 } )
   AAdd( _aAccel, { accFlag, accKey, nId } )

   RETURN .T.


FUNCTION Hwg_SetMenuItemBitmaps( aMenu, nId, abmp1, abmp2 )

   LOCAL aSubMenu := Hwg_FindMenuItem( aMenu, nId )
   LOCAL oMenu  && := aSubMenu

   oMenu := IIf( aSubMenu == Nil, 0, aSubMenu[ 5 ] )
   hwg__Setmenuitembitmaps( oMenu, nId, abmp1, abmp2 )

   RETURN Nil

FUNCTION Hwg_InsertBitmapMenu( aMenu, nId, lBitmap, oResource )

   LOCAL aSubMenu := Hwg_FindMenuItem( aMenu, nId )
   LOCAL oBmp
   LOCAL oMenu && := aSubMenu, oBmp

   //Serge(seohic) sugest
   IF oResource == Nil .or. ! oResource
      oBmp := HBitmap():AddFile( lBitmap )
   ELSE
      oBmp := HBitmap():AddResource( lBitmap )
   ENDIF
   oMenu := IIf( aSubMenu == Nil, 0, aSubMenu[ 5 ] )
   HWG__InsertBitmapMenu( oMenu, nId, oBmp:handle )
   RETURN Nil

STATIC FUNCTION SearchPosBitmap( nPos_Id )

   LOCAL nPos := 1, lBmp := { .F., "" }

   IF _oBitmap != Nil
      DO WHILE nPos <= Len( _oBitmap )

         IF _oBitmap[ nPos ][ 4 ] == nPos_Id
            lBmp := { _oBitmap[ nPos ][ 1 ], _oBitmap[ nPos ][ 2 ], _oBitmap[ nPos ][ 3 ] }
         ENDIF

         nPos ++

      ENDDO
   ENDIF

   RETURN lBmp

FUNCTION hwg_DeleteMenuItem( oWnd, nId )

   LOCAL aSubMenu, nPos

   IF ( aSubMenu := Hwg_FindMenuItem( oWnd:menu, nId, @nPos ) ) != Nil
      ADel( aSubMenu[ 1 ], nPos )
      ASize( aSubMenu[ 1 ], Len( aSubMenu[ 1 ] ) - 1 )

      hwg_DeleteMenu( hwg_Getmenuhandle( oWnd:handle ), nId )
   ENDIF

   RETURN Nil
