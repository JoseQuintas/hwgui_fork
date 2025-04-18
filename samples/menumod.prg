/*
 * $Id$
 *
 * This sample demonstrates handling menu items
 * while run-time in dialogs.
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

#include "hwgui.ch"

MEMVAR aItems , oDialg

FUNCTION Main()

   LOCAL oWinMain

   PRIVATE aItems

   INIT WINDOW oWinMain ;
      MAIN  ;
      SYSCOLOR COLOR_3DLIGHT+1 ;
      TITLE "Sample program handling menu items" ;
      AT 0, 0 ;
      SIZE 600,400;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&Exit"
         MENUITEM "&Quit"    ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Test"
         MENUITEM "Menu"     ACTION _menudialog()
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN Nil

FUNCTION _menudialog()

   LOCAL oFont , citem , i

   PRIVATE oDialg

   *  aItems := { "One" , "Two" , "Three", "Four"}
   *  aItems := {}
   aItems := { "<empty>" }

   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT -17

   INIT DIALOG oDialg ;
      TITLE "Menu Sample"  ;
      AT 200,0 ;
      SIZE 600,300                       ;
      FONT oFont


   MENU OF oDialg
      MENU TITLE "Menu"
         MENUITEM "New item" ACTION NewItem(0)
         SEPARATOR
          IF ! Empty( aItems )
             FOR i := 1 TO Len( aItems )
                citem := aItems[i]
                Hwg_DefineMenuItem( citem, 1020 + i, &( "{ | | NewItem("+LTrim(Str(i,2))+")}" ) )
                * other behavior on GTK:
                * the new item was appended at the end of the menu in the recent run.
             NEXT
            ENDIF
            SEPARATOR
         MENUITEM "Return" ACTION {||oDialg:Close() }
      ENDMENU
   ENDMENU

   ACTIVATE DIALOG oDialg

RETURN Nil

FUNCTION NewItem( nItem )

   LOCAL oDlg , oFont
   LOCAL aMenu, nId
   LOCAL cName
   LOCAL oGet1

   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT -17

   IF nItem > 0
      * Trim variables for GET
      cName := PADR(cName, 30)
   ELSE
      cName := Space(30)
   ENDIF

    cName := hwg_GET_Helper(cName,30)


   INIT DIALOG oDlg TITLE ;
      Iif( nItem==0,"New item","Change item" )  ;
      AT 210,10  ;
      SIZE 700,150 ;
      FONT oFont

   @ 20,20 SAY "Name:" ;
      SIZE 60, 22

   @ 80,20 GET oGet1 ;
      VAR cName ;
      SIZE 500, 26 ;
      STYLE WS_BORDER

   @ 20,110  BUTTON "Ok" ;
      SIZE 100, 32 ;
      ON CLICK {||oDlg:lResult:=.T.,hwg_EndDialog()}

   @ 180,110 BUTTON "Cancel" ;
      ID IDCANCEL ;
      SIZE 100, 32

   ACTIVATE DIALOG oDlg

   * Trim from GET

   cName := AllTrim(cName)

* Hwg_AddMenuItem( aMenu, cItem, nMenuId, lSubMenu, bItem, nPos, hWnd )

    IF oDlg:lResult .AND. ! Empty(cName)
      IF nItem == 0
         aMenu := oDialg:menu[1,1]
         nId := aMenu[1][Len(aMenu[1])-2,3]+1
         Hwg_AddMenuItem( aMenu, cName, nId, .F., ;
              &( "{ | | NewItem("+LTrim(Str(nId-1020,2))+")}" ), Len(aMenu[1])-1 )
      ELSE
         * Modified
         hwg_Setmenucaption( oDialg:handle, 1020+nItem, cName )
      ENDIF
*
    ENDIF

RETURN Nil

* ==================== EOF of menumod.prg ======================
