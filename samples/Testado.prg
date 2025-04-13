/*
 *
 * Testado.prg
 *
 * Test program sample for ADO Browse.
 *
 * $Id$
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Copyright 2020 Itamar M. Lins Jr. Junior and
 * José Quintas (TNX)
 * See ticket #55

*/
   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow

   INIT WINDOW oMainWindow MAIN TITLE "ADO Example" ;
     AT 200,0 SIZE 400,150

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Browse ADO" ACTION DlgADO()
      MENUITEM "&Browse DBF" ACTION DlgDBF()
   ENDMENU

   ACTIVATE WINDOW oMainWindow

RETURN Nil

FUNCTION DlgADO()

   LOCAL oModDlg, oBrw, cnSQL

   //cnSQL := win_OleCreateObject( "ADODB.Recordset" )
   //cnSQL:Open( hb_cwd() + "teste.ado" )
   cnSQL := RecordsetADO()

   INIT DIALOG oModDlg TITLE "ADO BROWSE" AT 0,0 SIZE 1024,600

   @ 20,10 BROWSE ARRAY oBrw SIZE 800,500 STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL
   oBrw:bOther := {|oBrw, msg, wParam, lParam| fKeyDown(oBrw, msg, wParam, lParam)}

   @ 500,540 OWNERBUTTON ON CLICK {||  hwg_EndDialog()} SIZE 180,36 FLAT TEXT "Close" COLOR hwg_ColorC2N("0000FF")

   oBrw:aArray := cnSQL
   oBrw:AddColumn( HColumn():New( "Name",   { |v,o| (v), o:aArray:Fields( "NAME" ):Value }  ,"C",30,0,.F.,DT_CENTER ) )
   oBrw:AddColumn( HColumn():New( "Adress", { |v,o| (v), o:aArray:Fields( "ADRESS" ):Value },"C",30,0,.T.,DT_CENTER,DT_LEFT ) )

   oBrw:bSkip     := { | o, nSkip | ADOSkipper( o:aArray, nSkip ) }
   oBrw:bGotop    := { | o | o:aArray:MoveFirst() }
   oBrw:bGobot    := { | o | o:aArray:MoveLast() }
   oBrw:bEof      := { | o | o:nCurrent > o:aArray:RecordCount() }
   oBrw:bBof      := { | o | o:nCurrent == 0 }
   oBrw:bRcou     := { | o | o:aArray:RecordCount() }
   oBrw:bRecno    := { | o | o:aArray:AbsolutePosition }
   obrw:bRecnoLog := oBrw:bRecno
   oBrw:bGOTO     := { | o, n | (o), o:aArray:Move( n - 1, 1 ) }

   ACTIVATE DIALOG oModDlg

   cnSQL:Close()

RETURN Nil

FUNCTION ADOSkipper( cnSQL, nSkip )

   LOCAL nRec := cnSQL:AbsolutePosition()

   IF ! cnSQL:Eof()
      cnSQL:Move( nSkip )
      IF cnSQL:Eof()
         cnSQL:MoveLast()
      ENDIF
      IF cnSQL:Bof()
         cnSQL:MoveFirst()
      ENDIF
   ENDIF

RETURN cnSQL:AbsolutePosition() - nRec


STATIC FUNCTION fKeyDown(oBrw, msg, wParam, lParam)

   LOCAL nKEY := hwg_PtrToUlong( wParam ) //wParam

   IF msg == WM_KEYDOWN
      IF nKey = VK_F2
         hwg_Msginfo("nRecords: " + Str(oBrw:nRecords) + hb_eol() +;
                     "Total:    " + Str(oBrw:aArray:RecordCount()) + hb_eol() + ;
                     "Recno:    " + Str(oBrw:nCurrent) + hb_eol() + ;
                     "Abs:      " + Str(oBrw:aArray:AbsolutePosition)  )
      ENDIF
   ENDIF

   (lParam) // -w3 -es2

RETURN .T.

// --- Recordset ADO ---

#define AD_VARCHAR     200

FUNCTION RecordsetADO()

   LOCAL nCont, cChar := "A"
   LOCAL cnSQL := win_OleCreateObject( "ADODB.Recordset" )

   WITH OBJECT cnSQL
      :Fields:Append( "NAME", AD_VARCHAR, 30 )
      :Fields:Append( "ADRESS", AD_VARCHAR, 30 )
      :Open()
      FOR nCont = 1 TO 10
         :AddNew()
         :Fields( "NAME" ):Value := "ADO_NAME_" + Replicate( cChar, 10 ) + Str( nCont, 6 )
         :Fields( "ADRESS" ):Value := "ADO_ANDRESS_" + Replicate( cChar, 10 ) + Str( nCont, 6 )
         :Update()
         cChar := iif( cChar == "Z", "A", Chr( Asc( cChar ) + 1 ) )
      NEXT
      :MoveFirst()
   ENDWITH

RETURN cnSQL

FUNCTION DlgDBF()

   LOCAL oModDlg, oBrw

   CreateDBF( "test" )
   USE test

   INIT DIALOG oModDlg TITLE "ADO BROWSE" AT 0,0 SIZE 1024,600

   @ 20,10 BROWSE oBrw DATABASE SIZE 800,500 STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL
   oBrw:bOther := {|oBrw, msg, wParam, lParam| fKeyDown(oBrw, msg, wParam, lParam)}

   @ 500,540 OWNERBUTTON ON CLICK {|| hwg_EndDialog()} SIZE 180,36 FLAT TEXT "Close" COLOR hwg_ColorC2N("0000FF")

   Add column FieldBlock("NAME")   to oBrw Header 'Name'   Length 30 justify Line DT_LEFT
   Add column FieldBlock("ADRESS") to oBrw Header 'Adress' Length 30 justify Line DT_LEFT

   ACTIVATE DIALOG oModDlg
   CLOSE DATABASE

RETURN Nil

// --- DBF ---
FUNCTION CreateDbf( cName )

   IF hb_vfExists( cName )
      RETURN NIL
   ENDIF

   dbCreate( cName, { ;
      { "NAME", "C", 30, 0 }, ;
      { "ADRESS", "C", 30, 0 } } )
   USE ( cName )
   APPEND BLANK
   REPLACE test->name WITH "DBF_AAAA", test->adress WITH "DBF_AAAA"
   APPEND BLANK
   REPLACE test->name WITH "DBF_BBBB", test->adress WITH "DBF_BBBB"
   APPEND BLANK
   REPLACE test->name WITH "DBF_CCCC", test->adress WITH "DBF_CCCC"
   USE

   RETURN NIL

* ==================== EOF of Testado.prg =======================
