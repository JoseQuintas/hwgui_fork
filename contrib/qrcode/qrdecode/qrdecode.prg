*
 * qrdecode.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *
 * Sample program for QR decoding and
 * converts its output to ext
 *
 * The decoding from camera to text is done
 * by external open source program
 * "Zbar"
 * https://sourceforge.net/projects/zbar 
 *
 * Copyright 2025 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/


    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No
    *  GTK/MacOS:  Yes

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow, oButton1, oButton2

   INIT WINDOW oMainWindow MAIN TITLE "Decoding QR code" AT 168,50 SIZE 250,150

   @ 20,50 BUTTON oButton1 CAPTION "Scan" ;
      ON CLICK { || Testen() } ;
      SIZE 80,32

   @ 120,50 BUTTON oButton2 CAPTION "Quit";
      ON CLICK { || oMainWindow:Close } ;
      SIZE 80,32

   ACTIVATE WINDOW oMainWindow

RETURN Nil


* Starts the external program "ZBar"
* and reads the output file to
* display the decoded QR-Code
* in a messagebox.

FUNCTION Testen()

LOCAL rc, outfilename, ccommand, dtueddel
LOCAL lEOF, arrrea, handle, couttext
LOCAL lnmodal
LOCAL lf := CHR(13) + CHR(10)

outfilename := "output.txt"
dtueddel := CHR(34)  && "


* Start the external app

couttext := ""

#ifdef __PLATFORM__WINDOWS
 lnmodal := .T.
  ccommand := dtueddel + "C:\Program Files (x86)\Zbar\bin\zbarcam.exe" + dtueddel
  rc := hwg_RunConsoleApp(ccommand,outfilename,.T.)
#else
#ifdef ___MACOSX___
 lnmodal := .F.
  ccommand := "./qrdecode_mac.sh 10"
  * Set execute permission
  hwg_RunConsoleApp("chmod 755 qrdecode_mac.sh")
  rc := hwg_RunConsoleApp(ccommand,outfilename)
#else
* All other LINUXe
 lnmodal := .F.
  ccommand := "~/local/bin/zbarcam"
  rc := hwg_RunConsoleApp(ccommand,outfilename)
#endif  
#endif

  * Now you can get the decoded text from output file 
  
 
  lEOF := .F.
  arrrea := {"",.F.,0,"U"}
  * Open the input text file
  handle := FOPEN(outfilename,0)
  * read the input file
  DO WHILE .NOT. lEOF
    arrrea := hwg_RdLn(handle)
    * Detect EOF
    IF arrrea[2]
     lEOF := .T.
    ELSE
     * collect all lines in a C Var
     couttext := couttext + arrrea[1] + lf
    ENDIF
  ENDDO
  FCLOSE(handle)
  
  hwg_ShowHelp(couttext,"Zbar scan",,,lnmodal)

RETURN Nil

* Table: List of types in output of ZBar 
* "EAN-2"
* "EAN-5"
* "EAN-8"
* "UPC-E"
* "ISBN-10"
* "UPC-A"
* "EAN-13"
* "ISBN-13"
* "COMPOSITE"
* "I2/5"
* "DataBar"
* "DataBar-Exp"
* "Codabar"
* "CODE-39"
* "CODE-93"
* "CODE-128"
* "PDF417"
* "QR-Code"
* "SQ-Code"
*
*    default:
* "UNKNOWN"


* ===================== EOF of qrdecode.prg ==================
