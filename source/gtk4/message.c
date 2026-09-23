/*
 * $Id: message.c 2968 2021-04-09 06:13:17Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Message box functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTES
 * -----
 *   * gtk_dialog_run() was removed in GTK 4.10.  To preserve the
 *     blocking semantics of HWG_MSGINFO / HWG_MSGYESNO / etc., we
 *     present the dialog, then run a local GMainLoop until the
 *     "response" signal fires.  The response id is captured and
 *     returned to Harbour.
 *
 *   * gtk_window_set_position(GTK_WIN_POS_CENTER) was removed:
 *     positioning is the compositor's job in GTK4.
 *
 *   * GTK_DIALOG_DESTROY_WITH_PARENT was deprecated in 4.10;
 *     destroy-with-parent behaviour is now the default.
 *
 *   * gtk_widget_destroy() was removed: use gtk_window_destroy().
 *
 *   * GtkDialog itself is deprecated since 4.10 in favour of
 *     GtkAlertDialog, but still functional.  The code below works on
 *     GTK 4.0 through 4.14 without using the new-only GtkAlertDialog.
 */

#include "guilib.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"
#include "gtk/gtk.h"
#include "hwgtk4.h"

/* Avoid warnings from GCC */
#include "warnings.h"

extern GtkWidget *GetActiveWindow( void );

/* =====================================================================
 *  Synchronous bridge over GtkMessageDialog (GTK4)
 *
 *  GtkMessageDialog::response still exists in GTK4 (deprecated in 4.10
 *  but functional).  We use it to break out of a local main loop with
 *  the user's choice.
 * ===================================================================== */
typedef struct {
    GMainLoop *loop;
    gint       response;
} HWG_DIALOG_CTX;

static void hwg_dialog_on_response( GtkDialog *dialog, gint response_id, gpointer user_data )
{
    HWG_DIALOG_CTX *ctx = (HWG_DIALOG_CTX *) user_data;

    HB_SYMBOL_UNUSED( dialog );

    ctx->response = response_id;
    g_main_loop_quit( ctx->loop );
}

static GtkWindow *hwg_get_parent_window( void )
{
    GtkWidget *parent = GetActiveWindow();

    if( parent && GTK_IS_WINDOW( parent ) )
        return GTK_WINDOW( parent );

    return NULL;
}

static int MessageBox( const char *cMsg, const char *cTitle,
                       int message_type, int button_type )
{
    GtkWidget      *dialog;
    HWG_DIALOG_CTX  ctx;
    gchar          *gcptr;

    gcptr  = hwg_convert_to_utf8( cMsg );
    dialog = gtk_message_dialog_new( hwg_get_parent_window(),
                                     GTK_DIALOG_MODAL,
                                     message_type,
                                     button_type, "%s",
                                     gcptr );
    g_free( gcptr );

    if( cTitle && *cTitle )
    {
        gcptr = hwg_convert_to_utf8( cTitle );
        gtk_window_set_title( GTK_WINDOW( dialog ), gcptr );
        g_free( gcptr );
    }

    gtk_window_set_resizable( GTK_WINDOW( dialog ), TRUE );

    /* Block until the user dismisses the dialog. */
    ctx.loop     = g_main_loop_new( NULL, FALSE );
    ctx.response = GTK_RESPONSE_NONE;

    g_signal_connect( dialog, "response",
                      G_CALLBACK( hwg_dialog_on_response ), &ctx );

    gtk_window_present( GTK_WINDOW( dialog ) );

    g_main_loop_run( ctx.loop );
    g_main_loop_unref( ctx.loop );

    /* Destroy the dialog now that the loop has stopped. */
    gtk_window_destroy( GTK_WINDOW( dialog ) );

    return ctx.response;
}

HB_FUNC( HWG_MSGINFO )
{
    const char *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );

    MessageBox( hb_parc( 1 ), cTitle, GTK_MESSAGE_INFO, GTK_BUTTONS_OK );
}

HB_FUNC( HWG_MSGSTOP )
{
    const char *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );

    MessageBox( hb_parc( 1 ), cTitle, GTK_MESSAGE_ERROR, GTK_BUTTONS_CLOSE );
}

HB_FUNC( HWG_MSGOKCANCEL )
{
    const char *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );

    hb_retl( MessageBox( hb_parc( 1 ), cTitle,
                         GTK_MESSAGE_QUESTION,
                         GTK_BUTTONS_OK_CANCEL ) == GTK_RESPONSE_OK );
}

HB_FUNC( HWG_MSGYESNO )
{
    const char *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );

    hb_retl( MessageBox( hb_parc( 1 ), cTitle,
                         GTK_MESSAGE_QUESTION,
                         GTK_BUTTONS_YES_NO ) == GTK_RESPONSE_YES );
}

HB_FUNC( HWG_MSGEXCLAMATION )
{
    const char *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );

    MessageBox( hb_parc( 1 ), cTitle, GTK_MESSAGE_WARNING, GTK_BUTTONS_CLOSE );
}

#define IDCANCEL            0
#define IDYES               1
#define IDNO                2

HB_FUNC( HWG_MSGYESNOCANCEL )
{
    const char    *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );
    GtkWidget     *dialog;
    HWG_DIALOG_CTX ctx;
    gchar         *gcptr;
    int            result;

    gcptr  = hwg_convert_to_utf8( hb_parc( 1 ) );
    dialog = gtk_message_dialog_new( hwg_get_parent_window(),
                                     GTK_DIALOG_MODAL,
                                     GTK_MESSAGE_QUESTION,
                                     GTK_BUTTONS_NONE, "%s",
                                     gcptr );
    g_free( gcptr );

    if( cTitle && *cTitle )
    {
        gcptr = hwg_convert_to_utf8( cTitle );
        gtk_window_set_title( GTK_WINDOW( dialog ), gcptr );
        g_free( gcptr );
    }

    /* gtk_dialog_add_button() still exists in GTK4 (deprecated 4.10). */
    gtk_dialog_add_button( GTK_DIALOG( dialog ), "Yes",    GTK_RESPONSE_YES );
    gtk_dialog_add_button( GTK_DIALOG( dialog ), "No",     GTK_RESPONSE_NO );
    gtk_dialog_add_button( GTK_DIALOG( dialog ), "Cancel", GTK_RESPONSE_CANCEL );

    gtk_window_set_resizable( GTK_WINDOW( dialog ), TRUE );

    /* Block until the user dismisses the dialog. */
    ctx.loop     = g_main_loop_new( NULL, FALSE );
    ctx.response = GTK_RESPONSE_NONE;

    g_signal_connect( dialog, "response",
                      G_CALLBACK( hwg_dialog_on_response ), &ctx );

    gtk_window_present( GTK_WINDOW( dialog ) );

    g_main_loop_run( ctx.loop );
    g_main_loop_unref( ctx.loop );

    result = ctx.response;

    gtk_window_destroy( GTK_WINDOW( dialog ) );

    hb_retni( (result == GTK_RESPONSE_YES) ? IDYES :
    (result == GTK_RESPONSE_NO)  ? IDNO  : IDCANCEL );
}

/* ================= EOF of message.c ======================== */
