/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  fileselect.prg
 *
 * Sample for file selection menues
 *
 * Copyright 2020 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes


* Some additional instructions:
* GTK:
* hwg_&Selectfile() ignores the mask and shows all files
* Use hwg_&SelectfileEx() instead.


#include "hwgui.ch"

FUNCTION Main
LOCAL oFormMain, oFontMain

PRIVATE cloctext,clocmsk,clocallf,cstartvz

* Get current directory as start directory
cstartvz := Curdir()

cloctext := "XBase source code( *.prg )"
clocmsk  := "*.prg"
clocallf := "All files"


#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFontMain NAME "MS Sans Serif" WIDTH 0 HEIGHT -14
#else
   PREPARE FONT oFontMain NAME "Sans" WIDTH 0 HEIGHT 12
#endif

* The background image was tiled, if size is smaller than window.
INIT WINDOW oFormMain MAIN  ;
   FONT oFontMain;
   TITLE "Hwgui sample for File Selection" AT 0,0 SIZE 300,200 ;
   STYLE WS_POPUP +  WS_CAPTION + WS_SYSMENU
  MENU OF oFormMain
      MENU TITLE "&Exit"
        MENUITEM "&Quit" ACTION oFormMain:Close()
      ENDMENU
      MENU TITLE "&Test"
        MENUITEM "hwg_&Selectfile()" ACTION Test1()
#ifdef __GTK__
        MENUITEM "hwg_&SelectfileEx()" ACTION Test2()
#else
        MENUITEM "hwg_SaveFile()" ACTION Test4()
#endif
        MENUITEM "hwg_SelectFolder()" ACTION Test3()
      ENDMENU
   ENDMENU

* Start select file dialog

   oFormMain:Activate()
RETURN NIL

FUNCTION Test1
LOCAL fname
 fname := hwg_Selectfile(cloctext , clocmsk, cstartvz )
 * Check for cancel
 IF EMPTY(fname)
  action_aborted()
  RETURN NIL
 ENDIF
 action_selected(fname)
RETURN NIL

FUNCTION Test2
LOCAL fname
#ifdef __GTK__
 fname := hwg_SelectFileEx(,,{{ cloctext,clocmsk },{ clocallf ,"*"}} )
* Check for cancel
 IF EMPTY(fname)
  action_aborted()
  RETURN NIL
 ENDIF
 action_selected(fname)
#endif
RETURN NIL

FUNCTION Test3
LOCAL fname
 fname := hwg_SelectFolder("Select sample folder")
* Check for cancel
 IF EMPTY(fname)
  action_aborted()
  RETURN NIL
 ENDIF
 action_selected(fname)
RETURN NIL

FUNCTION Test4
LOCAL fname
#ifndef __GTK__
 fname := hwg_SaveFile( "Enter name of new file","Test text file","*.txt",cstartvz,"Save File" )
 * Check for cancel
 IF EMPTY(fname)
  action_aborted()
  RETURN NIL
 ENDIF
 action_selected(fname)
#endif
RETURN NIL


FUNCTION action_aborted
  hwg_MsgStop("Selection Canceled","HWGUI Sample")
RETURN NIL

FUNCTION action_selected
 PARAMETERS pcfname
  hwg_MsgInfo("Selection done: " + pcfname ,"HWGUI Sample")
RETURN NIL

* ======================= EOF of fileselect.prg ==============================
