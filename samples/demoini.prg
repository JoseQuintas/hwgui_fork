/*
 *$Id: demoini.prg,v 1.1 2004/03/19 12:58:06 sandrorrfreire Exp $
 *
 * HwGUI Samples
 * demoini.prg - Test to use files ini
 *
 * The dafault path for Windows INI files is:
 * C:\Users\<userid>\AppData\Local\VirtualStore\Windows
 * (Windows 11)
 *
 * For multi platform usage see project CLLOG:
 * https://sourceforge.net/p/cllog/code/HEAD/tree/trunk/src/libini.prg
 * It is an extract of Harbour code with some modifications
 * and processes Windows like inifiles.
 */

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow
   LOCAL cIniFile:="HwGui.ini"

   //Create the inifile
   IF ! file( cIniFile )

      Hwg_WriteIni( 'Config', 'WallParer' , "No Paper", cIniFile )
      Hwg_WriteIni( 'Config', 'DirHwGUima', "C:\HwGUI" , cIniFile )
      Hwg_WriteIni( 'Print',  'Spoll'   ,   "Epson LX 80" , cIniFile )

    ENDIF

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "DEMOINI - Example" ;
      AT 200,0 ;
      SIZE 400,150

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Read Ini" ACTION ReadIni()
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

RETURN Nil

FUNCTION ReadIni()

   LOCAL cIniFile := "HwGui.ini"

   hwg_Msginfo( Hwg_GetIni( 'Config', 'WallParer' ,, cIniFile ) )
   hwg_Msginfo( Hwg_GetIni( 'Config', 'DirHwGUima',, cIniFile ) )
   hwg_Msginfo( Hwg_GetIni( 'Print',  'Spoll'     ,, cIniFile ) )

RETURN Nil
