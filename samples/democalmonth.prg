/*
democalmonth.prg
*/

#include "hwgui.ch"

STATIC nRowPos := -1, nColPos := -1

FUNCTION DemoCalMonth( lWithDialog, oDlg, oButton, dDate )

   LOCAL nCont, xValue, dDatRef, nMes

   hb_Default( @lWithDialog, .T. )

   SET DATE BRITISH
   IF oButton == Nil
      oButton := Array(31)
   ENDIF
   IF dDate == Nil
      dDate := Date()
   ENDIF

   dDatRef := dDate - 1
   nMes    := Month( dDate )

   nColPos := -1
   nRowPos := -1

   IF lWithDialog
     INIT DIALOG oDlg ;
         TITLE "Test Month" ;
         AT 1,1 ;
         SIZE 770, 548 ;
         STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE
   ENDIF
   ButtonForSample( "democalmonth.prg" )
   FOR nCont = 1 TO 7
      @ 20 + ( ( nCont - 1 ) * 50 ), 60 SAY Left( CDOW( Stod( "20250601" ) + nCont ), 3 ) ;
         OF oDlg ;
         SIZE 45, 30
   NEXT
   IF Dow( dDatRef - 1 ) != 7
      FOR nCont = 1 TO Dow( dDatRef - 1 )
         ColPos()
      NEXT
   ENDIF
   FOR nCont = 1 TO 31
      FOR EACH xValue IN { nCont }
         IF Month( dDatRef + xValue ) == nMes
            /* button
            @ ColPos(), nRowPos BUTTON oButton[ xValue ] ;
               CAPTION StrZero( xValue, 2 ) ;
               SIZE 30, 30 ;
               ; // FONT oFont  ;
               STYLE WS_TABSTOP + BS_FLAT ;
               ON CLICK { || Routine( dDatRef + xValue ) }
            */
            @ ColPos(), nRowPos CHECKBOX oButton[ xValue ]  ;
               CAPTION Ltrim( Str( xValue ) ) ;
               SIZE 50, 30
         ENDIF
      NEXT
   NEXT

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

   RETURN Nil

STATIC FUNCTION ColPos()

   IF nColPos == -1
      nColPos := 20
      nRowPos := 90
   ELSE
      nColPos += 50
      IF nColPos > 350
         nRowPos += 40 // LINE_HEIGHT
         nColPos := 20
      ENDIF
   ENDIF

   RETURN nColPos

#include "demo.ch"
