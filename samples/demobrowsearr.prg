/*
 *
 * demobrowsearr.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Sample for HBROWSE class for arrays
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2020 Wilfried Brunken, DF7BE
*/

/*
  More samples for ARRAY BROWSE in
  utils\devtools\memdump.prg

  Because the HBROWSE class for arrays have some bugs,
  so this sample demonstrates a suitable working browse function
  for full editing of arrays (mainly without crash's).
  This sample is for an array with one column of type "C", but
  it could be possible to extend it for more columns with other types.
  For editing features you need buttons for adding, editing and
  deleting lines.
  We will fix the bugs as soon as possible.
  The HBROWSE class for DBF's is very stable.

  Sample for read out the edited array:

  @ 360,410 BUTTON oBtn4 CAPTION "OK " SIZE 80,26 ;
    ON CLICK { | | bCancel := .F. , ;
    aBrowseList := oBrowse:aArray , ;
    hwg_EndDialog() }

*/

   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

#include "hwgui.ch"
#include "common.ch"
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

FUNCTION DemoBrowseArr( lWithDialog, oDlg )

   LOCAL oBrowse , oFont , oBtn1 , oBtn2 , oBtn3 , oBtn4
   LOCAL aBrowseList, aRow, aCol, oCol, nTmp

   hb_Default( @lWithDialog, .T. )

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
   PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12 && vorher 13
#endif

/*
 If the base array has one dimension, you need to convert it
 first into a 2 dimension array
 (and back again for storage after editing)
*/
   aBrowseList := Array(10,10)
   FOR EACH aRow IN aBrowseList
      FOR EACH aCol IN aRow
         aCol := Ltrim( Str( aCol:__EnumIndex() ) ) + "." + Ltrim( Str( aCol:__EnumIndex() ) )
      NEXT
   NEXT

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demobrowsearr.prg - Browse Array" ;
         AT 0,0 ;
         SIZE 600, 500 ;
         NOEXIT ;
         STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER
   ENDIF
/*
  Do not use parameters AUTOEDIT and APPEND, they are buggy.
*/

   ButtonForSample( "demobrowsearr.prg", oDlg )

   @ 21, 80 BROWSE oBrowse ;
      ARRAY ;
      ON CLICK { |oBrowse,nColPos| BrwArrayEditElem( oBrowse, nColPos ) };
      STYLE WS_VSCROLL + WS_HSCROLL + WS_BORDER ;
      SIZE 500, 300
      * Pressing ENTER starts editing of element, too

   //hwg_CREATEARLIST( oBrowse, aBrowseList )

   oBrowse:aArray := aBrowseList
   FOR EACH oCol IN aBrowseList[1]
      FOR EACH nTmp IN { oCol:__EnumIndex() }
         oBrowse:AddColumn( HColumn():New( Ltrim(Str(nTmp, 5)),{|v,o|(v),o:aArray[o:nCurrent,nTmp]},"C",10,0,.T.,DT_CENTER ) )
      NEXT
      //oCol:Heading := Ltrim( Str( oCol:__EnumIndex() ) )
      //oCol:Length  := 20
   NEXT

   oBrowse:bcolorSel := hwg_ColorC2N( "800080" )
   * FONT setting is mandatory, otherwise crashes with "Not exported method PROPS2ARR"
   oBrowse:ofont               := oFont && HFont():Add( 'Arial',0,-12 )

   @ 10,  410 BUTTON oBtn1 ;
      CAPTION "Edit1"    ;
      SIZE 60,25  ;
      ON CLICK { || BrwArrayEditElem( oBrowse, 1 ) } ;
      TOOLTIP "Click or ENTER: Edit element under cursor"

   @ 70,  410 BUTTON oBtn2 ;
      CAPTION "Add"     ;
      SIZE 60,25  ;
      ON CLICK { || BrwArrayAddElem( oBrowse ) } ;
      TOOLTIP "Add element"

   @ 140, 410 BUTTON oBtn3 ;
      CAPTION "Delete"  ;
      SIZE 60,25  ;
      ON CLICK { || BrwArrayDelElem( oBrowse ) } ;
      TOOLTIP "Delete element under cursor"

   @ 260,410 BUTTON oBtn4 ;
      CAPTION "OK " ;
      SIZE 80,26 ;
      ON CLICK { || hwg_EndDialog() }

   IF lWithDialog
      oDlg:Activate()
   ENDIF

RETURN .T.

STATIC FUNCTION BrwArrayEditElem( oBrowse, nColPos )

   * Edit the Element in the array
   LOCAL nlaeng, cGetfield, cOldget, aRow

   nlaeng := oBrowse:acolumns[ nColPos ]:length
   * Should be an element with one dimension and one element
   aRow := oBrowse:aArray[ oBrowse:nCurrent ]
   cGetField := Padr( aRow[ nColPos ], nlaeng )

   cOldget := cGetfield

   * Call edit window (GET)
   cGetfield := BrwArrayGetElem( oBrowse, cGetfield )
   * Write back, if modified or not cancelled
   IF ( .NOT. EMPTY( cGetfield ) ) .AND. ( cOldget != cGetfield )
      oBrowse:aArray[ oBrowse:nCurrent, nColPos ] := cGetfield
      oBrowse:lChanged := .T.
      oBrowse:Refresh()
   ENDIF

RETURN Nil

STATIC FUNCTION BrwArrayAddElem( oBrowse )

   * Add array element

   LOCAL oTotReg , i , nlaeng , cGetfield

   oTotReg   := {}
   nlaeng    := oBrowse:acolumns[1]:length
   cGetfield := SPACE(nlaeng)

   IF (oBrowse:aArray == NIL) .OR. EMPTY(oBrowse:aArray)
      //   ( LEN(oBrowse:aArray) == 1 .AND. oBrowse:aArray[1] == "" )
      oBrowse:aArray := {}
   ENDIF

   * Copy browse array and get number of elements
   FOR i := 1 TO LEN( oBrowse:aArray )
      AADD( oTotReg, oBrowse:aArray[ i ] )
   NEXT
   * Edit new element
   cGetfield := BrwArrayGetElem( oBrowse, cGetfield )
   IF .NOT. EMPTY( cGetfield )
      * Add new item
      AADD( oTotReg,  { cGetfield }  )
      oBrowse:aArray := oTotReg
      oBrowse:Refresh()
   ENDIF

RETURN Nil

STATIC FUNCTION BrwArrayDelElem( obrw )

   * Delete array element

   IF ( obrw:aArray == Nil ) .OR. Empty( obrw:aArray )
      * Nothing to delete
      RETURN NIL
   ENDIF
   Adel( obrw:aArray, obrw:nCurrent )
   ASize( obrw:aArray, Len( obrw:aArray ) - 1 )
   obrw:lChanged := .T.
   obrw:Refresh()

RETURN Nil

STATIC FUNCTION BrwArrayGetElem( oBrowse, cgetf )

   * Edit window for element
   * Cancel: return empty string

   LOCAL clgetf  , lcancel , oDlg
   LOCAL oLabel1, oLabel2, oGet1, oButton1, oButton2

   lcancel := .F.

   clgetf := cgetf

   INIT DIALOG oDlg ;
      TITLE "Edit array element" ;
      AT 437,74 ;
      SIZE 635,220 ;
      CLIPPER STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + DS_CENTER


   @ 38,12 SAY oLabel1 ;
      CAPTION "Record number:"  ;
      SIZE 136,22

   @ 188,12 SAY oLabel2 ;
      CAPTION Alltrim( Str( oBrowse:nCurrent ) )  ;
      SIZE 155,22

   @ 38,46 GET oGet1 ;
      VAR clgetf ;
      SIZE 534,24 ;
      STYLE WS_BORDER

   @ 38,100 BUTTON oButton1 ;
      CAPTION "Save"   ;
      SIZE 80,32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | oDlg:Close() } ;
      TOOLTIP "Save changes and return to array browse list"

   @ 169,100 BUTTON oButton2 ;
      CAPTION "Cancel"   ;
      SIZE 80,32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | lcancel := .T. , oDlg:Close() } ;
      TOOLTIP "Return to array browse list without saving modifications"

   ACTIVATE DIALOG oDlg CENTER

   * Cancelled ?
   IF lcancel
      clgetf := ""
   ENDIF

RETURN clgetf

#include "demo.ch"

* ============================ EOF of demobrowsearr.prg ==============================

