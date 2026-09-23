/*
 * $Id: draw.c 3636 2025-04-22 13:47:40Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level painting functions
 *
 * Copyright 2013 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port — target: GTK 4.24+
 */

#include "guilib.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"

#include <cairo.h>
#include <glib.h>
#include <gtk/gtk.h>

#include "hwgtk4.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

#include <math.h>

#include "warnings.h"

/* Define fixed parameters for bitmap */
#define BMPFILEIMG_MAXSZ 131072
#define _planes          1
#define _compression     0

#define HI_NIBBLE    0
#define LO_NIBBLE    1
#define MINIMUM(a, b) ((a) < (b) ? (a) : (b))
#define PS_SOLID     0

extern GtkWidget *hMainWindow;
extern GtkFixed  *getFixedBox( GObject *handle );

static void     *bmp_fileimg   = NULL;
static long int  nCurrPenClr   = 0;
static long int  nCurrBrushClr = 0xffffff;

/* =====================================================================
 *  Live cairo_t bridge (set by window.c / control.c around WM_PAINT)
 * ===================================================================== */
cairo_t   *hwg_current_cr     = NULL;
GtkWidget *hwg_current_widget = NULL;


/* =====================================================================
 *  Color helpers — GdkRGBA (GdkColor was removed in GTK4)
 * ===================================================================== */
void hwg_parse_color( HB_ULONG ncolor, GdkRGBA *pColor )
{
    pColor->red   = ( ( ncolor >> 16 ) & 0xff ) / 255.0;
    pColor->green = ( ( ncolor >>  8 ) & 0xff ) / 255.0;
    pColor->blue  = (   ncolor        & 0xff ) / 255.0;
    pColor->alpha = 1.0;
}

HB_ULONG hwg_gdk_color( const GdkRGBA *pColor )
{
    return ( ( (HB_ULONG)( pColor->red   * 255.0 ) & 0xff ) << 16 ) |
    ( ( (HB_ULONG)( pColor->green * 255.0 ) & 0xff ) <<  8 ) |
    (   (HB_ULONG)( pColor->blue  * 255.0 ) & 0xff );
}

void hwg_setcolor( cairo_t *cr, long int nColor )
{
    short int r, g, b;

    nColor %= ( 65536 * 256 );
    r = nColor % 256;
    g = ( ( nColor - r ) % 65536 ) / 256;
    b = ( nColor - g - r ) / 65536;

    cairo_set_source_rgb( cr,
                          ( (double) r ) / 255.,
                          ( (double) g ) / 255.,
                          ( (double) b ) / 255. );
}


void hwg_SelectObject( PHWGUI_HDC hDC, HWGUI_HDC_OBJECT *obj )
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
            pango_layout_set_attributes( hDC->layout, ((PHWGUI_FONT)obj)->attrs );
    }
}

GdkPixbuf *alpha2pixbuf( GdkPixbuf *hPixIn, long int nColor )
{
    short int r, g, b;

    r = nColor % 256;
    g = ( ( nColor - r ) % 65536 ) / 256;
    b = ( nColor - g - r ) / 65536;
    return gdk_pixbuf_add_alpha( hPixIn, 1,
                                 (guchar) r, (guchar) g, (guchar) b );
}

HB_FUNC( HWG_ALPHA2PIXBUF )
{
    PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(1);
    GdkPixbuf *handle;
    long int nColor = hb_parnl(2);

    if( obj && obj->handle && obj->trcolor != nColor )
    {
        handle = alpha2pixbuf( obj->handle, nColor );
        g_object_unref( (GObject*) obj->handle );
        obj->handle  = handle;
        obj->trcolor = nColor;
    }
}


/* =====================================================================
 *  Redraw / invalidation
 * ===================================================================== */
HB_FUNC( HWG_INVALIDATERECT )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE(1);
    if( widget && GTK_IS_WIDGET( widget ) )
        gtk_widget_queue_draw( widget );
}

HB_FUNC( HWG_REDRAWWINDOW )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE(1);
    if( widget && GTK_IS_WIDGET( widget ) )
        gtk_widget_queue_draw( widget );
}


/* =====================================================================
 *  Cairo drawing primitives
 * ===================================================================== */
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

HB_FUNC( HWG_PIE ) { }

HB_FUNC( HWG_TRIANGLE )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    int x1 = hb_parni(2), y1 = hb_parni(3);
    int x2 = hb_parni(4), y2 = hb_parni(5);
    int x3 = hb_parni(6), y3 = hb_parni(7);
    PHWGUI_PEN hPen = HB_ISNIL(8) ? NULL : (PHWGUI_PEN) HB_PARHANDLE(8);

    if( hPen ) hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
    else       hwg_setcolor( hDC->cr, nCurrPenClr );

    cairo_move_to( hDC->cr, x1, y1 );
    cairo_line_to( hDC->cr, x2, y2 );
    cairo_line_to( hDC->cr, x3, y3 );
    cairo_line_to( hDC->cr, x1, y1 );
    cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_TRIANGLE_FILLED )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    int x1 = hb_parni(2), y1 = hb_parni(3);
    int x2 = hb_parni(4), y2 = hb_parni(5);
    int x3 = hb_parni(6), y3 = hb_parni(7);
    PHWGUI_PEN   hPen   = NULL;
    PHWGUI_BRUSH hBrush = HB_ISNIL(9) ? NULL : (PHWGUI_BRUSH) HB_PARHANDLE(9);
    int bNullPen = 0;

    if( hBrush ) hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hBrush );
    else         hwg_setcolor( hDC->cr, nCurrBrushClr );

    cairo_move_to( hDC->cr, x1, y1 );
    cairo_line_to( hDC->cr, x2, y2 );
    cairo_line_to( hDC->cr, x3, y3 );
    cairo_line_to( hDC->cr, x1, y1 );
    cairo_fill( hDC->cr );

    if( !HB_ISNIL(8) ) {
        if( HB_ISLOG(8) ) {
            if( !hb_parl(8) ) bNullPen = 1;
        } else {
            hPen = (PHWGUI_PEN) HB_PARHANDLE(8);
            hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
        }
    }
    if( !bNullPen ) {
        if( !hPen ) hwg_setcolor( hDC->cr, nCurrPenClr );
        cairo_move_to( hDC->cr, x1, y1 );
        cairo_line_to( hDC->cr, x2, y2 );
        cairo_line_to( hDC->cr, x3, y3 );
        cairo_line_to( hDC->cr, x1, y1 );
        cairo_stroke( hDC->cr );
    }
}

HB_FUNC( HWG_RECTANGLE )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    int x1 = hb_parni(2), y1 = hb_parni(3);
    PHWGUI_PEN hPen = HB_ISNIL(6) ? NULL : (PHWGUI_PEN) HB_PARHANDLE(6);

    if( hPen ) hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
    else       hwg_setcolor( hDC->cr, nCurrPenClr );

    cairo_rectangle( hDC->cr, x1, y1,
                     (double)(hb_parni(4)-x1+1), (double)(hb_parni(5)-y1+1) );
    cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_RECTANGLE_FILLED )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    int x1 = hb_parni(2), y1 = hb_parni(3);
    PHWGUI_PEN   hPen   = NULL;
    PHWGUI_BRUSH hBrush = HB_ISNIL(7) ? NULL : (PHWGUI_BRUSH) HB_PARHANDLE(7);
    int bNullPen = 0;

    if( hBrush ) hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hBrush );
    else         hwg_setcolor( hDC->cr, nCurrBrushClr );

    cairo_rectangle( hDC->cr, x1, y1,
                     (double)(hb_parni(4)-x1+1), (double)(hb_parni(5)-y1+1) );
    cairo_fill( hDC->cr );

    if( !HB_ISNIL(6) ) {
        if( HB_ISLOG(6) ) {
            if( !hb_parl(6) ) bNullPen = 1;
        } else {
            hPen = (PHWGUI_PEN) HB_PARHANDLE(6);
            hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
        }
    }
    if( !bNullPen ) {
        if( !hPen ) hwg_setcolor( hDC->cr, nCurrPenClr );
        cairo_rectangle( hDC->cr, x1, y1,
                         (double)(hb_parni(4)-x1+1), (double)(hb_parni(5)-y1+1) );
        cairo_stroke( hDC->cr );
    }
}

HB_FUNC( HWG_ELLIPSE )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    int x1 = hb_parni(2), y1 = hb_parni(3), x2 = hb_parni(4), y2 = hb_parni(5);
    PHWGUI_PEN hPen = HB_ISNIL(6) ? NULL : (PHWGUI_PEN) HB_PARHANDLE(6);

    if( hPen ) hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
    else       hwg_setcolor( hDC->cr, nCurrPenClr );

    cairo_arc( hDC->cr, x1+(x2-x1)/2.0, y1+(y2-y1)/2.0, (x2-x1)/2.0, 0, 6.28 );
    cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_ELLIPSE_FILLED )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    int x1 = hb_parni(2), y1 = hb_parni(3), x2 = hb_parni(4), y2 = hb_parni(5);
    PHWGUI_BRUSH hBrush = HB_ISNIL(7) ? NULL : (PHWGUI_BRUSH) HB_PARHANDLE(7);
    PHWGUI_PEN   hPen   = NULL;
    int bNullPen = 0;

    if( hBrush ) hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hBrush );
    else         hwg_setcolor( hDC->cr, nCurrBrushClr );

    cairo_arc( hDC->cr, x1+(x2-x1)/2.0, y1+(y2-y1)/2.0, (x2-x1)/2.0, 0, 6.28 );
    cairo_fill( hDC->cr );

    if( !HB_ISNIL(6) ) {
        if( HB_ISLOG(6) ) {
            if( !hb_parl(6) ) bNullPen = 1;
        } else {
            hPen = (PHWGUI_PEN) HB_PARHANDLE(6);
            hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
        }
    }
    if( !bNullPen ) {
        if( !hPen ) hwg_setcolor( hDC->cr, nCurrPenClr );
        cairo_arc( hDC->cr, x1+(x2-x1)/2.0, y1+(y2-y1)/2.0, (x2-x1)/2.0, 0, 6.28 );
        cairo_stroke( hDC->cr );
    }
}

HB_FUNC( HWG_ROUNDRECT )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    gdouble x1 = hb_parnd(2), y1 = hb_parnd(3), x2 = hb_parnd(4), y2 = hb_parnd(5);
    gdouble radius = hb_parnd(6);
    PHWGUI_PEN hPen = HB_ISNIL(7) ? NULL : (PHWGUI_PEN) HB_PARHANDLE(7);

    if( hPen ) hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
    else       hwg_setcolor( hDC->cr, nCurrPenClr );

    cairo_new_sub_path( hDC->cr );
    cairo_arc( hDC->cr, x1+radius, y1+radius, radius, M_PI, 3*M_PI/2 );
    cairo_arc( hDC->cr, x2-radius, y1+radius, radius, 3*M_PI/2, 0 );
    cairo_arc( hDC->cr, x2-radius, y2-radius, radius, 0, M_PI/2 );
    cairo_arc( hDC->cr, x1+radius, y2-radius, radius, M_PI/2, M_PI );
    cairo_close_path( hDC->cr );
    cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_ROUNDRECT_FILLED )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    gdouble x1 = hb_parnd(2), y1 = hb_parnd(3), x2 = hb_parnd(4), y2 = hb_parnd(5);
    gdouble radius = hb_parnd(6);
    PHWGUI_BRUSH brush = HB_ISNIL(8) ? NULL : (PHWGUI_BRUSH) HB_PARHANDLE(8);
    PHWGUI_PEN   hPen  = NULL;
    int bNullPen = 0;

    cairo_new_sub_path( hDC->cr );
    if( brush ) hwg_setcolor( hDC->cr, brush->color );
    else        hwg_setcolor( hDC->cr, nCurrBrushClr );

    cairo_arc( hDC->cr, x1+radius, y1+radius, radius, M_PI, 3*M_PI/2 );
    cairo_arc( hDC->cr, x2-radius, y1+radius, radius, 3*M_PI/2, 0 );
    cairo_arc( hDC->cr, x2-radius, y2-radius, radius, 0, M_PI/2 );
    cairo_arc( hDC->cr, x1+radius, y2-radius, radius, M_PI/2, M_PI );
    cairo_close_path( hDC->cr );
    cairo_fill( hDC->cr );

    if( !HB_ISNIL(7) ) {
        if( HB_ISLOG(7) ) {
            if( !hb_parl(7) ) bNullPen = 1;
        } else {
            hPen = (PHWGUI_PEN) HB_PARHANDLE(7);
            hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
        }
    }
    if( !bNullPen ) {
        if( !hPen ) hwg_setcolor( hDC->cr, nCurrPenClr );
        cairo_arc( hDC->cr, x1+radius, y1+radius, radius, M_PI, 3*M_PI/2 );
        cairo_arc( hDC->cr, x2-radius, y1+radius, radius, 3*M_PI/2, 0 );
        cairo_arc( hDC->cr, x2-radius, y2-radius, radius, 0, M_PI/2 );
        cairo_arc( hDC->cr, x1+radius, y2-radius, radius, M_PI/2, M_PI );
        cairo_close_path( hDC->cr );
        cairo_stroke( hDC->cr );
    }
}

HB_FUNC( HWG_CIRCLESECTOR )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    gdouble x1 = hb_parnd(2), y1 = hb_parnd(3), radius = hb_parnd(4);
    int iAngle1 = -hb_parni(5), iAngle2 = iAngle1-hb_parni(6), i;
    PHWGUI_PEN hPen = HB_ISNIL(7) ? NULL : (PHWGUI_PEN) HB_PARHANDLE(7);

    if( hPen ) hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
    else       hwg_setcolor( hDC->cr, nCurrPenClr );

    if( iAngle2 < iAngle1 ) { i = iAngle1; iAngle1 = iAngle2; iAngle2 = i; }
    cairo_arc( hDC->cr, x1, y1, radius, iAngle1*M_PI/180., iAngle2*M_PI/180. );
    cairo_line_to( hDC->cr, x1, y1 );
    cairo_arc( hDC->cr, x1, y1, radius, iAngle1*M_PI/180., iAngle2*M_PI/180. );
    cairo_line_to( hDC->cr, x1, y1 );
    cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_CIRCLESECTOR_FILLED )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    gdouble x1 = hb_parnd(2), y1 = hb_parnd(3), radius = hb_parnd(4);
    int iAngle1 = -hb_parni(5), iAngle2 = iAngle1-hb_parni(6), i;
    PHWGUI_BRUSH brush = HB_ISNIL(8) ? NULL : (PHWGUI_BRUSH) HB_PARHANDLE(8);
    PHWGUI_PEN   hPen  = NULL;
    int bNullPen = 0;

    if( brush ) hwg_setcolor( hDC->cr, brush->color );
    else        hwg_setcolor( hDC->cr, nCurrBrushClr );

    if( iAngle2 < iAngle1 ) { i = iAngle1; iAngle1 = iAngle2; iAngle2 = i; }
    cairo_arc( hDC->cr, x1, y1, radius, iAngle1*M_PI/180., iAngle2*M_PI/180. );
    cairo_line_to( hDC->cr, x1, y1 );
    cairo_arc( hDC->cr, x1, y1, radius, iAngle1*M_PI/180., iAngle2*M_PI/180. );
    cairo_line_to( hDC->cr, x1, y1 );
    cairo_fill( hDC->cr );

    if( !HB_ISNIL(7) ) {
        if( HB_ISLOG(7) ) {
            if( !hb_parl(7) ) bNullPen = 1;
        } else {
            hPen = (PHWGUI_PEN) HB_PARHANDLE(7);
            hwg_SelectObject( hDC, (HWGUI_HDC_OBJECT*)hPen );
        }
    }
    if( !bNullPen ) {
        if( !hPen ) hwg_setcolor( hDC->cr, nCurrPenClr );
        cairo_arc( hDC->cr, x1, y1, radius, iAngle1*M_PI/180., iAngle2*M_PI/180. );
        cairo_line_to( hDC->cr, x1, y1 );
        cairo_arc( hDC->cr, x1, y1, radius, iAngle1*M_PI/180., iAngle2*M_PI/180. );
        cairo_line_to( hDC->cr, x1, y1 );
        cairo_stroke( hDC->cr );
    }
}

HB_FUNC( HWG_FILLRECT )
{
    int x1 = hb_parni(2), y1 = hb_parni(3);
    PHWGUI_HDC   hDC   = (PHWGUI_HDC) HB_PARHANDLE(1);
    PHWGUI_BRUSH brush = (PHWGUI_BRUSH) HB_PARHANDLE(6);

    hwg_setcolor( hDC->cr, brush->color );
    cairo_rectangle( hDC->cr, x1, y1,
                     (double)(hb_parni(4)-x1+1), (double)(hb_parni(5)-y1+1) );
    cairo_fill( hDC->cr );
}

HB_FUNC( HWG_ARC )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    gdouble x1 = hb_parnd(2), y1 = hb_parnd(3), radius = hb_parnd(4);
    int iAngle1 = hb_parni(5), iAngle2 = hb_parni(6);

    cairo_new_sub_path( hDC->cr );
    hwg_setcolor( hDC->cr, nCurrPenClr );
    cairo_arc( hDC->cr, x1, y1, radius, iAngle1*M_PI/180., iAngle2*M_PI/180. );
    cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_DRAWGRID )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    int x1 = hb_parni(2), y1 = hb_parni(3), x2 = hb_parni(4), y2 = hb_parni(5);
    int n = HB_ISNIL(6) ? 4 : hb_parni(6);
    unsigned int uiColor = HB_ISNIL(7) ? 0 : (unsigned int) hb_parnl(7);
    int i, j;

    hwg_setcolor( hDC->cr, uiColor );
    for( i = x1+n; i < x2; i += n )
        for( j = y1+n; j < y2; j += n )
            cairo_rectangle( hDC->cr, (double)i, (double)j, 1, 1 );
    cairo_fill( hDC->cr );
}


/* =====================================================================
 *  Button / edge drawing — GtkStyle was removed; use classic palette
 * ===================================================================== */
#define HWG_STYLE_BG    0x00d0d0d0
#define HWG_STYLE_LIGHT 0x00ffffff
#define HWG_STYLE_MID   0x00a0a0a0
#define HWG_STYLE_DARK  0x00505050

HB_FUNC( HWG_DRAWBUTTON )
{
    PHWGUI_HDC   hDC    = (PHWGUI_HDC) HB_PARHANDLE(1);
    int left   = hb_parni(2);
    int top    = hb_parni(3);
    int right  = hb_parni(4);
    int bottom = hb_parni(5);
    unsigned int iType = hb_parni(6);

    if( iType == 0 )
    {
        hwg_setcolor( hDC->cr, HWG_STYLE_BG );
        cairo_rectangle( hDC->cr, left, top,
                         (double)(right-left+1), (double)(bottom-top+1) );
        cairo_fill( hDC->cr );
    }
    else
    {
        hwg_setcolor( hDC->cr, ( iType & 2 ) ? HWG_STYLE_MID : HWG_STYLE_LIGHT );
        cairo_rectangle( hDC->cr, left, top,
                         (double)(right-left+1), (double)(bottom-top+1) );
        cairo_fill( hDC->cr );

        left++; top++;
        hwg_setcolor( hDC->cr,
                      ( iType & 2 ) ? HWG_STYLE_LIGHT :
                      ( ( iType & 4 ) ? HWG_STYLE_DARK : HWG_STYLE_MID ) );
        cairo_rectangle( hDC->cr, left, top,
                         (double)(right-left+1), (double)(bottom-top+1) );
        cairo_fill( hDC->cr );

        right--; bottom--;
        right--; bottom--;
        if( iType & 4 )
        {
            hwg_setcolor( hDC->cr, ( iType & 2 ) ? HWG_STYLE_MID : HWG_STYLE_LIGHT );
            cairo_rectangle( hDC->cr, left, top,
                             (double)(right-left+1), (double)(bottom-top+1) );
            cairo_fill( hDC->cr );

            left++; top++;
            hwg_setcolor( hDC->cr, ( iType & 2 ) ? HWG_STYLE_LIGHT : HWG_STYLE_MID );
            cairo_rectangle( hDC->cr, left, top,
                             (double)(right-left+1), (double)(bottom-top+1) );
            cairo_fill( hDC->cr );

            right--; bottom--;
        }
        hwg_setcolor( hDC->cr, HWG_STYLE_BG );
        cairo_rectangle( hDC->cr, left, top,
                         (double)(right-left+1), (double)(bottom-top+1) );
        cairo_fill( hDC->cr );
    }
}

void hwg_gtk_drawedge( PHWGUI_HDC hDC, int left, int top,
                       int right, int bottom, unsigned int iType )
{
    hwg_setcolor( hDC->cr, ( iType & 2 ) ? HWG_STYLE_MID : HWG_STYLE_LIGHT );
    cairo_rectangle( hDC->cr, left, top,
                     (double)(right-left+1), (double)(bottom-top+1) );
    cairo_stroke( hDC->cr );

    left++; top++;
    hwg_setcolor( hDC->cr,
                  ( iType & 2 ) ? HWG_STYLE_LIGHT :
                  ( ( iType & 4 ) ? HWG_STYLE_DARK : HWG_STYLE_MID ) );
    cairo_rectangle( hDC->cr, left, top,
                     (double)(right-left+1), (double)(bottom-top+1) );
    cairo_stroke( hDC->cr );

    right--; bottom--;
    right--; bottom--;
    if( iType & 4 )
    {
        hwg_setcolor( hDC->cr, ( iType & 2 ) ? HWG_STYLE_MID : HWG_STYLE_LIGHT );
        cairo_rectangle( hDC->cr, left, top,
                         (double)(right-left+1), (double)(bottom-top+1) );
        cairo_stroke( hDC->cr );

        left++; top++;
        hwg_setcolor( hDC->cr, ( iType & 2 ) ? HWG_STYLE_LIGHT : HWG_STYLE_MID );
        cairo_rectangle( hDC->cr, left, top,
                         (double)(right-left+1), (double)(bottom-top+1) );
        cairo_stroke( hDC->cr );

        right--; bottom--;
    }
    hwg_setcolor( hDC->cr, HWG_STYLE_BG );
    cairo_rectangle( hDC->cr, left, top,
                     (double)(right-left+1), (double)(bottom-top+1) );
    cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_GTK_DRAWEDGE )
{
    hwg_gtk_drawedge( (PHWGUI_HDC) HB_PARHANDLE(1),
                      hb_parni(2), hb_parni(3),
                      hb_parni(4), hb_parni(5), hb_parni(6) );
}


HB_FUNC( HWG_LOADICON )  { }
HB_FUNC( HWG_LOADIMAGE ) { }
HB_FUNC( HWG_LOADBITMAP ){ }


/* =====================================================================
 *  Window -> bitmap
 *
 *  GTK4 has no public API to capture an arbitrary widget through
 *  gtk_widget_snapshot_child(): that function may only be called from
 *  inside the parent's "snapshot" vfunc.  The supported approach is to
 *  wrap the widget in a GtkWidgetPaintable (a GdkPaintable) and render
 *  it into a GtkSnapshot from any context.  This also works for
 *  toplevels, as long as the widget is mapped.
 * ===================================================================== */
HB_FUNC( HWG_WINDOW2BITMAP )
{
    GtkWidget       *widget = (GtkWidget*) HB_PARHANDLE(1);
    int              x      = hb_parni(2);
    int              y      = hb_parni(3);
    int              w      = hb_parni(4);
    int              h      = hb_parni(5);
    GdkPaintable    *paintable;
    GtkSnapshot     *snapshot;
    GskRenderNode   *node;
    cairo_surface_t *surface;
    cairo_t         *cr;
    GdkPixbuf       *pixbuf = NULL;

    if( !widget || !GTK_IS_WIDGET( widget ) || w < 1 || h < 1 )
    {
        hb_ret();
        return;
    }

    /* The widget must be mapped, otherwise it has no drawable content. */
    if( !gtk_widget_get_mapped( widget ) )
    {
        hb_ret();
        return;
    }

    /* Wrap the widget into a paintable object. */
    paintable = gtk_widget_paintable_new( widget );

    /* Snapshot the paintable at the requested size. */
    snapshot = gtk_snapshot_new();
    gdk_paintable_snapshot( paintable, snapshot, (double) w, (double) h );
    node = gtk_snapshot_free_to_node( snapshot );

    /* Rasterize the render node into a cairo image surface. */
    surface = cairo_image_surface_create( CAIRO_FORMAT_ARGB32, w, h );
    cr      = cairo_create( surface );
    gsk_render_node_draw( node, cr );
    cairo_destroy( cr );
    gsk_render_node_unref( node );
    g_object_unref( paintable );

    /* Extract a GdkPixbuf from the surface. */
    pixbuf = gdk_pixbuf_get_from_surface( surface, x, y, w, h );
    cairo_surface_destroy( surface );

    if( pixbuf )
    {
        PHWGUI_PIXBUF hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
        hpix->type    = HWGUI_OBJECT_PIXBUF;
        hpix->handle  = pixbuf;
        hpix->trcolor = -1;
        HB_RETHANDLE( hpix );
    }
    else
        hb_ret();
}


/* =====================================================================
 *  Bitmap drawing — uses GDK-Cairo bridge
 * ===================================================================== */
HB_FUNC( HWG_DRAWBITMAP )
{
    PHWGUI_HDC    hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
    GdkPixbuf *pixbuf;
    gint x = hb_parni(4), y = hb_parni(5);
    gint srcWidth  = gdk_pixbuf_get_width(  obj->handle );
    gint srcHeight = gdk_pixbuf_get_height( obj->handle );
    gint destWidth  = ( hb_pcount() >= 5 && !HB_ISNIL(6) ) ? hb_parni(6) : srcWidth;
    gint destHeight = ( hb_pcount() >= 6 && !HB_ISNIL(7) ) ? hb_parni(7) : srcHeight;

    if( srcWidth == destWidth && srcHeight == destHeight ) {
        gdk_cairo_set_source_pixbuf( hDC->cr, obj->handle, x, y );
        cairo_paint( hDC->cr );
    } else {
        pixbuf = gdk_pixbuf_scale_simple( obj->handle, destWidth, destHeight, GDK_INTERP_HYPER );
        gdk_cairo_set_source_pixbuf( hDC->cr, pixbuf, x, y );
        cairo_paint( hDC->cr );
        g_object_unref( (GObject*) pixbuf );
    }
}

HB_FUNC( HWG_DRAWTRANSPARENTBITMAP )
{
    PHWGUI_HDC    hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
    GdkPixbuf *pixbuf;
    gint x = hb_parni(3), y = hb_parni(4);
    long int nColor = hb_parnl(5);
    gint srcWidth  = gdk_pixbuf_get_width(  obj->handle );
    gint srcHeight = gdk_pixbuf_get_height( obj->handle );
    gint destWidth  = ( hb_pcount() >= 5 && !HB_ISNIL(6) ) ? hb_parni(6) : srcWidth;
    gint destHeight = ( hb_pcount() >= 6 && !HB_ISNIL(7) ) ? hb_parni(7) : srcHeight;

    if( obj->trcolor != nColor ) {
        pixbuf = alpha2pixbuf( obj->handle, nColor );
        g_object_unref( (GObject*) obj->handle );
        obj->handle  = pixbuf;
        obj->trcolor = nColor;
    }

    if( srcWidth == destWidth && srcHeight == destHeight ) {
        gdk_cairo_set_source_pixbuf( hDC->cr, obj->handle, x, y );
        cairo_paint( hDC->cr );
    } else {
        pixbuf = gdk_pixbuf_scale_simple( obj->handle, destWidth, destHeight, GDK_INTERP_HYPER );
        gdk_cairo_set_source_pixbuf( hDC->cr, pixbuf, x, y );
        cairo_paint( hDC->cr );
        g_object_unref( (GObject*) pixbuf );
    }
}

HB_FUNC( HWG_SPREADBITMAP )
{
    PHWGUI_HDC    hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
    GtkWidget    *widget = hDC->widget;
    GdkPixbuf *pixbuf;
    int nWidth, nHeight, x1, x2, y1, y2, nw, nh;
    int nLeft   = HB_ISNUM(3) ? hb_parni(3) : 0;
    int nTop    = HB_ISNUM(4) ? hb_parni(4) : 0;
    int nRight  = HB_ISNUM(5) ? hb_parni(5) : 0;
    int nBottom = HB_ISNUM(6) ? hb_parni(6) : 0;

    if( nLeft == 0 && nRight == 0 ) {
        nLeft = nTop = 0;
        nRight  = gtk_widget_get_width(  widget );
        nBottom = gtk_widget_get_height( widget );
    }

    x1 = y1 = 0;
    x2 = nRight  - nLeft + 1;
    y2 = nBottom - nTop  + 1;

    pixbuf = gdk_pixbuf_new( GDK_COLORSPACE_RGB, 0,
                             gdk_pixbuf_get_bits_per_sample( obj->handle ), x2-x1+1, y2-y1+1 );

    nWidth  = gdk_pixbuf_get_width(  obj->handle );
    nHeight = gdk_pixbuf_get_height( obj->handle );
    while( y1 < y2 ) {
        nh = ( y2-y1 >= nHeight ) ? nHeight : y2-y1;
        while( x1 < x2 ) {
            nw = ( x2-x1 >= nWidth ) ? nWidth : x2-x1;
            gdk_pixbuf_copy_area( (const GdkPixbuf*) obj->handle, 0, 0, nw, nh,
                                  pixbuf, x1, y1 );
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
    PHB_ITEM aMetr = hb_itemArrayNew( 2 );
    PHB_ITEM temp;

    temp = hb_itemPutNL( NULL, gdk_pixbuf_get_width(  obj->handle ) );
    hb_itemArrayPut( aMetr, 1, temp ); hb_itemRelease( temp );

    temp = hb_itemPutNL( NULL, gdk_pixbuf_get_height( obj->handle ) );
    hb_itemArrayPut( aMetr, 2, temp ); hb_itemRelease( temp );

    hb_itemRelease( hb_itemReturn( aMetr ) );
}

HB_FUNC( HWG_OPENBITMAP )
{
    PHWGUI_PIXBUF hpix;
    GdkPixbuf *handle = gdk_pixbuf_new_from_file( hb_parc(1), NULL );

    if( handle ) {
        hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
        hpix->type    = HWGUI_OBJECT_PIXBUF;
        hpix->handle  = handle;
        hpix->trcolor = -1;
        HB_RETHANDLE( hpix );
    }
}

HB_FUNC( HWG_SAVEBITMAP )
{
    PHWGUI_PIXBUF hpix = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
    const char *szType = HB_ISCHAR(3) ? hb_parc(3) : "bmp";
    GError *error = NULL;
    gboolean ok;

    ok = gdk_pixbuf_save( hpix->handle, hb_parc(1), szType, &error, NULL );
    if( error ) g_error_free( error );
    hb_retl( ok );
}

HB_FUNC( HWG_OPENIMAGE )
{
    PHWGUI_PIXBUF hpix;
    short int iString = HB_ISNIL(2) ? 0 : hb_parl(2);
    GdkPixbuf *handle = NULL;
    int width  = HB_ISNIL(3) ? 0 : hb_parni(3);
    int height = HB_ISNIL(4) ? 0 : hb_parni(4);

    if( iString ) {
        guint8 *buf = (guint8*) hb_parc(1);
        short int iOk;
        GdkPixbufLoader *loader = gdk_pixbuf_loader_new();
        iOk = gdk_pixbuf_loader_write( loader, buf, hb_parclen(1), NULL );
        gdk_pixbuf_loader_close( loader, NULL );
        if( iOk ) handle = gdk_pixbuf_loader_get_pixbuf( loader );
    } else {
        if( width > 0 && height > 0 )
            handle = gdk_pixbuf_new_from_file_at_scale( hb_parc(1), width, height, TRUE, NULL );
        else
            handle = gdk_pixbuf_new_from_file( hb_parc(1), NULL );
    }
    if( handle ) {
        hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
        hpix->type    = HWGUI_OBJECT_PIXBUF;
        hpix->handle  = handle;
        hpix->trcolor = -1;
        HB_RETHANDLE( hpix );
    }
}

HB_FUNC( HWG_DRAWICON ) { }

HB_FUNC( HWG_GETSYSCOLOR )
{
    hb_retnl( 0x00d0d0d0 );
}


/* =====================================================================
 *  Pen / brush / font objects
 * ===================================================================== */
HB_FUNC( HWG_CREATEPEN )
{
    PHWGUI_PEN hpen = (PHWGUI_PEN) hb_xgrab( sizeof(HWGUI_PEN) );
    hpen->type  = HWGUI_OBJECT_PEN;
    hpen->style = hb_parni(1);
    hpen->width = hb_parnd(2);
    hpen->color = hb_parnl(3);
    HB_RETHANDLE( hpen );
}

HB_FUNC( HWG_CREATESOLIDBRUSH )
{
    PHWGUI_BRUSH hbrush = (PHWGUI_BRUSH) hb_xgrab( sizeof(HWGUI_BRUSH) );
    hbrush->type  = HWGUI_OBJECT_BRUSH;
    hbrush->color = hb_parnl(1);
    HB_RETHANDLE( hbrush );
}

HB_FUNC( HWG_SELECTOBJECT )
{
    HWGUI_HDC_OBJECT *obj = (HWGUI_HDC_OBJECT*) HB_PARHANDLE(2);

    hwg_SelectObject( (PHWGUI_HDC) HB_PARHANDLE(1), obj );

    if( obj->type == HWGUI_OBJECT_PEN )
        nCurrPenClr = ((PHWGUI_PEN)obj)->color;
    else if( obj->type == HWGUI_OBJECT_BRUSH )
        nCurrBrushClr = ((PHWGUI_BRUSH)obj)->color;

    HB_RETHANDLE( NULL );
}

HB_FUNC( HWG_DELETEOBJECT )
{
    HWGUI_HDC_OBJECT *obj = (HWGUI_HDC_OBJECT*) HB_PARHANDLE(1);

    if( obj->type == HWGUI_OBJECT_PEN )
        hb_xfree( obj );
    else if( obj->type == HWGUI_OBJECT_BRUSH )
        hb_xfree( obj );
    else if( obj->type == HWGUI_OBJECT_FONT ) {
        pango_font_description_free( ((PHWGUI_FONT)obj)->hFont );
        pango_attr_list_unref(      ((PHWGUI_FONT)obj)->attrs );
        hb_xfree( obj );
    } else if( obj->type == HWGUI_OBJECT_PIXBUF ) {
        g_object_unref( (GObject*) ((PHWGUI_PIXBUF)obj)->handle );
        hb_xfree( obj );
    }
}


/* =====================================================================
 *  DC management
 * ===================================================================== */
HB_FUNC( HWG_DEFINEPAINTSTRU )
{
    PHWGUI_PPS pps = (PHWGUI_PPS) hb_xgrab( sizeof(HWGUI_PPS) );
    pps->hDC = NULL;
    HB_RETHANDLE( pps );
}

HB_FUNC( HWG_BEGINPAINT )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE(1);
    PHWGUI_PPS pps    = (PHWGUI_PPS) HB_PARHANDLE(2);
    PHWGUI_HDC hDC    = (PHWGUI_HDC) hb_xgrab( sizeof(HWGUI_HDC) );

    memset( hDC, 0, sizeof(HWGUI_HDC) );
    hDC->widget = widget;

    if( hwg_current_cr && hwg_current_widget == widget ) {
        hDC->cr      = hwg_current_cr;
        hDC->surface = NULL;
        hDC->layout  = pango_cairo_create_layout( hDC->cr );
    } else {
        int w = gtk_widget_get_width(  widget );
        int h = gtk_widget_get_height( widget );
        if( w < 1 ) w = 1;
        if( h < 1 ) h = 1;
        hDC->surface = cairo_image_surface_create( CAIRO_FORMAT_ARGB32, w, h );
        hDC->cr      = cairo_create( hDC->surface );
        hDC->layout  = pango_cairo_create_layout( hDC->cr );
    }

    hDC->fcolor = hDC->bcolor = -1;
    pps->hDC = hDC;

    nCurrPenClr   = 0;
    nCurrBrushClr = 0xffffff;

    HB_RETHANDLE( hDC );
}

HB_FUNC( HWG_ENDPAINT )
{
    PHWGUI_PPS pps = (PHWGUI_PPS) HB_PARHANDLE(2);
    PHWGUI_HDC hDC = pps ? pps->hDC : NULL;

    if( hDC ) {
        if( hDC->layout )
            g_object_unref( (GObject*) hDC->layout );
        if( hDC->surface ) {
            cairo_surface_destroy( hDC->surface );
            cairo_destroy( hDC->cr );
        }
        hb_xfree( hDC );
    }
    if( pps ) hb_xfree( pps );
}

HB_FUNC( HWG_GETDC )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) hb_xgrab( sizeof(HWGUI_HDC) );
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE(1);
    int w, h;

    memset( hDC, 0, sizeof(HWGUI_HDC) );
    hDC->widget = widget;

    if( hwg_current_cr && hwg_current_widget == widget )
    {
        hDC->cr      = hwg_current_cr;
        hDC->surface = NULL;
        hDC->layout  = pango_cairo_create_layout( hDC->cr );
    }
    else
    {
        w = gtk_widget_get_width(  widget );
        h = gtk_widget_get_height( widget );
        if( w < 1 ) w = 1;
        if( h < 1 ) h = 1;

        hDC->surface = cairo_image_surface_create( CAIRO_FORMAT_ARGB32, w, h );
        hDC->cr      = cairo_create( hDC->surface );
        hDC->layout  = pango_cairo_create_layout( hDC->cr );
    }

    hDC->fcolor = hDC->bcolor = -1;

    nCurrPenClr   = 0;
    nCurrBrushClr = 0xffffff;

    HB_RETHANDLE( hDC );
}

HB_FUNC( HWG_RELEASEDC )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(2);

    if( !hDC ) return;

    if( hDC->layout )
        g_object_unref( (GObject*) hDC->layout );

    if( hDC->surface ) {
        cairo_surface_destroy( hDC->surface );
        cairo_destroy( hDC->cr );
    }

    hb_xfree( hDC );
}

HB_FUNC( HWG_CREATECOMPATIBLEDC )
{
    PHWGUI_HDC hDCdest   = (PHWGUI_HDC) hb_xgrab( sizeof(HWGUI_HDC) );
    PHWGUI_HDC hDCsource = (PHWGUI_HDC) HB_PARHANDLE(1);

    memset( hDCdest, 0, sizeof(HWGUI_HDC) );
    hDCdest->widget = hDCsource->widget;

    hDCdest->surface = cairo_surface_create_similar(
        cairo_get_target( hDCsource->cr ),
                                                    CAIRO_CONTENT_COLOR_ALPHA,
                                                    hb_parni(2), hb_parni(3) );
    hDCdest->cr     = cairo_create( hDCdest->surface );
    hDCdest->layout = pango_cairo_create_layout( hDCdest->cr );
    hDCdest->fcolor = hDCdest->bcolor = -1;

    HB_RETHANDLE( hDCdest );
}

HB_FUNC( HWG_BITBLT )
{
    PHWGUI_HDC hDCdest   = (PHWGUI_HDC) HB_PARHANDLE(1);
    PHWGUI_HDC hDCsource = (PHWGUI_HDC) HB_PARHANDLE(6);

    cairo_set_source_surface( hDCdest->cr, hDCsource->surface,
                              hb_parni(2), hb_parni(3) );
    cairo_paint( hDCdest->cr );
}

HB_FUNC( HWG_CAIRO_TRANSLATE )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    cairo_translate( hDC->cr, hb_parni(2), hb_parni(3) );
}

HB_FUNC( HWG_GETDRAWITEMINFO ) { }

HB_FUNC( HWG_DRAWGRAYBITMAP ) { }


/* =====================================================================
 *  Geometry queries — GtkAllocation was removed in GTK4
 * ===================================================================== */
HB_FUNC( HWG_GETCLIENTAREA )
{
    PHWGUI_PPS pps    = (PHWGUI_PPS) HB_PARHANDLE(1);
    GtkWidget *widget = pps->hDC->widget;
    PHB_ITEM  aMetr   = hb_itemArrayNew( 4 );

    if( getFixedBox( (GObject*) widget ) )
        widget = (GtkWidget*) getFixedBox( (GObject*) widget );

    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), gtk_widget_get_width(  widget ) );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), gtk_widget_get_height( widget ) );
    hb_itemRelease( hb_itemReturn( aMetr ) );
}

HB_FUNC( HWG_GETCLIENTRECT )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE(1);
    PHB_ITEM  aMetr   = hb_itemArrayNew( 4 );

    if( getFixedBox( (GObject*) widget ) )
        widget = (GtkWidget*) getFixedBox( (GObject*) widget );

    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), gtk_widget_get_width(  widget ) );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), gtk_widget_get_height( widget ) );
    hb_itemRelease( hb_itemReturn( aMetr ) );
}

HB_FUNC( HWG_GETWINDOWRECT )
{
    GtkWidget *widget = (GtkWidget*) HB_PARHANDLE(1);
    PHB_ITEM  aMetr   = hb_itemArrayNew( 4 );

    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), gtk_widget_get_width(  widget ) );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), gtk_widget_get_height( widget ) );
    hb_itemRelease( hb_itemReturn( aMetr ) );
}


/* =====================================================================
 *  Gradient
 * ===================================================================== */
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

HB_FUNC( HWG_DRAWGRADIENT )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    gdouble x1 = hb_parnd(2), y1 = hb_parnd(3), x2 = hb_parnd(4), y2 = hb_parnd(5);
    gint type = HB_ISNUM(6) ? hb_parni(6) : 1;
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

    if( HB_ISNUM(9) ) iRadius = hb_parni(9);
    else              pArrRadius = hb_param( 9, HB_IT_ARRAY );

    if( !pArrColor || ( user_colors_num = hb_arrayLen( pArrColor ) ) == 0 )
        return;

    if( user_colors_num == 1 )
        hwg_setcolor( hDC->cr, hb_arrayGetNL( pArrColor, 1 ) );
    else {
        type = ( type >= 1 && type <= 9 ) ? type : 1;
        switch( type ) {
            case 1: pat = cairo_pattern_create_linear( x1, y1, x1, y2 ); break;
            case 2: pat = cairo_pattern_create_linear( x1, y2, x1, y1 ); break;
            case 3: pat = cairo_pattern_create_linear( x1, y1, x2, y1 ); break;
            case 4: pat = cairo_pattern_create_linear( x2, y1, x1, y1 ); break;
            case 5: pat = cairo_pattern_create_linear( x1, y2, x2, y1 ); break;
            case 6: pat = cairo_pattern_create_linear( x2, y1, x1, y2 ); break;
            case 7: pat = cairo_pattern_create_linear( x1, y1, x2, y2 ); break;
            case 8: pat = cairo_pattern_create_linear( x2, y2, x1, y1 ); break;
            case 9:
                x_center  = (x2-x1)/2 + x1;
                y_center  = (y2-y1)/2 + y1;
                gr_radius = sqrt( pow(x2-x1,2) + pow(y2-y1,2) ) / 2;
                pat = cairo_pattern_create_radial( x_center, y_center, 0,
                                                   x_center, y_center, gr_radius );
                break;
        }

        colors_num    = user_colors_num;
        user_stops_num = pArrStop ? hb_arrayLen( pArrStop ) : 0;

        for( i = 0; i < colors_num; i++ ) {
            color = ( i < user_colors_num ) ? hb_arrayGetNL( pArrColor, i+1 )
            : 0xFFFFFF * i;
            hwg_prepare_cairo_colors( color, &r, &g, &b );
            stop = ( i < user_stops_num ) ? hb_arrayGetND( pArrStop, i+1 )
            : 1./(gdouble)(colors_num-1) * (gdouble)i;
            cairo_pattern_add_color_stop_rgb( pat, stop, r, g, b );
        }
    }

    if( pArrRadius || iRadius > 0 ) {
        if( pArrRadius ) {
            user_radiuses_num = hb_arrayLen( pArrRadius );
            max_r = ( x2-x1+1 > y2-y1+1 ) ? y2-y1+1 : x2-x1+1;
            max_r /= 2;
            for( i = 0; i < 4; i++ ) {
                radius[i] = ( i < user_radiuses_num ) ? hb_arrayGetNI( pArrRadius, i+1 ) : 0;
                radius[i] = ( radius[i] >= 0    ) ? radius[i] : 0;
                radius[i] = ( radius[i] <= max_r) ? radius[i] : max_r;
            }
        } else
            radius[0] = radius[1] = radius[2] = radius[3] = iRadius;

        cairo_arc( hDC->cr, x1+radius[0], y1+radius[0], radius[0], M_PI, 3*M_PI/2 );
        cairo_arc( hDC->cr, x2-radius[1], y1+radius[1], radius[1], 3*M_PI/2, 0 );
        cairo_arc( hDC->cr, x2-radius[2], y2-radius[2], radius[2], 0, M_PI/2 );
        cairo_arc( hDC->cr, x1+radius[3], y2-radius[3], radius[3], M_PI/2, M_PI );
        cairo_close_path( hDC->cr );
    } else
        cairo_rectangle( hDC->cr, x1, y1, x2-x1+1, y2-y1+1 );

    if( user_colors_num > 1 )
        cairo_set_source( hDC->cr, pat );
    cairo_fill( hDC->cr );

    if( user_colors_num > 1 )
        cairo_pattern_destroy( pat );
}


/* =====================================================================
 *  Combo / checkbox / radio owner-draw helpers
 * ===================================================================== */
HB_FUNC( HWG__DRAWCOMBO )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    gdouble x1 = hb_parni(2), y1 = hb_parni(3),
    x2 = hb_parni(4), y2 = hb_parni(5),
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
}

HB_FUNC( HWG__DRAWCHECKBTN )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    gdouble x1 = hb_parni(2), y1 = hb_parni(3), y2 = hb_parni(5),
    nHeight = y2-y1-6;
    int iSet = hb_parl(6);
    const char *cTitle = ( hb_pcount() > 6 ) ? hb_parc(7) : NULL;
    gchar *gcTitle;

    x1 += 2; y1 += 3;
    hwg_setcolor( hDC->cr, 0xffffff );
    cairo_rectangle( hDC->cr, x1, y1, nHeight, nHeight );
    cairo_fill( hDC->cr );

    hwg_setcolor( hDC->cr, 0 );
    cairo_set_line_width( hDC->cr, 1 );
    cairo_rectangle( hDC->cr, x1, y1, nHeight, nHeight );

    if( iSet ) {
        cairo_move_to( hDC->cr, x1+2, y1+nHeight/2 );
        cairo_line_to( hDC->cr, x1+nHeight/2, y1+nHeight-2 );
        cairo_line_to( hDC->cr, x1+nHeight-1, y1 );
    }
    cairo_stroke( hDC->cr );

    if( cTitle ) {
        gcTitle = hwg_convert_to_utf8( cTitle );
        pango_layout_set_text( hDC->layout, gcTitle, -1 );
        cairo_move_to( hDC->cr, x1 + nHeight + 4, y1-2 );
        pango_cairo_show_layout( hDC->cr, hDC->layout );
        g_free( gcTitle );
    }
}

HB_FUNC( HWG__DRAWRADIOBTN )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    gdouble x1 = hb_parni(2), y1 = hb_parni(3), y2 = hb_parni(5),
    nHeight = y2-y1-4;
    int iSet = hb_parl(6);
    const char *cTitle = ( hb_pcount() > 6 ) ? hb_parc(7) : NULL;
    gchar *gcTitle;

    x1 += 2; y1 += 2;
    hwg_setcolor( hDC->cr, 0xffffff );
    cairo_arc( hDC->cr, x1+nHeight/2, y1+nHeight/2, nHeight/2, 0, 6.28 );
    cairo_fill( hDC->cr );

    hwg_setcolor( hDC->cr, 0 );
    cairo_set_line_width( hDC->cr, 1 );
    cairo_arc( hDC->cr, x1+nHeight/2, y1+nHeight/2, nHeight/2, 0, 6.28 );
    cairo_stroke( hDC->cr );

    if( iSet ) {
        cairo_arc( hDC->cr, x1+nHeight/2, y1+nHeight/2, nHeight/2-3, 0, 6.28 );
        cairo_fill( hDC->cr );
    }

    if( cTitle ) {
        gcTitle = hwg_convert_to_utf8( cTitle );
        pango_layout_set_text( hDC->layout, gcTitle, -1 );
        cairo_move_to( hDC->cr, x1 + nHeight + 4, y1-2 );
        pango_cairo_show_layout( hDC->cr, hDC->layout );
        g_free( gcTitle );
    }
}

HB_FUNC( HWG_LOADPNG ) { }


/* =====================================================================
 *  Raw bitmap support (pure C, no GTK dependency) — unchanged.
 * ===================================================================== */
#pragma pack(push,1)

typedef struct{
    uint8_t  signature[2];
    uint32_t filesize;
    uint32_t reserved;
    uint32_t fileoffset_to_pixelarray;
} fileheader;

typedef struct{
    uint32_t dibheadersize;
    uint32_t width;
    uint32_t height;
    uint16_t planes;
    uint16_t bitsperpixel;
    uint32_t compression;
    uint32_t imagesize;
    uint32_t ypixelpermeter;
    uint32_t xpixelpermeter;
    uint32_t numcolorspallette;
    uint32_t mostimpcolor;
} bitmapinfoheader;

typedef struct {
    uint8_t b;
    uint8_t g;
    uint8_t r;
    uint8_t a;
} color;

typedef struct {
    uint8_t b;
    uint8_t g;
    uint8_t r;
    uint8_t i;
} pixel;

typedef struct {
    fileheader       fileheader;
    bitmapinfoheader bitmapinfoheader;
} bitmapheader3x;

typedef struct {
    uint32_t RedMask; uint32_t GreenMask; uint32_t BlueMask; uint32_t AlphaMask;
    uint32_t CSType;
    uint32_t RedX;   uint32_t RedY;   uint32_t RedZ;
    uint32_t GreenX; uint32_t GreenY; uint32_t GreenZ;
    uint32_t BlueX;  uint32_t BlueY;  uint32_t BlueZ;
    uint32_t GammaRed; uint32_t GammaGreen; uint32_t GammaBlue;
} bitmapinfoheader4x;

typedef struct {
    uint32_t intent;
    uint32_t profile_data;
    uint32_t profile_size;
    uint32_t reserved;
} bitmapinfoheader5x;

typedef struct {
    bitmapheader3x bmp_header;
    pixel **pixel_data;
    color  *palette;
} BMPImage3x;

typedef struct {
    uint32_t RedMask;
    uint32_t GreenMask;
    uint32_t BlueMask;
} WINNTBITFIELDSMASKS;

typedef struct {
    pixel **pixel_data;
    color  *palette;
} imagedata;

typedef struct {
    fileheader         fileheader;
    bitmapinfoheader   bitmapinfoheader;
    bitmapinfoheader4x bitmapinfoheader4x;
} bitmap4x;

typedef struct {
    bitmap4x bmp_header;
    pixel **pixel_data;
    color  *palette;
} BMPImage4x;

#pragma pack(pop)

static unsigned int cc_null( uint32_t wert )
{
    unsigned int zae = 0;
    if( !wert ) return 0u;
    while( !( wert & 0x1 ) ) { ++zae; wert >>= 1; }
    return zae;
}

uint32_t hwg_BMPFileSizeC( int bmp_width, int bmp_height,
                           int bmp_bit_depth, unsigned int colors )
{
    uint32_t image_size, pad, fileoffset_to_pixelarray, filesize;
    pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
    image_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad ) * bmp_height;
    fileoffset_to_pixelarray = sizeof(fileheader) + sizeof(bitmapinfoheader) + colors * 4;
    filesize = fileoffset_to_pixelarray + image_size;
    return filesize;
}

void *hwg_BMPNewImageC( int pbmp_width, int pbmp_height, int pbmp_bit_depth,
                        unsigned int colors, uint32_t xpixelpermeter,
                        uint32_t ypixelpermeter )
{
    BMPImage3x pbitmap;
    uint32_t image_size, pad, fileoffset_to_pixelarray, filesize, max_colors;
    uint32_t i, j;
    void *bmp_locpointer;
    uint8_t *bitmap_buffer, *buf, tmp;
    short bit;
    char csig[2];
    uint32_t bmp_width, bmp_height, bmp_bit_depth;
    uint8_t mask4[2];

    mask4[0] = 240; mask4[1] = 15;

    max_colors = (uint32_t) 1;
    csig[0] = 0x42; csig[1] = 0x4d;

    bmp_width      = (uint32_t) pbmp_width;
    bmp_height     = (uint32_t) pbmp_height;
    bmp_bit_depth  = (uint32_t) pbmp_bit_depth;

    memset( &pbitmap, 0, sizeof(BMPImage3x) );

    if( bmp_bit_depth != 1 && bmp_bit_depth != 4 && bmp_bit_depth != 8 &&
        bmp_bit_depth != 16 && bmp_bit_depth != 24 )
        return NULL;
    if( bmp_width < 1 || bmp_height < 1 ) return NULL;

    for( i = 0; i < bmp_bit_depth; ++i ) max_colors *= 2;
    if( colors > max_colors ) return NULL;

    pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
    image_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad ) * bmp_height;

    memset( &pbitmap, 0x00, sizeof(BMPImage3x) );

    fileoffset_to_pixelarray = sizeof(fileheader) + sizeof(bitmapinfoheader) + colors * 4;
    filesize = fileoffset_to_pixelarray + image_size;

    bmp_fileimg = malloc( filesize );

    memcpy( &pbitmap.bmp_header.fileheader.signature, csig, 2 );
    pbitmap.bmp_header.fileheader.filesize = filesize;
    pbitmap.bmp_header.fileheader.reserved = 0;
    pbitmap.bmp_header.fileheader.fileoffset_to_pixelarray = fileoffset_to_pixelarray;

    pbitmap.bmp_header.bitmapinfoheader.dibheadersize       = sizeof(bitmapinfoheader);
    pbitmap.bmp_header.bitmapinfoheader.width               = bmp_width;
    pbitmap.bmp_header.bitmapinfoheader.height              = bmp_height;
    pbitmap.bmp_header.bitmapinfoheader.planes              = (uint32_t) _planes;
    pbitmap.bmp_header.bitmapinfoheader.bitsperpixel        = (uint16_t) bmp_bit_depth;
    pbitmap.bmp_header.bitmapinfoheader.compression         = _compression;
    pbitmap.bmp_header.bitmapinfoheader.imagesize           = image_size;
    pbitmap.bmp_header.bitmapinfoheader.ypixelpermeter      = ypixelpermeter;
    pbitmap.bmp_header.bitmapinfoheader.xpixelpermeter      = xpixelpermeter;
    pbitmap.bmp_header.bitmapinfoheader.numcolorspallette   = colors;
    pbitmap.bmp_header.bitmapinfoheader.mostimpcolor        = colors;

    pbitmap.pixel_data = (pixel**) malloc( bmp_height * sizeof(pixel*) );
    if( !pbitmap.pixel_data ) return NULL;
    for( i = 0; i < bmp_height; ++i ) {
        pbitmap.pixel_data[i] = (pixel*) calloc( bmp_width, sizeof(pixel) );
        if( !pbitmap.pixel_data[i] ) {
            while( i > 0 ) free( pbitmap.pixel_data[--i] );
            free( pbitmap.pixel_data );
        }
    }

    pbitmap.palette = (color*) calloc( colors, sizeof(color) );
    memset( &pbitmap.palette, 0x00, sizeof(color) );

    memcpy( bmp_fileimg, &pbitmap, sizeof(BMPImage3x) );

    bmp_locpointer = bmp_fileimg + fileoffset_to_pixelarray;

    bitmap_buffer = (uint8_t*) calloc( 1, image_size );
    memset( bitmap_buffer, 0x00, image_size );
    buf = bitmap_buffer;

    switch( bmp_bit_depth ) {
        case 1:
            for( i = 0; i < bmp_height; ++i ) {
                j = 0;
                while( j < bmp_width ) {
                    tmp = 0;
                    for( bit = 7; bit >= 0 && j < bmp_width; --bit ) {
                        tmp |= ( pbitmap.pixel_data[i][j].i == 0 ? 0u : 1u ) << bit;
                        ++j;
                    }
                    *buf++ = tmp;
                }
                buf += pad;
            }
            break;
        case 4:
            for( i = 0; i < bmp_height; ++i ) {
                for( j = 0; j < bmp_width; j += 2 ) {
                    tmp = 0;
                    tmp |= pbitmap.pixel_data[i][j].i << 4;
                    if( j + 1 < bmp_height )
                        tmp |= pbitmap.pixel_data[i][j+1].i & mask4[LO_NIBBLE];
                    *buf++ = tmp;
                }
                buf += pad;
            }
            break;
        case 8:
            for( i = 0; i < bmp_height; ++i ) {
                for( j = 0; j < bmp_width; ++j ) *buf++ = pbitmap.pixel_data[i][j].i;
                buf += pad;
            }
            break;
        case 16:
            for( i = 0; i < bmp_height; ++i ) {
                for( j = 0; j < bmp_width; ++j ) {
                    uint16_t *px = (uint16_t*) buf;
                    *px = ( pbitmap.pixel_data[i][j].b << cc_null( pbitmap.palette->b ) ) +
                    ( pbitmap.pixel_data[i][j].g << cc_null( pbitmap.palette->g ) ) +
                    ( pbitmap.pixel_data[i][j].r << cc_null( pbitmap.palette->r ) );
                    buf += 2;
                }
                buf += pad;
            }
            break;
        case 24:
            for( i = 0; i < bmp_height; ++i ) {
                for( j = 0; j < bmp_width; ++j ) {
                    *buf++ = pbitmap.pixel_data[i][j].b;
                    *buf++ = pbitmap.pixel_data[i][j].g;
                    *buf++ = pbitmap.pixel_data[i][j].r;
                }
                buf += pad;
            }
            break;
    }

    memcpy( bmp_locpointer, bitmap_buffer, image_size );

    if( bitmap_buffer ) free( bitmap_buffer );

    return bmp_fileimg;
}

uint32_t hwg_BMPCalcOffsPixArrC( unsigned int colors )
{
    return sizeof(fileheader) + sizeof(bitmapinfoheader) + colors * 4;
}

uint32_t hwg_BMPCalcOffsPalC( int bmp_height )
{
    return sizeof(bitmapheader3x) + ( bmp_height * sizeof(pixel*) );
}

HB_FUNC( HWG_BMPNEWIMAGE )
{
    int bmp_width  = hb_parni(1);
    int bmp_height = hb_parni(2);
    int bmp_bit_depth = hb_parni(3);
    unsigned int colors = hb_parni(4);
    uint32_t xpixelpermeter = hb_parnl(5);
    uint32_t ypixelpermeter = hb_parnl(6);
    void *rci;
    char rcbuff[BMPFILEIMG_MAXSZ];
    uint32_t filesize;

    rci = hwg_BMPNewImageC( bmp_width, bmp_height, bmp_bit_depth, colors,
                            xpixelpermeter, ypixelpermeter );
    if( !rci ) { hb_retc("Error"); return; }

    filesize = hwg_BMPFileSizeC( bmp_width, bmp_height, bmp_bit_depth, colors );
    if( filesize > BMPFILEIMG_MAXSZ ) { hb_retc("Error"); return; }

    memcpy( &rcbuff, rci, filesize );
    hb_retclen_buffer( rcbuff, filesize );
}

HB_FUNC( HWG_BMPDESTROY ) { if( bmp_fileimg ) free( bmp_fileimg ); }

HB_FUNC( HWG_BMPFILESIZE )
{
    uint32_t image_size, pad, fileoffset_to_pixelarray, filesize;
    int bmp_width = hb_parni(1), bmp_height = hb_parni(2), bmp_bit_depth = hb_parni(3);
    unsigned int colors = hb_parni(4);
    pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
    image_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad ) * bmp_height;
    fileoffset_to_pixelarray = sizeof(fileheader) + sizeof(bitmapinfoheader) + colors * 4;
    filesize = fileoffset_to_pixelarray + image_size;
    hb_retnl( filesize );
}

HB_FUNC( HWG_BMPSZ3X ) { hb_retnl( sizeof(BMPImage3x) ); }
HB_FUNC( HWG_BMPMAXFILESZ ) { hb_retnl( BMPFILEIMG_MAXSZ ); }

HB_FUNC( HWG_BMPCALCOFFSPIXARR )
{
    hb_retnl( hwg_BMPCalcOffsPixArrC( hb_parni(1) ) );
}

HB_FUNC( HWG_BMPCALCOFFSPAL )
{
    hb_retnl( hwg_BMPCalcOffsPalC( hb_parni(1) ) );
}

HB_FUNC( HWG_BMPIMAGESIZE )
{
    int w = hb_parni(1), h = hb_parni(2), bd = hb_parni(3);
    uint32_t pad = (4 - (bd * w + 7 ) / 8 % 4) % 4;
    hb_retnl( ((bd * w + 7 ) / 8 + pad ) * h );
}

HB_FUNC( HWG_BMPLINESIZE )
{
    int w = hb_parni(1), bd = hb_parni(2);
    uint32_t pad = (4 - (bd * w + 7 ) / 8 % 4) % 4;
    hb_retnl( ((bd * w + 7 ) / 8 + pad ) );
}


/* =====================================================================
 *  QR code
 * ===================================================================== */
HB_FUNC( HWG_QRCODEZOOM_C )
{
    int i, j, leofq;
    int nzoom, nlen;
    int cptr, lptr;
    char cqrcode[16385];
    char cout[16385];
    char cLine[8192];
    const char *hString;

    nlen  = hb_parni( 2 );
    nzoom = HB_ISNIL( 3 ) ? 1 : hb_parni( 3 );

    lptr = 0; cptr = 0;
    memset( &cout,  0x00, 16385 );
    memset( &cLine, 0x00, 8192 );

    hString = hb_parc( 1 );
    memcpy( &cqrcode, hString, nlen );

    if( nzoom < 1 ) { hb_retclen( cqrcode, nlen ); return; }

    leofq = 0;
    for( i = 0; i < nlen; i++ ) {
        if( leofq == 0 ) {
            if( cqrcode[i] == 10 ) {
                if( !( cqrcode[i+1] == 32 ) ) leofq = 1;
                for( j = 1; j <= nzoom; j++ ) {
                    memcpy( &cout[cptr], &cLine, lptr );
                    cout[cptr + lptr + 1] = 10;
                    cptr = cptr + lptr + 2;
                }
                lptr = 0;
                memset( &cLine, 0x00, 8192 );
            } else {
                for( j = 1; j <= nzoom; j++ ) { cLine[lptr] = cqrcode[i]; lptr++; }
                cLine[lptr] = 10;
            }
        }
    }

    if( lptr > 0 ) {
        memcpy( &cout[cptr], &cLine, lptr );
        cout[cptr + lptr + 1] = 10;
        cptr = cptr + lptr + 2;
    }

    cout[cptr + 1] = 10;
    cptr++;
    cptr++;

    hb_retclen( cout, cptr );
}

/* ================== EOF of draw.c ========================== */
