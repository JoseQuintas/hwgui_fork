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

#ifdef __USING_MENU__
   FUNCTION DemoOnOther()
#else
   FUNCTION Main()
#endif

   LOCAL oDlg

   INIT DIALOG oDlg ;
      TITLE "DEMOONOTHER - ON OTHER MESSAGES"  ;
      SIZE 500, 500 ;
      ON OTHER MESSAGES { | a, b, c, d | OnOtherMessages( a, b, c, d ) }

   ACTIVATE DIALOG oDlg CENTER

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

