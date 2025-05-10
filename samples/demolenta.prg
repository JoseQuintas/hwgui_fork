/*
demolenta.prg
*/

// Lenta and panels, used as a replacement of a colorized tab
#include "hwgui.ch"

#define CLR_LIGHTGRAY_2 0xaaaaaa
#define CLR_BROWN_1     0x154780
#define CLR_BROWN_2     0x396eaa
#define CLR_BROWN_3     0x6a9cd4
#define CLR_BROWN_4     0x9dc7f6
#define CLR_DLGBACK     0x154780

FUNCTION DemoLenta( lWithDialog, oDlg )

   LOCAL oFont := HFont():Add( "MS Sans Serif", 0, - 13 )
   LOCAL oPane1, oPane2, oLenta, nTab := 1
   LOCAL aStyleLenta := { HStyle():New( { CLR_BROWN_2 }, 1 ), ;
      HStyle():New( { CLR_BROWN_3, CLR_BROWN_4 }, 1, , 2, CLR_LIGHTGRAY_2 ) }
   LOCAL bTab := { |o|
      IF nTab != o:Value
         nTab := o:Value
         IF nTab == 1
            oPane2:Hide()
            oPane1:Show()
         ELSEIF nTab == 2
            oPane1:Hide()
            oPane2:Show()
         ENDIF
      ENDIF
      RETURN .T.
   }

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog

      INIT DIALOG oDlg ;
         TITLE "demolenta.prg - Lenta control"  ;
         AT 210, 10 ;
         SIZE 400, 400 ;
         FONT oFont ;
         BACKCOLOR CLR_DLGBACK
   ENDIF

   ButtonForSample( "demolenta.prg", oDlg )

   @ 20, 116 LENTA oLenta ;
      FONT oFont ;
      ITEMS { "First", "Second" } ;
      OF oDlg ;
      SIZE 160, 28 ;
      ITEMSIZE 80 ;
      HSTYLES aStyleLenta ;
      ON CLICK bTab

   //oLenta := HLenta():New( , , 20, 16, 160, 28, oFont, , , bTab, , , ;
   //   { "First", "Second" }, 80, aStyleLenta )
   oLenta:Value := nTab

   @ 20, 150 PANEL oPane2 ;
      OF oDlg ;
      SIZE 360, 200 ;
      STYLE SS_OWNERDRAW ;
      BACKCOLOR CLR_BROWN_2 ;
      ON SIZE { || .T. }

   oPane2:oFont := oFont
   @ 20, 16 EDITBOX "Sergei" OF oPane2 SIZE 200, 26
   @ 20, 46 EDITBOX "Vasilievich" OF oPane2 SIZE 200, 26
   @ 20, 76 EDITBOX "Rachmaninoff" OF oPane2 SIZE 200, 26
   @ 20, 106 EDITBOX "01/04/1873" OF oPane2 SIZE 100, 26
   oPane2:Hide()

   @ 20, 150 PANEL oPane1 ;
      OF oDlg ;
      SIZE 360, 200 ;
      STYLE SS_OWNERDRAW ;
      BACKCOLOR CLR_BROWN_3 ;
      ON SIZE { || .T. }

   oPane1:oFont := oFont
   @ 20,  16 EDITBOX "Pyotr" OF oPane1 SIZE 200, 26
   @ 20,  46 EDITBOX "Ilyich" OF oPane1 SIZE 200, 26
   @ 20,  76 EDITBOX "Tchaikovsky" OF oPane1 SIZE 200, 26
   @ 20, 106 EDITBOX "07/05/1840" OF oPane1 SIZE 100, 26

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER

      oFont:Release()
   ENDIF

   RETURN Nil

#include "demo.ch"
