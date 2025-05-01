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

FUNCTION Main()

   LOCAL oDlg, aInitList := {}, aEndList := {}, bCode

   INIT DIALOG oDlg ;
      TITLE "demoall.prg - Show Samples on screen, and others on menu" ;
      AT 0,0 ;
      SIZE 1024, 768 ;
      BACKCOLOR 16772062 ;
      STYLE WS_POPUP + WS_CAPTION + WS_MAXIMIZEBOX + WS_MINIMIZEBOX + WS_SYSMENU ;
      ON INIT { || DemoAllEvalList( aInitList ) }

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

STATIC FUNCTION DemoAllEvalList( aCodeList )

   LOCAL bCode

   FOR EACH bCode IN aCodeList
      Eval( bCode )
   NEXT

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
      MenuOption( "5.Grid4",              { |o| DemoGrid4( .F., o, aEndList ) } )
      MenuOption( "6.Grid5",              { |o| DemoGrid5( .F., o, aInitList, aEndList ) } )
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
   MenuOption( "Radiobutton",             { |o| DemoGet1( .F., o ) } )
   MenuOption( "Get" )
      MenuDrop()
      MenuOption( "1.DemoGet2",             { |o| DemoGet2( .F., o ) } )
      MenuOption( "2.Editbox",              { |o| DemoIni( .F., o, aEndList ) } )
      MenuOption( "3.DateSelect",           { |o| DemoDateSelect( .F., o ) } )
      MenuOption( "4.Datepicker",           { |o| DemoGet1( .F., o ) } )
      MenuOption( "5.Simple Edit", "demosedit.prg", { || DemoSEdit() } )
      MenuUnDrop()
   MenuOption( "Image" )
      MenuDrop()
      MenuOption( "1.DemoImage2",                      { |o| DemoImage2( .F., o ) } )
      MenuOption( "2.demobitmap",                      { |o| DemoBitmap( .F., o ) } )
      MenuOption( "3.DemoImage1", "demoimage1.prg",    { || DemoImage1() } )
      MenuOption( "4.Image view", "demoimageview.prg", { || demoimageview() } )
      MenuUnDrop()
   MenuOption( "Listbox" )
      MenuDrop()
      MenuOption( "1.Listbox Alt",        { |o| DemoListBoxSub( .F., o ) } )
      MenuUndrop()
   MenuOption( "Menu" )
      MenuDrop()
      MenuOption( "1.menu",    "demomenu.prg",    { || DemoMenu() } )
      MenuOption( "2.menuxml", "demomenuxml.prg", { || DemoMenuXml() } )
#ifdef __PLATFORM__WINDOWS
      MenuOption( "3.menubitmap","demomenubitmap.prg", { || DemoMenuBitmap() } )
#endif
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
      MenuOption( "3.Dlgbox",             { |o| DemoDlgBox( .F., o ) } )
#ifdef __PLATFORM__WINDOWS
      MenuOption( "4.MonthCal",           { |o| DemoMonthCal( .F., o ) } )
#endif
      MenuOption( "5.Timer",              { |o| DemoGet2( .F., o ) } )
      MenuOption( "6.Functions",          { |o| DemoFunc( .F., o ) } )
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

   BEGIN PAGE "ToCompile" OF oTabLevel1

      AddToCompile( oTabLevel1 )

   END PAGE OF oTabLevel1

   RETURN Nil

STATIC FUNCTION AddToCompile( oTabLevel1 )

   LOCAL aList := { ;
       ; // NAME,                  WIN, LINUX, MACOS, DESCRIPTION
       ;
       ;  // neeed compile
       ;
       { "a.prg",                  .T., .F., .F., "MDI, Tab, checkbox, combobox, browse array, others" }, ;
       { "demomdi.prg",            .T., .F., .F., "MDI window" }, ;
       { "demoonother.prg",        .T., .F., .F., "ON OTHER MESSAGES" }, ;
       { "nice.prg",               .T., .F., .F., "Nice button, only WINDOW, not DIALOG" }, ;
       { "tstscrlbar.prg",         .T., .T., .T., "Scrollbar" }, ;
       ;
       ; // verify
       ;
       { "graph.prg",              .T., .T., .T., "Graph" }, ;
       ;
       { "tab.prg",                .T., .F., .F., "Tab, checkbox, editbox, combobox, browse array" }, ;
       { "testbrowsearr.prg",      .T., .T., .T., "browse array editable" }, ;
       { "colrbloc.prg",           .T., .T., .T., "Color Block" }, ;
       { "dbview.prg",             .T., .T., .T., "DBView" }, ;
       { "fileselect.prg",         .T., .T., .T., "File Select" }, ;
       { "helpstatic.prg",         .T., .T., .T., "Help Static" }, ;
       { "testbrw.prg",            .T., .F., .F., "Test browse" }, ;
       { "tstsplash.prg",          .T., .F., .F., "Test Splash" }, ;
       { "twolistbox.prg",         .T., .F., .F., "Two List Box" }, ;
       ;
       ; // try later
       ;
       { "escrita.prg",            .T., .T., .T., "Escrita" }, ;
       { "hello.prg",              .T., .F., .F., "RichEdit, Tab, Combobox" }, ;
       { "grid_2.prg",             .F., .F., .F., "Grid2 PostGres" }, ;
       { "grid_3.prg",             .F., .F., .F., "Grid3 PostGres" }, ;
       { "helpdemo.prg",           .T., .T., .T., "Help Demo ***outdated***" }, ;
       { "hole.prg",               .T., .F., .F., "Ole ***error***" }, ;
       { "nice2.prg",              .T., .F., .F., "Nice button 2 ***?***" }, ;
       { "propsh.prg",             .T., .F., .F., "Propsheet ***error***" }, ;
       { "testalert.prg",          .T., .F., .F., "Test Alert" }, ;
       { "testrtf.prg",            .T., .F., .F., "Test RTF" }, ;
       { "testtray.prg",           .T., .F., .F., "Test Tray ***Error***" }, ;
       { "tstprdos.prg",           .T., .F., .F., "test DOS ***outdated***" } }

   LOCAL oTab, aOption, lClosePage, nCount, lIsAvailable, nPage

   @ 30, 60 TAB oTab ITEMS {} SIZE 950, 650 OF oTabLevel1

   lClosePage := .F.
   nCount     := 0
   nPage      := 1
   FOR EACH aOption IN aList
      lIsAvailable := aOption[ __IS_AVAILABLE ]
      IF lIsAvailable
         IF Mod( nCount, 10 ) == 0
            IF lClosePage
               END PAGE OF oTab
            ENDIF
            BEGIN PAGE "ToCompile" + Str( nPage, 1 ) OF oTab
            lClosePage := .T.
            nCount     := 0
            nPage      += 1
         ENDIF
         @ 10, 60 + ( nCount * 30 ) BUTTON aOption[1] ;
            OF oTab ;
            SIZE 150, 24 ;
            ON CLICK { || ExecuteExe( aOption[ 1 ] ) }

         @ 200, 60 + ( nCount * 30 ) SAY aOption[ 5 ] ;
            SIZE 400, 24

         nCount += 1

      ENDIF
   NEXT
   IF lClosePage
      END PAGE OF oTab
   ENDIF

   RETURN Nil

// only test
FUNCTION LoadResourceDemo( cFileName )

DO CASE
CASE cFileName == "demo.ch";             #pragma __binarystreaminclude "demo.ch" | RETURN %s
CASE cFileName == "demoall.prg";         #pragma __binarystreaminclude "demoall.prg" | RETURN %s
CASE cFileName == "demobitmap.prg";      #pragma __binarystreaminclude "demobitmap.prg" | RETURN %s
CASE cFileName == "democheckbox.prg";    #pragma __binarystreaminclude "democheckbox.prg" | RETURN %s
CASE cFileName == "democombobox.prg";    #pragma __binarystreaminclude "democombobox.prg" | RETURN %s
CASE cFileName == "demobrowsedbf.prg";   #pragma __binarystreaminclude "demobrowsedbf.prg" | RETURN %s
CASE cFileName == "demobrowseado.prg";   #pragma __binarystreaminclude "demobrowseado.prg" | RETURN %s
CASE cFileName == "demodbfdata.prg";     #pragma __binarystreaminclude "demodbfdata.prg" | RETURN %s
CASE cFileName == "demodlgbox.prg";      #pragma __binarystreaminclude "demodlgbox.prg" | RETURN %s
CASE cFileName == "demofunc.prg";        #pragma __binarystreaminclude "demofunc.prg" | RETURN %s
CASE cFileName == "demogetupdown.prg";   #pragma __binarystreaminclude "demogetupdown.prg" | RETURN %s
CASE cFileName == "demoget1.prg";        #pragma __binarystreaminclude "demoget1.prg" | RETURN %s
CASE cFileName == "demoget2.prg";        #pragma __binarystreaminclude "demoget2.prg" | RETURN %s
CASE cFileName == "demogrid1.prg";       #pragma __binarystreaminclude "demogrid1.prg" | RETURN %s
CASE cFileName == "demogrid4.prg";       #pragma __binarystreaminclude "demogrid4.prg" | RETURN %s
CASE cFileName == "demogrid5.prg";       #pragma __binarystreaminclude "demogrid5.prg" | RETURN %s
CASE cFileName == "demohtrack.prg";      #pragma __binarystreaminclude "demohtrack.prg" | RETURN %s
CASE cFileName == "demoini.prg";         #pragma __binarystreaminclude "demoini.prg" | RETURN %s
CASE cFileName == "demoimage1.prg";      #pragma __binarystreaminclude "demoimage1.prg" | RETURN %s
CASE cFileName == "demoimage2.prg";      #pragma __binarystreaminclude "demoimage2.prg" | RETURN %s
CASE cFileName == "demolenta.prg";       #pragma __binarystreaminclude "demolenta.prg" | RETURN %s
CASE cFileName == "demolistbox.prg";     #pragma __binarystreaminclude "demolistbox.prg" | RETURN %s
CASE cFileName == "demolistboxsub.prg";  #pragma __binarystreaminclude "demolistboxsub.prg" | RETURN %s
CASE cFileName == "demomenubitmap.prg";  #pragma __binarystreaminclude "demomenubitmap.prg" | RETURN %s
CASE cFileName == "demomonthcal.prg";    #pragma __binarystreaminclude "demomonthcal.prg" | RETURN %s
CASE cFileName == "demomenu.prg";        #pragma __binarystreaminclude "demomenu.prg" | RETURN %s
CASE cFileName == "demomenuxml.prg";     #pragma __binarystreaminclude "demomenuxml.prg" | RETURN %s
CASE cFileName == "demoprogbar.prg";     #pragma __binarystreaminclude "demoprogbar.prg" | RETURN %s
CASE cFileName == "demosedit.prg";       #pragma __binarystreaminclude "demosedit.prg" | RETURN %s
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
