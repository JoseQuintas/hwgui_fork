/*
 * $Id$
 *
 * Sample for modifying a main window title in HWGUI
 * ( Harbour + HWGUI )
 *
 * Main file
 *
 * Copyright 2019 DF7BE
 * www - http://www.z02.de
 *
 * Status:
 *  WinAPI   :  Yes
 *  GTK/Linux:  Yes
 *  GTK/Win  :  Yes
*/

/* === includes === */
// #include "hwgui.ch"

#include "hwgui.ch"

MEMVAR oWndMain

FUNCTION Main()

//   LOCAL  oFont

   PRIVATE oWndMain

#ifndef __GTK__
   hwg_Settooltipballoon(.t.)
#endif
*   Parameter            Font Name,Breite,Hoehe
   //oFont := HFont():Add( "Courier", 0, -14 )

   INIT WINDOW oWndMain ;
      MAIN ;
      TITLE "Default title"  ;
      AT 200,100 ;
      SIZE 500,500 ;
      ON EXIT { || hwg_MsgYesNo("OK to quit ?" ) }

   MENU OF oWndMain
      MENU TITLE "&File"
         MENUITEM "&Quit" ACTION oWndMain:Close()
      ENDMENU
      MENU TITLE "&Titles"
         MENUITEM "&Date sorted title"  ACTION Titel1()
         MENUITEM "&Name sorted title"  ACTION Titel2()
      ENDMENU
   ENDMENU
   ACTIVATE WINDOW oWndMain CENTER

RETURN Nil

/* End of Main */

FUNCTION Titel1()
   // sample for display sort item
   // change order
   * SET ORDER TO 1
   // set new window title here
   oWndMain:SetTitle( "Sorted by date" )
   * oBrw:Refresh() // sample for refreshing a browse window with a new order

RETURN Nil

FUNCTION Titel2()

   // sample for display sort item
   // change order
   * SET ORDER TO 2
   // set new window title here
   oWndMain:SetTitle( "Sorted by name" )
   * oBrw:Refresh() // sample for refreshing a browse window with a new order

RETURN Nil

* ======== EOF of modtitle.prg =============
