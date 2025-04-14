/*
 * GetWinVers.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Sample for getting windows version identifiers
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 * Copyright 2020 Wilfried Brunken, DF7BE
 *
*/
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

/* Read the function documentation of the called functions for
   return values on non Windows operation systems (GTK)
*/

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow
   LOCAL nmin, nmaj, bwin, bwin7, bwin10

   bwin    := hwg_isWindows()
   bwin7   := hwg_isWin7()
   bwin10  := hwg_isWin10()
   nmin    := hwg_GetWinMinorVers()
   nmaj    := hwg_GetWinMajorVers()

   INIT WINDOW oMainWindow MAIN TITLE "Windows Version" ;
     AT 0,0 SIZE 100,100

   hwg_MsgInfo( ;
   "Windows    : " + LOGICAL2STR(bwin)   + CHR(10) + ;
   "Windows 7  : " + LOGICAL2STR(bwin7)  + CHR(10) + ;
   "Windows 10 : " + LOGICAL2STR(bwin10) + CHR(10) + ;
   "Major= " + ALLTRIM( STR( nmaj ) ) + CHR(10) + ;
   "Minor= " + ALLTRIM( STR( nmin ) ), "Windows Version" )
  ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

FUNCTION LOGICAL2STR( bl )

RETURN IIF( bl, "True", "False" )

* ====================== EOF of GetWinVers.prg ====================
