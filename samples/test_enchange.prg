/*
 * test_enchange.prg - exercise EN_CHANGE dispatch on GTK4.
 *
 * Confirms that HWG_CREATEEDIT + cb_editable_changed in window.c
 * forward EN_CHANGE to the Harbour side, and that the busy flag
 * installed by HWG_EDIT_SETTEXT suppresses the notification when
 * the change is programmatic.
 *
 * Uses the native ON CHANGE clause of the GET command; HEdit now
 * stores the block in ::bChange and calls it from the EN_CHANGE
 * branch of onEvent(), matching the WinAPI semantics.
 *
 * Build (GTK4):
 *     hbmk2 test_enchange.prg
 */

#include "hwgui.ch"

STATIC oWnd
STATIC oGet
STATIC oLblCount
STATIC oLblStatus

STATIC nCount := 0
STATIC cVal   := ""

/* ------------------------------------------------------------------ */

FUNCTION Main()

   INIT WINDOW oWnd MAIN TITLE "EN_CHANGE test" ;
      AT 100, 100 SIZE 480, 320

   /* ---- Edit under test ----
    * ON CHANGE fires on every user keystroke; the second parameter
    * of the block is the HEdit object itself. */
   @  20,  20 SAY  "Type here:" SIZE 100, 24
   @ 130,  20 GET  oGet VAR cVal  SIZE 300, 28 ;
      ON CHANGE { | cText, o | OnChange( cText, o ) }

   hwg_MsgInfo( "bChange = " + IF( oGet:bChange == Nil, "NIL (macros nao passaram)", "OK (bloco chegou)" ) )

   /* ---- Counter ---- */
   oLblCount := HStatic():New( oWnd, , , 130, 60, 300, 24 )
   oLblCount:SetText( "EN_CHANGE fired 0 times" )

   /* ---- Status line ---- */
   oLblStatus := HStatic():New( oWnd, , , 130, 88, 300, 24 )
   oLblStatus:SetText( "Ready." )

   /* ---- Buttons ---- */
   @  20, 140 BUTTON "SetText" SIZE 110, 32 OF oWnd ;
      ON CLICK { || TestSetText() }
   @ 140, 140 BUTTON "Refresh" SIZE 110, 32 OF oWnd ;
      ON CLICK { || TestRefresh() }
   @ 260, 140 BUTTON "Reset"   SIZE 110, 32 OF oWnd ;
      ON CLICK { || ResetCounter() }

   /* ---- Hint ---- */
   @  20, 190 SAY "Expected behaviour:" SIZE 400, 24
   @  20, 214 SAY "  Typing / Backspace  -> counter goes up" SIZE 400, 24
   @  20, 238 SAY "  SetText button      -> counter stays put" SIZE 400, 24
   @  20, 262 SAY "  Refresh button      -> counter stays put" SIZE 400, 24

   ACTIVATE WINDOW oWnd CENTER

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Runs on every EN_CHANGE that comes from the user.  The busy flag
 * installed by HWG_EDIT_SETTEXT keeps this from firing during
 * programmatic calls, so the counter only moves for real typing. */
STATIC FUNCTION OnChange( cText, oEdit )

   HB_SYMBOL_UNUSED( cText )
   HB_SYMBOL_UNUSED( oEdit )

   nCount++
   IF oLblCount != Nil
      oLblCount:SetText( "EN_CHANGE fired " + LTrim( Str( nCount ) ) + ;
                         " times" )
   ENDIF
   IF oLblStatus != Nil
      oLblStatus:SetText( "Last change: user typed (counter " + ;
                          LTrim( Str( nCount ) ) + ")" )
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Programmatic SetText: must NOT increment the counter.  The busy
 * flag in HWG_EDIT_SETTEXT is what makes this work. */
STATIC FUNCTION TestSetText()

   LOCAL nBefore := nCount

   oGet:SetText( "abc" )

   IF nCount == nBefore
      oLblStatus:SetText( "SetText: counter unchanged (OK)" )
   ELSE
      oLblStatus:SetText( "SetText: counter INCREASED (BUG!)" )
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

/* Programmatic Refresh: reads bSetGet and pushes the value through
 * HWG_EDIT_SETTEXT.  Same expectation as TestSetText. */
STATIC FUNCTION TestRefresh()

   LOCAL nBefore := nCount

   oGet:Refresh()

   IF nCount == nBefore
      oLblStatus:SetText( "Refresh: counter unchanged (OK)" )
   ELSE
      oLblStatus:SetText( "Refresh: counter INCREASED (BUG!)" )
   ENDIF

   RETURN Nil

/* ------------------------------------------------------------------ */

STATIC FUNCTION ResetCounter()

   nCount := 0
   IF oLblCount != Nil
      oLblCount:SetText( "EN_CHANGE fired 0 times" )
   ENDIF
   IF oLblStatus != Nil
      oLblStatus:SetText( "Counter reset." )
   ENDIF
   oGet:SetFocus()

   RETURN Nil
