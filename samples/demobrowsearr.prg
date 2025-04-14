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
    al_DOKs := oBrwArr:aArray , ;
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

FUNCTION Main()

   LOCAL oWinMain

   INIT WINDOW oWinMain MAIN  ;
      TITLE "DEMOBROWSEARR - Sample BROWSE arrays" AT 100, 100 SIZE 600,400;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&File"
          MENUITEM "&Exit"              ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Browse"
         MENUITEM "Array E&DITABLE"     ACTION BrwArr()
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN Nil

STATIC FUNCTION BrwArr()

   LOCAL oBrwArr , oDlg , oFont , oBtn1 , oBtn2 , oBtn3 , oBtn4
   LOCAL al_DOKs  // The array to be edited

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
   al_DOKs :=  { {"1"} , {"2"} , {"3"} , {"4"} }


   INIT DIALOG oDlg TITLE "Browse Array" ;
      AT 0,0 SIZE 600, 500 NOEXIT ;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

/*
  Do not use parameters AUTOEDIT and APPEND, they are buggy.
*/

   @ 21,29 BROWSE oBrwArr ARRAY ;
      ON CLICK { | | BrwArrayEditElem(oBrwArr) };
      STYLE WS_VSCROLL + WS_HSCROLL   SIZE 341,170
      * Pressing ENTER starts editing of element, too

   hwg_CREATEARLIST(oBrwArr,al_DOKs)
   oBrwArr:acolumns[1]:heading := "DOKs"  // Header string
   oBrwArr:acolumns[1]:length := 50
   oBrwArr:bcolorSel := hwg_ColorC2N( "800080" )
   * FONT setting is mandatory, otherwise crashes with "Not exported method PROPS2ARR"
   oBrwArr:ofont := oFont && HFont():Add( 'Arial',0,-12 )

   @ 10,  410 BUTTON oBtn1 CAPTION "Edit"    SIZE 60,25  ON CLICK {|| BrwArrayEditElem(oBrwArr) } ;
      TOOLTIP "or ENTER: Edit element under cursor"
   @ 70,  410 BUTTON oBtn2 CAPTION "Add"     SIZE 60,25  ON CLICK {|| BrwArrayAddElem(oBrwArr) } ;
      TOOLTIP "Add element"
   @ 140, 410 BUTTON oBtn3 CAPTION "Delete"  SIZE 60,25  ON CLICK {|| BrwArrayDelElem(oBrwArr) } ;
      TOOLTIP "Delete element under cursor"

   @ 260,410 BUTTON oBtn4 CAPTION "OK " SIZE 80,26 ;
      ON CLICK {|| hwg_EndDialog()}

   oDlg:Activate()

RETURN .T.

STATIC FUNCTION BrwArrayEditElem( oBrow )

   * Edit the Element in the array
   LOCAL nlaeng , cGetfield , cOldget , agetty

   nlaeng := oBrow:acolumns[1]:length
   * Should be an element with one dimension and one element
   agetty := oBrow:aArray[oBrow:nCurrent]
   cGetfield :=  PADR(agetty[1] , nlaeng )  && Trim variables for GET

   cOldget := cGetfield

   * Call edit window (GET)
   cGetfield := BrwArrayGetElem(oBrow,cGetfield)
   * Write back, if modified or not cancelled
   IF ( .NOT. EMPTY(cGetfield) ) .AND. ( cOldget != cGetfield )
      oBrow:aArray[oBrow:nCurrent] := { cGetfield }
      oBrow:lChanged := .T.
      oBrow:Refresh()
   ENDIF

RETURN Nil

STATIC FUNCTION BrwArrayAddElem( oBrow )

   * Add array element

   LOCAL oTotReg , i , nlaeng , cGetfield

   oTotReg := {}
   nlaeng := oBrow:acolumns[1]:length
   cGetfield := SPACE(nlaeng)

   IF (oBrow:aArray == NIL) .OR. EMPTY(oBrow:aArray)
      //   ( LEN(oBrow:aArray) == 1 .AND. oBrow:aArray[1] == "" )
      oBrow:aArray := {}
   ENDIF

   * Copy browse array and get number of elements
   FOR i := 1 TO LEN(oBrow:aArray)
      AADD(oTotReg, oBrow:aArray[i])
   NEXT
   * Edit new element
   cGetfield := BrwArrayGetElem(oBrow,cGetfield)
   IF .NOT. EMPTY(cGetfield)
      * Add new item
      AADD(oTotReg,  { cGetfield }  )
      oBrow:aArray := oTotReg
      oBrow:Refresh()
   ENDIF

RETURN Nil

STATIC FUNCTION BrwArrayDelElem( obrw )

   * Delete array element

   IF (obrw:aArray == NIL) .OR. EMPTY(obrw:aArray)
      * Nothing to delete
      RETURN NIL
   ENDIF
   Adel(obrw:aArray, obrw:nCurrent)
   ASize( obrw:aArray, Len( obrw:aArray ) - 1 )
   obrw:lChanged := .T.
   obrw:Refresh()

RETURN Nil

STATIC FUNCTION BrwArrayGetElem( oBrow, cgetf )

   * Edit window for element
   * Cancel: return empty string

   LOCAL clgetf  , lcancel , oDlg
   LOCAL oLabel1, oLabel2, oGet1, oButton1, oButton2

   lcancel := .F.

   clgetf := cgetf

   INIT DIALOG oDlg TITLE "Edit array element" ;
      AT 437,74 SIZE 635,220 ;
      CLIPPER STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + DS_CENTER


   @ 38,12 SAY oLabel1 CAPTION "Record number:"  SIZE 136,22
   @ 188,12 SAY oLabel2 CAPTION ALLTRIM(STR(oBrow:nCurrent))  SIZE 155,22
   @ 38,46 GET oGet1 VAR clgetf SIZE 534,24 ;
        STYLE WS_BORDER
   @ 38,100 BUTTON oButton1 CAPTION "Save"   SIZE 80,32 ;
        STYLE WS_TABSTOP + BS_FLAT ;
        ON CLICK { | | oDlg:Close() } ;
        TOOLTIP "Save changes and return to array browse list"
   @ 169,100 BUTTON oButton2 CAPTION "Cancel"   SIZE 80,32 ;
        STYLE WS_TABSTOP + BS_FLAT ;
        ON CLICK { | | lcancel := .T. , oDlg:Close() } ;
        TOOLTIP "Return to array browse list without saving modifications"

   ACTIVATE DIALOG oDlg

   * Cancelled ?
   IF lcancel
      clgetf := ""
   ENDIF

RETURN clgetf

* ============================ EOF of ademobnrowsearray.prg ==============================

