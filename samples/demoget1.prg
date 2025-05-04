/*
 *
 * demoget1.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 * This sample demonstrates:
 * Get system: Edit field, Checkboxes, Radio buttons, Combo box, Datepicker
 *
 * Copyright 2006 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Copyright 2022 Wilfried Brunken, DF7BE
 * https://sourceforge.net/projects/cllog/
 *
 * Modifications by DF7BE:
 * - Multi platform ready
 * - Substitute for Windows only DATEPICKER
 *   based on MONTHCALENDAR command
 *   On Windows, the DATEPICKER was activated instead
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No

#include "hwgui.ch"

FUNCTION DemoGet1( lWithDialog, oDlg )

   LOCAL oFont
   LOCAL oCombo, aCombo := { "First","Second" }
   LOCAL oGet
   LOCAL e1 := "Dialog from prg", c1 := .F., c2 := .T., r1 := 2, cm := 1
   LOCAL upd := 12, d1 := Date()+1
   LOCAL odGet
   LOCAL oDateOwb   && For DATEPICKER substitute

   hb_Default( @lWithDialog, .T. )

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
   PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12
#endif

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demoget1 - Get a value"  ;
         AT 0, 0  ;
         SIZE 640, 480 ;
         FONT oFont ;
         NOEXIT
   ENDIF

   ButtonForSample( "demoget1.prg" )

   SET KEY 0, VK_F3 TO hwg_Msginfo( "F3" )

   @ 20, 60 SAY "Input something:" ;
      SIZE 260, 22

   @ 20, 85 GET oGet ;
      VAR e1  ;
      STYLE WS_DLGFRAME   ;
      SIZE 260, 26 ;
      COLOR hwg_ColorC2N( "FF0000" )

   @ 20, 120 GET CHECKBOX c1 ;
      CAPTION "Check 1" ;
      SIZE 90, 20

   @ 20, 145 GET CHECKBOX c2 ;
      CAPTION "Check 2" ;
      SIZE 90, 20 ;
      COLOR hwg_ColorC2N( "0000FF" )

   @ 160, 120 GROUPBOX "RadioGroup" ;
      SIZE 130, 75

   GET RADIOGROUP r1
   @ 180, 140 RADIOBUTTON "Radio 1"  ;
        SIZE 90, 20 ;
        ON CLICK { || oGet:SetColor( hwg_ColorC2N( "0000FF" ),, .T. ) }

   @ 180, 165 RADIOBUTTON "Radio 2" ;
        SIZE 90, 20 ;
        ON CLICK { || oGet:SetColor( hwg_ColorC2N( "FF0000" ),, .T. ) }

   END RADIOGROUP

#ifdef __GTK__
   @ 300, 70 GET COMBOBOX oCombo ;
      VAR cm ;
      ITEMS aCombo ;
      SIZE 100, 24
#else
   @ 20, 170 GET COMBOBOX oCombo ;
      VAR cm ;
      ITEMS aCombo ;
      SIZE 100, 150
#endif

   @ 20, 220 GET UPDOWN upd ;
      RANGE 0,80 ;
      SIZE 50,30

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* Windows only DATEPICKER substitute
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*  v==> These are the original coordinates of DATEPICKER command : @ 160,170 SIZE 80, 20
   @ 140, 220 GET odGet ;
      VAR d1  ;
      STYLE WS_DLGFRAME   ;
      SIZE 100, 20 ;
      COLOR hwg_ColorC2N( "FF0000" )
*     SIZE 80, 20
*            ^==> This is the original size of DATEPICKER command

*    v==>  x = 160 + 81 (x value of GET + width of GET + 1 )
   @ 241, 220 OWNERBUTTON oDateOwb  ;
      ON CLICK { | | d1 := hwg_pCalendar( d1 ) , odGet:Value( d1 ) } ;
      SIZE 12, 12  ;            && Size of image + 1
      BITMAP hwg_oDatepicker_bmp() ;
      TRANSPARENT  ;
      COORDINATES 0, 0, 11, 11 ;
      TOOLTIP "Pick date from calendar"

#ifdef __PLATFORM__WINDOWS
   @ 300, 220 SAY "datepicker substitute" ;
      SIZE 200, 24

   @ 160, 270 GET DATEPICKER d1 ;
      SIZE 80, 20

   @ 300, 270 SAY "Windows datepicker" ;
      SIZE 200, 24
#endif

   @ 20, 310 BUTTON "Ok" ;
      ID IDOK  ;
      SIZE 100, 32 ;
      ON CLICK { || hwg_MsgInfo( "No action" ) }

   @ 180, 310 BUTTON "Cancel" ;
      ID IDCANCEL  ;
      SIZE 100, 32 ;
      ON CLICK { || hwg_MsgInfo( "No action" ) }

   @ 340, 310 BUTTON "Cal_Dialog" ;
      SIZE 100, 32 ;
      ON CLICK { || Cal_Dialog() }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      oFont:Release()

      IF oDlg:lResult
         hwg_Msginfo( ;
            e1 + chr(10) + chr(13) +                               ;
            "Check1 - " + Iif( c1, "On", "Off" ) + chr(10) + chr(13) + ;
            "Check2 - " + Iif( c2, "On", "Off" ) + chr(10) + chr(13) + ;
            "Radio: " + Str( r1, 1 ) + chr(10) + chr(13) + ;
            "Combo: " + aCombo[ cm ] + chr(10) + chr(13) + ;
            "UpDown: "+Str( upd ) + chr(10) + chr(13) + ;
            "DatePicker: " + Dtoc( d1 ), ;
            "Results:" )
      ENDIF
   ENDIF

RETURN Nil

STATIC FUNCTION Cal_Dialog()

   LOCAL ddatum, daltdatum, Ctext

   //Ctext := "Calendar"
   daltdatum := DATE()
   * Starts with today
   ddatum := hwg_pCalendar()

    * Check for modified / Cancel
   IF daltdatum == ddatum
      Ctext := "Date not modified or dialog cancelled"
      hwg_Msginfo( Ctext )
   ENDIF
   hwg_Msginfo( dtoc( ddatum ) )

RETURN Nil

#include "demo.ch"

* ========================== EOF of demoget1.prg =========================================
