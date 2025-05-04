/*
demoowner.prg

modified from tutorial
*/

#include "hwgui.ch"

STATIC nRowPos := -1, nColPos := -1

FUNCTION DemoOwner( lWithDialog, oDlg )

   LOCAL oButton := Array(30), nIndex, nLayout
   LOCAL aStyle1 := { ;
      HStyle():New( {16759929,16772062}, 1 ), ;             // normal
      HStyle():New( {16759929}, 1,, 3, 0 ), ;               // pressed
      HStyle():New( {16759929}, 1,, 2, 12164479 ) }         // over
   LOCAL aStyle2    := { ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 1 ), ;         // normal
      HStyle():New( {0xffffff,0xdddddd}, 2,, 1 ), ;         // pressed
      HStyle():New( {0xffffff,0xdddddd}, 1,, 2, 8421440 ) } // over

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demoowner.prg - ownerbutton" ;
         AT 390,197 ;
         SIZE 800, 600 ;
         STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE
   ENDIF

   ButtonForSample( "demoowner.prg" )

   FOR nIndex = 1 TO 30

      nLayout := Mod( nIndex, 3 ) + 1

      DO CASE
      CASE nLayout == 1

         @ ColPos(), nRowPos OWNERBUTTON oButton[ nIndex ] ;
               OF       oDlg ;
               SIZE     100, 24;
               TEXT     "Button " + Ltrim( Str( nIndex ) ) ;
               ON CLICK { || hwg_MsgInfo( "Click" ) }

      CASE nLayout == 2

         @ ColPos(), nRowPos OWNERBUTTON oButton[ nIndex ] ;
            OF       oDlg ;
            SIZE     100, 24 ;
            TEXT     "Button " + Ltrim( Str( nIndex ) ) ;
            ON CLICK { || hwg_MsgInfo( "Click" ) }
         oButton[ nIndex ]:aStyle := aStyle1

      CASE nLayout == 3

         @ ColPos(), nRowPos OWNERBUTTON oButton[ nIndex ] ;
            OF       oDlg ;
            SIZE     100, 24 ;
            HSTYLES aStyle2[ 1 ], aStyle2[ 2 ], aStyle2[ 3 ] ;
            TEXT     "Button " + Ltrim( Str( nIndex ) ) ;
            ON CLICK { || hwg_MsgInfo( "Click" ) }

      ENDCASE

   NEXT

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

   RETURN Nil

STATIC FUNCTION ColPos()

   IF nColPos == -1
      nColPos := 10
      nRowPos := 80
   ELSE
      nColPos += 150
      IF nColPos > 700
         nRowPos += 50
         nColPos := 10
      ENDIF
   ENDIF

   RETURN nColPos

#include "demo.ch"
