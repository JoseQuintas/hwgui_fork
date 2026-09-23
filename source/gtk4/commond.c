/*
 * $Id: commond.c 3182 2022-12-12 15:54:46Z df7be $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Common dialog functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port — target: GTK 4.24+
 *
 * NOTES
 * -----
 *   * Uses the modern GtkFontDialog / GtkFileDialog / GtkColorDialog APIs
 *     (introduced in GTK 4.10, required in 4.24 since the legacy dialogs
 *     were removed).
 *
 *   * All three are async-only.  A local GMainLoop wraps each call to
 *     preserve the blocking semantics expected by the Harbour API.
 *
 *   * GtkFileDialog uses GListModel for both filters and results.
 *
 *   * gtk_font_dialog_choose_font_and_features_finish returns gboolean
 *     and produces four output parameters:
 *         PangoFontDescription **font_desc,
 *         char                 **family,
 *         PangoLanguage        **language,
 *         GError               **error
 */

#include "guilib.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"
#include "gtk/gtk.h"
#include "hwgtk4.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif
#include "warnings.h"

extern GtkWidget *GetActiveWindow( void );
extern void       hwg_parse_color( HB_ULONG ncolor, GdkRGBA * pColor );
extern PHB_ITEM   GetObjectVar( PHB_ITEM pObject, const char *varname );


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


/* =====================================================================
 *  hwg_SelectFont — GtkFontDialog (async wrapped in GMainLoop)
 * ===================================================================== */
typedef struct {
    GMainLoop            *loop;
    PangoFontDescription *desc;     /* owned by caller if ok */
    gboolean              ok;
} HWG_FONT_CTX;

static void hwg_font_choose_cb( GObject *source, GAsyncResult *res, gpointer user_data )
{
    HWG_FONT_CTX         *ctx      = (HWG_FONT_CTX *) user_data;
    PangoFontDescription *desc     = NULL;
    char                 *family   = NULL;
    PangoLanguage        *language = NULL;
    GError               *error    = NULL;
    gboolean              ok;

    ok = gtk_font_dialog_choose_font_and_features_finish(
        GTK_FONT_DIALOG( source ), res,
                                                         &desc, &family, &language, &error );

    if( !ok || error )
    {
        if( error )
            g_error_free( error );
    }
    else if( desc )
    {
        ctx->ok   = TRUE;
        ctx->desc = desc;   /* ownership transferred to caller */
    }

    if( family )
        g_free( family );

    /* `language` is interned by Pango — do NOT free it. */

    g_main_loop_quit( ctx->loop );
}

HB_FUNC( HWG_SELECTFONT )
{
    GtkFontDialog        *dialog;
    HWG_FONT_CTX          ctx;
    PangoFontDescription *initial = NULL;
    const char           *cTitle = ( hb_pcount() > 1 && HB_ISCHAR(2) )
    ? hb_parc(2) : "Select Font";

    /* Pre-populate from the passed HFont object, if any. */
    if( hb_pcount() > 0 && !HB_ISNIL(1) )
    {
        PHB_ITEM pObj = hb_param( 1, HB_IT_OBJECT );
        if( pObj )
        {
            const char *ptr    = hb_itemGetCPtr( GetObjectVar( pObj, "NAME" ) );
            int         height = hb_itemGetNI( GetObjectVar( pObj, "HEIGHT" ) );
            int         weight = hb_itemGetNI( GetObjectVar( pObj, "WEIGHT" ) );
            int         italic = hb_itemGetNI( GetObjectVar( pObj, "ITALIC" ) );
            char        szFont[256];

            snprintf( szFont, sizeof(szFont), "%s %s %s %d",
                      ptr ? ptr : "sans",
                      ( weight >= 700 ) ? "Bold"   : "",
                      ( italic != 0   ) ? "Italic" : "",
                      height );

            initial = pango_font_description_from_string( szFont );
        }
    }

    dialog = gtk_font_dialog_new();
    gtk_font_dialog_set_title( dialog, cTitle );
    gtk_font_dialog_set_modal( dialog, TRUE );

    ctx.loop = g_main_loop_new( NULL, FALSE );
    ctx.desc = NULL;
    ctx.ok   = FALSE;

    gtk_font_dialog_choose_font_and_features(
        dialog, hwg_get_parent_window(),
                                             initial, NULL,
                                             hwg_font_choose_cb, &ctx );

    if( initial )
        pango_font_description_free( initial );

    g_main_loop_run( ctx.loop );
    g_main_loop_unref( ctx.loop );

    g_object_unref( dialog );

    if( !ctx.ok || !ctx.desc )
    {
        hb_ret();
        return;
    }

    /* Build the 9-element array expected by HSelectFont callers. */
    {
        PangoFontDescription *hFont = ctx.desc;
        PHWGUI_FONT h = (PHWGUI_FONT) hb_xgrab( sizeof(HWGUI_FONT) );
        PHB_ITEM aMetr = hb_itemArrayNew( 9 );
        PHB_ITEM temp;

        h->type  = HWGUI_OBJECT_FONT;
        h->hFont = hFont;
        h->attrs = NULL;

        temp = HB_PUTHANDLE( NULL, h );
        hb_itemArrayPut( aMetr, 1, temp ); hb_itemRelease( temp );

        temp = hb_itemPutC( NULL,
                            (char*) pango_font_description_get_family( hFont ) );
        hb_itemArrayPut( aMetr, 2, temp ); hb_itemRelease( temp );

        temp = hb_itemPutNL( NULL, 0 );
        hb_itemArrayPut( aMetr, 3, temp ); hb_itemRelease( temp );

        temp = hb_itemPutNL( NULL,
                             (HB_LONG) pango_font_description_get_size( hFont ) );
        hb_itemArrayPut( aMetr, 4, temp ); hb_itemRelease( temp );

        temp = hb_itemPutNL( NULL,
                             (HB_LONG) pango_font_description_get_weight( hFont ) );
        hb_itemArrayPut( aMetr, 5, temp ); hb_itemRelease( temp );

        temp = hb_itemPutNI( NULL, 0 );
        hb_itemArrayPut( aMetr, 6, temp ); hb_itemRelease( temp );

        temp = hb_itemPutNI( NULL,
                             (HB_LONG) pango_font_description_get_style( hFont ) );
        hb_itemArrayPut( aMetr, 7, temp ); hb_itemRelease( temp );

        temp = hb_itemPutNI( NULL, 0 );
        hb_itemArrayPut( aMetr, 8, temp ); hb_itemRelease( temp );

        temp = hb_itemPutNI( NULL, 0 );
        hb_itemArrayPut( aMetr, 9, temp ); hb_itemRelease( temp );

        hb_itemReturn( aMetr );
        hb_itemRelease( aMetr );
    }
}


/* =====================================================================
 *  hwg_SelectFile / hwg_SelectFileEx / hwg_SelectFolder — GtkFileDialog
 *
 *  GTK 4.24: GtkFileDialog uses GListModel for both the filters list
 *  and the multi-selection result.
 * ===================================================================== */
typedef struct {
    GMainLoop  *loop;
    GListModel *files;    /* model of GFile* — owned by ctx */
} HWG_FILE_CTX;

static void hwg_file_open_cb( GObject *source, GAsyncResult *res, gpointer user_data )
{
    HWG_FILE_CTX *ctx = (HWG_FILE_CTX *) user_data;
    GError       *error = NULL;

    ctx->files = gtk_file_dialog_open_multiple_finish(
        GTK_FILE_DIALOG( source ), res, &error );

    if( error )
    {
        g_error_free( error );
        ctx->files = NULL;
    }

    g_main_loop_quit( ctx->loop );
}

/* Convert a GListModel of GFile* to a Harbour string array. */
static void hwg_file_model_to_array( GListModel *model, PHB_ITEM aFiles )
{
    guint n = g_list_model_get_n_items( model );
    guint i;

    for( i = 0; i < n; i++ )
    {
        GFile *file = G_FILE( g_list_model_get_item( model, i ) );
        char  *path = g_file_get_path( file );

        hb_arraySetC( aFiles, i + 1, path ? path : "" );
        g_free( path );
        g_object_unref( file );
    }
}

/* Convert a GListModel of GFile* to a single path string (first item). */
static char *hwg_file_model_to_string( GListModel *model )
{
    GFile *file;
    char  *path;

    if( g_list_model_get_n_items( model ) == 0 )
        return NULL;

    file = G_FILE( g_list_model_get_item( model, 0 ) );
    path = g_file_get_path( file );
    g_object_unref( file );

    return path;
}

HB_FUNC( HWG_SELECTFILEEX )
{
    GtkFileDialog *dialog;
    HWG_FILE_CTX   ctx;
    const char    *cTitle = HB_ISCHAR(1) ? hb_parc(1) : "Select a file";
    const char    *cDir   = ( hb_pcount() > 1 && HB_ISCHAR(2) ) ? hb_parc(2) : "";
    PHB_ITEM       pArray = ( hb_pcount() > 2 && HB_ISARRAY(3) )
    ? hb_param( 3, HB_IT_ARRAY ) : NULL;
    int            bMulti = HB_ISLOG(4) ? hb_parl(4) : 0;
    int i, j, iLen, iLen1;

    dialog = gtk_file_dialog_new();
    gtk_file_dialog_set_title( dialog, cTitle );
    gtk_file_dialog_set_modal( dialog, TRUE );

    if( cDir && *cDir )
    {
        GFile *folder = g_file_new_for_path( cDir );
        gtk_file_dialog_set_initial_folder( dialog, folder );
        g_object_unref( folder );
    }

    /* Build the filter list — GTK 4.24 expects a GListModel. */
    if( pArray )
    {
        GListStore *store = g_list_store_new( GTK_TYPE_FILE_FILTER );

        iLen = hb_arrayLen( pArray );
        for( i = 1; i <= iLen; i++ )
        {
            GtkFileFilter *filter = gtk_file_filter_new();
            PHB_ITEM pArr1 = hb_arrayGetItemPtr( pArray, i );
            iLen1 = hb_arrayLen( pArr1 );
            for( j = 1; j <= iLen1; j++ )
            {
                if( j == 1 )
                    gtk_file_filter_set_name( filter, hb_arrayGetC( pArr1, j ) );
                else
                    gtk_file_filter_add_pattern( filter, hb_arrayGetC( pArr1, j ) );
            }
            g_list_store_append( store, filter );
            g_object_unref( filter );   /* store holds its own reference */
        }

        gtk_file_dialog_set_filters( dialog, G_LIST_MODEL( store ) );
        g_object_unref( store );
    }

    ctx.loop  = g_main_loop_new( NULL, FALSE );
    ctx.files = NULL;

    if( bMulti )
    {
        gtk_file_dialog_open_multiple( dialog, hwg_get_parent_window(),
                                       NULL, hwg_file_open_cb, &ctx );
    }
    else
    {
        gtk_file_dialog_open( dialog, hwg_get_parent_window(),
                              NULL, hwg_file_open_cb, &ctx );
    }

    g_main_loop_run( ctx.loop );
    g_main_loop_unref( ctx.loop );

    if( !ctx.files )
    {
        hb_retc( "" );
        g_object_unref( dialog );
        return;
    }

    if( bMulti )
    {
        guint    uiLen  = g_list_model_get_n_items( ctx.files );
        PHB_ITEM aFiles = hb_itemArrayNew( uiLen );

        hwg_file_model_to_array( ctx.files, aFiles );
        hb_itemReturnRelease( aFiles );
    }
    else
    {
        char *path = hwg_file_model_to_string( ctx.files );
        hb_retc( path ? path : "" );
        g_free( path );
    }

    g_object_unref( ctx.files );
    g_object_unref( dialog );
}

/* Legacy 4-argument overload of hwg_SelectFile. */
HB_FUNC( HWG_SELECTFILE )
{
    HB_FUNC_EXEC( HWG_SELECTFILEEX );
}


/* =====================================================================
 *  hwg_SelectFolder — GtkFileDialog (folder mode)
 * ===================================================================== */
HB_FUNC( HWG_SELECTFOLDER )
{
    GtkFileDialog *dialog;
    HWG_FILE_CTX   ctx;
    const char    *cTitle = HB_ISCHAR(1) ? hb_parc(1) : "Select a folder";

    dialog = gtk_file_dialog_new();
    gtk_file_dialog_set_title( dialog, cTitle );
    gtk_file_dialog_set_modal( dialog, TRUE );

    ctx.loop  = g_main_loop_new( NULL, FALSE );
    ctx.files = NULL;

    gtk_file_dialog_select_folder( dialog, hwg_get_parent_window(),
                                   NULL, hwg_file_open_cb, &ctx );

    g_main_loop_run( ctx.loop );
    g_main_loop_unref( ctx.loop );

    if( ctx.files )
    {
        char *path = hwg_file_model_to_string( ctx.files );
        hb_retc( path ? path : "" );
        g_free( path );
        g_object_unref( ctx.files );
    }
    else
    {
        hb_retc( "" );
    }

    g_object_unref( dialog );
}


/* =====================================================================
 *  hwg_ChooseColor — GtkColorDialog
 * ===================================================================== */
typedef struct {
    GMainLoop *loop;
    GdkRGBA   *color;    /* to be freed with gdk_rgba_free() by caller */
} HWG_COLOR_CTX;

static HB_ULONG hwg_rgba_to_hbcolor( const GdkRGBA *c )
{
    guchar r = (guchar)( c->red   * 255.0 );
    guchar g = (guchar)( c->green * 255.0 );
    guchar b = (guchar)( c->blue  * 255.0 );

    return ( (HB_ULONG) r ) |
    ( (HB_ULONG) g << 8 ) |
    ( (HB_ULONG) b << 16 );
}

static void hwg_color_choose_cb( GObject *source, GAsyncResult *res, gpointer user_data )
{
    HWG_COLOR_CTX *ctx = (HWG_COLOR_CTX *) user_data;
    GError        *error = NULL;

    ctx->color = gtk_color_dialog_choose_rgba_finish(
        GTK_COLOR_DIALOG( source ), res, &error );

    if( error )
    {
        g_error_free( error );
        ctx->color = NULL;
    }

    g_main_loop_quit( ctx->loop );
}

HB_FUNC( HWG_CHOOSECOLOR )
{
    GtkColorDialog *dialog;
    HWG_COLOR_CTX   ctx;
    const char     *cTitle = ( hb_pcount() > 2 && HB_ISCHAR(3) )
    ? hb_parc(3) : "Select color";
    GdkRGBA         initial;

    if( hb_pcount() > 0 && !HB_ISNIL(1) )
    {
        hwg_parse_color( (HB_ULONG) hb_parnl(1), &initial );
    }
    else
    {
        initial.red   = 0;
        initial.green = 0;
        initial.blue  = 0;
        initial.alpha = 1.0;
    }

    dialog = gtk_color_dialog_new();
    gtk_color_dialog_set_title( dialog, cTitle );
    gtk_color_dialog_set_modal( dialog, TRUE );
    gtk_color_dialog_set_with_alpha( dialog, FALSE );

    ctx.loop  = g_main_loop_new( NULL, FALSE );
    ctx.color = NULL;

    gtk_color_dialog_choose_rgba( dialog, hwg_get_parent_window(),
                                  &initial, NULL,
                                  hwg_color_choose_cb, &ctx );

    g_main_loop_run( ctx.loop );
    g_main_loop_unref( ctx.loop );

    if( ctx.color )
    {
        hb_retnl( (HB_LONG) hwg_rgba_to_hbcolor( ctx.color ) );
        gdk_rgba_free( ctx.color );
    }
    else
    {
        hb_retnl( -1 );
    }

    g_object_unref( dialog );
}


/* =====================================================================
 *  Stubs / trivial wrappers
 * ===================================================================== */
HB_FUNC( HWG_HDGETSERIAL )
{
    hb_retnl( -1 );
}

/* =================== EOF of commond.c =========================== */
