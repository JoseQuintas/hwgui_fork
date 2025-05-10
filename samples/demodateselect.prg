/*
demodateselect.prg

windows datepicker substitute
*/

#include "hwgui.ch"

FUNCTION DemoDateSelect( lWithDialog, oDlg )

   LOCAL oDate

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demodateselect.prg" ;
         AT 0,0 ;
         SIZE 500,400
   ENDIF

   ButtonForSample( "demodateselect.prg", oDlg )

   @ 10, 100 SAY "Date" ;
      SIZE 80, 30

   @ 100, 100 DATESELECT oDate ;
      SIZE 120,28

   IF lWithDialog
      ACTIVATE DIALOG oDLG CENTER
   ENDIF

   RETURN Nil

#include "demo.ch"
