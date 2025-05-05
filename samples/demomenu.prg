/*
demomenu.prg

hwg_EndDialog() forces to close dialog

*/

#include "hwgui.ch"

FUNCTION DemoMenu( lWithDialog, oDlg )

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demomenu.prg - build a menu" ;
         AT 0,0 ;
         SIZE 600, 400
   ENDIF

   MENU OF oDlg
      MENU TITLE "&File"
         MENUITEM "&New" ACTION hwg_Msginfo( "New" )
         MENUITEM "&Open" ACTION hwg_Msginfo( "Open" )
         SEPARATOR
         MENUITEM "&Font" ACTION hwg_Msginfo( "font" )
         SEPARATOR
         MENUITEM "&Exit" ACTION oDlg:Close()
      ENDMENU
   ENDMENU

   // do not remove button
   ButtonForSample( "demomenu.prg" )

   IF lWithDialog
      ACTIVATE DIALOG oDlg ;
         CENTER
   ENDIF

   RETURN Nil

// on demo.ch
#include "demo.ch"

* ============================== EOF of demomenu.prg =========================
