* Sample program for tabs with tooltips
* TNX to Alain Aupeix


* Support ticket #54 "Tooltip for tabs ?"

/*
 * $Id$
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

memvar oMainWindow
// ============================================================================
function Main()
// ============================================================================
local oTab, oToolbar, cTooltip1:="This is the first tab", cTooltip2:="This is the second tab"
local oButton

public oMainWindow

INIT WINDOW oMainWindow ;
   MAIN ;
   TITLE "Test tabs with tooltip" ;
   AT 168,50 ;
   SIZE 400,240 ;
   BACKCOLOR hwg_ColorC2N("#DCDAFF")

  // Toolbar
  @ 0,0 PANEL oToolbar ;
     SIZE 0,32

  @ 2,3 BUTTON oButton ;
     CAPTION "Quit";
     ON CLICK {||Quitter()} ;
     SIZE 40,24 ;
     COLOR hwg_ColorC2N("#FF0000") ;
     Tooltip "Quit ?"

  @ 10, 35 TAB oTab ;
     ITEMS {} ;
     SIZE 380, 190

  BEGIN PAGE "Tab 1" ;
     of oTab ;
     Tooltip cTooltip1

        @ 20,50 SAY "This is the tab 1" ;
        SIZE 150,22  && Need more space for Windows old: SIZE 100,22

  END PAGE of oTab

  BEGIN PAGE "Tab 2" ;
     of oTab ;
     Tooltip cTooltip2

        @ 20,50 SAY "This is the tab 2" ;
           SIZE 150,22

  END PAGE of oTab

  #ifndef __GTK__
   * On WinAPI, the correct tooltip must be synchronized with the shown first tab
   * at program start.
   oTab:ChangePage(1)
  #endif

ACTIVATE WINDOW oMainWindow CENTER

return nil

// ============================================================================
function Quitter()
// ============================================================================
local oDlg, oFont := HFont():Add( "Serif",0,-13 )

INIT DIALOG oDlg ;
   CLIPPER ;
   NOEXIT ;
   TITLE "Quit" ;
   AT oMainWindow:nLeft+250,oMainWindow:nTop+130  ;
   SIZE 210,90 ;
   FONT oFont

@ 40,10 SAY "Do you want to quit ?" ;
   SIZE 150, 22 ;
   COLOR hwg_ColorC2N("0000FF")

@ 30,40 BUTTON hb_i18n_gettext("Quit") ;
   OF oDlg ;
   ID IDOK  ;
   SIZE 60, 32 ;
   COLOR hwg_ColorC2N("FF0000") ;

@ 110,40 BUTTON hb_i18n_gettext("Cancel") ;
   OF oDlg ;
   ID IDCANCEL  ;
   SIZE 60, 32 ;
   COLOR hwg_ColorC2N("FF0000")


ACTIVATE DIALOG oDlg CENTER
oFont:Release()
if oDlg:lresult
   hwg_EndWindow()
endif

return nil

* ======================== EOF of tabs_toolt.prg ===============================


