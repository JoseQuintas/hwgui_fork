/*
testsamples.prg

For tests purpose over samples/demoall
May be deleted later
*/

PROCEDURE Main

   LOCAL aList, aFile, cTxtHbp := "", cTxt, nCounter := 0
   local lmdi, lnOPragma, lNoHbp, lWindow, lNoButton, lNoDefault
   LOCAL cTxtPragma

   cTxtPragma := MemoRead( "demoall.prg" )
   cTxtPragma := Substr( cTxtPragma, At( "#pragma", cTxtPragma) )

   aList := Directory( "*.hbp" )
   FOR EACH aFile IN aList
      cTxtHbp += MemoRead( aFile[ 1 ] )
   NEXT
   aList := Directory( "*.prg" )
   FOR EACH aFile IN aList
      DO CASE
      CASE Lower( aFile[1] ) == "demoall.prg" ;
         .OR. Lower( aFile[1] ) == "testsamples.prg"
         LOOP
      CASE Lower( aFile[1] ) == "grid_2.prg" ;
         .OR. Lower( aFile[1] ) == "grid_3.prg"
         ? Pad( aFile[1], 20 ) + "Postgress no demoall"
         LOOP
      CASE Lower( aFile[1] ) == "a.prg" ;
         .OR. Lower( aFile[1] ) == "testmdi.prg" ;
         .OR. Lower( aFile[1] ) == "demomdi.prg" ;
         .OR. Lower( aFile[1] ) == "testrtf.prg"
         ? Pad( aFile[1], 20 ) + "MDI no demoall"
         LOOP
      CASE Lower( aFile[1] ) == "demomenumt"
         ? Pad( aFile[1], 20 ) + "MT no demoall"
         LOOP
      ENDCASE
      cTxt       := MemoRead( aFile[ 1 ] )
      lNoHbp     := ! Lower( aFile[ 1 ] ) $ Lower( cTxtHbp )
      lWindow    := "init window" $ Lower( cTxt )
      lNoButton  := ! ( "demo.ch" $ Lower( cTxt ) .AND. [buttonforsample( "] + aFile[1] + [", oDlg )] $ Lower( cTxt ) )
      lmdi       := " mdi" $ Lower( cTxt )
      lNoDefault := "lWithDialog" $ cTxt .AND. ! "hb_Default( @lWithDialog" $ cTxt
      lNoPragma  := ! lNoButton .AND. ! Lower( aFile[ 1 ] ) $ Lower( cTxtPragma )
      IF lNoHbp .OR. lWindow .OR. lNoButton .OR. lNoDefault .OR. lNoPragma
         nCounter++
         cTxt := ""
         cTxt += Str( nCounter, 6 ) + " "
         cTxt += pad( aFile[ 1 ], 20 )
         cTxt += pad( iif( lNoHbp, "no hbp ", "" ), 10 )
         cTxt += pad( iif( lWindow, "window->dialog ", "" ), 16 )
         cTxt += pad( iif( lNoButton, "ButtonForSample ", "" ), 16 )
         cTxt += Pad( iif( lNoDefault, "lWithDialog default ", "" ), 18 )
         cTxt += Pad( iif( lNoPragma, "no pragma", "" ), 10 )
         cTxt += iif( lmdi, "MDI (external)", "" )
         ? cTxt
      ENDIF
   NEXT
   Inkey(0)

   RETURN

