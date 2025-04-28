/*
demoall.prg
menu for samples on samples/ folder

DF7BE:
This seems to be a bug in Harbour:
all.prg(182) Warning W0032  Variable 'CBINHBMK' is assigned but not used in function 'EXECUTEEXE(159)'

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

STATIC aMenuOptions := {}, nMenuLevel := 0

PROCEDURE DemoAll

   LOCAL oDlg, aItem, nIndex := 1, lCloseMenu := .F., nCont
   LOCAL lIsAvailable, lIsEXE
   LOCAL aInitList := {}, aEndList := {}, bCode
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
       { "grid_2.prg",             .F., .F., .F., "Grid2 PostGres" }, ;
       { "grid_3.prg",             .F., .F., .F., "Grid3 PostGres" }, ;
       { "helpstatic.prg",         .T., .T., .T., "Help Static" }, ;
       { "icons.prg",              .T., .T., .T., "Icons" }, ;
       { "icons2.prg",             .T., .T., .T., "Icons2" }, ;
       { "testalert.prg",          .T., .F., .F., "Test Alert" }, ;
       { "testbrwq.prg",           .T., .F., .F., "Test browse" }, ;
       { "testget1.prg",           .T., .F., .F., "Test Get 1" }, ;
       { "testmenubitmap.prg",     .T., .F., .F., "Test Menu Bitmap" }, ;
       { "demotree.prg",           .T., .F., .F., "Treeview Editable *** error on edit***" }, ;
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

   CreateAllTabPages( oDlg, aInitList, aEndList )

   // A STATUS PANEL may be used instead of a standard STATUS control
   ADD STATUS PANEL ;
      TO     oDlg ;
      HEIGHT 30 ;
      PARTS  80, 200, 0

   hwg_WriteStatus( oDlg, 1, "demoall.prg", .F. )
   hwg_WriteStatus( oDlg, 2, hwg_Version(), .F. )
   hwg_WriteStatus( oDlg, 3, "See more on hwgui tutorial", .F. )

   ACTIVATE DIALOG oDlg CENTER

   CLOSE DATABASES

   FOR EACH bCode IN aEndList
      Eval( bCode )
   NEXT

   RETURN

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

STATIC FUNCTION MenuOption( cCaption, bCodeOrString, bCode )

   LOCAL nCont, aLastMenu

   aLastMenu := aMenuOptions
   FOR nCont = 1 TO nMenuLevel
      aLastMenu := aLastMenu[ Len( aLastMenu ) ]
      aLastMenu := aLastMenu[ 2 ]
   NEXT
   AAdd( aLastMenu, { ccaption, {}, bCodeOrString, bCode } )

   RETURN Nil

STATIC FUNCTION MenuDrop()

   nMenuLevel++

   RETURN Nil

STATIC FUNCTION MenuUndrop()

   nMenuLevel --

   RETURN Nil

STATIC FUNCTION CreateAllTabPages( oDlg, aInitList, aEndList )

   LOCAL aOption, aOption2, oTabLevel1, oTabLevel2

   MenuOption( "Browse" )
      MenuDrop()
#ifdef __PLATFORM__WINDOWS
      MenuOption( "1.Browse ADO",         { |o| DemoBrowseADO( .F., o ) } )
#endif
      MenuOption( "2.Browse Array",       { |o| DemoBrowseArray( .F., o ) } )
      MenuOption( "3.Browse DBF",         { |o| DemoBrowseDbf( .F., o, aEndList ) } )
#ifdef __PLATFORM__WINDOWS
      MenuOption( "4.Grid1",              { |o| DemoGrid1( .F., o ) } )
      MenuOption( "4.Grid4",              { |o| DemoGrid4( .F., o, aEndList ) } )
      MenuOption( "4.Grid5",              { |o| DemoGrid5( .F., o, aInitList, aEndList ) } )
#endif
      MenuUndrop()
   MenuOption( "Button" )
      MenuDrop()
      MenuOption( "1.OwnerButton",        { |o| DemoOwner( .F., o ) } )
#ifdef __PLATFORM_WINDOWS
      MenuOption( "2.ShadeButton",        { |o| DemoShadeBtn( .F., o ) } )
#endif
      MenuUnDrop()
   MenuOption( "Checkbox",                { |o| DemoCheckbox( .F., o ) } )
   MenuOption( "Combobox",                { |o| DemoCombobox( .F., o ) } )
   MenuOption( "Date" )
      MenuDrop()
#ifdef __PLATFORM__WINDOWS
      MenuOption( "1.MonthCal",           { |o| DemoMonthCal( .F., o ) } )
#endif
      MenuOption( "DateSelect",           { |o| DemoDateSelect( .F., o ) } )
      MenuOption( "Alt.DPicker",          { |o| DemoAltDPicker( .F., o ) } )
      MenuUnDrop()
   MenuOption( "Get" )
      MenuDrop()
      MenuOption( "1.DemoGet2",           { |o| DemoGet2( .F., o ) } )
      MenuOption( "2.Editbox",            { |o| DemoIni( .F., o, aEndList ) } )
      MenuUnDrop()
   MenuOption( "Listbox" )
      MenuDrop()
      MenuOption( "1.Listbox Alt",        { |o| DemoListBoxSub( .F., o ) } )
      MenuUndrop()
   MenuOption( "Menu" )
      MenuDrop()
      MenuOption( "1.menu",    "demomenu.prg",    { || DemoMenu() } )
      MenuOption( "2.menuxml", "demomenuxml.prg", { || DemoMenuXml() } )
      MenuUnDrop()
   MenuOption( "Progbar",                 { |o| DemoProgbar( .F., o, aEndList ) } )
   MenuOption( "Say" )
      MenuDrop()
      MenuOption( "1.DemoGet2",           { |o| DemoGet2( .F., o ) } )
      MenuUnDrop()
   MenuOption( "Splitter" )
      MenuDrop()
      MenuOption( "1.Split",              { |o| DemoSplit( .F., o, aInitList ) } )
      MenuOption( "2.Splitter",           { |o| DemoSplitter( .F., o, aInitList ) } )
      MenuOption( "3.Tree",               { |o| DemoTree( .F., o, aInitList ) } )
      MenuOption( "4.XML Tree",           { |o| DemoXmlTree( .F., o ) } )
      MenuUnDrop()
   MenuOption( "Tab" )
      MenuDrop()
      MenuOption( "1.Lenta",              { |o| DemoLenta( .F., o ) } )
      MenuOption( "2.Tab",                { |o| DemoTab( .F., o, aEndList ) } )
      MenuUnDrop()
   MenuOption( "Trackbar" )
      MenuDrop()
      MenuOption( "1.HTrack",             { |o| DemoHTrack( .F., o ) } )
#ifdef __PLATFORM__WINDOWS
      MenuOption( "2.Trackbar",           { |o| DemoTrackbar( .F., o ) } )
#endif
      MenuUnDrop()
   MenuOption( "Tree" )
      MenuDrop()
      MenuOption( "1.Tree",               { |o| DemoTree( .F., o, aInitList ) } )
      MenuOption( "2.Split",              { |o| DemoSplit( .F., o, aInitList ) } )
      MenuOption( "3.Splitter",           { |o| DemoSplitter( .F., o, aInitList ) } )
      MenuOption( "5.XML Tree",           { |o| DemoXmlTree( .F., o ) } )
      MenuUnDrop()
   MenuOption( "UpDown",                  { |o| DemoGetUpDown( .F., o ) } )
   MenuOption( "Others" )
      MenuDrop()
      MenuOption( "1.AppData",            { |o| DemoDbfData( .F., o, aEndList ) } )
      MenuOption( "2.Ini Files",          { |o| DemoIni( .F., o, aEndList ) } )
      MenuOption( "3.Timer",              { |o| DemoGet2( .F., o ) } )
      MenuUnDrop()

   @ 30, 60 TAB oTabLevel1 ITEMS {} SIZE 950, 650 OF oDlg

   FOR EACH aOption IN aMenuOptions

      BEGIN PAGE aOption[ 1 ] OF oTabLevel1

      // without sub-level
      IF Len( aOption[ 2 ] ) == 0
         IF ValType( aOption[ 3 ] ) == "C"   // can't run on tabpage use button
            @ 30, 50 BUTTON "run " + aOption[ 3 ] ;
               SIZE 200, 24 ;
               ON CLICK aOption[ 4 ]
         ELSE
            Eval( aOption[ 3 ], oTabLevel1 ) // ok display sample
         ENDIF
      ELSE
         // with sub-level, all again
         FOR EACH oTabLevel2 IN { Nil }

            @ 30, 30 TAB oTabLevel2 ITEMS {} SIZE 850, 550 OF oTabLevel1

            FOR EACH aOption2 IN aOption[ 2 ]

               BEGIN PAGE aOption2[ 1 ] OF oTabLevel2

               IF ValType( aOption2[ 3 ] ) == "C" // can't run on tabpage use button
                  @ 30, 50 BUTTON "run " + aOption2[ 3 ] ;
                     SIZE 200, 24 ;
                     ON CLICK aOption2[ 4 ]
               ELSE
                  Eval( aOption2[ 3 ], oTabLevel2 ) // ok display sample
               ENDIF

               END PAGE OF oTabLevel2

            NEXT
         NEXT
      ENDIF

      END PAGE OF oTabLevel1

   NEXT

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
CASE cFileName == "demogrid1.prg";       #pragma __binarystreaminclude "demogrid1.prg" | RETURN %s
CASE cFileName == "demogrid4.prg";       #pragma __binarystreaminclude "demogrid4.prg" | RETURN %s
CASE cFileName == "demogrid5.prg";       #pragma __binarystreaminclude "demogrid5.prg" | RETURN %s
CASE cFileName == "demohtrack.prg";      #pragma __binarystreaminclude "demohtrack.prg" | RETURN %s
CASE cFileName == "demoini.prg";         #pragma __binarystreaminclude "demoini.prg" | RETURN %s
CASE cFileName == "demolenta.prg";       #pragma __binarystreaminclude "demolenta.prg" | RETURN %s
CASE cFileName == "demolistbox.prg";     #pragma __binarystreaminclude "demolistbox.prg" | RETURN %s
CASE cFileName == "demolistboxsub.prg";  #pragma __binarystreaminclude "demolistboxsub.prg" | RETURN %s
CASE cFileName == "demomonthcal.prg";    #pragma __binarystreaminclude "demomonthcal.prg" | RETURN %s
CASE cFileName == "demomenu.prg";        #pragma __binarystreaminclude "demomenu.prg" | RETURN %s
CASE cFileName == "demomenuxml.prg";     #pragma __binarystreaminclude "demomenuxml.prg" | RETURN %s
CASE cFileName == "demoprogbar.prg";     #pragma __binarystreaminclude "demoprogbar.prg" | RETURN %s
CASE cFileName == "demoshadebtn.prg";    #pragma __binarystreaminclude "demoshadebtn.prg" | RETURN %s
CASE cFileName == "demotab.prg";         #pragma __binarystreaminclude "demotab.prg" | RETURN %s
CASE cFileName == "demotrackbar.prg";    #pragma __binarystreaminclude "demotrackbar.prg" | RETURN %s
CASE cFileName == "demotree.prg";        #pragma __binarystreaminclude "demotree.prg" | RETURN %s
CASE cFileName == "demosplit.prg";       #pragma __binarystreaminclude "demosplit.prg" | RETURN %s
CASE cFileName == "demosplitter.prg";    #pragma __binarystreaminclude "demosplitter.prg" | RETURN %s
CASE cFileName == "demoxmltree.prg";     #pragma __binarystreaminclude "demoxmltree.prg" | RETURN %s
ENDCASE

RETURN Nil

#include "demo.ch"

* ================================= EOF of all.prg ===========================
