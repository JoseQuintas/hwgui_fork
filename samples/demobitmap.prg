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

*/
   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes


#include "hwgui.ch"

FUNCTION DemoBitmap( lWithDialog, oDlg )

   LOCAL oSayMain
   LOCAL nameimg
   LOCAL cs := hwg_GetDirSep()

   hb_Default( @lWithDialog, .T. )

   nameimg := ".." + cs + "image" + cs + "astro.bmp"
/*
#ifdef __GTK__
* relative from path samples\gtk_samples
 nameimg := ".." + cs + nameimg
#endif
*/

   IF .NOT. FILE( nameimg )
      hwg_msginfo( "File >" + nameimg + "< not found", "Error" )
   ENDIF

   IF lWithDialog
      INIT DIALOG oDlg ;
         AT 0,0 ;
         SIZE 500,400 ;
         CLIPPER ;
         NOEXIT ;
         NOEXITESC
   ENDIF

   ButtonForSample( "demobitmap.prg" )

* This command requires FreeImage
*@ 30, 10 IMAGE oSayMain SHOW nameimg OF oDlg SIZE 100, 90
*
* BITMAP:
* Supported formats: bmp, jpg
   @ 30, 100 BITMAP oSayMain ;
      SHOW nameimg ;
      OF oDlg ;
      SIZE 100, 90

   IF lWithDialog
      ACTIVATE Dialog oDlg CENTER
   ENDIF

RETURN Nil

#include "demo.ch"

* ================ EOF of demobitmap.prg ===========================
