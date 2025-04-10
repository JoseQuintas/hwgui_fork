/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 *  bitmapbug.prg
 *
 * Sample program for handling bug in display
 * of bitmaps (Class HBITMAP)
 *
 * Copyright 2024 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No

* --------- Instructions -------------
*
* The symptom:
*
* - Call test menu point "Bitmap bug":
* At the first call the bitmap is displayed and
* the size is delivered correct by methods
* hwg_GetBitmapWidth() and hwg_GetBitmapHeight()
*
* - Call test menu point "Bitmap &bug" twice or more:
*   The PUBLIC bitmap object "oBMPCancel" is corrupted
*   so that the Bitmap is not displayed and the size
*   parameters are out of range.
*   On GTK, the call crashes with:
*   (bitmapbug:53290): GLib-ERROR **: 16:12:05.854: ../../../glib/gmem.c:372:
*    overflow allocating 18446744073709551615*18446744073709551615 bytes
*
*
*
* Handling of this bug:
* Call test menu point "Bitmap OK" as often as you can,
* and the bitmap is displayed every time.
*
* In FUNCTION TestOK the bitmap obeject is forever created new
* before display operation.
* LOCAL oBitmap2,...,olbitmap
* olbitmap := HBitmap():AddString( "cancel", cBMPCancel )
* That's it !!!
*
* I found this bug during developing my HWGUI application "CLLOG"
* (see above link)
* ------------------------------------
#include "hwgui.ch"

MEMVAR cBMPCancel , oBMPCancel , ncalls

FUNCTION Main

LOCAL oFormMain

PUBLIC cBMPCancel , oBMPCancel , ncalls

ncalls := 0
* Convert hex image to binary as type C
LOAD_HEX_RES()

* Create bitmap object as PUBLIC (will be corrupted after first usage for display)
oBMPCancel := HBitmap():AddString( "cancel", cBMPCancel )


  INIT WINDOW oFormMain MAIN  ;
       TITLE "Hwgui sample for handling bitmap bug" AT 0,0 SIZE 300,200 ;
      STYLE WS_POPUP +  WS_CAPTION + WS_SYSMENU

   MENU OF oFormMain
      MENU TITLE "&Exit"
         MENUITEM "&Quit" ACTION oFormMain:Close()
      ENDMENU
      MENU TITLE "&Test"
         MENUITEM "Bitmap &bug" ACTION TestBug(oBMPCancel)
         MENUITEM "Bitmap &OK" ACTION TestOK(cBMPCancel)
      ENDMENU
   ENDMENU

   oFormMain:Activate()

RETURN Nil



* Display bitmap by passed object
* variable
FUNCTION TestBug(opbitmap)

LOCAL Display_bitmap
LOCAL oBitmap1, oButton1 , olabel1 , nflx , nfly

MEMVAR ncalls

  ncalls := ncalls + 1

  INIT DIALOG Display_bitmap TITLE "Display Bitmap (Bug)" ;
    AT 467,236 SIZE 304,248 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE

    @ 10 , 10 SAY olabel1 CAPTION "Number of calls: " + ALLTRIM(STR(ncalls)) ;
                SIZE 150, 30

  IF opbitmap != NIL

   nflx  := hwg_GetBitmapWidth ( opbitmap:handle )
   nfly  := hwg_GetBitmapHeight( opbitmap:handle )

   hwg_MsgInfo("nflx=" + ALLTRIM(STR(nflx)) + " nfly=" + ALLTRIM(STR(nfly)) )

#ifdef __GTK__

   @ 100,40 BITMAP oBitmap1 ; && OF Display_bitmap ;
        SHOW opbitmap  ;
         SIZE nflx, nfly
#else
   @ 100,40 BITMAP oBitmap1  ;
        SHOW opbitmap  ;
         SIZE nflx, nfly

#endif
   @ 107,124 BUTTON oButton1 CAPTION "OK"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| Display_bitmap:Close() }
  ELSE
    hwg_MsgInfo("opbitmap is NIL")
  ENDIF

   ACTIVATE DIALOG Display_bitmap


RETURN NIL


* Display bitmap by passed binary image
* variable
FUNCTION TestOK(cBMPCancel)

LOCAL Display_bitmap
LOCAL oBitmap2, oButton1 , nflx , nfly , olbitmap

* That's it: create object new before every usage !!!!
olbitmap := HBitmap():AddString( "cancel", cBMPCancel )

  INIT DIALOG Display_bitmap TITLE "Display Bitmap (OK)" ;
    AT 467,236 SIZE 304,248 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


  IF olbitmap != NIL

   nflx  := hwg_GetBitmapWidth ( olbitmap:handle )
   nfly  := hwg_GetBitmapHeight( olbitmap:handle )

//   hwg_MsgInfo("nflx=" + ALLTRIM(STR(nflx)) + " nfly=" + ALLTRIM(STR(nfly)) )

#ifdef __GTK__
  @ 100,40 BITMAP oBitmap2 ; && OF Display_bitmap ;
        SHOW olbitmap  ;
         SIZE nflx, nfly
#else
   @ 100,40 BITMAP oBitmap2  ;
        SHOW olbitmap  ;
         SIZE nflx, nfly
#endif

   @ 107,124 BUTTON oButton1 CAPTION "OK"  SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| Display_bitmap:Close() }
  ELSE
    hwg_MsgInfo("olbitmap is NIL")
  ENDIF

   ACTIVATE DIALOG Display_bitmap


RETURN NIL

FUNCTION LOAD_HEX_RES()

cBMPCancel := hwg_cHex2Bin( ;
"42 4D 76 02 00 00 00 00 00 00 76 00 00 00 28 00 " + ;
"00 00 20 00 00 00 20 00 00 00 01 00 04 00 00 00 " + ;
"00 00 00 02 00 00 74 12 00 00 74 12 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 80 00 00 80 " + ;
"00 00 00 80 80 00 80 00 00 00 80 00 80 00 80 80 " + ;
"00 00 80 80 80 00 C0 C0 C0 00 00 00 FF 00 00 FF " + ;
"00 00 00 FF FF 00 FF 00 00 00 FF 00 FF 00 FF FF " + ;
"00 00 FF FF FF 00 FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF F0 07 77 70 00 " + ;
"77 77 7F FF FF FF FF FF FF FF FF 01 10 77 01 11 " + ;
"07 77 7F FF FF FF FF FF FF FF F0 91 10 FF 09 11 " + ;
"00 FF FF FF FF FF FF FF FF FF F0 99 11 00 99 11 " + ;
"10 FF FF FF FF FF FF FF FF FF FF 09 11 00 99 91 " + ;
"0F FF FF FF FF FF FF FF FF FF FF 09 91 09 99 91 " + ;
"0F FF FF FF FF FF FF FF FF FF FF F0 91 99 99 10 " + ;
"FF FF FF FF FF FF FF FF FF FF FF F0 99 19 99 10 " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF 09 99 91 0F " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF 09 99 91 0F " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF 09 99 10 FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF F0 99 99 11 0F " + ;
"FF FF FF FF FF FF FF FF FF FF FF F0 99 99 11 0F " + ;
"FF FF FF FF FF FF FF FF FF FF FF 09 99 91 91 10 " + ;
"FF FF FF FF FF FF FF FF FF FF FF 09 99 10 91 10 " + ;
"FF FF FF FF FF FF FF FF FF FF F0 99 99 10 99 11 " + ;
"0F FF FF FF FF FF FF FF FF FF F0 97 99 0F 09 11 " + ;
"0F FF FF FF FF FF FF FF FF FF 09 98 71 0F 09 98 " + ;
"70 FF FF FF FF FF FF FF FF FF 07 77 80 FF F0 87 " + ;
"70 FF FF FF FF FF FF FF FF FF F0 77 70 FF F0 77 " + ;
"0F FF FF FF FF FF FF FF FF FF FF 00 0F FF FF 00 " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF " )

RETURN NIL

* =================== EOF of bitmapbug.prg =======================
