/*
  pseudocm.prg

  $Id$
  HWGUI example
  Pseudo context menu (mouse right click) for BRWOSE.


*/
#include "hwgui.ch"

STATIC oMenuBrw, nrp
MEMVAR aSample

FUNCTION Main()

   LOCAL oBmp := Nil // -w3 -es2 but no value and is used
   LOCAL oBrw, Form_Main
   // LOCAL oFontBtn

   PUBLIC aSample := { { .T. ,"Line 1",10 }, { .T. ,"Line 2",22 }, { .F. ,"Line 3",40 } }

   // PREPARE FONT oFontBtn NAME "MS Sans Serif" WIDTH 0 HEIGHT - 12

   INIT WINDOW Form_Main MAIN TITLE "HwGUI Sample Pseudo Context Menu in BROWSE" SIZE 360, 300

   MENU OF Form_Main
      MENU TITLE "&File"
         MENUITEM "&Exit" ACTION { ||hwg_EndWindow() }
      ENDMENU
      MENU TITLE "&Status"
         MENUITEM "&Show" ACTION st_f4( oBrw:rowPos, aSample[oBrw:rowPos][2] )
      ENDMENU
   ENDMENU

   CONTEXT MENU oMenuBrw
      MENUITEM "Status" ACTION { ||st_f4( nrp, aSample[nrp][2] ) }
   ENDMENU

   @ 160, 10 BROWSE oBrw ARRAY SIZE 180, 180 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL ;
      ON RIGHTCLICK { |o, nrow, ncol| (o), SUBMNU_BRW( ncol, nrow ) }

   hwg_CREATEARLIST( oBrw, aSample )

   oBrw:aColumns[1]:aBitmaps := { ;
      { { |l|l }, oBmp } ;
      }
   oBrw:aColumns[2]:length := 6
   oBrw:aColumns[3]:length := 4


   ACTIVATE WINDOW Form_Main

RETURN Nil

FUNCTION SUBMNU_BRW( nCol, nRow )

   IF nCol > 0 .AND. nCol <= Len( aSample )
      nrp := ncol
      oMenuBrw:Show( HWindow():GetMain() )
   ENDIF
   (nRow) // -w3 -es2

RETURN Nil

FUNCTION st_f4( n, c )

   hwg_MsgInfo( "This is the status window of Line " + AllTrim( Str(n ) ) + " : " + c, "Bingo !" )

RETURN 0
