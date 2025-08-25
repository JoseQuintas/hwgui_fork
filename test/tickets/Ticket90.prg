*
* Ticket90.prg
*
* $Id$

#include "hwgui.ch"

* hwg_WChoice( arr, cTitle, nLeft, nTop, oFont, clrT, clrB, clrTSel, clrBSel, cOk, cCancel )
* Creates a dialog box to select from a list.
*
* -  arr - an array, one-dimensional or multidimensional, which represents the list;
* -  cTitle - a header of a dialog box;
* -  nLeft, nTop - dialog box left upper corner coordinates;
* -  oFont - a font for a dialog, an object of HFont class;
* -  clrT, clrB - colors ( text and background ) of a browse;
* -  clrTSel, clrBSel - colors ( text and background ) of a selected row of a browse;
* -  cOk - a caption of a button to confirm selecting.
*    If this parameter is omitted, the button will not present;
* -  cCancel - a caption of a button to cancel selecting.
*    If this parameter is omitted, the button will not present;
* -   Return value - the number of selected row, 0 - if nothing is selected.
*

* The symptom:
* I have, here, 3 strings in the array, and only 2 appeared,
* the third appears empty, and just appears if I scroll.
* It I change manually the size of the dialog, It's ok.
* Is there a way to have directly a correct display ?

* The bug is not present on WinAPI.
* The code for GTK is found in source/gtk/gtkmain.prg, line 49
* WinAPI: source\winapi\guimain.prg, line 101

* Translation:
* Ouvrir  = Open
* Annuler = Cancel

* The default font is: "Times", 0, 14
* screenh=1080


* Before starting the dialog, the size parameters are:
* width=220
* height=75

* The height is calculated by:
*  aMetr := hwg_Gettextmetric( hDC )
*  height := ( aMetr[1] + 5 ) * aLen + 4 + addY
*  Returns 75

* aMetr[1]=0
* aArea[2]=1080  ==> screenh
* aRect[2]=0
* ntop default is 10

* (0 + 5) * 3 + 4 + 56 = 75

*   width := Max( minWidth, aMetr[2] * 2 * nLen + addX )
*                   0      ,   0     * 2 * 0    +   0   ==> 20

* For
* nwline

Procedure Main

LOCAL oMainWindow ,  oButton , datum , aMenu ,  rg

SET DATE GERMAN
SET CENTURY ON

datum := DTOC(DATE()) 

// aMenu := {"One"}
// aMenu := {"One","Two","Three"}

* Array with 3 lines of french text

aMenu := {"Soupe froide de courgettes au tableaux" , ;
"Samousas" , ;
"Flan légumes d'été" }

* and a big array

/*
aMenu := {"One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten", ;
 "Eleven","Twelve","Thirteen","Fourteen","Fivteen","Sixteen","Seventeen","Eighteen"," Nineteen", "Twenty", ;
 "Twentyone","Twentytwo","Twentythree","Twentyfour","Twentyfive","Twentysix","Twentyseven", "Twentyeight","Twentynine","Thirty", ;
 "Thirtyone","Thirtytwo","Thirtythree","Thirtyfour","Thirtyfive","Thirtysix","Thirtyseven","Thirtyeight","Thirtynine","Forty"}
*/ 


INIT DIALOG oMainWindow  TITLE "Ticket 90" AT 0,0 size 800,400 && STYLE DS_CENTER 


 * Need button for exit

  @ 100,100 BUTTON oButton CAPTION "Exit"   SIZE 80,32 ;
        STYLE WS_TABSTOP + BS_FLAT ;
        ON CLICK { | | oMainWindow:Close() } 

* Attention: Set this function call before activate main window !! 
rg := hwg_WChoice( aMenu, "Menu du " + datum, oMainWindow:nLeft+120,oMainWindow:nTop+140,,,,,, ;
  "Ouvrir", "Annuler" )


oMainWindow:Activate()

* Display result
hwg_MsgInfo("Result=" + ALLTRIM(STR(rg)) )

RETURN
