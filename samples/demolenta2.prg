/*
demolenta2.prg
*/

// Lenta and panels, used as a replacement of a colorized tab
#include "hwgui.ch"

#define CLR_LIGHTGRAY_2 0xaaaaaa
#define CLR_BROWN_1     0x154780
#define CLR_BROWN_2     0x396eaa
#define CLR_BROWN_3     0x6a9cd4
#define CLR_BROWN_4     0x9dc7f6
#define CLR_DLGBACK     0x154780

FUNCTION DemoLenta2( lWithDialog, oDlg )

   LOCAL oFont := HFont():Add( "MS Sans Serif", 0, - 13 )
   LOCAL aPanelList := Array(10), aCaptionList := Array(10), nCont
   LOCAL oLenta, nIndex := 0

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         TITLE "demolenta2.prg - Lenta control"  ;
         AT 210, 10 ;
         SIZE 1024, 768 ;
         FONT oFont
   ENDIF

   ButtonForSample( "demolenta2.prg", oDlg )

   FOR nCont = 1 TO Len( aPanelList )

      @ 20, 150 PANEL aPanelList[ nCont ] ;
         OF oDlg ;
         SIZE 800, 500 ;
         STYLE SS_OWNERDRAW ;
         BACKCOLOR NextBackColor() ;
         ON SIZE { || .T. }

      aPanelList[ nCont ]:oFont := oFont
      aCaptionList[ nCont ] := Chr( 64 + nCont )
      IF nCont != 1          // trying to solve behaviour on tabpage
         aPanelList[ nCont ]:Hide()
      ENDIF
   NEXT

   aCaptionList[ ++nIndex ] := "check"
   DemoCheckBox( .F., aPanelList[ nIndex ] )

   aCaptionList[ ++nIndex ] := "image2"
   DemoImage2( .F., aPanelList[ nIndex ] )

   aCaptionList[ ++nIndex ] := "tab"
   DemoTab( .F., aPanelList[ nIndex ] )

   aCaptionList[ ++nIndex ] := "lenta"
   DemoLenta( .F., aPanelList[ nIndex ] )

   aCaptionList[ ++nIndex ] := "One"
   @ 20,  16 EDITBOX "Edit One" OF aPanelList[ nIndex ] SIZE 200, 26
   @ 20,  46 EDITBOX "Edit Two" OF aPanelList[ nIndex ] SIZE 200, 26
   @ 20,  76 EDITBOX "Edit Three" OF aPanelList[ nIndex ] SIZE 200, 26

   aCaptionList[ ++nIndex ] := "Two"
   @ 20, 16 EDITBOX "Edit Four" OF aPanelList[ nIndex ] SIZE 200, 26
   @ 20, 46 EDITBOX "Edit Five" OF aPanelList[ nIndex ] SIZE 200, 26
   @ 20, 76 EDITBOX "Edit Six" OF aPanelList[ nIndex ] SIZE 200, 26

   aCaptionList[ ++nIndex  ] := "Three"
   @ 20, 16 EDITBOX "Edit Seven" OF aPanelList[ nIndex ] SIZE 200, 26

   aCaptionList[ ++nIndex ] := "Four"
   @ 20, 46 EDITBOX "Edit Eight" OF aPanelList[ nIndex ] SIZE 200, 26

   aCaptionList[ ++nIndex ] := "Five"
   @ 20, 76 EDITBOX "Edit Nine" OF aPanelList[ nIndex ] SIZE 200, 26

   @ 20, 116 LENTA oLenta ;
      OF oDlg ;
      SIZE 60 * Len( aPanelList ), 28 ;
      FONT oFont ;
      ITEMS aCaptionList ;
      ITEMSIZE 60 ;
      HSTYLES LentaStyles( aPanelList ) ;
      ON CLICK { || LentaClick( oLenta, aPanelList ) }

   //oLenta := HLenta():New( , , 20, 16, 160, 28, oFont, , , bTab, , , ;
   //   { "First", "Second" }, 80, aStyleLenta )

   oLenta:Value := 1
   LentaClick( oLenta, aPanelList )

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
      oFont:Release()
   ENDIF

   RETURN Nil

STATIC FUNCTION LentaClick( oLenta, aPanelList )

   LOCAL oChild

   IF ! Empty( aPanelList )
      FOR EACH oChild IN aPanelList
         IF oChild:__EnumIndex() == oLenta:Value
            oChild:Show()
         ELSE
            oChild:Hide()
         ENDIF
      NEXT
   ENDIF

   RETURN .T.

STATIC FUNCTION LentaStyles( aPanelList )

   LOCAL nIndex := 0, aList := {}, nCont
   LOCAL aStyleList := { ;
      HStyle():New( { CLR_LIGHTGRAY_2 }, 1 ), ;
      HStyle():New( { CLR_DLGBACK , CLR_BROWN_4 }, 1, , 2, CLR_DLGBACK ) }

   FOR nCont = 1 TO Len( aPanelList )
      nIndex += 1
      IF nIndex > Len( aStyleList )
         nIndex := 1
      ENDIF
      AAdd( aList, aStyleList[ nIndex ] )
   NEXT

   RETURN aList

STATIC FUNCTION NextBackColor()

   LOCAL aList := { ;
      16772062, ;
      CLR_LIGHTGRAY_2, ;
      CLR_BROWN_2 , ;
      CLR_BROWN_3 , ;
      CLR_BROWN_4 , ;
      CLR_DLGBACK  }

   STATIC nIndex := 0

   nIndex += 1
   IF nIndex > Len( aList )
      nIndex := 1
   ENDIF

   RETURN aList[ nIndex ]

#include "demo.ch"
