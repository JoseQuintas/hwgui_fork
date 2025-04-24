/*
 *
 * demoaltdpicker.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 * This sample demonstrates:
 * The multi platform substitute for the
 * Windows only DATEPICKER command.
 *
 * Copyright 2006 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Copyright 2022 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 *
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No


#include "hwgui.ch"

FUNCTION DemoAltDPicker( lWithDialog, oDlg )

   LOCAL oGetDate, oButtonDate, varOldDate
   LOCAL oFont, varDate := Date() + 1

   hb_Default( @lWithDialog, .T. )

   oFont := hwg_DefaultFont()

   * Remember old date
   varOldDate := varDate

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demoaltdpicker.prg - Datepicker alternative"  ;
         AT 210,10  ;
         SIZE 350,300                  ;
         FONT oFont NOEXIT
   ENDIF

// on demo.ch
   ButtonForSample( "demoaltdpicker.prg" )

*  v==> These are the original coordinates of DATEPICKER command
   @ 160,170 GET oGetDate ;
      VAR varDate  ;
      STYLE WS_DLGFRAME   ;
      SIZE 80, 20 ;
      COLOR hwg_ColorC2N("FF0000")
*     ^==> This is the original size of DATEPICKER command

*    v==>  x = 160 + 81 (x value of GET + width of GET + 1 )
   @ 241, 170 OWNERBUTTON oButtonDate  ;
      ON CLICK { | | ;
         varDate := hwg_pCalendar( varDate ) , ;
         oGetDate:Value( varDate ) } ;
      SIZE 12,12  ;            && Size of image + 1
      BITMAP hwg_oDatepicker_bmp() ;
      TRANSPARENT  COORDINATES 0, 0, 11, 11 ;
      TOOLTIP "Pick date from calendar"

   @ 150,250 BUTTON "Close" ;
      ON CLICK { || oDlg:Close() } ;
      SIZE 100,40

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      oFont:Release()
   ENDIF

  * Check for modified / Cancel
  IF lWithDialog
     IF varOldDate == varDate
         hwg_MsgInfo( "Date not modified or dialog cancelled" )
      ENDIF
      hwg_Msginfo( dtoc( varDate ) )
   ENDIF

RETURN Nil

// show buttons and source code
#include "demo.ch"

* =============================== EOF of demoaltdpicker.prg ==============================
