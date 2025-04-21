*
* ChTooltip.prg
*
* Test program for Changeing tooltips for:
*
* - Buttons
* - Checkboxes
*
*
* Reference: Ticket #53
* HCustomWindow
*   ==> HStatus
*      ==> HControl
*
*   HButton
*      ==> HControl
*   HCheckButton
*      ==> HControl


#include "hwgui.ch"

FUNCTION Main()
LOCAL oWinMain

INIT WINDOW oWinMain MAIN  ;
     SYSCOLOR COLOR_3DLIGHT+1 ;
     TITLE "Test program change tooltips" AT 0, 0 SIZE 600,400;
     STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&Exit"
         MENUITEM "&Quit"    ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Test"
         MENUITEM "&Testen"  ACTION _Testen()
       ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN NIL

FUNCTION _Testen()
Local frm_ChTT

LOCAL oButton1, oButton2, oButton3, oButton4, oButton5, oButton6
LOCAL oCheck, bcheck

bcheck := .T.

  INIT DIALOG frm_ChTT TITLE "Change tooltips" ;
    AT 238,78 SIZE 516,415 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 30,25 BUTTON oButton1 CAPTION "TT to change"   SIZE 135,32 ;
        STYLE WS_TABSTOP+BS_FLAT   ;
         ON CLICK {|| hwg_MsgInfo("Button 1 pressed") } ;
        TOOLTIP "First tooltip"

   @ 260,25 BUTTON oButton2 CAPTION "<=== Change Tooltip"   SIZE 216,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| oButton1:SetTooltip("Second tooltip") }

   @ 260,67 BUTTON oButton4 CAPTION "<=== Remove Tooltip"   SIZE 216,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| oButton1:SetTooltip() }


   @ 30,125 GET CHECKBOX oCheck VAR bcheck CAPTION "Checkbox"  SIZE 180,22 ;
         TOOLTIP "First TT of checkbox" STYLE WS_BORDER


   @ 260,118 BUTTON oButton5 CAPTION "<=== Change Tooltip"   SIZE 216,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| oCheck:SetTooltip("Second TT of checkbox") }

   @ 260,160 BUTTON oButton6 CAPTION "<=== Remove Tooltip"   SIZE 216,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| oCheck:SetTooltip() }

   @ 205,300 BUTTON oButton3 CAPTION "OK"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| frm_ChTT:Close() }

   ACTIVATE DIALOG frm_ChTT

RETURN NIL

* ============================= EOF of ChTooltip.prg ======================
