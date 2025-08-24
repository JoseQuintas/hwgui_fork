*
* Ticket207.prg
*
* $Id$
*
* #207 Bus with printing using a printer script.

* The syptom:
* I create a printer script to print in landscape mode (setmode(2,2)

* If I print directly on the printer, or in a pdf file, it's ok.
* When I try to ptint using the script file,
* the first page is in portrait mode, and obviously is not ok.
* The other pages are ok.
* First check on Windows, but with Microsoft's Print2Pdf no
* PDF file is created.
 


* Crashes with:
* Error BASE/1066  Argument error: conditional
* Called from (b)HWG_ERRSYS(20)
* Called from HPRINTER:ENDDOC(529)
* Called from TESTIT(46)
* Called from (b)MAIN(29)
* Called from ONCLICK(586)
* Called from (b)HBUTTON_NEW(416)
* Called from HWG_DLGCOMMAND(407)
* Called from (b)(_INITSTATICS00003)(0)
* Called from HDIALOG:ONEVENT(231)
* Called from HWG_DLGBOXINDIRECT(0)
* Called from HDIALOG:ACTIVATE(176)
* Called from MAIN(35)
* (1) = Type: U

* ==> add line:
*      oPrinter:lpreview := .T.


* The first line of alpha.out was modified:
* Original:
* job,589,836,2.8317,2.8339,utf8
* After program run:
* job,4961,7016,23.6238,23.6229,EN

* Continued on LINUX. 

#include "hwgui.ch"


Procedure Main

LOCAL oMainWindow ,  oButton1, oButton2


INIT DIALOG oMainWindow  TITLE "Ticket 207" AT 0,0 size 800,400


  @ 100,100 BUTTON oButton1 CAPTION "Test"   SIZE 80,32 ;
        STYLE WS_TABSTOP + BS_FLAT ;
        ON CLICK { | | TestIt() } 

  @ 200,100 BUTTON oButton2 CAPTION "Exit"   SIZE 80,32 ;
        STYLE WS_TABSTOP + BS_FLAT ;
        ON CLICK { | | oMainWindow:Close() } 

oMainWindow:Activate()


RETURN
 
FUNCTION TestIt()
LOCAL cScript := "alpha" 
LOCAL oPrinter

IF .NOT. FILE(cScript+".out")
 hwg_MsgStop("File does not exist: "+ cScript+".out")
 RETURN NIL
ENDIF 

//      oPrinter := HPrinter():New()

#ifndef __PLATFORM__WINDOWS
      oPrinter := HPrinter():New()
#else
      oPrinter := HPrinter():New()
#endif
//      oPrinter:StartDoc( .T. ,"temp_a2.ps", .T.) &&  lpreview = .T. lprbutton := .T.
//      oPrinter:lpreview := .T.
      oPrinter:LoadScript(cScript+".out")
      oPrinter:EndDoc(cScript+".out")
      oPrinter:End()
  
RETURN NIL

* ==================== EOF of Ticket207.prg ==================
