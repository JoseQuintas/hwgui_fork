/*
 * alert() replacement.
 *
 * Copyright 2005,2020 Alex Strickland <sscc@mweb.co.za>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, you have permission for
 * additional uses of the text contained in its release of HWGUI.
 *
 * The exception is that, if you link the HWGUI library with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the HWGUI library code into it.
 *
 */


#include "hwgui.ch"

#include "halert.ch"


ANNOUNCE HB_GTSYS
REQUEST HB_GT_GUI_DEFAULT

PROCEDURE main

   LOCAL i
   LOCAL oAlert
   //LOCAL nResult
   LOCAL oMainWindow
   //LOCAL hCursor

   hwg_Alert("Hello")

   /* hCursor := */ Hwg_SetCursor(Hwg_LoadCursor(IDC_WAIT))
        // not Modal, param 7
   SetDefaultAlert( , , 10, IDI_HAND, , , ALERT_NOTMODAL, , , , , ALERT_NOCLOSEBUTTON)
        // Note default aOptions overriden with empty array
   hwg_Alert("We will be processing (well, sleeping and beeping) for 5s (not modal)  ...", { })
   FOR i := 1 TO 5
      Hwg_MsgBeep( MB_ICONEXCLAMATION )
      Hwg_Sleep(1000)
   NEXT
   hwg_ReleaseDefaultAlert()
   hwg_GetDefaultAlert():ResetVars()
   //hCursor := Hwg_SetCursor(hCursor)

   ResetDefaultAlert()
   // Can't close - shows icon in title bar (and task bar)
   // Note aOptions overriden with empty array in SetDefaultAlert
   SetDefaultAlert( , , 10, IDI_HAND, { }, , , 5, , , ALERT_TITLEICON, ALERT_NOCLOSEBUTTON)
   hwg_Alert("Useful ever? (5s imposed wait doing nothing (modal), can't press esc); note title icon ...")
   hwg_GetDefaultAlert():ResetVars()

   // Thread safe like this, straight Alert and friends are not.
   HAlert():Init():Alert("Our own temporary object alert", { "Good", "or", "Bad" })

   // Compare alert() to Hwg_MsgYesNoCancel()
   hwg_Alert("hwg_Alert() returned " + ;
      HB_ValToStr(Alert("'ello 'ello;How are you?;I am alert();;abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", ;
      { "Yes", "No", "Cancel" })))
   // By way of comparison to MessageBox which is what Hwg_MsgYesNoCancel() calls
   hwg_Alert("Hwg_MsgYesNoCancel() returned " + ;
      HB_ValToStr(Hwg_MsgYesNoCancel("'ello 'ello" + chr(10) + "How are you?" + chr(10) + "I am Hwg_MsgYesNoCancel()" + chr(10) + chr(10) + ;
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", "Alert")))

   SetDefaultAlert("Error", , , IDI_ERROR, , SS_LEFT)
   /* Result := */ hwg_Alert("This is how an error with Alert looks")
   // By way of comparison to "error look" of MessageBox
   Hwg_MsgStop("This is how an error with Hwg_MsgStop looks!", "Error")

   // This is not a clone! So you working with the static Alert object (a pointer to it, anyway)
   oAlert := hwg_GetDefaultAlert()
   oAlert:Title := "Better than MessageBox"
   oAlert:Beep := .f.  // Quiet please
   oAlert:Icon := IDI_EXCLAMATION
   oAlert:FontSize := 18
   hwg_Alert("MessageBox can't do this, and quietly as well!")
       // This is a clone
   oAlert := __objclone(hwg_GetDefaultAlert())
   oAlert:FontSize := 28
   oAlert:Alert("MessageBox can't do this, and quietly as well!;Clone")
       // so the original is unchanged
   hwg_Alert("MessageBox can't do this, and quietly as well!;Original")
   ResetDefaultAlert()

   oAlert := hwg_GetDefaultAlert()
   oAlert:Title := ""
   oAlert:Beep := .t.  // Noise again please
   oAlert:FontSize := 8
   oAlert:Time := 5
   oAlert:Icon := IDI_APPLICATION
   oAlert:TitleIcon := .t.
   /* nResult := */ hwg_Alert("5s and we are done;but you can hit enter first!")
       // Remember to switch this off for new alerts
   oAlert:Time := 0
   oAlert:Icon := IDI_INFORMATION

   oAlert:ResetVars()

   INIT WINDOW oMainWindow MAIN TITLE "Main Window" ;
      AT 200, 0 SIZE 420, 300 ;
      ON INIT { || TestNonModalAlert() }

   MENU OF oMainWindow
      MENUITEM "E&xit" ACTION { || hwg_Alert("Goodbye;;BTW I'm centered on the app window"), oMainWindow:Close() }
   ENDMENU

   ACTIVATE WINDOW oMainWindow CENTER

   // Hwg_DestroyWindow (when app ends) does not invoke EndDialog so "ON EXIT" is not called
   // for a non-modal alert that is hanging around.
   hwg_ReleaseDefaultAlert()

RETURN

STATIC PROCEDURE TestNonModalAlert()

   LOCAL nResult
   LOCAL oAlert1 := __objclone( hwg_GetDefaultAlert() )
   LOCAL oAlert2 := __objclone( hwg_GetDefaultAlert() )

   oAlert1:Modal := .f.
   oAlert1:Time := 10
   nResult := oAlert1:Alert("Just returns zero and will disappear when:;program ends;or it's dismissed;or after 10s.;;;")

   Alert("Non Modal Dialog has returned immediately with a result of " + HB_ValToStr(nResult))

   // This will work too, it is a second non-modal dialog
   oAlert2:Modal := .f.
   oAlert2:Time := 7
   oAlert2:Alert("This is the 2nd non-modal, timed dialog and will disappear when:;program ends;or it's dismissed;or after 7s.")

RETURN

