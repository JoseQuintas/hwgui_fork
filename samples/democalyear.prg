/*
democalyear.prg
*/

#include "hwgui.ch"

FUNCTION DemoCalYear( lWithDialog, oDlg, nYear )

   LOCAL oTab, nCont, oButton[ 12, 31 ], aItem, dDate

   hb_Default( @lWithDialog, .T. )
   hb_Default( @nYear, 2025 )

   FOR EACH aItem IN oButton
      AFill( aItem, .F. )
   NEXT

   IF lWithDialog
     INIT DIALOG oDlg ;
         TITLE "Test Month" ;
         AT 1,1 ;
         SIZE 770, 548 ;
         STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE
   ENDIF

   ButtonForSample( "democalyear.prg" )

   @ 20, 80 TAB oTab ;
      ITEMS {} ;
      OF oDlg ;
      SIZE 504, 341 ;
      STYLE WS_CHILD + WS_VISIBLE

   FOR nCont = 1 TO 12

      dDate := Stod( StrZero( nYear, 4 ) + StrZero( nCont, 2 ) + "01" )
      BEGIN PAGE CMonth( dDate )  OF oTab

      DemoCalMonth( .F., oTab, oButton[ nCont ], dDate )

      END PAGE OF oTab

   NEXT

   @ 30, 500 BUTTON "showAll" SIZE 100,20 ON CLICK { || Show(oButton) }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

   RETURN Nil

STATIC FUNCTION Show( aValue )

   LOCAL cTxt := "", oMonth, oDay

   FOR EACH oMonth IN aValue
      FOR EACH oDay IN oMonth
         IF ValType( oDay ) == "O" .AND. oDay:Value
            cTxt += Dtoc( Stod( "2025" + StrZero( oMonth:__EnumIndex(), 2 ) + StrZero( oDay:__EnumIndex(), 2 ) ) ) + " "
         ENDIF
      NEXT
   NEXT
   hwg_MsgInfo( cTxt )

   RETURN Nil

#include "demo.ch"
