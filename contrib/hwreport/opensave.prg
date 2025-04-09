/*
 * Repbuild - Visual Report Builder
 * Open/save functions
 *
 * Copyright 2001-2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

   // Modifications by DF7BE:
   // Port of Borland C resources to HWGUI commands

#include "hwgui.ch"
#include "repbuild.h"
#include "repmain.h"
#include "fileio.ch"
// #ifdef __XHARBOUR__
// #include "ttable.ch"
// #endif
// #ifdef __GTK__
// #include "gtk.ch"
// #endif

   // Removed
   // #define SB_VERT         1

MEMVAR aPaintRep , mypath, aItemTypes, oFontDlg
STATIC oDlg

FUNCTION _hwr_FileDlg( lOpen )

   LOCAL oRb1, oRb2,  oEdit1, oLabel1, oEdit2

   IF !lOpen .AND. ( aPaintRep == Nil .OR. Empty( aPaintRep[FORM_ITEMS] ) )
      hwg_Msgstop( "Nothing to save" )
      RETURN Nil
   ELSEIF lOpen
      _hwr_CloseReport()
   ENDIF

   INIT DIALOG oDlg TITLE "" ;
      AT 100, 100 SIZE 426, 250 FONT oFontDlg ON INIT { || InitOpen( lOpen ) }

   @ 29, 8 GROUPBOX ""  SIZE 160, 76
   RADIOGROUP
   @ 36, 24 RADIOBUTTON oRb1  ;
      CAPTION "Report file"     SIZE 136, 24 ON CLICK {||oLabel1:SetText( "Report Name:" )}
   @ 36, 48 RADIOBUTTON oRb2  ;
      CAPTION "Program source"  SIZE 137, 24 ON CLICK {||oLabel1:SetText( "Function Name:" )}
   END RADIOGROUP SELECTED 1

   @ 16, 90 EDITBOX oEdit1 CAPTION ""  SIZE 280, 24 ;
      STYLE ES_AUTOHSCROLL + WS_TABSTOP

   @ 296, 88 BUTTON "Browse" SIZE 90, 30 ;
      STYLE WS_TABSTOP ON CLICK { ||BrowFile( lOpen ) }

   @ 28, 126 SAY oLabel1 CAPTION "Report name:"  SIZE 144, 22
   @ 61, 153 EDITBOX oEdit2 CAPTION ""  SIZE 96, 24

   @ 26, 200 BUTTON "OK"  SIZE 80, 32 STYLE WS_TABSTOP ON CLICK { || EndOpen( lOpen ) }
   @ 298, 200 BUTTON "Cancel"  SIZE 80, 32 STYLE WS_TABSTOP ON CLICK { || oDlg:Close() }

   oDlg:Activate()

   RETURN Nil

STATIC FUNCTION InitOpen( lOpen )

   oDlg:SetTitle( Iif( lOpen,"Open report","Save report" ) )
   hwg_Setfocus( oDlg:oEdit1:handle )

   RETURN .T.

STATIC FUNCTION BrowFile( lOpen )
   LOCAL fname, s1, s2

   IF oDlg:oRb1:Value
      s1 := "Report files( *.rpt )"
      s2 := "*.rpt"
   ELSE
      s1 := "Program files( *.prg )"
      s2 := "*.prg"
   ENDIF

   IF lOpen
      fname := hwg_SelectFile( s1, s2, mypath )
   ELSE
#ifdef __GTK__
      fname := hwg_Selectfile( s1, s2, mypath )
#else
      fname := hwg_SaveFile( s2, s1, s2, mypath )
#endif
   ENDIF

   oDlg:oEdit1:Value := fname
   hwg_Setfocus( oDlg:oEdit2:handle )

   RETURN Nil

STATIC FUNCTION EndOpen( lOpen )
   LOCAL fname, repName
   LOCAL res // := .T.// not needed value

   fname := oDlg:oEdit1:Value
   IF !Empty( fname )
      repName := oDlg:oEdit2:Value

      IF lOpen
         IF ( res := OpenFile( fname,@repName ) )
            aPaintRep[FORM_Y] := 0
            hwg_Enablemenuitem( ,IDM_VIEW1, .T., .T. )
            hwg_Enablemenuitem( ,1, .T., .F. )
            Hwindow():GetMain():Refresh()
         ELSE
            aPaintRep := Nil
            hwg_Enablemenuitem( ,IDM_VIEW1, .F., .T. )
            hwg_Enablemenuitem( ,1, .F., .F. )
         ENDIF
      ELSE
         res := SaveRFile( fname, repName )
         aPaintRep[FORM_FILENAME] := fname
         aPaintRep[FORM_REPNAME] := repName
      ENDIF

      IF res
         oDlg:Close()
      ENDIF
   ELSE
      hwg_Setfocus( oDlg:oEdit1:handle )
   ENDIF

   RETURN .T.

FUNCTION _hwr_CloseReport

   IF aPaintRep != Nil
      IF aPaintRep[FORM_CHANGED] == .T.
         IF hwg_Msgyesno( "Report was changed. Are you want to save it ?" )
            _hwr_SaveReport()
         ENDIF
      ENDIF
      hwg_hwr_Close( aPaintRep )
      aPaintRep := Nil
      //hwg_Showscrollbar( Hwindow():GetMain():handle, SB_VERT, .F. )
      Hwindow():GetMain():Refresh()
      hwg_Enablemenuitem( , 1, .F. , .F. )
   ENDIF

   RETURN .T.

FUNCTION _hwr_SaveReport

   IF ( aPaintRep == Nil .OR. Empty( aPaintRep[FORM_ITEMS] ) )
      hwg_Msgstop( "Nothing to save" )
      RETURN Nil
   ENDIF
   IF Empty( aPaintRep[FORM_FILENAME] )
      _hwr_FileDlg( .F. )
   ELSE
      SaveRFile( aPaintRep[FORM_FILENAME], aPaintRep[FORM_REPNAME] )
   ENDIF

   RETURN Nil

STATIC FUNCTION OpenFile( fname, repName )
   LOCAL strbuf := Space( 512 ), poz := 513, stroka, nMode := 0
   LOCAL han, res := .T., lPrg := .F.
   LOCAL cSource := "", vDummy //, i

   IF Upper( FilExten(fname ) ) == "PRG"
      lPrg := .T.
      han := FOpen( fname, FO_READ + FO_SHARED )
      IF han != - 1
         DO WHILE .T.
            stroka := RDSTR( han, @strbuf, @poz, 512 )
            IF Len( stroka ) = 0
               EXIT
            ENDIF
            IF Left( stroka, 1 ) == ";"
               LOOP
            ENDIF
            IF nMode == 0
               IF Upper( Left( stroka,8 ) ) == "FUNCTION" .AND. ;
                     Upper( LTrim( SubStr( stroka,10 ) ) ) == Upper( repname )
                  nMode := 10
               ENDIF
            ELSEIF nMode == 10
               IF Upper( Left( stroka,15 ) ) == "LOCAL APAINTREP"
                  nMode := 11
               ELSE
                  hwg_Msgstop( "Wrong function " + repname )
                  FClose( han )
                  RETURN .F.
               ENDIF
            ELSEIF nMode == 11
               IF Upper( Left( stroka,6 ) ) == "RETURN"
                  EXIT
               ELSE
                  IF Right( stroka, 1 ) == ";"
                     cSource += LTrim( RTrim( Left( stroka,Len(stroka ) - 1 ) ) )
                  ELSE
                     cSource += LTrim( RTrim( stroka ) )
                     vDummy := &cSource
// ---
                     (vDummy) // value not used -w3 -es2
// ---
                     cSource := ""
                  ENDIF
               ENDIF
            ENDIF
         ENDDO
         FClose( han )
      ELSE
         hwg_Msgstop( "Can't open " + fname )
         RETURN .F.
      ENDIF
   ELSE
      aPaintRep := hwg_hwr_Open( fname, repName )
   ENDIF
   IF aPaintRep == Nil .OR. Empty( aPaintRep[FORM_ITEMS] )
      hwg_Msgstop( repname + " not found or empty!" )
      res := .F.
   ELSE
      hwg_Enablemenuitem( , IDM_CLOSE, .T. , .T. )
      hwg_Enablemenuitem( , IDM_SAVE, .T. , .T. )
      hwg_Enablemenuitem( , IDM_SAVEAS, .T. , .T. )
      hwg_Enablemenuitem( , IDM_PRINT, .T. , .T. )
      hwg_Enablemenuitem( , IDM_PREVIEW, .T. , .T. )
      hwg_Enablemenuitem( , IDM_FOPT, .T. , .T. )
      /*
      FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
         IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_BITMAP
            aPaintRep[FORM_ITEMS,i,ITEM_BITMAP] := HBitmap():AddFile( aPaintRep[FORM_ITEMS,i,ITEM_CAPTION] )
         ENDIF
      NEXT
      */
      aPaintRep[FORM_ITEMS] := ASort( aPaintRep[FORM_ITEMS], , , { |z, y|z[ITEM_Y1] < y[ITEM_Y1] .OR. ( z[ITEM_Y1] == y[ITEM_Y1] .AND. z[ITEM_X1] < y[ITEM_X1] ) .OR. ( z[ITEM_Y1] == y[ITEM_Y1] .AND. z[ITEM_X1] == y[ITEM_X1] .AND. (z[ITEM_WIDTH] < y[ITEM_WIDTH] .OR. z[ITEM_HEIGHT] < y[ITEM_HEIGHT] ) ) } )
      IF !lPrg
         RecalcForm( aPaintRep, Round( aPaintRep[ FORM_XKOEF ] * aPaintRep[ FORM_WIDTH ], 0 ) )
      ENDIF

      hwg_WriteStatus( Hwindow():GetMain(), 2, LTrim( Str(aPaintRep[FORM_WIDTH],4 ) ) + "x" + ;
         LTrim( Str( aPaintRep[FORM_HEIGHT],4 ) ) + "  Items: " + LTrim( Str( Len(aPaintRep[FORM_ITEMS] ) ) ) )
   ENDIF

   RETURN res

STATIC FUNCTION RecalcForm( aPaintRep, nFormWidth )

   LOCAL hDC, aMetr, aItem, i, xKoef

   hDC := hwg_Getdc( hwg_Getactivewindow() )
   aMetr := hwg_Getdevicearea( hDC )
   aPaintRep[ FORM_XKOEF ] := ( aMetr[ 1 ] - XINDENT ) / aPaintRep[ FORM_WIDTH ]
   hwg_Releasedc( hwg_Getactivewindow(), hDC )

   IF nFormWidth != aMetr[ 1 ] - XINDENT
      xKoef := ( aMetr[ 1 ] - XINDENT ) / nFormWidth
      FOR i := 1 TO Len( aPaintRep[ FORM_ITEMS ] )
         aItem := aPaintRep[ FORM_ITEMS, i ]
         aItem[ ITEM_X1 ] := Round( aItem[ ITEM_X1 ] * xKoef, 0 )
         aItem[ ITEM_Y1 ] := Round( aItem[ ITEM_Y1 ] * xKoef, 0 )
         aItem[ ITEM_WIDTH ] := Round( aItem[ ITEM_WIDTH ] * xKoef, 0 )
         aItem[ ITEM_HEIGHT ] := Round( aItem[ ITEM_HEIGHT ] * xKoef, 0 )
      NEXT
   ENDIF
   RETURN Nil

STATIC FUNCTION SaveRFile( fname, repName )
   LOCAL strbuf := Space( 512 ), poz := 513, stroka, nMode := 0
   LOCAL han, hanOut, isOut := .F. , res := .F.
   LOCAL lPrg := ( Upper( FilExten(fname ) ) == "PRG" )

   IF File( fname )
      han := FOpen( fname, FO_READWRITE + FO_EXCLUSIVE )
      IF han <> - 1
         hanOut := FCreate( mypath + "__rpt.tmp" )
         IF hanOut <> - 1
            DO WHILE .T.
               stroka := RDSTR( han, @strbuf, @poz, 512 )
               IF Len( stroka ) = 0
                  EXIT
               ENDIF
               IF nMode == 0
                  IF ( lPrg .AND. Upper( Left( stroka,8 ) ) == "FUNCTION" ) ;
                        .OR. ( !lPrg .AND. Left( stroka,1 ) == "#" .AND. ;
                        Upper( SubStr( stroka,2,6 ) ) == "REPORT" )
                     IF Upper( LTrim( SubStr( stroka,9 ) ) ) == Upper( repName )
                        nMode := 1
                        isOut := .T.
                        LOOP
                     ENDIF
                  ENDIF
                  FWrite( hanOut, stroka + iif( Asc(Right(stroka,1 ) ) < 20,"",Chr(10 ) ) )
               ELSEIF nMode == 1
                  IF ( lPrg .AND. Left( stroka,6 ) == "RETURN" ) ;
                        .OR. ( !lPrg .AND. Left( stroka,1 ) == "#" .AND. ;
                        Upper( SubStr( stroka,2,6 ) ) == "ENDREP" )
                     nMode := 0
                     IF lPrg
                        WriteToPrg( hanOut, repName )
                     ELSE
                        WriteRep( hanOut, repName )
                     ENDIF
                  ENDIF
               ENDIF
            ENDDO
            IF isOut
               FClose( hanOut )
               FClose( han )
               IF FErase( fname ) == - 1 .OR. FRename( mypath + "__rpt.tmp", fname ) == - 1
                  hwg_Msgstop( "Can't rename __rpt.tmp" )
               ELSE
                  res := .T.
               ENDIF
            ELSE
               FSeek( han, 0, FS_END )
               FWrite( han, Chr( 10 ) )
               IF lPrg
                  WriteToPrg( han, repName )
               ELSE
                  WriteRep( hanOut, repName )
               ENDIF
               FClose( hanOut )
               FClose( han )
               res := .T.
            ENDIF
         ELSE
            hwg_Msgstop( "Can't create __rpt.tmp" )
            FClose( han )
         ENDIF
      ELSE
         hwg_Msgstop( "Can't open " + fname )
      ENDIF
   ELSE
      han := FCreate( fname )
      IF lPrg
         WriteToPrg( han, repName )
      ELSE
         WriteRep( han, repName )
      ENDIF
      FClose( han )
      res := .T.
   ENDIF
   IF res
      aPaintRep[FORM_CHANGED] := .F.
   ENDIF

   RETURN res

STATIC FUNCTION WriteRep( han, repName )
   LOCAL i, aItem, oPen, oFont, hDCwindow, aMetr

   hDCwindow := hwg_Getdc( Hwindow():GetMain():handle )
   aMetr := hwg_GetDeviceArea( hDCwindow )
   hwg_Releasedc( Hwindow():GetMain():handle, hDCwindow )

   FWrite( han, "#REPORT " + repName + Chr( 10 ) )
   FWrite( han, "FORM;" + LTrim( Str(aPaintRep[FORM_WIDTH] ) ) + ";" + ;
      LTrim( Str( aPaintRep[FORM_HEIGHT] ) ) + ";" + ;
      LTrim( Str( aMetr[1] - XINDENT ) ) + Chr( 10 ) )
   WriteScript( han, aPaintRep[FORM_VARS] )

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      aItem := aPaintRep[FORM_ITEMS,i]
      IF aItem[ITEM_TYPE] == TYPE_TEXT
         oFont := aItem[ITEM_FONT]
         FWrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + aItem[ITEM_CAPTION] + ";" + ;
            LTrim( Str( aItem[ITEM_X1],4 ) ) + ";" + LTrim( Str( aItem[ITEM_Y1],4 ) ) + ";" + ;
            LTrim( Str( aItem[ITEM_WIDTH],4 ) ) + ";" + LTrim( Str( aItem[ITEM_HEIGHT],4 ) ) + ;
            ";" + Str( aItem[ITEM_ALIGN], 1 ) + ";" + oFont:name ;
            + "," + LTrim( Str( oFont:width ) ) + "," + LTrim( Str( oFont:height ) ) ;
            + "," + LTrim( Str( oFont:weight ) ) + "," + LTrim( Str( oFont:charset ) ) ;
            + "," + LTrim( Str( oFont:italic ) ) + "," + LTrim( Str( oFont:underline ) ) ;
            + "," + LTrim( Str( oFont:strikeout ) ) + ";" + Str( aItem[ITEM_VAR], 1 ) + Chr( 10 ) )
         WriteScript( han, aItem[ITEM_SCRIPT] )
      ELSEIF aItem[ITEM_TYPE] == TYPE_HLINE .OR. aItem[ITEM_TYPE] == TYPE_VLINE .OR. aItem[ITEM_TYPE] == TYPE_BOX
         oPen := aItem[ITEM_PEN]
         FWrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + ;
            LTrim( Str( aItem[ITEM_X1],4 ) ) + ";" + LTrim( Str( aItem[ITEM_Y1],4 ) ) + ";" + ;
            LTrim( Str( aItem[ITEM_WIDTH],4 ) ) + ";" + LTrim( Str( aItem[ITEM_HEIGHT],4 ) ) + ;
            ";" + LTrim( Str( oPen:style ) ) + "," + LTrim( Str( oPen:width ) ) + "," + LTrim( Str( oPen:color ) ) ;
            + Chr( 10 ) )
      ELSEIF aItem[ITEM_TYPE] == TYPE_BITMAP
         FWrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + aItem[ITEM_CAPTION] + ";" + ;
            LTrim( Str( aItem[ITEM_X1],4 ) ) + ";" + LTrim( Str( aItem[ITEM_Y1],4 ) ) + ";" + ;
            LTrim( Str( aItem[ITEM_WIDTH],4 ) ) + ";" + LTrim( Str( aItem[ITEM_HEIGHT],4 ) ) + ;
            + Chr( 10 ) )
      ELSEIF aItem[ITEM_TYPE] == TYPE_MARKER
         FWrite( han, aItemTypes[aItem[ITEM_TYPE]] + ";" + aItem[ITEM_CAPTION] + ";" + ;
            LTrim( Str( aItem[ITEM_X1],4 ) ) + ";" + LTrim( Str( aItem[ITEM_Y1],4 ) ) + ";" + ;
            LTrim( Str( aItem[ITEM_WIDTH],4 ) ) + ";" + LTrim( Str( aItem[ITEM_HEIGHT],4 ) ) + ;
            ";" + Str( aItem[ITEM_ALIGN], 1 ) + Chr( 10 ) )
         WriteScript( han, aItem[ITEM_SCRIPT] )
      ENDIF
   NEXT
   FWrite( han, "#ENDREP " + Chr( 10 ) )

   RETURN Nil

STATIC FUNCTION WriteToPrg( han, repName )
   LOCAL i, aItem, oPen, oFont, hDCwindow, aMetr, cItem, cQuote, crlf := Chr( 10 )

   hDCwindow := hwg_Getdc( Hwindow():GetMain():handle )
   aMetr := hwg_GetDeviceArea( hDCwindow )
   hwg_Releasedc( Hwindow():GetMain():handle, hDCwindow )

   FWrite( han, "FUNCTION " + repName + crlf + crlf + ;
      "   LOCAL aPaintRep, cEnd := Chr(13)+Chr(10)" + crlf + crlf )

   FWrite( han, '   aPaintRep := hwg_hwr_Init( "' + repName + '", ' ;
      + LTrim( Str(aPaintRep[FORM_WIDTH] ) ) + ', ' + LTrim( Str( aPaintRep[FORM_HEIGHT] ) ) + ;
      ', ' + LTrim( Str(aMetr[1] - XINDENT ) ) + ')' + crlf )

   IF !Empty( aPaintRep[FORM_VARS] )
      FWrite( han, "   aPaintRep[FORM_VARS] := ;" + crlf )
      WriteScript( han, aPaintRep[FORM_VARS], .T. )
   ENDIF

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      aItem := aPaintRep[FORM_ITEMS,i]

      cItem := LTrim( Str( aItem[ITEM_TYPE],1 ) ) + ","
      IF aItem[ITEM_TYPE] == TYPE_TEXT .OR. aItem[ITEM_TYPE] == TYPE_BITMAP ;
            .OR. aItem[ITEM_TYPE] == TYPE_MARKER
         cQuote := iif( !( '"' $ aItem[ITEM_CAPTION] ), '"', ;
            iif( !( "'" $ aItem[ITEM_CAPTION] ), "'", "[" ) )
         cItem += cQuote + aItem[ITEM_CAPTION] + cQuote
      ENDIF
      cItem += "," + LTrim( Str( aItem[ITEM_X1],4 ) ) + "," + LTrim( Str( aItem[ITEM_Y1],4 ) ) + "," + ;
         LTrim( Str( aItem[ITEM_WIDTH],4 ) ) + "," + LTrim( Str( aItem[ITEM_HEIGHT],4 ) ) + ;
         "," + Str( aItem[ITEM_ALIGN], 1 )
      IF aItem[ITEM_TYPE] == TYPE_HLINE .OR. aItem[ITEM_TYPE] == TYPE_VLINE ;
            .OR. aItem[ITEM_TYPE] == TYPE_BOX
         oPen := aItem[ITEM_PEN]
         cItem += ",HPen():Add(" + LTrim( Str( oPen:style ) ) + "," + ;
            LTrim( Str( oPen:width ) ) + "," + LTrim( Str( oPen:color ) ) + ")"
      ELSE
         cItem += ",0"
      ENDIF
      IF aItem[ITEM_TYPE] == TYPE_TEXT
         oFont := aItem[ITEM_FONT]
         cItem += ',HFont():Add( "' + oFont:name + ;
            + '",' + LTrim( Str( oFont:width ) ) + "," + LTrim( Str( oFont:height ) ) ;
            + "," + LTrim( Str( oFont:weight ) ) + "," + LTrim( Str( oFont:charset ) ) ;
            + "," + LTrim( Str( oFont:italic ) ) + "," + LTrim( Str( oFont:underline ) ) ;
            + "," + LTrim( Str( oFont:strikeout ) ) + " )," + Str( aItem[ITEM_VAR], 1 )
      ELSE
         cItem += ",0,0"
      ENDIF
      //cItem += ",0,Nil,0"
      //FWrite( han, "   Aadd( aPaintRep[6], { " + cItem + " } )" + crlf )
      FWrite( han, "   hwg_Hwr_AddItem( aPaintRep, " + cItem + " )" + crlf )

      IF aItem[ITEM_SCRIPT] != Nil .AND. !Empty( aItem[ITEM_SCRIPT] )
         FWrite( han, "   aPaintRep[FORM_ITEMS,Len(aPaintRep[FORM_ITEMS]),12] := ;" + crlf )
         WriteScript( han, aItem[ITEM_SCRIPT], .T. )
      ENDIF
   NEXT

   FWrite( han, "RETURN aPaintRep" + crlf )

   RETURN Nil

STATIC FUNCTION WriteScript( han, cScript, lPrg )
   LOCAL poz := 0, stroka
   LOCAL lastC := Chr( 10 ), cQuote, lFirst := .T.

   IF lPrg == Nil; lPrg := .F. ; ENDIF
   IF cScript != Nil .AND. !Empty( cScript )
      IF !lPrg
         FWrite( han, "#SCRIPT" + Chr( 10 ) )
      ENDIF
      DO WHILE .T.
         stroka := RDSTR( , cScript, @poz )
         IF Len( stroka ) = 0
            IF lPrg
               FWrite( han, Chr( 10 ) )
            ENDIF
            EXIT
         ENDIF
         IF Left( stroka, 1 ) != Chr( 10 )
            IF lPrg
               cQuote := iif( !( '"' $ stroka ), '"', ;
                  iif( !( "'" $ stroka ), "'", "[" ) )
               FWrite( han, iif( lFirst,"",";" + Chr(10 ) ) + Space( 5 ) + ;
                  iif( lFirst, "", "+ " ) + cQuote + stroka + cQuote + "+cEnd" )
               lFirst := .F.
            ELSE
               FWrite( han, iif( Asc(lastC ) < 20,"",Chr(10 ) ) + stroka )
               lastC := Right( stroka, 1 )
            ENDIF
         ENDIF
      ENDDO
      IF !lPrg
         FWrite( han, iif( Asc(lastC ) < 20,"",Chr(10 ) ) + "#ENDSCRIPT" + Chr( 10 ) )
      ENDIF
   ENDIF

   RETURN Nil

   // ================================= EOF of opensave.prg ===================================
