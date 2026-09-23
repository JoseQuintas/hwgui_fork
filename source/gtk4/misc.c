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

HB_FUNC( HWG_SENDMESSAGE )
{
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

/* ========= EOF of misc.c ============ */
