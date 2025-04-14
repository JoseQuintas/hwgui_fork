/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  TwoListbox.prg
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
#ifdef __GTK__
#include "gtk.ch"
#endif
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

MEMVAR  oItems1w, oItems2w

FUNCTION Main()

   LOCAL oMainWindow
   LOCAL aResult

   aResult := {}

   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
     AT 0,0 SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION oMainWindow:Close()
      MENUITEM "&Teste" ACTION { || aResult := Teste() }
      MENUITEM "&Show Result" ACTION ShowR(aResult)
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

FUNCTION ShowR( ar, bdebug )

   * Show the contents of the result array
   * or for debugging purpose

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
      hwg_msgInfo("Result is empty",t)
      RETURN NIL
   ENDIF
   FOR j := 1 TO LEN(ar)
      co := co + ar[j] + CHR(10)
   NEXT
   hwg_msgInfo(co,t)

RETURN Nil

FUNCTION Teste()

   * Main dialog for moving items beetween
   * two listboxes

   LOCAL _frm_2listboxsel

   LOCAL oLabel1, oListbox1, oListbox2, oButton1, oButton2, oButton3, oButton4 , oButton5
   LOCAL oButton6, oButton7, oFont, oItemsR
   LOCAL oItems1, oItems2
   PRIVATE  oItems1w, oItems2w

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13

   * items
   oItems1 := GetItems()
   oItems2 := {}

   * return Value
   oItemsR := {}

  INIT DIALOG _frm_2listboxsel TITLE "Select Listbox Items" ;
     AT 536,148 SIZE 516,465 FONT oFont;
     STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE

   @ 33,15 SAY oLabel1 CAPTION "Select items"  SIZE 441,22 ;
        STYLE SS_CENTER

   // Please dimensionize size of both listboxes so that it is enough space to display
   // all items in oItems1 with additional reserve about 20 pixels.
   @ 34,56  LISTBOX oListbox1  ITEMS oItems1 INIT 1 SIZE 150,96
   @ 308,56 LISTBOX oListbox2  ITEMS oItems2 SIZE 150,96


   @ 207,92 BUTTON oButton1 CAPTION ">"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || LSTBOX_ITEMTORI(oListbox1,oListbox2) }
   @ 207,137 BUTTON oButton2 CAPTION ">>"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || LSTBOX_ITEMTORA(oListbox1,oListbox2,GetItems() ) }
   @ 207,223 BUTTON oButton3 CAPTION "<"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || LSTBOX_ITEMTOLI(oListbox1,oListbox2) }
   @ 207,281 BUTTON oButton4 CAPTION "<<"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || LSTBOX_ITEMTOLA(oListbox1,oListbox2,GetItems() ) }
   @ 36,345 BUTTON oButton5 CAPTION "OK"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK ;
         { || oItemsR := oListbox2:aItems , _frm_2listboxsel:Close() }  /* return content of target listbox */
   @ 158,345 BUTTON oButton6 CAPTION "Cancel"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || _frm_2listboxsel:Close() }
   @ 367,345 BUTTON oButton7 CAPTION "Help"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || Hilfe() }

   ACTIVATE DIALOG _frm_2listboxsel
   * Returns thze array with results.
   * Empty array, if pressed "Cancel" Button

RETURN oItemsR

STATIC FUNCTION GetItems()

   * This function is a solution of a strange behavior:
   * LSTBOX_ITEMTORA(oListbox1,oListbox2,oItems1)
   * Parameter oItems1 left the items moved by LSTBOX_ITEMTORI()
   * (seems to be only a pointer to oItems1)
   * Is overwritten, but should be fixed.
   * This works:
   * LSTBOX_ITEMTORA(oListbox1,oListbox2,GetItems() )
   * --------------------------------------------

RETURN {"Eins","Zwei","Drei","Vier"}

FUNCTION LSTBOX_ITEMTORI( olst1, olst2 )

   * moves selected item to target listbox

   LOCAL nPosi, cIt , nNeu

   * Source listbox empty: nothing to do
   IF EMPTY(olst1:aItems)
      RETURN NIL
   ENDIF
   * Get selected item
   nPosi := olst1:value
   cIt   := olst1:aItems[nPosi]
   * Search item in target listbox, if found, nothing to do (programing error)
   IF LSTBOX_ITEMFIND(olst2,cIt) <> 0
      RETURN NIL
   ENDIF
   * delete in source listbox
   olst1:DeleteItem( nPosi )
   * add in target listbox
   olst2:AddItems(cIt)
   * refresh both
   olst1:Requery()
   olst2:Requery()
   nNeu := LEN(olst2:aItems)
   olst2:SetItem(nNeu)
   olst1:SetItem(1)

RETURN Nil

FUNCTION LSTBOX_ITEMTOLI( olst1, olst2 )

   * moves selected item to source listbox

   LOCAL nPosi, cIt , nNeu

   IF EMPTY(olst2:aItems)
      RETURN NIL
   ENDIF
   nPosi := olst2:value
   cIt   := olst2:aItems[nPosi]
   IF LSTBOX_ITEMFIND(olst1,cIt) <> 0
      RETURN NIL
   ENDIF
   olst2:DeleteItem( nPosi )
   olst1:AddItems(cIt)
   * refresh both
   olst2:Requery()
   olst1:Requery()
   nNeu := LEN(olst1:aItems)
   olst1:SetItem(nNeu)
   olst2:SetItem(1)

RETURN NIL

FUNCTION LSTBOX_ITEMTORA( olst1, olst2, oIto )

   * moves all items to target listbox

   olst1:Clear()
   olst2:Clear()
   olst2:aItems := oIto
   olst2:value := 1
   olst1:Requery()
   olst2:Requery()
   olst2:SetItem(1)

RETURN Nil

FUNCTION LSTBOX_ITEMTOLA( olst1, olst2, oIto )

   * moves all items to source listbox

   olst1:Clear()
   olst2:Clear()
   olst1:aItems := oIto
   olst1:value := 1
   olst1:Requery()
   olst2:Requery()
   olst1:SetItem(1)

RETURN Nil


FUNCTION LSTBOX_ITEMFIND( olst, cItem )

   * searches the item cItem (String value) in
   * listbox olst and returns their position.
   * returns 0, if no match.

   LOCAL i

   FOR i := 1 TO LEN(olst:aItems)
      IF ALLTRIM(olst:aItems[i]) == ALLTRIM(cItem)
         RETURN i
      ENDIF
   NEXT

RETURN 0

FUNCTION Hilfe()

   * Display help window

   hwg_MsgInfo("Need Help","HELP !")

RETURN Nil

* ============== EOF of TwoListbox.prg =================
