/*
 * hello.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 * Sample program for
 * some elements: Edit field, tabs, tree view, combobox, ...
 *
 * Copyright 2005-2022 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Reduced
    *  GTK/Win  :  -
 *
 * Modifications by DF7BE:
 * - Port to GTK, deactivate "Windows only" functions
 * - Added more explanation
 * -
 *
 * List of deactived "Windows only" functions for GTK:
 * - Function PS1( oWnd ): hwg_PropertySheet(),
 * - HRICHEDIT(),
 * - HWG_RE_SETCHARFORMAT(),
 * - HWG_SETTABSIZE(),
 * - HWG_MSGTEMP(),     ==> only for debugging purposes, explanation see inline
 *                          comments in source code file source\winapi\message.c
 *                          The screenshot is available in samples\doc\image\Hello_InfoDlg_Win.png
 * - HWG_GETEDITTEXT(),
 * - HWG_SETDLGITEMTEXT()
 *
 * Design differences for GTK:
 *
 * In most cases, the design (for positions and sizes for GUI elements) differ
 * between WinAPI and GTK/LINUX.
 * For example:
 * The combobox size is more bigger.
 *
 * It is recommended to check the design for multi platform applications
 * also on LINUX !
 *
 * In this sample program, we demonstrate the differences.
 * Look at compiler switch
 * #ifdef __GTK__
 * for differences.
*/

#include "hwgui.ch"

MEMVAR aGetsTab

FUNCTION Main()

   LOCAL oMainWindow, aCombo := {"First","Second" }, oFont // oBtn, cTool := "Example",
   LOCAL aTabs := { "A","B","C","D","E","F","G","H","I","J","K","L","M","N" }, oTab
   LOCAL acho := { {"First item",180}, {"Second item",200} }
   LOCAL oEdit, oGetTab, oTree, oItem, oCombo
   LOCAL cExecprg
   PRIVATE aGetsTab := { "","","","","","","","","","","","","","" }

   // PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT -17 CHARSET 4

* Call of external programs differs between Windows and LINUX
#ifdef __GTK__
    cExecprg := "gedit Sample.txt"
#else
    cExecprg := "notepad Sample.txt"
#endif

#ifdef __GTK__
   * increased size of main window
   INIT WINDOW oMainWindow MAIN TITLE "Example"  ;
     SYSCOLOR COLOR_3DLIGHT+1                    ;
     AT 200,0 SIZE 600,400                       ;
     FONT oFont                                  ;
     ON EXIT {||hwg_Msgyesno("Really want to quit ?")}
#else
   INIT WINDOW oMainWindow MAIN TITLE "Example"  ;
     SYSCOLOR COLOR_3DLIGHT+1                    ;
     AT 200,0 SIZE 420,300                       ;
     FONT oFont                                  ;
     ON EXIT {||hwg_Msgyesno("Really want to quit ?")}
#endif

#ifndef __GTK__

* The Rich text format is a feature of Windows.
* It allows formatted text handling.
* All functions are implemented in riched20.dll.
* So this feature is not available on GTK/LINUX.
* See screenshot of this sample program in
* samples\doc\image\Hello_main_Win.png
* Functions for rich text format in source code file
* source\winapi\richedit.c

   @ 20,10 RICHEDIT oEdit TEXT "Hello, world !"  SIZE 200,30

   hwg_Re_setcharformat( oEdit:handle, { { 1,6,,,,.T. }, { 8,13,255,,,,,.T. } } )
#else
     @ 20,10 EDITBOX oEdit CAPTION "Hello, world !"  SIZE 200,30
#endif

#ifdef __GTK__
   @ 470,10 COMBOBOX oCombo ITEMS aCombo SIZE 100, 150 TOOLTIP "Combobox"
#else
   @ 270,10 COMBOBOX oCombo ITEMS aCombo SIZE 100, 150 TOOLTIP "Combobox"
#endif

   @ 20,50 LINE LENGTH 100

#ifndef __GTK__
   @ 20,60 TAB oTab ITEMS aTabs SIZE 140,100      ;
         STYLE TCS_FIXEDWIDTH+TCS_FORCELABELLEFT  ;
         ON CHANGE {|o,n|ChangeTab(o,oGetTab,n)}
   // @ 20,60 TAB oTab ITEMS aTabs SIZE 90,100 STYLE TCS_FIXEDWIDTH+TCS_VERTICAL+TCS_FORCELABELLEFT+WS_CLIPSIBLINGS  // +TCS_RIGHT

   hwg_Settabsize( oTab:handle,20,20 )

   @ 10,30 RICHEDIT oGetTab TEXT "" OF oTab SIZE 120,60 ;
          STYLE ES_MULTILINE
#else
   @ 20,60 TAB oTab ITEMS aTabs SIZE 340,100      ;
        STYLE TCS_FIXEDWIDTH+TCS_FORCELABELLEFT
#endif

#ifdef __GTK__
   @ 280,15 SAY "" SIZE 70,22 STYLE WS_BORDER BACKCOLOR 12507070
#else
   @ 180,60 SAY "" SIZE 70,22 STYLE WS_BORDER BACKCOLOR 12507070
#endif

#ifdef __GTK__
   @ 270,170 TREE oTree SIZE 140,100 EDITABLE
#else
   @ 270,60 TREE oTree SIZE 140,100 EDITABLE
#endif

   oTree:AddNode( "First" )
   oTree:AddNode( "Second" )
   oItem := oTree:AddNode( "Third" )
   oItem:AddNode( "Third-1" )
   oTree:AddNode( "Forth" )

#ifdef __GTK__
   @ 250,300 BUTTON "Close"  SIZE 150,30  ON CLICK {||hwg_EndWindow()} ON SIZE ANCHOR_BOTTOMABS
#else
   @ 100,180 BUTTON "Close"  SIZE 150,30  ON CLICK {||hwg_EndWindow()} ON SIZE ANCHOR_BOTTOMABS
#endif

   MENU OF oMainWindow
      MENU TITLE "File"
#ifndef __GTK__
           MENUITEM "Property sheet" ACTION ( hwg_MsgStop("The feature Property sheet is buggy yet ! " ;
           + CHR(10) + "We will fix as soon as possible","Sorry" ) )
//         MENUITEM "Property sheet" ACTION Ps1(oMainWindow)  && old: Ps
#endif
         SEPARATOR
         MENUITEM "YYYYY" ACTION hwg_MsgGet( "Example","Input anything")
      ENDMENU
      MENU TITLE "Help"
         MENUITEM "About" ACTION hwg_Msginfo("About")
#ifndef __GTK__
         MENUITEM "Info" ACTION hwg_Msgtemp("")
#endif
      ENDMENU
      MENU TITLE "Third"
         MENUITEM "Wchoice" ACTION hwg_WChoice( acho,"Select",,,,,15132390,,hwg_ColorC2N( "008000" ) )
         MENUITEM "hwg_Selectfolder" ACTION hwg_Msginfo( hwg_Selectfolder("!!!") )
         MENU TITLE "Submenu"

            MENUITEM "hwg_RunApp" ACTION (hwg_RunApp(cExecprg))
            MENUITEM "hwg_Shellexecute" ACTION SHELL_EXEC()

            MENUITEM "S2" ACTION hwg_Msgstop("S2")
         ENDMENU
      ENDMENU
   ENDMENU

/*
   aMenu := { ;
     { { { {||hwg_Msginfo("Xxxx")},"XXXXX",130 }, ;
         { ,,131 }, ;
         { {||hwg_Msginfo("Yyyy")},"YYYYY",132 } ;
       },"File",120 }, ;
     { {||hwg_Msginfo("Help")},"Help",121 } ;
   }
   hwg_BuildMenu( aMenu,hWnd,aMainWindow )
*/

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

FUNCTION SHELL_EXEC()

   LOCAL hinst

   hwg_MsgStop("hwg_Shellexecute() does not work at this time" + ;
      CHR(10) + "We will fix as soon as possible","Sorry")

   hinst := hwg_Shellexecute("Sample.txt")    && ,"open",NIL,NIL,2))
   *  ,hwg_Msginfo(str(oMainWindow:handle))
   *  ==> handles can not be converted by STR() (crashes)
   * hwg_Shellexecute() fails, use hwg_RunApp() for starting external apps.
   *  Call of "d:\temp\podst.doc" makes no sense.
   *
   * Display the return code of hwg_Shellexecute(),
   * values less then 33 represent error codes.

   hwg_MsgInfo(STR(hinst))

RETURN Nil

#ifndef __GTK__
STATIC FUNCTION ChangeTab( oWnd,oGet,n )

   STATIC lastTab := 1

   aGetsTab[lastTab] := hwg_Getedittext( oGet:oParent:handle,oGet:id )
   hwg_Setdlgitemtext( oGet:oParent:handle,oGet:id,aGetsTab[n] )
   lastTab := n

   (oWnd) // -w3 -es2

RETURN Nil
#endif

#ifndef __GTK__
FUNCTION PS1( oWnd )

   LOCAL oDlg1, oDlg2

   INIT DIALOG oDlg1 TITLE "PAGE_1" STYLE WS_CHILD + WS_VISIBLE + WS_BORDER
   @ 20,15 EDITBOX "" SIZE 160, 26 STYLE WS_BORDER
   @ 10,50 LINE  LENGTH 200

   INIT DIALOG oDlg2 TITLE "PAGE_2" STYLE WS_CHILD + WS_VISIBLE + WS_BORDER
   @ 20,35 EDITBOX "" SIZE 160, 26 STYLE WS_BORDER

   hwg_MsgIsNIL(hwg_Getactivewindow() )

   hwg_PropertySheet( hwg_Getactivewindow(), { oDlg1, oDlg2 }, "Sheet Example",210,10,300,300 )

   (oWnd) // -w3 -es2

RETURN Nil
#endif

* ================================== EOF of hello.prg ======================================

