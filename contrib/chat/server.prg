#include "hwgui.ch"
#include "hbsocket.ch"

#ifndef HB_NO_SOCKET
   #define HB_NO_SOCKET -1
#endif

STATIC hUsers       := {=>}
STATIC hSockets     := {=>}
STATIC hMaquinas    := {=>}
STATIC hEmojis      := {=>}
STATIC hMutex       := NIL
STATIC nPort        := 9999
STATIC oLst
STATIC sdListen     := HB_NO_SOCKET
STATIC aEventos     := {}
STATIC lStop        := .F.
STATIC hFormWnd     := NIL
STATIC oMain        := NIL

#define WM_REFRESH  1125
#define SEP_B64     Chr(1)

//=============================================================================
FUNCTION Main()
   LOCAL oIcon, oTrayMenu, cImageDir := hb_DirBase()
   hb_cdpSelect( "UTF8" )
   hMutex := hb_mutexCreate()

   oIcon := HIcon():AddFile( cImageDir + "server.ico" )

   INIT WINDOW oMain MAIN ICON oIcon APPNAME "Chat Server" ;
      TITLE "Chat Server - port " + LTrim(Str(nPort)) SIZE 620, 560
   @ 10, 10 LISTBOX oLst ITEMS {} SIZE 600, 520

   CONTEXT MENU oTrayMenu
      MENUITEM "Open Window"  ACTION AbrirJanela()
      SEPARATOR
      MENUITEM "E&xit"        ACTION FecharServidor()
      SEPARATOR
      MENUITEM "&About"       ACTION hwg_MsgInfo( "Chat Server v1.0" + hb_eol() + ;
                                                  "Port: " + LTrim(Str(nPort)) )
   ENDMENU

   oMain:InitTray( oIcon, , oTrayMenu, "Chat Server - port " + LTrim(Str(nPort)) )
   oMain:bOther    := { |o,msg,wp,lp| OnOtherMsg(o,msg,wp,lp) }
   oMain:bActivate := { || hFormWnd := oMain:handle }

   LogSrv( "=== Starting server ===" )

   sdListen := hb_inetServer( nPort )
   IF !hb_inetIsSocket( sdListen )
      hwg_MsgStop( "Could not open port " + LTrim(Str(nPort)) )
      RETURN NIL
   ENDIF
   LogSrv( "OK: listening on port " + LTrim(Str(nPort)) )

   hb_threadStart( @ThreadAccept() )
   hb_idleAdd( { || DrenaEventos() } )

   ACTIVATE WINDOW oMain NOSHOW
   oTrayMenu:End()
   lStop := .T.
RETURN NIL

STATIC FUNCTION AbrirJanela()
   IF oMain != NIL
      hwg_ShowWindow( oMain:handle, SW_SHOW )
      hwg_SetForegroundWindow( oMain:handle )
   ENDIF
RETURN NIL

STATIC FUNCTION FecharServidor()
   lStop := .T.
   IF hb_inetIsSocket( sdListen ) ; hb_inetClose( sdListen ) ; ENDIF
   hwg_EndWindow()
RETURN NIL

STATIC FUNCTION LogSrv( cMsg )
   LOCAL cOld := ""
   IF File( "srv_debug.log" ) ; cOld := MemoRead( "srv_debug.log" ) ; ENDIF
   MemoWrit( "srv_debug.log", cOld + DToC(Date())+" "+Time()+" "+cMsg+Chr(10) )
RETURN NIL

STATIC FUNCTION OnOtherMsg( o, nMsg, nWParam, nLParam )
   IF nMsg == WM_REFRESH ; DrenaEventos() ; RETURN 0 ; ENDIF
RETURN -1

STATIC FUNCTION PostRefresh()
   hb_mutexLock( hMutex )
   AAdd( aEventos, "r" )
   hb_mutexUnlock( hMutex )
   IF hFormWnd != NIL ; HWG_POSTMESSAGE( hFormWnd, WM_REFRESH, 0, 0 ) ; ENDIF
RETURN NIL

STATIC FUNCTION DrenaEventos()
   LOCAL aLocal, aItens, cItem
   hb_mutexLock( hMutex )
   IF Empty( aEventos ) ; hb_mutexUnlock( hMutex ) ; RETURN NIL ; ENDIF
   aLocal := aEventos ; aEventos := {}
   hb_mutexUnlock( hMutex )

   aItens := ListaUsuariosDetalhado()
   oLst:Clear()
   FOR EACH cItem IN aItens ; oLst:AddItems( cItem ) ; NEXT
RETURN NIL

STATIC FUNCTION ThreadAccept()
   LOCAL sdCli
   LogSrv( "Accept thread started" )
   DO WHILE !lStop
      sdCli := hb_inetAccept( sdListen, 1000 )
      IF hb_inetIsSocket( sdCli )
         LogSrv( "client connected" )
         hb_mutexLock( hMutex ) ; hSockets[ sdCli ] := "" ; hb_mutexUnlock( hMutex )
         hb_threadStart( @ThreadCliente(), sdCli )
      ENDIF
   ENDDO
RETURN NIL

//=============================================================================
STATIC FUNCTION ThreadCliente( sdCli )
   LOCAL cBuf := Space( 65536 )
   LOCAL cAcc := "", cLine, nPos, nBytes

   DO WHILE !lStop
      IF hb_inetDataReady( sdCli, 500 ) == 1
         nBytes := hb_inetRecv( sdCli, @cBuf, 65536 )
         IF nBytes > 0
            cAcc += Left( cBuf, nBytes )
            DO WHILE ( nPos := At( Chr(10), cAcc ) ) > 0
               cLine := Left( cAcc, nPos - 1 )
               cAcc  := SubStr( cAcc, nPos + 1 )
               cLine := StrTran( cLine, Chr(13), "" )
               IF !Empty( cLine )
                  ProcessaMsg( sdCli, cLine )
               ENDIF
            ENDDO
         ELSEIF hb_inetErrorCode( sdCli ) != 0
            EXIT
         ENDIF
      ENDIF
   ENDDO
   DisconnectClient( sdCli )
RETURN NIL

STATIC FUNCTION DisconnectClient( sdCli )
   LOCAL cUser
   hb_mutexLock( hMutex )
   cUser := hb_HGetDef( hSockets, sdCli, "" )
   IF !Empty( cUser )
      hUsers[ cUser ] := NIL
      hb_HDel( hMaquinas, cUser )
      hb_HDel( hEmojis,   cUser )
      hb_mutexUnlock( hMutex )
      BroadcastPresence( cUser, .F., sdCli )
      hb_mutexLock( hMutex )
      LogSrv( "logout: " + cUser )
   ENDIF
   hb_HDel( hSockets, sdCli )
   hb_mutexUnlock( hMutex )
   hb_inetClose( sdCli )
   PostRefresh()
RETURN NIL

//=============================================================================
STATIC FUNCTION ProcessaMsg( sdCli, cLine )
   LOCAL hMsg, cCmd, cUser, cMaquina, cEmoji, cTo, cText, sdDest, cId
   LOCAL nSep, cPayload

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
   CASE cCmd == "login"
      cUser    := AllTrim( hb_HGetDef( hMsg, "user",    "" ) )
      cMaquina := AllTrim( hb_HGetDef( hMsg, "maquina", "" ) )
      cEmoji   := AllTrim( hb_HGetDef( hMsg, "emoji",   "" ) )
      IF Empty( cUser ) ; RETURN NIL ; ENDIF

      hb_mutexLock( hMutex )
      IF hb_HGetDef( hUsers, cUser, NIL ) != NIL
         hb_mutexUnlock( hMutex )
         SendLine( sdCli, hb_jsonEncode({ "cmd"=>"error", "msg"=>"Name already in use" }) )
         LogSrv( "login REJECTED: " + cUser )
         RETURN NIL
      ENDIF
      hSockets[ sdCli ]  := cUser
      hUsers[ cUser ]    := sdCli
      hMaquinas[ cUser ] := IIF( Empty(cMaquina), "?", cMaquina )
      hEmojis[ cUser ]   := cEmoji
      hb_mutexUnlock( hMutex )

      LogSrv( "login OK: " + cUser + " emoji=" + cEmoji + " machine=" + cMaquina )
      SendLine( sdCli, hb_jsonEncode({ "cmd"=>"list", "users"=>ListaUsuariosJson() }) )
      BroadcastPresence( cUser, .T., sdCli )
      PostRefresh()

   CASE cCmd == "msg"
      hb_mutexLock( hMutex )
      cUser  := hb_HGetDef( hSockets, sdCli, "" )
      cTo    := AllTrim( hb_HGetDef( hMsg, "to", "" ) )
      cText  := hb_HGetDef( hMsg, "text", "" )
      sdDest := hb_HGetDef( hUsers, cTo, NIL )
      hb_mutexUnlock( hMutex )

      IF Empty( cUser ) .OR. Empty( cTo ) .OR. Empty( cText ) ; RETURN NIL ; ENDIF

      IF sdDest == NIL
         SendLine( sdCli, hb_jsonEncode({ "cmd"=>"error", "msg"=>cTo+" is offline" }) )
      ELSE
         SendLine( sdDest, hb_jsonEncode({ "cmd"=>"msg", "from"=>cUser, "text"=>cText }) )
         SendLine( sdCli,  hb_jsonEncode({ "cmd"=>"sent", "to"=>cTo }) )
      ENDIF

   CASE cCmd == "file.start"
      hb_mutexLock( hMutex )
      cUser  := hb_HGetDef( hSockets, sdCli, "" )
      cTo    := AllTrim( hb_HGetDef( hMsg, "to", "" ) )
      sdDest := hb_HGetDef( hUsers, cTo, NIL )
      hb_mutexUnlock( hMutex )

      IF Empty( cUser ) .OR. Empty( cTo ) .OR. sdDest == NIL
         SendLine( sdCli, hb_jsonEncode({ "cmd"=>"error", "msg"=>"destination offline" }) )
         RETURN NIL
      ENDIF

      cId := hb_HGetDef( hMsg, "id", "" )
      LogSrv( "file.start " + cUser + " -> " + cTo + " id=" + cId )

      SendLine( sdDest, hb_jsonEncode({ ;
         "cmd"  => "file.start", ;
         "from" => cUser, ;
         "id"   => cId, ;
         "name" => hb_HGetDef( hMsg, "name", "file" ), ;
         "size" => hb_HGetDef( hMsg, "size", 0 ), ;
         "mime" => hb_HGetDef( hMsg, "mime", "application/octet-stream" ) }) )

   CASE cCmd == "file.chunk"
      hb_mutexLock( hMutex )
      sdDest := hb_HGetDef( hUsers, AllTrim( hb_HGetDef( hMsg, "to", "" ) ), NIL )
      hb_mutexUnlock( hMutex )

      IF sdDest != NIL
         SendLine( sdDest, cLine + SEP_B64 + cPayload )
         LogSrv( "  relay chunk i=" + LTrim(Str(hb_HGetDef(hMsg,"i",0))) + ;
                 " b64len=" + LTrim(Str(Len(cPayload))) )
      ELSE
         LogSrv( "  chunk i=" + LTrim(Str(hb_HGetDef(hMsg,"i",0))) + ;
                 " DISCARDED (destination offline)" )
      ENDIF

   CASE cCmd == "file.end"
      hb_mutexLock( hMutex )
      cUser  := hb_HGetDef( hSockets, sdCli, "" )
      cTo    := AllTrim( hb_HGetDef( hMsg, "to", "" ) )
      sdDest := hb_HGetDef( hUsers, cTo, NIL )
      hb_mutexUnlock( hMutex )

      IF sdDest != NIL
         cId := hb_HGetDef( hMsg, "id", "" )
         SendLine( sdDest, hb_jsonEncode({ "cmd"=>"file.end", "id"=>cId }) )
         SendLine( sdCli,  hb_jsonEncode({ "cmd"=>"file.sent", "id"=>cId }) )
         LogSrv( "file.end id=" + cId )
      ENDIF
   ENDCASE
RETURN NIL

STATIC FUNCTION SendLine( sd, cLine )
   hb_inetSend( sd, cLine + Chr(10) )
RETURN NIL

STATIC FUNCTION ListaUsuariosJson()
   LOCAL a := {}, k
   hb_mutexLock( hMutex )
   FOR EACH k IN hb_HKeys( hUsers )
      IF hUsers[ k ] != NIL
         AAdd( a, { "nome" => k, "emoji" => hb_HGetDef( hEmojis, k, "" ) } )
      ENDIF
   NEXT
   hb_mutexUnlock( hMutex )
RETURN a

STATIC FUNCTION ListaUsuariosDetalhado()
   LOCAL a := {}, k, cMaq, cEmoji
   hb_mutexLock( hMutex )
   FOR EACH k IN hb_HKeys( hUsers )
      IF hUsers[ k ] != NIL
         cMaq   := hb_HGetDef( hMaquinas, k, "?" )
         cEmoji := hb_HGetDef( hEmojis,   k, "" )
         AAdd( a, PadR( cEmoji + " " + k, 22 ) + " [" + PadR( cMaq, 18 ) + "]" )
      ENDIF
   NEXT
   hb_mutexUnlock( hMutex )
RETURN a

STATIC FUNCTION BroadcastPresence( cUser, lOn, exceptSd )
   LOCAL k, cJson
   hb_mutexLock( hMutex )
   cJson := hb_jsonEncode({ "cmd"=>"presence", "user"=>cUser, "on"=>lOn, ;
                            "emoji"=>hb_HGetDef( hEmojis, cUser, "" ) }) + Chr(10)
   FOR EACH k IN hb_HKeys( hSockets )
      IF k != exceptSd .AND. !Empty( hSockets[ k ] )
         hb_inetSend( k, cJson )
      ENDIF
   NEXT
   hb_mutexUnlock( hMutex )
RETURN NIL
