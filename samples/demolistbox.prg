#include "hwgui.ch"
// #include "listbox.ch"

FUNCTION Main()

   LOCAL oMainWindow

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "DEMOLISTBOX - Example Listbox" ;
      AT 0,0 ;
      SIZE 600, 400

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION oMainWindow:Close()
      MENUITEM "&Teste" ACTION Teste()
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

FUNCTION Teste()

   LOCAL oModDlg, oFont := HFont():Add( "MS Sans Serif",0,-13 )
   LOCAL oList, oItems:={"Item01","Item02","Item03","Item04"}

   INIT DIALOG oModDlg ;
      TITLE "Test"  ;
      AT 0,0  ;
      SIZE 450,350   ;
      FONT oFont

   @ 10,40 LISTBOX oList ;
      ITEMS oItems ;
      OF oModDlg                  ;
      INIT 1 ;
      SIZE 210, 220            ;
      ON INIT {||hwg_Msginfo("Teste")} ;
      TOOLTIP "Test ListBox"

   @  10,280 BUTTON "Ok" ;
      ID IDOK  ;
      SIZE 50, 32

   ACTIVATE DIALOG oModDlg CENTER
   oFont:Release()

   // show result
   hwg_msgInfo( Str( oList:value ), "Result of Listbox selection" )

   IF oModDlg:lResult
   ENDIF

RETURN Nil
