/*
testsamples.prg

For tests purpose over samples/demoall
May be deleted later
*/

PROCEDURE Main

   LOCAL aList, aFile, cTxtHbp := "", cTxt, nCounter := 0
   local lmdi, lnOPragma, lNoHbp, lWindow, lNoButton, lNoDefault
   LOCAL cTxtPragma, cTxtButton
   LOCAL cTxtshMakeAllSam, cTxtshClean, cTxtshSamplesClean
   LOCAL cTxtAboutsh, cNameNoExt
   LOCAL aList1, cText
   LOCAL aNoTestList := { ;
      { "no check", "demoall.prg", "testsamples.prg" }, ;
      { "MDI", "a.prg", "testmdi.prg", "testrtf.prg", "demomdi.prg" }, ;
      { "utility?", "buildpelles.prg", "dbview.prg" }, ;
      { "multithead", "demomenumt.prg" }, ;
      { "window", "demoonother.prg" }, ;
      { "postgress", "grid_2.prg", "grid_3.prg" }, ;
      { "console", "helloworld.prg" }, ;
      { "undefined", "propsh.prg", "tststconsapp.prg", "helpstatic.prg", ;
         "tstprdos.prg", "winprn.prg", "testalert.prg", "pseudocm.prg", ;
         "bincnts.prg", "bindbf.prg", "hexbincnt.prg" }, ;
      { "bug", "tstscrlbar.prg", "helpdemo.prg" } }

   cTxtPragma := MemoRead( "demoall.prg" )
   cTxtPragma := Substr( cTxtPragma, At( "#pragma", cTxtPragma) )

   cTxtshMakeAllSam   := MemoRead( "makeallsam.ch" )
   cTxtshClean        := MemoRead( "..\clean.sh" )
   cTxtshSamplesClean := MemoRead( "clean.sh" )

   aList := Directory( "*.hbp" )
   FOR EACH aFile IN aList
      cTxtHbp += MemoRead( aFile[ 1 ] )
   NEXT
   aList := Directory( "*.prg" )
   FOR EACH aList1 IN aNoTestList
      FOR EACH cText IN aList1
         ?? ": " + cText
      NEXT
      ?
   NEXT
   FOR EACH aFile IN aList
      IF hb_AScan( aNoTestList, { |a| hb_AScan( a, { |b| ;
         b == Lower( aFile[1] ) } ) != 0 } ) != 0
         LOOP
      ENDIF
      cNameNoExt := hb_FNameName( aFile[ 1 ] )
      cTxtButton := [ButtonForSample( "] + Lower( aFile[1] ) + [", oDlg )]
      cTxt       := MemoRead( aFile[ 1 ] )
      lNoHbp     := ! Lower( aFile[ 1 ] ) $ Lower( cTxtHbp )
      lWindow    := "init window" $ Lower( cTxt )
      lNoButton  := ! ( "demo.ch" $ Lower( cTxt ) .AND. cTxtButton $ cTxt )
      lmdi       := " mdi" $ Lower( cTxt )
      lNoDefault := "lWithDialog" $ cTxt .AND. ! "hb_Default( @lWithDialog" $ cTxt
      lNoPragma  := ! lNoButton .AND. ! Lower( aFile[ 1 ] ) $ Lower( cTxtPragma )
      cTxtAboutsh := ""
      IF ! File( cNameNoExt + ".hbp" )
         IF cNameNoExt + ".hbp" $ cTxtshMakeAllSam
            cTxtAboutsh += "delete from MakeAllSam.sh"
         ENDIF
         IF cNameNoExt + ".o" $ cTxtshClean
            cTxtAboutsh += "delete .o from Clean.sh"
         ENDIF
         IF cNameNoExt + ".c" $ cTxtshClean
            cTxtAboutsh += "delete .c from clean.sh"
         ENDIF
         IF cNameNoExt + ".O" $ cTxtshSamplesClean
            cTxtAboutsh += "delete .o from Samples\Clean.sh"
         ENDIF
         IF cNameNoExt + ".c" $ cTxtshSamplesClean
            cTxtAboutsh += "delete .c from Samples\clean.sh"
         ENDIF
      ENDIF
      IF lNoHbp .OR. lWindow .OR. lNoButton .OR. lNoDefault .OR. lNoPragma ;
         .OR. ! Empty( cTxtAboutsh )
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
         cTxt += " " + cTxtAboutsh
         ? cTxt
      ENDIF
   NEXT
   Inkey(0)

   RETURN

