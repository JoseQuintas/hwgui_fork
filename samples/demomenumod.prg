/*
 * $Id$ demomenumod
 *
 * This sample demonstrates handling menu items
 * while run-time in dialogs.
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

#include "hwgui.ch"

FUNCTION DemoMenuMod()

   LOCAL oFont, citem, nCont, bCode, xVarToBCode, oDlg
   LOCAL aItems := { "<empty>" }

   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT -17

   INIT DIALOG oDlg ;
      TITLE "Menu Sample"  ;
      AT 200, 0 ;
      SIZE 600, 300                       ;
      FONT oFont
      // note: only window // SYSCOLOR COLOR_3DLIGHT+1 ;
      // note: not sure    // STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oDlg
      MENU TITLE "Menu"
         MENUITEM "New item" ACTION NewItem( 0, oDlg, aItems )
         SEPARATOR
         IF ! Empty( aItems )
            FOR nCont = 1 TO Len( aItems )
               citem := aItems[ nCont ]
               FOR EACH xVarToBCode IN { nCont }
                  bCode := { || NewItem( xVarToBCode, oDlg, aItems ) }
               NEXT
               Hwg_DefineMenuItem( citem, 1020 + nCont, bCode )
               * other behavior on GTK:
               * the new item was appended at the end of the menu in the recent run.
            NEXT
         ENDIF
         SEPARATOR
         MENUITEM "Return" ACTION { || oDlg:Close() }
      ENDMENU
   ENDMENU

   ButtonForSample( "demomenumod.prg", oDlg )

   ACTIVATE DIALOG oDlg CENTER

RETURN Nil

STATIC FUNCTION NewItem( nItem, oDlgMenu, aItems )

   LOCAL oDlg , oFont, aMenu, nId, cCaption, oGet1, bCode, xVarToBCode

   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT -17

   IF nItem > 0 .AND. nItem <= Len( aItems )
      cCaption := aItems[ nItem ]
   ELSE
      cCaption := ""
   ENDIF

   INIT DIALOG oDlg TITLE ;
      Iif( nItem == 0, "New item", "Change item" )  ;
      AT 210, 10  ;
      SIZE 700, 150 ;
      FONT oFont

   @ 20, 20 SAY "Name:" ;
      SIZE 60, 22

   @ 80, 20 GET oGet1 ;
      VAR cCaption ;
      SIZE 500, 26 ;
      MAXLENGTH 50 ;
      STYLE WS_BORDER

   @ 20, 110  BUTTON "Ok" ;
      SIZE 100, 32 ;
      ON CLICK {|| oDlg:lResult := .T., oDlg:Close() }

   @ 180, 110 BUTTON "Cancel" ;
      ID IDCANCEL ;
      SIZE 100, 32

   ACTIVATE DIALOG oDlg CENTER

   * Trim from GET

   cCaption := AllTrim( cCaption )

* Hwg_AddMenuItem( aMenu, cItem, nMenuId, lSubMenu, bItem, nPos, hWnd )

   IF oDlg:lResult .AND. ! Empty( cCaption )
      IF nItem == 0
         aMenu := oDlgMenu:menu[ 1, 1 ]
         nId := aMenu[ 1 ][ Len( aMenu[ 1 ] ) - 2, 3 ] + 1
         FOR EACH xVarToBCode IN { nId }
            bCode := { || NewItem( xVarToBCode - 1020, oDlgMenu, aItems ) }
         NEXT
         Hwg_AddMenuItem( aMenu, cCaption, nId, .F., bCode, Len( aMenu[ 1 ] ) - 1 )
         AAdd( aItems, cCaption )
      ELSE
         * Modified
         hwg_Setmenucaption( oDlgMenu:handle, 1020 + nItem, cCaption )
      ENDIF
   ENDIF

RETURN Nil

#include "demo.ch"

* ==================== EOF of demomenumod.prg ======================
