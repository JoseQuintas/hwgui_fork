/*
 * $Id: demoMenuBitmap.prg,v 1.6 2004/05/05 18:27:14 sandrorrfreire Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level menu functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 * Copyright 2004 Sandro R. R. Freire <sandrorrfreire@yahoo.com.br>
 * Demo for use Bitmap in menu
 *
 * Modified by DF7BE:
 * See ticket #31: This example crashes
 * To avoid crash:
 * - use relative paths for bitmap files
 * - Check, if bitmap file really exits
 *
 * The crash message is:
 * Error BASE/1004  No exported method: HANDLE
 * Called from ->HANDLE(0)
 * Called from source\winapi/menu.prg->HWG_DEFINEMENUITEM(250)
 * Called from demomenubitmap.prg->MAIN(48)

 * For GTK test copy sample program to directory samples\gtk_samples
*/

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No

*   Need to port functions HWG_INSERTBITMAPMENU() and
*   HWG__INSERTBITMAPMENU() to GTK
*   Source files : menu_c.c and menu.prg
*   (source\winapi\menu.prg)

#include "hwgui.ch"
#include "sampleinc.ch"

FUNCTION DemoMenuBitmap()

   LOCAL oDlg
   LOCAL cbmpexit, cbmpnew, cbmpopen, cbmplogo, bbmperror
   PRIVATE oMenu

   bbmperror := .F.

   cbmpexit := SAMPLE_IMAGEPATH + "exit_m.bmp"
   cbmpnew  := SAMPLE_IMAGEPATH + "new_m.bmp"
   cbmpopen := SAMPLE_IMAGEPATH + "open_m.bmp"
   cbmplogo := SAMPLE_IMAGEPATH + "logo.bmp"
   * Check for existing bitmaps
   IF .NOT. FILE( cbmpexit )
      hwg_MsgStop( "demomenubitmap.prg" + hb_Eol() + ;
         "Error: File not exists: " + hb_Eol() + ;
         cbmpexit, "Bitmap error" )
      bbmperror := .T.
   ENDIF
   IF .NOT. FILE( cbmpnew )
      hwg_MsgStop( "demomenubitmap.prg" + hb_Eol() + ;
         "Error: File not exists: " + hb_Eol() + ;
         cbmpnew, "Bitmap error" )
      bbmperror := .T.
   ENDIF
   IF .NOT. FILE( cbmpopen )
     hwg_MsgStop( "demomenubitmap.prg" + hb_Eol() + ;
        "Error: File not exists: " + hb_Eol() + ;
        cbmpopen, "Bitmap error")
     bbmperror := .T.
   ENDIF
   IF .NOT. FILE( cbmplogo )
     hwg_MsgStop( "demomenubitmap.prg" + hb_Eol() + ;
        "Error: File not exists: " + hb_Eol() + ;
        cbmplogo, "Bitmap error" )
     bbmperror := .T.
   ENDIF
   * Exit, if bitmap error
   IF bbmperror
      RETURN Nil
   ENDIF

   INIT DIALOG oDlg ;
      TITLE "Teste" ;
      AT 0, 0 ;//BACKGROUND BITMAP OBMP;
      SIZE 800, 600

   MENU OF oDlg
      MENU TITLE "Samples"
         MENUITEM "&Exit"    ID 1001 ACTION oDlg:Close()   BITMAP cbmpexit
         SEPARATOR
         MENUITEM "&New "    ID 1002 ACTION hwg_Msginfo("New")  BITMAP cbmpnew
         MENUITEM "&Open"    ID 1003 ACTION hwg_Msginfo("Open") BITMAP cbmpopen
         MENUITEM "&Demo"    ID 1004 ACTION Test()
         SEPARATOR
         MENUITEM "&Bitmap and a Text"  ID 1005 ACTION Test()
      ENDMENU
   ENDMENU
   //The number ID is very important to use bitmap in menu
   MENUITEMBITMAP oDlg ID 1005 BITMAP cbmplogo
   //Hwg_InsertBitmapMenu(oMain:Menu, 1005, "\hwgui\sourceoBmp:handle)   //do not use bitmap empty

   ButtonForSample( "demomenubitmap.prg", oDlg )

   ACTIVATE DIALOG oDlg CENTER

RETURN Nil

FUNCTION Test()

   hwg_Msginfo( "Test" )

RETURN Nil

#include "demo.ch"

* ======================== EOF of demomenubitmap.prg ======================
