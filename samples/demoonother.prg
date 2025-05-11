/*
 * demoonother.prg
 *
 * HWGUI sample display key codes
 *
 *  $Id$
 *
 * Status:
 *  WinAPI   :  Yes
 *  GTK/Linux:  No
 *  GTK/Win  :  No
 *
*/

#INCLUDE "hwgui.ch"

FUNCTION DemoOnOther()

   LOCAL oDlg

   INIT WINDOW oDlg ;
      TITLE "demoonother.prg - ON OTHER MESSAGES"  ;
      SIZE 500, 500 ;
      ON OTHER MESSAGES { | a, b, c, d | OnOtherMessages( a, b, c, d ) }

   @ 10, 100 SAY "Hit any key to test" ;
      SIZE 300, 24

   ACTIVATE WINDOW oDlg CENTER

RETURN Nil

STATIC FUNCTION OnOtherMessages( Sender, WinMsg, WParam, LParam )

   LOCAL nKey

/* Remove comment chars to display keydown codes */
// IF WinMsg == WM_KEYDOWN
//    nKey := WParam
//    hwg_Msginfo( "Keydown " + chr( hwg_Loword( nKey ) ) + " " + str( hwg_Loword( nKey ) ) )
//  endif


   IF WinMsg == WM_KEYUP
      nKey := WParam
      hwg_Msginfo( "Keyup " + chr( hwg_Loword( nKey ) ) + " " + str( hwg_Loword( nKey ) ) )
   ENDIF

   (Sender); (lParam) // Not used (-w3 -es2)

RETURN -1

* ============================ EOF of demoonother.prg ==========================

