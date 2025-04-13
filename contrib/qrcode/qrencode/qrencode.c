/*
 * qrencode.c
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level QR encode functions,
 * interface module to HWGUI.
 *
 * Copyright 2022 Wilfried Brunken, DF7BE 
 * https://sourceforge.net/projects/cllog/
*/


#include "hbapi.h"
#include "hbapiitm.h"

#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

/* #include "hwingui.h" */
#include "hbdefs.h"
#include "hbvm.h"
#include "hbstack.h"
#include "missing.h"

#include <stdbool.h>

#include "qrcodegen.h"




/*
 hwg_QRCodeTxtGen(ctext)
*/ 

HB_FUNC( HWG_QRCODETXTGEN )
{
  /* UTF-8 */
  
//  void *hString;
  
  uint8_t qrcode[qrcodegen_BUFFER_LEN_MAX];
  uint8_t tempBuffer[qrcodegen_BUFFER_LEN_MAX];
  bool ok;
  int size;
  int border;
  int x,y;
  char retchr[16385];
  int cptr;
  
  /*   border = 4; default  */
  border =  ( HB_ISNIL( 2 ) ? 4 : hb_parni( 2 )  );

  cptr = -1;
  memset(&retchr, 0x00, 16385 );
  memset(&qrcode, 0x00, qrcodegen_BUFFER_LEN_MAX);
  
  ok = qrcodegen_encodeText(hb_parc( 1 ), tempBuffer, qrcode,
       qrcodegen_Ecc_QUARTILE, qrcodegen_VERSION_MIN,
       qrcodegen_VERSION_MAX, qrcodegen_Mask_AUTO, true);  

  if (ok)
  {
   
   size = qrcodegen_getSize(qrcode);
 
   
    for ( y = -border; y < size + border; y++)
     {
      for (x = -border; x < size + border; x++)
        {
          if ( qrcodegen_getModule(qrcode, x, y) )
          {
            /* # = 0x23 */
            cptr++;
            if (cptr < 16385)
            {
              retchr[cptr] = 0x23;
            }
/*
            cptr++;
            if (cptr < 16385)
            {
              retchr[cptr] = 0x23;
            }
*/
          }
          else
          {
            /* SPACE = 0x20 */
            cptr++;
            if (cptr < 16385)
            {
              retchr[cptr] = 0x20;
            }
/*
            cptr++;
            if (cptr < 16385)
            {
              retchr[cptr] = 0x20;
            }
*/
          }  
         }
            cptr++;
            if (cptr < 16385)
            {
              retchr[cptr] = 0x0a;
            }
       }
            cptr++;
            if (cptr < 16385)
            {
              retchr[cptr] = 0x0a;
            }
    }
    cptr++;

      hb_retclen(retchr,cptr);

}


/* ========================== EOF of qrencode.c ==================== */