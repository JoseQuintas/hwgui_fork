/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * TVideo component
 *
 * Copyright 2003 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
*/
#include "hbclass.ch"
#include "hwgui.ch"

#include "common.ch"

CLASS TVideo FROM HControl

   DATA   oMci
   DATA   cAviFile

   METHOD New( nRow, nCol, nWidth, nHeight, cFileName, oWnd, ;
               lNoBorder, nid ) CONSTRUCTOR

   METHOD ReDefine( nId, cFileName, oDlg, bWhen, bValid ) CONSTRUCTOR

   METHOD Initiate()

   /* FIXED: Removed extra parameter - ::oMci:Play expects only nFrom, nTo */
   METHOD Play( nFrom, nTo )

ENDCLASS

/*=============================================================================
 * New()
 * Creates a video control
 *===========================================================================*/
METHOD New( nRow, nCol, nWidth, nHeight, cFileName, oWnd, lNoBorder, nid ) CLASS TVideo

   DEFAULT nWidth TO 200, nHeight TO 200, cFileName TO "", ;
   lNoBorder TO .F.

   /* FIXED: Coordinates are in pixels, not characters */
   ::nTop      := nRow
   ::nLeft     := nCol
   ::nWidth    := nWidth
   ::nHeight   := nHeight

   ::Style     := hwg_bitOR( WS_CHILD + WS_VISIBLE + WS_TABSTOP, ;
                    IF( ! lNoBorder, WS_BORDER, 0 ) )

   ::oParent   := IIf( oWnd == Nil, ::oDefaultParent, oWnd )
   ::id        := IIf( nid == Nil, ::NewId(), nid )
   ::cAviFile  := cFileName
   ::oMci      := TMci():New( "avivideo", cFileName )

   IF ! Empty( ::oParent:handle )
      ::Initiate()
   ELSE
      ::oParent:AddControl( Self )
   ENDIF

   RETURN Self

/*=============================================================================
 * ReDefine()
 * Redefines a video control from resource
 *===========================================================================*/
METHOD ReDefine( nId, cFileName, oDlg, bWhen, bValid ) CLASS TVideo

   ::nId      = nId
   ::cAviFile = cFileName
   /* FIXED: bWhen and bValid are not used - store them anyway */
   ::bWhen    = bWhen
   ::bValid   = bValid
   ::oWnd     = oDlg
   ::oMci     = TMci():New( "avivideo", cFileName )

   oDlg:AddControl( Self )

   RETURN Self

/*=============================================================================
 * Initiate()
 * Initializes the video control
 *===========================================================================*/
METHOD Initiate() CLASS TVideo

   /* FIXED: Call parent initialization - HControl does not have Init, but
    * it has a method called Init (without parenthesis). In HWGUI, controls
    * typically call ::Init() to set up the window. However, the correct
    * approach is to call ::Super:Init() if the parent has it, but HControl
    * does not have an Init method. Instead, we just initialize the MCI. */

   IF !Empty( ::oParent:handle )
      /* FIXED: Call lOpen() and SetWindow() - SetWindow expects a window object,
       * but in TVideo the parent window is ::oParent, not Self */
      ::oMci:lOpen()
      /* FIXED: Pass ::oParent (the parent window) instead of Self */
      ::oMci:SetWindow( ::oParent )
   ENDIF

   RETURN nil

/*=============================================================================
 * Play()
 * Plays the video from nFrom to nTo
 *===========================================================================*/
METHOD Play( nFrom, nTo ) CLASS TVideo

   /* FIXED: Removed extra parameter - ::oMci:Play expects only nFrom, nTo */
   ::oMci:Play( nFrom, nTo )

   RETURN nil
