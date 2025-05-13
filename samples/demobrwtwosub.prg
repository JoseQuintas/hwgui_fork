/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  demobrwtwosub.prg
 *
 * Sample for select and move items between two browse windows,
 * a source and a target box.
 * This sample is a good substitute for TwoListbox.prg,
 * because listbox is at the moment Windows only.
 *
 * Copyright 2020 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes
    * Port of Listbox to GTK under construction

*  Modification documentation
*
*  +------------+-------------------------+----------------------------------+
*  + Date       ! Name and Call           ! Modification                     !
*  +------------+-------------------------+----------------------------------+
*  ! 10.12.2024 ! W.Brunken        DF7BE  ! Bugfix compile GTK               !
*  +------------+-------------------------+----------------------------------+
*  ! 27.04.2020 ! W.Brunken        DF7BE  ! first creation                   !
*  +------------+-------------------------+----------------------------------+
*

#include "hwgui.ch"
// #include "common.ch"
// #ifdef __XHARBOUR__
//    #include "ttable.ch"
// #endif

FUNCTION DemoBrwtwoSub( lWithDialog, oDlg )

   LOCAL aControls := Array(10)
   LOCAL oBrowseSource, oBrowseTarget, oFont
   LOCAL aListSource, aListTarget := {}
   LOCAL aListFull := { { "Eins" }, { "Zwei" }, { "Drei" }, { "Vier" } }

   hb_Default( @lWithDialog, .T. )

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
   PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12 && vorher 13
#endif

   aListSource := AClone( aListFull )

   (aListSource);(aListTarget) // warning -w3 -es2

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demobrwtwosub.prg - Select Browsebox Items" ;
         AT    0, 0 ;
         SIZE  800, 600 ;
         FONT  oFont;
         STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE
   ENDIF

   ButtonForSample( "demobrwtwosub.prg", oDlg )

   // Please dimensionize size of both BROWSE windows so that it is enough space to display
   // all items in oItems1 with additional reserve about 20 pixels.
   @ 34, 106  BROWSE oBrowseSource  ;
      ARRAY ;
      SIZE  150,96 ;
      FONT  oFont  ;
      STYLE WS_BORDER  // NO VSCROLL

   oBrowseSource:aArray := aListSource
   oBrowseSource:AddColumn( HColumn():New( "Source", { |v,o| (v), o:aArray[ o:nCurrent, 1 ] }, "C", 10, 0 ) )
   oBrowseSource:lEditable := .F.
   oBrowseSource:lDispHead := .F. // No Header
   oBrowseSource:active := .T.

   @ 308, 106 BROWSE oBrowseTarget  ;
      ARRAY ;
      SIZE  150,96 ;
      FONT  oFont  ;
      STYLE WS_BORDER // NO VSCROLL

   oBrowseTarget:aArray := aListTarget
   oBrowseTarget:AddColumn( HColumn():New( "Target",{|v,o| (v), o:aArray[ o:nCurrent, 1 ] }, "C", 10, 0 ) )
   oBrowseTarget:lEditable := .F.
   oBrowseTarget:lDispHead := .F.
   oBrowseTarget:active := .T.

   @ 207, 102 BUTTON aControls[1] CAPTION ">" ;
      SIZE     80,32 ;
      STYLE    WS_TABSTOP+BS_FLAT ;
      ON CLICK { || ItemToBrowse( oBrowseSource, oBrowseTarget ) }

   @ 207, 147 BUTTON aControls[2] CAPTION  ">>" ;
      SIZE     80, 32 ;
      STYLE    WS_TABSTOP + BS_FLAT ;
      ON CLICK { || AllToBrowse( oBrowseSource, oBrowseTarget ) }

   @ 207, 233 BUTTON aControls[3] CAPTION  "<"   ;
      SIZE     80,32 ;
      STYLE    WS_TABSTOP + BS_FLAT ;
      ON CLICK { || ItemToBrowse( oBrowseTarget, oBrowseSource ) }

   @ 207, 291 BUTTON aControls[4] CAPTION  "<<"   ;
      SIZE     80, 32 ;
      STYLE    WS_TABSTOP + BS_FLAT ;
      ON CLICK { || AllToBrowse( oBrowseTarget, oBrowseSource ) }

   @ 36, 355 BUTTON aControls[5] CAPTION "Show"   ;
      SIZE    80,32 ;
      STYLE   WS_TABSTOP + BS_FLAT ;
      ON CLICK ;
         { || hwg_MsgInfo( hb_ValToExp( oBrowseTarget:aArray ) ) }

   @ 158, 355 BUTTON aControls[6] CAPTION   "Reset"   ;
      SIZE      80, 32 ;
      STYLE     WS_TABSTOP + BS_FLAT ;
      ON CLICK { || ResetBrowse( oBrowseSource, oBrowseTarget, aListFull ) }

   @ 367, 355 BUTTON aControls[7] CAPTION  "Help"   ;
      SIZE     80, 32 ;
      STYLE    WS_TABSTOP + BS_FLAT ;
      ON CLICK { ||
         hwg_MsgInfo( "No help" )
         RETURN Nil
         }

   @ 33, 400 SAY aControls[9] CAPTION "Select items"  ;
      SIZE 441,22 ;
      STYLE SS_CENTER

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

STATIC FUNCTION ItemToBrowse( oBrowseSource, oBrowseTarget )

   IF Empty( oBrowseSource:aArray )
      RETURN Nil
   ENDIF
   AAdd( oBrowseTarget:aArray, AClone( oBrowseSource:aArray[ oBrowseSource:nCurrent ] ) )
   hb_ADel( oBrowseSource:aArray, oBrowseSource:nCurrent, .T. )
   oBrowseSource:Refresh()
   oBrowseTarget:Refresh()
   RETURN Nil

STATIC FUNCTION AllToBrowse( oBrowseSource, oBrowseTarget )

   LOCAL aItem

   FOR EACH aItem IN oBrowseSource:aArray
      AAdd( oBrowseTarget:aArray, AClone( aItem ) )
   NEXT
   oBrowseSource:aArray := {} // reference?
   oBrowseSource:Refresh()
   oBrowseTarget:Refresh()

   RETURN Nil

STATIC FUNCTION ResetBrowse( oBrowseSource, oBrowseTarget, aListFull )

   oBrowseSource:aArray := AClone( aListFull )
   oBrowseTarget:aArray:= {} // reference?
   oBrowseSource:Refresh()
   oBrowseTarget:Refresh()
   RETURN Nil

#include "demo.ch"

* ============== EOF of demobrwtwosub.prg =================
