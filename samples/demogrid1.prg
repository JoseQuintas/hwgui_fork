/*
 * $Id: demogrid1.prg,v 1.1 2004/04/05 14:16:35 rodrigo_moreno Exp $
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

FUNCTION DemoGrid1( lWithDialog, oDlg )

   LOCAL oFont, oGrid

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

      INIT DIALOG oDlg ;
         CLIPPER ;
         NOEXIT ;
         TITLE "demogrid1.prg - Grid Demo" ;
         FONT oFont ;
         AT 0, 0 ;
         SIZE 720, 480 ;
         STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU
   ENDIF

   ButtonForSample( "demogrid1.prg" )

   @ 50, 100 GRID oGrid OF oDlg SIZE 600, 300 ;
      ITEMCOUNT 1000 ;
      ON KEYDOWN { | oCtrl, key| OnKey( oCtrl, key ) } ;
      ON POSCHANGE { | oCtrl, nRow| OnPoschange( oCtrl, nRow ) } ;
      ON CLICK { | oCtrl | OnClick( oCtrl ) } ;
      ON DISPINFO { | oCtrl, nRow, nCol | OnDispInfo( oCtrl, nRow, nCol ) } ;
      COLOR hwg_ColorC2N( "D3D3D3" ) ;
      BACKCOLOR hwg_ColorC2N( "BEBEBE" )

   ADD COLUMN TO GRID oGrid HEADER "Column 1" WIDTH 150
   ADD COLUMN TO GRID oGrid HEADER "Column 2" WIDTH 150
   ADD COLUMN TO GRID oGrid HEADER "Column 3" WIDTH 150

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

STATIC FUNCTION OnKey( o, k )

   //    hwg_Msginfo(str(k))

   (o); (k) // -w3 -es2

RETURN Nil

STATIC FUNCTION OnPosChange( o, row )

   //    hwg_Msginfo( str(row) )

   (o); (row) // -w3 -es2

RETURN Nil

STATIC FUNCTION OnClick( o )

   //    hwg_Msginfo( "click" )

   (o) // -w3 -es2

RETURN Nil

STATIC FUNCTION OnDispInfo( o, x, y )

   (o) // -w3 -es2

RETURN "Row: " + ltrim( str( x ) ) + " Col: " + ltrim( str( y ) )

#include "demo.ch"
