/*
 *$Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTab class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"
#include "common.ch"

CLASS HTab INHERIT HControl

   CLASS VAR winclass   INIT "SysTabControl32"
   DATA  aTabs
   DATA  aPages  INIT {}
   DATA  bChange, bChange2
   DATA  hIml, aImages, Image1, Image2
   DATA  oTemp
   DATA  bAction
   DATA  lResourceTab INIT .F.
   DATA  aTooltips    INIT {}  // Array with tooltips messages
   DATA  aTabDisabled INIT {}  // .T. = aba desativada (tab disabled)
                               // One element for every tab

 /*  PATCH (compatibility)
    *  - Stores "Page(n)" objects to allow:
    *      oTab:Page(1):Disable()
    *      oTab:Page(1):Enable()
    *  - Does not interfere with the original HTab flow.
    */
   DATA  aPageObj INIT {}     // PATCH: cache of HTabPage
   DATA  nPrevSel INIT 0      // PATCH: (retained if you already use it in other logic)

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, aTabs, bChange, aImages, lResour, nBC, ;
      bClick, bGetFocus, bLostFocus, lOwnerDraw )
   METHOD Activate()
   METHOD Init()
   //METHOD onEvent( msg, wParam, lParam )
   METHOD SetTab( n )
   METHOD StartPage( cName, oDlg , ctooltip )
   METHOD EndPage()
   METHOD ChangePage( nPage )
   METHOD DeletePage( nPage )
   METHOD HidePage( nPage )
   METHOD ShowPage( nPage )
   METHOD GetActivePage( nFirst, nEnd )
   METHOD Notify( lParam )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem )
   METHOD SetTooltip( nhandle, ntab )
   METHOD SetTabDisabled( nTab, lDisabled )
   /* PATCH: API compatível com versões antigas */
   METHOD Page( nTab )

   HIDDEN:
   DATA  nActive  INIT 0         // Active Page

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, aTabs, bChange, aImages, lResour, nBC, bClick, bGetFocus, bLostFocus, lOwnerDraw ) CLASS HTab
   LOCAL i, aBmpSize

   lOwnerDraw := ( ValType( lOwnerDraw ) == "L" .AND. lOwnerDraw )

   nStyle   := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), WS_CHILD + WS_VISIBLE + WS_TABSTOP )

   IF lOwnerDraw
      nStyle := Hwg_BitOr( nStyle, TCS_OWNERDRAWFIXED )
   ENDIF

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint )

   ::title   := ""
   ::oFont   := iif( oFont == Nil, ::oParent:oFont, oFont )
   ::aTabs   := iif( aTabs == Nil, {}, aTabs )
   ::bChange := bChange
   ::bChange2 := bChange

   ::bGetFocus := iif( bGetFocus == Nil, Nil, bGetFocus )
   ::bLostFocus := iif( bLostFocus == Nil, Nil, bLostFocus )
   ::bAction   := iif( bClick == Nil, Nil, bClick )

   IF aImages != Nil
      ::aImages := {}
      FOR i := 1 TO Len( aImages )
         AAdd( ::aImages, Upper( aImages[i] ) )
         aImages[i] := iif( lResour, hwg_Loadbitmap( aImages[i] ), hwg_Openbitmap( aImages[i] ) )
      NEXT
      aBmpSize := hwg_Getbitmapsize( aImages[1] )
      ::himl := hwg_Createimagelist( aImages, aBmpSize[1], aBmpSize[2], 12, nBC )
      ::Image1 := 0
      IF Len( aImages ) > 1
         ::Image2 := 1
      ENDIF
   ENDIF

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
   LOCAL i

   IF !::lInit
      ::Super:Init()
      hwg_Inittabcontrol( ::handle, ::aTabs, IF( ::himl != Nil,::himl,0 ) )
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )

      IF ::himl != Nil
         hwg_Sendmessage( ::handle, TCM_SETIMAGELIST, 0, ::himl )
      ENDIF

      FOR i := 2 TO Len( ::aPages )
         ::HidePage( i )
      NEXT
      Hwg_InitTabProc( ::handle )
   ENDIF

   RETURN Nil
/*
METHOD onEvent( msg, wParam, lParam ) CLASS HTab

   LOCAL iParHigh, iParLow, nPos

   IF msg == WM_COMMAND
      IF ::aEvents != Nil
         iParHigh := hwg_Hiword( wParam )
         iParLow  := hwg_Loword( wParam )
         IF ( nPos := Ascan( ::aEvents, { |a|a[1] == iParHigh .AND. a[2] == iParLow } ) ) > 0
            Eval( ::aEvents[ nPos,3 ], Self, iParLow )
         ENDIF
      ENDIF
   ENDIF

   Return - 1
*/
METHOD SetTab( n ) CLASS HTab

   hwg_Sendmessage( ::handle, TCM_SETCURFOCUS, n - 1, 0 )

   RETURN Nil

// ----------------------------------------------------------
// SetTabDisabled( nTab, lDisabled )
// - Marks a tab as disabled (to block selection/gray it out)
// ----------------------------------------------------------
METHOD SetTabDisabled( nTab, lDisabled ) CLASS HTab

   LOCAL nNeed

   IF ValType( nTab ) <> "N" .OR. nTab <= 0
      RETURN Nil
   ENDIF

   lDisabled := ( ValType( lDisabled ) == "L" .AND. lDisabled )

   nNeed := Max( nTab, Len( ::aTabs ) )
   IF Len( ::aTabDisabled ) < nNeed
      ASize( ::aTabDisabled, nNeed )
      AEval( ::aTabDisabled, { |x,i| HB_SYMBOL_UNUSED(x), ;
         IIF( ::aTabDisabled[i] == NIL, .F., ::aTabDisabled[i] ) } )
   ENDIF

   ::aTabDisabled[ nTab ] := lDisabled

   IF !Empty( ::handle )
      hwg_RedrawWindow( ::handle )
   ENDIF

RETURN Nil


// -----------------------------------------------------
// Page( nTab )  [PATCH - compatibility]
// - Returns a "page object" with :Disable() / :Enable()
// -----------------------------------------------------
METHOD Page( nTab ) CLASS HTab

   LOCAL nNeed

   IF ValType( nTab ) <> "N" .OR. nTab <= 0
      RETURN Nil
   ENDIF

   nNeed := Max( nTab, Len( ::aTabs ) )

   IF Len( ::aPageObj ) < nNeed
      ASize( ::aPageObj, nNeed )
   ENDIF

   IF ::aPageObj[ nTab ] == NIL
      ::aPageObj[ nTab ] := HTabPage():New( Self, nTab )
   ENDIF

RETURN ::aPageObj[ nTab ]

METHOD StartPage( cname, oDlg , ctooltip ) CLASS HTab

   ::oTemp := ::oDefaultParent
   ::oDefaultParent := Self

   IF Len( ::aTabs ) > 0 .AND. Len( ::aPages ) == 0
      ::aTabs := {}
   ENDIF
   AAdd( ::aTabs, cname )
   if ::lResourceTab
      AAdd( ::aPages, { oDlg , 0 } )
   ELSE
      AAdd( ::aPages, { Len( ::aControls ), 0 } )
   ENDIF

  * Collect tooltips in the array
   AAdd( ::aTooltips , IIF ( ctooltip == NIL , "" , ctooltip ) )

   IF ::nActive > 1 .AND. !Empty( ::handle )
      ::HidePage( ::nActive )
   ENDIF
   ::nActive := Len( ::aPages )
   * Set tooltip
   ::SetTooltip( ::handle, ::nActive )

   RETURN Nil

METHOD EndPage() CLASS HTab

   IF !::lResourceTab
      ::aPages[ ::nActive,2 ] := Len( ::aControls ) - ::aPages[ ::nActive,1 ]
      IF !Empty( ::handle )
         hwg_Addtab( ::handle, ::nActive, ::aTabs[::nActive] )
      ENDIF
   ELSE
      IF !Empty( ::handle != Nil )
         hwg_Addtabdialog( ::handle, ::nActive, ::aTabs[::nActive], ::aPages[::nactive,1]:handle )
      ENDIF
   ENDIF

   IF ::nActive > 1 .AND. !Empty( ::handle )
      ::HidePage( ::nActive )
   ENDIF
   ::nActive := 1

   ::oDefaultParent := ::oTemp
   ::oTemp := Nil

   ::bChange = { |o, n|o:ChangePage( n ) }

   RETURN Nil

METHOD ChangePage( nPage ) CLASS HTab

   IF !Empty( ::aPages )
      ::HidePage( ::nActive )
      ::nActive := nPage
      ::ShowPage( ::nActive )
   ENDIF

   IF ::bChange2 != Nil
      Eval( ::bChange2, Self, nPage )
   ENDIF

   IF !Empty( ::aPages )
      * Set tooltip
      ::SetTooltip( ::handle, ::nActive )
   ENDIF

   RETURN Nil

METHOD HidePage( nPage ) CLASS HTab

   LOCAL i, nFirst, nEnd

   IF !::lResourceTab
      nFirst := ::aPages[ nPage,1 ] + 1
      nEnd   := ::aPages[ nPage,1 ] + ::aPages[ nPage,2 ]
      FOR i := nFirst TO nEnd
         ::aControls[i]:Hide()
      NEXT
   ELSE
      ::aPages[nPage,1]:Hide()
   ENDIF

   RETURN Nil

METHOD ShowPage( nPage ) CLASS HTab

   LOCAL i, nFirst, nEnd

   IF !::lResourceTab
      nFirst := ::aPages[ nPage,1 ] + 1
      nEnd   := ::aPages[ nPage,1 ] + ::aPages[ nPage,2 ]
      FOR i := nFirst TO nEnd
         ::aControls[i]:Show()
      NEXT
      FOR i := nFirst TO nEnd
         IF __ObjHasMsg( ::aControls[i], "BSETGET" ) .AND. ::aControls[i]:bSetGet != Nil
            hwg_Setfocus( ::aControls[i]:handle )
            EXIT
         ENDIF
      NEXT
   ELSE
      ::aPages[nPage,1]:Show()
      FOR i := 1  TO Len( ::aPages[nPage,1]:aControls )
         IF __ObjHasMsg( ::aPages[nPage,1]:aControls[i], "BSETGET" ) .AND. ::aPages[nPage,1]:aControls[i]:bSetGet != Nil
            hwg_Setfocus( ::aPages[nPage,1]:aControls[i]:handle )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

METHOD GetActivePage( nFirst, nEnd ) CLASS HTab

   IF !::lResourceTab
      IF !Empty( ::aPages )
         nFirst := ::aPages[ ::nActive,1 ] + 1
         nEnd   := ::aPages[ ::nActive,1 ] + ::aPages[ ::nActive,2 ]
      ELSE
         nFirst := 1
         nEnd   := Len( ::aControls )
      ENDIF
   ENDIF

   Return ::nActive

METHOD DeletePage( nPage ) CLASS HTab

   LOCAL nFirst, nEnd, i

   if ::lResourceTab
      ADel( ::m_arrayStatusTab, nPage, , .T. )
      hwg_Deletetab( ::handle, nPage )
      ::nActive := nPage - 1

   ELSE

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
   ENDIF

   RETURN ::nActive

METHOD Notify( lParam ) CLASS HTab

   LOCAL nCode := hwg_Getnotifycode( lParam )
   LOCAL nTabTry

   DO CASE
   CASE nCode == TCN_SELCHANGING
      nTabTry := hwg_Getcurrenttab( ::handle )
      IF ValType( nTabTry ) == "N" .AND. nTabTry > 0 .AND. ;
         Len( ::aTabDisabled ) >= nTabTry .AND. ::aTabDisabled[ nTabTry ] == .T.
         RETURN 1
      ENDIF
      RETURN 0

   CASE nCode == TCN_SELCHANGE
      IF ::bChange != Nil
         Eval( ::bChange, Self, hwg_Getcurrenttab( ::handle ) )
      ENDIF
   CASE nCode == TCN_CLICK
      IF ::bAction != Nil
         Eval( ::bAction, Self, hwg_Getcurrenttab( ::handle ) )
      ENDIF
   CASE nCode == TCN_SETFOCUS
      IF ::bGetFocus != NIL
         Eval( ::bGetFocus, Self, hwg_Getcurrenttab( ::handle ) )
      ENDIF
   CASE nCode == TCN_KILLFOCUS
      IF ::bLostFocus != NIL
         Eval( ::bLostFocus, Self, hwg_Getcurrenttab( ::handle ) )
      ENDIF
   ENDCASE

   RETURN -1

/* aItem and cCaption added */
METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem )  CLASS hTab

     * Parameters not used
    HB_SYMBOL_UNUSED(cCaption)
    HB_SYMBOL_UNUSED(lTransp)
    HB_SYMBOL_UNUSED(aItem)


   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::lResourceTab := .T.
   ::aTabs := {}
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   RETURN Self

METHOD SetTooltip( nhandle, ntab ) CLASS hTab

  LOCAL cText

  IF nhandle == NIL
   RETURN NIL && Nothing to do, avoid crash
  ENDIF

  cText := ::aTooltips[ntab]

  IF cText == NIL
    RETURN NIL
  ENDIF
  IF EMPTY(cText)
    RETURN NIL
  ENDIF
  hwg_Deltooltip( nhandle )
  IF .NOT. EMPTY(cText)
   hwg_Addtooltip( nhandle, cText )
  ENDIF

   RETURN NIL

/*
 * ============================================================================
 * PATCH (compatibility): HTabPage
 * - Enables syntax:
 *     ThisForm:oTab:Page( x ):Disable()
 *     ThisForm:oTab:Page( x ):Enable()
 * - Encapsulates SetTabDisabled() without modifying the rest of HWGUI.
 * ============================================================================
 */
CLASS HTabPage

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
