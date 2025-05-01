/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level menu functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "guilib.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "gtk/gtk.h"
#include "hwgtk.h"

#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

/* Avoid warnings from GCC */
#include "warnings.h"

#define  FLAG_DISABLED   1
#define  FLAG_CHECK      2

extern GtkWidget * aWindows[];
extern void cb_signal( GtkWidget *widget,gchar* data );
extern GtkFixed * getFixedBox( GObject * handle );

/*
 *  CreateMenu() --> hMenu
 */
HB_FUNC( HWG__CREATEMENU )
{
   HB_RETHANDLE( gtk_menu_bar_new() );
}

HB_FUNC( HWG__CREATEPOPUPMENU )
{
   HB_RETHANDLE( gtk_menu_new() );
}

/*
 *  AddMenuItem( hMenu,cCaption,nPos,hWnd,nId,fState,lSubMenu ) --> hMenuItem
 */

HB_FUNC( HWG__ADDMENUITEM )
{
   GtkWidget * hMenu;
   HB_BOOL lString = HB_FALSE, lCheck = HB_FALSE, lStock = FALSE;
   const char * lpNewItem = NULL;

   if( HB_ISCHAR( 2 ) )
   {
      const char * ptr;
      lpNewItem	= hb_parc(2);
      ptr = lpNewItem;
      if( *ptr == '%' )
         lStock = TRUE;
      else
         while( *ptr )
         {
            if( *ptr != ' ' && *ptr != '-' )
            {
               lString = TRUE;
               break;
            }
            ptr ++;
         }
   }
   if( !HB_ISNIL(6) && ( hb_parni(6) & FLAG_CHECK ) )
      lCheck = TRUE;

   if( lCheck )
   {
      gchar * gcptr = hwg_convert_to_utf8( lpNewItem );
      hMenu = gtk_check_menu_item_new_with_mnemonic( gcptr );
      g_free( gcptr );
   }
   else if( lStock )
   {
      hMenu = (GtkWidget *) gtk_image_menu_item_new_from_stock( lpNewItem+1,NULL );
   }
   else if( lString )
   {
      gchar * gcptr = hwg_convert_to_utf8( lpNewItem );
      hMenu = (GtkWidget *) gtk_menu_item_new_with_mnemonic( gcptr );
      g_free( gcptr );
   }
   else
      hMenu = (GtkWidget *) gtk_separator_menu_item_new();

   if( !HB_ISNIL( 7 ) && hb_parl(7) )
   {
      GtkWidget * hSubMenu = gtk_menu_new();
      gtk_menu_item_set_submenu( GTK_MENU_ITEM (hMenu), hSubMenu );
      HB_RETHANDLE( hSubMenu );
   }
   else
   {
      char buf[40]={0};
      sprintf( buf,"0 %ld %ld",hb_parnl(5),( HB_LONG ) HB_PARHANDLE(4) );
      g_signal_connect(G_OBJECT (hMenu), "activate",
          G_CALLBACK (cb_signal), (gpointer) g_strdup (buf));

      HB_RETHANDLE( hMenu );
   }
   gtk_menu_shell_append( GTK_MENU_SHELL( HB_PARHANDLE(1) ), hMenu );

   gtk_widget_show( hMenu );
}

/*
 *  SetMenu( hWnd, hMenu ) --> lResult
 */
// HWG__SETMENU: Sets a menu (e.g., GtkMenuBar) as a child of a GtkBox in a window.
// Parameters:
// - HB_PARHANDLE(1): Handle to the parent window (GObject*).
// - HB_PARHANDLE(2): Handle to the menu widget (GtkWidget*, typically GtkMenuBar).
// Returns: 1 on success, 0 on failure (if the parent is not a GtkBox).
HB_FUNC( HWG__SETMENU )
{
    // Cast the first parameter to a GObject* to access the window handle.
    GObject * handle = (GObject*) HB_PARHANDLE(1);
    // Cast the second parameter to a GtkWidget* to access the menu widget.
    GtkWidget * menu = (GtkWidget*) HB_PARHANDLE(2);
    // Retrieve the GtkFixed container associated with the window using a custom function.
    GtkFixed * box = getFixedBox(handle);
    // Get the parent widget of the GtkFixed, expected to be a GtkBox (e.g., GtkVBox).
    GtkWidget * vbox = gtk_widget_get_parent((GtkWidget*)box);

    // Check if the parent widget is a valid GtkBox. If not, log a warning and return failure.
    if (!GTK_IS_BOX(vbox)) {
        g_warning("Parent widget is not a GtkBox!");
        hb_retl(0); // Return 0 to indicate failure.
        return;
    }

    // Check if the menu widget already has a parent (i.e., is attached to another container).
    GtkWidget * parent = gtk_widget_get_parent(menu);
    if (parent != NULL) {
        // Increment the reference count to prevent the menu widget from being destroyed.
        g_object_ref(menu);
        // Remove the menu widget from its current parent container.
        gtk_container_remove(GTK_CONTAINER(parent), menu);
    }

    // Add the menu widget to the GtkBox, with no expansion, no filling, and 0 padding.
    gtk_box_pack_start(GTK_BOX(vbox), menu, FALSE, FALSE, 0);
    // Reorder the menu widget to the first position in the GtkBox.
    gtk_box_reorder_child(GTK_BOX(vbox), menu, 0);
    // Make the menu widget visible.
    gtk_widget_show(menu);

    // If the menu had a parent, release the extra reference added earlier.
    if (parent != NULL) {
        g_object_unref(menu);
    }

    // Return 1 to indicate success.
    hb_retl(1);
}

HB_FUNC( HWG_GETMENUHANDLE )
{
   // HWND handle = ( hb_pcount()>0 && !HB_ISNIL(1) )? (HWND)hb_parnl(1):aWindows[0];
   // hb_retnl( (HB_LONG) GetMenu( handle ) );
}

HB_FUNC( HWG__CHECKMENUITEM )
{
   GtkCheckMenuItem * check_menu_item = (GtkCheckMenuItem *) HB_PARHANDLE(1);

   g_signal_handlers_block_matched( (gpointer)check_menu_item, G_SIGNAL_MATCH_FUNC,
       0, 0, 0, G_CALLBACK (cb_signal), 0 );
   gtk_check_menu_item_set_active( check_menu_item, (HB_ISNIL(2))? 1 : hb_parl(2) );
   g_signal_handlers_unblock_matched( (gpointer)check_menu_item, G_SIGNAL_MATCH_FUNC,
       0, 0, 0, G_CALLBACK (cb_signal), 0 );

}

HB_FUNC( HWG__ISCHECKEDMENUITEM )
{
   GtkCheckMenuItem * check_menu_item = (GtkCheckMenuItem *) HB_PARHANDLE(1);

   hb_retl( gtk_check_menu_item_get_active( check_menu_item ) );
}

HB_FUNC( HWG__ENABLEMENUITEM )
{
   GtkMenuItem * menu_item = (GtkMenuItem *) HB_PARHANDLE(1);

   gtk_widget_set_sensitive( (GtkWidget*)menu_item, (HB_ISNIL(2))? 1 : hb_parl(2) );
}

HB_FUNC( HWG__ISENABLEDMENUITEM )
{
   hb_retl( gtk_widget_is_sensitive( (GtkWidget*) HB_PARHANDLE(1) ) );
}

HB_FUNC( HWG_TRACKMENU )
{
   gtk_menu_popup( (GtkMenu *) HB_PARHANDLE(1), NULL, NULL, NULL, NULL, 3,
      gtk_get_current_event_time() );
}

HB_FUNC( HWG_DESTROYMENU )
{
/*
   hb_retl( DestroyMenu( (HMENU) hb_parnl(1) ) );
*/
}

/*
 * hwg__CreateAcceleratorTable( hWnd )
 */
HB_FUNC( HWG__CREATEACCELERATORTABLE )
{
   GtkAccelGroup *accel_group = gtk_accel_group_new();

   gtk_window_add_accel_group( GTK_WINDOW( HB_PARHANDLE(1) ), accel_group );
   HB_RETHANDLE( accel_group );
}

#define FSHIFT    4
#define FCONTROL  8
#define FALT     16

/*
 * hwg__AddAccelerator( hAccelTable, hMenuitem, nControl, nKey )
 */
HB_FUNC( HWG__ADDACCELERATOR )
{

   int iControl = hb_parni( 3 );
   GdkModifierType nType = (iControl==FSHIFT)? GDK_SHIFT_MASK : 
         ( (iControl==FCONTROL)? GDK_CONTROL_MASK : ( (iControl==FALT)? GDK_MOD1_MASK : 0 ) );

   gtk_widget_add_accelerator( (GtkWidget *) HB_PARHANDLE(2), "activate", 
         (GtkAccelGroup *)HB_PARHANDLE(1), 
         (guint)hb_parni(4), nType, 0 );
}

/*
 * DestroyAcceleratorTable( hAccel )
 */
HB_FUNC( HWG_DESTROYACCELERATORTABLE )
{
   g_object_unref( G_OBJECT( HB_PARHANDLE(1) ) );
}

HB_FUNC( HWG__SETMENUCAPTION )
{
   GtkMenuItem * menu_item = (GtkMenuItem *) HB_PARHANDLE(1);
   gchar * gcptr = hwg_convert_to_utf8( hb_parc(2) );

   gtk_label_set_text( (GtkLabel*) gtk_bin_get_child((GtkBin*)(menu_item)), gcptr );
   g_free( gcptr );
}

HB_FUNC( HWG__DELETEMENU )
{
   GtkMenuItem * menu_item = (GtkMenuItem *) HB_PARHANDLE(1);

   gtk_container_remove( (GtkContainer*)gtk_widget_get_parent(((GtkWidget*)menu_item)), (GtkWidget*)menu_item );
}

HB_FUNC( HWG_DRAWMENUBAR )
{
}

/* =========================== EOF of menu_c.c ================================== */

