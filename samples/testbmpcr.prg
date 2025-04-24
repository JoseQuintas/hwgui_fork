#pragma -w1

 *
 * testbmpcr.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *
 * Sample program for creating monochrome bitmaps (W3.x)
 * with HWGUI functions for example for QR encoding.
 *
 * Copyright 2022 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/


    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow, oButton1, oButton2

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "Creating monochrome bitmap file" ;
      AT 168,50 ;
      SIZE 250,150

   @ 20,50 BUTTON oButton1 ;
      CAPTION "Test";
      ON CLICK {|| Testen()} ;
      SIZE 80,32

   @ 120,50 BUTTON oButton2 ;
      CAPTION "Quit";
      ON CLICK {|| oMainWindow:Close } ;
      SIZE 80,32

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

FUNCTION Testen()

   LOCAL CBMP , nfilesiz ,rc , lrc , cmsg , nx, ny && noffset
   LOCAL CBMP2 , cdirsep
   LOCAL ctest, ctemp
   LOCAL i, j , acircle

   // nx := 48
   // ny := 48

   nx := 122
   ny := 77

   cdirsep := hwg_GetDirSep()
   nfilesiz := HWG_BMPFILESIZE(48, 48, 1, 2)
   hwg_msgInfo("Filesize is " + ALLTRIM(STR(nfilesiz)) )

* Create the bitmap template string.
* This is the default for QR encoding (monochrome):
*
*                        (x) width
*                        !  (y) height
*                        !  !   bits per pixel
*                        !  !   !
*                        !  !   !  colors (2 = monochrome bitmap)
*                        !  !   !  !  x pixel per meter
*                        !  !   !  !  !
*                        !  !   !  !  !     y pixel per meter
*                        !  !   !  !  !     !
*                        v  v   v  v  v     v

   CBMP := HWG_BMPNEWIMAGE(nx, ny, 1, 2, 2835, 2835 )

* The x and y size can be modified by size of QR code.
*
* After creating the bitmap template string,
* free not used memory:

   HWG_BMPDESTROY()

// hwg_msgInfo("Size of pixel data is " + ALLTRIM(STR( hwg_BMPImageSize(nx, ny, 1) )) )

// noffset := hwg_BMPCalcOffsPixArr(2);

// hwg_msgInfo("Offset to pixel data is " + ALLTRIM(STR(noffset)), "Expected value: 62" )

* Set monochrome palette for QR encoding

   CBMP := hwg_BMPSetMonochromePalette(CBMP)

* Setting example pixels:

* Pixel data of image, index
* y , x
*
* y = 0 bottom, x = 0 left

* Some tests
* 0x101 = 257 + 1,  0x80 = 128

   CBMP := hwg_ChangeCharInString(CBMP,258,CHR(128) )  // center point for 48 x 48 at 24, 24

* Sample drawing a vertical stripe pattern
/*
FOR j = 1 TO nx
 FOR i = 1 to ny step 2
  CBMP := hwg_QR_SetPixel(CBMP,i,j,nx,ny)
 NEXT
NEXT
*/

* Draw pixels at edge positions
   CBMP := hwg_QR_SetPixel(CBMP,1,1,nx,ny)   && top left
   CBMP := hwg_QR_SetPixel(CBMP,nx,1,nx,ny)  && top right
   CBMP := hwg_QR_SetPixel(CBMP,nx,ny,nx,ny) && bottom right
   CBMP := hwg_QR_SetPixel(CBMP,1,ny,nx,ny)  && bottom left

* Draw a circle
   FOR i := 0 TO 360
      acircle := hwg_BMPDrawCircle(24,i)
      CBMP := hwg_QR_SetPixel(CBMP,acircle[1],acircle[2],nx,ny)
   NEXT

* Draw a line at bottom
// FOR i := 1 TO nx
//  CBMP := hwg_QR_SetPixel(CBMP,i,ny,nx,ny)
// NEXT

* Store to bitmap file

   MEMOWRIT("test.bmp",CBMP)

* EOF mark 0x1A = CHR(26) is added by MEMOWRIT,
* it seems, that this has no negative effect.

* And show the new bitmap image

   hwg_ShowBitmap(CBMP,"test",0,hwg_ColorC2N("080808") ) // Color = 526344

   CBMP2 := MEMOREAD(".." + cdirsep + "image" + cdirsep + "astro.bmp")
   hwg_ShowBitmap(CBMP2,"astro")

* Test for setting bits in a byte
// hwg_msgInfo(hwg_hex2binchar(hwg_HEX_DUMP(CHR(HWG_SETBITBYTE(0,8,1)), 4 ) ) )  && OK 0 to 1
// hwg_msgInfo(hwg_hex2binchar(hwg_HEX_DUMP(CHR(HWG_SETBITBYTE(255,8,0)), 4 ) ) ) && OK 1 to 0

// hwg_MsgInfo(hwg_hex2binchar(hwg_HEX_DUMP(hwg_Toggle_HalfByte(CHR(8) ) ),4 ) )  && 128 > 8

RETURN Nil

* ~~~~~~~~~~~~~~~~~~~~~~
* Additional information
* ~~~~~~~~~~~~~~~~~~~~~~

* Calculates the the pixel position in the
* pixel data jagged array at position x,y
* bases on the position in an created bitmap
* file image string created with function HWG_BMPNEWIMAGE().
* xw: width
* xh: heigth
* Pass these values same as HWG_BMPNEWIMAGE(x,y, ...)
* Returns an array with 2 numerical values:
* 1 : The position of the byte
* 2 : The position of bit to set in the byte of 1
*

* The bitmap starts at index 1 with bottom left
* y = 0 bottom, x = 0 left, so turn to
* y = 1 top,    x = 1 left
*
* The following chart bases on 48 x 48 pixels, monochrome
* !
* !
* v
* y
*
* ==> x
* 1       ......      48   ==> 8 bytes per line (for this sample)
*                          This is calculted with the function hwg_BMPLineSize()
* 1
* .
* .
* .
* .
* 48
*
* convert to
* ==>
*
* 1      ........     48
* 48
* .
* .
* .
* 1      ........     48




* ===================== EOF of testbmpcr.prg ====================
