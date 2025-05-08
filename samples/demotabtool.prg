* Sample program for tabs with tooltips
* TNX to Alain Aupeix
* Support ticket #54 "Tooltip for tabs ?"

/*
 * $Id$ dmotabtool.prg
 *
 * Copyright 2022 Alain Aupeix
 */

/*
  Advice to mouse position:
  The tooltip is forever displayed of the active tab,
  if the mouse pointer is positioned on the headline of another tab.
  We suggest to add to the headline text the name of the tab in the tooltext string.
  This should show the user, for which tab the displayed tooltip is valid.
*/

#include "hwgui.ch"

FUNCTION DemoTabTool( lWithDialog, oDlg )

   LOCAL oTab, oToolbar, cTooltip1:="This is the first tab", cTooltip2:="This is the second tab"
   LOCAL oButton

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demotabtool.pg - Test tabs with tooltip" ;
         AT 168,50 ;
         SIZE 640, 480 ;
         BACKCOLOR hwg_ColorC2N("#DCDAFF")
   ENDIF

   ButtonForSample( "demotabtool.prg", oDlg )

  // Toolbar
  @ 0,0 PANEL oToolbar ;
     SIZE 0,32

  @ 400, 60 BUTTON oButton ;
     CAPTION "Quit";
     ON CLICK { || iif( lWithDialog, ;
                        iif( AskYesNo( oDlg ), oDlg:Close(), Nil ), ;
                        hwg_MsgInfo( "No action here" ) ) } ;
     SIZE 40,24 ;
     COLOR hwg_ColorC2N("#FF0000") ;
     TOOLTIP "Quit ?"

  @ 10, 60 TAB oTab ;
     ITEMS {} ;
     SIZE 380, 190

  BEGIN PAGE "Tab 1" ;
     OF oTab ;
     TOOLTIP cTooltip1

        @ 20,50 SAY "This is the tab 1" ;
        SIZE 150,22  && Need more space for Windows old: SIZE 100,22

  END PAGE of oTab

  BEGIN PAGE "Tab 2" ;
     OF oTab ;
     TOOLTIP cTooltip2

     @ 20,50 SAY "This is the tab 2" ;
        SIZE 150,22

  END PAGE of oTab

  #ifndef __GTK__
   * On WinAPI, the correct tooltip must be synchronized with the shown first tab
   * at program start.
   oTab:ChangePage(1)
  #endif

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN nil

FUNCTION AskYesNo( oDlgMain )

   LOCAL oDlg, oFont := HFont():Add( "Serif",0,-13 ), lYes := .F.

   INIT DIALOG oDlg ;
      CLIPPER ;
      NOEXIT ;
      TITLE "Quit" ;
      AT oDlgMain:nLeft + 250, oDlgMain:nTop + 130  ;
      SIZE 210,90 ;
      FONT oFont

   @ 40,10 SAY "Do you want to quit ?" ;
      SIZE 150, 22 ;
      COLOR hwg_ColorC2N("0000FF")

   @ 30,40 BUTTON hb_i18n_gettext( "Quit" ) ;
      OF oDlg ;
      ; // ID IDOK  ; // if define ID, sample does not end
      SIZE 60, 32 ;
      COLOR hwg_ColorC2N("FF0000") ;
      ON CLICK { || lYes := .T., oDlg:Close() }

   @ 110,40 BUTTON hb_i18n_gettext("Cancel") ;
      OF oDlg ;
      ID IDCANCEL  ;
      SIZE 60, 32 ;
      COLOR hwg_ColorC2N("FF0000")

   ACTIVATE DIALOG oDlg CENTER

RETURN lYes

#include "demo.ch"

* ======================== EOF of demotabtool.prg ===============================

