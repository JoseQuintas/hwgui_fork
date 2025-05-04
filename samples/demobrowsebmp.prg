/*
 *$Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 * demobrowsebmp.prg - another browsing sample (array)
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

FUNCTION DemoBrowseBmp( lWithDialog, oDlg )

   LOCAL oBmp, oBrw1, oBrw2
   LOCAL aSample1 := { {"Alex",17,2500}, {"Victor",42,2200}, {"John",31,1800}, ;
      {"Sebastian",35,2000}, {"Mike",54,2600}, {"Sardanapal",22,2350}, {"Sergey",30,2800}, {"Petr",42,2450} }
   LOCAL aSample2 := { {.t.,"Line 1",10}, {.t.,"Line 2",22}, {.f.,"Line 3",40} }

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "About" ;
         AT 0, 0 ;
         SIZE 800, 640
   ENDIF

   ButtonForSample( "demobrowse.bmp" )

   @ 20, 80 BROWSE oBrw1 ;
      ARRAY ;
      SIZE 280, 300 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   @ 310, 80 BROWSE oBrw2 ;
      ARRAY ;
      SIZE 280, 300 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   oBrw1:aArray := aSample1
   oBrw1:AddColumn( HColumn():New( "Name",{|v,o| (v), o:aArray[o:nCurrent,1]},"C",12,0,.F.,DT_CENTER ) )
   oBrw1:AddColumn( HColumn():New( "Age",{|v,o| (v), o:aArray[o:nCurrent,2]},"N",6,0,.T.,DT_CENTER,DT_RIGHT ) )
   oBrw1:AddColumn( HColumn():New( "Koef",{|v,o| (v), o:aArray[o:nCurrent,3]},"N",6,0,.F.,DT_CENTER,DT_RIGHT ) )
   oBrw1:aColumns[2]:footing := "Age"
   oBrw1:aColumns[2]:lResizable := .F.

   hwg_CREATEARLIST( oBrw2,aSample2 )

   oBmp := HBitmap():AddString( "true" , res_true_bmp() )

   oBrw2:aColumns[1]:aBitmaps := { { {|l|l}, oBmp } }
   oBrw2:aColumns[2]:length := 6
   oBrw2:aColumns[3]:length := 4
   oBrw2:bKeyDown := { |o,key| BrwKey( o, key ) }
   oBrw2:bcolorSel := oBrw2:htbColor := 0xeeeeee
   oBrw2:tcolorSel := 0xff0000

   @ 210, 400 OWNERBUTTON ;
      SIZE 180, 36 FLAT                                ;
      TEXT "Close" ;
      COLOR hwg_ColorC2N("0000FF") ;
      ON CLICK { || iif( lWithDialog, oDlg:Close(), hwg_MsgInfo( "No action here" ) ) }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

STATIC FUNCTION BrwKey( oBrw, key )

   IF key == 32
      oBrw:aArray[ oBrw:nCurrent,1 ] := !oBrw:aArray[ oBrw:nCurrent,1 ]
      oBrw:RefreshLine()
   ENDIF

RETURN .T.

FUNCTION res_true_bmp()

#ifdef __PLATFORM__WINDOWS
   #pragma __binarystreaminclude "..\image\true.bmp" | RETURN %s
#else
   #pragma __binarystreaminclude "../image/true.bmp" | RETURN %s
#endif

#include "demo.ch"

* ======================== EOF of demobrowsebmp.prg ========================
