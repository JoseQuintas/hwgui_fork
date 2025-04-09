/*
 * $Id$
 */

/*
 * HWGUI - Harbour Win32 GUI library source code:
 * The GUI Debugger
 *
 * Copyright 2013 Alexander Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version, with one exception:
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#include "hwgui.ch"
#include "hxml.ch"
#include "fileio.ch"

#define MODE_INPUT      1
#define MODE_INIT       2
#define MODE_WAIT_ANS   3
#define MODE_WAIT_BR    4

#define ANS_BRP         1
#define ANS_CALC        2
#define ANS_STACK       3
#define ANS_LOCAL       4
#define ANS_WATCH       5
#define ANS_AREAS       6
#define ANS_REC         7
#define ANS_OBJECT      8
#define ANS_ARRAY       9

#define CMD_QUIT        1
#define CMD_GO          2
#define CMD_STEP        3
#define CMD_TRACE       4
#define CMD_NEXTR       5
#define CMD_TOCURS      6
#define CMD_EXIT        7
#define CMD_STACK       8
#define CMD_EXP         9
#define CMD_LOCAL      10
#define CMD_STATIC     11
#define CMD_PRIV       12
#define CMD_PUBL       13
#define CMD_WATCH      14
#define CMD_AREA       15
#define CMD_REC        16
#define CMD_OBJECT     17
#define CMD_ARRAY      18
#define CMD_TERMINATE  19

#define BUFF_LEN     1024
#define RES_LEN       100
#define ARR_LEN       100

#define  CLR_LGREEN  12507070
#define  CLR_GREEN      32768
#define  CLR_DBLUE    8404992
#define  CLR_LBLUE1  16759929
#define  CLR_LBLUE2  16764831
#define  CLR_LIGHT1  15132390
#define  CLR_LIGHT2  12632256

#define EDIT_RES         1900

#define MENU_VIEW        1901
#define MENU_STACK       1902
#define MENU_VARS        1903
#define MENU_WATCH       1904
#define MENU_RUN         1905
#define MENU_INIT        1906
#define MENU_QUIT        1907
#define MENU_EXIT        1908
#define MENU_BRP         1909
#define MENU_CMDLINE     1910

#ifdef __PLATFORM__WINDOWS
REQUEST HWG_SAVEFILE, HWG_SELECTFOLDER
#endif
REQUEST GETENV, HB_FGETDATETIME
REQUEST HB_OSPATHLISTSEPARATOR
REQUEST HWG_RUNCONSOLEAPP, HWG_RUNAPP

#ifdef __XHARBOUR__
#xtranslate HB_PROCESSOPEN([<n,...>]) =>  HB_OPENPROCESS(<n>)
#endif

STATIC lModeIde := .T.
STATIC lDebugging := .F.
STATIC hHrbProj
STATIC handl1 := - 1, handl2, cBuffer
STATIC nId1 := 0, nId2 := - 1

STATIC oIni, cHrbPath := "hrb"
STATIC cAppName, cPrgName := ""
STATIC cTextLocate, nLineLocate

STATIC oTimer, oSayState, oEditExpr, oBtnExp, oMainFont
STATIC oBrwRes
STATIC oStackDlg, oVarsDlg, oWatchDlg, oAreasDlg
STATIC oInspectDlg
STATIC cInspectVar
STATIC lViewCmd := .T.
STATIC oTabMain, nTabsMax := 5
STATIC cPaths := ";"

STATIC aBP := {}
STATIC aWatches := {}
STATIC aExpr := {}
STATIC nCurrLine := 0
STATIC nMode, nAnsType, cPrgBP
STATIC aBPLoad, nBPLoad
STATIC lAnimate := .F. , nAnimate := 3

STATIC nExitMode := 1
STATIC nVerProto := 0
STATIC cMsgNotSupp := "Command isn't supported"

#ifdef __HCEDIT__
#define P_X                  1
#define P_Y                  2

STATIC oHighLighter
#endif

MEMVAR cIniPath, cCurrPath

FUNCTION Main( ... )
   LOCAL oMainW
   LOCAL aParams := hb_aParams(), i, j, cFile, cExe, cParams, cDirWait
   PUBLIC cIniPath := FilePath( hb_ArgV( 0 ) ), cCurrPath := ""

   FOR i := 1 TO Len( aParams )
      IF Left( aParams[i], 1 ) == "-"
         IF Left( aParams[i], 2 ) == "-c"
            cFile := SubStr( aParams[i], 3 )
            lModeIde := .F.
         ELSEIF Left( aParams[i], 2 ) == "-w"
            cDirWait := SubStr( aParams[i], 3 )
            lModeIde := .F.
         ENDIF
      ELSE
         lModeIde := .F.
         cExe := aParams[i]
         cParams := ""
         FOR j := i + 1 TO Len( aParams )
            cParams += " " + aParams[j]
         NEXT
         EXIT
      ENDIF
   NEXT

   ReadIni()
   ReadHrb()

   IF Empty( oMainFont )
#ifndef __PLATFORM__WINDOWS
      oMainFont := HFont():Add( "Sans", 0, 12, 400, 4, , , , , .T. )
#else
      PREPARE FONT oMainFont NAME "Georgia" WIDTH 0 HEIGHT - 15 CHARSET 4
#endif
   ENDIF

   INIT WINDOW oMainW MAIN TITLE "Debugger" ;
      AT 200, 0 SIZE 600, 544                  ;
      FONT oMainFont                         ;
      ON EXIT { || ExitDbg() }

   MENU OF oMainW
   MENU TITLE "&File"
   MENUITEM "Debug program" ID MENU_INIT ACTION DebugNewExe()
   SEPARATOR
   MENUITEM "Open source file" + Chr( 9 ) + "Ctrl+O" ACTION OpenPrg() ACCELERATOR FCONTROL, Asc( "O" )
   SEPARATOR
   MENUITEM "Close source file" ACTION oTabMain:DeletePage( oTabMain:GetActivePage() )
   IF lModeIde
      DO( hb_hrbGetFunsym( hHrbProj, "proj_menu_save" ) )
   ENDIF
   SEPARATOR
   MENUITEM "&Close debugger" ID MENU_EXIT ACTION DoCommand( CMD_EXIT )
   MENUITEM "&Exit and terminate program" ID MENU_QUIT ACTION DoCommand( CMD_QUIT )
   ENDMENU
   IF lModeIde
      DO( hb_hrbGetFunsym( hHrbProj, "proj_menu" ) )
   ENDIF
   MENU TITLE "&Search"
   MENUITEM "&Find" + Chr( 9 ) + "Ctrl+F" ACTION Locate( 0 ) ACCELERATOR FCONTROL, Asc( "F" )
   MENUITEM "&Next" + Chr( 9 ) + "F3" ACTION Locate( 1 ) ACCELERATOR 0, VK_F3
   MENUITEM "&Previous" + Chr( 9 ) + "Shift+F3" ACTION Locate( - 1 ) ACCELERATOR FSHIFT, VK_F3
   SEPARATOR
   MENUITEM "&Go to line" + Chr( 9 ) + "Ctrl+G" ACTION GoToLine( )ACCELERATOR FCONTROL, Asc( "G" )
   SEPARATOR
   MENUITEM "&Current position" ACTION iif( lDebugging, SetCurrLine( nCurrLine,cPrgName ), .T. )
   SEPARATOR
   MENUITEM "Functions &list" ACTION Funclist()
   ENDMENU
   MENU ID MENU_VIEW TITLE "&View"
   MENUITEMCHECK "&Stack" ID MENU_STACK ACTION StackToggle()
   MENUITEMCHECK "&Variables" ID MENU_VARS ACTION VarsToggle()
   MENUITEMCHECK "&Watches" ID MENU_WATCH ACTION WatchesToggle()
   SEPARATOR
   MENUITEM "Work&Areas" + Chr( 9 ) + "F6" ACTION InspectAreas() ACCELERATOR 0, VK_F6
   SEPARATOR
   MENUITEMCHECK "&Commands" ID MENU_CMDLINE ACTION ViewCmdLine()
   SEPARATOR
   MENUITEMCHECK "Selected &var" + Chr( 9 ) + "F12" ACTION ViewSelVar() ACCELERATOR 0, VK_F12
   ENDMENU
   MENU ID MENU_RUN TITLE "&Run"
   MENUITEM "&Go" + Chr( 9 ) + "F5" ACTION DoCommand( CMD_GO ) ACCELERATOR 0, VK_F5
   MENUITEM "&Step" + Chr( 9 ) + "F8" ACTION DoCommand( CMD_STEP ) ACCELERATOR 0, VK_F8
   MENUITEM "To &cursor" + Chr( 9 ) + "F7" ACTION DoCommand( CMD_TOCURS ) ACCELERATOR 0, VK_F7
   MENUITEM "&Trace" + Chr( 9 ) + "F10" ACTION DoCommand( CMD_TRACE ) ACCELERATOR 0, VK_F10
   MENUITEM "&Next Routine" + Chr( 9 ) + "Ctrl+F5" ACTION DoCommand( CMD_NEXTR ) ACCELERATOR FCONTROL, VK_F5
   SEPARATOR
   MENUITEM "&Animate" ACTION Animate()
   SEPARATOR
   MENUITEM "T&erminate program" ACTION DoCommand( CMD_TERMINATE )
   ENDMENU
   MENU ID MENU_BRP TITLE "&BreakPoints"
   MENUITEM "&Add" + Chr( 9 ) + "F9" ACTION AddBreakPoint() ACCELERATOR 0, VK_F9
   MENUITEM "&Delete" + Chr( 9 ) + "F9" ACTION AddBreakPoint()
   ENDMENU
   MENU TITLE "&Options"
   MENUITEM "Set &Path" ACTION SetPath( , cPrgName )
   MENUITEM "&Font" ACTION SetFont()
   MENUITEM "&Max Tabs" ACTION ( nTabsMax := iif( !Empty(i := hu_Get( "Max number of tabs:","99",nTabsMax ) ), i, nTabsMax ) )
   SEPARATOR
   MENUITEM "&Save Settings" ACTION SaveIni()
   SEPARATOR
   MENUITEM "Save &breakpoints" ACTION SaveBreaks()
   MENUITEM "&Load breakpoints" ACTION LoadBreaks()
   ENDMENU
   MENU TITLE "&?"
    MENUITEM "&About" ACTION About()
   ENDMENU
   ENDMENU

   @ 0, 0 TAB oTabMain ITEMS {} SIZE 600, 436 ON SIZE { |o, x, y|o:Move( , , x, y - 108 ) }
   oTabMain:bChange2 := { |o, n|iif( Len( o:aControls ) >= n, hwg_setfocus( o:acontrols[n]:handle ), .T. ) }
   CreateTextCtrl()

   @ 4, 444 BROWSE oBrwRes ARRAY SIZE 592, 72 STYLE WS_BORDER + WS_VSCROLL ;
      ON SIZE { |o, x, y|o:Move( , y - 104, x - 8 ) }

   oBrwRes:aArray := {}
   oBrwRes:AddColumn( HColumn():New( "",{ | v, o | (v), o:aArray[ o:nCurrent, 1 ] }, "C", 80, 0 ) )
   oBrwRes:lDispHead := .F.
   oBrwRes:bcolor := CLR_LIGHT1
   oBrwRes:bcolorSel := oBrwRes:htbcolor := CLR_LGREEN
   oBrwRes:tcolorSel := oBrwRes:httcolor := 0
   oBrwRes:bEnter := { |o| iif( o:nCurrent > 0 .AND. o:nCurrent <= o:nRecords, oEditExpr:value := o:aArray[o:nCurrent,2], .T. ) }

   @ 4, 516 SAY oSayState CAPTION "" SIZE 80, 28 STYLE WS_BORDER + SS_CENTER ON SIZE { | o, x, y | (x), o:Move( , y - 32 ) }
   SET KEY 0, VK_RETURN TO KeyPress( VK_RETURN )
   SET KEY 0, VK_UP TO KeyPress( VK_UP )
   SET KEY 0, VK_DOWN TO KeyPress( VK_DOWN )
   @ 84, 516 EDITBOX oEditExpr CAPTION "" ID EDIT_RES SIZE 452, 26 STYLE ES_AUTOHSCROLL ON SIZE { |o, x, y|o:Move( , y - 32, x - 148 ) }
   //oEditExpr := HCEdit():New( , EDIT_RES,, 84, 516, 452, 26,,, {|o,x,y|o:Move(,y-32,x-148)},,,,,, .T. )
   //oEditExpr:nMaxLines := 1
   //oEditExpr:bColorCur := oEditExpr:bColor

   @ 536, 516 BUTTON "-" SIZE 24, 14 ON CLICK { ||PrevExpr( 1 ) } ON SIZE { |o, x, y|o:Move( x - 64, y - 32 ) }
   @ 536, 530 BUTTON "-" SIZE 24, 14 ON CLICK { ||PrevExpr( - 1 ) } ON SIZE { |o, x, y|o:Move( x - 64, y - 18 ) }
   @ 560, 516 BUTTON oBtnExp CAPTION "Ok" SIZE 36, 28 ON CLICK { ||Calc() } ON SIZE { |o, x, y|o:Move( x - 40, y - 32 ) }

   SetMode( MODE_INIT )

   cBuffer := Space( BUFF_LEN )

   IF !Empty( cFile )
      handl1 := FOpen( cFile + ".d1", FO_READWRITE + FO_SHARED )
      handl2 := FOpen( cFile + ".d2", FO_READ + FO_SHARED )
      IF handl1 != - 1 .AND. handl2 != - 1
         cAppName := Lower( CutPath( cFile ) )
      ELSE
         handl1 := handl2 := - 1
         hwg_MsgStop( "No connection" )
      ENDIF
   ELSEIF !Empty( cExe )
      DebugNewExe( cExe, cParams )
   ELSEIF !Empty( cDirWait )
      Wait4Conn( cDirWait )
   ENDIF

   IF lModeIde
      ViewCmdLine( .F. )
   ELSE
      hwg_Checkmenuitem( , MENU_CMDLINE, lViewCmd )
   ENDIF

   SET TIMER oTimer OF oMainW VALUE 30 ACTION { ||TimerProc() }

   ACTIVATE WINDOW oMainW

   RETURN Nil

STATIC FUNCTION ReadHrb()
   LOCAL cHrb

   IF lModeIde
      cHrb := cHrbPath + iif( Right( cHrbPath,1 ) $ "\/", "", hb_OsPathSeparator() ) + ;
         "hwg_project.hrb"
      IF !File( cHrb ) .OR. Empty( hHrbProj := hb_hrbLoad( cHrb ) )
         lModeIde := .F.
      ELSE
         DO( hb_hrbGetFunsym( hHrbProj, "proj_RdIni" ) )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION ReadIni()
   LOCAL oInit, i , cxmlfile

   cxmlfile := cIniPath + "hwgdebug.xml"
   IF FILE(cxmlfile)
   * DF7BE: crashes here, object oIni not constructed, if file not existing !
    oIni := HXMLDoc():Read( cxmlfile )
    IF !Empty( oIni:aItems )
     IF oIni:aItems[1]:title == "init"
       oInit := oIni:aItems[1]
       FOR i := 1 TO Len( oInit:aItems )
          IF oInit:aItems[i]:title == "module"
          ELSEIF oInit:aItems[i]:title == "path"
             cPaths := oInit:aItems[i]:aItems[1]
             IF Left( cPaths, 1 ) != ";"
                cPaths := ";" + cPaths
             ENDIF
          ELSEIF oInit:aItems[i]:title == "font"
             oMainFont := hwg_hfrm_FontFromXML( oInit:aItems[i], .T. )
          ELSEIF oInit:aItems[i]:title == "maxtabs"
             nTabsMax := Val( oInit:aItems[i]:aItems[1] )
          ELSEIF oInit:aItems[i]:title == "hrbpath"
             cHrbPath := oInit:aItems[i]:aItems[1]
          ENDIF
       NEXT
     ENDIF
    ENDIF
   ENDIF && FILE
#ifdef __HCEDIT__
   oHighLighter := Hilight():New( cIniPath + "hilight.xml", "prg" )
#endif

   RETURN Nil

STATIC FUNCTION SaveIni()
   LOCAL oInit, oNode

   IF Empty( oIni ) .OR. Empty( oIni:aItems )
      oIni := HXMLDoc():New( "windows-1251" )
      oIni:Add( oInit := HXMLNode():New( "init" ) )
   ELSE
      oInit := oIni:aItems[1]
   ENDIF

   IF !Empty( oNode := oInit:Find( "path" ) )
      oNode:aItems[1] := cPaths
   ELSE
      oInit:Add( HXMLNode():New( "path",,,cPaths ) )
   ENDIF
   IF !Empty( oNode := oInit:Find( "font" ) )
      oNode:aAttr := Font2Attr( oMainFont )
   ELSE
      oInit:Add( HXMLNode():New( "font", HBXML_TYPE_SINGLE, Font2Attr( oMainFont ) ) )
   ENDIF
   IF !Empty( oNode := oInit:Find( "maxtabs" ) )
      oNode:aItems[1] := LTrim( Str( nTabsMax ) )
   ELSE
      oInit:Add( HXMLNode():New( "maxtabs",,,LTrim(Str(nTabsMax ) ) ) )
   ENDIF

   oIni:Save( cIniPath + "hwgdebug.xml" )

   RETURN Nil

STATIC FUNCTION SaveBreaks()
   LOCAL oInit, oNode, n := 0, lFound := .F.

   IF Empty( cAppName )
      RETURN Nil
   ENDIF
   IF Empty( oIni ) .OR. Empty( oIni:aItems )
      oIni := HXMLDoc():New( "windows-1251" )
      oIni:Add( oInit := HXMLNode():New( "init" ) )
   ELSE
      oInit := oIni:aItems[1]
   ENDIF

   DO WHILE .T.
      n ++
      IF Empty( oNode := oInit:Find( "app", @n ) )
         EXIT
      ELSEIF oNode:GetAttribute( "name" ) == cAppName
         lFound := .T.
         oNode:aItems := {}
         EXIT
      ENDIF
   ENDDO
   IF !lFound
      oInit:Add( oNode := HXMLNode():New( "app",, { { "name",cAppName } } ) )
   ENDIF
   FOR n := 1 TO Len( aBP )
      oNode:Add( HXMLNode():New( "brp", HBXML_TYPE_SINGLE, { { "prg",aBP[n,2] }, { "line",LTrim(Str(aBP[n,1] ) ) } } ) )
   NEXT
   oIni:Save( cIniPath + "hwgdebug.xml" )

   RETURN Nil

STATIC FUNCTION LoadBreaks()
   LOCAL oInit, oNode, n := 0, nLine, cPrg

   IF Empty( cAppName )
      RETURN Nil
   ENDIF
   IF Empty( oIni ) .OR. Empty( oIni:aItems )
      RETURN Nil
   ENDIF

   oInit := oIni:aItems[1]
   DO WHILE .T.
      n ++
      IF Empty( oNode := oInit:Find( "app", @n ) )
         EXIT
      ELSEIF oNode:GetAttribute( "name" ) == cAppName
         aBPLoad := {}
         FOR n := 1 TO Len( oNode:aItems )
            IF oNode:aItems[n]:title == "brp"
               nLine := Val( oNode:aItems[n]:GetAttribute( "line" ) )
               cPrg := oNode:aItems[n]:GetAttribute( "prg" )
               IF getBP( nLine, cPrg ) == 0
                  AAdd( aBPLoad, { nLine, cPrg } )
               ENDIF
            ENDIF
         NEXT
         IF !Empty( aBPLoad )
            nBPLoad := 1
            AddBreakPoint( aBPLoad[1,2], aBPLoad[1,1] )
         ENDIF
         EXIT
      ENDIF
   ENDDO

   RETURN Nil

FUNCTION DebugNewExe( cExe, cParams )

   IF cExe == Nil
      IF !Empty( cExe := hwg_Selectfile( "Executable files( *.exe )", "*.exe", CurDir() ) )
         aBP := {}
         aWatches := {}
         aExpr := {}
         nCurrLine := 0
         nId1 := 0
         nId2 := - 1
      ELSE
         RETURN Nil
      ENDIF
   ENDIF

   IF !File( cExe )
      hwg_MsgStop( cExe + " isn't found..." )
      RETURN Nil
   ENDIF

   FErase( cExe + ".d1" )
   FErase( cExe + ".d2" )

   handl1 := FCreate( cExe + ".d1" )
   FWrite( handl1, "init,!" )
   FClose( handl1 )
   handl2 := FCreate( cExe + ".d2" )
   FClose( handl2 )

   hb_processOpen( cExe + iif( !Empty( cParams ), cParams, "" ) )

   handl1 := FOpen( cExe + ".d1", FO_READWRITE + FO_SHARED )
   handl2 := FOpen( cExe + ".d2", FO_READ + FO_SHARED )
   IF handl1 != - 1 .AND. handl2 != - 1
      cAppName := Lower( CutPath( cExe ) )
   ELSE
      handl1 := handl2 := - 1
      hwg_MsgStop( "No connection" )
   ENDIF

   RETURN Nil

STATIC FUNCTION Wait4Conn( cDir )

   cDir += iif( Right( cDir,1 ) $ "\/", "", hb_OsPathSeparator() ) + "hwgdebug"
   FErase( cDir + ".d1" )
   FErase( cDir + ".d2" )

   handl1 := FCreate( cDir + ".d1" )
   FWrite( handl1, "init,!" )
   FClose( handl1 )
   handl2 := FCreate( cDir + ".d2" )
   FClose( handl2 )

   handl1 := FOpen( cDir + ".d1", FO_READWRITE + FO_SHARED )
   handl2 := FOpen( cDir + ".d2", FO_READ + FO_SHARED )
   IF handl1 != - 1 .AND. handl2 != - 1
   ELSE
      handl1 := handl2 := - 1
      hwg_MsgStop( "No connection" )
   ENDIF

   RETURN Nil

STATIC FUNCTION dbgRead()
   LOCAL n, s := "", arr

   FSeek( handl2, 0, 0 )
   DO WHILE ( n := FRead( handl2, @cBuffer, Len(cBuffer ) ) ) > 0
      s += Left( cBuffer, n )
      IF ( n := At( ",!", s ) ) > 0
         IF ( arr := hb_aTokens( Left( s,n + 1 ), "," ) ) != Nil .AND. Len( arr ) > 2 .AND. arr[1] == arr[Len(arr)-1]
            RETURN arr
         ELSE
            EXIT
         ENDIF
      ENDIF
   ENDDO

   RETURN Nil

STATIC FUNCTION Send( ... )
   LOCAL arr := hb_aParams(), i, s := ""

   FSeek( handl1, 0, 0 )
   FOR i := 1 TO Len( arr )
      s += arr[i] + ","
   NEXT
   FWrite( handl1, LTrim( Str( ++ nId1 ) ) + "," + s + LTrim( Str(nId1 ) ) + ",!" )

   RETURN Nil

STATIC FUNCTION TimerProc()
   LOCAL n, arr, xTmp
   STATIC nLastSec := 0

   IF nMode != MODE_INPUT
      IF !Empty( arr := dbgRead() )
         IF arr[1] == "quit"
            SetMode( MODE_INIT )
            StopDebug()
            RETURN Nil
         ENDIF
         IF nMode == MODE_WAIT_ANS
            IF Left( arr[1], 1 ) == "b" .AND. ( n := Val( SubStr(arr[1],2 ) ) ) == nId1
               IF nAnsType == ANS_CALC
                  IF arr[2] == "value"
                     IF !Empty( cInspectVar )
                        IF ( xTmp := SubStr( Hex2Str(arr[3] ),2,1 ) ) == "O"
                           nMode := MODE_INPUT
                           InspectObject( cInspectVar )
                           cInspectVar := Nil
                           RETURN Nil
                        ELSEIF xTmp == "A"
                           nMode := MODE_INPUT
                           InspectArray( cInspectVar )
                           cInspectVar := Nil
                           RETURN Nil
                        ELSE
                           nMode := MODE_INPUT
                           Calc( cInspectVar )
                           RETURN Nil
                        ENDIF
                     ELSE
                        SetResult( Hex2Str( arr[3] ) )
                     ENDIF
                  ELSE
                     oEditExpr:value := "-- BAD ANSWER --"
                  ENDIF
               ELSEIF nAnsType == ANS_BRP
                  IF arr[2] == "err"
                     oEditExpr:value := "-- BAD LINE --"
                  ELSE
                     ToggleBreakPoint( arr[2], arr[3] )
                  ENDIF
                  IF !Empty( aBPLoad )
                     IF ++ nBPLoad <= Len( aBPLoad )
                        AddBreakPoint( aBPLoad[nBPLoad,2], aBPLoad[nBPLoad,1] )
                        RETURN Nil
                     ELSE
                        aBPLoad := Nil
                     ENDIF
                  ENDIF
               ELSEIF nAnsType == ANS_STACK
                  IF arr[2] == "stack"
                     ShowStack( arr, 3 )
                  ENDIF
               ELSEIF nAnsType == ANS_LOCAL
                  IF arr[2] == "valuelocal"
                     ShowVars( arr, 3, 1 )
                  ELSEIF arr[2] == "valuepriv"
                     ShowVars( arr, 3, 2 )
                  ELSEIF arr[2] == "valuepubl"
                     ShowVars( arr, 3, 3 )
                  ELSEIF arr[2] == "valuestatic"
                     ShowVars( arr, 3, 4 )
                  ENDIF
               ELSEIF nAnsType == ANS_WATCH
                  IF arr[2] == "valuewatch"
                     ShowWatch( arr, 3 )
                  ENDIF
               ELSEIF nAnsType == ANS_AREAS
                  IF arr[2] == "valueareas"
                     ShowAreas( arr, 3 )
                  ENDIF
               ELSEIF nAnsType == ANS_REC
                  IF arr[2] == "valuerec"
                     ShowRec( arr, 3 )
                  ENDIF
               ELSEIF nAnsType == ANS_OBJECT
                  IF arr[2] == "valueobj"
                     ShowObject( arr, 3 )
                  ENDIF
               ELSEIF nAnsType == ANS_ARRAY
                  IF arr[2] == "valuearr"
                     ShowArray( arr, 3 )
                  ENDIF
               ENDIF
               SetMode( MODE_INPUT )
            ENDIF
         ELSE
            IF Left( arr[1], 1 ) == "a" .AND. ( n := Val( SubStr(arr[1],2 ) ) ) > nId2
               nId2 := n
               IF arr[2] == "."
                  oEditExpr:value := "-- BAD LINE --"
               ELSE
                  IF !( cPrgName == arr[2] )
                     cPrgName := arr[2]
                     SetPath( cPaths, cPrgName )
                  ENDIF
                  SetCurrLine( nCurrLine := Val( arr[3] ), cPrgName )
                  n := 4
                  DO WHILE .T.
                     IF arr[n] == "ver"
                        nVerProto := Val( arr[n+1] )
                        n += 2
                     ELSEIF arr[n] == "stack"
                        ShowStack( arr, n + 1 )
                        n += 2 + Val( arr[n+1] ) * 3
                     ELSEIF arr[n] == "valuelocal"
                        ShowVars( arr, n + 1, 1 )
                        n += 2 + Val( arr[n+1] ) * 3
                     ELSEIF arr[n] == "valuepriv"
                        ShowVars( arr, n + 1, 2 )
                        n += 2 + Val( arr[n+1] ) * 3
                     ELSEIF arr[n] == "valuepubl"
                        ShowVars( arr, n + 1, 3 )
                        n += 2 + Val( arr[n+1] ) * 3
                     ELSEIF arr[n] == "valuestatic"
                        ShowVars( arr, n + 1, 4 )
                        n += 2 + Val( arr[n+1] ) * 3
                     ELSEIF arr[n] == "valuewatch"
                        ShowWatch( arr, n + 1 )
                        n += 2 + Val( arr[n+1] )
                     ELSE
                        EXIT
                     ENDIF
                  ENDDO
                  // Set Inspectors to nonactual state
                  FOR n := 1 TO Len( HDialog():aDialogs )
                     IF ValType( xTmp := HDialog():aDialogs[n]:cargo ) == "A" .AND. ;
                           !Empty( xTmp ) .AND. ValType( xTmp[1] ) == "C" .AND. xTmp[1] == "f"
                        xTmp[2] := .F.
                        HDialog():aDialogs[n]:aControls[2]:Setcolor( 0, 255, .T. )
                     ENDIF
                  NEXT
                  hwg_Setwindowtext( HWindow():GetMain():handle, "Debugger (" + arr[2] + ", line " + arr[3] + ")" )
               ENDIF
               SetMode( MODE_INPUT )
               nLastSec := Seconds()
            ENDIF
         ENDIF
      ENDIF
   ELSEIF lAnimate .AND. Seconds() - nLastSec > nAnimate
      Send( "cmd", "step" )
      SetMode( MODE_WAIT_BR )
   ENDIF

   RETURN Nil

STATIC FUNCTION SetMode( newMode )
   LOCAL aStates := { { "Input",16711680,CLR_LGREEN }, { "Init",16777215,CLR_DBLUE }, { "Wait",16777215,255 }, { "Run",16777215,0 } }

   nMode := newMode
   hwg_Enablemenuitem( , MENU_RUN, ( newmode == MODE_INPUT ), .T. )
   hwg_Enablemenuitem( , MENU_VIEW, ( newmode == MODE_INPUT ), .T. )
   hwg_Enablemenuitem( , MENU_BRP, ( newmode == MODE_INPUT ), .T. )
   hwg_Enablemenuitem( , MENU_QUIT, ( newmode == MODE_INPUT ), .T. )
   hwg_Drawmenubar( HWindow():GetMain():handle )
   oSayState:SetText( aStates[ newMode,1 ] )
   oSayState:Setcolor( aStates[ newMode,2 ], aStates[ newMode,3 ], .T. )
   IF newMode == MODE_INPUT
      oBtnExp:Enable()
#ifndef __PLATFORM__WINDOWS
#else
      hwg_SetForeGroundWindow( HWindow():GetMain():handle )
#endif
   ELSE
      oBtnExp:Disable()
      IF newMode == MODE_WAIT_ANS .OR. newMode == MODE_WAIT_BR
         IF newMode == MODE_WAIT_BR
            nCurrLine := 0
            SetCurrLine()
         ENDIF
      ELSEIF newMode == MODE_INIT
         hwg_Enablemenuitem( , MENU_INIT, .T. , .T. )
         lDebugging := .F.
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION DoCommand( nCmd, cDop, cDop2, cDop3 )

   IF nMode == MODE_INPUT
      lAnimate := .F.
      IF nCmd == CMD_GO
         hwg_Setwindowtext( HWindow():GetMain():handle, "Debugger (" + cPrgName + ")" )
         Send( "cmd", "go" )

      ELSEIF nCmd == CMD_STEP
         Send( "cmd", "step" )

      ELSEIF nCmd == CMD_TOCURS
         Send( "cmd", "to", cPrgName, LTrim( Str(GetCurrLine() ) ) )

      ELSEIF nCmd == CMD_TRACE
         Send( "cmd", "trace" )

      ELSEIF nCmd == CMD_NEXTR
         Send( "cmd", "nextr" )

      ELSEIF nCmd == CMD_EXP
         Send( "exp", cDop )
         nAnsType := ANS_CALC
         SetMode( MODE_WAIT_ANS )
         RETURN Nil

      ELSEIF nCmd == CMD_STACK
         Send( "view", "stack", cDop )
         nAnsType := ANS_STACK
         SetMode( MODE_WAIT_ANS )
         RETURN Nil

      ELSEIF nCmd == CMD_LOCAL
         Send( "view", "local", cDop )
         nAnsType := ANS_LOCAL
         SetMode( MODE_WAIT_ANS )
         RETURN Nil

      ELSEIF nCmd == CMD_PRIV
         IF nVerProto > 1
            Send( "view", "priv", cDop )
            nAnsType := ANS_LOCAL
            SetMode( MODE_WAIT_ANS )
         ELSE
            hwg_MsgStop( cMsgNotSupp )
         ENDIF
         RETURN Nil

      ELSEIF nCmd == CMD_PUBL
         IF nVerProto > 1
            Send( "view", "publ", cDop )
            nAnsType := ANS_LOCAL
            SetMode( MODE_WAIT_ANS )
         ELSE
            hwg_MsgStop( cMsgNotSupp )
         ENDIF
         RETURN Nil

      ELSEIF nCmd == CMD_STATIC
         IF nVerProto > 1
            Send( "view", "static", cDop )
            nAnsType := ANS_LOCAL
            SetMode( MODE_WAIT_ANS )
         ELSE
            hwg_MsgStop( cMsgNotSupp )
         ENDIF
         RETURN Nil

      ELSEIF nCmd == CMD_WATCH
         IF Empty( cDop2 )
            Send( "view", "watch", cDop )
         ELSE
            Send( "watch", cDop, cDop2 )
         ENDIF
         nAnsType := ANS_WATCH
         SetMode( MODE_WAIT_ANS )
         RETURN Nil

      ELSEIF nCmd == CMD_AREA
         Send( "view", "areas" )
         nAnsType := ANS_AREAS
         SetMode( MODE_WAIT_ANS )
         RETURN Nil

      ELSEIF nCmd == CMD_REC
         IF nVerProto > 1
            Send( "insp", "rec", cDop )
            nAnsType := ANS_REC
            SetMode( MODE_WAIT_ANS )
         ELSE
            hwg_MsgStop( cMsgNotSupp )
         ENDIF
         RETURN Nil

      ELSEIF nCmd == CMD_OBJECT
         IF nVerProto > 1
            Send( "insp", "obj", cDop )
            nAnsType := ANS_OBJECT
            SetMode( MODE_WAIT_ANS )
         ELSE
            hwg_MsgStop( cMsgNotSupp )
         ENDIF
         RETURN Nil

      ELSEIF nCmd == CMD_ARRAY
         IF nVerProto > 2
            Send( "insp", "arr", cDop, cDop2, cDop3 )
            nAnsType := ANS_ARRAY
            SetMode( MODE_WAIT_ANS )
         ELSE
            hwg_MsgStop( cMsgNotSupp )
         ENDIF
         RETURN Nil

      ELSEIF nCmd == CMD_QUIT
         nExitMode := 2
         hwg_EndWindow()
         RETURN Nil

      ELSEIF nCmd == CMD_EXIT
         nExitMode := 1
         hwg_EndWindow()
         RETURN Nil

      ELSEIF nCmd == CMD_TERMINATE
         Send( "cmd", "quit" )
         lDebugging := .F.
         StopDebug()

      ENDIF
      SetMode( MODE_WAIT_BR )
   ELSEIF nCmd == CMD_EXIT
      nExitMode := 1
      hwg_EndWindow()

   ENDIF

   RETURN Nil

STATIC FUNCTION SetPath( cRes, cName, lClear )
   LOCAL arr, i, cFull

   IF !Empty( cRes ) .OR. !Empty( cRes := hu_Get( "Path to source files", Replicate("X",256), cPaths ) )
      cPaths := iif( Left( cRes,1 ) != ";", ";" + cRes, cRes )
      arr := hb_aTokens( cPaths, ";" )
      IF !Empty( cName )
         FOR i := 1 TO Len( arr )
            cFull := arr[i] + ;
               iif( Empty( arr[i] ) .OR. Right( arr[i],1 ) $ "\/", "", hb_OsPathSeparator() ) + cPrgName
            IF SetText( cFull, lClear )
               EXIT
            ENDIF
         NEXT
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION OpenPrg()
   LOCAL cFile := hwg_Selectfile( "Source files( *.prg )", "*.prg", cCurrPath )

   IF !Empty( cFile )
      SetText( cFile )
   ENDIF

   RETURN Nil

FUNCTION GetTextObj( cName, nTab )
   LOCAL i, oText

   IF Empty( cName )
      oText := oTabMain:aControls[ nTab := oTabMain:GetActivePage() ]
   ELSE
      FOR i := 1 TO Len( oTabMain:aControls )
         IF oTabMain:aControls[i]:cargo == cName
            oText := oTabMain:aControls[i]
            nTab := i
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN oText

#ifdef __HCEDIT__

#define HILIGHT_KEYW    1

#define HILIGHT_FUNC    2

#define HILIGHT_QUOTE   3

#define HILIGHT_COMM    4

STATIC FUNCTION CreateTextCtrl()
   LOCAL oText

   BEGIN PAGE "Empty" of oTabMain
#ifdef __GTK__
   oText := HCEdit():New( oTabMain, , , 4, 4, 592, 426, oMainFont, , { |o, x, y|o:Move( ,,x - 8,y - 10 ) } )
#else
   oText := HCEdit():New( oTabMain, , , 10, 30, oTabMain:nWidth - 20, oTabMain:nHeight - 36, oMainFont, , ;
      { |o, x, y|o:Move( , , x - 20, y - 36 ) }, , , , , , , .T. )
#endif
   END PAGE of oTabMain

   oText:HighLighter( Hilight():New( cIniPath + "hilight.xml", "prg" ) )
   oText:lReadOnly := !lModeIde
   oText:lShowNumbers := .T.
   oText:bPaint := { |o, h, n, y1, y2| onTxtPaint( o, h, n, y1, y2 ) }
   oText:bKeyDown := { |o, n|iif( n == 120 .OR. n == 13, AddBreakPoint(), - 1 ) }
   oText:bClickDoub := { ||AddBreakPoint() }
   oText:HighLighter( oHighLighter )

   oText:SetHili( HILIGHT_KEYW, oText:oFont:SetFontStyle( .T. ), 8388608, oText:bColor )
   oText:SetHili( HILIGHT_FUNC, 0, 8388608, oText:bColor )
   oText:SetHili( HILIGHT_QUOTE, 0, 16711680, oText:bColor )
   oText:SetHili( HILIGHT_COMM, oText:oFont:SetFontStyle( ,, .T. ), 32768, oText:bColor )

   RETURN oText

STATIC FUNCTION onTxtPaint( oText, hDC, nLine, y1, y2 )
   LOCAL y
   STATIC oPenCurr, oPenBP

   IF nLine == Nil
      oText:n4Separ += 12
   ELSE
      IF Empty( oPenCurr )
         oPenCurr := HPen():Add( , 2, 8388608 )
         oPenBP := HPen():Add( , 2, 255 )
      ENDIF
      IF nCurrLine == nLine
         IF !( cPrgName == oText:cargo )
            RETURN Nil
         ENDIF
         y := y1 + Int( ( y2 - y1 )/2 )
         hwg_Selectobject( hDC, oPenCurr:handle )
         hwg_Drawline( hDC, oText:n4Separ - 12, y - 3, oText:n4Separ - 4, y )
         hwg_Drawline( hDC, oText:n4Separ - 12, y + 3, oText:n4Separ - 4, y )
      ELSEIF getBP( nLine, oText:cargo ) != 0
         hwg_Selectobject( hDC, oPenBP:handle )
         y := y1 + Int( ( y2 - y1 )/2 )
         hwg_Ellipse( hDC, oText:n4Separ - 12, y - 4, oText:n4Separ - 4, y + 4 )
         hwg_Ellipse( hDC, oText:n4Separ - 10, y - 2, oText:n4Separ - 6, y + 2 )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION SetCurrLine( nLine, cName )
   LOCAL nTab, oText := GetTextObj( cName, @nTab )

   IF !lDebugging
      IF !lViewCmd
         ViewCmdLine( .T. )
      ENDIF
      hwg_Enablemenuitem( , MENU_INIT, .F. , .T. )
      lDebugging := .T.
      IF !Empty( oText )
         oText:lReadOnly := .T.
      ENDIF
   ENDIF

   IF !Empty( oText )
      IF !Empty( nLine ) .AND. oText:nTextLen >= nLine
         oTabMain:SetTab( nTab )
         oText:GoTo( nLine )
      ELSE
         oText:Refresh()
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION SetText( cName, lClear )
   LOCAL oText, nTab, i

   IF cName == Nil; cName := cPrgName; ENDIF

   IF !Empty( GetTextObj( CutPath( cName ) ) )
      RETURN .T.
   ENDIF
   FOR i := Len( oTabMain:aControls ) TO 1 STEP - 1
      IF Empty( oTabMain:aControls[i]:cargo ) .AND. oTabMain:aControls[i]:nTextLen <= 1
         oText := oTabMain:aControls[i]
         nTab := i
         EXIT
      ENDIF
   NEXT
   IF Empty( oText )
      IF Len( oTabMain:aControls ) < nTabsMax
         oText := CreateTextCtrl()
         nTab := Len( oTabMain:aControls )
      ELSE
         oText := oTabMain:aControls[nTabsMax]
         nTab := nTabsMax
      ENDIF
   ENDIF

   oTabMain:SetTab( nTab )
   IF File( cName )
      cCurrPath := FilePath( cName )
      oText:Open( cName )
      FOR i := 1 TO Len( oText:aText )
         IF Chr( 9 ) $ oText:aText[i]
            oText:aText[i] := StrTran( oText:aText[i], Chr( 9 ), Space( 4 ) )
         ENDIF
      NEXT
      oText:lReadOnly := lDebugging
      hwg_SetTabName( oTabMain:handle, nTab, oText:cargo := CutPath( cName ) )
      RETURN .T.
   ELSEIF !Empty( lClear )
      oText:SetText( "" )
      oText:cargo := ""
      hwg_SetTabName( oTabMain:handle, nTab, "Empty" )
   ENDIF

   RETURN .F.

STATIC FUNCTION SetTextFont( oFont )
   LOCAL oText := oTabMain:aControls[ oTabMain:GetActivePage() ]

   RETURN iif( Empty( oText ), Nil, oText:SetFont( oFont ) )

STATIC FUNCTION GetTextArr()
   LOCAL oText := oTabMain:aControls[ oTabMain:GetActivePage() ]

   RETURN iif( Empty( oText ), Nil, oText:aText )

STATIC FUNCTION GetCurrLine()
   LOCAL oText := oTabMain:aControls[ oTabMain:GetActivePage() ]

   RETURN iif( Empty( oText ), 0, oText:nLineF + oText:nLineC - 1 )

#else

STATIC FUNCTION CreateTextCtrl()
   LOCAL oText

   BEGIN PAGE "Empty" of oTabMain
#ifdef __GTK__
   @ 4, 4 BROWSE oText OF oTabMain ARRAY SIZE 592, 426  ;
      FONT oMainFont STYLE WS_BORDER + WS_VSCROLL ;
      ON SIZE { |o, x, y|o:Move( , , x - 8, y - 32 ) }
#else
   @ 10, 30 BROWSE oText OF oTabMain ARRAY SIZE oTabMain:nWidth - 20, oTabMain:nHeight - 36  ;
      FONT oMainFont NOBORDER ;
      ON SIZE { |o, x, y|o:Move( , , x - 20, y - 36 ) }
#endif
   END PAGE of oTabMain

   oText:aArray := {}

   oText:AddColumn( HColumn():New( "",{ |v,o| (v), iif(cPrgName == o:cargo,iif(o:nCurrent == nCurrLine,'>',iif(getBP(o:nCurrent ) != 0,'#',' ' ) ),' ' ) },"C",2,0 ) )
   oText:aColumns[1]:oFont := oMainFont:SetFontStyle( .T. )
   oText:aColumns[1]:bColorBlock := { ||iif( getBP( oText:nCurrent ) != 0, { 65535, 255, 16777215, 255 }, { oText:tColor, oText:bColor, oText:tColorSel, oText:bColorSel } ) }

   oText:AddColumn( HColumn():New( "",{ |v,o| (v), o:nCurrent },"N",5,0 ) )
   oText:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent] },"C",80,0 ) )

   oText:bEnter := { ||AddBreakPoint() }
   oText:lDispHead := .F.
   oText:bcolorSel := oText:htbcolor := CLR_LGREEN
   oText:tcolorSel := 0

   RETURN oText

STATIC FUNCTION SetCurrLine( nLine, cName )
   LOCAL nLine1, nTab, oText := GetTextObj( cName, @nTab )

   IF !lDebugging
      IF !lViewCmd
         ViewCmdLine( .T. )
      ENDIF
      hwg_Enablemenuitem( , MENU_INIT, .F. , .T. )
      lDebugging := .T.
   ENDIF

   IF !Empty( oText ) .AND. !Empty( oText:aArray )
      IF !Empty( nLine )
         oTabMain:SetTab( nTab )
         nLine1 := oText:nCurrent - oText:rowPos + 1
         oText:nCurrent := nLine
         IF nLine < nLine1 .OR. nLine > nLine1 + oText:rowCount - 1
            oText:rowPos := Int( oText:rowCount / 2 )
         ENDIF
         IF oText:rowPos > nLine
            oText:rowPos := nLine
         ENDIF
         hwg_VScrollPos( oText, 0, .F. )
      ENDIF
      oText:Refresh()
   ENDIF

   RETURN Nil

STATIC FUNCTION SetText( cName, lClear )
   LOCAL oText, nTab, cBuff, cNewLine := Chr( 13 ) + Chr( 10 ), i

   IF cName == Nil; cName := cPrgName; ENDIF

   IF !Empty( GetTextObj( CutPath( cName ) ) )
      RETURN .T.
   ENDIF

   FOR i := Len( oTabMain:aControls ) TO 1 STEP - 1
      IF Empty( oTabMain:aControls[i]:cargo )
         oText := oTabMain:aControls[i]
         nTab := i
         EXIT
      ENDIF
   NEXT
   IF Empty( oText )
      IF Len( oTabMain:aControls ) < nTabsMax
         oText := CreateTextCtrl()
         nTab := Len( oTabMain:aControls )
      ELSE
         oText := oTabMain:aControls[nTabsMax]
         nTab := nTabsMax
      ENDIF
   ENDIF

   IF File( cName ) .AND. !Empty( cBuff := MemoRead( cName ) )
      IF !( cNewLine $ cBuff )
         cNewLine := Chr( 10 )
      ENDIF
      cCurrPath := FilePath( cName )
      oText:aArray := hb_aTokens( cBuff, cNewLine )
      FOR i := 1 TO Len( oText:aArray )
         IF Chr( 9 ) $ oText:aArray[i]
            oText:aArray[i] := StrTran( oText:aArray[i], Chr( 9 ), Space( 4 ) )
         ENDIF
      NEXT
      hwg_SetTabName( oTabMain:handle, nTab, oText:cargo := CutPath( cName ) )
      oTabMain:SetTab( nTab )
      hwg_Invalidaterect( oText:handle, 1 )
      oText:Refresh()
      RETURN .T.
   ELSEIF !Empty( lClear )
      oText:aArray := {}
      oText:cargo := ""
      hwg_SetTabName( oTabMain:handle, nTab, "Empty" )
      oTabMain:SetTab( nTab )
      hwg_Invalidaterect( oText:handle, 1 )
      oText:Refresh()
   ENDIF

   RETURN .F.

STATIC FUNCTION SetTextFont( oFont )
   LOCAL oText := oTabMain:aControls[ oTabMain:GetActivePage() ]

   IF !Empty( oText )
      oText:oFont := oFont
      oText:Refresh()
   ENDIF

   RETURN Nil

STATIC FUNCTION GetTextArr()
   LOCAL oText := oTabMain:aControls[ oTabMain:GetActivePage() ]

   RETURN iif( Empty( oText ), Nil, oText:aArray )

STATIC FUNCTION GetCurrLine()

   LOCAL oText := oTabMain:aControls[ oTabMain:GetActivePage() ]

   RETURN iif( Empty( oText ), 0, oText:nCurrent )

#endif

STATIC FUNCTION GoToLine()
   LOCAL nLine := GetCurrLine()

   nLine = hu_Get( "Go to line", "999999", nLine )
   IF !Empty( nLine )
      SetCurrLine( nLine )
   ENDIF

   RETURN nil

STATIC FUNCTION LOCATE( nDir )
   LOCAL i, arr := GetTextArr()

   IF Empty( arr )
      RETURN Nil
   ENDIF
   IF nDir == 0 .OR. nDir > 0
      IF nDir == 0
         cTextLocate := hu_Get( "Search string", "@S256", "" )
         nLineLocate := 0
      ELSEIF Empty( nLineLocate )
         RETURN Nil
      ENDIF
      IF !Empty( cTextLocate )
         cTextLocate := Lower( cTextLocate )
         FOR i := nLineLocate + 1 TO Len( arr )
            IF cTextLocate $ Lower( arr[i] )
               nLineLocate := i
               EXIT
            ENDIF
         NEXT
         IF i > Len( arr )
            hwg_MsgStop( "String isn't found" )
         ELSE
            SetCurrLine( nLineLocate )
         ENDIF
      ENDIF
   ELSEIF nDir < 0
      IF !Empty( cTextLocate ) .AND. !Empty( nLineLocate )
         FOR i := nLineLocate - 1 TO 1 STEP - 1
            IF cTextLocate $ Lower( arr[i] )
               nLineLocate := i
               EXIT
            ENDIF
         NEXT
      ENDIF
      IF i == 0
         hwg_MsgStop( "String isn't found" )
      ELSE
         SetCurrLine( nLineLocate )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION Funclist()
   LOCAL i, arr := GetTextArr(), cLine, cfirst, cSecond, nSkip, arrfnc := {}, lClassDef := .F.

   IF Empty( arr )
      RETURN Nil
   ENDIF
   FOR i := 1 TO Len( arr )
      cLine := Lower( LTrim( arr[i] ) )
      nSkip := 0
      cfirst := hb_TokenPtr( cLine, @nSkip )
      IF cfirst == "function" .OR. cfirst == "procedure" .OR. ;
            ( cfirst == "method" .AND. !lClassDef ) .OR. cfirst == "func" .OR. cfirst == "proc" .OR. ;
            ( cfirst == "static" .AND. ( ( cSecond := hb_TokenPtr( cLine, @nSkip ) ) == "function" .OR. ;
            cSecond == "procedure" .OR. cSecond == "func" .OR. cSecond == "proc" ) )
         AAdd( arrfnc, { Left( arr[i],72 ), i } )
      ENDIF
      IF cfirst == "class" .OR. ( cfirst == "create" .AND. ( cSecond := hb_TokenPtr( cLine, @nSkip ) ) == "class" )
         IF cfirst == "create" .OR. ( !( ( cSecond := hb_TokenPtr( cLine, @nSkip ) ) == "var" ) ;
               .AND. !( cSecond == "data" ) )
            lClassDef := .T.
            AAdd( arrfnc, { Left( arr[i],72 ), i } )
         ENDIF
      ELSEIF cfirst == "end" .OR. cfirst == "endclass"
         lClassDef := .F.
      ENDIF
   NEXT
   IF !Empty( arrfnc ) .AND. ( i := hwg_WChoice( arrfnc, "Functions list",,,HWindow():GetMain():oFont ) ) != 0
      SetCurrLine( arrfnc[i,2] )
   ENDIF

   RETURN Nil

STATIC FUNCTION Animate()
   LOCAL n := hu_Get( "Seconds:", "9", nAnimate )

   IF !Empty( n )
      nAnimate := n
      lAnimate := .T.
      DoCommand( CMD_STEP )
   ENDIF

   RETURN Nil

STATIC FUNCTION getBP( nLine, cPrg )

   cPrg := Lower( iif( cPrg == Nil, cPrgName, cPrg ) )

   RETURN Ascan( aBP, { |a|a[1] == nLine .AND. Lower( a[2] ) == cPrg } )

STATIC FUNCTION ToggleBreakPoint( cAns, cLine )
   LOCAL nLine := Val( cLine ), i

   IF cAns == "line"
      FOR i := 1 TO Len( aBP )
         IF aBP[i,1] == 0
            aBP[i,1] := nLine
            EXIT
         ENDIF
      NEXT
      IF i > Len( aBP )
         AAdd( aBP, { nLine, cPrgBP } )
      ENDIF
   ELSE
      IF ( i := getBP( nLine, cPrgBP ) ) == 0
         hwg_MsgInfo( "Error deleting BP line " + cLine )
      ELSE
         aBP[i,1] := 0
      ENDIF
   ENDIF
   SetCurrLine()

   RETURN Nil

STATIC FUNCTION AddBreakPoint( cPrg, nLine )
   LOCAL oText

   IF nMode != MODE_INPUT .AND. Empty( aBPLoad )
      RETURN Nil
   ENDIF
   IF lAnimate
      lAnimate := .F.
      RETURN Nil
   ENDIF
   IF nLine == Nil
      nLine := GetCurrLine()
   ENDIF
   IF !Empty( oText := oTabMain:aControls[oTabMain:GetActivePage()] ) .AND. ;
         !Empty( oText:cargo )

      IF cPrg == Nil
         cPrg := oText:cargo
      ENDIF

      IF getBP( nLine, cPrg ) == 0
         Send( "brp", "add", cPrg, LTrim( Str(nLine ) ) )
      ELSE
         Send( "brp", "del", cPrg, LTrim( Str(nLine ) ) )
      ENDIF
      IF nMode != MODE_WAIT_ANS
         nAnsType := ANS_BRP
         cPrgBP := cPrg
         SetMode( MODE_WAIT_ANS )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION PrevExpr( nDirection )
   LOCAL i
   STATIC iPos := 0

   IF nDirection == 0

      iPos := 0
   ELSEIF iPos + nDirection <= Len( oBrwRes:aArray ) .AND. iPos + nDirection > 0

      iPos += nDirection
      i := Len( oBrwRes:aArray ) - iPos + 1
      oEditExpr:value := oBrwRes:aArray[ i,2]

      oBrwRes:nCurrent := i
      oBrwRes:rowPos := Min( 2, i )
      hwg_VScrollPos( oBrwRes, 0, .F. )
      hwg_Invalidaterect( oBrwRes:handle, 1 )
      oBrwRes:Refresh()

   ELSEIF nDirection < 0

      oEditExpr:value := ""
      iPos := 0
   ENDIF

   RETURN Nil

STATIC FUNCTION SetResult( cLine )

   oBrwRes:aArray[ Len(oBrwRes:aArray),1 ] := cLine
   oBrwRes:Bottom( .T. )
   hwg_Setfocus( oEditExpr:handle )

   RETURN Nil

STATIC FUNCTION KeyPress( nKey )
   LOCAL o

   IF nMode == MODE_INPUT .AND. !Empty( o := HWindow():GetMain():FindControl( ,hwg_Getfocus() ) ) .AND. o:id == EDIT_RES
      IF nKey == VK_RETURN
         Calc()
      ELSEIF nKey == VK_UP
         PrevExpr( 1 )
         hwg_Setfocus( oEditExpr:handle )
      ELSEIF nKey == VK_DOWN
         PrevExpr( - 1 )
         hwg_Setfocus( oEditExpr:handle )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION Calc( cExp )
   LOCAL arr, cmd

   IF Empty( cExp )
      cExp := Trim( oEditExpr:value )
   ENDIF
   IF !Empty( cExp )
      oEditExpr:value := ""
      IF Left( cExp, 1 ) == ":" .AND. SubStr( cExp, 2, 1 ) != ":"
         arr := hb_aTokens( SubStr( cExp,2 ), " " )
         cmd := Lower( arr[1] )
         IF "inspect" = cmd
            IF Len( arr ) > 1 .AND. !Empty( arr[2] )
               cInspectVar := arr[2]
               DoCommand( CMD_EXP, Str2Hex( "Valtype(" + arr[2] + ")" ) )
            ENDIF
         ELSEIF "record" = cmd
            InspectRec( iif( Len(arr ) > 1, arr[2], "" ) )
         ENDIF
      ELSE
         IF Len( oBrwRes:aArray ) < RES_LEN
            AAdd( oBrwRes:aArray, { "", cExp } )
            oBrwRes:nRecords ++
         ELSE
            ADel( oBrwRes:aArray, 1 )
            oBrwRes:aArray[RES_LEN] := { "", cExp }
         ENDIF
         PrevExpr( 0 )
         cInspectVar := Nil
         DoCommand( CMD_EXP, Str2Hex( cExp ) )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION StackToggle()
   LOCAL oBrw
   LOCAL bEnter := { |o|

   IF Lower( cPrgName ) != Lower( o:aArray[o:nCurrent,1] )
      SetPath( cPaths, o:aArray[o:nCurrent,1], .T. )
   ENDIF
   SetCurrLine( Val( o:aArray[o:nCurrent,3] ), o:aArray[o:nCurrent,1] )

   RETURN .T.

   }
   LOCAL bClose := { ||
   hwg_Checkmenuitem( , MENU_STACK, .F. )
   oStackDlg := Nil
   IF lDebugging
      DoCommand( CMD_STACK, "off" )
   ENDIF

   RETURN .T.

   }

   IF !Empty( oStackDlg )
      oStackDlg:Close()
   ELSE
      INIT DIALOG oStackDlg TITLE "Stack" AT 0, 0 SIZE 340, 120 ;
         FONT HWindow():GetMain():oFont ON EXIT bClose

      @ 0, 0 BROWSE oBrw ARRAY OF oStackDlg     ;
         SIZE 340, 120                       ;
         FONT HWindow():GetMain():oFont     ;
         STYLE WS_VSCROLL                   ;
         ON SIZE { |o, x, y|o:Move( 0, 0, x, y ) }

      oBrw:aArray := {}
      oBrw:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,1] },"C",16,0 ) )
      oBrw:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,2] },"C",16,0 ) )
      oBrw:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,3] },"C",8,0 ) )

      oBrw:bcolorSel := oBrw:htbcolor := CLR_LGREEN
      oBrw:tcolorSel := oBrw:httcolor := 0
      oBrw:bEnter := bEnter

      ACTIVATE DIALOG oStackDlg NOMODAL

      DoCommand( CMD_STACK, "on" )
      //hwg_Checkmenuitem( ,MENU_STACK, .T. )
   ENDIF

   RETURN Nil

STATIC FUNCTION ShowStack( arr, n )
   LOCAL oBrw, i, nLen := Val( arr[n] )

   IF !Empty(  oStackDlg )
      oBrw := oStackDlg:aControls[1]
      IF Empty( oBrw:aArray ) .OR. Len( oBrw:aArray ) != nLen
         oBrw:aArray := Array( nLen, 3 )
      ENDIF
      FOR i := 1 TO nLen
         oBrw:aArray[i,1] := arr[ ++n ]
         oBrw:aArray[i,2] := arr[ ++n ]
         oBrw:aArray[i,3] := arr[ ++n ]
      NEXT
      oBrw:Refresh()
   ENDIF

   RETURN Nil

STATIC FUNCTION VarsToggle()
   LOCAL oTab, oBrwL, oBrwR, oBrwU, oBrwS, y1
   LOCAL bClose := { ||

   hwg_Checkmenuitem( , MENU_VARS, .F. )
   oVarsDlg := Nil
   IF lDebugging
      DoCommand( CMD_LOCAL, "off" )
   ENDIF

   RETURN .T.

   }
   LOCAL bTbChange := { |o, n|
   (o)
   IF lDebugging
      IF n == 1
         DoCommand( CMD_LOCAL, "on" )
      ELSEIF n == 2
         DoCommand( CMD_PRIV, "on" )
      ELSEIF n == 3
         DoCommand( CMD_PUBL, "on" )
      ELSE
         DoCommand( CMD_STATIC, "on" )
      ENDIF
   ENDIF

   RETURN .T.

   }

   IF !Empty( oVarsDlg ) //hwg_Ischeckedmenuitem( ,MENU_VARS )
      oVarsDlg:Close()
   ELSE
      INIT DIALOG oVarsDlg TITLE "Local variables" AT 10, 10 SIZE 360, 180 ;
         FONT HWindow():GetMain():oFont ON EXIT bClose

      @ 0, 0 TAB oTab ITEMS {} SIZE 360, 180 ON SIZE { |o, x, y|o:Move( , , x, y ) }
      oTab:bChange2 := bTbChange
#ifdef __GTK__
      y1 := 4
#else
      y1 := 30
#endif

      BEGIN PAGE "Local" of oTab

      @ 8, y1 BROWSE oBrwL ARRAY OF oTab        ;
         SIZE 344, 142                       ;
         FONT HWindow():GetMain():oFont     ;
         STYLE WS_VSCROLL                   ;
         ON SIZE { |o, x, y|o:Move( , , x - 16, y - 38 ) }

      oBrwL:aArray := {}
      oBrwL:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,1] },"C",16,0 ) )
      oBrwL:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,2] },"C",2,0 ) )
      oBrwL:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,3] },"C",60,0 ) )

      oBrwL:bcolorSel := oBrwL:htbcolor := CLR_LGREEN
      oBrwL:tcolorSel := oBrwL:httcolor := 0
      oBrwL:bEnter := { ||ViewVar( oBrwL:aArray[oBrwL:nCurrent] ) }

      END PAGE of oTab

      BEGIN PAGE "Private" of oTab

      @ 8, y1 BROWSE oBrwR ARRAY OF oTab        ;
         SIZE 344, 142                       ;
         FONT HWindow():GetMain():oFont     ;
         STYLE WS_VSCROLL                   ;
         ON SIZE { |o, x, y|o:Move( , , x - 16, y - 38 ) }

      oBrwR:aArray := {}
      oBrwR:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,1] },"C",16,0 ) )
      oBrwR:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,2] },"C",2,0 ) )
      oBrwR:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,3] },"C",60,0 ) )

      oBrwR:bcolorSel := oBrwR:htbcolor := CLR_LGREEN
      oBrwR:tcolorSel := oBrwR:httcolor := 0
      oBrwR:bEnter := { ||ViewVar( oBrwR:aArray[oBrwR:nCurrent] ) }

      END PAGE of oTab

      BEGIN PAGE "Public" of oTab

      @ 8, y1 BROWSE oBrwU ARRAY OF oTab        ;
         SIZE 344, 142                       ;
         FONT HWindow():GetMain():oFont     ;
         STYLE WS_VSCROLL                   ;
         ON SIZE { |o, x, y|o:Move( , , x - 16, y - 38 ) }

      oBrwU:aArray := {}
      oBrwU:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,1] },"C",16,0 ) )
      oBrwU:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,2] },"C",2,0 ) )
      oBrwU:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,3] },"C",60,0 ) )

      oBrwU:bcolorSel := oBrwU:htbcolor := CLR_LGREEN
      oBrwU:tcolorSel := oBrwU:httcolor := 0
      oBrwU:bEnter := { ||ViewVar( oBrwU:aArray[oBrwU:nCurrent] ) }

      END PAGE of oTab

      BEGIN PAGE "Static" of oTab

      @ 8, y1 BROWSE oBrwS ARRAY OF oTab        ;
         SIZE 344, 142                       ;
         FONT HWindow():GetMain():oFont     ;
         STYLE WS_VSCROLL                   ;
         ON SIZE { |o, x, y|o:Move( , , x - 16, y - 38 ) }

      oBrwS:aArray := {}
      oBrwS:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,1] },"C",16,0 ) )
      oBrwS:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,2] },"C",2,0 ) )
      oBrwS:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,3] },"C",60,0 ) )

      oBrwS:bcolorSel := oBrwS:htbcolor := CLR_LGREEN
      oBrwS:tcolorSel := oBrwS:httcolor := 0
      oBrwS:bEnter := { ||ViewVar( oBrwS:aArray[oBrwS:nCurrent] ) }

      END PAGE of oTab

      ACTIVATE DIALOG oVarsDlg NOMODAL

      DoCommand( CMD_LOCAL, "on" )
      //hwg_Checkmenuitem( ,MENU_VARS, .T. )
   ENDIF

   RETURN Nil

STATIC FUNCTION ShowVars( arr, n, nVarType )
   LOCAL oBrw, i, nLen := Val( arr[n] )

   IF !Empty( oVarsDlg )
      oBrw := oVarsDlg:aControls[1]:aControls[nVarType]
      IF Empty( oBrw:aArray ) .OR. Len( oBrw:aArray ) != nLen
         oBrw:aArray := Array( nLen, 3 )
      ENDIF
      FOR i := 1 TO nLen
         oBrw:aArray[i,1] := Hex2Str( arr[ ++n ] )
         oBrw:aArray[i,2] := Hex2Str( arr[ ++n ] )
         oBrw:aArray[i,3] := Hex2Str( arr[ ++n ] )
      NEXT
      oBrw:aArray := ASort( oBrw:aArray, , , { |z, y|z[1] < y[1] } )
      oBrw:Refresh()
   ENDIF

   RETURN Nil

STATIC FUNCTION ViewVar( aLine, cObjName, nItem )
   LOCAL cName := aLine[1], cType := aLine[2]

   IF !Empty( nItem )
      cName := cObjName + "[" + LTrim( Str( nItem ) ) + "]"
      cType := aLine[1]
   ELSEIF !Empty( cObjName )
      cName := cObjName + ":" + aLine[1]
   ENDIF
   IF cType == "O"
      InspectObject( cName )
   ELSEIF cType == "A"
      InspectArray( cName )
   ENDIF

   RETURN Nil

STATIC FUNCTION WatchesToggle()
   LOCAL oBrw
   LOCAL bClose := { ||

   hwg_Checkmenuitem( , MENU_WATCH, .F. )
   oWatchDlg := Nil
   IF lDebugging
      DoCommand( CMD_WATCH, "off" )
   ENDIF

   RETURN .T.

   }

   IF !Empty( oWatchDlg )
      oWatchDlg:Close()
   ELSE
      INIT DIALOG oWatchDlg TITLE "Watch expressions" AT 20, 20 SIZE 340, 120 ;
         FONT HWindow():GetMain():oFont ON EXIT bClose

      MENU OF oWatchDlg
      MENUITEM "&Add" ACTION WatchAdd()
      MENUITEM "&Delete" ACTION WatchDel()
      ENDMENU

      @ 0, 0 BROWSE oBrw ARRAY OF oWatchDlg     ;
         SIZE 340, 120                       ;
         FONT HWindow():GetMain():oFont     ;
         STYLE WS_VSCROLL                   ;
         ON SIZE { |o, x, y|o:Move( 0, 0, x, y ) }

      oBrw:aArray := aWatches
      oBrw:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,1] },"C",16,0 ) )
      oBrw:AddColumn( HColumn():New( "",{ |v,o| (v), o:aArray[o:nCurrent,2] },"C",60,0 ) )

      oBrw:bcolorSel := oBrw:htbcolor := CLR_LGREEN
      oBrw:tcolorSel := oBrw:httcolor := 0

      ACTIVATE DIALOG oWatchDlg NOMODAL

      DoCommand( CMD_WATCH, "on" )
      //hwg_Checkmenuitem( ,MENU_WATCH, .T. )
   ENDIF

   RETURN Nil

STATIC FUNCTION ShowWatch( arr, n )
   LOCAL oBrw, i, nLen := Val( arr[n] )

   IF !Empty(  oWatchDlg )
      oBrw := oWatchDlg:aControls[1]
      FOR i := 1 TO nLen
         oBrw:aArray[i,2] := Hex2Str( arr[ ++n ] )
      NEXT
      oBrw:Refresh()
   ENDIF

   RETURN Nil

STATIC FUNCTION WatchAdd()
   LOCAL cExpr

   IF !Empty( cExpr := hu_Get( "Watch expression", "@S256", "" ) )
      AAdd( aWatches, { cExpr, "" } )
      DoCommand( CMD_WATCH, "add", Str2Hex( cExpr ) )
   ENDIF

   RETURN Nil

STATIC FUNCTION WatchDel()
   LOCAL n := oWatchDlg:aControls[1]:nCurrent

   IF n > 0 .AND. n <= Len( aWatches )
      IF Len( aWatches ) == 1
         oWatchDlg:aControls[1]:aArray := aWatches := {}
      ELSE
         ADel( aWatches, n )
         oWatchDlg:aControls[1]:aArray := ASize( aWatches, Len( aWatches ) - 1 )
      ENDIF
      DoCommand( CMD_WATCH, "del", LTrim( Str( n ) ) )
   ENDIF

   RETURN Nil

STATIC FUNCTION InspectAreas()
   LOCAL oBrw, oSayRdd
   LOCAL bChgPos := { |o|
      LOCAL arr, nOrd, cOrd

      IF Empty( o:aArray )
         oSayRdd:SetText( "No Workareas in use..." )
      ELSE
         //hwg_writelog(o:aArray[o:nCurrent,11] + " " + o:aArray[o:nCurrent,12])
         IF ( nOrd := Val( o:aArray[o:nCurrent,11] ) ) == 0
            cOrd := ""
         ELSE
            nOrd++
            arr := hb_ATokens( o:aArray[o:nCurrent,12], '/' )
            cOrd := iif( nOrd <= Len( arr ), arr[nOrd], "" )
            cOrd := StrTran( cOrd, '@', ', ' )
         ENDIF
         oSayRdd:SetText( o:aArray[o:nCurrent,1] + " rdd: " + o:aArray[o:nCurrent,3] + ;
            "  area N: " + o:aArray[o:nCurrent,2] + Chr( 13 ) + Chr( 10 ) + ;
            "Filter: " + o:aArray[o:nCurrent,10] + Chr( 13 ) + Chr( 10 ) +  ;
            "Order: " + cOrd )
      ENDIF

      RETURN .T.
   }

   IF !Empty( oAreasDlg )
      RETURN Nil
   ENDIF
   INIT DIALOG oAreasDlg TITLE "Watch expressions" AT 30, 30 SIZE 480, 400 ;
      FONT HWindow():GetMain():oFont ON EXIT { ||oAreasDlg := Nil, .T. }

   @ 0, 0 BROWSE oBrw ARRAY OF oAreasDlg     ;
      SIZE 480, 260                       ;
      FONT HWindow():GetMain():oFont     ;
      STYLE WS_VSCROLL                   ;
      ON POSCHANGE bChgPos               ;
      ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   oBrw:aArray := {}
   oBrw:AddColumn( HColumn():New( "",{ |v,o| (v), iif(Left(o:aArray[o:nCurrent,1],1 ) == "*","*","" ) },"C",1,0 ) )
   oBrw:AddColumn( HColumn():New( "Alias",{ |v,o| (v), iif(Left(o:aArray[o:nCurrent,1],1 ) == "*",SubStr(o:aArray[o:nCurrent,1],2 ),o:aArray[o:nCurrent,1] ) },"C",10,0 ) )
   oBrw:AddColumn( HColumn():New( "Records",{ |v,o| (v), o:aArray[o:nCurrent,4] },"C",10,0 ) )
   oBrw:AddColumn( HColumn():New( "Current",{ |v,o| (v), o:aArray[o:nCurrent,5] },"C",10,0 ) )
   oBrw:AddColumn( HColumn():New( "Bof",{ |v,o| (v), o:aArray[o:nCurrent,6] },"C",5,0 ) )
   oBrw:AddColumn( HColumn():New( "Eof",{ |v,o| (v), o:aArray[o:nCurrent,7] },"C",5,0 ) )
   oBrw:AddColumn( HColumn():New( "Fou",{ |v,o| (v), o:aArray[o:nCurrent,8] },"C",5,0 ) )
   oBrw:AddColumn( HColumn():New( "Del",{ |v,o| (v), o:aArray[o:nCurrent,9] },"C",5,0 ) )

   oBrw:bcolorSel := oBrw:htbcolor := CLR_LGREEN
   oBrw:tcolorSel := oBrw:httcolor := 0

   @ 10, 264 SAY oSayRdd CAPTION "" SIZE 460, 80 STYLE WS_BORDER BACKCOLOR CLR_LIGHT1 ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   @ 10, 360 BUTTON "Refresh" ON CLICK { || DoCommand( CMD_AREA ) } SIZE 100, 28 ON SIZE ANCHOR_BOTTOMABS
   @ 130, 360 BUTTON "Inspect" ON CLICK { || iif( !Empty( oBrw:aArray ), InspectRec( oBrw:aArray[oBrw:nCurrent,1] ), .T. ) } SIZE 100, 28 ON SIZE ANCHOR_BOTTOMABS
   @ 250, 360 BUTTON "Indexes" ON CLICK { || iif( !Empty( oBrw:aArray ), InspectInd( oBrw:aArray[oBrw:nCurrent,12] ), .T. ) } SIZE 100, 28 ON SIZE ANCHOR_BOTTOMABS
   @ 370, 360 BUTTON "Close" ON CLICK { || oAreasDlg:Close() } SIZE 100, 28 ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oAreasDlg NOMODAL

   DoCommand( CMD_AREA )

   RETURN Nil

STATIC FUNCTION ShowAreas( arr, n )
   LOCAL oBrw, arr1, i, j, nAreas := Val( arr[n] ), nAItems := Val( Hex2Str( arr[++n] ) )

   IF !Empty(  oAreasDlg )
      oBrw := oAreasDlg:aControls[1]
      arr1 := Array( nAreas, nAItems )
      FOR i := 1 TO nAreas
         FOR j := 1 TO nAItems
            arr1[i,j] := Hex2Str( arr[ ++n ] )
         NEXT
      NEXT
      oBrw:aArray := arr1
      Eval( oBrw:bPosChanged, oBrw )
      oBrw:Refresh()
   ENDIF

   RETURN Nil

STATIC FUNCTION InspectRec( cAlias )
   LOCAL oDlg, oBrw

   IF Left( cAlias, 1 ) == '*'
      cAlias := SubStr( cAlias, 2 )
   ENDIF

   INIT DIALOG oDlg TITLE cAlias AT 30, 30 SIZE 480, 400 ;
      FONT HWindow():GetMain():oFont

   @ 0, 0 BROWSE oBrw ARRAY OF oDlg          ;
      SIZE 480, 340                       ;
      FONT HWindow():GetMain():oFont     ;
      STYLE WS_VSCROLL                   ;
      ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   oBrw:aArray := {}
   oBrw:AddColumn( HColumn():New( "Name",{ |v,o| (v), o:aArray[o:nCurrent,1] },"C",14,0 ) )
   oBrw:AddColumn( HColumn():New( "Type",{ |v,o| (v), o:aArray[o:nCurrent,2] },"C",2,0 ) )
   oBrw:AddColumn( HColumn():New( "Len",{ |v,o| (v), o:aArray[o:nCurrent,3] },"C",6,0 ) )
   oBrw:AddColumn( HColumn():New( "Value",{ |v,o| (v), o:aArray[o:nCurrent,4] },"C",60,0 ) )

   oBrw:bcolorSel := oBrw:htbcolor := CLR_LGREEN
   oBrw:tcolorSel := oBrw:httcolor := 0

   @ 45, 360 BUTTON "Refresh" ON CLICK { || oInspectDlg := oDlg, DoCommand( CMD_REC, cAlias ) } SIZE 100, 28 ON SIZE ANCHOR_BOTTOMABS
   @ 335, 360 BUTTON "Close" ON CLICK { || oDlg:Close() } SIZE 100, 28 ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oDlg NOMODAL

   oInspectDlg := oDlg
   DoCommand( CMD_REC, cAlias )

   RETURN Nil

STATIC FUNCTION InspectInd( cInd )
   LOCAL oDlgInd, oBrw, arr, i

   IF Empty( cInd )
      RETURN Nil
   ENDIF
   arr := hb_ATokens( Substr(cInd,2), '/' )
   FOR i := 1 TO Len(arr)
      arr[i] := hb_ATokens( arr[i], '@' )
   NEXT

   INIT DIALOG oDlgInd TITLE "Indexes" AT 30, 30 SIZE 480, 300 ;
      FONT HWindow():GetMain():oFont

   @ 0, 0 BROWSE oBrw ARRAY OF oDlgInd   ;
      SIZE 480, 240                      ;
      FONT HWindow():GetMain():oFont     ;
      STYLE WS_VSCROLL                   ;
      ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   oBrw:aArray := arr
   oBrw:AddColumn( HColumn():New( "Num",{ |v,o| (v), o:nCurrent },"N",3,0 ) )
   oBrw:AddColumn( HColumn():New( "Name",{ |v,o| (v), o:aArray[o:nCurrent,1] },"C",10,0 ) )
   oBrw:AddColumn( HColumn():New( "Key",{ |v,o| (v), o:aArray[o:nCurrent,2] },"C",80,0 ) )

   oBrw:bcolorSel := oBrw:htbcolor := CLR_LGREEN
   oBrw:tcolorSel := oBrw:httcolor := 0

   @ 190, 260 BUTTON "Close" ON CLICK { || oDlgInd:Close() } SIZE 100, 28 ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oDlgInd

   RETURN Nil

STATIC FUNCTION ShowRec( arr, n )
   LOCAL oBrw, arr1, i, j, nFields := Val( arr[n] )

   IF !Empty( oInspectDlg )
      hwg_Setwindowtext( oInspectDlg:handle, "Record inspector (" + Hex2Str( arr[++n] ) + ", rec." + Hex2Str( arr[++n] ) + ")" )
      oBrw := oInspectDlg:aControls[1]
      arr1 := Array( nFields, 4 )
      FOR i := 1 TO nFields
         FOR j := 1 TO 4
            arr1[i,j] := Hex2Str( arr[ ++n ] )
         NEXT
      NEXT
      oBrw:aArray := arr1
      oBrw:Refresh()
      oInspectDlg := Nil
   ENDIF

   RETURN Nil

STATIC FUNCTION InspectObject( cObjName )
   LOCAL oDlg, oBrw

   INIT DIALOG oDlg TITLE "Object inspector (" + cObjName + ")" AT 30, 30 SIZE 480, 400 ;
      FONT HWindow():GetMain():oFont

   @ 0, 0 BROWSE oBrw ARRAY OF oDlg          ;
      SIZE 480, 340                       ;
      FONT HWindow():GetMain():oFont     ;
      STYLE WS_VSCROLL                   ;
      ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   oBrw:aArray := {}
   oBrw:AddColumn( HColumn():New( "Name",{ |v,o| (v), o:aArray[o:nCurrent,1] },"C",12,0 ) )
   oBrw:AddColumn( HColumn():New( "Type",{ |v,o| (v), o:aArray[o:nCurrent,2] },"C",2,0 ) )
   oBrw:AddColumn( HColumn():New( "Value",{ |v,o| (v), o:aArray[o:nCurrent,3] },"C",60,0 ) )

   oBrw:bcolorSel := oBrw:htbcolor := CLR_LGREEN
   oBrw:tcolorSel := oBrw:httcolor := 0
   oBrw:bEnter := { ||ViewVar( oBrw:aArray[oBrw:nCurrent], cObjName ) }

   @ 45, 360 BUTTON "Refresh" ON CLICK { || oInspectDlg := oDlg, DoCommand( CMD_OBJECT, cObjName ) } SIZE 100, 28 ON SIZE ANCHOR_BOTTOMABS
   @ 335, 360 BUTTON "Close" ON CLICK { || oDlg:Close() } SIZE 100, 28 ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oDlg NOMODAL

   oInspectDlg := oDlg
   DoCommand( CMD_OBJECT, cObjName )

   RETURN Nil

STATIC FUNCTION ShowObject( arr, n )
   LOCAL oBrw, arr1, i, j, nLen := Val( arr[n] )

   IF !Empty( oInspectDlg )
      oBrw := oInspectDlg:aControls[1]
      arr1 := Array( nLen, 3 )
      FOR i := 1 TO nLen
         FOR j := 1 TO 3
            arr1[i,j] := Hex2Str( arr[ ++n ] )
         NEXT
      NEXT
      oBrw:aArray := arr1
      oBrw:Refresh()
      oInspectDlg := Nil
   ENDIF

   RETURN Nil

STATIC FUNCTION InspectArray( cArrName )
   LOCAL oDlg, oBrw, i

   /* Bugfix Ticket #80:
       this old line causes crash press button "Refresh" in array inspector:
       n2 := n1 + oBrw:rowCount - 1
       oBrw:rowCount return 13, but must be 4 !
   */

   /* hwg_WriteLog("n1=" + ALLTRIM(STR(n1)) +  " n2=" + ALLTRIM(STR(n2)) + " oBrw:rowCount=" + ;
          ALLTRIM(STR(oBrw:rowCount)) )
   */

   LOCAL bRefresh := { ||
   LOCAL n1, n2, lRefr := .F.

   IF nMode == MODE_INPUT
      n1 := oBrw:nCurrent - oBrw:rowPos + 1
      n2 := n1 + Min( oBrw:rowCount, Len( oBrw:aArray ) ) - 1
      IF !oDlg:cargo[2]
         lRefr := .T.
      ELSE
         FOR i := n1 TO n2
            IF oBrw:aArray[i,1] == "-"
               lRefr := .T.
               EXIT
            ENDIF
         NEXT
      ENDIF
      IF lRefr
         oInspectDlg := oDlg
         DoCommand( CMD_ARRAY, cArrName, LTrim( Str(Max(1,n1 - 10 ) ) ), LTrim( Str(ARR_LEN ) ) )
      ENDIF
   ENDIF

   RETURN .T.

   }
   LOCAL bChgPos := { ||
   LOCAL n1, n2
   IF nMode == MODE_INPUT .AND. !Empty( oBrw:aArray )
      n1 := oBrw:nCurrent - oBrw:rowPos + 1
      n2 := n1 + Min( oBrw:rowCount, Len( oBrw:aArray ) ) - 1
      FOR i := n1 TO n2
         IF oBrw:aArray[i,1] == "-"
            oInspectDlg := oDlg
            DoCommand( CMD_ARRAY, cArrName, LTrim( Str(i ) ), LTrim( Str(ARR_LEN ) ) )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN .T.

   }

   INIT DIALOG oDlg TITLE "Array inspector - " + cArrName AT 30, 30 SIZE 480, 400 ;
      FONT HWindow():GetMain():oFont
   oDlg:cargo := { "f", .F. }

   @ 0, 0 BROWSE oBrw ARRAY OF oDlg          ;
      SIZE 480, 340                       ;
      FONT HWindow():GetMain():oFont     ;
      STYLE WS_VSCROLL                   ;
      ON POSCHANGE bChgPos               ;
      ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   oBrw:aArray := {}
   oBrw:AddColumn( HColumn():New( "Index",{ |v,o| (v), "[" + LTrim(Str(o:nCurrent ) ) + "]" },"C",12,0 ) )
   oBrw:AddColumn( HColumn():New( "Type",{ |v,o| (v), o:aArray[o:nCurrent,1] },"C",2,0 ) )
   oBrw:AddColumn( HColumn():New( "Value",{ |v,o| (v), o:aArray[o:nCurrent,2] },"C",60,0 ) )

   oBrw:bcolorSel := oBrw:htbcolor := CLR_LGREEN
   oBrw:tcolorSel := oBrw:httcolor := 0

   oBrw:bEnter := { ||ViewVar( oBrw:aArray[oBrw:nCurrent], cArrName, oBrw:nCurrent ) }

   @ 12, 366 SAY "" SIZE 16, 16 STYLE WS_BORDER BACKCOLOR 255 ON SIZE ANCHOR_BOTTOMABS
   @ 45, 360 BUTTON "Refresh" ON CLICK bRefresh SIZE 100, 28 ON SIZE ANCHOR_BOTTOMABS
   @ 335, 360 BUTTON "Close" ON CLICK { || oDlg:Close() } SIZE 100, 28 ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oDlg NOMODAL

   oInspectDlg := oDlg
   DoCommand( CMD_ARRAY, cArrName, "1", LTrim( Str(ARR_LEN ) ) )

   RETURN Nil

STATIC FUNCTION ShowArray( arr, n )
   LOCAL oBrw, i, j, nItems := Val( arr[n] ), nFirst := Val( Hex2Str( arr[++n] ) )
   LOCAL nLen := Val( Hex2Str( arr[++n] ) )

   IF !Empty( oInspectDlg )
      hwg_Setwindowtext( oInspectDlg:handle, oInspectDlg:title + "(" + LTrim( Str(nLen ) ) + ")" )
      oBrw := oInspectDlg:aControls[1]
      IF Len( oBrw:aArray ) != nLen .OR. !oInspectDlg:cargo[2]
         IF Len( oBrw:aArray ) != nLen
            oBrw:aArray := Array( nLen, 2 )
         ENDIF
         FOR i := 1 TO nLen
            oBrw:aArray[i,1] := "-"
            oBrw:aArray[i,2] := ""
         NEXT
      ENDIF
      nItems += nFirst - 1
      FOR i := nFirst TO nItems
         FOR j := 1 TO 2
            oBrw:aArray[i,j] := Hex2Str( arr[ ++n ] )
         NEXT
      NEXT
      oInspectDlg:cargo[2] := .T.
      oInspectDlg:aControls[2]:Setcolor( 0, CLR_GREEN, .T. )
      oBrw:Refresh()
      oInspectDlg := Nil
   ENDIF

   RETURN Nil

STATIC FUNCTION ViewCmdLine( lView )
   LOCAL oMain := HWindow():GetMain(), aControls := oMain:aControls
   LOCAL i := Ascan( aControls, { |o| hwg_isPtrEq( o:handle,oBrwRes:handle ) } ), j := 7

   lViewCmd := iif( lView != Nil, lView, !lViewCmd )
   hwg_Checkmenuitem( , MENU_CMDLINE, lViewCmd )
   DO WHILE -- j > 0
      IF lViewCmd
         aControls[i]:Show()
      ELSE
         aControls[i]:Hide()
      ENDIF
      i ++
   ENDDO
   IF lViewCmd
      oTabMain:bSize := { |o, x, y|o:Move( , , x, y - 108 ) }
      oMain:Move( , , , oMain:nHeight + 24 )
   ELSE
      oTabMain:bSize := { |o, x, y|o:Move( , , x, y ) }
      oMain:Move( , , , oMain:nHeight + 12 )
   ENDIF

   RETURN Nil

STATIC FUNCTION ViewSelVar()

#ifdef __HCEDIT__
   LOCAL oText := oTabMain:aControls[ oTabMain:GetActivePage() ]
   LOCAL nL := oText:aPointC[P_Y], nPos := oText:aPointC[P_X], cLine, c, nPos1, nPos2

   IF Empty( nL ) .OR. Empty( nPos1 := nPos2 := nPos ) .OR. SubStr( cLine := oText:aText[nL], nPos, 1 ) < '0'
      RETURN Nil
   ENDIF
   DO WHILE -- nPos1 > 0 .AND. ( IsDigit( c := SubStr( cLine,nPos1,1 ) ) .OR. ;
         IsAlpha( c ) .OR. c == '_' .OR. c == ':' )
   ENDDO
   nPos1 ++
   IF IsDigit( SubStr( cLine,nPos1,1 ) )
      RETURN Nil
   ENDIF
   DO WHILE ++ nPos2 <= Len( cLine ) .AND. ( IsDigit( c := SubStr( cLine,nPos2,1 ) ) .OR. ;
         IsAlpha( c ) .OR. c == '_' )
   ENDDO
   IF c == '('
      IF ( nPos := Find_Z( SubStr(cLine,nPos2 + 1 ), ')' ) ) == 0
         RETURN Nil
      ENDIF
      nPos2 += nPos + 1
   ENDIF
   cLine := SubStr( cLine, nPos1, nPos2 - nPos1 )
   IF '(' $ cLine
      oEditExpr:value := cLine
   ELSE
      Calc( ":ins " + cLine )
   ENDIF
#endif

   RETURN Nil

STATIC FUNCTION SetFont( oFont )

   IF !Empty( oFont ) .OR. !Empty( oFont := HFont():Select( HWindow():GetMain():oFont ) )
      oMainFont := oBrwRes:oFont := HWindow():GetMain():oFont := oFont
      SetTextFont( oFont )
      oBrwRes:lChanged := .T.
      oBrwRes:lChanged := .T.
      oBrwRes:Refresh()
   ENDIF

   RETURN Nil

STATIC FUNCTION About()
   LOCAL oDlg

   INIT DIALOG oDlg TITLE "About" AT 0, 0 SIZE 340, 170 ;
      FONT HWindow():GetMain():oFont ;
      STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + DS_CENTER

   @ 20, 30 SAY "HwGUI Debugger" SIZE 300, 24 STYLE SS_CENTER ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS
   @ 20, 60 SAY "Version 2.03" SIZE 300, 24 STYLE SS_CENTER ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS

#ifdef __PLATFORM__WINDOWS
   @ 20, 90 SAY "http://www.kresin.ru/debugger.html" ;
      LINK "http://www.kresin.ru/debugger.html" ;
      SIZE 300, 24 STYLE SS_CENTER  ;
      COLOR hwg_ColorC2N( "0000FF" ) ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS
#endif
   @ 120, 130 BUTTON "Ok" ID IDOK SIZE 100, 28 ON SIZE ANCHOR_BOTTOMABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   ACTIVATE DIALOG oDlg

   RETURN Nil

FUNCTION Font2Attr( oFont )
   LOCAL aAttr := {}

   AAdd( aAttr, { "name", oFont:name } )
   AAdd( aAttr, { "width", LTrim( Str(oFont:width,5 ) ) } )
   AAdd( aAttr, { "height", LTrim( Str(oFont:height,5 ) ) } )
   IF oFont:weight != 0
      AAdd( aAttr, { "weight", LTrim( Str(oFont:weight,5 ) ) } )
   ENDIF
   IF oFont:charset != 0
      AAdd( aAttr, { "charset", LTrim( Str(oFont:charset,5 ) ) } )
   ENDIF
   IF oFont:Italic != 0
      AAdd( aAttr, { "italic", LTrim( Str(oFont:Italic,5 ) ) } )
   ENDIF
   IF oFont:Underline != 0
      AAdd( aAttr, { "underline", LTrim( Str(oFont:Underline,5 ) ) } )
   ENDIF

   RETURN aAttr

STATIC FUNCTION hu_Get( cTitle, tpict, txget )
   LOCAL oDlg

   INIT DIALOG oDlg TITLE cTitle AT 0, 0 SIZE 300, 100 ;
      FONT HWindow():GetMain():oFont CLIPPER ;
      STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + DS_CENTER

   @ 20, 15 GET txget SIZE 260, 26 PICTURE tpict STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 20, 55 BUTTON "Ok" ID IDOK SIZE 100, 32 ON SIZE ANCHOR_BOTTOMABS
   @ 180, 55 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      RETURN iif( ValType( txget ) == "C", Trim( txget ), txget )
   ENDIF

   RETURN ""

STATIC FUNCTION Hex2Int( stroka )
   LOCAL i := Asc( stroka ), res

   IF i > 64 .AND. i < 71
      res := ( i - 55 ) * 16
   ELSEIF i > 47 .AND. i < 58
      res := ( i - 48 ) * 16
   ELSE
      RETURN 0
   ENDIF

   i := Asc( SubStr( stroka,2,1 ) )
   IF i > 64 .AND. i < 71
      res += i - 55
   ELSEIF i > 47 .AND. i < 58
      res += i - 48
   ENDIF

   RETURN res

STATIC FUNCTION Int2Hex( n )
   LOCAL n1 := Int( n/16 ), n2 := n % 16

   IF n > 255
      RETURN "XX"
   ENDIF

   RETURN Chr( iif( n1 < 10,n1 + 48,n1 + 55 ) ) + Chr( iif( n2 < 10,n2 + 48,n2 + 55 ) )

STATIC FUNCTION Str2Hex( stroka )
   LOCAL cRes := "", i, nLen := Len( stroka )

   FOR i := 1 TO nLen
      cRes += Int2Hex( Asc( SubStr(stroka,i,1 ) ) )
   NEXT

   RETURN cRes

STATIC FUNCTION Hex2Str( stroka )
   LOCAL cRes := "", i := 1, nLen := Len( stroka )

   DO WHILE i <= nLen
      cRes += Chr( Hex2Int( SubStr( stroka,i,2 ) ) )
      i += 2
   ENDDO

   RETURN cRes

STATIC FUNCTION StopDebug()

   IF !Empty( oVarsDlg )
      oVarsDlg:Close()
   ENDIF
   IF !Empty( oStackDlg )
      oStackDlg:Close()
   ENDIF
   IF !Empty( oWatchDlg )
      oWatchDlg:Close()
   ENDIF
   IF !Empty( oAreasDlg )
      oAreasDlg:Close()
   ENDIF

   IF handl1 != - 1
      FClose( handl1 )
      FClose( handl2 )
      handl1 := - 1
   ENDIF

   RETURN Nil

STATIC FUNCTION ExitDbg()

   IF nExitMode == 1
      IF handl1 != - 1
         Send( "cmd", "exit" )
      ENDIF
   ELSEIF nExitMode == 2
      Send( "cmd", "quit" )
   ENDIF
   lDebugging := .F.
   StopDebug()

   IF lModeIde
      DO( hb_hrbGetFunsym( hHrbProj, "proj_WrIni" ) )
   ENDIF

   RETURN .T.

* ===================== EOF of hwgdebug.prg ========================

