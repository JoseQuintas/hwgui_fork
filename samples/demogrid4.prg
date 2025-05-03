/*
 * $Id: demogrid4.prg,v 1.1 2004/04/05 14:16:35 rodrigo_moreno Exp $
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

FUNCTION DemoGrid4( lWithDialog, oDlg, aEndList )

   LOCAL oFont, oGrid

   SET EXCLUSIVE OFF
   SET DELETED ON

   hb_Default( @lWithDialog, .T. )
   hb_Default( @aEndList, {} )

   SELECT ( Select( "tmpgrid4" ) )
   USE

   IF ! File( "tmpgrid4.dbf" )
      DBCreate( "tmpgrid4.dbf", {{"LINE", "C", 300, 0}} )
   ENDIF

   USE ( "tmpgrid4" )

   IF lWithDialog
      PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

      INIT DIALOG oDlg ;
         CLIPPER ;
         NOEXIT ;
         TITLE "File Viewer" ;
         FONT oFont ;
         AT 0, 0 ;
         SIZE 720, 480 ;
         STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU
   ENDIF

   ButtonForSample( "demogrid4.prg" )

   @ 10, 100 GRID oGrid ;
      OF oDlg ;
      SIZE 680, 300 ;
      ITEMCOUNT Lastrec() ;
      ON DISPINFO {|oCtrl, nRow, nCol| OnDispInfo( oCtrl, nRow, nCol ) } ;
      NOGRIDLINES

   ADD COLUMN TO GRID oGrid ;
      HEADER "" ;
      WIDTH  800

   @ 10, 420 BUTTON "Open file" ;
      OF oDlg ;
      SIZE 100, 24 ;
      ON CLICK { || FileOpen() }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      CLOSE DATABASES
#ifndef DEMOALL
      FErase( "tmpgrid4.dbf" )
#endif
   ELSE
      AAdd( aEndList, { || fErase( "tmpgrid4.dbf" ) } )
   ENDIF

RETURN Nil

STATIC FUNCTION OnDispInfo( o, x, y )

   LOCAL result

   DBGoto( x )

   result := field->line

   (o); (y) // -w3 -es2

RETURN result

STATIC FUNCTION FileOpen()

   LOCAL fname

   fname := hwg_Selectfile( "Select File", "*.*" )

   // because sample may be running as part of another routine
   // it will be deleted, no problem deleted records
   SELECT tmpgrid4
   DELETE ALL FOR RLock()
   APPEND FROM ( fname ) SDF
RETURN Nil

#include "demo.ch"

* =========================== EOF of demogrid4.prg ============================
