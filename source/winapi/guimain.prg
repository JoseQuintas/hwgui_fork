/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Main prg level functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"

#ifdef __XHARBOUR__
#xtranslate hb_processOpen([<x,...>])   => hb_openProcess(<x>)
#xtranslate hb_NumToHex([<n,...>])      => NumToHex(<n>)
#endif

FUNCTION hwg_InitControls( oWnd, lNoActivate )

   LOCAL i, pArray := oWnd:aControls, lInit

   lNoActivate := iif( lNoActivate == Nil, .F. , lNoActivate )
   IF pArray != Nil
      FOR i := 1 TO Len( pArray )
         // writelog( "InitControl1"+str(pArray[i]:handle)+"/"+pArray[i]:classname+" "+str(pArray[i]:nWidth)+"/"+str(pArray[i]:nHeight) )
         IF Empty( pArray[i]:handle ) .AND. !lNoActivate
            lInit := pArray[i]:lInit
            pArray[i]:lInit := .T.
            pArray[i]:Activate()
            pArray[i]:lInit := lInit
         ENDIF
         IF IIF( ValType( pArray[ i ]:handle ) == "P", hwg_Ptrtoulong( pArray[ i ]:handle ), pArray[ i ]:handle ) <= 0
         //IF Empty( pArray[i]:handle ) .OR. hwg_isPtrneg1( pArray[i]:handle )
            pArray[i]:handle := hwg_Getdlgitem( oWnd:handle, pArray[i]:id )
            // writelog( "InitControl2"+str(pArray[i]:handle)+"/"+pArray[i]:classname )
         ENDIF
         IF !Empty( pArray[i]:aControls )
            hwg_InitControls( pArray[i] )
         ENDIF
         pArray[i]:Init()
      NEXT
   ENDIF

   RETURN .T.

FUNCTION hwg_WriteStatus( oWnd, nPart, cText, lRedraw )

   LOCAL aControls, i

   IF oWnd == Nil
      oWnd := HWindow():GetMain()
   ENDIF
   aControls := oWnd:aControls
   IF ( i := Ascan( aControls, { |o|o:ClassName() = "HSTATUS" } ) ) > 0
      hwg_SendMessage( aControls[i]:handle, SB_SETTEXT, Iif(nPart==Nil,0,nPart-1), cText )
      IF lRedraw != Nil .AND. lRedraw
         hwg_Redrawwindow( aControls[i]:handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ELSEIF ( i := Ascan( aControls, { |o|o:ClassName() = "HPANELSTS" } ) ) > 0
      aControls[i]:Write( cText, nPart, lRedraw )
   ENDIF

   RETURN Nil

FUNCTION hwg_MsgGet( cTitle, cText, nStyle, x, y, nDlgStyle, cRes )

   LOCAL oDlg, oFont := HFont():Add( "MS Sans Serif", 0, - 13 )

   IF Empty( cRes )
      cRes := ""
   ENDIF

   nStyle := iif( nStyle == Nil, 0, nStyle )
   x := iif( x == Nil, 210, x )
   y := iif( y == Nil, 10, y )
   nDlgStyle := iif( nDlgStyle == Nil, 0, nDlgStyle )

   INIT DIALOG oDlg TITLE cTitle AT x, y SIZE 300, 140 ;
      FONT oFont CLIPPER STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + nDlgStyle

   IF !Empty( cText )
      @ 20, 10 SAY cText SIZE 260, 22
   ENDIF
   @ 20, 35 GET cres  SIZE 260, 26 STYLE WS_TABSTOP + nStyle MAXLENGTH 0
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 20, 95 BUTTON "Ok" ID IDOK SIZE 100, 32 ON SIZE ANCHOR_BOTTOMABS
   @ 180, 95 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32 ON SIZE ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oDlg

   oFont:Release()
   IF oDlg:lResult
      RETURN Trim( cRes )
   ELSE
      cRes := ""
   ENDIF

   RETURN cRes

FUNCTION hwg_WChoice( arr, cTitle, nLeft, nTop, oFont, clrT, clrB, clrTSel, clrBSel, cOk, cCancel , nwline )

   LOCAL oDlg, oBrw, nChoice := 0, lArray := .T. , nField, lNewFont := .F.
   LOCAL i, aLen, nLen := 0, addX := 20, addY := 20, minWidth := 0, x1
   LOCAL hDC, aMetr, width, height, aArea, aRect
   LOCAL nStyle := WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX
   
   HB_SYMBOL_UNUSED( nwline )  && For GTK only, ignored

   IF cTitle == Nil; cTitle := ""; ENDIF
   IF nLeft == Nil .AND. nTop == Nil; nStyle += DS_CENTER; ENDIF
   IF nLeft == Nil; nLeft := 0; ENDIF
   IF nTop == Nil; nTop := 0; ENDIF
   IF oFont == Nil
      oFont := HFont():Add( "MS Sans Serif", 0, - 13 )
      lNewFont := .T.
   ENDIF
   IF cOk != Nil
      minWidth += 120
      IF cCancel != Nil
         minWidth += 100
      ENDIF
      addY += 36
   ENDIF

   IF ValType( arr ) == "C"
      lArray := .F.
      aLen := RecCount()
      IF ( nField := FieldPos( arr ) ) == 0
         RETURN 0
      ENDIF
      nLen := dbFieldInfo( 3, nField )
   ELSE
      aLen := Len( arr )
      IF ValType( arr[1] ) == "A"
         FOR i := 1 TO aLen
            nLen := Max( nLen, Len( arr[i,1] ) )
         NEXT
      ELSE
         FOR i := 1 TO aLen
            nLen := Max( nLen, Len( arr[i] ) )
         NEXT
      ENDIF
   ENDIF

   hDC := hwg_Getdc( hwg_Getactivewindow() )
   hwg_Selectobject( hDC, ofont:handle )
   aMetr := hwg_Gettextmetric( hDC )
   aArea := hwg_Getdevicearea( hDC )
   aRect := hwg_Getwindowrect( hwg_Getactivewindow() )
   hwg_Releasedc( hwg_Getactivewindow(), hDC )
   height := ( aMetr[1] + 5 ) * aLen + 4 + addY + 8
   IF height > aArea[2] - aRect[2] - nTop - 60
      height := aArea[2] - aRect[2] - nTop - 60
   ENDIF
   width := Max( aMetr[2] * 2 * nLen + 8 + addX, minWidth )

   INIT DIALOG oDlg TITLE cTitle ;
      AT nLeft, nTop           ;
      SIZE width, height       ;
      STYLE nStyle            ;
      FONT oFont              ;
      ON INIT { |o|hwg_Resetwindowpos( o:handle ), hwg_Setfocus( oBrw:handle ) }

   IF lArray
      @ addX/2, 10 BROWSE oBrw ARRAY SIZE width - addX, height - addY
      oBrw:aArray := arr
      IF ValType( arr[1] ) == "A"
         oBrw:AddColumn( HColumn():New( ,{ | value, o | ( value ), o:aArray[ o:nCurrent, 1 ] }, "C", nLen ) )
      ELSE
         oBrw:AddColumn( HColumn():New( ,{ | value, o | ( value ), o:aArray[ o:nCurrent ] }, "C", nLen ) )
      ENDIF
   ELSE
      @ addX/2, 10 BROWSE oBrw DATABASE SIZE width - addX, height - addY
      oBrw:AddColumn( HColumn():New( ,{ | value, o | ( value ), ( o:alias ) -> ( FieldGet( nField ) ) }, "C", nLen ) )
   ENDIF

   oBrw:oFont  := oFont
   oBrw:bSize  := { |o, x, y|o:Move( ,, x - addX, y - addY ) }
   oBrw:bEnter := { |o|nChoice := o:nCurrent, hwg_EndDialog( o:oParent:handle ) }
   oBrw:bKeyDown := { | o, key | ( o ), iif( key == 27, ( hwg_EndDialog( oDlg:handle ), .F. ), .T. ) }

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
      oBrw:htbColor := oBrw:bcolorSel := clrBSel
   ENDIF

   IF cOk != Nil
      x1 := Int( width/2 ) - iif( cCancel != Nil, 90, 40 )
      @ x1, height - 36 BUTTON cOk SIZE 80, 28 ON CLICK { ||nChoice := oBrw:nCurrent, hwg_EndDialog( oDlg:handle ) } ON SIZE { | o, x, y | ( x ), o:Move( , y - 36 ) }
      IF cCancel != Nil
         @ x1 + 100, height - 36 BUTTON cCancel SIZE 80, 28 ON CLICK { ||hwg_EndDialog( oDlg:handle ) } ON SIZE {|o,x,y|o:Move( x-100,y-36 ) }
      ENDIF
   ENDIF

   oDlg:Activate()
   IF lNewFont
      oFont:Release()
   ENDIF

   RETURN nChoice

FUNCTION hwg_ShowProgress( nStep, maxPos, nRange, cTitle, oWnd, x1, y1, width, height )

   LOCAL nStyle := WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX
   STATIC oDlg, hPBar, iCou, nLimit

   IF nStep == 0
      nLimit := iif( nRange != Nil, Int( nRange/maxPos ), 1 )
      iCou := 0
      x1 := iif( x1 == Nil, 0, x1 )
      y1 := iif( x1 == Nil, 0, y1 )
      width := iif( width == Nil, 220, width )
      height := iif( height == Nil, 55, height )
      IF x1 == 0
         nStyle += DS_CENTER
      ENDIF
      IF oWnd != Nil
         oDlg := Nil
         hPBar := hwg_Createprogressbar( oWnd:handle, maxPos, 20, 25, width - 40, 20 )
      ELSE
         INIT DIALOG oDlg TITLE cTitle   ;
            AT x1, y1 SIZE width, height ;
            STYLE nStyle               ;
            ON INIT { |o|hPBar := hwg_Createprogressbar( o:handle, maxPos, 20, 25, width - 40, 20 ) }
         ACTIVATE DIALOG oDlg NOMODAL
      ENDIF
   ELSEIF nStep == 1
      iCou ++
      IF iCou == nLimit
         iCou := 0
         hwg_Updateprogressbar( hPBar )
      ENDIF
   ELSEIF nStep == 2
      hwg_Updateprogressbar( hPBar )
   ELSEIF nStep == 3
      hwg_Setwindowtext( oDlg:handle, cTitle )
      IF maxPos != Nil
         hwg_Setprogressbar( hPBar, maxPos )
      ENDIF
   ELSE
      hwg_Destroywindow( hPBar )
      IF oDlg != Nil
         hwg_EndDialog( oDlg:handle )
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION hwg_HdSerial( cDrive )

   LOCAL cHex := hb_Numtohex( hwg_Hdgetserial( cDrive ) )

   RETURN SubStr( cHex, 1, 4 ) + '-' + SubStr( cHex, 5, 4 )

FUNCTION Hwg_GetIni( cSection, cEntry, cDefault, cFile )

   RETURN hwg_Getprivateprofilestring( cSection, cEntry, cDefault, cFile )

FUNCTION Hwg_WriteIni( cSection, cEntry, cValue, cFile )

   RETURN( hwg_Writeprivateprofilestring( cSection, cEntry, cValue, cFile ) )

FUNCTION hwg_SetHelpFileName ( cNewName )

   STATIC cName := ""
   LOCAL cOldName := cName

   IF cNewName <> Nil
      cName := cNewName
   ENDIF

   RETURN cOldName

FUNCTION hwg_SelectMultipleFiles( cDescr, cTip, cIniDir, cTitle )

   LOCAL aFiles, cFile, x, cFilter := "", cItem, nAt, cChar, i /* cRet */
   LOCAL hWnd := 0
   LOCAL nFlags := ""
   LOCAL cPath
   LOCAL nIndex := 1

   cFilter += cDescr + Chr( 0 ) + cTip + Chr( 0 )

   cFile := Space( 32000 )

   /* cRet := */ hwg_getopenfilename( hWnd, @cFile, cTitle, cFilter, nFlags, cIniDir, Nil, @nIndex )

   nAt := At( Chr( 0 ) + Chr( 0 ), cFile )

   cFile := Left( cFile, nAt )

   aFiles := {}

   IF nAt == 0 // no double chr(0) user must have pressed cancel
      RETURN( aFiles )
   ENDIF

   x := At( Chr( 0 ), cFile ) // fist null
   cPath := Left( cFile, x )

   cFile := StrTran( cFile, cPath, "" )

   IF ! Empty( cFile ) // user selected more than 1 file
      cItem := ""

      FOR i := 1 TO Len( cFile ) //EACH cChar IN cFile
         cChar := cFile[i]
         IF cChar == 0
            AAdd( aFiles, StrTran( cPath, Chr(0 ), "" ) + '\' + cItem )
            cItem := ""
            LOOP
         ENDIF
         cItem += cChar
      NEXT
   ELSE
      aFiles := { StrTran( cPath, Chr( 0 ), "" ) }
   ENDIF

   RETURN( aFiles )

FUNCTION hwg_Version( n )

   LOCAL s

   IF !Empty( n )
      IF n == 1
         RETURN HWG_VERSION
      ELSEIF n == 2
         RETURN HWG_BUILD
      ELSEIF n == 3
#ifdef UNICODE
         RETURN Iif( hwg__isUnicode(), 1, 0 )
#else
         RETURN 0
#endif
      ELSEIF n == 4
         RETURN 0
      ENDIF
   ENDIF
   s := "HWGUI " + HWG_VERSION + " Build " + Ltrim(Str(HWG_BUILD))
#ifdef UNICODE
   IF hwg__isUnicode()
      s += " Unicode"
   ENDIF
#endif

   RETURN s

FUNCTION hwg_TxtRect( cTxt, oWin, oFont )

   LOCAL hDC, aSize, hFont

   oFont := iif( oFont != Nil, oFont, oWin:oFont )

   hDC := hwg_Getdc( oWin:handle )
   IF oFont == Nil .AND. oWin:oParent != Nil
      oFont := oWin:oParent:oFont
   ENDIF
   IF oFont != Nil
      hFont := hwg_Selectobject( hDC, oFont:handle )
   ENDIF
   aSize := hwg_Gettextsize( hDC, cTxt )
   IF oFont != Nil
      hwg_Selectobject( hDC, hFont )
   ENDIF
   hwg_Releasedc( oWin:handle, hDC )

   RETURN aSize

FUNCTION HWG_ScrollHV( oForm, msg, wParam, lParam )

   LOCAL nDelta, nSBCode , nPos, nInc

   HB_SYMBOL_UNUSED( lParam )

   nSBCode := hwg_Loword( wParam )
   IF msg == WM_MOUSEWHEEL
      nSBCode = iif( hwg_Hiword( wParam ) > 32768, hwg_Hiword( wParam ) - 65535, hwg_Hiword( wParam ) )
      nSBCode = iif( nSBCode < 0, SB_LINEDOWN, SB_LINEUP )
   ENDIF
   IF ( msg = WM_VSCROLL ) .OR. msg == WM_MOUSEWHEEL
      // Handle vertical scrollbar messages
      Switch ( nSBCode )
      CASE SB_TOP
         nInc := - oForm:nVscrollPos; EXIT
      CASE SB_BOTTOM
         nInc := oForm:nVscrollMax - oForm:nVscrollPos;  EXIT
      CASE SB_LINEUP
         nInc := - Int( oForm:nVertInc * 0.05 + 0.49 );    EXIT
      CASE SB_LINEDOWN
         nInc := Int( oForm:nVertInc * 0.05 + 0.49 ); EXIT
      CASE SB_PAGEUP
         nInc := Min( - 1, - oForm:nVertInc / 2 );  EXIT
      CASE SB_PAGEDOWN
         nInc := Max( 1, oForm:nVertInc / 2 );   EXIT
      CASE SB_THUMBTRACK
         nPos := hwg_Hiword( wParam )
         nInc := nPos - oForm:nVscrollPos ; EXIT
#ifdef __XHARBOUR__
         DEFAULT
#else
         OTHERWISE
#endif
         nInc := 0
      END
      nInc := Max( - oForm:nVscrollPos, Min( nInc, oForm:nVscrollMax - oForm:nVscrollPos ) )
      oForm:nVscrollPos += nInc
      nDelta := - VERT_PTS * nInc
      hwg_Scrollwindow( oForm:handle, 0, nDelta ) //, Nil, NIL )
      hwg_Setscrollpos( oForm:Handle, SB_VERT, oForm:nVscrollPos, .T. )

   ELSEIF ( msg = WM_HSCROLL ) //.OR. msg == WM_MOUSEWHEEL
      // Handle vertical scrollbar messages
      Switch ( nSBCode )
      CASE SB_TOP
         nInc := - oForm:nHscrollPos; EXIT
      CASE SB_BOTTOM
         nInc := oForm:nHscrollMax - oForm:nHscrollPos;  EXIT
      CASE SB_LINEUP
         nInc := - 1;    EXIT
      CASE SB_LINEDOWN
         nInc := 1; EXIT
      CASE SB_PAGEUP
         nInc := - HORZ_PTS;  EXIT
      CASE SB_PAGEDOWN
         nInc := HORZ_PTS;   EXIT
      CASE SB_THUMBTRACK
         nPos := hwg_Hiword( wParam )
         nInc := nPos - oForm:nHscrollPos; EXIT
#ifdef __XHARBOUR__
         DEFAULT
#else
         OTHERWISE
#endif
         nInc := 0
      END
      nInc := Max( - oForm:nHscrollPos, Min( nInc, oForm:nHscrollMax - oForm:nHscrollPos ) )
      oForm:nHscrollPos += nInc
      nDelta := - HORZ_PTS * nInc
      hwg_Scrollwindow( oForm:handle, nDelta, 0 )
      hwg_Setscrollpos( oForm:Handle, SB_HORZ, oForm:nHscrollPos, .T. )
   ENDIF

   RETURN Nil

FUNCTION hwg_KeyToUtf8( nCode )

   RETURN hb_utf8Chr( nCode )
