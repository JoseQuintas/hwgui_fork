*
* escrita.prg
*
* $Id$
*
* HWGUI sample program:
* Tool buttons with bitmaps
* "Teste da Acentuação"
*

    * Status:
    *  WinAPI   :  No
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

REQUEST HB_CODEPAGE_PTISO, HB_CODEPAGE_PT850
#include "hwgui.ch"

FUNCTION Main()
   LOCAL oModDlg, oEditbox, onome, obar
   LOCAL meditbox := "", mnome := Space( 50 )
   LOCAL cbmppref
   LOCAL otool


cbmppref := ".." + hwg_GetDirSep() + ".." + hwg_GetDirSep() + "image" + hwg_GetDirSep()
* Check, if all bitmaps are existing, otherwise the program crashes or freezes
CHECK_FILE(cbmppref + "new.bmp")
CHECK_FILE(cbmppref + "book.bmp")
CHECK_FILE(cbmppref + "ok.ico")
CHECK_FILE(cbmppref + "door.bmp")
CHECK_FILE(cbmppref + "cancel.ico")

   INIT DIALOG oModDlg TITLE "Teste da Acentuação" ;
      AT 210, 10  SIZE 300, 300 ON INIT { ||otool:refresh(), hwg_Enablewindow( oTool:aItem[2,11], .F. ) }

   @ 0, 0 toolbar oTool of oModDlg size 50, 100 ID 700
   TOOLBUTTON  otool ;
      ID 701 ;
      BITMAP cbmppref + "new.bmp";
      STYLE 0;
      STATE 4;
      TEXT "teste1"  ;
      TOOLTIP "ola" ;
      ON CLICK { | x, y | (x), (y), hwg_Msginfo( "ola" ), hwg_Enablewindow( oTool:aItem[ 2, 11 ], .T. ) , hwg_Enablewindow( oTool:aItem[ 1, 11 ], .F. ) }

   TOOLBUTTON  otool ;
      ID 702 ;
      BITMAP cbmppref + "book.bmp";
      STYLE 0 ;
      STATE 4;
      TEXT "teste2"  ;
      TOOLTIP "ola2" ;
      ON CLICK { | x, y | (x), (y), hwg_Msginfo( "ola1" ), hwg_Enablewindow( oTool:aItem[ 1, 11 ], .T. ), hwg_Enablewindow( oTool:aItem[ 2, 11], .F. ) }

   TOOLBUTTON  otool ;
      ID 703 ;
      BITMAP cbmppref + "ok.ico";
      STYLE 0 ;
      STATE 4;
      TEXT "asdsa"  ;
      TOOLTIP "ola3" ;
      ON CLICK { | x, y | (x), (y), hwg_Msginfo( "ola2" ) }
   TOOLBUTTON  otool ;
      ID 702 ;
      STYLE 1 ;
      STATE 4;
      TEXT "teste2"  ;
      TOOLTIP "ola2" ;
      ON CLICK { | x, y | (x), (y), hwg_Msginfo( "ola3" ) }
   TOOLBUTTON  otool ;
      ID 702 ;
      BITMAP cbmppref + "door.bmp";  // DF7BE: tools.bmp does not exist, choose existing one
      STYLE 0 ;
      STATE 4;
      TEXT "teste2"  ;
      TOOLTIP "ola2" ;
      ON CLICK { | x, y | (x), (y), hwg_Msginfo( "ola4" ) }

   TOOLBUTTON  otool ;
      ID 702 ;
      BITMAP cbmppref + "cancel.ico";
      STYLE 0 ;
      STATE 4;
      TEXT "teste2"  ;
      TOOLTIP "ola2" ;
      ON CLICK { | x, y | (x), (y), hwg_Msginfo( "ola5" ) }



   @ 20, 35 EDITBOX oEditbox CAPTION ""    ;
      STYLE WS_DLGFRAME              ;
      SIZE 260, 26

   @ 20, 75 GET onome VAR mnome SIZE 260, 26

   @ 20, 105 progressbar obar size 260, 26  barwidth 100

   ACTIVATE DIALOG oModDlg

   hwg_Msginfo( meditbox , "Contents of variable meditbox")
   hwg_Msginfo( OEDITBOX:TITLE , "Title of OEDITBOX")
   hwg_Msginfo( mnome  , "Contents of variable mnome")

   RETURN Nil

FUNCTION CHECK_FILE ( cfi )
* Check, if file exist, otherwise terminate program
 IF .NOT. FILE( cfi )
  Hwg_MsgStop("File >" + cfi + "< not found, program terminated","File ERROR !")
  QUIT
 ENDIF
RETURN Nil

* =================== EOF of escrita.prg ====================

