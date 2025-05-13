/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  demolisttwosub.prg
 *
 * Sample for select and move items between two listboxes,
 * a source and a target listbox.
 *
 * Copyright 2020 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No
    * Port of Listbox to GTK under construction

*  Modification documentation
*
*  +------------+-------------------------+----------------------------------+
*  + Date       ! Name and Call           ! Modification                     !
*  +------------+-------------------------+----------------------------------+
*  ! 18.04.2020 ! W.Brunken        DF7BE  ! first creation                   !
*  +------------+-------------------------+----------------------------------+
*

#include "hwgui.ch"
#include "common.ch"
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

FUNCTION DemoListTwoSub( lWithDialog, oDlg )

   LOCAL oFont
   LOCAL oListboxSource, oListboxTarget
   LOCAL aControlList := Array(10)
   LOCAL aListSource, aListTarget
   LOCAL aListFull := { "Eins", "Zwei", "Drei", "Vier" }

   hb_Default( @lWithDialog, .T. )

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13

   aListSource := AClone( aListFull )
   aListTarget := {}

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "Select Listbox Items" ;
         AT 0, 0 ;
         SIZE 800, 600 ;
         FONT oFont;
         STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE
   ENDIF

   ButtonForSample( "demolisttwosub.prg", oDlg )

   // Please dimensionize size of both listboxes so that it is enough space to display
   // all items in aListSource with additional reserve about 20 pixels.
   @ 34, 106  LISTBOX oListboxSource  ;
      ITEMS aListSource ;
      INIT  1 ;
      SIZE  150, 96

   @ 308, 106 LISTBOX oListboxTarget  ;
      ITEMS aListTarget ;
      SIZE  150, 96

   @ 207, 142 BUTTON aControlList[2] ;
      CAPTION  ">"   ;
      SIZE     80, 32 ;
      STYLE    WS_TABSTOP + BS_FLAT ;
      ON CLICK { || ItemToBrowse( oListboxSource, oListboxTarget ) }

   @ 207, 187 BUTTON aControlList[3] ;
      CAPTION  ">>"   ;
      SIZE     80, 32 ;
      STYLE    WS_TABSTOP + BS_FLAT ;
      ON CLICK { || AllToBrowse( oListboxSource, oListboxTarget ) }

   @ 207, 273 BUTTON aControlList[4] ;
      CAPTION  "<"   ;
      SIZE     80, 32 ;
      STYLE    WS_TABSTOP+BS_FLAT ;
      ON CLICK { || ItemToBrowse( oListboxTarget, oListboxSource ) }

   @ 207, 331 BUTTON aControlList[5] ;
      CAPTION "<<"   ;
      SIZE 80, 32 ;
      STYLE WS_TABSTOP+BS_FLAT ;
      ON CLICK { || AllToBrowse( oListboxTarget, oListboxSource ) }

   @ 36, 395 BUTTON aControlList[6] ;
      CAPTION "Show"   ;
      SIZE    80, 32 ;
      STYLE    WS_TABSTOP + BS_FLAT ;
      ON CLICK { || hwg_MsgInfo( hb_ValToExp( oListboxTarget:aItems ) ) }

   @ 158,395 BUTTON aControlList[7] ;
      CAPTION "Reset"   ;
      SIZE 80,32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || ResetBrowse( oListboxSource, oListboxTarget, aListFull ) }

   @ 367, 395 BUTTON aControlList[8] ;
      CAPTION "Help"   ;
      SIZE 80, 32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || hwg_MsgInfo( "No help" ) }

   @ 33, 445 SAY aControlList[1] ;
      CAPTION "Select items"  ;
      SIZE    441, 22 ;
      STYLE   SS_CENTER

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

STATIC FUNCTION ItemToBrowse( oListboxSource, oListboxTarget )

   IF Empty( oListboxSource:aItems )
      RETURN Nil
   ENDIF
   oListboxTarget:AddItems( oListboxSource:aItems[ oListboxSource:Value ] )
   oListboxSource:DeleteItem( oListboxSource:Value )
   oListboxSource:Requery()
   oListboxTarget:Requery()
   oListboxTarget:SetItem( Len( oListboxTarget:aItems ) )
   oListboxSource:SetItem( 1 )

RETURN Nil

STATIC FUNCTION AllToBrowse( oListboxSource, oListboxTarget )

   LOCAL cItem

   IF Empty( oListboxSource:aItems )
      RETURN Nil
   ENDIF

   FOR EACH cItem IN oListboxSource:aItems DESCEND
      oListboxTarget:AddItems( cItem )
   NEXT
   oListboxSource:Clear()
   oListboxSource:Requery()
   oListboxTarget:Requery()
   oListboxTarget:SetItem( Len( oListboxTarget:aItems ) )
   oListboxSource:SetItem( 1 )

RETURN NIL

STATIC FUNCTION ResetBrowse( oListboxSource, oListboxTarget, aListFull )

   LOCAL cItem

   oListboxTarget:Clear()
   oListboxSource:Clear()
   FOR EACH cItem IN aListFull
      oListboxSource:AddItems( cItem )
   NEXT
   oListboxSource:Requery()
   oListboxTarget:Requery()
   oListboxTarget:SetItem( 1 )
   oListboxSource:SetItem( 1 )

RETURN Nil

#include "demo.ch"

* ============== EOF of DemoListTwosub.prg =================
