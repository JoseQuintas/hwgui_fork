/*
 * HWGUI using sample
 *
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * For GTK need to port or search for substitutes:
 *  HWG_GETCURRENTDIR()
 *  HMDICHILDWINDOW()
 *  HDATEPICKER()
 *  HRECT()
 *  HWG_RECT()
 *
*/

  * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  NO

#include "hwgui.ch"

// REQUEST HB_CODEPAGE_RU866
// REQUEST HB_CODEPAGE_RU1251

MEMVAR oMainWindow, oPanel
MEMVAR oFont , cImageDir , cdirSep
MEMVAR nColor, oBmp2
MEMVAR oProg

#ifdef __USING_MENU__
   FUNCTION DlgMDI()
#else
   FUNCTION Main()
#endif

   PRIVATE cdirSep := hwg_GetDirSep()
   PRIVATE oMainWindow, oPanel
   PRIVATE oFont := Nil, cImageDir := ".." + cdirSep + "image" + cdirSep
   PRIVATE nColor, oBmp2

   // hb_SetCodepage( "RU1251" )

   INIT WINDOW oMainWindow MDI TITLE "Example" SIZE 800,500 ;
         MENUPOS 3 BACKCOLOR 16744703

   @ 0,0 PANEL oPanel SIZE 800,32 ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS
   @ 2,3 OWNERBUTTON OF oPanel ON CLICK {||CreateChildWindow()} ;
       SIZE 32,26 FLAT ;
       BITMAP cImageDir+"new.bmp" COORDINATES 0,4,0,0 TOOLTIP "New MDI child window" ;
       ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS

//   ADD STATUS oStatus TO oMainWindow PARTS 400

   MENU OF oMainWindow
      MENU TITLE "&File"
         MENUITEM "&New" ACTION CreateChildWindow()
         MENUITEM "&Open" ACTION FileOpen()
         SEPARATOR
         MENUITEM "&Font" ACTION oFont := HFont():Select( oFont )
         MENUITEM "&Color" ACTION ( nColor := Hwg_ChooseColor( nColor, .F. ), ;
                     hwg_Msginfo( Iif( nColor != Nil, str( nColor ), "--" ), "Color value" ) )
         MENUITEM "&Test" ACTION test1()
         SEPARATOR
         MENUITEM "&Move Main Window" ACTION oMainWindow:Move( 50, 60, 200, 300 )
         MENUITEM "&Exit" ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Samples"
         MENUITEM "&Checked" ID 1001 ;
               ACTION hwg_Checkmenuitem( ,1001, ! hwg_Ischeckedmenuitem( ,1001 ) )
         SEPARATOR
         MENUITEM "&Test Tab" ACTION TestTab()
         MENUITEM "&Class HRect" ACTION RRectangle()
         SEPARATOR
         MENUITEM "&MsgGet" ;
               ACTION hwg_Copystringtoclipboard( hwg_MsgGet( "Dialog Sample", "Input table name" ) )
         MENUITEM "&Dialog from prg" ACTION DialogFromPrg()
         MENUITEM "&DOS print" ACTION PrintDos()
         // MENUITEM "&Windows print" ;
         //      ACTION Iif( hwg_OpenReport("a.rpt","Simple"),hwg_PrintReport(,,.T.),.F.)
         MENUITEM "&Print Preview" ACTION PrnTest()
         MENUITEM "&Sending e-mail using Outlook" ACTION Sendemail( "test@test.com" )
         MENUITEM "&Command ProgressBar" ACTION TestProgres()
         SEPARATOR
         MENUITEM "&Test No Exit" ACTION NoExit()
      ENDMENU

      MENU TITLE "&TopMost"
         MENUITEM "&Active" ACTION ActiveTopMost( oMainWindow:Handle, .T. )
         MENUITEM "&Desactive" ACTION ActiveTopMost( oMainWindow:Handle, .F. )
      ENDMENU

      MENU TITLE "&Help"
         MENUITEM "&About" ACTION OpenAbout()
         MENUITEM "&hwg_Window2bitmap" ACTION About2()
#ifdef __XHARBOUR__
         MENUITEM "&Version HwGUI and Compilator" ACTION hwg_Msginfo( HwG_Version() + Chr(10) + Chr(13) + version() )
#else
         MENUITEM "&Version HwGUI and Compilator" ACTION hwg_Msginfo( HwG_Version() + Chr(10) + Chr(13) + hb_version()+Chr(10)+Chr(13)+hb_version(1) )
#endif
         MENUITEM "&Version HwGUI" ACTION hwg_Msginfo( HwG_Version() )
         MENUITEM "&Current dir" ACTION hwg_Msginfo( hwg_Getcurrentdir() )
      ENDMENU
      MENU TITLE "&Windows"
         MENUITEM "&Tile"  ;
            ACTION  hwg_Sendmessage( HWindow():GetMain():handle, WM_MDITILE, MDITILE_HORIZONTAL, 0 )
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow

RETURN Nil

FUNCTION CreateChildWindow()

   LOCAL oChildWnd, oPanel, oFontBtn, oBoton1, oBoton2
   LOCAL e1 := "Dialog from prg"
   LOCAL e2 := Date()
   LOCAL e3 := 10320.54
   LOCAL e4:="11222333444455"
   LOCAL e5 := 10320.54

   PREPARE FONT oFontBtn NAME "MS Sans Serif" WIDTH 0 HEIGHT -12

   INIT WINDOW oChildWnd MDICHILD TITLE "Child" STYLE WS_VISIBLE + WS_OVERLAPPEDWINDOW

   @ 0, 0 PANEL oPanel OF oChildWnd SIZE 0, 44

   @ 2, 3 OWNERBUTTON oBoton1 OF oPanel ID 108 ON CLICK { || oBoton2:Enable() } ;
       SIZE 44, 38 FLAT ;
       TEXT "New" FONT oFontBtn COORDINATES 0, 20, 0, 0  ;
       BITMAP cImageDir+"new.bmp" COORDINATES 0, 4, 0, 0 TOOLTIP "New"
   @ 46, 3 OWNERBUTTON oBoton2 OF oPanel ID 109 ON CLICK { || oBoton2:disable() } ;
       SIZE 44, 38 FLAT ;
       TEXT "Open" FONT oFontBtn COORDINATES 0, 20, 0, 0 ;
       BITMAP cImageDir + "open.bmp" COORDINATES 0, 4, 0, 0 TOOLTIP "Open" DISABLED

   @ 20, 55 GET e1                       ;
        PICTURE "XXXXXXXXXXXXXXX"       ;
        SIZE 260, 25

   @ 20, 80 GET e2  SIZE 260, 25

   @ 20, 105 GET e3  SIZE 260, 25

   @ 20, 130 GET e4                      ;
        PICTURE "@R 99.999.999/9999-99" ;
        SIZE 260, 25

   @ 20, 155 GET e5                      ;
        PICTURE "@e 999,999,999.99"     ;
        SIZE 260, 25

   @ 20, 190  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||( hwg_Msginfo( e1 + chr(10) + chr(13) + ;
               Dtoc(e2) + chr(10) + chr(13) + ;
               Str(e3) + chr(10) + chr(13) +  ;
               e4 + chr(10) + chr(13) +       ;
               Str(e5) + chr(10) + chr(13)    ;
               ,"Results:" ) ,oChildWnd:Close() ) }
   @ 180, 190 BUTTON "Cancel" SIZE 100, 32 ON CLICK { || oChildWnd:Close() }

   oChildWnd:Activate()

RETURN Nil

FUNCTION NoExit()

   LOCAL oDlg, oGet, vGet:="Dialog if no close in ENTER or EXIT"

   INIT DIALOG oDlg TITLE "No Exit Enter and Esc"     ;
      AT 190, 10 SIZE 360, 240 NOEXIT NOEXITESC
   @ 10, 10 GET oGet VAR vGET SIZE 200, 32
   @ 20, 190  BUTTON "Ok" SIZE 100, 32 ;
      ON CLICK { || oDlg:Close() }
   oDlg:Activate()

RETURN Nil

FUNCTION OpenAbout()

   LOCAL oModDlg, oFontBtn, oFontDlg, oBrw
   LOCAL aSample := { {.t.,"Line 1",10}, {.t.,"Line 2",22}, {.f.,"Line 3",40} }
   LOCAL oBmp, oIcon := HIcon():AddFile( ".." + cdirSep +  "image" + cdirSep + "exclmk_trsp.ico")   && PIM.ICO was deleted
   LOCAL oSay

   PREPARE FONT oFontDlg NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
   PREPARE FONT oFontBtn NAME "MS Sans Serif" WIDTH 0 HEIGHT -13 ITALIC UNDERLINE

   INIT DIALOG oModDlg TITLE "About"     ;
      AT 190, 10  SIZE 360, 300          ;
      ICON oIcon                         ;
      ON EXIT { || oBmp2 := HBitmap():AddWindow( oBrw ), .T. } ;
      FONT oFontDlg

   @ 30,10 BITMAP ".." + cdirSep + "image"+ cdirSep + "astro.jpg" ;
      SIZE 100, 90 TRANSPARENT ON CLICK { || hwg_MsgInfo( "onclick" ) }

   @ 20, 110 SAY "Sample Dialog"       ;
       SIZE 130, 22 STYLE SS_CENTER  ;
       COLOR hwg_ColorC2N( "0000FF" )

   @ 20, 130 SAY "Written as a sample"  ;
        SIZE 130, 22 STYLE SS_CENTER
   @ 20, 150 SAY "of Harbour GUI" ;
        SIZE 130, 22 STYLE SS_CENTER
   @ 20, 170 SAY "application"    ;
        SIZE 130, 22 STYLE SS_CENTER

   @ 20, 210 SAY "Hwgui Page"        ;
   LINK "http://www.kresin.ru/en/hwgui.html" ;
       SIZE 320, 22 STYLE SS_CENTER  ;
       COLOR hwg_ColorC2N("0000FF") ;
       VISITCOLOR hwg_ColorRgb2N( 241, 249, 91 )

   @ 20,230 SAY "Hwgui international Forum"        ;
      LINK "http://br.groups.yahoo.com/group/hwguibr" ;
      SIZE 320, 22 STYLE SS_CENTER  ;
      COLOR hwg_ColorC2N( "0000FF" ) ;
      VISITCOLOR hwg_ColorRgb2N( 241, 249, 91 )

   @ 160, 10 BROWSE oBrw ARRAY SIZE 180, 180 ;
        STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   @ 80, 260 OWNERBUTTON ON CLICK { || hwg_EndDialog() }  ;
       SIZE 180, 35 FLAT                                  ;
       TEXT "Close" COLOR hwg_ColorC2N( "0000FF" ) FONT oFontBtn ;
       BITMAP cImageDir+"door.bmp" COORDINATES 40, 10, 0, 0
       //

   hwg_CREATEARLIST( oBrw,aSample )
   oBrw:bColorSel    := 12507070  // 15149157449

   oBmp := HBitmap():AddStandard( OBM_CHECK )
   oBrw:aColumns[1]:aBitmaps := { ;
      { {|l|l}, oBmp } ;
   }
   oBrw:aColumns[2]:length := 6
   oBrw:aColumns[3]:length := 4
   oBrw:bKeyDown := { | o, key | BrwKey( o, key ) }

   ACTIVATE DIALOG oModDlg
   oIcon:Release()

RETURN Nil

STATIC FUNCTION About2()

   LOCAL oModDlg

   IF oBmp2 == Nil
      Return NIL
   ENDIF

   INIT DIALOG oModDlg TITLE "About2"   ;
   AT 190,10  SIZE 360,240

   @ 10, 10 BITMAP oBmp2

   ACTIVATE DIALOG oModDlg

RETURN Nil

STATIC FUNCTION BrwKey( oBrw, key )

   IF key == 32
      oBrw:aArray[ oBrw:nCurrent,1 ] := ! oBrw:aArray[ oBrw:nCurrent,1 ]
      oBrw:RefreshLine()
   ENDIF

RETURN .T.

FUNCTION FileOpen()

   LOCAL oModDlg, oBrw
   LOCAL mypath := cdirSep + CurDir() + IIF( Empty( CurDir() ), "", cdirSep )
   LOCAL fname := hwg_Selectfile( "xBase files( *.dbf )", "*.dbf", mypath )
   LOCAL nId

   IF ! Empty( fname )
      mypath := cdirSep + CurDir() + IIF( Empty( CurDir() ), "", cdirSep )
      // use &fname new codepage RU866
      USE &fname NEW
      nId := 111

      INIT DIALOG oModDlg TITLE "1"                    ;
            AT 210,10  SIZE 500,300                    ;
            ON INIT { |o| hwg_Setwindowtext( o:handle, fname ) } ;
            ON EXIT { |o| Fileclose(o)}

      MENU OF oModDlg
         MENUITEM "&Font" ACTION ( oBrw:oFont := HFont():Select( oFont ), oBrw:Refresh() )
         MENUITEM "&Exit" ACTION hwg_EndDialog( oModDlg:handle )
      ENDMENU

      @ 0,0 BROWSE oBrw DATABASE OF oModDlg ID nId ;
            SIZE 500,300                           ;
            STYLE WS_VSCROLL + WS_HSCROLL          ;
            ON SIZE { | o, x, y | hwg_Movewindow( o:handle, 0, 0, x, y ) } ;
            ON GETFOCUS { | o | dbSelectArea( o:alias ) }
      hwg_CreateList( oBrw,.T. )
      oBrw:bScrollPos := { | o, n, lEof, nPos | hwg_VScrollPos( o, n, lEof, nPos ) }
      IF oFont != Nil
         oBrw:ofont := oFont
      ENDIF
      AEval( oBrw:aColumns, { | o | o:bHeadClick := { | oB, n | hwg_Msginfo( "Column number " + Str( n ) ) } } )

      ACTIVATE DIALOG oModDlg NOMODAL
   ENDIF

RETURN Nil

FUNCTION FileClose( oDlg )

   LOCAL oBrw := oDlg:FindControl( 111 )

   dbSelectArea( oBrw:alias )
   dbCloseArea()

RETURN .T.

FUNCTION printdos()

   LOCAL han := fcreate( "LPT1", 0 )

   IF han != -1
      fwrite( han, Chr(10) + Chr(13) + "Example of dos printing ..." + Chr(10) + Chr(13) )
      fwrite( han, "Line 2 ..." + Chr(10) + Chr(13) )
      fwrite( han, "---------------------------" + Chr(10) + Chr(13) + Chr(12) )
      fclose( han )
   ELSE
      hwg_Msgstop( "Can't open printer port!" )
   ENDIF

RETURN Nil

FUNCTION PrnTest()

   LOCAL oPrinter, oFont

   INIT PRINTER oPrinter
   IF oPrinter == Nil
      RETURN Nil
   ENDIF

   oFont := oPrinter:AddFont( "Times New Roman", 10 )

   oPrinter:StartDoc( .T. )
   oPrinter:StartPage()
   oPrinter:SetFont( oFont )
   oPrinter:Box( 5, 5, oPrinter:nWidth - 5, oPrinter:nHeight - 5 )
   oPrinter:Say( "Windows printing first sample !", 50, 10, 165, 26, DT_CENTER, oFont  )
   oPrinter:Line( 45, 30, 170, 30 )
   oPrinter:Line( 45, 5, 45, 30 )
   oPrinter:Line( 170, 5, 170, 30 )
   oPrinter:Say( "----------", 50, 120, 150, 132, DT_CENTER  )
   oPrinter:Box( 50,134,160,146 )
   oPrinter:Say( "End Of Report", 50, 135, 160, 146, DT_CENTER  )
   oPrinter:EndPage()
   oPrinter:EndDoc()
   oPrinter:Preview()
   oPrinter:End()

RETURN Nil

FUNCTION DialogFromPrg( o )

   LOCAL cTitle := "Dialog from prg", cText := "Input something"
   LOCAL oModDlg, oFont := HFont():Add( "MS Sans Serif",0,-13 )
   LOCAL cRes, aCombo := { "First","Second" }, oEdit, vard := "Monday"
// Local aTabs := { "Monday","Tuesday","Wednesday","Thursday","Friday" }
   LOCAL oTab

   // o:bGetFocus := Nil
   INIT DIALOG oModDlg TITLE cTitle           ;
      AT 210, 10  SIZE 300, 300               ;
      FONT oFont                              ;
      ON EXIT { || hwg_Msgyesno( "Really exit ?" ) }

   @ 20, 10 SAY cText SIZE 260, 22
   @ 20, 35 EDITBOX oEdit CAPTION ""    ;
        STYLE WS_DLGFRAME              ;
        SIZE 260, 26 COLOR hwg_ColorC2N( "FF0000" ) ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 20, 70 CHECKBOX "Check 1" SIZE 90, 20
   @ 20, 95 CHECKBOX "Check 2"  ;
        SIZE 90, 20 COLOR Iif( nColor == Nil, hwg_ColorC2N( "0000FF" ), nColor )

   @ 160, 70 GROUPBOX "RadioGroup"  SIZE 130, 75

   RADIOGROUP
   @ 180, 90 RADIOBUTTON "Radio 1"  ;
        SIZE 90, 20 ON CLICK { || oEdit:SetColor( hwg_ColorC2N( "0000FF" ),,.T. ) }
   @ 180,115 RADIOBUTTON "Radio 2" ;
        SIZE 90, 20 ON CLICK { || oEdit:SetColor( hwg_ColorC2N( "FF0000" ),, .T. ) }
   END RADIOGROUP SELECTED 2

   @ 20, 120 COMBOBOX aCombo STYLE WS_TABSTOP ;
        SIZE 100, 150 EDIT

   @ 20, 160 UPDOWN 10 RANGE -10, 50 SIZE 50, 32 STYLE WS_BORDER

   @ 160, 160 TAB oTab ITEMS {} SIZE 130, 56
   BEGIN PAGE "Monday" OF oTab
      @ 20, 28 GET vard SIZE 80, 22 STYLE WS_BORDER
   END PAGE OF oTab
   BEGIN PAGE "Tuesday" OF oTab
      @ 20, 28 EDITBOX "" SIZE 80, 22 STYLE WS_BORDER
   END PAGE OF oTab

   @ 100, 220 LINE LENGTH 100

   @ 20, 240 BUTTON "Ok" OF oModDlg ID IDOK  ;
        SIZE 100, 32 COLOR hwg_ColorC2N( "FF0000" ) ON SIZE ANCHOR_BOTTOMABS
   @ 140, 240 BUTTON "11" OF oModDlg  ;
        SIZE 20, 32 ON CLICK { | o | CreateC( o ) }
   @ 180,240 BUTTON "Cancel" OF oModDlg ID IDCANCEL  ;
        SIZE 100, 32 ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oModDlg
   oFont:Release()

RETURN Nil

#define DTM_SETFORMAT       4101

STATIC FUNCTION CreateC( oDlg )

   STATIC lFirst := .F., o

   IF ! lFirst
      @ 100, 200 DATEPICKER o SIZE 80, 24
      lFirst := .T.
   ENDIF
   hwg_Sendmessage( o:handle, DTM_SETFORMAT, 0, "dd':'MM':'yyyy" )

RETURN Nil

FUNCTION Sendemail( endereco )

   hwg_Shellexecute( "rundll32.exe", "open", ;
            "url.dll,FileProtocolHandler " + ;
            "mailto:" + endereco + "?cc=&bcc=" + ;
            "&subject=Ref%20:" + ;
            "&body=This%20is%20test%20.", , 1 )

RETURN Nil

FUNCTION TestTab()

   LOCAL oDlg, oTAB
   LOCAL oGet1, oGet2, oVar1:="1", oVar2:="2"
   LOCAL oGet3, oGet4, oVar3:="3", oVar4:="4", oGet5, oVar5 := "5"

   INIT DIALOG oDlg CLIPPER NOEXIT AT 0, 0 SIZE 200, 200

   @ 10, 10 TAB oTab ITEMS {} SIZE 180, 180 ;
      ON LOSTFOCUS { || hwg_Msginfo( "Lost Focus" ) } ;
      ON INIT { || hwg_Setfocus( oDlg:getlist[1]:handle ) } ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   BEGIN PAGE "Page 01" of oTab

      @ 30, 60 Get oGet1 VAR oVar1 SIZE 100, 26
      oGet1:Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS
      @ 30, 90 Get oGet2 VAR oVar2 SIZE 100, 26
      @ 30,120 Get oGet3 VAR oVar3 SIZE 100, 26
      @ 30,150 Get oGet4 VAR oVar4 SIZE 100, 26

   END PAGE of oTab

   BEGIN PAGE "Page 02" of oTab

      @ 30, 60 Get oGet5 VAR oVar5 SIZE 100, 26

   END PAGE of oTab

   ACTIVATE DIALOG oDlg

RETURN Nil

FUNCTION ActiveTopMost( nHandle, lActive )

   LOCAL lSucess

    IF lActive
       lSucess := hwg_Settopmost(nHandle)    // Set TopMost
    ELSE
       lSucess := hwg_Removetopmost(nHandle) // Remove TopMost
    ENDIF

RETURN lSucess

FUNCTION TestProgres()

   LOCAL oDlg,ostatus,oBar
   LOCAL cRes, aCombo := { "First","Second" }
   LOCAL oCombo

   PRIVATE oProg

   INIT DIALOG oDlg TITLE "Progress Bar"    ;
      AT 190, 10  SIZE 360, 240

   @ 10, 10 PROGRESSBAR oProg  ;
             OF oDlg        ;
             SIZE 200,25    ;
             BARWIDTH 10    ;
             QUANTITY 1000
   ADD STATUS oStatus TO oDlg PARTS 400
   oBar   := HProgressBar():New( ostatus,, 0, 2, 200, 20, 200, 1000, hwg_ColorRgb2N( 12, 143, 243 ), hwg_ColorRgb2N( 243, 132, 143 ) )
   oCombo := HComboBox():New( ostatus,,,, 65536, 0, 2, 200, 20, aCombo,,,,,,, .F., .F.,,, )
   @ 10, 60  BUTTON "Test" SIZE 100, 32 ON CLICK { || MudeProg( oBar ) }

   oDlg:Activate()

RETURN Nil

FUNCTION MudeProg( ostatus )

   LOCAL ct := 1

   DO WHILE ct < 1001
      oProg:Step()
      ostatus:step()
      ++ct
   ENDDO

RETURN Nil


FUNCTION RRectangle()

   LOCAL oDlg, oR1, oR2, oR3

   INIT DIALOG oDlg TITLE "Sample HRect"    ;
      AT 190, 10  SIZE 600, 400

       @ 230, 10, 400, 100 RECT oR1 of oDlg PRESS
       @  10, 10, 200, 100 RECT oR2 of oDlg RECT_STYLE 3
       @  10,130, 100, 230 RECT oR3 of oDlg PRESS RECT_STYLE 2

       hwg_Rect( oDlg, 10, 250, 590, 320, , 1 )

   oDlg:Activate()

RETURN Nil

FUNCTION Test1()

   LOCAL hDC := hwg_Getdc( 0 ), aMetr, oFont

   PREPARE FONT oFont NAME "Arial" WIDTH 0 HEIGHT -17
   hwg_Selectobject( hDC, oFont:handle )
   aMetr := hwg_Gettextmetric( hDC )
   hwg_writelog( ltrim( str( aMetr[ 2 ] ) ) + " " + ltrim( str( aMetr[ 3 ] ) ) )

   hwg_writelog( ltrim( str( hwg_Gettextsize( hDC, "          " )[1] ) ) )
   hwg_writelog( ltrim( str( hwg_Gettextsize( hDC, "1111111111" )[1] ) ) )
   hwg_writelog( ltrim( str( hwg_Gettextsize( hDC, "aaaaaaaaaa" )[1] ) ) )
   hwg_writelog( ltrim( str( hwg_Gettextsize( hDC, "AAAAAAAAAA" )[1] ) ) )
   hwg_writelog( ltrim( str( hwg_Gettextsize( hDC, "WWWWWWWWWW" )[1] ) ) )
   hwg_writelog( ltrim( str( hwg_Gettextsize( hDC, "bbbbbbbbbb" )[1] ) ) )
   hwg_writelog( ltrim( str( hwg_Gettextsize( hDC, "RRRRRRRRRR" )[1] ) ) )

   hwg_Releasedc( 0,hDC )

RETURN Nil

* ============================ EOF of a.prg =================================
