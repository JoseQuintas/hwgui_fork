/*
all.prg
menu for standard samples

First test
Only samples without own hbp
Remember to change all.hbp about Windows, Linux, MacOS
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

PROCEDURE Main

   LOCAL oDlg, aItem, nIndex := 1, lCloseMenu := .F., nCont
   LOCAL lIsAvailable, lIsEXE
   LOCAL aList := { ;
       ; // NAME,          WIN, LINUX, MACOS, DESCRIPTION
       { "A.EXE",           .T., .F., .F., "All" }, ;
       { "ARRAYBROWSE.EXE", .T., .T., .T., "Array browse" }, ;
       { "CHECKBOX.EXE",    .T., .T., .T., "Check box" }, ;
       { "COLRBLOC.EXE",    .T., .T., .T., "Color Block" }, ;
       { "DBVIEW.EXE",      .T., .T., .T., "DBView" }, ;
       { "DEMODBF.EXE",     .T., .T., .T., "DBF" }, ;
       { "DEMOHLIST.EXE",   .T., .F., .F., "HList" }, ;
       { "DEMOHLISTSUB.EXE",.T., .T., .T., "HList Sub" }, ;
       { "DIALOGBOXES.EXE", .T., .T., .T., "Dialogboxes" }, ;
       { "DLGBRWDBF",       .T., .T., .T., "Browse DBF"  }, ;
       { "DLGCOMBO",        .T., .T., .T., "Combobox" }, ;
       { "DLGDPICK",        .T., .T., .T., "Date Picker" }, ;
       { "DLGBOT",          .T., .F., .F., "ON OTHER MESSAGES" }, ;
       { "DLGSHADEBTN",     .T., .F., .F., "Shade button" }, ;
       { "DLGHMONTH",       .T., .T., .T., "Month Calendar" }, ;
       { "DLGSPLIT",        .T., .T., .T., "Splitter" }, ;
       { "DLGXML",          .T., .T., .T., "Setup from XML" }, ;
       { "DLGMENU1",        .T., .T., .T., "Menu using desktop Size" }, ;
       { "ESCRITA.EXE",     .T., .T., .T., "Escrita" }, ;
       { "FILESELECT.EXE",  .T., .T., .T., "File Select" }, ;
       { "GETUPDOWN",       .T., .T., .T., "Get UpDown" }, ;
       { "GRAPH.EXE",       .T., .T., .T., "Graph" }, ;
       { "GRID_1.EXE",      .T., .F., .F., "Grid1" }, ;
       { "GRID_2.EXE",      .F., .F., .F., "Grid2 PostGres" }, ;
       { "GRID_3.EXE",      .F., .F., .F., "Grid3 PostGres" }, ;
       { "GRID_4.EXE",      .T., .F., .F., "Grid4" }, ;
       { "GRID_5.EXE",      .T., .F., .F., "Grid5" }, ;
       { "HELLO.EXE",       .T., .F., .F., "RichEdit, Tab, Combobox" }, ;
       { "HELPSTATIC.EXE",  .T., .T., .T., "Help Static" }, ;
       { "HTRACK.EXE",      .T., .T., .T., "HTrack" }, ;
       { "NICE;EXE",        .T., .F., .F., "Nice button" }, ;
       { "ICONS.EXE",       .T., .T., .T., "Icons" }, ;
       { "ICONS2.EXE",      .T., .T., .T., "Icons2" }, ;
       { "TAB.EXE",         .T., .F., .F., "Tab, checkbox, editbox, combobox, browse array" }, ;
       { "TESTADO.EXE",     .T., .F., .F., "Test ADO" }, ;
       { "TESTALERT.EXE",   .T., .F., .F., "Test Alert" }, ;
       { "TESTBRW.EXE",     .T., .F., .F., "Test browse" }, ;
       { "TESTGET1.EXE",    .T., .F., .F., "Test Get 1" }, ;
       { "TESTGET2.EXE",    .T., .F., .F., "Test Get 2" }, ;
       { "TESTHGT.EXE",     .T., .T., .T., "Test HGT" }, ;
       { "TESTINI.,EXE",    .T., .F., .F., "Test Ini" }, ;
       { "TESTMENUBITMAP.EXE",.T.,.F.,.F., "Test Menu Bitmap" }, ;
       { "TESTRTF.EXE",     .T., .F., .F., "Test RTF" }, ;
       { "TESTSDI.EXE",     .T., .T., .T., "Menu, Tree and Splitter" }, ;
       { "TSTSCRLBAR.EXE",  .T., .T., .T., "Scrollbar" }, ;
       { "TSTSPLASH.EXE",   .T., .F., .F., "Test Splash" }, ;
       { "TWOLISTBOX.EXE",  .T., .F., .F., "Two List Box" }, ;
       { "QRENCODE.EXE",    .T., .F., .F., "QREncode ***need extra setup***" }, ;
       { "QRENCODEDLL.EXE", .T., .F., .F., "QREncodedll ***need extra setup***" }, ;
       { "HELPDEMO.EXE",    .T., .T., .T., "Help Demo ***outdated***" }, ;
       { "HOLE.EXE",        .T., .F., .F., "Ole ***error***" }, ;
       { "IESAMPLE.EXE",    .T., .F., .F., "IE sample ***outdated***" }, ;
       { "NICE2.EXE",       .T., .F., .F., "Nice button 2 ***error***" }, ;
       { "PROPSH.EXE",      .T., .F., .F., "Propsheet ***error***" }, ;
       { "TESTCHILD.EXE",   .T., .F., .F., "Test Child ***error***" }, ;
       { "TESTTRAY.EXE",    .T., .F., .F., "Test Tray ***Error***" }, ;
       { "TSTPRDOS.EXE",    .T., .F., .F., "test DOS ***outdated***" }, ;
       { "NOTEXIST",        .F., .F., .F., "Test for menu, about not available" } }

   INIT WINDOW oDlg MAIN TITLE "ALL - Samples without own hbp" ;
     AT 0,0 SIZE 600, 400

   MENU OF oDlg
      FOR nCont = 1 TO Len( aList ) // not sure about Xharbour for/each
         IF Mod( nCont, 10 ) == 1 // 10 options by group
            MENU TITLE "Samples" + Str( nIndex, 1 )
            nIndex     += 1
            lCloseMenu := .T.
         ENDIF
         FOR EACH aItem IN { aList[ nCont ] } // for/each isolate aItem to codeblock
            lIsAvailable := aItem[ __IS_AVAILABLE ]
            lIsExe       := Right( aItem[ 1 ], 4 ) == ".EXE"
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
      MENUITEM "&Exit" ACTION hwg_EndWindow()
   ENDMENU

   ACTIVATE WINDOW oDlg CENTER

   RETURN

/*
TODO: Adjust for Linux and MacOS
*/

STATIC FUNCTION ExecuteExe( cFileName )

   IF ! File( cFileName )
      IF ! hwg_MsgYesNo( cFileName + " not found, try create it?" )
         RETURN Nil
      ENDIF
      RUN ( "hbmk2 " + Left( cFileName, At( ".", cFileName ) - 1 ) )
      IF ! File( cFileName )
         hwg_MsgInfo( "Can't create " + cFileName )
         RETURN Nil
      ENDIF
   ENDIF
   RUN ( cFileName )

   RETURN Nil
