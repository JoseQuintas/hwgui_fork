/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level painting functions
 *
 * Copyright 2013 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "guilib.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"

#include <cairo.h>
#include "gtk/gtk.h"

#include "hwgtk.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

#include <math.h>

/* Avoid warnings from GCC */
#include "warnings.h"

/* Define fixed parameters for bitmap */

#define BMPFILEIMG_MAXSZ 131072 /* Max file size of a bitmap (128 K) */
#define  _planes      1         /* Forever 1 */
#define  _compression 0         /* No compression */


#define HI_NIBBLE    0
#define LO_NIBBLE    1
#define MINIMUM(a, b) ((a) < (b) ? (a) : (b))

#define  PS_SOLID   0

extern GtkWidget * hMainWindow;
extern GtkFixed *getFixedBox( GObject * handle );

static void * bmp_fileimg ; /* Pointer to file image of a bitmap */
static long int nCurrPenClr = 0, nCurrBrushClr = 0xffffff;

void hwg_parse_color( HB_ULONG ncolor, GdkColor * pColor )
{
   char color[10]={0};

   sprintf( color,"#%0*lX",6,ncolor );
   color[8] = color[1]; color[9] = color[2];
   color[1] = color[5]; color[2] = color[6];
   color[5] = color[8]; color[6] = color[9];
   color[7] = '\0';
   gdk_color_parse( color,pColor );
}

HB_ULONG hwg_gdk_color( GdkColor * pColor )
{
   return (HB_ULONG) ( (pColor->red>>8) + (pColor->green&0xff00) + ((pColor->blue&0xff00)<<8) );
}

void hwg_setcolor( cairo_t * cr, long int nColor )
{
   short int r, g, b;

   nColor %= ( 65536 * 256 );
   r = nColor % 256;
   g = ( ( nColor - r ) % 65536 ) / 256;
   b = ( nColor - g - r ) / 65536;

   cairo_set_source_rgb( cr, ( ( double ) r ) / 255.,
          ( ( double ) g ) / 255., ( ( double ) b ) / 255. );

}


void hwg_SelectObject( PHWGUI_HDC hDC, HWGUI_HDC_OBJECT * obj )
{

   if( obj->type == HWGUI_OBJECT_PEN )
   {
      hwg_setcolor( hDC->cr, ((PHWGUI_PEN)obj)->color );
      cairo_set_line_width( hDC->cr, ((PHWGUI_PEN)obj)->width );
      if( ((PHWGUI_PEN)obj)->style == PS_SOLID )
         cairo_set_dash( hDC->cr, NULL, 0, 0 );
      else
      {
         static const double dashed[] = {2.0, 2.0};
         cairo_set_dash( hDC->cr, dashed, 2, 0 );
      }
   }
   else if( obj->type == HWGUI_OBJECT_BRUSH )
   {
      hwg_setcolor( hDC->cr, ((PHWGUI_BRUSH)obj)->color );
   }
   else if( obj->type == HWGUI_OBJECT_FONT )
   {
      hDC->hFont = ((PHWGUI_FONT)obj)->hFont;
      pango_layout_set_font_description( hDC->layout, hDC->hFont );
      if( ((PHWGUI_FONT)obj)->attrs )
      {
         pango_layout_set_attributes( hDC->layout, ((PHWGUI_FONT)obj)->attrs );
      }
   }
}

GdkPixbuf * alpha2pixbuf( GdkPixbuf * hPixIn, long int nColor )
{
   short int r, g, b;

   r = nColor % 256;
   g = ( ( nColor - r ) % 65536 ) / 256;
   b = ( nColor - g - r ) / 65536;
   return gdk_pixbuf_add_alpha( hPixIn, 1,
            (guchar) r, (guchar) g, (guchar) b );
}

/*
 * hwg_Alpha2Pixbuf( hBitmap, nColor )
 */
HB_FUNC( HWG_ALPHA2PIXBUF )
{
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(1);
   GdkPixbuf * handle;
   long int nColor = hb_parnl(2);

   if( obj && obj->handle && obj->trcolor != nColor )
   {
      handle = alpha2pixbuf( obj->handle, nColor );
      g_object_unref( (GObject*) obj->handle );
      obj->handle = handle;
      obj->trcolor = nColor;
   }

}

HB_FUNC( HWG_INVALIDATERECT )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   int x1, y1, x2, y2;

   if( hb_pcount() > 2 )
   {
      x1 = hb_parni(3);
      y1 = hb_parni(4);
      x2 = hb_parni(5);
      y2 = hb_parni(6);
   }
   else
   {
      GtkAllocation alloc;
      gtk_widget_get_allocation( widget, &alloc );

      x1 = y1 = 0;
      x2 = alloc.width;
      y2 = alloc.height;
   }
   gtk_widget_queue_draw_area( widget, x1, y1,
        x2 - x1 + 1, y2 - y1 + 1 );

}

HB_FUNC( HWG_MOVETO )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   cairo_move_to( hDC->cr, (gdouble)hb_parni(2), (gdouble)hb_parni(3) );

}

HB_FUNC( HWG_LINETO )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);

   hwg_setcolor( hDC->cr, nCurrPenClr );
   cairo_line_to( hDC->cr, (gdouble)hb_parni(2), (gdouble)hb_parni(3) );
   if( HB_ISLOG(4) && hb_parl(4) )
      cairo_stroke( hDC->cr );

}

HB_FUNC( HWG_DRAWLINE )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);

   hwg_setcolor( hDC->cr, nCurrPenClr );
   cairo_move_to( hDC->cr, (gdouble)hb_parni(2), (gdouble)hb_parni(3) );
   cairo_line_to( hDC->cr, (gdouble)hb_parni(4), (gdouble)hb_parni(5) );
   cairo_stroke( hDC->cr );

}

HB_FUNC( HWG_PIE )
{
}

/*
 * hwg_Triangle( hDC, x1, y1, x2, y2, x3, y3 [, hPen] )
 */
HB_FUNC( HWG_TRIANGLE )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   int x2 = hb_parni( 4 ), y2 = hb_parni( 5 );
   int x3 = hb_parni( 6 ), y3 = hb_parni( 7 );
   PHWGUI_PEN hPen = ( HB_ISNIL( 8 ) ) ? NULL : ( PHWGUI_PEN ) HB_PARHANDLE( 8 );

   if( hPen )
   {
      //cairo_save( hDC->cr );
      hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
   }
   else
      hwg_setcolor( hDC->cr, nCurrPenClr );

   cairo_move_to( hDC->cr, (gdouble)x1, (gdouble)y1 );
   cairo_line_to( hDC->cr, (gdouble)x2, (gdouble)y2 );
   cairo_line_to( hDC->cr, (gdouble)x3, (gdouble)y3 );
   cairo_line_to( hDC->cr, (gdouble)x1, (gdouble)y1 );
   cairo_stroke( hDC->cr );

   //if( hPen )
   //   cairo_restore( hDC->cr );

}

/*
 * hwg_Triangle_Filled( hDC, x1, y1, x2, y2, x3, y3 [, hPen | lPen] [, hBrush] )
 */
HB_FUNC( HWG_TRIANGLE_FILLED )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   int x2 = hb_parni( 4 ), y2 = hb_parni( 5 );
   int x3 = hb_parni( 6 ), y3 = hb_parni( 7 );
   PHWGUI_PEN hPen = NULL;
   PHWGUI_BRUSH hBrush = ( HB_ISNIL( 9 ) ) ? NULL : (PHWGUI_BRUSH) HB_PARHANDLE( 9 );
   int bNullPen = 0;
   //int bSave = ( ( !HB_ISNIL( 8 ) && !HB_ISLOG( 8 ) ) || !HB_ISNIL( 9 ) );

   //if( bSave )
   //   cairo_save( hDC->cr );

   if( hBrush )
      hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hBrush );
   else
      hwg_setcolor( hDC->cr, nCurrBrushClr );

   cairo_move_to( hDC->cr, (gdouble)x1, (gdouble)y1 );
   cairo_line_to( hDC->cr, (gdouble)x2, (gdouble)y2 );
   cairo_line_to( hDC->cr, (gdouble)x3, (gdouble)y3 );
   cairo_line_to( hDC->cr, (gdouble)x1, (gdouble)y1 );
   cairo_fill( hDC->cr );

   if( !HB_ISNIL( 8 ) )
   {
      if( HB_ISLOG( 8 ) )
      {
         if( !hb_parl(8) )
            bNullPen = 1;
      }
      else
      {
         hPen = (PHWGUI_PEN) HB_PARHANDLE( 8 );
         hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
      }
   }
   if( !bNullPen )
   {
      if( !hPen )
         hwg_setcolor( hDC->cr, nCurrPenClr );
      cairo_move_to( hDC->cr, (gdouble)x1, (gdouble)y1 );
      cairo_line_to( hDC->cr, (gdouble)x2, (gdouble)y2 );
      cairo_line_to( hDC->cr, (gdouble)x3, (gdouble)y3 );
      cairo_line_to( hDC->cr, (gdouble)x1, (gdouble)y1 );
      cairo_stroke( hDC->cr );
   }

   //if( bSave )
   //   cairo_restore( hDC->cr );

}

/*
 * hwg_Rectangle( hDC, x1, y1, x2, y2 [, hPen] )
 */
HB_FUNC( HWG_RECTANGLE )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   PHWGUI_PEN hPen = ( HB_ISNIL( 6 ) ) ? NULL : ( PHWGUI_PEN ) HB_PARHANDLE( 6 );

   if( hPen )
   {
      //cairo_save( hDC->cr );
      hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
   }
   else
      hwg_setcolor( hDC->cr, nCurrPenClr );

   cairo_rectangle( hDC->cr, (gdouble)x1, (gdouble)y1,
        (gdouble)(hb_parni(4)-x1+1), (gdouble)(hb_parni(5)-y1+1) );
   cairo_stroke( hDC->cr );

   //if( hPen )
   //   cairo_restore( hDC->cr );
}

/*
 * hwg_Rectangle_Filled( hDC, x1, y1, x2, y2 [, hPen | lPen] [, hBrush] )
 */
HB_FUNC( HWG_RECTANGLE_FILLED )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   PHWGUI_PEN hPen = NULL;
   PHWGUI_BRUSH hBrush = ( HB_ISNIL( 7 ) ) ? NULL : (PHWGUI_BRUSH) HB_PARHANDLE( 7 );
   int bNullPen = 0;
   //int bSave = ( ( !HB_ISNIL( 6 ) && !HB_ISLOG( 6 ) ) || !HB_ISNIL( 7 ) );

   //if( bSave )
   //   cairo_save( hDC->cr );

   if( hBrush )
      hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hBrush );
   else
      hwg_setcolor( hDC->cr, nCurrBrushClr );

   cairo_rectangle( hDC->cr, (gdouble)x1, (gdouble)y1,
        (gdouble)(hb_parni(4)-x1+1), (gdouble)(hb_parni(5)-y1+1) );
   cairo_fill( hDC->cr );

   if( !HB_ISNIL( 6 ) )
   {
      if( HB_ISLOG( 6 ) )
      {
         if( !hb_parl(6) )
            bNullPen = 1;
      }
      else
      {
         hPen = (PHWGUI_PEN) HB_PARHANDLE( 6 );
         hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
      }
   }
   if( !bNullPen )
   {
      if( !hPen )
         hwg_setcolor( hDC->cr, nCurrPenClr );
      cairo_rectangle( hDC->cr, (gdouble)x1, (gdouble)y1,
           (gdouble)(hb_parni(4)-x1+1), (gdouble)(hb_parni(5)-y1+1) );
      cairo_stroke( hDC->cr );
   }

   //if( bSave )
   //   cairo_restore( hDC->cr );
}

/*
 * hwg_Ellipse( hDC, x1, y1, x2, y2 [, hPen] )
 */
HB_FUNC( HWG_ELLIPSE )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 ), x2 = hb_parni( 4 ), y2 = hb_parni( 5 );
   PHWGUI_PEN hPen = ( HB_ISNIL( 6 ) ) ? NULL : ( PHWGUI_PEN ) HB_PARHANDLE( 6 );

   if( hPen )
   {
      //cairo_save( hDC->cr );
      hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
   }
   else
      hwg_setcolor( hDC->cr, nCurrPenClr );

   cairo_arc( hDC->cr, (double)x1+(x2-x1)/2, (double)y1+(y2-y1)/2, (double) (x2-x1)/2, 0, 6.28 );
   cairo_stroke( hDC->cr );

   //if( hPen )
   //   cairo_restore( hDC->cr );
}

/*
 * hwg_Ellipse_Filled( hDC, x1, y1, x2, y2 [, hPen | lPen] [, hBrush] )
 */
HB_FUNC( HWG_ELLIPSE_FILLED )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 ), x2 = hb_parni( 4 ), y2 = hb_parni( 5 );
   PHWGUI_BRUSH hBrush = ( HB_ISNIL( 7 ) ) ? NULL : (PHWGUI_BRUSH) HB_PARHANDLE( 7 );
   PHWGUI_PEN hPen = NULL;
   int bNullPen = 0;
   //int bSave = ( ( !HB_ISNIL( 6 ) && !HB_ISLOG( 6 ) ) || !HB_ISNIL( 7 ) );

   //if( bSave )
   //   cairo_save( hDC->cr );

   if( hBrush )
      hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hBrush );
   else
      hwg_setcolor( hDC->cr, nCurrBrushClr );

   cairo_arc( hDC->cr, (double)x1+(x2-x1)/2, (double)y1+(y2-y1)/2, (double) (x2-x1)/2, 0, 6.28 );
   cairo_fill( hDC->cr );

   if( !HB_ISNIL( 6 ) )
   {
      if( HB_ISLOG( 6 ) )
      {
         if( !hb_parl(6) )
            bNullPen = 1;
      }
      else
      {
         hPen = (PHWGUI_PEN) HB_PARHANDLE( 6 );
         hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
      }
   }
   if( !bNullPen )
   {
      if( !hPen )
         hwg_setcolor( hDC->cr, nCurrPenClr );
      cairo_arc( hDC->cr, (double)x1+(x2-x1)/2, (double)y1+(y2-y1)/2, (double) (x2-x1)/2, 0, 6.28 );
      cairo_stroke( hDC->cr );
   }

   //if( bSave )
   //   cairo_restore( hDC->cr );

}

/*
 * hwg_RoundRect( hDC, x1, y1, x2, y2, iRadius [, hPen] )
 */
HB_FUNC( HWG_ROUNDRECT )
{

   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = hb_parnd( 2 ), y1 = hb_parnd( 3 ), x2 = hb_parnd( 4 ), y2 = hb_parnd( 5 );
   gdouble radius = hb_parnd( 6 );
   PHWGUI_PEN hPen = ( HB_ISNIL( 7 ) ) ? NULL : ( PHWGUI_PEN ) HB_PARHANDLE( 7 );

   if( hPen )
   {
      //cairo_save( hDC->cr );
      hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
   }
   else
      hwg_setcolor( hDC->cr, nCurrPenClr );

   cairo_new_sub_path( hDC->cr );
   cairo_arc( hDC->cr, x1+radius, y1+radius, radius, M_PI, 3*M_PI/2 );
   cairo_arc( hDC->cr, x2-radius, y1+radius, radius, 3*M_PI/2, 0 );
   cairo_arc( hDC->cr, x2-radius, y2-radius, radius, 0, M_PI/2 );
   cairo_arc( hDC->cr, x1+radius, y2-radius, radius, M_PI/2, M_PI );
   cairo_close_path(hDC->cr);
   cairo_stroke( hDC->cr );

   //if( hPen )
   //   cairo_restore( hDC->cr );
}

/*
 * hwg_RoundRect_Filled( hDC, x1, y1, x2, y2, iRadius [, hPen | lPen] [, hBrush] )
 */
HB_FUNC( HWG_ROUNDRECT_FILLED )
{

   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = hb_parnd( 2 ), y1 = hb_parnd( 3 ), x2 = hb_parnd( 4 ), y2 = hb_parnd( 5 );
   gdouble radius = hb_parnd( 6 );
   PHWGUI_BRUSH brush = ( HB_ISNIL( 8 ) ) ? NULL : (PHWGUI_BRUSH) HB_PARHANDLE(8);
   PHWGUI_PEN hPen = NULL;
   int bNullPen = 0;
   //int bSave = ( ( !HB_ISNIL( 7 ) && !HB_ISLOG( 7 ) ) || !HB_ISNIL( 8 ) );

   //if( bSave )
   //   cairo_save( hDC->cr );

   cairo_new_sub_path( hDC->cr );
   if( brush )
      hwg_setcolor( hDC->cr, brush->color );
   else
      hwg_setcolor( hDC->cr, nCurrBrushClr );

   cairo_arc( hDC->cr, x1+radius, y1+radius, radius, M_PI, 3*M_PI/2 );
   cairo_arc( hDC->cr, x2-radius, y1+radius, radius, 3*M_PI/2, 0 );
   cairo_arc( hDC->cr, x2-radius, y2-radius, radius, 0, M_PI/2 );
   cairo_arc( hDC->cr, x1+radius, y2-radius, radius, M_PI/2, M_PI );
   cairo_close_path(hDC->cr);
   cairo_fill( hDC->cr );

   if( !HB_ISNIL( 7 ) )
   {
      if( HB_ISLOG( 7 ) )
      {
         if( !hb_parl(7) )
            bNullPen = 1;
      }
      else
      {
         hPen = (PHWGUI_PEN) HB_PARHANDLE( 7 );
         hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
      }
   }
   if( !bNullPen )
   {
      if( !hPen )
         hwg_setcolor( hDC->cr, nCurrPenClr );
      cairo_arc( hDC->cr, x1+radius, y1+radius, radius, M_PI, 3*M_PI/2 );
      cairo_arc( hDC->cr, x2-radius, y1+radius, radius, 3*M_PI/2, 0 );
      cairo_arc( hDC->cr, x2-radius, y2-radius, radius, 0, M_PI/2 );
      cairo_arc( hDC->cr, x1+radius, y2-radius, radius, M_PI/2, M_PI );
      cairo_close_path(hDC->cr);
      cairo_stroke( hDC->cr );
   }

   //if( bSave )
   //   cairo_restore( hDC->cr );
}

/*
 * hwg_CircleSector( hDC, xc, yc, radius, iAngleStart, iAngle [, hPen] )
 * Draws a circle sector with a center in xc, yc, with a radius from an angle
 */
HB_FUNC( HWG_CIRCLESECTOR )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = hb_parnd( 2 ), y1 = hb_parnd( 3 );
   gdouble radius = hb_parnd( 4 );
   int iAngle1 = -hb_parni(5), iAngle2 = iAngle1-hb_parni(6), i;
   PHWGUI_PEN hPen = ( HB_ISNIL( 7 ) ) ? NULL : ( PHWGUI_PEN ) HB_PARHANDLE( 7 );

   if( hPen )
      hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
   else
      hwg_setcolor( hDC->cr, nCurrPenClr );

   if( iAngle2 < iAngle1 )
   {
      i = iAngle1;
      iAngle1 = iAngle2;
      iAngle2 = i;
   }
   cairo_arc ( hDC->cr, x1, y1, radius, iAngle1 * M_PI / 180., iAngle2 * M_PI / 180. );
   cairo_line_to ( hDC->cr, x1, y1 );
   cairo_arc ( hDC->cr, x1, y1, radius, iAngle1 * M_PI / 180., iAngle2 * M_PI / 180. );
   cairo_line_to ( hDC->cr, x1, y1 );
   cairo_stroke ( hDC->cr );
}

/*
 * hwg_CircleSector_Filled( hDC, xc, yc, radius, iAngleStart, iAngle [, hPen] )
 * Draws a circle sector with a center in xc, yc, with a radius from an angle
 */
HB_FUNC( HWG_CIRCLESECTOR_FILLED )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = hb_parnd( 2 ), y1 = hb_parnd( 3 );
   gdouble radius = hb_parnd( 4 );
   int iAngle1 = -hb_parni(5), iAngle2 = iAngle1-hb_parni(6), i;
   PHWGUI_BRUSH brush = ( HB_ISNIL( 8 ) ) ? NULL : (PHWGUI_BRUSH) HB_PARHANDLE(8);
   PHWGUI_PEN hPen = NULL;
   int bNullPen = 0;

   if( brush )
      hwg_setcolor( hDC->cr, brush->color );
   else
      hwg_setcolor( hDC->cr, nCurrBrushClr );

   if( iAngle2 < iAngle1 )
   {
      i = iAngle1;
      iAngle1 = iAngle2;
      iAngle2 = i;
   }
   cairo_arc ( hDC->cr, x1, y1, radius, iAngle1 * M_PI / 180., iAngle2 * M_PI / 180. );
   cairo_line_to ( hDC->cr, x1, y1 );
   cairo_arc ( hDC->cr, x1, y1, radius, iAngle1 * M_PI / 180., iAngle2 * M_PI / 180. );
   cairo_line_to ( hDC->cr, x1, y1 );
   cairo_fill( hDC->cr );

   if( !HB_ISNIL( 7 ) )
   {
      if( HB_ISLOG( 7 ) )
      {
         if( !hb_parl(7) )
            bNullPen = 1;
      }
      else
      {
         hPen = (PHWGUI_PEN) HB_PARHANDLE( 7 );
         hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
      }
   }
   if( !bNullPen )
   {
      if( !hPen )
         hwg_setcolor( hDC->cr, nCurrPenClr );
      cairo_arc ( hDC->cr, x1, y1, radius, iAngle1 * M_PI / 180., iAngle2 * M_PI / 180. );
      cairo_line_to ( hDC->cr, x1, y1 );
      cairo_arc ( hDC->cr, x1, y1, radius, iAngle1 * M_PI / 180., iAngle2 * M_PI / 180. );
      cairo_line_to ( hDC->cr, x1, y1 );
      cairo_stroke( hDC->cr );
   }

}

HB_FUNC( HWG_FILLRECT )
{
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PHWGUI_BRUSH brush = (PHWGUI_BRUSH) HB_PARHANDLE(6);

   //cairo_save( hDC->cr );
   hwg_setcolor( hDC->cr, brush->color );
   cairo_rectangle( hDC->cr, (gdouble)x1, (gdouble)y1,
         (gdouble)(hb_parni(4)-x1+1), (gdouble)(hb_parni(5)-y1+1) );
   cairo_fill( hDC->cr );
   //cairo_restore( hDC->cr );
}

/*
 * hwg_Arc( hDC, xc, yc, radius, iAngleStart, iAngleEnd )
 * Draws an arc with a center in xc, yc, with a radius from an angle
 * iAngleStart to iAngleEnd. Angles are passed in degrees.
 * 0 corresponds to the standard X axis, drawing direction is clockwise.
 */
HB_FUNC( HWG_ARC )
{

   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = hb_parnd( 2 ), y1 = hb_parnd( 3 );
   gdouble radius = hb_parnd( 4 );
   int iAngle1 = hb_parni(5), iAngle2 = hb_parni(6);

   cairo_new_sub_path( hDC->cr );
   hwg_setcolor( hDC->cr, nCurrPenClr );
   cairo_arc( hDC->cr, x1, y1, radius, iAngle1 * M_PI / 180., iAngle2 * M_PI / 180. );
   //cairo_close_path(hDC->cr);
   cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_REDRAWWINDOW )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   GtkAllocation alloc;

   gtk_widget_get_allocation( widget, &alloc );
   gtk_widget_queue_draw_area( widget, 0, 0,
        alloc.width, alloc.height );
}

HB_FUNC( HWG_DRAWGRID )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int x1 = hb_parni(2), y1 = hb_parni(3), x2 = hb_parni(4), y2 = hb_parni(5);
   int n = ( HB_ISNIL( 6 ) ) ? 4 : hb_parni( 6 );
   unsigned int uiColor = ( HB_ISNIL( 7 ) ) ? 0 : ( unsigned int ) hb_parnl( 7 );
   int i, j;

   hwg_setcolor( hDC->cr, uiColor );
   for( i = x1+n; i < x2; i+=n )
      for( j = y1+n; j < y2; j+=n )
         cairo_rectangle( hDC->cr, (gdouble)i, (gdouble)j, 1, 1 );
   cairo_fill( hDC->cr );
}

/*
  hwg_DrawButton(handle,nleft,ntop,nright,nbottom,niType)
*/

HB_FUNC( HWG_DRAWBUTTON )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int left = hb_parni( 2 );
   int top = hb_parni( 3 );
   int right = hb_parni( 4 );
   int bottom = hb_parni( 5 );
   unsigned int iType = hb_parni( 6 );
   GtkStyle * style = gtk_widget_get_style( hDC->widget );

   if( iType == 0 )
   {
      hwg_setcolor( hDC->cr, hwg_gdk_color( style->bg ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top,
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_fill( hDC->cr );
   }
   else
   {
      hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->mid : style->light ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top,
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_fill( hDC->cr );

      left ++; top ++;
      hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->light : ( (iType & 4)? style->dark : style->mid ) ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top,
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_fill( hDC->cr );

      right --; bottom --;
      right --; bottom --;
      if( iType & 4 )
      {
         hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->mid : style->light ) );
         cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top,
              (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
         cairo_fill( hDC->cr );

         left ++; top ++;
         hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->light : style->mid ) );
         cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top,
              (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
         cairo_fill( hDC->cr );

         right --; bottom --;
      }
      hwg_setcolor( hDC->cr, hwg_gdk_color( style->bg ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top,
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_fill( hDC->cr );
   }
}

void hwg_gtk_drawedge( PHWGUI_HDC hDC, int left, int top, int right, int bottom, unsigned int iType )
{

   GtkStyle * style = gtk_widget_get_style( hDC->widget );

   hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->mid : style->light ) );
   cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top,
        (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
   cairo_stroke( hDC->cr );

   left ++; top ++;
   hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->light : ( (iType & 4)? style->dark : style->mid ) ) );
   cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top,
        (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
   cairo_stroke( hDC->cr );

   right --; bottom --;
   right --; bottom --;
   if( iType & 4 )
   {
      hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->mid : style->light ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top,
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_stroke( hDC->cr );

      left ++; top ++;
      hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->light : style->mid ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top,
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_stroke( hDC->cr );

      right --; bottom --;
   }
   hwg_setcolor( hDC->cr, hwg_gdk_color( style->bg ) );
   cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top,
        (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
   cairo_stroke( hDC->cr );

}
/*
 * DrawEdge( hDC,x1,y1,x2,y2,nFlag )
 */
HB_FUNC( HWG_GTK_DRAWEDGE )
{

   hwg_gtk_drawedge( (PHWGUI_HDC) HB_PARHANDLE(1), hb_parni( 2 ), hb_parni( 3 ),
         hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ) );
}

HB_FUNC( HWG_LOADICON )
{
}

HB_FUNC( HWG_LOADIMAGE )
{
}

HB_FUNC( HWG_LOADBITMAP )
{
}

/*
 * Window2Bitmap( hWnd )
 */
HB_FUNC( HWG_WINDOW2BITMAP )
{
   GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE(1);
   GdkPixbuf *pixbuf = gdk_pixbuf_new( GDK_COLORSPACE_RGB, 0, 8, hb_parni(4), hb_parni(5) );

#if GTK_MAJOR_VERSION -0 < 3
   pixbuf = gdk_pixbuf_get_from_drawable( pixbuf, gtk_widget_get_window(hCtrl),
      NULL, hb_parni(2), hb_parni(3), 0, 0, hb_parni(4), hb_parni(5) );
#else
   pixbuf = gdk_pixbuf_get_from_window( gtk_widget_get_window(hCtrl),
      hb_parni(2), hb_parni(3), hb_parni(4), hb_parni(5) );
#endif

   if( pixbuf )
   {
      PHWGUI_PIXBUF hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
      hpix->type = HWGUI_OBJECT_PIXBUF;
      hpix->handle = pixbuf;
      hpix->trcolor = -1;
      HB_RETHANDLE( hpix );
   }
}

/*
 * DrawBitmap( hDC, hBitmap, style, x, y, width, height )
 */
HB_FUNC( HWG_DRAWBITMAP )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
   GdkPixbuf * pixbuf;
   gint x =  hb_parni(4);
   gint y =  hb_parni(5);
   gint srcWidth = gdk_pixbuf_get_width( obj->handle );
   gint srcHeight = gdk_pixbuf_get_height( obj->handle );
   gint destWidth = ( hb_pcount(  ) >= 5 && !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : srcWidth;
   gint destHeight = ( hb_pcount(  ) >= 6 && !HB_ISNIL( 7 ) ) ? hb_parni( 7 ) : srcHeight;

   if( srcWidth == destWidth && srcHeight == destHeight ) {
      gdk_cairo_set_source_pixbuf( hDC->cr, obj->handle, x, y );
      cairo_paint( hDC->cr );
   }
   else {
      pixbuf = gdk_pixbuf_scale_simple( obj->handle, destWidth, destHeight, GDK_INTERP_HYPER );
      gdk_cairo_set_source_pixbuf( hDC->cr, pixbuf, x, y );
      cairo_paint( hDC->cr );
      g_object_unref( (GObject*) pixbuf );
   }

}

/*
 * DrawTransparentBitmap( hDC, hBitmap, x, y, trcolor, width, height )
 */
HB_FUNC( HWG_DRAWTRANSPARENTBITMAP )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
   GdkPixbuf * pixbuf;
   gint x =  hb_parni(3);
   gint y =  hb_parni(4);
   long int nColor = hb_parnl(5);
   gint srcWidth = gdk_pixbuf_get_width( obj->handle );
   gint srcHeight = gdk_pixbuf_get_height( obj->handle );
   gint destWidth = ( hb_pcount(  ) >= 5 && !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : srcWidth;
   gint destHeight = ( hb_pcount(  ) >= 6 && !HB_ISNIL( 7 ) ) ? hb_parni( 7 ) : srcHeight;

   if( obj->trcolor != nColor )
   {
      pixbuf = alpha2pixbuf( obj->handle, nColor );
      g_object_unref( (GObject*) obj->handle );
      obj->handle = pixbuf;
      obj->trcolor = nColor;
   }

   if( srcWidth == destWidth && srcHeight == destHeight ) {
      gdk_cairo_set_source_pixbuf( hDC->cr, obj->handle, x, y );
      cairo_paint( hDC->cr );
   }
   else {
      pixbuf = gdk_pixbuf_scale_simple( obj->handle, destWidth, destHeight, GDK_INTERP_HYPER );
      gdk_cairo_set_source_pixbuf( hDC->cr, pixbuf, x, y );
      cairo_paint( hDC->cr );
      g_object_unref( (GObject*) pixbuf );
   }
}

HB_FUNC( HWG_SPREADBITMAP )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
   GtkWidget * widget = hDC->widget;
   GdkPixbuf * pixbuf;
   int nWidth, nHeight, x1, x2, y1, y2, nw, nh;
   int nLeft = (HB_ISNUM(3))? hb_parni(3) : 0;
   int nTop = (HB_ISNUM(4))? hb_parni(4) : 0;
   int nRight = (HB_ISNUM(5))? hb_parni(5) : 0;
   int nBottom = (HB_ISNUM(6))? hb_parni(6) : 0;

   if( nLeft == 0 && nRight == 0 )
   {
      GtkAllocation alloc;
      gtk_widget_get_allocation( widget, &alloc );

      nLeft = nTop = 0;
      nRight = alloc.width;
      nBottom = alloc.height;
   }

   x1 = y1 = 0;
   x2 = nRight - nLeft + 1;
   y2 = nBottom - nTop + 1;

   pixbuf = gdk_pixbuf_new( GDK_COLORSPACE_RGB, 0,
      gdk_pixbuf_get_bits_per_sample( obj->handle ), x2-x1+1, y2-y1+1 );

   nWidth = gdk_pixbuf_get_width( obj->handle );
   nHeight = gdk_pixbuf_get_height( obj->handle );
   while( y1 < y2 )
   {
      nh = (y2-y1 >= nHeight)? nHeight : y2-y1;
      while( x1 < x2 )
      {
         nw = (x2-x1 >= nWidth)? nWidth : x2-x1;
         gdk_pixbuf_copy_area( (const GdkPixbuf *)obj->handle, 0, 0, nw, nh, pixbuf, x1, y1);
         x1 += nWidth;
      }
      x1 = 0;
      y1 += nHeight;
   }

   gdk_cairo_set_source_pixbuf( hDC->cr, pixbuf, nLeft, nTop );
   cairo_paint( hDC->cr );
   g_object_unref( (GObject*) pixbuf );

}

HB_FUNC( HWG_GETBITMAPSIZE )
{
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(1);
   PHB_ITEM aMetr = _itemArrayNew( 2 );
   PHB_ITEM temp;

   temp = _itemPutNL( NULL, gdk_pixbuf_get_width ( obj->handle) );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, gdk_pixbuf_get_height ( obj->handle) );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );

}

/*
  hwg_Openbitmap( cBitmap )
  cBitmap : File name of bitmap
  returns handle to pixbuffer
*/
HB_FUNC( HWG_OPENBITMAP )
{
   PHWGUI_PIXBUF hpix;
   GdkPixbuf * handle = gdk_pixbuf_new_from_file( hb_parc(1), NULL );

   if( handle )
   {
      hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
      hpix->type = HWGUI_OBJECT_PIXBUF;
      hpix->handle = handle;
      hpix->trcolor = -1;
      HB_RETHANDLE( hpix );
   }
}

/* hwg_SaveBitMap( cfilename , hpixbuf , ctype )
 * ctype default: "bmp"
 */
HB_FUNC( HWG_SAVEBITMAP )
{
   PHWGUI_PIXBUF hpix = HB_PARHANDLE(2);
   const char * szType = (HB_ISCHAR(3))? hb_parc(3) : "bmp";
#if GTK_MAJOR_VERSION -0 < 3
   hb_retl( gdk_pixbuf_save( hpix->handle, hb_parc(1), szType, NULL, NULL ) );
#else
   hb_retl( gdk_pixbuf_save_to_stream( ( GdkPixbuf *) hb_parc(1),(GOutputStream * ) hpix->handle,  szType, NULL, NULL) );
#endif
}

/* hwg_Openimage( name , ltype , width, height )
  ltype : .F. : from image file (default)
          .T. : from GDK pixbuffer
  returns handle to pixbuffer
  */
HB_FUNC( HWG_OPENIMAGE )
{
   PHWGUI_PIXBUF hpix;
   short int iString = ( HB_ISNIL( 2 ) ) ? 0 : hb_parl( 2 );
   GdkPixbuf * handle = NULL;
   int width = ( HB_ISNIL( 3 ) ) ? 0 : hb_parni( 3 );
   int height = ( HB_ISNIL( 4 ) ) ? 0 : hb_parni( 4 );

   if( iString )
   {
      /* Load image from GDK pixbuffer */
       guint8 *buf = (guint8 *) hb_parc(1);
       short int iOk;
       GdkPixbufLoader * loader = gdk_pixbuf_loader_new();

       iOk = gdk_pixbuf_loader_write( loader, buf, hb_parclen(1), NULL );
       gdk_pixbuf_loader_close( loader, NULL );
       if( iOk )
          handle = gdk_pixbuf_loader_get_pixbuf( loader );
   }
   else
   {
      /* Load image from file */
  
      /* Both size parameters must have a value greater 0 */
      if ( (width > 0 ) &&  ( height > 0) )
      {
      
       /* with size parameters
        DF7BE 2025-03-01 :
        GdkPixbuf*
        gdk_pixbuf_new_from_file_at_scale (
        const char* filename,
        int width,
        int height,
        gboolean preserve_aspect_ratio,
        GError** error
        )
        Return value: Type=GdkPixbuf A newly-created pixbuf.
        height, width: -1 to not constrain the width or height.
        preserve_aspect_ratio: Type: gboolean  TRUE to preserve the image’s aspect ratio.
       */
   
        handle = gdk_pixbuf_new_from_file_at_scale( hb_parc(1), width, height, TRUE , NULL );
     }
     else
     {
        handle = gdk_pixbuf_new_from_file( hb_parc(1), NULL );
     }  /* Size parameters */   
   } /* if String/file */
   if( handle )
   {
      hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
      hpix->type = HWGUI_OBJECT_PIXBUF;
      hpix->handle = handle;
      hpix->trcolor = -1;
      HB_RETHANDLE( hpix );
   }  /* if handle */
}

HB_FUNC( HWG_DRAWICON )
{
}

HB_FUNC( HWG_GETSYSCOLOR )
{
   if( hMainWindow )
   {
      GdkColor color = gtk_widget_get_style(hMainWindow)->bg[GTK_STATE_NORMAL];
      hb_retnl( hwg_gdk_color( &color ) );
   }
   else
      hb_retnl( 0 );
}

HB_FUNC( HWG_CREATEPEN )
{
   PHWGUI_PEN hpen = (PHWGUI_PEN) hb_xgrab( sizeof(HWGUI_PEN) );

   hpen->type = HWGUI_OBJECT_PEN;
   hpen->style = hb_parni(1);
   hpen->width = hb_parnd(2);
   hpen->color = hb_parnl(3);

   HB_RETHANDLE( hpen );
}

HB_FUNC( HWG_CREATESOLIDBRUSH )
{
   PHWGUI_BRUSH hbrush = (PHWGUI_BRUSH) hb_xgrab( sizeof(HWGUI_BRUSH) );

   hbrush->type = HWGUI_OBJECT_BRUSH;
   hbrush->color = hb_parnl(1);

   HB_RETHANDLE( hbrush );
}

HB_FUNC( HWG_SELECTOBJECT )
{
   HWGUI_HDC_OBJECT * obj = (HWGUI_HDC_OBJECT*) HB_PARHANDLE(2);

   hwg_SelectObject( (PHWGUI_HDC) HB_PARHANDLE(1), obj );

   if( obj->type == HWGUI_OBJECT_PEN )
      nCurrPenClr = ((PHWGUI_PEN)obj)->color;
   else if( obj->type == HWGUI_OBJECT_BRUSH )
      nCurrBrushClr = ((PHWGUI_BRUSH)obj)->color;

   HB_RETHANDLE( NULL );
}

HB_FUNC( HWG_DELETEOBJECT )
{
   HWGUI_HDC_OBJECT * obj = (HWGUI_HDC_OBJECT*) HB_PARHANDLE(1);

   if( obj->type == HWGUI_OBJECT_PEN )
   {
      hb_xfree( obj );
   }
   else if( obj->type == HWGUI_OBJECT_BRUSH )
   {
      hb_xfree( obj );
   }
   else if( obj->type == HWGUI_OBJECT_FONT )
   {
      pango_font_description_free( ( (PHWGUI_FONT)obj )->hFont );
      pango_attr_list_unref( ( (PHWGUI_FONT)obj )->attrs );
      hb_xfree( obj );
   }
   else if( obj->type == HWGUI_OBJECT_PIXBUF )
   {
      g_object_unref( (GObject*) ( (PHWGUI_PIXBUF)obj )->handle );
      hb_xfree( obj );
   }

}

HB_FUNC( HWG_DEFINEPAINTSTRU )
{
   PHWGUI_PPS pps = (PHWGUI_PPS) hb_xgrab( sizeof(HWGUI_PPS) );

   pps->hDC = NULL;
   HB_RETHANDLE( pps );
}

HB_FUNC( HWG_BEGINPAINT )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   PHWGUI_PPS pps = (PHWGUI_PPS) HB_PARHANDLE(2);
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_xgrab( sizeof(HWGUI_HDC) );

   memset( hDC, 0, sizeof(HWGUI_HDC) );
   hDC->widget = widget;

   hDC->window = gtk_widget_get_window( widget );
   hDC->cr = gdk_cairo_create( hDC->window );

   hDC->layout = pango_cairo_create_layout( hDC->cr );
   hDC->fcolor = hDC->bcolor = -1;

   pps->hDC = hDC;
   nCurrPenClr = 0;
   nCurrBrushClr = 0xffffff;

   HB_RETHANDLE( hDC );
}

HB_FUNC( HWG_ENDPAINT )
{
   PHWGUI_PPS pps = (PHWGUI_PPS) HB_PARHANDLE(2);
   PHWGUI_HDC hDC = pps->hDC;

   if( hDC->layout )
      g_object_unref( (GObject*) hDC->layout );
   if( hDC->surface )
      cairo_surface_destroy( hDC->surface );
   cairo_destroy( hDC->cr );

   hb_xfree( hDC );
   hb_xfree( pps );
}

HB_FUNC( HWG_GETDC )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_xgrab( sizeof(HWGUI_HDC) );
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);

   memset( hDC, 0, sizeof(HWGUI_HDC) );
   hDC->widget = widget;

   hDC->window = gtk_widget_get_window( widget );
   hDC->cr = gdk_cairo_create( hDC->window );

   hDC->layout = pango_cairo_create_layout( hDC->cr );
   hDC->fcolor = hDC->bcolor = -1;

   nCurrPenClr = 0;
   nCurrBrushClr = 0xffffff;

   HB_RETHANDLE( hDC );
}

HB_FUNC( HWG_RELEASEDC )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(2);

   if( hDC->layout )
      g_object_unref( (GObject*) hDC->layout );

   if( hDC->surface )
      cairo_surface_destroy( hDC->surface );
   cairo_destroy( hDC->cr );
   hb_xfree( hDC );
}

HB_FUNC( HWG_CREATECOMPATIBLEDC )
{
   PHWGUI_HDC hDCdest = (PHWGUI_HDC) hb_xgrab( sizeof(HWGUI_HDC) );
   PHWGUI_HDC hDCsource = (PHWGUI_HDC) HB_PARHANDLE(1);

   memset( hDCdest, 0, sizeof(HWGUI_HDC) );
   hDCdest->widget = hDCsource->widget;
   hDCdest->window = hDCsource->window;

   hDCdest->surface = cairo_surface_create_similar(cairo_get_target( hDCsource->cr ),
         CAIRO_CONTENT_COLOR_ALPHA, hb_parni(2), hb_parni(3) );
   hDCdest->cr = cairo_create( hDCdest->surface );

   hDCdest->layout = pango_cairo_create_layout( hDCdest->cr );
   hDCdest->fcolor = hDCdest->bcolor = -1;

   HB_RETHANDLE( hDCdest );
}

HB_FUNC( HWG_BITBLT )
{
   PHWGUI_HDC hDCdest = ( PHWGUI_HDC ) HB_PARHANDLE( 1 );
   PHWGUI_HDC hDCsource = ( PHWGUI_HDC ) HB_PARHANDLE( 6 );

   cairo_set_source_surface( hDCdest->cr, hDCsource->surface, hb_parni( 2 ), hb_parni( 3 ) );
   cairo_paint( hDCdest->cr );
}

HB_FUNC( HWG_CAIRO_TRANSLATE )
{
   PHWGUI_HDC hDC = ( PHWGUI_HDC ) HB_PARHANDLE( 1 );
   cairo_translate( hDC->cr, hb_parni(2), hb_parni(3) );
}

HB_FUNC( HWG_GETDRAWITEMINFO )
{
}

/*
 * DrawGrayBitmap( hDC, hBitmap, x, y )
 */
HB_FUNC( HWG_DRAWGRAYBITMAP )
{
/*
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
   gint x =  hb_parni(3);
   gint y =  hb_parni(4);

   gdk_cairo_set_source_pixbuf( hDC->cr, obj->handle, x, y );
   cairo_paint( hDC->cr );
   cairo_set_source_rgb( hDC->cr, 1, 1, 1 );
   cairo_set_operator( hDC->cr, CAIRO_OPERATOR_HSL_COLOR );
   cairo_paint( hDC->cr );
*/
}

HB_FUNC( HWG_GETCLIENTAREA )
{
   PHWGUI_PPS pps = ( PHWGUI_PPS ) HB_PARHANDLE( 1 );
   GtkWidget * widget = pps->hDC->widget;
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   GtkAllocation alloc;

   if( getFixedBox( (GObject *) widget ) )
      widget = (GtkWidget*) getFixedBox( (GObject *) widget );

   gtk_widget_get_allocation( widget, &alloc );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), alloc.width );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), alloc.height );
   hb_itemRelease( hb_itemReturn( aMetr ) );
}

HB_FUNC( HWG_GETCLIENTRECT )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   GtkAllocation alloc;

   if( getFixedBox( (GObject *) widget ) )
      widget = (GtkWidget*) getFixedBox( (GObject *) widget );

   gtk_widget_get_allocation( widget, &alloc );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), alloc.width );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), alloc.height );
   hb_itemRelease( hb_itemReturn( aMetr ) );
}

HB_FUNC( HWG_GETWINDOWRECT )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   GtkAllocation alloc;
   gtk_widget_get_allocation( widget, &alloc );

   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), alloc.width );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), alloc.height );
   hb_itemRelease( hb_itemReturn( aMetr ) );
}

void hwg_prepare_cairo_colors( long int nColor, gdouble *r, gdouble *g, gdouble *b )
{
   short int int_r, int_g, int_b;

   nColor %= ( 65536 * 256 );
   int_r = nColor % 256;
   int_g = ( ( nColor - int_r ) % 65536 ) / 256;
   int_b = ( nColor - int_r - int_g ) / 65536;

   *r = (gdouble)int_r / 255.;
   *g = (gdouble)int_g / 255.;
   *b = (gdouble)int_b / 255.;
}

/*
 * hwg_drawGradient( hDC, x1, y1, x2, y2, int type, array colors, array stops, array radiuses )
 */
HB_FUNC( HWG_DRAWGRADIENT )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = hb_parnd( 2 ), y1 = hb_parnd( 3 ), x2 = hb_parnd( 4 ), y2 = hb_parnd( 5 );
   gint type = ( HB_ISNUM(6) ) ? hb_parni( 6 ) : 1;
   PHB_ITEM pArrColor = hb_param( 7, HB_IT_ARRAY );
   long int color;
   PHB_ITEM pArrStop = hb_param( 8, HB_IT_ARRAY );
   gdouble stop;
   gint user_colors_num, colors_num, user_stops_num, i;
   cairo_pattern_t *pat = NULL;
   gdouble x_center, y_center, gr_radius;
   gdouble r, g, b;
   PHB_ITEM pArrRadius = NULL;
   int iRadius = -1;
   gint radius[4], max_r;
   gint user_radiuses_num;

   if( HB_ISNUM(9) )
      iRadius = hb_parni(9);
   else
      pArrRadius = hb_param( 9, HB_IT_ARRAY );
   if( !pArrColor || ( user_colors_num = hb_arrayLen( pArrColor ) ) == 0 )
      return;

   if( user_colors_num == 1 )
      hwg_setcolor( hDC->cr, hb_arrayGetNL( pArrColor, 1 ) );
   else
   {
      // type of gradient
      type = ( type >= 1 && type <= 9 ) ? type : 1;
      switch( type )
      {
         case 1:
            // vertical and down
            pat = cairo_pattern_create_linear( x1, y1, x1, y2 );
            break;
         case 2:
            // vertical and up
            pat = cairo_pattern_create_linear( x1, y2, x1, y1 );
            break;
         case 3:
            // horizontal and to the right
            pat = cairo_pattern_create_linear( x1, y1, x2, y1 );
            break;
         case 4:
            // horizontal and to the left
            pat = cairo_pattern_create_linear( x2, y1, x1, y1 );
            break;
         case 5:
            // diagonal right-up
            pat = cairo_pattern_create_linear( x1, y2, x2, y1 );
            break;
         case 6:
            // diagonal left-down
            pat = cairo_pattern_create_linear( x2, y1, x1, y2 );
            break;
         case 7:
            // diagonal right-down
            pat = cairo_pattern_create_linear( x1, y1, x2, y2 );
            break;
         case 8:
            // diagonal left-up
            pat = cairo_pattern_create_linear( x2, y2, x1, y1 );
            break;
         case 9:
            // radial gradient
            x_center = (x2 - x1) / 2 + x1;
            y_center = (y2 - y1) / 2 + y1;
            gr_radius = sqrt( pow(x2-x1,2) + pow(y2-y1,2) ) / 2;
            pat = cairo_pattern_create_radial(x_center, y_center, 0, x_center, y_center, gr_radius);
            break;
      }

      colors_num = user_colors_num;
      user_stops_num = ( pArrStop ) ? hb_arrayLen( pArrStop ) : 0;

      for ( i = 0; i < colors_num; i++ )
      {
         color = ( i < user_colors_num ) ? hb_arrayGetNL( pArrColor, i+1 ) : 0xFFFFFF * i;
         hwg_prepare_cairo_colors( color, &r, &g, &b );
         stop = ( i < user_stops_num ) ? hb_arrayGetND( pArrStop, i+1 ) : 1. / (gdouble)(colors_num-1) * (gdouble)i;
         cairo_pattern_add_color_stop_rgb( pat, stop, r, g, b );
      }
   }

   if( pArrRadius || iRadius > 0 ) {
      if( pArrRadius ) {
         user_radiuses_num =  hb_arrayLen( pArrRadius );
         max_r = ( x2-x1+1 > y2-y1+1 ) ? y2-y1+1 : x2-x1+1;
         max_r /= 2;

         for ( i = 0; i < 4; i++ )
         {
            radius[i] = ( i < user_radiuses_num ) ? hb_arrayGetNI( pArrRadius, i+1 ) : 0;
            radius[i] = ( radius[i] >= 0 ) ? radius[i] : 0;
            radius[i] = ( radius[i] <= max_r ) ? radius[i] : max_r;
         }
      } else
         radius[0] = radius[1] = radius[2] = radius[3] = iRadius;

      cairo_arc( hDC->cr, x1+radius[0], y1+radius[0], radius[0], M_PI, 3*M_PI/2 );
      cairo_arc( hDC->cr, x2-radius[1], y1+radius[1], radius[1], 3*M_PI/2, 0 );
      cairo_arc( hDC->cr, x2-radius[2], y2-radius[2], radius[2], 0, M_PI/2 );
      cairo_arc( hDC->cr, x1+radius[3], y2-radius[3], radius[3], M_PI/2, M_PI );
      cairo_close_path(hDC->cr);
   }
   else
      cairo_rectangle( hDC->cr, x1, y1, x2-x1+1, y2-y1+1 );

   if( user_colors_num > 1 )
      cairo_set_source( hDC->cr, pat );
   cairo_fill( hDC->cr );

   if( user_colors_num > 1 )
      cairo_pattern_destroy( pat );
}

HB_FUNC( HWG__DRAWCOMBO )
{
#if GTK_MAJOR_VERSION -0 < 3
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = (gdouble)hb_parni( 2 ), y1 = (gdouble)hb_parni( 3 ),
           x2 = (gdouble)hb_parni( 4 ), y2 = (gdouble)hb_parni( 5 ),
           nWidth = x2-x1+1, nHeight = y2-y1+1;

   hwg_setcolor( hDC->cr, 0xffffff );
   cairo_rectangle( hDC->cr, x1, y1, nWidth, nHeight );
   cairo_fill( hDC->cr );

   hwg_setcolor( hDC->cr, 0 );
   cairo_set_line_width( hDC->cr, 0.5 );

   cairo_rectangle( hDC->cr, x1, y1, nWidth, nHeight );

   cairo_move_to( hDC->cr, x1+6, y1+nHeight/2-3 );
   cairo_line_to( hDC->cr, x1+nWidth/2, y1+nHeight/2+3 );
   cairo_line_to( hDC->cr, x2-6, y1+nHeight/2-3 );

   cairo_stroke( hDC->cr );
#endif
}

HB_FUNC( HWG__DRAWCHECKBTN )
{
#if GTK_MAJOR_VERSION -0 < 3
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = (gdouble)hb_parni( 2 ), y1 = (gdouble)hb_parni( 3 ),
           y2 = (gdouble)hb_parni( 5 ),
           nHeight = y2-y1-6;
   int iSet = hb_parl(6);
   const char *cTitle = ( hb_pcount(  ) > 6 ) ? hb_parc( 7 ) : NULL;
   gchar *gcTitle;

   x1 += 2;
   y1 += 3;
   hwg_setcolor( hDC->cr, 0xffffff );
   cairo_rectangle( hDC->cr, x1, y1, nHeight, nHeight );
   cairo_fill( hDC->cr );

   hwg_setcolor( hDC->cr, 0 );
   cairo_set_line_width( hDC->cr, 1 );

   cairo_rectangle( hDC->cr, x1, y1, nHeight, nHeight );

   if( iSet )
   {
      cairo_move_to( hDC->cr, x1+2, y1+nHeight/2 );
      cairo_line_to( hDC->cr, x1+nHeight/2, y1+nHeight-2 );
      cairo_line_to( hDC->cr, x1+nHeight-1, y1 );
   }

   cairo_stroke( hDC->cr );

   if( cTitle )
   {
      gcTitle = hwg_convert_to_utf8( cTitle );
      pango_layout_set_text( hDC->layout, gcTitle, -1 );
      cairo_move_to( hDC->cr, x1 + nHeight + 4, y1-2 );
      pango_cairo_show_layout( hDC->cr, hDC->layout );
      g_free( gcTitle );
   }
#endif
}

HB_FUNC( HWG__DRAWRADIOBTN )
{
#if GTK_MAJOR_VERSION -0 < 3
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = (gdouble)hb_parni( 2 ), y1 = (gdouble)hb_parni( 3 ),
           y2 = (gdouble)hb_parni( 5 ),
           nHeight = y2-y1-4;
   int iSet = hb_parl(6);
   const char *cTitle = ( hb_pcount(  ) > 6 ) ? hb_parc( 7 ) : NULL;
   gchar *gcTitle;

   x1 += 2;
   y1 += 2;
   hwg_setcolor( hDC->cr, 0xffffff );
   cairo_arc( hDC->cr, x1+nHeight/2, y1+nHeight/2, nHeight/2, 0, 6.28 );
   cairo_fill( hDC->cr );

   hwg_setcolor( hDC->cr, 0 );
   cairo_set_line_width( hDC->cr, 1 );

   cairo_arc( hDC->cr, x1+nHeight/2, y1+nHeight/2, nHeight/2, 0, 6.28 );
   cairo_stroke( hDC->cr );

   if( iSet )
   {
      cairo_arc( hDC->cr, x1+nHeight/2, y1+nHeight/2, nHeight/2-3, 0, 6.28 );
      cairo_fill( hDC->cr );
   }

   if( cTitle )
   {
      gcTitle = hwg_convert_to_utf8( cTitle );
      pango_layout_set_text( hDC->layout, gcTitle, -1 );
      cairo_move_to( hDC->cr, x1 + nHeight + 4, y1-2 );
      pango_cairo_show_layout( hDC->cr, hDC->layout );
      g_free( gcTitle );
   }
#endif
}


/* As preparation to further versions */
HB_FUNC( HWG_LOADPNG )
{
}

/*   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   */
/*   Functions for raw bitmap support   */
/*   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   */


/* Some more functions for bitmap support
   (for example painting and stretching of bitmap images)
   are implemented in source code file "cxshade.c".
*/

/*
 === Bitmap structures ==

 Not used structures are inserted for future realeases of HWGUI.

 */

/* uint32_t : l=4, DWORD LONG  , uint16_t : l=2, WORD  uint8_t l=1,BYTE, unsigned char */

/*
 Summary of bitmap structures:

 fileheader l=14

 bitmapinfoheader l=40

 bitmapheader3x l=54
   - fileheader
   - bitmapinfoheader

 Win2xPaletteElement

 bitmapinfoheader4x

 bitmapinfoheader5x

 bitmap4x  l= 122
   -  fileheader
   -  bitmapinfoheader bitmapinfoheader
   -  bitmapinfoheader4x bitmapinfoheader4x


 WINNTBITFIELDSMASKS (RGB mask's)

 color (Win3x palette element)

 pixel

 imagedata
   - pixel
   - color

 BMPImage
   - bitmap4x
   - pixel **
   - color

*/



#pragma pack(push,1)

/* Alternative declaration:
typedef struct <name> {
 ...
}  __attribute__((packed)) <name> ;
*/

typedef struct{
    uint8_t signature[2];              /* 0  "BM" */
    uint32_t filesize;                 /* 2  Size of file in bytes */
    uint32_t reserved;                 /* 6  reserved, forever 0 */
    uint32_t fileoffset_to_pixelarray; /* 10 Start position of image data in bytes */
} fileheader;                          /* 14 l = 14 */

/* Win 3.x info header */
typedef struct{
    uint32_t dibheadersize;            /* 14  Size of this header in bytes */
    uint32_t width;                    /* 18  Image width in pixels */
    uint32_t height;                   /* 22  Image height in pixels */
    uint16_t planes;                   /* 26  Number of color planes */
    uint16_t bitsperpixel;             /* 28  Number of bits per pixel */
    uint32_t compression;              /* 30  Compression methods used */
    uint32_t imagesize;                /* 34  Size of bitmap in bytes */
    uint32_t ypixelpermeter;           /* 38  Horizontal resolution in pixels per meter */
    uint32_t xpixelpermeter;           /* 42  Vertical resolution in pixels per meter */
    uint32_t numcolorspallette;        /* 46  Number of colors in the image */
    uint32_t mostimpcolor;             /* 50  Minimum number of important colors */
} bitmapinfoheader;                    /* 54 l = 40 */


/* Color components (Win3x palette element)  */
typedef struct {
    uint8_t b; /* Blue */
    uint8_t g; /* Green */
    uint8_t r; /* Red component */
    uint8_t a; /* Reserved = 0 */
} color;

typedef struct
{
    uint8_t b;
    uint8_t g;
    uint8_t r;
    uint8_t i;
}  pixel;

/* W3.x complete header */
typedef struct {
    fileheader fileheader;             /* l = 14 */
    bitmapinfoheader bitmapinfoheader; /* l = 40 */
} bitmapheader3x;  /* l=54 */

typedef struct {
   char Blue;      /* Blue component */
   char Green;     /* Green component */
   char Red;       /* Red component */
} Win2xPaletteElement ;

/* Fields added for Windows 4.x follow this line */

typedef struct {
 uint32_t RedMask;       /* 54 Mask identifying bits of red component */
 uint32_t GreenMask;     /* 58 Mask identifying bits of green component */
 uint32_t BlueMask;      /* 62 Mask identifying bits of blue component */
 uint32_t AlphaMask;     /* Mask identifying bits of alpha component */
 uint32_t CSType;        /* Color space type */
 uint32_t RedX;          /* X coordinate of red endpoint */
 uint32_t RedY;          /* Y coordinate of red endpoint */
 uint32_t RedZ;          /* Z coordinate of red endpoint */
 uint32_t GreenX;        /* X coordinate of green endpoint */
 uint32_t GreenY;        /* Y coordinate of green endpoint */
 uint32_t GreenZ;        /* Z coordinate of green endpoint */
 uint32_t BlueX;         /* X coordinate of blue endpoint */
 uint32_t BlueY;         /* Y coordinate of blue endpoint */
 uint32_t BlueZ;         /* Z coordinate of blue endpoint */
 uint32_t GammaRed;      /* Gamma red coordinate scale value */
 uint32_t GammaGreen;    /* Gamma green coordinate scale value */
 uint32_t GammaBlue;     /* Gamma blue coordinate scale value */
} bitmapinfoheader4x;    /* l=68 */

typedef struct {
    uint32_t        intent;             /* Rendering intent */
    uint32_t        profile_data;       /* Profile data offset in byte) */
    uint32_t        profile_size;       /* Profile data size in byte */
    uint32_t        reserved;           /* 0 */
} bitmapinfoheader5x;

/* Bmp image W3.x structure for QR encoding */
typedef struct {
    bitmapheader3x bmp_header;   /* full Header of the bitmap */
    pixel **pixel_data;    /* Pixel matrix (jagged array) */
    color *palette;        /* Color palette (array) */
}  BMPImage3x;




typedef struct {
 uint32_t  RedMask;         /* Mask red component */
 uint32_t  GreenMask;       /* Mask green component */
 uint32_t  BlueMask;        /* Mask blue component */
} WINNTBITFIELDSMASKS ;



typedef struct {
    pixel **pixel_data;    /* Pixel matrix (jagged array) */
    color *palette;        /* Color palette (array) */
}  imagedata;

typedef struct {
    fileheader fileheader;                  /* l = 14 */
    bitmapinfoheader bitmapinfoheader;      /* l = 40 */
    bitmapinfoheader4x bitmapinfoheader4x;  /* l = 68 */
} bitmap4x;  /* l=122 */

typedef struct
{
    bitmap4x bmp_header;   /* full Header of the bitmap */
    pixel **pixel_data;    /* Pixel matrix (jagged array) */
    color *palette;        /* Color palette (array) */
}  BMPImage4x; /* W4x */

#pragma pack(pop)

static unsigned int cc_null(uint32_t wert)
{
    unsigned int zae ;

    zae = 0;

    if (! wert)
    {
      return 0u;
    }

    while (!(wert & 0x1))
    {
        ++zae;
        wert >>= 1;
    }

    return zae;
}


uint32_t hwg_BMPFileSizeC(
    int bmp_width,
    int bmp_height,
    int bmp_bit_depth,
    unsigned int colors
    )
{
    uint32_t image_size;
    uint32_t pad;
    uint32_t fileoffset_to_pixelarray;
    uint32_t filesize ;


    pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
    image_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad ) * bmp_height;

    fileoffset_to_pixelarray = sizeof (fileheader) + sizeof(bitmapinfoheader) +
    colors * 4 ;
    filesize = fileoffset_to_pixelarray + image_size ;

    return filesize;
}

/* Creates a C element with bitmap file image */

void * hwg_BMPNewImageC(

    int pbmp_width,
    int pbmp_height,
    int pbmp_bit_depth,
    unsigned int colors,
    uint32_t xpixelpermeter,
    uint32_t ypixelpermeter )

{
    BMPImage3x pbitmap;  /* Memory for the image with pointers */
    uint32_t image_size;
    uint32_t pad;
    uint32_t fileoffset_to_pixelarray;

    uint32_t filesize ;
    uint32_t max_colors;
//    int i;
    uint32_t i,j;
    void * bmp_locpointer;
    uint8_t * bitmap_buffer;
    uint8_t * buf;
    uint8_t tmp;
    short bit;
    char csig[2];
    uint32_t bmp_width;
    uint32_t bmp_height;
    uint32_t bmp_bit_depth;

    /* uint8_t mask1[8]; */
    uint8_t mask4[2];

    /* Reserved for later releases
    mask1[0] = 128;
    mask1[1] = 64;
    mask1[2] = 32;
    mask1[3] = 16;
    mask1[4] = 8;
    mask1[5] = 4;
    mask1[6] = 2;
    mask1[7] = 1;
   */

    mask4[0] = 240,
    mask4[1] = 15;

    max_colors = (uint32_t) 1;

    /* Fixed signature "BM" */
    csig[0] = 0x42;
    csig[1] = 0x4d;

    /* Cast for avoiding warnings in for loops (int ==> uint32_t */
     bmp_width = (uint32_t) pbmp_width;
     bmp_height = (uint32_t) pbmp_height;
     bmp_bit_depth = (uint32_t) pbmp_bit_depth;

    memset(&pbitmap, 0, sizeof (BMPImage3x));

    /* Some parameter checks */
    if (bmp_bit_depth != 1 && bmp_bit_depth != 4 && bmp_bit_depth != 8 && bmp_bit_depth != 16 && bmp_bit_depth != 24 )
    {
       return NULL;
    }

    if (bmp_width < 1 || bmp_height < 1 )
    {
       return NULL;
    }


    for (i = 0; i < bmp_bit_depth; ++i)
    {
        max_colors *= 2;
    }

    if (colors > max_colors)
    {
        /* Colors and max colors not compatible */
        return NULL;
    }

    pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
    image_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad ) * bmp_height;



    /* Pre init with 0 */
    memset(&pbitmap,0x00,sizeof(BMPImage3x) );


    fileoffset_to_pixelarray = sizeof (fileheader) + sizeof(bitmapinfoheader) +
    colors * 4 ;
    filesize = fileoffset_to_pixelarray + image_size ;

    /* Allocate memory for full file size */
    bmp_fileimg = malloc(filesize);


    /* Bitmap file header */

    memcpy( &pbitmap.bmp_header.fileheader.signature,csig,2);                     /* fixed signature */
    pbitmap.bmp_header.fileheader.filesize = filesize;                            /* Size of file in bytes */
    pbitmap.bmp_header.fileheader.reserved = 0;
    pbitmap.bmp_header.fileheader.fileoffset_to_pixelarray = fileoffset_to_pixelarray; /* Start position of image data in bytes */

    /* Bitmap information header 3.x*/
    pbitmap.bmp_header.bitmapinfoheader.dibheadersize = (uint32_t) sizeof(bitmapinfoheader); /* Size of this header in bytes */
    pbitmap.bmp_header.bitmapinfoheader.width =  bmp_width;            /* Image width in pixels */
    pbitmap.bmp_header.bitmapinfoheader.height = bmp_height;          /* Image height in pixels */
    pbitmap.bmp_header.bitmapinfoheader.planes = (uint32_t) _planes;             /* Number of color planes (must be 1) */
    pbitmap.bmp_header.bitmapinfoheader.bitsperpixel = (uint16_t) bmp_bit_depth; /* Number of bits per pixel `*/
    pbitmap.bmp_header.bitmapinfoheader.compression = _compression;              /* Compression methods used */
    pbitmap.bmp_header.bitmapinfoheader.imagesize = (uint32_t) image_size;       /* Size of bitmap in bytes (pixelbytesize) */
    pbitmap.bmp_header.bitmapinfoheader.ypixelpermeter = ypixelpermeter ;        /* Horizontal resolution in pixels per meter */
    pbitmap.bmp_header.bitmapinfoheader.xpixelpermeter = xpixelpermeter ;        /* Vertical resolution in pixels per meter */
    pbitmap.bmp_header.bitmapinfoheader.numcolorspallette = colors;              /* Number of colors in the image */
    pbitmap.bmp_header.bitmapinfoheader.mostimpcolor = colors;                   /* Minimum number of important colors */


    /* process image data */

    /* Alloc pixel data (jagged array) */
    pbitmap.pixel_data = (pixel**) malloc(bmp_height * sizeof(pixel*) );

    if ( ! pbitmap.pixel_data)
    {
       return NULL;
    }
    for (i = 0; i < bmp_height; ++i)
    {
      pbitmap.pixel_data[i] = (pixel*) calloc(bmp_width, sizeof (pixel));

      if (! pbitmap.pixel_data[i])
      {
        while (i > 0)
        {
          free( pbitmap.pixel_data[--i]);
        }
          free(pbitmap.pixel_data);
      }
    }

    /* Alloc color palette */
    pbitmap.palette = (color*) calloc(colors, sizeof (color));
    memset(&pbitmap.palette, 0x00, sizeof (color));

    /* Copy structure pbitmap (BMPImage3x) to file buffer */
    memcpy(bmp_fileimg,&pbitmap, sizeof(BMPImage3x) );

    /*
      Now until here processed:
      - Fileheader
      - Info header
      - Pixel pointer
      - Palette
     */

    /* Move pointer to end of block : start position of pixel data */
    bmp_locpointer = bmp_fileimg + fileoffset_to_pixelarray;

    /* Process initialization of  pixel data */

    /* allocate buffer for bitmap pixel data */
    bitmap_buffer = (uint8_t *) calloc(1, image_size);
    memset(bitmap_buffer,0x00,image_size);
    buf = bitmap_buffer;

    /* convert pixel data into bitmap format */
    switch (bmp_bit_depth)
    {
    /* Each byte of data represents 8 pixels, with the most significant
       bit mapped into the leftmost pixel */
    case 1:
       for (i = 0; i < bmp_height; ++i)
       {
         j = 0;
         while (j < bmp_width)
         {
           tmp = 0;
           for (bit = 7; bit >= 0 && j < bmp_width; --bit)
           {
             tmp |= (pbitmap.pixel_data[i][j].i == 0 ? 0u : 1u) << bit;
             ++j;
           }
           *buf++ = tmp;
         }
         buf += pad;
       }
       break;

    /* Each byte represents 2 pixel byte, nibble */

    case 4:
       for (i = 0; i < bmp_height; ++i)
        {
         for (j = 0; j < bmp_width; j += 2)
          {
             /* write two pixels in the one byte variable tmp */
             tmp = 0;
             /* most significant nibble */
             tmp |= pbitmap.pixel_data[i][j].i << 4;
             if (j + 1 < bmp_height)
             {
              /* least significant nibble */
               tmp |= pbitmap.pixel_data[i][j + 1].i & mask4[LO_NIBBLE];
             }
              /* write the byte in the image buffer */
              *buf++ = tmp;
          }
          /* each row has a padding to a 4 byte alignment */
          buf += pad;
        }
        break;

    /* represents 1 byte pixel */
    case 8:
       for (i = 0; i < bmp_height; ++i)
        {
         for (j = 0; j < bmp_width; ++j)
         {
           *buf++ = pbitmap.pixel_data[i][j].i;
         }

           /* each row has a padding to a 4 byte alignment */
           buf += pad;
        }
        break;

    /* 2 bytes pixel*/
    case 16:
       for (i = 0; i < bmp_height; ++i)
        {
          for (j = 0; j < bmp_width; ++j)
          {
            uint16_t *px = (uint16_t*) buf;
            *px =
             (pbitmap.pixel_data[i][j].b << cc_null(pbitmap.palette->b)) +
             (pbitmap.pixel_data[i][j].g << cc_null(pbitmap.palette->g)) +
             (pbitmap.pixel_data[i][j].r << cc_null(pbitmap.palette->r));
            buf += 2;
          }
          buf += pad;
       }
       break;

    /* 3 bytes pixel, 1 byte for one color */
    case 24:
       for (i = 0; i < bmp_height; ++i)
       {
          for (j = 0; j < bmp_width; ++j)
          {
             *buf++ = pbitmap.pixel_data[i][j].b;
             *buf++ = pbitmap.pixel_data[i][j].g;
             *buf++ = pbitmap.pixel_data[i][j].r;
          }
          /* Each row has a padding to a 4 byte alignment */
          buf += pad;
       }
       break;
     }


    /* Copy the image data to the file buffer */
    memcpy(bmp_locpointer,bitmap_buffer, image_size );

    /* Free all the memory not needed */

    if( bitmap_buffer )
      free(bitmap_buffer);
//    if ( bmp_locpointer )
//     free(bmp_locpointer);
//    if (buf)
//     free(buf);


    /* Return the pointer of complete file buffer,
       its content must be returned as Harbour string
       in the corresponding HB_FUNC()
    */

    return bmp_fileimg;

}

/* Calculates the offset to pixel array (image data) */
uint32_t hwg_BMPCalcOffsPixArrC(unsigned int colors)
   {
    uint32_t fileoffset_to_pixelarray;

    fileoffset_to_pixelarray = sizeof (fileheader) + sizeof(bitmapinfoheader) +
    colors * 4 ;

    return fileoffset_to_pixelarray;

}


/*
 Calculates the offset to palette data,
 located after the pixel matrix (jagged array)
 */


uint32_t hwg_BMPCalcOffsPalC(int bmp_height)
{
  uint32_t iret;
  iret = sizeof(bitmapheader3x) + ( bmp_height * sizeof(pixel*) );
  return iret;
}


/*  ==== HWGUI Interface function for raw bitmap support ==== */

HB_FUNC( HWG_BMPNEWIMAGE )
{

    int bmp_width;
    int bmp_height;
    int bmp_bit_depth;
    unsigned int colors;
    uint32_t xpixelpermeter;
    uint32_t ypixelpermeter;
    void * rci;
    char rcbuff[BMPFILEIMG_MAXSZ];
    uint32_t filesize ;

    bmp_width = hb_parni(1);
    bmp_height = hb_parni(2);
    bmp_bit_depth = hb_parni(3);
    colors = hb_parni(4);
    xpixelpermeter = hb_parnl(5);
    ypixelpermeter = hb_parnl(6);



    rci = hwg_BMPNewImageC(
     bmp_width,
     bmp_height,
     bmp_bit_depth,
     colors,
     xpixelpermeter,
     ypixelpermeter );


     if ( ! rci )
     {
      hb_retc("Error");
     }

    /* Calculate the file size */
    filesize = hwg_BMPFileSizeC(bmp_width, bmp_height, bmp_bit_depth, colors) ;

    if ( filesize > BMPFILEIMG_MAXSZ )
    {
      hb_retc("Error");
    }

     memcpy(&rcbuff,rci,filesize);


     hb_retclen_buffer(rcbuff,filesize);

    /* HB_RETSTR(rcbuff) stops writing bytes at first appearence of 0x00 */

}


/* Free's the allocted memory of a bitmap */
HB_FUNC( HWG_BMPDESTROY )
{
   if ( bmp_fileimg )
   {
    free(bmp_fileimg);
   }
}

/* Calculates the expected filesize of a bitmap W3.x file */
HB_FUNC( HWG_BMPFILESIZE )
{
    uint32_t image_size;
    uint32_t pad;
    uint32_t fileoffset_to_pixelarray;
    uint32_t filesize ;

    int bmp_width;
    int bmp_height;
    int bmp_bit_depth;
    unsigned int colors;

    bmp_width = hb_parni(1);
    bmp_height = hb_parni(2);
    bmp_bit_depth = hb_parni(3);
    colors = hb_parni(4);

    pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
    image_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad ) * bmp_height;

    fileoffset_to_pixelarray = sizeof (fileheader) + sizeof(bitmapinfoheader) +
    colors * 4 ;
    filesize = fileoffset_to_pixelarray + image_size ;

    hb_retnl(filesize);
}

/* Returns the size of BMPImage3x structure */
HB_FUNC( HWG_BMPSZ3X )
{
  uint32_t i;
  i = ( sizeof(BMPImage3x) );
  hb_retnl(i);
}

/* Returns the maximum size of the bitmap file size */
HB_FUNC( HWG_BMPMAXFILESZ )
{
  hb_retnl(BMPFILEIMG_MAXSZ);
}

/* Calculates the offset to pixel array (image data) */

HB_FUNC( HWG_BMPCALCOFFSPIXARR )
{

    unsigned int colors;
    uint32_t fileoffset_to_pixelarray;

    colors = hb_parni(1);

    fileoffset_to_pixelarray = hwg_BMPCalcOffsPixArrC(colors);
    hb_retnl(fileoffset_to_pixelarray);

}

/* Calculates the offset to palette data */
HB_FUNC( HWG_BMPCALCOFFSPAL )
{
  uint32_t rc;
  int bmp_height;

  bmp_height = hb_parni(1);
  rc = hwg_BMPCalcOffsPalC(bmp_height);
  hb_retnl(rc);
}

/*
  BMPImageSize(width,height,bitsperpixel)
  Calculates the imagesize of a bitmap W3x .
*/

HB_FUNC( HWG_BMPIMAGESIZE )
{
    uint32_t image_size;

    int bmp_width;
    int bmp_height;
    int bmp_bit_depth;

    uint32_t pad;

    bmp_width = hb_parni(1);
    bmp_height = hb_parni(2);
    bmp_bit_depth = hb_parni(3);


    pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
    image_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad ) * bmp_height;

   hb_retnl(image_size);

}


/*
  hwg_BMPLineSize(width,bitsperpixel)
  Returns the size of a pixel line in bytes,
  accepting the padding at end of line
*/
HB_FUNC( HWG_BMPLINESIZE )
{
    uint32_t line_size;

    int bmp_width;
    int bmp_bit_depth;

    uint32_t pad;

    bmp_width = hb_parni(1);
    bmp_bit_depth = hb_parni(2);


    pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
    line_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad );

    hb_retnl(line_size);

}

/*   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   */
/*   End of Functions for raw bitmap support   */
/*   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   */

/*
* Increases the size of a QR code image
* cqrcode : The QR code in text format
* nlen    : Pass LEN(cqrcode)
* nzoom   : The zoom factor 1 ... n
*           The default is 1 (no zoom)
* Return the new QR code text string

hwg_QRCodeZoom_C(cqrcode,nlen,<nzoom>)

*/

HB_FUNC ( HWG_QRCODEZOOM_C )
{
  int i , j, leofq;
  // leofq: 0 = .F. , 1 = .T.
  int nzoom, nlen;
  int cptr,lptr;
  char cqrcode [16385];
  char cout[16385];
  char cLine[8192];
  const char *hString;




  nlen  =  hb_parni( 2 );
  nzoom =  ( HB_ISNIL( 3 ) ? 1 : hb_parni( 3 )  );


  lptr = 0;  // Position in a line
  cptr = 0;  // Position in cout
  memset(&cout , 0x00, 16385 );
  memset(&cLine , 0x00, 8192 );

  // Copy the image into char array
  hString = hb_parc( 1 );
  memcpy(&cqrcode,hString,nlen);



  if ( nzoom < 1 )
  {
    hb_retclen(cqrcode,nlen);
  }


leofq = 0;
// i: Position in cqrcode

for (i = 0 ; i < nlen ; i++ )
{
 if ( leofq == 0 )
 {
  if ( cqrcode[i] == 10 )
  {
    if ( ! ( cqrcode[ i + 1 ] == 32 )  )
    {
      // Empty line following, stop here
      leofq = 1;
    }
    // Count line ending and start with new line

    // Replicate line with zoom factor
    // and add line to output string
        for(j = 1 ; j <= nzoom ; j++ )
        {
          memcpy(&cout[cptr],&cLine,lptr);
          cout[cptr + lptr + 1 ] = 10;
          cptr = cptr + lptr + 2; // Next line
        }
        lptr = 0;
        memset(&cLine , 0x00, 8192 );
  }
  else  // SUBSTR " "
  {
    // Replicate characters in line with zoom factor

    for(j = 1 ; j <= nzoom ; j++ )
    {
      cLine[lptr] = cqrcode[i];
      lptr++;
    }
    // Set line ending
    cLine[lptr] = 10;


  }  // is CHR(10)
 }   // .NOT. leofq

} // NEXT

  if (lptr > 0)
  {
      memcpy(&cout[cptr],&cLine,lptr);
      cout[cptr + lptr + 1] = 10;
      cptr = cptr + lptr + 2; // Next line
  }

// Empty line as mark for EOF


   cout[cptr + 1] = 10;
   cptr++;
   cptr++;

   hb_retclen(cout,cptr);

}


/* ================== EOF of draw.c ========================== */

