//================================================================//
// Programa......: Controle MonthCalendar - Exemplo
// Programador...: Marcos Antonio Gambeta
// Contato.......: marcos_gambeta@hotmail.com
// Website.......: http://geocities.yahoo.com.br/marcosgambeta/
//================================================================//
// Linguagem.....: Harbour/xHarbour + HWGUI
// Plataforma....: Windows
// Criado em ....: 17/2/2004 21:41:05
// Atualizado em : 17/2/2004 22:39:19
//================================================================//
// Este programa demonstra o uso do controle MonthCalendar da
// biblioteca HWGUI (Classe HMonthCalendar).
//================================================================//

FUNCTION DemoMonthCal( lWithDialog, oDlg )

#include "hwgui.ch"

#ifndef __PLATFORM__WINDOWS
   hwg_MsgInfo( "This sample is Windows only" )
   RETURN Nil
#else
   LOCAL oMonthCal1, oFontMonthCal1
   LOCAL oMonthCal2, oFontMonthCal2

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demomonthcal.prg - month calendar" ;
         AT 0, 00 ;
         SIZE 800, 600 ;
         BACKCOLOR 10408107
   ENDIF

   PREPARE FONT oFontMonthCal1 NAME "Arial" WIDTH 0 HEIGHT -12

// on demo.ch
   ButtonForSample( "demomonthcal.prg" )

   // On Win11 event on change occurs at any time
   @ 20, 50 MONTHCALENDAR oMonthCal1 ;
      SIZE 250,250 ;
      INIT ctod( "01/01/2004" ) ;
      ; // ON INIT { || hwg_Msginfo( "Evento On Init","MonthCalendar" ) } ;
      ; // ON CHANGE { || hwg_Msginfo( "Evento On Change","MonthCalendar" ) } ;
      NOTODAY NOTODAYCIRCLE WEEKNUMBERS ;
      FONT oFontMonthCal1 ;
      TOOLTIP "MonthCalendar - NoToday - NoTodayCircle - WeekNumbers"

   @ 20, 350 BUTTON "Get Date" ;
      ON CLICK { || hwg_Msginfo( dtoc( oMonthCal1:Value ) ) } ;
      SIZE 100,40

   @ 150, 350 BUTTON "Set Date" ;
      ON CLICK { || oMonthCal1:Value := Date() } ;
      SIZE 100,40

   PREPARE FONT oFontMonthCal2 NAME "Courier New" WIDTH 0 HEIGHT -12

   @ 300, 50 MONTHCALENDAR oMonthCal2 ;
      SIZE 250,250 ;
      INIT Date() ;
      FONT oFontMonthCal2

   @ 300, 350 BUTTON "Get Date" ;
      ON CLICK { || hwg_Msginfo(dtoc( oMonthCal2:Value ) ) } ;
      SIZE 100,40

   @ 430, 350 BUTTON "Set Date" ;
      ON CLICK { || oMonthCal2:Value := Date() } ;
      SIZE 100,40

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
   ENDIF

RETURN Nil
#endif

// show buttons and source code
#include "demo.ch"

* ======================== EOF of demmonthcal.prg ========================
