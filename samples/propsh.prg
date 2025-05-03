/*
 * HWGUI using sample
 * Property sheet
 *
 * $Id$
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Modifications by DF7BE:
 * - Port of Borland resources to HWGUI commands
 * - Screenshots of both dialogs in
 *   subdirectory doc/image saved.
 *
 * Solved 2025-03-29:
 * The function hwg_PropertySheet()
 * have a bug, the property sheet does not appear !
 * Also the programm freezes, if compiled with BCC.
*/

#include "hwgui.ch"
#include "common.ch"
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

/* This defines only for Borland resources */
#define IDC_COMBOBOX1   101
#define IDC_CHECKBOX3   102
#define IDC_CHECKBOX1   101
#define IDC_CHECKBOX2   102
#define IDC_EDIT2       103
#define ID_BROWSE1      104
#define ID_BROWSE2      105

FUNCTION Main()

   LOCAL oMainWindow

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "Example" ;
      AT 200,0 ;
      SIZE 650,400

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Property Sheet" ACTION OpenConfig()
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

FUNCTION OpenConfig()

   LOCAL aDlg1, aDlg2, aCombo := { "Aaaa","Bbbb" }
   LOCAL oBrw1, oBrw2
   LOCAL aSample1 := { {"Alex",17}, {"Victor",42}, {"John",31} }
   LOCAL aSample2 := { {"Line 1",10}, {"Line 2",22}, {"Line 3",40} }
   LOCAL e1 := "Xxxx"
   LOCAL oEditbox1, oCheckbox1, oCombobox1
   LOCAL oFont
   LOCAL oSay1,oSay2,oSay3,oSay4

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
   PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12
#endif
* oFont := HFont():Add( "MS Sans Serif",0,-11,400,,,) && 8, "MS Sans Serif"

   // INIT DIALOG aDlg1 FROM RESOURCE  "PAGE_1" ON EXIT {||hwg_Msginfo("Exit"),.T.}
   // REDEFINE GET e1 ID 103

    INIT DIALOG aDlg1 ;
       TITLE "Config1" ;
       AT 10,10 ;
       SIZE 262,249 ;   && 210,297
       STYLE  WS_VISIBLE + WS_BORDER ;   && WS_CHILD freezes program
       FONT oFont ;
       ON EXIT {||hwg_Msginfo("Exit"),.T.}

   @ 40,26 CHECKBOX "Checkbox" ;
      OF aDlg1 ;
      SIZE 120,22 ;
      FONT oFont

   * not allowed :
   *           STYLE BS_AUTOCHECKBOX + WS_TABSTOP ;
   *           FONT oFont

   @ 40,59 CHECKBOX "Checkbox" ;
      OF aDlg1 ;
      SIZE 80,22 ;
      FONT oFont

   @ 40,96 GET oEditbox1 VAR e1 ;
        OF aDlg1 ;
        SIZE 80,24 ;
        STYLE WS_CHILD + WS_VISIBLE + WS_BORDER ;
        FONT oFont

   @ 40,150 SAY oSay1 ;
      CAPTION "Close sheet with <ESC>" ;
      OF aDlg1 ;
      SIZE 150,22

   @ 40,175 SAY oSay2 ;
      CAPTION "or <Alt> + F4" ;
      OF aDlg1 ;
      SIZE 150,22

   * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   // INIT DIALOG aDlg2 FROM RESOURCE  "PAGE_2" ON EXIT {||.T.}
     INIT DIALOG aDlg2 ;
        TITLE "Config2" ;
        AT 282,10  ;
        SIZE 346,249 ;  && 295,329
        STYLE WS_VISIBLE + WS_CAPTION ;
        FONT oFont ;
        ON EXIT {||.T.}

   // REDEFINE COMBOBOX aCombo ID 101
     @ 18,47 COMBOBOX oCombobox1 ;
        ITEMS aCombo ;
        OF aDlg2 ;
        SIZE 63,80 ;
        STYLE CBS_DROPDOWNLIST + WS_TABSTOP ;
        FONT oFont

     @ 18,83 CHECKBOX oCheckbox1 ;
        CAPTION "Checkbox" ;
        OF aDlg2 ;
        SIZE 80,22    ;
        FONT oFont

     @ 18,150 SAY oSay3 ;
        CAPTION "Close sheet with <ESC>" ;
        OF aDlg2 ;
        SIZE 150,22

     @ 40,175 SAY oSay4 ;
        CAPTION "or <Alt> + F4" ;
        OF aDlg2 ;
        SIZE 150,22


   // REDEFINE BROWSE oBrw1 ARRAY ID 104
   // REDEFINE BROWSE oBrw2 ARRAY ID 105

   @ 103,17 BROWSE oBrw1 ;
      ARRAY ;
      OF aDlg2 ;
      SIZE 97,106 ;
      STYLE WS_CHILD + WS_VISIBLE + WS_BORDER + WS_VSCROLL + WS_HSCROLL + WS_TABSTOP ;
      FONT oFont

      hwg_CREATEARLIST( oBrw1,aSample1 )

/*
    oBrowse1:aColumns := {}
    oBrowse1:aArray := {}
    oBrowse1:AddColumn( HColumn():New( ,{|v,o|Iif(v!=Nil,o:aArray[o:nCurrent]:=v,o:aArray[o:nCurrent])},'C',100,0))
    *- FIM DE oBrowse1
*/

   @ 213,17 BROWSE oBrw2 ;
      ARRAY ;
      OF aDlg2 ;
      SIZE 97,106 ;
      STYLE WS_CHILD + WS_VISIBLE + WS_BORDER + WS_VSCROLL + WS_HSCROLL + WS_TABSTOP ;
      FONT oFont

      hwg_CREATEARLIST( oBrw2,aSample2 )

/*
    oBrowse2:aColumns := {}
    oBrowse2:aArray := {}
    oBrowse2:AddColumn( HColumn():New( ,{|v,o|Iif(v!=Nil,o:aArray[o:nCurrent]:=v,o:aArray[o:nCurrent])},'C',100,0))
    *- FIM DE oBrowse2
*/

   * hwg_PropertySheet( hParentWindow, aPages, cTitle, x1, y1, width, height, ;
   *   lModeless, lNoApply, lWizard )
   // hwg_PropertySheet( hwg_Getactivewindow(),{ aDlg1, aDlg2 }, "Sheet Example" )

   hwg_PropertySheet( hwg_Getactivewindow(),{ aDlg1, aDlg2 }, "Sheet Example" )

   activate dialog aDlg1 CENTER
   activate dialog aDlg2 CENTER

RETURN Nil

/*
 Old Borland resource here as comment:

 PAGE_1 DIALOG 6, 15, 161, 114
STYLE WS_CHILD | WS_VISIBLE | WS_BORDER
CAPTION "Config1"
FONT 8, "MS Sans Serif"
BEGIN
 CHECKBOX "Checkbox", IDC_CHECKBOX1, 16, 25, 60, 12,
     BS_AUTOCHECKBOX | WS_TABSTOP
 CHECKBOX "Checkbox", IDC_CHECKBOX2, 17, 43, 60, 12, BS_AUTOCHECKBOX | WS_TABSTOP
 CONTROL "", IDC_EDIT2, "EDIT", 0 | WS_CHILD | WS_VISIBLE | WS_BORDER, 18, 63, 67, 12
END


PAGE_2 DIALOG 6, 15, 217, 114
STYLE WS_CHILD | WS_VISIBLE | WS_CAPTION
CAPTION "Config2"
FONT 8, "MS Sans Serif"
{
 COMBOBOX IDC_COMBOBOX1, 9, 31, 49, 43, CBS_DROPDOWNLIST | WS_TABSTOP
 CHECKBOX "Checkbox", IDC_CHECKBOX3, 9, 53, 45, 12, BS_AUTOCHECKBOX | WS_TABSTOP
 CONTROL "", ID_BROWSE1, "BROWSE", 0 | WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | WS_HSCROLL | WS_TABSTOP, 65, 10, 68, 75
 CONTROL "", ID_BROWSE2, "BROWSE", 0 | WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | WS_HSCROLL | WS_TABSTOP, 140, 10, 73, 75
}


*/

* ====================================== EOF of propsh.prg =============================================
