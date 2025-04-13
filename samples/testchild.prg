/*
 * HWGUI using sample
 *
 * $Id$
 *
 * Jose Augusto M de Andrade Jr - jamaj@terra.com.br
 *
 * Modifications by DF7BE:
 * - Ticket 102: PIM.ICO does not exist any more, use W.ico instead
 *               Don't working yet, bug must be found in source code file
 *               hwindow.prg, about line 529
 *               (to be continued)
 *
 * - Need for GTK : Port of function HCHILDWINDOW()
*/

#include "hwgui.ch"

STATIC aChilds := {}

FUNCTION Main()

   LOCAL oMainWindow

   INIT WINDOW oMainWindow MAIN TITLE "HwGui - Child Windows Example" STYLE WS_CLIPCHILDREN ;

   MENU OF oMainWindow
#ifdef __GTK__
      MENU TITLE "&Exit"
         MENUITEM "&Quit" ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Test"
         MENUITEM "&Create a child" ACTION CreateChild()
      ENDMENU
#else
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Create a child" ACTION CreateChild()
#endif
   ENDMENU

   ACTIVATE WINDOW oMainWindow

RETURN Nil

FUNCTION CreateChild( lClip )

   LOCAL oChild
   LOCAL cdirsep := hwg_GetDirSep()
#ifdef __GTK__
   LOCAL cImagdir := ".." + cdirsep + ".." + cdirsep + "image" + cdirsep
#else
   LOCAL cImagdir := ".." + cdirsep + "image" + cdirsep
#endif

   LOCAL cTitle := "Child Window #" + Str(len(aChilds)+1,2,0)
   LOCAL oIcon := HIcon():AddFile(cImagdir + "W.ico")
   //LOCAL oBmp  := HBitMap():AddFile(cImagdir + "logo.bmp")
   LOCAL cMenu := ""
   LOCAL bExit := { | oSelf | hwg_Msginfo( "Bye!" , "Destroy message from " + oSelf:title )  }

   DEFAULT lClip := .f.

    /*
   oChild := HWindow():New( WND_CHILD , oIcon,hwg_ColorC2N("0000FF"),NIL,10,10,200,100,cTitle,cMenu,NIL,NIL, ;
                          NIL,bExit,NIL,NIL,NIL,NIL,NIL, "Child_" + Alltrim(Str(len(aChilds))) , oBmp )
    */

   * The class HChildWindow is coded in file hwindow.prg at about line 517

   oChild := HChildWindow():New( oIcon,hwg_ColorC2N("0000FF"),NIL,10,10,200,100,cTitle,cMenu,NIL,NIL, ;
                          bExit,NIL,NIL,NIL,NIL,NIL, "Child_" + Alltrim(Str(len(aChilds))) , NIL )


   // Test if we could create the window object
   IF ISOBJECT( oChild )
      hwg_MsgInfo( "Child object exists" )
      aAdd( aChilds, oChild )
   ELSE
       * Erro ao tentar criar objeto HWindow!
       hwg_Msgstop( "Error trying to create object HWindow!" )
   ENDIF

   oChild:Activate(.t.)

RETURN Nil

* ===================================== EOF of testchild.prg =============================================
