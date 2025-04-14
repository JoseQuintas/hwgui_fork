/*
 * $Id: TestMenuBitmap.prg,v 1.6 2004/05/05 18:27:14 sandrorrfreire Exp $
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
 * - use ralative paths for bitmap files
 * - Check, if bitmap file really exits
 *
 * The crash message is:
 * Error BASE/1004  No exported method: HANDLE
 * Called from ->HANDLE(0)
 * Called from source\winapi/menu.prg->HWG_DEFINEMENUITEM(250)
 * Called from testmenubitmap.prg->MAIN(48)

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

FUNCTION Main()

   LOCAL oMain
   LOCAL cbmpexit, cbmpnew, cbmpopen, cbmplogo, bbmperror , cimagepath
   PRIVATE oMenu

   bbmperror := .F.


 * Use relative paths
#ifdef __GTK__
   cimagepath := ".." + hwg_GetDirSep() + ".." + hwg_GetDirSep() + "image" + hwg_GetDirSep()
#else
   cimagepath := "..\image\"
#endif
   cbmpexit := cimagepath + "exit_m.bmp"
   cbmpnew  := cimagepath + "new_m.bmp"
   cbmpopen := cimagepath + "open_m.bmp"
   cbmplogo := cimagepath + "logo.bmp"
   * Check for existing bitmaps
   IF .NOT. FILE( cbmpexit )
      hwg_MsgStop("Error: File not exists: " + cbmpexit, "Bitmap error")
      bbmperror := .T.
   ENDIF
   IF .NOT. FILE( cbmpnew )
      hwg_MsgStop("Error: File not exists: " + cbmpnew, "Bitmap error")
      bbmperror := .T.
   ENDIF
   IF .NOT. FILE( cbmpopen )
     hwg_MsgStop("Error: File not exists: " + cbmpopen, "Bitmap error")
     bbmperror := .T.
   ENDIF
   IF .NOT. FILE( cbmplogo )
     hwg_MsgStop( "Error: File not exists: " + cbmplogo, "Bitmap error" )
     bbmperror := .T.
   ENDIF
   * Exit, if bitmap error
   IF bbmperror
      RETURN Nil
   ENDIF

   INIT WINDOW oMain MAIN TITLE "Teste" ;
      AT 0,0 ;//BACKGROUND BITMAP OBMP;
      SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   MENU OF oMain
      MENU TITLE "Samples"
         MENUITEM "&Exit"    ID 1001 ACTION oMain:Close()   BITMAP cbmpexit
         SEPARATOR
         MENUITEM "&New "    ID 1002 ACTION hwg_Msginfo("New")  BITMAP cbmpnew
         MENUITEM "&Open"    ID 1003 ACTION hwg_Msginfo("Open") BITMAP cbmpopen
         MENUITEM "&Demo"    ID 1004 ACTION Test()
         SEPARATOR
         MENUITEM "&Bitmap and a Text"  ID 1005 ACTION Test()
      ENDMENU
   ENDMENU
   //The number ID is very important to use bitmap in menu
   MENUITEMBITMAP oMain ID 1005 BITMAP cbmplogo
   //Hwg_InsertBitmapMenu(oMain:Menu, 1005, "\hwgui\sourceoBmp:handle)   //do not use bitmap empty
   ACTIVATE WINDOW oMain CENTER

RETURN Nil

FUNCTION Test()

   hwg_Msginfo( "Test" )

RETURN Nil

* ======================== EOF of testmenubitmap.prg ======================
