/*
 *
 * demobitmap.prg
 *
 * Test program sample for displaying images and usage of FreeImage library.
 *
 * $Id$
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Copyright 2020 Itamar M. Lins Jr. Junior (TNX)
 * See ticket #43

* This command requires FreeImage
*@ 30, 10 IMAGE oSayMain SHOW nameimg OF oDlg SIZE 100, 90

*/
   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

#ifdef __PLATFORM__WINDOWS
   #define FILE_BITMAP "..\image\astro.bmp"
#else
   #define FILE_BITMAP "../image/astro.bmp"
#endif

#include "hwgui.ch"

FUNCTION DemoBitmap( lWithDialog, oDlg )

#ifndef __CALLED_FROM_DEMOALL
   LOCAL oSayMain
#endif

   hb_Default( @lWithDialog, .T. )

   IF lWithDialog
      INIT DIALOG oDlg ;
         AT 0,0 ;
         SIZE 500,400 ;
         CLIPPER ;
         NOEXIT ;
         NOEXITESC
   ENDIF

   ButtonForSample( "demobitmap.prg" )

   IF .NOT. FILE( FILE_BITMAP )
      hwg_msginfo( "File >" + FILE_BITMAP + "< not found", "Error" )
   ENDIF

   @ 30, 100 BITMAP hBitmap():AddString( FILE_BITMAP, ImageOnPRG() ) ;
      OF oDlg ;
      SIZE 100, 90

#ifndef __CALLED_FROM_DEMOALL
   @ 250, 100 BITMAP oSayMain ;
      SHOW FILE_BITMAP ;
      OF oDlg ;
      SIZE 100, 90
#endif

   IF lWithDialog
      ACTIVATE Dialog oDlg CENTER
   ENDIF

RETURN Nil

STATIC FUNCTION ImageOnPRG()

#ifdef __PLATFORM__WINDOWS
   #pragma __binarystreaminclude "..\image\astro.bmp" | RETURN %s
#else
   #pragma __binarystreaminclude "../image/astro.bmp" | RETURN %s
#endif

#include "demo.ch"

* ================ EOF of demobitmap.prg ===========================
