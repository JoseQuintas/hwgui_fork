#include "hwgui.ch"
#include "hbdyn.ch"
#include "hbsocket.ch"

#ifndef HB_NO_SOCKET
   #define HB_NO_SOCKET -1
#endif

STATIC pLib        := NIL
STATIC hWebView    := NIL
STATIC nWebViewID  := 1
STATIC sockSrv     := NIL
STATIC cMeuNome    := ""
STATIC cSrvIP      := "127.0.0.1"
STATIC nSrvPort    := 9999
STATIC lStopCli    := .F.

STATIC hMutexCli    := NIL
STATIC aFilaEventos := {}
STATIC cArqLogCli   := ""
STATIC hFormWnd     := NIL
STATIC pUser32      := NIL

#define WM_WEBVIEW  1124
#define WM_SOCKMSG  1125
#define SEP_B64     Chr(1)

//=============================================================================
FUNCTION Main()
   LOCAL oForm
   hb_cdpSelect( "UTF8" )
   cArqLogCli := "user_debug_" + LTrim(Str(hb_MilliSeconds())) + "_" + ;
                 LTrim(Str(hb_RandomInt(100,999))) + ".log"
   LeConfig()

   hMutexCli := hb_mutexCreate()
   pUser32   := hb_LibLoad( "user32.dll" )

   pLib := hb_LibLoad( "webview_wrapper.dll" )
   IF pLib == NIL ; hwg_MsgStop( "hb_LibLoad failed" ) ; RETURN NIL ; ENDIF

   hb_idleAdd( { || DrenaFilaEventos() } )

   sockSrv := TcpConnect( cSrvIP, nSrvPort )
   IF !hb_inetIsSocket( sockSrv )
      hwg_MsgStop( "Could not connect to " + cSrvIP + ":" + LTrim(Str(nSrvPort)) )
      RETURN NIL
   ENDIF
   hb_threadStart( @ThreadReceptor(), sockSrv )

   INIT WINDOW oForm TITLE "Corporate Chat" SIZE 1050, 720 ;
      ON EXIT { || Finaliza() }

   MENU OF oForm
      MENU TITLE "&File"
         MENUITEM "E&xit" ACTION oForm:Close()
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About..." ACTION hwg_MsgInfo( "Corporate Chat v1.0" + Chr(10) + ;
                                                  "Server: " + cSrvIP + ":" + LTrim(Str(nSrvPort)) )
      ENDMENU
   ENDMENU

   oForm:bOther    := { |o,msg,wp,lp| OnOtherMsg(o,msg,wp,lp) }
   oForm:bActivate := { || InitWebView( oForm ) }
   ACTIVATE WINDOW oForm CENTER

   IF pLib != NIL    ; hb_LibFree( pLib )    ; ENDIF
   IF pUser32 != NIL ; hb_LibFree( pUser32 ) ; ENDIF
RETURN NIL

//=============================================================================
STATIC FUNCTION LeConfig()
   LOCAL cIni := hb_DirBase() + "user.ini"
   LOCAL aLinhas, cLinha, nP, cChave, cValor, cSecaoAtual := ""

   IF !File( cIni ) ; RETURN NIL ; ENDIF

   aLinhas := hb_ATokens( MemoRead( cIni ), Chr(10) )

   FOR EACH cLinha IN aLinhas
      cLinha := AllTrim( cLinha )
      IF Empty( cLinha ) .OR. Left( cLinha, 1 ) $ ";#" ; LOOP ; ENDIF

      IF Left( cLinha, 1 ) == "[" .AND. Right( cLinha, 1 ) == "]"
         cSecaoAtual := Upper( SubStr( cLinha, 2, Len( cLinha ) - 2 ) )
         LOOP
      ENDIF

      nP := At( "=", cLinha )
      IF nP > 0 .AND. cSecaoAtual == "SERVER"
         cChave := Upper( AllTrim( Left( cLinha, nP - 1 ) ) )
         cValor := AllTrim( SubStr( cLinha, nP + 1 ) )
         DO CASE
         CASE cChave == "IP"   ; cSrvIP   := cValor
         CASE cChave == "PORT" ; nSrvPort := Val( cValor )
         ENDCASE
      ENDIF
   NEXT
RETURN NIL

//=============================================================================
STATIC FUNCTION LogCli( cMsg )
   LOCAL cOld := "", cArq := IIF( Empty(cArqLogCli), "user_debug.log", cArqLogCli )
   IF File( cArq ) ; cOld := MemoRead( cArq ) ; ENDIF
   MemoWrit( cArq, cOld + DToC(Date())+" "+Time()+" "+cMsg+Chr(10) )
RETURN NIL

//=============================================================================
STATIC FUNCTION OnOtherMsg( o, nMsg, nWParam, nLParam )
   IF nMsg == WM_WEBVIEW ; CheckMensagem()      ; RETURN 0 ; ENDIF
   IF nMsg == WM_SOCKMSG ; DrenaFilaEventos() ; RETURN 0 ; ENDIF
RETURN -1

//=============================================================================
STATIC FUNCTION InitWebView( oForm )
   LOCAL nBind
   hFormWnd := oForm:handle
   LogCli( "InitWebView: hFormWnd=" + hb_ValToStr( hFormWnd ) )

   hWebView := hb_DynCall( { "create_webview_embedded", pLib, ;
      hb_bitOr(HB_DYN_CTYPE_VOID_PTR, HB_DYN_CALLCONV_CDECL), ;
      HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CTYPE_CHAR_PTR, ;
      HB_DYN_CTYPE_INT, HB_DYN_CTYPE_INT, HB_DYN_CTYPE_INT }, ;
      "Corporate Chat", "WebView2", 1050, 680, nWebViewID )

   IF hWebView == NIL ; hwg_MsgStop( "WebView failed" ) ; RETURN NIL ; ENDIF

   nBind := BindJS( "ExecutarAcao" )

   hb_DynCall( { "navigate_webview", pLib, ;
      hb_bitOr(HB_DYN_CTYPE_VOID, HB_DYN_CALLCONV_CDECL), ;
      HB_DYN_CTYPE_VOID_PTR, HB_DYN_CTYPE_CHAR_PTR }, ;
      hWebView, "file:///"+hb_DirBase()+"user.html?v=" + ;
                LTrim(Str(hb_MilliSeconds())) )
RETURN NIL

//=============================================================================
STATIC FUNCTION PostMsgUI()
   IF pUser32 == NIL .OR. hFormWnd == NIL ; RETURN NIL ; ENDIF

   hb_DynCall( { "PostMessageA", pUser32, ;
      hb_bitOr( HB_DYN_CTYPE_INT, HB_DYN_CALLCONV_STDCALL ), ;
      HB_DYN_CTYPE_VOID_PTR, ;
      HB_DYN_CTYPE_LONG, ;
      HB_DYN_CTYPE_LONG, ;
      HB_DYN_CTYPE_LONG }, ;
      hFormWnd, WM_SOCKMSG, 0, 0 )
RETURN NIL

//=============================================================================
STATIC FUNCTION ThreadReceptor( sd )
   LOCAL cBuf := Space( 65536 )
   LOCAL cAcc := "", cLine, nPos, nBytes

   LogCli( "ThreadReceptor: STARTED" )

   DO WHILE !lStopCli
      IF hb_inetDataReady( sd, 500 ) == 1

         nBytes := hb_inetRecv( sd, @cBuf, 65536 )

         IF nBytes > 0
            cAcc += Left( cBuf, nBytes )
            DO WHILE ( nPos := At( Chr(10), cAcc ) ) > 0
               cLine := Left( cAcc, nPos - 1 )
               cAcc  := SubStr( cAcc, nPos + 1 )
               cLine := StrTran( cLine, Chr(13), "" )
               IF !Empty( cLine )
                  hb_mutexLock( hMutexCli )
                  AAdd( aFilaEventos, cLine )
                  hb_mutexUnlock( hMutexCli )
                  PostMsgUI()
               ENDIF
            ENDDO
         ELSEIF hb_inetErrorCode( sd ) != 0
            EXIT
         ENDIF
      ENDIF
   ENDDO

   hb_inetClose( sd )
   sockSrv := HB_NO_SOCKET
RETURN NIL

//=============================================================================
STATIC FUNCTION DrenaFilaEventos()
   LOCAL aLocal, cLinha

   hb_mutexLock( hMutexCli )
   IF Empty( aFilaEventos )
      hb_mutexUnlock( hMutexCli )
      RETURN NIL
   ENDIF
   aLocal := aFilaEventos
   aFilaEventos := {}
   hb_mutexUnlock( hMutexCli )

   IF hWebView == NIL
      LogCli( "DrenaFilaEventos: hWebView NIL, discarding " + LTrim(Str(Len(aLocal))) )
      RETURN NIL
   ENDIF

   FOR EACH cLinha IN aLocal
      ProcessaMsg( cLinha )
   NEXT
RETURN NIL

//=============================================================================
STATIC FUNCTION ProcessaMsg( cLine )
   LOCAL hMsg, cCmd, nSep, cPayload, cId, cJs, cB64

   nSep := At( SEP_B64, cLine )
   IF nSep > 0
      cPayload := SubStr( cLine, nSep + 1 )
      cLine    := Left( cLine, nSep - 1 )
   ENDIF

   hMsg := hb_jsonDecode( cLine )
   IF ValType(hMsg) == "A" .AND. Len(hMsg) >= 1 ; hMsg := hMsg[1] ; ENDIF
   IF ValType(hMsg) != "H" ; RETURN NIL ; ENDIF

   cCmd := hb_HGetDef( hMsg, "cmd", "" )

   DO CASE
   CASE cCmd == "list"
      PushEvent( "usr.list", hb_HGetDef( hMsg, "users", {} ) )

   CASE cCmd == "presence"
      PushEvent( "usr.presence", { ;
         "user"  => hb_HGetDef( hMsg, "user",  "" ), ;
         "on"    => hb_HGetDef( hMsg, "on",    .F. ), ;
         "emoji" => hb_HGetDef( hMsg, "emoji", "" ) } )

   CASE cCmd == "msg"
      AvisarNovaMsg()
      PushEvent( "msg.recv", { ;
         "from" => hb_HGetDef( hMsg, "from", "" ), ;
         "text" => hb_HGetDef( hMsg, "text", "" ), ;
         "hora" => DToC( Date() ) + " " + Time() } )

   CASE cCmd == "sent"
      PushEvent( "msg.sent", hb_HGetDef( hMsg, "to", "" ) )

   CASE cCmd == "file.start"
      PushEvent( "file.start", { ;
         "from" => hb_HGetDef( hMsg, "from", "" ), ;
         "id"   => hb_HGetDef( hMsg, "id",   "" ), ;
         "name" => hb_HGetDef( hMsg, "name", "" ), ;
         "size" => hb_HGetDef( hMsg, "size", 0 ), ;
         "mime" => hb_HGetDef( hMsg, "mime", "" ) } )

   CASE cCmd == "file.chunk"
      cId  := hb_HGetDef( hMsg, "id", "" )
      cB64 := cPayload

      LogCli( "RECV file.chunk id=" + cId + ;
              " i=" + LTrim(Str(hb_HGetDef(hMsg,"i",0))) + ;
              " b64len=" + LTrim(Str(Len(cB64))) )

      cJs := 'window._hwgui.event("file.chunk",{"id":"' + cId + ;
             '","i":' + LTrim(Str(hb_HGetDef(hMsg,"i",0))) + ;
             ',"data":"' + cB64 + '"})'
      EvalJS( cJs )

   CASE cCmd == "file.end"
      PushEvent( "file.end", hb_HGetDef( hMsg, "id", "" ) )

   CASE cCmd == "file.sent"
      PushEvent( "file.sent", hb_HGetDef( hMsg, "id", "" ) )

   CASE cCmd == "error"
      PushEvent( "erro", hb_HGetDef( hMsg, "msg", "" ) )
   ENDCASE
RETURN NIL

//=============================================================================
STATIC FUNCTION AvisarNovaMsg()
   IF pUser32 != NIL .AND. hFormWnd != NIL
      hb_threadStart( @ThreadPiscar() )
   ENDIF
RETURN NIL

STATIC FUNCTION ThreadPiscar()
   LOCAL i
   FOR i := 1 TO 6
      hb_DynCall( { "FlashWindow", pUser32, ;
         hb_bitOr(HB_DYN_CTYPE_INT, HB_DYN_CALLCONV_STDCALL), ;
         HB_DYN_CTYPE_VOID_PTR, HB_DYN_CTYPE_INT }, hFormWnd, 1 )
      hb_idleSleep( 0.4 )
   NEXT
   hb_DynCall( { "FlashWindow", pUser32, ;
      hb_bitOr(HB_DYN_CTYPE_INT, HB_DYN_CALLCONV_STDCALL), ;
      HB_DYN_CTYPE_VOID_PTR, HB_DYN_CTYPE_INT }, hFormWnd, 0 )
RETURN NIL

//=============================================================================
STATIC FUNCTION PushEvent( cEvento, xData )
   LOCAL cJs := "window._hwgui.event(" + hb_jsonEncode(cEvento) + "," + ;
                hb_jsonEncode(xData) + ")"
   LOCAL nRet := EvalJS( cJs )
   LogCli( "PushEvent " + cEvento + " ret=" + hb_ValToStr(nRet) )
RETURN NIL

//=============================================================================
STATIC FUNCTION BindJS( cName )
RETURN hb_DynCall( { "bind_webview", pLib, ;
   hb_bitOr(HB_DYN_CTYPE_INT, HB_DYN_CALLCONV_CDECL), ;
   HB_DYN_CTYPE_VOID_PTR, HB_DYN_CTYPE_CHAR_PTR }, hWebView, cName )

STATIC FUNCTION EvalJS( cJs )
RETURN hb_DynCall( { "eval_webview", pLib, ;
   hb_bitOr(HB_DYN_CTYPE_INT, HB_DYN_CALLCONV_CDECL), ;
   HB_DYN_CTYPE_VOID_PTR, HB_DYN_CTYPE_CHAR_PTR }, hWebView, cJs )

//=============================================================================
STATIC FUNCTION CheckMensagem()
   LOCAL hCtx, cId, cJson, cFunc, cResult
   IF hWebView == NIL ; RETURN NIL ; ENDIF
   hCtx := hb_DynCall( { "get_context_by_id", pLib, ;
      hb_bitOr(HB_DYN_CTYPE_VOID_PTR, HB_DYN_CALLCONV_CDECL), ;
      HB_DYN_CTYPE_INT }, nWebViewID )
   IF hCtx == NIL ; RETURN NIL ; ENDIF

   cId := hb_DynCall( { "get_message_id", pLib, ;
      hb_bitOr(HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CALLCONV_CDECL), ;
      HB_DYN_CTYPE_VOID_PTR }, hCtx )
   IF ValType(cId)=="A" .AND. Len(cId)>=1 ; cId := cId[1] ; ENDIF
   IF cId == NIL .OR. Empty(cId) ; RETURN NIL ; ENDIF

   cFunc := hb_DynCall( { "get_message_func", pLib, ;
      hb_bitOr(HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CALLCONV_CDECL), ;
      HB_DYN_CTYPE_VOID_PTR }, hCtx )
   IF ValType(cFunc)=="A" .AND. Len(cFunc)>=1 ; cFunc := cFunc[1] ; ENDIF

   cJson := hb_DynCall( { "get_message_data", pLib, ;
      hb_bitOr(HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CALLCONV_CDECL), ;
      HB_DYN_CTYPE_VOID_PTR }, hCtx )
   IF ValType(cJson)=="A" .AND. Len(cJson)>=1 ; cJson := cJson[1] ; ENDIF

   cResult := Dispatch( cFunc, cJson )
   hb_DynCall( { "reply_webview", pLib, ;
      hb_bitOr(HB_DYN_CTYPE_INT, HB_DYN_CALLCONV_CDECL), ;
      HB_DYN_CTYPE_VOID_PTR, HB_DYN_CTYPE_CHAR_PTR }, hCtx, cResult )
RETURN NIL

//=============================================================================
STATIC FUNCTION Dispatch( cFunc, cJson )
   LOCAL hParams, cAcao, hArgs
   HB_SYMBOL_UNUSED( cFunc )
   hParams := hb_jsonDecode( cJson )
   IF ValType(hParams)=="A" .AND. Len(hParams)>=1 ; hParams := hParams[1] ; ENDIF
   IF ValType(hParams) != "H" ; hParams := {=>} ; ENDIF
   cAcao := hb_HGetDef( hParams, "acao", "" )
   hArgs := hb_HGetDef( hParams, "args", {=>} )
   IF ValType(hArgs) != "H" ; hArgs := {=>} ; ENDIF

   DO CASE
   CASE cAcao == "login"      ; RETURN Login( hArgs )
   CASE cAcao == "msg.send"   ; RETURN MsgSend( hArgs )
   CASE cAcao == "file.start" ; RETURN FileStart( hArgs )
   CASE cAcao == "file.chunk" ; RETURN FileChunk( hArgs )
   CASE cAcao == "file.end"   ; RETURN FileEnd( hArgs )
   CASE cAcao == "meu.nome"   ; RETURN hb_jsonEncode({ "ok"=>.T., "nome"=>cMeuNome })
   ENDCASE
RETURN hb_jsonEncode({ "ok"=>.F., "msg"=>"Unknown action: "+cAcao })

//=============================================================================
STATIC FUNCTION Login( hArgs )
   LOCAL cNome    := AllTrim( hb_HGetDef( hArgs, "nome",  "" ) )
   LOCAL cEmoji   := hb_HGetDef( hArgs, "emoji", "" )
   LOCAL cMaquina := hb_GetEnv( "COMPUTERNAME" )
   LOCAL cUsuario := hb_GetEnv( "USERNAME" )

   IF Empty( cNome ) ; RETURN hb_jsonEncode({ "ok"=>.F., "msg"=>"Name required" }) ; ENDIF
   IF Empty( cMaquina ) ; cMaquina := "?" ; ENDIF
   cMeuNome := cNome

   IF hb_inetIsSocket( sockSrv )
      hb_inetSend( sockSrv, hb_jsonEncode({ ;
         "cmd"     => "login", ;
         "user"    => cNome, ;
         "maquina" => cMaquina, ;
         "usuario" => cUsuario, ;
         "emoji"   => cEmoji })+Chr(10) )
      LogCli( "login sent: " + cNome + " emoji=[" + cEmoji + "]" )
   ENDIF
RETURN hb_jsonEncode({ "ok"=>.T., "nome"=>cNome })

//=============================================================================
STATIC FUNCTION MsgSend( hArgs )
   LOCAL cTo   := AllTrim( hb_HGetDef( hArgs, "to",   "" ) )
   LOCAL cText := AllTrim( hb_HGetDef( hArgs, "text", "" ) )
   IF Empty(cTo) .OR. Empty(cText)
      RETURN hb_jsonEncode({ "ok"=>.F., "msg"=>"Invalid data" })
   ENDIF
   IF hb_inetIsSocket( sockSrv )
      hb_inetSend( sockSrv, hb_jsonEncode({ "cmd"=>"msg", "to"=>cTo, "text"=>cText })+Chr(10) )
   ENDIF
RETURN hb_jsonEncode({ "ok"=>.T. })

//=============================================================================
STATIC FUNCTION FileStart( hArgs )
   LOCAL cTo   := AllTrim( hb_HGetDef( hArgs, "to",   "" ) )
   LOCAL cId   := hb_HGetDef( hArgs, "id",   "" )
   LOCAL cName := hb_HGetDef( hArgs, "name", "" )
   LOCAL cMime := hb_HGetDef( hArgs, "mime", "" )
   LOCAL nSize := hb_HGetDef( hArgs, "size", 0 )

   LogCli( "FileStart -> " + cTo + " id=" + cId + " size=" + LTrim(Str(nSize)) )

   IF hb_inetIsSocket( sockSrv )
      hb_inetSend( sockSrv, hb_jsonEncode({ ;
         "cmd"=>"file.start", "to"=>cTo, "id"=>cId, ;
         "name"=>cName, "mime"=>cMime, "size"=>nSize })+Chr(10) )
   ENDIF
RETURN hb_jsonEncode({ "ok"=>.T. })

//=============================================================================
STATIC FUNCTION FileChunk( hArgs )
   LOCAL cTo   := AllTrim( hb_HGetDef( hArgs, "to",   "" ) )
   LOCAL cId   := hb_HGetDef( hArgs, "id",   "" )
   LOCAL nI    := hb_HGetDef( hArgs, "i",    0 )
   LOCAL cB64  := hb_HGetDef( hArgs, "data", "" )
   LOCAL cLine
   LOCAL nRet
   LOCAL lSock

   lSock := hb_inetIsSocket( sockSrv )
   LogCli( "FileChunk i=" + LTrim(Str(nI)) + ;
           " b64len=" + LTrim(Str(Len(cB64))) + ;
           " isSock=" + hb_ValToStr(lSock) )

   IF lSock
      cLine := hb_jsonEncode({ "cmd"=>"file.chunk", "to"=>cTo, ;
                               "id"=>cId, "i"=>nI }) + SEP_B64 + cB64
      nRet := hb_inetSend( sockSrv, cLine + Chr(10) )
      LogCli( "  send ret=" + hb_ValToStr(nRet) + ;
              " len=" + LTrim(Str(Len(cLine))) + ;
              " err=" + LTrim(Str(hb_inetErrorCode(sockSrv))) )
   ELSE
      LogCli( "  NOT SENT - invalid socket" )
   ENDIF
RETURN hb_jsonEncode({ "ok"=>.T. })

//=============================================================================
STATIC FUNCTION FileEnd( hArgs )
   LOCAL cTo := AllTrim( hb_HGetDef( hArgs, "to", "" ) )
   LOCAL cId := hb_HGetDef( hArgs, "id", "" )

   LogCli( "FileEnd -> " + cTo + " id=" + cId )

   IF hb_inetIsSocket( sockSrv )
      hb_inetSend( sockSrv, hb_jsonEncode({ "cmd"=>"file.end", "to"=>cTo, "id"=>cId })+Chr(10) )
   ENDIF
RETURN hb_jsonEncode({ "ok"=>.T. })

//=============================================================================
STATIC FUNCTION Finaliza()
   lStopCli := .T.
   IF hb_inetIsSocket( sockSrv )
      hb_inetSend( sockSrv, hb_jsonEncode({ "cmd"=>"quit" })+Chr(10) )
      hb_inetClose( sockSrv )
      sockSrv := HB_NO_SOCKET
   ENDIF
   IF hWebView != NIL
      hb_DynCall( { "destroy_webview", pLib, ;
         hb_bitOr(HB_DYN_CTYPE_VOID, HB_DYN_CALLCONV_CDECL), ;
         HB_DYN_CTYPE_VOID_PTR }, hWebView )
      hWebView := NIL
   ENDIF
RETURN NIL

//=============================================================================
STATIC FUNCTION TcpConnect( cHost, nPort )
   LOCAL sd, nErr

   sd := hb_inetConnect( cHost, nPort )
   IF !hb_inetIsSocket( sd )
      LogCli( "connect: invalid socket" )
      RETURN HB_NO_SOCKET
   ENDIF

   nErr := hb_inetErrorCode( sd )
   IF nErr != 0
      hb_inetClose( sd )
      LogCli( "connect FAILED err=" + LTrim(Str(nErr)) )
      RETURN HB_NO_SOCKET
   ENDIF

   LogCli( "connect OK to " + cHost + ":" + LTrim(Str(nPort)) )
RETURN sd
