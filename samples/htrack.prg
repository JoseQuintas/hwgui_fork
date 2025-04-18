// We create here a new control, which can be
// used as a replacement for a track bar,
// which has not gtk version.
#include "hwgui.ch"
#include "hbclass.ch"
#define CLR_WHITE    0xffffff
#define CLR_BLACK    0x000000
#define CLR_BROWN_1  0x154780
#define CLR_BROWN_3  0xaad2ff

FUNCTION Main()

   LOCAL oWinMain

   INIT WINDOW oWinMain ;
      MAIN  ;
      TITLE "Sample program new progbar" ;
      AT 0, 0 ;
      SIZE 600,400 ;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&File"
         MENUITEM "&Exit"              ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Test"
         MENUITEM "Start test"     ACTION Test()
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN Nil

FUNCTION Test()

   LOCAL oDlg, oTrack, oSay, oFont := HFont():Add( "MS Sans Serif",0,-13 )
   LOCAL bVolChange := { | o, n |
         HB_SYMBOL_UNUSED( o )
         HB_SYMBOL_UNUSED( n )
         oSay:SetText( Ltrim( Str( oTrack:value ) ) )
         RETURN .T.
         }

   INIT DIALOG oDlg ;
      TITLE "Track bar control"  ;
      AT 210,10  ;
      SIZE 300,200 ;
      FONT oFont BACKCOLOR CLR_BROWN_1

   @ 40, 20 SAY "Just drag the slider:" ;
      SIZE 220, 22 ;
      STYLE SS_CENTER BACKCOLOR CLR_BROWN_3

   oTrack := HTrack():New( ,, 80, 50, 140, 28,,, CLR_WHITE, CLR_BROWN_1, 16 )
   oTrack:bChange := bVolChange
   oTrack:Value := 0.5

   @ 80, 100 SAY oSay ;
      CAPTION "" ;
      SIZE 140, 22 ;
      STYLE SS_CENTER ;
      BACKCOLOR CLR_BROWN_3

   ACTIVATE DIALOG oDlg
   oFont:Release()

RETURN Nil

* ============================ EOF of htrack.prg ==============================
