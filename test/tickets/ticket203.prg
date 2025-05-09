#include "hwgui.ch"

FUNCTION MAIN

Test()

RETURN NIL

Function Test()
Local oDlg, oBrw
// Local aSample := { {"Alex Santos Silva   ",17,1200}, {"Victor Vladimir Soares   ",42,1600}, {"John Lennon Bob Marley   ",31,1000} }

Local aSample := { {"Alex Santos Silva",17,1200}, {"Victor Vladimir Soares",42,1600}, {"John Lennon Bob Marley",31,1000} }

   INIT DIALOG oDlg TITLE "Browse Align and Streth of columns";
         AT 0, 0 SIZE 600, 230 ;  && old size: 400, 230
         FONT HFont():Add( "Verdana",0,-17 ) 

   @ 10,20 BROWSE oBrw ARRAY SIZE 540,140 STYLE WS_BORDER + WS_VSCROLL ;  && old size: 340,140
         ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   // hwg_CreateArList() sets the array to browse and creates columns
   // You may use oBrw:AddColumn( HColumn():New(...) ) instead to set
   // columns with necessary options.
   hwg_CreateArList( oBrw, aSample )

   // In case of using hwg_CreateArList() you may set some columns options later,
   // for example:
   // DF7BE:
   // Bugfix for get length of column:
   // Browsing a database, the length of every column is delivered by the 
   // structure data.
   // For arrays, in the init of browse, the field length is got from the length of the
   // header text. So trim the header text with PADR() to the desired length ! 
   oBrw:aColumns[1]:heading := PADR("Name",45)
   oBrw:aColumns[2]:heading := PADR("Age",4)
   oBrw:aColumns[2]:lEditable := .T.
 //  oBrw:aColumns[1]:length:=30   && old: 20

   @ 100,180 BUTTON 'Close' SIZE 100,28 ON CLICK {|| oDlg:Close() } ;
         ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oDlg CENTER
Return Nil

FUNCTION DATELENGTH()
RETURN IIF (hwg_getCentury(),12,10)
