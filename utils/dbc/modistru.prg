/*
 * $Id$
 * DBCHW - DBC ( Harbour + HWGUI )
 * Database structure handling
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "dbchw.h"
#ifdef RDD_ADS
#include "ads.ch"
#endif

MEMVAR improc, aFiles, nServerType, oMainFont

STATIC aFieldTypes := { "C", "N", "D", "L" }

FUNCTION StruMan( lNew )
   LOCAL oDlg, oBrowse, oMsg, oBrw
   LOCAL oGet1, oGet2, oGet3, oGet4
   LOCAL af, af0, cName := "", nType := 1, cLen := "0", cDec := "0", i, lCanModif
   LOCAL aTypes := { "Character", "Numeric", "Date", "Logical" }
   LOCAL fname, cAlias, nRec, nOrd, lOverFlow := .F. , xValue
   LOCAL currentCP, currFname
   LOCAL bChgPos := {|o|
      oGet1:SetGet( o:aArray[o:nCurrent,1] )
      oGet2:SetItem( Ascan( aFieldTypes,o:aArray[o:nCurrent,2] ) )
      oGet3:SetGet( LTrim( Str(o:aArray[o:nCurrent,3] ) ) )
      oGet4:SetGet( LTrim( Str(o:aArray[o:nCurrent,4] ) ) )
      hwg_RefreshAllGets( oDlg )
      RETURN Nil
   }

   IF lNew
      af := { { "","",0,0 } }
   ELSE
      currentCP := aFiles[improc,AF_CP]
      currFname := CutExten( aFiles[improc,AF_NAME] )
      oBrw := GetBrwActive()
      af0 := dbStruct()
      af  := dbStruct()
      FOR i := 1 TO Len( af )
         AAdd( af[i], i )
      NEXT
   ENDIF
   lCanModif := ( !lNew .AND. aFiles[improc,AF_EXCLU] .AND. !aFiles[improc,AF_RDONLY] .AND. aFiles[improc,AF_LOCAL] )

   INIT DIALOG oDlg TITLE iif( lCanModif, "Modify", "View" ) + " structure" ;
      AT 0, 0  SIZE 460, 330  FONT oMainFont

   @ 20, 20 BROWSE oBrowse ARRAY SIZE 308, 190 ;
      STYLE WS_BORDER + WS_VSCROLL ON POSCHANGE bChgPos

   oBrowse:aHeadPadding := { 4, 2, 4, 2 }
   oBrowse:oStyleHead := HStyle():New( { 0xffffff, 0xbbbbbb }, 1 )
   oBrowse:aArray := af
   oBrowse:AddColumn( HColumn():New( "",{ |v,o| (v), o:nCurrent },"N",4,0 ) )
   oBrowse:AddColumn( HColumn():New( "Name",{ |v,o| (v), o:aArray[o:nCurrent,1] },"C",14,0 ) )
   oBrowse:AddColumn( HColumn():New( "Type",{ |v,o| (v), o:aArray[o:nCurrent,2] },"C",1,0 ) )
   oBrowse:AddColumn( HColumn():New( "Length",{ |v,o| (v), o:aArray[o:nCurrent,3] },"N",5,0 ) )
   oBrowse:AddColumn( HColumn():New( "Dec",{ |v,o| (v), o:aArray[o:nCurrent,4] },"N",2,0 ) )

   @ 20, 230 GET oGet1 VAR cName SIZE 100, 24 PICTURE "XXXXXXXXXX"
   @ 130, 230 GET COMBOBOX oGet2 VAR nType ITEMS aTypes SIZE 100, 24
   @ 240, 230 GET oGet3 VAR cLen SIZE 50, 24 PICTURE "9999"
   @ 300, 230 GET oGet4 VAR cDec SIZE 40, 24 PICTURE "99"

   IF ( lNew .AND. nServerType == LOCAL_SERVER ) .OR. lCanModif

      @ 28, 270 BUTTON "Add" SIZE 80, 30 ON CLICK { ||UpdStru( oBrowse, oGet1, oGet2, oGet3, oGet4, 1 ) }
      @ 136, 270 BUTTON "Insert" SIZE 80, 30 ON CLICK { ||UpdStru( oBrowse, oGet1, oGet2, oGet3, oGet4, 2 ) }
      @ 246, 270 BUTTON "Replace" SIZE 80, 30 ON CLICK { ||UpdStru( oBrowse, oGet1, oGet2, oGet3, oGet4, 3 ) }
      @ 356, 270 BUTTON "Remove" SIZE 80, 30 ON CLICK { ||UpdStru( oBrowse, oGet1, oGet2, oGet3, oGet4, 4 ) }

      @ 344, 40 BUTTON iif( lNew, "Create", "Modify" ) SIZE 100, 40 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   ELSEIF !lCanModif
      @ 28, 270 SAY "Open file in exclusive mode to modify it!" SIZE 360, 24
   ENDIF
   @ 344, 100 BUTTON "Close" SIZE 100, 40 ON CLICK { ||hwg_EndDialog() }

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult

      oMsg = DlgWait( "Restructuring" )
      IF lNew
         CLOSE ALL
         fname := hwg_MsgGet( "File creation", "Input new file name" )
         IF Empty( fname )
            RETURN Nil
         ENDIF
         dbCreate( fname, af )
         OpenDbf( fname )
      ELSE
         cAlias := Alias()
         nOrd := OrdNumber()
         nRec := RecNo()
         SET ORDER TO 0
         GO TOP

         fname := "a0_new"
         dbCreate( fname, af )
         IF currentCP != Nil
            USE ( fname ) NEW codepage ( currentCP )
         ELSE
            USE ( fname ) new
         ENDIF
         dbSelectArea( cAlias )

         DO WHILE !Eof()
            dbSelectArea( fname )
            APPEND BLANK
            FOR i := 1 TO Len( af )
               IF Len( af[i] ) > 4
                  xValue := ( cAlias ) -> ( FieldGet( af[i,5] ) )
                  IF af[i,2] == af0[af[i,5], 2] .AND. af[i,3] == af0[af[i,5], 3]
                     FieldPut( i, xValue )
                  ELSE
                     IF af[i,2] != af0[af[i,5], 2]
                        IF af[i,2] == "C" .AND. af0[af[i,5], 2] == "N"
                           xValue := Str( xValue, af0[af[i,5], 3], af0[af[i,5], 4] )
                        ELSEIF af[i,2] == "N" .AND. af0[af[i,5], 2] == "C"
                           xValue := Val( LTrim( xValue ) )
                        ELSE
                           LOOP
                        ENDIF
                     ENDIF
                     IF af[i,3] >= af0[af[i,5], 3]
                        FieldPut( i, xValue )
                     ELSE
                        IF af[i,2] == "C"
                           FieldPut( i, Left( xValue,af[i,3] ) )
                        ELSEIF af[i,2] == "N"
                           FieldPut( i, 0 )
                           lOverFlow := .T.
                        ENDIF
                     ENDIF
                  ENDIF
               ENDIF
            NEXT
            IF ( cAlias ) -> ( Deleted() )
               DELETE
            ENDIF
            dbSelectArea( cAlias )
            SKIP
         ENDDO
         IF lOverFlow
            hwg_Msginfo( "There was overflow in Numeric field", "Warning!" )
         ENDIF

         CLOSE ALL
         FErase( currFname + ".bak" )
         FRename( currFname + ".dbf", currFname + ".bak" )
         FRename( "a0_new.dbf", currFname + ".dbf" )
         IF File( "a0_new.fpt" )
            FRename( "a0_new.fpt", currFname + ".fpt" )
         ENDIF

         USE ( currFname )
         REINDEX

         GO nRec
         SET ORDER TO nOrd
         hwg_CreateList( oBrw, .T. )
         oBrw:Refresh()
      ENDIF
      oMsg:Close()

   ENDIF

   RETURN Nil

STATIC FUNCTION UpdStru( oBrowse, oGet1, oGet2, oGet3, oGet4, nOperation )
   LOCAL cName, cType, nLen, nDec

   IF nOperation == 4
      IF oBrowse:nRecords > 1
         ADel( oBrowse:aArray, oBrowse:nCurrent )
         oBrowse:aArray := ASize( oBrowse:aArray, Len( oBrowse:aArray ) - 1 )
         IF oBrowse:nCurrent < Len( oBrowse:aArray ) .AND. oBrowse:nCurrent > 1
            oBrowse:nCurrent --
            oBrowse:RowPos --
         ENDIF
         oBrowse:nRecords --
      ENDIF
   ELSE
      IF Empty( cName := oGet1:SetGet() )
         RETURN Nil
      ENDIF
      cType := aFieldTypes[ Eval(oGet2:bSetGet,,oGet2) ]
      nLen  := Val( oGet3:SetGet() )
      nDec  := Val( oGet4:SetGet() )
      IF oBrowse:nRecords == 1 .AND. Empty( oBrowse:aArray[oBrowse:nCurrent,1] )
         nOperation := 3
      ENDIF
      IF nOperation == 1
         AAdd( oBrowse:aArray, { cName, cType, nLen, nDec } )
      ELSE
         IF nOperation == 2
            AAdd( oBrowse:aArray, Nil )
            AIns( oBrowse:aArray, oBrowse:nCurrent )
            oBrowse:aArray[oBrowse:nCurrent] := { "", "", 0, 0 }
         ENDIF
         oBrowse:aArray[oBrowse:nCurrent,1] := cName
         oBrowse:aArray[oBrowse:nCurrent,2] := cType
         oBrowse:aArray[oBrowse:nCurrent,3] := nLen
         oBrowse:aArray[oBrowse:nCurrent,4] := nDec
      ENDIF
   ENDIF
   oBrowse:Refresh()

   RETURN Nil
