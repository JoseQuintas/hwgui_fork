/*
 *$Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 * testbrw.prg - another browsing sample (array)
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes , see comment above
    *  GTK/Win  :  No

* -------------------------
* Sample crashes on GTK,
* method Add standard not
* working here, so
* the image add as hex value.
*
* -------------------------

* Only Field "Age" is editable.
* HBROWSE class on GTK:
* Obscure behavior on editable field "Age" need to fix !
* The modified value not accepted.

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "Example" ;
      AT 200,0 ;
      SIZE 400,150

   * GTK: Submenus required, otherwise only display "Activate"
   MENU OF oMainWindow
    MENU TITLE "&Exit"
      MENUITEM "&Quit" ACTION hwg_EndWindow()
    ENDMENU
    MENU TITLE "&Dialog"
      MENUITEM "&Start Browse" ACTION DlgGet()
    ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

STATIC FUNCTION DlgGet()

   LOCAL oBmp
   LOCAL oModDlg, oBrw1, oBrw2
   LOCAL aSample1 := { {"Alex",17,2500}, {"Victor",42,2200}, {"John",31,1800}, ;
      {"Sebastian",35,2000}, {"Mike",54,2600}, {"Sardanapal",22,2350}, {"Sergey",30,2800}, {"Petr",42,2450} }
   LOCAL aSample2 := { {.t.,"Line 1",10}, {.t.,"Line 2",22}, {.f.,"Line 3",40} }
#ifdef __GTK__
   LOCAL cValTrue
#endif

   INIT DIALOG oModDlg ;
      TITLE "About" ;
      AT 190,10 ;
      SIZE 600,320

   @ 20,16 BROWSE oBrw1 ;
      ARRAY ;
      SIZE 280,220 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   @ 310,16 BROWSE oBrw2 ;
      ARRAY ;
      SIZE 280,220 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   oBrw1:aArray := aSample1
   oBrw1:AddColumn( HColumn():New( "Name",{|v,o| (v), o:aArray[o:nCurrent,1]},"C",12,0,.F.,DT_CENTER ) )
   oBrw1:AddColumn( HColumn():New( "Age",{|v,o| (v), o:aArray[o:nCurrent,2]},"N",6,0,.T.,DT_CENTER,DT_RIGHT ) )
   oBrw1:AddColumn( HColumn():New( "Koef",{|v,o| (v), o:aArray[o:nCurrent,3]},"N",6,0,.F.,DT_CENTER,DT_RIGHT ) )
   oBrw1:aColumns[2]:footing := "Age"
   oBrw1:aColumns[2]:lResizable := .F.

   hwg_CREATEARLIST( oBrw2,aSample2 )
#ifdef __GTK__
* Standard image OBM_CHECK not available on GTK
* Take it from hex value
   cValTrue := hwg_cHex2Bin(true_bmp())
   oBmp     := HBitmap():AddString( "true" , cValTrue )
#else
   oBmp := HBitmap():AddStandard( OBM_CHECK )
#endif
   oBrw2:aColumns[1]:aBitmaps := { { {|l|l}, oBmp } }
   oBrw2:aColumns[2]:length := 6
   oBrw2:aColumns[3]:length := 4
   oBrw2:bKeyDown := {|o,key|BrwKey(o,key)}
   oBrw2:bcolorSel := oBrw2:htbColor := 0xeeeeee
   oBrw2:tcolorSel := 0xff0000

   @ 210,260 OWNERBUTTON ;
      ON CLICK {|| hwg_EndDialog()} ;
      SIZE 180,36 FLAT                                ;
      TEXT "Close" ;
      COLOR hwg_ColorC2N("0000FF")

   ACTIVATE DIALOG oModDlg

RETURN Nil

STATIC FUNCTION BrwKey( oBrw, key )
   IF key == 32
      oBrw:aArray[ oBrw:nCurrent,1 ] := !oBrw:aArray[ oBrw:nCurrent,1 ]
      oBrw:RefreshLine()
   ENDIF

RETURN .T.

#ifdef __GTK__
STATIC FUNCTION true_bmp()

   * Hexdump of true.bmp, needed for GTK
RETURN ;
   "42 4D 36 05 00 00 00 00 00 00 36 04 00 00 28 00 " + ;
   "00 00 0D 00 00 00 10 00 00 00 01 00 08 00 00 00 " + ;
   "00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 01 " + ;
   "00 00 00 00 00 00 00 00 00 00 00 00 80 00 00 80 " + ;
   "00 00 00 80 80 00 80 00 00 00 80 00 80 00 80 80 " + ;
   "00 00 C0 C0 C0 00 C0 DC C0 00 F0 CA A6 00 00 20 " + ;
   "40 00 00 20 60 00 00 20 80 00 00 20 A0 00 00 20 " + ;
   "C0 00 00 20 E0 00 00 40 00 00 00 40 20 00 00 40 " + ;
   "40 00 00 40 60 00 00 40 80 00 00 40 A0 00 00 40 " + ;
   "C0 00 00 40 E0 00 00 60 00 00 00 60 20 00 00 60 " + ;
   "40 00 00 60 60 00 00 60 80 00 00 60 A0 00 00 60 " + ;
   "C0 00 00 60 E0 00 00 80 00 00 00 80 20 00 00 80 " + ;
   "40 00 00 80 60 00 00 80 80 00 00 80 A0 00 00 80 " + ;
   "C0 00 00 80 E0 00 00 A0 00 00 00 A0 20 00 00 A0 " + ;
   "40 00 00 A0 60 00 00 A0 80 00 00 A0 A0 00 00 A0 " + ;
   "C0 00 00 A0 E0 00 00 C0 00 00 00 C0 20 00 00 C0 " + ;
   "40 00 00 C0 60 00 00 C0 80 00 00 C0 A0 00 00 C0 " + ;
   "C0 00 00 C0 E0 00 00 E0 00 00 00 E0 20 00 00 E0 " + ;
   "40 00 00 E0 60 00 00 E0 80 00 00 E0 A0 00 00 E0 " + ;
   "C0 00 00 E0 E0 00 40 00 00 00 40 00 20 00 40 00 " + ;
   "40 00 40 00 60 00 40 00 80 00 40 00 A0 00 40 00 " + ;
   "C0 00 40 00 E0 00 40 20 00 00 40 20 20 00 40 20 " + ;
   "40 00 40 20 60 00 40 20 80 00 40 20 A0 00 40 20 " + ;
   "C0 00 40 20 E0 00 40 40 00 00 40 40 20 00 40 40 " + ;
   "40 00 40 40 60 00 40 40 80 00 40 40 A0 00 40 40 " + ;
   "C0 00 40 40 E0 00 40 60 00 00 40 60 20 00 40 60 " + ;
   "40 00 40 60 60 00 40 60 80 00 40 60 A0 00 40 60 " + ;
   "C0 00 40 60 E0 00 40 80 00 00 40 80 20 00 40 80 " + ;
   "40 00 40 80 60 00 40 80 80 00 40 80 A0 00 40 80 " + ;
   "C0 00 40 80 E0 00 40 A0 00 00 40 A0 20 00 40 A0 " + ;
   "40 00 40 A0 60 00 40 A0 80 00 40 A0 A0 00 40 A0 " + ;
   "C0 00 40 A0 E0 00 40 C0 00 00 40 C0 20 00 40 C0 " + ;
   "40 00 40 C0 60 00 40 C0 80 00 40 C0 A0 00 40 C0 " + ;
   "C0 00 40 C0 E0 00 40 E0 00 00 40 E0 20 00 40 E0 " + ;
   "40 00 40 E0 60 00 40 E0 80 00 40 E0 A0 00 40 E0 " + ;
   "C0 00 40 E0 E0 00 80 00 00 00 80 00 20 00 80 00 " + ;
   "40 00 80 00 60 00 80 00 80 00 80 00 A0 00 80 00 " + ;
   "C0 00 80 00 E0 00 80 20 00 00 80 20 20 00 80 20 " + ;
   "40 00 80 20 60 00 80 20 80 00 80 20 A0 00 80 20 " + ;
   "C0 00 80 20 E0 00 80 40 00 00 80 40 20 00 80 40 " + ;
   "40 00 80 40 60 00 80 40 80 00 80 40 A0 00 80 40 " + ;
   "C0 00 80 40 E0 00 80 60 00 00 80 60 20 00 80 60 " + ;
   "40 00 80 60 60 00 80 60 80 00 80 60 A0 00 80 60 " + ;
   "C0 00 80 60 E0 00 80 80 00 00 80 80 20 00 80 80 " + ;
   "40 00 80 80 60 00 80 80 80 00 80 80 A0 00 80 80 " + ;
   "C0 00 80 80 E0 00 80 A0 00 00 80 A0 20 00 80 A0 " + ;
   "40 00 80 A0 60 00 80 A0 80 00 80 A0 A0 00 80 A0 " + ;
   "C0 00 80 A0 E0 00 80 C0 00 00 80 C0 20 00 80 C0 " + ;
   "40 00 80 C0 60 00 80 C0 80 00 80 C0 A0 00 80 C0 " + ;
   "C0 00 80 C0 E0 00 80 E0 00 00 80 E0 20 00 80 E0 " + ;
   "40 00 80 E0 60 00 80 E0 80 00 80 E0 A0 00 80 E0 " + ;
   "C0 00 80 E0 E0 00 C0 00 00 00 C0 00 20 00 C0 00 " + ;
   "40 00 C0 00 60 00 C0 00 80 00 C0 00 A0 00 C0 00 " + ;
   "C0 00 C0 00 E0 00 C0 20 00 00 C0 20 20 00 C0 20 " + ;
   "40 00 C0 20 60 00 C0 20 80 00 C0 20 A0 00 C0 20 " + ;
   "C0 00 C0 20 E0 00 C0 40 00 00 C0 40 20 00 C0 40 " + ;
   "40 00 C0 40 60 00 C0 40 80 00 C0 40 A0 00 C0 40 " + ;
   "C0 00 C0 40 E0 00 C0 60 00 00 C0 60 20 00 C0 60 " + ;
   "40 00 C0 60 60 00 C0 60 80 00 C0 60 A0 00 C0 60 " + ;
   "C0 00 C0 60 E0 00 C0 80 00 00 C0 80 20 00 C0 80 " + ;
   "40 00 C0 80 60 00 C0 80 80 00 C0 80 A0 00 C0 80 " + ;
   "C0 00 C0 80 E0 00 C0 A0 00 00 C0 A0 20 00 C0 A0 " + ;
   "40 00 C0 A0 60 00 C0 A0 80 00 C0 A0 A0 00 C0 A0 " + ;
   "C0 00 C0 A0 E0 00 C0 C0 00 00 C0 C0 20 00 C0 C0 " + ;
   "40 00 C0 C0 60 00 C0 C0 80 00 C0 C0 A0 00 F0 FB " + ;
   "FF 00 A4 A0 A0 00 80 80 80 00 00 00 FF 00 00 FF " + ;
   "00 00 00 FF FF 00 FF 00 00 00 FF 00 FF 00 FF FF " + ;
   "00 00 FF FF FF 00 FF FF FF FF FF FF FF FF FF FF " + ;
   "FF FF FF 00 00 00 FF FF FF FF FF FF FF FF FF FF " + ;
   "FF FF FF 00 00 00 FF FF FF FF FF FF FF FF FF FF " + ;
   "FF FF FF 00 00 00 FF FF FF FF FF FF FF FF FF FF " + ;
   "FF FF FF 00 00 00 FF FF FF FF 00 FF FF FF FF FF " + ;
   "FF FF FF 00 00 00 FF FF FF 00 00 00 FF FF FF FF " + ;
   "FF FF FF 00 00 00 FF FF 00 00 00 00 00 FF FF FF " + ;
   "FF FF FF 00 00 00 FF FF 00 00 FF 00 00 00 FF FF " + ;
   "FF FF FF 00 00 00 FF FF 00 FF FF FF 00 00 00 FF " + ;
   "FF FF FF 00 00 00 FF FF FF FF FF FF FF 00 00 FF " + ;
   "FF FF FF 00 00 00 FF FF FF FF FF FF FF FF 00 FF " + ;
   "FF FF FF 00 00 00 FF FF FF FF FF FF FF FF FF FF " + ;
   "FF FF FF 00 00 00 FF FF FF FF FF FF FF FF FF FF " + ;
   "FF FF FF 00 00 00 FF FF FF FF FF FF FF FF FF FF " + ;
   "FF FF FF 00 00 00 FF FF FF FF FF FF FF FF FF FF " + ;
   "FF FF FF 00 00 00 FF FF FF FF FF FF FF FF FF FF " + ;
   "FF FF FF 00 00 00 "
#endif

* ========================== EOF of testbrw.prg ==========================
