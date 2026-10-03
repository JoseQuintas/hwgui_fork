/*
 * $Id: listbox.c 3911 2026-10-03 04:47:24Z itamarlins $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HListBox class -- GTK4 implementation
 *
 * GTK4 port -- matches the WinAPI listbox.c API so the same Harbour
 * class (hlistbox.prg) works unchanged on both backends.
 *
 * ----------------------------------------------------------------------
 *  Widget mapping
 * ----------------------------------------------------------------------
 *
 *      Win32 LISTBOX            GTK4
 *      ---------------          --------------------------------
 *      HWND                     GtkScrolledWindow
 *      LB_ADDSTRING             GtkListBox + GtkListBoxRow(child=GtkLabel)
 *      LB_SETCURSEL             gtk_list_box_select_row()
 *      LB_GETCURSEL             gtk_list_box_get_selected_row() -> index
 *      LB_RESETCONTENT          remove all rows
 *      LB_DELETESTRING          gtk_list_box_remove()
 *
 *  The handle returned to Harbour is the GtkScrolledWindow, so that
 *  WS_VSCROLL and WS_BORDER map naturally (a scrolled window has both).
 *  The inner GtkListBox is cached on the scrolled window under the
 *  "hwg_listbox_list" data key; every other helper in this file
 *  retrieves it from there.
 *
 * ----------------------------------------------------------------------
 *  Event bridging
 * ----------------------------------------------------------------------
 *
 *  Win32 sends LBN_SELCHANGE / LBN_DBLCLK / LBN_SETFOCUS / LBN_KILLFOCUS
 *  as WM_COMMAND notifications.  The Harbour side catches them through
 *  HControl:AddEvent.  On GTK4 we translate:
 *
 *      GtkListBox::row-selected    ->  LBN_SELCHANGE
 *      GtkListBox::row-activated   ->  LBN_DBLCLK
 *
 *  and dispatch via hwg_dispatch_onevent(), which walks the Harbour
 *  object stored on the widget by SetWindowObject() -- done from the
 *  .prg side in HListBox:Init() through hwg_Setwindowobject().
 *
 * ----------------------------------------------------------------------
 *  Programmatic vs. user selection
 * ----------------------------------------------------------------------
 *
 *  Selecting a row from Harbour (HListBox:SetItem, :Refresh, :Init)
 *  must NOT fire LBN_SELCHANGE, otherwise bSetGet and bChange run
 *  twice and any recursive UI update enters a loop.  A "busy" flag on
 *  the listbox is set around the programmatic gtk_list_box_select_row()
 *  call, and the row-selected handler bails out when it is present.
 *  Same idea as hwg_toggle_signal_block() in control.c.
 *
 * ----------------------------------------------------------------------
 *  Notes on HWG_SENDMESSAGE
 * ----------------------------------------------------------------------
 *
 *  hlistbox.prg uses hwg_Sendmessage() for a handful of LB_* messages
 *  (LB_SETITEMHEIGHT, LB_RESETCONTENT, LB_SETCURSEL, LB_GETCURSEL,
 *  LB_DELETESTRING).  On Win32 these travel straight to the OS; on
 *  GTK4 they must be emulated, since a GtkListBox has no SendMessage.
 *
 *  If your tree already defines HWG_SENDMESSAGE elsewhere, remove the
 *  definition at the bottom of this file and merge the LB_* branch
 *  into the existing dispatcher.
 */

#include "guilib.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbapifs.h"
#include "windows.ch"

#include <glib.h>
#include <gtk/gtk.h>

#include "hwgtk4.h"
#include "warnings.h"

/* ---------------------------------------------------------------------
 *  LB_ERR
 *
 *  windows.ch does not publish this one -- its LB_* block stops at
 *  LB_SETCOUNT (0x01A7).  Define it locally; the value matches the
 *  Win32 SDK and the ">= 0 means success" test in HListBox:DeleteItem.
 * --------------------------------------------------------------------- */
#define LB_ERR   (-1)

/* ---------------------------------------------------------------------
 *  Externs from control.c / hwgtk4.h
 *  (kept minimal; anything already declared in hwgtk4.h is omitted)
 * --------------------------------------------------------------------- */
extern HB_LONG  hwg_dispatch_onevent( GtkWidget *widget,
                                      HB_LONG p1, HB_LONG p2, HB_LONG p3 );
extern gboolean hwg_install_widget_events( GtkWidget *widget,
                                           gboolean bDrawable );
extern GtkFixed *getFixedBox( GObject *handle );


/* =====================================================================
 *  Internal helpers
 * ===================================================================== */

/*
 * Return the inner GtkListBox for a listbox handle (the scrolled
 * window).  NULL when the handle is not an HWGUI listbox.
 */
static GtkWidget *hwg_listbox_get_list( GtkWidget *scroll )
{
    if( !scroll || !G_IS_OBJECT( scroll ) ||
        !GTK_IS_SCROLLED_WINDOW( scroll ) )
        return NULL;

    return (GtkWidget*) g_object_get_data( (GObject*) scroll,
                                           "hwg_listbox_list" );
}


/*
 * Number of rows currently stored in the listbox.
 * GtkListBox has no "count" accessor; iterate the index-based one
 * until it returns NULL, exactly like hwg_checklist_count() does in
 * control.c.
 */
static gint hwg_listbox_count( GtkWidget *listbox )
{
    gint n = 0;

    if( !listbox || !GTK_IS_LIST_BOX( listbox ) )
        return 0;

    while( gtk_list_box_get_row_at_index( GTK_LIST_BOX( listbox ), n ) )
        n++;

    return n;
}


/*
 * 1-based index of the currently selected row, or 0 when nothing is
 * selected.
 */
static gint hwg_listbox_get_sel( GtkWidget *listbox )
{
    GtkListBoxRow *row;

    if( !listbox || !GTK_IS_LIST_BOX( listbox ) )
        return 0;

    row = gtk_list_box_get_selected_row( GTK_LIST_BOX( listbox ) );
    if( !row )
        return 0;

    return gtk_list_box_row_get_index( row ) + 1;
}


/*
 * Remove every row.  Iterated from the end so the row pointer we just
 * obtained stays valid across the removal -- GtkListBoxRow indexes
 * shift when a preceding row is removed.
 */
static void hwg_listbox_clear( GtkWidget *listbox )
{
    gint total, i;

    if( !listbox || !GTK_IS_LIST_BOX( listbox ) )
        return;

    total = hwg_listbox_count( listbox );

    for( i = total - 1; i >= 0; i-- )
    {
        GtkListBoxRow *row = gtk_list_box_get_row_at_index(
            GTK_LIST_BOX( listbox ), i );

        if( row )
            gtk_list_box_remove( GTK_LIST_BOX( listbox ),
                                 GTK_WIDGET( row ) );
    }
}


/*
 * Programmatic selection helper.  Sets the busy flag so that the
 * row-selected signal does not re-enter the Harbour side.
 * idx is 0-based, matching the internal GTK convention and the
 * wParam of LB_SETCURSEL.
 */
static void hwg_listbox_set_sel( GtkWidget *listbox, gint idx )
{
    if( !listbox || !GTK_IS_LIST_BOX( listbox ) )
        return;

    g_object_set_data( (GObject*) listbox, "hwg_listbox_busy",
                       GINT_TO_POINTER( 1 ) );

    if( idx < 0 )
        gtk_list_box_unselect_all( GTK_LIST_BOX( listbox ) );
    else
    {
        GtkListBoxRow *row = gtk_list_box_get_row_at_index(
            GTK_LIST_BOX( listbox ), idx );

        if( row )
            gtk_list_box_select_row( GTK_LIST_BOX( listbox ), row );
    }

    g_object_set_data( (GObject*) listbox, "hwg_listbox_busy", NULL );
}


/*
 * Signal handler for GtkListBox::row-selected.
 * Dispatches LBN_SELCHANGE to the Harbour side, unless the change was
 * triggered programmatically (busy flag).
 */
static void cb_listbox_row_selected( GtkListBox *lb, GtkListBoxRow *row,
                                     gpointer user_data )
{
    GtkWidget *scroll = GTK_WIDGET( user_data );
    gint       idx    = 0;

    if( !scroll || !GTK_IS_WIDGET( scroll ) )
        return;

    /* Programmatic selection: skip the notification. */
    if( g_object_get_data( G_OBJECT( lb ), "hwg_listbox_busy" ) )
        return;

    if( row )
        idx = gtk_list_box_row_get_index( row ) + 1;

    /* p2 (wParam) carries the 1-based index; p3 (lParam) is unused. */
    hwg_dispatch_onevent( scroll, LBN_SELCHANGE, (HB_LONG) idx, 0 );
}


/*
 * Signal handler for GtkListBox::row-activated, which fires on Enter
 * or double-click.  HListBox:bDblclick is wired to LBN_DBLCLK, so we
 * dispatch that notification.
 */
static void cb_listbox_row_activated( GtkListBox *lb, GtkListBoxRow *row,
                                      gpointer user_data )
{
    GtkWidget *scroll = GTK_WIDGET( user_data );
    gint       idx    = 0;

    HB_SYMBOL_UNUSED( lb );

    if( !scroll || !GTK_IS_WIDGET( scroll ) )
        return;

    if( row )
        idx = gtk_list_box_row_get_index( row ) + 1;

    hwg_dispatch_onevent( scroll, LBN_DBLCLK, (HB_LONG) idx, 0 );
}


/* =====================================================================
 *  HWG_CREATELISTBOX
 *
 *  Creates the underlying GTK4 widget tree and returns the handle.
 *
 *  Parameters (identical to the WinAPI version):
 *      1 - Parent window handle (GtkWidget)
 *      2 - Control ID (unused on GTK4; HWGUI does not assign numeric IDs)
 *      3 - Style flags (WS_VSCROLL, WS_BORDER, LBS_*)
 *      4 - x position, in pixels
 *      5 - y position, in pixels
 *      6 - width,  in pixels
 *      7 - height, in pixels
 *
 *  Returns:
 *      Handle to the scrolled window, or NULL on error.
 * ===================================================================== */
HB_FUNC( HWG_CREATELISTBOX )
{
    GtkWidget    *scroll;
    GtkWidget    *listbox;
    GtkFixed     *box;
    unsigned long ulStyle = (unsigned long) hb_parnl( 3 );
    gint          nX      = hb_parni( 4 );
    gint          nY      = hb_parni( 5 );
    gint          nW      = hb_parni( 6 );
    gint          nH      = hb_parni( 7 );

    box = getFixedBox( (GObject*) HB_PARHANDLE( 1 ) );

    scroll  = gtk_scrolled_window_new();
    listbox = gtk_list_box_new();

    /*
     * Single selection: the Win32 default.  LBS_EXTENDEDSEL /
     * LBS_MULTIPLESEL are not used by HListBox, so they are not
     * mapped here.  See the note in the header if the class ever
     * needs them.
     */
    gtk_list_box_set_selection_mode( GTK_LIST_BOX( listbox ),
                                     GTK_SELECTION_SINGLE );

    /*
     * Vertical scroll policy: ALWAYS when WS_VSCROLL is set (matches
     * the Win32 "reserve the gutter" behaviour, which callers rely on
     * for layout).  Horizontal: always AUTOMATIC so long entries can
     * scroll instead of being clipped.
     */
    gtk_scrolled_window_set_policy( GTK_SCROLLED_WINDOW( scroll ),
                                    GTK_POLICY_AUTOMATIC,
                                    ( ulStyle & WS_VSCROLL )
                                    ? GTK_POLICY_ALWAYS
                                    : GTK_POLICY_AUTOMATIC );

    if( ulStyle & WS_BORDER )
    {
        gtk_scrolled_window_set_has_frame(
            GTK_SCROLLED_WINDOW( scroll ), TRUE );
    }
        gtk_scrolled_window_set_child( GTK_SCROLLED_WINDOW( scroll ), listbox );

    /*
     * Cache the inner listbox so the other helpers in this file do not
     * need to walk the widget hierarchy each time.
     */
    g_object_set_data( (GObject*) scroll, "hwg_listbox_list",
                       (gpointer) listbox );

    /*
     * Wire the signals.  The scrolled window is passed as user_data
     * because it is the widget to which the Harbour object is attached
     * from HListBox:Init() via hwg_Setwindowobject(); the dispatch
     * helper walks up from the widget it receives.
     */
    g_signal_connect( listbox, "row-selected",
                      G_CALLBACK( cb_listbox_row_selected ), scroll );
    g_signal_connect( listbox, "row-activated",
                      G_CALLBACK( cb_listbox_row_activated ), scroll );

    if( box )
        gtk_fixed_put( box, scroll, nX, nY );

    hwg_set_size_request( scroll, nW, nH );

    HB_RETHANDLE( scroll );
}


/* =====================================================================
 *  HWG_LISTBOXADDSTRING
 *
 *  Appends a string to the listbox.
 *
 *  Parameters:
 *      1 - Listbox handle (the GtkScrolledWindow returned by
 *          CreateListBox)
 *      2 - String to append
 *
 *  Returns:
 *      1-based index of the new item, or LB_ERR (-1) on error.
 * ===================================================================== */
HB_FUNC( HWG_LISTBOXADDSTRING )
{
    GtkWidget *scroll  = (GtkWidget*) HB_PARHANDLE( 1 );
    GtkWidget *listbox = hwg_listbox_get_list( scroll );
    gchar     *cLabel  = hwg_convert_to_utf8( hb_parcx( 2 ) );
    GtkWidget *row;
    GtkWidget *label;
    gint       idx;
    gint       row_h;

    if( !listbox || !GTK_IS_LIST_BOX( listbox ) )
    {
        g_free( cLabel );
        hb_retni( LB_ERR );
        return;
    }

    label = gtk_label_new( cLabel );
    gtk_label_set_xalign( GTK_LABEL( label ), 0.0f );
    gtk_widget_set_margin_start( label, 6 );
    gtk_widget_set_margin_end( label, 6 );

    /*
     * Row height, if LB_SETITEMHEIGHT has already been applied.
     * hlistbox.prg's Init() sets the height BEFORE adding strings, so
     * every row sees the correct value.  Later changes only affect new
     * rows -- matching the Win32 semantics closely enough for HWGUI.
     */
    row_h = GPOINTER_TO_INT(
        g_object_get_data( (GObject*) listbox, "hwg_listbox_rowh" ) );

    if( row_h > 0 )
    {
        gtk_widget_set_size_request( label, -1, row_h );
        gtk_widget_set_margin_top( label, 0 );
        gtk_widget_set_margin_bottom( label, 0 );
    }
    else
    {
        gtk_widget_set_margin_top( label, 2 );
        gtk_widget_set_margin_bottom( label, 2 );
    }

    row = gtk_list_box_row_new();
    gtk_list_box_row_set_child( GTK_LIST_BOX_ROW( row ), label );
    gtk_list_box_append( GTK_LIST_BOX( listbox ), row );

    idx = gtk_list_box_row_get_index( GTK_LIST_BOX_ROW( row ) ) + 1;

    g_free( cLabel );
    hb_retni( idx );
}


/* =====================================================================
 *  HWG_LISTBOXSETSTRING
 *
 *  Sets the current selection.
 *
 *  Parameters:
 *      1 - Listbox handle
 *      2 - 1-based index of the item to select
 * ===================================================================== */
HB_FUNC( HWG_LISTBOXSETSTRING )
{
    GtkWidget *scroll  = (GtkWidget*) HB_PARHANDLE( 1 );
    GtkWidget *listbox = hwg_listbox_get_list( scroll );
    gint       idx     = hb_parni( 2 );

    if( !listbox || !GTK_IS_LIST_BOX( listbox ) || idx <= 0 )
        return;

    hwg_listbox_set_sel( listbox, idx - 1 );
}


/* =====================================================================
 *  HWG_LISTBOXDELETESTRING
 *
 *  Deletes an item.
 *
 *  Parameters:
 *      1 - Listbox handle
 *      2 - 1-based index of the item to delete
 *
 *  Returns:
 *      Count of remaining items, or LB_ERR on error.
 *
 *  hlistbox.prg calls hwg_Sendmessage(LB_DELETESTRING) instead of this
 *  function directly, but the WinAPI header exposes it, so we keep
 *  the same symbol for source compatibility.
 * ===================================================================== */
HB_FUNC( HWG_LISTBOXDELETESTRING )
{
    GtkWidget *scroll  = (GtkWidget*) HB_PARHANDLE( 1 );
    GtkWidget *listbox = hwg_listbox_get_list( scroll );
    gint       idx     = hb_parni( 2 );

    if( !listbox || !GTK_IS_LIST_BOX( listbox ) || idx <= 0 )
    {
        hb_retni( LB_ERR );
        return;
    }

    {
        GtkListBoxRow *row = gtk_list_box_get_row_at_index(
            GTK_LIST_BOX( listbox ), idx - 1 );

        if( !row )
        {
            hb_retni( LB_ERR );
            return;
        }

        gtk_list_box_remove( GTK_LIST_BOX( listbox ), GTK_WIDGET( row ) );
    }

    hb_retni( hwg_listbox_count( listbox ) );
}


/* =====================================================================
 *  HWG_INITLISTPROC
 *
 *  Called by HListBox:Init() right after the widget tree is created.
 *  On Win32 this subclassed the listbox procedure so HWGUI could
 *  intercept WM_COMMAND notifications.  On GTK4 all signals are
 *  already wired inside HWG_CREATELISTBOX, so this is a no-op kept
 *  purely for API compatibility.
 * ===================================================================== */
HB_FUNC( HWG_INITLISTPROC )
{
    /* No-op.  Kept so hlistbox.prg does not need a platform #ifdef. */
    HB_SYMBOL_UNUSED( hb_parptr( 1 ) );
}

/* =====================================================================
 *  hwg_listbox_handle_message
 *
 *  Centralised LB_* dispatcher, called from HWG_SENDMESSAGE() in
 *  misc.c.  Keeps every listbox-internal helper static to this file
 *  while still letting the global message router reach them.
 *
 *  Parameters:
 *      hWnd    - candidate listbox handle (the GtkScrolledWindow)
 *      ulMsg   - Win32 message id (LB_*)
 *      wParam  - message wParam
 *      lParam  - message lParam
 *      pResult - out-parameter: the value the message would return
 *
 *  Returns:
 *      TRUE  -> the message was recognised and handled; *pResult holds
 *               the return value
 *      FALSE -> the handle is not an HWGUI listbox, or the message is
 *               not one this module knows about
 * ===================================================================== */
HB_BOOL hwg_listbox_handle_message( GtkWidget *hWnd, HB_ULONG ulMsg,
                                    HB_LONG wParam, HB_LONG lParam,
                                    HB_LONG *pResult )
{
    GtkWidget *listbox = hwg_listbox_get_list( hWnd );

    if( !listbox )
        return FALSE;

    switch( ulMsg )
    {
        case LB_RESETCONTENT:
            hwg_listbox_clear( listbox );
            *pResult = 0;
            return TRUE;

        case LB_SETCURSEL:
            hwg_listbox_set_sel( listbox, (gint) wParam );
            *pResult = 0;
            return TRUE;

        case LB_GETCURSEL:
        {
            gint sel = hwg_listbox_get_sel( listbox );
            *pResult = ( sel > 0 ? sel - 1 : LB_ERR );
            return TRUE;
        }

        case LB_GETCOUNT:
            *pResult = hwg_listbox_count( listbox );
            return TRUE;

        case LB_DELETESTRING:
        {
            GtkListBoxRow *row = gtk_list_box_get_row_at_index(
                GTK_LIST_BOX( listbox ), (gint) wParam );

            if( row )
            {
                gtk_list_box_remove( GTK_LIST_BOX( listbox ),
                                     GTK_WIDGET( row ) );
                *pResult = hwg_listbox_count( listbox );
            }
            else
                *pResult = LB_ERR;

            return TRUE;
        }

        case LB_SETITEMHEIGHT:
            g_object_set_data( (GObject*) listbox, "hwg_listbox_rowh",
                               GINT_TO_POINTER( (gint) lParam ) );
            *pResult = 0;
            return TRUE;

        case LB_GETITEMHEIGHT:
            *pResult = GPOINTER_TO_INT(
                g_object_get_data( (GObject*) listbox,
                                   "hwg_listbox_rowh" ) );
            return TRUE;

        default:
            /* The handle is a listbox, but this message is not ours. */
            return FALSE;
    }
}

/* ============================ EOF of listbox.c ============================= */
