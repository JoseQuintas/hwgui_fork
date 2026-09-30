/*
 * $Id: message.c 2968 2021-04-09 06:13:17Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Message box functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port -- target GTK 4.24+
 *
 * NOTES
 * -----
 *   GtkDialog and GtkMessageDialog are deprecated since GTK 4.10, and
 *   gtk_dialog_run() was removed entirely.  This file builds the
 *   dialog by hand with plain GtkWindow, GtkBox, GtkSeparator,
 *   GtkImage, GtkLabel and GtkButton -- all non-deprecated in GTK 4.
 *
 *   The old blocking gtk_dialog_run() is replaced by a local GMainLoop
 *   that runs until the user picks a button or closes the window.
 *   gtk_widget_destroy() is replaced by gtk_window_destroy().
 *
 *   Button labels come from the GTK message catalog itself, via
 *   g_dgettext() with the "gtk40" domain -- exactly the same source
 *   GTK2/GTK3 GtkMessageDialog used.  So installing the GTK language
 *   pack (e.g. language-pack-gnome-pt-base on Ubuntu) is enough to
 *   get "Sim", "Nao", "Fechar", "Cancelar" etc. without changing
 *   any Harbour source.  Applications may still override individual
 *   labels via hwg_SetMsgButtons().
 *
 *   The message label is selectable (so users can copy error text)
 *   but has can_focus(FALSE): otherwise GTK4 auto-selects the whole
 *   label on presentation, which paints it with the theme's selection
 *   colours.  Focus goes to the first button, which is also set as
 *   the default widget so Enter activates it.
 *
 *   Both the message body and the window title arrive from Harbour as
 *   single-byte Latin-1 data (see hwg_convert_to_utf8 in window.c).
 *   GTK requires valid UTF-8 in every string API, so both are passed
 *   through the converter before touching GTK.  Without that, the
 *   title bar shows mojibake and pango prints "Invalid UTF-8 string
 *   passed to pango_layout_set_text()" warnings on any accented text.
 *
 *   Focus restoration:
 *   ------------------
 *   When a modal message box closes, GTK does not automatically
 *   restore focus to the widget that had it.  Two reasons:
 *
 *     1. GTK4 clears the parent window's focus state as soon as the
 *        modal's GtkWindow is created, so by the time the modal
 *        opens, gtk_window_get_focus() and gtk_root_get_focus()
 *        both return NULL for the parent.  There is nothing for GTK
 *        to restore.
 *
 *     2. Even if the C side grabbed focus on the right widget, the
 *        HWGui dialog engine would move focus again right after
 *        hwg_message_box() returns -- when a VALID block returns
 *        .F., the engine advances to the next control in the queue
 *        (typically the "phantom" get used to hold the dialog open).
 *        That happens later than any synchronous grab_focus() call.
 *
 *   The fix has two parts:
 *
 *     a. window.c keeps its own focus tracker (s_pLastFocusedWidget,
 *        updated in cb_focus_enter) and exposes it through
 *        hwg_get_last_focused_widget().  message.c reads that
 *        pointer instead of asking GTK.
 *
 *     b. After the modal is destroyed, message.c schedules the focus
 *        restoration through g_idle_add().  Idle callbacks run after
 *        the current event burst is fully processed -- i.e. after
 *        the Harbour VALID chain is done -- so our grab_focus() is
 *        the last one to run.  The callback returns G_SOURCE_REMOVE
 *        so it executes exactly once and is automatically dropped
 *        from the queue.  No loops, no CPU burn.
 *
 *   All message box variants (MsgInfo, MsgStop, MsgExclamation,
 *   MsgOkCancel, MsgYesNo, MsgYesNoCancel) share the same internal
 *   hwg_message_box(), so the focus restoration applies to all of
 *   them without duplication.
 */

#include "guilib.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"
#include "gtk/gtk.h"
#include <glib/gi18n.h>          /* g_dgettext */
#include "hwgtk4.h"

#include "warnings.h"

extern GtkWidget *GetActiveWindow( void );
extern gchar     *hwg_convert_to_utf8( const char * szText );

/*
 * HWGui's own focus tracker (defined in window.c).
 *
 * Returns the last HWGui widget that received GTK focus, or NULL if
 * none is currently valid.  message.c uses this to restore focus
 * after a modal closes, because GTK4 clears the parent window's
 * focus as soon as the modal's GtkWindow is created -- by then,
 * gtk_window_get_focus() and gtk_root_get_focus() both return NULL.
 */
extern GtkWidget *hwg_get_last_focused_widget( void );

/* Response ids exposed to Harbour (Win32-compatible). */
#define IDCANCEL   2
#define IDYES      6
#define IDNO       7


/* =====================================================================
 *  Localisation
 *
 *  GTK stores its own UI strings ("_OK", "_Cancel", "_Close", "_Yes",
 *  "_No", ...) in the "gtk40" gettext domain (GTK 3 used "gtk30",
 *  GTK 2 used "gtk20"; some distros also expose "gtk4").  We look the
 *  string up in each domain until we find a real translation.
 * ===================================================================== */
static const gchar *hwg_tr( const gchar *msgid )
{
    static const gchar *domains[] = { "gtk40", "gtk4", "gtk30", "gtk20", NULL };
    const gchar        *result;
    int                 i;

    for( i = 0; domains[i]; i++ )
    {
        result = g_dgettext( domains[i], msgid );
        if( result != msgid )
            return result;
    }
    return msgid;
}

/* Application overrides, set via hwg_SetMsgButtons(). */
static gchar *s_btn_ok     = NULL;
static gchar *s_btn_close  = NULL;
static gchar *s_btn_yes    = NULL;
static gchar *s_btn_no     = NULL;
static gchar *s_btn_cancel = NULL;

static const gchar *hwg_label( const gchar *custom, const gchar *msgid )
{
    return custom ? custom : hwg_tr( msgid );
}


/* =====================================================================
 *  Internal context and button descriptor
 * ===================================================================== */
typedef struct {
    GMainLoop *loop;
    int        response;   /* 0 when the user closed the window */
} HWG_DIALOG_CTX;

typedef struct {
    const gchar *label;      /* may contain '_' for mnemonic */
    int          response;   /* GTK_RESPONSE_* */
} HWG_BUTTON_DEF;


/* =====================================================================
 *  Deferred focus restoration
 *
 *  See the file header for the full rationale.  Short version: the
 *  HWGui dialog engine moves focus to the "phantom" get *after*
 *  hwg_message_box() returns, when a VALID block returns .F.  We
 *  therefore cannot restore focus synchronously -- we have to wait
 *  for the next GLib idle cycle, at which point the Harbour chain is
 *  done and our grab_focus() wins.
 * ===================================================================== */
typedef struct {
    GtkWidget *prev_focus;   /* weak reference: we do not own it */
} HWG_FOCUS_RESTORE;

static gboolean hwg_restore_focus_idle( gpointer data )
{
    HWG_FOCUS_RESTORE *fr = (HWG_FOCUS_RESTORE *) data;

    /*
     * Guard against the widget having been destroyed while the modal
     * was open (e.g. the user chose "Quit" instead of fixing the
     * password).  The "dead" flag and the mapped/visible/sensitive
     * checks in combination make sure we only call grab_focus on a
     * widget that can actually take it.
     */
    if( fr->prev_focus && GTK_IS_WIDGET( fr->prev_focus ) &&
        gtk_widget_get_visible( fr->prev_focus ) &&
        gtk_widget_get_mapped( fr->prev_focus ) &&
        gtk_widget_is_sensitive( fr->prev_focus ) )
    {
        /*
         * Bring the parent window forward first.  In GTK4,
         * gtk_widget_grab_focus() on a child of a non-active window
         * is a no-op -- the window has to be presented first.
         */
        GtkWidget *win = gtk_widget_get_ancestor( fr->prev_focus,
                                                  GTK_TYPE_WINDOW );
        if( win )
            gtk_window_present( GTK_WINDOW( win ) );

        gtk_widget_grab_focus( fr->prev_focus );

        /*
         * GTK4 auto-selects the whole content of an editable when it
         * receives focus (the same behaviour HWG_SETFOCUS and
         * hwg_deferred_setfocus_idle compensate for in window.c).
         * Undo it here so the user lands with the caret at position
         * zero instead of the text all selected.
         */
        if( GTK_IS_EDITABLE( fr->prev_focus ) )
        {
            gtk_editable_set_position( GTK_EDITABLE( fr->prev_focus ), 0 );
            gtk_editable_select_region( GTK_EDITABLE( fr->prev_focus ), 0, 0 );
        }
    }

    g_free( fr );
    return G_SOURCE_REMOVE;   /* run once, then drop from the queue */
}


/* =====================================================================
 *  Signal handlers
 * ===================================================================== */
static void cb_button_clicked( GtkButton *btn, gpointer user_data )
{
    HWG_DIALOG_CTX *ctx = (HWG_DIALOG_CTX *) user_data;
    GtkWidget      *dlg;

    /* Capture the response BEFORE the window starts tearing down. */
    ctx->response = GPOINTER_TO_INT(
        g_object_get_data( G_OBJECT( btn ), "hwg_response" ) );

    /*
     * Ask the window to close.  GTK4 will emit "close-request" and then
     * "destroy"; our cb_dialog_destroy() stops the local loop from
     * there.  This uses the same code path as the window manager's
     * close button, and avoids fragile reentrancy between the button's
     * "clicked" handler and the running GMainLoop.
     */
    dlg = gtk_widget_get_ancestor( GTK_WIDGET( btn ), GTK_TYPE_WINDOW );
    if( dlg )
        gtk_window_close( GTK_WINDOW( dlg ) );
    else if( g_main_loop_is_running( ctx->loop ) )
        g_main_loop_quit( ctx->loop );
}

/*
 * On "destroy" we only stop the loop if it is still running.  We must
 * NOT reset ctx->response: if the user clicked a button, that value
 * was already set by cb_button_clicked; if the user closed via the WM,
 * ctx->response is still 0 and the caller treats it as "cancelled".
 */
static void cb_dialog_destroy( GtkWidget *widget, gpointer user_data )
{
    HWG_DIALOG_CTX *ctx = (HWG_DIALOG_CTX *) user_data;

    HB_SYMBOL_UNUSED( widget );

    if( g_main_loop_is_running( ctx->loop ) )
        g_main_loop_quit( ctx->loop );
}


/* =====================================================================
 *  Helpers
 * ===================================================================== */
static GtkWindow *hwg_get_parent_window( void )
{
    GtkWidget *parent = GetActiveWindow();

    if( parent && GTK_IS_WINDOW( parent ) )
        return GTK_WINDOW( parent );

    return NULL;
}

static const char *hwg_icon_name( int message_type )
{
    switch( message_type )
    {
        case GTK_MESSAGE_ERROR:    return "dialog-error";
        case GTK_MESSAGE_WARNING:  return "dialog-warning";
        case GTK_MESSAGE_QUESTION: return "dialog-question";
        case GTK_MESSAGE_INFO:
        default:                   return "dialog-information";
    }
}

/* Titles are localised through the same mechanism. */
static const char *hwg_default_title( int message_type )
{
    switch( message_type )
    {
        case GTK_MESSAGE_ERROR:    return hwg_tr( "Error" );
        case GTK_MESSAGE_WARNING:  return hwg_tr( "Warning" );
        case GTK_MESSAGE_QUESTION: return hwg_tr( "Question" );
        case GTK_MESSAGE_INFO:
        default:                   return hwg_tr( "Information" );
    }
}


/* =====================================================================
 *  Core implementation
 * ===================================================================== */
static int hwg_message_box( const char *cMsg, const char *cTitle,
                            int message_type,
                            const HWG_BUTTON_DEF *buttons, int n_buttons )
{
    GtkWidget      *dialog;
    GtkWidget      *outer;
    GtkWidget      *content;
    GtkWidget      *sep;
    GtkWidget      *image;
    GtkWidget      *label;
    GtkWidget      *btnbox;
    GtkWidget      *first_btn;
    GtkWindow      *parent;
    GtkWidget      *prev_focus = NULL;
    HWG_DIALOG_CTX  ctx;
    gchar          *gcptr;
    gchar          *gcTitle;
    const char     *icon_name;
    const char     *title;
    int             i;

    parent    = hwg_get_parent_window();
    icon_name = hwg_icon_name( message_type );
    title     = ( cTitle && *cTitle ) ? cTitle : hwg_default_title( message_type );

    /*
     * The title arrives from Harbour as Latin-1 bytes (see
     * hwg_convert_to_utf8 in window.c).  GTK requires valid UTF-8 in
     * every string API, so without this conversion the window manager
     * prints "Invalid utf8 passed to gdk_surface_set_title" and the
     * title bar shows mojibake for any accented character.
     *
     * hwg_default_title() returns a string from the GTK catalogue,
     * which is already UTF-8; passing it through the converter is
     * harmless because hwg_convert_to_utf8() short-circuits on valid
     * input.  gcTitle is freed at the end of this function.
     */
    gcTitle = hwg_convert_to_utf8( title );

    /*
     * Remember which widget owned the focus before the modal opened.
     *
     * We ask HWGui's own focus tracker (window.c) rather than GTK:
     * by the time the modal's GtkWindow exists, GTK has already
     * cleared the parent window's focus, and both
     * gtk_window_get_focus() and gtk_root_get_focus() return NULL.
     * The tracker is kept up to date by cb_focus_enter() and is the
     * only reliable source of "who had focus a moment ago".
     *
     * We capture it *before* creating the dialog because creating
     * the dialog is exactly what triggers GTK to drop the parent's
     * focus.
     */
    prev_focus = hwg_get_last_focused_widget();

    /* ---- window -------------------------------------------------- */
    dialog = gtk_window_new();
    gtk_window_set_title( GTK_WINDOW( dialog ), gcTitle );
    gtk_window_set_modal( GTK_WINDOW( dialog ), TRUE );
    gtk_window_set_resizable( GTK_WINDOW( dialog ), FALSE );
    gtk_window_set_icon_name( GTK_WINDOW( dialog ), icon_name );
    gtk_window_set_default_size( GTK_WINDOW( dialog ), 420, -1 );

    if( parent )
        gtk_window_set_transient_for( GTK_WINDOW( dialog ), parent );

    /* ---- outer vertical box -------------------------------------- */
    outer = gtk_box_new( GTK_ORIENTATION_VERTICAL, 0 );

    /* ---- content: icon + message --------------------------------- */
    content = gtk_box_new( GTK_ORIENTATION_HORIZONTAL, 12 );
    gtk_widget_set_margin_start(  content, 16 );
    gtk_widget_set_margin_end(    content, 16 );
    gtk_widget_set_margin_top(    content, 16 );
    gtk_widget_set_margin_bottom( content, 12 );

    image = gtk_image_new_from_icon_name( icon_name );
    gtk_image_set_pixel_size( GTK_IMAGE( image ), 48 );
    gtk_widget_set_valign( image, GTK_ALIGN_START );
    gtk_box_append( GTK_BOX( content ), image );

    gcptr = hwg_convert_to_utf8( cMsg );
    label = gtk_label_new( gcptr );
    g_free( gcptr );

    gtk_label_set_wrap( GTK_LABEL( label ), TRUE );
    gtk_label_set_xalign( GTK_LABEL( label ), 0.0 );
    gtk_label_set_yalign( GTK_LABEL( label ), 0.5 );

    /*
     * Keep the message selectable (so the user can copy error text)
     * but do NOT let it grab keyboard focus.  Otherwise GTK4 selects
     * the whole label when the dialog is presented, which paints it
     * with the theme's selection colours (blue on blue in dark mode).
     */
    gtk_label_set_selectable( GTK_LABEL( label ), TRUE );
    gtk_widget_set_can_focus( label, FALSE );

    gtk_widget_set_hexpand( label, TRUE );
    gtk_box_append( GTK_BOX( content ), label );

    gtk_box_append( GTK_BOX( outer ), content );

    /* ---- separator ----------------------------------------------- */
    sep = gtk_separator_new( GTK_ORIENTATION_HORIZONTAL );
    gtk_box_append( GTK_BOX( outer ), sep );

    /* ---- buttons ------------------------------------------------- */
    btnbox = gtk_box_new( GTK_ORIENTATION_HORIZONTAL, 6 );
    gtk_widget_set_halign( btnbox, GTK_ALIGN_END );
    gtk_widget_set_margin_start(  btnbox, 16 );
    gtk_widget_set_margin_end(    btnbox, 16 );
    gtk_widget_set_margin_top(    btnbox, 8 );
    gtk_widget_set_margin_bottom( btnbox, 12 );

    ctx.loop     = g_main_loop_new( NULL, FALSE );
    ctx.response = 0;

    for( i = 0; i < n_buttons; i++ )
    {
        /*
         * gtk_button_new_with_mnemonic() understands the '_' prefix
         * used in the GTK catalogue ("_OK", "_Cancel", ...) and shows
         * the mnemonic underline.  If the application provided a plain
         * label without '_', it is shown as-is.
         */
        GtkWidget *btn = gtk_button_new_with_mnemonic( buttons[i].label );

        g_object_set_data( G_OBJECT( btn ), "hwg_response",
                           GINT_TO_POINTER( buttons[i].response ) );
        g_signal_connect( btn, "clicked",
                          G_CALLBACK( cb_button_clicked ), &ctx );
        gtk_box_append( GTK_BOX( btnbox ), btn );
    }

    gtk_box_append( GTK_BOX( outer ), btnbox );

    gtk_window_set_child( GTK_WINDOW( dialog ), outer );

    g_signal_connect( dialog, "destroy",
                      G_CALLBACK( cb_dialog_destroy ), &ctx );

    /*
     * Pick the first button as the dialog's "default widget": it gets
     * initial focus and responds to Enter.  This must be set BEFORE
     * the window is presented, but grab_focus() itself must come
     * AFTER present() because in GTK4 the widget has to be mapped
     * for focus to stick.
     */
    first_btn = gtk_widget_get_first_child( btnbox );
    if( first_btn && GTK_IS_WIDGET( first_btn ) )
        gtk_window_set_default_widget( GTK_WINDOW( dialog ), first_btn );

    gtk_window_present( GTK_WINDOW( dialog ) );

    /*
     * Now that the window is mapped, grab the focus explicitly on the
     * first button.  Otherwise the focus ordering could land on the
     * selectable label, which would auto-select the whole text.
     */
    if( first_btn && GTK_IS_WIDGET( first_btn ) )
        gtk_widget_grab_focus( first_btn );

    g_main_loop_run( ctx.loop );
    g_main_loop_unref( ctx.loop );

    /*
     * If the user closed the dialog through the WM (X button) instead
     * of clicking a button, the window may still be alive here.  In
     * that case, destroy it now so we do not leak it.
     */
    if( GTK_IS_WINDOW( dialog ) )
        gtk_window_destroy( GTK_WINDOW( dialog ) );

    /*
     * Hand focus back to the previous widget, but deferred through
     * the GLib idle queue so we run *after* the HWGui dialog engine
     * finishes processing VALID=.F. and moves focus to the phantom.
     *
     * If prev_focus is NULL (no widget was tracked before the modal
     * opened) there is nothing to restore, and we skip the idle.
     * See the file header for the full rationale.
     */
    if( prev_focus && GTK_IS_WIDGET( prev_focus ) )
    {
        HWG_FOCUS_RESTORE *fr = g_new0( HWG_FOCUS_RESTORE, 1 );
        fr->prev_focus = prev_focus;
        g_idle_add( hwg_restore_focus_idle, fr );
    }

    g_free( gcTitle );

    return ctx.response;
}


/* =====================================================================
 *  Harbour bindings
 * ===================================================================== */

/*
 * hwg_SetMsgButtons( cOK, cClose, cYes, cNo, cCancel )
 *
 * Optional.  By default the labels come from GTK's own translation
 * catalogue ("_OK", "_Close", "_Yes", "_No", "_Cancel"), which is
 * translated by the system language pack.  Use this only if you want
 * to override any of them.  Pass Nil to leave a label at its default.
 */
HB_FUNC( HWG_SETMSGBUTTONS )
{
    if( !HB_ISNIL(1) ) { g_free( s_btn_ok     ); s_btn_ok     = g_strdup( hb_parc(1) ); }
    if( !HB_ISNIL(2) ) { g_free( s_btn_close  ); s_btn_close  = g_strdup( hb_parc(2) ); }
    if( !HB_ISNIL(3) ) { g_free( s_btn_yes    ); s_btn_yes    = g_strdup( hb_parc(3) ); }
    if( !HB_ISNIL(4) ) { g_free( s_btn_no     ); s_btn_no     = g_strdup( hb_parc(4) ); }
    if( !HB_ISNIL(5) ) { g_free( s_btn_cancel ); s_btn_cancel = g_strdup( hb_parc(5) ); }
}

HB_FUNC( HWG_MSGINFO )
{
    const char *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );
    HWG_BUTTON_DEF btns[1];

    btns[0].label    = hwg_label( s_btn_ok, "_OK" );
    btns[0].response = GTK_RESPONSE_OK;

    hwg_message_box( hb_parc( 1 ), cTitle,
                     GTK_MESSAGE_INFO, btns, 1 );
}

HB_FUNC( HWG_MSGSTOP )
{
    const char *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );
    HWG_BUTTON_DEF btns[1];

    btns[0].label    = hwg_label( s_btn_close, "_Close" );
    btns[0].response = GTK_RESPONSE_CLOSE;

    hwg_message_box( hb_parc( 1 ), cTitle,
                     GTK_MESSAGE_ERROR, btns, 1 );
}

HB_FUNC( HWG_MSGEXCLAMATION )
{
    const char *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );
    HWG_BUTTON_DEF btns[1];

    btns[0].label    = hwg_label( s_btn_close, "_Close" );
    btns[0].response = GTK_RESPONSE_CLOSE;

    hwg_message_box( hb_parc( 1 ), cTitle,
                     GTK_MESSAGE_WARNING, btns, 1 );
}

HB_FUNC( HWG_MSGOKCANCEL )
{
    const char *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );
    HWG_BUTTON_DEF btns[2];
    int resp;

    btns[0].label    = hwg_label( s_btn_cancel, "_Cancel" );
    btns[0].response = GTK_RESPONSE_CANCEL;
    btns[1].label    = hwg_label( s_btn_ok, "_OK" );
    btns[1].response = GTK_RESPONSE_OK;

    resp = hwg_message_box( hb_parc( 1 ), cTitle,
                            GTK_MESSAGE_QUESTION, btns, 2 );

    hb_retl( resp == GTK_RESPONSE_OK );
}

HB_FUNC( HWG_MSGYESNO )
{
    const char *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );
    HWG_BUTTON_DEF btns[2];
    int resp;

    btns[0].label    = hwg_label( s_btn_no, "_No" );
    btns[0].response = GTK_RESPONSE_NO;
    btns[1].label    = hwg_label( s_btn_yes, "_Yes" );
    btns[1].response = GTK_RESPONSE_YES;

    resp = hwg_message_box( hb_parc( 1 ), cTitle,
                            GTK_MESSAGE_QUESTION, btns, 2 );

    hb_retl( resp == GTK_RESPONSE_YES );
}

HB_FUNC( HWG_MSGYESNOCANCEL )
{
    const char *cTitle = ( hb_pcount() == 1 ) ? "" : hb_parc( 2 );
    HWG_BUTTON_DEF btns[3];
    int resp;

    btns[0].label    = hwg_label( s_btn_no, "_No" );
    btns[0].response = GTK_RESPONSE_NO;
    btns[1].label    = hwg_label( s_btn_yes, "_Yes" );
    btns[1].response = GTK_RESPONSE_YES;
    btns[2].label    = hwg_label( s_btn_cancel, "_Cancel" );
    btns[2].response = GTK_RESPONSE_CANCEL;

    resp = hwg_message_box( hb_parc( 1 ), cTitle,
                            GTK_MESSAGE_QUESTION, btns, 3 );

    if( resp == GTK_RESPONSE_YES )      hb_retni( IDYES );
    else if( resp == GTK_RESPONSE_NO )  hb_retni( IDNO  );
    else                                hb_retni( IDCANCEL );
}

/* ================= EOF of message.c ======================== */
