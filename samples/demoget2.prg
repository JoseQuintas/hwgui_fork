/*
 *$Id: demoget2.prg,v 1.9 2006/05/05 21:45:54 sandrorrfreire Exp $
 *
 * HwGUI Samples
 * demoget2.prg - GET system and Timer in dialog box.
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

FUNCTION DemoGet2( lWithDialog, oDlg )

   LOCAL oFont := HFont():Add( "MS Sans Serif", 0, -13 ), oTimer
   LOCAL e1 := "Dialog from prg"
   LOCAL e2 := Date()
   LOCAL e3 := 10320.54
   LOCAL e4 := "11222333444455"
   LOCAL e5 := 10320.54
   LOCAL e6 := "Max Lenght = 15"
   LOCAL e7 := "Password"
   LOCAL oget6, oSayT

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         CLIPPER ;
         NOEXIT ;
         TITLE "demoget2.prg - get values"  ;
         AT 0, 0  ;
         SIZE 600, 450 ;
         FONT oFont ;
         ON INIT { || Dlg_Settimer( oDlg, @oTimer, oSayT ) }

      SET KEY FSHIFT, VK_F3 TO hwg_Msginfo( "Shift-F3" )
      SET KEY FCONTROL, VK_F3 TO hwg_Msginfo( "Ctrl-F3" )
      SET KEY 0, VK_F3 TO hwg_Msginfo( "F3" )
      SET KEY 0, VK_RETURN TO hwg_Msginfo( "Return" )
   ENDIF

   hwg_SetColorinFocus( .T.)

   ButtonForSample( "demoget2.prg" )

   @ 20, 110  SAY "Input something:" ;
      SIZE 260, 22

   @ 20, 135  GET e1 PICTURE "XXXXXXXXXXXXXXX" ;
      SIZE 260, 26

   @ 20, 165  GET oget6 ;
      VAR e6 ;
      MAXLENGTH 15 ;
      SIZE 260, 26

   @ 20, 195  GET e2  ;
      SIZE 260, 26

   @ 20, 225 GET e3  ;
      SIZE 260, 26

   @ 20, 255 GET e4 ;
      PICTURE "@R 99.999.999/9999-99" ;
      SIZE 260, 26

   @ 20, 285 GET e5 ;
      PICTURE "@e 999,999,999.9999" ;
      SIZE 260, 26

   @ 20, 315 GET e7 ;
      PASSWORD ;
      SIZE 260, 26

   @  20, 350  BUTTON "Ok" ;
      SIZE 100, 32 ;
      ON CLICK { || ;
         iif( lWithDialog, oDlg:lResult := .T., Nil ), ;
         iif( lWithDialog, oDlg:Close(), hwg_MsgInfo( "No action here" ) ) }

   @ 180, 350 BUTTON "Cancel" ;
      ID IDCANCEL ;
      SIZE 100, 32

   @ 100, 395 SAY oSayT ;
      CAPTION "" ;
      SIZE 100,22 ;
      STYLE WS_BORDER + SS_CENTER ;
      COLOR 10485760 ;
      BACKCOLOR 12507070

   ReadExit( .T. )

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER

      oTimer:End()

      IF oDlg:lResult
         hwg_Msginfo( e1 + chr(10) + chr(13) + ;
               e6 + chr(10) + chr(13) +       ;
               Dtoc(e2) + chr(10) + chr(13) + ;
               Str(e3) + chr(10) + chr(13) +  ;
               e4 + chr(10) + chr(13) +       ;
               Str(e5) + chr(10) + chr(13) +  ;
               e7 + chr(10) + chr(13)         ;
               ,"Results:" )
      ENDIF
   ENDIF

RETURN Nil

STATIC FUNCTION Dlg_Settimer( oDlg,oTimer, oSayT )

   SET TIMER oTimer ;
      OF oDlg ;
      VALUE 1000 ;
      ACTION { || TimerFunc( oSayT ) }

RETURN Nil

STATIC FUNCTION TimerFunc( oSayT )

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

   ACTIVATE DIALOG oWnd CENTER

RETURN Nil


FUNCTION MAXLEN_VALID(nlen,cstring)

 IF LEN(cstring) > nlen
   hwg_MsgInfo("Entry field length exceeds " + ALLTRIM(STR(nlen)) )
   RETURN .F.
 ENDIF

RETURN .T.

#include "demo.ch"

* ============================= EOF of demoget2.prg ================================================

