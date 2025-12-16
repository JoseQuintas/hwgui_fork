/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPaintCB, HPicture classes, common functions
 *
 * Copyright 2023 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hblang.ch"
#include "hbclass.ch"

CLASS HPaintCB INHERIT HObject

   DATA   aCB    INIT {}

   METHOD New()  INLINE Self
   METHOD Set( nId, block, cId )
   METHOD Get( nId )

ENDCLASS

METHOD Set( nId, block, cId ) CLASS HPaintCB

   LOCAL i, nLen

   IF Empty( cId ); cId := "_"; ENDIF

   nLen := Len( ::aCB )
   FOR i := 1 TO nLen
      IF ::aCB[i,1] == nId .AND. ::aCB[i,2] == cId
         EXIT
      ENDIF
   NEXT
   IF Empty( block )
      IF i <= nLen
         ADel( ::aCB, i )
         ::aCB := ASize( ::aCB, nLen - 1 )
      ENDIF
   ELSE
      IF i > nLen
         AAdd( ::aCB, { nId, cId, block } )
      ELSE
         ::aCB[i,3] := block
      ENDIF
   ENDIF

   RETURN Nil

METHOD Get( nId ) CLASS HPaintCB

   LOCAL i, nLen, aRes

   IF !Empty( ::aCB )
      nLen := Len( ::aCB )
      FOR i := 1 TO nLen
         IF ::aCB[i,1] == nId
            IF nId < PAINT_LINE_ITEM
               RETURN ::aCB[i,3]
            ELSE
               IF aRes == Nil
                  aRes := { ::aCB[i,3] }
               ELSE
                  AAdd( aRes, ::aCB[i,3] )
               ENDIF
            ENDIF
         ENDIF
      NEXT
   ENDIF

   RETURN aRes

//  ------------------------------

CLASS HPicture INHERIT HObject

   DATA cPicFunc, cPicMask
   DATA lPicComplex    INIT .F.
   DATA cType
   DATA nMaxLength     INIT Nil

   METHOD New( cPicture, vari, nMaxLength )
   METHOD IsEditable( nPos )
   METHOD FirstEditable()
   METHOD LastEditable()
   METHOD KeyRight( nPos )
   METHOD KeyLeft( nPos )
   METHOD Delete( cText, nPos )
   METHOD Input( cChar, nPos )
   METHOD GetApplyKey( cText, nPos, cKey, lFirst, lIns )
   METHOD Transform( vari )
   METHOD UnTransform( cBuffer )

   ENDCLASS

METHOD New( cPicture, vari, nMaxLength ) CLASS HPicture

   LOCAL nAt, i, masklen

   ::cType := Valtype( vari )
   ::cPicFunc := ::cPicMask := ""
   IF cPicture != Nil
      IF Left( cPicture, 1 ) == "@"
         nAt := At( " ", cPicture )
         IF nAt == 0
            ::cPicFunc := Upper( cPicture )
            ::cPicMask := ""
         ELSE
            ::cPicFunc := Upper( SubStr( cPicture, 1, nAt - 1 ) )
            ::cPicMask := SubStr( cPicture, nAt + 1 )
         ENDIF
         IF ::cPicFunc == "@"
            ::cPicFunc := ""
         ENDIF
      ELSE
         ::cPicFunc   := ""
         ::cPicMask   := cPicture
      ENDIF
      IF Empty( ::nMaxLength ) .AND. !Empty( ::cPicMask ) .AND. !( ::cPicFunc == "@R")
         ::nMaxLength := Len( ::cPicMask )
      ENDIF
   ENDIF

   IF Empty( ::cPicMask )
      IF ::cType == "D"
         ::cPicMask := StrTran( Dtoc( CToD( Space(8) ) ), ' ', '9' )
      ELSEIF ::cType == "N"
         vari := Str( vari )
         IF ( nAt := At( ".", vari ) ) > 0
            ::cPicMask := Replicate( '9', nAt - 1 ) + "." + ;
               Replicate( '9', Len( vari ) - nAt )
         ELSE
            ::cPicMask := Replicate( '9', Len( vari ) )
         ENDIF
      ENDIF
   ENDIF

   IF !Empty( ::cPicMask )
      masklen := Len( ::cPicMask )
      FOR i := 1 TO masklen
         IF !( SubStr( ::cPicMask, i, 1 ) $ "!ANX9#" )
            ::lPicComplex := .T.
            EXIT
         ENDIF
      NEXT
   ENDIF

   IF Empty( ::nMaxLength ) .AND. ::cType == "C"
      ::nMaxLength := hwg_Len( vari )
   ENDIF
   IF nMaxLength != Nil
      ::nMaxLength := nMaxLength
   ENDIF

   //  ------------ added by Maurizio la Cecilia
   IF !Empty( ::nMaxLength ) .AND. Len( ::cPicMask ) < ::nMaxLength
      ::cPicMask := PadR( ::cPicMask, ::nMaxLength, "X" )
   ENDIF
   //  ------------- end of added code

   RETURN Self

METHOD IsEditable( nPos ) CLASS HPicture

   LOCAL cChar

   IF Empty( ::cPicMask )
      RETURN .T.
   ENDIF
   IF nPos > Len( ::cPicMask )
      RETURN .F.
   ENDIF

   cChar := SubStr( ::cPicMask, nPos, 1 )

   IF ::cType == "C"
      RETURN cChar $ "!ANX9#"
   ELSEIF ::cType == "N"
      RETURN cChar $ "9#$*"
   ELSEIF ::cType == "D"
      RETURN cChar == "9"
   ELSEIF ::cType == "L"
      RETURN cChar $ "TFYN"
   ENDIF

   RETURN .F.

METHOD FirstEditable() CLASS HPicture

   LOCAL nFor, nMaxLen := Len( ::cPicMask )

   IF ::IsEditable( 1 )
      RETURN 1
   ENDIF

   FOR nFor := 2 TO nMaxLen
      IF ::IsEditable( nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

METHOD LastEditable() CLASS HPicture

   LOCAL nFor, nMaxLen := Len( ::cPicMask )

   FOR nFor := nMaxLen TO 1 step - 1
      IF ::IsEditable( nFor )
         RETURN nFor
      ENDIF
   NEXT

   RETURN 0

METHOD KeyRight( nPos ) CLASS HPicture

   LOCAL nMax

   IF Empty( ::cPicMask )
      RETURN nPos + 1
   ENDIF
   // cursor until end ( after last char )
   nMax := Len( ::cPicMask ) + 1
   DO WHILE nPos < nMax
      nPos += 1
      IF ::IsEditable( nPos )
         RETURN nPos
      ENDIF
   ENDDO

   RETURN Min( nPos, nMax )

METHOD KeyLeft( nPos ) CLASS HPicture

   IF ::cPicMask == Nil .OR. Empty( ::cPicMask )
      RETURN nPos - 1
   ELSE
      DO WHILE nPos > 1
         nPos --
         IF ::IsEditable( nPos )
            RETURN nPos
         ENDIF
      ENDDO
   ENDIF

   RETURN -1

METHOD Delete( cText, nPos ) CLASS HPicture

   LOCAL nGetLen := Len( ::cPicMask ), nLen

   FOR nLen := 0 TO nGetLen
      IF !::IsEditable( nPos + nLen )
         EXIT
      ENDIF
   NEXT
   IF nLen == 0
      DO WHILE nPos >= 1
         nPos --
         nLen ++
         IF ::IsEditable( nPos )
            EXIT
         ENDIF
      ENDDO
   ENDIF
   cText := PadR( Left( cText, nPos - 1 ) + ;
      SubStr( cText, nPos + 1, nLen - 1 ) + " " + ;
      SubStr( cText, nPos + nLen ), nGetLen )

   RETURN cText

METHOD Input( cChar, nPos ) CLASS HPicture

   LOCAL cPic

   IF !Empty( ::cPicMask ) .AND. nPos > Len( ::cPicMask )
      RETURN Nil
   ENDIF
   IF ::cType == "N"
      IF cChar == "-"
         IF nPos != 1
            RETURN Nil
         ENDIF
      ELSEIF !( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF ::cType == "D"

      IF !( cChar $ "0123456789" )
         RETURN Nil
      ENDIF

   ELSEIF ::cType == "L"

      IF !( Upper( cChar ) $ "YNTF" )
         RETURN Nil
      ENDIF

   ENDIF

   IF Len( cChar ) > 1
      IF !Empty( ::cPicMask ) .AND. SubStr( ::cPicMask, nPos, 1 ) $ "N9#"
         cChar := Nil
      ENDIF
   ELSE
      IF !Empty( ::cPicFunc )
         cChar := Transform( cChar, ::cPicFunc )
      ENDIF

      IF !Empty( ::cPicMask )
         cPic  := SubStr( ::cPicMask, nPos, 1 )

         cChar := Transform( cChar, cPic )
         IF cPic == "A"
            IF ! IsAlpha( cChar )
               cChar := Nil
            ENDIF
         ELSEIF cPic == "N"
            IF ! IsAlpha( cChar ) .AND. ! IsDigit( cChar )
               cChar := Nil
            ENDIF
         ELSEIF cPic == "9"
            IF ! IsDigit( cChar ) .AND. cChar != "-"
               cChar := Nil
            ENDIF
         ELSEIF cPic == "#"
            IF ! IsDigit( cChar ) .AND. !( cChar == " " ) .AND. !( cChar $ "+-" )
               cChar := Nil
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN cChar

METHOD GetApplyKey( cText, nPos, cKey, lFirst, lIns ) CLASS HPicture

   LOCAL nGetLen, nLen, vari, x, newPos
   LOCAL nDecimals, lMinus := .F.

   IF lFirst
      nPos := ::KeyRight( 0 )
   ENDIF

   IF ::cType == "N" .AND. cKey $ ".," .AND. ( nPos := At( ".",::cPicMask ) ) != 0
      IF lFirst
         vari := 0
      ELSE
         vari := Val( LTrim( ::UnTransform( Trim( cText ) ) ) )
         lMinus := Iif( Left( Ltrim(cText),1 ) == "-", .T., .F. )
      ENDIF
      cText := ::Transform( vari )
      IF ( x := ::KeyRight( nPos - 1 ) ) > 0
         nPos := x
      ENDIF
      IF !Empty( ::cPicFunc ) .OR. !Empty( ::cPicMask )
         IF lMinus .AND. vari == 0
            nLen := Len( cText )
            cText := Padl( "-" + Ltrim( cText ), nLen )
         ENDIF
      ENDIF
   ELSE

      IF ::cType == "N" .AND. lFirst
         nGetLen := Len( ::cPicMask )
         IF ( nPos := At( ".", ::cPicMask ) ) == 0
            cText := Space( nGetLen )
         ELSE
            cText := Space( nPos - 1 ) + "." + Space( nGetLen - nPos )
         ENDIF
         nPos := 1
      ENDIF
      cKey := ::Input( cKey, nPos )
      IF cKey != Nil
         IF lIns
            IF ::lPicComplex
               nGetLen := Len( ::cPicMask )
               FOR nLen := 0 TO nGetLen
                  IF !::IsEditable( nPos + nLen )
                     EXIT
                  ENDIF
               NEXT
               cText := hwg_Left( cText, nPos - 1 ) + cKey + ;
                  hwg_SubStr( cText, nPos, nLen - 1 ) + hwg_SubStr( cText, nPos + nLen )
            ELSE
               cText := hwg_Left( cText, nPos - 1 ) + cKey + ;
                  hwg_SubStr( cText, nPos )
            ENDIF

            IF !Empty( ::cPicMask ) .AND. Len( ::cPicMask ) < hwg_Len( cText )
               cText := hwg_Left( cText, nPos - 1 ) + cKey + hwg_SubStr( cText, nPos + 1 )
            ENDIF
         ELSE
            cText := hwg_Left( cText, nPos - 1 ) + cKey + hwg_SubStr( cText, nPos + 1 )
         ENDIF
         IF !Empty( ::nMaxLength )
            nGetLen := Max( Len( ::cPicMask ), ::nMaxLength )
            nLen := hwg_Len( cText )
            IF nGetLen > nLen
               cText += Space( nGetLen-nLen )
            ELSEIF nGetLen < nLen
               cText := hwg_Left( cText, nGetLen )
            ENDIF
         ENDIF
         IF ( x := ::KeyRight( nPos ) ) > 0
            nPos := x
         ENDIF
         //Added By Sandro Freire
         IF ::cType == "N"
            IF !Empty( ::cPicMask )
               nDecimals := Len( SubStr(  ::cPicMask, At( ".", ::cPicMask ), Len( ::cPicMask ) ) )
               IF nDecimals <= 0
                  nDecimals := 3
               ENDIF
               newPos := Len( ::cPicMask ) - nDecimals
               IF "E" $ ::cPicFunc .AND. nPos == newPos
                  cText := ::GetApplyKey( cText, nPos, ",", .F., lIns )
               ENDIF
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN cText

METHOD Transform( vari ) CLASS HPicture
   RETURN Transform( vari, ::cPicFunc + iif( Empty(::cPicFunc ),""," " ) + ::cPicMask )

METHOD UnTransform( cBuffer ) CLASS HPicture

   LOCAL xValue, cChar, nFor, minus

   IF ::cType == "C"

      IF "R" $ ::cPicFunc
         FOR nFor := 1 TO Len( ::cPicMask )
            cChar := SubStr( ::cPicMask, nFor, 1 )
            IF !cChar $ "ANX9#!"
               cBuffer := SubStr( cBuffer, 1, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
         cBuffer := StrTran( cBuffer, Chr( 1 ), "" )
      ENDIF

      xValue := cBuffer

   ELSEIF ::cType == "N"
      minus := ( Left( LTrim( cBuffer ),1 ) == "-" )
      cBuffer := Space( ::FirstEditable() - 1 ) + SubStr( cBuffer, ::FirstEditable(), ::LastEditable() - ::FirstEditable() + 1 )

      IF "D" $ ::cPicFunc
         FOR nFor := ::FirstEditable() TO ::LastEditable()
            IF !::IsEditable( nFor )
               cBuffer = Left( cBuffer, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
      ELSE
         IF "E" $ ::cPicFunc
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) +  ;
               StrTran( SubStr( cBuffer, ::FirstEditable(),      ;
               ::LastEditable() - ::FirstEditable() + 1 ),       ;
               ".", " " ) + SubStr( cBuffer, ::LastEditable() + 1 )
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) +  ;
               StrTran( SubStr( cBuffer, ::FirstEditable(),      ;
               ::LastEditable() - ::FirstEditable() + 1 ),  ;
               ",", "." ) + SubStr( cBuffer, ::LastEditable() + 1 )
         ELSE
            cBuffer := Left( cBuffer, ::FirstEditable() - 1 ) + ;
               StrTran( SubStr( cBuffer, ::FirstEditable(),     ;
               ::LastEditable() - ::FirstEditable() + 1 ), ;
               ",", " " ) + SubStr( cBuffer, ::LastEditable() + 1 )
         ENDIF

         FOR nFor := ::FirstEditable() TO ::LastEditable()
            IF !::IsEditable( nFor ) .AND. SubStr( cBuffer, nFor, 1 ) != "."
               cBuffer = Left( cBuffer, nFor - 1 ) + Chr( 1 ) + SubStr( cBuffer, nFor + 1 )
            ENDIF
         NEXT
      ENDIF

      cBuffer := StrTran( cBuffer, Chr( 1 ), "" )

      cBuffer := StrTran( cBuffer, "$", " " )
      cBuffer := StrTran( cBuffer, "*", " " )
      cBuffer := StrTran( cBuffer, "-", " " )
      cBuffer := StrTran( cBuffer, "(", " " )
      cBuffer := StrTran( cBuffer, ")", " " )

      cBuffer := PadL( StrTran( cBuffer, " ", "" ), Len( cBuffer ) )

      IF minus
         FOR nFor := 1 TO Len( cBuffer )
            IF IsDigit( SubStr( cBuffer, nFor, 1 ) )
               EXIT
            ENDIF
         NEXT
         nFor --
         IF nFor > 0
            cBuffer := Left( cBuffer, nFor - 1 ) + "-" + SubStr( cBuffer, nFor + 1 )
         ELSE
            cBuffer := "-" + cBuffer
         ENDIF
      ENDIF

      xValue := cBuffer

   ELSEIF ::cType == "L"

      cBuffer := Upper( cBuffer )
      xValue := "T" $ cBuffer .OR. "Y" $ cBuffer .OR. hb_langmessage( HB_LANG_ITEM_BASE_TEXT + 1 ) $ cBuffer

   ELSEIF ::cType == "D"

      IF "E" $ ::cPicFunc
         cBuffer := SubStr( cBuffer, 4, 3 ) + SubStr( cBuffer, 1, 3 ) + SubStr( cBuffer, 7 )
      ENDIF
      xValue := cBuffer

   ENDIF

   RETURN xValue

//  ------------------------------

FUNCTION hwg_EndWindow()

   IF HWindow():GetMain() != Nil
      HWindow():aWindows[1]:Close()
   ENDIF

   RETURN Nil

FUNCTION hwg_FindParent( hCtrl, nLevel )

   LOCAL i, oParent, hParent := hwg_Getparent( hCtrl )

   IF !Empty( hParent )
      IF ( i := Ascan( HDialog():aModalDialogs,{ |o|o:handle == hParent } ) ) != 0
         RETURN HDialog():aModalDialogs[i]
      ELSEIF ( oParent := HDialog():FindDialog( hParent ) ) != Nil
         RETURN oParent
      ELSEIF ( oParent := HWindow():FindWindow( hParent ) ) != Nil
         RETURN oParent
      ENDIF
   ENDIF
   IF nLevel == Nil; nLevel := 0; ENDIF
   IF nLevel < 2
      IF ( oParent := hwg_FindParent( hParent,nLevel + 1 ) ) != Nil
         RETURN oParent:FindControl( , hParent )
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION hwg_FindSelf( hCtrl )

   LOCAL oParent := hwg_FindParent( hCtrl )

   IF oParent != Nil
      RETURN oParent:FindControl( , hCtrl )
   ENDIF

   RETURN Nil

FUNCTION hwg_getParentForm( o )

   DO WHILE o:oParent != Nil .AND. !__ObjHasMsg( o, "GETLIST" )
      o := o:oParent
   ENDDO

   RETURN o

FUNCTION hwg_ColorC2N( cColor )

   LOCAL i, res := 0, n := 1, iValue

   IF Left( cColor,1 ) == "#"
      cColor := Substr( cColor,2 )
   ENDIF
   cColor := Trim( cColor )
   FOR i := 1 TO Len( cColor )
      iValue := Asc( SubStr( cColor,i,1 ) )
      IF iValue < 58 .AND. iValue > 47
         iValue -= 48
      ELSEIF iValue >= 65 .AND. iValue <= 70
         iValue -= 55
      ELSEIF iValue >= 97 .AND. iValue <= 102
         iValue -= 87
      ELSE
         RETURN 0
      ENDIF
      iValue *= n
      IF i % 2 == 1
         iValue *= 16
      ELSE
         n *= 256
      ENDIF
      res += iValue
   NEXT

   RETURN res

FUNCTION hwg_ColorN2C( nColor )

   LOCAL s := "", n1, n2, i

   FOR i := 0 to 2
      n1 := hb_BitAnd( hb_BitShift( nColor,-i*8-4 ), 15 )
      n2 := hb_BitAnd( hb_BitShift( nColor,-i*8 ), 15 )
      s += Chr( Iif(n1<10,n1+48,n1+55) ) + Chr( Iif(n2<10,n2+48,n2+55) )
   NEXT

   RETURN s

FUNCTION hwg_ColorN2RGB( nColor, nr, ng, nb )

   nr := nColor % 256
   ng := Int( nColor/256 ) % 256
   nb := Int( nColor/65536 )

   RETURN { nr, ng, nb }

FUNCTION hwg_RefreshAllGets( oDlg )

   AEval( oDlg:GetList, { |o|o:Refresh() } )

   RETURN Nil

FUNCTION hwg_CreateGetList( oDlg )

   // Rebuild GetList recursively to support nested containers (e.g., TAB inside TAB).
   // The previous implementation only scanned one level deep (oDlg:aControls and one child level),
   // which prevents <Enter> navigation between GETs placed deeper in the control tree.

   IF oDlg == Nil
      RETURN Nil
   ENDIF

   // Ensure it starts clean
   IF __ObjHasMsg( oDlg, "GETLIST" )
      oDlg:GetList := {}
   ENDIF

   __hwg_AddGetsRecursive( oDlg, oDlg )
   RETURN Nil


STATIC PROCEDURE __hwg_AddGetsRecursive( oNode, oDlg )

   LOCAL i, aChildren, nLen

   IF oNode == Nil
      RETURN
   ENDIF

   // If this node is a GET-like control (has bSetGet), register it
   IF __ObjHasMsg( oNode, "BSETGET" ) .AND. oNode:bSetGet != Nil
      AAdd( oDlg:GetList, oNode )
   ENDIF

   // Recurse into children controls if available
   IF __ObjHasMsg( oNode, "ACONTROLS" ) .AND. !Empty( oNode:aControls )
      aChildren := oNode:aControls
      nLen := Len( aChildren )
      FOR i := 1 TO nLen
         __hwg_AddGetsRecursive( aChildren[i], oDlg )
      NEXT
   ENDIF

   RETURN

FUNCTION hwg_GetSkip( oParent, hCtrl, nSkip, lClipper )

   LOCAL nPos, nGetCount

   DO WHILE oParent != Nil .AND. !__ObjHasMsg( oParent, "GETLIST" )
      oParent := oParent:oParent
   ENDDO
   IF oParent == Nil .OR. ( lClipper != Nil .AND. lClipper .AND. !oParent:lClipper )
      RETURN .F.
   ENDIF
   nGetCount := Len( oParent:GetList )
   IF ( hCtrl == Nil .OR. ( nPos := Ascan( oParent:Getlist,{ |o|o:handle == hCtrl } ) ) != 0 ) ;
      .AND. nGetCount > 1
      IF nPos > 0 .AND. __ObjHasMsg( oParent:Getlist[ nPos ], "LFIRST" )
         oParent:Getlist[ nPos ]:lFirst := .T.
      ENDIF
      IF nSkip > 0
         DO WHILE ( nPos += nSkip ) <= nGetCount
            IF ! oParent:Getlist[ nPos ]:lHide .AND. hwg_Iswindowenabled( oParent:Getlist[ nPos ]:Handle ) // Now tab and enter goes trhow the check, combo, etc...
               hwg_Setfocus( oParent:Getlist[ nPos ]:handle )
               RETURN .T.
            ENDIF
         ENDDO
      ELSE
         DO WHILE ( nPos += nSkip ) > 0
            IF ! oParent:Getlist[ nPos ]:lHide .AND. hwg_Iswindowenabled( oParent:Getlist[ nPos ]:Handle )
               hwg_Setfocus( oParent:Getlist[ nPos ]:handle )
               RETURN .T.
            ENDIF
         ENDDO
      ENDIF
   ENDIF

   RETURN .F.

FUNCTION hwg_SetGetUpdated( o )

   o:lChanged := .T.
   IF ( o := hwg_getParentForm( o ) ) != Nil
      o:lUpdated := .T.
   ENDIF

   RETURN Nil

FUNCTION hwg_resize_onAnchor( oCtrl, x, y, w, h )

   LOCAL nAnchor, nXincRelative, nYincRelative, nXincAbsolute, nYincAbsolute
   LOCAL x1, y1, w1, h1, x9, y9, w9, h9

   nAnchor := oCtrl:anchor
   x9 := x1 := oCtrl:nLeft
   y9 := y1 := oCtrl:nTop
   w9 := w1 := oCtrl:nWidth
   h9 := h1 := oCtrl:nHeight
   // *- calculo relativo
   nXincRelative := iif( x > 0, w / x, 1 )
   nYincRelative := iif( y > 0, h / y, 1 )
   // *- calculo ABSOLUTE
   nXincAbsolute := ( w - x )
   nYincAbsolute := ( h - y )

   IF nAnchor >= ANCHOR_VERTFIX
      // *- vertical fixed center
      nAnchor -= ANCHOR_VERTFIX
      y1 := y9 + Int( ( h - y ) * ( ( y9 + h9 / 2 ) / y ) )
   ENDIF
   IF nAnchor >= ANCHOR_HORFIX
      // *- horizontal fixed center
      nAnchor -= ANCHOR_HORFIX
      x1 := x9 + Int( ( w - x ) * ( ( x9 + w9 / 2 ) / x ) )
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTREL
      // relative - RIGHT RELATIVE
      nAnchor -= ANCHOR_RIGHTREL
      x1 := w - Int( ( x - x9 - w9 ) * nXincRelative ) - w9
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMREL
      // relative - BOTTOM RELATIVE
      nAnchor -= ANCHOR_BOTTOMREL
      y1 := h - Int( ( y - y9 - h9 ) * nYincRelative ) - h9
   ENDIF
   IF nAnchor >= ANCHOR_LEFTREL
      // relative - LEFT RELATIVE
      nAnchor -= ANCHOR_LEFTREL
      IF x1 != x9
         w1 := x1 - ( Int( x9 * nXincRelative ) ) + w9
      ENDIF
      x1 := Int( x9 * nXincRelative )
   ENDIF
   IF nAnchor >= ANCHOR_TOPREL
      // relative  - TOP RELATIVE
      nAnchor -= ANCHOR_TOPREL
      IF y1 != y9
         h1 := y1 - ( Int( y9 * nYincRelative ) ) + h9
      ENDIF
      y1 := Int( y9 * nYincRelative )
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTABS
      // Absolute - RIGHT ABSOLUTE
      nAnchor -= ANCHOR_RIGHTABS
      IF HWG_BITAND( nAnchor, ANCHOR_LEFTREL ) != 0
         w1 := Int( nxIncAbsolute ) - ( x1 - x9 ) + w9
      ELSE
         IF x1 != x9
            w1 := x1 - ( x9 +  Int( nXincAbsolute ) ) + w9
         ENDIF
         x1 := x9 +  Int( nXincAbsolute )
      ENDIF
      IF x1 + w1 > w
         w1 := w - x1
      ENDIF
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMABS
      // Absolute - BOTTOM ABSOLUTE
      nAnchor -= ANCHOR_BOTTOMABS
      IF HWG_BITAND( nAnchor, ANCHOR_TOPREL ) != 0
         h1 := Int( nyIncAbsolute ) - ( y1 - y9 ) + h9
      ELSE
         IF y1 != y9
            h1 := y1 - ( y9 +  Int( nYincAbsolute ) ) + h9
         ENDIF
         y1 := y9 +  Int( nYincAbsolute )
      ENDIF
      IF y1 + h1 > h
         h1 := h - y1
      ENDIF
   ENDIF
   IF nAnchor >= ANCHOR_LEFTABS
      // Absolute - LEFT ABSOLUTE
      nAnchor -= ANCHOR_LEFTABS
      IF x1 != x9
         w1 := x1 - x9 + w9
      ENDIF
      x1 := x9
   ENDIF
   IF nAnchor >= ANCHOR_TOPABS
      // Absolute - TOP ABSOLUTE
      IF y1 != y9
         h1 := y1 - y9 + h9
      ENDIF
      y1 := y9
   ENDIF
   // REDRAW AND INVALIDATE SCREEN
   IF ( x1 != x9 .OR. y1 != y9 .OR. w1 != w9 .OR. h1 != h9 )
      oCtrl:Move( x1, y1, w1, h1 )
      //oCtrl:Refresh()
      RETURN .T.
   ENDIF

   RETURN .F.

FUNCTION hwg_onAnchor( oWnd, wold, hold, wnew, hnew )

   LOCAL aControls := oWnd:aControls, oItem, w, h

   FOR EACH oItem IN aControls
      IF oItem:Anchor > 0
         w := oItem:nWidth
         h := oItem:nHeight
         oItem:onAnchor( wold, hold, wnew, hnew )
         hwg_onAnchor( oItem, w, h, oItem:nWidth, oItem:nHeight )
      ENDIF
   NEXT

   RETURN Nil

FUNCTION hwg_GetModalDlg()

   LOCAL i := Len( HDialog():aModalDialogs )

   RETURN Iif( i > 0, HDialog():aModalDialogs[i], Nil )

FUNCTION hwg_GetModalHandle()

   LOCAL i := Len( HDialog():aModalDialogs )

   RETURN Iif( i > 0, HDialog():aModalDialogs[i]:handle, 0 )

FUNCTION hwg_SetDlgKey( oDlg, nctrl, nkey, block, lGlobal )

   LOCAL i, aKeys

   IF oDlg == Nil ; oDlg := HCustomWindow():oDefaultParent ; ENDIF
   IF nctrl == Nil ; nctrl := 0 ; ENDIF

   IF Empty( lGlobal )
      IF !__ObjHasMsg( oDlg, "KEYLIST" )
         RETURN .F.
      ENDIF
      aKeys := oDlg:KeyList
   ELSE
      aKeys := HWindow():aKeysGlobal
   ENDIF

   IF block == Nil

      IF ( i := Ascan( aKeys,{ |a|a[1] == nctrl .AND. a[2] == nkey } ) ) == 0
         RETURN .F.
      ELSE
         ADel( aKeys, i )
         ASize( aKeys, Len( aKeys ) - 1 )
      ENDIF
   ELSE
      IF ( i := Ascan( aKeys,{ |a|a[1] == nctrl .AND. a[2] == nkey } ) ) == 0
         AAdd( aKeys, { nctrl, nkey, block } )
      ELSE
         aKeys[i,3] := block
      ENDIF
   ENDIF

   RETURN .T.

FUNCTION hwg_Trace()

   LOCAL s := "", n := 2

   WHILE ! Empty( ProcName( n ) )
#ifdef __XHARBOUR__
      s += Chr( 13 ) + Chr( 10 ) + "Called from " + ProcFile( n ) + "->" + ProcName( n ) + "(" + AllTrim( Str( ProcLine( n ++ ) ) ) + ")"
#else
      s += Chr( 13 ) + Chr( 10 ) + "Called from " + ProcName( n ) + "(" + AllTrim( Str( ProcLine( n ++ ) ) ) + ")"
#endif
   ENDDO

   RETURN s

   //   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   //   Functions for raw bitmap support
   //   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FUNCTION hwg_BPMinches_per_meter()

   RETURN 100.0 / 2.54

FUNCTION hwg_BPMconv_inch( mtr )

   RETURN mtr / ( 100.0 / 2.54 )

FUNCTION hwg_ShowBitmap( cbmp, cbmpname, ncolbg, ncolfg )

   // Shows a bitmap
   // cbmp      : The bitmap file image string
   // cbmpname  : A unique name of the bitmap
   // ncolbg    : Background color (system, if NIL)
   // ncolfg    : foreground colors (ignored, if no background color is set)
   // You can use
   // hwg_ColorC2N( cColor ):
   //  Converts color representation from string to numeric format.
   //  cColor - a string in #RRGGBB

   LOCAL frm_bitmap , oButton1 , nx , ny , oBitmap
   LOCAL oLabel1, oLabel2, oLabel3, oLabel4
   LOCAL obmp, ldefc

   // Display the bitmap in an extra window
   // Max size : 1277,640

   ldefc := .F.
   IF ncolbg != NIL
      ldefc := .T.
   ENDIF

   IF ncolfg != NIL
      ldefc := .T.
   ENDIF

   obmp := HBitmap():AddString( cbmpname , cbmp )

   // Get current size
   nx := hwg_GetBitmapWidth ( obmp:handle )
   ny := hwg_GetBitmapHeight( obmp:handle )

   IF nx > 1277
      nx := 1277
   ENDIF

   IF ny > 640
      ny := 640
   ENDIF

   IF ldefc

      INIT DIALOG frm_bitmap TITLE "Bitmap Image" ;
         AT 20, 20 SIZE 1324, 772 ;
         BACKCOLOR ncolbg;
         STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE

      @ 747, 667 SAY oLabel1 CAPTION "Size:  x:"  SIZE 87, 22 ;
         COLOR ncolfg  BACKCOLOR ncolbg ;
         STYLE SS_RIGHT

      @ 866, 667 SAY oLabel2 CAPTION AllTrim( Str( nx ) )  SIZE 80, 22  ;
         COLOR ncolfg  BACKCOLOR ncolbg
      @ 988, 667 SAY oLabel3 CAPTION "y:"  SIZE 80, 22 ;
         COLOR ncolfg  BACKCOLOR ncolbg ;
         STYLE SS_RIGHT
      @ 1130, 667 SAY oLabel4 CAPTION AllTrim( Str( ny ) )  SIZE 80, 22 ;
         COLOR ncolfg  BACKCOLOR ncolbg ;

         # ifdef __GTK__
      @ 17, 12 BITMAP oBitmap  ;
         SHOW obmp OF frm_bitmap  ;
         SIZE nx, ny
#else
      @ 17, 12 BITMAP oBitmap  ;
         SHOW obmp OF frm_bitmap
#endif

      @ 590, 663 BUTTON oButton1 CAPTION "OK"   SIZE 80, 32 ;
         COLOR ncolfg  BACKCOLOR ncolbg ;
         STYLE WS_TABSTOP + BS_FLAT ;
         ON CLICK { || frm_bitmap:Close() }

   ELSE
      // System colors

      INIT DIALOG frm_bitmap TITLE "Bitmap Image" ;
         AT 20, 20 SIZE 1324, 772 ;
         STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE

      @ 747, 667 SAY oLabel1 CAPTION "Size:  x:"  SIZE 87, 22 ;
         STYLE SS_RIGHT
      @ 866, 667 SAY oLabel2 CAPTION AllTrim( Str( nx ) )  SIZE 80, 22
      @ 988, 667 SAY oLabel3 CAPTION "y:"  SIZE 80, 22 ;
         STYLE SS_RIGHT
      @ 1130, 667 SAY oLabel4 CAPTION AllTrim( Str( ny ) )  SIZE 80, 22

#ifdef __GTK__
      @ 17, 12 BITMAP oBitmap  ;
         SHOW obmp OF frm_bitmap  ;
         SIZE nx, ny
#else
      @ 17, 12 BITMAP oBitmap  ;
         SHOW obmp OF frm_bitmap
#endif

      @ 590, 663 BUTTON oButton1 CAPTION "OK"   SIZE 80, 32 ;
         STYLE WS_TABSTOP + BS_FLAT ;
         ON CLICK { || frm_bitmap:Close() }

   ENDIF

   ACTIVATE DIALOG frm_bitmap

   RETURN NIL

FUNCTION hwg_BMPDrawCircle( nradius, ndeg )

   LOCAL aret , nx, ny , nrad

   aret := {}
   // Convert degrees to radiant
   nrad := ndeg/180.0 * hwg_PI()

   nx := Round( hwg_Cos( nrad ) * nradius  , 0 ) + nradius + 1
   ny := Round( hwg_Sin( nrad ) * nradius  , 0 ) + nradius + 1

   AAdd( aret, nx )
   AAdd( aret, ny )

   RETURN aret

FUNCTION hwg_BMPSetMonochromePalette( pcBMP )

   // Set monochrome palette for QR encoding,
   // The background is white.
   // (2 colors, black and white)
   // Set 55, 56, 57 to 0xFF
   // This setting define color 0 as white (the color 1 now is black by default)
   // Sample:
   // CBMP := HWG_BMPNEWIMAGE(nx, ny, 1, 2, 2835, 2835 )
   // HWG_BMPDESTROY()
   // CBMP := hwg_BMPSetMonochromePalette(CBMP)

   LOCAL npoffset, CBMP
   CBMP := pcBMP

   // Get Offset to palette data, expected value by default is 54
   npoffset := HWG_BMPCALCOFFSPAL()
   CBMP := hwg_ChangeCharInString( CBMP, npoffset     , Chr( 255 ) )
   CBMP := hwg_ChangeCharInString( CBMP, npoffset + 1 , Chr( 255 ) )
   CBMP := hwg_ChangeCharInString( CBMP, npoffset + 2 , Chr( 255 ) )
   CBMP := hwg_ChangeCharInString( CBMP, npoffset + 3 , Chr( 255 ) )

   RETURN CBMP

   // Converts the bitmap string after (opional)
   // modifications into a bitmap object.
   // cbmpname : String with an unique bitmap name

FUNCTION hwg_BMPStr2Obj( pcBMP, cbmpname )

   LOCAL oBmp

   oBmp := HBitmap():AddString( cbmpname , pcBMP )

   RETURN oBmp

   //   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   //   End of Functions for raw bitmap support
   //   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FUNCTION hwg_oDatepicker_bmp()

   * Returns the bimap object of image Datepick_Button2.bmp
   * (size 11 x 11 )
   * for the multi platform datepicker based on HMONTHCALENDAR class

RETURN HBitmap():AddString("Datepick_Button", hwg_cHex2Bin(;
   "42 4D 6A 00 00 00 00 00 00 00 3E 00 00 00 28 00 " + ;
   "00 00 0B 00 00 00 0B 00 00 00 01 00 01 00 00 00 " + ;
   "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
   "00 00 00 00 00 00 F0 FB FF 00 00 00 00 00 00 00 " + ;
   "00 00 00 00 00 00 00 00 00 00 04 00 00 00 0E 00 " + ;
   "00 00 1F 00 00 00 3F 80 00 00 00 00 00 00 00 00 " + ;
   "00 00 00 00 00 00 00 00 00 00 " ) )

 FUNCTION hwg_pCalendar(dstartdate, cTitle , cOK, cCancel , nx , ny , wid, hei )
* Date picker command for all platforms in the design of original
* Windows only DATEPICKER command

   LOCAL oDlg, oMC , oFont , dolddate , dnewdate,  lcancel

  IF cTitle == NIL
    cTitle := "Calendar"
  ENDIF

  IF cOK == NIL
     cOK := "OK"
  ENDIF

  IF cCancel == NIL
     cCancel := "Cancel"
  ENDIF

  IF dstartdate == NIL
   dstartdate := DATE()
  ENDIF

  IF nx == NIL
   nx := 0  && old: 20
  ENDIF

  IF ny == NIL
   ny := 0  && old: 20
  ENDIF

  IF wid == NIL
   wid := 200 && old: 80
  ENDIF

  IF hei == NIL
   hei := 160 && old: 20
  ENDIF

  oFont := hwg_DefaultFont()

  lcancel := .T.

  * Remember old date
  dolddate := dstartdate

   INIT DIALOG oDlg TITLE cTitle ;
      AT nx,ny SIZE  wid , hei + 23 && wid , hei , 22 = height of buttons

   @ 0,0 MONTHCALENDAR oMC ;
      SIZE wid - 1 , hei - 1 ;
      INIT dstartdate ;   && Date(), if NIL
      FONT oFont

   @ 0 ,hei BUTTON cOK FONT oFont ;
    ON CLICK {|| lcancel := .F., dnewdate := oMC:Value , oDlg:Close() } SIZE 80 , 22
   @ 81,hei BUTTON cCancel FONT oFont ;
    ON CLICK {|| oDlg:Close() } SIZE 80, 22


   ACTIVATE DIALOG oDlg


   IF lcancel
    dnewdate := dolddate
   ENDIF

   RETURN dnewdate

   //   ~~~~~~~~~~~~~~~~~~~~~~~~~
   //   Functions for QR encoding
   //   ~~~~~~~~~~~~~~~~~~~~~~~~~

   /* Convert QR code to bitmap */

FUNCTION hwg_QRCodetxt2BPM( cqrcode )

   LOCAL cBMP , nlines, ncol , x , i , n
   LOCAL leofq

   IF cqrcode == NIL
      RETURN ""
   ENDIF

   // Count the columns in QR code text string
   // ( Appearance of line end in first line )
   ncol   := At( Chr( 10 ), cqrcode ) - 1

   // Count the lines in QR code text string
   // Suppress empty lines

   leofq := .F.
   nlines := 0
   FOR i := 1 TO Len( cqrcode )
      IF .NOT. leofq
         IF SubStr( cqrcode, i, 1 ) == Chr( 10 )
            IF .NOT. ( SubStr( cqrcode, i + 1 , 1 ) == " " )
               // Empty line following, stop here
               leofq := .T.
            ELSE
               // Count line ending
               nlines := nlines + 1
            ENDIF
         ENDIF
      ENDIF

   NEXT

   // Based on this, calculate the bitmap size
   nlines := nlines + 1

   // Create the bitmap template and set monochrome palette
   cBMP := HWG_BMPNEWIMAGE( ncol, nlines, 1, 2, 2835, 2835 )
   HWG_BMPDESTROY()
   cBMP := hwg_BMPSetMonochromePalette( cBMP )

   // Convert to bitmap

   leofq := .F.
   // i:        Position in cqrcode
   n := 1   // Line
   x := 0   // Column
   FOR i := 1 TO Len( cqrcode )
      x := x + 1
      IF .NOT. leofq
         IF SubStr( cqrcode, i, 1 ) == Chr( 10 )
            IF .NOT. ( SubStr( cqrcode, i + 1 , 1 ) == " " )
               // Empty line following, stop here
               leofq := .T.
            ENDIF
            // Count line ending and start with new line
            n := n + 1
            x := 0
         ELSE  // SUBSTR " "
            IF SubStr( cqrcode, i, 1 ) == "#"
               cBMP := hwg_QR_SetPixel( cBMP, x, n, ncol, nlines )
            ENDIF  // #
         ENDIF // is CHR(10)
      ENDIF // .NOT. leofq

   NEXT

   RETURN cBMP

   // Set a single pixel into QR code bitmap string
   // Background color is white, pixel color is black

FUNCTION hwg_QR_SetPixel( cmbp, x, y, xw, yh )

   LOCAL cbmret, noffset, nbit , y1
   LOCAL nolbyte
   LOCAL nbline, nbyt , nline , nbint

   cbmret := cmbp

   // Range check
   IF ( x > xw ) .OR. ( y > yh ) .OR. ( x < 1 ) .OR. ( y < 1 )
      RETURN cbmret
   ENDIF

   // Add 1 to pixel data offset, this is done with call of HWG_SETBITBYTE()
   noffset := hwg_BMPCalcOffsPixArr( 2 );  // For 2 colors

   // y Position conversion
   // (reversed position 1 = 48, 48 = 1)
   y1 := yh - y + 1
   // Bytes per line
   nline := hwg_BMPLineSize( xw, 1 )
   // hwg_MsgInfo("nline="+ STR(nline) )

   // Calculate the recent y position
   // (Start postion of a line)

   nbyt := ( y1 - 1 ) *  nline

   // Split line into number of bytes and bit position
   nbline := Int( x / 8 )
   nbyt := nbyt + nbline + 1   // Added 1 padding byte at begin of a line

   nbint :=  Int( x % 8 ) // + 1

   // Reverse x value in a byte
   nbint := 8 - nbint + 1 // 1 ... 8

   IF nbint == 9
      nbint := 1
      nbyt := nbyt - 1
   ENDIF

   // Extract old byte value
   nolbyte := Asc( SubStr( cbmret,noffset + nbyt,1 ) )

   nbit := Chr( HWG_SETBITBYTE( 0,nbint,1 ) )
   nbit := Chr( HWG_BITOR_INT( Asc(nbit ), nolbyte ) )

   cbmret := hwg_ChangeCharInString( cbmret, noffset + nbyt , nbit )

   RETURN cbmret

   // Increases the size of a QR code image
   // cqrcode : The QR code in text format
   // nzoom   : The zoom factor 1 ... n
   // Return the new QR code text string

FUNCTION hwg_QRCodeZoom( cqrcode, nzoom )

   LOCAL cBMP, cLine, i , j
   LOCAL leofq

   IF nzoom == NIL
      nzoom := 1
   ENDIF

   IF nzoom < 1
      RETURN cqrcode
   ENDIF

   cBMP  := ""
   cLine := ""

   leofq := .F.
   // i:        Position in cqrcode

   FOR i := 1 TO Len( cqrcode )
      IF .NOT. leofq
         IF SubStr( cqrcode, i, 1 ) == Chr( 10 )
            IF .NOT. ( SubStr( cqrcode, i + 1 , 1 ) == " " )
               // Empty line following, stop here
               leofq := .T.
            ENDIF
            // Count line ending and start with new line

            // Replicate line with zoom factor
            FOR j := 1 TO nzoom
               cBMP  := cBMP + cLine + Chr( 10 )
            NEXT
            //
            cLine := ""
         ELSE  // SUBSTR " "
            cLine := cLine + Replicate( SubStr( cqrcode,i,1 ), nzoom )
         ENDIF // is CHR(10)
      ENDIF // .NOT. leofq

   NEXT

   IF .NOT. Empty( cLine )
      cBMP  := cBMP + cLine + Chr( 10 )
   ENDIF

   // Empty line as mark for EOF
   cBMP  := cBMP + Chr( 10 )

   RETURN cBMP

   // ====
   // Add border to QR code image
   // cqrcode : The QR code in text format
   // nborder : The number of border pixels to add 1 ... n
   // Return the new QR code text string

FUNCTION hwg_QRCodeAddBorder( cqrcode, nborder )

   LOCAL cBMP,  i , nx , cLine , cLineOut
   LOCAL leofq

   IF nborder == NIL
      RETURN cqrcode
   ENDIF

   IF nborder < 1
      RETURN cqrcode
   ENDIF

   cBMP  := ""
   cLineOut := ""

   leofq := .F.
   // i:        Position in cqrcode

   // Add nborder lines to begin
   // Preread first line getting the x size of the QR code
   nx := At( Chr( 10 ), cqrcode )
   cLine := Space( nx + nborder + nborder - 1 ) + Chr( 10 ) // Empty line new
   FOR i := 1 TO nborder
      cBMP  := cBMP + cLine
   NEXT

   FOR i := 1 TO Len( cqrcode )
      IF .NOT. leofq
         IF SubStr( cqrcode, i, 1 ) == Chr( 10 )
            IF .NOT. ( SubStr( cqrcode, i + 1 , 1 ) == " " )
               // Empty line following, stop here
               leofq := .T.
            ENDIF
            // Count line ending and start with new line
            cBMP := cBMP + Space( nborder ) + cLineOut + Space( nborder ) + Chr( 10 )
            cLineOut := ""
         ELSE  // SUBSTR " "
            cLineOut := cLineOut + SubStr( cqrcode, i, 1 )
         ENDIF // is CHR(10)
      ENDIF // .NOT. leofq

   NEXT

   FOR i := 1 TO nborder
      cBMP  := cBMP + cLine
   NEXT

   RETURN cBMP

   // Get the size of a QR code
   // Returns an array with 2 elements: xSize,ySize

FUNCTION hwg_QRCodeGetSize( cqrcode )

   LOCAL aret, xSize, ySize, i, leofq

   aret := {}
   ySize := 0
   leofq := .F.

   xSize := At( Chr( 10 ), cqrcode )

   FOR i := 1 TO Len( cqrcode )
      IF .NOT. leofq
         IF SubStr( cqrcode, i, 1 ) == Chr( 10 )
            IF .NOT. ( SubStr( cqrcode, i + 1 , 1 ) == " " )
               // Empty line following, stop here
               leofq := .T.
            ENDIF
            // Count lines
            ySize := ySize + 1
         ENDIF // is CHR(10)
      ENDIF // .NOT. leofq
   NEXT

   AAdd( aret, xSize )
   AAdd( aret, ySize )

   RETURN aret

   //   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   //   End of Functions for QR encoding
   //   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* ============================ EOF of common.prg =============================
