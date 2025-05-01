/*
 *$Id$
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Misc functions for multi platform usage.
 *
 * This is a container for several useful functions.
 * Don't forget to add the desription in the function docu, if
 * a new function is added.
 * Try to make versions for WinAPI and GTK equal.
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2020-2025 Wilfried Brunken, DF7BE

 * All functions of this file are former found in
 * hmisc.prg of source/winapi and source/gtk

*/

#include "hwgui.ch"
#include "hbclass.ch"

* ================================= *

STATIC nuniquenr

FUNCTION hwg_RdLn(nhandle, lrembltab)

 LOCAL nnumbytes , nnumbytes2 , buffer , buffer2
 LOCAL  bEOL , xLine , bMacOS, xarray, ceoltype
 // LOCAL lbEOF

 IF lrembltab == NIL
   lrembltab := .F.
 ENDIF
 xarray := {}
 nnumbytes := 1
 nnumbytes2 := 0
 bEOL := .F.
 xLine := ""
 bMacOS := .F.
 * Buffer may not be empty, otherwise FREAD() reads nothing !
 * Fill with SPACE(n), n is the desired size of read buffer
 * (here 1)
 buffer := " "
 buffer2 := " "
//   lbEOF := .F.
 ceoltype := "U"

    DO WHILE ( nnumbytes != 0 ) .AND. ( .NOT. bEOL )
       nnumbytes := FREAD(nhandle,@buffer,1)  && Read 1 Byte
       * If read nothing, EOF is reached
       IF nnumbytes < 1
//        lbEOF := .T.
        IF .NOT. EMPTY(xLine)
        * Last line may be without line ending
          xLine := hwg_RmCr(xLine)
          * Remove SUB 0x1A = CHR(26) = EOF marker
          xLine := STRTRAN(xLine,CHR(26),"")
           IF lrembltab
             * Remove blanks or tabs at end of line
             xLine := hwg_RmBlTabs(xLine)
           ENDIF  && lrembltab
         RETURN {xLine,.T.,nnumbytes,ceoltype}
        ELSE
         RETURN {"",.T.,0,ceoltype}
        ENDIF
       ENDIF
       * Detect MacOS: First appearance of CR alone
        IF ( .NOT. bMacOS ) .AND. ( buffer == CHR(13) )
       * End of line reached ?
         bEOL := .T.
         * Pre read (2nd read sequence)
          nnumbytes2 := FREAD(nhandle,@buffer2,1)  && Read 1 byte
         IF nnumbytes2 < 1
          * Optional last line with line ending
          IF .NOT. EMPTY(xLine)
                xLine := hwg_RmCr(xLine)
                * Remove SUB 0x1A = CHR(26)  && EOF marker
                xLine := STRTRAN(xLine,CHR(26),"")
                IF lrembltab
                   * Remove blanks or tabs at end of line
                   xLine := hwg_RmBlTabs(xLine)
                ENDIF
                RETURN {xLine,.F.,nnumbytes2,ceoltype}
          ELSE
                RETURN {"",.T.,0,ceoltype}
          ENDIF
         ENDIF
         * Line ending for Windows: must be LF (continue reading)
         * Before this, CR CHR(13) is read, but ignored
          IF .NOT. ( buffer2 == CHR(10) )
            * Windows : ignore read character
            bMacOS := .T.
            ceoltype := "M"
            * Set file pointer one byte backwards (is first character of following line)
            FSEEK (nhandle, -1 , 1 )
          ELSE
           ceoltype := "W"
          ENDIF
       ELSE
         * UNIX / LINUX (only LF)
          IF buffer == CHR(10)
           bEOL := .T.
           ceoltype := "L"
           * Ignore EOL character
           buffer := ""
          ENDIF
       ENDIF
        * Otherwise complete the line
        xLine := xLine + buffer

      * Successful read

      * Prefill buffer for next read
       buffer := " "

ENDDO

    IF EMPTY(xLine)
     RETURN {"",.T.,0,ceoltype}
//     RETURN {"",lbeof,0,ceoltype}
    ENDIF

    * Remove CR line ending
    * (if the returned line ended with MacOS line ending
    * CR , so you need to handle this)
     xLine := hwg_RmCr(xLine)
     * Remove SUB 0x1A = CHR(26)  && EOF marker
     xLine := STRTRAN(xLine,CHR(26),"")

     IF lrembltab
     * Remove blanks or tabs at end of line
       xLine := hwg_RmBlTabs(xLine)
     ENDIF

* Compose final return array
   AADD(xarray, xLine)
   AADD(xarray, .F.)
   //   AADD(xarray, lbeof)
   AADD(xarray, hwg_Max(nnumbytes, nnumbytes2) )
   AADD(xarray, ceoltype)
RETURN xarray



FUNCTION hwg_RmCr(xLine)

LOCAL nllinelen , czl
IF xLine == NIL
 xLine := ""
ENDIF
czl := xLine
nllinelen := LEN(xLine)
IF nllinelen > 0
 IF SUBSTR( xLine , nllinelen , 1) == CHR(13)
    czl := SUBSTR(xLine , 1 , nllinelen - 1 )
 ENDIF
ENDIF
RETURN czl


FUNCTION hwg_RmBlTabs(xLine)

LOCAL npos, lendf

IF xLine == NIL
 xLine := ""
ENDIF

* Remove blanks
 lendf := .F.
 DO WHILE .NOT. lendf
  npos := LEN(xLine)
  IF SUBSTR(xLine,npos,1) == " "
      xLine := SUBSTR(xLine,1,npos - 1)
  ELSE
   lendf := .T.
  ENDIF
 ENDDO
* Remove tabs
 lendf := .F.
 DO WHILE .NOT. lendf
   npos := LEN(xLine)
  IF SUBSTR(xLine,npos,1) == CHR(26)
   xLine := SUBSTR(xLine,1,npos - 1)
  ELSE
   lendf := .T.
  ENDIF
 ENDDO

RETURN xLine

FUNCTION hwg_Max(a,b)
IF a >= b
 RETURN a
ENDIF
RETURN b


FUNCTION hwg_Min(a,b)
IF a <= b
 RETURN a
ENDIF
RETURN b


FUNCTION hwg_IsLeapYear ( nyear )

   * nyear : a year to check for leap year
   * returns:
   * .T. a leap year
   * ================================= *
   RETURN ( ( (nyear % 4)  == 0 );
       .AND. ( ( nyear % 100 ) != 0 ) ;
       .OR.  ( ( nyear % 400 ) == 0 ) )

FUNCTION hwg_isWindows()

#ifndef __PLATFORM__WINDOWS
   RETURN .F.
#else
   RETURN .T.
#endif

FUNCTION hwg_CompleteFullPath( cPath )

   LOCAL  cDirSep := hwg_GetDirSep()

   IF RIGHT(cPath , 1 ) != cDirSep
      cPath := cPath + cDirSep
   ENDIF

   RETURN cPath

FUNCTION hwg_CreateTempfileName( cPrefix , cSuffix )

   LOCAL cPre , cSuff

   cPre  := IIF( cPrefix == NIL , "e" , cPrefix )
   cSuff := IIF( cSuffix == NIL , ".tmp" , cSuffix )

   RETURN hwg_CompleteFullPath( hwg_GetTempDir() ) + cPre + Ltrim(Str(Int(Seconds()*100))) + cSuff

FUNCTION hwg_CurDrive()

#ifdef __PLATFORM__WINDOWS
   RETURN hb_CurDrive() + ":\"
#else
   RETURN ""
#endif

FUNCTION hwg_CurDir()

#ifdef __PLATFORM__WINDOWS
   RETURN hwg_CurDrive() + CurDir()
#else
   RETURN "/" + CurDir()
#endif

FUNCTION hwg_GetUTCDateANSI

   * Format: YYYYMMDD, based on UTC

   RETURN SUBSTR(hwg_GetUTCTimeDate(), 3 , 8 )

FUNCTION hwg_GetUTCTime

   * Format: HH:MM:SS

   RETURN SUBSTR(hwg_GetUTCTimeDate(), 12 , 8 )

FUNCTION hwg_cHex2Bin (chexstr,cdebug)

   * Converts a hex string to binary
   * Returns empty string, if error
   * or number of hex characters is
   * odd.
   * chexstr:
   * Valid characters:
   * 0 ... 9 , A ... F , a ... f
   * Other characters are ignored.
   * cdebug : Set a string for debug.
   * The string appears at the beginning
   * of the logfile.
   * ================================= *

   LOCAL cbin, ncount, chs, lpos, nvalu, nvalue , nodd
   * lpos : F = MSB , T = LSB
   LOCAL ldebug

   IF cdebug == NIL
      ldebug := .F.
   ELSE
      ldebug := .T.
      hwg_xvalLog(cdebug)
   ENDIF
   cbin := ""
   lpos := .T.
   nvalue := 0
   nodd := 0
   IF (chexstr == NIL)
      RETURN ""
   ENDIF
   chexstr := UPPER(chexstr)
   IF ldebug
      hwg_xvalLog(chexstr)
   ENDIF
   FOR ncount := 1 TO LEN(chexstr)
      chs := SUBSTR(chexstr, ncount, 1 )
      IF chs $ "0123456789ABCDEF"
         nodd := nodd + 1  && Count valid chars for odd/even check
         DO CASE
         CASE chs == "0" ; nvalu := 0
         CASE chs == "1" ; nvalu := 1
         CASE chs == "2" ; nvalu := 2
         CASE chs == "3" ; nvalu := 3
         CASE chs == "4" ; nvalu := 4
         CASE chs == "5" ; nvalu := 5
         CASE chs == "6" ; nvalu := 6
         CASE chs == "7" ; nvalu := 7
         CASE chs == "8" ; nvalu := 8
         CASE chs == "9" ; nvalu := 9
         CASE chs == "A" ; nvalu := 10
         CASE chs == "B" ; nvalu := 11
         CASE chs == "C" ; nvalu := 12
         CASE chs == "D" ; nvalu := 13
         CASE chs == "E" ; nvalu := 14
         CASE chs == "F" ; nvalu := 15
         ENDCASE
         IF lpos
            * MSB
            nvalue := nvalu * 16
            lpos := .F.  && Toggle MSB/LSB
         ELSE
            * LSB
            nvalue := nvalue + nvalu
            lpos := .T.
            cbin := cbin + CHR(nvalue)
            * nvalue := 0
         ENDIF
      ENDIF  && IF 0..9,A..F
   NEXT
   * if odd, return error
   IF ( nodd % 2 ) != 0
      RETURN ""
   ENDIF
   IF ldebug
      hwg_xvalLog(cbin)
   ENDIF

   RETURN cbin

FUNCTION hwg_HEX_DUMP ( cinfield, npmode, cpVarName )

* Hex dump from a C field (binary)
* into C field (Character type).
* In general,
* every byte value (2 hex digits)
* separated by a blank.
*
* npmode:
* Selects the output format.
* 0 : All hex values in one line,
*     without quotes and trailing EOL.
* 1 : 16 bytes per line,
*     with display of printable
*     characters,
*     not inserted in quotes,
*     but columns with printable
*     characters are separated with
*     ">> " in every line.
* 2 : As variable definition
*     for copy and paste into prg source
*     code file, 16 bytes per line,
*     concatenated by "+ ;"
*     (Default)
* 3 : 16 bytes per line, only hex output,
*     no quotes or other characters.
* 4 : Like 0, but without blank
*     between the hex values.
*     Used by Binary Large Objects (BLOBs)
*     stored in memo fields of a DBF.
*     See program utils\bincnt\bindbf.prg
* 5:  As C notation array,
*     16 bytes per line, 0x..
*     written in {}
*     Add before generated block (for example):
*     const unsigned char sample[] =
*
* cpVarName:
* Only used, if npmode = 2.
* Preset for variable name,
* Default is "cVar".
* For other modes, this parameter
* is ignored.
*
* Sample writing hex dump to text file
* MEMOWRIT("hexdump.txt",HEX_DUMP(varbuf))
* ================================= *

   LOCAL nlength, coutfield,  nindexcnt , cccchar, nccchar, ccchex, nlinepos, cccprint, ;
      cccprline, ccchexline, nmode , cVarName , ncomma

   IF npmode == NIL
      nmode := 2
   ELSE
      nmode := npmode
   ENDIF
   IF cpVarName == NIL
      cVarName := "cVar"
   ELSE
      cVarName := cpVarName
   ENDIF
   * Check for valid mode
   IF (nmode < 1 ) .OR. (nmode > 6 )
      RETURN ""
   ENDIF
   * get length of field to be dumped
   nlength := LEN(cinfield)
   * if empty, nothing to dump
   IF nlength == 0
      RETURN ""
   ENDIF
   nlinepos := 0
   IF nmode == 2
      coutfield := cVarName + " := " + CHR(34)  && collects out line, start with variable name
   ELSE
      IF nmode == 5
         coutfield := "{"
      ELSE
         coutfield := ""  && collects out line
      ENDIF
   ENDIF
   // cccprint := ""   && collects printable char
   cccprline := ""  && collects printable chars
   ccchexline := "" && collects hex chars
   * loop over every byte in field
   FOR nindexcnt := 1 TO nlength
      nlinepos := nlinepos + 1
      * extract single character to convert
      cccchar := SUBSTR(cinfield,nindexcnt,1)
      * convert single character to number
      nccchar := ASC(cccchar)
      * is printable character below 0x80 (pure ASCII)
      IF (nccchar > 31) .AND. (nccchar < 128)
         IF nccchar == 32
            * space represented by underline
            cccprint := "_"
         ELSE
            cccprint := cccchar
         ENDIF
      ELSE
         * other characters represented by "."
         cccprint := "."
      ENDIF
      * convert single character to hex
      ccchex  := hwg_NUMB2HEX(nccchar)
      * collect hex and printable chars in outline
      IF nmode == 4
         cccprline := cccprline + cccprint
         ccchexline := ccchexline + ccchex
      ELSE
         IF nmode == 5
            cccprline := cccprline + cccprint + " "
            ccchexline := ccchexline + "0x" + ccchex + ","
         ELSE
            * Add a blank between a hex value pair
            cccprline := cccprline + cccprint + " "
            ccchexline := ccchexline + ccchex + " "
         ENDIF
      ENDIF
      * end of line with 16 bytes reached
      IF nlinepos > 15
         * create new line
         *
         DO CASE
         CASE nmode == 0
            coutfield := coutfield + ccchexline
         CASE nmode == 1
            coutfield := coutfield + ccchexline + ">> " +  cccprline + hwg_EOLStyle()
         CASE nmode == 2
            coutfield := coutfield + ccchexline + CHR(34) + " + ;" + hwg_EOLStyle()
         CASE nmode == 3
            coutfield := coutfield + ccchexline + hwg_EOLStyle()
         CASE nmode == 4
            coutfield := coutfield + ccchexline
         CASE nmode == 5
            coutfield := coutfield + ccchexline + hwg_EOLStyle()
         ENDCASE

         * ready for new line
         nlinepos := 0
         cccprline := ""
         IF nmode == 2
            ccchexline := CHR(34) && start new line with double quote
         ELSE
            ccchexline := ""
         ENDIF
      ENDIF
   NEXT
   * complete as last line, if rest of recent line existing
   * HEX line 16 * 3 = 48
   * line with printable chars: 16 * 2 = 32
   IF  .NOT. EMPTY(ccchexline)  && nlinepos < 16
      DO CASE
      CASE nmode == 0
         coutfield := coutfield + ccchexline
      CASE nmode == 1
         coutfield := coutfield + PADR(ccchexline,48) + ">> " +  PADR(cccprline,32) + hwg_EOLStyle()
      CASE nmode == 2
         coutfield := coutfield + ccchexline + CHR(34) +  hwg_EOLStyle()
      CASE nmode == 3
         coutfield := coutfield + ccchexline + hwg_EOLStyle()
      CASE nmode == 4
         coutfield := coutfield + ccchexline
      CASE nmode == 5
         * Remove "," at end of last line
         ncomma := RAT(",",ccchexline)
         ccchexline := IIF(ncomma > 0 , SUBSTR(ccchexline, 1, ncomma - 1) , ccchexline )
         coutfield := coutfield + ccchexline + "}" + hwg_EOLStyle()
      ENDCASE
   ENDIF

   RETURN coutfield

FUNCTION hwg_NUMB2HEX (nascchar)

* Converts
* 0 ... 255 TO HEX 00 ... FF
* (2 Bytes String)
* ================================= *

   LOCAL chexchars := ;
      {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}

   LOCAL n1, n2

   * Range 0 ... 255
   IF nascchar > 255
      RETURN "  "
   ENDIF
   IF nascchar < 0
      RETURN "  "
   ENDIF
   * split bytes
   * MSB: n1, LSB: n2
   n1 := nascchar / 16
   n2 := nascchar % 16
   * combine return value

   RETURN chexchars[ n1 + 1 ] + chexchars[ n2 + 1 ]

FUNCTION hwg_EOLStyle()

   * Returns the "End Of Line" (EOL) character(s)
   * OS dependent.
   * Windows: 0D0A (CRLF)
   * LINUX:   0A (LF)
   * This function works also on
   * GTK cross development environment.
   * MacOS:   0D (CR).
   * ================================= *

#ifdef __PLATFORM__WINDOWS
   RETURN CHR(13) + CHR(10)
#else
#ifdef ___MACOSX___
* MacOS
   RETURN CHR(13)
#else
   * LINUX and other UNIX'e (Free BSD, ...)
   RETURN CHR(10)
#endif
#endif

FUNCTION hwg_BaseName ( pFullpath )

   LOCAL nPosifilna , cFilename , cseparator

   * avoid crash
   IF PCOUNT() == 0
      RETURN ""
   ENDIF
   IF EMPTY(pFullpath)
      RETURN ""
   ENDIF

   cseparator := hwg_GetDirSep()
   * Search separator backwards
   nPosifilna = RAT(cseparator,pFullpath)

   IF nPosifilna == 0
      * Only filename
      cFilename := pFullpath
   ELSE
      cFilename := SUBSTR(pFullpath , nPosifilna + 1)
   ENDIF

   RETURN ALLTRIM(cFilename)

FUNCTION hwg_Dirname ( pFullpath )

   LOCAL nPosidirna , sFilePath , cseparator , sFullpath

   * avoid crash
   IF PCOUNT() == 0
      RETURN ""
   ENDIF
   IF EMPTY(pFullpath)
      RETURN ""
   ENDIF

   cseparator := hwg_GetDirSep()
   *  Reduce \\ to \  or // to /
   sFullpath := ALLTRIM(hwg_CleanPathname(pFullpath))

   * Search separator backwards
   nPosidirna := RAT(cseparator,sFullpath)

   IF nPosidirna == 1
      * Special case:  /name  or  \name
      *   is "root" ==> directory separator
      sFilePath := cseparator
   ELSE
      IF nPosidirna != 0
         sFilePath := SUBSTR(sFullpath,1,nPosidirna - 1)
      ELSE
         * Special case:
         * recent directory (only filename)
         * or only drive letter
         * for example C:name
         * ==> set directory with "cd".
         IF SUBSTR(sFullpath,2,1) == ":"
            * Only drive letter with ":" (for example C: )
            sFilePath := SUBSTR(sFullpath,1,2)
         ELSE
            sFilePath = "."
         ENDIF
      ENDIF
   ENDIF

   RETURN sFilePath

FUNCTION hwg_CleanPathname ( pSwithdbl )

   LOCAL sSwithdbl , bready , cseparator

   * avoid crash
   IF PCOUNT() == 0
      RETURN ""
   ENDIF
   IF EMPTY(pSwithdbl)
      RETURN ""
   ENDIF
   cseparator = hwg_GetDirSep()
   bready := .F.
   sSwithdbl = ALLTRIM(pSwithdbl)
   DO WHILE .NOT. bready
      * Loop until
      * multi separators (for example "///") are reduced to "/"
      sSwithdbl := STRTRAN(sSwithdbl , cseparator + cseparator , cseparator)
      * Done, if // does not apear any more
      IF AT(cseparator + cseparator, sSwithdbl) == 0
         bready := .T.
      ENDIF
   ENDDO

   RETURN sSwithdbl

FUNCTION hwg_Array_Len(ato_check)

   IF ato_check == NIL
      RETURN 0
   ENDIF

   RETURN IIF(EMPTY(ato_check), 0 , LEN(ato_check)  )

FUNCTION hwg_MemoEdit(mpmemo , cTextTitME , cTextSave ,  cTextClose , ;
   cTTSave , cTTClose , oHCfont )

   LOCAL mvarbuff , varbuf , oModDlg , oEdit , owb1 , owb2 , bMemoMod

   IF mpmemo == Nil
      mpmemo := ""
   ENDIF

   IF cTextTitME == NIL
      cTextTitME := "Memo Edit"
   ENDIF

   IF cTextSave == NIL
      cTextSave := "Save"
   ENDIF

   IF cTextClose == NIL
      cTextClose := "Close"
   ENDIF

   IF cTTSave == NIL
      cTTSave := "Save modifications and close"
   ENDIF

   IF cTTClose == NIL
      cTTClose := "Close without saving modifications"
   ENDIF

   mvarbuff := mpmemo
   varbuf   := mpmemo

   INIT DIALOG oModDlg title cTextTitME AT 0, 0 SIZE 400, 300 ON INIT { |o|o:center() }

   IF oHCfont == NIL
      @ 10, 10 HCEDIT oEdit SIZE oModDlg:nWidth - 20, 240
   ELSE
      @ 10, 10 HCEDIT oEdit SIZE oModDlg:nWidth - 20, 240 ;
         FONT  oHCfont
   ENDIF

   @ 10, 252  ownerbutton owb2 TEXT cTextSave size 80, 24 ;
      ON Click { || mvarbuff := oEdit , omoddlg:Close(), oModDlg:lResult := .T. } ;
      TOOLTIP cTTSave
   @ 100, 252 ownerbutton owb1 TEXT cTextClose size 80, 24 ON CLICK { ||oModDlg:close() } ;
      TOOLTIP cTTClose

   oEdit:SetText(mvarbuff)

   ACTIVATE DIALOG oModDlg

   * is modified ? (.T.)
   bMemoMod := oEdit:lUpdated
   IF bMemoMod
   * write out edited memo field
     varbuf := oEdit:GetText()
   ENDIF

   RETURN varbuf

* ~~~~~~~~~~~~~~~~~~~~~~~~
* === Unit conversions ===
* ~~~~~~~~~~~~~~~~~~~~~~~~

* ===== Temperature conversions ==============

FUNCTION hwg_TEMP_C2F( T )

   RETURN (T * 1.8) + 32.0

FUNCTION hwg_TEMP_C2K( T )

   RETURN T + 273.15

FUNCTION hwg_TEMP_C2RA( T )

   RETURN (T * 1.8) + 32.0 + 459.67

FUNCTION hwg_TEMP_C2R( T )

   RETURN T * 0.8

FUNCTION hwg_TEMP_K2C( T )

   RETURN T - 273.15

FUNCTION hwg_TEMP_K2F( T )

   RETURN (T * 1.8) - 459.67

FUNCTION hwg_TEMP_K2RA( T )

   RETURN T * 1.8

FUNCTION hwg_TEMP_K2R( T )

   RETURN ( T - 273.15 ) * 0.8

FUNCTION hwg_TEMP_F2C( T )

   RETURN ( T - 32.0) / 1.8

FUNCTION hwg_TEMP_F2K( T )

   RETURN ( T + 459.67) / 1.8

FUNCTION hwg_TEMP_F2RA( T )

   RETURN T + 459.67

FUNCTION hwg_TEMP_F2R( T )

   RETURN ( T - 32.0 ) / 2.25

FUNCTION hwg_TEMP_RA2C( T )

   RETURN ( T - 32.0 - 459.67) / 1.8

FUNCTION hwg_TEMP_RA2F( T )

   RETURN  T - 459.67

FUNCTION hwg_TEMP_RA2K( T )

   RETURN T / 1.8

FUNCTION hwg_TEMP_RA2R( T )

   RETURN ( T - 32.0 -459.67 ) / 2.25

FUNCTION hwg_TEMP_R2C( T )

   RETURN T * 1.25

FUNCTION hwg_TEMP_R2F( T )

   RETURN ( T * 2.25 ) + 32.0

FUNCTION hwg_TEMP_R2K( T )

   RETURN ( T * 1.25 ) + 273.15

FUNCTION hwg_TEMP_R2RA( T )

   RETURN ( T * 2.25 ) + 32.0 + 459.67

* ===== End of temperature conversions ==============

* ===== Other unit conversions =====================

* in / cm

FUNCTION hwg_INCH2CM( I )

   RETURN I * 2.54

FUNCTION hwg_CM2INCH( cm )

   RETURN cm * 0.3937

* feet / m

FUNCTION  hwg_FT2METER( ft )

   RETURN ft * 0.3048

FUNCTION hwg_METER2FT( m )

   RETURN m * 3.2808

* mile / km

FUNCTION hwg_MILES2KM( mi )

   RETURN mi * 1.6093

FUNCTION hwg_KM2MILES( km )

   RETURN  km * 0.6214

* sqin / sq cm

FUNCTION hwg_SQIN2SQCM( sqin )

   RETURN sqin * 6.4516

FUNCTION hwg_SQCM2SQIN( sqcm )

   RETURN sqcm * 0.155

* sqft / sq m

FUNCTION hwg_SQFT2SQM( sqft )

   RETURN sqft * 0.0929

FUNCTION hwg_SQM2SQFT( sqm )

   RETURN sqm * 10.7642

* usoz / c.c. (Cubic cm)

FUNCTION hwg_USOZ2CC( usoz )

   RETURN usoz * 29.574

FUNCTION hwg_CC2USOZ( cc )

   RETURN cc * 0.0338

* usgal / liter

FUNCTION hwg_USGAL2L( usgal )

   RETURN usgal * 3.7854

FUNCTION hwg_L2USGAL( l )

   RETURN l * 0.2642

* lb / kg

FUNCTION  hwg_LB2KG( lb )

   RETURN lb * 0.4536

FUNCTION hwg_KG2LB( kg )

   RETURN kg * 2.2046

* oz / g

FUNCTION hwg_OZ2GR( oz )

   RETURN oz * 28.35

FUNCTION hwg_GR2OZ( gr )

   RETURN gr * 0.0353

* Nautical mile / km

FUNCTION hwg_NML2KM(nml)

   RETURN nml * 1.852

FUNCTION hwg_KM2NML(km)

   RETURN km * 0.5399568034557235

* ===== End of unit conversions ==============

FUNCTION hwg_KEYESCCLDLG (odlg)

    odlg:Close()

   RETURN NIL

FUNCTION hwg_ShowHelp(cHelptxt,cTitle,cClose,opFont,blmodus)

   * Shows a help window
   * ================================= *

   LOCAL oDlg , oheget

   * T: not modal (default is .F.)
   IF blmodus == NIL
      blmodus := .F.
   ENDIF

   IF cTitle == NIL
      cTitle := "No title for help window"
   ENDIF

   IF cHelptxt == NIL
      cHelptxt := "No help available"
   ENDIF

   IF cClose == NIL
      cClose := "Close"
   ENDIF

   IF opFont == NIL
#ifdef __PLATFORM__WINDOWS
      PREPARE FONT opFont NAME "Courier" WIDTH 0 HEIGHT -16
#else
      PREPARE FONT opFont NAME "Sans" WIDTH 0 HEIGHT 12
#endif
   ENDIF

   INIT DIALOG oDlg TITLE cTitle ;
        AT 204,25 SIZE 777, 440 FONT opFont

   SET KEY 0,VK_ESCAPE TO hwg_KEYESCCLDLG(oDlg)
   @ 1,3 GET oheget VAR cHelptxt SIZE 772,384 NOBORDER ;
      STYLE WS_VSCROLL + ES_AUTOHSCROLL + ES_MULTILINE + ES_READONLY + WS_BORDER + ES_NOHIDESEL

   @ 322,402 BUTTON cClose SIZE 100,32 ;
      ON CLICK {||oDlg:Close() }

   IF blmodus
      ACTIVATE DIALOG oDlg NOMODAL
   ELSE
      ACTIVATE DIALOG oDlg
   ENDIF

   SET KEY 0,VK_ESCAPE TO

   RETURN NIL

FUNCTION hwg_PI()

   * high accuracy

   RETURN 3.141592653589793285

FUNCTION hwg_StrDebNIL(xParchk)

   LOCAL cres

   IF xParchk == NIL
      cres := "NIL"
   ELSE
      cres := "not NIL"
   ENDIF

   RETURN cres

FUNCTION hwg_StrDebLog(ltoCheck)

   LOCAL cres

   IF ltoCheck
      cres := ".T."
   ELSE
      cres := ".F."
   ENDIF

   RETURN cres

FUNCTION hwg_IsNIL(xpara)

   IF xpara == NIL
      RETURN .T.
   ENDIF

   RETURN .F.

FUNCTION hwg_MsgIsNIL(xpara,ctitle)

   * Sample call:
   * hwg_MsgIsNIL(hwg_Getactivewindow() )
   * Only for debugging
   * =======================================================

   LOCAL lrvalue

   lrvalue := hwg_Isnil( xpara )

   IF ctitle == NIL
      IF lrvalue
         hwg_MsgInfo("NIL")
      ELSE
         hwg_MsgInfo("NOT NIL")
      ENDIF
   ELSE
      IF lrvalue
         hwg_MsgInfo("NIL",ctitle)
      ELSE
         hwg_MsgInfo("NOT NIL",ctitle)
      ENDIF
   ENDIF

   RETURN lrvalue

FUNCTION hwg_DefaultFont()

* Returns an object with a suitable default font
* for Windows and LINUX
* =======================================================

   LOCAL oFont

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
   PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12
#endif

   RETURN oFont

FUNCTION hwg_deb_is_object(oObj)

   LOCAL lret

   IF Valtype(oObj) == "O" && Debug
      hwg_MsgInfo("Is object")
      lret := .T.
   ELSE
      hwg_MsgInfo("Is not an object")
      lret := .F.
   ENDIF

   RETURN lret

* Returns .T:, if oObj is a valid object
FUNCTION hwg_is_object(oObj)
LOCAL lret
  IF oObj == NIL
   RETURN .F.
  ENDIF
  lret := .F.
  IF Valtype(oObj) == "O"
     lret := .T.
  ENDIF
RETURN lret

* Returns a table of contents (TOC) of a bitmap object (name's)
FUNCTION hwg_bitmapTOC(oBitmap)

   LOCAL oBmp, aretu

   IF .NOT. hwg_is_object(oBitmap)
    RETURN {}
   ENDIF

   aretu := {}

   FOR EACH oBmp IN oBitmap:aBitmaps
      AADD(aretu,oBmp:name)
   NEXT

 RETURN aretu

FUNCTION BMPSize2Logfile(oBitmap,name)
LOCAL bhandle , aBmpSize, nWidth, nHeight, bmpnam, i

  IF .NOT. hwg_is_object(oBitmap)
    hwg_WriteLog("oBitmap is not an object")
    RETURN NIL
  ENDIF

  bhandle := NIL
  bmpnam  := "<none>"
  FOR EACH i  IN  oBitmap:aBitmaps
      IF i:name == name
         bhandle := i:handle
         bmpnam  := i:name
      ENDIF
   NEXT

   aBmpSize  := hwg_Getbitmapsize( bhandle )
   nWidth  := aBmpSize[ 1 ]
   nHeight := aBmpSize[ 2 ]

   hwg_WriteLog("name=" + bmpnam + " nWidth= " + ALLTRIM(STR(nWidth)) + ;
    " nHeight=" +  ALLTRIM(STR(nHeight)) )

 RETURN NIL

  * Only for debug purposes:
  * Write a single dimension array with c values into logfile
  FUNCTION hwg_Debug_logarrayC(acarray)
     LOCAL  nindiz
      FOR nindiz := 1 TO hwg_Array_Len(acarray)
        IF VALTYPE(acarray[nindiz]) == "C"
          hwg_WriteLog(ALLTRIM(STR(nindiz)) + ": " + acarray[nindiz] )
        ELSE
          hwg_WriteLog(ALLTRIM(STR(nindiz)) + ": " + "Element not of type C")
        ENDIF
      NEXT
   RETURN NIL

FUNCTION hwg_leading0(ce)

* ce : string
* Returns : String
* Replace all leading blanks with
* "0".
* =================================

   LOCAL vni , e1 , crvalue, lstop

   lstop := .F.

   e1 := ce
   IF LEN(e1) == 0
      RETURN ""
   ENDIF
   FOR vni := 1 TO LEN(ce)
      IF .NOT. lstop
         IF SUBSTR(e1,vni,1) == " "
            e1 := STUFF(e1,vni,1,"0")  && modify character at position vni to "0"
         ELSE
            lstop := .T.               && Stop search, if no blank appeared
         ENDIF
      ENDIF
   NEXT
   crvalue := e1

   RETURN crvalue

FUNCTION hwg_Bin2D(chex,nlen,ndec)

   // hwg_msginfo(chex)

   RETURN hwg_Bin2DC(SUBSTR(STRTRAN(SUBSTR(chex,1,23) ," ","") ,1,16) ,nlen,ndec)

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* Date and time functions
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FUNCTION hwg_checkANSIDate(cANSIDate)

* Check, if an ANSI Date is valid.
* cANSIDate: ANSI date as string
* of Format YYYYMMDD
*
* =================================

   LOCAL ddate, cdate

   IF cANSIDate == NIL
      RETURN .F.
   ENDIF
   cANSIDate := ALLTRIM(cANSIDate)
   IF EMPTY(cANSIDate)
      RETURN .F.
   ENDIF
   IF LEN(cANSIDate) <> 8
      RETURN .F.
   ENDIF
   ddate := hwg_STOD(cANSIDate)
   cdate := DTOC(ddate)
   * Invalid date is "  .  .  " , so ...
   cdate := STRTRAN(cdate," ","")
   cdate := STRTRAN(cdate,".","")
   IF EMPTY(cdate)
      RETURN .F.
   ENDIF

   RETURN .T.

FUNCTION hwg_Date2JulianDay(dDate,nhour,nminutes,nseconds)

   LOCAL nyear, nmonth, nday , ngreg

   IF nhour == NIL
      nhour     := 0
   ENDIF
   IF nminutes == NIL
      nminutes  := 0
   ENDIF
   IF nseconds == NIL
      nseconds  := 0
   ENDIF

   nyear  := YEAR(dDate)
   nmonth := MONTH(dDate)
   nday   := DAY(dDate)

   IF nmonth <= 2
      nmonth := nmonth + 12
      nyear :=  nyear - 1
   ENDIF

   ngreg :=  ( nyear / 400 ) - ( nyear / 100 ) + ( nyear / 4 )  && Gregorian calendar

   RETURN 2400000.5 + 365 * nyear - 679004 + ngreg ;
           + INT(30.6001 * ( nmonth + 1 )) + nday + ( nhour / 24 ) ;
           + ( nminutes / 1440 ) + ( nseconds / 86400 )


FUNCTION hwg_JulianDay2Date(z)

* Converts julian date of mem files into
* String , Format YYYYMMDD (ANSI)
* z: double (of type N)
* Returns string
* Valid for dates from 1901 to 2099
* The julian is stored in Clipper
* and Harbour MEM files as
* double value.
* =================================

   LOCAL njoff , nRound_4 , nFour , nYear , d , d1 , i , jz  , sz ,  k ,  cYear ,  cMonth , cday

   njoff := 4712                  && const year offset
   nFour := ( z + 13 ) / 1461     && 1461 = 3*365+366  period of 4 years  (valid 1901 ... 2099)
   nRound_4 := INT(nFour)
   nYear := nRound_4 * 4
   nRound_4 := (nRound_4 * 1461) - 13
   d  := z - nRound_4
   i  := 1
   d1 := 0
   DO WHILE (d1 >= 0) .AND. (i < 5)
      IF i == 1
         jz := 366
      ELSE
         jz := 365
      ENDIF
      d1 := d - jz
      IF d1 >= 0
         d := d1
         nYear := nYear + 1
      ENDIF
      i := i + 1
   ENDDO
   nYear := nYear - njoff
   cYear := STR( nYear , 4 , 0 )

   cYear := hwg_leading0(cYear)
   * Check for valid year range
   IF (nYear < 1901 ) .OR. (nYear > 2099)
      RETURN ""
   ENDIF

   d := d + 1;     && 0 .. 364 => 1 .. 365

   IF ( nYear % 4 ) == 0   && Leap year 1901 ... 2099
      sz := -1
   ELSE
      sz := 0
   ENDIF
   IF (sz = -1) .AND. (d = 60)
      * 29th February
      cMonth := "02"
      cday := "29"
    ELSE
      * All other days
      IF (d > 60) .AND. (sz == -1)
           d := d - 1
      ENDIF  && Correction Leap Year
      cMonth := "  "
      IF  d > 0
         cMonth := "01"
         k := 0
      ENDIF
      IF  d > 31
         cMonth := "02"
         k := 31
      ENDIF
      IF  d > 59
         cMonth := "03"
         k := 59
      ENDIF
      IF  d > 90
         cMonth := "04"
         k := 90
      ENDIF
      IF  d > 120
         cMonth := "05"
         k := 120
      ENDIF
      IF  d > 151
         cMonth := "06"
         k := 151
      ENDIF
      IF  d > 181
         cMonth := "07"
         k := 181
      ENDIF
      IF  d > 212
         cMonth := "08"
         k := 212
      ENDIF
      IF  d > 243
         cMonth := "09"
         k := 243
      ENDIF
      IF  d > 273
         cMonth := "10"
         k := 273
      ENDIF
      IF  d > 304
         cMonth := "11"
         k := 304
      ENDIF
      IF  d > 334
         cMonth := "12"
         k := 334
      ENDIF
      d := d - k
      cday := STR( d , 2 ,0 )
   ENDIF
   cday := hwg_leading0(cday)

   * Check for Errors
   * Could be for example "20991232".
   IF .NOT. hwg_checkANSIDate(cYear + cMonth + cday)
      RETURN ""
   ENDIF

   RETURN cYear + cMonth + cday


FUNCTION HWG_GET_TIME_SHIFT()

   LOCAL nhUTC , nhLocal

   nhUTC := VAL(SUBSTR(HWG_GETUTCTIMEDATE(),12,2  ))
   * Format: W,YYYYMMDD-HH:MM:SS
   nhLocal := VAL(SUBSTR(TIME(),1,2))

   RETURN nhLocal - nhUTC



FUNCTION hwg_addextens(cfilename,cext,lcs)

   LOCAL nposi , fna , ce

   IF cfilename == NIL
      cfilename := ""
   ENDIF
   IF cext == NIL
      RETURN cfilename
   ENDIF
   IF EMPTY(cext)
      RETURN cfilename
   ENDIF
   IF lcs == NIL
      lcs := .F.
   ENDIF
   fna := cfilename
   IF lcs
      cfilename := UPPER(cfilename)
      ce := "." + UPPER(cext)
   ELSE
      ce := "." + cext
   ENDIF
   nposi := RAT(ce,cfilename)
   IF nposi == 0
      fna := fna + "." + cext
   ENDIF

   RETURN fna

FUNCTION hwg_EuroUTF8()

   * 0xE2 + 0x82 + 0xAC

   RETURN CHR(226) + CHR(130) + CHR(172)

FUNCTION hwg_ValType(xxxx)

   * Returns the type of a variable or expression:
   * "A", "L", "N", "C" , "D", "O" , "U"

   LOCAL crtype

   IF xxxx == NIL
      crtype := "U"
   ELSE
      crtype := VALTYPE(xxxx)
   ENDIF

   RETURN crtype

FUNCTION hwg_xVal2C(xxx)

   * Convert the value of xxx to string, dependant
   * of type.
   * Helpful for debugging.

   LOCAL ctyp , cval

   ctyp := hwg_ValType(xxx)

   DO CASE
   CASE ctyp == "U"
      cval := "NIL"
   CASE ctyp == "A"
      cval := "<ARRAY>"
   CASE ctyp == "L"
      cval := IIF(xxx, ".T.",".F.")
   CASE ctyp == "N"
      cval := ALLTRIM(STR(xxx))
   CASE ctyp == "C"
      cval := xxx
   CASE ctyp == "D"
      cval := DTOS(xxx)
   CASE ctyp == "O"
      cval := "<OBJECT>"
   OTHERWISE
      cval := "<UNKNOWN>"
   ENDCASE

   RETURN cval

FUNCTION hwg_xvalMsg(xxx,cttype,cttval,cttitle)

   * Starts a messagebox to display a value of xxx

   IF cttype == NIL
      cttype := "Type : "
   ENDIF
   IF cttval == NIL
      cttval := "Value : "
   ENDIF
   IF cttitle == NIL
      cttitle := "Debug"
   ENDIF
   hwg_MsgInfo(cttype + hwg_ValType(xxx) + CHR(10) +  cttval + hwg_xVal2C(xxx) )

   RETURN NIL

FUNCTION hwg_xvalLog(xxx,cttype,cttval,cttitle,cfilename)

   * Writes a value of xxx into a log file
   IF cttype == NIL
      cttype := "Type : "
   ENDIF
   IF cttval == NIL
      cttval := "Value : "
   ENDIF
   IF cttitle == NIL
      cttitle := "Debug"
   ENDIF
   IF cfilename == NIL
      cfilename := "a.log"
   ENDIF
   hwg_WriteLog(cttype + hwg_ValType(xxx) + " " +  cttval + hwg_xVal2C(xxx), cfilename )

   RETURN NIL

FUNCTION hwg_ChangeCharInString(cinp,nposi,cval)

   LOCAL cout, i

   IF cinp == NIL
      RETURN ""
   ENDIF

   IF cval == NIL
      RETURN cinp
   ENDIF

   IF LEN(cval) <> 1
      RETURN cinp
   ENDIF

   IF nposi == NIL
      RETURN cinp
   ENDIF

   IF nposi > LEN(cinp)
      RETURN cinp
   ENDIF

   cout := ""

   FOR i := 1 TO LEN(cinp)
      IF i == nposi
         cout := cout + cval
      ELSE
         cout := cout + SUBSTR(cinp,i,1)
      ENDIF
   NEXT

   RETURN cout

FUNCTION hwg_hex2binchar(cchar)

   LOCAL cret , ipos , csingle, lpair, lignore

   cret := ""
   lpair := .F.
   cchar := UPPER(cchar)
   FOR ipos := 1 to LEN(cchar)
      lignore := .F.
      csingle := SUBSTR(cchar,ipos,1)
      DO CASE
      CASE csingle == "0" ; cret := cret + "0000 "
      CASE csingle == "1" ; cret := cret + "0001 "
      CASE csingle == "2" ; cret := cret + "0010 "
      CASE csingle == "3" ; cret := cret + "0011 "
      CASE csingle == "4" ; cret := cret + "0100 "
      CASE csingle == "5" ; cret := cret + "0101 "
      CASE csingle == "6" ; cret := cret + "0110 "
      CASE csingle == "7" ; cret := cret + "0111 "
      CASE csingle == "8" ; cret := cret + "1000 "
      CASE csingle == "9" ; cret := cret + "1001 "
      CASE csingle == "A" ; cret := cret + "1010 "
      CASE csingle == "B" ; cret := cret + "1011 "
      CASE csingle == "C" ; cret := cret + "1100 "
      CASE csingle == "D" ; cret := cret + "1101 "
      CASE csingle == "E" ; cret := cret + "1110 "
      CASE csingle == "F" ; cret := cret + "1111 "
      OTHERWISE
         lignore := .T.
      ENDCASE
      * Ignore invalid character
      IF .NOT. lignore
         IF lpair
            cret := cret + " "
         ENDIF
         * toggle for hex pair to add a space
         lpair := .NOT. lpair
      ENDIF
   NEXT

   RETURN cret

FUNCTION hwg_Toggle_HalfByte( cchar )

   LOCAL ci

   ci := ASC(SUBSTR(cchar,1,1))

   RETURN SUBSTR(CHR(hwg_Toggle_HalfByte_C(ci) ),1,1)

FUNCTION hwg_COUNT_CHAR(stri,such)

* Counts the appearance of string "such"
* in "stri".
* This function has a subset
* of parameters of the function
* AFTERATNUM() for better handling.

   LOCAL l,i,c,t

   l := LEN (stri)
   IF l == 0
      RETURN 0
   ENDIF
   IF LEN(such) == 0
      RETURN 0
   ENDIF
   c := 0
   t := stri
   DO WHILE .T.
      i := AT(such,t)
      IF i != 0
         c := c + 1
         t := SUBSTR(t,i+LEN(such))
      ELSE
         RETURN c
      ENDIF
   ENDDO

   RETURN 0


FUNCTION hwg_nothing(xpara)

   RETURN xpara

FUNCTION hwg_ProcFileExt(pFiname,pFiext,lupper,ctestdirsep)

   * Process file name extension:
   * Add file extension, if not available
   * or replace an existing extension.
   * pFiname : The filename to be processed (optional with full path)
   * pFiext  : The new file extension
   *           may be NIL or empty to remove a file extension
   * lupper  : Windows only (parameter ignored on UNIX/LINUX):
   *           Set to .T. , if extension is set to upper case
   *           .F. : preserve case (default)
   * ctestdirsep : Only for test purposes:
   * Modify the directory separator, default
   * is the return value of function hwg_GetDirSep(),
   * so it is assigned correct by the used operating system
   *
   * Sample call: hwg_ProcFileExt("TEST.TXT","PRG")
   * returns the value "TEST.PRG"
   * pFiname may contain a full path.
   * DOS, Windows and UNIX/LINUX/MacOS filenames
   * are supported.
   *

   LOCAL sfifullnam , sFiname , sFiext , nSlash , nPunkt && , nslashr

#ifndef __PLATFORM__WINDOWS
   HB_SYMBOL_UNUSED(lupper)
#endif

   IF pFiext == NIL
     pFiext := ""
   ENDIF

   IF lupper == NIL
      lupper := .F.
   ENDIF

   IF ctestdirsep == NIL
     ctestdirsep := hwg_GetDirSep()
   ELSE
     ctestdirsep := SUBSTR(ALLTRIM(ctestdirsep),1,1)
   ENDIF

   * Trim strings
   sFiext := ALLTRIM(pFiext)

   sFiname := ALLTRIM(hwg_CleanPathname( pFiname ))

#ifdef __PLATFORM__WINDOWS
   IF lupper
      sFiext := UPPER(sFiext)
   ENDIF
#endif
   * UNIX/LINUX : preserve case as passed
   * Attention !
   * Also path names may contain dots!
   nSlash := RAT(ctestdirsep,sFiname)
   nPunkt := RAT(".", sFiname )


  * Another special case:
  * /home/temp./test + "prg" ==> /home/temp./test.prg
  * Bugfix of 2024-10-03 by DF7BE, case 5 in demofunc.prg:
  * ==> /home/temp.prg
  * Need to set another directory separator (if tested on windows)!

   IF nPunkt == 0
      * Without extension: add extension
      IF EMPTY(sFiext)
       * Special case: no file extension to remove
       sfifullnam := sFiname
      ELSE
       sfifullnam := sFiname + "." + sFiext
      ENDIF
   ELSE
      IF nSlash > nPunkt
         * Special case:
         * Without extension, but dot in path name
         IF EMPTY(sFiext)
         * Special Case: There is no file extension to remove
         * (avoid to add a single dot)
           sfifullnam := sFiname
         ELSE
           sfifullnam := sFiname + "." + sFiext
         ENDIF
      ELSE
         IF nPunkt == 1
            * Special : hidden file in UNIX, for example .profile
            * so add extension
            sfifullnam := sFiname + "." + sFiext
         ELSE
             * The rest:
             * Cut existing extension
             sFiname := SUBSTR(sFiname,1,nPunkt - 1)
             * Check for removing
             IF EMPTY(sFiext)
               sfifullnam := sFiname
             ELSE
             * Add new extension
               sfifullnam := sFiname + "." + sFiext
             ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN sfifullnam

FUNCTION hwg_FBINREAD(cfilename,nbufsize)
LOCAL handle, cbuffer, coutput, anzbytes, zuende
// LOCAL nbyread   && Debug

IF cfilename == NIL
 RETURN ""
ENDIF

IF nbufsize == NIL
 nbufsize := 4096
ENDIF

zuende  := .F.
coutput := ""
// nbyread := 0   && Debug

 handle := FOPEN(cfilename,0)  && READ_ONLY / zum Lesen
 IF handle < 0
  * Cannot open file
  RETURN ""
 ENDIF

cbuffer := SPACE(nbufsize)

  DO WHILE .NOT. zuende
  anzbytes := FREAD(handle,@cbuffer,nbufsize)
//  nbyread := nbyread + anzbytes   && Debug
  IF anzbytes <> nbufsize
    zuende := .T.
  ENDIF
  * Collect data
  coutput := coutput + cbuffer
  * Clear buffer for next read
  cbuffer := SPACE(nbufsize)
  ENDDO
 FCLOSE(handle)
// hwg_MsgInfo("Bytes read=" +  ALLTRIM(STR(anzbytes)) )    && Debug
RETURN coutput

* FUNCTION HWG_QRENCODE() moved to contrib\qrencode\libqrencode.prg



FUNCTION hwg_CBmp2file(cbitmap,cbitmapfile)

  IF cbitmap == NIL
   RETURN NIL
  ENDIF

  IF cbitmapfile == NIL
   cbitmapfile := "bitmap.bmp"
  ENDIF

   MEMOWRIT( cbitmapfile, cbitmap )

RETURN NIL



FUNCTION hwg_bpmObj2String(obmp,cname)
LOCAL  cBitmap , cTmp

IF obmp == NIL
  RETURN NIL
ENDIF

IF cname == NIL
 RETURN NIL
ENDIF

* Processing steps:
* Save bitmap in a temporary file (extracted for bitmap object)
* and read it afterwards for return value
*

  cTmp := hwg_CreateTempfileName() + ".bmp"

  // hwg_Msginfo(cTmp)
  // hwg_Msginfo(cname)

  obmp:OBMP2FILE(cTmp,cname)

  cBitmap := MEMOREAD(cTmp)

  * And remove the EOF marker
   cBitmap := hwg_delEOFMarker(cBitmap)

RETURN cBitmap



FUNCTION hwg_Stretch_BMP_i(cbmp, clocname, nWidth, nHeight )

LOCAL cTmp, oBmp
#ifdef __PLATFORM__WINDOWS
 LOCAL ctempfilename
#endif

   IF cbmp == NIL
    RETURN ""
   ENDIF

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF

   IF clocname == NIL
     clocname := ""
   ENDIF


   * Do not resize, return original
   IF  (nWidth < 1) .OR. (nHeight) < 1
    RETURN cbmp
   ENDIF

* First write bitmap string into a temporary file
  cTmp := hwg_CreateTempfileName() + ".bmp"
  * The pure filename of the temporary file is stored as bitmap name,
  * so remove the directory path !
  * ==> not needed for LINUX !
#ifdef __PLATFORM__WINDOWS
  ctempfilename := hwg_BaseName(cTmp)
#endif
  IF .NOT. MEMOWRIT(cTmp,cbmp)
  * Returns .T., if success
   RETURN ""
  ENDIF

  * Create bitmap object by read the temporary file and resize it at loading
  *  AddFile( name, hDC, lTransparent, nWidth, nHeight )
  *  (hDC is not needed here, lTransparent is not available on GTK )
  * Some trouble in winprn.prg.
  * (See comment later)

  oBmp := HBitmap():AddFile(cTmp,,.F.,nWidth,nHeight)
  FErase( cTmp )


  // hwg_Writelog("clocname=" + clocname + " ctempfilename=" + ctempfilename)
  // hwg_BMPTOC2Logfile(oBmp)


  * Rename from temporary to previous name
#ifdef __PLATFORM__WINDOWS
  oBmp := hwg_BMPRename(oBmp,ctempfilename,clocname)
#else
  oBmp := hwg_BMPRename(oBmp,cTmp,clocname)
#endif

  // hwg_BMPTOC2Logfile(oBmp)

  * Extract string from bitmap
  * Bitmap object may contain more than one bitmap !
  * See sample program winprn.prg (compiled with QR code option):
  * 1: astro
  * 2: e4889615.tmp.bmp
  * After renaming:
  * 1: astro
  * 2: qrcode

   cbmp := hwg_bpmObj2String(oBmp,clocname)

RETURN cbmp


* ================================================================================


FUNCTION hwg_BMPRename(oBitmap,cnamold,cnamnew)

 LOCAL  i

 IF oBitmap == NIL
  RETURN NIL
 ENDIF

 IF cnamold == NIL
   RETURN NIL
 ENDIF

 IF cnamnew == NIL
   RETURN NIL
 ENDIF

  // Search for bitmap with old name in object
   FOR EACH i IN oBitmap:aBitmaps
      IF i:name == cnamold
        * Rename
        i:name := cnamnew
      ENDIF
   NEXT
 RETURN oBitmap


// Removes the EOF marker from a C string
// EOF marker 0x1a = CHR(26)

FUNCTION hwg_delEOFMarker(CBinrec)

LOCAL nlaenge
  IF CBinrec == NIL
    RETURN ""
  ENDIF
  nlaenge := LEN(CBinrec)
  IF nlaenge > 0
   IF SUBSTR(CBinrec,nlaenge,1) == CHR(26)
     * Remove the EOF marker
     CBinrec := SUBSTR(CBinrec,1,nlaenge - 1)
   ENDIF
  ENDIF
  RETURN CBinrec

FUNCTION hwg_BMPxyfromBinary(cbpm)

* BITMAPFILEHEADER (14 Byte) + BITMAPINFOHEADER (40 Byte) = 54 (0x36)
* 18 0x12 LONG int32_t 4 Bytes Width   x
* 22 0x16 LONG int32_t 4 Bytes Height  y
* Add 1, because index starts with 0 in C, so xpos= 19, ypos= 23

LOCAL nx, ny

IF cbpm == NIL
 RETURN {0,0}
ENDIF
* Check for header sizes
IF LEN(cbpm) < 54
 RETURN {0,0}
ENDIF
* Check for bitmap magic
IF .NOT. ( SUBSTR(cbpm,1,2) == "BM")
 RETURN {0,0}
ENDIF
* Get the values from header structure
nx := Bin2L(SUBSTR(cbpm,19,4))
ny := Bin2L(SUBSTR(cbpm,23,4))
* nx and ny may be negative, this is a "top-down" bitmap,
* the usual case is the bottom-up bitmap.

* Now return result array
RETURN { nx,ny }


FUNCTION hwg_BMPuniquename(cprefix)
 IF nuniquenr == NIL
   nuniquenr := 0
 ENDIF
 IF cprefix == NIL
   cprefix := "name"
 ENDIF
 nuniquenr := nuniquenr + 1
RETURN cprefix + ALLTRIM(STR(nuniquenr))

FUNCTION hwg_oBitmap2file(oBitmap,cbmpname,coutfilename )

IF oBitmap == NIL
// hwg_MsgInfo("oBitmap is NIL cbmpname=" + cbmpname )
 RETURN NIL
ENDIF

IF coutfilename == NIL
 coutfilename := "bitmap.bmp"
ENDIF

IF cbmpname == NIL
 cbmpname := ""
ENDIF

oBitmap:OBMP2FILE(coutfilename,cbmpname)
RETURN NIL

/*
Windows BITMAPINFOHEADER

Offset (hex)    Offset (dec)    Size (bytes)
12              18              4              the bitmap width in pixels (signed integer)
16              22              4              the bitmap height in pixels (signed integer)
*/

FUNCTION hwg_BMPTOC2Logfile(oBitmap)
     LOCAL atoc
     atoc :=  hwg_bitmapTOC(oBitmap)
     hwg_Debug_logarrayC(atoc)
RETURN NIL

* ======================= EOF of hmisccross.prg ===========================
