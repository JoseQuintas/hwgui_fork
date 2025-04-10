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
   LOCAL aList := { ;
       ; // NAME,     WIN, LINUX, MACOS, DESCRIPTION
       { "DLGBRWDBF",    .T., .T., .T., "Browse DBF"  }, ;
       { "DLGCOMBO",     .T., .T., .T., "Combobox" }, ;
       { "DLGDPICK",     .T., .T., .T., "Date Picker" }, ;
       { "DLGBOT",       .T., .F., .F., "ON OTHER MESSAGES" }, ;
       { "DLGSHADEBTN",  .T., .F., .F., "Shade button" }, ;
       { "DLGHMONTH",    .T., .T., .T., "Month Calendar" }, ;
       { "DLGSPLIT",     .T., .T., .T., "Splitter" }, ;
       { "DLGXML",       .T., .T., .T., "Setup from XML" }, ;
       { "DLGMENU1",     .T., .T., .T., "Menu using desktop Size" }, ;
       { "DLGMDI",       .T., .F., .F., "MDI Window" } }

   INIT DIALOG oDlg TITLE "ALL - Samples without own hbp" ;
     AT 0,0 SIZE 600, 400

   MENU OF oDlg
      FOR nCont = 1 TO Len( aList ) // not sure about xharbour for/each
         IF Mod( nCont, 10 ) == 1 // 10 options by group
            MENU TITLE "Samples" + Str( nIndex, 1 )
            nIndex     += 1
            lCloseMenu := .T.
         ENDIF
         FOR EACH aItem IN { aList[ nCont ] } // special var aItem on codeblock
            IF aItem[ __IS_AVAILABLE ]
               MENUITEM aItem[ 1 ] + " - " + aItem[ 5 ] ACTION { || Do( aItem[ 1 ] ) }
            ELSE
               MENU TITLE aItem[ 1 ] + " - " + aItem[ 5 ] + " not available"
            ENDIF
         NEXT
         IF Mod( nCont, 10 ) == 0 // 10 options by group
            ENDMENU
            lCloseMenu := .F.
         ENDIF
      NEXT
      IF lCloseMenu // close menu if < 10
         ENDMENU
      ENDIF
      MENUITEM "&Exit" ACTION hwg_EndDialog()
   ENDMENU

   ACTIVATE DIALOG oDlg CENTER

   RETURN
