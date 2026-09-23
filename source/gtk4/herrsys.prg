/*
 * $Id: herrsys.prg 3838 2026-08-08 20:39:47Z itamarlins $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Windows errorsys replacement
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * The Harbour part is unchanged.  The embedded C handler in
 * #pragma BEGINDUMP was migrated to GTK4:
 *
 *   - GtkDialog::response signal was removed → use close-request.
 *   - gtk_widget_show_all() was removed      → use gtk_window_present().
 *   - gtk_main_iteration() was removed       → use g_main_context_iteration().
 *
 * The blocking-until-dismissed pattern is preserved so the fatal error
 * dialog still kills the process cleanly.
 */

#include "common.ch"
#include "error.ch"
#include "hwgui.ch"

DYNAMIC hwg_ErrMsg, hwg_WriteLog

STATIC LogInitialPath := ""
STATIC lInError := .F.

PROCEDURE hwg_ErrSys
   ErrorBlock( { | oError | DefError( oError ) } )
   LogInitialPath := "/" + CurDir() + iif( Empty( CurDir() ), "", "/" )
   RETURN

STATIC FUNCTION DefError( oError )
   LOCAL cMessage
   LOCAL cDOSError

   /* RECURSION PROTECTION: If an error hits while already in panic mode, force instant exit */
   IF lInError
      ErrorBlock( { || Nil } )
      hwg_NativeErrorShow( "Fatal: Recursive error loop detected inside ErrorSys." )
      RETURN .F.
   ENDIF
   lInError := .T.
   ErrorBlock( { || Nil } )

   // By default, division by zero results in zero
   IF oError:genCode == EG_ZERODIV
      lInError := .F.
      ErrorBlock( { | o | DefError( o ) } )
      RETURN 0
   ENDIF

   // Set NetErr() if there was a database open error
   IF oError:genCode == EG_OPEN .AND. oError:osCode == 32 .AND. oError:canDefault
      NetErr( .T. )
      lInError := .F.
      ErrorBlock( { | o | DefError( o ) } )
      RETURN .F.
   ENDIF

   // Set NetErr() if there was a lock error on dbAppend()
   IF oError:genCode == EG_APPENDLOCK .AND. oError:canDefault
      NetErr( .T. )
      lInError := .F.
      ErrorBlock( { | o | DefError( o ) } )
      RETURN .F.
   ENDIF

   cMessage := hwg_ErrMsg( oError )
   IF ! Empty( oError:osCode )
      cDOSError := "(DOS Error " + LTrim( Str( oError:osCode ) ) + ")"
      cMessage += " " + cDOSError
   ENDIF

   cMessage += hwg_Trace()
   cMessage += Chr( 13 ) + Chr( 10 ) + Chr( 13 ) + Chr( 10 ) + hwg_version()
   cMessage += Chr( 13 ) + Chr( 10 ) + "Date:" + DToC( Date() )
   cMessage += Chr( 13 ) + Chr( 10 ) + "Time:" + Time()

   hwg_ReleaseTimers()
   MemoWrit( LogInitialPath + "Error.log", cMessage )

   /*
      SAFE DISPLAY & TERMINATION:
      This call blocks inside C using native GTK signals and kills
      the application instantly when the user clicks 'Close'.
   */
   hwg_NativeErrorShow( cMessage )

   RETURN .F.

FUNCTION hwg_ErrMsg( oError )
   LOCAL cMessage
   cMessage := iif( oError:severity > ES_WARNING, "Error", "Warning" ) + " "
   IF ISCHARACTER( oError:subsystem )
      cMessage += oError:subsystem()
   ELSE
      cMessage += "???"
   ENDIF
   IF ISNUMBER( oError:subCode )
      cMessage += "/" + LTrim( Str( oError:subCode ) )
   ELSE
      cMessage += "/???"
   ENDIF
   IF ISCHARACTER( oError:description )
      cMessage += "  " + oError:description
   ENDIF
   DO CASE
   CASE !Empty( oError:filename )
      cMessage += ": " + oError:filename
   CASE !Empty( oError:operation )
      cMessage += ": " + oError:operation
   ENDCASE
   RETURN cMessage

FUNCTION hwg_WriteLog( cText, fname )
   LOCAL nHand
   fname := LogInitialPath + iif( fname == Nil, "a.log", fname )
   IF !File( fname )
      nHand := FCreate( fname )
   ELSE
      nHand := FOpen( fname, 1 )
   ENDIF
   FSeek( nHand, 0, 2 )
   FWrite( nHand, cText + Chr( 10 ) )
   FClose( nHand )
   RETURN nil

#pragma BEGINDUMP
/*
   FIXED: Including guilib.h guarantees that the global GCC diagnostics
   and the incomp_pointer.h protections apply to this module as well.
*/
#include "guilib.h"
#include "hbapi.h"
#include <unistd.h> /* Required for _exit() */

#ifdef HB_DEPRECATED
   #undef HB_DEPRECATED
#endif
#include <gtk/gtk.h>

/*
 * GTK4 callback: fired when the dialog receives a close request, which
 * happens when any GtkMessageDialog button is pressed OR when the user
 * clicks the window's X button.
 *
 * GTK4 removed GtkDialog::response — close-request is the new entry
 * point for "the user dismissed this dialog".
 *
 * _exit(0) bypasses atexit handlers and the Harbour engine, exactly as
 * the original implementation did.  It is marked noreturn so GCC does
 * not warn about the missing return.
 */
static gboolean native_kill_callback( GtkWindow *window, gpointer data )
{
   (void)window;
   (void)data;

   /* Absolute hardware-level exit bypasses all pending GTK/Harbour events */
   _exit( 0 );

   return FALSE; /* unreachable */
}

HB_FUNC( HWG_NATIVEERRORSHOW )
{
   const char *acMessage = hb_parc( 1 );

   if( acMessage )
   {
      GtkWidget *pDialog;

      /*
       * GTK4: GTK_DIALOG_DESTROY_WITH_PARENT is deprecated (4.10); the
       * destroy-with-parent behaviour is now the default.  We only pass
       * GTK_DIALOG_MODAL.
       */
      pDialog = gtk_message_dialog_new( NULL,
                                        GTK_DIALOG_MODAL,
                                        GTK_MESSAGE_ERROR,
                                        GTK_BUTTONS_CLOSE,
                                        "%s", acMessage );

      gtk_window_set_title( GTK_WINDOW( pDialog ),
                            "HwGUI - Critical Engine Exception" );

      /*
       * SUPREME BLINDAGE: connect close-request (GTK4 replacement for
       * the removed "response" signal) to our killer callback.  The
       * exact millisecond any button or the window close icon is
       * pressed, the application terminates inside C, avoiding the
       * broken Harbour engine loop.
       */
      g_signal_connect( pDialog, "close-request",
                        G_CALLBACK( native_kill_callback ), NULL );

      /*
       * GTK4: gtk_widget_show_all() was removed.  gtk_window_present()
       * handles both showing the dialog and giving it focus.
       */
      gtk_window_present( GTK_WINDOW( pDialog ) );

      /*
       * Run a clean, isolated iteration loop to hold the window visible.
       * GTK4: gtk_main_iteration() was removed; g_main_context_iteration()
       * is the equivalent primitive.
       *
       * The loop normally never terminates on its own: the close-request
       * handler calls _exit(0) as soon as the user dismisses the dialog.
       */
      while( gtk_widget_get_visible( pDialog ) )
      {
         g_main_context_iteration( NULL, TRUE );
      }
   }
}

#pragma ENDDUMP
