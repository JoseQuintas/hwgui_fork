/*
 * $Id: hmonthc.prg 3359 2023-10-17 10:11:28Z alkresin $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HMonthCalendar class
 *
 * Copyright 2008 Luiz Rafael Culik (luiz at xharbour.com.br
 * www - http://www.xharbour.org
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It relies exclusively on the
 * hwg_* abstraction layer:
 *
 *   - hwg_Initmonthcalendar       → GtkCalendar            (control.c)
 *   - hwg_Setmonthcalendardate    → gtk_calendar_select_*
 *   - hwg_Getmonthcalendardate    → gtk_calendar_get_date (GDateTime*)
 *   - hwg_Monthcalendar_setaction → g_signal_connect("day-selected")
 *
 * The GtkCalendar "day-selected" signal is still present in GTK4, so
 * no translation is required in set_signal().
 */

#include "hbclass.ch"
#include "guilib.ch"

#define MCS_DAYSTATE             1
#define MCS_MULTISELECT          2
#define MCS_WEEKNUMBERS          4
#define MCS_NOTODAYCIRCLE        8
#define MCS_NOTODAY             16

CLASS HMonthCalendar INHERIT HControl

   CLASS VAR winclass   INIT "SysMonthCal32"

   DATA dValue
   DATA bChange

   METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bChange, cTooltip, lNoToday, lNoTodayCircle, ;
      lWeekNumbers )
   METHOD Activate()
   METHOD Init()
   METHOD Value( dValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bChange, cTooltip, lNoToday, lNoTodayCircle, ;
      lWeekNumbers ) CLASS HMonthCalendar

   * Parameters not used
   HB_SYMBOL_UNUSED(lNoToday)
   HB_SYMBOL_UNUSED(lNoTodayCircle)
   HB_SYMBOL_UNUSED(lWeekNumbers)

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      , , ctooltip )

   ::dValue   := iif( ValType( vari ) == "D" .AND. !Empty( vari ), vari, Date() )

   ::bChange := bChange

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HMonthCalendar

LOCAL bChg := {||
   ::dValue := hwg_Getmonthcalendardate( ::handle )
   IF !Empty( ::bChange )
      Eval( ::bChange )
   ENDIF
   RETURN .T.
   }

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Initmonthcalendar ( ::oParent:handle, , ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight )
      hwg_Setwindowobject( ::handle, Self )
      hwg_Monthcalendar_setaction( ::handle, bChg )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init() CLASS HMonthCalendar

   IF !::lInit
      ::Super:Init()
      IF !Empty( ::dValue )
         hwg_Setmonthcalendardate( ::handle , ::dValue )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Value( dValue ) CLASS HMonthCalendar

   IF dValue != Nil
      IF ValType( dValue ) == "D" .AND. !Empty( dValue )
         hwg_Setmonthcalendardate( ::handle, dValue )
         ::dValue := dValue
      ENDIF
   ENDIF

   RETURN ::dValue
