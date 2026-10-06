/*
 * agenda.prg - Custom month-calendar/agenda widget for HWGui.
 *
 * A lightweight alternative to FiveWin's TCalEx, built on top of HStatic
 * with a custom paint handler.  Works on both backends:
 *   - WinAPI : native GDI drawing
 *   - GTK4   : Cairo-based drawing
 *
 * Appointments are persisted in a DBF file created on first run,
 * in the current working directory (see AGENDA_DBF below).
 *
 * Build (WinAPI):
 *     hbmk2 agenda.prg C:\dev\hwgui\hwgui.hbp
 * Build (GTK4 / Linux):
 *     hbmk2 agenda.prg
 */

#include "hbclass.ch"
#include "hwgui.ch"

#define WIN_W      820
#define WIN_H      620

/* Name (without extension) of the DBF file.  It is created on the
 * first run if it does not exist.  Delete the file to reset the
 * agenda, or change this constant to use a different dataset. */
#define AGENDA_DBF  "agenda"

/* Calendar geometry, in pixels.  The header heights are tuned for
 * the 12pt body font selected in Main().  If you change the font
 * size, adjust both these values and the character / line estimates
 * inside DrawTextAt(). */
#define AG_TITLE_H  36
#define AG_WDAY_H   26
#define AG_HEAD_H   ( AG_TITLE_H + AG_WDAY_H )

/* Colors, in WinAPI 0x00BBGGRR form.  The GTK4 backend normalises
 * them to Cairo-style RGB internally, so the same numeric values
 * work on both platforms. */
#define AG_TITLE_BG   0x00E8D8B8
#define AG_TITLE_TXT  0x00403010
#define AG_WDAY_BG    0x00D8C8A8
#define AG_WDAY_TXT   0x00605030
#define AG_DAY_BG     0x00FFFFFF
#define AG_OTHER_BG   0x00F2F2F2
#define AG_WKND_BG    0x00F8F0E8
#define AG_TODAY_BG   0x00D8FFD8
#define AG_SEL_BG     0x00FFD8B0
#define AG_DAY_TXT    0x00202020
#define AG_OTHER_TXT  0x00B8B8B8
#define AG_GRID_LINE  0x00C8C8C8
#define AG_APPT_DOT   0x000000D0
#define AG_NAV_TXT    0x00302010

STATIC oMain, oFont
STATIC oAgenda
STATIC oLbx

/* Cached list of appointments currently shown in the side list.
 * Kept in sync by ShowAppts() and used by EditAppt() / DelAppt()
 * to translate the HListBox 1-based selection back into the actual
 * TAppointment object, without recomputing GetApptsOfDay() again. */
STATIC aCurAppts := {}

/* ------------------------------------------------------------------ */

FUNCTION Main()

   #ifdef __PLATFORM__WINDOWS
      PREPARE FONT oFont NAME "Segoe UI"  WIDTH 0 HEIGHT -16 WEIGHT 400
   #else
      PREPARE FONT oFont NAME "Noto Sans" WIDTH 0 HEIGHT -16 WEIGHT 400
   #endif

   /* Open (and create if needed) the DBF before the window is built. */
   IF ! OpenAgendaDBF()
      hwg_MsgStop( "Cannot open " + AGENDA_DBF + ".dbf" + Chr(10) + ;
                   "Check write permission in the current folder." )
      RETURN Nil
   ENDIF

   INIT WINDOW oMain MAIN ;
      TITLE "Agenda - HWGui" ;
      AT 100, 50 SIZE WIN_W, WIN_H ;
      FONT oFont

   /* Close the DBF when the window is destroyed.  The .T. return
    * value tells HWGui the close is allowed (see onDestroy in
    * hwindow.prg: a .F. return blocks the destruction). */
   oMain:bDestroy := { || CloseAgendaDBF(), .T. }

   /* ---- Menu ---- */
   MENU OF oMain
      MENU TITLE "&File"
         MENUITEM "&New appointment..."   ACTION NewAppt()
         MENUITEM "&Edit selected"        ACTION EditAppt()
         MENUITEM "&Delete selected"      ACTION DelAppt()
         SEPARATOR
         MENUITEM "E&xit"                 ACTION oMain:Close()
      ENDMENU
      MENU TITLE "&View"
         MENUITEM "&Today"                ACTION oAgenda:GotoToday()
         SEPARATOR
         MENUITEM "&Previous month"       ACTION oAgenda:PrevMonth()
         MENUITEM "&Next month"           ACTION oAgenda:NextMonth()
         SEPARATOR
         MENUITEM "&Add sample data"      ACTION AddSamples()
         MENUITEM "&Clear all"            ACTION ClearAll()
      ENDMENU
      MENU TITLE "&Help"
         #ifdef __PLATFORM__WINDOWS
            MENUITEM "&About..." ACTION hwg_MsgInfo( "Agenda Demo" + Chr(10) + ;
                                          "HWGui + WinAPI" )
         #else
            MENUITEM "&About..." ACTION hwg_MsgInfo( "Agenda Demo" + Chr(10) + ;
                                          "HWGui + GTK4" )
         #endif
      ENDMENU
   ENDMENU

   /* ---- Custom calendar widget ---- */
   oAgenda := TAgendaEx():New( oMain, 10, 10, 520, 580, Date() )

   /* ---- Navigation buttons ---- */
   @ 550,  10 BUTTON "< Month" SIZE  80, 32 OF oMain ;
        ON CLICK { || oAgenda:PrevMonth() }
   @ 640,  10 BUTTON "Month >" SIZE  80, 32 OF oMain ;
        ON CLICK { || oAgenda:NextMonth() }
   @ 550,  50 BUTTON "Today"   SIZE 170, 32 OF oMain ;
        ON CLICK { || oAgenda:GotoToday() }

   /* ---- CRUD buttons ---- */
   @ 550,  90 BUTTON "New"     SIZE  80, 32 OF oMain ;
        ON CLICK { || NewAppt() }
   @ 640,  90 BUTTON "Edit"    SIZE  80, 32 OF oMain ;
        ON CLICK { || EditAppt() }
   @ 550, 128 BUTTON "Delete"  SIZE 170, 32 OF oMain ;
        ON CLICK { || DelAppt() }

   /* ---- Appointment list ----
    *
    * The ITEMS clause is mandatory: without it the #xcommand parser
    * does not bind oLbx to the object and the variable stays NIL.
    */
   @ 550, 170 SAY "Appointments:" OF oMain SIZE 200, 22
   @ 550, 195 LISTBOX oLbx ITEMS {} SIZE 250, 385 OF oMain ;
        ON DBLCLICK { || EditAppt() }

   /* ---- Load persisted data.  On a fresh DBF, seed it with the
    * sample set so the demo shows something the first time. ---- */
   LoadApptsFromDBF()

   SELECT AGENDA
   DbGoTop()
   IF Eof()
      AddSamples()
   ENDIF
   SELECT AGENDA

   /* ---- Event hooks ---- */
   oAgenda:bOnSelect   := { | d | ShowAppts( d ) }
   oAgenda:bOnDblClick := { | d | OnDayDblClick( d ) }

   ShowAppts( Date() )

   ACTIVATE WINDOW oMain CENTER

   /* Belt and braces: close the DBF even if the bDestroy hook did
    * not run (e.g. an alternative close path in a future HWGui). */
   CloseAgendaDBF()

   RETURN Nil

/* ================================================================== */
/* DBF persistence layer                                              */
/* ================================================================== */

/* Open the DBF, creating it on first run.  Returns .T. on success. */
STATIC FUNCTION OpenAgendaDBF()

   LOCAL aStruct

   IF ! File( AGENDA_DBF + ".dbf" )
      aStruct := { ;
         { "ID",        "N",  10, 0 }, ;
         { "DATA",      "D",   8, 0 }, ;
         { "HORA",      "C",   5, 0 }, ;
         { "DURACAO",   "N",   4, 0 }, ;
         { "TITULO",    "C",  60, 0 }, ;
         { "DESCRICAO", "C", 200, 0 }, ;
         { "COR",       "N",   8, 0 } ;
      }
      DbCreate( AGENDA_DBF, aStruct )
   ENDIF

   USE (AGENDA_DBF) ALIAS AGENDA NEW EXCLUSIVE
   IF NetErr()
      RETURN .F.
   ENDIF

   RETURN .T.

/* ------------------------------------------------------------------ */

STATIC FUNCTION CloseAgendaDBF()

   IF Select( "AGENDA" ) > 0
      DbCommitAll()
      DbCloseArea()
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Read every record into oAgenda:aAppts.  Called once at startup.
 * The array is reset first so a second call does not duplicate the
 * in-memory list.  Blank records (left over from earlier buggy runs
 * of DBFAddAppt) are skipped by the guard on TITULO. */
STATIC FUNCTION LoadApptsFromDBF()

   LOCAL oAppt

   oAgenda:aAppts := {}

   SELECT AGENDA
   DbGoTop()

   DO WHILE ! Eof()
      IF ! Empty( AllTrim( AGENDA->TITULO ) )
         oAppt := TAppointment():New( AGENDA->DATA, ;
                                       AllTrim( AGENDA->HORA ), ;
                                       AGENDA->DURACAO, ;
                                       AllTrim( AGENDA->TITULO ), ;
                                       AllTrim( AGENDA->DESCRICAO ), ;
                                       AGENDA->COR )
         oAppt:nId := AGENDA->ID
         AAdd( oAgenda:aAppts, oAppt )
      ENDIF
      DbSkip()
   ENDDO

   DbGoTop()

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Return max(ID) + 1.  Simple linear scan; fine for the demo scale.
 * For large datasets, build an index on ID and use DbSeek. */
STATIC FUNCTION NextApptId()

   LOCAL nMax := 0

   SELECT AGENDA
   DbGoTop()

   DO WHILE ! Eof()
      IF AGENDA->ID > nMax
         nMax := AGENDA->ID
      ENDIF
      DbSkip()
   ENDDO

   DbGoTop()

   RETURN nMax + 1

/* ------------------------------------------------------------------ */

/* Append one appointment.  The id is computed BEFORE DbAppend()
 * because NextApptId() moves the record pointer (DbGoTop / DbSkip),
 * and anything assigned to AGENDA->field after that would land on
 * whichever record the pointer stopped at -- not on the freshly
 * appended one.  That was the cause of "only the last entry shows
 * up": every Add was overwriting record #1. */
STATIC FUNCTION DBFAddAppt( oAppt )

   LOCAL nNewId

   SELECT AGENDA
   nNewId := NextApptId()

   DbAppend()
   AGENDA->ID        := nNewId
   AGENDA->DATA      := oAppt:dDate
   AGENDA->HORA      := oAppt:cTime
   AGENDA->DURACAO   := oAppt:nDuration
   AGENDA->TITULO    := oAppt:cTitle
   AGENDA->DESCRICAO := oAppt:cDescription
   AGENDA->COR       := oAppt:nColor

   oAppt:nId := nNewId

   DbCommit()

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Update the record whose ID matches oAppt:nId.  If oAppt has no
 * ID yet (nId is 0), the record is appended instead. */
STATIC FUNCTION DBFUpdateAppt( oAppt )

   LOCAL nId := oAppt:nId

   IF nId == Nil .OR. nId == 0
      DBFAddAppt( oAppt )
      RETURN Nil
   ENDIF

   SELECT AGENDA
   DbGoTop()

   DO WHILE ! Eof()
      IF AGENDA->ID == nId
         AGENDA->DATA      := oAppt:dDate
         AGENDA->HORA      := oAppt:cTime
         AGENDA->DURACAO   := oAppt:nDuration
         AGENDA->TITULO    := oAppt:cTitle
         AGENDA->DESCRICAO := oAppt:cDescription
         AGENDA->COR       := oAppt:nColor
         DbCommit()
         EXIT
      ENDIF
      DbSkip()
   ENDDO

   DbGoTop()

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Physically remove the record whose ID matches oAppt:nId. */
STATIC FUNCTION DBFDeleteAppt( oAppt )

   LOCAL nId := oAppt:nId

   IF nId == Nil .OR. nId == 0
      RETURN Nil
   ENDIF

   SELECT AGENDA
   DbGoTop()

   DO WHILE ! Eof()
      IF AGENDA->ID == nId
         DbDelete()
         //__DbPack()
         DbCommit()
         EXIT
      ENDIF
      DbSkip()
   ENDDO

   DbGoTop()

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Remove every record. */
STATIC FUNCTION DBFClearAll()

   SELECT AGENDA
   DbGoTop()

   DO WHILE ! Eof()
      DbDelete()
      DbSkip()
   ENDDO

   //__DbPack()
   DbCommit()
   DbGoTop()

   RETURN Nil

/* ================================================================== */
/* Application logic                                                  */
/* ================================================================== */

/* Adds one appointment to both the in-memory list and the DBF. */
STATIC FUNCTION AddApptEx( oAppt )

   DBFAddAppt( oAppt )
   oAgenda:AddAppt( oAppt )

   RETURN Nil

/* ------------------------------------------------------------------ */

STATIC FUNCTION AddSamples()

   AddApptEx( TAppointment():New( Date(),   "09:00", 60, ;
               "Daily standup", "Room 1" ) )
   AddApptEx( TAppointment():New( Date(),   "14:00", 90, ;
               "Client lunch",  "Restaurant" ) )
   AddApptEx( TAppointment():New( Date()+1, "10:30", 30, ;
               "Team call",     "" ) )

   ShowAppts( oAgenda:dSelected )

   RETURN Nil

/* ------------------------------------------------------------------ */

STATIC FUNCTION ClearAll()

   IF ! hwg_MsgYesNo( "Clear all appointments?" )
      RETURN Nil
   ENDIF

   DBFClearAll()
   oAgenda:aAppts := {}
   oAgenda:Refresh()
   ShowAppts( oAgenda:dSelected )

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Rebuild the side list from the appointments of dDay, and cache the
 * result in aCurAppts so Edit/Del can translate the HListBox
 * selection back into the corresponding TAppointment object. */
STATIC FUNCTION ShowAppts( dDay )

   LOCAL aA     := oAgenda:GetApptsOfDay( dDay )
   LOCAL aItems := {}
   LOCAL i

   FOR i := 1 TO Len( aA )
      AAdd( aItems, aA[i]:cTime + "  " + aA[i]:cTitle )
   NEXT

   aCurAppts := aA

   oLbx:aItems := aItems
   oLbx:Requery()

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Returns the 1-based index of the row currently selected in the
 * HListBox, or 0 when nothing is selected.
 *
 * Read directly from the widget via LB_GETCURSEL instead of relying
 * on oLbx:value, because on GTK4 the LBN_SELCHANGE notification path
 * requires hlistbox.prg to handle the message in onEvent() -- which
 * is not guaranteed across all builds.  Asking the widget is immune
 * to that and works on both backends. */
STATIC FUNCTION SelectedIndex()

   LOCAL n := hwg_SendMessage( oLbx:handle, LB_GETCURSEL, 0, 0 )

   RETURN IF( n >= 0, n + 1, 0 )

/* ------------------------------------------------------------------ */

STATIC FUNCTION OnDayDblClick( dDay )

   IF hwg_MsgYesNo( "Create a new appointment on " + DToC( dDay ) + "?" )
      NewApptOn( dDay )
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

STATIC FUNCTION NewAppt()

   NewApptOn( oAgenda:dSelected )

   RETURN Nil

/* ------------------------------------------------------------------ */

STATIC FUNCTION NewApptOn( dDay )

   LOCAL oAppt := TAppointment():New( dDay, "09:00", 60, "", "" )

   IF EditApptDialog( oAppt, .T. )
      AddApptEx( oAppt )
      ShowAppts( dDay )
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Edit the appointment currently selected in the side list.  If the
 * list is empty or nothing is selected, show a message and bail. */
STATIC FUNCTION EditAppt()

   LOCAL nPos, oAppt

   IF Empty( aCurAppts )
      hwg_MsgInfo( "No appointments to edit on this day." )
      RETURN Nil
   ENDIF

   nPos := SelectedIndex()
   IF nPos < 1 .OR. nPos > Len( aCurAppts )
      hwg_MsgInfo( "Select an appointment first." )
      RETURN Nil
   ENDIF

   /* Work on a copy so a Cancel leaves the original untouched.
    * CloneAppt preserves nId, so DBFUpdateAppt can locate the row. */
   oAppt := CloneAppt( aCurAppts[ nPos ] )

   IF EditApptDialog( oAppt, .F. )
      DBFUpdateAppt( oAppt )
      oAgenda:ReplaceAppt( aCurAppts[ nPos ], oAppt )
      ShowAppts( oAgenda:dSelected )
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

STATIC FUNCTION DelAppt()

   LOCAL nPos, oAppt

   IF Empty( aCurAppts )
      hwg_MsgInfo( "No appointments to delete on this day." )
      RETURN Nil
   ENDIF

   nPos := SelectedIndex()
   IF nPos < 1 .OR. nPos > Len( aCurAppts )
      hwg_MsgInfo( "Select an appointment first." )
      RETURN Nil
   ENDIF

   oAppt := aCurAppts[ nPos ]

   IF ! hwg_MsgYesNo( "Delete '" + oAppt:cTitle + "' at " + oAppt:cTime + "?" )
      RETURN Nil
   ENDIF

   DBFDeleteAppt( oAppt )
   oAgenda:DelAppt( oAppt )
   ShowAppts( oAgenda:dSelected )

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Shallow clone used by EditAppt so Cancel discards the changes.
 * The DBF id is carried over so the eventual update targets the
 * right record. */
STATIC FUNCTION CloneAppt( oSrc )

   LOCAL oNew := TAppointment():New( oSrc:dDate, oSrc:cTime, ;
                                     oSrc:nDuration, oSrc:cTitle, ;
                                     oSrc:cDescription, oSrc:nColor )

   oNew:nId := oSrc:nId

   RETURN oNew

/* ------------------------------------------------------------------ */

/* Modal dialog shared by New and Edit.  Returns .T. when the user
 * confirmed with OK, .F. on Cancel. */
STATIC FUNCTION EditApptDialog( oAppt, lIsNew )

   LOCAL oDlg, oGetTime, oGetTitle, oGetDesc
   LOCAL cTime  := oAppt:cTime
   LOCAL cTitle := oAppt:cTitle
   LOCAL cDesc  := oAppt:cDescription
   LOCAL lOK    := .F.
   LOCAL cCaption := IF( lIsNew, "New appointment", "Edit appointment" )

   INIT DIALOG oDlg TITLE cCaption ;
      AT 0, 0 SIZE 460, 300 ;
      FONT oFont

   @  20,  20 SAY "Date :" SIZE  80, 24
   @ 110,  20 SAY DToC( oAppt:dDate ) SIZE 320, 24

   @  20,  60 SAY "Time :" SIZE  80, 24
   @ 110,  60 GET oGetTime VAR cTime SIZE 110, 28

   @  20, 100 SAY "Title:" SIZE  80, 24
   @ 110, 100 GET oGetTitle VAR cTitle SIZE 320, 28

   @  20, 140 SAY "Notes:" SIZE  80, 24
   @ 110, 140 GET oGetDesc  VAR cDesc SIZE 320, 28

   @ 140, 220 BUTTON "OK"     SIZE 90, 34 ;
        ON CLICK { || SaveDialog( oAppt, cTime, cTitle, cDesc, @lOK ), ;
                       IF( lOK, oDlg:Close(), Nil ) }

   @ 250, 220 BUTTON "Cancel" SIZE 90, 34 ;
        ON CLICK { || oDlg:Close() }

   ACTIVATE DIALOG oDlg CENTER

   RETURN lOK

/* ------------------------------------------------------------------ */

STATIC FUNCTION SaveDialog( oAppt, cTime, cTitle, cDesc, lOK )

   cTitle := AllTrim( cTitle )
   IF Empty( cTitle )
      hwg_MsgInfo( "Title is required." )
      RETURN Nil
   ENDIF

   cTime := AllTrim( cTime )
   IF ! IsValidTime( cTime )
      hwg_MsgInfo( "Time must be in HH:MM format (00:00 to 23:59)." )
      RETURN Nil
   ENDIF

   oAppt:cTime        := cTime
   oAppt:cTitle       := cTitle
   oAppt:cDescription := cDesc

   lOK := .T.

   RETURN Nil

/* ------------------------------------------------------------------ */

STATIC FUNCTION IsValidTime( cTime )

   LOCAL nColon, cHH, cMM, nHH, nMM

   IF Empty( cTime )
      RETURN .F.
   ENDIF

   nColon := At( ":", cTime )
   IF nColon < 2 .OR. nColon > 3
      RETURN .F.
   ENDIF

   cHH := SubStr( cTime, 1, nColon - 1 )
   cMM := SubStr( cTime, nColon + 1 )

   IF Len( cMM ) != 2 .OR. ! ( ( cHH + cMM ) == DigitsOnly( cHH + cMM ) )
      RETURN .F.
   ENDIF

   nHH := Val( cHH )
   nMM := Val( cMM )

   RETURN nHH >= 0 .AND. nHH <= 23 .AND. nMM >= 0 .AND. nMM <= 59

/* ------------------------------------------------------------------ */

STATIC FUNCTION DigitsOnly( cStr )

   LOCAL i, c

   IF Empty( cStr )
      RETURN ""
   ENDIF

   FOR i := 1 TO Len( cStr )
      c := SubStr( cStr, i, 1 )
      IF c < "0" .OR. c > "9"
         RETURN ""
      ENDIF
   NEXT

   RETURN cStr

/* ================================================================== */
/* TAppointment - a single appointment                                */
/* ================================================================== */

CLASS TAppointment

   DATA dDate, cTime, nDuration, cTitle, cDescription, nColor
   DATA nId                    /* DBF record id (0 = not saved yet) */

   METHOD New( dDate, cTime, nDur, cTit, cDesc, nColor ) CONSTRUCTOR

ENDCLASS

METHOD New( dDate, cTime, nDur, cTit, cDesc, nColor ) CLASS TAppointment

   ::dDate        := dDate
   ::cTime        := cTime
   ::nDuration    := nDur
   ::cTitle       := cTit
   ::cDescription := cDesc
   ::nColor       := IF( nColor == Nil, AG_APPT_DOT, nColor )
   ::nId          := 0

   RETURN Self

/* ================================================================== */
/* TAgendaEx - custom-drawn month calendar with appointment markers   */
/* ================================================================== */

CLASS TAgendaEx FROM HStatic

   DATA dViewFirst
   DATA dSelected
   DATA aAppts
   DATA aDayNames

   DATA bOnSelect
   DATA bOnDblClick
   DATA bOnMonthChange

   DATA nColW, nRowH

   METHOD Init()                                         /* platform hook */
   METHOD New( oParent, nX, nY, nW, nH, dInit ) CONSTRUCTOR
   METHOD RecalcDims()
   METHOD Paint( hDC )
   METHOD DrawTitleBar( hDC )
   METHOD DrawWeekHeader( hDC )
   METHOD DrawCells( hDC )
   METHOD DrawCell( hDC, nIdx, dCell, lOther, lSel )
   METHOD HitTestDay( nX, nY )
   METHOD FirstCellDate()
   METHOD PrevMonth()
   METHOD NextMonth()
   METHOD GotoToday()
   METHOD AddAppt( oAppt )
   METHOD ReplaceAppt( oOld, oNew )
   METHOD DelAppt( oAppt )
   METHOD GetApptsOfDay( dDate )
   METHOD HasAppts( dDate )
   METHOD MonthLabel()
   METHOD OnLButtonDown( nX, nY )
   METHOD OnLButtonDblClick( nX, nY )
   METHOD onEvent( msg, wParam, lParam )

ENDCLASS

/* ------------------------------------------------------------------ */

METHOD Init() CLASS TAgendaEx

   ::Super:Init()

#ifdef __PLATFORM__WINDOWS
   // Windows: subclass the native STATIC so mouse messages reach
   // onEvent().  Without this the STATIC ignores WM_LBUTTONDOWN and
   // the calendar never changes day on click.  Other HStatic controls
   // (SAY) are not affected because the subclass is installed here,
   // not in HStatic:Init.
   hwg_InitStaticProc( ::handle )
#endif
   // GTK4: HWGui wires the widget signals internally and calls
   // onEvent() directly.  Nothing to do.

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD New( oParent, nX, nY, nW, nH, dInit ) CLASS TAgendaEx

   LOCAL d0
   LOCAL nStyle

   d0 := IF( dInit == Nil, Date(), dInit )

   ::dSelected  := d0
   ::dViewFirst := d0 - Day( d0 ) + 1
   ::aDayNames  := { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
   ::aAppts     := {}

#ifdef __PLATFORM__WINDOWS
   // Windows: SS_OWNERDRAW routes painting through the parent's
   // WM_DRAWITEM.  SS_NOTIFY is required for the STATIC to receive
   // mouse messages at all - without it, onEvent() never fires.
   nStyle := hwg_BitOr( SS_OWNERDRAW, SS_NOTIFY )
#else
   // GTK4: SS_OWNERDRAW is what makes HStatic connect the widget
   // "draw" signal and invoke the user bPaint.  Same as it was
   // before the WinAPI fix - do not change.
   nStyle := SS_OWNERDRAW
#endif

   ::Super:New( oParent, 0, nStyle, nX, nY, nW, nH )

   ::RecalcDims()

   ::bPaint := { | o, w | DoPaint( o ) }

   RETURN Self

/* ------------------------------------------------------------------ */

METHOD onEvent( msg, wParam, lParam ) CLASS TAgendaEx

   LOCAL nX, nY

   DO CASE
   CASE msg == WM_LBUTTONDOWN
      nX := hwg_Loword( lParam )
      nY := hwg_Hiword( lParam )
      ::OnLButtonDown( nX, nY )
      RETURN 0

   CASE msg == WM_LBUTTONDBLCLK
      nX := hwg_Loword( lParam )
      nY := hwg_Hiword( lParam )
      ::OnLButtonDblClick( nX, nY )
      RETURN 0
   ENDCASE

#ifdef __PLATFORM__WINDOWS
   // Windows: returning -1 makes StaticSubclassProc call the saved
   // original procedure, so WM_PAINT / WM_ERASEBKGND / focus / etc.
   // behave as default.  Without this the subclass swallows the
   // messages, WM_PAINT never validates and the app loops forever.
   RETURN -1
#else
   // GTK4: fall through to the parent class.
   RETURN ::Super:onEvent( msg, wParam, lParam )
#endif

/* ------------------------------------------------------------------ */

STATIC FUNCTION DoPaint( oAgenda )

   LOCAL hDC

#ifdef __PLATFORM__WINDOWS
   // Windows: painting is driven by the parent's WM_DRAWITEM, which
   // calls HStatic:DrawFromLpDis() -> Paint( hDC ).  DoPaint() is
   // not used on this path; calling it would bypass the paint cycle
   // and trigger an endless WM_PAINT loop.
   HB_SYMBOL_UNUSED( oAgenda )
#else
   // GTK4: HWGui invokes bPaint from the widget draw signal; a fresh
   // device context is valid at this point.
   hDC := hwg_GetDC( oAgenda:handle )
   IF hDC != Nil
      oAgenda:Paint( hDC )
      hwg_ReleaseDC( oAgenda:handle, hDC )
   ENDIF
#endif

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD RecalcDims() CLASS TAgendaEx

   ::nColW := Int( ::nWidth / 7 )
   ::nRowH := Int( ( ::nHeight - AG_HEAD_H ) / 6 )

   IF ::nRowH < 10
      ::nRowH := 10
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD FirstCellDate() CLASS TAgendaEx

   RETURN ::dViewFirst - ( Dow( ::dViewFirst ) - 1 )

/* ------------------------------------------------------------------ */

METHOD MonthLabel() CLASS TAgendaEx

   LOCAL aM := { "January", "February", "March",     "April",    ;
                 "May",     "June",     "July",      "August",   ;
                 "September","October","November",  "December" }

   RETURN aM[ Month( ::dViewFirst ) ] + " / " + ;
          StrZero( Year( ::dViewFirst ), 4 )

/* ------------------------------------------------------------------ */

METHOD Paint( hDC ) CLASS TAgendaEx

   IF hDC == Nil
      RETURN Nil
   ENDIF

   ::DrawTitleBar( hDC )
   ::DrawWeekHeader( hDC )
   ::DrawCells( hDC )

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD DrawTitleBar( hDC ) CLASS TAgendaEx

   LOCAL cLabel := ::MonthLabel()

   FillArea( hDC, 0, 0, ::nWidth, AG_TITLE_H, AG_TITLE_BG )

   DrawTextAt( hDC, "<", 0, 0, 32, AG_TITLE_H, .T., AG_NAV_TXT )
   DrawTextAt( hDC, ">", ::nWidth - 32, 0, ::nWidth, AG_TITLE_H, .T., AG_NAV_TXT )
   DrawTextAt( hDC, cLabel, 36, 0, ::nWidth - 36, AG_TITLE_H, .T., AG_TITLE_TXT )

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD DrawWeekHeader( hDC ) CLASS TAgendaEx

   LOCAL i, nX, nW := ::nColW

   FillArea( hDC, 0, AG_TITLE_H, ::nWidth, AG_HEAD_H, AG_WDAY_BG )

   FOR i := 1 TO 7
      nX := ( i - 1 ) * nW
      DrawTextAt( hDC, ::aDayNames[i], nX, AG_TITLE_H, ;
                  nX + nW, AG_HEAD_H, .T., AG_WDAY_TXT )
   NEXT

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD DrawCells( hDC ) CLASS TAgendaEx

   LOCAL i, dCell, dFirst, lOther, lSel

   dFirst := ::FirstCellDate()

   FOR i := 0 TO 41
      dCell  := dFirst + i
      lOther := ( Month( dCell ) != Month( ::dViewFirst ) )
      lSel   := ( dCell == ::dSelected )
      ::DrawCell( hDC, i, dCell, lOther, lSel )
   NEXT

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD DrawCell( hDC, nIdx, dCell, lOther, lSel ) CLASS TAgendaEx

   LOCAL nRow, nCol, nL, nT, nR, nB, nBg, nTxt, cTxt, lToday
   LOCAL nDotY, k, aA

   nRow := Int( nIdx / 7 )
   nCol := nIdx % 7

   nL := nCol * ::nColW
   nT := AG_HEAD_H + nRow * ::nRowH
   nR := nL + ::nColW
   nB := nT + ::nRowH

   lToday := ( dCell == Date() )

   DO CASE
   CASE lSel                      ; nBg := AG_SEL_BG
   CASE lToday                    ; nBg := AG_TODAY_BG
   CASE lOther                    ; nBg := AG_OTHER_BG
   CASE nCol == 0 .OR. nCol == 6  ; nBg := AG_WKND_BG
   OTHERWISE                      ; nBg := AG_DAY_BG
   ENDCASE

   FillArea( hDC, nL, nT, nR, nB, nBg )
   DrawBorder( hDC, nL, nT, nR, nB, AG_GRID_LINE )

   nTxt := IF( lOther, AG_OTHER_TXT, AG_DAY_TXT )
   cTxt := LTrim( Str( Day( dCell ) ) )
   DrawTextAt( hDC, cTxt, nL + 4, nT + 3, nR - 3, nT + ::nRowH - 3, ;
               .F., nTxt )

   IF ::HasAppts( dCell )
      aA    := ::GetApptsOfDay( dCell )
      nDotY := nT + 8
      FOR k := 1 TO Min( Len( aA ), 5 )
         FillArea( hDC, nR - 9, nDotY, nR - 4, nDotY + 6, aA[k]:nColor )
         nDotY += 8
      NEXT
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD HitTestDay( nX, nY ) CLASS TAgendaEx

   LOCAL nCol, nRow, nIdx

   IF nY < AG_HEAD_H
      RETURN Nil
   ENDIF

   nCol := Int( nX / ::nColW )
   nRow := Int( ( nY - AG_HEAD_H ) / ::nRowH )

   IF nCol < 0 .OR. nCol > 6 .OR. nRow < 0 .OR. nRow > 5
      RETURN Nil
   ENDIF

   nIdx := nRow * 7 + nCol

   RETURN ::FirstCellDate() + nIdx

/* ------------------------------------------------------------------ */

METHOD PrevMonth() CLASS TAgendaEx

   LOCAL dLast := ::dViewFirst - 1

   ::dViewFirst := dLast - Day( dLast ) + 1
   ::Refresh()

   IF ::bOnMonthChange != Nil
      Eval( ::bOnMonthChange, ::dViewFirst )
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD NextMonth() CLASS TAgendaEx

   LOCAL dTmp := ::dViewFirst + 32

   ::dViewFirst := dTmp - Day( dTmp ) + 1
   ::Refresh()

   IF ::bOnMonthChange != Nil
      Eval( ::bOnMonthChange, ::dViewFirst )
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD GotoToday() CLASS TAgendaEx

   LOCAL d := Date()

   ::dSelected  := d
   ::dViewFirst := d - Day( d ) + 1
   ::Refresh()

   IF ::bOnMonthChange != Nil
      Eval( ::bOnMonthChange, ::dViewFirst )
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD AddAppt( oAppt ) CLASS TAgendaEx
   AAdd( ::aAppts, oAppt )
   ::Refresh()
   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD ReplaceAppt( oOld, oNew ) CLASS TAgendaEx

   LOCAL i

   FOR i := 1 TO Len( ::aAppts )
      IF ::aAppts[i] == oOld
         ::aAppts[i] := oNew
         EXIT
      ENDIF
   NEXT

   ::Refresh()

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD DelAppt( oAppt ) CLASS TAgendaEx

   LOCAL i

   FOR i := 1 TO Len( ::aAppts )
      IF ::aAppts[i] == oAppt
         hb_ADel( ::aAppts, i, .T. )
         EXIT
      ENDIF
   NEXT

   ::Refresh()

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD GetApptsOfDay( dDate ) CLASS TAgendaEx

   LOCAL aRes := {}, i

   FOR i := 1 TO Len( ::aAppts )
      IF ::aAppts[i]:dDate == dDate
         AAdd( aRes, ::aAppts[i] )
      ENDIF
   NEXT

   RETURN aRes

/* ------------------------------------------------------------------ */

METHOD HasAppts( dDate ) CLASS TAgendaEx

   LOCAL i

   FOR i := 1 TO Len( ::aAppts )
      IF ::aAppts[i]:dDate == dDate
         RETURN .T.
      ENDIF
   NEXT

   RETURN .F.

/* ------------------------------------------------------------------ */

METHOD OnLButtonDown( nX, nY ) CLASS TAgendaEx

   LOCAL dDay

   IF nY < AG_TITLE_H
      IF nX < 32
         ::PrevMonth()
      ELSEIF nX > ::nWidth - 32
         ::NextMonth()
      ELSE
         ::GotoToday()
      ENDIF
      RETURN Nil
   ENDIF

   dDay := ::HitTestDay( nX, nY )
   IF dDay != Nil
      ::dSelected := dDay
      ::Refresh()
      IF ::bOnSelect != Nil
         Eval( ::bOnSelect, dDay )
      ENDIF
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

METHOD OnLButtonDblClick( nX, nY ) CLASS TAgendaEx

   LOCAL dDay := ::HitTestDay( nX, nY )

   IF dDay != Nil .AND. ::bOnDblClick != Nil
      Eval( ::bOnDblClick, dDay )
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */
/* Low-level drawing helpers                                          */
/* ------------------------------------------------------------------ */

STATIC FUNCTION FillArea( hDC, nL, nT, nR, nB, nColor )

   hwg_FillRect( hDC, nL, nT, nR, nB, HBrush():Add( nColor ):handle )

   RETURN Nil

STATIC FUNCTION DrawBorder( hDC, nL, nT, nR, nB, nColor )

   FillArea( hDC, nL,     nT,     nR,     nT + 1, nColor )
   FillArea( hDC, nL,     nB - 1, nR,     nB,     nColor )
   FillArea( hDC, nL,     nT,     nL + 1, nB,     nColor )
   FillArea( hDC, nR - 1, nT,     nR,     nB,     nColor )

   RETURN Nil

STATIC FUNCTION DrawTextAt( hDC, cText, nL, nT, nR, nB, lCentered, nColor )

   LOCAL nX, nY, nTW, nTH

   IF nColor != Nil
      hwg_SetTextColor( hDC, nColor )
   ENDIF

   IF lCentered
      nTW := Len( cText ) * 9
      nTH := 18
      nX  := nL + Int( ( nR - nL - nTW ) / 2 )
      nY  := nT + Int( ( nB - nT - nTH ) / 2 )
   ELSE
      nX := nL
      nY := nT
   ENDIF

   hwg_DrawText( hDC, cText, nX, nY, nR, nB, DT_LEFT + DT_SINGLELINE )

   RETURN Nil
