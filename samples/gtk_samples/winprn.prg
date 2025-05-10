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
*/

    * Status:
    *  WinAPI   :  Yes ==> Special problem bitmaps, see inline comment.
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No   (Compilable, but no print preview visible, don't matter, because not recommended)
    *
    * ----------------------------------------------
    * List of languages supported ( with name of author with call sign or e-mail address )
    * ----------------------------------------------
    * - English   (default, original by Alexander Kresin)
    * - German    Wilfried Brunken, DF7BE
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
* 2. Add requests for new languages in REQUEST section;
* 3. Add entry in PUBLIC array for new language.
*    Function Main :
*    aLanguage : Add new element in array with name of language, avoid special signs (only ANSI)
* 4. FUNCTION NLS_SetLang() : Add new block in case command.
* 5. FUNCTION PRINT_OUT():  Add new block in case command with initialization of Winprn class.


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
*/

/*
 Special hint for editing:
 Some troubles with Windows characters: we suggest to use the CHR() function
 to assign windows characters unique.
 */


#include "hwgui.ch"
#include "sampleinc.ch"

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


* === EN/USA ===
* Nothing to do

* ****************************
* For all languages: Unicode *
* ****************************
#ifndef __PLATFORM__WINDOWS
* LINUX Codepage
REQUEST HB_CODEPAGE_UTF8
#endif

 MEMVAR aMainMenu , aLanguages , aPriCharSets , att_priprev, clangset, cIniFile, cTitle
 MEMVAR nPrCharset, nchrs
 MEMVAR cHexAstro , cValAstro , oBitmap1 , oBitmap2
 MEMVAR ctempfile


* ---------------------------------------------
Function Main
* ---------------------------------------------
 LOCAL oMainWindow
 LOCAL cDirSep := hwg_GetDirSep()

 PUBLIC aMainMenu , aLanguages , aPriCharSets , att_priprev, clangset, cIniFile, cTitle
 PUBLIC nPrCharset, nchrs
 PUBLIC cHexAstro , cValAstro , oBitmap1 , oBitmap2
 PUBLIC ctempfile

   /* Names of supported languages, use only ANSI charset, displayed in language selection dialog */
   aLanguages := { "English", "Deutsch" }
   //   cIniFile := "language.ini"

   /* Preset defaults */
   nPrCharset := 0
   nchrs := 1 /* Item in COMBOXBOX */
   clangset := "English"
   aMainMenu := { "&Exit", "&Quit" , "&Print" , "&Start printing" , "&Settings" , ;
      "&Printer Char Set" , "&Language" }
   cTitle := "Demo for Winprn Class"
   NLS_SetLang(clangset)
* Ask user for startup language setting combobox
* and set to new language, if modified
 Select_LangDia(aLanguages)

* ==== Handle Resources ====

* Fill variables with hex values
 Init_Hexvars()

 CHECK_FILE( SAMPLE_IMAGEPATH + "hwgui.bmp")  && 301 x 160 pixel

 * Convert them all to binary.
 cValAstro := hwg_cHex2Bin ( cHexAstro )

 * Load contents from hex resources into image objects.
 * astro.bmp
 oBitmap1 := HBitmap():AddString( "astro", cValAstro )  && original size (Width x Height): 107 x 90 Pixel

 * Write hex value of astro.bmp into temporary file for GTK
 ctempfile := hwg_CreateTempfileName( , ".bmp")
 hb_memowrit( ctempfile , cValAstro )

 // not working yet:
 // oBitmap2 := HBitmap():AddString( "astro", cValAstro , 428 , 360) && resized x 4

 // Test
 // oBitmap1:OBMP2FILE( "test.bmp" , "astro" )

* Main Menu

   INIT WINDOW oMainWindow MAIN TITLE cTitle ;
     AT 0,0 SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   // MENUITEM in main menu on GTK/Linux does not start the desired action
   // Submenu needed
   MENU OF oMainWindow
      MENU TITLE aMainMenu[1]  /* Exit */
        MENUITEM aMainMenu[2] ACTION oMainWindow:Close() /* Quit */
      ENDMENU
      MENU TITLE aMainMenu[3] /* Print */
         MENUITEM aMainMenu[4] ACTION { || PRINT_OUT(clangset) }
      ENDMENU
      MENU TITLE aMainMenu[5] /* Settings */
         MENUITEM aMainMenu[6] ACTION Select_LangChrs()  /* Charset */
         MENUITEM aMainMenu[7] ACTION Select_LangDia(aLanguages)  /* Language */
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow

 * Erase the temporary file from astro.bmp
 FERASE(ctempfile)

RETURN NIL

#ifdef __GTK__
#ifdef __PLATFORM__WINDOWS
#include "..\hexres.ch"
#else
#include "../hexres.ch"
#endif
#else
#include "hexres.ch"
#endif

* ---------------------------------------------
FUNCTION Set_Maintitle(omnwnd,ctit)
* Modify title of main window
* ---------------------------------------------
  omnwnd:SetTitle(ctit)
RETURN NIL

* ---------------------------------------------
FUNCTION PRINT_OUT(cname)
* Print test
* ---------------------------------------------

Local oWinPrn, i , j
LOCAL ctest1
* Block grafic chars (CP850), single line
LOCAL cCross, cvert, chori, ctl, ctr, ctd, clr , crl, cbl, cbr, cbo
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


  IF cname == NIL ; cname := "English" ; ENDIF
/* ===========================================
   + Initialize sequences for printer class  +
   ===========================================
*/
  DO CASE

   * =============== German =================
   CASE cname == "Deutsch"  && Germany @ Euro

#ifndef __PLATFORM__WINDOWS
   oWinPrn := HWinPrn():New( ,"DE858","UTF8", , nPrCharset )
//   oWinPrn := HWinPrn():New( ,,"UTF8", , nPrCharset )
   oWinPrn:aTooltips := hwg_HPrinter_LangArray_DE()
   oWinPrn:StartDoc( .T.,"temp_a2.ps" )
#else
   oWinPrn := HWinPrn():New( ,"DE858","DEWIN", , nPrCharset)
   /* This displays the Euro currency sign CHR(128) correct, but not
      all of the Umlaute ! */
//   oWinPrn := HWinPrn():New( ,,, , nPrCharset )
   oWinPrn:aTooltips := hwg_HPrinter_LangArray_DE()
*   oWinPrn:StartDoc( .T. )
   oWinPrn:StartDoc( .T.,"temp_a2.pdf" )
#endif


/*
   *  =============== Russian ==================
*  Hello Alexander, i think this is your job.
  CASE cname == "Russian"
#ifndef __PLATFORM__WINDOWS
   oWinPrn := HWinPrn():New( ,"RU866","RUKOI8" , , nPrCharset ) && 204
      oWinPrn:aTooltips := hwg_HPrinter_LangArray_RU()
   oWinPrn:StartDoc( .T.,"temp_a2.ps" )
#else
   oWinPrn := HWinPrn():New( ,"RU866","RU1251", , nPrCharset ) && 204
   oWinPrn:aTooltips := hwg_HPrinter_LangArray_RU()
//   Hwg_MsgInfo("nCharset=" + STR(oWinPrn:nCharset),"Russian" )
*   oWinPrn:StartDoc( .T. )
   oWinPrn:StartDoc( .T.,"temp_a2.pdf" )
#endif
*/

 OTHERWISE
/* ============== Default EN/USA ==================*/
#ifndef __PLATFORM__WINDOWS
   oWinPrn := HWinPrn():New( ,,, , nPrCharset )
   oWinPrn:StartDoc( .T.,"temp_a2.ps" )
#else
   oWinPrn := HWinPrn():New( ,,, , nPrCharset)
*   oWinPrn:StartDoc( .T. )
    oWinPrn:StartDoc( .T.,"temp_a2.pdf" )
#endif

 ENDCASE
/* ====================================
   + End of Printer initialization    +
   ====================================
*/

* Test German Umlaute and sharp "S"
   ctest1 := CHR(142) + CHR(153) + CHR(154) + CHR(132) + CHR(148) + CHR(129) + CHR(225)



  * print all chars over ASCII with decimal values
  FOR j := 128 TO 190
   oWinPrn:PrintLine(ALLTRIM(STR(j)) + ": " + CHR(j) )
  NEXT
  oWinPrn:NextPage()
  FOR j := 191 TO 255
   oWinPrn:PrintLine(ALLTRIM(STR(j)) + ": " + CHR(j) )
  NEXT
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

   oWinPrn:PrintLine(ctest1)

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
   oWinPrn:NextPage()
   oWinPrn:PrintLine( oWinPrn:oFont:name + " " + Str(oWinPrn:oFont:height) + " " + Str(oWinPrn:nCharW) + " " + Str(oWinPrn:nLineHeight) )
   FOR i := 1 TO 80
      oWinPrn:PrintLine( Padl( i,3 ) + " --------" )
   NEXT

   * Test 10 lines forward
   oWinPrn:NextPage()
   oWinPrn:PrintLine(10)
   oWinPrn:PrintLine("Line 11")
   oWinPrn:PrintLine()
   oWinPrn:PrintLine("Line 13")


   /*
    =============================
    Error handling in GTK/Cairo:
    =============================
    The symptom is, that after a bitmap is displayed,
    in all text lines following the the first insertion of a bitmap,
    the text is not displayed.
    Referred to sample program "winprn.prg", on page 7
    the first text "From file >hwgui.bmp<" is visible,
    after the first bitmap "./../image/hwgui.bmp" all
    following texts ("astro from hex value via temporary file" and
    "--------------------") are blank.
    Line feed with PrintLine(10) works OK.

    So the workaround is:
    First insert all text lines, after
    this, insert all images.
    To set the position of the image in the document,
    use method SetY(n) to preset the position of the
    image, than say oWinPrn:PrintBitmap(...).
    Get the Y position by inserting:
    hwg_MsgInfo(STR(oWinPrn:y) )
    Repeat this for every bitmap.

    That is done here in the following program lines.

    Also this does not work on GTK:
     oWinPrn:PrintBitmap( oBitmap1 )
    (read bitmap from object)

    This workaround is:

    In main section:
    * Fill variables with hex values
    Init_Hexvars()

    * Convert to binary.
    cValAstro := hwg_cHex2Bin ( cHexAstro )

    * Write hex value of astro.bmp into temporary file
    ctempfile := hwg_CreateTempfileName( , ".bmp")
    hb_memowrit( ctempfile , cValAstro )

    ...

    * Erase the temporary file from astro.bmp
    FERASE(ctempfile)

    ...

    Insert bitmap into print cache:
    oWinPrn:SetY(nnn)
    oWinPrn:PrintBitmap( ctempfile )

    Check with WinAPI:
    The method SetY() does not work in the same way.
    For multi platform application
    use the compiler switch
    #ifdef __GTK__
    to activate special adapted code.
    See also same sample for WinAPI.

   */

   * Print a bitmap in several ways
   oWinPrn:NextPage() && Text height is 12
   oWinPrn:PrintLine("From file >hwgui.bmp<")  && hwgui.bmp height = 160
/* Get Y position */
//   hwg_MsgInfo(STR(oWinPrn:y) )
//   oWinPrn:PrintBitmap( SAMPLE_IMAGEPATH + "hwgui.bmp" )
/* Move forward up to the height of bitmap (0 + 160)  */


   oWinPrn:SetY(172)  && 160 + 12
   * astro.bmp height = 90

/* Handled by workaround */


// Before workaround: This line is not visible.
   // oWinPrn:PrintLine("From Hex value")
   oWinPrn:PrintLine("astro from hex value via temporary file")
   // hwg_MsgInfo(STR(oWinPrn:y) )  && 184
   oWinPrn:SetY(274)   && 184 + 90
//   oWinPrn:PrintBitmap( oBitmap1 ,   , "astro")
   oWinPrn:PrintLine("Center align")
   // hwg_MsgInfo(STR(oWinPrn:y) )
   oWinPrn:SetY(376)   && 286 + 90
//   oWinPrn:PrintBitmap( oBitmap1 , 1 , "astro")
   oWinPrn:PrintLine("Right align")
//   hwg_MsgInfo(STR(oWinPrn:y) )
//   oWinPrn:PrintBitmap( oBitmap1 , 2 , "astro")
   // oWinPrn:PrintLine("From Hex value, size x 4")
   // oWinPrn:PrintBitmap( oBitmap2 , , "astro")

// The rest is OK



   oWinPrn:SetY(490)  && 388 + 90
   oWinPrn:PrintLine("--------------------")

   * Workaround:
   * Insert bitmaps after text lines.

   oWinPrn:SetY(12)
   oWinPrn:PrintBitmap( SAMPLE_IMAGEPATH + "hwgui.bmp" )
   oWinPrn:SetY(184)
   oWinPrn:PrintBitmap( ctempfile )
//   oWinPrn:PrintBitmap( oBitmap1 ,   , "astro")   && Does not work
   oWinPrn:SetY(286)
//   oWinPrn:PrintBitmap( oBitmap1 , 1 , "astro")
   oWinPrn:PrintBitmap( ctempfile , 1 )
   oWinPrn:SetY(388)
//   oWinPrn:PrintBitmap( oBitmap1 , 2 , "astro")
   oWinPrn:PrintBitmap( ctempfile , 2 )

   * All okay on next page ?
   oWinPrn:NextPage()
   oWinPrn:PrintLine("Page 8")

   oWinPrn:End()

Return Nil

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
   CASE cname == "Deutsch"  && Germany @ Euro
      clangset := "Deutsch"
      aMainMenu := { "E&nde", "&Quit" , "&Drucken" , "&Druck starten" , "&Einstellungen" , ;
       "Drucker &Zeichensatz" , "&Sprache" }
      IF hwg__isUnicode()
        * UTF-8 (without BOM)
        cTitle := "Demo für Winprn-Klasse"
      ELSE
        * Windows
        cTitle := "Demo f" + CHR(252) + "r Winprn-Klasse"
      ENDIF
      * Set title of main windows
      IF bmn ; Set_Maintitle(omain,cTitle) ; ENDIF
   CASE cname == "Deutsch-OE"  && Austria: German @ Euro
      aMainMenu := { "E&nde", "&Quit" , "&Drucken" , "&Druck starten" , "&Einstellungen" , ;
       "Drucker &Zeichensatz" , "&Sprache" }
      clangset := "Deutsch"
      IF hwg__isUnicode()
        * UTF-8 (without BOM)
        cTitle := "Demo für Winprn-Klasse"
      ELSE
        * Windows
        cTitle := "Demo f" + CHR(252) + "r Winprn-Klasse"
      ENDIF
  OTHERWISE    && Default EN/USA
     aMainMenu := { "&Exit", "&Quit" , "&Print" , "&Start printing" , "&Settings" , ;
      "&Printer Char Set" , "&Language" }
     clangset := "English"
     cTitle := "Demo for Winprn Class"
      * Set title of main windows
     IF bmn ; Set_Maintitle(omain,cTitle) ; ENDIF
 ENDCASE

RETURN NIL

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

RETURN aTooltips

* ==========================================
FUNCTION __frm_CcomboSelect(apItems, cpTitle, cpLabel, npOffset, cpOK, cpCancel, cpHelp , cpHTopic , cpHVar , npreset )
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

   ACTIVATE DIALOG oDlgcCombo1
* RETURN oDlgcCombo1:lresult
RETURN nRetu


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

* ============================= EOF of winprn.prg =========================================
