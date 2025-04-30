/*
demomdi.prg
*/

#include "hwgui.ch"

FUNCTION DemoMDI()

   LOCAL oDlg

   INIT WINDOW oDlg ;
      MDI ;
      TITLE "Test samples" ;
      SIZE 1024, 768 ;
      BACKCOLOR 16772062

   MENU OF oDlg
      MENU TITLE "Sample"
         MENUITEM "checkbox.prg" ACTION DlgSample()
      ENDMENU
      MENU TITLE "Option"
         MENUITEM "Window" ID 1001 ;
            ACTION hwg_CheckMenuItem( , 1001, ! hwg_IsCheckedMenuItem( , 1001 ) )
         MENUITEM "Tabpage" ID 1002 ;
            ACTION hwg_CheckMenuItem( , 1002, ! hwg_IsCheckedMenuItem( , 1002 ) )
         MENUITEM "Tabpage 2" ID 1003 ;
            ACTION hwg_CheckMenuItem( , 1003, ! hwg_IsCheckedMenuItem( , 1003 ) )
         MENUITEM "Panel" ID 1004 ;
            ACTION hwg_CheckMenuItem( , 1004, ! hwg_IsCheckedMenuItem( , 1004 ) )
         MENUITEM "MDI" ID 1005 ;
            ACTION hwg_CheckMenuItem( , 1005, ! hwg_IsCheckedMenuItem( , 1005 ) )
      ENDMENU
      MENU TITLE "Window"
         MENUITEM "Tile Horizontal"  ;
            ACTION  hwg_Sendmessage( HWindow():GetMain():handle, WM_MDITILE, MDITILE_HORIZONTAL, 0 )
         MENUITEM "Tile Vertical" ;
            ACTION hwg_Sendmessage( HWindow():GetMain():handle, WM_MDITILE, MDITILE_VERTICAL, 0 )
         MENUITEM "Cascade" ;
            ACTION hwg_Sendmessage( HWindow():GetMain():handle, WM_MDICASCADE, 0, 0 )
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oDlg CENTER

   RETURN Nil

STATIC FUNCTION DlgSample()

   LOCAL oDlg, lIsWindow, lIsTabPage, lIsTabPage2, lIsPanel
   LOCAL lIsMDI, oTab, nCont, nPageCount := 0

   lIsWindow    := hwg_IsCheckedMenuItem( ,1001 )
   lIsTabPage   := hwg_IsCheckedMenuItem( ,1002 )
   lIsTabPage2  := hwg_IsCheckedMenuItem( ,1003 )
   lIsPanel     := hwg_IsCheckedMenuItem( ,1004 )
   lIsMDI       := hwg_IsCheckedMenuItem( ,1005 )

   nPageCount += iif( lIsTabPage, 1, 0 )
   nPageCount += iif( lIsTabPage2, 1, 0 )

   DO CASE
   CASE lIsMDI

      INIT WINDOW oDlg ;
         MDICHILD ;
         TITLE "democheckbox.prg" ;
         SIZE 800, 600 ;
         STYLE WS_VISIBLE + WS_OVERLAPPEDWINDOW

   CASE lIsWindow

      INIT WINDOW oDlg ;
         TITLE "democheckbox.prg" ;
         SIZE 800, 600 ;
         STYLE WS_VISIBLE + WS_OVERLAPPEDWINDOW

   OTHERWISE

      INIT DIALOG oDlg ;
         TITLE "democheckbox.prg" ;
         SIZE 800, 600 ;
         STYLE WS_VISIBLE + WS_OVERLAPPEDWINDOW

   ENDCASE

   IF lIsTabPage .OR. lIsTabPage2
      @ 3, 10 TAB oTab ITEMS {} OF oDlg SIZE 700, 500
   ELSE
      DemoCheckbox( .F., oDlg )
   ENDIF

   FOR nCont = 1 TO nPageCount

      BEGIN PAGE "TabPage" OF oTab

      IF lIsPanel
      ENDIF

      DemoCheckbox( .F., oTab )

      END PAGE OF oTab

   NEXT

   DO CASE
   CASE lIsMDI
      ACTIVATE WINDOW oDlg
   CASE lIsWindow
      // ACTIVATE WINDOW oDlg CENTER
      hwg_MsgInfo( "Not available" )
      RETURN Nil
   OTHERWISE
      ACTIVATE DIALOG oDlg CENTER
   ENDCASE

   (oTab) := Nil       // warning -w3 -es2
   (oTab)

   RETURN Nil
