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

FUNCTION DemoIni( lWithDialog, oDlg, aExitList )

   LOCAL oGet, cIniFile

   hb_Default( @lWithDialog, .T. )
   hb_Default( @aExitList, {} )

   cIniFile := hb_cwd() + "tmpini.ini"

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demoini.prg - read/write ini file" ;
         AT 0,0 ;
         SIZE 800, 600
   ENDIF

   ButtonForSample( "demoini.prg" )

   @ 10, 100 EDITBOX oGet ;
      CAPTION "" ;
      SIZE 400, 300 ;
      COLOR hwg_ColorC2N( "FF0000" ) ;
      STYLE   ES_MULTILINE + ES_AUTOVSCROLL + WS_VSCROLL + WS_HSCROLL

   @ 450, 100 BUTTON "Read Ini to Text" ;
      SIZE 150, 24 ;
      ON CLICK { || ReadIni( cIniFile, oGet ) }

   @ 450, 150 BUTTON "Write Text To Ini" ;
      SIZE 150, 24 ;
      ON CLICK { || WriteIni( cIniFile, oGet ) }

   @ 450, 200 BUTTON "Show Values" ;
      SIZE 150, 24 ;
      ON CLICK { || ShowValues( cIniFile ) }

   @ 450, 250 BUTTON "Write Default" ;
      SIZE 150, 24 ;
      ON CLICK { || ResetIni( cIniFile, oGet ) }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      fErase( cIniFile )
   ELSE
      Aadd( aExitList, { || fErase( cIniFile ) } )
   ENDIF

RETURN Nil

STATIC FUNCTION ShowValues( cIniFile )

   hwg_Msginfo( ;
      "Config/Paper:" + hb_ValToExp( Hwg_GetIni( 'Config', 'Paper',, cIniFile ) ) + hb_Eol() + ;
      "Config/Path:" + hb_ValToExp( Hwg_GetIni( 'Config', 'Path',,  cIniFile ) ) + hb_Eol() + ;
      "Print/Spool:"+ hb_ValToExp( Hwg_GetIni( 'Print',  'Spool',, cIniFile ) ) )

RETURN Nil

STATIC FUNCTION ReadIni( cIniFile, oGet )

   IF ! File( cIniFile )
      hwg_MsgInfo( cIniFile + " not found" )
      RETURN Nil
   ENDIF
   oGet:Value := MemoRead( cIniFile )

   RETURN Nil

STATIC FUNCTION WriteIni( cIniFile, oGet )

   hb_MemoWrit( cIniFile, oGet:Value )

   RETURN Nil

STATIC FUNCTION ResetIni( cIniFile, oGet )

   hb_MemoWrit( cIniFile, "" )
   Hwg_WriteIni( 'Config', 'Paper', "No Paper",    cIniFile )
   Hwg_WriteIni( 'Config', 'Path',  "C:\HwGUI" ,   cIniFile )
   Hwg_WriteIni( 'Print',  'Spool', "Epson LX 80", cIniFile )
   ReadIni( cIniFile, oGet )

   RETURN Nil

#include "demo.ch"
