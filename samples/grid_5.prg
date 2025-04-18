/*
 * $Id: grid_5.prg,v 1.1 2004/04/05 14:16:35 rodrigo_moreno Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGrid class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
 * This sample show how to edit records with grid control
*/

#include "hwgui.ch"

#define GET_FIELD   1
#define GET_LABEL   2
#define GET_PICT    3
#define GET_EDIT    4
#define GET_VALID   5
#define GET_LIST    6
#define GET_LEN     7
#define GET_TYPE    8
#define GET_VALUE   9
#define GET_HEIGHT 10
#define GET_OBJECT 11

STATIC oMain, oForm, oBrowse

#xcommand ADD COLUMN TO GRIDEDIT <aGrid> ;
            FIELD <cField>               ;
            [ LABEL <cLabel> ]           ;
            [ PICTURE <cPicture> ]       ;
            [ <lReadonly:READONLY> ]     ;
            [ VALID <bValid> ]           ;
            [ LIST <aList> ]             ;
          => ;
          aadd(<aGrid>, {<cField>, <cLabel>, <cPicture>, <.lReadonly.>, <{bValid}>, <aList>})

FUNCTION Main()

   INIT WINDOW oMain ;
      MAIN ;
      TITLE "Grid Edition Sample" ;
      AT 0,0 ;
      SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   MENU OF oMain
      MENUITEM "&Exit"   ACTION oMain:Close()
      MENUITEM "&Demo"   ACTION Test()
   ENDMENU

   ACTIVATE WINDOW oMain CENTER

RETURN Nil

FUNCTION Test()

   LOCAL aItems := {}
   LOCAL i , oFont , oGrid

   PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

   Ferase('temp.dbf')

   DBCreate("temp.dbf", {{"field_1", "N", 10, 0} , ;
                  {"field_2", "C", 30, 0} , ;
                  {"field_3", "L",  1, 0} , ;
                  {"field_4", "D",  8, 0} , ;
                  {"field_5", "M", 10, 0} } )

    USE temp NEW

    FOR i := 1 TO 100
        APPEND BLANK
        REPLACE field_1 WITH i
        REPLACE field_2 WITH 'Test ' + str(i)
        REPLACE field_3 WITH mod( i, 10) == 0
        REPLACE field_4 WITH Date() + i
        REPLACE field_5 WITH 'Memo Test'
   NEXT

   COMMIT

   ADD COLUMN TO GRIDEDIT aItems FIELD "Field_1" LABEL "Number" LIST {'List 1', 'List 2'}
   ADD COLUMN TO GRIDEDIT aItems FIELD "Field_2" LABEL "Char" PICTURE "@!" //READONLY
   ADD COLUMN TO GRIDEDIT aItems FIELD "Field_3" LABEL "Bool"
   ADD COLUMN TO GRIDEDIT aItems FIELD "Field_4" LABEL "Date"
   ADD COLUMN TO GRIDEDIT aItems FIELD "Field_5" LABEL "Memo"

   INIT DIALOG oForm ;
      CLIPPER ;
      NOEXIT ;
      TITLE "Grid Edit";
      AT 0, 0 ;
      SIZE 700, 425 ;
      FONT oFont ;
      STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU


   @ 10,10 GRID oGrid ;
      OF oForm ;
      SIZE 680,375;
      ITEMCOUNT LastRec() ;
      ON KEYDOWN {|oCtrl, key| OnKey(oCtrl, key, aItems,oGrid) } ;
      ON CLICK {|oCtrl| OnClick(oCtrl, aItems) } ;
      ON DISPINFO {|oCtrl, nRow, nCol| OnDispInfo( oCtrl, nRow, nCol ) }

   ADD COLUMN TO GRID oGrid HEADER "Number" WIDTH 100
   ADD COLUMN TO GRID oGrid HEADER "Descr"  WIDTH 250
   ADD COLUMN TO GRID oGrid HEADER "Bool"   WIDTH 70
   ADD COLUMN TO GRID oGrid HEADER "Date"   WIDTH 100
   ADD COLUMN TO GRID oGrid HEADER "Memo"   WIDTH 200

   @  10, 395 BUTTON 'Insert' SIZE 75,25 ON CLICK {|| OnKey( oGrid, VK_INSERT, aItems ) }
   @  90, 395 BUTTON 'Change' SIZE 75,25 ON CLICK {|| OnClick( oGrid, aItems ) }
   @ 170, 395 BUTTON 'Delete' SIZE 75,25 ON CLICK {|| OnKey( oGrid, VK_DELETE, aItems ) }

   @ 620, 395 BUTTON 'Close' SIZE 75,25 ON CLICK {|| oForm:close() }

   ACTIVATE DIALOG oForm
   CLOSE DATABASES

RETURN Nil

FUNCTION GridEdit( cAlias, aFields, lAppend, bChange )

   LOCAL i , oFont
   //LOCAL cField
   LOCAL nSay := 0
   LOCAL nGet := 0
   LOCAL cType
   LOCAL nLen
   //LOCAL nRowSize := 30
   LOCAL nGetSize := 10
   LOCAL oForm
   LOCAL nRow := 10
   LOCAL nCol
   LOCAL nHeight := 0
   //LOCAL cValid
   LOCAL nStyle := 0
   LOCAL nArea := Select()


   PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

   DBSelectArea(cAlias)

   IF lAppend
      DBAppend()
   ELSE
      rlock()
   ENDIF

   // set the highest say and get

   FOR i := 1 TO len( aFields )
      ASize(aFields[i], 12)
      nSay := max( nSay, len(aFields[i, GET_LABEL]) )
      cType := Fieldtype(Fieldpos(aFields[i, GET_FIELD]))
      IF Empty(aFields[ i, GET_PICT ] )
         IF cType == "M"
            nLen := 50
         ELSEIF cType == "D"
            nLen := 15
         ELSEIF cType == "L"
            nLen := 5
         ELSE
            nLen := Fieldlen(Fieldpos(aFields[i, GET_FIELD]))
         ENDIF
      ELSE
         nLen := len(transform(Fieldget(FieldPos(aFields[i, GET_FIELD])), aFields[i, GET_PICT]))
      ENDIF
      nGet := max( nGet, nLen )

      aFields[i, GET_LEN] := nLen
      aFields[i, GET_TYPE] := cType
      aFields[i, GET_HEIGHT] := iif( cType == "M", 150, 25 )
      aFields[i, GET_VALUE] := Fieldget(FieldPos(aFields[i, GET_FIELD]))

      nHeight += aFields[i, GET_HEIGHT]
   NEXT

   nHeight += 5 * len(aFields) + 15 + 30
   nRow := 10
   nCol := nSay * nGetSize

   INIT DIALOG oForm ;
      CLIPPER ;
      TITLE "Teste" ;
      AT 0, 0 ;
      SIZE Min( hwg_Getdesktopwidth() - 50, (nSay + nGet) * nGetSize + nGetSize ), ;
         Min( hwg_Getdesktopheight() - 28, nheight ) ;
      FONT oFont ;
      STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU


   FOR i := 1 TO len(aFields)
      @   10, nRow SAY aFields[i, GET_LABEL] ;
         SIZE len(aFields[i, GET_LABEL]) * nGetSize, 25

      cType  := Fieldtype(Fieldpos(aFields[i, GET_FIELD]))

      IF cType == "N" .and. aFields[i, GET_LIST] != NIL
         aFields[i, GET_OBJECT] := HComboBox():New( oForm,;
            3000 + i,;
            aFields[i, GET_VALUE],;
            FieldBlock(aFields[i, GET_FIELD]),;
            IIF( ! aFields[i, GET_EDIT], NIL, WS_DISABLED ),;
            nCol,;
            nRow,;
            aFields[i, GET_LEN] * nGetSize,;
            min(150, len(aFields[i, GET_LIST]) * 25 + 25),;
            aFields[i, GET_LIST],;
            NIL,;
            NIL,;
            NIL,;
            NIL,;
            {|value, oCtrl| __valid(value, oCtrl, aFields, bChange) },;
            NIL)

         ELSEIF cType == 'L'

         aFields[i, GET_OBJECT] := HCheckButton():New( oForm,;
            3000 + i,;
            aFields[i, GET_VALUE],;
            FieldBlock(aFields[i, GET_FIELD]),;
            IIF( ! aFields[i, GET_EDIT], NIL, WS_DISABLED ),;
            nCol,;
            nRow,;
            aFields[i, GET_LEN] * nGetSize,;
            aFields[i, GET_HEIGHT],;
            '',;
            NIL, ;
            NIL,;
            NIL,;
            NIL,;
            {|value, oCtrl| __valid(value, oCtrl, aFields, bChange) },;
            NIL,;
            NIL,;
            NIL)

      ELSEIF cType = 'D'

         aFields[i, GET_OBJECT] := HDatePicker():New( oForm,;
            3000 + i,;
            aFields[i, GET_VALUE],;
            FieldBlock(aFields[i, GET_FIELD ]),;
            IIF( ! aFields[i, GET_EDIT], NIL, WS_DISABLED ),;
            nCol,;
            nRow,;
            aFields[i, GET_LEN] * nGetSize,;
            aFields[i, GET_HEIGHT],;
            NIL,;
            NIL,;
            NIL,;
            {|value, oCtrl| __valid(value, oCtrl, aFields, bChange) },;
            NIL,;
            NIL,;
            NIL )

      ELSE
         IF cType == "M"
            nStyle := WS_VSCROLL + WS_HSCROLL + ES_AUTOHSCROLL + ES_MULTILINE
         ENDIF

         IF aFields[i, GET_EDIT]
            nStyle += WS_DISABLED
         ENDIF

         aFields[i, GET_OBJECT] := HEdit():New( oForm, ;  && oWndParent
            3000 + i,;   && nId
            aFields[i, GET_VALUE],;   && vari
            FieldBlock(aFields[i, GET_FIELD]),; && bSetGet
            nStyle,;     && nStyle
            nCol,;       && nLeft
            nRow,;       && nTop
            aFields[i, GET_LEN]  ,;    && nWidth
            aFields[i, GET_HEIGHT],;   && nHeight
            NIL,;   && oFont
            NIL,NIL,NIL,;  && bInit, bSize, bGfocus
            NIL,;  && bLfocus
            {|value, oCtrl| __valid(value, oCtrl, aFields, bChange) },; && ctooltip
            NIL,; && tcolor
            NIL,; && bcolor
            aFields[i, GET_PICT],; && cPicture
            NIL,; && lNoBorder
            .F.)   && bChange
      ENDIF
//  nMaxLength, lPassword, bKeyDown, bChange
      nRow += aFields[i, GET_HEIGHT] + 5

   NEXT

   @ oForm:nWidth - 160, oForm:nHeight - 30 BUTTON "Ok"     ID IDOK SIZE 75,25
   @ oForm:nWidth -  80, oForm:nHeight - 30 BUTTON "Cancel" ID IDCANCEL SIZE 75,25 ON CLICK {|| oForm:Close() }

   oForm:bActivate := {|| hwg_Setfocus(aFields[1, GET_OBJECT]:handle)}

   ACTIVATE DIALOG oForm

   IF oForm:lResult
      DBCommit()
   ELSEIF lAppend
      DELETE
   ELSE
      /* When canceled, reverte record to old information */
      FOR i := 1 TO len(aFields)
         Fieldput(Fieldpos(aFields[i, GET_FIELD]), aFields[i, GET_VALUE])
      NEXT
   ENDIF

   UNLOCK
   DBSelectArea(nArea)

RETURN oForm:lResult

STATIC FUNCTION __valid(value, oCtrl, aFields, bChange)

   LOCAL result := .T.
   LOCAL i, n, oGet
   LOCAL val

   IF ISOBJECT(oCtrl)
      n := oCtrl:id - 3000

      Eval(bChange, oCtrl, n)

      IF aFields[n, GET_VALID] != nil
         IF ! Eval(aFields[n, GET_VALID])
            result := .F.
            oGet := aFields[n, GET_OBJECT]
            oGet:Setfocus()
         ENDIF
      ENDIF

      FOR i := 1 TO len( aFields )
         val := Fieldget(fieldpos(aFields[i, GET_FIELD]))

         IF valtype(val) == "D" .and. empty(val)
            Fieldput(Fieldpos(aFields[i, GET_FIELD]), Date())
         ENDIF

         oGet := aFields[i, GET_OBJECT]

         IF oGet:id != oCtrl:id .or. valtype(val) == "D"
            oGet:refresh()
         ENDIF
      NEXT
   ENDIF

   (Value) // -w3 -es2

RETURN result

STATIC FUNCTION OnDispInfo( oCtrl, nRow, nCol )

   LOCAL result := ''

   DBGoto(nRow)

   IF nCol == 1
      result := str(field->field_1)
   ELSEIF nCol == 2
      result := field->field_2
   ELSEIF nCol == 3
      result := iif( field->field_3, 'Y', 'N' )
   ELSEIF nCol == 4
      result := DtoC( field->field_4 )
   ELSEIF nCol == 5
      result := MemoLine( field->field_5, 100, 1)
   ENDIF

   (oCtrl) // -w3 -es2

RETURN result

STATIC FUNCTION OnKey( o, k, aItems , oGrid )

   IF k == VK_INSERT
      IF GridEdit('temp', aItems, .T., {|oCtrl, colpos| myblock(oCtrl, colpos)})
         o:SetItemCount(lastrec())
      ELSE
//         MyDelete(oGrid)
         MyDelete(o)
      ENDIF
   ELSEIF k == VK_DELETE .and. hwg_Msgyesno("Delete this record ?", "Warning")
//      MyDelete(oGrid)
         MyDelete(o)
   ENDIF

   (oGrid) // -w3 -es2

RETURN Nil

STATIC FUNCTION OnClick( o, aItems )

    GridEdit('temp', aItems, .F., {|oCtrl, colpos| myblock(oCtrl, colpos)})

   (o) // -w3 -es2

RETURN Nil

STATIC FUNCTION myblock( oCtrl, colpos )

   IF colpos == 3
      REPLACE field_5 WITH 'hello'
   ENDIF

   (oCtrl) // -w3 -es2

RETURN Nil

STATIC FUNCTION mydelete( oGrid )

   DELETE
   PACK
   oGrid:SetItemCount( Lastrec() )

RETURN Nil

* ============================== EOF of grid_5.prg ================================
