/*
 * chartdemo.prg
 *
 * Sample for HChart: bars, line and pie, side by side.
 */

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDlg
   LOCAL oChart1, oChart2, oChart3
   LOCAL aSales, aShare

   aSales := { ;
      { "Jan", 120, 80 }, ;
      { "Feb", 150, 95 }, ;
      { "Mar", 180, 110 }, ;
      { "Apr", 140, 130 }, ;
      { "May", 210, 155 }, ;
      { "Jun", 175, 140 } }

   aShare := { ;
      { "North", 42 }, ;
      { "South", 27 }, ;
      { "East",  18 }, ;
      { "West",  13 } }

   INIT DIALOG oDlg TITLE "HChart sample" AT 100, 100 SIZE 900, 620

   @ 20, 20 CHART oChart1 ;
      TYPE CHART_BAR ;
      ITEMS aSales ;
      TITLE "Monthly sales" ;
      OF oDlg ;
      SIZE 860, 180 ;
      STYLE WS_BORDER

   @ 20, 210 CHART oChart2 ;
      TYPE CHART_LINE ;
      ITEMS aSales ;
      TITLE "Trend" ;
      OF oDlg ;
      SIZE 860, 180 ;
      STYLE WS_BORDER

   @ 20, 400 CHART oChart3 ;
      TYPE CHART_PIE ;
      ITEMS aShare ;
      TITLE "Regional share" ;
      OF oDlg ;
      SIZE 860, 180 ;
      STYLE WS_BORDER

   ACTIVATE DIALOG oDlg CENTER

   HB_SYMBOL_UNUSED( oChart1 )
   HB_SYMBOL_UNUSED( oChart2 )
   HB_SYMBOL_UNUSED( oChart3 )

   RETURN Nil
