/*
demomdi.prg
*/

#include "hwgui.ch"

FUNCTION DemoMDI()

   LOCAL oDlg

   INIT WINDOW oDlg ;
      MDI ;
      TITLE "demomdi.prg - MDI Sample and more" ;
      SIZE 800, 500 ;
      BACKCOLOR 16772062

   MENU OF oDlg
      MENU TITLE "Option"
         MENUITEM "Checkbox" ACTION DlgCheckbox()
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

STATIC FUNCTION DlgCheckbox()

   LOCAL oDlg

   INIT WINDOW oDlg ;
      MDICHILD ;
      TITLE "democheckbox.prg" ;
      STYLE WS_VISIBLE + WS_OVERLAPPEDWINDOW

   DemoCheckbox( .F., oDlg )

   ACTIVATE WINDOW oDlg

   RETURN Nil
