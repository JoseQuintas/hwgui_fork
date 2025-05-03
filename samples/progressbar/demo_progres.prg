*
* demo_progres.prg
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

#ifndef __PLATFORM__WINDOWS
memvar lprogress
#endif

* On Windows, the time to sleep must decreased
#define SLEEP_LINUX    3000
#define SLEEP_WINDOWS  500

memvar otest
// ============================================================================
function main()
// ============================================================================
local oFont

#ifndef __PLATFORM__WINDOWS
public lprogress:=.f.
#endif

PUBLIC otest

* Better dsign for all platforms
#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -12
#else
   oFont:= HFont():Add( "Serif",0,-13)
#endif

INIT DIALOG otest CLIPPER NOEXIT TITLE "Progress test" FONT oFont ;
             AT 200,200 SIZE 200,200 STYLE WS_POPUP

     MENU OF otest
       MENU TITLE "Run"
          MENUITEM "Run the demo" ACTION RunDemo()
       ENDMENU
       MENU TITLE "Quit"
          MENUITEM "Quit the test" ACTION hwg_EndDialog()
       ENDMENU
       MENU TITLE "Help"
          MENUITEM "About progress" ACTION aide()
       ENDMENU
     ENDMENU

     ACTIVATE DIALOG otest CENTER

return NIL

// ============================================================================
function RunDemo()
// ============================================================================
local tabfiles:={ "1003236_10151902282894923.jpg",;
                  "20140921_ 00.jpg",;
                  "20140921_1865.jpeg",;
                  "20140921_191722.jpg",;
                  "20140921_1.jpg",;
                  "20140921_3.jpg",;
                  "20140921_5634.jpeg",;
                  "20140921_5.jpg",;
                  "20140921_841.jpeg",;
                  "20140921_9639.jpeg",;
                  "406.jpeg",;
                  "bebe1 shandra.jpg",;
                  "bebe shandra 2.jpg",;
                  "bebe shandra3.jpg",;
                  "bebe shandra4.jpg",;
                  "bebe shandra 5.jpg",;
                  "dominique shandra.jpg";
                }
local rg

#ifdef __PLATFORM__WINDOWS
local oBar
* On Windows, the progbar is supported by the WinAPI

* Create progbar object

// NewBox( cTitle, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bExit,  Percent )
// Default values:
//                 ^ 0    ^ 0   ^220-40 ^55      ^ 20    ^ 100   ^ none  ^none

  oBar := HProgressBar():NewBox( "Treating image file  ..." ,,,350,,    LEN(tabfiles) , 100  )

  * By this, make experiments:
  * ::nLimit   := iif( nRange != Nil, Int( ::nRange / ::maxPos ), 1 )
  * By setting 100/100, the prog bars starts with 1% step, stopping at 17
  * (=LEN(tabfiles) )
  * By setting LEN(tabfiles)/100
  * The progbar steps with 5% and stop also at 17.

  * So need to step for this case 100/17 = 5,888
  * Be careful with bExit, may crash !

// This is not running !
//  @ 0,0 PROGRESSBAR oBar SIZE 350, 55 BARWIDTH 300 QUANTITY len(tabfiles)

* On WinAPI, the only way to display the treated file by add them
* into the title headline of StepBar()

for rg=1 to len(tabfiles)
//       "Treating image file "+ltrim(str(rg))+" / "+ltrim(str(len(tabfiles)))+"#!"+space(30-len(tabfiles[rg]))+tabfiles[rg]+chr(10)+"Treating files")
    StepBar(oBar,"Treating image file "+ltrim(str(rg))+" / "+ltrim(str(len(tabfiles))) ;
     + " : " + ALLTRIM(tabfiles[rg]) )
    hwg_sleep(SLEEP_WINDOWS)

    * Debug:
//    hwg_Writelog("Treating image file "+ltrim(str(rg))+" / "+ltrim(str(len(tabfiles))) ;
//     + " : " + ALLTRIM(tabfiles[rg]) )
next

* Close progress bar

CloseBar(oBar)

#else
* LINUX/MacOS calling external tool "wmctrl"
// local cStdOut:=""
// local cmd

for rg=1 to len(tabfiles)
    if !lprogress
       lprogress=.t.
       run("./progress "+ltrim(str(otest:nLeft+100))+" "+ltrim(str(otest:nTop+100))+" 30 &")
    endif
    hb_memowrit("/tmp/what","       Treating image file "+ltrim(str(rg))+" / "+ltrim(str(len(tabfiles)))+"#!"+space(30-len(tabfiles[rg]))+tabfiles[rg]+chr(10)+"Treating files")
    hwg_sleep(SLEEP_LINUX)
next

// cmd="ps -ef|grep progress|grep -v grep"
// hb_processrun("sh -c '"+cmd+"'",,@cStdOut)
// qout(cStdOut)

// kill -9 `ps aux | grep progress | awk '{print $2}'`
// hb_run("kill -9 "+cStdOut)

  hb_run( "kill -9 `ps -ef | grep progress | grep -v grep | grep -v demo | awk '{print $2}'`" )

lprogress=.f.
hb_run("rm /tmp/what")
#endif


hwg_MsgInfo("All the files have been treated","Progress Demo")

return NIL

// ============================================================================
function Aide()
// ============================================================================
* About dialog

 hwg_MsgInfo( ;
  "Progress v1.01 for Linux" + CHR(10) + ;
  "2023-2025 (c) Alain Aupeix" + CHR(10) + ;
  "alain.aupeix@wanadoo.fr","About progress"  )

return NIL


#ifdef __PLATFORM__WINDOWS

FUNCTION StepBar(oBar,cTitle)
Iif(oBar == Nil, hwg_Msgstop( "oBar is NIL" ), oBar:Step(cTitle) )
RETURN oBar

FUNCTION CloseBar(oBar)
Iif( oBar == Nil, hwg_Msgstop( "oBar is NIL" ), ( oBar:Close(), oBar := Nil ) )
RETURN oBar


FUNCTION ResetBar(oBar,cTitle)
Iif( oBar == Nil, hwg_Msgstop( "oBar is NIL" ), oBar:RESET( cTitle ) )
RETURN oBar

#endif

* ========================= EOF of demo_progres.prg ==============================================
