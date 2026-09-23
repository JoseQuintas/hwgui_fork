/*
 * $Id: hwinprn.prg 3205 2023-01-26 12:33:44Z josequintas $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HWinPrn class
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * Modifications by DF7BE:
 * - New parameter "nCharset" for
 *   selecting international charachter sets
 *   Data and methods for National Language Support
 *
 * - New method SetDefaultMode():
 *   should act like a "printer reset"
 *   (Set back to default values).
 *
 * - Recovered METHOD PrintBitmap
 *   (Ticket #64, TNX HKrzak)
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It is a pure Harbour wrapper
 * around the HPrinter class (hprinter.prg), which has already been
 * ported.  Both #ifdef __GTK__ blocks remain valid: the macro reflects
 * the build target (Linux/GTK), not the GTK version.
 *
 * Harbour 3.2.x compatibility fix:
 *   The STATIC aCodes array in METHOD PutCode() used empty elements
 *   between commas (e.g. { a, , b }).  Harbour 3.2.x rejects this
 *   with E0020/E0030 "incomplete statement" errors.  Empty elements
 *   were replaced by explicit Nil values — semantically identical.
 */

#include "hwgui.ch"
#include "hbclass.ch"

#define   STD_HEIGHT      4

#define   MODE_NORMAL     0
#define   MODE_ELITE      1
#define   MODE_COND       2
#define   MODE_ELITECOND  3
#define   MODE_USER      10

CLASS HWinPrn

   CLASS VAR nStdHeight SHARED  INIT Nil
   CLASS VAR cPrinterName SHARED  INIT Nil
   DATA   oPrinter
   DATA   nFormType INIT 9
   DATA   oFont
   DATA   nLineHeight, nLined
   DATA   nCharW
   DATA   x, y
   DATA   old_y
   DATA   cPseudo   INIT "耐澈谏罩炕犯廊釉偌骄滤岩潦闲锰魄垂刀盼棕"
   DATA   lElite    INIT .F.
   DATA   lCond     INIT .F.
   DATA   nLineInch INIT 6
   DATA   lBold     INIT .F.
   DATA   lItalic   INIT .F.
   DATA   lUnder    INIT .F.
   DATA   nLineMax  INIT 0
   DATA   lChanged  INIT .F.

   DATA   cpFrom    INIT "EN"
   DATA   cpTo      INIT "EN"
   DATA   nTop      INIT 5
   DATA   nBottom   INIT 5
   DATA   nLeft     INIT 5
   DATA   nRight    INIT 5

   DATA   nCharset  INIT 0   &&  Charset (N) Default: 0  , 204 = Russian
                             &&  Ignored on GTK

   // --- International Language Support for internal dialogs --
   DATA aTooltips   INIT {}  // Array with tooltips messages for print preview dialog
   DATA aBootUser   INIT {}  // Array with control  messages for print preview dialog  (optional usage)


   METHOD New( cPrinter, cpFrom, cpTo, nFormType, nCharset )
   METHOD SetLanguage(apTooltips, apBootUser)
   METHOD InitValues( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset )
   METHOD SetMode( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset )
   METHOD SetDefaultMode()
   METHOD SetCPTo(cpTo)
   METHOD SetCP(ccp)
   METHOD SetCDPin(ccp)
   METHOD StartDoc( lPreview, cMetaName , lprbutton )
   METHOD NextPage()
   METHOD NewLine()
   METHOD PrintLine( cLine, lNewLine )
   METHOD PrintLine2( cLine )
   METHOD PrintBitmap( xBitmap, nAlign , cBitmapName  )  && cImageName
   METHOD PrintText( cText )
   METHOD SetX( nYvalue )
   METHOD SetY( nYvalue )
   METHOD PutCode( cLine )  && cText
   METHOD EndDoc()
   METHOD END()

#ifdef __GTK__
   METHOD SetMetaFile( cMetafile )    INLINE ::oPrinter:cScriptFile := cMetafile
#endif

   HIDDEN:
   DATA lDocStart   INIT .F.
   DATA lPageStart  INIT .F.
   DATA lFirstLine

ENDCLASS

METHOD New( cPrinter, cpFrom, cpTo, nFormType , nCharset ) CLASS HWinPrn

   ::SetLanguage() // Start with default english

   ::oPrinter := HPrinter():New( cPrinter, .F., nFormType )
   IF ::oPrinter == Nil
      RETURN Nil
   ENDIF
   ::cpFrom := cpFrom
   ::cpTo   := cpTo
#ifdef __GTK__
   IF !Empty( cpTo )
      ::oPrinter:cdpIn := cpTo
   ENDIF
#endif
   IF nFormType != Nil
      ::nFormType := nFormType
   ENDIF

   IF nCharset != Nil
      :: nCharset := nCharset
   ENDIF

   RETURN Self

METHOD SetCPTo(cpTo) CLASS HWinPrn

   IF cpTo != NIL
      ::cpTo   := cpTo
      ::oPrinter:cdpIn := cpTo
   ENDIF

   RETURN NIL

METHOD SetCP(ccp) CLASS HWinPrn

   IF ccp != NIL
      ::cpTo   := ccp
      ::oPrinter:cdp  := ccp
   ENDIF

   RETURN NIL

METHOD SetCDPin(ccp) CLASS HWinPrn

   IF ccp != NIL
      ::oPrinter:cdpIn  := ccp
   ENDIF

   RETURN NIL

METHOD SetLanguage(apTooltips, apBootUser) CLASS HWinPrn

   * NLS: Sets the message and control texts to print preview dialog
   * Are stored in arrays:   ::aTooltips[], ::aBootUser[]

   * Parameters not used
   HB_SYMBOL_UNUSED(apBootUser)

   * Default settings (English)
   ::aTooltips := hwg_HPrinter_LangArray_EN()
   * Overwrite default, if array with own language served
   IF apTooltips != NIL
      ::aTooltips := apTooltips
   ENDIF
/* Activate, if necessary */
//   IF apBootUser != NIL ; ::aBootUser := apBootUser ; ENDIF

   RETURN Nil

METHOD InitValues( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset ) CLASS HWinPrn

   IF lElite != Nil
      ::lElite := lElite
   ENDIF
   IF lCond != Nil
      ::lCond := lCond
   ENDIF
   IF nLineInch != Nil
      ::nLineInch := nLineInch
   ENDIF
   IF lBold != Nil
      ::lBold := lBold
   ENDIF
   IF lItalic != Nil
      ::lItalic := lItalic
   ENDIF
   IF lUnder != Nil
      ::lUnder := lUnder
   ENDIF
   IF nLineMax != Nil
      ::nLineMax := nLineMax
   ENDIF
   IF nCharset != Nil
      ::nCharset := nCharset
   ENDIF
   ::lChanged := .T.

   RETURN Nil

METHOD SetMode( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset) CLASS HWinPrn

#ifdef __GTK__
   LOCAL cFont := "monospace"
#else
   LOCAL cFont := "Lucida Console"
#endif
   LOCAL aKoef := { 1, 1.22, 1.71, 2 }
   LOCAL nMode := 0, oFont, nWidth, nPWidth, nStdHeight, nStdLineW

   ::InitValues( lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset )

   IF ::lPageStart

      IF ::nStdHeight == Nil .OR. ::cPrinterName != ::oPrinter:cPrinterName
         ::nStdHeight := STD_HEIGHT
         ::cPrinterName := ::oPrinter:cPrinterName
         nPWidth := ::oPrinter:nWidth / ::oPrinter:nHRes - 10

         IF ::nFormType == 9 .AND. ( nPWidth > 210 .OR. nPWidth < 190 )
            nPWidth := 200
         ELSEIF ::nFormType == 8 .AND. ( nPWidth > 300 .OR. nPWidth < 280 )
            nPWidth := 290
         ENDIF

         oFont := ::oPrinter:AddFont( cFont, ::nStdHeight * ::oPrinter:nVRes )

         nWidth := ::oPrinter:GetTextWidth( Replicate( 'A', Iif( ::nFormType==8, 113, 80 ) ), oFont ) / ::oPrinter:nHRes
         IF nWidth > nPWidth + 2 .OR. nWidth < nPWidth - 15
            ::nStdHeight := ::nStdHeight * ( nPWidth / nWidth )
         ENDIF
         oFont:Release()
      ENDIF

      nStdLineW  := Iif( ::nFormType==8, Iif(::oPrinter:nOrient==2,160,113), Iif(::oPrinter:nOrient==2,113,80) )
      nStdHeight := Iif( !Empty(::nLineMax), ::nStdHeight / ( ::nLineMax/nStdLineW ), ::nStdHeight )

      IF ::lElite ; nMode ++ ; ENDIF
      IF ::lCond ; nMode += 2 ; ENDIF
      //hwg_writelog( "nStdHeight: "+Ltrim(str(::nStdHeight))+"/"+Ltrim(str(nStdHeight))+" ::nLineMax: "+Ltrim(str(::nLineMax))+"  nStdLineW: "+Ltrim(str(nStdLineW)) )

      ::nLineHeight := ( nStdHeight / aKoef[ nMode + 1 ] ) * ::oPrinter:nVRes
      ::nLined := ( 25.4 * ::oPrinter:nVRes ) / ::nLineInch - ::nLineHeight

      oFont := ::oPrinter:AddFont( cFont, ::nLineHeight, ::lBold, ::lItalic, ::lUnder, ::nCharset ) && ::nCharset 204 = Russian

      IF ::oFont != Nil
         ::oFont:Release()
      ENDIF

      ::oFont := oFont

      ::oPrinter:SetFont( ::oFont )
      ::nCharW := ::oPrinter:GetTextWidth( "ABCDEFGHIJ", oFont ) / 10
      ::lChanged := .F.

   ENDIF

   RETURN Nil

/*
  Added by DF7BE:
  Should act like a "printer reset"
  (Set back to default values).
*/
METHOD SetDefaultMode() CLASS HWinPrn

   ::SetMode( .F., .F. , 6, .F. , .F. , .F. , 0 , 0 )

   RETURN Nil

METHOD SetY( nYvalue ) CLASS HWinPrn

   IF nYvalue == NIL
      nYvalue := 0
   ENDIF
   ::Y := nYvalue

   RETURN nYvalue

METHOD SetX( nYvalue ) CLASS HWinPrn

   IF nYvalue == NIL
      nYvalue := 0
   ENDIF
   ::X := nYvalue

   RETURN nYvalue

METHOD StartDoc( lPreview, cMetaName , lprbutton ) CLASS HWinPrn
   * Set lprbutton to .F., if preview dialog not shows the print button

   ::lDocStart := .T.
   ::oPrinter:StartDoc( lPreview, cMetaName , lprbutton )
   ::NextPage()

   RETURN Nil

METHOD NextPage() CLASS HWinPrn

   IF ! ::lDocStart
      RETURN Nil
   ENDIF
   IF ::lPageStart
      ::oPrinter:EndPage()
   ENDIF

   ::lPageStart := .T.
   ::oPrinter:StartPage()

   IF ::oFont == Nil
      ::SetMode()
   ELSE
      ::oPrinter:SetFont( ::oFont )
   ENDIF

#ifdef __GTK__
   ::y := ::nTop * ::oPrinter:nVRes - ::nLineHeight + ::nLined
#else
   ::y := ::nTop * ::oPrinter:nVRes - ::nLineHeight - ::nLined
#endif
   ::lFirstLine := .T.

   RETURN Nil

/*
   DF7BE:
   Recovered from r2536 2016-06-16
   added support for bitmap object

   xBitmap     : Name and path to bitmap file
                 or bitmap object variable
   nAlign      : 0 - left, 1 - center, 2 - right, default = 0
   cBitmapName  : Name of resource, if xBitmap is bitmap object
 */

METHOD PrintBitmap( xBitmap, nAlign , cBitmapName ) CLASS HWinPrn

   LOCAL i , cTmp , bfromobj
   LOCAL hBitmap, aBmpSize , cImageName

   * Variables not used
   * LOCAL oBitmap

   IF ! ::lDocStart
      ::StartDoc()
   ENDIF

   IF nAlign == NIL
     nAlign := 0  // 0 - left, 1 - center, 2 - right
   ENDIF

   bfromobj := .F.

   cTmp := hwg_CreateTempfileName( , ".bmp")

   // IF VALTYPE( xBitmap ) == "C" && does not work on GTK
     * from file
     IF ! hb_fileexists( xBitmap )
      * xBitmap is a bitmap object
      bfromobj := .T.
      cImageName := IIF(EMPTY (cBitmapName), "" , cBitmapName)
      * Store into a temporary file
      /* DF7BE:
        Bug in GTK: gdk_pixbuf_save(pixbuff,handle,"bmp",&error,cFile,contents_encode,NULL)
        set the value of printer resolution (pixels per meter) to zero.
        For example: astro.bmp
        Offsets / values
        26 / c4 0e
        2a / c4 0e = 3780 dec.
        New function OBMP2FILE2( cTmp , cImageName ) saves the bmp object
        correct to file.
      */
      xBitmap:OBMP2FILE( cTmp , cImageName , "bmp" )
      hBitmap := hwg_Openbitmap( cTmp , ::oPrinter:hDC )
      // hwg_msginfo(hb_valtostr(hBitmap))
      IF hb_ValToStr(hBitmap) == "0x00000000"
        RETURN NIL
      ENDIF
      aBmpSize  := hwg_Getbitmapsize( hBitmap )
      cImageName := IIF(EMPTY (cBitmapName), xBitmap, cBitmapName)
      // FERASE(cTmp)
     ELSE
      * from file
      hBitmap := hwg_Openbitmap( xBitmap, ::oPrinter:hDC )
      // hwg_msginfo(hb_valtostr(hBitmap))
      IF hb_ValToStr(hBitmap) == "0x00000000"
        RETURN NIL
      ENDIF
      cImageName := IIF(EMPTY (cBitmapName), xBitmap, cBitmapName)
      //  aBmpSize[1] = width(x) aBmpSize[2] = height(y)
      aBmpSize  := hwg_Getbitmapsize( hBitmap )
   ENDIF

/* Page size overflow  ? ==> next page */
#ifdef __GTK__
   IF ::y + aBmpSize[2] + ::nLined > ::oPrinter:nHeight
#else
   IF ::y + aBmpSize[2] + ::nLined > ::oPrinter:nHeight
#endif
      ::NextPage()
   ENDIF

   ::x := ::nLeft * ::oPrinter:nHRes
   ::y += ::nLineHeight + ::nLined

   IF nAlign == 1 .AND. ::x + aBmpSize[1] < ::oPrinter:nWidth
     ::x += ROUND( (::oPrinter:nWidth - ::x - aBmpSize[1] ) / 2, 0)
  * HKrzak 2020-10-27
   ELSEIF nAlign == 2
     ::x += ROUND( (::oPrinter:nWidth - ::x - aBmpSize[1]), 0)
   ENDIF
   IF ::lFirstLine
      ::lFirstLine := .F.
   ENDIF
   * Paint bitmap
   // hwg_msginfo(STR(::x) + CHR(10) + STR(::y) + CHR(10) + STR(aBmpSize[1]) + CHR(10) +  STR(aBmpSize[2]) )

   IF bfromobj
   /* from object: need to read from temporary file */
    ::oPrinter:Bitmap( ::x, ::y, ::x + aBmpSize[1], ::y + aBmpSize[2],, hBitmap, cTmp )
    FERASE(cTmp)
   ELSE
    ::oPrinter:Bitmap( ::x, ::y, ::x + aBmpSize[1], ::y + aBmpSize[2],, hBitmap, cImageName )
   ENDIF
   /* Height of bitmap, increase Y value */
   i := aBmpSize[2]   &&   - ::nLineHeight  ==> DF7BE: not the correct size of bitmap !
   IF i > 0
       ::Y +=  i
   ENDIF

   // hwg_WriteLog(STR(::x) + CHR(10) + STR(::y) + CHR(10) ;
   // + STR(aBmpSize[1]) + CHR(10) +  STR(aBmpSize[2]) + CHR(10) +  STR(i) )

  RETURN Nil

METHOD NewLine()  CLASS HWinPrn

    ::old_y := ::y
//    ::PrintLine( "" , .T. )
    ::PrintLine(  , .T. )
    ::SetX()
    * Handle bug in METHOD PrintLine()
    IF ::y ==  ::old_y
    ::y += ::nLineHeight
    ENDIF
     IF ::y < 0
       ::y := 0
     ENDIF

     // hwg_WriteLog("::y=" + STR(::y) + " ::nLineHeight=" + STR(::nLineHeight)  )
   RETURN Nil

METHOD PrintLine2( cLine ) CLASS HWinPrn
   * Special for Umlaute and other characters

  IF ! ::lDocStart
      ::StartDoc()
  ENDIF
  ::NewLine()

  ::PrintText("  " + cLine)  && Try to get same behavior as PrintLine(), left margin not 0

  //  ::PrintLine( IIf( ::cpFrom != ::cpTo, hb_Translate( cLine, ::cpFrom, ::cpTo ), cLine ), lNewLine )

   RETURN NIL

METHOD PrintLine( cLine, lNewLine ) CLASS HWinPrn

   LOCAL i, i0, j, slen, c

   IF ! ::lDocStart
      ::StartDoc()
   ENDIF

   IF lNewLine == Nil
     lNewLine := .T.
   ENDIF

   * HKrzak.Start 2020-10-25
   * Bug Ticket #64
   IF cLine != Nil .AND. VALTYPE(cLine) == "N"
      ::y += ::nLineHeight * cLine
      IF ::y < 0
         ::y := 0
      ENDIF
   ENDIF
* HKrzak.End

#ifdef __GTK__
   IF ::y + 3 * ( ::nLineHeight + ::nLined ) > ::oPrinter:nHeight
#else
   IF ::y + 2 * ( ::nLineHeight + ::nLined ) > ::oPrinter:nHeight
#endif
      ::NextPage()
   ENDIF

* HKrzak.Start 2020-10-25
* Bug Ticket #64
   IF cLine != Nil .AND. VALTYPE(cLine) == "N"
     RETURN NIL
   ENDIF
* HKrzak.End

   ::x := ::nLeft * ::oPrinter:nHRes
   IF ::lFirstLine
      ::lFirstLine := .F.
   ELSEIF lNewLine
      ::y += ::nLineHeight + ::nLined
   ENDIF

   IF cLine != Nil .AND. ! Empty( cLine )
      slen := Len( cLine )
      i := 1
      i0 := 0
      DO WHILE i <= slen
         IF ( c := SubStr( cLine, i, 1 ) ) < " "
            IF i0 != 0
               ::PrintText( SubStr( cLine, i0, i - i0 ) )
               i0 := 0
            ENDIF
            i += ::PutCode( SubStr( cLine, i ) )
            LOOP
         ELSEIF ( j := At( c, ::cPseudo ) ) != 0
            IF i0 != 0
               ::PrintText( SubStr( cLine, i0, i - i0 ) )
               i0 := 0
            ENDIF
            IF j < 3            // Horisontal line 耐
               i0 := i
               DO WHILE i <= slen .AND. SubStr( cLine, i, 1 ) == c
                  i ++
               ENDDO
               ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ( i - i0 ) * ::nCharW, ::y + ( ::nLineHeight / 2 ) )
               ::x += ( i - i0 ) * ::nCharW
               i0 := 0
               LOOP
            ELSE
               IF j < 5         // Vertical Line 澈
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 9     // 谏罩
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 13    // 炕犯
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 17    // 廊釉
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
               ELSEIF j < 21    // 偌骄
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
               ELSEIF j < 25    // 滤岩
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 29    // 潦闲
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
               ELSEIF j < 33    // 锰魄
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSEIF j < 37    // 垂刀
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ( ::nCharW / 2 ), ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ELSE    // 盼棕
                  ::oPrinter:Line( ::x, ::y + ( ::nLineHeight / 2 ), ::x + ::nCharW, ::y + ( ::nLineHeight / 2 ) )
                  ::oPrinter:Line( ::x + ( ::nCharW / 2 ), ::y, ::x + ( ::nCharW / 2 ), ::y + ::nLineHeight + ::nLined )
               ENDIF
               ::x += ::nCharW
            ENDIF
         ELSE
            IF i0 == 0
               i0 := i
            ENDIF
         ENDIF
         i ++
      ENDDO
      IF i0 != 0
       // hwg_writelog(STR(::x) + CHR(10) + STR(::y) + CHR(10) + STR(i0) + CHR(10) + STR(i) + ;
       //  CHR(10) + STR(::nLineHeight) )
         ::PrintText( SubStr( cLine, i0, i - i0 ) )
       ENDIF
   ENDIF

   RETURN Nil

METHOD PrintText( cText ) CLASS HWinPrn

   LOCAL x , y

   IF ::lChanged
      ::SetMode()
   ENDIF

// hwg_writelog( IIf( ::cpFrom != ::cpTo, hb_Translate( cText, ::cpFrom, ::cpTo ), cText ) )

   x := ::x
   y := ::y

   IF hwg_ValType(x) != "N"
    x := 0
    ::x := 0
   ENDIF

   IF hwg_ValType(y) != "N"
    y := 0
   ENDIF

   ::oPrinter:Say( IIf( ::cpFrom != ::cpTo, hb_Translate( cText, ::cpFrom, ::cpTo ), cText ), ;
         x, y, ::oPrinter:nWidth, y + ::nLineHeight + ::nLined )

   ::x += ( ::nCharW * Len( cText ) )

   RETURN Nil

METHOD PutCode( cLine ) CLASS HWinPrn

   STATIC aCodes := {   ;
          { Chr( 27 ) + '@',   .f.,  .f.,  6,   .f.,  .f.,  .f. },  ;
          { Chr( 27 ) + 'M',   .t.,  Nil, Nil,  Nil,  Nil,  Nil },  ;
          { Chr( 15 ),         Nil,  .t., Nil,  Nil,  Nil,  Nil },  ;
          { Chr( 18 ),         Nil,  .f., Nil,  Nil,  Nil,  Nil },  ;
          { Chr( 27 ) + '0',   Nil,  Nil,  8,   Nil,  Nil,  Nil },  ;
          { Chr( 27 ) + '2',   Nil,  Nil,  6,   Nil,  Nil,  Nil },  ;
          { Chr( 27 ) + '-1',  Nil,  Nil, Nil,  Nil,  Nil,  .t. },  ;
          { Chr( 27 ) + '-0',  Nil,  Nil, Nil,  Nil,  Nil,  .f. },  ;
          { Chr( 27 ) + '4',   Nil,  Nil, Nil,  Nil,  .t.,  Nil },  ;
          { Chr( 27 ) + '5',   Nil,  Nil, Nil,  Nil,  .f.,  Nil },  ;
          { Chr( 27 ) + 'G',   Nil,  Nil, Nil,  .t.,  Nil,  Nil },  ;
          { Chr( 27 ) + 'H',   Nil,  Nil, Nil,  .f.,  Nil,  Nil }   ;
        }
   LOCAL i, sLen := Len( aCodes ), c := Left( cLine, 1 )

   IF !Empty( c ) .AND. c < " "
      IF Asc( c ) == 31
         ::InitValues( Nil, Nil, Nil, Nil, Nil, Nil, Asc(Substr(cLine,2,1)) )
         RETURN 2
      ELSE
         FOR i := 1 TO sLen
            IF Left( aCodes[ i, 1 ], 1 ) == c .AND. At( aCodes[ i, 1 ], Left( cLine, 3 ) ) == 1
               ::InitValues( aCodes[ i, 2 ], aCodes[ i, 3 ], aCodes[ i, 4 ], aCodes[ i, 5 ], aCodes[ i, 6 ], aCodes[ i, 7 ]  )
               RETURN Len( aCodes[ i, 1 ] )
            ENDIF
         NEXT
      ENDIF
   ENDIF

   RETURN 1

METHOD EndDoc() CLASS HWinPrn

   IF ::lPageStart
      ::oPrinter:EndPage()
      ::lPageStart := .F.
   ENDIF
   IF ::lDocStart
      ::oPrinter:EndDoc()
      ::lDocStart := .F.
      IF __ObjHasMsg( ::oPrinter, "PREVIEW" ) .AND. ::oPrinter:lPreview
         ::oPrinter:Preview( , , ::aTooltips,)
      ENDIF
   ENDIF

   RETURN Nil

METHOD END() CLASS HWinPrn

   ::EndDoc()
   ::oFont:Release()
   ::oPrinter:END()

   RETURN Nil
