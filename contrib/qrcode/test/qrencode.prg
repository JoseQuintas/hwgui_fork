 *
 * qrencode.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *
 * Sample program for QR encoding and
 * converts its output to
 * monochrome bitmaps for multi platform usage.
 * The created bitmap with the QR code is displayed in
 * a extra windows and also written in file
 * "test.bmp"
 * and under construction:
 * "qr-code.bmp"
 *
 * Copyright 2025 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/


    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No
    *  MacOS    :  Yes


#include "hwgui.ch"
#include "hbextcdp.ch"

FUNCTION Main()

   LOCAL oMainWindow, oButton1, oButton2, oButton3


REQUEST HB_CODEPAGE_UTF8
REQUEST HB_CODEPAGE_UTF8EX

* Modify to your language setting on Windows
REQUEST HB_CODEPAGE_DEWIN


   INIT WINDOW oMainWindow MAIN TITLE "Creating QR code" AT 168,50 SIZE 350,150


  * First run
  * Testen()
  * Second run (optional)

   @ 20,50 BUTTON oButton1 CAPTION "Test" ;
      ON CLICK { || Testen() } ;
      SIZE 80,32


   @ 120,50 BUTTON oButton2 CAPTION "Enter Text" ;
      ON CLICK { || TextEnter() } ;
      SIZE 80,32

   @ 220,50 BUTTON oButton3 CAPTION "Quit";
      ON CLICK { || oMainWindow:Close } ;
      SIZE 80,32

   ACTIVATE WINDOW oMainWindow


RETURN Nil

* Ask for string to convert, zoom factor and
* store to bitmap file
* Convert to bitmap and show the qrcode,
* Store the QR code to bitmap file "test.bmp


FUNCTION Testen()

FIRST_RUN()
SECOND_RUN()
RETURN NIL



FUNCTION FIRST_RUN()

*
* All steps of generating a QR code from string
* are collected in one function:
*   HWG_QRENCODE(ctext,nzoomf)
   LOCAL  cbitmap // narrsize


   cbitmap  := HWG_QRENCODE("https://sourceforge.net/projects/hwgui/")

  hwg_msgInfo(STR(LEN(cbitmap)))

   // QR_Size_Disp(cbitmap)  && here 0,0

   // hwg_WriteLog( cbitmap )
   // cqrc := hwg_QRCodeZoom_C(cqrc,LEN(cqrc),3)

  * Store to bitmap file
   // MEMOWRIT( "test.bmp", cbitmap )
   hwg_CBmp2file(cbitmap,"test.bmp")

   * <under construction>
   // TO-DO: extend with conversion to bitmap object.
   // hwg_oBitmap2file(cbitmap,"qr-code.bmp")

   * And show the new bitmap image
   hwg_ShowBitmap( cbitmap, "hwgui", 0, hwg_ColorC2N( "080808" ) ) // Color = 526344

RETURN Nil

 FUNCTION QR_Size_Disp(cbitmap)
   * Get size of QR code and display it

   LOCAL narrsize

   narrsize := hwg_QRCodeGetSize(cbitmap)

   hwg_MsgInfo("x=" + ALLTRIM(STR(narrsize[1])) + " y=" +  ;
   ALLTRIM(STR(narrsize[2])),"Size of QR code")
RETURN NIL


FUNCTION SECOND_RUN()

   LOCAL cqrc, cbitmap

   // cqrc := hwg_QRCodeTxtGen("https://www.darc.de",1)

//   cqrc := hwg_QRCodeTxtGen( "https://sourceforge.net/projects/hwgui", 1 )

   cqrc := hwg_QRCodeTxtGen( "https://github.com/harbour/core")

   hwg_msgInfo(STR(LEN(cqrc)))

   cqrc := hwg_QRCodeZoom( cqrc, 3 )

   // cqrc := hwg_QRCodeZoom_C(cqrc,LEN(cqrc),3)


   * Add border
   cqrc := hwg_QRCodeAddBorder(cqrc,10)

   * Get size of QR code and display it
   // narrsize := hwg_QRCodeGetSize(cqrc)
   // Now in this function
    QR_Size_Disp(cqrc)

   // Size should be x=126 y=125

   // hwg_WriteLog( cqrc )

   * Finally convert QR code text image to bitmap binary image as type C
   cbitmap := hwg_QRCodetxt2BPM( cqrc )

   * Store to bitmap file
   MEMOWRIT( "secondrun.bmp", cbitmap )
   * Attention !
   * The MEMOWRIT() function add an EOF marker at end of file
   * 0x1a = CHR(26)

   * Display also the size (x,y) of bitamp vom binary image as type C
   QR_Size_Disp_Bin(cbitmap)

   * <under construction>
   // TO-DO: extend with conversion to bitmap object.
   // hwg_oBitmap2file(cbitmap,"qr-code.bmp")

   * And show the new bitmap image
   hwg_ShowBitmap( cbitmap, "harbour", 0, hwg_ColorC2N( "080808" ) ) // Color = 526344


//     hwg_CBmp2file(cbitmap,"secondrun.bmp")

RETURN NIL

FUNCTION QR_Size_Disp_Bin(cbitmap)
   * Get size of QR code and display it
   * from binary image
   LOCAL narrsize

   narrsize := hwg_BMPxyfromBinary(cbitmap)

   hwg_MsgInfo("x=" + ALLTRIM(STR(narrsize[1])) + " y=" +  ;
   ALLTRIM(STR(narrsize[2])),"Size of QR code")

RETURN NIL

FUNCTION TextEnter()
* Query text to convert to QR code
* Create QR code, display it and write bitmap to file.
LOCAL cqrcstri,cuniq

cuniq := hwg_BMPuniquename("freeqrcode")
cqrcstri := Enterlongstr()
IF EMPTY(cqrcstri)   && Cancel button pressed
 RETURN NIL
ENDIF

#ifdef __PLATFORM__WINDOWS
  * Comes in as WIN charset, need to convert to UTF8
    cqrcstri := HB_TRANSLATE(cqrcstri, "DEWIN" , "UTF8EX")
#endif
* On LINUX and MacOS UTF-8 supported by OS

QRENCODESHOW(cqrcstri,cuniq)

RETURN NIL


FUNCTION QRENCODESHOW(ctextqr,cbmpname)
* Encode passed text to QR code and display it
* with standard HWGUI function
* and write to bitmap file (fixed file name)

LOCAL cqr

cqr := HWG_QRENCODE(ctextqr)

hwg_ShowBitmap( cqr, cbmpname, 0 )
MEMOWRIT("qrcode.bmp",cqr)
hwg_MsgInfo("Generated QR code written to file qrcode.bmp","QR Code" )
RETURN NIL

FUNCTION Enterlongstr()
* Dialog enter long string

LOCAL frm_enterlongstr

LOCAL oLabel1, oLabel2, oEditbox1, oButton1, oButton2
//LOCAL oLabel3
LOCAL cprevstr , lAbbruch, nlaeng

lAbbruch := .T.
nlaeng := 60  && Max length to enter


 cprevstr := hwg_GET_Helper(SPACE(nlaeng),nlaeng)

  INIT DIALOG frm_enterlongstr TITLE "Enter Text for QR code" ;
    AT 250,166 SIZE 1104,288 NOEXIT;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 25,11 SAY oLabel1 CAPTION "Enter text for creating QR code"  SIZE 763,22
   @ 25,50 SAY oLabel2 CAPTION "Maximal " + ALLTRIM(STR(nlaeng)) + " characters: "  SIZE 763,22
   * Optional 3rd line
   // @ 25,90 SAY oLabel3 CAPTION "xxxx"  SIZE 763,22

   @ 25,129 GET oEditbox1 VAR cprevstr  SIZE 1032,24 ;
          STYLE WS_BORDER

   @ 30,170 BUTTON oButton1 CAPTION "OK"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| lAbbruch := .F. , frm_enterlongstr:Close() }
   @ 165,170 BUTTON oButton2 CAPTION "Cancel" SIZE 110,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
       ON CLICK {|| frm_enterlongstr:Close() }


   ACTIVATE DIALOG frm_enterlongstr

   IF  lAbbruch
     cprevstr := ""
   ENDIF


RETURN cprevstr



*  ================== EOF of qrencode.prg ======================
