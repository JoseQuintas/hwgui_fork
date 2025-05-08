/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  demolistboxsub.prg
 *
 * Sample for substite of listbox usage:
 * Use BROWSE of an array instead for
 * multi platform use.
 *
 * Copyright 2020 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 * Copied from sample "demolistbox.prg".
 */

   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

#include "hwgui.ch"

FUNCTION DemoListboxsub( lWithDialog, oDlg )

   LOCAL oFont, oBrowse
   LOCAL oList, aBrowseList := { { "Item01" } , { "Item02" } , { "Item03" } , { "Item04" } }
   // Array aBrowseList is a 2 dimensional array with one "column".

   hb_Default( @lWithDialog, .T. )

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
   PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12 && vorher 13
#endif

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demolistboxsub.prg - listbox substitute for any platform" ;
         AT 0,0  ;
         SIZE 500, 350 ;
         FONT oFont
   ENDIF

   ButtonForSample( "demolistboxsub.prg", oDlg )

   // Please dimensionize size of BROWSE window so that it is enough space to display
   // all items in oItemso with additional reserve about 20 pixels.
   @ 34, 100  BROWSE oBrowse  ;
      ARRAY oList ;
      SIZE 210, 220 ;
      FONT oFont  ;
      STYLE WS_BORDER  // NO VSCROLL

   oBrowse:aArray := Aclone( aBrowseList )
   oBrowse:AddColumn( HColumn():New( "Listbox", { | v, o | (v), o:aArray[ o:nCurrent, 1 ]}, "C", 10, 0 ) )
   oBrowse:lEditable := .F.
   oBrowse:lDispHead := .F. // No Header
   oBrowse:active := .T.

   @  300, 100 BUTTON "Show Values" ;
      ; // ID IDOK ; // crash on Windows
      SIZE 150, 32 ;
      ON CLICK { || ShowValues( oBrowse ) }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER

      oFont:Release()
   ENDIF

RETURN Nil

STATIC FUNCTION ShowValues( oBrowse )

   LOCAL nPos, cText

   nPos  := oBrowse:nCurrent
   cText := oBrowse:aArray[ nPos, 1 ]
   hwg_msgInfo( ;
      "Position: " + STR( nPos ) + hb_Eol() + ;
      "Value: " + cText, "Result of Listbox selection" )

   RETURN Nil

#include "demo.ch"

* ==================== EOF of demolistboxsub.prg =========================
