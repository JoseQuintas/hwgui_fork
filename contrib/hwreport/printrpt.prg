/*
 * Repbuild - Visual Report Builder
 * Printing functions
 *
 * Copyright 2001-2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "repbuild.h"
#include "repmain.h"

MEMVAR aPaintRep, lAddMode, oFontStandard, aImgs

FUNCTION _hwr_PrintRpt

   LOCAL hDCwindow
   LOCAL oPrinter := HPrinter():New()
   LOCAL aPrnCoors, prnXCoef, prnYCoef
   LOCAL oFontStdPrn
   LOCAL i, aMetr, aTmetr, dKoef
   LOCAL oFont
#ifdef __GTK__
   LOCAL hDC := oPrinter:hDC
#else
   LOCAL hDC := oPrinter:hDCPrn
   LOCAL fontKoef
#endif
   PRIVATE lAddMode := .F.
   PRIVATE aImgs := {}

   IF Empty( hDC )
      RETURN .F.
   ENDIF

#ifdef __GTK__
   aPrnCoors := hwg_gp_Getdevicearea( hDC )
#else
   aPrnCoors := hwg_GetDeviceArea( hDC )
#endif
   prnXCoef := ( aPrnCoors[ 1 ] / aPaintRep[ FORM_WIDTH ] ) / aPaintRep[ FORM_XKOEF ]
   prnYCoef := ( aPrnCoors[ 2 ] / aPaintRep[ FORM_HEIGHT ] ) / aPaintRep[ FORM_XKOEF ]
   //hwg_writelog( str(aPrnCoors[2])+" / "+str(prnYCoef)+" / "+str(aPaintRep[FORM_XKOEF])+" // "+;
   //   str(aPaintRep[FORM_HEIGHT]) +" / "+str(oPrinter:nHeight)+" / "+str(oPrinter:nHeight/aPaintRep[FORM_HEIGHT]) )

   hDCwindow := hwg_Getdc( Hwindow():GetMain():handle )
   aMetr := hwg_GetDeviceArea( hDCwindow )
   hwg_Selectobject( hDCwindow, oFontStandard:handle )
   aTmetr := hwg_Gettextmetric( hDCwindow )
   //---
   dKoef := ( aMetr[1] - XINDENT ) / aTmetr[2]
   (dKoef) // used only when __GTK__ -w3 -es2
   //---
   hwg_Releasedc( Hwindow():GetMain():handle, hDCwindow )

#ifdef __GTK__
   oFontStdPrn := oPrinter:AddFont( "Arial", -13, .F., .F., .F., 204 )
#else
   oFontStdPrn := HFont():Add( "Arial", 0, - 13, 400, 204 )
#endif

#ifndef __GTK__
   hwg_Selectobject( hDC, oFontStdPrn:handle )
   fontKoef := ( aPrnCoors[1] / hwg_Gettextmetric(hDC)[2] ) / dKoef
#endif
   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_TEXT
         oFont := aPaintRep[FORM_ITEMS,i,ITEM_FONT]
#ifdef __GTK__
         aPaintRep[ FORM_ITEMS, i, ITEM_GROUP ] := oPrinter:AddFont( oFont:name, ;
            Round( oFont:height * prnYCoef, 0 ), (oFont:weight>400), ;
            (oFont:italic>0), .F., oFont:charset )
#else
         aPaintRep[FORM_ITEMS,i,ITEM_GROUP] := HFont():Add( oFont:name, ;
            oFont:width, Round( oFont:height * fontKoef, 0 ), oFont:weight, ;
            oFont:charset, oFont:italic )
#endif
         //hwg_writelog( str(ofont:height)+" "+str(prnycoef)+" "+str(aPaintRep[ FORM_ITEMS, i, ITEM_GROUP ]:height) )
      ENDIF
   NEXT

   oPrinter:StartDoc( .T. )
   oPrinter:StartPage()

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      //IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] != TYPE_BITMAP
         hwg_Hwr_PrintItem( oPrinter, aPaintRep[FORM_ITEMS,i], prnXCoef, prnYCoef, 0, .F. )
      //ENDIF
   NEXT
   /*
   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_BITMAP
         hwg_Hwr_PrintItem( oPrinter, aPaintRep[FORM_ITEMS,i], prnXCoef, prnYCoef, 0, .F. )
      ENDIF
   NEXT
   */
   IF !Empty( aImgs )
      FOR i := 1 TO Len( aImgs )
         oPrinter:Bitmap( aImgs[i,1], aImgs[i,2], aImgs[i,3], aImgs[i,4], , aImgs[i,5], aImgs[i,6] )
      NEXT
   ENDIF

   oPrinter:EndPage()
   oPrinter:EndDoc()

   oPrinter:Preview()
   oPrinter:End()

   oFontStdPrn:Release()
   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_TEXT
         aPaintRep[FORM_ITEMS,i,ITEM_GROUP]:Release()
         aPaintRep[FORM_ITEMS,i,ITEM_GROUP] := Nil
      ENDIF
   NEXT
   aImgs := Nil

   RETURN Nil
