/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HStaticEx, HButtonEx, HGroupEx
 *
 * Copyright 2007 Luiz Rafael Culik Guimaraes <luiz at xharbour.com.br >
 * www - http://sites.uol.com.br/culikr/
*/

#include "hwgui.ch"
#include "hbclass.ch"
#include "common.ch"

#translate :hBitmap       => :m_csbitmaps\[ 1 \]
#translate :dwWidth       => :m_csbitmaps\[ 2 \]
#translate :dwHeight      => :m_csbitmaps\[ 3 \]
#translate :hMask         => :m_csbitmaps\[ 4 \]
#translate :crTransparent => :m_csbitmaps\[ 5 \]

#define TRANSPARENT 1
#define BTNST_COLOR_BK_IN     1            // Background color when mouse is INside
#define BTNST_COLOR_FG_IN     2            // Text color when mouse is INside
#define BTNST_COLOR_BK_OUT    3             // Background color when mouse is OUTside
#define BTNST_COLOR_FG_OUT    4             // Text color when mouse is OUTside
#define BTNST_COLOR_BK_FOCUS  5           // Background color when the button is focused
#define BTNST_COLOR_FG_FOCUS  6            // Text color when the button is focused
#define BTNST_MAX_COLORS      6
#define WM_SYSCOLORCHANGE               0x0015
#define BS_TYPEMASK SS_TYPEMASK
#define OFS_X 10 // distance from left/right side to beginning/end of text
#define RT_MANIFEST  24

CLASS HThemed
   CLASS VAR WindowsManifest INIT !EMPTY(hwg_Findresource( , 1 , RT_MANIFEST ) ) SHARED
   DATA hTheme
   DATA Themed INIT .F.

ENDCLASS

CLASS HStaticEx INHERIT HStatic

   CLASS VAR winclass   INIT "STATIC"
   DATA AutoSize INIT .F.
   DATA nStyleHS
   DATA bClick, bDblClick
   DATA BackStyle       INIT OPAQUE
   DATA hBrushDefault  HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
      bColor, lTransp, bClick, bDblClick, bOther )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, bDblClick, bOther )
   METHOD SetText( value ) INLINE ::SetValue( value )
   METHOD SetValue( cValue )
   METHOD Auto_Size( cValue )  HIDDEN
   METHOD Init()
   METHOD PAINT( lpDis )
   METHOD onClick()
   METHOD onDblClick()
   METHOD OnEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
      bColor, lTransp, bClick, bDblClick, bOther ) CLASS HStaticEx

   nStyle := iif( nStyle = Nil, 0, nStyle )
   ::nStyleHS := nStyle - Hwg_BitAND( nStyle,  WS_VISIBLE + WS_DISABLED + WS_CLIPSIBLINGS + ;
      WS_CLIPCHILDREN + WS_BORDER + WS_DLGFRAME + ;
      WS_VSCROLL + WS_HSCROLL + WS_THICKFRAME + WS_TABSTOP )
   nStyle += SS_NOTIFY + WS_CLIPCHILDREN

   ::BackStyle := OPAQUE
   IF ( lTransp != NIL .AND. lTransp )
      ::BackStyle := TRANSPARENT
      ::extStyle := Hwg_BitOr( ::extStyle, WS_EX_TRANSPARENT )
      bPaint := { | o, p | o:paint( p ) }
      nStyle += SS_OWNERDRAW - ::nStyleHS
   ELSEIF ::nStyleHS > 32 .OR. ::nStyleHS = 2
      bPaint := { | o, p | o:paint( p ) }
      nStyle +=  SS_OWNERDRAW - ::nStyleHS
   ENDIF

   ::hBrushDefault := HBrush():Add( hwg_Getsyscolor( COLOR_BTNFACE ) )
   ::bOther := bOther

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor )

   ::bClick := bClick
   IF ::id > 2
      ::oParent:AddEvent( STN_CLICKED, ::id, { || ::onClick() } )
   ENDIF
   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, ::id, { || ::onDblClick() } )

   RETURN Self

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, bDblClick, bOther ) CLASS HStaticEx

   IF ( lTransp != NIL .AND. lTransp )
      ::extStyle := Hwg_BitOr( ::extStyle, WS_EX_TRANSPARENT )
      bPaint := { | o, p | o:paint( p ) }
      ::BackStyle := TRANSPARENT
   ENDIF

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor )

   ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   // Enabling style for tooltips
   ::style := SS_NOTIFY
   ::bOther := bOther
   ::bClick := bClick
   IF ::id > 2
      ::oParent:AddEvent( STN_CLICKED, ::id, { || ::onClick() } )
   ENDIF
   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, ::id, { || ::onDblClick() } )

   RETURN Self

METHOD Init() CLASS HStaticEx

   IF ! ::lInit
      ::Super:init()
      IF ::nHolder != 1
         ::nHolder := 1
         hwg_Setwindowobject( ::handle, Self )
         Hwg_InitStaticProc( ::handle )
      ENDIF
      IF ::classname == "HSTATIC"
         ::Auto_Size( ::Title )
      ENDIF
      IF ::title != NIL
         hwg_Setwindowtext( ::handle, ::title )
      ENDIF
   ENDIF

   RETURN  NIL

METHOD OnEvent( msg, wParam, lParam ) CLASS  HStaticEx
   LOCAL nEval, pos

   IF ::bOther != NIL
      IF ( nEval := Eval( ::bOther, Self, msg, wParam, lParam ) ) != - 1 .AND. nEval != NIL
         RETURN 0
      ENDIF
   ENDIF
   wParam := hwg_PtrToUlong( wParam )
   IF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg = WM_KEYUP
      IF wParam = VK_DOWN
         hwg_GetSkip( ::oParent, ::handle, 1 )
      ELSEIF wParam = VK_UP
         hwg_GetSkip( ::oParent, ::handle, - 1 )
      ELSEIF wParam = VK_TAB
         hwg_GetSkip( ::oParent, ::handle, iif( hwg_IsCtrlShift( .F. , .T. ), - 1, 1 ) )
      ENDIF
      RETURN 0
   ELSEIF msg == WM_SYSKEYUP
      IF ( pos := At( "&", ::title ) ) > 0 .AND. wParam == Asc( Upper( SubStr( ::title, ++ pos, 1 ) ) )
         hwg_GetSkip( ::oparent, ::handle, 1 )
         RETURN  0
      ENDIF
   ELSEIF msg = WM_GETDLGCODE
      RETURN DLGC_WANTARROWS + DLGC_WANTTAB
   ENDIF

   RETURN - 1

METHOD SetValue( cValue )  CLASS HStaticEx

   ::Auto_Size( cValue )
   IF ::backstyle = TRANSPARENT .AND. ::Title != cValue .AND. hwg_Iswindowvisible( ::handle )
      hwg_Setdlgitemtext( ::oParent:handle, ::id, cValue )
      IF ::backstyle = TRANSPARENT .AND. ::Title != cValue .AND. hwg_Iswindowvisible( ::handle )
         hwg_Redrawwindow( ::oParent:Handle, RDW_ERASE + RDW_INVALIDATE + RDW_ERASENOW + RDW_INTERNALPAINT , ::nLeft, ::nTop, ::nWidth , ::nHeight )
         hwg_Updatewindow( ::oParent:Handle )
      ENDIF
   ELSEIF ::backstyle != TRANSPARENT
      hwg_Setdlgitemtext( ::oParent:handle, ::id, cValue )
   ENDIF
   ::Title := cValue

   RETURN NIL

METHOD Paint( lpDis ) CLASS HStaticEx
   LOCAL drawInfo := hwg_Getdrawiteminfo( lpDis )
   LOCAL client_rect, szText
   LOCAL dwtext, nstyle, brBackground
   LOCAL dc := drawInfo[ 3 ]

   client_rect := hwg_Copyrect( { drawInfo[ 4 ] , drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] } )
   szText := hwg_Getwindowtext( ::handle )

   // Map "Static Styles" to "Text Styles"
   nstyle := ::nStyleHS  // ::style
   IF nStyle - SS_NOTIFY < DT_SINGLELINE
      hwg_Setastyle( @nstyle, @dwtext )
   ELSE
      dwtext := nStyle - DT_NOCLIP
   ENDIF

   // Set transparent background
   hwg_Setbkmode( dc, ::backstyle )
   IF ::BackStyle = OPAQUE
      brBackground := iif( ! Empty( ::brush ), ::brush, ::hBrushDefault )
      hwg_Fillrect( dc, client_rect[ 1 ], client_rect[ 2 ], client_rect[ 3 ], client_rect[ 4 ], brBackground:handle )
   ENDIF

   IF ::tcolor != NIL .AND. ::Enabled
      hwg_Settextcolor( dc, ::tcolor )
   ELSEIF ! ::Enabled
      hwg_Settextcolor( dc, 16777215 )
      hwg_Drawtext( dc, szText, { client_rect[ 1 ] + 1, client_rect[ 2 ] + 1, client_rect[ 3 ] + 1, client_rect[ 4 ] + 1 }, dwtext )
      hwg_Setbkmode( dc, TRANSPARENT )
      hwg_Settextcolor( dc, 10526880 )
   ENDIF
   // Draw the text
   hwg_Drawtext( dc, szText, client_rect, dwtext )

   RETURN NIL

METHOD onClick()  CLASS HStaticEx

   IF ::bClick != NIL
      Eval( ::bClick, Self, ::id )
   ENDIF

   RETURN NIL

METHOD onDblClick()  CLASS HStaticEx

   IF ::bDblClick != NIL
      Eval( ::bDblClick, Self, ::id )
   ENDIF

   RETURN NIL

METHOD Auto_Size( cValue ) CLASS HStaticEx
   LOCAL  ASize, nLeft, nAlign

   IF ::autosize
      nAlign := ::nStyleHS - SS_NOTIFY
      ASize :=  hwg_TxtRect( cValue, Self )
      // ajust VCENTER
      IF nAlign == SS_RIGHT
         nLeft := ::nLeft + ( ::nWidth - ASize[ 1 ] - 2 )
      ELSEIF nAlign == SS_CENTER
         nLeft := ::nLeft + Int( ( ::nWidth - ASize[ 1 ] - 2 ) / 2 )
      ELSEIF nAlign == SS_LEFT
         nLeft := ::nLeft
      ENDIF
      ::nWidth := ASize[ 1 ] + 2
      ::nHeight := ASize[ 2 ]
      ::nLeft := nLeft
      ::move( ::nLeft, ::nTop )
   ENDIF

   RETURN NIL

CLASS HButtonX INHERIT HButton

   CLASS VAR winclass   INIT "BUTTON"
   DATA bClick
   DATA cNote  HIDDEN
   DATA lFlat INIT .F.
   DATA lnoWhen

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor, bGFocus )
   METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, cCaption, bGFocus )
   METHOD Init()
   METHOD onClick()
   METHOD onGetFocus()
   METHOD onLostFocus()
   METHOD onEvent( msg, wParam, lParam )
   METHOD NoteCaption( cNote )  SETGET

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor, bGFocus ) CLASS HButtonX

   nStyle := Hwg_BitOr( iif( nStyle == NIL, 0, nStyle ), BS_PUSHBUTTON + BS_NOTIFY )
   ::lFlat := Hwg_BitAND( nStyle, BS_FLAT ) != 0

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint,, cTooltip, ;
      tcolor, bColor, bGFocus )

   ::bClick := bClick
   ::bGetFocus  := bGFocus
   ::oParent:AddEvent( BN_SETFOCUS, ::id, { || ::onGetFocus() } )
   ::oParent:AddEvent( BN_KILLFOCUS, ::id, { || ::onLostFocus() } )

   IF ::id > IDCANCEL .OR. ::bClick != NIL
      IF ::id < IDABORT
         hwg_GetParentForm( Self ):AddEvent( BN_CLICKED, ::id, { || ::onClick() } )
      ENDIF
      IF hwg_GetParentForm( Self ):Classname != ::oParent:Classname  .OR. ::id > IDCANCEL
         ::oParent:AddEvent( BN_CLICKED, ::id, { || ::onClick() } )
      ENDIF
   ENDIF

   RETURN Self

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, cCaption, bGFocus ) CLASS HButtonX

   ::super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor )

   ::title   := cCaption
   ::bGetFocus  := bGFocus
   ::oParent:AddEvent( BN_SETFOCUS, ::id, { || ::onGetFocus() } )
   ::oParent:AddEvent( BN_KILLFOCUS, ::id, { || ::onLostFocus() } )
   ::bClick  := bClick
   IF ::id > IDCANCEL .OR. ::bClick != NIL
      IF ::id < IDABORT
         hwg_GetParentForm( Self ):AddEvent( BN_CLICKED, ::id, { || ::onClick() } )
      ENDIF
      IF hwg_GetParentForm( Self ):Classname != ::oParent:Classname  .OR. ::id > IDCANCEL
         ::oParent:AddEvent( BN_CLICKED, ::id, { || ::onClick() } )
      ENDIF
   ENDIF

   RETURN Self

METHOD Init() CLASS HButtonX

   IF ! ::lInit
      IF !( hwg_GetParentForm( Self ):classname == ::oParent:classname .AND. ;
            hwg_GetParentForm( Self ):Type >= WND_DLG_RESOURCE ) .OR. ;
            ! hwg_GetParentForm( Self ):lModal  .OR. ::nHolder = 1
         ::nHolder := 1
         hwg_Setwindowobject( ::handle, Self )
         HWG_INITBUTTONPROC( ::handle )
      ENDIF
      ::Super:init()
   ENDIF

   RETURN  NIL

METHOD onevent( msg, wParam, lParam ) CLASS HButtonX

   IF msg = WM_SETFOCUS .AND. ::oParent:oParent = NIL
   ELSEIF msg = WM_KILLFOCUS
      IF hwg_GetParentForm( Self ):handle != ::oParent:Handle
         hwg_Invalidaterect( ::handle, 0 )
         hwg_Sendmessage( ::handle, BM_SETSTYLE , BS_PUSHBUTTON , 1 )
      ENDIF
   ELSEIF msg = WM_KEYDOWN
      IF ( wParam == VK_RETURN   .OR. wParam == VK_SPACE )
         hwg_Sendmessage( ::handle, WM_LBUTTONDOWN, 0, hwg_Makelparam( 1, 1 ) )
         RETURN 0
      ENDIF
      /*
      IF ! hwg_ProcKeyList( Self, wParam )
         IF wParam = VK_TAB
            hwg_GetSkip( ::oparent, ::handle,iif( hwg_IsCtrlShift( .F. , .T. ), - 1, 1 )  )
            RETURN 0
         ELSEIF wParam = VK_LEFT .OR. wParam = VK_UP
            hwg_GetSkip( ::oparent, ::handle,- 1 )
            RETURN 0
         ELSEIF wParam = VK_RIGHT .OR. wParam = VK_DOWN
            hwg_GetSkip( ::oparent, ::handle,1 )
            RETURN 0
         ENDIF
      ENDIF
      */
   ELSEIF msg == WM_KEYUP
      IF ( wParam == VK_RETURN .OR. wParam == VK_SPACE )
         hwg_Sendmessage( ::handle, WM_LBUTTONUP, 0, hwg_Makelparam( 1, 1 ) )
         RETURN 0
      ENDIF
   ELSEIF  msg = WM_GETDLGCODE .AND. ! Empty( lParam )
      IF wParam = VK_RETURN .OR. wParam = VK_TAB
      ELSEIF hwg_Getdlgmessage( lParam ) = WM_KEYDOWN .AND. wParam != VK_ESCAPE
      ELSEIF hwg_Getdlgmessage( lParam ) = WM_CHAR .OR. wParam = VK_ESCAPE
         RETURN - 1
      ENDIF
      RETURN DLGC_WANTMESSAGE
   ENDIF

   RETURN - 1

METHOD onClick()  CLASS HButtonX

   IF ::bClick != NIL
      Eval( ::bClick, Self, ::id )
   ENDIF

   RETURN NIL

METHOD NoteCaption( cNote )  CLASS HButtonX

   IF cNote != NIL
      IF Hwg_BitOr( ::Style, BS_COMMANDLINK ) > 0
         hwg_Sendmessage( ::Handle, BCM_SETNOTE, 0, hwg_Ansitounicode( cNote ) )
      ENDIF
      ::cNote := cNote
   ENDIF

   RETURN ::cNote

METHOD onGetFocus()  CLASS HButtonX
   LOCAL res := .T. , nSkip

   /*
   IF ! hwg_CheckFocus( Self, .F. ) .OR. ::bGetFocus = NIL
      RETURN .T.
   ENDIF
   */
   IF ::bGetFocus != NIL
      nSkip := iif( hwg_Getkeystate( VK_UP ) < 0 .OR. ( hwg_Getkeystate( VK_TAB ) < 0 .AND. hwg_Getkeystate( VK_SHIFT ) < 0 ), - 1, 1 )
      res := Eval( ::bGetFocus, ::title, Self )
      IF res != NIL .AND.  Empty( res )
         /*
         hwg_WhenSetFocus( Self, nSkip )
         */
         IF ::lflat
            hwg_Invalidaterect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
         ENDIF
      ENDIF
   ENDIF
// Suppress warning: nSkip is kept for future reactivation of hwg_WhenSetFocus
   HB_SYMBOL_UNUSED( nSkip )
   RETURN res

METHOD onLostFocus()  CLASS HButtonX

   IF ::lflat
      hwg_Invalidaterect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
   ENDIF
   ::lnoWhen := .F.
   IF ::bLostFocus != NIL .AND. hwg_Selffocus( hwg_Getparent( hwg_Getfocus() ), hwg_getparentform( Self ):Handle )
      Eval( ::bLostFocus, ::title, Self )
   ENDIF

   RETURN NIL


CLASS HButtonEX INHERIT HButtonX, HThemed

   DATA hBitmap
   DATA hIcon
   DATA m_dcBk
   DATA m_bFirstTime INIT .T.
   DATA m_crColors INIT Array( 6 )
   DATA m_crBrush INIT Array( 6 )
   DATA Caption
   DATA state
   DATA m_bIsDefault INIT .F.
   DATA m_nTypeStyle  init 0
   DATA m_bSent, m_bLButtonDown, m_bIsToggle
   DATA m_rectButton           // button rect in parent window coordinates
   DATA m_dcParent init hdc():new()
   DATA m_bmpParent
   DATA m_pOldParentBitmap
   DATA m_csbitmaps init { , , , , }
   DATA m_bToggled INIT .F.
   DATA PictureMargin INIT 0
   DATA m_bDrawTransparent INIT .F.
   DATA iStyle
   DATA m_bmpBk, m_pbmpOldBk
   DATA bMouseOverButton INIT .F.
   DATA lnoThemes

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor, hBitmap, iStyle, hicon, Transp, bGFocus, nPictureMargin, lnoThemes, bOther )
   METHOD Paint( lpDis )
   METHOD SetBitmap( hBitMap )
   METHOD SetIcon( hIcon )
   METHOD Init()
   METHOD onevent( msg, wParam, lParam )
   METHOD CancelHover()
   METHOD END()

   METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon, bGFocus, ;
      nPictureMargin, Transp, lnoThemes )

   METHOD PaintBk( hdc )
   METHOD Setcolor( tcolor, bcolor ) INLINE ::SetDefaultColor( tcolor, bcolor ) //, ::SetDefaultColor( .T. )
   METHOD SetDefaultColor( tColor, bColor, lPaint )
   METHOD SetColorEx( nIndex, nColor, lPaint )
   METHOD SetText( c ) INLINE ::title := c,  ;
      hwg_Redrawwindow( ::Handle, RDW_NOERASE + RDW_INVALIDATE ), ;
      iif( ::oParent != NIL .AND. hwg_Iswindowvisible( ::Handle ) , ;
      hwg_Invalidaterect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  ), ), ;
      hwg_Setwindowtext( ::handle, ::title )
   //   METHOD SaveParentBackground()

END CLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor, hBitmap, iStyle, hicon, Transp, bGFocus, nPictureMargin, lnoThemes, bOther ) CLASS HButtonEx

   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT Transp TO .T.
   DEFAULT nPictureMargin TO 0
   DEFAULT lnoThemes  TO .F.
   ::m_bLButtonDown := .F.
   ::m_bSent := .F.
   ::m_bLButtonDown := .F.
   ::m_bIsToggle := .F.

   cCaption := iif( cCaption = NIL, "", cCaption )
   ::Caption := cCaption
   ::iStyle              := iStyle
   ::hBitmap             := iif( Empty( hBitmap ), NIL, hBitmap )
   ::hicon               := iif( Empty( hicon ), NIL, hIcon )
   ::m_bDrawTransparent  := Transp
   ::PictureMargin       := nPictureMargin
   ::lnoThemes           := lnoThemes
   ::bOther := bOther
   bPaint := { | o, p | o:paint( p ) }

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor, bGFocus )

   RETURN Self

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon, bGFocus, nPictureMargin ,Transp,lnoThemes) CLASS HButtonEx

   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT nPictureMargin TO 0
   DEFAULT Transp TO .T.
   DEFAULT lnoThemes  TO .F.

   bPaint := { | o, p | o:paint( p ) }
   ::Super:Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, cCaption,  bGFocus  )
   ::bPaint  := bPaint
   ::m_bLButtonDown := .F.
   ::m_bIsToggle := .F.
   ::m_bLButtonDown := .F.
   ::m_bSent := .F.

   ::title := cCaption
   ::Caption := cCaption
   ::iStyle  := iStyle
   ::hBitmap := hBitmap
   ::hIcon   := hIcon
   ::m_crColors[ BTNST_COLOR_BK_IN ]    := hwg_Getsyscolor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := hwg_Getsyscolor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := hwg_Getsyscolor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := hwg_Getsyscolor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := hwg_Getsyscolor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := hwg_Getsyscolor( COLOR_BTNTEXT )
   ::PictureMargin                      := nPictureMargin
   ::m_bDrawTransparent  := Transp
   ::lnoThemes           := lnoThemes


   ::title := cCaption
   ::Caption := cCaption

   RETURN Self

METHOD SetBitmap( hBitMap ) CLASS HButtonEX

   DEFAULT hBitmap TO ::hBitmap
   IF !Empty( hBitmap )
      ::hBitmap := hBitmap
      hwg_Sendmessage( ::handle, BM_SETIMAGE, IMAGE_BITMAP, ::hBitmap )
      hwg_Redrawwindow( ::Handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT )
   ENDIF

   RETURN Self

METHOD SetIcon( hIcon ) CLASS HButtonEX

   DEFAULT hIcon TO ::hIcon
   IF !Empty( hIcon )
      ::hIcon := hIcon
      hwg_Sendmessage( ::handle, BM_SETIMAGE, IMAGE_ICON, ::hIcon )
      hwg_Redrawwindow( ::Handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT )
   ENDIF

   RETURN Self

METHOD END() CLASS HButtonEX

   ::Super:END()

   RETURN Self

METHOD INIT() CLASS HButtonEx
   LOCAL nbs
altd()
   IF ! ::lInit
      ::nHolder := 1
      IF !Empty( ::handle )
         nbs := HWG_GETWINDOWSTYLE( ::handle )
         ::m_nTypeStyle :=  hwg_Getthestyle( nbs , BS_TYPEMASK )

         // Check if this is a checkbox
         // Set initial default state flag
         IF ( ::m_nTypeStyle == BS_DEFPUSHBUTTON )
            // Set default state for a default button
            ::m_bIsDefault := .T.

            // Adjust style for default button
            ::m_nTypeStyle := BS_PUSHBUTTON
         ENDIF
         nbs := hwg_Modstyle( nbs, BS_TYPEMASK  , BS_OWNERDRAW )
         HWG_SETWINDOWSTYLE ( ::handle, nbs )
      ENDIF

      ::Super:init()
      ::SetBitmap()
   ENDIF

   RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HBUTTONEx

   LOCAL pt := { , }, rectButton, acoor
   LOCAL pos, nID, oParent, nEval

   wParam := hwg_PtrToUlong( wParam )
   IF msg == WM_THEMECHANGED
      IF ::Themed
         IF !Empty( ::htheme )
            hwg_closethemedata( ::htheme )
            ::hTheme := NIL
         ENDIF
         ::Themed := .F.
      ENDIF
      ::m_bFirstTime := .T.
      hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
      RETURN 0
   ELSEIF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg == BM_SETSTYLE
      RETURN hwg_Buttonexonsetstyle( wParam, lParam, ::handle, @::m_bIsDefault )
   ELSEIF msg == WM_MOUSEMOVE
      IF wParam = MK_LBUTTON
         pt[ 1 ] := hwg_Loword( lParam )
         pt[ 2 ] := hwg_Hiword( lParam )
         acoor := hwg_Clienttoscreen( ::handle, pt[ 1 ], pt[ 2 ] )
         rectButton := hwg_Getwindowrect( ::handle )
         IF ( ! hwg_Ptinrect( rectButton, acoor ) )
            hwg_Sendmessage( ::handle, BM_SETSTATE, ::m_bToggled, 0 )
            ::bMouseOverButton := .F.
            RETURN 0
         ENDIF
      ENDIF
      IF ( ! ::bMouseOverButton )
         ::bMouseOverButton := .T.
         hwg_Invalidaterect( ::handle, .F. )
         hwg_Trackmousevent( ::handle )
      ENDIF
      RETURN 0
   ELSEIF msg == WM_MOUSELEAVE
      ::CancelHover()
      RETURN 0
   ENDIF
   IF ::bOther != NIL
      IF ( nEval := Eval( ::bOther, Self, msg, wParam, lParam ) ) != - 1 .AND. nEval != NIL
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_KEYDOWN
      IF hwg_CheckBit( hwg_Ptrtoulong( lParam ), 30 )  // the key was down before ?
         RETURN 0
      ENDIF
      IF ( ( wParam == VK_SPACE ) .OR. ( wParam == VK_RETURN ) )
         hwg_Sendmessage( ::handle, WM_LBUTTONDOWN, 0, hwg_Makelparam( 1, 1 ) )
         RETURN 0
      ENDIF
      IF wParam == VK_LEFT .OR. wParam == VK_UP
         hwg_GetSkip( ::oParent, ::handle, - 1 )
         RETURN 0
      ELSEIF wParam == VK_RIGHT .OR. wParam == VK_DOWN
         hwg_GetSkip( ::oParent, ::handle, 1 )
         RETURN 0
      ELSEIF  wParam = VK_TAB
         hwg_GetSkip( ::oparent, ::handle, iif( hwg_IsCtrlShift( .F. , .T. ), - 1, 1 )  )
      ENDIF
      /*
      hwg_ProcKeyList( Self, wParam )
      */
   ELSEIF msg == WM_SYSKEYUP .OR. ( msg == WM_KEYUP .AND. ;
         ASCAN( { VK_SPACE, VK_RETURN, VK_ESCAPE }, wParam ) = 0 )
      IF hwg_Checkbit( lParam, 23 ) .AND. ( wParam > 95 .AND. wParam < 106 )
         wParam -= 48
      ENDIF
      IF ! Empty( ::title ) .AND. ( pos := At( "&", ::title ) ) > 0 .AND. wParam == Asc( Upper( SubStr( ::title, ++ pos, 1 ) ) )
         IF ValType( ::bClick ) == "B" .OR. ::id < 3
            hwg_Sendmessage( ::oParent:handle, WM_COMMAND, hwg_Makewparam( ::id, BN_CLICKED ), ::handle )
         ENDIF
      ELSEIF ( nID := Ascan( ::oparent:acontrols, { | o | iif( ValType( o:title ) = "C", ( pos := At( "&", o:title ) ) > 0 .AND. ;
            wParam == Asc( Upper( SubStr( o:title, ++ pos, 1 ) ) ), ) } ) ) > 0
         IF __ObjHasMsg( ::oParent:aControls[ nID ], "BCLICK" ) .AND. ;
               ValType( ::oParent:aControls[ nID ]:bClick ) == "B" .OR. ::oParent:aControls[ nID]:id < 3
            hwg_Sendmessage( ::oParent:handle, WM_COMMAND, hwg_Makewparam( ::oParent:aControls[ nID ]:id, BN_CLICKED ), ::oParent:aControls[ nID ]:handle )
         ENDIF
      ENDIF
      IF msg != WM_SYSKEYUP
         RETURN 0
      ENDIF
   ELSEIF msg == WM_KEYUP
      IF ( wParam == VK_SPACE .OR. wParam == VK_RETURN  )
         ::bMouseOverButton := .T.
         hwg_Sendmessage( ::handle, WM_LBUTTONUP, 0, hwg_Makelparam( 1, 1 ) )
         ::bMouseOverButton := .F.
         RETURN 0
      ENDIF
   ELSEIF msg == WM_LBUTTONUP
      ::m_bLButtonDown := .F.
      IF ( ::m_bSent )
         hwg_Sendmessage( ::handle, BM_SETSTATE, 0, 0 )
         ::m_bSent := .F.
      ENDIF
      IF ::m_bIsToggle
         pt[ 1 ] := hwg_Loword( lParam )
         pt[ 2 ] := hwg_Hiword( lParam )
         acoor := hwg_Clienttoscreen( ::handle, pt[ 1 ], pt[ 2 ] )
         rectButton := hwg_Getwindowrect( ::handle )
         IF ( ! hwg_Ptinrect( rectButton, acoor ) )
            ::m_bToggled := ! ::m_bToggled
            hwg_Invalidaterect( ::handle, 0 )
            hwg_Sendmessage( ::handle, BM_SETSTATE, 0, 0 )
            ::m_bLButtonDown := .T.
         ENDIF
      ENDIF
      IF ( ! ::bMouseOverButton )
         hwg_Setfocus( 0 )
         ::Setfocus()
         RETURN 0
      ENDIF
      RETURN - 1
   ELSEIF msg == WM_LBUTTONDOWN
      ::m_bLButtonDown := .T.
      IF ( ::m_bIsToggle )
         ::m_bToggled := ! ::m_bToggled
         hwg_Invalidaterect( ::handle, 0 )
      ENDIF
      RETURN - 1
   ELSEIF msg == WM_LBUTTONDBLCLK
      IF ( ::m_bIsToggle )
         // for toggle buttons, treat doubleclick as singleclick
         hwg_Sendmessage( ::handle, BM_SETSTATE, ::m_bToggled, 0 )
      ELSE
         hwg_Sendmessage( ::handle, BM_SETSTATE, 1, 0 )
         ::m_bSent := TRUE
      ENDIF
      RETURN 0
   ELSEIF msg == WM_GETDLGCODE
      IF wParam = VK_ESCAPE .AND. ( hwg_Getdlgmessage( lParam ) = WM_KEYDOWN .OR. hwg_Getdlgmessage( lParam ) = WM_KEYUP )
         oParent := hwg_GetParentForm( Self )
         /*
         IF ! hwg_ProcKeyList( Self, wParam )  .AND. ( oParent:Type < WND_DLG_RESOURCE .OR. ! oParent:lModal )
            hwg_Sendmessage( oParent:handle, WM_COMMAND, hwg_Makewparam( IDCANCEL, 0 ), ::handle )
         ELSE
         */
         IF oParent:FindControl( IDCANCEL ) != NIL .AND. ! oParent:FindControl( IDCANCEL ):Enabled .AND. oParent:lExitOnEsc
            hwg_Sendmessage( oParent:handle, WM_COMMAND, hwg_Makewparam( IDCANCEL, 0 ), ::handle )
            RETURN 0
         ENDIF
      ENDIF
      RETURN iif( wParam = VK_ESCAPE, - 1, hwg_Buttongetdlgcode( lParam ) )
   ELSEIF msg == WM_SYSCOLORCHANGE
      ::SetDefaultColors()
   ELSEIF msg == WM_CHAR
      IF wParam == VK_RETURN .OR. wParam == VK_SPACE
         IF ( ::m_bIsToggle )
            ::m_bToggled := ! ::m_bToggled
            hwg_Invalidaterect( ::handle, 0 )
         ELSE
            hwg_Sendmessage( ::handle, BM_SETSTATE, 1, 0 )
            //::m_bSent := .t.
         ENDIF
         // remove because repet click  2 times
         //hwg_Sendmessage( ::oParent:handle, WM_COMMAND, hwg_Makewparam( ::id, BN_CLICKED ), ::handle )
      ELSEIF wParam == VK_ESCAPE
         hwg_Sendmessage( ::oParent:handle, WM_COMMAND, hwg_Makewparam( IDCANCEL, BN_CLICKED ), ::handle )
      ENDIF
      RETURN 0
   ENDIF

   RETURN - 1

METHOD CancelHover() CLASS HBUTTONEx

   IF ( ::bMouseOverButton ) .AND. ::id != IDOK //NANDO
      ::bMouseOverButton := .F.
      IF !::lflat
         hwg_Invalidaterect( ::handle, .F. )
      ELSE
         hwg_Invalidaterect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
      ENDIF
   ENDIF

   RETURN NIL

METHOD SetDefaultColor( tColor, bColor, lPaint ) CLASS HBUTTONEx

   DEFAULT lPaint TO .F.

   IF !Empty( tColor )
      ::tColor := tColor
   ENDIF
   IF !Empty( bColor )
      ::bColor := bColor
      IF ::brush != NIL
         ::brush:Release()
      ENDIF
      ::brush := HBrush():Add( bColor )
   ENDIF
   ::m_crColors[ BTNST_COLOR_BK_IN ]    := iif( ::bColor = NIL, hwg_Getsyscolor( COLOR_BTNFACE ), ::bColor )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := iif( ::tColor = NIL, hwg_Getsyscolor( COLOR_BTNTEXT ), ::tColor )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := iif( ::bColor = NIL, hwg_Getsyscolor( COLOR_BTNFACE ), ::bColor )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := iif( ::tColor = NIL, hwg_Getsyscolor( COLOR_BTNTEXT ), ::tColor )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := iif( ::bColor = NIL, hwg_Getsyscolor( COLOR_BTNFACE ), ::bColor )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := iif( ::tColor = NIL, hwg_Getsyscolor( COLOR_BTNTEXT ), ::tColor )
   //
   ::m_crBrush[ BTNST_COLOR_BK_IN ] := HBrush():Add( ::m_crColors[ BTNST_COLOR_BK_IN ] )
   ::m_crBrush[ BTNST_COLOR_BK_OUT ] := HBrush():Add( ::m_crColors[ BTNST_COLOR_BK_OUT ] )
   ::m_crBrush[ BTNST_COLOR_BK_FOCUS ] := HBrush():Add( ::m_crColors[ BTNST_COLOR_BK_FOCUS ] )
   IF lPaint
      hwg_Invalidaterect( ::handle, .F. )
   ENDIF

   RETURN Self

METHOD SetColorEx( nIndex, nColor, lPaint ) CLASS HBUTTONEx

   DEFAULT lPaint TO .F.
   IF nIndex > BTNST_MAX_COLORS
      RETURN - 1
   ENDIF
   ::m_crColors[ nIndex ]    := nColor
   IF lPaint
      hwg_Invalidaterect( ::handle, .F. )
   ENDIF

   RETURN 0

METHOD Paint( lpDis ) CLASS HBUTTONEx
   LOCAL drawInfo := hwg_Getdrawiteminfo( lpDis )
   LOCAL dc := drawInfo[ 3 ]
   LOCAL bIsPressed     := HWG_BITAND( drawInfo[ 9 ], ODS_SELECTED ) != 0
   LOCAL bIsFocused     := HWG_BITAND( drawInfo[ 9 ], ODS_FOCUS ) != 0
   LOCAL bIsDisabled    := HWG_BITAND( drawInfo[ 9 ], ODS_DISABLED ) != 0
   LOCAL bDrawFocusRect := ! HWG_BITAND( drawInfo[ 9 ], ODS_NOFOCUSRECT ) != 0
   LOCAL focusRect
   LOCAL captionRect
   LOCAL centerRect
   LOCAL bHasTitle
   LOCAL itemRect := hwg_Copyrect( { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] } )
   LOCAL state
   LOCAL crColor
   LOCAL brBackground
   LOCAL br
   LOCAL brBtnShadow
   LOCAL uState
   LOCAL captionRectHeight
   LOCAL centerRectHeight

   LOCAL uAlign, uStyleTmp
   LOCAL aTxtSize := iif( ! Empty( ::caption ), hwg_TxtRect( ::caption, Self ), { 0, 0 } )
   LOCAL aBmpSize := iif( ! Empty( ::hbitmap ), hwg_Getbitmapsize( ::hbitmap ), { 0, 0 } )
   LOCAL itemRectOld, saveCaptionRect, bmpRect, itemRect1, captionRect1, fillRect
   LOCAL lMultiLine, nHeight := 0

   IF ( ::m_bFirstTime )
      ::m_bFirstTime := .F.
      IF ( hwg_Isthemedload() )
         IF !Empty( ::hTheme )
            hwg_closethemedata( ::htheme )
         ENDIF
         ::hTheme := NIL
         IF ::WindowsManifest
            ::hTheme := hwg_openthemedata( ::handle, "BUTTON" )
         ENDIF
      ENDIF
   ENDIF
   IF ! Empty( ::hTheme ) .AND. !::lnoThemes
      ::Themed := .T.
   ENDIF
   hwg_Setbkmode( dc, TRANSPARENT )
   IF ( ::m_bDrawTransparent )
      // ::PaintBk(DC)
   ENDIF

   // Prepare draw... paint button background
   IF ::Themed
      IF bIsDisabled
         state :=  PBS_DISABLED
      ELSE
         state := iif( bIsPressed, PBS_PRESSED, PBS_NORMAL )
      ENDIF
      IF state == PBS_NORMAL
         IF bIsFocused
            state := PBS_DEFAULTED
         ENDIF
         IF ::bMouseOverButton .OR. ::id = IDOK
            state := PBS_HOT
         ENDIF
      ENDIF
      IF ! ::lFlat
         hwg_drawthemebackground( ::hTheme, dc, BP_PUSHBUTTON, state, itemRect, NIL )
      ELSEIF bIsDisabled
         hwg_Fillrect( dc, itemRect[ 1 ] + 1, itemRect[ 2 ] + 1, itemRect[ 3 ] - 1, itemRect[ 4 ] - 1, hwg_Getsyscolorbrush( hwg_Getsyscolor( COLOR_BTNFACE ) ) )
      ELSEIF ::bMouseOverButton .OR. bIsFocused
         hwg_drawthemebackground( ::hTheme, dc, BP_PUSHBUTTON  , state, itemRect, NIL ) // + PBS_DEFAULTED
      ENDIF
   ELSE
      IF bIsFocused .OR. ::id = IDOK
         br := HBRUSH():Add( hwg_ColorRgb2N( 1, 1, 1 ) )
         hwg_Framerect( dc, itemRect, br:handle )
         hwg_Inflaterect( @itemRect, - 1, - 1 )
      ENDIF
      crColor := hwg_Getsyscolor( COLOR_BTNFACE )
      brBackground := HBRUSH():Add( crColor )
      hwg_Fillrect( dc, itemRect, brBackground:handle )
      IF ( bIsPressed )
         brBtnShadow := HBRUSH():Add( hwg_Getsyscolor( COLOR_BTNSHADOW ) )
         hwg_Framerect( dc, itemRect, brBtnShadow:handle )
      ELSE
         IF ! ::lFlat .OR. ::bMouseOverButton
            uState := HWG_BITOR( ;
               HWG_BITOR( DFCS_BUTTONPUSH, ;
               iif( ::bMouseOverButton, DFCS_HOT, 0 ) ), ;
               iif( bIsPressed, DFCS_PUSHED, 0 ) )
            hwg_Drawframecontrol( dc, itemRect, DFC_BUTTON, uState )
         ELSEIF bIsFocused
            uState := HWG_BITOR( ;
               HWG_BITOR( DFCS_BUTTONPUSH + DFCS_MONO , ; // DFCS_FLAT , ;
            iif( ::bMouseOverButton, DFCS_HOT, 0 ) ), ;
               iif( bIsPressed, DFCS_PUSHED, 0 ) )
            hwg_Drawframecontrol( dc, itemRect, DFC_BUTTON, uState )
         ENDIF
      ENDIF
   ENDIF

   uAlign := 0 //DT_LEFT
   IF !Empty( ::hbitmap ) .OR. !Empty( ::hIcon )
      uAlign := DT_VCENTER
   ENDIF

   IF uAlign = DT_VCENTER
      uAlign := iif( HWG_BITAND( ::Style, BS_TOP ) != 0, DT_TOP, DT_VCENTER )
      uAlign += iif( HWG_BITAND( ::Style, BS_BOTTOM ) != 0, DT_BOTTOM - DT_VCENTER , 0 )
      uAlign += iif( HWG_BITAND( ::Style, BS_LEFT ) != 0, DT_LEFT, DT_CENTER )
      uAlign += iif( HWG_BITAND( ::Style, BS_RIGHT ) != 0, DT_RIGHT - DT_CENTER, 0 )
   ELSE
      uAlign := iif( uAlign = 0, DT_CENTER + DT_VCENTER, uAlign )
   ENDIF

   uStyleTmp := HWG_GETWINDOWSTYLE( ::handle )
   itemRectOld := AClone( itemRect )
   IF hb_BitAnd( uStyleTmp, BS_MULTILINE ) != 0 .AND. !Empty( ::caption ) .AND. ;
         Int( aTxtSize[ 2 ] ) !=  Int( hwg_Drawtext( dc, ::caption, itemRect[ 1 ], itemRect[ 2 ],;
         itemRect[ 3 ] - iif( ::iStyle = ST_ALIGN_VERT, 0, aBmpSize[ 1 ] + 8 ), ;
         itemRect[ 4 ], DT_CALCRECT + uAlign + DT_WORDBREAK, itemRectOld ) )
      // *-INT( aTxtSize[ 2 ] ) !=  INT( hwg_Drawtext( dc, ::caption, itemRect,  DT_CALCRECT + uAlign + DT_WORDBREAK ) )
      uAlign += DT_WORDBREAK
      lMultiline := .T.
      drawInfo[ 4 ] += 2
      drawInfo[ 6 ] -= 2
      itemRect[ 1 ] += 2
      itemRect[ 3 ] -= 2
      aTxtSize[ 1 ] := itemRectold[ 3 ] - itemRectOld[ 1 ] + 1
      aTxtSize[ 2 ] := itemRectold[ 4 ] - itemRectold[ 2 ] + 1
   ELSE
      uAlign += DT_SINGLELINE
      lMultiline := .F.
   ENDIF

   captionRect := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] }
   //
   IF ( !Empty( ::hbitmap ) .OR. !Empty( ::hicon ) ) .AND. lMultiline
      IF ::iStyle = ST_ALIGN_HORIZ
         captionRect := { drawInfo[ 4 ] + ::PictureMargin , drawInfo[ 5 ], drawInfo[ 6 ] , drawInfo[ 7 ] }
      ELSEIF ::iStyle = ST_ALIGN_HORIZ_RIGHT
         captionRect := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ] - ::PictureMargin, drawInfo[ 7 ] }
      ELSEIF ::iStyle = ST_ALIGN_VERT
      ENDIF
   ENDIF

   itemRectOld := AClone( itemRect )

   IF !Empty( ::caption ) .AND. !Empty( ::hbitmap )  //.AND.!EMPTY( ::hicon )
      nHeight :=  aTxtSize[ 2 ] //nHeight := IIF( lMultiLine, hwg_Drawtext( dc, ::caption, itemRect,  DT_CALCRECT + uAlign + DT_WORDBREAK  ), aTxtSize[ 2 ] )
      IF ::iStyle = ST_ALIGN_HORIZ
         itemRect[ 1 ] := iif( ::PictureMargin = 0, ( ( ( ::nWidth - aTxtSize[ 1 ] - aBmpSize[ 1 ] / 2 ) / 2 ) ) / 2, ::PictureMargin )
         itemRect[ 1 ] := iif( itemRect[ 1 ] < 0, 0, itemRect[ 1 ] )
      ELSEIF ::iStyle = ST_ALIGN_HORIZ_RIGHT
      ELSEIF ::iStyle = ST_ALIGN_VERT .OR. ::iStyle = ST_ALIGN_OVERLAP
         nHeight := iif( lMultiLine,  hwg_Drawtext( dc, ::caption, itemRect,  DT_CALCRECT + DT_WORDBREAK  ), aTxtSize[ 2 ] )
         ::iStyle := ST_ALIGN_OVERLAP
         itemRect[ 1 ] := ( ::nWidth - aBmpSize[ 1 ] ) /  2
         itemRect[ 2 ] := iif( ::PictureMargin = 0, ( ( ( ::nHeight - ( nHeight + aBmpSize[ 2 ] + 1 ) ) / 2 ) ), ::PictureMargin )
      ENDIF
   ELSEIF ! Empty( ::caption )
      nHeight := aTxtSize[ 2 ] //nHeight := IIF( lMultiLine, hwg_Drawtext( dc, ::caption, itemRect,  DT_CALCRECT + DT_WORDBREAK ), aTxtSize[ 2 ] )
   ENDIF

   bHasTitle := ValType( ::caption ) == "C" .AND. ! Empty( ::Caption )

   IF !Empty( ::hbitmap ) .AND. ::m_bDrawTransparent .AND. ( ! bIsDisabled .OR. ::istyle = ST_ALIGN_HORIZ_RIGHT )
      bmpRect := hwg_Prepareimagerect( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, ::hIcon, ::hbitmap, ::iStyle )
      IF ::istyle = ST_ALIGN_HORIZ_RIGHT
         bmpRect[ 1 ]     -= ::PictureMargin
         captionRect[ 3 ] -= ::PictureMargin
      ENDIF
      IF ! bIsDisabled
         hwg_Drawtransparentbitmap( dc, ::hbitmap, bmpRect[ 1 ], bmpRect[ 2 ] )
      ELSE
         hwg_Drawgraybitmap( dc, ::hbitmap, bmpRect[ 1 ], bmpRect[ 2 ] )
      ENDIF
   ELSEIF !Empty( ::hbitmap ) .OR. !Empty( ::hicon )
      IF ::istyle = ST_ALIGN_HORIZ_RIGHT
         captionRect[ 3 ] -= ::PictureMargin
      ENDIF
      hwg_Drawtheicon( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle )
   ELSE
      hwg_Inflaterect( @captionRect, - 3, - 3 )
   ENDIF
   captionRect[ 1 ] += iif( HWG_BITAND( ::Style, BS_LEFT )  != 0, Max( ::PictureMargin, 2 ), 0 )
   captionRect[ 3 ] -= iif( HWG_BITAND( ::Style, BS_RIGHT ) != 0, Max( ::PictureMargin, 3 ), 0 )

   itemRect1    := AClone( itemRect )
   captionRect1 := AClone( captionRect )
   itemRect     := AClone( itemRectOld )

   IF ( bHasTitle )
      // If button is pressed then "press" title also
      IF bIsPressed .AND. ! ::Themed
         hwg_Offsetrect( @captionRect, 1, 1 )
      ENDIF
      // Center text
      centerRect := hwg_Copyrect( captionRect )
      IF !Empty( ::hbitmap ) .OR. !Empty( ::hicon )
         IF ! lmultiline  .AND. ::iStyle != ST_ALIGN_OVERLAP
            // hwg_Drawtext( dc, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], uAlign + DT_CALCRECT, @captionRect )
         ELSEIF !Empty( ::caption )
            // figura no topo texto em baixo
            IF ::iStyle = ST_ALIGN_OVERLAP //ST_ALIGN_VERT
               captionRect[ 2 ] :=  itemRect1[ 2 ] + aBmpSize[ 2 ] //+ 1
               uAlign -= ST_ALIGN_OVERLAP + 1
            ELSE
               captionRect[ 2 ] :=  ( ::nHeight - nHeight ) / 2 + 2
            ENDIF
            savecaptionRect := AClone( captionRect )
            hwg_Drawtext( dc, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], uAlign , @captionRect )
         ENDIF
      ELSE
         // *- uAlign += DT_CENTER
      ENDIF

      captionRectHeight := captionRect[ 4 ] - captionRect[ 2 ]
      centerRectHeight  := centerRect[ 4 ] - centerRect[ 2 ]
      hwg_Offsetrect( @captionRect, 0, ( centerRectHeight - captionRectHeight ) / 2 )
      IF ::Themed
         IF !Empty( ::hbitmap ) .OR. !Empty( ::hicon )
            IF lMultiLine  .OR. ::iStyle = ST_ALIGN_OVERLAP
               captionRect := AClone( savecaptionRect )
            ENDIF
         ELSEIF lMultiLine
            captionRect[ 2 ] := ( ::nHeight  - nHeight ) / 2 + 2
         ENDIF
         hwg_drawthemetext( ::hTheme, dc, BP_PUSHBUTTON, iif( bIsDisabled, PBS_DISABLED, PBS_NORMAL ), ;
            ::caption, ;
            uAlign + DT_END_ELLIPSIS, ;
            0, captionRect )
      ELSE
         hwg_Setbkmode( dc, TRANSPARENT )
         IF ( bIsDisabled )
            hwg_Offsetrect( @captionRect, 1, 1 )
            hwg_Settextcolor( dc, hwg_Getsyscolor( COLOR_3DHILIGHT ) )
            hwg_Drawtext( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
            hwg_Offsetrect( @captionRect, - 1, - 1 )
            hwg_Settextcolor( dc, hwg_Getsyscolor( COLOR_3DSHADOW ) )
            hwg_Drawtext( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
         ELSE
            IF ( ::bMouseOverButton .OR. bIsPressed )
               hwg_Settextcolor( dc, ::m_crColors[ BTNST_COLOR_FG_IN ] )
               hwg_Setbkcolor( dc, ::m_crColors[ BTNST_COLOR_BK_IN ] )
               fillRect := hwg_Copyrect( itemRect )
               IF bIsPressed
                  hwg_Drawbutton( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], 6 )
               ENDIF
               hwg_Inflaterect( @fillRect, - 2, - 2 )
               hwg_Fillrect( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], ::m_crBrush[ BTNST_COLOR_BK_IN ]:handle )
            ELSE
               IF ( bIsFocused )
                  hwg_Settextcolor( dc, ::m_crColors[ BTNST_COLOR_FG_FOCUS ] )
                  hwg_Setbkcolor( dc, ::m_crColors[ BTNST_COLOR_BK_FOCUS ] )
                  fillRect := hwg_Copyrect( itemRect )
                  hwg_Inflaterect( @fillRect, - 2, - 2 )
                  hwg_Fillrect( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], ::m_crBrush[ BTNST_COLOR_BK_FOCUS ]:handle )
               ELSE
                  hwg_Settextcolor( dc, ::m_crColors[ BTNST_COLOR_FG_OUT ] )
                  hwg_Setbkcolor( dc, ::m_crColors[ BTNST_COLOR_BK_OUT ] )
                  fillRect := hwg_Copyrect( itemRect )
                  hwg_Inflaterect( @fillRect, - 2, - 2 )
                  hwg_Fillrect( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], ::m_crBrush[ BTNST_COLOR_BK_OUT ]:handle )
               ENDIF
            ENDIF
            IF !Empty( ::hbitmap ) .AND. ::m_bDrawTransparent
               hwg_Drawtransparentbitmap( dc, ::hbitmap, bmpRect[ 1 ], bmpRect[ 2 ] )
            ELSEIF !Empty( ::hbitmap ) .OR. !Empty( ::hicon )
               hwg_Drawtheicon( ::handle, dc, bHasTitle, @itemRect1, @captionRect1, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle )
            ENDIF
            IF !Empty( ::hbitmap ) .OR. !Empty( ::hicon )
               IF lmultiline  .OR. ::iStyle = ST_ALIGN_OVERLAP
                  captionRect := AClone( savecaptionRect )
               ENDIF
            ELSEIF lMultiLine
               captionRect[ 2 ] := ( ::nHeight  - nHeight ) / 2 + 2
            ENDIF
            hwg_Drawtext( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
         ENDIF
      ENDIF
   ENDIF

   // Draw the focus rect
   IF bIsFocused .AND. bDrawFocusRect .AND. Hwg_BitaND( ::sTyle, WS_TABSTOP ) != 0
      focusRect := hwg_Copyrect( itemRect )
      hwg_Inflaterect( @focusRect, - 3, - 3 )
      hwg_Drawfocusrect( dc, focusRect )
   ENDIF
   hwg_Deleteobject( br )
   hwg_Deleteobject( brBackground )
   hwg_Deleteobject( brBtnShadow )

   RETURN NIL

METHOD PAINTBK( hdc ) CLASS HBUTTONEx

   LOCAL clDC := HclientDc():New( ::oparent:handle )
   LOCAL rect, rect1

   rect := hwg_Getclientrect( ::handle )
   rect1 := hwg_Getwindowrect( ::handle )
   hwg_Screentoclient( ::oparent:handle, rect1 )
   IF ValType( ::m_dcBk ) == "U"
      ::m_dcBk := hdc():New()
      ::m_dcBk:Createcompatibledc( clDC:m_hDC )
      ::m_bmpBk := hwg_Createcompatiblebitmap( clDC:m_hDC, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 2 ] )
      ::m_pbmpOldBk := ::m_dcBk:Selectobject( ::m_bmpBk )
      ::m_dcBk:Bitblt( 0, 0, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 4 ], clDC:m_hDc, rect1[ 1 ], rect1[ 2 ], SRCCOPY )
   ENDIF
   hwg_Bitblt( hdc, 0, 0, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 4 ], ::m_dcBk:m_hDC, 0, 0, SRCCOPY )

   RETURN Self

CLASS HGroupEx INHERIT HGroup

   DATA oRGroup
   DATA oBrush
   DATA BackStyle       INIT OPAQUE
   DATA lTransparent HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, tcolor, bColor, lTransp, oRGroup )
   METHOD Init()
   METHOD Paint( lpDis )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
      oFont, bInit, bSize, bPaint, tcolor, bColor, lTransp, oRGroup ) CLASS HGroupEx

   ::oRGroup := oRGroup
   ::oBrush := iif( bColor != NIL, ::brush, NIL )
   ::lTransparent := iif( lTransp != NIL, lTransp, .F. )
   ::backStyle := iif( ( lTransp != NIL .AND. lTransp ) .OR. ::bColor != NIL , TRANSPARENT, OPAQUE )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
      oFont, bInit, bSize, bPaint, tcolor, bColor )

   RETURN Self

METHOD Init() CLASS HGroupEx
   LOCAL nbs

   IF ! ::lInit
      ::Super:Init()
      IF ::oBrush != NIL .OR. ::backStyle = TRANSPARENT
         nbs := HWG_GETWINDOWSTYLE( ::handle )
         nbs := hwg_Modstyle( nbs, BS_TYPEMASK , BS_OWNERDRAW + WS_DISABLED )
         HWG_SETWINDOWSTYLE ( ::handle, nbs )
         ::bPaint   := { | o, p | o:paint( p ) }
      ENDIF
      IF ::oRGroup != NIL
         ::oRGroup:Handle := ::handle
         ::oRGroup:id := ::id
         ::oFont := ::oRGroup:oFont
         ::oRGroup:lInit := .F.
         ::oRGroup:Init()
      ELSE
         IF ::oBrush != NIL
            hwg_Setwindowpos( ::Handle, NIL, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE )
         ELSE
            hwg_Setwindowpos( ::Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE + SWP_NOSENDCHANGING )
         ENDIF
      ENDIF
   ENDIF

   RETURN NIL

METHOD PAINT( lpdis ) CLASS HGroupEx
   LOCAL drawInfo := hwg_Getdrawiteminfo( lpdis )
   LOCAL DC := drawInfo[ 3 ]
   LOCAL ppnOldPen, pnFrmDark,   pnFrmLight, iUpDist
   LOCAL szText, aSize, dwStyle
   LOCAL rc  := hwg_Copyrect( { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ] - 1, drawInfo[ 7 ] - 1 } )
   LOCAL rcText

   // determine text length
   szText := ::Title
   aSize := hwg_TxtRect( iif( Empty( szText ), "A", szText ), Self )
   // distance from window top to group rect
   iUpDist := ( aSize[ 2 ] / 2 )
   dwStyle := ::Style //HWG_GETWINDOWSTYLE( ::handle ) //GetStyle();
   rcText := { 0, rc[ 2 ] + iUpDist , 0, rc[ 2 ] + iUpDist  }
   IF Empty( szText )
   ELSEIF hb_BitAnd( dwStyle, BS_CENTER ) == BS_RIGHT // right aligned
      rcText[ 3 ] := rc[ 3 ] + 2 - OFS_X
      rcText[ 1 ] := rcText[ 3 ] - aSize[ 1 ]
   ELSEIF hb_BitAnd( dwStyle, BS_CENTER ) == BS_CENTER  // text centered
      rcText[ 1 ] := ( rc[ 3 ] - rc[ 1 ]  - aSize[ 1 ]  ) / 2
      rcText[ 3 ] := rcText[ 1 ] + aSize[ 1 ]
   ELSE //((!(dwStyle & BS_CENTER)) || ((dwStyle & BS_CENTER) == BS_LEFT))// left aligned   / default
      rcText[ 1 ] := rc[ 1 ] + OFS_X
      rcText[ 3 ] := rcText[ 1 ] + aSize[ 1 ]
   ENDIF
   hwg_Setbkmode( dc, TRANSPARENT )

   IF Hwg_BitAND( dwStyle, BS_FLAT ) != 0  // "flat" frame
      pnFrmDark  := HPen():Add( PS_SOLID, 1,  hwg_ColorRgb2N( 64, 64, 64 ) )
      pnFrmLight := HPen():Add( PS_SOLID, 1, hwg_Getsyscolor( COLOR_3DHILIGHT ) )
      ppnOldPen := hwg_Selectobject( dc, pnFrmDark:Handle )
      hwg_Moveto( dc, rcText[ 1 ] - 2, rcText[ 2 ]  )
      hwg_Lineto( dc, rc[ 1 ], rcText[ 2 ] )
      hwg_Lineto( dc, rc[ 1 ], rc[ 4 ] )
      hwg_Lineto( dc, rc[ 3 ], rc[ 4 ] )
      hwg_Lineto( dc, rc[ 3 ], rcText[ 4 ] )
      hwg_Lineto( dc, rcText[ 3 ], rcText[ 4 ] )
      hwg_Selectobject( dc, pnFrmLight:handle )
      hwg_Moveto( dc, rcText[ 1 ] - 2, rcText[ 2 ] + 1 )
      hwg_Lineto( dc, rc[ 1 ] + 1, rcText[ 2 ] + 1 )
      hwg_Lineto( dc, rc[ 1 ] + 1, rc[ 4 ] - 1 )
      hwg_Lineto( dc, rc[ 3 ] - 1, rc[ 4 ] - 1 )
      hwg_Lineto( dc, rc[ 3 ] - 1, rcText[ 4 ] + 1 )
      hwg_Lineto( dc, rcText[ 3 ], rcText[ 4 ] + 1 )
   ELSE // 3D frame
      pnFrmDark  := HPen():Add( PS_SOLID, 1, hwg_Getsyscolor( COLOR_3DSHADOW ) )
      pnFrmLight := HPen():Add( PS_SOLID, 1, hwg_Getsyscolor( COLOR_3DHILIGHT ) )
      ppnOldPen := hwg_Selectobject( dc, pnFrmDark:handle )
      hwg_Moveto( dc, rcText[ 1 ] - 2, rcText[ 2 ] )
      hwg_Lineto( dc, rc[ 1 ], rcText[ 2 ] )
      hwg_Lineto( dc, rc[ 1 ], rc[ 4 ] - 1 )
      hwg_Lineto( dc, rc[ 3 ] - 1, rc[ 4 ] - 1 )
      hwg_Lineto( dc, rc[ 3 ] - 1, rcText[ 4 ] )
      hwg_Lineto( dc, rcText[ 3 ], rcText[ 4 ] )
      hwg_Selectobject( dc, pnFrmLight:handle )
      hwg_Moveto( dc, rcText[ 1 ] - 2, rcText[ 2 ] + 1 )
      hwg_Lineto( dc, rc[ 1 ] + 1, rcText[ 2 ] + 1 )
      hwg_Lineto( dc, rc[ 1 ] + 1, rc[ 4 ] - 1 )
      hwg_Moveto( dc, rc[ 1 ], rc[ 4 ] )
      hwg_Lineto( dc, rc[ 3 ], rc[ 4 ] )
      hwg_Lineto( dc, rc[ 3 ], rcText[ 4 ] - 1 )
      hwg_Moveto( dc, rc[ 3 ] - 2, rcText[ 4 ] + 1 )
      hwg_Lineto( dc, rcText[ 3 ], rcText[ 4 ] + 1 )
   ENDIF
   // draw text (if any)
   IF !Empty( szText )
      hwg_Setbkmode( dc, TRANSPARENT )
      IF ::oBrush != NIL
         hwg_Fillrect( DC, rc[ 1 ] + 2, rc[ 2 ] + iUpDist + 2 , rc[ 3 ] - 2, rc[ 4 ] - 2 , ::brush:handle )
         IF ! ::lTransparent
            hwg_Fillrect( DC, rcText[ 1 ] - 2, rc[ 2 ] + 1 ,  rcText[ 3 ] + 1, rc[ 2 ] + iUpDist + 2 , ::brush:handle )
         ENDIF
      ENDIF
      hwg_Drawtext( dc, szText, rcText, DT_VCENTER + DT_LEFT + DT_SINGLELINE + DT_NOCLIP )
   ENDIF
   // cleanup
   hwg_Deleteobject( pnFrmLight )
   hwg_Deleteobject( pnFrmDark )
   hwg_Selectobject( dc, ppnOldPen )

   RETURN NIL

   INIT PROCEDURE starttheme()
   hwg_Initthemelib()

   EXIT PROCEDURE endtheme()
   hwg_Endthemelib()

CLASS HStatusEx INHERIT HControl

CLASS VAR winclass   INIT "msctls_statusbar32"

   DATA aParts
   DATA nStatusHeight   INIT 0
   DATA bDblClick
   DATA bRClick

   METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint, bRClick, bDblClick, nHeight )
   METHOD Activate()
   METHOD Init()
   METHOD Notify( lParam )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                    bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )
   METHOD SetText( cText,nPart ) INLINE  hwg_WriteStatus( ::oParent, nPart, cText )
   METHOD SetTextPanel( nPart, cText, lRedraw )
   METHOD GetTextPanel( nPart )
   METHOD SetIconPanel( nPart, cIcon, nWidth, nHeight )
   METHOD StatusHeight( nHeight )
   METHOD Resize( xIncrSize )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint, bRClick, bDblClick, nHeight ) CLASS HStatusEx

   bSize  := IIf( bSize != NIL, bSize, { | o, x, y | o:Move( 0, y - ::nStatusHeight, x, ::nStatusHeight ) } )
   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
                        WS_CHILD + WS_VISIBLE + WS_OVERLAPPED + WS_CLIPSIBLINGS )
   ::Super:New( oWndParent, nId, nStyle, 0, 0, 0, 0, oFont, bInit, bSize, bPaint )

   ::nStatusHeight := IIF( nHeight = Nil, ::nStatusHeight, nHeight )
   ::aParts    := aParts
   ::bDblClick := bDblClick
   ::bRClick   := bRClick

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HStatusEx

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_CreateStatusWindow( ::oParent:handle, ::id )
      ::StatusHeight( ::nStatusHeight )
      ::Init()
   ENDIF
   RETURN NIL

METHOD Init() CLASS HStatusEx
   IF ! ::lInit
      IF ! Empty( ::aParts )
         hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
      ENDIF
      ::Super:Init()
   ENDIF
   RETURN  NIL

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )  CLASS HStatusEx

   HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::aParts := aParts
   RETURN Self

METHOD Notify( lParam ) CLASS HStatusEx

LOCAL nCode := hwg_GetNotifyCode( lParam )
LOCAL nParts := hwg_GetNotifySBParts( lParam ) - 1

#define NM_DBLCLK               (NM_FIRST-3)
#define NM_RCLICK               (NM_FIRST-5)    // uses NMCLICK struct
#define NM_RDBLCLK              (NM_FIRST-6)

   DO CASE
      CASE nCode == NM_CLICK

      CASE nCode == NM_DBLCLK
          IF ::bdblClick != Nil
              Eval( ::bdblClick, Self, nParts )
          ENDIF
      CASE nCode == NM_RCLICK
         IF ::bRClick != Nil
             Eval( ::bRClick, Self, nParts )
         ENDIF
   ENDCASE
   RETURN Nil

METHOD StatusHeight( nHeight  ) CLASS HStatusEx
   LOCAL aCoors

   IF nHeight != Nil
      aCoors := hwg_GetWindowRect( ::handle )
      IF nHeight != 0
         IF  ::lInit .AND. __ObjHasMsg( ::oParent, "AOFFSET" )
            ::oParent:aOffset[ 4 ] -= ( aCoors[ 4 ] - aCoors[ 2 ] )
         ENDIF
         hwg_SendMessage( ::handle,;           // (HWND) handle to destination control
                SB_SETMINHEIGHT, nHeight, 0 )      // (UINT) message ID  // = (WPARAM)(int) minHeight;
         hwg_SendMessage( ::handle, WM_SIZE, 0, 0 )
         aCoors := hwg_GetWindowRect( ::handle )
      ENDIF
      ::nStatusHeight := ( aCoors[ 4 ] - aCoors[ 2 ] ) - 1
      IF __ObjHasMsg( ::oParent, "AOFFSET" )
         ::oParent:aOffset[ 4 ] += ( aCoors[ 4 ] - aCoors[ 2 ]  )
      ENDIF
   ENDIF
   RETURN ::nStatusHeight

METHOD GetTextPanel( nPart ) CLASS HStatusEx
   LOCAL ntxtLen, cText := ""

   ntxtLen := hwg_SendMessage( ::handle, SB_GETTEXTLENGTH, nPart - 1, 0 )
   cText := Replicate( Chr( 0 ), ntxtLen )
   hwg_SendMessage( ::handle, SB_GETTEXT, nPart - 1, @cText )
   RETURN cText

METHOD SetTextPanel( nPart, cText, lRedraw ) CLASS HStatusEx
   hwg_SendMessage( ::handle, SB_SETTEXT, nPart - 1, cText )
   IF lRedraw != Nil .AND. lRedraw
      hwg_RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

   RETURN Nil

METHOD SetIconPanel( nPart, cIcon, nWidth, nHeight ) CLASS HStatusEx
   Local oIcon

   DEFAULT nWidth := 16
   DEFAULT nHeight := 16
   DEFAULT cIcon := ""

   IF HB_IsNumeric( cIcon ) .OR. At( ".", cIcon ) = 0
      oIcon := HIcon():addResource( cIcon, nWidth, nHeight )
   ELSE
      oIcon := HIcon():addFile( cIcon, nWidth, nHeight )
    ENDIF
    IF ! EMPTY( oIcon )
      hwg_SendMessage( ::handle, SB_SETICON, nPart - 1, oIcon:handle )
   ENDIF

   RETURN Nil

METHOD Resize( xIncrSize ) CLASS HStatusEx
   LOCAL i

   IF ! Empty( ::aParts )
      FOR i := 1 TO LEN( ::aParts )
         ::aParts[ i ] := ROUND( ::aParts[ i ] * xIncrSize, 0 )
      NEXT
      hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
   ENDIF
   RETURN NIL
