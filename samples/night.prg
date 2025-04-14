/*
 *
 * night.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Sample for "ADD HEADER PANEL" for a night mode application
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2022 Wilfried Brunken, DF7BE
*/

   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

/*
   This sample program based on graph.prg
   and demonstrates a suitable "Night modus"
   for "eye friendly" display, if working
   with the computer at low illumination.
   Test the night design in main and
   dialog window.
*/

STATIC oStyleNormal, oStylePressed, oStyleOver
STATIC inilNightDesign,nNightOffset
STATIC oFont

#include "hwgui.ch"

FUNCTION MAIN()

   LOCAL oDlg, oPanel, oButton // oPaneTop
   LOCAL cTitle := "Header"


   * Style objects for night design
   oStyleNormal := HStyle():New( {0x7b7680,0x5b5760}, 1 )
   oStylePressed := HStyle():New( {0x7b7680}, 1,, 2, 0xffffff )
   oStyleOver := HStyle():New( {0x7b7680}, 1 )

   inilNightDesign := hwg_MsgYesNo("Set to night mode")
   nNightOffset := 32

   PREPARE FONT oFont NAME "Georgia" WIDTH 0 HEIGHT -17 ITALIC

   IF inilNightDesign

      INIT WINDOW oDlg TITLE "" BACKCOLOR 0x3C3940 ;
            AT 0, 0 SIZE 380, 400 STYLE WND_NOTITLE &&  + WND_NOSIZEBOX ;
		   // MENUPOS 33

		   // Add a header panel with predefined buttons
      ADD HEADER PANEL oPanel HEIGHT 32 TEXTCOLOR 0xFFFFFF BACKCOLOR 0x2F343F ;
         FONT oFont TEXT cTitle  COORS 0 BTN_CLOSE BTN_MAXIMIZE BTN_MINIMIZE

      // Set colors of predefined buttons to correspond panel color.
      // "btnClose" is a predefined name of a close button, "btnMax" and
      // "btnMin" - of maximize and minimize buttons.
      oPanel:SetSysbtnColor( 0xffffff, 0x7b7680 )
   ELSE

      INIT WINDOW oDlg TITLE cTitle ;
      AT 0, 0 SIZE 380, 400 STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE
   ENDIF

   // The menu is fix connected to the main bar,
   // so the HEADER Panel appeared unter the menu bar
   MENU OF oDlg
      MENU TITLE "&File"
         MENUITEM "Quit" ACTION  { || oDlg:Close() }
      ENDMENU
      MENU TITLE "&Dialog"
         MENUITEM "&Test dialog" ACTION TestDialog()
      ENDMENU
   ENDMENU


	// Problem: Menu must be moved under the header
	// Hwg_BeginMenu( <oWnd>, <nId>, <cTitle> )
	&& Show( oWnd, xPos, yPos, lWnd )

   IF inilNightDesign

      @ 140,260 OWNERBUTTON SIZE 100,32 TEXT "Close" COLOR 0xffffff ;
            HSTYLES oStyleNormal, oStylePressed, oStyleOver ;
            ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS ;
            ON CLICK {|| oDlg:Close()}
   ELSE

     @ 140,260 BUTTON oButton CAPTION "Close" SIZE 100,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| oDlg:Close()}
   ENDIF

   ACTIVATE WINDOW oDlg CENTER

RETURN Nil

FUNCTION TestDialog()

   LOCAL oPanel , oDlg, al_DOKs
   LOCAL oButton , oBrwArr, oButton2
   LOCAL cTitle := "Header of dialog"

   al_DOKs :=  { {"1"} , {"2"} , {"3"} , {"4"} }

   INIT DIALOG oDlg TITLE "" BACKCOLOR 0x3C3940 ;
         AT 200, 200 SIZE 380, 400 STYLE WND_NOTITLE &&  + WND_NOSIZEBOX ;

   IF inilNightDesign

      INIT DIALOG oDlg TITLE "" BACKCOLOR 0x3C3940 ;
            AT 0, 0 SIZE 380, 400 STYLE WND_NOTITLE

      ADD HEADER PANEL oPanel HEIGHT 32 TEXTCOLOR 0xFFFFFF BACKCOLOR 0x2F343F ;
         FONT oFont TEXT cTitle  COORS 0 BTN_CLOSE BTN_MAXIMIZE BTN_MINIMIZE

      oPanel:SetSysbtnColor( 0xffffff, 0x7b7680 )
   ELSE

      INIT DIALOG oDlg TITLE cTitle ;
         AT 0, 0 SIZE 380, 400 STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE+DS_CENTER

   ENDIF

   MENU OF oDlg
      MENU TITLE "&Dialog"
         MENUITEM "&Return" ACTION  { || oDlg:Close() }
      ENDMENU
      MENU TITLE "&Title"
         MENUITEM "&Test dialog" ACTION ChangeHeader()
      ENDMENU
   ENDMENU


	// Problem: Menu must be moved under the header
	// Hwg_BeginMenu( <oWnd>, <nId>, <cTitle> )
	&& Show( oWnd, xPos, yPos, lWnd )

   * For you to do at your own needs : change colors of browse,
   * see sample program "colrbloc.prg"

   @ 21,50 BROWSE oBrwArr ARRAY ;
      STYLE WS_VSCROLL + WS_HSCROLL   SIZE 100,170

	/* See demobrowsearray.prg */
   hwg_CREATEARLIST(oBrwArr,al_DOKs)
   oBrwArr:acolumns[1]:heading := "DOKs"  // Header string
   oBrwArr:acolumns[1]:length := 50
   oBrwArr:bcolorSel := hwg_ColorC2N( "800080" )
   * FONT setting is mandatory, otherwise crashes with "Not exported method PROPS2ARR"
   oBrwArr:ofont := oFont

   IF inilNightDesign

      @ 200,260 OWNERBUTTON SIZE 100,32 TEXT "Close" COLOR 0xffffff ;
         HSTYLES oStyleNormal, oStylePressed, oStyleOver ;
         ON CLICK {|| oDlg:Close(oDlg) }
         * ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS ;

      @ 39,260 OWNERBUTTON SIZE 100,64 TEXT "Change header text" COLOR 0xffffff ;
         HSTYLES oStyleNormal, oStylePressed, oStyleOver ;
         ON CLICK {|| ChangeHeader(oPanel,.T.) }
      * ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS ;

   ELSE

      @ 240,260 BUTTON oButton CAPTION "Close" SIZE 100,32 ;
         STYLE WS_TABSTOP+BS_FLAT ;
         ON CLICK {|| oDlg:Close() }
      @ 39,260 BUTTON oButton2 CAPTION "Change header text" SIZE 200,32 ;
         STYLE WS_TABSTOP+BS_FLAT ;
         ON CLICK {|| ChangeHeader(oDlg,.F.) }
   ENDIF

   ACTIVATE DIALOG oDlg

RETURN Nil

FUNCTION ChangeHeader(ohda,lmo)

   IF lmo
      ohda:SetText( "New header text" , .T. )
   ELSE
      ohda:SetTitle("New header text")
   ENDIF

RETURN Nil

* ================================ EOF of night.prg ============================================
