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
 *  - Colour helpers at the end of this file keep two CSS providers
 *    per widget (fg and bg), stored as widget data so they can be
 *    removed later.  This is what allows an entry to go back to the
 *    current theme when it loses focus.
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

#define ES_PASSWORD        32
#define ES_MULTILINE        4
#define ES_READONLY      2048
#define ES_CENTER           1
#define ES_RIGHT            2
#define ES_UPPERCASE        8

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
#define WS_BORDER    0x00800000L
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
extern gchar *hwg_convert_from_utf8( const char * szText );

extern GtkWidget *GetActiveWindow( void );
extern GdkPixbuf *alpha2pixbuf( GdkPixbuf *hPixIn, long int nColor );

static PHB_DYNS   pSymTimerProc = NULL;
static PHB_DYNS   pSym_onEvent  = NULL;


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
 *  hwg_legacy_gtk_name
 *
 *  Translate the GTK3 stock ids (gtk-copy, gtk-save, gtk-open, ...)
 *  into the freedesktop equivalents used by GTK4 icon themes.  The
 *  GTK3 stock registry was removed in GTK4; the names themselves are
 *  still what applications pass to HBitmap:AddStandard(), so we keep
 *  accepting them and map to the modern names here.
 * ===================================================================== */
const char *hwg_legacy_gtk_name( const char *name )
{
    static char buf[128];
    const char *p;
    size_t n;

    if( !name )
        return NULL;

    p = name;
    if( strncmp( p, "gtk-", 4 ) == 0 )
        p += 4;

    if( strcmp( p, "ok" )        == 0 ) return "emblem-ok-symbolic";
    if( strcmp( p, "apply" )     == 0 ) return "emblem-ok-symbolic";
    if( strcmp( p, "yes" )       == 0 ) return "emblem-ok-symbolic";
    if( strcmp( p, "cancel" )    == 0 ) return "window-close";
    if( strcmp( p, "close" )     == 0 ) return "window-close";
    if( strcmp( p, "no" )        == 0 ) return "process-stop";
    if( strcmp( p, "stop" )      == 0 ) return "process-stop";
    if( strcmp( p, "quit" )      == 0 ) return "application-exit";
    if( strcmp( p, "copy" )      == 0 ) return "edit-copy";
    if( strcmp( p, "paste" )     == 0 ) return "edit-paste";
    if( strcmp( p, "cut" )       == 0 ) return "edit-cut";
    if( strcmp( p, "delete" )    == 0 ) return "edit-delete";
    if( strcmp( p, "clear" )     == 0 ) return "edit-clear";
    if( strcmp( p, "undo" )      == 0 ) return "edit-undo";
    if( strcmp( p, "redo" )      == 0 ) return "edit-redo";
    if( strcmp( p, "find" )      == 0 ) return "edit-find";
    if( strcmp( p, "save" )      == 0 ) return "document-save";
    if( strcmp( p, "save-as" )   == 0 ) return "document-save-as";
    if( strcmp( p, "open" )      == 0 ) return "document-open";
    if( strcmp( p, "new" )       == 0 ) return "document-new";
    if( strcmp( p, "print" )     == 0 ) return "document-print";
    if( strcmp( p, "refresh" )   == 0 ) return "view-refresh";
    if( strcmp( p, "go-back" )   == 0 ) return "go-previous";
    if( strcmp( p, "go-forward" )== 0 ) return "go-next";
    if( strcmp( p, "home" )      == 0 ) return "go-home";
    if( strcmp( p, "help" )      == 0 ) return "help-about";
    if( strcmp( p, "about" )     == 0 ) return "help-about";
    if( strcmp( p, "info" )      == 0 ) return "dialog-information";
    if( strcmp( p, "edit" )      == 0 ) return "document-properties";
    if( strcmp( p, "preferences" ) == 0 ) return "preferences-system";

    n = strlen( p );
    if( n >= sizeof( buf ) )
        n = sizeof( buf ) - 1;
    memcpy( buf, p, n );
    buf[ n ] = '\0';
    return buf;
}

/* =====================================================================
 *  HWG_STOCKBITMAP
 *
 *  Look up a named icon in the active GtkIconTheme and return it as
 *  an HWGUI PIXBUF handle.
 *
 *  GTK4 removed gtk_widget_render_icon() (GTK2) and the GtkStockItem
 *  registry.  The replacement path used below is:
 *
 *      GtkIconTheme     -> holds the icon lookup table
 *      GtkIconPaintable -> the resolved icon
 *      GtkSnapshot      -> render target for the paintable
 *      GskRenderNode    -> the rendered node
 *      cairo_surface_t  -> the node is drawn into this
 *      GdkPixbuf        -> a copy of the surface, wrapped in the HWGUI
 *                          PIXBUF handle
 *
 *  gdk_pixbuf_get_from_surface() copies the pixel data out of the
 *  cairo surface in one step, so there is no need for the intermediate
 *  GBytes / GdkTexture pipeline that a previous version used.  That
 *  pipeline was the source of the Cairo assertion
 *
 *      cairo_surface_reference: assertion
 *        'CAIRO_REFERENCE_COUNT_HAS_REFERENCE(&surface->ref_count)' failed
 *
 *  -- a duplicated block called cairo_surface_reference() on a surface
 *  that had already been destroyed by the previous pass.
 *
 *  The flag GTK_ICON_LOOKUP_FORCE_REGULAR makes the theme prefer the
 *  colour variant of an icon over the symbolic one.  Symbolic icons
 *  inherit the foreground colour of the theme: on a light-on-dark
 *  theme (Breeze-Dark, for instance) they render almost white and
 *  disappear against the white row background of a browse.
 *
 *  hwg_legacy_gtk_name() translates the GTK3 stock ids to the modern
 *  freedesktop names before the lookup, so callers that still pass
 *  "gtk-copy" or "gtk-save" keep working.
 * ===================================================================== */
HB_FUNC( HWG_STOCKBITMAP )
{
    PHWGUI_PIXBUF     hpix;
    GdkPixbuf        *handle = NULL;
    GtkIconTheme     *theme;
    GtkIconPaintable *paintable;
    const char       *requested;
    const char       *resolved;

    theme = gtk_icon_theme_get_for_display( gdk_display_get_default() );

    requested = hb_parc( 1 );
    if( !requested || !*requested )
    {
        hb_ret();
        return;
    }

    resolved = hwg_legacy_gtk_name( requested );

    paintable = gtk_icon_theme_lookup_icon( theme, resolved,
                                            NULL,
                                            HWG_ICON_SIZE_PX,
                                            1,
                                            GTK_TEXT_DIR_NONE,
                                            GTK_ICON_LOOKUP_FORCE_REGULAR );

    if( paintable )
    {
        int width  = gdk_paintable_get_intrinsic_width( GDK_PAINTABLE( paintable ) );
        int height = gdk_paintable_get_intrinsic_height( GDK_PAINTABLE( paintable ) );

        if( width <= 0 )  width  = HWG_ICON_SIZE_PX;
        if( height <= 0 ) height = HWG_ICON_SIZE_PX;

        {
            cairo_surface_t *surface = cairo_image_surface_create( CAIRO_FORMAT_ARGB32, width, height );
            GtkSnapshot     *snapshot = gtk_snapshot_new();
            GskRenderNode   *node;
            cairo_t         *cr;

            gdk_paintable_snapshot( GDK_PAINTABLE( paintable ), snapshot, width, height );
            node = gtk_snapshot_free_to_node( snapshot );

            /*
             * gtk_snapshot_free_to_node() returns NULL when the paintable
             * pushed nothing to the snapshot (some symbolic icons at a
             * given size).  Guard the pipeline so the Gsk assertions
             *     gsk_render_node_draw: assertion 'GSK_IS_RENDER_NODE (node)' failed
             * do not fire.
             */
            if( node )
            {
                cr = cairo_create( surface );
                gsk_render_node_draw( node, cr );
                cairo_destroy( cr );
                gsk_render_node_unref( node );

                /* Make the pixels written by cairo visible to the
                 * GdkPixbuf reader below. */
                cairo_surface_flush( surface );

                handle = gdk_pixbuf_get_from_surface( surface, 0, 0, width, height );
            }

            cairo_surface_destroy( surface );
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
        gchar  szName[64];                                    /* ← NOVO */
        hCtrl = gtk_label_new( gcTitle );
        g_free( gcTitle );

        /* Unique, non-"Gtk*" name so HWG_SETFGCOLOR / HWG_SETBGCOLOR
         * do not skip this widget (they ignore names starting with
         * "Gtk").  Needed so a SAY with WS_BORDER + BACKCOLOR can be
         * painted by the standard colour helpers. */
        snprintf( szName, sizeof(szName), "hwg-static-%p", (void*) hCtrl );  /* ← NOVO */
        gtk_widget_set_name( hCtrl, szName );                                /* ← NOVO */

        gtk_label_set_xalign( GTK_LABEL( hCtrl ),
                              ( ulStyle & SS_RIGHT )  ? 1.0 :
                              ( ( ulStyle & SS_CENTER ) ? 0.5 : 0.0 ) );
        gtk_label_set_yalign( GTK_LABEL( hCtrl ), 0.0 );

        if( ulExtStyle & WS_EX_TRANSPARENT )
            gtk_widget_set_opacity( hCtrl, 1.0 );

        if( ulStyle & WS_BORDER )
            gtk_widget_add_css_class( hCtrl, "hwg-static-border" );

        g_object_set_data( (GObject*) hCtrl, "label", (gpointer) hCtrl );
    }

    box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
    hwg_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

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
 *  GroupBox drawn by hand
 *
 *  GtkFrame's internal "> border" node is theme-dependent and often
 *  invisible on KDE/Breeze.  We draw the classic Win32 group box
 *  instead: a rectangle whose top line is interrupted where the label
 *  sits, with the label vertically centered on that line.
 *
 *  Colours come from gtk_widget_get_color(), so the box follows the
 *  current theme (dark or light) without any hard-coded colour.
 * ===================================================================== */
static void hwg_groupbox_draw( GtkDrawingArea *area, cairo_t *cr,
                               int width, int height, gpointer user_data )
{
    GtkWidget      *w = GTK_WIDGET( area );
    const char     *title = g_object_get_data( G_OBJECT( w ), "hwg_gb_title" );
    PangoLayout    *layout;
    PangoRectangle  rect;
    GdkRGBA         fg;

    /* -------- FINE TUNE --------
     * label_y : vertical position of the TEXT, from the top of the widget.
     *           Increase to move the text down.
     * line_y  : vertical position of the top frame LINE.
     *           Increase to move the line down.
     * Rule: to keep the text centered on the line (Win32 default),
     *       use line_y = label_y + rect.height/2.
     * To place the whole text above the line, use line_y = label_y + rect.height + 1.
     */
    double label_y = -5;
    double line_y  = 8.0;

    double label_x = 10.0;
    double gap_start, gap_end;

    HB_SYMBOL_UNUSED( user_data );

    if( !title || !*title )
        title = "";

    /* Foreground colour comes from the current theme (dark or light). */
    gtk_widget_get_color( w, &fg );

    layout = pango_cairo_create_layout( cr );
    pango_layout_set_text( layout, title, -1 );
    pango_layout_get_pixel_extents( layout, &rect, NULL );

    gap_start = label_x - 2.0;
    gap_end   = label_x + rect.width + 2.0;
    if( gap_end > width - 1 )
        gap_end = width - 1;

    /* Frame line: foreground at 45% opacity -- readable on both themes. */
    cairo_set_source_rgba( cr, fg.red, fg.green, fg.blue, 0.45 );
    cairo_set_line_width( cr, 0.5 );

    /* Top, with a gap where the label sits */
    cairo_move_to( cr, 0.5,       line_y );
    cairo_line_to( cr, gap_start, line_y );
    cairo_move_to( cr, gap_end,   line_y );
    cairo_line_to( cr, width - 0.5, line_y );

    /* Right */
    cairo_move_to( cr, width - 0.5, line_y );
    cairo_line_to( cr, width - 0.5, height - 0.5 );

    /* Bottom */
    cairo_move_to( cr, width - 0.5, height - 0.5 );
    cairo_line_to( cr, 0.5,         height - 0.5 );

    /* Left */
    cairo_move_to( cr, 0.5, height - 0.5 );
    cairo_line_to( cr, 0.5, line_y );

    cairo_stroke( cr );

    /* Caption text: full foreground. */
    cairo_set_source_rgba( cr, fg.red, fg.green, fg.blue, 1.0 );
    cairo_move_to( cr, label_x, label_y );
    pango_cairo_show_layout( cr, layout );

    g_object_unref( layout );
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
        hCtrl = gtk_drawing_area_new();
        gtk_widget_set_can_focus( hCtrl, FALSE );

        /* Store the caption for the draw function. */
        g_object_set_data_full( G_OBJECT( hCtrl ), "hwg_gb_title",
                                g_strdup( gcTitle ), g_free );

        gtk_drawing_area_set_draw_func( GTK_DRAWING_AREA( hCtrl ),
                                        hwg_groupbox_draw, NULL, NULL );
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
    hwg_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

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

        /* ES_READONLY on GtkEntry: mark as non-editable AND remove
         * focus.  gtk_editable_set_editable(FALSE) alone leaves the
         * widget focusable and, on some GTK builds, still accepts
         * keystrokes.  Dropping can_focus closes that hole. */
        if( ulStyle & ES_READONLY )
        {
            gtk_editable_set_editable( GTK_EDITABLE( hCtrl ), FALSE );
            gtk_widget_set_can_focus( hCtrl, FALSE );
        }
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
        hwg_set_size_request( hScroll, nW, nH );
    else
        hwg_set_size_request( hCtrl, nW, nH );

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
            {
                /* Mark the change as programmatic.  cb_editable_changed
                 * in window.c bails out when this flag is set, so
                 * EN_CHANGE is not dispatched to Harbour.  GTK emits
                 * "changed" synchronously from within set_text(), so
                 * the guard window is exactly as wide as it needs to
                 * be -- cleared right after. */
                g_object_set_data( (GObject*) hCtrl, "hwg_edit_busy",
                                   GINT_TO_POINTER( 1 ) );

                gtk_editable_set_text( GTK_EDITABLE( hCtrl ), gcText );

                g_object_set_data( (GObject*) hCtrl, "hwg_edit_busy", NULL );
            }
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

/*
 * Clear the selection range of a GtkEntry, without changing the caret
 * position.  Used on WM_KILLFOCUS so a highlighted selection is not
 * left visible in an entry that no longer has focus.
 */
HB_FUNC( HWG_EDIT_CLEARSELECTION )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );

    if( !hCtrl || !G_IS_OBJECT( hCtrl ) ||
        !GTK_IS_WIDGET( hCtrl ) || !GTK_IS_EDITABLE( hCtrl ) )
        return;

    gtk_editable_select_region( GTK_EDITABLE( hCtrl ), 0, 0 );
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
    PHB_ITEM aSel, temp;

    /* Always return a two-element array.  The previous version left
     * the return value as Nil when there was no selection, which
     * broke any Harbour code doing Len() / Ascan() / indexing on the
     * result -- common in a HGet's Valid block that inspects the
     * selection before deciding whether to act.  {0,0} is the neutral
     * "no selection" sentinel: start == end == caret position, which
     * matches the semantics of an empty selection in GTK. */
    if( !hCtrl || !G_IS_OBJECT( hCtrl ) ||
        !GTK_IS_WIDGET( hCtrl ) || !GTK_IS_EDITABLE( hCtrl ) )
    {
        aSel = hb_itemArrayNew( 2 );
        temp = hb_itemPutNL( NULL, 0 );
        hb_itemArrayPut( aSel, 1, temp ); hb_itemRelease( temp );
        temp = hb_itemPutNL( NULL, 0 );
        hb_itemArrayPut( aSel, 2, temp ); hb_itemRelease( temp );
        hb_itemRelease( hb_itemReturn( aSel ) );
        return;
    }

    if( !gtk_editable_get_selection_bounds( GTK_EDITABLE( hCtrl ), &start, &end ) )
    {
        start = 0;
        end   = 0;
    }

    aSel = hb_itemArrayNew( 2 );

    temp = hb_itemPutNL( NULL, start );
    hb_itemArrayPut( aSel, 1, temp ); hb_itemRelease( temp );
    temp = hb_itemPutNL( NULL, end );
    hb_itemArrayPut( aSel, 2, temp ); hb_itemRelease( temp );

    hb_itemRelease( hb_itemReturn( aSel ) );
}

/* Idle callback that resets the caret and clears any selection.
 * Runs after the current GTK event queue drains, so it overrides
 * GTK4's auto-select that happens when an entry receives focus. */
static gboolean hwg_clear_selection_idle( gpointer data )
{
    GtkWidget *w = GTK_WIDGET( data );

    if( G_IS_OBJECT( w ) && GTK_IS_WIDGET( w ) && GTK_IS_EDITABLE( w ) )
    {
        gtk_editable_set_position( GTK_EDITABLE( w ), 0 );
        gtk_editable_select_region( GTK_EDITABLE( w ), 0, 0 );
    }

    if( G_IS_OBJECT( w ) )
        g_object_unref( w );

    return G_SOURCE_REMOVE;
}

HB_FUNC( HWG_EDIT_CLEARSELECTION_ASYNC )
{
    GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );

    if( !hCtrl || !G_IS_OBJECT( hCtrl ) || !GTK_IS_WIDGET( hCtrl ) )
        return;

    g_object_ref( hCtrl );
    g_idle_add_full( G_PRIORITY_LOW, hwg_clear_selection_idle, hCtrl, NULL );
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
/*
 * Type-ahead context for editable combos.
 */
typedef struct {
    GtkWidget *combo;
    gchar     *prefix;
} HWG_COMBO_SEEK_CTX;


/*
 * ES_UPPERCASE for editable combos.
 *
 * Modifying the entry content directly from inside the "changed"
 * handler triggers a GTK4 warning:
 *   "Cannot begin irreversible action while in user action"
 * because gtk_editable_set_text() tries to open an irreversible
 * action while the user action that produced the current change is
 * still open.  The fix is to defer the rewrite to an idle callback:
 * by the time it runs, the user action has already closed and the
 * set_text() is allowed.
 */
static gboolean hwg_uppercase_idle( gpointer data )
{
    GtkEditable *editable = GTK_EDITABLE( data );
    const gchar *text;
    gchar       *upper;
    gint         pos;

    if( !editable || !G_IS_OBJECT( editable ) )
        return G_SOURCE_REMOVE;

    g_object_set_data( G_OBJECT( editable ), "hwg_upper_scheduled", NULL );

    text = gtk_editable_get_text( editable );
    if( text && *text )
    {
        upper = g_utf8_strup( text, -1 );
        if( upper )
        {
            if( g_strcmp0( text, upper ) != 0 )
            {
                pos = gtk_editable_get_position( editable );
                gtk_editable_set_text( editable, upper );
                gtk_editable_set_position( editable, pos );
            }
            g_free( upper );
        }
    }

    g_object_unref( editable );
    return G_SOURCE_REMOVE;
}

static void cb_combo_uppercase( GtkEditable *editable, gpointer user_data )
{
    HB_SYMBOL_UNUSED( user_data );

    if( !editable || !GTK_IS_EDITABLE( editable ) )
        return;

    /* Coalesce: if a rewrite is already scheduled, do nothing.  A
     * burst of keystrokes should trigger one idle, not one per key. */
    if( g_object_get_data( G_OBJECT( editable ), "hwg_upper_scheduled" ) )
        return;

    g_object_set_data( G_OBJECT( editable ), "hwg_upper_scheduled",
                       GINT_TO_POINTER( 1 ) );
    g_object_ref( editable );
    g_idle_add( hwg_uppercase_idle, editable );
}


/*
 * Key handler for the internal entry of an editable combo.  Sets a
 * skip flag whenever the user presses Backspace or Delete, so the
 * deferred seek does not refill the entry with the matched item and
 * undo the deletion.
 *
 * GTK4 has no key-press signal on GtkComboBox itself; the controller
 * is installed on the combo's child (the internal GtkEntry) and finds
 * its way back through gtk_widget_get_parent.
 */
static gboolean cb_combo_entry_key( GtkEventControllerKey *ctl,
                                    guint keyval, guint keycode,
                                    GdkModifierType state,
                                    gpointer user_data )
{
    GtkWidget *entry = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( ctl ) );
    GtkWidget *combo;

    HB_SYMBOL_UNUSED( keycode );
    HB_SYMBOL_UNUSED( state );
    HB_SYMBOL_UNUSED( user_data );

    combo = gtk_widget_get_parent( entry );
    if( !combo || !GTK_IS_COMBO_BOX( combo ) )
        return FALSE;

    if( keyval == GDK_KEY_BackSpace || keyval == GDK_KEY_Delete )
    {
        g_object_set_data( G_OBJECT( combo ), "hwg_seek_skip",
                           GINT_TO_POINTER( 1 ) );
    }

    return FALSE;
}


/*
 * Deferred worker.  Runs in an idle callback, after the "changed"
 * handler (and the user action it was part of) has already returned.
 * From here, gtk_combo_box_set_active() is allowed to modify the
 * entry without triggering GTK's
 *   "Cannot begin irreversible action while in user action"
 * warning.
 */
static gboolean hwg_combo_seek_idle( gpointer data )
{
    HWG_COMBO_SEEK_CTX *ctx = (HWG_COMBO_SEEK_CTX *) data;
    GtkWidget    *combo = ctx->combo;
    GtkTreeModel *model;
    GtkTreeIter   iter;
    GtkWidget    *entry;
    gchar        *upper_prefix;
    gint          n, i, matched = 0;
    gint          prefix_chars;

    if( !combo || !G_IS_OBJECT( combo ) || !GTK_IS_COMBO_BOX( combo ) )
    {
        g_free( ctx->prefix );
        g_free( ctx );
        return G_SOURCE_REMOVE;
    }

    g_object_set_data( G_OBJECT( combo ), "hwg_seek_pending", NULL );

    upper_prefix = g_utf8_strup( ctx->prefix, -1 );
    if( !upper_prefix )
    {
        g_free( ctx->prefix );
        g_free( ctx );
        return G_SOURCE_REMOVE;
    }

    prefix_chars = (gint) g_utf8_strlen( ctx->prefix, -1 );

    model = gtk_combo_box_get_model( GTK_COMBO_BOX( combo ) );
    n     = gtk_tree_model_iter_n_children( model, NULL );

    for( i = 0; i < n; i++ )
    {
        gchar *item = NULL;

        if( gtk_tree_model_iter_nth_child( model, &iter, NULL, i ) )
        {
            gtk_tree_model_get( model, &iter, 0, &item, -1 );

            if( item )
            {
                gchar    *upper_item = g_utf8_strup( item, -1 );
                gboolean  match = ( upper_item &&
                g_str_has_prefix( upper_item, upper_prefix ) );

                g_free( upper_item );
                g_free( item );

                if( match )
                {
                    matched = i + 1;
                    break;
                }
            }
        }
    }

    g_free( upper_prefix );

    if( matched > 0 &&
        gtk_combo_box_get_active( GTK_COMBO_BOX( combo ) ) != matched - 1 )
    {
        g_object_set_data( G_OBJECT( combo ), "hwg_autocompleting",
                           GINT_TO_POINTER( 1 ) );

        gtk_combo_box_set_active( GTK_COMBO_BOX( combo ), matched - 1 );

        entry = gtk_combo_box_get_child( GTK_COMBO_BOX( combo ) );
        if( entry && GTK_IS_EDITABLE( entry ) )
        {
            gtk_editable_select_region( GTK_EDITABLE( entry ),
                                        prefix_chars, -1 );
        }

        g_object_set_data( G_OBJECT( combo ), "hwg_autocompleting", NULL );
    }

    g_free( ctx->prefix );
    g_free( ctx );
    return G_SOURCE_REMOVE;
}


/* =====================================================================
 *  HWG_CREATECOMBO
 * ===================================================================== */
HB_FUNC( HWG_CREATECOMBO )
{
    GtkWidget *hCtrl;
    GtkWidget *entry = NULL;
    gint iText = ( ( hb_parni( 3 ) & 1 ) == 0 );
    unsigned long ulStyle = (unsigned long) hb_parni( 3 );
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
    hwg_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

    (void) hwg_install_widget_events( hCtrl, FALSE );
    entry = gtk_combo_box_get_child( GTK_COMBO_BOX( hCtrl ) );
    if( entry && GTK_IS_WIDGET( entry ) )
    {
        (void) hwg_install_widget_events( entry, FALSE );

        /* ES_UPPERCASE from the style: force the entry content to
         * uppercase on every change.  Works both for text typed by
         * the user and for values assigned from Harbour through
         * SetText / bSetGet, since both fire "changed". */
        if( ( ulStyle & ES_UPPERCASE ) != 0 && GTK_IS_EDITABLE( entry ) )
        {
            g_signal_connect( entry, "changed",
                              G_CALLBACK( cb_combo_uppercase ), NULL );
        }

        /* Track Backspace/Delete presses so HWG_COMBOSEEKPREFIX can
         * skip autocomplete on deletion -- otherwise set_active()
         * would refill the entry and undo the deletion. */
        {
            GtkEventController *key = gtk_event_controller_key_new();
            /* CAPTURE phase: the handler must run BEFORE the entry
             * processes the keystroke, so hwg_seek_skip is already
             * set when the resulting "changed" fires and schedules
             * the deferred seek.  In BUBBLE phase the flag arrives
             * too late and the seek re-fills the entry, undoing the
             * Backspace. */
            gtk_event_controller_set_propagation_phase( key, GTK_PHASE_CAPTURE );
            g_signal_connect( key, "key-pressed",
                              G_CALLBACK( cb_combo_entry_key ), NULL );
            gtk_widget_add_controller( entry, key );
        }
    }

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

HB_FUNC( HWG_COMBOENTRY )
{
    GtkWidget *combo = (GtkWidget*) HB_PARHANDLE( 1 );

    if( !combo || !GTK_IS_COMBO_BOX( combo ) )
    {
        HB_RETHANDLE( NULL );
        return;
    }

    HB_RETHANDLE( gtk_combo_box_get_child( GTK_COMBO_BOX( combo ) ) );
}

HB_FUNC( HWG_COMBOGETTEXT )
{
    GtkWidget   *combo = (GtkWidget*) HB_PARHANDLE( 1 );
    GtkWidget   *entry;
    const gchar *text;

    if( !combo || !GTK_IS_COMBO_BOX( combo ) )
    {
        hb_retc( "" );
        return;
    }

    entry = gtk_combo_box_get_child( GTK_COMBO_BOX( combo ) );
    if( !entry || !GTK_IS_EDITABLE( entry ) )
    {
        hb_retc( "" );
        return;
    }

    text = gtk_editable_get_text( GTK_EDITABLE( entry ) );

    if( text && *text )
    {
        char *cptr = hwg_convert_from_utf8( text );
        hb_retc( cptr );
        g_free( cptr );
    }
    else
    {
        hb_retc( "" );
    }
}

HB_FUNC( HWG_COMBOSEEKPREFIX )
{
    GtkWidget          *combo = (GtkWidget*) HB_PARHANDLE( 1 );
    const gchar        *prefix = hb_parc( 2 );
    HWG_COMBO_SEEK_CTX *ctx;

    if( !combo || !GTK_IS_COMBO_BOX( combo ) || !prefix || !*prefix )
    {
        hb_retni( 0 );
        return;
    }

    if( g_object_get_data( G_OBJECT( combo ), "hwg_autocompleting" ) )
    {
        hb_retni( 0 );
        return;
    }

    /* Backspace/Delete just ran: consume the flag here and bail out
     * before scheduling the idle.  If the flag were left for the idle
     * to check, an earlier keystroke's idle could clear it first, and
     * the autocomplete would refill the text the user just deleted. */
    if( g_object_get_data( G_OBJECT( combo ), "hwg_seek_skip" ) )
    {
        g_object_set_data( G_OBJECT( combo ), "hwg_seek_skip", NULL );
        hb_retni( 0 );
        return;
    }

    if( g_object_get_data( G_OBJECT( combo ), "hwg_seek_pending" ) )
    {
        hb_retni( 0 );
        return;
    }

    g_object_set_data( G_OBJECT( combo ), "hwg_seek_pending",
                       GINT_TO_POINTER( 1 ) );

    ctx = g_new0( HWG_COMBO_SEEK_CTX, 1 );
    ctx->combo  = combo;
    ctx->prefix = g_strdup( prefix );
    g_idle_add( hwg_combo_seek_idle, ctx );

    hb_retni( 1 );
}


HB_FUNC( HWG_COMBOPOPUP )
{
    gtk_combo_box_popup( GTK_COMBO_BOX( HB_PARHANDLE( 1 ) ) );
}


/* =====================================================================
 *  Combo: limit the number of visible rows in the dropdown popup
 *
 *  Windows honours DisplayCount by sizing the dropdown to show only
 *  the requested number of items; GTK2 ignored it entirely.  On GTK4
 *  the combo's popup is a GtkPopover that contains a GtkScrolledWindow.
 *  Setting its "max-content-height" is the exact equivalent.
 * ===================================================================== */

static GtkWidget *hwg_find_descendant( GtkWidget *parent, GType type )
{
    GtkWidget *child = gtk_widget_get_first_child( parent );

    while( child )
    {
        if( G_TYPE_CHECK_INSTANCE_TYPE( child, type ) )
            return child;

        {
            GtkWidget *found = hwg_find_descendant( child, type );
            if( found )
                return found;
        }

        child = gtk_widget_get_next_sibling( child );
    }
    return NULL;
}

static void hwg_combo_apply_display_count( GtkWidget *combo )
{
    int        count;
    int        row_height;
    GtkWidget *popover;
    GtkWidget *scrolled;
    GtkWidget *child;

    if( !combo || !GTK_IS_COMBO_BOX( combo ) )
        return;

    count = GPOINTER_TO_INT( g_object_get_data( G_OBJECT( combo ),
                                                "hwg_display_count" ) );
    if( count <= 0 )
        return;

    /* The popup is a child of the combo box. */
    popover = NULL;
    child = gtk_widget_get_first_child( combo );
    while( child )
    {
        if( GTK_IS_POPOVER( child ) )
        {
            popover = child;
            break;
        }
        child = gtk_widget_get_next_sibling( child );
    }
    if( !popover )
        return;

    scrolled = hwg_find_descendant( popover, GTK_TYPE_SCROLLED_WINDOW );
    if( !scrolled )
        return;

    /* Row height: use the combo's own height (the entry matches the
     * list rows in GTK4), fall back to a sane default. */
    row_height = gtk_widget_get_height( combo );
    if( row_height <= 0 )
        row_height = 28;

    gtk_scrolled_window_set_propagate_natural_height(
        GTK_SCROLLED_WINDOW( scrolled ), TRUE );
    gtk_scrolled_window_set_max_content_height(
        GTK_SCROLLED_WINDOW( scrolled ), row_height * count );
}

static gboolean hwg_combo_reapply_idle( gpointer data )
{
    hwg_combo_apply_display_count( GTK_WIDGET( data ) );
    g_object_unref( data );
    return G_SOURCE_REMOVE;
}

static void hwg_combo_popup_shown( GObject *obj, GParamSpec *pspec,
                                   gpointer user_data )
{
    gboolean shown = FALSE;

    HB_SYMBOL_UNUSED( pspec );
    HB_SYMBOL_UNUSED( user_data );

    /* GTK4: popup-shown is a read-only property.  There is no
     * gtk_combo_box_get_popup_shown() function; read it via g_object_get(). */
    g_object_get( obj, "popup-shown", &shown, NULL );

    if( shown )
    {
        /* Apply once synchronously (to avoid a first-show flash) and
         * again on the next idle (GTK may re-layout the popup after
         * the notify handler). */
        hwg_combo_apply_display_count( GTK_WIDGET( obj ) );
        g_object_ref( obj );
        g_idle_add( hwg_combo_reapply_idle, obj );
    }
}

HB_FUNC( HWG_COMBOSETDISPLAYCOUNT )
{
    GtkWidget *combo = (GtkWidget*) HB_PARHANDLE( 1 );
    int        count = hb_parni( 2 );

    if( !combo || !GTK_IS_COMBO_BOX( combo ) )
        return;

    g_object_set_data( G_OBJECT( combo ), "hwg_display_count",
                       GINT_TO_POINTER( count ) );

    if( !g_object_get_data( G_OBJECT( combo ), "hwg_dc_hooked" ) )
    {
        g_signal_connect( combo, "notify::popup-shown",
                          G_CALLBACK( hwg_combo_popup_shown ), NULL );
        g_object_set_data( G_OBJECT( combo ), "hwg_dc_hooked",
                           GINT_TO_POINTER( 1 ) );
    }
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
    hwg_set_size_request( hCtrl, hb_parni( 4 ), hb_parni( 5 ) );

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
 *  Scrollbar visibility
 *
 *  A GtkScrollbar outside a GtkScrolledWindow does not manage its own
 *  visibility when the adjustment range changes -- unlike
 *  GtkScrolledWindow, which has internal logic for that.  On Win32 the
 *  WS_VSCROLL / WS_HSCROLL bits in the browse STYLE mean "always show
 *  the bar", and HWGUI callers rely on that: HWG_CREATEBROWSE only
 *  creates the widget when its flag is present, so the callback below
 *  simply keeps the bar visible across adjustment notifies.
 * ===================================================================== */
static void hwg_sync_scrollbar_visibility( GtkAdjustment *adj, GtkWidget *bar )
{
    HB_SYMBOL_UNUSED( adj );

    if( !bar || !GTK_IS_WIDGET( bar ) )
        return;

    gtk_widget_set_visible( bar, TRUE );
}

static void cb_scrollbar_visibility( GtkAdjustment *adj, GParamSpec *pspec,
                                     gpointer bar )
{
    HB_SYMBOL_UNUSED( pspec );
    hwg_sync_scrollbar_visibility( adj, GTK_WIDGET( bar ) );
}


/* =====================================================================
 *  HWG_CREATEBROWSE
 * ===================================================================== */
HB_FUNC( HWG_CREATEBROWSE )
{
    GtkWidget *hbox;
    GtkFixed  *inner;
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
    int nBarV = ( ulStyle & WS_VSCROLL ) ? 16 : 0;
    int nBarH = ( ulStyle & WS_HSCROLL ) ? 16 : 0;
    int nAreaW = nWidth  - nBarV;
    int nAreaH = nHeight - nBarH;

    if( nAreaW < 0 ) nAreaW = 0;
    if( nAreaH < 0 ) nAreaH = 0;

    temp   = GetObjectVar( pObject, "OPARENT" );
    handle = (GObject*) HB_GETHANDLE( GetObjectVar( temp, "HANDLE" ) );

    /*
     * GtkFixed never renegotiates/shrinks a child below the size it
     * was given -- unlike GtkBox, which (when the sum of children's
     * minimum sizes exceeds the space available) proportionally
     * shrinks ALL children, including non-expanding ones, and can
     * compress the vertical scrollbar down to zero width. Using an
     * inner GtkFixed with hard-coded pixel positions/sizes for area,
     * vscroll and hscroll sidesteps that negotiation entirely: each
     * widget always gets exactly the rectangle it was assigned.
     */
    hbox  = gtk_fixed_new();
    inner = (GtkFixed*) hbox;
    area  = gtk_drawing_area_new();

    gtk_widget_set_size_request( area, nAreaW, nAreaH );
    gtk_fixed_put( inner, area, 0, 0 );

    if( ulStyle & WS_VSCROLL )
    {
        GtkAdjustment *adjV = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
        vscroll = gtk_scrollbar_new( GTK_ORIENTATION_VERTICAL, adjV );
        gtk_widget_set_size_request( vscroll, nBarV, nAreaH );
        gtk_fixed_put( inner, vscroll, nAreaW, 0 );

        /* GTK4 widgets are born invisible.  Show the bar up front so
         * it appears even when the content fits and Paint() never
         * triggers a notify on the adjustment. */
        gtk_widget_set_visible( vscroll, TRUE );

        g_signal_connect( adjV, "notify::upper",
                          G_CALLBACK( cb_scrollbar_visibility ), vscroll );
        g_signal_connect( adjV, "notify::page-size",
                          G_CALLBACK( cb_scrollbar_visibility ), vscroll );
        g_signal_connect( adjV, "notify::lower",
                          G_CALLBACK( cb_scrollbar_visibility ), vscroll );

        temp = HB_PUTHANDLE( NULL, adjV );
        SetObjectVar( pObject, "_HSCROLLV", temp );
        hb_itemRelease( temp );

        SetWindowObject( (GtkWidget*) adjV, pObject );
        set_signal( (gpointer) adjV, "value-changed", WM_VSCROLL, 0, 0 );
    }

    if( ulStyle & WS_HSCROLL )
    {
        GtkAdjustment *adjH = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
        hscroll = gtk_scrollbar_new( GTK_ORIENTATION_HORIZONTAL, adjH );
        gtk_widget_set_size_request( hscroll, nAreaW, nBarH );
        gtk_fixed_put( inner, hscroll, 0, nAreaH );
        gtk_widget_set_visible( hscroll, TRUE );

        g_signal_connect( adjH, "notify::upper",
                          G_CALLBACK( cb_scrollbar_visibility ), hscroll );
        g_signal_connect( adjH, "notify::page-size",
                          G_CALLBACK( cb_scrollbar_visibility ), hscroll );
        g_signal_connect( adjH, "notify::lower",
                          G_CALLBACK( cb_scrollbar_visibility ), hscroll );

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

HB_FUNC( HWG_SETSCROLLVISIBLE )
{
    GtkWidget *w = (GtkWidget*) HB_PARHANDLE( 1 );
    HB_BOOL    bVisible = hb_parl( 2 );

    if( w && GTK_IS_WIDGET( w ) )
        gtk_widget_set_visible( w, bVisible );
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

    hwg_set_size_request( hCtrl, nW, nH );

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
    hwg_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

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

    if( ulStyle & WS_VSCROLL )
    {
        GtkAdjustment *adjV = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
        vscroll = gtk_scrollbar_new( GTK_ORIENTATION_VERTICAL, adjV );
        hwg_set_size_request( vscroll, 16, -1 );
        gtk_widget_set_hexpand( vscroll, FALSE );
        gtk_widget_set_vexpand( vscroll, TRUE );
        gtk_widget_set_visible( vscroll, TRUE );
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
        hwg_set_size_request( hbox, nWidth, nHeight );
        if( vscroll ) nWidth  -= 12;
        if( hscroll ) nHeight -= 12;
        hwg_set_size_request( hCtrl, nWidth, nHeight );
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
    hwg_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

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
    hb_retni( (gint) g_timeout_add_full( G_PRIORITY_DEFAULT,
                                         (guint32) hb_parnl( 2 ),
                                         (GSourceFunc) cb_timer,
                                         g_strdup( buf ),
                                         g_free ) );
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
        handle = gdk_pixbuf_new_from_file( hb_parc( 1 ), NULL );
        if( !handle ) {
            HB_RETHANDLE( gdk_cursor_new_from_name( "default", NULL ) );
            return;
        }

        pHandle = alpha2pixbuf( handle, 4095 );
        g_object_unref( handle );
        if( !pHandle ) {
            HB_RETHANDLE( gdk_cursor_new_from_name( "default", NULL ) );
            return;
        }

        texture = gdk_texture_new_for_pixbuf( pHandle );
        g_object_unref( pHandle );
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

        /* Clamp before touching GTK.  The Harbour side computes the
         * new size by subtracting paddings, scrollbar widths and
         * margins; on a small parent those subtractions go negative
         * and GTK4 asserts:
         *   "gtk_widget_set_size_request: assertion 'width >= -1' failed"
         * -1 is the "natural size" sentinel GTK accepts; anything
         * smaller is invalid.  Positive values above the parent size
         * are capped, as before. */
        if( w1 < -1 ) w1 = -1;
        if( h1 < -1 ) h1 = -1;
        if( w1 > pW ) w1 = pW;
        if( h1 > pH ) h1 = pH;

        if( w != w1 || h != h1 ) {
            hwg_set_size_request( widget, w1, h1 );
            if( ch_widget && GTK_IS_WIDGET( ch_widget ) )
                hwg_set_size_request( ch_widget, w1, h1 );

            /*
             * If this widget is a browse's outer container (created by
             * HWG_CREATEBROWSE), it holds an inner GtkFixed with the
             * drawing area and up to two scrollbars placed at absolute
             * pixel positions computed from the ORIGINAL width/height.
             * Resizing the outer container alone leaves those children
             * stale -- Paint()'s row-count math (based on the outer
             * container's live size) then disagrees with what the
             * frozen drawing area can actually show, hiding the
             * scrollbar even though many rows are cut off.  Recompute
             * and reposition them here so a live resize keeps the
             * browse internally consistent.
             */
            {
                GtkWidget *area    = (GtkWidget*) g_object_get_data( (GObject*) widget, "draw" );
                GtkWidget *vscroll = (GtkWidget*) g_object_get_data( (GObject*) widget, "vscroll" );
                GtkWidget *hscroll = (GtkWidget*) g_object_get_data( (GObject*) widget, "hscroll" );

                if( area && GTK_IS_WIDGET( area ) && GTK_IS_FIXED( widget ) )
                {
                    int nBarV  = ( vscroll && GTK_IS_WIDGET( vscroll ) ) ? 16 : 0;
                    int nBarH  = ( hscroll && GTK_IS_WIDGET( hscroll ) ) ? 16 : 0;
                    int nAreaW = w1 - nBarV;
                    int nAreaH = h1 - nBarH;

                    if( nAreaW < 0 ) nAreaW = 0;
                    if( nAreaH < 0 ) nAreaH = 0;

                    hwg_set_size_request( area, nAreaW, nAreaH );

                    if( vscroll && GTK_IS_WIDGET( vscroll ) )
                    {
                        hwg_set_size_request( vscroll, nBarV, nAreaH );
                        gtk_fixed_move( GTK_FIXED( widget ), vscroll, nAreaW, 0 );
                        //gtk_widget_queue_allocate( vscroll );
                        gtk_widget_queue_draw( vscroll );
                    }
                    if( hscroll && GTK_IS_WIDGET( hscroll ) )
                    {
                        hwg_set_size_request( hscroll, nAreaW, nBarH );
                        gtk_fixed_move( GTK_FIXED( widget ), hscroll, 0, nAreaH );
                        //gtk_widget_queue_allocate( hscroll );
                        gtk_widget_queue_draw( hscroll );
                    }

                    /*
                     * Force the whole browse container (and the area
                     * itself) to re-allocate and repaint too -- without
                     * this, the GL renderer can keep a stale cached
                     * render node for the scrollbar's previous
                     * position/size: the CSS engine computes the right
                     * color (visible in GtkInspector), but the actually
                     * painted pixels stay whatever was last drawn.
                     */
                    /* Drop the queue_allocate calls: they force a
                     * re-allocation pass that climbs the entire
                     * parent chain up to the GtkNotebook, and the
                     * notebook redraws its tab strip every time.
                     * The set_size_request above already tells GTK
                     * that the widget's preferred size changed;
                     * GTK will revalidate on its own. */
                    gtk_widget_queue_draw( area );
                    gtk_widget_queue_draw( widget );

                }
            }
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
    hwg_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

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
    GtkWidget *hCtrl  = gtk_box_new( GTK_ORIENTATION_HORIZONTAL, 0 );
    GObject   *handle = (GObject*) HB_PARHANDLE( 1 );
    GtkFixed  *box    = getFixedBox( handle );
    GtkWidget *vbox;
    GtkWidget *menubar;

    if( !box )
    {
        HB_RETHANDLE( hCtrl );
        return;
    }

    vbox = gtk_widget_get_parent( GTK_WIDGET( box ) );
    if( !vbox || !GTK_IS_BOX( vbox ) )
    {
        HB_RETHANDLE( hCtrl );
        return;
    }

    /* Insert the toolbar between the menubar (if any) and the content
     * area (the GtkFixed holding all child widgets).  The Win32 HWGUI
     * convention is:
     *     [ menubar ]            <- topmost
     *     [ toolbar ]            <- below the menubar
     *     [ content GtkFixed ]   <- fills the rest
     *
     * A plain gtk_box_append() puts the toolbar below the content,
     * which is why it appeared at the bottom of the window.  A bare
     * gtk_box_prepend() would put it ABOVE the menubar -- equally
     * wrong.  Inserting right after the menubar (or prepending when
     * there is none) lands it in the correct slot regardless of the
     * order in which MENU...ENDMENU and the toolbar are declared in
     * the .prg. */
    menubar = g_object_get_data( handle, "hwg_menubar" );
    if( menubar && GTK_IS_WIDGET( menubar ) &&
        gtk_widget_get_parent( menubar ) == vbox )
    {
        gtk_box_insert_child_after( GTK_BOX( vbox ), hCtrl, menubar );
    }
    else
    {
        gtk_box_prepend( GTK_BOX( vbox ), hCtrl );
    }

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
    hwg_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

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
    GtkFixed  *box     = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    GdkPixbuf *handle  = gdk_pixbuf_new_from_file( hb_parc( 2 ), NULL );
    GdkPixbuf *pHandle;

    /* gdk_pixbuf_new_from_file() returns NULL on any I/O or decode
     * error.  alpha2pixbuf() calls gdk_pixbuf_add_alpha() with no
     * NULL guard -- GLib will assert, and abort under
     * G_DEBUG=fatal-warnings.  Screen the input here. */
    if( !handle )
    {
        HB_RETHANDLE( NULL );
        return;
    }

    /* alpha2pixbuf() returns a NEW pixbuf; the input is left intact
     * and remains owned by us.  Release it at once, mirroring the
     * pattern already used in draw.c (HWG_ALPHA2PIXBUF,
     * HWG_DRAWTRANSPARENTBITMAP). */
    pHandle = alpha2pixbuf( handle, 16777215 );
    g_object_unref( handle );

    if( !pHandle )
    {
        HB_RETHANDLE( NULL );
        return;
    }

    /* gtk_image_new_from_pixbuf() builds a GdkTexture from the pixbuf
     * (pixel data is copied), so our reference can be dropped once
     * the call returns. */
    hCtrl = gtk_image_new_from_pixbuf( pHandle );
    g_object_unref( pHandle );

    if( box )
        gtk_fixed_put( box, hCtrl, hb_parni( 3 ), hb_parni( 4 ) );
    hwg_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

    HB_RETHANDLE( hCtrl );
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
    hwg_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

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
    hwg_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

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
 *  Per-widget colour
 *
 *  We keep two CSS providers per widget (one for fg, one for bg),
 *  both stored as widget data so they can be removed later.  The
 *  selector is the widget's own name (#GtkEntry123), so rules never
 *  bleed into other widgets.
 *
 *  Same guard as the original set_css_data() path: widgets with a
 *  default GTK name ("GtkEntry", "GtkWindow", ...) are skipped, so
 *  hwg_SetBgColor(window, ...) does not paint the whole window.
 * ===================================================================== */
/* Custom destroy notifier: removes the provider from the display
 * before releasing it.  Without this the provider stays attached
 * to the display even after the widget is destroyed, so the rule
 * leaks into the next dialog that reuses the same widget name. */
static void hwg_provider_destroy( gpointer data )
{
    GtkCssProvider *p = GTK_CSS_PROVIDER( data );
    GdkDisplay     *display = gdk_display_get_default();

    if( display )
    {
        gtk_style_context_remove_provider_for_display(
            display, GTK_STYLE_PROVIDER( p ) );
    }
        g_object_unref( p );
}

static void hwg_apply_widget_color( GtkWidget *w, const char *property,
                                    long int color )
{
    const char *name;
    const char *key;
    char        szColor[8];
    char        szCss[256];
    GtkCssProvider *p;

    if( !w || !GTK_IS_WIDGET( w ) )
        return;

    name = gtk_widget_get_name( w );
    if( !name || strncmp( name, "Gtk", 3 ) == 0 )
        return;

    key = ( strcmp( property, "color" ) == 0 ) ? "hwg_css_fg" : "hwg_css_bg";

    hwg_colorN2C( (unsigned int) color, szColor );
    snprintf( szCss, sizeof( szCss ), "#%s { %s: #%s; }",
              name, property, szColor );

    p = g_object_get_data( G_OBJECT( w ), key );
    if( !p )
    {
        p = gtk_css_provider_new();
        gtk_style_context_add_provider_for_display(
            gdk_display_get_default(),
                                                   GTK_STYLE_PROVIDER( p ),
                                                   GTK_STYLE_PROVIDER_PRIORITY_APPLICATION );
        g_object_set_data_full( G_OBJECT( w ), key, p, hwg_provider_destroy );
    }
    gtk_css_provider_load_from_data( p, szCss, -1 );
}

static void hwg_clear_widget_color( GtkWidget *w, const char *key )
{
    if( !w || !GTK_IS_WIDGET( w ) )
        return;

    /* Setting the data to NULL fires the destroy notifier, which
     * removes the provider from the display and unrefs it. */
    g_object_set_data( G_OBJECT( w ), key, NULL );
}

HB_FUNC( HWG_SETFGCOLOR )
{
    hwg_apply_widget_color( (GtkWidget*) HB_PARHANDLE(1),
                            "color", hb_parnl(2) );
}

HB_FUNC( HWG_SETBGCOLOR )
{
    hwg_apply_widget_color( (GtkWidget*) HB_PARHANDLE(1),
                            "background-color", hb_parnl(2) );
}

HB_FUNC( HWG_CLEARFGCOLOR )
{
    hwg_clear_widget_color( (GtkWidget*) HB_PARHANDLE(1), "hwg_css_fg" );
}

HB_FUNC( HWG_CLEARBGCOLOR )
{
    hwg_clear_widget_color( (GtkWidget*) HB_PARHANDLE(1), "hwg_css_bg" );
}


/* =====================================================================
 *  Theme detection
 *
 *  GTK4 does not expose a supported way to query the current theme's
 *  colours programmatically.  The pragmatic approach used here is:
 *    1. Read org.gnome.desktop.interface color-scheme via GSettings
 *       (works on KDE/GNOME/XFCE with xdg-desktop-portal installed).
 *    2. Fall back to gtk-application-prefer-dark-theme.
 *  From the result we build a small colour set that matches the
 *  standard light/dark palettes closely enough for HWGUI's widgets.
 * ===================================================================== */

static gboolean hwg_is_dark_theme( void )
{
    GSettings   *gset;
    gchar       *scheme;
    gboolean     dark = FALSE;

    /* 1. Ask the desktop portal / GSettings. */
    gset = g_settings_new( "org.gnome.desktop.interface" );
    if( gset )
    {
        scheme = g_settings_get_string( gset, "color-scheme" );
        if( scheme )
        {
            if( g_strcmp0( scheme, "prefer-dark" ) == 0 )
                dark = TRUE;
            g_free( scheme );
        }
        g_object_unref( gset );
    }

    /* 2. Respect an explicit GTK setting if it was forced. */
    if( !dark )
    {
        GtkSettings *gtset = gtk_settings_get_default();
        if( gtset )
            g_object_get( gtset, "gtk-application-prefer-dark-theme",
                          &dark, NULL );
    }

    return dark;
}

/*
 * hwg_GetThemeColors() -> array with 8 elements:
 *   1: bg           (window / browse background)
 *   2: fg           (text)
 *   3: bg_alt       (alternate row / panel background)
 *   4: sel_bg       (selection background)
 *   5: sel_fg       (selection text)
 *   6: header_bg    (column header background)
 *   7: header_fg    (column header text)
 *   8: separator    (grid / separator lines)
 */
HB_FUNC( HWG_GETTHEMECOLORS )
{
    gboolean dark = hwg_is_dark_theme();
    PHB_ITEM aColors = hb_itemArrayNew( 8 );

    if( dark )
    {
        hb_arraySetNL( aColors, 1, 0x2B2B2B );   /* bg         */
        hb_arraySetNL( aColors, 2, 0xE0E0E0 );   /* fg         */
        hb_arraySetNL( aColors, 3, 0x363636 );   /* bg_alt     */
        hb_arraySetNL( aColors, 4, 0x4A90D9 );   /* sel_bg     */
        hb_arraySetNL( aColors, 5, 0xFFFFFF );   /* sel_fg     */
        hb_arraySetNL( aColors, 6, 0x3A3A3A );   /* header_bg  */
        hb_arraySetNL( aColors, 7, 0xD0D0D0 );   /* header_fg  */
        hb_arraySetNL( aColors, 8, 0x555555 );   /* separator  */
    }
    else
    {
        hb_arraySetNL( aColors, 1, 0xFFFFFF );
        hb_arraySetNL( aColors, 2, 0x000000 );
        hb_arraySetNL( aColors, 3, 0xF5F5F5 );
        hb_arraySetNL( aColors, 4, 0x308CC6 );
        hb_arraySetNL( aColors, 5, 0xFFFFFF );
        hb_arraySetNL( aColors, 6, 0xE0E0E0 );
        hb_arraySetNL( aColors, 7, 0x000000 );
        hb_arraySetNL( aColors, 8, 0xC0C0C0 );
    }

    hb_itemReturnRelease( aColors );
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

/* =====================================================================
 *  CheckList
 *
 *  A vertical list of GtkCheckButton rows inside a GtkScrolledWindow.
 *  Replaces the Win32 pattern of a ListView with LVS_EX_CHECKBOXES
 *  for cases where each row is just a label and an independent
 *  boolean.
 *
 *  Handle returned to Harbour: the outer GtkScrolledWindow.  Its
 *  child is the GtkListBox; each GtkListBoxRow's child is a
 *  GtkCheckButton carrying its 1-based row index under the
 *  "hwg_checklist_row" data key.
 *
 *  Every "toggled" fires a WM_USER+1 message on the scrolled window,
 *  so HCheckList:onEvent can run bChange / bSetGet.  wParam carries
 *  the 1-based row index, lParam carries 1 (checked) or 0 (unchecked).
 * ===================================================================== */

#define HWG_MSGLIST_CHECKED  ( WM_USER + 1 )

static void cb_checklist_toggle( GtkCheckButton *btn, gpointer user_data )
{
    GtkWidget *scroll = GTK_WIDGET( user_data );
    gint       row;
    gboolean   active;

    /* Ignore the signal when the change came from
     * HWG_CHECKLIST_SETCHECKED, not from the user. */
    if( g_object_get_data( G_OBJECT( btn ), "hwg_checklist_busy" ) )
        return;

    if( !scroll || !GTK_IS_WIDGET( scroll ) )
        return;

    row    = GPOINTER_TO_INT( g_object_get_data( G_OBJECT( btn ),
                                                 "hwg_checklist_row" ) );
    active = gtk_check_button_get_active( btn );

    hwg_dispatch_onevent( scroll, HWG_MSGLIST_CHECKED,
                          (HB_LONG) row, (HB_LONG) ( active ? 1 : 0 ) );
}

static GtkWidget *hwg_checklist_get_listbox( GtkWidget *scroll )
{
    if( !scroll || !GTK_IS_SCROLLED_WINDOW( scroll ) )
        return NULL;

    return (GtkWidget*) g_object_get_data( (GObject*) scroll,
                                           "hwg_checklist_list" );
}

static GtkWidget *hwg_checklist_get_row_button( GtkWidget *listbox, gint idx )
{
    GtkListBoxRow *row;
    GtkWidget     *btn;

    if( !listbox || !GTK_IS_LIST_BOX( listbox ) || idx < 1 )
        return NULL;

    row = gtk_list_box_get_row_at_index( GTK_LIST_BOX( listbox ), idx - 1 );
    if( !row )
        return NULL;

    btn = gtk_list_box_row_get_child( row );
    return ( btn && GTK_IS_CHECK_BUTTON( btn ) ) ? btn : NULL;
}

static gint hwg_checklist_count( GtkWidget *listbox )
{
    gint n = 0;

    if( !listbox || !GTK_IS_LIST_BOX( listbox ) )
        return 0;

    /* GTK4: GtkListBox does not expose its rows through
     * gtk_widget_get_first_child().  Use the canonical index-based
     * accessor instead; iterate until it returns NULL. */
    while( gtk_list_box_get_row_at_index( GTK_LIST_BOX( listbox ), n ) != NULL )
        n++;

    return n;
}

HB_FUNC( HWG_CREATECHECKLIST )
{
    GtkWidget    *scroll;
    GtkWidget    *listbox;
    GtkFixed     *box    = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );
    unsigned long ulStyle = (unsigned long) hb_parnl( 3 );

    scroll  = gtk_scrolled_window_new();
    listbox = gtk_list_box_new();

    gtk_list_box_set_selection_mode( GTK_LIST_BOX( listbox ),
                                     GTK_SELECTION_NONE );

    gtk_scrolled_window_set_policy( GTK_SCROLLED_WINDOW( scroll ),
                                    GTK_POLICY_AUTOMATIC,
                                    ( ulStyle & WS_VSCROLL ) ? GTK_POLICY_ALWAYS
                                    : GTK_POLICY_AUTOMATIC );

    if( ulStyle & WS_BORDER )
        gtk_scrolled_window_set_has_frame( GTK_SCROLLED_WINDOW( scroll ), TRUE );

    gtk_scrolled_window_set_child( GTK_SCROLLED_WINDOW( scroll ), listbox );

    if( box )
        gtk_fixed_put( box, scroll, hb_parni( 4 ), hb_parni( 5 ) );

    hwg_set_size_request( scroll, hb_parni( 6 ), hb_parni( 7 ) );

    g_object_set_data( (GObject*) scroll, "hwg_checklist_list",
                       (gpointer) listbox );

    HB_RETHANDLE( scroll );
}

HB_FUNC( HWG_CHECKLISTADDITEM )
{
    GtkWidget *scroll  = (GtkWidget*) HB_PARHANDLE( 1 );
    gchar     *cLabel  = hwg_convert_to_utf8( hb_parc( 2 ) );
    gboolean   checked = HB_ISLOG( 3 ) ? hb_parl( 3 ) : FALSE;
    GtkWidget *listbox = hwg_checklist_get_listbox( scroll );
    GtkWidget *row;
    GtkWidget *btn;
    gint       idx;

    if( !listbox )
    {
        g_free( cLabel );
        hb_retni( 0 );
        return;
    }

    btn = gtk_check_button_new_with_label( cLabel );
    gtk_check_button_set_active( GTK_CHECK_BUTTON( btn ), checked );
    gtk_widget_set_margin_start( btn, 6 );
    gtk_widget_set_margin_end( btn, 6 );
    gtk_widget_set_margin_top( btn, 2 );
    gtk_widget_set_margin_bottom( btn, 2 );

    row = gtk_list_box_row_new();
    gtk_list_box_row_set_child( GTK_LIST_BOX_ROW( row ), btn );
    gtk_list_box_row_set_activatable( GTK_LIST_BOX_ROW( row ), FALSE );

    gtk_list_box_append( GTK_LIST_BOX( listbox ), row );

    idx = hwg_checklist_count( listbox );
    g_object_set_data( G_OBJECT( btn ), "hwg_checklist_row",
                       GINT_TO_POINTER( idx ) );

    g_signal_connect( btn, "toggled",
                      G_CALLBACK( cb_checklist_toggle ), scroll );

    g_free( cLabel );
    hb_retni( idx );
}

HB_FUNC( HWG_CHECKLISTCLEAR )
{
    GtkWidget *listbox = hwg_checklist_get_listbox( (GtkWidget*) HB_PARHANDLE( 1 ) );
    gint       total, i;

    if( !listbox )
        return;

    total = hwg_checklist_count( listbox );

    /* Remove from the end so the indexes of the remaining rows do
     * not shift while we iterate.  GtkListBox has no "remove all"
     * call; gtk_list_box_remove() takes the row by pointer and the
     * row we grabbed from get_row_at_index is valid until removed. */
    for( i = total - 1; i >= 0; i-- )
    {
        GtkListBoxRow *row = gtk_list_box_get_row_at_index( GTK_LIST_BOX( listbox ), i );
        if( row )
            gtk_list_box_remove( GTK_LIST_BOX( listbox ), GTK_WIDGET( row ) );
    }
}

HB_FUNC( HWG_CHECKLISTGETCOUNT )
{
    GtkWidget *listbox = hwg_checklist_get_listbox( (GtkWidget*) HB_PARHANDLE( 1 ) );
    hb_retni( hwg_checklist_count( listbox ) );
}

HB_FUNC( HWG_CHECKLISTISCHECKED )
{
    GtkWidget *listbox = hwg_checklist_get_listbox( (GtkWidget*) HB_PARHANDLE( 1 ) );
    GtkWidget *btn     = hwg_checklist_get_row_button( listbox, hb_parni( 2 ) );

    if( !btn )
    {
        hb_retl( FALSE );
        return;
    }

    hb_retl( gtk_check_button_get_active( GTK_CHECK_BUTTON( btn ) ) );
}

HB_FUNC( HWG_CHECKLISTSETCHECKED )
{
    GtkWidget *listbox = hwg_checklist_get_listbox( (GtkWidget*) HB_PARHANDLE( 1 ) );
    GtkWidget *btn     = hwg_checklist_get_row_button( listbox, hb_parni( 2 ) );

    if( !btn )
        return;

    /* Mark as programmatic so cb_checklist_toggle ignores the
     * resulting "toggled".  SetChecked from Harbour must not fire
     * HCheckList:bChange. */
    g_object_set_data( G_OBJECT( btn ), "hwg_checklist_busy",
                       GINT_TO_POINTER( 1 ) );
    gtk_check_button_set_active( GTK_CHECK_BUTTON( btn ), hb_parl( 3 ) );
    g_object_set_data( G_OBJECT( btn ), "hwg_checklist_busy", NULL );
}

HB_FUNC( HWG_CHECKLISTGETCHECKED )
{
    GtkWidget *listbox = hwg_checklist_get_listbox( (GtkWidget*) HB_PARHANDLE( 1 ) );
    PHB_ITEM   aIdx;
    gint       total, i, n;

    if( !listbox )
    {
        hb_reta( 0 );
        return;
    }

    total = hwg_checklist_count( listbox );

    /* First pass: count how many are checked. */
    n = 0;
    for( i = 0; i < total; i++ )
    {
        GtkListBoxRow *row = gtk_list_box_get_row_at_index( GTK_LIST_BOX( listbox ), i );
        GtkWidget     *btn;

        if( !row )
            continue;

        btn = gtk_list_box_row_get_child( row );
        if( btn && GTK_IS_CHECK_BUTTON( btn ) &&
            gtk_check_button_get_active( GTK_CHECK_BUTTON( btn ) ) )
            n++;
    }

    aIdx = hb_itemArrayNew( n );

    /* Second pass: fill with 1-based indexes. */
    n = 0;
    for( i = 0; i < total; i++ )
    {
        GtkListBoxRow *row = gtk_list_box_get_row_at_index( GTK_LIST_BOX( listbox ), i );
        GtkWidget     *btn;

        if( !row )
            continue;

        btn = gtk_list_box_row_get_child( row );
        if( btn && GTK_IS_CHECK_BUTTON( btn ) &&
            gtk_check_button_get_active( GTK_CHECK_BUTTON( btn ) ) )
        {
            PHB_ITEM tmp = hb_itemPutNI( NULL, i + 1 );
            hb_itemArrayPut( aIdx, ++n, tmp );
            hb_itemRelease( tmp );
        }
    }

    hb_itemReturnRelease( aIdx );
}

/* =====================================================================
 *  WebView
 *
 *  Embed a WebKitGTK 6.0 WebKitWebView inside a HWGUI GtkFixed.  The
 *  WebView is a full browser engine: HTML, CSS, JavaScript and Canvas
 *  all work.  Used for charts rendered with Chart.js, reports laid
 *  out in HTML, and any rich content the Cairo drawing area cannot
 *  reach.
 *
 *  The library is GTK4-only -- WebKitGTK 6.0 replaces the older
 *  webkit2gtk-4.0 (GTK3).  Both must not be linked into the same
 *  binary.
 * ===================================================================== */
#include <webkit/webkit.h>

HB_FUNC( HWG_CREATEWEBVIEW )
{
    GtkWidget *wv;
    GtkFixed  *box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );

    wv = webkit_web_view_new();

    if( box )
        gtk_fixed_put( box, wv, hb_parni( 4 ), hb_parni( 5 ) );

    hwg_set_size_request( wv, hb_parni( 6 ), hb_parni( 7 ) );

    HB_RETHANDLE( wv );
}

HB_FUNC( HWG_WEBVIEWLOADHTML )
{
    GtkWidget  *wv   = (GtkWidget*) HB_PARHANDLE( 1 );
    const char *html = hb_parc( 2 );

    if( wv && WEBKIT_IS_WEB_VIEW( wv ) && html )
        webkit_web_view_load_html( WEBKIT_WEB_VIEW( wv ), html, NULL );
}

HB_FUNC( HWG_WEBVIEWRUNJS )
{
    GtkWidget  *wv = (GtkWidget*) HB_PARHANDLE( 1 );
    const char *js = hb_parc( 2 );

    if( wv && WEBKIT_IS_WEB_VIEW( wv ) && js )
        webkit_web_view_evaluate_javascript( WEBKIT_WEB_VIEW( wv ),
                                             js, -1, NULL, NULL, NULL,
                                             NULL, NULL );
}
/* ====================== EOF of control.c ======================= */
