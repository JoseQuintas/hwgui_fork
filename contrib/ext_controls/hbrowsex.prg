/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HBrowseEx class - browse databases and arrays
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

   // Modificaciones y Agregados. 27.07.2002, WHT.de la Argentina ///////////////
   // 1) En el metodo HColumn se agregaron las DATA: "nJusHead" y "nJustLin",  //
   //    para poder justificar los encabezados de columnas y tambien las       //
   //    lineas. Por default es DT_LEFT                                        //
   //    0-DT_LEFT, 1-DT_RIGHT y 2-DT_CENTER. 27.07.2002. WHT.                 //
   // 2) Ahora la variable "cargo" del metodo HBrowseEx si es codeblock          //
   //    ejectuta el CB. 27.07.2002. WHT                                       //
   // 3) Se agreg¢ el Metodo "ShowSizes". Para poder ver la "width" de cada    //
   //    columna. 27.07.2002. WHT.                                             //
   //////////////////////////////////////////////////////////////////////////////

#include "hwgui.ch"
#include "hwg_extctrl.ch"

#include "common.ch"
#include "inkey.ch"
#include "dbstruct.ch"
#include "hbclass.ch"

#ifdef __XHARBOUR__
#xtranslate hb_RAScan([<x,...>])        => RAScan(<x>)
#xtranslate hb_tokenGet([<x>,<n>,<c>] ) =>  __StrToken(<x>,<n>,<c>)
#endif

   REQUEST DBGoTop
   REQUEST DBGoTo
   REQUEST DBGoBottom
   REQUEST DBSkip
   REQUEST RecCount
   REQUEST RecNo
   REQUEST Eof
   REQUEST Bof

   /* Moved to windows.ch */
   //#define HDM_GETITEMCOUNT    4608
   
#define RT_MANIFEST         24

   STATIC ColSizeCursor := 0
   STATIC arrowCursor := 0
   STATIC downCursor := 0
   STATIC oCursor     := 0
   STATIC oPen64
   STATIC xDrag
   STATIC xDragMove := 0
   STATIC axPosMouseOver := { 0, 0 }
   STATIC xToolTip

   //----------------------------------------------------//

CLASS HColumnEx INHERIT HObject

   DATA oParent
   DATA block, heading, footing, width, Type
   DATA length INIT 0
   DATA dec, cargo
   DATA nJusHead, nJusLin, nJusFoot        // Para poder Justificar los Encabezados
   // de las columnas y lineas.
   DATA tcolor, bcolor, brush
   DATA oFont
   DATA lEditable INIT .F.       // Is the column editable
   DATA aList                    // Array of possible values for a column -
   // combobox will be used while editing the cell
   DATA aBitmaps
   DATA bValid, bWhen, bclick    // When and Valid codeblocks for cell editing
   DATA bEdit                    // Codeblock, which performs cell editing, if defined
   DATA cGrid                    // Specify border for Header (SNWE), can be
   // multiline if separated by ;
   DATA lSpandHead INIT .F.
   DATA lSpandFoot INIT .F.
   DATA PICTURE
   DATA bHeadClick
   DATA bHeadRClick
   DATA bColorFoot               //   bColorFoot must return an array containing two colors values
   //   oBrowse:aColumns[1]:bColorFoot := {|| IF (nNumber < 0, ;
   //      {textColor, backColor} , ;
   //      {textColor, backColor} ) }

   DATA bColorBlock              //   bColorBlock must return an array containing four colors values
   //   oBrowse:aColumns[1]:bColorBlock := {|| IF (nNumber < 0, ;
   //      {textColor, backColor, textColorSel, backColorSel} , ;
   //      {textColor, backColor, textColorSel, backColorSel} ) }
   DATA headColor                // Header text color
   DATA FootFont                // Footing font
   DATA lHeadClick   INIT .F.
   DATA lHide INIT .F. // HIDDEN
   DATA Column
   DATA nSortMark INIT 0
   DATA Resizable INIT .T.
   DATA ToolTip
   DATA aHints INIT {}
   DATA Hint INIT .F.

   METHOD New( cHeading, block, Type, length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bWhen, aItem, bColorBlock, bHeadClick, tcolor, bColor, bClick )
   METHOD Visible( lVisible ) SETGET
   METHOD Hide()
   METHOD Show()
   METHOD SortMark( nSortMark ) SETGET
   METHOD Value( xValue ) SETGET
   METHOD Editable( lEditable ) SETGET

ENDCLASS

   //----------------------------------------------------//

METHOD New( cHeading, block, Type, length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bWhen, aItem, bColorBlock, bHeadClick, tcolor, bcolor, bClick ) CLASS HColumnEx

   ::heading   := iif( cHeading == NIL, "", cHeading )
   ::block     := block
   ::Type      := iif( Type != NIL, Upper( Type ), Type )
   ::length    := length
   ::dec       := dec
   ::lEditable := iif( lEditable != NIL, lEditable, ::lEditable )
   ::nJusHead  := iif( nJusHead == NIL,  DT_LEFT, nJusHead ) + DT_VCENTER + DT_SINGLELINE // Por default
   ::nJusLin   := nJusLin //IIf( nJusLin  == NIL,  DT_LEFT, nJusLin  ) + DT_VCENTER + DT_SINGLELINE // Justif.Izquierda
   ::nJusFoot  := iif( nJusLin  == NIL, DT_LEFT, nJusLin  )
   ::picture   := cPict
   ::bValid    := bValid
   ::bWhen     := bWhen
   ::aList     := aItem
   ::bColorBlock := bColorBlock
   ::bHeadClick  := bHeadClick
   ::footing   := ""
   ::tcolor    := tcolor
   ::bcolor    := bcolor
   ::bClick    := bClick

   RETURN Self

METHOD Visible( lVisible ) CLASS HColumnEx

   IF lVisible != NIL
      IF ! lVisible
         ::Hide()
      ELSE
         ::Show()
      ENDIF
      ::lHide := ! lVisible
   ENDIF

   RETURN ! ::lHide

METHOD Hide( ) CLASS HColumnEx

   ::lHide := .T.
   ::oParent:Refresh()

   RETURN ::lHide

METHOD Show( ) CLASS HColumnEx

   ::lHide := .F.
   ::oParent:Refresh()

   RETURN ::lHide

METHOD Editable( lEditable ) CLASS HColumnEx

   IF lEditable != NIL
      ::lEditable := lEditable
      ::oParent:lEditable := lEditable .OR. Ascan( ::oParent:aColumns, { | c |  c:lEditable } ) > 0
      hwg_Redrawwindow( ::oParent:handle, RDW_INVALIDATE + RDW_INTERNALPAINT )
   ENDIF

   RETURN ::lEditable

METHOD SortMark( nSortMark ) CLASS HColumnEx

   IF nSortMark != NIL
      AEval( ::oParent:aColumns, { | c | c:nSortMark := 0 } )
      ::oParent:lHeadClick := .T.
      hwg_Invalidaterect( ::oParent:handle, 0, ::oParent:x1, ::oParent:y1 - ::oParent:nHeadHeight * ::oParent:nHeadRows, ::oParent:x2, ::oParent:y1 )
      ::oParent:lHeadClick := .F.
      ::nSortMark := nSortMark
   ENDIF

   RETURN ::nSortMark

METHOD Value( xValue ) CLASS HColumnEx
   LOCAL varbuf

   IF xValue != NIL
      varbuf := xValue
      IF ::oParent:Type == BRW_DATABASE
         IF ( ::oParent:Alias ) -> ( RLock() )
            ( ::oParent:Alias ) -> ( Eval( ::block, varbuf, ::oParent, ::Column ) )
            ( ::oParent:Alias ) -> ( dbUnlock() )
         ELSE
            hwg_Msgstop( "Can't lock the record!" )
         ENDIF
      ELSEIF ::oParent:nRecords  > 0
         Eval( ::block,  varbuf, ::oParent, ::Column )
      ENDIF
      /* Execute block after changes are made */
      IF ::oParent:bUpdate != NIL // .AND. ! ::oParent:lSuspendMsgsHandling
         //::oParent:lSuspendMsgsHandling := .T.
         Eval( ::oParent:bUpdate, ::oParent, ::Column )
         //::oParent:lSuspendMsgsHandling := .F.
      ENDIF
   ELSE
      IF ::oParent:Type == BRW_DATABASE
         varbuf := ( ::oParent:Alias ) -> ( Eval( ::block,, ::oParent, ::Column ) )
      ELSEIF ::oParent:nRecords  > 0
         varbuf :=  Eval( ::block, , ::oParent, ::Column )
      ENDIF
   ENDIF

   RETURN varbuf

   //----------------------------------------------------//

CLASS HBrowseEx INHERIT HControl, HThemed

   DATA winclass   INIT "HBOARD"
   DATA active     INIT .T.
   DATA lChanged   INIT .F.
   DATA lDispHead  INIT .T.                    // Should I display headers ?
   DATA lDispSep   INIT .T.                    // Should I display separators ?
   DATA aColumns                               // HColumnEx's array
   DATA aColAlias  INIT { }
   DATA aRelation  INIT .F.
   DATA rowCount   INIT 0                       // Number of visible data rows
   DATA rowPos     INIT 1                       // Current row position
   DATA rowCurrCount INIT 0                     // Current number of rows
   DATA colPos     INIT 1                       // Current column position
   DATA nColumns   INIT 0                       // Number of visible data columns
   DATA nLeftCol                                // Leftmost column
   DATA freeze     INIT 0                       // Number of columns to freeze
   DATA nRecords   INIT 0                       // Number of records in browse
   DATA nCurrent   INIT 1                       // Current record
   DATA aArray                                  // An array browsed if this is BROWSE ARRAY
   DATA recCurr    INIT 0
   DATA headColor                               // Header text color
   DATA sepColor   INIT 12632256                // Separators color
   DATA lSep3d     INIT .F.
   DATA lInFocus   INIT .F.                     // Set focus in :Paint()
   DATA varbuf                                  // Used on Edit()
   DATA tcolorSel, bcolorSel, brushSel, htbColor, httColor // Hilite Text Back Color
   DATA bSkip, bGoTo, bGoTop, bGoBot, bEof, bBof
   DATA bRcou, bRecno, bRecnoLog
   DATA bPosChanged, bLineOut
   DATA bScrollPos                             // Called when user move browse through vertical scroll bar
   DATA bHScrollPos                            // Called when user move browse through horizontal scroll bar
   DATA bEnter, bKeyDown, bUpdate, bRclick
   DATA bChangeRowCol
   DATA internal
   DATA ALIAS                                  // Alias name of browsed database
   DATA x1, y1, x2, y2, width, height, xAdjRight
   DATA minHeight INIT 0
   DATA forceHeight INIT 0                     // force Row height in pixel, set by SetRowHeight
   DATA lEditable INIT .T.
   DATA lAppable  INIT .F.
   DATA lAppMode  INIT .F.
   DATA lAutoEdit INIT .F.
   DATA lUpdated  INIT .F.
   DATA lAppended INIT .F.
   DATA lESC      INIT .F.
   DATA lAdjRight INIT .T.                     // Adjust last column to right
   DATA oEditDlg
   DATA nHeadRows INIT 1                       // Rows in header
   DATA nHeadHeight INIT 0                     // Pixel height in header for footer (if present) or std font
   DATA nFootHeight INIT 0                     // Pixel height in footer for standard font
   DATA nFootRows INIT 0                       // Rows in footer
   DATA lResizing INIT .F.                     // .T. while a column resizing is undergoing
   DATA lCtrlPress INIT .F.                    // .T. while Ctrl key is pressed
   DATA lShiftPress INIT .F.                    // .T. while Shift key is pressed
   DATA aSelected                              // An array of selected records numbers
   DATA nWheelPress INIT 0                        // wheel or central button mouse pressed flag
   DATA oHeadFont
   DATA lDescend INIT .F.              // Descend Order?
   DATA lFilter INIT .F.               // Filtered? (atribuition is automatic in method "New()").
   DATA bFirst INIT { || DBGoTop() }     // Block to place pointer in first record of condition filter. (Ex.: DbGoTop(), DbSeek(), etc.).
   DATA bLast  INIT { || dbGoBottom() }  // Block to place pointer in last record of condition filter. (Ex.: DbGoBottom(), DbSeek(), etc.).
   DATA bWhile INIT { || .T. }           // Clausule "while". Return logical.
   DATA bFor INIT { || .T. }             // Clausule "for". Return logical.
   DATA nLastRecordFilter INIT 0       // Save the last record of filter.
   DATA nFirstRecordFilter INIT 0      // Save the first record of filter.
   DATA nPaintRow, nPaintCol                   // Row/Col being painted
   DATA aMargin INIT { 0, 0, 0, 0 } PROTECTED  // Margin TOP-RIGHT-BOTTOM-LEFT
   DATA lRepaintBackground INIT .F. HIDDEN    // Set to true performs a canvas fill before painting rows
   DATA lHeadClick  INIT  .F.    // .T. while a HEADER column is CLICKED
   DATA nyHeight    INIT  0
   DATA fipos      HIDDEN
   DATA lDeleteMark INIT .F.   HIDDEN
   DATA lShowMark   INIT .T.   HIDDEN
   DATA nDeleteMark INIT 0     HIDDEN
   DATA nShowMark   INIT 12    HIDDEN
   DATA oBmpMark    INIT  HBitmap():AddStandard( OBM_MNARROW ) HIDDEN
   DATA ShowSortMark  INIT .T.
   DATA nWidthColRight INIT 0  HIDDEN
   DATA nVisibleColLeft INIT 0 HIDDEN
   // one to many relationships
   DATA cLinkMaster             // Specifies the parent table linked to the child table displayed in a Grid control.
   DATA ChildOrder             // Specifies the index tag for the record source of the Grid control or Relation object.
   DATA RelationalExpr         // Specifies the expression based on fields in the parent table that relates to an index in the child table joining the two tables
   DATA aRecnoFilter   INIT {}
   DATA nIndexOrd INIT - 1 HIDDEN
   DATA nRecCount INIT 0  HIDDEN
   // ADD THEME IN BROWSE
   DATA m_bFirstTime  INIT .T.
   DATA xPosMouseOver INIT  0
   DATA isMouseOver   INIT .F.
   DATA allMouseOver  INIT .F.
   DATA AutoColumnFit INIT  0   // 0-Enable / 2  Disables capability for columns to fit data automatically.
   DATA nAutoFit
   DATA lNoVScroll   INIT .F.
   DATA lDisableVScrollPos INIT .F.
   DATA oTimer  HIDDEN
   DATA nSetRefresh  INIT 0 HIDDEN
   DATA Highlight        INIT .F. // only editable is Highlight
   DATA HighlightStyle   INIT  1  // 0 No color highlighting for grid row
   // 1 Enable highlighting for current row. (Default)
   // 2 nopersit highlighting //for current row and current cell
   // 3 nopersist when grid is not the current active control.

   METHOD New( lType, oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, ;
      lNoBorder, lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect, ;
      lDescend, bWhile, bFirst, bLast, bFor, bOther, tcolor, bcolor, brclick, bChgRowCol, ctooltip )
   METHOD InitBrw( nType, lInit )
   METHOD Rebuild()
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Redefine( lType, oWndParent, nId, oFont, bInit, bSize, bPaint, bEnter, bGfocus, bLfocus )
   METHOD FindBrowse( nId )
   METHOD AddColumn( oColumn )
   METHOD InsColumn( oColumn, nPos )
   METHOD DelColumn( nPos )
   METHOD Paint( lLostFocus )
   METHOD LineOut( nRow, nCol, hDC, lSelected, lClear )
   METHOD SELECT()
   METHOD HeaderOut( hDC )
   METHOD SeparatorOut( hDC, nRowsFill )
   METHOD FooterOut( hDC )
   METHOD SetColumn( nCol )
   METHOD DoHScroll( wParam )
   METHOD DoVScroll( wParam )
   METHOD LineDown( lMouse )
   METHOD LineUp()
   METHOD PageUp()
   METHOD PageDown()
   METHOD Bottom( lPaint )
   METHOD Top()
   METHOD Home()  INLINE ::DoHScroll( SB_LEFT )
   METHOD ButtonDown( lParam, lReturnRowCol )
   METHOD ButtonUp( lParam )
   METHOD ButtonDbl( lParam )
   METHOD MouseMove( wParam, lParam )
   METHOD MouseWheel( nKeys, nDelta, nXPos, nYPos )
   METHOD Edit( wParam, lParam )
   METHOD APPEND() INLINE ( ::Bottom( .F. ), ::LineDown() )
   METHOD onClick( )
   METHOD RefreshLine()
   METHOD Refresh( lFull, lLineUp )
   METHOD ShowSizes()
   METHOD END()
   METHOD SetMargin( nTop, nRight, nBottom, nLeft )
   METHOD SetRowHeight( nPixels )
   METHOD FldStr( oBrw, numf )
   METHOD LinkMaster( cLinkMaster ) SETGET
   METHOD Filter( lFilter ) SETGET
   //
   METHOD WhenColumn( value, oGet )
   METHOD ValidColumn( value, oGet, oBtn )
   METHOD onClickColumn( value, oGet, oBtn )
   METHOD EditEvent( oCtrl, msg, wParam, lParam )
   METHOD ButtonRDown( lParam )
   METHOD ShowMark( lShowMark ) SETGET
   METHOD DeleteMark( lDeleteMark ) SETGET
   // METHOD BrwScrollVPos()
   // new
   METHOD ShowColToolTips( lParam )
   METHOD SetRefresh( nSeconds ) SETGET
   METHOD When()
   METHOD Valid()
   METHOD ChangeRowCol( nRowColChange )
   METHOD EditLogical( wParam, lParam )   HIDDEN
   METHOD AutoFit()

ENDCLASS

   //----------------------------------------------------//

METHOD New( lType, oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, ;
      lNoBorder, lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect, ;
      lDescend, bWhile, bFirst, bLast, bFor, bOther, tcolor, bcolor, bRclick, bChgRowCol, ctooltip ) CLASS HBrowseEx

   lNoVScroll := iif( lNoVScroll = NIL , .F. , lNoVScroll )
   nStyle := Hwg_BitOr( iif( nStyle == NIL, 0, nStyle ), WS_CHILD + WS_VISIBLE + WS_TABSTOP + ;
      iif( lNoBorder = NIL .OR. ! lNoBorder, WS_BORDER, 0 ) +            ;
      iif( ! lNoVScroll, WS_VSCROLL, 0 ) )
   nStyle -= iif( Hwg_BitAND( nStyle, WS_VSCROLL ) > 0 .AND. lNoVScroll, WS_VSCROLL, 0 )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, iif( nWidth == NIL, 0, nWidth ), ;
      iif( nHeight == NIL, 0, nHeight ), oFont, bInit, bSize, bPaint, ctooltip , tColor, bColor )
   ::lNoVScroll := lNoVScroll
   ::Type    := lType
   IF oFont == NIL
      ::oFont := ::oParent:oFont
   ENDIF
   ::bEnter  := bEnter
   ::bRclick := bRclick
   ::bGetFocus   := bGfocus
   ::bLostFocus  := bLfocus
   ::bOther :=  bOther
   ::lAppable      := iif( lAppend == NIL, .F. , lAppend )
   ::lAutoedit     := iif( lAutoedit == NIL, .F. , lAutoedit )
   ::bUpdate       := bUpdate
   ::bKeyDown      := bKeyDown
   ::bPosChanged   := bPosChg
   ::bChangeRowCol := bChgRowCol
   IF lMultiSelect != NIL .AND. lMultiSelect
      ::aSelected := { }
   ENDIF
   ::lDescend    := iif( lDescend == NIL, .F. , lDescend )
   IF ISBLOCK( bFirst ) .OR. ISBLOCK( bFor ) .OR. ISBLOCK( bWhile )
      ::lFilter := .T.
      IF ISBLOCK( bFirst )
         ::bFirst := bFirst
      ENDIF
      IF ISBLOCK( bLast )
         ::bLast := bLast
      ENDIF
      IF ISBLOCK( bWhile )
         ::bWhile := bWhile
      ENDIF
      IF ISBLOCK( bFor )
         ::bFor := bFor
      ENDIF
   ELSE
      ::lFilter := .F.
   ENDIF
   hwg_RegBoard()
   ::InitBrw( , .F. )
   ::Activate()

   RETURN Self

   //----------------------------------------------------//

METHOD Activate() CLASS HBrowseEx

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_CreateBoard( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD Init() CLASS HBrowseEx

   IF ! ::lInit
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      ::Super:Init()
      ::InitBrw( , .T. )
      IF hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
         hwg_GetParentForm( Self ):lDisableCtrlTab := .T.
      ENDIF
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD SetMargin( nTop, nRight, nBottom, nLeft )  CLASS HBrowseEx
   LOCAL aOldMargin := AClone( ::aMargin )

   IF nTop == NIL
      nTop := 0
   ENDIF

   IF nRight == NIL
      nRight := nBottom := nLeft := nTop
   ENDIF

   IF nBottom == NIL
      nBottom := nTop
      nLeft := nRight
   ENDIF

   ::aMargin := { nTop, nRight, nBottom, nLeft }

   RETURN aOldMargin

   //----------------------------------------------------//

METHOD SetRowHeight( nPixels ) CLASS HBrowseEx
   LOCAL nOldPixels

   nOldPixels := ::forceHeight

   IF ValType( nPixels ) == "N"
      IF nPixels > 0
         ::forceHeight := nPixels
         IF nPixels != nOldPixels .AND. ::rowCurrCount > 0  //nando
            ::lRepaintBackground := .T.
            ::Rebuild()
            ::Refresh()
         ENDIF
      ELSE
         ::forceHeight := 0
      ENDIF
   ENDIF

   RETURN( nOldPixels )

   //----------------------------------------------------//

METHOD onEvent( msg, wParam, lParam )  CLASS HBrowseEx
   LOCAL oParent, cKeyb, nCtrl, nPos, lBEof, iParHigh, iParLow
   LOCAL nRecStart, nRecStop, nRet, nShiftAltCtrl

   IF ::active .AND. ! Empty( ::aColumns )
      // moved to first
      IF msg == WM_MOUSEWHEEL //.AND. ! ::oParent:lSuspendMsgsHandling
         ::isMouseOver := .F.
         ::MouseWheel( hwg_Loword( wParam ), ;
            iif( hwg_Hiword( wParam ) > 32768, ;
            hwg_Hiword( wParam ) - 65535, hwg_Hiword( wParam ) ), ;
            hwg_Loword( lParam ), hwg_Hiword( lParam ) )
         // RETURN 0 because bother is not run
      ENDIF
      //
      IF ::bOther != NIL
         IF ValType( nRet := Eval( ::bOther,Self,msg,wParam,lParam ) ) != "N"
            nRet := iif( ValType( nRet ) = "L" .AND. ! nRet, 0, - 1 )
         ENDIF
         IF nRet >= 0
            RETURN - 1
         ENDIF
      ENDIF
      IF msg == WM_THEMECHANGED
         IF ::Themed
            IF ValType( ::hTheme ) == "P"
               hwg_closethemedata( ::htheme )
               ::hTheme := NIL
            ENDIF
            ::Themed := .F.
         ENDIF
         ::m_bFirstTime := .T.
         hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
         RETURN 0
      ENDIF
      IF msg == WM_PAINT
         ::Paint()
         RETURN 1
      ELSEIF msg == WM_ERASEBKGND
         RETURN 0
      ELSEIF msg = WM_SIZE
         //::oParent:lSuspendMsgsHandling := .F.
         ::lRepaintBackground := .T.
         ::isMouseOver := .F.
         IF ::AutoColumnFit = 1
            IF ! hwg_Iswindowvisible( ::oParent:Handle )
               ::Rebuild()
               ::lRepaintBackground := .F.
            ENDIF
            ::AutoFit()
         ENDIF
      ELSEIF msg = WM_SETFONT .AND. ::oHeadFont = NIL .AND. ::lInit
         ::nHeadHeight := 0
         ::nFootHeight := 0
      ELSEIF msg == WM_SETFOCUS //.AND. ! ::lSuspendMsgsHandling
         ::When()
      ELSEIF msg == WM_KILLFOCUS //.AND. ! ::lSuspendMsgsHandling
         ::Valid()
         ::internal[ 1 ] := 15 //force redraw header,footer and separator
      ELSEIF msg == WM_HSCROLL
         ::DoHScroll( wParam )
      ELSEIF msg == WM_VSCROLL
         ::DoVScroll( wParam )
      ELSEIF msg == WM_CHAR
         wParam := hwg_PtrToUlong( wParam )
         IF ! hwg_Checkbit( lParam, 32 )
            nShiftAltCtrl := iif( hwg_IsCtrlShift( .F. , .T. ), 1 , 0 )
            nShiftAltCtrl += iif( hwg_IsCtrlShift( .T. , .F. ), 2 , nShiftAltCtrl )
            /*
            IF ::bKeyDown != NIL .AND. ValType( ::bKeyDown ) == 'B' .AND. wParam != VK_TAB .AND. wParam != VK_RETURN
               IF Empty( nRet := Eval( ::bKeyDown, Self, wParam, nShiftAltCtrl, msg ) ) .AND. nRet != NIL
                  RETURN 0
               ENDIF
            ENDIF
            */
            IF wParam == VK_RETURN .OR. wParam == VK_ESCAPE
               RETURN - 1
            ENDIF
            IF ::lAutoEdit .OR. ::aColumns[ ::SetColumn() ]:lEditable
               ::Edit( wParam, lParam )
            ENDIF
         ENDIF
      ELSEIF msg == WM_GETDLGCODE
         ::isMouseOver := .F.
         wParam := hwg_PtrToUlong( wParam )
         IF wParam = VK_ESCAPE   .AND. ;          // DIALOG MODAL
               ( oParent := hwg_GetParentForm( Self ):FindControl( IDCANCEL ) ) != NIL .AND. ! oParent:Enabled
            RETURN DLGC_WANTMESSAGE
         ELSEIF ( wParam = VK_ESCAPE .AND. hwg_GetParentForm( Self ):handle != ::oParent:Handle .AND. ::lEsc ) .OR. ; //! ::lAutoEdit
            ( wParam = VK_RETURN .AND. hwg_GetParentForm( Self ):FindControl( IDOK ) != NIL )
            RETURN - 1
         ENDIF
         RETURN DLGC_WANTALLKEYS
      ELSEIF msg == WM_COMMAND
         IF hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
            hwg_GetParentForm( Self ):onEvent( msg, wparam, lparam )
         ELSEIF ::aEvents != Nil
            iParHigh := hwg_Hiword( wParam )
            iParLow  := hwg_Loword( wParam )           
            IF ( nPos := AScan( ::aEvents, {|a|a[1] == iParHigh .AND. a[2] == iParLow } ) ) > 0
               //IF ! ::lSuspendMsgsHandling
                  Eval( ::aEvents[nPos,3], Self, iParLow )
               //ENDIF
            ENDIF
         ENDIF
      ELSEIF msg == WM_KEYUP
         wParam := hwg_PtrToUlong( wParam )
         IF wParam == 17
            ::lCtrlPress := .F.
         ENDIF
         IF wParam == 16
            ::lShiftPress := .F.
         ENDIF
         IF wParam == VK_TAB .AND. hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
            IF hwg_IsCtrlShift( .T. , .F. )
               hwg_GetSkip( ::oParent, ::handle, ;
                  iif( hwg_IsCtrlShift( .F. , .T. ), - 1, 1 ) )
               RETURN 0
            ENDIF
         ENDIF
         IF wParam != VK_SHIFT .AND. wParam != VK_CONTROL .AND. wParam != 18
            oParent := ::oParent
            DO WHILE oParent != NIL .AND. ! __ObjHasMsg( oParent, "GETLIST" )
               oParent := oParent:oParent
            ENDDO
            IF oParent != NIL .AND. ! Empty( oParent:KeyList )
               cKeyb := hwg_Getkeyboardstate()
               nCtrl := iif( Asc( SubStr( cKeyb, VK_CONTROL + 1, 1 ) ) >= 128, FCONTROL, iif( Asc( SubStr( cKeyb, VK_SHIFT + 1, 1 ) ) >= 128, FSHIFT, 0 ) )
               IF ( nPos := AScan( oParent:KeyList, { | a | a[ 1 ] == nCtrl .AND. a[ 2 ] == wParam } ) ) > 0
                  Eval( oParent:KeyList[ nPos, 3 ], Self )
               ENDIF
            ENDIF
         ENDIF
         RETURN 1
      ELSEIF msg == WM_KEYDOWN //.AND. ! ::oParent:lSuspendMsgsHandling
         wParam := hwg_PtrToUlong( wParam )
         /*IF ( ( hwg_Checkbit( lParam, 25 ) .AND. wParam != 111 ) .OR.  ( wParam > 111 .AND. wParam < 124 ) .OR. ;
               wParam = VK_TAB .OR. wParam = VK_RETURN )   .AND. ; */
         IF ::bKeyDown != NIL .AND. ValType( ::bKeyDown ) == 'B'
            nShiftAltCtrl := iif( hwg_IsCtrlShift( .F. , .T. ), 1 , 0 )
            nShiftAltCtrl += iif( hwg_IsCtrlShift( .T. , .F. ), 2 , nShiftAltCtrl )
            nShiftAltCtrl += iif( wParam > 111, 4, nShiftAltCtrl )
            IF Empty( nRet := Eval( ::bKeyDown, Self, wParam, nShiftAltCtrl, msg ) ) .AND. nRet != NIL
               RETURN 0
            ENDIF
         ENDIF
         ::isMouseOver := .F.
         IF wParam == VK_PRIOR .OR. wParam == VK_NEXT .OR. wParam == VK_UP .OR. wParam == VK_DOWN
            IF ! ::ChangeRowCol( 1 )
               RETURN - 1
            ENDIF
         ENDIF
         IF wParam == VK_TAB
            IF ::lCtrlPress
               hwg_GetSkip( ::oParent, ::handle, ;
                  iif( hwg_IsCtrlShift( .F. , .T. ), - 1, 1 ) )
               RETURN 0
            ELSE
               ::DoHScroll( iif( hwg_IsCtrlShift( .F. , .T. ), SB_LINELEFT, SB_LINERIGHT ) )
            ENDIF
         ELSEIF wParam == VK_DOWN //40        // Down
            IF ::lShiftPress .AND. ::aSelected != NIL
               Eval( ::bskip, Self, 1 )
               lBEof := Eval( ::beof, Self )
               Eval( ::bskip, Self, - 1 )
               IF ! ( lBEof .AND. AScan( ::aSelected, Eval( ::bRecno, Self ) ) > 0 )
                  ::Select()
                  IF lBEof
                     ::refreshline()
                  ENDIF
               ENDIF
            ENDIF
            ::LINEDOWN()
         ELSEIF wParam == VK_UP //38    // Up
            IF ::lShiftPress .AND. ::aSelected != NIL
               Eval( ::bskip, Self, 1 )
               lBEof := Eval( ::beof, Self )
               Eval( ::bskip, Self, - 1 )
               IF ! ( lBEof .AND. AScan( ::aSelected, Eval( ::bRecno, Self ) ) > 0 )
                  ::LINEUP()
               ENDIF
            ELSE
               ::LINEUP()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != NIL
               Eval( ::bskip, Self, - 1 )
               IF ! lBEof := Eval( ::bBof, Self )
                  Eval( ::bskip, Self, 1 )
               ENDIF
               IF ! ( lBEof .AND. AScan( ::aSelected, Eval( ::bRecno, Self ) ) > 0 )
                  ::Select()
                  ::refresh( .F. )
               ENDIF
            ENDIF
         ELSEIF wParam == VK_RIGHT //39    // Right
            ::DoHScroll( SB_LINERIGHT )
         ELSEIF wParam == VK_LEFT //37    // Left
            ::DoHScroll( SB_LINELEFT )
         ELSEIF wParam == VK_HOME //36    // Home
            IF ! ::lCtrlPress .AND. ( ::lAutoEdit .OR. ::aColumns[ ::SetColumn() ]:lEditable )
               ::Edit( wParam )
            ELSE
               ::DoHScroll( SB_LEFT )
            ENDIF
         ELSEIF wParam == VK_END //35    // End
            IF ! ::lCtrlPress .AND. ( ::lAutoEdit .OR. ::aColumns[ ::SetColumn() ]:lEditable )
               ::Edit( wParam )
            ELSE
               ::DoHScroll( SB_RIGHT )
            ENDIF
         ELSEIF wParam == VK_NEXT    // 34 PageDown
            nRecStart := Eval( ::brecno, Self )
            IF ::lCtrlPress
               IF( ::nRecords > ::rowCount )
                  ::BOTTOM()
               ELSE
                  ::PageDown()
               ENDIF
            ELSE
               ::PageDown()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != NIL
               nRecStop := Eval( ::brecno, Self )
               Eval( ::bskip, Self, 1 )
               lBEof := Eval( ::beof, Self )
               Eval( ::bskip, Self, - 1 )
               IF ! ( lBEof .AND. AScan( ::aSelected, Eval( ::bRecno, Self ) ) > 0 )
                  ::Select()
               ENDIF
               DO WHILE Eval( ::bRecno, Self ) != nRecStart
                  ::Select()
                  Eval( ::bskip, Self, - 1 )
               ENDDO
               ::Select()
               Eval( ::bgoto, Self, nRecStop )
               Eval( ::bskip, Self, 1 )
               IF Eval( ::beof, Self )
                  Eval( ::bskip, Self, - 1 )
                  ::Select()
               ELSE
                  Eval( ::bskip, Self, - 1 )
               ENDIF
               ::Refresh()
            ENDIF
         ELSEIF wParam == VK_PRIOR   // 33  PageUp
            nRecStop := Eval( ::brecno, Self )
            IF ::lCtrlPress
               ::TOP()
            ELSE
               ::PageUp()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != NIL
               nRecStart := Eval( ::bRecno, Self )
               DO WHILE Eval( ::bRecno, Self ) != nRecStop
                  ::Select()
                  Eval( ::bskip, Self, 1 )
               ENDDO
               Eval( ::bgoto, Self, nRecStart )
               ::Refresh()
            ENDIF
         ELSEIF wParam == VK_RETURN    // Enter
            ::Edit( VK_RETURN )
         ELSEIF wParam == VK_ESCAPE .AND. ::lESC
            IF hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
               hwg_Sendmessage( hwg_Getparent( ::handle ), WM_SYSCOMMAND, SC_CLOSE, 0 )
            ELSE
               hwg_Sendmessage( hwg_Getparent( ::handle ), WM_CLOSE, 0, 0 )
            ENDIF
         ELSEIF wParam == VK_CONTROL  //17
            ::lCtrlPress := .T.
         ELSEIF wParam == VK_SHIFT   //16
            ::lShiftPress := .T.
         ENDIF
         RETURN 1
      ELSEIF msg == WM_LBUTTONDBLCLK
         ::ButtonDbl( lParam )
      ELSEIF msg == WM_LBUTTONDOWN
         ::ButtonDown( lParam )
      ELSEIF msg == WM_LBUTTONUP
         ::ButtonUp( lParam )
      ELSEIF msg == WM_RBUTTONDOWN
         ::ButtonRDown( lParam )
      ELSEIF msg == WM_MOUSEMOVE //.AND. ! ::oParent:lSuspendMsgsHandling
         IF ::nWheelPress > 0
            ::MouseWheel( hwg_Loword( wParam ), ::nWheelPress - hwg_PtrToUlong( lParam ) )
         ELSE
            ::MouseMove( wParam, lParam )
            IF ::lHeadClick
               AEval( ::aColumns, { | c | c:lHeadClick := .F. } )
               hwg_Invalidaterect( ::handle, 0, ::x1, ::y1 - ::nHeadHeight * ::nHeadRows, ::x2, ::y1 )
               ::lHeadClick := .F.
            ENDIF
            IF ( ! ::allMouseOver ) .AND. ::hTheme != NIL
               ::allMouseOver := .T.
               hwg_Trackmousevent( ::handle )
            ELSE
               hwg_Trackmousevent( ::handle, TME_HOVER + TME_LEAVE )
            ENDIF
         ENDIF
      ELSEIF msg =  WM_MOUSEHOVER
         ::ShowColToolTips( lParam )
      ELSEIF ( msg = WM_MOUSELEAVE .OR. msg = WM_NCMOUSELEAVE )
         IF ::allMouseOver
            ::MouseMove( wParam, lParam )
            ::allMouseOver := .F.
         ENDIF
      ELSEIF msg == WM_MBUTTONUP
         ::nWheelPress := iif( ::nWheelPress > 0, 0, hwg_PtrToUlong( lParam ) )
         IF ::nWheelPress > 0
            Hwg_SetCursor( hwg_Loadcursor( 32652 ) )
         ELSE
            Hwg_SetCursor( hwg_Loadcursor( IDC_ARROW ) )
         ENDIF
      ELSEIF msg == WM_DESTROY
         IF ValType( ::hTheme ) == "P"
            hwg_closethemedata( ::htheme )
            ::hTheme := NIL
         ENDIF
         ::END()
      ENDIF
   ENDIF

   RETURN - 1

   //----------------------------------------------------//

METHOD Redefine( lType, oWndParent, nId, oFont, bInit, bSize, bPaint, bEnter, bGfocus, bLfocus ) CLASS HBrowseEx

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint )

   ::Type    := lType
   IF oFont == NIL
      ::oFont := ::oParent:oFont
   ENDIF
   ::bEnter  := bEnter
   ::bGetFocus  := bGfocus
   ::bLostFocus := bLfocus

   hwg_RegBoard()
   ::InitBrw()

   RETURN Self

   //----------------------------------------------------//

METHOD FindBrowse( nId ) CLASS HBrowseEx
   LOCAL i := AScan( ::aItemsList, { | o | o:id == nId }, 1, ::iItems )

   RETURN iif( i > 0, ::aItemsList[ i ], NIL )

   //----------------------------------------------------//

METHOD AddColumn( oColumn ) CLASS HBrowseEx

   LOCAL n, arr

   IF Valtype( oColumn ) == "A"
      arr := oColumn
      n := Len(arr)
      oColumn := HColumnEx():New( Iif(n>0,arr[1],Nil), Iif(n>1,arr[2],Nil), ;
         Iif(n>2,arr[3],Nil), Iif(n>3,arr[4],Nil), Iif(n>4,arr[5],Nil), Iif(n>5,arr[6],Nil) )
   ENDIF

   AAdd( ::aColumns, oColumn )
   ::lChanged := .T.
   InitColumn( Self, oColumn, Len( ::aColumns ) )

   RETURN oColumn

   //----------------------------------------------------//

METHOD InsColumn( oColumn, nPos ) CLASS HBrowseEx

   LOCAL n, arr

   IF Valtype( oColumn ) == "A"
      arr := oColumn
      n := Len(arr)
      oColumn := HColumnEx():New( Iif(n>0,arr[1],Nil), Iif(n>1,arr[2],Nil), ;
         Iif(n>2,arr[3],Nil), Iif(n>3,arr[4],Nil), Iif(n>4,arr[5],Nil), Iif(n>5,arr[6],Nil) )
   ENDIF

   AAdd( ::aColumns, NIL )
   AIns( ::aColumns, nPos )
   ::aColumns[ nPos ] := oColumn
   ::lChanged := .T.
   InitColumn( Self, oColumn, nPos )

   RETURN oColumn

STATIC FUNCTION InitColumn( oBrw, oColumn, n )
   LOCAL xres, ctype
   LOCAL cname := "Column" + LTrim( Str( Len( oBrw:aColumns ) ) )

   IF oColumn:Type == NIL
      oColumn:Type := ValType( Eval( oColumn:block,, oBrw, n ) )
   ENDIF
   oColumn:width := 0
   IF oColumn:dec == NIL
      IF oColumn:Type == "N" .AND. At( '.', Str( Eval( oColumn:block,, oBrw, n ) ) ) != 0
         oColumn:dec := Len( SubStr( Str( Eval( oColumn:block,, oBrw, n ) ), ;
            At( '.', Str( Eval( oColumn:block,, oBrw, n ) ) ) + 1 ) )
      ELSE
         oColumn:dec := 0
      ENDIF
   ENDIF
   IF oColumn:length == NIL
      IF oColumn:picture != NIL .AND. ! Empty( oBrw:aArray )
         oColumn:length := Len( Transform( Eval( oColumn:block,, oBrw, n ), oColumn:picture ) )
      ELSE
         oColumn:length := 10
         IF !Empty( oBrw:aArray )
            xres     := Eval( oColumn:block, , oBrw, n )
            ctype    := ValType( xres )
         ELSE
            xRes     := Space( 10 )
            ctype    := "C"
         ENDIF
      ENDIF
      // oColumn:length := Max( oColumn:length, Len( oColumn:heading ) )
      oColumn:length := LenVal( xres, ctype, oColumn:picture )
   ENDIF
   oColumn:nJusLin := iif( oColumn:nJusLin == NIL, iif( oColumn:Type == "N", DT_RIGHT , DT_LEFT ), oColumn:nJusLin ) + DT_VCENTER + DT_SINGLELINE
   oColumn:lEditable := iif( oColumn:lEditable != NIL, oColumn:lEditable, .F. )
   oColumn:oParent := oBrw
   oColumn:Column := n
   __objAddData( oBrw, cName )
   oBrw:&( cName ) := oColumn

   RETURN NIL

   //----------------------------------------------------//

METHOD DelColumn( nPos ) CLASS HBrowseEx

   ADel( ::aColumns, nPos )
   ASize( ::aColumns, Len( ::aColumns ) - 1 )
   ::lChanged := .T.

   RETURN NIL

   //----------------------------------------------------//

METHOD END() CLASS HBrowseEx

   ::Super:END()
   IF ::brush != NIL
      ::brush:Release()
      ::brush := NIL
   ENDIF
   IF ::brushSel != NIL
      ::brushSel:Release()
      ::brushSel := NIL
   ENDIF
   IF oPen64 != NIL
      oPen64:Release()
   ENDIF
   IF ::oTimer != NIL
      ::oTimer:End()
   ENDIF

   RETURN NIL

METHOD ShowMark( lShowMark ) CLASS HBrowseEx

   IF lShowMark != NIL
      ::nShowMark := iif( lShowMark, 12, 0 )
      ::lShowMark := lShowMark
      ::Refresh()
   ENDIF

   RETURN ::lDeleteMark

METHOD DeleteMark( lDeleteMark ) CLASS HBrowseEx

   IF lDeleteMark != NIL
      IF ::Type == BRW_DATABASE
         ::nDeleteMark := iif( lDeleteMark, 7, 0 )
         ::lDeleteMark := lDeleteMark
         ::Refresh()
      ENDIF
   ENDIF

   RETURN ::lDeleteMark

METHOD ShowColToolTips( lParam ) CLASS HBrowseEx
   LOCAL pt, cTip := ""

   IF Ascan( ::aColumns, { | c | c:Hint != .F. .OR. c:Tooltip != Nil } ) = 0
      RETURN NIL
   ENDIF
   pt := ::ButtonDown( lParam, .T. )
   IF pt = NIL .OR. pt[ 1 ] = - 1
      RETURN NIL
   ELSEIF pt[ 1 ] != 0 .AND. pt[ 2 ] != 0 .AND. ::aColumns[ pt[ 2 ] ]:Hint
      cTip := ::aColumns[ pt[ 2 ] ]:aHints[ pt[ 1 ] ]
   ELSEIF pt[ 1 ] = 0 .AND. pt[ 2 ] != 0 .AND. ::aColumns[ pt[ 2 ] ]:ToolTip != Nil
      cTip := ::aColumns[ pt[ 2 ] ]:ToolTip
   ENDIF
   IF ! Empty( cTip ) .OR. ! Empty( xToolTip )
      hwg_Settooltiptitle( hwg_GetparentForm( Self ):handle, ::handle, cTip )
      xToolTip := iif( ! Empty( cTip ), cTip, iif( ! Empty( xToolTip ), NIL, xToolTip ) )
   ENDIF

   RETURN NIL

METHOD SetRefresh( nSeconds ) CLASS HBrowseEx

   IF nSeconds != NIL //.AND. ::Type == BRW_DATABASE
      IF ::oTimer != NIL
         ::oTimer:Interval := nSeconds * 1000
      ELSEIF nSeconds > 0
         SET TIMER ::oTimer OF hwg_GetParentForm( Self ) VALUE ( nSeconds * 1000 )  ACTION { || iif( hwg_Iswindowvisible( ::Handle ), ;
            ( ::internal[ 1 ] := 12, hwg_Invalidaterect( ::handle, 0,;
            ::x1 , ;
            ::y1 , ;
            ::x1 + ::xAdjRight, ;
            ::y1 + ::rowCount * ( ::height + 1 ) + 1 ) ), NIL ) }
      ENDIF
      ::nSetRefresh := nSeconds
   ENDIF

   RETURN ::nSetRefresh

   //----------------------------------------------------//

METHOD InitBrw( nType, lInit )  CLASS HBrowseEx
   LOCAL cAlias := Alias()

   DEFAULT lInit TO .F.
   IF Empty( lInit )
      ::x1 := ::y1 := ::x2 := ::y2  := ::xAdjRight := 0
      ::height := ::width := 0
      ::nyHeight := iif( hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE , 1 , 0 )
      ::lDeleteMark := .F.
      ::lShowMark := .T.
      ::nPaintCol := 0
      IF nType != NIL
         ::Type := nType
      ELSE
         ::aColumns := { }
         ::rowPos  := ::nCurrent  := ::colpos := 1
         ::rowCurrCount := 0
         ::nLeftCol := 1
         ::freeze  := 0
         ::internal  := { 15, 1 , 0, 0 }
         ::aArray     := NIL
         ::aMargin := { 1, 1, 0, 1 }
         IF Empty( ColSizeCursor )
            ColSizeCursor := hwg_Loadcursor( IDC_SIZEWE )
            arrowCursor := hwg_Loadcursor( IDC_ARROW )
            downCursor := hwg_Loadcursor( IDC_HAND )
         ENDIF
         oPen64 :=  HPen():Add( PS_SOLID, 1, hwg_ColorRgb2N( 156, 156, 156 ) )
      ENDIF
   ENDIF

   IF ! Empty( ::RelationalExpr )
      ::lFilter := .T.
   ENDIF

   IF ::Type == BRW_DATABASE
      ::Filter( ::lFilter )
   ELSEIF ::Type == BRW_ARRAY
      ::bSkip      := { | o, n | ARSKIP( o, n ) }
      ::bGoTop  := { | o | o:nCurrent := 1 }
      ::bGoBot  := { | o | o:nCurrent := o:nRecords }
      ::bEof    := { | o | o:nCurrent > o:nRecords }
      ::bBof    := { | o | o:nCurrent == 0 }
      ::bRcou   := { | o | Len( o:aArray ) }
      ::bRecnoLog := ::bRecno  := { | o | o:nCurrent }
      ::bGoTo   := { | o, n | o:nCurrent := n }
      ::bScrollPos := { | o, n, lEof, nPos | hwg_VScrollPosEx( o, n, lEof, nPos ) }
      IF ::lFilter
         ::nLastRecordFilter  := 0
         ::nFirstRecordFilter := 0
         ::rowCurrCount := 0
         ::bSkip     := { | o, n | aFltSkip( o, n, .F. )  }
         ::bGoTop    := { | o | aFltGoTop( o  ) }
         ::bGoBot    := { | o | aFltGoBottom( o )  }
      ENDIF

   ENDIF
   IF lInit
      IF ::Type == BRW_DATABASE
         ::LinkMaster( ::cLinkMaster )
      ENDIF
   ENDIF
   IF !Empty( cAlias )
      SELECT ( cAlias )
   ENDIF

   RETURN NIL

METHOD LinkMaster( cLinkMaster ) CLASS HBrowseEx

   IF cLinkMaster  != Nil
      ::lFilter := iif( ! Empty( cLinkMaster ), .T. , ::lFilter )
      IF ! Empty( ::cLinkMaster ) .AND. Empty( cLinkMaster )
         ::bWhile    := { || .T. }
      ENDIF
      ::cLinkMaster := Trim( cLinkMaster )
      IF Empty( ::Alias )
         RETURN Nil
      ENDIF
      ::Filter( ::lFilter )
      IF ! Empty( ::cLinkMaster )
         IF ! Empty( ::ChildOrder )
            ( ::Alias ) -> ( dbSetOrder( ::ChildOrder ) )
         ENDIF
         IF ! Empty( ::RelationalExpr )
            ::bFirst := { |  | ( ::Alias ) -> ( dbSeek( ( ::cLinkMaster ) -> ( &( ::RelationalExpr ) ), .F. ) ) }
            ::bLast  := { |  | ( ::Alias ) -> ( dbSeek( ( ::cLinkMaster ) -> ( &( ::RelationalExpr ) ) , .F. , .T. ) ) }
            ::bWhile := { |  | ( ::Alias ) -> ( ( ::cLinkMaster ) -> &( ::RelationalExpr ) )  = ( ::cLinkMaster ) -> ( &( ::RelationalExpr ) ) }
            Eval( ::bFirst, Self )
            ::rowCurrCount := 1
         ENDIF
      ELSE
         ( ::Alias ) -> ( OrdScope( 0 ) )
         ( ::Alias ) -> ( OrdScope( 1 ) )
         ::bFirst := { |  | ( ::Alias ) -> ( DBGoTop() ) }
         ::bLast  := { |  | ( ::Alias ) -> ( dbGoBottom() ) }
         ::rowCurrCount := 0
      ENDIF
   ENDIF

   RETURN ::cLinkMaster

METHOD FILTER( lFilter ) CLASS HBrowseEx

   IF lFilter != Nil .AND. ::Type == BRW_DATABASE
      IF  Empty( ::Alias )
         ::Alias   := Alias()
      ENDIF
      IF Empty( ::ALias )
         RETURN ::lFilter
      ENDIF
      IF lFilter
         ::nLastRecordFilter  := 0
         ::nFirstRecordFilter := 0
         ::rowCurrCount := 0
         IF ::lDescend
            ::bSkip     := { | o, n | ( ::Alias ) -> ( FltSkip( o, n, .T. ) ) }
            ::bGoTop    := { | o | ( ::Alias ) -> ( FltGoBottom( o ) ) }
            ::bGoBot    := { | o | ( ::Alias ) -> ( FltGoTop( o ) ) }
            ::bEof      := { | o | ( ::Alias ) -> ( FltBOF( o ) ) }
            ::bBof      := { | o | ( ::Alias ) -> ( FltEOF( o ) ) }
         ELSE
            ::bSkip     := { | o, n | ( ::Alias ) -> ( FltSkip( o, n, .F. ) ) }
            ::bGoTop    := { | o | ( ::Alias ) -> ( FltGoTop( o ) ) }
            ::bGoBot    := { | o | ( ::Alias ) -> ( FltGoBottom( o ) ) }
            ::bEof      := { | o | ( ::Alias ) -> ( FltEOF( o ) ) }
            ::bBof      := { | o | ( ::Alias ) -> ( FltBOF( o ) ) }
         ENDIF
         ::bRcou     := { || ( ::Alias ) -> ( RecCount() ) }
         ::bRecnoLog := ::bRecno := { | o | ( ::Alias ) -> ( FltRecNo( o ) ) }
         ::bGoTo     := { | o, n | ( ::Alias ) -> ( FltGoTo( o, n ) ) }
      ELSE
         ::bSkip     :=  { | o, n | HB_SYMBOL_UNUSED( o ), ( ::Alias ) -> ( dbSkip( n ) ) }
         ::bGoTop    :=  { || ( ::Alias ) -> ( DBGoTop() ) }
         ::bGoBot    :=  { || ( ::Alias ) -> ( dbGoBottom() ) }
         ::bEof      :=  { || ( ::Alias ) -> ( Eof() ) }
         ::bBof      :=  { || ( ::Alias ) -> ( Bof() ) }
         ::bRcou     :=  { || ( ::Alias ) -> ( RecCount() ) }
         ::bRecnoLog := ::bRecno  := { || ( ::Alias ) -> ( RecNo() ) }
         ::bGoTo     := { | a, n | HB_SYMBOL_UNUSED( a ), ( ::Alias ) -> ( dbGoto( n ) ) }
         ::bWhile    := { || .T. }
         ::bFor      := { || .T. }
      ENDIF
      ::lFilter := lFilter
   ELSEIF lFilter != Nil .AND. ::Type == BRW_ARRAY
      IF lFilter
         ::nLastRecordFilter  := 0
         ::nFirstRecordFilter := 0
         ::rowCurrCount := 0
         ::bSkip     := { | o, n | aFltSkip( o, n, .F. )  }
         ::bGoTop    := { | o | aFltGoTop( o  ) }
         ::bGoBot    := { | o | aFltGoBottom( o )  }
      ELSE
         ::bSkip      := { | o, n | ARSKIP( o, n ) }
         ::bGoTop  := { | o | o:nCurrent := 1 }
         ::bGoBot  := { | o | o:nCurrent := o:nRecords }
         ::bWhile    := { || .T. }
         ::bFor      := { || .T. }
      ENDIF
      ::lFilter := lFilter
   ENDIF

   RETURN ::lFilter

   //----------------------------------------------------//

METHOD Rebuild() CLASS HBrowseEx
   LOCAL i, j, oColumn, xSize, nColLen, nHdrLen, nCount, fontsize

   IF ::brush != NIL
      ::brush:Release()
   ENDIF
   IF ::brushSel != NIL
      ::brushSel:Release()
   ENDIF
   IF ::bcolor != NIL
      ::brush     := HBrush():Add( ::bcolor )
   ENDIF
   IF ::bcolorSel != NIL
      ::brushSel  := HBrush():Add( ::bcolorSel )
   ENDIF
   ::nLeftCol  := ::freeze + 1
   ::lEditable := .F.
   ::minHeight := 0

   FOR i := 1 TO Len( ::aColumns )
      oColumn := ::aColumns[ i ]
      IF oColumn:lEditable
         ::lEditable := .T.
      ENDIF
      FontSize := iif( oColumn:type $ "DN", hwg_TxtRect( "9", Self, oColumn:oFont )[1], hwg_TxtRect( "N", Self, oColumn:oFont )[1] )
      IF oColumn:aBitmaps != NIL
         IF oColumn:heading != NIL
            xSize := Round( ( Len( oColumn:heading ) + 0.6 ) * FontSize, 0 )
         ELSE
            xSize := 0
         ENDIF
         IF ::forceHeight > 0
            ::minHeight := ::forceHeight
         ELSE
            FOR j := 1 TO Len( oColumn:aBitmaps )
               IF hb_IsObject( oColumn:aBitmaps[j,2] )
                  xSize := Max( xSize, oColumn:aBitmaps[ j, 2 ]:nWidth + 2 )
                  ::minHeight := Max( ::minHeight, ::aMargin[ 1 ] + oColumn:aBitmaps[ j, 2 ]:nHeight + ::aMargin[ 3 ] )
               ENDIF
            NEXT
         ENDIF
      ELSE
         nColLen := oColumn:length
         IF oColumn:heading != NIL
            HdrToken( oColumn:heading, @nHdrLen, @nCount )
            IF ! oColumn:lSpandHead
               nColLen := Max( nColLen, nHdrLen )
            ENDIF
            ::nHeadRows := Max( ::nHeadRows, nCount )
         ENDIF
         IF oColumn:footing != NIL .AND. !oColumn:lHide
            HdrToken( oColumn:footing, @nHdrLen, @nCount )
            IF ! oColumn:lSpandFoot
               nColLen := Max( nColLen, nHdrLen )
            ENDIF
            ::nFootRows := Max( ::nFootRows, nCount )
         ENDIF
         xSize := Round( ( nColLen + 0.6 ) * ( (  FontSize ) ), 0 )
      ENDIF
      xSize := ::aMargin[ 4 ] + xSize + ::aMargin[ 2 ]
      IF Empty( oColumn:width )
         oColumn:width := xSize
      ENDIF
   NEXT
   IF HWG_BITAND( ::style, WS_HSCROLL ) != 0
      hwg_Setscrollinfo( ::Handle, SB_HORZ, 1, 0,  1 , Len( ::aColumns ) )
   ENDIF

   ::lChanged := .F.

   RETURN NIL

METHOD AutoFit( ) CLASS HBrowseEx
   LOCAL nlen , i, aCoors, nXincRelative

   IF ::AutoColumnFit = 2
      RETURN .F.
   ENDIF
   ::lAdjRight := .F.
   //::oParent:lSuspendMsgsHandling := .T.
   hwg_Redrawwindow( ::handle, RDW_VALIDATE + RDW_UPDATENOW )
   //::oParent:lSuspendMsgsHandling := .F.
   aCoors := hwg_Getwindowrect( ::handle )
   IF ::nAutoFit = NIL
      ::nAutoFit :=  iif( Max( 0, ::x2 - ::xAdjRight - 2 ) = 0, 0,  ::x2  / ::xAdjRight )
      nXincRelative := iif( ( aCoors[ 3 ] - aCoors[ 1 ] )  - ( ::nWidth  ) > 0, ::nAutoFit, 1/::nAutoFit )
   ELSE
      nXincRelative :=    ( aCoors[ 3 ] - aCoors[ 1 ] )  / ( ::nWidth  ) - 0.01
   ENDIF
   IF ::nAutoFit = 0 .OR. nXincRelative < 1
      IF nXincRelative < 0.1 .OR. ::nAutoFit = 0
         ::nAutoFit := iif( nXincRelative < 1, NIL, ::nAutoFit )
         RETURN .F.
      ENDIF
      ::nAutoFit := iif( nXincRelative < 1, NIL, ::nAutoFit )
   ENDIF
   nlen := Len( ::aColumns )
   FOR i = 1 TO nLen
      IF ::aColumns[ i ]:Resizable
         ::aColumns[ i ]:Width := ::aColumns[ i ]:Width  * nXincRelative
      ENDIF
   NEXT

   RETURN .T.

   //----------------------------------------------------//

METHOD Paint( lLostFocus )  CLASS HBrowseEx
   LOCAL aCoors, aMetr, cursor_row, tmp, nRows, nRowsFill
   LOCAL pps, hDC
   LOCAL oldfont, aMetrHead,  nRecFilter

   IF ! ::active .OR. Empty( ::aColumns ) .OR. ::lHeadClick
      pps := hwg_Definepaintstru()
      hDC := hwg_Beginpaint( ::handle, pps )
      IF ::lHeadClick .OR. ::isMouseOver
         //::oParent:lSuspendMsgsHandling := .T.
         ::HeaderOut( hDC )
         //::oParent:lSuspendMsgsHandling := .F.
      ENDIF
      hwg_Endpaint( ::handle, pps )
      ::isMouseOver := .F.
      RETURN NIL
   ENDIF
   IF ( ::m_bFirstTime ) .AND. ::Themed
      ::m_bFirstTime := .F.
      IF ( hwg_Isthemedload() )
         IF ValType( ::hTheme ) == "P"
            hwg_closethemedata( ::htheme )
         ENDIF
         IF ::WindowsManifest
            ::hTheme := hwg_openthemedata( ::handle, "HEADER" )
         ENDIF
         ::hTheme := iif( Empty( ::hTheme  ), NIL, ::hTheme )
      ENDIF
   ENDIF

   // Validate some variables

   IF ::tcolor == NIL ; ::tcolor := 0 ; ENDIF
   IF ::bcolor == NIL ; ::bcolor := hwg_ColorC2N( "FFFFFF" ) ; ENDIF

   IF ::httcolor == NIL ; ::httcolor := hwg_Getsyscolor( COLOR_HIGHLIGHTTEXT ) ; ENDIF
   IF ::htbcolor == NIL ; ::htbcolor := hwg_Getsyscolor( COLOR_HIGHLIGHT )  ; ENDIF

   IF ::tcolorSel == NIL ; ::tcolorSel := hwg_ColorC2N( "FFFFFF" ) ; ENDIF
   IF ::bcolorSel == NIL ; ::bcolorSel := hwg_ColorC2N( "808080" ) ; ENDIF

   // Open Paint procedure

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( ::handle, pps )

   IF ::ofont != NIL
      hwg_Selectobject( hDC, ::ofont:handle )
   ENDIF
   IF ::brush == NIL .OR. ::lChanged
      ::Rebuild()
   ENDIF

   // Get client area coordinate

   aCoors := hwg_Getclientrect( ::handle )
   aMetr := hwg_Gettextmetric( hDC )
   ::width := Round( ( aMetr[ 3 ] + aMetr[ 2 ] ) / 2 - 1, 0 )
   // If forceHeight is set, we should use that value
   IF ( ::forceHeight > 0 )
      ::height := ::forceHeight + 1
   ELSE
      ::height := ::aMargin[ 1 ] + Max( aMetr[ 1 ], ::minHeight ) + 1 + ::aMargin[ 3 ]
   ENDIF

   aMetrHead := AClone( aMetr )
   IF ::oHeadFont != NIL
      oldfont := hwg_Selectobject( hDC, ::oHeadFont:handle )
      aMetrHead := hwg_Gettextmetric( hDC )
      hwg_Selectobject( hDC, oldfont )
   ENDIF
   // USER DEFINE Height  IF != 0
   IF Empty( ::nHeadHeight )
      ::nHeadHeight := ::aMargin[ 1 ] + aMetrHead[ 1 ] + 1 + ::aMargin[ 3 ] + 3
   ENDIF
   IF Empty( ::nFootHeight )
      ::nFootHeight := ::aMargin[ 1 ] + aMetr[ 1 ] + 1 + ::aMargin[ 3 ]
   ENDIF
   ::x1 := aCoors[ 1 ] +  ::nShowMark + ::nDeleteMark
   ::y1 := aCoors[ 2 ] + iif( ::lDispHead, ::nHeadHeight * ::nHeadRows, 0 )
   ::x2 := aCoors[ 3 ]
   ::y2 := aCoors[ 4 ]
   IF ::lRepaintBackground
      hwg_Fillrect( hDC, ::x1 - ::nDeleteMark, ::y1, ::xAdjRight, ::y2 - ( ::nFootHeight * ::nFootRows ), ::brush:handle )
      ::lRepaintBackground := .F.
   ENDIF
   nRowsFill := ::rowCurrCount
   ::nRecords := Eval( ::bRcou, Self )
   IF ::nCurrent > ::nRecords .AND. ::nRecords > 0
      ::nCurrent := ::nRecords
   ENDIF

   // Calculate number of columns visible

   ::nColumns := FLDCOUNT( Self, ::x1 + 2, ::x2 - 2, ::nLeftCol )

   // Calculate number of rows the canvas can host
   ::rowCount := Int( ( ::y2 - ::y1 - ( ::nFootRows * ::nFootHeight ) ) / ( ::height + 1 ) )

   // nRows: if number of data rows are less than video rows available....
   nRows := Min( ::nRecords, ::rowCount )

   IF ::internal[ 1 ] == 0
      IF ::rowPos != ::internal[ 2 ] .AND. ! ::lAppMode
         Eval( ::bSkip, Self, ::internal[ 2 ] - ::rowPos )
      ENDIF
      //::oParent:lSuspendMsgsHandling := .T.
      IF ::aSelected != NIL .AND. AScan( ::aSelected, { | x | x = Eval( ::bRecno, Self ) } ) > 0
         ::LineOut( ::internal[ 2 ], 0, hDC, ! ::lResizing )
      ELSE
         ::LineOut( ::internal[ 2 ], 0, hDC, .F. )
      ENDIF
      IF ::rowPos != ::internal[ 2 ] .AND. ! ::lAppMode
         Eval( ::bSkip, Self, ::rowPos - ::internal[ 2 ] )
      ENDIF
   ELSEIF ::internal[ 1 ] == 2
      ::xAdjRight := ::x2
      ::HeaderOut( hDC )
   ELSE
      IF ! ::lAppMode
         IF Eval( ::bEof, Self ) .OR. Eval( ::bBof, Self ) .OR. ::rowPos > ::nRecords
            Eval( ::bGoTop, Self )
            ::rowPos := 1
         ENDIF
      ENDIF
      // Se riga_cursore_video > numero_record
      // metto il cursore sull'ultima riga
      IF ::rowPos > nRows .AND. nRows > 0
         ::rowPos := nRows
      ENDIF
      // Take record number
      tmp := Eval( ::bRecno, Self )

      // if riga_cursore_video > 1
      //   we skip ::rowPos-1 number of records back,
      //   actually positioning video cursor on first line
      IF ::rowPos > 1
         // Eval( ::bSkip, Self, - ( ::rowPos - 1 ) )
      ENDIF
      // new
      IF ::lFilter .AND. ::rowPos > 1 .AND. tmp = ::nFirstRecordFilter
         Eval( ::bSkip, Self,  ( ::rowPos - 1 ) )
         tmp := Eval( ::bRecno, Self )
      ENDIF

      // Browse printing is split in two parts
      // first part starts from video row 1 and goes to end of data (EOF)
      // or end of video lines

      // second part starts from where part 1 stopped -
      // new 01/09/2009 - nando
      //nRecFilter := FltRecNoRelative( Self )
      nRecFilter := 0
      IF ::Type == BRW_DATABASE
         nRecFilter := ( ::Alias ) -> ( RecNo() )
         IF ::lFilter .AND. Empty( ::RelationalExpr )
            nRecFilter := ASCAN( ::aRecnoFilter, ( ::Alias ) -> ( RecNo() ) )
         ELSEIF ! Empty( ( ::Alias ) -> ( dbFilter() ) ) .AND. ( ::Alias ) -> ( RecNo() ) > ::nRecords
            nRecFilter := ::nRecords
         ENDIF
      ENDIF
      IF ::rowCurrCount = 0  .AND. ::nRecords > 0 // INIT
         Eval( ::bSkip, Self, 1 )
         ::rowCurrCount := iif( Eval( ::bEof, Self ), ::rowCount , iif( ::nRecords < ::rowCount, ::nRecords,  1 ) )
         nRecFilter := - 1
      ELSEIF ::nRecords < ::rowCount .AND. Empty( ::cLinkMaster )
         //ELSEIF ::nRecords < ::rowCount
         ::rowCurrCount := ::nRecords
      ELSEIF ::rowCurrCount >= ::RowPos  .AND. nRecFilter <= ::nRecords
         ::rowCurrCount -= ( ::rowCurrCount - ::RowPos + 1 )
      ELSEIF ::rowCurrCount > ::rowCount - 1
         ::rowCurrCount := ::rowCount - 1
      ENDIF
      IF ::rowCurrCount > 0
         Eval( ::bSkip, Self, - ::rowCurrCount )
         IF Eval( ::bBof, Self )
            Eval( ::bGoTop, Self )
         ENDIF
         tmp := iif( ::lFilter .AND. nRecFilter = - 1, Eval( ::bRecno, Self ), tmp )
      ENDIF

      cursor_row := 1
      //::oParent:lSuspendMsgsHandling := .T.
      ::internal[ 3 ] := Eval( ::bRecno, Self )
      AEval( ::aColumns, { | c | c:aHints := {} } )
      DO WHILE .T.
         // if we are on the current record, set current video line
         IF Eval( ::bRecno, Self ) == tmp
            ::rowPos := cursor_row
         ENDIF

         // exit loop when at last row or eof()
         IF cursor_row > nRows .OR. ( Eval( ::bEof, Self ) .AND. ! ::lAppMode )
            EXIT
         ENDIF

         // decide how to print the video row
         IF ::aSelected != NIL .AND. AScan( ::aSelected, { | x | x = Eval( ::bRecno, Self ) } ) > 0
            ::LineOut( cursor_row, 0, hDC, ! ::lResizing )
         ELSE
            ::LineOut( cursor_row, 0, hDC, .F. )
         ENDIF
         cursor_row ++
         Eval( ::bSkip, Self, 1 )
      ENDDO
      ::internal[ 4 ] := Eval( ::bRecno, Self )
      //::rowCurrCount := cursor_row - 1
      ::rowCurrCount := iif( cursor_row - 1 < ::rowCurrCount, ::rowCurrCount, cursor_row - 1 )

      // set current_video_line depending on the situation
      IF ::rowPos >= cursor_row
         ::rowPos := iif( cursor_row > 1, cursor_row - 1, 1 )
      ENDIF

      // print the rest of the browse

      DO WHILE cursor_row <= ::rowCount .AND. ( ::nRecords > nRows .AND. ! Eval( ::bEof, Self ) )
         ::LineOut( cursor_row, 0, hDC, .F. , .T. )
         cursor_row ++
      ENDDO
      IF ::lDispSep .AND. ! hwg_Checkbit( ::internal[ 1 ], 1 ) .AND. nRowsFill <= ::rowCurrCount
         ::SeparatorOut( hDC, ::rowCurrCount )
      ENDIF
      nRowsFill := cursor_row - 1
      // fill the remaining canvas area with background color if needed
      nRows := cursor_row - 1
      IF nRows < ::rowCount .OR. ( nRows * ( ::height - 1 ) + ::nHeadHeight + ::nFootHeight ) < ::nHeight
         //  hwg_Fillrect( hDC, ::x1, ::y1 + ( ::height + 1 ) * nRows + 1, ::x2, ::y2, ::brush:handle )
      ENDIF
      Eval( ::bGoTo, Self, tmp )
   ENDIF
   IF ::lAppMode
      ::LineOut( nRows + 1, 0, hDC, .F. , .T. )
   ENDIF

   // Highlights the selected ROW
   // we can have a modality with CELL selection only or ROW selection
   IF !::lHeadClick  .AND. ( ! ::lEditable .OR. ( ::lEditable .AND. ::Highlight ) ) // .AND.! ::lResizing
      ::LineOut( ::rowPos, 0, hDC, ! ::lResizing )
   ENDIF
   // Highligths the selected cell
   // FP: Reenabled the lEditable check as it's not possible
   // to move the "cursor cell" if lEditable is FALSE
   // Actually: if lEditable is FALSE we can only have LINE selection
   IF lLostFocus == NIL .AND. ! ::lHeadClick  .AND. ( ::lEditable .OR. ::Highlight )  //.AND. !::lResizing
      ::LineOut( ::rowPos, ::colpos, hDC, ! ::lResizing )
   ENDIF

   // if bit-1 refresh header and footer
   //::oParent:lSuspendMsgsHandling := .F.

   IF hwg_Checkbit( ::internal[ 1 ], 1 ) .OR. ::lAppMode
      ::SeparatorOut( hDC , nRowsFill  )
      IF ::nHeadRows > 0
         ::HeaderOut( hDC )
      ENDIF
      IF ::nFootRows > 0
         ::FooterOut( hDC )
      ENDIF
   ENDIF
   IF ::lAppMode  .AND. ::nRecords != 0 .AND. ::rowPos = ::rowCount
      ::LineOut( ::rowPos, 0 , hDC, .T. , .T. )
   ENDIF

   // End paint block
   hwg_Endpaint( ::handle, pps )

   ::internal[ 1 ] := 15
   ::internal[ 2 ] := ::rowPos

   // calculate current bRecno()
   tmp := Eval( ::bRecno, Self )
   IF ::recCurr != tmp
      ::recCurr := tmp
      IF ::bPosChanged != NIL
         Eval( ::bPosChanged, Self, ::rowpos )
      ENDIF
   ENDIF

   IF ::lAppMode
      ::Edit()
   ENDIF

   ::lAppMode := .F.

   // fixed postion vertical scroll bar in refresh out browse
   IF hwg_Getfocus() != ::handle .OR. nRecFilter = - 1
      Eval( ::bSkip, Self, 1 )
      Eval( ::bSkip, Self, - 1 )
      IF ::bScrollPos != NIL // array
         Eval( ::bScrollPos, Self, 1, .F. )
      ELSE
         hwg_VScrollPosEx( Self, 0, .F. )
      ENDIF
   ENDIF

   IF ::lInFocus .AND. ( ( tmp := hwg_Getfocus() ) == ::oParent:handle ;
         .OR. ::oParent:FindControl(,tmp) != Nil )
      hwg_Setfocus( ::handle )
   ENDIF

   RETURN NIL

   //----------------------------------------------------//
   // TODO: hb_tokenGet() can create problems.... can't have separator as first char

METHOD HeaderOut( hDC ) CLASS HBrowseEx
   LOCAL x, oldc, fif, xSize, lFixed := .F. , xSizeMax
   LOCAL oPen, oldBkColor
   LOCAL oColumn, nLine, cStr, cNWSE, oPenHdr, oPenLight
   LOCAL toldc, oldfont
   LOCAL oBmpSort, nMe, nMd, captionRect := { , , , }, aTxtSize
   LOCAL state, aItemRect

   oldBkColor := hwg_Setbkcolor( hDC, hwg_Getsyscolor( COLOR_3DFACE ) )

   IF ::hTheme = NIL
      hwg_Selectobject( hDC, oPen64:handle )
      hwg_Rectangle( hDC, ;
         ::x1 - ::nShowMark - ::nDeleteMark , ;
         ::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight , ;
         ::x2 , ;
         ::y1   )
   ENDIF
   IF ! ::lDispSep
      oPen := HPen():Add( PS_SOLID, 1, ::bColor )
      hwg_Selectobject( hDC, oPen:handle )
   ELSEIF ::lDispSep
      oPen := HPen():Add( PS_SOLID, 1, ::sepColor )
      hwg_Selectobject( hDC, oPen:handle )
   ENDIF
   IF ::lSep3d
      oPenLight := HPen():Add( PS_SOLID, 1, hwg_Getsyscolor( COLOR_3DHILIGHT ) )
   ENDIF

   x := ::x1
   IF ::oHeadFont <> NIL
      oldfont := hwg_Selectobject( hDC, ::oHeadFont:handle )
   ENDIF
   IF ::headColor <> NIL
      oldc := hwg_Settextcolor( hDC, ::headColor )
   ENDIF
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[ fif ]
      IF oColumn:headColor <> NIL
         toldc := hwg_Settextcolor( hDC, oColumn:headColor )
      ENDIF
      xSize := oColumn:width
      IF ::lAdjRight .AND. fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      ENDIF
      xSizeMax := xSize

      IF ( fif == Len( ::aColumns ) ) .OR. lFixed
         xSizeMax := Max( ::x2 - x, xSize )
         xSize := iif( ::lAdjRight, xSizeMax, xSize )
      ENDIF
      // NANDO
      IF !oColumn:lHide
         IF ::lDispHead .AND. ! ::lAppMode
            IF oColumn:cGrid == NIL
               //-  hwg_Drawbutton( hDC, x - 1, ::y1 - ::nHeadHeight * ::nHeadRows, x + xSize - 1, ::y1 + 1, 1 )
               IF xsize != xsizeMax
                  hwg_Drawbutton( hDC, x + xsize, ::y1 - ::nHeadHeight * ::nHeadRows, x + xsizeMax , ::y1 + 1, 0 )
               ENDIF
            ELSE
               // Draws a grid to the NWSE coordinate...
               //-  hwg_Drawbutton( hDC, x - 1, ::y1 - ::nHeadHeight * ::nHeadRows, x + xSize - 1, ::y1 + 1, 0 )
               IF xSize != xSizeMax
                  //-    hwg_Drawbutton( hDC, x + xsize - 1, ::y1 - ::nHeadHeight * ::nHeadRows, x + xsizeMax - 1, ::y1 + 1, 0 )
               ENDIF
               IF oPenHdr == NIL
                  oPenHdr := HPen():Add( BS_SOLID, 1, 0 )
               ENDIF
               hwg_Selectobject( hDC, oPenHdr:handle )
               cStr := oColumn:cGrid + ';'
               FOR nLine := 1 TO ::nHeadRows
                  cNWSE := hb_tokenGet( @cStr, nLine, ';' )
                  IF At( 'S', cNWSE ) != 0
                     hwg_Drawline( hDC, x - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine ), x + xSize - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine ) )
                  ENDIF
                  IF At( 'N', cNWSE ) != 0
                     hwg_Drawline( hDC, x - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine + 1 ), x + xSize - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine + 1 ) )
                  ENDIF
                  IF At( 'E', cNWSE ) != 0
                     hwg_Drawline( hDC, x + xSize - 2, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine + 1 ) + 1, x + xSize - 2, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine ) )
                  ENDIF
                  IF At( 'W', cNWSE ) != 0
                     hwg_Drawline( hDC, x - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine + 1 ) + 1, x - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine ) )
                  ENDIF
               NEXT
               hwg_Selectobject( hDC, oPen:handle )
            ENDIF
            // Prints the column heading - justified
            aItemRect := { x   , ::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight - 1, ;
               x + xSize  , ::y1 + 1  }
            IF ! oColumn:lHeadClick
               state := iif( ::hTheme != NIL, iif( ::xPosMouseOver > x .AND. ::xPosMouseOver < x + xsize - 3,;
                  PBS_HOT, PBS_NORMAL ), PBS_NORMAL )
               axPosMouseOver  := iif( ::xPosMouseOver > x .AND. ::xPosMouseOver < x + xsize - 3, { x, x + xsize }, axPosMouseOver )
            ELSE
               state := iif( ::hTheme != NIL, PBS_PRESSED, 6 )
               hwg_Inflaterect( @aItemRect, - 1, - 1 )
            ENDIF
            IF ::hTheme != NIL
               hwg_drawthemebackground( ::hTheme, hDC, BP_PUSHBUTTON, state , aItemRect, NIL )
               hwg_Setbkmode( hDC, 1 )
            ELSE
               hwg_Drawbutton( hDC, x   , ;
                  ::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight , ;
                  x + xSize   , ;
                  ::y1  , ;
                  state )
            ENDIF
            nMe := iif( ::ShowSortMark .AND. oColumn:SortMark > 0, iif( oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE  ==  DT_LEFT, 18, 0 ), 0 )
            nMd := iif( ::ShowSortMark .AND. oColumn:SortMark > 0, iif( oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE  !=  DT_LEFT, 17, 0 ), ;
               iif( oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE =  DT_RIGHT, 1, 0 ) )
            cStr := oColumn:heading + ';'
            FOR nLine := 1 TO ::nHeadRows
               aTxtSize := iif( nLine = 1, hwg_TxtRect( cStr, Self ), aTxtSize )
               hwg_Drawtext( hDC, hb_tokenGet( @cStr, nLine, ';' ), ;
                  x + ::aMargin[ 4 ] + 1 + nMe, ;
                  ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine + 1 ) +  ::aMargin[ 1 ] + 1, ;
                  x + xSize - ( 2 + ::aMargin[ 2 ] + nMd ) , ;
                  ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine ) - 1, ;
                  oColumn:nJusHead + iif( oColumn:lSpandHead, DT_NOCLIP, 0 ) + DT_END_ELLIPSIS, @captionRect )
            NEXT // Nando DT_VCENTER+DT_SINGLELINE
            IF ::ShowSortMark .AND. oColumn:SortMark > 0
               oBmpSort  :=  iif( oColumn:SortMark = 1, HBitmap():AddStandard( OBM_UPARROWD ),  HBitmap():AddStandard( OBM_DNARROWD ) )
               captionRect[ 2 ] := ( ::nHeadHeight + 17 ) / 2 - 17
               IF oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE  ==  DT_RIGHT .OR. xSize < aTxtSize[ 1 ] + nMd
                  hwg_Drawtransparentbitmap( hDC, oBmpSort:Handle, captionRect[ 1 ] + ( captionRect[ 3 ] - captionRect[ 1 ]  ) , captionRect[ 2 ] + 2, , )
               ELSEIF  oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE  ==  DT_CENTER
                  CaptionRect[ 1 ] := captionRect[ 1 ] + ( captionRect[ 3 ] - captionRect[ 1 ] + aTxtSize[ 1 ] ) / 2  +  ;
                     Min( ( x + xSize - ( 1 + ::aMargin[ 2 ] ) ) - ( captionRect[ 1 ] + ( captionRect[ 3 ] - captionRect[ 1 ] + aTxtSize[ 1 ] ) / 2   ) - 16, 8 )
                  hwg_Drawbitmap( hDC, oBmpSort:Handle, , captionRect[ 1 ] - 1 , captionRect[ 2 ]  , , )
               ELSE
                  hwg_Drawtransparentbitmap( hDC, oBmpSort:Handle, captionRect[ 1 ] - nMe , captionRect[ 2 ] , , )
               ENDIF
            ENDIF
         ENDIF
      ELSE
         xSize := 0
         IF fif = Len( ::aColumns ) .AND. !lFixed
            fif := hb_RAscan( ::aColumns, { | c | c:lhide = .F. } ) - 1
            //::nPaintCol := nColumn
            x -= ::aColumns[ fif + 1 ]:width
            lFixed := .T.
         ENDIF
      ENDIF
      x += xSize
      IF oColumn:headColor <> NIL
         hwg_Settextcolor( hDC, toldc )
      ENDIF
      fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         EXIT
      ENDIF
   ENDDO
   ::xAdjRight := x
   IF ::lShowMark  .OR. ::lDeleteMark
      xSize := ::nShowMark + ::nDeleteMark
      IF ::hTheme != NIL
         hwg_drawthemebackground( ::hTheme, hDC, BP_PUSHBUTTON, 1, ;
            { ::x1 - xSize - 1 , ::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight - 1, ;
            ::x1 + 1 ,  ::y1 + 1 }, NIL )
      ELSE
         hwg_Selectobject( hDC, oPen64:handle )
         hwg_Rectangle( hDC, ::x1 - xSize - 1, ::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight , ;
            ::x1 - 1 , ::y1  )
         hwg_Drawbutton( hDC, ::x1 - xSize - 0 , ::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight , ;
            ::x1 - 1,  ::y1, 1 )
      ENDIF
   ENDIF

   IF ::hTheme != NIL
      hwg_Selectobject( hDC, oPen64:handle )
      hwg_Rectangle( hDC, ;
         ::x1 - ::nShowMark - ::nDeleteMark , ;
         ::y1 , ;//- ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight , ;
      ::x2 , ;
         ::y1   )
   ENDIF
   IF ! ::lAdjRight
      hwg_Drawline( hDC, ::xAdjRight, ::y1 - 1, ::x2 , ::y1 - 1  )
   ENDIF
   hwg_Setbkcolor( hDC, oldBkColor )
   IF ::headColor <> NIL
      hwg_Settextcolor( hDC, oldc )
   ENDIF
   IF ::oHeadFont <> NIL
      hwg_Selectobject( hDC, oldfont )
   ENDIF
   IF ::lResizing .AND. xDragMove > 0
      hwg_Selectobject( hDC, oPen64:handle )
      //hwg_Rectangle( hDC, xDragMove , 1, xDragMove , 1 + ( ::nheight + 1 )  )
      hwg_Drawline( hDC, xDragMove, 1, xDragMove , ( ::nHeadHeight * ::nHeadRows ) + ::nyHeight + 1 + ( ::rowCount * ( ::height + 1 + ::aMargin[ 3 ] ) ) )
   ENDIF
   IF ::lDispSep
      hwg_Deleteobject( oPen )
      IF oPenHdr != NIL
         oPenHdr:Release()
      ENDIF
      IF oPenLight != NIL
         oPenLight:Release()
      ENDIF
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD SeparatorOut( hDC, nRowsFill ) CLASS HBrowseEx
   LOCAL i, x, fif, xSize, lFixed := .F. , xSizeMax
   LOCAL bColor
   LOCAL oColumn, oPen, oPenLight, oPenFree

   DEFAULT nRowsFill TO Min( ::nRecords + iif( ::lAppMode, 1, 0 ), ::rowCount )
   oPen := NIL
   oPenLight := NIL
   oPenFree := NIL

   IF ! ::lDispSep
      oPen := HPen():Add( PS_SOLID, 1, ::bColor )
      hwg_Selectobject( hDC, oPen:handle )
   ELSEIF ::lDispSep
      oPen := HPen():Add( PS_SOLID, 1, ::sepColor )
      hwg_Selectobject( hDC, oPen:handle )
   ENDIF
   IF ::lSep3d
      IF oPenLight == NIL
         oPenLight := HPen():Add( PS_SOLID, 1, hwg_Getsyscolor( COLOR_3DHILIGHT ) )
      ENDIF
   ENDIF

   x := ::x1 
   fif := iif( ::freeze > 0, 1, ::nLeftCol )
   hwg_Fillrect( hDC, ::x1 - ::nShowMark - ::nDeleteMark - 1 , ::y1 + ( ::height + 1 ) * nRowsfill + 1, ::x2 , ::y2 - ( ::nFootHeight * ::nFootRows ) , ::brush:handle )
   // SEPARATOR HORIZONT
   FOR i := 1 TO nRowsFill
      hwg_Drawline( hDC, ::x1 - ::nDeleteMark, ::y1 + ( ::height + 1 ) * i, iif( ::lAdjRight, ::x2, ::x2 ), ::y1 + ( ::height + 1 ) * i )
   NEXT
   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[ fif ]
      xSize := oColumn:width
      IF ( fif == Len( ::aColumns ) ) .OR. lFixed
         xSizeMax := Max( ::x2 - x, xSize ) - 1
         xSize := iif( ::lAdjRight, xSizeMax, xSize )
      ENDIF
      IF ! oColumn:lHide
         IF ::lDispSep .AND. x > ::x1
            IF ::lSep3d
               hwg_Selectobject( hDC, oPenLight:handle )
               hwg_Drawline( hDC, x - 1, ::y1 + 1, x - 1, ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
               hwg_Selectobject( hDC, oPen:handle )
               hwg_Drawline( hDC, x - 2, ::y1 + 1, x - 2, ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
            ELSE
               hwg_Selectobject( hDC, oPen:handle )
               hwg_Drawline( hDC, x - 1 , ::y1 + 1, x - 1, ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
            ENDIF
         ELSE
            // SEPARATOR VERTICAL
            IF ! ::lDispSep .AND. ( oColumn:bColorBlock != NIL .OR. oColumn:bColor != NIL )
               bColor := iif( oColumn:bColorBlock != NIL , ( Eval( oColumn:bColorBlock, ::FLDSTR( Self, fif ), fif, Self ) )[ 2 ], oColumn:bColor )
               IF bColor != NIL
                  // horizontal
                  hwg_Selectobject( hDC, HPen():Add( PS_SOLID, 1, bColor ):handle )
                  FOR i := 1 TO nRowsFill
                     hwg_Drawline( hDC, x, ::y1 + ( ::height + 1 ) * i, x + xsize, ::y1 + ( ::height + 1 ) * i )
                  NEXT
               ENDIF
            ENDIF
            IF x > ::x1 - iif( ::lDeleteMark , 1, 0 )
               hwg_Selectobject( hDC, oPen:handle )
               hwg_Drawline( hDC, x - 1, ::y1 + 1, x - 1, ::y1 + ( ::height + 1 ) * nRowsFill )
            ENDIF
         ENDIF
      ELSE
         xSize := 0
         IF fif = Len( ::aColumns ) .AND. !lFixed
            fif := hb_RAscan( ::aColumns, { |c| c:lhide = .F. } ) - 1
            x -= ::aColumns[ fif + 1 ]:width
            lFixed := .T.
         ENDIF
      ENDIF
      x += xSize

      fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         EXIT
      ENDIF
   ENDDO
   //  SEPARATOR HORIZONT
   hwg_Selectobject( hDC, oPen:handle )
   IF ! ::lAdjRight
      IF ::lSep3d
         hwg_Selectobject( hDC, oPenLight:handle )
         hwg_Drawline( hDC, x - 1 , ::y1 - ( ::height * ::nHeadRows ), x - 1 , ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
         hwg_Selectobject( hDC, oPen:handle )
         hwg_Drawline( hDC, x - 2 , ::y1 - ( ::height * ::nHeadRows ), x - 2 , ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
      ELSE
         hwg_Drawline( hDC, x - 1 , ::y1 - ( ::height * ::nHeadRows ), x - 1 , ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
      ENDIF
   ELSE
      hwg_Drawline( hDC, x, ::y1 - ( ::height * ::nHeadRows ), x , ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
   ENDIF
   IF ::lDispSep
      hwg_Deleteobject( oPen )
      IF oPenLight != NIL
         oPenLight:Release()
      ENDIF
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD FooterOut( hDC ) CLASS HBrowseEx
   LOCAL x, fif, xSize, oPen, nLine, cStr
   LOCAL oColumn, aColorFoot, oldBkColor, oldTColor, oBrush
   LOCAL nPixelFooterHeight, nY, lFixed := .F.
   LOCAL lColumnFont := .F. , nMl, aItemRect

   nMl := iif( ::lShowMark, ::nShowMark, 0 ) + iif( ::lDeleteMark,  ::nDeleteMark, 0 )
   IF ! ::lDispSep
      oPen := HPen():Add( PS_SOLID, 1, ::bColor )
      hwg_Selectobject( hDC, oPen:handle )
   ELSEIF ::lDispSep
      oPen := HPen():Add( PS_SOLID, 1, ::sepColor )
      hwg_Selectobject( hDC, oPen:handle )
   ENDIF

   x := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[ fif ]
      xSize := oColumn:width
      IF ::lAdjRight .AND. fif == Len( ::aColumns ) .OR. lFixed
         xSize := Max( ::x2 - x, xSize )
      ENDIF
      IF ! oColumn:lHide
         cStr := oColumn:footing + ';'
         aColorFoot := NIL
         IF oColumn:bColorFoot != NIL
            aColorFoot := Eval( oColumn:bColorFoot, Self )
            oldBkColor := hwg_Setbkcolor(   hDC, aColorFoot[ 2 ] )
            oldTColor  := hwg_Settextcolor( hDC, aColorFoot[ 1 ] )
            oBrush := HBrush():Add( aColorFoot[ 2 ] )
         ELSE
            oBrush := NIL
         ENDIF
         IF oColumn:FootFont != NIL
            hwg_Selectobject( hDC, oColumn:FootFont:Handle )
            lColumnFont := .T.
         ELSEIF lColumnFont
            hwg_Selectobject( hDC, ::ofont:handle )
            lColumnFont := .F.
         ENDIF
         nPixelFooterHeight := ( ::nFootRows ) * ( ::nFootHeight + 1 )
         IF ::lDispSep
            IF ::hTheme != NIL
               aItemRect := {  x, ::y2 - nPixelFooterHeight , x + xsize, ::y2 + 1 }
               hwg_drawthemebackground( ::hTheme, hDC, PBS_NORMAL , 0 , aItemRect, NIL )
               hwg_Setbkmode( hDC, 1 )
            ELSE
               hwg_Drawbutton( hDC, x, ::y2 - nPixelFooterHeight, x + xsize, ::y2 , 0 )
               hwg_Drawline( hDC, x, ::y2, x + xSize, ::y2 )
            ENDIF
         ELSE
            IF ::hTheme != NIL
               aItemRect := {  x, ::y2 - nPixelFooterHeight , x + xsize + 1, ::y2 + 1 }
               hwg_drawthemebackground( ::hTheme, hDC, PBS_NORMAL , 0 , aItemRect, NIL )
               hwg_Setbkmode( hDC, 1 )
            ELSE
               hwg_Drawbutton( hDC, x, ::y2 - nPixelFooterHeight, x + xsize + 1, ::y2 + 1 , 0 )
            ENDIF
         ENDIF
         IF oBrush != NIL
            hwg_Fillrect( hDC, x, ::y2 - nPixelFooterHeight + 1,  ;
               x + xSize - 1, ::y2, oBrush:handle )
         ELSE
            oldBkColor := hwg_Setbkcolor( hDC, hwg_Getsyscolor( COLOR_3DFACE ) )
         ENDIF
         nY := ::y2 - nPixelFooterHeight
         FOR nLine := 1 TO ::nFootRows
            hwg_Drawtext( hDC, hb_tokenGet( @cStr, nLine, ';' ), ;
               x + ::aMargin[ 4 ], ;
               nY + ( nLine - 1 ) * ( ::nFootHeight + 1 ) + 1 + ::aMargin[ 1 ], ;
               x + xSize - ( 1 + ::aMargin[ 2 ] ), ;
               nY + ( nLine ) * ( ::nFootHeight + 1 ), ;
               oColumn:nJusFoot + iif( oColumn:lSpandFoot, DT_NOCLIP, 0 ) )
         NEXT // nando DT_VCENTER + DT_SINGLELINE
         IF aColorFoot != NIL
            hwg_Setbkcolor(   hDC, oldBkColor )
            hwg_Settextcolor( hDC, oldTColor )
            oBrush:release()
         ENDIF
         // Draw footer separator
         IF ::lDispSep .AND. x >= ::x1
            hwg_Drawline( hDC, x + xSize - 1, nY + 3, x + xSize - 1, ::y2 - 4 )
         ENDIF
      ELSE
         xSize := 0
         IF fif = Len( ::aColumns ) .AND. !lFixed
            fif := hb_RASCAN( ::aColumns, { | c | c:lhide = .F. } ) - 1
            x -= ::aColumns[ fif + 1 ]:width
            lFixed := .T.
         ENDIF
      ENDIF
      x += xSize
      fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         EXIT
      ENDIF
   ENDDO

   IF ::lDispSep
      IF HWG_BITAND( ::style, WS_HSCROLL ) != 0
         hwg_Drawline( hDC, ::x1 , ::y2 - 1, iif( ::lAdjRight, ::x2, x ), ::y2 - 1 )
      ENDIF
      oPen:Release()
   ENDIF
   IF nMl > 0
      hwg_Selectobject( hDC, oPen64:handle )
      xSize := nMl
      IF ::hTheme != NIL
         aItemRect := {  ::x1 - xSize , nY , ::x1 - 1,  ::y2 + 1 }
         hwg_drawthemebackground( ::hTheme, hDC, BP_PUSHBUTTON, 0 , aItemRect, NIL )
      ELSE
         hwg_Drawbutton( hDC, ::x1 - xSize , nY, ::x1 - 1,  ::y2, 1 )
      ENDIF
   ENDIF
   IF lColumnFont
      hwg_Selectobject( hDC, ::oFont:Handle )
   ENDIF

   RETURN NIL

   //-------------- -Row--  --Col-- ------------------------------//

METHOD LineOut( nRow, nCol, hDC, lSelected, lClear ) CLASS HBrowseEx
   LOCAL x, nColumn, sviv, xSize, lFixed := .F. , xSizeMax
   LOCAL j, ob, bw, bh, y1, hBReal, oPen
   LOCAL oldBkColor, oldTColor, oldBk1Color, oldT1Color
   LOCAL lColumnFont := .F.
   LOCAL rcBitmap, ncheck, nstate, nCheckHeight
   LOCAL oLineBrush :=  iif( nCol >= 1, HBrush():Add( ::htbColor ), iif( lSelected, ::brushSel, ::brush ) )
   LOCAL aCores

   nColumn := 1
   x := ::x1
   IF lClear == NIL ; lClear := .F. ; ENDIF
   IF ::bLineOut != NIL
      Eval( ::bLineOut, Self, lSelected )
   ENDIF
   IF ::nRecords > 0 .OR. lClear
      ::nPaintCol  := iif( ::freeze > 0, 1, ::nLeftCol )
      ::nPaintRow  := nRow
      IF ::lDeleteMark
         hwg_Fillrect( hDC, ::x1 - ::nDeleteMark - 0, ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 , ;
            ::x1 - 1 , ::y1 + ( ::height + 1 ) * ::nPaintRow , iif( Deleted(), hwg_Getstockobject( 7 ), hwg_Getstockobject( 0 ) ) ) //::brush:handle ))
      ENDIF
      IF ::lShowMark
         IF ::hTheme != NIL
            hwg_drawthemebackground( ::hTheme, hDC, BP_PUSHBUTTON, iif( lSelected, PBS_VERTICAL,  PBS_VERTICAL ), ;
               { ::x1 - ::nShowMark - ::nDeleteMark - 1, ;
               ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1  , ;
               ::x1 - ::nDeleteMark   , ;
               ::y1 + ( ::height + 1 ) * ::nPaintRow + 1 }  , NIL )
         ELSE
            hwg_Drawbutton( hDC, ::x1 - ::nShowMark - ::nDeleteMark - 0, ;
               ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1  , ;
               ::x1 - ::nDeleteMark - 1  , ; //IIF( ::lDeleteMark, -1, -2 ),  ;
            ::y1 + ( ::height + 1 ) * ::nPaintRow + 1, 1 )
            hwg_Selectobject( hDC, oPen64:handle )
            hwg_Rectangle( hDC, ::x1 - ::nShowMark - ::nDeleteMark - 1 , ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 )  , ;
               ::x1  - ::nDeleteMark - 1 , ::y1 + ( ::height + 1 ) * ::nPaintRow - 0 ) //, IIF( Deleted(), hwg_Getstockobject( 7 ), ::brush:handle ))
         ENDIF
         IF lSelected
            hwg_Drawtransparentbitmap( hDC, ::oBmpMark:Handle, ::x1 - ::nShowMark - ::nDeleteMark + 1, ;
               ( ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) ) + ;
               ( ( ::y1 + ( ::height + 1 ) * ( ::nPaintRow  ) ) - ( ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) ) ) / 2 - 6 )
            IF ::HighlightStyle = 2 .OR. ( ( ::HighlightStyle = 0 .AND. hwg_Selffocus( ::Handle ) ) .OR. ;
                  ( ::HighlightStyle = 3 .AND. (  ::Highlight .OR. ::lEditable .OR. ! hwg_Selffocus( ::Handle ) ) ) )
               IF ! ::lEditable  .OR. ::HighlightStyle = 3 .OR. ::HighlightStyle = 0
                  ::internal[ 1 ] := 1
                  oPen := HPen():Add( 0, 1, ::bcolorSel )
                  hwg_Selectobject( hDC, hwg_Getstockobject( NULL_BRUSH ) )
                  hwg_Selectobject( hDC, oPen:handle )
                  hwg_Roundrect( hDC, ::x1, ;
                     ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1  , ;
                     ::xAdjRight - 2, ;  //::x2 - 1  ,;
                  ::y1 + ( ::height + 1 ) * ::nPaintRow  , 0, 0 )
                  hwg_Deleteobject( oPen )
                  IF ( ( ::Highlight .OR. ! ::lEditable ) .AND. nCol = 0 )  .OR. ( ::HighlightStyle = 3 .AND. ! hwg_Selffocus( ::Handle ) )
                     RETURN NIL
                  ENDIF
               ENDIF
            ELSEIF ::HighlightStyle = 0 //.OR. ::HighlightStyle = 3
               RETURN NIL
            ENDIF
         ENDIF
      ENDIF
      oldBkColor := hwg_Setbkcolor(   hDC, iif( nCol >= 1, ::htbcolor, iif( lSelected, ::bcolorSel, ::bcolor ) ) )
      oldTColor  := hwg_Settextcolor( hDC, iif( nCol >= 1, ::httcolor, iif( lSelected, ::tcolorSel, ::tcolor ) ) )
      ::nVisibleColLeft :=  ::nPaintCol
      WHILE x < ::x2 - 2
         aCores := {}
         IF ( nCol == 0 .OR. nCol == nColumn ) .AND. ::aColumns[ ::nPaintCol ]:bColorBlock != NIL .AND. ! lClear
            // nando
            aCores := Eval( ::aColumns[ ::nPaintCol ]:bColorBlock, ::FLDSTR( Self, ::nPaintCol ), ::nPaintCol, Self )
            IF lSelected
               ::aColumns[ ::nPaintCol ]:tColor := iif( aCores[ 3 ] != NIL, aCores[ 3 ], ::tcolorSel )
               ::aColumns[ ::nPaintCol ]:bColor := iif( aCores[ 4 ] != NIL, aCores[ 4 ], ::bcolorSel )
            ELSE
               ::aColumns[ ::nPaintCol ]:tColor := iif( aCores[ 1 ] != NIL, aCores[ 1 ], ::tcolor )
               ::aColumns[ ::nPaintCol ]:bColor := iif( aCores[ 2 ] != NIL, aCores[ 2 ], ::bcolor )
            ENDIF
            ::aColumns[ ::nPaintCol ]:brush := HBrush():Add( ::aColumns[ ::nPaintCol ]:bColor )
         ELSE
            ::aColumns[ ::nPaintCol ]:brush := NIL
         ENDIF
         xSize := ::aColumns[ ::nPaintCol ]:width
         xSizeMax := xSize
         IF ( ::nPaintCol == Len( ::aColumns ) ) .OR. lFixed
            xSizeMax := Max( ::x2 - x, xSize )
            xSize := iif( ::lAdjRight, xSizeMax, xSize )
            ::nWidthColRight := xSize
         ENDIF
         IF !::aColumns[ ::nPaintCol ]:lHide
            IF nCol == 0 .OR. nCol == nColumn
               hBReal := oLineBrush:handle
               IF ! lClear
                  IF ::aColumns[ ::nPaintCol ]:bColor != NIL .AND. ::aColumns[ ::nPaintCol ]:brush == NIL
                     ::aColumns[ ::nPaintCol ]:brush := HBrush():Add( ::aColumns[ ::nPaintCol ]:bColor )
                  ENDIF
                  hBReal := iif( ::aColumns[ ::nPaintCol ]:brush != NIL .AND. !( lSelected .AND. Empty( aCores ) ), ;
                     ::aColumns[ ::nPaintCol ]:brush:handle, oLineBrush:handle )
               ENDIF
               // Fill background color of a cell
               hwg_Fillrect( hDC, x, ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1, ;
                  x + xSize - iif( ::lSep3d, 2, 1 ), ::y1 + ( ::height + 1 ) * ::nPaintRow, hBReal )
               IF xSize != xSizeMax
                  hBReal := HBrush():Add( 16448764 ):Handle
                  hwg_Fillrect( hDC, x + xsize, ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 , ;
                     x + xSizeMax - iif( ::lSep3d, 2, 1 ) , ::y1 + ( ::height + 1 ) * ::nPaintRow, hBReal ) //::brush:handle )
               ENDIF
               IF ! lClear
                  IF ::aColumns[ ::nPaintCol ]:aBitmaps != NIL .AND. ! Empty( ::aColumns[ ::nPaintCol ]:aBitmaps )
                     FOR j := 1 TO Len( ::aColumns[ ::nPaintCol ]:aBitmaps )
                        IF Eval( ::aColumns[ ::nPaintCol ]:aBitmaps[ j, 1 ], Eval( ::aColumns[ ::nPaintCol ]:block,, Self, ::nPaintCol ), lSelected )
                           ob := ::aColumns[ ::nPaintCol ]:aBitmaps[ j, 2 ]
                           IF hb_isObject( ob )
                              IF ob:nHeight > ::height
                                 y1 := 0
                                 bh := ::height
                                 bw := Int( ob:nWidth * ( ob:nHeight / ::height ) )
                                 hwg_Drawbitmap( hDC, ob:handle, , x + ( Int( ::aColumns[ ::nPaintCol ]:width - ob:nWidth ) / 2 ), y1 + ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1, bw, bh )
                              ELSE
                                 y1 := Int( ( ::height - ob:nHeight ) / 2 )
                                 hwg_Drawtransparentbitmap( hDC, ob:handle, x + ( Int( ::aColumns[ ::nPaintCol ]:width - ob:nWidth ) / 2 ), y1 + ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 )
                              ENDIF
                           ENDIF
                           EXIT
                        ENDIF
                     NEXT
                  ELSE
                     sviv := ::FLDSTR( Self, ::nPaintCol )
                     // new nando
                     IF ::aColumns[ ::nPaintCol ]:type = "L"
                        ncheck := iif( sviv = "T", 1, 0 ) + 1
                        rcBitmap := { x + ::aMargin[ 4 ] + 1, ;
                           ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 + ::aMargin[ 1 ], ;
                           0, 0 }
                        nCheckHeight := ( ::y1 + ( ::height + 1 ) * ::nPaintRow  ) - ( ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) ) - ::aMargin[ 1 ] - ::aMargin[ 3 ] - 1
                        nCheckHeight := iif( nCheckHeight > 16, 16, nCheckHeight )
                        IF Hwg_BitAND( ::aColumns[ ::nPaintCol ]:nJusLin, DT_CENTER ) != 0
                           rcBitmap[ 1 ] := rcBitmap[ 1 ] + (  xsize - ::aMargin[ 2 ] - ::aMargin[ 4 ] - nCheckHeight + 1 ) / 2
                        ENDIF
                        rcBitmap[ 4 ] := ::y1 + ( ::height + 1 ) * ::nPaintRow - ( 1 + ::aMargin[ 3 ] )
                        rcBitmap[ 2 ] := rcBitmap[ 2 ] + ( ( rcBitmap[ 4 ] -  rcBitmap[ 2 ] )  -  nCheckHeight + 1 ) / 2
                        rcBitmap[ 3 ] := rcBitmap[ 1 ] + nCheckHeight
                        rcBitmap[ 4 ] := rcBitmap[ 2 ] + nCheckHeight
                        IF ( nCheck > 0 )
                           nState := DFCS_BUTTONCHECK
                           IF ( nCheck > 1 )
                              nState := hwg_bitor( nstate, DFCS_CHECKED )
                           ENDIF
                           nState += iif( ::lEditable .OR. ::aColumns[ ::nPaintCol ]:lEditable, 0, DFCS_INACTIVE )
                           hwg_Drawframecontrol( hDC, rcBitmap, DFC_BUTTON , nState + DFCS_FLAT  )
                        ENDIF
                        sviv := ""
                     ENDIF
                     // Ahora lineas Justificadas !!
                     IF ::aColumns[ ::nPaintCol ]:tColor != NIL //.AND. ( ::nPaintCol != ::colPos .OR. ! lSelected )
                        oldT1Color := hwg_Settextcolor( hDC, ::aColumns[ ::nPaintCol ]:tColor )
                     ENDIF
                     IF ::aColumns[ ::nPaintCol ]:bColor != NIL //.AND. ( ::nPaintCol != ::colPos .OR. ! lSelected )
                        oldBk1Color := hwg_Setbkcolor( hDC, ::aColumns[ ::nPaintCol ]:bColor )
                     ENDIF
                     IF ::aColumns[ ::nPaintCol ]:oFont != NIL
                        hwg_Selectobject( hDC, ::aColumns[ ::nPaintCol ]:oFont:handle )
                        lColumnFont := .T.
                     ELSEIF lColumnFont
                        hwg_Selectobject( hDC, ::ofont:handle )
                        lColumnFont := .F.
                     ENDIF
                     IF ::aColumns[ ::nPaintCol ]:Hint
                        AAdd( ::aColumns[ ::nPaintCol ]:aHints, sViv )
                     ENDIF
                     hwg_Drawtext( hDC, sviv,  ;
                        x + ::aMargin[ 4 ] + 1, ;
                        ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 + ::aMargin[ 1 ] , ;
                        x + xSize - ( 2 + ::aMargin[ 2 ] ) , ;
                        ::y1 + ( ::height + 1 ) * ::nPaintRow - ( 1 + ::aMargin[ 3 ] ) , ;
                        ::aColumns[ ::nPaintCol ]:nJusLin + DT_NOPREFIX )
                     // Clipping rectangle
#if 0
                     hwg_Rectangle( hDC, ;
                        x + ::aMargin[ 4 ], ;
                        ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 + ::aMargin[ 1 ] , ;
                        x + xSize - ( 2 + ::aMargin[ 2 ] ) , ;
                        ::y1 + ( ::height + 1 ) * ::nPaintRow - ( 1 + ::aMargin[ 3 ] ) ;
                        )
#endif
                     IF ::aColumns[ ::nPaintCol ]:tColor != NIL //.AND. ( ::nPaintCol != ::colPos .OR. ! lSelected )
                        hwg_Settextcolor( hDC, oldT1Color )
                     ENDIF
                     IF ::aColumns[ ::nPaintCol ]:bColor != NIL //.AND. ( ::nPaintCol != ::colPos .OR. ! lSelected )
                        hwg_Setbkcolor( hDC, oldBk1Color )
                     ENDIF
                  ENDIF
               ENDIF
            ENDIF
         ELSE
            xSize := 0
            IF nCol > 0 .AND. lSelected .AND. nCol = nColumn
               nCol ++
            ENDIF
            IF nColumn = Len( ::aColumns ) .AND. !lFixed
               nColumn := hb_RAscan( ::aColumns, { | c | c:lhide = .F. } ) - 1
               ::nPaintCol := nColumn
               x -= ::aColumns[ ::nPaintCol + 1 ]:width
               lFixed := .T.
            ENDIF
         ENDIF
         x += xSize
         ::nPaintCol := iif( ::nPaintCol == ::freeze, ::nLeftCol, ::nPaintCol + 1 )
         nColumn ++
         IF ! ::lAdjRight .AND. ::nPaintCol > Len( ::aColumns )
            EXIT
         ENDIF
      ENDDO

      hwg_Settextcolor( hDC, oldTColor )
      hwg_Setbkcolor( hDC, oldBkColor )
      IF lColumnFont
         hwg_Selectobject( hDC, ::ofont:handle )
      ENDIF
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD SetColumn( nCol ) CLASS HBrowseEx
   LOCAL nColPos, lPaint := .F.
   LOCAL lEditable := ::lEditable .OR. ::Highlight

   IF lEditable .OR. ::lAutoEdit
      IF nCol != NIL .AND. nCol >= 1 .AND. nCol <= Len( ::aColumns )
         IF nCol <= ::freeze
            ::colpos := nCol
         ELSEIF nCol >= ::nLeftCol .AND. nCol <= ::nLeftCol + ::nColumns - ::freeze - 1
            ::colpos := nCol - ::nLeftCol + ::freeze + 1
         ELSE
            ::nLeftCol := nCol
            ::colpos := ::freeze + 1
            lPaint := .T.
         ENDIF
         IF ! lPaint
            ::RefreshLine()
         ELSE
            hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
         ENDIF
      ENDIF
      IF ::colpos <= ::freeze
         nColPos := ::colpos
      ELSE
         nColPos := ::nLeftCol + ::colpos - ::freeze - 1
      ENDIF
      RETURN nColPos
   ENDIF

   RETURN 1

   //----------------------------------------------------//

STATIC FUNCTION LINERIGHT( oBrw )
   LOCAL i
   LOCAL lEditable := oBrw:lEditable .OR. oBrw:Highlight

   IF lEditable .OR. oBrw:lAutoEdit
      IF oBrw:colpos < oBrw:nColumns
         oBrw:colpos ++
         RETURN NIL
      ENDIF
   ENDIF
   IF oBrw:nColumns + oBrw:nLeftCol - oBrw:freeze - 1 < Len( oBrw:aColumns ) .AND. ;
         oBrw:nLeftCol < Len( oBrw:aColumns )
      i := oBrw:nLeftCol + oBrw:nColumns
      DO WHILE oBrw:nColumns + oBrw:nLeftCol - oBrw:freeze - 1 < Len( oBrw:aColumns ) .AND. oBrw:nLeftCol + oBrw:nColumns = i
         oBrw:nLeftCol ++
      ENDDO
      oBrw:colpos := i - oBrw:nLeftCol + 1
   ENDIF

   RETURN NIL

   //----------------------------------------------------//
   // Move the visible browse one step to the left

STATIC FUNCTION LINELEFT( oBrw )
   LOCAL lEditable := oBrw:lEditable .OR. oBrw:Highlight

   IF lEditable .OR. oBrw:lAutoEdit
      oBrw:colpos --
   ENDIF
   IF oBrw:nLeftCol > oBrw:freeze + 1 .AND. ( ! lEditable .OR. oBrw:colpos < oBrw:freeze + 1 )
      oBrw:nLeftCol --
      IF ! lEditable .OR. oBrw:colpos < oBrw:freeze + 1
         oBrw:colpos := oBrw:freeze + 1
      ENDIF
   ENDIF
   IF oBrw:colpos < 1
      oBrw:colpos := 1
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD DoVScroll( wParam ) CLASS HBrowseEx
   LOCAL nScrollCode := hwg_Loword( wParam )

   IF nScrollCode == SB_LINEDOWN
      ::LINEDOWN( .T. )
   ELSEIF nScrollCode == SB_LINEUP
      ::LINEUP()
   ELSEIF nScrollCode == SB_BOTTOM
      ::BOTTOM()
   ELSEIF nScrollCode == SB_TOP
      ::TOP()
   ELSEIF nScrollCode == SB_PAGEDOWN
      ::PAGEDOWN()
   ELSEIF nScrollCode == SB_PAGEUP
      ::PAGEUP()
   ELSEIF nScrollCode == SB_THUMBPOSITION .OR. nScrollCode == SB_THUMBTRACK
      ::Setfocus()
      IF ::bScrollPos != NIL
         Eval( ::bScrollPos, Self, nScrollCode, .F. , hwg_Hiword( wParam ) )
      ELSE
         IF ( ::Alias ) -> ( IndexOrd() ) == 0              // sk
            ( ::Alias ) -> ( dbGoto( hwg_Hiword( wParam ) ) )   // sk
         ELSE
            ( ::Alias ) -> ( OrdKeyGoTo( hwg_Hiword( wParam ) ) ) // sk
         ENDIF
         Eval( ::bSkip, Self, 1 )
         Eval( ::bSkip, Self, - 1 )
         hwg_VScrollPosEx( Self, 0, .F. )
         ::refresh()
      ENDIF
   ENDIF

   RETURN 0

   //----------------------------------------------------//

METHOD DoHScroll( wParam ) CLASS HBrowseEx
   LOCAL nScrollCode := hwg_Loword( wParam )
   LOCAL nPos
   LOCAL oldLeft := ::nLeftCol, nLeftCol, colpos, oldPos := ::colpos

   IF ! ::ChangeRowCol( 2 )
      RETURN .F.
   ENDIF

   IF nScrollCode == SB_LINELEFT .OR. nScrollCode == SB_PAGELEFT
      LineLeft( Self )
   ELSEIF nScrollCode == SB_LINERIGHT .OR. nScrollCode == SB_PAGERIGHT
      LineRight( Self )
   ELSEIF nScrollCode == SB_LEFT
      nLeftCol := colpos := 0
      DO WHILE nLeftCol != ::nLeftCol .OR. colpos != ::colpos
         nLeftCol := ::nLeftCol
         colpos := ::colpos
         LineLeft( Self )
      ENDDO
   ELSEIF nScrollCode == SB_RIGHT
      nLeftCol := colpos := 0
      DO WHILE nLeftCol != ::nLeftCol .OR. colpos != ::colpos
         nLeftCol := ::nLeftCol
         colpos := ::colpos
         LineRight( Self )
      ENDDO
   ELSEIF nScrollCode == SB_THUMBTRACK .OR. nScrollCode == SB_THUMBPOSITION
      ::Setfocus()
      IF ::lEditable
         hwg_Setscrollrange( ::handle, SB_HORZ, 1, Len( ::aColumns ) )
         hwg_Setscrollpos( ::handle, SB_HORZ, hwg_Hiword( wParam ) )
         ::SetColumn( hwg_Hiword( wParam ) )
      ELSE
         IF hwg_Hiword( wParam ) > ( ::colpos + ::nLeftCol - 1 )
            LineRight( Self )
         ENDIF
         IF hwg_Hiword( wParam ) < ( ::colpos + ::nLeftCol - 1 )
            LineLeft( Self )
         ENDIF
      ENDIF
   ENDIF
   IF ::nLeftCol != oldLeft .OR. ::colpos != oldPos
      IF HWG_BITAND( ::style, WS_HSCROLL ) != 0
         hwg_Setscrollrange( ::handle, SB_HORZ, 1, Len( ::aColumns ) )
         nPos :=  ::colpos + ::nLeftCol - 1
         hwg_Setscrollpos( ::handle, SB_HORZ, nPos )
      ENDIF
      // TODO: here I force a full repaint and HSCROLL appears...
      //       but we should do more checks....
      // IF ::nLeftCol == oldLeft
      //   ::RefreshLine()
      //ELSE
      IF ::nLeftCol != ::nVisibleColLeft
         hwg_Redrawwindow( ::handle, RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW )  // Force a complete redraw
      ELSE
         ::RefreshLine()
      ENDIF
   ENDIF
   ::Setfocus()

   RETURN NIL

   //----------------------------------------------------//

METHOD LINEDOWN( lMouse ) CLASS HBrowseEx

   Eval( ::bSkip, Self, 1 )
   IF Eval( ::bEof, Self )
      //Eval( ::bSkip, Self, - 1 )
      IF ::lAppable .AND. ( lMouse == NIL .OR. ! lMouse )
         ::lAppMode := .T.
      ELSE
         Eval( ::bSkip, Self, - 1 )
         IF ! hwg_Selffocus( ::handle )
            ::Setfocus()
         ENDIF
         RETURN NIL
      ENDIF
   ENDIF
   ::rowPos ++
   IF ::rowPos > ::rowCount
      ::rowPos := ::rowCount
      IF ::lAppMode
         hwg_Redrawwindow( ::handle, RDW_INVALIDATE + RDW_UPDATENOW + RDW_NOERASE )
      ELSE
         hwg_Redrawwindow( ::handle, RDW_INVALIDATE + RDW_INTERNALPAINT )
      ENDIF
      ::internal[ 1 ] := 14
   ELSE
      ::internal[ 1 ] := 0
   ENDIF
   hwg_Invalidaterect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] - ::height, ::xAdjRight, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] )
   hwg_Invalidaterect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::xAdjRight , ::y1 + ( ::height + 1 ) * ::rowPos )

   //ENDIF
   IF ::lAppMode
      IF ::RowCurrCount < ::RowCount
         Eval( ::bSkip, Self, - 1 )
      ENDIF
      IF ::rowPos > 1
         ::rowPos --
      ENDIF
      ::colPos := Max( 1,  Ascan( ::aColumns, { | c |  c:lEditable } ) )
      ::nLeftCol  := ::freeze + 1
   ENDIF
   IF ! ::lAppMode  .OR. ::nLeftCol == 1
      ::internal[ 1 ] := hwg_SetBit( ::internal[ 1 ], 1, 0 )
   ENDIF

   IF ::bScrollPos != NIL
      Eval( ::bScrollPos, Self, 1, .F. )
   ELSEIF ::nRecords > 1
      hwg_VScrollPosEx( Self, 0, .F. )
   ENDIF

   // ::Setfocus()  ??

   RETURN NIL

   //----------------------------------------------------//

METHOD LINEUP() CLASS HBrowseEx

   Eval( ::bSkip, Self, - 1 )
   IF Eval( ::bBof, Self )
      Eval( ::bGoTop, Self )
   ELSE
      ::rowPos --
      IF ::rowPos = 0  // needs scroll
         ::rowPos := 1
         hwg_Redrawwindow( ::handle, RDW_INVALIDATE + RDW_INTERNALPAINT )
         ::internal[ 1 ] := 14
      ELSE
         ::internal[ 1 ] := 0
      ENDIF
      hwg_Invalidaterect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] - ::height, ::xAdjRight, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] )
      hwg_Invalidaterect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::xAdjRight , ::y1 + ( ::height + 1 ) * ::rowPos )
      IF ::bScrollPos != NIL
         Eval( ::bScrollPos, Self, - 1, .F. )
      ELSEIF ::nRecords > 1
         hwg_VScrollPosEx( Self, 0, .F. )
      ENDIF
      ::internal[ 1 ] := hwg_SetBit( ::internal[ 1 ], 1, 0 )
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD PAGEUP() CLASS HBrowseEx
   LOCAL STEP, lBof := .F.

   IF ::rowPos > 1
      STEP := ( ::rowPos - 1 )
      Eval( ::bSKip, Self, - STEP )
      ::rowPos := 1
   ELSE
      STEP := ::rowCurrCount
      Eval( ::bSkip, Self, - STEP )
      IF Eval( ::bBof, Self )
         Eval( ::bGoTop, Self )
         lBof := .T.
      ENDIF
   ENDIF
   IF ::bScrollPos != NIL
      Eval( ::bScrollPos, Self, - STEP, lBof )
   ELSEIF ::nRecords > 1
      hwg_VScrollPosEx( Self, 0, .F. )
   ENDIF

   ::Refresh( ::nFootRows > 0 )

   RETURN NIL

   //----------------------------------------------------//
/*
 *
 * If cursor is in the last visible line, skip one page
 * If cursor in not in the last line, go to the last
 *
*/

METHOD PAGEDOWN() CLASS HBrowseEx
   LOCAL nRows := ::rowCurrCount
   LOCAL STEP := iif( nRows > ::rowPos, nRows - ::rowPos, nRows )

   Eval( ::bSkip, Self, STEP )

   IF Eval( ::bEof, Self )
      Eval( ::bSkip, Self, - 1 )
   ENDIF
   ::rowPos := Min( ::nRecords, nRows )

   IF ::bScrollPos != NIL
      Eval( ::bScrollPos, Self, STEP, .F. )
   ELSE
      hwg_VScrollPosEx( Self, 0, .F. )
   ENDIF

   ::Refresh( ::nFootRows > 0 )

   RETURN NIL

   //----------------------------------------------------//

METHOD BOTTOM( lPaint ) CLASS HBrowseEx

   IF ::Type == BRW_ARRAY
      ::nCurrent := ::nRecords
      ::rowPos := iif( ::rowCurrCount <= ::rowCount, ::rowCurrCount , ::rowCount + 1 )
   ELSE
      ::rowPos := iif( ::rowCurrCount <= ::rowCount, ::rowCurrCount , ::rowCount + 1 )
      Eval( ::bGoBot, Self )
   ENDIF

   hwg_VScrollPosEx( Self, 0, iif( ::Type == BRW_ARRAY, .F. , .T. ) )

   IF lPaint == NIL .OR. lPaint
      ::Refresh( ::nFootRows > 0 )
   ELSE
      ::internal[ 1 ] := hwg_SetBit( ::internal[ 1 ], 1, 0 )
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD TOP() CLASS HBrowseEx

   ::rowPos := 1
   Eval( ::bGoTop, Self )
   hwg_VScrollPosEx( Self, 0, .F. )

   ::Refresh( ::nFootRows > 0 )
   ::internal[ 1 ] := hwg_SetBit( ::internal[ 1 ], 1, 0 )

   RETURN NIL

   //----------------------------------------------------//

METHOD ButtonDown( lParam, lReturnRowCol ) CLASS HBrowseEx

   LOCAL nLine
   LOCAL STEP, res
   LOCAL xm, x1, fif
   LOCAL aColumns := {}, nCols := 1, xSize := 0
   LOCAL lEditable := ::lEditable .OR. ::Highlight

   // Calculate the line you clicked on, keeping track of header
   IF( ::lDispHead )
      nLine := Int( ( hwg_Hiword( lParam ) - ( ::nHeadHeight * ::nHeadRows ) ) / ( ::height + 1 ) + 1 )
   ELSE
      nLine := Int( hwg_Hiword( lParam ) / ( ::height + 1 ) + 1 )
   ENDIF

   STEP := nLine - ::rowPos
   res := .F.
   xm := hwg_Loword( lParam )
   x1  := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE nCols <= Len( ::aColumns )
      xSize := ::aColumns[ nCols ]:width
      IF ( ::lAdjRight .AND. nCols == Len( ::aColumns ) )
         xSize := Max( ::x2 - x1, xSize )
      ENDIF
      IF !::aColumns[ nCols ]:lHide
         AAdd( aColumns, { xSize, ncols } )
         x1 += xSize
         xSize := 0
      ENDIF
      nCols ++
   ENDDO
   x1  := ::x1
   aColumns[ Len( aColumns ) , 1 ] += xSize

   DO WHILE fif <= Len( ::aColumns )
      IF ( ! ( fif < ( ::nLeftCol + ::nColumns ) .AND. x1 + aColumns[ fif,1 ] < xm ) )
         EXIT
      ENDIF
      x1 += aColumns[ fif,1 ]
      fif := iif( fif == ::freeze, ::nLeftCol, fif + 1 )
   ENDDO
   IF fif > Len( aColumns )
      IF ! ::lAdjRight     // no column select
         RETURN NIL
      ENDIF
      fif --
   ENDIF
   //nando
   fif := aColumns[ fif, 2 ]
   IF lReturnRowCol != NIL .AND. lReturnRowCol
      RETURN { iif( nLine <= ::rowCurrCount, nLine, - 1 ), fif }
   ENDIF

   IF nLine > 0 .AND. nLine <= ::rowCurrCount
      // NEW
      IF ! ::ChangeRowCol( iif( nLine = ::rowPos .AND. ::colpos == fif, 0, iif( ;
            nLine != ::rowPos .AND. ::colpos != fif , 3, iif( nLine != ::rowPos, 1, 2 ) ) ) )
         RETURN .F.
      ENDIF

      IF STEP != 0
         Eval( ::bSkip, Self, STEP )
         ::rowPos := nLine
         IF ::bScrollPos != NIL
            Eval( ::bScrollPos, Self, STEP, .F. )
         ELSEIF ::nRecords > 1
            hwg_VScrollPosEx( Self, 0, .F. )
         ENDIF
         res := .T.

      ENDIF
      IF lEditable .OR. ::lAutoEdit
         IF ::colpos != fif - ::nLeftCol + 1 + ::freeze
            // Colpos should not go beyond last column or I get bound errors on ::Edit()
            ::colpos := Min( ::nColumns + 1, fif - ::nLeftCol + 1 + ::freeze )
            hwg_VScrollPosEx( Self, 0, .F. )
            res := .T.
         ENDIF
      ENDIF
      IF res
         ::internal[ 1 ] := 15   // Force FOOTER
         hwg_Invalidaterect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] - ::height, ::xAdjRight, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] )
         hwg_Invalidaterect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::xAdjRight , ::y1 + ( ::height + 1 ) * ::rowPos )
      ENDIF
      ::fipos := Min( ::colpos + ::nLeftCol - 1 - ::freeze, Len( ::aColumns ) )
      IF ::aColumns[ ::fipos ]:Type = "L"
         ::EditLogical( WM_LBUTTONDOWN )
      ENDIF

   ELSEIF nLine == 0
      IF hwg_Ptrtoulong( oCursor ) ==  hwg_Ptrtoulong( ColSizeCursor )
         ::lResizing := .T.
         ::isMouseOver := .F.
         Hwg_SetCursor( oCursor )
         xDrag := hwg_Loword( lParam )
         xDragMove := xDrag
         hwg_Invalidaterect( ::handle, 0 )
      ELSEIF ::lDispHead .AND.  nLine >= - ::nHeadRows .AND. ;
            fif <= Len( ::aColumns ) //.AND. ;
         ::aColumns[ fif ]:lHeadClick := .T.
         hwg_Invalidaterect( ::handle, 0, ::x1, ::y1 - ::nHeadHeight * ::nHeadRows, ::x2, ::y1 )
         IF ::aColumns[ fif ]:bHeadClick != NIL
            ::isMouseOver := .F.
            //::oParent:lSuspendMsgsHandling := .T.
            Eval( ::aColumns[ fif ]:bHeadClick, ::aColumns[ fif ], fif, Self )
            //::oParent:lSuspendMsgsHandling := .F.
         ENDIF
         ::lHeadClick := .T.
      ENDIF
   ENDIF
   IF ( hwg_Ptrtoulong( hwg_Getactivewindow() ) = hwg_Ptrtoulong( hwg_GetParentForm(Self ):Handle )  .OR. ;
         hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE )
      ::Setfocus()
      ::RefreshLine()
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD ButtonUp( lParam ) CLASS HBrowseEx

   LOCAL xPos := hwg_Loword( lParam ), x, x1, i

   IF ::lResizing
      x1 := 0
      x := ::x1
      i := iif( ::freeze > 0, 1, ::nLeftCol )
      DO WHILE x < xDrag
         IF !::aColumns[ i ]:lHide
            x += ::aColumns[ i ]:width
            IF Abs( x - xDrag ) < 10 .AND. ::aColumns[ i ]:Resizable
               x1 := x - ::aColumns[ i ]:width
               EXIT
            ENDIF
            i := iif( i == ::freeze, ::nLeftCol, i + 1 )
         ENDIF
      ENDDO
      IF xPos > x1
         ::aColumns[ i ]:width := xPos - x1
         Hwg_SetCursor( arrowCursor )
         oCursor := 0
         ::isMouseOver := .F.
         //xDragMove := 0
         hwg_Invalidaterect( ::handle, 0 )
         ::lResizing := .F.
      ENDIF
   ELSEIF ::aSelected != NIL
      IF ::lCtrlPress
         ::Select()
         ::refreshline()
      ELSE
         IF Len( ::aSelected ) > 0
            ::aSelected := { }
            ::Refresh()
         ENDIF
      ENDIF
   ENDIF
   IF ::lHeadClick
      AEval( ::aColumns, { | c | c:lHeadClick := .F. } )
      hwg_Invalidaterect( ::handle, 0, ::x1, ::y1 - ::nHeadHeight * ::nHeadRows, ::x2, ::y1 )
      ::lHeadClick := .F.
      Hwg_SetCursor( downCursor )
   ENDIF

   RETURN NIL

METHOD SELECT() CLASS HBrowseEx
   LOCAL i

   IF ( i := AScan( ::aSelected, Eval( ::bRecno, Self ) ) ) > 0
      ADel( ::aSelected, i )
      ASize( ::aSelected, Len( ::aSelected ) - 1 )
   ELSE
      AAdd( ::aSelected, Eval( ::bRecno, Self ) )
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD ButtonRDown( lParam ) CLASS HBrowseEx
   LOCAL nLine
   LOCAL xm, x1, fif
   LOCAL acolumns := {}, nCols := 1, xSize := 0

   // Calculate the line you clicked on, keeping track of header
   IF ( ::lDispHead )
      nLine := Int( ( hwg_Hiword( lParam ) - ( ::nHeadHeight * ::nHeadRows ) ) / ( ::height + 1 ) + 1 )
   ELSE
      nLine := Int( hwg_Hiword( lParam ) / ( ::height + 1 ) + 1 )
   ENDIF
   xm := hwg_Loword( lParam )
   x1 := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )
   DO WHILE nCols <= Len( ::aColumns )
      xSize := ::aColumns[ ncols ]:width
      IF ( ::lAdjRight .AND. nCols == Len( ::aColumns ) )
         xSize := Max( ::x2 - x1, xSize )
      ENDIF
      IF !::aColumns[ nCols ]:lhide
         AAdd( aColumns, { xSize, ncols } )
         x1 += xSize
         xSize := 0
      ENDIF
      nCols ++
   ENDDO
   x1  := ::x1
   aColumns[ Len( aColumns ) , 1] += xSize
   DO WHILE fif <= Len( aColumns )
      IF ( ! ( fif < ( ::nLeftCol + ::nColumns ) .AND. x1 + aColumns[ fif,1 ] < xm ) )
         EXIT
      ENDIF
      x1 += aColumns[ fif,1 ]
      fif := iif( fif == ::freeze, ::nLeftCol, fif + 1 )
   ENDDO
   IF fif > Len( aColumns )
      IF ! ::lAdjRight     // no column select
         RETURN NIL
      ENDIF
      fif --
   ENDIF
   fif := aColumns[ fif, 2 ]
   IF nLine > 0 .AND. nLine <= ::rowCurrCount
      IF ::bRClick != NIL
         Eval( ::bRClick, Self, nLine, fif )
      ENDIF
   ELSEIF nLine == 0
      IF ::lDispHead .AND. ;
            nLine >=  - ::nHeadRows .AND. fif <= Len( ::aColumns )
         IF ::aColumns[ fif ]:bHeadRClick != NIL
            Eval( ::aColumns[ fif ]:bHeadRClick, Self, nLine, fif  )
         ENDIF
      ENDIF
   ENDIF

   RETURN NIL

METHOD ButtonDbl( lParam ) CLASS HBrowseEx
   LOCAL nLine := Int( iif( ::lDispHead , ( ( hwg_Hiword( lParam ) - ( ::nHeadHeight * ::nHeadRows ) ) / ( ::height + 1 ) + 1 )  ,;
      hwg_Hiword( lParam ) / ( ::height + 1 ) + 1  ) )

   IF nLine > 0 .AND. nLine <= ::rowCurrCount
      ::ButtonDown( lParam )
      ::Edit()
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD MouseMove( wParam, lParam ) CLASS HBrowseEx
   LOCAL xPos := hwg_Loword( lParam ), yPos := hwg_Hiword( lParam )
   LOCAL x := ::x1, i, res := .F.
   LOCAL nLastColumn 
   LOCAL currxPos := ::xPosMouseOver

   wParam := hwg_PtrToUlong( wParam )
   ::xPosMouseOver := 0
   ::isMouseOver := iif( ::lDispHead .AND. ::hTheme != NIL .AND. currxPos != 0, .T. , .F. )
   nLastColumn := Len( ::aColumns ) // iif( ::lAdjRight, Len( ::aColumns ) - 1, Len( ::aColumns ) )

   IF ! ::active .OR. Empty( ::aColumns ) .OR. ::x1 == NIL .OR. !Empty( ::oEditDlg )
      RETURN NIL
   ENDIF
   IF ::isMouseOver
      hwg_Invalidaterect( ::handle, 0, axPosMouseOver[ 1 ], ::y1 - ::nHeadHeight * ::nHeadRows, axPosMouseOver[ 2 ] , ::y1 )
   ENDIF
   IF ::lDispHead .AND. ( yPos <= ::nHeadHeight * ::nHeadRows + 1 .OR. ; // ::height*::nHeadRows+1
      ( ::lResizing .AND. yPos > ::y1 ) ) .AND. ;
         ( xPos >= ::x1 .AND. xPos <= Max( xDragMove, ::xAdjRight ) + 4 )
      IF wParam == MK_LBUTTON .AND. ::lResizing
         Hwg_SetCursor( oCursor )
         res := .T.
         xDragMove := xPos
         ::isMouseOver := .T.
         hwg_Invalidaterect( ::handle, 0, xPos - 18 , ::y1 - ( ::nHeadHeight * ::nHeadRows ), xPos + 18 , ::y2 - ( ::nFootHeight * ::nFootRows ) - 1 )
      ELSE
         i := iif( ::freeze > 0, 1, ::nLeftCol )
         DO WHILE x < ::x2 - 2 .AND. i <= nLastColumn     // Len( ::aColumns )
            IF !::aColumns[ i ]:lhide
               x += ::aColumns[ i ]:width
               ::xPosMouseOver := xPos
               IF Abs( x - xPos ) < 8
                  IF hwg_Ptrtoulong( oCursor ) != hwg_Ptrtoulong( ColSizeCursor )
                     oCursor := ColSizeCursor
                  ENDIF
                  Hwg_SetCursor( oCursor )
                  res := .T.
                  EXIT
               ELSE
                  oCursor := DownCursor
                  Hwg_SetCursor( oCursor )
                  res := .T.
               ENDIF
            ENDIF
            i := iif( i == ::freeze, ::nLeftCol, i + 1 )
         ENDDO
      ENDIF
      IF ! res .AND. ! Empty( oCursor )
         Hwg_SetCursor( arrowCursor )
         oCursor := 0
         ::lResizing := .F.
      ENDIF
      ::isMouseOver := iif( ::hTheme != NIL .AND. ::xPosMouseOver != 0, .T. , .F. )
   ENDIF
   IF ::isMouseOver
      hwg_Invalidaterect( ::handle, 0, ::xPosMouseOver - 1, ::y1 - ::nHeadHeight * ::nHeadRows, ::xPosMouseOver + 1, ::y1 )
   ENDIF

   RETURN NIL

   //----------------------------------------------------------------------------//

METHOD MouseWheel( nKeys, nDelta, nXPos, nYPos ) CLASS HBrowseEx

   HB_SYMBOL_UNUSED( nXPos )
   HB_SYMBOL_UNUSED( nYPos )

   IF Hwg_BitAnd( nKeys, MK_MBUTTON ) != 0
      IF nDelta > 0
         ::PageUp()
      ELSE
         ::PageDown()
      ENDIF
   ELSE
      IF nDelta > 0
         ::LineUp()
      ELSE
         ::LineDown( .T. )
      ENDIF
   ENDIF

   RETURN NIL

METHOD onClick( ) CLASS HBrowseEx
   LOCAL  lRes := .F.

   IF ::bEnter != NIL
      //::oParent:lSuspendMsgsHandling := .T.
      lRes := Eval( ::bEnter, Self, ::fipos )
      //::oParent:lSuspendMsgsHandling := .F.
      IF ValType( lRes ) != "L"
         RETURN .T.
      ENDIF
   ENDIF

   RETURN lRes

   //----------------------------------------------------//

METHOD Edit( wParam, lParam ) CLASS HBrowseEx
   LOCAL fipos, x1, y1, fif, nWidth, lReadExit, rowPos
   LOCAL oColumn, aCoors, nChoic, bInit, oGet, Type
   LOCAL oComboFont, oCombo, oBtn
   LOCAL oGet1, owb1, owb2 , nHget

   fipos := Min( ::colpos + ::nLeftCol - 1 - ::freeze, Len( ::aColumns ) )
   ::fiPos := fipos

   IF ( ! Eval( ::bEof, Self ) .OR. ::lAppMode ) .AND. ( ! ::onClick( )  ) .AND. Empty(::oEditDlg)
      oColumn := ::aColumns[ fipos ]
      IF ::Type == BRW_DATABASE
         ::varbuf := ( ::Alias ) -> ( Eval( oColumn:block,, Self, fipos ) )
      ELSE
         IF ::nRecords  = 0 .AND. ::lAppMode
            AAdd( ::aArray, Array( Len( ::aColumns ) ) )
            FOR fif := 1 TO Len( ::aColumns )
               ::aArray[ 1, fif ] := ;
                  iif( ::aColumns[ fif ]:Type == "D", CToD( Space( 8 ) ), ;
                  iif( ::aColumns[ fif ]:Type == "N", 0, iif( ::aColumns[ fif ]:Type == "L", .F. , "" ) ) )
            NEXT
            ::lAppMode := .F.
            ::Refresh( ::nFootRows > 0 )
         ENDIF
         ::varbuf := Eval( oColumn:block, , Self, fipos )
      ENDIF
      Type := iif( oColumn:Type == "U" .AND. ::varbuf != NIL, ValType( ::varbuf ), oColumn:Type )
      IF ::lEditable .AND. Type != "O" .AND. ( oColumn:aList != NIL .OR.  ( oColumn:aList = NIL .AND. wParam != 13 ) )
         IF oColumn:lEditable
            IF ::lAppMode
               IF Type == "D"
                  ::varbuf := CToD( "" )
               ELSEIF Type == "N"
                  ::varbuf := 0
               ELSEIF Type == "L"
                  ::varbuf := .F.
               ELSE
                  ::varbuf := ""
               ENDIF
            ENDIF
         ELSE
            RETURN NIL
         ENDIF
         x1  := ::x1
         fif := iif( ::freeze > 0, 1, ::nLeftCol )
         DO WHILE fif < fipos
            IF !::aColumns[ fif ]:lhide
               x1 += ::aColumns[ fif ]:width
            ENDIF
            fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
         ENDDO
         nWidth := Min( ::aColumns[ fif ]:width, ::x2 - x1 - 1 )
         IF fif =  Len( ::aColumns )
            nWidth := Min( ::nWidthColRight, ::x2 - x1 - 1 )
         ENDIF
         rowPos := ::rowPos - 1
         IF ::lAppMode .AND. ::nRecords != 0 .AND. ::rowPos != ::rowCount
            rowPos ++
         ENDIF
         y1 := ::y1 + ( ::height + 1 ) * rowPos

         aCoors := hwg_Clienttoscreen( ::handle, x1, y1 )
         x1 := aCoors[ 1 ]
         y1 := aCoors[ 2 ] + 1
         lReadExit := Set( _SET_EXIT, .T. )
         IF Type <> "L"
            bInit := iif( wParam == NIL .OR. wParam = 13 .OR. Empty( lParam ), { | o | hwg_Movewindow( o:handle, x1, y1, nWidth, o:nHeight + 1 ) }, ;
               { | o | hwg_Movewindow( o:handle, x1, y1, nWidth, o:nHeight + 1 ), ;
               o:aControls[ 1 ]:Setfocus(), hwg_Postmessage( o:aControls[ 1 ]:handle, WM_CHAR, wParam, lParam ) } )
            IF Type <> "M"
               /* Bug Ticket #108 by Itamer M. Lins Jr,
                  WINE ESC and ENTER not working on get (edit) browse:
                  + DS_CONTROL removed */
               INIT DIALOG ::oEditDlg ;
                  STYLE WS_POPUP + 1 + iif( oColumn:aList == NIL, WS_BORDER, 0 )  ;
                  At x1, y1 - iif( oColumn:aList == NIL, 1, 0 ) ;
                  SIZE nWidth - 1, ::height + iif( oColumn:aList == NIL, 1, 0 ) ;
                  ON INIT bInit ;
                  ON OTHER MESSAGES { | o, m, w, l | ::EditEvent( o, m, w, l ) }
            ELSE
               INIT DIALOG ::oEditDlg title "memo edit" At 0, 0 SIZE 400, 300 ON INIT { | o | o:center() }
            ENDIF
            IF oColumn:aList != NIL  .AND. ( oColumn:bWhen = NIL .OR. Eval( oColumn:bWhen ) )
               ::oEditDlg:brush := - 1
               ::oEditDlg:nHeight := ::height + 1 // * 5
               IF ValType( ::varbuf ) == 'N'
                  nChoic := ::varbuf
               ELSE
                  ::varbuf := AllTrim( ::varbuf )
                  nChoic := AScan( oColumn:aList, ::varbuf )
               ENDIF
               oComboFont := iif( ValType( ::oFont ) == "U", ;
                  HFont():Add( "MS Sans Serif", 0, - 8 ), ;
                  HFont():Add( ::oFont:name, ::oFont:width, ::oFont:height + 2 ) )
               @ 0, 0 GET COMBOBOX oCombo VAR nChoic ;
                  ITEMS oColumn:aList            ;
                  SIZE nWidth, ::height + 1      ;
                  FONT oComboFont  ;
                  DISPLAYCOUNT  iif( Len( oColumn:aList ) > ::rowCount , ::rowCount - 1, Len( oColumn:aList ) ) ;
                  VALID { || ::ValidColumn( nChoic, oCombo ) };
                  WHEN { || ::WhenColumn( nChoic, oCombo ) }

               ::oEditDlg:AddEvent( 0, IDOK, { || ::oEditDlg:lResult := .T. , ::oEditDlg:close() } )
            ELSE
               IF Type == "L"
                  ::oEditDlg:lResult := .T.
               ELSEIF Type <> "M"
                  nHGet := Max( ( ::height - ( hwg_TxtRect( "N", self ) )[ 2 ] ) / 2 , 0 )
                  @ 0, nHGet GET oGet VAR ::varbuf       ;
                     SIZE nWidth - iif( oColumn:bClick != NIL, 16, 1 ) , ::height   ;
                     NOBORDER                       ;
                     STYLE ES_AUTOHSCROLL           ;
                     FONT ::oFont                   ;
                     PICTURE iif( Empty( oColumn:picture ), NIL, oColumn:picture )   ;
                     VALID { | oColumn, oGet | ::ValidColumn( oColumn, oGet, oBtn ) };
                     WHEN { | oColumn, oGet | ::WhenColumn( oColumn, oGet, oBtn ) }
                  IF oColumn:bClick != NIL
                     IF Type != "D"
                        @ nWidth - 15, 0  OWNERBUTTON oBtn  SIZE 16, ::height - 0 ;
                           TEXT '...'  FONT HFont():Add( 'MS Sans Serif', 0, - 10, 400, , , ) ;
                           COORDINATES 0, 1, 0, 0      ;
                           ON CLICK { | oColumn, oBtn | HB_SYMBOL_UNUSED( oColumn ), ::onClickColumn( .T. , oGet, oBtn ) }
                        oBtn:themed :=  ::hTheme != NIL
                     ELSE
                        @ nWidth - 16, 0 DATEPICKER oBtn SIZE 16, ::height - 1  ;
                           ON CHANGE { | value, oBtn |  ::onClickColumn( value, oGet, oBtn ) }
                     ENDIF
                  ENDIF
                  IF ! Empty( wParam )  .AND. wParam != 13 .AND. !Empty( lParam )
                     hwg_Sendmessage( oGet:handle, WM_CHAR,  wParam, lParam  )
                  ENDIF
               ELSE
                  oGet1 := ::varbuf
                  @ 10, 10 GET oGet1 SIZE ::oEditDlg:nWidth - 20, 240 FONT ::oFont Style WS_VSCROLL + WS_HSCROLL + ES_MULTILINE VALID oColumn:bValid
                  @ 010, 252 ownerbutton owb2 TEXT "Save" size 80, 24 ON Click { || ::varbuf := oGet1, ::oEditDlg:close(), ::oEditDlg:lResult := .T. }
                  @ 100, 252 ownerbutton owb1 TEXT "Close" size 80, 24 ON CLICK { || ::oEditDlg:close() }
               ENDIF
            ENDIF
            IF Type != "L" .AND. ::nSetRefresh > 0
               ::oTimer:Interval := 0
            ENDIF

            ACTIVATE DIALOG ::oEditDlg

         ELSE // .AND. wParam != VK_RETURN
            Hwg_SetCursor( arrowCursor )
            IF wParam = VK_SPACE
               ::EditLogical( wParam )
            ENDIF
            RETURN NIL
         ENDIF

         IF oColumn:aList != NIL
            oComboFont:Release()
         ENDIF

         IF ::oEditDlg:lResult
            IF oColumn:aList != NIL
               IF ValType( ::varbuf ) == 'N'
                  ::varbuf := nChoic
               ELSE
                  ::varbuf := oColumn:aList[ nChoic ]
               ENDIF
            ENDIF
            IF ::lAppMode
               ::lAppMode := .F.
               IF ::Type == BRW_DATABASE
                  ( ::Alias ) -> ( dbAppend() )
                  ( ::Alias ) -> ( Eval( oColumn:block, ::varbuf, Self, fipos ) )
                  ( ::Alias ) -> ( dbUnlock() )
               ELSE
                  IF ValType( ::aArray[ 1 ] ) == "A"
                     AAdd( ::aArray, Array( Len( ::aArray[ 1 ] ) ) )
                     FOR fif := 2 TO Len( ( ::aArray[ 1 ] ) )
                        ::aArray[ Len( ::aArray ), fif ] := ;
                           iif( ::aColumns[ fif ]:Type == "D", CToD( Space( 8 ) ), ;
                           iif( ::aColumns[ fif ]:Type == "N", 0, "" ) )
                     NEXT
                  ELSE
                     AAdd( ::aArray, NIL )
                  ENDIF
                  ::nCurrent := Len( ::aArray )
                  Eval( oColumn:block, ::varbuf, Self, fipos )
               ENDIF
               IF ::nRecords > 0
                  ::rowPos ++
               ENDIF
               ::lAppended := .T.
               IF ! ( hwg_Getkeystate( VK_UP ) < 0 .OR. hwg_Getkeystate( VK_DOWN ) < 0 )
                  ::DoHScroll( SB_LINERIGHT )
               ENDIF
               ::Refresh( ::nFootRows > 0 )
            ELSE
               IF ::Type == BRW_DATABASE
                  IF ( ::Alias ) -> ( RLock() )
                     ( ::Alias ) -> ( Eval( oColumn:block, ::varbuf, Self, fipos ) )
                     ( ::Alias ) -> ( dbUnlock() )
                  ELSE
                     hwg_Msgstop( "Can't lock the record!" )
                  ENDIF
               ELSE
                  Eval( oColumn:block, ::varbuf, Self, fipos )
               ENDIF
               IF ! ( hwg_Getkeystate( VK_UP ) < 0 .OR. hwg_Getkeystate( VK_DOWN ) < 0 .OR. hwg_Getkeystate( VK_SPACE ) < 0 ) .AND. Type != "L"
                  ::DoHScroll( SB_LINERIGHT )
               ENDIF
               ::lUpdated := .T.
               hwg_Invalidaterect( ::handle, 0, ::x1, ::y1 + ( ::height + 1 ) * ( ::rowPos - 2 ), ::x2, ::y1 + ( ::height + 1 ) * ::rowPos )
               ::RefreshLine()
            ENDIF

            /* Execute block after changes are made */
            IF ::bUpdate != NIL
               Eval( ::bUpdate,  Self, fipos )
            END

         ELSEIF ::lAppMode
            ::lAppMode := .F.
            IF ::Type == BRW_DATABASE .AND. Eval( ::bEof, Self )
               Eval( ::bSkip, Self, - 1 )
            ENDIF
            IF ::rowPos < ::rowCount
               hwg_Invalidaterect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::rowPos, ::x2, ::y1 + ( ::height + 1 ) * ( ::rowPos + 1 ) )
            ELSE
               ::Refresh()
            ENDIF
         ENDIF
         ::Setfocus()
         SET( _SET_EXIT, lReadExit )

         IF ::nSetRefresh > 0
            ::oTimer:Interval := ::nSetRefresh
         ENDIF
         ::oEditDlg := Nil

      ELSEIF ::lEditable
         ::DoHScroll( SB_LINERIGHT )
      ENDIF
   ENDIF

   RETURN NIL

METHOD EditLogical( wParam, lParam ) CLASS HBrowseEx

   HB_SYMBOL_UNUSED( lParam )

   wParam := hwg_PtrToUlong( wParam )
   IF ! ::aColumns[ ::fipos ]:lEditable
      RETURN .F.
   ENDIF
   IF ::aColumns[ ::fipos ]:bWhen != NIL
      //::oparent:lSuspendMsgsHandling := .T.
      ::varbuf := Eval( ::aColumns[ ::fipos ]:bWhen, ::aColumns[ ::fipos ], ::varbuf )
      //::oparent:lSuspendMsgsHandling := .F.
      IF ! ( ValType( ::varbuf ) == "L" .AND. ::varbuf )
         RETURN .F.
      ENDIF
   ENDIF
   IF ::Type == BRW_DATABASE
      IF wParam != VK_SPACE
         ::varbuf := ( ::Alias ) -> ( Eval( ::aColumns[ ::fipos ]:block,, Self, ::fipos ) )
      ENDIF
      IF ( ::Alias ) -> ( RLock() )
         ( ::Alias ) -> ( Eval( ::aColumns[ ::fipos ]:block, ! ::varbuf, Self, ::fipos ) )
         ( ::Alias ) -> ( dbUnlock() )
      ELSE
         hwg_Msgstop( "Can't lock the record!" )
      ENDIF
   ELSEIF ::nRecords  > 0
      IF wParam != VK_SPACE
         ::varbuf :=  Eval( ::aColumns[ ::fipos ]:block, , Self, ::fipos )
      ENDIF
      Eval( ::aColumns[ ::fipos ]:block, ! ::varbuf, Self, ::fipos )
   ENDIF

   ::lUpdated := .T.
   ::RefreshLine()
   IF ::aColumns[ ::fipos ]:bValid != NIL
      //::oparent:lSuspendMsgsHandling := .T.
      Eval( ::aColumns[ ::fipos ]:bValid, ! ::varbuf, ::aColumns[ ::fipos ] ) //, ::varbuf )
      //::oparent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN .T.

METHOD EditEvent( oCtrl, msg, wParam, lParam )

   HB_SYMBOL_UNUSED( lParam )

   wParam := hwg_PtrToUlong( wParam )
   IF ( msg = WM_KEYDOWN .AND. ( wParam = VK_RETURN  .OR. wParam = VK_TAB ) )
      RETURN - 1
   ELSEIF ( msg = WM_KEYDOWN .AND. wParam = VK_ESCAPE )
      oCtrl:oParent:lResult := .F.
      oCtrl:oParent:Close()
      RETURN 0
   ENDIF

   RETURN - 1

METHOD onClickColumn( value, oGet, oBtn ) CLASS HBrowseEx
   LOCAL oColumn := ::aColumns[ ::fipos ]

   IF ValType( value ) = "D"
      ::varbuf := value
      oGet:refresh()
      hwg_Postmessage( oBtn:handle, WM_KEYDOWN, VK_TAB, 0 )
   ENDIF
   IF oColumn:bClick != NIL
      //::oparent:lSuspendMsgsHandling := .T.
      Eval( oColumn:bClick, value, oGet, oColumn, Self )
      //::oparent:lSuspendMsgsHandling := .F.
   ENDIF
   oGet:Setfocus()

   RETURN NIL

METHOD WhenColumn( value, oGet ) CLASS HBrowseEx
   LOCAL res := .T.
   LOCAL oColumn := ::aColumns[ ::fipos ]

   IF oColumn:bWhen != NIL
      //::oparent:lSuspendMsgsHandling := .T.
      res := Eval( oColumn:bWhen, Value, oGet )
      res := iif( ValType( res ) = "L" , res, .T. )
      IF ValType( res ) = "L" .AND. ! res
         ::Setfocus()
         oGet:oParent:close()
      ENDIF
      //::oparent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN res

METHOD ValidColumn( value, oGet, oBtn ) CLASS HBrowseEx
   LOCAL res := .T.
   LOCAL oColumn := ::aColumns[ ::fipos ]

   /*
   IF !hwg_CheckFocus( oGet, .T. )
      RETURN .T.
   ENDIF
   */
   IF oBtn != NIL .AND. hwg_Getfocus() = oBtn:handle
      RETURN .T.
   ENDIF
   IF oColumn:bValid != NIL
      //::oparent:lSuspendMsgsHandling := .T.
      res := Eval( oColumn:bValid, value, oGet )
      IF ValType( res ) = "L" .AND. ! res
         oGet:Setfocus()
         hwg_Setfocus( Nil )
      ENDIF
      //::oparent:lSuspendMsgsHandling := .F.
   ENDIF
   IF res
      oGet:oParent:close()
      oGet:oParent:lResult := .T.
   ENDIF

   RETURN res

METHOD ChangeRowCol( nRowColChange ) CLASS HBrowseEx

   // 0 (default) No change.
   // 1 Row change
   // 2 Column change
   // 3 Row and column change
   LOCAL res := .T.
   //LOCAL lSuspendMsgsHandling := ::oParent:lSuspendMsgsHandling

   IF ::bChangeRowCol != NIL //.AND.  !::oParent:lSuspendMsgsHandling
      //::oParent:lSuspendMsgsHandling := .T.
      res :=  Eval( ::bChangeRowCol, nRowColChange, Self, ::SetColumn() )
      //::oParent:lSuspendMsgsHandling := lSuspendMsgsHandling
   ENDIF
   IF nRowColChange > 0
      //::lSuspendMsgsHandling := .F.
   ENDIF

   RETURN ! Empty( res )

METHOD When() CLASS HBrowseEx
   LOCAL nSkip, res := .T.

   /*
   IF !hwg_CheckFocus( self, .F. )
      RETURN .F.
   ENDIF
   */
   IF ::HighlightStyle = 0 .OR. ::HighlightStyle = 3
      ::RefreshLine()
   ENDIF

   IF ::bGetFocus != NIL
      nSkip := iif( hwg_Getkeystate( VK_UP ) < 0 .OR. ( hwg_Getkeystate( VK_TAB ) < 0 .AND. hwg_Getkeystate(VK_SHIFT ) < 0 ), - 1, 1 )
      res := Eval( ::bGetFocus, ::Colpos, Self )
      res := iif( ValType( res ) = "L", res, .T. )
   ENDIF
   // Suppress warning: nSkip is kept for future reactivation of hwg_WhenSetFocus
   HB_SYMBOL_UNUSED( nSkip )
   RETURN res

METHOD Valid() CLASS HBrowseEx
   LOCAL res

   IF ::HighlightStyle = 0 .OR. ::HighlightStyle = 3
      ::RefreshLine()
   ENDIF
   IF ::bLostFocus != NIL
      res := Eval( ::bLostFocus, ::ColPos, Self )
      res := iif( ValType( res ) = "L", res, .T. )
      IF ValType( res ) = "L" .AND. ! res
         ::Setfocus( .T. )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.

   //----------------------------------------------------//

METHOD RefreshLine() CLASS HBrowseEx
   LOCAL nInternal := ::internal[ 1 ]

   ::internal[ 1 ] := 0
   hwg_Invalidaterect( ::handle, 0, ::x1 - ::nDeleteMark , ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::rowPos )
   ::internal[ 1 ] := nInternal

   RETURN NIL

   //----------------------------------------------------//

METHOD Refresh( lFull, lLineUp ) CLASS HBrowseEx

   IF lFull == NIL .OR. lFull
      IF ::lFilter
         ::nLastRecordFilter := 0
         ::nFirstRecordFilter := 0
      ENDIF
      ::internal[ 1 ] := 15
      IF ::nCurrent < ::rowCount .AND. ::rowPos <= ::nCurrent .AND. Empty( lLineUp )
         ::rowPos := ::nCurrent
      ENDIF
   ELSE
      hwg_Invalidaterect( ::handle, 0 )
      ::internal[ 1 ] := hwg_SetBit( ::internal[ 1 ], 1, 0 )
      IF ::nCurrent < ::rowCount .AND. ::rowPos <= ::nCurrent .AND. Empty( lLineUp )
         ::rowPos := ::nCurrent
      ENDIF
   ENDIF
   IF hwg_Iswindowvisible( ::oParent:handle )
      hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW )  // Force a complete redraw
   ELSE
      hwg_Redrawwindow( ::handle, RDW_NOERASE + RDW_NOINTERNALPAINT )
   ENDIF

   RETURN NIL

   //----------------------------------------------------//

METHOD FldStr( oBrw, numf ) CLASS HBrowseEx
   LOCAL cRes, vartmp, Type, pict

   IF numf <= Len( oBrw:aColumns )
      pict := oBrw:aColumns[ numf ]:picture
      IF pict != NIL
         IF oBrw:Type == BRW_DATABASE
            IF oBrw:aRelation
               cRes := ( oBrw:aColAlias[ numf ] ) -> ( Transform( Eval( oBrw:aColumns[ numf ]:block,, oBrw, numf ), pict ) )
            ELSE
               cRes := ( oBrw:Alias ) -> ( Transform( Eval( oBrw:aColumns[ numf ]:block,, oBrw, numf ), pict ) )
            ENDIF
         ELSE
            oBrw:nCurrent := iif( oBrw:nCurrent = 0, 1, oBrw:nCurrent )
            vartmp :=  Eval( oBrw:aColumns[ numf ]:block, , oBrw, numf )
            cRes := iif( vartmp != NIL, Transform( vartmp, pict ), Space( oBrw:aColumns[ numf ]:length ) )
         ENDIF
      ELSE
         IF oBrw:Type == BRW_DATABASE
            IF oBrw:aRelation
               vartmp := ( oBrw:aColAlias[ numf ] ) -> ( Eval( oBrw:aColumns[ numf ]:block,, oBrw, numf ) )
            ELSE
               vartmp := ( oBrw:Alias ) -> ( Eval( oBrw:aColumns[ numf ]:block,, oBrw, numf ) )
            ENDIF
         ELSE
            oBrw:nCurrent := iif( oBrw:nCurrent = 0, 1, oBrw:nCurrent )
            vartmp := Eval( oBrw:aColumns[ numf ]:block, , oBrw, numf )
         ENDIF

         Type := ( oBrw:aColumns[ numf ] ):Type
         IF Type == "U" .AND. vartmp != NIL
            Type := ValType( vartmp )
         ENDIF
         IF Type == "C"
            cRes := vartmp
         ELSEIF Type == "N"
            IF oBrw:aColumns[ numf ]:aList != NIL .AND. ( oBrw:aColumns[ numf ]:bWhen = NIL .OR. Eval( oBrw:aColumns[ numf ]:bWhen ) )
               IF vartmp == 0
                  cRes := ""
               ELSE
                  cRes := oBrw:aColumns[ numf ]:aList[vartmp]
               ENDIF
            ELSE
               cRes := PadL( Str( vartmp, oBrw:aColumns[ numf ]:length, ;
                  oBrw:aColumns[ numf ]:dec ), oBrw:aColumns[ numf ]:length )
            ENDIF
         ELSEIF Type == "D"
            cRes := PadR( Dtoc( vartmp ), oBrw:aColumns[ numf ]:length )
         ELSEIF Type == "L"
            cRes := PadR( iif( vartmp, "T", "F" ), oBrw:aColumns[ numf ]:length )
         ELSEIF Type == "M"
            cRes := iif( Empty( vartmp ), "<memo>", "<MEMO>" )
         ELSEIF Type == "O"
            cRes := "<" + vartmp:Classname() + ">"
         ELSEIF Type == "A"
            cRes := "<Array>"
         ELSE
            cRes := Space( oBrw:aColumns[ numf ]:length )
         ENDIF
      ENDIF
   ENDIF

   RETURN cRes

METHOD ShowSizes() CLASS HBrowseEx
   LOCAL cText := ""

   AEval( ::aColumns, ;
      { | v, e | HB_SYMBOL_UNUSED( v ), cText += ::aColumns[ e ]:heading + ": " + Str( Round( ::aColumns[ e ]:width / 8, 0 ) - 2  ) + Chr( 10 ) + Chr( 13 ) } )
   hwg_Msginfo( cText )

   RETURN NIL

   //----------------------------------------------------//

STATIC FUNCTION FLDCOUNT( oBrw, xstrt, xend, fld1 )
   LOCAL klf := 0, i := iif( oBrw:freeze > 0, 1, fld1 )

   DO WHILE .T.
      xstrt += oBrw:aColumns[ i ]:width
      IF xstrt > xend
         EXIT
      ENDIF
      klf ++
      i   := iif( i = oBrw:freeze, fld1, i + 1 )
      IF i > Len( oBrw:aColumns )
         EXIT
      ENDIF
   ENDDO

   RETURN iif( klf = 0, 1, klf )

FUNCTION hwg_VScrollPosEx( oBrw, nType, lEof, nPos )

   LOCAL minPos, maxPos, oldRecno, newRecno, nrecno

   IF oBrw:lNoVScroll
      RETURN NIL
   ENDIF
   hwg_Getscrollrange( oBrw:handle, SB_VERT, @minPos, @maxPos )
   IF nPos == NIL
      IF oBrw:Type <> BRW_DATABASE
         IF nType > 0 .AND. lEof
            Eval( oBrw:bSkip, oBrw, - 1 )
         ENDIF
         nPos := iif( oBrw:nRecords > 1, Round( ( ( maxPos - minPos + 1 ) / ( oBrw:nRecords - 1 ) ) * ;
            ( Eval( oBrw:bRecnoLog, oBrw ) - 1 ), 0 ), minPos )
         hwg_Setscrollpos( oBrw:handle, SB_VERT, nPos )
      ELSEIF ! Empty( oBrw:Alias )
         nrecno := ( oBrw:Alias ) -> ( RecNo() )
         Eval( oBrw:bGotop, oBrw )
         minPos := iif( ( oBrw:Alias ) -> ( IndexOrd() ) = 0, ( oBrw:Alias ) -> ( RecNo() ), ( oBrw:Alias ) -> ( ordkeyno() ) )
         Eval( oBrw:bGobot, oBrw )
         maxPos := iif( ( oBrw:Alias ) -> ( IndexOrd() ) = 0, ( oBrw:Alias ) -> ( RecNo() ), ( oBrw:Alias ) -> ( ordkeyno() ) )
         IF minPos != maxPos
            hwg_Setscrollrange( oBrw:handle, SB_VERT, minPos, maxPos )
         ENDIF
         ( oBrw:Alias ) -> ( dbGoto( nrecno ) )
         hwg_Setscrollpos( oBrw:handle, SB_VERT, iif( ( oBrw:Alias ) -> ( IndexOrd() ) = 0, ( oBrw:Alias ) -> ( RecNo() ), ;
            iif(  oBrw:lDisableVScrollPos, oBrw:nRecCount / 2, ( oBrw:Alias ) -> ( ordkeyno() ) ) ) )
      ENDIF
   ELSE
      oldRecno := Eval( oBrw:bRecnoLog, oBrw )
      newRecno := Round( ( oBrw:nRecords - 1 ) * nPos / ( maxPos - minPos ) + 1, 0 )
      IF newRecno <= 0
         newRecno := 1
      ELSEIF newRecno > oBrw:nRecords
         newRecno := oBrw:nRecords
      ENDIF
      IF nType == SB_THUMBPOSITION
         hwg_Setscrollpos( oBrw:handle, SB_VERT, nPos )
      ENDIF
      IF newRecno != oldRecno
         Eval( oBrw:bSkip, oBrw, newRecno - oldRecno )
         IF oBrw:rowCount - oBrw:rowPos > oBrw:nRecords - newRecno
            oBrw:rowPos := oBrw:rowCount - ( oBrw:nRecords - newRecno )
         ENDIF
         IF oBrw:rowPos > newRecno
            oBrw:rowPos := newRecno
         ENDIF
         oBrw:Refresh( oBrw:nFootRows > 0 )
      ENDIF
   ENDIF

   RETURN NIL

STATIC FUNCTION HdrToken( cStr, nMaxLen, nCount )
   LOCAL nL, nPos := 0

   nMaxLen := nCount := 0
   cStr += ';'
#ifdef __XHARBOUR__
   DO WHILE ( nL := Len( __StrTkPtr( @cStr, @nPos, ";" ) ) ) != 0
#else
   DO WHILE ( nL := Len( hb_tokenPtr( @cStr, @nPos, ";" ) ) ) != 0
#endif
   nMaxLen := Max( nMaxLen, nL )
   nCount ++
   ENDDO

   RETURN NIL

STATIC FUNCTION FltSkip( oBrw, nLines, lDesc )
   LOCAL n

   IF nLines == NIL
      nLines := 1
   ENDIF
   IF lDesc == NIL
      lDesc := .F.
   ENDIF
   IF nLines > 0
      FOR n := 1 TO nLines
         ( oBrw:Alias ) -> ( dbSkip( iif( lDesc, - 1, + 1 ) ) )
         IF Empty( oBrw:RelationalExpr )
            WHILE ( oBrw:Alias ) -> ( ! Eof() ) .AND. Eval( oBrw:bWhile, oBrw ) .AND. ! Eval( oBrw:bFor, oBrw )
               // SKIP IF( lDesc, - 1, + 1 )
               ( oBrw:Alias ) -> ( dbSkip( iif( lDesc, - 1, + 1 ) ) )
            ENDDO
         ENDIF
      NEXT
   ELSEIF nLines < 0
      FOR n := 1 TO ( nLines * ( - 1 ) )
         IF ( oBrw:Alias ) -> ( Eof() )
            IF lDesc
               FltGoTop( oBrw )
            ELSE
               FltGoBottom( oBrw )
            ENDIF
         ELSE
            // SKIP IF( lDesc, + 1, - 1 )
            ( oBrw:Alias ) -> ( dbSkip( iif( lDesc, + 1, - 1 ) ) )
         ENDIF
         IF Empty( oBrw:RelationalExpr )
            WHILE ! ( oBrw:Alias ) -> ( Bof() ) .AND. Eval( oBrw:bWhile, oBrw ) .AND. ! Eval( oBrw:bFor, oBrw )
               // SKIP IF( lDesc, + 1, - 1 )
               ( oBrw:Alias ) -> ( dbSkip( iif( lDesc, + 1, - 1 ) ) )
            ENDDO
         ENDIF
      NEXT
   ENDIF

   RETURN NIL

STATIC FUNCTION FltGoTop( oBrw )

   IF oBrw:nFirstRecordFilter == 0
      Eval( oBrw:bFirst )
      IF ( oBrw:Alias ) -> ( ! Eof() )
         IF Empty( oBrw:RelationalExpr )
            WHILE ( oBrw:Alias ) -> ( ! Eof() ) .AND. ! ( Eval( oBrw:bWhile, oBrw ) .AND. Eval( oBrw:bFor, oBrw ) )
               ( oBrw:Alias ) -> ( dbSkip() )
            ENDDO
         ENDIF
         oBrw:nFirstRecordFilter := FltRecNo( oBrw )
      ELSE
         oBrw:nFirstRecordFilter := 0
      ENDIF
   ELSE
      FltGoTo( oBrw, oBrw:nFirstRecordFilter )
   ENDIF

   RETURN NIL

STATIC FUNCTION FltGoBottom( oBrw )

   IF oBrw:nLastRecordFilter == 0
      Eval( oBrw:bLast )
      IF Empty( oBrw:RelationalExpr )
         IF ! Eval( oBrw:bWhile, oBrw ) .OR. ! Eval( oBrw:bFor, oBrw )
            WHILE ( oBrw:Alias ) -> ( ! Bof() ) .AND. ! Eval( oBrw:bWhile, oBrw )
               ( oBrw:Alias ) -> ( dbSkip( - 1 ) )
            ENDDO
            WHILE ! Bof() .AND. Eval( oBrw:bWhile, oBrw ) .AND. ! Eval( oBrw:bFor, oBrw )
               ( oBrw:Alias ) -> ( dbSkip( - 1 ) )
            ENDDO
         ENDIF
      ENDIF
      oBrw:nLastRecordFilter := FltRecNo( oBrw )
   ELSE
      FltGoTo( oBrw, oBrw:nLastRecordFilter )
   ENDIF

   RETURN NIL

STATIC FUNCTION FltBOF( oBrw )
   LOCAL lRet := .F. , nRecord
   LOCAL xValue, xFirstValue

   IF ( oBrw:Alias ) -> ( Bof() )
      lRet := .T.
   ELSE
      nRecord := FltRecNo( oBrw )
      xValue := ( oBrw:Alias ) -> ( OrdKeyNo() ) // &(cKey)
      FltGoTop( oBrw )
      xFirstValue := ( oBrw:Alias ) -> ( OrdKeyNo() ) // &(cKey)

      IF xValue < xFirstValue
         lRet := .T.
         FltGoTop( oBrw )
      ELSE
         FltGoTo( oBrw, nRecord )
      ENDIF
   ENDIF

   RETURN lRet

STATIC FUNCTION FltEOF( oBrw )
   LOCAL lRet := .F. , nRecord
   LOCAL xValue, xLastValue

   IF ( oBrw:Alias ) -> ( Eof() )
      lRet := .T.
   ELSE
      nRecord := FltRecNo( oBrw )
      xValue := ( oBrw:Alias ) -> ( OrdKeyNo() )
      FltGoBottom( oBrw )
      xLastValue := ( oBrw:Alias ) -> ( OrdKeyNo() )
      IF xValue > xLastValue
         lRet := .T.
         FltGoBottom( oBrw )
         ( oBrw:Alias ) -> ( dbSkip() )
      ELSE
         FltGoTo( oBrw, nRecord )
      ENDIF
   ENDIF

   RETURN lRet

STATIC FUNCTION FltGoTo( oBrw, nRecord )

   HB_SYMBOL_UNUSED( oBrw )

   RETURN ( oBrw:Alias ) -> ( dbGoto( nRecord ) )

STATIC FUNCTION FltRecNo( oBrw )

   HB_SYMBOL_UNUSED( oBrw )

   RETURN ( oBrw:Alias ) -> ( RecNo() )

   // Implementation by Basso

STATIC FUNCTION aFltSkip( oBrw, nLines )
   LOCAL n := Eval( oBrw:bRcou , oBrw )
   LOCAL abSkip   := { | o, n | ARSKIP( o, n ) }

   nLines := iif( nLines == NIL, 1, nLines )
   IF nLines > 0 .AND. n > 0
      FOR n := 1 TO nLines
         Eval( abSkip, oBrw, 1 )  //IIF( lDesc, - 1, + 1 ) )
         WHILE ! Eval( oBrw:bEof, oBrw ) .AND. Eval( oBrw:bWhile, oBrw ) .AND. ! Eval( oBrw:bFor, oBrw )
            Eval( abSkip, oBrw, 1 ) //IIF( lDesc, - 1, + 1 ) )
         ENDDO
      NEXT
   ELSEIF nLines < 0 .AND. n > 0
      FOR n := 1 TO ( nLines * ( - 1 ) )
         IF  Eval( oBrw:bEof, oBrw )
            aFltGoBottom( oBrw )
         ELSE
            Eval( abSkip, oBrw, - 1 ) //IIF( lDesc, - 1, + 1 ) )
         ENDIF
         WHILE ! Eval( oBrw:bBof, oBrw ) .AND. Eval( oBrw:bWhile, oBrw ) .AND. ! Eval( oBrw:bFor, oBrw )
            Eval( abSkip, oBrw, - 1 ) //IIF( lDesc, - 1, + 1 ) )
         ENDDO
         IF Eval( oBrw:bBof, oBrw )
            aFltGoTop( oBrw )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN NIL

STATIC FUNCTION aFltGoTop( oBrw )
   LOCAL abSkip   := { | o, n | ARSKIP( o, n ) }

   IF oBrw:nFirstRecordFilter == 0
      oBrw:nCurrent := 1
      IF ! Eval( oBrw:bEof, oBrw )
         WHILE ! Eval( oBrw:bEof, oBrw ) .AND.  Eval( oBrw:bWhile, oBrw ) .AND. ! Eval( oBrw:bFor, oBrw )
            Eval( abskip, oBrw,  1 )
         ENDDO
         oBrw:nFirstRecordFilter := aFltRecNo( oBrw )
      ELSE
         oBrw:nFirstRecordFilter := 0
      ENDIF
   ELSE
      aFltGoTo( oBrw, oBrw:nFirstRecordFilter )
   ENDIF

   RETURN NIL

STATIC FUNCTION aFltGoBottom( oBrw )
   LOCAL abSkip   := { | o, n | ARSKIP( o, n ) }

   IF oBrw:nLastRecordFilter == 0
      oBrw:nCurrent := oBrw:nRecords
      IF ! Eval( oBrw:bWhile, oBrw ) .OR. ! Eval( oBrw:bFor, oBrw )
         WHILE ! Eval( oBrw:bBof, oBrw ) .AND. ! Eval( oBrw:bWhile, oBrw )
            Eval( abskip, oBrw, - 1 )
         ENDDO
         WHILE ! Eval( oBrw:bBof, oBrw ) .AND. Eval( oBrw:bWhile, oBrw ) .AND. ! Eval( oBrw:bFor, oBrw )
            Eval( abskip, oBrw,  - 1 )
         ENDDO
      ENDIF
      oBrw:nLastRecordFilter := aFltRecNo( oBrw )
   ELSE
      aFltGoTo( oBrw, oBrw:nLastRecordFilter )
   ENDIF

   RETURN NIL

STATIC FUNCTION aFltGoTo( oBrw, nRecord )

   HB_SYMBOL_UNUSED( oBrw )

   RETURN Eval( oBrw:bGoTo, oBrw, nRecord )

STATIC FUNCTION aFltRecNo( oBrw )

   HB_SYMBOL_UNUSED( oBrw )

   RETURN Eval( oBrw:bRecno, oBrw )

   // End Implementation by Basso

STATIC FUNCTION LenVal( xVal, cType, cPict )
   LOCAL nLen

   IF ! ISCHARACTER( cType )
      cType := ValType( xVal )
   ENDIF

   SWITCH cType
   CASE "L"
      nLen := 1
      EXIT

   CASE "N"
   CASE "C"
   CASE "D"
      IF ! Empty( cPict )
         nLen := Len( Transform( xVal, cPict ) )
         EXIT
      ENDIF

      SWITCH cType
      CASE "N"
         nLen := Len( Str( xVal ) )
         EXIT

      CASE "C"
         nLen := Len( xVal )
         EXIT

      CASE "D"
         nLen := Len( Dtoc( xVal ) )
         EXIT
      END
      EXIT

#ifdef __XHARBOUR__
      DEFAULT
#else
      OTHERWISE
#endif
      nLen := 0

   END

   RETURN nLen
