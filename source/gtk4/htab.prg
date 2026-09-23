/*
 *$Id: htab.prg 3839 2026-08-08 23:54:37Z itamarlins $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HTab class
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It relies exclusively on the
 * hwg_* abstraction layer:
 *
 *   - hwg_Createtabcontrol       → GtkNotebook         (control.c)
 *   - hwg_Addtab                 → gtk_notebook_append_page
 *   - hwg_SetCurrentTab          → gtk_notebook_set_current_page
 *   - hwg_Deletetab              → gtk_notebook_remove_page
 *   - hwg_Settabdisabled         → gtk_widget_set_sensitive on the label
 *   - hwg_Addtooltip             → gtk_widget_set_tooltip_text
 *
 * The tab-change notification (WM_USER with page_num+1) is emitted by
 * cb_signal_tab() in control.c, which is bound to GtkNotebook::switch-page
 * (still present in GTK4).
 *
 * The HTabPage compatibility class (chained syntax oTab:Page(x):Disable())
 * is pure Harbour and unaffected by the toolkit version.
 */

#include "hwgui.ch"
#include "hbclass.ch"

DYNAMIC HTabPage

CLASS HTab INHERIT HControl

   CLASS VAR winclass   INIT "SysTabControl32"
   DATA  aTabs
   DATA  aPages  INIT {}
   DATA  bChange, bChange2
   DATA  oTemp
   DATA  bAction
   DATA  aTabDisabled INIT {}  // Array for Tab Disabled
   DATA  aTooltips INIT {}     // Array with tooltips messages

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, aTabs, bChange, aImages, lResour, nBC, ;
      bClick, bGetFocus, bLostFocus )
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD SetTab( n )
   METHOD StartPage( cname , cToolTip )
   METHOD EndPage()
   METHOD GetActivePage( nFirst, nEnd )
   METHOD DeletePage( nPage )
   METHOD Page( nPage )
   METHOD SetTabDisabled( nPage, lDisable )

   HIDDEN:
   DATA  nActive  INIT 0         // Active Page

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, aTabs, bChange, aImages, lResour, nBC, ;
      bClick, bGetFocus, bLostFocus ) CLASS HTab

   HB_SYMBOL_UNUSED(aImages)
   HB_SYMBOL_UNUSED(lResour)
   HB_SYMBOL_UNUSED(nBC)

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint )

   ::title   := ""
   ::oFont   := iif( oFont == Nil, ::oParent:oFont, oFont )
   ::aTabs   := iif( aTabs == Nil, {}, aTabs )
   ::bChange := bChange

   /*
    * Force fresh per-instance arrays.  In Harbour, "DATA x INIT {}"
    * can share the SAME array object across every instance of the
    * class.  Without these four lines a second/third HTab instance
    * inherits stale aPages/aTabDisabled/aTooltips entries from the
    * previous dialog, which makes the notebook misbehave after some
    * open/close cycles.
    */
   ::aPages       := {}   // <<< fresh
   ::aTabDisabled := {}   // <<< fresh
   ::aTooltips    := {}   // <<< fresh
   ::nActive      := 0    // <<< reset

   ::bChange2 := bChange

   ::bGetFocus  := iif( bGetFocus == Nil, Nil, bGetFocus )
   ::bLostFocus := iif( bLostFocus == Nil, Nil, bLostFocus )
   ::bAction    := iif( bClick == Nil, Nil, bClick )

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HTab

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createtabcontrol( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )

      ::Init()
   ENDIF

   RETURN Nil

METHOD Init() CLASS HTab

   LOCAL i, h

   IF !::lInit
      ::Super:Init()
      FOR i := 1 TO Len( ::aTabs )
         h := hwg_Addtab( ::handle, ::aTabs[i] )
         AAdd( ::aPages, { 0, 0, .T. , h } )
      NEXT

      hwg_Setwindowobject( ::handle, Self )

   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HTab

   LOCAL n

   * Parameters not used
   HB_SYMBOL_UNUSED(lParam)

   IF msg == WM_USER
      IF wParam >= 1 .AND. wParam <= Len( ::aPages )
         ::nActive := wParam
         IF ::bChange2 != Nil .AND. ::aPages[ ::nActive,3 ]
            Eval( ::bChange2, Self, wParam )
         ENDIF
      ENDIF
      RETURN 0
   ENDIF

  * Change tooltip concerning the selected tab
   n := ::nActive

   IF n > 0
    IF .NOT. EMPTY(::aTooltips[n])
     hwg_Addtooltip( ::aPages[ n,4 ],  ::aTooltips[n]  )
    ENDIF
   ENDIF

   RETURN 0

METHOD SetTab( n ) CLASS HTab

   hwg_SetCurrentTab( ::handle, n )

   * If the tab is changed, need to set tooltip for this page
   * for the whole notebook

   IF n > 0
    IF .NOT. EMPTY(::aTooltips[n])
     hwg_Addtooltip( ::aPages[ n,4 ],  ::aTooltips[n]  )
    ENDIF
   ENDIF

   RETURN Nil

METHOD StartPage( cname , ctooltip ) CLASS HTab

   LOCAL i

   ::oTemp := ::oDefaultParent
   ::oDefaultParent := Self
   AAdd( ::aTabs, cname )
   i := Len( ::aTabs )
   AAdd( ::aPages, { Len( ::aControls ), 0, .F., 0 } )
   AAdd( ::aTabDisabled, .F. )

   * Collect tooltips in the array
   AAdd( ::aTooltips , IIF ( ctooltip == NIL , "" , ctooltip ) )

   ::nActive := i

   IF  cToolTip == NIL
    ::aPages[ i,4 ] := hwg_Addtab( ::handle, ::aTabs[i] , "" )
   ELSE
    ::aPages[ i,4 ] := hwg_Addtab( ::handle, ::aTabs[i] , cToolTip )
   ENDIF

   RETURN Nil

METHOD EndPage() CLASS HTab

   ::aPages[ ::nActive,2 ] := Len( ::aControls ) - ::aPages[ ::nActive,1 ]
   ::aPages[ ::nActive,3 ] := .T.
   ::nActive := 1

   ::oDefaultParent := ::oTemp
   ::oTemp := Nil

   RETURN Nil

METHOD GetActivePage( nFirst, nEnd ) CLASS HTab
   IF !Empty( ::aPages )
      nFirst := ::aPages[ ::nActive,1 ] + 1
      nEnd   := ::aPages[ ::nActive,1 ] + ::aPages[ ::nActive,2 ]
   ELSE
      nFirst := 1
      nEnd   := Len( ::aControls )
   ENDIF

   Return ::nActive

METHOD DeletePage( nPage ) CLASS HTab

   LOCAL nFirst, nEnd, i

   nFirst := ::aPages[ nPage,1 ] + 1
   nEnd   := ::aPages[ nPage,1 ] + ::aPages[ nPage,2 ]
   FOR i := nEnd TO nFirst STEP -1
      ::DelControl( ::aControls[i] )
   NEXT
   FOR i := nPage + 1 TO Len( ::aPages )
      ::aPages[ i,1 ] -= ( nEnd-nFirst+1 )
   NEXT

   hwg_Deletetab( ::handle, nPage - 1 )

   ADel( ::aPages, nPage )
   ASize( ::aPages, Len( ::aPages ) - 1 )

   ADel( :: aTabs, nPage )
   ASize( :: aTabs, Len( :: aTabs) - 1 )

   ADel( ::aTabDisabled, nPage )
   ASize( ::aTabDisabled, Len( ::aTabDisabled ) - 1 )

   * Delete the tooltip
   ADel( ::aTooltips , nPage )
   ASize( ::aTooltips, Len( ::aTooltips ) - 1 )

   IF nPage > 1
      ::nActive := nPage - 1
      ::SetTab( ::nActive )
   ELSEIF Len( ::aPages ) > 0
      ::nActive := 1
      ::SetTab( 1 )
   ENDIF

   RETURN ::nActive

METHOD Page( nPage ) CLASS HTab
   hb_default( @nPage, ::nActive )
RETURN HTabPage():New( Self, nPage )

METHOD SetTabDisabled( nPage, lDisable ) CLASS HTab
   hb_default( @lDisable, .T. )

   /* Keep Harbour logical array state synchronised */
   IF Len( ::aTabDisabled ) < nPage
      ASize( ::aTabDisabled, nPage )
   ENDIF
   ::aTabDisabled[ nPage ] := lDisable

   /* Delegate to the existing native GTK C wrapper in control.c */
   IF !Empty( ::handle )
      hwg_Settabdisabled( ::handle, nPage, lDisable )
   ENDIF
RETURN Nil

/*
 * ============================================================================
 * CROSS-PLATFORM COMPATIBILITY PATCH: HTabPage (GTK/Linux)
 * Provides uniform support for chained syntax: oTab:Page(x):Disable()
 * ============================================================================
 */
CREATE CLASS HTabPage

   DATA oTab
   DATA nTab

   METHOD New( oTab, nTab )
   METHOD Disable()
   METHOD Enable()
   METHOD IsDisabled()
   METHOD Handle()
   METHOD nChildId( nValue )
   METHOD AddControl( oCtrl )
   METHOD AddEvent( nMsg, nId, bAction, lNotify )
   METHOD AddNotify( nMsg, nId, bAction )

ENDCLASS

METHOD New( oTab, nTab ) CLASS HTabPage
   ::oTab := oTab
   ::nTab := nTab
RETURN Self

METHOD Disable() CLASS HTabPage
   IF ValType( ::oTab ) == "O"
      IF ! ::IsDisabled()
         ::oTab:SetTabDisabled( ::nTab, .T. )
      ENDIF
   ENDIF
RETURN Self

METHOD Enable() CLASS HTabPage
   IF ValType( ::oTab ) == "O"
      IF ::IsDisabled()
         ::oTab:SetTabDisabled( ::nTab, .F. )
      ENDIF
   ENDIF
RETURN Self

METHOD IsDisabled() CLASS HTabPage
   LOCAL lDis := .F.
   BEGIN SEQUENCE
      IF ValType( ::oTab ) == "O" .AND. ValType( ::oTab:aTabDisabled ) == "A"
         IF Len( ::oTab:aTabDisabled ) >= ::nTab
            lDis := ( ::oTab:aTabDisabled[ ::nTab ] == .T. )
         ENDIF
      ENDIF
   RECOVER
      lDis := .F.
   END SEQUENCE
RETURN lDis

METHOD Handle() CLASS HTabPage
RETURN IIF( ValType( ::oTab ) == "O", ::oTab:handle, 0 )

METHOD nChildId( nValue ) CLASS HTabPage
   LOCAL oHost
   oHost := IIF( ValType( ::oTab ) == "O" .AND. ValType( ::oTab:oParent ) == "O", ::oTab:oParent, ::oTab )
   IF ValType( oHost ) == "O"
      IF PCount() >= 1
         oHost:nChildId := nValue
      ENDIF
      RETURN oHost:nChildId
   ENDIF
RETURN 0

METHOD AddControl( oCtrl ) CLASS HTabPage
   LOCAL oHost
   oHost := IIF( ValType( ::oTab ) == "O" .AND. ValType( ::oTab:oParent ) == "O", ::oTab:oParent, ::oTab )
   IF ValType( oHost ) == "O"
      BEGIN SEQUENCE
         oHost:AddControl( oCtrl )
      RECOVER
      END SEQUENCE
   ENDIF
RETURN NIL

METHOD AddEvent( nMsg, nId, bAction, lNotify ) CLASS HTabPage
   LOCAL oHost
   oHost := IIF( ValType( ::oTab ) == "O" .AND. ValType( ::oTab:oParent ) == "O", ::oTab:oParent, ::oTab )
   IF ValType( oHost ) == "O"
      BEGIN SEQUENCE
         IF PCount() >= 4
            oHost:AddEvent( nMsg, nId, bAction, lNotify )
         ELSE
            oHost:AddEvent( nMsg, nId, bAction )
         ENDIF
      RECOVER
      END SEQUENCE
   ENDIF
RETURN NIL

METHOD AddNotify( nMsg, nId, bAction ) CLASS HTabPage
   LOCAL oHost
   oHost := IIF( ValType( ::oTab ) == "O" .AND. ValType( ::oTab:oParent ) == "O", ::oTab:oParent, ::oTab )
   IF ValType( oHost ) == "O"
      BEGIN SEQUENCE
         oHost:AddNotify( nMsg, nId, bAction )
      RECOVER
         BEGIN SEQUENCE
            oHost:AddEvent( nMsg, nId, bAction, .T. )
         RECOVER
         END SEQUENCE
      END SEQUENCE
   ENDIF
RETURN NIL
