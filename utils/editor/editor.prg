/*
 * $Id$
 *
 * Simple editor
 *
 * Copyright 2014 Alexander Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

/* Modifications by DF7BE:
  - Selection of charset at start of program:
    0   : ISO8859-15 (western countries with Euro currency sign)
    204 : Russian

   On LINUX always use of UTF-8 , so the selection menu is suppressed
*/

#include "hwgui.ch"
#include "hxml.ch"
#include "hcedit.ch"

#define APP_VERSION  "0.9"

#define MAX_RECENT_FILES    6

#ifdef __GTK__
// #include "gtk.ch"
#define CURS_HAND GDK_HAND1
#else
#define CURS_HAND IDC_HAND
#endif

#if defined (__HARBOUR__) // ( __HARBOUR__ - 0 >= 0x030000 )
REQUEST HB_CODEPAGE_UTF8
#endif

REQUEST HB_CODEPAGE_RU1251
REQUEST HB_CODEPAGE_RU866
#if ( HB_VER_REVID - 0 ) >= 2002101634
REQUEST HB_CODEPAGE_DE858  && With Euro currency sign
#endif
REQUEST HB_CODEPAGE_DEWIN  && ----  "   -------------

#define MENU_RULER       1901
#define MENU_IMAGE       1902
#define MENU_TABLE       1903
#define MENU_SPAN        1904
#define MENU_FINDNEXT    1905
#define MENU_PNOWR       1911
#define MENU_PNOINS      1912
#define MENU_PNOCR       1913
#define MENU_SALLOW      1914
#define MENU_SNOWR       1915
#define MENU_SNOINS      1916
#define MENU_SNOCR       1917
#define MENU_COPYF       1918
#define MENU_PASTEF      1919
#define MENU_INS_TABLE   1920
#define MENU_INS_BLOCK   1921
#define MENU_BLOCK       1922
#define MENU_VSCROLL  1923

#define FREE_BOUNDL      12
#define DOC_BOUNDL       12

#define P_X             1
#define P_Y             2

#define SETC_LEFT       3
#define SETC_XY         4
#define SETC_XFIRST     5
#define SETC_XYPOS      8

#define OB_TYPE         1
#define OB_OB           2
#define OB_ASTRU        2
#define OB_CLS          3
#define OB_ID           4
#define OB_ACCESS       5
#define OB_ATEXT        4
#define OB_TWIDTH       4
#define OB_TRNUM        4
#define OB_TALIGN       5
#define OB_OPT          5
#define OB_TBL          6
#define OB_HREF         6
#define OB_IALIGN       7
#define OB_EXEC         7

#define OB_CWIDTH       1
#define OB_CLEFT        2
#define OB_CRIGHT       3

#define OB_COLSPAN      5
#define OB_ROWSPAN      6
#define OB_AWRAP        7
#define OB_ALIN         8
#define OB_NLINES       9
#define OB_NLINEF      10
#define OB_NTLEN       11
#define OB_NWCF        12
#define OB_NWSF        13
#define OB_NLINEC      14
#define OB_NPOSC       15
#define OB_NLALL       16
#define OB_APC         17
#define OB_APM1        18
#define OB_APM2        19

#define BIT_ALLOW       1
#define BIT_RDONLY      2
#define BIT_NOINS       3
#define BIT_NOCR        4
#define BIT_CLCSCR      5

#define TROPT_SEL       1

#define  CLR_BLACK          0
#define  CLR_GRAY1    5592405  // #555555
#define  CLR_GRAY2   11184810  // #AAAAAA

#define  CLR_VDBLUE  10485760
#define  CLR_LBLUE   16759929  // #79BCFF
#define  CLR_LBLUE0  12164479  // #7F9DB9
#define  CLR_LBLUE1  16773866  // #EAF2FF
#define  CLR_LBLUE2  16770002  // #D2E3FF
#define  CLR_LBLUE3  16772062  // #DEEBFF
#define  CLR_LIGHT1  15132390

STATIC cNewLine := e"\r\n"
STATIC cWebBrow
STATIC oFontMain, oFontP, oBrush1
STATIC oToolbar, oRuler, oEdit, aButtons[4]
STATIC oComboSiz, cComboSizDef := "100%", lComboSet := .F.
STATIC aSetStyle, nLastMsg, nLastWpar, aPointLast[2], nCharsLast
STATIC alAcc := { .F.,.F.,.F.,.F.,.F.,.F.,.F. }
STATIC cCBformatted
STATIC cSearch := "", aPointFound, lSeaCase := .T., lSeaRegex := .F.
STATIC lScrollBar := .T.
STATIC aFilesRecent := {}, lOptChg := .F.
STATIC cpDef := "DEWIN", cpSource := "DEWIN"

MEMVAR handcursor, cIniPath

FUNCTION Main ( fName )
   LOCAL oMainWindow, i
   LOCAL oStyle1, oStyle2, oStyle3, oStylePane
   LOCAL aComboSiz := { "50%", "60%", "80%", "90%", cComboSizDef, "110%", "120%", "130%", "140%", "150%", "160%", "180%", "200%", "240%", "280%" }
   LOCAL x1
   LOCAL obtn
   LOCAL result, csel , nchrs
   LOCAL aCharset := { "ISO8859@Euro (0)" , "Russian (204)" }

   PRIVATE handcursor, cIniPath := FilePath( hb_ArgV( 0 ) )

   csel := ""
   nchrs := 0

   ReadIni( cIniPath )

   SetCpDef()

   IF Empty( oFontMain )
#ifndef __PLATFORM__WINDOWS
      PREPARE FONT oFontMain NAME "Sans" WIDTH 0 HEIGHT 13
#else
      PREPARE FONT oFontMain NAME "Courier New" WIDTH 0 HEIGHT - 18
#endif
      lOptChg := .T.
   ENDIF
#ifndef __PLATFORM__WINDOWS
      PREPARE FONT oFontP NAME "Sans" WIDTH 0 HEIGHT 12
#else
      PREPARE FONT oFontP NAME "Courier New" WIDTH 0 HEIGHT - 15
#endif

   oBrush1 := HBrush():Add( 16777215 )

   oStyle1 := HStyle():New( {CLR_LBLUE,CLR_LBLUE3}, 1 )
   oStyle2 := HStyle():New( {CLR_LBLUE}, 1,, 3, CLR_BLACK )
   oStyle3 := HStyle():New( {CLR_LBLUE1}, 1,, 2, CLR_LBLUE0 )
   oStylePane := HStyle():New( { CLR_GRAY1, CLR_GRAY2 }, 1 )

   INIT WINDOW oMainWindow MAIN TITLE "Editor" ;
      AT 200, 0 SIZE 600, 300 FONT oFontMain

   ADD TOP PANEL oToolBar TO oMainWindow HEIGHT 30 HSTYLE oStylePane
   @ 0,2 COMBOBOX oComboSiz ITEMS aComboSiz OF oToolBar INIT Ascan( aComboSiz,cComboSizDef ) ;
         SIZE 80, 26 DISPLAYCOUNT 6 ON CHANGE {||onBtnSize()} TOOLTIP "Font size in %"
   x1 := 82

   oToolBar:brush := 0

   @ x1   ,0 OWNERBUTTON aButtons[1] OF oToolBar ON CLICK {|| onBtnStyle(1) } ;
       SIZE 30,30 TEXT "B" FONT oMainWindow:oFont:SetFontStyle( .T. ) CHECK
   aButtons[1]:aStyle := { oStyle1,oStyle2,oStyle3 }
   aButtons[1]:cargo := "fb"
   @ x1+30,0 OWNERBUTTON aButtons[2] OF oToolBar ON CLICK {|| onBtnStyle(2) } ;
       SIZE 30,30 TEXT "I" FONT oMainWindow:oFont:SetFontStyle( .F.,,.T. ) CHECK
   aButtons[2]:aStyle := { oStyle1,oStyle2,oStyle3 }
   aButtons[2]:cargo := "fi"
   @ x1+60,0 OWNERBUTTON aButtons[3] OF oToolBar ON CLICK {|| onBtnStyle(3) } ;
       SIZE 30,30 TEXT "U" FONT oMainWindow:oFont:SetFontStyle( .F.,,.F.,.T. ) CHECK
   aButtons[3]:aStyle := { oStyle1,oStyle2,oStyle3 }
   aButtons[3]:cargo := "fu"
   @ x1+90,0 OWNERBUTTON aButtons[4] OF oToolBar ON CLICK {|| onBtnStyle(4) } ;
       SIZE 30,30 TEXT "S" FONT oMainWindow:oFont:SetFontStyle( .F.,,.F.,.F.,.T. ) CHECK
   aButtons[4]:aStyle := { oStyle1,oStyle2,oStyle3 }
   aButtons[4]:cargo := "fs"

   @ x1+124,0 OWNERBUTTON OF oToolBar ON CLICK {|| onBtnColor() } ;
       SIZE 30,30 TEXT "A" FONT oMainWindow:oFont:SetFontStyle( .T.,,.F.,.T. )

   Atail(oToolBar:aControls):aStyle := { oStyle1,oStyle2,oStyle3 }

   @ 0, 30 PANEL oRuler SIZE oMainWindow:nWidth, 0 STYLE SS_OWNERDRAW ON SIZE {|o,x|o:Move(,,x) }

* DF7BE: old SIZE  600, 270
   @ 0, 30 HCEDITEXT oEdit SIZE 569, 260 ON SIZE { |o, x, y|o:Move( , oRuler:nHeight+oToolBar:nHeight, x, y-oRuler:nHeight-oToolBar:nHeight ) }
   oEdit:nIndent := 20
   IF hwg__isUnicode()
      oEdit:lUtf8 := .T.
   ENDIF
   oEdit:nBoundL := FREE_BOUNDL
   oEdit:nBoundT := 12

   oEdit:bColorCur := oEdit:bColor
   oEdit:AddClass( "url", "color: #000080;" )
   oEdit:AddClass( "h1", "font-size: 140%; font-weight: bold;" )
   oEdit:AddClass( "h2", "font-size: 130%; font-weight: bold;" )
   oEdit:AddClass( "h3", "font-size: 120%; font-weight: bold;" )
   oEdit:AddClass( "h4", "font-size: 110%; font-weight: bold;" )
   oEdit:AddClass( "h5", "font-weight: bold;" )
   oEdit:AddClass( "i", "font-style: italic;" )
   oEdit:AddClass( "bi", "font-style: italic; font-weight: bold;" )
   oEdit:AddClass( "u", "text-decoration: underline;" )
   oEdit:AddClass( "cite", "color: #007800; margin-left: 3%; margin-right: 3%;" )
   oEdit:AddClass( "code", "font-family: Courier; background-color: #DFDFDF; border: 1px solid #9A9A9A;" )
   oEdit:aDefClasses := { "url","h1","h2","h3","h4","h5","i","bi","u","cite","code" }
   oEdit:bOther := {|o,m,wp,lp|EditMessProc( o,m,wp,lp )}
   oEdit:bAfter := {|o,m,wp,lp|EdMsgAfter( o,m,wp,lp )}
   oEdit:bChangePos := { || onChangePos() }

   MENU OF oMainWindow
      MENU TITLE "&File"
         MENUITEM "&New"+Chr(9)+"Ctrl+N" ACTION NewFile() ACCELERATOR FCONTROL,Asc("N")
         MENUITEM "&Open"+Chr(9)+"Ctrl+O" ACTION __OpenFile() ACCELERATOR FCONTROL,Asc("O")
         MENU TITLE "&Recent files"
         FOR i := 1 TO Len( aFilesRecent )
            Hwg_DefineMenuItem( aFilesRecent[i,1], 1020 + i, ;
               &( "{||__OpenFile('" + aFilesRecent[i,1] + "','" + aFilesRecent[i,2] + "')}" ) )
         NEXT
         ENDMENU
         SEPARATOR
         MENUITEM "&Save"+Chr(9)+"Ctrl+S" ACTION SaveFile( .F. ) ACCELERATOR FCONTROL,Asc("S")
         MENUITEM "Save &as" ACTION SaveFile( .T. , .F. )
         MENUITEM "Save as &html" ACTION SaveFile( .T. , .T. )
         SEPARATOR
         MENUITEM "&Print"+Chr(9)+"Ctrl+P" ACTION PrintFile() ACCELERATOR FCONTROL,Asc("P")
         SEPARATOR
         MENUITEM "E&xit" ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Edit"
         MENUITEM "Undo"+Chr(9)+"Ctrl+Z" ACTION oEdit:Undo()
         SEPARATOR
         MENUITEM "Copy formatted"+Chr(9)+"F5" ID MENU_COPYF ACTION CopyFormatted() ACCELERATOR 0,VK_F5
         MENUITEM "Paste formatted"+Chr(9)+"Ctrl+F5" ID MENU_PASTEF ACTION PasteFormatted() ACCELERATOR FCONTROL,VK_F5
         SEPARATOR
         MENUITEM "&Find"+Chr(9)+"Ctrl+F" ACTION Find() ACCELERATOR FCONTROL,ASC("F")
         MENUITEM "Find &Next"+Chr(9)+"F3" ID MENU_FINDNEXT ACTION FindNext() ACCELERATOR 0,VK_F3
         SEPARATOR
         MENU TITLE "&Access to paragraph"
            MENUITEMCHECK "&Read only" ID MENU_PNOWR ACTION setAccess( 1 )
            MENUITEMCHECK "&OverWrite only" ID MENU_PNOINS ACTION setAccess( 2 )
            MENUITEMCHECK "&No line break" ID MENU_PNOCR ACTION setAccess( 3 )
         ENDMENU
         MENU TITLE "&Access to span"
            MENUITEMCHECK "&Read only" ID MENU_SNOWR ACTION setAccess( 1,.T. )
            MENUITEMCHECK "&OverWrite only" ID MENU_SNOINS ACTION setAccess( 2,.T. )
            MENUITEMCHECK "&No line break" ID MENU_SNOCR ACTION setAccess( 3,.T. )
            MENUITEMCHECK "&No restrictions" ID MENU_SALLOW ACTION setAccess( 0,.T. )
         ENDMENU
      ENDMENU
      MENU TITLE "&View"
         MENUITEMCHECK "&Ruler" ID MENU_RULER ACTION SetRuler()
#ifdef __PLATFORM__WINDOWS
         MENUITEMCHECK "&Scroll bar" ID MENU_VSCROLL ACTION (lScrollBar:=!lScrollBar,oEdit:ShowTrackBar(lScrollBar))
#endif
         SEPARATOR
         MENUITEM "Zoom &In"+Chr(9)+"Ctrl+ +" ACTION Zoom( 2 ) ACCELERATOR FCONTROL,VK_ADD
         MENUITEM "&Zoom &Out"+Chr(9)+"Ctrl+ -" ACTION Zoom( -2 ) ACCELERATOR FCONTROL,VK_SUBTRACT
         SEPARATOR
         MENUITEM "Set font" ACTION SetFont()
      ENDMENU
      MENU TITLE "&Insert"
         MENU TITLE "&Url"
            MENUITEM "&External"+Chr(9)+"Ctrl+I" ACTION (InsUrl( 1 ),hwg_Setfocus(oEdit:handle)) ACCELERATOR FCONTROL,Asc("I")
            MENUITEM "&Internal" ACTION (InsUrl( 2 ),hwg_Setfocus(oEdit:handle))
         ENDMENU
         MENUITEM "&Image" ACTION (setImage( .T. ),hwg_Setfocus(oEdit:handle))
         MENUITEM "&Table" ID MENU_INS_TABLE ACTION (setTable( .T. ),hwg_Setfocus(oEdit:handle))
         MENUITEM "&Block" ID MENU_INS_BLOCK ACTION (insBlock(),hwg_Setfocus(oEdit:handle))
         MENUITEM "&Script" ACTION EditScr(oEdit)
      ENDMENU
      MENU TITLE "F&ormat"
         MENU TITLE "&Selected" ID MENU_SPAN
            MENUITEM "&Properties"+Chr(9)+"Ctrl+E" ACTION (setSpan(),hwg_Setfocus(oEdit:handle)) ACCELERATOR FCONTROL,Asc("E")
            MENUITEM "to &UPPER CASE" ACTION CnvCase( 1 )
            MENUITEM "To &lower case" ACTION CnvCase( 2 )
            MENUITEM "To &Title case" ACTION CnvCase( 3 )
         ENDMENU
         SEPARATOR
         MENUITEM "&Document" ACTION (setDoc(),hwg_Setfocus(oEdit:handle))
         MENU TITLE "&Paragraph"
            MENUITEM "&Properties"+Chr(9)+"Ctrl+H" ACTION (setPara(),hwg_Setfocus(oEdit:handle)) ACCELERATOR FCONTROL,Asc("H")
            SEPARATOR
            MENUITEM "h1" ACTION oEdit:StyleDiv( ,, "h1" )
            MENUITEM "h2" ACTION oEdit:StyleDiv( ,, "h2" )
            MENUITEM "h3" ACTION oEdit:StyleDiv( ,, "h3" )
            MENUITEM "h4" ACTION oEdit:StyleDiv( ,, "h4" )
            MENUITEM "h5" ACTION oEdit:StyleDiv( ,, "h5" )
            MENUITEM "cite" ACTION oEdit:StyleDiv( ,, "cite" )
         ENDMENU
         SEPARATOR
         MENUITEM "&Image" ID MENU_IMAGE ACTION (setImage( .F. ),hwg_Setfocus(oEdit:handle))
         MENU TITLE "&Table" ID MENU_TABLE
            MENUITEM "&Properties" ACTION (setTable( .F. ),hwg_Setfocus(oEdit:handle))
            SEPARATOR
            MENUITEM "&Insert row" ACTION (InsRows(),hwg_Setfocus(oEdit:handle))
            MENUITEM "&Delete row" ACTION DelRow()
            SEPARATOR
            MENUITEM "Insert column" ACTION InsCols( .F. )
            MENUITEM "Add column" ACTION InsCols( .T. )
            MENUITEM "Delete column" ACTION DelCol()
            SEPARATOR
            MENUITEM "&Cell properties" ACTION (setCell(),hwg_Setfocus(oEdit:handle))
         ENDMENU
         MENUITEM "&Block" ID MENU_BLOCK ACTION (setBlock(),hwg_Setfocus(oEdit:handle))
      ENDMENU
      MENU TITLE "&Tools"
         MENUITEM "Calculate"+Chr(9)+"F9" ACTION Calc( oEdit ) ACCELERATOR 0,VK_F9
         MENUITEM "Calculate all"+Chr(9)+"Ctrl+F9" ACTION CalcAll( oEdit ) ACCELERATOR FCONTROL,VK_F9
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&Help" ACTION Help()
         MENUITEM "&About" ACTION About()
      ENDMENU
   ENDMENU

   handCursor := hwg_Loadcursor( CURS_HAND )

   IF fname != Nil
      __OpenFile( fname )
   ELSE
      onChangePos( .T. )
   ENDIF

   SET KEY GLOBAL 0, VK_F2 TO MarkRow()
   hwg_Enablemenuitem( , MENU_FINDNEXT, .F., .T. )
#ifdef __PLATFORM__WINDOWS
   hwg_Checkmenuitem( ,MENU_VSCROLL, .T. )
#endif

   ACTIVATE WINDOW oMainWindow
   CloseFile()

   IF lOptChg
      WriteIni( cIniPath )
   ENDIF

   RETURN Nil

STATIC FUNCTION NewFile()

   CloseFile()
   oEdit:SetText()
   onChangePos( .T. )

   RETURN Nil

FUNCTION __OpenFile( fname, cp )

   LOCAL oDlg, oGet, cFile := ""
   LOCAL aCps := { "", "DE850", "DEWIN", "RU1251", "RU866", "RUKOI8" }, nCp := 1

   CloseFile()
   IF Empty( fname )
      IF hwg__isUnicode()
         AAdd( aCps, "UTF8" )
      ENDIF

      INIT DIALOG oDlg TITLE "Open file" AT 50, 50 SIZE 400, 230 FONT HWindow():GetMain():oFont

      @ 20, 30 GET oGet VAR cFile SIZE 320, 24 STYLE ES_AUTOHSCROLL
#ifdef __GTK__
      @ 340, 30 BUTTON ".." SIZE 40, 24 ON CLICK ;
         {||fname := hwg_SelectfileEx( ,, { { "HwGUI Editor files", "*.hwge" }, { "All files", "*" } } ), cFile := Iif(Empty(fname),cFile,fname), oGet:Refresh()}
#else
      @ 340, 30 BUTTON ".." SIZE 40, 24 ON CLICK ;
         {||fname := hwg_Selectfile( { "HwGUI Editor files","All files" }, { "*.hwge","*.*" }, Curdir() ), cFile := Iif(Empty(fname),cFile,fname), oGet:Refresh()}
#endif
      @ 20, 80 SAY "Codepage:" SIZE 120, 24
      @ 140, 80 GET COMBOBOX nCp ITEMS aCps SIZE 140, 28 DISPLAYCOUNT 5

      @ 20, 180  BUTTON "Ok" SIZE 100, 32 ON CLICK {||oDlg:lResult := .T., hwg_EndDialog() }
      @ 280, 180 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

      ACTIVATE DIALOG oDlg
      cp := aCps[nCp]
   ELSE
      cFile := fname
   ENDIF

   IF ( Empty(oDlg) .OR. oDlg:lResult ) .AND. !Empty( cFile )
      IF !( Lower( hb_FNameExt( fname ) ) $ ".html;.hwge;" )
         oEdit:bImport := { |o, cText| SetText( o, cText ) }
      ENDIF
      oEdit:SetText( MemoRead(fname), Iif( Empty(cp), Nil, cp ), SetCpDef( cp ) )
      oEdit:cFileName := fname

      oEdit:bImport := Nil
      oEdit:nBoundL := Iif( oEdit:nDocFormat > 0, DOC_BOUNDL, FREE_BOUNDL )
      onChangePos( .T. )
      IF oEdit:lError
         hwg_MsgStop( "Wrong file format!" )
      ENDIF
      Add2Recent( fname )
   ENDIF

   RETURN Nil

STATIC FUNCTION SaveFile( lAs, lHtml )

   LOCAL oDlg, oGet, cFile := "", fname
   LOCAL aCps, nCp := 1, cp := ""

   IF lAs .OR. Empty( oEdit:cFileName )
      IF Empty( oEdit:cpSource ) .OR. oEdit:cpSource == "UTF8"
         aCps := { "DE850", "DEWIN", "RU1251", "RU866", "RUKOI8" }
         IF Empty( oEdit:cpSource )
            hb_AIns( aCps, 1, "", .T. )
         ENDIF
      ELSEIF Left( oEdit:cpSource,2 ) == "RU"
         aCps := { "RU1251", "RU866", "RUKOI8" }
      ELSE
         aCps := { "DE850", "DEWIN" }
      ENDIF
      IF hwg__isUnicode()
         AAdd( aCps, "UTF8" )
      ENDIF
      nCp := Iif( Empty( oEdit:cpSource ), 1, Ascan( aCps, oEdit:cpSource ) )
      IF lAs
         cFile := oEdit:cFileName
      ENDIF

      INIT DIALOG oDlg TITLE "Save file" AT 50, 50 SIZE 400, 230 FONT oFontMain

      @ 20, 30 GET oGet VAR cFile SIZE 320, 24 STYLE ES_AUTOHSCROLL
#ifdef __GTK__
      @ 340, 30 BUTTON ".." SIZE 40, 24 ON CLICK ;
         {||fname := hwg_SelectfileEx( ,, { Iif(Empty(lHtml),{"HwGUI Editor files","*.hwge"},{"Html files","*.html"}), { "All files", "*" } } ), cFile := Iif(Empty(fname),cFile,fname), oGet:Refresh()}
#else
      @ 340, 30 BUTTON ".." SIZE 40, 24 ON CLICK ;
         {||fname := hwg_Savefile( "*.*", "( *.* )", "*.*", CurDir() ), cFile := Iif(Empty(fname),cFile,fname), oGet:Refresh()}
#endif
      @ 20, 80 SAY "Codepage:" SIZE 120, 24
      @ 140, 80 GET COMBOBOX nCp ITEMS aCps SIZE 140, 28 DISPLAYCOUNT 5

      @ 20, 180  BUTTON "Ok" SIZE 100, 32 ON CLICK {||oDlg:lResult := .T., hwg_EndDialog() }
      @ 280, 180 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

      ACTIVATE DIALOG oDlg
      cp := aCps[nCp]
   ELSE
      cFile := oEdit:cFileName
      cp := oEdit:cpSource
   ENDIF

   IF !Empty( cFile )
      IF Empty( hb_FnameExt( cFile ) )
         cFile += Iif( Empty( lHtml ), ".hwge", ".html" )
      ENDIF
      oEdit:Save( cFile, cp, lHtml )
      oEdit:lUpdated := .F.
      oEdit:cpSource := cp
      IF Empty( lHtml )
         Add2Recent( cFile )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION CloseFile()

   IF oEdit:lUpdated .AND. hwg_MsgYesNo( "Save changes ?" )
      SaveFile( .F. )
   ENDIF

   RETURN Nil

STATIC FUNCTION PrintFile()

   IF Empty( oEdit:nDocFormat )
      setDoc()
   ENDIF
   IF !Empty( oEdit:nDocFormat )
      oEdit:Print()
   ENDIF

   RETURN Nil

STATIC FUNCTION SetRuler()

   IF Empty( oRuler:bPaint )
      oRuler:bPaint := { |o| PaintRuler(o) }
      oRuler:nHeight := 32
      oEdit:Move( , oRuler:nHeight+oToolBar:nHeight,, oEdit:nHeight - 28 )
      hwg_Checkmenuitem( ,MENU_RULER, .T. )
   ELSE
      oRuler:bPaint := Nil
      oRuler:nHeight := 0
      oEdit:Move( , oRuler:nHeight+oToolBar:nHeight,, oEdit:nHeight + 28 )
      hwg_Checkmenuitem( ,MENU_RULER, .F. )
   ENDIF
   oRuler:Move( ,,, oRuler:nHeight )

   RETURN Nil

STATIC FUNCTION PaintRuler( o )
   LOCAL pps, hDC, aCoors, n1cm, x := oEdit:nBoundL - oEdit:nShiftL, i := 0, nBoundR

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( o:handle, pps )

   n1cm := Round( oEdit:nKoeffScr * 10, 0 )
   aCoors := hwg_Getclientrect( o:handle )

   nBoundR := iif( !Empty( oEdit:nDocWidth ), Min( aCoors[3], oEdit:nDocWidth + oEdit:nMarginR - oEdit:nShiftL ), aCoors[3] - 10 )
   hwg_Fillrect( hDC, If( x < 0,0,x ), 4, nBoundR, 28, oBrush1:handle )
   DO WHILE x <= ( nBoundR - n1cm )
      i ++
      x += n1cm
      IF x > 0
         hwg_Drawline( hDC, x, 8, x, iif( i % 10 == 0, 26, 16 ) )
         IF i % 2 == 0
            hwg_Selectobject( hDC, oFontP:handle )
            hwg_Settransparentmode( hDC, .T. )
            hwg_Drawtext( hDC, LTrim( Str(i,2 ) ), x - 12, 12, x + 12, 30, DT_CENTER )
            hwg_Settransparentmode( hDC, .F. )
         ENDIF
      ENDIF
   ENDDO

   hwg_Endpaint( o:handle, pps )

   RETURN Nil

STATIC FUNCTION onBtnSize()

   LOCAL cAttr

   IF !lComboSet
      IF !Empty( oEdit:aPointM2[P_Y] ) .OR. !Empty( oEdit:aTdSel[2] )

         cAttr := "fh" + oComboSiz:aItems[oComboSiz:Value]
         oEdit:ChgStyle( ,, cAttr )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION onBtnColor()

   LOCAL nColor, cAttr

   IF !Empty( oEdit:aPointM2[P_Y] ) .OR. !Empty( oEdit:aTdSel[2] )

      IF ( nColor := Hwg_ChooseColor( 0 ) ) != Nil
         cAttr := "ct" + Ltrim(Str( nColor ))
         oEdit:ChgStyle( ,, cAttr )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION onBtnStyle( nBtn )

   LOCAL cAttr

   IF !Empty( oEdit:aPointM2[P_Y] ) .OR. !Empty( oEdit:aTdSel[2] )

      cAttr := aButtons[nBtn]:cargo + Iif( aButtons[nBtn]:lPress, "", "-" )
      oEdit:ChgStyle( ,, cAttr )
   ELSE
      oEdit:PCopy( oEdit:aPointC, aPointLast )
      nCharsLast := hced_Len( oEdit, oEdit:aText[oEdit:aPointC[P_Y]] )
      IF Empty( aSetStyle )
         aSetStyle := { -1, -1, -1, -1, -1 }
      ENDIF
      aSetStyle[nBtn] := Iif( aButtons[nBtn]:lPress, 1, 0 )
   ENDIF

   RETURN Nil

STATIC FUNCTION onChangePos( lInit )

   LOCAL arr, aStru, aAttr, i, l, lb, cTmp, nOptP, nOptS, aStruTbl, nL, nEnv
   STATIC lInTable := .F., lSelection := .T., lImage := .T., lInBlock := .F.

   IF lInit == Nil; lInit := .F.; ENDIF

   lComboSet := .T.
   IF !Empty(aSetStyle) .AND. ( nLastMsg == WM_CHAR .OR. nLastMsg == WM_KEYDOWN ) .AND. ;
         oEdit:aPointC[P_Y] == aPointLast[P_Y] .AND. ;
         ( i := hced_Len( oEdit, oEdit:aText[oEdit:aPointC[P_Y]] ) ) > nCharsLast
      aAttr := {}
      FOR i := 1 TO 4
         IF aSetStyle[i] >= 0
            AAdd( aAttr, aButtons[i]:cargo + Iif( aSetStyle[i]==0,"-","" ) )
         ENDIF
      NEXT
      oEdit:ChgStyle( aPointLast, oEdit:aPointC, aAttr )
   ELSE
      IF !Empty( arr := oEdit:GetPosInfo() ) .AND. !Empty( arr[3] ) .AND. ;
            !Empty( arr[3][OB_CLS] )
         aAttr := oEdit:getClassAttr( arr[3][OB_CLS] )
         FOR i := 1 TO 4
            IF Ascan( aAttr, aButtons[i]:cargo ) > 0
               aButtons[i]:Press()
            ELSEIF aButtons[i]:lPress
               aButtons[i]:Release()
            ENDIF
         NEXT
         cTmp := Iif( ( i := Ascan(aAttr,"fh") ) == 0, cComboSizDef, Substr(aAttr[i],3) )
         IF ( i := Ascan( oComboSiz:aItems,cTmp ) ) != 0 .AND. oComboSiz:Value != i
            oComboSiz:Value := i
         ENDIF
      ELSE
         FOR i := 1 TO 4
            IF aButtons[i]:lPress
               aButtons[i]:Release()
            ENDIF
         NEXT
         IF oComboSiz:aItems[oComboSiz:Value] != cComboSizDef
            oComboSiz:Value := Ascan( oComboSiz:aItems,cComboSizDef )
         ENDIF
      ENDIF
      IF lSelection != ( !Empty(oEdit:aPointM2[P_Y]) )
         lSelection := ( !Empty(oEdit:aPointM2[P_Y]) )
         hwg_Enablemenuitem( , MENU_COPYF, lSelection, .T. )
      ENDIF
      IF lInit
         hwg_Enablemenuitem( , MENU_PASTEF, .F., .T. )
      ENDIF
      hwg_Enablemenuitem( , MENU_SPAN, (!Empty(arr).AND.!Empty(arr[3])).OR.lSelection, .T. )

      IF !Empty( arr )
         aStru := Iif( Len( arr ) >= 7, arr[7], oEdit:aStru[arr[1]] )
         IF ( l := ( Valtype(aStru[1,OB_TYPE]) == "C" .AND. aStru[1,OB_TYPE] == "img" ) ) != lImage
            lImage := l
            hwg_Enablemenuitem( , MENU_IMAGE, l, .T. )
         ENDIF
      ENDIF
      l := ( ( (nEnv := oEdit:getEnv()) > 0 ) .OR. ( !Empty(arr).AND.Len(arr)>= 7 ) )
      lB := l
      IF l
         IF nEnv > 0
            nL := Int( (nEnv - nEnv%256)/256 )
            aStru := oEdit:getEnv( OB_ASTRU )
         ELSE
            nL := oEdit:aPointC[P_Y]
            aStru := oEdit:aStru
         ENDIF
         IF aStru[nL,1,OB_TRNUM] > 1
            lB := .F.
         ELSE
            aStruTbl := aStru[nL,1,OB_TBL]
            IF Len( aStruTbl[OB_OB] ) > 1
               lB := .F.
            ELSE
               IF nL+1 <= Len(aStru) .AND. Valtype(aStru[nL+1,1,1]) == "C" .AND. aStru[nL+1,1,1] == "tr"
                  lB := .F.
               ENDIF
            ENDIF
         ENDIF
      ENDIF
      IF lb != lInBlock .OR. l != lInTable .OR. lInit
         IF l != lInTable .OR. lInit
            lInTable := l
            hwg_Enablemenuitem( , MENU_INS_BLOCK, !lInTable, .T. )
            hwg_Enablemenuitem( , MENU_INS_TABLE, !lInTable, .T. )
         ENDIF
         IF lb != lInBlock .OR. lInit
            lInBlock := lb
            hwg_Enablemenuitem( , MENU_BLOCK, lInBlock, .T. )
         ENDIF
         hwg_Enablemenuitem( , MENU_TABLE, lInTable.AND.!lInBlock, .T. )
      ENDIF
   ENDIF
   nOptP := hced_getAccInfo( oEdit, oEdit:aPointC, 0 )
   IF ( nOptS := hced_getAccInfo( oEdit, oEdit:aPointC, 1 ) ) == Nil
      nOptS := 0
   ENDIF
   FOR i := 1 TO 3
      IF hwg_CheckBit( nOptP, i+1 ) != alAcc[i]
         alAcc[i] := !alAcc[i]
         hwg_Checkmenuitem( ,MENU_PNOWR+i-1, alAcc[i] )
      ENDIF
      IF hwg_CheckBit( nOptS, i+1 ) != alAcc[i+3]
         alAcc[i+3] := !alAcc[i+3]
         hwg_Checkmenuitem( ,MENU_SNOWR+i-1, alAcc[i+3] )
      ENDIF
   NEXT
   IF hwg_CheckBit( nOptS, 1 ) != alAcc[7]
      alAcc[7] := !alAcc[7]
      hwg_Checkmenuitem( ,MENU_SALLOW, alAcc[7] )
   ENDIF

   aSetStyle := Nil
   lComboSet := .F.

   RETURN Nil

STATIC FUNCTION insBlock()

   LOCAL oDlg, nChoice := 1, nStyle := 1, aStyles := { "code" }
   LOCAL i, nl1, nl2, cBuff, aAttr, nWidth := Nil

   IF Len( oEdit:GetPosInfo() ) >= 7
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Insert block"  ;
      AT 210, 10  SIZE 300, 230 FONT HWindow():GetMain():oFont

   @ 20, 20 SAY "Style:" SIZE 90, 22 TRANSPARENT
   @ 110, 20 GET COMBOBOX nStyle ITEMS aStyles SIZE 160, 28 DISPLAYCOUNT 4

   IF !Empty( oEdit:aPointM2[P_Y] )
      nChoice := 2
      @ 10,50 GET RADIOGROUP nChoice  CAPTION "" SIZE 280, 100
      @ 40,80 RADIOBUTTON "Insert empty" SIZE 230, 24
      @ 40,110 RADIOBUTTON "With selected lines" SIZE 230, 24
      END RADIOGROUP
   ENDIF

   @  20, 170  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T., hwg_EndDialog() }
   @ 180, 170 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF nChoice == 1
         nl1 := nl2 := oEdit:aPointC[P_Y]
      ELSE
         nl1 := Min( oEdit:aPointM1[P_Y], oEdit:aPointM2[P_Y] )
         nl2 := Max( oEdit:aPointM1[P_Y], oEdit:aPointM2[P_Y] )

         cBuff := oEdit:Save( ,,, .T., { 1,nl1 }, { Len(oEdit:aText[nl2])+1, nl2 } )

         IF !Empty( cBuff )
            IF Asc( cBuff ) == 32
               cBuff := Ltrim( cBuff )
            ENDIF
         ENDIF

         FOR i := nl2 TO nl1 STEP -1
            oEdit:DelLine( i )
         NEXT

      ENDIF

      oEdit:aPointC[P_X] := 1; oEdit:aPointC[P_Y] := nl1
      aAttr := oEdit:getClassAttr( aStyles[nStyle] )
      IF nStyle == 1
         nWidth := -94
      ENDIF
      oEdit:InsTable( {-100}, 1, nWidth, 1, aAttr )

      IF !Empty( cBuff )
         oEdit:LoadEnv( nl1, 1 )

         oEdit:SetText( cBuff,,, .T., .F., 1 )

         oEdit:RestoreEnv( nl1, 1 )
         oEdit:aPointM2[P_Y] := 0
      ENDIF

      oEdit:Scan( nl1 )
      oEdit:Paint( .F. )
      hced_Invalidaterect( oEdit:hEdit, 0, 0, 0, oEdit:nClientWidth, oEdit:nHeight )
   ENDIF

   RETURN Nil

STATIC FUNCTION textTab( oTab, aAttr, nTop )

   LOCAL i, oSayTest, nColor, oSayTClr, oSayBClr
   LOCAL bColorT, bColorB
   MEMVAR tColor, bColor, tc, tb, aComboFam, cFamily, nFamily
   MEMVAR nSize, nsb, nfb
   MEMVAR lb, li, lu, ls, lbb, lib, lub, lsb

   bColorT := {||
      IF ( nColor := Hwg_ChooseColor( tColor ) ) != Nil
         tColor := nColor
         oSayTest:Setcolor( tColor,,.T. )
         oSayTClr:SetText( Iif( tColor==0,"Default","#"+hwg_ColorN2C(tColor) ) )
         hwg_Redrawwindow( oSayTClr:handle, RDW_ERASE + RDW_INVALIDATE + + RDW_INTERNALPAINT + RDW_UPDATENOW )
      ENDIF
      RETURN .T.
   }
   bColorB := {||
      IF ( nColor := Hwg_ChooseColor( bColor ) ) != Nil
         bColor := nColor
         oSayTest:Setcolor( ,bColor,.T. )
         oSayBClr:SetText( Iif( bColor==16777215,"Default","#"+hwg_ColorN2C(bColor) ) )
         hwg_Redrawwindow( oSayBClr:handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
      ENDIF
      RETURN .T.
   }

   IF nTop == Nil
     nTop := GetVal_nTop()
   ENDIF

   IF !Empty( aAttr )
      IF ( i := Ascan( aAttr, "ct" ) ) != 0
         tColor := Val( SubStr( aAttr[i],3 ) )
      ENDIF
      IF ( i := Ascan( aAttr, "cb" ) ) != 0
         bColor := Val( SubStr( aAttr[i],3 ) )
      ENDIF
      IF ( i := Ascan( aAttr, "fn" ) ) != 0
         cFamily := SubStr( aAttr[i],3 )
      ENDIF
      IF ( i := Ascan( aAttr, "fh" ) ) != 0
         IF ( i := Ascan( oComboSiz:aItems,Substr(aAttr[i],3) ) ) > 0
            nSize := i
         ENDIF
      ENDIF
      IF ( i := Ascan( aAttr, "fb" ) ) != 0
         lb := ( Substr(aAttr[i],3,1) != '-' )
      ENDIF
      IF ( i := Ascan( aAttr, "fi" ) ) != 0
         li := ( Substr(aAttr[i],3,1) != '-' )
      ENDIF
      IF ( i := Ascan( aAttr, "fu" ) ) != 0
         lu := ( Substr(aAttr[i],3,1) != '-' )
      ENDIF
      IF ( i := Ascan( aAttr, "fs" ) ) != 0
         ls := ( Substr(aAttr[i],3,1) != '-' )
      ENDIF
   ENDIF
   tc := tColor; tb := bColor; nsb := nSize; nfb := nFamily
   lbb := lb; lib := li; lub := lu; lsb := ls

   IF oTab != Nil
      BEGIN PAGE "Text" of oTab
   ENDIF

      @ 10, nTop GROUPBOX "Font" SIZE 360, 160

      @ 20,nTop+20 SAY "Family:" SIZE 90, 22 TRANSPARENT
      IF ( i := Ascan( aComboFam, cFamily ) ) > 0
         nFamily := i
      ENDIF
      @ 110,nTop+20 GET COMBOBOX nFamily ITEMS aComboFam SIZE 240, 28 DISPLAYCOUNT 8

      @ 20,nTop+60 SAY "Size:" SIZE 90, 22 TRANSPARENT
      @ 110,nTop+60 GET COMBOBOX nSIze ITEMS oComboSiz:aItems SIZE 90, 26 DISPLAYCOUNT 6

      @ 20, nTop+100 GET CHECKBOX lb CAPTION "Bold" SIZE 140, 22 TRANSPARENT
      @ 190,nTop+100 GET CHECKBOX li CAPTION "Italic" SIZE 140, 22 TRANSPARENT
      @ 20, nTop+124 GET CHECKBOX lu CAPTION "Underline" SIZE 140, 22 TRANSPARENT
      @ 190,nTop+124 GET CHECKBOX ls CAPTION "Strikeout" SIZE 140, 22 TRANSPARENT

      @ 10, nTop+188 GROUPBOX "Color" SIZE 360, 140
      @ 20, nTop+214 SAY "Text:" SIZE 120, 22 TRANSPARENT
      @ 150,nTop+210  BUTTON "Select" SIZE 100, 32 ON CLICK bColorT
      @ 260,nTop+214 SAY oSayTClr CAPTION Iif( tColor==0,"Default","#"+hwg_ColorN2C(tColor) ) SIZE 90, 24 STYLE WS_BORDER BACKCOLOR 16777215

      @ 20, nTop+254 SAY "Background:" SIZE 120, 22 TRANSPARENT
      @ 150,nTop+250 BUTTON "Select" SIZE 100, 32 ON CLICK bColorB
      @ 260,nTop+254 SAY oSayBClr CAPTION Iif( bColor==16777215,"Default","#"+hwg_ColorN2C(bColor) ) SIZE 90, 24 STYLE WS_BORDER BACKCOLOR 16777215

      @ 20, nTop+290 SAY oSayTest CAPTION "This is a sample" SIZE 340, 26 ;
         STYLE WS_BORDER + SS_CENTER COLOR tColor BACKCOLOR bcolor

   IF oTab != Nil
      END PAGE of oTab
   ENDIF

   RETURN Nil

STATIC FUNCTION text2attr( aAttr )

   MEMVAR tColor, bColor, tc, tb, aComboFam, cFamily, nFamily
   MEMVAR nSize, nsb, nfb
   MEMVAR lb, li, lu, ls, lbb, lib, lub, lsb

   IF tColor != tc .OR. bColor != tb .OR. ;
         nFamily != nfb .OR. nSize != nsb .OR. lbb != lb .OR. lib != li .OR. lub != lu .OR. lsb != ls

      IF tColor != tc
         AAdd( aAttr, "ct" + LTrim( Str(tColor ) ) )
      ENDIF
      IF bColor != tb
         AAdd( aAttr, "cb" + LTrim( Str(bColor ) ) )
      ENDIF
      IF nFamily != nfb
         AAdd( aAttr, "fn" + aComboFam[nFamily] )
      ENDIF
      IF nSize != nsb
         AAdd( aAttr, "fh" + oComboSiz:aItems[nSize] )
      ENDIF
      IF lb != lbb
         AAdd( aAttr, "fb" + Iif( lb, "","-" ) )
      ENDIF
      IF li != lib
         AAdd( aAttr, "fi" + Iif( li, "","-" ) )
      ENDIF
      IF lu != lub
         AAdd( aAttr, "fu" + Iif( lu, "","-" ) )
      ENDIF
      IF ls != lsb
         AAdd( aAttr, "fs" + Iif( ls, "","-" ) )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION setCell()
   LOCAL oDlg
   LOCAL cClsName, aAttr

   MEMVAR tColor, bColor, tc, tb, aComboFam, cFamily, nFamily
   MEMVAR nSize, nsb, nfb
   MEMVAR lb, li, lu, ls, lbb, lib, lub, lsb
   PRIVATE tColor := oEdit:tColor, bColor := oEdit:bColor, tc, tb
   PRIVATE aComboFam := Asort( hwg_getFontsList() ), cFamily := "", nFamily := 1
   PRIVATE nSize := Ascan( oComboSiz:aItems,cComboSizDef ), nsb, nfb
   PRIVATE lb := .F., li := .F., lu := .F., ls := .F., lbb, lib, lub, lsb

   IF Len( oEdit:GetPosInfo() ) < 7
      RETURN Nil
   ENDIF

   cClsName := oEdit:aStru[oEdit:aPointC[P_Y],1,OB_OB,oEdit:aPointc[P_X],OB_CLS]
   IF !Empty( cClsName )
      aAttr := oEdit:getClassAttr( cClsName )
   ENDIF

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Set cell properties"  ;
      AT 210, 10  SIZE 400, 410 FONT HWindow():GetMain():oFont

   textTab( , aAttr, 16 )

   @  20, 360  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T., hwg_EndDialog() }
   @ 280, 360 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      aAttr := { }
      text2attr( aAttr )
      IF !Empty( aAttr )
        oEdit:StyleDiv( , aAttr )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION setPara()
   LOCAL oDlg, nMarginL := oEdit:nMarginL, nMarginR := oEdit:nMarginR, nIndent := oEdit:nIndent
   LOCAL oTab, nTop, nColor
   LOCAL nBWidth := 0, nBColor := 0, cId := ""
   LOCAL lml := .F. , lmr := .F. , lti := .F. , nAlign := 1, aCombo := { "Left", "Center", "Right" }
   LOCAL nL := oEdit:aPointC[P_Y], arr1, cClsName, aAttr, i, arr[6]
   LOCAL lFew := .F.

   MEMVAR tColor, bColor, tc, tb, aComboFam, cFamily, nFamily
   MEMVAR nSize, nsb, nfb
   MEMVAR lb, li, lu, ls, lbb, lib, lub, lsb
   PRIVATE tColor := oEdit:tColor, bColor := oEdit:bColor, tc, tb
   PRIVATE aComboFam := Asort( hwg_getFontsList() ), cFamily := "", nFamily := 1
   PRIVATE nSize := Ascan( oComboSiz:aItems,cComboSizDef ), nsb, nfb
   PRIVATE lb := .F., li := .F., lu := .F., ls := .F., lbb, lib, lub, lsb

   nTop := GetVal_nTop()

   IF !Empty( oEdit:aPointM2[P_Y] ) .AND. oEdit:aPointM2[P_Y] != oEdit:aPointM1[P_Y]
      lFew := .T.
   ELSE
      IF Len( arr1 := oEdit:GetPosInfo() ) >= 7
         cClsName := arr1[7,1,OB_CLS]
         IF Len( arr1[7,1] ) >= OB_ID
            cId := arr1[7,1,OB_ID]
         ENDIF
      ELSE
         cClsName := oEdit:aStru[nl,1,OB_CLS]
         IF Len( oEdit:aStru[nl,1] ) >= OB_ID
            cId := oEdit:aStru[nl,1,OB_ID]
         ENDIF
      ENDIF
   ENDIF

   IF !Empty( cClsName )
      aAttr := oEdit:getClassAttr( cClsName )
      IF ( i := Ascan( aAttr, "ml" ) ) != 0
         nMarginL := Val( SubStr( aAttr[i],3 ) )
         lml := ( Right( aAttr[i],1 ) == '%' )
      ENDIF
      IF ( i := Ascan( aAttr, "mr" ) ) != 0
         nMarginR := Val( SubStr( aAttr[i],3 ) )
         lmr := ( Right( aAttr[i],1 ) == '%' )
      ENDIF
      IF ( i := Ascan( aAttr, "ti" ) ) != 0
         nIndent := Val( SubStr( aAttr[i],3 ) )
         lti := ( Right( aAttr[i],1 ) == '%' )
      ENDIF
      IF ( i := Ascan( aAttr, "ta" ) ) != 0
         nAlign := Val( SubStr( aAttr[i],3 ) ) + 1
      ENDIF
      IF ( i := Ascan( aAttr, "bw" ) ) != 0
         nBWidth := Val( SubStr( aAttr[i],3 ) )
      ENDIF
      IF ( i := Ascan( aAttr, "bc" ) ) != 0
         nBColor := Val( SubStr( aAttr[i],3 ) )
      ENDIF
   ENDIF

   arr[1] := nMarginL; arr[2] := nMarginR; arr[3] := nIndent; arr[4] := nAlign; arr[5] := nBWidth; arr[6] := nBColor
   tc := tColor; tb := bColor; nsb := nSize; nfb := nFamily
   lbb := lb; lib := li; lub := lu; lsb := ls

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Set paragraph properties"  ;
      AT 210, 10  SIZE 400, 460 FONT HWindow():GetMain():oFont

   @ 10, 10 TAB oTab ITEMS {} SIZE 380,380 ON SIZE ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_BOTTOMABS+ANCHOR_RIGHTABS

   BEGIN PAGE "Layout" of oTab

      @ 10, nTop GROUPBOX "Margins" SIZE 360, 130
      @ 30, nTop+20 SAY "Left:" SIZE 120, 24 TRANSPARENT
      @ 150, nTop+20 GET nMarginL SIZE 80, 24 PICTURE "999"
      @ 242, nTop+20 GET CHECKBOX lml CAPTION "in %" SIZE 80, 22 TRANSPARENT

      @ 30, nTop+48 SAY "Right:" SIZE 120, 24 TRANSPARENT
      @ 150,nTop+48 GET nMarginR SIZE 80, 24 PICTURE "999"
      @ 242,nTop+48 GET CHECKBOX lmr CAPTION "in %" SIZE 80, 22 TRANSPARENT

      @ 30, nTop+76 SAY "First line:" SIZE 120, 24 TRANSPARENT
      @ 150,nTop+76 GET nIndent SIZE 80, 24 PICTURE "999"
      @ 242,nTop+76 GET CHECKBOX lti CAPTION "in %" SIZE 80, 22 TRANSPARENT

      @ 30, nTop+140 SAY "Alignment:" SIZE 140, 24 TRANSPARENT
      @ 150,nTop+140 GET COMBOBOX nAlign ITEMS aCombo SIZE 120, 24 DISPLAYCOUNT 4

      @ 10, nTop+190 GROUPBOX "Border" SIZE 360, 80
      @ 30, nTop+226 SAY "Width:" SIZE 100, 24 TRANSPARENT
      @ 150,nTop+220 GET nBWidth SIZE 60, 24 PICTURE "9"
      @ 240,nTop+220  BUTTON "Color" SIZE 80, 30 ;
            ON CLICK {||Iif((nColor:=Hwg_ChooseColor(nBColor))==Nil,.T.,(nBColor:=nColor)) }
      IF !lFew
         @ 30, nTop+290 SAY "Anchor:" SIZE 100, 24 TRANSPARENT
         @ 170,nTop+290 GET cId SIZE 100, 24 MAXLENGTH 0
      ENDIF

   END PAGE of oTab

   textTab( oTab, aAttr )

   @  20, 410  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 220, 410 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      aAttr := { }
      IF arr[1] != nMarginL .OR. arr[2] != nMarginR .OR. ;
         arr[3] != nIndent .OR. arr[4] != nAlign .OR. arr[5] != nBWidth .OR. arr[6] != nBColor

         IF arr[1] != nMarginL
            AAdd( aAttr, "ml" + LTrim( Str( nMarginL ) ) + iif( lml, '%', '' ) )
         ENDIF
         IF arr[2] != nMarginR
            AAdd( aAttr, "mr" + LTrim( Str( nMarginR ) ) + iif( lmr, '%', '' ) )
         ENDIF
         IF arr[3] != nIndent
            AAdd( aAttr, "ti" + LTrim( Str( nIndent ) ) + iif( lti, '%', '' ) )
         ENDIF
         IF arr[4] != nAlign
            AAdd( aAttr, "ta" + LTrim( Str( nAlign - 1 ) ) )
         ENDIF
         IF arr[5] != nBWidth
            AAdd( aAttr, "bw" + LTrim( Str( nBWidth ) ) )
         ENDIF
         IF arr[6] != nBColor
            AAdd( aAttr, "bc" + LTrim( Str( nBColor ) ) )
         ENDIF
      ENDIF

      text2attr( aAttr )
      IF !Empty( aAttr )
         IF lFew
            oEdit:ChgStyle( ,, aAttr, .T. )
         ELSE
            IF Len( arr1 ) >= 7
               oEdit:LoadEnv( arr1[1], arr1[2] )
               oEdit:StyleDiv( arr1[4], aAttr )
               oEdit:RestoreEnv( arr1[1], arr1[2] )
            ELSE
               oEdit:StyleDiv( nL, aAttr )
            ENDIF
         ENDIF
      ENDIF
      IF !lFew .AND. !Empty( cId )
         IF Len( arr1 ) >= 7
            oEdit:LoadEnv( arr1[1], arr1[2] )
            nl := arr1[4]
         ENDIF
         IF Len( oEdit:aStru[nl,1] ) >= OB_ID
            oEdit:aStru[nl,1,OB_ID] := cId
         ELSE
            Aadd( oEdit:aStru[nl,1], cId )
         ENDIF
         IF Len( arr1 ) >= 7
            oEdit:RestoreEnv( arr1[1], arr1[2] )
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION setSpan()
   LOCAL oDlg, oTab, nTop
   LOCAL nL, aStru, cClsName, aAttr, arr1
   LOCAL cId := "", cIdB := "", nAcc := 0, cHref := "", cHrefB := "", cBody := "", cBodyB := ""

   MEMVAR tColor, bColor, tc, tb, aComboFam, cFamily, nFamily
   MEMVAR nSize, nsb, nfb
   MEMVAR lb, li, lu, ls, lbb, lib, lub, lsb
   PRIVATE tColor := oEdit:tColor, bColor := oEdit:bColor, tc, tb
   PRIVATE aComboFam := Asort( hwg_getFontsList() ), cFamily := "", nFamily := 1
   PRIVATE nSize := Ascan( oComboSiz:aItems,cComboSizDef ), nsb, nfb
   PRIVATE lb := .F., li := .F., lu := .F., ls := .F., lbb, lib, lub, lsb

   nTop := GetVal_nTop()

   IF !Empty( oEdit:aPointM2[P_Y] ) .OR. !Empty( oEdit:aTdSel[2] )
   ELSE
      arr1 := oEdit:GetPosInfo()
      IF !Empty( aStru := arr1[3] )
         cClsName := aStru[OB_CLS]
         IF Len( aStru ) >= OB_ID
            cId := cIdB := aStru[OB_ID]
         ENDIF
         IF Len( aStru ) >= OB_ACCESS
            nAcc := aStru[OB_ACCESS]
         ENDIF
         IF Len( aStru ) >= OB_HREF
            cHref := cHrefB := aStru[OB_HREF]
         ENDIF
         IF Len( arr1 := oEdit:GetPosInfo() ) >= 7
            oEdit:LoadEnv( arr1[1], arr1[2] )
            nL := arr1[4]
         ELSE
            nL := arr1[1]
         ENDIF
         cBody := cBodyB := hced_SubStr( oEdit, oEdit:aText[nL], aStru[1], aStru[2] - aStru[1] + 1 )
         IF Len( arr1 ) >= 7
            oEdit:RestoreEnv( arr1[1], arr1[2] )
         ENDIF
      ELSE
         RETURN Nil
      ENDIF

      IF !Empty( cClsName )
         aAttr := oEdit:getClassAttr( cClsName )
      ENDIF
   ENDIF

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Set span properties"  ;
      AT 210, 10  SIZE 400, 460 FONT HWindow():GetMain():oFont

   @ 10, 10 TAB oTab ITEMS {} SIZE 380,380 ON SIZE ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_BOTTOMABS+ANCHOR_RIGHTABS

   textTab( oTab, aAttr )

   BEGIN PAGE "Attributes" of oTab

   IF !Empty( aStru )
      @ 10,nTop SAY "Id:" SIZE 50, 22 TRANSPARENT
      @ 60,nTop GET cId SIZE 100, 24 MAXLENGTH 0
   ENDIF

   IF !Empty( cHRef ) .AND. !hwg_CheckBit( nAcc, BIT_CLCSCR )
      @ 10,nTop+40 SAY "Href:" SIZE 60, 22 TRANSPARENT
      @ 10,nTop+64 GET cHref SIZE 360, 26 STYLE ES_AUTOHSCROLL MAXLENGTH 0 ;
            ON SIZE {|o,x,y| (y), o:Move( ,,x-30)}

      @ 10,nTop+100 SAY "Text:" SIZE 60, 22 TRANSPARENT
      @ 10,nTop+124 GET cBody SIZE 360, 26 STYLE ES_AUTOHSCROLL MAXLENGTH 0 ;
            ON SIZE {|o,x,y| (y), o:Move( ,,x-30)}
   ENDIF

   END PAGE of oTab

   @  20, 410  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 220, 410 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      aAttr := { }
      text2attr( aAttr )
      IF !Empty( aAttr )
         IF !Empty( oEdit:aPointM2[P_Y] ) .OR. !Empty( oEdit:aTdSel[2] )
            oEdit:ChgStyle( ,, aAttr )
         ELSEIF Len(arr1) >= 7
            oEdit:ChgStyle( {aStru[1],arr1[4]}, {aStru[2]+1,arr1[4]}, aAttr,, ;
                  {arr1[2],arr1[1]} )
         ELSE
            oEdit:ChgStyle( {aStru[1],arr1[1]}, {aStru[2]+1,arr1[1]}, aAttr )
         ENDIF
      ENDIF
      IF !( cHref == cHrefB )
         aStru[OB_HREF] := cHref
         oEdit:lUpdated := .T.
      ENDIF
      IF !( cId == cIdB )
         IF Len( aStru ) >= OB_ID
            aStru[OB_ID] := cId
         ELSE
            Aadd( aStru, cId )
         ENDIF
         oEdit:lUpdated := .T.
      ENDIF
      IF cBody != cBodyB
         IF Len( arr1 := oEdit:GetPosInfo() ) >= 7
            oEdit:LoadEnv( arr1[1], arr1[2] )
            nL := arr1[4]
         ELSE
            nL := arr1[1]
         ENDIF
         oEdit:InsText( { aStru[1],nL }, cBody,, .F. )
         oEdit:DelText( { aStru[1]+hced_Len(oEdit,cBody),nL }, ;
               { aStru[1]+hced_Len(oEdit,cBody)+hced_Len(oEdit,cBodyB),nL }, .F. )
         oEdit:lUpdated := .T.
         IF Len( arr1 ) >= 7
            oEdit:RestoreEnv( arr1[1], arr1[2] )
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION setBlock()

   LOCAL oDlg, oTab, oSayClr, nTop
   LOCAL nL := oEdit:aPointC[P_Y]
   LOCAL aStruTbl, i, aAttr, nBorder, nBorder0, nBColor, nBColor0, nWidth, nAlign
   LOCAL cClsName, arr := { "Left", "Center", "Right" }
   LOCAL bClr := { ||
     LOCAL nColor
     IF ( nColor := Hwg_ChooseColor( nBColor ) ) != Nil
        nBColor := nColor
        oSayClr:SetText( Iif( nBColor==0,"Default","#"+hwg_ColorN2C(nBColor) ) )
     ENDIF
     RETURN .T.
   }

   MEMVAR tColor, bColor, tc, tb, aComboFam, cFamily, nFamily
   MEMVAR nSize, nsb, nfb
   MEMVAR lb, li, lu, ls, lbb, lib, lub, lsb
   PRIVATE tColor := oEdit:tColor, bColor := oEdit:bColor, tc, tb
   PRIVATE aComboFam := Asort( hwg_getFontsList() ), cFamily := "", nFamily := 1
   PRIVATE nSize := Ascan( oComboSiz:aItems,cComboSizDef ), nsb, nfb
   PRIVATE lb := .F., li := .F., lu := .F., ls := .F., lbb, lib, lub, lsb

   IF Len( oEdit:GetPosInfo() ) < 7 .OR. oEdit:aStru[nL,1,OB_TRNUM] > 1
      RETURN Nil
   ENDIF

   aStruTbl := oEdit:aStru[nL,1,OB_TBL]
   IF Len( aStruTbl[OB_OB] ) > 1
      RETURN Nil
   ENDIF
   IF nL+1 <= oEdit:nTextLen .AND. Valtype(oEdit:aStru[nL+1,1,1]) == "C" .AND. oEdit:aStru[nL+1,1,1] == "tr"
      RETURN Nil
   ENDIF

   IF !Empty( cClsName := aStruTbl[OB_CLS] )
      aAttr := oEdit:getClassAttr( cClsName )
      IF ( i := Ascan( aAttr, "bw" ) ) != 0
         nBorder := nBorder0 := Val( SubStr( aAttr[i],3 ) )
      ENDIF
      IF ( i := Ascan( aAttr, "bc" ) ) != 0
         nBColor := nBColor0 := Val( SubStr( aAttr[i],3 ) )
      ENDIF
   ENDIF
   nWidth := Iif( Empty(aStruTbl[OB_TWIDTH]), 100, Abs(aStruTbl[OB_TWIDTH]) )
   nAlign := aStruTbl[OB_TALIGN] + 1

   nTop := GetVal_nTop()

   INIT DIALOG oDlg TITLE "Set block"  ;
      AT 20, 30 SIZE 460, 460 FONT HWindow():GetMain():oFont

   @ 10, 10 TAB oTab ITEMS {} SIZE 440,380 ;
         ON SIZE ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_BOTTOMABS+ANCHOR_RIGHTABS

   BEGIN PAGE "Main" of oTab

   @ 10, nTop+40 SAY "Width,%" SIZE 96, 22 TRANSPARENT
   @ 106,nTop+40 GET UPDOWN nWidth RANGE 10, 100 SIZE 80, 30 STYLE WS_BORDER

   @ 210,nTop+40 SAY "Align:" SIZE 96, 22 TRANSPARENT
   @ 306,nTop+40 GET COMBOBOX nAlign ITEMS arr SIZE 100, 26 DISPLAYCOUNT 3

   @ 10,nTop+80 GROUPBOX "Border" SIZE 420, 80
   @ 20,nTop+106 SAY "Width:" SIZE 100, 24 TRANSPARENT
   @ 140,nTop+100 GET UPDOWN nBorder RANGE 0, 8 SIZE 60, 30
   @ 220,nTop+100  BUTTON "Color" SIZE 80, 30 ON CLICK bClr
   @ 320,nTop+104 SAY oSayClr CAPTION Iif( nBColor==0,"Default","#"+hwg_ColorN2C(nBColor) ) SIZE 90, 24 STYLE WS_BORDER BACKCOLOR 16777215

   END PAGE of oTab

   textTab( oTab, aAttr )

   @ 80, 410 BUTTON "Ok" ID IDOK SIZE 100, 32 ON SIZE ANCHOR_LEFTABS+ANCHOR_BOTTOMABS
   @ 260,410 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ON SIZE ANCHOR_BOTTOMABS+ANCHOR_RIGHTABS

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      oEdit:lSetFocus := .T.
      IF aStruTbl[OB_TWIDTH] != - nWidth
         aStruTbl[OB_TWIDTH] := - nWidth
         oEdit:lUpdated := .T.
      ENDIF
      IF aStruTbl[OB_TALIGN] != nAlign - 1
         aStruTbl[OB_TALIGN] := nAlign - 1
         oEdit:lUpdated := .T.
      ENDIF
      IF ( i := Ascan( aAttr, "bw" ) ) != 0
         aAttr[i] := "bw" + Ltrim(Str(nBorder))
      ELSE
         AAdd( aAttr, "bw" + LTrim(Str(nBorder)) )
      ENDIF
      IF ( i := Ascan( aAttr, "bc" ) ) != 0
         aAttr[i] := "bc" + Ltrim(Str(nBColor))
      ELSE
         AAdd( aAttr, "bc" + LTrim(Str(nBColor)) )
      ENDIF
      text2attr( aAttr )
      aStruTbl[OB_CLS] := oEdit:FindClass( , aAttr, .T. )
      oEdit:lUpdated := .T.
      oEdit:Scan( oEdit:aPointC[P_Y] )
      oEdit:Paint( .F. )
      hced_Invalidaterect( oEdit:hEdit, 0, 0, 0, oEdit:nClientWidth, oEdit:nHeight )
   ENDIF

   RETURN Nil

STATIC FUNCTION setTable( lNew )
   LOCAL oDlg, oTab, nTop, oSayClr, nRows := 3, nCols := 2, nBorder := 1, nBColor := 0, nWidth := 100
   LOCAL arr := { "Left", "Center", "Right" }, nAlign := 1, cClsName, aAttr, lNeedScan := .F.
   LOCAL nRows0, nBorder0 := 0, nBColor0 := 0
   LOCAL oBrw, aCols, nAll
   LOCAL nL := oEdit:aPointC[P_Y], nLast
   LOCAL aStruTbl, i
   LOCAL bClr := { ||
     LOCAL nColor
     IF ( nColor := Hwg_ChooseColor( nBColor ) ) != Nil
        nBColor := nColor
        oSayClr:SetText( Iif( nBColor==0,"Default","#"+hwg_ColorN2C(nBColor) ) )
     ENDIF
     RETURN .T.
   }
   LOCAL bChgTab := {|o,n|
      IF n == 2 .AND. Len( aCols ) != nCols
         IF lNew
            aCols := Array( nCols )
            nAll := 0
            FOR i := 1 TO Len( aCols )
               aCols[i] := Int( 100/Len(aCols) )
               nAll += aCols[i]
            NEXT
            aCols[1] += ( 100 - nAll )
            oBrw:aArray := aCols
         ENDIF
      ENDIF
      RETURN .T.
   }
   LOCAL bValid := {|n|
      LOCAL nOld := aCols[oBrw:nCurrent]
      IF n != nOld
         aCols[oBrw:nCurrent] := n
         n -= nOld
         FOR i := 1 TO Len(aCols)
            IF i != oBrw:nCurrent
               aCols[i] -= n
               IF aCols[i] <= 0
                  n := 1 + aCols[i]
                  aCols[i] := 1
               ELSE
                  EXIT
               ENDIF
            ENDIF
         NEXT
         HTimer():New( oDlg,, 150, {||oBrw:Refresh()}, .T. )
      ENDIF
      RETURN .T.
   }

   MEMVAR tColor, bColor, tc, tb, aComboFam, cFamily, nFamily
   MEMVAR nSize, nsb, nfb
   MEMVAR lb, li, lu, ls, lbb, lib, lub, lsb
   PRIVATE tColor := oEdit:tColor, bColor := oEdit:bColor, tc, tb
   PRIVATE aComboFam := Asort( hwg_getFontsList() ), cFamily := "", nFamily := 1
   PRIVATE nSize := Ascan( oComboSiz:aItems,cComboSizDef ), nsb, nfb
   PRIVATE lb := .F., li := .F., lu := .F., ls := .F., lbb, lib, lub, lsb

   nTop := GetVal_nTop()

   IF lNew == ( Valtype(oEdit:aStru[nL,1,OB_TYPE]) == "C" .AND. oEdit:aStru[nL,1,OB_TYPE] == "tr" )
      RETURN Nil
   ENDIF

   IF lNew
      aCols := Array( nCols )
      nAll := 0
      FOR i := 1 TO Len( aCols )
         aCols[i] := Int( 100/Len(aCols) )
         nAll += aCols[i]
      NEXT
      aCols[1] += ( 100 - nAll )
   ELSE
      nRows := oEdit:aStru[nL,1,OB_TRNUM]
      aStruTbl := oEdit:aStru[nL-nRows+1,1,OB_TBL]
      IF !Empty( cClsName := aStruTbl[OB_CLS] )
         aAttr := oEdit:getClassAttr( cClsName )
         IF ( i := Ascan( aAttr, "bw" ) ) != 0
            nBorder := nBorder0 := Val( SubStr( aAttr[i],3 ) )
         ENDIF
         IF ( i := Ascan( aAttr, "bc" ) ) != 0
            nBColor := nBColor0 := Val( SubStr( aAttr[i],3 ) )
         ENDIF
      ENDIF

      i := 1
      DO WHILE nL+i <= oEdit:nTextLen .AND. Valtype(oEdit:aStru[nL+i,1,1]) == "C" .AND. ;
         oEdit:aStru[nL+i,1,OB_TYPE] == "tr" .AND. Len( oEdit:aStru[nL+i,1] ) < OB_TBL
         i ++
         nRows ++
      ENDDO
      nRows0 := nRows
      nCols := Len( aStruTbl[OB_OB] )
      nWidth := Iif( Empty(aStruTbl[OB_TWIDTH]), 100, Abs(aStruTbl[OB_TWIDTH]) )
      nAlign := aStruTbl[OB_TALIGN] + 1
      aCols := Array( nCols )
      FOR i := 1 TO Len( aCols )
         aCols[i] := Int( Abs( aStruTbl[OB_OB,i,1] ) )
      NEXT
   ENDIF

   INIT DIALOG oDlg TITLE Iif( lNew, "Insert", "Set" ) + " table"  ;
      AT 20, 30 SIZE 460, 460 FONT HWindow():GetMain():oFont

   @ 10, 10 TAB oTab ITEMS {} SIZE 440,380 ON CHANGE bChgTab ;
         ON SIZE ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_BOTTOMABS+ANCHOR_RIGHTABS

   BEGIN PAGE "Main" of oTab

   @ 10, nTop SAY "Rows:" SIZE 96, 22 TRANSPARENT
   @ 106, nTop GET UPDOWN nRows RANGE 1, 100 SIZE 50, 30 STYLE WS_BORDER

   @ 210, nTop SAY "Columns:" SIZE 96, 22 TRANSPARENT
   @ 306, nTop GET UPDOWN nCols RANGE 1, 24 SIZE 50, 30 STYLE WS_BORDER

   @ 10, nTop+40 SAY "Width,%" SIZE 96, 22 TRANSPARENT
   @ 106,nTop+40 GET UPDOWN nWidth RANGE 10, 100 SIZE 80, 30 STYLE WS_BORDER

   @ 210,nTop+40 SAY "Align:" SIZE 96, 22 TRANSPARENT
   @ 306,nTop+40 GET COMBOBOX nAlign ITEMS arr SIZE 100, 26 DISPLAYCOUNT 3

   @ 10,nTop+80 GROUPBOX "Border" SIZE 420, 80
   @ 20,nTop+106 SAY "Width:" SIZE 100, 24 TRANSPARENT
   @ 140,nTop+100 GET UPDOWN nBorder RANGE 0, 8 SIZE 60, 30
   @ 220,nTop+100  BUTTON "Color" SIZE 80, 30 ON CLICK bClr
   @ 320,nTop+104 SAY oSayClr CAPTION Iif( nBColor==0,"Default","#"+hwg_ColorN2C(nBColor) ) SIZE 90, 24 STYLE WS_BORDER BACKCOLOR 16777215

   END PAGE of oTab

   BEGIN PAGE "Columns" of oTab

   @ 10, nTop BROWSE oBrw ARRAY SIZE 260, 160 ON SIZE {|o,x,y|o:Move(,,,y-70)}
   oBrw:aArray := aCols
   oBrw:AddColumn( HColumn():New( " Column N  ",{ |value,o| (value), o:nCurrent },"N",2 ) )
   oBrw:AddColumn( HColumn():New( "  Width, %",{ |value,o| (value), o:aArray[o:nCurrent] },"N",2 ) )
   oBrw:aColumns[2]:lEditable := .T.
   oBrw:aColumns[2]:bValid := bValid
   oBrw:aColumns[2]:picture := "99"

   END PAGE of oTab

   textTab( oTab, aAttr )

   @ 80, 410 BUTTON "Ok" ID IDOK SIZE 100, 32 ON SIZE ANCHOR_LEFTABS+ANCHOR_BOTTOMABS
   @ 260,410 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ON SIZE ANCHOR_BOTTOMABS+ANCHOR_RIGHTABS

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      oEdit:lSetFocus := .T.
      IF Len( aCols ) != nCols
         Eval( bChgTab, Nil, 2 )
      ENDIF
      FOR i := 1 TO Len( aCols )
         aCols[i] := - aCols[i]
      NEXT
      IF lNew
         aAttr := {}
         IF nBorder > 0 .OR. nBColor > 0
            IF nBorder > 0
               AAdd( aAttr, "bw" + LTrim( Str( nBorder ) ) )
            ENDIF
            IF nBColor > 0
               AAdd( aAttr, "bc" + LTrim( Str( nBColor ) ) )
            ENDIF
         ENDIF
         text2attr( aAttr )
         oEdit:InsTable( aCols, nRows, iif( nWidth == 100, Nil, - nWidth ), ;
            nAlign-1, aAttr )
      ELSE
         IF aStruTbl[OB_TWIDTH] != - nWidth
            aStruTbl[OB_TWIDTH] := - nWidth
            oEdit:lUpdated := .T.
         ENDIF
         IF aStruTbl[OB_TALIGN] != nAlign - 1
            aStruTbl[OB_TALIGN] := nAlign - 1
            oEdit:lUpdated := .T.
         ENDIF
         FOR i := 1 TO Len( aCols )
            IF aCols[i] != aStruTbl[OB_OB,i,1]
               aStruTbl[OB_OB,i,1] := aCols[i]
               oEdit:lUpdated := .T.
            ENDIF
         NEXT
         nLast := nL - oEdit:aStru[nL,1,OB_TRNUM] + nRows0
         IF nRows < nRows0
            IF nL > nLast - (nRows0-nRows)
               oEdit:aPointC[P_Y] := nLast - (nRows0-nRows)
            ENDIF
            FOR i := nLast TO nLast - (nRows0-nRows) + 1 STEP - 1
               oEdit:DelLine( i )
            NEXT
            lNeedScan := .T.
         ELSEIF nRows > nRows0
            oEdit:InsRows( nLast, nRows-nRows0 )
            lNeedScan := .T.
         ENDIF
         IF Empty( aAttr )
            aAttr := {}
            IF nBorder > 0
               AAdd( aAttr, "bw" + LTrim(Str(nBorder)) )
            ENDIF
            IF nBColor > 0
               AAdd( aAttr, "bc" + LTrim(Str(nBColor)) )
            ENDIF
         ELSE
            IF ( i := Ascan( aAttr, "bw" ) ) != 0
               aAttr[i] := "bw" + Ltrim(Str(nBorder))
            ELSE
               AAdd( aAttr, "bw" + LTrim(Str(nBorder)) )
            ENDIF
            IF ( i := Ascan( aAttr, "bc" ) ) != 0
               aAttr[i] := "bc" + Ltrim(Str(nBColor))
            ELSE
               AAdd( aAttr, "bc" + LTrim(Str(nBColor)) )
            ENDIF
         ENDIF
         text2attr( aAttr )
         aStruTbl[OB_CLS] := oEdit:FindClass( , aAttr, .T. )
         oEdit:lUpdated := .T.
         IF lNeedScan
            oEdit:Scan( oEdit:aPointC[P_Y] )
            oEdit:Paint( .F. )
            hced_Invalidaterect( oEdit:hEdit, 0, 0, 0, oEdit:nClientWidth, oEdit:nHeight )
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION setDoc()
   LOCAL oDlg, arr[6]
   LOCAL nFormat := oEdit:nDocFormat + 1, aCombo := { "Free", "A3", "A4", "A5", "A6" }
   LOCAL nOrient := oEdit:nDocOrient+1, nMargL, nMargR, nMargT, nMargB

   IF !Empty( oEdit:nKoeffScr )
      nMargL := oEdit:aDocMargins[1]
      nMargR := oEdit:aDocMargins[2]
      nMargT := oEdit:aDocMargins[3]
      nMargB := oEdit:aDocMargins[4]
   ELSE
      nMargL := nMargR := nMargT := nMargB := 0
   ENDIF
   arr[1] := nFormat; arr[2] := nOrient; arr[3] := nMargL; arr[4] := nMargR; arr[5] := nMargT; arr[6] := nMargB

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Document properties"  ;
      AT 210, 10  SIZE 440, 370 FONT HWindow():GetMain():oFont

   @ 20, 20 SAY "Size:" SIZE 100, 24
   @ 120, 16 GET COMBOBOX nFormat ITEMS aCombo SIZE 120, 150

   @ 20,60 GROUPBOX "Orientation" SIZE 200, 90

   GET RADIOGROUP nOrient
   @ 40,90 RADIOBUTTON "Portrait" SIZE 160, 22
   @ 40,114 RADIOBUTTON "Landscape" SIZE 160, 22
   END RADIOGROUP

   @ 20,170 GROUPBOX "Margins" SIZE 400, 120

   @ 40, 200 SAY "Left" SIZE 100, 24
   @ 140,200 GET UPDOWN nMargL RANGE 0,80 SIZE 60,30

   @ 240,200 SAY "Top" SIZE 100, 24
   @ 340,200 GET UPDOWN nMargT RANGE 0,80 SIZE 60,30

   @ 40, 240 SAY "Right" SIZE 100, 24
   @ 140,240 GET UPDOWN nMargR RANGE 0,80 SIZE 60,30

   @ 240,240 SAY "Bottom" SIZE 100, 24
   @ 340,240 GET UPDOWN nMargB RANGE 0,80 SIZE 60,30

   @  20, 320  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 220, 320 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult .AND. ( arr[1] != nFormat .OR. arr[2] != nOrient .OR. ;
         arr[3] != nMargL .OR. arr[4] != nMargR .OR.arr[5] != nMargT .OR.arr[6] != nMargB )
      IF ( oEdit:nDocFormat := nFormat - 1 ) > 0
         oEdit:nBoundL := DOC_BOUNDL
         oEdit:nDocOrient := nOrient - 1
         oEdit:aDocMargins[1] := nMargL
         oEdit:aDocMargins[2] := nMargR
         oEdit:aDocMargins[3] := nMargT
         oEdit:aDocMargins[4] := nMargB
         oEdit:nMarginL := Round( nMargL*oEdit:nKoeffScr,0 )
         oEdit:nMarginR := Round( nMargR*oEdit:nKoeffScr,0 )
         oEdit:nMarginT := Round( nMargT*oEdit:nKoeffScr,0 )
         oEdit:nMarginB := Round( nMargB*oEdit:nKoeffScr,0 )
      ELSE
         oEdit:nBoundL := FREE_BOUNDL
         oEdit:nDocOrient := oEdit:nMarginL := oEdit:nMarginR := oEdit:nMarginT := oEdit:nMarginB := 0
      ENDIF

      oEdit:Scan()
      oEdit:nWCharF := oEdit:nWSublF := 1
      oEdit:Paint( .F. )
      oEdit:SetCaretPos()
      hced_Invalidaterect( oEdit:hEdit, 0, 0, 0, oEdit:nClientWidth, oEdit:nHeight )
      RETURN .T.
   ENDIF

   RETURN .F.

STATIC FUNCTION setAccess( n, lSpan )

   LOCAL nL, aStru, arr1, nOpt := 0, l

   IF Len( arr1 := oEdit:GetPosInfo() ) >= 7
      oEdit:LoadEnv( arr1[1], arr1[2] )
      nl := arr1[4]
   ELSE
      nL := oEdit:aPointC[P_Y]
   ENDIF
   aStru := oEdit:aStru[nL]

   nOpt := hced_getAccInfo( oEdit, oEdit:aPointC, Iif( Empty(lSpan), 0, 1 ) )
   IF nOpt == Nil
      nOpt := 0
   ENDIF

   IF Empty( lSpan )
      l := !hwg_CheckBit( nOpt, n+1 )
      hwg_Checkmenuitem( , MENU_PNOWR+n-1, l )
      alAcc[n] := l
      IF l
         nOpt := hb_BitSet( nOpt, n )
      ELSE
         nOpt := hb_BitReset( nOpt, n )
      ENDIF
   ELSE
      IF n == 0
      ENDIF
      l := !hwg_CheckBit( nOpt, n+1 )
      hwg_Checkmenuitem( , MENU_SNOWR+n-1, l )
      alAcc[Iif(n==0,7,n+3)] := l
      IF l
         nOpt := hb_BitSet( nOpt, n )
      ELSE
         nOpt := hb_BitReset( nOpt, n )
      ENDIF
   ENDIF

   hced_setAccInfo( oEdit, oEdit:aPointC, Iif( Empty(lSpan), 0, 1 ), nOpt )

   IF Len( arr1 ) >= 7
      oEdit:RestoreEnv( arr1[1], arr1[2] )
   ENDIF

   RETURN Nil

STATIC FUNCTION SetText( oEd, cText )
   LOCAL aText, i, nLen
   LOCAL nPos1, nPos2

   IF ( nPos1 := At( Chr(10 ), cText ) ) == 0
      aText := hb_aTokens( cText, Chr( 13 ) )
   ELSEIF SubStr( cText, nPos1 - 1, 1 ) == Chr( 13 )
      aText := hb_aTokens( cText, cNewLine )
   ELSE
      aText := hb_aTokens( cText, Chr( 10 ) )
   ENDIF
   oEd:aStru := Array( Len( aText ) )

   FOR i := 1 TO Len( aText )
      oEd:aStru[i] := { { 0,0,Nil } }
      nLen := Len( aText[i] )
      nPos2 := 1
      DO WHILE ( nPos1 := hb_At( "://", aText[i], nPos2 ) ) != 0
         DO WHILE -- nPos1 > 0 .AND. IsAlpha( SubStr( aText[i], nPos1, 1 ) ); ENDDO
         nPos1 ++
         nPos2 := nPos1
         DO WHILE ++ nPos2 <= nLen .AND. !( SubStr( aText[i], nPos2, 1 ) == " " ); ENDDO
         nPos2 --
         IF SubStr( aText[i], nPos2 - 1, 1 ) $ ",.;"
            nPos2 --
         ENDIF
         AAdd( oEd:aStru[i], { nPos1, nPos2, "url", SubStr( aText[i],nPos1,nPos2 - nPos1 + 1 ) } )
      ENDDO
   NEXT

   RETURN aText

STATIC FUNCTION SetCpDef( cpSou )

   IF hwg__isUnicode()
      hb_cdpSelect( cpDef := "UTF8" )
   ELSE
      IF Empty( cpSou )
         hb_cdpSelect( cpDef )
      ELSEIF Left( cpSou, 2 ) == "RU"
         hb_cdpSelect( cpDef := "RU1251" )
      ELSE
         hb_cdpSelect( cpDef := "DEWIN" )
      ENDIF
   ENDIF
   RETURN cpDef

STATIC FUNCTION SetFont()

   LOCAL oFont := HFont():Select( oFontMain )

   IF !Empty( oFont )
      oFontMain := oFont
      lOptChg := .T.
      oEdit:SetFont( oFont )
   ENDIF

   RETURN Nil

STATIC FUNCTION InsUrl( nType )
   LOCAL oDlg, cHref := "", cName := "", aPos, xAttr
   LOCAL aRefs, nref
   LOCAL oProto, aProto := { "http", "https", "ftp", "goto" }, cProto := aProto[1]

   aPos := oEdit:GetPosInfo()
   IF aPos != Nil .AND. aPos[3] != Nil .AND. Len( aPos[3] ) >= OB_HREF
      hwg_msgStop( "Can't insert URL into existing one" )
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Insert URL"  ;
      AT 210, 10  SIZE 400, 190 FONT HWindow():GetMain():oFont ;
      ON INIT {||Iif(nType==2,oProto:Disable(),.t.)}

   IF nType == 2
      nref := Ascan( aProto, "goto" )
      cProto := aProto[nref]
   ENDIF

   @ 20, 10 SAY "Href:" SIZE 120, 22
   @ 10, 32 GET COMBOBOX oProto VAR cProto ITEMS aProto SIZE 90, 26 EDIT
   @ 100,34 SAY "://" SIZE 40, 22

   IF nType == 1
      @ 140, 32 GET cHref SIZE 250, 26 STYLE ES_AUTOHSCROLL MAXLENGTH 0
   ELSE
      IF !Empty( aRefs := oEdit:Find( ,"",, .T. ) )
         FOR nref := 1 TO Len( aRefs )
            IF Len( aRefs[nref] ) == 2
               aRefs[nref,1] := oEdit:aStru[aRefs[nref,2],aRefs[nref,1],OB_ID]
            ELSE
               aRefs[nref,1] := ""
            ENDIF
         NEXT
      ENDIF
      nref := 1
      @ 140, 32 GET COMBOBOX nref ITEMS aRefs SIZE 150, 26
   ENDIF
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 20, 70 SAY "Name:" SIZE 120, 22
   @ 10, 92 GET cName SIZE 380, 26 STYLE ES_AUTOHSCROLL MAXLENGTH 0 ;
        ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @  20, 140 BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 240, 140 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF ( ( nType == 1 .AND. !Empty( cHref ) ) .OR. ( nType == 2 .AND. !Empty(aRefs) ) ) .AND. !Empty( cName )
         IF !Empty( aRefs )
            cHref := "goto://#" + aRefs[nref,1]
         ELSEIF !Empty( cHref )
            cHRef := cProto + "://" + Iif( cProto=="goto".AND.Left(cHRef,1)!="#", "#", "" ) + cHref
         ENDIF
         xAttr := oEdit:getClassAttr( "url" )
         oEdit:InsSpan( cName, xAttr, cHref )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION setImage( lNew )

   LOCAL oDlg, oGet1, arr1, nL, aStru, cClsName, aAttr, fname, nb0, i, cName, cBin, nImage := 0
   LOCAL arr := { "Left", "Center", "Right" }, nAlign := 1, lEmbed := .T., nBorder := 0
   LOCAL bClick1 := {||
      LOCAL cfname
      IF Empty( cfname := hwg_Selectfile( "Graphic files( *.jpg;*.png;*.gif;*.bmp )", "*.jpg;*.png;*.gif;*.bmp", "" ) )
         RETURN .F.
      ELSE
         oGet1:value := fname := cfname
      ENDIF
      RETURN .T.
   }
   LOCAL bClick2 := {||
      IF !Empty( nImage := selectImage() )
         oGet1:value := fname := "#" + oEdit:aBin[nImage,1]
      ENDIF
      RETURN .T.
   }

   IF Len( arr1 := oEdit:GetPosInfo() ) >= 7
      nL := arr1[4]
      aStru := arr1[7]
   ELSE
      nL := arr1[1]
      aStru := oEdit:aStru[nL]
   ENDIF

   IF lNew == ( Valtype(aStru[1,OB_TYPE]) == "C" .AND. aStru[1,OB_TYPE] == "img" )
      RETURN Nil
   ENDIF

   IF !lNew
      lEmbed := ( Left( aStru[1,OB_HREF], 1 ) == "#" )
      nAlign := aStru[1,OB_IALIGN] + 1
      IF !Empty( cClsName := aStru[1,OB_CLS] )
         aAttr := oEdit:getClassAttr( cClsName )
         IF ( i := Ascan( aAttr, "bw" ) ) != 0
            nBorder := Val( SubStr( aAttr[i],3 ) )
         ENDIF
      ENDIF
   ENDIF
   nb0 := nBorder

   INIT DIALOG oDlg TITLE Iif( lNew, "Insert image", "Set image properties" )  ;
      AT 20, 30 SIZE 480, 260 FONT HWindow():GetMain():oFont

   IF lNew
      @ 20, 10 GET oGet1 VAR fname SIZE 280, 26 STYLE ES_AUTOHSCROLL MAXLENGTH 0 ;
           ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS
      @ 300,10 BUTTON "File" SIZE 60, 32 ON CLICK bClick1 ON SIZE ANCHOR_TOPABS + ANCHOR_RIGHTABS
      @ 360,10 BUTTON "Embedded" SIZE 100, 32 ON CLICK bClick2 ON SIZE ANCHOR_TOPABS + ANCHOR_RIGHTABS
   ENDIF

   @ 20, 50 GET CHECKBOX lEmbed CAPTION "Keep an image embedded in the document ?" SIZE 440, 24

   @ 20, 90 SAY "Align:" SIZE 96, 22
   @ 116, 90 GET COMBOBOX nAlign ITEMS arr SIZE 100, 26 DISPLAYCOUNT 3

   @ 20, 130 SAY "Border:" SIZE 96, 22
   @ 116, 130 GET UPDOWN nBorder RANGE 0, 4 SIZE 50, 30 STYLE WS_BORDER

   @ 80, 202 BUTTON "Ok" ID IDOK  SIZE 100, 32 ON SIZE ANCHOR_BOTTOMABS
   @ 300, 202 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32 ON SIZE ANCHOR_BOTTOMABS + ANCHOR_RIGHTABS

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      IF lNew
         IF !Empty( fname )
            IF nImage > 0 .AND. Left( fname,1 ) == "#"
               oEdit:InsImage( , nAlign-1, Iif( nBorder>0,"bw" + LTrim(Str(nBorder)),Nil ), oEdit:aBin[nImage,2] )
            ELSEIF lEmbed
               oEdit:InsImage( , nAlign-1, Iif( nBorder>0,"bw" + LTrim(Str(nBorder)),Nil ), MemoRead(fname), Lower(hb_FNameExt(fname)) )
            ELSE
               oEdit:InsImage( fname, nAlign-1, Iif( nBorder>0,"bw" + LTrim(Str(nBorder)),Nil ) )
            ENDIF
         ENDIF
      ELSEIF lEmbed != ( Left( aStru[1,OB_HREF], 1 ) == "#" ) .OR. ;
            nAlign != (aStru[1,OB_IALIGN] + 1) .OR. nBorder != nb0
         aStru[1,OB_IALIGN] := nAlign - 1
         IF nBorder != nb0
            aStru[1,OB_CLS] := oEdit:FindClass( cClsName, { "bw" + LTrim(Str(nBorder)) }, .T. )
         ENDIF
         IF lEmbed != ( Left( aStru[1,OB_HREF], 1 ) == "#" )
            IF lEmbed
               cName := aStru[1,OB_HREF]
               IF !Empty( cBin := MemoRead( cName ) )
                  IF ( i := Ascan( oEdit:aBin, {|a|a[2]==cBin} ) ) > 0
                     aStru[1,OB_HREF] := "#" + oEdit:aBin[i,1]
                  ELSE
                     i := 1
                     DO WHILE !Empty( cName := "img_"+Ltrim(Str(i)) ) .AND. Ascan( oEdit:aBin, {|a|a[1]==cName} ) != 0
                        i ++
                     ENDDO
                     Aadd( oEdit:aBin, { cName, cBin, aStru[1,OB_OB] } )
                  ENDIF
               ENDIF
            ELSE
               cName := Substr( aStru[1,OB_HREF], 2 )
               IF ( i := Ascan( oEdit:aBin, {|a|a[1]==cName} ) ) > 0
                  hb_MemoWrit( cName, oEdit:aBin[i,2] )
                  aStru[1,OB_HREF] := cName
               ENDIF
            ENDIF
         ENDIF
         oEdit:lUpdated := .T.
      ENDIF
   ENDIF
   hwg_Setfocus( oEdit:handle )

   RETURN Nil

STATIC FUNCTION selectImage()

   LOCAL oDlg, oBrw, oPanel
   LOCAL bPaint := {|o|
      LOCAL pps := hwg_Definepaintstru(), hDC := hwg_Beginpaint( o:handle, pps ), aCoors := hwg_Getclientrect( o:handle )
      LOCAL oImg := oBrw:aArray[oBrw:nCurrent,3], nWidth, nHeight

      nWidth := Iif( oImg:nWidth > oPanel:nWidth-8, oPanel:nWidth-8, oImg:nWidth )
      nHeight := Int( oImg:nHeight * ( nWidth/oImg:nWidth ) )
      IF  nHeight > oPanel:nHeight-8
         nHeight := oPanel:nHeight-8
         nWidth := Int( oImg:nWidth * ( nHeight/oImg:nHeight ) )
      ENDIF
      hwg_drawGradient( hDC, 0, 0, aCoors[3], aCoors[4], 1, { CLR_GRAY1, CLR_GRAY2 } )
      hwg_Drawbitmap( hDC, oImg:handle,, (oPanel:nWidth-nWidth)/2, (oPanel:nHeight-nHeight)/2, nWidth, nHeight )
      hwg_Endpaint( o:handle, pps )
      RETURN Nil
   }

   IF Empty( oEdit:aBin )
      RETURN 0
   ENDIF

   INIT DIALOG oDlg TITLE "Select image"  ;
      AT 20, 30 SIZE 400, 260 FONT HWindow():GetMain():oFont

   @ 0, 0 BROWSE oBrw ARRAY SIZE 200, oDlg:nHeight - 60 ON SIZE {|o,x,y| (x), o:Move( ,,, y-60)}
   @ 200, 0 PANEL oPanel SIZE 200, oDlg:nHeight - 60 STYLE SS_OWNERDRAW ;
      ON PAINT bPaint ON SIZE {|o,x,y|o:Move( ,, x-o:nLeft, y-60)}
   oBrw:aArray := oEdit:aBin
   oBrw:AddColumn( HColumn():New( ,{ |value,o| (value), o:aArray[o:nCurrent,1] },"C",32 ) )
   oBrw:bcolorSel := oBrw:htbColor := CLR_LBLUE
   oBrw:bColor := CLR_LIGHT1
   oBrw:tcolorSel := oBrw:httColor := CLR_BLACK
   oBrw:tcolor := CLR_BLACK
   oBrw:bPosChanged := {||hwg_Invalidaterect(oPanel:handle,0,0,0,oPanel:nWidth,oPanel:nHeight)}

   @ 32, 210 BUTTON "Ok" ID IDOK  SIZE 90, 32 ON SIZE ANCHOR_BOTTOMABS
   @ 276, 210 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32 ON SIZE ANCHOR_BOTTOMABS + ANCHOR_RIGHTABS

   ACTIVATE DIALOG oDlg CENTER

   IF oDlg:lResult
      RETURN oBrw:nCurrent
   ENDIF

   RETURN 0

STATIC FUNCTION InsRows()
   LOCAL nL := oEdit:aPointC[P_Y], oDlg, nRows := 1

   IF Valtype(oEdit:aStru[nL,1,1]) != "C" .OR. oEdit:aStru[nL,1,1] != "tr"
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg TITLE "Insert rows"  ;
      AT 20, 30 SIZE 200, 150 FONT HWindow():GetMain():oFont

   @ 20, 20 SAY "Rows:" SIZE 100, 22
   @ 120, 20 GET UPDOWN nRows RANGE 1, 100 SIZE 50, 30 STYLE WS_BORDER

   @ 10, 100 BUTTON "Ok" ID IDOK  SIZE 80, 32
   @ 110, 100 BUTTON "Cancel" ID IDCANCEL  SIZE 80, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      oEdit:InsRows( nL, nRows )
      hced_Invalidaterect( oEdit:hEdit, 0, 0, 0, oEdit:nClientWidth, oEdit:nHeight )
   ENDIF

   RETURN Nil

STATIC FUNCTION DelRow()

   LOCAL nL := oEdit:aPointC[P_Y]

   oEdit:DelRow( nL )
   oEdit:Scan( nL )
   oEdit:Paint( .F. )
   onChangePos()
   hced_Invalidaterect( oEdit:hEdit, 0, 0, 0, oEdit:nClientWidth, oEdit:nHeight )

   RETURN Nil

STATIC FUNCTION InsCols( l2End )

   LOCAL nL := oEdit:aPointC[P_Y]

   IF Valtype(oEdit:aStru[nL,1,1]) != "C" .OR. oEdit:aStru[nL,1,1] != "tr"
      RETURN Nil
   ENDIF

   oEdit:InsCol( nL, Iif( l2End, Nil, oEdit:aPointC[P_X] ) )
   oEdit:Scan()
   oEdit:Paint( .F. )
   hced_Invalidaterect( oEdit:hEdit, 0, 0, 0, oEdit:nClientWidth, oEdit:nHeight )
   hwg_Setfocus( oEdit:handle )

   RETURN Nil

STATIC FUNCTION DelCol()

   LOCAL nL := oEdit:aPointC[P_Y]

   IF Valtype(oEdit:aStru[nL,1,1]) != "C" .OR. oEdit:aStru[nL,1,1] != "tr"
      RETURN Nil
   ENDIF

   oEdit:DelCol( nL, oEdit:aPointC[P_X] )
   oEdit:Scan()
   oEdit:Paint( .F. )
   hced_Invalidaterect( oEdit:hEdit, 0, 0, 0, oEdit:nClientWidth, oEdit:nHeight )
   hwg_Setfocus( oEdit:handle )

   RETURN Nil

STATIC FUNCTION EditMessProc( o, msg, wParam, lParam )
   LOCAL arr
   STATIC nShiftL := 0

   nLastMsg  := msg
   nLastWpar := hwg_PtrToUlong( wParam )
   IF msg == WM_LBUTTONDBLCLK
      IF !Empty( arr := o:GetPosInfo( hwg_LoWord(lParam ), hwg_HiWord(lParam ) ) ) .AND. ;
            !Empty( arr[3] ) .AND. Len( arr[3] ) >= OB_HREF
         hwg_SetCursor( handCursor )
         IF hwg_CheckBit( arr[3,OB_ACCESS], BIT_CLCSCR )
            EditScr( oEdit, arr[3] )
         ELSE
            UrlLaunch( o, arr[3,OB_HREF] )
         ENDIF
      ENDIF
      RETURN 0

   ELSEIF msg == WM_MOUSEMOVE .OR. msg == WM_LBUTTONDOWN
      IF !Empty( arr := o:GetPosInfo( hwg_LoWord(lParam ), hwg_HiWord(lParam ) ) ) .AND. ;
            !Empty( arr[3] ) .AND. Len( arr[3] ) >= OB_HREF
         hwg_SetCursor( handCursor )
      ENDIF

   ELSEIF msg == WM_RBUTTONDOWN

   ENDIF

   IF nShiftL != o:nShiftL
      nShiftL := o:nShiftL
      hwg_Redrawwindow( oRuler:handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

   RETURN - 1

STATIC FUNCTION EdMsgAfter( o, msg, wParam, lParam )

   LOCAL nKey, cLine, nPos, nPos1, arr, l1 := .F., l2 := .F., nLen
   LOCAL lUrl := .F., lSpan, lInTable

   IF msg == WM_KEYDOWN

      nKey := hwg_PtrToUlong( wParam )
      IF nKey == VK_UP .OR. nKey == VK_DOWN .OR. nKey == VK_NEXT .OR. nKey == VK_PRIOR
         MarkRow( 1 )
      ENDIF

   ELSEIF msg == WM_RBUTTONDOWN .OR. msg == WM_LBUTTONDOWN

      MarkRow( 0 )

   ENDIF
   (o) // -w3 -es2

   RETURN -1

STATIC FUNCTION UrlLaunch( oEdi, cAddr )

   LOCAL arrf
   IF Lower( Left( cAddr, 4 ) ) == "http"
      IF !Empty( cWebBrow )
         hwg_RunApp( cWebBrow + " " + cAddr )
      ELSE
#ifdef __PLATFORM__WINDOWS
         hwg_Shellexecute( cAddr )
#endif
      ENDIF
   ELSEIF Lower( Left( cAddr, 8 ) ) == "goto://#"
      IF !Empty( arrf := oEdi:Find( ,Substr( cAddr,9 ) ) )
         oEdi:Goto( arrf[2] )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION Find()

   LOCAL oDlg, oGet

   INIT DIALOG oDlg TITLE "Find" AT 0, 0 SIZE 400, 260 ;
      FONT HWindow():GetMain():oFont

   @ 10, 20 SAY "String:" SIZE 80, 24 STYLE SS_RIGHT

   @ 90, 20 GET oGet VAR cSearch SIZE 300, 24 STYLE ES_AUTOHSCROLL MAXLENGTH 0 ;
         ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 20, 56 GET CHECKBOX lSeaCase CAPTION "Case sensitive" SIZE 180, 24
   @ 20, 80 GET CHECKBOX lSeaRegex CAPTION "Regular expression" SIZE 180, 24

   @  30, 220 BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 270, 220 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   ACTIVATE DIALOG oDlg CENTER

   IF oDlg:lResult
      IF !Empty( aPointFound := oEdit:Find( cSearch,,,, lSeaCase, lSeaRegex ) )
         hwg_Enablemenuitem( , MENU_FINDNEXT, .T., .T. )
         IF Len( aPointFound ) <= 3
            oEdit:PCopy( {aPointFound[1],aPointFound[2]}, oEdit:aPointM1 )
            oEdit:PCopy( {aPointFound[1]+Iif(lSeaRegex,aPointFound[3],hced_Len(oEdit,cSearch)),aPointFound[2]}, oEdit:aPointM2 )
            oEdit:PCopy( oEdit:aPointM1, oEdit:aPointC )
            oEdit:Goto( aPointFound[2] )
         ELSE
         ENDIF
      ENDIF
   ENDIF
   hwg_Setfocus( oEdit:handle )

   RETURN Nil

STATIC FUNCTION FindNext()

   IF !Empty( aPointFound )
      aPointFound[1] += hced_Len( oEdit,cSearch )
      IF !Empty( aPointFound := oEdit:Find( cSearch,,,aPointFound, lSeaCase, lSeaRegex ) )
         IF Len( aPointFound ) == 2
            oEdit:PCopy( {aPointFound[1],aPointFound[2]}, oEdit:aPointM1 )
            oEdit:PCopy( {aPointFound[1]+Iif(lSeaRegex,aPointFound[3],hced_Len(oEdit,cSearch)),aPointFound[2]}, oEdit:aPointM2 )
            oEdit:Goto( aPointFound[2] )
         ELSE
         ENDIF
      ELSE
         hwg_Enablemenuitem( , MENU_FINDNEXT, .F., .T. )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION CopyFormatted()

   LOCAL nL, nLTr, iTd

   nL := oEdit:aPointC[P_Y]
   IF Valtype( oEdit:aStru[nL,1,OB_TYPE] ) == "C" .AND. oEdit:aStru[nL,1,OB_TYPE] == "tr"
      nLTr := nL
      iTd := oEdit:nPosC
      oEdit:LoadEnv( nL, iTd )
   ENDIF
   IF !Empty( oEdit:aPointM2[P_Y] )
      cCBformatted := oEdit:Save( ,,, .T., oEdit:aPointM1, oEdit:aPointM2 )
      IF !Empty( cCBformatted )
         IF Asc( cCBformatted ) == 32
            cCBformatted := Ltrim( cCBformatted )
         ENDIF
         hwg_Copystringtoclipboard( cCBformatted )
         hwg_Enablemenuitem( , MENU_PASTEF, .T., .T. )
      ENDIF
   ENDIF
   IF !Empty( nLTr )
      oEdit:RestoreEnv( nLTr, iTd )
   ENDIF

   RETURN Nil

STATIC FUNCTION PasteFormatted()

   LOCAL nLines, nLineF, nLineC, nPosF, nPosC, nWCharF, nWSublF
   LOCAL nL, nLTr, iTd

   IF !Empty( cCBformatted )
      IF !Empty( oEdit )
         nL := oEdit:aPointC[P_Y]
         nLines := oEdit:nLines; nLineF := oEdit:nLineF; nLineC := oEdit:nLineC; nPosF := oEdit:nPosF; nPosC := oEdit:nPosC; nWCharF := oEdit:nWCharF; nWSublF := oEdit:nWSublF

         IF Valtype( oEdit:aStru[nL,1,OB_TYPE] ) == "C" .AND. oEdit:aStru[nL,1,OB_TYPE] == "tr"
            nLTr := nL
            iTd := oEdit:nPosC
            oEdit:LoadEnv( nL, iTd )
            nL := oEdit:aPointC[P_Y]
         ENDIF
         oEdit:SetText( cCBformatted,,, .T., .T., nL )
         IF !Empty( nLTr )
            oEdit:RestoreEnv( nLTr, iTd )
         ENDIF

         oEdit:nLines := nLines; oEdit:nLineF := nLineF; oEdit:nLineC := nLineC; oEdit:nPosF := nPosF; oEdit:nPosC := nPosC; oEdit:nWCharF := nWCharF; oEdit:nWSublF := nWSublF
         oEdit:PCopy( { nPosC, nLineC }, oEdit:aPointC )
         oEdit:SetCaretPos( SETC_XY )
         hwg_Setfocus( oEdit:handle )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION Zoom( n )

   LOCAL nHeight := oEdit:oFont:height

   nHeight := Iif( nHeight<0, nHeight-n, nHeight+n )
   oEdit:SetFont( HFont():Add( oEdit:oFont:name, oEdit:oFont:Width,nHeight,,oEdit:oFont:Charset,,,,,.T. ) )

   RETURN Nil

STATIC FUNCTION MarkRow( n )

   LOCAL nEnv := oEdit:getEnv(), nL, i, aStru, aPointM1, aPointM2, aText
   STATIC nRow1 := 0, nRow2 := 0

   IF nEnv > 0
      nL := Int( (nEnv - nEnv%256)/256 )
      aStru := oEdit:getEnv( OB_ASTRU ); aPointM1 := oEdit:getEnv( OB_APM1 ); aPointM2 := oEdit:getEnv( OB_APM2 )
   ELSE
      nL := oEdit:aPointC[P_Y]
      aStru := oEdit:aStru; aPointM1 := oEdit:aPointM1; aPointM2 := oEdit:aPointM2
   ENDIF
   IF n == Nil
      IF nRow1 == 0 .OR. ( nRow1 > 0 .AND. nRow2 > 0 )
         nRow1 := nL; nRow2 := 0
         aPointM1[P_Y] := nL; aPointM1[P_X] := 1
      ELSEIF nRow1 > 0 .AND. nRow2 == 0
         nRow2 := nL
         aPointM2[P_Y] := nL; aPointM2[P_X] := hced_Len( oEdit,oEdit:aText[nL] ) + 1
         IF Valtype( aStru[nL,1,OB_TYPE] ) != "N" .AND. aStru[nL,1,OB_TYPE] == "tr"
            aStru[nL,1,OB_OPT] := TROPT_SEL
         ENDIF
         hwg_Enablemenuitem( , MENU_COPYF, .T., .T. )
         oEdit:Refresh()
      ENDIF
   ELSEIF n == 0
      nRow1 := nRow2 := 0
   ELSEIF nRow1 > 0 .AND. nRow2 == 0
      IF nEnv > 0
         aPointM2[P_Y] := nL; aPointM2[P_X] := 2
         FOR i := nRow1 TO nL
            IF Valtype( aStru[i,1,OB_TYPE] ) != "N" .AND. aStru[i,1,OB_TYPE] == "tr"
               aStru[i,1,OB_OPT] := TROPT_SEL
            ENDIF
         NEXT
      ELSE
         aPointM2[P_Y] := nL; aPointM2[P_X] := hced_Len( oEdit,oEdit:aText[nL] ) + 1
         oEdit:Refresh()
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION CnvCase( nType )

   LOCAL arr1, nL1, nL2, i, nPos1, nPos2, nLen, cTemp
   LOCAL lUtf8 := oEdit:lUtf8, P1, P2

   IF Len( arr1 := oEdit:GetPosInfo() ) >= 7
      oEdit:LoadEnv( arr1[1], arr1[2] )
   ENDIF

   IF !Empty( oEdit:aPointM2[P_Y] )
      IF oEdit:aPointM2[P_Y] >= oEdit:aPointM1[P_Y]
         P1 := oEdit:aPointM1
         P2 := oEdit:aPointM2
      ELSE
         P2 := oEdit:aPointM1
         P1 := oEdit:aPointM2
      ENDIF
      nL1 := P1[P_Y]
      nL2 := P2[P_Y]
      FOR i := nL1 TO nL2
         nPos1 := Iif( i==nL1, P1[P_X], 1 )
         nLen := hced_Len( oEdit, oEdit:aText[i] )
         nPos2 := Iif( i==nL2, P2[P_X]-1, nLen )
         cTemp := hced_Substr( oEdit, oEdit:aText[i], nPos1, nPos2-nPos1+1 )
         IF nType == 1
            cTemp := Iif( lUtf8, edi_utf8_Upper( cTemp ), Upper( cTemp ) )
         ELSEIF nType == 2
            cTemp := Iif( lUtf8, edi_utf8_Lower( cTemp ), Lower( cTemp ) )
         ELSEIF nType == 3
            cTemp := Iif( lUtf8, edi_utf8_Upper(hb_utf8Left(cTemp,1)), Upper(Left(cTemp,1 )) ) + ;
               Iif( lUtf8, edi_utf8_Upper(hb_utf8Substr(cTemp,2)), Lower(Substr(cTemp,2)) )
         ENDIF
         oEdit:aText[i] := Iif( nPos1==1,"", hced_Left(oEdit,oEdit:aText[i],nPos1-1) ) + ;
            cTemp + Iif( nPos2==nLen, "", hced_Substr(oEdit,oEdit:aText[i],nPos2+1) )
      NEXT
      oEdit:lUpdated := .T.
      oEdit:Refresh()
   ENDIF

   IF Len( arr1 ) >= 7
      oEdit:RestoreEnv( arr1[1], arr1[2] )
   ENDIF

   RETURN Nil

FUNCTION Add2Recent( cFile )

   LOCAL i, j, cp := Iif( Empty(oEdit:cpSource), "", oEdit:cpSource )

   IF ( i := Ascan( aFilesRecent, {|a|a[1]==cFile} ) ) == 0
      IF Len( aFilesRecent ) < MAX_RECENT_FILES
         Aadd( aFilesRecent, Nil )
      ENDIF
      AIns( aFilesRecent, 1 )
      aFilesRecent[1] := { cFile, cp }
      lOptChg := .T.
   ELSEIF i > 1
      FOR j := i TO 2 STEP -1
         aFilesRecent[j] := aFilesRecent[j-1]
      NEXT
      aFilesRecent[1] := { cFile, cp }
      lOptChg := .T.
   ELSEIF !( aFilesRecent[1,2] == cp )
      aFilesRecent[1,2] := cp
      lOptChg := .T.
   ENDIF

   RETURN Nil

STATIC FUNCTION ReadIni( cPath )

   LOCAL oIni := HXMLDoc():Read( cPath + "editor.ini" )
   LOCAL oNode, i, j, xTemp

   IF !Empty( oIni ) .AND. !Empty( oIni:aItems )
      FOR i := 1 TO Len( oIni:aItems[1]:aItems )
         oNode := oIni:aItems[1]:aItems[i]
         IF oNode:title == "recent"
            FOR j := 1 TO Min( Len( oNode:aItems ), MAX_RECENT_FILES )
               Aadd( aFilesRecent, { Trim( oNode:aItems[j]:GetAttribute("name","C","") ), ;
                  Trim( oNode:aItems[j]:GetAttribute("cp","C","") ) } )
            NEXT
         ELSEIF oNode:title == "font"
            oFontMain := FontFromXML( oNode )
         ELSEIF oNode:title == "codepage"
            xTemp := oNode:GetAttribute( "main" )
            IF !Empty( xTemp ) .AND. hb_cdpExists( xTemp )
               cpDef := xTemp
            ENDIF
            xTemp := oNode:GetAttribute( "source" )
            IF !Empty( xTemp ) .AND. hb_cdpExists( xTemp )
               cpSource := xTemp
            ENDIF
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

STATIC FUNCTION WriteIni( cPath )

   LOCAL oIni := HXMLDoc():New()
   LOCAL oNode, oNodeR, i

   oIni:Add( oNode := HXMLNode():New( "init" ) )

   oNode:Add( FontToXML( oFontMain, "font" ) )
   oNode:Add(  HXMLNode():New( "codepage", HBXML_TYPE_SINGLE, { { "main", cpDef }, { "source", cpSource } } ) )

   oNodeR := oNode:Add( HXMLNode():New( "recent" ) )
   FOR i := 1 TO Len( aFilesRecent )
      oNodeR:Add( HXMLNode():New( "file", HBXML_TYPE_SINGLE, { { "name", aFilesRecent[i,1] }, { "cp", aFilesRecent[i,2] } } ) )
   NEXT

   oIni:Save( cPath + "editor.ini" )

   RETURN Nil

STATIC FUNCTION FontFromXML( oXmlNode )

   LOCAL width  := oXmlNode:GetAttribute( "width" )
   LOCAL height := oXmlNode:GetAttribute( "height" )
   LOCAL weight := oXmlNode:GetAttribute( "weight" )
   LOCAL charset := oXmlNode:GetAttribute( "charset" )
   LOCAL ita   := oXmlNode:GetAttribute( "italic" )
   LOCAL under := oXmlNode:GetAttribute( "underline" )

   IF width != Nil
      width := Val( width )
   ENDIF
   IF height != Nil
      height := Val( height )
   ENDIF
   IF weight != Nil
      weight := Val( weight )
   ENDIF
   IF charset != Nil
      charset := Val( charset )
   ENDIF
   IF ita != Nil
      ita := Val( ita )
   ENDIF
   IF under != Nil
      under := Val( under )
   ENDIF

   RETURN HFont():Add( oXmlNode:GetAttribute( "name" ),  ;
      width, height, weight, charset, ita, under,,,.T. )

STATIC FUNCTION FontToXML( oFont, cTitle )

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

   RETURN HXMLNode():New( cTitle, HBXML_TYPE_SINGLE, aAttr )

STATIC FUNCTION Help(cHTopic , nPROCLINE , cHVar)

   LOCAL oEdit
   STATIC oDlgHelp

   IF !Empty( oDlgHelp )
      hwg_SetFocus( oDlgHelp:handle )
      RETURN Nil
   ENDIF

   IF !File( cIniPath + "editor.hwge" )
      hwg_msgStop( "Help file editor.hwge not found" )
      RETURN Nil
   ENDIF

   INIT DIALOG oDlgHelp TITLE "Help" AT 100, 50 ;
         SIZE 400,400 FONT HWindow():GetMain():oFont ON EXIT {||oDlgHelp := Nil, .T.}
   oDlgHelp:brush := 0

   oEdit := HCEdiExt():New( ,,, 0, 0, oDlgHelp:nWidth, oDlgHelp:nHeight, ;
         HWindow():GetMain():oFont,, {|o,x,y|o:Move( ,,x,y ) } )

   oEdit:bColorCur := oEdit:bColor
   oEdit:AddClass( "url", "color: #000080;" )
   oEdit:AddClass( "h1", "font-size: 140%; font-weight: bold;" )
   oEdit:AddClass( "h2", "font-size: 130%; font-weight: bold;" )
   oEdit:AddClass( "h3", "font-size: 120%; font-weight: bold;" )
   oEdit:AddClass( "h4", "font-size: 110%; font-weight: bold;" )
   oEdit:AddClass( "h5", "font-weight: bold;" )
   oEdit:AddClass( "i", "font-style: italic;" )
   oEdit:AddClass( "cite", "color: #007800; margin-left: 3%; margin-right: 3%;" )
   oEdit:aDefClasses := { "url","h1","h2","h3","h4","h5","i","cite" }
   oEdit:lReadOnly := .T.
   oEdit:bOther := { |o, m, wp, lp|EditMessProc( o, m, wp, lp ) }

   ACTIVATE DIALOG oDlgHelp NOMODAL

   oEdit:Open( cIniPath + "editor.hwge" )

   RETURN Nil

STATIC FUNCTION About()

   LOCAL oDlg, oStyle1, oStyle2, aRadius := { 4,4,4,4 }

   oStyle1 := HStyle():New( { 0xDDDDDD, 0xAAAAAA }, 1, aRadius, )
   oStyle2 := HStyle():New( { 0xDDDDDD, 0xAAAAAA }, 2, aRadius, )

   INIT DIALOG oDlg TITLE "About" ;
      AT 0, 0 SIZE 460, 310 FONT HWindow():GetMain():oFont COLOR hwg_colorC2N("CCCCCC")

   @ 20, 40 SAY "Editor" SIZE 420,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 20, 64 SAY "Version "+APP_VERSION+Iif( hwg__isUnicode()," Unicode","" ) SIZE 420,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 10, 100 SAY "Copyright 2015-2022 Alexander S.Kresin" SIZE 440,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 20, 124 SAY "http://www.kresin.ru" LINK "http://www.kresin.ru" SIZE 420,26 STYLE SS_CENTER
   @ 20, 160 LINE LENGTH 420
   @ 20, 180 SAY hwg_version() SIZE 420,26 STYLE SS_CENTER COLOR CLR_LBLUE0 TRANSPARENT

   @ 150, 246 OWNERBUTTON ON CLICK {|| hwg_EndDialog()} SIZE 160,36 ;
          TEXT "Close" COLOR hwg_colorC2N("0000FF")

   Atail(oDlg:aControls):aStyle := { oStyle1, oStyle2 }
   //Atail(oDlg:aControls):aRadius := { 8,8,8,8 }

   ACTIVATE DIALOG oDlg CENTER

   hwg_Setfocus( oEdit:handle )

   RETURN Nil

* ==========================================
STATIC FUNCTION GetVal_nTop
* or #ifdef __GTK__ ?
* ==========================================
#ifndef __PLATFORM__WINDOWS
   RETURN 10
#else
   RETURN 40
#endif

* ================== EOF of editor.prg =======================
