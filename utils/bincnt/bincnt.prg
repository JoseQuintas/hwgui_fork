/*
 * $Id$
 *
 * Binary container manager
 *
 * Copyright 2014 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 
 * DF7BE (2024-12-06):
 * Fixed warnings (compile is aborted):
 * ..\utils\bincnt\bincnt.prg(153) Warning W0001  Ambiguous reference 'ODLG'
 * ..\utils\bincnt\bincnt.prg(220) Warning W0001  Ambiguous reference 'CKEY'
 * ..\utils\bincnt\bincnt.prg(223) Warning W0001  Ambiguous reference 'CVAL'
 *
 */

#include "hwgui.ch"
#include "hbclass.ch"
#include "fileio.ch"

#define APP_VERSION  "1.2"

#define MENU_CONT    1001
#define MENU_SAVE    1002
#define MENU_SAVEAS  1003

#define OBJ_NAME      1
#define OBJ_TYPE      2

STATIC oBrw, oContainer, lCntUpdated := .F., cCntFile
STATIC cHead := "hwgbc"

FUNCTION Main( cContainer )

   LOCAL oMainW, oMainFont, oMenuBrw
   LOCAL nBkColor, nFgColor, nHeadBg, nHeadFg, nSelBg, nSelFg, nSepColor
   LOCAL aColors
   LOCAL oStyle
   LOCAL bRClick

#ifdef __HWGUI_GTK4__
   /*
    * GTK4: read the current theme (light or dark) from the system
    * and use matching colours.  Bar, browse, header and status panel
    * then follow the desktop theme (KDE / GNOME).
    */
   aColors   := hwg_GetThemeColors()
   nBkColor  := aColors[1]   /* bg         */
   nFgColor  := aColors[2]   /* fg         */
   nHeadBg   := aColors[6]   /* header_bg  */
   nHeadFg   := aColors[7]   /* header_fg  */
   nSelBg    := aColors[4]   /* sel_bg     */
   nSelFg    := aColors[5]   /* sel_fg     */
   nSepColor := aColors[8]   /* separator  */
#else
   /*
    * Windows and GTK2: keep the original fixed light palette.
    */
   nBkColor  := 0xffffff
   nFgColor  := 0
   nHeadBg   := 0xffffff
   nHeadFg   := 0xbbbbbb
   nSelBg    := 0xeeeeee
   nSelFg    := 0
   nSepColor := 0xbbbbbb
#endif

   oStyle := HStyle():New( { nHeadBg, nSepColor } )

   bRClick := {|o,nCol,nLine|
      LOCAL n := nLine, nRec := Eval( o:bRecno,o )
      IF n != nRec
         DO WHILE n != nRec
            IF n < nRec
               o:LineUp()
               n ++
            ELSE
               o:LineDown()
               n --
            ENDIF
         ENDDO
      ENDIF
      oMenuBrw:Show( HWindow():GetMain() )
      RETURN Nil
   }

   PREPARE FONT oMainFont NAME "Georgia" WIDTH 0 HEIGHT - 17 CHARSET 4

   INIT WINDOW oMainW MAIN TITLE "Binary container manager" ;
      AT 200, 0 SIZE 600, 540 FONT oMainFont ON EXIT {||CntClose()}

   MENU OF oMainW
      MENU TITLE "&File"
         MENUITEM "&Create" ACTION CntCreate()
         MENUITEM "&Open" ACTION CntOpen()
         SEPARATOR
         MENUITEM "&Save" ID MENU_SAVE ACTION CntSave()
         MENUITEM "Save &as..." ID MENU_SAVEAS ACTION CntSaveAs()
         SEPARATOR
         MENUITEM "&Exit" ACTION oMainW:Close()
      ENDMENU
      MENU TITLE "&Container" ID MENU_CONT
         MENUITEM "&Add item" ACTION CntAdd()
         MENUITEM "&Delete item" ACTION CntDel()
         SEPARATOR
         MENUITEM "&Save item as" ACTION CntSaveItem()
         MENUITEM "&View item" ACTION CntView()
         SEPARATOR
         MENUITEM "&Import from folder" ACTION CntImport()
         SEPARATOR
         MENUITEM "&Pack" ACTION CntPack()
         MENUITEM "In&fo" ACTION CntInfo()
      ENDMENU
      MENU TITLE "&Help"
         MENUITEM "&About" ACTION About()
      ENDMENU
   ENDMENU

   CONTEXT MENU oMenuBrw
      MENUITEM "&Delete item" ACTION CntDel()
      SEPARATOR
      MENUITEM "&Save item as" ACTION CntSaveItem()
      SEPARATOR
      MENUITEM "&View item" ACTION CntView()
   ENDMENU

   @ 0, 0 BROWSE oBrw ARRAY            ;
      SIZE 600, 510                    ;
      STYLE WS_VSCROLL                 ;
      FONT oMainFont                   ;
      ON SIZE { |o, x, y|o:Move( , , x, y - 32 ) }

   oBrw:aArray := {}
   oBrw:AddColumn( HColumn():New( "Name",{ |value,o|o:aArray[o:nCurrent,1] },"C",32 ) )
   oBrw:AddColumn( HColumn():New( "Type",{ |value,o|o:aArray[o:nCurrent,2] },"C",8 ) )
   oBrw:AddColumn( HColumn():New( "Size",{ |value,o|o:aArray[o:nCurrent,4] },"N",14,0 ) )

   oBrw:oStyleHead := oStyle
   oBrw:bcolorSel := oBrw:htbcolor := 0xeeeeee
   oBrw:tcolorSel := oBrw:httcolor := 0
   oBrw:aHeadPadding[2] := oBrw:aHeadPadding[4] := 4
   oBrw:lInFocus := .T.

   oBrw:bRClick := bRClick
   oBrw:bEnter := {||CntView()}

   ADD STATUS PANEL TO oMainW HEIGHT 30 FONT oMainW:oFont ;
      HSTYLE oStyle PARTS 200, 120, 0

   hwg_Enablemenuitem( , MENU_CONT, .F. , .T. )
   hwg_Enablemenuitem( , MENU_SAVE, .F. , .T. )
   hwg_Enablemenuitem( , MENU_SAVEAS, .F. , .T. )

   IF cContainer != Nil
      CntOpen( cContainer )
   ENDIF

   ACTIVATE WINDOW oMainW

   IF !Empty( oContainer )
      oContainer:Close()
   ENDIF

   RETURN Nil

STATIC FUNCTION CntCreate()

   LOCAL fname, oEdit, lRes := .F., nChoic := 1
   LOCAL odlg
   LOCAL bFile := { ||
#ifdef __GTK__
      fname := hwg_Selectfile( "( *.* )", "*.*", CurDir() )
#else
      fname := hwg_Savefile( "*.*", "( *.* )", "*.*", CurDir() )
#endif
      IF !Empty( fname )
         oEdit:value := fname
      ENDIF
      RETURN .T.
   }
   LOCAL bOk := { ||
      CntClose()
      IF Empty( fname := oEdit:value )
         hwg_MsgStop( "Set file name" )
         RETURN .F.
      ENDIF
      hwg_EndDialog()
      lRes := .T.
      RETURN .T.
   }

   INIT DIALOG oDlg TITLE "Create container" ;
      AT 50, 100 SIZE 310, 250 FONT HWindow():GetMain():oFont

   RADIOGROUP
   @ 10,20 RADIOBUTTON "Binary container" SIZE 180, 24 ON CLICK {||nChoic := 1}
   @ 10,60 RADIOBUTTON "Prg file" SIZE 180, 24 ON CLICK {||nChoic := 2}
   END RADIOGROUP SELECTED 1

   @ 10, 100 EDITBOX oEdit CAPTION "" STYLE ES_AUTOHSCROLL SIZE 200, 26
   @ 210, 100 BUTTON "Browse" SIZE 80, 26 ON CLICK bFile

   @ 20, 200 BUTTON "Ok" SIZE 100, 32 ON CLICK bOk
   @ 180, 200 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32

   oDlg:Activate()

   IF lRes
      IF nChoic == 1
         oContainer := HBinC():Create( fname )
      ELSE
         IF !__mvExist( "HWG_RESO_ARR" )
            __mvPublic( "HWG_RESO_ARR" )
         ENDIF
         __mvPut( "HWG_RESO_ARR", hb_hash() )
         oContainer := HBinC():Create()
         oContainer:aObjects := {}
         lCntUpdated := .T.
         cCntFile := fname
      ENDIF

      IF !Empty( oContainer )
         hwg_WriteStatus( HWindow():GetMain(), 1, hb_fnameNameExt( fname ) )
         hwg_WriteStatus( HWindow():GetMain(), 2, "Items: " + LTrim( Str(oContainer:nItems ) ) )
         hwg_Enablemenuitem( , MENU_CONT, .T., .T. )
         hwg_Enablemenuitem( , MENU_SAVE, (nChoic == 2), .T. )
         hwg_Enablemenuitem( , MENU_SAVEAS, .T. , .T. )
         hwg_Drawmenubar( HWindow():GetMain():handle )
         oBrw:aArray := oContainer:aObjects
         oBrw:Refresh()
      ELSE
         hwg_WriteStatus( HWindow():GetMain(), 1, "" )
         hwg_WriteStatus( HWindow():GetMain(), 2, "" )
      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION CntOpen( fname )

   LOCAL cBuf, n1, n2, h
   LOCAL CVAL, CKEY

   CntClose()

   IF Empty( fname )
      fname := hwg_Selectfile( { "All files" }, { "*.*" }, "" )
   ENDIF

   IF !Empty( fname )
      IF Lower( hb_fnameExt( fname ) ) == ".prg"
         cBuf := MemoRead( fname )
         IF ( n1 := hb_AtI( "INIT", cBuf, 1 ) ) > 0 .AND. ( n1 := hb_AtI( "RESOURCE", cBuf, n1 ) ) > 0 ;
            .AND. ( n1 := hb_AtI( "hb_hash", cBuf, n1 ) ) > 0

            h := hb_hash()
            n1 := hb_At( '"', cBuf, n1 )

            DO WHILE n1 > 0
               n2 := hb_At( '"', cBuf, n1+1 )
               cKey := Substr( cBuf, n1+1, n2-n1-1 )
               n1 := hb_At( '{', cBuf, n2 )
               n2 := hb_At( '}', cBuf, n1+1 )
               cVal := &( Substr( cBuf, n1, n2-n1+1 ) )
               hb_hset( h, cKey, cVal )
               n1 := hb_At( '"', cBuf, n2+1 )
            ENDDO

            IF !__mvExist( "HWG_RESO_ARR" )
               __mvPublic( "HWG_RESO_ARR" )
            ENDIF
            __mvPut( "HWG_RESO_ARR", h )
            oContainer := HBinC():Create()
            oContainer:aObjects := hb_hkeys( h )
            FOR n1 := 1 TO Len( oContainer:aObjects )
               oContainer:aObjects[n1] := { oContainer:aObjects[n1], ;
                  hb_hGet(h,oContainer:aObjects[n1])[1], 0, ;
                  Len( hb_hGet(h,oContainer:aObjects[n1])[2] ), 0 }
            NEXT
            hwg_Enablemenuitem( , MENU_SAVE, .T., .T. )
            cCntFile := fname
         ENDIF
      ELSE
         oContainer := HBinC():Open( fname, .T. )
      ENDIF
   ENDIF

   IF !Empty( oContainer )
      hwg_WriteStatus( HWindow():GetMain(), 1, hb_fnameNameExt( fname ) )
      hwg_WriteStatus( HWindow():GetMain(), 2, "Items: " + LTrim( Str(oContainer:nItems ) ) )
      hwg_Enablemenuitem( , MENU_CONT, .T., .T. )
      hwg_Enablemenuitem( , MENU_SAVEAS, .T. , .T. )
      hwg_Drawmenubar( HWindow():GetMain():handle )
      oBrw:aArray := oContainer:aObjects
      oBrw:Refresh()
   ELSE
      hwg_WriteStatus( HWindow():GetMain(), 1, "" )
      hwg_WriteStatus( HWindow():GetMain(), 2, "" )
      hwg_MsgStop( "Error opening container" )
   ENDIF

   RETURN Nil

STATIC FUNCTION CntClose()

   IF !Empty( oContainer )
      IF oContainer:type == 1 .AND. lCntUpdated
         IF hwg_MsgYesNo( "Save changes?" )
            CntSave()
         ENDIF
      ENDIF
      lCntUpdated := .F.
      oContainer:Close()
      oContainer := Nil
      IF __mvExist( "HWG_RESO_ARR" )
         __mvPut( "HWG_RESO_ARR", Nil )
      ENDIF
      cCntFile := Nil
   ENDIF

   RETURN .T.

STATIC FUNCTION CntAdd()
   LOCAL oDlg, oEdit1, oEdit2, oEdit3, cFileName := "", cObjName := "", cType := ""
   LOCAL bFile := { ||
      LOCAL cFile := hwg_Selectfile( "All files( *.* )", "*.*" )
      IF !Empty( cFile )
         oEdit1:value := cFile
         oEdit2:value := Left( CutExten( CutPath(cFile ) ), 32 )
         oEdit3:value := Left( FilExten( cFile ), 4 )
      ENDIF
      RETURN .T.
   }
   LOCAL bOk := { ||
      IF Empty( cFileName ) .OR. Empty( cObjName ) .OR. Empty( cType )
         hwg_MsgStop( "Fill all fields!" )
         RETURN .F.
      ENDIF
      oContainer:Add( cObjName, cType, MemoRead( cFileName ) )
      lCntUpdated := .T.
      hwg_EndDialog()
      hwg_WriteStatus( HWindow():GetMain(), 2, "Items: " + LTrim( Str(oContainer:nItems ) ) )
      oBrw:Refresh()
      RETURN .T.
   }

   INIT DIALOG oDlg TITLE "Add binary object" ;
      AT 50, 100 SIZE 310, 250 FONT HWindow():GetMain():oFont

   @ 10, 20 GET oEdit1 VAR cFileName STYLE ES_AUTOHSCROLL SIZE 200, 26 MAXLENGTH 0
   @ 210, 20 BUTTON "Browse" SIZE 80, 26 ON CLICK bFile

   @ 10, 70 SAY "Object name:" SIZE 120, 22
   @ 130, 70 GET oEdit2 VAR cObjName SIZE 160, 26 PICTURE Replicate( 'X', 32 ) MAXLENGTH 0

   @ 10, 100 SAY "Type:" SIZE 120, 22
   @ 10, 100 GET oEdit3 VAR cType SIZE 80, 26 PICTURE "XXXX" MAXLENGTH 0

   @ 20, 200 BUTTON "Ok" SIZE 100, 32 ON CLICK bOk
   @ 180, 200 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32

   oDlg:Activate()

   RETURN Nil

STATIC FUNCTION CntImport()

   LOCAL cDir := hwg_SelectFolder(), arr, i, n := 0

   IF Empty( cDir )
      RETURN Nil
   ENDIF

   cDir += hb_ps()
   arr := Directory( cDir + "*.*" )
   FOR i := 1 TO Len( arr )
      IF oContainer:Add( hb_fnameName( arr[i,1] ), Substr( hb_fnameExt( arr[i,1] ), 2 ), ;
         MemoRead( cDir + arr[i,1] ) )
         n ++
      ENDIF
   NEXT
   lCntUpdated := .T.

   hwg_MsgInfo( Ltrim(Str(n)) + " files added" )

   oBrw:Refresh()

   RETURN Nil

STATIC FUNCTION CntExport2Prg( fname )

   LOCAL i, j, s, nLen := Len( oContainer:aObjects ), cBuf
   LOCAL h

   IF Empty( fname )
      RETURN Nil
   ENDIF

   h := FCreate( fname )
   FWrite( h, "// Embedded resource file, created by Bincnt " + APP_VERSION + e". Do not edit!\n\n" )
   FWrite( h, e"INIT PROCEDURE RESOURCES\n   __mvPublic( \x22HWG_RESO_ARR\x22 )\n   __mvPut( \x22HWG_RESO_ARR\x22, hb_hash( ;\n" )

   FOR i := 1 TO nLen
      s := '"' + oContainer:aObjects[i,OBJ_NAME] + '", { "' + ;
         Trim(oContainer:aObjects[i,OBJ_TYPE]) + '", e"'
      hb_gcStep()
      cBuf := oContainer:Get( oContainer:aObjects[i,OBJ_NAME] )
      FOR j := 1 TO Len( cBuf )
         s += "\x" + hb_NumToHex( hb_bPeek( cBuf,j ), 2 )
      NEXT
      s += '" }' + Iif( i == nLen, "", "," ) + e" ;\n"
      FWrite( h, s )
   NEXT

   FWrite( h, e"   ) )\n   RETURN\n" )
   FClose( h )

   RETURN Nil

STATIC FUNCTION CntExport2Bin( fname )

   LOCAL oCntNew := HBinC():Create( fname ), i

   FOR i := 1 TO Len( oContainer:aObjects )
      oCntNew:Add( oContainer:aObjects[i,OBJ_NAME], oContainer:aObjects[i,OBJ_TYPE], ;
         oContainer:Get( oContainer:aObjects[i,OBJ_NAME] ) )
   NEXT
   oCntNew:Close()

   RETURN Nil

STATIC FUNCTION CntDel()
   LOCAL n := oBrw:nCurrent

   IF hwg_MsgYesNo( "Really delete " + oContainer:aObjects[n,1] + "?" )
      oContainer:Del( oContainer:aObjects[n,1] )
      lCntUpdated := .T.
      oBrw:Refresh()
   ENDIF

   RETURN Nil

STATIC FUNCTION CntSave()

   CntExport2Prg( cCntFile )

   RETURN Nil

STATIC FUNCTION CntSaveAs()

   LOCAL oDlg, oEdit, nChoic := 1, fname, lRes := .F.
   LOCAL bFile := { ||
#ifdef __GTK__
      fname := hwg_Selectfile( "( *.* )", "*.*", CurDir() )
#else
      fname := hwg_Savefile( "*.*", "( *.* )", "*.*", CurDir() )
#endif
      IF !Empty( fname )
         oEdit:value := fname
      ENDIF
      RETURN .T.
   }
   LOCAL bOk := { ||
      IF Empty( fname := oEdit:value )
         hwg_MsgStop( "Set file name" )
         RETURN .F.
      ENDIF
      hwg_EndDialog()
      lRes := .T.
      RETURN .T.
   }

   INIT DIALOG oDlg TITLE "Save as..." ;
      AT 50, 100 SIZE 310, 250 FONT HWindow():GetMain():oFont

   RADIOGROUP
   @ 10,20 RADIOBUTTON "Binary container" SIZE 180, 24 ON CLICK {||nChoic := 1}
   @ 10,60 RADIOBUTTON "Prg file" SIZE 180, 24 ON CLICK {||nChoic := 2}
   END RADIOGROUP SELECTED 1

   @ 10, 100 EDITBOX oEdit CAPTION "" STYLE ES_AUTOHSCROLL SIZE 200, 26
   @ 210, 100 BUTTON "Browse" SIZE 80, 26 ON CLICK bFile

   @ 20, 200 BUTTON "Ok" SIZE 100, 32 ON CLICK bOk
   @ 180, 200 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32

   oDlg:Activate()

   IF lRes
      IF nChoic == 2
         CntExport2Prg( fname )
      ELSEIF oContainer:type == 0
         hb_vfCopyFile( oContainer:cName, fname )
      ELSE
         CntExport2Bin( fname )
      ENDIF
   ENDIF

   RETURN Nil


STATIC FUNCTION CntSaveItem()
   LOCAL n := oBrw:nCurrent
   LOCAL fname

#ifdef __GTK__
   fname := hwg_Selectfile( "( *.* )", "*.*", CurDir() )
#else
   fname := hwg_Savefile( "*.*", "( *.* )", "*.*", CurDir() )
#endif
   IF !Empty( fname )
      fname := hb_FNameExtSetDef( fname, oContainer:aObjects[n,2] )
      hb_MemoWrit( fname, oContainer:Get( oContainer:aObjects[n,1] ) )
   ENDIF

   RETURN Nil

STATIC FUNCTION CntPack()

   IF oContainer:type == 1
      RETURN Nil
   ENDIF

   oContainer:Pack()
   hwg_WriteStatus( HWindow():GetMain(), 2, "Items: " + LTrim( Str(oContainer:nItems ) ) )
   oBrw:aArray := oContainer:aObjects
   oBrw:Top()
   oBrw:Refresh()

   RETURN Nil

STATIC FUNCTION CntView()

   LOCAL oDlg, oBoa
   LOCAL name := oContainer:aObjects[oBrw:nCurrent,1], type := Trim( oContainer:aObjects[oBrw:nCurrent,2] )
   LOCAL cBuf, handle, aBmpSize

   IF !( Trim( type ) $ "bmp;jpg;png;gif;ico" )
      RETURN Nil
   ENDIF
   IF !Empty( cBuf := oContainer:Get( name ) ) .AND. !Empty( handle := hwg_OpenImage( cBuf, .T. ) )
      aBmpSize := hwg_Getbitmapsize( handle )
   ELSE
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg TITLE  name + " " + ;
      Ltrim(Str(aBmpSize[1])) + "x" + Ltrim(Str(aBmpSize[2])) ;
      AT 0, 0 SIZE Max( aBmpSize[1] + 20, 220 ), aBmpSize[2] + 70 FONT HWindow():GetMain():oFont ;
      ON EXIT {||hwg_Deleteobject(handle),.T.}

   @ 0, 0 BOARD oBoa SIZE oDlg:nWidth, oDlg:nHeight-50 ;
      ON SIZE {|o,x,y|o:Move(,,x,y-50)} ON PAINT {|o,h|FPaint(o,h,handle)}

   @ Int((oDlg:nWidth-100)/2), oDlg:nHeight - 50 BUTTON "Close" ON CLICK {|| oDlg:Close() } SIZE 100,32

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil

STATIC FUNCTION FPaint( o, hDC, handle )

   hwg_Drawbitmap( hDC, handle,, 10, 10 )

   RETURN -1

STATIC FUNCTION CntInfo()

   LOCAL oDlg

   INIT DIALOG oDlg TITLE "Info" ;
      AT 0, 0 SIZE 280, 320 FONT HWindow():GetMain():oFont

   @ 20, 40 SAY "Type:" SIZE 140,26 STYLE SS_LEFT
   @ 160, 40 SAY Iif( oContainer:type==0, "Binary", "Prg" ) SIZE 100,26 STYLE SS_RIGHT

   @ 20, 80 SAY "Items:" SIZE 140,26 STYLE SS_LEFT
   @ 160, 80 SAY Ltrim(Str( oContainer:nItems )) SIZE 100,26 STYLE SS_RIGHT

   @ 20, 120 SAY "Content length:" SIZE 140,26 STYLE SS_LEFT
   @ 160, 120 SAY Ltrim(Str( oContainer:nCntLen )) SIZE 100,26 STYLE SS_RIGHT

   @ 20, 160 SAY "Content blocks:" SIZE 140,26 STYLE SS_LEFT
   @ 160, 160 SAY Ltrim(Str( oContainer:nCntBlocks )) SIZE 100,26 STYLE SS_RIGHT

   @ 60, 250 BUTTON "Close" ON CLICK {|| oDlg:Close() } SIZE 160,36

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil

#define  CLR_VDBLUE  10485760
#define  CLR_LBLUE0  12164479

STATIC FUNCTION About()

   LOCAL oDlg

   INIT DIALOG oDlg TITLE "About" ;
      AT 0, 0 SIZE 400, 320 FONT HWindow():GetMain():oFont COLOR hwg_colorC2N("CCCCCC")

   @ 20, 40 SAY "Binary container manager" SIZE 360,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 20, 64 SAY "Version "+APP_VERSION SIZE 360,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 10, 100 SAY "Copyright 2014 Alexander S.Kresin" SIZE 380,26 STYLE SS_CENTER COLOR CLR_VDBLUE TRANSPARENT
   @ 20, 124 SAY "http://www.kresin.ru" LINK "http://www.kresin.ru" SIZE 360,26 STYLE SS_CENTER
   @ 20, 160 LINE LENGTH 360
   @ 20, 180 SAY hwg_version() SIZE 360,26 STYLE SS_CENTER COLOR CLR_LBLUE0 TRANSPARENT

   @ 120, 250 BUTTON "Close" ON CLICK {|| hwg_EndDialog()} SIZE 160,36

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil
