/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HMonthCalendar class
 *
 * Copyright 2004 Marcos Antonio Gambeta <marcos_gambeta@hotmail.com>
 * www - http://geocities.yahoo.com.br/marcosgambeta/
*/

#include "hwgui.ch"
#include "hbclass.ch"

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
   METHOD Value ( dValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bChange, cTooltip, lNoToday, lNoTodayCircle, ;
            lWeekNumbers ) CLASS HMonthCalendar

   nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP )
   nStyle   += IIf( lNoToday == Nil.OR. ! lNoToday, 0, MCS_NOTODAY )
   nStyle   += IIf( lNoTodayCircle == Nil.OR. ! lNoTodayCircle, 0, MCS_NOTODAYCIRCLE )
   nStyle   += IIf( lWeekNumbers == Nil.OR. ! lWeekNumbers, 0, MCS_WEEKNUMBERS )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              ,, cTooltip )

   ::dValue   := IIf( ValType( vari ) == "D" .And. ! Empty( vari ), vari, Date() )

   ::bChange := bChange

   HWG_InitCommonControlsEx()

   IF bChange != Nil
      ::oParent:AddEvent( MCN_SELECT, ::id, bChange, .T., "onChange" )
      ::oParent:AddEvent( MCN_SELCHANGE, ::id, bChange, .T., "onChange" )
   ENDIF

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HMonthCalendar

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_initmonthcalendar ( ::oParent:handle, ::id, ::style, ;
                                      ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init() CLASS HMonthCalendar

   IF ! ::lInit
      ::Super:Init()
      IF ! Empty( ::dValue )
         hwg_setmonthcalendardate( ::handle , ::dValue )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Value( dValue ) CLASS HMonthCalendar

   IF dValue != Nil
      IF ValType( dValue ) == "D" .And. ! Empty( dValue )
         hwg_setmonthcalendardate( ::handle, dValue )
         ::dValue := dValue
      ENDIF
   ELSE
      ::dValue := hwg_getmonthcalendardate( ::handle )
   ENDIF
   RETURN ::dValue

//--------------------------------------------------------------------------//

#pragma BEGINDUMP

#define _WIN32_IE      0x0500
#define HB_OS_WIN_32_USED
#ifndef _WIN32_WINNT
   #define _WIN32_WINNT   0x0400
#endif
#include "guilib.h"
#include <windows.h>
#include <commctrl.h>

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbdate.h"

#if defined(__DMC__)
#include "missing.h"
#endif

HB_FUNC( HWG_INITMONTHCALENDAR )
{
   HWND hMC;

   hMC = CreateWindowEx( 0,
                         MONTHCAL_CLASS,
                         TEXT(""),
                         (LONG) hb_parnl(3), /* 0,0,0,0, */
                         hb_parni(4), hb_parni(5),      /* x, y       */
                         hb_parni(6), hb_parni(7),      /* nWidth, nHeight */
                         (HWND) HB_PARHANDLE(1),
                         (HMENU) ( UINT_PTR ) hb_parni(2),
                         GetModuleHandle(NULL),
                         NULL );

   SetWindowPos( hMC, NULL, hb_parni(4), hb_parni(5), hb_parni(6),hb_parni(7), SWP_NOZORDER );

   HB_RETHANDLE(  hMC );
}

HB_FUNC( HWG_SETMONTHCALENDARDATE ) // adaptation of hwg_Setdatepicker of file Control.c
{
   PHB_ITEM pDate = hb_param( 2, HB_IT_DATE );

   if( pDate )
   {
      SYSTEMTIME sysTime;
      #ifndef HARBOUR_OLD_VERSION
      int lYear, lMonth, lDay;
      #else
      long lYear, lMonth, lDay;
      #endif

      hb_dateDecode( hb_itemGetDL( pDate ), &lYear, &lMonth, &lDay );

      sysTime.wYear = (unsigned short) lYear;
      sysTime.wMonth = (unsigned short) lMonth;
      sysTime.wDay = (unsigned short) lDay;
      sysTime.wDayOfWeek = 0;
      sysTime.wHour = 0;
      sysTime.wMinute = 0;
      sysTime.wSecond = 0;
      sysTime.wMilliseconds = 0;

      MonthCal_SetCurSel( (HWND) HB_PARHANDLE (1), &sysTime);

   }
}

HB_FUNC( HWG_GETMONTHCALENDARDATE ) // adaptation of hwg_Getdatepicker of file Control.c
{
   SYSTEMTIME st;
   char szDate[9];

   SendMessage( (HWND) HB_PARHANDLE (1), MCM_GETCURSEL, 0, (LPARAM) &st);

   hb_dateStrPut( szDate, st.wYear, st.wMonth, st.wDay );
   szDate[8] = 0;
   hb_retds( szDate );
}

HB_FUNC( HWG_GETMONTHCALENDARSIZE )
{
   RECT rc;
   PHB_ITEM aMetr = hb_itemArrayNew( 2 );
   PHB_ITEM temp;

   MonthCal_GetMinReqRect( (HWND) HB_PARHANDLE (1), &rc );

   temp = hb_itemPutNL( NULL, rc.right - rc.left );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.bottom - rc.top );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );

}

#pragma ENDDUMP

