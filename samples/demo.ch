/*
  $Id: demo.ch

  include buttons on sample to run and show source code
*/

STATIC FUNCTION ButtonForSample( cFileName, oDlg )

   LOCAL cRunName

   cRunName := StrTran( cFileName, ".prg", "" )

   @ 10, 30 OWNERBUTTON ;
      OF       oDlg ;
      SIZE     50, 24 ;
      TEXT     "Dlg" ;
      HSTYLES ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 2,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 2, 8421440 ) ;
      ON CLICK { || iif( cRunName == "demoall", "", Do( cRunName ) ) }

   @ 70, 30 OWNERBUTTON ;
      OF oDlg ;
      SIZE 50, 24 ;
      TEXT "Code" ;
      HSTYLES ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 2,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 2, 8421440 ) ;
      ON CLICK { || ShowCode( cFileName ) }

   @ 130, 30 SAY cFileName ;
      OF oDlg ;
      SIZE 200, 24 ;
      BACKCOLOR 0xffffff

   RETURN Nil

STATIC FUNCTION ShowCode( cFileName )

   LOCAL oDlg, oEdit, oFont, cText

   BEGIN SEQUENCE WITH __BreakBlock()
      cText := &( [LoadResourceDemo( "] + cFileName + [" )] )
   ENDSEQUENCE

   IF Empty( cText )
      IF ! File( cFileName )
         hwg_MsgInfo( cFileName + " not found" )
         RETURN Nil
      ENDIF
      IF "demoall" $ Lower( hb_ProgName() )
         hwg_MsgInfo( "Add " + cFileName +  " to LoadResourceDemo()" )
      ENDIF
      cText := MemoRead( cFileName )
   ENDIF

#ifdef __PLATFORM__WINDOW
   // if source code on linux format
   IF ! hb_Eol() $ cText
      cText := StrTran( cText, Chr(10), hb_Eol() )
   ENDIF
#endif

   PREPARE FONT oFont ;
      NAME "Courier New" ;
      WIDTH 0 ;
      HEIGHT -13

   INIT DIALOG oDlg ;
      TITLE cFileName ;
      SIZE 800, 600 ;
      FONT oFont

   @ 10, 10 EDITBOX oEdit ;
      CAPTION cText ;
      SIZE    780, 580 ;
      ; // FONT    oFont
      STYLE   ES_MULTILINE + ES_AUTOVSCROLL + WS_VSCROLL + WS_HSCROLL

   ACTIVATE DIALOG oDlg CENTER

   RETURN Nil
