/*
 * $Id$

 * HWGUI - Harbour Win32 GUI library source code:
 * HQhtm class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "hwgui.ch"
#include "hbclass.ch"
#include "hwg_qhtm.ch"

CLASS HQhtm INHERIT HControl

   DATA winclass   INIT "QHTM_Window_Class_001"
   DATA cText INIT ""
   DATA filename INIT ""
   DATA resname INIT ""
   DATA bLink, bSubmit

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption, ;
                  bInit,bSize,bLink,bSubmit,fname,resname )
   METHOD Activate()
   METHOD Redefine( oWndParent,nId,caption,bInit,bSize,bLink,bSubmit,fname,resname )
   METHOD Init()
   METHOD Notify( lParam )

ENDCLASS


METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,caption, ;
                  bInit,bSize,bLink,bSubmit,fname,resname ) CLASS HQhtm

   // ::classname:= "HQHTM"
   ::oParent := Iif( oWndParent==Nil, ::oDefaultParent, oWndParent )
   ::id      := Iif( nId==Nil,::NewId(), nId )
   ::style   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_CHILD+WS_VISIBLE )
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::bInit   := bInit
   ::bSize   := bSize
   ::bLink   := bLink
   ::bSubmit := bSubmit
   IF caption != Nil
      ::cText := caption
   ELSEIF fname != Nil
      ::filename := fname
   ELSEIF resname != Nil
      ::resname := resname
   ENDIF

   ::oParent:AddControl( Self )
   ::Activate()

Return Self

METHOD Activate() CLASS HQhtm
   IF ::oParent:handle != 0
      ::handle := CreateQHTM( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ELSE
      QHTM_INIT()
   ENDIF
Return Nil

METHOD Redefine( oWndParent,nId,caption,bInit,bSize,bLink,bSubmit,fname,resname ) CLASS HQhtm
   // ::classname:= "HQHTM"
   ::oParent := Iif( oWndParent==Nil, ::oDefaultParent, oWndParent )
   ::id      := nId
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::bInit   := bInit
   ::bSize   := bSize
   ::bLink   := bLink
   ::bSubmit := bSubmit
   IF caption != Nil
      ::cText := caption
   ELSEIF fname != Nil
      ::filename := fname
   ELSEIF resname != Nil
      ::resname := resname
   ENDIF

   ::oParent:AddControl( Self )
   QHTM_INIT()

Return Self

METHOD Init() CLASS HQhtm

   IF !::lInit
      ::Super:Init()
      IF !Empty( ::cText )
         hwg_Setwindowtext( ::handle,::cText )
      ELSEIF !Empty( ::filename )
         QHTM_LoadFile( ::handle,::filename )
      ELSEIF !Empty( ::resname )
         QHTM_LoadRes( ::handle,::resname )
      ENDIF
      QHTM_FormCallBack( ::handle )
   ENDIF

Return Nil

METHOD Notify( lParam ) CLASS HQhtm
Local cLink := QHTM_GetNotify( lParam )

   IF ::bLink == Nil .OR. !Eval( ::bLink,Self,cLink )
      IF "tp://" $ clink
         Return 0
      ELSE
         IF File( cLink )
            QHTM_LoadFile( ::handle,cLink )
         ELSE
            hwg_Msgstop( cLink,"File not found" )
         ENDIF
      ENDIF
   ENDIF
   QHTM_SetReturnValue( lParam,.F. )
Return 0

Function QhtmFormProc( hCtrl,cMethod,cAction,cName,aFields )
Local oCtrl := hwg_FindSelf( hCtrl )

   IF oCtrl != Nil
      IF oCtrl:bSubmit != Nil
         Eval( oCtrl:bSubmit,oCtrl,cMethod,cAction,cName,aFields )
      ENDIF
   ENDIF

Return 0

// CLASS hQHTMButton

CLASS HQhtmButton INHERIT HButton

   CLASS VAR winclass   INIT "BUTTON"
   DATA  cHtml
   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bClick,ctooltip )
   METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit,bSize,bClick,ctooltip )
   METHOD Init()

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bClick,ctooltip ) CLASS HQhtmButton

   HB_SYMBOL_UNUSED( oFont )

   ::cHtml := cCaption
   ::Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,"",, ;
                  bInit,bSize,,bClick,ctooltip )
   // ::classname:= "HQHTMBUTTON"

Return Self

METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit,bSize,bClick,ctooltip) CLASS HQhtmButton

   HB_SYMBOL_UNUSED( oFont )

   ::cHtml := cCaption
   ::Super:Redefine( oWndParent,nId,,bInit,bSize,,bClick,ctooltip )
   // ::classname:= "HQHTMBUTTON"

Return Self

METHOD Init() CLASS HQhtmButton

   ::Super:Init()
   IF ::oFont == Nil .AND. ::oParent:oFont == Nil
      hwg_Setctrlfont( ::oParent:handle, ::id, hwg_Getstockobject(SYSTEM_FONT) )
   ENDIF
   hwg_Setwindowtext( ::handle,::cHtml )
   QHTM_SetHtmlButton( ::handle )

Return Nil

EXIT PROCEDURE FreeQHTM
   QHTM_End()
Return