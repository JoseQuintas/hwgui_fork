 *
 * democheckbox.prg
 *
 * $Id$
 *
 * Test program HWGUI sample for checkboxes
 *
 * Copyright 2022 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Copyright 2020-2022 Wilfried Brunken, DF7BE
 *

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

#include "hwgui.ch"
#include "common.ch"
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

FUNCTION DemoCheckBox( lWithDialog, oDlg )

   LOCAL oButton1, oButton2, oButton3, oButton7
   LOCAL oCheckbox1, oCheckbox2, oCheckbox3
   LOCAL lCheckbox1, lCheckbox2, lCheckbox3

   hb_Default( @lWithDialog, .T. )

   lCheckbox1 := .F.
   lCheckbox2 := .F.
   lCheckbox3 := .F.

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "democheckbox.prg - Checkboxes and tabs" ;
         AT 390,197 ;
         SIZE 516,323 ;
         STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE
   ENDIF

// on demo.ch
   ButtonForSample( "democheckbox.prg", oDlg )

   @ 300, 70 BUTTON oButton7 ;
      CAPTION  "Invert all"   ;
      SIZE     120,32 ;
      STYLE    WS_TABSTOP+BS_FLAT ;
      ON CLICK { || ;
         oCheckbox1:Invert(), ;
         oCheckbox2:Invert(), ;
         oCheckbox3:Invert() }

   @ 300, 110 BUTTON oButton1 ;
      CAPTION "Select all"   ;
      SIZE 120, 32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || ;
         oCheckbox1:Value( .T. ), ;
         oCheckbox2:Value( .T. ), ;
         oCheckbox3:Value( .T. ) }

   @ 300, 150 BUTTON oButton2 ;
      CAPTION "Unselect all"   ;
      SIZE 120,32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || ;
         oCheckbox1:Value( .F. ), ;
         oCheckbox2:Value( .F. ), ;
         oCheckbox3:Value( .F. ) }

   @ 300, 190 BUTTON oButton3 ;
      CAPTION  "OK"   ;
      SIZE     120,32 ;
      STYLE    WS_TABSTOP+BS_FLAT ;
      ON CLICK {|| ;
         DisplayResults( lCheckbox1, lCheckbox2, lCheckbox3 ), ;
         oDlg:Close() }

   @ 45, 70  GET CHECKBOX oCheckbox1 ;
      VAR      lCheckbox1 ;
      CAPTION  "Check 1" ;
      SIZE     80,22

   @ 45, 110 GET CHECKBOX oCheckbox2 ;
      VAR      lCheckbox2 ;
      CAPTION  "Check 2" ;
      SIZE     80,22

   @ 45, 150 GET CHECKBOX oCheckbox3 ;
      VAR      lCheckbox3 ;
      CAPTION  "Check 2" ;
      SIZE     80,22

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

STATIC FUNCTION DisplayResults( Checkbox1, Checkbox2, Checkbox3 )

   LOCAL cergstr

   cergstr := "Check 1= " + bool2onoff( Checkbox1 ) + CHR(10) + ;
              "Check 2= " + bool2onoff( Checkbox2 ) + CHR(10) + ;
              "Check 3= " + bool2onoff( Checkbox3 ) + CHR(10)

   hwg_MsgInfo( cergstr, "Result" )

RETURN Nil

STATIC FUNCTION bool2onoff( lbool )

   IF lbool
      RETURN "On"
   ENDIF

RETURN "Off"

// show buttons and source code
#include "demo.ch"

* ============================== EOF of checkbox.prg ========================
