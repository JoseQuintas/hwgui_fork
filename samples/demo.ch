/*
  $Id: demo.ch

  Created to do not duplicate source code on all samples
*/

STATIC FUNCTION ButtonForSample( cFileName, oDlg )

   LOCAL cRunName

   cRunName := StrTran( cFileName, ".prg", "" )

   @ 3, 30 OWNERBUTTON ;
      OF       oDlg ;
      SIZE     200, 24 ;
      TEXT     cFileName ;
      HSTYLES ;
         HStyle():New( {16759929,16772062}, 1 ), ;
         HStyle():New( {16759929}, 1,, 3, 0 ), ;
         HStyle():New( {16759929}, 1,, 2, 12164479 ) ;
      ON CLICK { || Do( cRunName ) }

   @ 220, 30 OWNERBUTTON ;
      OF oDlg ;
      SIZE 100, 24 ;
      TEXT "show code" ;
      HSTYLES ;
         HStyle():New( {16759929,16772062}, 1 ), ;
         HStyle():New( {16759929}, 1,, 3, 0 ), ;
         HStyle():New( {16759929}, 1,, 2, 12164479 ) ;
      ON CLICK { || ShowCode( cFileName ) }

   RETURN Nil

STATIC FUNCTION ShowCode( cFileName )

   LOCAL oDlg, oEdit, oFont

   IF ! File( cFileName )
      hwg_MsgInfo( cFileName + " not found" )
   ENDIF

   PREPARE FONT oFont ;
      NAME "Courier New" ;
      WIDTH 0 ;
      HEIGHT -13

   INIT DIALOG oDlg ;
      TITLE cFileName ;
      SIZE 800, 600 ;
      FONT oFont

   @ 10, 10 EDITBOX oEdit ;
      CAPTION MemoRead( cFileName ) ;
      SIZE    780, 580 ;
      ; // FONT    oFont
      STYLE   ES_MULTILINE + ES_AUTOVSCROLL + WS_VSCROLL + WS_HSCROLL

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil
