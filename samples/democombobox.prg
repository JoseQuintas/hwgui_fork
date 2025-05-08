/*
democombobox.prg
*/

#include "hwgui.ch"

FUNCTION DemoCombobox( lWithDialog, oDlg )

   LOCAL oCombo1, oCombo2
   LOCAL aComboList  := { "White", "Blue", "Red", "Black" }

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "democombobox.prg - combobox" ;
         AT 390,197 ;
         SIZE 516,323 ;
         STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE
   ENDIF

   ButtonForSample( "democombobox.prg", oDlg )

#ifndef __PLATFORM__WINDOWS
   @ 10, 100 COMBOBOX oCombo1 ;
      ITEMS aComboList ;
      SIZE  100, 25              // size for GTK

   oCombo2 := Nil // ok, warning -w3 -es2 require value
   (oCombo2)      // ok, warning -w3 -es2 require use
#else
   @ 10, 100 COMBOBOX oCombo1 ;
      ITEMS aComboList ;
      SIZE  100, 100             // size for windows

   @ 10, 150 COMBOBOX oCombo2 ;
      ITEMS   aComboList ;
      SIZE    100, 100 ;
      EDIT                       // only windows, crash on GTK
#endif

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

   RETURN Nil

#include "demo.ch"
