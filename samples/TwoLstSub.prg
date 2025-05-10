/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  TwoLstSub.prg
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

FUNCTION Main()

   LOCAL oMainWindow
   LOCAL aResult

   aResult := {}

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "Example" ;
      AT 0,0 ;
      SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   // MENUITEM in main menu on GTK/Linux does not start the desired action
   // Submenu needed
   MENU OF oMainWindow
      MENU TITLE "&Exit"
        MENUITEM "&Quit" ACTION oMainWindow:Close()
      ENDMENU
      MENU TITLE "&Teste"
        MENUITEM "&Do it" ACTION { || aResult := Teste() }
      ENDMENU
      MENU TITLE "&Show Result"
        MENUITEM "&Show" ACTION ShowR( aResult )
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

FUNCTION ShowR( ar, bdebug )

   * Show the contents of the result array
   * or for debugging purpose
   * --------------------------------------------

   LOCAL j, co , d , t

   d := .F.
   IF bdebug <> NIL
      d := bdebug
   ENDIF
   IF d
      t := "Debug"
   ELSE
      t := "Result Array"
   ENDIF
   co := ""
   IF LEN(ar) < 1
      hwg_msgInfo( "Result is empty", t )
      RETURN NIL
   ENDIF
   FOR j := 1 TO LEN( ar )
     co := co + ar[ j ] + CHR(10)
   NEXT
   hwg_msgInfo( co, t )

RETURN Nil

FUNCTION Teste()

   * Main dialog for moving items beetween
   * two browsboxes
   * --------------------------------------------

   LOCAL _frm_2browsboxsel

   LOCAL oLabel1, obrowsbox1, obrowsbox2, oButton1, oButton2, oButton3, oButton4, oButton5
   LOCAL oButton6, oButton7, oFont, oItemsR
   LOCAL oItems1, oItems2

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
   PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12 && vorher 13
#endif

   * items
   oItems1 := GetItems()
   oItems2 := {}
   (oItems1);(oItems2) // -w3 -es2

   * return Value
   oItemsR := {}

   INIT DIALOG _frm_2browsboxsel ;
      TITLE "Select Browsebox Items" ;
      AT    536, 148 ;
      SIZE  516, 465 ;
      FONT  oFont;
      STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE

   @ 33,15 SAY oLabel1 CAPTION "Select items"  SIZE 441,22 ;
        STYLE SS_CENTER

   // Please dimensionize size of both BROWSE windows so that it is enough space to display
   // all items in oItems1 with additional reserve about 20 pixels.
   @ 34,56  BROWSE obrowsbox1  ;
      ARRAY oItems1 ;
      SIZE  150,96 ;
      FONT  oFont  ;
      STYLE WS_BORDER  // NO VSCROLL

   @ 308,56 BROWSE obrowsbox2  ;
      ARRAY oItems2 ;
      SIZE  150,96 ;
      FONT  oFont  ;
      STYLE WS_BORDER // NO VSCROLL

   // Init Browse windows
   obrowsbox1:aArray := GetItems() // Fill source browse box with all items
   obrowsbox2:aArray := {}
   obrowsbox1:AddColumn( HColumn():New( "Source",{|v,o| (v), o:aArray[ o:nCurrent, 1 ] }, "C", 10, 0 ) )
   obrowsbox2:AddColumn( HColumn():New( "Target",{|v,o| (v), o:aArray[ o:nCurrent, 1 ] }, "C", 10, 0 ) )
   obrowsbox1:lEditable := .F.
   obrowsbox2:lEditable := .F.
   obrowsbox1:lDispHead := .F. // No Header
   obrowsbox2:lDispHead := .F.
   obrowsbox1:active := .T.
   obrowsbox2:active := .T.

   @ 207,92 BUTTON oButton1 CAPTION ">" ;
      SIZE     80,32 ;
      STYLE    WS_TABSTOP+BS_FLAT ;
      ON CLICK { || browsBOX_ITEMTORI( obrowsbox1, obrowsbox2 ) }

   @ 207,137 BUTTON oButton2 ;
      CAPTION  ">>" ;
      SIZE     80, 32 ;
      STYLE    WS_TABSTOP + BS_FLAT ;
      ON CLICK { || browsBOX_ITEMTORA( obrowsbox1, obrowsbox2, GetItems() ) }

   @ 207,223 BUTTON oButton3 ;
      CAPTION  "<"   ;
      SIZE     80,32 ;
      STYLE    WS_TABSTOP + BS_FLAT ;
      ON CLICK { || browsBOX_ITEMTOLI( obrowsbox1, obrowsbox2 ) }

   @ 207,281 BUTTON oButton4 ;
      CAPTION  "<<"   ;
      SIZE     80, 32 ;
      STYLE    WS_TABSTOP + BS_FLAT ;
      ON CLICK { || browsBOX_ITEMTOLA( obrowsbox1, obrowsbox2, GetItems() ) }

   @ 36,345 BUTTON oButton5 ;
      CAPTION "OK"   ;
      SIZE    80,32 ;
      STYLE   WS_TABSTOP + BS_FLAT ;
      ON CLICK ;
         { || oItemsR := obrowsbox2:aArray , _frm_2browsboxsel:Close() }  /* return content of target browsbox */

   @ 158,345 BUTTON oButton6 ;
      CAPTION   "Cancel"   ;
      SIZE      80, 32 ;
      STYLE     WS_TABSTOP + BS_FLAT ;
      ON CLICK { || _frm_2browsboxsel:Close() }

   @ 367,345 BUTTON oButton7 ;
      CAPTION  "Help"   ;
      SIZE     80, 32 ;
      STYLE    WS_TABSTOP + BS_FLAT ;
      ON CLICK { || Hilfe() }

   ACTIVATE DIALOG _frm_2browsboxsel CENTER
   * Returns thze array with results.
   * Empty array, if pressed "Cancel" Button

RETURN browsBOX_procarray( oItemsR )

STATIC FUNCTION GetItems()

   * This function is a solution of a strange behavior:
   * browsBOX_ITEMTORA(obrowsbox1,obrowsbox2,oItems1)
   * Parameter oItems1 left the items moved by browsBOX_ITEMTORI()
   * (seems to be only a pointer to oItems1)
   * Is overwritten, but should be fixed.
   * This works:
   * browsBOX_ITEMTORA(obrowsbox1,obrowsbox2,GetItems() )
   * --------------------------------------------

RETURN { { "Eins" },{ "Zwei" },{ "Drei" },{ "Vier" } }

FUNCTION browsBOX_procarray( aEin )

   * Reduces the 2 dimensional array of
   * BROWSE classs to one dimension.
   * Is only valid for this case, because the
   * BROWSE list contains only one column.
   * --------------------------------------------

   LOCAL iii, aret, cret

   aret := {}
   FOR iii := 1 TO LEN( aEin )
      cret := aEin[ iii , 1 ]
      AADD( aret, cret )
   NEXT

RETURN aret

FUNCTION browsBOX_ITEMTORI( obrows1, obrows2 )

   * moves selected item to target browse box
   * --------------------------------------------

   LOCAL nPosi, cIt , aIt

   * Source browse box empty: nothing to do
   IF Empty( obrows1:aArray )
      RETURN NIL
   ENDIF
   * Get selected item
   nPosi := obrows1:nCurrent
   cIt   := obrows1:aArray[ nPosi, 1 ]
   aIt   := { cIt }
   * Search item in target browse box, if found, nothing to do (programing error)
   IF browsBOX_ITEMFIND( obrows2, cIt ) <> 0
      RETURN NIL
   ENDIF
   // dbg(obrows2)
   * delete item in source browse box
   browsBOX_DelItem( obrows1, nPosi )
   * add item in target browse box
   AADD( obrows2:aArray, aIt )
   * refresh both
   obrows1:Refresh()
   obrows2:Refresh()

RETURN Nil

FUNCTION browsBOX_DelItem( obrw, nPosi )

   * Deletes an item in browse array
   * --------------------------------------------

   ADEL( obrw:aArray, nPosi )
   ASize( obrw:aArray, Len( obrw:aArray ) - 1 )
   obrw:lChanged := .T.

RETURN Nil

FUNCTION browsBOX_ITEMTOLI( obrows1, obrows2 )

   * moves selected item to source browsbox
   * --------------------------------------------

   LOCAL nPosi, cIt, aIt

   IF Empty( obrows2:aArray )
      RETURN Nil
   ENDIF
   nPosi := obrows2:nCurrent
   cIt   := obrows2:aArray[ nPosi, 1 ]
   aIt := { cIt }
   IF browsBOX_ITEMFIND( obrows1, cIt ) <> 0
      RETURN NIL
   ENDIF
   browsBOX_DelItem( obrows2, nPosi )
   AADD(obrows1:aArray, aIt )
   * refresh both
   obrows2:Refresh()
   obrows1:Refresh()

RETURN Nil

FUNCTION browsBOX_ITEMTORA( obrows1, obrows2, oIto )

   * moves all items to target browsbox
   * --------------------------------------------
   // Clear both browse boxes
   obrows1:aArray := {}
   obrows2:aArray := {}
   // Init target with all items
   obrows2:aArray := oIto
   obrows1:Refresh()
   obrows2:Refresh()

RETURN Nil

FUNCTION browsBOX_ITEMTOLA( obrows1, obrows2, oIto )

   * moves all items to source browsbox
   * --------------------------------------------
   obrows1:aArray := {}
   obrows2:aArray := {}
   obrows1:aArray := oIto
   obrows1:Refresh()
   obrows2:Refresh()

RETURN Nil

FUNCTION browsBOX_ITEMFIND( obrows, cItem )

   * searches the item cItem (String value) in
   * browsbox obrows and returns their position.
   * returns 0, if no match.

   LOCAL i

   //    hwg_msgInfo(STR( LEN(obrows:aArray)  ) )
   FOR i := 1 TO LEN( obrows:aArray )
      IF AllTrim( obrows:aArray[ i, 1 ] ) == ALLTRIM( cItem )
         RETURN i
      ENDIF
   NEXT

RETURN 0

FUNCTION Hilfe()

   * Display help window

   hwg_MsgInfo( "Need Help", "HELP !" )

RETURN Nil

FUNCTION dbg( obr )

   * Debug output
   * --------------------------------------------

   LOCAL i,m,s

   m := Len( obr:aArray )
   s := AllTrim( Str( m ) ) + CHR(10)
   FOR i := 1 TO m
      s:=  s + obr:aArray[ i, 1 ] + CHR(10)
   NEXT
   IF m == 0
      s := s + "Empty Array"
   ENDIF
   hwg_MsgInfo( s, "Debug" )

RETURN Nil

* ============== EOF of TwoLstSub.prg =================
