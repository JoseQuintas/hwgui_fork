/*
 This sample is not running and fires a runtime error
 (seems to be outdated)

Error TOleAuto/-1  CO_E_CLASSSTRING: TOLEAUTO:NEW
Called from (b)HWG_ERRSYS(20)
Called from THROW(0)
Called from TOLEAUTO:NEW(0)
Called from MAIN(22)

HWGUI 2.23 dev Build 8
Date:10/13/24

(With MingW)

Harbour options
-n0
-w0
avoids build abort with
Warning W0001  Ambiguous reference

*/


#include "hwgui.ch"

#ifdef __XHARBOUR__
#xtranslate HB_AT(<x,...>) => AT(<x>)
#endif

FUNCTION Main()

   LOCAL oFont
   LOCAL oEdit
   PRIVATE oMainWindow, oChar, oBtnSpeak, oBtnPause, oUpDown, lPause := .F.
   PRIVATE oReq, cText, nPos, nPosOld
   PUBLIC oAgent, oTimer

   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT -17 CHARSET 204

   INIT WINDOW oMainWindow MAIN TITLE "Example"  ;
     SYSCOLOR COLOR_3DLIGHT+1                    ;
     AT 200,0 SIZE 600,380                       ;
     FONT oFont

   oAgent := TOleAuto():New("Agent.Control.2")
   IF Empty( oAgent ) .OR. Empty( oAgent:hObj )
      cText := "Ms Agent isn't installed !"
   ELSE
      oAgent:Connected := 1
      oAgent:Characters:Load("Default")
      oChar := oAgent:Characters("Default")
      IF Empty( oChar ) .OR. Empty( oChar:hObj )
         cText := "No default character !"
      ELSE
         @ 480,20 BUTTON oBtnSpeak CAPTION "Speak!" SIZE 100,32  ON CLICK {||SpeakIt(oEdit)}
         @ 480,60 BUTTON oBtnPause CAPTION "Pause"  SIZE 100,32 ;
               ON CLICK {||SetPause()}
         // @ 480,100 UPDOWN oUpDown INIT 10 RANGE 2,100 SIZE 100,30
      ENDIF
      @ 480,250 BUTTON "Set Default"  SIZE 100,32  ON CLICK {||oAgent:showDefaultCharacterProperties()}
   ENDIF

   @ 12,20 EDITBOX oEdit CAPTION hwg_Getclipboardtext() SIZE 460,310 ;
      STYLE ES_MULTILINE+ES_AUTOVSCROLL

   @ 480,300 BUTTON "Close"  SIZE 100,32  ON CLICK {||hwg_EndWindow()}

   SET TIMER oTimer OF oMainWindow VALUE 200 ACTION {||TimerFunc()}

   ACTIVATE WINDOW oMainWindow

RETURN Nil

STATIC FUNCTION SpeakIt( oEdit )

   // Local aTop := hwg_Clienttoscreen( oMainWindow:handle,0,0 )

   oBtnSpeak:Disable()
   cText := hwg_Getedittext( oEdit:oParent:handle, oEdit:id )
   nPosOld := 1

   oChar:Show(1)
   // oChar:Moveto( aTop[1]+20, aTop[2]+70 )
   oChar:Balloon:Style := 0
   oChar:LanguageID := Iif( Asc(cText)>122,"&H0419","&H0409" )

   IF SpeakLine()
      oReq := Nil
      oChar:Hide( 1 )
   ENDIF

RETURN Nil

STATIC FUNCTION SpeakLine()

   LOCAL cLine, lEnd := .F., cUpd := "10"

   IF ( nPos := hb_At( ".", cText, nPosOld ) ) == 0
      cLine := Substr( cText, nPosOld )
      lEnd := .T.
   ELSE
      cLine := Substr( cText, nPosOld, nPos-nPosOld+1 )
      nPosOld := nPos + 1
   ENDIF
   IF !Empty( cLine )
      // cUpd := Alltrim( hwg_Getedittext( oUpDown:oParent:handle, oUpDown:id ) )
      oReq := oChar:Speak( "\Spd="+cUpd+"\"+cLine )
      // hwg_writelog( "\Spd="+cUpd+"\"+cLine )
   ENDIF
   IF lEnd
      oBtnSpeak:Enable()
   ENDIF

RETURN lEnd

STATIC FUNCTION SetPause()

   IF lPause
      oBtnPause:SetText( "Pause" )
   ELSE
      oBtnPause:SetText( "Play" )
   ENDIF
   lPause := !lPause

RETURN Nil

STATIC FUNCTION TimerFunc()

   LOCAL nReq

   IF !lPause .AND. !Empty( oReq ) .AND. ( nReq := oReq:Status() ) != 2 .AND. nReq != 4
      oReq := Nil
      IF SpeakLine()
         oChar:Hide( 1 )
      ENDIF
   ENDIF

RETURN Nil

EXIT PROCEDURE EXI

   IF !Empty( oAgent ) .AND. !Empty( oAgent:hObj )
      oAgent:Characters:UnLoad("Default")
      oAgent:End()
   ENDIF
   oTimer:End()

RETURN

* ======================== EOF of hole.prg ==============================
