/*
 * $Id: hformgen.prg,v 1.18 2004-07-18 14:24:16 alkresin Exp $
 *
 * Designer
 * HFormGen class
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "fileio.ch"
#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "hxml.ch"

Static aG := { "left","top","width","height" }

Static aStaticTypes := { { SS_LEFT,"SS_LEFT" }, { SS_CENTER,"SS_CENTER" }, ;
    { SS_RIGHT,"SS_RIGHT" }, { SS_BLACKFRAME,"SS_BLACKFRAME" },            ;
    { SS_GRAYFRAME,"SS_GRAYFRAME" }, { SS_WHITEFRAME,"SS_WHITEFRAME" },    ;
    { SS_BLACKRECT,"SS_BLACKRECT" }, { SS_GRAYRECT,"SS_GRAYRECT" },        ;
    { SS_WHITERECT,"SS_WHITERECT" }, { SS_ETCHEDFRAME,"SS_ETCHEDFRAME" },  ;
    { SS_ETCHEDHORZ,"SS_ETCHEDHORZ" }, { SS_ETCHEDVERT,"SS_ETCHEDVERT" },  ;
    { SS_OWNERDRAW,"SS_OWNERDRAW" } }

Static aStyles := { { WS_POPUP,"WS_POPUP" }, { WS_CHILD,"WS_CHILD" }, { WS_VISIBLE,"WS_VISIBLE" }, ;
    { WS_DISABLED,"WS_DISABLED" }, { WS_CLIPSIBLINGS,"WS_CLIPSIBLINGS" }, { WS_BORDER,"WS_BORDER" }, ;
    { WS_DLGFRAME,"WS_DLGFRAME" }, { WS_VSCROLL,"WS_VSCROLL" }, { WS_HSCROLL,"WS_HSCROLL" }, ;
    { WS_SYSMENU,"WS_SYSMENU" }, { WS_THICKFRAME,"WS_THICKFRAME" }, { WS_GROUP,"WS_GROUP" }, ;
    { WS_TABSTOP,"WS_TABSTOP" }, { BS_PUSHBUTTON,"BS_PUSHBUTTON" }, { BS_CHECKBOX,"BS_CHECKBOX" }, ;
    { BS_AUTORADIOBUTTON,"BS_AUTORADIOBUTTON" }, { ES_AUTOHSCROLL,"ES_AUTOHSCROLL" }, ;
    { ES_AUTOVSCROLL,"ES_AUTOVSCROLL" }, { ES_MULTILINE,"ES_MULTILINE" }, { BS_GROUPBOX,"BS_GROUPBOX" }, ;
    { CBS_DROPDOWNLIST,"CBS_DROPDOWNLIST" }, { SS_OWNERDRAW,"SS_OWNERDRAW" }  }

CLASS HFormGen INHERIT HObject

   CLASS VAR aForms INIT {}
   CLASS VAR oDlgSelected
   DATA oDlg
   DATA name
   DATA filename, path
   DATA type  INIT 1
   DATA lGet  INIT .T.
   DATA oCtrlSelected
   DATA lChanged  INIT .F.
   DATA aProp         INIT {}
   DATA aMethods      INIT {}

   METHOD New() CONSTRUCTOR
   METHOD Open() CONSTRUCTOR
   METHOD OpenR() CONSTRUCTOR
   METHOD Save( lAs )
   METHOD CreateDialog( aProp )
   METHOD GetProp( cName )
   METHOD SetProp( xName,xValue )
   METHOD End()

ENDCLASS

METHOD New() CLASS HFormGen
Local oDlg, i := 1, name
Local hDCwindow := GetDC( GetActiveWindow() ), aTermMetr := GetDeviceArea( hDCwindow )

   DeleteDC( hDCwindow )
   DO WHILE .T.
      name := "Form"+Ltrim(Str(i))
      IF Ascan( ::aForms,{|o|o:name==name} ) == 0
        Exit
      ENDIF
      i ++
   ENDDO

   ::type := 1
   ::name := name
   ::CreateDialog( { {"Left",Ltrim(Str(aTermMetr[1]-500))}, {"Top","120"},{"Width","500"},{"Height","400"},{"Caption",name} } )
   ::filename := ""

   Aadd( ::aForms, Self )

Return Self

METHOD OpenR( fname )  CLASS HFormGen
Local oForm := ::aForms[1]

   IF !MsgYesNo( "The form will be opened INSTEAD of current ! Are you agree ?" )
      Return Nil
   ENDIF
   oDesigner:lSingleForm := .F.
   oForm:lChanged := .F.
   oForm:End()
   oDesigner:lSingleForm := .T.

Return ::Open( fname )

METHOD Open( fname,cForm )  CLASS HFormGen
Local aFormats := oDesigner:aFormats
Private oForm := Self, aCtrlTable

   IF fname != Nil
      ::path := Filepath( fname )
      ::filename := CutPath( fname )
   ENDIF
   IF fname != Nil .OR. cForm != Nil .OR. FileDlg( Self,.T. )
      IF ::type == 1
         ReadForm( Self,cForm )
      ELSE
         IF Valtype( aFormats[ ::type,4 ] ) == "C"
            aFormats[ ::type,4 ] := OpenScript( cCurDir + aFormats[ ::type,3 ], aFormats[ ::type,4 ] )
         ENDIF
         IF Valtype( aFormats[ ::type,6 ] ) == "C"
            aFormats[ ::type,6 ] := OpenScript( cCurDir + aFormats[ ::type,3 ], aFormats[ ::type,6 ] )
         ENDIF
         IF Valtype( aFormats[ ::type,6 ] ) == "A"
            DoScript( aFormats[ ::type,6 ] )
         ENDIF
         IF Valtype( aFormats[ ::type,4 ] ) == "A"
            DoScript( aFormats[ ::type,4 ] )
         ENDIF
      ENDIF
      IF ::oDlg != Nil
         ::name := ::oDlg:title
         Aadd( ::aForms, Self )
         InspSetCombo()
      ENDIF
      IF ::oDlg == Nil .OR. Empty( ::oDlg:aControls )
         MsgStop( "Can't load the form" )
      ENDIF
   ENDIF

RETURN Self

METHOD End( lDlg ) CLASS HFormGen
Local i, j, name := ::name, oDlgSel

   IF lDlg == Nil; lDlg := .F.; ENDIF
   IF ::lChanged
      IF MsgYesNo( ::name + " was changed. Save it ?" )
         ::Save()
      ENDIF
   ENDIF

   FOR i := 1 TO Len( HFormGen():aForms )
      IF HFormGen():aForms[i]:oDlg:handle != ::oDlg:handle
         oDlgSel := HFormGen():aForms[i]:oDlg
      ELSE
         j := i
      ENDIF
   NEXT
   IF oDlgSel != Nil
      SetDlgSelected( oDlgSel )
   ELSE
      HFormGen():oDlgSelected := Nil
      IF oDesigner:oDlgInsp != Nil
         oDesigner:oDlgInsp:Close()
         // InspSetCombo()
      ENDIF
   ENDIF

   Adel( ::aForms,j )
   Asize( ::aForms, Len(::aForms)-1 )
   IF !lDlg
      ::oDlg:bDestroy := Nil
      EndDialog( ::oDlg:handle )
   ENDIF
   IF oDesigner:lSingleForm
      oDesigner:oMainWnd:Close()
   ENDIF

RETURN .T.

METHOD Save( lAs ) CLASS HFormGen
Local aFormats := oDesigner:aFormats
Private oForm := Self, aCtrlTable

   IF lAs == Nil; lAs := .F.; ENDIF
   IF !::lChanged .AND. !lAs
      MsgStop( "Nothing to save" )
      Return Nil
   ENDIF

   IF ( oDesigner:lSingleForm .AND. !lAs ) .OR. ;
   ( ( Empty( ::filename ) .OR. lAs ) .AND. FileDlg( Self,.F. ) ) .OR. !Empty( ::filename )
      FrmSort( ::oDlg:aControls )
      IF ::type == 1
         aControls := WriteForm( Self )
      ELSE
         IF Valtype( aFormats[ ::type,5 ] ) == "C"
            aFormats[ ::type,5 ] := OpenScript( cCurDir + aFormats[ ::type,3 ], aFormats[ ::type,5 ] )
         ENDIF
         IF Valtype( aFormats[ ::type,6 ] ) == "C"
            aFormats[ ::type,6 ] := OpenScript( cCurDir + aFormats[ ::type,3 ], aFormats[ ::type,6 ] )
         ENDIF
         IF Valtype( aFormats[ ::type,6 ] ) == "A"
            DoScript( aFormats[ ::type,6 ] )
         ENDIF
         IF Valtype( aFormats[ ::type,5 ] ) == "A"
            DoScript( aFormats[ ::type,5 ] )
         ENDIF
      ENDIF
   ENDIF
   IF !lAs
      ::lChanged := .F.
   ENDIF

RETURN Nil

METHOD CreateDialog( aProp ) CLASS HFormGen
Local i, j, cPropertyName, xProperty, oFormDesc := oDesigner:oFormDesc
Private value, oCtrl

   INIT DIALOG ::oDlg                         ;
          STYLE DS_ABSALIGN+WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SYSMENU+WS_SIZEBOX ;
          ON SIZE  {|o,h,w|dlgOnSize(o,h,w)}  ;
          ON PAINT {|o|PaintDlg(o)}           ;
          ON EXIT  {|o|o:oParent:End(.T.)}    ;
          ON GETFOCUS {|o|SetDlgSelected(o)}  ;
          ON OTHER MESSAGES {|o,m,wp,lp|MessagesProc(o,m,wp,lp)}

   ::oDlg:oParent := Self

   oCtrl := ::oDlg
   IF oFormDesc != Nil
      FOR i := 1 TO Len( oFormDesc:aItems )
         IF oFormDesc:aItems[i]:title == "property"
            IF !Empty( oFormDesc:aItems[i]:aItems )
               IF Valtype( oFormDesc:aItems[i]:aItems[1]:aItems[1] ) == "C"
                  oFormDesc:aItems[i]:aItems[1]:aItems[1] := &( "{||" + oFormDesc:aItems[i]:aItems[1]:aItems[1] + "}" )
               ENDIF
               xProperty := Eval( oFormDesc:aItems[i]:aItems[1]:aItems[1] )
            ELSE
               xProperty := oFormDesc:aItems[i]:GetAttribute( "value" )
            ENDIF
            Aadd( ::aProp, { oFormDesc:aItems[i]:GetAttribute( "name" ),  ;
                             xProperty, ;
                             oFormDesc:aItems[i]:GetAttribute( "type" ) } )
         ELSEIF oFormDesc:aItems[i]:title == "method"
            Aadd( ::aMethods, { oFormDesc:aItems[i]:GetAttribute( "name" ),"" } )
         ENDIF
      NEXT
   ENDIF
   IF aProp != Nil
      FOR i := 1 TO Len( aProp )
         cPropertyName := Lower( aProp[ i,1 ] )
         IF ( j := Ascan( ::aProp, {|a|Lower(a[1])==cPropertyName} ) ) != 0
            IF !Empty( aProp[i,2] )
               ::aProp[j,2] := aProp[i,2]
            ENDIF
         ELSE
            // Aadd( ::aProp, { aProp[i,1], aProp[i,2] } )
         ENDIF
      NEXT
   ENDIF
   FOR i := 1 TO Len( ::aProp )
      value := ::aProp[ i,2 ]
      IF value != Nil // .AND. !Empty( value )
         cPropertyName := Lower( ::aProp[ i,1 ] )
         j := Ascan( oDesigner:aDataDef, {|a|a[1]==cPropertyName} )
         IF j != 0 .AND. oDesigner:aDataDef[ j,3 ] != Nil
            EvalCode( oDesigner:aDataDef[ j,3 ] )
         ENDIF
      ENDIF
   NEXT

   ::oDlg:Activate(.T.)

   IF oDesigner:oDlgInsp == Nil
      InspOpen()
   ENDIF

RETURN Nil

METHOD GetProp( cName ) CLASS HFormGen
Local i
  cName := Lower( cName )
  i := Ascan( ::aProp,{|a|Lower(a[1])==cName} )
Return Iif( i==0, Nil, ::aProp[i,2] )

METHOD SetProp( xName,xValue )

   IF Valtype( xName ) == "C"
      xName := Lower( xName )
      xName := Ascan( ::aProp,{|a|Lower(a[1])==xName} )
   ENDIF
   IF xName != 0
      ::aProp[xName,2] := xValue
   ENDIF
Return Nil

// ------------------------------------------

Static Function dlgOnSize( oDlg,h,w )
Local aCoors := GetClientRect( oDlg:handle )

   // Writelog( "dlgOnSize "+Str(h)+Str(w) )
   oDlg:oParent:SetProp("Width",Ltrim(Str(oDlg:nWidth:=aCoors[3])))
   oDlg:oParent:SetProp("Height",Ltrim(Str(oDlg:nHeight:=aCoors[4])))
   InspUpdBrowse()
   oDlg:oParent:lChanged:=.T.
Return Nil

Static Function SetDlgSelected( oDlg )

   IF HFormGen():oDlgSelected == Nil .OR. HFormGen():oDlgSelected:handle != oDlg:handle
      HFormGen():oDlgSelected := oDlg
      IF oDesigner:oDlgInsp != Nil
         InspSetCombo()
      ENDIF
   ENDIF
Return .T.

Function CnvCtrlName( cName,l2 )
Local i
   IF aCtrlTable == Nil
      Return cName
   ENDIF
   IF l2 == Nil
      l2 := .F.
   ENDIF
   IF l2
      i := Ascan( aCtrlTable,{|a|a[2]==cName} )
   ELSE
      i := Ascan( aCtrlTable,{|a|a[1]==cName} )
   ENDIF
Return Iif( i == 0, Nil, Iif( l2,aCtrlTable[i,1],aCtrlTable[i,2] ) )

Static Function FileDlg( oFrm,lOpen )
Local oDlg, aFormats := oDesigner:aFormats
Local aCombo := {}, af := {}, oEdit1, oEdit2
Local nType := 1, fname := Iif( lOpen.OR.oFrm:filename==Nil,"",oFrm:filename )
Local formname := Iif( lOpen,"",oFrm:name )
Local i

   FOR i := 1 TO Len( aFormats )
      IF i == 1 .OR. ( lOpen .AND. aFormats[ i,4 ] != Nil ) .OR. ;
                     ( !lOpen .AND. aFormats[ i,5 ] != Nil )
         Aadd( aCombo, aFormats[ i,1 ] )
         Aadd( af,i )
         IF !lOpen .AND. oFrm:type == i
            nType := Len( af ) 
         ENDIF
      ENDIF
   NEXT

   INIT DIALOG oDlg TITLE Iif( lOpen,"Open form","Save form" ) ;
       AT 50, 100 SIZE 310,250 FONT oDesigner:oMainWnd:oFont

   @ 10,20 GET COMBOBOX nType ITEMS aCombo SIZE 140, 150 ;
       ON CHANGE {||Iif(lOpen,.F.,(fname:=CutExten(fname)+Iif(!Empty(fname),"."+aFormats[af[nType],2],""),oEdit1:Refresh()))}

   @ 10,70 GET oEdit1 VAR fname  ;
        STYLE ES_AUTOHSCROLL      ;
        SIZE 200, 26
 
   @ 210,70 BUTTON "Browse" SIZE 80, 26   ;
        ON CLICK {||BrowFile(lOpen,af[nType],oEdit1,oEdit2)}

   @ 10,110 SAY "Form name:" SIZE 80,22

   @ 10,135 GET oEdit2 VAR formname SIZE 140, 26

   @ 20,200 BUTTON "Ok" ID IDOK  SIZE 100, 32
   @ 180,200 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32

   oDlg:Activate()

   IF oDlg:lResult
      oFrm:type := af[nType]
      oFrm:filename := CutPath( fname )
      IF Empty( FilExten( oFrm:filename ) )
         oFrm:filename += "."+aFormats[ af[nType],2 ]
      ENDIF
      oFrm:path := Iif( Empty( FilePath(fname) ), ds_mypath, FilePath(fname) )
      Return .T.
   ENDIF

Return .F.

Static Function BrowFile( lOpen,nType,oEdit1, oEdit2 )
Local fname, s1, s2

   s2 := "*." + oDesigner:aFormats[ nType,2 ]
   s1 := oDesigner:aFormats[ nType,1 ] + "( " + s2 + " )"

   IF lOpen
      fname := SelectFile( s1, s2,ds_mypath )
   ELSE
      fname := SaveFile( s2,s1,s2,ds_mypath )
   ENDIF
   IF !Empty( fname )
      ds_mypath := FilePath( fname )
      fname := CutPath( fname )
      oEdit1:SetGet( fname )
      oEdit1:Refresh()
      SetFocus( oEdit2:handle )
   ENDIF

Return Nil

Static Function ReadTree( aParent,oDesc )
Local i, aTree := {}, oNode

   FOR i := 1 TO Len( oDesc:aItems )
      oNode := oDesc:aItems[i]
      IF oNode:type == HBXML_TYPE_CDATA
         aParent[4] := oNode:aItems[1]
      ELSE
         Aadd( aTree, { Nil, oNode:GetAttribute("name"), ;
                 Val( oNode:GetAttribute("id") ), Nil } )
         IF !Empty( oNode:aItems )
            aTree[ Len(aTree),1 ] := ReadTree( aTail( aTree ),oNode )
         ENDIF
      ENDIF
   NEXT

Return Iif( Empty(aTree), Nil, aTree )

Static Function ReadCtrls( oDlg, oCtrlDesc, oContainer, nPage )
Local i, j, o, aRect, aProp := {}, aItems := oCtrlDesc:aItems, oCtrl, cName, cProperty

   FOR i := 1 TO Len( aItems )
      IF aItems[i]:title == "style"
         FOR j := 1 TO Len( aItems[i]:aItems )
            o := aItems[i]:aItems[j]
            IF o:title == "property"
               cPropertyName := o:GetAttribute( "name" )
               IF Lower( cPropertyName ) == "geometry"
                  aRect := hfrm_Str2Arr( o:aItems[1] )
                  Aadd( aProp, { "Left", aRect[1] } )
                  Aadd( aProp, { "Top", aRect[2] } )
                  Aadd( aProp, { "Width", aRect[3] } )
                  Aadd( aProp, { "Height", aRect[4] } )
               ELSEIF Lower( cPropertyName ) == "font"
                  Aadd( aProp, { cPropertyName,hfrm_FontFromxml( o:aItems[1] ) } )
               ELSEIF Lower( cPropertyName ) == "atree"
                  Aadd( aProp, { cPropertyName,ReadTree( ,o ) } )
               ELSEIF !Empty(o:aItems)
                  cProperty := Left( o:aItems[1],1 )
                  IF cProperty == '['
                     cProperty := Substr( o:aItems[1],2,Len(o:aItems[1])-2 )
                  ELSEIF cProperty == '.'
                     cProperty := Iif( Substr(o:aItems[1],2,1)=="T","True","False" )
                  ELSEIF cProperty == '{'
                     cProperty := hfrm_Str2Arr( o:aItems[1] )
                  ELSE
                     cProperty := o:aItems[1]
                  ENDIF
                  Aadd( aProp, { cPropertyName,cProperty } )
               ENDIF
            ENDIF
         NEXT
         IF Ascan( aProp,{|a|a[1]=="Name"} ) == 0
            Aadd( aProp, { "Name","" } )
         ENDIF
         oCtrl := HControlGen():New( oDlg, oCtrlDesc:GetAttribute( "class" ), aProp )
         IF oContainer != Nil
            oContainer:AddControl( oCtrl )
            oCtrl:oContainer := oContainer
         ENDIF
         IF nPage != Nil
            oCtrl:nPage := nPage
         ENDIF
      ELSEIF aItems[i]:title == "method"
         cName := aItems[i]:GetAttribute( "name" )
         IF ( j := Ascan( oCtrl:aMethods, {|a|a[1]==cName} ) ) != 0
            oCtrl:aMethods[j,2] := aItems[i]:aItems[1]:aItems[1]
         ENDIF
      ELSEIF aItems[i]:title == "part"
         IF Lower( aItems[i]:GetAttribute( "class" ) ) == "pagesheet"
            FOR j := 1 TO Len( aItems[i]:aItems )
               ReadCtrls( oDlg,aItems[i]:aItems[j],oCtrl,Val(aItems[i]:GetAttribute( "page" )) )
            NEXT
         ELSE
            ReadCtrls( oDlg,aItems[i],oCtrl )
         ENDIF
         IF oCtrl != Nil .AND. Lower( oCtrl:cClass ) == "page"
            aRect := oCtrl:GetProp( "Tabs" )
            IF aRect != Nil .AND. !Empty( aRect )
               Page_Upd( oCtrl, aRect )
               Page_Select( oCtrl, 1, .T. )
            ENDIF
         ENDIF
      ENDIF
   NEXT

Return Nil

Static Function ReadForm( oForm,cForm )
Local oDoc := Iif( cForm!=Nil, HXMLDoc():ReadString(cForm), HXMLDoc():Read( oForm:path+oForm:filename ) )
Local i, j, aItems, o, aProp := {}, cPropertyName, aRect, pos, cProperty

   IF Empty( oDoc:aItems )
      MsgStop( "Can't open "+oForm:path+oForm:filename )
      Return Nil
   ELSEIF oDoc:aItems[1]:title != "part" .OR. oDoc:aItems[1]:GetAttribute( "class" ) != "form"
      MsgStop( "Form description isn't found" )
      Return Nil
   ENDIF
   aItems := oDoc:aItems[1]:aItems
   FOR i := 1 TO Len( aItems )
      IF aItems[i]:title == "style"
         FOR j := 1 TO Len( aItems[i]:aItems )
            o := aItems[i]:aItems[j]
            IF o:title == "property"
               cPropertyName := o:GetAttribute( "name" )
               IF Lower( cPropertyName ) == "geometry"
                  aRect := hfrm_Str2Arr( o:aItems[1] )
                  Aadd( aProp, { "Left", aRect[1] } )
                  Aadd( aProp, { "Top", aRect[2] } )
                  Aadd( aProp, { "Width", aRect[3] } )
                  Aadd( aProp, { "Height", aRect[4] } )
               ELSEIF Lower( cPropertyName ) == "font"
                  Aadd( aProp, { cPropertyName,hfrm_FontFromxml( o:aItems[1] ) } )
               ELSEIF !Empty(o:aItems)
                  cProperty := Left( o:aItems[1],1 )
                  IF cProperty == '['
                     cProperty := Substr( o:aItems[1],2,Len(o:aItems[1])-2 )
                  ELSEIF cProperty == '.'
                     cProperty := Iif( Substr(o:aItems[1],2,1)=="T","True","False" )
                  ELSEIF cProperty == '{'
                     cProperty := hfrm_Str2Arr( o:aItems[1] )
                  ELSE
                     cProperty := o:aItems[1]
                  ENDIF
                  Aadd( aProp, { cPropertyName,cProperty } )
               ENDIF
            ENDIF
         NEXT
         oForm:CreateDialog( aProp )
      ELSEIF aItems[i]:title == "method"
         cPropertyName := aItems[i]:GetAttribute( "name" )
         IF ( j := Ascan( oForm:aMethods, {|a|a[1]==cPropertyName} ) ) != 0
            oForm:aMethods[j,2] := aItems[i]:aItems[1]:aItems[1]
         ENDIF
      ELSEIF aItems[i]:title == "part"
         ReadCtrls( oForm:oDlg,aItems[i] )
      ENDIF
   NEXT
Return Nil

Function IsDefault( oCtrl,aPropItem )
Local j1, aItems := oCtrl:oXMLDesc:aItems, xProperty, cPropName := Lower(aPropItem[1])

   FOR j1 := 1 TO Len( aItems )
      IF aItems[j1]:title == "property" .AND. ;
                   Lower(aItems[j1]:GetAttribute("name")) == cPropName

         IF !Empty( aItems[j1]:aItems )
            IF Valtype( aItems[j1]:aItems[1]:aItems[1] ) == "C"
               aItems[j1]:aItems[1]:aItems[1] := &( "{||" + aItems[j1]:aItems[1]:aItems[1] + "}" )
            ENDIF
            xProperty := Eval( aItems[j1]:aItems[1]:aItems[1] )
         ELSE
            xProperty := aItems[j1]:GetAttribute( "value" )
         ENDIF

         IF xProperty != Nil .AND. xProperty == aPropItem[2]
            Return .T.
         ENDIF
      ENDIF
   NEXT

Return .F.

Static Function WriteTree( aTree, oParent )
Local i, oNode, type

   FOR i := 1 TO Len( aTree )
      IF aTree[i,4] != Nil .OR. ( Valtype( aTree[i,1] ) == "A" .AND. !Empty( aTree[i,1] ) )
         type := HBXML_TYPE_TAG
      ELSE
         type := HBXML_TYPE_SINGLE
      ENDIF
      oNode := oParent:Add( HXMLNode():New( "item", type, ;
             { { "name",aTree[i,2] },{ "id",Ltrim(Str(aTree[i,3])) } } ) )
      IF aTree[i,4] != Nil
         oNode:Add( HXMLNode():New( ,HBXML_TYPE_CDATA,,aTree[i,4] ) )
      ENDIF
      IF Valtype( aTree[i,1] ) == "A" .AND. !Empty( aTree[i,1] )
         WriteTree( aTree[i,1], oNode )
      ENDIF
   NEXT
Return Nil

Static Function WriteCtrl( oParent,oCtrl,lRoot )
Local i, j, j1, oNode, oNode1, oStyle, oMeth, aItems, cPropertyName, value, lDef
Local cProperty, i1

   IF !lRoot .OR. oCtrl:oContainer == Nil
      aItems := oCtrl:oXMLDesc:aItems
      oNode := oParent:Add( HXMLNode():New( "part",,{ { "class",oCtrl:cClass } } ) )
      oStyle := oNode:Add( HXMLNode():New( "style" ) )
      oStyle:Add( HXMLNode():New( "property",,{ { "name","Geometry" } }, ;
          Arr2Str( { oCtrl:nLeft,oCtrl:nTop,oCtrl:nWidth,oCtrl:nHeight } ) ) )
      FOR j := 1 TO Len( oCtrl:aProp )
         cPropertyName := Lower(oCtrl:aProp[j,1])
         IF Ascan( aG,cPropertyName  ) != 0
            lDef := .T.
         /*
         ELSEIF ( cPropertyName == "textcolor" .AND. oCtrl:tColor == 0 ) .OR. ;
                ( cPropertyName == "backcolor" .AND. oCtrl:bColor == GetSysColor( COLOR_3DFACE ) )
            lDef := .T.
         */
         ELSEIF ( cPropertyName == "name" .AND. Empty( oCtrl:aProp[j,2] ) )
            lDef := .T.
         ELSE
            lDef := IsDefault( oCtrl, oCtrl:aProp[j] )
         ENDIF
         IF !lDef
            IF Lower(oCtrl:aProp[j,1]) == "font"
               IF oCtrl:oFont != Nil
                  oNode1 := oStyle:Add( HXMLNode():New( "property",,{ { "name","font" } } ) )
                  oNode1:Add( Font2XML( oCtrl:oFont ) )
               ENDIF
            ELSEIF Lower(oCtrl:aProp[j,1]) == "atree"
               oNode1 := oStyle:Add( HXMLNode():New( "property",,{ { "name","atree" } } ) )
               WriteTree( oCtrl:aProp[j,2],oNode1 )
            ELSEIF oCtrl:aProp[j,2] != Nil
               IF oCtrl:aProp[j,3] == "C"
                  cProperty := '[' + oCtrl:aProp[j,2] + ']'
               ELSEIF oCtrl:aProp[j,3] == "N"
                  cProperty := oCtrl:aProp[j,2]
               ELSEIF oCtrl:aProp[j,3] == "L"
                  cProperty := Iif( Lower( oCtrl:aProp[j,2] ) == "true",".T.",".F." )
               ELSEIF oCtrl:aProp[j,3] == "A"
                  cProperty := Arr2Str( oCtrl:aProp[j,2] )
               ELSE
                  cProperty := ""
               ENDIF
               oStyle:Add( HXMLNode():New( "property",,{ { "name",oCtrl:aProp[j,1] } },cProperty ) )
            ENDIF
         ENDIF
      NEXT
      FOR j := 1 TO Len( oCtrl:aMethods )
         IF !Empty( oCtrl:aMethods[j,2] )
            oMeth := oNode:Add( HXMLNode():New( "method",,{ { "name",oCtrl:aMethods[j,1] } } ) )
            oMeth:Add( HXMLNode():New( ,HBXML_TYPE_CDATA,,oCtrl:aMethods[j,2] ) )
         ENDIF
      NEXT
      IF !Empty( oCtrl:aControls )
         IF Lower( oCtrl:cClass ) == "page" .AND. ; 
              ( aItems := oCtrl:GetProp("Tabs") ) != Nil .AND. ;
              !Empty( aItems )
            FOR j := 1 TO Len( aItems )
               oNode1 := oNode:Add( HXMLNode():New( "part",,{ { "class","PageSheet" },{ "page",Ltrim(Str(j)) } } ) )
               FOR i := 1 TO Len( oCtrl:aControls )
                  IF oCtrl:aControls[i]:nPage == j
                     WriteCtrl( oNode1,oCtrl:aControls[i],.F. )
                  ENDIF
               NEXT
            NEXT
         ELSE
            FOR i := 1 TO Len( oCtrl:aControls )
               WriteCtrl( oNode,oCtrl:aControls[i],.F. )
            NEXT
         ENDIF
      ENDIF
   ENDIF

Return Nil

Static Function WriteForm( oForm )
Local oDoc := HXMLDoc():New()
Local oNode, oNode1, oStyle, i, i1, oMeth, cProperty

   oNode := oDoc:Add( HXMLNode():New( "part",,{ { "class","form" } } ) )
   oStyle := oNode:Add( HXMLNode():New( "style" ) )  
   oStyle:Add( HXMLNode():New( "property",,{ { "name","Geometry" } }, ;
       Arr2Str( { oForm:oDlg:nLeft,oForm:oDlg:nTop,oForm:oDlg:nWidth,oForm:oDlg:nHeight } ) ) )
   FOR i := 1 TO Len( oForm:aProp )
      IF Ascan( aG, Lower(oForm:aProp[i,1]) ) == 0
         IF Lower(oForm:aProp[i,1]) == "font"
            IF oForm:oDlg:oFont != Nil
               oNode1 := oStyle:Add( HXMLNode():New( "property",,{ { "name",oForm:aProp[i,1] } } ) )
               oNode1:Add( Font2XML( oForm:oDlg:oFont ) )
            ENDIF
         ELSEIF oForm:aProp[i,2] != Nil
            IF oForm:aProp[i,3] == "C"
               cProperty := '[' + oForm:aProp[i,2] + ']'
            ELSEIF oForm:aProp[i,3] == "N"
               cProperty := oForm:aProp[i,2]
            ELSEIF oForm:aProp[i,3] == "L"
               cProperty := Iif( Lower( oForm:aProp[i,2] ) == "true",".T.",".F." )
            ELSEIF oForm:aProp[i,3] == "A"
               cProperty := Arr2Str( oForm:aProp[i,2] )
            ELSE
               cProperty := ""
            ENDIF
            oStyle:Add( HXMLNode():New( "property",,{ { "name",oForm:aProp[i,1] } },cProperty ) )
         ENDIF
      ENDIF
   NEXT
   FOR i := 1 TO Len( oForm:aMethods )
      IF !Empty( oForm:aMethods[i,2] )
         oMeth := oNode:Add( HXMLNode():New( "method",,{ { "name",oForm:aMethods[i,1] } } ) )
         oMeth:Add( HXMLNode():New( ,HBXML_TYPE_CDATA,,oForm:aMethods[i,2] ) )
      ENDIF
   NEXT
   FOR i := 1 TO Len( oForm:oDlg:aControls )
      WriteCtrl( oNode,oForm:oDlg:aControls[i],.T. )
   NEXT

   IF oDesigner:lSingleForm
      oDesigner:cResForm := oDoc:Save()
   ELSE
      oDoc:Save( oForm:path + oForm:filename )
   ENDIF
Return Nil

Static Function PaintDlg( oDlg )
Local pps, hDC, aCoors, oCtrl := GetCtrlSelected( oDlg )

   pps := DefinePaintStru()
   hDC := BeginPaint( oDlg:handle, pps )

   // aCoors := GetClientRect( oDlg:handle )   
   // FillRect( hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4], oDlg:brush:handle )
   IF oCtrl != Nil .AND. oCtrl:nTop >= 0

      Rectangle( hDC, oCtrl:nLeft-3, oCtrl:nTop-3, ;
                  oCtrl:nLeft+oCtrl:nWidth+2, oCtrl:nTop+oCtrl:nHeight+2 )
      Rectangle( hDC, oCtrl:nLeft-1, oCtrl:nTop-1, ;
                  oCtrl:nLeft+oCtrl:nWidth, oCtrl:nTop+oCtrl:nHeight )

   ENDIF

   EndPaint( oDlg:handle, pps )

Return Nil


Static Function MessagesProc( oDlg, msg, wParam, lParam )
Local oCtrl, aCoors

   // writelog( str(msg)+str(wParam)+str(lParam) )
   IF msg == WM_MOUSEMOVE
      MouseMove( oDlg, wParam, LoWord( lParam ), HiWord( lParam ) )
      Return 1
   ELSEIF msg == WM_LBUTTONDOWN
      LButtonDown( oDlg, LoWord( lParam ), HiWord( lParam ) )
      Return 1
   ELSEIF msg == WM_LBUTTONUP
      LButtonUp( oDlg, LoWord( lParam ), HiWord( lParam ) )
      Return 1
   ELSEIF msg == WM_RBUTTONUP
      RButtonUp( oDlg, LoWord( lParam ), HiWord( lParam ) )
      Return 1
   ELSEIF msg == WM_MOVE
      aCoors := GetWindowRect( oDlg:handle )
      oDlg:oParent:SetProp( "Left", Ltrim(Str(oDlg:nLeft := aCoors[1])) )
      oDlg:oParent:SetProp( "Top", Ltrim(Str(oDlg:nTop  := aCoors[2])) )
      InspUpdBrowse()
      oDlg:oParent:lChanged := .T.
   ELSEIF msg == WM_KEYDOWN
      IF wParam == 46    // Del
         DeleteCtrl()
      ENDIF
   ELSEIF msg == WM_KEYUP
      IF wParam == 40        // Down
         IF ( oCtrl := GetCtrlSelected( oDlg ) ) != Nil
            SetBDown( ,0,0,0 )
            CtrlMove( oCtrl,0,1,.F. )
         ENDIF
      ELSEIF wParam == 38    // Up
         IF ( oCtrl := GetCtrlSelected( oDlg ) ) != Nil
            SetBDown( ,0,0,0 )
            CtrlMove( oCtrl,0,-1,.F. )
         ENDIF
      ELSEIF wParam == 39    // Right
         IF ( oCtrl := GetCtrlSelected( oDlg ) ) != Nil
            SetBDown( ,0,0,0 )
            CtrlMove( oCtrl,1,0,.F. )
         ENDIF
      ELSEIF wParam == 37    // Left
         IF ( oCtrl := GetCtrlSelected( oDlg ) ) != Nil
            SetBDown( ,0,0,0 )
            CtrlMove( oCtrl,-1,0,.F. )
         ENDIF
      ENDIF
   ENDIF

Return -1

Static Function MouseMove( oDlg, wParam, xPos, yPos )
Local aBDown, oCtrl, resizeDirection

   IF oDesigner:addItem != Nil
      Hwg_SetCursor( crossCursor )
   ELSE
      aBDown := GetBDown()
      IF aBDown[1] != Nil
         IF aBDown[4] > 0
            IF aBDown[4] == 1 .OR. aBDown[4] == 3
               Hwg_SetCursor( horzCursor )
            ELSEIF aBDown[4] == 2 .OR. aBDown[4] == 4
               Hwg_SetCursor( vertCursor )
            ENDIF            
            CtrlResize( aBDown[1],xPos,yPos )
         ELSE
            CtrlMove( aBDown[1],xPos,yPos,.T. )
         ENDIF
      ELSE
         IF ( oCtrl := GetCtrlSelected( oDlg ) ) != Nil
            IF ( resizeDirection := CheckResize( oCtrl,xPos,yPos ) ) == 1 .OR. resizeDirection == 3
               Hwg_SetCursor( horzCursor )
            ELSEIF resizeDirection == 2 .OR. resizeDirection == 4
               Hwg_SetCursor( vertCursor )
            ENDIF
         ENDIF
      ENDIF
   ENDIF

Return Nil

Static Function LButtonDown( oDlg, xPos, yPos )
Local oCtrl := GetCtrlSelected( oDlg ), resizeDirection, flag, i

   IF oDesigner:addItem != Nil
      Return Nil
   ENDIF
   IF oCtrl != Nil .AND. ;
        ( resizeDirection := CheckResize( oCtrl,xPos,yPos ) ) > 0
      IF resizeDirection == 1 .OR. resizeDirection == 3
         i := Ascan( oCtrl:aProp,{|a|Lower(a[1])=="height"} )
         IF i != 0 .AND. Len( oCtrl:aProp[i] ) == 3
            SetBDown( oCtrl,xPos,yPos,resizeDirection )
            Hwg_SetCursor( horzCursor )
         ENDIF
      ELSEIF resizeDirection == 2 .OR. resizeDirection == 4
         i := Ascan( oCtrl:aProp,{|a|Lower(a[1])=="width"} )
         IF i != 0 .AND. Len( oCtrl:aProp[i] ) == 3
            SetBDown( oCtrl,xPos,yPos,resizeDirection )
            Hwg_SetCursor( vertCursor )
         ENDIF
      ENDIF            
   ELSE
      IF ( oCtrl := CtrlByPos( oDlg,xPos,yPos ) ) != Nil
         IF oCtrl:Adjust == 0
            SetBDown( oCtrl,xPos,yPos,0 )
         ELSE
            SetCtrlSelected( oCtrl:oParent,oCtrl )
         ENDIF
      ELSEIF ( oCtrl := GetCtrlSelected( oDlg ) ) != Nil
         SetCtrlSelected( oDlg )
      ENDIF
   ENDIF
   IF oCtrl != Nil .AND. Lower( oCtrl:cClass ) == "page"
      i := Tab_HitTest( oCtrl:handle,,,@flag )
      IF i >= 0 .AND. flag == 4 .OR. flag == 6
         Page_Select( oCtrl, i+1 )
      ENDIF
   ENDIF

Return Nil

Static Function LButtonUp( oDlg, xPos, yPos )
Local aBDown, oCtrl, oContainer, i, nLeft, aProp, j, name

   IF oDesigner:addItem == Nil
      aBDown := GetBDown()
      oCtrl := aBDown[1]
      IF oCtrl != Nil
         IF aBDown[4] > 0
            CtrlResize( oCtrl,xPos,yPos )
         ELSE
            CtrlMove( oCtrl,xPos,yPos,.T. )
            Container( oDlg,oCtrl,xPos,yPos )
         ENDIF
         SetBDown( Nil,0,0,0 )
      ENDIF
   ELSE 
      oContainer := CtrlByPos( oDlg,xPos,yPos )
      IF oDesigner:addItem:classname() == "HCONTROLGEN"
         aProp := AClone( oDesigner:addItem:aProp )
         j := 0
         FOR i := Len( aProp ) TO 1 STEP -1
            IF ( name := Lower( aProp[i,1] ) ) == "name" .OR. name == "varname"
               Adel( aProp,i )
               j ++
            ELSEIF name == "left"
               aProp[i,2] := Ltrim(Str(xPos))
            ELSEIF name == "top"
               aProp[i,2] := Ltrim(Str(yPos))
            ENDIF
         NEXT
         IF j > 0
            Asize( aProp,Len(aProp)-j )
         ENDIF
         oCtrl := HControlGen():New( oDlg,oDesigner:addItem:oXMLDesc, aProp )
      ELSE
         oCtrl := HControlGen():New( oDlg,oDesigner:addItem, { { "Left",Ltrim(Str(xPos)) }, { "Top",Ltrim(Str(yPos)) } } )
      ENDIF
      IF oContainer != Nil .AND. ( ;
          oCtrl:nLeft+oCtrl:nWidth <= oContainer:nLeft+oContainer:nWidth .AND. ;
          oCtrl:nTop+oCtrl:nHeight <= oContainer:nTop+oContainer:nHeight )
         oContainer:AddControl( oCtrl )
         oCtrl:oContainer := oContainer
         IF Lower( oContainer:cClass ) == "page"
            oCtrl:nPage := GetCurrentTab( oContainer:handle )
            IF oCtrl:nPage == 0
               oCtrl:nPage ++
            ENDIF
         ENDIF
      ENDIF

      SetCtrlSelected( oDlg,oCtrl )
      oDlg:oParent:lChanged := .T.
      IF oDesigner:oBtnPressed != Nil
         oDesigner:oBtnPressed:Release()
      ENDIF
      oDesigner:addItem := Nil
      IF IsCheckedMenuItem( oDesigner:oMainWnd:handle,1011 )
         AdjustCtrl( oCtrl )
      ENDIF
   ENDIF

Return -1

Static Function RButtonUp( oDlg, xPos, yPos )
Local oCtrl

   IF oDesigner:addItem == Nil
      IF ( oCtrl := CtrlByPos( oDlg,xPos,yPos ) ) != Nil
         SetCtrlSelected( oDlg,oCtrl )
         IF Lower( oCtrl:cClass ) == "page"
            oDesigner:oTabMenu:Show( oDlg,xPos,yPos,.T. )
         ELSE
            oDesigner:oCtrlMenu:Show( oDlg,xPos,yPos,.T. )
         ENDIF
      ENDIF
   ENDIF

Return Nil

Function Container( oDlg,oCtrl,xPos,yPos )
Local i, nLeft := oCtrl:nLeft

   oCtrl:nLeft := 9999
   oContainer := CtrlByPos( oDlg,xPos,yPos )
   IF oContainer != Nil .AND. ( ;
       nLeft+oCtrl:nWidth > oContainer:nLeft+oContainer:nWidth .OR. ;
       oCtrl:nTop+oCtrl:nHeight > oContainer:nTop+oContainer:nHeight )
      oContainer := Nil
   ENDIF
   IF oCtrl:oContainer != Nil .AND. ( oContainer == Nil .OR. ;
          oCtrl:oContainer:handle != oContainer:handle )
      i := Ascan( oCtrl:oContainer:aControls,{|o|o:handle==oCtrl:handle} )
      IF i != 0
         Adel( oCtrl:oContainer:aControls,i )
         Asize( oCtrl:oContainer:aControls,Len(oCtrl:oContainer:aControls)-1 )
      ENDIF
      oCtrl:oContainer := Nil
   ENDIF
   IF oContainer != Nil .AND. oCtrl:oContainer == Nil
      oContainer:AddControl( oCtrl )
      oCtrl:oContainer := oContainer
      IF Lower( oContainer:cClass ) == "page"
         oCtrl:nPage := GetCurrentTab( oContainer:handle )
         IF oCtrl:nPage == 0
            oCtrl:nPage ++
         ENDIF
      ENDIF
      IF ( i := Ascan( oDlg:aControls,{|o|o:handle==oCtrl:handle} ) ) ;
         < Ascan( oDlg:aControls,{|o|o:handle==oContainer:handle} )
         DestroyWindow( oCtrl:handle )
         aDel( oDlg:aControls,i )
         oDlg:aControls[Len(oDlg:aControls)] := oCtrl
         oCtrl:nLeft := nLeft
         oCtrl:lInit := .F.
         oCtrl:Activate()
      ENDIF
   ENDIF
   oCtrl:nLeft := nLeft

Return Nil

Static Function CtrlByPos( oDlg,xPos,yPos )
Local i := 1, aControls := oDlg:aControls, alen := Len( aControls )
Local oCtrl

   DO WHILE i <= alen
     IF !aControls[i]:lHide .AND. xPos >= aControls[i]:nLeft .AND. ;
           xPos < ( aControls[i]:nLeft+aControls[i]:nWidth ) .AND. ;
           yPos >= aControls[i]:nTop .AND.                         ;
           yPos < ( aControls[i]:nTop+aControls[i]:nHeight )
        oCtrl := aControls[i]
        aControls := oCtrl:aControls
        i := 0
        alen := Len( aControls )
     ENDIF
     i ++
   ENDDO
Return oCtrl

Static Function FrmSort( aControls,lSub )
Local i, nLeft, nTop, lSorted := .T., aTabs

   FOR i := 1 TO Len( aControls )
      IF i > 1 .AND. aControls[i]:nTop*10000+aControls[i]:nLeft < nTop*10000+nLeft
         lSorted := .F.
         EXIT
      ENDIF
      nLeft := aControls[i]:nLeft
      nTop  := aControls[i]:nTop
   NEXT

   IF !lSorted .AND. ( lSub == Nil .OR. !lSub )
      FOR i := Len( aControls ) TO 1 STEP -1
         DestroyWindow( aControls[i]:handle )
      NEXT
   ENDIF
   IF !lSorted
      Asort( aControls,,, {|z,y| z:nTop*10000+z:nLeft < y:nTop*10000+y:nLeft } )
   ENDIF
   FOR i := 1 TO Len( aControls )
      IF !Empty( aControls[i]:aControls )
         FrmSort( aControls[i]:aControls,.T. )
      ENDIF
   NEXT
   IF !lSorted .AND. ( lSub == Nil .OR. !lSub )
      FOR i := 1 TO Len( aControls )
         aControls[i]:lInit := .F.
         aControls[i]:Activate()
         aControls[i]:lHide := .F.
      NEXT
      FOR i := 1 TO Len( aControls )
         IF Lower( aControls[i]:cClass ) == "page" .AND. ;
                   ( aTabs := aControls[i]:GetProp("Tabs") ) != Nil .AND. ;
                   !Empty( aTabs )
            Page_Upd( aControls[i], aTabs )
            Page_Select( aControls[i], 1, .T. )
         ENDIF
      NEXT
   ENDIF
Return Nil

Function _CHR( n )
Return CHR( n )

