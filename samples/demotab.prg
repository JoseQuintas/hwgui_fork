/*
demotab.prg
show tab

At momment using source code using parts from hwgui tutorial  hwgui/utils/tutorial

Note: oDlg may be another dialog

called from all.prg - need to add here same prgs on demotab.hbp
*/

#include "hwgui.ch"

FUNCTION DemoTab( lWithDialog, oDlg )

   LOCAL oTab

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demotab.prg - tab" ;
         AT    0, 0 ;
         SIZE  800, 600 ;
         FONT  HFont():Add( "MS Sans Serif",0,-15 ) ;
         BACKCOLOR 16772062
   ENDIF

   // do not remove button
   ButtonForSample( "demotab.prg", oDlg )

   @ 30, 60 TAB oTab ;
      ITEMS {} ;
      SIZE  700, 480

   BEGIN PAGE "tab1" ;
      OF oTab

      DemoCheckbox( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "tab2" ;
      OF oTab

      DemoBrowseDBF( .F., oTab )

   END PAGE OF oTab

   IF lWithDialog

      ACTIVATE DIALOG oDlg ;
         CENTER
   ENDIF

   RETURN Nil

#include "demo.ch"

* ============================== EOF of demotab.prg ========================
