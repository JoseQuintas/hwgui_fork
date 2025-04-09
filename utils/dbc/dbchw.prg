/*
 * $Id$
 * DBCHW - DBC ( Harbour + HWGUI )
 * Main file
 *
 * Copyright 2001-2016 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "dbchw.h"
#include "dbstruct.ch"
#include "error.ch"
#ifdef RDD_ADS
#include "ads.ch"
#endif

#ifdef __XHARBOUR__
#xtranslate HB_HHASKEY(<x,...>) => HHASKEY(<x>)
#endif

#define MITEM_INDEX      1901
#define MITEM_FLDS       1902
#define MITEM_MOVE       1903
#define MITEM_CMDS       1904

REQUEST  HB_CODEPAGE_BG866, HB_CODEPAGE_BGISO, HB_CODEPAGE_BGMIK, HB_CODEPAGE_BGWIN
REQUEST  HB_CODEPAGE_CS852, HB_CODEPAGE_CSISO, HB_CODEPAGE_CSWIN, HB_CODEPAGE_DE850
REQUEST  HB_CODEPAGE_DE850M,HB_CODEPAGE_DEISO, HB_CODEPAGE_DEWIN, HB_CODEPAGE_DK865
REQUEST  HB_CODEPAGE_EL437, HB_CODEPAGE_EL737, HB_CODEPAGE_ELISO, HB_CODEPAGE_ELWIN
REQUEST  HB_CODEPAGE_EN,    HB_CODEPAGE_ES850, HB_CODEPAGE_ES850C,HB_CODEPAGE_ES850M
REQUEST  HB_CODEPAGE_ESISO, HB_CODEPAGE_ESMWIN,HB_CODEPAGE_ESWIN, HB_CODEPAGE_FI850
REQUEST  HB_CODEPAGE_FR850, HB_CODEPAGE_FR850M,HB_CODEPAGE_FRISO, HB_CODEPAGE_FRWIN
REQUEST  HB_CODEPAGE_HR646, HB_CODEPAGE_HR852, HB_CODEPAGE_HRISO, HB_CODEPAGE_HRWIN
REQUEST  HB_CODEPAGE_HU852, HB_CODEPAGE_HU852C,HB_CODEPAGE_HUISO, HB_CODEPAGE_HUWIN
REQUEST  HB_CODEPAGE_IS850, HB_CODEPAGE_IS861, HB_CODEPAGE_IT437, HB_CODEPAGE_IT850
REQUEST  HB_CODEPAGE_IT850M,HB_CODEPAGE_ITISB, HB_CODEPAGE_ITISO, HB_CODEPAGE_ITWIN
REQUEST  HB_CODEPAGE_LTWIN, HB_CODEPAGE_NL850, HB_CODEPAGE_NL850M,HB_CODEPAGE_NO865
REQUEST  HB_CODEPAGE_PL852, HB_CODEPAGE_PLISO, HB_CODEPAGE_PLMAZ, HB_CODEPAGE_PLWIN
REQUEST  HB_CODEPAGE_PT850, HB_CODEPAGE_PT860, HB_CODEPAGE_PTISO, HB_CODEPAGE_RO852
REQUEST  HB_CODEPAGE_ROISO, HB_CODEPAGE_ROWIN, HB_CODEPAGE_RU1251,HB_CODEPAGE_RU866
REQUEST  HB_CODEPAGE_RUISO, HB_CODEPAGE_RUKOI8,HB_CODEPAGE_SK852, HB_CODEPAGE_SKISO
REQUEST  HB_CODEPAGE_SKWIN, HB_CODEPAGE_SL646, HB_CODEPAGE_SL852, HB_CODEPAGE_SLISO
REQUEST  HB_CODEPAGE_SLWIN, HB_CODEPAGE_SRWIN, HB_CODEPAGE_SV437C,HB_CODEPAGE_SV850
REQUEST  HB_CODEPAGE_SV850M,HB_CODEPAGE_SVISO, HB_CODEPAGE_SVWIN, HB_CODEPAGE_TR857
REQUEST  HB_CODEPAGE_TRISO, HB_CODEPAGE_TRWIN, HB_CODEPAGE_UA1125,HB_CODEPAGE_UA1251
REQUEST  HB_CODEPAGE_UA866, HB_CODEPAGE_UAKOI8

#if defined( HB_VER_MAJOR ) .AND. HB_VER_MAJOR > 2
REQUEST  HB_CODEPAGE_CS852C,HB_CODEPAGE_CSKAMC,HB_CODEPAGE_HE862, HB_CODEPAGE_HEWIN
REQUEST  HB_CODEPAGE_LT775, HB_CODEPAGE_SK852C,HB_CODEPAGE_SKKAMC,HB_CODEPAGE_SR646
REQUEST  HB_CODEPAGE_SR646C,HB_CODEPAGE_UTF16LE,HB_CODEPAGE_UTF8, HB_CODEPAGE_UTF8EX
#endif

REQUEST ORDKEYNO
REQUEST ORDKEYCOUNT

STATIC aCPInfo := { "Bulgarian CP-866","Bulgarian ISO-8859-5","Bulgarian MIK", ;
      "Bulgarian Windows-1251","Czech CP-852","Czech CP-852C", ;
      "Czech ISO-8859-2","Czech Kamenicky","Czech Windows-1250", ;
      "German CP-850","German CP-850M", "German ISO-8859-1","German Windows-1252","Danish CP-865", ;
      "Greek CP-437","Greek CP-737","Greek ISO-8859-7","Greek ANSI CP-1253","English CP-437", ;
      "Spanish (Modern) CP-850","Spanish CP-850","Spanish CP-850","Spanish (Modern) ISO-8859-1", ;
      "Spanish (Modern) ISO-8859-1","Spanish (Modern) Windows-1252","Finnish CP-850", ;
      "French CP-850","French CP-850M","French ISO-8859-1","French Windows-1252","Hebrew CP-862", ;
      "Hebrew Windows-1255","Croatian ISO-646 (CROSCII)","Croatian CP-852","Croatian ISO-8859-2", ;
      "Croatian Windows-1250","Hungarian CP-852","Hungarian CP-852C","Hungarian ISO-8859-2", ;
      "Hungarian Windows-1250","Icelandic CP-850","Icelandic CP-861","Italian CP-437", ;
      "Italian CP-850","Italian CP-850M","Italian ISO-8859-1b","Italian ISO-8859-1", ;
      "Italian Windows-1252","Lithuanian CP-775","Lithuanian Windows-1257","Dutch CP-850", ;
      "Dutch CP-850M","Norwegian CP-865","Polish CP-852","Polish ISO-8859-2","Polish Mazovia", ;
      "Polish Windows-1250","Portuguese CP-850","Portuguese CP-860","Portuguese ISO-8859-1", ;
      "Romanian CP-852","Romanian ISO-8859-2","Romanian Windows-1250","Russian Windows-1251", ;
      "Russian CP-866","Russian ISO-8859-5","Russian KOI-8","Slovak CP-852","Slovak CP-852C", ;
      "Slovak ISO-8859-2","Slovak Kamenicky","Slovak Windows-1250","Slovenian ISO-646 (SLOSCII)", ;
      "Slovenian CP-852","Slovenian ISO-8859-2","Slovenian CP-1250","Serbian ISO-646 (YUSCII)", ;
      "Serbian ISO-646C (Cyrillic YUSCII)","Serbian Windows-1251","Swedish CP-437", ;
      "Swedish CP-850","Swedish CP-850M","Swedish ISO-8859-1","Swedish Windows-1252", ;
      "Turkish CP-857","Turkish ISO-8859-9","Turkish Windows-1254","Ukrainian CP-1125", ;
      "Ukrainian Windows-1251","Ukrainian CP-866","Ukrainian KOI8-U","UTF-16 little endian", ;
      "UTF-8","UTF-8 extended" }

STATIC oTabMain, cExePath

Memvar aBrwFont, oBrwFont, oMainFont, aButtons, aFiles, improc, mypath, aDateF
Memvar dformat, memownd, lRdonly, lShared, cAppCpage, cDataCpage, lMdi, nQueryWndHandle, aDrivers
Memvar nServerType, cServerPath, numdriv, aCPId

FUNCTION Main( ... )
   LOCAL oWndMain, oPanel, aParams := hb_aParams()
   PUBLIC aBrwFont := { "MS Sans Serif", "0", "-13" }, oBrwFont, oMainFont
   PUBLIC aButtons := Array( 5 )
   PUBLIC aFiles[ OPENED_FILES_LIMIT, AF_LEN ], improc := 0
   PUBLIC mypath := "\" + Curdir() + Iif( Empty( Curdir() ), "", "\" )
   PUBLIC aDateF := { "dd/mm/yy", "mm/dd/yy", "yyyy-mm-dd", "yyyy.mm.dd", "dd.mm.yy", "dd-mm-yy", "yy/mm/dd", "dd/mm/yyyy", "dd.mm.yyyy", "mm/dd/yyyy" }
   PUBLIC dformat := aDateF[1], memownd := .F. , lRdonly := .F., lShared := .F.
   PUBLIC cAppCpage := "RU1251", cDataCpage := "RU866"
#ifdef __GTK__
   PUBLIC lMdi := .F.
#else
   PUBLIC lMdi := .T.
#endif
#ifdef RDD_ADS
   PUBLIC nQueryWndHandle := 0
   PUBLIC aDrivers := { "ADS_CDX", "ADS_NTX", "ADS_ADT" }
#else
   PUBLIC aDrivers := { "DBFCDX", "DBFNTX" }
#endif
   PUBLIC nServerType := LOCAL_SERVER
   PUBLIC cServerPath := ""
   PUBLIC numdriv := 1
   PUBLIC aCPId := { "BG866","BGISO","BGMIK","BGWIN","CS852", ;
      "CS852C","CSISO","CSKAMC","CSWIN","DE850","DE850M","DEISO","DEWIN","DK865", ;
      "EL437","EL737","ELISO","ELWIN","EN","ES850","ES850C","ES850M","ESISO", ;
      "ESMWIN","ESWIN","FI850","FR850","FR850M","FRISO","FRWIN","HE862","HEWIN", ;
      "HR646","HR852","HRISO","HRWIN","HU852","HU852C","HUISO","HUWIN","IS850", ;
      "IS861","IT437","IT850","IT850M","ITISB","ITISO","ITWIN","LT775","LTWIN", ;
      "NL850","NL850M","NO865","PL852","PLISO","PLMAZ","PLWIN","PT850","PT860", ;
      "PTISO","RO852","ROISO","ROWIN","RU1251","RU866","RUISO","RUKOI8","SK852", ;
      "SK852C","SKISO","SKKAMC","SKWIN","SL646","SL852","SLISO","SLWIN","SR646", ;
      "SR646C","SRWIN","SV437C","SV850","SV850M","SVISO","SVWIN","TR857","TRISO", ;
      "TRWIN","UA1125","UA1251","UA866","UAKOI8","UTF16LE","UTF8","UTF8EX" }

#ifdef RDD_ADS
   rddRegister( "ADS", 1 )
   rddSetDefault( "ADS" )
   nServerType := ADS_LOCAL_SERVER
   AdsRightsCheck( .F. )
   SET CHARTYPE TO OEM
#else
   REQUEST DBFNTX
   REQUEST DBFCDX
   rddSetDefault( "DBFCDX" )
#ifdef RDD_LETO
   REQUEST LETO
   Rddsetdefault( "LETO" )
   nServerType := REMOTE_SERVER
#endif
#endif

   IF lShared
      SET EXCLUSIVE OFF
   ELSE
      SET EXCLUSIVE ON
   ENDIF
   SET EPOCH TO 1960
   SET DATE FORMAT dformat

   cExePath := FilePath( hb_ArgV( 0 ) )
   ReadIni( FilePath( hb_ArgV( 0 ) ) )
   ReadIni( "\" + Curdir() + Iif( Empty( Curdir() ), "", "\" ) )
   IF !Empty( cServerPath ) .AND. !( Right( cServerPath, 1 ) $ "/\" )
      cServerPath += "\"
   ENDIF
   hb_cdpSelect( cAppCpage )
   hwg_SetResContainer(  cExePath + "dbchw.bin" )
#ifdef __GTK__
   PREPARE FONT oMainFont NAME "MS Sans Serif" WIDTH 0 HEIGHT - 12
#else
   PREPARE FONT oMainFont NAME "MS Sans Serif" WIDTH 0 HEIGHT - 13
#endif

#ifdef RDD_ADS
   AdsSetServerType( nServerType )
   AdsSetFileType( Iif( numdriv == 1,2,Iif( numdriv == 2,1,3 ) ) )
#endif

   oBrwFont := HFont():Add( aBrwFont[1], Val(aBrwFont[2]), Val(aBrwFont[3]) )

   IF lMdi
#ifndef __GTK__
      INIT WINDOW oWndMain MDI TITLE "Dbc" MENU "APPMENU" MENUPOS 8 ;
            ICON HIcon():AddResource("DBC")
#endif
   ELSE
      INIT WINDOW oWndMain MAIN TITLE "Dbc" SIZE 600, 474;
         ICON HIcon():AddResource("DBC")
      //ADD STATUS PARTS 140, 360, 0
      ADD STATUS PANEL TO oWndMain HEIGHT 28 BACKCOLOR 0xEEEEEE FONT oBrwFont PARTS 140, 360, 0
      @ 0, 24 TAB oTabMain ITEMS {} SIZE 600,436 ON SIZE {|o,x,y|o:Move( ,,x,y-28-o:nTop ) }
      //{|o,x,y|ResizeBrwQ( o,x,y ) }
      oTabMain:bChange2 := {|o,n|Iif(Len(o:aControls)>=n,ChildGetFocus(n),.T.)}
   ENDIF

   MENU OF oWndMain
      MENU TITLE "&File"
         MENUITEM "&New" ACTION StruMan( .T. )
         MENUITEM "&Open"+Chr(9)+"Ctrl+O" ACTION OpenFile() ACCELERATOR FCONTROL,Asc("O")
         MENUITEM "&Close" ACTION ChildClose()
         SEPARATOR
         MENUITEM "&Print" ACTION .T.
         SEPARATOR
         MENUITEM "Op&tions" ACTION Options()
         SEPARATOR
         MENUITEM "&Exit" ACTION  hwg_EndWindow()
      ENDMENU
      MENU TITLE  "&View"
         MENUITEM "&Font" ACTION ChangeBrwFont()
         SEPARATOR
         MENUITEM "Zoom &In"+Chr(9)+"Ctrl++" ACTION ChangeFont( , 2 ) ACCELERATOR FCONTROL,VK_ADD
         MENUITEM "Zoom &Out"+Chr(9)+"Ctrl+-" ACTION ChangeFont( , -2 ) ACCELERATOR FCONTROL,VK_SUBTRACT
      ENDMENU
      MENU TITLE  "&Index" ID MITEM_INDEX
         MENUITEM "&Select current" ACTION  SelectIndex()
         MENUITEM "&New index" ACTION  NewIndex()
         MENUITEM "&Open index" ACTION  OpenIndex()
         SEPARATOR
         MENUITEM "&Close all" ACTION CloseIndex()
      ENDMENU
      MENU TITLE "Fie&lds" ID MITEM_FLDS
         MENUITEM "&Modify structure" ACTION StruMan( .F. )
         SEPARATOR
         MENUITEM "&Edit record"+Chr(9)+"Ctrl+E" ACTION EditRec() ACCELERATOR FCONTROL,Asc("E")
      ENDMENU
      MENU TITLE  "&Move" ID MITEM_MOVE
         MENUITEM "&Locate" ACTION  Move( 1 )
         MENUITEM "&Continue" ACTION .T.
         MENUITEM "&Seek"+Chr(9)+"Ctrl+S" ACTION  Move( 2 ) ACCELERATOR FCONTROL,Asc("S")
         MENUITEM "&Filter"+Chr(9)+"Ctrl+F" ACTION  Move( 3 ) ACCELERATOR FCONTROL,Asc("F")
         MENUITEM "&Go To"+Chr(9)+"Ctrl+G" ACTION  Move( 4 ) ACCELERATOR FCONTROL,Asc("G")
      ENDMENU
      MENU TITLE  "&Commands" ID MITEM_CMDS
         MENUITEM "&Replace" ACTION  C_Repl()
         MENUITEM "&Delete" ACTION  C_4( 1 )
         MENUITEM "Reca&ll" ACTION  C_4( 2 )
         MENUITEM "&Count" ACTION  C_4( 3 )
         MENUITEM "&Sum" ACTION  C_4( 4 )
         MENUITEM "&Append from"  ACTION  C_Append()
         MENUITEM "Copy &To" ACTION C_Copy()
         MENUITEM "Re&index" ACTION  C_RPZ( 1 )
         MENUITEM "&Pack" ACTION  C_RPZ( 2 )
         MENUITEM "&Zap" ACTION  C_RPZ( 3 )
         SEPARATOR
         MENUITEM "D&o script" ACTION  Scripts( 1 )
         MENUITEM "&Memo" ACTION .T.
         MENUITEM "Set Relatio&n" ACTION C_Rel()
      ENDMENU
      MENU TITLE  "V&iews"
         MENUITEM "&Open view" ACTION RdView()
         MENUITEM "&Save view" ACTION WrView()
      ENDMENU
      MENU TITLE  "&More..."
         MENUITEM "&Calculator" ACTION  Calcul()
         MENUITEM "&Do script" ACTION  Scripts( 2 )
      ENDMENU
#ifndef __GTK__
      IF lMdi
         MENU TITLE  "&Windows"
            MENUITEM "&Vertically" ACTION hwg_Sendmessage( HWindow():GetMain():handle, WM_MDITILE, MDITILE_VERTICAL, 0 )
            MENUITEM "&Horizontally" ACTION hwg_Sendmessage( HWindow():GetMain():handle, WM_MDITILE, MDITILE_HORIZONTAL, 0 )
            MENUITEM "&Cascade" ACTION hwg_Sendmessage( HWindow():GetMain():handle, WM_MDICASCADE, 0, 0 )
         ENDMENU
      ENDIF
#endif
#ifdef RDD_ADS
      MENU TITLE  "&Query"
         MENUITEM "&New query" ACTION  Query( .F. )
         MENUITEM "&Open query" ACTION  OpenQuery()
         MENUITEM "&Edit query" ACTION  Query( .T. )
      ENDMENU
#endif
      MENUITEM "&About" ACTION  About()
   ENDMENU

   @ 0,0 PANEL oPanel OF oWndMain SIZE oWndMain:nWidth-2,24 ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 2,0 OWNERBUTTON aButtons[5] OF oPanel ON CLICK {||OpenFile()} ;
       SIZE 24,24 FLAT BITMAP "OPEN" FROM RESOURCE TRANSPARENT COLOR 12632256 TOOLTIP "Open file"

   @ 32,2 LINE OF oPanel LENGTH 22 VERTICAL

   @ 36,0 OWNERBUTTON aButtons[1] OF oPanel ON CLICK {||GetBrwActive():Top()} ;
       SIZE 24,24 FLAT BITMAP "TOP" FROM RESOURCE TRANSPARENT COLOR 12632256 TOOLTIP "Top"

   @ 60,0 OWNERBUTTON aButtons[2] OF oPanel ON CLICK {||GetBrwActive():Pageup()} ;
       SIZE 24,24 FLAT BITMAP "PREV" FROM RESOURCE TRANSPARENT COLOR 12632256 TOOLTIP "Page up"

   @ 84,0 OWNERBUTTON aButtons[3] OF oPanel ON CLICK {||GetBrwActive():Pagedown()} ;
       SIZE 24,24 FLAT BITMAP "NEXT" FROM RESOURCE TRANSPARENT COLOR 12632256 TOOLTIP "Page down"

   @ 108,0 OWNERBUTTON aButtons[4] OF oPanel ON CLICK {||GetBrwActive():Bottom()} ;
       SIZE 24,24 FLAT BITMAP "BOTTOM" FROM RESOURCE TRANSPARENT COLOR 12632256 TOOLTIP "Bottom"

   oWndMain:bActivate := {|| ReadParams( aParams ) }

   hwg_Enablemenuitem( , MITEM_INDEX, .F., .T. )
   hwg_Enablemenuitem( , MITEM_FLDS, .F., .T. )
   hwg_Enablemenuitem( , MITEM_MOVE, .F., .T. )
   hwg_Enablemenuitem( , MITEM_CMDS, .F., .T. )

   aButtons[1]:Disable()
   aButtons[2]:Disable()
   aButtons[3]:Disable()
   aButtons[4]:Disable()

   oWndMain:Activate()

   RETURN Nil

STATIC FUNCTION ReadIni( cPath )
   LOCAL hIni := hb_iniRead( cPath + "dbc.ini" ), aSect, cTmp

   IF !Empty( hIni )
      hb_hCaseMatch( hIni, .F. )
      IF !Empty( aSect := hIni[ "MAIN" ] )
         hb_hCaseMatch( aSect, .F. )
         IF hb_hHaskey( aSect, "brwfont" ) .AND. !Empty( cTmp := aSect[ "brwfont" ] )
            m->aBrwFont := hb_aTokens( cTmp, "," )
         ENDIF
         IF hb_hHaskey( aSect, "dateformat" ) .AND. !Empty( cTmp := aSect[ "dateformat" ] )
            IF Ascan( aDateF, cTmp ) != Nil
               dformat := cTmp
            ENDIF
         ENDIF
         IF hb_hHaskey( aSect, "shared" ) .AND. !Empty( cTmp := aSect[ "shared" ] )
            lShared := ( Lower( cTmp ) == "on" )
         ENDIF
         IF hb_hHaskey( aSect, "readonly" ) .AND. !Empty( cTmp := aSect[ "readonly" ] )
            lRdOnly := ( Lower( cTmp ) == "on" )
         ENDIF
         IF hb_hHaskey( aSect, "appcodepage" ) .AND. !Empty( cTmp := aSect[ "appcodepage" ] )
            IF Ascan( aCpId, cTmp ) != Nil
               cAppCpage := cTmp
            ENDIF
         ENDIF
         IF hb_hHaskey( aSect, "datacodepage" ) .AND. !Empty( cTmp := aSect[ "datacodepage" ] )
            IF Ascan( aCpId, cTmp ) != Nil
               cDataCpage := cTmp
            ENDIF
         ENDIF
         IF hb_hHaskey( aSect, "mdi" ) .AND. ( Empty( cTmp := aSect[ "mdi" ] ) ;
               .OR. Lower( cTmp ) != "on" )
            lMdi := .F.
         ENDIF
         IF hb_hHaskey( aSect, "index" ) .AND. ( !Empty( cTmp := aSect[ "index" ] ) ;
               .AND. Lower( cTmp ) == "ntx" )
            numdriv := 2
         ENDIF
      ENDIF
#ifdef RDD_ADS
      IF hb_hHaskey( hIni, "ADS" ) .AND. !Empty( aSect := hIni[ "ADS" ] )
         hb_hCaseMatch( aSect, .F. )
         IF hb_hHaskey( aSect, "serverpath" ) .AND. !Empty( cTmp := aSect[ "serverpath" ] )
            cServerPath := cTmp
         ENDIF
         IF hb_hHaskey( aSect, "servertype" ) .AND. !Empty( cTmp := aSect[ "servertype" ] )
            nServerType := Iif( Lower(cTmp) == "remote", 6, 1 )
         ENDIF
      ENDIF
#endif
#ifdef RDD_LETO
      IF hb_hHaskey( hIni, "LETO" ) .AND. !Empty( aSect := hIni[ "LETO" ] )
         hb_hCaseMatch( aSect, .F. )
         IF hb_hHaskey( aSect, "serverpath" ) .AND. !Empty( cTmp := aSect[ "serverpath" ] )
            cServerPath := cTmp
         ENDIF
         IF hb_hHaskey( aSect, "servertype" ) .AND. !Empty( cTmp := aSect[ "servertype" ] )
            nServerType := Iif( Lower(cTmp) == "remote", REMOTE_SERVER, LOCAL_SERVER )
         ENDIF
      ENDIF
#endif
   ENDIF

   RETURN Nil

STATIC FUNCTION ReadParams( aParams )
   LOCAL i, cExt

   FOR i := 1 TO Len( aParams )
      IF Left( aParams[i],1 ) $ "-/"
      ELSEIF ( cExt := Lower( FilExten( aParams[i] ) ) ) == "dbf"
         hb_cdpSelect( cAppCpage )
         Set( _SET_EXCLUSIVE, !lShared )
         IF nServerType != LOCAL_SERVER
            OpenDbf( cServerPath + aParams[i] )
         ELSE
            OpenDbf( aParams[i] )
         ENDIF
      ELSEIF cExt == "vew"
         hb_cdpSelect( cAppCpage )
         RdView( aParams[i] )
      ENDIF
   NEXT
   RETURN Nil

STATIC FUNCTION ChildClose
   LOCAL xWnd

   IF lMdi
#ifndef __GTK__
      IF !Empty( xWnd := HMainWindow():GetMdiActive() )
         hwg_Sendmessage( xWnd:handle, WM_SYSCOMMAND, SC_CLOSE, 0 )
      ENDIF
#endif
   ELSE
      IF !Empty( xWnd := oTabMain:GetActivePage() )
         ChildKill( xWnd )
         oTabMain:DeletePage( xWnd )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION About
   LOCAL oDlg, sv, nPos

   INIT DIALOG oDlg AT 200, 200 SIZE 476, 168 FONT oMainFont

   @ 0, 0 BITMAP "BMP_ABOUT" FROM RESOURCE

   @ 288, 0 GROUPBOX "" SIZE 170, 92
   @ 290, 12 SAY "xBase files management" SIZE 178, 18 STYLE SS_CENTER
   @ 290, 30 SAY "utility" SIZE 178, 18 STYLE SS_CENTER
   @ 290, 48 SAY "version 3.2" SIZE 178, 20 STYLE SS_CENTER
#ifdef __XHARBOUR__
   sv := version()
#else
   sv := hb_version()
#endif
   nPos := At( "(", sv )
   @ 290, 68 SAY Left( sv, nPos-1 ) SIZE 178, 20 STYLE SS_CENTER

   @ 298, 92 GROUPBOX "" SIZE 172, 36
   @ 300,108 SAY "Alexander Kresin, 2016" SIZE 168, 20 STYLE SS_CENTER

   @ 288, 132 BUTTON "Close" SIZE 182, 32 ON CLICK { || hwg_EndDialog() } ;

   oDlg:Activate()

   RETURN Nil

   /* -----------------------  Select Order --------------------- */

Static Function SelectIndex()
Local aIndex := { { "None","   ","   " } }, i, indname, iLen := 0
Local oDlg, oBrowse, width, height, nChoice := 0, cOrder, nOrder := OrdNumber()+1

   i := 1
   DO WHILE !EMPTY( indname := ORDNAME( i ) )
      AADD( aIndex, { indname, ORDKEY( i ), ORDBAGNAME( i ) } )
      iLen := Max( iLen, Len( OrdKey( i ) ) )
      i ++
   ENDDO

   INIT DIALOG oDlg TITLE "Select Order" ;
         AT 0,0                  ;
         SIZE 400,180            ;
         FONT oMainFont

   @ 0,0 BROWSE oBrowse ARRAY       ;
       SIZE 400,180                 ;
       FONT oMainFont               ;
       STYLE WS_BORDER+WS_VSCROLL + WS_HSCROLL ;
       ON SIZE {|o,x,y|o:Move(,,x,y)} ;
       ON CLICK {|o|nChoice:=o:nCurrent,cOrder:=o:aArray[o:nCurrent,1],hwg_EndDialog(o:oParent:handle)}

   oBrowse:aArray := aIndex
   oBrowse:AddColumn( HColumn():New( "OrdName",{|v,o| (v), o:aArray[o:nCurrent,1]},"C",10,0 ) )
   oBrowse:AddColumn( HColumn():New( "Order key",{|v,o| (v), o:aArray[o:nCurrent,2]},"C",Max(iLen,30),0 ) )
   oBrowse:AddColumn( HColumn():New( "Filename",{|v,o| (v), o:aArray[o:nCurrent,3]},"C",10,0 ) )

   oBrowse:bScrollPos := {|o,n,lEof,nPos|hwg_VScrollPos(o,n,lEof,nPos)}
   oBrowse:aHeadPadding := { 4,2,4,2 }
   oBrowse:oStyleHead := HStyle():New( { 0xffffff, 0xbbbbbb }, 1 )

   oBrowse:rowPos := nOrder
   Eval( oBrowse:bGoTo,oBrowse,nOrder )

   oDlg:Activate()

   IF nChoice > 0
      nChoice --
      Set Order To nChoice
      UpdBrowse()
   ENDIF

Return Nil

Static Function NewIndex()
Local oDlg, oMsg
Local cName := CutPath(CutExten(aFiles[improc,AF_NAME]))
Local lMulti := .T., lUniq := .F., cTag := "", cExpr := "", cCond := ""

   INIT DIALOG oDlg TITLE "Create Order" ;
         AT 0,0         ;
         SIZE 300,250   ;
         FONT oMainFont

   @ 10,10 SAY "Order name:" SIZE 100,22
   @ 110,10 GET cName SIZE 100,24

   @ 10,40 GET CHECKBOX lMulti CAPTION "Multibag" SIZE 100,22
   @ 110,40 GET cTag SIZE 100,24

   @ 10,65 GET CHECKBOX lUniq CAPTION "Unique" SIZE 100,22

   @ 10,85 SAY "Expression:" SIZE 100,22
   @ 10,107 GET cExpr SIZE 280,24

   @ 10,135 SAY "Condition:" SIZE 100,22
   @ 10,157 GET cCond SIZE 280,24

   @  30,210  BUTTON "Ok" SIZE 100, 32 ON CLICK {||oDlg:lResult:=.T.,hwg_EndDialog()}
   @ 170,210 BUTTON "Cancel" SIZE 100, 32 ON CLICK {||hwg_EndDialog()}

   oDlg:Activate()

   IF oDlg:lResult
      IF !Empty( cName ) .AND. ( !Empty( cTag ) .OR. !lMulti ) .AND. !Empty( cExpr )

         oMsg := DlgWait("Indexing")
         cName := cServerPath + Trim( cName )
         IF lMulti
            IF EMPTY( cCond )
               ORDCREATE( cName,RTRIM(cTag),RTRIM(cExpr), &("{||"+RTRIM(cExpr)+"}"),Iif(lUniq,.T.,Nil) )
            ELSE
               ordCondSet( RTRIM(cCond), &("{||"+RTRIM(cCond) + "}" ),,,,, RECNO(),,,, )
               ORDCREATE( cName, RTRIM(cTag), RTRIM(cExpr), &("{||"+RTRIM(cExpr)+"}"),Iif(lUniq,.T.,Nil) )
            ENDIF
         ELSE
            IF EMPTY( cCond )
               dbCreateIndex( cName,RTRIM(cExpr),&("{||"+RTRIM(cExpr)+"}"),Iif(lUniq,.T.,Nil) )
            ELSE
               ordCondSet( RTRIM(cCond), &("{||"+RTRIM(cCond) + "}" ),,,,, RECNO(),,,, )
               ORDCREATE( cName, RTRIM(cTag), RTRIM(cExpr), &("{||"+RTRIM(cExpr)+"}"),Iif(lUniq,.T.,Nil) )
            ENDIF
         ENDIF
         oMsg:Close()
         UpdBrowse()
      ELSE
         hwg_MsgStop( "Fill necessary fields" )
      ENDIF
   ENDIF

Return Nil

Static Function OpenIndex()
Local fname, cExt := Iif( numdriv==1,"*.cdx", "*.ntx" )

   IF aFiles[ improc, AF_LOCAL ]
#ifdef __GTK__
      fname := hwg_SelectFileEx( ,, { { "Index files", cExt }, { "All files", "*" } } )
#else
      fname := hwg_SelectFile( {"index files( "+cExt+" )","All files(*.*)"}, {cExt,"*.*"}, "\" + Curdir() + Iif( Empty( Curdir() ), "", "\" ) )
#endif
   ELSE
      fname := hwg_MsgGet( "Open index", "Input file name:" )
   ENDIF

   IF !Empty( fname )
      Set Index To (fname) Additive
      UpdBrowse()
   ENDIF

Return Nil

FUNCTION CloseIndex()

   OrdListClear()
   Set Order To 0
   UpdBrowse()

   RETURN Nil

Function UpdBrowse()
   LOCAL oBrw := GetBrwActive(), i, cTmp

   IF !Empty( oBrw )

      IF aFiles[ improc,AF_LFLT ]
         oBrw:bRcou := {|o| o:nRecords }
         oBrw:bRecnoLog := {|o| o:nCurrent }
      ELSE
         IF OrdNumber() == 0
            oBrw:bRcou := {|o| (o:alias)->(Reccount()) }
            oBrw:bRecnoLog := {|o| (o:alias)->(Recno()) }
         ELSE
            oBrw:bRcou := {|o| (o:alias)->(Ordkeycount()) }
            oBrw:bRecnoLog := {|o| (o:alias)->(Ordkeyno()) }
         ENDIF
      ENDIF

      WriteTableInfo( 2, Iif(aFiles[improc,AF_EXCLU],"Exclusive","Shared") + ;
            Iif(aFiles[improc,AF_RDONLY],", Readonly","") + Iif(aFiles[improc,AF_LFLT],", Filtered","") + ", Order: "+Iif(Empty(cTmp:=ordSetFocus()),"None",cTmp) )
      WriteTableInfo( 1, LTrim(Str(Eval(oBrw:bRecno,oBrw)))+"/"+LTrim(Str(Eval(oBrw:bRcou,oBrw))) )
      hwg_Invalidaterect( oBrw:handle, 1 )
      oBrw:Refresh()
      hwg_SetFocus( oBrw:handle )
   ENDIF

Return Nil

Function GetBrwActive()

   LOCAL oWindow, i, oBrw

   IF lMdi
#ifndef __GTK__
      IF !Empty( oWindow := HMainWindow():GetMdiActive() )
         i := Ascan( oWindow:aControls, { |o|o:classname() == "HBROWSE" } )
      ENDIF
      oBrw := Iif( Empty(i), Nil, oWindow:aControls[i] )
#endif
   ELSE
      oBrw := oTabMain:aControls[ oTabMain:GetActivePage() ]
   ENDIF

   RETURN oBrw

Function DlgWait( cTitle )
Local oDlg

   INIT DIALOG oDlg TITLE cTitle ;
         AT 0,0                  ;
         SIZE 160,50

   @ 10, 20 SAY "Wait, please ..." SIZE 140,22

   ACTIVATE DIALOG oDlg NOMODAL CENTER

Return oDlg

   /* -----------------------  Open Database file --------------------- */

FUNCTION OpenFile()
Local oDlg, oGetFile, cFile := "", alsname := "", pass
Local lExcl := !lShared, lRd := lRdonly, nCp := Ascan( aCpId, cDataCpage ), r1 := numdriv
#ifdef RDD_ADS
Local lAxl := AdsLocking(), lRemote := (nServerType == 6)
#else
Local lRemote := (nServerType == REMOTE_SERVER)
#endif
Local oBtnFile, bBtnDis := {||Iif(lRemote,oBtnFile:Disable(),oBtnFile:Enable()),.T.}
Local bFileBtn := {||
#ifdef __GTK__
   cFile := hwg_SelectFileEx( ,, { { "Dbf files", "*.dbf" }, { "All files", "*" } } )
#else
   cFile := hwg_Selectfile( {"dbf files( *.dbf )","All files(*.*)"}, {"*.dbf","*.*"}, hb_curDrive()+":\"+Curdir() )
#endif
   IF Empty( cFile )
      cFile := ""
   ENDIF
   oGetFile:Refresh()
   Return .T.
   }

   INIT DIALOG oDlg TITLE "Open file" ;
         AT 0,0         ;
         SIZE 400,280   ;
         FONT oMainFont ON INIT bBtnDis

#if defined( RDD_ADS ) .OR. defined( RDD_LETO )
   @ 10,10 SAY "Server " SIZE 60,22 STYLE SS_RIGHT
   @ 70,10 GET CHECKBOX lRemote CAPTION "Remote:" SIZE 80, 20 ON CLICK bBtnDis
   @ 150,10 GET cServerPath SIZE 240,24
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS
#endif

   @ 10,34 SAY "File name: " SIZE 80,22 STYLE SS_RIGHT

   @ 90,34 GET oGetFile VAR cFile SIZE 220,24 PICTURE "@S128" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS
   @ 310,34 BUTTON oBtnFile CAPTION "Browse" SIZE 80, 26 ON CLICK bFileBtn ON SIZE ANCHOR_RIGHTABS

   @ 10,60 SAY "Alias: " SIZE 80,22  STYLE SS_RIGHT
   @ 90,60 GET alsname SIZE 110,24

   @ 10, 92 GROUPBOX "" SIZE 180, 88
   @ 20, 116 GET CHECKBOX lExcl CAPTION "Exclusive" SIZE 120, 22
   @ 20, 140 GET CHECKBOX lRd CAPTION "Readonly" SIZE 120, 22

   @ 210,92 GROUPBOX "" SIZE 180, 88
#ifdef RDD_ADS
   GET RADIOGROUP r1
   @ 220,116 RADIOBUTTON "AXS_CDX" SIZE 120, 22
   @ 220,140 RADIOBUTTON "AXS_NTX" SIZE 120, 22
   @ 220,164 RADIOBUTTON "AXS_ADT" SIZE 120, 22
   END RADIOGROUP

   @ 220,188 GET CHECKBOX lAxl CAPTION "Axslock" SIZE 120, 20
#else
#ifndef RDD_LETO
   GET RADIOGROUP r1
   @ 220,116 RADIOBUTTON "DBFCDX" SIZE 120, 22
   @ 220,140 RADIOBUTTON "DBFNTX" SIZE 120, 22
   END RADIOGROUP
#endif
#endif

   @ 20,188 GET COMBOBOX nCp ITEMS aCpInfo SIZE 170,24 DISPLAYCOUNT 12

   @  30,228 BUTTON "Ok" SIZE 100, 32 ON CLICK {||oDlg:lResult:=.T.,hwg_EndDialog()}
   @ 270,228 BUTTON "Cancel" SIZE 100, 32 ON CLICK {||hwg_EndDialog()}

   oDlg:Activate()

   IF oDlg:lResult
      IF Empty( cFile )
         hwg_MsgStop( "File name is absent!" )
         Return Nil
      ENDIF
#ifdef RDD_ADS
      AdsSetServerType( nServerType := Iif( lRemote, 6, ADS_LOCAL_SERVER ) )
      numdriv := r1
      AdsSetFileType( Iif( numdriv == 1,2,Iif( numdriv == 2,1,3 ) ) )
      AdsLocking( lAxl )
#endif
#ifdef RDD_LETO
      rddSetDefault( Iif( lRemote, "LETO", "DBFCDX" ) )
      nServerType := Iif( lRemote, REMOTE_SERVER, LOCAL_SERVER )
#endif
#if !defined ( RDD_ADS ) .AND. !defined( RDD_LETO )
      rddSetDefault( Iif( ( numdriv := r1 ) == 1, "DBFCDX","DBFNTX" ) )
#endif
      Set( _SET_EXCLUSIVE, lExcl )
      lShared := !lExcl
      lRdonly := lRd
      cDataCpage := aCpId[ nCp ]
      OpenDbf( Iif(lRemote,cServerPath+cFile,cFile), alsname,, pass )
   ENDIF

Return Nil

FUNCTION OpenDbf( fname, alsname, hChild, pass )
   LOCAL oWindow, oBrowse, i, nArea, kolf
   LOCAL oStyle := HStyle():New( { 0xffffff, 0xbbbbbb }, 1 )
   LOCAL bPosChg := {|o|
      LOCAL j := 0, j1, cAls
      WriteTableInfo( 1,LTrim(Str(Eval(o:bRecno,o)))+"/"+LTrim(Str(Eval(o:bRcou,o))) )
      DO WHILE !Empty( dbRelation( ++j ) )
         cAls := Lower( Alias( dbRselect(j) ) )
         FOR j1 := 1 TO Len( aFiles )
            IF !Empty(aFiles[j1,AF_NAME]) .AND. Lower( aFiles[j1,AF_ALIAS] ) == cAls
               hwg_Invalidaterect( aFiles[j1,AF_BRW]:handle, 1 )
               aFiles[j1,AF_BRW]:Refresh()
               EXIT
            ENDIF
         NEXT
      ENDDO
      RETURN Nil
   }
   LOCAL bCol1 := {|o,h,x1,y1,x2,y2|
      oStyle:Draw( h,x1,y1,x2,y2 )
      IF (oBrowse:alias)->(Deleted())
         hwg_Settextcolor( h,0 )
         hwg_Settransparentmode( h, .T. )
         hwg_Drawtext( h, '*', x1, y1 + 6, x2, y2 - 4, 1 )
         hwg_Settransparentmode( h, .F. )
      ENDIF
      RETURN Nil
   }

   IF !FiOpen( fname, alsname, pass )
      RETURN 0
   ENDIF

   hwg_Enablemenuitem( , MITEM_INDEX, .T., .T. )
   hwg_Enablemenuitem( , MITEM_FLDS, .T., .T. )
   hwg_Enablemenuitem( , MITEM_MOVE, .T., .T. )
   hwg_Enablemenuitem( , MITEM_CMDS, .T., .T. )
   hwg_Drawmenubar( HWindow():aWindows[1]:handle )
   aButtons[1]:Enable()
   aButtons[2]:Enable()
   aButtons[3]:Enable()
   aButtons[4]:Enable()

   IF Empty( hChild )
      IF lMdi
#ifndef __GTK__
         INIT WINDOW oWindow MDICHILD TITLE fname ;
            AT 0, 0                              ;
            STYLE WS_VISIBLE + WS_OVERLAPPEDWINDOW ;
            ON GETFOCUS { |o|ChildGetFocus( o ) }  ;
            ON EXIT { |o|ChildKill( o ) }

         //ADD STATUS PARTS 140, 360, 0
         //ADD STATUS PANEL TO oWindow HEIGHT 28 HSTYLE oStyle PARTS 140, 360, 0
         ADD STATUS PANEL TO oWindow HEIGHT 28 BACKCOLOR 0xEEEEEE FONT oBrwFont PARTS 140, 360, 0

         @ 0, 0 BROWSE oBrowse DATABASE ON SIZE {|o,x,y|o:Move( ,,x,y-28 ) }
         //{|o,x,y|ResizeBrwQ( o,x,y ) }
#endif
      ELSE
         BEGIN PAGE Lower(Alias()) of oTabMain
#ifdef __GTK__
         @ 4,4 BROWSE oBrowse OF oTabMain DATABASE SIZE 592,426  ;
             STYLE WS_BORDER+WS_VSCROLL ;
             ON SIZE {|o,x,y|o:Move(,,x-8,y-32)}
#else
         @ 0,30 BROWSE oBrowse OF oTabMain DATABASE SIZE oTabMain:nWidth, oTabMain:nHeight-36  ;
             NOBORDER ;
             ON SIZE {|o,x,y|o:Move(,,x,y-36)}
#endif
         END PAGE of oTabMain
      ENDIF

      oBrowse:bPosChanged := bPosChg
      oBrowse:htbcolor := 0x777777
      oBrowse:bcolorSel := BCOLOR_SEL
      oBrowse:tcolorSel := TCOLOR_SEL
      oBrowse:oStyleHead := oStyle
      oBrowse:ofont := oBrwFont
      oBrowse:cargo := { improc, {"","",""} }

      nArea := Select()
      kolf := FCount()

      oBrowse:alias := Alias()
      oBrowse:aColumns := {}
      oBrowse:AddColumn( { "",, "C", 2, 0 } )
      oBrowse:aColumns[1]:cargo := oBrowse
      oBrowse:aColumns[1]:oPaintCB := HPaintCB():New()
      oBrowse:aColumns[1]:oPaintCB:Set( PAINT_LINE_ALL, bCol1 )
      FOR i := 1 TO kolf
         oBrowse:AddColumn( { FieldName( i ),        ;
            FieldWBlock( FieldName( i ), nArea ), ;
            dbFieldInfo( DBS_TYPE, i ),         ;
            iif( dbFieldInfo( DBS_TYPE,i ) == "D" .AND. __SetCentury(), 10, dbFieldInfo( DBS_LEN,i ) ), ;
            dbFieldInfo( DBS_DEC, i ), .T. } )
      NEXT

      oBrowse:lAppable := .T.
      oBrowse:bScrollPos := {|o,n,lEof,nPos|hwg_VScrollPos(o,n,lEof,nPos)}
      oBrowse:lInFocus := .T.
      oBrowse:freeze := 1
      oBrowse:colpos := 2
      oBrowse:Refresh()

      IF lMdi
#ifndef __GTK__
         oWindow:Activate()
#endif
      ELSE
         oTabMain:SetTab( Len(oTabMain:aPages) )
      ENDIF
   ELSE
      IF lMdi
#ifndef __GTK__
         oWindow := HWindow():FindWindow( hChild )
         IF oWindow != Nil .AND. ;
               ( i := Ascan( oWindow:aControls, { |o|o:classname() == "HBROWSE" } ) ) > 0
            oBrowse := oWindow:aControls[ i ]
            hwg_Sendmessage( HWindow():GetMain():handle, WM_MDIACTIVATE, hChild, 0 )
         ENDIF
#endif
      ELSE
         oBrowse := oTabMain:aControls[hChild]
         oTabMain:SetTab( hChild )
      ENDIF
      IF !Empty( oBrowse )
         oBrowse:InitBrw()
         oBrowse:bcolorSel := BCOLOR_SEL
         oBrowse:tcolorSel := TCOLOR_SEL
         oBrowse:ofont := oBrwFont
         oBrowse:cargo := { improc, {"","",""} }
         oBrowse:Refresh()
      ENDIF
   ENDIF
   aFiles[ improc, AF_BRW ] := oBrowse
   UpdBrowse()

   RETURN Iif( lMdi, oWindow:handle, oTabMain:GetActivePage() )

FUNCTION WriteTableInfo( n, cText )

   LOCAL oBrw

   IF lMdi
#ifndef __GTK__
      hwg_WriteStatus( HMainWindow():GetMdiActive(), n, cText )
#endif
   ELSE
      oBrw := GetBrwActive()
      oBrw:cargo[2,n] := cText
#ifdef __GTK__
      hwg_WriteStatus( HWindow():GetMain(), 1, oBrw:cargo[2,1]+", "+oBrw:cargo[2,2]+", "+oBrw:cargo[2,3] )
#else
      hwg_WriteStatus( HWindow():GetMain(), n, cText )
#endif
   ENDIF

   RETURN Nil

   /* -----------------------  Calculator  --------------------- */

FUNCTION Calcul()
   LOCAL oDlg, oSayRes, cExpr, xRes
   LOCAL bCalcBtn := {||
      Local bOldError := ErrorBlock( { |e|break( e ) } ), lRes := .T.
      BEGIN SEQUENCE
         xRes := &( Trim( cExpr ) )
      RECOVER
         hwg_MsgStop( "Expression error" )
         lRes := .F.
      END SEQUENCE
      ErrorBlock( bOldError )
      IF lRes
         oSayRes:SetText( Iif( xRes==Nil, "Nil", Transform( xRes, "@B" ) ) )
      ENDIF
      RETURN Nil
   }

   INIT DIALOG oDlg TITLE "Calculator" ;
         AT 0,0         ;
         SIZE 400,150   ;
         FONT oMainFont

   @ 10,10 SAY "Expression: " SIZE 90,22 STYLE SS_RIGHT
   @ 100,10 GET cExpr SIZE 290,24
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS

   @ 10,40 BUTTON "Calc it!" SIZE 80, 26 ON CLICK bCalcBtn

   @ 90,40 SAY oSayRes CAPTION "" SIZE 300,22 COLOR 16711680 BACKCOLOR 16777215 ;
         STYLE WS_BORDER ON SIZE ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS

   @ 150,100 BUTTON "Close" SIZE 100, 32 ON CLICK {||hwg_EndDialog()}

   oDlg:Activate()

   RETURN Nil

   /* -----------------------  Scripts  --------------------- */

FUNCTION Scripts( nAct )
   LOCAL oDlg, oEdit1
   LOCAL bLoadBtn := {||
#ifdef __GTK__
      Local fname := hwg_SelectFileEx( ,, { { "Script files( *.scr )", "*.scr" }, { "All files", "*" } } )
#else
      Local fname := hwg_SelectFile( "Script files( *.scr )", "*.scr", mypath )
#endif
      IF !Empty( fname )
         oEdit1:SetText( Memoread(fname) )
      ENDIF
      RETURN Nil
   }

   LOCAL bCalcBtn := {||
      Local aScr := RdScript( ,oEdit1:GetText() ), obl
      IF aScr != Nil
         IF nAct == 1
            obl := Select()
            GO TOP
            DO WHILE !Eof()
               DoScript( aScr )
               SELECT( obl )
               SKIP
            ENDDO
         ELSE
            DoScript( aScr )
         ENDIF
         hwg_Msginfo( "Script executed" )
      ENDIF
      RETURN Nil
   }

   INIT DIALOG oDlg TITLE "Script" ;
         AT 0,0         ;
         SIZE 400,250   ;
         FONT oMainFont

   @ 10,10 BUTTON "Browse" SIZE 80, 26 ON CLICK bLoadBtn
   @ 310,10 BUTTON "Execute" SIZE 80, 26 ON CLICK bCalcBtn
   @ 10, 40 EDITBOX oEdit1 CAPTION "" SIZE 380, 60 STYLE WS_VSCROLL + ES_MULTILINE

   @ 150,200 BUTTON "Close" SIZE 100, 32 ON CLICK {||hwg_EndDialog()}

   oDlg:Activate()

   RETURN Nil

FUNCTION ChildGetFocus( xWindow )
   LOCAL i, oBrw

   IF xWindow != Nil
      IF lMdi
         IF ( i := Ascan( xWindow:aControls, { |o|o:classname() == "HBROWSE" } ) ) > 0
            oBrw := xWindow:aControls[i]
         ENDIF
      ELSE
         oBrw := oTabMain:aControls[xWindow]
      ENDIF
      IF !Empty( oBrw ) .AND. ValType( oBrw:cargo ) == "A"
         SELECT( improc := oBrw:cargo[1] )
#ifdef __GTK
         hwg_WriteStatus( HWindow():GetMain(), 1, oBrw:cargo[2,1]+", "+oBrw:cargo[2,2]+", "+oBrw:cargo[2,3] )
         hwg_Setfocus( oBrw:area )
#else
         hwg_WriteStatus( HWindow():GetMain(), 1, oBrw:cargo[2,1] )
         hwg_WriteStatus( HWindow():GetMain(), 2, oBrw:cargo[2,2] )
         hwg_WriteStatus( HWindow():GetMain(), 3, oBrw:cargo[2,3] )
         hwg_Setfocus( oBrw:handle )
#endif
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION ChildKill( xWindow )
   LOCAL i, oBrw

   IF xWindow != Nil
      IF lMdi
         IF ( i := Ascan( xWindow:aControls, { |o|o:classname() == "HBROWSE" } ) ) > 0
            oBrw := xWindow:aControls[i]
         ENDIF
      ELSE
         oBrw := oTabMain:aControls[xWindow]
      ENDIF
      IF !Empty( oBrw )
         IF ValType( oBrw:cargo[1] ) == "N"
            SELECT( improc := oBrw:cargo[1] )
#ifdef RDD_ADS
            IF Alias() == "ADSSQL"
               nQueryWndHandle := 0
            ENDIF
#endif
            FiClose()
            IF Len( HWindow():aWindows ) == 3
               hwg_Enablemenuitem( , MITEM_INDEX, .F., .T. )
               hwg_Enablemenuitem( , MITEM_FLDS, .F., .T. )
               hwg_Enablemenuitem( , MITEM_MOVE, .F., .T. )
               hwg_Enablemenuitem( , MITEM_CMDS, .F., .T. )
               hwg_Drawmenubar( HWindow():GetMain():handle )
               aButtons[1]:Disable()
               aButtons[2]:Disable()
               aButtons[3]:Disable()
               aButtons[4]:Disable()
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION ResizeBrwQ( oBrw, nWidth, nHeight )
   LOCAL hWndStatus, aControls := oBrw:oParent:aControls
   LOCAL aRect, i, nHbusy := 0

   FOR i := 1 TO Len( aControls )
      IF aControls[i]:classname() == "HSTATUS"
         hWndStatus := aControls[i]:handle
         aRect := hwg_Getclientrect( hWndStatus )
         nHbusy += aRect[ 4 ]
      ENDIF
   NEXT
   oBrw:Move( ,, nWidth, nHeight - nHBusy - oBrw:nTop )
   //hwg_Movewindow( oBrw:handle, 0, oBrw:nTop, nWidth, nHeight - nHBusy - oBrw:nTop )

   RETURN Nil

STATIC FUNCTION Fiopen( fname, alsname, pass )

   LOCAL i, oldimp := improc, newimp, res := .T.
   LOCAL strerr := "Can't open file " + Iif( Empty(fname), alsname, fname )
   LOCAL bOldError, oError

   IF fname != Nil
      FOR i := 1 TO OPENED_FILES_LIMIT
         IF aFiles[ i,AF_NAME ] == Nil
            improc := i
            EXIT
         ENDIF
      NEXT
      IF improc > OPENED_FILES_LIMIT
         improc := oldimp
         hwg_Msgstop( "Too many opened files!" )
         RETURN .F.
      ENDIF
      newimp := improc

      alsname := Iif( Empty(alsname), CutExten( CutPath( fname ) ), alsname )

      bOldError := ErrorBlock( { | e | break( e ) } )
      DO WHILE .T.
         BEGIN SEQUENCE
            SELECT( improc )
            dbUseArea( ,, fname, alsname,, lRdonly, cDataCpage )
         RECOVER USING oError
            IF oError:genCode == EG_BADALIAS .OR. oError:genCode == EG_DUPALIAS
               IF Empty( alsname := hwg_MsgGet( "","Bad alias name, input other:" ) )
                  res := .F.
               ELSE
                  improc := newimp
                  LOOP
               ENDIF
            ELSE
               res := .F.
            ENDIF
         END SEQUENCE
         EXIT
      ENDDO
      ErrorBlock( bOldError )
      IF NetErr()
         IF SET( _SET_EXCLUSIVE )
            SET( _SET_EXCLUSIVE, .F. )
            dbUseArea( , , fname, CutExten( iif( alsname = Nil, fname, alsname ) ), , lRdonly )
            IF NetErr()
               hwg_Msgstop( strerr )
               improc := oldimp
               RETURN .F.
            ENDIF
         ELSE
            improc := oldimp
            hwg_Msgstop( strerr )
            RETURN .F.
         ENDIF
      ELSEIF !res
         improc := oldimp
         hwg_Msgstop( strerr )
         RETURN .F.
      ENDIF
   ENDIF
#ifdef RDD_ADS
   IF pass != Nil
      AdsEnableEncryption( pass )
   ENDIF
#endif
   aFiles[ improc, AF_NAME ] := Iif( fname != Nil, fname, Alias() )
   aFiles[ improc, AF_EXCLU ] := Set( _SET_EXCLUSIVE )
   aFiles[ improc, AF_RDONLY ] := lRdonly
   aFiles[ improc, AF_DRIVER ] := numdriv
   aFiles[ improc, AF_LOCAL ] := ( nServerType == LOCAL_SERVER )
   aFiles[ improc, AF_PASS ] := pass
   aFiles[ improc, AF_ALIAS ] := alsname
   aFiles[ improc, AF_LFLT ] := .F.
   aFiles[ improc, AF_CP ] := cDataCpage

   RETURN .T.

FUNCTION FiClose

   LOCAL i

   IF improc > 0
      SELECT( improc )
      USE
      aFiles[ improc,AF_NAME ] := Nil
      aFiles[ improc,AF_BRW ]  := Nil
      improc := 0
   ENDIF

   RETURN Nil


/*
 This function is not used,
 link error, duplicate definition in
 source\common\procmisc\procscri.prg
FUNCTION WndOut()

   RETURN Nil
*/

FUNCTION MsgSay( cText )

   hwg_Msgstop( cText )

   RETURN Nil

Static Function ChangeFont( oCtrl, n )
Local oFont, nHeight, i, nOld

   IF Empty( oCtrl )
      oCtrl := GetBrwActive()
   ENDIF
   IF !Empty( oCtrl )
      nHeight := oCtrl:oFont:height
      nOld := nHeight
      nHeight := Iif( nHeight<0, nHeight-n, nHeight+n )
      oFont := HFont():Add( oCtrl:oFont:name, oCtrl:oFont:Width,nHeight,,oCtrl:oFont:Charset,,,,,.T. )
      hwg_Setctrlfont( oCtrl:oParent:handle, oCtrl:id, ( oCtrl:oFont := oFont ):handle )
      IF __ObjHasMsg( oCtrl, "ACOLUMNS" )
         FOR i := 1 TO Len( oCtrl:aColumns )
            oCtrl:aColumns[i]:width := Int( oCtrl:aColumns[i]:width * (nHeight/nOld) )
         NEXT
         oCtrl:Refresh( .T. )
      ELSE
         hwg_Redrawwindow( oCtrl:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ENDIF

   Return Nil

Static Function ChangeBrwFont()
Local nHold, nHeight, i, j, oBrw, oFont

   IF !Empty( oFont := HFont():Select( m->oBrwFont ) )
      m->oBrwFont := oFont
      nHeight := (m->oBrwFont):height
      FOR i := 1 TO OPENED_FILES_LIMIT
         IF ( oBrw := aFiles[ improc,AF_BRW ] ) != Nil
            nHold := oBrw:oFont:height
            hwg_Setctrlfont( oBrw:oParent:handle, oBrw:id, ( oBrw:oFont := m->oBrwFont ):handle )
            FOR j := 1 TO Len( oBrw:aColumns )
               oBrw:aColumns[j]:width := Int( oBrw:aColumns[j]:width * (nHeight/nHold) )
            NEXT
            oBrw:Refresh( .T. )
         ENDIF
      NEXT
   ENDIF

   Return Nil

Static Function Options()
   LOCAL oDlg, nCp := Ascan( aCpId, cAppCpage ), nDf := Ascan( aDatef, dformat )

   INIT DIALOG oDlg TITLE "Options" ;
      AT 0, 0         ;
      SIZE 300, 320   ;
      FONT oMainFont

   @ 10,10 SAY "Main codepage: " SIZE 100,22 STYLE SS_RIGHT
   @ 110,10 GET COMBOBOX nCp ITEMS aCpInfo SIZE 180,24 DISPLAYCOUNT 12

   @ 10,40 SAY "Date format: " SIZE 100,22 STYLE SS_RIGHT
   @ 110,40 GET COMBOBOX nDf ITEMS aDateF SIZE 140,24 DISPLAYCOUNT Len(aDateF)

   @  30, 268  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 170, 268 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   oDlg:Activate()

   IF oDlg:lResult

      dformat := aDatef[ nDf ]
      SET DATE FORMAT dformat
      hb_cdpSelect( cAppCpage := aCpId[ nCp ] )

   ENDIF

   Return Nil

STATIC FUNCTION EditRec()
   LOCAL oDlg, oBrowse, af := Array( FCount(), 3 ), i, nFile := improc, oBrwM

   FOR i := 1 TO Len( af )
      af[i,1] := dbFieldInfo( 1, i )
      af[i,2] := FieldGet( i )
      IF ( af[i,3] := dbFieldInfo( 2, i ) ) $ "NIBYZ842+^"
         af[i,2] := Str( af[i,2], dbFieldInfo(3,i), dbFieldInfo(4,i) )
      ELSEIF af[i,3] == "D"
         af[i,2] := Dtoc( af[i,2] )
      ELSEIF af[i,3] == "L"
         af[i,2] := Iif( af[i,2], "T", "L" )
      ENDIF
   NEXT

   INIT DIALOG oDlg TITLE "Edit record" ;
      AT 0, 0         ;
      SIZE 440, 320   ;
      FONT oBrwFont

   @ 20,20 BROWSE oBrowse ARRAY   ;
       SIZE 400,230               ;
       STYLE WS_BORDER+WS_VSCROLL ;
       FONT oBrwFont              ;
       ON SIZE ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_BOTTOMABS+ANCHOR_RIGHTABS

   oBrowse:aArray := af
   oBrowse:AddColumn( HColumn():New( "",{|v,o|o:nCurrent},"N",4,0 ) )
   oBrowse:AddColumn( HColumn():New( "Field",{|v,o|o:aArray[o:nCurrent,1]},"C",12,0 ) )
   oBrowse:AddColumn( HColumn():New( "Value",{|v,o|Iif(v==Nil,o:aArray[o:nCurrent,2],o:aArray[o:nCurrent,2]:=v)},"C",40,0,.T. ) )
   oBrowse:bScrollPos := {|o,n,lEof,nPos|hwg_VScrollPos(o,n,lEof,nPos)}

   oBrowse:bcolorSel := BCOLOR_SEL
   oBrowse:tcolorSel := TCOLOR_SEL
#ifndef __GTK__
   oBrowse:bEnter := {|o,n|EdRec(o,n,nFile)}
#endif

   @  30, 268 BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() } ON SIZE ANCHOR_LEFTABS+ANCHOR_BOTTOMABS
   @ 310, 268 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() } ON SIZE ANCHOR_RIGHTABS+ANCHOR_BOTTOMABS

   oDlg:Activate()

   IF oDlg:lResult
      oBrwM := aFiles[ nFile, AF_BRW ]

      IF !aFiles[ nFile, AF_EXCLU ]
         (oBrwM:Alias)->( RLock() )
      ENDIF

      FOR i := 1 TO Len( af )

         IF af[i,3] == "N"
            af[i,2] := Val( af[i,2] )
         ELSEIF af[i,3] == "D"
            af[i,2] := Ctod( af[i,2] )
         ELSEIF af[i,3] == "L"
            af[i,2] := ( af[i,2] == "T" )
         ENDIF
         (oBrwM:Alias)->( FieldPut( i, af[i,2] ) )
      NEXT

      IF !aFiles[ nFile, AF_EXCLU ]
         (oBrwM:Alias)->( dbUnLock() )
      ENDIF
      hwg_Invalidaterect( oBrwM:handle, 0, oBrwM:x1, oBrwM:y1 + ( oBrwM:height + 1 ) * ( oBrwM:rowPos - 2 ), oBrwM:x2, oBrwM:y1 + ( oBrwM:height + 1 ) * oBrwM:rowPos )
      oBrwM:RefreshLine()

   ENDIF

   Return Nil

#ifndef __GTK__
STATIC FUNCTION EdRec( oBrw, n, nFile )
LOCAL oDlg, oBrwM, oColumn, oGet, nField, aCoors, cBuff, x1, y1, nWidth, lReadExit
LOCAL cType, nLen, nDec, cPicture, rowPos

   IF n != 3 .OR. aFiles[ nFile, AF_RDONLY ]
      Return .T.
   ENDIF

   oBrwM := aFiles[ nFile, AF_BRW ]
   oColumn := oBrw:aColumns[n]
   nField := oBrw:nCurrent
   cBuff := oBrw:aArray[nField,2]

   nLen := (oBrwM:Alias)->( dbFieldInfo( 3, nField ) )
   nDec := (oBrwM:Alias)->( dbFieldInfo( 4, nField ) )

   IF ( cType := oBrw:aArray[nField,3] ) == "C"
      cPicture := Replicate( "X", nLen )
   ELSEIF cType == "N"
      cPicture := Iif( nDec==0, Replicate("9",nLen), Replicate("9",nLen-1-nDec)+"."+Replicate("9",nDec) )
      cBuff := Val( cBuff )
   ELSEIF cType == "D"
      cPicture := "@D"
      cBuff := Ctod( cBuff )
   ELSEIF cType == "L"
      cPicture := "L"
   ENDIF

   x1 := oBrw:x1
   y1 := oBrw:nLeftCol - 1
   DO WHILE ++y1 < n
      x1 += oBrw:aColumns[y1]:width
   ENDDO
   nWidth := Min( oColumn:width, oBrw:x2 - x1 - 1 )
   rowPos := oBrw:rowPos - 1
   y1 := oBrw:y1 + ( oBrw:height + 1 ) * ( oBrw:rowPos - 1 )

   aCoors := hwg_Clienttoscreen( oBrw:handle, x1, y1 )
   x1 := aCoors[1]
   y1 := aCoors[2]

   lReadExit := Set( _SET_EXIT, .T. )

   IF cType != "M"
      INIT DIALOG oDlg AT x1, y1 - 1 ;
         STYLE WS_POPUP + 1 + WS_BORDER  ;
         SIZE nWidth, oBrw:height + iif( oColumn:aList == Nil, 1, 0 ) ;
         ON INIT { |o|hwg_Movewindow( o:handle,x1,y1,nWidth,o:nHeight + 1 ) }
   ELSE
      INIT DIALOG oDlg TITLE "Memo edit" AT 0, 0 SIZE 400, 300 ON INIT { |o|o:center() }
   ENDIF

   IF cType != "M"
      @ 0, 0 GET oGet VAR cBuff         ;
         SIZE nWidth, oBrw:height + 1   ;
         NOBORDER                       ;
         STYLE ES_AUTOHSCROLL           ;
         FONT oBrw:oFont                ;
         PICTURE oColumn:picture        ;
         VALID oColumn:bValid
   ELSE
      @ 10, 10 GET cBuff SIZE oDlg:nWidth - 20, 240 FONT oBrw:oFont STYLE WS_VSCROLL + WS_HSCROLL + ES_MULTILINE VALID oColumn:bValid
      @ 10, 252 OWNERBUTTON TEXT "Save" SIZE 80, 24 ON CLICK { ||oDlg:Close(), oDlg:lResult := .T. }
      @ 100, 252 OWNERBUTTON TEXT "Close" SIZE 80, 24 ON CLICK { ||oDlg:Close() }
   ENDIF

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult

      IF cType == "C"
         oBrw:aArray[nField,2] := cBuff
      ELSEIF cType == "N"
         oBrw:aArray[nField,2] := Str( cBuff,nLen,nDec )
      ELSEIF cType == "D"
         oBrw:aArray[nField,2] := Dtoc( cBuff )
      ELSEIF cType == "L"
         oBrw:aArray[nField,2] := Iif( cBuff $ "YT", "T", "L" )
      ENDIF

      hwg_Invalidaterect( oBrw:handle, 0, oBrw:x1, oBrw:y1 + ( oBrw:height + 1 ) * ( oBrw:rowPos - 2 ), oBrw:x2, oBrw:y1 + ( oBrw:height + 1 ) * oBrw:rowPos )
      oBrw:RefreshLine()

   ENDIF
   hwg_Setfocus( oBrw:handle )
   SET( _SET_EXIT, lReadExit )

   Return .T.
#endif
