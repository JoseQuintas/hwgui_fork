  *
  *
  * Tickets #93 and #48
  *
  * Look for bugfixing of:
  * IA__gtk_window_set_transient_for: assertion 'window != parent' failed
  *
  *
#include "hwgui.ch"
#include "common.ch"
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

STATIC oWinMain

FUNCTION Main()
LOCAL cimg , oFormMain

cimg := "../image/door.bmp"

CHECK_FILE(cimg)



INIT WINDOW oFormMain MAIN  ;
   TITLE "Hwgui Test program gtk error" AT 0,0 SIZE 300,200 ;
   STYLE WS_POPUP +  WS_CAPTION + WS_SYSMENU
  MENU OF oFormMain
      MENU TITLE "&Exit"
        MENUITEM "&Quit" ACTION oFormMain:Close()
      ENDMENU
      MENU TITLE "&Test"
        MENUITEM "&Teste" ACTION TESTEN(cimg)
      ENDMENU
   ENDMENU
   oFormMain:Activate()
RETURN NIL



FUNCTION TESTEN(cimg)

LOCAL oToolbar , htab , nbut ,  oFontMain , oWinDia , oObj_Exit


htab := 0
nbut := 0

 oObj_Exit := HBitMap():AddFile(cimg)

   PREPARE FONT oFontMain NAME "Sans" WIDTH 0 HEIGHT 12

INIT DIALOG oWinDia ;
   FONT oFontMain  ;
     TITLE "Test program gtk error dialog" AT 0, 0 SIZE 200,200;
//     STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

 @ 0, 0 TOOLBAR oToolbar OF oWinDia SIZE  199 , 50

  @ htab+(nbut*32), 3 OWNERBUTTON /* OF oToolbar */ ;
      ON CLICK {||oWinDia:Close() } ;
      SIZE 28,24   /* FLAT */ ;
      BITMAP oObj_Exit TRANSPARENT COLOR hwg_ColorC2N("#DCDAD5") ;
      COORDINATES 0,4,0,0 ;
      TOOLTIP "Quit"

   oWinDia:Activate()

RETURN NIL

FUNCTION Quitter()
 oWinMain:Close()
RETURN NIL

FUNCTION CHECK_FILE ( cfi )
* Check, if file exist, otherwise terminate program
 IF .NOT. FILE( cfi )
  Hwg_MsgStop("File >" + cfi + "< not found, program terminated","File ERROR !")
  QUIT
 ENDIF
RETURN Nil

* ================================= EOF of gtk_err93.prg =============================================

