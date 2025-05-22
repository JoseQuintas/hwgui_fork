#include "hwgui.ch"

FUNCTION DemoListbox( lWithDialog, oDlg )

   LOCAL oFont := HFont():Add( "MS Sans Serif",0,-13 )
   LOCAL oListbox, aList := { "Item01", "Item02", "Item03", "Item04" }

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demolistbox.prg - listbox sample"  ;
         AT 0,0  ;
         SIZE 450, 350   ;
         FONT oFont
   ENDIF

   ButtonForSample( "demolistbox.prg", oDlg )

   @ 10, 100 LISTBOX oListbox ;
      ITEMS aList ;
      OF oDlg  ;
      INIT 1 ;
      SIZE 210, 220 ;
      ; //ON INIT { || hwg_Msginfo( "Teste" ) } ;
      TOOLTIP "Test ListBox"

#ifndef __PLATFORM__WINDOWS
   @  300, 100 BUTTON "Show Value" ;
      ID IDOK  ;
      SIZE 100, 32 ;
      ON CLICK { || hwg_msgInfo( Str( oListbox:value ), "Result of Listbox selection" ) }
#endif

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      oFont:Release()
   ENDIF

RETURN Nil

// on demo.ch
#include "demo.ch"
