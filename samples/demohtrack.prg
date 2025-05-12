#include "hwgui.ch"

#define CLR_WHITE    0xffffff
#define CLR_BLACK    0x000000
#define CLR_BROWN_1  0x154780
#define CLR_BROWN_3  0xaad2ff

FUNCTION DemoHTrack( lWithDialog, oDlg )

   LOCAL oTrack1, oSay1, oTrack2, oSay2, oFont := HFont():Add( "MS Sans Serif",0,-13 )
   LOCAL bVolChange := {|o,n|
      HB_SYMBOL_UNUSED( n )
      IF o:lVertical
         oSay2:SetText( Ltrim(Str(o:value)) )
      ELSE
         oSay1:SetText( Ltrim(Str(o:value)) )
      ENDIF
      RETURN .T.
   }

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg TITLE "demohtrack.prg - Track bar control"  ;
            AT 0, 0  SIZE 400, 400 FONT oFont BACKCOLOR CLR_BROWN_1
   ENDIF

   ButtonForSample( "demohtrack.prg", oDlg )

   @ 40, 120 SAY "Just drag the slider:" SIZE 220, 22 STYLE SS_CENTER BACKCOLOR CLR_BROWN_3

   @ 20, 150 TRACK oTrack1 SIZE 140, 28 COLOR CLR_WHITE ;
      BACKCOLOR CLR_BROWN_1 SLIDER SIZE 16 AXIS
   oTrack1:bChange := bVolChange
   oTrack1:Value := 0.5

   @ 200, 150 SAY oSay1 CAPTION "" SIZE 80, 22 STYLE SS_CENTER BACKCOLOR CLR_BROWN_3

   @ 40, 220 TRACK oTrack2 SIZE 28, 100 COLOR CLR_WHITE ;
      BACKCOLOR CLR_BROWN_1 SLIDER SIZE 16 AXIS
   oTrack2:bChange := bVolChange
   oTrack2:Value := 0.5

   @ 200, 220 SAY oSay2 CAPTION "" SIZE 80, 22 STYLE SS_CENTER BACKCOLOR CLR_BROWN_3

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      oFont:Release()
   ENDIF

RETURN Nil

#include "demo.ch"

* ============================ EOF of htrack.prg ==============================
