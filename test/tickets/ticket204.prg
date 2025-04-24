#include "hwgui.ch"

FUNCTION MAIN

SET CENTURY ON

Test()

RETURN NIL

Function Test()
Local oDlg, oBrw
Local aSample := { {"Alex Santos Silva XYZ",17,1200,ctod('01/01/2025'),1}, {"Victor Vladimir Soares ABCDEF",42,1600,ctod('01/02/2025'),2}, {"John Lennon Bob Marley",31,1000,ctod('01/03/2025'),3} }

   INIT DIALOG oDlg TITLE "Browse 3 dots";
         AT 0, 0 SIZE 520, 230 ;
         FONT HFont():Add( "Verdana",0,-17 ) 

   @ 10,20 BROWSE oBrw ARRAY SIZE 510,140 STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL ;
         ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   hwg_CreateArList( oBrw, aSample )

   oBrw:aColumns[1]:heading := PADR("Name",30)
   oBrw:aColumns[2]:heading := PADR("Age",3)
   oBrw:aColumns[4]:heading := PADR("Date",DATELENGTH())
   * Comment added by Itamar M. Lins Jr. at 23.04.2025
   * DF7BE:
   * Now the length must have a secure addition :
   * CENTURY ON  : 10 + 2 = 12
   * CENTURY OFF : 8 + 2  = 10
   * Fixed in hbrowse.prg:
   *  IF oColumn:type == "D"
   *   IF hwg_getCentury()
   *    oColumn:length := Max(oColumn:length,12)  && old: 10
   *   ELSE
   *    oColumn:length := Max(oColumn:length,10)
   *   ENDIF
   *
   // oBrw:aColumns[4]:length:=12 //->date is 8 characters, I put + 1, and Browse GTK cut and put "..." 
   // For bug with field length see comment in ticket203.prg !
   // oBrw:aColumns[4]:length:=9
   oBrw:aColumns[2]:lEditable := .T.
   oBrw:aColumns[1]:length:=20


   @ 100,180 BUTTON 'Close' SIZE 100,28 ON CLICK {|| oDlg:Close() } ;
         ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oDlg CENTER
Return Nil


FUNCTION DATELENGTH()
RETURN IIF (hwg_getCentury(),12,10)
