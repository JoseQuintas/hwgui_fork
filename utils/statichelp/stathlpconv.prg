/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 * stathlpconv.prg - Utility convert help text
 * to HWGUI source code.
 *
 * Copyright 2023
 * Wilfried Brunken, DF7BE
 *
 * https://sourceforge.net/projects/hwgui/
 */
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes

#include "hwgui.ch"
#ifdef __GTK__
#include "gtk.ch"
#endif

* Define the number of maximal characters in an output line
#define MAXCHARSPERLINE 25

FUNCTION Main()

   LOCAL oWndMain

  INIT WINDOW oWndMain MAIN TITLE "Static help text converter" AT 200,100 SIZE 300,300

MENU OF oWndMain
      MENU TITLE "&File"
         MENUITEM "&Exit" ACTION oWndMain:Close()
      ENDMENU
      MENU TITLE "&Helptext"
         MENUITEM "&Convert"  ACTION ConvertHelp()
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION hwg_Msginfo("HWGUI Static help text converter" + Chr(10) + "2022" )
      ENDMENU
   ENDMENU

  ACTIVATE WINDOW oWndMain

RETURN NIL

FUNCTION ConvertHelp()

   LOCAL mypath, cdirsep, fname , ctext , cprgtext , cvarname , i
   LOCAL cfoutfile, ctemp, nchrcount , ninlen
   LOCAL lf := CHR(13) + CHR(10) , lfstr := "CHR(13) + CHR(10)"

   nchrcount := 0
   //cprgtext := ""

   cvarname  := "cHelptext1" + SPACE(20) && size = 30

   cvarname  := hwg_GET_Helper(cvarname,30)

   cdirsep := hwg_GetDirSep()

   mypath := cdirsep + CURDIR() + IIF( EMPTY( CURDIR() ), "", cdirsep )

   fname := hwg_Selectfile( "Text files( *.txt )", "*.txt", mypath )

    IF Empty( fname )
     RETURN NIL
    ENDIF

    IF .NOT. FILE(fname)
     RETURN NIL
    ENDIF

    * Modify file extension to .prg

    cfoutfile := hwg_ProcFileExt(fname,"prg")

    * Ask for variable name (into cvarname)

    cvarname := GetCValue(cvarname,"HWGUI Static help text converter", ;
     "Enter variable name:",,.F.)

    cprgtext := ALLTRIM(cvarname) + " := ;" + lf + CHR(34)

    ctext := MEMOREAD(fname)
    * Interpret the input file contents
    * and collect the new contents into cprgtext.
    * Handle special characters:
    * LF : CHR(10)
    * For output use variables "lf" and "lfstr"
    * "  : CHR(34)
    * '  : CHR(39)
    ninlen := LEN(ctext)
    FOR i := 1 TO ninlen
      ctemp := SUBSTR(ctext,i,1)
      DO CASE
       CASE ctemp == CHR(10) && LF  Force a new prg line
        cprgtext := cprgtext + CHR(34) + " + " + lfstr + " + ;" + lf + CHR(34)
        nchrcount := 0
       CASE ctemp == CHR(34) && "
        cprgtext := cprgtext + CHR(34) + " + CHR(34) + " + CHR(34)
        nchrcount++
        IF nchrcount > MAXCHARSPERLINE
         * Force a new prg line
         cprgtext := cprgtext + " ;" + lf + CHR(34)
         nchrcount := 0
        ENDIF
       CASE ctemp == CHR(39) && '
        cprgtext := cprgtext + CHR(34) + " + CHR(39) + " + CHR(34)
        nchrcount++
        IF nchrcount > MAXCHARSPERLINE
         * Force a new prg line
         cprgtext := cprgtext + " ;" + CHR(34)
         nchrcount := 0
        ENDIF
       OTHERWISE
        cprgtext := cprgtext + ctemp
        nchrcount++
        IF nchrcount > MAXCHARSPERLINE
        * Force a new prg line
         cprgtext := cprgtext  + CHR(34) + " +  ; " + lf + CHR(34)
         nchrcount := 0
        ENDIF
       ENDCASE
    NEXT

    * Handle end of file
    IF SUBSTR(ctext,ninlen,1) != CHR(34)
     cprgtext := cprgtext  + CHR(34)
    ENDIF
    * Reduce "+ "" +" to " + "
    cprgtext := STRTRAN(cprgtext,"+ " + CHR(34) + CHR(34) + " +"," + ")
    IF  MEMOWRIT(cfoutfile,cprgtext)
    hwg_MsgInfo("File " + cfoutfile + " written", ;
       "HWGUI Static help text converter")
    ELSE
     hwg_MsgStop("Error writing file " + cfoutfile, ;
       "HWGUI Static help text converter")
    ENDIF


RETURN NIL



FUNCTION GetCValue(cPreset,cTitle,cQuery,nlaenge,lcaval)
* An universal function for getting a C value
*
* lcaval  : if set to .T., old value is returned
*           .F. : empty string returned
*           Default is .T.
* nlaenge : Max length of string to get.
*           Default value is LEN(cPreset)
LOCAL _enterC, oLabel1, oEditbox1, oButton1 , oButton2 , cNewValue, lcancel

 IF cTitle == NIL
  cTitle := ""
 ENDIF

 IF cQuery == NIL
  cQuery := ""
 ENDIF

 IF cPreset == NIL
  cPreset := " "
 ENDIF

 IF lcaval == NIL
  lcaval := .T.
 ENDIF

 IF nlaenge == NIL
  nlaenge := LEN(cPreset)
 ELSE
  IF EMPTY(cpreset)
   cpreset := SPACE(nlaenge)
  ELSE
   cpreset := PADR(cpreset,nlaenge)
  ENDIF
 ENDIF

 lcancel := .T.

 cPreset := hwg_GET_Helper(cPreset, nlaenge )

 cNewValue := cPreset

 INIT DIALOG _enterC TITLE cTitle ;
    AT 315,231 SIZE 940,239 ;
    STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE
  @ 80,32 SAY oLabel1 CAPTION cQuery SIZE 587,22
   @ 80,71 GET oEditbox1 VAR cNewValue  SIZE 772,24 ;
        STYLE WS_BORDER
   @ 115,120 BUTTON oButton1 CAPTION "OK" SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| lcancel := .F. , _enterC:Close() }
   @ 809,120 BUTTON oButton2 CAPTION "Cancel" SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| _enterC:Close() }

   ACTIVATE DIALOG _enterC

   IF lcancel
    IF lcaval
     cNewValue := cPreset
    ELSE
          cNewValue := ""
    ENDIF
   ENDIF

RETURN cNewValue

* ====================== EOF of stathlpconv.prg ====================
