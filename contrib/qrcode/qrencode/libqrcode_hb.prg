*
* libqrcode_hb.prg
*
* $Id$
*
*
*
* HWGUI - Harbour Win32, LINUX and MacOS library source code:
* Collection of functions encoding QR codes in a
* Harbour console application (for example for batch usage)
*
* Copyright 2023 Alexander S.Kresin <alex@kresin.ru>
* www - http://www.kresin.ru
*
* Copyright 2025 Wilfried Brunken, DF7BE 
* https://sourceforge.net/projects/cllog/
*
* License:
* GNU General Public License V2.
* As a special exception, you have permission for
* additional uses of the text contained in its release of HWGUI.
*
* For Details, see file
* license.txt 
*
*
* Function list:
*
* HWG_QRENCODE(ctext,cbitmapfile,nzoomf)   && Function to call from main.
*                                          && Creates the QR code and write to bitmap file.
*                                          && It is the "user interface".
*                                          && Returns the bitmap binary image of type C.
*                                          && Do not use for DLL.
*
*                                          && ctext        : The text to convert to QR code
*                                          && nzoomf       : The zoom factor, default is 3
*
*  hwg_CBmp2file(cbitmap,cbitmapfile)      && Write the bitmap binary image of type C to file.
*                                          && cbitmapfile  : The bitmap file name
*                                          && containing the QR code, with extension ".bmp"
*                                          && For compatibilty with UNIX/LINUX and MacOS,
*                                          && use file name always in lower case.
*
*
* hwg_QRCodeTxtGen() found in qrencode.c
*
* Copied from common.prg:
* hwg_QRCodeZoom()
* hwg_QRCodeAddBorder()
* hwg_QRCodetxt2BPM()
* hwg_QRCodeGetSize()
*
* Other functions from misc.c,draw.c, hmisccross.prg
*
* HWG_BMPNEWIMAGE()
* HWG_BMPDESTROY()
* hwg_BMPSetMonochromePalette ( from common.prg )
* HWG_QR_SETPIXEL()
* hwg_BMPFileSizeC()
* hwg_BMPNewImageC
* HWG_SETBITBYTE()
* HWG_BITOR_INT
* HWG_BMPCALCOFFSPAL()
* HWG_CHANGECHARINSTRING()
* HWG_BMPCALCOFFSPIXARR()
* HWG_BMPLINESIZE()
* HWG_SETBITBYTE()
*
*
* For detailed function description see 
* function description HTML document of HWGUI.
*
* Need to request in main function:
* REQUEST HB_CODEPAGE_DEWIN
* * Set "_DEWIN" to your language setting on Windows
* For list of supported codepages see Harbour inlcude file:
* include\hbcpage.hbx
*
* REQUEST HB_CODEPAGE_UTF8
* #ifndef __PLATFORM__WINDOWS
*  REQUEST HB_CODEPAGE_UTF8EX
* #endif
*
* For Debug purposes uncomment the lines
* with the MEMOWRIT() function to look
* for correct codepage conversion on Windows.  

#include "hbextcdp.ch"

FUNCTION HWG_QRENCODE(ctext,nzoomf)

   LOCAL cqrc, cbitmap

  IF ( ctext == NIL )
   * nothing to do
    RETURN NIL
  ENDIF 
  
  IF nzoomf == NIL
     nzoomf := 3
  ENDIF


   // cqrc := hwg_QRCodeTxtGen("https://www.darc.de",1)

   cqrc := hwg_QRCodeTxtGen( ctext, 1 )


   cqrc := hwg_QRCodeZoom( cqrc, nzoomf )

   
   * Add border 10 pixels
   cqrc := hwg_QRCodeAddBorder(cqrc,10)

   * Final crrating of bitmap with QR code 
   cbitmap := hwg_QRCodetxt2BPM( cqrc )


RETURN cbitmap


FUNCTION hwg_CBmp2file(cbitmap,cbitmapfile)

IF cbitmap == NIL
 RETURN NIL
ENDIF

IF cbitmapfile == NIL
 cbitmapfile := "bitmap.bmp"
ENDIF 

   MEMOWRIT( cbitmapfile, cbitmap )
RETURN NIL



FUNCTION hwg_QRCodeZoom( cqrcode, nzoom )

   LOCAL cBMP, cLine, i , j
   LOCAL leofq

   IF nzoom == NIL
      nzoom := 1
   ENDIF

   IF nzoom < 1
      RETURN cqrcode
   ENDIF

   cBMP  := ""
   cLine := ""

   leofq := .F.
   // i:        Position in cqrcode

   FOR i := 1 TO Len( cqrcode )
      IF .NOT. leofq
         IF SubStr( cqrcode, i, 1 ) == Chr( 10 )
            IF .NOT. ( SubStr( cqrcode, i + 1 , 1 ) == " " )
               // Empty line following, stop here
               leofq := .T.
            ENDIF
            // Count line ending and start with new line

            // Replicate line with zoom factor
            FOR j := 1 TO nzoom
               cBMP  := cBMP + cLine + Chr( 10 )
            NEXT
            //
            cLine := ""
         ELSE  // SUBSTR " "
            cLine := cLine + Replicate( SubStr( cqrcode,i,1 ), nzoom )
         ENDIF // is CHR(10)
      ENDIF // .NOT. leofq

   NEXT

   IF .NOT. Empty( cLine )
      cBMP  := cBMP + cLine + Chr( 10 )
   ENDIF

   // Empty line as mark for EOF
   cBMP  := cBMP + Chr( 10 )

   RETURN cBMP

   // ====
   // Add border to QR code image
   // cqrcode : The QR code in text format
   // nborder : The number of border pixels to add 1 ... n
   // Return the new QR code text string

FUNCTION hwg_QRCodeAddBorder( cqrcode, nborder )

   LOCAL cBMP,  i , nx , cLine , cLineOut
   LOCAL leofq

   IF nborder == NIL
      RETURN cqrcode
   ENDIF

   IF nborder < 1
      RETURN cqrcode
   ENDIF

   cBMP  := ""
   cLineOut := ""

   leofq := .F.
   // i:        Position in cqrcode

   // Add nborder lines to begin
   // Preread first line getting the x size of the QR code
   nx := At( Chr( 10 ), cqrcode )
   cLine := Space( nx + nborder + nborder - 1 ) + Chr( 10 ) // Empty line new
   FOR i := 1 TO nborder
      cBMP  := cBMP + cLine
   NEXT

   FOR i := 1 TO Len( cqrcode )
      IF .NOT. leofq
         IF SubStr( cqrcode, i, 1 ) == Chr( 10 )
            IF .NOT. ( SubStr( cqrcode, i + 1 , 1 ) == " " )
               // Empty line following, stop here
               leofq := .T.
            ENDIF
            // Count line ending and start with new line
            cBMP := cBMP + Space( nborder ) + cLineOut + Space( nborder ) + Chr( 10 )
            cLineOut := ""
         ELSE  // SUBSTR " "
            cLineOut := cLineOut + SubStr( cqrcode, i, 1 )
         ENDIF // is CHR(10)
      ENDIF // .NOT. leofq

   NEXT

   FOR i := 1 TO nborder
      cBMP  := cBMP + cLine
   NEXT

   RETURN cBMP

   // Get the size of a QR code
   // Returns an array with 2 elements: xSize,ySize

FUNCTION hwg_QRCodeGetSize( cqrcode )

   LOCAL aret, xSize, ySize, i, leofq

   aret := {}
   ySize := 0
   leofq := .F.

   xSize := At( Chr( 10 ), cqrcode )

   FOR i := 1 TO Len( cqrcode )
      IF .NOT. leofq
         IF SubStr( cqrcode, i, 1 ) == Chr( 10 )
            IF .NOT. ( SubStr( cqrcode, i + 1 , 1 ) == " " )
               // Empty line following, stop here
               leofq := .T.
            ENDIF
            // Count lines
            ySize := ySize + 1
         ENDIF // is CHR(10)
      ENDIF // .NOT. leofq
   NEXT

   AAdd( aret, xSize )
   AAdd( aret, ySize )

   RETURN aret

   /* Convert QR code to bitmap */

FUNCTION hwg_QRCodetxt2BPM( cqrcode )

   LOCAL cBMP , nlines, ncol , x , i , n
   LOCAL leofq

   IF cqrcode == NIL
      RETURN ""
   ENDIF

   // Count the columns in QR code text string
   // ( Appearance of line end in first line )
   ncol   := At( Chr( 10 ), cqrcode ) - 1

   // Count the lines in QR code text string
   // Suppress empty lines

   leofq := .F.
   nlines := 0
   FOR i := 1 TO Len( cqrcode )
      IF .NOT. leofq
         IF SubStr( cqrcode, i, 1 ) == Chr( 10 )
            IF .NOT. ( SubStr( cqrcode, i + 1 , 1 ) == " " )
               // Empty line following, stop here
               leofq := .T.
            ELSE
               // Count line ending
               nlines := nlines + 1
            ENDIF
         ENDIF
      ENDIF

   NEXT

   // Based on this, calculate the bitmap size
   nlines := nlines + 1

   // Create the bitmap template and set monochrome palette
   cBMP := HWG_BMPNEWIMAGE( ncol, nlines, 1, 2, 2835, 2835 )
   HWG_BMPDESTROY()
   cBMP := hwg_BMPSetMonochromePalette( cBMP )

   // Convert to bitmap

   leofq := .F.
   // i:        Position in cqrcode
   n := 1   // Line
   x := 0   // Column
   FOR i := 1 TO Len( cqrcode )
      x := x + 1
      IF .NOT. leofq
         IF SubStr( cqrcode, i, 1 ) == Chr( 10 )
            IF .NOT. ( SubStr( cqrcode, i + 1 , 1 ) == " " )
               // Empty line following, stop here
               leofq := .T.
            ENDIF
            // Count line ending and start with new line
            n := n + 1
            x := 0
         ELSE  // SUBSTR " "
            IF SubStr( cqrcode, i, 1 ) == "#"
               cBMP := hwg_QR_SetPixel( cBMP, x, n, ncol, nlines )
            ENDIF  // #
         ENDIF // is CHR(10)
      ENDIF // .NOT. leofq

   NEXT

   RETURN cBMP

   
FUNCTION hwg_BMPSetMonochromePalette( pcBMP )
   
   LOCAL npoffset, CBMP
   CBMP := pcBMP

   // Get Offset to palette data, expected value by default is 54
   npoffset := HWG_BMPCALCOFFSPAL()
   CBMP := hwg_ChangeCharInString( CBMP, npoffset     , Chr( 255 ) )
   CBMP := hwg_ChangeCharInString( CBMP, npoffset + 1 , Chr( 255 ) )
   CBMP := hwg_ChangeCharInString( CBMP, npoffset + 2 , Chr( 255 ) )
   CBMP := hwg_ChangeCharInString( CBMP, npoffset + 3 , Chr( 255 ) )

   RETURN CBMP
   
   
FUNCTION hwg_QR_SetPixel( cmbp, x, y, xw, yh )

   LOCAL cbmret, noffset, nbit , y1
   LOCAL nolbyte
   LOCAL nbline, nbyt , nline , nbint

   cbmret := cmbp

   // Range check
   IF ( x > xw ) .OR. ( y > yh ) .OR. ( x < 1 ) .OR. ( y < 1 )
      RETURN cbmret
   ENDIF

   // Add 1 to pixel data offset, this is done with call of HWG_SETBITBYTE()
   noffset := hwg_BMPCalcOffsPixArr( 2 );  // For 2 colors

   // y Position conversion
   // (reversed position 1 = 48, 48 = 1)
   y1 := yh - y + 1
   // Bytes per line
   nline := hwg_BMPLineSize( xw, 1 )
   // hwg_MsgInfo("nline="+ STR(nline) )

   // Calculate the recent y position
   // (Start postion of a line)

   nbyt := ( y1 - 1 ) *  nline

   // Split line into number of bytes and bit position
   nbline := Int( x / 8 )
   nbyt := nbyt + nbline + 1   // Added 1 padding byte at begin of a line

   nbint :=  Int( x % 8 ) // + 1

   // Reverse x value in a byte
   nbint := 8 - nbint + 1 // 1 ... 8

   IF nbint == 9
      nbint := 1
      nbyt := nbyt - 1
   ENDIF

   // Extract old byte value
   nolbyte := Asc( SubStr( cbmret,noffset + nbyt,1 ) )

   nbit := Chr( HWG_SETBITBYTE( 0,nbint,1 ) )
   nbit := Chr( HWG_BITOR_INT( Asc(nbit ), nolbyte ) )

   cbmret := hwg_ChangeCharInString( cbmret, noffset + nbyt , nbit )

   RETURN cbmret   
   
FUNCTION hwg_ChangeCharInString(cinp,nposi,cval)

   LOCAL cout, i

   IF cinp == NIL
      RETURN ""
   ENDIF

   IF cval == NIL
      RETURN cinp
   ENDIF

   IF LEN(cval) <> 1
      RETURN cinp
   ENDIF

   IF nposi == NIL
      RETURN cinp
   ENDIF

   IF nposi > LEN(cinp)
      RETURN cinp
   ENDIF

   cout := ""

   FOR i := 1 TO LEN(cinp)
      IF i == nposi
         cout := cout + cval
      ELSE
         cout := cout + SUBSTR(cinp,i,1)
      ENDIF
   NEXT

   RETURN cout
   
   
   
/* #### C functions from draw.c  and others ##### */   
/*  ==== HWGUI Interface function for raw bitmap support ==== */

#pragma BEGINDUMP


/* Define fixed parameters for bitmap */

#define BMPFILEIMG_MAXSZ 131072 /* Max file size of a bitmap (128 K) */
#define  _planes      1         /* Forever 1 */
#define  _compression 0         /* No compression */


#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"

#define HI_NIBBLE    0
#define LO_NIBBLE    1
#define MINIMUM(a, b) ((a) < (b) ? (a) : (b))

#pragma pack(push,1)

typedef struct{
    uint8_t signature[2];              /* 0  "BM" */
    uint32_t filesize;                 /* 2  Size of file in bytes */
    uint32_t reserved;                 /* 6  reserved, forever 0 */
    uint32_t fileoffset_to_pixelarray; /* 10 Start position of image data in bytes */
} fileheader;

typedef struct{
    uint32_t dibheadersize;            /* 14  Size of this header in bytes */
    uint32_t width;                    /* 18  Image width in pixels */
    uint32_t height;                   /* 22  Image height in pixels */
    uint16_t planes;                   /* 26  Number of color planes */
    uint16_t bitsperpixel;             /* 28  Number of bits per pixel */
    uint32_t compression;              /* 30  Compression methods used */
    uint32_t imagesize;                /* 34  Size of bitmap in bytes */
    uint32_t ypixelpermeter;           /* 38  Horizontal resolution in pixels per meter */
    uint32_t xpixelpermeter;           /* 42  Vertical resolution in pixels per meter */
    uint32_t numcolorspallette;        /* 46  Number of colors in the image */
    uint32_t mostimpcolor;             /* 50  Minimum number of important colors */
} bitmapinfoheader; 

typedef struct {
    uint8_t b; /* Blue */
    uint8_t g; /* Green */
    uint8_t r; /* Red component */
    uint8_t a; /* Reserved = 0 */
} color;

typedef struct
{
    uint8_t b;
    uint8_t g;
    uint8_t r;
    uint8_t i;
}  pixel;

typedef struct {
    fileheader fileheader;             /* l = 14 */
    bitmapinfoheader bitmapinfoheader; /* l = 40 */
} bitmapheader3x;

typedef struct {
   char Blue;      /* Blue component */
   char Green;     /* Green component */
   char Red;       /* Red component */
} Win2xPaletteElement ;

typedef struct {
 uint32_t RedMask;       /* 54 Mask identifying bits of red component */
 uint32_t GreenMask;     /* 58 Mask identifying bits of green component */
 uint32_t BlueMask;      /* 62 Mask identifying bits of blue component */
 uint32_t AlphaMask;     /* Mask identifying bits of alpha component */
 uint32_t CSType;        /* Color space type */
 uint32_t RedX;          /* X coordinate of red endpoint */
 uint32_t RedY;          /* Y coordinate of red endpoint */
 uint32_t RedZ;          /* Z coordinate of red endpoint */
 uint32_t GreenX;        /* X coordinate of green endpoint */
 uint32_t GreenY;        /* Y coordinate of green endpoint */
 uint32_t GreenZ;        /* Z coordinate of green endpoint */
 uint32_t BlueX;         /* X coordinate of blue endpoint */
 uint32_t BlueY;         /* Y coordinate of blue endpoint */
 uint32_t BlueZ;         /* Z coordinate of blue endpoint */
 uint32_t GammaRed;      /* Gamma red coordinate scale value */
 uint32_t GammaGreen;    /* Gamma green coordinate scale value */
 uint32_t GammaBlue;     /* Gamma blue coordinate scale value */
} bitmapinfoheader4x; 


/* Bmp image W3.x structure for QR encoding */
typedef struct {
    bitmapheader3x bmp_header;   /* full Header of the bitmap */
    pixel **pixel_data;    /* Pixel matrix (jagged array) */
    color *palette;        /* Color palette (array) */
}  BMPImage3x;

typedef struct {
    fileheader fileheader;                  /* l = 14 */
    bitmapinfoheader bitmapinfoheader;      /* l = 40 */
    bitmapinfoheader4x bitmapinfoheader4x;  /* l = 68 */
} bitmap4x;

typedef struct
{
    bitmap4x bmp_header;   /* full Header of the bitmap */
    pixel **pixel_data;    /* Pixel matrix (jagged array) */
    color *palette;        /* Color palette (array) */
}  BMPImage4x;

#pragma pack(pop)

static void * bmp_fileimg ;


HB_FUNC( HWG_SETBITBYTE )
{
  int para3;

   if ( hb_pcount() < 3 )
    {
      /* Return previous value */
      hb_retni( hb_parni(1) );
    }

    para3 = hb_parni( 3 );
    if ( para3 < 0 || para3 > 1 )
    {
      /* Return previous value */
      hb_retni( hb_parni(1) );
    }

   if ( para3 == 1 )
   {
   /* 0 to 1 */
    hb_retni( hb_parni(1) | ( 1 << (hb_parni(2) - 1) ) );
   }
   else
   {
   /* 1 to 0 */
   hb_retni( hb_parni(1) & ~( 1 << (hb_parni(2) - 1) ) );
   }
}

HB_FUNC( HWG_BITOR_INT )
{
   hb_retni( ( hb_parni( 1 ) | hb_parni( 2 ) ) );
}


HB_FUNC( HWG_BMPLINESIZE )
{
    uint32_t line_size;

    int bmp_width;
    int bmp_bit_depth;

    uint32_t pad;

    bmp_width = hb_parni(1);
    bmp_bit_depth = hb_parni(2);


    pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
    line_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad );

    hb_retnl(line_size);

}

uint32_t hwg_BMPCalcOffsPalC(int bmp_height)
{
  uint32_t iret;
  iret = sizeof(bitmapheader3x) + ( bmp_height * sizeof(pixel*) );
  return iret;
}

uint32_t hwg_BMPCalcOffsPixArrC(unsigned int colors)
   {
    uint32_t fileoffset_to_pixelarray;

    fileoffset_to_pixelarray = sizeof (fileheader) + sizeof(bitmapinfoheader) +
    colors * 4 ;

    return fileoffset_to_pixelarray;

}

HB_FUNC( HWG_BMPCALCOFFSPIXARR )
{

    unsigned int colors;
    uint32_t fileoffset_to_pixelarray;

    colors = hb_parni(1);

    fileoffset_to_pixelarray = hwg_BMPCalcOffsPixArrC(colors);
    hb_retnl(fileoffset_to_pixelarray);

}



static unsigned int cc_null(uint32_t wert)
{
    unsigned int zae ;

    zae = 0;

    if (! wert)
    {
      return 0u;
    }

    while (!(wert & 0x1))
    {
        ++zae;
        wert >>= 1;
    }

    return zae;
}

uint32_t hwg_BMPFileSizeC(
    int bmp_width,
    int bmp_height,
    int bmp_bit_depth,
    unsigned int colors
    )
{
    uint32_t image_size;
    uint32_t pad;
    uint32_t fileoffset_to_pixelarray;
    uint32_t filesize ;


    pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
    image_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad ) * bmp_height;

    fileoffset_to_pixelarray = sizeof (fileheader) + sizeof(bitmapinfoheader) +
    colors * 4 ;
    filesize = fileoffset_to_pixelarray + image_size ;

    return filesize;
}


void * hwg_BMPNewImageC(

    int pbmp_width,
    int pbmp_height,
    int pbmp_bit_depth,
    unsigned int colors,
    uint32_t xpixelpermeter,
    uint32_t ypixelpermeter )

{
    BMPImage3x pbitmap;  /* Memory for the image with pointers */
    uint32_t image_size;
    uint32_t pad;
    uint32_t fileoffset_to_pixelarray;

    uint32_t filesize ;
    uint32_t max_colors;
//    int i;
    uint32_t i,j;
    void * bmp_locpointer;
    uint8_t * bitmap_buffer;
    uint8_t * buf;
    uint8_t tmp;
    short bit;
    char csig[2];
    uint32_t bmp_width;
    uint32_t bmp_height;
    uint32_t bmp_bit_depth;

    /* uint8_t mask1[8]; */
    uint8_t mask4[2];

    /* Reserved for later releases
    mask1[0] = 128;
    mask1[1] = 64;
    mask1[2] = 32;
    mask1[3] = 16;
    mask1[4] = 8;
    mask1[5] = 4;
    mask1[6] = 2;
    mask1[7] = 1;
   */

    mask4[0] = 240,
    mask4[1] = 15;

    max_colors = (uint32_t) 1;

    /* Fixed signature "BM" */
    csig[0] = 0x42;
    csig[1] = 0x4d;

    /* Cast for avoiding warnings in for loops (int ==> uint32_t */
     bmp_width = (uint32_t) pbmp_width;
     bmp_height = (uint32_t) pbmp_height;
     bmp_bit_depth = (uint32_t) pbmp_bit_depth;

    memset(&pbitmap, 0, sizeof (BMPImage3x));

    /* Some parameter checks */
    if (bmp_bit_depth != 1 && bmp_bit_depth != 4 && bmp_bit_depth != 8 && bmp_bit_depth != 16 && bmp_bit_depth != 24 )
    {
       return NULL;
    }

    if (bmp_width < 1 || bmp_height < 1 )
    {
       return NULL;
    }


    for (i = 0; i < bmp_bit_depth; ++i)
    {
        max_colors *= 2;
    }

    if (colors > max_colors)
    {
        /* Colors and max colors not compatible */
        return NULL;
    }

    pad = (4 - (bmp_bit_depth * bmp_width + 7 ) / 8 % 4) % 4;
    image_size = ((bmp_bit_depth * bmp_width + 7 ) / 8 + pad ) * bmp_height;



    /* Pre init with 0 */
    memset(&pbitmap,0x00,sizeof(BMPImage3x) );


    fileoffset_to_pixelarray = sizeof (fileheader) + sizeof(bitmapinfoheader) +
    colors * 4 ;
    filesize = fileoffset_to_pixelarray + image_size ;

    /* Allocate memory for full file size */
    bmp_fileimg = malloc(filesize);


    /* Bitmap file header */

    memcpy( &pbitmap.bmp_header.fileheader.signature,csig,2);                     /* fixed signature */
    pbitmap.bmp_header.fileheader.filesize = filesize;                            /* Size of file in bytes */
    pbitmap.bmp_header.fileheader.reserved = 0;
    pbitmap.bmp_header.fileheader.fileoffset_to_pixelarray = fileoffset_to_pixelarray; /* Start position of image data in bytes */

    /* Bitmap information header 3.x*/
    pbitmap.bmp_header.bitmapinfoheader.dibheadersize = (uint32_t) sizeof(bitmapinfoheader); /* Size of this header in bytes */
    pbitmap.bmp_header.bitmapinfoheader.width =  bmp_width;            /* Image width in pixels */
    pbitmap.bmp_header.bitmapinfoheader.height = bmp_height;          /* Image height in pixels */
    pbitmap.bmp_header.bitmapinfoheader.planes = (uint32_t) _planes;             /* Number of color planes (must be 1) */
    pbitmap.bmp_header.bitmapinfoheader.bitsperpixel = (uint16_t) bmp_bit_depth; /* Number of bits per pixel `*/
    pbitmap.bmp_header.bitmapinfoheader.compression = _compression;              /* Compression methods used */
    pbitmap.bmp_header.bitmapinfoheader.imagesize = (uint32_t) image_size;       /* Size of bitmap in bytes (pixelbytesize) */
    pbitmap.bmp_header.bitmapinfoheader.ypixelpermeter = ypixelpermeter ;        /* Horizontal resolution in pixels per meter */
    pbitmap.bmp_header.bitmapinfoheader.xpixelpermeter = xpixelpermeter ;        /* Vertical resolution in pixels per meter */
    pbitmap.bmp_header.bitmapinfoheader.numcolorspallette = colors;              /* Number of colors in the image */
    pbitmap.bmp_header.bitmapinfoheader.mostimpcolor = colors;                   /* Minimum number of important colors */


    /* process image data */

    /* Alloc pixel data (jagged array) */
    pbitmap.pixel_data = (pixel**) malloc(bmp_height * sizeof(pixel*) );

    if ( ! pbitmap.pixel_data)
    {
       return NULL;
    }
    for (i = 0; i < bmp_height; ++i)
    {
      pbitmap.pixel_data[i] = (pixel*) calloc(bmp_width, sizeof (pixel));

      if (! pbitmap.pixel_data[i])
      {
        while (i > 0)
        {
          free( pbitmap.pixel_data[--i]);
        }
          free(pbitmap.pixel_data);
      }
    }

    /* Alloc color palette */
    pbitmap.palette = (color*) calloc(colors, sizeof (color));
    memset(&pbitmap.palette, 0x00, sizeof (color));

    /* Copy structure pbitmap (BMPImage3x) to file buffer */
    memcpy(bmp_fileimg,&pbitmap, sizeof(BMPImage3x) );

    /*
      Now until here processed:
      - Fileheader
      - Info header
      - Pixel pointer
      - Palette
     */

    /* Move pointer to end of block : start position of pixel data */
 
 #if defined( _MSC_VER )
    bmp_locpointer = (char *) bmp_fileimg + fileoffset_to_pixelarray;
 #else
 #if defined( __BORLANDC__ )
   bmp_locpointer = (char *) bmp_fileimg + fileoffset_to_pixelarray;
 #else   
     bmp_locpointer = bmp_fileimg + fileoffset_to_pixelarray;
 #endif
 #endif
 
    /* Process initialization of  pixel data */

    /* allocate buffer for bitmap pixel data */
    bitmap_buffer = (uint8_t *) calloc(1, image_size);
    memset(bitmap_buffer,0x00,image_size);
    buf = bitmap_buffer;

    /* convert pixel data into bitmap format */
    switch (bmp_bit_depth)
    {
    /* Each byte of data represents 8 pixels, with the most significant
       bit mapped into the leftmost pixel */
    case 1:
       for (i = 0; i < bmp_height; ++i)
       {
         j = 0;
         while (j < bmp_width)
         {
           tmp = 0;
           for (bit = 7; bit >= 0 && j < bmp_width; --bit)
           {
             tmp |= (pbitmap.pixel_data[i][j].i == 0 ? 0u : 1u) << bit;
             ++j;
           }
           *buf++ = tmp;
         }
         buf += pad;
       }
       break;

    /* Each byte represents 2 pixel byte, nibble */

    case 4:
       for (i = 0; i < bmp_height; ++i)
        {
         for (j = 0; j < bmp_width; j += 2)
          {
             /* write two pixels in the one byte variable tmp */
             tmp = 0;
             /* most significant nibble */
             tmp |= pbitmap.pixel_data[i][j].i << 4;
             if (j + 1 < bmp_height)
             {
              /* least significant nibble */
               tmp |= pbitmap.pixel_data[i][j + 1].i & mask4[LO_NIBBLE];
             }
              /* write the byte in the image buffer */
              *buf++ = tmp;
          }
          /* each row has a padding to a 4 byte alignment */
          buf += pad;
        }
        break;

    /* represents 1 byte pixel */
    case 8:
       for (i = 0; i < bmp_height; ++i)
        {
         for (j = 0; j < bmp_width; ++j)
         {
           *buf++ = pbitmap.pixel_data[i][j].i;
         }

           /* each row has a padding to a 4 byte alignment */
           buf += pad;
        }
        break;

    /* 2 bytes pixel*/
    case 16:
       for (i = 0; i < bmp_height; ++i)
        {
          for (j = 0; j < bmp_width; ++j)
          {
            uint16_t *px = (uint16_t*) buf;
            *px =
             (pbitmap.pixel_data[i][j].b << cc_null(pbitmap.palette->b)) +
             (pbitmap.pixel_data[i][j].g << cc_null(pbitmap.palette->g)) +
             (pbitmap.pixel_data[i][j].r << cc_null(pbitmap.palette->r));
            buf += 2;
          }
          buf += pad;
       }
       break;

    /* 3 bytes pixel, 1 byte for one color */
    case 24:
       for (i = 0; i < bmp_height; ++i)
       {
          for (j = 0; j < bmp_width; ++j)
          {
             *buf++ = pbitmap.pixel_data[i][j].b;
             *buf++ = pbitmap.pixel_data[i][j].g;
             *buf++ = pbitmap.pixel_data[i][j].r;
          }
          /* Each row has a padding to a 4 byte alignment */
          buf += pad;
       }
       break;
     }


    /* Copy the image data to the file buffer */
    memcpy(bmp_locpointer,bitmap_buffer, image_size );

    /* Free all the memory not needed */

    if( bitmap_buffer )
      free(bitmap_buffer);
//    if ( bmp_locpointer )
//     free(bmp_locpointer);
//    if (buf)
//     free(buf);


    /* Return the pointer of complete file buffer,
       its content must be returned as Harbour string
       in the corresponding HB_FUNC()
    */

    return bmp_fileimg;

}



HB_FUNC( HWG_BMPNEWIMAGE )
{

    int bmp_width;
    int bmp_height;
    int bmp_bit_depth;
    unsigned int colors;
    uint32_t xpixelpermeter;
    uint32_t ypixelpermeter;
    void * rci;
    char rcbuff[BMPFILEIMG_MAXSZ];
    uint32_t filesize ;

    bmp_width = hb_parni(1);
    bmp_height = hb_parni(2);
    bmp_bit_depth = hb_parni(3);
    colors = hb_parni(4);
    xpixelpermeter = hb_parnl(5);
    ypixelpermeter = hb_parnl(6);



    rci = hwg_BMPNewImageC(
     bmp_width,
     bmp_height,
     bmp_bit_depth,
     colors,
     xpixelpermeter,
     ypixelpermeter );


     if ( ! rci )
     {
      hb_retc("Error");
     }

    /* Calculate the file size */
    filesize = hwg_BMPFileSizeC(bmp_width, bmp_height, bmp_bit_depth, colors) ;

    if ( filesize > BMPFILEIMG_MAXSZ )
    {
      hb_retc("Error");
    }

     memcpy(&rcbuff,rci,filesize);


     hb_retclen_buffer(rcbuff,filesize);

    /* HB_RETSTR(rcbuff) stops writing bytes at first appearence of 0x00 */

}


/* Free's the allocted memory of a bitmap */
HB_FUNC( HWG_BMPDESTROY )
{
   if ( bmp_fileimg )
   {
    free(bmp_fileimg);
   }
}


HB_FUNC( HWG_BMPCALCOFFSPAL )
{
  uint32_t rc;
  int bmp_height;

  bmp_height = hb_parni(1);
  rc = hwg_BMPCalcOffsPalC(bmp_height);
  hb_retnl(rc);
}




#pragma ENDDUMP
   
* ==================== EOF of libqrcode_hb.prg ==========================
