*
* teststrrev.prg
*
* $Id$
*
* HWGUI - Harbour Win32 GUI and GTK library source code:
*
* Sample program testing function hwg_strrev(cstring):
* Reverse strings with UTF-8
* and GET with Euro currency sign support.
*
*   Reverses a string.
*   This is the equivalent strrev() function from the standard C library,
*   but extended to understand UTF-8.
*   cstring may not exceed 511 bytes, inclusive length of all
*   used UTF-8 characters.
*
* Copyright 2024 Wilfried Brunken, DF7BE
*
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No
    *  GTK/MacOS:  Yes

/*

 More instructions:
 ==================
 (by DF7BE)

 Handling the Euro currency sign in HWGUI programs.
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 Windows:
 ########

 The Euro sign is supported by some national charsets
 of Windows. Be sure, that the current language setting
 has the Euro sign inside (for example WIN1252).
 So no more settings or REQUEST's are necessary,
 except you want to trancode charsets
 (for example to write records into a DBF).


 On Windows 10 and 11 the Euro sign is regularly CHR(128) = 0x80


 LINUX, MacOS and other operating systems supporting UTF-8
 #########################################################
 UTF-8 contains the Euro curency sign.
 So also no settings are necessary.

 The Euro sign is represented as CHR(226) + CHR(130) + CHR(172).

 Info for MS-DOS: CHR(213) in charset IBM-858


 Obscure behavior in GET fields:
 ###############################
 (see also command description of @ <x>,<y> GET ...
  in the HWGUI documentation)

 Some trouble with GET, some keys are ignored
 The symptom:
 ------------

 - Windows 11:
   On the german keyboard some important ASCII characters are only reached
   via pressing the "AltGr" and another key here listed:
   @ : AltGr + Q
   \ : AltGr + ß
   { : AltGr + 7
   } : AltGr + 9
   [ : AltGr + 8
   ] : AltGr + 9
   ~ : AltGr + +
   | : AltGr + <

   Euro currency sign: AltGr + E

   All the input of these characters are complete ignored !!!

 - LINUX
    All the above characters kann be entered, but not at the
    desired position (it seems, that the characters are inserted
    2 or 3 positions before the cursor position)
    This problem appears also, if a blank is entered.
    Entering Alt Gr + \ here the backslash is inserted.
    Alt Gr + Q = @ was inserted, if repeated.



 The Solution:
 -------------

  Very easy: be shure, that the input field of GET has enough
  SIZE displaying all characters of possible input !

  You can reproduce this situation with this sample program:
  In dialog "Test" ==>  "Set max char number":
  Set the default of 20 to maximum of 511,
  and the behavior described above is present.
  Reset to a lower value, the behavior is normal as well known.

  To check in your HWGUI, please enter simply a string of numbers
  in the entry field up the end, for example:
  1234567890123456789012 ...

*/


#include "hwgui.ch"

STATIC nmaxchars

FUNCTION MAIN()

  LOCAL oWinMain

#ifdef __LINUX__
* LINUX Codepage
REQUEST HB_CODEPAGE_UTF8
REQUEST HB_CODEPAGE_UTF8EX
#endif

  nmaxchars := 20  && Max 511 for hwg_Strrev()

   INIT WINDOW oWinMain ;
      MAIN  ;
      TITLE "Sample program for function hwg_Strrev()" ;
      AT    100, 100 ;
      SIZE  600,400;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&File"
          MENUITEM "&Exit"              ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Test"
         MENUITEM "&Reverse string"     ACTION Teste()
         MENUITEM "Set max char &number"  ACTION SetChars()
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN Nil

STATIC FUNCTION Teste()

   LOCAL Strrev
   LOCAL oLabel1, oLabel2, oLabel3, oLabel4, oLabel5, oLabel6
   LOCAL oEditbox1, oButton1, oButton2
   LOCAL cstring, cneustr

* Init

  cstring := SPACE(nmaxchars)
  cstring := hwg_GET_Helper(cstring,nmaxchars)
  cneustr := ""

  INIT DIALOG Strrev ;
     TITLE "Test of function hwg_Strrev()" ;
     AT 279,216 ;
     SIZE 966,475 ;
     STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE ;
     NOEXIT


   @ 40,20 SAY oLabel2 ;
      CAPTION "Test of hwg_Strrev()"  ;
      SIZE 246,22

   @ 40,55 SAY oLabel1 ;
      CAPTION "Enter a string (max " + ALLTRIM(STR(nmaxchars)) + " characters) :"  ;
     SIZE 386,22

   @ 40,102 GET oEditbox1 ;
      VAR cstring  ;
      SIZE 865,24 ;
      STYLE WS_BORDER

   @ 40,150 SAY oLabel3 ;
      CAPTION "UTF-8 support  (hwg__isUnicode()  :  "  ;
      SIZE 391,22

   @ 509,150 SAY oLabel4 ;
      CAPTION IIF(hwg__isUnicode(),"Yes","No") ;
      SIZE 249,22

   @ 40,190 SAY oLabel5 ;
      CAPTION "Result :"  ;
      SIZE 80,22

   @ 40,245 SAY oLabel6 ;
      CAPTION cneustr  ;
      SIZE 865,22

   @ 53,305 BUTTON oButton1 ;
      CAPTION "Reverse string"   ;
      SIZE 259,32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | cneustr := hwg_Strrev(cstring) , oLabel6:SetText(ALLTRIM(cneustr)) }
        * Attention !
        * On Windows the result string contains blanks
        * from the GET field, so the result must be
        * ALLTRIM'ed for correct display.

   @ 626,305 BUTTON oButton2 ;
      CAPTION "Exit"   ;
      SIZE 80,32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Strrev:Close() }

   ACTIVATE DIALOG Strrev CENTER
// RETURN Strrev:lresult


RETURN NIL

STATIC FUNCTION SetChars()

   LOCAL setmaxchars
   LOCAL oLabel1, oEditbox1, oButton1, oButton2
   LOCAL lAbbruch, nneu

   lAbbruch := .T.
   nneu    := nmaxchars

   INIT DIALOG setmaxchars ;
      TITLE "Set max numbers of characters" ;
      AT 387,215 ;
      SIZE 554,231 ;
      NOEXIT ;
      STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 35,11 SAY oLabel1 ;
      CAPTION "Enter maximal numbers of characters (1...511) :"  ;
      SIZE 415,22

   @ 35,50 GET oEditbox1 ;
      VAR nneu  ;
      SIZE 80,24 ;
      PICTURE "999" ;
      STYLE WS_BORDER ;
      VALID { | | IIF( (nneu > 0) .AND. (nneu < 512) , .T. , .F. ) }

   @ 41,100 BUTTON oButton1 ;
      CAPTION "OK"  ;
      SIZE 80,32 ;
      STYLE WS_TABSTOP+BS_FLAT ;
      ON CLICK {|| lAbbruch := .F. , setmaxchars:Close() }

   @ 401,100 BUTTON oButton2 ;
      CAPTION "Cancel"   ;
      SIZE 80,32 ;
      STYLE WS_TABSTOP+BS_FLAT ;
      ON CLICK {||  setmaxchars:Close() }

   ACTIVATE DIALOG setmaxchars CENTER

   IF .NOT. lAbbruch  && not cancelled or ESC key
      nmaxchars := nneu
   ENDIF


RETURN NIL

* ==================== EOF of teststrrev.prg ============================
