/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HRichEdit class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

CLASS HRichEdit INHERIT HControl

#ifdef UNICODE
   CLASS VAR winclass INIT "RichEdit20W"
#else
   CLASS VAR winclass INIT "RichEdit20A"
#endif
   DATA lChanged   INIT .F.
   DATA lSetFocus  INIT .T.
   DATA lAllowTabs INIT .F.
   DATA lctrltab   HIDDEN
   DATA lReadOnly  INIT .F.
   DATA Col        INIT 0
   DATA Line       INIT 0
   DATA LinesTotal INIT 0
   DATA SelStart   INIT 0
   DATA SelText    INIT 0
   DATA SelLength  INIT 0
   DATA bChange

   METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bGfocus, bLfocus, ctooltip, ;
      tcolor, bcolor, bOther, lAllowTabs, bChange, lnoBorder )

   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD When()
   METHOD Valid()
   METHOD UpdatePos( )
   METHOD onChange( )
   METHOD ReadOnly( lreadOnly ) SETGET
   METHOD Setcolor( tColor, bColor, lRedraw )

ENDCLASS

METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bGfocus, bLfocus, ctooltip, ;
      tcolor, bcolor, bOther, lAllowTabs, bChange, lnoBorder ) CLASS HRichEdit

   nStyle := Hwg_BitOr( iif( nStyle == Nil, 0, nStyle ), WS_CHILD + WS_VISIBLE + WS_TABSTOP + ;
         iif( lNoBorder = Nil .OR. ! lNoBorder, WS_BORDER, 0 ) )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize,, ctooltip, tcolor, iif( bcolor == Nil, hwg_Getsyscolor( COLOR_BTNHIGHLIGHT ), bcolor ) )

   ::title  := vari
   ::bOther := bOther
   ::bChange := bChange
   ::lAllowTabs := iif( Empty( lAllowTabs ), ::lAllowTabs, lAllowTabs )
   ::lReadOnly := Hwg_BitAnd( nStyle, ES_READONLY ) != 0

   hwg_InitRichEdit()

   ::Activate()

   IF bGfocus != Nil
      ::bGetFocus := bGfocus
      ::oParent:AddEvent( EN_SETFOCUS, ::id, {|o|::When(o)} )
   ENDIF
   IF bLfocus != Nil
      ::bLostFocus := bLfocus
      ::oParent:AddEvent( EN_KILLFOCUS, ::id, {|o|::Valid(o)} )
   ENDIF

   RETURN Self

METHOD Activate() CLASS HRichEdit

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createrichedit( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init()  CLASS HRichEdit

   IF !::lInit
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitRichProc( ::handle )
      ::Super:Init()
      ::Setcolor( ::tColor, ::bColor )
      IF ::bChange != Nil
         hwg_Sendmessage( ::handle, EM_SETEVENTMASK, 0, ENM_SELCHANGE + ENM_CHANGE )
         ::oParent:AddEvent( EN_CHANGE, ::id, {||::onChange()} )
      ENDIF
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HRichEdit

   LOCAL nDelta

   /* NOTE: contract for ::bOther - it must return a Number <= -1 to mean
    * "not handled, continue with default processing below". Any other
    * return value (including no explicit RETURN, which yields NIL) short-
    * circuits this whole onEvent() - Tab handling, ESC-to-close, the
    * position/selection tracking, everything below - so a bOther block
    * that doesn't RETURN a negative number will silently disable all of
    * that default behaviour. */
   IF ::bOther != Nil
      nDelta := Eval( ::bOther, Self, msg, wParam, lParam )
      IF ValType( nDelta ) != "N" .OR. nDelta > - 1
         RETURN nDelta
      ENDIF
   ENDIF
   IF msg = WM_KEYUP .OR. msg == WM_LBUTTONDOWN .OR. msg == WM_LBUTTONUP // msg = WM_NOTIFY .OR.
      ::updatePos()
   ELSEIF msg == WM_CHAR
      wParam := hwg_PtrToUlong( wParam )
      IF wParam = VK_TAB
         IF  ( hwg_IsCtrlShift( .T. , .F. ) .OR. ! ::lAllowTabs )
            RETURN 0
         ENDIF
      ENDIF
      IF !hwg_IsCtrlShift( .T. , .F. )
         ::lChanged := .T.
      ENDIF
   ELSEIF msg == WM_KEYDOWN
      wParam := hwg_PtrToUlong( wParam )
      IF wParam = VK_TAB .AND. ( hwg_IsCtrlShift( .T. , .F. ) .OR. ! ::lAllowTabs )
         hwg_GetSkip( ::oParent, ::handle, ;
            iif( hwg_IsCtrlShift( .F. , .T. ), - 1, 1 ) )
         RETURN 0
      ELSEIF wParam = VK_TAB
         hwg_Re_inserttext( ::handle, Chr( VK_TAB ) )
         RETURN 0
      ELSEIF wParam == 27 // ESC
         /* FIX: was 'hwg_Getparent(...) != Nil'. If hwg_Getparent() wraps
          * Win32 GetParent(), it returns 0 (a Number), not the Harbour
          * NIL, when there is no parent window - so '!= Nil' would be
          * true even with no parent, sending WM_CLOSE to handle 0 (Win32
          * undefined behaviour for that call). Empty() safely covers both
          * NIL and 0, without changing behaviour for the case that already
          * worked (a real, non-zero handle). */
         IF !Empty( hwg_Getparent( ::oParent:handle ) )
            hwg_Sendmessage( hwg_Getparent( ::oParent:handle ), WM_CLOSE, 0, 0 )
         ENDIF
      ENDIF

      IF wParam == 46     // Del
         ::lChanged := .T.
      ENDIF
   ELSEIF msg == WM_MOUSEWHEEL
      nDelta := hwg_Hiword( wParam )
      /* FIX: off-by-one in the unsigned-to-signed 16-bit conversion - was
       * 'nDelta > 32768 ? nDelta - 65535 : nDelta', should be
       * 'nDelta >= 32768 ? nDelta - 65536 : nDelta' (standard two's
       * complement conversion). Doesn't currently change observable
       * behaviour since real wheel deltas are always multiples of 120 and
       * only the sign of nDelta is used below, but the old formula was
       * off by one at both the boundary (32768) and the value itself. */
      nDelta := iif( nDelta >= 32768, nDelta - 65536, nDelta )
      /* FIX: this hwg_Sendmessage(EM_SCROLL,...) call was duplicated
       * verbatim (copy-paste), causing every mouse wheel notch to scroll
       * the rich edit twice as far as intended. Removed the duplicate. */
      hwg_Sendmessage( ::handle, EM_SCROLL, iif( nDelta > 0,SB_LINEUP,SB_LINEDOWN ), 0 )
   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

   RETURN -1

METHOD Setcolor( tColor, bColor, lRedraw )  CLASS HRichEdit

   IF tcolor != Nil
      hwg_re_SetDefault( ::handle, tColor )
   ENDIF
   IF bColor != Nil
      hwg_Sendmessage( ::Handle, EM_SETBKGNDCOLOR, 0, bColor )
   ENDIF
   ::Super:Setcolor( tColor, bColor, lRedraw )

   RETURN Nil

METHOD ReadOnly( lreadOnly ) CLASS HRichEdit
   /* FIX: this method was missing the 'CLASS HRichEdit' clause that every
    * other out-of-body method implementation in this file has. Without it,
    * the Harbour class-body compiler can't bind this implementation to the
    * METHOD ReadOnly(...) SETGET slot declared inside CLASS HRichEdit -
    * ::ReadOnly / ::ReadOnly := ... (which is exactly what SETGET is for)
    * would be broken, and depending on the compiler/version this could
    * either fail to build or silently fall back to an unrelated global
    * function named ReadOnly. */

   IF lreadOnly != Nil
      IF ! Empty( hwg_Sendmessage( ::handle,  EM_SETREADONLY, iif( lReadOnly, 1, 0 ), 0 ) )
         ::lReadOnly := lReadOnly
      ENDIF
   ENDIF

   RETURN ::lReadOnly

METHOD UpdatePos( ) CLASS HRichEdit

   LOCAL npos := hwg_Sendmessage( ::handle, EM_GETSEL, 0, 0 )
   LOCAL pos1 := hwg_Loword( npos ) + 1,   pos2 := hwg_Hiword( npos ) + 1

   ::Line := hwg_Sendmessage( ::Handle, EM_LINEFROMCHAR, pos1 - 1, 0 ) + 1
   ::LinesTotal := hwg_Sendmessage( ::handle, EM_GETLINECOUNT, 0, 0 )
   ::SelText := hwg_Re_gettextrange( ::handle, pos1, pos2 )
   ::SelStart := pos1
   ::SelLength := pos2 - pos1
   ::Col := pos1 - hwg_Sendmessage( ::Handle, EM_LINEINDEX, - 1, 0 )

   RETURN nPos

METHOD onChange( ) CLASS HRichEdit

   IF ::bChange != Nil
      Eval( ::bChange, ::gettext(), Self  )
   ENDIF

   RETURN Nil

METHOD When( ) CLASS HRichEdit

   ::title := ::GetText()
   Eval( ::bGetFocus, ::title, Self )

   RETURN .T.

METHOD Valid( ) CLASS HRichEdit

   ::title := ::GetText()
   Eval( ::bLostFocus, ::title, Self )

   RETURN .T.
