*
* tststconsapp.prg
*
* $Id$
*
* HWGUI - Harbour Win32,MacOS and Linux (GTK) GUI library
*
* This sample program demonstrates:
* 1. Start of an another HWGUI program from here
* 2. Start external Harbour application (Console/Terminal mode)
* by using functions:
* hwg_RunApp() (async mode)
* hwg_RunConsoleApp() (sync mode)
* hwg_RunConsApp() (async mode, GTK)
* hwg_ShellExecute() <under construction>

*
* Copyright 2024 Wilfried Brunken, DF7BE
* https://sourceforge.net/projects/cllog/
*
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No  && Not yet tested
    *  GTK/MacOS:  Yes

/*

 Instructions:
 - First compile the HWGUI program to be called by this program:
   hbmk2 demobrowsearr.hbp (Windows, MacOS & LINUX)
 - Compile the Harbour Console/Terminal program to be called:
   hbmk2 helloworld.prg (Windows & LINUX)
   ./hbmk.sh helloworld (MacOS, optional for LINUX)
   (see above)
 - Compile this program by:
   hbmk2 tststconsapp.hbp
 - Start this programm by typing
     - tststconsapp.exe (Windows)
     - ./tststconsapp   (LINUX & MacOS)
   Do not start in background mode !

 Additional information:

 Special instructions to run Harbour and HWGUI programs see file
  install-macos.txt
 found in the main directory of HWGUI source code tree.

 1. On Windows and LINUX compile a simple Harbour Console/Terminal application by typing
    hbmk2 <prgname>.prg
    an the programs runs at its best.
    But on MacOS the start was refused by following error message:
    ./helloworld       the start is faulted with the following error message:
    dyld[1767]: Library not loaded: libharbour.dylib
    Referenced from: <F7B1FE28-9F46-3B03-BBF2-CCB7EC56B210> /Users/afumacbook/svnwork/
    hwgui/hwgui-code/hwgui/samples/helloworld
    Reason: tried: 'libharbour.dylib' (no such file),
    '/System/Volumes/Preboot/Cryptexes/OSlibharbour.dylib' (no such file),
    'libharbour.dylib' (no such file),
    '/Users/afumacbook/svnwork/hwgui/hwgui-code/hwgui/samples/libharbour.dylib' (no such file),
    '/System/Volumes/Preboot/Cryptexes/OS/Users/afumacbook/svnwork/hwgui/hwgui-code/hwgui/samples/libharbour.dylib'
    (no such file),
    '/Users/afumacbook/svnwork/hwgui/hwgui-code/hwgui/samples/libharbour.dylib' (no such file)
    zsh: abort      ./helloworld
     Now compile this sample by
             ./hbmk.sh helloworld
      and it runs now.
    Compile now the Harbour program by:
    ./hbmk.sh <prgname>
    without extension ".prg"
    and it starts.
    This script can also used on LINUX, it contains an OS
    autodetect function*.

    The special behavior:
    Windows:
    In this sample the external programs are started by using
    the function hwg_RunApp().
    The PATH setting is here inherited.
    Starting tststconsapp.exe by double click in the Explorer.
    GUI programs are started independant (HWGUI app or Notepad),
    so you can close tststconsapp.exe (asynchron)
    Starting a Harbour console app, it run in a new console.
    If tststconsapp.exe was started from an existing console,
    the Harbour console app runs here.
    ! But:
    After terminating the Harbour console app, a console is left.
    Closing it with "exit", the tststconsapp.exe is also finished.
    An extra console (with optional parameters cmd /C <options)
    does not appear.

    LINUX:
    In this sample the external programs are started by using
    the function hwg_RunConsApp().
    The PATH setting is here inherited.


    hwg_RunApp() works best by starting GUI applications
    by using the full path, but terminal apps are not running,
    because the IO channels stdin, stdout and stderror
    are assigned to /dev/null, so the keyboard interaction
    is broken.

    Open a Terminal and start this sample by entering:
    ./tststconsapp
    Warning!
    To avoid trouble with freezing do not start in background mode by
    ./tststconsapp &

    If a terminal program is started,
    it runs in the terminal, where tststconsapp is started.
    In the test menu also an item "show environent" by
    use command "env" exists, the full environment is
    displayed here.

    Closing the terminal by "exit", tststconsapp is also
    terminated.
    Calling a shell (bash), it is like Windows,
    not appearing, too.

    Finally: always use hwg_RunApp() and hwg_RunConsApp()
    with care, if Terminal/Console apps are started from here.
    Shells (cmd, command or bash) are not running !

*/

* Windows command shell
#define wincmd "cmd"   && Or "command", depends on Windows version

#include "hwgui.ch"

STATIC oDir

FUNCTION Main()

   LOCAL oWinMain

#ifdef __PLATFORM__WINDOWS
   oDir := "\"+Curdir()+"\"   && The complete path to program
#else
   oDir := "/"+Curdir()+"/"
#endif

   INIT WINDOW oWinMain ;
      MAIN  ;
      TITLE "Sample program Start external Programs" ;
      AT 0, 0 ;
      SIZE 600,400 ;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&File"
          MENUITEM "&Exit"              ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Test"
         MENUITEM "Start another &HWGUI application"     ACTION Test1()
         MENUITEM "&Start external Harbour application"     ACTION Test2()
#ifdef __PLATFORM__WINDOWS
       MENUITEM "Start &Notepad" ACTION START_PGM("notepad", ,.F.,.T.,.F.)

* The console window does not appear !
//       MENUITEM "show &environment"  ACTION  START_PGM(wincmd + " /C env",,.F.,.T.,.F.)
//        MENUITEM "&Cmd"  ACTION  START_PGM(wincmd,,.F.,.T.,.F.)
#else
#ifndef ___MACOSX___
* Devide code for MacOS, here hide start of gedit, it is only LINUX
     MENUITEM "Start &gedit"     ACTION START_PGM( "/usr/bin/gedit",, .F. )
#endif

* Attention: calling program freezes after is "exit"-ed (zombie process left ?)
//     MENUITEM "Start s&hell"     ACTION START_PGM("/usr/bin/bash",,.F.)  && Crashes at end

* ==> will be contstructed later, full description in  hwdoc_functions.hmtl missing, need to add later !
*     hwg_ShellExecute( cFile, cOperation, cParams, cDir, nFlag )

     MENUITEM "show &environment"     ACTION START_PGM( "env",, .F., .T., .F. )
#endif
      MENUITEM "Start not existing program"  ACTION START_PGM( "hello_nothing",, .F. )
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN Nil

FUNCTION Test1()

   * Start another HWGUI application
   START_PGM( "demobrowsearr" )

RETURN Nil

FUNCTION Test2()

   * Start external Harbour application
   START_PGM( "helloworld" )

RETURN Nil

* ====================================
FUNCTION START_PGM(cprgm,ccomm,laddpath,lcmd,lnotexe)

* Starts an external program or shell
* cprgm    : Program name without .exe
* ccomm    : Command prefix with options
*            (may be NIL or empty)
* laddpath : Set to .F., if
*            working directory may not
*            be added (default is .T.)
*            (set to .F., if program
*             call contains an absolute
*             path)
* lcmd     :  Set to .T., if cprgm is only
*             a shell command or program
*             reachable by PATH.
*             The check for existing file
*             is omitted.
*             Default is .F.
* lnotexe  : (Windows only)
*             Set to .F., if .EXE
*             may not be appendend to the program name,
*             for example for commands.
*             Default is .T.
*             This parameter is ignored
*             on LINUX and MacOS, it is
*             the normal behavior
* ===================================

    LOCAL ckommando, cexeext

   IF cprgm == NIL
     RETURN NIL
   ENDIF
   IF EMPTY(cprgm)
      RETURN NIL
   ENDIF

   IF laddpath == NIL
      laddpath := .T.
   ENDIF

   IF ccomm == NIL
      ccomm := ""
   ENDIF

   IF lnotexe == NIL
      lnotexe := .T.
   ENDIF

   IF lcmd == NIL
      lcmd := .F.
   ENDIF

   IF .NOT. EMPTY(ccomm)
      * Add a blank
      ccomm := ccomm + " "
   ENDIF

#ifdef __PLATFORM__WINDOWS
   IF lnotexe
      cexeext := ".exe"          && File extension of program
   ELSE
      cexeext := ""
   ENDIF
#else
* LINUX and MacOS, file exension is none
   cexeext := ""
#endif

* Compose command line for programm start
   IF laddpath
      ckommando := ccomm + oDir + cprgm + cexeext
   ELSE
      ckommando := ccomm + cprgm + cexeext
   ENDIF

   IF lcmd .OR. FILE(ckommando)
#ifdef __PLATFORM__WINDOWS
      hwg_RunApp(ckommando)
#else
 //    hwg_RunConsoleApp(ckommando)  && sync mode
      hwg_RunConsApp(ckommando)
 #endif
   ELSE
      SYS_FEHLST(ckommando)  && Display message for missing program file (Fehlstart)
   ENDIF

RETURN NIL

FUNCTION SYS_FEHLST(ckommando)

* Message for start of program with error
* (program file not found)
* ================================= *
   hwg_MsgStop("Program file " + ckommando + " not found !","Program Start")

RETURN 0

* ==================== EOF of tststconsapp.prg ====================
