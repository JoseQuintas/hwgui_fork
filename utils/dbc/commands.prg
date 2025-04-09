/*
 * $Id$
 * DBCHW - DBC ( Harbour + HWGUI )
 * Commands ( Replace, delete, ... )
 *
 * Copyright 2001-2014 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "fileio.ch"
#include "hwgui.ch"
#include "dbchw.h"

Memvar improc, nServerType, cServerPath, cDataCPage, aFiles, oMainFont, aDateF, mypath

   /* -----------------------  Replace --------------------- */

FUNCTION C_REPL
   LOCAL oDlg, oMsg, nRec
   LOCAL af := Array( FCount() ), nField := 0
   LOCAL cVal := "", xVal, r1 := 1, nNext := 0, cFor := "", bFor
   LOCAL oBrw := GetBrwActive()

   AFields( af )
   improc := oBrw:cargo[1]

   IF aFiles[ improc, AF_RDONLY ]
      hwg_Msgstop( "File is opened in readonly mode" )
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg TITLE aFiles[improc,AF_ALIAS]+": Replace" ;
      AT 0, 0         ;
      SIZE 320, 250   ;
      FONT oMainFont

   @ 10,10 GET COMBOBOX nField ITEMS af SIZE 120, 150

   @ 140,10 GROUPBOX "" SIZE 160, 80
   GET RADIOGROUP r1
   @ 150,24 RADIOBUTTON "All" SIZE 60, 20
   @ 150,44 RADIOBUTTON "Next" SIZE 60, 20
   @ 150,64 RADIOBUTTON "Rest" SIZE 60, 20
   END RADIOGROUP
   @ 210,44 GET nNext SIZE 50, 24 PICTURE "9999"

   @ 10, 80 SAY "with value: " SIZE 100, 22
   @ 10, 104 GET cVal SIZE 300, 24
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 10, 130 SAY "For: " SIZE 100, 22
   @ 10, 154 GET cFor SIZE 300, 24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @  30, 210  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 190, 210 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   oDlg:Activate()

   IF oDlg:lResult
      IF !Empty( cFor ) .AND. Type( cFor ) != "L"
         hwg_Msgstop( "Wrong expression!" )
      ELSE
         IF !Empty( cFor )
            bFor := &( "{||" + cFor + "}" )
         ENDIF
         nrec := RecNo()
         oMsg := DlgWait( "Replacing" )

         xVal := &cVal
         IF r1 == 1
            Eval( oBrw:bGoTop, oBrw )
         ENDIF
         DO WHILE !Eval( oBrw:bEof, oBrw ) .AND. Iif( r1==2, nNext-- > 0, .T. )
            IF Empty( cFor ) .OR. Eval( bFor )
               IF !aFiles[improc,AF_EXCLU]
                  rlock()
               ENDIF
               Fieldput( nField, xVal )
               IF !aFiles[improc,AF_EXCLU]
                  UNLOCK
               ENDIF
            ENDIF
            Eval( oBrw:bSkip, oBrw, 1 )
         ENDDO

         GO nrec
         oMsg:Close()
         UpdBrowse()
      ENDIF
   ENDIF

   RETURN Nil


   /* -----------------------  Delete, recall, count --------------------- */

FUNCTION C_4( nAct )
   LOCAL oDlg, aTitle := { "Delete", "Recall", "Count", "Sum" }
   LOCAL cExpr := "", r1 := 1, nNext := 1, cFor := "", bFor, bSum
   LOCAL oBrw := GetBrwActive(), nCount := 0, nRec, oMsg

   INIT DIALOG oDlg TITLE aTitle[nAct] ;
      AT 0, 0         ;
      SIZE 320, 250   ;
      FONT oMainFont

   IF nAct <= 2 .AND. aFiles[ improc, AF_RDONLY ]
      hwg_Msgstop( "File is opened in readonly mode" )
      RETURN Nil
   ENDIF

   IF nAct == 4
      @ 10, 10 SAY "Sum: " SIZE 40, 22
      @ 50, 10 GET cExpr SIZE 260, 24
      Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS
   ENDIF

   @ 20,40 GROUPBOX "" SIZE 160, 80
   GET RADIOGROUP r1
   @ 30,50 RADIOBUTTON "All" SIZE 60, 20
   @ 30,70 RADIOBUTTON "Next" SIZE 60, 20
   @ 30,90 RADIOBUTTON "Rest" SIZE 60, 20
   END RADIOGROUP
   @ 96,70 GET nNext SIZE 50, 24 PICTURE "9999"

   @ 10, 130 SAY "For: " SIZE 60, 22
   @ 10, 152 GET cFor SIZE 300, 24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @  30, 210  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 190, 210 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   oDlg:Activate()

   IF oDlg:lResult

      IF !Empty( cFor ) .AND. Type( cFor ) != "L"
         hwg_Msgstop( "Wrong 'FOR' expression!" )
         RETURN Nil
      ENDIF
      IF nAct == 4
         IF Empty( cExpr ) .AND. Type( cExpr ) != "N"
            hwg_Msgstop( "Wrong 'SUM' expression!" )
            RETURN Nil
         ELSE
            bSum := &( "{||" + cExpr + "}" )
         ENDIF
      ENDIF

      IF !Empty( cFor )
         bFor := &( "{||" + cFor + "}" )
      ENDIF
      nrec := RecNo()
      oMsg := DlgWait( aTitle[nAct] )

      IF r1 == 1
         Eval( oBrw:bGoTop, oBrw )
      ENDIF
      DO WHILE !Eval( oBrw:bEof, oBrw ) .AND. Iif( r1==2, nNext-- > 0, .T. )
         IF Empty( cFor ) .OR. Eval( bFor )
            IF nAct == 1
               IF !aFiles[improc,AF_EXCLU]
                  rlock()
               ENDIF
               DELETE
               IF !aFiles[improc,AF_EXCLU]
                  UNLOCK
               ENDIF
            ELSEIF nAct == 2
               IF !aFiles[improc,AF_EXCLU]
                  rlock()
               ENDIF
               RECALL
               IF !aFiles[improc,AF_EXCLU]
                  UNLOCK
               ENDIF
            ELSEIF nAct == 3
               nCount ++
            ELSEIF nAct == 4
               nCount += Eval( bSum )
            ENDIF
         ENDIF
         Eval( oBrw:bSkip, oBrw, 1 )
      ENDDO

      GO nrec
      oMsg:Close()
      IF nAct > 2
         hwg_MsgInfo( Ltrim(Str(nCount)), "Result" )
      ELSE
         UpdBrowse()
      ENDIF
   ENDIF

   RETURN Nil

   /* -----------------------  Append from --------------------- */

#define STR_BUFLEN  4096

FUNCTION C_APPEND()
   LOCAL oDlg, oMsg, cFile := "", cFields := "", cFor := ""
   LOCAL cDelim := " ", cDelim2 := ",", cQuo := '"', nDf := 1, oDelim, oDelim2, oQuo, oDf
   LOCAL r1 := 1, bFor, af, cPath := cServerPath
   LOCAL i, j, aFie, xVal, arr, s, nOverf := 0, oldDf
   LOCAL han, stroka, strbuf := Space(STR_BUFLEN), poz := STR_BUFLEN+1
#ifdef RDD_ADS
   LOCAL lRemote := (nServerType == 6)
#else
   LOCAL lRemote := (nServerType == REMOTE_SERVER)
#endif
   LOCAL oBrw := GetBrwActive()
   Local oBtnFile
   LOCAL bBtnDis := {||
      Iif(lRemote,oBtnFile:Disable(),oBtnFile:Enable())
      oDelim:Hide()
      oDelim2:Hide()
      oQuo:Hide()
      oDf:Hide()
      RETURN .T.
   }
   LOCAL bFileBtn := {||
#ifdef __GTK__
   cFile := hwg_SelectFileEx( ,, { { "All files", "*" } } )
#else
   cFile := hwg_Selectfile( "*.*", "*.*", hb_curDrive()+":\"+Curdir() )
#endif
   hwg_RefreshAllGets( oDlg )
   Return .T.
   }

   IF aFiles[ improc, AF_RDONLY ]
      hwg_Msgstop( "File is opened in readonly mode" )
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg TITLE aFiles[improc,AF_ALIAS]+": Append" ;
      AT 0, 0 SIZE 400, 400   ;
      FONT oMainFont ON INIT bBtnDis

#if defined( RDD_ADS ) .OR. defined( RDD_LETO )
   @ 10,10 SAY "Server " SIZE 60,22 STYLE SS_RIGHT
   @ 70,10 GET CHECKBOX lRemote CAPTION "Remote:" SIZE 80, 20 ON CLICK bBtnDis
   @ 150,10 GET cPath SIZE 240,24
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS
#endif

   @ 10,34 SAY "File name: " SIZE 80,22 STYLE SS_RIGHT
   @ 90,34 GET cFile SIZE 220,24 PICTURE "@S128" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS
   @ 310,34 BUTTON oBtnFile CAPTION "Browse" SIZE 80, 26 ON CLICK bFileBtn ON SIZE ANCHOR_RIGHTABS

   @ 10,60 SAY "Fields: " SIZE 80,22 STYLE SS_RIGHT
   @ 90,60 GET cFields SIZE 220,24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS

   @ 10, 92 GROUPBOX "" SIZE 168, 172
   GET RADIOGROUP r1
   @ 20,104 RADIOBUTTON "Dbf" SIZE 90, 20
   @ 20,128 RADIOBUTTON "Sdf" SIZE 90, 20
   @ 20,152 RADIOBUTTON "Delimited with" SIZE 112, 20 ON CLICK {||oDelim:Show()}
   @ 20,176 RADIOBUTTON "Csv" SIZE 50, 20 ON CLICK {||oDelim2:Show(),oQuo:Show(),oDf:Show()}
   END RADIOGROUP
   @ 136,152 GET oDelim VAR cDelim SIZE 28, 24 PICTURE "XX"
   @ 70, 176 SAY "quote:" SIZE 72,24 STYLE SS_RIGHT
   @ 142,176 GET oQuo VAR cQuo SIZE 24, 24 PICTURE "X"
   @ 40, 200 SAY "delimiter:" SIZE 102,24 STYLE SS_RIGHT
   @ 142,200 GET oDelim2 VAR cDelim2 SIZE 24, 24 PICTURE "X"
   @ 24,224 GET COMBOBOX oDf VAr nDf ITEMS aDateF SIZE 140,24 DISPLAYCOUNT 5

   @ 10, 280 SAY "For: " SIZE 100, 22
   @ 10, 302 GET cFor SIZE 380, 24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @  30, 348  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 190, 348 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   ACTIVATE DIALOG oDlg CENTER

   IF oDlg:lResult

      IF Empty( cFile )
         hwg_Msgstop( "File name is absent" )
         RETURN Nil
      ENDIF
      IF !Empty( cFor ) .AND. Type( cFor ) != "L"
         hwg_Msgstop( "Wrong 'FOR' expression!" )
         RETURN Nil
      ENDIF
      IF !Empty( cFor )
         bFor := &( "{||" + cFor + "}" )
      ENDIF
      IF !Empty( cFields )
         af := hb_aTokens( Trim(cFields), "," )
      ENDIF

      oMsg := DlgWait( "Append" )
      cFile := Iif( lRemote.AND.r1==1, Trim( cPath ), "" ) + Trim( cFile )
      IF r1 == 1
#ifdef RDD_ADS
         AdsSetServerType( nServerType := Iif( lRemote, 6, ADS_LOCAL_SERVER ) )
         __dbApp( cFile, af, bfor,,,, .F. )
#else
         __dbApp( cFile, af, bfor,,,, .F., Iif( lRemote,"LETO","DBFCDX" ),, cDataCPage )
#endif
      ELSEIF r1 == 2
         __dbSdf( .F., cFile, af, bfor,,,, .F. )
      ELSEIF r1 == 3
         __dbDelim( .F., cFile, Iif( Empty(cdelim), "blank", Trim(cdelim) ), af, bfor,,,, .F. )
      ELSE
         aFie := dbStruct()
         IF Empty( af )
            af := Array( Len( aFie ) )
            FOR i := 1 TO Len( af )
               af[i] := i
            NEXT
         ELSE
            FOR i := 1 TO Len( af )
               af[i] := Ascan( aFie, {|a|Upper(a[1])==Upper(af[i])} )
            NEXT
         ENDIF
         IF ( han := FOpen( cFile, FO_READ + FO_SHARED ) ) != -1
            j := 0
            oldDf := Set( _SET_DATEFORMAT, aDatef[nDf] )
            DO WHILE .T.
               s := RdStr( han, @strbuf, @poz, STR_BUFLEN )
               IF Empty( s )
                  EXIT
               ELSE
                  IF j % 2 == 1
                     stroka += s
                  ELSE
                     stroka := s
                  ENDIF
                  i := 1; j := 0
                  DO WHILE ( i := hb_At( cQuo,stroka,i ) ) != 0
                     i ++; j ++
                  ENDDO
                  IF j % 2 == 0
                     arr := hb_aTokens( stroka, cDelim2, .T. )
                     APPEND BLANK
                     FOR i := 1 TO Len(arr)
                        IF i <= Len( af )
                           xVal := arr[i]
                           IF Left( xVal,1 ) == cQuo
                              xVal := Substr( xVal, 2, Len(xVal)-2 )
                           ENDIF
                           IF cQuo+cQuo $ arr[i]
                              xVal := Strtran( xVal, cQuo+cQuo, cQuo )
                           ENDIF
                           IF aFie[af[i],2] == "N"
                              IF Len( xVal ) > aFie[af[i],3]
                                 IF nOverf == 0
                                    IF hwg_MsgYesNo( "Numeric field overflow! Continue?", "Warning" )
                                       nOverf := 1
                                    ELSE
                                       nOverf := 2
                                       EXIT
                                    ENDIF
                                 ENDIF
                                 IF nOverf == 0
                                    xVal := "0"
                                 ENDIF
                              ENDIF
                              FieldPut( af[i], Val(xVal) )
                           ELSEIF aFie[af[i],2] == "D"
                              FieldPut( af[i], Ctod(xVal) )
                           ELSEIF aFie[af[i],2] == "L"
                              FieldPut( af[i], ( xVal="T" ) )
                           ELSEIF aFie[af[i],2] == "C"
                              FieldPut( af[i], Left( xVal, aFie[af[i],3] ) )
                           ELSEIF aFie[af[i],2] == "M"
                              FieldPut( af[i], xVal )
                           ENDIF
                        ENDIF
                     NEXT
                     IF nOverf == 2
                        EXIT
                     ENDIF
                  ENDIF
               ENDIF
            ENDDO
            Set( _SET_DATEFORMAT, oldDf )
            FClose( han )
         ENDIF
      ENDIF
      oMsg:Close()
      UpdBrowse()
   ENDIF

   RETURN Nil

FUNCTION C_COPY()
   LOCAL oDlg, oMsg, cFile := "", cFields := "", cFor := ""
   LOCAL cDelim := " ", cDelim2 := ",", nNext := 0, cQuo := '"', nDf := 1, oDelim, oDelim2, oNext, oQuo, oDf
   LOCAL r1 := 1, r2 := 1, bFor, af, cPath := cServerPath
   LOCAL i, aFie, han, s, xVal, l, oldDf
#ifdef RDD_ADS
   LOCAL lRemote := (nServerType == 6)
#else
   LOCAL lRemote := (nServerType == REMOTE_SERVER)
#endif
   LOCAL oBtnFile
   LOCAL bBtnDis := {||
      Iif(lRemote,oBtnFile:Disable(),oBtnFile:Enable())
      oDelim:Hide()
      oDelim2:Hide()
      oQuo:Hide()
      oDf:Hide()
      oNext:Hide()
      RETURN .T.
   }
   LOCAL bFileBtn := {||
#ifdef __GTK__
   cFile := hwg_SelectFileEx( ,, { { "All files", "*" } } )
#else
   cFile := hwg_Savefile( "*.*","*.*", "*.dbf", mypath )
#endif
   hwg_RefreshAllGets( oDlg )
   Return .T.
   }

   INIT DIALOG oDlg TITLE aFiles[improc,AF_ALIAS]+": Copy" ;
      AT 0, 0 SIZE 400, 400 FONT oMainFont ON INIT bBtnDis

#if defined( RDD_ADS ) .OR. defined( RDD_LETO )
   @ 10,10 SAY "Server " SIZE 60,22 STYLE SS_RIGHT
   @ 70,10 GET CHECKBOX lRemote CAPTION "Remote:" SIZE 80, 20 ON CLICK bBtnDis
   @ 150,10 GET cPath SIZE 240,24
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS
#endif

   @ 10,34 SAY "File name: " SIZE 80,22 STYLE SS_RIGHT
   @ 90,34 GET cFile SIZE 220,24 PICTURE "@S128" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS
   @ 310,34 BUTTON oBtnFile CAPTION "Browse" SIZE 80, 26 ON CLICK bFileBtn ON SIZE ANCHOR_RIGHTABS

   @ 10,60 SAY "Fields: " SIZE 80,22 STYLE SS_RIGHT
   @ 90,60 GET cFields SIZE 220,24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS

   @ 10, 92 GROUPBOX "" SIZE 168, 172
   GET RADIOGROUP r1
   @ 20,104 RADIOBUTTON "Dbf" SIZE 90, 20
   @ 20,128 RADIOBUTTON "Sdf" SIZE 90, 20
   @ 20,152 RADIOBUTTON "Delimited with" SIZE 112, 20 ON CLICK {||oDelim:Show()}
   @ 20,176 RADIOBUTTON "Csv" SIZE 50, 20 ON CLICK {||oDelim2:Show(),oQuo:Show(),oDf:Show()}
   END RADIOGROUP
   @ 136,152 GET oDelim VAR cDelim SIZE 28, 24 PICTURE "XX"
   @ 70, 176 SAY "quote:" SIZE 72,24 STYLE SS_RIGHT
   @ 142,176 GET oQuo VAR cQuo SIZE 24, 24 PICTURE "X"
   @ 40, 200 SAY "delimiter:" SIZE 102,24 STYLE SS_RIGHT
   @ 142,200 GET oDelim2 VAR cDelim2 SIZE 24, 24 PICTURE "X"
   @ 24,224 GET COMBOBOX oDf VAr nDf ITEMS aDateF SIZE 140,24 DISPLAYCOUNT 5

   @ 200, 92 GROUPBOX "" SIZE 168, 88
   GET RADIOGROUP r2
   @ 210,104 RADIOBUTTON "All" SIZE 90, 20
   @ 210,128 RADIOBUTTON "Next" SIZE 90, 20 ON CLICK {||oNext:Show()}
   @ 210,152 RADIOBUTTON "Rest" SIZE 90, 20
   END RADIOGROUP
   @ 300,128 GET oNext VAR nNext SIZE 40, 24 PICTURE "9999"

   @ 10, 280 SAY "For: " SIZE 100, 22
   @ 10, 302 GET cFor SIZE 380, 24 PICTURE "@S256" STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @  50, 348  BUTTON "Ok" SIZE 100, 32 ON CLICK { ||oDlg:lResult := .T. , hwg_EndDialog() }
   @ 250, 348 BUTTON "Cancel" SIZE 100, 32 ON CLICK { ||hwg_EndDialog() }

   ACTIVATE DIALOG oDlg CENTER

   IF oDlg:lResult

      IF Empty( cFile )
         hwg_Msgstop( "File name is absent" )
         RETURN Nil
      ENDIF
      IF !Empty( cFor ) .AND. Type( cFor ) != "L"
         hwg_Msgstop( "Wrong 'FOR' expression!" )
         RETURN Nil
      ENDIF
      IF !Empty( cFor )
         bFor := &( "{||" + cFor + "}" )
      ENDIF
      IF !Empty( cFields )
         af := hb_aTokens( Trim(cFields), "," )
      ENDIF

      oMsg := DlgWait( "Append" )
      cFile := Iif( lRemote.AND.r1==1, Trim( cPath ), "" ) + Trim( cFile )
      IF r1 == 1 .AND. r2 == 1
#ifdef RDD_ADS
          AdsSetServerType( nServerType := Iif( lRemote, 6, ADS_LOCAL_SERVER ) )
         __dbApp( cFile, af, bfor,,,, .F. )
#else
         __dbCopy( cFile, af, bFor,,,, .F., Iif( lRemote,"LETO","DBFCDX" ),, cDataCPage )
#endif
      ELSEIF r1 == 1 .AND. r2 == 2
#ifdef RDD_ADS
          AdsSetServerType( nServerType := Iif( lRemote, 6, ADS_LOCAL_SERVER ) )
         __dbCopy( cFile, af, bFor,, nNext,, .F. )
#else
         __dbCopy( cFile, af, bFor,, nNext,, .F., Iif( lRemote,"LETO","DBFCDX" ),, cDataCPage )
#endif
      ELSEIF r1 == 1 .AND. r2 == 3
#ifdef RDD_ADS
          AdsSetServerType( nServerType := Iif( lRemote, 6, ADS_LOCAL_SERVER ) )
         __dbCopy( cFile, af, bFor,,,, .T. )
#else
         __dbCopy( cFile, af, bFor,,,, .T., Iif( lRemote,"LETO","DBFCDX" ),, cDataCPage )
#endif
      ELSEIF r1 == 2 .AND. r2 == 1
         __dbSdf( .T., cFile, af, bFor,,,, .F. )
      ELSEIF r1 == 2 .AND. r2 == 2
         __dbSdf( .T., cFile, af, bFor,, nNext,, .F. )
      ELSEIF r1 == 2 .AND. r2 == 3
         __dbSdf( .T., cFile, af, bFor,,,, .T. )
      ELSEIF r1 == 3 .AND. r2 == 1
         __dbDelim( .T., cFile, Iif( Empty(cdelim), "blank", cdelim ), af, bFor,,,, .F. )
      ELSEIF r1 == 3 .AND. r2 == 2
         __dbDelim( .T., cFile, Iif( Empty(cdelim), "blank", cdelim ), af, bFor,, nNext,, .F. )
      ELSEIF r1 == 3 .AND. r2 == 3
         __dbDelim( .T., cFile, Iif( Empty(cdelim), "blank", cdelim ), af, bFor,,,, .T. )
      ELSEIF r1 == 4
         han := FCreate( cFile )
         aFie := dbStruct()
         IF Empty( af )
            af := Array( Len( aFie ) )
            FOR i := 1 TO Len( af )
               af[i] := i
            NEXT
         ELSE
            FOR i := 1 TO Len( af )
               af[i] := Ascan( aFie, {|a|Upper(a[1])==Upper(af[i])} )
            NEXT
         ENDIF
         IF r2 == 1
            GO TOP
         ENDIF
         oldDf := Set( _SET_DATEFORMAT, aDatef[nDf] )
         DO WHILE !Eof()
            IF Empty( bFor ) .OR. Eval( bFor )
               s := ""
               FOR i := 1 TO Len( af )
                  xVal := FieldGet( af[i] )
                  xVal := Iif( aFie[i,2]=="N", Ltrim(Str(xval)), ;
                     Iif( aFie[i,2]=="D", Dtoc(xVal),;
                     Iif( aFie[i,2]=="L", Iif(xVal,"T","F"), Trim(xVal) ) ) )
                  IF ( i==Len(af).AND.Empty(xVal) ) .OR. ( l := (cQuo $ xVal) ) ;
                        .OR. cDelim2 $ xVal .OR. Chr(13)+Chr(10) $ xVal
                     IF l
                        xVal := Strtran( xVal, cQuo, cQuo+cQuo )
                     ENDIF
                     s += Iif( i>1,cDelim2,'' ) + cQuo + xVal + cQuo
                  ELSE
                     s += Iif( i>1,cDelim2,'' ) + xVal
                  ENDIF
               NEXT
               FWrite( han, s + Chr(13) + Chr(10) )
               IF r2 == 2 .AND. --nNext == 0
                  EXIT
               ENDIF
            ENDIF
            SKIP
         ENDDO
         Set( _SET_DATEFORMAT, oldDf )
         FClose( han )
      ENDIF
      oMsg:Close()
      UpdBrowse()
   ENDIF

   RETURN Nil

   /* -----------------------  Reindex, pack, zap --------------------- */

FUNCTION C_RPZ( nAct )
   LOCAL oMsg, aTitle := { "Reindex", "Pack", "Zap" }
   LOCAL oBrw := GetBrwActive()

   improc := oBrw:cargo[1]

   IF !aFiles[ improc, AF_EXCLU ]
      hwg_Msgstop( "File must be opened in exclusive mode" )
      RETURN Nil
   ENDIF
   IF aFiles[ improc, AF_RDONLY ]
      hwg_Msgstop( "File is opened in readonly mode" )
      RETURN Nil
   ENDIF

   IF hwg_MsgYesNo( "Really " + aTitle[nAct] + " " + aFiles[improc,AF_ALIAS] + "?", "Attention!" )

      oMsg := DlgWait( aTitle[nAct] )
      IF nAct == 1
         REINDEX
      ELSEIF nAct == 2
         PACK
      ELSEIF nAct == 3
         ZAP
      ENDIF
      oMsg:Close()
      UpdBrowse()
   ENDIF

   RETURN Nil

FUNCTION C_REL
   LOCAL oDlg, oBrowse, arel := {}, aals := {}, nAlias := 1, i := 0, cExpr
   LOCAL bClear := {||
      dbClearRelation()
      oBrowse:aArray := arel := {}
      hwg_Invalidaterect( oBrowse:handle, 1 )
      oBrowse:Refresh()
      RETURN Nil
      }
   LOCAL bAdd := {||
      LOCAL cTmp
      dbSetRelation( aals[nAlias], &( "{||"+Trim(cExpr)+"}" ), Trim(cExpr) )
      oBrowse:aArray := aRel := {}
      i := 0
      DO WHILE !Empty( cTmp := dbRelation( ++i ) )
         Aadd( arel, { cTmp, Alias( dbRselect(i) ) } )
      ENDDO
      hwg_Invalidaterect( oBrowse:handle, 1 )
      oBrowse:Refresh()
      RETURN Nil
      }

   DO WHILE !Empty( cExpr := dbRelation( ++i ) )
      Aadd( arel, { cExpr, Alias( dbRselect(i) ) } )
   ENDDO
   FOR i := 1 TO Len( aFiles )
      IF aFiles[ i,AF_NAME ] != Nil .AND. i != improc
         Aadd( aals, aFiles[ i,AF_ALIAS ] )
      ENDIF
   NEXT

   INIT DIALOG oDlg TITLE "Relations" ;
      AT 0, 0         ;
      SIZE 400, 280   ;
      FONT oMainFont

   @ 20,20 BROWSE oBrowse ARRAY   ;
       SIZE 360,120               ;
       STYLE WS_BORDER+WS_VSCROLL ;
       ON SIZE ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_BOTTOMABS+ANCHOR_RIGHTABS

   oBrowse:aArray := arel
   oBrowse:AddColumn( HColumn():New( "",{|v,o| (v), o:nCurrent},"N",4,0 ) )
   oBrowse:AddColumn( HColumn():New( "Expression",{|v,o| (v), o:aArray[o:nCurrent,1]},"C",30,0 ) )
   oBrowse:AddColumn( HColumn():New( "Child",{|v,o| (v), o:aArray[o:nCurrent,2]},"C",10,0 ) )
   oBrowse:bcolorSel := BCOLOR_SEL
   oBrowse:tcolorSel := TCOLOR_SEL

   cExpr := ""
   @ 10,160 SAY "Expression: " SIZE 90, 22
   @ 100,160 GET cExpr SIZE 280, 24 STYLE ES_AUTOHSCROLL
   Atail( oDlg:aControls ):Anchor := ANCHOR_BOTTOMABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 10,184 SAY "To area: " SIZE 90, 22
   @ 100,184 GET COMBOBOX nAlias ITEMS aals SIZE 120, 150

   @ 40,230 BUTTON "Add" SIZE 80,30 ON CLICK bAdd ON SIZE ANCHOR_LEFTABS+ANCHOR_BOTTOMABS
   @ 160,230 BUTTON "Clear all" SIZE 80,30 ON CLICK bClear ON SIZE ANCHOR_LEFTABS+ANCHOR_BOTTOMABS
   @ 280,230 BUTTON "Close" SIZE 80,30 ON CLICK {||hwg_EndDialog()} ON SIZE ANCHOR_BOTTOMABS+ANCHOR_RIGHTABS

   oDlg:Activate()

   RETURN Nil
