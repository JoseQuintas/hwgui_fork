/*
 * $Id$
 * 
 * Ticket:
 * #92 UpDown values
 * Copyright 2014-2025 Alain Aupeix <alain.aupeix@wanadoo.fr>
 * www - http://jujuland.pagesperso-orange.fr/
*/

/* 
 Comments by DF7BE:
 Hello Alain,
 this should work like
 desired:
 
 - IDOK and IDCANCEL are not working correct,
   so use ON CLICK ... 
 - instead UPDOWN use GET UPDOWN ... VAR nselection
   which is presetted with the init value 6.
   nselection contains the value set in updown window. 
 - Trick with lcanc
   If OK, set to .T.
   I use this in CLLOG, the advantage is,
   that the ESC key like "Cancel"
   
*/ 

#include "hwgui.ch"

REQUEST HB_CODEPAGE_UTF8
REQUEST HB_CODEPAGE_FR850

REQUEST ORDKEYNO
REQUEST ORDKEYCOUNT

// ============================================================================
function main()
// ============================================================================
local oMatchID, oFont := HFont():Add( "Serif",0,-13 )
local oUpdown, oResult, cResult:="5"
local cTitle  := "Test of UpDown"
local cTooltip:= "Choose a value between 1 and 10"

  
LOCAL nselection := 6, lcanc := .T. , noldsel


INIT DIALOG oMatchID CLIPPER NOEXIT TITLE cTitle AT 140,130 SIZE 610,245 FONT oFont

   * Remember old value:
     noldsel := nselection

   @  15, 33 SAY cTooltip SIZE 220,22 
   @ 250, 30 GET UPDOWN oUpDown VAR nselection RANGE 1, 10 SIZE 45, 22 COLOR hwg_ColorC2N("FF0000") TOOLTIP "Choose a value between 1 and 10"

    @ 105,205 BUTTON "ok"  SIZE 60, 32 COLOR hwg_ColorC2N("FF0000") ;
     ON CLICK {|| lcanc := .F. , oMatchID:Close() }  && OF oMatchID

   @ 405,205 BUTTON "Cancel"    ; && OF oMatchID  ID IDCANCEL
       SIZE 100, 32 ;
    ON CLICK {|| oMatchID:Close() }      

ACTIVATE DIALOG oMatchID

IF .NOT. lcanc
// if oMatchID:lresult
//   hwg_msginfo("oUpdown:value() = "+ltrim(str(oUpDown:value()))+chr(10)+"cResult = "+cResult+chr(10)+space(30),"Test of UpDown")
 hwg_msginfo("oUpdown:value() = "+ltrim(str(oUpDown:value()))+chr(10)+ " nselection = "+ ALLTRIM(STR(nselection)) +chr(10)+space(30),"Test of UpDown")
else
   * Cancelled: old value is recovered !
   nselection := noldsel
   hwg_msginfo("Cancelled : Old value= " + ltrim(str(nselection)) )
endif

return nil

function affiche(ctext)

hwg_msginfo("oUpdown:value() = "+ltrim(str(oUpDown:value()))+chr(10)+"cResult = "+cResult+chr(10)+space(30),"Test of UpDown")

return nil
// ============================================================================
// This is the end ...
// ============================================================================