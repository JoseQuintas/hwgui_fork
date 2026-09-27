#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDlg, oChk, aBranches

   aBranches := { ;
      { "São Paulo",      .T., "SP" }, ;
      { "Rio de Janeiro", .F., "RJ" }, ;
      { "Belo Horizonte", .T., "MG" }, ;
      { "Curitiba",       .F., "PR" }, ;
      { "Porto Alegre",   .F., "RS" } }

   INIT DIALOG oDlg TITLE "HCheckList sample" AT 100, 100 SIZE 400, 340

   @ 20, 20 SAY "Branches:" SIZE 300, 22

   @ 20, 50 CHECKLIST oChk                 ;
      ITEMS aBranches                      ;
      OF oDlg                              ;
      SIZE 340, 200                        ;
      STYLE WS_BORDER + WS_VSCROLL         ;
      ON CHANGE { |o, n, lOn| hwg_MsgInfo( "Row " + Str(n) + ;
                     Iif( lOn, " checked", " unchecked" ) ) }

   @ 20, 270 BUTTON "Show checked" SIZE 160, 30 ;
      ON CLICK { || hwg_MsgInfo( ;
         "Indexes: " + hb_ValToExp( oChk:GetChecked() ) + Chr(10) + ;
         "Items:   " + hb_ValToExp( oChk:GetCheckedItems() ) + Chr(10) + ;
         "Values:  " + hb_ValToExp( oChk:GetCheckedValues() ) ) }

   @ 200, 270 BUTTON "Close" SIZE 100, 30 ;
      ON CLICK { || oDlg:Close() }

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil
