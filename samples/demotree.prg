/*
 * $Id: demotree.prg,v 1.2 2005/09/19 10:00:35 alkresin Exp $
 *
 * This sample demonstrates the using of a TREE control
 *
 */

#include "hwgui.ch"

FUNCTION DemoTree( lWithDialog, oDlg, aInitList )

   LOCAL oFont := HFont():Add( "MS Sans Serif",0,-13 )
   LOCAL oTree, oSplit, oSay, oPopup

   hb_Default( @lWithDialog, .T. )
   hb_Default( @aInitList, {} )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demotree.prg - TreeView control sample"  ;
         AT 210,10  ;
         SIZE 430,300  ;
         FONT oFont ;
         ON INIT { || BuildTree( oDlg, oTree, oSay ) }
   ELSE
      AAdd( aInitList, { || BuildTree( oDlg, oTree, oSay ) } )
   ENDIF

   ButtonForSample( "demotree.prg", oDlg )

   CONTEXT MENU oPopup
      MENUITEM "Add child"  ACTION { || AddNode( oTree,0 ) }
      MENUITEM "Add after"  ACTION { || AddNode( oTree,1 ) }
      MENUITEM "Add before" ACTION { || AddNode( oTree,2 ) }
   ENDMENU

   @ 10, 110 TREE oTree ;
      OF oDlg ;
      SIZE 200,280 ;
      EDITABLE ;
      BITMAP { "..\image\cl_fl.bmp","..\image\op_fl.bmp" } ;
      ON SIZE { | o,x,y | (x), o:Move(,,,y - 20 ) }

   oTree:bRClick := {|ot,on|TreeMenuShow( ot, oPopup, on )}

   @ 214, 110 SAY oSay ;
      CAPTION "" ;
      SIZE    206,280 ;
      STYLE   WS_BORDER ;
      ON SIZE { | o,x,y | (x), o:Move(,,x - oSplit:nLeft - oSplit:nWidth - 10, y - 20 ) }

   @ 210, 110 SPLITTER oSplit ;
      SIZE 4,260 ;
      DIVIDE {oTree} FROM {oSay} ;
      ON SIZE { | o,x,y | (x), o:Move(,,, y - 20 ) }

   oSplit:bEndDrag := {||hwg_Redrawwindow( oSay:handle,RDW_ERASE+RDW_INVALIDATE+RDW_INTERNALPAINT+RDW_UPDATENOW)}

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      oFont:Release()
   ENDIF

RETURN Nil

STATIC FUNCTION BuildTree( oDlg, oTree, oSay )

   LOCAL oNode

   INSERT NODE "First" TO oTree ON CLICK {||NodeOut(1,oSay)}
   INSERT NODE "Second" TO oTree ON CLICK {||NodeOut(2,oSay)}
   INSERT NODE oNode CAPTION "Third" TO oTree ON CLICK {||NodeOut(0,oSay)}
      INSERT NODE "Third-1" TO oNode BITMAP {"..\image\book.bmp"} ON CLICK {||NodeOut(3,oSay)}
      INSERT NODE "Third-2" TO oNode BITMAP {"..\image\book.bmp"} ON CLICK {||NodeOut(4,oSay)}
   INSERT NODE "Forth" TO oTree ON CLICK {||NodeOut(5,oSay)}

   oTree:bExpand := {||.T.}

   (oDlg) // -w3 -es2

RETURN Nil

STATIC FUNCTION NodeOut( n, oSay )

   LOCAL aText := { ;
      "This is a sample application, which demonstrates using of TreeView control in HwGUI.", ;
      "'Second' item is selected", ;
      "'Third-1' item is selected", ;
      "'Third-2' item is selected", ;
      "'Forth' item is selected", ;
               }

   IF n == 0
      oSay:SetText("")
   ELSE
      oSay:SetText(aText[n])
   ENDIF

RETURN Nil

STATIC FUNCTION TreeMenuShow( oTree, oPopup, oNode )

   oTree:Select( oNode )
   oPopup:Show( oTree:oParent )

RETURN Nil

STATIC FUNCTION AddNode( oTree, nType )

   LOCAL cName, oTo

   IF !Empty( cName := hwg_MsgGet( "Node name" ) )
      oTo := Iif( oTree:oSelected:oParent == Nil, oTree, oTree:oSelected:oParent )
      IF nType == 0
         INSERT NODE cName TO oTree:oSelected
      ELSEIF nType == 1
         INSERT NODE cName TO oTo AFTER oTree:oSelected
      ELSE
         INSERT NODE cName TO oTo BEFORE oTree:oSelected
      ENDIF
   ENDIF

RETURN Nil

#include "demo.ch"
