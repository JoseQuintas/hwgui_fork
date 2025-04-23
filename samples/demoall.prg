/*
demoall.prg
menu for samples on samples/ folder

DF7BE:
This seems to be a bug in Harbour:
all.prg(182) Warning W0032  Variable 'CBINHBMK' is assigned but not used in function 'EXECUTEEXE(159)'

possible bug on windows 11:
status panel is not full on dialog first display, need to be up
Ok if use mouse and change dialog height
insert a dialog move on init ?
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

   LOCAL oDlg, aItem, nIndex := 1, lCloseMenu := .F., nCont
   LOCAL lIsAvailable, lIsEXE
   LOCAL oTab, oTab2, oTab3
   LOCAL aList := { ;
       ; // NAME,                  WIN, LINUX, MACOS, DESCRIPTION
       { "a.prg",                  .T., .F., .F., "MDI, Tab, checkbox, combobox, browse array, others" }, ;
       ;
       { "",                       .T., .F., .F., "" }, ;
       ;
       { "demodbfdata.prg",        .T., .T., .T., "DBF data using tab" }, ;
       { "demoini.prg",            .T., .F., .F., "Read/write Ini" }, ;
       { "demomenuxml.prg",        .T., .T., .T., "Setup menu from XML ***error on new item***" }, ;
       { "demoxmltree.prg",        .T., .T., .T., "Show XML using hxmldoc and tree" }, ;
       { "hello.prg",              .T., .F., .F., "RichEdit, Tab, Combobox" }, ;
       { "tab.prg",                .T., .F., .F., "Tab, checkbox, editbox, combobox, browse array" }, ;
       ;
       ; // controls
       ;
       { "demogetupdown.prg",      .T., .T., .T., "Get UpDown" }, ;
       { "testbrowsearr.prg",      .T., .T., .T., "browse array editable" }, ;
       { "democombobox.prg",       .T., .T., .T., "Combobox" }, ;
       { "demodatepicker.prg",     .T., .T., .T., "Date Picker" }, ;
       { "demolistbox.prg",        .T., .F., .F., "Listbox" }, ;
       { "demolistboxsub.prg",     .T., .T., .T., "Listbox Substitute" }, ;
       { "demoonother.prg",        .T., .F., .F., "ON OTHER MESSAGES" }, ;
       { "demotreebox",            .T., .T., .T., "Treebox, Splitter and tab" }, ;
       ;
       { "",                       .F., .F., .F., "" }, ;
       ;
       ; // not recommended. Move to contrib ?
       { "demoshadebtn.prg",        .T., .F., .F., "Shade button" }, ;
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
       { "testget2.prg",           .T., .F., .F., "Test Get 2" }, ;
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
       { "demotab",                .T., .T., .T., "Tab and more samples" } , ;
       ; // { "demobrowsedbf",          .T., .T., .T., "Browse DBF (demotab)"  }, ;
       ; // { "demomonthcal",           .T., .T., .T., "Month Calendar (demotab)" }, ;
       ; // { "demobrowseado.prg",      .T., .F., .F., "Browse using ADO (demotab)" }, ;
       ; // { "democheckbox",           .T., .T., .T., "Checkbox and tab (demotab)" }, ;
       ; // { "demomenu",               .T., .T., .T., "Simple menu" }, ;
       { "",                       .F., .F., .F., "" }, ;
       { "notexist",               .F., .F., .F., "Test for menu, about not available" } }

   INIT DIALOG oDlg ;
      TITLE "demoall.prg - Group Show Samples on screen, and others on menu" ;
      AT 0,0 ;
      SIZE 1024, 768 ;
      BACKCOLOR 16772062

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
      MENU TITLE "Other"
         MENUITEM "For tests check PRG/HBP/EXE" ACTION { || CheckPrgHbpExe() }
         MENUITEM "&Exit" ACTION hwg_EndWindow()
      ENDMENU
   ENDMENU

   @ 30, 60 TAB oTab ;
      ITEMS {} ;
      SIZE  700, 480

   BEGIN PAGE "menu" ;
      OF oTab

      @ 30, 50 BUTTON "demomenu.prg" ;
         SIZE 100, 24 ;
         ON CLICK { || DemoMenu() }

   END PAGE OF oTab

   BEGIN PAGE "say" ;
      OF oTab

      DemoSay( .F. )

   END PAGE OF oTab

   BEGIN PAGE "button" ;
      OF oTab

      DemoButton( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "browse" ;
      OF oTab

      @ 30, 30 TAB oTab2 ;
         ITEMS {} ;
         SIZE  650, 450

         BEGIN PAGE "browse array" ;
            OF oTab2

            DemoBrowseArray( .F., oTab2 )

         END PAGE OF oTab2

         BEGIN PAGE "browse dbf" ;
            OF oTab2

            DemoBrowseDBF( .F., oTab2 )

         END PAGE OF oTab2

#ifdef __PLATFORM__WINDOWS
         BEGIN PAGE "browseado" ;
            OF oTab2

            DemoBrowseADO( .F., oTab2 )

         END PAGE OF oTab2
#endif

   END PAGE OF oTab

   BEGIN PAGE "tab" ;
      OF oTab

      DemoTab( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "combobox" ;
      OF oTab

      DemoCombobox( .F., oTab )

   END PAGE of oTab

   BEGIN PAGE "checkbox" ;
      OF oTab

      DemoCheckBox( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "demotreebox" ;
      OF oTab

      DemoTreebox( .F., oTab )

   END PAGE OF oTab

   BEGIN PAGE "date" ;
      OF oTab

      @ 30, 30 TAB oTab3 ;
         ITEMS {} ;
         SIZE  650, 450

      BEGIN PAGE "dateselect" ;
         OF oTab3

         DemoDateSelect( .F., oTab3 )

      END PAGE OF oTab3

#ifdef __PLATFORM__WINDOWS

      BEGIN PAGE "monthcal" ;
         OF oTab3

         DemoMonthCal( .F., oTab3 )

      END PAGE OF oTab3
#endif

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

STATIC FUNCTION CheckPrgHbpExe()

   LOCAL aItem, cFile, lWithHbp, lWithExe
   LOCAL cTxtPrg := "No HBP without EXE" + hb_Eol() + hb_Eol()
   LOCAL cTxtHbp := "HBP without EXE" + hb_Eol() + hb_Eol()

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
STATIC FUNCTION DemoSay()

   @ 10, 50 SAY "a text" ;
      SIZE 80, 30

   @ 10, 100 SAY "Need SIZE (*)" ;
      SIZE 300, 30

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
STATIC FUNCTION DemoCombobox()

   LOCAL oCombo1, oCombo2
   LOCAL aComboList  := { "White", "Blue", "Red", "Black" }

#ifndef __PLATFORM__WINDOWS
   @ 10, 50 COMBOBOX oCombo1 ;
      ITEMS aComboList ;
      SIZE  100, 25              // size for GTK

   oCombo2 := Nil // ok, warning -w3 -es2 require value
   (oCombo2)      // ok, warning -w3 -es2 require use
#else
   @ 10, 50 COMBOBOX oCombo1 ;
      ITEMS aComboList ;
      SIZE  100, 100             // size for GTK

   @ 100, 50 COMBOBOX oCombo2 ;
      ITEMS   aComboList ;
      SIZE    100, 100 ;
      EDIT                       // crash on GTK
#endif

   @ 10, 200 SAY "size height include list height on win" ;
      SIZE 300, 30

   RETURN Nil

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
STATIC FUNCTION DemoButton( lWithDialog, oDlg )

   LOCAL oBtn1, oBtn2, oBtn3
   LOCAL oStyleNormal  := HStyle():New( {16759929,16772062}, 1 )
   LOCAL oStylePressed := HStyle():New( {16759929}, 1,, 3, 0 )
   LOCAL oStyleOver    := HStyle():New( {16759929}, 1,, 2, 12164479 )
   LOCAL aBtn2Style    := { ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 2,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 2, 8421440 ) }

   @ 10, 50 OWNERBUTTON oBtn1 ;
      OF       oDlg ;
      SIZE     60, 24;
      TEXT     "But.1" ;
      ON CLICK { || hwg_MsgInfo( "Button 1" ) }

   @ 74, 50 OWNERBUTTON oBtn2 ;
      OF       oDlg ;
      SIZE     60, 24 ;
      TEXT     "But.2" ;
      ON CLICK { || hwg_MsgInfo( "Button 2" ) }
   oBtn2:aStyle := aBtn2Style

   @ 138, 50 OWNERBUTTON oBtn3 ;
      OF       oDlg ;
      SIZE     60, 24 ;
      HSTYLES oStyleNormal, oStylePressed, oStyleOver ;
      TEXT     "But.3" ;
      ON CLICK { || hwg_MsgInfo( "Button 3" ) }

   (lWithDialog) // not used, warning -w3 -es2

   RETURN Nil

* ================================= EOF of all.prg ===========================
