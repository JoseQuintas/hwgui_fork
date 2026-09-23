/*
 * $Id: drawtext.c 3719 2025-05-02 10:42:16Z df7be $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level text functions
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 */

#include "guilib.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"

#include <cairo.h>
#include <gtk/gtk.h>

#include "hwgtk4.h"

#define DT_CENTER                   1
#define DT_RIGHT                    2

#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

#include "warnings.h"

#ifndef PANGO_WRAP_NONE
#define PANGO_WRAP_NONE 3
#endif

/* GTK4: hwg_parse_color() now takes a GdkRGBA (GdkColor removed). */
extern void hwg_parse_color( HB_ULONG ncolor, GdkRGBA *pColor );
extern void hwg_setcolor    ( cairo_t *cr, long int nColor );
extern void set_css_data    ( char *szData );
extern GtkWidget *GetActiveWindow( void );


HB_FUNC( HWG_DELETEDC ) { }


/* TextOut( hDC, x, y, cText ) */
HB_FUNC( HWG_TEXTOUT )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    char *cText;

    if( hb_parclen(4) > 0 )
    {
        cText = hwg_convert_to_utf8( hb_parc(4) );
        pango_layout_set_text( hDC->layout, cText, -1 );

        hwg_setcolor( hDC->cr, ( hDC->fcolor != -1 ) ? hDC->fcolor : 0 );

        cairo_move_to( hDC->cr, (gdouble)hb_parni(2), (gdouble)hb_parni(3) );
        pango_cairo_show_layout( hDC->cr, hDC->layout );

        g_free( cText );
    }
}


/*  hwg_DrawText( hDC, "Text", x1, y1, x2, y2 [, nFlags] )
 *  DT_CENTER / DT_RIGHT apply only when text fits into the given box. */
HB_FUNC( HWG_DRAWTEXT )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    char *cText;
    PangoRectangle rc;
    int iWidth = hb_parni(5) - hb_parni(3);

    if( !hDC || !hDC->cr || !hDC->layout )
        return;

    if( hb_parclen(2) > 0 )
    {
        cText = hwg_convert_to_utf8( hb_parc(2) );
        pango_layout_set_text( hDC->layout, cText, -1 );

        pango_layout_get_pixel_extents( hDC->layout, &rc, NULL );

        pango_layout_set_width( hDC->layout, iWidth * PANGO_SCALE );
        pango_layout_set_ellipsize( hDC->layout, PANGO_ELLIPSIZE_NONE );
        pango_layout_set_justify( hDC->layout, 0 );

        if( pango_version() >= PANGO_VERSION_ENCODE(1, 56, 0) )
            pango_layout_set_wrap( hDC->layout, PANGO_WRAP_NONE );
        else
            pango_layout_set_width( hDC->layout, -1 );

        pango_layout_set_single_paragraph_mode( hDC->layout, TRUE );

        if( !HB_ISNIL(7) &&
            ( hb_parni(7) & ( DT_CENTER | DT_RIGHT ) ) &&
            ( rc.width < ( iWidth - 10 ) ) )
        {
            pango_layout_set_alignment( hDC->layout,
                                        ( hb_parni(7) & DT_CENTER ) ? PANGO_ALIGN_CENTER : PANGO_ALIGN_RIGHT );
        }
        else
            pango_layout_set_alignment( hDC->layout, PANGO_ALIGN_LEFT );

        hwg_setcolor( hDC->cr, ( hDC->fcolor != -1 ) ? hDC->fcolor : 0 );
        cairo_move_to( hDC->cr, (gdouble)hb_parni(3), (gdouble)hb_parni(4) );
        pango_cairo_show_layout( hDC->cr, hDC->layout );
        cairo_stroke( hDC->cr );

        g_free( cText );
    }
}


/*  hwg_GetTextMetric( hDC ) -> { nHeight, nAveCharWidth, nMaxCharWidth }
 *
 *  GTK4: gtk_widget_get_style() was removed. We obtain the widget's
 *  current Pango context directly and use whatever font Pango reports.
 *  If hDC->hFont is set (via SelectObject on a HFONT), it is honoured. */
HB_FUNC( HWG_GETTEXTMETRIC )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    PangoContext     *context;
    PangoFontMetrics *metrics;
    PangoFontDescription *fontDesc;

    context  = pango_layout_get_context( hDC->layout );

    if( hDC->hFont )
    {
        fontDesc = hDC->hFont;
    }
    else
    {
        /* GTK4 replacement for gtk_widget_get_style(widget)->font_desc. */
        const PangoFontDescription *def =
        pango_context_get_font_description( context );
        fontDesc = (PangoFontDescription*) def;
    }

    metrics = pango_context_get_metrics( context, fontDesc, NULL );
    {
        PHB_ITEM aMetr = hb_itemArrayNew( 3 );
        PHB_ITEM temp;
        int height, width;

        height = ( pango_font_metrics_get_ascent( metrics ) +
        pango_font_metrics_get_descent( metrics ) ) / PANGO_SCALE;
        width  = pango_font_metrics_get_approximate_char_width( metrics ) / PANGO_SCALE;
        pango_font_metrics_unref( metrics );

        temp = hb_itemPutNL( NULL, height );
        hb_itemArrayPut( aMetr, 1, temp ); hb_itemRelease( temp );

        temp = hb_itemPutNL( NULL, width );
        hb_itemArrayPut( aMetr, 2, temp ); hb_itemRelease( temp );

        temp = hb_itemPutNL( NULL, width );
        hb_itemArrayPut( aMetr, 3, temp ); hb_itemRelease( temp );

        hb_itemRelease( hb_itemReturn( aMetr ) );
    }
}


HB_FUNC( HWG_GETTEXTSIZE )
{
    PHWGUI_HDC hDC   = (PHWGUI_HDC) HB_PARHANDLE(1);
    char      *cText = hwg_convert_to_utf8( hb_parc(2) );
    PangoRectangle rc;
    PHB_ITEM aMetr = hb_itemArrayNew( 2 );

    if( HB_ISCHAR(2) && hb_parclen(2) > 0 )
        pango_layout_set_text( hDC->layout, cText, -1 );
    pango_layout_get_pixel_extents( hDC->layout, &rc, NULL );

    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), rc.width );
    hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), rc.height );
    hb_itemRelease( hb_itemReturn( aMetr ) );
    g_free( cText );
}

HB_FUNC( HWG_GETTEXTWIDTH )
{
    PHWGUI_HDC hDC   = (PHWGUI_HDC) HB_PARHANDLE(1);
    char      *cText = hwg_convert_to_utf8( hb_parc(2) );
    PangoRectangle rc;

    if( HB_ISCHAR(2) && hb_parclen(2) > 0 )
        pango_layout_set_text( hDC->layout, cText, -1 );
    pango_layout_get_pixel_extents( hDC->layout, &rc, NULL );

    hb_retnl( rc.width );
    g_free( cText );
}


/*  hwg_GetFontsList() -> array of font-family names
 *
 *  GTK4: gdk_cairo_create() is gone. We use Pango's font map directly. */
HB_FUNC( HWG_GETFONTSLIST )
{
    PangoFontMap      *fontmap;
    PangoContext      *context;
    PangoFontFamily  **families;
    int                n_families, i;
    PHB_ITEM           aFonts;

    fontmap = pango_cairo_font_map_get_default();
    context = pango_font_map_create_context( fontmap );

    pango_context_list_families( context, &families, &n_families );
    if( n_families <= 0 )
    {
        g_object_unref( context );
        return;
    }

    aFonts = hb_itemArrayNew( n_families );
    for( i = 0; i < n_families; i++ )
        hb_arraySetC( aFonts, i+1, pango_font_family_get_name( families[i] ) );

    g_free( families );
    g_object_unref( context );
    hb_itemReturnRelease( aFonts );
}


HB_FUNC( HWG_SETTEXTCOLOR )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    hb_retnl( hDC->fcolor );
    hDC->fcolor = hb_parnl(2);
}

HB_FUNC( HWG_SETBKCOLOR )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    hb_retnl( hDC->bcolor );
    hDC->bcolor = hb_parnl(2);
}

HB_FUNC( HWG_SETTRANSPARENTMODE ) { }

HB_FUNC( HWG_GETTEXTCOLOR )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    hb_retnl( hDC->fcolor );
}

HB_FUNC( HWG_GETBKCOLOR )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    hb_retnl( hDC->bcolor );
}

HB_FUNC( HWG_EXTTEXTOUT ) { }

HB_FUNC( HWG_WINDOWFROMDC )
{
    PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
    HB_RETHANDLE( (GtkWidget*) hDC->widget );
}


/*  CreateFont( fontName, nWidth, nHeight [, fnWeight] [, fdwCharSet],
 *              [, fdwItalic] [, fdwUnderline] [, fdwStrikeOut] ) */
HB_FUNC( HWG_CREATEFONT )
{
    PangoFontDescription *hFont;
    PHWGUI_FONT h   = (PHWGUI_FONT) hb_xgrab( sizeof(HWGUI_FONT) );
    int iUnder  = ( !HB_ISNIL(7) && hb_parni(7) > 0 ) ? 1 : 0;
    int iStrike = ( !HB_ISNIL(8) && hb_parni(8) > 0 ) ? 1 : 0;

    hFont = pango_font_description_new();
    pango_font_description_set_family( hFont, hb_parc(1) );

    if( !HB_ISNIL(6) )
    {
        pango_font_description_set_style( hFont,
                                          hb_parni(6) ? PANGO_STYLE_ITALIC : PANGO_STYLE_NORMAL );
    }

    pango_font_description_set_size( hFont, hb_parni(3) );

    if( !HB_ISNIL(4) )
    {
        pango_font_description_set_weight( hFont, hb_parni(4) );
    }

    h->type  = HWGUI_OBJECT_FONT;
    h->hFont = hFont;

    if( iUnder || iStrike )
    {
        h->attrs = pango_attr_list_new();
        if( iUnder )
        {
            pango_attr_list_insert( h->attrs,
                                    pango_attr_underline_new( PANGO_UNDERLINE_SINGLE ) );
        }
        if( iStrike )
        {
            pango_attr_list_insert( h->attrs,
                                    pango_attr_strikethrough_new( 1 ) );
        }
    }
    else
    {
        h->attrs = NULL;
    }

    HB_RETHANDLE( h );
}


/*  SetCtrlFont( hCtrl, hFont )
 *
 *  GTK4: gtk_widget_modify_font() / GtkBin / GtkEventBox are all gone.
 *  The GtkStyle-based approach is replaced by CSS, but here we can go
 *  a step further and set the Pango font description directly on each
 *  concrete widget type. That covers GtkLabel, GtkEntry, GtkButton and
 *  GtkFrame consistently without needing the CSS route. */
static void hwg_apply_font_to_widget( GtkWidget *w, PangoFontDescription *font )
{
    PangoAttrList *pAttrs;
    GtkWidget     *pChild;
    GtkWidget     *pLabel;

    if( !w || !GTK_IS_WIDGET( w ) || !font )
        return;

    if( GTK_IS_LABEL( w ) )
    {
        pAttrs = pango_attr_list_new();
        pango_attr_list_insert( pAttrs, pango_attr_font_desc_new( font ) );
        gtk_label_set_attributes( GTK_LABEL( w ), pAttrs );
        pango_attr_list_unref( pAttrs );
    }
    else if( GTK_IS_ENTRY( w ) )
    {
        pAttrs = pango_attr_list_new();
        pango_attr_list_insert( pAttrs, pango_attr_font_desc_new( font ) );
        gtk_entry_set_attributes( GTK_ENTRY( w ), pAttrs );
        pango_attr_list_unref( pAttrs );
    }
    else if( GTK_IS_BUTTON( w ) )
    {
        pChild = gtk_button_get_child( GTK_BUTTON( w ) );
        if( pChild )
        {
            hwg_apply_font_to_widget( pChild, font );
        }
        else
        {
            char  buf[512];
            char *family = pango_font_description_get_family( font );
            int   size   = pango_font_description_get_size( font ) / PANGO_SCALE;
            int   italic = ( pango_font_description_get_style( font ) == PANGO_STYLE_ITALIC );
            int   bold   = ( pango_font_description_get_weight( font ) >= PANGO_WEIGHT_BOLD );

            snprintf( buf, sizeof(buf),
                      "button { font-family: %s; font-size: %dpx; font-style: %s; font-weight: %s; }",
                      family ? family : "sans", size,
                      italic ? "italic" : "normal",
                      bold   ? "bold"   : "normal" );
            set_css_data( buf );
        }
    }
    else if( GTK_IS_FRAME( w ) )
    {
        pLabel = gtk_frame_get_label_widget( GTK_FRAME( w ) );
        if( pLabel )
            hwg_apply_font_to_widget( pLabel, font );
    }
    else if( GTK_IS_COMBO_BOX( w ) )
    {
        pChild = gtk_combo_box_get_child( GTK_COMBO_BOX( w ) );
        if( pChild )
            hwg_apply_font_to_widget( pChild, font );
    }
}

HB_FUNC( HWG_SETCTRLFONT )
{
    GtkWidget    *hCtrl = (GtkWidget*) HB_PARHANDLE( 1 );
    PHWGUI_FONT   pFont = (PHWGUI_FONT) HB_PARHANDLE( 3 );
    GtkWidget    *hLabel;

    if( !hCtrl || !pFont )
        return;

    /* First, try the widget's "label" data key (set by HWG_CREATESTATIC). */
    hLabel = (GtkWidget*) g_object_get_data( (GObject*) hCtrl, "label" );
    if( hLabel && GTK_IS_WIDGET( hLabel ) )
        hwg_apply_font_to_widget( hLabel, pFont->hFont );

    hwg_apply_font_to_widget( hCtrl, pFont->hFont );
}


HB_FUNC( G_DEBUG )
{
    g_debug( "%s", hb_parc(1) );
}

/* =========================== EOF of drawtext.c ============================= */
