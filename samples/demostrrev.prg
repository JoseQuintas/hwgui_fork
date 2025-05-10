*
* demostrrev.prg
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

#ifdef __LINUX__
* LINUX Codepage
  REQUEST HB_CODEPAGE_UTF8
  REQUEST HB_CODEPAGE_UTF8EX
#endif

#include "hwgui.ch"

FUNCTION DemoStrRev( lWithDialog, oDlg )

   LOCAL aLabel := Array(6), aButton := Array(2)
   LOCAL oEditbox1, cNormal, cReverse

   hb_Default( @lWithDialog, .T. )

   cNormal  := SPACE(511)
   cNormal  := hwg_GET_Helper( cNormal, 511 )
   cReverse := ""

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demostrrev.prg - Test of function hwg_Strrev()" ;
         AT    279, 216 ;
         SIZE  966, 475 ;
         STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE ;
         NOEXIT
   ENDIF

   @ 40, 20 SAY aLabel[1] ;
      CAPTION "Test of hwg_Strrev()"  ;
      SIZE 246, 22

   @ 40, 55 SAY aLabel[2] ;
      CAPTION "Enter a string (max 511 characters) :"  ;
      SIZE 386, 22

   @ 40, 102 GET oEditbox1 ;
      VAR   cNormal ;
      SIZE  865, 24 ;
      STYLE WS_BORDER

   @ 40, 150 SAY aLabel[3] ;
      CAPTION "UTF-8 support  (hwg__isUnicode()  :  "  ;
      SIZE 391, 22

   @ 509, 150 SAY aLabel[4] ;
      CAPTION IIF( hwg__isUnicode(), "Yes", "No" ) ;
      SIZE 249, 22

   @ 40, 190 SAY aLabel[5] ;
      CAPTION "Result :"  ;
      SIZE 80, 22

   @ 40, 245 SAY aLabel[6] ;
      CAPTION cReverse ;
      SIZE 865, 22

   @ 53, 305 BUTTON aButton[1] ;
      CAPTION "Reverse string"   ;
      SIZE 259, 32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { ||
         cNormal := AllTrim( cNormal )
         IF Len( cNormal ) > 511
            cReverse := "More than 511 characters"
         ELSE
            cReverse := hwg_Strrev( cNormal )
         ENDIF
         aLabel[6]:SetText( cReverse )
         RETURN Nil
         }

   @ 626, 305 BUTTON aButton[2] ;
      CAPTION "Exit"   ;
      SIZE    80, 32 ;
      STYLE   WS_TABSTOP + BS_FLAT ;
      ON CLICK { || oDlg:Close() }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN NIL

* ==================== EOF of demostrrev.prg ============================
