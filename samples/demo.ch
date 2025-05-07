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
      ON CLICK { || demo_ShowCode( cFileName ) }

   @ 130, 30 SAY cFileName ;
      OF oDlg ;
      SIZE 200, 24 ;
      BACKCOLOR 0xffffff

   RETURN Nil

STATIC FUNCTION demo_ShowCode( cFileName )

   LOCAL cText

   cText := demo_ReadFile( cFileName )

#ifdef __PLATFORM__WINDOW
   // if source code on linux format
   IF ! hb_Eol() $ cText
      cText := StrTran( cText, Chr(10), hb_Eol() )
   ENDIF
   #define _SHOW_HELP_MODAL .T.
#else
   #define _SHOW_HELP_MODAL .F.
#endif

   hwg_ShowHelp( cText, cFileName, "Close",, _SHOW_HELP_MODAL )

   RETURN Nil

STATIC FUNCTION demo_ReadFile( cFileName )

   LOCAL cText

#ifdef __PLATFORM__WINDOWS
   cFileName := StrTran( cFileName, "/", "\" )
#else
   cFileName := StrTran( cFileName, "\", "/" )
#endif

// this function is on demoall.prg
   BEGIN SEQUENCE WITH __BreakBlock()
      cText := &( [demo_LoadResource( "] + cFileName + [" )] )
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

   RETURN cText
