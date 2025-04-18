/*
 demomenumt.prg
 menu using multithread
 need demobrowsedbf.prg
 compile using -mt

CAUTION

- *** MT is experimental ***

- *** Make your own tests with another multithread GT ***

- If do not build hwgui using HB_GUI_MT_EXPERIMENTAL,
  need to close dialogs in reverse order of open

- If use INIT WINDOW it crashes.

- Using multithread, when a module crashes,
  may be needed to close on task manager.

- I use Windows only, but I am using more than this:
  I am using GTWVG, HWGUI and other GUI library together
  I think default harbour GUI GT is valid, on Windows is GTWVT
*/

#include "hbgtinfo.ch"
#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDlg, nCont := 1

   INIT DIALOG oDlg ;
      TITLE "demomenumt.prg - Menu using Multithread" ;
      AT 200,0 ;
      SIZE 400,150

   MENU OF oDlg
      MENUITEM "&Exit" ACTION hwg_EndDialog()
      MENUITEM "&Browse DBF" ACTION hb_ThreadStart( { || DoMt( nCont++ ) } )
   ENDMENU

   ACTIVATE DIALOG oDlg

   hb_ThreadWaitForAll()

   RETURN Nil

STATIC FUNCTION DoMt( nCont )

   hb_gtReload( hb_gtInfo( HB_GTI_VERSION ) )
   hwg_initProc() // init hwgui on thread
   DemoBrowseDBF( nCont )

   RETURN Nil

