/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Pens, brushes, fonts, bitmaps, icons handling
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

/*
~~~~~~~~~ Attention ~~~~~~~~~~
PNG support prepared for further Windows releases:
The recent Windows release do not support PNG images.

For further releases the following functions and methods
are inserted for test purposes, if the
WinAPI function LoadImage() will support PNGs:

METHOD AddPngString( name, cVal ) CLASS HIcon            of drawwidg.prg
METHOD AddPngFile( name , nWidth, nHeight) CLASS HIcon   of drawwidg.prg

HWG_LOADPNG()                                            of draw.c

DF7BE, September 2022
*/

#include "hbclass.ch"
#include "hwgui.ch"

   //- HFont

CLASS HFont INHERIT HObject

   CLASS VAR aFonts   INIT {}
   DATA handle
   DATA name, width, height , weight
   DATA charset, italic, Underline, StrikeOut
   DATA nCounter   INIT 1

   METHOD Add( fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut, nHandle )
   METHOD SaveToStr()
   METHOD LoadFromStr( s )
   METHOD SELECT( oFont, nCharSet )
   METHOD Props2Arr()
   METHOD PrintFont()
   METHOD SetFontStyle( lBold, nCharSet, lItalic, lUnder, lStrike, nHeight )
   METHOD RELEASE()

ENDCLASS

METHOD Add( fontName, nWidth, nHeight , fnWeight, ;
      fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut, nHandle ) CLASS HFont

   LOCAL i, nlen := Len( ::aFonts )

   nHeight  := iif( nHeight == Nil, - 13, nHeight )
   fnWeight := iif( fnWeight == Nil, 0, fnWeight )
   fdwCharSet := iif( fdwCharSet == Nil, 0, fdwCharSet )
   fdwItalic := iif( fdwItalic == Nil, 0, fdwItalic )
   fdwUnderline := iif( fdwUnderline == Nil, 0, fdwUnderline )
   fdwStrikeOut := iif( fdwStrikeOut == Nil, 0, fdwStrikeOut )

   FOR i := 1 TO nlen
      IF ::aFonts[i]:name == fontName .AND.             ;
            ( ( Empty(::aFonts[i]:width ) .AND. Empty(nWidth ) ) ;
            .OR. ::aFonts[i]:width == nWidth ) .AND.    ;
            ::aFonts[i]:height == nHeight .AND.         ;
            ::aFonts[i]:weight == fnWeight .AND.        ;
            ::aFonts[i]:CharSet == fdwCharSet .AND.     ;
            ::aFonts[i]:Italic == fdwItalic .AND.       ;
            ::aFonts[i]:Underline == fdwUnderline .AND. ;
            ::aFonts[i]:StrikeOut == fdwStrikeOut

         ::aFonts[i]:nCounter ++
         IF nHandle != Nil
            hwg_Deleteobject( nHandle )
         ENDIF
         RETURN ::aFonts[i]
      ENDIF
   NEXT

   IF nHandle == Nil
      ::handle := hwg_Createfont( fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut )
   ELSE
      ::handle := nHandle
   ENDIF

   ::name      := fontName
   ::width     := nWidth
   ::height    := nHeight
   ::weight    := fnWeight
   ::CharSet   := fdwCharSet
   ::Italic    := fdwItalic
   ::Underline := fdwUnderline
   ::StrikeOut := fdwStrikeOut

   AAdd( ::aFonts, Self )

   RETURN Self

METHOD SaveToStr() CLASS HFont

   RETURN ::name + ',' + Ltrim(Str(::height)) + ',' + Iif( ::weight > FW_REGULAR, 'b', '' ) + ;
      Iif( ::Italic == 1, 'i', "" ) + Iif( ::Underline == 1, 'u', "" ) + ;
      Iif( ::StrikeOut == 1, 's', "" ) + ',' + Ltrim(Str(::CharSet))

METHOD LoadFromStr( s ) CLASS HFont

   LOCAL af := hb_ATokens( s, ',' ), nLen := Len( af )

   RETURN ::Add( af[1], 0, Val(af[2]), Iif( nLen>2 .AND. 'b' $ af[3], FW_BOLD, FW_REGULAR ), ;
      Iif( nLen>3, Val(af[4]), Nil ), Iif( nLen>2 .AND. 'i' $ af[3], 1, 0 ), ;
      Iif( nLen>2 .AND. 'u' $ af[3], 1, 0 ), Iif( nLen>2 .AND. 's' $ af[3], 1, 0 ) )

METHOD SELECT( oFont, nCharSet  ) CLASS HFont

   LOCAL af := hwg_Selectfont( oFont )

   IF af == Nil
      RETURN Nil
   ENDIF

   RETURN ::Add( af[ 2 ], af[ 3 ], af[ 4 ], af[ 5 ], iif( Empty( nCharSet ), ;
      af[ 6 ], nCharSet ), af[ 7 ], af[ 8 ], af[ 9 ], af[ 1 ] )

METHOD SetFontStyle( lBold, nCharSet, lItalic, lUnder, lStrike, nHeight ) CLASS HFont

   LOCAL  weight, Italic, Underline, StrikeOut

   IF lBold != Nil
      weight = iif( lBold, FW_BOLD, FW_REGULAR )
   ELSE
      weight := ::weight
   ENDIF
   Italic    := iif( lItalic = Nil, ::Italic, iif( lItalic, 1, 0 ) )
   Underline := iif( lUnder  = Nil, ::Underline, iif( lUnder , 1, 0 ) )
   StrikeOut := iif( lStrike = Nil, ::StrikeOut, iif( lStrike , 1, 0 ) )
   nheight   := iif( nheight = Nil, ::height, nheight )
   nCharSet  := iif( nCharSet = Nil, ::CharSet, nCharSet )

   RETURN HFont():Add( ::name, ::width, nheight, weight, ;
      nCharSet, Italic, Underline, StrikeOut ) // ::handle )

METHOD RELEASE() CLASS HFont

   LOCAL i, nlen := Len( ::aFonts )

   ::nCounter --
   IF ::nCounter == 0
      FOR i := 1 TO nlen
         IF ::aFonts[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aFonts, i )
            ASize( ::aFonts, nlen - 1 )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

   /* DF7BE: For debugging purposes */

METHOD PrintFont()  CLASS HFont

   //        fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut
   // Type:  C         N       N         N         N           N          N             N
   // - 9999 means NIL

   LOCAL fontName , nWidth , nHeight , fnWeight , fdwCharSet , fdwItalic , fdwUnderline , fdwStrikeOut

   fontName     := iif( ::name == NIL , "<Empty>", ::name )
   nWidth       := iif( ::width == Nil, - 9999 , ::width )
   nHeight      := iif( ::height == NIL , - 9999 , ::height )
   fnWeight     := iif( ::weight == Nil, - 9999 , ::weight )
   fdwCharSet   := iif( ::CharSet == Nil, - 9999 , ::CharSet )
   fdwItalic    := iif( ::Italic == Nil, - 9999 , ::Italic )
   fdwUnderline := iif( ::Underline == Nil, - 9999 , ::Underline )
   fdwStrikeOut := iif( ::StrikeOut == Nil, - 9999 , ::StrikeOut )

   RETURN "Font Name=" + fontName + " Width=" + AllTrim( Str( nWidth ) ) + " Height=" + AllTrim( Str( nHeight ) ) + ;
      " Weight=" + AllTrim( Str( fnWeight ) ) + " CharSet=" + AllTrim( Str( fdwCharSet ) ) + ;
      " Italic=" + AllTrim( Str( fdwItalic ) ) + " Underline=" + AllTrim( Str( fdwUnderline ) ) + ;
      " StrikeOut=" + AllTrim( Str( fdwStrikeOut ) )


/*
  Returns an array with font properties (for creating a copy of a font entry)
  Copy sample
   apffrarr := oFont1:Props2Arr()
   oFont2 := HFont():Add( apffrarr[1], apffrarr[2], apffrarr[3], apffrarr[4], apffrarr[5], ;
                apffrarr[6], apffrarr[7], apffrarr[8] )
 */

METHOD Props2Arr() CLASS HFont

   //        fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut
   //        1         2       3         4         5           6          7             8
   LOCAL fontName , nWidth , nHeight , fnWeight , fdwCharSet , fdwItalic , fdwUnderline , fdwStrikeOut
   LOCAL aFontprops := {}

   fontName     := iif( ::name == NIL , "<Empty>", ::name )
   nWidth       := iif( ::width == Nil, - 9999 , ::width )
   nHeight      := iif( ::height == NIL , - 9999 , ::height )
   fnWeight     := iif( ::weight == Nil, - 9999 , ::weight )
   fdwCharSet   := iif( ::CharSet == Nil, - 9999 , ::CharSet )
   fdwItalic    := iif( ::Italic == Nil, - 9999 , ::Italic )
   fdwUnderline := iif( ::Underline == Nil, - 9999 , ::Underline )
   fdwStrikeOut := iif( ::StrikeOut == Nil, - 9999 , ::StrikeOut )

   AAdd ( aFontprops, fontName )  // C
   AAdd ( aFontprops, nWidth )    // all other of type N
   AAdd ( aFontprops, nHeight )
   AAdd ( aFontprops, fnWeight )
   AAdd ( aFontprops, fdwCharSet )
   AAdd ( aFontprops, fdwItalic )
   AAdd ( aFontprops, fdwUnderline )
   AAdd ( aFontprops, fdwStrikeOut )

   RETURN aFontprops

   //- HPen

CLASS HPen INHERIT HObject

   CLASS VAR aPens   INIT {}
   DATA handle
   DATA style, width, color
   DATA nCounter   INIT 1

   METHOD Add( nStyle, nWidth, nColor )
   METHOD Get( nStyle, nWidth, nColor )
   METHOD RELEASE()

ENDCLASS

METHOD Add( nStyle, nWidth, nColor ) CLASS HPen

   LOCAL i

   nStyle := iif( nStyle == Nil, BS_SOLID, nStyle )
   nWidth := iif( nWidth == Nil, 1, nWidth )
   IF nStyle != BS_SOLID
      nWidth := 1
   ENDIF
   nColor := iif( nColor == Nil, 0, nColor )

   FOR EACH i IN ::aPens
      IF i:style == nStyle .AND. ;
            i:width == nWidth .AND. ;
            i:color == nColor

         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   ::handle := hwg_Createpen( nStyle, nWidth, nColor )
   ::style  := nStyle
   ::width  := nWidth
   ::color  := nColor
   AAdd( ::aPens, Self )

   RETURN Self

METHOD Get( nStyle, nWidth, nColor ) CLASS HPen

   LOCAL i

   nStyle := iif( nStyle == Nil, PS_SOLID, nStyle )
   nWidth := iif( nWidth == Nil, 1, nWidth )
   IF nStyle != BS_SOLID
      nWidth := 1
   ENDIF
   nColor := iif( nColor == Nil, 0, nColor )

   FOR EACH i IN ::aPens
      IF i:style == nStyle .AND. ;
            i:width == nWidth .AND. ;
            i:color == nColor

         RETURN i
      ENDIF
   NEXT

   RETURN Nil

METHOD RELEASE() CLASS HPen

   LOCAL i, nlen := Len( ::aPens )

   ::nCounter --
   IF ::nCounter == 0
      FOR i := 1 TO nlen
         IF ::aPens[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aPens, i )
            ASize( ::aPens, nlen - 1 )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

   //- HBrush

CLASS HBrush INHERIT HObject

   CLASS VAR aBrushes   INIT {}
   DATA handle
   DATA COLOR
   DATA nHatch   INIT 99
   DATA nCounter INIT 1

   METHOD Add( nColor, nHatch )
   METHOD RELEASE()

ENDCLASS

METHOD Add( nColor, nHatch ) CLASS HBrush

   LOCAL i

   IF nHatch == Nil
      nHatch := 99
   ENDIF

   FOR EACH i IN ::aBrushes

      IF i:color == nColor .AND. i:nHatch == nHatch
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   IF nHatch != 99
      ::handle := hwg_Createhatchbrush( nHatch, nColor )
   ELSE
      ::handle := hwg_Createsolidbrush( nColor )
   ENDIF
   ::color  := nColor
   AAdd( ::aBrushes, Self )

   RETURN Self

METHOD RELEASE() CLASS HBrush

   LOCAL i, nlen := Len( ::aBrushes )

   ::nCounter --
   IF ::nCounter == 0
      FOR i := 1 TO nlen
         IF ::aBrushes[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aBrushes, i )
            ASize( ::aBrushes, nlen - 1 )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

   //- HBitmap

CLASS HBitmap INHERIT HObject

   CLASS VAR cPath SHARED
   CLASS VAR aBitmaps   INIT {}
   CLASS VAR lSelFile   INIT .F.
   DATA handle
   DATA name
   DATA nFlags
   DATA nTransparent    INIT - 1
   DATA nWidth, nHeight
   DATA nCounter   INIT 1

   METHOD AddResource( name, nFlags, lOEM, nWidth, nHeight )
   METHOD AddStandard( nId )
   METHOD AddFile( name, hDC, lTransparent, nWidth, nHeight )
   METHOD AddString( name, cVal , nWidth, nHeight )
   METHOD AddWindow( oWnd, x1, y1, width, height )
   METHOD Draw( hDC, x1, y1, width, height )
   METHOD RELEASE()
   METHOD OBMP2FILE( cfilename , name )

ENDCLASS

/*
 Stores a bitmap in a file from object
*/

METHOD OBMP2FILE( cfilename , name ) CLASS HBitmap

   LOCAL i , hbmp
   // LOCAL j, ncoun  && Debug

   hbmp := NIL
   // Search for bitmap in object
   FOR EACH i IN ::aBitmaps
      IF i:name == name
         hbmp := i:handle
      ELSE
         // not found
//         hwg_writelog("Bitmap " + name + "not found")
//         ncoun := 0
//         * Write out table of contents (TOC)
//         FOR EACH j IN ::aBitmaps
//          ncoun := ncoun  + 1
//          hwg_writelog(ALLTRIM(STR(ncoun)) + ": " + ::name)
//         NEXT
         RETURN NIL
      ENDIF
   NEXT

   hwg_SaveBitMap( cfilename, hbmp )

   RETURN NIL

METHOD AddResource( name, nFlags, lOEM, nWidth, nHeight ) CLASS HBitmap

   LOCAL lPreDefined := .F. , i, aBmpSize, oResCnt

   IF nFlags == nil
      nFlags := LR_DEFAULTCOLOR
   ENDIF
   IF lOEM == nil
      lOEM := .F.
   ENDIF
   IF ValType( name ) == "N"
      name := LTrim( Str( name ) )
      lPreDefined := .T.
   ENDIF
   FOR EACH i IN ::aBitmaps
      IF i:name == name .AND. i:nFlags == nFlags .AND. ;
            ( ( nWidth == nil .OR. nHeight == nil ) .OR. ;
            ( i:nWidth == nWidth .AND. i:nHeight == nHeight ) )
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   IF !Empty( oResCnt := hwg_GetResContainer() )
      IF !Empty( i := oResCnt:Get( name ) )
         ::handle := hwg_OpenImage( i, .T. )
      ENDIF
   ELSEIF lOEM
      ::handle := hwg_Loadimage( 0, Val( name ), IMAGE_BITMAP, nil, nil, Hwg_bitor( nFlags, LR_SHARED ) )
   ELSE
      ::handle := hwg_Loadimage( nil, iif( lPreDefined, Val( name ), name ), IMAGE_BITMAP, nWidth, nHeight, nFlags )
   ENDIF
   IF Empty( ::handle )
      RETURN Nil
   ENDIF
   ::name    := name
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   ::nFlags  :=  nFlags
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD AddStandard( nId ) CLASS HBitmap

   LOCAL i, aBmpSize, name := "s" + LTrim( Str( nId ) )

   FOR EACH i  IN  ::aBitmaps
      IF i:name == name
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   ::handle := hwg_Loadbitmap( nId, .T. )
   IF Empty( ::handle )
      RETURN Nil
   ENDIF
   ::name   := name
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD AddFile( name, hDC, lTransparent, nWidth, nHeight ) CLASS HBitmap

   LOCAL i, aBmpSize, cname := CutPath( name ), cCurDir

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF

   FOR EACH i IN ::aBitmaps
      IF i:name == cname && .AND. ( nWidth == Nil .OR. nHeight == Nil )
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   name := AddPath( name, ::cPath )
   name := iif( ! File( name ) .AND. File( cname ), cname, name )
   IF ::lSelFile .AND. !File( name )
      cCurDir  := DiskName() + ':\' + CurDir()
      name := hwg_Selectfile( "Image Files( *.jpg;*.gif;*.bmp;*.ico )", CutPath( name ), FilePath( name ), "Locate " + name ) //"*.jpg;*.gif;*.bmp;*.ico"
      DirChange( cCurDir )
   ENDIF

   IF Lower( Right( name, 4 ) ) != ".bmp" .OR. ( nWidth == nil .AND. nHeight == nil .AND. lTransparent == Nil )
      IF Lower( Right( name, 4 ) ) == ".bmp"
         ::handle := hwg_Openbitmap( name, hDC )
      ELSE
         IF Empty( ::handle := hwg_Openimage( name ) )
            ::handle := hwg_GdiplusOpenimage( name )
         ENDIF
      ENDIF
   ELSE
      IF lTransparent != Nil .AND. lTransparent
         ::handle := hwg_Loadimage( nil, name, IMAGE_BITMAP, nWidth, nHeight, LR_LOADFROMFILE + LR_LOADTRANSPARENT + LR_LOADMAP3DCOLORS )
      ELSE
         ::handle := hwg_Loadimage( nil, name, IMAGE_BITMAP, nWidth, nHeight, LR_LOADFROMFILE )
      ENDIF
   ENDIF
   IF Empty( ::handle )
      RETURN Nil
   ENDIF
   ::name := cname
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   // ::name is here the filename
   // hwg_Writelog("nWidth=" + ALLTRIM(STR(:: nWidth)) + ;
   //            " nHeight="  + ALLTRIM(STR(::nHeight)) + ;
   //            " name=" +  ::name )

   RETURN Self

METHOD AddString( name, cVal , nWidth, nHeight ) CLASS HBitmap

   LOCAL oBmp, aBmpSize

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF

   For EACH oBmp IN ::aBitmaps
      IF oBmp:name == name
         oBmp:nCounter ++
         RETURN oBmp
      ENDIF
   NEXT

   /* DF7BE: Open of de.bmp fails here */
   ::handle := hwg_Openimage( cVal, .T. )
   IF !Empty( ::handle )
      ::name := name
      aBmpSize  := hwg_Getbitmapsize( ::handle )
      ::nWidth  := aBmpSize[1]
      ::nHeight := aBmpSize[2]
      AAdd( ::aBitmaps, Self )
   ELSE
      RETURN Nil
   ENDIF

   RETURN Self

METHOD AddWindow( oWnd, x1, y1, width, height ) CLASS HBitmap

   LOCAL aBmpSize

   IF x1 == Nil .OR. y1 == Nil
      x1 := 0; y1 := 0; width := oWnd:nWidth - 1; height := oWnd:nHeight - 1
   ENDIF

   ::handle := hwg_Window2bitmap( oWnd:handle, x1, y1, width, height )
   ::name := LTrim( hb_valToStr( oWnd:handle ) )
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD Draw( hDC, x1, y1, width, height ) CLASS HBitmap

   IF ::nTransparent < 0
      hwg_Drawbitmap( hDC, ::handle, , x1, y1, width, height )
   ELSE
      hwg_Drawtransparentbitmap( hDC, ::handle, x1, y1, ::nTransparent )
   ENDIF

   RETURN Nil

METHOD RELEASE() CLASS HBitmap

   LOCAL i, nlen := Len( ::aBitmaps )

   ::nCounter --
   IF ::nCounter == 0
      FOR i := 1 TO nlen
         IF ::aBitmaps[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aBitmaps, i )
            ASize( ::aBitmaps, nlen - 1 )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

   //- HIcon

CLASS HIcon INHERIT HObject

   CLASS VAR cPath SHARED
   CLASS VAR aIcons     INIT {}
   CLASS VAR lSelFile   INIT .F.
   DATA handle
   DATA name
   DATA nWidth, nHeight
   DATA nCounter   INIT 1

   METHOD AddResource( name, nWidth, nHeight, nFlags, lOEM )
   METHOD AddFile( name, nWidth, nHeight )
   METHOD AddString( name, cVal , nWidth, nHeight )
   METHOD Draw( hDC, x, y )   INLINE hwg_DrawiconEx( hDC, ::handle, x, y )
   METHOD RELEASE()
   // PNG support prepared for further Windows releases
   METHOD AddPngString( name, cVal )
   METHOD AddPngFile( name , nWidth, nHeight )   // Not used: nWidth, nHeight)

ENDCLASS

METHOD AddResource( name, nWidth, nHeight, nFlags, lOEM ) CLASS HIcon

   LOCAL lPreDefined := .F. , i, aIconSize, oResCnt

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF
   IF nFlags == nil
      nFlags := 0
   ENDIF
   IF lOEM == nil
      lOEM := .F.
   ENDIF
   // hwg_writelog( "HIcon:AddResource " + Str(nWidth)+"/"+str(nHeight) )
   IF ValType( name ) == "N"
      name := LTrim( Str( name ) )
      lPreDefined := .T.
   ENDIF
   FOR EACH i IN ::aIcons
      IF i:name == name
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT
   IF !Empty( oResCnt := hwg_GetResContainer() )
      IF !Empty( i := oResCnt:Get( name ) )
         ::handle := hwg_OpenImage( i, .T. , IMAGE_CURSOR )
         //hwg_writelog( Str(Len(i))+"/"+Iif(Empty(::handle),"Err","Ok") )
      ENDIF
   ELSEIF lOEM // LR_SHARED is required for OEM images
      ::handle := hwg_Loadimage( 0, Val( name ), IMAGE_ICON, nWidth, nHeight, Hwg_bitor( nFlags, LR_SHARED ) )
   ELSE
      ::handle := hwg_Loadimage( nil, iif( lPreDefined, Val( name ), name ), IMAGE_ICON, nWidth, nHeight, nFlags )
   ENDIF
   IF Empty( ::handle )
      RETURN Nil
   ENDIF
   ::name   := name
   aIconSize := hwg_Geticonsize( ::handle )
   ::nWidth  := aIconSize[ 1 ]
   ::nHeight := aIconSize[ 2 ]
   //hwg_writelog( Str(::nWidth)+"/"+str(::nHeight) )

   AAdd( ::aIcons, Self )

   RETURN Self


 /* Added by DF7BE
 name : Name of resource
 cVal : Binary contents of *.ico file
 */

METHOD AddString( name, cVal , nWidth, nHeight ) CLASS HIcon

   LOCAL cTmp    // , oreturn
   LOCAL aIconSize

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF

   // Write contents into temporary file
   hb_memowrit( cTmp := hwg_CreateTempfileName( , ".ico" ) , cVal )
   // Load icon from temporary file
   ::handle := hwg_Loadimage( 0, cTmp, IMAGE_ICON, nWidth, nHeight, LR_DEFAULTSIZE + LR_LOADFROMFILE + LR_SHARED )
   ::name := name
   aIconSize := hwg_Geticonsize( ::handle )
   ::nWidth  := aIconSize[ 1 ]
   ::nHeight := aIconSize[ 2 ]

   AAdd( ::aIcons, Self )

   // oreturn := ::AddFile( name )
   FErase( cTmp )

   RETURN  Self   // oreturn

   /* Added by DF7BE Sept. 2022 */

METHOD AddPngString( name, cVal ) CLASS HIcon

   // Not used :  nWidth, nHeight
   LOCAL cTmp
   LOCAL aIconSize

/*
   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF
*/
   // Write contents into temporary file
   hb_memowrit( cTmp := hwg_CreateTempfileName( , ".png" ) , cVal )
   // Load PNG from temporary file
   ::handle :=  HWG_LOADPNG( 0, cTmp )
   ::name := name
   aIconSize := hwg_Geticonsize( ::handle )
   ::nWidth  := aIconSize[ 1 ]
   ::nHeight := aIconSize[ 2 ]

   AAdd( ::aIcons, Self )

   // oreturn := ::AddFile( name )
   FErase( cTmp )

   RETURN  Self

METHOD AddPngFile( name , nWidth, nHeight ) CLASS HIcon

   // Not used: nWidth, nHeight

   LOCAL i, aIconSize, cname := CutPath( name ), cCurDir, cFext


   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF

   FOR EACH i IN  ::aIcons
      IF i:name == cname .AND. ( nWidth == Nil .OR. i:nWidth == nWidth ) ;
            .AND. ( nHeight == Nil .OR. i:nHeight == nHeight )
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   name := AddPath( name, ::cPath )
   name := iif( ! File( name ) .AND. File( cname ), cname, name )
   IF ::lSelFile .AND. !File( name )
      cCurDir  := DiskName() + ':\' + CurDir()
      name := hwg_Selectfile( "Image Files( *.jpg;*.gif;*.bmp;*.ico )", CutPath( name ), FilePath( name ), "Locate " + name ) //"*.jpg;*.gif;*.bmp;*.ico"
      DirChange( cCurDir )
   ENDIF
#ifdef __XHARBOUR__
   hb_FNameSplit( name, , , @cFext )
#else
   cFext := hb_fNameExt( name )
#endif
   IF Empty( cFext )
      name += ".png"
   ENDIF
   ::handle := HWG_LOADPNG( 0, name )
   // ::handle := hwg_Loadimage( 0, name, IMAGE_ICON, nWidth, nHeight, LR_DEFAULTSIZE + LR_LOADFROMFILE + LR_SHARED )
   ::name := cname
   aIconSize := hwg_Geticonsize( ::handle )
   ::nWidth  := aIconSize[ 1 ]
   ::nHeight := aIconSize[ 2 ]

   AAdd( ::aIcons, Self )

   RETURN Self

METHOD AddFile( name, nWidth, nHeight ) CLASS HIcon

   LOCAL i, aIconSize, cname := CutPath( name ), cCurDir, cFext

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF
   FOR EACH i IN  ::aIcons
      IF i:name == cname .AND. ( nWidth == Nil .OR. i:nWidth == nWidth ) ;
            .AND. ( nHeight == Nil .OR. i:nHeight == nHeight )
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   name := AddPath( name, ::cPath )
   name := iif( ! File( name ) .AND. File( cname ), cname, name )
   IF ::lSelFile .AND. !File( name )
      cCurDir  := DiskName() + ':\' + CurDir()
      name := hwg_Selectfile( "Image Files( *.jpg;*.gif;*.bmp;*.ico )", CutPath( name ), FilePath( name ), "Locate " + name ) //"*.jpg;*.gif;*.bmp;*.ico"
      DirChange( cCurDir )
   ENDIF
#ifdef __XHARBOUR__
   hb_FNameSplit( name, , , @cFext )
#else
   cFext := hb_fNameExt( name )
#endif
   IF Empty( cFext )
      name += ".ico"
   ENDIF
   ::handle := hwg_Loadimage( 0, name, IMAGE_ICON, nWidth, nHeight, LR_DEFAULTSIZE + LR_LOADFROMFILE + LR_SHARED )
   ::name := cname
   aIconSize := hwg_Geticonsize( ::handle )
   ::nWidth  := aIconSize[ 1 ]
   ::nHeight := aIconSize[ 2 ]

   AAdd( ::aIcons, Self )

   RETURN Self

METHOD RELEASE() CLASS HIcon

   LOCAL i, nlen := Len( ::aIcons )

   ::nCounter --
   IF ::nCounter == 0
      FOR i := 1 TO nlen
         IF ::aIcons[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aIcons, i )
            ASize( ::aIcons, nlen - 1 )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

CLASS HStyle INHERIT HObject

   CLASS VAR aStyles   INIT {}

   DATA id
   DATA nOrient
   DATA aColors
   DATA oBitmap
   DATA nBmpStyle
   DATA nBorder
   DATA tColor
   DATA oPen
   DATA aCorners

   METHOD New( aColors, nOrient, aCorners, nBorder, tColor, oBitmap, nBmpStyle )
   METHOD Draw( hDC, nLeft, nTop, nRight, nBottom )

ENDCLASS

METHOD New( aColors, nOrient, aCorners, nBorder, tColor, oBitmap, nBmpStyle ) CLASS HStyle

   LOCAL i, nlen := Len( ::aStyles )

   nBorder := iif( nBorder == Nil, 0, nBorder )
   tColor := iif( tColor == Nil, 0, tColor )
   nOrient := iif( nOrient == Nil .OR. nOrient > 9, 1, nOrient )

   FOR i := 1 TO nlen
      IF hwg_aCompare( ::aStyles[i]:aColors, aColors ) .AND. ;
            hwg_aCompare( ::aStyles[i]:aCorners, aCorners ) .AND. ;
            ValType( ::aStyles[i]:tColor ) == ValType( tColor ) .AND. ;
            ::aStyles[i]:nBorder == nBorder .AND. ;
            ::aStyles[i]:tColor == tColor .AND. ;
            ::aStyles[i]:nOrient == nOrient .AND. ;
            ( ( ::aStyles[i]:oBitmap == Nil .AND. oBitmap == Nil ) .OR. ;
            ( ::aStyles[i]:oBitmap != Nil .AND. oBitmap != Nil .AND. ::aStyles[i]:oBitmap:name == oBitmap:name ) )

         RETURN ::aStyles[i]
      ENDIF
   NEXT

   ::aColors  := aColors
   ::nOrient  := nOrient
   ::nBorder  := nBorder
   ::tColor   := tColor
   ::aCorners := aCorners
   ::oBitmap := oBitmap
   ::nBmpStyle := iif( nBmpStyle == Nil, BMP_DRAW_SPREAD, nBmpStyle )
   IF nBorder > 0
      ::oPen := HPen():Add( BS_SOLID, nBorder, tColor )
   ENDIF

   AAdd( ::aStyles, Self )
   ::id := Len( ::aStyles )

   RETURN Self

METHOD Draw( hDC, nLeft, nTop, nRight, nBottom ) CLASS HStyle

   LOCAL n1, n2

   IF ::oBitmap == Nil
      hwg_drawGradient( hDC, nLeft, nTop, nRight, nBottom, ::nOrient, ::aColors, , ::aCorners )
   ELSEIF ::nBmpStyle == BMP_DRAW_CENTER
      n1 := Round( ( nRight - nLeft - ::oBitmap:nWidth ) / 2, 0 )
      n2 := Round( ( nBottom - nTop - ::oBitmap:nHeight ) / 2, 0 )
      hwg_Drawbitmap( hDC, ::oBitmap:handle, , n1, n2, ::oBitmap:nWidth, ::oBitmap:nHeight )
   ELSEIF ::nBmpStyle == BMP_DRAW_FULL
      hwg_Drawbitmap( hDC, ::oBitmap:handle, , nLeft, nTop, nRight - nLeft + 1, nBottom - nTop + 1 )
   ELSE
      hwg_SpreadBitmap( hDC, ::oBitmap:handle, nLeft, nTop, nRight, nBottom )
   ENDIF
   IF !Empty( ::oPen )
      n2 := ::nBorder/2
      n1 := Int( n2 )
      IF n2 - n1 > 0.1
         n2 := n1 + 1
      ENDIF
      hwg_Selectobject( hDC, ::oPen:handle )
      hwg_Rectangle( hDC, nLeft + n1, nTop + n1, nRight - n2, nBottom - n2 )
   ENDIF

   RETURN Nil

FUNCTION hwg_aCompare( arr1, arr2 )

   LOCAL i, nLen

   IF arr1 == Nil .AND. arr2 == Nil
      RETURN .T.
   ELSEIF ValType( arr1 ) == ValType( arr2 ) .AND. ValType( arr1 ) == "A" ;
         .AND. ( nLen := Len( arr1 ) ) == Len( arr2 )
      FOR i := 1 TO nLen
         IF !( ValType( arr1[i] ) == ValType( arr2[i] ) ) .OR. !( arr1[i] == arr2[i] )
            RETURN .F.
         ENDIF
      NEXT
      RETURN .T.
   ENDIF

   RETURN .F.

FUNCTION hwg_BmpFromRes( cBmp )

   LOCAL handle, cBuff, oResCnt

   IF !Empty( oResCnt := hwg_GetResContainer() )
      IF !Empty( cBuff := oResCnt:Get( cBmp ) )
         handle := hwg_OpenImage( cBuff, .T. )
      ENDIF
   ELSE
      handle := hwg_Loadbitmap( cBmp )
   ENDIF

   RETURN handle

   EXIT PROCEDURE CleanDrawWidg
   LOCAL i, oResCnt

   FOR i := 1 TO Len( HPen():aPens )
      hwg_Deleteobject( HPen():aPens[i]:handle )
   NEXT
   FOR i := 1 TO Len( HBrush():aBrushes )
      hwg_Deleteobject( HBrush():aBrushes[i]:handle )
   NEXT
   FOR i := 1 TO Len( HFont():aFonts )
      hwg_Deleteobject( HFont():aFonts[i]:handle )
   NEXT
   FOR i := 1 TO Len( HBitmap():aBitmaps )
      hwg_Deleteobject( HBitmap():aBitmaps[i]:handle )
   NEXT
   FOR i := 1 TO Len( HIcon():aIcons )
      hwg_Deleteobject( HIcon():aIcons[i]:handle )
   NEXT
   IF !Empty( oResCnt := hwg_GetResContainer() )
      oResCnt:Close()
   ENDIF

   RETURN

/*
   DF7BE: only needed for WinAPI, on GTK/LINUX charset is UTF-8 forever.
   All other attributes are not modified.
 */

FUNCTION hwg_FontSetCharset ( oFont, nCharSet  )
   LOCAL i, nlen := Len( oFont:aFonts )

   IF nCharSet == NIL .OR. nCharSet == - 1
      RETURN oFont
   ENDIF

   oFont:charset := nCharSet

   FOR i := 1 TO nlen
      oFont:aFonts[i]:CharSet := nCharSet
   NEXT

   RETURN oFont

FUNCTION hwg_LoadCursorFromString( cVal, nx , ny )
   LOCAL cTmp , hCursor

   // Parameter x and y not used on WinApi
   HB_SYMBOL_UNUSED( nx )
   HB_SYMBOL_UNUSED( ny )

   // Write contents into temporary file
   hb_memowrit( cTmp := hwg_CreateTempfileName( , ".cur" ) , cVal )
   // Load cursor from temporary file
   hCursor := hwg_LoadCursorFromFile( cTmp ) // for GTK add parameters nx, ny
   FErase( cTmp )

   RETURN hCursor
