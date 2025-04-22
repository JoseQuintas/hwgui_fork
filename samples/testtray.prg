*
* $Id$
*
* HWGUI test tray sample for WinAPI and GTK/LINUX
*
* Copyright 2022 Wilfried Brunken, DF7BE
* https://sourceforge.net/projects/cllog/
*
* License:
* GNU General Public License
* with special exceptions of HWGUI.
* See file "license.txt" for details.
*
* Sample modified by DF7BE
* 2022-01-03
*
* Special information:
* The behavior on LINUX differs:
* - The main window is visible at start time
*   but the tray menu works as usual under LINUX
*
*
* testtray.rc not needed any more
* (ported from Borland resources to HWGUI commands)
*
* Build testtray.exe:
*  hbmk2 testtray.hbp
*
* Start by enter:
* testtray.exe
*
* The Window is hidden.
* Go to tray and call with right mouse click
*
* Compile bugfix on LINUX:
* testtray.prg(118) Warning W0003  Variable 'OTRAYMENU' declared but not used in function 'MAIN(41)'
* testtray.prg(118) Warning W0032  Variable 'OICON2' is assigned but not used in function 'MAIN(61)'


#include "hwgui.ch"


FUNCTION Main()

   LOCAL oMainWindow, cdirsep, cimagedir
   LOCAL oIcon1
   
#ifndef __GTK__   
    LOCAL oTrayMenu, oIcon2
#endif    

   * Borland resources removed
   // LOCAL oIcon1 := HIcon():AddResource( "ICON_1" )
   // LOCAL oIcon2 := HIcon():AddResource( "ICON_2" )

   cdirsep := hwg_GetDirSep()
   * decides for samples/gtk_samples or samples/

   cimagedir := ".." + cdirsep + "image" + cdirsep


   * Better way to uses hex values for resources instead of
   * icon files

   // oIcon1 := HIcon():AddFile(cimagedir + "ok.ico")
   oIcon1 := HIcon():AddFile(cimagedir + "hwgui_32x32.ico")
   
#ifndef __GTK__   
   oIcon2 := HIcon():AddFile(cimagedir + "cancel.ico")
#endif   

   IF .NOT. FILE(cimagedir + "hwgui_16x16.ico")
      hwg_msgstop("Icon not found: " + cimagedir + "hwgui_32x32.ico")
      RETURN NIL
   ENDIF

   IF .NOT. FILE(cimagedir + "cancel.ico")
      hwg_msgstop("Icon not found: " + cimagedir + "cancel.ico")
      RETURN NIL
   ENDIF

#ifdef __GTK__
   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "Example" ;
      AT 200,0 ;
      SIZE 200,100 ;  && Needed for Ubuntu 16, otherwise not visible
      ICON oIcon1
#else
   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "Example" ;
      AT 0, 0 ;
      SIZE 600, 400
#endif

#ifdef __GTK__
   MENU OF oMainWindow
      * The default context menu is set by systems, the
      * menu of this program is only reachable by set
      * focus on the main window.
      MENU TITLE "&Tray menu"  && Submenu avoid "Activate (Aktivieren)" only
#else
      CONTEXT MENU oTrayMenu
#endif
         MENUITEM "Message"  ACTION hwg_Msginfo( "Tray Message !" )
#ifndef __GTK__
         * At this time there is no way to change the tray icon on LINUX on running application
         MENUITEM "Change icon"  ACTION hwg_ShellModifyicon( oMainWindow:handle, oIcon2:handle )
#endif
         SEPARATOR
         MENUITEM "Exit"  ACTION hwg_EndWindow()
      ENDMENU
#ifdef __GTK__
   ENDMENU
   oMainWindow:DEICONIFY()
   ACTIVATE WINDOW oMainWindow CENTER
#else
   * InitTray( oNotifyIcon, bNotify, oNotifyMenu, cTooltip )
   oMainWindow:InitTray( oIcon1, oTrayMenu:aMenu[1,1,1], oTrayMenu, "TestTray" )

   ACTIVATE WINDOW oMainWindow NOSHOW
   oTrayMenu:End()
#endif

RETURN Nil

* ======================== EOF of testtray.prg =================================

