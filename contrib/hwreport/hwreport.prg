/*
 * $Id$
 *
 * Repbuild - Visual Report Builder
 * Main file
 *
 * Copyright 2001-2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

/*
  DF7BE: (started 2021-02-25)
  Port from Borland res file "repbuild.rc" (not compatible with MinGW windres compiler and LINUX/GTK)
  to HWGUI commands, Version 1.2

  Hint for port to HWGUI commands:
                                               ID
                                               !    ?
                                               !    !   ?
                                               !    !   !    ?
                                               !    !   !    !
                                               v    v   v    v
  AboutDlg DIALOG LOADONCALL FIXED DISCARDABLE 100, 63, 111, 96

  The sizes and positions are not plausible,
  so forms created new with the HWGUI designer.

  At bottom of this file the contents of the rc file is added as an inline comment
  for archive purposes.

*/

#include "hwgui.ch"
#include "repbuild.h"
#include "repmain.h"

   // #include "hwgui.ch"
// #include "common.ch"
// #ifdef __XHARBOUR__
// #include "ttable.ch"
// #endif
//#ifdef __GTK__
// #include "gtk.ch"
// #endif

#ifndef SB_VERT
#define SB_VERT         1
#endif
#define IDCW_STATUS  2001

   STATIC nAddItem := 0, nMarkerType := 0
   STATIC crossCursor, vertCursor, horzCursor
   STATIC itemPressed := 0, mPos := { 0, 0 }
   STATIC itemBorder := 0, itemSized := 0, resizeDirection := 0
   STATIC aInitialSize := { { 50,20 }, { 60,4 }, { 4,60 }, { 60,40 }, { 40,40 }, { 16,10 } }
   STATIC aMarkers := { "PH", "SL", "EL", "PF", "EPF", "DF" }
   STATIC oPenDivider, oPenLine
   STATIC oBrushWhite, oBrushLGray, oBrushGray
   STATIC lPreviewMode := .F.

   MEMVAR mypath
   MEMVAR aPaintRep
   MEMVAR oPenBorder, oFontSmall, oFontStandard, oFontDlg, lastFont
   MEMVAR aItemTypes
   MEMVAR cDirSep

FUNCTION Main()
   LOCAL oMainWindow, oPanel, oIcon

   PUBLIC cDirSep := hwg_GetDirSep()
   PUBLIC mypath := cDirSep + CurDir() + iif( Empty( CurDir() ), "", cDirSep )
   PUBLIC aPaintRep := Nil
   PUBLIC oPenBorder, oFontSmall, oFontStandard, oFontDlg , lastFont := Nil
   PUBLIC aItemTypes := { "TEXT", "HLINE", "VLINE", "BOX", "BITMAP", "MARKER" }

   // Icon from hex value "ICON_1"
   oIcon := HIcon():AddString( "ICON_1" , hwg_cHex2Bin( hwreport_icon_hex() ) )

   SET DECIMALS TO 4
#ifdef __GTK__
   crossCursor := hwg_Loadcursor( GDK_CROSS )
   horzCursor := hwg_Loadcursor( GDK_SIZING )
   vertCursor := hwg_Loadcursor( GDK_HAND1 )
#else
   crossCursor := hwg_Loadcursor( IDC_CROSS )
   horzCursor := hwg_Loadcursor( IDC_SIZEWE )
   vertCursor := hwg_Loadcursor( IDC_SIZENS )
#endif
   oPenBorder := HPen():Add( PS_SOLID, 1, hwg_ColorC2N( "800080" ) )
   oPenLine   := HPen():Add( PS_SOLID, 1, hwg_ColorC2N( "000000" ) )
   oPenDivider := HPen():Add( PS_DOT, 1, hwg_ColorC2N( "C0C0C0" ) )

   oBrushWhite := HBrush():Add( CLR_WHITE )
   oBrushLGray := HBrush():Add( CLR_LGRAY )
   oBrushGray  := HBrush():Add( CLR_GRAY )

   oFontSmall := HFont():Add( "Courier", 0, -8 )
   oFontStandard := HFont():Add( "Courier", 0, - 13, 400, 204 )
   oFontDlg   := HFont():Add( "MS Sans Serif" , 0 , -13 )

   INIT WINDOW oMainWindow MAIN TITLE "Visual Report Builder"    ;
      SIZE hwg_getDesktopWidth()-100, hwg_getDesktopHeight()-100 ;
      ICON oIcon COLOR COLOR_3DSHADOW                            ;
      ON EXIT {||_hwr_CloseReport() }

   @ 0,0 PANEL oPanel SIZE oMainWindow:nWidth, oMainWindow:nHeight-24 ;
      STYLE SS_OWNERDRAW ;
      ON PAINT {|o| PaintMain( o ) } ON SIZE {|o,x,y|o:Move( ,,x,y-24 )}
   oPanel:bOther := { |o, m, wp, lp|MessagesProc( o, m, wp, lp ) }

   ADD STATUS TO oMainWindow ID IDCW_STATUS PARTS 240, 180, 0

   MENU OF oMainWindow
      MENU TITLE "&File"
         MENUITEM "&New" ACTION NewReport()
         MENUITEM "&Open" ACTION _hwr_FileDlg( .T. )
         MENUITEM "&Close" ID IDM_CLOSE ACTION _hwr_CloseReport()
         SEPARATOR
         MENUITEM "&Save" ID IDM_SAVE ACTION _hwr_SaveReport()
         MENUITEM "Save &as..." ID IDM_SAVEAS ACTION _hwr_FileDlg( .F. )
         SEPARATOR
         MENUITEM "&Print static" ID IDM_PRINT ACTION _hwr_PrintRpt()
         MENUITEM "&Print full" ID IDM_PREVIEW ACTION ( hwg_hwr_Print( aPaintRep,, .T. ) )
         SEPARATOR
         MENUITEM "&Exit" ID IDM_EXIT ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Items"
         MENUITEM "&Text"  ACTION nAddItem := TYPE_TEXT
         MENUITEM "&Horizontal Line" ACTION nAddItem := TYPE_HLINE
         MENUITEM "&Vertical Line" ACTION nAddItem := TYPE_VLINE
         MENUITEM "&Box" ACTION nAddItem := TYPE_BOX
         MENUITEM "B&itmap" ACTION nAddItem := TYPE_BITMAP
         SEPARATOR
         MENU TITLE "&Markers"
            MENUITEM "&Page Header" ACTION ( nAddItem := TYPE_MARKER, nMarkerType := MARKER_PH )
            MENUITEM "&Start line" ACTION ( nAddItem := TYPE_MARKER, nMarkerType := MARKER_SL )
            MENUITEM "&End line" ACTION ( nAddItem := TYPE_MARKER, nMarkerType := MARKER_EL )
            MENUITEM "Page &Footer" ACTION ( nAddItem := TYPE_MARKER, nMarkerType := MARKER_PF )
            MENUITEM "E&nd of Page Footer" ACTION ( nAddItem := TYPE_MARKER, nMarkerType := MARKER_EPF )
            MENUITEM "&Document Footer" ACTION ( nAddItem := TYPE_MARKER, nMarkerType := MARKER_DF )
         ENDMENU
         SEPARATOR
         MENUITEM "&Delete item" ACTION DeleteItem()
      ENDMENU
      MENU TITLE "&Options"
         MENUITEM "&Form options" ID IDM_FOPT ACTION FormOptions()
         MENUITEMCHECK "&Preview" ID IDM_VIEW1 ACTION FPreview()
      ENDMENU
      MENUITEM "&About" ID IDM_ABOUT ACTION About()
   ENDMENU

   hwg_Enablemenuitem( , IDM_CLOSE, .F. , .T. )
   hwg_Enablemenuitem( , IDM_SAVE, .F. , .T. )
   hwg_Enablemenuitem( , IDM_SAVEAS, .F. , .T. )
   hwg_Enablemenuitem( , IDM_PRINT, .F. , .T. )
   hwg_Enablemenuitem( , IDM_PREVIEW, .F. , .T. )
   hwg_Enablemenuitem( , IDM_FOPT, .F. , .T. )
   hwg_Enablemenuitem( , IDM_VIEW1, .F. , .T. )
   hwg_Enablemenuitem( , 1, .F. , .F. )

   SET KEY 0, VK_LEFT TO KeyActions( VK_LEFT )
   SET KEY 0, VK_RIGHT TO KeyActions( VK_RIGHT )
   SET KEY 0, VK_UP TO KeyActions( VK_UP )
   SET KEY 0, VK_DOWN TO KeyActions( VK_DOWN )
   SET KEY 0, VK_DELETE TO KeyActions( VK_DELETE )
   SET KEY 0, VK_NEXT TO KeyActions( VK_NEXT )
   SET KEY 0, VK_PRIOR TO KeyActions( VK_PRIOR )

   ACTIVATE WINDOW oMainWindow CENTER

   RETURN Nil

STATIC FUNCTION About()

   LOCAL oDlg

   INIT DIALOG oDlg TITLE "About" ;
      AT 0, 0 SIZE 400, 330 FONT HWindow():GetMain():oFont STYLE DS_CENTER

   @ 20, 40 SAY "HwReport" SIZE 360, 26 STYLE SS_CENTER COLOR CLR_VDBLUE
   @ 20, 64 SAY "Version " + APP_VERSION SIZE 360, 26 STYLE SS_CENTER COLOR CLR_VDBLUE
   @ 20, 100 SAY "Copyright 2001-2021 Alexander S.Kresin" SIZE 360, 26 STYLE SS_CENTER COLOR CLR_VDBLUE
   @ 20, 124 SAY "http://www.kresin.ru" LINK "http://www.kresin.ru" SIZE 360, 26 STYLE SS_CENTER
   @ 20, 160 LINE LENGTH 360
   @ 20, 180 SAY hwg_Version() SIZE 360, 26 STYLE SS_CENTER COLOR CLR_DBLUE

   @ 150, 250 BUTTON "Close" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() } ON SIZE ANCHOR_BOTTOMABS + ANCHOR_RIGHTABS + ANCHOR_LEFTABS

   ACTIVATE DIALOG oDlg

   RETURN Nil

STATIC FUNCTION FPreview()

   //hwg_Showscrollbar( oMainWindow:handle,SB_VERT,hwg_Ischeckedmenuitem(,IDM_VIEW1 ) )
   lPreviewMode := !lPreviewMode
   hwg_Checkmenuitem( ,IDM_VIEW1, lPreviewMode )
   IF lPreviewMode
      DeselectAll()
   ENDIF
   Hwindow():GetMain():oPanel:Refresh()

   RETURN Nil

STATIC FUNCTION NewReport()
   LOCAL oDlg
   LOCAL oRb1, oRb2

   // FROM RESOURCE "DLG_NEWREP"
   INIT DIALOG oDlg TITLE "" AT 460, 260 SIZE 260, 220

   @ 26, 12 GROUPBOX "Page size"  SIZE 200, 100

   RADIOGROUP
   @ 30, 36 RADIOBUTTON oRb1 CAPTION "A4 portrait ( 210x297 )" SIZE 181, 24
   @ 30, 64 RADIOBUTTON oRb2 CAPTION "A4 landscape ( 297x210 )" SIZE 187, 24
   END RADIOGROUP SELECTED 1

   @ 25, 144 BUTTON "OK" SIZE 90, 28 ;
      STYLE WS_TABSTOP ON CLICK {|| EndNewrep( oDlg ) }
   @ 145, 144 BUTTON "Cancel" ID IDCANCEL SIZE 90, 28 STYLE WS_TABSTOP

   oDlg:Activate()

   RETURN Nil

STATIC FUNCTION EndNewrep( oDlg )

   LOCAL oMainWindow := HWindow():GetMain()

   aPaintRep := { 0, 0, 0, 0, 0, {}, "", "", .F. , 0, Nil }
   IF oDlg:oRb1:Value
      aPaintRep[FORM_WIDTH] := 210 ; aPaintRep[FORM_HEIGHT] := 297
   ELSE
      aPaintRep[FORM_WIDTH] := 297 ; aPaintRep[FORM_HEIGHT] := 210
   ENDIF

   aPaintRep[FORM_Y] := 0
   hwg_Enablemenuitem( , 1, .T. , .F. )
   hwg_WriteStatus( oMainWindow, 2, LTrim( Str(aPaintRep[FORM_WIDTH],4 ) ) + "x" + ;
      LTrim( Str( aPaintRep[FORM_HEIGHT],4 ) ) + "  Items: " + LTrim( Str( Len(aPaintRep[FORM_ITEMS] ) ) ) )
   oMainWindow:Refresh()

   oDlg:Close()

   RETURN Nil

STATIC FUNCTION PaintMain( oWnd )
   LOCAL hWnd := oWnd:handle
   LOCAL x1 := LEFT_INDENT, y1 := TOP_INDENT, x2, y2, oldBkColor, aMetr, nWidth, nHeight
   LOCAL n1cm, xt, yt
   LOCAL i
   LOCAL aCoors
   LOCAL step, nsteps  //, kolsteps

#ifdef __GTK__
   LOCAL hDC := hwg_Getdc( hWnd )
#else
   LOCAL pps := hwg_Definepaintstru()
   LOCAL hDC := hwg_Beginpaint( hWnd, pps )
#endif

   IF aPaintRep == Nil
#ifdef __GTK__
     hwg_Releasedc( hWnd, hDC )
#else
     hwg_Endpaint( hWnd, pps )
#endif
      Return - 1
   ENDIF

   aCoors := hwg_Getclientrect( hWnd )

   IF aPaintRep[FORM_XKOEFCONST] == 0
      aMetr := hwg_GetDeviceArea( hDC )
      aPaintRep[FORM_XKOEFCONST] := ( aMetr[1] - XINDENT )/aPaintRep[FORM_WIDTH]
   ENDIF

   IF lPreviewMode
      aPaintRep[FORM_Y] := 0
      IF aPaintRep[FORM_WIDTH] > aPaintRep[FORM_HEIGHT]
         nWidth := aCoors[3] - aCoors[1] - XINDENT
         nHeight := Round( nWidth * aPaintRep[FORM_HEIGHT] / aPaintRep[FORM_WIDTH], 0 )
         IF nHeight > aCoors[4] - aCoors[2] - YINDENT
            nHeight := aCoors[4] - aCoors[2] - YINDENT
            nWidth := Round( nHeight * aPaintRep[FORM_WIDTH] / aPaintRep[FORM_HEIGHT], 0 )
         ENDIF
      ELSE
         nHeight := aCoors[4] - aCoors[2] - YINDENT
         nWidth := Round( nHeight * aPaintRep[FORM_WIDTH] / aPaintRep[FORM_HEIGHT], 0 )
         IF nWidth > aCoors[3] - aCoors[1] - XINDENT
            nWidth := aCoors[3] - aCoors[1] - XINDENT
// -----
            nHeight := Round( nWidth * aPaintRep[FORM_HEIGHT] / aPaintRep[FORM_WIDTH], 0 )
            (nHeight) // this value is not used anymore, why error on github ubuntu only?
// -----
         ENDIF
      ENDIF
      aPaintRep[FORM_XKOEF] := nWidth/aPaintRep[FORM_WIDTH]
   ELSE
      aPaintRep[FORM_XKOEF] := aPaintRep[FORM_XKOEFCONST]
   ENDIF

   x2 := x1 + Round( aPaintRep[FORM_WIDTH] * aPaintRep[FORM_XKOEF], 0 ) - 1
   y2 := y1 + Round( aPaintRep[FORM_HEIGHT] * aPaintRep[FORM_XKOEF], 0 ) - aPaintRep[FORM_Y] - 1
   n1cm := Round( aPaintRep[FORM_XKOEF] * 10, 0 )
   step := n1cm * 2
   nsteps := Round( aPaintRep[FORM_Y]/step, 0 )
   hwg_Fillrect( hDC, 0, 0, LEFT_INDENT - 12, aCoors[4], oBrushLGray:handle )

   i := 0
   hwg_Selectobject( hDC, oPenLine:handle )
   hwg_Selectobject( hDC, iif( lPreviewMode,oFontSmall:handle,oFontStandard:handle ) )
   oldBkColor := hwg_Setbkcolor( hDC, CLR_LGRAY )
   DO WHILE i <= aPaintRep[FORM_WIDTH]/10 .AND. i * n1cm < ( aCoors[3] - aCoors[1] - LEFT_INDENT )
      xt := x1 + i * n1cm
      hwg_Drawline( hDC, xt + Round( n1cm/4,0 ), 0, xt + Round( n1cm/4,0 ), 4 )
      hwg_Drawline( hDC, xt + Round( n1cm/2,0 ), 0, xt + Round( n1cm/2,0 ), 8 )
      hwg_Drawline( hDC, xt + Round( n1cm * 3/4,0 ), 0, xt + Round( n1cm * 3/4,0 ), 4 )
      hwg_Drawline( hDC, xt, 0, xt, 12 )
      IF i > 0 .AND. i < aPaintRep[FORM_WIDTH]/10
         hwg_Drawtext( hDC, LTrim( Str(i,2 ) ), xt - 15, 12, xt + 15, TOP_INDENT - 5, DT_CENTER )
      ENDIF
      i ++
   ENDDO

   i := 0
   DO WHILE i <= aPaintRep[FORM_HEIGHT]/10 .AND. i * n1cm < ( aCoors[4] - aCoors[2] - TOP_INDENT )
      yt := y1 + i * n1cm
      hwg_Drawline( hDC, 0, yt + Round( n1cm/4,0 ), 4, yt + Round( n1cm/4,0 ) )
      hwg_Drawline( hDC, 0, yt + Round( n1cm/2,0 ), 8, yt + Round( n1cm/2,0 ) )
      hwg_Drawline( hDC, 0, yt + Round( n1cm * 3/4,0 ), 4, yt + Round( n1cm * 3/4,0 ) )
      hwg_Drawline( hDC, 0, yt, 12, yt )
      IF i > 0 .AND. i < aPaintRep[FORM_HEIGHT]/10
         hwg_Drawtext( hDC, LTrim( Str(i + nsteps * 2,2 ) ), 12, yt - 10, LEFT_INDENT - 12, yt + 10, DT_CENTER )
      ENDIF
      i ++
   ENDDO
   hwg_Drawline( hDC, x1, TOP_INDENT-1, x2, TOP_INDENT-1 )

   hwg_Fillrect( hDC, LEFT_INDENT - 12, y1, x1, y2, oBrushGray:handle )
   hwg_Fillrect( hDC, x1, y1, x2, y2, oBrushWhite:handle )
   //hwg_Setbkcolor( hDC, hwg_Getsyscolor( COLOR_WINDOW ) )
   hwg_Setbkcolor( hDC, CLR_WHITE )
   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] != TYPE_BITMAP
         PaintItem( hDC, aPaintRep[FORM_ITEMS,i], aCoors, lPreviewMode )
      ENDIF
   NEXT

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_BITMAP
         PaintItem( hDC, aPaintRep[FORM_ITEMS,i], aCoors, lPreviewMode )
      ENDIF
   NEXT
   hwg_Setbkcolor( hDC, oldBkColor )
   /*
   kolsteps := Round( ( Round(aPaintRep[FORM_HEIGHT] * aPaintRep[FORM_XKOEF],0 ) - ;
      ( aCoors[4] - aCoors[2] - TOP_INDENT ) ) / step, 0 ) + 1

   IF lPreviewMode
      hwg_Setscrollinfo( hWnd, SB_VERT, 1 )
   ELSE
      hwg_Setscrollinfo( hWnd, SB_VERT, 1, nSteps + 1, 1, kolsteps + 1 )
   ENDIF
   */
#ifdef __GTK__
   hwg_Releasedc( hWnd, hDC )
#else
   hwg_Endpaint( hWnd, pps )
#endif

   RETURN 0

STATIC FUNCTION PaintItem( hDC, aItem, aCoors )
   LOCAL x1 := LEFT_INDENT + aItem[ITEM_X1], y1 := TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y]
   LOCAL x2 := x1 + aItem[ITEM_WIDTH] - 1, y2 := y1 + aItem[ITEM_HEIGHT] - 1

   IF lPreviewMode
      x1 := LEFT_INDENT + aItem[ITEM_X1] * aPaintRep[FORM_XKOEF]/aPaintRep[FORM_XKOEFCONST]
      x2 := LEFT_INDENT + ( aItem[ITEM_X1] + aItem[ITEM_WIDTH] - 1 ) * aPaintRep[FORM_XKOEF]/aPaintRep[FORM_XKOEFCONST]
      y1 := TOP_INDENT + aItem[ITEM_Y1] * aPaintRep[FORM_XKOEF]/aPaintRep[FORM_XKOEFCONST]
      y2 := TOP_INDENT + ( aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - 1 ) * aPaintRep[FORM_XKOEF]/aPaintRep[FORM_XKOEFCONST]
   ENDIF
   IF y1 >= TOP_INDENT .AND. y1 <= aCoors[4]
      IF aItem[ITEM_STATE] == STATE_SELECTED .OR. aItem[ITEM_STATE] == STATE_PRESSED
         hwg_Fillrect( hDC, x1 - 3, y1 - 3, x2 + 3, y2 + 3, oBrushLGray:handle )
         hwg_Selectobject( hDC, oPenBorder:handle )
         hwg_Rectangle( hDC, x1 - 3, y1 - 3, x2 + 3, y2 + 3 )
         hwg_Rectangle( hDC, x1 - 1, y1 - 1, x2 + 1, y2 + 1 )
      ENDIF
      IF aItem[ITEM_TYPE] == TYPE_TEXT
         IF Empty( aItem[ITEM_CAPTION] )
            hwg_Fillrect( hDC, x1, y1, x2, y2, oBrushGray:handle )
         ELSE
            hwg_Selectobject( hDC, iif( lPreviewMode,oFontSmall:handle,aItem[ITEM_FONT]:handle ) )
            hwg_Drawtext( hDC, aItem[ITEM_CAPTION], x1, y1, x2, y2, ;
               iif( aItem[ITEM_ALIGN] == 0, DT_LEFT, iif( aItem[ITEM_ALIGN] == 1,DT_RIGHT,DT_CENTER ) ) )
         ENDIF
      ELSEIF aItem[ITEM_TYPE] == TYPE_HLINE
         hwg_Selectobject( hDC, aItem[ITEM_PEN]:handle )
         hwg_Drawline( hDC, x1, y1, x2, y1 )
      ELSEIF aItem[ITEM_TYPE] == TYPE_VLINE
         hwg_Selectobject( hDC, aItem[ITEM_PEN]:handle )
         hwg_Drawline( hDC, x1, y1, x1, y2 )
      ELSEIF aItem[ITEM_TYPE] == TYPE_BOX
         hwg_Selectobject( hDC, aItem[ITEM_PEN]:handle )
         hwg_Rectangle( hDC, x1, y1, x2, y2 )
      ELSEIF aItem[ITEM_TYPE] == TYPE_BITMAP
         IF aItem[ITEM_BITMAP] == Nil
            hwg_Fillrect( hDC, x1, y1, x2, y2, oBrushGray:handle )
         ELSE
            hwg_Drawbitmap( hDC, aItem[ITEM_BITMAP]:handle, SRCAND, x1, y1, x2 - x1 + 1, y2 - y1 + 1 )
         ENDIF
      ELSEIF aItem[ITEM_TYPE] == TYPE_MARKER
         hwg_Selectobject( hDC, oPenDivider:handle )
         hwg_Drawline( hDC, LEFT_INDENT, y1, LEFT_INDENT - 1 + Round( aPaintRep[FORM_WIDTH] * aPaintRep[FORM_XKOEF],0 ), y1 )
         hwg_Selectobject( hDC, oFontSmall:handle )
         hwg_Drawtext( hDC, aItem[ITEM_CAPTION], x1, y1, x2, y2, DT_CENTER )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION KeyActions( nKey )

   LOCAL hWnd := HWindow():GetMain():oPanel:handle, i, aItem

   IF Empty( aPaintRep )
      RETURN -1
   ENDIF
   IF nKey == VK_DOWN        // Down
      FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
         IF aPaintRep[FORM_ITEMS,i,ITEM_STATE] == STATE_SELECTED
            aItem := aPaintRep[FORM_ITEMS,i]
            IF aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] < aPaintRep[FORM_HEIGHT] * aPaintRep[FORM_XKOEFCONST]
               aItem[ITEM_Y1] ++
               aPaintRep[FORM_CHANGED] := .T.
               WriteItemInfo( aItem )
               hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aItem[ITEM_X1] - 3, ;
                  TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 4, ;
                  LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] + 3, ;
                  TOP_INDENT + aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - aPaintRep[FORM_Y] + 3 )
               IF aItem[ITEM_TYPE] == TYPE_MARKER
                  hwg_Invalidaterect( hWnd, 0, LEFT_INDENT, ;
                     TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y], ;
                     LEFT_INDENT - 1 + Round( aPaintRep[FORM_WIDTH] * aPaintRep[FORM_XKOEF], 0 ), ;
                     TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] )
               ENDIF
               //hwg_Postmessage( hWnd, WM_PAINT, 0, 0 )
               hwg_Redrawwindow( hWnd )
            ENDIF
         ENDIF
      NEXT
   ELSEIF nKey == VK_UP    // Up
      FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
         IF aPaintRep[FORM_ITEMS,i,ITEM_STATE] == STATE_SELECTED
            aItem := aPaintRep[FORM_ITEMS,i]
            IF aItem[ITEM_Y1] > 1
               aItem[ITEM_Y1] --
               aPaintRep[FORM_CHANGED] := .T.
               WriteItemInfo( aItem )
               hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aItem[ITEM_X1] - 3, ;
                  TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
                  LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] + 3, ;
                  TOP_INDENT + aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - aPaintRep[FORM_Y] + 4 )
               IF aItem[ITEM_TYPE] == TYPE_MARKER
                  hwg_Invalidaterect( hWnd, 0, LEFT_INDENT, ;
                     TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y], ;
                     LEFT_INDENT - 1 + Round( aPaintRep[FORM_WIDTH] * aPaintRep[FORM_XKOEF], 0 ), ;
                     TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] )
               ENDIF
               //hwg_Postmessage( hWnd, WM_PAINT, 0, 0 )
               hwg_Redrawwindow( hWnd )
            ENDIF
         ENDIF
      NEXT
   ELSEIF nKey == VK_RIGHT    // Right
      FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
         IF aPaintRep[FORM_ITEMS,i,ITEM_STATE] == STATE_SELECTED
            aItem := aPaintRep[FORM_ITEMS,i]
            IF aItem[ITEM_TYPE] != TYPE_MARKER .AND. ;
                  aItem[ITEM_X1] + aItem[ITEM_WIDTH] < aPaintRep[FORM_WIDTH] * aPaintRep[FORM_XKOEFCONST]
               aItem[ITEM_X1] ++
               aPaintRep[FORM_CHANGED] := .T.
               WriteItemInfo( aItem )
               hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aItem[ITEM_X1] - 4, ;
                  TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
                  LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] + 3, ;
                  TOP_INDENT + aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - aPaintRep[FORM_Y] + 3 )
               //hwg_Postmessage( hWnd, WM_PAINT, 0, 0 )
               hwg_Redrawwindow( hWnd )
            ENDIF
         ENDIF
      NEXT
   ELSEIF nKey == VK_LEFT    // Left
      FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
         IF aPaintRep[FORM_ITEMS,i,ITEM_STATE] == STATE_SELECTED
            aItem := aPaintRep[FORM_ITEMS,i]
            IF aItem[ITEM_TYPE] != TYPE_MARKER .AND. aItem[ITEM_X1] > 1
               aItem[ITEM_X1] --
               aPaintRep[FORM_CHANGED] := .T.
               WriteItemInfo( aItem )
               hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aItem[ITEM_X1] - 3, ;
                  TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
                  LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] + 4, ;
                  TOP_INDENT + aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - aPaintRep[FORM_Y] + 3 )
               //hwg_Postmessage( hWnd, WM_PAINT, 0, 0 )
               hwg_Redrawwindow( hWnd )
            ENDIF
         ENDIF
      NEXT
   ELSEIF nKey == VK_DELETE
      DeleteItem()
   ELSEIF nKey == VK_NEXT    // PageDown
      VScroll( hWnd, SB_LINEDOWN )
   ELSEIF nKey == VK_PRIOR   // PageUp
      VScroll( hWnd, SB_LINEUP )
   ENDIF

   RETURN -1

STATIC FUNCTION MessagesProc( oWnd, msg, wParam, lParam )
   LOCAL hWnd := oWnd:handle

   wParam := hwg_PtrToUlong( wParam )
   lParam := hwg_PtrToUlong( lParam )

   IF msg == WM_VSCROLL
      Vscroll( hWnd, hwg_Loword( wParam ), hwg_Hiword( wParam ) )
   ELSEIF msg == WM_MOUSEMOVE
      MouseMove( wParam, hwg_Loword( lParam ), hwg_Hiword( lParam ) )
   ELSEIF msg == WM_LBUTTONDOWN
      LButtonDown( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
   ELSEIF msg == WM_LBUTTONUP
      LButtonUp( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
   ELSEIF msg == WM_LBUTTONDBLCLK
      _hwr_LButtonDbl( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
   ENDIF

   Return - 1

STATIC FUNCTION VSCROLL( hWnd, nScrollCode, nNewPos )
   LOCAL step  := Round( aPaintRep[FORM_XKOEF] * 10, 0 ) * 2, nsteps := aPaintRep[FORM_Y]/step, kolsteps
   LOCAL aCoors := hwg_Getclientrect( hWnd )

   IF nScrollCode == SB_LINEDOWN
      kolsteps := Round( ( Round(aPaintRep[FORM_HEIGHT] * aPaintRep[FORM_XKOEF],0 ) - ;
         ( aCoors[4] - aCoors[2] - TOP_INDENT ) ) / step, 0 ) + 1
      IF nsteps < kolsteps
         aPaintRep[FORM_Y] += step
         nsteps ++
         IF nsteps >= kolsteps
            hwg_Redrawwindow( hWnd, RDW_ERASE + RDW_INVALIDATE )
         ELSE
            hwg_Invalidaterect( hWnd, 0, 0, TOP_INDENT, aCoors[3], aCoors[4] )
            //hwg_Sendmessage( hWnd, WM_PAINT, 0, 0 )
            hwg_Redrawwindow( hWnd )
         ENDIF
      ENDIF
   ELSEIF nScrollCode == SB_LINEUP
      IF nsteps > 0
         aPaintRep[FORM_Y] -= step
         hwg_Invalidaterect( hWnd, 0, 0, TOP_INDENT, aCoors[3], aCoors[4] )
         //hwg_Postmessage( hWnd, WM_PAINT, 0, 0 )
         hwg_Redrawwindow( hWnd )
      ENDIF
   ELSEIF nScrollCode == SB_THUMBTRACK
      IF -- nNewPos != nsteps
         kolsteps := Round( ( Round(aPaintRep[FORM_HEIGHT] * aPaintRep[FORM_XKOEF],0 ) - ;
            ( aCoors[4] - aCoors[2] - TOP_INDENT ) ) / step, 0 ) + 1
         aPaintRep[FORM_Y] := nNewPos * step
         IF aPaintRep[FORM_Y]/step >= kolsteps
            hwg_Redrawwindow( hWnd, RDW_ERASE + RDW_INVALIDATE )
         ELSE
            hwg_Invalidaterect( hWnd, 0, 0, TOP_INDENT, aCoors[3], aCoors[4] )
            //hwg_Postmessage( hWnd, WM_PAINT, 0, 0 )
            hwg_Redrawwindow( hWnd )
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION MouseMove( wParam, xPos, yPos )
   LOCAL x1 := LEFT_INDENT, y1 := TOP_INDENT, x2, y2
   LOCAL hWnd
   LOCAL aItem, i, dx, dy

   IF aPaintRep == Nil .OR. lPreviewMode
      RETURN .T.
   ENDIF
   itemBorder := 0
   x2 := x1 + Round( aPaintRep[FORM_WIDTH] * aPaintRep[FORM_XKOEF], 0 ) - 1
   y2 := y1 + Round( aPaintRep[FORM_HEIGHT] * aPaintRep[FORM_XKOEF], 0 ) - aPaintRep[FORM_Y] - 1
   IF nAddItem > 0
      IF xPos > x1 .AND. xPos < x2 .AND. yPos > y1 .AND. yPos < y2
         Hwg_SetCursor( crossCursor )
      ENDIF
   ELSEIF itemPressed > 0
      IF Abs( xPos - mPos[1] ) < 3 .AND. Abs( yPos - mPos[2] ) < 3
         RETURN Nil
      ENDIF
      aItem := aPaintRep[FORM_ITEMS,itemPressed]
      IF hwg_Checkbit( wParam, MK_LBUTTON )
         hWnd := Hwindow():GetMain():handle
         hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aItem[ITEM_X1] - 3, ;
            TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
            LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] + 3, ;
            TOP_INDENT + aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - aPaintRep[FORM_Y] + 3 )
         IF aItem[ITEM_TYPE] == TYPE_MARKER
            hwg_Invalidaterect( hWnd, 0, LEFT_INDENT, ;
               TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
               LEFT_INDENT - 1 + Round( aPaintRep[FORM_WIDTH] * aPaintRep[FORM_XKOEF], 0 ), ;
               TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] + 3 )
         ELSE
            aItem[ITEM_X1] += ( xPos - mPos[1] )
         ENDIF
         aItem[ITEM_Y1] += ( yPos - mPos[2] )
         hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aItem[ITEM_X1] - 3, ;
            TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
            LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] + 3, ;
            TOP_INDENT + aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - aPaintRep[FORM_Y] + 3 )
         IF aItem[ITEM_TYPE] == TYPE_MARKER
            hwg_Invalidaterect( hWnd, 0, LEFT_INDENT, ;
               TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
               LEFT_INDENT - 1 + Round( aPaintRep[FORM_WIDTH] * aPaintRep[FORM_XKOEF], 0 ), ;
               TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] + 3 )
         ENDIF
         mPos[1] := xPos; mPos[2] := yPos
         aPaintRep[FORM_CHANGED] := .T.
         WriteItemInfo( aItem )
         //hwg_Postmessage( hWnd, WM_PAINT, 0, 0 )
         hwg_Redrawwindow( hWnd )
      ELSE
         aItem[ITEM_STATE] := STATE_SELECTED
         itemPressed := 0
      ENDIF
   ELSEIF itemSized > 0
      aItem := aPaintRep[FORM_ITEMS,itemSized]
      IF hwg_Checkbit( wParam, MK_LBUTTON )
         dx := xPos - mPos[1]
         dy := yPos - mPos[2]
         hWnd := Hwindow():GetMain():handle
         hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aItem[ITEM_X1] - 3, ;
            TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
            LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] + 3, ;
            TOP_INDENT + aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - aPaintRep[FORM_Y] + 3 )
         IF resizeDirection == 1
            IF aItem[ITEM_WIDTH] - dx > 10
               aItem[ITEM_WIDTH] -= dx
               aItem[ITEM_X1] += dx
            ENDIF
         ELSEIF resizeDirection == 2
            IF aItem[ITEM_HEIGHT] - dy > 7
               aItem[ITEM_HEIGHT] -= dy
               aItem[ITEM_Y1] += dy
            ENDIF
         ELSEIF resizeDirection == 3
            IF aItem[ITEM_WIDTH] + dx > 10
               aItem[ITEM_WIDTH] += dx
            ENDIF
         ELSEIF resizeDirection == 4
            IF aItem[ITEM_HEIGHT] + dy > 7
               aItem[ITEM_HEIGHT] += dy
            ENDIF
         ENDIF
         mPos[1] := xPos; mPos[2] := yPos
         hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aItem[ITEM_X1] - 3, ;
            TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
            LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] + 3, ;
            TOP_INDENT + aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - aPaintRep[FORM_Y] + 3 )
         aPaintRep[FORM_CHANGED] := .T.
         WriteItemInfo( aItem )
         Hwg_SetCursor( iif( resizeDirection == 1 .OR. resizeDirection == 3,horzCursor,vertCursor ) )
         //hwg_Postmessage( hWnd, WM_PAINT, 0, 0 )
         hwg_Redrawwindow( hWnd )
      ENDIF
   ELSE
#ifdef __GTK__
      Hwg_SetCursor( Nil )
#endif
      FOR i := Len( aPaintRep[FORM_ITEMS] ) TO 1 STEP - 1
         aItem := aPaintRep[FORM_ITEMS,i]
         IF aItem[ITEM_STATE] == STATE_SELECTED
            IF xPos >= LEFT_INDENT - 2 + aItem[ITEM_X1] .AND. ;
                  xPos < LEFT_INDENT + 1 + aItem[ITEM_X1] .AND. ;
                  yPos >= TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] .AND. yPos < TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] + aItem[ITEM_HEIGHT]
               IF aItem[ITEM_TYPE] != TYPE_VLINE .AND. aItem[ITEM_TYPE] != TYPE_MARKER
                  Hwg_SetCursor( horzCursor )
                  itemBorder := i
                  resizeDirection := 1
               ENDIF
            ELSEIF xPos >= LEFT_INDENT - 1 + aItem[ITEM_X1] + aItem[ITEM_WIDTH] .AND. ;
                  xPos < LEFT_INDENT + 2 + aItem[ITEM_X1] + aItem[ITEM_WIDTH] .AND. ;
                  yPos >= TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] .AND. yPos < LEFT_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] + aItem[ITEM_HEIGHT]
               IF aItem[ITEM_TYPE] != TYPE_VLINE .AND. aItem[ITEM_TYPE] != TYPE_MARKER
                  Hwg_SetCursor( horzCursor )
                  itemBorder := i
                  resizeDirection := 3
               ENDIF
            ELSEIF yPos >= TOP_INDENT - 2 + aItem[ITEM_Y1] - aPaintRep[FORM_Y] .AND. ;
                  yPos < TOP_INDENT + 1 + aItem[ITEM_Y1] - aPaintRep[FORM_Y] .AND. ;
                  xPos >= LEFT_INDENT + aItem[ITEM_X1] .AND. xPos < LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH]
               IF aItem[ITEM_TYPE] != TYPE_HLINE .AND. aItem[ITEM_TYPE] != TYPE_MARKER
                  Hwg_SetCursor( vertCursor )
                  itemBorder := i
                  resizeDirection := 2
               ENDIF
            ELSEIF yPos >= TOP_INDENT - 1 + aItem[ITEM_Y1] - aPaintRep[FORM_Y] + aItem[ITEM_HEIGHT] .AND. ;
                  yPos < TOP_INDENT + 2 + aItem[ITEM_Y1] - aPaintRep[FORM_Y] + aItem[ITEM_HEIGHT] .AND. ;
                  xPos >= LEFT_INDENT + aItem[ITEM_X1] .AND. xPos < LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH]
               IF aItem[ITEM_TYPE] != TYPE_HLINE .AND. aItem[ITEM_TYPE] != TYPE_MARKER
                  Hwg_SetCursor( vertCursor )
                  itemBorder := i
                  resizeDirection := 4
               ENDIF
            ENDIF
            IF itemBorder != 0
               EXIT
            ENDIF
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

STATIC FUNCTION LButtonDown( xPos, yPos )
   LOCAL i, aItem, res := .F.
   LOCAL hWnd := Hwindow():GetMain():handle

   IF aPaintRep == Nil .OR. lPreviewMode
      RETURN .T.
   ENDIF
   IF nAddItem > 0
   ELSEIF itemBorder != 0
      itemSized := itemBorder
      mPos[1] := xPos; mPos[2] := yPos
      Hwg_SetCursor( iif( resizeDirection == 1 .OR. resizeDirection == 3,horzCursor,vertCursor ) )
   ELSE
      IF ( i := DeselectAll() ) != 0
         hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aPaintRep[FORM_ITEMS,i,ITEM_X1] - 3, ;
            TOP_INDENT + aPaintRep[FORM_ITEMS,i,ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
            LEFT_INDENT + aPaintRep[FORM_ITEMS,i,ITEM_X1] + aPaintRep[FORM_ITEMS,i,ITEM_WIDTH] + 3, ;
            TOP_INDENT + aPaintRep[FORM_ITEMS,i,ITEM_Y1] + aPaintRep[FORM_ITEMS,i,ITEM_HEIGHT] - aPaintRep[FORM_Y] + 3 )
         res := .T.
      ENDIF
      hwg_WriteStatus( Hwindow():GetMain(), 1, "" )
      FOR i := Len( aPaintRep[FORM_ITEMS] ) TO 1 STEP - 1
         aItem := aPaintRep[FORM_ITEMS,i]
         IF xPos >= LEFT_INDENT + aItem[ITEM_X1] ;
               .AND. xPos < LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] ;
               .AND. yPos > TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] ;
               .AND. yPos < TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] + aItem[ITEM_HEIGHT]
            aPaintRep[FORM_ITEMS,i,ITEM_STATE] := STATE_PRESSED
            itemPressed := i
            mPos[1] := xPos; mPos[2] := yPos
            WriteItemInfo( aItem )
            hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aItem[ITEM_X1] - 3, ;
               TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
               LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] + 3, ;
               TOP_INDENT + aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - aPaintRep[FORM_Y] + 3 )
            res := .T.
            EXIT
         ENDIF
      NEXT
      IF res
         //hwg_Postmessage( hWnd, WM_PAINT, 0, 0 )
         hwg_Redrawwindow( hWnd )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION LButtonUp( xPos, yPos )
   LOCAL x1 := LEFT_INDENT, y1 := TOP_INDENT, x2, y2, aItem
   LOCAL hWnd := Hwindow():GetMain():handle

   IF aPaintRep == Nil .OR. lPreviewMode
      RETURN .T.
   ENDIF
   x2 := x1 + Round( aPaintRep[FORM_WIDTH] * aPaintRep[FORM_XKOEF], 0 ) - 1
   y2 := y1 + Round( aPaintRep[FORM_HEIGHT] * aPaintRep[FORM_XKOEF], 0 ) - aPaintRep[FORM_Y] - 1
   IF nAddItem > 0 .AND. xPos > x1 .AND. xPos < x2 .AND. yPos > y1 .AND. yPos < y2
      AAdd( aPaintRep[FORM_ITEMS], { nAddItem, "", xPos - x1, ;
         yPos - y1 + aPaintRep[FORM_Y], aInitialSize[nAddItem,1], ;
         aInitialSize[nAddItem,2], 0, Nil, Nil, 0, 0, Nil, STATE_SELECTED } )
      aItem := Atail( aPaintRep[FORM_ITEMS] )
      IF nAddItem == TYPE_HLINE .OR. nAddItem == TYPE_VLINE .OR. nAddItem == TYPE_BOX
         aItem[ITEM_PEN] := HPen():Add()
      ELSEIF nAddItem == TYPE_TEXT
         aItem[ITEM_FONT] := ;
            iif( lastFont == Nil, HFont():Add( "Arial",0, - 13 ), lastFont )
      ELSEIF nAddItem == TYPE_MARKER
         aItem[ITEM_X1] := - aInitialSize[nAddItem,1]
         aItem[ITEM_CAPTION] := aMarkers[ nMarkerType ]
      ENDIF
      DeselectAll( Len( aPaintRep[FORM_ITEMS] ) )
      aPaintRep[FORM_CHANGED] := .T.
      WriteItemInfo( Atail( aPaintRep[FORM_ITEMS] ) )
      hwg_WriteStatus( Hwindow():GetMain(), 2, LTrim( Str(aPaintRep[FORM_WIDTH],4 ) ) + "x" + ;
         LTrim( Str( aPaintRep[FORM_HEIGHT],4 ) ) + "  Items: " + LTrim( Str( Len(aPaintRep[FORM_ITEMS] ) ) ) )
      hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aItem[ITEM_X1] - 3, ;
         TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
         LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] + 3, ;
         TOP_INDENT + aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - aPaintRep[FORM_Y] + 3 )
      //hwg_Postmessage( hWnd, WM_PAINT, 0, 0 )
      hwg_Redrawwindow( hWnd )
      IF Len( aPaintRep[FORM_ITEMS] ) == 1
         hwg_Enablemenuitem( , IDM_CLOSE, .T. , .T. )
         hwg_Enablemenuitem( , IDM_SAVE, .T. , .T. )
         hwg_Enablemenuitem( , IDM_SAVEAS, .T. , .T. )
         hwg_Enablemenuitem( , IDM_PRINT, .T. , .T. )
         hwg_Enablemenuitem( , IDM_PREVIEW, .T. , .T. )
         hwg_Enablemenuitem( , IDM_FOPT, .T. , .T. )
         hwg_Enablemenuitem( , IDM_VIEW1, .T. , .T. )
      ENDIF
   ELSEIF itemPressed > 0
      aPaintRep[FORM_ITEMS,itemPressed,ITEM_STATE] := STATE_SELECTED
   ENDIF
   IF itemPressed > 0 .OR. itemSized > 0 .OR. nAddItem > 0
      aPaintRep[FORM_ITEMS] := ASort( aPaintRep[FORM_ITEMS], , , { |z, y|z[ITEM_Y1] < y[ITEM_Y1] .OR. ( z[ITEM_Y1] == y[ITEM_Y1] .AND. z[ITEM_X1] < y[ITEM_X1] ) .OR. ( z[ITEM_Y1] == y[ITEM_Y1] .AND. z[ITEM_X1] == y[ITEM_X1] .AND. (z[ITEM_WIDTH] < y[ITEM_WIDTH] .OR. z[ITEM_HEIGHT] < y[ITEM_HEIGHT] ) ) } )
   ENDIF
   itemPressed := itemSized := itemBorder := nAddItem := 0

   RETURN Nil

STATIC FUNCTION DeleteItem()
   LOCAL hWnd := Hwindow():GetMain():handle
   LOCAL i, aItem

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_STATE] == STATE_SELECTED
         aItem := aPaintRep[FORM_ITEMS,i]
         IF aItem[ITEM_PEN] != Nil .AND. Valtype( aItem[ ITEM_PEN ] ) == "O"
            aItem[ITEM_PEN]:Release()
            aItem[ITEM_PEN] := Nil
         ENDIF
         hwg_Invalidaterect( hWnd, 0, LEFT_INDENT + aItem[ITEM_X1] - 3, ;
            TOP_INDENT + aItem[ITEM_Y1] - aPaintRep[FORM_Y] - 3, ;
            LEFT_INDENT + aItem[ITEM_X1] + aItem[ITEM_WIDTH] + 3, ;
            TOP_INDENT + aItem[ITEM_Y1] + aItem[ITEM_HEIGHT] - aPaintRep[FORM_Y] + 3 )
         ADel( aPaintRep[FORM_ITEMS], i )
         ASize( aPaintRep[FORM_ITEMS], Len( aPaintRep[FORM_ITEMS] ) - 1 )
         aPaintRep[FORM_CHANGED] := .T.
         hwg_WriteStatus( Hwindow():GetMain(), 1, "" )
         hwg_WriteStatus( Hwindow():GetMain(), 2, LTrim( Str(aPaintRep[FORM_WIDTH],4 ) ) + "x" + ;
            LTrim( Str( aPaintRep[FORM_HEIGHT],4 ) ) + "  Items: " + LTrim( Str( Len(aPaintRep[FORM_ITEMS] ) ) ) )
         IF Len( aPaintRep[FORM_ITEMS] ) == 0
            hwg_Enablemenuitem( , IDM_CLOSE, .F. , .T. )
            hwg_Enablemenuitem( , IDM_SAVE, .F. , .T. )
            hwg_Enablemenuitem( , IDM_SAVEAS, .F. , .T. )
            hwg_Enablemenuitem( , IDM_PRINT, .F. , .T. )
            hwg_Enablemenuitem( , IDM_PREVIEW, .F. , .T. )
            hwg_Enablemenuitem( , IDM_FOPT, .F. , .T. )
            hwg_Enablemenuitem( , IDM_VIEW1, .F. , .T. )
         ENDIF
         //hwg_Postmessage( hWnd, WM_PAINT, 0, 0 )
         hwg_Redrawwindow( hWnd )
         EXIT
      ENDIF
   NEXT

   RETURN Nil

STATIC FUNCTION DeselectAll( iSelected )
   LOCAL i, iPrevSelected := 0

   iSelected := iif( iSelected == Nil, 0, iSelected )
   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_STATE] == STATE_SELECTED .OR. ;
            aPaintRep[FORM_ITEMS,i,ITEM_STATE] == STATE_PRESSED
         iPrevSelected := i
      ENDIF
      IF iSelected != i
         aPaintRep[FORM_ITEMS,i,ITEM_STATE] := STATE_NORMAL
      ENDIF
   NEXT

   RETURN iPrevSelected

STATIC FUNCTION WriteItemInfo( aItem )

   hwg_WriteStatus( Hwindow():GetMain(), 1, " x1: " + LTrim( Str(aItem[ITEM_X1] ) ) + ", y1: " ;
      + LTrim( Str( aItem[ITEM_Y1] ) ) + ", cx: " + LTrim( Str( aItem[ITEM_WIDTH] ) ) ;
      + ", cy: " + LTrim( Str( aItem[ITEM_HEIGHT] ) ) )

   RETURN Nil

   // Returns the Hex value of icon

FUNCTION hwreport_icon_hex()

   RETURN ;
      "00 00 01 00 01 00 20 20 10 00 01 00 04 00 E8 02 " + ;
      "00 00 16 00 00 00 28 00 00 00 20 00 00 00 40 00 " + ;
      "00 00 01 00 04 00 00 00 00 00 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 00 00 00 00 00 00 00 00 FF FF " + ;
      "00 00 FF FF FF 00 C0 C0 C0 00 00 00 00 00 00 00 " + ;
      "FF 00 00 00 80 00 00 80 80 00 80 00 00 00 80 80 " + ;
      "00 00 80 80 80 00 00 80 00 00 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 00 00 00 00 00 00 00 00 88 88 " + ;
      "88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 " + ;
      "88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 88 " + ;
      "82 28 22 28 88 88 88 88 88 8A 18 88 88 88 88 86 " + ;
      "68 88 88 88 88 88 88 88 88 88 88 88 82 88 88 88 " + ;
      "88 88 88 88 88 88 03 38 88 88 88 A8 81 88 88 88 " + ;
      "88 88 03 83 30 13 33 30 88 88 88 88 88 88 88 88 " + ;
      "88 88 33 01 03 33 33 30 88 88 88 88 88 88 88 88 " + ;
      "88 33 13 13 33 33 33 38 18 88 88 88 88 88 88 88 " + ;
      "83 33 33 33 33 33 33 38 88 88 88 88 88 88 88 88 " + ;
      "33 33 33 33 33 33 33 37 88 88 88 88 88 88 88 82 " + ;
      "33 33 33 33 32 23 33 37 88 88 88 88 88 88 88 83 " + ;
      "33 33 33 33 33 33 33 33 88 88 88 88 88 89 00 03 " + ;
      "33 33 33 33 33 33 33 33 70 00 00 00 00 00 00 03 " + ;
      "33 22 12 13 11 33 33 33 32 00 00 00 00 00 00 02 " + ;
      "33 33 33 33 33 33 33 33 33 00 00 00 00 00 00 00 " + ;
      "03 11 11 12 00 00 12 77 33 20 00 01 11 00 00 10 " + ;
      "03 22 22 62 00 10 00 00 23 30 00 00 10 00 00 00 " + ;
      "03 35 55 22 00 00 00 00 00 00 00 00 00 00 00 10 " + ;
      "00 04 44 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
      "00 03 11 00 00 00 00 00 11 11 11 11 01 00 00 00 " + ;
      "00 03 22 00 11 11 10 11 11 11 11 11 11 10 00 00 " + ;
      "00 00 20 00 01 11 10 00 11 10 11 11 01 10 00 00 " + ;
      "00 01 20 00 00 00 10 10 11 11 11 10 11 10 01 11 " + ;
      "11 12 10 00 00 01 00 01 01 11 11 01 01 00 01 02 " + ;
      "02 21 00 00 00 00 00 00 11 11 11 00 10 00 01 10 " + ;
      "10 11 00 00 00 00 00 01 11 11 11 00 00 00 01 11 " + ;
      "11 00 00 00 00 00 01 11 11 11 00 00 00 00 00 10 " + ;
      "00 00 00 00 00 00 11 00 11 10 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 01 11 11 10 00 00 00 00 00 01 " + ;
      "01 10 00 00 00 00 00 00 11 10 00 00 00 00 00 11 " + ;
      "11 11 10 00 00 00 00 00 01 00 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
      "00 00 00 00 00 00 00 00 00 00 00 00 00 00 "

/*
 Contents of file repbuild.rc copied here for archive purposes

include "repbuild.h"

DLG_NEWREP DIALOG 6, 15, 162, 119
STYLE DS_MODALFRAME | WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU
CAPTION "New report"
FONT 8, "MS Sans Serif"
{
 DEFPUSHBUTTON "OK", IDOK, 12, 96, 50, 14
 PUSHBUTTON "Cancel", IDCANCEL, 98, 96, 50, 14
 GROUPBOX "Page size", IDC_GROUPBOX1, 10, 10, 139, 63, BS_GROUPBOX
 CONTROL "A4 portrait ( 210x297 )", IDC_RADIOBUTTON1, "BUTTON", BS_AUTORADIOBUTTON, 15, 25, 85, 9
 CONTROL "A4 landscape ( 297x210 )", IDC_RADIOBUTTON2, "BUTTON", BS_AUTORADIOBUTTON, 15, 39, 85, 10
}

DLG_FILE DIALOG 6, 15, 197, 142
STYLE DS_MODALFRAME | WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU
CAPTION ""
FONT 8, "MS Sans Serif"
{
 GROUPBOX "", IDC_GROUPBOX4, 17, 10, 82, 34, BS_GROUPBOX
 CONTROL "Report file", IDC_RADIOBUTTON1, "BUTTON", BS_AUTORADIOBUTTON, 23, 19, 60, 9
 CONTROL "Program source", IDC_RADIOBUTTON2, "BUTTON", BS_AUTORADIOBUTTON, 23, 31, 60, 9
 EDITTEXT IDC_EDIT1, 13, 54, 149, 12, ES_AUTOHSCROLL | WS_BORDER | WS_TABSTOP
 PUSHBUTTON "Browse", IDC_BUTTONBRW, 162, 53, 25, 14
 EDITTEXT IDC_EDIT2, 39, 88, 47, 12
 LTEXT "Report name:", IDC_TEXT1, 17, 76, 60, 8
 DEFPUSHBUTTON "OK", IDOK, 12, 116, 50, 14
 PUSHBUTTON "Cancel", IDCANCEL, 132, 116, 50, 14
}

DLG_STATIC DIALOG 7, 14, 232, 208
STYLE DS_MODALFRAME | WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU
CAPTION "Text"
FONT 8, "MS Sans Serif"
{
 LTEXT "Caption:", -1, 12, 8, 38, 8
 EDITTEXT IDC_EDIT1, 15, 22, 206, 12, ES_AUTOHSCROLL | WS_BORDER | WS_TABSTOP
 GROUPBOX "Alignment", IDC_GROUPBOX1, 15, 41, 48, 48, BS_GROUPBOX
 CONTROL "Left", IDC_RADIOBUTTON1, "BUTTON", BS_AUTORADIOBUTTON, 19, 53, 28, 8
 CONTROL "Right", IDC_RADIOBUTTON2, "BUTTON", BS_AUTORADIOBUTTON, 19, 65, 28, 8
 CONTROL "Center", IDC_RADIOBUTTON3, "BUTTON", BS_AUTORADIOBUTTON, 19, 77, 28, 8
 GROUPBOX "Font", IDC_GROUPBOX3, 82, 41, 70, 48, BS_GROUPBOX
 PUSHBUTTON "Change", IDC_PUSHBUTTON1, 89, 70, 41, 14
 LTEXT "", IDC_TEXT1, 88, 52, 60, 11
 EDITTEXT IDC_EDIT3, 16, 108, 206, 65, ES_MULTILINE | ES_AUTOVSCROLL | ES_AUTOHSCROLL | ES_WANTRETURN | WS_TABSTOP | WS_DLGFRAME
 LTEXT "Script:", -1, 16, 97, 28, 8
 COMBOBOX IDC_COMBOBOX3, 174, 54, 43, 33, CBS_DROPDOWNLIST | WS_TABSTOP
 LTEXT "Type:", -1, 172, 44, 24, 8
 DEFPUSHBUTTON "OK", IDOK, 14, 188, 50, 14
 PUSHBUTTON "Cancel", IDCANCEL, 167, 188, 50, 14
}

DLG_LINE DIALOG 11, 21, 139, 108
STYLE DS_MODALFRAME | WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU
CAPTION "Line"
FONT 8, "MS Sans Serif"
{
 DEFPUSHBUTTON "OK", IDOK, 12, 82, 50, 14
 PUSHBUTTON "Cancel", IDCANCEL, 76, 82, 50, 14
 COMBOBOX IDC_COMBOBOX1, 11, 18, 49, 43, CBS_DROPDOWNLIST | WS_TABSTOP
 LTEXT "Line width:", -1, 9, 46, 39, 8
 EDITTEXT IDC_EDIT1, 46, 45, 12, 12
 LTEXT "Type:", -1, 9, 6, 32, 8
 COMBOBOX IDC_COMBOBOX2, 83, 45, 49, 33, CBS_DROPDOWNLIST | WS_TABSTOP
 LTEXT "Fill:", -1, 82, 35, 32, 8
}

DLG_BITMAP DIALOG 6, 15, 163, 147
STYLE DS_MODALFRAME | WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU
CAPTION "Bitmap"
FONT 8, "MS Sans Serif"
{
 DEFPUSHBUTTON "OK", IDOK, 12, 123, 50, 14
 PUSHBUTTON "Cancel", IDCANCEL, 97, 123, 50, 14
 EDITTEXT IDC_EDIT1, 8, 14, 122, 12
 PUSHBUTTON "Browse", IDC_BUTTONBRW, 130, 13, 27, 14
 GROUPBOX "Bitmap size", IDC_GROUPBOX3, 20, 33, 120, 71, BS_GROUPBOX
 LTEXT "Bitmap file:", -1, 15, 6, 41, 8
 LTEXT "0x0", IDC_TEXT1, 79, 45, 25, 8
 LTEXT "0x0", IDC_TEXT2, 78, 59, 26, 8
 RTEXT "Percentage of original %", -1, 25, 78, 76, 8
 EDITTEXT IDC_EDIT3, 106, 77, 25, 15
 LTEXT "Original size:", -1, 25, 45, 47, 8
 LTEXT "New size", -1, 25, 59, 45, 8
 LTEXT "pixels", -1, 110, 45, 25, 8
 LTEXT "pixels", -1, 110, 59, 25, 8
}

DLG_MARKL DIALOG 6, 15, 194, 115
STYLE DS_MODALFRAME | WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU
CAPTION "Start line"
FONT 8, "MS Sans Serif"
{
 DEFPUSHBUTTON "OK", IDOK, 14, 89, 50, 14
 PUSHBUTTON "Cancel", IDCANCEL, 126, 89, 50, 14
 LTEXT "", IDC_TEXT1, 10, 11, 50, 8
 EDITTEXT IDC_EDIT1, 12, 22, 170, 47, ES_MULTILINE | ES_AUTOVSCROLL | ES_AUTOHSCROLL | ES_WANTRETURN | WS_TABSTOP | WS_DLGFRAME
}

DLG_MARKF DIALOG 6, 15, 134, 119
STYLE DS_MODALFRAME | WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU
CAPTION "Marker"
FONT 8, "MS Sans Serif"
{
 DEFPUSHBUTTON "OK", IDOK, 12, 96, 50, 14
 PUSHBUTTON "Cancel", IDCANCEL, 72, 96, 50, 14
 GROUPBOX "Type of a footer position", IDC_GROUPBOX1, 16, 13, 93, 51, BS_GROUPBOX
 CONTROL "Fixed", IDC_RADIOBUTTON1, "BUTTON", BS_AUTORADIOBUTTON, 21, 28, 68, 12
 CONTROL "Dependent on list", IDC_RADIOBUTTON2, "BUTTON", BS_AUTORADIOBUTTON, 21, 46, 68, 12
}


AboutDlg DIALOG LOADONCALL FIXED DISCARDABLE 100, 63, 111, 96
STYLE DS_MODALFRAME | WS_POPUP | WS_VISIBLE | WS_CAPTION | WS_SYSMENU
CAPTION "About"
FONT 9, "MS Shell Dlg"
{
 GROUPBOX "", -1, 14, 0, 84, 37, BS_GROUPBOX
 GROUPBOX "", -1, 20, 39, 75, 18, BS_GROUPBOX
 CTEXT "Visual report Builder", -1, 18, 16, 78, 8
 CTEXT "HWREPORT", 101, 30, 7, 52, 8
 CTEXT "version 1.1", -1, 25, 26, 66, 8
 CTEXT "Alexander Kresin, 2001", -1, 22, 45, 72, 7
 CONTROL "", IDC_OWNB1, "OWNBTN", 0 | WS_CHILD | WS_VISIBLE, 22, 66, 72, 20
}

ICON_1 ICON
{
.... ==> extracted from exe file.
}

*/

   // ===================================== EOF of hwreport.prg ========================================
