*
* helloworld.prg
*
* Sample program iconification
* of terminal/console programs.
* 
* $Id$
*
* Advice:
* To port old clipper programs under MS-DOS
* the terminal/console geometry must be set to
* 80x25, but on most systems the terminal/console
* starts with 80x24.
* So set them to 80x25 in the properties dialog,
* in most cases, the setting is stored permanently.
* On Windows, the SETMODE() function do this
* automatically.
* 
* Compile with
* hbmk2 helloworld.prg

FUNCTION MAIN()

#ifdef __PLATFORM__WINDOWS
REQUEST HB_GT_WIN_DEFAULT
#endif

SETMODE(25,80)
SET CURSOR OFF
CLEAR SCREEN
  @ 0 , 0 TO 24,79 DOUBLE

  @ 10, 10 SAY "Hello World !"
  
  @ 21, 10 SAY "Be shure, that the 25th line is visible !"
  @ 22, 10 SAY "!"
  @ 23, 10 SAY "V"
  
  @ 16, 10 SAY "Quit ==> Press any key"
  
  
  WAIT ""

QUIT


RETURN NIL

* ========================= EOF of helloworld.prg ===========================