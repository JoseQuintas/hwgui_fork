/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Array / String conversion functions
 *
 * Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * 2026-09-08 Fixed 64-bit integer serialization/deserialization
 *            - WriteArray: corrected pointer advance (ptr += 8 instead of 9)
 *            - ReadArray: correctly reads 64-bit int as HB_LONGLONG
 *            - Updated comments for clarity
*/

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "guilib.h"

/*
 * ReadArray: deserializes a binary string back into an Harbour array.
 * The binary format uses a leading type byte for each element:
 *   '\6' - nested array
 *   '\1' - character string (length <= 0xFFFF)
 *   '\7' - long character string (length > 0xFFFF)
 *   '\2' - 32-bit integer
 *   '\10' - 64-bit integer (if HB_LONG_LONG_OFF not defined)
 *   '\3' - numeric (double) with width/decimals
 *   '\4' - date (stored as Julian day number)
 *   '\5' - logical
 *   '\0' - NIL
 * Returns pointer after the parsed array.
 */
static const char *ReadArray( const char *ptr, PHB_ITEM pItem )
{
   HB_ULONG ulArLen, ulLen, ul;
   ptr++;
   ulArLen = HB_GET_LE_UINT16( ptr );
   ptr++;
   ptr++;

   hb_arrayNew( pItem, ulArLen );
   for( ul = 1; ul <= ulArLen; ++ul )
   {
      if( *ptr == '\6' )        // nested array
      {
         ptr = ReadArray( ptr, hb_arrayGetItemPtr( pItem, ul ) );
      }
      else if( *ptr == '\1' )   // short character string (16-bit length)
      {
         ptr++;
         ulLen = HB_GET_LE_UINT16( ptr );
         ptr++;
         ptr++;
         hb_itemPutCL( hb_arrayGetItemPtr( pItem, ul ), ptr, ulLen );
         ptr += ulLen;
      }
      else if( *ptr == '\2' )   // 32-bit integer
      {
         ptr++;
         hb_itemPutNL( hb_arrayGetItemPtr( pItem, ul ),
               HB_GET_LE_UINT32( ptr ) );
         ptr += 4;
      }
      else if( *ptr == '\3' )   // double with width/decimals
      {
         int iWidth, iDec;
         ptr++;
         iWidth = ( int ) *ptr++;
         iDec = ( int ) *ptr++;
         hb_itemPutNDLen( hb_arrayGetItemPtr( pItem, ul ),
               HB_GET_LE_DOUBLE( ptr ), iWidth, iDec );
         ptr += 8;
      }
      else if( *ptr == '\4' )   // date (Julian day)
      {
         ptr++;
         hb_itemPutDL( hb_arrayGetItemPtr( pItem, ul ),
               HB_GET_LE_UINT32( ptr ) );
         ptr += 4;
      }
      else if( *ptr == '\5' )   // logical
      {
         ptr++;
         hb_itemPutL( hb_arrayGetItemPtr( pItem, ul ), *ptr++ != 0 );
      }
      else if( *ptr == '\7' )   // long character string (32-bit length)
      {
         ptr++;
         ulLen = HB_GET_LE_UINT32( ptr );
         ptr += 4;
         hb_itemPutCL( hb_arrayGetItemPtr( pItem, ul ), ptr, ulLen );
         ptr += ulLen;
      }
#ifndef HB_LONG_LONG_OFF
      else if( *ptr == '\10' )  // 64-bit integer (FIXED)
      {
         ptr++;
         /* Read the 64-bit value and store as long long */
         hb_itemPutNLL( hb_arrayGetItemPtr( pItem, ul ),
                        (HB_LONGLONG)HB_GET_LE_UINT64( ptr ) );
         ptr += 8;  /* 8 bytes for the integer value */
      }
#endif
      else                      // NIL
      {
         ptr++;
      }
   }
   return ptr;
}

/*
 * ArrayMemoSize: calculates the buffer size needed to serialize the array.
 * Returns total bytes required (including headers and type markers).
 */
static HB_ULONG ArrayMemoSize( PHB_ITEM pArray )
{
   HB_ULONG ulArrLen = hb_arrayLen( pArray ), ulMemoSize = 3, ulLen, ul;
   double dVal;

   if( ulArrLen > 0xFFFF )
      ulArrLen = 0xFFFF;

   for( ul = 1; ul <= ulArrLen; ++ul )
   {
      switch ( hb_arrayGetType( pArray, ul ) )
      {
         case HB_IT_STRING:
            ulLen = hb_arrayGetCLen( pArray, ul );
            ulMemoSize += ( ( ulLen > 0xffff ) ? 5 : 3 ) + ulLen;
            break;

         case HB_IT_DATE:
            ulMemoSize += 5;        /* type + 4 bytes for Julian */
            break;

         case HB_IT_LOGICAL:
            ulMemoSize += 2;        /* type + 1 byte value */
            break;

         case HB_IT_ARRAY:
            ulMemoSize += ArrayMemoSize( hb_arrayGetItemPtr( pArray, ul ) );
            break;

         case HB_IT_INTEGER:
         case HB_IT_LONG:
            dVal = hb_arrayGetND( pArray, ul );
            if( HB_DBL_LIM_INT32( dVal ) )
               ulMemoSize += 5;     /* type + 4 bytes (32-bit) */
            else
               ulMemoSize += 9;     /* type + 8 bytes (64-bit) */
            break;

         case HB_IT_DOUBLE:
            ulMemoSize += 11;       /* type + width + dec + 8 bytes */
            break;

         default:
            ulMemoSize += 1;        /* only type marker (NIL) */
            break;
      }
   }

   return ulMemoSize;
}

/*
 * WriteArray: serializes an Harbour array into a binary buffer.
 * The buffer must have been allocated with enough space (use ArrayMemoSize).
 * Returns pointer after the written data.
 */
static char *WriteArray( char *ptr, PHB_ITEM pArray )
{
   int iDec, iWidth;
   double dVal;

#if  defined(__XHARBOUR__)
   ULONG ulArrLen = hb_arrayLen( pArray ), ulVal, ul;
#else
   HB_ULONG ulArrLen = hb_arrayLen( pArray ), ulVal, ul;
#endif

#ifndef HB_LONG_LONG_OFF
#if  defined(__XHARBOUR__)
   LONGLONG ullVal;
#else 
   HB_LONGLONG ullVal;
#endif
#endif

   if( ulArrLen > 0xFFFF )
      ulArrLen = 0xFFFF;

   /* Write array header: type '\6' and 16-bit length */
   *ptr++ = '\6';
   HB_PUT_LE_UINT16( ptr, ulArrLen );
   ptr++;
   ptr++;

   for( ul = 1; ul <= ulArrLen; ++ul )
   {
      switch ( hb_arrayGetType( pArray, ul ) )
      {
         case HB_IT_STRING:
            ulVal = hb_arrayGetCLen( pArray, ul );
            if( ulVal > 0xffff )
            {
               *ptr++ = '\7';        /* long string marker */
               HB_PUT_LE_UINT32( ptr, ulVal );
               ptr += 4;
            }
            else
            {
               *ptr++ = '\1';        /* short string marker */
               HB_PUT_LE_UINT16( ptr, ulVal );
               ptr += 2;
            }
            memcpy( ptr, hb_arrayGetCPtr( pArray, ul ), ulVal );
            ptr += ulVal;
            break;

         case HB_IT_DATE:
            *ptr++ = '\4';
            ulVal = hb_arrayGetDL( pArray, ul );
            HB_PUT_LE_UINT32( ptr, ulVal );
            ptr += 4;
            break;

         case HB_IT_LOGICAL:
            *ptr++ = '\5';
            *ptr++ = hb_arrayGetL( pArray, ul ) ? 1 : 0;
            break;

         case HB_IT_ARRAY:
            ptr = WriteArray( ptr, hb_arrayGetItemPtr( pArray, ul ) );
            break;

         case HB_IT_INTEGER:
         case HB_IT_LONG:
            dVal = hb_arrayGetND( pArray, ul );
            if( HB_DBL_LIM_INT32( dVal ) )
            {
               *ptr++ = '\2';        /* 32-bit integer */
               ulVal = hb_arrayGetNL( pArray, ul );
               HB_PUT_LE_UINT32( ptr, ulVal );
               ptr += 4;
            }
#ifndef HB_LONG_LONG_OFF
            else
            {
               *ptr++ = '\10';       /* 64-bit integer (FIXED) */
               ullVal = hb_arrayGetNLL( pArray, ul );
               HB_PUT_LE_UINT64( ptr, ullVal );
               ptr += 8;             /* was erroneously 9 before */
            }
#endif
            break;

         case HB_IT_DOUBLE:
            *ptr++ = '\3';
            dVal = hb_arrayGetND( pArray, ul );
            hb_itemGetNLen( hb_arrayGetItemPtr( pArray, ul ), &iWidth,
                  &iDec );
            *ptr++ = ( char ) iWidth;
            *ptr++ = ( char ) iDec;
            HB_PUT_LE_DOUBLE( ptr, dVal );
            ptr += 8;
            break;

         default:                  /* NIL or unsupported */
            *ptr++ = '\0';
      }
   }

   return ptr;
}

/*
 * ARRAY2STRING( aArray ) -> cString
 * Serializes an array into a binary string that can be stored or transmitted.
 */
HB_FUNC( ARRAY2STRING )
{
   PHB_ITEM pArray = hb_param( 1, HB_IT_ARRAY );
   HB_ULONG ulMemoSize = ArrayMemoSize( pArray );
   char *szResult = ( char * ) hb_xgrab( ulMemoSize + 1 );

   WriteArray( szResult, pArray );
   hb_retclen_buffer( szResult, ulMemoSize );
}

/*
 * STRING2ARRAY( cString ) -> aArray
 * Deserializes a binary string back into an Harbour array.
 * Returns NIL if the string does not start with a valid array marker.
 */
HB_FUNC( STRING2ARRAY )
{
   const char *szResult = hb_parc( 1 );
   PHB_ITEM pItem = hb_itemNew( NULL );

   if( hb_parclen( 1 ) > 2 && *szResult == '\6' )
      ReadArray( szResult, pItem );

   hb_itemRelease( hb_itemReturn( pItem ) );
}

/* ==================== EOF of arr2str.c =========================== */