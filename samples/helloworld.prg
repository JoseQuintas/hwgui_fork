*
* helloworld.prg
*
* $Id$
*
* HWGUI - Harbour Win32,MacOS and Linux (GTK) GUI library
*
* This little Harbour program is called by tststconsapp.prg,
* demonstrating the call of console/terminal application
* by a HWGUI program.
*
* For more instructions to compile and usage on MacOS
* see:
* - tststconsapp.prg
* - install-macos.txt
*
* ===========================================================

FUNCTION MAIN()

LOCAL old_screen

   * The default mode ist regularly 24x80,
   * but on MS-DOS it is 25x80
   * This setting works on Windows Console, LINUX and MacOS terminal.
   SETMODE(25,80)

   SAVE SCREEN TO old_screen

   CLEAR SCREEN

   @ 0,0 TO 24,79 DOUBLE

   @ 10,10 TO 14, 40
   @ 12,12 SAY "Hello World"

   * INKEY(0) says at keys alt+C paused ... continue

   SET COLOR TO R/W
   @ 21, 10 SAY "Press any key for quit ==>"
   INKEY(0)

   RESTORE SCREEN FROM old_screen

   IF .T. // warning -w3 -es2
      QUIT
   ENDIF

RETURN NIL


* =================== EOF of helloworld.prg ================
