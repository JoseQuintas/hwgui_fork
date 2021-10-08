/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * RepExec - Loading and executing of reports, built with RepBuild
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "guilib.ch"
#include "repmain.h"
#include "fileio.ch"
#include "common.ch"

STATIC aPaintRep := Nil

REQUEST DBUseArea
REQUEST RecNo
REQUEST DBSkip
REQUEST DBGoTop
REQUEST DBCloseArea

MEMVAR aBitmaps

FUNCTION hwg_ClonePaintRep( ar )

   aPaintRep := AClone( ar )
   RETURN Nil

FUNCTION hwg_SetPaintRep( ar )

   aPaintRep := ar
   RETURN Nil

FUNCTION hwg_OpenReport( fname, repName )

   LOCAL strbuf := Space( 512 ), poz := 513, stroka, nMode := 0
   LOCAL han
   LOCAL aLine, itemName, aItem, res := .T.
   LOCAL nFormWidth

   IF aPaintRep != Nil .AND. fname == aPaintRep[ FORM_FILENAME ] .AND. repName == aPaintRep[ FORM_REPNAME ]
      RETURN res
   ENDIF
   han := FOpen( fname, FO_READ + FO_SHARED )
   IF han <> - 1
      DO WHILE .T.
         stroka := RDSTR( han, @strbuf, @poz, 512 )
         IF Len( stroka ) = 0
            EXIT
         ENDIF
         IF Left( stroka, 1 ) == ";"
            LOOP
         ENDIF
         IF nMode == 0
            IF Left( stroka, 1 ) == "#"
               IF Upper( SubStr( stroka, 2, 6 ) ) == "REPORT"
                  stroka := LTrim( SubStr( stroka, 9 ) )
                  IF Upper( stroka ) == Upper( repName )
                     nMode := 1
                     aPaintRep := { 0, 0, 0, 0, 0, { }, fname, repName, .F., 0, Nil }
                  ENDIF
               ENDIF
            ENDIF
         ELSEIF nMode == 1
            IF Left( stroka, 1 ) == "#"
               IF Upper( SubStr( stroka, 2, 6 ) ) == "ENDREP"
                  EXIT
               ELSEIF Upper( SubStr( stroka, 2, 6 ) ) == "SCRIPT"
                  nMode := 2
                  IF aItem != Nil
                     aItem[ ITEM_SCRIPT ] := ""
                  ELSE
                     aPaintRep[ FORM_VARS ] := ""
                  ENDIF
               ENDIF
            ELSE
               aLine := hb_ATokens( stroka, ';' )
               IF ( itemName := aLine[1] ) == "FORM"
                  aPaintRep[ FORM_WIDTH ] := Val( aLine[2] )
                  aPaintRep[ FORM_HEIGHT ] := Val( aLine[3] )
                  nFormWidth := Val( aLine[4] )
                  aPaintRep[ FORM_XKOEF ] := nFormWidth / aPaintRep[ FORM_WIDTH ]
               ELSEIF itemName == "TEXT"
                  aItem := hwg_Hwr_AddItem( 1, aLine[2], Val( aLine[3] ), ;
                     Val( aLine[4] ), Val( aLine[5] ), Val( aLine[6] ), Val( aLine[7] ), ;
                     0, aLine[8], Val( aLine[9] ) )

                  IF aItem[ ITEM_X1 ] == Nil .OR. aItem[ ITEM_X1 ] == 0 .OR. ;
                          aItem[ ITEM_Y1 ] == Nil .OR. aItem[ ITEM_Y1 ] == 0 .OR. ;
                          aItem[ ITEM_WIDTH ] == Nil .OR. aItem[ ITEM_WIDTH ] == 0 .OR. ;
                          aItem[ ITEM_HEIGHT ] == Nil .OR. aItem[ ITEM_HEIGHT ] == 0
                          hwg_Msgstop( "Error: " + stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "HLINE" .OR. itemName == "VLINE" .OR. itemName == "BOX"
                  aItem := hwg_Hwr_AddItem( IIf( itemName == "HLINE", 2, IIf( itemName == "VLINE", 3, 4 ) ), ;
                      "", Val( aLine[2] ), Val( aLine[3] ), Val( aLine[4] ), ;
                      Val( aLine[5] ), 0, aLine[6] )

                  IF aItem[ ITEM_X1 ] == Nil .OR. aItem[ ITEM_X1 ] == 0 .OR. ;
                              aItem[ ITEM_Y1 ] == Nil .OR. aItem[ ITEM_Y1 ] == 0 .OR. ;
                              aItem[ ITEM_WIDTH ] == Nil .OR. aItem[ ITEM_WIDTH ] == 0 .OR. ;
                              aItem[ ITEM_HEIGHT ] == Nil .OR. aItem[ ITEM_HEIGHT ] == 0
                              hwg_Msgstop( "Error: " + stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "BITMAP"
                  aItem := hwg_Hwr_AddItem(  5, aLine[2], ;
                      Val( aLine[3] ), Val( aLine[4] ), Val( aLine[5] ), Val( aLine[6] ) )

                  IF aItem[ ITEM_X1 ] == Nil .OR. aItem[ ITEM_X1 ] == 0 .OR. ;
                     aItem[ ITEM_Y1 ] == Nil .OR. aItem[ ITEM_Y1 ] == 0 .OR. ;
                     aItem[ ITEM_WIDTH ] == Nil .OR. aItem[ ITEM_WIDTH ] == 0 .OR. ;
                     aItem[ ITEM_HEIGHT ] == Nil .OR. aItem[ ITEM_HEIGHT ] == 0
                     hwg_Msgstop( "Error: " + stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "MARKER"
                  aItem := hwg_Hwr_AddItem( 6, aLine[2], Val( aLine[3] ), ;
                      Val( aLine[4] ), Val( aLine[5] ), Val( aLine[6] ), Val( aLine[7] ) )
               ENDIF
            ENDIF
         ELSEIF nMode == 2
            IF Left( stroka, 1 ) == "#" .AND. Upper( SubStr( stroka, 2, 6 ) ) == "ENDSCR"
               nMode := 1
            ELSE
               IF aItem != Nil
                  aItem[ ITEM_SCRIPT ] += stroka + Chr( 13 ) + Chr( 10 )
               ELSE
                  aPaintRep[ FORM_VARS ] += stroka + Chr( 13 ) + Chr( 10 )
               ENDIF
            ENDIF
         ENDIF
      ENDDO
      FClose( han )
   ELSE
      hwg_Msgstop( "Can't open " + fname )
      RETURN .F.
   ENDIF
   IF Empty( aPaintRep[ FORM_ITEMS ] )
      hwg_Msgstop( repName + " not found or empty!" )
      res := .F.
   ELSE
      aPaintRep[ FORM_ITEMS ] := ASort( aPaintRep[ FORM_ITEMS ],,, { | z, y | z[ ITEM_Y1 ] < y[ ITEM_Y1 ] .OR.( z[ ITEM_Y1 ] == y[ ITEM_Y1 ] .AND.z[ ITEM_X1 ] < y[ ITEM_X1 ] ) .OR.( z[ ITEM_Y1 ] == y[ ITEM_Y1 ] .AND.z[ ITEM_X1 ] == y[ ITEM_X1 ] .AND.( z[ ITEM_WIDTH ] < y[ ITEM_WIDTH ] .OR.z[ ITEM_HEIGHT ] < y[ ITEM_HEIGHT ] ) ) } )
   ENDIF
   RETURN res

FUNCTION hwg_Hwr_AddItem( nType, cCaption, nLeft, nTop, nWidth, nHeight, nAlign, cPen, cFont, nVarType )

   LOCAL aItem, arr

   IF Empty( nAlign ); nAlign := 0; ENDIF
   IF Empty( cPen ); cPen := 0; ENDIF
   IF Empty( cFont ); cFont := 0; ENDIF
   IF Empty( nVarType ); nVarType := 0; ENDIF

   AAdd( aPaintRep[ FORM_ITEMS ], aItem := { nType, cCaption, ;
      nLeft, nTop, nWidth, nHeight, nAlign, cPen, cFont, nVarType, 0, Nil, 0 } )

   IF !Empty( aItem[ ITEM_FONT ] ) .AND. Valtype( aItem[ ITEM_FONT ] ) == "C"
      arr := hb_ATokens( aItem[ ITEM_FONT ], ',' )
      aItem[ ITEM_FONT ] := HFont():Add( arr[1], ;
         Val( arr[2] ), Val( arr[3] ), Val( arr[4] ), Val( arr[5] ), ;
         Val( arr[6] ), Val( arr[7] ), Val( arr[8] ) )
   ENDIF
   IF !Empty( aItem[ ITEM_PEN ] ) .AND. Valtype( aItem[ ITEM_PEN ] ) == "C"
      arr := hb_ATokens( aItem[ ITEM_PEN ], ',' )
      aItem[ ITEM_PEN ] := HPen():Add( Val( arr[1] ), Val( arr[2]), Val( arr[3] ) )
   ENDIF

   RETURN aItem

FUNCTION hwg_RecalcForm( aPaintRep, nFormWidth )

   LOCAL hDC, aMetr, aItem, i
   hDC := hwg_Getdc( hwg_Getactivewindow() )
   aMetr := hwg_Getdevicearea( hDC )
   aPaintRep[ FORM_XKOEF ] := ( aMetr[ 1 ] - XINDENT ) / aPaintRep[ FORM_WIDTH ]
   hwg_Releasedc( hwg_Getactivewindow(), hDC )

   IF nFormWidth != aMetr[ 1 ] - XINDENT
      FOR i := 1 TO Len( aPaintRep[ FORM_ITEMS ] )
         aItem := aPaintRep[ FORM_ITEMS, i ]
         aItem[ ITEM_X1 ] := Round( aItem[ ITEM_X1 ] * ( aMetr[ 1 ] - XINDENT ) / nFormWidth, 0 )
         aItem[ ITEM_Y1 ] := Round( aItem[ ITEM_Y1 ] * ( aMetr[ 1 ] - XINDENT ) / nFormWidth, 0 )
         aItem[ ITEM_WIDTH ] := Round( aItem[ ITEM_WIDTH ] * ( aMetr[ 1 ] - XINDENT ) / nFormWidth, 0 )
         aItem[ ITEM_HEIGHT ] := Round( aItem[ ITEM_HEIGHT ] * ( aMetr[ 1 ] - XINDENT ) / nFormWidth, 0 )
      NEXT
   ENDIF
   RETURN Nil

FUNCTION hwg_PrintReport( printerName, oPrn, lPreview )

   LOCAL oPrinter := IIf( oPrn != Nil, oPrn, HPrinter():New( printerName ) )
   LOCAL aPrnCoors, prnXCoef, prnYCoef
   LOCAL iItem, aItem, nLineStartY := 0, nLineHeight := 0, nPHStart := 0
   LOCAL iPH := 0, iSL := 0, iEL := 0, iPF := 0, iEPF := 0, iDF := 0
   LOCAL poz := 0, stroka, varName, varValue, i
   LOCAL oFont
   LOCAL lAddMode := .F., nYadd := 0, nEndList := 0
#ifdef __GTK__
   LOCAL hDC := oPrinter:hDC
#else
   LOCAL hDC := oPrinter:hDCPrn
#endif

   MEMVAR lFirst, lFinish, lLastCycle, oFontStandard
   PRIVATE lFirst := .T., lFinish := .T., lLastCycle := .F., aBitmaps := {}

   IF Empty( hDC )
      RETURN .F.
   ENDIF

   aPrnCoors := hwg_Getdevicearea( hDC )
   prnXCoef := ( aPrnCoors[ 1 ] / aPaintRep[ FORM_WIDTH ] ) / aPaintRep[ FORM_XKOEF ]
   prnYCoef := ( aPrnCoors[ 2 ] / aPaintRep[ FORM_HEIGHT ] ) / aPaintRep[ FORM_XKOEF ]
   // writelog( oPrinter:cPrinterName + str(aPrnCoors[1])+str(aPrnCoors[2])+" / "+str(aPaintRep[FORM_WIDTH])+" "+str(aPaintRep[FORM_HEIGHT])+str(aPaintRep[FORM_XKOEF])+" / "+str(prnXCoef)+str(prnYCoef) )

   IF Type( "oFontStandard" ) = "U"
#ifdef __GTK__
      PRIVATE oFontStandard := oPrinter:AddFont( "Arial", -13, .F., .F., .F., 204 )
#else
      PRIVATE oFontStandard := HFont():Add( "Arial", 0, - 13, 400, 204 )
#endif
   ENDIF

   FOR i := 1 TO Len( aPaintRep[ FORM_ITEMS ] )
      IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_TEXT
         oFont := aPaintRep[ FORM_ITEMS, i, ITEM_FONT ]
#ifdef __GTK__
         aPaintRep[ FORM_ITEMS, i, ITEM_STATE ] := oPrinter:AddFont( oFont:name, ;
            Round( oFont:height * prnYCoef, 0 ), (oFont:weight>400), ;
            (oFont:italic>0), .F., oFont:charset )
#else
         aPaintRep[ FORM_ITEMS, i, ITEM_STATE ] := HFont():Add( oFont:name, ;
            oFont:width, Round( oFont:height * prnYCoef, 0 ), oFont:weight, ;
            oFont:charset, oFont:italic )
#endif
      ENDIF
   NEXT

   IF ValType( aPaintRep[ FORM_VARS ] ) == "C"
      DO WHILE .T.
         stroka := RDSTR( , aPaintRep[ FORM_VARS ], @poz )
         IF Len( stroka ) = 0
            EXIT
         ENDIF
         DO WHILE ! Empty( varName := getNextVar( @stroka, @varValue ) )
            PRIVATE &varName
            IF varValue != Nil
               &varName := &varValue
            ENDIF
         ENDDO
      ENDDO
   ENDIF

   FOR iItem := 1 TO Len( aPaintRep[ FORM_ITEMS ] )
      aItem := aPaintRep[ FORM_ITEMS, iItem ]
      IF aItem[ ITEM_TYPE ] == TYPE_MARKER
         aItem[ ITEM_STATE ] := 0
         IF aItem[ ITEM_CAPTION ] == "SL"
            nLineStartY := aItem[ ITEM_Y1 ]
            aItem[ ITEM_STATE ] := 0
            iSL := iItem
         ELSEIF aItem[ ITEM_CAPTION ] == "EL"
            nLineHeight := aItem[ ITEM_Y1 ] - nLineStartY
            iEL := iItem
         ELSEIF aItem[ ITEM_CAPTION ] == "PF"
            nEndList := aItem[ ITEM_Y1 ]
            iPF := iItem
         ELSEIF aItem[ ITEM_CAPTION ] == "EPF"
            iEPF := iItem
         ELSEIF  aItem[ ITEM_CAPTION ] == "DF"
            iDF := iItem
            IF iPF == 0
               nEndList := aItem[ ITEM_Y1 ]
            ENDIF
         ELSEIF aItem[ ITEM_CAPTION ] == "PH"
            iPH := iItem
            nPHStart := aItem[ ITEM_Y1 ]
         ENDIF
      ENDIF
   NEXT
   IF iPH > 0 .AND. iSL == 0
      hwg_Msgstop( "'Start Line' marker is absent" )
      oPrinter:END()
      RETURN .F.
   ELSEIF iSL > 0 .AND. iEL == 0
      hwg_Msgstop( "'End Line' marker is absent" )
      oPrinter:END()
      RETURN .F.
   ELSEIF iPF > 0 .AND. iEPF == 0
      hwg_Msgstop( "'End of Page Footer' marker is absent" )
      oPrinter:END()
      RETURN .F.
   ELSEIF iSL > 0 .AND. iPF == 0 .AND. iDF == 0
      hwg_Msgstop( "'Page Footer' and 'Document Footer' markers are absent" )
      oPrinter:END()
      RETURN .F.
   ENDIF

   oPrinter:StartDoc( lPreview )
   oPrinter:StartPage()

   DO WHILE .T.
      iItem := 1
      DO WHILE iItem <= Len( aPaintRep[ FORM_ITEMS ] )
         aItem := aPaintRep[ FORM_ITEMS, iItem ]
         // WriteLog( Str(iItem,3)+": "+Str(aItem[ITEM_TYPE]) )
         IF aItem[ ITEM_TYPE ] == TYPE_MARKER
            IF aItem[ ITEM_CAPTION ] == "PH"
               IF aItem[ ITEM_STATE ] == 0
                  aItem[ ITEM_STATE ] := 1
                  FOR i := 1 TO iPH - 1
                     IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_BITMAP
                        hwg_Hwr_PrintItem( oPrinter, aPaintRep, aPaintRep[ FORM_ITEMS, i ], prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
                     ENDIF
                  NEXT
               ENDIF
            ELSEIF aItem[ ITEM_CAPTION ] == "SL"
               IF aItem[ ITEM_STATE ] == 0
                  // IF iPH == 0
                  FOR i := 1 TO iSL - 1
                     IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_BITMAP
                        hwg_Hwr_PrintItem( oPrinter, aPaintRep, aPaintRep[ FORM_ITEMS, i ], prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
                     ENDIF
                  NEXT
                  // ENDIF
                  aItem[ ITEM_STATE ] := 1
                  IF ! ScriptExecute( aItem )
                     oPrinter:EndPage()
                     oPrinter:EndDoc()
                     oPrinter:END()
                     RETURN .F.
                  ENDIF
                  IF lLastCycle
                     iItem := iEL + 1
                     LOOP
                  ENDIF
               ENDIF
               lAddMode := .T.
            ELSEIF aItem[ ITEM_CAPTION ] == "EL"
               FOR i := iSL + 1 TO iEL - 1
                  IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_BITMAP
                     hwg_Hwr_PrintItem( oPrinter, aPaintRep, aPaintRep[ FORM_ITEMS, i ], prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
                  ENDIF
               NEXT
               IF ! ScriptExecute( aItem )
                  oPrinter:EndPage()
                  oPrinter:EndDoc()
                  oPrinter:END()
                  RETURN .F.
               ENDIF
               IF ! lLastCycle
                  nYadd += nLineHeight
                  IF nLineStartY + nYadd + nLineHeight >= nEndList
                     // Writelog("New Page")
                     IF iPF == 0
                        oPrinter:EndPage()
                        oPrinter:StartPage()
                        nYadd := 10 - IIf( nPHStart > 0, nPHStart, nLineStartY )
                        lAddMode := .T.
                        IF iPH == 0
                           iItem := iSL
                        ELSE
                           iItem := iPH
                        ENDIF
                     ELSE
                        lAddMode := .F.
                     ENDIF
                  ELSE
                     iItem := iSL
                  ENDIF
               ELSE
                  lAddMode := .F.
               ENDIF
            ELSEIF aItem[ ITEM_CAPTION ] == "EPF"
               FOR i := iPF + 1 TO iEPF - 1
                  IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_BITMAP
                     hwg_Hwr_PrintItem( oPrinter, aPaintRep, aPaintRep[ FORM_ITEMS, i ], prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
                  ENDIF
               NEXT
               IF ! lLastCycle
                  oPrinter:EndPage()
                  oPrinter:StartPage()
                  nYadd := 10 - IIf( nPHStart > 0, nPHStart, nLineStartY )
                  lAddMode := .T.
                  IF iPH == 0
                     iItem := iSL
                  ELSE
                     iItem := iPH
                  ENDIF
               ENDIF
            ELSEIF aItem[ ITEM_CAPTION ] == "DF"
               lAddMode := .F.
               IF aItem[ ITEM_ALIGN ] == 1
               ENDIF
            ENDIF
         ELSE
            IF aItem[ ITEM_TYPE ] == TYPE_TEXT
               IF ! ScriptExecute( aItem )
                  oPrinter:EndPage()
                  oPrinter:EndDoc()
                  oPrinter:END()
                  RETURN .F.
               ENDIF
            ENDIF
            IF aItem[ ITEM_TYPE ] != TYPE_BITMAP
               hwg_Hwr_PrintItem( oPrinter, aPaintRep, aItem, prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
            ENDIF
         ENDIF
         iItem ++
      ENDDO
      FOR i := IIf( iSL == 0, 1, IIf( iDF > 0, iDF + 1, IIf( iPF > 0, iEPF + 1, iEL + 1 ) ) ) TO Len( aPaintRep[ FORM_ITEMS ] )
         IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_BITMAP
            hwg_Hwr_PrintItem( oPrinter, aPaintRep, aPaintRep[ FORM_ITEMS, i ], prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
         ENDIF
      NEXT
      IF lFinish
         EXIT
      ENDIF
   ENDDO

   oPrinter:EndPage()
   oPrinter:EndDoc()
   IF lPreview != Nil .AND. lPreview
      oPrinter:Preview()
   ENDIF
   oPrinter:END()

   FOR i := 1 TO Len( aPaintRep[ FORM_ITEMS ] )
      IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_TEXT
         aPaintRep[ FORM_ITEMS, i, ITEM_STATE ]:Release()
         aPaintRep[ FORM_ITEMS, i, ITEM_STATE ] := Nil
      ENDIF
   NEXT
   FOR i := 1 TO Len( aBitmaps )
      IF !Empty( aBitmaps[i] )
         hwg_Deleteobject( aBitmaps[i] )
      ENDIF
      aBitmaps[i] := Nil
   NEXT

   RETURN .T.

FUNCTION hwg_Hwr_PrintItem( oPrinter, aPaintRep, aItem, prnXCoef, prnYCoef, nYadd, lCalc )

   LOCAL x1 := aItem[ ITEM_X1 ], y1 := aItem[ ITEM_Y1 ] + nYadd, x2, y2
   LOCAL hBitmap, stroka

   HB_SYMBOL_UNUSED( aPaintRep )

   x2 := x1 + aItem[ ITEM_WIDTH ] - 1
   y2 := y1 + aItem[ ITEM_HEIGHT ] - 1
   x1 := Round( x1 * prnXCoef, 0 )
   y1 := Round( y1 * prnYCoef, 0 )
   x2 := Round( x2 * prnXCoef, 0 )
   y2 := Round( y2 * prnYCoef, 0 )

   IF aItem[ ITEM_TYPE ] == TYPE_TEXT
      IF aItem[ ITEM_VAR ] > 0
         stroka := IIf( lCalc, &( aItem[ ITEM_CAPTION ] ), "" )
      ELSE
         stroka := aItem[ ITEM_CAPTION ]
      ENDIF
      IF ! Empty( aItem[ ITEM_CAPTION ] )
         oPrinter:Say( stroka, x1, y1, x2, y2, ;
                       IIf( aItem[ ITEM_ALIGN ] == 0, DT_LEFT, IIf( aItem[ ITEM_ALIGN ] == 1, DT_RIGHT, DT_CENTER ) ), ;
                       aItem[ ITEM_STATE ] )
      ENDIF
   ELSEIF aItem[ ITEM_TYPE ] == TYPE_HLINE
      oPrinter:Line( x1, Round( ( y1 + y2 ) / 2, 0 ), x2, Round( ( y1 + y2 ) / 2, 0 ), aItem[ ITEM_PEN ] )
   ELSEIF aItem[ ITEM_TYPE ] == TYPE_VLINE
      oPrinter:Line( Round( ( x1 + x2 ) / 2, 0 ), y1, Round( ( x1 + x2 ) / 2, 0 ), y2, aItem[ ITEM_PEN ] )
   ELSEIF aItem[ ITEM_TYPE ] == TYPE_BOX
      oPrinter:Box( x1, y1, x2, y2, aItem[ ITEM_PEN ] )
   ELSEIF aItem[ ITEM_TYPE ] == TYPE_BITMAP
      Aadd( aBitmaps, hBitmap := hwg_Openbitmap( aItem[ ITEM_CAPTION ], oPrinter:hDC ) )
      //hwg_writelog( "hBitmap: "+Iif(hBitmap==Nil,"Nil","Ok") )
      oPrinter:Bitmap( x1, y1, x2, y2,, hBitmap, aItem[ ITEM_CAPTION ] )
      //hwg_Deleteobject( hBitmap )
   ENDIF

   RETURN Nil

STATIC FUNCTION ScriptExecute( aItem )
   LOCAL nError, nLineEr
   IF aItem[ ITEM_SCRIPT ] != Nil .AND. ! Empty( aItem[ ITEM_SCRIPT ] )
      IF ValType( aItem[ ITEM_SCRIPT ] ) == "C"
         IF ( aItem[ ITEM_SCRIPT ] := RdScript( , aItem[ ITEM_SCRIPT ] ) ) == Nil
            nError := CompileErr( @nLineEr )
            hwg_Msgstop( "Script error (" + LTrim( Str( nError ) ) + "), line " + LTrim( Str( nLineEr ) ) )
            RETURN .F.
         ENDIF
      ENDIF
      DoScript( aItem[ ITEM_SCRIPT ] )
      RETURN .T.
   ENDIF
   RETURN .T.
