*
* libqrencode.prg
*
*
* $Id$
*
*
*
* HWGUI - Harbour Win32, LINUX and MacOS library source code:
* Collection of functions encoding QR codes.
* (if not implemented in other HWGUI modules)


* Copyright 2023 Alexander S.Kresin <alex@kresin.ru>
* www - http://www.kresin.ru
*
* Copyright 2025 Wilfried Brunken, DF7BE 
* https://sourceforge.net/projects/cllog/
*
* License:
* GNU General Public License V2.
* As a special exception, you have permission for
* additional uses of the text contained in its release of HWGUI.
*
* For Details, see file
* license.txt 
*

FUNCTION HWG_QRENCODE(ctext,nzoomf,nboarder)
* Important !
* ctext must be coded in UTF-8.

   LOCAL cqrc
   LOCAL cbitmap 
//   LOCAL narrsize      && For debug

  IF ( ctext == NIL )
   * nothing to do
    RETURN NIL
  ENDIF 
  
  IF nzoomf == NIL
     nzoomf := 3
  ENDIF
  
  IF nboarder == NIL
    nboarder := 10
  ENDIF  
  

   // cqrc := hwg_QRCodeTxtGen("https://www.darc.de",1)

   cqrc := hwg_QRCodeTxtGen( ctext, 1 )


   cqrc := hwg_QRCodeZoom( cqrc, nzoomf )


   
   * Add border 10 pixels
   cqrc := hwg_QRCodeAddBorder(cqrc,nboarder)
   
//   narrsize := hwg_QRCodeGetSize(cqrc)
//   hwg_MsgInfo("x=" + ALLTRIM(STR(narrsize[1])) + " y=" +  ;
//   ALLTRIM(STR(narrsize[2])),"Size of QR code")
  

   * Final creating of bitmap with QR code 
   cbitmap := hwg_QRCodetxt2BPM( cqrc )

RETURN cbitmap

* ================== EOF of libqrencode.prg  ==================