/*
 *
 * testget1.prg
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

FUNCTION Main()

   LOCAL oMainWindow

   // Modify to your own needs
   SET CENTURY ON
   SET DATE GERMAN

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "Example" ;
      AT 200, 0 ;
      SIZE 200, 250

   MENU OF oMainWindow
      MENU TITLE "&Exit"
         MENUITEM "&Quit" ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Test"
         MENUITEM "&Get a value" ACTION DlgGet()
         MENUITEM "&Calendar" ACTION Cal_Dialog()
         MENUITEM "&MONTHCALENDAR command" ACTION DLG_MONTHCALENDAR()
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

FUNCTION DlgGet()

   LOCAL oModDlg, oFont
   LOCAL oCombo, aCombo := { "First","Second" }
   LOCAL oGet
   LOCAL e1 := "Dialog from prg", c1 := .F., c2 := .T., r1 := 2, cm := 1
   LOCAL upd := 12, d1 := Date()+1
   LOCAL nxsizedia

#ifdef __GTK__
   LOCAL odGet
   LOCAL oDateOwb   && For DATEPICKER substitute

   nxsizedia := 450
#else
   nxsizedia := 350
#endif

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
   PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12
#endif

   INIT DIALOG oModDlg ;
      TITLE "Get a value"  ;
      AT 210, 10  ;
      SIZE nxsizedia, 300       ;
      FONT oFont ;
      NOEXIT

   SET KEY 0, VK_F3 TO hwg_Msginfo( "F3" )

   @ 20, 10 SAY "Input something:" ;
      SIZE 260, 22

   @ 20, 35 GET oGet ;
      VAR e1  ;
      STYLE WS_DLGFRAME   ;
      SIZE 260, 26 ;
      COLOR hwg_ColorC2N( "FF0000" )

   @ 20, 70 GET CHECKBOX c1 ;
      CAPTION "Check 1" ;
      SIZE 90, 20

   @ 20, 95 GET CHECKBOX c2 ;
      CAPTION "Check 2" ;
      SIZE 90, 20 ;
      COLOR hwg_ColorC2N( "0000FF" )

   @ 160, 70 GROUPBOX "RadioGroup" ;
      SIZE 130, 75

   GET RADIOGROUP r1
   @ 180,90 RADIOBUTTON "Radio 1"  ;
        SIZE 90, 20 ;
        ON CLICK { || oGet:SetColor( hwg_ColorC2N( "0000FF" ),, .T. ) }

   @ 180,115 RADIOBUTTON "Radio 2" ;
        SIZE 90, 20 ;
        ON CLICK { || oGet:SetColor( hwg_ColorC2N( "FF0000" ),, .T. ) }

   END RADIOGROUP

#ifdef __GTK__
   @ 300,20 GET COMBOBOX oCombo ;
      VAR cm ;
      ITEMS aCombo ;
      SIZE 100, 150
#else
   @ 20,120 GET COMBOBOX oCombo ;
      VAR cm ;
      ITEMS aCombo ;
      SIZE 100, 150
#endif

   @ 20,170 GET UPDOWN upd ;
      RANGE 0,80 ;
      SIZE 50,30

#ifdef __GTK__

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* Windows only DATEPICKER substitute
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*  v==> These are the original coordinates of DATEPICKER command : @ 160,170 SIZE 80, 20
   @ 140,170 GET odGet ;
      VAR d1  ;
      STYLE WS_DLGFRAME   ;
      SIZE 100, 20 ;
      COLOR hwg_ColorC2N( "FF0000" )
*     SIZE 80 ,20
*            ^==> This is the original size of DATEPICKER command

*    v==>  x = 160 + 81 (x value of GET + width of GET + 1 )
   @ 241, 170 OWNERBUTTON oDateOwb  ;
      ON CLICK { | | d1 := hwg_pCalendar( d1 ) , odGet:Value( d1 ) } ;
      SIZE 12, 12  ;            && Size of image + 1
      BITMAP hwg_oDatepicker_bmp() ;
      TRANSPARENT  ;
      COORDINATES 0, 0, 11, 11 ;
      TOOLTIP "Pick date from calendar"


#else
   @ 160, 170 GET DATEPICKER d1 ;
      SIZE 80, 20
#endif

   @ 20, 240 BUTTON "Ok" ;
      ID IDOK  ;
      SIZE 100, 32

   @ 180, 240 BUTTON "Cancel" ;
      ID IDCANCEL  ;
      SIZE 100, 32

   ACTIVATE DIALOG oModDlg
   oFont:Release()

   IF oModDlg:lResult
      hwg_Msginfo( e1 + chr(10) + chr(13) +                               ;
               "Check1 - " + Iif(c1,"On","Off") + chr(10) + chr(13) + ;
               "Check2 - " + Iif(c2,"On","Off") + chr(10) + chr(13) + ;
               "Radio: " + Str(r1,1) + chr(10) + chr(13) +            ;
               "Combo: " + aCombo[cm] + chr(10) + chr(13) +    ;
               "UpDown: "+Str(upd) + chr(10) + chr(13) +              ;
               "DatePicker: "+Dtoc(d1)                                ;
               ,"Results:" )
   ENDIF

RETURN Nil

FUNCTION Cal_Dialog()

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

FUNCTION DLG_MONTHCALENDAR()

// For range of years see FUNCTION _frm_CalValid

   LOCAL oDlg
   LOCAL oMC , dheute , lcancel , dnewdate , daltdatum
   Local oFont , Ctext

   //Ctext := "MONTHCALENDAR"

   * Today (based on local time)
   dheute := Date()

   * Remember old date
   daltdatum := dheute

   lcancel := .T.

   oFont := hwg_DefaultFont()

   INIT DIALOG oDlg ;
      TITLE "Calendar" ;
      AT 20, 20 ;
      SIZE 450, 300

   @ 20, 20 MONTHCALENDAR oMC ;
      SIZE 250, 250 ;
      INIT dheute ;   && Date()
      FONT oFont ;
      WEEKNUMBERS

    @ 300, 60  BUTTON "Cancel" ;
       ON CLICK { || oDlg:Close() } ;
       SIZE 100, 40

    @ 300, 20  BUTTON "OK" ;
       ON CLICK { || lcancel := .F., dnewdate := oMC:Value, oDlg:Close() } ;
       SIZE 100, 40

    @ 300, 100 BUTTON "Today" ;
       ON CLICK { || oMC:Value := Date() } ;
       SIZE 100,40

   ACTIVATE DIALOG oDlg

   // dnewdate := oMC:Value

   IF lcancel
      dnewdate := daltdatum
   ENDIF

   * Check for modified / Cancel
   IF daltdatum == dnewdate
      Ctext := "Date not modified or dialog cancelled"
      hwg_Msginfo( Ctext )
   ENDIF

   hwg_Msginfo( dtoc( dnewdate ) )

RETURN Nil

* ========================== EOF of testget1.prg =========================================
