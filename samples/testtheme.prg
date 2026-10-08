/*
 * testtheme.prg - Complete theme test for HWGUI
 *
 * Build:
 *   hbmk2 hwgui.hbp testtheme.prg
 *   (or whatever command you already use: hbmk2 hwgui.hbp svg.hbc testtheme.prg)
 */

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDlg, oTab, oEdit, oCombo, oSay, oBtn1, oBtn2, oBtn3, cEdit

   /* ---------------------------------------------------------------
    * 1) Diagnostics: prints to console whether theming is active.
    *    Expected: both .T.
    *    If IsAppThemed() = .F., the manifest was NOT embedded in the .exe.
    * --------------------------------------------------------------- */
   ? "===== THEME DIAGNOSTICS ====="
   ? "IsThemeActive     :", hwg_IsThemeActive()
   ? "IsAppThemed       :", hwg_IsAppThemed()
   ? "============================="
   ?

   /* ---------------------------------------------------------------
    * 2) Main dialog with a variety of controls.
    *    All should show the modern Windows 10/11 look:
    *      - Button: rounded corners, blue hover
    *      - Edit: bluish border on focus
    *      - Combo: styled dropdown arrow
    *      - Tab: themed background
    * --------------------------------------------------------------- */
   INIT DIALOG oDlg TITLE "HWGUI Theme Test" ;
        AT 0, 0 SIZE 520, 400

   @ 10, 10 SAY oSay ;
        CAPTION "Diagnostics:" ;
        SIZE 500, 20

   @ 10, 35 SAY oSay ;
        CAPTION "IsThemeActive=" + Iif( hwg_IsThemeActive(), "T", "F" ) ;
        SIZE 200, 20

   @ 220, 35 SAY oSay ;
        CAPTION "IsAppThemed=" + Iif( hwg_IsAppThemed(), "T", "F" ) ;
        SIZE 200, 20

   /* --- Edit --- */
   @ 10, 65 SAY oSay CAPTION "Edit:" SIZE 60, 22
   @ 80, 62 GET oEdit VAR cEdit SIZE 300, 26

   /* --- Combo --- */
   @ 10, 100 SAY oSay CAPTION "Combo:" SIZE 60, 22
   @ 80, 97 COMBOBOX oCombo ;
        ITEMS { "Option 1", "Option 2", "Option 3" } ;
        SIZE 300, 26 ;
        INIT 1

   /* --- Buttons --- */
   @ 10, 135 BUTTON oBtn1 CAPTION "Normal Button" ;
        SIZE 120, 32 ;
        ON CLICK { || hwg_MsgInfo( "You clicked the normal button!", "Test" ) }

   @ 140, 135 BUTTON oBtn2 CAPTION "Button 2" ;
        SIZE 120, 32 ;
        ON CLICK { || hwg_MsgInfo( "You clicked button 2!", "Test" ) }

   @ 270, 135 BUTTON oBtn3 CAPTION "Button 3" ;
        SIZE 120, 32 ;
        ON CLICK { || hwg_MsgInfo( "You clicked button 3!", "Test" ) }

   /* --- Tab control (the most important test for EnableThemeDialogTexture) --- */
   @ 10, 180 TAB oTab ;
        ITEMS { "Tab 1", "Tab 2", "Tab 3" } ;
        SIZE 500, 150

      BEGIN PAGE "Tab 1" OF oTab
         @ 20, 40 SAY oSay ;
              CAPTION "Content of Tab 1" ;
              SIZE 300, 22
         @ 20, 65 SAY oSay ;
              CAPTION "The background of this area should match the theme" ;
              SIZE 400, 22
         @ 20, 85 SAY oSay ;
              CAPTION "(not the old flat gray)." ;
              SIZE 400, 22
      END PAGE OF oTab

      BEGIN PAGE "Tab 2" OF oTab
         @ 20, 40 SAY oSay ;
              CAPTION "Content of Tab 2" ;
              SIZE 300, 22
      END PAGE OF oTab

      BEGIN PAGE "Tab 3" OF oTab
         @ 20, 40 SAY oSay ;
              CAPTION "Content of Tab 3" ;
              SIZE 300, 22
      END PAGE OF oTab

   /* --- SetWindowTheme test buttons --- */
   @ 10, 345 BUTTON "Apply Explorer to Edit" ;
        SIZE 200, 32 ;
        ON CLICK { || hwg_SetWindowTheme( oEdit:handle, "Explorer", Nil ), ;
                   hwg_MsgInfo( "Explorer theme applied to Edit.", "Test" ) }

   @ 220, 345 BUTTON "Remove Theme from Edit" ;
        SIZE 200, 32 ;
        ON CLICK { || hwg_SetWindowTheme( oEdit:handle, " ", " " ), ;
                   hwg_MsgInfo( "Theme removed from Edit.", "Test" ) }

   @ 430, 345 BUTTON "Exit" ID IDCANCEL ;
        SIZE 80, 32

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil
