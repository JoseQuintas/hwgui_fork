//--------------------------------------------------------------------------//

#include "hwgui.ch"

FUNCTION DemoTrackbar( lWithDialog, oDlg )

   LOCAL oTb1, oSay1, oTB2, oSay2, oTb3, oSay3

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "TrackBar Control - Demo" ;
         AT    0, 0 ;
         SIZE  800, 600
   ENDIF

   ButtonForSample( "demotrackbar.prg" )

   @ 30, 100 TRACKBAR oTb1 ;
      OF      oDlg ;
      SIZE    50, 300 ;
      RANGE   0, 50 ;
      INIT    50 ;
      VERTICAL ;
      AUTOTICKS ;
      TOOLTIP   "trackbar control" ;
      ON CHANGE { || oSay1:SetText( AllTrim(str( oTb1:Value ) ) ) }

   @ 100, 100 SAY oSay1 ;
      CAPTION "50" ;
      SIZE 40, 40

   @ 100, 150 BUTTON "Get Value" ;
      SIZE 100, 40 ;
      ON CLICK { || hwg_Msginfo( str( oTb1:Value ) ) }

   @ 100, 200 BUTTON "Set Value" ;
      SIZE 100, 40 ;
      ON CLICK { || oTb1:Value := 50, oSay1:SetText( AllTrim(str( oTB1:Value ) ) ) }

   @ 320, 100 TRACKBAR oTb2 ;
      SIZE   300, 50 ;
      RANGE  0, 10 ;
      INIT   5 ;
      AUTOTICKS ;
      ON CHANGE { || oSay2:SetText( AllTrim(str( oTb2:Value ) ) ) }

   @ 650, 100 SAY oSay2 ;
      CAPTION "5" ;
      SIZE 40, 40

   @ 320, 150 BUTTON "Get Value" ;
      SIZE 100, 40 ;
      ON CLICK { || hwg_Msginfo( str( oTb2:Value ) ) }

   @ 470, 150 BUTTON "Set Value" ;
      SIZE 100, 40 ;
      ON CLICK { || oTb2:Value := 5, oSay2:SetText( AllTrim(str( oTB2:Value ) ) ) }

   @ 320, 250 TRACKBAR oTB3 ;
      SIZE    300, 50 ;
      RANGE   0, 100 ;
      INIT    25 ;
      ; // ON INIT { || hwg_Msginfo("On Init", "TrackBar" ) } ;
      ON CHANGE { || oSay3:SetText( AllTrim(str( oTB3:Value ) ) ) } ;
      AUTOTICKS ;
      TOOLTIP "trackbar control"

   @ 650, 250 SAY oSay3 ;
      CAPTION "25" ;
      SIZE    40,40

   @ 320, 300 BUTTON "Get Value" ;
      SIZE     100, 40 ;
      ON CLICK { || hwg_Msginfo( str( oTB3:Value ) ) }

   @ 470, 300 BUTTON "Set Value" ;
      SIZE     100, 40 ;
      ON CLICK { || oTB3:Value := 25, oSay3:SetText( AllTrim(str( oTb3:Value ) ) ) }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

#include "demo.ch"

* ======================= EOF of trackbar.prg =====================
