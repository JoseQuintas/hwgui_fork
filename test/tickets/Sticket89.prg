*
* Support ticket #89 Curious crash
*
* This sample does not crash, and no GTK messages appeared during program run.
* The white image is grey, but the cancel image appeared correct !
* The OK button has on Ubuntu a white background, so it is recommended to use this.
* Some more comments follow.
* The bindbf.prg sample crashes, need to fix later.

#include "hwgui.ch"

MEMVAR cHex_white, cVal_white, oObj_white

FUNCTION MAIN

Local oGrille, hbloc,vbloc,oAa,oAb,oAc
LOCAL oButton1, cImageDir

hbloc := 25
vbloc := 27
#ifdef __PLATFORM__WINDOWS
cImageDir := ".\image\"
#else
cImageDir := "./image/"
#endif

public cHex_white:="", cVal_white:="", oObj_white:=""

// --------- white.png ----------------
cHex_white := ;
"89 50 4E 47 0D 0A 1A 0A 00 00 00 0D 49 48 44 52 " + ;
"00 00 00 18 00 00 00 18 08 06 00 00 00 E0 77 3D " + ;
"F8 00 00 00 01 73 52 47 42 00 AE CE 1C E9 00 00 " + ;
"00 06 62 4B 47 44 00 00 00 00 00 00 F9 43 BB 7F " + ;
"00 00 00 09 70 48 59 73 00 00 0B 13 00 00 0B 13 " + ;
"01 00 9A 9C 18 00 00 00 07 74 49 4D 45 07 E3 03 " + ;
"15 10 20 18 E6 AD 01 75 00 00 00 19 74 45 58 74 " + ;
"43 6F 6D 6D 65 6E 74 00 43 72 65 61 74 65 64 20 " + ;
"77 69 74 68 20 47 49 4D 50 57 81 0E 17 00 00 00 " + ;
"28 49 44 41 54 48 C7 63 BC 73 E7 CE 7F 06 1A 02 " + ;
"26 06 1A 83 51 0B 46 2D 18 B5 60 D4 82 51 0B 46 " + ;
"2D 18 B5 60 D4 02 EA 00 00 5C EB 03 C3 EE 39 63 " + ;
"E5 00 00 00 00 49 45 4E 44 AE 42 60 82 "

cVal_white := hwg_cHex2Bin(cHex_white)

* At first run create the image file
* Created a bmp from png by external program
// MEMOWRIT("white.png", cVal_white)

oObj_white := HBitmap():AddString( "white" , cVal_white )

  INIT WINDOW oGrille TITLE "Support ticket #89 Curious crash";
         AT 0, 0 SIZE 600, 230 

* No FLAT on GTK, see sample bindbf.prg
* - GTK: Remove "OF oToolbar" and "FLAT"

@ hbloc+27,vbloc+27 OWNERBUTTON oAa  SIZE 24, 24 ; && OF oGrille
BITMAP oobj_white  ID 1101 && FLAT
hbloc+=27
@ hbloc+27,vbloc+27 OWNERBUTTON oAb  SIZE 24, 24 ; && OF oGrille 
BITMAP oobj_white  ID 1102  && FLAT
hbloc+=27
@ hbloc+27,vbloc+27 OWNERBUTTON oAc  SIZE 24, 24;   && OF oGrille
BITMAP cImageDir+"cancel.bmp" ID 1103 && FLAT 
// COORDINATES 0,0,24,24


@ 30,175 BUTTON oButton1 CAPTION "OK" SIZE 80,30 ;
ON CLICK {|| oGrille:Close() }

ACTIVATE WINDOW oGrille

RETURN NIL

* ======================= EOF of Sticket89.prg =============================

