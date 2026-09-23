/*
 * $Id: inter.c 3464 2024-07-23 08:48:45Z df7be $
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Additional Functions for National Language Support ("International")
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2020 Wilfried Brunken, DF7BE
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It has no GTK/GDK dependencies
 * at all.  All platform-specific code is isolated inside
 * "#if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) ||
 *  defined(__MINGW64__)" blocks; the Linux branch uses only POSIX/libc:
 *
 *     setlocale(LC_CTYPE, NULL)
 *     time() / gmtime() / localtime()
 *
 * The original file does not include gtk.h nor hwgtk.h (the hwgtk.h
 * include is commented out), so it is unaffected by the GTK4 migration.
 *
 * Pre-existing bug (not GTK4-related): hwg_strdebuglog() uses
 * sizeof((char *) dest), which is the size of a pointer, not the
 * string length.  The loop therefore always iterates 8 times on a
 * 64-bit host.  Left as-is to preserve behaviour.
 */


#include "guilib.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"
#include "hbtypes.h"
#include "hbwinuni.h"


// #include "hwgtk.h"
#include "hbdate.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

#ifdef __APPLE__
#include <sys/uio.h>
#include <unistd.h>
#else
#include <sys/io.h>
#endif
// #include <malloc.h>

/* Avoid warnings from GCC */
#include "warnings.h"

/* For GTK Windows cross development environment by DF7BE */
#if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
/* Type conflict GtkWidget *GetActiveWindow  ==> do not include gtk/gtk.h */
#include <windows.h>
#include <winnt.h>
#include <winnls.h>
// --- List of needed defines and symbols in this module ---
// typedef char	TCHAR;  /* from tchar.h */
// #define LOCALE_USER_DEFAULT	0x400  /* from winnls.h */
// #define LOCALE_SLIST	12
// typedef WORD LANGID; /* from winnt.h */
// WINBASEAPI LANGID WINAPI GetUserDefaultUILanguage(void);  /* from winnls.h */
/*
 ! "if (WINVER >= 0x0500)" has no effect on MinGW, so defined here.*
 */
WINBASEAPI LANGID WINAPI GetUserDefaultUILanguage(void);
#else
#include <time.h>
#include <locale.h>
#endif

/* from hwingui.h */
extern void hwg_writelog( const char * sFile, const char * sTraceMsg, ... );

/*
 S ome troubleshootings:                                            *
 The function HB_RETSTR() is windows only !
 Use hb_retc().
 */

HB_FUNC( HWG_GETLOCALEINFO )
/* Port to GTK added by DF7BE */
{
    char * puf = malloc(128);
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    TCHAR szBuffer[] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"; /* l=20 */
    GetLocaleInfo( LOCALE_USER_DEFAULT, LOCALE_SLIST, szBuffer,
                   HB_SIZEOFARRAY( szBuffer ) );
    strncpy(puf, szBuffer, 24);
    hb_retc( puf );
    free ( puf );
    #else
    char * lokale;
    lokale = setlocale(LC_CTYPE,NULL); /* only user setting, LC_ALL displays all locale settings */
    if ( lokale == NULL ) /* Out of memory ? ==> return empty string */
        lokale = "\0";
    strncpy(puf, lokale, 127);  /* Avoid buffer overflow */
    //   hwg_writelog( NULL ,  puf);
    hb_retc( puf );
    free( puf );
    #endif
}

HB_FUNC( HWG_GETLOCALEINFON )
{
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    /* returns Windows LCID, type is int.
     W indows only , on other OSs available, returns forever -1. */  *
     int lio;
     lio = GetLocaleInfo( LOCALE_USER_DEFAULT, LOCALE_SLIST, NULL, 0 );
     hb_retni(lio);
     #else
     hb_retni( -1 );
     #endif
}

HB_FUNC( HWG_GETUTCTIMEDATE )
{
    /* Format: W,YYYYMMDD-HH:MM:SS */
    char cst[128] = { 0 };
    char * puf = malloc(25);
    int i;
    for ( i = 0 ; i < 128 ; i++) /* Fill string with zeroes to avoid buffer overflow on LINUX */
        cst[i] = '\0';
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    SYSTEMTIME st = { 0 };
    GetSystemTime(&st);
    sprintf(cst,"%01d.%04d%02d%02d-%02d:%02d:%02d",st.wDayOfWeek, st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);
    strncpy(puf, cst, 24);
    hb_retc( puf);
    free( puf);
    #else
    /* Note for possible extensions:
     t m.tm_yday;    Days since Jan. 1: 0-365                        *
     tm.tm_isdst;   +1 Daylight Savings Time, 0 No DST,
     * -1 don't know
     Use localtime ( &T ); for local time
     */
    time_t T = time( NULL );
    struct tm tm = * gmtime( &T );
    /* tm.tm_wday: Days since Sunday (0-6) */
    sprintf(cst,"%01d,%04d%02d%02d-%02d:%02d:%02d",tm.tm_wday, tm.tm_year + 1900,  tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
    strncpy(puf, cst, 24);
    hb_retc( puf );
    free( puf );
    #endif
}

HB_FUNC( HWG_GETDATEANSI )
{
    /* Format: YYYYMMDD, based on local time */
    char cst[128] = { 0 };
    char * puf = malloc(25);
    int i;
    for ( i = 0 ; i < 128 ; i++) /* Fill string with zeroes to avoid buffer overflow on LINUX */
        cst[i] = '\0';
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    SYSTEMTIME lt = { 0 };
    GetLocalTime(&lt);
    sprintf(cst,"%04d%02d%02d", lt.wYear, lt.wMonth, lt.wDay);
    strncpy(puf, cst, 24);
    hb_retc( puf);
    free( puf);
    #else
    /* Note for possible extensions:
     t m.tm_yday;    Days since Jan. 1: 0-365                        *
     tm.tm_isdst;   +1 Daylight Savings Time, 0 No DST,
     * -1 don't know
     Use localtime ( &T ); for local time
     */
    time_t T = time( NULL );
    struct tm tm = * localtime( &T );
    /* tm.tm_wday: Days since Sunday (0-6) */
    sprintf(cst,"%04d%02d%02d", tm.tm_year + 1900,  tm.tm_mon + 1, tm.tm_mday );
    strncpy(puf, cst, 24);
    hb_retc( puf );
    free( puf );
    #endif
}


HB_FUNC( HWG_DEFUSERLANG )
/* Windows only , on other OSs available, returns forever "-1". */
{
    char * puf = malloc(25);
    #if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
    char clang[25] = { 0 };
    LANGID l;  /* ==> WORD */
    l = GetUserDefaultUILanguage();
    sprintf(clang, "%d", l);
    strncpy(puf, clang , 24);
    hb_retc( puf );
    free( puf );
    #else
    /* "Mecker" vom Compiler vermeiden */
    strcpy( puf, "-1" );
    hb_retc( puf );
    free( puf );
    #endif
}

void hwg_strdebuglog(char * dest )
/* writes a string in logfile ac.log, only for debugging */
{
    size_t n;
    char c;
    char aus[1024] = {0};
    for ( n = 0; n < sizeof ( (char *) dest) ; ++n ) {
        c =  dest[n];
        c ? sprintf(aus,"'%c' ", c) : sprintf(aus,"'\\0' ");
        hwg_writelog( NULL ,  aus);
    }
}
/* ====================== EOF of inter.c ======================= */
