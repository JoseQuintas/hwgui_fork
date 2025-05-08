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

#include "hwgui.ch"


FUNCTION DemoUpDown( lWithDialog, oDlg )

   LOCAL n_Key2, o_Number, o_get

   hb_Default( @lWithDialog, .T. )

#ifndef __GTK__
   hwg_Settooltipballoon(.t.)
#endif

   //n_Key1 := 1
   n_Key2 := 3000
   o_Number := 10

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demoupdown.prg - Ticket #19"  ;
         AT 200,100 SIZE 500,500 ;
         // ON EXIT { || hwg_MsgYesNo( "OK to quit ?" ) }
   ENDIF

   ButtonForSample( "demoupdown.prg", oDlg )

   @ 200, 100 GET UPDOWN o_get ;
      VAR o_Number ;
      RANGE 1, n_Key2 OF oDlg ;
      ID 100 ;
      SIZE 80, 30 ;
      STYLE WS_BORDER ;
      TOOLTIP "Select the Progressive Number"

   @ 200, 200 BUTTON "Show Value" ;
      OF oDlg ;
      SIZE 200, 24 ;
      ON CLICK { || hwg_MsgInfo( "Value = " + LTrim( Str( o_Get:Value() ) ) ) }

   o_Number := o_Number + 1
   o_get:Value( o_Number )
   o_get:Refresh()

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF
   * after some code execution
   * I put this istruction to see the value
   * nValue := o_Number:Value()
   //nValue := o_Number
   //hwg_msginfo( "nValue =" + ALLTRIM( STR( nValue ) ) )

RETURN Nil

#include "demo.ch"

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

* ====== EOF of demoupdown.prg ======
