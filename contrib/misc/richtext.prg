/*
 * $Id$
 *
 * Class: RichText
 * Description: System for generating simple RTF files.
 * Original Author: Tom Marchione (1997)
 * Revisions:
 *   2026-09-08 - Added full Unicode (UTF-8).
 *                Fixed shading, style handling, table header validation.
 *                Improved English comments and code consistency.
 *
 * This version requires Harbour (for UTF-8 conversion).
 */

#include "hbclass.ch"
#include "common.ch"
#include "hwgui.ch"
#include "richtext.ch"

CLASS RichText

   DATA cFileName, hFile
   DATA nFontSize
   DATA nFontColor
   DATA aTranslate      // Legacy ANSI translation table (deprecated)
   DATA nFontNum
   DATA nScale
   DATA lTrimSpaces
   DATA nFontAct
   DATA cLastApar INIT ""
   DATA cLastBook INIT ""

   // Table Management
   DATA cTblHAlign, nTblFntNum, nTblFntSize, nTblRows, nTblColumns
   DATA nTblRHgt, aTableCWid, cRowBorder, cCellBorder, aColPct, nCellPct
   DATA lTblNoSplit, nTblHdRows, nTblHdHgt, nTblHdPct, nTblHdFont
   DATA nTblHdFSize, nTblHdColor, nTblHdFColor
   DATA cCellAppear, cHeadAppear
   DATA cCellHAlign, cHeadHAlign
   DATA nCurrRow, nCurrColumn
   DATA TblCJoin

   // TextBox Variables
   DATA txtbox, aSztBox, aCltBox, cTpltBox, nWltBox, nFPtbox
   DATA aOfftbox

   // Facing pages
   DATA lFacing AS LOGICAL INIT .F.

   // Styles Management
   DATA NStlDef INIT 1
   DATA nStlAct INIT 0
   DATA nCharStl INIT 1
   DATA nCharAct INIT 0
   DATA nStlSec INIT 1
   DATA nSectAct INIT 0
   DATA ParStyles AS Array INIT { }
   DATA CharStyles AS Array INIT { }
   DATA SectStyles AS Array INIT { }
   DATA oPrinter

   // Methods
   METHOD New( cFileName, aFontData, aFontFam, aFontChar, nFontSize, nFontColor, nScale, aHigh ) CONSTRUCTOR
   METHOD END() INLINE ::TextCode( "par\pard" ), ::CloseGroup(), FClose( ::hFile )
   METHOD TextCode( cCode )
   METHOD NumCode( cCode, nValue, lScale )
   METHOD LogicCode( cCode, lTest )
   METHOD Write( xData, lCodesOK )
   METHOD OpenGroup() INLINE FWrite( ::hFile, "{" )
   METHOD CloseGroup() INLINE FWrite( ::hFile, "}" )
   METHOD NewSection( lLandscape, nColumns, nLeft, nRight, nTop, nBottom, ;
         nWidth, nHeight, cVertAlign, lDefault )
   METHOD PageSetup( nLeft, nRight, nTop, nBottom, nWidth, nHeight, ;
         nTabWidth, lLandscape, lNoWidow, cVertAlign, ;
         cPgNumPos, lPgNumTop )
   METHOD BeginHeader() INLINE ::OpenGroup(), ;
         IIf( ! ::lFacing, ::TextCode( "header \pard" ), ::TextCode( "headerr \pard" ) )
   METHOD EndHeader() INLINE ::TextCode( "par" ), ::CloseGroup()
   METHOD BeginFooter() INLINE ::OpenGroup(), ;
         IIf( ! ::lFacing, ::TextCode( "footer \pard" ), ::TextCode( "footerr \pard" ) )
   METHOD EndFooter() INLINE ::TextCode( "par" ), ::CloseGroup()
   METHOD Paragraph( cText, nFontNumber, nFontSize, cAppear, ;
         cHorzAlign, aTabPos, nIndent, nFIndent, nRIndent, nSpace, ;
         lSpExact, nBefore, nAfter, lNoWidow, lBreak, ;
         lBullet, cBulletChar, lHang, lDefault, lNoPar, ;
         nFontColor, cTypeBorder, cBordStyle, nBordCol, nShdPct, cShadPat, ;
         nStyle, lChar )
   METHOD DefineTable( cTblHAlign, nTblFntNum, nTblFntSize, ;
         cCellAppear, cCellHAlign, nTblRows, ;
         nTblColumns, nTblRHgt, aTableCWid, cRowBorder, cCellBorder, aColPct, nCellPct, ;
         lTblNoSplit, nTblHdRows, nTblHdHgt, nTblHdPct, nTblHdFont, ;
         nTblHdFSize, cHeadAppear, cHeadHAlign, nTblHdColor , nTblHdFColor )
   METHOD BeginRow() INLINE ::TextCode( "trowd" ), ::nCurrRow += 1
   METHOD EndRow()   INLINE ::TextCode( "row" )
   METHOD WriteCell( cText, nFontNumber, nFontSize, cAppear, cHorzAlign, ;
         nSpace, lSpExact, cCellBorder, nCellPct, nFontColor, lDefault )
   METHOD Appearance( cAppear )
   METHOD HAlignment( cAlign )
   METHOD LineSpacing( nSpace, lSpExact )
   METHOD Borders( cEntity, cBorder )
   METHOD NewFont( nFontNumber )
   METHOD SetFontSize( nFontSize )
   METHOD SetFontColor( nFontColor )
   METHOD NewLine() INLINE FWrite( ::hFile, hb_Eol() ), ::TextCode( "par" )
   METHOD NewPage() INLINE ::TextCode( "page" + hb_Eol() )
   METHOD NumPage() INLINE ::TextCode( "chpgn" )
   METHOD CurrDate( cFormat )
   METHOD BorderCode( cBorderID )
   METHOD ShadeCode( cShadeID )
   METHOD ParaBorder( cBorder, cType )
   METHOD BegBookMark( texto )
   METHOD EndBookMark()
   METHOD SetStlDef()
   METHOD IncStyle( cName, styletype, nFontNumber, nFontSize, ;
         nFontColor, cAppear, cHorzAlign, nIndent, cKeys, ;
         cTypeBorder, cBordStyle, nBordColor, nShdPct, cShadPat, lAdd, LUpdate )
   METHOD BeginStly()
   METHOD WriteStly()
   METHOD ParaStyle( nStyle )
   METHOD CharStyle( nStyle )
   METHOD FootNote( cTexto, cChar, nFontNumber, nFontSize, cAppear, nFontColor, lEnd, lAuto, lUpper )
   METHOD BegTextBox( cTexto, aOffset, ASize, cTipo, aColores, nWidth, nPatron, ;
         lSombra, aSombra, nFontNumber, nFontSize, cAppear, nFontColor, nIndent, lRounded, lEnd )
   METHOD EndTextBox()
   METHOD SetFrame( ASize, cHorzAlign, cVertAlign, lNoWrap, cXAlign, xpos, cYAlign, ypos )
   METHOD RtfImage( cName, aSize, nPercent )
   METHOD Wmf2Rtf( cName, aSize, nPercent )
   METHOD Bmp2Wmf( cName, aSize, nPercent )
   METHOD SetClrTab()
   METHOD Linea( aInicio, aFinal, nxoffset, nyoffset, ASize, cTipo, ;
         aColores, nWidth, nPatron, lSombra, aSombra )
   METHOD Image( cName, ASize, nPercent, lCell, lInclude, lFrame, aFSize, cHorzAlign, ;
         cVertAlign, lNoWrap, cXAlign, xpos, cYAlign, ypos )
   METHOD InfoDoc( cTitle, cSubject, cAuthor, cManager, cCompany, cOperator, ;
         cCategor, cKeyWords, cComment )
   METHOD DocFormat( nTab, nLineStart, lBackup, nDefLang, nDocType, ;
         cFootType, cFootNotes, cEndNotes, cFootNumber, nPage, cProtect, lFacing, nGutter )
   METHOD EndTable() INLINE ::CloseGroup()
   METHOD TableDef( lHeader, nRowHead, cCellBorder, aColPct )
   METHOD TableCell( cText, nFontNumber, nFontSize, cAppear, cHorzAlign, ;
         nSpace, lSpExact, nFontColor, ;
         lDefault, lHeader, lPage, lDate )
   METHOD CellFormat( cCellBorder, aCellPct )
   METHOD DefNewTable( cTblHAlign, nTblFntNum, nTblFntSize, ;
         cCellAppear, cCellHAlign, nTblRows, ;
         nTblColumns, nTblRHgt, aTableCWid, cRowBorder, cCellBorder, aColPct, nCellPct, ;
         lTblNoSplit, nTblHdRows, aHeadTit, nTblHdHgt, nTblHdPct, nTblHdFont, ;
         nTblHdFSize, cHeadAppear, cHeadHAlign, nTblHdColor , nTblHdFColor, aTblCJoin )

   HIDDEN:
   DATA nFile INIT 1
   DATA lUnicode INIT .T.   // Enable Unicode (UTF-8) by default

ENDCLASS

METHOD New( cFileName, aFontData, aFontFam, aFontChar, nFontSize, nFontColor, nScale, aHigh ) CLASS RichText
   LOCAL i
   LOCAL cTopFile := "rtf1\ansi\ansicpg65001\deff0"   // UTF-8 code page
   LOCAL cColors  := ::SetClrTab()

   DEFAULT ;
   cFileName TO "REPORT.RTF", ;
   aFontData TO { "Courier New" }, ;
   nFontSize TO 12, ;
   nScale    TO INCH_TO_TWIP, ;
   nFontColor TO 0

   ::cFileName := cFileName
   ::nFontSize := nFontSize
   ::nScale    := nScale
   ::nFontColor := nFontColor
   ::lTrimSpaces := .F.

   IF aFontFam == NIL
      aFontFam := Array( aFontData )
      AFill( aFontFam, "fNIL" )
   ENDIF
   IF aFontChar == NIL
      aFontChar := Array( aFontData )
      AFill( aFontChar, 0 )
   ENDIF

   IF ValType( aHigh ) == "A"
      ::aTranslate := aHigh
   ENDIF

   IF ! ( "." $ ::cFileName )
      ::cFileName += ".RTF"
   ENDIF

   ::hFile := FCreate( ::cFileName )
   ::oPrinter := NIL

   IF ::hFile >= 0
      ::OpenGroup()
      ::TextCode( cTopFile )
      ::nFontNum := Len( aFontData )
      ::OpenGroup()
      ::TextCode( "fonttbl" )
      FOR i := 1 TO ::nFontNum
         ::OpenGroup()
         ::NewFont( i )
         ::NumCode( "charset", aFontChar[ i ], .F. )
         ::TextCode( aFontFam[ i ] )
         ::Write( aFontData[ i ] + ";" )
         ::CloseGroup()
      NEXT
      ::CloseGroup()
      ::OpenGroup()
      ::TextCode( cColors )
      ::CloseGroup()
   ENDIF

   RETURN Self

METHOD PageSetup( nLeft, nRight, nTop, nBottom, nWidth, nHeight, ;
      nTabWidth, lLandscape, lNoWidow, cVertAlign, ;
      cPgNumPos, lPgNumTop ) CLASS RichText

   HB_SYMBOL_UNUSED( cPgNumPos )

   DEFAULT lLandscape TO .F.
   DEFAULT lNoWidow TO .F.
   DEFAULT lPgNumTop TO .F.

   ::LogicCode( "landscape", lLandscape )
   ::NumCode( "paperw", nWidth )
   ::NumCode( "paperh", nHeight )
   ::LogicCode( "widowctrl", lNoWidow )
   ::NumCode( "margl", nLeft )
   ::NumCode( "margr", nRight )
   ::NumCode( "margt", nTop )
   ::NumCode( "margb", nBottom )
   ::NumCode( "deftab", nTabWidth )

   IF ! Empty( cVertAlign )
      ::TextCode( "vertal" + Lower( Left( cVertAlign, 1 ) ) )
   ENDIF

   ::SetFontSize( ::nFontSize )

   RETURN NIL

METHOD Paragraph( cText, nFontNumber, nFontSize, cAppear, ;
      cHorzAlign, aTabPos, nIndent, nFIndent, nRIndent, nSpace, ;
      lSpExact, nBefore, nAfter, lNoWidow, lBreak, ;
      lBullet, cBulletChar, lHang, lDefault, lNoPar, ;
      nFontColor, cTypeBorder, cBordStyle, nBordCol, nShdPct, cShadPat, ;
      nStyle, lChar ) CLASS RichText

   LOCAL i

   DEFAULT ;
   lDefault TO .F., ;
   lNoWidow TO .F., ;
   lBreak TO .F., ;
   lBullet TO .F., ;
   lHang TO .F., ;
   cAppear TO "", ;
   cHorzAlign TO "", ;
   cBulletChar TO "\bullet", ;
   lNoPar TO .F., ;
   nFontColor TO 0, ;
   cTypeBorder TO NIL, ;
   cBordStyle TO "SINGLE", ;
   nBordCol TO 0, ;
   nShdPct TO 0, ;
   cShadPat TO "", ;
   lChar TO .F., ;
   nStyle TO 0

   /* FIX: Shading value - ensure it's in 0..10000 range */
   IF nShdPct > 0
      IF nShdPct < 1
         nShdPct := nShdPct * 10000   // assume fraction (0.5 -> 5000)
      ELSEIF nShdPct <= 100
         nShdPct := nShdPct * 100     // assume percent (50 -> 5000)
      ENDIF
   ENDIF

   ::LogicCode( "pagebb", lBreak )

   IF ! lNoPar
      ::TextCode( "par" )
   ENDIF

   ::LogicCode( "pard", lDefault )

   IF ! lChar
      ::ParaStyle( nStyle )
   ENDIF

   ::NewFont( nFontNumber )
   ::SetFontSize( nFontSize )
   ::SetFontColor( nFontColor )
   ::Appearance( cAppear )
   ::HAlignment( cHorzAlign )

   IF ValType( aTabPos ) == "A"
      AEval( aTabPos, { | x | ::NumCode( "tx", x ) } )
   ENDIF

   ::NumCode( "li", nIndent )
   ::NumCode( "fi", nFIndent )
   ::NumCode( "ri", nRIndent )
   ::LineSpacing( nSpace, lSpExact )

   ::NumCode( "sb", nBefore )
   ::NumCode( "sa", nAfter )
   ::LogicCode( "keep", lNoWidow )

   IF cTypeBorder # NIL
      IF AScan( cTypeBorder, "ALL" ) # 0
         ::ParaBorder( "ALL", cBordStyle )
      ELSEIF AScan( cTypeBorder, "CHARACTER" ) # 0
         ::ParaBorder( "CHARACTER", cBordStyle )
      ELSE
         FOR i = 1 TO Len( cTypeBorder )
            ::ParaBorder( cTypeBorder[ i ], cBordStyle )
         NEXT i
      ENDIF
   ENDIF

   IF lBullet
      ::OpenGroup()
      ::TextCode( "*" )
      ::TextCode( "pnlvlblt" )
      ::LogicCode( "pnhang", lHang )
      ::TextCode( "pntxtb " + cBulletChar )
      ::CloseGroup()
   ENDIF

   IF nShdPct > 0
      ::NumCode( IIf( ! lChar, "shading", "chshdng" ), nShdPct, .F. )
      IF ! Empty( cShadPat )
         ::TextCode( "bg" + ::ShadeCode( cShadPat ) )
      ENDIF
   ENDIF

   ::Write( cText )

   IF lChar
      IF cTypeBorder # NIL
         ::TextCode( "chrbdr" )
      ENDIF
      IF nShdPct > 0
         ::NumCode( "chshdng", 0 )
      ENDIF
      ::CharStyle( nStyle )
   ENDIF

   RETURN NIL

METHOD SetFontSize( nFontSize ) CLASS RichText
   IF ValType( nFontSize ) == "N"
      ::nFontSize := nFontSize
      ::NumCode( "fs", ::nFontSize * 2, .F. )
   ENDIF
   RETURN NIL

METHOD SetFontColor( nFontColor ) CLASS RichText
   IF ValType( nFontColor ) == "N"
      ::nFontColor := nFontColor
      ::NumCode( "cf", ::nFontColor, .F. )
   ENDIF
   RETURN NIL

/* ----------------------------------------------------------------------
   Write(): Enhanced to support Unicode (UTF-8) using Harbour native
   functions. Converts input string to UTF-8 if needed, then iterates
   over Unicode characters, generating \u escapes for non-ASCII.
---------------------------------------------------------------------- */
METHOD Write( xData, lCodesOK ) CLASS RichText
   LOCAL cWrite := ""
   LOCAL cString, cUtf8, cChar, nCode, i, nLen
   LOCAL aCodes := { "\", "{", "}" }

   DEFAULT lCodesOK TO .F.

   cString := cStr( xData )   // convert to string

   IF ::lTrimSpaces
      cString := RTrim( cString )
   ENDIF

   /* Ensure we work with UTF-8 internally */
   IF ! hb_StrIsUTF8( cString )
      cUtf8 := hb_StrToUTF8( cString )
   ELSE
      cUtf8 := cString
   ENDIF

   /* Iterate over characters (not bytes) */
   nLen := hb_utf8Len( cUtf8 )
   FOR i := 1 TO nLen
      cChar := hb_utf8SubStr( cUtf8, i, 1 )
      nCode := hb_utf8Asc( cChar )

      IF nCode < 128
         /* ASCII: handle control chars and escaping */
         IF nCode > 91
            IF ! lCodesOK
               IF AScan( aCodes, Chr( nCode ) ) > 0
                  cWrite += "\" + Chr( nCode )
                  LOOP
               ENDIF
            ENDIF
         ELSEIF nCode < 33
            IF nCode == 13
               cWrite += "\par "
               LOOP
            ELSEIF nCode == 10
               LOOP
            ENDIF
         ENDIF
         cWrite += Chr( nCode )
      ELSE
         /* Non-ASCII: use \u escape (decimal Unicode code point) */
         cWrite += "\u" + AllTrim( Str( nCode ) ) + "?"
      ENDIF
   NEXT

   ::OpenGroup()
   FWrite( ::hFile, cWrite )
   ::CloseGroup()

   RETURN NIL

METHOD NumCode( cCode, nValue, lScale ) CLASS RichText
   LOCAL cWrite := ""

   IF ValType( cCode ) == "C" .AND. ValType( nValue ) == "N"
      cCode := FormatCode( cCode )
      cWrite += cCode
      DEFAULT lScale TO .T.
      IF lScale
         nValue := Int( nValue * ::nScale )
      ENDIF
      cWrite += AllTrim( Str( nValue ) )
      FWrite( ::hFile, cWrite )
   ENDIF

   RETURN cWrite

METHOD LogicCode( cCode, lTest ) CLASS RichText
   LOCAL cWrite := ""
   IF ValType( cCode ) == "C" .AND. ValType( lTest ) == "L"
      IF lTest
         cWrite := ::TextCode( cCode )
      ENDIF
   ENDIF
   RETURN cWrite

FUNCTION FormatCode( cCode )
   cCode := AllTrim( cCode )
   IF ! ( Left( cCode, 1 ) == "\" )
      cCode := "\" + cCode
   ENDIF
   RETURN cCode

METHOD DefineTable( cTblHAlign, nTblFntNum, nTblFntSize, ;
      cCellAppear, cCellHAlign, nTblRows, ;
      nTblColumns, nTblRHgt, aTableCWid, cRowBorder, cCellBorder, aColPct, nCellPct, ;
      lTblNoSplit, nTblHdRows, nTblHdHgt, nTblHdPct, nTblHdFont, ;
      nTblHdFSize, cHeadAppear, cHeadHAlign, nTblHdColor , nTblHdFColor ) CLASS RichText

   LOCAL i

   DEFAULT ;
   cTblHAlign TO "CENTER", ;
   nTblFntNum TO 1, ;
   nTblFntSize TO ::nFontSize, ;
   nTblRows TO 1, ;
   nTblColumns TO 1, ;
   nTblRHgt TO NIL, ;
   aTableCWid  TO  Array( nTblColumns ), ;
   cRowBorder  TO  "NONE", ;
   cCellBorder  TO  "SINGLE", ;
   lTblNoSplit  TO  .F., ;
   nCellPct  TO  0, ;
   nTblHdRows  TO  0, ;
   nTblHdHgt  TO  nTblRHgt, ;
   nTblHdPct  TO  0, ;
   nTblHdFont  TO  nTblFntNum, ;
   nTblHdFSize  TO  ::nFontSize + 2, ;
   nTblHdColor   TO  0, ;
   nTblHdFColor  TO  0

   IF aTableCWid[ 1 ] == NIL
      AFill( aTableCWid, 6.5 / nTblColumns )
   ELSEIF ValType( aTableCWid[ 1 ] ) == "A"
      aTableCWid := AClone( aTableCWid[ 1 ] )
   ENDIF

   FOR i := 2 TO Len( aTableCWid )
      aTableCWid[ i ] += aTableCWid[ i - 1 ]
   NEXT

   IF aColPct == NIL
      aColPct   := Array( nTblColumns )
      AFill( aColPct, 0 )
   ENDIF

   ::cTblHAlign := Lower( Left( cTblHAlign, 1 ) )
   ::nTblFntNum := nTblFntNum
   ::nTblFntSize := nTblFntSize
   ::cCellAppear := cCellAppear
   ::cCellHAlign := cCellHAlign
   ::nTblRows := nTblRows
   ::nTblColumns := nTblColumns
   ::nTblRHgt := nTblRHgt
   ::aTableCWid := aTableCWid
   ::cRowBorder := ::BorderCode( cRowBorder )
   ::cCellBorder := ::BorderCode( cCellBorder )
   ::aColPct := AClone( aColPct )
   ::nCellPct := IIf( nCellPct < 1, nCellPct * 10000, nCellPct * 100 )
   i := 1
   AEval( ::aColPct, { || ::aColPct[ i ] := IIf( ::aColPct[ i ] < 1, ::aColPct[ i ] * 10000, ;
         ::aColPct[ i ] * 100 ), i ++ } )
   ::lTblNoSplit := lTblNoSplit
   ::nTblHdRows := nTblHdRows
   ::nTblHdHgt := nTblHdHgt
   ::nTblHdPct := IIf( nTblHdPct < 1, nTblHdPct * 10000, nTblHdPct * 100 )
   ::nTblHdFont := nTblHdFont
   ::nTblHdFSize := nTblHdFSize
   ::nTblHdColor := nTblHdColor
   ::nTblHdFColor := nTblHdFColor
   ::cHeadAppear := cHeadAppear
   ::cHeadHAlign := cHeadHAlign
   ::nCurrColumn := 0
   ::nCurrRow    := 0

   RETURN NIL

METHOD WriteCell( cText, nFontNumber, nFontSize, cAppear, cHorzAlign, ;
      nSpace, lSpExact, cCellBorder, nCellPct, nFontColor, lDefault ) CLASS RichText

   LOCAL i

   HB_SYMBOL_UNUSED( cCellBorder )
   HB_SYMBOL_UNUSED( nCellPct )

   DEFAULT cText TO "", ;
   lDefault TO .F.

   IF ::nCurrColumn == ::nTblColumns
      ::nCurrColumn := 1
   ELSE
      ::nCurrColumn += 1
   ENDIF

   IF ::nCurrColumn == 1
      IF ::nCurrRow == 0 .AND. ::nTblHdRows > 0
         ::OpenGroup()
         ::BeginRow()
         ::TextCode( "trgaph108\trleft-108" )
         ::TextCode( "trq" + ::cTblHAlign )
         ::Borders( "tr", ::cRowBorder )
         ::NumCode( "trrh", ::nTblHdHgt )
         ::TextCode( "trhdr" )
         ::LogicCode( "trkeep", ::lTblNoSplit )
         FOR i := 1 TO Len( ::aTableCWid )
            ::NumCode( "clshdng", ::nTblHdPct, .F. )
            IF ::nTblHdColor > 0
               ::NumCode( "clcbpat", ::nTblHdColor, .F. )
            ENDIF
            ::Borders( "cl", ::cCellBorder )
            ::NumCode( "cellx", ::aTableCWid[ i ] )
         NEXT
         ::NewFont( ::nTblHdFont )
         ::SetFontSize( ::nTblHdFSize )
         IF ::nTblHdFColor > 0
            ::SetFontColor( ::nTblHdFColor )
         ENDIF
         ::Appearance( ::cHeadAppear )
         ::HAlignment( ::cHeadHAlign )
         ::TextCode( "intbl" )
      ELSEIF ::nCurrRow == ::nTblHdRows
         IF ::nTblHdRows > 0
            ::EndRow()
            ::CloseGroup()
         ENDIF
         ::BeginRow()
         ::TextCode( "trgaph108\trleft-108" )
         ::TextCode( "trq" + ::cTblHAlign )
         ::Borders( "tr", ::cRowBorder )
         ::NumCode( "trrh", ::nTblRHgt )
         ::LogicCode( "trkeep", ::lTblNoSplit )
         FOR i := 1 TO Len( ::aTableCWid )
            ::NumCode( "clshdng", ::aColPct[ i ], .F. )
            ::Borders( "cl", ::cCellBorder )
            ::NumCode( "cellx", ::aTableCWid[ i ] )
         NEXT
         ::NewFont( ::nTblFntNum )
         ::SetFontSize( ::nTblFntSize )
         ::Appearance( ::cCellAppear )
         ::HAlignment( ::cCellHAlign )
         ::TextCode( "intbl" )
      ELSE
         ::EndRow()
         ::TextCode( "intbl" )
      ENDIF
   ENDIF

   ::OpenGroup()
   ::LogicCode( "pard", lDefault )
   ::NewFont( nFontNumber )
   ::SetFontSize( nFontSize )
   ::SetFontColor( nFontColor )
   ::Appearance( cAppear )
   ::HAlignment( cHorzAlign )
   ::LineSpacing( nSpace, lSpExact )
   ::Write( cText )
   ::CloseGroup()
   ::TextCode( "cell" )

   RETURN NIL

METHOD NewSection( lLandscape, nColumns, nLeft, nRight, nTop, nBottom, ;
      nWidth, nHeight, cVertAlign, lDefault ) CLASS RichText

   DEFAULT lDefault TO .F.

   ::TextCode( "sect" )
   IF lDefault
      ::TextCode( "sectd" )
   ENDIF
   ::LogicCode( "lndscpsxn", lLandscape )
   ::NumCode( "cols", nColumns, .F. )
   ::NumCode( "marglsxn", nLeft )
   ::NumCode( "margrsxn", nRight )
   ::NumCode( "margtsxn", nTop )
   ::NumCode( "margbsxn", nBottom )
   ::NumCode( "pgwsxn", nWidth )
   ::NumCode( "pghsxn", nHeight )

   IF ! Empty( cVertAlign )
      ::TextCode( "vertal" + Lower( Left( cVertAlign, 1 ) ) )
   ENDIF

   ::TextCode( "sbkpage" )
   ::TextCode( "pgncont" )
   ::TextCode( "pgndec" )

   RETURN NIL

METHOD NewFont( nFontNumber ) CLASS RichText
   IF ! Empty( nFontNumber ) .AND. nFontNumber <= ::nFontNum
      ::NumCode( "f", nFontNumber - 1, .F. )
      ::nFontAct := nFontNumber
   ENDIF
   RETURN NIL

METHOD Appearance( cAppear ) CLASS RichText
   LOCAL cWrite := ""
   IF ! Empty( cAppear )
      cWrite := ::TextCode( SubStr( cAppear, 2 ) )
      ::cLastApar := cAppear
   ENDIF
   RETURN cWrite

METHOD HAlignment( cAlign ) CLASS RichText
   IF ! Empty( cAlign )
      ::TextCode( "q" + Lower( Left( cAlign, 1 ) ) )
   ENDIF
   RETURN NIL

METHOD LineSpacing( nSpace, lSpExact ) CLASS RichText
   DEFAULT lSpExact TO .F.
   ::NumCode( "sl", nSpace, lSpExact )
   IF ! Empty( nSpace )
      ::NumCode( "slmult", IIf( lSpExact, 0, 1 ), .F. )
   ENDIF
   RETURN NIL

METHOD Borders( cEntity, cBorder ) CLASS RichText
   LOCAL i, aBorder := { "t", "b", "l", "r" }
   IF ValType( cBorder ) == "C"
      FOR i := 1 TO 4
         ::TextCode( cEntity + "brdr" + aBorder[ i ] + "\brdr" + cBorder )
      NEXT
   ENDIF
   RETURN NIL

METHOD ParaBorder( cBorder, cType ) CLASS RichText
   LOCAL codigo
   cBorder := Upper( AllTrim( cBorder ) )
   DO CASE
   CASE cBorder == "CHARACTER"
      codigo := "chbrdr"
   CASE cBorder == "ALL"
      codigo := "box"
   CASE cBorder == "TOP"
      codigo := "brdrt"
   CASE cBorder == "BOTTOM"
      codigo := "brdrb"
   CASE cBorder == "LEFT"
      codigo := "brdrl"
   CASE cBorder == "RIGHT"
      codigo := "RIGHT"
   ENDCASE
   RETURN ::TextCode( codigo + "\brdr" + ::BorderCode( cType ) )

METHOD BorderCode( cBorderID ) CLASS RichText
   LOCAL cBorderCode := "", n
   LOCAL aBorder := ;
         { ;
         { "NONE",        NIL   }, ;
         { "SINGLE",      "s"   }, ;
         { "DOUBLETHICK", "th"  }, ;
         { "SHADOW",      "sh"  }, ;
         { "DOUBLE",      "db"  }, ;
         { "DOTTED",      "dot" }, ;
         { "DASHED",      "dash" }, ;
         { "HAIRLINE",    "hair" }  ;
         }
   cBorderID := Upper( RTrim( cBorderID ) )
   n := AScan( aBorder, { | x | x[ 1 ] == cBorderID } )
   IF n > 0
      cBorderCode := aBorder[ n ][ 2 ]
   ENDIF
   RETURN cBorderCode

METHOD ShadeCode( cShadeID ) CLASS RichText
   LOCAL cShadeCode := "", n
   LOCAL aShade := ;
         { ;
         { "NONE",         ""        }, ;
         { "HORIZ",        "horiz"   }, ;
         { "VERT",         "vert"    }, ;
         { "CROSS",        "cross"   }, ;
         { "FORDIAG",      "fdiag"   }, ;
         { "BACKDIAG",     "bdiag"      } ;
         }
   cShadeID := Upper( RTrim( cShadeID ) )
   n := AScan( aShade, { | x | x[ 1 ] == cShadeID } )
   IF n > 0
      cShadeCode := aShade[ n ][ 2 ]
   ENDIF
   RETURN cShadeCode

FUNCTION IntlTranslate()
   LOCAL i
   LOCAL aTranslate[ 128 ]
   LOCAL aHighTable := ;
         { ;
         "\'fc", "\'e9", "\'e2", "\'e4", "\'e0", "\'e5", "\'e7", "\'ea", ;
         "\'eb", "\'e8", "\'ef", "\'ee", "\'ec", "\'c4", "\'c5", "\'c9", ;
         "\'e6", "\'c6", "\'f4", "\'f6", "\'f2", "\'fb", "\'f9", "\'ff", ;
         "\'d6", "\'dc", "\'a2", "\'a3", "\'a5", "\'83", "\'ed", "\'e1", ;
         "\'f3", "\'fa", "\'f1", "\'d1", "\'aa", "\'ba", "\'bf" ;
         }
   AFill( aTranslate, "" )
   FOR i := 1 TO Len( aHighTable )
      aTranslate[ i ] := aHighTable[ i ]
   NEXT
   RETURN aTranslate

FUNCTION NewBase( nDec, nBase )
   LOCAL cNewBase := "", nDividend, nRemain, lContinue := .T., cRemain
   DO WHILE lContinue
      nDividend := Int( nDec / nBase )
      nRemain := nDec % nBase
      IF nDividend >= 1
         nDec := nDividend
      ELSE
         lContinue := .F.
      ENDIF
      IF nRemain < 10
         cRemain := AllTrim( Str( nRemain, 2, 0 ) )
      ELSE
         cRemain := Chr( nRemain + 55 )
      ENDIF
      cNewBase := cRemain + cNewBase
   ENDDO
   RETURN cNewBase

METHOD BegBookMark( texto )  CLASS RichText
   DEFAULT texto TO "marca"
   ::cLastBook := StrTran( texto, " ", "_" )
   ::OpenGroup()
   ::TextCode( "*\bkmkstart " + Lower( ::cLastBook ) )
   ::CloseGroup()
   RETURN NIL

METHOD EndBookMark()  CLASS RichText
   ::OpenGroup()
   ::TextCode( "*\bkmkend " + Lower( ::cLastBook ) )
   ::CloseGroup()
   RETURN NIL

METHOD Linea( aInicio, aFinal, nxoffset, nyoffset, ASize, cTipo, ;
      aColores, nWidth, nPatron, lSombra, aSombra ) CLASS RichText

   DEFAULT cTipo TO "SOLIDA", ;
         nxoffset TO 0, ;
         nyoffset TO 0, ;
         nWidth TO  0.01, ;
         aColores TO { 0, 0, 0 }, ;
         ASize TO { 2.0, 0 }, ;
         nPatron TO 1, ;
         lSombra TO .F., ;
         aSombra TO { 0, 0 }

   ::OpenGroup()
   ::TextCode( "do\dobxmargin\dobypara\dpline" )
   ::NumCode( "dpptx", aInicio[ 1 ], .T. )
   ::NumCode( "dppty", aInicio[ 2 ], .T. )
   ::NumCode( "dpptx", aFinal[ 1 ], .T. )
   ::NumCode( "dppty", aFinal[ 2 ], .T. )
   ::NumCode( "dpx", nxoffset, .T. )
   ::NumCode( "dpy", nyoffset, .T. )
   ::NumCode( "dpxsize", ASize[ 1 ], .T. )
   ::NumCode( "dpysize", ASize[ 2 ], .T. )
   DO CASE
   CASE cTipo == "SOLIDA"
      ::TextCode( "dplinesolid" )
   CASE cTipo == "PUNTOS"
      ::TextCode( "dplinedot" )
   CASE cTipo == "LINEAS"
      ::TextCode( "dplinedash" )
   CASE cTipo == "PUNTOLINEA"
      ::TextCode( "dplinedado" )
   ENDCASE
   ::NumCode( "dplinecob", aColores[ 1 ], .F. )
   ::NumCode( "dplinecog", aColores[ 2 ], .F. )
   ::NumCode( "dplinecor", aColores[ 3 ], .F. )
   ::NumCode( "dplinew", nWidth, .T. )
   ::NumCode( "dpfillpat", nPatron, .F. )
   ::LogicCode( "dpshadow", lSombra )
   IF lSombra
      ::NumCode( "dpshadx", aSombra[ 1 ], .T. )
      ::NumCode( "dpshady", aSombra[ 2 ], .T. )
   ENDIF
   ::CloseGroup()
   RETURN NIL

METHOD SetClrTab() CLASS RichText
   LOCAL colors
   colors := "colortbl;\red0\green0\blue0;\red0\green0\blue128;\red0\green128\blue0;"
   colors += "\red0\green128\blue128;\red128\green0\blue0;\red128\green0\blue128;\red128\green128\blue0;"
   colors += "\red192\green192\blue192;\red128\green128\blue128;\red0\green0\blue255;"
   colors += "\red0\green255\blue0;\red0\green255\blue255;\red255\green0\blue0;"
   colors += "\red255\green0\blue255;\red255\green255\blue0;\red255\green255\blue255;"
   RETURN colors

METHOD SetStlDef() CLASS Richtext
   ::IncStyle( "Normal" )
   ::IncStyle( "Default Paragraph Font", "CHARACTER" )
   RETURN NIL

METHOD InfoDoc( cTitle, cSubject, cAuthor, cManager, cCompany, cOperator, ;
      cCategor, cKeyWords, cComment ) CLASS RichText

   DEFAULT cTitle TO "Informe", ;
         cSubject TO "", ;
         cAuthor TO "", ;
         cManager TO "", ;
         cCompany TO "", ;
         cOperator TO "", ;
         cCategor TO "", ;
         cKeyWords TO "", ;
         cComment TO ""

   ::OpenGroup()
   ::TextCode( "info" )
   ::OpenGroup() ; ::TextCode( "title " + cTitle ) ; ::CloseGroup()
   ::OpenGroup() ; ::TextCode( "subject " + cSubject ) ; ::CloseGroup()
   ::OpenGroup() ; ::TextCode( "author " + cAuthor ) ; ::CloseGroup()
   ::OpenGroup() ; ::TextCode( "manager " + cManager ) ; ::CloseGroup()
   ::OpenGroup() ; ::TextCode( "company " + cCompany ) ; ::CloseGroup()
   ::OpenGroup() ; ::TextCode( "operator " + cOperator ) ; ::CloseGroup()
   ::OpenGroup() ; ::TextCode( "category " + cCategor ) ; ::CloseGroup()
   ::OpenGroup() ; ::TextCode( "keywords " + cKeyWords ) ; ::CloseGroup()
   ::OpenGroup() ; ::TextCode( "comment " + cComment ) ; ::CloseGroup()
   ::CloseGroup()
   RETURN NIL

METHOD FootNote( cTexto, cChar, nFontNumber, ;
      nFontSize, cAppear, nFontColor, lEnd, lAuto, lUpper ) CLASS RichText

   DEFAULT cTexto TO "", ;
         cChar TO "*", ;
         nFontNumber TO 0, ;
         nFontSize TO 8, ;
         cAppear TO "", ;
         nFontColor TO 0, ;
         lUpper TO .T., ;
         lAuto TO .F., ;
         lEnd TO .F.

   cChar := IIf( lAuto, "", cChar )
   ::OpenGroup()
   ::OpenGroup()
   IF lUpper
      ::TextCode( "super " + cChar )
   ELSE
      IF ! Empty( cChar )
         ::Write( cChar )
      ENDIF
   ENDIF
   IF lAuto ; ::TextCode( "chftn" ) ; ENDIF
   ::CloseGroup()
   ::OpenGroup()
   ::TextCode( "footnote" )
   IF lEnd ; ::TextCode( "ftnalt" ) ; ENDIF
   ::NewFont( nFontNumber )
   ::SetFontSize( nFontSize )
   ::SetFontColor( nFontColor )
   ::Appearance( cAppear )
   ::OpenGroup()
   IF lUpper
      ::TextCode( "super " + cChar )
   ELSE
      IF ! Empty( cChar )
         ::Write( cChar )
      ENDIF
   ENDIF
   IF lAuto ; ::TextCode( "chftn" ) ; ENDIF
   ::CloseGroup()
   ::Write( cTexto )
   ::CloseGroup()
   ::CloseGroup()
   RETURN NIL

METHOD BegTextBox( cTexto, aOffset, ASize, cTipo, aColores, nWidth, nPatron, ;
      lSombra, aSombra, nFontNumber, nFontSize, cAppear, nFontColor, nIndent, lRounded, lEnd ) CLASS RichText

   DEFAULT cTexto TO "", ;
         aOffset TO { 0, 0 }, ;
         ASize TO { 2.0, 1.0 }, ;
         cTipo TO "SOLIDA", ;
         aColores TO { 0, 0, 0 }, ;
         nWidth TO 20, ;
         nPatron TO 1, ;
         lEnd TO .F., ;
         lRounded TO .F., ;
         lSombra TO .F., ;
         aSombra TO { 0, 0 }

   ::aOfftBox := aOffset
   ::aSztBox := ASize
   ::aCltBox := aColores
   ::cTpltBox := cTipo
   ::nWltBox := nWidth
   ::nFPtbox := nPatron
   ::OpenGroup()
   ::TextCode( "do\dobxmargin\dobypara\dptxbx\dptxbxmar40" )
   ::logicCode( "dproundr", lRounded )
   ::LogicCode( "dpshadow", lSombra )
   IF lSombra
      ::NumCode( "dpshadx", aSombra[ 1 ], .T. )
      ::NumCode( "dpshadx", aSombra[ 2 ], .T. )
   ENDIF
   ::OpenGroup()
   ::TextCode( "dptxbxtext \s0\ql" )
   IF ! Empty( cTexto )
      ::Paragraph( cTexto, nFontNumber, nFontSize, cAppear, ;
            ,, nIndent,,,,,,,,,,,, .F., .T. , nFontColor )
   ENDIF
   IF lEnd
      ::EndTextBox()
   ENDIF
   RETURN NIL

METHOD EndTextBox() CLASS RichText
   ::CloseGroup()
   ::NumCode( "dpx", ::aOfftbox[ 1 ], .T. )
   ::NumCode( "dpy", ::aOfftbox[ 2 ], .T. )
   ::NumCode( "dpxsize", ::aSztBox[ 1 ], .T. )
   ::NumCode( "dpysize", ::aSztBox[ 2 ], .T. )
   DO CASE
   CASE ::cTpltBox == "SOLIDA"
      ::TextCode( "dplinesolid" )
   CASE ::cTpltBox == "PUNTOS"
      ::TextCode( "dplinedot" )
   CASE ::cTpltBox == "LINEAS"
      ::TextCode( "dplinedash" )
   CASE ::cTpltBox == "PUNTOLINEA"
      ::TextCode( "dplinedado" )
   ENDCASE
   ::NumCode( "dplinecob", ::aCltBox[ 1 ], .F. )
   ::NumCode( "dplinecog", ::aCltBox[ 2 ], .F. )
   ::NumCode( "dplinecor", ::aCltBox[ 3 ], .F. )
   ::NumCode( "dplinew", ::nWltBox, .F. )
   ::TextCode( "\dpfillbgcr255\dpfillbgcg255\dpfillbgcb255" )
   ::NumCode( "dpfillpat", ::nFPtbox, .F. )
   ::CloseGroup()
   RETURN NIL

METHOD SetFrame( ASize, cHorzAlign, cVertAlign, lNoWrap, ;
      cXAlign, xpos, cYAlign, ypos ) CLASS RichText
   LOCAL ancho
   IF Empty( ASize )
      RETURN NIL
   ENDIF
   ancho := Round( ( 1.25 * ASize[ 1 ] * ::nScale ) + 0.5, 0 )
   ::TextCode( "absh0" )
   ::NumCode( "absw", ancho, .F. )
   IF cXAlign == "MARGIN"
      ::TextCode( "phmrg" )
   ELSE
      ::TextCode( "phpg" )
   ENDIF
   IF xpos == NIL
      DO CASE
      CASE cHorzAlign == "LEFT"
         ::TextCode( "posxl" )
      CASE cHorzAlign == "RIGHT"
         ::TextCode( "posxr" )
      CASE cHorzAlign == "CENTER"
         ::TextCode( "posxc" )
      ENDCASE
   ELSE
      ::NumCode( "posx", xpos, .T. )
   ENDIF
   IF cYAlign == "MARGIN"
      ::TextCode( "pvmrg" )
   ELSEIF cYAlign == "PARRAFO"
      ::TextCode( "pvpara" )
   ELSE
      ::TextCode( "pvpg" )
   ENDIF
   IF ypos == NIL
      DO CASE
      CASE cVertAlign == "TOP"
         ::TextCode( "posyt" )
      CASE cVertAlign == "BOTTOM"
         ::TextCode( "posyb" )
      CASE cVertAlign == "CENTER"
         ::TextCode( "posyc" )
      ENDCASE
   ELSE
      ::NumCode( "posy", ypos, .T. )
   ENDIF
   IF lNoWrap
      ::TextCode( "nowrap" )
   ELSE
      ::TextCode( "dxfrtext180\dfrmtxtx180\dfrmtxty0" )
   ENDIF
   ::TextCode( "par\li0\ql" )
   ::ParaBorder( "ALL", "SINGLE" )
   RETURN NIL

METHOD Image( cName, ASize, nPercent, lCell, lInclude, lFrame, aFSize, cHorzAlign, ;
      cVertAlign, lNoWrap, cXAlign, xpos, cYAlign, ypos ) CLASS RichText
   LOCAL cExt

   DEFAULT cName TO "", ;
         ASize TO { }, ;
         cHorzAlign TO "CENTER", ;
         cVertAlign TO "TOP", ;
         lFrame TO .T., ;
         lNoWrap TO .F., ;
         lCell TO .F., ;
         xpos TO NIL, ;
         cXAlign TO "MARGIN", ;
         cYAlign TO "PARRAFO", ;
         ypos TO NIL, ;
         lInclude TO .F., ;
         nPercent TO 1

   IF Empty( cName )
      RETURN NIL
   ENDIF

   IF lCell
      ::nCurrColumn += 1
      ::LogicCode( "pard", .T. )
      ::TextCode( "intbl" )
      ::OpenGroup()
   ELSE
      IF lFrame
         DEFAULT aFSize TO ASize
         ::SetFrame( aFSize, cHorzAlign, cVertAlign, lNoWrap, ;
               cXAlign, xpos, cYAlign, ypos )
      ENDIF
   ENDIF

   IF ! lInclude
      ::NumCode( "sslinkpictw", ASize[ 1 ] )
      ::NumCode( "sslinkpicth", ASize[ 2 ] )
      ::OpenGroup()
      ::TextCode( "field" )
      ::OpenGroup()
      ::TextCode( "fldinst" )
      FWrite( ::hFile, " INCLUDEPICTURE " )
      cName := StrTran( cName, "\", "\\\\" )
      FWrite( ::hFile, " " + AllTrim( cName ) + " \\*MERGEFORMAT " )
      ::CloseGroup()
      ::OpenGroup()
      ::TextCode( "fldrslt" )
      ::CloseGroup()
      ::CloseGroup()
   ELSE
      cExt := Upper( cFileExt( cName ) )
      DO CASE
      CASE cExt == "BMP"
         ::Bmp2Wmf( cName, ASize, nPercent )
      CASE cExt == "WMF"
         ::Wmf2Rtf( cName, ASize, nPercent )
      OTHERWISE
         ::RtfImage( cName, ASize, nPercent )
      ENDCASE
   ENDIF

   IF lCell
      ::CloseGroup()
      ::TextCode( "cell" )
      IF ::nCurrColumn == ::nTblColumns
         ::TextCode( "intbl\row" )
         ::nCurrColumn := 0
      ENDIF
   ELSE
      ::TextCode( "par\pard" )
   ENDIF

   RETURN NIL

/* ===========================================================================
   Style Management - Fixed IncStyle, ParaStyle, CharStyle
=========================================================================== */
METHOD IncStyle( cName, styletype, nFontNumber, nFontSize, ;
      nFontColor, cAppear, cHorzAlign, nIndent, cKeys, ;
      cTypeBorder, cBordStyle, nBordColor, nShdPct, cShadPat, lAdd, LUpdate ) CLASS RichText

   LOCAL lParrafo := .F., lChar := .F., i
   LOCAL cEstilo := ""

   DEFAULT cName TO "", ;
         styletype TO "PARAGRAPH", ;
         nFontNumber TO 1, ;
         nFontSize   TO ::nFontSize, ;
         nFontColor  TO ::nFontColor, ;
         cAppear  TO "", ;
         cHorzAlign TO "LEFT", ;
         nIndent TO 0, ;
         cKeys TO "", ;
         cTypeBorder TO NIL, ;
         cBordStyle TO "SINGLE", ;
         nBordColor TO 0, ;
         nShdPct TO 0, ;
         cShadPat TO "", ;
         lAdd TO .F., ;
         LUpdate TO .F.

   /* FIX: Shading normalization */
   IF nShdPct > 0
      IF nShdPct < 1
         nShdPct := nShdPct * 10000
      ELSEIF nShdPct <= 100
         nShdPct := nShdPct * 100
      ENDIF
   ENDIF

   ::OpenGroup()
   DO CASE
   CASE styletype == "PARAGRAPH"
      ::NumCode( "s", ::NStlDef, .F. )
      lParrafo := .T.
   CASE styletype == "CHARACTER"
      ::NumCode( "*\cs", ::nCharStl, .F. )
      lChar := .T.
   CASE styletype == "SECTION"
      ::NumCode( "ds", ::nStlSec, .F. )
      /* FIX: increment section style counter */
      ::nStlSec += 1
   ENDCASE

   IF ! Empty( cKeys )
      ::OpenGroup()
      ::TextCode( "keycode " + cKeys )
      ::CloseGroup()
   ENDIF

   IF lParrafo
      IF cTypeBorder # NIL
         IF AScan( cTypeBorder, "ALL" ) # 0
            cEstilo += ::ParaBorder( "ALL", cBordStyle )
         ELSE
            FOR i := 1 TO Len( cTypeBorder )
               cEstilo += ::ParaBorder( cTypeBorder[ i ], cBordStyle )
            NEXT i
         ENDIF
      ENDIF
      cEstilo += ::NumCode( "\li", nIndent )
   ENDIF

   cEstilo += ::NumCode( "f", nFontNumber - 1, .F. )
   cEstilo += ::NumCode( "fs", nFontSize * 2, .F. )
   cEstilo += ::NumCode( "cf", nFontColor, .F. )
   cEstilo += ::Appearance( cAppear )

   IF lChar
      cEstilo += ::LogicCode( "\additive", lAdd )
      AAdd( ::CharStyles, cEstilo )
      ::nCharStl += 1
   ENDIF

   cEstilo += ::LogicCode( "\sautoupd", LUpdate )

   IF lParrafo
      IF nShdPct > 0
         cEstilo += ::NumCode( "shading", nShdPct, .F. )
         IF ! Empty( cShadPat )
            cEstilo += ::TextCode( "bg" + ::ShadeCode( cShadPat ) )
         ENDIF
      ENDIF
      AAdd( ::ParStyles, cEstilo )
      ::NStlDef += 1
   ENDIF

   FWrite( ::hFile, " " + cName + ";" )
   ::CloseGroup()

   RETURN NIL

METHOD BeginStly() CLASS RichText
   ::OpenGroup()
   ::TextCode( "stylesheet" )
   ::SetStlDef()
   RETURN NIL

METHOD WriteStly() CLASS RichText
   ::CloseGroup()
   RETURN NIL

/* FIXED: ParaStyle and CharStyle now use Len(::ParStyles) properly */
METHOD ParaStyle( nStyle ) CLASS RichText
   IF nStyle == 0
      RETURN NIL
   ENDIF
   IF ::nStlAct # nStyle
      IF nStyle <= Len( ::ParStyles )
         ::Numcode( "par\pard\s", nStyle, .F. )
         FWrite( ::hFile, ::ParStyles[ nStyle ] )
         ::nStlAct := nStyle
      ENDIF
   ENDIF
   RETURN NIL

METHOD CharStyle( nStyle ) CLASS RichText
   IF nStyle == 0
      RETURN NIL
   ENDIF
   IF ::nCharAct # nStyle
      IF nStyle <= Len( ::CharStyles )
         ::Numcode( "\cs", nStyle, .F. )
         FWrite( ::hFile, ::CharStyles[ nStyle ] )
         ::nCharAct := nStyle
      ENDIF
   ENDIF
   RETURN NIL

METHOD TextCode( cCode ) CLASS RichText
   LOCAL codigo
   codigo :=  FormatCode( cCode )
   FWrite( ::hFile, codigo )
   RETURN codigo

/* ===========================================================================
   DefNewTable - Added validation for aHeadTit and TblCJoin
=========================================================================== */
METHOD DefNewTable( cTblHAlign, nTblFntNum, nTblFntSize, ;
      cCellAppear, cCellHAlign, nTblRows, ;
      nTblColumns, nTblRHgt, aTableCWid, cRowBorder, cCellBorder, aColPct, nCellPct, ;
      lTblNoSplit, nTblHdRows, aHeadTit, nTblHdHgt, nTblHdPct, nTblHdFont, ;
      nTblHdFSize, cHeadAppear, cHeadHAlign, nTblHdColor , nTblHdFColor, ;
      aTblCJoin ) CLASS RichText

   LOCAL i, j

   DEFAULT ;
         cTblHAlign  TO  "CENTER", ;
         nTblFntNum  TO  1, ;
         nTblFntSize  TO  ::nFontSize, ;
         nTblRows  TO  1, ;
         nTblColumns TO  1, ;
         nTblRHgt  TO  NIL, ;
         aTableCWid  TO  Array( nTblColumns ), ;
         cRowBorder  TO  "NONE", ;
         cCellBorder  TO  "SINGLE", ;
         lTblNoSplit  TO  .F., ;
         nCellPct  TO  0, ;
         nTblHdRows  TO  0, ;
         aHeadTit TO { }, ;
         nTblHdHgt  TO  nTblRHgt, ;
         nTblHdPct  TO  0, ;
         nTblHdFont  TO  nTblFntNum, ;
         nTblHdFSize  TO  ::nFontSize + 2, ;
         nTblHdColor   TO  0, ;
         nTblHdFColor  TO  0, ;
         aTblCJoin TO { }

   IF aTableCWid[ 1 ] == NIL
      AFill( aTableCWid, 6.5 / nTblColumns )
   ELSEIF ValType( aTableCWid[ 1 ] ) == "A"
      aTableCWid := AClone( aTableCWid[ 1 ] )
   ENDIF
   FOR i := 2 TO Len( aTableCWid )
      aTableCWid[ i ] += aTableCWid[ i - 1 ]
   NEXT

   IF aColPct == NIL
      aColPct   := Array( nTblColumns )
      AFill( aColPct, 0 )
   ENDIF

   ::cTblHAlign := Lower( Left( cTblHAlign, 1 ) )
   ::nTblFntNum := nTblFntNum
   ::nTblFntSize := nTblFntSize
   ::cCellAppear := cCellAppear
   ::cCellHAlign := cCellHAlign
   ::nTblRows := nTblRows
   ::nTblColumns := nTblColumns
   ::nTblRHgt := nTblRHgt
   ::aTableCWid := aTableCWid
   ::cRowBorder := ::BorderCode( cRowBorder )
   ::cCellBorder := ::BorderCode( cCellBorder )
   ::aColPct := AClone( aColPct )
   ::nCellPct := IIf( nCellPct < 1, nCellPct * 10000, nCellPct * 100 )
   i := 1
   AEval( ::aColPct, { || ::aColPct[ i ] := IIf( ::aColPct[ i ] < 1, ::aColPct[ i ] * 10000, ;
         ::aColPct[ i ] * 100 ), i ++ } )
   ::lTblNoSplit := lTblNoSplit
   ::nTblHdRows := nTblHdRows
   ::nTblHdHgt := nTblHdHgt
   ::nTblHdPct := IIf( nTblHdPct < 1, nTblHdPct * 10000, nTblHdPct * 100 )
   ::nTblHdFont := nTblHdFont
   ::nTblHdFSize := nTblHdFSize
   ::nTblHdColor := nTblHdColor
   ::nTblHdFColor := nTblHdFColor
   ::cHeadAppear := cHeadAppear
   ::cHeadHAlign := cHeadHAlign
   ::TblCJoin    := AClone( aTblCJoin )
   ::nCurrColumn := 0
   ::nCurrRow    := 0

   ::OpenGroup()
   FOR j := 1 TO ::nTblHdRows
      /* Validate aHeadTit exists and has correct dimensions */
      IF Len( aHeadTit ) >= j
         IF ValType( aHeadTit[ j ] ) != "A"
            aHeadTit[ j ] := Array( ::nTblColumns )
            AFill( aHeadTit[ j ], "" )
         ELSEIF Len( aHeadTit[ j ] ) < ::nTblColumns
            aHeadTit[ j ] := ASize( aHeadTit[ j ], ::nTblColumns )
            AFill( aHeadTit[ j ], "" )
         ENDIF
      ELSE
         aHeadTit[ j ] := Array( ::nTblColumns )
         AFill( aHeadTit[ j ], "" )
      ENDIF

      ::TableDef( .T., j )
      FOR i := 1 TO Len( ::aTableCWid )
         ::TableCell( aHeadTit[ j ][ i ],,,,,,,, .T., .T. )
      NEXT i
   NEXT j

   ::TableDef()
   RETURN NIL

METHOD TableDef( lHeader, nRowHead, cCellBorder, aColPct ) CLASS RichText
   LOCAL i, j, pos

   DEFAULT lHeader TO .F., ;
         nRowHead TO 1, ;
         cCellBorder TO ::cCellBorder, ;
         aColPct TO AClone( ::aColPct )

   ::TextCode( "trowd\trgaph108\trleft-108" )
   ::TextCode( "trq" + ::cTblHAlign )
   ::Borders( "tr", ::cRowBorder )
   ::NumCode( "trrh", ::nTblRHgt )
   ::LogicCode( "trhdr", lHeader )
   ::LogicCode( "trkeep", ::lTblNoSplit )

   FOR i := 1 TO Len( ::aTableCWid )
      IF lHeader
         IF ! Empty( ::TblCJoin )
            FOR j := 1 TO Len( ::TblCJoin[ nRowHead ] )
               pos := AScan( ::TblCJoin[ nRowHead ][ j ], i )
               IF pos == 1
                  ::TextCode( "clvertalt" )
                  ::TextCode( "clmgf" )
               ELSEIF pos # 0
                  ::TextCode( "clmrg" )
               ELSE
                  ::TextCode( "clvertalt" )
               ENDIF
            NEXT j
         ELSE
            ::TextCode( "clvertalt" )
         ENDIF
      ELSE
         ::TextCode( "clvertalt" )
      ENDIF
      ::Borders( "cl", cCellBorder )
      IF lHeader
         ::NumCode( "clshdng", ::nTblHdPct, .F. )
         IF ::nTblHdColor > 0
            ::NumCode( "clcbpat", ::nTblHdColor, .F. )
         ENDIF
      ELSE
         ::NumCode( "clshdng", aColPct[ i ], .F. )
      ENDIF
      ::NumCode( "cellx", ::aTableCWid[ i ] )
   NEXT

   RETURN NIL

METHOD TableCell( cText, nFontNumber, nFontSize, cAppear, cHorzAlign, ;
      nSpace, lSpExact, nFontColor, ;
      lDefault, lHeader, lPage, lDate ) CLASS RichText

   DEFAULT nFontNumber TO - 1, ;
         nFontSize TO - 1, ;
         cAppear TO NIL, ;
         cHorzAlign TO NIL, ;
         nSpace TO 0, ;
         nFontColor TO 0, ;
         lDefault TO .F., ;
         lHeader TO .F., ;
         lPage TO .F., ;
         lDate TO .F.

   ::nCurrColumn += 1
   ::LogicCode( "pard", lDefault )
   ::TextCode( "intbl" )
   IF lHeader
      ::NewFont( ::nTblHdFont )
      ::SetFontSize( ::nTblHdFSize )
      IF ::nTblHdFColor > 0
         ::SetFontColor( ::nTblHdFColor )
      ENDIF
      ::Appearance( ::cHeadAppear )
      ::HAlignment( ::cHeadHAlign )
   ELSE
      ::NewFont( IIf( nFontNumber == - 1, ::nTblFntNum, nFontNumber ) )
      ::SetFontSize( IIf( nFontSize == - 1, ::nTblFntSize, nFontSize ) )
      ::SetFontColor( nFontColor )
      ::Appearance( IIf( cAppear == NIL, ::cCellAppear, cAppear ) )
      ::HAlignment( IIf( cHorzAlign == NIL, ::cCellHAlign, cHorzAlign ) )
      ::LineSpacing( nSpace, lSpExact )
   ENDIF
   ::Write( cText )
   IF lPage
      ::NumPage()
   ENDIF
   IF lDate
      ::CurrDate()
   ENDIF
   ::TextCode( "cell" )
   IF ::nCurrColumn == ::nTblColumns
      ::TextCode( "intbl\row" )
      ::nCurrColumn := 0
   ENDIF

   RETURN NIL

METHOD CellFormat( cCellBorder, aCellPct ) CLASS RichText
   DEFAULT cCellBorder TO ::cCellBorder, ;
         aCellPct TO AClone( ::aColPct )
   ::TableDef(,, cCellBorder, aCellPct )
   RETURN NIL

METHOD DocFormat( nTab, nLineStart, lBackup, nDefLang, nDocType, ;
      cFootType, cFootNotes, cEndNotes, cFootNumber, nPage, ;
      cProtect, lFacing, nGutter ) CLASS RichText

   DEFAULT nTab TO 0.5, ;
         nLineStart TO 1, ;
         lBackup TO .F., ;
         nDefLang TO 1034, ;
         nDocType TO 0, ;
         cFootType TO "FOOTNOTES", ;
         cEndNotes TO "SECTION", ;
         cFootNotes TO "SECTION", ;
         cFootNumber TO "SIMBOL", ;
         nPage TO 1, ;
         cProtect TO "NONE", ;
         lFacing TO .F., ;
         nGutter TO 0

   ::lFacing := lFacing
   ::NumCode( "deftab", nTab, .T. )
   ::NumCode( "linestart", nLineStart, .F. )
   ::LogicCode( "makebackup", lBackup )
   ::NumCode( "deflang", nDefLang, .F. )
   ::NumCode( "doctype", nDocType, .F. )
   DO CASE
   CASE cFootType == "FOOTNOTES"
      ::NumCode( "fet", 0, .F. )
      IF cFootNotes == "SECTION"
         ::TextCode( "endnotes" )
      ELSE
         ::TextCode( "enddoc" )
      ENDIF
      ::TextCode( "ftnbj" )
   CASE cFootType == "ENDNOTES"
      ::NumCode( "fet", 1, .F. )
      IF cEndNotes == "SECTION"
         ::TextCode( "aendnotes" )
      ELSE
         ::TextCode( "aenddoc" )
      ENDIF
      ::TextCode( "aftnbj" )
   CASE cFootType == "BOTH"
      ::NumCode( "fet", 2, .F. )
      IF cFootNotes == "SECTION"
         ::TextCode( "endnotes" )
      ELSE
         ::TextCode( "enddoc" )
      ENDIF
      IF cEndNotes == "SECTION"
         ::TextCode( "aendnotes" )
      ELSE
         ::TextCode( "aenddoc" )
      ENDIF
      ::TextCode( "ftnbj" )
      ::TextCode( "aftnbj" )
   ENDCASE
   DO CASE
   CASE cFootNumber == "SIMBOL"
      ::TextCode( "ftnnchi" )
      ::TextCode( "aftnnchi" )
   CASE cFootNumber == "ARABIC"
      ::TextCode( "ftnnar" )
      ::TextCode( "aftnnar" )
   CASE cFootNumber == "ALPHA"
      ::TextCode( "ftnnalc" )
      ::TextCode( "aftnnalc" )
   CASE cFootNumber == "ROMAN"
      ::TextCode( "ftnnrlc" )
      ::TextCode( "aftnnrlc" )
   ENDCASE
   ::LogicCode( "facingp", lFacing )
   IF lFacing
      ::NumCode( "gutter", nGutter, .T. )
   ENDIF
   ::Numcode( "pgnstart", nPage, .F. )
   DO CASE
   CASE cProtect == "REVISIONS"
      ::TextCode( "revprot" )
   CASE cProtect == "COMMENTS"
      ::TextCode( "annotprot" )
   ENDCASE

   RETURN NIL

METHOD CurrDate( cFormat ) CLASS RichText
   DEFAULT cFormat TO "LONGFORMAT"
   DO CASE
   CASE cFormat == "LONGFORMAT"
      ::TextCode( "chdpl" )
   CASE cFormat == "SHORTFORMAT"
      ::TextCode( "chdpa" )
   CASE cFormat == "HEADER"
      ::TextCode( "chdate" )
   ENDCASE
   RETURN NIL

/*
 * =============================================================================
 * METHOD RtfImage( cName, aSize, nPercent ) CLASS RichText
 *
 * DESCRIPTION:
 *   Embeds an image (JPEG, PNG, or GIF) directly into the RTF document stream.
 *   Utilizes the Windows GDI+ API via HWGUI's built-in functions, ensuring
 *   compatibility across Clang, MSVC, and GCC compilers, and works correctly
 *   on both 32-bit and 64-bit architectures.
 *
 * PARAMETERS:
 *   cName    - Full file system path to the source image.
 *   aSize    - Optional array { nWidth, nHeight } in inches, to override the
 *              natural image dimensions. If not provided or empty, the method
 *              will automatically calculate the dimensions based on the screen
 *              DPI and the image's pixel size.
 *   nPercent - Integer scale factor, applied when aSize is omitted. For example,
 *              nPercent = 2 doubles the rendered size; nPercent = 0.5 halves it.
 *
 * RETURN:
 *   NIL - The method writes directly to the RTF output file handle (::hFile)
 *         and does not return a value.
 *
 * IMPLEMENTATION NOTES:
 *   1. IMAGE LOADING:
 *      - JPEG, PNG, and GIF are all loaded via HWG_GDIPLUSOPENIMAGE(),
 *        which internally invokes GDI+ to decode the file into a Windows HBITMAP
 *        handle. This approach avoids external DLLs and works with all modern
 *        Windows versions (Vista+).
 *
 *   2. GIF HANDLING (TRANSPARENT CONVERSION):
 *      - Since RTF does not natively support GIF, the method converts the
 *        animated/static GIF to a compressed PNG file using GDI+.
 *      - The conversion is performed by HWG_GDIPLUSSAVEPNG(), which saves the
 *        HBITMAP as a PNG file to the system's temporary directory.
 *      - The temporary PNG is then embedded using the RTF \pngblip marker,
 *        which is widely supported by all modern RTF readers (Microsoft Word,
 *        LibreOffice, WordPad, etc.).
 *      - The temporary file is automatically deleted after embedding.
 *
 *   3. SIZE CALCULATION:
 *      - The method retrieves the image dimensions in pixels (nWidth, nHeight)
 *        and converts them to twips (1/1440 inch) using the screen DPI values
 *        obtained from the Windows device context.
 *      - If aSize is provided, those values override the computed size.
 *      - All scaling is performed via ::NumCode() and ::TextCode() to correctly
 *        produce the RTF meta-header.
 *
 *   4. RTF PICTURE GROUP:
 *      - Opens an RTF \pict group and writes the appropriate blip marker:
 *        * \jpegblip for JPEG files.
 *        * \pngblip for PNG files and for GIF after conversion.
 *      - The binary data is read in 8 KB chunks, converted to hexadecimal
 *        using hb_StrToHex(), and written directly to the output stream.
 *
 *   5. MEMORY MANAGEMENT:
 *      - The HBITMAP handle is explicitly freed via hwg_Deleteobject() to
 *        prevent GDI resource leaks.
 *      - Temporary files are cleaned up with FERASE() after the embedding
 *        is complete.
 *
 * DEPENDENCIES:
 *   - HWGUI library with GDI+ support:
 *     * HWG_GDIPLUSOPENIMAGE()
 *     * HWG_GDIPLUSSAVEPNG()
 *   - Harbour core functions:
 *     * hb_DirTemp(), hb_StrToHex()
 *     * hwg_Getbitmapwidth(), hwg_Getbitmapheight()
 *
 * COMPATIBILITY:
 *   - Tested with Clang 15+, MSVC 2022, GCC 12+ (Windows targets).
 *   - Fully compatible with 32-bit (x86) and 64-bit (x64) builds.
 *
 * REVISION HISTORY:
 *   2026-09-08 - Initial implementation replacing legacy nviewlib approach.
 *   2026-09-09 - Added GDI+ support for GIF-to-PNG conversion.
 *              - Optimized buffer read loop with 8 KB blocks.
 *              - Added screen DPI fallback to prevent division by zero.
 * =============================================================================
 */
METHOD RtfImage( cName, aSize, nPercent ) CLASS RichText
   LOCAL aInches[2], in, nWidth := 0, nHeight := 0
   LOCAL cBuffer, nBytes, nBloque := 8192
   LOCAL scale, PictWidth, PictHeight
   LOCAL ScreenResY, ScreenResX
   LOCAL hBitmap, oWnd, hWnd, hdc
   LOCAL cExt, cImageType := "", cTempFile := ""
   LOCAL lGif := .F.

   HB_SYMBOL_UNUSED( nWidth )
   HB_SYMBOL_UNUSED( nHeight )
   HB_SYMBOL_UNUSED( cImageType )

   DEFAULT aSize := {}
   DEFAULT nPercent := 1

   cExt := Upper( cFileExt( cName ) )

   // Load the image using GDI+ (handles JPEG, PNG, GIF, etc.)
   hBitmap := HWG_GDIPLUSOPENIMAGE( cName )

   IF ! Empty( hBitmap )
      // Retrieve pixel dimensions
      nWidth  := hwg_Getbitmapwidth( hBitmap )
      nHeight := hwg_Getbitmapheight( hBitmap )

      // Convert GIF to PNG using GDI+ (RTF doesn't support GIF natively)
      IF cExt == "GIF"
         lGif := .T.
         cTempFile := hb_DirTemp() + "img_" + LTrim(Str(::nFile)) + ".png"
         ::nFile += 1

         IF HWG_GDIPLUSSAVEPNG( cTempFile, hBitmap )
            hwg_Deleteobject( hBitmap )

            // Reload to confirm dimensions (optional but safe)
            hBitmap := HWG_GDIPLUSOPENIMAGE( cTempFile )
            IF ! Empty( hBitmap )
               nWidth  := hwg_Getbitmapwidth( hBitmap )
               nHeight := hwg_Getbitmapheight( hBitmap )
            ENDIF
         ENDIF
      ENDIF

      // Obtain screen DPI for proper scaling to twips
      oWnd := GetWndDefault()
      hWnd := oWnd:hWnd
      hdc  := hwg_Getdc( hWnd )
      ScreenResX := GETDEVICEC( hdc, 88 ) // LOGPIXELSX
      ScreenResY := GETDEVICEC( hdc, 90 ) // LOGPIXELSY
      hwg_Releasedc( hWnd, hdc )

      // Free the GDI handle immediately
      IF ! Empty( hBitmap )
         hwg_Deleteobject( hBitmap )
      ENDIF

      // Safety fallback for DPI values (should never happen, but just in case)
      IF ScreenResX == 0 .OR. ScreenResY == 0
         ScreenResX := 96
         ScreenResY := 96
      ENDIF

      // Convert pixels to twips (1/1440 inch)
      aInches[1] := ROUND( ( ( nWidth  / ScreenResX ) * ::nScale ) + 0.5, 0 )
      aInches[2] := ROUND( ( ( nHeight / ScreenResY ) * ::nScale ) + 0.5, 0 )

      // Determine final rendering size
      IF EMPTY( aSize ) .OR. Len( aSize ) < 2
         PictWidth  := ROUND( aInches[1] + 0.5, 0 ) * nPercent
         PictHeight := ROUND( aInches[2] + 0.5, 0 ) * nPercent
      ELSE
         PictWidth  := ROUND( ( aSize[1] * ::nScale ) + 0.5, 0 )
         PictHeight := ROUND( ( aSize[2] * ::nScale ) + 0.5, 0 )
      ENDIF

      // Determine which file to read and which RTF blip to use
      IF lGif
         in := fopen( cTempFile )
         cImageType := "pngblip"
      ELSE
         in := fopen( cName )
         DO CASE
         CASE cExt == "JPG" .OR. cExt == "JPEG"
            cImageType := "jpegblip"
         CASE cExt == "PNG"
            cImageType := "pngblip"
         OTHERWISE
            cImageType := "pngblip"   // fallback
         ENDCASE
      ENDIF

      IF in >= 0
         ::OpenGroup()
         ::TextCode( "pict\" + cImageType )

         // Write the RTF picture meta-header
         scale := ROUND( ( PictWidth  * 100 / aInches[1] ) + 0.5, 0 )
         ::NumCode( "picw", nWidth, .F. )
         ::NumCode( "picwgoal", aInches[1], .F. )
         ::NumCode( "picscalex", scale, .F. )

         scale := ROUND( ( PictHeight * 100 / aInches[2] ) + 0.5, 0 )
         ::NumCode( "pich", nHeight, .F. )
         ::NumCode( "pichgoal", aInches[2], .F. )
         ::NumCode( "picscaley", scale, .F. )

         // Read the binary file in 8 KB chunks and convert to hex
         cBuffer := Space( nBloque )
         DO WHILE .T.
            nBytes := fread( in, @cBuffer, nBloque )
            IF nBytes <= 0
               EXIT
            ENDIF
            FWRITE( ::hFile, hb_StrToHex( SubStr( cBuffer, 1, nBytes ) ) )
         ENDDO

         ::CloseGroup()
         fclose( in )

         // Clean up temporary file (GIF conversion)
         IF lGif .AND. ! Empty( cTempFile )
            FERASE( cTempFile )
         ENDIF
      ENDIF
   ENDIF

   RETURN NIL

/*=============================================================================
 * METHOD Wmf2Rtf( cName, aSize, nPercent ) CLASS RichText
 *
 * DESCRIPTION:
 *   Embeds a Windows Metafile (WMF) directly into the RTF document.
 *   Reads the Aldus Placeable Metafile header to extract logical dimensions
 *   and resolution, eliminating the need for external DLLs or printer objects.
 *   Fully compatible with Clang, MSVC, and GCC (32/64-bit).
 *
 * PARAMETERS:
 *   cName    - Full path to the WMF file.
 *   aSize    - Optional array { nWidth, nHeight } in inches.
 *   nPercent - Scale factor (1 = 100%).
 *
 * RETURN:
 *   NIL
 *
 * DEPENDENCIES:
 *   - Harbour core: Bin2L(), Bin2W(), hb_StrToHex()
 *   - HWGUI: hwg_Getdc(), hwg_Releasedc(), GETDEVICEC()
 * =============================================================================
 */
METHOD Wmf2Rtf( cName, aSize, nPercent ) CLASS RichText
   LOCAL in, cMenInter, nBloque := 8192, nBytes
   LOCAL scale, PictWidth, PictHeight
   LOCAL ancho, alto, bmHeight, bmWidth, x
   LOCAL cHeader, nLeft, nTop, nRight, nBottom, nInch
   LOCAL ScreenResX, ScreenResY, oWnd, hWnd, hdc

   DEFAULT aSize := {}
   DEFAULT nPercent := 1

   in := fopen( cName )

   IF in >= 0
      // Read the 22-byte Aldus Placeable Metafile header
      cHeader := Space( 22 )
      fread( in, @cHeader, 22 )

      IF Bin2L( SubStr( cHeader, 1, 4 ) ) == -1698484777
         // Extract bound coordinates (16-bit signed integers) using native Bin2W()
         nLeft   := Bin2W( SubStr( cHeader, 7, 2 ) )
         nTop    := Bin2W( SubStr( cHeader, 9, 2 ) )
         nRight  := Bin2W( SubStr( cHeader, 11, 2 ) )
         nBottom := Bin2W( SubStr( cHeader, 13, 2 ) )
         nInch   := Bin2W( SubStr( cHeader, 15, 2 ) ) // Units per inch

         // Protect against malformed headers (division by zero)
         IF nInch == 0 .OR. nInch > 1440
            nInch := 1440
         ENDIF

         // Compute dimensions in logical units
         IF EMPTY( aSize ) .OR. Len( aSize ) < 2
            alto  := ( nBottom - nTop ) * nPercent
            ancho := ( nRight - nLeft ) * nPercent
         ELSE
            alto  := ( aSize[2] * nInch )
            ancho := ( aSize[1] * nInch )
         ENDIF

         // Obtain screen DPI (fallback to 96 if unavailable)
         oWnd := GetWndDefault()
         hWnd := oWnd:hWnd
         hdc  := hwg_Getdc( hWnd )
         ScreenResX := GETDEVICEC( hdc, 88 ) // LOGPIXELSX
         ScreenResY := GETDEVICEC( hdc, 90 ) // LOGPIXELSY
         hwg_Releasedc( hWnd, hdc )

         IF ScreenResX == 0 .OR. ScreenResY == 0
            ScreenResX := 96
            ScreenResY := 96
         ENDIF

         // Standard RTF Metafile scaling conversions (Twips setup)
         bmHeight   := ROUND( ( alto  * 1440 / nInch ) + 0.5, 0 )
         bmWidth    := ROUND( ( ancho * 1440 / nInch ) + 0.5, 0 )
         PictHeight := ROUND( ( alto  * 1440 / ScreenResY ) + 0.5, 0 )
         PictWidth  := ROUND( ( ancho * 1440 / ScreenResX ) + 0.5, 0 )

         // Prevent division by zero
         IF bmWidth == 0 .OR. bmHeight == 0
            bmWidth  := 100
            bmHeight := 100
         ENDIF

         ::OpenGroup()
         ::TextCode( "\pict\wmetafile8" )

         x := ROUND( ( bmWidth * 2540 / 1440 ) + 0.5, 0 )
         ::NumCode( "picw", x, .F. )
         ::NumCode( "picwgoal", bmWidth, .F. )

         scale := ROUND( ( PictWidth * 100 / bmWidth ) + 0.5, 0 )
         ::NumCode( "picscalex", scale, .F. )

         x := ROUND( ( bmHeight * 2540 / 1440 ) + 0.5, 0 )
         ::NumCode( "pich", x, .F. )
         ::NumCode( "pichgoal", bmHeight, .F. )

         scale := ROUND( ( PictHeight * 100 / bmHeight ) + 0.5, 0 )
         ::NumCode( "picscaley", scale, .F. )

         ::OpenGroup()

         // Seek back past the Aldus header to write raw WMF data stream
         fseek( in, 22, 0 )
         cMenInter := Space( nBloque )

         DO WHILE .T.
            nBytes := fread( in, @cMenInter, nBloque )
            IF nBytes <= 0
               EXIT
            ENDIF
            FWRITE( ::hFile, hb_StrToHex( SubStr( cMenInter, 1, nBytes ) ) )
         ENDDO

         ::CloseGroup()
         ::CloseGroup()
      ENDIF
      fclose( in )
   ENDIF

   RETURN NIL

/*=============================================================================
 * METHOD Bmp2Wmf( cName, aSize, nPercent ) CLASS RichText
 *
 * DESCRIPTION:
 *   Converts a Windows Bitmap (BMP) into a Windows Metafile (WMF) and embeds
 *   it into the RTF document. Uses native HWGUI HBitmap and GDI metafile
 *   functions, ensuring full compatibility with 32-bit and 64-bit platforms
 *   compiled via Clang, MSVC, or GCC.
 *
 * PARAMETERS:
 *   cName    - Full file system path to the source BMP image.
 *   aSize    - Optional array { nWidth, nHeight } in inches to override size.
 *   nPercent - Scale factor (1 = 100%).
 *
 * RETURN:
 *   NIL
 *
 * DEPENDENCIES:
 *   - Harbour core: hb_DirTemp(), hb_StrToHex()
 *   - HWGUI / GDI: HBitmap(), hwg_CreateMetafile(), hwg_CloseMetafile(),
 *                  hwg_Setwindowextex(), hwg_Getdc(), hwg_Releasedc()
 * =============================================================================
 */
METHOD Bmp2Wmf( cName, aSize, nPercent ) CLASS RichText
   LOCAL cMenInter, nBloque := 8192, nBytes
   LOCAL scalex, scaley
   LOCAL hDCOut, oBmp, in, x
   LOCAL nWidth, nHeight
   LOCAL ResX, ResY, ScreenResX, ScreenResY
   LOCAL cTempFile, oWnd, hWnd, hdc
   LOCAL aInches

   DEFAULT aSize := {}
   DEFAULT nPercent := 1

   aInches := Array( 2 )

   // Load the BMP image using HWGUI's native object loader
   oBmp := HBitmap():LoadFromFile( cName )

   IF ! Empty( oBmp:handle )
      // Extract pixel dimensions directly from the object
      nWidth  := oBmp:nWidth
      nHeight := oBmp:nHeight

      // Obtain native screen DPI context for logical unit resolution
      oWnd := GetWndDefault()
      hWnd := oWnd:hWnd
      hdc  := hwg_Getdc( hWnd )
      ScreenResX := GETDEVICEC( hdc, 88 ) // LOGPIXELSX
      ScreenResY := GETDEVICEC( hdc, 90 ) // LOGPIXELSY
      hwg_Releasedc( hWnd, hdc )

      // Fallback for screen DPI to prevent division by zero
      IF ScreenResX == 0 .OR. ScreenResY == 0
         ScreenResX := 96
         ScreenResY := 96
      ENDIF

      // Calculate resolution scale (convert inches/DPI equivalents)
      ResX := ScreenResX
      ResY := ScreenResY

      // Compute actual image dimensions in inches
      aInches[1] := nWidth  / ResX
      aInches[2] := nHeight / ResY

      IF EMPTY( aSize ) .OR. Len( aSize ) < 2
         aInches[1] *= nPercent
         aInches[2] *= nPercent
         scalex     := INT( nPercent * 100 )
         scaley     := INT( nPercent * 100 )
      ELSE
         scalex     := ROUND( ( ( aSize[1] * 100 ) / aInches[1] ) + 0.5, 0 )
         scaley     := ROUND( ( ( aSize[2] * 100 ) / aInches[2] ) + 0.5, 0 )
         aInches[1] := aSize[1]
         aInches[2] := aSize[2]
      ENDIF

      // Convert dimensions to RTF standard Twips (1/1440 inch)
      aInches[1] := ROUND( aInches[1] * 1440, 0 )
      aInches[2] := ROUND( aInches[2] * 1440, 0 )

      // Setup a secure, isolated temporary file path for the WMF output
      cTempFile := hb_DirTemp() + "tmp_" + PADL( ALLTRIM( STR( ::nFile, 4, 0 ) ), 4, "0" ) + ".wmf"

      // Initialize the GDI Metafile output context
      hDCOut := hwg_Createenhmetafile( hWnd, cTempFile )

      IF hDCOut != NIL .AND. hDCOut != 0
         // Setup coordinate boundaries inside the Metafile DC
         hwg_Setwindowextex( hDCOut, nWidth, nHeight )

         // Draw the bitmap handle into the Metafile Device Context
         oBmp:Draw( hDCOut, 0, 0, nWidth, nHeight )

         // Close and commit the Metafile structure to disk
         hEmf := hwg_Closeenhmetafile( hDCOut )

         IF ! Empty( hEmf )
            hwg_Deleteenhmetafile( hEmf )
         ENDIF
      ENDIF

      // Dispose of the source graphic object memory
      oBmp:Release()

      // Open the generated metafile stream to copy into the RTF document
      in := fopen( cTempFile )

      IF in >= 0
         ::OpenGroup()
         ::TextCode( "\pict\wmetafile8" )

         x := ROUND( ( ( aInches[1] * 2540 ) / 1440 ) + 0.5, 0 )
         ::NumCode( "picw", x, .F. )
         ::NumCode( "picwgoal", aInches[1], .F. )
         ::NumCode( "picscalex", scalex, .F. )

         x := ROUND( ( ( aInches[2] * 2540 ) / 1440 ) + 0.5, 0 )
         ::NumCode( "pich", x, .F. )
         ::NumCode( "pichgoal", aInches[2], .F. )
         ::NumCode( "picscaley", scaley, .F. )

         ::OpenGroup()

         // Fast binary buffer read loop using optimized 8 KB blocks
         cMenInter := Space( nBloque )
         DO WHILE .T.
            nBytes := fread( in, @cMenInter, nBloque )
            IF nBytes <= 0
               EXIT
            ENDIF
            FWRITE( ::hFile, hb_StrToHex( SubStr( cMenInter, 1, nBytes ) ) )
         ENDDO

         ::CloseGroup()
         ::CloseGroup()

         fclose( in )
         FERASE( cTempFile )
         ::nFile += 1
      ENDIF
   ENDIF

   RETURN NIL

/* Helper function to get file extension */
FUNCTION cFileExt( cFile )
   RETURN SubStr( cFile, At( '.', cFile ) + 1 )

#ifndef __XHARBOUR__
STATIC FUNCTION CStr( xExp )
   LOCAL cType

   IF xExp == NIL
      RETURN 'NIL'
   ENDIF
   cType := ValType( xExp )
   DO CASE
   CASE cType == 'C'
      RETURN xExp
   CASE cType == 'D'
      RETURN DToC( xExp )
   CASE cType == 'L'
      RETURN IIf( xExp, '.T.', '.F.' )
   CASE cType == 'N'
      RETURN Str( xExp )
   CASE cType == 'M'
      RETURN xExp
   CASE cType == 'A'
      RETURN "{ Array of " +  LTrim( Str( Len( xExp ) ) ) + " Items }"
   CASE cType == 'B'
      RETURN '{|| Block }'
   CASE cType == 'O'
      RETURN "{ " + xExp:ClassName() + " Object }"
   CASE cType == 'P'
#if defined( __XHARBOUR__ )
      RETURN NumToHex( xExp )
#else
      RETURN hb_NumToHex( xExp )
#endif
   CASE cType == 'H'
      RETURN "{ Hash of " +  LTrim( Str( Len( xExp ) ) ) + " Items }"
   OTHERWISE
      RETURN "Type: " + cType
   ENDCASE

   RETURN ""
#endif
