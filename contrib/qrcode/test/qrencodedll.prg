
* qrencodedll.prg

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow, oButton1, oButton2

   INIT WINDOW oMainWindow MAIN TITLE "Creating QR code" AT 168,50 SIZE 250,150

   @ 20,50 BUTTON oButton1 CAPTION "Test" ;
      ON CLICK { || Testen() } ;
      SIZE 80,32

   @ 120,50 BUTTON oButton2 CAPTION "Quit" ;
      ON CLICK {|| oMainWindow:Close } ;
      SIZE 80,32

   ACTIVATE WINDOW oMainWindow

RETURN Nil

FUNCTION Testen()

   LOCAL cqrcode, ctempfile , cqrc , cbitmap

   ctempfile := hwg_CreateTempfileName( , ".bmp")

   CreateQRtoBMP( "https://sourceforge.net/projects/hwgui", ctempfile )

   cqrc = MEMOREAD(ctempfile)

   cqrc := hwg_QRCodeZoom(cqrc,2)

   cbitmap := hwg_QRCodetxt2BPM( cqrc )

   * And show the new bitmap image
   hwg_ShowBitmap( cbitmap, "test", 0, hwg_ColorC2N( "080808" ) )

   DELETE FILE &ctempfile

RETURN Nil

#ifdef __PLATFORM__WINDOWS
#require "hbxpp"

FUNCTION CreateQRtoBMP( cStr, cFile )

   LOCAL qrDLL

   cFile := IIF( HB_ISNIL( cFile ), hwg_CreateTempfileName( "QR", "*.bmp" ), cFile )
   qrDLL := DLLLoad( "qrcodegen.dll" )
   DllCall( qrDLL, 0x0000, "FastQRCode", cStr, cFile )
   DLLUnload( qrDLL )

RETURN cFile

#endif

* ==================== EOF of qrencodedll.prg  ========================
