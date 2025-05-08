/*
 *
 * demobrowseado.prg
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

#ifndef __PLATFORM__WINDOWS
   FUNCTION DemoBrowseADO( ... )

   hwg_MsgInfo( "This sample is Windows only" )

   RETURN Nil
#else
FUNCTION DemoBrowseADO( lWithDialog, oDlg )

   LOCAL oBrowse, cnSQL

   hb_Default( @lWithDialog, .T. )

   //cnSQL := win_OleCreateObject( "ADODB.Recordset" )
   //cnSQL:Open( hb_cwd() + "teste.ado" )
   cnSQL := RecordsetADO()

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demobrowseado.prg - Browse using ADO" ;
         AT 0,0 ;
         SIZE 800,600
   ENDIF

// on demo.ch
   ButtonForSample( "demobrowseado.prg", oDlg )

   @ 20, 80 BROWSE ;
      ARRAY oBrowse ;
      SIZE 600, 400 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   oBrowse:bOther := {|oBrowse, msg, wParam, lParam| fKeyDown(oBrowse, msg, wParam, lParam)}

   IF lWithDialog
      @ 500, 500 OWNERBUTTON ;
            ON CLICK {||  hwg_EndDialog()} ;
         SIZE 180,36 ;
         FLAT ;
         TEXT "Close" ;
         COLOR hwg_ColorC2N("0000FF")
   ENDIF

   oBrowse:aArray := cnSQL
   oBrowse:AddColumn( HColumn():New( "Name",   { |v,o| (v), o:aArray:Fields( "NAME" ):Value }  ,"C",30,0,.F.,DT_CENTER ) )
   oBrowse:AddColumn( HColumn():New( "Adress", { |v,o| (v), o:aArray:Fields( "ADRESS" ):Value },"C",30,0,.T.,DT_CENTER,DT_LEFT ) )

   oBrowse:bSkip     := { | o, nSkip | ADOSkipper( o:aArray, nSkip ) }
   oBrowse:bGotop    := { | o | o:aArray:MoveFirst() }
   oBrowse:bGobot    := { | o | o:aArray:MoveLast() }
   oBrowse:bEof      := { | o | o:nCurrent > o:aArray:RecordCount() }
   oBrowse:bBof      := { | o | o:nCurrent == 0 }
   oBrowse:bRcou     := { | o | o:aArray:RecordCount() }
   oBrowse:bRecno    := { | o | o:aArray:AbsolutePosition }
   oBrowse:bRecnoLog := oBrowse:bRecno
   oBrowse:bGOTO     := { | o, n | (o), o:aArray:Move( n - 1, 1 ) }

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER

      cnSQL:Close()
   ENDIF

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


STATIC FUNCTION fKeyDown(oBrowse, msg, wParam, lParam)

   LOCAL nKEY := hwg_PtrToUlong( wParam ) //wParam

   IF msg == WM_KEYDOWN
      IF nKey = VK_F2
         hwg_Msginfo("nRecords: " + Str(oBrowse:nRecords) + hb_eol() +;
                     "Total:    " + Str(oBrowse:aArray:RecordCount()) + hb_eol() + ;
                     "Recno:    " + Str(oBrowse:nCurrent) + hb_eol() + ;
                     "Abs:      " + Str(oBrowse:aArray:AbsolutePosition)  )
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
#endif

// show buttons and source code
#include "demo.ch"

* ==================== EOF of demobrowseado.prg =======================
