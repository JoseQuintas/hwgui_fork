/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library
 *
 * Sample:  HButton with image + text
 *
 * Demonstrates the ownerdraw path added to HButton:SetImage() and
 * HButton:DrawFromLpDis().  A push button can now show an icon (or a
 * bitmap) AND a caption at the same time, with a proper focus
 * rectangle - something the native BS_ICON / BS_BITMAP styles cannot
 * do (they suppress the caption and hide the focus indicator).
 *
 * The icons come from the <hwgui>\image folder that ships with the
 * library.  Only .ico files are used here to keep the sample
 * dependency-free; PNG / BMP / JPEG work the same way through
 * HBitmap():AddFile() (see the comments in button_image.txt).
 */

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow
   LOCAL oIconOk, oIconCancel, oIconWarn, oIconHwgui
   LOCAL oBtnOk, oBtnCancel, oBtnWarn, oBtnText
   LOCAL oBtnSwap, oBtnDisabled, oBtnBig, oBtnClose
   LOCAL oBtnAbout, oBtnToggle
   LOCAL cImgDir

   /* ---------- locate the <hwgui>\image folder ---------- */

   cImgDir := FindImageDir()
   IF cImgDir == NIL
      hwg_MsgStop( ;
         "Image folder not found." + Chr(10) + Chr(10) + ;
         "This sample expects the standard HWGUI layout:" + Chr(10) + ;
         "   <hwgui>\samples\   <- this .prg" + Chr(10) + ;
         "   <hwgui>\image\     <- *.ico files" + Chr(10) + Chr(10) + ;
         "Run it from the samples folder, or copy the image folder" + Chr(10) + ;
         "next to the executable.", ;
         "button_image" )
      RETURN NIL
   ENDIF

   /* ---------- load the icons once ---------- */

   oIconOk     := HIcon():AddFile( cImgDir + "ok.ico" )
   oIconCancel := HIcon():AddFile( cImgDir + "cancel.ico" )
   oIconWarn   := HIcon():AddFile( cImgDir + "W.ico" )
   oIconHwgui  := HIcon():AddFile( cImgDir + "hwgui_32x32.ico" )

   IF Empty( oIconOk ) .OR. Empty( oIconCancel ) .OR. ;
      Empty( oIconWarn ) .OR. Empty( oIconHwgui )
      hwg_MsgStop( "Failed to load one or more .ico files from " + ;
                   cImgDir, "button_image" )
      RETURN NIL
   ENDIF

   /* ---------- main window ---------- */

   INIT DIALOG oMainWindow ;
   TITLE "HWGUI - HButton with image + text" ;
   SIZE 520, 320

   /* Row 1: three buttons, each with a different icon + caption.
      These exercise the new ownerdraw code. */

   @ 20, 20 BUTTON oBtnOk ;
      CAPTION "OK" ;
      IMAGE oIconOk ;
      SIZE 150, 40 ;
      ON CLICK { || hwg_MsgInfo( "OK clicked", "button_image" ) }

   @ 185, 20 BUTTON oBtnCancel ;
      CAPTION "Cancel" ;
      IMAGE oIconCancel ;
      SIZE 150, 40 ;
      ON CLICK { || hwg_MsgInfo( "Cancel clicked", "button_image" ) }

   @ 350, 20 BUTTON oBtnWarn ;
      CAPTION "Warning" ;
      IMAGE oIconWarn ;
      SIZE 150, 40 ;
      ON CLICK { || hwg_MsgInfo( "Warning clicked", "button_image" ) }

   /* Row 2: plain text button - unchanged behaviour, keeps the
      native push button look.  Use this as a reference to compare
      the two styles side by side. */

   @ 20, 80 BUTTON oBtnText ;
      CAPTION "Only text (native)" ;
      SIZE 150, 30 ;
      ON CLICK { || hwg_MsgInfo( "Native button clicked", "button_image" ) }

   /* Row 3: disabled button with image, to confirm that
      ODS_DISABLED is honoured (gray caption, dimmed icon). */

   @ 185, 80 BUTTON oBtnDisabled ;
      CAPTION "Disabled" ;
      IMAGE oIconHwgui ;
      SIZE 150, 40

   hwg_Enablewindow( oBtnDisabled:handle, .F. )
   hwg_Redrawwindow( oBtnDisabled:handle, ;
                     RDW_ERASE + RDW_INVALIDATE + RDW_UPDATENOW )

   /* Row 4: runtime image swap.  The button starts as text-only and
      becomes image + text at click time, proving SetImage() can be
      called after creation. */

   @ 20, 140 BUTTON oBtnSwap ;
      CAPTION "Click me to add an icon" ;
      SIZE 315, 40 ;
      ON CLICK { || SwapImage( oBtnSwap, oIconHwgui ) }

   /* Row 5: more variants for visual inspection. */

   @ 350, 140 BUTTON oBtnBig ;
      CAPTION "Big icon" ;
      IMAGE HIcon():AddFile( cImgDir + "hwgui_48x48.ico" ) ;
      SIZE 150, 40

   @ 20, 200 BUTTON oBtnClose ;
      CAPTION "Close" ;
      IMAGE oIconCancel ;
      SIZE 150, 40 ;
      ON CLICK { || oMainWindow:Close() }

   @ 185, 200 BUTTON oBtnAbout ;
      CAPTION "HWGUI" ;
      IMAGE HIcon():AddFile( cImgDir + "hwgui.ico" ) ;
      SIZE 150, 40 ;
      ON CLICK { || hwg_MsgInfo( ;
         "HWGUI" + Chr(10) + ;
         "Image + caption on the same button.", ;
         "About" ) }

   @ 350, 200 BUTTON oBtnToggle ;
      CAPTION "Toggle disabled" ;
      SIZE 150, 40 ;
      ON CLICK { || ToggleEnabled( oBtnDisabled ) }

   ACTIVATE DIALOG oMainWindow

RETURN NIL

/*-----------------------------------------------------------------------------
 * SwapImage()
 *
 * Attaches an image to an existing button.  Exercises HButton:SetImage()
 * at runtime: the button switches from BS_PUSHBUTTON to BS_OWNERDRAW,
 * so its caption moves aside to make room for the icon.
 *---------------------------------------------------------------------------*/
STATIC FUNCTION SwapImage( oBtn, oIcon )

   IF !Empty( oBtn:oImg )
      RETURN NIL
   ENDIF

   oBtn:SetImage( oIcon )
   oBtn:SetText( "Now with image" )

   RETURN NIL

/*-----------------------------------------------------------------------------
 * ToggleEnabled()
 *
 * Flips the enabled state of the target button.  Uses the HWGUI wrappers
 * hwg_Iswindowenabled() / hwg_Enablewindow(), which are the only functions
 * the library exposes for this purpose (see window.c).
 *---------------------------------------------------------------------------*/
STATIC FUNCTION ToggleEnabled( oBtn )

   LOCAL lEnabled := hwg_Iswindowenabled( oBtn:handle )

   hwg_Enablewindow( oBtn:handle, !lEnabled )
   hwg_Redrawwindow( oBtn:handle, ;
                     RDW_ERASE + RDW_INVALIDATE + RDW_UPDATENOW )

   RETURN NIL

/*-----------------------------------------------------------------------------
 * FindImageDir()
 *
 * Returns the path of the HWGUI image folder (with trailing backslash)
 * or NIL if it cannot be located.  Three candidates are tested, in
 * order:
 *
 *    ..\image\   - typical when running from <hwgui>\samples\
 *    .\image\    - when the sample was copied next to the image folder
 *    image\      - when running from the HWGUI root
 *
 * The existence check is done on a file that ships with every HWGUI
 * distribution (ok.ico), so a stray empty folder does not fool us.
 *---------------------------------------------------------------------------*/
STATIC FUNCTION FindImageDir()

   LOCAL aCand := { "..\image\", ".\image\", "image\", "..\..\image\" }
   LOCAL i

   FOR i := 1 TO Len( aCand )
      IF File( aCand[ i ] + "ok.ico" )
         RETURN aCand[ i ]
      ENDIF
   NEXT

   RETURN NIL
