/*
dlgWinOnly
*/

#include "hwgui.ch"

PROCEDURE Main

   Dialog1()

   RETURN

FUNCTION Dialog1()

   LOCAL oDlg

   INIT WINDOW oDlg MAIN TITLE "Dialog 1" ;
      AT 0, 0 SIZE 600, 400

   MENU OF oDlg
      MENU TITLE "Opções"
         MENUITEM "Dialog2" ACTION { || Dialog2() }
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oDlg CENTER

   RETURN Nil

FUNCTION Dialog2()

   LOCAL oDlg

   INIT WINDOW oDlg TITLE "Dialog 2" ;
      AT 0, 0 SIZE 500, 300

   ACTIVATE WINDOW oDlg CENTER

   RETURN Nil

