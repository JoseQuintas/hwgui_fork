#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDlg, oChk, aFiliais

   aFiliais := { ;
      { "São Paulo",      .T., "SP" }, ;
      { "Rio de Janeiro", .F., "RJ" }, ;
      { "Belo Horizonte", .T., "MG" }, ;
      { "Curitiba",       .F., "PR" }, ;
      { "Porto Alegre",   .F., "RS" } }

   INIT DIALOG oDlg TITLE "Teste HCheckList" AT 100, 100 SIZE 400, 340

   @ 20, 20 SAY "Filiais:" SIZE 300, 22

   oChk := HCheckList():New( oDlg, 0, ;
      WS_BORDER + WS_VSCROLL, ;
      20, 50, 340, 200, ;
      aFiliais, ;
      Nil, Nil, Nil, Nil, ;
      { |o, n, lOn| hwg_MsgInfo( "Linha " + Str(n) + ;
                     Iif( lOn, " marcada", " desmarcada" ) ) } )

   @ 20, 270 BUTTON "Mostrar marcados" SIZE 160, 30 ;
      ON CLICK { || hwg_MsgInfo( ;
         "Índices: " + hb_ValToExp( oChk:GetChecked() ) + Chr(10) + ;
         "Itens:   " + hb_ValToExp( oChk:GetCheckedItems() ) + Chr(10) + ;
         "Valores: " + hb_ValToExp( oChk:GetCheckedValues() ) ) }

   @ 200, 270 BUTTON "Fechar" SIZE 100, 30 ;
      ON CLICK { || oDlg:Close() }

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil
