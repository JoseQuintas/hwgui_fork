#include "hwgui.ch"
#include "hbdyn.ch"

STATIC pLib     := NIL
STATIC hWebView := NIL
STATIC nWebViewID := 1

//=============================================================================
FUNCTION Main()
   LOCAL oForm

   hb_cdpSelect( "UTF8" )

   // Create the DBF if it doesn't exist yet
   IF !File( "clientes.dbf" )
      DbCreate( "clientes.dbf", { ;
         { "NOME",  "C",  60, 0 }, ;
         { "EMAIL", "C",  80, 0 } } )
   ENDIF

   pLib := hb_LibLoad( "webview_wrapper.dll" )
   IF pLib == NIL
      hwg_MsgStop( "hb_LibLoad failed" )
      RETURN NIL
   ENDIF

   INIT WINDOW oForm TITLE "HwguiTurbo - Cadastro de Clientes" SIZE 900, 700 ;
      ON INIT { || InicializaWebView( oForm ) } ;
      ON EXIT { || FinalizaWebView() }
/*
   MENU OF oForm
      MENU TITLE "&Arquivo"
         MENUITEM "Sai&r" ACTION oForm:Close()
      ENDMENU
      MENU TITLE "A&juda"
         MENUITEM "&Sobre..." ACTION hwg_MsgInfo( "HwguiTurbo v1.2.0" )
      ENDMENU
   ENDMENU
*/
   // Capture WM_USER+100 sent by C via PostMessage
   oForm:bOther := { |o, msg, wp, lp| OnOtherMsg( o, msg, wp, lp ) }

   ACTIVATE WINDOW oForm CENTER

   IF pLib != NIL
      hb_LibFree( pLib )
   ENDIF
RETURN NIL

//=============================================================================
STATIC FUNCTION OnOtherMsg( o, nMsg, nLParam )
   IF nMsg == 1124
      CheckMensagem( )
      RETURN 0
   ENDIF
RETURN -1

//=============================================================================
STATIC FUNCTION InicializaWebView( oForm )
   LOCAL nBind

   hWebView := hb_DynCall( { "create_webview_embedded", pLib, ;
                             hb_bitOr( HB_DYN_CTYPE_VOID_PTR, HB_DYN_CALLCONV_CDECL ), ;
                             HB_DYN_CTYPE_CHAR_PTR, ;
                             HB_DYN_CTYPE_CHAR_PTR, ;
                             HB_DYN_CTYPE_INT, ;
                             HB_DYN_CTYPE_INT, ;
                             HB_DYN_CTYPE_INT }, ;
                           "HwguiTurbo - Cadastro de Clientes", "WebView2", 900, 660, ;
                           nWebViewID )

   IF hWebView == NIL
      hwg_MsgStop( "Failed to create WebView" )
      RETURN NIL
   ENDIF

   // Single bind - all actions pass through here
   nBind := BindJS( "ExecutarAcao" )
   IF nBind != 0
      hwg_MsgStop( "bind failed: " + hb_ValToStr( nBind ) )
   ENDIF

   hb_DynCall( { "navigate_webview", pLib, ;
                 hb_bitOr( HB_DYN_CTYPE_VOID, HB_DYN_CALLCONV_CDECL ), ;
                 HB_DYN_CTYPE_VOID_PTR, ;
                 HB_DYN_CTYPE_CHAR_PTR }, ;
               hWebView, "file:///C:/dev/hwgui/contrib/webview2/clientes.html" )
RETURN NIL

//=============================================================================
STATIC FUNCTION BindJS( cName )
RETURN hb_DynCall( { "bind_webview", pLib, ;
                     hb_bitOr( HB_DYN_CTYPE_INT, HB_DYN_CALLCONV_CDECL ), ;
                     HB_DYN_CTYPE_VOID_PTR, ;
                     HB_DYN_CTYPE_CHAR_PTR }, ;
                   hWebView, cName )

//=============================================================================
STATIC FUNCTION EvalJS( cJs )
RETURN hb_DynCall( { "eval_webview", pLib, ;
                     hb_bitOr( HB_DYN_CTYPE_INT, HB_DYN_CALLCONV_CDECL ), ;
                     HB_DYN_CTYPE_VOID_PTR, ;
                     HB_DYN_CTYPE_CHAR_PTR }, ;
                   hWebView, cJs )

//=============================================================================
STATIC FUNCTION CheckMensagem()
   LOCAL hCtx, cId, cJson, cFunc, cResult

   IF hWebView == NIL
      RETURN NIL
   ENDIF

   // Como so temos 1 WebView, o ID e' sempre 1
   hCtx := hb_DynCall( { "get_context_by_id", pLib, ;
                         hb_bitOr( HB_DYN_CTYPE_VOID_PTR, HB_DYN_CALLCONV_CDECL ), ;
                         HB_DYN_CTYPE_INT }, 1 )

   IF hCtx == NIL
      hwg_MsgStop( "Context not found" )
      RETURN NIL
   ENDIF

   cId := hb_DynCall( { "get_message_id", pLib, ;
                        hb_bitOr( HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CALLCONV_CDECL ), ;
                        HB_DYN_CTYPE_VOID_PTR }, hCtx )
   IF ValType( cId ) == "A" .AND. Len( cId ) >= 1
      cId := cId[1]
   ENDIF
   IF cId == NIL .OR. Empty( cId )
      RETURN NIL
   ENDIF

   cFunc := hb_DynCall( { "get_message_func", pLib, ;
                          hb_bitOr( HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CALLCONV_CDECL ), ;
                          HB_DYN_CTYPE_VOID_PTR }, hCtx )
   IF ValType( cFunc ) == "A" .AND. Len( cFunc ) >= 1
      cFunc := cFunc[1]
   ENDIF

   cJson := hb_DynCall( { "get_message_data", pLib, ;
                          hb_bitOr( HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CALLCONV_CDECL ), ;
                          HB_DYN_CTYPE_VOID_PTR }, hCtx )
   IF ValType( cJson ) == "A" .AND. Len( cJson ) >= 1
      cJson := cJson[1]
   ENDIF

   cResult := Despachar( cFunc, cJson )

   hb_DynCall( { "reply_webview", pLib, ;
                 hb_bitOr( HB_DYN_CTYPE_INT, HB_DYN_CALLCONV_CDECL ), ;
                 HB_DYN_CTYPE_VOID_PTR, ;
                 HB_DYN_CTYPE_CHAR_PTR }, ;
               hCtx, cResult )
RETURN NIL

//=============================================================================
STATIC FUNCTION Despachar( cFunc, cJson )
   LOCAL hParams, cAcao, hArgs

   HB_SYMBOL_UNUSED( cFunc )

   hParams := hb_jsonDecode( cJson )
   IF ValType( hParams ) == "A" .AND. Len( hParams ) >= 1
      hParams := hParams[1]
   ENDIF
   IF ValType( hParams ) != "H"
      hParams := {=>}
   ENDIF

   cAcao := hb_HGetDef( hParams, "acao", "" )
   hArgs := hb_HGetDef( hParams, "args", {=>} )
   IF ValType( hArgs ) != "H"
      hArgs := {=>}
   ENDIF

   DO CASE
   CASE cAcao == "cliente.gravar"
      RETURN GravarCliente( hArgs )
   CASE cAcao == "cliente.listar"
      RETURN ListarClientes( hArgs )
   CASE cAcao == "cliente.apagar"
      RETURN ApagarCliente( hArgs )
   CASE cAcao == "cliente.buscar"
      RETURN BuscarCliente( hArgs )
   CASE cAcao == "cliente.resumo"
      RETURN ResumoClientes()
   CASE cAcao == "demo.contar"
      RETURN DemoContar( hArgs )
   ENDCASE

RETURN hb_jsonEncode( { "ok" => .F., "msg" => "Unknown action: " + cAcao } )

//=============================================================================
STATIC FUNCTION GravarCliente( hDados )
   LOCAL cNome  := hb_HGetDef( hDados, "nome",  "" )
   LOCAL cEmail := hb_HGetDef( hDados, "email", "" )
   LOCAL nRecno

   IF Empty( cNome )
      RETURN hb_jsonEncode( { "ok" => .F., "msg" => "Name is required" } )
   ENDIF

   AbreClientes()

   clientes->( DbAppend() )
   REPLACE clientes->NOME  WITH cNome
   REPLACE clientes->EMAIL WITH cEmail
   nRecno := clientes->( RecNo() )
   clientes->( DbCommit() )

RETURN hb_jsonEncode( { "ok" => .T., "recno" => nRecno } )

//=============================================================================
STATIC FUNCTION ListarClientes( hDados )
   LOCAL nPagina     := hb_HGetDef( hDados, "pagina",     1 )
   LOCAL nPorPagina  := hb_HGetDef( hDados, "por_pagina", 50 )
   LOCAL aLista      := {}
   LOCAL nTotal      := 0
   LOCAL nTotalPag   := 0
   LOCAL nSkip
   LOCAL i

   nPagina    := IIF( nPagina    < 1, 1,  nPagina    )
   nPorPagina := IIF( nPorPagina < 1, 50, nPorPagina )

   AbreClientes()

   // Count the total (including deleted)
   clientes->( DbGoTop() )
   DO WHILE !clientes->( Eof() )
      nTotal++
      clientes->( DbSkip() )
   ENDDO

   nTotalPag := Int( ( nTotal + nPorPagina - 1 ) / nPorPagina )
   IF nTotalPag < 1
      nTotalPag := 1
   ENDIF
   IF nPagina > nTotalPag
      nPagina := nTotalPag
   ENDIF

   nSkip := ( nPagina - 1 ) * nPorPagina
   clientes->( DbGoTop() )
   IF nSkip > 0
      clientes->( DbSkip( nSkip ) )
   ENDIF

   i := 0
   DO WHILE !clientes->( Eof() ) .AND. i < nPorPagina
      AAdd( aLista, { "recno"   => clientes->( RecNo() ), ;
                      "nome"    => AllTrim( clientes->NOME ), ;
                      "email"   => AllTrim( clientes->EMAIL ), ;
                      "deleted" => clientes->( Deleted() ) } )
      clientes->( DbSkip() )
      i++
   ENDDO

RETURN hb_jsonEncode( { "ok"         => .T., ;
                        "clientes"   => aLista, ;
                        "pagina"     => nPagina, ;
                        "por_pagina" => nPorPagina, ;
                        "total"      => nTotal, ;
                        "total_pag"  => nTotalPag } )

//=============================================================================
STATIC FUNCTION ApagarCliente( hDados )
   LOCAL nRecno := hb_HGetDef( hDados, "recno", 0 )

   IF nRecno <= 0
      RETURN hb_jsonEncode( { "ok" => .F., "msg" => "Invalid RECNO" } )
   ENDIF

   AbreClientes()
   clientes->( DbGoTo( nRecno ) )
   IF !clientes->( Eof() )
      IF clientes->( Deleted() )
         clientes->( DbRecall() )      // restore
      ELSE
         clientes->( DbDelete() )      // mark as deleted
      ENDIF
      clientes->( DbCommit() )
      RETURN hb_jsonEncode( { "ok" => .T. } )
   ENDIF

RETURN hb_jsonEncode( { "ok" => .F., "msg" => "Record not found" } )

//=============================================================================
STATIC FUNCTION BuscarCliente( hDados )
   LOCAL cNome      := hb_HGetDef( hDados, "nome",       "" )
   LOCAL nPagina    := hb_HGetDef( hDados, "pagina",     1 )
   LOCAL nPorPagina := hb_HGetDef( hDados, "por_pagina", 50 )
   LOCAL aLista     := {}
   LOCAL aMatches   := {}
   LOCAL nTotal     := 0
   LOCAL nTotalPag  := 0
   LOCAL nSkip
   LOCAL i
   LOCAL nIdx

   nPagina    := IIF( nPagina    < 1, 1,  nPagina    )
   nPorPagina := IIF( nPorPagina < 1, 50, nPorPagina )

   AbreClientes()

   // Collect matching RECNOs
   clientes->( DbGoTop() )
   DO WHILE !clientes->( Eof() )
      IF Upper( cNome ) $ Upper( AllTrim( clientes->NOME ) )
         AAdd( aMatches, clientes->( RecNo() ) )
      ENDIF
      clientes->( DbSkip() )
   ENDDO

   nTotal := Len( aMatches )
   nTotalPag := Int( ( nTotal + nPorPagina - 1 ) / nPorPagina )
   IF nTotalPag < 1
      nTotalPag := 1
   ENDIF
   IF nPagina > nTotalPag
      nPagina := nTotalPag
   ENDIF

   nSkip := ( nPagina - 1 ) * nPorPagina

   FOR i := 1 TO nPorPagina
      nIdx := nSkip + i
      IF nIdx > nTotal
         EXIT
      ENDIF
      clientes->( DbGoTo( aMatches[ nIdx ] ) )
      AAdd( aLista, { "recno"   => clientes->( RecNo() ), ;
                      "nome"    => AllTrim( clientes->NOME ), ;
                      "email"   => AllTrim( clientes->EMAIL ), ;
                      "deleted" => clientes->( Deleted() ) } )
   NEXT

RETURN hb_jsonEncode( { "ok"         => .T., ;
                        "clientes"   => aLista, ;
                        "pagina"     => nPagina, ;
                        "por_pagina" => nPorPagina, ;
                        "total"      => nTotal, ;
                        "total_pag"  => nTotalPag } )

//=============================================================================
STATIC FUNCTION ResumoClientes()
   LOCAL nAtivos   := 0
   LOCAL nDelet    := 0
   LOCAL nComEmail := 0
   LOCAL nUltimo   := 0
   LOCAL nRecno

   AbreClientes()
   clientes->( DbGoTop() )
   DO WHILE !clientes->( Eof() )
      nRecno := clientes->( RecNo() )
      IF nRecno > nUltimo
         nUltimo := nRecno
      ENDIF
      IF clientes->( Deleted() )
         nDelet++
      ELSE
         nAtivos++
         IF !Empty( AllTrim( clientes->EMAIL ) )
            nComEmail++
         ENDIF
      ENDIF
      clientes->( DbSkip() )
   ENDDO

RETURN hb_jsonEncode( { "ok"           => .T., ;
                        "ativos"       => nAtivos, ;
                        "deletados"    => nDelet, ;
                        "com_email"    => nComEmail, ;
                        "ultimo_recno" => nUltimo } )

//=============================================================================
// DEMO CALLBACK — Harbour loops and calls back the JS at each iteration
//=============================================================================
STATIC FUNCTION DemoContar( hDados )
   LOCAL cCallbackId := hb_HGetDef( hDados, "callbackId", "" )
   LOCAL nTotal      := hb_HGetDef( hDados, "total", 10 )
   LOCAL i, cJs, nPct

   IF Empty( cCallbackId )
      RETURN hb_jsonEncode( { "ok" => .F., "msg" => "callbackId missing" } )
   ENDIF

   FOR i := 1 TO nTotal
      // Simulate work - replace with real processing
      hb_idleSleep( 0.3 )

      nPct := Int( i * 100 / nTotal )

      // Call the JavaScript callback registered by the client
      cJs := "window._hwgui.invoke('" + cCallbackId + "', " + ;
             hb_NToS( nPct ) + ")"
      EvalJS( cJs )
   NEXT

RETURN hb_jsonEncode( { "ok" => .T. } )

//=============================================================================
STATIC FUNCTION AbreClientes()
   IF !Used()
      IF !File( "clientes.dbf" )
         DbCreate( "clientes.dbf", { ;
            { "NOME",  "C",  60, 0 }, ;
            { "EMAIL", "C",  80, 0 } } )
      ENDIF
      USE clientes.dbf ALIAS clientes NEW
   ENDIF
RETURN NIL

//=============================================================================
STATIC FUNCTION FinalizaWebView()
   IF hWebView != NIL
      hb_DynCall( { "destroy_webview", pLib, ;
                    hb_bitOr( HB_DYN_CTYPE_VOID, HB_DYN_CALLCONV_CDECL ), ;
                    HB_DYN_CTYPE_VOID_PTR }, ;
                  hWebView )
      hWebView := NIL
   ENDIF
RETURN NIL
