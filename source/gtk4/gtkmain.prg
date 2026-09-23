/*
 * $Id: gtkmain.prg 3790 2025-08-19 15:24:08Z df7be $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Main prg level functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTES
 * -----
 *  - This file is intentionally 99% platform-agnostic: it only relies on
 *    Harbour-level HWGUI constructs (INIT DIALOG, @ SAY/GET/BUTTON,
 *    ACTIVATE DIALOG) which do not change between GTK2/GTK3/GTK4.
 *
 *  - hwg_Getdc() in GTK4 creates an offscreen Cairo image surface the
 *    size of the target widget.  When the widget is not yet realized
 *    (0x0), the surface is created in error state, but Pango text
 *    metrics keep working because they do not touch the surface.
 *    In hwg_WChoice() we obtain metrics only, so this is safe as long
 *    as the main window has already been shown at least once.
 *
 *  - hwg_Getdesktopheight() now returns the height of the *primary*
 *    GdkMonitor in GTK4 (C side).  Multi-monitor setups may need a
 *    different policy — override in the C if needed.
 */

#include "hwgui.ch"

FUNCTION hwg_MsgGet( cTitle, cText, nStyle, x, y, nDlgStyle, cRes )

   LOCAL oModDlg, oFont := HFont():Add( "Sans", 0, 12 )

   IF Empty( cRes )
      cRes := ""
   ENDIF

   nStyle    := iif( nStyle    == Nil, 0,  nStyle )
   x         := iif( x         == Nil, 210, x )
   y         := iif( y         == Nil, 10,  y )
   nDlgStyle := iif( nDlgStyle == Nil, 0,  nDlgStyle )

   INIT DIALOG oModDlg TITLE cTitle AT x, y SIZE 300, 140 ;
      FONT oFont CLIPPER STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + nDlgStyle

   IF !Empty( cText )
      @ 20, 10 SAY cText SIZE 260, 22
   ENDIF
   @ 20, 35 GET cRes  SIZE 260, 26 STYLE WS_DLGFRAME + WS_TABSTOP + nStyle
   Atail( oModDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 20,  95 BUTTON "Ok"     ID IDOK     SIZE 100, 32 ;
       ON CLICK { || oModDlg:lResult := .T., hwg_EndDialog() } ;
       ON SIZE  ANCHOR_BOTTOMABS
   @ 180, 95 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ;
       ON CLICK { || hwg_EndDialog() } ;
       ON SIZE  ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oModDlg

   oFont:Release()

   IF oModDlg:lResult
      RETURN Trim( cRes )
   ENDIF

   RETURN ""


FUNCTION hwg_WChoice( arr, cTitle, nLeft, nTop, oFont, clrT, clrB, ;
                      clrTSel, clrBSel, cOk, cCancel, nwline )

   LOCAL oDlg, oBrw, lNewFont := .F.
   LOCAL nChoice := 0, i, aLen := Len( arr ), nLen := 0
   LOCAL addX := 20, addY := 20, minWidth := 0, x1
   LOCAL hDC, aMetr, width, height
   LOCAL screenh

   IF cTitle == Nil ; cTitle := ""  ; ENDIF
   IF nLeft   == Nil ; nLeft   := 10 ; ENDIF
   IF nTop    == Nil ; nTop    := 10 ; ENDIF
   IF oFont   == Nil
      oFont := HFont():Add( "Times", 0, 14 )
      lNewFont := .T.
   ENDIF
   IF nwline  == Nil ; nwline  := 21 ; ENDIF   && Ticket 90

   IF cOk != Nil
      minWidth += 120
      IF cCancel != Nil
         minWidth += 100
      ENDIF
      addY += 36
   ENDIF

   IF ValType( arr[1] ) == "A"
      FOR i := 1 TO aLen
         nLen := Max( nLen, Len( arr[i,1] ) )
      NEXT
   ELSE
      FOR i := 1 TO aLen
         nLen := Max( nLen, Len( arr[i] ) )
      NEXT
   ENDIF

   /*
    * GTK4 NOTE:
    *   hwg_Getdc() in GTK4 creates an offscreen cairo image surface and
    *   a PangoLayout on it.  Only the *metrics* of the selected font are
    *   read here, and those do not depend on the surface, so this works
    *   even before the main window has been resized.
    *
    *   The call to hwg_Getdc( HWindow():GetMain() ) is kept as-is for
    *   compatibility; the crash on ":handle" mentioned in the original
    *   code was a pre-existing Harbour-side issue, unrelated to GTK.
    */
   hDC := hwg_Getdc( HWindow():GetMain() )

   hwg_Selectobject( hDC, oFont:handle )
   aMetr := hwg_Gettextmetric( hDC )

   hwg_Releasedc( hwg_Getactivewindow(), hDC )

   /*
    * New formula (Ticket 90) — no longer depends on the DC height,
    * which in GTK4 has no 1:1 relation to the widget metrics.
    */
   height := ( nwline + 5 ) * aLen + 4 + addY

   screenh := hwg_Getdesktopheight()

   IF height > screenh * 2 / 3
      height := Int( screenh * 2 / 3 )
   ENDIF

   width := Max( minWidth, aMetr[2] * 2 * nLen + addX )

   INIT DIALOG oDlg TITLE cTitle ;
      AT nLeft, nTop           ;
      SIZE width, height       ;
      FONT oFont

   @ 0, 0 BROWSE oBrw ARRAY        ;
      SIZE  width, height - addY   ;
      FONT  oFont                  ;
      STYLE WS_BORDER              ;
      ON SIZE  { |o,x,y| o:Move( addX/2, 10, x - addX, y - addY ) } ;
      ON CLICK { |o| nChoice := o:nCurrent, hwg_EndDialog( o:oParent:handle ) }

   IF ValType( arr[1] ) == "A"
      oBrw:AddColumn( HColumn():New( , ;
         { |value,o| HB_SYMBOL_UNUSED( value ), o:aArray[o:nCurrent,1] }, ;
         "C", nLen ) )
   ELSE
      oBrw:AddColumn( HColumn():New( , ;
         { |value,o| HB_SYMBOL_UNUSED( value ), o:aArray[o:nCurrent] }, ;
         "C", nLen ) )
   ENDIF

   hwg_CREATEARLIST( oBrw, arr )
   oBrw:lDispHead := .F.

   IF clrT    != Nil ; oBrw:tcolor    := clrT    ; ENDIF
   IF clrB    != Nil ; oBrw:bcolor    := clrB    ; ENDIF
   IF clrTSel != Nil ; oBrw:tcolorSel := clrTSel ; ENDIF
   IF clrBSel != Nil ; oBrw:bcolorSel := clrBSel ; ENDIF

   IF cOk != Nil
      x1 := Int( width / 2 ) - iif( cCancel != Nil, 90, 40 )

      @ x1, height - 36 BUTTON cOk SIZE 80, 30 ;
            ON CLICK { || nChoice := oBrw:nCurrent, hwg_EndDialog( oDlg:handle ) } ;
            ON SIZE  ANCHOR_BOTTOMABS

      IF cCancel != Nil
         @ x1 + 100, height - 36 BUTTON cCancel SIZE 80, 30 ;
            ON CLICK { || hwg_EndDialog( oDlg:handle ) } ;
            ON SIZE  ANCHOR_BOTTOMABS
      ENDIF
   ENDIF

   oDlg:Activate()

   IF lNewFont
      oFont:Release()
   ENDIF

   RETURN nChoice


FUNCTION HWG_Version( n )

   IF !Empty( n )
      IF n == 1
         RETURN HWG_VERSION
      ELSEIF n == 2
         RETURN HWG_BUILD
      ELSEIF n == 3
         RETURN 1
      ELSEIF n == 4
         RETURN 1
      ENDIF
   ENDIF

   RETURN "HWGUI " + HWG_VERSION + " Build " + LTrim( Str( HWG_BUILD ) )


FUNCTION hwg_WriteStatus( oWnd, nPart, cText )

   LOCAL aControls, i

   aControls := oWnd:aControls

   IF ( i := Ascan( aControls, { |o| o:ClassName() == "HSTATUS" } ) ) > 0
      hwg_Writestatuswindow( aControls[i]:handle, 0, cText )
   ELSEIF ( i := Ascan( aControls, { |o| o:ClassName() = "HPANELSTS" } ) ) > 0
      aControls[i]:Write( cText, nPart )
   ENDIF

   RETURN Nil


FUNCTION HWG_ISWINDOWVISIBLE( handle )

   LOCAL o := hwg_GetWindowObject( handle )

   IF o != Nil .AND. o:lHide
      RETURN .F.
   ENDIF

   RETURN .T.
