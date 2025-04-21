*
* ticket79.prg
*
* Test program for
* Ticket #79: COLOR doesn't work with GET under Linux
*
* without or with COLOR parameter, the text in the get is always grey ...
*
* The foreground color (text color)
* in GET entry fields cannot be modified.
* See GTK 2 reference for gtk_entry_* class.
* There is no parameter "color" explained.
*

#include "hwgui.ch"

#define ID_ODT 101

FUNCTION Main()
LOCAL oWinMain

INIT WINDOW oWinMain MAIN  ;
     SYSCOLOR COLOR_3DLIGHT+1 ;
     TITLE "Test program Coloured GET" AT 0, 0 SIZE 600,400;
     STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&Exit"
         MENUITEM "&Quit"    ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Test"
         MENUITEM "&Start"     ACTION _Testen()
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN NIL

FUNCTION _Testen()
LOCAL oodt , codt , nget

 nget := 1
 codt := "1234567890abc   "

   INIT DIALOG oDlg TITLE "Ticket #79" ;
        AT 0,0 SIZE 300, 500  ;
        STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   @ 10, 14 + (30 * nget) GET oodt VAR codt ID ID_ODT COLOR hwg_ColorC2N("FF0000") SIZE 474,24

   oDlg:Activate()

RETURN NIL

* =========================== EOF of ticket79.prg ===============================


