/*
 * $Id: testmenu1.prg
 * Menu screen size
 *
 */

#include "hwgui.ch"

#ifdef __USING_MENU__
   PROCEDURE TestMenu1
#else
   PROCEDURE Main
#endif
   LOCAL oDlg
   LOCAL oFont := HFont():Add( "MS Sans Serif",0,-13 )

   INIT DIALOG oDlg  TITLE "TESTMENU1 - Menu Desktop Size" ;
     AT 200,0 SIZE hwg_GetDesktopWidth(), hwg_GetDesktopHeight() FONT oFont

   MENU OF oDlg
      MENU TITLE "&File"
         MENUITEM "&New" ACTION hwg_Msginfo( "New" )
         MENUITEM "&Open" ACTION hwg_Msginfo( "Open" )
         SEPARATOR
         MENUITEM "&Font" ACTION hwg_Msginfo( "font" )
         SEPARATOR
         MENUITEM "&Exit" ACTION hwg_EndDialog()
      ENDMENU
   ENDMENU

   ACTIVATE DIALOG oDlg

   RETURN
