/*
 *$Id: iesample.prg,v 1.2 2006/10/05 11:02:42 alkresin Exp $
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 * iesample.prg - sample of ActiveX container for the IE browser object
 *
 * Copyright 2006 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 */

* Windows only:
* Needed to link with HWGUI contrib library libhbactivex.a
* Needed external prerequisites: Development environment for ActiveX.
*
* Attention !
* Sample program needs ActiveX and contrib library "libhbactivex.a".
* Support for ActiveX ended, substituted by HTML5 and Java.
* !!!!!!  Sample is outdated.  !!!!!!
*
* Original file from:
* iesample.prg,v 1.2 2006/10/05 11:02:42 alkresin Exp
*
* Warning fixed:
* iesample.prg(43) Warning W0005  RETURN statement with no return value in function
* iesample.prg(54) Warning W0005  RETURN statement with no return value in function
*
* If error appeared:
* ../../../../contrib/activex/htmlcore.h:17:119: fatal error: mshtmhst.h: No such file or directory
* check the development environment for ActiveX
*

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWnd, oPanelTool, oPanelIE, oFont
   LOCAL oEdit, cUrl, oIE

   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT -15
   INIT WINDOW oMainWnd TITLE "Example" AT 200,0 SIZE 500,400 FONT oFont

   MENU OF oMainWnd
      MENU TITLE "File"
         MENUITEM "&Open file" ACTION OpenFile(oIE,oEdit)
         MENUITEM "&Save" ACTION hwg_writelog( oIE:getBody() )
         SEPARATOR
         MENUITEM "E&xit" ACTION oMainWnd:Close()
      ENDMENU
   ENDMENU

    @ 0,0 PANEL oPanelTool SIZE 500,32

    @ 5,4 EDITBOX oEdit CAPTION "http://kresin.belgorod.su" OF oPanelTool SIZE 400,24
    @ 405,4 BUTTON "Go!" OF oPanelTool SIZE 30,24 ;
        ON CLICK {||Iif(!Empty(cUrl:=hwg_Getedittext(oEdit:oParent:handle,oEdit:id)),oIE:DisplayPage(cUrl),.T.)}
    @ 435,4 BUTTON "Search" OF oPanelTool SIZE 55,24 ;
        ON CLICK {||Iif(!Empty(cUrl:=hwg_Getedittext(oEdit:oParent:handle,oEdit:id)),FindInGoogle(cUrl,oIE,oEdit),.T.)}

    @ 0,34 PANEL oPanelIE SIZE 500,366 ON SIZE {|o,x,y|o:Move(,,x,y-34)}

    oIE := HHtml():New( oPanelIE )

    ACTIVATE WINDOW oMainWnd

RETURN Nil

STATIC FUNCTION OpenFile( oIE,oEdit )

   LOCAL mypath := "\" + Curdir() + Iif( Empty( Curdir() ), "", "\" )
   LOCAL fname := hwg_Selectfile( "HTML files", "*.htm;*.html", mypath )

   IF !Empty( fname )
      oEdit:SetText( fname )
      oIE:DisplayPage( fname )
   ENDIF

RETURN Nil

STATIC FUNCTION FindInGoogle( cQuery,oIE,oEdit )

   LOCAL cUrl := "http://www.google.com/search?q=", cItem

   IF !Empty( cItem := NextItem( cQuery,.T.,' ' ) )
      cUrl += cItem
      DO WHILE !Empty( cItem := NextItem( cQuery,,' ' ) )
         cUrl += '+' + cItem
      ENDDO
      oEdit:SetText( cUrl )
      oIE:DisplayPage( cUrl )
   ENDIF

RETURN Nil

* =============== EOF of iesample.prg =========================
