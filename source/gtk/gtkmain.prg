/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Main prg level functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"

FUNCTION hwg_MsgGet( cTitle, cText, nStyle, x, y, nDlgStyle, cRes )

   LOCAL oModDlg, oFont := HFont():Add( "Sans", 0, 12 )

   IF Empty( cRes )
      cRes := ""
   ENDIF

   nStyle := iif( nStyle == Nil, 0, nStyle )
   x := iif( x == Nil, 210, x )
   y := iif( y == Nil, 10, y )
   nDlgStyle := iif( nDlgStyle == Nil, 0, nDlgStyle )

   INIT DIALOG oModDlg TITLE cTitle AT x, y SIZE 300, 140 ;
      FONT oFont CLIPPER STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + nDlgStyle

   IF !Empty( cText )
      @ 20, 10 SAY cText SIZE 260, 22
   ENDIF
   @ 20, 35 GET cres  SIZE 260, 26 STYLE WS_DLGFRAME + WS_TABSTOP + nStyle
   Atail( oModDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 20, 95 BUTTON "Ok" ID IDOK SIZE 100, 32 ON CLICK { ||oModDlg:lResult := .T. , hwg_EndDialog() } ON SIZE ANCHOR_BOTTOMABS
   @ 180, 95 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ON CLICK { ||hwg_EndDialog() } ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oModDlg

   oFont:Release()
   IF oModDlg:lResult
      RETURN Trim( cRes )
   ELSE
      cRes := ""
   ENDIF

   RETURN cRes

FUNCTION hwg_WChoice( arr, cTitle, nLeft, nTop, oFont, clrT, clrB, clrTSel, clrBSel, cOk, cCancel,nwline )

   LOCAL oDlg, oBrw, lNewFont := .F.
   LOCAL nChoice := 0, i, aLen := Len( arr ), nLen := 0, addX := 20, addY := 20, minWidth := 0, x1
   LOCAL hDC, aMetr, width, height
   // LOCAL aArea, aRect
   LOCAL screenh

   IF cTitle == Nil; cTitle := ""; ENDIF
   IF nLeft == Nil; nLeft := 10; ENDIF
   IF nTop == Nil; nTop := 10; ENDIF
   IF oFont == Nil
      oFont := HFont():Add( "Times", 0, 14 )
      lNewFont := .T.
   ENDIF
   IF nwline == NIL ; nwline := 21 ; ENDIF  && Ticket 90
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

   * hDC := hwg_Getdc( HWindow():GetMain():handle )
   * DF7BE: Ticket #90:
   * crashes with "No exported method: HANDLE"
   hDC := hwg_Getdc( HWindow():GetMain() )

   hwg_Selectobject( hDC, ofont:handle )
   aMetr := hwg_Gettextmetric( hDC )
 
   // aRect := hwg_Getwindowrect( hwg_Getactivewindow() )
   
   hwg_Releasedc( hwg_Getactivewindow(), hDC )
   
   // aArea := hwg_Getdevicearea( hDC )  /* Copied from WinAPI */
   
   // hwg_WriteLog("addY=" + ALLTRIM(STR(addY)) )
   
   // height := ( aMetr[1] + 5 ) * aLen + 4 + addY
   * New formula, because of bug in GTK (Ticket 90)
   height := ( nwline + 5 ) * aLen + 4 + addY
   
    screenh := hwg_Getdesktopheight()
   
    IF height > screenh * 2/3
      height := Int( screenh * 2/3 )
 //     addX := addY := 0
   ENDIF


   width := Max( minWidth, aMetr[2] * 2 * nLen + addX )
   
//   hwg_WriteLog("width="+ ALLTRIM(STR(width)) + CHR(10) + ;
//      "height=" + ALLTRIM(STR(height)) + CHR(10) + ;
//      "aMetr[1]=" + ALLTRIM(STR(aMetr[1]))  + CHR(10) + ;
//      "aMetr[2]=" + ALLTRIM(STR(aMetr[2]))  + CHR(10) + ;
//      "aArea[2]=" + ALLTRIM(STR(aArea[2]))  + CHR(10) + ;
//      "aRect[2]=" + ALLTRIM(STR(aRect[2]))  + CHR(10) + ;
//      "aLen=" + ALLTRIM(STR(aLen))          + CHR(10) + ;
//      "nLen=" + ALLTRIM(STR(nLen))          + CHR(10) + ;
//      "addY=" + ALLTRIM(STR(addY)) ;
//      )
 
   // height:= 150 && Is OK vor array with 3 elements.

   INIT DIALOG oDlg TITLE cTitle ;
      AT nLeft, nTop           ;
      SIZE width, height       ;
      FONT oFont

   @ 0, 0 BROWSE oBrw ARRAY        ;
      SIZE  width, height - addY   ;
      FONT oFont                   ;
      STYLE WS_BORDER              ;
      ON SIZE {|o,x,y|o:Move( addX/2, 10, x - addX, y - addY )} ;
      ON CLICK { |o|nChoice := o:nCurrent, hwg_EndDialog( o:oParent:handle ) }

   IF ValType( arr[1] ) == "A"
      oBrw:AddColumn( HColumn():New( ,{ |value,o| HB_SYMBOL_UNUSED ( value ) , o:aArray[o:nCurrent,1] },"C",nLen ) )
   ELSE
      oBrw:AddColumn( HColumn():New( ,{ |value,o| HB_SYMBOL_UNUSED ( value ) ,o:aArray[o:nCurrent] },"C",nLen ) )
   ENDIF
   hwg_CREATEARLIST( oBrw, arr )
   oBrw:lDispHead := .F.
   IF clrT != Nil
      oBrw:tcolor := clrT
   ENDIF
   IF clrB != Nil
      oBrw:bcolor := clrB
   ENDIF
   IF clrTSel != Nil
      oBrw:tcolorSel := clrTSel
   ENDIF
   IF clrBSel != Nil
      oBrw:bcolorSel := clrBSel
   ENDIF

   IF cOk != Nil
      x1 := Int( width/2 ) - iif( cCancel != Nil, 90, 40 )
      @ x1, height - 36 BUTTON cOk SIZE 80, 30 ;
            ON CLICK { ||nChoice := oBrw:nCurrent, hwg_EndDialog( oDlg:handle ) } ;
            ON SIZE ANCHOR_BOTTOMABS
      IF cCancel != Nil
         @ x1 + 100, height - 36 BUTTON cCancel SIZE 80, 30 ;
            ON CLICK { ||hwg_EndDialog( oDlg:handle ) } ;
            ON SIZE ANCHOR_BOTTOMABS
      ENDIF
   ENDIF

   oDlg:Activate()
   IF lNewFont
      oFont:Release()
   ENDIF  &&   addX := addY := 0

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
   IF ( i := Ascan( aControls, { |o|o:ClassName() == "HSTATUS" } ) ) > 0
      hwg_Writestatuswindow( aControls[i]:handle, 0, cText )
   ELSEIF ( i := Ascan( aControls, { |o|o:ClassName() = "HPANELSTS" } ) ) > 0
      aControls[i]:Write( cText, nPart )
   ENDIF

   RETURN Nil

FUNCTION HWG_ISWINDOWVISIBLE( handle )

   LOCAL o := hwg_GetWindowObject( handle )

   IF o != Nil .AND. o:lHide
      RETURN .F.
   ENDIF

   RETURN .T.
