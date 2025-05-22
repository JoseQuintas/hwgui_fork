/*
 * $Id: demoSplitter.prg,v 1.2 2005/09/19 16:32:44 lf_sfnet Exp $
 *
 * This sample demonstrates the using of a TREE control
 *
 */

#include "hwgui.ch"
#include "sampleinc.ch"

FUNCTION DemoSplitter( lWithDialog, oDlg, aInitList )

   LOCAL oFont := HFont():Add( "MS Sans Serif",0,-13 )
   LOCAL oTree, oSplit, oTab
   LOCAL oGet, cImage1, cImage2

   cImage1 := SAMPLE_IMAGEPATH + "cl_fl.bmp"
   cImage2 := SAMPLE_IMAGEPATH + "op_fl.bmp"

   hb_Default( @lWithDialog, .T. )

   IF ! File( cImage1 ) .OR. ! File( cImage2 )
      hwg_MsgInfo( "demosplitter.prg" + hb_Eol() + ;
         "file not found" + hb_Eol() + ;
         cImage1 + hb_Eol() + ;
         cImage2 )
      RETURN Nil
   ENDIF
   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demosplitter.prg - splitter and treeview" ;
         AT 200, 0 ;
         SIZE 600, 400 ;
         FONT oFont ;
         ON INIT { || BuildTree( oDlg, oTree, oTab ) }
   ELSE
      AADD( aInitList, { || BuildTree( oDlg, oTree, oTab ) } )
   ENDIF

// on demo.ch
   ButtonForSample( "demosplitter.prg", oDlg )

   @ 10, 60 TREE oTree ;
      OF oDlg ;
      SIZE 200, 280 ;
      EDITABLE ;
      BITMAP { cImage1, cImage2 }  ;
      ON SIZE { | o, x, y | (x), o:Move( ,,, y - 20 ) }

   @ 214, 60 EDITBOX oGet ;
      CAPTION "Command" ;
      SIZE 106, 20 ;
      COLOR hwg_ColorC2N( "FF0000" ) ;
      ON SIZE { | o, x, y | (y), o:Move(,, x-oSplit:nLeft - oSplit:nWidth - 50 ) }

   @ 214, 85 TAB oTab ;
      ITEMS {} ;
      SIZE 206, 280 ;
      ON SIZE { | o, x, y | o:Move( ,, x-oSplit:nLeft - oSplit:nWidth - 10, y - 20 ) } ;
      ON CHANGE { | o | hwg_Msginfo( str( len( o:aPages ) ) ) }

   @ 414, 60 BUTTON "X" ;
      SIZE 24, 24 ;
      ON CLICK { | nPos | ;
         nPos := oTab:GetActivePage(), ;
         hwg_MsgInfo( iif( nPos == 0, "No Page To Delete", "Delete " + Str( nPos ) ) ), ;
         iif( nPos == 0, Nil, oTab:DeletePage( nPos ) ) } ;
      ON SIZE { | o, x, y | (x), (y), o:Move( oTab:nLeft + oTab:nWidth - 26 ) } ;

   @ 210, 60 SPLITTER oSplit ;
      SIZE 4, 260 ;
      DIVIDE { oTree } FROM { oTab, oGet } ;
      ON SIZE { | o, x, y | (x), o:Move(,,, y - 20 ) }

   oSplit:bEndDrag := { || hwg_Redrawwindow( oTab:handle, ;
      RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW ) }

   //BuildTree( oDlg, oTree,oTab )

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      oFont:Release()
   ENDIF

RETURN Nil

STATIC FUNCTION BuildTree( oDlg, oTree, oTab )

   LOCAL oNode

   INSERT NODE "First" TO oTree ON CLICK { || NodeOut( 1, oTab ) }
   INSERT NODE "Second" TO oTree ON CLICK { || NodeOut( 2, oTab ) }
   INSERT NODE oNode CAPTION "Third" TO oTree ON CLICK { || NodeOut( 0, oTab ) }
      INSERT NODE "Third-1" TO oNode BITMAP { SAMPLE_IMAGEPATH + "book.bmp" } ON CLICK { || NodeOut( 3, oTab ) }
      INSERT NODE "Third-2" TO oNode BITMAP { SAMPLE_IMAGEPATH + "book.bmp" } ON CLICK { || NodeOut( 4, oTab ) }
   INSERT NODE "Forth" TO oTree ON CLICK { || NodeOut( 5, oTab ) }

   oTree:bExpand := { || .T. }

   (oDlg) // warning -w3 -es2

RETURN Nil

STATIC FUNCTION NodeOut( n, oTab )

   LOCAL cTitle := "Page " + str( len( oTab:aPages ) + 1 )

   oTab:StartPage( cTitle )

   cTitle := "Pages " + str( len( oTab:aPages ) )

   @ 30, 60 SAY cTitle SIZE 100, 26

   oTab:EndPage()

   (n) // warning -w3 -es2

RETURN Nil

// show buttons and source code
#include "demo.ch"
