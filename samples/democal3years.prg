/*
democal3years.prg
*/

#include "hwgui.ch"

FUNCTION DemoCal3Years( lWithDialog, oDlg )

   LOCAL oTab, nCont, nYear := 2025

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
     INIT DIALOG oDlg ;
        TITLE "Test Month" ;
        AT 1,1 ;
        SIZE 800, 600 ;
        STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE
   ENDIF

   ButtonForSample( "demo3years.prg" )
   @ 20, 60 TAB oTab ;
      ITEMS {} ;
      OF oDlg ;
      SIZE 750, 550 ;
      STYLE WS_CHILD + WS_VISIBLE

   FOR nCont = 1 TO 3

      BEGIN PAGE Str( nYear - 2 + nCont, 4 ) OF oTab

      DemoCalYear( .F., oTab, nYear - 2 + nCont )

      END PAGE OF oTab

   NEXT

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

   RETURN Nil

#include "demo.ch"
