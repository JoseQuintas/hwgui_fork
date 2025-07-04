/*
  $Id: demo.ch

  include buttons on sample to run and show source code
*/

STATIC FUNCTION ButtonForSample( cFileName, oParent )

   LOCAL cRunName

   cRunName := StrTran( cFileName, ".prg", "" )

   @ 10, 30 OWNERBUTTON ;
      OF       oParent ;
      SIZE     50, 20 ;
      TEXT     "Dlg" ;
      HSTYLES ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 2,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 2, 8421440 ) ;
      ON CLICK { || iif( cRunName == "demoall", "", Do( cRunName ) ) }

   @ 70, 30 OWNERBUTTON ;
      OF oParent ;
      SIZE 50, 20 ;
      TEXT "Code" ;
      HSTYLES ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 2,, 1 ), ;
      HStyle():New( {0xffffff,0xdddddd}, 1,, 2, 8421440 ) ;
      ON CLICK { || demo_ShowCode( cFileName ) }

   @ 130, 30 SAY cFileName ;
      OF oParent ;
      SIZE 200, 20 ;
      BACKCOLOR 0xffffff

   RETURN Nil

STATIC FUNCTION demo_ShowCode( cFileName )

   LOCAL cText

   cText := demo_ReadFile( cFileName )


   // if source code on linux format
   // Convert it forever to Windows (also on LINUX)
   // is mandatory for memo fields !
   // IF ! hb_Eol() $ cText
   
   cText := hwg_UNIX2DOS(cText)
    
#ifdef __PLATFORM__WINDOW   
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
         hwg_MsgInfo( "demo.ch " + cFileName + " not found" )
         RETURN Nil
      ENDIF
      cText := MemoRead( cFileName )
   ENDIF

   RETURN cText
