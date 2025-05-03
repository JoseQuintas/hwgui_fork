*
* progress.prg
*
* $Id$
*
* HWGUI Progress bar sample for WinAPI, MacOS and GTK/LINUX
*
* For Details and usage instructions see Readme.txt file
*
* 2023-2025 (c) Alain Aupeix
* alain.aupeix@wanadoo.fr
*
* License:
* GNU General Public License
* with special exceptions of HWGUI.
* See file "license.txt" for details.



#include "hwgui.ch"

REQUEST HB_CODEPAGE_UTF8

memvar oFont, oForm, oBar, isTimer, n, oMessage, cTitle, nLarge, nHigh
// ======================
#include "./memvar.prg"
// ======================

// ============================================================================
function main(cLeft,cTop,more)
// ============================================================================
local oTimer, oFont

* Better dsign for all platforms
#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -1
#else
   oFont:= HFont():Add( "Serif",0,-13)
#endif

public n :=0, oMessage, oForm, cTitle, nLarge, nHigh
public cHex_icon, cVal_icon, oObj_icon

if cleft == NIL .or. cTop == NIL
   hwg_MsgInfo("Syntax : progress <left> <top> [large+high]"+chr(10)+;
               "where :"+chr(10)+;
               "    - left and top are necessary"+chr(10)+;
               "    - large+high allows you to enlarge the dialog"+chr(10)+;
               "                           and can be omitted"+chr(10)+chr(10)+;
               "Examples : progress 200 300 "+chr(10)+;
               "                     progress 100 200 0+30"+chr(10)+;
               "                     progress 200, 150 30+50",;
               "progress v1.01 (2025-03-07)")
   quit
endif
if more == NIL
   nLarge=0
   nHigh=0
else
   if at("+",more) > 0
      nLarge=val(left(more,at("+",more)-1))
      nHigh=val(substr(more,at("+",more)+1))
   else
      nLarge=val(more)
      nHigh= 0
   endif
endif
oMessage=" "
cTitle=" "

init_Hexvars()

// ======================
#include "./loadhex.prg"
// ======================

// ======================
#include "./objects.prg"
// ======================

INIT DIALOG oForm CLIPPER NOEXIT TITLE cTitle FONT oFont ;
             AT val(cLeft), val(cTop) SIZE 260+nLarge, 80+nHigh ;
             ICON oObj_icon ;
             STYLE WS_POPUP ON EXIT {||oTimer:end(),oBar:Close()}

     @ 60,10 say oMessage SIZE 160+nLarge,32
     @ 30,45 PROGRESSBAR oBar SIZE 200+nLarge, 20 BARWIDTH 10 QUANTITY 100
     SetTimer(oForm,@oTimer)

     ACTIVATE DIALOG oForm CENTER

oTimer:End()

return Nil

// ============================================================================
function res_progbar(opbar)
// ============================================================================

 n := 0
 opBar:Reset()
 * opBar:Set(,0 )

hb_run("wmctrl -a '"+cTitle+"'")

return .F.

// ============================================================================
Static Function SetTimer( oDlg,oTimer )
// ============================================================================

SET TIMER oTimer OF oDlg VALUE 1000 ACTION {||TimerFunc()}

return Nil

// ============================================================================
Static function TimerFunc()
// ============================================================================
local cStdOut:="", cLanguage

n+=400
oBar:Set(,n/100)
hb_processrun("sh -c 'cat /tmp/what 2>/dev/null'",,@cStdOut)
oMessage=left(cStdOut,at(chr(10),cStdOut)-1)
if at("#!",oMessage) > 0
   oMessage=strtran(oMessage,"#!",chr(10))
endif
if cTitle== " " .and. at(chr(10),cStdOut) > 0
   cTitle=substr(cStdOut,at(chr(10),cStdOut)+1)
else
   if trim(cTitle) == ""
      cLanguage=getenv("LANGUAGE")
      do case
         case clanguage == "fr_FR"
              cTitle="Merci de patienter ..."
         case clanguage == "es_ES"
              ctitle="Espere por favor ..."
         case clanguage == "de_DE"
              ctitle="Bitte warten ..."
         otherwise
              ctitle="Please, wait ..."
      endcase
   endif
endif
if oForm:title == " "
   oForm:SetTitle(cTitle)
   oForm:refresh()
endif

@ 20,10 say oMessage SIZE 220+nLarge,32+nHigh
hb_run("wmctrl -a '"+cTitle+"'")
if n/100 == 100
   RES_PROGBAR ( obar )
endif

return Nil

// ======================
#include "./inithex.prg"
// ======================

// ====================== EOF of progress.prg ========================
