/*
 *
 * demofunc.prg
 *
 * Test program sample for HWGUI (hwg_*) standalone functions
 *
 * $Id$
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Copyright 2020-2024 Wilfried Brunken, DF7BE
*/

    * Status:
    *   WinAPI   :  Yes
    *   GTK/Linux:  Yes
    *   GTK/Win  :  Yes
    *  GTK/MacOS :  Yes
/*
  Add extensions to your own needs
*/

/*
 List of used HWGUI standalone functions:

 hwg_GetUTCTimeDate()
 hwg_GetDateANSI()
 hwg_GetUTCDateANSI()
 hwg_GetUTCTime()
 hwg_getCentury()
 hwg_GetWindowsDir()
 hwg_GetTempDir()
 hwg_CreateTempfileName
 Activate / Deactivate  Button
 hwg_CompleteFullPath()
 hwg_ShowCursor()
 hwg_GetCursorType() && GTK only
 hwg_IsLeapYear ( nyear )
 hwg_GUIType()
 hwg_RunApp()
 hwg_Has_Win_Euro_Support()
 hwg_FileModTimeU()
 hwg_FileModTime()
 hwg_Get_Time_Shift()
 hwg_ProcFileExt()
 hwg_ChrDir()
 hwg_EOLStyle()
 hwg_RunConsoleApp( cCommand [, cOutFile] )
     coutfile is fixed set to "output.txt"


 Harbour functions:
 CurDir()
 OS()

Other functions:
 - Build date and time (Harbour predefined macros)
 - Origin path
*/


#include "hwgui.ch"
#include "common.ch"

#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

#ifdef __PLATFORM__WINDOWS
   #define BUTTON_HEIGHT 20
#ELSE
   #define BUTTON_HEIGHT 25
#endif
#define BUTTON_WIDTH 200
// On GTK3 buttons are greater, than need more space between buttons
#ifdef __GTK3__
   #define LINE_HEIGHT 35
#else
   #define LINE_HEIGHT 30
#endif

MEMVAR cDirSep , bgtk , ndefaultcsrtype

STATIC nRowPos := -1, nColPos := -1

FUNCTION DemoFunc( lWithDialog, oDlg )

   LOCAL coriginp, coriginchdir
   LOCAL oFont, nQtClicks := 0
   LOCAL oButton1, oButton2, oButton3, oButton4, oButton5, oButton6, oButton7, oButton8, oButton9
   LOCAL oButton10, oButton11 , oButton12 , oButton15 , oButton16 , oButton17
   LOCAL oButton18, oButton19 , oButton20 , oButton22 , oButton23 , oButton24 , oButton25
   LOCAL oButton26, oButton27, oButton28, oButton29
   LOCAL oButton30, oButton31, oButton32, oButton33, obutton34, obutton35
   LOCAL obutton36, obutton37, obutton38

   PUBLIC cDirSep := hwg_GetDirSep()
   PUBLIC bgtk , ndefaultcsrtype

   hb_Default( @lWithDialog, .T. )

   // when called from another program
   nColPos := -1
   nRowPos := -1

* === Get origin path (this were the exe file is located) ===
*              For multi platform usage !
*
*    argv[0]: The argv[0] argument passed to the main()
*    function contains the path and name of the executable file.
*
*    int main(int argc, char *argv[]) {
*        printf("Executable path: %s", argv[0]);
*        return 0;
*    }
*    but this is reachable from Harbour and HWGUI by following sequence:
*
 * Get the origin path and name
   coriginp := hb_argV( 0 )

 * Change to origin directory
  IF .NOT. EMPTY(coriginp)
     coriginchdir := hwg_Dirname(coriginp)
     //ft_ChDir( coriginp )
     hwg_CHDIR(coriginchdir)
  ENDIF

* Trouble with GTK3:
* Buttons are greater than nheigth, so
* space between them must be increased

   * Detect GTK build
   bgtk := .F.

#ifdef __GTK__
   bgtk := .T.
#endif

   SET DATE ANSI  && YY(YY).MM.TT

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -10 && vorher -13
#else
  PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12 && vorher 13
#endif

   * save default cursor style in a numeric variable for
   * later recovery after cursor hide action.
#ifdef __GTK__
   ndefaultcsrtype := hwg_GetCursorType() && GTK only
#else
   ndefaultcsrtype := 0  && not needed on WinAPI
#endif

   // hwg_msginfo(Str(ndefaultcsrtype))

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demofunc.prg - Test Of Standalone HWGUI Functions" ;
         AT 1,1 ;
         SIZE 770,548 ;
         STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE
   ENDIF

   ButtonForSample( "demofunc.prg" )

   IF lWithDialog
      @ ColPos(), nRowPos BUTTON oButton1 ;
         CAPTION "Exit" ;
         SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
         FONT oFont ;
         STYLE WS_TABSTOP + BS_FLAT ON CLICK { || oDlg:Close() } ;
         TOOLTIP "Terminate Program"
   ENDIF

   @ ColPos(), nRowPos BUTTON oButton10 ;
      CAPTION "Enabled" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || oButton11:Enable(), oButton11:SetText( "Enabled" ), oButton10:SetText( "Disabled" ), oButton10:Disable() }

   @ ColPos(), nRowPos BUTTON oButton11 ;
      CAPTION "Enabled" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || oButton10:Enable(), oButton10:SetText( "Enabled" ), oButton11:SetText( "Disabled" ), oButton11:Disable() }

   @ ColPos(), nRowPos BUTTON oButton27 CAPTION "Caption Updated 0" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || oButton27:SetText( "Caption Updated " + Ltrim( Str( ++nQtClicks, 3 ) ) ) }

   @ ColPos(), nRowPos BUTTON oButton2 ;
      CAPTION "CENTURY ON"   ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK  { | | CENT_ON() }

   @ ColPos(), nRowPos BUTTON oButton3 ;
      CAPTION "CENTURY OFF"   ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK  { | | CENT_OFF() }

   @ ColPos(), nRowPos BUTTON oButton4 ;
      CAPTION "DATE()"   ;
         SIZE BUTTON_WIDTH, BUTTON_HEIGHT FONT oFont  ;
         STYLE WS_TABSTOP + BS_FLAT ;
         ON CLICK { | |Funkt(DATE(),"D","DATE()") }

   @ ColPos(), nRowPos BUTTON oButton5 ;
      CAPTION "Summary"   ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | |  fSUMM() }

   @ ColPos(), nRowPos BUTTON oButton6 ;
      CAPTION "hwg_GetUTCTimeDate()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK ;
       { | |Funkt(hwg_GetUTCTimeDate(),"C","hwg_GetUTCTimeDate()") }

   @ ColPos(), nRowPos BUTTON oButton7 ;
      CAPTION "hwg_getCentury()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Funkt(hwg_getCentury(),"O","hwg_getCentury()") }

   /* Sample for a Windows only function,
      use a intermediate function with compiler switch for platform windows   */

   @ ColPos(), nRowPos BUTTON oButton8 ;
      CAPTION "hwg_GetWindowsDir()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Funkt(GET_WINDIR(),"C","hwg_GetWindowsDir()") }

   @ ColPos(), nRowPos BUTTON oButton9 ;
      CAPTION "hwg_GetTempDir()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | |Funkt(hwg_GetTempDir(),"C","hwg_GetTempDir()") }

   @ ColPos(), nRowPos BUTTON oButton9 ;
      CAPTION "hwg_CreateTempfileName()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | |Funkt(hwg_CreateTempfileName(),"C","hwg_CreateTempfileName()") }

   @ ColPos(), nRowPos BUTTON oButton12 ;
      CAPTION "GetWindowsDir Full" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Funkt(GET_WINDIR_FULL(),"C","GET_WINDIR_FULL()") }

   @ ColPos(), nRowPos BUTTON oButton15 ;
      CAPTION "CurDir()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Funkt(CurDir(),"C","CurDir()") }

   @ ColPos(), nRowPos BUTTON oButton16 ;
      CAPTION "hwg_CurDir()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Funkt(hwg_CurDir(),"C","hwg_CurDir()") }

   @ ColPos(), nRowPos  BUTTON oButton17 ;
      CAPTION "hwg_GetDateANSI()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Funkt(hwg_GetDateANSI(),"C","hwg_GetDateANSI()") }

   @ ColPos(), nRowPos BUTTON oButton18 ;
      CAPTION "hwg_GetUTCDateANSI()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Funkt(hwg_GetUTCDateANSI(),"C","hwg_GetUTCDateANSI()") }

   @ ColPos(), nRowPos BUTTON oButton19 ;
      CAPTION "hwg_GetUTCTime()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Funkt(hwg_GetUTCTime(),"C","hwg_GetUTCTime()") }

   * Hide / recovery of mouse cursor in extra dialog
   @ ColPos(), nRowPos BUTTON oButton20 ;
      CAPTION "Cursor functions" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | HIDE_CURSOR ( oFont, oDlg ) }

   @ ColPos(), nRowPos BUTTON oButton22 ;
      CAPTION "hwg_IsLeapYear()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | TestLeapYear() }

   @ ColPos(), nRowPos BUTTON oButton23 ;
      CAPTION "hwg_Has_Win_Euro_Support()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
         ON CLICK { | |  Funkt(hwg_Has_Win_Euro_Support(),"L","hwg_Has_Win_Euro_Support()" ) }

   @ ColPos(), nRowPos BUTTON oButton24 ;
      CAPTION "hwg_FileModTimeU()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | |  Test_FileModTimeU() }

   @ ColPos(), nRowPos BUTTON oButton25 ;
      CAPTION "hwg_FileModTime()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | |  Test_FileModTime() }

   @ ColPos(), nRowPos BUTTON oButton26 ;
      CAPTION "hwg_Get_Time_Shift()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Funkt(hwg_Get_Time_Shift(),"N","hwg_Get_Time_Shift()") }

   @ ColPos(), nRowPos BUTTON oButton28 ;
      CAPTION "hwg_GUIType()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Funkt(hwg_GUIType(),"C","hwg_GUIType()") }

   @ ColPos(), nRowPos BUTTON oButton29 ;
      CAPTION "hwg_RunApp()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | do_the_RunApp() }

    @ ColPos(), nRowPos BUTTON obutton37 ;
       CAPTION "hwg_RunConsoleApp()" ;
       SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
       FONT oFont  ;
       STYLE WS_TABSTOP + BS_FLAT ;
       ON CLICK { | | do_the_RunConsoleApp() }

   @ ColPos(), nRowPos BUTTON oButton30 ;
      CAPTION "hwg_HdSerial()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Test_hwg_HdSerial() }

   @ ColPos(), nRowPos BUTTON oButton31 ;
      CAPTION "hwg_HdGetSerial()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Test_hwg_HdGetSerial() }

   @ ColPos(), nRowPos BUTTON oButton32 ;
      CAPTION "hwg_ProcFileExt()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Test_hwg_ProcFileExt() }

   /* Added August 2024 also for MacOS port */

    @ ColPos(), nRowPos BUTTON oButton33 ;
       CAPTION "OS()" ;
       SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
       FONT oFont  ;
       STYLE WS_TABSTOP + BS_FLAT ;
       ON CLICK { | | Test_hb_os() }

    @ ColPos(), nRowPos BUTTON oButton34 ;
       CAPTION "Build date" ;
       SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
       FONT oFont  ;
       STYLE WS_TABSTOP + BS_FLAT ;
       ON CLICK { | | Test_BuildDatetime() }

    @ ColPos(), nRowPos BUTTON oButton35 ;
       CAPTION "Origin path" ;
       SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
       FONT oFont  ;
       STYLE WS_TABSTOP + BS_FLAT ;
       ON CLICK { | | Test_originpath(coriginp) }

   @ ColPos(), nRowPos BUTTON obutton36 ;
      CAPTION "hwg_EOLStyle()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Test_hwg_EOLStyle() }

   @ ColPos(), nRowPos BUTTON obutton38 ;
      CAPTION "hwg_GetEpoch()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { | | Test_hwg_GetEpoch() }

   @ ColPos(), nRowPos BUTTON oButton22 ;
      CAPTION "hwg_IsWindows()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || hwg_MsgInfo( "Is Windows?" + hb_ValToExp( hwg_IsWindows() ) ) }

   @ ColPos(), nRowPos BUTTON oButton22 ;
      CAPTION "hwg_IsWin7()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || hwg_MsgInfo( "Is Win7?" + hb_ValToExp( hwg_IsWin7() ) ) }

   @ ColPos(), nRowPos BUTTON oButton22 ;
      CAPTION "hwg_IsWin10()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || hwg_MsgInfo( "Is Win10?" + hb_ValToExp( hwg_IsWin10() ) ) }

   @ ColPos(), nRowPos BUTTON oButton22 ;
      CAPTION "hwg_GetWinMinorVers()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || hwg_MsgInfo( "WinMinorVers:" + hb_ValToExp( hwg_GetWinMinorVers() ) ) }

   @ ColPos(), nRowPos BUTTON oButton22 ;
      CAPTION "hwg_GetWinMajorVers()" ;
      SIZE BUTTON_WIDTH, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || hwg_MsgInfo( "WinMajorVers:" + hb_ValToExp( hwg_GetWinMajorVers() ) ) }

   /* Last  obuttonxx is obutton38 */

   /* Disable buttons for Windows only functions */
#ifndef __PLATFORM__WINDOWS
   oButton8:Disable()
#endif
   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

STATIC FUNCTION HIDE_CURSOR ( oFont, oDlgMain )

   LOCAL odlg , oButton1 , oButton2 , oButton3 , ncursor , hmain

   (oDlgMain) // -w3 -es2 where it is used ?????
   * oDlgMain: object variable of main window only for GTK

   * Init, otherwise crashes, if dialog closed without any action.
   ncursor := 0

   * For hiding mouse cursor on main window
   //     hmain := oDlgMain:handle

   INIT DIALOG odlg ;
      TITLE "Hide / show cursor"  ;
      AT 0,0   ;
      SIZE 400 , 200 ;
      FONT oFont ;
      CLIPPER

   * Hide cursor only in dialog window.
   hmain := odlg:handle

   @ 25 , 35 BUTTON oButton1 ;
      CAPTION "hwg_ShowCursor(.F.)" ;
      SIZE 140, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK ;
        { || Funkt( ncursor := hwg_ShowCursor(.F.,hmain,ndefaultcsrtype),"N","hwg_ShowCursor(.F.)") , ;
            hwg_Setfocus(oButton2:handle) }

   @ 180 , 35 BUTTON oButton2 ;
      CAPTION "hwg_ShowCursor(.T.)" ;
      SIZE 140, BUTTON_HEIGHT FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK ;
        { || Funkt( ncursor := hwg_ShowCursor(.T.,hmain,ndefaultcsrtype),"N","hwg_ShowCursor(.T.)") }

   @ 25 , 70 BUTTON oButton3 ;
      CAPTION "Return" ;
      SIZE 140, BUTTON_HEIGHT ;
      FONT oFont  ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || odlg:Close }

   ACTIVATE DIALOG odlg CENTER

#ifndef __GTK__
   * Activate cursor before return to main window
   * crash on GTK, because handle is lost after leaving dialog.
   DO WHILE ncursor < 0
      ncursor := hwg_ShowCursor(.T.)   && ,hmain,ndefaultcsrtype)  : crash
   ENDDO
#endif

RETURN Nil

STATIC FUNCTION Funkt( rval, cType , cfunkt)
   * ====================================
   * Executes a function and displays the
   * result in a info messagebox.
   * rval: Return value of the called function
   * cfunkt: Name of the function for display in title.
   * cType: Type of rval
   * "C" "N" "L" "D"
   * "O" ==> "L", but display ON/OFF
   * ====================================

   DO CASE
   CASE cType == "C"
      hwg_MsgInfo("Return Value: >" + rval + "<", "Function: " + cfunkt )
   CASE cType == "N"
      hwg_MsgInfo("Return Value: >" + ALLTRIM(STR(rval)) + "<", "Function: " + cfunkt )
   CASE cType == "L"
      hwg_MsgInfo("Return Value: >" + IIF(rval,"True","False") + "<", "Function: " + cfunkt )
   CASE cType == "D"
      hwg_MsgInfo("Return Value: >" + DTOC(rval) + "<", "Function: " + cfunkt )
   CASE cType == "O"
      hwg_MsgInfo("Return Value: >" + IIF(rval,"ON","OFF") + "<", "Function: " + cfunkt )
   ENDCASE

RETURN Nil

STATIC FUNCTION CENT_ON()

   SET CENTURY ON

RETURN Nil

STATIC FUNCTION CENT_OFF()

   SET CENTURY OFF

RETURN Nil

STATIC FUNCTION N2STR( numb )

   RETURN ALLTRIM( STR( numb ) )

STATIC FUNCTION TotF( btf )

RETURN IIF( btf, "True", "False" )

STATIC FUNCTION fSUMM()

  hwg_Msginfo( ;
       "OS(): " + OS() + CHR(10) + ;
       "Hwgui Version  : " + hwg_Version() + CHR(10) + ;
       "Windows : " + TotF(hwg_isWindows() )  + CHR(10) + ;
       "Windows 7: " + TotF(hwg_isWin7() ) + CHR(10) + ;
       "Windows 10: " + TotF(hwg_isWin10() ) + CHR(10) + ;
       "Windows Maj.Vers.: " + N2STR(hwg_GetWinMajorVers() ) + CHR(10) + ;
       "Windows Min.Vers.: " + N2STR(hwg_GetWinMinorVers() ) + CHR(10) + ;
       "Unicode : " + TotF(hwg__isUnicode() ) + CHR(10) + ;
       "Default user lang. :" + HWG_DEFUSERLANG() + CHR(10) +  ;
       "Locale :" + hwg_GetLocaleInfo() + CHR(10) +  ;
       "Locale (N) :" + N2STR(hwg_GetLocaleInfoN()) + CHR(10) +  ;
       "UTC :" + HWG_GETUTCTIMEDATE() + CHR(10) +  ;
       "GTK : " + TotF(bgtk)  + CHR(10) + ;
       "Dir Separator: " + cDirSep ;
   )

RETURN Nil

STATIC FUNCTION GET_WINDIR()

   LOCAL verz

#ifndef __PLATFORM__WINDOWS
   verz := "<none>: Windows only"
#else
   verz := hwg_GetWindowsDir()
#endif

RETURN verz

STATIC FUNCTION GET_WINDIR_FULL()

   LOCAL verz

#ifndef __PLATFORM__WINDOWS
   verz := "<none>: Windows only"
#else
   verz := hwg_CompleteFullPath(hwg_GetWindowsDir() )
#endif

RETURN verz

STATIC FUNCTION TestLeapYear()

   LOCAL nyeart
   LOCAL oTestLeapYear
   LOCAL oLabel1, oEditbox1, oButton1 , oButton2

   nyeart := YEAR( DATE() )  && Preset recent year

   INIT DIALOG oTestLeapYear ;
      TITLE "hwg_IsLeapYear()" ;
      AT 738, 134 ;
      SIZE 516, 336 ;
      NOEXIT ;
      STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE

   @ 54, 44 SAY oLabel1 ;
      CAPTION "Enter a year 1583 and higher"  ;
      SIZE 380, 22

   @ 61, 102 GET oEditbox1 ;
      VAR nyeart  ;
      SIZE 325, 24 ;
      STYLE WS_BORDER   ;
      PICTURE "9999"

   @ 63, 181 BUTTON oButton1 ;
      CAPTION "OK"   ;
      SIZE 80, 32 ;
      STYLE WS_TABSTOP + BS_FLAT   ;
      ON CLICK { | | Res_LeapYear(nyeart) }

   @ 200, 181 BUTTON oButton2 ;
      CAPTION "Cancel"   ;
      SIZE 80, 32 ;
      STYLE WS_TABSTOP + BS_FLAT   ;
      ON CLICK { | | oTestLeapYear:Close() }

   ACTIVATE DIALOG oTestLeapYear CENTER

RETURN Nil

STATIC FUNCTION Res_LeapYear( nyeart )

   LOCAL cRet

   cRet := IIF( hwg_IsLeapYear(nyeart), "TRUE", "FALSE" )
   hwg_MsgInfo("Result of Res_LeapYear(" + ALLTRIM(STR(nyeart)) + ")=" + cRet , "hwg_IsLeapYear()" )

RETURN Nil

STATIC FUNCTION FILE_SEL()

   LOCAL cstartvz,fname

   * Get current directory as start directory
   cstartvz := Curdir()
   fname := hwg_Selectfile("Select a file" , "*.*", cstartvz )

RETURN fname

STATIC FUNCTION Test_FileModTimeU()

   LOCAL fn, ctim

   fn := FILE_SEL()
   IF EMPTY( fn )
      RETURN NIL
   ENDIF
   ctim := hwg_FileModTimeU(fn)
   hwg_MsgInfo("Modification date and time (UTC) of file" + ;
      CHR(10) + fn + " is :" + CHR(10) +  ctim, "Result of hwg_FileModTimeU()")

RETURN Nil

STATIC FUNCTION Test_FileModTime()

   LOCAL fn, ctim

   fn := FILE_SEL()
   IF EMPTY( fn )
      RETURN Nil
   ENDIF
   ctim := hwg_FileModTime(fn)
   hwg_MsgInfo("Modification date and time (local) of file" + ;
      CHR(10) + fn + " is :" + CHR(10) +  ctim, "Result of hwg_FileModTime()")

RETURN Nil

STATIC FUNCTION do_the_RunApp()

   LOCAL cCmd , rc , cgt

   cCmd := _hwg_RunApp()
   IF EMPTY(cCmd)
      RETURN NIL
   ENDIF

   rc := hwg_RunApp(cCmd)

   cgt := hwg_GUIType()

   DO CASE
   CASE cgt == "WinAPI"
      hwg_MsgInfo("Return Code: " + ALLTRIM(STR(rc)),"Result of hwg_RunApp()")
   CASE cgt == "GTK2"
      hwg_MsgInfo("Return Code: " + ALLTRIM(STR(rc)),"Result of hwg_RunApp()")
//  hwg_MsgInfo("Return Code: " + hb_ValToExp(),"Result of hwg_RunApp()")
   CASE cgt == "GTK3"
      hwg_MsgInfo("Return Code: " + ALLTRIM(STR(rc)),"Result of hwg_RunApp()")
//  hwg_MsgInfo("Return Code: " + hb_ValToExp(),"Result of hwg_RunApp()")
   ENDCASE

RETURN NIL

STATIC FUNCTION do_the_RunConsoleApp()

   LOCAL cCmd , rc , cgt

* Get command
   cCmd := _hwg_RunApp("hwg_RunConsoleApp()")
   IF EMPTY(cCmd)
      RETURN NIL
   ENDIF

   rc := hwg_RunConsoleApp(cCmd,"output.txt")

   cgt := hwg_GUIType()

   DO CASE
   CASE cgt == "WinAPI"
      hwg_MsgInfo("Return Code: " + ALLTRIM(STR(rc)),"Result of hwg_RunConsoleApp()")
   CASE cgt == "GTK2"
      hwg_MsgInfo("Return Code: " + ALLTRIM(STR(rc)),"Result of hwg_RunConsoleApp()")
//  hwg_MsgInfo("Return Code: " + hb_ValToExp(),"Result of hwg_RunConsoleApp()")
   CASE cgt == "GTK3"
      hwg_MsgInfo("Return Code: " + ALLTRIM(STR(rc)),"Result of hwg_RunConsoleApp()")
//  hwg_MsgInfo("Return Code: " + hb_ValToExp(),"Result of hwg_RunConsoleApp()")
   ENDCASE

RETURN NIL


STATIC FUNCTION _hwg_RunApp(cpcmd)

   LOCAL _hwg_RunApp_test
   LOCAL oLabel1, oEditbox1, oButton1, oButton2
   LOCAL cCmd

* For header text: cpcmd (default is "hwg_RunApp()")
  IF cpcmd == NIL
    cpcmd := "hwg_RunApp()"
  ENDIF

  cCmd := SPACE(80)
  cCmd := hwg_GET_Helper(cCmd, 80)

  INIT DIALOG _hwg_RunApp_test ;
     TITLE cpcmd ;
     AT 315, 231 ;
     SIZE 940, 239 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 80,32 SAY oLabel1 ;
      CAPTION "Enter command line for run an external program"  ;
      SIZE 587, 22

   @ 80,71 GET oEditbox1 ;
      VAR cCmd  ;
      SIZE 772, 24 ;
      STYLE WS_BORDER

   @ 115,120 BUTTON oButton1 ;
      CAPTION "Run" ;
      SIZE 80, 32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || _hwg_RunApp_test:Close() }

   @ 809, 120 BUTTON oButton2 ;
      CAPTION "Cancel" SIZE 80, 32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || cCmd := "" , _hwg_RunApp_test:Close() }

   ACTIVATE DIALOG _hwg_RunApp_test CENTER
* RETURN _hwg_RunApp_test:lresult

RETURN cCmd

STATIC FUNCTION GetCValue(cPreset,cTitle,cQuery,nlaenge,lcaval)
* An universal function for getting a C value
*
* lcaval  : if set to .T., old value is returned
*           .F. : empty string returned
*           Default is .T.
* nlaenge : Max length of string to get.
*           Default value is LEN(cPreset)

   LOCAL _enterC, oLabel1, oEditbox1, oButton1 , oButton2 , cNewValue, lcancel

   IF cTitle == NIL
      cTitle := ""
   ENDIF

   IF cQuery == NIL
      cQuery := ""
   ENDIF

   IF cPreset == NIL
      cPreset := " "
   ENDIF

  IF lcaval == NIL
     lcaval := .T.
  ENDIF

  IF nlaenge == NIL
     nlaenge := LEN(cPreset)
  ELSE
     IF EMPTY(cpreset)
         cpreset := SPACE(nlaenge)
      ELSE
         cpreset := PADR(cpreset,nlaenge)
      ENDIF
   ENDIF

   lcancel := .T.

   cPreset := hwg_GET_Helper(cPreset, nlaenge )

   cNewValue := cPreset

   INIT DIALOG _enterC ;
      TITLE cTitle ;
      AT 315, 231 ;
      SIZE 940,239 ;
      STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE

   @ 80, 32 SAY oLabel1 ;
      CAPTION cQuery ;
      SIZE 587,22

   @ 80, 71 GET oEditbox1 ;
      VAR cNewValue  ;
      SIZE 772, 24 ;
      STYLE WS_BORDER

   @ 115, 120 BUTTON oButton1 ;
      CAPTION "OK" ;
      SIZE 80, 32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || lcancel := .F. , _enterC:Close() }

   @ 809,120 BUTTON oButton2 ;
      CAPTION "Cancel" ;
      SIZE 80, 32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK { || _enterC:Close() }

   ACTIVATE DIALOG _enterC CENTER

   IF lcancel
      IF lcaval
         cNewValue := cPreset
      ELSE
         cNewValue := ""
      ENDIF
   ENDIF

RETURN cNewValue

STATIC FUNCTION Test_hwg_HdSerial()

   LOCAL cDriveletter

   cDriveletter := GetCValue("C","hwg_HdSerial()", "Enter drive letter:",1,.F.)
   IF .NOT. EMPTY(cDriveletter)
      cDriveletter := cDriveletter + ":\"
   ENDIF

   IF .NOT. EMPTY(cDriveletter)
      hwg_MsgInfo("Serial number of drive " + cDriveletter + " is:" + CHR(10) + ;
      hwg_HdSerial(ALLTRIM(cDriveletter)))
   ENDIF

RETURN NIL

STATIC FUNCTION Test_hwg_HdGetSerial()

   LOCAL cDriveletter

   cDriveletter := GetCValue("C","hwg_HdGetSerial()", "Enter drive letter:",1,.F.)
   IF .NOT. EMPTY(cDriveletter)
      cDriveletter := cDriveletter + ":\"
   ENDIF

   IF .NOT. EMPTY(cDriveletter)
      hwg_MsgInfo("Serial number of drive " + cDriveletter + " is:" + CHR(10) + ;
         ALLTRIM(STR(hwg_HdGetSerial(ALLTRIM(cDriveletter)))))
   ENDIF

RETURN NIL

STATIC FUNCTION Test_hwg_ProcFileExt()

   LOCAL oDlg
   LOCAL oLabel1, oLabel2, oLabel3, oLabel4, oLabel5, oLabel6, oLabel7, oLabel8
   LOCAL oLabel9, oLabel10, oLabel11, oLabel12, oLabel13, oLabel14, oLabel15, oLabel16, oButton1
   LOCAL oLabel17, oLabel18, oLabel19, oLabel20, oLabel21, oLabel22 , oLabel23, oLabel24, oLabel25

  INIT DIALOG oDlg ;
     TITLE "hwg_ProcFileExt()" ;
     AT 488, 108 ;
     SIZE 528, 605 ;   && Previous: SIZE 528,465
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 130,13 SAY oLabel16 ;
      CAPTION "Set to file extension .prg"  ;
      SIZE 271, 22

   * After test case number in comment line: the expected result

   * 1 : test.prg
   @ 40,50 SAY oLabel1 ;
      CAPTION "test.txt"  ;
      SIZE 152,22

   @ 237,50 SAY oLabel2 ;
      CAPTION ">"  ;
      SIZE 29, 22

   @ 338,50 SAY oLabel3 ;
      CAPTION hwg_ProcFileExt("test.txt","prg")  ;
      SIZE 162, 22
   * 2 C:\temp.dir\test.prg

   @ 40,100 SAY oLabel4 ;
      CAPTION "C:\temp.dir\test.txt"  ;
      SIZE 135, 22

   @ 237,100 SAY oLabel5 ;
      CAPTION ">"  ;
      SIZE 29, 20

   @ 338,100 SAY oLabel6 ;
      CAPTION hwg_ProcFileExt("C:\temp.dir\test.txt","prg",,"\")  ;
      SIZE 155, 22

   * 3 C:\temp.\test.prg
   @ 40,150 SAY oLabel7 ;
      CAPTION "C:\temp.\test"  ;
      SIZE 97, 22

   @ 237,150 SAY oLabel8 ;
      CAPTION ">"  ;
      SIZE 29, 22

   @ 338,150 SAY oLabel9 ;
      CAPTION hwg_ProcFileExt("C:\temp.\test","prg",,"\")  ;
      SIZE 158, 22

   * 4 : /home/temp.dir/test.prg
   @ 40,200 SAY oLabel10 ;
      CAPTION "/home/temp.dir/test.txt"  ;
      SIZE 169, 22

   @ 237,200 SAY oLabel11 ;
      CAPTION ">"  ;
      SIZE 29, 22

   @ 338,200 SAY oLabel12 ;
      CAPTION hwg_ProcFileExt("/home/temp.dir/test.txt","prg",,"/")  ;
      SIZE 161, 22

   * 5 : /home/temp./test.prg
   @ 40,250 SAY oLabel13 ;
      CAPTION "/home/temp./test"  ;
      SIZE 133, 22

   @ 237,250 SAY oLabel14 ;
      CAPTION ">"  ;
      SIZE 29, 22

   @ 338,250 SAY oLabel15 ;
      CAPTION hwg_ProcFileExt("/home/temp./test","prg",,"/")  ;
      SIZE 157, 22

   * 6 : /home/temp./test
   * Remove a file extension
   @ 40, 300 SAY oLabel17 ;
      CAPTION "/home/temp./test.xyz"  ;
      SIZE 134, 22

   @ 237,300 SAY oLabel18 ;
      CAPTION ">"  ;
      SIZE 29, 22

   @ 338,300 SAY oLabel19 ;
      CAPTION hwg_ProcFileExt("/home/temp./test.xyz","",,"/")  ;
      SIZE 157, 22

   * 7 : /home/temp./test
   * There is no file extension to remove
   @ 40, 350 SAY oLabel20 ;
      CAPTION "/home/temp./test"  ;
      SIZE 134, 22

   @ 237,350 SAY oLabel21 ;
      CAPTION ">"  ;
      SIZE 29, 22

   @ 338,350 SAY oLabel22 ;
      CAPTION hwg_ProcFileExt("/home/temp./test",,,"/")  ;
      SIZE 157, 22

   * 8 : /home/temp/test
   * Same as 7, but no dot in directory name
   * There is no file extension to remove
   @ 40,400 SAY oLabel23 ;
      CAPTION "/home/temp/test"  ;
      SIZE 134, 22

   @ 237,400 SAY oLabel24 ;
      CAPTION ">"  ;
      SIZE 29, 22

   @ 338,400 SAY oLabel25 ;
      CAPTION hwg_ProcFileExt("/home/temp/test",,,"/")  ;
      SIZE 157, 22


   @ 205,508 BUTTON oButton1 CAPTION "OK"   ;
      SIZE 80, 32 ;
      STYLE WS_TABSTOP + BS_FLAT ;
      ON CLICK {|| oDlg:Close() }

   ACTIVATE DIALOG oDlg CENTER

RETURN NIL

STATIC FUNCTION Test_hb_os()
* On MacOS the value displayed is "Darwin"

   hwg_Msginfo("OS() = " + OS())

RETURN NIL

STATIC FUNCTION Test_BuildDatetime()

* Display build date by reading
* Harbour predefined macros
   hwg_MsgInfo("Build date = " + __DATE__ + CHR(10) + ;
      "Build time = " + __TIME__ , "Build"  )

RETURN NIL

STATIC FUNCTION Test_originpath(coriginp)

   hwg_MsgInfo("Origin path and name is :" + coriginp + CHR(10) + ;
     "Changed to directory at start : " + PWD() , "Test Originpath")

RETURN NIL

* ================================================================= *
STATIC FUNCTION PWD()
* Returns the curent directory with trailing \ or /
* so you can add a file name after the returned value:
* fullpath := PWD() + "FILE.EXT"
* ================================================================= *

   LOCAL oDir

#ifdef __PLATFORM__WINDOWS
  * Usage of hwg_CleanPathname() avoids C:\\
   oDir := hwg_CleanPathname(HB_curdrive() + ":\" + Curdir() + "\")
#else
   oDir := hwg_CleanPathname("/"+Curdir()+"/")
#endif

RETURN oDir

FUNCTION Test_hwg_EOLStyle()

   LOCAL ceolsty,cretuv

   ceolsty := hwg_EOLStyle()
   DO CASE
   CASE ceolsty == CHR(13) + CHR(10)
      cretuv := "EOLStyle = DOS/Windows 0D0A (CRLF)"
   CASE ceolsty == CHR(10)
      cretuv := "EOLStyle = LINUX/UNIX: 0A (LF)"
   CASE ceolsty == CHR(13)
      cretuv := "MacOS: 0D (CR)"
   OTHERWISE
      cretuv := "EOLStyle unknown"
   ENDCASE
   hwg_MsgInfo(cretuv,"hwg_EOLStyle()")

RETURN NIL

STATIC FUNCTION Test_hwg_GetEpoch()

   LOCAL nepoch

   nepoch := hwg_GetEpoch()
   Funkt( nepoch , "N" , "hwg_GetEpoch()")

RETURN NIL

STATIC FUNCTION ColPos()

   IF nColPos == -1
      nColPos := 20
      nRowPos := 80
   ELSE
      nColPos += 250
      IF nColPos > 600
         nRowPos += LINE_HEIGHT
         nColPos := 20
      ENDIF
   ENDIF

   RETURN nColPos

// at the end
#include "demo.ch"
* ============================== EOF of demofunc.prg ==============================
