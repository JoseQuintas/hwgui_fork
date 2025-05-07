#include "hwgui.ch"

FUNCTION Test

   LOCAL oDlg

   INIT DIALOG oDlg ;
      TITLE "About" ;
      AT 0, 0 ;
      SIZE 1024, 768

   Browse1()
   Browse2()
   Browse3()
   Browse4()

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil

FUNCTION Browse1()

   LOCAL oBrw1
   LOCAL aSample1 := { {"Alex",17,2500}, {"Victor",42,2200}, {"John",31,1800}, ;
      {"Sebastian",35,2000}, {"Mike",54,2600}, {"Sardanapal",22,2350}, {"Sergey",30,2800}, {"Petr",42,2450} }

   @ 20, 20 BROWSE oBrw1 ;
      ARRAY ;
      SIZE 280, 300 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL ;
      ON CLICK { || BrowseClick( oBrw1 ) }

   oBrw1:aArray := aSample1
   oBrw1:AddColumn( HColumn():New( "Name", {|v,o| (v), o:aArray[o:nCurrent,1]},"C",12,0,.F.,DT_CENTER ) )
   oBrw1:AddColumn( HColumn():New( "Age",  {|v,o| (v), o:aArray[o:nCurrent,2]},"N",6,0,.T.,DT_CENTER,DT_RIGHT ) )
   oBrw1:AddColumn( HColumn():New( "Koef", {|v,o| (v), o:aArray[o:nCurrent,3]},"N",6,0,.F.,DT_CENTER,DT_RIGHT ) )
   oBrw1:aColumns[2]:footing := "Age"
   oBrw1:aColumns[2]:lResizable := .F.

   RETURN Nil

FUNCTION Browse2()

   LOCAL oBrw2
   LOCAL aSample2 := { {"1","Line 1",10}, {"1","Line 2",22}, {"0","Line 3",40} }

   @ 20, 350 BROWSE oBrw2 ;
      ARRAY ;
      SIZE 280, 300 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL ;
      ON CLICK { || BrowseClick( oBrw2 ) }

   hwg_CREATEARLIST( oBrw2,aSample2 )

   oBrw2:aColumns[2]:length := 6
   oBrw2:aColumns[3]:length := 4
   //oBrw2:bKeyDown := { |o,key| BrwKey( o, key ) }
   //oBrw2:bcolorSel := oBrw2:htbColor := 0xeeeeee
   //oBrw2:tcolorSel := 0xff0000

   RETURN Nil

FUNCTION Browse3()

   LOCAL oBrw3, aRow, aCol
   LOCAL aList := Array(10,10)

   FOR EACH aRow IN aList
      FOR EACH aCol IN aRow
         aCol := Str( aRow:__EnumIndex(), 3 ) + "." + Str( aCol:__EnumIndex(), 3 )
      NEXT
   NEXT

   @ 500, 20 BROWSE oBrw3 ;
      ARRAY ;
      SIZE 280, 300 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL ;
      ON CLICK { || BrowseClick( oBrw3 ) }

   oBrw3:aArray := aList
   oBrw3:AddColumn( HColumn():New( "Name", {|v,o| (v), o:aArray[o:nCurrent,1]},"C",12,0,.F.,DT_CENTER ) )
   oBrw3:AddColumn( HColumn():New( "Age",  {|v,o| (v), o:aArray[o:nCurrent,2]},"C",10,0,.T.,DT_CENTER,DT_RIGHT ) )
   oBrw3:AddColumn( HColumn():New( "Koef", {|v,o| (v), o:aArray[o:nCurrent,3]},"C",10,0,.F.,DT_CENTER,DT_RIGHT ) )
   oBrw3:AddColumn( HColumn():New( "Name", {|v,o| (v), o:aArray[o:nCurrent,4]},"C",12,0,.F.,DT_CENTER ) )
   oBrw3:AddColumn( HColumn():New( "Age",  {|v,o| (v), o:aArray[o:nCurrent,5]},"C",10,0,.T.,DT_CENTER,DT_RIGHT ) )
   oBrw3:AddColumn( HColumn():New( "Koef", {|v,o| (v), o:aArray[o:nCurrent,6]},"C",10,0,.F.,DT_CENTER,DT_RIGHT ) )
   oBrw3:AddColumn( HColumn():New( "Name", {|v,o| (v), o:aArray[o:nCurrent,7]},"C",12,0,.F.,DT_CENTER ) )
   oBrw3:AddColumn( HColumn():New( "Age",  {|v,o| (v), o:aArray[o:nCurrent,8]},"C",10,0,.T.,DT_CENTER,DT_RIGHT ) )
   oBrw3:AddColumn( HColumn():New( "Koef", {|v,o| (v), o:aArray[o:nCurrent,9]},"C",10,0,.F.,DT_CENTER,DT_RIGHT ) )
   oBrw3:AddColumn( HColumn():New( "Name", {|v,o| (v), o:aArray[o:nCurrent,10]},"C",12,0,.F.,DT_CENTER ) )
   oBrw3:aColumns[2]:lResizable := .T.

   RETURN Nil

FUNCTION Browse4()

   LOCAL oBrw4, aRow, aCol
   LOCAL aList := Array(10,10)

   FOR EACH aRow IN aList
      FOR EACH aCol IN aRow
         aCol := Str( aRow:__EnumIndex(), 3 ) + "." + Str( aCol:__EnumIndex(), 3 )
      NEXT
   NEXT

   @ 500, 350 BROWSE oBrw4 ;
      ARRAY ;
      SIZE 280, 300 ;
      STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL ;
      ON CLICK { || BrowseClick( oBrw4 ) }

   hwg_CREATEARLIST( oBrw4, aList )

   oBrw4:aColumns[1]:length := 10
   oBrw4:aColumns[2]:length := 10
   oBrw4:aColumns[3]:length := 10
   oBrw4:aColumns[4]:length := 10
   oBrw4:aColumns[5]:length := 10
   oBrw4:aColumns[6]:length := 10
   oBrw4:aColumns[7]:length := 10
   oBrw4:aColumns[8]:length := 10
   oBrw4:aColumns[9]:length := 10
   oBrw4:aColumns[10]:length := 10
   //oBrw4:bKeyDown := { |o,key| BrwKey( o, key ) }
   //oBrw4:bcolorSel := oBrw2:htbColor := 0xeeeeee
   //oBrw4:tcolorSel := 0xff0000

   RETURN Nil

FUNCTION BrowseClick( oBrowse )

   hwg_MsgInfo( ;
      hb_ValToExp( oBrowse:RowPos ) + hb_Eol() + ;
      hb_ValToExp( oBrowse:ColPos ) )

   RETURN Nil
