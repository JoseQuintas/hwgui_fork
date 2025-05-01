/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Widget creation functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * StatusBar /ProgressBar and monthCalendar Functions
 *
 * Copyright 2008 Luiz Rafael Culik Guimaraes <luiz at xharbour.com.br >
 * www - http://sites.uol.com.br/culikr/

*/

#include "guilib.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"

#include <cairo.h>
// #include "gtk/gtk.h"
#include <gtk/gtk.h>

#include "hwgtk.h"
#include "hbdate.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif
/* Avoid warnings from GCC */
#include "warnings.h"

#define SS_CENTER           1
#define SS_RIGHT            2
#define ES_PASSWORD 32
#define ES_MULTILINE        4
#define ES_READONLY      2048
#define ES_CENTER           1
#define ES_RIGHT            2

#define BS_AUTO3STATE       6
#define BS_GROUPBOX         7
#define BS_AUTORADIOBUTTON  9

#define TCS_BOTTOM          2

#define SS_OWNERDRAW        13

#define WM_PAINT            15
#define WM_HSCROLL         276
#define WM_VSCROLL         277
#define WM_USER           1024
#define WS_EX_TRANSPARENT   32

extern PHB_ITEM GetObjectVar( PHB_ITEM pObject, char *varname );
extern void SetObjectVar( PHB_ITEM pObject, char *varname, PHB_ITEM pValue );
extern void SetWindowObject( GtkWidget * hWnd, PHB_ITEM pObject );
extern void set_signal( gpointer handle, char *cSignal, long int p1,
      long int p2, long int p3 );
extern void set_event( gpointer handle, char *cSignal, long int p1,
      long int p2, long int p3 );
extern void cb_signal( GtkWidget * widget, gchar * data );
extern gint cb_signal_size( GtkWidget *widget, GtkAllocation *allocation, gpointer data );
extern void all_signal_connect( gpointer hWnd );
extern GtkWidget *GetActiveWindow( void );
extern GdkPixbuf *alpha2pixbuf( GdkPixbuf * hPixIn, long int nColor );

static PHB_DYNS pSymTimerProc = NULL;

static PHB_DYNS pSym_onEvent = NULL;

static GtkWidget *h4stock = NULL;

GtkFixed *getFixedBox( GObject * handle )
{
   return ( GtkFixed * ) g_object_get_data( handle, "fbox" );
}

void hwg_colorN2C( unsigned int lColor, char *szColor )
{
   char c;
   sprintf( szColor, "%06x", lColor );
   c = szColor[0]; szColor[0] = szColor[4]; szColor[4] = c;
   c = szColor[1]; szColor[1] = szColor[5]; szColor[5] = c;
}

#if GTK_MAJOR_VERSION -0 > 2
void set_css_data( char *szData )
{
   GtkCssProvider* provider = gtk_css_provider_new();
   GdkDisplay* display = gdk_display_get_default();
   GdkScreen* screen = gdk_display_get_default_screen(display);

   gtk_style_context_add_provider_for_screen(screen,
      GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

   gtk_css_provider_load_from_data(GTK_CSS_PROVIDER(provider), szData, -1, NULL);
   g_object_unref(provider);

}
#endif

GtkWidget *getDrawing( GObject * handle )
{
   return ( GtkWidget * ) g_object_get_data( handle, "draw" );
}

HB_FUNC( HWG_GETDRAWING )
{
   HB_RETHANDLE( getDrawing( (GObject *)HB_PARHANDLE(1) ) );
}

HB_FUNC( HWG_STOCKBITMAP )
{
   PHWGUI_PIXBUF hpix;
   GdkPixbuf * handle;

   if( !h4stock )
      h4stock = gtk_drawing_area_new();

   handle = gtk_widget_render_icon( h4stock, hb_parc(1),
        ( ( HB_ISNIL(2) ) ? GTK_ICON_SIZE_BUTTON : hb_parni(2)), NULL );
   if( handle )
   {
      hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
      hpix->type = HWGUI_OBJECT_PIXBUF;
      hpix->handle = handle;
      hpix->trcolor = -1;
      HB_RETHANDLE( hpix );
   }
}


/*
   CreateStatic( hParentWindow, nControlID, nStyle, x, y, nWidth, nHeight, nExtStyle, cTitle )
*/
HB_FUNC( HWG_CREATESTATIC )
{
   HB_ULONG ulStyle = hb_parnl( 3 );
   const char *cTitle = ( hb_pcount(  ) > 8 ) ? hb_parc( 9 ) : "";
   GtkWidget *hCtrl, *hLabel;
   GtkFixed *box;
   HB_ULONG ulExtStyle = hb_parnl( 8 );

   if( ( ulStyle & SS_OWNERDRAW ) == SS_OWNERDRAW )
   {
      hCtrl = gtk_drawing_area_new();
      g_object_set_data( ( GObject * ) hCtrl, "draw", ( gpointer ) hCtrl );
   }
   else
   {
      gchar *gcTitle = hwg_convert_to_utf8( cTitle );
      hCtrl = gtk_event_box_new(  );
      hLabel = gtk_label_new( gcTitle );
      g_free( gcTitle );
      gtk_container_add( GTK_CONTAINER( hCtrl ), hLabel );
      g_object_set_data( ( GObject * ) hCtrl, "label", ( gpointer ) hLabel );
      if( ulExtStyle & WS_EX_TRANSPARENT )
      {
         gtk_event_box_set_visible_window( GTK_EVENT_BOX( hCtrl ), 0 );
      }

      if( !( ulStyle & SS_CENTER ) )
         gtk_misc_set_alignment( GTK_MISC( hLabel ),
               ( ulStyle & SS_RIGHT ) ? 1 : 0, 0 );
   }
   box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );
   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

   if( ( ulStyle & SS_OWNERDRAW ) == SS_OWNERDRAW )
   {
#if GTK_MAJOR_VERSION -0 < 3
      set_event( ( gpointer ) hCtrl, "expose_event", WM_PAINT, 0, 0 );
#else
      set_event( ( gpointer ) hCtrl, "draw", WM_PAINT, 0, 0 );
#endif
   }
   HB_RETHANDLE( hCtrl );

}

HB_FUNC( HWG_STATIC_SETTEXT )
{
   gchar *gcTitle = hwg_convert_to_utf8( hb_parcx( 2 ) );
   GtkLabel *hLabel =
         ( GtkLabel * ) g_object_get_data( ( GObject * ) HB_PARHANDLE( 1 ),
         "label" );
   gtk_label_set_text( hLabel, gcTitle );
   g_free( gcTitle );
}

HB_FUNC( HWG_STATIC_GETTEXT )
{

   hb_retc( (char*) gtk_label_get_text( g_object_get_data( ( GObject * ) HB_PARHANDLE( 1 ),
         "label" ) ) );
}

/*
   hwg_CreateButton( hParentWindow, nButtonID, nStyle, x, y, nWidth, nHeight,
                 cCaption , hpixbuf )
*/
HB_FUNC( HWG_CREATEBUTTON )
{
   GtkWidget *hCtrl;
   HB_ULONG ulStyle = hb_parnl( 3 );
   const char *cTitle = ( hb_pcount(  ) > 7 ) ? hb_parc( 8 ) : "";
   GtkFixed *box;
   PHWGUI_PIXBUF hImg =
         HB_ISPOINTER( 9 ) ? ( PHWGUI_PIXBUF ) HB_PARHANDLE( 9 ) : NULL;
   gchar *gcTitle = hwg_convert_to_utf8( cTitle );

   if( ( ulStyle & 0xf ) == BS_AUTORADIOBUTTON )
   {
      GSList *group = ( GSList * ) HB_PARHANDLE( 2 );
      hCtrl = gtk_radio_button_new_with_label( group, gcTitle );
      group = gtk_radio_button_get_group( ( GtkRadioButton * ) hCtrl );
      HB_STOREHANDLE( group, 2 );
   }
   else if( ( ulStyle & 0xf ) == BS_AUTO3STATE )
      hCtrl = gtk_check_button_new_with_label( gcTitle );
   else if( ( ulStyle & 0xf ) == BS_GROUPBOX )
      hCtrl = gtk_frame_new( gcTitle );
   else
      hCtrl = gtk_button_new_with_mnemonic( gcTitle );

//#if GTK_CHECK_VERSION(2,4,1)
   if( hImg )
   {
      GtkSettings *default_settings = gtk_settings_get_default();
      g_object_set(default_settings, "gtk-button-images", TRUE, NULL);
      gtk_button_set_image( GTK_BUTTON( hCtrl ), gtk_image_new_from_pixbuf( hImg->handle ) );
   }
//#endif
   g_free( gcTitle );
   box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );
   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

   HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_BUTTON_SETIMAGE )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   PHWGUI_PIXBUF hImg =
         HB_ISPOINTER( 2 ) ? ( PHWGUI_PIXBUF ) HB_PARHANDLE( 2 ) : NULL;

   if( hImg )
   {
      GtkSettings *default_settings = gtk_settings_get_default();
      g_object_set(default_settings, "gtk-button-images", TRUE, NULL);
      gtk_button_set_image( GTK_BUTTON( hCtrl ), gtk_image_new_from_pixbuf( hImg->handle ) );
   }
}


HB_FUNC( HWG_BUTTON_SETTEXT )
{
   gchar *gcTitle = hwg_convert_to_utf8( hb_parcx( 2 ) );
   GtkWidget *hBtn = ( GtkWidget * ) HB_PARHANDLE( 1 );

   gtk_button_set_label( (GtkButton *) hBtn, gcTitle );
   g_free( gcTitle );
}

HB_FUNC( HWG_BUTTON_GETTEXT )
{

   hb_retc( (char*) gtk_button_get_label( (GtkButton *) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_CHECKBUTTON )
{
   gtk_toggle_button_set_active( ( GtkToggleButton * ) HB_PARHANDLE( 1 ),
         hb_parl( 2 ) );
}

HB_FUNC( HWG_ISBUTTONCHECKED )
{
   hb_retl( gtk_toggle_button_get_active( ( GtkToggleButton * )
               HB_PARHANDLE( 1 ) ) );
}

/*
   CreateEdit( hParentWIndow, nEditControlID, nStyle, x, y, nWidth, nHeight,
               cInitialString )
*/
HB_FUNC( HWG_CREATEEDIT )
{
   GtkWidget *hCtrl;
   const char *cTitle = ( hb_pcount(  ) > 7 ) ? hb_parc( 8 ) : "";
   unsigned long ulStyle = ( HB_ISNIL( 3 ) ) ? 0 : hb_parnl( 3 );

   if( ulStyle & ES_MULTILINE )
   {
      hCtrl = gtk_text_view_new(  );
      g_object_set_data( ( GObject * ) hCtrl, "multi", ( gpointer ) 1 );
      if( ulStyle & ES_READONLY )
         gtk_text_view_set_editable( ( GtkTextView * ) hCtrl, 0 );
      gtk_text_view_set_wrap_mode( GTK_TEXT_VIEW(hCtrl), GTK_WRAP_WORD_CHAR);
   }
   else
   {
      hCtrl = gtk_entry_new(  );
      if( ulStyle & ES_PASSWORD )
         gtk_entry_set_visibility( ( GtkEntry * ) hCtrl, FALSE );
      if( ulStyle & ES_RIGHT )
         gtk_entry_set_alignment( ( GtkEntry * ) hCtrl, 1 );
   }

   GtkFixed *box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );
   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

   if( *cTitle )
   {
      gchar *gcTitle = hwg_convert_to_utf8( cTitle );
      if( ulStyle & ES_MULTILINE )
      {
         GtkTextBuffer *buffer =
               gtk_text_view_get_buffer( GTK_TEXT_VIEW( hCtrl ) );
         gtk_text_buffer_set_text( buffer, gcTitle, -1 );
      }
      else
         gtk_entry_set_text( ( GtkEntry * ) hCtrl, gcTitle );
      g_free( gcTitle );
   }

   gtk_widget_add_events( hCtrl, GDK_BUTTON_PRESS_MASK | GDK_BUTTON_RELEASE_MASK );
   set_event( ( gpointer ) hCtrl, "button_press_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "button_release_event", 0, 0, 0 );

   all_signal_connect( ( gpointer ) hCtrl );
   HB_RETHANDLE( hCtrl );

}

HB_FUNC( HWG_EDIT_SETTEXT )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   gchar *gcTitle = hwg_convert_to_utf8( hb_parcx( 2 ) );

   if( g_object_get_data( ( GObject * ) hCtrl, "multi" ) )
   {
      GtkTextBuffer *buffer =
            gtk_text_view_get_buffer( GTK_TEXT_VIEW( hCtrl ) );
      gtk_text_buffer_set_text( buffer, gcTitle, -1 );
   }
   else
      gtk_entry_set_text( ( GtkEntry * ) hCtrl, gcTitle );
   g_free( gcTitle );
}

HB_FUNC( HWG_EDIT_GETTEXT )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   char *cptr;

   if( g_object_get_data( ( GObject * ) hCtrl, "multi" ) )
   {
      GtkTextBuffer *buffer =
            gtk_text_view_get_buffer( GTK_TEXT_VIEW( hCtrl ) );
      GtkTextIter iterStart, iterEnd;

      gtk_text_buffer_get_start_iter( buffer, &iterStart );
      gtk_text_buffer_get_end_iter( buffer, &iterEnd );
      cptr = gtk_text_buffer_get_text( buffer, &iterStart, &iterEnd, 1 );
   }
   else
      cptr = ( char * ) gtk_entry_get_text( ( GtkEntry * ) hCtrl );

   if( *cptr )
   {
      cptr = hwg_convert_from_utf8( cptr );
      hb_retc( cptr );
      g_free( cptr );
   }
   else
      hb_retc( "" );
}

HB_FUNC( HWG_EDIT_SETPOS )
{
   gtk_editable_set_position( ( GtkEditable * ) HB_PARHANDLE( 1 ),
         hb_parni( 2 ) - 1 );
}

HB_FUNC( HWG_EDIT_GETPOS )
{
   hb_retni( gtk_editable_get_position( ( GtkEditable * ) HB_PARHANDLE( 1 ) ) + 1 );
}

HB_FUNC( HWG_EDIT_GETSELPOS )
{
   gint start, end;
   if( gtk_editable_get_selection_bounds( ( (GtkEditable *) HB_PARHANDLE( 1 ) ),
         &start, &end ) )
   {
      PHB_ITEM aSel = hb_itemArrayNew( 2 );
      PHB_ITEM temp;

      temp = hb_itemPutNL( NULL, start );
      hb_itemArrayPut( aSel, 1, temp );
      hb_itemRelease( temp );

      temp = hb_itemPutNL( NULL, end );
      hb_itemArrayPut( aSel, 2, temp );
      hb_itemRelease( temp );

      hb_itemReturn( aSel );
      hb_itemRelease( aSel );
   }
}

HB_FUNC( HWG_EDIT_SET_OVERMODE )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   gboolean bOver;

   if( g_object_get_data( ( GObject * ) hCtrl, "multi" ) )
   {
     bOver = gtk_text_view_get_overwrite( ( (GtkTextView *) hCtrl ) );
     if( !( HB_ISNIL(2) ) )
        gtk_text_view_set_overwrite( ( (GtkTextView *) hCtrl ), hb_parl(2) );
   }
   else
   {
     bOver = gtk_entry_get_overwrite_mode( ( (GtkEntry *) hCtrl ) );
     if( !( HB_ISNIL(2) ) )
        gtk_entry_set_overwrite_mode( ( (GtkEntry *) hCtrl ), hb_parl(2) );
   }
   hb_retl( bOver );
}

/*
   CreateCombo( hParentWIndow, nComboID, nStyle, x, y, nWidth, nHeight )
*/
HB_FUNC( HWG_CREATECOMBO )
{
   GtkWidget *hCtrl;
   gint iText = ((hb_parni(3) & 1) == 0);
   GtkFixed *box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );

#if GTK_MAJOR_VERSION -0 < 3
   hCtrl = gtk_combo_box_entry_new_text();
#else
   hCtrl = gtk_combo_box_text_new_with_entry();
#endif
   if( !iText )
   {
      gtk_editable_set_editable( (GtkEditable*)gtk_bin_get_child((GtkBin*)hCtrl), FALSE );
      //hCtrl = gtk_combo_box_new_text();
   }
   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

   HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_COMBOSETARRAY )
{
   GtkWidget *hCtrl = (GtkWidget *) HB_PARHANDLE( 1 );
   PHB_ITEM pArray = hb_param( 2, HB_IT_ARRAY );
   HB_ULONG ulKol;

   if( pArray )
   {
      HB_ULONG ul, ulLen = hb_arrayLen( pArray );
      char *cItem;

      ulKol = (HB_ULONG) g_object_get_data( ( GObject * ) hCtrl, "kol" );
      for( ul = 1; ul <= ulKol; ++ul )
#if GTK_MAJOR_VERSION -0 < 3
         gtk_combo_box_remove_text( (GtkComboBox *) (hCtrl), 0 );
#else
         gtk_combo_box_text_remove( (GtkComboBox *) (hCtrl), 0 );
#endif
      for( ul = 1; ul <= ulLen; ++ul )
      {
         if( hb_arrayGetType( pArray, ul ) & HB_IT_ARRAY )
            cItem = hwg_convert_to_utf8( hb_arrayGetCPtr( hb_arrayGetItemPtr( pArray, ul ), 1 ) );
         else
            cItem = hwg_convert_to_utf8( hb_arrayGetCPtr( pArray, ul ) );
#if GTK_MAJOR_VERSION -0 < 3
         gtk_combo_box_append_text((GtkComboBox *) (hCtrl), cItem);
#else
         gtk_combo_box_text_append((GtkComboBox *) (hCtrl), NULL, cItem);
#endif
      }
      g_object_set_data( ( GObject * ) hCtrl, "kol", ( gpointer ) ulLen);
   }

}

HB_FUNC( HWG_COMBOSET )
{
   gtk_combo_box_set_active( (GtkComboBox *) HB_PARHANDLE( 1 ), hb_parni(2)-1 );
}

HB_FUNC( HWG_COMBOGET )
{
   gint i = gtk_combo_box_get_active( (GtkComboBox *) HB_PARHANDLE( 1 ) ) + 1;
   if( i <= 0 )
     i = 1;
   hb_retni( i );
}

HB_FUNC( HWG_COMBOPOPUP )
{
  gtk_combo_box_popup( (GtkComboBox *) HB_PARHANDLE( 1 ) );
}

/*
HB_FUNC( HWG_COMBOGETEDIT )
{
   hb_retptr( ( void * ) ( (GTK_ENTRY (GTK_BIN (HB_PARHANDLE( 1 ))->child)) ) );
}
*/

/*
HB_FUNC( HWG_COMBOSETSTRING )
{
   gtk_entry_set_text( GTK_ENTRY (GTK_COMBO( hb_parnl(1) )->entry), hb_parc(2) );
}

HB_FUNC( HWG_COMBOGETSTRING )
{
   gtk_entry_get_text( GTK_ENTRY ( GTK_COMBO( hb_parnl(1) )->entry) );
}
*/

HB_FUNC( HWG_CREATEUPDOWNCONTROL )
{
#if GTK_MAJOR_VERSION -0 < 3
   GtkObject *adj;
#else
   GtkAdjustment *adj;
#endif
   adj = gtk_adjustment_new( ( gdouble ) hb_parnl( 6 ),      // value
         ( gdouble ) hb_parnl( 7 ),     // lower
         ( gdouble ) hb_parnl( 8 ),     // upper
         1, 1, 0 ); //step_increment, page_increment, page_size (0 for disable warning: GtkSpinButton: setting an adjusttment with nom-zero page size is deprecated)
   GtkWidget *hCtrl = gtk_spin_button_new( ( GtkAdjustment * ) adj, 0.5, 0 );

   GtkFixed *box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );
   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 2 ), hb_parni( 3 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 4 ), hb_parni( 5 ) );

   HB_RETHANDLE( hCtrl );

}

HB_FUNC( HWG_SETUPDOWN )
{
   gtk_spin_button_set_value( ( GtkSpinButton * ) HB_PARHANDLE( 1 ),
         ( gdouble ) hb_parnl( 2 ) );
}

HB_FUNC( HWG_GETUPDOWN )
{
   hb_retnl( gtk_spin_button_get_value_as_int( ( GtkSpinButton * )
               HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_SETRANGEUPDOWN )
{
   gtk_spin_button_set_range( ( GtkSpinButton * ) HB_PARHANDLE( 1 ),
         ( gdouble ) hb_parnl( 2 ), ( gdouble ) hb_parnl( 3 ) );
}


#define WS_VSCROLL          2097152     // 0x00200000L
#define WS_HSCROLL          1048576     // 0x00100000L

HB_FUNC( HWG_CREATEBROWSE )
{
   GtkWidget *vbox, *hbox;
   GtkWidget *vscroll, *hscroll;
   GtkWidget *area;
   GtkFixed *box;
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp;
   GObject *handle;
   int nLeft = hb_itemGetNI( GetObjectVar( pObject, "NLEFT" ) );
   int nTop = hb_itemGetNI( GetObjectVar( pObject, "NTOP" ) );
   int nWidth = hb_itemGetNI( GetObjectVar( pObject, "NWIDTH" ) );
   int nHeight = hb_itemGetNI( GetObjectVar( pObject, "NHEIGHT" ) );
   unsigned long int ulStyle =
         hb_itemGetNL( GetObjectVar( pObject, "STYLE" ) );

   temp = GetObjectVar( pObject, "OPARENT" );
   handle = ( GObject * ) HB_GETHANDLE( GetObjectVar( temp, "HANDLE" ) );

   hbox = gtk_hbox_new( FALSE, 0 );
   vbox = gtk_vbox_new( FALSE, 0 );

   area = gtk_drawing_area_new(  );

   gtk_box_pack_start( GTK_BOX( hbox ), vbox, TRUE, TRUE, 0 );
   if( ulStyle & WS_VSCROLL )
   {
#if GTK_MAJOR_VERSION -0 < 3
      GtkObject *adjV;
#else
      GtkAdjustment *adjV;
#endif
      adjV = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
      vscroll = gtk_vscrollbar_new( GTK_ADJUSTMENT( adjV ) );
      gtk_box_pack_end( GTK_BOX( hbox ), vscroll, FALSE, FALSE, 0 );

      temp = HB_PUTHANDLE( NULL, adjV );
      SetObjectVar( pObject, "_HSCROLLV", temp );
      hb_itemRelease( temp );

      SetWindowObject( ( GtkWidget * ) adjV, pObject );
      set_signal( ( gpointer ) adjV, "value_changed", WM_VSCROLL, 0, 0 );
   }

   gtk_box_pack_start( GTK_BOX( vbox ), area, TRUE, TRUE, 0 );
   if( ulStyle & WS_HSCROLL )
   {
#if GTK_MAJOR_VERSION -0 < 3
      GtkObject *adjH;
#else
      GtkAdjustment *adjH;
#endif
      adjH = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
      hscroll = gtk_hscrollbar_new( GTK_ADJUSTMENT( adjH ) );
      gtk_box_pack_end( GTK_BOX( vbox ), hscroll, FALSE, FALSE, 0 );

      temp = HB_PUTHANDLE( NULL, adjH );
      SetObjectVar( pObject, "_HSCROLLH", temp );
      hb_itemRelease( temp );

      SetWindowObject( ( GtkWidget * ) adjH, pObject );
      set_signal( ( gpointer ) adjH, "value_changed", WM_HSCROLL, 0, 0 );
   }

   box = getFixedBox( handle );
   if( box )
      gtk_fixed_put( box, hbox, nLeft, nTop );
   gtk_widget_set_size_request( hbox, nWidth, nHeight );

   temp = HB_PUTHANDLE( NULL, area );
   SetObjectVar( pObject, "_AREA", temp );
   hb_itemRelease( temp );

   SetWindowObject( area, pObject );
#if GTK_MAJOR_VERSION -0 < 3
   set_event( ( gpointer ) area, "expose_event", WM_PAINT, 0, 0 );
#else
   set_event( ( gpointer ) area, "draw", WM_PAINT, 0, 0 );
#endif

   gtk_widget_set_can_focus(area,1);
   //GTK_WIDGET_SET_FLAGS( area, GTK_CAN_FOCUS );

   gtk_widget_add_events( area, GDK_BUTTON_PRESS_MASK |
         GDK_BUTTON_RELEASE_MASK | GDK_KEY_PRESS_MASK | GDK_KEY_RELEASE_MASK |
         GDK_POINTER_MOTION_MASK | GDK_SCROLL_MASK | GDK_FOCUS_CHANGE_MASK);
   set_event( ( gpointer ) area, "button_press_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "button_release_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "motion_notify_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "key_press_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "key_release_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "scroll_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "focus_in_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "focus_out_event", 0, 0, 0 );

   // gtk_widget_show_all( hbox );
   all_signal_connect( ( gpointer ) area );
   g_object_set_data( ( GObject * ) hbox, "draw", ( gpointer ) area );
   HB_RETHANDLE( hbox );
}

HB_FUNC( HWG_GETADJVALUE )
{
   GtkAdjustment *adj = ( GtkAdjustment * ) HB_PARHANDLE( 1 );
   int iOption = ( HB_ISNIL( 2 ) ) ? 0 : hb_parni( 2 );

   if( iOption == 0 )
      hb_retnl( ( HB_LONG ) gtk_adjustment_get_value(adj) );
   else if( iOption == 1 )
      hb_retnl( ( HB_LONG ) gtk_adjustment_get_upper(adj) );
   else if( iOption == 2 )
      hb_retnl( ( HB_LONG ) gtk_adjustment_get_step_increment(adj) );
   else if( iOption == 3 )
      hb_retnl( ( HB_LONG ) gtk_adjustment_get_page_increment(adj) );
   else if( iOption == 4 )
      hb_retnl( ( HB_LONG ) gtk_adjustment_get_page_size(adj) );
   else
      hb_retnl( 0 );
}

/*
 * hwg_SetAdjOptions( hAdj, value, maxpos, step, pagestep, pagesize )
 */
HB_FUNC( HWG_SETADJOPTIONS )
{
   GtkAdjustment *adj = ( GtkAdjustment * ) HB_PARHANDLE( 1 );
   gdouble value;
   int lChanged = 0;

   if( !HB_ISNIL( 2 ) && ( ( value = ( gdouble ) hb_parnl( 2 ) ) != gtk_adjustment_get_value(adj) ) )
   {
      gtk_adjustment_set_value(adj, value);
      lChanged = 1;
   }
   if( !HB_ISNIL( 3 ) && ( ( value = ( gdouble ) hb_parnl( 3 ) ) != gtk_adjustment_get_upper(adj) ) )
   {
      gtk_adjustment_set_upper(adj, value);
      lChanged = 1;
   }
   if( !HB_ISNIL( 4 ) &&
         ( ( value = ( gdouble ) hb_parnl( 4 ) ) != gtk_adjustment_get_step_increment(adj) ) )
   {
      gtk_adjustment_set_step_increment(adj, value);
      lChanged = 1;
   }
   if( !HB_ISNIL( 5 ) &&
         ( ( value = ( gdouble ) hb_parnl( 5 ) ) != gtk_adjustment_get_page_increment(adj) ) )
   {
      gtk_adjustment_set_page_increment(adj, value);
      lChanged = 1;
   }
   if( !HB_ISNIL( 6 ) &&
         ( ( value = ( gdouble ) hb_parnl( 6 ) ) != gtk_adjustment_get_page_size(adj) ) )
   {
      gtk_adjustment_set_page_size(adj, value);
      lChanged = 1;
   }
   //if( lChanged )
    //  gtk_adjustment_changed( adj );
   hb_retl( lChanged );
}

void cb_signal_tab( GtkNotebook *notebook, GtkWidget *page,
      guint page_num, gpointer user_data )
{
   gpointer gObject = g_object_get_data( (GObject*) notebook, "obj" );

   HB_SYMBOL_UNUSED( page );
   HB_SYMBOL_UNUSED( user_data );
   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && gObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( ( PHB_ITEM ) gObject );
      hb_vmPushLong( WM_USER );
      hb_vmPushLong( (HB_LONG) page_num+1 );
      hb_vmPushLong( (HB_LONG) 0 );
      hb_vmSend( 3 );
   }
}

HB_FUNC( HWG_CREATETABCONTROL )
{
   GtkWidget *hCtrl = gtk_notebook_new(  );

   GtkFixed *box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );
   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );
   gtk_notebook_set_scrollable( (GtkNotebook*) hCtrl, 1 );
   if( hb_parni(3) & TCS_BOTTOM )
      gtk_notebook_set_tab_pos( (GtkNotebook*) hCtrl, GTK_POS_BOTTOM );

   g_signal_connect( hCtrl, "switch-page",
                      G_CALLBACK (cb_signal_tab), NULL );

   HB_RETHANDLE( hCtrl );

}


/*
  hwg_AddTab(handle, cLabel, ctooltip)
*/
HB_FUNC( HWG_ADDTAB )
{
   GtkNotebook *nb = ( GtkNotebook * ) HB_PARHANDLE( 1 );
   GtkWidget *box = gtk_fixed_new(  );
   GtkWidget *hLabel;
   char * cLabel = hwg_convert_to_utf8( hb_parc( 2 ) );

   char * cTooltip = ( ( HB_ISNIL(2) ) ? NULL :  hwg_convert_to_utf8(hb_parc(3) ) );

   hLabel = gtk_label_new( cLabel );
   g_free( cLabel );

   gtk_notebook_append_page( nb, box, hLabel );

   g_object_set_data( ( GObject * ) nb, "fbox", ( gpointer ) box );

   /* Tooltip */
   if (cTooltip)
       gtk_widget_set_tooltip_text( (GtkWidget * ) nb, cTooltip );

   HB_RETHANDLE( nb );
}

HB_FUNC( HWG_DELETETAB )
{
   gtk_notebook_remove_page( (GtkNotebook *) HB_PARHANDLE( 1 ),
         hb_parni(2)-1 );
}

HB_FUNC( HWG_SETTABNAME )
{
   GtkNotebook *nb = ( GtkNotebook * ) HB_PARHANDLE( 1 );
   gchar *gcTitle = hwg_convert_to_utf8( hb_parc(3) );

   gtk_notebook_set_tab_label_text( nb,
         gtk_notebook_get_nth_page( nb, hb_parni(2)-1 ), gcTitle );
   g_free( gcTitle );
}

HB_FUNC( HWG_SETCURRENTTAB )
{
   gtk_notebook_set_current_page( (GtkNotebook *) HB_PARHANDLE( 1 ),
         hb_parni(2)-1 );
}

HB_FUNC( HWG_GETCURRENTTAB )
{
   hb_retni( gtk_notebook_get_current_page( ( GtkNotebook * )
               HB_PARHANDLE( 1 ) ) + 1 );
}

HB_FUNC( HWG_CREATESEP )
{
   HB_BOOL lVert = hb_parl( 2 );
   GtkWidget *hCtrl;
   GtkFixed *box;

   if( lVert )
      hCtrl = gtk_vseparator_new(  );
   else
      hCtrl = gtk_hseparator_new(  );
   box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );
   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 3 ), hb_parni( 4 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

   HB_RETHANDLE( hCtrl );
}

/*
   CreatePanel( hParentWindow, nControlID, nStyle, x, y, nWidth, nHeight, nExtStyle, cTitle )
*/
HB_FUNC( HWG_CREATEPANEL )
{
   GtkWidget *vbox, *hbox;
   GtkWidget *vscroll = NULL, *hscroll = NULL;
   GtkWidget *hCtrl;
   GtkFixed *box, *fbox;
   GObject *handle;
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp;
   HB_ULONG ulStyle = hb_parnl( 3 );
   gint nWidth = hb_parnl( 6 ), nHeight = hb_parnl( 7 );

   temp = GetObjectVar( pObject, "OPARENT" );
   handle = ( GObject * ) HB_GETHANDLE( GetObjectVar( temp, "HANDLE" ) );

   fbox = ( GtkFixed * ) gtk_fixed_new(  );

   hbox = gtk_hbox_new( FALSE, 0 );
   vbox = gtk_vbox_new( FALSE, 0 );

   if( ( ulStyle & SS_OWNERDRAW ) == SS_OWNERDRAW )
   {
      hCtrl = gtk_drawing_area_new();
      g_object_set_data( ( GObject * ) hCtrl, "draw", ( gpointer ) hCtrl );
   }
   else
      hCtrl = gtk_toolbar_new();

   gtk_box_pack_start( GTK_BOX( hbox ), vbox, TRUE, TRUE, 0 );
   if( ulStyle & WS_VSCROLL )
   {
#if GTK_MAJOR_VERSION -0 < 3
      GtkObject *adjV;
#else
      GtkAdjustment *adjV;
#endif
      adjV = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
      vscroll = gtk_vscrollbar_new( GTK_ADJUSTMENT( adjV ) );
      gtk_box_pack_end( GTK_BOX( hbox ), vscroll, FALSE, FALSE, 0 );

      temp = HB_PUTHANDLE( NULL, adjV );
      SetObjectVar( pObject, "_HSCROLLV", temp );
      hb_itemRelease( temp );

      SetWindowObject( ( GtkWidget * ) adjV, pObject );
      set_signal( ( gpointer ) adjV, "value_changed", WM_VSCROLL, 0, 0 );
   }

   gtk_box_pack_start( GTK_BOX( vbox ), (GtkWidget*)fbox, TRUE, TRUE, 0 );
   gtk_fixed_put( fbox, hCtrl, 0, 0 );
   if( ulStyle & WS_HSCROLL )
   {
#if GTK_MAJOR_VERSION -0 < 3
      GtkObject *adjH;
#else
      GtkAdjustment *adjH;
#endif
      adjH = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
      hscroll = gtk_hscrollbar_new( GTK_ADJUSTMENT( adjH ) );
      gtk_box_pack_end( GTK_BOX( vbox ), hscroll, FALSE, FALSE, 0 );

      temp = HB_PUTHANDLE( NULL, adjH );
      SetObjectVar( pObject, "_HSCROLLH", temp );
      hb_itemRelease( temp );

      SetWindowObject( ( GtkWidget * ) adjH, pObject );
      set_signal( ( gpointer ) adjH, "value_changed", WM_HSCROLL, 0, 0 );
   }

   box = getFixedBox( handle );
   if( box )
   {
      gtk_fixed_put( box, ( GtkWidget * ) hbox, hb_parni( 4 ), hb_parni( 5 ) );
      gtk_widget_set_size_request( ( GtkWidget * ) hbox, nWidth, nHeight );
      if( vscroll )
         nWidth -= 12;
      if( hscroll )
         nHeight -= 12;
      gtk_widget_set_size_request( hCtrl, nWidth, nHeight );
   }

   g_object_set_data( ( GObject * ) hCtrl, "fbox", ( gpointer ) fbox );

   temp = HB_PUTHANDLE( NULL, hbox );
   SetObjectVar( pObject, "_HBOX", temp );
   hb_itemRelease( temp );

   gtk_widget_set_can_focus(hCtrl,1);
   //GTK_WIDGET_SET_FLAGS( hCtrl, GTK_CAN_FOCUS );
   if( ( ulStyle & SS_OWNERDRAW ) == SS_OWNERDRAW )
#if GTK_MAJOR_VERSION -0 < 3
      set_event( ( gpointer ) hCtrl, "expose_event", WM_PAINT, 0, 0 );
#else
      set_event( ( gpointer ) hCtrl, "draw", WM_PAINT, 0, 0 );
#endif
   gtk_widget_add_events( hCtrl, GDK_BUTTON_PRESS_MASK |
         GDK_BUTTON_RELEASE_MASK | GDK_ENTER_NOTIFY_MASK |
         GDK_LEAVE_NOTIFY_MASK | GDK_POINTER_MOTION_MASK );
   set_event( ( gpointer ) hCtrl, "button_press_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "button_release_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "enter_notify_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "leave_notify_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "motion_notify_event", 0, 0, 0 );
   all_signal_connect( ( gpointer ) hCtrl );

   HB_RETHANDLE( hCtrl );

}

HB_FUNC( HWG_DESTROYPANEL )
{
   GtkFixed *box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );
   if( box )
      gtk_widget_destroy( ( GtkWidget * ) box );
}

/*
   CreateOwnBtn( hParentWindow, nControlID, x, y, nWidth, nHeight )
*/
HB_FUNC( HWG_CREATEOWNBTN )
{
   GtkWidget *hCtrl;
   GtkFixed *box;

   hCtrl = gtk_drawing_area_new();
   g_object_set_data( ( GObject * ) hCtrl, "draw", ( gpointer ) hCtrl );
   box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );

   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 3 ), hb_parni( 4 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );

#if GTK_MAJOR_VERSION -0 < 3
   set_event( ( gpointer ) hCtrl, "expose_event", WM_PAINT, 0, 0 );
#else
   set_event( ( gpointer ) hCtrl, "draw", WM_PAINT, 0, 0 );
#endif
   gtk_widget_set_can_focus(hCtrl,1);
   gtk_widget_add_events( hCtrl, GDK_BUTTON_PRESS_MASK |
         GDK_BUTTON_RELEASE_MASK | GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK );
   set_event( ( gpointer ) hCtrl, "button_press_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "button_release_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "enter_notify_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "leave_notify_event", 0, 0, 0 );
   all_signal_connect( ( gpointer ) hCtrl );

   HB_RETHANDLE( hCtrl );

}


/*
   hwg_AddToolTip(handle,ctext)
*/

HB_FUNC( HWG_ADDTOOLTIP )
{
   gchar *gcTitle = hwg_convert_to_utf8( hb_parcx( 2 ) );


   gtk_widget_set_tooltip_text( ( GtkWidget * ) HB_PARHANDLE( 1 ), gcTitle );

   g_free( gcTitle );
}

HB_FUNC( HWG_DELTOOLTIP )
{

   gtk_widget_set_tooltip_text( ( GtkWidget * ) HB_PARHANDLE( 1 ), NULL );

}

HB_FUNC( HWG_SETTOOLTIPTITLE )
{
   gchar *gcTitle = hwg_convert_to_utf8( hb_parcx( 2 ) );

    gtk_widget_set_tooltip_text( ( GtkWidget * ) HB_PARHANDLE( 1 ), gcTitle );

   g_free( gcTitle );
}

HB_FUNC( HWG_SETTOOLTIPBALLOON )
{
  /* Empty function added by DF7BE
   The tooltip balloon is a nice gimmick of Windows and is not available in GTK.
   For compatible purposes you can set
     hwg_Settooltipballoon(.T.)
   as you like in your app, but the function call has no effect in GTK.
   In GTK, the tooltip is displayed in an rectangle.

  */
}

static gint cb_timer( gchar * data )
{
   HB_LONG p1;

   sscanf( ( char * ) data, "%ld", &p1 );

   if( !pSymTimerProc )
      pSymTimerProc = hb_dynsymFind( "HWG_TIMERPROC" );

   if( pSymTimerProc )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSymTimerProc ) );
      hb_vmPushNil(  );
      hb_vmPushLong( ( HB_LONG ) p1 );
      hb_vmDo( 1 );
      return hb_parnl(-1);
   }
   return 0;
}

/*
 *  HWG_SetTimer( idTimer,i_MilliSeconds ) -> tag
 */

HB_FUNC( HWG_SETTIMER )
{
   char buf[10] = { 0 };
   sprintf( buf, "%ld", hb_parnl( 1 ) );
   hb_retni( ( gint ) g_timeout_add( ( guint32 ) hb_parnl( 2 ),
               (GSourceFunc) cb_timer, g_strdup( buf ) ) );
}

/*
 *  HWG_KillTimer( tag )
 */

HB_FUNC( HWG_KILLTIMER )
{
   //gtk_timeout_remove( ( gint ) hb_parni( 1 ) );
}

HB_FUNC( HWG_GETPARENT )
{
   hb_retptr( ( void * ) gtk_widget_get_parent( ( GtkWidget * ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_LOADCURSOR )
{
   if( HB_ISCHAR( 1 ) )
   {
      // hb_retnl( (HB_LONG) LoadCursor( GetModuleHandle( NULL ), hb_parc( 1 )  ) );
   }
   else
      HB_RETHANDLE( gdk_cursor_new( ( GdkCursorType ) hb_parni( 1 ) ) );
}

/* Added by DF7BE:
       hwg_LoadCursorFromFile(ccurFname,x,y)
*/
HB_FUNC( HWG_LOADCURSORFROMFILE )
{
   GdkPixbuf  *handle;
   GdkPixbuf  *pHandle;
   GdkCursor  *cursor;
   GdkDisplay *display = gdk_display_get_default();

   if( HB_ISCHAR( 1 ) )
   {
      handle = gdk_pixbuf_new_from_file( hb_parc( 1 ), NULL );
      pHandle = alpha2pixbuf( handle, 4095 );   /* 16777215 = 2^24 -1 (old value)  cursor are small */
      /* Returns handle to GdkCursor */
      cursor = gdk_cursor_new_from_pixbuf(display, pHandle, hb_parni( 2 ) , hb_parni( 3 ) );
      /* g_free(pHandle);   core dump with invalid pointer */
      HB_RETHANDLE(cursor);
   }
   else
      HB_RETHANDLE( gdk_cursor_new( ( GdkCursorType ) GDK_ARROW ) );
}

/*
 Hwg_SetCursor(objecthandle , areahandle )
 area : for example return value of Select() in HBROWSE
*/
HB_FUNC( HWG_SETCURSOR )
{
   GtkWidget *widget =
         ( HB_ISPOINTER( 2 ) ) ? ( GtkWidget * ) HB_PARHANDLE( 2 ) :
         GetActiveWindow(  );
   gdk_window_set_cursor( gtk_widget_get_window( widget ), ( GdkCursor * ) HB_PARHANDLE( 1 ) );
}

HB_FUNC( HWG_MOVEWIDGET )
{
   GtkWidget *widget = ( GtkWidget * ) HB_PARHANDLE( 1 );
   GtkWidget *ch_widget = NULL;
   GtkWidget *parent;

   if( !HB_ISNIL( 6 ) && hb_parl( 6 ) )
   {
      ch_widget = widget;
      widget = gtk_widget_get_parent( widget );
   }

   parent = gtk_widget_get_parent( widget );
   if( !HB_ISNIL( 2 ) && !HB_ISNIL( 3 ) )
   {
      gtk_fixed_move( ( GtkFixed * ) ( parent ), widget,
            hb_parni( 2 ), hb_parni( 3 ) );
   }
   if( !HB_ISNIL( 4 ) || !HB_ISNIL( 5 ) )
   {
      gint w, h, w1, h1;
      GtkAllocation alloc;
      gtk_widget_get_allocation( parent, &alloc );
      gtk_widget_get_size_request( widget, &w, &h );
      w1 = ( HB_ISNIL( 4 ) ) ? w : hb_parni( 4 );
      h1 = ( HB_ISNIL( 5 ) ) ? h : hb_parni( 5 );
      if( w1 > alloc.width )
         w1 = alloc.width;
      if( h1 > alloc.height )
         h1 = alloc.height;
      if( w != w1 || h != h1 )
      {
         gtk_widget_set_size_request( widget, w1, h1 );
         if( ch_widget )
            gtk_widget_set_size_request( ch_widget, w1, h1 );
      }
   }
}

HB_FUNC( HWG_CREATEPROGRESSBAR )
{
   GtkWidget *hCtrl;
   GtkFixed *box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );
   hCtrl = gtk_progress_bar_new(  );

   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 3 ), hb_parni( 4 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );
   HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_UPDATEPROGRESSBAR )
{
   // SendMessage( (HWND) hb_parnl(1), PBM_STEPIT, 0, 0 );
   gtk_progress_bar_pulse( ( GtkProgressBar * ) HB_PARHANDLE( 1 ) );
}

HB_FUNC( HWG_SETPROGRESSBAR )
{
   GtkWidget *widget = ( GtkWidget * ) HB_PARHANDLE( 1 );
   gdouble b = ( gdouble ) hb_parnd( 2 );

   //gtk_progress_bar_update( GTK_PROGRESS_BAR( widget ), b );
   gtk_progress_bar_set_fraction( GTK_PROGRESS_BAR( widget ), b );
   while( gtk_events_pending(  ) )
   {
      gtk_main_iteration(  );
   }

}

/* Added by DF7BE:
   Resets an existing progress bar:
   Use this function after creating a
   progress bar after a first use.
 */
HB_FUNC( HWG_RESETPROGRESSBAR )
{
   GtkWidget *widget = ( GtkWidget * ) HB_PARHANDLE( 1 );


    gtk_progress_bar_set_fraction( GTK_PROGRESS_BAR( widget ), 0.0 );
#if GTK_MAJOR_VERSION -0 < 3
    gtk_progress_bar_update( GTK_PROGRESS_BAR( widget ), 0.0 );
#else
    gtk_progress_bar_pulse( GTK_PROGRESS_BAR( widget ) );
#endif
    while( gtk_events_pending(  ) )
   {
      gtk_main_iteration(  );
   }

}

HB_FUNC( HWG_CREATESTATUSWINDOW )
{
   GtkWidget *w, *h;
   GObject *handle = ( GObject * ) HB_PARHANDLE( 1 );
   GtkWidget *vbox = ( GtkWidget * ) g_object_get_data( handle, "vbox" );

   // w  = gtk_statusbar_new() ;
   h = gtk_hseparator_new(  );
   w = gtk_label_new( "" );
   gtk_misc_set_alignment( GTK_MISC( w ), 0, 0 );

   gtk_box_pack_start( GTK_BOX( vbox ), ( GtkWidget * ) h, FALSE, FALSE, 0 );
   gtk_box_pack_start( GTK_BOX( vbox ), ( GtkWidget * ) w, FALSE, FALSE, 0 );

   HB_RETHANDLE( w );
}

HB_FUNC( HWG_WRITESTATUSWINDOW )
{
   char *cText = hwg_convert_to_utf8( hb_parcx( 3 ) );
   GtkWidget *w = ( GtkWidget * ) hb_parptr( 1 );

   //hb_retni( gtk_statusbar_push( GTK_STATUSBAR(w), iStatus, cText ) );
   gtk_label_set_text( (GtkLabel *)w, cText );
   g_free( cText );
}

static void toolbar_clicked( GtkWidget * item, gpointer user_data )
{
   PHB_ITEM pData = ( PHB_ITEM ) user_data;
   hb_vmEvalBlock( ( PHB_ITEM ) pData );
   HB_SYMBOL_UNUSED( item );
}

HB_FUNC( HWG_CREATETOOLBAR )
{
   GtkWidget *hCtrl = gtk_toolbar_new(  );

//   GtkFixed * box = getFixedBox( (GObject*) HB_PARHANDLE(1) );
//   GtkWidget *tmp_image;
//   GtkWidget *toolbutton1;
//   GtkWidget *toolbutton2;
//   gint tmp_toolbar_icon_size;
   GObject *handle = ( GObject * ) HB_PARHANDLE( 1 );
   GtkFixed *box = getFixedBox( handle );
   GtkWidget *vbox = gtk_widget_get_parent( ( GtkWidget * ) box );
   gtk_box_pack_start( GTK_BOX( vbox ), hCtrl, FALSE, FALSE, 0 );
   HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_CREATETOOLBARBUTTON )
{
#if GTK_CHECK_VERSION(2,4,1)
   GtkWidget *toolbutton1, *img;
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   PHWGUI_PIXBUF szFile =
         HB_ISPOINTER( 2 ) ? ( PHWGUI_PIXBUF ) HB_PARHANDLE( 2 ) : NULL;
   const char *szLabel = HB_ISCHAR( 3 ) ? hb_parc( 3 ) : NULL;
   HB_BOOL lSep = hb_parl( 4 );
   gchar *gcLabel = NULL;

   if( szLabel )
   {
      gcLabel = hwg_convert_to_utf8( szLabel );
   }
   if( lSep )
   {
      toolbutton1 = ( GtkWidget * ) gtk_separator_tool_item_new(  );
   }
   else
   {
      if( szFile )
      {
         img = gtk_image_new_from_pixbuf( szFile->handle );
         gtk_widget_show( img );
         toolbutton1 = ( GtkWidget * ) gtk_tool_button_new( img, gcLabel );
      }
      else
      {
         toolbutton1 = ( GtkWidget * ) gtk_tool_button_new( NULL, gcLabel );
      }
      if( gcLabel )
      {
         g_free( gcLabel );
      }
   }
   gtk_widget_show( toolbutton1 );
   gtk_container_add( GTK_CONTAINER( hCtrl ), toolbutton1 );

   HB_RETHANDLE( toolbutton1 );
#endif
}


HB_FUNC( HWG_TOOLBAR_SETACTION )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   PHB_ITEM pItem = hb_itemParam( 2 );
   g_signal_connect( hCtrl, "clicked",
         G_CALLBACK( toolbar_clicked ), ( void * ) pItem );
}

static void tabchange_clicked( GtkNotebook * item,
      GtkWidget * Page, guint pagenum, gpointer user_data )
{
   PHB_ITEM pData = ( PHB_ITEM ) user_data;
   gpointer dwNewLong = g_object_get_data( ( GObject * ) item, "obj" );
   PHB_ITEM pObject = ( PHB_ITEM ) dwNewLong;
   PHB_ITEM Disk = hb_itemPutNL( NULL, pagenum + 1 );

   HB_SYMBOL_UNUSED( Page );
   hb_vmEvalBlockV( ( PHB_ITEM ) pData, 2, pObject, Disk );
   hb_itemRelease( Disk );
}


HB_FUNC( HWG_TAB_SETACTION )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   PHB_ITEM pItem = hb_itemParam( 2 );

   g_signal_connect( hCtrl, "switch-page",
         G_CALLBACK( tabchange_clicked ), ( void * ) pItem );
}

HB_FUNC( HWG_INITMONTHCALENDAR )
{
   GtkWidget *hCtrl;
   GtkFixed *box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );

   hCtrl = gtk_calendar_new(  );

   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 3 ), hb_parni( 4 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );
   HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_SETMONTHCALENDARDATE )
{
   PHB_ITEM pDate = hb_param( 2, HB_IT_DATE );

   if( pDate )
   {
      GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
#ifndef HARBOUR_OLD_VERSION
      int lYear, lMonth, lDay;
#else
      long lYear, lMonth, lDay;
#endif

      hb_dateDecode( hb_itemGetDL( pDate ), &lYear, &lMonth, &lDay );

      lMonth = lMonth - 1;  /* Bugfixung by DF7BE */

      gtk_calendar_select_month( GTK_CALENDAR( hCtrl ), lMonth, lYear );
      gtk_calendar_select_day( GTK_CALENDAR( hCtrl ), lDay );


   }
}

HB_FUNC( HWG_GETMONTHCALENDARDATE )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   char szDate[9];
#ifndef HARBOUR_OLD_VERSION
   int lYear, lMonth, lDay;
#else
   long lYear, lMonth, lDay;
#endif
   gtk_calendar_get_date( GTK_CALENDAR( hCtrl ), ( guint * ) & lYear,
         ( guint * ) & lMonth, ( guint * ) & lDay );

   lMonth = lMonth + 1;

   hb_dateStrPut( szDate, lYear, lMonth, lDay );
   szDate[8] = 0;
   hb_retds( szDate );
}

HB_FUNC( HWG_CREATEIMAGE )
{
   GtkWidget *hCtrl;
   GtkFixed *box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );
   GdkPixbuf *handle = gdk_pixbuf_new_from_file( hb_parc( 2 ), NULL );
   GdkPixbuf *pHandle = alpha2pixbuf( handle, 16777215 );

   hCtrl = gtk_image_new_from_pixbuf( pHandle );

   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 3 ), hb_parni( 4 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 5 ), hb_parni( 6 ) );
   HB_RETHANDLE( hCtrl );
}

HB_FUNC( HWG_MONTHCALENDAR_SETACTION )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   PHB_ITEM pItem = hb_itemParam( 2 );

   g_signal_connect( hCtrl, "day-selected", G_CALLBACK( toolbar_clicked ),
         ( void * ) pItem );
}

void hwg_parse_color( HB_ULONG ncolor, GdkColor * pColor );

#if GTK_MAJOR_VERSION -0 < 3
HB_FUNC( HWG_SETFGCOLOR )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   GtkStateType iType = (HB_ISNIL(3))? GTK_STATE_NORMAL : hb_parni(3);

   GtkWidget *label;
   HB_ULONG hColor = hb_parnl( 2 );
   GdkColor color;

   if( GTK_IS_BUTTON( hCtrl ) )
   {
      label = gtk_bin_get_child( GTK_BIN( hCtrl ) );
   }
   else if( GTK_IS_EVENT_BOX( hCtrl ) )
      label = gtk_bin_get_child( GTK_BIN( hCtrl ) );
   else
   {
      label = hCtrl; //g_object_get_data( ( GObject * ) hCtrl, "label" );
   }

   if( label )
   {
      hwg_parse_color( hColor, &color );
      if( GTK_IS_ENTRY( hCtrl ) )
      {
         GtkStyle * style = gtk_style_copy( gtk_widget_get_style( hCtrl ) );
         hwg_parse_color( hColor, &(style->fg[GTK_STATE_NORMAL]) );
         hwg_parse_color( hColor, &(style->text[GTK_STATE_NORMAL]) );
         gtk_widget_set_style( hCtrl, style );
         //gtk_widget_modify_text( label, iType, &color );
      }
      else
         gtk_widget_modify_fg( label, iType, &color );

   }
}

HB_FUNC( HWG_SETBGCOLOR )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   HB_ULONG hColor = hb_parnl( 2 );
   GdkColor color;

   hwg_parse_color( hColor, &color );
   if( GTK_IS_ENTRY( hCtrl ) )
   {
      GtkStyle * style = gtk_style_copy( gtk_widget_get_style( hCtrl ) );
      hwg_parse_color( hColor, &(style->bg[GTK_STATE_NORMAL]) );
      hwg_parse_color( hColor, &(style->base[GTK_STATE_NORMAL]) );
      gtk_widget_set_style( hCtrl, style );
      //gtk_widget_modify_base( hCtrl, GTK_STATE_NORMAL, &color );
   }
   else
      gtk_widget_modify_bg( hCtrl, GTK_STATE_NORMAL, &color );
}

#else

HB_FUNC( HWG_SETFGCOLOR )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   char szData[128], szColor[8];
   const char *pName = gtk_widget_get_name( hCtrl );

   if( pName && strncmp(pName,"Gtk",3) != 0 )
   {
      hwg_colorN2C( (unsigned int) hb_parni(2), szColor );
      sprintf( szData, "#%s { color: #%s; }", pName, szColor );
      //hwg_writelog( NULL,szData );
      set_css_data( szData );
   }
}

HB_FUNC( HWG_SETBGCOLOR )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   char szData[128], szColor[8];
   const char *pName = gtk_widget_get_name( hCtrl );

   if( pName && strncmp(pName,"Gtk",3) != 0 )
   {
      hwg_colorN2C( (unsigned int) hb_parni( 2 ), szColor );
      sprintf( szData, "#%s { background: #%s; }", pName, szColor );
      //hwg_writelog( NULL,szData );
      set_css_data( szData );
   }
}
#endif

/*
   CreateSplitter( hParentWindow, nControlID, nStyle, x, y, nWidth, nHeight )
*/
HB_FUNC( HWG_CREATESPLITTER )
{
   // HB_ULONG ulStyle = hb_parnl( 3 );
   GtkWidget *hCtrl;
   GtkFixed *box;
   //GtkFixed *fbox = ( GtkFixed * ) gtk_fixed_new(  );

   hCtrl = gtk_drawing_area_new(  );
   g_object_set_data( ( GObject * ) hCtrl, "draw", ( gpointer ) hCtrl );
   box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );

   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );
   /*
   if( box )
   {
      gtk_fixed_put( box, ( GtkWidget * ) fbox, hb_parni( 4 ),
            hb_parni( 5 ) );
      gtk_widget_set_size_request( ( GtkWidget * ) fbox, hb_parni( 6 ),
            hb_parni( 7 ) );
   }
   gtk_fixed_put( fbox, hCtrl, 0, 0 );
   gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );
   g_object_set_data( ( GObject * ) hCtrl, "fbox", ( gpointer ) fbox );
   */
#if GTK_MAJOR_VERSION -0 < 3
   set_event( ( gpointer ) hCtrl, "expose_event", WM_PAINT, 0, 0 );
#else
   set_event( ( gpointer ) hCtrl, "draw", WM_PAINT, 0, 0 );
#endif
   gtk_widget_set_can_focus(hCtrl,1);
   //GTK_WIDGET_SET_FLAGS( hCtrl, GTK_CAN_FOCUS );

   gtk_widget_add_events( hCtrl, GDK_BUTTON_PRESS_MASK |
         GDK_BUTTON_RELEASE_MASK | GDK_POINTER_MOTION_MASK );
   set_event( ( gpointer ) hCtrl, "button_press_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "button_release_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "motion_notify_event", 0, 0, 0 );

   all_signal_connect( ( gpointer ) hCtrl );
   HB_RETHANDLE( hCtrl );

}

/*
   CreateBoard( hParentWindow, nId, nStyle, x, y, nWidth, nHeight )
*/
HB_FUNC( HWG_CREATEBOARD )
{
   GtkWidget *hCtrl;
   GtkFixed *box;

   hCtrl = gtk_drawing_area_new();
   g_object_set_data( ( GObject * ) hCtrl, "draw", ( gpointer ) hCtrl );
   box = getFixedBox( ( GObject * ) HB_PARHANDLE( 1 ) );

   if( box )
      gtk_fixed_put( box, hCtrl, hb_parni( 4 ), hb_parni( 5 ) );
   gtk_widget_set_size_request( hCtrl, hb_parni( 6 ), hb_parni( 7 ) );

#if GTK_MAJOR_VERSION -0 < 3
   set_event( ( gpointer ) hCtrl, "expose_event", WM_PAINT, 0, 0 );
#else
   set_event( ( gpointer ) hCtrl, "draw", WM_PAINT, 0, 0 );
#endif
   gtk_widget_set_can_focus(hCtrl,1);

   gtk_widget_add_events( hCtrl, GDK_BUTTON_PRESS_MASK |
         GDK_BUTTON_RELEASE_MASK | GDK_POINTER_MOTION_MASK | GDK_LEAVE_NOTIFY_MASK |
         GDK_FOCUS_CHANGE_MASK | GDK_KEY_PRESS_MASK | GDK_KEY_RELEASE_MASK | GDK_SCROLL_MASK );
   g_signal_connect( hCtrl, "size-allocate", G_CALLBACK (cb_signal_size), "1" );
   set_event( ( gpointer ) hCtrl, "focus_in_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "focus_out_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "key_press_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "key_release_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "scroll_event", 0, 0, 0 );

   set_event( ( gpointer ) hCtrl, "button_press_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "button_release_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "motion_notify_event", 0, 0, 0 );
   set_event( ( gpointer ) hCtrl, "leave_notify_event", 0, 0, 0 );

   all_signal_connect( ( gpointer ) hCtrl );
   HB_RETHANDLE( hCtrl );

}

HB_FUNC( HWG_CSSLOAD )
{
#if GTK_MAJOR_VERSION -0 > 2
   set_css_data( (char *)hb_parc(1) );
#endif
}

HB_FUNC( HWG_SETWIDGETNAME )
{
   gtk_widget_set_name( ( GtkWidget * ) HB_PARHANDLE( 1 ), hb_parc(2) );
}

/*
 DF7BE : Ticket #64
 hwg_ShowCursor( lcursor , hwindow , ndefaultcsrtype )
*/
HB_FUNC( HWG_SHOWCURSOR )
{

  HB_BOOL modus ;
  int rvalue ;

  GdkCursor *cursor;
  GdkWindow *win;

  /* long csrtype; */

  modus = hb_parl( 1 );

  /* csrtype = ( HB_ISNIL(3) ) ? 0 : hb_parnl(3) ; */


  if (modus)
  /* show cursor */
  {
   cursor = gdk_cursor_new(GDK_ARROW);
  /*
  crashes on LINUX, works best on GTK development environment on Windows
  cursor = gdk_cursor_new(csrtype);
  */

   rvalue = 0;
  }
  else
  {
  /* hide cursor */
   cursor = gdk_cursor_new(GDK_BLANK_CURSOR);
   rvalue = -1;
  }
  win = gtk_widget_get_window( ( GtkWidget * ) HB_PARHANDLE( 2 )  ) ;
  gdk_window_set_cursor( win , cursor);
  hb_retni( rvalue );
}

HB_FUNC( HWG_GETCURSORTYPE )
{
  hb_retnl( (long) gdk_cursor_get_type );
}

/* ====================== EOF of control.c ======================= */
