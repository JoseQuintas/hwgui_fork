*
* hb_qrencode.prg
*
*
* $Id$
*
* Sample program creating QR codes by Harbour console program
* (for example to create QR codes by bat or sh calls)
* using functions of HWGUI.
* 
*
* Compile with:
* hbmk2 hb_qrencode.hbp

#include "hbextcdp.ch"

FUNCTION MAIN(ctext,cbitmapfile,czoomf)

LOCAL nzoomf, cbmp

* Set "_DE858" to your language setting on Windows command line

REQUEST HB_CODEPAGE_DEWIN

REQUEST HB_CODEPAGE_DE858
REQUEST HB_CODEPAGE_UTF8

REQUEST HB_CODEPAGE_UTF8EX


  IF ( ctext == NIL ) .OR.  (cbitmapfile == NIL)
    ? "Usage: hb_qrencode <text convert to QR code> , "  + ;
     "<bitmap file name with QRcode, add extension " + CHR(34) + ".bmp" + CHR(34) + "> " + ;
     "[,<zoom factor>]"
    ? "Default value for zoom factor is 3"
    RETURN 1
  ENDIF 
  
  IF czoomf == NIL
   nzoomf := 3
  ELSE
   nzoomf := VAL(czoomf)
  ENDIF 
 
  // ? "Zoom factor is " , nzoomf

#ifdef __PLATFORM__WINDOWS
   * Convert to UTF-8
   * Set "DE858" to your language setting on Windows
//   MEMOWRIT("testout1.txt",ctext)   && Debug   
   ctext := HB_TRANSLATE(ctext, "DE858" , "UTF8")
//   MEMOWRIT("testout2.txt",ctext)   && Debug
#endif
 
 
  * Convert text to bitmap binary image as type C
  cbmp := HWG_QRENCODE(ctext,nzoomf)
  
  * Store to bitmap file
  hwg_CBmp2file(cbmp,cbitmapfile)

 QUIT

RETURN 0 



* =============== EOF of hb_qrencode.prg =========================
