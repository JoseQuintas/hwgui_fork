/*
 *
 * demotab.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Sample for Tabs
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/
   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

/*
 Modifications (March 2021):
 - Port from Borland resource file to HWGUI commands

 - The contents of old rc file is listed in a command line comment
   at end of program text.

  Severe bug fixed:
  missing function(s): hb_enumIndex()

  Different behavior to BCC version:
  Background color is white instead of grey,
  can not mofified yet, the REDEFINE freezes the program.


*/

#include "hwgui.ch"
* #include "tab.rh"

#define IDC_1           101

MEMVAR oFont

FUNCTION DemoTab( lWithDialog, oDlg )

   LOCAL oTab // oDlg2, oDlg3
   LOCAL aCombo := { "Aaaa","Bbbb" }
   LOCAL oBrw1, oBrw2
   LOCAL aSample1 := { {"Alex",17}, {"Victor",42}, {"John",31} }
   LOCAL aSample2 := { {"Line 1",10}, {"Line 2",22}, {"Line 3",40} }
   LOCAL e1 := "Xxxx"
   LOCAL e2 := "Xxxx"
   LOCAL e3 := "Xxxx"
   LOCAL oCombobox1

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      * from resource DIALOG_1
      INIT DIALOG oDlg ;
         TITLE "demotab.prg - DIALOG_1" ;
         CLIPPER ;
         NOEXIT ;
         NOEXITESC ;
         AT 10, 25 ;
         SIZE 545, 394 ;
         FONT oFont ;
         STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_THICKFRAME + WS_MINIMIZEBOX + WS_MAXIMIZEBOX ;
         ON EXIT { || hwg_Msginfo( "Exit" ), .T. }
   ENDIF

* on init {|| buildtabPages(oTab,{adlg1,adlg2},{"pagina1","pagina2"})} ;

/*
aDlg1:oParent:=oTab,aDlg2:oParent:=oTab,;
aDlg1:Activate(.t.),      aDlg2:Activate(.t.), ;
aDlg2:hide(),    oTab:StartPage( "pagina1",aDlg1 ),    oTab:EndPage(), ;
oTab:StartPage( "pagina2",aDlg2 ),    oTab:EndPage(),otab:changepage(1)

}
*/

   ButtonForSample( "demotab.prg" )

   @ 20, 80 TAB oTab ;
      ITEMS {} ID IDC_1 ;
      SIZE 504, 341 ;
      STYLE WS_CHILD+WS_VISIBLE

* REDEFINE TAB oTab ID IDC_1

* If set, crashees at exit
* oDlg1:lRouteCommand := .T.

   BEGIN PAGE "Page 1" of oTab

*  FROM RESOURCE  PAGE_1
//   INIT DIALOG aDlg1 AT 6, 15 SIZE 161, 114 ;
//   FONT oFont ;
//   STYLE WS_CHILD+WS_VISIBLE ;
//   CLIPPER NOEXIT NOEXITESC ;
//   ON EXIT {||hwg_Msginfo("Exit"),.T.}


      @ 65,92  CHECKBOX "Checkbox" ;
         SIZE 149,22

      @ 65,123 CHECKBOX "Checkbox" ;
         SIZE 149,22

      @ 65,163  EDITBOX e1 ;
         ID 103 ;
         SIZE 134,24 ;
         STYLE WS_CHILD + WS_TABSTOP + WS_BORDER

      @ 65,201  EDITBOX e2 ;
         ID 104 ;
         SIZE 134,24 ;
         STYLE WS_CHILD + WS_TABSTOP + WS_BORDER

      @ 65,240  EDITBOX e3 ;
         ID 105 ;
         SIZE 134,24 ;
         STYLE WS_CHILD + WS_TABSTOP + WS_BORDER

*   REDEFINE GET e1 ID 103
*   REDEFINE GET e2 ID 104
*   REDEFINE GET e3 ID 105

   END PAGE of oTab

   BEGIN PAGE "Page 2" of oTab

*  FROM RESOURCE  PAGE_2
//   INIT DIALOG aDlg2  ;
//   FONT oFont ;
//   STYLE WS_CHILD+WS_VISIBLE ;
//   CLIPPER NOEXIT NOEXITESC ON EXIT {||hwg_Msginfo("Exit"),.T.}

      @ 36,108 COMBOBOX oCombobox1 ;
         ITEMS aCombo ;
         SIZE 87,96 ;
         STYLE CBS_DROPDOWNLIST + WS_TABSTOP

      @ 38,153 CHECKBOX "Checkbox" ;
         SIZE 80,22

      @ 165,81 BROWSE oBrw1 ;
         ARRAY ;
         SIZE 103,135 ;  && ID 104
         STYLE WS_CHILD + WS_VISIBLE + WS_BORDER + WS_VSCROLL + WS_HSCROLL + WS_TABSTOP

      hwg_CREATEARLIST( oBrw1,aSample1 )

      @ 300,81 BROWSE oBrw2 ;
         ARRAY ;
         SIZE 103,135 ; && ID 105
         STYLE WS_CHILD + WS_VISIBLE + WS_BORDER + WS_VSCROLL + WS_HSCROLL + WS_TABSTOP

      hwg_CREATEARLIST( oBrw2,aSample2 )


*   REDEFINE COMBOBOX aCombo ID 101
*   REDEFINE BROWSE oBrw1 ARRAY ID 104
*   REDEFINE BROWSE oBrw2 ARRAY ID 105

   END PAGE of oTab

* TO DO: To modify colors, program running dead
* REDEFINE TAB oTab ID IDC_1 COLOR 65280 BACKCOLOR 255

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

/*

 This function now obselete

function buildtabPages(oTab,aPage,aTitle)
Local n , ind
ind := 0

for each n in aPage
   n:oParent := oTab
   n:activate(.t.)
   ind := ind + 1
   oTab:startpage(aTitle[ind],n)  && hb_enumindex()
   otab:endpage()
   n:oParent := nil
next
return .t.
*/

/*

#include "tab.rh"

DIALOG_1 DIALOG 6, 15, 362, 242
STYLE WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
CAPTION "DIALOG_1"
FONT 8, "MS Sans Serif"
{
 CONTROL "", IDC_1, "SysTabControl32", 0 | WS_CHILD | WS_VISIBLE|WS_CLIPSIBLINGS, 5, 9, 348, 225
}

PAGE_1 DIALOG 6, 15, 161, 114
STYLE WS_CHILD | WS_VISIBLE
FONT 8, "MS Sans Serif"
{
 CHECKBOX "Checkbox", IDC_CHECKBOX1, 16, 25, 60, 12, BS_AUTOCHECKBOX | WS_TABSTOP
 CHECKBOX "Checkbox", IDC_CHECKBOX2, 17, 43, 60, 12, BS_AUTOCHECKBOX | WS_TABSTOP
 EDITTEXT IDC_EDIT1, 18, 63, 67, 12, WS_CHILD| WS_TABSTOP | WS_BORDER
 EDITTEXT IDC_EDIT2, 18, 84, 63, 12,  WS_CHILD| WS_TABSTOP | WS_BORDER
 EDITTEXT IDC_EDIT3, 18, 115, 63, 12, WS_CHILD| WS_TABSTOP | WS_BORDER
}


PAGE_2 DIALOG 6, 15, 217, 114
STYLE WS_CHILD | WS_VISIBLE
FONT 8, "MS Sans Serif"
{
 COMBOBOX IDC_COMBOBOX1, 9, 31, 49, 43, CBS_DROPDOWNLIST | WS_TABSTOP
 CHECKBOX "Checkbox", IDC_CHECKBOX3, 9, 53, 45, 12, BS_AUTOCHECKBOX | WS_TABSTOP
 CONTROL "", ID_BROWSE1, "BROWSE", 0 | WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | WS_HSCROLL | WS_TABSTOP, 65, 10, 68, 75
 CONTROL "", ID_BROWSE2, "BROWSE", 0 | WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | WS_HSCROLL | WS_TABSTOP, 140, 10, 73, 75
}

Contents of tab.rh:

#define DIALOG_1          1
#define IDC_1           101
#define IDC_COMBOBOX1   101
#define IDC_CHECKBOX3   102
#define IDC_CHECKBOX1   101
#define IDC_CHECKBOX2   102
#define IDC_EDIT1       103
#define IDC_EDIT3       105
#define IDC_EDIT2       104
#define ID_BROWSE1      104
#define ID_BROWSE2      105
#define PAGE_1 3
#define PAGE_2 4

*/

#include "demo.ch"

* =============================== EOF of demotab.prg ==========================================
