*
* euro.prg
*
* Test program for display Euro currency sign, locale and fonts.
*
*
* Function hb_cdpSelect() returns "EN" as default

#include "hwgui.ch"

FUNCTION Main()
LOCAL oWinMain

INIT WINDOW oWinMain MAIN  ;
     SYSCOLOR COLOR_3DLIGHT+1 ;
     TITLE "Test program Coloured GET" AT 0, 0 SIZE 600,400;
     STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&Exit"
         MENUITEM "&Quit"    ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Test"
         MENUITEM "&Show Euro Currency sign"  ACTION _Testen()
         MENUITEM "Get &Font List"  ACTION {|| hwg_MsgInfo(hwg_GetFontsList() , "Font list" ) }
         MENUITEM "Get Locale Info" ACTION {|| hwg_MsgInfo(hwg_GetLocaleInfo() , "Locale Info" ) }
         MENUITEM "Some more &Information" ACTION _MoreInfo()
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN NIL

FUNCTION _Testen()
LOCAL cEuro

#ifdef __PLATFORM__WINDOWS
  cEuro := CHR(128)
#else
  cEuro := hwg_EuroUTF8()
#endif

hwg_MsgInfo(cEuro,"Euro Currency Sign")

RETURN NIL

FUNCTION _MoreInfo()
hwg_MsgInfo( ;
 "Unicode support: " + Local2str(hwg__isUnicode() ) + CHR(10) + ;
 "Win Euro support: " + Local2str(hwg_Has_Win_Euro_Support() ) + CHR(10) + ;
 "Codepage: " + hb_cdpSelect() ;
 , ;
 "More Information" )

RETURN NIL

FUNCTION Local2str(clo)
IF clo
  RETURN "True"
ENDIF
RETURN "False"
* ======================== EOF of euro.prg ====================
