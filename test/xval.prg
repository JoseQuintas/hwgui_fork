*
* xval.prg
*
* $Id$
*
* Test program for functions
* hwg_ValType(), hwg_xVal2C(), hwg_xvalMsg() and hwg_xvalLog().
*
*

#include "hwgui.ch"

FUNCTION Main()
LOCAL oWinMain

INIT WINDOW oWinMain MAIN  ;
     SYSCOLOR COLOR_3DLIGHT+1 ;
     TITLE "Test program xval.prg" AT 0, 0 SIZE 600,400;
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




* "U" (NIL)
hwg_xvalMsg()
hwg_xvalLog()
* "A"
hwg_xvalMsg( {1,2,3} )
hwg_xvalLog( {1,2,3} )
* "L"
hwg_xvalMsg(.T.)
hwg_xvalLog(.T.)
* "N"
hwg_xvalMsg(12345)
hwg_xvalLog(12345)
* "C"
hwg_xvalMsg("Test")
hwg_xvalLog("Test")
* "D" (today)
hwg_xvalMsg( DATE() )
hwg_xvalLog( DATE() )
* "O"
hwg_xvalMsg(otest)
hwg_xvalLog(otest)

hwg_MsgInfo("Values also written to file a.log","Sample xval.prg")

RETURN NIL


* ======================== EOF of xval.prg ====================
