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

   LOCAL oButton1, oButton2, oButton3, oButton4, oButton5, oButton6 , oButton7 , oButton8
   LOCAL oTab
   LOCAL oCheckbox1, oCheckbox2, oCheckbox3 , oCheckbox4 , oCheckbox5,  oCheckbox6
   LOCAL lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6

   hb_Default( @lWithDialog, .T. )

   lCheckbox1 := .F.
   lCheckbox2 := .F.
   lCheckbox3 := .F.
   lCheckbox4 := .F.
   lCheckbox5 := .F.
   lCheckbox6 := .F.

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "democheckbox.prg - Checkboxes and tabs" ;
         AT 390,197 ;
         SIZE 516,323 ;
         STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE
   ENDIF

   // do not remove button
   @ 3, 30 OWNERBUTTON ;
      OF       oDlg ;
      SIZE     200, 24 ;
      HSTYLES ;
         HStyle():New( {16759929,16772062}, 1 ), ;
         HStyle():New( {16759929}, 1,, 3, 0 ), ;
         HStyle():New( {16759929}, 1,, 2, 12164479 ) ;
      TEXT     "democheckbox.prg" ;
      ON CLICK { || democheckbox() }

   @ 20, 50 TAB oTab ;
      ITEMS   {} ;
      SIZE    440, 250 ;
      ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   BEGIN PAGE "Tab 1" of oTab

      @ 300,61 BUTTON oButton1 ;
         CAPTION "Select all"   ;
         SIZE 120, 32 ;
         STYLE WS_TABSTOP + BS_FLAT ;
         ON CLICK {|| oCheckbox1:Value(.T.) , oCheckbox2:Value(.T.) , oCheckbox3:Value(.T.)}

      @ 300,112 BUTTON oButton2 ;
         CAPTION "Unselect all"   ;
         SIZE 120,32 ;
         STYLE WS_TABSTOP + BS_FLAT ;
         ON CLICK {|| oCheckbox1:Value(.F.) , oCheckbox2:Value(.F.) , oCheckbox3:Value(.F.)}

      @ 300,28 BUTTON oButton7 ;
         CAPTION  "Invert all"   ;
         SIZE     120,32 ;
         STYLE    WS_TABSTOP+BS_FLAT ;
         ON CLICK {|| oCheckbox1:Invert() , oCheckbox2:Invert() , oCheckbox3:Invert()}


      @ 300,166 BUTTON oButton3 ;
         CAPTION  "OK"   ;
         SIZE     120,32 ;
         STYLE    WS_TABSTOP+BS_FLAT ;
         ON CLICK {|| DisplayResults(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6) ;
                      , oDlg:Close() }

      @ 45,70  GET CHECKBOX oCheckbox1 ;
         VAR      lCheckbox1 ;
         CAPTION  "Check 1" ;
         SIZE     80,22

      @ 45,110 GET CHECKBOX oCheckbox2 ;
         VAR      lCheckbox2 ;
         CAPTION  "Check 2" ;
         SIZE     80,22

      @ 45,150 GET CHECKBOX oCheckbox3 ;
         VAR      lCheckbox3 ;
         CAPTION  "Check 2" ;
         SIZE     80,22

   END PAGE of oTab

   BEGIN PAGE "Tab 2" of oTab

      @ 300,61 BUTTON oButton4 ;
         CAPTION  "Select all"   ;
         SIZE     120,32 ;
         STYLE    WS_TABSTOP + BS_FLAT ;
         ON CLICK {|| oCheckbox4:Value(.T.) , oCheckbox5:Value(.T.) , oCheckbox6:Value(.T.)}

      @ 300,112 BUTTON oButton5 ;
         CAPTION  "Unselect all"   ;
         SIZE     120,32 ;
         STYLE    WS_TABSTOP+BS_FLAT ;
         ON CLICK {|| oCheckbox4:Value(.F.) , oCheckbox5:Value(.F.) , oCheckbox6:Value(.F.)}

      @ 300,28 BUTTON oButton8 ;
         CAPTION "Invert all"   ;
         SIZE 120,32 ;
         STYLE WS_TABSTOP + BS_FLAT ;
         ON CLICK {|| oCheckbox4:Invert() , oCheckbox5:Invert() , oCheckbox6:Invert()}

      @ 300,166 BUTTON oButton6 CAPTION "OK"   ;
         SIZE 120,32 ;
         STYLE WS_TABSTOP + BS_FLAT ;
         ON CLICK {|| DisplayResults(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6) ;
                     , oDlg:Close() }

      @ 45,70  GET CHECKBOX oCheckbox4 ;
         VAR     lCheckbox4 ;
         CAPTION "Check 4" ;
         SIZE    80,22

      @ 45,110 GET CHECKBOX oCheckbox5 ;
         VAR     lCheckbox5 ;
         CAPTION "Check 5" ;
         SIZE    80,22

      @ 45,150 GET CHECKBOX oCheckbox6 ;
         VAR     lCheckbox6 ;
         CAPTION "Check 6" ;
         SIZE    80,22

   END PAGE of oTab

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

STATIC FUNCTION DisplayResults( Checkbox1, Checkbox2, Checkbox3 , Checkbox4 , Checkbox5,  Checkbox6 )

   LOCAL cergstr

   cergstr := "Check 1= " + bool2onoff(Checkbox1) + CHR(10) + "Check 2= " + bool2onoff(Checkbox2) + CHR(10) +  ;
              "Check 3= " + bool2onoff(Checkbox3) + CHR(10) + "Check 4= " + bool2onoff(Checkbox4) + CHR(10) +  ;
              "Check 5= " + bool2onoff(Checkbox5) + CHR(10) + "Check 6= " + bool2onoff(Checkbox6)

   hwg_MsgInfo(cergstr,"Result")

RETURN Nil

STATIC FUNCTION bool2onoff( lbool )

   IF lbool
      RETURN "On"
   ENDIF

RETURN "Off"

* ============================== EOF of checkbox.prg ========================
