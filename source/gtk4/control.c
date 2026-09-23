/*
 * $Id: control.c 3852 2026-08-16 20:42:12Z itamarlins $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Widget creation functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port — target: GTK 4.24+
 *
 * Port notes:
 *  - hwg_toggle_signal_block / hwg_combo_signal_block restore
 *    GTK2/Windows semantics for programmatic state changes.
 *  - "notify::active" is not a signal name; it is the "notify"
 *    signal with detail "active".
 *  - Zero-sized Get (phantom) stays ACTIVE via opacity 0.
 *  - HWG_EDIT_* functions guard G_IS_OBJECT + GTK_IS_WIDGET +
 *    GTK_IS_EDITABLE before touching the widget.  Handles that
 *    come from a destroyed widget (or from a non-editable one such
 *    as the browse drawing area) are silently ignored.
 *  - HWG_EDIT_SETTEXT / HWG_STATIC_SETTEXT / HWG_WRITESTATUSWINDOW
 *    skip set_text/set_label when the content is identical.
 *  - HWG_CREATEEDIT / HWG_CREATESTATIC set width_chars to 0.
 *  - The mouse-wheel event controller is installed ONLY on the
 *    GtkDrawingArea of a browse (HWG_CREATEBROWSE).
 *  - CSS theme loader (hwg_CssLoadFile) + widget class helpers
 *    (hwg_AddCssClass and friends) live at the end of this file.
 */

#include "guilib.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"

#include <cairo.h>
#include <glib.h>
#include <glib/gdatetime.h>
#include <gtk/gtk.h>
#include <gdk/gdkkeysyms.h>
#include "hwgtk4.h"
#include "hbdate.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif
#include "warnings.h"

#define SS_CENTER           1
#define SS_RIGHT            2
#define SS_ICON             3
#define ES_PASSWORD        32
#define ES_MULTILINE        4
#define ES_READONLY      2048
#define ES_CENTER           1
#define ES_RIGHT            2

#define BS_AUTO3STATE       6
#define BS_GROUPBOX         7
#define BS_AUTORADIOBUTTON  9

#define TCS_BOTTOM          2
#define SS_OWNERDRAW       13

#define WM_PAINT           15
#define WM_HSCROLL        276
#define WM_VSCROLL        277
#define WS_HSCROLL   0x00100000L
#define WS_VSCROLL   0x00200000L
#define WM_USER          1024
#define WS_EX_TRANSPARENT   32

#define HWG_ICON_SIZE_PX    16

extern void    hwg_install_widget_events( GtkWidget *widget, gboolean bDrawable );
extern HB_LONG hwg_dispatch_onevent    ( GtkWidget *widget, HB_LONG p1, HB_LONG p2, HB_LONG p3 );
extern gboolean cb_scroll              ( GtkEventControllerScroll *controller,
                                         double dx, double dy, gpointer user_data );

extern PHB_ITEM  GetObjectVar( PHB_ITEM pObject, char *varname );
extern void      SetObjectVar( PHB_ITEM pObject, char *varname, PHB_ITEM pValue );
extern void      SetWindowObject( GtkWidget * hWnd, PHB_ITEM pObject );
extern void      set_signal( gpointer handle, char *cSignal, long p1, long p2, long p3 );
extern void      set_event ( gpointer handle, char *cSignal, long p1, long p2, long p3 );
extern void      cb_signal ( GtkWidget *widget, gchar *data );
extern void      cb_signal_size( GtkWidget *widget, int w, int h, gpointer data );
extern void      all_signal_connect( gpointer hWnd );
extern GtkWidget *GetActiveWindow( void );
extern GdkPixbuf *alpha2pixbuf( GdkPixbuf *hPixIn, long int nColor );

static PHB_DYNS   pSymTimerProc = NULL;
static PHB_DYNS   pSym_onEvent  = NULL;
static GtkWidget *h4stock       = NULL;


/* =====================================================================
 *  Utility helpers
 * ===================================================================== */
GtkFixed *getFixedBox( GObject *handle )
{
    return (GtkFixed*) g_object_get_data( handle, "fbox" );
}

static void hwg_toggle_signal_block( GtkWidget *w, gboolean block )
{
    guint sig_id;

    if( !w || !G_IS_OBJECT( w ) )
        return;

    sig_id = g_signal_lookup( "toggled", G_OBJECT_TYPE( w ) );
    if( sig_id == 0 )
        return;

    if( block )
        g_signal_handlers_block_matched( w, G_SIGNAL_MATCH_ID,
                                         sig_id, 0, NULL, NULL, NULL );
        else
            g_signal_handlers_unblock_matched( w, G_SIGNAL_MATCH_ID,
                                               sig_id, 0, NULL, NULL, NULL );
}

static void hwg_combo_signal_block( GtkWidget *w, gboolean block )
{
    guint  sig_id;
    GQuark detail;

    if( !w || !G_IS_OBJECT( w ) )
        return;

    sig_id = g_signal_lookup( "notify", G_OBJECT_TYPE( w ) );
    if( sig_id == 0 )
        return;

    detail = g_quark_from_string( "active" );

    if( block )
        g_signal_handlers_block_matched( w,
                                         G_SIGNAL_MATCH_ID | G_SIGNAL_MATCH_DETAIL,
                                         sig_id, detail, NULL, NULL, NULL );
        else
            g_signal_handlers_unblock_matched( w,
                                               G_SIGNAL_MATCH_ID | G_SIGNAL_MATCH_DETAIL,
                                               sig_id, detail, NULL, NULL, NULL );
}

void hwg_colorN2C( unsigned int lColor, char *szColor )
{
    char c;
    sprintf( szColor, "%06x", lColor );
    c = szColor[0]; szColor[0] = szColor[4]; szColor[4] = c;
    c = szColor[1]; szColor[1] = szColor[5]; szColor[5] = c;
}

void set_css_data( char *szData )
{
    GtkCssProvider *provider = gtk_css_provider_new();
    GdkDisplay     *display  = gdk_display_get_default();

    gtk_css_provider_load_from_data( provider, szData, -1 );
    gtk_style_context_add_provider_for_display(
        display,
        GTK_STYLE_PROVIDER( provider ),
                                               GTK_STYLE_PROVIDER_PRIORITY_APPLICATION );

    g_object_unref( provider );
}

GtkWidget *getDrawing( GObject *handle )
{
    return (GtkWidget*) g_object_get_data( handle, "draw" );
}

HB_FUNC( HWG_GETDRAWING )
{
    HB_RETHANDLE( getDrawing( (GObject*) HB_PARHANDLE( 1 ) ) );
}


/* =====================================================================
 *  HWG_STOCKBITMAP
 * ===================================================================== */
HB_FUNC( HWG_STOCKBITMAP )
{
    PHWGUI_PIXBUF     hpix;
    GdkPixbuf        *handle = NULL;
    GtkIconTheme     *theme;
    GtkIconPaintable *paintable;

    HB_SYMBOL_UNUSED( h4stock );

    theme = gtk_icon_theme_get_for_display( gdk_display_get_default() );

    paintable = gtk_icon_theme_lookup_icon( theme, hb_parc(1),
                                            NULL,
                                            HWG_ICON_SIZE_PX,
                                            1,
                                            GTK_TEXT_DIR_NONE,
                                            GTK_ICON_LOOKUP_FORCE_REGULAR );

    if( paintable )
    {
        int width  = gdk_paintable_get_intrinsic_width( GDK_PAINTABLE( paintable ) );
        int height = gdk_paintable_get_intrinsic_height( GDK_PAINTABLE( paintable ) );

        if( width > 0 && height > 0 )
        {
            cairo_surface_t *surface = cairo_image_surface_create( CAIRO_FORMAT_ARGB32, width, height );
            GtkSnapshot *snapshot = gtk_snapshot_new();
            GskRenderNode *node;
            cairo_t *cr;
            GBytes *bytes;
            GdkTexture *texture;

            gdk_paintable_snapshot( GDK_PAINTABLE( paintable ), snapshot, width, height );
            node = gtk_snapshot_free_to_node( snapshot );
            cr = cairo_create( surface );
            gsk_render_node_draw( node, cr );
            cairo_destroy( cr );
            gsk_render_node_unref( node );

            bytes = g_bytes_new_with_free_func(
                cairo_image_surface_get_data( surface ),
                                               cairo_image_surface_get_height( surface ) * cairo_image_surface_get_stride( surface ),
                                               (GDestroyNotify) cairo_surface_destroy,
                                               cairo_surface_reference( surface ) );

            texture = gdk_memory_texture_new(
                cairo_image_surface_get_width( surface ),
                                             cairo_image_surface_get_height( surface ),
                                             GDK_MEMORY_DEFAULT,
                                             bytes,
                                             cairo_image_surface_get_stride( surface ) );

            g_bytes_unref( bytes );
            cairo_surface_destroy( surface );

            if( texture )
            {
                handle = gdk_pixbuf_get_from_texture( texture );
                g_object_unref( texture );
            }
        }
        g_object_unref( paintable );
    }

    if( !handle )
    {
        hb_ret();
        return;
    }

    hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
    hpix->type    = HWGUI_OBJECT_PIXBUF;
    hpix->handle  = handle;
    hpix->trcolor = -1;
    HB_RETHANDLE( hpix );
}


/* =====================================================================
 *  HWG_CREATESTATIC
 * ===================================================================== */
HB_FUNC( HWG_CREATESTATIC )
{
    HB_ULONG    ulStyle    = hb_parnl( 3 );
    const char *cTitle     = ( hb_pcount() > 8 ) ? hb_parc( 9 ) : "";
    GtkWidget  *hCtrl;
    GtkFixed   *box;
    HB_ULONG    ulExtStyle = hb_parnl( 8 );

    if( ( ulStyle & SS_OWNERDRAW ) == SS_OWNERDRAW )
    {
        hCtrl = gtk_drawing_area_new();
        g_object_set_data( (GObject*) hCtrl, "draw", (gpointer) hCtrl );
        (void) hwg_install_widget_events( hCtrl, TRUE );
    }
    else if( ( ulStyle & SS_ICON ) == SS_ICON )
    {
        hCtrl = gtk_image_new();
        gtk_widget_set_halign( hCtrl, GTK_ALIGN_START );
        gtk_widget_set_valign( hCtrl, GTK_ALIGN_START );
        g_object_set_data( (GObject*) hCtrl, "icon", (gpointer) 1 );
    }
    else
    {
        gchar *gcTitle = hwg_convert_to_utf8( cTitle );
        hCtrl = gtk_label_new( gcTitle );
        g_free( gcTitle );

        gtk_label_set_xalign( GTK_LABEL( hCtrl ),
                              ( ulStyle & SS_RIGHT )  ? 1.0 :
                              ( ( ulStyle & SS_CENTER ) ? 0.5 : 0.0 ) );
        gtk_label_set_yalign( GTK_LABEL( hCtrl ), 0.0 );

        if( ulExtStyle & WS_EX_TRANSPARENT )
            gtk_widget_set_opacity( hCtrl, 1.0 );

        g_object_set_data( (GObject*) hCtrl, "label", (gpointer) hCtrl );
    }

    box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
    gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

    if( GTK_IS_LABEL( hCtrl ) )
    {
        gtk_label_set_width_chars( GTK_LABEL( hCtrl ), 0 );
        gtk_label_set_max_width_chars( GTK_LABEL( hCtrl ), 0 );
        gtk_label_set_ellipsize( GTK_LABEL( hCtrl ), PANGO_ELLIPSIZE_NONE );
    }

    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_STATIC_SETTEXT )
{
    gchar    *gcTitle = hwg_convert_to_utf8( hb_parcx( 2 ) );
    GtkLabel *hLabel  = (GtkLabel*) g_object_get_data( (GObject*) HB_PARHANDLE( 1 ),
                                                       "label" );
    if( hLabel && GTK_IS_LABEL( hLabel ) )
    {
        const gchar *cur = gtk_label_get_text( hLabel );
        if( !cur || strcmp( cur, gcTitle ) != 0 )
            gtk_label_set_text( hLabel, gcTitle );
    }
    g_free( gcTitle );
}

HB_FUNC( HWG_STATIC_GETTEXT )
{
    GtkLabel *hLabel = (GtkLabel*) g_object_get_data( (GObject*) HB_PARHANDLE( 1 ),
                                                      "label" );
    if( hLabel && GTK_IS_LABEL( hLabel ) )
        hb_retc( (char*) gtk_label_get_text( hLabel ) );
    else
        hb_retc( "" );
}

HB_FUNC( HWG_STATICSETIMAGE )
{
    GtkWidget *hCtrl   = (GtkWidget*) HB_PARHANDLE( 1 );
    GdkPixbuf *hPixbuf = (GdkPixbuf*) HB_PARHANDLE( 2 );

    if( !hCtrl || !GTK_IS_IMAGE( hCtrl ) )
        return;

    if( hPixbuf && GDK_IS_PIXBUF( hPixbuf ) )
        gtk_image_set_from_pixbuf( GTK_IMAGE( hCtrl ), hPixbuf );
    else
        gtk_image_clear( GTK_IMAGE( hCtrl ) );
}


/* =====================================================================
 *  Checkbox / Radio keyboard navigation
 * ===================================================================== */
static gboolean hwg_button_key_press_ctrl( GtkEventControllerKey *controller,
                                           guint keyval, guint keycode,
                                           GdkModifierType state, gpointer user_data )
{
    GtkWidget *widget = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( controller ) );

    HB_SYMBOL_UNUSED( keycode );
    HB_SYMBOL_UNUSED( state );
    HB_SYMBOL_UNUSED( user_data );

    if( keyval == GDK_KEY_Tab || keyval == GDK_KEY_KP_Tab )
    {
        GtkRoot *root = gtk_widget_get_root( widget );
        if( root )
            return gtk_widget_child_focus( GTK_WIDGET( root ), GTK_DIR_TAB_FORWARD );
    }
    return FALSE;
}

static void hwg_attach_checkbox_nav( GtkWidget *w )
{
    GtkEventController *ctl = gtk_event_controller_key_new();
    g_signal_connect( ctl, "key-pressed",
                      G_CALLBACK( hwg_button_key_press_ctrl ), NULL );
    gtk_widget_add_controller( w, ctl );
}


/* =====================================================================
 *  HWG_CREATEBUTTON
 * ===================================================================== */
HB_FUNC( HWG_CREATEBUTTON )
{
    GtkWidget  *hCtrl;
    HB_ULONG    ulStyle = hb_parnl( 3 );
    const char *cTitle  = ( hb_pcount() > 7 ) ? hb_parc( 8 ) : "";
    GtkFixed   *box;
    PHWGUI_PIXBUF hImg = HB_ISPOINTER( 9 )
    ? (PHWGUI_PIXBUF) HB_PARHANDLE( 9 ) : NULL;
    gchar *gcTitle = hwg_convert_to_utf8( cTitle );

    if( ( ulStyle & 0xf ) == BS_AUTORADIOBUTTON )
    {
        GtkCheckButton *group = (GtkCheckButton*) HB_PARHANDLE( 2 );

        hCtrl = gtk_check_button_new_with_label( gcTitle );

        if( group && GTK_IS_CHECK_BUTTON( group ) )
        {
            gtk_check_button_set_group( GTK_CHECK_BUTTON( hCtrl ), group );
        }
        else
        {
            HB_STOREHANDLE( GTK_CHECK_BUTTON( hCtrl ), 2 );
        }

        gtk_widget_set_can_focus( hCtrl, TRUE );
    }
    else if( ( ulStyle & 0xf ) == BS_AUTO3STATE )
    {
        hCtrl = gtk_check_button_new_with_label( gcTitle );
        gtk_widget_set_can_focus( hCtrl, TRUE );
        hwg_attach_checkbox_nav( hCtrl );
    }
    else if( ( ulStyle & 0xf ) == BS_GROUPBOX )
    {
        hCtrl = gtk_frame_new( gcTitle );
        gtk_widget_set_can_focus( hCtrl, FALSE );
    }
    else
    {
        hCtrl = gtk_button_new_with_mnemonic( gcTitle );
        gtk_widget_set_can_focus( hCtrl, TRUE );
    }

    if( hImg )
    {
        GtkWidget *img = gtk_image_new_from_pixbuf( hImg->handle );
        if( GTK_IS_CHECK_BUTTON( hCtrl ) )
            gtk_check_button_set_child( GTK_CHECK_BUTTON( hCtrl ), img );
        else if( GTK_IS_BUTTON( hCtrl ) )
            gtk_button_set_child( GTK_BUTTON( hCtrl ), img );
    }

    g_free( gcTitle );

    box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
    gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_BUTTON_SETIMAGE )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    PHWGUI_PIXBUF hImg = HB_ISPOINTER( 2 )
    ? (PHWGUI_PIXBUF) HB_PARHANDLE( 2 ) : NULL;

    if( !hImg || !hCtrl )
        return;

    if( GTK_IS_CHECK_BUTTON( hCtrl ) )
        gtk_check_button_set_child( GTK_CHECK_BUTTON( hCtrl ),
                                    gtk_image_new_from_pixbuf( hImg->handle ) );
        else if( GTK_IS_BUTTON( hCtrl ) )
            gtk_button_set_child( GTK_BUTTON( hCtrl ),
                                  gtk_image_new_from_pixbuf( hImg->handle ) );
}

HB_FUNC( HWG_BUTTON_SETTEXT )
{
    gchar *gcTitle = hwg_convert_to_utf8( hb_parcx( 2 ) );
    GtkWidget *hBtn = (GtkWidget*) HB_PARHANDLE( 1 );

    if( !hBtn )
    {
        g_free( gcTitle );
        return;
    }

    if( GTK_IS_CHECK_BUTTON( hBtn ) )
        gtk_check_button_set_label( GTK_CHECK_BUTTON( hBtn ), gcTitle );
    else if( GTK_IS_BUTTON( hBtn ) )
        gtk_button_set_label( GTK_BUTTON( hBtn ), gcTitle );

    g_free( gcTitle );
}

HB_FUNC( HWG_BUTTON_GETTEXT )
{
    GtkWidget *hBtn = (GtkWidget*) HB_PARHANDLE( 1 );
    const char *cLabel = NULL;

    if( !hBtn )
    {
        hb_retc( "" );
        return;
    }

    if( GTK_IS_CHECK_BUTTON( hBtn ) )
        cLabel = gtk_check_button_get_label( GTK_CHECK_BUTTON( hBtn ) );
    else if( GTK_IS_BUTTON( hBtn ) )
        cLabel = gtk_button_get_label( GTK_BUTTON( hBtn ) );

    hb_retc( cLabel ? (char*) cLabel : "" );
}

HB_FUNC( HWG_CHECKBUTTON )
{
    GtkWidget *w      = (GtkWidget*) HB_PARHANDLE( 1 );
    gboolean   active = hb_parl( 2 );

    if( !w )
        return;

    if( GTK_IS_CHECK_BUTTON( w ) )
    {
        hwg_toggle_signal_block( w, TRUE );
        gtk_check_button_set_active( GTK_CHECK_BUTTON( w ), active );
        hwg_toggle_signal_block( w, FALSE );
    }
    else if( GTK_IS_TOGGLE_BUTTON( w ) )
    {
        hwg_toggle_signal_block( w, TRUE );
        gtk_toggle_button_set_active( GTK_TOGGLE_BUTTON( w ), active );
        hwg_toggle_signal_block( w, FALSE );
    }
}

HB_FUNC( HWG_ISBUTTONCHECKED )
{
    GtkWidget *w = (GtkWidget*) HB_PARHANDLE( 1 );

    if( !w )
    {
        hb_retl( FALSE );
        return;
    }

    if( GTK_IS_CHECK_BUTTON( w ) )
        hb_retl( gtk_check_button_get_active( GTK_CHECK_BUTTON( w ) ) );
    else if( GTK_IS_TOGGLE_BUTTON( w ) )
        hb_retl( gtk_toggle_button_get_active( GTK_TOGGLE_BUTTON( w ) ) );
    else
        hb_retl( FALSE );
}


/* =====================================================================
 *  HWG_CREATEEDIT
 * ===================================================================== */
HB_FUNC( HWG_CREATEEDIT )
{
    GtkWidget *hCtrl;
    GtkWidget *hScroll = NULL;
    const char *cTitle = ( hb_pcount() > 7 ) ? hb_parc( 8 ) : "";
    unsigned long ulStyle = HB_ISNIL(3) ? 0 : hb_parnl( 3 );
    gint nW = hb_parni( 6 );
    gint nH = hb_parni( 7 );

    if( ulStyle & ES_MULTILINE )
    {
        hCtrl = gtk_text_view_new();
        g_object_set_data( (GObject*) hCtrl, "multi", (gpointer) 1 );

        if( ulStyle & ES_READONLY )
            gtk_text_view_set_editable( GTK_TEXT_VIEW( hCtrl ), FALSE );

        gtk_text_view_set_wrap_mode( GTK_TEXT_VIEW( hCtrl ),
                                     ( ulStyle & WS_HSCROLL ) ? GTK_WRAP_NONE : GTK_WRAP_WORD_CHAR );

        hScroll = gtk_scrolled_window_new();
        gtk_scrolled_window_set_policy( GTK_SCROLLED_WINDOW( hScroll ),
                                        ( ulStyle & WS_HSCROLL ) ? GTK_POLICY_ALWAYS : GTK_POLICY_AUTOMATIC,
                                        ( ulStyle & WS_VSCROLL ) ? GTK_POLICY_ALWAYS : GTK_POLICY_AUTOMATIC );

        gtk_scrolled_window_set_has_frame( GTK_SCROLLED_WINDOW( hScroll ), TRUE );
        gtk_scrolled_window_set_child( GTK_SCROLLED_WINDOW( hScroll ), hCtrl );

        g_object_set_data( (GObject*) hCtrl, "main_widget", (gpointer) hScroll );
    }
    else
    {
        hCtrl = gtk_entry_new();
        if( ulStyle & ES_PASSWORD )
            gtk_entry_set_visibility( GTK_ENTRY( hCtrl ), FALSE );
        if( ulStyle & ES_RIGHT )
            gtk_editable_set_alignment( GTK_EDITABLE( hCtrl ), 1.0f );
    }

    {
        GtkFixed *box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
        if( box )
        {
            if( ( ulStyle & ES_MULTILINE ) && hScroll )
                gtk_fixed_put( box, hScroll, hb_parni( 4 ), hb_parni( 5 ) );
            else
                gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
        }
    }

    if( ( ulStyle & ES_MULTILINE ) && hScroll )
        gtk_widget_set_size_request( hScroll, nW, nH );
    else
        gtk_widget_set_size_request( hCtrl, nW, nH );

    if( !( ulStyle & ES_MULTILINE ) )
    {
        gtk_editable_set_width_chars( GTK_EDITABLE( hCtrl ), 0 );
        gtk_editable_set_max_width_chars( GTK_EDITABLE( hCtrl ), 0 );
        gtk_editable_set_alignment( GTK_EDITABLE( hCtrl ),
                                    ( ulStyle & ES_RIGHT ) ? 1.0f : 0.0f );
    }

    if( *cTitle )
    {
        gchar *gcTitle = hwg_convert_to_utf8( cTitle );
        if( ulStyle & ES_MULTILINE )
        {
            GtkTextBuffer *buffer = gtk_text_view_get_buffer( GTK_TEXT_VIEW( hCtrl ) );
            gtk_text_buffer_set_text( buffer, gcTitle, -1 );
        }
        else
        {
            gtk_editable_set_text( GTK_EDITABLE( hCtrl ), gcTitle );
        }
        g_free( gcTitle );
    }

    (void) hwg_install_widget_events( hCtrl, FALSE );

    if( nW <= 1 || nH <= 1 )
        gtk_widget_set_opacity( hCtrl, 0.0 );

    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_EDIT_SETTEXT )
{
    GtkWidget   *hCtrl  = (GtkWidget*) HB_PARHANDLE( 1 );
    gchar       *gcText;
    const gchar *cur;

    if( !hCtrl || !G_IS_OBJECT( hCtrl ) || !GTK_IS_WIDGET( hCtrl ) )
        return;

    gcText = hwg_convert_to_utf8( hb_parcx( 2 ) );

    if( g_object_get_data( (GObject*) hCtrl, "multi" ) )
    {
        if( GTK_IS_TEXT_VIEW( hCtrl ) )
        {
            GtkTextBuffer *buffer = gtk_text_view_get_buffer( GTK_TEXT_VIEW( hCtrl ) );
            gtk_text_buffer_set_text( buffer, gcText, -1 );
        }
    }
    else
    {
        if( GTK_IS_EDITABLE( hCtrl ) )
        {
            cur = gtk_editable_get_text( GTK_EDITABLE( hCtrl ) );
            if( !cur || strcmp( cur, gcText ) != 0 )
                gtk_editable_set_text( GTK_EDITABLE( hCtrl ), gcText );
        }
    }

    g_free( gcText );
}

HB_FUNC( HWG_EDIT_GETTEXT )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    char *cptr = NULL;

    if( !hCtrl || !G_IS_OBJECT( hCtrl ) || !GTK_IS_WIDGET( hCtrl ) )
    {
        hb_retc( "" );
        return;
    }

    if( g_object_get_data( (GObject*) hCtrl, "multi" ) )
    {
        if( GTK_IS_TEXT_VIEW( hCtrl ) )
        {
            GtkTextBuffer *buffer = gtk_text_view_get_buffer( GTK_TEXT_VIEW( hCtrl ) );
            GtkTextIter iterStart, iterEnd;
            gtk_text_buffer_get_start_iter( buffer, &iterStart );
            gtk_text_buffer_get_end_iter( buffer, &iterEnd );
            cptr = gtk_text_buffer_get_text( buffer, &iterStart, &iterEnd, TRUE );
        }
    }
    else
    {
        if( GTK_IS_EDITABLE( hCtrl ) )
            cptr = (char*) gtk_editable_get_text( GTK_EDITABLE( hCtrl ) );
    }

    if( cptr && *cptr )
    {
        cptr = hwg_convert_from_utf8( cptr );
        hb_retc( cptr );
        g_free( cptr );
    }
    else
    {
        hb_retc( "" );
    }
}

HB_FUNC( HWG_EDIT_SETPOS )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );

    if( !hCtrl || !G_IS_OBJECT( hCtrl ) ||
        !GTK_IS_WIDGET( hCtrl ) || !GTK_IS_EDITABLE( hCtrl ) )
        return;

    gtk_editable_set_position( GTK_EDITABLE( hCtrl ), hb_parni( 2 ) - 1 );
}

HB_FUNC( HWG_EDIT_GETPOS )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );

    if( !hCtrl || !G_IS_OBJECT( hCtrl ) ||
        !GTK_IS_WIDGET( hCtrl ) || !GTK_IS_EDITABLE( hCtrl ) )
    {
        hb_retni( 0 );
        return;
    }

    hb_retni( gtk_editable_get_position( GTK_EDITABLE( hCtrl ) ) + 1 );
}

HB_FUNC( HWG_EDIT_GETSELPOS )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    gint start, end;

    if( !hCtrl || !G_IS_OBJECT( hCtrl ) ||
        !GTK_IS_WIDGET( hCtrl ) || !GTK_IS_EDITABLE( hCtrl ) )
        return;

    if( gtk_editable_get_selection_bounds( GTK_EDITABLE( hCtrl ), &start, &end ) )
    {
        PHB_ITEM aSel = hb_itemArrayNew( 2 );
        PHB_ITEM temp;

        temp = hb_itemPutNL( NULL, start );
        hb_itemArrayPut( aSel, 1, temp ); hb_itemRelease( temp );
        temp = hb_itemPutNL( NULL, end );
        hb_itemArrayPut( aSel, 2, temp ); hb_itemRelease( temp );

        hb_itemReturn( aSel );
        hb_itemRelease( aSel );
    }
}

HB_FUNC( HWG_EDIT_SET_OVERMODE )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    gboolean bOver = FALSE;

    if( !hCtrl || !G_IS_OBJECT( hCtrl ) || !GTK_IS_WIDGET( hCtrl ) )
    {
        hb_retl( FALSE );
        return;
    }

    if( g_object_get_data( (GObject*) hCtrl, "multi" ) )
    {
        if( GTK_IS_TEXT_VIEW( hCtrl ) )
        {
            bOver = gtk_text_view_get_overwrite( GTK_TEXT_VIEW( hCtrl ) );
            if( !HB_ISNIL( 2 ) )
                gtk_text_view_set_overwrite( GTK_TEXT_VIEW( hCtrl ), hb_parl( 2 ) );
        }
    }
    else
    {
        if( GTK_IS_ENTRY( hCtrl ) )
        {
            bOver = gtk_entry_get_overwrite_mode( GTK_ENTRY( hCtrl ) );
            if( !HB_ISNIL( 2 ) )
                gtk_entry_set_overwrite_mode( GTK_ENTRY( hCtrl ), hb_parl( 2 ) );
        }
    }
    hb_retl( bOver );
}


/* =====================================================================
 *  HWG_CREATECOMBO
 * ===================================================================== */
HB_FUNC( HWG_CREATECOMBO )
{
    GtkWidget *hCtrl;
    GtkWidget *entry = NULL;
    gint iText = ( ( hb_parni( 3 ) & 1 ) == 0 );
    GtkFixed *box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );

    hCtrl = gtk_combo_box_text_new_with_entry();
    if( !iText )
    {
        entry = gtk_combo_box_get_child( GTK_COMBO_BOX( hCtrl ) );
        if( entry )
            gtk_editable_set_editable( GTK_EDITABLE( entry ), FALSE );
    }
    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
    gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

    (void) hwg_install_widget_events( hCtrl, FALSE );
    entry = gtk_combo_box_get_child( GTK_COMBO_BOX( hCtrl ) );
    if( entry && GTK_IS_WIDGET( entry ) )
        (void) hwg_install_widget_events( entry, FALSE );

    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_COMBOSETARRAY )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    PHB_ITEM   pArray = hb_param( 2, HB_IT_ARRAY );
    HB_ULONG   ulKol;

    if( pArray )
    {
        HB_ULONG ul, ulLen = hb_arrayLen( pArray );
        char *cItem;

        ulKol = (HB_ULONG) GPOINTER_TO_SIZE(
            g_object_get_data( (GObject*) hCtrl, "kol" ) );

        for( ul = 1; ul <= ulKol; ++ul )
            gtk_combo_box_text_remove( GTK_COMBO_BOX_TEXT( hCtrl ), 0 );

        for( ul = 1; ul <= ulLen; ++ul )
        {
            if( hb_arrayGetType( pArray, ul ) & HB_IT_ARRAY )
                cItem = hwg_convert_to_utf8(
                    hb_arrayGetCPtr( hb_arrayGetItemPtr( pArray, ul ), 1 ) );
                else
                    cItem = hwg_convert_to_utf8( hb_arrayGetCPtr( pArray, ul ) );

            gtk_combo_box_text_append( GTK_COMBO_BOX_TEXT( hCtrl ), NULL, cItem );
            g_free( cItem );
        }
        g_object_set_data( (GObject*) hCtrl, "kol",
                           GSIZE_TO_POINTER( ulLen ) );
    }
}

HB_FUNC( HWG_COMBOSET )
{
    GtkWidget *w = (GtkWidget*) HB_PARHANDLE( 1 );

    if( !w || !GTK_IS_COMBO_BOX( w ) )
        return;

    hwg_combo_signal_block( w, TRUE );
    gtk_combo_box_set_active( GTK_COMBO_BOX( w ), hb_parni( 2 ) - 1 );
    hwg_combo_signal_block( w, FALSE );
}

HB_FUNC( HWG_COMBOGET )
{
    gint i = gtk_combo_box_get_active( GTK_COMBO_BOX( HB_PARHANDLE( 1 ) ) ) + 1;
    if( i <= 0 ) i = 1;
    hb_retni( i );
}

HB_FUNC( HWG_COMBOPOPUP )
{
    gtk_combo_box_popup( GTK_COMBO_BOX( HB_PARHANDLE( 1 ) ) );
}


/* =====================================================================
 *  HWG_CREATEUPDOWNCONTROL
 * ===================================================================== */
HB_FUNC( HWG_CREATEUPDOWNCONTROL )
{
    GtkAdjustment *adj;
    GtkWidget     *hCtrl;
    GtkFixed      *box;

    adj = gtk_adjustment_new( (gdouble) hb_parnl( 6 ),
                              (gdouble) hb_parnl( 7 ),
                              (gdouble) hb_parnl( 8 ),
                              1, 1, 0 );

    hCtrl = gtk_spin_button_new( adj, 0.5, 0 );

    box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 2 ), hb_parni( 3 ) );
    gtk_widget_set_size_request( hCtrl, hb_parni( 4 ), hb_parni( 5 ) );

    (void) hwg_install_widget_events( hCtrl, FALSE );

    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_SETUPDOWN )
{
    gtk_spin_button_set_value( GTK_SPIN_BUTTON( HB_PARHANDLE( 1 ) ),
                               (gdouble) hb_parnl( 2 ) );
}

HB_FUNC( HWG_GETUPDOWN )
{
    hb_retnl( gtk_spin_button_get_value_as_int(
        GTK_SPIN_BUTTON( HB_PARHANDLE( 1 ) ) ) );
}

HB_FUNC( HWG_SETRANGEUPDOWN )
{
    gtk_spin_button_set_range( GTK_SPIN_BUTTON( HB_PARHANDLE( 1 ) ),
                               (gdouble) hb_parnl( 2 ),
                               (gdouble) hb_parnl( 3 ) );
}


/* =====================================================================
 *  HWG_CREATEBROWSE
 * ===================================================================== */
HB_FUNC( HWG_CREATEBROWSE )
{
    GtkWidget *vbox, *hbox;
    GtkWidget *vscroll = NULL, *hscroll = NULL;
    GtkWidget *area;
    GtkFixed  *box;
    PHB_ITEM   pObject = hb_param( 1, HB_IT_OBJECT ), temp;
    GObject   *handle;
    int nLeft   = hb_itemGetNI( GetObjectVar( pObject, "NLEFT" ) );
    int nTop    = hb_itemGetNI( GetObjectVar( pObject, "NTOP" ) );
    int nWidth  = hb_itemGetNI( GetObjectVar( pObject, "NWIDTH" ) );
    int nHeight = hb_itemGetNI( GetObjectVar( pObject, "NHEIGHT" ) );
    unsigned long int ulStyle =
    hb_itemGetNL( GetObjectVar( pObject, "STYLE" ) );

    temp   = GetObjectVar( pObject, "OPARENT" );
    handle = (GObject*) HB_GETHANDLE( GetObjectVar( temp, "HANDLE" ) );

    hbox = gtk_box_new( GTK_ORIENTATION_HORIZONTAL, 0 );
    vbox = gtk_box_new( GTK_ORIENTATION_VERTICAL,   0 );
    area = gtk_drawing_area_new();

    gtk_widget_set_hexpand( vbox, TRUE );
    gtk_widget_set_vexpand( vbox, TRUE );
    gtk_widget_set_hexpand( area, TRUE );
    gtk_widget_set_vexpand( area, TRUE );

    gtk_box_append( GTK_BOX( hbox ), vbox );

    if( ulStyle & WS_VSCROLL )
    {
        GtkAdjustment *adjV = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
        vscroll = gtk_scrollbar_new( GTK_ORIENTATION_VERTICAL, adjV );
        gtk_widget_set_size_request( vscroll, 16, -1 );
        gtk_box_append( GTK_BOX( hbox ), vscroll );

        temp = HB_PUTHANDLE( NULL, adjV );
        SetObjectVar( pObject, "_HSCROLLV", temp );
        hb_itemRelease( temp );

        SetWindowObject( (GtkWidget*) adjV, pObject );
        set_signal( (gpointer) adjV, "value-changed", WM_VSCROLL, 0, 0 );
    }

    gtk_box_append( GTK_BOX( vbox ), area );

    if( ulStyle & WS_HSCROLL )
    {
        GtkAdjustment *adjH = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
        hscroll = gtk_scrollbar_new( GTK_ORIENTATION_HORIZONTAL, adjH );
        gtk_widget_set_size_request( hscroll, -1, 16 );
        gtk_box_append( GTK_BOX( vbox ), hscroll );

        temp = HB_PUTHANDLE( NULL, adjH );
        SetObjectVar( pObject, "_HSCROLLH", temp );
        hb_itemRelease( temp );

        SetWindowObject( (GtkWidget*) adjH, pObject );
        set_signal( (gpointer) adjH, "value-changed", WM_HSCROLL, 0, 0 );
    }

    box = getFixedBox( handle );
    if( box )
        gtk_fixed_put( box, hbox, nLeft, nTop );

    gtk_widget_set_size_request( hbox, nWidth, nHeight );

    temp = HB_PUTHANDLE( NULL, area );
    SetObjectVar( pObject, "_AREA", temp );
    hb_itemRelease( temp );

    SetWindowObject( area, pObject );

    gtk_widget_set_can_focus( area, TRUE );
    gtk_widget_set_focusable( area, TRUE );
    (void) hwg_install_widget_events( area, TRUE );

    /*
     * Mouse wheel is installed ONLY on the browse's drawing area.
     * The controller is NOT installed globally in
     * hwg_install_widget_events -- doing that made the input method
     * of any focused GtkEntry insert literal characters ('x') when
     * the wheel was turned over a text field.
     */
    {
        GtkEventController *scroll;
        scroll = gtk_event_controller_scroll_new(
            GTK_EVENT_CONTROLLER_SCROLL_VERTICAL );
        g_signal_connect( scroll, "scroll", G_CALLBACK( cb_scroll ), NULL );
        gtk_widget_add_controller( area, scroll );
    }

    g_object_set_data( (GObject*) hbox, "draw", (gpointer) area );

    HB_RETHANDLE( hbox );
}

HB_FUNC( HWG_GETADJVALUE )
{
    GtkAdjustment *adj = (GtkAdjustment*) HB_PARHANDLE( 1 );
    int iOption = HB_ISNIL( 2 ) ? 0 : hb_parni( 2 );

    if( adj && GTK_IS_ADJUSTMENT( adj ) )
    {
        switch( iOption ) {
            case 0: hb_retnl( (HB_LONG) gtk_adjustment_get_value(adj) ); break;
            case 1: hb_retnl( (HB_LONG) gtk_adjustment_get_upper(adj) ); break;
            case 2: hb_retnl( (HB_LONG) gtk_adjustment_get_step_increment(adj) ); break;
            case 3: hb_retnl( (HB_LONG) gtk_adjustment_get_page_increment(adj) ); break;
            case 4: hb_retnl( (HB_LONG) gtk_adjustment_get_page_size(adj) ); break;
            default: hb_retnl( 0 );
        }
    }
    else hb_retnl( 0 );
}

HB_FUNC( HWG_SETADJOPTIONS )
{
    GtkAdjustment *adj = (GtkAdjustment*) HB_PARHANDLE( 1 );
    gdouble value;
    int     lChanged = 0;

    if( adj && GTK_IS_ADJUSTMENT( adj ) )
    {
        g_object_freeze_notify( G_OBJECT( adj ) );

        if( !HB_ISNIL(2) && ( (value = (gdouble) hb_parnl(2)) != gtk_adjustment_get_value(adj) ) )
        { gtk_adjustment_set_value(adj, value); lChanged = 1; }
        if( !HB_ISNIL(3) && ( (value = (gdouble) hb_parnl(3)) != gtk_adjustment_get_upper(adj) ) )
        { gtk_adjustment_set_upper(adj, value); lChanged = 1; }
        if( !HB_ISNIL(4) && ( (value = (gdouble) hb_parnl(4)) != gtk_adjustment_get_step_increment(adj) ) )
        { gtk_adjustment_set_step_increment(adj, value); lChanged = 1; }
        if( !HB_ISNIL(5) && ( (value = (gdouble) hb_parnl(5)) != gtk_adjustment_get_page_increment(adj) ) )
        { gtk_adjustment_set_page_increment(adj, value); lChanged = 1; }
        if( !HB_ISNIL(6) && ( (value = (gdouble) hb_parnl(6)) != gtk_adjustment_get_page_size(adj) ) )
        { gtk_adjustment_set_page_size(adj, value); lChanged = 1; }

        g_object_thaw_notify( G_OBJECT( adj ) );
        hb_retl( lChanged );
    }
    else hb_retl( FALSE );
}


/* =====================================================================
 *  Tabs
 * ===================================================================== */
static void hwg_tab_disabled_free( gpointer data )
{
    if( data ) g_array_free( (GArray*) data, TRUE );
}

static GArray *hwg_tab_disabled_get( GtkNotebook *nb )
{
    GArray *arr = (GArray*) g_object_get_data( (GObject*) nb, "hwg_tab_disabled" );
    if( !arr ) {
        arr = g_array_new( FALSE, TRUE, sizeof(gboolean) );
        g_object_set_data_full( (GObject*) nb, "hwg_tab_disabled",
                                arr, hwg_tab_disabled_free );
    }
    return arr;
}

static void hwg_tab_disabled_ensure( GtkNotebook *nb, guint nPages )
{
    GArray *arr = hwg_tab_disabled_get( nb );
    while( arr->len < nPages ) {
        gboolean b = FALSE;
        g_array_append_val( arr, b );
    }
}

static void cb_tablabel_click( GtkGestureClick *gesture, int n_press,
                               double x, double y, gpointer user_data )
{
    GtkWidget    *w  = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( gesture ) );
    GtkNotebook  *nb = (GtkNotebook*) user_data;
    guint         idx = GPOINTER_TO_UINT(
        g_object_get_data( (GObject*) w, "hwg_tab_idx" ) );

    HB_SYMBOL_UNUSED( n_press );
    HB_SYMBOL_UNUSED( x );
    HB_SYMBOL_UNUSED( y );

    if( nb ) {
        GArray *arr = (GArray*) g_object_get_data( (GObject*) nb, "hwg_tab_disabled" );
        if( arr && idx < arr->len &&
            g_array_index( arr, gboolean, idx ) )
        {
            gtk_gesture_set_state( GTK_GESTURE( gesture ), GTK_EVENT_SEQUENCE_CLAIMED );
        }
    }
}

void cb_signal_tab( GtkNotebook *notebook, GtkWidget *page,
                    guint page_num, gpointer user_data )
{
    gpointer gObject = g_object_get_data( (GObject*) notebook, "obj" );
    GArray  *arr = (GArray*) g_object_get_data( (GObject*) notebook, "hwg_tab_disabled" );

    HB_SYMBOL_UNUSED( page );
    HB_SYMBOL_UNUSED( user_data );

    if( arr && page_num < arr->len ) {
        gboolean disabled = g_array_index( arr, gboolean, page_num );
        if( disabled ) {
            g_signal_stop_emission_by_name( notebook, "switch-page" );
            return;
        }
    }

    if( !pSym_onEvent )
        pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

    if( pSym_onEvent && gObject ) {
        hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
        hb_vmPush( (PHB_ITEM) gObject );
        hb_vmPushLong( WM_USER );
        hb_vmPushLong( (HB_LONG) page_num + 1 );
        hb_vmPushLong( (HB_LONG) 0 );
        hb_vmSend( 3 );
    }
}

HB_FUNC( HWG_CREATETABCONTROL )
{
    GtkWidget *hCtrl = gtk_notebook_new();
    GtkFixed  *box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    gint nW = hb_parni( 6 );
    gint nH = hb_parni( 7 );

    if( nW < 1 ) nW = 1;
    if( nH < 1 ) nH = 1;

    gtk_widget_set_hexpand( hCtrl, TRUE );
    gtk_widget_set_vexpand( hCtrl, TRUE );
    gtk_widget_set_halign( hCtrl, GTK_ALIGN_FILL );
    gtk_widget_set_valign( hCtrl, GTK_ALIGN_FILL );

    gtk_widget_set_size_request( hCtrl, nW, nH );

    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );

    gtk_notebook_set_scrollable( GTK_NOTEBOOK( hCtrl ), TRUE );

    if( hb_parni( 3 ) & TCS_BOTTOM )
        gtk_notebook_set_tab_pos( GTK_NOTEBOOK( hCtrl ), GTK_POS_BOTTOM );

    g_signal_connect( hCtrl, "switch-page",
                      G_CALLBACK( cb_signal_tab ), NULL );

    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_ADDTAB )
{
    GtkNotebook *nb = (GtkNotebook*) HB_PARHANDLE( 1 );
    GtkWidget   *box = gtk_fixed_new();
    GtkWidget   *hLabel;
    char        *cLabel   = hwg_convert_to_utf8( hb_parc( 2 ) );
    char        *cTooltip = HB_ISNIL(3) ? NULL : hwg_convert_to_utf8( hb_parc(3) );
    guint        nIdx;

    gtk_widget_set_hexpand( box, TRUE );
    gtk_widget_set_vexpand( box, TRUE );
    gtk_widget_set_halign( box, GTK_ALIGN_FILL );
    gtk_widget_set_valign( box, GTK_ALIGN_FILL );

    hLabel = gtk_label_new( cLabel );
    g_free( cLabel );

    nIdx = (guint) gtk_notebook_get_n_pages( nb );
    hwg_tab_disabled_ensure( nb, nIdx + 1 );
    g_object_set_data( (GObject*) hLabel, "hwg_tab_idx", GUINT_TO_POINTER( nIdx ) );

    {
        GtkGesture *g = gtk_gesture_click_new();
        gtk_gesture_single_set_button( GTK_GESTURE_SINGLE( g ), 0 );
        g_signal_connect( g, "pressed",
                          G_CALLBACK( cb_tablabel_click ), (gpointer) nb );
        gtk_widget_add_controller( hLabel, GTK_EVENT_CONTROLLER( g ) );
    }

    gtk_notebook_append_page( nb, box, hLabel );

    g_object_set_data( (GObject*) nb, "fbox", (gpointer) box );

    if( cTooltip && GTK_IS_WIDGET( nb ) ) {
        gtk_widget_set_tooltip_text( (GtkWidget*) nb, cTooltip );
        g_free( cTooltip );
    }

    HB_RETHANDLE( nb );
}

HB_FUNC( HWG_DELETETAB )
{
    gtk_notebook_remove_page( GTK_NOTEBOOK( HB_PARHANDLE( 1 ) ),
                              hb_parni( 2 ) - 1 );
}

HB_FUNC( HWG_SETTABNAME )
{
    GtkNotebook *nb = (GtkNotebook*) HB_PARHANDLE( 1 );
    gchar *gcTitle  = hwg_convert_to_utf8( hb_parc( 3 ) );

    gtk_notebook_set_tab_label_text( nb,
                                     gtk_notebook_get_nth_page( nb, hb_parni(2) - 1 ), gcTitle );
    g_free( gcTitle );
}

HB_FUNC( HWG_SETTABDISABLED )
{
    GtkNotebook *nb = (GtkNotebook*) HB_PARHANDLE( 1 );
    gint         nPage = hb_parni( 2 );
    gboolean     lDisable = hb_parl( 3 );
    GtkWidget   *page;
    GtkWidget   *tabLabel;

    if( !nb || nPage <= 0 ) return;

    hwg_tab_disabled_ensure( nb, (guint) nPage );
    {
        GArray *arr = (GArray*) g_object_get_data( (GObject*) nb, "hwg_tab_disabled" );
        if( arr && (guint)(nPage-1) < arr->len )
            g_array_index( arr, gboolean, (guint)(nPage-1) ) = lDisable ? TRUE : FALSE;
    }

    page = gtk_notebook_get_nth_page( nb, nPage - 1 );
    if( page ) {
        tabLabel = gtk_notebook_get_tab_label( nb, page );
        if( tabLabel )
            gtk_widget_set_sensitive( tabLabel, lDisable ? FALSE : TRUE );
    }
}

HB_FUNC( HWG_SETCURRENTTAB )
{
    gtk_notebook_set_current_page( GTK_NOTEBOOK( HB_PARHANDLE( 1 ) ),
                                   hb_parni( 2 ) - 1 );
}

HB_FUNC( HWG_GETCURRENTTAB )
{
    hb_retni( gtk_notebook_get_current_page(
        GTK_NOTEBOOK( HB_PARHANDLE( 1 ) ) ) + 1 );
}


/* =====================================================================
 *  HWG_CREATESEP
 * ===================================================================== */
HB_FUNC( HWG_CREATESEP )
{
    HB_BOOL    lVert = hb_parl( 2 );
    GtkWidget *hCtrl;
    GtkFixed  *box;

    hCtrl = gtk_separator_new( lVert ? GTK_ORIENTATION_VERTICAL
    : GTK_ORIENTATION_HORIZONTAL );

    box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 3 ), hb_parni( 4 ) );
    gtk_widget_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

    HB_RETHANDLE( hCtrl );
}


/* =====================================================================
 *  HWG_CREATEPANEL
 * ===================================================================== */
HB_FUNC( HWG_CREATEPANEL )
{
    GtkWidget *vbox, *hbox;
    GtkWidget *vscroll = NULL, *hscroll = NULL;
    GtkWidget *hCtrl;
    GtkFixed  *box, *fbox;
    GObject   *handle;
    PHB_ITEM   pObject = hb_param( 1, HB_IT_OBJECT ), temp;
    HB_ULONG   ulStyle = hb_parnl( 3 );
    gint       nWidth  = hb_parnl( 6 ), nHeight = hb_parnl( 7 );

    temp   = GetObjectVar( pObject, "OPARENT" );
    handle = (GObject*) HB_GETHANDLE( GetObjectVar( temp, "HANDLE" ) );

    fbox = (GtkFixed*) gtk_fixed_new();
    hbox = gtk_box_new( GTK_ORIENTATION_HORIZONTAL, 0 );
    vbox = gtk_box_new( GTK_ORIENTATION_VERTICAL,   0 );

    if( ( ulStyle & SS_OWNERDRAW ) == SS_OWNERDRAW ) {
        hCtrl = gtk_drawing_area_new();
        g_object_set_data( (GObject*) hCtrl, "draw", (gpointer) hCtrl );
    } else {
        hCtrl = gtk_box_new( GTK_ORIENTATION_HORIZONTAL, 0 );
    }

    gtk_box_append( GTK_BOX( hbox ), vbox );

    if( ulStyle & WS_VSCROLL ) {
        GtkAdjustment *adjV = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
        vscroll = gtk_scrollbar_new( GTK_ORIENTATION_VERTICAL, adjV );
        gtk_box_append( GTK_BOX( hbox ), vscroll );

        temp = HB_PUTHANDLE( NULL, adjV );
        SetObjectVar( pObject, "_HSCROLLV", temp );
        hb_itemRelease( temp );

        SetWindowObject( (GtkWidget*) adjV, pObject );
        set_signal( (gpointer) adjV, "value-changed", WM_VSCROLL, 0, 0 );
    }

    gtk_widget_set_hexpand( GTK_WIDGET( fbox ), TRUE );
    gtk_widget_set_vexpand( GTK_WIDGET( fbox ), TRUE );
    gtk_box_append( GTK_BOX( vbox ), GTK_WIDGET( fbox ) );
    gtk_fixed_put( fbox, hCtrl, 0, 0 );

    if( ulStyle & WS_HSCROLL ) {
        GtkAdjustment *adjH = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
        hscroll = gtk_scrollbar_new( GTK_ORIENTATION_HORIZONTAL, adjH );
        gtk_box_append( GTK_BOX( vbox ), hscroll );

        temp = HB_PUTHANDLE( NULL, adjH );
        SetObjectVar( pObject, "_HSCROLLH", temp );
        hb_itemRelease( temp );

        SetWindowObject( (GtkWidget*) adjH, pObject );
        set_signal( (gpointer) adjH, "value-changed", WM_HSCROLL, 0, 0 );
    }

    box = getFixedBox( handle );
    if( box ) {
        gtk_fixed_put( box, hbox, hb_parni( 4 ), hb_parni( 5 ) );
        gtk_widget_set_size_request( hbox, nWidth, nHeight );
        if( vscroll ) nWidth  -= 12;
        if( hscroll ) nHeight -= 12;
        gtk_widget_set_size_request( hCtrl, nWidth, nHeight );
    }

    g_object_set_data( (GObject*) hCtrl, "fbox", (gpointer) fbox );

    temp = HB_PUTHANDLE( NULL, hbox );
    SetObjectVar( pObject, "_HBOX", temp );
    hb_itemRelease( temp );

    gtk_widget_set_can_focus( hCtrl, TRUE );

    if( ( ulStyle & SS_OWNERDRAW ) == SS_OWNERDRAW )
        (void) hwg_install_widget_events( hCtrl, TRUE );
    else
        (void) hwg_install_widget_events( hCtrl, FALSE );

    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_DESTROYPANEL )
{
    GtkFixed *box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    if( box ) {
        GtkWidget *w = GTK_WIDGET( box );
        GtkWidget *parent = gtk_widget_get_parent( w );
        if( parent && GTK_IS_FIXED( parent ) )
            gtk_fixed_remove( GTK_FIXED( parent ), w );
    }
}


/* =====================================================================
 *  HWG_CREATEOWNBTN
 * ===================================================================== */
HB_FUNC( HWG_CREATEOWNBTN )
{
    GtkWidget *hCtrl;
    GtkFixed  *box;

    hCtrl = gtk_drawing_area_new();
    g_object_set_data( (GObject*) hCtrl, "draw", (gpointer) hCtrl );

    box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 3 ), hb_parni( 4 ) );
    gtk_widget_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

    gtk_widget_set_can_focus( hCtrl, TRUE );
    (void) hwg_install_widget_events( hCtrl, TRUE );

    HB_RETHANDLE( hCtrl );
}


/* =====================================================================
 *  Tooltips
 * ===================================================================== */
HB_FUNC( HWG_ADDTOOLTIP )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE( 1 );
    gchar *gcTitle    = hwg_convert_to_utf8( hb_parcx( 2 ) );

    if( gcTitle && widget && GTK_IS_WIDGET( widget ) )
        gtk_widget_set_tooltip_text( widget, gcTitle );

    if( gcTitle ) g_free( gcTitle );
}

HB_FUNC( HWG_DELTOOLTIP )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE( 1 );
    if( widget && GTK_IS_WIDGET( widget ) )
        gtk_widget_set_tooltip_text( widget, NULL );
}

HB_FUNC( HWG_SETTOOLTIPTITLE )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE( 1 );
    gchar *gcTitle    = hwg_convert_to_utf8( hb_parcx( 2 ) );

    if( gcTitle && widget && GTK_IS_WIDGET( widget ) )
        gtk_widget_set_tooltip_text( widget, gcTitle );

    if( gcTitle ) g_free( gcTitle );
}

HB_FUNC( HWG_SETTOOLTIPBALLOON )
{
}


/* =====================================================================
 *  Timers
 * ===================================================================== */
static gint cb_timer( gchar *data )
{
    HB_LONG p1;
    sscanf( (char*) data, "%ld", &p1 );

    if( !pSymTimerProc )
        pSymTimerProc = hb_dynsymFind( "HWG_TIMERPROC" );

    if( pSymTimerProc ) {
        hb_vmPushSymbol( hb_dynsymSymbol( pSymTimerProc ) );
        hb_vmPushNil();
        hb_vmPushLong( (HB_LONG) p1 );
        hb_vmDo( 1 );
        return hb_parnl( -1 );
    }
    return 0;
}

HB_FUNC( HWG_SETTIMER )
{
    char buf[10] = {0};
    sprintf( buf, "%ld", hb_parnl( 1 ) );
    hb_retni( (gint) g_timeout_add( (guint32) hb_parnl( 2 ),
                                    (GSourceFunc) cb_timer, g_strdup( buf ) ) );
}

HB_FUNC( HWG_KILLTIMER )
{
    guint tag = (guint) hb_parni( 1 );

    if( tag > 0 )
        g_source_remove( tag );
}


/* =====================================================================
 *  Parents / cursors / misc
 * ===================================================================== */
HB_FUNC( HWG_GETPARENT )
{
    GtkWidget *w = (GtkWidget*) HB_PARHANDLE( 1 );
    hb_retptr( w && GTK_IS_WIDGET( w ) ? (void*) gtk_widget_get_parent( w ) : NULL );
}

HB_FUNC( HWG_LOADCURSOR )
{
    const char *name = "default";

    if( HB_ISCHAR( 1 ) )
        name = hb_parc( 1 );
    else
    {
        switch( hb_parni( 1 ) )
        {
            case 12:  name = "sw-resize";    break;
            case 14:  name = "se-resize";    break;
            case 16:  name = "s-resize";     break;
            case 30:  name = "crosshair";    break;
            case 34:  name = "crosshair";    break;
            case 52:  name = "move";         break;
            case 58:  name = "grab";         break;
            case 60:  name = "pointer";      break;
            case 68:  name = "default";      break;
            case 70:  name = "w-resize";     break;
            case 92:  name = "help";         break;
            case 96:  name = "e-resize";     break;
            case 108: name = "ew-resize";    break;
            case 116: name = "ns-resize";    break;
            case 120: name = "nwse-resize";  break;
            case 138: name = "n-resize";     break;
            case 150: name = "wait";         break;
            case 152: name = "text";         break;
            default:  name = "default";      break;
        }
    }

    HB_RETHANDLE( gdk_cursor_new_from_name( name, NULL ) );
}

HB_FUNC( HWG_LOADCURSORFROMFILE )
{
    GdkPixbuf  *handle;
    GdkPixbuf  *pHandle;
    GdkTexture *texture;
    GdkCursor  *cursor;

    if( HB_ISCHAR( 1 ) ) {
        handle  = gdk_pixbuf_new_from_file( hb_parc( 1 ), NULL );
        pHandle = alpha2pixbuf( handle, 4095 );

        texture = gdk_texture_new_for_pixbuf( pHandle );
        cursor  = gdk_cursor_new_from_texture( texture,
                                               hb_parni( 2 ), hb_parni( 3 ),
                                               NULL );
        g_object_unref( texture );
        HB_RETHANDLE( cursor );
    }
    else
        HB_RETHANDLE( gdk_cursor_new_from_name( "default", NULL ) );
}

HB_FUNC( HWG_SETCURSOR )
{
    GtkWidget *widget = HB_ISPOINTER( 2 )
    ? (GtkWidget*) HB_PARHANDLE( 2 )
    : GetActiveWindow();
    if( widget && GTK_IS_WIDGET( widget ) )
        gtk_widget_set_cursor( widget, (GdkCursor*) HB_PARHANDLE( 1 ) );
}

HB_FUNC( HWG_MOVEWIDGET )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE( 1 );
    GtkWidget *ch_widget = NULL;
    GtkWidget *parent;

    if( !widget || !GTK_IS_WIDGET( widget ) )
        return;

    if( !HB_ISNIL( 6 ) && hb_parl( 6 ) ) {
        ch_widget = widget;
        widget    = gtk_widget_get_parent( widget );
        if( !widget || !GTK_IS_WIDGET( widget ) )
            return;
    }

    parent = gtk_widget_get_parent( widget );
    if( !parent || !GTK_IS_WIDGET( parent ) )
        return;

    if( !HB_ISNIL( 2 ) && !HB_ISNIL( 3 ) ) {
        if( GTK_IS_FIXED( parent ) )
            gtk_fixed_move( GTK_FIXED( parent ), widget,
                            hb_parni( 2 ), hb_parni( 3 ) );
    }
    if( !HB_ISNIL( 4 ) || !HB_ISNIL( 5 ) ) {
        gint w, h, w1, h1;
        gint pW = gtk_widget_get_width( parent );
        gint pH = gtk_widget_get_height( parent );

        gtk_widget_get_size_request( widget, &w, &h );
        w1 = HB_ISNIL( 4 ) ? w : hb_parni( 4 );
        h1 = HB_ISNIL( 5 ) ? h : hb_parni( 5 );
        if( w1 > pW ) w1 = pW;
        if( h1 > pH ) h1 = pH;
        if( w != w1 || h != h1 ) {
            gtk_widget_set_size_request( widget, w1, h1 );
            if( ch_widget && GTK_IS_WIDGET( ch_widget ) )
                gtk_widget_set_size_request( ch_widget, w1, h1 );
        }
    }
}


/* =====================================================================
 *  Progress bar
 * ===================================================================== */
HB_FUNC( HWG_CREATEPROGRESSBAR )
{
    GtkWidget *hCtrl;
    GtkFixed  *box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    hCtrl = gtk_progress_bar_new();

    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 3 ), hb_parni( 4 ) );
    gtk_widget_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_UPDATEPROGRESSBAR )
{
    gtk_progress_bar_pulse( GTK_PROGRESS_BAR( HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_SETPROGRESSBAR )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE( 1 );
    gdouble b = (gdouble) hb_parnd( 2 );

    gtk_progress_bar_set_fraction( GTK_PROGRESS_BAR( widget ), b );

    while( g_main_context_pending( NULL ) )
        g_main_context_iteration( NULL, TRUE );
}

HB_FUNC( HWG_RESETPROGRESSBAR )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE( 1 );

    gtk_progress_bar_set_fraction( GTK_PROGRESS_BAR( widget ), 0.0 );

    while( g_main_context_pending( NULL ) )
        g_main_context_iteration( NULL, TRUE );
}


/* =====================================================================
 *  Status window
 * ===================================================================== */
HB_FUNC( HWG_CREATESTATUSWINDOW )
{
    GtkWidget *w, *h;
    GObject   *handle = (GObject*) HB_PARHANDLE( 1 );
    GtkWidget *vbox   = (GtkWidget*) g_object_get_data( handle, "vbox" );

    h = gtk_separator_new( GTK_ORIENTATION_HORIZONTAL );
    w = gtk_label_new( "" );
    gtk_label_set_xalign( GTK_LABEL( w ), 0.0f );

    gtk_box_append( GTK_BOX( vbox ), h );
    gtk_box_append( GTK_BOX( vbox ), w );

    HB_RETHANDLE( w );
}

HB_FUNC( HWG_WRITESTATUSWINDOW )
{
    char      *cText = hwg_convert_to_utf8( hb_parcx( 3 ) );
    GtkWidget *w     = (GtkWidget*) hb_parptr( 1 );

    if( w && GTK_IS_LABEL( w ) )
    {
        const gchar *cur = gtk_label_get_text( GTK_LABEL( w ) );
        if( !cur || strcmp( cur, cText ) != 0 )
            gtk_label_set_text( GTK_LABEL( w ), cText );
    }
    g_free( cText );
}


/* =====================================================================
 *  Toolbar
 * ===================================================================== */
static void toolbar_clicked( GtkWidget *item, gpointer user_data )
{
    PHB_ITEM pData = (PHB_ITEM) user_data;
    hb_vmEvalBlock( (PHB_ITEM) pData );
    HB_SYMBOL_UNUSED( item );
}

HB_FUNC( HWG_CREATETOOLBAR )
{
    GtkWidget *hCtrl = gtk_box_new( GTK_ORIENTATION_HORIZONTAL, 0 );
    GObject   *handle = (GObject*) HB_PARHANDLE( 1 );
    GtkFixed  *box   = getFixedBox( handle );
    GtkWidget *vbox  = gtk_widget_get_parent( GTK_WIDGET( box ) );

    gtk_box_append( GTK_BOX( vbox ), hCtrl );
    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_CREATETOOLBARBUTTON )
{
    GtkWidget *toolbutton1, *img;
    GtkWidget *hCtrl   = (GtkWidget*) HB_PARHANDLE( 1 );
    PHWGUI_PIXBUF szFile = HB_ISPOINTER( 2 )
    ? (PHWGUI_PIXBUF) HB_PARHANDLE( 2 ) : NULL;
    const char *szLabel = HB_ISCHAR( 3 ) ? hb_parc( 3 ) : NULL;
    HB_BOOL     lSep    = hb_parl( 4 );
    gchar      *gcLabel = NULL;

    if( szLabel ) gcLabel = hwg_convert_to_utf8( szLabel );

    if( lSep )
        toolbutton1 = gtk_separator_new( GTK_ORIENTATION_VERTICAL );
    else {
        if( szFile ) {
            GtkWidget *box = gtk_box_new( GTK_ORIENTATION_HORIZONTAL, 4 );
            img = gtk_image_new_from_pixbuf( szFile->handle );
            gtk_box_append( GTK_BOX( box ), img );
            if( gcLabel ) {
                GtkWidget *lbl = gtk_label_new( gcLabel );
                gtk_box_append( GTK_BOX( box ), lbl );
            }
            toolbutton1 = gtk_button_new();
            gtk_button_set_child( GTK_BUTTON( toolbutton1 ), box );
        }
        else
            toolbutton1 = gtk_button_new_with_label( gcLabel ? gcLabel : "" );
    }
    if( gcLabel ) g_free( gcLabel );

    gtk_box_append( GTK_BOX( hCtrl ), toolbutton1 );
    HB_RETHANDLE( toolbutton1 );
}

HB_FUNC( HWG_TOOLBAR_SETACTION )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    PHB_ITEM pItem = hb_itemParam( 2 );
    g_signal_connect( hCtrl, "clicked",
                      G_CALLBACK( toolbar_clicked ), (void*) pItem );
}

static void tabchange_clicked( GtkNotebook *item,
                               GtkWidget *Page, guint pagenum,
                               gpointer user_data )
{
    PHB_ITEM pData = (PHB_ITEM) user_data;
    gpointer dwNewLong;
    PHB_ITEM pObject;
    PHB_ITEM Disk;

    HB_SYMBOL_UNUSED( Page );

    if( !pData )
        return;

    dwNewLong = g_object_get_data( (GObject*) item, "obj" );
    if( !dwNewLong )
        return;

    pObject = (PHB_ITEM) dwNewLong;
    Disk = hb_itemPutNL( NULL, pagenum + 1 );

    hb_vmEvalBlockV( (PHB_ITEM) pData, 2, pObject, Disk );
    hb_itemRelease( Disk );
}

HB_FUNC( HWG_TAB_SETACTION )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    PHB_ITEM pItem = hb_itemParam( 2 );
    g_signal_connect( hCtrl, "switch-page",
                      G_CALLBACK( tabchange_clicked ), (void*) pItem );
}


/* =====================================================================
 *  Month calendar
 * ===================================================================== */
HB_FUNC( HWG_INITMONTHCALENDAR )
{
    GtkWidget *hCtrl;
    GtkFixed  *box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );

    hCtrl = gtk_calendar_new();
    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 3 ), hb_parni( 4 ) );
    gtk_widget_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_SETMONTHCALENDARDATE )
{
    PHB_ITEM pDate = hb_param( 2, HB_IT_DATE );

    if( pDate ) {
        GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
        int lYear, lMonth, lDay;
        GDateTime *dt;

        hb_dateDecode( hb_itemGetDL( pDate ), &lYear, &lMonth, &lDay );

        dt = g_date_time_new_local( lYear, lMonth, lDay, 12, 0, 0.0 );
        if( dt ) {
            gtk_calendar_select_day( GTK_CALENDAR( hCtrl ), dt );
            g_date_time_unref( dt );
        }
    }
}

HB_FUNC( HWG_GETMONTHCALENDARDATE )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    char szDate[9];
    GDateTime *dt = gtk_calendar_get_date( GTK_CALENDAR( hCtrl ) );

    hb_dateStrPut( szDate,
                   g_date_time_get_year( dt ),
                   g_date_time_get_month( dt ),
                   g_date_time_get_day_of_month( dt ) );
    szDate[8] = 0;
    g_date_time_unref( dt );
    hb_retds( szDate );
}

HB_FUNC( HWG_MONTHCALENDAR_SETACTION )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    PHB_ITEM pItem = hb_itemParam( 2 );
    g_signal_connect( hCtrl, "day-selected",
                      G_CALLBACK( toolbar_clicked ), (void*) pItem );
}


/* =====================================================================
 *  Image
 * ===================================================================== */
HB_FUNC( HWG_CREATEIMAGE )
{
    GtkWidget *hCtrl;
    GtkFixed  *box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    GdkPixbuf *handle  = gdk_pixbuf_new_from_file( hb_parc( 2 ), NULL );
    GdkPixbuf *pHandle = alpha2pixbuf( handle, 16777215 );

    hCtrl = gtk_image_new_from_pixbuf( pHandle );

    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 3 ), hb_parni( 4 ) );
    gtk_widget_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

    HB_RETHANDLE( hCtrl );
}


/* =====================================================================
 *  Colors via CSS
 * ===================================================================== */
HB_FUNC( HWG_SETFGCOLOR )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    char szData[128], szColor[8];
    const char *pName = gtk_widget_get_name( hCtrl );

    if( pName && strncmp( pName, "Gtk", 3 ) != 0 ) {
        hwg_colorN2C( (unsigned int) hb_parni( 2 ), szColor );
        sprintf( szData, "#%s { color: #%s; }", pName, szColor );
        set_css_data( szData );
    }
}

HB_FUNC( HWG_SETBGCOLOR )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    char szData[128], szColor[8];
    const char *pName = gtk_widget_get_name( hCtrl );

    if( pName && strncmp( pName, "Gtk", 3 ) != 0 ) {
        hwg_colorN2C( (unsigned int) hb_parni( 2 ), szColor );
        sprintf( szData, "#%s { background: #%s; }", pName, szColor );
        set_css_data( szData );
    }
}


/* =====================================================================
 *  Splitter / Board
 * ===================================================================== */
HB_FUNC( HWG_CREATESPLITTER )
{
    GtkWidget *hCtrl;
    GtkFixed  *box;

    hCtrl = gtk_drawing_area_new();
    g_object_set_data( (GObject*) hCtrl, "draw", (gpointer) hCtrl );

    box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
    gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

    gtk_widget_set_can_focus( hCtrl, TRUE );
    (void) hwg_install_widget_events( hCtrl, TRUE );

    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_CREATEBOARD )
{
    GtkWidget *hCtrl;
    GtkFixed  *box;

    hCtrl = gtk_drawing_area_new();
    g_object_set_data( (GObject*) hCtrl, "draw", (gpointer) hCtrl );

    box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
    gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

    gtk_widget_set_can_focus( hCtrl, TRUE );
    (void) hwg_install_widget_events( hCtrl, TRUE );

    g_signal_connect( hCtrl, "resize",
                      G_CALLBACK( cb_signal_size ), "1" );

    HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_CSSLOAD )
{
    set_css_data( (char*) hb_parc( 1 ) );
}

HB_FUNC( HWG_SETWIDGETNAME )
{
    GtkWidget *w = (GtkWidget*) HB_PARHANDLE( 1 );
    if( w && GTK_IS_WIDGET( w ) )
        gtk_widget_set_name( w, hb_parc( 2 ) );
}


/* =====================================================================
 *  Show cursor
 * ===================================================================== */
HB_FUNC( HWG_SHOWCURSOR )
{
    HB_BOOL    modus  = hb_parl( 1 );
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE( 2 );
    GdkCursor *cursor;

    cursor = gdk_cursor_new_from_name( modus ? "default" : "none", NULL );

    if( widget && GTK_IS_WIDGET( widget ) )
        gtk_widget_set_cursor( widget, cursor );

    hb_retni( modus ? 0 : -1 );
}

HB_FUNC( HWG_GETCURSORTYPE )
{
    hb_retnl( 0 );
}


/* =====================================================================
 *  CSS theme loader + widget class helpers
 * ===================================================================== */

static GtkCssProvider *s_ThemeCss = NULL;

HB_FUNC( HWG_CSSLOADFILE )
{
    const char *path = hb_parc( 1 );

    if( !path || !*path )
    {
        hb_retl( FALSE );
        return;
    }

    if( !g_file_test( path, G_FILE_TEST_IS_REGULAR ) )
    {
        fprintf( stderr, "[HWGUI] theme CSS not found: %s\n", path );
        fflush( stderr );
        hb_retl( FALSE );
        return;
    }

    if( s_ThemeCss )
    {
        GdkDisplay *display = gdk_display_get_default();
        if( display )
        {
            gtk_style_context_remove_provider_for_display(
                display, GTK_STYLE_PROVIDER( s_ThemeCss ) );
        }
        g_object_unref( s_ThemeCss );
        s_ThemeCss = NULL;
    }

    s_ThemeCss = gtk_css_provider_new();
    gtk_css_provider_load_from_path( s_ThemeCss, path );

    gtk_style_context_add_provider_for_display(
        gdk_display_get_default(),
                                               GTK_STYLE_PROVIDER( s_ThemeCss ),
                                               GTK_STYLE_PROVIDER_PRIORITY_USER + 1 );

    hb_retl( TRUE );
}

HB_FUNC( HWG_ADDCSSCLASS )
{
    GtkWidget  *w   = (GtkWidget*) HB_PARHANDLE( 1 );
    const char *cls = hb_parc( 2 );

    if( !w || !GTK_IS_WIDGET( w ) || !cls || !*cls )
        return;

    gtk_widget_add_css_class( w, cls );
}

HB_FUNC( HWG_REMOVECSSCLASS )
{
    GtkWidget  *w   = (GtkWidget*) HB_PARHANDLE( 1 );
    const char *cls = hb_parc( 2 );

    if( !w || !GTK_IS_WIDGET( w ) || !cls || !*cls )
        return;

    gtk_widget_remove_css_class( w, cls );
}

HB_FUNC( HWG_HASCSSCLASS )
{
    GtkWidget  *w   = (GtkWidget*) HB_PARHANDLE( 1 );
    const char *cls = hb_parc( 2 );

    if( !w || !GTK_IS_WIDGET( w ) || !cls || !*cls )
    {
        hb_retl( FALSE );
        return;
    }

    hb_retl( gtk_widget_has_css_class( w, cls ) );
}

HB_FUNC( HWG_SETCSSCLASS )
{
    GtkWidget  *w   = (GtkWidget*) HB_PARHANDLE( 1 );
    const char *cls = hb_parc( 2 );

    if( !w || !GTK_IS_WIDGET( w ) )
        return;

    if( cls && *cls )
    {
        const char *classes[2];
        classes[0] = cls;
        classes[1] = NULL;
        gtk_widget_set_css_classes( w, classes );
    }
    else
    {
        gtk_widget_set_css_classes( w, NULL );
    }
}

/* ====================== EOF of control.c ======================= */
