/*
 * $Id$
 * GTHWGUI, Video subsystem, based on HwGUI
 *
 * Copyright 2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hwgui.ch"

#define MSG_USER_SIZE  0x502

#ifdef __GTK__
FUNCTION HB_GT_CGI
   RETURN Nil

FUNCTION HB_GT_CGI_DEFAULT
   RETURN Nil
#else
FUNCTION HB_GT_GUI
   RETURN Nil

FUNCTION HB_GT_GUI_DEFAULT
   RETURN Nil

FUNCTION HB_GT_WIN
   RETURN Nil

FUNCTION HB_GT_WIN_DEFAULT
   RETURN Nil
#endif

FUNCTION gthwg_CreateMainWindow( cTitle, oFont, oIcon )

   LOCAL oWnd, oPane := Nil
   LOCAL nStyle := Nil, x := 0, y := 0, width := 400, height := 200
   LOCAL bSize := Nil

   oWnd := HMainWindow():New( 1, oIcon,, nStyle, x, y, width, height, ;
      Iif( Empty(cTitle),"gt_HwGUI",cTitle ),,, oFont,, {||gthwg_CloseWindow()}, ;
      ,,,,,,,,,, WS_THICKFRAME )

   gthwg_SetWindow( oWnd:handle, Iif( Empty(oFont), Nil, oFont:handle ) )

   RETURN oWnd

FUNCTION gthwg_CreatePane( oWnd, nLeft, nTop, nWidth, nHeight, oFont, bSize )

   LOCAL oPane
   LOCAL bOther := {|o,msg,wp,lp|
      IF msg == MSG_USER_SIZE
         Eval( bSize, o, oPane, wp, lp )
      ENDIF
      RETURN -1
   }
   LOCAL bSizeDef := {|o,op,w,h|
      LOCAL nDelta
      nDelta := op:nWidth - ( w := hwg_PtrToUlong(w) )
      IF nDelta > 0
         op:Move( ,, w )
         o:Move( ,, o:nWidth-nDelta )
      ELSEIF nDelta < 0
         o:Move( ,, o:nWidth-nDelta )
         op:Move( ,, w )
      ENDIF
      nDelta := op:nHeight - ( h := hwg_PtrToUlong(h) )
      IF nDelta > 0
         op:Move( ,,, h )
         o:Move( ,,, o:nHeight-nDelta )
      ELSEIF nDelta < 0
         o:Move( ,,, o:nHeight-nDelta )
         op:Move( ,,, h )
      ENDIF
      hwg_writelog( ltrim(str(w)) + " " + ltrim(str(h)) + " / " + ;
         ltrim(str(op:nWidth)) + " " + ltrim(str(op:nHeight)) + " / " + ;
         ltrim(str(o:nWidth)) + " " + ltrim(str(o:nHeight)) )
      RETURN -1
   }

   @ nLeft,nTop BROWSE oPane ARRAY OF oWnd SIZE nWidth, nHeight NO VSCROLL

   gthwg_SetPanel( oPane:handle, oWnd:handle, Iif( Empty(oFont), Nil, oFont:handle ) )

   IF Empty( bSize )
      bSize := bSizeDef
   ENDIF
   oWnd:bOther := bOther

   RETURN oPane

FUNCTION gthwg_AddFont( cName, nHeight, nWidth, nWeight, nQuality, nCodepage )

   LOCAL oFont := HFont():Add( cName, nWidth, nHeight, nWeight, nCodePage ), oWnd

   HB_SYMBOL_UNUSED( nQuality )

   IF !Empty( oFont )
      IF !Empty( oWnd := HWindow():GetMain() )
         oWnd:oFont := oFont
      ENDIF
      //hwg_writelog( cName + " " + Str(nWidth) + " " + Str(oFont:width) + " / " + Str(nHeight) + " " + Str(oFont:height) )
      RETURN oFont:handle
   ENDIF

   RETURN Nil
