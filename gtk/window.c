/*
 * $Id: window.c,v 1.1 2005-01-12 11:56:34 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level windows functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"
#include "guilib.h"
#include "gtk/gtk.h"

#define WM_KEYDOWN                      256    // 0x0100

extern void writelog( char*s );

void SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue );
PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname );
void SetWindowObject( GtkWidget * hWnd, PHB_ITEM pObject );
void all_signal_connect( gpointer hWnd );
void cb_signal( GtkWidget *widget,gchar* data );

PHB_DYNS pSym_onEvent = NULL;

typedef struct
{
   char * cName;
   int msg;
} HW_SIGNAL, * PHW_SIGNAL;

#define NUMBER_OF_SIGNALS   1
static HW_SIGNAL aSignals[NUMBER_OF_SIGNALS] = { { "destroy",2 } };

#ifndef __XHARBOUR__
#ifdef __EXPORT__
PHB_ITEM hb_stackReturn( void )
{
   HB_STACK stack = hb_GetStack();
   return &stack.Return;
}
#endif
#endif

HB_FUNC( HWG_GTK_INIT )
{
   gtk_set_locale();
   gtk_init( 0,0 );
}

HB_FUNC( HWG_GTK_EXIT )
{
   gtk_main_quit();
}

/*  Creates main application window
    InitMainWindow( szAppName, cTitle, cMenu, hIcon, nBkColor, nStyle, nLeft, nTop, nWidth, nHeight )
*/
HB_FUNC( HWG_INITMAINWINDOW )
{
   GtkWidget * hWnd ;
   GtkWidget *vbox;   
   GtkFixed * box;
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp;
   // char *szAppName = hb_parc(2);
   char *cTitle = hb_parc( 3 );
   // LONG nStyle =  hb_parnl(7);
   // char *cMenu = hb_parc( 4 );
   int x = hb_parnl(8);
   int y = hb_parnl(9);
   int width = hb_parnl(10);
   int height = hb_parnl(11);

   hWnd = ( GtkWidget * ) gtk_window_new( GTK_WINDOW_TOPLEVEL );

   cTitle = g_locale_to_utf8( cTitle,-1,NULL,NULL,NULL );
   gtk_window_set_title( GTK_WINDOW(hWnd), cTitle );
   g_free( cTitle );
   gtk_window_set_default_size( GTK_WINDOW(hWnd), width, height );
   gtk_window_move( GTK_WINDOW(hWnd), x, y );
   
   vbox = gtk_vbox_new (FALSE, 0);
   gtk_container_add (GTK_CONTAINER(hWnd), vbox);
   // gtk_widget_show (vbox);
   
   box = (GtkFixed*)gtk_fixed_new();
   // gtk_container_add( GTK_CONTAINER(hWnd), (GtkWidget*)box );
   gtk_box_pack_end( GTK_BOX(vbox), (GtkWidget*)box, TRUE, TRUE, 2 );
   
   temp = hb_itemPutNL( NULL, (LONG)box );
   SetObjectVar( pObject, "_FBOX", temp );
   hb_itemRelease( temp );  
   
   temp = hb_itemPutNL( NULL, 1 );
   SetObjectVar( pObject, "_NHOLDER", temp );
   hb_itemRelease( temp );
   SetWindowObject( hWnd, pObject );
   all_signal_connect( G_OBJECT (hWnd) );

   hb_retnl( (LONG) hWnd );
}

HB_FUNC( HWG_CREATEDLG )
{
   GtkWidget * hWnd;
   GtkWidget * vbox;   
   GtkFixed  * box;
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp;
   char *cTitle = hb_itemGetCPtr( GetObjectVar( pObject, "TITLE" ) );
   int x = hb_itemGetNI( GetObjectVar( pObject, "NLEFT" ) );
   int y = hb_itemGetNI( GetObjectVar( pObject, "NTOP" ) );
   int width = hb_itemGetNI( GetObjectVar( pObject, "NWIDTH" ) );
   int height = hb_itemGetNI( GetObjectVar( pObject, "NHEIGHT" ) );

   hWnd = ( GtkWidget * ) gtk_window_new( GTK_WINDOW_TOPLEVEL );

   cTitle = g_locale_to_utf8( cTitle,-1,NULL,NULL,NULL );
   gtk_window_set_title( GTK_WINDOW(hWnd), cTitle );
   g_free( cTitle );
   gtk_window_set_default_size( GTK_WINDOW(hWnd), width, height );
   gtk_window_move( GTK_WINDOW(hWnd), x, y );
   
   vbox = gtk_vbox_new (FALSE, 0);
   gtk_container_add (GTK_CONTAINER(hWnd), vbox);
   
   box = (GtkFixed*)gtk_fixed_new();
   gtk_box_pack_end( GTK_BOX(vbox), (GtkWidget*)box, TRUE, TRUE, 2 );
   
   temp = hb_itemPutNL( NULL, (LONG)box );
   SetObjectVar( pObject, "_FBOX", temp );
   hb_itemRelease( temp );  
   
   temp = hb_itemPutNL( NULL, 1 );
   SetObjectVar( pObject, "_NHOLDER", temp );
   hb_itemRelease( temp );
   SetWindowObject( hWnd, pObject );
   all_signal_connect( G_OBJECT (hWnd) );

   hb_retnl( (LONG) hWnd );

}

/*
 *  HWG_ACTIVATEMAINWINDOW( lShow, hAccel, lMaximize ) 
 */
HB_FUNC( HWG_ACTIVATEMAINWINDOW )
{
   // HACCEL hAcceler = ( ISNIL(2) )? NULL : (HACCEL) hb_parnl(2);

   gtk_widget_show_all( (GtkWidget*) hb_parnl(1) );
   gtk_main();
}

HB_FUNC( HWG_ACTIVATEDIALOG )
{
   gtk_widget_show_all( (GtkWidget*) hb_parnl(1) );
   // gtk_dialog_run( (GtkDialog*) hb_parnl(1) );
   gtk_main();
}

void cb_signal( GtkWidget *widget,gchar* data )
{
   gpointer gObject;
   LONG p1, p2, p3;

   // writelog( "cb_signal-0" );
   // writelog( (char*)data );
   sscanf( (char*)data,"%ld %ld %ld",&p1,&p2,&p3 );
   if( !p1 )
   {
      p1 = 273;
      widget = (GtkWidget*) p3;
      p3 = 0;
   }
   
   gObject = g_object_get_data( (GObject*) widget, "obj" );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && gObject )
   {
      PHB_ITEM pObject = hb_itemNew( NULL );
      
      pObject->type = HB_IT_OBJECT;
      pObject->item.asArray.value = (PHB_BASEARRAY) gObject;
      pObject->item.asArray.value->ulHolders++;

      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( p1 );
      hb_vmPushLong( p2 );
      hb_vmPushLong( p3 );
      hb_vmSend( 3 );
      // res = hb_itemGetNL( (PHB_ITEM) hb_stackReturn() );
      hb_itemRelease( pObject );
   }
}

static gint cb_event( GtkWidget *widget, GdkEventKey * event, gchar* data )
{
   gpointer gObject = g_object_get_data( (GObject*) widget, "obj" );
   LONG lRes;

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && gObject )
   {
      PHB_ITEM pObject = hb_itemNew( NULL );
      LONG p1, p2, p3;
      
      if( event->type == GDK_KEY_PRESS )
      {
         p1 = WM_KEYDOWN;
	 p2 = event->keyval;
	 p3 = ( ( event->state & GDK_SHIFT_MASK )? 1 : 0 ) |
	      ( ( event->state & GDK_CONTROL_MASK )? 2 : 0 ) |
	      ( ( event->state & GDK_MOD1_MASK )? 4 : 0 );
      }
      else
         sscanf( (char*)data,"%ld %ld %ld",&p1,&p2,&p3 );
      
      pObject->type = HB_IT_OBJECT;
      pObject->item.asArray.value = (PHB_BASEARRAY) gObject;
      pObject->item.asArray.value->ulHolders++;

      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( p1 );
      hb_vmPushLong( p2 );
      hb_vmPushLong( p3 );
      hb_vmSend( 3 );
      lRes = hb_itemGetNL( (PHB_ITEM) hb_stackReturn() );
      hb_itemRelease( pObject );
      return lRes;
   }
   return 0;
}

void all_signal_connect( gpointer hWnd )
{
   int i;
   char buf[20];

   // writelog( "all_signal-connect-0" );
   for( i=0; i<NUMBER_OF_SIGNALS; i++ )
   {
      sprintf( buf,"%d 0 0",aSignals[i].msg );
      // writelog(buf);
      g_signal_connect( hWnd, aSignals[i].cName,
        G_CALLBACK (cb_signal), g_strdup(buf) );
   }
}

HB_FUNC( HWG_SETSIGNAL )
{
   char buf[25];
   
   sprintf( buf,"%ld %ld %ld",hb_parnl(3),hb_parnl(4),hb_parnl(5) );   
   g_signal_connect( (gpointer)hb_parnl(1), hb_parc(2),
                      G_CALLBACK (cb_signal), g_strdup(buf) );

}

HB_FUNC( HWG_SETEVENT )
{
   char buf[25];
   
   sprintf( buf,"%ld %ld %ld",hb_parnl(3),hb_parnl(4),hb_parnl(5) );   
   g_signal_connect( (gpointer)hb_parnl(1), hb_parc(2),
                      G_CALLBACK (cb_event), g_strdup(buf) );
}

GtkWidget * GetActiveWindow( void )
{
   return gtk_window_list_toplevels()->data;
}

HB_FUNC( GETACTIVEWINDOW )
{
   hb_retnl( (LONG) GetActiveWindow() );
}

HB_FUNC( SETWINDOWOBJECT )
{
   SetWindowObject( (GtkWidget *) hb_parnl(1),hb_param(2,HB_IT_OBJECT) );
}

void SetWindowObject( GtkWidget * hWnd, PHB_ITEM pObject )
{
   if( pObject )
   {
      // Must increase uiHolders as we now have additional copy of object.
      #ifndef UIHOLDERS
      pObject->item.asArray.value->ulHolders++;
      #else
      pObject->item.asArray.value->uiHolders++;
      #endif
      g_object_set_data( (GObject*) hWnd, "obj", (gpointer) (pObject->item.asArray.value) );
   }
   else
   {
      g_object_set_data( (GObject*) hWnd, "obj", (gpointer) NULL );
   }
}

HB_FUNC( GETWINDOWOBJECT )
{
   gpointer dwNewLong = g_object_get_data( (GObject*) hb_parnl(1), "obj" );

   if( dwNewLong )
   {
      PHB_ITEM pObj = hb_itemNew( NULL );

      pObj->type = HB_IT_OBJECT;
      pObj->item.asArray.value = (PHB_BASEARRAY) dwNewLong;

      // Must increase uiHolders as we will shortly release this unaccounted copy.
      #ifndef UIHOLDERS
      pObj->item.asArray.value->ulHolders++;
      #else
      pObj->item.asArray.value->uiHolders++;
      #endif

      hb_itemReturn( pObj );
      hb_itemRelease( pObj );
   }
}

HB_FUNC( SETWINDOWTEXT )
{
   char * cTitle = g_locale_to_utf8( hb_parc(2),-1,NULL,NULL,NULL );
   gtk_window_set_title( GTK_WINDOW( hb_parnl(1) ), cTitle );
   g_free( cTitle );
}

HB_FUNC( GETWINDOWTEXT )
{
   /*
   GtkWidget *  hWnd = (GtkWidget *) hb_parnl( 1 );

   USHORT iLen = (USHORT)SendMessage( hWnd, WM_GETTEXTLENGTH, 0, 0 );
   char *cText = (char*) hb_xgrab( iLen+2 );

   iLen = (USHORT)SendMessage( hWnd, WM_GETTEXT, (WPARAM)(iLen+1), (LPARAM)cText );
   if( iLen > 0 )
      hb_retc( cText );
   else
      hb_retc( "" );
   hb_xfree( cText );
   */
}

HB_FUNC( MOVEWINDOW )
{
   GtkWidget * hWnd = (GtkWidget*)hb_parnl(1);
   
   gtk_window_move( GTK_WINDOW(hWnd), hb_parni(2), hb_parni(3) );
   gtk_window_resize( GTK_WINDOW(hWnd), hb_parni(4), hb_parni(5) );
}

PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname )
{
   PHB_DYNS pMsg = hb_dynsymGet( varname );

   if( pMsg )
   {
      hb_vmPushSymbol( pMsg->pSymbol );   /* Push message symbol */
      hb_vmPush( pObject );               /* Push object */

      hb_vmDo( 0 );
   }
   return ( hb_stackReturn() );
}

void SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue )
{
   PHB_DYNS pMsg = hb_dynsymGet( varname );

   if( pMsg )
   {
      hb_vmPushSymbol( pMsg->pSymbol );   /* Push message symbol */
      hb_vmPush( pObject );               /* Push object */
      hb_vmPush( pValue );                /* Push value */

      hb_vmDo( 1 );
   }
}

HB_FUNC( HWG_DECREASEHOLDERS )
{
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );

   #ifndef  UIHOLDERS
   if( pObject->item.asArray.value->ulHolders )
      pObject->item.asArray.value->ulHolders--;
   #else
   if( pObject->item.asArray.value->uiHolders )
      pObject->item.asArray.value->uiHolders--;
   #endif
}

HB_FUNC( SETFOCUS )
{
   gtk_widget_grab_focus( (GtkWidget*) hb_parnl( 1 ) );
}

HB_FUNC( GETFOCUS )
{
   GtkWidget * hCtrl;
   hCtrl = gtk_window_get_focus( gtk_window_list_toplevels()->data );
}

HB_FUNC( HWG_DESTROYWINDOW )
{
    gtk_widget_destroy( (GtkWidget *) hb_parnl(1) );
}

HB_FUNC( HWG_SET_MODAL )
{
   gtk_window_set_modal( (GtkWindow *) hb_parnl(1), 1 );
   gtk_window_set_transient_for( (GtkWindow *) hb_parnl(1), (GtkWindow *) hb_parnl(2) );
}
