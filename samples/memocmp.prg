/*
 *
 * memocmp.prg
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
   so use the FUNCTION nMemolen(mmemo)
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

FUNCTION Main()

   LOCAL oWinMain
   LOCAL mmemo1, mmemo2

   SET EXACT ON
   * Init empty
   mmemo1 := ""
   mmemo2 := ""

   INIT WINDOW oWinMain ;
      MAIN  ;
      TITLE "Sample program Memo edit and compare" ;
      AT 100, 100 ;
      SIZE 600,400;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&File"
          MENUITEM "&Exit"              ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Edit"
         MENUITEM "Memo &1"  ACTION {|| mmemo1 := hwg_MemoEdit(mmemo1 , "Edit memo 1") }
         MENUITEM "Memo &2"  ACTION {|| mmemo2 := hwg_MemoEdit(mmemo2 , "Edit memo 2") }
         MENUITEM "Init memos with NIL"  ACTION {|| mmemo1 := NIL , mmemo2 := NIL }
      ENDMENU
      MENU TITLE "&Compare"
         MENUITEM " direct =="     ACTION Compare1(mmemo1, mmemo2)
         //
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN Nil

FUNCTION Compare1( mMemo1, mMemo2 )

   LOCAL nLines1 := 0, nLines2 := 0, nLen1 := 0, nLen2 := 0, cText := ""

   IF mMemo1 == NIL
      cText += "Memo1 is NIL" + hb_Eol()
   ELSE
      nLines1 := MLCount( mMemo1, 254 )
      nLen1   := Len( mMemo1 )
   ENDIF

   IF mMemo2 == NIL
      cText += "Memo2 is NIL" + hb_Eol()
   ELSE
      nLines2 := MLCount( mMemo2, 254 )
      nLen2   := Len( mMemo2 )
   ENDIF

   cText += "Memo1 have " + Ltrim( Str( nLines1 ) ) + " line(s) and " + ;
      Ltrim( Str( nLen1 ) ) + " chars" + hb_Eol()
   cText += "Memo2 have " + Ltrim( Str( nLines2 ) ) + " line(s) and " + ;
      Ltrim( Str( nLen2 ) ) + " chars" + hb_Eol()

   IF mMemo1 == mMemo2
      cText += "Memos are equal"
   ELSE
      cText += "Memos are not equal"
   ENDIF
   hwg_MsgInfo( cText )

   RETURN NIL
