/*
 * $Id$
 *
 * HWGUI Tutorial
 *
 * Copyright 2013 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

 /*
  Ticket #82 (missing symbols):
  Additional instructions by DF7BE:
  For extensions of the tutor it is necessary to
  add all used symbols as an list for the EXTERNAL or REQUEST commands.

  1.) Standalone functions of HWGUI (for example HWG_SAVEFILE() )
      must be added in the header file hwgextern.ch
      If missing in the HWGUI libs, the symbol was displayed
      at making of tutor.prg
      Look for differences between WinAPI and GTK set by
      compiler switch "#ifdef __GTK__"
  2.) Class names of HWGUI must be listed in the EXTERNAL's listed above.

  The missing symbol was displayed in the error stack, if the
  Run button is pressed, for example HWG_MSGNOYES():

  Error BASE/6101  Unknown or unregistered symbol: HWG_MSGNOYES
  Called from HB_HRBRUN(0)
  Called from RUNSAMPLE(292)
  Called from (b)MAIN(82)
  Called from HOWNBUTTON:MUP(296)
  Called from HOWNBUTTON:ONEVENT(149)
  Called from HWG_ACTIVATEMAINWINDOW(0)
  Called from HMAINWINDOW:ACTIVATE(348)
  Called from MAIN(116)

 */

#include "hwgui.ch"
#include "hrbextern.ch"
#include "hwgextern.ch"

#define CLR_BLACK     0
#define CLR_WHITE     0xFFFFFF
#define CLR_LGREEN    0xAAC8AA
#define CLR_GREEN     32768
#define CLR_DBLUE     8388608
#define CLR_BLUE      16711680
#define	CLR_GRAY      4473924
#define	CLR_LGRAY1    0xBBBBBB
#define CLR_LGRAY2    0x999999

#define MENU_LOAD     1009
#define MENU_THEMES   1010

#define HILIGHT_KEYW    1
#define HILIGHT_FUNC    2
#define HILIGHT_QUOTE   3
#define HILIGHT_COMM    4

#ifndef __PLATFORM__WINDOWS
#define DIR_SEP         '/'
#else
#define DIR_SEP         '\'
#endif

STATIC oIni
STATIC cIniPath, cTutor
STATIC oFontText
STATIC oMainMenu, oEditMenu
STATIC oCurrNode
STATIC oText, oHighLighter
STATIC oBtnRun
STATIC cHwgrunPath
STATIC cHwg_include_dir := ".."+ DIR_SEP + ".." + DIR_SEP + "include"
STATIC cHwg_image_dir := ".." + DIR_SEP + ".." + DIR_SEP + "image"
STATIC cHrb_inc_dir := "", cHrb_bin_dir := ""
STATIC aThemes := {}, nCurrTheme := 1
STATIC nInitWidth := 900, nInitHeight := 600, nInitSplitX := 270

FUNCTION Main
   LOCAL oMain, oPanel, oBtnMenu, oFont := HFont():Add( "Georgia", 0, - 15 )
   LOCAL oTree, oSplit, i
   LOCAL oStyle1 := HStyle():New( {CLR_WHITE, CLR_LGRAY1}, 1 ), ;
         oStyle2 := HStyle():New( {CLR_LGRAY1}, 1,, 3 ), ;
         oStyle3 := HStyle():New( {CLR_LGRAY1}, 1,, 2, CLR_LGRAY2 )
   LOCAL bSize := {|o|
      LOCAL arr := hwg_GetWindowRect( o:handle )

      nInitWidth := arr[3] - arr[1]
      nInitHeight := arr[4] - arr[2]
      RETURN .T.
      }

   IF hwg__isUnicode()
      hb_cdpSelect( "UTF8" )
   ENDIF
   cIniPath := FilePath( hb_ArgV( 0 ) )
   cHwgrunPath := FindHwgrun()
   ReadIni()
   ReadHis()
   IF Empty( oFontText )
      oFontText := oFont
   ENDIF

   HBitmap():cPath := cHwg_image_dir
   hwg_SetResContainer()

   INIT WINDOW oMain MAIN TITLE "HwGUI Tutorial" ;
      AT 200, 0 SIZE nInitWidth, nInitHeight FONT oFont ON SIZE bSize ;
      ON EXIT {|| WriteHis(),.T. }

   CONTEXT MENU oMainMenu
      MENUITEM "&Load file" ID MENU_LOAD ACTION Load2Draft()
      MENUITEM "&Save" ACTION SaveDraft()
      SEPARATOR
      MENU TITLE "Themes"
      FOR i := 1 TO Len( aThemes )
         Hwg_DefineMenuItem( aThemes[i,6], MENU_THEMES + i, &( "{||ChangeTheme(" + LTrim(Str(i,2 ) ) + ")}" ),,,,,, .T. )
      NEXT
      ENDMENU
      MENUITEM "&Font" ACTION SetFont()
      SEPARATOR
      MENUITEM "&About" ACTION About()
      SEPARATOR
      MENUITEM "&Exit" ACTION oMain:Close()
   ENDMENU

   CONTEXT MENU oEditMenu
      MENUITEM "Run" ACTION RunSample()
      SEPARATOR
      MENUITEM "&Load file" ID MENU_LOAD ACTION Load2Draft()
      MENUITEM "Save" ACTION SaveDraft()
      SEPARATOR
      FOR i := 1 TO Len( aThemes )
         Hwg_DefineMenuItem( aThemes[i,6], MENU_THEMES + i, &( "{||ChangeTheme(" + LTrim(Str(i,2 ) ) + ")}" ),,,,,, .T. )
      NEXT
      SEPARATOR
      MENUITEM "&Font" ACTION SetFont()
   ENDMENU

   ADD TOP PANEL oPanel TO oMain HEIGHT 32 HSTYLE oStyle1

   @ 0, 0 OWNERBUTTON oBtnMenu OF oPanel ON CLICK {||ShowMainMenu()} ;
      SIZE 40, oPanel:nHeight FLAT ;
      BITMAP "menu" FROM RESOURCE TRANSPARENT COLOR CLR_WHITE TOOLTIP "Menu"
   oBtnMenu:aStyle := { oStyle1, oStyle2, oStyle3 }

   @ oMain:nWidth-150, 0 OWNERBUTTON OF oPanel ON CLICK {||ChangeFont(oText,2) } ;
      SIZE 40, oPanel:nHeight FLAT ;
      TEXT "+" TOOLTIP "Zoom in" ON SIZE ANCHOR_RIGHTABS
   ATail(oPanel:aControls):aStyle := { oStyle1, oStyle2, oStyle3 }
   @ oMain:nWidth-110, 0 OWNERBUTTON OF oPanel ON CLICK {||ChangeFont(oText,-2) } ;
      SIZE 40, oPanel:nHeight FLAT ;
      TEXT "-" TOOLTIP "Zoom out" ON SIZE ANCHOR_RIGHTABS
   ATail(oPanel:aControls):aStyle := { oStyle1, oStyle2, oStyle3 }

   @ oMain:nWidth-60, 0 OWNERBUTTON oBtnRun OF oPanel ON CLICK { ||RunSample() } ;
      SIZE 44, oPanel:nHeight FLAT ;
      TEXT "Run" TOOLTIP "Run sample" ON SIZE ANCHOR_RIGHTABS
   oBtnRun:aStyle := { oStyle1, oStyle2, oStyle3 }
   oBtnRun:Disable()

   @ 0, 32 TREE oTree SIZE nInitSplitX, oMain:nHeight-oPanel:nHeight ;
      EDITABLE ;
      BITMAP { "cl_fl", "op_fl" } FROM RESOURCE ;
      ON SIZE {|o,x,y| HB_SYMBOL_UNUSED(x), o:Move( ,,, y-32 ) }

   oTree:bDblClick := {|o,oItem| HB_SYMBOL_UNUSED(o),RunSample( oItem ) }

   oText := HCEdit():New( oMain, ,, nInitSplitX+4, oPanel:nHeight, ;
      nInitWidth-nInitSplitX-4, oMain:nHeight-oPanel:nHeight, oFontText,, ;
      { |o,x,y|o:Move( ,,x - oSplit:nLeft - oSplit:nWidth,y - 32 ) } )
   IF hwg__isUnicode()
      oText:lUtf8 := .T.
   ENDIF
   oText:bRClick := {||ShowEditMenu()}

   ChangeTheme( nCurrTheme )

   @ nInitSplitX, oPanel:nHeight SPLITTER oSplit SIZE 4, oMain:nHeight-oPanel:nHeight ;
      DIVIDE { oTree } FROM { oText } ;
      ON SIZE {|o,x,y| HB_SYMBOL_UNUSED(x),o:Move( ,,, y - oPanel:nHeight ) }
   oSplit:bEndDrag := {|o|nInitSplitX := o:nLeft}

   SET KEY FCONTROL, VK_ADD TO ChangeFont( oText, 2 )
   SET KEY FCONTROL, VK_SUBTRACT TO ChangeFont( oText, - 2 )

   BuildTree( oTree  )

   ACTIVATE WINDOW oMain

   RETURN Nil

STATIC FUNCTION ReadIni()
   LOCAL oInit, i, oNode1, oNode2, cHwgui_dir, arr, j, j1
   LOCAL aTypes := { "normal", "command", "function", "comment", "quote" }

   Aadd( aThemes, arr := Array(6) )
   arr[1] := { CLR_GRAY, CLR_WHITE, .F., .F. }
   arr[2] := { CLR_DBLUE, CLR_WHITE, .T., .F. }
   arr[3] := { CLR_DBLUE, CLR_WHITE, .T., .F. }
   arr[4] := { CLR_GREEN, CLR_WHITE, .F., .T. }
   arr[5] := { CLR_BLUE, CLR_WHITE, .F., .F. }
   arr[6] := "default"

   oIni := HXMLDoc():Read( cIniPath + "tutor.xml" )
   IF !Empty( oIni:aItems ) .AND. oIni:aItems[1]:title == "init"
      oInit := oIni:aItems[1]
      FOR i := 1 TO Len( oInit:aItems )
         oNode1 := oInit:aItems[i]
         IF oNode1:title == "tutorial"
            cTutor := oNode1:GetAttribute( "file" )
         ELSEIF oNode1:title == "hwgui_dir"
            IF !Empty( cHwgui_dir := oNode1:GetAttribute( "path",,"" ) )
               cHwg_include_dir := cHwgui_dir + DIR_SEP + "include"
               cHwg_image_dir := cHwgui_dir + DIR_SEP + "image"
            ENDIF
         ELSEIF oNode1:title == "harbour_bin"
            cHrb_bin_dir := oNode1:GetAttribute( "path", , "" )
         ELSEIF oNode1:title == "harbour_inc"
            cHrb_inc_dir := oNode1:GetAttribute( "path",,"" )
         ELSEIF oNode1:title == "hilight"
            oHighLighter := Hilight():New( oNode1 )
         ELSEIF oNode1:title == "theme"
            Aadd( aThemes, arr := Array(6) )
            arr[6] := oNode1:GetAttribute("name","C","xxx")
            FOR j := 1 TO Len( oNode1:aItems )
               oNode2 := oNode1:aItems[j]
               IF ( j1 := Ascan( aTypes, oNode2:title ) ) > 0
                  arr[j1] := { oNode2:GetAttribute("tcolor","N",CLR_BLACK), oNode2:GetAttribute("bcolor","N",CLR_WHITE), ;
                     oNode2:GetAttribute("bold"), oNode2:GetAttribute("italic") }
               ENDIF
            NEXT
         ENDIF
      NEXT
   ENDIF
#ifndef __PLATFORM__WINDOWS
   cHwg_image_dir := StrTran( cHwg_image_dir, '\', '/' )
   cHwg_include_dir := StrTran( cHwg_include_dir, '\', '/' )
   cHrb_inc_dir := StrTran( cHrb_inc_dir, '\', '/' )
   cHrb_bin_dir := StrTran( cHrb_bin_dir, '\', '/' )
#endif

   IF !File( cHwg_include_dir + DIR_SEP + "hwgui.ch" )
      hwg_MsgStop( "Set correct path to HwGUI in tutor.xml", "Hwgui.ch isn't found" )
   ENDIF

   IF !Empty( cHrb_inc_dir )
      cHrb_inc_dir := hb_OsPathListSeparator() + cHrb_inc_dir
   ENDIF

   RETURN Nil

STATIC FUNCTION ReadHis()

   LOCAL s := MemoRead( cIniPath + "tutor.his" ), arr, arr1, cSep, i, cName, x, y

   IF !Empty( s )
      cSep := Iif( Chr(13) $ s, Chr(13)+Chr(10), Chr(10) )
      arr := hb_aTokens( s, cSep )
      FOR i := 1 TO Len( arr )
         arr1 := hb_aTokens( arr[i], '=' )
         cName := Lower( AllTrim( arr1[1] ) )
         IF Len(arr1) > 1
            IF cName == "theme"
               nCurrTheme := Val( arr1[2] )
               IF nCurrTheme == 0 .OR. nCurrTheme > Len( aThemes )
                  nCurrTheme := 1
               ENDIF
            ELSEIF cName == "size"
               arr1 := hb_aTokens( arr1[2], ',' )
               IF Len( arr1 ) == 2 .AND. ( x := Val( arr1[1] ) ) > 0 .AND. ( y := Val( arr1[2] ) ) > 0
                  nInitWidth := x
                  nInitHeight := y
               ENDIF
            ELSEIF cName == "split"
               nInitSplitX := Val( arr1[2] )
            ELSEIF cName == "font"
               oFontText := HFont():LoadFromStr( arr1[2] )
            ENDIF
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

STATIC FUNCTION WriteHis()

   LOCAL s := "theme=" + Ltrim(Str( nCurrTheme,2 )) + Chr(13)+Chr(10) + ;
      "font=" + oText:oFont:SaveToStr() + Chr(13)+Chr(10) + ;
      "size=" + Ltrim(Str(nInitWidth)) + "," + Ltrim(Str(nInitHeight)) + Chr(13)+Chr(10) + ;
      "split=" + Ltrim(Str(Iif(nInitSplitX<10,200,nInitSplitX)))
   hb_MemoWrit( cIniPath + "tutor.his", s )

   RETURN Nil

STATIC FUNCTION BuildTree( oTree )
   LOCAL oTreeNode1, oTreeNode2, oTNode
   LOCAL oIniTut, oInit, i, j, j1, oNode1, oNode2, oNode3, cTemp
#ifndef __PLATFORM__WINDOWS
   LOCAL cVer := "gtk"
#else
   LOCAL cVer := "win"
#endif

   oIniTut := HXMLDoc():Read( cIniPath + cTutor )
   IF !Empty( oIniTut:aItems ) .AND. oIniTut:aItems[1]:title == "init"
      oInit := oIniTut:aItems[1]
      FOR i := 1 TO Len( oInit:aItems )
         oNode1 := oInit:aItems[i]
         IF oNode1:title == "chapter"
            INSERT NODE oTreeNode1 CAPTION oNode1:GetAttribute( "name", , "" ) TO oTree ON CLICK { |o|NodeOut( o ) }
            oTreeNode1:cargo := { .F. , "" }
            FOR j := 1 TO Len( oNode1:aItems )
               oNode2 := oNode1:aItems[j]
               IF oNode2:title == "chapter"
                  INSERT NODE oTreeNode2 CAPTION oNode2:GetAttribute( "name", , "" ) TO oTreeNode1 ON CLICK { |o|NodeOut( o ) }
                  oTreeNode2:cargo := { .F. , "" }
                  FOR j1 := 1 TO Len( oNode2:aItems )
                     oNode3 := oNode2:aItems[j1]
                     IF oNode3:title == "module"
                        IF Empty( cTemp := oNode3:GetAttribute( "ver",,"" ) ) .OR. cTemp == cVer
                           INSERT NODE oTNode CAPTION oNode3:GetAttribute( "name", , "" ) ;
                              TO oTreeNode2 BITMAP { "book" } ON CLICK { |o|NodeOut( o ) }
                           oTNode:cargo := { .T. , "" }
                           IF Empty( oTNode:cargo[2] := oNode3:GetAttribute( "file",,"" ) )
                              IF !Empty( oNode3:aItems ) .AND. ValType( oNode3:aItems[1] ) == "O"
                                 oTNode:cargo[2] := oNode3:aItems[1]:aItems[1]
                              ENDIF
                           ENDIF
                        ENDIF
                     ELSEIF oNode3:title == "comment"
                        IF !Empty( oNode3:aItems ) .AND. ValType( oNode3:aItems[1] ) == "O"
                           oTreeNode2:cargo[2] := oNode3:aItems[1]:aItems[1]
                        ENDIF
                     ENDIF
                  NEXT
               ELSEIF oNode2:title == "module"
                  IF Empty( cTemp := oNode2:GetAttribute( "ver",,"" ) ) .OR. cTemp == cVer
                     INSERT NODE oTNode CAPTION oNode2:GetAttribute( "name", , "" ) ;
                        TO oTreeNode1 BITMAP { "book" } ON CLICK { |o|NodeOut( o ) }
                     oTNode:cargo := { .T. , "" }
                     IF Empty( oTNode:cargo[2] := oNode2:GetAttribute( "file",,"" ) )
                        IF !Empty( oNode2:aItems ) .AND. ValType( oNode2:aItems[1] ) == "O"
                           oTNode:cargo[2] := oNode2:aItems[1]:aItems[1]
                        ENDIF
                     ENDIF
                  ENDIF
               ELSEIF oNode2:title == "comment"
                  IF !Empty( oNode2:aItems ) .AND. ValType( oNode2:aItems[1] ) == "O"
                     oTreeNode1:cargo[2] := oNode2:aItems[1]:aItems[1]
                  ENDIF
               ENDIF
            NEXT
         ELSEIF oNode1:title == "module"
            IF Empty( cTemp := oNode1:GetAttribute( "ver",,"" ) ) .OR. cTemp == cVer
               INSERT NODE oTNode CAPTION oNode1:GetAttribute( "name", , "" ) ;
                  TO oTree BITMAP { "book" } ON CLICK { |o|NodeOut( o ) }
               oTNode:cargo := { .T. , "" }
               IF Empty( oTNode:cargo[2] := oNode1:GetAttribute( "file",,"" ) )
                  IF !Empty( oNode1:aItems ) .AND. ValType( oNode1:aItems[1] ) == "O"
                     oTNode:cargo[2] := oNode1:aItems[1]:aItems[1]
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
      NEXT
      INSERT NODE oTreeNode1 CAPTION "Drafts" TO oTree ON CLICK { |o|NodeOut( o ) }
      oTreeNode1:cargo := { .F. , "" }
      INSERT NODE oTNode CAPTION "Draft1" TO oTreeNode1 BITMAP { "book" } ON CLICK { |o|NodeOut( o ) }
      oTNode:cargo := { .T. , "", "" }
      INSERT NODE oTNode CAPTION "Draft2" TO oTreeNode1 BITMAP { "book" } ON CLICK { |o|NodeOut( o ) }
      oTNode:cargo := { .T. , "", "" }
      INSERT NODE oTNode CAPTION "Draft3" TO oTreeNode1 BITMAP { "book" } ON CLICK { |o|NodeOut( o ) }
      oTNode:cargo := { .T. , "", "" }
   ENDIF
   IF !Empty( oTree:aItems )
      oTree:Select( oTree:aItems[1] )
   ENDIF

   oTree:bExpand := { || .T. }

   RETURN Nil

STATIC FUNCTION NodeOut( oItem )

   IF oItem:cargo[1]
      oText:HighLighter( oHighLighter )
      oBtnRun:Enable()
   ELSE
      oText:HighLighter()
      oBtnRun:Disable()
   ENDIF
   IF !Empty( oCurrNode ) .AND. Len( oCurrNode:cargo ) > 2
      oCurrNode:cargo[2] := oText:GetText()
   ENDIF
   IF hwg__isUnicode()
      oText:SetText( oItem:cargo[2], "UTF8", "UTF8" )
   ELSE
      oText:SetText( oItem:cargo[2] )
   ENDIF
   oCurrNode := oItem

   RETURN Nil

STATIC FUNCTION RunSample( oItem )
   LOCAL cText := "", cLine, i, ie, cHrb, lWnd := .F.
   LOCAL cFileErr := hb_DirTemp() + "hwg_compile_err.out", cTemp
#ifdef __XHARBOUR__
   LOCAL cHrbCopts := ""
#endif
#ifdef __GTK__
   cHrbCopts := cHrbCopts + "-d__GTK__"
#else
   #ifdef __XHARBOUR__
      cHrbCopts := ""
   #endif
#endif

   IF oItem != Nil .AND. !oItem:cargo[1]
      RETURN Nil
   ENDIF

   dirChange( hb_dirBase() )
   FOR i := 1 TO oText:nTextLen
      cLine := oText:aText[i]
      IF "INIT WINDOW" $ Upper( cLine )
         lWnd := .T.
      ENDIF
      cText += cLine + Chr( 13 ) + Chr( 10 )
   NEXT
   IF Empty( cText )
      RETURN Nil
   ENDIF

#ifdef __XHARBOUR__
   FErase( "__tmp.hrb" )
   oText:Save( "__tmp.prg" )
   IF hwg_RunConsoleApp( cHrb_bin_dir + "harbour " + "__tmp.prg -n -gh " + cHrbCopts + " -I" + cHwg_include_dir + cHrb_inc_dir ) .AND. File( "__tmp.hrb" )
      IF !Empty( cHwgrunPath )
         hwg_RunApp( cHwgrunPath + "hwgrun __tmp.hrb" )
      ELSE
         hwg_MsgStop( "HwgRun is absent, you need to compile it at first." )
      ENDIF
   ELSE
      hwg_MsgStop( "Compile error" )
   ENDIF
#else

   i := hwg_rediron( 1, hb_DirTemp() + "hwg_compile.out" )
   ie := hwg_rediron( 2, cFileErr )
#ifdef __GTK__
   cHrb := hb_compileFromBuf( cText, "harbour","-n", "-w", "-d__GTK__" , "-I" + cHwg_include_dir + cHrb_inc_dir )
#else
   cHrb := hb_compileFromBuf( cText, "harbour","-n", "-w", "-I" + cHwg_include_dir + cHrb_inc_dir )
#endif
   hwg_rediroff( 2, ie )
   hwg_rediroff( 1, i )

   cTemp := MemoRead( cFileErr )
   ie := .T.
   IF !Empty( cTemp ) .AND. ( ( " Warning " $ cTemp ) .OR. ( " Error " $ cTemp ) )
      ie := ShowErr( cTemp )
   ENDIF
   IF !Empty( cHrb ) .AND. ie
      IF lWnd
         IF !Empty( cHwgrunPath )
            hb_Memowrit( "__tmp.hrb", cHrb )
            hwg_RunApp( cHwgrunPath + "hwgrun __tmp.hrb" )
         ELSE
            hwg_MsgStop( "HwgRun is absent, you need to compile it at first." )
         ENDIF
      ELSE
         hb_hrbRun( cHrb )
      ENDIF
   ELSE
      hwg_MsgStop( "Compile error" )
   ENDIF
#endif

   RETURN Nil

STATIC FUNCTION FindHwgrun()
   LOCAL arr, i, cPath
#ifndef __PLATFORM__WINDOWS
   LOCAL cDefSep := "/"
   LOCAL cHwgRun := "hwgrun"
#else
   LOCAL cDefSep := "\"
   LOCAL cHwgRun := "hwgrun.exe"
#endif

   arr := hb_aTokens( "./" + hb_OsPathListSeparator() + GetEnv( "PATH" ), hb_OsPathListSeparator() )
   FOR i := 1 TO Len( arr )
      cPath := arr[i] + Iif( Empty( arr[i] ) .OR. Right( arr[i],1 ) $ "\/", ;
         "", cDefSep )
      IF File( cPath + cHwgRun )
         RETURN cPath
      ENDIF
   NEXT

   RETURN ""

STATIC FUNCTION ChangeFont( oCtrl, n )
   LOCAL oFont, nHeight := oCtrl:oFont:height

   nHeight := Iif( nHeight < 0, nHeight - n, nHeight + n )
   oFont := HFont():Add( oCtrl:oFont:name,, nHeight,, ;
      oCtrl:oFont:Charset,,,,, .T. )
   //hwg_Setctrlfont( oCtrl:oParent:handle, oCtrl:id, oFont:handle )

   oCtrl:SetFont( oFont )

   RETURN Nil

STATIC FUNCTION Load2Draft()

   LOCAL fname
   LOCAL oTNode := HWindow():GetMain():oTree:GetSelected()

   IF Len( oTNode:cargo ) > 2
      fname := hwg_Selectfile( { "( *.prg )" }, { "*.prg" }, Curdir() )

      oTNode:cargo[2] := MemoRead( fname )
      oTNode:cargo[3] := fname
      oTNode:SetText( hb_fnameNameExt(fname) )
      IF hwg__isUnicode()
         oText:SetText( oTNode:cargo[2], "UTF8", "UTF8" )
      ELSE
         oText:SetText( oTNode:cargo[2] )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION SaveDraft()

   LOCAL fname, cExt := ".prg", cMask := "*.prg", cTitle := "( *.prg )"
   LOCAL oTNode := HWindow():GetMain():oTree:GetSelected()

   DirChange( hb_DirBase() )
#ifdef __PLATFORM__WINDOWS
   fname := hwg_Savefile( cMask, cTitle, cMask, Curdir() )
#else
   fname := hwg_Selectfile( cTitle, cMask, Curdir() )
#endif

   IF !Empty( fname )
      IF !Empty( cExt )
         fname := hb_fnameExtSetDef( fname, cExt )
      ENDIF
      IF !File( fname ) .OR. hwg_MsgYesNo( "File exists. Overwrite it?" )
         oText:Save( fname )
      ENDIF
   ENDIF

   IF Len( oTNode:cargo ) > 2
      oTNode:SetText( hb_fnameNameExt(fname) )
   ENDIF

   RETURN Nil

STATIC FUNCTION ShowMainMenu()

   hwg_Enablemenuitem( oMainMenu, MENU_LOAD, Len(oCurrNode:cargo)>2, .T. )
   oMainMenu:Show( HWindow():GetMain(), 32, 32, .T. )

   RETURN Nil

STATIC FUNCTION ShowEditMenu()

   hwg_Enablemenuitem( oEditMenu, MENU_LOAD, Len(oCurrNode:cargo)>2, .T. )
   oEditMenu:Show( HWindow():GetMain() )

   RETURN Nil

FUNCTION ChangeTheme( n )

   LOCAL arr := aThemes[n]

   hwg_CheckMenuItem( oMainMenu, MENU_THEMES+nCurrTheme, .F. )
   hwg_CheckMenuItem( oEditMenu, MENU_THEMES+nCurrTheme, .F. )
   hwg_CheckMenuItem( oMainMenu, MENU_THEMES+n, .T. )
   hwg_CheckMenuItem( oEditMenu, MENU_THEMES+n, .T. )

   IF !Empty( arr[1] )
      oText:tColor := arr[1,1]
      oText:bColor := arr[1,2]
   ENDIF
   oText:bColorCur := oText:bColor

   IF !Empty( arr[2] )
      oText:SetHili( HILIGHT_KEYW, Iif( !Empty(arr[2,3]).OR.!Empty(arr[2,4]), ;
         oText:oFont:SetFontStyle( !Empty(arr[2,3]),,!Empty(arr[2,4]) ), -1 ), arr[2,1], arr[2,2] )
   ENDIF
   IF !Empty( arr[3] )
      oText:SetHili( HILIGHT_FUNC, Iif( !Empty(arr[3,3]).OR.!Empty(arr[3,4]), ;
         oText:oFont:SetFontStyle( !Empty(arr[3,3]),,!Empty(arr[3,4]) ), -1 ), arr[3,1], arr[3,2] )
   ENDIF
   IF !Empty( arr[4] )
      oText:SetHili( HILIGHT_COMM, Iif( !Empty(arr[4,3]).OR.!Empty(arr[4,4]), ;
         oText:oFont:SetFontStyle( !Empty(arr[4,3]),,!Empty(arr[4,4]) ), -1 ), arr[4,1], arr[4,2] )
   ENDIF
   IF !Empty( arr[5] )
      oText:SetHili( HILIGHT_QUOTE, Iif( !Empty(arr[5,3]).OR.!Empty(arr[5,4]), ;
         oText:oFont:SetFontStyle( !Empty(arr[5,3]),,!Empty(arr[5,4]) ), -1 ), arr[5,1], arr[5,2] )
   ENDIF
   oText:Refresh()

   nCurrTheme := n

   RETURN Nil


STATIC FUNCTION ShowErr( cMess )

   LOCAL oDlg, oEdit, lErr := ( " Error " $ cMess ), lRes := .F.

   INIT DIALOG oDlg TITLE "Error.log" At 92, 61 SIZE 500, 500 FONT HWindow():Getmain():oFont

   @ 4, 4 HCEDIT oEdit SIZE 492, 440 ON SIZE {|o,x,y|o:Move( ,, x-8, y-60 ) }
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF
   oEdit:SetText( cMess )

   IF lErr
      @ 200, 460 BUTTON "Close" ON CLICK { || hwg_EndDialog() } SIZE 100, 32 ;
         ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS
   ELSE
      @ 50, 460 BUTTON "Run anyway" ON CLICK { || lRes := .T., hwg_EndDialog() } SIZE 100, 32 ;
         ON SIZE ANCHOR_BOTTOMABS
      @ 350, 460 BUTTON "Cancel" ON CLICK { || hwg_EndDialog() } SIZE 100, 32 ;
         ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS
   ENDIF

   ACTIVATE DIALOG oDlg CENTER

   RETURN lRes

STATIC FUNCTION SetFont()

   LOCAL oFont := HFont():Select( oText:oFont )

   IF !Empty( oFont )
      oText:SetFont( oFont )
      oFontText := oFont
   ENDIF

   RETURN Nil

STATIC FUNCTION About

   hwg_MsgInfo( "HwGUI Tutor" + Chr(13)+Chr(10) + "Interactive Tutorial" + Chr(13)+Chr(10) + "Version 1.2" + Chr(13)+Chr(10) + "(C) Alexander S.Kresin" ;
      + Chr(13)+Chr(10) + Chr(13)+Chr(10) + hwg_Version() )

   RETURN Nil

* ================================= EOF of tutor.prg ===============================


