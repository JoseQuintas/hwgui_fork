/*
demoall.prg
menu for samples on samples/ folder

DF7BE:
This seems to be a bug in Harbour:
all.prg(182) Warning W0032  Variable 'CBINHBMK' is assigned but not used in function 'EXECUTEEXE(159)'

possible bug on windows 11:
status panel is not full on dialog first display, if remove ACTIVATE DIALOG CENTER ok

How to reutilize samples:

1) Change sample to receive 2 parameters lWithDialog and oDLG
2) If send lWithDialog=.F. sample do not create dialog, use dialog from parameter
3) Add on sample ButtonForSample( "name", oDlg ) to show buttons
4) Add on sample at the end #include "demo.ch"

Depending on sample, it can be used on a dialog or tab page (send oTab and not oDlg)
if not, add a button call to it.
It is all

*/

#ifdef __LINUX__
   #define __IS_AVAILABLE 3
#else
   #ifdef __MACOS__
      #define __IS_AVAILABLE 4
   #else
      #define __IS_AVAILABLE 2
   #endif
#endif

#include "hwgui.ch"
#include "directry.ch"

PROCEDURE Main

   LOCAL oDlg, oTab, aItem, nIndex := 1, lCloseMenu := .F., nCont
   LOCAL lIsAvailable, lIsEXE, aInitList := {}
   LOCAL aList := { ;
       ; // NAME,                  WIN, LINUX, MACOS, DESCRIPTION
       { "a.prg",                  .T., .F., .F., "MDI, Tab, checkbox, combobox, browse array, others" }, ;
       ;
       { "",                       .T., .F., .F., "" }, ;
       ;
       { "demoini.prg",            .T., .F., .F., "Read/write Ini" }, ;
       { "hello.prg",              .T., .F., .F., "RichEdit, Tab, Combobox" }, ;
       { "tab.prg",                .T., .F., .F., "Tab, checkbox, editbox, combobox, browse array" }, ;
       ;
       ; // controls
       ;
       { "testbrowsearr.prg",      .T., .T., .T., "browse array editable" }, ;
       { "demodatepicker.prg",     .T., .T., .T., "Date Picker" }, ;
       { "demoonother.prg",        .T., .F., .F., "ON OTHER MESSAGES" }, ;
       ;
       { "",                       .F., .F., .F., "" }, ;
       ;
       ; // not recommended. Move to contrib ?
       ;
       { "",                       .F., .F., .F., "" }, ;
       { "",                       .F., .F., .F., "" }, ;
       ;
       ; // first review
       { "nice.prg",               .T., .F., .F., "Nice button" }, ;
       { "nice2.prg",              .T., .F., .F., "Nice button 2 ***?***" }, ;
       ;
       { "",                       .F., .F., .F., "" }, ;
       ;
       ; // next review
       { "colrbloc.prg",           .T., .T., .T., "Color Block" }, ;
       { "dbview.prg",             .T., .T., .T., "DBView" }, ;
       { "dialogboxes.prg",        .T., .T., .T., "Dialogboxes" }, ;
       { "escrita.prg",            .T., .T., .T., "Escrita" }, ;
       { "fileselect.prg",         .T., .T., .T., "File Select" }, ;
       { "graph.prg",              .T., .T., .T., "Graph" }, ;
       { "grid_1.prg",             .T., .F., .F., "Grid1" }, ;
       { "grid_2.prg",             .F., .F., .F., "Grid2 PostGres" }, ;
       { "grid_3.prg",             .F., .F., .F., "Grid3 PostGres" }, ;
       { "grid_4.prg",             .T., .F., .F., "Grid4" }, ;
       { "grid_5.prg",             .T., .F., .F., "Grid5" }, ;
       { "helpstatic.prg",         .T., .T., .T., "Help Static" }, ;
       { "htrack.prg",             .T., .T., .T., "HTrack" }, ;
       { "icons.prg",              .T., .T., .T., "Icons" }, ;
       { "icons2.prg",             .T., .T., .T., "Icons2" }, ;
       { "testalert.prg",          .T., .F., .F., "Test Alert" }, ;
       { "testbrwq.prg",           .T., .F., .F., "Test browse" }, ;
       { "testget1.prg",           .T., .F., .F., "Test Get 1" }, ;
       { "testmenubitmap.prg",     .T., .F., .F., "Test Menu Bitmap" }, ;
       { "testtree.prg",           .T., .F., .F., "Treebox Editable *** error on edit***" }, ;
       { "testrtf.prg",            .T., .F., .F., "Test RTF" }, ;
       { "tstscrlbar.prg",         .T., .T., .T., "Scrollbar" }, ;
       { "tstspach.prg",           .T., .F., .F., "Test Splash" }, ;
       { "twolistbox.prg",         .T., .F., .F., "Two List Box" }, ;
       { "helpdemo.prg",           .T., .T., .T., "Help Demo ***outdated***" }, ;
       { "hole.prg",               .T., .F., .F., "Ole ***error***" }, ;
       { "propsh.prg",             .T., .F., .F., "Propsheet ***error***" }, ;
       { "testtray.prg",           .T., .F., .F., "Test Tray ***Error***" }, ;
       { "tstprdos.prg",           .T., .F., .F., "test DOS ***outdated***" }, ;
       ;
       { "",                       .F., .F., .F., "" }, ;
       ; // already visible on the tab of demoall.prg
       ;
       ; // { "demotab",                .T., .T., .T., "Tab and more samples" } , ;
       ; // { "demobrowsedbf",          .T., .T., .T., "Browse DBF"  }, ;
       ; // { "demoget2.prg",           .T., .F., .F., "Test Get 2" }, ;
       ; // { "demomonthcal",           .T., .T., .T., "Month Calendar" }, ;
       ; // { "demobrowseado",          .T., .F., .F., "Browse using ADO" }, ;
       ; // { "democheckbox",           .T., .T., .T., "Checkbox and tab" }, ;
       ; // { "democombobox.prg",       .T., .T., .T., "Combobox" }, ;
       ; // { "demodbfdata.prg",        .T., .T., .T., "DBF data using tab" }, ;
       ; // { "demogetupdown.prg",      .T., .T., .T., "Get UpDown" }, ;
       ; // { "demolistbox.prg",        .T., .F., .F., "Listbox" }, ;
       ; // { "demolistboxsub.prg",     .T., .T., .T., "Listbox Substitute" }, ;
       ; // { "demomenu",               .T., .T., .T., "Simple menu" }, ;
       ; // { "demomenuxml",            .T., .T., .T., "Setup menu from XML ***error on new item***" }, ;
       ; // { "demotreebox",            .T., .T., .T., "Treebox, Splitter and tab" }, ;
       ; // { "demoshadebtn",           .T., .F., .F., "Shade button" }, ;
       ; // { "demoxmltree.prg",        .T., .T., .T., "Show XML using hxmldoc and tree" }, ;
       { "",                       .F., .F., .F., "" }, ;
       { "notexist",               .F., .F., .F., "Test for menu, about not available" } }

   INIT DIALOG oDlg ;
      TITLE "demoall.prg - Show Samples on screen, and others on menu" ;
      AT 0,0 ;
      SIZE 1024, 768 ;
      BACKCOLOR 16772062 ;
      STYLE WS_MAXIMIZEBOX + WS_MINIMIZEBOX + WS_SYSMENU ;
      ON INIT { || DemoAllEvalList( aInitList ) }

   MENU OF oDlg
      FOR nCont = 1 TO Len( aList ) // not sure about Xharbour for/each
         IF Mod( nCont, 10 ) == 1 // 10 options by group
            MENU TITLE "Samples" + Str( nIndex, 1 )
            nIndex     += 1
            lCloseMenu := .T.
         ENDIF
         FOR EACH aItem IN { aList[ nCont ] } // for/each isolate aItem to codeblock
            IF Empty( aItem[ 1 ] )
               SEPARATOR
               LOOP
            ENDIF
            lIsAvailable := aItem[ __IS_AVAILABLE ]
            lIsExe       := Right( aItem[ 1 ], 4 ) == ".prg"
            IF lIsAvailable
               IF lIsExe
                  MENUITEM aItem[ 1 ] + " - " + aItem[ 5 ] ACTION { || ExecuteExe( aItem[ 1 ] ) }
               ELSE
                  MENUITEM aItem[ 1 ] + " - " + aItem[ 5 ] ACTION { || Do( aItem[ 1 ] ) }
               ENDIF
            ELSE
               MENU TITLE aItem[ 1 ] + " - " + aItem[ 5 ] + " not available"
               ENDMENU
            ENDIF
         NEXT
         IF Mod( nCont, 10 ) == 0 // 10 options by group
            ENDMENU
            lCloseMenu := .F.
         ENDIF
      NEXT
      IF lCloseMenu // close menu if not closed before
         ENDMENU
      ENDIF
      MENU TITLE "Tests/Exit"
         MENUITEM "For tests check PRG/HBP/EXE" ACTION { || CheckPrgHbpExe() }
         MENUITEM "Display current DLG Size" ACTION { || ;
            hwg_MsgInfo( "Width: " + Ltrim( Str( oDlg:nWidth ) ) + " - " + ;
               "Height:" + Ltrim( Str( oDlg:nHeight ) ) ) }
         MENUITEM "Refresh Dilaog" ACTION { || oDlg:refresh() }
         MENUITEM "&Exit" ACTION hwg_EndWindow()
      ENDMENU
   ENDMENU

   ButtonForSample( "demoall.prg" )

   @ 30, 60 TAB oTab ;
      ITEMS {} ;
      SIZE  950, 600

   BEGIN PAGE "AppData" OF oTab

      DemoDbfData( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "Browse" OF oTab

      DemoAllTabBrowse()

   END PAGE OF oTab

   BEGIN PAGE "Button" OF oTab

      DemoAllTabButton()

   END PAGE OF oTab

   BEGIN PAGE "Checkbox" OF oTab

      DemoCheckBox( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "Combobox" OF oTab

      DemoCombobox( .F., oTab )

   END PAGE of oTab

   BEGIN PAGE "Date" OF oTab

      DemoAllTabDate()

   END PAGE OF oTab

   BEGIN PAGE "Get" OF oTab

      DemoAllTabGet()

   END PAGE OF oTab

   BEGIN PAGE "Listbox" OF oTab

      DemoAllTabListbox()

   END PAGE OF oTab

   BEGIN PAGE "Menu" OF oTab

      DemoAllTabMenu()

   END PAGE OF oTab

   BEGIN PAGE "Say" OF oTab

      DemoAllTabSay()

   END PAGE OF oTab

   BEGIN PAGE "Splitter" OF oTab

      DemoAllTabSplitter( aInitList )

   END PAGE OF oTab

   BEGIN PAGE "Tab" OF oTab

      DemoTab( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "Timer" OF oTab

      DemoGet2( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "Treebox" OF oTab

      DemoAllTabTreebox( aInitList )

   END PAGE OF oTab

   BEGIN PAGE "Updown" OF oTab

      DemoGetUpDown( .F., oTab )

   END PAGE OF oTab

   // A STATUS PANEL may be used instead of a standard STATUS control
   ADD STATUS PANEL ;
      TO     oDlg ;
      HEIGHT 30 ;
      PARTS  80, 200, 0

   hwg_WriteStatus( oDlg, 1, "demoall.prg", .F. )
   hwg_WriteStatus( oDlg, 2, hwg_Version(), .F. )
   hwg_WriteStatus( oDlg, 3, "See more on hwgui tutorial", .F. )

   ACTIVATE DIALOG oDlg CENTER

   RETURN

STATIC FUNCTION DemoAllTabSay()

   LOCAL oTab

   @ 10, 30 TAB oTab ;
      ITEMS {} ;
      SIZE 700, 550

   BEGIN PAGE "1.DemoGet2" OF oTab

      DemoGet2( .F., oTab )

   END PAGE OF oTab

   RETURN Nil

STATIC FUNCTION DemoAllTabGet()

   LOCAL oTab

   @ 10, 30 TAB oTab ;
      ITEMS {} ;
      SIZE 700, 550

   BEGIN PAGE "1.DemoGet2" OF oTab

      DemoGet2( .F., oTab )

   END PAGE OF oTab

   RETURN Nil

STATIC FUNCTION DemoAllTabBrowse()

   LOCAL oTab

   @ 30, 30 TAB oTab ;
      ITEMS {} ;
      SIZE  700, 550

#ifdef __PLATFORM__WINDOWS
   BEGIN PAGE "1.Browse ADO" OF oTab

      DemoBrowseADO( .F., oTab )

   END PAGE OF oTab
#endif

   BEGIN PAGE "2.Browse Array" OF oTab

      DemoBrowseArray( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "3.Browse DBF" OF oTab

      DemoBrowseDBF( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "4.Listbox Alt" OF oTab

      DemoListBoxSub( .F., oTab )

   END PAGE OF oTab

   RETURN Nil

STATIC FUNCTION DemoAllTabButton()

   LOCAL oTab

   @ 30, 60 TAB oTab ;
      ITEMS {} ;
      SIZE  700, 480

   BEGIN PAGE "1.Ownerbutton" OF oTab

      DemoOwner( .F., oTab )

   END PAGE OF oTab

#ifdef __PLATFORM__WINDOWS
   BEGIN PAGE "2.Shadebutton" OF oTab

      DemoShadeBtn( .F., oTab )

   END PAGE OF oTab
#endif

   RETURN Nil

STATIC FUNCTION DemoAllTabMenu()

   LOCAL oTab

   @ 30, 60 TAB oTab ;
      ITEMS {} ;
      SIZE 700, 550

   BEGIN PAGE "1.menu" OF oTab

      @ 30, 50 BUTTON "demomenu.prg" ;
         SIZE 200, 24 ;
         ON CLICK { || DemoMenu() }

   END PAGE OF oTab

   BEGIN PAGE "2.menuxml" OF oTab

      @ 30, 50 BUTTON "demomenuxml.prg" ;
         SIZE 200, 24 ;
         ON CLICK { || DemoMenuXml() }

   END PAGE OF oTab

   RETURN Nil

STATIC FUNCTION DemoAllTabDate()

   LOCAL oTab

   @ 30, 30 TAB oTab ;
      ITEMS {} ;
      SIZE  700, 550

#ifdef __PLATFORM__WINDOWS

   BEGIN PAGE "1.Monthcal" OF oTab

      DemoMonthCal( .F., oTab )

   END PAGE OF oTab
#endif

   BEGIN PAGE "2.Dateselect" OF oTab

      DemoDateSelect( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "3.Alt.DPicker" OF oTab

      DemoAltDPicker( .F., oTab )

   END PAGE OF oTab

   RETURN Nil

STATIC FUNCTION DemoAllTabTreebox( aInitList )

   LOCAL oTab

   @ 30, 30 TAB oTab ;
      ITEMS {} ;
      SIZE 700, 550

   BEGIN PAGE "1.Treebox" OF oTab

      DemoTreebox( .F., oTab, aInitList )

   END PAGE OF oTab

   BEGIN PAGE "2.XML Tree" OF oTab

      DemoXmlTree( .F., oTab, aInitList )

   END PAGE OF oTab

   RETURN Nil

STATIC FUNCTION DemoAllTabSplitter( aInitList )

   LOCAL oTab

   @ 30, 30 TAB oTab ;
      ITEMS {} ;
      SIZE 700, 550

   BEGIN PAGE "1.Treebox" OF oTab

      DemoTreebox( .F., oTab, aInitList )

   END PAGE OF oTab

   BEGIN PAGE "2.XML Tree" OF oTab

      DemoXmlTree( .F., oTab )

   END PAGE OF oTab

   RETURN Nil

STATIC FUNCTION DemoAllTabListbox()

   LOCAL oTab

   @ 30, 30 TAB oTab ;
      ITEMS {} ;
      SIZE 700, 650

   BEGIN PAGE "1.Alt.Listbox" OF oTab

      DemoListBoxSub( .F., oTab )

   END PAGE OF oTab

   RETURN Nil

STATIC FUNCTION CreatePanel( oDlg, nLeft, nTop, nWidth, nHeight )

   LOCAL oPanel, aColorList := { ;
      16772062, ; // light blue
      0xaaaaaa, ; // light gray
      0x154780, ; // brown 1
      0x396eaa, ; // brown 2
      0x6a9cd4, ; // brown 3
      0x9dc7f6 }   // browm4

   STATIC nValue := 0

   nValue := iif( nValue >= Len( aColorList ), 1, nValue + 1 )

   @ nLeft, nTop PANEL oPanel ;
      ; // OF oDlg, ;
      SIZE nWidth, nHeight ;
      BACKCOLOR nValue

// DANGER: remove before use
   IF .F.
      CreatePanel()
   ENDIF
   (oDlg);(oPanel);(nLeft);(nTop);(nWidth);(nHeight) // -w3 -es2

   RETURN Nil

STATIC FUNCTION ExecuteExe( cFileName )

   LOCAL cFileNoExt, cBinName, cBinHbmk

   cFileNoExt := Left( cFileName, At( ".", cFileName ) - 1 )

#ifndef __PLATFORM__WINDOWS
   cBinName := "./" + cFileNoExt
   cBinHbmk := "hbmk2"
#else
   cBinName := cFileNoExt + ".exe"
   cBinHbmk := "hbmk2.exe"
#endif

   IF ! File( cBinName )
      IF ! hwg_MsgYesNo( cBinName + " not found, try create it?" )  && DF7BE: cFileName ==> cBinName
         RETURN Nil
      ENDIF

      // hwg_RunApp( cBinHbmk + " " + cFileNoExt, .T. ) // hbmk2 will use hbp or prg
      // do not wait
      * See bug in Harbour, not recognized,that CBINHBMK is used here!
      // RUN( CBINHBMK + " " + cFileNoExt, .T. ) // hbmk2 will use hbp or prg
      hwg_RunConsoleApp( CBINHBMK + " " + cFileNoExt, , .T. )

      IF ! File( cBinName )
         hwg_MsgInfo( "Can't create " + cBinName )
         RETURN Nil
      ENDIF
   ENDIF
   HWG_RunApp( cBinName )

   RETURN Nil

STATIC FUNCTION DemoAllEvalList( aInitList )

   LOCAL bCode

   FOR EACH bCode IN aInitList
      Eval( bCode )
   NEXT

   RETURN Nil

STATIC FUNCTION CheckPrgHbpExe()

   LOCAL aItem, cFile, lWithHbp, lWithExe
   LOCAL cTxtPrg := "No HBP" + hb_Eol() + hb_Eol()
   LOCAL cTxtHbp := "With HBP" + hb_Eol() + hb_Eol()

   FOR EACH aItem IN Directory( "*.prg" )
      cFile := aItem[ F_NAME ]
      cFile := Substr( cFile, 1, Len( cFile ) - 4 )
      lWithHbp := File( cFile + ".hbp" )
      lWithExe := File( cFile + ".exe" )
      IF ! lWithHbp
         cTxtPrg += Pad( cFile, 20 )
         cTxtPrg += iif( lWithExe, "EXE_YES", "EXE_NO" )
         cTxtPrg += hb_Eol()
      ELSEIF ! ( lWithExe )
         cTxtHbp += Pad( cFile, 20 )
         cTxtHbp += "EXE_" + iif( lWithExe, "YES", "NO" )
         cTxtHbp += hb_Eol()
      ENDIF
   NEXT
   hwg_MsgInfo( cTxtPrg )
   hwg_MsgInfo( cTxtHbp )

   RETURN Nil

// to be external
STATIC FUNCTION DemoDateSelect()

   LOCAL oDate

   @ 10, 50 SAY "Date" ;
      SIZE 80, 30

   @ 100, 50 DATESELECT oDate ;
      SIZE 120,28

   RETURN Nil

// to be external

// to be external
STATIC FUNCTION DemoBrowseArray()

   LOCAL oBrowse
   LOCAL aBrowseList := { ;
      { "Alex",   17, 12600 }, ;
      { "Victor", 42, 1600 }, ;
      { "John",   31, 15000 } }

   @ 10, 30 BROWSE oBrowse ;
      ARRAY ;
      SIZE  450, 250 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   // array stored on browse aArray, and codeblocks using it
   oBrowse:aArray := aBrowseList
   oBrowse:AddColumn( HColumn():New( "Name",  { | v, o | (v), o:aArray[ o:nCurrent, 1 ] }, "C", 16, 0 ) )
   oBrowse:AddColumn( HColumn():New( "Age",   { | v, o | (v), o:aArray[ o:nCurrent, 2 ] }, "N", 6, 0 ) )
   oBrowse:AddColumn( HColumn():New( "Number",{ | v, o | (v), o:aArray[ o:nCurrent, 3 ] }, "N", 8, 0 ) )

   RETURN Nil

// to be external
STATIC FUNCTION DemoOwner( lWithDialog, oDlg )

   LOCAL oBtn1, oBtn2, oBtn3
   LOCAL oStyleNormal  := HStyle():New( {16759929,16772062}, 1 )
   LOCAL oStylePressed := HStyle():New( {16759929}, 1,, 3, 0 )
   LOCAL oStyleOver    := HStyle():New( {16759929}, 1,, 2, 12164479 )
   LOCAL aBtn2Style    := { ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 2,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 2, 8421440 ) }

   @ 10, 150 OWNERBUTTON oBtn1 ;
      OF       oDlg ;
      SIZE     60, 24;
      TEXT     "But.1" ;
      ON CLICK { || hwg_MsgInfo( "Button 1" ) }

   @ 10, 200 OWNERBUTTON oBtn2 ;
      OF       oDlg ;
      SIZE     60, 24 ;
      TEXT     "But.2" ;
      ON CLICK { || hwg_MsgInfo( "Button 2" ) }
   oBtn2:aStyle := aBtn2Style

   @ 10, 250 OWNERBUTTON oBtn3 ;
      OF       oDlg ;
      SIZE     60, 24 ;
      HSTYLES oStyleNormal, oStylePressed, oStyleOver ;
      TEXT     "But.3" ;
      ON CLICK { || hwg_MsgInfo( "Button 3" ) }

   (lWithDialog) // not used, warning -w3 -es2

   RETURN Nil

// only test
FUNCTION LoadResourceDemo( cFileName )

DO CASE
CASE cFileName == "demo.ch";             #pragma __binarystreaminclude "demo.ch" | RETURN %s
CASE cFileName == "demoall.prg";         #pragma __binarystreaminclude "demoall.prg" | RETURN %s
CASE cFileName == "democheckbox.prg";    #pragma __binarystreaminclude "democheckbox.prg" | RETURN %s
CASE cFileName == "democombobox.prg";    #pragma __binarystreaminclude "democombobox.prg" | RETURN %s
CASE cFileName == "demoaltdpicker.prg";  #pragma __binarystreaminclude "demoaltdpicker.prg" | RETURN %s
CASE cFileName == "demobrowsedbf.prg";   #pragma __binarystreaminclude "demobrowsedbf.prg" | RETURN %s
CASE cFileName == "demobrowseado.prg";   #pragma __binarystreaminclude "demobrowseado.prg" | RETURN %s
CASE cFileName == "demodbfdata.prg";     #pragma __binarystreaminclude "demodbfdata.prg" | RETURN %s
CASE cFileName == "demogetupdown.prg";   #pragma __binarystreaminclude "demogetupdown.prg" | RETURN %s
CASE cFileName == "demoget2.prg";        #pragma __binarystreaminclude "demoget2.prg" | RETURN %s
CASE cFileName == "demolistbox.prg";     #pragma __binarystreaminclude "demolistbox.prg" | RETURN %s
CASE cFileName == "demolistboxsub.prg";  #pragma __binarystreaminclude "demolistboxsub.prg" | RETURN %s
CASE cFileName == "demomonthcal.prg";    #pragma __binarystreaminclude "demomonthcal.prg" | RETURN %s
CASE cFileName == "demomenu.prg";        #pragma __binarystreaminclude "demomenu.prg" | RETURN %s
CASE cFileName == "demomenuxml.prg";     #pragma __binarystreaminclude "demomenuxml.prg" | RETURN %s
CASE cFileName == "demoshadebtn.prg";    #pragma __binarystreaminclude "demoshadebtn.prg" | RETURN %s
CASE cFileName == "demotab.prg";         #pragma __binarystreaminclude "demotab.prg" | RETURN %s
CASE cFileName == "demotreebox.prg";     #pragma __binarystreaminclude "demotreebox.prg" | RETURN %s
CASE cFileName == "demoxmltree.prg";     #pragma __binarystreaminclude "demoxmltree.prg" | RETURN %s
ENDCASE

RETURN Nil

#include "demo.ch"

* ================================= EOF of all.prg ===========================
