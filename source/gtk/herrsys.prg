/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Windows errorsys replacement
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
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

#include "hbapi.h"
#include <unistd.h> /* Required for _exit() */

#ifdef HB_DEPRECATED
   #undef HB_DEPRECATED
#endif
#include <gtk/gtk.h>

/* Callback native function that kills the process instantly at kernel level */
static void native_kill_callback(GtkWidget *widget, gint response_id, gpointer data)
{
    (void)widget;
    (void)response_id;
    (void)data;

    /* Absolute hardware-level exit bypasses all pending GTK/Harbour events */
    _exit(0);
}

HB_FUNC( HWG_NATIVEERRORSHOW )
{
    const char * acMessage = hb_parc(1);

    if( acMessage )
    {
        GtkWidget *pDialog;

        pDialog = gtk_message_dialog_new( NULL,
                                          GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
                                          GTK_MESSAGE_ERROR,
                                          GTK_BUTTONS_CLOSE,
                                          "%s", acMessage );

        gtk_window_set_title( GTK_WINDOW(pDialog), "HwGUI - Critical Engine Exception" );

        /*
           SUPREME BLINDAGE: Connects the "response" signal directly to our killer callback.
           The exact millisecond any button or the window close icon is pressed,
           the application terminates inside C, avoiding the broken Harbour engine loop.
        */
        g_signal_connect( pDialog, "response", G_CALLBACK(native_kill_callback), NULL );

        /* Show the widget visually without running the blocking gtk_dialog_run loop */
        gtk_widget_show_all( pDialog );

        /* Run a clean, isolated iteration loop to hold the window visible */
        while ( gtk_widget_get_visible(pDialog) )
        {
            gtk_main_iteration();
        }
    }
}

#pragma ENDDUMP
