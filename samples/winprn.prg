#pragma -w1

/*
 * HWinPrn using sample
 *
 * $Id$
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Modified by DF7BE: New parameter "nCharset" for
 * selecting international character sets
 * NLS and Main menu for more experiments
 *
 * More modifications mentioned in the above lines.
 *
 * Special instructions for QR code support also above.
*/

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No   (Compilable, but no print preview visible, don't matter, because not recommended)
    *
    * ----------------------------------------------
    * List of languages supported ( with name of author with call sign or e-mail address )
    * ----------------------------------------------
    * - English   (default, original by Alexander Kresin)
    * - German    Wilfried Brunken, DF7BE
    * - Serbian   srdjankv (addition for QRCode printing with XHARBOUR)
    *             Need compiler switch #ifdef __XHARBOUR__
    *
    *
* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
* We invite all other HWGUI developers to add more languages.
* Try to add lines for Unicode support.
* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*
* Steps for adding a new language:
* 1. Create new function "FUNCTION hwg_HPrinter_LangArray_xx()", where "xx" ist
*    the short abbreviation of the language.
*    Use "FUNCTION hwg_HPrinter_LangArray_DE()" as a template.
*    The original english texts are commented with "&&" for better orientation
*    Optional for codepage mapping from UTF-8 to Windows create a function
*    FUNCTION XWIN_xx(clang)
*    where "xx" is the shorte abbreviation, see above, for example "SR" for serbian
*    Set in the function call for of or HB_TRANSLATE() to the required codepages.
* 2. Add requests for new languages in REQUEST section;
* 3. Add entry in PUBLIC array for new language.
*    Function Main :
*    aLanguage : Add new element in array with name of language, avoid special signs (only ANSI)
* 4. FUNCTION NLS_SetLang() : Add new block in case command.
* 5. FUNCTION PRINT_OUT():  Add new block in case command with initialization of Winprn class.
* 6. FUNCTION acdiamode():  Add text block for dialog mode



/* Modifications by DF7BE:
  - Main menu added:
  - NLS , language setting of program could be changed
    so that print preview dialog appears in selected language.
  - Selected language asked first at program start.
  - NLS , set printer character set in comboxbox.
    Try to find your correct language setting for your printer model.
    (Main menu appeared in selected language only after restart, so store language setting in ini file)
  - Added PrintBitmap

    Special hints for test and development without printer usage:
    Windows 10: You can install a virtual printer driver named "Print to PDF" to redirect the printer data.
    LINUX: The Printer dialog of the system allows redirection into a PDF file.

    June 2022:

    nmode:
     0 : Print immediately (show no print preview). Default, old behavior.
     1 : Show print preview and start printing with button press
     2 : Show print preview and hide print button

    Test for METHOD NewLine()
    Charsets for LINUX: METHOD New()
    The option nPrCharset is Windows only and ignored on GTK/LINUX
    The Option cdp is for LINUX/GTK and ignored on Windows

    December 2022:

    Added full support for QR code encoding:
     - Static link of QR encoding library (LINUX, Windows)
     - Usage of DLL for QR encoding (Windows only)

*/

/*
  Instruction activation QR code encoding.

  For details to build the QR encode library see file
  contrib\qrencode\Readme.txt

  The last page can be filled with a QR code image.
  Follow the instructions:

  1.) Modify the string to convert to QR code in variable
      cQR in Function Main().
      Encoding must be UTF-8, use function HB_TRANSLATE()
      to convert at your opinion.

  2.) Library setting:
      DLL: copy the DLL "qrcodegen.dll" into the
      directory running the program (here: samples).
      Compile the DLL with MinGW32 yourself following instructions
      in contrib\qrencode\Readme.txt
      or download a "ready to use" dll from the "Files"
      section of the HWGUI project site at sourgeforge.net.

      Static link:
      Be shure, that the following libraries are available in directory "lib":
       libhbqrencode.a
       libqrcodegen.a

   3.)Edit "winprn.hbp" to select the mode:
      # QR encode linking
      # -dWITH_QRENCDLL   ==> activate for DLL usage (Windows only)
      # -dWITH_QRENCST    ==> activate for static link (Windows and LINUX)

      # Free this entries for static link of QR encoding library
       -lqrcodegen
       -lhbqrencode
        ==> must be done, if activated "-dWITH_QRENCST"
   4.) Compile this sample:
       hbmk2 winprn.hbp

   5.) Run this sample:
       winprn.exe (or LINUX: ./winprn)

       The QR code appeared in the last page.
       Use the "(+)" Button to zoom and check the QR code
       for example with your smartphone.

   The properitary DLL as alternative can be download from:
   https://github.com/VFPX/FoxBarcodeQR

*/

/*
 Special hint for editing:
 Some troubles with Windows characters: we suggest to use the CHR() function
 to assign windows characters unique.
 */


#include "hwgui.ch"
#include "sampleinc.ch"

#ifdef __XHARBOUR__
  #include "ttable.ch"
  #include "hbzebra.ch"
#endif
#define _SCALE_ 7.2


* ***********************
* * REQUESTS            *
* ***********************

* === Russian ===
REQUEST HB_CODEPAGE_RU866
#ifdef __LINUX__
REQUEST HB_CODEPAGE_RUKOI8
#else
REQUEST HB_CODEPAGE_RU1251
#endif

* === German ===
* Data Codepage (in DBFs)
REQUEST HB_CODEPAGE_DE858
* Windows codepage
REQUEST HB_CODEPAGE_DEWIN

* === Serbian ===
REQUEST HB_CODEPAGE_SRWIN

* === EN/USA ===
* Nothing to do


* ****************************
* For all languages: Unicode *
* ****************************
#ifndef __PLATFORM__WINDOWS
* LINUX Codepage
REQUEST HB_CODEPAGE_UTF8
// REQUEST HB_CODEPAGE_UTF8EX
#endif

MEMVAR aMainMenu , aLanguages , aPriCharSets , att_priprev, clangset, cIniFile, cTitle
MEMVAR nPrCharset, nchrs , cQR
MEMVAR cHexAstro , cValAstro , oBitmap1 , oBitmap2
MEMVAR nmode , lPreview , lprbutton, aMessages

* ---------------------------------------------
Function Main
* ---------------------------------------------
 LOCAL oMainWindow
 LOCAL cDirSep := hwg_GetDirSep()

 PUBLIC nmode , lPreview , lprbutton
 PUBLIC aMainMenu , aLanguages , aPriCharSets , att_priprev, clangset, cIniFile, cTitle
 PUBLIC nPrCharset, nchrs
 PUBLIC cHexAstro , cValAstro , oBitmap1 , oBitmap2

 PRIVATE cQR
 // cQR:= "https://suf.purs.gov.rs/v/?vl=A0FVRVM0RllGQVVFUzRGWUYDAAAAAgAAAJCfiEIAAAAAAAABgjsBiWkAAAA8cNJI%2FbGxx11DlHJlGtKZGtRuq4NHcwg%2BKztPLN1bogOyAyHaj4xt5XCaRxE9jtqE0Rg12mLYgasUenuR1hBowZyUgTA%2F3jIbDAZkROSOqlnVpaJ4bDV4JH66ddL0YKiAwyOmW65IeXUcVamb3ZiGDw5RcGggRfi9iO%2B1uZRrBCnQImPFWYRD9DOkcNr%2Frmkr78J4cNsK1B8rfIGHGb028lJjd9SJJCoRAxm4mo9sUKEZuyKXZm%2BnM12kXS1r5jicRiM%2B1niB44jg8BU%2F8fjSp1sxgEErV5DHEGzgsrgS1iQPWidElHV7wmaydSFfqyEUuweCuNy5NTg%2FrcJvpHNWDfpl58E27SvTZ2k5BdrDSsveSh3ioh1UW2uAKYhemoA5pWCWsu4XYL0bV0DYMY0ePUlSnXqiQr5bmUyUl7lTDvY3KLziTjSLzNRyY8Oxn%2B1%2F8lV5GwUIslxjLzh9Wq7lM%2FAfZLpx4GcP%2F19pQC7shi4k%2F2zOcAT8MQVMUzljMkOFYK73pxunbitupzKocTy4z2FonLuSCeQOJeCQF9hVmtQAZ2K1m%2FiUqbD5NnAdEfPZrmdsblD8EW%2FRsUL5n7FTmwpUIFtdP%2B1mEy4mWEU8Jrb3XTiB%2F8fSJUUt%2Bg%2Bz4S0ncApxLI0ZgjGk3LwtLFz5h0ymFMumxhfPc1FgLhPBl0fvq%2BQSUCxo6UCMCh2cOsU%3D"
 cQR := "https:www.darc.de/distrikte"
   /* Names of supported languages, use only ANSI charset, displayed in language selection dialog */
   aLanguages := { "English", "Deutsch", "Serbian" }
   //   cIniFile := "language.ini"

   /* Preset defaults (English)*/
   lPreview := .T.
   lprbutton := .T.
   nmode := 0
   nPrCharset := 0
   nchrs := 1 /* Item in COMBOXBOX */
   clangset := "English"
   aMainMenu := { "&Exit", "&Quit" , "&Print" , "&Start printing" , "&Settings" , ;
       "&Printer Char Set" , "&Language" }
   cTitle := "Demo for Winprn Class"
   NLS_SetLang(clangset)
   aMessages := Wprn_HPrinter_LangArray_EN()

* Ask user for startup language setting combobox
* and set to new language, if modified
 Select_LangDia(aLanguages)

#ifndef __PLATFORM__WINDOWS
* This setting causes error no printing of German Umlaute and Euro currency sign
IF ( clangset != "Deutsch") .AND. ( clangset != "English")
 hb_SetCodepage( "UTF8" )
END
// hb_SetCodepage( "UTF8EX" )
#endif

* ==== Handle Resources ====

* Fill variables with hex values
 Init_Hexvars()

 CHECK_FILE( SAMPLE_IMAGEPATH + "hwgui.bmp")  && 301 x 160 pixel

 * Convert them all to binary.
 cValAstro := hwg_cHex2Bin ( cHexAstro )

 * Load contents from hex resources into image objects.
 * astro.bmp
 oBitmap1 := HBitmap():AddString( "astro", cValAstro )  && original size (Width x Height): 107 x 90 Pixel

 // not working yet:
 // oBitmap2 := HBitmap():AddString( "astro", cValAstro , 428 , 360) && resized x 4

 // Test
 // oBitmap1:OBMP2FILE( "test.bmp" , "astro" )

* Main Menu

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE cTitle ;
      AT 0,0 ;
      SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   // MENUITEM in main menu on GTK/Linux does not start the desired action
   // Submenu needed
   MENU OF oMainWindow
      MENU TITLE aMainMenu[1]  /* Exit */
        MENUITEM aMainMenu[2] ACTION oMainWindow:Close() /* Quit */
      ENDMENU
      MENU TITLE aMainMenu[3] /* Print */
         MENUITEM aMainMenu[4] ACTION { || PRINT_OUT(clangset,lpreview,lprbutton) }
      ENDMENU
      MENU TITLE aMainMenu[5] /* Settings */
         MENUITEM aMainMenu[6] ACTION Select_LangChrs()  /* Charset */
         MENUITEM aMainMenu[7] ACTION Select_LangDia(aLanguages)  /* Language */
         MENUITEM aMainMenu[8] ACTION Select_Mode() /* Select dialog mode */
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

RETURN NIL


#include "hexres.ch"

* ---------------------------------------------
FUNCTION Set_Maintitle(omnwnd,ctit)
* Modify title of main window
* ---------------------------------------------
  omnwnd:SetTitle(ctit)
RETURN NIL


/*
STATIC FUNCTION myFillRect( nX1, nY1, nX2, nY2, nColor )

   LOCAL lResult := .F.

//   IF ::CheckPage()
      lResult := win_FillRect( qself():oPrinter:hDC, nX1, nY1, nX2, nY2, nColor )
//      IF lResult
//         ::HavePrinted := .T.
//      ENDIF
//   ENDIF

RETURN lResult
*/

* ---------------------------------------------
FUNCTION PRINT_OUT(cname,lpreview,lprbutton)
* Print test
* lpreview : Set to .T. for print preview
*            Default is .F.
* lprbutton:
* Set to .F., if preview dialog not shows the print button
* Default is .T.
* ---------------------------------------------

Local oWinPrn, i , j
LOCAL ctest1,ctest2,ctest3,cEuroUTF8,cEuroDOS
* Block grafic chars (CP850), single line
LOCAL cCross, cvert, chori, ctl, ctr, ctd, clr , crl, cbl, cbr, cbo
LOCAL nRet, nScale := 7.2
#ifdef __XHARBOUR__
 Local hZebra := hb_zebra_create_qrcode( cQR, HB_ZEBRA_FLAG_QR_LEVEL_M )
#endif
LOCAL nLineWidth := 1*nScale, nLineHeight := nLineWidth
LOCAL nY := 130*nScale, nX:= 300*nScale
LOCAL cFile

  cCross := CHR(197)
  cvert  := CHR(196)  && Vertical line
  chori  := CHR(179)  && Horizontal line
  ctl    := CHR(218)  && Edge top left
  ctr    := CHR(191)  && Edge top right
  ctd    := CHR(194)  && T top down
  clr    := CHR(195)  && T left right
  crl    := CHR(180)  && T right left
  cbo    := CHR(193)  && T bottom up
  cbl    := CHR(192)  && Edge bottom left
  cbr    := CHR(217)  && Edge bottom right

  IF lpreview == NIL
    lpreview := .F.
  ENDIF

  IF lprbutton == NIL
     lprbutton := .T.
  ENDIF

  IF cname == NIL ; cname := "English" ; ENDIF
  IF EMPTY(cname) ; cname := "English" ; ENDIF

/* ===========================================
   + Initialize sequences for printer class  +
   ===========================================
*/

* Method  StartDoc(): If the first parameter is set to .T., the print preview dialog appeared,
* otherwise the print action starts immediately (.F. or left empty).
* Set the 3rd parameter to .F., if you want to hide the "Print" button, the default is .T.
*

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* Add new block for every new supported language
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  DO CASE

   * =============== German =================
   CASE cname == "Deutsch"  && Germany @ Euro

#ifndef __PLATFORM__WINDOWS
* GTK/LINUX
  oWinPrn := HWinPrn():New( ,,, , nPrCharset)  && OK for Umlaute and Euro currency sign
//   oWinPrn := HWinPrn():New( ,"UTF8" , "DEWIN" , , nPrCharset )
//   oWinPrn := HWinPrn():New( ,"DE858","UTF8", , nPrCharset )
//   oWinPrn := HWinPrn():New( ,,"UTF8", , nPrCharset )
   oWinPrn:aTooltips := hwg_HPrinter_LangArray_DE()
//   oWinPrn:StartDoc( .T.,"temp_a2.ps" )
   oWinPrn:StartDoc( lpreview ,"temp_a2.ps", lprbutton )
#else
* Windows
    oWinPrn := HWinPrn():New( ,,, , 1)
//   oWinPrn := HWinPrn():New( ,"DE858","DEWIN", , nPrCharset)
   /* This displays the Euro currency sign CHR(128) correct, but not
      all of the Umlaute ! */
//   oWinPrn := HWinPrn():New( ,,, , nPrCharset )
   oWinPrn:aTooltips := hwg_HPrinter_LangArray_DE()
*   oWinPrn:StartDoc( .T. )
//   oWinPrn:StartDoc( .T.,"temp_a2.pdf" )
   oWinPrn:StartDoc( lpreview ,"temp_a2.pdf" , lprbutton)
#endif


   *  =============== Serbian ==================
*  Hello srdjankv, i think this is your job.
  CASE cname == "Serbian"
#ifndef __PLATFORM__WINDOWS
   oWinPrn := HWinPrn():New( ,"RU866","RUKOI8" , , nPrCharset )
      oWinPrn:aTooltips := hwg_HPrinter_LangArray_SR()
 *  oWinPrn:StartDoc( .T.,"temp_a2.ps" )
   oWinPrn:StartDoc( lpreview,"temp_a2.ps" , lprbutton )
#else
* Windows
   oWinPrn := HWinPrn():New( ,,, , nPrCharset)
//   oWinPrn := HWinPrn():New( ,"RU866","RU1251", , nPrCharset )
   oWinPrn:aTooltips := hwg_HPrinter_LangArray_SR()
//   Hwg_MsgInfo("nCharset=" + STR(oWinPrn:nCharset),"Serbian" )
*   oWinPrn:StartDoc( .T. )
*   oWinPrn:StartDoc( .T.,"temp_a2.pdf" )
   oWinPrn:StartDoc( lpreview,"temp_a2.pdf" , lprbutton)
#endif


/*

  CASE cname == "Russian"
   *  =============== Russian ==================
*  Hello Alexander, i think this is your job.
  CASE cname == "Russian"
#ifndef __PLATFORM__WINDOWS
   oWinPrn := HWinPrn():New( ,"RU866","RUKOI8" , , nPrCharset ) && 204
      oWinPrn:aTooltips := hwg_HPrinter_LangArray_RU()
 *  oWinPrn:StartDoc( .T.,"temp_a2.ps" )
   oWinPrn:StartDoc( lpreview,"temp_a2.ps" , lprbutton )
#else
* Windows
   oWinPrn := HWinPrn():New( ,"RU866","RU1251", , nPrCharset ) && 204
   oWinPrn:aTooltips := hwg_HPrinter_LangArray_RU()
//   Hwg_MsgInfo("nCharset=" + STR(oWinPrn:nCharset),"Russian" )
*   oWinPrn:StartDoc( .T. )
*   oWinPrn:StartDoc( .T.,"temp_a2.pdf" )
   oWinPrn:StartDoc( lpreview,"temp_a2.pdf" , lprbutton)
#endif
*/

 OTHERWISE
/* ============== Default EN/USA ==================*/
#ifndef __PLATFORM__WINDOWS
   oWinPrn := HWinPrn():New( ,,, , nPrCharset)
//   oWinPrn:StartDoc( .T.,"temp_a2.ps" )
   oWinPrn:StartDoc( lpreview ,"temp_a2.ps" , lprbutton)
#else
   oWinPrn := HWinPrn():New( ,,, , nPrCharset)
*   oWinPrn:StartDoc( .T. )
//   oWinPrn:StartDoc( .T.,"temp_a2.pdf" )
    oWinPrn:StartDoc( lpreview ,"temp_a2.pdf" , lprbutton )
#endif

 ENDCASE

// #ifndef __PLATFORM__WINDOWS
// __objAddMethod(oWinPrn, "FillRect", @myFillRect())


// Hwg_SetDocumentProperties( oWinPrn:oPrinter:hDCPrn, oWinPrn:oPrinter:cPrinterName, ;
// oWinPrn:oPrinter:FormType, oWinPrn:oPrinter:nOrient == 2, oWinPrn:oPrinter:Copies, ;
// oWinPrn:oPrinter:BinNumber, 0, /*DMRES_HIGH*/ 65532, oWinPrn:oPrinter:PaperLength, ;
// oWinPrn:oPrinter:PaperWidth )
//#endif


/* ====================================
   + End of Printer initialization    +
   ====================================
*/

*  DOS Test German Umlaute and sharp "S" + mue + Euro
   ctest1 := CHR(142) + CHR(153) + CHR(154) + CHR(132) + CHR(148) + CHR(129) + CHR(225) + CHR(230) + CHR(213)
*  Windows
   ctest2 := CHR(196) + CHR(214) + CHR(220) + CHR(228) + CHR(246) + CHR(252) + CHR(223) + CHR(181) + CHR(128)


* Euro = 0xE2 0x82 0xAC = CHR(226) + CHR(130) + CHR(172)
   cEuroUTF8 := CHR(226) + CHR(130) + CHR(172)       && "€"

   cEuroDOS := CHR(128)

 *  UTF-8
   ctest3 := "ÄÖÜäöüßµ" + cEuroUTF8     && €

  * Page 1 :  print all chars over ASCII with decimal values (128 ... 190)
  FOR j := 128 TO 190
   oWinPrn:PrintLine(ALLTRIM(STR(j)) + ": " + CHR(j) )
  NEXT
  * Page 2: 191 ... 255
  oWinPrn:NextPage()
  FOR j := 191 TO 255
   oWinPrn:PrintLine(ALLTRIM(STR(j)) + ": " + CHR(j) )
  NEXT
  * Page 3: Several character sizes and block grafics
   oWinPrn:NextPage()

   oWinPrn:PrintLine( oWinPrn:oFont:name + " " + Str(oWinPrn:oFont:height) + " " + Str(oWinPrn:nCharW) + " " + Str(oWinPrn:nLineHeight) )
   oWinPrn:PrintLine( "A123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
/*
   oWinPrn:PrintLine( " ¡¢£¤¥¦§¨©ª«¬­®¯àáâãäåæçèéêëìíîï" )
   oWinPrn:PrintLine( "€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ" )
*/

*  DOS  (dez / oct / hex) >> CP850, DE850
*  AE  = 142 / 216 / 8E
*  OE  = 153 / 231 / 99
*  UE  = 154 / 232 / 9A
*  ae  = 132 / 204 / 84
*  oe  = 148 / 224 / 94
*  ue  = 129 / 201 / 81
*  sz  = 225 / 341 / E1
*
*  Windows (ungefaehr ISO8859-1) "WIN1252"
*  WIN     (dez / oct / hex)
*
*  AE  = 196 / 304 / C4
*  OE  = 214 / 326 / D6
*  UE  = 220 / 334 / DC
*  ae  = 228 / 344 / E4
*  oe  = 246 / 366 / F6
*  ue  = 252 / 374 / FC
*  sz  = 223 / 337 / DF
*

* German Umlaute
#ifdef __PLATFORM__WINDOWS
   oWinPrn:PrintLine(" Recent charset is " + ALLTRIM(STR(oWinPrn:nCharset)) )
   oWinPrn:PrintLine(ctest1)
#else
   oWinPrn:PrintLine(ctest1)    && ctest3 (UTF-8) not working here
#endif

   oWinPrn:PrintLine( "abcdefghijklmnopqrstuvwxyz" )
   oWinPrn:PrintLine( "ABCDEFGHIJKLMNOPQRSTUVWXYZ" )

   oWinPrn:PrintLine( ctl + REPLICATE(cvert,9) + ctd + REPLICATE(cvert, 15) + ctr )
   oWinPrn:PrintLine( chori + "   129.54" + chori + "           0.00" + chori )
   oWinPrn:PrintLine( clr + REPLICATE(cvert,9) + cCross + REPLICATE(cvert, 15) + crl )
   oWinPrn:PrintLine( chori + "    17.88" + chori + "      961014.21" + chori )
   oWinPrn:PrintLine( cbl + REPLICATE(cvert,9) + cbo + REPLICATE(cvert, 15) + cbr )
   oWinPrn:PrintLine()
   oWinPrn:PrintLine( ctl + REPLICATE(cvert,9) + ctd + REPLICATE(cvert, 15) + ctr )
   oWinPrn:PrintLine( cbl + REPLICATE(cvert,9) + cbo + REPLICATE(cvert, 15) + cbr )
//   oWinPrn:PrintLine( "ÚÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿" )
//   oWinPrn:PrintLine( "ÀÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ" )

   oWinPrn:PrintLine()
   oWinPrn:PrintLine()

   oWinPrn:SetMode( .T. )
   oWinPrn:PrintLine( "A12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
   oWinPrn:PrintLine( "A123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
   oWinPrn:PrintLine()
   oWinPrn:PrintLine()

   oWinPrn:SetMode( .F.,.T. )
   oWinPrn:PrintLine( "A12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
   oWinPrn:PrintLine( "A123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
   oWinPrn:PrintLine()
   oWinPrn:PrintLine()

   oWinPrn:SetMode( .T.,.T. )
   oWinPrn:PrintLine( "A12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )
   oWinPrn:PrintLine( "A123456789012345678901234567890123456789012345678901234567890123456789012345678Z" )

   oWinPrn:SetMode( .F.,.F. )
   * Page 4: 80 Lines (overflow to page 5 after 69 lines)
   oWinPrn:NextPage()
   oWinPrn:PrintLine( oWinPrn:oFont:name + " " + Str(oWinPrn:oFont:height) + " " + Str(oWinPrn:nCharW) + " " + Str(oWinPrn:nLineHeight) )
   FOR i := 1 TO 80
      oWinPrn:PrintLine( Padl( i,3 ) + " --------" )
   NEXT

   * Page 6:
   * Test 10 lines forward
   oWinPrn:NextPage()
   oWinPrn:PrintLine(10)

   IF cname == "Serbian"
     IF hwg__isUnicode()
      oWinPrn:PrintLine("Линија 11")
     ELSE
      oWinPrn:PrintLine(XWIN_SR("Линија 11"))
     ENDIF
   ELSE
     oWinPrn:PrintLine("Line 11")
   ENDIF
   oWinPrn:PrintLine()

   IF cname == "Serbian"
     IF hwg__isUnicode()
      oWinPrn:PrintLine("Срђан Драгојловић у реду број 13")
     ELSE
      oWinPrn:PrintLine(XWIN_SR("Срђан Драгојловић у реду број 13"))
     ENDIF
   ELSE
    oWinPrn:PrintLine("Line 13")
   ENDIF


   * Page 7
   * Print a bitmap in several ways
   oWinPrn:NextPage()
   oWinPrn:PrintLine("From file >hwgui.bmp<")
   oWinPrn:PrintBitmap( SAMPLE_IMAGEPATH + "hwgui.bmp" )
   * astro.bmp
   oWinPrn:PrintLine("From Hex value")
   oWinPrn:PrintBitmap( oBitmap1 , , "astro")
   oWinPrn:PrintLine("Center align")
   oWinPrn:PrintBitmap( oBitmap1 , 1 , "astro")
   oWinPrn:PrintLine("Right align")
   oWinPrn:PrintBitmap( oBitmap1 , 2 , "astro")
   // oWinPrn:PrintLine("From Hex value, size x 4")
   // oWinPrn:PrintBitmap( oBitmap2 , , "astro")

   * Page 8:
   * Test for METHOD NewLine() and switch to other modes in one print line
   * + Euro currency sign
   oWinPrn:NextPage()
   * Switch to small and back

   oWinPrn:PrintLine("Recent charset is " + ALLTRIM(STR(oWinPrn:nCharset)))
   oWinPrn:Newline()
   oWinPrn:SetX()
   oWinPrn:PrintText("Small : ")
   oWinPrn:SetMode( .T. )
   oWinPrn:PrintText("Small")
   oWinPrn:SetMode(.F.)
   oWinPrn:PrintText(" ... and normal again")
   oWinPrn:Newline()
#ifdef __PLATFORM__WINDOWS
* Windows
   oWinPrn:SetMode( , , , , , , , 1 )
   oWinPrn:PrintText("German Umlaute: " + ctest2 +  " Recent charset is " + ALLTRIM(STR(oWinPrn:nCharset)) )
   * Change charset, so that the Euro currency sign appeared
   oWinPrn:SetMode( , , , , , , , 0 )
   oWinPrn:PrintText(" Euro : " + CHR(128) )
   oWinPrn:Newline()
   oWinPrn:PrintText("Stroked zero : " + CHR(216) )
#else
* LINUX
   oWinPrn:SetCP("EN")
   oWinPrn:PrintText("German Umlaute: " + ctest1 +  " Recent charset is " + ALLTRIM(STR(oWinPrn:nCharset)) )
   oWinPrn:Newline()
   oWinPrn:SetCP("EN")       && Only this settings to have Euro sign
   oWinPrn:SetCDPin("UTF8")
   oWinPrn:PrintText(" Euro : " + cEuroUTF8 )
   oWinPrn:Newline()        && Reset to "EN","EN" ; otherwise the newline not printed
   oWinPrn:SetCP("EN")
   oWinPrn:SetCDPin("EN")
   oWinPrn:SetCDPin("UTF8")
   * Stroked zero: UTF-8 : 0xC3 = 195 , 0x98 = 152
   oWinPrn:PrintText("Stroked zero : " + CHR(195) + CHR(152) )


* Use the following sequence to look for desired characters and codepages
/*
   oWinPrn:Newline()
   FOR i := 128 TO 190
    oWinPrn:PrintText(CHR(i))
   NEXT
   oWinPrn:Newline()
   FOR i := 191 TO 255
    oWinPrn:PrintText(CHR(i))
   NEXT
*/

#endif

#ifdef __XHARBOUR__
     IF hZebra != NIL
        IF hb_zebra_geterror( hZebra ) == 0
           hb_zebra_draw( hZebra, {|x,y,w,h| oWinPrn:oPrinter:box(Int( x + .5 ), Int( y + .5 ),;
            Int( x + .5 ) + Int( w ), Int( y + .5 ) + Int( h ) + 1, xxxx ) },;  &&   xxxx => HB_WIN_RGB_BLACK
            nX, nY, nLineWidth, nLineHeight )
        ELSE
            hwg_msginfo( "Code"+cQR+";Error"+hb_zebra_geterror( hZebra ))
      ENDIF
      hb_zebra_destroy( hZebra )
     ELSE
     * Error
     hwg_msginfo(aMessages[22])
   ENDIF
#else
*    #ifdef __PLATFORM__WINDOWS
        cFile := CreateQRtoBMP( cQR, SAMPLE_IMAGEPATH + "QR.bmp" )
        IF .NOT. EMPTY(cFile)
         oWinPrn:PrintBitmap( cFile )
        ENDIF
*    #endif
#endif

   oWinPrn:End()

Return Nil

* QR encoding:
* The FUNCTION CreateQRtoBMP returns empty string, if encoding fails
* (because of for example of missing DLL)
* If OK, the return value is the name of a temporary bitmap
* file containing the requested QR code from passed string.

#ifdef __PLATFORM__WINDOWS
#ifdef WITH_QRENCDLL

#require "hbxpp"

FUNCTION CreateQRtoBMP( cStr, cFile )
   LOCAL qrDLL, cqrc, cbitmap , ctxtfi
   cFile := IIF(HB_ISNIL(cFile),hwg_CreateTempfileName("QR","*.bmp"), cFile )
   * Some trouble on Windows 11 with the created temporary file !
//   ctxtfi := hwg_CreateTempfileName("QR","*.txt")
    ctxtfi := "QRCodetemp.txt"
// hwg_msginfo("DLL")
   * Properitary libraray
   * IF CHECK_FILE2("QRCodelib.Dll")
   *  qrDLL := DLLLoad("QRCodelib.Dll" )
   *  DllCall(qrDLL,0x0020,"FastQRCode",cStr,cFile)
   *  DLLUnload(qrDLL)
   * ELSE
   *  cFile:= ""
   * ENDIF

   * Open source library
   IF CHECK_FILE2("qrcodegen.dll")
    qrDLL := DLLLoad( "qrcodegen.dll" )
    DllCall( qrDLL, 0x0000, "FastQRCode", cStr, ctxtfi )
    DLLUnload(qrDLL)

    cqrc := MEMOREAD(ctxtfi)
    cqrc := hwg_QRCodeZoom(cqrc,4)
    cbitmap := hwg_QRCodetxt2BPM( cqrc )
    MEMOWRIT( cFile, cbitmap )
    DELETE FILE &ctxtfi
   ELSE
     cFile := ""
   ENDIF

RETURN cFile

#endif
#endif

#ifdef __PLATFORM__WINDOWS
* Static link Win
#ifdef WITH_QRENCST
FUNCTION CreateQRtoBMP( cStr, cFile )
 LOCAL cqrc, cbitmap
 cFile := IIF(HB_ISNIL(cFile),hwg_CreateTempfileName("QR","*.bmp"), cFile )
 cqrc := hwg_QRCodeTxtGen(cStr,1)
* If desired to zoom
  cqrc := hwg_QRCodeZoom( cqrc, 4 )
  cbitmap := hwg_QRCodetxt2BPM( cqrc )
* Store to bitmap file
   MEMOWRIT( cFile, cbitmap )
RETURN cFile
#endif
#endif
* With no dll

#ifndef __PLATFORM__WINDOWS
* --- LINUX ---
#ifdef WITH_QRENCST
* LINUX (static link)
FUNCTION CreateQRtoBMP( cStr, cFile )
 LOCAL cqrc, cbitmap
 cFile := IIF(HB_ISNIL(cFile),hwg_CreateTempfileName("QR","*.bmp"), cFile )
 cqrc := hwg_QRCodeTxtGen(cStr,1)
* If desired to zoom
  cqrc := hwg_QRCodeZoom( cqrc, 4 )
  cbitmap := hwg_QRCodetxt2BPM( cqrc )
* Store to bitmap file
   MEMOWRIT( cFile, cbitmap )
RETURN cFile

#endif
#endif

* Without QRCODE (use dummy function)
#ifndef WITH_QRENCST
#ifndef WITH_QRENCDLL
FUNCTION CreateQRtoBMP( cStr, cFile )
HB_SYMBOL_UNUSED(cStr)
HB_SYMBOL_UNUSED(cFile)
RETURN ""
#endif
#endif

* ---------------------------------------------
FUNCTION XWIN_SR(clang)
* ~~~~~~~~~~ Serbian ~~~~~~~~~~~~~~~~~~~~~~~~~~
* ---------------------------------------------
RETURN HB_TRANSLATE( clang, "UTF8", "SRWIN" )

* ---------------------------------------------
FUNCTION NLS_SetLang(cname,omain)
* Sets the desired language for NLS
* ---------------------------------------------
*
* For special signs:
*  IF hwg__isUnicode()
*  * UTF-8 (without BOM)
*   ....
*  ELSE
*   && Windows
*   && Use CHR(n) function for encoding character
*   ....
*  ENDIF
  LOCAL bmn
  bmn := .F.
  IF omain != NIL ; bmn := .T. ; ENDIF

/* Add case block for every new language */
  DO CASE
    * ~~~~~~~~~~~~ Serbian ~~~~~~~~~~~
    CASE cname == "Serbian"
      clangset := "Serbian"
     IF hwg__isUnicode()
         * UTF-8 (without BOM)
      aMainMenu := { "Излаз", "&Заврши са радом" , "&Штампај" , "Покрени штампу" , "Подешавање", "Кодна страна штампача" , "&Jезик" , ;
      "&Диалог-Модус" }
        cTitle := "Демо за Winprn класу"
      ELSE
        * Windows
       aMainMenu := { XWIN_SR("Излаз"), XWIN_SR("&Заврши са радом") , XWIN_SR("&Штампај") , ;
         XWIN_SR("Покрени штампу") , XWIN_SR("Подешавање"), XWIN_SR("Кодна страна штампача") , ;
         XWIN_SR("&Jезик") , ;
         "&Dialog-Modus" }
        cTitle := XWIN_SR( "Демо за Winprn класу" )
      ENDIF
      * Set title of main windows
      IF bmn ; Set_Maintitle(omain,cTitle) ; ENDIF
    * ~~~~~~~~~~~~ German DE ~~~~~~~~~~~
    CASE cname == "Deutsch"  && Germany @ Euro
      clangset := "Deutsch"
      aMainMenu := { "E&nde", "&Quit" , "&Drucken" , "&Druck starten" , "&Einstellungen" , ;
       "Drucker &Zeichensatz" , "&Sprache" , "&Dialog-Modus" }
      IF hwg__isUnicode()
        * UTF-8 (without BOM)
        cTitle := "Demo für Winprn-Klasse"
      ELSE
        * Windows
        cTitle := "Demo f" + CHR(252) + "r Winprn-Klasse"
      ENDIF
      * Set title of main windows
      IF bmn ; Set_Maintitle(omain,cTitle) ; ENDIF
   * ~~~~~~~~~~~~ German AT ~~~~~~~~~~~
   CASE cname == "Deutsch-OE"  && Austria: German @ Euro
      aMainMenu := { "E&nde", "&Quit" , "&Drucken" , "&Druck starten" , "&Einstellungen" , ;
       "Drucker &Zeichensatz" , "&Sprache" , "&Dialog-Modus" }
      clangset := "Deutsch"
      IF hwg__isUnicode()
        * UTF-8 (without BOM)
        cTitle := "Demo für Winprn-Klasse"
      ELSE
        * Windows
        cTitle := "Demo f" + CHR(252) + "r Winprn-Klasse"
      ENDIF
   * ~~~~~~~~~~~~ English / USA ~~~~~~~~~~~
   OTHERWISE    && Default EN/USA
     aMainMenu := { "&Exit", "&Quit" , "&Print" , "&Start printing" , "&Settings" , ;
      "&Printer Char Set" , "&Language" , "&Select dialog mode" }
     clangset := "English"
     cTitle := "Demo for Winprn Class"
      * Set title of main windows
     IF bmn ; Set_Maintitle(omain,cTitle) ; ENDIF
 ENDCASE

RETURN NIL


* ---------------------------------------------
FUNCTION Select_Mode
* Dialog for selection of printer dialog mode
* ---------------------------------------------
LOCAL result, achrit, csel , nchrs
  csel := ""
  nchrs := 1
  achrit := acdiamode()
  result := __frm_CcomboSelect(achrit,"Select a dialog mode","Please Select dialog mode", ;
   200 , "OK" , "Cancel", "Help" , "Need Help : " , "HELP !" , nchrs )
  nchrs := result - 1 /* Position in COMBOBOX */
  * Copy results to public
   nmode := nchrs
/*
   0 : Print immediately (show no print preview). Default, old behavior.
   1 : Show print preview and start printing with print button press.
   2 : Show print preview and hide print button.
*/
   lPreview := IIF ( nmode > 0 , .T. , .F.)
   lprbutton :=  IIF ( nmode > 1 , .F. , .T. )

   hwg_MsgInfo("Preview: " + Bool2string(lPreview) + CHR(10) + ;
   "Print Button in preview: " + Bool2string(lprbutton),"Dialog mode settting")
RETURN NIL

* ---------------------------------------------
FUNCTION Bool2string(lval)
* ---------------------------------------------
IF lval
 RETURN "Yes"
ENDIF
RETURN "No"

* ---------------------------------------------
FUNCTION Select_LangChrs
* Dialog for selection of printer character set
* ---------------------------------------------
LOCAL result, achrit, csel
  csel := ""
  achrit := acPr_Charsets()
  result := __frm_CcomboSelect(achrit,"Printer Character Set","Please Select a Character Set", ;
   200 , "OK" , "Cancel", "Help" , "Need Help : " , "HELP !" , nchrs )
 IF result != 0
  * set to new value, if modified
  nchrs := result /* Position in COMBOBOX */
  csel := achrit[result]
  * Get the number of printer char set before ":"
  nPrCharset := VAL(SUBSTR(csel,1,AT(":",csel) - 1 ) )
  hwg_MsgInfo("Character Set is now: " + ALLTRIM(STR(nchrs)) + " Name: " + csel , ;
          "Printer Character Set")
 ENDIF
RETURN NIL


* ---------------------------------------------
FUNCTION hwg_HPrinter_LangArray_SR()
* ============ Serbian ==============
* ---------------------------------------------
/* Returns array with captions for titles and controls of print preview dialog
  in serbian language.
  Use this code snippet as template to set to your own desired language. */

  LOCAL aTooltips := {}
  LOCAL cEuro

  IF hwg__isUnicode()
    cEuro  := "€"
   ELSE
    cEuro  := CHR(128)
   ENDIF

  IF hwg__isUnicode()
  /* 1  */ AAdd(aTooltips,"Излаз из прегледа")           && Exit Preview
  /* 2  */ AAdd(aTooltips,"Штампање документа")          && Print file
  /* 3  */ AAdd(aTooltips,"Прва страна")                 && First page
  /* 4  */ AAdd(aTooltips,"Следећа страна")              && Next page
  /* 5  */ AAdd(aTooltips,"Претходна страна")            && Previous page
  /* 6  */ AAdd(aTooltips,"Последња страна")             && Last page
  /* 7  */ AAdd(aTooltips,"Увећај")                      && Zoom out
  /* 8  */ AAdd(aTooltips,"Умањи")                       && Zoom in
  /* 9  */ AAdd(aTooltips,"Подешавање штампе")              && Print dialog
  // added (Titles and other Buttons)
  /* 10 */ AAdd(aTooltips,"Преглед штампе -")          && Title                     "Print preview -"
  /* 11 */ AAdd(aTooltips,"Штампај")                    && Button                    "Print"
  /* 12 */ AAdd(aTooltips,"Излаз")                      && Button             "Exit"
  /* 13 */ AAdd(aTooltips,"Подешавање")        && Button                    "Dialog"
  /* 14 */ AAdd(aTooltips,"Benutzer-Knopf")  && aBootUser[ 3 ], Tooltip   "User Button"
  /* 15 */ AAdd(aTooltips,"Benutzer-Knopf")  && aBootUser[ 4 ]            "User Button"
  // Subdialog "Printer Dialog"
  /* 16 */ AAdd(aTooltips,"Све")              && Radio Button              "All"
  /* 17 */ AAdd(aTooltips,"Тренутна страна")  && Radio Button              "Current"
  /* 18 */ AAdd(aTooltips,"Стране")           && Radio Button              "Pages"
  /* 19 */ AAdd(aTooltips,"Штампај")          && Button                    "Print"
  /* 20 */ AAdd(aTooltips,"Прекини" )         && Button                    "Cancel"
  /* 21 */ AAdd(aTooltips,"Унеси опсег страна") && Tooltip         "Enter range of pages"
  /* 22 */ AAdd(aTooltips,"Грешка")                                        && Error

  ELSE
  * Windows
   /* 1  */ AAdd(aTooltips,XWIN_SR("Излаз из прегледа") )          && Exit Preview
  /* 2  */ AAdd(aTooltips,XWIN_SR("Штампање документа") )          && Print file
  /* 3  */ AAdd(aTooltips,XWIN_SR("Прва страна") )                 && First page
  /* 4  */ AAdd(aTooltips,XWIN_SR("Следећа страна") )              && Next page
  /* 5  */ AAdd(aTooltips,XWIN_SR("Претходна страна") )           && Previous page
  /* 6  */ AAdd(aTooltips,XWIN_SR("Последња страна") )             && Last page
  /* 7  */ AAdd(aTooltips,XWIN_SR("Увећај") )                      && Zoom out
  /* 8  */ AAdd(aTooltips,XWIN_SR("Умањи") )                      && Zoom in
  /* 9  */ AAdd(aTooltips,XWIN_SR("Подешавање штампе") )             && Print dialog
  // added (Titles and other Buttons)
  /* 10 */ AAdd(aTooltips,XWIN_SR("Преглед штампе -") )        && Title                     "Print preview -"
  /* 11 */ AAdd(aTooltips,XWIN_SR("Штампај") )                   && Button                    "Print"
  /* 12 */ AAdd(aTooltips,XWIN_SR("Излаз") )                     && Button             "Exit"
  /* 13 */ AAdd(aTooltips,XWIN_SR("Подешавање") )           && Button                    "Dialog"
  /* 14 */ AAdd(aTooltips,"Benutzer-Knopf")  && aBootUser[ 3 ], Tooltip   "User Button"
  /* 15 */ AAdd(aTooltips,"Benutzer-Knopf")  && aBootUser[ 4 ]            "User Button"
  // Subdialog "Printer Dialog"
  /* 16 */ AAdd(aTooltips,XWIN_SR("Све")  )            && Radio Button              "All"
  /* 17 */ AAdd(aTooltips,XWIN_SR("Тренутна страна") )  && Radio Button              "Current"
  /* 18 */ AAdd(aTooltips,XWIN_SR("Стране") )          && Radio Button              "Pages"
  /* 19 */ AAdd(aTooltips,XWIN_SR("Штампај") )         && Button                    "Print"
  /* 20 */ AAdd(aTooltips,XWIN_SR("Прекини" ) )        && Button                    "Cancel"
  /* 21 */ AAdd(aTooltips,XWIN_SR("Унеси опсег страна") ) && Tooltip         "Enter range of pages"
  /* 22 */ AAdd(aTooltips,XWIN_SR("Грешка") )                                        && Error

  ENDIF

RETURN aTooltips

* ---------------------------------------------
FUNCTION hwg_HPrinter_LangArray_DE()
* ============ German ==============
* ---------------------------------------------
/* Returns array with captions for titles and controls of print preview dialog
  in german language.
  Use this code snippet as template to set to your own desired language. */

  LOCAL aTooltips
  * For special characters: Umlaute, sharp "S" and Euro Currency sign
  LOCAL CAGUML, COGUML, CUGUML, CAKUML, COKUML, CUKUML, CSZUML, cEuro
  aTooltips := {}
  * Language dependent special characters:
  * Umlaute and Sharp "S", Euro currency sign.

  IF hwg__isUnicode()
  * UTF-8 (without BOM)
    CAGUML := "Ä"
    COGUML := "Ö"
    CUGUML := "Ü"
    CAKUML := "ä"
    COKUML := "ö"
    CUKUML := "ü"
    CSZUML := "ß"
    cEuro  := "€"
   ELSE
   * DEWIN
    CAGUML := CHR(196)
    COGUML := CHR(214)
    CUGUML := CHR(220)
    CAKUML := CHR(228)
    COKUML := CHR(246)
    CUKUML := CHR(252)
    CSZUML := CHR(223)
    cEuro  := CHR(128)
   ENDIF


  /* 1  */ AAdd(aTooltips,"Vorschau beenden")            && Exit Preview
  /* 2  */ AAdd(aTooltips,"Datei drucken")               && Print file
  /* 3  */ AAdd(aTooltips,"Erste Seite")                 && First page
  /* 4  */ AAdd(aTooltips,"N" + CAKUML + "chste Seite")  && Next page
  /* 5  */ AAdd(aTooltips,"Vorherige Seite")             && Previous page
  /* 6  */ AAdd(aTooltips,"Letzte Seite")                && Last page
  /* 7  */ AAdd(aTooltips,"Kleiner")                     && Zoom out
  /* 8  */ AAdd(aTooltips,"Gr" + COKUML + CSZUML + "er") && Zoom in
  /* 9  */ AAdd(aTooltips,"Druck-Optionen")              && Print dialog
  // added (Titles and other Buttons)
  /* 10 */ AAdd(aTooltips,"Druckvorschau -") && Title                     "Print preview -"
  /* 11 */ AAdd(aTooltips,"Drucken")         && Button                    "Print"
  /* 12 */ AAdd(aTooltips,"Schlie" + CSZUML + "en") && Button             "Exit"
  /* 13 */ AAdd(aTooltips,"Optionen")        && Button                    "Dialog"
  /* 14 */ AAdd(aTooltips,"Benutzer-Knopf")  && aBootUser[ 3 ], Tooltip   "User Button"
  /* 15 */ AAdd(aTooltips,"Benutzer-Knopf")  && aBootUser[ 4 ]            "User Button"
  // Subdialog "Printer Dialog"
  /* 16 */ AAdd(aTooltips,"Alles")           && Radio Button              "All"
  /* 17 */ AAdd(aTooltips,"Aktuelle Seite")  && Radio Button              "Current"
  /* 18 */ AAdd(aTooltips,"Seiten")          && Radio Button              "Pages"
  /* 19 */ AAdd(aTooltips,"Drucken")         && Button                    "Print"
  /* 20 */ AAdd(aTooltips,"Abbruch" )        && Button                    "Cancel"
  /* 21 */ AAdd(aTooltips,"Seitenbereich(e) eingeben") && Tooltip         "Enter range of pages"
  /* 22 */ AAdd(aTooltips,"Fehler")                                        && Error

RETURN aTooltips

* ---------------------------------------------
FUNCTION Wprn_HPrinter_LangArray_EN()
* ============ English ==============
* ~~~~~~~~~~ Default ~~~~~~~~~~~~~~~~

  LOCAL aTooltips

  aTooltips := {}

  /* 1  */ AAdd(aTooltips,"Exit Preview")                                 && Exit Preview
  /* 2  */ AAdd(aTooltips,"Print file")                                   && Print file
  /* 3  */ AAdd(aTooltips,"First page")                                   && First page
  /* 4  */ AAdd(aTooltips,"Next page")  && Next page
  /* 5  */ AAdd(aTooltips,"Previous page")                                && Previous page
  /* 6  */ AAdd(aTooltips,"Last page")                                    && Last page
  /* 7  */ AAdd(aTooltips,"Zoom out")                                     && Zoom out (smaller)
  /* 8  */ AAdd(aTooltips,"Zoom in") && Zoom in (greater)
  /* 9  */ AAdd(aTooltips,"Print dialog")                                 && Print dialog
   // added (Titles and other Buttons)
  /* 10 */ AAdd(aTooltips,"Print preview -") && Title                     "Print preview -"
  /* 11 */ AAdd(aTooltips,"Print")           && Button                    "Print"
  /* 12 */ AAdd(aTooltips,"Exit") && Button             "Exit"
  /* 13 */ AAdd(aTooltips,"Dialog")          && Button                    "Dialog"  (Options)
  /* 14 */ AAdd(aTooltips,"User Button")     && aBootUser[ 3 ], Tooltip   "User Button"
  /* 15 */ AAdd(aTooltips,"User Button")     && aBootUser[ 4 ]            "User Button"
  // Subdialog "Printer Dialog"
  /* 16 */ AAdd(aTooltips,"All")             && Radio Button              "All"
  /* 17 */ AAdd(aTooltips,"Current")         && Radio Button              "Current"
  /* 18 */ AAdd(aTooltips,"Pages")           && Radio Button              "Pages"
  /* 19 */ AAdd(aTooltips,"Print")           && Button                    "Print"
  /* 20 */ AAdd(aTooltips,"Cancel" )         && Button                    "Cancel"
  /* 21 */ AAdd(aTooltips,"Enter range of pages") && Tooltip              "Enter range of pages"
 // Added: For dialogs and messages
  /* 22 */ AAdd(aTooltips,"Error")                                        && Error

RETURN aTooltips


* ==========================================
FUNCTION __frm_CcomboSelect(apItems, cpTitle, cpLabel, npOffset, cpOK, cpCancel, cpHelp , cpHTopic , cpHVar , npreset)
* Common Combobox Selection
* One combobox flexible.
* Parameters: (Default values in brackets)
* apItems  : Array with items (empty)
* cpTitle  : Title for dialog ("Select Item")
* cpLabel  : Headline         ("Select Item")
* npOffset : Number of pixels for windows size offset, y axis (0)
*            recommended value: depends of number of items:
*            npOffset = (n - 1) * 30 (not exact)
* cpOK     : Button caption   ("OK")
* cpCancel : Button caption   ("Cancel")
* cpHelp   : Button caption   ("Help")
* cpHTopic : HELP() : Topic   ("")
* cpHVar   : HELP() : Variable Name ("")
* npreset  : Preser position (1)
*
* Sample call :
*
* LOCAL result,acItems
* acItems := {"One","Two","Three"}
* result := __frm_CcomboSelect(acItems,"Combo selection","Please Select an item", ;
*  0 , "OK" , "Cancel", "Help" , "Need Help : " , "HELP !" )
* returns: index number of item, if cancel: 0
* ============================================
LOCAL oDlgcCombo1
LOCAL aITEMS , cTitle, cLabel, nOffset, cOK, cCancel, cHelp , cHTopic , cHVar
LOCAL oLabel1, oCombobox1, oButton1, oButton2, oButton3 , nType , yofs, bcancel ,nRetu

* Parameter check
 cTitle  := "Select Item"
 cLabel  := "Select Item"
 nOffset := 0
 cOK     := "OK"
 cCancel := "Cancel"
 cHelp   := "Help"
 cHTopic := ""
 cHVar   := ""
 nRetu   := 0

aITEMS := {}
IF .NOT. apItems == NIL
 aITEMS := apItems
ENDIF
IF .NOT. cpTitle == NIL
 cTitle := cpTitle
ENDIF
IF .NOT. cpLabel == NIL
 cLabel :=  cpLabel
ENDIF
IF .NOT. npOffset == NIL
 nOffset :=  npOffset
ENDIF
IF .NOT. cpOK == NIL
 cOK  :=  cpOK
ENDIF
IF .NOT. cpCancel == NIL
 cCancel :=  cpCancel
ENDIF
IF .NOT. cpHelp == NIL
 cHelp :=  cpHelp
ENDIF
IF .NOT. cpHTopic == NIL
 cHTopic  := cpHTopic
ENDIF
IF .NOT. cpHVar == NIL
 cHVar  := cpHVar
ENDIF
nType := 1
IF .NOT. npreset == NIL
 nType := npreset
ENDIF

bcancel := .T.
yofs := nOffset + 120
* y positions of elements:
* Label1       : 44
* Buttons      : 445  : ==> yofs
* Combobox     : 84   :
* Dialog size  : 565  : ==> yofs + 60
*
  INIT DIALOG oDlgcCombo1 TITLE cTitle ;
    AT 578,79 SIZE 516, yofs + 80;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 67,44 SAY oLabel1 CAPTION cLabel SIZE 378,22 ;
        STYLE SS_CENTER
   @ 66,84 GET COMBOBOX oCombobox1 VAR nType ITEMS aITEMS SIZE 378,96
   @ 58 , yofs  BUTTON oButton1 CAPTION cOK SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || nRetu := nType , bcancel := .F. , oDlgcCombo1:Close() }
   @ 175, yofs  BUTTON oButton2 CAPTION cCancel SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || oDlgcCombo1:Close() }
   @ 375, yofs  BUTTON oButton3 CAPTION cHelp SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || HELP( cHTopic ,PROCLINE(), cHVar ) }

   ACTIVATE DIALOG oDlgcCombo1 CENTER
* RETURN oDlgcCombo1:lresult
RETURN nRetu

* --------------------------------------------
FUNCTION acdiamode()
* Returns array with valid dialog modes
* as strings.
* Format : n : string
* Dependant on language setting.
* --------------------------------------------
LOCAL aps := {}

IF (clangset == NIL) .OR. EMPTY(clangset)
   AAdd (aps, "0")
   AAdd (aps, "1")
   AAdd (aps, "2")
   RETURN aps  && Avoid crash
 ENDIF

 IF clangset == "Serbian"
  IF hwg__isUnicode()
   AAdd (aps, "0 : Print immediately (show no print preview). Default, old behavior.")
   AAdd (aps, "1 : Show print preview and start printing with print button press")
   AAdd (aps, "2 : Show print preview and hide print button")
  ELSE
   * Windows
   // Use CHR(n) to code non ASCII characters (n > 127) to avoid errors with LINUX text editor (for example "gedit")
   // Sample:
   //  /* 1  */ AAdd(aps,"0 : " + CHR(nnn) + CHR(mmm) + CHR(ooo) + ...  )
   AAdd (aps, "0 : Print immediately (show no print preview). Default, old behavior.")
   AAdd (aps, "1 : Show print preview and start printing with print button press")
   AAdd (aps, "2 : Show print preview and hide print button")
  ENDIF && IF UTF-8
ENDIF   && Serbian



 IF clangset == "Deutsch"
   AAdd (aps, "0 : Sofortiger Ausdruck (keine Vorschau). Default, altes Verhalten.")
   AAdd (aps, "1 : Zeige Druck-Vorschau und Start des Ausdrucks mit Drucken-Knopf")
   AAdd (aps, "2 : Zeige Druck-Vorschau und verstecke den Drucken-Knopf")
 ENDIF

 IF clangset == "English"
  AAdd (aps, "0 : Print immediately (show no print preview). Default, old behavior.")
  AAdd (aps, "1 : Show print preview and start printing with print button press")
  AAdd (aps, "2 : Show print preview and hide print button")
 ENDIF


RETURN aps

* --------------------------------------------
FUNCTION acPr_Charsets
* Returns array with valid printer charsets
* as Strings
* See als include file "prncharsets.ch"
* For COMBOBOX selection dialog.
* Format : n : string
* --------------------------------------------
LOCAL aps := {}


 AAdd (aps, "0  : ANSI (CP1252, ansi-0, iso8859-{1,15})")
 AAdd (aps, "1  : DEFAULT")
 AAdd (aps, "2  : SYMBOL")
 AAdd (aps, "77 : MAC")
 AAdd (aps, "128: SHIFTJIS (CP932)")
 AAdd (aps, "129: HANGEUL(CP949, ksc5601.1987-0")
 AAdd (aps, "129: HANGUL")
 AAdd (aps, "130: JOHAB (korean (johab) CP1361)")
 AAdd (aps, "134: GB2312 (CP936, gb2312.1980-0)")
 AAdd (aps, "136: CHINESEBIG5 (CP950, big5.et-0)")
 AAdd (aps, "161: GREEK (CP1253)")
 AAdd (aps, "162: TURKISH (CP1254, -iso8859-9)")
 AAdd (aps, "163: VIETNAMESE (CP1258)")
 AAdd (aps, "177: HEBREW (CP1255, -iso8859-8)")
 AAdd (aps, "178: ARABIC (CP1256, -iso8859-6)")
 AAdd (aps, "186: BALTIC (CP1257, -iso8859-13)")
 AAdd (aps, "204: RUSSIAN (CP1251, -iso8859-5)")
 AAdd (aps, "222: THAI  (CP874,  -iso8859-11)")
 AAdd (aps, "238: EAST_EUROPE (EE_CHARSET)")
 AAdd (aps, "255: OEM")
RETURN aps


* --------------------------------------------
FUNCTION HELP(cTopic,nproc,cvar)
* Display help window
* --------------------------------------------
 hwg_MsgInfo(cTopic + " Line Number :" + ALLTRIM(STR(nproc)),cvar)
RETURN NIL

* --------------------------------------------
FUNCTION Select_LangDia(acItems)
* --------------------------------------------
LOCAL result
 result := __frm_CcomboSelect(acItems,"Language","Please Select a language", ;
   200 , "OK" , "Cancel", "Help" , "Need Help : " , "HELP !" )
 IF result != 0
  * set to new language, if modified
  clangset := aLanguages[result]
  NLS_SetLang(clangset)
  hwg_MsgInfo("Language set to " + clangset,"Language Setting")
 ENDIF
RETURN NIL

* --------------------------------------------
FUNCTION CHECK_FILE ( cfi )
* Check, if file exist,
* otherwise terminate program
* --------------------------------------------
 IF .NOT. FILE( cfi )
  Hwg_MsgStop("File >" + cfi + "< not found, program terminated","File ERROR !")
  QUIT
 ENDIF
RETURN Nil

* --------------------------------------------
FUNCTION CHECK_FILE2 ( cfi )
* Check, if file exist,
* if not, return .F.
* --------------------------------------------
 IF FILE( cfi )
  RETURN .T.
 ENDIF
RETURN .F.

* ========================================================
* Template for messages
* (Copy and modify to your own language)
* ========================================================

// IF hwg__isUnicode()
   // Use an text editor supporting UTF-8 coding
//  /* 1  */ AAdd(aTooltips,"Exit Preview")                                 && Exit Preview
//  /* 2  */ AAdd(aTooltips,"Print file")                                   && Print file
//  /* 3  */ AAdd(aTooltips,"First page")                                   && First page
//  /* 4  */ AAdd(aTooltips,"Next page")  && Next page
//  /* 5  */ AAdd(aTooltips,"Previous page")                                && Previous page
//  /* 6  */ AAdd(aTooltips,"Last page")                                    && Last page
//  /* 7  */ AAdd(aTooltips,"Zoom out")                                     && Zoom out (smaller)
//  /* 8  */ AAdd(aTooltips,"Zoom in") && Zoom in (greater)
//  /* 9  */ AAdd(aTooltips,"Print dialog")                                 && Print dialog
  // added (Titles and other Buttons)
//  /* 10 */ AAdd(aTooltips,"Print preview -") && Title                     "Print preview -"
//  /* 11 */ AAdd(aTooltips,"Print")           && Button                    "Print"
//  /* 12 */ AAdd(aTooltips,"Exit") && Button             "Exit"
//  /* 13 */ AAdd(aTooltips,"Dialog")          && Button                    "Dialog"  (Options)
//  /* 14 */ AAdd(aTooltips,"User Button")     && aBootUser[ 3 ], Tooltip   "User Button"
//  /* 15 */ AAdd(aTooltips,"User Button")     && aBootUser[ 4 ]            "User Button"
  // Subdialog "Printer Dialog"
//  /* 16 */ AAdd(aTooltips,"All")             && Radio Button              "All"
//  /* 17 */ AAdd(aTooltips,"Current")         && Radio Button              "Current"
//  /* 18 */ AAdd(aTooltips,"Pages")           && Radio Button              "Pages"
//  /* 19 */ AAdd(aTooltips,"Print")           && Button                    "Print"
//  /* 20 */ AAdd(aTooltips,"Cancel" )         && Button                    "Cancel"
//  /* 21 */ AAdd(aTooltips,"Enter range of pages") && Tooltip              "Enter range of pages"
 // Added: For dialogs and messages
//  /* 22 */ AAdd(aTooltips,"Error")                                        && Error

// ELSE
   // Windows
   // Use CHR(n) to code non ASCII characters (n > 127) to avoid errors with LINUX text editor (for example "gedit")
   // Sample:
   //  /* 1  */ AAdd(aTooltips,CHR(nnn) + CHR(mmm) + CHR(ooo) + ...  )      && Exit Preview
// ENDIF

* ============================= EOF of winprn.prg =========================================
