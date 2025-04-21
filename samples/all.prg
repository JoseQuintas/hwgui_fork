/*
all.prg
menu for samples on samples/ folder

DF7BE:
This seems to be a bug in Harbour:
all.prg(182) Warning W0032  Variable 'CBINHBMK' is assigned but not used in function 'EXECUTEEXE(159)'

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
   LOCAL aList := { ;
       ; // NAME,                  WIN, LINUX, MACOS, DESCRIPTION
       { "a.prg",                  .T., .F., .F., "MDI, Tab, checkbox, combobox, browse array, others" }, ;
       ;
       { "",                       .F., .F., .F., "" }, ;
       ;
       { "demotab",                .T., .T., .T., "Tab and more samples" } , ;
       { "demobrowsedbf",          .T., .T., .T., "Browse DBF (demotab)"  }, ;
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
       { "demobrowsearr.prg",      .T., .T., .T., "browse array editable" }, ;
       { "democheckbox.prg",       .T., .T., .T., "Checkbox and tab" }, ;
       { "democombobox.prg",       .T., .T., .T., "Combobox" }, ;
       { "demodatepicker.prg",     .T., .T., .T., "Date Picker" }, ;
       { "demolistbox.prg",        .T., .F., .F., "Listbox" }, ;
       { "demolistboxsub.prg",     .T., .T., .T., "Listbox Substitute" }, ;
       { "demomonthcal.prg",       .T., .T., .T., "Month Calendar" }, ;
       { "demoonother.prg",        .T., .F., .F., "ON OTHER MESSAGES" }, ;
       { "demotreebox.prg",        .T., .T., .T., "Treebox, Splitter and tab" }, ;
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
       { "testado.prg",            .T., .F., .F., "Test ADO" }, ;
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
       { "",                       .F., .F., .F., "" }, ;
       { "notexist",               .F., .F., .F., "Test for menu, about not available" } }

   INIT WINDOW oDlg ;
      MAIN ;
      TITLE "ALL - Samples list-------------------------------------" ;
      AT 0,0 ;
      SIZE 800, 600

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
         MENUITEM "Check PRG/HBP/EXE" ACTION { || CheckPrgHbpExe() }
         MENUITEM "&Exit" ACTION hwg_EndWindow()
      ENDMENU
   ENDMENU

   DemoTab( .F. )

   ACTIVATE WINDOW oDlg CENTER

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

   LOCAL aItem, cFile, cTxt := "", lWithHbp, lWithExe

   FOR EACH aItem IN Directory( "*.prg" )
      cFile := aItem[ F_NAME ]
      cFile := Substr( cFile, 1, Len( cFile ) - 4 )
      lWithHbp := File( cFile + ".hbp" )
      lWithExe := File( cFile + ".exe" )
      IF ! ( lWithHbp .AND. lWithExe )
         cTxt += Pad( cFile, 20 )
         cTxt += "HBP_" + iif( lWithHbp, "Yes", "No " )
         cTxt += "EXE_" + iif( lWithExe, "Yes", "No " )
         cTxt += hb_Eol()
      ENDIF
   NEXT
   hwg_MsgInfo( cTxt )

   RETURN Nil

* ================================= EOF of all.prg ===========================
