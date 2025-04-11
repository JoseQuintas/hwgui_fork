/*
 * HWGUI sample demonstrates usage of @ <x> <y> GET UPDOWN ..
 * See ticket #19 from
 *
 * Copyright 2020 Wilfried Brunken, DF7BE
 *
 * $Id$
 *
 * [hwgui:support-requests] #19 how to set updown value
 *
 * Status:
 *  WinAPI   :  Yes
 *  GTK/Linux:  Yes
 *  GTK/Win  :  Yes
 */

/* === includes === */
// #include "hwgui.ch"
// #ifdef __GTK__
//  #include "gtk.ch"
// #endif
#include "hwgui.ch"


FUNCTION Main()

   LOCAL n_Key2, o_Number, o_TAB_1, nValue, o_get // n_Key1

#ifndef __GTK__
   hwg_Settooltipballoon(.t.)
#endif

   //n_Key1 := 1
   n_Key2 := 3000
   o_Number := 10

   INIT WINDOW o_TAB_1 MAIN TITLE "Ticket #19"  ;
      AT 200,100 SIZE 500,500 ;
      ON EXIT { || hwg_MsgYesNo( "OK to quit ?" ) }

   @ 200, 50 GET UPDOWN o_get VAR o_Number RANGE 1, n_Key2 OF o_TAB_1 ;
      ID 100 ;
      SIZE 80, 30 ;
      STYLE WS_BORDER ;
      TOOLTIP "Select the Progressive Number"

   o_Number := o_Number + 1
   o_get:Value(o_Number)
   o_get:Refresh()

   ACTIVATE WINDOW o_TAB_1
   * after some code execution
   * I put this istruction to see the value
   * nValue := o_Number:Value()
   nValue := o_Number
   hwg_msginfo( "nValue =" + ALLTRIM( STR( nValue ) ) )

RETURN Nil

* reading the value works fine
*    after some other code execution i increment the counter
//    nValue := nValue + 1
*   and after I put this istruction to change the value
//   o_Number:Value( nValue )
//    o_Number:Refresh()
 *   at this point in the terminal console where i started the application
 *   appear this message
 *   IA__gtk_spin_button_set_value: assertion 'GTK_IS_SPIN_BUTTON (spin_button)' failed
 *   at this point o_Number:Value()  should return 2
 *   but the value of the o_Number is 1

* ====== EOF of getupdown.prg ======
