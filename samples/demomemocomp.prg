/*
 *
 * demomemocomp.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Sample for Edit and Compare memo and get length of a memo
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2024 Wilfried Brunken, DF7BE
*/

/*
 Some instructions:
 - SET EXACT ON
   before comparing memos with " == "
 - If one memo or both memo's are NIL,
   it is no problem to compare it with " == "
 - The only trouble is to use LEN() to get
   the size of a memo, LEN() crashes, if memo is NIL
   (in this case the return value must be 0)
   so use the FUNCTION nMemolen(cMemo)
   above to get the size of a memo !

 Reference:
 Commit  [r3463] by josequintas 2024-07-17
 Browse code at this revision
 Parent: [r3462]
 Child: [r3464]
 title:
 removed hwg_memocmp() and hwg_lenmem()

*/


   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes
    *  GTK/MacOS:  Yes

#include "hwgui.ch"
#include "common.ch"
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

FUNCTION DemoMemoComp( lWithDialog, oDlg )

   LOCAL oSay1, oSay2
   LOCAL cMemo1 := "", cMemo2 := ""

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demomemocomp.prg - Sample program Memo edit and compare" ;
         AT 0, 0 ;
         SIZE 800, 600;
         //STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER
   ENDIF

   ButtonForSample( "demomemocmp.prg", oDlg )

   @ 20, 100 SAY oSay1 ;
      CAPTION cMemo1 ;
      SIZE 290, 290 ;
      BACKCOLOR 255+255*256+255*256*256

   @ 320, 100 SAY oSay2 ;
      CAPTION cMemo2 ;
      SIZE 290, 290 ;
      BACKCOLOR 255+255*256+255*256*256

   @ 20, 400 BUTTON "Edit Memo1" ;
      SIZE 100, 24 ;
      ON CLICK { || cMemo1 := hwg_MemoEdit( cMemo1, "Edit memo1" ), oSay1:SetText( cMemo1 ) }

   @ 320, 400 BUTTON "Edit Memo2" ;
      SIZE 100, 24 ;
      ON CLICK { || cMemo2 := hwg_MemoEdit( cMemo2, "Edit memo2" ), oSay2:SetText( cMemo2 ) }

   @ 20, 430 BUTTON "Memo1:=Nil" ;
      SIZE 100,24 ;
      ON CLICK { || cMemo1 := Nil }

   @ 320, 430 BUTTON "Memo2:=Nil" ;
      SIZE 100,24 ;
      ON CLICK { || cMemo2 := Nil }

   @ 10, 460 BUTTON "Compare method a" ;
      SIZE 200,24 ;
      ON CLICK { || Compare1(cMemo1,cMemo2) }

   @ 320, 460 BUTTON "Compare method b" ;
      SIZE 200,24 ;
      ON CLICK { || Compare2(cMemo1,cMemo2) }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil

FUNCTION Compare1( cMemo1, cMemo2 )

   LOCAL nLines1 := 0, nLines2 := 0, nLen1 := 0, nLen2 := 0, cText := ""

   IF cMemo1 == NIL
      cText += "Memo1 is NIL" + hb_Eol()
   ELSE
      nLines1 := MLCount( cMemo1, 254 )
      nLen1   := Len( cMemo1 )
   ENDIF

   IF cMemo2 == NIL
      cText += "Memo2 is NIL" + hb_Eol()
   ELSE
      nLines2 := MLCount( cMemo2, 254 )
      nLen2   := Len( cMemo2 )
   ENDIF

   cText += "Memo1 have " + Ltrim( Str( nLines1 ) ) + " line(s) and " + ;
      Ltrim( Str( nLen1 ) ) + " chars" + hb_Eol()
   cText += "Memo2 have " + Ltrim( Str( nLines2 ) ) + " line(s) and " + ;
      Ltrim( Str( nLen2 ) ) + " chars" + hb_Eol()

   IF cMemo1 == cMemo2
      cText += "Memos are equal"
   ELSE
      cText += "Memos are not equal"
   ENDIF
   hwg_MsgInfo( cText )

   RETURN NIL

STATIC FUNCTION Compare2( cMemo1, cMemo2 )

   hwg_MsgInfo( iif( cMemo1 == cMemo2, "Equal", "Different" ) )

   RETURN Nil

#include "demo.ch"
