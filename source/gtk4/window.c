/*
 * $Id: window.c 3853 2026-08-18 00:17:27Z itamarlins $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level windows functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port -- consolidated version
 *
 * ARCHITECTURAL NOTES (highlights):
 *  13. Key controller CAPTURE phase.
 *  19. Focus advance walks siblings of a GtkFixed parent manually.
 *  20. HWG_SETMAXLENGTH exposes max length from the Harbour side.
 *  21. HWG_SETFOCUS defers grab_focus when the widget is unmapped.
 *  22. cb_close_request quits the main loop only for the main window.
 *  23. HWG_DESTROYWINDOW quits the main loop only for the main window
 *      and clears all Harbour object references BEFORE destroy.
 *  24. Log writer installed before gtk_init().
 *  25. hwg_clear_objects_recursive disconnects the Harbour objects.
 *  26. cb_close_request and HWG_ACTIVATEDIALOG check the toplevel list.
 *  27. "hwg_dead" flag set right before destruction.
 *  28. hwg_convert_to_utf8 defensive: never returns NULL.
 *  29. HWG_GTK_INIT forces LC_CTYPE to UTF-8.
 *  30. Mouse wheel -- native GTK4 path via cb_scroll (non-static).
 *  31. cb_close_request return value inversion.
 *  32. HWG_GTK_EXIT refuses to kill the app while any toplevel lives.
 *  33. cb_button_pressed grabs focus on click; cb_button_released
 *      deliberately does NOT (that would steal focus from the HGet
 *      that just opened for editing).
 *  34. HWG_DESTROYWINDOW clears the widget's "obj" BEFORE unparenting.
 *  35. Background image support (GtkOverlay + GtkPicture).
 *  36. Window icon via gdk_toplevel_set_icon_list(), applied from the
 *      "realize" signal because GtkWindow is not GdkToplevel; the
 *      surface only exists after realize.
 *  37. hwg_deferred_setfocus_idle requires an attached root -- a
 *      destroyed-but-not-yet-finalized GtkWidget would otherwise pass
 *      GTK_IS_WIDGET and crash inside gtk_widget_grab_focus.
 *  38. cb_window_destroyed marks the window dead on ANY destruction
 *      path, including GTK4's auto-destroy of children.  Without it,
 *      HWG_SETFOCUS could present a corpse.
 */

#include "guilib.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"
#include <locale.h>

#include <gtk/gtk.h>
#include "hbapi.h"
#include "hbapilng.h"

#include "gdk/gdkkeysyms.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#else
#include "hbapicls.h"
#endif
#include "hwgtk4.h"

#include "warnings.h"

extern int hb_setGetConfirm( void );

#define WM_MOVE                           3
#define WM_SIZE                           5
#define WM_SETFOCUS                       7
#define WM_KILLFOCUS                      8
#define WM_PAINT                         15
#define WM_KEYDOWN                      256
#define WM_KEYUP                        257
#define WM_MOUSEMOVE                    512
#define WM_MOUSELEAVE                   675
#define WM_LBUTTONDOWN                  513
#define WM_LBUTTONUP                    514
#define WM_LBUTTONDBLCLK                515
#define WM_RBUTTONDOWN                  516
#define WM_RBUTTONUP                    517
#define WM_MOUSEWHEEL                   522

#define HWG_DEAD_KEY "hwg_dead"

extern void hwg_writelog( const char * sFile, const char * sTraceMsg, ... );

void      SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue );
PHB_ITEM  GetObjectVar( PHB_ITEM pObject, char* varname );
void      SetWindowObject( GtkWidget * hWnd, PHB_ITEM pObject );
void      set_signal( gpointer handle, char *cSignal, long p1, long p2, long p3 );
void      set_event ( gpointer handle, char *cSignal, long p1, long p2, long p3 );
void      cb_signal ( GtkWidget *widget, gchar* data );
void      cb_signal_size( GtkWidget *widget, int w, int h, gpointer data );

PHB_DYNS   pSym_onEvent  = NULL;
PHB_DYNS   pSym_keylist  = NULL;
GtkWidget *hMainWindow   = NULL;

HB_LONG    prevp2 = -1;

static GMainLoop      *s_MainLoop = NULL;
static GtkCssProvider *s_EntryCss = NULL;

static gboolean s_swallow_next_enter_press   = FALSE;
static gboolean s_swallow_next_enter_release = FALSE;
static guint    s_swallow_timeout_id        = 0;

extern cairo_t   *hwg_current_cr;
extern GtkWidget *hwg_current_widget;

static gchar szAppLocale[] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";


/*------------------------------------------------------------------
 * "hwg_dead" helpers
 *----------------------------------------------------------------*/
static void hwg_mark_dead( GtkWidget *w )
{
    if( w && G_IS_OBJECT( w ) )
        g_object_set_data( (GObject*) w, HWG_DEAD_KEY, GINT_TO_POINTER( 1 ) );
}

static gboolean hwg_is_dead( GObject *o )
{
    return ( o && G_IS_OBJECT( o ) &&
    g_object_get_data( o, HWG_DEAD_KEY ) != NULL );
}


/*------------------------------------------------------------------
 * Window icon
 *
 * GTK4 note: GdkToplevel is NOT implemented by GtkWindow.  It lives
 * on the GdkSurface, which is created only after the window is
 * realized.  So the icon must be applied from the "realize" signal.
 *
 * X11 honours gdk_toplevel_set_icon_list().  Wayland ignores it by
 * protocol design -- there, the icon comes from the .desktop file
 * matched by the application id (see g_set_prgname in HWG_GTK_INIT).
 *----------------------------------------------------------------*/
static void cb_window_realize_icon( GtkWidget *w, gpointer user_data )
{
    PHWGUI_PIXBUF pix = (PHWGUI_PIXBUF) g_object_get_data( (GObject*) w, "hwg_icon" );
    GdkSurface   *surface;
    GdkTexture   *texture;
    GList        *icons;

    HB_SYMBOL_UNUSED( user_data );

    if( !pix || !pix->handle )
        return;

    surface = gtk_native_get_surface( GTK_NATIVE( w ) );
    if( !surface || !GDK_IS_TOPLEVEL( surface ) )
        return;

    texture = gdk_texture_new_for_pixbuf( pix->handle );
    if( !texture )
        return;

    icons = g_list_append( NULL, texture );
    gdk_toplevel_set_icon_list( GDK_TOPLEVEL( surface ), icons );
    g_list_free( icons );
    g_object_unref( texture );
}

static void hwg_arm_window_icon( GtkWidget *win, PHWGUI_PIXBUF pix )
{
    if( !win || !pix || !pix->handle )
        return;

    g_object_set_data( (GObject*) win, "hwg_icon", (gpointer) pix );
    g_signal_connect( win, "realize",
                      G_CALLBACK( cb_window_realize_icon ), NULL );
}


HB_LONG hwg_dispatch_onevent( GtkWidget *widget, HB_LONG p1, HB_LONG p2, HB_LONG p3 );
static HB_LONG ToKey( HB_LONG a, HB_LONG b );
static void hwg_maybe_quit_main_loop( GtkWidget *just_closed );

static void hwg_install_entry_css( void );
static void hwg_arm_swallow_enter( void );
static gint hwg_get_field_maxlen( GtkWidget *w );
static GtkWidget *hwg_next_focusable( GtkWidget *current );
static gboolean hwg_is_toplevel( GtkWidget *w );
static void hwg_clear_objects_recursive( GtkWidget *widget );


static GLogWriterOutput
hwg_log_writer( GLogLevelFlags   log_level,
                const GLogField *fields,
                gsize            n_fields,
                gpointer         user_data )
{
    gsize i;

    HB_SYMBOL_UNUSED( user_data );

    for( i = 0; i < n_fields; i++ )
    {
        if( g_strcmp0( fields[i].key, "MESSAGE" ) == 0 &&
            fields[i].value != NULL )
        {
            const gchar *msg = (const gchar *) fields[i].value;

            if( g_strrstr( msg, "GtkGizmo" ) ||
                g_strrstr( msg, "gdk_frame_timings_presented" ) ||
                g_strrstr( msg, "reported min width" ) ||
                g_strrstr( msg, "reported min height" ) ||
                g_strrstr( msg, "reported natural width" ) ||
                g_strrstr( msg, "reported natural height" ) ||
                g_strrstr( msg, "Trying to snapshot" ) ||
                g_strrstr( msg, "gtk_window_get_focus_visible" ) ||
                g_strrstr( msg, "g_object_ref: assertion 'G_IS_OBJECT" ) ||
                g_strrstr( msg, "g_object_notify_by_pspec: assertion 'G_IS_OBJECT" ) ||
                g_strrstr( msg, "gtk_widget_get_settings: assertion" ) ||
                g_strrstr( msg, "g_object_get: assertion 'G_IS_OBJECT" ) ||
                g_strrstr( msg, "g_object_set_data: assertion 'G_IS_OBJECT" ) ||
                g_strrstr( msg, "gtk_toggle_button_set_active: assertion" ) ||
                g_strrstr( msg, "gdk_event_triggers_context_menu" ) )
            {
                return G_LOG_WRITER_HANDLED;
            }
        }
    }

    return g_log_writer_default( log_level, fields, n_fields, user_data );
}


static gboolean hwg_swallow_timeout_cb( gpointer data )
{
    HB_SYMBOL_UNUSED( data );

    s_swallow_next_enter_press   = FALSE;
    s_swallow_next_enter_release = FALSE;
    s_swallow_timeout_id         = 0;
    return G_SOURCE_REMOVE;
}

static void hwg_arm_swallow_enter( void )
{
    s_swallow_next_enter_press   = TRUE;
    s_swallow_next_enter_release = TRUE;
    if( s_swallow_timeout_id )
        g_source_remove( s_swallow_timeout_id );
    s_swallow_timeout_id = g_timeout_add( 250, hwg_swallow_timeout_cb, NULL );
}


static gboolean hwg_is_toplevel( GtkWidget *w )
{
    GList    *tops;
    gboolean  found = FALSE;

    if( !w )
        return FALSE;

    for( tops = gtk_window_list_toplevels(); tops; tops = tops->next )
    {
        if( tops->data == (gpointer) w )
        {
            found = TRUE;
            break;
        }
    }

    return found;
}


static void hwg_install_entry_css( void )
{
    if( s_EntryCss )
        return;

    s_EntryCss = gtk_css_provider_new();

    gtk_css_provider_load_from_string( s_EntryCss,
                                       /* Normal state: reset Adwaita's inflated
                                        * geometry so the pixel size requested by
                                        * gtk_widget_set_size_request() is honored.
                                        * Win32-like geometry: 1px border,
                                        * 1/3px padding, no min-size.
                                        * Corners are kept slightly rounded (4px)
                                        * for a modern look. */
                                       "entry,"
                                       "entry.entry,"
                                       "entry.entry > text,"
                                       "entry.entry > text > placeholder {"
                                       "  min-width: 0;"
                                       "  min-height: 0;"
                                       "  padding: 1px 3px;"
                                       "  margin: 0;"
                                       "  border-width: 1px;"
                                       "  border-radius: 4px;"
                                       "  background-color: #ffffff;"
                                       "  background-image: none;"
                                       "  color: #000000;"
                                       "  caret-color: #000000;"
                                       "  border-color: #a0a0a0;"
                                       "  box-shadow: none;"
                                       "  outline: none;"
                                       "}"

                                       "entry:focus,"
                                       "entry.entry:focus,"
                                       "entry.entry:focus-within,"
                                       "entry.entry:focus > text,"
                                       "entry.entry:focus-within > text {"
                                       "  min-width: 0;"
                                       "  min-height: 0;"
                                       "  padding: 1px 3px;"
                                       "  margin: 0;"
                                       "  border-width: 1px;"
                                       "  border-radius: 4px;"
                                       "  background-color: #ffffcc;"
                                       "  background-image: none;"
                                       "  color: #000000;"
                                       "  caret-color: #000000;"
                                       "  border-color: #4488ff;"
                                       "  box-shadow: 0 0 0 1px #4488ff;"
                                       "  outline: none;"
                                       "}"

                                       "entry selection,"
                                       "entry.entry > text selection {"
                                       "  background-color: #308cc6;"
                                       "  color: #ffffff;"
                                       "}"

                                       "entry:disabled,"
                                       "entry.entry:disabled,"
                                       "entry.entry:disabled > text {"
                                       "  min-width: 0;"
                                       "  min-height: 0;"
                                       "  padding: 1px 3px;"
                                       "  margin: 0;"
                                       "  border-width: 1px;"
                                       "  border-radius: 4px;"
                                       "  background-color: #e0e0e0;"
                                       "  color: #808080;"
                                       "}"
    );

    gtk_style_context_add_provider_for_display(
        gdk_display_get_default(),
                                               GTK_STYLE_PROVIDER( s_EntryCss ),
                                               GTK_STYLE_PROVIDER_PRIORITY_USER );
}


static HB_LONG ToKey( HB_LONG a, HB_LONG b )
{
    if( a == GDK_KEY_asciitilde || a == GDK_KEY_dead_tilde )
    {
        if( b == GDK_KEY_A ) return (HB_LONG)GDK_KEY_Atilde;
        else if( b == GDK_KEY_a ) return (HB_LONG)GDK_KEY_atilde;
        else if( b == GDK_KEY_N ) return (HB_LONG)GDK_KEY_Ntilde;
        else if( b == GDK_KEY_n ) return (HB_LONG)GDK_KEY_ntilde;
        else if( b == GDK_KEY_O ) return (HB_LONG)GDK_KEY_Otilde;
        else if( b == GDK_KEY_o ) return (HB_LONG)GDK_KEY_otilde;
    }
    if( a == GDK_KEY_asciicircum || a == GDK_KEY_dead_circumflex )
    {
        if( b == GDK_KEY_A ) return (HB_LONG)GDK_KEY_Acircumflex;
        else if( b == GDK_KEY_a ) return (HB_LONG)GDK_KEY_acircumflex;
        else if( b == GDK_KEY_E ) return (HB_LONG)GDK_KEY_Ecircumflex;
        else if( b == GDK_KEY_e ) return (HB_LONG)GDK_KEY_ecircumflex;
        else if( b == GDK_KEY_I ) return (HB_LONG)GDK_KEY_Icircumflex;
        else if( b == GDK_KEY_i ) return (HB_LONG)GDK_KEY_icircumflex;
        else if( b == GDK_KEY_O ) return (HB_LONG)GDK_KEY_Ocircumflex;
        else if( b == GDK_KEY_o ) return (HB_LONG)GDK_KEY_ocircumflex;
        else if( b == GDK_KEY_U ) return (HB_LONG)GDK_KEY_Ucircumflex;
        else if( b == GDK_KEY_u ) return (HB_LONG)GDK_KEY_ucircumflex;
        else if( b == GDK_KEY_C ) return (HB_LONG)GDK_KEY_Ccircumflex;
        else if( b == GDK_KEY_H ) return (HB_LONG)GDK_KEY_Hcircumflex;
        else if( b == GDK_KEY_h ) return (HB_LONG)GDK_KEY_hcircumflex;
        else if( b == GDK_KEY_J ) return (HB_LONG)GDK_KEY_Jcircumflex;
        else if( b == GDK_KEY_j ) return (HB_LONG)GDK_KEY_jcircumflex;
        else if( b == GDK_KEY_G ) return (HB_LONG)GDK_KEY_Gcircumflex;
        else if( b == GDK_KEY_g ) return (HB_LONG)GDK_KEY_gcircumflex;
        else if( b == GDK_KEY_S ) return (HB_LONG)GDK_KEY_Scircumflex;
        else if( b == GDK_KEY_s ) return (HB_LONG)GDK_KEY_scircumflex;
    }
    if( a == GDK_KEY_grave || a == GDK_KEY_dead_grave )
    {
        if( b == GDK_KEY_A ) return (HB_LONG)GDK_KEY_Agrave;
        else if( b == GDK_KEY_a ) return (HB_LONG)GDK_KEY_agrave;
        else if( b == GDK_KEY_E ) return (HB_LONG)GDK_KEY_Egrave;
        else if( b == GDK_KEY_e ) return (HB_LONG)GDK_KEY_egrave;
        else if( b == GDK_KEY_I ) return (HB_LONG)GDK_KEY_Igrave;
        else if( b == GDK_KEY_i ) return (HB_LONG)GDK_KEY_igrave;
        else if( b == GDK_KEY_O ) return (HB_LONG)GDK_KEY_Ograve;
        else if( b == GDK_KEY_o ) return (HB_LONG)GDK_KEY_ograve;
        else if( b == GDK_KEY_U ) return (HB_LONG)GDK_KEY_Ugrave;
        else if( b == GDK_KEY_u ) return (HB_LONG)GDK_KEY_ugrave;
        else if( b == GDK_KEY_C ) return (HB_LONG)GDK_KEY_Ccedilla;
        else if( b == GDK_KEY_c ) return (HB_LONG)GDK_KEY_ccedilla;
    }
    if( a == GDK_KEY_acute || a == GDK_KEY_dead_acute )
    {
        if( b == GDK_KEY_A ) return (HB_LONG)GDK_KEY_Aacute;
        else if( b == GDK_KEY_a ) return (HB_LONG)GDK_KEY_aacute;
        else if( b == GDK_KEY_E ) return (HB_LONG)GDK_KEY_Eacute;
        else if( b == GDK_KEY_e ) return (HB_LONG)GDK_KEY_eacute;
        else if( b == GDK_KEY_I ) return (HB_LONG)GDK_KEY_Iacute;
        else if( b == GDK_KEY_i ) return (HB_LONG)GDK_KEY_iacute;
        else if( b == GDK_KEY_O ) return (HB_LONG)GDK_KEY_Oacute;
        else if( b == GDK_KEY_o ) return (HB_LONG)GDK_KEY_oacute;
        else if( b == GDK_KEY_U ) return (HB_LONG)GDK_KEY_Uacute;
        else if( b == GDK_KEY_u ) return (HB_LONG)GDK_KEY_uacute;
        else if( b == GDK_KEY_Y ) return (HB_LONG)GDK_KEY_Yacute;
        else if( b == GDK_KEY_y ) return (HB_LONG)GDK_KEY_yacute;
        else if( b == GDK_KEY_C ) return (HB_LONG)GDK_KEY_Cacute;
        else if( b == GDK_KEY_c ) return (HB_LONG)GDK_KEY_cacute;
        else if( b == GDK_KEY_L ) return (HB_LONG)GDK_KEY_Lacute;
        else if( b == GDK_KEY_l ) return (HB_LONG)GDK_KEY_lacute;
        else if( b == GDK_KEY_N ) return (HB_LONG)GDK_KEY_Nacute;
        else if( b == GDK_KEY_n ) return (HB_LONG)GDK_KEY_nacute;
        else if( b == GDK_KEY_R ) return (HB_LONG)GDK_KEY_Racute;
        else if( b == GDK_KEY_r ) return (HB_LONG)GDK_KEY_racute;
        else if( b == GDK_KEY_S ) return (HB_LONG)GDK_KEY_Sacute;
        else if( b == GDK_KEY_s ) return (HB_LONG)GDK_KEY_sacute;
        else if( b == GDK_KEY_Z ) return (HB_LONG)GDK_KEY_Zacute;
        else if( b == GDK_KEY_z ) return (HB_LONG)GDK_KEY_zacute;
    }
    if( a == GDK_KEY_diaeresis || a == GDK_KEY_dead_diaeresis )
    {
        if( b == GDK_KEY_A ) return (HB_LONG)GDK_KEY_Adiaeresis;
        else if( b == GDK_KEY_a ) return (HB_LONG)GDK_KEY_adiaeresis;
        else if( b == GDK_KEY_E ) return (HB_LONG)GDK_KEY_Ediaeresis;
        else if( b == GDK_KEY_e ) return (HB_LONG)GDK_KEY_ediaeresis;
        else if( b == GDK_KEY_I ) return (HB_LONG)GDK_KEY_Idiaeresis;
        else if( b == GDK_KEY_i ) return (HB_LONG)GDK_KEY_idiaeresis;
        else if( b == GDK_KEY_O ) return (HB_LONG)GDK_KEY_Odiaeresis;
        else if( b == GDK_KEY_o ) return (HB_LONG)GDK_KEY_odiaeresis;
        else if( b == GDK_KEY_U ) return (HB_LONG)GDK_KEY_Udiaeresis;
        else if( b == GDK_KEY_u ) return (HB_LONG)GDK_KEY_udiaeresis;
        else if( b == GDK_KEY_Y ) return (HB_LONG)GDK_KEY_Ydiaeresis;
        else if( b == GDK_KEY_y ) return (HB_LONG)GDK_KEY_ydiaeresis;
    }
    return b;
}


static void hwg_maybe_quit_main_loop( GtkWidget *just_closed )
{
    GList    *tops;
    gboolean  bOther = FALSE;

    if( hMainWindow == NULL || just_closed == NULL ||
        just_closed != GTK_WIDGET( hMainWindow ) )
        return;

    for( tops = gtk_window_list_toplevels(); tops; tops = tops->next )
    {
        if( tops->data == (gpointer) just_closed )
            continue;
        if( GTK_IS_WINDOW( tops->data ) )
        {
            bOther = TRUE;
            break;
        }
    }

    if( !bOther && s_MainLoop && g_main_loop_is_running( s_MainLoop ) )
        g_main_loop_quit( s_MainLoop );
}


static void hwg_clear_objects_recursive( GtkWidget *widget )
{
    GtkWidget *child;

    if( !widget || !GTK_IS_WIDGET( widget ) )
        return;

    SetWindowObject( widget, NULL );

    if( GTK_IS_COMBO_BOX( widget ) )
    {
        GtkWidget *entry = gtk_combo_box_get_child( GTK_COMBO_BOX( widget ) );
        if( entry && GTK_IS_WIDGET( entry ) )
            SetWindowObject( entry, NULL );
    }

    if( GTK_IS_NOTEBOOK( widget ) )
    {
        gint n = gtk_notebook_get_n_pages( GTK_NOTEBOOK( widget ) );
        gint i;

        for( i = 0; i < n; i++ )
        {
            GtkWidget *page  = gtk_notebook_get_nth_page( GTK_NOTEBOOK( widget ), i );
            GtkWidget *label = page ? gtk_notebook_get_tab_label( GTK_NOTEBOOK( widget ), page ) : NULL;

            if( label )
                SetWindowObject( label, NULL );
        }
    }

    for( child = gtk_widget_get_first_child( widget );
        child;
    child = gtk_widget_get_next_sibling( child ) )
        {
            hwg_clear_objects_recursive( child );
        }
}


/*------------------------------------------------------------------
 * Window destroyed handler
 *
 * Marks the GtkWindow as dead on ANY destruction path -- including
 * GTK4's own auto-destroy when a parent is torn down or when the
 * user closes a transient window without going through
 * HWG_DESTROYWINDOW.  Without this, HWG_SETFOCUS could call
 * gtk_window_present() on a corpse and trigger:
 *   "A window is shown after it has been destroyed."
 *----------------------------------------------------------------*/
static void cb_window_destroyed( GtkWidget *widget, gpointer user_data )
{
    HB_SYMBOL_UNUSED( user_data );

    if( widget && G_IS_OBJECT( widget ) )
        hwg_mark_dead( widget );
}


static void cb_focus_enter( GtkEventControllerFocus *ctl, gpointer user_data )
{
    GtkWidget *w = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( ctl ) );

    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) w ) )
        return;

    if( g_object_get_data( (GObject*) w, "obj" ) )
        hwg_dispatch_onevent( w, WM_SETFOCUS, 0, 0 );
}

static void cb_focus_leave( GtkEventControllerFocus *ctl, gpointer user_data )
{
    GtkWidget *w = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( ctl ) );

    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) w ) )
        return;

    if( g_object_get_data( (GObject*) w, "obj" ) )
        hwg_dispatch_onevent( w, WM_KILLFOCUS, 0, 0 );
}


static gboolean hwg_is_focusable( GtkWidget *w )
{
    gint width, height;

    if( !w || !GTK_IS_WIDGET( w ) )
        return FALSE;
    if( hwg_is_dead( (GObject*) w ) )
        return FALSE;
    if( !gtk_widget_get_can_focus( w ) )
        return FALSE;
    if( !gtk_widget_get_visible( w ) )
        return FALSE;
    if( !gtk_widget_is_sensitive( w ) )
        return FALSE;

    width  = gtk_widget_get_width( w );
    height = gtk_widget_get_height( w );
    if( width <= 0 || height <= 0 )
        return FALSE;

    return TRUE;
}

static GtkWidget *hwg_next_focusable( GtkWidget *current )
{
    GtkWidget *parent       = gtk_widget_get_parent( current );
    GtkWidget *sibling      = NULL;
    GtkWidget *first_child  = NULL;
    gboolean   past_current = FALSE;

    if( !parent )
        return NULL;

    for( sibling = gtk_widget_get_first_child( parent );
        sibling;
    sibling = gtk_widget_get_next_sibling( sibling ) )
        {
            if( sibling == current )
            {
                past_current = TRUE;
                continue;
            }
            if( past_current && hwg_is_focusable( sibling ) )
                return sibling;
        }

        if( past_current )
        {
            for( first_child = gtk_widget_get_first_child( parent );
                first_child;
            first_child = gtk_widget_get_next_sibling( first_child ) )
                {
                    if( first_child == current )
                        continue;
                    if( hwg_is_focusable( first_child ) )
                        return first_child;
                }
        }

        return NULL;
}

static gboolean hwg_advance_focus_idle( gpointer data )
{
    GtkWidget *w = GTK_WIDGET( data );
    GtkWidget *next;

    if( GTK_IS_WIDGET( w ) && !hwg_is_dead( (GObject*) w ) &&
        gtk_widget_get_parent( w ) != NULL &&
        gtk_widget_get_visible( w ) && gtk_widget_has_focus( w ) )
    {
        next = hwg_next_focusable( w );
        if( next )
            gtk_widget_grab_focus( next );
    }

    g_object_unref( w );
    return G_SOURCE_REMOVE;
}


static gboolean hwg_deferred_setfocus_idle( gpointer data )
{
    GtkWidget *w = GTK_WIDGET( data );

    /*
     * Guard against "destroyed but not yet finalized": GTK4 defers
     * finalization of the GObject, so GTK_IS_WIDGET still returns
     * TRUE on a corpse -- but gtk_widget_grab_focus() would then call
     * gtk_widget_get_native() on it, raising
     *   gtk_widget_get_native: assertion 'GTK_IS_WIDGET (widget)' failed
     * and its cascade.  Requiring an attached root rejects those.
     */
    if( G_IS_OBJECT( w ) && GTK_IS_WIDGET( w ) &&
        !hwg_is_dead( (GObject*) w ) &&
        gtk_widget_get_root( w ) != NULL &&
        gtk_widget_get_parent( w ) != NULL &&
        gtk_widget_get_mapped( w ) &&
        gtk_widget_get_visible( w ) &&
        gtk_widget_is_sensitive( w ) )
    {
        gtk_widget_grab_focus( w );
    }

    if( G_IS_OBJECT( w ) )
        g_object_unref( w );

    return G_SOURCE_REMOVE;
}


static gint hwg_get_field_maxlen( GtkWidget *w )
{
    gint max_len = 0;

    if( !w || !GTK_IS_WIDGET( w ) )
        return 0;

    if( GTK_IS_ENTRY( w ) )
        max_len = gtk_entry_get_max_length( GTK_ENTRY( w ) );

    if( max_len <= 0 )
        max_len = GPOINTER_TO_INT( g_object_get_data( (GObject*) w, "hwg_maxlen" ) );

    return max_len;
}


static void cb_editable_changed( GtkEditable *editable, gpointer user_data )
{
    GtkWidget   *w;
    gint         max_len;
    const gchar *text;
    glong        text_len;
    glong        prev_len;

    HB_SYMBOL_UNUSED( user_data );

    if( !GTK_IS_ENTRY( editable ) )
        return;

    if( hb_setGetConfirm() )
        return;

    w = GTK_WIDGET( editable );

    if( hwg_is_dead( (GObject*) w ) )
        return;

    max_len = hwg_get_field_maxlen( w );
    if( max_len <= 0 )
        return;

    text     = gtk_editable_get_text( editable );
    text_len = text ? g_utf8_strlen( text, -1 ) : 0;

    prev_len = (glong) GPOINTER_TO_INT(
        g_object_get_data( (GObject*) w, "hwg_prevlen" ) );

    g_object_set_data( (GObject*) w, "hwg_prevlen",
                       GINT_TO_POINTER( (int) text_len ) );

    if( prev_len >= max_len || text_len < max_len )
        return;

    g_object_ref( w );
    g_idle_add( hwg_advance_focus_idle, w );
}


static gboolean cb_key_pressed( GtkEventControllerKey *controller,
                                guint keyval, guint keycode,
                                GdkModifierType state, gpointer user_data )
{
    GtkWidget *w = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( controller ) );
    HB_LONG    p2 = (HB_LONG) keyval;
    HB_LONG    p3;
    HB_LONG    result;

    HB_SYMBOL_UNUSED( keycode );
    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) w ) )
        return FALSE;

    if( s_swallow_next_enter_press &&
        ( keyval == GDK_KEY_Return || keyval == GDK_KEY_KP_Enter ) )
    {
        s_swallow_next_enter_press   = FALSE;
        s_swallow_next_enter_release = FALSE;
        return TRUE;
    }

    p3 = ( ( state & GDK_SHIFT_MASK )   ? 1 : 0 ) |
    ( ( state & GDK_CONTROL_MASK ) ? 2 : 0 ) |
    ( ( state & GDK_ALT_MASK )     ? 4 : 0 );

    if( GTK_IS_EDITABLE( w ) )
    {
        g_object_ref( w );

        result = hwg_dispatch_onevent( w, WM_KEYDOWN, p2, p3 );

        if( hwg_is_dead( (GObject*) w ) || gtk_widget_get_parent( w ) == NULL )
        {
            g_object_unref( w );
            return TRUE;
        }

        g_object_unref( w );

        return (gboolean) result;
    }

    if( p2 == GDK_KEY_asciitilde    || p2 == GDK_KEY_asciicircum     ||
        p2 == GDK_KEY_grave         || p2 == GDK_KEY_acute           ||
        p2 == GDK_KEY_diaeresis     || p2 == GDK_KEY_dead_acute      ||
        p2 == GDK_KEY_dead_tilde    || p2 == GDK_KEY_dead_circumflex ||
        p2 == GDK_KEY_dead_grave    || p2 == GDK_KEY_dead_diaeresis )
    {
        prevp2 = p2;
        p2 = -1;
    }
    else if( prevp2 != -1 )
    {
        p2 = ToKey( prevp2, p2 );
        prevp2 = -1;
    }

    result = hwg_dispatch_onevent( w, WM_KEYDOWN, p2, p3 );

    return (gboolean) result;
}

static void cb_key_released( GtkEventControllerKey *controller,
                             guint keyval, guint keycode,
                             GdkModifierType state, gpointer user_data )
{
    GtkWidget *w = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( controller ) );
    HB_LONG    p2 = (HB_LONG) keyval;
    HB_LONG    p3;

    HB_SYMBOL_UNUSED( keycode );
    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) w ) )
        return;

    if( s_swallow_next_enter_release &&
        ( keyval == GDK_KEY_Return || keyval == GDK_KEY_KP_Enter ) )
    {
        s_swallow_next_enter_release = FALSE;
        return;
    }

    if( GTK_IS_EDITABLE( w ) )
        return;

    if( p2 == GDK_KEY_asciitilde    || p2 == GDK_KEY_asciicircum     ||
        p2 == GDK_KEY_grave         || p2 == GDK_KEY_acute           ||
        p2 == GDK_KEY_diaeresis     || p2 == GDK_KEY_dead_acute      ||
        p2 == GDK_KEY_dead_tilde    || p2 == GDK_KEY_dead_circumflex ||
        p2 == GDK_KEY_dead_grave    || p2 == GDK_KEY_dead_diaeresis )
    {
        prevp2 = p2;
        p2 = -1;
    }
    else if( prevp2 != -1 )
    {
        p2 = ToKey( prevp2, p2 );
        prevp2 = -1;
    }

    p3 = ( ( state & GDK_SHIFT_MASK )   ? 1 : 0 ) |
    ( ( state & GDK_CONTROL_MASK ) ? 2 : 0 ) |
    ( ( state & GDK_ALT_MASK )     ? 4 : 0 );

    hwg_dispatch_onevent( w, WM_KEYUP, p2, p3 );
}

static void cb_button_pressed( GtkGestureClick *gesture, int n_press,
                               double x, double y, gpointer user_data )
{
    GtkWidget *w   = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( gesture ) );
    guint      btn = gtk_gesture_single_get_current_button( GTK_GESTURE_SINGLE( gesture ) );
    HB_LONG    p1  = ( n_press == 2 ) ? WM_LBUTTONDBLCLK :
    ( btn == 3 ? WM_RBUTTONDOWN : WM_LBUTTONDOWN );
    HB_LONG    p3  = ( ( (HB_ULONG) x ) & 0xFFFF ) |
    ( ( ( (HB_ULONG) y ) << 16 ) & 0xFFFF0000 );

    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) w ) )
        return;

    if( gtk_widget_get_can_focus( w ) && !gtk_widget_has_focus( w ) )
        gtk_widget_grab_focus( w );

    hwg_dispatch_onevent( w, p1, 0, p3 );
}

static void cb_button_released( GtkGestureClick *gesture, int n_press,
                                double x, double y, gpointer user_data )
{
    GtkWidget *w   = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( gesture ) );
    guint      btn = gtk_gesture_single_get_current_button( GTK_GESTURE_SINGLE( gesture ) );
    HB_LONG    p1  = ( btn == 3 ) ? WM_RBUTTONUP : WM_LBUTTONUP;
    HB_LONG    p3  = ( ( (HB_ULONG) x ) & 0xFFFF ) |
    ( ( ( (HB_ULONG) y ) << 16 ) & 0xFFFF0000 );

    HB_SYMBOL_UNUSED( n_press );
    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) w ) )
        return;

    /* Deliberately does NOT grab focus.  Doing so would steal focus
     f rom the HGet that was created by a double click. */
     hwg_dispatch_onevent( w, p1, 0, p3 );
}

static void cb_motion( GtkEventControllerMotion *controller,
                       double x, double y, gpointer user_data )
{
    GtkWidget *w = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( controller ) );
    HB_LONG    p3 = ( ( (HB_ULONG) x ) & 0xFFFF ) |
    ( ( ( (HB_ULONG) y ) << 16 ) & 0xFFFF0000 );

    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) w ) )
        return;

    hwg_dispatch_onevent( w, WM_MOUSEMOVE, 0, p3 );
}

static void cb_motion_enter( GtkEventControllerMotion *controller,
                             double x, double y, gpointer user_data )
{
    GtkWidget *w = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( controller ) );
    HB_LONG    p3 = ( ( (HB_ULONG) x ) & 0xFFFF ) |
    ( ( ( (HB_ULONG) y ) << 16 ) & 0xFFFF0000 );

    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) w ) )
        return;

    hwg_dispatch_onevent( w, WM_MOUSEMOVE, 0x10, p3 );
}

static void cb_motion_leave( GtkEventControllerMotion *controller, gpointer user_data )
{
    GtkWidget *w = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( controller ) );

    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) w ) )
        return;

    hwg_dispatch_onevent( w, WM_MOUSELEAVE, 0, 0 );
}

gboolean cb_scroll( GtkEventControllerScroll *controller,
                    double dx, double dy, gpointer user_data )
{
    GtkWidget *w = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( controller ) );
    HB_LONG    p2;

    HB_SYMBOL_UNUSED( dx );
    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) w ) )
        return TRUE;

    if( dy == 0.0 )
        return TRUE;

    p2 = ( dy < 0.0 ) ? 120 : -120;

    hwg_dispatch_onevent( w, WM_MOUSEWHEEL, p2, 0 );

    return TRUE;
}

static void hwg_draw_func( GtkDrawingArea *area, cairo_t *cr,
                           int width, int height, gpointer user_data )
{
    cairo_t   *saved_cr     = hwg_current_cr;
    GtkWidget *saved_widget = hwg_current_widget;
    HB_LONG    p3;

    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) area ) )
        return;

    hwg_current_cr     = cr;
    hwg_current_widget = GTK_WIDGET( area );

    p3 = ( ( (HB_ULONG) width  & 0xFFFF ) |
    ( ( (HB_ULONG) height << 16 ) & 0xFFFF0000 ) );

    hwg_dispatch_onevent( GTK_WIDGET( area ), WM_PAINT, 0, p3 );

    hwg_current_cr     = saved_cr;
    hwg_current_widget = saved_widget;
}

HB_LONG hwg_dispatch_onevent( GtkWidget *widget, HB_LONG p1, HB_LONG p2, HB_LONG p3 )
{
    gpointer gObject;

    if( !widget || !GTK_IS_WIDGET( widget ) )
        return 0;

    if( hwg_is_dead( (GObject*) widget ) )
        return 0;

    gObject = g_object_get_data( (GObject*) widget, "obj" );

    if( !pSym_onEvent )
        pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

    if( pSym_onEvent && gObject )
    {
        hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
        hb_vmPush( (PHB_ITEM) gObject );
        hb_vmPushLong( p1 );
        hb_vmPushLong( p2 );
        hb_vmPushLong( p3 );
        hb_vmSend( 3 );
        return hb_parnl( -1 );
    }
    return 0;
}

void hwg_install_widget_events( GtkWidget *widget, gboolean bDrawable )
{
    GtkGesture         *click;
    GtkEventController *motion;
    GtkEventController *key;
    GtkEventController *focus_ctl;

    if( !widget || !GTK_IS_WIDGET( widget ) )
        return;

    if( bDrawable && GTK_IS_DRAWING_AREA( widget ) )
    {
        gtk_drawing_area_set_draw_func( GTK_DRAWING_AREA( widget ),
                                        hwg_draw_func, NULL, NULL );
    }

    click = gtk_gesture_click_new();
    gtk_gesture_single_set_button( GTK_GESTURE_SINGLE( click ), 0 );
    g_signal_connect( click, "pressed",  G_CALLBACK( cb_button_pressed ),  NULL );
    g_signal_connect( click, "released", G_CALLBACK( cb_button_released ), NULL );
    gtk_widget_add_controller( widget, GTK_EVENT_CONTROLLER( click ) );

    motion = gtk_event_controller_motion_new();
    g_signal_connect( motion, "motion", G_CALLBACK( cb_motion ),       NULL );
    g_signal_connect( motion, "enter",  G_CALLBACK( cb_motion_enter ), NULL );
    g_signal_connect( motion, "leave",  G_CALLBACK( cb_motion_leave ), NULL );
    gtk_widget_add_controller( widget, motion );

    /* The scroll controller is NOT installed here.  It lives only on
     t he GtkDrawingArea of a browse (see HWG_CREATEBROWSE in     *
     control.c).  Installing it on every widget made the input
     method of a focused GtkEntry insert literal characters. */

    key = gtk_event_controller_key_new();
    gtk_event_controller_set_propagation_phase( key, GTK_PHASE_CAPTURE );
    g_signal_connect( key, "key-pressed",  G_CALLBACK( cb_key_pressed ),  NULL );
    g_signal_connect( key, "key-released", G_CALLBACK( cb_key_released ), NULL );
    gtk_widget_add_controller( widget, key );

    focus_ctl = gtk_event_controller_focus_new();
    g_signal_connect( focus_ctl, "enter", G_CALLBACK( cb_focus_enter ), NULL );
    g_signal_connect( focus_ctl, "leave", G_CALLBACK( cb_focus_leave ), NULL );
    gtk_widget_add_controller( widget, focus_ctl );

    if( GTK_IS_EDITABLE( widget ) )
    {
        g_signal_connect( widget, "changed",
                          G_CALLBACK( cb_editable_changed ), NULL );
    }
}


static gboolean cb_close_request( GtkWindow *window, gpointer user_data )
{
    gpointer   gObject = g_object_get_data( (GObject*) window, "obj" );
    GMainLoop *dialogLoop;
    gboolean   bClose = FALSE;
    gboolean   is_main;
    gboolean   still_toplevel;

    HB_SYMBOL_UNUSED( user_data );

    is_main = ( hMainWindow != NULL &&
    window == GTK_WINDOW( hMainWindow ) );

    if( !pSym_onEvent )
        pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

    if( pSym_onEvent && gObject )
    {
        hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
        hb_vmPush( (PHB_ITEM) gObject );
        hb_vmPushLong( 2 );
        hb_vmPushLong( 0 );
        hb_vmPushLong( 0 );
        hb_vmSend( 3 );
        bClose = (gboolean) hb_parl( -1 );
    }
    else
    {
        bClose = TRUE;
    }

    still_toplevel = hwg_is_toplevel( GTK_WIDGET( window ) );
    if( !still_toplevel || hwg_is_dead( (GObject*) window ) )
        return TRUE;

    if( !is_main )
    {
        dialogLoop = g_object_get_data( G_OBJECT( window ), "hwg_dialog_loop" );
        if( dialogLoop && g_main_loop_is_running( dialogLoop ) )
        {
            g_main_loop_quit( dialogLoop );
            hwg_arm_swallow_enter();
        }

        hwg_mark_dead( GTK_WIDGET( window ) );
        hwg_clear_objects_recursive( GTK_WIDGET( window ) );

        return FALSE;
    }

    if( bClose )
    {
        GList    *tops;
        gboolean  bOther = FALSE;

        for( tops = gtk_window_list_toplevels(); tops; tops = tops->next )
        {
            if( tops->data == (gpointer) window )
                continue;
            if( GTK_IS_WINDOW( tops->data ) )
            {
                bOther = TRUE;
                break;
            }
        }

        if( !bOther && s_MainLoop && g_main_loop_is_running( s_MainLoop ) )
            g_main_loop_quit( s_MainLoop );

        return FALSE;
    }

    return TRUE;
}

static void cb_window_default_size_notify( GObject *obj, GParamSpec *pspec, gpointer user_data )
{
    GtkWidget *w = GTK_WIDGET( obj );
    int width  = gtk_widget_get_width( w );
    int height = gtk_widget_get_height( w );
    HB_LONG p3 = ( ( (HB_ULONG) width  & 0xFFFF ) |
    ( ( (HB_ULONG) height << 16 ) & 0xFFFF0000 ) );

    HB_SYMBOL_UNUSED( pspec );
    HB_SYMBOL_UNUSED( user_data );

    if( hwg_is_dead( (GObject*) w ) )
        return;

    hwg_dispatch_onevent( w, WM_SIZE, 0, p3 );
}


void cb_signal_size( GtkWidget *widget, int width, int height, gpointer data )
{
    gpointer gObject;

    if( hwg_is_dead( (GObject*) widget ) )
        return;

    if( data )
        gObject = g_object_get_data( (GObject*) widget, "obj" );
    else
        gObject = g_object_get_data( (GObject*)
        gtk_widget_get_parent( gtk_widget_get_parent( widget ) ), "obj" );

    if( !pSym_onEvent )
        pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

    if( pSym_onEvent && gObject )
    {
        HB_LONG p3 = ( ( (HB_ULONG) width  & 0xFFFF ) |
        ( ( (HB_ULONG) height << 16 ) & 0xFFFF0000 ) );

        hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
        hb_vmPush( (PHB_ITEM) gObject );
        hb_vmPushLong( WM_SIZE );
        hb_vmPushLong( 0 );
        hb_vmPushLong( p3 );
        hb_vmSend( 3 );
    }
}


void cb_signal( GtkWidget *widget, gchar* data )
{
    gpointer gObject;
    HB_LONG p1, p2, p3;

    if( hwg_is_dead( (GObject*) widget ) )
        return;

    sscanf( (char*)data, "%ld %ld %ld", &p1, &p2, &p3 );

    if( !p1 )
    {
        p1 = 273;
        if( p3 )
            widget = (GtkWidget*) p3;
        else
            widget = hMainWindow;
        p3 = 0;
    }

    gObject = g_object_get_data( (GObject*) widget, "obj" );

    if( !pSym_onEvent )
        pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

    if( pSym_onEvent && gObject )
    {
        hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
        hb_vmPush( (PHB_ITEM) gObject );
        hb_vmPushLong( p1 );
        hb_vmPushLong( p2 );
        hb_vmPushLong( (HB_LONG) p3 );
        hb_vmSend( 3 );
    }
}


static void cb_signal_motion( GtkEventControllerMotion *controller,
                              double x, double y, gpointer user_data )
{
    GtkWidget *w = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( controller ) );

    HB_SYMBOL_UNUSED( x );
    HB_SYMBOL_UNUSED( y );

    if( hwg_is_dead( (GObject*) w ) )
        return;

    cb_signal( w, (gchar*) user_data );
}

static void cb_combo_changed( GObject *obj, GParamSpec *pspec, gpointer user_data )
{
    HB_SYMBOL_UNUSED( pspec );

    if( hwg_is_dead( obj ) )
        return;

    cb_signal( GTK_WIDGET( obj ), (gchar*) user_data );
}

static void cb_window_mapped( GObject *obj, GParamSpec *pspec, gpointer user_data )
{
    GtkWidget *w = GTK_WIDGET( obj );

    HB_SYMBOL_UNUSED( pspec );

    if( hwg_is_dead( obj ) )
        return;

    if( gtk_widget_get_mapped( w ) )
        cb_signal( w, (gchar*) user_data );
}

static gboolean cb_clipboard_shortcut( GtkWidget *widget, GVariant *args,
                                       gpointer user_data )
{
    HB_SYMBOL_UNUSED( args );

    if( hwg_is_dead( (GObject*) widget ) )
        return FALSE;

    cb_signal( widget, (gchar*) user_data );

    return FALSE;
}


void set_signal( gpointer handle, char * cSignal, long int p1, long int p2, long int p3 )
{
    char buf[25] = {0};
    sprintf( buf, "%ld %ld %ld", p1, p2, p3 );

    if( !cSignal )
        return;

    if( strcmp( cSignal, "enter" ) == 0 || strcmp( cSignal, "leave" ) == 0 )
    {
        GtkEventController *ctl = gtk_event_controller_motion_new();
        g_signal_connect_data( ctl, cSignal,
                               G_CALLBACK( cb_signal_motion ),
                               g_strdup( buf ),
                               (GClosureNotify) g_free, 0 );
        gtk_widget_add_controller( GTK_WIDGET( handle ), ctl );
        return;
    }

    if( strcmp( cSignal, "map-event" ) == 0 )
    {
        g_signal_connect_data( handle, "notify::mapped",
                               G_CALLBACK( cb_window_mapped ),
                               g_strdup( buf ),
                               (GClosureNotify) g_free, 0 );
        return;
    }

    if( strcmp( cSignal, "changed" ) == 0 && GTK_IS_COMBO_BOX( handle ) )
    {
        g_signal_connect_data( handle, "notify::active",
                               G_CALLBACK( cb_combo_changed ),
                               g_strdup( buf ),
                               (GClosureNotify) g_free, 0 );
        return;
    }

    if( strcmp( cSignal, "copy-clipboard" ) == 0 ||
        strcmp( cSignal, "paste-clipboard" ) == 0 )
    {
        GtkShortcutController *ctl =
        (GtkShortcutController *) gtk_shortcut_controller_new();
        GtkShortcutTrigger    *trigger;
        GtkShortcutAction     *action;
        GtkShortcut           *shortcut;
        guint                  key = ( strcmp( cSignal, "copy-clipboard" ) == 0 )
        ? GDK_KEY_c : GDK_KEY_v;

        trigger  = gtk_keyval_trigger_new( key, GDK_CONTROL_MASK );
        action   = gtk_callback_action_new( cb_clipboard_shortcut,
                                            g_strdup( buf ), g_free );
        shortcut = gtk_shortcut_new( trigger, action );
        gtk_shortcut_controller_add_shortcut( ctl, shortcut );
        gtk_widget_add_controller( GTK_WIDGET( handle ),
                                   GTK_EVENT_CONTROLLER( ctl ) );
        return;
    }

    if( ( strcmp( cSignal, "clicked" ) == 0 ||
        strcmp( cSignal, "released" ) == 0 ) &&
        GTK_IS_CHECK_BUTTON( handle ) )
    {
        cSignal = "toggled";
    }

    if( g_signal_lookup( cSignal, G_OBJECT_TYPE( handle ) ) == 0 )
    {
        return;
    }

    g_signal_connect( handle, cSignal,
                      G_CALLBACK( cb_signal ), g_strdup( buf ) );
}

HB_FUNC( HWG_SETSIGNAL )
{
    gpointer p = (gpointer) HB_PARHANDLE( 1 );
    set_signal( p, (char*) hb_parc( 2 ),
                hb_parnl( 3 ), hb_parnl( 4 ), (long int) HB_PARHANDLE( 5 ) );
}

HB_FUNC( HWG_EMITSIGNAL )
{
    g_signal_emit_by_name( G_OBJECT( HB_PARHANDLE( 1 ) ), (char*) hb_parc( 2 ) );
}

void set_event( gpointer handle, char * cSignal, long int p1, long int p2, long int p3 )
{
    HB_SYMBOL_UNUSED( handle );
    HB_SYMBOL_UNUSED( cSignal );
    HB_SYMBOL_UNUSED( p1 );
    HB_SYMBOL_UNUSED( p2 );
    HB_SYMBOL_UNUSED( p3 );
}

HB_FUNC( HWG_SETEVENT )
{
    set_event( (gpointer) HB_PARHANDLE( 1 ), (char*) hb_parc( 2 ),
               hb_parnl( 3 ), hb_parnl( 4 ), hb_parnl( 5 ) );
}

void all_signal_connect( gpointer hWnd )
{
    HB_SYMBOL_UNUSED( hWnd );
}

GtkWidget * GetActiveWindow( void )
{
    GList *pL = gtk_window_list_toplevels(), *pList;

    pList = pL;
    while( pList )
    {
        if( GTK_IS_WINDOW( pList->data ) &&
            !hwg_is_dead( (GObject*) pList->data ) &&
            gtk_window_is_active( pList->data ) )
            break;
        pList = g_list_next( pList );
    }

    if( !pList )
    {
        pList = pL;
        while( pList )
        {
            if( GTK_IS_WINDOW( pList->data ) &&
                !hwg_is_dead( (GObject*) pList->data ) )
                break;
            pList = g_list_next( pList );
        }
    }

    return ( pList ) ? pList->data : NULL;
}

HB_FUNC( HWG_GETACTIVEWINDOW )
{
    HB_RETHANDLE( GetActiveWindow() );
}


HB_FUNC( HWG_GTK_INIT )
{
    g_log_set_writer_func( hwg_log_writer, NULL, NULL );

    setlocale( LC_CTYPE,   "C.UTF-8" );
    setlocale( LC_NUMERIC, "C" );

    /*
     * Wayland identifies applications by app_id.  Setting the program
     * name explicitly makes the compositor look for sciwin.desktop
     * in the standard locations.  X11 ignores it.  The executable
     * name is used otherwise -- which on some systems does not match
     * the installed .desktop file, so the compositor falls back to
     * the generic icon.
     */
    g_set_prgname( "sciwin" );
    g_set_application_name( "SCI" );

    gtk_init();

    hwg_install_entry_css();
}

HB_FUNC( HWG_GTK_EXIT )
{
    if( gtk_window_list_toplevels() != NULL )
        return;

    if( s_MainLoop && g_main_loop_is_running( s_MainLoop ) )
        g_main_loop_quit( s_MainLoop );
}

HB_FUNC( HWG_INITMAINWINDOW )
{
    GtkWidget    *hWnd;
    GtkWidget    *overlay;
    GtkWidget    *vbox;
    GtkWidget    *picture  = NULL;
    GtkFixed     *box;
    PHB_ITEM      pObject  = hb_param( 1, HB_IT_OBJECT );
    gchar        *gcTitle  = hwg_convert_to_utf8( hb_parcx( 3 ) );
    int           width    = hb_parnl( 9 );
    int           height   = hb_parnl( 10 );

    PHWGUI_PIXBUF szIcon = HB_ISPOINTER( 5 )  ? (PHWGUI_PIXBUF) HB_PARHANDLE( 5 )  : NULL;
    PHWGUI_PIXBUF szBack = HB_ISPOINTER( 11 ) ? (PHWGUI_PIXBUF) HB_PARHANDLE( 11 ) : NULL;

    hWnd = gtk_window_new();

    gtk_window_set_title( GTK_WINDOW( hWnd ), gcTitle );
    g_free( gcTitle );

    gtk_window_set_resizable( GTK_WINDOW( hWnd ), TRUE );
    gtk_window_set_default_size( GTK_WINDOW( hWnd ), width, height );

    hwg_arm_window_icon( hWnd, szIcon );

    /* GtkOverlay + GtkPicture for the background */
    overlay = gtk_overlay_new();
    gtk_window_set_child( GTK_WINDOW( hWnd ), overlay );

    if( szBack && szBack->handle )
    {
        picture = gtk_picture_new_for_pixbuf( szBack->handle );
        gtk_picture_set_content_fit( GTK_PICTURE( picture ), GTK_CONTENT_FIT_FILL );
        gtk_widget_set_can_target( picture, FALSE );
        gtk_overlay_set_child( GTK_OVERLAY( overlay ), picture );
    }

    vbox = gtk_box_new( GTK_ORIENTATION_VERTICAL, 0 );
    gtk_widget_set_hexpand( vbox, TRUE );
    gtk_widget_set_vexpand( vbox, TRUE );
    gtk_overlay_add_overlay( GTK_OVERLAY( overlay ), vbox );

    box = (GtkFixed*) gtk_fixed_new();
    gtk_widget_set_hexpand( GTK_WIDGET( box ), TRUE );
    gtk_widget_set_vexpand( GTK_WIDGET( box ), TRUE );
    gtk_box_append( GTK_BOX( vbox ), GTK_WIDGET( box ) );

    g_object_set_data( (GObject*) hWnd, "window", (gpointer) 1 );
    SetWindowObject( hWnd, pObject );
    g_object_set_data( (GObject*) hWnd, "vbox", (gpointer) vbox );
    g_object_set_data( (GObject*) hWnd, "fbox", (gpointer) box );

    hwg_install_widget_events( hWnd, FALSE );

    g_signal_connect( G_OBJECT( hWnd ), "close-request",
                      G_CALLBACK( cb_close_request ), NULL );

    g_signal_connect( G_OBJECT( hWnd ), "destroy",
                      G_CALLBACK( cb_window_destroyed ), NULL );

    g_signal_connect( G_OBJECT( hWnd ), "notify::default-width",
                      G_CALLBACK( cb_window_default_size_notify ), NULL );
    g_signal_connect( G_OBJECT( hWnd ), "notify::default-height",
                      G_CALLBACK( cb_window_default_size_notify ), NULL );

    if( hMainWindow != NULL && hMainWindow != hWnd )
    {
        fprintf( stderr,
                 "[HWGUI] HWG_INITMAINWINDOW called twice: "
                 "old=%p new=%p -- possible dialog created as main window!\n",
                 (void*) hMainWindow, (void*) hWnd );
        fflush( stderr );
    }
    hMainWindow = hWnd;
    HB_RETHANDLE( hWnd );
}

HB_FUNC( HWG_CREATEDLG )
{
    GtkWidget    *hWnd;
    GtkWidget    *overlay;
    GtkWidget    *vbox;
    GtkWidget    *picture  = NULL;
    GtkFixed     *box;
    PHB_ITEM      pObject  = hb_param( 1, HB_IT_OBJECT );
    gchar        *gcTitle  = hwg_convert_to_utf8( hb_itemGetCPtr( GetObjectVar( pObject, "TITLE" ) ) );
    int           width    = hb_itemGetNI( GetObjectVar( pObject, "NWIDTH" ) );
    int           height   = hb_itemGetNI( GetObjectVar( pObject, "NHEIGHT" ) );

    PHWGUI_PIXBUF szIcon = HB_ISPOINTER( 2 ) ? (PHWGUI_PIXBUF) HB_PARHANDLE( 2 ) : NULL;
    PHWGUI_PIXBUF szBack = HB_ISPOINTER( 3 ) ? (PHWGUI_PIXBUF) HB_PARHANDLE( 3 ) : NULL;

    hWnd = gtk_window_new();

    gtk_window_set_title( GTK_WINDOW( hWnd ), gcTitle );
    g_free( gcTitle );
    gtk_window_set_resizable( GTK_WINDOW( hWnd ), TRUE );
    gtk_window_set_default_size( GTK_WINDOW( hWnd ), width, height );
    gtk_window_set_decorated( GTK_WINDOW( hWnd ), TRUE );

    hwg_arm_window_icon( hWnd, szIcon );

    overlay = gtk_overlay_new();
    gtk_window_set_child( GTK_WINDOW( hWnd ), overlay );

    if( szBack && szBack->handle )
    {
        picture = gtk_picture_new_for_pixbuf( szBack->handle );
        gtk_picture_set_content_fit( GTK_PICTURE( picture ), GTK_CONTENT_FIT_FILL );
        gtk_widget_set_can_target( picture, FALSE );
        gtk_overlay_set_child( GTK_OVERLAY( overlay ), picture );
    }

    vbox = gtk_box_new( GTK_ORIENTATION_VERTICAL, 0 );
    gtk_widget_set_hexpand( vbox, TRUE );
    gtk_widget_set_vexpand( vbox, TRUE );
    gtk_overlay_add_overlay( GTK_OVERLAY( overlay ), vbox );

    box = (GtkFixed*) gtk_fixed_new();
    gtk_widget_set_hexpand( GTK_WIDGET( box ), TRUE );
    gtk_widget_set_vexpand( GTK_WIDGET( box ), TRUE );
    gtk_box_append( GTK_BOX( vbox ), GTK_WIDGET( box ) );

    g_object_set_data( (GObject*) hWnd, "window", (gpointer) 1 );
    SetWindowObject( hWnd, pObject );
    g_object_set_data( (GObject*) hWnd, "vbox", (gpointer) vbox );
    g_object_set_data( (GObject*) hWnd, "fbox", (gpointer) box );

    hwg_install_widget_events( hWnd, FALSE );

    g_signal_connect( G_OBJECT( hWnd ), "close-request",
                      G_CALLBACK( cb_close_request ), NULL );

    g_signal_connect( G_OBJECT( hWnd ), "destroy",
                      G_CALLBACK( cb_window_destroyed ), NULL );

    g_signal_connect( G_OBJECT( hWnd ), "notify::default-width",
                      G_CALLBACK( cb_window_default_size_notify ), NULL );
    g_signal_connect( G_OBJECT( hWnd ), "notify::default-height",
                      G_CALLBACK( cb_window_default_size_notify ), NULL );

    HB_RETHANDLE( hWnd );
}

HB_FUNC( HWG_ACTIVATEMAINWINDOW )
{
    if( !s_MainLoop )
        s_MainLoop = g_main_loop_new( NULL, FALSE );

    if( !g_main_loop_is_running( s_MainLoop ) )
        g_main_loop_run( s_MainLoop );
}


HB_FUNC( HWG_ACTIVATEDIALOG )
{
    GtkWidget * widget = (GtkWidget*) HB_PARHANDLE( 1 );
    GtkWindow * parent = ( HB_ISPOINTER( 3 ) || HB_ISNUM( 3 ) )
    ? (GtkWindow *) HB_PARHANDLE( 3 ) : NULL;
    gboolean    bModal;
    GMainLoop  *dialogLoop;

    if( !widget || !GTK_IS_WINDOW( widget ) )
        return;

    bModal = ( HB_ISNIL( 2 ) || !hb_parl( 2 ) );

    if( bModal )
    {
        gtk_window_set_modal( GTK_WINDOW( widget ), TRUE );
        if( parent && GTK_IS_WINDOW( parent ) )
            gtk_window_set_transient_for( GTK_WINDOW( widget ), parent );

        dialogLoop = g_main_loop_new( NULL, FALSE );
        g_object_set_data( G_OBJECT( widget ), "hwg_dialog_loop", dialogLoop );

        gtk_window_present( GTK_WINDOW( widget ) );
        g_main_loop_run( dialogLoop );

        g_main_loop_unref( dialogLoop );
        hwg_arm_swallow_enter();
    }
    else
    {
        gtk_window_present( GTK_WINDOW( widget ) );
    }
}


void ProcessMessage( void )
{
    while( g_main_context_iteration( NULL, FALSE ) );
}

void hwg_doEvents( void )
{
    ProcessMessage();
}

HB_FUNC( HWG_PROCESSMESSAGE )
{
    ProcessMessage();
}


HB_FUNC( HWG_SETWINDOWOBJECT )
{
    GtkWidget *hWnd = (GtkWidget*) HB_PARHANDLE( 1 );
    PHB_ITEM   pObj  = hb_param( 2, HB_IT_OBJECT );

    if( hWnd && G_IS_OBJECT( hWnd ) && !hwg_is_dead( (GObject*) hWnd ) )
    {
        SetWindowObject( hWnd, pObj );

        if( pObj && GTK_IS_COMBO_BOX( hWnd ) )
        {
            GtkWidget *child = gtk_combo_box_get_child( GTK_COMBO_BOX( hWnd ) );
            if( child && GTK_IS_WIDGET( child ) )
                SetWindowObject( child, pObj );
        }
    }
}

void SetWindowObject( GtkWidget * hWnd, PHB_ITEM pObject )
{
    if( hWnd && G_IS_OBJECT( hWnd ) )
    {
        gpointer gObject = g_object_get_data( (GObject*) hWnd, "obj" );

        if( gObject )
            hb_itemRelease( (PHB_ITEM) gObject );

        if( pObject )
            g_object_set_data( (GObject*) hWnd, "obj", (gpointer) hb_itemNew( pObject ) );
        else
            g_object_set_data( (GObject*) hWnd, "obj", (gpointer) NULL );
    }
}

HB_FUNC( HWG_GETWINDOWOBJECT )
{
    GObject *hObj = (GObject*) HB_PARHANDLE( 1 );

    if( hObj && G_IS_OBJECT( hObj ) && !hwg_is_dead( hObj ) )
    {
        gpointer dwNewLong = g_object_get_data( hObj, "obj" );
        if( dwNewLong )
        {
            hb_itemReturn( (PHB_ITEM) dwNewLong );
            return;
        }
    }
    hb_ret();
}

HB_FUNC( HWG_SETWINDOWTEXT )
{
    gchar *gcTitle = hwg_convert_to_utf8( hb_parcx( 2 ) );
    GtkWidget *w = (GtkWidget*) HB_PARHANDLE( 1 );

    if( w && GTK_IS_WINDOW( w ) && !hwg_is_dead( (GObject*) w ) )
    {
        const gchar *cur = gtk_window_get_title( GTK_WINDOW( w ) );
        if( !cur || strcmp( cur, gcTitle ) != 0 )
            gtk_window_set_title( GTK_WINDOW( w ), gcTitle );
    }
    g_free( gcTitle );
}

HB_FUNC( HWG_GETWINDOWTEXT )
{
    GtkWidget *w = (GtkWidget*) HB_PARHANDLE( 1 );
    const char *cTitle = "";

    if( w && GTK_IS_WINDOW( w ) && !hwg_is_dead( (GObject*) w ) )
        cTitle = gtk_window_get_title( GTK_WINDOW( w ) );

    hb_retc( (char*) cTitle );
}

HB_FUNC( HWG_ENABLEWINDOW )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE( 1 );
    HB_BOOL    lEnable = hb_parl( 2 );

    if( widget && !hwg_is_dead( (GObject*) widget ) )
        gtk_widget_set_sensitive( widget, lEnable );
}

HB_FUNC( HWG_ISWINDOWENABLED )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE( 1 );

    if( widget && !hwg_is_dead( (GObject*) widget ) )
        hb_retl( gtk_widget_is_sensitive( widget ) );
    else
        hb_retl( FALSE );
}

HB_FUNC( HWG_ISICONIC )
{
    hb_retl( 0 );
}

HB_FUNC( HWG_MOVEWINDOW )
{
    GtkWidget *w = (GtkWidget*) HB_PARHANDLE( 1 );

    if( !w || !GTK_IS_WIDGET( w ) || hwg_is_dead( (GObject*) w ) )
        return;

    if( GTK_IS_WINDOW( w ) )
    {
        if( !HB_ISNIL( 4 ) || !HB_ISNIL( 5 ) )
        {
            gtk_window_set_default_size( GTK_WINDOW( w ),
                                         hb_parni( 4 ), hb_parni( 5 ) );
        }
        return;
    }

    {
        GtkWidget *parent = gtk_widget_get_parent( w );

        if( parent && GTK_IS_FIXED( parent ) )
        {
            if( !HB_ISNIL( 2 ) && !HB_ISNIL( 3 ) )
                gtk_fixed_move( GTK_FIXED( parent ), w,
                                hb_parni( 2 ), hb_parni( 3 ) );
        }
        if( !HB_ISNIL( 4 ) || !HB_ISNIL( 5 ) )
        {
            gint curw = 0, curh = 0;
            gint w1, h1;
            gtk_widget_get_size_request( w, &curw, &curh );
            w1 = HB_ISNIL(4) ? curw : hb_parni(4);
            h1 = HB_ISNIL(5) ? curh : hb_parni(5);
            gtk_widget_set_size_request( w, w1, h1 );
        }
    }
}

HB_FUNC( HWG_CENTERWINDOW )
{
    GtkWindow *hWnd = (GtkWindow*) HB_PARHANDLE( 1 );
    gint width = 0, height = 0;

    if( !hWnd || hwg_is_dead( (GObject*) hWnd ) )
        return;

    gtk_window_get_default_size( hWnd, &width, &height );
    if( width > 0 && height > 0 )
        gtk_window_set_default_size( hWnd, width, height );
}

HB_FUNC( HWG_WINDOWMAXIMIZE )
{
    GtkWindow *w = (GtkWindow*) HB_PARHANDLE( 1 );
    if( w && !hwg_is_dead( (GObject*) w ) )
        gtk_window_maximize( w );
}

HB_FUNC( HWG_RESTOREWINDOW )
{
    GtkWindow *w = (GtkWindow*) HB_PARHANDLE( 1 );
    if( w && !hwg_is_dead( (GObject*) w ) )
        gtk_window_unmaximize( w );
}

HB_FUNC( HWG_WINDOWMINIMIZE )
{
    GtkWindow *w = (GtkWindow*) HB_PARHANDLE( 1 );
    if( w && !hwg_is_dead( (GObject*) w ) )
        gtk_window_minimize( w );
}


PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname )
{
    return hb_objSendMsg( pObject, varname, 0 );
}

void SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue )
{
    hb_objSendMsg( pObject, varname, 1, pValue );
}


HB_FUNC( HWG_RELEASEOBJECT )
{
    GObject *hWnd = (GObject*) HB_PARHANDLE( 1 );
    gpointer dwNewLong;

    if( !hWnd || !G_IS_OBJECT( hWnd ) )
    {
        hb_ret();
        return;
    }

    dwNewLong = g_object_get_data( hWnd, "obj" );

    if( dwNewLong )
    {
        hb_itemRelease( (PHB_ITEM) dwNewLong );
        g_object_set_data( hWnd, "obj", (gpointer) NULL );
    }
    else
        hb_ret();
}

HB_FUNC( HWG_SETFOCUS )
{
    GObject   *hObj      = (GObject*) HB_PARHANDLE( 1 );
    GtkWidget *handle    = NULL;
    GList     *top_levels = gtk_window_list_toplevels();

    if( top_levels && top_levels->data && GTK_IS_WINDOW( top_levels->data ) )
    {
        GtkRoot *root = GTK_ROOT( top_levels->data );
        if( root )
            handle = gtk_root_get_focus( root );
    }

    if( hObj && G_IS_OBJECT( hObj ) && !hwg_is_dead( hObj ) )
    {
        if( g_object_get_data( hObj, "window" ) )
        {
            if( GTK_IS_WINDOW( hObj ) )
                gtk_window_present( GTK_WINDOW( hObj ) );
        }
        else if( GTK_IS_WIDGET( hObj ) )
        {
            GtkWidget *widget = GTK_WIDGET( hObj );

            /* Guard against destroyed-but-not-yet-finalized widgets:
             G TK_IS_WIDGET still returns TRUE on a corpse, but   *
             gtk_widget_grab_focus would then crash inside
             gtk_widget_get_native.  Require an attached root. */
            if( gtk_widget_get_root( widget ) != NULL &&
                gtk_widget_get_parent( widget ) != NULL )
            {
                if( gtk_widget_get_mapped( widget ) )
                {
                    gtk_widget_grab_focus( widget );
                }
                else
                {
                    g_object_ref( widget );
                    g_idle_add( hwg_deferred_setfocus_idle, widget );
                }
            }
        }
    }
    HB_RETHANDLE( handle );
}

HB_FUNC( HWG_GETFOCUS )
{
    GList     *tops  = gtk_window_list_toplevels();
    GtkWidget *focus = NULL;

    if( tops && tops->data && GTK_IS_WINDOW( tops->data ) )
    {
        GtkRoot *root = GTK_ROOT( tops->data );
        if( root )
            focus = gtk_root_get_focus( root );
    }

    HB_RETHANDLE( focus );
}

HB_FUNC( HWG_DESTROYWINDOW )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE( 1 );
    GMainLoop *dialogLoop;
    gboolean   is_main;

    if( !widget || !G_IS_OBJECT( widget ) || hwg_is_dead( (GObject*) widget ) )
        return;

    if( GTK_IS_WINDOW( widget ) )
    {
        dialogLoop = g_object_get_data( G_OBJECT( widget ), "hwg_dialog_loop" );
        if( dialogLoop && g_main_loop_is_running( dialogLoop ) )
        {
            g_main_loop_quit( dialogLoop );
            hwg_arm_swallow_enter();
        }

        is_main = ( hMainWindow != NULL && widget == hMainWindow );

        if( hwg_is_toplevel( widget ) )
        {
            hwg_mark_dead( widget );
            hwg_clear_objects_recursive( widget );

            gtk_window_destroy( GTK_WINDOW( widget ) );
        }

        if( is_main )
            hwg_maybe_quit_main_loop( widget );
    }
    else if( GTK_IS_WIDGET( widget ) )
    {
        /*
         * Clear the Harbour object BEFORE unparenting.
         *
         * gtk_widget_unparent() destroys the widget, and GTK4 emits
         * focus-out synchronously when the destroyed widget owned the
         * focus.  cb_focus_leave() looks up "obj" to decide whether to
         * dispatch WM_KILLFOCUS to Harbour -- if "obj" is still set,
         * the dispatch re-enters HEdit:onEvent, and the Valid chain
         * runs a second time while oBrw:oGet is already Nil, raising
         * BASE/1004 and freezing the UI inside a focus handler.
         *
         * Setting "obj" to NULL first makes cb_focus_leave() a no-op
         * and breaks the reentrancy cleanly.
         */
        SetWindowObject( widget, NULL );
        gtk_widget_unparent( widget );
    }
}


void hwg_set_modal( GtkWindow * hDlg, GtkWindow * hParent )
{
    gtk_window_set_modal( hDlg, TRUE );
    if( hParent )
        gtk_window_set_transient_for( hDlg, hParent );
}

HB_FUNC( HWG_SET_MODAL )
{
    hwg_set_modal( (GtkWindow*) HB_PARHANDLE( 1 ),
                   (GtkWindow*) ( ( !HB_ISNIL( 2 ) ) ? HB_PARHANDLE( 2 ) : NULL ) );
}

HB_FUNC( HWG_WINDOWSETRESIZE )
{
    GtkWindow *handle = (GtkWindow*) HB_PARHANDLE( 1 );
    gint width = 0, height = 0;
    HB_BOOL bResize = hb_parl( 2 );

    if( !handle || hwg_is_dead( (GObject*) handle ) )
        return;

    gtk_window_get_default_size( handle, &width, &height );
    if( width > 0 && height > 0 )
        gtk_widget_set_size_request( (GtkWidget*) handle, width, height );

    gtk_window_set_resizable( handle, bResize );
}

HB_FUNC( HWG_WINDOWSETDECORATED )
{
    GtkWindow *handle = (GtkWindow*) HB_PARHANDLE( 1 );

    if( !handle || hwg_is_dead( (GObject*) handle ) )
        return;

    gtk_window_set_decorated( handle, hb_parl( 2 ) );
}

HB_FUNC( HWG_SETTOPMOST )
{
    HB_SYMBOL_UNUSED( HB_PARHANDLE( 1 ) );
}

HB_FUNC( HWG_REMOVETOPMOST )
{
    HB_SYMBOL_UNUSED( HB_PARHANDLE( 1 ) );
}

HB_FUNC( HWG_GETWINDOWPOS )
{
    PHB_ITEM aMetr = hb_itemArrayNew( 2 );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
    hb_itemRelease( hb_itemReturn( aMetr ) );
}


gchar * hwg_convert_to_utf8( const char * szText )
{
    gchar  *result = NULL;
    GError *err    = NULL;

    if( !szText || !*szText )
        return g_strdup( "" );

    if( *szAppLocale )
        result = g_convert( szText, -1, "UTF-8", szAppLocale, NULL, NULL, &err );
    else
        result = g_locale_to_utf8( szText, -1, NULL, NULL, &err );

    if( !result )
    {
        if( err )
            g_error_free( err );
        return g_strdup( szText );
    }

    if( !g_utf8_validate( result, -1, NULL ) )
    {
        g_free( result );
        return g_strdup( szText );
    }

    return result;
}

gchar * hwg_convert_from_utf8( const char * szText )
{
    gchar  *result = NULL;
    GError *err    = NULL;

    if( !szText || !*szText )
        return g_strdup( "" );

    if( *szAppLocale )
        result = g_convert( szText, -1, szAppLocale, "UTF-8", NULL, NULL, &err );
    else
        result = g_locale_from_utf8( szText, -1, NULL, NULL, &err );

    if( !result )
    {
        if( err )
            g_error_free( err );
        return g_strdup( szText );
    }

    return result;
}

HB_FUNC( HWG_SETAPPLOCALE )
{
    const char *szLocale = hb_parc( 1 );
    int iLen = hb_parclen( 1 );

    hb_retc( szAppLocale );
    memcpy( szAppLocale, szLocale, iLen );
    szAppLocale[iLen] = '\0';
}


HB_FUNC( HWG_KEYTOUTF8 )
{
    char utf8string[10];
    int  iLen;

    iLen = g_unichar_to_utf8( gdk_keyval_to_unicode( hb_parnl( 1 ) ), utf8string );
    utf8string[iLen] = '\0';
    hb_retc( utf8string );
}

HB_FUNC( HWG_SEND_KEY )
{
    HB_SYMBOL_UNUSED( hb_parni( 2 ) );
    HB_SYMBOL_UNUSED( hb_parni( 3 ) );
}


HB_FUNC( HWG_SETMAXLENGTH )
{
    GtkWidget *w   = (GtkWidget*) HB_PARHANDLE( 1 );
    gint       max = hb_parni( 2 );

    if( !w || !GTK_IS_WIDGET( w ) || hwg_is_dead( (GObject*) w ) )
        return;

    if( GTK_IS_ENTRY( w ) )
        gtk_entry_set_max_length( GTK_ENTRY( w ), max );

    g_object_set_data( (GObject*) w, "hwg_maxlen", GINT_TO_POINTER( max ) );
}


HB_FUNC( HWG__ISUNICODE )
{
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    #ifdef UNICODE
    hb_retl( 1 );
    #else
    hb_retl( 0 );
    #endif
    #else
    hb_retl( 1 );
    #endif
}

HB_FUNC( HWG_WIDGET_GET_TOP )
{
    hb_retni( 0 );
}


static gboolean cb_key_snooper( GtkEventControllerKey *controller,
                                guint keyval, guint keycode,
                                GdkModifierType state, gpointer user_data )
{
    GtkWidget * window = GetActiveWindow();
    HB_LONG     p2;

    HB_SYMBOL_UNUSED( controller );
    HB_SYMBOL_UNUSED( keycode );
    HB_SYMBOL_UNUSED( user_data );

    if( window && !hwg_is_dead( (GObject*) window ) )
    {
        PHB_ITEM pObject = (PHB_ITEM) g_object_get_data( (GObject*) window, "obj" );
        if( !pSym_keylist )
            pSym_keylist = hb_dynsymFindName( "EVALKEYLIST" );

        if( pObject && pSym_keylist && hb_objHasMessage( pObject, pSym_keylist ) )
        {
            hb_vmPushSymbol( hb_dynsymSymbol( pSym_keylist ) );
            hb_vmPush( pObject );
            hb_vmPushLong( (HB_LONG) keyval );
            p2 = ( ( state & GDK_SHIFT_MASK )   ? 1 : 0 ) |
            ( ( state & GDK_CONTROL_MASK ) ? 2 : 0 ) |
            ( ( state & GDK_ALT_MASK )     ? 4 : 0 );
            hb_vmPushLong( (HB_LONG) p2 );
            hb_vmSend( 2 );
        }
    }
    return FALSE;
}

static GtkEventController *s_KeyCtl = NULL;

HB_FUNC( HWG_INITPROC )
{
    if( hMainWindow && !hwg_is_dead( (GObject*) hMainWindow ) )
    {
        s_KeyCtl = gtk_event_controller_key_new();
        gtk_event_controller_set_propagation_phase( s_KeyCtl, GTK_PHASE_CAPTURE );
        g_signal_connect( s_KeyCtl, "key-released",
                          G_CALLBACK( cb_key_snooper ), NULL );
        gtk_widget_add_controller( hMainWindow, s_KeyCtl );
    }
}

HB_FUNC( HWG_EXITPROC )
{
    if( s_KeyCtl && hMainWindow && !hwg_is_dead( (GObject*) hMainWindow ) )
    {
        gtk_widget_remove_controller( hMainWindow, s_KeyCtl );
        s_KeyCtl = NULL;
    }
}


HB_FUNC( HWG_DEICONIFY )
{
    GtkWindow *w = (GtkWindow*) HB_PARHANDLE( 1 );
    if( w && !hwg_is_dead( (GObject*) w ) )
        gtk_window_unminimize( w );
}

HB_FUNC( HWG_ICONIFY )
{
    GtkWindow *w = (GtkWindow*) HB_PARHANDLE( 1 );
    if( w && !hwg_is_dead( (GObject*) w ) )
        gtk_window_minimize( w );
}

HB_FUNC( HWG_PAINTWINDOW )
{
    GtkWidget *widget = (GtkWidget*) hb_parptr( 1 );
    if( widget && GTK_IS_WIDGET( widget ) && !hwg_is_dead( (GObject*) widget ) )
        gtk_widget_queue_draw( widget );
}

/* ================== EOF of window.c ========================== */
