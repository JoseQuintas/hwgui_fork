/*
 * $Id: misc.c 3512 2025-01-10 19:04:45Z df7be $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Miscellaneous functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTES
 * -----
 *   * Clipboard API changed: GtkClipboard was removed.  We use GdkClipboard
 *     accessed via gdk_display_get_clipboard().  Reading is async-only in
 *     GTK4, so HWG_GETCLIPBOARDTEXT wraps the async call in a local
 *     GMainLoop to keep the original synchronous behaviour.
 *
 *   * gdk_screen_width/height and gdk_screen_get_width_mm were removed.
 *     All screen geometry queries now go through GdkMonitor, obtained from
 *     gdk_display_get_monitors() (a GListModel).
 *
 *   * gtk_widget_show / hide / show_all were removed.  Visibility is a
 *     plain boolean property now: gtk_widget_set_visible().
 *
 *   * gtk_show_uri() was removed.  HWG_SHELLEXECUTE now uses
 *     g_app_info_launch_default_for_uri().
 *
 *   * HWG_GUITYPE now reports "GTK4".
 */

/*
 * Some troubleshooting notes:
 * The function HB_RETSTR() is Windows-only!
 * Use hb_retc() instead.
 */

#define HB_MEM_NUM_LEN  8

/* Standard C libraries */
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#ifndef __APPLE__
#include <malloc.h>
#endif
#include <time.h>
#include <sys/stat.h>

#include "windows.ch"
#include "guilib.h"
#include "hbmath.h"
#include "hbapi.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbset.h"
#include "item.api"
#include "hbtypes.h"
#include "hbwinuni.h"
#include <unistd.h>
#include "gtk/gtk.h"
#include "gdk/gdkkeysyms.h"
#if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
#include <windows.h>
#endif
/* Avoid warnings from GCC */
#include "warnings.h"

/* listbox.c -- LB_* message bridge, used by HWG_SENDMESSAGE below.
 * Declared locally, mirroring the extern block in control.c, so this
 * file does not need to pull in hwgtk4.h just for one prototype. */
extern HB_BOOL hwg_listbox_handle_message( GtkWidget *hWnd, HB_ULONG ulMsg,
                                           HB_LONG wParam, HB_LONG lParam,
                                           HB_LONG *pResult );

/* Same pattern for the combo and edit handlers, both defined further
 * down in this file.  The forward declarations are required because
 * HWG_SENDMESSAGE references them before their definitions appear. */
HB_BOOL hwg_combo_handle_message( GtkWidget *hWnd, HB_ULONG ulMsg,
                                  HB_LONG wParam, HB_LONG lParam,
                                  HB_LONG *pResult );

HB_BOOL hwg_edit_handle_message ( GtkWidget *hWnd, HB_ULONG ulMsg,
                                  HB_LONG wParam, HB_LONG lParam,
                                  HB_LONG *pResult );
/* ---------------------------------------------------------------------
 *  LB_ERR
 *
 *  windows.ch does not publish this one -- its LB_* block stops at
 *  LB_SETCOUNT (0x01A7).  Define it locally; the value matches the
 *  Win32 SDK and the ">= 0 means success" test in HListBox:DeleteItem.
 * --------------------------------------------------------------------- */
#define LB_ERR   (-1)

static GdkClipboard *clipboard = NULL;

void hwg_writelog( const char * sFile, const char * sTraceMsg, ... )
{
    FILE *hFile;

    if( sFile == NULL )
    {
        hFile = hb_fopen( "ac.log", "a" );
    }
    else
    {
        hFile = hb_fopen( sFile, "a" );
    }

    if( hFile )
    {
        va_list ap;

        va_start( ap, sTraceMsg );
        vfprintf( hFile, sTraceMsg, ap );
        va_end( ap );

        fclose( hFile );
    }

}

HB_FUNC( HWG_SETDLGRESULT )
{
}

HB_FUNC( HWG_SETCAPTURE )
{
}

HB_FUNC( HWG_RELEASECAPTURE )
{
}

/* ---------------------------------------------------------------------
 *  Clipboard (GTK4)
 *
 *  GtkClipboard was removed; GdkClipboard is the replacement, obtained
 *  from the display: gdk_display_get_clipboard( gdk_display_get_default() ).
 * ------------------------------------------------------------------- */
HB_FUNC( HWG_COPYSTRINGTOCLIPBOARD )
{
    if( !clipboard )
        clipboard = gdk_display_get_clipboard( gdk_display_get_default() );

    gdk_clipboard_set_text( clipboard, hb_parc( 1 ) );

    /*
     * GTK4: gdk_clipboard_store_async() is the async store.  The sync
     * variant is gone, but for text the store is essentially immediate.
     */
    gdk_clipboard_store_async( clipboard, G_PRIORITY_DEFAULT, NULL, NULL, NULL );
}

/* Small context used to bridge the async clipboard read into a sync call. */
typedef struct {
    GMainLoop *loop;
    char      *text;
} HWG_CLIPBOARD_READ_CTX;

static void hwg_clipboard_read_cb( GObject *source, GAsyncResult *res, gpointer user_data )
{
    HWG_CLIPBOARD_READ_CTX *ctx = (HWG_CLIPBOARD_READ_CTX *) user_data;
    GError *error = NULL;

    ctx->text = gdk_clipboard_read_text_finish( GDK_CLIPBOARD( source ), res, &error );
    if( error )
    {
        g_error_free( error );
        ctx->text = NULL;
    }

    g_main_loop_quit( ctx->loop );
}

HB_FUNC( HWG_GETCLIPBOARDTEXT )
{
    GdkClipboard *cb = gdk_display_get_clipboard( gdk_display_get_default() );
    HWG_CLIPBOARD_READ_CTX ctx;

    ctx.loop = g_main_loop_new( NULL, FALSE );
    ctx.text = NULL;

    gdk_clipboard_read_text_async( cb, NULL, hwg_clipboard_read_cb, &ctx );
    g_main_loop_run( ctx.loop );
    g_main_loop_unref( ctx.loop );

    if( ctx.text )
    {
        hb_retc( ctx.text );
        g_free( ctx.text );
    }
    else
        hb_retc( "" );
}

HB_FUNC( HWG_GETKEYBOARDSTATE )
{
    char lpbKeyState[256];
    HB_ULONG ulState = hb_parnl( 1 );

    memset( lpbKeyState, 0, 255 );

    /* Each bit is independent -- the three blocks are NOT nested. */
    if( ulState & 1 )
    {
        lpbKeyState[ 0x10 ] = 0x80;  /* Shift */
    }
    if( ulState & 2 )
    {
        lpbKeyState[ 0x11 ] = 0x80;  /* Ctrl  */
    }
    if( ulState & 4 )
    {
        lpbKeyState[ 0x12 ] = 0x80;  /* Alt   */
    }

    hb_retclen( lpbKeyState, 255 );
}


HB_FUNC( HWG_LOWORD )
{
    hb_retni( (int) ( hb_parnl( 1 ) & 0xFFFF ) );
}

HB_FUNC( HWG_HIWORD )
{
    hb_retni( (int) ( ( hb_parnl( 1 ) >> 16 ) & 0xFFFF ) );
}


HB_FUNC( HWG_BITOR )
{
    hb_retnl( hb_parnl(1) | hb_parnl(2) );
}

HB_FUNC( HWG_BITOR_INT )
{
    hb_retni( ( hb_parni( 1 ) | hb_parni( 2 ) ) );
}

HB_FUNC( HWG_BITAND )
{
    hb_retnl( hb_parnl(1) & hb_parnl(2) );
}

HB_FUNC( HWG_BITANDINVERSE )
{
    hb_retnl( hb_parnl(1) & (~hb_parnl(2)) );
}

HB_FUNC( HWG_SETBIT )
{
    if( hb_pcount() < 3 || hb_parni( 3 ) )
        hb_retnl( hb_parnl(1) | ( 1 << (hb_parni(2)-1) ) );
    else
        hb_retnl( hb_parnl(1) & ~( 1 << (hb_parni(2)-1) ) );
}

HB_FUNC( HWG_SETBITBYTE )
{
    int para3;

    if ( hb_pcount() < 3 )
    {
        hb_retni( hb_parni(1) );
    }

    para3 = hb_parni( 3 );
    if ( para3 < 0 || para3 > 1 )
    {
        hb_retni( hb_parni(1) );
    }

    if ( para3 == 1 )
    {
        hb_retni( hb_parni(1) | ( 1 << (hb_parni(2) - 1) ) );
    }
    else
    {
        hb_retni( hb_parni(1) & ~( 1 << (hb_parni(2) - 1) ) );
    }
}

HB_FUNC( HWG_CHECKBIT )
{
    hb_retl( hb_parnl(1) & ( 1 << (hb_parni(2)-1) ) );
}

HB_FUNC( HWG_PTRTOULONG )
{
    hb_retnl( hb_parnl( 1 ) );
}

HB_FUNC( HWG_ISPTREQ )
{
    hb_retl( HB_PARHANDLE( 1 ) == HB_PARHANDLE( 2 ) );
}

HB_FUNC( HWG_SIN )
{
    hb_retnd( sin( hb_parnd(1) ) );
}

HB_FUNC( HWG_COS )
{
    hb_retnd( cos( hb_parnd(1) ) );
}

/* ---------------------------------------------------------------------
 *  Screen geometry (GTK4)
 *
 *  gdk_screen_width/height and the gdk_screen_* getters were removed.
 *  GTK4 also removed gdk_display_get_monitor() and
 *  gdk_display_get_primary_monitor().  The portable replacement is
 *  gdk_display_get_monitors(), which returns a GListModel; the first
 *  item is used as the "default" monitor.
 *
 *  IMPORTANT: g_list_model_get_item() returns a NEW REFERENCE.  The
 *  caller MUST g_object_unref() the monitor when done.  All callers
 *  below honour that.
 * ------------------------------------------------------------------- */
static GdkMonitor *hwg_get_primary_monitor( void )
{
    GdkDisplay *display = gdk_display_get_default();
    GListModel *monitors;
    GdkMonitor *monitor;

    if( !display )
        return NULL;

    monitors = gdk_display_get_monitors( display );
    if( !monitors || g_list_model_get_n_items( monitors ) == 0 )
        return NULL;

    monitor = GDK_MONITOR( g_list_model_get_item( monitors, 0 ) );
    return monitor;   /* caller owns the reference */
}

HB_FUNC( HWG_GETDESKTOPWIDTH )
{
    GdkMonitor *monitor = hwg_get_primary_monitor();

    if( monitor )
    {
        GdkRectangle geom;
        gdk_monitor_get_geometry( monitor, &geom );
        hb_retni( geom.width );
        g_object_unref( monitor );
    }
    else
        hb_retni( 0 );
}

HB_FUNC( HWG_GETDESKTOPHEIGHT )
{
    GdkMonitor *monitor = hwg_get_primary_monitor();

    if( monitor )
    {
        GdkRectangle geom;
        gdk_monitor_get_geometry( monitor, &geom );
        hb_retni( geom.height );
        g_object_unref( monitor );
    }
    else
        hb_retni( 0 );
}

/* ---------------------------------------------------------------------
 *  Widget visibility (GTK4)
 *
 *  gtk_widget_show/hide/show_all were removed.  Visibility is a plain
 *  boolean property.  Children inherit visibility from their parent,
 *  so a single set_visible(TRUE) on the toplevel is enough.
 * ------------------------------------------------------------------- */
HB_FUNC( HWG_HIDEWINDOW )
{
    GtkWidget *w = (GtkWidget *) HB_PARHANDLE( 1 );
    if( w && GTK_IS_WIDGET( w ) )
        gtk_widget_set_visible( w, FALSE );
}

HB_FUNC( HWG_SHOWWINDOW )
{
    GtkWidget *w = (GtkWidget *) HB_PARHANDLE( 1 );
    if( w && GTK_IS_WIDGET( w ) )
        gtk_widget_set_visible( w, TRUE );
}

HB_FUNC( HWG_SHOWALL )
{
    GtkWidget *w = (GtkWidget *) HB_PARHANDLE( 1 );
    if( w && GTK_IS_WIDGET( w ) )
        gtk_widget_set_visible( w, TRUE );
}

/* =====================================================================
 *  HWG_SENDMESSAGE
 *
 *  Global Win32 SendMessage() emulation.  Delegates to one handler
 *  per widget family; each handler returns TRUE when the message was
 *  recognised.  Add a new "if( hwg_xxx_handle_message(...) )" line
 *  for each new widget class that needs LB_*CB_/EM_* support.
 * ===================================================================== */
HB_FUNC( HWG_SENDMESSAGE )
{
    GtkWidget *hWnd   = (GtkWidget*) HB_PARHANDLE( 1 );
    HB_ULONG   ulMsg  = (HB_ULONG)   hb_parnl( 2 );
    HB_LONG    wParam = (HB_LONG)    hb_parnl( 3 );
    HB_LONG    lParam = (HB_LONG)    hb_parnl( 4 );
    HB_LONG    result = 0;

    /* Each widget family publishes a handler that returns TRUE when
     * it recognises the message.  The chain short-circuits on the
     * first match, so the dispatch cost is proportional to how many
     * families are tried before a hit -- negligible at HWGui scale. */
    if( hWnd && G_IS_OBJECT( hWnd ) )
    {
        if( hwg_listbox_handle_message( hWnd, ulMsg, wParam, lParam, &result ) ||
            hwg_combo_handle_message  ( hWnd, ulMsg, wParam, lParam, &result ) ||
            hwg_edit_handle_message   ( hWnd, ulMsg, wParam, lParam, &result ) )
        {
            hb_retnl( result );
            return;
        }
    }

    hb_retnl( 0 );
}

/* =====================================================================
 *  HWG_ISCTRLSHIFT
 *
 *  Returns .T. when the requested modifier keys are currently held.
 *
 *  Called from hlistbox.prg's onEvent():
 *
 *      hwg_GetSkip( ::oParent, ::handle, , ;
 *                   iif( hwg_IsCtrlShift( .f., .t. ), -1, 1 ) )
 *
 *  Declared as REQUEST in hwgextern.ch, so it must exist in C on
 *  every backend.  Parameters follow the Win32 convention:
 *
 *      1 - lCtrl  : .T. to test Ctrl  (default .F.)
 *      2 - lShift : .T. to test Shift (default .T.)
 *
 *  Both .F.  -> returns .T. if EITHER modifier is down.
 *  Otherwise -> returns .T. only when BOTH requested keys are down.
 *
 *  GTK4 replacement for gdk_keymap_get_modifier_state() (removed in
 *  GTK4) is gdk_device_get_modifier_state() on the seat's keyboard.
 * ===================================================================== */
HB_FUNC( HWG_ISCTRLSHIFT )
{
    GdkDisplay     *display;
    GdkSeat        *seat;
    GdkDevice      *keyboard;
    GdkModifierType state  = 0;
    HB_BOOL         lCtrl  = HB_ISLOG( 1 ) ? hb_parl( 1 ) : FALSE;
    HB_BOOL         lShift = HB_ISLOG( 2 ) ? hb_parl( 2 ) : TRUE;
    HB_BOOL         bCtrl;
    HB_BOOL         bShift;

    display = gdk_display_get_default();
    if( !display )
    {
        hb_retl( FALSE );
        return;
    }

    seat = gdk_display_get_default_seat( display );
    if( !seat )
    {
        hb_retl( FALSE );
        return;
    }

    keyboard = gdk_seat_get_keyboard( seat );
    if( !keyboard )
    {
        hb_retl( FALSE );
        return;
    }

    state = gdk_device_get_modifier_state( keyboard );

    bCtrl  = ( state & GDK_CONTROL_MASK ) != 0;
    bShift = ( state & GDK_SHIFT_MASK   ) != 0;

    if( !lCtrl && !lShift )
        hb_retl( bCtrl || bShift );
    else
        hb_retl( ( !lCtrl  || bCtrl  ) &&
        ( !lShift || bShift ) );
}

HB_FUNC( HWG_GETNOTIFYCODE )
{
}

/* ---------------------------------------------------------------------
 *  Device area (GTK4)
 *
 *  Same as desktop width/height, but also returns millimetre sizes.
 *  Array format: { width_px, height_px, width_mm, height_mm }.
 * ------------------------------------------------------------------- */
HB_FUNC( HWG_GETDEVICEAREA )
{
    GdkMonitor *monitor = hwg_get_primary_monitor();

    PHB_ITEM aMetr = hb_itemArrayNew( 4 );
    PHB_ITEM temp;

    if( monitor )
    {
        GdkRectangle geom;
        gdk_monitor_get_geometry( monitor, &geom );

        temp = hb_itemPutNL( NULL, (HB_LONG) geom.width );
        hb_itemArrayPut( aMetr, 1, temp );

        hb_itemPutNL( temp, (HB_LONG) geom.height );
        hb_itemArrayPut( aMetr, 2, temp );

        hb_itemPutNL( temp, (HB_LONG) gdk_monitor_get_width_mm( monitor ) );
        hb_itemArrayPut( aMetr, 3, temp );

        hb_itemPutNL( temp, (HB_LONG) gdk_monitor_get_height_mm( monitor ) );
        hb_itemArrayPut( aMetr, 4, temp );

        hb_itemRelease( temp );
        g_object_unref( monitor );
    }
    else
    {
        int i;
        for( i = 1; i <= 4; i++ )
        {
            temp = hb_itemPutNL( NULL, 0 );
            hb_itemArrayPut( aMetr, i, temp );
            hb_itemRelease( temp );
        }
    }

    hb_itemReturn( aMetr );
    hb_itemRelease( aMetr );
}

HB_FUNC( HWG_COLORRGB2N )
{
    hb_retnl( hb_parni( 1 ) + hb_parni( 2 ) * 256 + hb_parni( 3 ) * 65536 );
}

HB_FUNC( HWG_SLEEP )
{
    if( hb_parinfo( 1 ) )
        usleep( hb_parnl( 1 ) * 1000 );
}

HB_FUNC( HWG_SLEEP_C )
{
    if( hb_parinfo( 1 ) )
        usleep( hb_parnl( 1 ) );
}

HB_FUNC( HWG_RUNAPP )
{
    GError * error = NULL;
    gint rc = 0;
    g_spawn_command_line_async( hb_parc(1),  &error );
    if (error)
    {
        rc = error->code ;
        g_error_free(error);
    }
    hb_retni ( rc );
}

/* This function only for experimental usage */
static void child_watch_cb (
    GPid     pid,
    gint     status,
    gpointer user_data)
{
    /* This avoids, that the process is after end existing like a zombie process */
    g_spawn_close_pid (pid);
}

HB_FUNC( HWG_RUNCONSAPP )
{
    GError * error = NULL;
    gint rc = 0;

    gchar *argv[2];
    GPid  pid = 0;

    argv[0] = hb_parc(1);  /* Name of external program */
    argv[1] = NULL;

    g_spawn_async_with_pipes(
        NULL,             //   gchar *working_directory
        argv,             //   gchar **argv
        NULL,             //   gchar **envp
        G_SPAWN_SEARCH_PATH | G_SPAWN_CHILD_INHERITS_STDIN,
        NULL,             //   GSpawnChildSetupFunc child_setup
        NULL,             //   gpointer user_data
        &pid,             //   GPid *child_pid
        NULL,             //   gint *standard_input
        NULL,             //   gint *standard_output
        NULL,             //   gint *standard_error
        &error);          //   GError **error

    if (error != NULL)
    {
        rc = error->code;
        g_error_free(error);
        hwg_writelog(NULL, "Program start terminated with error");
        hb_retni ( rc );
        return;
    }

    /* Watch the started process so it is reaped when it exits. */
    if( pid > 0 )
        g_child_watch_add( pid, child_watch_cb, NULL );

    hb_retni ( rc );
}


/* ---------------------------------------------------------------------
 *  Shell execute (GTK4)
 *
 *  gtk_show_uri() was removed.  The recommended replacement is
 *  g_app_info_launch_default_for_uri().  It returns FALSE if no
 *  application is registered for the scheme.
 * ------------------------------------------------------------------- */
HB_FUNC( HWG_SHELLEXECUTE )
{
    const gchar *uri = hb_parc( 1 );
    GError *error = NULL;
    gboolean ok = g_app_info_launch_default_for_uri( uri, NULL, &error );

    if( error )
        g_error_free( error );

    hb_retl( ok );
}

HB_FUNC( HWG_GETCENTURY )
{
    HB_BOOL centset = hb_setGetCentury();
    hb_retl(centset);
}

/* DF7BE: This functions works on GTK cross development environment */
HB_FUNC( HWG_ISWIN7 )
{
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    OSVERSIONINFO ovi;
    ovi.dwOSVersionInfoSize = sizeof ovi;
    ovi.dwMajorVersion = 0;
    ovi.dwMinorVersion = 0;
    GetVersionEx( &ovi );
    hb_retl( ovi.dwMajorVersion >= 6 && ovi.dwMinorVersion == 1 );
    #else
    hb_retl( 1 == 2 );  /* .F.  for all other operating systems */
    #endif
}

HB_FUNC( HWG_ISWIN10 )
{
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    OSVERSIONINFO ovi;
    ovi.dwOSVersionInfoSize = sizeof ovi;
    ovi.dwMajorVersion = 0;
    ovi.dwMinorVersion = 0;
    GetVersionEx( &ovi );
    hb_retl( ovi.dwMajorVersion >= 6 && ovi.dwMinorVersion == 2 );
    #else
    hb_retl( 1 == 2 );  /* .F.  for all other operating systems */
    #endif
}

HB_FUNC( HWG_GETWINMAJORVERS )
{
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    OSVERSIONINFO ovi;
    ovi.dwOSVersionInfoSize = sizeof ovi;
    ovi.dwMajorVersion = 0;
    ovi.dwMinorVersion = 0;
    GetVersionEx( &ovi );
    hb_retni( ovi.dwMajorVersion );
    #else
    hb_retni( -1 );  /* -1  for all other operating systems */
    #endif
}

HB_FUNC( HWG_GETWINMINORVERS )
{
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    OSVERSIONINFO ovi;
    ovi.dwOSVersionInfoSize = sizeof ovi;
    ovi.dwMajorVersion = 0;
    ovi.dwMinorVersion = 0;
    GetVersionEx( &ovi );
    hb_retni( ovi.dwMinorVersion );
    #else
    hb_retni( -1 );  /* -1  for all other operating systems */
    #endif
}

HB_FUNC( HWG_GETTEMPDIR )
{
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    TCHAR szBuffer[MAX_PATH + 1] = { 0 };

    GetTempPath( MAX_PATH, szBuffer );
    hb_retc( szBuffer );
    #else
    char const * tempdirname = getenv("TMPDIR");

    if (tempdirname == NULL)
    { tempdirname = "/tmp"; }
    hb_retc(tempdirname);
    #endif
}

HB_FUNC( HWG_GETWINDOWSDIR )
{
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    TCHAR szBuffer[MAX_PATH + 1] = { 0 };

    GetWindowsDirectory( szBuffer, MAX_PATH );
    hb_retc( szBuffer );
    #else
    hb_retc("");
    #endif
}

/* experimental state of this function */
HB_FUNC( HWG_GETKEYSTATE )
{
}

HB_FUNC( HWG_SHOWSCROLLBAR )
{
}

/*
 * ============================================
 * FUNCTION hwg_STOD
 * Extra implementation of STOD(),
 * it is a Clipper tools function.
 * For compatibilty purposes.
 * Parameter 1: Date String
 * in ANSI-Format YYYYMMDD.
 * Result value is independant from
 * SET DATE and SET CENTURY settings.
 * Sample Call:
 * ddate := hwg_STOD("20201108")
 * ============================================
 */

HB_FUNC( HWG_STOD )
{
    PHB_ITEM pDateString = hb_param( 1, HB_IT_STRING );

    hb_retds( hb_itemGetCLen( pDateString ) >= 7 ? hb_itemGetCPtr( pDateString ) : NULL );
}

int hwg_hexbin(int cha)
/* converts single hex char to int, returns -1, if not in range
 returns 0 - 15 (dec), only a half byte **/
{
    char gross;
    int o;

    gross = toupper(cha);
    switch (gross)
    {
        case 48:  /* 0 */
            o = 0;
            break;
        case 49:  /* 1 */
            o = 1;
            break;
        case 50:  /* 2 */
            o = 2;
            break;
        case 51:  /* 3 */
            o = 3;
            break;
        case 52:  /* 4 */
            o = 4;
            break;
        case 53:  /* 5 */
            o = 5;
            break;
        case 54:  /* 6 */
            o = 6;
            break;
        case 55:  /* 7 */
            o = 7;
            break;
        case 56:  /* 8 */
            o = 8;
            break;
        case 57:  /* 9 */
            o = 9;
            break;
        case 65:  /* A */
            o = 10;
            break;
        case 66:  /* B */
            o = 11;
            break;
        case 67:  /* C */
            o = 12;
            break;
        case 68:  /* D */
            o = 13;
            break;
        case 69:  /* E */
            o = 14;
            break;
        case 70:  /* F */
            o = 15;
            break;
        default:
            o = -1;
    }
    return o;
}

/*
 * hwg_Bin2DC(cbin,nlen,ndec)
 */

HB_FUNC( HWG_BIN2DC )
{

    double pbyNumber;
    int i;
    unsigned char o;
    unsigned char bu[8];     /* Buffer with binary contents of double value */
    unsigned char szHex[17]; /* The hex string from parameter 1 + null byte*/


    int p;
    int c;      /* char with int value hex from hex */
    int od;     /* odd even sign / gerade - ungerade */

    /* init vars */

    pbyNumber = 0;

    szHex[0] = '\0';
    szHex[1] = '\0';
    szHex[2] = '\0';
    szHex[3] = '\0';
    szHex[4] = '\0';
    szHex[5] = '\0';
    szHex[6] = '\0';
    szHex[7] = '\0';
    szHex[8] = '\0';
    szHex[9] = '\0';
    szHex[10] = '\0';
    szHex[11] = '\0';
    szHex[12] = '\0';
    szHex[13] = '\0';
    szHex[14] = '\0';
    szHex[15] = '\0';
    szHex[16] = '\0';


    p = 0;
    c = 0;
    od = 0;

    /* Internal I2BIN for Len */

    HB_USHORT uiWidth = ( HB_USHORT ) hb_parni( 2 );

    /* Internal I2BIN for Dec */

    HB_USHORT uiDec = ( HB_USHORT ) hb_parni( 3 );


    const char *name = hb_parc( 1 );

    memcpy(&szHex,name,16);

    szHex[16] = '\0';

    /* Convert hex to bin */

    for ( i = 0 ; i < 16; i++ )
    {

        c = hwg_hexbin(szHex[i]);
        /* ignore, if not in 0 ... 1, A ... F */
        if ( c  != -1 )
        {
            /*
             * must be a pair of chars,
             * other values between the pairs of hex values are ignored
             */
            if ( od == 1 )
            {
                od = 0;
            }
            else
            {
                od = 1;
            }
            /* 1. Halbbyte zwischenspeichern / Store first half byte */
            if ( od == 1)
            {
                p = c;
            }
            else
            {
                /*
                 * 2. Halbbyte verarbeiten, ganzes Byte ausspeichern
                 *    / Process second half byte and store full byte
                 */
                p = ( p * 16 ) + c;
                o = (unsigned char) p;
                bu[ i / 2 ] = o;
            }
        }
    }

    /* Convert buffer to double */

    memcpy(&pbyNumber,bu,sizeof(pbyNumber));

    /* Return double value as type N */

    hb_retndlen( pbyNumber , uiWidth , uiDec );

}

static void GetFileMtimeU(const char * filePath)
{
    /* Format: YYYYMMDD-HH:MM:SS  for example: 20211204-20:05:42 l= 17 + NULL byte */
    struct stat attrib;
    char date[18];
    stat (filePath, &attrib);

    strftime(date, sizeof(date) , "%Y%m%d-%H:%M:%S", gmtime(&(attrib.st_mtime)));
    hb_retc(date);
}

static void GetFileMtime(const char * filePath)
{
    /* Format: YYYYMMDD-HH:MM:SS  for example: 20211204-20:05:42 l= 17 + NULL byte */
    struct stat attrib;
    char date[18];
    stat (filePath, &attrib);
    strftime(date, sizeof(date) , "%Y%m%d-%H:%M:%S", localtime(&(attrib.st_mtime)));
    hb_retc(date);
}


HB_FUNC( HWG_FILEMODTIMEU )
{
    GetFileMtimeU( ( const char * ) hb_parc(1) );
}


HB_FUNC( HWG_FILEMODTIME )
{
    GetFileMtime( ( const char * ) hb_parc(1) );
}


/* hwg_Toggle_HalfByte_C(n) */
HB_FUNC( HWG_TOGGLE_HALFBYTE_C )
{
    int i,k,l;

    i = hb_parni( 1 );
    k = i & 15;
    l = i & 240;

    k = k << 4;
    l = l >> 4;

    hb_retni( l | k );

}

/* ---------------------------------------------------------------------
 *  HWG_GUITYPE — report the active toolkit
 * ------------------------------------------------------------------- */
HB_FUNC( HWG_GUITYPE )
{
    #if GTK_MAJOR_VERSION >= 4
    hb_retc( "GTK4" );
    #elif GTK_MAJOR_VERSION >= 3
    hb_retc( "GTK3" );
    #else
    hb_retc( "GTK2" );
    #endif
}

/* =====================================================================
 *  Combo box message handler
 *
 *  Called from HWG_SENDMESSAGE for CB_* messages.  Only numeric
 *  messages are handled here -- the string-carrying ones
 *  (CB_ADDSTRING, CB_INSERTSTRING, CB_FINDSTRING, CB_SELECTSTRING,
 *  CB_GETLBTEXT) require a dedicated function because SendMessage
 *  only transports integer arguments.  HWGui's .prg side already
 *  uses hwg_ComboAddString / hwg_ComboSetArray for those paths (see
 *  control.c), so the dispatcher below can reject them cleanly.
 * ===================================================================== */

static gint hwg_combo_count( GtkWidget *combo )
{
    GtkTreeModel *model;

    if( !combo || !GTK_IS_COMBO_BOX( combo ) )
        return 0;

    model = gtk_combo_box_get_model( GTK_COMBO_BOX( combo ) );
    if( !model )
        return 0;

    return gtk_tree_model_iter_n_children( model, NULL );
}

HB_BOOL hwg_combo_handle_message( GtkWidget *hWnd, HB_ULONG ulMsg,
                                  HB_LONG wParam, HB_LONG lParam,
                                  HB_LONG *pResult )
{
    if( !hWnd || !G_IS_OBJECT( hWnd ) || !GTK_IS_COMBO_BOX( hWnd ) )
        return FALSE;

    switch( ulMsg )
    {
        case CB_RESETCONTENT:
            /* Only GtkComboBoxText exposes remove_all().  Non-text
             * combos would have to clear the GtkTreeModel row by row;
             * HWG_CREATECOMBO only ever builds GtkComboBoxText, so
             * this branch is safe for the HWGui usage. */
            if( GTK_IS_COMBO_BOX_TEXT( hWnd ) )
                gtk_combo_box_text_remove_all( GTK_COMBO_BOX_TEXT( hWnd ) );

        *pResult = 0;
        return TRUE;

        case CB_DELETESTRING:
        {
            gint idx = (gint) wParam;

            if( idx >= 0 && GTK_IS_COMBO_BOX_TEXT( hWnd ) )
                gtk_combo_box_text_remove( GTK_COMBO_BOX_TEXT( hWnd ), idx );

            *pResult = hwg_combo_count( hWnd );
            return TRUE;
        }

        case CB_GETCOUNT:
            *pResult = hwg_combo_count( hWnd );
            return TRUE;

        case CB_GETCURSEL:
            /* gtk_combo_box_get_active() returns 0-based, -1 when
             * nothing is selected -- exactly the Win32 semantics. */
            *pResult = gtk_combo_box_get_active( GTK_COMBO_BOX( hWnd ) );
            return TRUE;

        case CB_SETCURSEL:
        {
            gint idx = (gint) wParam;

            if( idx < 0 || idx >= hwg_combo_count( hWnd ) )
                gtk_combo_box_set_active( GTK_COMBO_BOX( hWnd ), -1 );
            else
                gtk_combo_box_set_active( GTK_COMBO_BOX( hWnd ), idx );

            *pResult = 0;
            return TRUE;
        }

        case CB_SETITEMHEIGHT:
            /* Stored as a hint.  GtkComboBoxText does not offer fixed
             * row height; CSS would be the way to apply it, but for the
             * demo scale we just remember the value so CB_GETITEMHEIGHT
             * is symmetric. */
            g_object_set_data( (GObject*) hWnd, "hwg_combo_itemheight",
                               GINT_TO_POINTER( (gint) lParam ) );
            *pResult = 0;
            return TRUE;

        case CB_GETITEMHEIGHT:
            *pResult = GPOINTER_TO_INT(
                g_object_get_data( (GObject*) hWnd,
                                   "hwg_combo_itemheight" ) );
            return TRUE;

        case CB_ADDSTRING:
        case CB_INSERTSTRING:
        case CB_FINDSTRING:
        case CB_SELECTSTRING:
        case CB_GETLBTEXT:
        case CB_GETLBTEXTLEN:
            /* String-carrying messages cannot travel through
             * hwg_Sendmessage() -- its lParam is an integer.  The .prg
             * side reaches these via dedicated functions
             * (hwg_ComboAddString, hwg_ComboSetArray, ...) already
             * implemented in control.c.  Returning CB_ERR here just
             * makes the misuse visible instead of silently succeeding. */
            *pResult = -1;
            return TRUE;
    }

    return FALSE;
}


/* =====================================================================
 *  Edit message handler
 *
 *  Handles both GtkEntry (single-line) and GtkTextView (multi-line),
 *  because HWG_CREATEEDIT builds one or the other depending on the
 *  ES_MULTILINE style bit.  The widget handle returned to Harbour is
 *  the same in both cases (the .c layer stores the GtkScrolledWindow
 *  wrapper of the multi-line variant under the "main_widget" key).
 * ===================================================================== */

HB_BOOL hwg_edit_handle_message( GtkWidget *hWnd, HB_ULONG ulMsg,
                                 HB_LONG wParam, HB_LONG lParam,
                                 HB_LONG *pResult )
{
    HB_BOOL is_view;
    HB_BOOL is_editable;

    if( !hWnd || !G_IS_OBJECT( hWnd ) )
        return FALSE;

    is_view     = GTK_IS_TEXT_VIEW( hWnd );
    is_editable = GTK_IS_EDITABLE( hWnd );

    if( !is_view && !is_editable )
        return FALSE;

    switch( ulMsg )
    {
        case EM_GETSEL:
        {
            gint start = 0, end = 0;

            if( is_editable )
            {
                if( !gtk_editable_get_selection_bounds( GTK_EDITABLE( hWnd ),
                    &start, &end ) )
                {
                    /* No selection: both values hold the caret position,
                     * matching the Win32 behaviour. */
                    start = end = gtk_editable_get_position( GTK_EDITABLE( hWnd ) );
                }
            }

            /* Win32 packs start in the low word and end in the high
             * word of the return value.  cb_edit_GetSel on the .prg
             * side unpacks with hwg_Loword / hwg_Hiword. */
            *pResult = ( (HB_LONG)( start & 0xFFFF ) ) |
            ( (HB_LONG)( end ) << 16 );
            return TRUE;
        }

        case EM_SETSEL:
        {
            gint start = (gint) wParam;
            gint end   = (gint) lParam;

            if( is_editable )
            {
                if( start < 0 )
                    gtk_editable_select_region( GTK_EDITABLE( hWnd ), 0, -1 );
                else
                    gtk_editable_select_region( GTK_EDITABLE( hWnd ), start, end );
            }

            *pResult = 0;
            return TRUE;
        }

        case EM_SETREADONLY:
        {
            HB_BOOL bReadOnly = ( wParam != 0 );

            if( is_view )
            {
                gtk_text_view_set_editable( GTK_TEXT_VIEW( hWnd ), !bReadOnly );
            }
            else if( is_editable )
            {
                gtk_editable_set_editable( GTK_EDITABLE( hWnd ), !bReadOnly );
            }

            /* GTK4 note: gtk_editable_set_editable(FALSE) is not enough on
             * its own.  The widget still receives focus and, depending on the
             * GTK build, may still accept keystrokes.  Removing the "can
             * focus" flag makes the read-only state stick, and disabling
             * sensitivity gives the visual feedback the user expects (the
             * field is greyed out and clearly non-interactive).
             *
             * gtk_widget_set_can_focus was introduced in GTK4 to replace the
             * old GTK_WIDGET_CAN_FOCUS flag.  On GTK3 it would be
             * gtk_widget_set_can_focus too, so no #ifdef is needed. */
            if( !is_view )
            {
                gtk_widget_set_can_focus( hWnd, !bReadOnly );
                gtk_widget_set_sensitive( hWnd, !bReadOnly );
            }

            *pResult = 0;
            return TRUE;
        }

        case EM_LIMITTEXT:
        {
            gint max = (gint) wParam;

            if( GTK_IS_ENTRY( hWnd ) )
                gtk_entry_set_max_length( GTK_ENTRY( hWnd ), max );

            /* Stored on the widget so the multi-line path (and
             * HWG_CREATEEDIT's own max-length bookkeeping) can consult
             * it later, and so EM_GETLIMITTEXT below returns what the
             * caller set. */
            g_object_set_data( (GObject*) hWnd, "hwg_maxlen",
                               GINT_TO_POINTER( max ) );

            *pResult = 0;
            return TRUE;
        }

        case EM_GETLIMITTEXT:
        {
            gint max = 0;

            if( GTK_IS_ENTRY( hWnd ) )
            {
                max = gtk_entry_get_max_length( GTK_ENTRY( hWnd ) );
            }

            if( max <= 0 )
            {
                max = GPOINTER_TO_INT(
                    g_object_get_data( (GObject*) hWnd, "hwg_maxlen" ) );
            }

            *pResult = max;
            return TRUE;
        }

        case EM_GETLINECOUNT:
        {
            if( is_view )
            {
                GtkTextBuffer *buf = gtk_text_view_get_buffer( GTK_TEXT_VIEW( hWnd ) );
                *pResult = gtk_text_buffer_get_line_count( buf );
            }
            else
            {
                *pResult = 1;
            }

            return TRUE;
        }

        case EM_LINELENGTH:
        {
            /* Single-line: the length of the whole content.
             * Multi-line: computing the length of the line at position
             * wParam needs a GtkTextIter walk; return 0 to signal "not
             * implemented" rather than guessing. */
            if( is_editable && !is_view )
            {
                const gchar *text = gtk_editable_get_text( GTK_EDITABLE( hWnd ) );
                *pResult = text ? g_utf8_strlen( text, -1 ) : 0;
            }
            else
            {
                *pResult = 0;
            }

            return TRUE;
        }

        case EM_SCROLLCARET:
            if( is_view )
            {
                GtkTextBuffer *buf  = gtk_text_view_get_buffer( GTK_TEXT_VIEW( hWnd ) );
                GtkTextMark   *mark = gtk_text_buffer_get_insert( buf );

                gtk_text_view_scroll_to_mark( GTK_TEXT_VIEW( hWnd ), mark,
                                              0.0, FALSE, 0.0, 0.0 );
            }
            *pResult = 0;
            return TRUE;

        case EM_SETMODIFY:
            g_object_set_data( (GObject*) hWnd, "hwg_modified",
                               GINT_TO_POINTER( wParam != 0 ? 1 : 0 ) );

            if( is_view )
            {
                GtkTextBuffer *buf = gtk_text_view_get_buffer( GTK_TEXT_VIEW( hWnd ) );
                gtk_text_buffer_set_modified( buf, wParam != 0 );
            }
            *pResult = 0;
            return TRUE;

        case EM_GETMODIFY:
        {
            if( is_view )
            {
                GtkTextBuffer *buf = gtk_text_view_get_buffer( GTK_TEXT_VIEW( hWnd ) );
                *pResult = gtk_text_buffer_get_modified( buf ) ? 1 : 0;
            }
            else
            {
                *pResult = GPOINTER_TO_INT(
                    g_object_get_data( (GObject*) hWnd,
                                       "hwg_modified" ) );
            }

            return TRUE;
        }
    }
    return FALSE;
}

/* ========= EOF of misc.c ============ */
