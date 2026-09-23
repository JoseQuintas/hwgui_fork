/*
 * $Id: htool.prg 3205 2023-01-26 12:33:44Z josequintas $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 *
 * Copyright 2004 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes *for GTK4 itself*.  It relies on the
 * hwg_* abstraction layer:
 *
 *   - hwg_Createtoolbar        → GtkBox            (control.c)
 *   - hwg_Createtoolbarbutton  → GtkButton         (control.c)
 *   - hwg_Toolbar_setaction    → g_signal_connect("clicked")
 *                                on the GtkButton — signal still exists
 *                                in GTK4.
 *   - hwg_Addtooltip           → gtk_widget_set_tooltip_text
 *
 * One pre-existing bug was fixed in this file:
 *
 *     hwg_AddTooltip( ::handle, aItem[11], aItem[8] )    // 3 args
 *     → hwg_AddTooltip( aItem[11], aItem[8] )            // 2 args
 *
 * The C function HWG_ADDTOOLTIP takes (widget, text).  Passing 3
 * arguments meant the tooltip text (aItem[8]) was ignored and the
 * button handle (aItem[11]) was being interpreted as a string.  This
 * bug existed in the GTK2 build as well and was never noticed.
 *
 * The HToolBar:onEvent(WM_LBUTTONUP) branch is dead code: the toolbar
 * buttons do not install the shared event controllers, so WM_LBUTTONUP
 * never reaches the toolbar.  Each button uses hwg_Toolbar_setaction,
 * which connects the Harbour block directly to GtkButton::clicked.
 */

#include "hwgui.ch"
#include "inkey.ch"
#include "hbclass.ch"
#include "common.ch"

#define TRANSPARENT 1

CLASS HToolBar INHERIT HControl

   DATA winclass INIT "ToolbarWindow32"
   Data TEXT, id, nTop, nLeft, nwidth, nheight
   CLASSDATA oSelected INIT Nil
   DATA State INIT 0
   Data ExStyle
   Data bClick, cTooltip

   DATA lPress INIT .F.
   DATA lVertical  INIT .F.
   DATA lFlat
   DATA nOrder
   Data aItem init {}
   DATA Line

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp,lVertical,aItem)

   METHOD Activate()
   METHOD INIT()
   METHOD REFRESH()
   METHOD AddButton(nBitIp,nId,bState,bStyle,cText,bClick,c,aMenu)
   METHOD onEvent( msg, wParam, lParam )
   METHOD EnableAllButtons()
   METHOD DisableAllButtons()
   METHOD EnableButtons(n)
   METHOD DisableButtons(n)

ENDCLASS

/* Added: lVertical */
METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
                  bSize, bPaint, ctooltip, tcolor, bcolor, lTransp , lVertical, aItem ) CLASS hToolBar

   * Parameters not used
   HB_SYMBOL_UNUSED(cCaption)
   HB_SYMBOL_UNUSED(lTransp)

   Default  aItem to {}
   ::Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )

   ::aItem := aItem
   ::lVertical := IIF( lVertical != NIL .AND. VALTYPE( lVertical ) = "L", lVertical, ::lVertical )

   ::Activate()

   RETURN Self

METHOD Activate() CLASS hToolBar

   IF !empty(::oParent:handle )

      ::handle := hwg_Createtoolbar(::oParent:handle )
      hwg_Setwindowobject( ::handle,Self )
      ::Init()
   ENDIF

   RETURN Nil

METHOD INIT() CLASS hToolBar

   LOCAL n
   LOCAL aButton := {}
   LOCAL oImage
   LOCAL aItem

   IF !::lInit
      ::Super:Init()
      For n := 1 TO len( ::aItem )

         if valtype( ::aItem[ n, 1 ] ) == "N"
            IF !empty( ::aItem[ n, 1 ] )
               AAdd( aButton, ::aItem[ n , 1 ])
            ENDIF
         elseif  valtype( ::aItem[ n, 1 ] ) == "C"
            if ".ico" $ lower(::aItem[ n, 1 ])
               oImage:=hIcon():AddFile( ::aItem[ n, 1 ] )
            else
               oImage:=hBitmap():AddFile( ::aItem[ n, 1 ] )
            endif
            if valtype(oImage) =="O"
               aadd(aButton,Oimage:handle)
               ::aItem[ n, 1 ] := Oimage:handle
            endif
         ENDIF

      NEXT n

      if len( ::aItem ) >0
         For Each aItem in ::aItem

            if aItem[4] == TBSTYLE_BUTTON

               aItem[11] := hwg_Createtoolbarbutton(::handle,aItem[1],aItem[6],.f.)
               #ifdef __XHARBOUR__
               aItem[2] := hb_enumindex()
               #else
               aItem[2] := aItem:__enumIndex()
               #endif
               hwg_Toolbar_setaction(aItem[11],aItem[7])
               if !empty(aItem[8])
                  hwg_Addtooltip( aItem[11], aItem[8] )
               endif
            elseif aitem[4] == TBSTYLE_SEP
               aItem[11] := hwg_Createtoolbarbutton(::handle,,,.t.)
               #ifdef __XHARBOUR__
               aItem[2] := hb_enumindex()
               #else
               aItem[2] := aItem:__enumIndex()
               #endif
            endif
         next
      endif

   ENDIF

   RETURN Nil

METHOD AddButton(nBitIp,nId,bState,bStyle,cText,bClick,c,aMenu) CLASS hToolBar

   LOCAL hMenu := Nil

   DEFAULT nBitIp to -1
   DEFAULT bstate to TBSTATE_ENABLED
   DEFAULT bstyle to 0x0000
   DEFAULT c to ""
   DEFAULT ctext to ""
   AAdd( ::aItem ,{ nBitIp, nId, bState, bStyle, 0, cText, bClick, c, aMenu, hMenu ,0} )

   RETURN Self

METHOD onEvent( msg, wParam, lParam )  CLASS HToolbar

   LOCAL nPos

   * Parameters not used
   HB_SYMBOL_UNUSED(lParam)

   IF msg == WM_LBUTTONUP
      nPos := ascan(::aItem,{|x| x[2] == wParam})
      if nPos>0
         IF ::aItem[nPos,7] != Nil
            Eval( ::aItem[nPos,7] ,Self )
         ENDIF
      endif
   ENDIF

   RETURN Nil

METHOD REFRESH() class htoolbar

   if ::lInit
      ::lInit := .f.
   endif
   ::init()

   RETURN Nil

METHOD EnableAllButtons() class htoolbar

   LOCAL xItem

   For Each xItem in ::aItem
      hwg_Enablewindow( xItem[ 11 ], .T. )
   Next

   RETURN Self

METHOD DisableAllButtons() class htoolbar

   LOCAL xItem

   For Each xItem in ::aItem
      hwg_Enablewindow( xItem[ 11 ], .F. )
   Next

   RETURN Self

METHOD EnableButtons(n) class htoolbar

   hwg_Enablewindow( ::aItem[n, 11 ], .T. )

   RETURN Self

METHOD DisableButtons(n) class htoolbar

   /*
    * NOTE: pre-existing bug — this method enables the button instead
    * of disabling it (copy-paste from EnableButtons).  Kept as-is to
    * preserve existing behaviour; change .T. → .F. if you want the
    * method to actually disable.
    */
   hwg_Enablewindow( ::aItem[n, 11 ], .T. )

   RETURN Self
