*
* template.prg
*
* $Id$
*
* HWGUI template
*
*

#include "hwgui.ch"

FUNCTION Main()
LOCAL oWinMain

INIT WINDOW oWinMain MAIN  ;
     SYSCOLOR COLOR_3DLIGHT+1 ;
     TITLE "Test program template.prg" AT 0, 0 SIZE 600,400;
     STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&Exit"
         MENUITEM "&Quit"    ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Test"
         MENUITEM "&Test it"  ACTION _Testen()
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN NIL

FUNCTION _Testen()

LOCAL otest

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT otest NAME "MS Sans Serif" WIDTH 0 HEIGHT -14
#else
   PREPARE FONT otest NAME "Sans" WIDTH 0 HEIGHT 12
#endif



hwg_MsgInfo("HWGUI template","template.prg")

RETURN NIL


* ======================== EOF of template.prg ====================
