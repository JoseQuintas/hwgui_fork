/*
demomdi.prg
*/

#include "hwgui.ch"

FUNCTION DemoMDI()

   LOCAL oDlg
   LOCAL cSampleName := "demotrackbar.prg"
   LOCAL bCodeSample := { |o| DemoTrackBar( .F., o ) }

   INIT WINDOW oDlg ;
      MDI ;
      TITLE "Test samples" ;
      SIZE 1024, 768 ;
      BACKCOLOR 16772062

   MENU OF oDlg
      MENU TITLE "ExecuteSample"
         MENUITEM cSampleName ACTION DlgSample( cSampleName, bCodeSample )
      ENDMENU
      MENU TITLE "Option"
         MENUITEM "Window" ID 1001 ;
            ACTION hwg_CheckMenuItem( , 1001, ! hwg_IsCheckedMenuItem( , 1001 ) )
         MENUITEM "Tabpage" ID 1002 ;
            ACTION hwg_CheckMenuItem( , 1002, ! hwg_IsCheckedMenuItem( , 1002 ) )
         MENUITEM "Tabpage 2" ID 1003 ;
            ACTION hwg_CheckMenuItem( , 1003, ! hwg_IsCheckedMenuItem( , 1003 ) )
         MENUITEM "Panel" ID 1004 ;
            ACTION hwg_CheckMenuItem( , 1004, ! hwg_IsCheckedMenuItem( , 1004 ) )
         MENUITEM "MDI" ID 1005 ;
            ACTION hwg_CheckMenuItem( , 1005, ! hwg_IsCheckedMenuItem( , 1005 ) )
      ENDMENU
      MENU TITLE "Window"
         MENUITEM "Tile Horizontal"  ;
            ACTION  hwg_Sendmessage( HWindow():GetMain():handle, WM_MDITILE, MDITILE_HORIZONTAL, 0 )
         MENUITEM "Tile Vertical" ;
            ACTION hwg_Sendmessage( HWindow():GetMain():handle, WM_MDITILE, MDITILE_VERTICAL, 0 )
         MENUITEM "Cascade" ;
            ACTION hwg_Sendmessage( HWindow():GetMain():handle, WM_MDICASCADE, 0, 0 )
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oDlg CENTER

   RETURN Nil

STATIC FUNCTION DlgSample( cSampleName, bCodeSample )

   LOCAL oDlg, oTab, oPanel, nCont, nPageCount := 0
   LOCAL lIsWindow, lIsTabPage, lIsTabPage2, lIsPanel, lIsMDI

   lIsWindow    := hwg_IsCheckedMenuItem( ,1001 )
   lIsTabPage   := hwg_IsCheckedMenuItem( ,1002 )
   lIsTabPage2  := hwg_IsCheckedMenuItem( ,1003 )
   lIsPanel     := hwg_IsCheckedMenuItem( ,1004 )
   lIsMDI       := hwg_IsCheckedMenuItem( ,1005 )

   nPageCount += iif( lIsTabPage, 1, 0 )
   nPageCount += iif( lIsTabPage2, 1, 0 )

   DO CASE
   CASE lIsMDI

      INIT WINDOW oDlg ;
         MDICHILD ;
         TITLE cSampleName ;
         SIZE 800, 600 ;
         STYLE WS_VISIBLE + WS_OVERLAPPEDWINDOW

   CASE lIsWindow

      INIT WINDOW oDlg ;
         TITLE cSampleName ;
         SIZE 800, 600 ;
         STYLE WS_VISIBLE + WS_OVERLAPPEDWINDOW

   OTHERWISE

      INIT DIALOG oDlg ;
         TITLE cSampleName ;
         SIZE 800, 600 ;
         STYLE WS_VISIBLE + WS_OVERLAPPEDWINDOW

   ENDCASE

   IF lIsTabPage .OR. lIsTabPage2
      @ 3, 10 TAB oTab ;
         ITEMS {} ;
         OF oDlg ;
         SIZE 700, 500 ;
         STYLE SS_OWNERDRAW
   ELSE
      IF lIsPanel
         @ 3, 100 PANEL oPanel ;
            SIZE 700, 500 ;
            STYLE SS_OWNERDRAW ;
            BACKCOLOR 16772062
      ENDIF
      Eval( bCodeSample, iif( lIsPanel, oPanel, oDlg ) )
   ENDIF

   FOR nCont = 1 TO nPageCount

      BEGIN PAGE "TabPage" OF oTab

      IF lIsPanel
         @ 3, 60 PANEL oPanel ;
            SIZE 700, 500 ;
            STYLE SS_OWNERDRAW ;
            BACKCOLOR 16772062
      ENDIF

      Eval( bCodeSample, iif( lIsPanel, oPanel, oTab ) )

      END PAGE OF oTab

   NEXT

   DO CASE
   CASE lIsMDI
      ACTIVATE WINDOW oDlg
   CASE lIsWindow
      // ACTIVATE WINDOW oDlg CENTER
      hwg_MsgInfo( "Not available" )
      RETURN Nil
   OTHERWISE
      ACTIVATE DIALOG oDlg CENTER
   ENDCASE

   (oTab) := Nil       // warning -w3 -es2
   (oTab)

   RETURN Nil
