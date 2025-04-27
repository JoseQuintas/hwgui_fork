//--------------------------------------------------------------------------//

#include "hwgui.ch"

STATIC oWnd
STATIC oDlg1
STATIC oDlg2
STATIC oTB
STATIC oTB1
STATIC oTB2
STATIC oSay
STATIC oSayDlg1
STATIC oSayDlg2

FUNCTION Main()

   INIT WINDOW oWnd ;
      MAIN ;
      TITLE "TrackBar Control - Demo" ;
      AT    100,100 ;
      SIZE  640,480

   MENU OF oWnd
      MENUITEM "&Dialog 1" ACTION Dlg1()
      MENUITEM "&Dialog 2" ACTION Dlg2()
      MENUITEM "&Exit"     ACTION hwg_EndWindow()
   ENDMENU

   @ 20,20 TRACKBAR oTB ;
      SIZE   300,50 ;
      RANGE  0,10 ;
      INIT   5 ;
      AUTOTICKS ;
      ON CHANGE {||UpdateSay()}

   @ 300,200 BUTTON "Get Value" ;
      ON CLICK {||hwg_Msginfo(str(oTB:Value))} ;
      SIZE     100,40

   @ 300,300 BUTTON "Set Value" ;
      ON CLICK {||oTB:Value := 5,UpdateSay()} ;
      SIZE     100,40

   @ 100,100 SAY oSay ;
      CAPTION "5" ;
      SIZE 40,40

   ACTIVATE WINDOW oWnd CENTER

RETURN Nil

FUNCTION UpdateSay()

   oSay:SetText( ALLTRIM(str( oTB:Value )) )

RETURN Nil

FUNCTION Dlg1()

   INIT DIALOG oDlg1 TITLE "Dialog 1" ;
      AT 20,20 SIZE 500,300

   @ 20,20 TRACKBAR oTB1 ;
      SIZE    400,50 ;
      RANGE   0,100 ;
      INIT    25 ;
      ON INIT {||hwg_Msginfo("On Init","TrackBar")} ;
      ON CHANGE {||UpdateSayDlg1()} AUTOTICKS TOOLTIP "trackbar control"

   @ 300,100 BUTTON "Get Value" ;
      ON CLICK {||hwg_Msginfo(str(oTB1:Value))} ;
      SIZE     100,40

   @ 300,200 BUTTON "Set Value" ;
      ON CLICK {||oTB1:Value := 25,UpdateSayDlg1()} ;
      SIZE     100,40

   @ 100,100 SAY oSayDlg1 ;
      CAPTION "25" ;
      SIZE    40,40

   ACTIVATE DIALOG oDlg1

RETURN Nil

FUNCTION UpdateSayDlg1()

   oSayDlg1:SetText( ALLTRIM(str( oTB1:Value )) )

RETURN Nil

FUNCTION Dlg2()

   INIT DIALOG oDlg2 ;
      TITLE "Dialog 2" ;
      AT    20,20 ;
      SIZE  500,300

   @ 20,20 TRACKBAR oTB2 ;
      OF      oDlg2 ;
      SIZE    100,200 ;
      RANGE   0,50 ;
      INIT    50 ;
      VERTICAL ;
      AUTOTICKS ;
      TOOLTIP   "trackbar control" ;
      ON CHANGE {||UpdateSayDlg2()}

   @ 300,060 BUTTON "Get Value" ;
      ON CLICK {||hwg_Msginfo(str(oTB2:Value))} ;
      SIZE     100,40

   @ 300,100 BUTTON "Set Value" ;
      ON CLICK {||oTB2:Value := 50,UpdateSayDlg2()} ;
      SIZE     100,40

   @ 200,100 SAY oSayDlg2 ;
      CAPTION "50" ;
      SIZE    40,40

   ACTIVATE DIALOG oDlg2

RETURN Nil

FUNCTION UpdateSayDlg2()

   oSayDlg2:SetText( ALLTRIM(str( oTB2:Value )) )

RETURN Nil

* ======================= EOF of trackbar.prg =====================
