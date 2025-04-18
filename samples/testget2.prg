/*
 *$Id: testget2.prg,v 1.9 2006/05/05 21:45:54 sandrorrfreire Exp $
 *
 * HwGUI Samples
 * testget2.prg - GET system and Timer in dialog box.
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No

    * Port to GTK3 was successful

/*
  Some trouble on GTK.
  - The function hwg_SetColorinFocus() does not work correct.
    The entry field in focus became only a simple border.
  - The Background color of the clock in menu
    (light green on WinAPI and GTK2) not visible (GTK3).
  - Ticket #117 by Itamar M. Lins Jr.:
    Fail on Linux OS. (MAXLENGTH).
    The Input field can be filled with more characters than with the
    parameter MAXLENGTH defined, but they are not stored in the variable.
    Moving the focus to another input field and go back to the input field
    with the length rectricted field, the content is displayed with the defined MAXLENGTH.
*/

#include "hwgui.ch"

MEMVAR oSayT

FUNCTION Main()

   LOCAL oMainWindow

   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
     AT 200,0 SIZE 400,150

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Get values" ACTION DlgGet(.F.)
      MENUITEM "&Get using SetcolorinFocus" ACTION DlgGet(.T.)
      MENUITEM "&Text Ballon" ACTION TestBallon()
      MENUITEM "&Hd Serial  " ACTION hwg_Msginfo( hwg_HdSerial( "C:\" ), "HD Serial number" )
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

FUNCTION DlgGet( lColorInFocus )

   LOCAL oModDlg, oFont := HFont():Add( "MS Sans Serif", 0, -13 ), oTimer
   LOCAL e1 := "Dialog from prg"
   LOCAL e2 := Date()
   LOCAL e3 := 10320.54
   LOCAL e4 := "11222333444455"
   LOCAL e5 := 10320.54
   LOCAL e6 := "Max Lenght = 15"
   LOCAL e7 := "Password"
   LOCAL oget6

   PRIVATE oSayT

   INIT DIALOG oModDlg ;
      CLIPPER ;
      NOEXIT ;
      TITLE "Get values"  ;
      AT 210,10  ;
      SIZE 300,320 ;
      FONT oFont ;
      ON INIT { || Dlg_Settimer( oModDlg, @oTimer ) }

   SET KEY FSHIFT, VK_F3 TO hwg_Msginfo( "Shift-F3" )
   SET KEY FCONTROL, VK_F3 TO hwg_Msginfo( "Ctrl-F3" )
   SET KEY 0, VK_F3 TO hwg_Msginfo( "F3" )
   SET KEY 0, VK_RETURN TO hwg_Msginfo( "Return" )

   IF lColorInFocus <> Nil
      hwg_SetColorinFocus( lColorInFocus )
   ENDIF

   @ 20, 10  SAY "Input something:" ;
      SIZE 260, 22

   @ 20, 35  GET e1 PICTURE "XXXXXXXXXXXXXXX" ;
      SIZE 260, 26

   @ 20, 65  GET oget6 ;
      VAR e6 ;
      MAXLENGTH 15 ;
      SIZE 260, 26

   @ 20, 95  GET e2  ;
      SIZE 260, 26

   @ 20, 125 GET e3  ;
      SIZE 260, 26

   @ 20, 155 GET e4 ;
      PICTURE "@R 99.999.999/9999-99" ;
      SIZE 260, 26

   @ 20, 185 GET e5 ;
      PICTURE "@e 999,999,999.9999" ;
      SIZE 260, 26

   @ 20, 215 GET e7 ;
      PASSWORD ;
      SIZE 260, 26

   @  20, 250  BUTTON "Ok" ;
      SIZE 100, 32 ;
      ON CLICK { || oModDlg:lResult := .T., hwg_EndDialog() }

   @ 180, 250 BUTTON "Cancel" ;
      ID IDCANCEL ;
      SIZE 100, 32

   @ 100, 295 SAY oSayT ;
      CAPTION "" ;
      SIZE 100,22 ;
      STYLE WS_BORDER + SS_CENTER ;
      COLOR 10485760 ;
      BACKCOLOR 12507070

   ReadExit( .T. )
   ACTIVATE DIALOG oModDlg

   oTimer:End()

   IF oModDlg:lResult
      hwg_Msginfo( e1 + chr(10) + chr(13) +       ;
               e6 + chr(10) + chr(13) +       ;
               Dtoc(e2) + chr(10) + chr(13) + ;
               Str(e3) + chr(10) + chr(13) +  ;
               e4 + chr(10) + chr(13) +       ;
               Str(e5) + chr(10) + chr(13) +  ;
               e7 + chr(10) + chr(13)         ;
               ,"Results:" )
   ENDIF

RETURN Nil

STATIC FUNCTION Dlg_Settimer( oDlg,oTimer )

   SET TIMER oTimer ;
      OF oDlg ;
      VALUE 1000 ;
      ACTION { || TimerFunc() }

RETURN Nil

STATIC FUNCTION TimerFunc()

   oSayT:SetText( Time() )

RETURN Nil

FUNCTION TestBallon()

   LOCAL oWnd

   hwg_Settooltipballoon(.t.)


   INIT DIALOG oWnd ;
      CLIPPER ;
      TITLE "Dialog text Balon" ;
      AT 100, 100 ;
      SIZE 140, 100

   @ 20, 20 BUTTON "Button 1" ;
      ON CLICK { || hwg_Msginfo( "Button 1" ) } ;
      SIZE 100, 40 ;
      TOOLTIP "ToolTip do Button 1"

   ACTIVATE DIALOG oWnd

RETURN Nil


FUNCTION MAXLEN_VALID(nlen,cstring)

 IF LEN(cstring) > nlen
   hwg_MsgInfo("Entry field length exceeds " + ALLTRIM(STR(nlen)) )
   RETURN .F.
 ENDIF

RETURN .T.

* ============================= EOF of testget2.prg ================================================

