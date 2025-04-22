/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level windows functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * Some debugging info:
 *
 * Write messages to console window by example:
 * g_print ("Hello\n");
 *
 * Also format expressions are possible:
 * g_print ("%s\n",gcTitle);
 *
*/

#include "guilib.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"
#include <locale.h>

//#if ( GTK_MAJOR_VERSION -0 < 3 )
#include "gtk/gtk.h"
//#endif
#include "gdk/gdkkeysyms.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#else
#include "hbapicls.h"
#endif
#include "hwgtk.h"

/* Avoid warnings from GCC */
#include "warnings.h"

/* Migration to GTK 3 */

#if ! ( GTK_MAJOR_VERSION -0 < 3 )
// #include <gtk/gdkx.h>
#ifndef __PLATFORM__WINDOWS
#include <gdk/gdk.h>
#else
#include <gdk/gdkwin32.h>
#endif
#endif

#define WM_MOVE                           3
#define WM_SIZE                           5
#define WM_SETFOCUS                       7
#define WM_KILLFOCUS                      8
#define WM_PAINT                         15
#define WM_KEYDOWN                      256    // 0x0100
#define WM_KEYUP                        257    // 0x0101
#define WM_MOUSEMOVE                    512    // 0x0200
#define WM_MOUSELEAVE                   675    // 0x02A3
#define WM_LBUTTONDOWN                  513    // 0x0201
#define WM_LBUTTONUP                    514    // 0x0202
#define WM_LBUTTONDBLCLK                515    // 0x0203
#define WM_RBUTTONDOWN                  516    // 0x0204
#define WM_RBUTTONUP                    517    // 0x0205


extern void hwg_writelog( const char * sFile, const char * sTraceMsg, ... );

void SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue );
PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname );
void SetWindowObject( GtkWidget * hWnd, PHB_ITEM pObject );
void all_signal_connect( gpointer hWnd );
void set_signal( gpointer handle, char * cSignal, long int p1, long int p2, long int p3 );
void cb_signal( GtkWidget *widget,gchar* data );
gint cb_signal_size( GtkWidget *widget, GtkAllocation *allocation, gpointer data );
void set_event( gpointer handle, char * cSignal, long int p1, long int p2, long int p3 );

PHB_DYNS pSym_onEvent = NULL;
PHB_DYNS pSym_keylist = NULL;
guint s_KeybHook = 0;
GtkWidget * hMainWindow = NULL;

HB_LONG prevp2 = -1;

typedef struct
{
   char * cName;
   int msg;
} HW_SIGNAL, * PHW_SIGNAL;

#define NUMBER_OF_SIGNALS   1
static HW_SIGNAL aSignals[NUMBER_OF_SIGNALS] = { { "destroy",2 } };

static gchar szAppLocale[] = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";


gboolean cb_delete_event( GtkWidget *widget, gchar* data )
{
   gpointer gObject;

   HB_SYMBOL_UNUSED( data );
   gObject = g_object_get_data( (GObject*) widget, "obj" );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && gObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( ( PHB_ITEM ) gObject );
      hb_vmPushLong( 2 );
      hb_vmPushLong( 0 );
      hb_vmPushLong( 0 );
      hb_vmSend( 3 );
      return ! ((gboolean) hb_parl( -1 ));
   }
   return FALSE;
}

HB_FUNC( HWG_GTK_INIT )
{
   gtk_init( 0,0 );
   setlocale( LC_NUMERIC, "C" );
   setlocale( LC_CTYPE, "" );
}

HB_FUNC( HWG_GTK_EXIT )
{
   gtk_main_quit();
}

/*  Creates main application window
    hwg_InitMainWindow( pObject, szAppName, cTitle, cMenu, hIcon, nStyle, nLeft, nTop, nWidth, nHeight, hbackground )
*/
HB_FUNC( HWG_INITMAINWINDOW )
{
   GtkWidget * hWnd ;
   GtkWidget * vbox;
   GtkFixed * box;
#if GTK_MAJOR_VERSION -0 < 3
   GdkPixmap * background;
#else
   /* GdkPixbuf * background; */
   GtkWidget * background;
   GtkStyleContext * context;
   GtkApplication *app;
#endif
   GtkStyle * style;
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
   gchar *gcTitle = hwg_convert_to_utf8( hb_parcx( 3 ) );
   int x = hb_parnl(7);
   int y = hb_parnl(8);
   int width = hb_parnl(9);
   int height = hb_parnl(10);
   /* Icon */
   PHWGUI_PIXBUF szFile = HB_ISPOINTER(5) ? (PHWGUI_PIXBUF) HB_PARHANDLE(5): NULL;
   /* Background image */
   PHWGUI_PIXBUF szBackFile = HB_ISPOINTER(11) ? (PHWGUI_PIXBUF) HB_PARHANDLE(11): NULL;

   /* Background style*/
   style = gtk_style_new();

   if (szBackFile)
   {
#if GTK_MAJOR_VERSION -0 < 3
      /* GTK 2 */
      gdk_pixbuf_render_pixmap_and_mask(szBackFile->handle, &background, NULL, 0);
      if ( ! background ) g_error("%s\n","Error loading background image");
      style->bg_pixmap[0] = background ;
#endif
   }

#if GTK_MAJOR_VERSION -0 < 3
   hWnd = ( GtkWidget * ) gtk_window_new( GTK_WINDOW_TOPLEVEL );
#else
  app = gtk_application_new ("net.sourceforge.projects.hwgui.gtk.sample", G_APPLICATION_FLAGS_NONE);
  hWnd = gtk_application_window_new (app);
//  gtk_window_set_default_size (GTK_WINDOW (hWnd), 200, 200);
// hwg_writelog(NULL,"Hier");
  gtk_widget_show_all (hWnd);
#endif


#if ! ( GTK_MAJOR_VERSION -0 < 3 )
  /* GTK 3 */
  /* To be contiued
//  background = gtk_image_new_from_file( szBackFile->handle );

  if ( background )
   gdk_window_set_back_pixmap( GDK_WINDOW (hWnd), background, (gboolean) TRUE);
  */
#endif

   gtk_window_set_title( GTK_WINDOW(hWnd), gcTitle );

   g_free( gcTitle );

   //gtk_window_set_policy( GTK_WINDOW(hWnd), TRUE, TRUE, FALSE );
   gtk_window_set_resizable( GTK_WINDOW(hWnd), TRUE);
   gtk_window_set_default_size( GTK_WINDOW(hWnd), width, height );
   gtk_window_move( GTK_WINDOW(hWnd), x, y );

   vbox = gtk_vbox_new (FALSE, 0);
   gtk_container_add (GTK_CONTAINER(hWnd), vbox);

   box = (GtkFixed*)gtk_fixed_new();
   gtk_box_pack_start( GTK_BOX(vbox), (GtkWidget*)box, TRUE, TRUE, 0 );

   g_object_set_data( ( GObject * ) hWnd, "window", ( gpointer ) 1 );
   SetWindowObject( hWnd, pObject );
   g_object_set_data( (GObject*) hWnd, "vbox", (gpointer) vbox );
   g_object_set_data( (GObject*) hWnd, "fbox", (gpointer) box );

   gtk_widget_add_events( hWnd, GDK_BUTTON_PRESS_MASK |
         GDK_BUTTON_RELEASE_MASK |
         GDK_POINTER_MOTION_MASK | GDK_FOCUS_CHANGE );
   set_event( ( gpointer ) hWnd, "button_press_event", 0, 0, 0 );
   set_event( ( gpointer ) hWnd, "button_release_event", 0, 0, 0 );
   set_event( ( gpointer ) hWnd, "motion_notify_event", 0, 0, 0 );

   g_signal_connect (G_OBJECT (hWnd), "delete-event",
	 	      G_CALLBACK (cb_delete_event), NULL );
   g_signal_connect (G_OBJECT (hWnd), "destroy",
	 	      G_CALLBACK (gtk_main_quit), NULL);

   set_event( (gpointer)hWnd, "configure_event", 0, 0, 0 );
   set_event( (gpointer)hWnd, "focus_in_event", 0, 0, 0 );

   g_signal_connect_after( box, "size-allocate", G_CALLBACK (cb_signal_size), NULL );
   //g_signal_connect_after( hWnd, "size-allocate", G_CALLBACK (cb_signal_size), NULL );

/* Set default icon
   DF7BE:
   gtk_window_set_icon() does not work (GTK2)
*/

   if (szFile)
   {
        //gtk_window_set_default_icon( szFile->handle );
        gtk_window_set_icon(GTK_WINDOW(hWnd), szFile->handle  );
   }
   /* Set Background */
   if (szBackFile)
   {
     gtk_widget_set_style(GTK_WIDGET(hWnd), GTK_STYLE(style) );
   }

   hMainWindow = hWnd;
   HB_RETHANDLE( hWnd );
}

/*
  hwg_CreateDlg(nhandle)
*/

HB_FUNC( HWG_CREATEDLG )
{
   GtkWidget * hWnd;
   GtkWidget * vbox;
   GtkFixed  * box;
#if GTK_MAJOR_VERSION -0 < 3
   GdkPixmap * background = NULL;
#else
   /* GdkPixbuf * background; */
  GtkWidget * background;
  GtkStyleContext * context;
#endif

   GtkStyle * style;
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
   gchar *gcTitle = hwg_convert_to_utf8 ( hb_itemGetCPtr( GetObjectVar( pObject, "TITLE" ) ) );
   int x = hb_itemGetNI( GetObjectVar( pObject, "NLEFT" ) );
   int y = hb_itemGetNI( GetObjectVar( pObject, "NTOP" ) );
   int width = hb_itemGetNI( GetObjectVar( pObject, "NWIDTH" ) );
   int height = hb_itemGetNI( GetObjectVar( pObject, "NHEIGHT" ) );
   //PHB_ITEM pIcon = GetObjectVar( pObject, "OICON" );
   //PHB_ITEM pBmp = GetObjectVar( pObject, "OBMP" );
   PHWGUI_PIXBUF szFile = HB_ISPOINTER(2) ? (PHWGUI_PIXBUF) HB_PARHANDLE(2): NULL;
   PHWGUI_PIXBUF szBackFile = HB_ISPOINTER(3) ? (PHWGUI_PIXBUF) HB_PARHANDLE(3): NULL;

/*
   if( HB_IS_OBJECT(pIcon) )
      szFile = (PHWGUI_PIXBUF) hb_itemGetPtr( GetObjectVar(pIcon,"HANDLE") );
   if( HB_IS_OBJECT(pBmp) )
      szBackFile = (PHWGUI_PIXBUF) hb_itemGetPtr( GetObjectVar(pBmp,"HANDLE") );
*/
   /* Background style*/
   style = gtk_style_new();
   if (szBackFile)
   {
#if GTK_MAJOR_VERSION -0 < 3
      /* GTK 2 */
      gdk_pixbuf_render_pixmap_and_mask(szBackFile->handle, &background, NULL, 0);
      if ( ! background ) g_error("%s\n","Error loading background image");
      style->bg_pixmap[0] = background ;
#endif
   }

   hWnd = ( GtkWidget * ) gtk_window_new( GTK_WINDOW_TOPLEVEL );


#if ! ( GTK_MAJOR_VERSION -0 < 3 )
  /* GTK 3 */
  background = gtk_image_new_from_pixbuf( szBackFile->handle );
  /* To be contiued
  if ( background )
     gdk_window_set_back_pixmap( GDK_WINDOW (hWnd), background, (gboolean) TRUE);
  */
#endif

   if (szFile)
   {
      gtk_window_set_icon(GTK_WINDOW(hWnd), szFile->handle  );
   }

   gtk_window_set_title( GTK_WINDOW(hWnd), gcTitle );
   g_free( gcTitle );
   //gtk_window_set_policy( GTK_WINDOW(hWnd), TRUE, TRUE, FALSE );
   gtk_window_set_resizable( GTK_WINDOW(hWnd), TRUE);
   gtk_window_set_default_size( GTK_WINDOW(hWnd), width, height );
   gtk_window_move( GTK_WINDOW(hWnd), x, y );

   vbox = gtk_vbox_new (FALSE, 0);
   gtk_container_add (GTK_CONTAINER(hWnd), vbox);

   box = (GtkFixed*)gtk_fixed_new();
   gtk_box_pack_start( GTK_BOX(vbox), (GtkWidget*)box, TRUE, TRUE, 0 );

   g_object_set_data( ( GObject * ) hWnd, "window", ( gpointer ) 1 );
   SetWindowObject( hWnd, pObject );
   g_object_set_data( (GObject*) hWnd, "vbox", (gpointer) vbox );
   g_object_set_data( (GObject*) hWnd, "fbox", (gpointer) box );

   gtk_widget_add_events( hWnd, GDK_BUTTON_PRESS_MASK |
         GDK_BUTTON_RELEASE_MASK |
         GDK_POINTER_MOTION_MASK | GDK_FOCUS_CHANGE_MASK );
   set_event( ( gpointer ) hWnd, "button_press_event", 0, 0, 0 );
   set_event( ( gpointer ) hWnd, "button_release_event", 0, 0, 0 );
   set_event( ( gpointer ) hWnd, "motion_notify_event", 0, 0, 0 );

   g_signal_connect (G_OBJECT (hWnd), "delete-event",
      G_CALLBACK (cb_delete_event), NULL );

   set_event( (gpointer)hWnd, "configure_event", 0, 0, 0 );
   set_event( (gpointer)hWnd, "focus_in_event", 0, 0, 0 );
   set_event( ( gpointer )hWnd, "focus_out_event", 0, 0, 0 );

   g_signal_connect( box, "size-allocate", G_CALLBACK (cb_signal_size), NULL );
   //g_signal_connect( hWnd, "size-allocate", G_CALLBACK (cb_signal_size), NULL );

   /* Set Background */
   if (szBackFile)
   {
     gtk_widget_set_style(GTK_WIDGET(hWnd), GTK_STYLE(style) );
   }


   HB_RETHANDLE( hWnd );

}

/*
 *  HWG_ACTIVATEMAINWINDOW( lShow, hAccel, lMaximize, lMinimize )
 */
HB_FUNC( HWG_ACTIVATEMAINWINDOW )
{
/*
   GtkWidget * hWnd = (GtkWidget*) HB_PARHANDLE(1);

   if( !HB_ISNIL(3) && hb_parl(3) )
   {
      gtk_window_maximize( (GtkWindow*) hWnd );
   }
   if( !HB_ISNIL(4) && hb_parl(4) )
   {
      gtk_window_iconify( (GtkWindow*) hWnd );
   }

   gtk_widget_show_all( hWnd );
*/
   gtk_main();
}

HB_FUNC( HWG_ACTIVATEDIALOG )
{
   // gtk_widget_show_all( (GtkWidget*) HB_PARHANDLE(1) );
   if( HB_ISNIL(2) || !hb_parl(2) )
      gtk_main();
}

void hwg_doEvents( void )
{
   while( g_main_context_iteration( NULL, FALSE ) );
}

void ProcessMessage( void )
{
   while( g_main_context_iteration( NULL, FALSE ) );
}

HB_FUNC( HWG_PROCESSMESSAGE )
{
   ProcessMessage();
}

gint cb_signal_size( GtkWidget *widget, GtkAllocation *allocation, gpointer data )
{
   gpointer gObject; // = g_object_get_data( (GObject*)
      //gtk_widget_get_parent( gtk_widget_get_parent(widget) ), "obj" );
   //gpointer gObject = g_object_get_data( (GObject*) widget, "obj" );
   //HB_SYMBOL_UNUSED( data );

   if( data )
      gObject = g_object_get_data( (GObject*) widget, "obj" );
   else
      gObject = g_object_get_data( (GObject*)
         gtk_widget_get_parent( gtk_widget_get_parent(widget) ), "obj" );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && gObject )
   {
      HB_LONG p3 = ( (HB_ULONG)(allocation->width) & 0xFFFF ) |
                 ( ( (HB_ULONG)(allocation->height) << 16 ) & 0xFFFF0000 );

      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( ( PHB_ITEM ) gObject );
      hb_vmPushLong( WM_SIZE );
      hb_vmPushLong( 0 );
      hb_vmPushLong( p3 );
      hb_vmSend( 3 );

   }
   return 0;
}

void cb_signal( GtkWidget *widget,gchar* data )
{
   gpointer gObject;
   HB_LONG p1, p2, p3;

   sscanf( (char*)data,"%ld %ld %ld",&p1,&p2,&p3 );
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
      hb_vmPush( ( PHB_ITEM ) gObject );
      hb_vmPushLong( p1 );
      hb_vmPushLong( p2 );
      hb_vmPushLong( (HB_LONG) p3 );
      hb_vmSend( 3 );
      /* res = hb_parnl( -1 ); */
   }
}

static HB_LONG ToKey(HB_LONG a,HB_LONG b)
{

if ( a == GDK_KEY_asciitilde || a == GDK_KEY_dead_tilde)
{
   if ( b== GDK_KEY_A)
      return (HB_LONG)GDK_KEY_Atilde;
   else if ( b == GDK_KEY_a )
      return (HB_LONG)GDK_KEY_atilde;
   else if ( b== GDK_KEY_N)
      return (HB_LONG)GDK_KEY_Ntilde;
   else if ( b == GDK_KEY_n )
      return (HB_LONG)GDK_KEY_ntilde;
   else if ( b== GDK_KEY_O)
      return (HB_LONG)GDK_KEY_Otilde;
   else if ( b == GDK_KEY_o )
      return (HB_LONG)GDK_KEY_otilde;
}
if  ( a == GDK_KEY_asciicircum || a ==GDK_KEY_dead_circumflex)
{
   if ( b== GDK_KEY_A)
      return (HB_LONG)GDK_KEY_Acircumflex;
   else if ( b == GDK_KEY_a )
      return (HB_LONG)GDK_KEY_acircumflex;
   else if ( b== GDK_KEY_E)
      return (HB_LONG)GDK_KEY_Ecircumflex;
   else if ( b == GDK_KEY_e )
      return (HB_LONG)GDK_KEY_ecircumflex;
   else if ( b== GDK_KEY_I)
      return (HB_LONG)GDK_KEY_Icircumflex;
   else if ( b == GDK_KEY_i )
      return (HB_LONG)GDK_KEY_icircumflex;
   else if ( b== GDK_KEY_O)
      return (HB_LONG)GDK_KEY_Ocircumflex;
   else if ( b == GDK_KEY_o )
      return (HB_LONG)GDK_KEY_ocircumflex;
   else if ( b== GDK_KEY_U)
      return (HB_LONG)GDK_KEY_Ucircumflex;
   else if ( b == GDK_KEY_u )
      return (HB_LONG)GDK_KEY_ucircumflex;
   else if ( b== GDK_KEY_C)
      return (HB_LONG)GDK_KEY_Ccircumflex;
   else if ( b== GDK_KEY_H)
      return (HB_LONG)GDK_KEY_Hcircumflex;
   else if ( b == GDK_KEY_h )
      return (HB_LONG)GDK_KEY_hcircumflex;
   else if ( b== GDK_KEY_J)
      return (HB_LONG)GDK_KEY_Jcircumflex;
   else if ( b == GDK_KEY_j )
      return (HB_LONG)GDK_KEY_jcircumflex;
   else if ( b== GDK_KEY_G)
      return (HB_LONG)GDK_KEY_Gcircumflex;
   else if ( b == GDK_KEY_g )
      return (HB_LONG)GDK_KEY_gcircumflex;
   else if ( b== GDK_KEY_S)
      return (HB_LONG)GDK_KEY_Scircumflex;
   else if ( b == GDK_KEY_s )
      return (HB_LONG)GDK_KEY_scircumflex;
}
	
if ( a == GDK_KEY_grave  || a==GDK_KEY_dead_grave )
{
   if ( b== GDK_KEY_A)
      return (HB_LONG)GDK_KEY_Agrave;
   else if ( b == GDK_KEY_a )
      return (HB_LONG)GDK_KEY_agrave;
   else if ( b== GDK_KEY_E)
      return (HB_LONG)GDK_KEY_Egrave;
   else if ( b == GDK_KEY_e )
      return (HB_LONG)GDK_KEY_egrave;
   else if ( b== GDK_KEY_I)
      return (HB_LONG)GDK_KEY_Igrave;
   else if ( b == GDK_KEY_i )
      return (HB_LONG)GDK_KEY_igrave;
   else if ( b== GDK_KEY_O)
      return (HB_LONG)GDK_KEY_Ograve;
   else if ( b == GDK_KEY_o )
      return (HB_LONG)GDK_KEY_ograve;
   else if ( b== GDK_KEY_U)
      return (HB_LONG)GDK_KEY_Ugrave;
   else if ( b == GDK_KEY_u )
      return (HB_LONG)GDK_KEY_ugrave;
   else if ( b== GDK_KEY_C)
      return (HB_LONG)GDK_KEY_Ccedilla;
   else if ( b == GDK_KEY_c )
      return (HB_LONG)GDK_KEY_ccedilla ;

}

if ( a == GDK_KEY_acute  ||  a == GDK_KEY_dead_acute)
{
  if ( b== GDK_KEY_A)
      return (HB_LONG)GDK_KEY_Aacute;
   else if ( b == GDK_KEY_a )
      return (HB_LONG)GDK_KEY_aacute;
   else if ( b== GDK_KEY_E)
      return (HB_LONG)GDK_KEY_Eacute;
   else if ( b == GDK_KEY_e )
      return (HB_LONG)GDK_KEY_eacute;
   else if ( b== GDK_KEY_I)
      return (HB_LONG)GDK_KEY_Iacute;
   else if ( b == GDK_KEY_i )
      return (HB_LONG)GDK_KEY_iacute;
   else if ( b== GDK_KEY_O)
      return (HB_LONG)GDK_KEY_Oacute;
   else if ( b == GDK_KEY_o )
      return (HB_LONG)GDK_KEY_oacute;
   else if ( b== GDK_KEY_U)
      return (HB_LONG)GDK_KEY_Uacute;
   else if ( b == GDK_KEY_u )
      return (HB_LONG)GDK_KEY_uacute;
   else if ( b== GDK_KEY_Y)
      return (HB_LONG)GDK_KEY_Yacute;
   else if ( b == GDK_KEY_y )
      return (HB_LONG)GDK_KEY_yacute;
   else if ( b== GDK_KEY_C)
      return (HB_LONG)GDK_KEY_Cacute;
   else if ( b == GDK_KEY_c )
      return (HB_LONG)GDK_KEY_cacute;
   else if ( b== GDK_KEY_L)
      return (HB_LONG)GDK_KEY_Lacute;
   else if ( b == GDK_KEY_l )
      return (HB_LONG)GDK_KEY_lacute;
   else if ( b== GDK_KEY_N)
      return (HB_LONG)GDK_KEY_Nacute;
   else if ( b == GDK_KEY_n )
      return (HB_LONG)GDK_KEY_nacute;
   else if ( b== GDK_KEY_R)
      return (HB_LONG)GDK_KEY_Racute;
   else if ( b == GDK_KEY_r )
      return (HB_LONG)GDK_KEY_racute;
   else if ( b== GDK_KEY_S)
      return (HB_LONG)GDK_KEY_Sacute;
   else if ( b == GDK_KEY_s )
      return (HB_LONG)GDK_KEY_sacute;
   else if ( b== GDK_KEY_Z)
      return (HB_LONG)GDK_KEY_Zacute;
   else if ( b == GDK_KEY_z )
      return (HB_LONG)GDK_KEY_zacute;
}
if ( a == GDK_KEY_diaeresis|| a==GDK_KEY_dead_diaeresis)	
{
  if ( b== GDK_KEY_A)
      return (HB_LONG)GDK_KEY_Adiaeresis;
   else if ( b == GDK_KEY_a )
      return (HB_LONG)GDK_KEY_adiaeresis;
   else if ( b== GDK_KEY_E)
      return (HB_LONG)GDK_KEY_Ediaeresis;
   else if ( b == GDK_KEY_e )
      return (HB_LONG)GDK_KEY_ediaeresis;
   else if ( b== GDK_KEY_I)
      return (HB_LONG)GDK_KEY_Idiaeresis;
   else if ( b == GDK_KEY_i )
      return (HB_LONG)GDK_KEY_idiaeresis;
   else if ( b== GDK_KEY_O)
      return (HB_LONG)GDK_KEY_Odiaeresis;
   else if ( b == GDK_KEY_o )
      return (HB_LONG)GDK_KEY_odiaeresis;
   else if ( b== GDK_KEY_U)
      return (HB_LONG)GDK_KEY_Udiaeresis;
   else if ( b == GDK_KEY_u )
      return (HB_LONG)GDK_KEY_udiaeresis;
   else if ( b== GDK_KEY_Y)
      return (HB_LONG)GDK_KEY_Ydiaeresis;
   else if ( b == GDK_KEY_y )
      return (HB_LONG)GDK_KEY_ydiaeresis;       	

}
 return b;

}

static gint cb_event( GtkWidget *widget, GdkEvent * event, gchar* data )
{
   gpointer gObject = g_object_get_data( (GObject*) widget, "obj" );
   HB_LONG lRes;
   //gunichar uchar;
   //gchar* tmpbuf;
   //gchar *res = NULL;

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   //if( !gObject )
   //   gObject = g_object_get_data( (GObject*) (widget->parent->parent), "obj" );
   if( pSym_onEvent && gObject )
   {
      HB_LONG p1, p2, p3;

      if( event->type == GDK_KEY_PRESS || event->type == GDK_KEY_RELEASE )
      {
         /*
         char utf8string[10];
         gunichar uchar;
         int ll;
         uchar= gdk_keyval_to_unicode(((GdkEventKey*)event)->keyval);
         ll = g_unichar_to_utf8( uchar, utf8string );
         utf8string[ll] = '\0';
         g_debug( "keyval: %lu %s", ((GdkEventKey*)event)->keyval, utf8string );
         */
         p1 = (event->type==GDK_KEY_PRESS)? WM_KEYDOWN : WM_KEYUP;
         p2 = ((GdkEventKey*)event)->keyval;

         if ( p2 == GDK_KEY_asciitilde  ||  p2 == GDK_KEY_asciicircum  ||  p2 == GDK_KEY_grave ||  p2 == GDK_KEY_acute ||  p2 == GDK_KEY_diaeresis || p2 == GDK_KEY_dead_acute ||	 p2 ==GDK_KEY_dead_tilde || p2==GDK_KEY_dead_circumflex || p2==GDK_KEY_dead_grave || p2 == GDK_KEY_dead_diaeresis)	
         {
            prevp2 = p2 ;
            p2=-1;
         }
         else
         {
            if ( prevp2 != -1 )
            {
               p2 = ToKey(prevp2,(HB_LONG)p2);
               //uchar= gdk_keyval_to_unicode(p2);
               prevp2=-1;
            }
         }

         //tmpbuf=g_new0(gchar,7);
         //g_unichar_to_utf8( uchar,tmpbuf );
         //res = hwg_convert_to_utf8( tmpbuf );
         //g_free(tmpbuf);	
         p3 = ( ( ((GdkEventKey*)event)->state & GDK_SHIFT_MASK )? 1 : 0 ) |
              ( ( ((GdkEventKey*)event)->state & GDK_CONTROL_MASK )? 2 : 0 ) |
              ( ( ((GdkEventKey*)event)->state & GDK_MOD1_MASK )? 4 : 0 );
      }
      else if( event->type == GDK_SCROLL )
      {
         p1 = WM_KEYDOWN;
         p2 = ( ( (GdkEventScroll*)event )->direction == GDK_SCROLL_DOWN )? 0xFF54 : 0xFF52;
         p3 = 0;
      }
      else if( event->type == GDK_BUTTON_PRESS ||
               event->type == GDK_2BUTTON_PRESS ||
               event->type == GDK_BUTTON_RELEASE )
      {
         if( ((GdkEventButton*)event)->button == 3 )
            p1 = (event->type==GDK_BUTTON_PRESS)? WM_RBUTTONDOWN :
                 ( (event->type==GDK_BUTTON_RELEASE)? WM_RBUTTONUP : WM_LBUTTONDBLCLK );
         else
            p1 = (event->type==GDK_BUTTON_PRESS)? WM_LBUTTONDOWN :
                 ( (event->type==GDK_BUTTON_RELEASE)? WM_LBUTTONUP : WM_LBUTTONDBLCLK );
         p2 = 0;
         p3 = ( ((HB_ULONG)(((GdkEventButton*)event)->x)) & 0xFFFF ) | ( ( ((HB_ULONG)(((GdkEventButton*)event)->y)) << 16 ) & 0xFFFF0000 );
      }
      else if( event->type == GDK_MOTION_NOTIFY )
      {
         p1 = WM_MOUSEMOVE;
         p2 = ( ((GdkEventMotion*)event)->state & GDK_BUTTON1_MASK )? 1:0;
         p3 = ( ((HB_ULONG)(((GdkEventMotion*)event)->x)) & 0xFFFF ) | ( ( ((HB_ULONG)(((GdkEventMotion*)event)->y)) << 16 ) & 0xFFFF0000 );
      }
      else if( event->type == GDK_CONFIGURE )
      {
         GtkAllocation alloc;
         gtk_widget_get_allocation( widget, &alloc );
         p2 = 0;
         if( alloc.width != ((GdkEventConfigure*)event)->width ||
             alloc.height!= ((GdkEventConfigure*)event)->height )
         {
            return 0;
         }
         else
         {
            p1 = WM_MOVE;
            p3 = ( ((GdkEventConfigure*)event)->x & 0xFFFF ) |
                 ( ( ((GdkEventConfigure*)event)->y << 16 ) & 0xFFFF0000 );
         }
      }
      else if( event->type == GDK_LEAVE_NOTIFY ) // event->type == GDK_ENTER_NOTIFY ||
      {
         p1 = WM_MOUSELEAVE;
         p2 = 0;
         //p2 = ( ((GdkEventCrossing*)event)->state & GDK_BUTTON1_MASK )? 1:0 |
         //     ( event->type == GDK_ENTER_NOTIFY )? 0x10:0;
         p3 = ( ((HB_ULONG)(((GdkEventCrossing*)event)->x)) & 0xFFFF ) | ( ( ((HB_ULONG)(((GdkEventMotion*)event)->y)) << 16 ) & 0xFFFF0000 );
      }
      else if( event->type == GDK_ENTER_NOTIFY )
      {
         p1 = WM_MOUSEMOVE;
         p2 = 0;
         p2 = ( ( ((GdkEventCrossing*)event)->state & GDK_BUTTON1_MASK )? 1:0 ) | 0x10;
         p3 = ( ((HB_ULONG)(((GdkEventCrossing*)event)->x)) & 0xFFFF ) | ( ( ((HB_ULONG)(((GdkEventMotion*)event)->y)) << 16 ) & 0xFFFF0000 );
      }
      else if( event->type == GDK_FOCUS_CHANGE )
      {
         p1 = ( ((GdkEventFocus*)event)->in )? WM_SETFOCUS : WM_KILLFOCUS;
         p2 = p3 = 0;
      }
      else if( event->type == GDK_EXPOSE )
      {
         p1 = WM_PAINT;
         p2 = ( ((GdkEventExpose*)event)->area.x & 0xffff ) |
            ( (((GdkEventExpose*)event)->area.y << 16 ) & 0xffff0000 );
         p3 = ( ((GdkEventExpose*)event)->area.width & 0xffff ) |
            ( (((GdkEventExpose*)event)->area.height << 16 ) & 0xffff0000 );
      }
      else
         sscanf( (char*)data,"%ld %ld %ld",&p1,&p2,&p3 );

      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent  ) );
      hb_vmPush( ( PHB_ITEM ) gObject );
      hb_vmPushLong( p1 );
      hb_vmPushLong( p2 );
      hb_vmPushLong( p3 );
      hb_vmSend( 3 );
      lRes = hb_parnl( -1 );
      return lRes;
   }
   return 0;
}

void set_signal( gpointer handle, char * cSignal, long int p1, long int p2, long int p3 )
{
   char buf[25]={0};

   sprintf( buf, "%ld %ld %ld", p1, p2, p3 );
   g_signal_connect( handle, cSignal,
                      G_CALLBACK (cb_signal), g_strdup(buf) );
}

HB_FUNC( HWG_SETSIGNAL )
{
   gpointer p = (gpointer) HB_PARHANDLE(1);
   set_signal( (gpointer)p, (char*)hb_parc(2), hb_parnl(3), hb_parnl(4), ( long int ) HB_PARHANDLE( 5 ) );
}

HB_FUNC( HWG_EMITSIGNAL )
{
   g_signal_emit_by_name( G_OBJECT (HB_PARHANDLE(1)), (char*)hb_parc(2) );
}

void set_event( gpointer handle, char * cSignal, long int p1, long int p2, long int p3 )
{
   char buf[25]={0};

   sprintf( buf, "%ld %ld %ld", p1, p2, p3 );
   g_signal_connect( handle, cSignal,
                      G_CALLBACK (cb_event), g_strdup(buf) );
}

HB_FUNC( HWG_SETEVENT )
{
   gpointer p = (gpointer) HB_PARHANDLE(1);
   set_event( p, (char*)hb_parc(2), hb_parnl(3), hb_parnl(4), hb_parnl(5) );
}

void all_signal_connect( gpointer hWnd )
{
   int i;
   char buf[20]={0};

   for( i=0; i<NUMBER_OF_SIGNALS; i++ )
   {
      sprintf( buf,"%d 0 0",aSignals[i].msg );
      g_signal_connect( hWnd, aSignals[i].cName,
        G_CALLBACK (cb_signal), g_strdup(buf) );
   }
}

GtkWidget * GetActiveWindow( void )
{
   GList * pL = gtk_window_list_toplevels(), * pList;

   pList = pL;
   while( pList )
   {
      if( gtk_window_is_active( pList->data ) )
        break;
      pList = g_list_next( pList );
   }
   if( !pList )
      pList = pL;

   return ( pList )? pList->data : NULL;
}

HB_FUNC( HWG_GETACTIVEWINDOW )
{
   HB_RETHANDLE( GetActiveWindow() );
}

HB_FUNC( HWG_SETWINDOWOBJECT )
{
   SetWindowObject( (GtkWidget *) HB_PARHANDLE(1),hb_param(2,HB_IT_OBJECT) );
}

void SetWindowObject( GtkWidget * hWnd, PHB_ITEM pObject )
{
   gpointer gObject = g_object_get_data( (GObject*) hWnd, "obj" );

   if( gObject )
   {
      hb_itemRelease( ( PHB_ITEM ) gObject );
   }
   if( pObject )
   {
      g_object_set_data( (GObject*) hWnd, "obj", (gpointer) hb_itemNew( pObject ) );
   }
   else
   {
      g_object_set_data( (GObject*) hWnd, "obj", (gpointer) NULL );
   }
}

HB_FUNC( HWG_GETWINDOWOBJECT )
{
   gpointer dwNewLong = g_object_get_data( (GObject*) HB_PARHANDLE(1), "obj" );

   if( dwNewLong )
   {
      hb_itemReturn( ( PHB_ITEM ) dwNewLong );
   }
   else
   {
      hb_ret();
   }
}

HB_FUNC( HWG_SETWINDOWTEXT )
{
   gchar * gcTitle = hwg_convert_to_utf8( hb_parcx(2) );
   gtk_window_set_title( GTK_WINDOW( HB_PARHANDLE(1) ), gcTitle );
   g_free( gcTitle );
}

HB_FUNC( HWG_GETWINDOWTEXT )
{
   char * cTitle = (char*) gtk_window_get_title( GTK_WINDOW( HB_PARHANDLE(1) ) );

   hb_retc( cTitle );
}

HB_FUNC( HWG_ENABLEWINDOW )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE( 1 );
   HB_BOOL lEnable = hb_parl( 2 );
   gtk_widget_set_sensitive( widget, lEnable );
}

HB_FUNC( HWG_ISWINDOWENABLED )
{
   hb_retl( gtk_widget_is_sensitive( (GtkWidget*) HB_PARHANDLE(1) ) );
}

HB_FUNC( HWG_ISICONIC )
{
   hb_retl( 0 );
}

HB_FUNC( HWG_MOVEWINDOW )
{
   GtkWidget * hWnd = (GtkWidget*)HB_PARHANDLE(1);

   if( !HB_ISNIL(2) || !HB_ISNIL(3) )
      gtk_window_move( GTK_WINDOW(hWnd), hb_parni(2), hb_parni(3) );
   if( !HB_ISNIL(4) || !HB_ISNIL(5) )
      gtk_window_resize( GTK_WINDOW(hWnd), hb_parni(4), hb_parni(5) );
}

HB_FUNC( HWG_CENTERWINDOW )
{
   GtkWindow *  hWnd = (GtkWindow*)HB_PARHANDLE(1);

   gint width = 0, height = 0;

   gtk_window_get_size( hWnd, &width, &height );
   gtk_window_move( hWnd, (gdk_screen_width()-width)/2, (gdk_screen_height()-height)/2 );

}

HB_FUNC( HWG_WINDOWMAXIMIZE )
{

   gtk_window_maximize( (GtkWindow*) HB_PARHANDLE(1) );
}

HB_FUNC( HWG_RESTOREWINDOW )
{

   gtk_window_unmaximize( (GtkWindow*) HB_PARHANDLE(1) );
}

HB_FUNC( HWG_WINDOWMINIMIZE )
{

   gtk_window_iconify( (GtkWindow*) HB_PARHANDLE(1) );
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
   GObject * hWnd = (GObject*) HB_PARHANDLE(1);
   gpointer dwNewLong = g_object_get_data( hWnd, "obj" );

   if( dwNewLong )
   {
      hb_itemRelease( ( PHB_ITEM ) dwNewLong );
      g_object_set_data( hWnd, "obj", (gpointer) NULL );
   }
   else
   {
      hb_ret();
   }
}

HB_FUNC( HWG_SETFOCUS )
{
   GObject * hObj = ( GObject * ) HB_PARHANDLE( 1 );
   GtkWidget * handle = gtk_window_get_focus( gtk_window_list_toplevels()->data );

   if( hObj )
   {
      if( g_object_get_data( hObj, "window" ) )
         gtk_window_present( (GtkWindow*) HB_PARHANDLE( 1 ) );
      else
         gtk_widget_grab_focus( (GtkWidget*) HB_PARHANDLE( 1 ) );
   }
   HB_RETHANDLE( handle );
}

HB_FUNC( HWG_GETFOCUS )
{
   HB_RETHANDLE( gtk_window_get_focus( gtk_window_list_toplevels()->data ) );
}

HB_FUNC( HWG_DESTROYWINDOW )
{
    gtk_widget_destroy( (GtkWidget *) HB_PARHANDLE(1) );
}

void hwg_set_modal( GtkWindow * hDlg, GtkWindow * hParent )
{
   gtk_window_set_modal( hDlg, 1 );
   if( hParent )
      gtk_window_set_transient_for( hDlg, hParent );
}

HB_FUNC( HWG_SET_MODAL )
{
   hwg_set_modal( (GtkWindow *) HB_PARHANDLE(1),
         (GtkWindow *) ( ( !HB_ISNIL(2) )? HB_PARHANDLE(2) : NULL ) );
}

HB_FUNC( HWG_WINDOWSETRESIZE )
{
   GtkWindow * handle = (GtkWindow*) HB_PARHANDLE(1);
   gint width = 0, height = 0, bResize = hb_parl(2);

   //if( !bResize )
   {
      gtk_window_get_size( handle, &width, &height );
      gtk_widget_set_size_request( (GtkWidget*)handle, width, height );
   }
   gtk_window_set_resizable( handle, bResize );
}

HB_FUNC( HWG_WINDOWSETDECORATED )
{
   GtkWindow * handle = (GtkWindow*) HB_PARHANDLE(1);
   gtk_window_set_decorated( handle ,hb_parl(2));
}

HB_FUNC( HWG_SETTOPMOST )
{
   gtk_window_set_keep_above( (GtkWindow*) HB_PARHANDLE(1), TRUE );
}

HB_FUNC( HWG_REMOVETOPMOST )
{
   gtk_window_set_keep_above( (GtkWindow*) HB_PARHANDLE(1), FALSE );
}

HB_FUNC( HWG_GETWINDOWPOS )
{
   gint x, y;
   PHB_ITEM aMetr = hb_itemArrayNew( 2 );

   gtk_window_get_position( (GtkWindow*) HB_PARHANDLE(1), &x, &y );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), x );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), y );
   hb_itemRelease( hb_itemReturn( aMetr ) );
}

gchar * hwg_convert_to_utf8( const char * szText )
{
   if( szText ) {
      if( *szAppLocale )
         return g_convert( szText, -1, "UTF-8", szAppLocale, NULL, NULL, NULL );
      else
         return g_locale_to_utf8( szText,-1,NULL,NULL,NULL );
   } else
      return (gchar*) szText;
}

gchar * hwg_convert_from_utf8( const char * szText )
{
   if( szText ) {
      if( *szAppLocale )
         return g_convert( szText, -1, szAppLocale, "UTF-8", NULL, NULL, NULL );
      else
         return g_locale_from_utf8( szText,-1,NULL,NULL,NULL );
   } else
      return (gchar*) szText;
}

HB_FUNC( HWG_SETAPPLOCALE )
{
   const char * szLocale = hb_parc(1);
   int iLen = hb_parclen(1);

   hb_retc( szAppLocale );
   memcpy( szAppLocale, szLocale, iLen );
   szAppLocale[iLen] = '\0';
}

HB_FUNC( HWG_KEYTOUTF8 )
{
   char utf8string[10];
   int iLen;

   iLen = g_unichar_to_utf8( gdk_keyval_to_unicode( hb_parnl(1) ), utf8string );
   utf8string[iLen] = '\0';
   hb_retc( utf8string );
}

HB_FUNC( HWG_SEND_KEY )
{
   gtk_test_widget_send_key ( (GtkWidget*) HB_PARHANDLE(1),
      (guint) hb_parni(2), (GdkModifierType) hb_parni(3) );
}

static gint snooper ( GtkWidget *grab_widget,
         GdkEventKey *event, gpointer func_data )
{
   GtkWidget * window = GetActiveWindow();

   HB_SYMBOL_UNUSED( func_data );
   if( window && event->type == GDK_KEY_RELEASE )
   {
      PHB_ITEM pObject = (PHB_ITEM) g_object_get_data( (GObject*) window, "obj" );
      if( !pSym_keylist )
         pSym_keylist = hb_dynsymFindName( "EVALKEYLIST" );

      if( pObject && pSym_keylist && hb_objHasMessage( pObject, pSym_keylist ) )
      {
         HB_LONG p2;
         hb_vmPushSymbol( hb_dynsymSymbol( pSym_keylist ) );
         hb_vmPush( pObject );
         hb_vmPushLong( ( HB_LONG ) ((GdkEventKey*)event)->keyval );
         p2 = ( ( ((GdkEventKey*)event)->state & GDK_SHIFT_MASK )? 1 : 0 ) |
              ( ( ((GdkEventKey*)event)->state & GDK_CONTROL_MASK )? 2 : 0 ) |
              ( ( ((GdkEventKey*)event)->state & GDK_MOD1_MASK )? 4 : 0 );
         hb_vmPushLong( ( HB_LONG ) p2 );
         hb_vmSend( 2 );
      }
   }

   return FALSE;
}

HB_FUNC( HWG__ISUNICODE )
{
/* Windows */
#if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
#ifdef UNICODE
   hb_retl( 1 );
#else
   hb_retl( 0 );
#endif
#else
/* *NIX */
   hb_retl( 1 );
#endif
}

HB_FUNC( HWG_WIDGET_GET_TOP )
{
   GtkWidget *widget = (GtkWidget*) HB_PARHANDLE(1);
   gint y;

   gdk_window_get_origin( gtk_widget_get_window (widget), NULL, &y );
   hb_retni( y );
}

HB_FUNC( HWG_INITPROC )
{
   s_KeybHook = gtk_key_snooper_install( &snooper, NULL );
}

HB_FUNC( HWG_EXITPROC )
{
   gtk_key_snooper_remove( s_KeybHook );
}

HB_FUNC( HWG_DEICONIFY ) /* maximize  */
{
gtk_window_deiconify(  (GtkWindow*) (HB_PARHANDLE(1) ) );
}

HB_FUNC( HWG_ICONIFY )   /* minimize */
{
gtk_window_iconify(  (GtkWindow*) (HB_PARHANDLE(1) ) );
}

/*
  *  ShellModifyIcon( hWnd,  hIcon )
  * TOOLTIP not supported
  * Comment out for experimental purposes
  */
/*
HB_FUNC( HWG_SHELLMODIFYICON )
{


  PHWGUI_PIXBUF szFile = HB_ISPOINTER(2) ? (PHWGUI_PIXBUF) HB_PARHANDLE(2): NULL;
  if (szFile)
   {
        gtk_window_set_icon( (GtkWindow*) (HB_PARHANDLE(1) ), szFile->handle);
        gtk_window_set_default_icon( szFile->handle );
        gtk_window_iconify(  (GtkWindow*) (HB_PARHANDLE(1) ) );
        gtk_window_deiconify(  (GtkWindow*) (HB_PARHANDLE(1) ) );
   }
}
*/

/* ==================== EOF of window.c ==================== */

