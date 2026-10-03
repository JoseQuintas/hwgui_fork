/*
 * test_msgs.prg - exercise CB_* and EM_* dispatch on GTK4
 *
 * Exercises the three message handlers registered in
 * source/gtk4/misc.c:
 *
 *   hwg_combo_handle_message  ->  CB_GETCOUNT, CB_GETCURSEL, ...
 *   hwg_edit_handle_message   ->  EM_GETSEL, EM_SETSEL, EM_SETREADONLY, ...
 *   hwg_listbox_handle_message -> (not used here; see utils/agenda)
 *
 * Build (GTK4):
 *     hbmk2 test_msgs.prg
 */

#include "hwgui.ch"

STATIC oWnd, oCmb, oGet

/* ------------------------------------------------------------------ */

FUNCTION Main()

   LOCAL cVal := "Hello"

   INIT WINDOW oWnd MAIN TITLE "Dispatch test" ;
      AT 100, 100 SIZE 420, 300

   /* ---- Combo ------------------------------------------------------
    * Height must be a real combobox height (~30 px).  GTK4 renders a
    * GtkComboBoxText as a single-row widget; giving it a tall
    * rectangle does not open the popup, it just stretches the widget
    * (and the popup arrow with it).  See HWG_CREATECOMBO in control.c.
    */
   @ 20,  20 SAY  "Combo:" SIZE 60, 26
   @ 90,  20 COMBOBOX oCmb ITEMS { "Alpha", "Bravo", "Charlie" } ;
      SIZE 200, 30 OF oWnd

   /* ---- Edit ------------------------------------------------------- */
   @ 20,  65 SAY "Edit:"  SIZE 60, 26
   @ 90,  65 GET oGet VAR cVal SIZE 200, 28

   /* ---- Buttons ---------------------------------------------------- */
   @ 20, 120 BUTTON "Report"   SIZE 110, 34 OF oWnd ;
      ON CLICK { || Report() }

   @ 20, 165 BUTTON "SetSel"   SIZE 110, 34 OF oWnd ;
      ON CLICK { || SetSelTest() }

   @ 20, 210 BUTTON "ReadOnly" SIZE 110, 34 OF oWnd ;
      ON CLICK { || ToggleReadOnly() }

   /* ---- Hint ------------------------------------------------------- */
   @ 150, 120 SAY "ReadOnly toggles:" SIZE 250, 24
   @ 150, 148 SAY "  1st click -> read-only" SIZE 250, 24
   @ 150, 172 SAY "  2nd click -> editable again" SIZE 250, 24

   ACTIVATE WINDOW oWnd CENTER

RETURN Nil

/* ------------------------------------------------------------------ */

/* Reads three CB_* / EM_* values and shows them in a message box.
 * The call goes through HWG_SENDMESSAGE in source/gtk4/misc.c, which
 * forwards to hwg_combo_handle_message / hwg_edit_handle_message. */
STATIC FUNCTION Report()

   LOCAL nCnt   := hwg_SendMessage( oCmb:handle, CB_GETCOUNT,  0, 0 )
   LOCAL nSel   := hwg_SendMessage( oCmb:handle, CB_GETCURSEL, 0, 0 )
   LOCAL nSelE  := hwg_SendMessage( oGet:handle, EM_GETSEL,    0, 0 )
   LOCAL nMax   := hwg_SendMessage( oGet:handle, EM_GETLIMITTEXT, 0, 0 )

   hwg_MsgInfo( ;
      "CB_GETCOUNT      = " + LTrim( Str( nCnt ) )  + Chr(10) + ;
      "CB_GETCURSEL     = " + LTrim( Str( nSel ) )  + Chr(10) + ;
      "EM_GETSEL low    = " + LTrim( Str( hwg_Loword( nSelE ) ) ) + Chr(10) + ;
      "EM_GETSEL hi     = " + LTrim( Str( hwg_Hiword( nSelE ) ) ) + Chr(10) + ;
      "EM_GETLIMITTEXT  = " + LTrim( Str( nMax ) ) )

RETURN Nil

/* ------------------------------------------------------------------ */

/* Selects characters 2..4 of "Hello" -- i.e. "ell". */
STATIC FUNCTION SetSelTest()

   hwg_SendMessage( oGet:handle, EM_SETSEL, 1, 4 )
   hwg_MsgInfo( "Selected chars 1..3 of the edit (should be 'ell')" )

RETURN Nil

/* ------------------------------------------------------------------ */

/* Toggles read-only.  Tracks the state so a second click restores
 * editability -- the earlier version always set it to read-only. */
STATIC FUNCTION ToggleReadOnly()

   STATIC lRO := .F.

   lRO := ! lRO
   hwg_SendMessage( oGet:handle, EM_SETREADONLY, IF( lRO, 1, 0 ), 0 )

   IF lRO
      hwg_MsgInfo( "Edit is now read-only -- try to type into it" )
   ELSE
      hwg_MsgInfo( "Edit is editable again" )
   ENDIF

RETURN Nil
