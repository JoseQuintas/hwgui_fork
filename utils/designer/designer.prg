/*
 * $Id$
 *
 * Designer
 * Main file
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"
#include "hxml.ch"
#include "designer.ch"
#include "hwgextern.ch"

   // #include "extmodul.ch"

#define  MAX_RECENT_FILES  5

#ifdef __GTK__
//   #include "gtk.ch"
   #define CURS_CROSS GDK_CROSS
   #define CURS_SIZEV GDK_SIZING
   #define CURS_SIZEH GDK_HAND1
#else
   #define CURS_CROSS IDC_CROSS
   #define CURS_SIZEV IDC_SIZEWE
   #define CURS_SIZEH IDC_SIZENS
#endif

#ifdef __PLATFORM__WINDOWS
   #define DIR_SEP  '\'
#else
   #define DIR_SEP  '/'
#endif

REQUEST DBCREATE, DBUSEAREA, DBCREATEINDEX, DBSEEK, HB_ATOKENS, HB_FNAMENAME, HB_FNAMEDIR
REQUEST HB_OSNEWLINE

MEMVAR oDesigner, crossCursor, vertCursor, horzCursor, cCurDir

STATIC lOmmitMenuFile := .F.

#ifdef INTEGRATED
FUNCTION Designer( p0, p1, p2 )
#else
FUNCTION Main( p0, p1, p2 )
#endif
   LOCAL oPanel, oTab, oFont, cResForm, i
   PUBLIC oDesigner
   PUBLIC crossCursor, vertCursor, horzCursor

#ifdef __XHARBOUR__
   REQUEST HB_CODEPAGE_RUWIN
   hb_cdpSelect( "RUWIN" )
#else
   REQUEST HB_CODEPAGE_UTF8
   REQUEST HB_CODEPAGE_RU1251
   IF hwg__isUnicode()
      hb_cdpSelect( "UTF8" )
   ELSE
      hb_cdpSelect( "RU1251" )
   ENDIF
#endif

   oDesigner := HDesigner():New()

   IF p0 != Nil .AND. ( p0 == "-r" .OR. p0 == "/r" )
      oDesigner:lReport := .T.
      IF p1 != Nil
         IF Left( p1, 1 ) $ "-/"
            p0 := p1
            p1 := p2
         ELSE
            p0 := "-f"
         ENDIF
      ENDIF
   ENDIF

#ifdef INTEGRATED
   // #ifdef MODAL
   IF p0 == "-s" .OR. p0 == "/s"
      oDesigner:lSingleForm := .T.
   ENDIF
   // #endif
#endif

   IF !__mvExist( "cCurDir" )
      __mvPublic( "cCurDir" )
   ENDIF
   IF ValType( cCurDir ) != "C"
      cCurDir := DIR_SEP + CurDir() + DIR_SEP
   ENDIF
   oDesigner:ds_mypath := cCurDir

   IF !ReadIniFiles()
      RETURN Nil
   ENDIF

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT - 13
   IF ValType( crossCursor ) != "N"
      crossCursor := hwg_Loadcursor( CURS_CROSS )
      horzCursor  := hwg_Loadcursor( CURS_SIZEV )
      vertCursor  := hwg_Loadcursor( CURS_SIZEH )
   ENDIF

#ifdef INTEGRATED
   INIT DIALOG oDesigner:oMainWnd AT 0, 0 SIZE 400, 200 TITLE iif( !oDesigner:lReport, "Form", "Report" ) + " designer" ;
      FONT oFont                          ;
      ON INIT { |o|StartDes( o, p0, p1 ) }   ;
      ON EXIT { ||EndIde() }
#else
   INIT WINDOW oDesigner:oMainWnd MAIN AT 0, 0 SIZE 400, 200 TITLE iif( !oDesigner:lReport, "Form", "Report" ) + " designer" ;
      FONT oFont                                                  ;
      ON EXIT { ||EndIde() }
#endif

   MENU OF oDesigner:oMainWnd
      MENU TITLE "&File"
      IF !oDesigner:lSingleForm
         MENUITEM "&New " + iif( !oDesigner:lReport, "Form", "Report" )  ACTION HFormGen():New()
         MENUITEM "&Open " + iif( !oDesigner:lReport, "Form", "Report" ) ACTION HFormGen():Open()
         SEPARATOR
         MENUITEM "&Save " + iif( !oDesigner:lReport, "Form", "Report" )   ACTION iif( HFormGen():oDlgSelected != Nil, HFormGen():oDlgSelected:oParent:Save(), hwg_Msgstop( "No Form in use!", "Designer" ) )
         MENUITEM "&Save as ..." ACTION iif( HFormGen():oDlgSelected != Nil, HFormGen():oDlgSelected:oParent:Save( .T. ), hwg_Msgstop( "No Form in use!" ) )
         MENUITEM "&Close " + iif( !oDesigner:lReport, "Form", "Report" )  ACTION iif( HFormGen():oDlgSelected != Nil, HFormGen():oDlgSelected:oParent:End(), hwg_Msgstop( "No Form in use!", "Designer" ) )
      ELSE
         IF !lOmmitMenuFile
            MENUITEM "&Open " + iif( !oDesigner:lReport, "Form", "Report" ) ACTION HFormGen():OpenR()
            SEPARATOR
            MENUITEM "&Save as ..." ACTION ( oDesigner:lSingleForm := .F. , HFormGen():oDlgSelected:oParent:Save( .T. ), oDesigner:lSingleForm := .T. )
         ENDIF
      ENDIF
      IF !lOmmitMenuFile
         SEPARATOR
         i := 1
         DO WHILE i <= MAX_RECENT_FILES .AND. oDesigner:aRecent[i] != Nil
            Hwg_DefineMenuItem( CutPath( oDesigner:aRecent[i] ), 1020 + i, ;
               &( "{||HFormGen():Open('" + oDesigner:aRecent[i] + "')}" ) )
            i ++
         ENDDO
         SEPARATOR
      ENDIF
         MENUITEM IF( !lOmmitMenuFile, "&Exit", "&Close Designer" ) ACTION oDesigner:oMainWnd:Close()
      ENDMENU
      MENU TITLE "&Edit"
         MENUITEM "&Copy control" ACTION ( oDesigner:oClipBrd := GetCtrlSelected( HFormGen():oDlgSelected ), iif( oDesigner:oClipBrd != Nil,hwg_Enablemenuitem(,MENU_PASTE1, .T. , .T. ), .F. ) )
         MENUITEM "&Paste" ID MENU_PASTE1 ACTION oDesigner:addItem := oDesigner:oClipbrd
      ENDMENU
      MENU TITLE "&View"
         MENUITEMCHECK "&Object Inspector" ID MENU_OINSP ACTION iif( oDesigner:oDlgInsp == Nil, InspOpen(), oDesigner:oDlgInsp:Close() )
         SEPARATOR
         IF !oDesigner:lReport
            MENUITEMCHECK "Grid &4px" ID MENU_GRID4 ACTION SetGrid( 4 )
            MENUITEMCHECK "Grid &8px" ID MENU_GRID8 ACTION SetGrid( 8 )
            SEPARATOR
         ENDIF
         MENUITEM "&Preview"  ID MENU_PREVIEW ACTION DoPreview()
      ENDMENU
      MENU TITLE "&Control"
         MENUITEM "&Delete"  ACTION DeleteCtrl()
      ENDMENU
      MENU TITLE "&Options"
         MENUITEMCHECK "&AutoAdjust" ID MENU_AADJ ACTION hwg_Checkmenuitem( oDesigner:oMainWnd:handle, MENU_AADJ, !hwg_Ischeckedmenuitem( oDesigner:oMainWnd:handle,MENU_AADJ ) )
         MENUITEMCHECK "&BmpSelFile" ID MENU_BMPSEL ACTION hwg_Checkmenuitem( oDesigner:oMainWnd:handle, MENU_BMPSEL, HBitmap():lSelFile := !hwg_Ischeckedmenuitem( oDesigner:oMainWnd:handle,MENU_BMPSEL ) )
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION hwg_Msginfo( hwg_Version() + Chr(10)+Chr(13) + "Visual Designer", "About" )
      ENDMENU
   ENDMENU

   //@ 0, 0 PANEL oPanel SIZE 400, 200 ON SIZE { |o, x, y|hwg_Movewindow( o:handle, 0, 0, x, y ) }
   @ 0, 0 PANEL oPanel SIZE 0, 30

   IF !oDesigner:lSingleForm
      @ 2, 3 OWNERBUTTON OF oPanel       ;
         ON CLICK { ||HFormGen():New() } ;
         SIZE 24, 24 FLAT               ;
         BITMAP oDesigner:cBmpPath+"bmp_new.bmp" COORDINATES 0, 4, 0, 0 TRANSPARENT ;
         TOOLTIP "New Form"
      @ 27, 3 OWNERBUTTON OF oPanel       ;
         ON CLICK { ||HFormGen():Open() } ;
         SIZE 24, 24 FLAT                ;
         BITMAP oDesigner:cBmpPath+"bmp_open.bmp" COORDINATES 0, 4, 0, 0 TRANSPARENT ;
         TOOLTIP "Open Form"

      @ 55, 6 LINE LENGTH 18 VERTICAL

      @ 70, 3 OWNERBUTTON OF oPanel       ;
         ON CLICK { ||iif( HFormGen():oDlgSelected != Nil, HFormGen():oDlgSelected:oParent:Save(), hwg_Msgstop( "No Form in use!" ) ) } ;
         SIZE 24, 24 FLAT                ;
         BITMAP oDesigner:cBmpPath+"bmp_save.bmp" COORDINATES 0, 4, 0, 0 TRANSPARENT ;
         TOOLTIP "Save Form"
   ENDIF

   //@ 3, 30 TAB oTab ITEMS {} OF oPanel SIZE 400, 210 FONT oFont ;
   //   ON SIZE { |o, x, y|ArrangeBtn( o, x, y ) }

   @ 3, 30 TAB oTab ITEMS {} SIZE 400, 170 FONT oFont ;
      ON SIZE { |o, x, y|ArrangeBtn( o, x, y ) }

   BuildSet( oTab )

   CONTEXT MENU oDesigner:oCtrlMenu
      MENUITEM "Copy"   ACTION ( oDesigner:oClipBrd := GetCtrlSelected( HFormGen():oDlgSelected ), iif( oDesigner:oClipBrd != Nil,hwg_Enablemenuitem(,MENU_PASTE1, .T. , .T. ), .F. ) )
      MENUITEM "Paste"  ID MENU_PASTE2 ACTION oDesigner:addItem := oDesigner:oClipbrd
      SEPARATOR
      MENU TITLE "Adjust to..."
         MENUITEM "left"  ACTION AdjustCtrl( GetCtrlSelected( HFormGen():oDlgSelected ), .T. , .F. , .F. , .F. )
         MENUITEM "top"   ACTION AdjustCtrl( GetCtrlSelected( HFormGen():oDlgSelected ), .F. , .T. , .F. , .F. )
         MENUITEM "right" ACTION AdjustCtrl( GetCtrlSelected( HFormGen():oDlgSelected ), .F. , .F. , .T. , .F. )
         MENUITEM "bottom" ACTION AdjustCtrl( GetCtrlSelected( HFormGen():oDlgSelected ), .F. , .F. , .F. , .T. )
      ENDMENU
      MENU TITLE "Align..."
         MENUITEM "vertically"  ACTION AlignCtrl( GetCtrlSelected( HFormGen():oDlgSelected ), 1 )
         MENUITEM "horizontally"  ACTION AlignCtrl( GetCtrlSelected( HFormGen():oDlgSelected ), 2 )
      ENDMENU
      MENU TITLE "Set as pattern for..."
         MENUITEM "vertical alignment"  ACTION SetAsPattern( GetCtrlSelected( HFormGen():oDlgSelected ), 1 )
         MENUITEM "horizontal alignment"  ACTION SetAsPattern( GetCtrlSelected( HFormGen():oDlgSelected ), 2 )
      ENDMENU
      SEPARATOR
      IF oDesigner:lReport
         MENUITEMCHECK "Fit into Box" ID MENU_FIT ACTION FitLine( GetCtrlSelected( HFormGen():oDlgSelected ) )
         SEPARATOR
      ENDIF
      MENUITEM "Delete" ACTION DeleteCtrl()
   ENDMENU

   CONTEXT MENU oDesigner:oTabMenu
      MENUITEM "New Page" ACTION Page_New( GetCtrlSelected( HFormGen():oDlgSelected ) )
      MENUITEM "Next Page" ACTION Page_Next( GetCtrlSelected( HFormGen():oDlgSelected ) )
      MENUITEM "Previous Page" ACTION Page_Prev( GetCtrlSelected( HFormGen():oDlgSelected ) )
      SEPARATOR
      MENUITEM "Copy"   ACTION ( oDesigner:oClipBrd := GetCtrlSelected( HFormGen():oDlgSelected ), iif( oDesigner:oClipBrd != Nil,hwg_Enablemenuitem(,MENU_PASTE1, .T. , .T. ), .F. ) )
      MENU TITLE "Adjust to..."
         MENUITEM "left"  ACTION AdjustCtrl( GetCtrlSelected( HFormGen():oDlgSelected ), .T. , .F. , .F. , .F. )
         MENUITEM "top"   ACTION AdjustCtrl( GetCtrlSelected( HFormGen():oDlgSelected ), .F. , .T. , .F. , .F. )
         MENUITEM "right" ACTION AdjustCtrl( GetCtrlSelected( HFormGen():oDlgSelected ), .F. , .F. , .T. , .F. )
         MENUITEM "bottom" ACTION AdjustCtrl( GetCtrlSelected( HFormGen():oDlgSelected ), .F. , .F. , .F. , .T. )
      ENDMENU
      SEPARATOR
      MENUITEM "Delete" ACTION DeleteCtrl()
   ENDMENU

   CONTEXT MENU oDesigner:oDlgMenu
      MENUITEM "Paste" ID MENU_PASTE2 ACTION oDesigner:addItem := oDesigner:oClipbrd
      MENUITEM "Preview" ACTION DoPreview()
   ENDMENU

#ifndef __GTK__
   HWG_InitCommonControlsEx()
#endif

   hwg_Enablemenuitem( ,MENU_OINSP, .F. , .T. )
   hwg_Enablemenuitem( ,MENU_PREVIEW, .F. , .T. )
   IF oDesigner:nGrid > 0
      hwg_Checkmenuitem( , Iif( oDesigner:nGrid==4, MENU_GRID4, MENU_GRID8 ), .T. )
   ENDIF

#ifdef INTEGRATED
#ifdef MODAL
   ACTIVATE DIALOG oDesigner:oMainWnd
   cResForm := oDesigner:cResForm
   oDesigner := Nil
#else
   ACTIVATE DIALOG oDesigner:oMainWnd NOMODAL
#endif
#else
   StartDes( oDesigner:oMainWnd, p0, p1 )
   ACTIVATE WINDOW oDesigner:oMainWnd
#endif

   RETURN cResForm

   // -----------------

CLASS HDesigner

   DATA oMainWnd, oDlgInsp
   DATA oCtrlMenu, oTabMenu, oDlgMenu
   DATA oClipbrd
   DATA lReport      INIT .F.
   DATA ds_mypath, cBmpPath
   DATA lChgOpt      INIT .F.
   DATA aRecent      INIT Array( MAX_RECENT_FILES )
   DATA lChgRecent   INIT .F.
   DATA oWidgetsSet, oFormDesc
   DATA oBtnPressed, addItem
   DATA aFormats     INIT { { "Hwgui XML format","xml" } }
   DATA aDataDef     INIT {}
   DATA aMethDef     INIT {}
   DATA lSingleForm  INIT .F.
   DATA cResForm
   DATA nrepzoom     INIT 1
   DATA nGrid        INIT 0

   METHOD NEW   INLINE Self

ENDCLASS

   // -----------------

STATIC FUNCTION StartDes( oDlg, p1, cForm )

   hwg_Movewindow( oDlg:handle, 0, 0, 400, 210 )

   IF p1 != Nil .AND. Left( p1, 1 ) $ "-/"
      IF ( p1 := SubStr( p1,2,1 ) ) == "n"
         HFormGen():New()
      ELSEIF p1 == "f"
         IF cForm == Nil
            HFormGen():New()
         ELSE
            HFormGen():Open( cForm )
         ENDIF
#ifdef INTEGRATED
         // #ifdef MODAL
      ELSEIF p1 == "s"
         IF cForm == Nil
            HFormGen():New()
         ELSE
            HFormGen():Open( , cForm )
         ENDIF
         Hwg_SetForegroundWindow( HFormGen():aForms[1]:oDlg:handle )
         hwg_Setfocus( HFormGen():aForms[1]:oDlg:handle )
         // #endif
#endif
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION ReadIniFiles()
   LOCAL oIni := HXMLDoc():Read( "designer.iml" )
   LOCAL i, oNode, cWidgetsFileName, cwitem, cfitem, critem, l_ds_mypath, j
   LOCAL cBmpPath := oDesigner:ds_mypath + "resource" + DIR_SEP + "bmp" + DIR_SEP

   IF oDesigner:lReport
      cwItem := "rep_widgetset"
      cfitem := "rep_format"
      critem := "rep_recent"
   ELSE
      cwItem := "widgetset"
      cfitem := "format"
      critem := "recent"
   ENDIF
   IF Empty( oIni:aItems )
      CreateIni( oIni )
   ENDIF
   FOR i := 1 TO Len( oIni:aItems[1]:aItems )
      oNode := oIni:aItems[1]:aItems[i]
      IF oNode:title == cwitem
         IF !Empty( oNode:aItems )
            cWidgetsFileName := oNode:aItems[1]
         ENDIF
      ELSEIF oNode:title == cfitem
         AAdd( oDesigner:aFormats, { oNode:GetAttribute( "name" ), oNode:GetAttribute( "ext" ), ;
            oNode:GetAttribute( "file" ), oNode:GetAttribute( "rdscr" ), ;
            oNode:GetAttribute( "wrscr" ), oNode:GetAttribute( "cnvtable" ) } )
      ELSEIF oNode:title == "editor"
         LoadEdOptions( oNode:aItems[1] )
      ELSEIF oNode:title == "dirpath"
         l_ds_mypath := oNode:GetAttribute( "default" )
         IF !Empty( l_ds_mypath )
            oDesigner:ds_mypath := Lower( l_ds_mypath )
         ENDIF
      ELSEIF oNode:title == "grid"
         oDesigner:nGrid := oNode:GetAttribute( "value", "N", 0 )
      ELSEIF oNode:title == "bmppath"
         cBmpPath := oNode:GetAttribute( "default" )
      ELSEIF oNode:title == critem .AND. !oDesigner:lSingleForm
         FOR j := 1 TO Min( Len( oNode:aItems ), MAX_RECENT_FILES )
            oDesigner:aRecent[j] := Lower( Trim( oNode:aItems[j]:aItems[1] ) )
         NEXT
      ELSEIF oNode:title == "rep_zoom"
         oDesigner:nRepZoom := Val( oNode:GetAttribute( "default" ) )
      ENDIF
   NEXT

   oDesigner:cBmpPath := cBmpPath

   IF ValType( cWidgetsFileName ) == "C"
      oDesigner:oWidgetsSet := HXMLDoc():Read( cCurDir + cWidgetsFileName )
   ENDIF
   IF oDesigner:oWidgetsSet == Nil .OR. Empty( oDesigner:oWidgetsSet:aItems )
      hwg_Msgstop( "Widgets file isn't found!", "Designer error" )
      RETURN .F.
   ENDIF

   RETURN .T.

STATIC FUNCTION BuildSet( oTab )
   LOCAL i, j, j1, aSet, oWidget, oProperty, b1, b2, b3, cDlg, arr, b4
   LOCAL x1, cText, cBmp, oButton

   IF !Empty( oDesigner:oWidgetsSet:aItems )
      aSet := oDesigner:oWidgetsSet:aItems[1]:aItems
      FOR i := 1 TO Len( aSet )
         IF aSet[i]:title == "set"
            oTab:StartPage( aSet[i]:GetAttribute( "name" ) )
            x1 := 4
            FOR j := 1 TO Len( aSet[i]:aItems )
               IF aSet[i]:aItems[j]:title == "widget"
                  oWidget := aSet[i]:aItems[j]
                  cText := oWidget:GetAttribute( "text" )
                  cBmp := oWidget:GetAttribute( "bmp" )
                  IF cText != Nil .OR. cBmp != Nil
                     oButton := HOwnButton():New( ,,, x1, 28, 30, 26, ;
                        ,,, { |o, id|ClickBtn( o, id ) }, .T., ;
                        cText,,,,,,, ;
                        oDesigner:cBmpPath+Lower(cBmp)+".bmp", .F.,,,,, .F.,, ;
                        oWidget:GetAttribute( "name" ) )
                     oButton:cargo := oWidget
                     x1 += 30
                  ENDIF
               ENDIF
            NEXT
            oTab:EndPage()
         ELSEIF aSet[i]:title == "form"
            oDesigner:oFormDesc := aSet[i]
         ELSEIF aSet[i]:title == "data"
            FOR j := 1 TO Len( aSet[i]:aItems )
               IF aSet[i]:aItems[j]:title == "property"
                  oProperty := aSet[i]:aItems[j]
                  b1 := b2 := b3 := b4 := Nil
                  FOR j1 := 1 TO Len( oProperty:aItems )
                     IF oProperty:aItems[j1]:title == "code1"
                        b1 := oProperty:aItems[j1]:aItems[1]:aItems[1]
                     ELSEIF oProperty:aItems[j1]:title == "code2"
                        b2 := oProperty:aItems[j1]:aItems[1]:aItems[1]
                     ELSEIF oProperty:aItems[j1]:title == "code3"
                        b3 := oProperty:aItems[j1]:aItems[1]:aItems[1]
                     ELSEIF oProperty:aItems[j1]:title == "code_def"
                        b4 := oProperty:aItems[j1]:aItems[1]:aItems[1]
                     ENDIF
                  NEXT

                  cDlg := oProperty:GetAttribute( "array" )
                  IF cDlg != Nil
                     arr := {}
                     DO WHILE ( j1 := At( ",",cDlg ) ) > 0
                        AAdd( arr, Left( cDlg,j1 - 1 ) )
                        cDlg := LTrim( SubStr( cDlg,j1 + 1 ) )
                     ENDDO
                     AAdd( arr, cDlg )
                  ELSE
                     arr := Nil
                  ENDIF
                  cDlg := oProperty:GetAttribute( "dlg" )
                  IF cDlg != Nil
                     cDlg := Lower( cDlg )
                  ENDIF
                  AAdd( oDesigner:aDataDef, { Lower( oProperty:GetAttribute("name" ) ), ;
                     b1, b2, b3, cDlg, arr, b4 } )
               ENDIF
            NEXT
         ELSEIF aSet[i]:title == "methods"
            FOR j := 1 TO Len( aSet[i]:aItems )
               IF aSet[i]:aItems[j]:title == "method"
                  AAdd( oDesigner:aMethDef, { Lower( aSet[i]:aItems[j]:GetAttribute("name" ) ), ;
                     aSet[i]:aItems[j]:GetAttribute( "params" ) } )
               ENDIF
            NEXT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

STATIC FUNCTION ArrangeBtn( oTab, x, y )
   LOCAL i, x1, y1, oBtn

   //oTab:Move( , , x - 6, y - 33 )
   oTab:Move( , , x - 6, y - 30 )
   FOR i := 1 TO Len( oTab:aControls )
      oBtn := oTab:aControls[i]
      IF oBtn:Classname == "HOWNBUTTON"
         IF oBtn:nLeft == 4 .AND. oBtn:nTop == 28
            x1 := 4
            y1 := 28
         ELSE
            IF oBtn:nLeft != x1 .OR. oBtn:nTop != y1
               oBtn:Move( x1, y1 )
            ENDIF
         ENDIF
         x1 += 30
         IF x1 + oBtn:nWidth > x
            x1 := 4
            y1 += 26
         ENDIF
      ENDIF
   NEXT

   RETURN Nil

STATIC FUNCTION ClickBtn( oBtn, cItem, cText, nWidth, nHeight )

   IF !Empty( HFormGen():aForms )
      oDesigner:addItem := oBtn:cargo
      IF oDesigner:oBtnPressed != Nil
         oDesigner:oBtnPressed:Release()
      ENDIF
      oBtn:Press()
      oDesigner:oBtnPressed := oBtn
   ENDIF

   RETURN Nil

FUNCTION DeleteCtrl()
   LOCAL oDlg := HFormGen():oDlgSelected, oCtrl, i

   IF oDlg != Nil .AND. ( oCtrl := GetCtrlSelected( oDlg ) ) != Nil
      IF oCtrl:oContainer != Nil
         i := Ascan( oCtrl:oContainer:aControls, { |o|o:handle == oCtrl:handle } )
         IF i != 0
            ADel( oCtrl:oContainer:aControls, i )
            ASize( oCtrl:oContainer:aControls, Len( oCtrl:oContainer:aControls ) - 1 )
         ENDIF
      ENDIF
      IF oDesigner:lReport
         oDlg:aControls[1]:aControls[1]:DelControl( oCtrl )
      ELSE
         oDlg:DelControl( oCtrl )
      ENDIF
      SetCtrlSelected( oDlg )
      oDlg:oParent:lChanged := .T.
   ENDIF

   RETURN Nil

FUNCTION FindWidget( cClass )
   LOCAL i, aSet := oDesigner:oWidgetsSet:aItems[1]:aItems, oNode

   FOR i := 1 TO Len( aSet )
      IF aSet[i]:title == "set"
         IF ( oNode := aSet[i]:Find( "widget",1,{ |o|o:GetAttribute("class" ) == cClass } ) ) != Nil
            RETURN oNode
         ENDIF
      ENDIF
   NEXT

   RETURN Nil

FUNCTION Evalcode( xCode )
   LOCAL nLines

   IF ValType( xCode ) == "C"
      nLines := MLCount( xCode )
      IF nLines > 1
         xCode := RdScript( , xCode )
      ELSE
         xCode := &( "{||" + xCode + "}" )
      ENDIF
   ENDIF
   IF ValType( xCode ) == "A"
      RETURN DoScript( xCode )
   ELSE
      RETURN Eval( xCode )
   ENDIF

   RETURN Nil

STATIC FUNCTION CreateIni( oIni )
   LOCAL oNode := oIni:Add( HXMLNode():New( "designer" ) )

   oNode:Add( HXMLNode():New( "widgetset",,,"widgets.xml" ) )

   oIni:Save( "designer.iml" )

   RETURN Nil

FUNCTION AddRecent( oForm )
   LOCAL i, cItem := Lower( Trim( oForm:path + oForm:filename ) )

   IF oDesigner:aRecent[1] == Nil .OR. !( oDesigner:aRecent[1] == cItem )
      FOR i := 1 TO MAX_RECENT_FILES
         IF oDesigner:aRecent[i] == Nil
            EXIT
         ELSEIF oDesigner:aRecent[i] == cItem
            ADel( oDesigner:aRecent, i )
         ENDIF
      NEXT
      AIns( oDesigner:aRecent, 1 )
      oDesigner:aRecent[1] := cItem
      oDesigner:lChgRecent := .T.
   ENDIF

   RETURN Nil

STATIC FUNCTION EndIde
   LOCAL i, j, alen := Len( HFormGen():aForms ), lRes := .T. , oIni, critem, oNode
   LOCAL nGrid := 0

   IF alen > 0
      IF hwg_Msgyesno( "Are you really want to quit ?", "Designer" )
         FOR i := Len( HFormGen():aForms ) TO 1 STEP - 1
            HFormGen():aForms[i]:End( , .F. )
         NEXT
      ELSE
         lRes := .F.
      ENDIF
   ENDIF
   IF !oDesigner:lSingleForm .AND. ( oDesigner:lChgRecent .OR. oDesigner:lChgOpt )
      critem := iif( oDesigner:lReport, "rep_recent", "recent" )
      oIni := HXMLDoc():Read( cCurDir + "Designer.iml" )

      i := 1
      oNode := HXMLNode():New( "dirpath", HBXML_TYPE_SINGLE, { { "default",oDesigner:ds_myPath } } )
      IF oIni:aItems[1]:Find( "dirpath", @i ) == Nil
         oIni:aItems[1]:Add( oNode )
      ELSE
         oIni:aItems[1]:aItems[i] := oNode
      ENDIF

      IF ( oNode := oIni:aItems[1]:Find( "grid" ) ) != Nil
         nGrid := oNode:GetAttribute( "value", "N", 0 )
      ENDIF
      IF nGrid != oDesigner:nGrid
         IF oNode == Nil
            oNode := HXMLNode():New( "grid", HBXML_TYPE_SINGLE, { { "value",Ltrim(Str(oDesigner:nGrid)) } } )
            oIni:aItems[1]:Add( oNode )
         ELSE
            oNode:SetAttribute( "value", Ltrim(Str(oDesigner:nGrid)) )
         ENDIF
      ENDIF

      IF oDesigner:lChgRecent
         i := 1
         IF oIni:aItems[1]:Find( critem, @i ) == Nil
            oIni:aItems[1]:Add( HXMLNode():New( critem,, ) )
            i := Len( oIni:aItems[1]:aItems )
         ENDIF
         j := 1
         oIni:aItems[1]:aItems[i]:aItems := {}
         DO WHILE j <= MAX_RECENT_FILES .AND. oDesigner:aRecent[j] != Nil
            oIni:aItems[1]:aItems[i]:Add( HXMLNode():New( "file",,,oDesigner:aRecent[j] ) )
            j ++
         ENDDO
      ENDIF
      oIni:Save( cCurDir + "Designer.iml" )
   ENDIF
   IF lRes
      oDesigner:oCtrlMenu:End()
      oDesigner:oTabMenu:End()
      IF HDTheme():lChanged
         SaveEdOptions()
      ENDIF
#ifndef MODAL
      oDesigner := Nil
#endif
   ENDIF

   RETURN lRes

FUNCTION SetOmmitMenuFile( lom )

   lOmmitMenuFile := lOm

   RETURN lOm

STATIC FUNCTION SetGrid( nGrid )

   LOCAL i, j, aControls, lNeedAlign := .F.

   IF oDesigner:nGrid == nGrid
      hwg_Checkmenuitem( , Iif( nGrid==4, MENU_GRID4, MENU_GRID8 ), .F. )
      oDesigner:nGrid := 0
   ELSE
      IF oDesigner:nGrid > 0
         hwg_Checkmenuitem( , Iif( nGrid==4, MENU_GRID8, MENU_GRID4 ), .F. )
      ENDIF
      hwg_Checkmenuitem( , Iif( nGrid==4, MENU_GRID4, MENU_GRID8 ), .T. )
      oDesigner:nGrid := nGrid

      FOR i := 1 TO Len( HFormGen():aForms )
         aControls := HFormGen():aForms[i]:oDlg:aControls
         FOR j := 1 TO Len(aControls)
            IF aControls[j]:nLeft % nGrid != 0 .OR. aControls[j]:nTop % nGrid != 0
                  //aControls[j]:nWidth % nGrid != 0 .OR. aControls[j]:nHeight % nGrid != 0
               lNeedAlign := .T.
               EXIT
            ENDIF
         NEXT
         IF lNeedAlign
            EXIT
         ENDIF
      NEXT
      IF lNeedAlign
         IF hwg_MsgYesNo( "Align controls to grid?", "Alignment" )
            FOR i := 1 TO Len( HFormGen():aForms )
               AlignToGrid( HFormGen():aForms[i]:oDlg )
            NEXT
         ENDIF
      ENDIF
   ENDIF

   FOR i := 1 TO Len( HFormGen():aForms )
      hwg_Invalidaterect( HFormGen():aForms[i]:oDlg:handle, 1 )
   NEXT
   oDesigner:lChgOpt := .T.

   RETURN Nil

STATIC FUNCTION AlignToGrid( oDlg )

   LOCAL j, aControls := oDlg:aControls, oCtrl

   FOR j := 1 TO Len(aControls)
      oCtrl := aControls[j]
      IF oCtrl:nLeft % oDesigner:nGrid != 0 .OR. oCtrl:nTop % oDesigner:nGrid != 0
         CtrlMove( oCtrl, - (oCtrl:nLeft % oDesigner:nGrid), ;
            -(oCtrl:nTop % oDesigner:nGrid), .F., .T. )
      ENDIF
      /*
      IF oCtrl:nWidth % oDesigner:nGrid != 0
         SetBDown( oCtrl, oCtrl:nLeft+oCtrl:nWidth-1, oCtrl:nTop+oCtrl:nHeight-1, 3 )
         CtrlResize( oCtrl, oCtrl:nLeft+oCtrl:nWidth-1 - (oCtrl:nWidth % oDesigner:nGrid), ;
            oCtrl:nTop+oCtrl:nHeight-1 )
      ENDIF
      IF oCtrl:nHeight % oDesigner:nGrid != 0
         SetBDown( oCtrl, oCtrl:nLeft+oCtrl:nWidth-1, oCtrl:nTop+oCtrl:nHeight-1, 4 )
         CtrlResize( oCtrl, oCtrl:nLeft+oCtrl:nWidth-1, ;
            oCtrl:nTop+oCtrl:nHeight-1  - (oCtrl:nHeight % oDesigner:nGrid) )
      ENDIF
      */
      SetBDown( Nil, 0, 0, 0 )
   NEXT

   RETURN Nil
