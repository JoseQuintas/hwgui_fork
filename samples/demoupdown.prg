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

   LOCAL nRange1, nValue1 := 1, oGet1, nValue2 := 1, oUpDown2, lCanc := .F.
   LOCAL nSelection := 1, nOldSel := 1
   LOCAL cText := "Choose a value 1-10"

   hb_Default( @lWithDialog, .T. )

#ifndef __GTK__
   hwg_Settooltipballoon(.t.)
#endif

   nRange1 := 3000
   nValue1 := 10

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demoupdown.prg - Ticket #19/#92"  ;
         AT 200,100 SIZE 500,500 ;
         // ON EXIT { || hwg_MsgYesNo( "OK to quit ?" ) }
   ENDIF

   ButtonForSample( "demoupdown.prg", oDlg )

   @ 200, 100 GET UPDOWN oGet1 ;
      VAR nValue1 ;
      RANGE 1, nRange1 OF oDlg ;
      ID 100 ;
      SIZE 80, 30 ;
      STYLE WS_BORDER ;
      TOOLTIP "#19 Select the Progressive Number"

   @ 33, 150 SAY cText SIZE 220,22
   @ 200, 150 GET UPDOWN oUpDown2 VAR nValue2 ;
      RANGE 1, 10 SIZE 45, 22 COLOR hwg_ColorC2N( "FF0000" ) ;
      TOOLTIP "Choose a value 1-10"

    @ 105,205 BUTTON "ok"  SIZE 60, 32 COLOR hwg_ColorC2N( "FF0000" ) ;
     ON CLICK { || lcanc := .F. , iif( lWithDialog, oDlg:Close(), Nil ) }

   @ 405,205 BUTTON "Cancel"    ; && OF oMatchID  ID IDCANCEL
       SIZE 100, 32 ;
       ON CLICK { || iif( lWithDialog, oDlg:Close(), Nil ) }

   @ 200, 200 BUTTON "Show Value" ;
      OF oDlg ;
      SIZE 200, 24 ;
      ON CLICK { || hwg_MsgInfo( "Value = " + LTrim( Str( oGet1:Value() ) ) ) }

   nValue1 := nValue1 + 1
   oGet1:Value( nValue1 )
   oGet1:Refresh()

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      IF .NOT. lcanc
         // if oMatchID:lresult
         //   hwg_msginfo("oUpdown:value() = "+ltrim(str(oUpDown:value()))+chr(10)+"cResult = "+cResult+chr(10)+space(30),"Test of UpDown")
         hwg_msginfo( ;
            "oUpdown2:value() = " + Ltrim( str( oUpDown2:value() ) ) + chr(10) + ;
            " nselection = " + AllTrim( Str( nselection ) ) + chr(10) + ;
            space(30), "Test of UpDown" )
      ELSE
         // Cancelled: old value is recovered !
         nselection := noldsel
         hwg_msginfo( "Cancelled : Old value = " + ltrim( str( nselection ) ) )
      ENDIF

   ENDIF

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
