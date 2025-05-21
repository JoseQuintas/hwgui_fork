/*
demoaltprog.prg
*/

#include "hwgui.ch"

PROCEDURE DemoAltProg( lWIthDialog, oDlg )

   LOCAL oLabel1, oLabel2, oLabel3, nPos := 0

   hb_Default( @lWithDialog, .T. )

   IF lWIthDialog
      INIT DIALOG oDlg ;
         TITLE "demosplit.prg - Split windows example"  ;
         AT 0,0 ;
         SIZE 800, 600
   ENDIF

   ButtonForSample( "demoaltprog.prg", oDlg )

   @ 10, 100 SAY oLabel1 CAPTION "" ;
      SIZE 700, 24 ;

   @ 10, 100 SAY oLabel2 CAPTION "" ;
      SIZE 700, 24 ;

   @ 10, 100 SAY oLabel3 CAPTION "0" ;
      SIZE 700, 24 ;
      STYLE SS_CENTER ;
      TRANSPARENT

   @ 10, 250 BUTTON "Up" SIZE 100, 24 ON CLICK { || nPos := Min( nPos + 1, 100 ), Adjust( nPos, oLabel2, oLabel3 ) }

   @ 200, 250 BUTTON "Down" SIZE 100, 24 ON CLICK { || nPos := Max( nPos -1, 0 ), Adjust( nPos, oLabel2, oLabel3 ) }

   oLabel1:SetColor( hwg_RGB( 255, 255, 255 ), hwg_RGB( 255, 255, 255 ) )
   oLabel2:SetColor( hwg_RGB( 0, 255, 0 ), hwg_RGB( 0, 255, 0 ) )
   oLabel2:Move( 10, 100, 0, 0 )

   IF lWithDialog
      ACTIVATE DIALOG oDLG CENTER
   ENDIF

   RETURN

STATIC FUNCTION Adjust( nPos, oLabel2, oLabel3 )

   oLabel2:Move( 10, 100, Int( 700 * nPos / 100 ), 24 )
   oLabel3:SetText( hb_ValToExp( Int( nPos ) ) + "%" )
   oLabel2:Refresh()
   oLabel3:Refresh()

   RETURN Nil

#include "demo.ch"
