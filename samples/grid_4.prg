/*
 * $Id: grid_4.prg,v 1.1 2004/04/05 14:16:35 rodrigo_moreno Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGrid class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
*/

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No

#include "hwgui.ch"
#include "common.ch"

STATIC oMain, oForm, oFont, oGrid

FUNCTION Main()

   IF File('temp.dbf')
      FErase('temp.dbf')
   END

   DBCreate( "temp.dbf", {{"LINE", "C", 300, 0}} )

   USE temp

   INIT WINDOW oMain MAIN TITLE "File Viewer" ;
      AT 0,0 ;
      SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   MENU OF oMain
      MENU TITLE "&Exit"
         MENUITEM "&Quit" ACTION oMain:Close()
      ENDMENU
      MENU TITLE "&Open"
         MENUITEM "&Open File" ACTION FileOpen()
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMain CENTER

RETURN Nil

FUNCTION Test()

   PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

   INIT DIALOG oForm CLIPPER NOEXIT TITLE "File Viewer" ;
      FONT oFont ;
      AT 0, 0 SIZE 700, 425 ;
      STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU


   @ 10,10 GRID oGrid OF oForm SIZE 680,375;
      ITEMCOUNT Lastrec() ;
      ON DISPINFO {|oCtrl, nRow, nCol| OnDispInfo( oCtrl, nRow, nCol ) } ;
      NOGRIDLINES

   ADD COLUMN TO GRID oGrid HEADER "" WIDTH  800

   @ 620, 395 BUTTON 'Close' SIZE 75,25 ON CLICK { || oForm:Close() }

   ACTIVATE DIALOG oForm

RETURN Nil

FUNCTION OnDispInfo( o, x, y )

   LOCAL result

   DBGoto( x )

   result := field->line

   (o); (y) // -w3 -es2

RETURN result

FUNCTION FileOpen()

   LOCAL fname

   fname := hwg_Selectfile( "Select File", "*.*" )

   ZAP
   APPEND FROM ( fname ) SDF
RETURN Test()

* =========================== EOF of grid_4.prg ============================
