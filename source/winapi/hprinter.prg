/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPrinter class
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"
#include "common.ch"

STATIC crlf := e"\r\n"
#define SCREEN_PRINTER ".buffer"

// #if defined( __GTK__ ) .AND. defined( __RUSSIAN__ )
//
//   CLASS VAR cdp       SHARED  INIT "RUKOI8"
// #else
//   CLASS VAR cdp       SHARED  INIT "EN"
// #endif

   CLASS HPrinter INHERIT HObject

   CLASS VAR aPaper  INIT { { "A3", 297, 420 }, { "A4", 210, 297 }, { "A5", 148, 210 }, ;
      { "A6", 105, 148 } }

   DATA hDCPrn     INIT 0   && GTK only
   DATA hDC                 && INIT 0 on GTK
   DATA cPrinterName         && INIT "DEFAULT" on GTK
   DATA hPrinter   INIT 0
   DATA lPreview
   DATA nWidth, nHeight, nPWidth, nPHeight
   DATA nHRes, nVRes                     // Resolution ( pixels/mm )
   DATA nOrient        INIT 1
   DATA nPage

   DATA lBuffPrn   INIT .F.
   DATA lUseMeta   INIT .F.
   DATA lastPen, lastFont
   DATA aPages, aJob
   DATA aFonts INIT {}
   DATA aPens, aBitmaps
   DATA oFont, oPen
   DATA cScriptFile

   DATA lmm  INIT .F.
   DATA nCurrPage, oTrackV, oTrackH
   DATA nZoom, xOffset, yOffset, x1, y1, x2, y2

   DATA memDC       HIDDEN    // dc offscreen
   DATA memBitmap   HIDDEN    // bitmap offscreen
   DATA NeedsRedraw INIT .T.  // if offscreen needs redrawing...
   DATA FormType       INIT 0
   DATA BinNumber      INIT 0
   DATA Copies         INIT 1
   DATA fDuplexType    INIT 0      HIDDEN
   DATA fPrintQuality  INIT 0      HIDDEN
   DATA PaperLength    INIT 0                        // Value is * 1/10 of mm   1000 = 10cm
   DATA PaperWidth     INIT 0                        //   "    "    "     "       "     "
   DATA TopMargin
   DATA BottomMargin
   DATA LeftMargin
   DATA RightMargin
   DATA lprbutton      INIT .T.
   // --- International Language Support for internal dialogs --
   DATA aLangTexts

   // Print Preview Dialog with sub dialog:
   // The messages and control text's are delivered by other classes, calling
   // the method Preview() in Parameter aTooltips as an array.
   // After call of Init method, you can update the array with messages in your
   // desired language.
   // Sample: Preview( , , aTooltips, )
   // Structure of array look at
   // METHOD SetLanguage(apTooltips) CLASS HWinPrn
   // in file hwinprn.prg.
   // List of classes calling print preview
   // HWINPRN, HRepTmpl , ...
   // For more details see inline comments in sample program "nlsdemo.prg"


   // DF7BE: More methods on WinAPI as on GTK and some differences
   // Methods of GTK are here deactivated by //
   // 30 methods  

   METHOD New( cPrinter, lmm, nFormType, nBin, lLandScape, nCopies, lProprierties, hDCPrn )
   // FUNCTION hwg_HPrinter_LangArray_EN()
   METHOD DefaultLang()
   METHOD SetMode( nOrientation, nDuplex )
   METHOD Recalc( x1, y1, x2, y2 )
   METHOD AddFont( fontName, nHeight , lBold, lItalic, lUnderline, nCharset )
   METHOD SetFont( oFont )  INLINE (::oFont := oFont, hwg_Selectobject( ::hDC, oFont:handle ) )
//   METHOD AddPen( nWidth, style, color ) && GTK ONLY
//   METHOD SetPen( nWidth, style, color ) && GTK ONLY
   METHOD Settextcolor( nColor )  INLINE hwg_Settextcolor( ::hDC, nColor ) && WinAPI only
   METHOD SetTBkColor( nColor )   INLINE hwg_Setbkcolor( ::hDC, nColor ) && WinAPI only
   METHOD Setbkmode( lmode )   INLINE hwg_Setbkmode( ::hDC, IF( lmode, 1, 0 ) )  && WinAPI only
   METHOD StartDoc( lPreview, cScriptFile , lprbutton )
   METHOD EndDoc()
   METHOD StartPage()
   METHOD EndPage()
   METHOD End()
   METHOD LoadScript( cScriptFile )
   METHOD SaveScript( cScriptFile )
   METHOD Box( x1, y1, x2, y2, oPen, oBrush )
   METHOD Line( x1, y1, x2, y2, oPen )
   METHOD Say( cString, x1, y1, x2, y2, nOpt, oFont, nTextColor, nBkColor )
   METHOD Bitmap( x1, y1, x2, y2, nOpt, hBitmap, cImageName )
   METHOD Preview(cTitle, aBitmaps, aTooltips, aBootUser )
   METHOD PaintDoc( oWnd )
   METHOD PrintDoc( nPage )
   METHOD ChangePage( oCanvas, oSayPage, n, nPage ) HIDDEN   
   METHOD ReleaseMeta()  && WinAPI only
   METHOD GetTextWidth( cString, oFont )   
   METHOD PrintDlg(aTooltips)  && WinAPI only
   METHOD PrintScript( hDC, nPage, x1, y1, x2, y2 )  && WinAPI only
   METHOD ReleaseRes()  && WinAPI only
   METHOD ResizePreviewDlg( oCanvas, nZoom, msg, wParam, lParam ) HIDDEN   && WinAPI only


ENDCLASS



FUNCTION hwg_HPrinter_LangArray_EN()

  /* Returns array with captions for titles and controls of print preview dialog
  in default language english.
  Use this code snippet as template to set to your own desired language.
  */

  LOCAL aTooltips

  aTooltips := {}

  /* 1  */ AAdd(aTooltips,"Exit Preview")
  /* 2  */ AAdd(aTooltips,"Print file")
  /* 3  */ AAdd(aTooltips,"First page")
  /* 4  */ AAdd(aTooltips,"Next page")
  /* 5  */ AAdd(aTooltips,"Previous page")
  /* 6  */ AAdd(aTooltips,"Last page")
  /* 7  */ AAdd(aTooltips,"Zoom out")
  /* 8  */ AAdd(aTooltips,"Zoom in")
  /* 9  */ AAdd(aTooltips,"Print dialog")
  // added (Titles and other Buttons)
  /* 10 */ AAdd(aTooltips,"Print preview -") && Title
  /* 11 */ AAdd(aTooltips,"Print")           && Button
  /* 12 */ AAdd(aTooltips,"Exit")            && Button
  /* 13 */ AAdd(aTooltips,"Dialog")          && Button
  /* 14 */ AAdd(aTooltips,"User Button")     && aBootUser[ 3 ], Tooltip
  /* 15 */ AAdd(aTooltips,"User Button")     && aBootUser[ 4 ]
  // Subdialog "Printer Dialog"
  /* 16 */ AAdd(aTooltips,"All")             && Radio Button              "All"
  /* 17 */ AAdd(aTooltips,"Current")         && Radio Button              "Current"
  /* 18 */ AAdd(aTooltips,"Pages")           && Radio Button              "Pages"
  /* 19 */ AAdd(aTooltips,"Print")           && Button                    "Print"
  /* 20 */ AAdd(aTooltips,"Cancel")          && Button                    "Cancel"
  /* 21 */ AAdd(aTooltips,"Enter range of pages") && Tooltip              "Enter range of pages"

RETURN aTooltips


METHOD New( cPrinter, lmm, nFormType, nBin, lLandScape, nCopies, lProprierties, hDCPrn ) CLASS HPrinter

   LOCAL aPrnCoors
   LOCAL cPrinterName, nTemp

   ::DefaultLang()

   IF ValType( nFormType ) == "N"
      // A3 - DMPAPER_A3, A4 - DMPAPER_A4
      ::FormType := nFormType
   ELSE
      nFormType := DMPAPER_A4
   ENDIF
   IF ValType( nBin ) == "N"
      ::BinNumber := nBin
   ENDIF
   IF ValType( lLandScape ) == "L"
      ::nOrient := Iif( lLandScape, 2, 1 )
   ENDIF
   IF ValType( nCopies ) == "N"
      IF nCopies > 0
         ::Copies := nCopies
      ENDIF
   ENDIF
   IF ValType( lProprierties ) <> "L"
      lProprierties := .T.
   ENDIF

   IF lmm != Nil
      ::lmm := lmm
   ENDIF
   IF !Empty( hDCPrn )
      ::hDCPrn = hDCPrn
      ::cPrinterName := cPrinter
   ELSE

      IF cPrinter == Nil
         ::hDCPrn := hwg_Printsetup( @cPrinterName )
         ::cPrinterName := cPrinterName
      ELSEIF Empty( cPrinter )
         cPrinterName := HWG_GETDEFAULTPRINTER()
         ::hDCPrn := Hwg_OpenPrinter( cPrinterName )
         ::cPrinterName := cPrinterName
      ELSEIF cPrinter == SCREEN_PRINTER
         ::lBuffPrn := .T.
         ::hDCPrn := hwg_Getdc( hwg_Getactivewindow() )
         ::cPrinterName := ""
      ELSE
         ::hDCPrn := Hwg_OpenPrinter( cPrinter )
         ::cPrinterName := cPrinter
      ENDIF
   ENDIF

   IF Empty( ::hDCPrn )
      RETURN Nil
   ELSE
      IF !Empty( lProprierties ) .AND. !::lBuffPrn
         IF !Hwg_SetDocumentProperties( ::hDCPrn, ::cPrinterName, ::FormType, ::nOrient == 2, ::Copies, ::BinNumber, ::fDuplexType, ::fPrintQuality, ::PaperLength, ::PaperWidth )
            RETURN NIL
         ENDIF
      ENDIF

      aPrnCoors := hwg_Getdevicearea( ::hDCPrn )
      ::nHRes   := aPrnCoors[ 1 ] / aPrnCoors[ 3 ]
      ::nVRes   := aPrnCoors[ 2 ] / aPrnCoors[ 4 ]
      IF ::lBuffPrn
         ::nWidth  := Iif( nFormType==DMPAPER_A3, 297, 210 )
         ::nHeight := Iif( nFormType==DMPAPER_A3, 420, 297 )
         IF !::lmm
            ::nWidth  := Round( ::nHRes * ::nWidth, 0 )
            ::nHeight := Round( ::nVRes * ::nHeight, 0 )
         ENDIF
         IF ::nOrient == 2
            nTemp := ::nHeight
            ::nHeight := ::nWidth
            ::nWidth := nTemp
         ENDIF
      ELSE
         ::nWidth  := Iif( ::lmm, aPrnCoors[ 3 ], aPrnCoors[ 1 ] )
         ::nHeight := Iif( ::lmm, aPrnCoors[ 4 ], aPrnCoors[ 2 ] )
         ::nPWidth  := Iif( ::lmm, aPrnCoors[ 8 ], aPrnCoors[ 1 ] )
         ::nPHeight := Iif( ::lmm, aPrnCoors[ 9 ], aPrnCoors[ 2 ] )
      ENDIF
      //hwg_writelog( str(::nWidth)+"/"+str(::nHeight)+"/"+str(::nPWidth)+"/"+str(::nPHeight)+"/"+str(::nHRes)+"/"+str(::nVRes))
   ENDIF

   RETURN Self

METHOD DefaultLang() CLASS HPrinter

  ::aLangTexts := hwg_HPrinter_LangArray_EN()

RETURN NIL

METHOD SetMode( nOrientation, nDuplex ) CLASS HPrinter

   LOCAL hPrinter := ::hPrinter, hDC, aPrnCoors, nTemp

   IF !Empty( nOrientation )
      ::nOrient := nOrientation
   ENDIF
   IF ::lBuffPrn
      IF ::nOrient != Iif( ::nHeight>::nWidth, 1, 2 )
         nTemp := ::nHeight
         ::nHeight := ::nWidth
         ::nWidth := nTemp
      ENDIF
   ELSE
      hDC := hwg_Setprintermode( ::cPrinterName, @hPrinter, nOrientation, nDuplex )
      IF hDC != Nil
         IF !Empty( ::hDCPrn )
            hwg_Deletedc( ::hDCPrn )
         ENDIF
         ::hDCPrn := hDC
         ::hPrinter := hPrinter
         aPrnCoors := hwg_Getdevicearea( ::hDCPrn )
         ::nWidth  := Iif( ::lmm, aPrnCoors[ 3 ], aPrnCoors[ 1 ] )
         ::nHeight := Iif( ::lmm, aPrnCoors[ 4 ], aPrnCoors[ 2 ] )
         ::nPWidth  := Iif( ::lmm, aPrnCoors[ 8 ], aPrnCoors[ 1 ] )
         ::nPHeight := Iif( ::lmm, aPrnCoors[ 9 ], aPrnCoors[ 2 ] )
         ::nHRes   := aPrnCoors[ 1 ] / aPrnCoors[ 3 ]
         ::nVRes   := aPrnCoors[ 2 ] / aPrnCoors[ 4 ]
         RETURN .T.
      ENDIF
   ENDIF

   RETURN .F.

/* Added: , nCharset */
METHOD AddFont( fontName, nHeight , lBold, lItalic, lUnderline, nCharset ) CLASS HPrinter

   LOCAL oFont

   IF ::lmm .AND. nHeight != Nil
      nHeight := Round( nHeight * ::nVRes, 0 )
   ENDIF
   oFont := HFont():Add( fontName, , nHeight,          ;
      Iif( lBold != Nil .AND. lBold, 700, 400 ), nCharset, ;
      Iif( lItalic != Nil .AND. lItalic, 255, 0 ), Iif( lUnderline != Nil .AND. lUnderline, 1, 0 ) )

   RETURN oFont

METHOD End() CLASS HPrinter

   IF !Empty( ::hDCPrn )
      IF ::lBuffPrn
         hwg_Releasedc( hwg_Getactivewindow(), ::hDCPrn )
      ELSE
         hwg_Deletedc( ::hDCPrn )
      ENDIF
      ::hDCPrn := Nil
   ENDIF
   IF !Empty( ::hPrinter )
      hwg_Closeprinter( ::hPrinter )
   ENDIF
   ::ReleaseMeta()
   ::ReleaseRes()

   RETURN Nil

METHOD ReleaseRes() CLASS HPrinter

   LOCAL i

   IF !Empty( ::aFonts )
      FOR i := 1 TO Len( ::aFonts )
         ::aFonts[i]:Release()
      NEXT
      ::aFonts := Nil
   ENDIF
   IF !Empty( ::aPens )
      FOR i := 1 TO Len( ::aPens )
         ::aPens[i]:Release()
      NEXT
      ::aPens := Nil
   ENDIF
   IF !Empty( ::aBitmaps )
      FOR i := 1 TO Len( ::aBitmaps )
         IF !::aBitmaps[i,3]
            hwg_Deleteobject( ::aBitmaps[i,2] )
         ENDIF
      NEXT
      ::aBitmaps := Nil
   ENDIF

   RETURN Nil

METHOD Recalc( x1, y1, x2, y2 ) CLASS HPrinter

   IF ::lmm
      x1 := Round( x1 * ::nHRes, 1 )
      x2 := Round( x2 * ::nHRes, 1 )
      y1 := Round( y1 * ::nVRes, 1 )
      y2 := Round( y2 * ::nVRes, 1 )
   ENDIF

   RETURN Nil

METHOD Box( x1, y1, x2, y2, oPen, oBrush ) CLASS HPrinter

   ::Recalc( @x1, @y1, @x2, @y2 )

   IF !::lUseMeta .AND. ::lPreview
      IF oPen != Nil
         IF Empty( ::lastPen ) .OR. oPen:width != ::lastPen:width .OR. ;
               oPen:style != ::lastPen:style .OR. oPen:color != ::lastPen:color
            ::lastPen := oPen
            ::aPages[::nPage] += "pen," + LTrim( Str( oPen:width ) ) + "," + ;
               LTrim( Str( oPen:style ) ) + "," + LTrim( Str( oPen:color ) ) + "," + crlf
         ENDIF
      ENDIF

      ::aPages[::nPage] += "box," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
         LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + crlf
   ELSE
      IF oPen != Nil
         hwg_Selectobject( ::hDC, oPen:handle )
      ENDIF
      IF oBrush != Nil
         hwg_Selectobject( ::hDC, oBrush:handle )
      ENDIF

      hwg_Rectangle( ::hDC, x1, y1, x2, y2 )
   ENDIF

   RETURN Nil

METHOD Line( x1, y1, x2, y2, oPen ) CLASS HPrinter

   ::Recalc( @x1, @y1, @x2, @y2 )

   IF !::lUseMeta .AND. ::lPreview
      IF oPen != Nil
         IF Empty( ::lastPen ) .OR. oPen:width != ::lastPen:width .OR. ;
               oPen:style != ::lastPen:style .OR. oPen:color != ::lastPen:color
            ::lastPen := oPen
            ::aPages[::nPage] += "pen," + LTrim( Str( oPen:width ) ) + "," + ;
               LTrim( Str( oPen:style ) ) + "," + LTrim( Str( oPen:color ) ) + "," + crlf
         ENDIF
      ENDIF

      ::aPages[::nPage] += "lin," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
         LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + "," + crlf
   ELSE
      IF oPen != Nil
         hwg_Selectobject( ::hDC, oPen:handle )
      ENDIF
      hwg_Drawline( ::hDC, x1, y1, x2, y2 )
   ENDIF

   RETURN Nil

METHOD Say( cString, x1, y1, x2, y2, nOpt, oFont, nTextColor, nBkColor ) CLASS HPrinter

   LOCAL hFont, nOldTC, nOldBC, lTr

   ::Recalc( @x1, @y1, @x2, @y2 )

   IF !::lUseMeta .AND. ::lPreview
      IF oFont == Nil
         oFont := ::oFont
      ENDIF
      IF oFont != Nil
         IF ( ::lastFont == Nil .OR. !( ::lastFont:name == oFont:name .AND. ;
               ::lastFont:height == oFont:height .AND. ;
               ::lastFont:weight == oFont:weight .AND. ;
               ::lastFont:Italic == oFont:Italic .AND. ;
               ::lastFont:Underline == oFont:Underline ) )
            ::lastFont := oFont
            ::aPages[::nPage] += "fnt," + oFont:name + "," + LTrim( Str( oFont:height ) ) + "," + ;
               LTrim( Str( oFont:weight ) ) + "," + LTrim( Str( oFont:Italic ) ) + "," + ;
               LTrim( Str( oFont:Underline ) ) + "," + LTrim( Str( oFont:Charset ) ) + crlf
         ENDIF
      ENDIF

      // hwg_xvalLog(x1)

      /* DF7BE: x1 is not forever of type N, so STR() crashes with argument error */
      IF hwg_ValType(x1) != "N"
         x1 := 0
      ENDIF


      ::aPages[::nPage] += "txt," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
         LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + "," + ;
         Iif( nOpt == Nil, ",", LTrim( Str(nOpt ) ) + "," ) + cString + crlf
   ELSE
      IF oFont != Nil
         hFont := hwg_Selectobject( ::hDC, oFont:handle )
      ENDIF
      IF nTextColor != Nil
         nOldTC := hwg_Settextcolor( ::hDC, nTextColor )
      ENDIF
      IF nBkColor != Nil
         nOldBC := hwg_Setbkcolor( ::hDC, nBkColor )
      ENDIF

      lTr := hwg_Settransparentmode( ::hDC, .T. )
      hwg_Drawtext( ::hDC, cString, x1, y1, x2, y2, Iif( nOpt == Nil, DT_LEFT, nOpt ) )
      hwg_Settransparentmode( ::hDC, lTr )

      IF oFont != Nil
         hwg_Selectobject( ::hDC, hFont )
      ENDIF
      IF nTextColor != Nil
         hwg_Settextcolor( ::hDC, nOldTC )
      ENDIF
      IF nBkColor != Nil
         hwg_Setbkcolor( ::hDC, nOldBC )
      ENDIF

   ENDIF

   RETURN Nil

METHOD Bitmap( x1, y1, x2, y2, nOpt, hBitmap, cImageName ) CLASS HPrinter

   ::Recalc( @x1, @y1, @x2, @y2 )

   IF !::lUseMeta .AND. ::lPreview
      ::aPages[::nPage] += "img," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
         LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + "," + ;
         Iif( nOpt == Nil, ",", LTrim( Str(nOpt ) ) + "," ) + cImageName + crlf
      IF !Empty( hBitmap ) .AND. Ascan( ::aBitmaps, {|a|a[1]==cImageName} ) == 0
         Aadd( ::aBitmaps, { cImageName, hBitmap, .T. } )
      ENDIF
   ELSE
      hwg_Drawbitmap( ::hDC, hBitmap, Iif( nOpt == Nil, SRCAND, nOpt ), x1, y1, x2 - x1 + 1, y2 - y1 + 1 )
   ENDIF

   RETURN Nil

METHOD GetTextWidth( cString, oFont ) CLASS HPrinter

   LOCAL arr, hFont, hDC := Iif( ::lUseMeta, ::hDC, ::hDCPrn )

   IF oFont != Nil
      hFont := hwg_Selectobject( hDC, oFont:handle )
   ENDIF
   arr := hwg_Gettextsize( hDC, cString )
   IF oFont != Nil
      hwg_Selectobject( hDC, hFont )
   ENDIF

   RETURN Iif( ::lmm, Int( arr[ 1 ] / ::nHRes ), arr[ 1 ] )

METHOD StartDoc( lPreview, cScriptFile , lprbutton ) CLASS HPrinter

   LOCAL nRes := 0

   IF lprbutton == NIL
      ::lprbutton := .T.
   ELSE
      ::lprbutton := lprbutton
   ENDIF

   IF !Empty( lPreview ) .OR. ::lBuffPrn
      ::lPreview := .T.
      IF ::lUseMeta
         ::ReleaseMeta()
      ENDIF
      ::aJob := { , LTrim( Str(Iif(::lmm,::nWidth*::nHRes,::nWidth) ) ), ;
            LTrim( Str(Iif(::lmm,::nHeight*::nVRes,::nHeight) ) ), LTrim( Str(::nHRes,11,4 ) ), LTrim( Str(::nVRes,11,4 ) ) }
      ::ReleaseRes()
      ::aPages := {}
      ::aFonts := {}
      ::aPens := {}
      ::aBitmaps := {}
      ::cScriptFile := cScriptFile
   ELSE
      ::lPreview := .F.
      ::hDC := ::hDCPrn
      nRes := Hwg_StartDoc( ::hDC, "HwGUIPrint" )
   ENDIF
   ::nPage := 0

   RETURN nRes

METHOD EndDoc() CLASS HPrinter

   LOCAL  nRes := 0

   * Variables not used
   * i, han

   IF !::lUseMeta .AND. ::lPreview .AND. !Empty( ::cScriptFile )
      ::SaveScript()
   ENDIF

   IF ! ::lPreview
      nRes := Hwg_EndDoc( ::hDC )
   ENDIF

   RETURN nRes

METHOD StartPage() CLASS HPrinter

   LOCAL nRes := 0

   * Variables not used
   * fname

   ::nPage ++
   IF ::lPreview
      IF ::lUseMeta
         AAdd( ::aPages, hwg_Createmetafile( ::hDCPrn, Nil ) )
         ::hDC := ATail( ::aPages )
      ELSE
         AAdd( ::aPages, "page," + LTrim( Str( ::nPage ) ) + "," + ;
            Iif( ::lmm, "mm,", "px," ) + Iif( ::nOrient == 1, "p", "l" ) + crlf )
      ENDIF
   ELSE
      nRes := Hwg_StartPage( ::hDC )
   ENDIF

   RETURN nRes

METHOD EndPage() CLASS HPrinter

   LOCAL nLen, nRes := 0

   IF ::lPreview
      IF ::lUseMeta
         nLen := Len( ::aPages )
         ::aPages[ nLen ] := hwg_Closeenhmetafile( ::aPages[ nLen ] )
         ::hDC := 0
      ENDIF
   ELSE
      nRes := Hwg_EndPage( ::hDC )
   ENDIF

   RETURN nRes

METHOD LoadScript( cScriptFile ) CLASS HPrinter

   LOCAL arr, i, s

   IF Empty( cScriptFile ) .OR. Empty( arr := hb_aTokens( MemoRead( cScriptFile ), crlf ) )
      RETURN .F.
   ENDIF
   ::cScriptFile := cScriptFile
   ::aPages := {}

   ::aJob := hb_aTokens( arr[1], "," )

   FOR i := 1 TO Len( arr )
      IF Left( arr[i], 4 ) == "page"
         IF !Empty( s )
            AAdd( ::aPages, s )
         ENDIF
         s := arr[i] + crlf
      ELSEIF !Empty( arr[i] ) .AND. !Empty( s )
         s += arr[i] + crlf
      ENDIF
   NEXT
   IF !Empty( s )
      AAdd( ::aPages, s )
   ENDIF

   RETURN !Empty( ::aPages )

METHOD SaveScript( cScriptFile ) CLASS HPrinter

   LOCAL han, i

   IF Empty( cScriptFile )
      IF Empty( ::cScriptFile )
         cScriptFile := ::cScriptFile := hwg_Savefile( "*.*","All files( *.* )","*.*",Curdir() )
      ELSE
         cScriptFile := ::cScriptFile
      ENDIF
   ENDIF

   IF !Empty( cScriptFile )
      // hwg_MsgInfo("Scriptfile=" + cScriptFile )
      // Default scriptfile is "temp_a2.ps"
      han := FCreate( cScriptFile )
      FWrite( han, "job," + ;
            LTrim( Str(Iif(::lmm,::nWidth*::nHRes,::nWidth) ) ) + "," + ;
            LTrim( Str(Iif(::lmm,::nHeight*::nVRes,::nHeight) ) ) + "," + ;
            LTrim( Str(::nHRes,11,4 ) ) + "," + LTrim( Str(::nVRes,11,4 ) ) + "," + hb_cdpSelect() + crlf )
      FOR i := 1 TO Len( ::aPages )
         FWrite( han, ::aPages[i] + crlf )
      NEXT
      FClose( han )
   ENDIF

   RETURN Nil

METHOD ReleaseMeta() CLASS HPrinter

   LOCAL i, nLen

   IF !::lUseMeta == Nil
      RETURN Nil
   ENDIF

   nLen := Len( ::aPages )
   FOR i := 1 TO nLen
      hwg_Deleteenhmetafile( ::aPages[ i ] )
   NEXT
   ::aPages := Nil

   RETURN Nil

METHOD Preview( cTitle, aBitmaps, aTooltips, aBootUser) CLASS HPrinter

/*
aBootUser[ 1 ] : oBtn:bClick
aBootUser[ 2 ] : AddResource(Bitmap)
aBootUser[ 3 ] : "User Button", Tooltip ==> cBootUser3
aBootUser[ 4 ] : "User Button"          ==> cBootUser4

Default values in array aTooltips see
FUNCTION hwg_HPrinter_LangArray_EN()
*/

   LOCAL cmExit, cmPrint, cmDialog, cmTitle
   LOCAL oDlg, oToolBar, oSayPage, oBtn, oCanvas, i, aPage && := { }
   LOCAL oFont := HFont():Add( "Times New Roman", 0, - 13, 700 )
   LOCAL lTransp := ( aBitmaps != Nil .AND. Len( aBitmaps ) > 9 .AND. aBitmaps[ 10 ] != Nil .AND. aBitmaps[ 10 ] )

   * Variables not used
   * cBootUser3, cBootUser4

   aPage := Array( Len( ::aPages ) )
   FOR i := 1 TO Len( aPage )
      aPage[i] := Str( i, 4 ) + ":" + Str( Len( aPage ), 4 )
   NEXT

   // Button and title default captions
   // "Print preview -", see above
   cmExit         := "Exit"
   cmPrint        := "Print"
   cmDialog       := "Dialog"
*   cBootUser3     := "User Button"
*   cBootUser4     := "User Button"
   cmTitle        := "Print preview - " + ::cPrinterName

   /* Parameter cTitle preferred */
   IF cTitle == Nil
    cTitle := cmTitle
    IF aTooltips != Nil
      cTitle := aTooltips[ 10 ] + " " + ::cPrinterName
    ENDIF
   ELSE
    cTitle := cmTitle
   ENDIF
   IF aTooltips != Nil
      cmPrint    := aTooltips[ 11 ]
      cmExit     := aTooltips[ 12 ]
      cmDialog   := aTooltips[ 13 ]
 *     cBootUser3 := aTooltips[ 14 ]
 *     cBootUser4 := aTooltips[ 15 ]
   ENDIF

   ::nZoom := 0
   ::nCurrPage := 1

   ::NeedsRedraw := .T.

   INIT DIALOG oDlg TITLE cTitle ;
      At 40, 10 SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() ;
      STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + WS_MAXIMIZEBOX + WS_CLIPCHILDREN ;
      ON INIT { | o | o:Maximize(), ::ResizePreviewDlg( oCanvas, 1 ) } ;
      ON EXIT { || oCanvas:brush := NIL, .T. }

   oDlg:bScroll := { | oWnd, msg, wParam, lParam | HB_SYMBOL_UNUSED( oWnd ), ::ResizePreviewDlg( oCanvas, , msg, wParam, lParam ) }
   oDlg:brush := HBrush():Add( 11316396 )

   @ 0, 0 PANEL oToolBar SIZE 88, oDlg:nHeight

   // Canvas should fill ALL the available space
   @ oToolBar:nWidth, 0 PANEL oCanvas ;
      SIZE oDlg:nWidth - oToolBar:nWidth, oDlg:nHeight ;
      ON SIZE { | o, x, y | o:Move( , , x - oToolBar:nWidth, y ), ::ResizePreviewDlg( o ) } ;
      ON PAINT { || ::PaintDoc( oCanvas ) } STYLE WS_VSCROLL + WS_HSCROLL

   oCanvas:bScroll := { | oWnd, msg, wParam, lParam | HB_SYMBOL_UNUSED( oWnd ), ::ResizePreviewDlg( oCanvas, , msg, wParam, lParam ) }
   IF !::lUseMeta
      oCanvas:bOther := { |o,m,wp,lp|HB_SYMBOL_UNUSED(wp),Iif(m==WM_LBUTTONDBLCLK,MessProc(Self,o,lp),-1) }
      SET KEY FCONTROL, ASC("S") TO ::SaveScript()
   ENDIF
   // DON'T CHANGE NOR REMOVE THE FOLLOWING LINE !
   // I need it to have the correct side-effect to avoid flickering !!!
   oCanvas:brush := 0

   @ 3, 2 OWNERBUTTON oBtn OF oToolBar ON CLICK { || hwg_EndDialog() } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT cmExit FONT oFont              ;  && "Exit"
      TOOLTIP Iif( aTooltips != Nil, aTooltips[ 1 ], "Exit Preview" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 1 .AND. aBitmaps[ 2 ] != Nil
      oBtn:oBitmap  := Iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 2 ] ), HBitmap():AddFile( aBitmaps[ 2 ] ) )
      oBtn:title    := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1, 31 LINE LENGTH oToolBar:nWidth - 1

  IF ::lprbutton
   @ 3, 36 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::PrintDoc() } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT cmPrint FONT oFont           ;  && "Print"
      TOOLTIP Iif( aTooltips != Nil, aTooltips[ 2 ], "Print file" )
  ENDIF


   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 2 .AND. aBitmaps[ 3 ] != Nil
      oBtn:oBitmap := Iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 3 ] ), HBitmap():AddFile( aBitmaps[ 3 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 66 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::PrintDlg(aTooltips) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT cmDialog FONT oFont          ;  && "Dialog"
      TOOLTIP Iif( aTooltips!=Nil .AND. Len(aTooltips)>8, aTooltips[ 9 ], "Print dialog" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 8 .AND. aBitmaps[ 9 ] != Nil
      oBtn:oBitmap := Iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 9 ] ), HBitmap():AddFile( aBitmaps[ 9 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 92 COMBOBOX oSayPage ITEMS aPage of oToolBar ;
      SIZE oToolBar:nWidth - 6, 24 COLOR "fff000" backcolor 12507070 DISPLAYCOUNT 4;
      ON CHANGE { || ::ChangePage( oCanvas, oSayPage, , oSayPage:GetValue() ) } STYLE WS_VSCROLL


   @ 3, 116 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ChangePage( oCanvas, oSayPage, 0 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT "|<<" FONT oFont                 ;
      TOOLTIP Iif( aTooltips != Nil, aTooltips[ 3 ], "First page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 3 .AND. aBitmaps[ 4 ] != Nil
      oBtn:oBitmap := Iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 4 ] ), HBitmap():AddFile( aBitmaps[ 4 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 140 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ChangePage( oCanvas, oSayPage, 1 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT ">" FONT oFont                  ;
      TOOLTIP Iif( aTooltips != Nil, aTooltips[ 4 ], "Next page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 4 .AND. aBitmaps[ 5 ] != Nil
      oBtn:oBitmap := Iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 5 ] ), HBitmap():AddFile( aBitmaps[ 5 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 164 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ChangePage( oCanvas, oSayPage, - 1 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT "<" FONT oFont    ;
      TOOLTIP Iif( aTooltips != Nil, aTooltips[ 5 ], "Previous page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 5 .AND. aBitmaps[ 6 ] != Nil
      oBtn:oBitmap := Iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 6 ] ), HBitmap():AddFile( aBitmaps[ 6 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 188 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ChangePage( oCanvas, oSayPage, 2 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT ">>|" FONT oFont   ;
      TOOLTIP Iif( aTooltips != Nil, aTooltips[ 6 ], "Last page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 6 .AND. aBitmaps[ 7 ] != Nil
      oBtn:oBitmap := Iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 7 ] ), HBitmap():AddFile( aBitmaps[ 7 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1, 219 LINE LENGTH oToolBar:nWidth - 1

   @ 3, 222 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ResizePreviewDlg( oCanvas, - 1 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT "(-)" FONT oFont   ;
      TOOLTIP Iif( aTooltips != Nil, aTooltips[ 7 ], "Zoom out" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 7 .AND. aBitmaps[ 8 ] != Nil
      oBtn:oBitmap := Iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 8 ] ), HBitmap():AddFile( aBitmaps[ 8 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 246 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ResizePreviewDlg( oCanvas, 1 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT "(+)" FONT oFont   ;
      TOOLTIP Iif( aTooltips != Nil, aTooltips[ 8 ], "Zoom in" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 8 .AND. aBitmaps[ 9 ] != Nil
      oBtn:oBitmap := Iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 9 ] ), HBitmap():AddFile( aBitmaps[ 9 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1, 273 LINE LENGTH oToolBar:nWidth - 1

   IF aBootUser != Nil

      @ 1, 343 LINE LENGTH oToolBar:nWidth - 1

      @ 3, 346 OWNERBUTTON oBtn OF oToolBar  ;
         SIZE oToolBar:nWidth - 6, 24        ;
         TEXT Iif( Len( aBootUser ) == 4, aBootUser[ 4 ], "User Button" ) ;
         FONT oFont                   ;
         TOOLTIP Iif( aBootUser[ 3 ] != Nil, aBootUser[ 3 ], "User Button" )

      oBtn:bClick := aBootUser[ 1 ]

      IF aBootUser[ 2 ] != Nil
         oBtn:oBitmap := Iif( aBitmaps[ 1 ], HBitmap():AddResource( aBootUser[ 2 ] ), HBitmap():AddFile( aBootUser[ 2 ] ) )
         oBtn:title   := Nil
         oBtn:lTransp := lTransp
      ENDIF

   ENDIF

   oDlg:Activate()

   oDlg:brush:Release()
   oFont:Release()
   IF !::lUseMeta
      ::ReleaseRes()
   ENDIF

   RETURN Nil

METHOD ChangePage( oCanvas, oSayPage, n, nPage ) CLASS hPrinter

   IF nPage == nil
      IF n == 0
         ::nCurrPage := 1
      ELSEIF n == 2
         ::nCurrPage := Len( ::aPages )
      ELSEIF n == 1 .AND. ::nCurrPage < Len( ::aPages )
         ::nCurrPage ++
      ELSEIF n == - 1 .AND. ::nCurrPage > 1
         ::nCurrPage --
      ENDIF
      oSayPage:SetItem( ::nCurrPage )
   ELSE
      ::nCurrPage := nPage
   ENDIF
   ::NeedsRedraw := .T.
   hwg_Setscrollpos( oCanvas:handle, SB_VERT, 1 )
   hwg_Setscrollpos( oCanvas:handle, SB_HORZ, 1 )
   ::ResizePreviewDlg( oCanvas,, 0 )
   //hwg_Redrawwindow( oCanvas:handle, RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW + RDW_INVALIDATE )

   RETURN Nil



/***
 nZoom: zoom factor: -1 or 1, NIL if scroll message
*/

METHOD ResizePreviewDlg( oCanvas, nZoom, msg, wParam, lParam ) CLASS hPrinter

   LOCAL nWidth, nHeight, k1, k2, x, y
   LOCAL i, nPos, wmsg, nPosVert, nPosHorz

   x := oCanvas:nWidth
   y := oCanvas:nHeight

   HB_SYMBOL_UNUSED( lParam )

   nPosVert := hwg_Getscrollpos( oCanvas:handle, SB_VERT )
   nPosHorz := hwg_Getscrollpos( oCanvas:handle, SB_HORZ )

   IF msg = WM_VSCROLL
      hwg_Setscrollrange( oCanvas:handle, SB_VERT, 1, 20 )
      wmsg := hwg_Loword( wParam )
      IF wmsg = SB_THUMBPOSITION .OR. wmsg = SB_THUMBTRACK
         nPosVert := hwg_Hiword( wParam )
      ELSEIF wmsg = SB_LINEUP
         nPosVert := nPosVert - 1
         IF nPosVert < 1
            nPosVert := 1
         ENDIF
      ELSEIF wmsg = SB_LINEDOWN
         nPosVert := nPosVert + 1
         IF nPosVert > 20
            nPosVert = 20
         ENDIF
      ELSEIF wmsg = SB_PAGEDOWN
         nPosVert := nPosVert + 4
         IF nPosVert > 20
            nPosVert = 20
         ENDIF
      ELSEIF wmsg = SB_PAGEUP
         nPosVert := nPosVert - 4
         IF nPosVert < 1
            nPosVert = 1
         ENDIF
      ENDIF
      hwg_Setscrollpos( oCanvas:handle, SB_VERT, nPosVert )
      ::NeedsRedraw := .T.
   ENDIF

   IF msg = WM_HSCROLL
      hwg_Setscrollrange( oCanvas:handle, SB_HORZ, 1, 20 )
      wmsg := hwg_Loword( wParam )
      IF wmsg = SB_THUMBPOSITION .OR. wmsg = SB_THUMBTRACK
         nPosHorz := hwg_Hiword( wParam )
      ELSEIF wmsg = SB_LINEUP
         nPosHorz := nPosHorz - 1
         IF nPosHorz < 1
            nPosHorz = 1
         ENDIF
      ELSEIF wmsg = SB_LINEDOWN
         nPosHorz := nPosHorz + 1
         IF nPosHorz > 20
            nPosHorz = 20
         ENDIF
      ELSEIF wmsg = SB_PAGEDOWN
         nPosHorz := nPosHorz + 4
         IF nPosHorz > 20
            nPosHorz = 20
         ENDIF
      ELSEIF wmsg = SB_PAGEUP
         nPosHorz := nPosHorz - 4
         IF nPosHorz < 1
            nPosHorz = 1
         ENDIF
      ENDIF
      hwg_Setscrollpos( oCanvas:handle, SB_HORZ, nPosHorz )
      ::NeedsRedraw := .T.
   ENDIF

   IF msg == WM_MOUSEWHEEL
      hwg_Setscrollrange( oCanvas:handle, SB_VERT, 1, 20 )
      IF hwg_Hiword( wParam ) > 32678
         IF ++ nPosVert > 20
            nPosVert := 20
         ENDIF
      ELSE
         IF -- nPosVert < 1
            nPosVert := 1
         ENDIF
      ENDIF
      hwg_Setscrollpos( oCanvas:handle, SB_VERT, nPosVert )
      ::NeedsRedraw := .T.
   ENDIF

   IF nZoom != Nil
      // If already at maximum zoom returns
      IF nZoom < 0 .AND. ::nZoom == 0
         RETURN Nil
      ENDIF
      ::nZoom += nZoom
      ::NeedsRedraw := .T.
   ENDIF
   k1 := ::nWidth / ::nHeight
   k2 := ::nHeight / ::nWidth

   IF ::nWidth > ::nHeight
      nWidth := x - 20
      nHeight := Round( nWidth * k2, 0 )
      IF nHeight > y - 20
         nHeight := y - 20
         nWidth := Round( nHeight * k1, 0 )
      ENDIF
      ::NeedsRedraw := .T.
   ELSE
      nHeight := y - 10
      nWidth := Round( nHeight * k1, 0 )
      IF nWidth > x - 20
         nWidth := x - 20
         nHeight := Round( nWidth * k2, 0 )
      ENDIF
      ::NeedsRedraw := .T.
   ENDIF

   IF ::nZoom > 0
      FOR i := 1 TO ::nZoom
         nWidth := Round( nWidth * 1.5, 0 )
         nHeight := Round( nHeight * 1.5, 0 )
      NEXT
      ::NeedsRedraw := .T.
   ELSEIF ::nZoom == 0
      nWidth := Round( nWidth * 0.93, 0 )
      nHeight := Round( nHeight * 0.93, 0 )
   ENDIF

   ::xOffset := ::yOffset := 0
   IF nHeight > y
      nPos := nPosVert
      IF nPos > 0
         ::yOffset := Round( ( ( nPos - 1 ) / 18 ) * ( nHeight - y + 10 ), 0 )
      ENDIF
   ELSE
      hwg_Setscrollpos( oCanvas:handle, SB_VERT, 0 )
   ENDIF

   IF nWidth > x
      nPos := nPosHorz
      IF nPos > 0
         nPos := ( nPos - 1 ) / 18
         ::xOffset := Round( nPos * ( nWidth - x + 10 ), 0 )
      ENDIF
   ELSE
      hwg_Setscrollpos( oCanvas:handle, SB_HORZ, 0 )
   ENDIF

   ::x1 := Iif( nWidth < x, Round( ( x - nWidth ) / 2, 0 ), 10 ) - ::xOffset
   ::x2 := ::x1 + nWidth - 1
   ::y1 := Iif( nHeight < y, Round( ( y - nHeight ) / 2, 0 ), 10 ) - ::yOffset
   ::y2 := ::y1 + nHeight - 1

   IF nZoom != Nil .OR. msg != Nil
      hwg_Redrawwindow( oCanvas:handle, RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW + RDW_INVALIDATE )  // Force a complete redraw
   ENDIF
   //hwg_writelog( str(::x1)+" "+str(::y1)+" "+str(::x2)+" "+str(::y2)+" "+str(::xoffset)+" "+str(::yoffset) )

   RETURN Nil

METHOD PaintDoc( oWnd ) CLASS HPrinter

   LOCAL pps, hDC
   LOCAL Rect := hwg_Getclientrect( oWnd:handle )
   STATIC Brush := NIL
   STATIC BrushShadow := NIL
   STATIC BrushBorder := NIL
   STATIC BrushWhite := NIL
   STATIC BrushBlack := NIL
   STATIC BrushLine := NIL
   STATIC BrushBackground := NIL

   IF ::xOffset == Nil
      ::ResizePreviewDlg( oWnd )
   ENDIF

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( oWnd:handle, pps )

   IF ValType( ::memDC ) == "U"
      ::memDC := hDC():New()
      ::memDC:Createcompatibledc( hDC )
      ::memBitmap := hwg_Createcompatiblebitmap( hDC, Rect[ 3 ] - Rect[ 1 ], Rect[ 4 ] - Rect[ 2 ] )
      ::memDC:Selectobject( ::memBitmap )
      Brush           := HBrush():Add( hwg_Getsyscolor( COLOR_3DHILIGHT + 1 ) ):handle
      BrushWhite      := HBrush():Add( hwg_ColorRgb2N( 255, 255, 255 ) ):handle
      BrushBlack      := HBrush():Add( hwg_ColorRgb2N( 0, 0, 0 ) ):handle
      BrushLine       := HBrush():Add( hwg_ColorRgb2N( 102, 100, 92 ) ):handle
      BrushBackground := HBrush():Add( hwg_ColorRgb2N( 204, 200, 184 ) ):handle
      BrushShadow     := HBrush():Add( hwg_ColorRgb2N( 178, 175, 161 ) ):handle
      BrushBorder     := HBrush():Add( hwg_ColorRgb2N( 129, 126, 115 ) ):handle
   ENDIF

   IF ::NeedsRedraw
      // Draw the canvas background (gray)
      hwg_Fillrect( ::memDC:m_hDC, rect[ 1 ], rect[ 2 ], rect[ 3 ], rect[ 4 ], BrushBackground )
      hwg_Fillrect( ::memDC:m_hDC, rect[ 1 ], rect[ 2 ], rect[ 1 ], rect[ 4 ], BrushBorder )
      hwg_Fillrect( ::memDC:m_hDC, rect[ 1 ], rect[ 2 ], rect[ 3 ], rect[ 2 ], BrushBorder )
      // Draw the PAPER background (white)
      hwg_Fillrect( ::memDC:m_hDC, ::x1 - 1, ::y1 - 1, ::x2 + 1, ::y2 + 1, BrushLine )
      hwg_Fillrect( ::memDC:m_hDC, ::x1, ::y1, ::x2, ::y2, BrushWhite )
      // Draw the actual printer data
      IF ::lUseMeta
         hwg_Playenhmetafile( ::memDC:m_hDC, ::aPages[ ::nCurrPage ], ::x1, ::y1, ::x2, ::y2 )
      ELSE
         ::PrintScript( ::memDC:m_hDC, ::nCurrPage, ::x1, ::y1, ::x2, ::y2 )
      ENDIF

      hwg_Fillrect( ::memDC:m_hDC, ::x2, ::y1 + 2, ::x2 + 1, ::y2 + 2, BrushBlack )
      hwg_Fillrect( ::memDC:m_hDC, ::x2 + 1, ::y1 + 1, ::x2 + 2, ::y2 + 2, BrushShadow )
      hwg_Fillrect( ::memDC:m_hDC, ::x2 + 1, ::y1 + 2, ::x2 + 2, ::y2 + 2, BrushLine )
      hwg_Fillrect( ::memDC:m_hDC, ::x2 + 2, ::y1 + 2, ::x2 + 3, ::y2 + 2, BrushShadow )


      hwg_Fillrect( ::memDC:m_hDC, ::x1 + 2, ::y2, ::x2, ::y2 + 2, BrushBlack )
      hwg_Fillrect( ::memDC:m_hDC, ::x1 + 2, ::y2 + 1, ::x2 + 1, ::y2 + 2, BrushLine )
      hwg_Fillrect( ::memDC:m_hDC, ::x1 + 2, ::y2 + 2, ::x2 + 2, ::y2 + 3, BrushShadow )
      ::NeedsRedraw := .F.
   ENDIF
   hwg_Bitblt( hDC, rect[ 1 ], rect[ 2 ], rect[ 3 ], rect[ 4 ], ::memDC:m_hDC, 0, 0, SRCCOPY )

   hwg_Endpaint( oWnd:handle, pps )

   RETURN Nil

METHOD PrintDoc( nPage ) CLASS HPrinter

   LOCAL hDCBuff, cPrinterName, cTemp, lBuffPrn := ::lBuffPrn, arr
   LOCAL aPrnCoors, nWidth, nHeight, nHres, nVres

   IF ::lPreview
      ::lBuffPrn := .F.
      IF lBuffPrn
         hDCBuff := ::hDCPrn
         cPrinterName := ::cPrinterName
         ::hDCPrn := hwg_Printsetup( @cTemp )
         ::cPrinterName := cTemp

         nWidth := ::nWidth; nHeight := ::nHeight; nHres := ::nHres; nVres := ::nVres
         aPrnCoors := hwg_Getdevicearea( ::hDCPrn )
         ::nHRes   := aPrnCoors[ 1 ] / aPrnCoors[ 3 ]
         ::nVRes   := aPrnCoors[ 2 ] / aPrnCoors[ 4 ]
         ::nWidth  := Iif( ::lmm, aPrnCoors[ 3 ], aPrnCoors[ 1 ] )
         ::nHeight := Iif( ::lmm, aPrnCoors[ 4 ], aPrnCoors[ 2 ] )
         IF ::nOrient == 2
            ::SetMode( ::nOrient )
         ENDIF
      ENDIF
      ::StartDoc()
      IF nPage == Nil
         FOR nPage := 1 TO Len( ::aPages )
            IF ::lUseMeta
               hwg_Printenhmetafile( ::hDCPrn, ::aPages[ nPage ] )
            ELSE
               Hwg_StartPage( ::hDCPrn )
               ::PrintScript( ::hDCPrn, nPage )
               Hwg_EndPage( ::hDCPrn )
            ENDIF
         NEXT
      ELSEIF Valtype( nPage ) == "A"
         arr := nPage
         FOR nPage := 1 TO Len( arr )
            IF ::lUseMeta
               hwg_Printenhmetafile( ::hDCPrn, ::aPages[ arr[nPage] ] )
            ELSE
               Hwg_StartPage( ::hDCPrn )
               ::PrintScript( ::hDCPrn, arr[nPage] )
               Hwg_EndPage( ::hDCPrn )
            ENDIF
         NEXT
      ELSE
         IF ::lUseMeta
            hwg_Printenhmetafile( ::hDCPrn, ::aPages[ nPage ] )
         ELSE
            Hwg_StartPage( ::hDCPrn )
            ::PrintScript( ::hDCPrn, nPage )
            Hwg_EndPage( ::hDCPrn )
         ENDIF
      ENDIF
      ::EndDoc()
      IF lBuffPrn
         hwg_Deletedc( ::hDCPrn )
         ::hDCPrn := hDCBuff
         ::cPrinterName := cPrinterName
         ::nWidth := nWidth; ::nHeight := nHeight; ::nHres := nHres; ::nVres := nVres
      ENDIF
      ::lPreview := .T.
      ::lBuffPrn := lBuffPrn
   ENDIF

   RETURN Nil

METHOD PrintDlg(aTooltips) CLASS HPrinter

   LOCAL oDlg, oGet, nChoic := 1, cpages := "", arr, arrt, i, j, n1, n2, nPos

   IF aTooltips == Nil
    aTooltips := ::aLangTexts
   ENDIF

   INIT DIALOG oDlg TITLE aTooltips[9]  ; && "Print dialog"
      At 40, 10 SIZE 220, 230 STYLE DS_CENTER

   GET RADIOGROUP nChoic
   @ 20,20 RADIOBUTTON aTooltips[16] SIZE 150, 22 ON CLICK {||oGet:Disable()}  && "All"
   @ 20,46 RADIOBUTTON aTooltips[17] SIZE 150, 22 ON CLICK {||oGet:Disable()}  && "Current"
   @ 20,70 RADIOBUTTON aTooltips[18] SIZE 150, 22 ON CLICK {||oGet:Enable()}   && "Pages", former ""
   END RADIOGROUP

   @ 40,100 GET oGet VAR cpages SIZE 160, 24 ;
   TOOLTIP aTooltips[21]   && "Enter range of pages"
   oGet:Disable()

   @  20, 150  BUTTON aTooltips[19] SIZE 80, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }  && "Print"
   @ 120, 150  BUTTON aTooltips[20] ID IDCANCEL SIZE 80, 32   && "Cancel"

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF nChoic == 1
         ::PrintDoc()
      ELSEIF nChoic == 2
         ::PrintDoc( ::nCurrPage )
      ELSEIF !Empty( cpages )
         arr := {}
         arrt := hb_aTokens( cpages, ',' )
         FOR i := 1 TO Len( arrt )
            Aadd( arr, n1 := Val( Ltrim( arrt[i] ) ) )
            IF ( nPos := At( '-', arrt[i] ) ) != 0
               n2 := Val( Ltrim( Substr( arrt[i],nPos+1 ) ) )
               FOR j := n1+1 TO n2
                  Aadd( arr, j )
               NEXT
            ENDIF
         NEXT
         ::PrintDoc( arr )
      ENDIF
   ENDIF

   RETURN Nil

METHOD PrintScript( hDC, nPage, x1, y1, x2, y2 ) CLASS HPrinter

   LOCAL i, j, arr, nPos, sCom
   LOCAL nOpt, cTemp
   LOCAL name, height, weight, italic, underline, charset, oFont
   LOCAL width, style, color, oPen, hBitmap
   LOCAL nWidth, nHeight, nHRes, nVRes, nHResNew, nVResNew, xOff, yOff

   IF Empty( ::aPages ) .OR. Empty( nPage ) .OR. Len( ::aPages ) < nPage .OR. ;
         Empty( arr := hb_aTokens( ::aPages[nPage], crlf ) )
      RETURN Nil
   ENDIF

   nWidth := Val( ::aJob[2] )
   nHeight := Val( ::aJob[3] )
   nHRes := Val( ::aJob[4] )
   nVRes := Val( ::aJob[5] )

   IF x1 == Nil
      nHResNew := ::nHRes
      nVResNew := ::nVRes
      nHRes *= ( (nWidth/nHRes) / Iif(::lmm,::nWidth,::nWidth/::nHRes) )
      nVRes *= ( (nHeight/nVRes) / Iif(::lmm,::nHeight,::nHeight/::nVRes) )
      xOff := 0
      yOff := 0
   ELSE
      nHResNew := (x2-x1)/( nWidth/nHres )
      nVResNew := (y2-y1)/( nHeight/nVres )
      xOff := x1
      yOff := y1
   ENDIF
   FOR i := 1 TO Len( arr )
      nPos := 0
      sCom := hb_TokenPtr( arr[i], @nPos, "," )
      IF sCom $ "txt;lin;box;img"
         x1 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nHResNew / nHres, 0 ) + xOff
         y1 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVResNew / nVres, 0 ) + yOff
         x2 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nHResNew / nHres, 0 ) + xOff
         y2 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVResNew / nVres, 0 ) + yOff

         IF sCom == "txt"
            nOpt := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
            cTemp := SubStr( arr[i], nPos+1 )
            j := hwg_Settransparentmode( hDC, .T. )
            hwg_Drawtext( hDC, cTemp, x1, y1, x2, y2, nOpt )
            hwg_Settransparentmode( hDC, j )

         ELSEIF sCom == "lin"
            hwg_Drawline( hDC, x1, y1, x2, y2 )

         ELSEIF sCom == "box"
            hwg_Rectangle( hDC, x1, y1, x2, y2 )

         ELSEIF sCom == "img"
            nOpt := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
            cTemp := SubStr( arr[i], nPos+1 )

            IF ( j := Ascan( ::aBitmaps, {|a|a[1]==cTemp} ) ) == 0
               hBitmap := hwg_Openbitmap( cTemp, hDC )
               Aadd( ::aBitmaps, { cTemp, hBitmap, .F. } )
            ELSE
               hBitmap := ::aBitmaps[j,2]
            ENDIF
            hwg_Drawbitmap( hDC, hBitmap, Iif( Empty(nOpt), SRCAND, nOpt ), x1, y1, x2 - x1 + 1, y2 - y1 + 1 )
         ENDIF

      ELSEIF sCom == "fnt"
         name := hb_TokenPtr( arr[i], @nPos, "," )
         height := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVResNew / nVres, 0 )
         weight := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         italic := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         underline := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         charset := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         FOR j := 1 TO Len( ::aFonts )
            IF ::aFonts[j]:name == name .AND. ::aFonts[j]:height == height .AND. ;
               ::aFonts[j]:weight == weight .AND. ::aFonts[j]:italic == italic .AND. ;
               ::aFonts[j]:underline == underline .AND. ::aFonts[j]:charset == charset
               EXIT
            ENDIF
         NEXT
         IF j > Len( ::aFonts )
            oFont := HFont():Add( name,, height, weight, charset, italic, underline )
            Aadd( ::aFonts, oFont )
         ELSE
            oFont := ::aFonts[j]
         ENDIF
         hwg_Selectobject( hDC, oFont:handle )

      ELSEIF sCom == "pen"
         width := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVResNew / nVres, 0 )
         style := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         color := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         FOR j := 1 TO Len( ::aPens )
            IF ::aPens[j]:width == width .AND. ::aPens[j]:style == style .AND. ::aPens[j]:color == color
               EXIT
            ENDIF
         NEXT
         IF j > Len( ::aPens )
            oPen := HPen():Add( style, width, color )
            Aadd( ::aPens, oPen )
         ELSE
            oPen := ::aPens[j]
         ENDIF
         hwg_Selectobject( hDC, oPen:handle )
      ENDIF
   NEXT

   RETURN Nil

STATIC FUNCTION MessProc( oPrinter, oPanel, lParam )

   LOCAL xPos, yPos, nPage := oPrinter:nCurrPage, arr, i, j, nPos, x1, y1, x2, y2, cTemp
   LOCAL nHRes, nVRes

   xPos := hwg_Loword( lParam )
   yPos := hwg_Hiword( lParam )

   nHRes := (oPrinter:x2-oPrinter:x1)/Iif( oPrinter:lmm, oPrinter:nWidth, oPrinter:nWidth/oPrinter:nHRes )
   nVRes := (oPrinter:y2-oPrinter:y1)/Iif( oPrinter:lmm, oPrinter:nHeight, oPrinter:nHeight/oPrinter:nVRes )

   arr := hb_aTokens( oPrinter:aPages[nPage], crlf )
   FOR i := 1 TO Len( arr )
      nPos := 0
      IF hb_TokenPtr( arr[i], @nPos, "," ) == "txt"
         x1 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nHRes / oPrinter:nHres, 0 ) + oPrinter:x1
         y1 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVRes / oPrinter:nVres, 0 ) + oPrinter:y1
         x2 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nHRes / oPrinter:nHres, 0 ) + oPrinter:x1
         y2 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVRes / oPrinter:nVres, 0 ) + oPrinter:y1
         IF xPos >= x1 .AND. xPos <= x2 .AND. yPos >= y1 .AND. yPos <= y2
            EXIT
         ENDIF
      ENDIF
   NEXT
   IF i <= Len( arr )
      hb_TokenPtr( arr[i], @nPos, "," )
      IF !Empty( cTemp := hwg_MsgGet( "",,ES_AUTOHSCROLL,,,DS_CENTER,SubStr( arr[i], nPos+1 ) ) ) .AND. !( cTemp == SubStr(arr[i],nPos+1) )
         oPrinter:aPages[nPage] := ""
         FOR j := 1 TO Len( arr )
            IF j != i
               oPrinter:aPages[nPage] += arr[j] + crlf
            ELSE
               oPrinter:aPages[nPage] += Left( arr[j], nPos ) + cTemp + crlf
            ENDIF
         NEXT
         oPrinter:NeedsRedraw := .T.
         hwg_Redrawwindow( oPanel:handle, RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW + RDW_INVALIDATE )
      ENDIF
   ENDIF

   RETURN 1

* =================== EOF of hprinter.prg =================