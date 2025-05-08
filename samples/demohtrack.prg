// We create here a new control, which can be
// used as a replacement for a track bar,
// which has not gtk version.
#include "hwgui.ch"
#include "hbclass.ch"
#define CLR_WHITE    0xffffff
#define CLR_BLACK    0x000000
#define CLR_BROWN_1  0x154780
#define CLR_BROWN_3  0xaad2ff

FUNCTION DemoHTrack( lWithDialog, oDlg )

   LOCAL oTrack, oSay, oFont := HFont():Add( "MS Sans Serif",0,-13 )
   LOCAL bVolChange := { | o, n |
         HB_SYMBOL_UNUSED( o )
         HB_SYMBOL_UNUSED( n )
         oSay:SetText( Ltrim( Str( oTrack:value ) ) )
         RETURN .T.
         }

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "Track bar control"  ;
         AT 210,10  ;
         SIZE 400, 300 ;
         FONT oFont BACKCOLOR CLR_BROWN_1
   ENDIF

   ButtonForSample( "demohtrack.prg", oDlg )

   @ 40, 170 SAY "Just drag the slider:" ;
      SIZE 220, 22 ;
      STYLE SS_CENTER BACKCOLOR CLR_BROWN_3

   oTrack := HTrack():New( ,, 80, 100, 140, 28,,, CLR_WHITE, CLR_BROWN_1, 16 )
   oTrack:bChange := bVolChange
   oTrack:Value := 0.5

   @ 80, 250 SAY oSay ;
      CAPTION "" ;
      SIZE 140, 22 ;
      STYLE SS_CENTER ;
      BACKCOLOR CLR_BROWN_3

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      oFont:Release()
   ENDIF

RETURN Nil

#include "demo.ch"

* ============================ EOF of htrack.prg ==============================
