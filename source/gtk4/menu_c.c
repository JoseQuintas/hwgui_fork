/*
 * $Id: menu_c.c 3712 2025-05-01 19:38:40Z itamarlins $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level menu functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * ARCHITECTURAL NOTE
 * ------------------
 * GTK 4.10 removed GtkMenuBar, GtkMenu, GtkMenuItem and all their
 * subclasses.  Menus are now data-driven:
 *
 *      GMenuModel   ->   GtkPopoverMenuBar   (menu bar)
 *                   ->   GtkPopoverMenu      (popup / context menu)
 *
 * Each item is a GMenuItem inside a GMenu.  Activation goes through
 * named GActions registered on a GActionMap.  The legacy "activate"
 * signal with a gpointer data argument no longer exists.
 *
 * IMPORTANT (GTK4): plain GtkWindow does NOT implement GActionMap any
 * more.  Only GtkApplicationWindow does.  Since HWGUI does not use a
 * GtkApplication, we install a per-window GSimpleActionGroup with the
 * prefix "hwg" via gtk_widget_insert_action_group() and register all
 * menu actions there.
 *
 * To keep the Harbour API unchanged we map:
 *      "menu handle"        ->  GMenu
 *      "menu item handle"   ->  GMenuItem / GMenu (see below)
 *      "accel table handle" ->  GtkShortcutController
 *
 * Handle type per item:
 *   - Regular / check items  -> GMenuItem
 *   - Separators             -> section break (no handle returned)
 *   - Submenus (top-level)   -> GMenu (the submenu model itself)
 *
 * The owning window is stored under the key "hwg_wnd", and the
 * associated action name under "hwg_actname".  Both keys are attached
 * to whichever object the Harbour side actually stores (GMenuItem for
 * regular items, GMenu for submenus).
 *
 * SEPARATORS
 * ----------
 * GTK4 has no GtkSeparatorMenuItem.  Instead, we group items into
 * "sections" inside each submenu GMenu.  GtkPopoverMenu draws a
 * horizontal line between two adjacent sections.  Each SEPARATOR in
 * the Harbour menu definition closes the current section; the next
 * item starts a fresh one.
 *
 * The menubar (GtkPopoverMenuBar) expects a flat model, so its
 * top-level items are added directly to the model, bypassing the
 * section grouping (they are marked with "hwg_is_menubar").
 *
 * TOP-LEVEL ENABLE / DISABLE
 * --------------------------
 * GtkPopoverMenuBar renders each top-level item as a
 * GtkPopoverMenuBarItem widget that is NOT bound to any action -- it
 * simply opens the submenu popover.  Setting the associated GAction
 * to disabled has no visual effect on it.
 *
 * To make hwg__EnableMenuItem work on top-level items we therefore
 * walk the menubar's direct children once, right after it is built,
 * and link each child widget to its submenu GMenu under the
 * "hwg_menubar_button" key.  hwg__EnableMenuItem then toggles both
 * gtk_widget_set_sensitive() and gtk_widget_set_can_target() on that
 * widget, so the item is greyed out and does not respond to mouse
 * hover or clicks.
 */

#include "guilib.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "gtk/gtk.h"
#include "hwgtk4.h"

#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

#include "warnings.h"

#define  FLAG_DISABLED   1
#define  FLAG_CHECK      2

#define  HWG_ACTION_PREFIX   "hwg"

extern GtkWidget *aWindows[];
extern void       cb_signal( GtkWidget *widget, gchar *data );
extern GtkFixed  *getFixedBox( GObject *handle );
extern GtkWidget *GetActiveWindow( void );


/* =====================================================================
 *  Internal state
 * ===================================================================== */
static guint       s_menu_action_counter = 0;

typedef struct {
    long      nId;
    GtkWidget *hWnd;
    gboolean   bSubmenu;   /* TRUE for top-level items that open a submenu */
} HWG_MENU_ACTION;


/* =====================================================================
 *  Per-window action group
 *
 *  GTK4: GtkWindow does not implement GActionMap.  We attach a
 *  GSimpleActionGroup to each window, using the "hwg" prefix, and
 *  register all menu actions there.
 * ===================================================================== */
static GSimpleActionGroup *hwg_get_action_group( GtkWidget *hWnd )
{
    GSimpleActionGroup *group;

    if( !hWnd || !GTK_IS_WIDGET( hWnd ) )
        return NULL;

    group = g_object_get_data( G_OBJECT( hWnd ), "hwg_action_group" );
    if( !group )
    {
        group = g_simple_action_group_new();
        g_object_set_data_full( G_OBJECT( hWnd ), "hwg_action_group",
                                g_object_ref( group ), g_object_unref );
        gtk_widget_insert_action_group( hWnd, HWG_ACTION_PREFIX,
                                        G_ACTION_GROUP( group ) );
        g_object_unref( group );
    }
    return group;
}


/* =====================================================================
 *  Action activation -> cb_signal (legacy bridge)
 * ===================================================================== */
static void hwg_menu_action_activate( GSimpleAction *action,
                                      GVariant *param, gpointer user_data )
{
    HWG_MENU_ACTION *ctx = (HWG_MENU_ACTION *) user_data;
    char buf[64];

    HB_SYMBOL_UNUSED( action );
    HB_SYMBOL_UNUSED( param );

    if( !ctx ) return;

    /*
     * Submenu items: GTK opens the popover on its own.  We must not
     * forward this to Harbour, otherwise the application would receive
     * a spurious ONEVENT when the user merely opens the submenu.
     */
    if( ctx->bSubmenu ) return;

    snprintf( buf, sizeof(buf), "0 %ld %ld",
              ctx->nId, (long) ctx->hWnd );
    cb_signal( ctx->hWnd, buf );
}


static void hwg_menu_action_free( gpointer data )
{
    g_free( data );
}


/* =====================================================================
 *  Section management
 *
 *  GtkPopoverMenu draws a horizontal separator line between two
 *  adjacent sections of a GMenu.  We keep a "current section" pointer
 *  inside each model's metadata; SEPARATOR closes it, and the next
 *  item opens a new one.
 * ===================================================================== */

/* Return the current section of a submenu model, creating it if needed. */
static GMenu *hwg_menu_current_section( GMenu *model )
{
    GMenu *section = g_object_get_data( G_OBJECT( model ),
                                        "hwg_current_section" );

    if( !section ) {
        section = g_menu_new();
        g_menu_append_section( model, NULL, G_MENU_MODEL( section ) );
        g_object_set_data_full( G_OBJECT( model ), "hwg_current_section",
                                section, g_object_unref );
    }
    return section;
}

/* Close the current section.  The next item will start a new one. */
static void hwg_menu_close_section( GMenu *model )
{
    g_object_set_data( G_OBJECT( model ), "hwg_current_section", NULL );
}


/* =====================================================================
 *  hwg__CreateMenu  ->  GMenu (top-level menu bar model)
 * ===================================================================== */
HB_FUNC( HWG__CREATEMENU )
{
    GMenu *model = g_menu_new();

    /*
     * GtkPopoverMenuBar expects a flat model (no sections), so we
     * flag this model as a menubar and bypass the section grouping
     * used for popover menus.
     */
    g_object_set_data( G_OBJECT( model ), "hwg_is_menubar",
                       GINT_TO_POINTER( 1 ) );

    HB_RETHANDLE( model );
}

/* =====================================================================
 *  hwg__CreatePopupMenu  ->  GMenu (for context / popup menus)
 * ===================================================================== */
HB_FUNC( HWG__CREATEPOPUPMENU )
{
    GMenu *model = g_menu_new();
    HB_RETHANDLE( model );
}


/* =====================================================================
 *  hwg__AddMenuItem( hMenu, cCaption, nPos, hWnd, nId, fState, lSubMenu )
 *
 *  Returns:
 *    - a GMenuItem handle for a normal item
 *    - a GMenu handle for a submenu (caller adds items to it)
 *    - NULL handle for a separator (section break)
 * ===================================================================== */
HB_FUNC( HWG__ADDMENUITEM )
{
    GMenu              *model;
    GMenuItem          *item;
    GSimpleAction      *action;
    GSimpleActionGroup *group;
    GtkWidget          *hWnd;
    HWG_MENU_ACTION    *ctx;
    gchar              *action_full_name;    /* "hwg.act.N" */
    gchar              *action_simple_name;  /* "act.N"     */
    gchar              *gcLabel;
    const char         *cCaption = HB_ISCHAR(2) ? hb_parc(2) : NULL;
    long                nId;
    int                 nFlags;
    gboolean            bCheck;
    gboolean            bDisabled;
    gboolean            bSubMenu;
    gboolean            bIsSeparator = TRUE;

    model = ( HB_PARHANDLE(1) && G_IS_MENU( HB_PARHANDLE(1) ) )
    ? G_MENU( HB_PARHANDLE(1) ) : NULL;
    if( !model ) { hb_ret(); return; }

    hWnd      = (GtkWidget *) HB_PARHANDLE(4);
    nId       = hb_parnl(5);
    nFlags    = HB_ISNIL(6) ? 0 : hb_parni(6);
    bSubMenu  = !HB_ISNIL(7) && hb_parl(7);
    bCheck    = ( nFlags & FLAG_CHECK    ) != 0;
    bDisabled = ( nFlags & FLAG_DISABLED ) != 0;

    /* Detect separator / stock / regular item */
    if( cCaption ) {
        const char *p = cCaption;
        while( *p ) {
            if( *p != ' ' && *p != '-' ) { bIsSeparator = FALSE; break; }
            p++;
        }
    }

    /* ---------- separator ---------- */
    if( bIsSeparator ) {
        /*
         * GTK4 has no GtkSeparatorMenuItem.  Instead, we close the
         * current section so that the next item starts a new one;
         * GtkPopoverMenu then draws a horizontal line between the
         * two sections.
         */
        hwg_menu_close_section( model );

        hb_ret();
        return;
    }

    /* ---------- submenu ---------- */
    if( bSubMenu ) {
        GMenu *submenu = g_menu_new();
        gchar *sub_action_simple;
        gchar *sub_action_full;

        /*
         * GTK4: a GMenuItem that carries a submenu has no action of its
         * own.  We still attach a dummy GSimpleAction to the item so
         * that the Harbour-side API (enable/check/is*) has something to
         * manipulate consistently across item types.  The visible
         * enable/disable effect on the top-level button is handled
         * separately (see hwg__EnableMenuItem).
         */
        sub_action_simple = g_strdup_printf( "sub.%u", ++s_menu_action_counter );
        sub_action_full   = g_strdup_printf( "%s.%s",
                                             HWG_ACTION_PREFIX,
                                             sub_action_simple );

        ctx = g_new0( HWG_MENU_ACTION, 1 );
        ctx->nId      = nId;
        ctx->hWnd     = hWnd;
        ctx->bSubmenu = TRUE;

        action = g_simple_action_new( sub_action_simple, NULL );
        g_simple_action_set_enabled( action, !bDisabled );
        g_signal_connect( action, "activate",
                          G_CALLBACK( hwg_menu_action_activate ), ctx );

        if( hWnd && GTK_IS_WIDGET( hWnd ) ) {
            group = hwg_get_action_group( hWnd );
            if( group )
                g_action_map_add_action( G_ACTION_MAP( group ),
                                         G_ACTION( action ) );
        }
        g_object_unref( action );

        gcLabel = hwg_convert_to_utf8( cCaption );
        item    = g_menu_item_new( gcLabel, sub_action_full );
        g_free( gcLabel );

        g_menu_item_set_submenu( item, G_MENU_MODEL( submenu ) );
        g_menu_append_item( model, item );

        /*
         * Metadata is attached to the submenu GMenu (not the GMenuItem)
         * because that is the handle the Harbour side stores and passes
         * back to hwg__EnableMenuItem / hwg__CheckMenuItem.
         */
        g_object_set_data( G_OBJECT( submenu ), "hwg_wnd", hWnd );
        g_object_set_data_full( G_OBJECT( submenu ), "hwg_actname",
                                g_strdup( sub_action_full ), g_free );
        g_object_set_data_full( G_OBJECT( submenu ), "hwg_ctx",
                                ctx, hwg_menu_action_free );

        g_free( sub_action_simple );
        g_free( sub_action_full );

        HB_RETHANDLE( submenu );
        return;
    }

    /* ---------- normal / check item ---------- */
    action_simple_name = g_strdup_printf( "act.%u", ++s_menu_action_counter );
    action_full_name   = g_strdup_printf( "%s.%s",
                                          HWG_ACTION_PREFIX,
                                          action_simple_name );

    ctx = g_new0( HWG_MENU_ACTION, 1 );
    ctx->nId      = nId;
    ctx->hWnd     = hWnd;
    ctx->bSubmenu = FALSE;

    if( bCheck )
    {
        action = g_simple_action_new_stateful( action_simple_name, NULL,
                                               g_variant_new_boolean( FALSE ) );
    }
    else
    {
        action = g_simple_action_new( action_simple_name, NULL );
    }

    g_simple_action_set_enabled( action, !bDisabled );
    g_signal_connect( action, "activate",
                      G_CALLBACK( hwg_menu_action_activate ), ctx );

    if( hWnd && GTK_IS_WIDGET( hWnd ) )
    {
        group = hwg_get_action_group( hWnd );
        if( group )
            g_action_map_add_action( G_ACTION_MAP( group ),
                                     G_ACTION( action ) );
    }
    g_object_unref( action );

    gcLabel = hwg_convert_to_utf8( cCaption );
    item    = g_menu_item_new( gcLabel, action_full_name );
    g_free( gcLabel );

    if( bCheck )
    {
        g_menu_item_set_attribute_value( item, "state",
                                         g_variant_new_boolean( FALSE ) );
    }

    /*
     * Menubar top-level items go directly into the model (flat).
     * Submenu items are grouped into sections so GtkPopoverMenu
     * draws separator lines between them.
     */
    if( g_object_get_data( G_OBJECT( model ), "hwg_is_menubar" ) )
        g_menu_append_item( model, item );
    else
        g_menu_append_item( hwg_menu_current_section( model ), item );

    g_object_set_data_full( G_OBJECT( item ), "hwg_actname",
                            g_strdup( action_full_name ), g_free );
    g_object_set_data( G_OBJECT( item ), "hwg_wnd", hWnd );
    g_object_set_data_full( G_OBJECT( item ), "hwg_ctx",
                            ctx, hwg_menu_action_free );

    g_free( action_simple_name );
    g_free( action_full_name );

    HB_RETHANDLE( item );
}


/* =====================================================================
 *  hwg__SetMenu( hWnd, hMenu )
 *  Materialize a GtkPopoverMenuBar from the GMenuModel and insert it at
 *  the top of the window's vertical box.
 * ===================================================================== */

/*
 * Walk the GtkPopoverMenuBar's direct children.  In GTK 4 the children
 * are GtkPopoverMenuBarItem widgets, one per top-level item, in the
 * same order as the items in the model.  There is no intermediate
 * GtkBox.
 *
 * For each child that corresponds to a submenu, store its pointer in
 * the submenu GMenu's metadata under "hwg_menubar_button".  This lets
 * hwg__EnableMenuItem toggle widget sensitivity directly, since the
 * item widget is not bound to the submenu's dummy GAction.
 */
static void hwg_link_menubar_buttons( GtkWidget *menubar, GMenuModel *model )
{
    GtkWidget *child;
    guint      i, n;

    if( !menubar || !model ) return;

    n     = g_menu_model_get_n_items( model );
    child = gtk_widget_get_first_child( menubar );

    for( i = 0; i < n && child; i++ )
    {
        GMenuModel *submenu =
        g_menu_model_get_item_link( model, i, G_MENU_LINK_SUBMENU );

        if( submenu && G_IS_MENU( submenu ) )
        {
            g_object_set_data( G_OBJECT( submenu ),
                               "hwg_menubar_button", child );
        }

        child = gtk_widget_get_next_sibling( child );
    }
}


HB_FUNC( HWG__SETMENU )
{
    GObject    *handle = (GObject *)    HB_PARHANDLE(1);
    GMenuModel *model  = (GMenuModel *) HB_PARHANDLE(2);
    GtkFixed   *box;
    GtkWidget  *vbox;
    GtkWidget  *menubar;
    GtkWidget  *old;

    if( !model || !G_IS_MENU_MODEL( model ) ) { hb_retl(0); return; }

    box  = getFixedBox( handle );
    vbox = box ? gtk_widget_get_parent( GTK_WIDGET( box ) ) : NULL;

    if( !vbox || !GTK_IS_BOX( vbox ) ) {
        g_warning( "HWG__SETMENU: parent widget is not a GtkBox!" );
        hb_retl( 0 );
        return;
    }

    /* Make sure the action group exists before the menu is shown. */
    if( GTK_IS_WIDGET( handle ) )
        hwg_get_action_group( GTK_WIDGET( handle ) );

    /* Remove any previously installed menubar for this window */
    old = g_object_get_data( handle, "hwg_menubar" );
    if( old && GTK_IS_WIDGET( old ) )
        gtk_box_remove( GTK_BOX( vbox ), old );

    menubar = gtk_popover_menu_bar_new_from_model( model );
    gtk_widget_set_halign( menubar, GTK_ALIGN_FILL );
    gtk_widget_set_valign( menubar, GTK_ALIGN_START );
    gtk_widget_set_vexpand( menubar, FALSE );
    gtk_widget_set_hexpand( menubar, TRUE );

    /*
     * Some GTK4 builds emit:
     *   "GtkGizmo ... (slider) reported min width -2, but sizes must be >= 0"
     * from the internal scrollbar of GtkPopoverMenuBar.  Explicitly
     * requesting a sensible height (>= 0) prevents the negative size
     * computation in the internal scrollbar.
     */
    gtk_widget_set_size_request( menubar, -1, 30 );

    gtk_box_prepend( GTK_BOX( vbox ), menubar );
    gtk_widget_set_visible( menubar, TRUE );

    g_object_set_data( handle, "hwg_menubar", menubar );

    /*
     * Link top-level item widgets to their submenu models so that
     * hwg__EnableMenuItem can later toggle widget sensitivity directly.
     */
    hwg_link_menubar_buttons( menubar, model );

    hb_retl( 1 );
}


HB_FUNC( HWG_GETMENUHANDLE )
{
    /* In GTK4 the "menu" is a GMenuModel, not a widget. */
    hb_ret();
}


/* =====================================================================
 *  Helpers to look up a menu item's action name and owning window
 * ===================================================================== */
/*
 * Return the full action name ("hwg.act.N") associated with a menu
 * object.  Accepts both GMenuItem (regular items) and GMenu (submenus,
 * which are returned by hwg__AddMenuItem when lSubMenu=.T.).
 */
static const gchar *hwg_item_action_name( GObject *obj )
{
    const gchar *n;
    const gchar *action = NULL;

    if( !obj ) return NULL;

    n = g_object_get_data( obj, "hwg_actname" );
    if( n ) return n;

    if( G_IS_MENU_ITEM( obj ) ) {
        if( g_menu_item_get_attribute( G_MENU_ITEM( obj ),
            G_MENU_ATTRIBUTE_ACTION, "s", &action ) )
            return action;
    }

    return NULL;
}


/* Strip the "hwg." prefix from a full action name. */
static const gchar *hwg_action_simple_name( const gchar *full )
{
    if( !full ) return NULL;
    if( g_str_has_prefix( full, HWG_ACTION_PREFIX "." ) )
        return full + strlen( HWG_ACTION_PREFIX ) + 1;
    return full;
}


/* Look up an action in the window's action group. */
static GAction *hwg_lookup_action( GtkWidget *hWnd, const gchar *full_name )
{
    GSimpleActionGroup *group;
    const gchar        *simple_name;

    if( !hWnd || !full_name ) return NULL;

    group = g_object_get_data( G_OBJECT( hWnd ), "hwg_action_group" );
    if( !group ) return NULL;

    simple_name = hwg_action_simple_name( full_name );
    return g_action_map_lookup_action( G_ACTION_MAP( group ), simple_name );
}


/* =====================================================================
 *  hwg__CheckMenuItem( hMenuItemOrSubmenu [, lChecked] )
 * ===================================================================== */
HB_FUNC( HWG__CHECKMENUITEM )
{
    GObject     *obj = (GObject *) HB_PARHANDLE(1);
    GtkWidget   *hWnd;
    const gchar *name;
    GAction     *action;
    gboolean     bSet = HB_ISNIL(2) ? TRUE : hb_parl(2);

    if( !obj || !G_IS_OBJECT( obj ) ) { hb_ret(); return; }
    if( !G_IS_MENU_ITEM( obj ) && !G_IS_MENU( obj ) ) { hb_ret(); return; }

    hWnd = (GtkWidget *) g_object_get_data( obj, "hwg_wnd" );
    if( !hWnd || !GTK_IS_WIDGET( hWnd ) ) { hb_ret(); return; }

    name = hwg_item_action_name( obj );
    if( !name ) { hb_ret(); return; }

    action = hwg_lookup_action( hWnd, name );
    if( action && G_IS_SIMPLE_ACTION( action ) )
    {
        g_simple_action_set_state( G_SIMPLE_ACTION( action ),
                                   g_variant_new_boolean( bSet ) );
    }

    hb_ret();
}

HB_FUNC( HWG__ISCHECKEDMENUITEM )
{
    GObject     *obj = (GObject *) HB_PARHANDLE(1);
    GtkWidget   *hWnd;
    const gchar *name;
    GAction     *action;
    GVariant    *state;
    gboolean     bSet = FALSE;

    if( obj && G_IS_OBJECT( obj ) &&
        ( G_IS_MENU_ITEM( obj ) || G_IS_MENU( obj ) ) ) {
        hWnd = (GtkWidget *) g_object_get_data( obj, "hwg_wnd" );
    if( hWnd && GTK_IS_WIDGET( hWnd ) ) {
        name = hwg_item_action_name( obj );
        if( name ) {
            action = hwg_lookup_action( hWnd, name );
            if( action ) {
                state = g_action_get_state( action );
                if( state && g_variant_is_of_type( state,
                    G_VARIANT_TYPE_BOOLEAN ) )
                    bSet = g_variant_get_boolean( state );
            }
        }
    }
        }

        hb_retl( bSet );
}


/* =====================================================================
 *  hwg__EnableMenuItem( hMenuItemOrSubmenu [, lEnabled] )
 *
 *  Works for both regular items (GMenuItem) and top-level submenus
 *  (GMenu).
 *
 *  Regular items: toggles the GAction's enabled state, which
 *  GtkModelButton inside the popover menu honours.
 *
 *  Submenus: the top-level GtkPopoverMenuBarItem is NOT bound to the
 *  dummy action, so we also toggle the widget directly:
 *    - gtk_widget_set_sensitive()  greys it out
 *    - gtk_widget_set_can_target() removes it from hit-testing, so no
 *      hover highlight is shown when the item is disabled
 * ===================================================================== */
HB_FUNC( HWG__ENABLEMENUITEM )
{
    GObject     *obj = (GObject *) HB_PARHANDLE(1);
    GtkWidget   *hWnd;
    const gchar *name;
    GAction     *action;
    gboolean     bSet = HB_ISNIL(2) ? TRUE : hb_parl(2);

    if( !obj || !G_IS_OBJECT( obj ) ) return;
    if( !G_IS_MENU_ITEM( obj ) && !G_IS_MENU( obj ) ) return;

    hWnd = (GtkWidget *) g_object_get_data( obj, "hwg_wnd" );
    if( !hWnd || !GTK_IS_WIDGET( hWnd ) ) return;

    name = hwg_item_action_name( obj );
    if( !name ) return;

    action = hwg_lookup_action( hWnd, name );
    if( action && G_IS_SIMPLE_ACTION( action ) )
    {
        g_simple_action_set_enabled( G_SIMPLE_ACTION( action ), bSet );
    }

    if( G_IS_MENU( obj ) )
    {
        GtkWidget *button = g_object_get_data( obj, "hwg_menubar_button" );
        if( button && GTK_IS_WIDGET( button ) )
        {
            gtk_widget_set_sensitive( button, bSet );
            gtk_widget_set_can_target( button, bSet );
        }
    }

    hb_ret();
}

HB_FUNC( HWG__ISENABLEDMENUITEM )
{
    GObject     *obj = (GObject *) HB_PARHANDLE(1);
    GtkWidget   *hWnd;
    const gchar *name;
    GAction     *action;
    gboolean     bEnabled = FALSE;

    if( obj && G_IS_OBJECT( obj ) &&
        ( G_IS_MENU_ITEM( obj ) || G_IS_MENU( obj ) ) ) {
        hWnd = (GtkWidget *) g_object_get_data( obj, "hwg_wnd" );
    if( hWnd && GTK_IS_WIDGET( hWnd ) ) {
        name = hwg_item_action_name( obj );
        if( name ) {
            action = hwg_lookup_action( hWnd, name );
            if( action )
                bEnabled = g_action_get_enabled( action );
        }
    }
        }

        hb_retl( bEnabled );
}


/* =====================================================================
 *  hwg_TrackMenu( hPopupMenu )
 *
 *  Original GTK2 code used gtk_menu_popup() with the current event.
 *  In GTK4 we create a GtkPopoverMenu on the fly and pop it up on the
 *  active toplevel window.
 * ===================================================================== */
HB_FUNC( HWG_TRACKMENU )
{
    GMenuModel *model = (GMenuModel *) HB_PARHANDLE(1);
    GtkWidget  *parent;
    GtkWidget  *popover;

    if( !model || !G_IS_MENU_MODEL( model ) ) return;

    parent = GetActiveWindow();
    if( !parent ) return;

    popover = gtk_popover_menu_new_from_model( model );
    gtk_widget_set_parent( popover, parent );
    gtk_popover_popup( GTK_POPOVER( popover ) );
}


HB_FUNC( HWG_DESTROYMENU )
{
    GObject *obj = (GObject *) HB_PARHANDLE(1);
    if( obj && G_IS_OBJECT( obj ) )
        g_object_unref( obj );
}


/* =====================================================================
 *  Accelerators
 *
 *  GTK4 removed gtk_widget_add_accelerator().  We use a
 *  GtkShortcutController attached to the window instead.
 * ===================================================================== */
#define FSHIFT    4
#define FCONTROL  8
#define FALT     16

HB_FUNC( HWG__CREATEACCELERATORTABLE )
{
    GtkWidget             *hWnd = (GtkWidget *) HB_PARHANDLE(1);
    GtkShortcutController *ctl;

    if( !hWnd || !GTK_IS_WINDOW( hWnd ) ) { hb_ret(); return; }

    /*
     * In some builds gtk_shortcut_controller_new() is declared to
     * return GtkEventController*.  Cast explicitly to silence the
     * incompatible-pointer-type warning.
     */
    ctl = (GtkShortcutController *) gtk_shortcut_controller_new();
    gtk_shortcut_controller_set_scope( ctl, GTK_SHORTCUT_SCOPE_GLOBAL );
    gtk_widget_add_controller( hWnd, GTK_EVENT_CONTROLLER( ctl ) );

    HB_RETHANDLE( ctl );
}

HB_FUNC( HWG__ADDACCELERATOR )
{
    GtkShortcutController *ctl   = (GtkShortcutController *) HB_PARHANDLE(1);
    GMenuItem             *item  = (GMenuItem *) HB_PARHANDLE(2);
    int                    iCtrl = hb_parni(3);
    guint                  nKey  = (guint) hb_parni(4);
    GdkModifierType        mods;
    const gchar           *action_name;
    GtkShortcutTrigger    *trigger;
    GtkShortcutAction     *action;
    GtkShortcut           *shortcut;

    if( !ctl || !GTK_IS_SHORTCUT_CONTROLLER( ctl ) )   return;
    if( !item || !G_IS_MENU_ITEM( item ) )             return;

    mods = ( iCtrl == FSHIFT )   ? GDK_SHIFT_MASK   :
    ( iCtrl == FCONTROL ) ? GDK_CONTROL_MASK :
    ( iCtrl == FALT )     ? GDK_ALT_MASK     : 0;

    /*
     * Accelerators are attached only to leaf items (GMenuItem).
     * The helper accepts GObject, so cast explicitly here.
     */
    action_name = hwg_item_action_name( G_OBJECT( item ) );
    if( !action_name ) return;

    trigger  = gtk_keyval_trigger_new( nKey, mods );
    action   = gtk_named_action_new( action_name );
    shortcut = gtk_shortcut_new( trigger, action );

    gtk_shortcut_controller_add_shortcut( ctl, shortcut );
}

HB_FUNC( HWG_DESTROYACCELERATORTABLE )
{
    GtkShortcutController *ctl = (GtkShortcutController *) HB_PARHANDLE(1);
    if( ctl && GTK_IS_SHORTCUT_CONTROLLER( ctl ) ) {
        GtkWidget *w = gtk_event_controller_get_widget( GTK_EVENT_CONTROLLER( ctl ) );
        if( w ) gtk_widget_remove_controller( w, GTK_EVENT_CONTROLLER( ctl ) );
    }
}


/* =====================================================================
 *  hwg__SetMenuCaption( hMenuItem, cCaption )
 *
 *  In GTK4 a GMenuModel is immutable; renaming means replacing the item
 *  inside its parent GMenu.  Since we do not track the parent/index for
 *  each item (it would require storing extra state in the Harbour side),
 *  we update the label stored inside the GMenuItem itself.  This is a
 *  no-op for already-rendered items -- the caller must trigger a
 *  rebuild of the model if a live rename is required.
 * ===================================================================== */
HB_FUNC( HWG__SETMENUCAPTION )
{
    GMenuItem *item = (GMenuItem *) HB_PARHANDLE(1);
    gchar     *gcptr;

    if( !item || !G_IS_MENU_ITEM( item ) ) return;

    gcptr = hwg_convert_to_utf8( hb_parc(2) );
    g_menu_item_set_label( item, gcptr );
    g_free( gcptr );
}


/* =====================================================================
 *  hwg__DeleteMenuItem( hMenuItemOrSubmenu )
 *
 *  GMenu has no "remove this item" call without the parent + index.
 *  We disable the action instead (and, for top-level submenus, also
 *  the corresponding top-level widget), which is the closest
 *  observable behaviour.  Accepts both GMenuItem and GMenu.
 * ===================================================================== */
HB_FUNC( HWG__DELETEMENU )
{
    GObject     *obj = (GObject *) HB_PARHANDLE(1);
    GtkWidget   *hWnd;
    const gchar *name;
    GAction     *action;

    if( !obj || !G_IS_OBJECT( obj ) ) return;
    if( !G_IS_MENU_ITEM( obj ) && !G_IS_MENU( obj ) ) return;

    hWnd = (GtkWidget *) g_object_get_data( obj, "hwg_wnd" );
    if( !hWnd || !GTK_IS_WIDGET( hWnd ) ) return;

    name = hwg_item_action_name( obj );
    if( !name ) return;

    action = hwg_lookup_action( hWnd, name );
    if( action && G_IS_SIMPLE_ACTION( action ) )
    {
        g_simple_action_set_enabled( G_SIMPLE_ACTION( action ), FALSE );
    }

    if( G_IS_MENU( obj ) )
    {
        GtkWidget *button = g_object_get_data( obj, "hwg_menubar_button" );
        if( button && GTK_IS_WIDGET( button ) )
        {
            gtk_widget_set_sensitive( button, FALSE );
            gtk_widget_set_can_target( button, FALSE );
        }
    }
}


HB_FUNC( HWG_DRAWMENUBAR )
{
    /* GtkPopoverMenuBar draws itself. */
}

/* =========================== EOF of menu_c.c ================================== */
