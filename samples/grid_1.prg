/*
 * $Id: grid_1.prg,v 1.1 2004/04/05 14:16:35 rodrigo_moreno Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGrid class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
*/

#include "hwgui.ch"

STATIC oMain, oForm, oFont, oGrid

FUNCTION Main()

   INIT WINDOW oMain MAIN TITLE "Grid Sample" ;
      AT 0,0 ;
      SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   MENU OF oMain
      MENUITEM "&Exit"      ACTION oMain:Close()
      MENUITEM "&Grid Demo" ACTION Test()
   ENDMENU

   ACTIVATE WINDOW oMain

RETURN Nil

FUNCTION Test()

   PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

   INIT DIALOG oForm CLIPPER NOEXIT TITLE "Grid Demo" ;
      FONT oFont ;
      AT 0, 0 SIZE 700, 425 ;
      STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU

      @ 10,10 GRID oGrid OF oForm SIZE 680,375 ;
         ITEMCOUNT 10000 ;
         ON KEYDOWN { | oCtrl, key| OnKey( oCtrl, key ) } ;
         ON POSCHANGE { | oCtrl, nRow| OnPoschange( oCtrl, nRow ) } ;
         ON CLICK { | oCtrl | OnClick( oCtrl ) } ;
         ON DISPINFO { | oCtrl, nRow, nCol | OnDispInfo( oCtrl, nRow, nCol ) } ;
         COLOR hwg_ColorC2N( "D3D3D3" ) ;
         BACKCOLOR hwg_ColorC2N( "BEBEBE" )

             ADD COLUMN TO GRID oGrid HEADER "Column 1" WIDTH 150
             ADD COLUMN TO GRID oGrid HEADER "Column 2" WIDTH 150
             ADD COLUMN TO GRID oGrid HEADER "Column 3" WIDTH 150

             @ 620, 395 BUTTON "Close" SIZE 75,25 ON CLICK { || oForm:Close() }

        ACTIVATE DIALOG oForm

RETURN Nil

FUNCTION OnKey( o, k )

   //    hwg_Msginfo(str(k))

   (o); (k) // -w3 -es2

RETURN Nil

FUNCTION OnPosChange( o, row )

   //    hwg_Msginfo( str(row) )

   (o); (row) // -w3 -es2

RETURN Nil

FUNCTION OnClick( o )

   //    hwg_Msginfo( "click" )

   (o) // -w3 -es2

RETURN Nil

FUNCTION OnDispInfo( o, x, y )

   (o) // -w3 -es2

RETURN "Row: " + ltrim( str( x ) ) + " Col: " + ltrim( str( y ) )
