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

   LOCAL oDlg, aItem
   LOCAL aList := { ;
       ; // NAME,     WIN, LINUX, MACOS, DESCRIPTION
       { "DLGBRWDBF", .T., .T., .T., "Browse DBF"  }, ;
       { "DLGCOMBO",  .T., .T., .T., "Combobox" }, ;
       { "DLGDPICK",  .T., .T., .T., "Date Picker" }, ;
       { "DLGMENU1",  .T., .T., .T., "Menu using desktop Size" }, ;
       { "DLGBOT",    .T., .F., .F., "ON OTHER MESSAGES" }, ;
       { "DLGSPLIT",  .T., .T., .T., "Splitter" }, ;
       { "DLGXML",    .T., .T., .T., "Setup from XML" }, ;
       { "DLGMDI",    .T., .F., .F., "MDI Window" } }

   INIT DIALOG oDlg TITLE "ALL - Samples without own hbp" ;
     AT 0,0 SIZE 600, 400

   MENU OF oDlg
      MENU TITLE "Samples"
         FOR EACH aItem IN aList
            IF aItem[ __IS_AVAILABLE ]
               MENUITEM aItem[ 1 ] + " - " + aItem[ 5 ] ACTION { || Do( aItem[ 1 ] ) }
            ELSE
               MENU TITLE aItem[ 1 ] + " - " + aItem[ 5 ] + " not available"
               ENDMENU
            ENDIF
         NEXT
      ENDMENU
      MENUITEM "&Exit" ACTION hwg_EndDialog()
   ENDMENU

   ACTIVATE DIALOG oDlg CENTER

   RETURN
