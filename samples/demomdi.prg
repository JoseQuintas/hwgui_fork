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
         MENUITEM "Tile"  ;
            ACTION  hwg_Sendmessage( HWindow():GetMain():handle, WM_MDITILE, MDITILE_HORIZONTAL, 0 )
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
