/*
 * $Id: hwgtk4.h 2737 2018-12-12 17:36:43Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code
 *
 * GTK4 port
 *
 * Changes relative to the GTK2/3 header:
 *
 *   1.  GdkWindow *window was removed from HWGUI_HDC.
 *       GTK4 removed GdkWindow in favour of GdkSurface, and the
 *       HWGUI_HDC no longer carries a native surface handle.  All
 *       painting now goes through cairo_t (hDC->cr), which is either:
 *           * the live cairo_t provided by a GtkDrawingArea draw_func,
 *             or
 *           * a cairo_t attached to an offscreen image surface
 *             (used only for text metrics and similar queries).
 *
 *   2.  Two externs were added to expose the "live cairo_t bridge"
 *       used by draw.c:
 *
 *           extern cairo_t   *hwg_current_cr;
 *           extern GtkWidget *hwg_current_widget;
 *
 *       These are set/cleared by the draw_func dispatcher in
 *       window.c / control.c around the OnEvent(WM_PAINT) call.
 *
 *   3.  An include guard was added (the original header had none).
 *
 *   4.  An extern "C" wrapper was added so the header can be included
 *       from C++ translation units without name-mangling surprises.
 *
 * The rest of the ABI is unchanged: HWGUI_PEN, HWGUI_BRUSH,
 * HWGUI_FONT, HWGUI_PIXBUF, HWGUI_PPS and all type tags keep the
 * same layout, so existing Harbour-level code does not need to change.
 */

#ifndef HWGTK4_H_
#define HWGTK4_H_

#ifdef __cplusplus
extern "C" {
    #endif

    /*
     * ---------------------------------------------------------------
     *  HWGUI_HDC — Harbour-level "device context" wrapper
     *
     *  NOTE (GTK4):
     *    window field was removed.
     *    cairo_t ownership is signalled by the `surface` field:
     *      - surface != NULL  → we own the cairo_t (offscreen image surface)
     *      - surface == NULL  → we borrowed the live cairo_t from a draw_func
     *    ReleaseDC uses this to decide whether to destroy hDC->cr.
     * ---------------------------------------------------------------
     */
    typedef struct HWGUI_HDC_STRU
    {
        GtkWidget           *widget;
        cairo_surface_t     *surface;
        cairo_t             *cr;
        PangoFontDescription*hFont;
        PangoLayout         *layout;
        long                 fcolor, bcolor;
    } HWGUI_HDC, * PHWGUI_HDC;


    typedef struct HWGUI_PPS_STRU
    {
        PHWGUI_HDC hDC;
    } HWGUI_PPS, * PHWGUI_PPS;


    #define HWGUI_OBJECT_PEN     1
    #define HWGUI_OBJECT_BRUSH   2
    #define HWGUI_OBJECT_FONT    3
    #define HWGUI_OBJECT_PIXBUF  4

    typedef struct HWGUI_HDC_OBJECT_STRU
    {
        short int type;
    } HWGUI_HDC_OBJECT;

    typedef struct HWGUI_PEN_STRU
    {
        short int  type;
        gdouble    width;
        int        style;
        long int   color;
    } HWGUI_PEN, * PHWGUI_PEN;

    typedef struct HWGUI_BRUSH_STRU
    {
        short int  type;
        long int   color;
    } HWGUI_BRUSH, * PHWGUI_BRUSH;

    typedef struct HWGUI_FONT_STRU
    {
        short int             type;
        PangoFontDescription *hFont;
        PangoAttrList        *attrs;
    } HWGUI_FONT, * PHWGUI_FONT;

    typedef struct HWGUI_PIXBUF_STRU
    {
        short int   type;
        long int    trcolor;
        GdkPixbuf  *handle;
    } HWGUI_PIXBUF, * PHWGUI_PIXBUF;


    /* =====================================================================
     *  Live cairo_t bridge
     *
     *  These globals are defined in draw.c and set/cleared by the
     *  draw_func dispatcher around each OnEvent(WM_PAINT) call.
     *  HWG_GETDC and HWG_BEGINPAINT consult them to decide whether to
     *  return the live cairo_t (drawn directly on screen) or an offscreen
     *  image surface (used for text metrics only).
     * ===================================================================== */
    extern cairo_t   *hwg_current_cr;
    extern GtkWidget *hwg_current_widget;


    /* =====================================================================
     *  Utility conversions (defined in window.c)
     * ===================================================================== */
    extern gchar *hwg_convert_to_utf8  ( const char *szText );
    extern gchar *hwg_convert_from_utf8( const char *szText );


    #ifdef __cplusplus
}
#endif

#endif /* HWGTK4_H_ */

/* =========================== EOF of hwgtk4.h =========================== */
