/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level print functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#define OEMRESOURCE
#include "hwingui.h"
#include <commctrl.h>

#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

#include "incomp_pointer.h"

/*=============================================================================
 * HWG_OPENPRINTER()
 * Opens a printer device context by name
 * Param 1: Printer name
 * Returns: Printer DC handle
 *===========================================================================*/
HB_FUNC( HWG_OPENPRINTER )
{
   void *hText;
   HB_RETHANDLE( CreateDC( NULL, HB_PARSTR( 1, &hText, NULL ), NULL, NULL ) );
   hb_strfree( hText );
}

/*=============================================================================
 * HWG_OPENDEFAULTPRINTER()
 * Opens the default printer
 * Returns: Default printer DC handle
 *===========================================================================*/
HB_FUNC( HWG_OPENDEFAULTPRINTER )
{
   DWORD dwNeeded, dwReturned;
   HDC hDC;
   PRINTER_INFO_4 *pinfo4;
   TCHAR PrinterDefault[256] = { 0 };
   DWORD BuffSize = 256;

   // Try GetDefaultPrinter first (Windows 2000+)
   if( GetDefaultPrinter( PrinterDefault, &BuffSize ) )
   {
      hDC = CreateDC( NULL, PrinterDefault, NULL, NULL );
      if( hb_pcount() > 0 )
         HB_STORSTR( PrinterDefault, 1 );
      HB_RETHANDLE( hDC );
      return;
   }

   // Fallback: enumerate local printers
   EnumPrinters( PRINTER_ENUM_LOCAL, NULL, 4, NULL,
         0, &dwNeeded, &dwReturned );

   if( dwNeeded == 0 || dwReturned == 0 )
   {
      HB_RETHANDLE( NULL );
      return;
   }

   pinfo4 = ( PRINTER_INFO_4 * ) hb_xgrab( dwNeeded );
   if( pinfo4 == NULL )
   {
      HB_RETHANDLE( NULL );
      return;
   }

   EnumPrinters( PRINTER_ENUM_LOCAL, NULL, 4, ( PBYTE ) pinfo4,
         dwNeeded, &dwNeeded, &dwReturned );

   hDC = CreateDC( NULL, pinfo4->pPrinterName, NULL, NULL );
   if( hb_pcount() > 0 )
      HB_STORSTR( pinfo4->pPrinterName, 1 );

   hb_xfree( pinfo4 );
   HB_RETHANDLE( hDC );
}

/*=============================================================================
 * HWG_GETDEFAULTPRINTER()
 * Returns the name of the default printer
 * Returns: Printer name string
 *===========================================================================*/
HB_FUNC( HWG_GETDEFAULTPRINTER )
{
   TCHAR PrinterDefault[256] = { 0 };
   DWORD BuffSize = 256;

   if( GetDefaultPrinter( PrinterDefault, &BuffSize ) )
   {
      HB_RETSTR( PrinterDefault );
   }
   else
   {
      // Fallback: get first local printer
      DWORD dwNeeded, dwReturned;
      PRINTER_INFO_4 *pinfo4;

      EnumPrinters( PRINTER_ENUM_LOCAL, NULL, 4, NULL,
            0, &dwNeeded, &dwReturned );

      if( dwNeeded == 0 || dwReturned == 0 )
      {
         hb_retc( "" );
         return;
      }

      pinfo4 = ( PRINTER_INFO_4 * ) hb_xgrab( dwNeeded );
      if( pinfo4 == NULL )
      {
         hb_retc( "" );
         return;
      }

      EnumPrinters( PRINTER_ENUM_LOCAL, NULL, 4, ( PBYTE ) pinfo4,
            dwNeeded, &dwNeeded, &dwReturned );

      HB_RETSTR( pinfo4->pPrinterName );
      hb_xfree( pinfo4 );
   }
}

/*=============================================================================
 * HWG_GETPRINTERS()
 * Returns an array of all installed printers
 * Returns: Array of printer names
 *===========================================================================*/
HB_FUNC( HWG_GETPRINTERS )
{
      DWORD dwNeeded, dwReturned;
      PBYTE pBuffer = NULL;
      PRINTER_INFO_4 *pinfo4 = NULL;
      PHB_ITEM aMetr, temp;
      int i;

      // Enumerate local printers (Windows 2000+)
      EnumPrinters( PRINTER_ENUM_LOCAL, NULL, 4, NULL,
                    0, &dwNeeded, &dwReturned );

      if( dwNeeded == 0 || dwReturned == 0 )
      {
            hb_ret();
            return;
      }

      pBuffer = ( PBYTE ) hb_xgrab( dwNeeded );
      if( pBuffer == NULL )
      {
            hb_ret();
            return;
      }

      pinfo4 = ( PRINTER_INFO_4 * ) pBuffer;
      EnumPrinters( PRINTER_ENUM_LOCAL, NULL, 4, pBuffer,
                    dwNeeded, &dwNeeded, &dwReturned );

      aMetr = hb_itemArrayNew( dwReturned );

      for( i = 0; i < ( int ) dwReturned; i++ )
      {
            temp = HB_ITEMPUTSTR( NULL, pinfo4->pPrinterName );
            hb_itemArrayPut( aMetr, i + 1, temp );
            hb_itemRelease( temp );
            pinfo4++;
      }

      hb_itemReturn( aMetr );
      hb_itemRelease( aMetr );

      if( pBuffer )
            hb_xfree( pBuffer );
}

/*=============================================================================
 * HWG_SETPRINTERMODE()
 * Changes printer orientation and duplex mode
 * Param 1: Printer name
 * Param 2: Printer handle (by reference)
 * Param 3: Orientation (1=Portrait, 2=Landscape)
 * Param 4: Duplex mode
 * Returns: New printer DC handle
 *===========================================================================*/
HB_FUNC( HWG_SETPRINTERMODE )
{
   void *hPrinterName;
   LPCTSTR lpPrinterName = HB_PARSTR( 1, &hPrinterName, NULL );
   HANDLE hPrinter =
         ( HB_ISNIL( 2 ) ) ? ( HANDLE ) NULL : ( HANDLE ) HB_PARHANDLE( 2 );
   BOOL bOpenedHere = FALSE;
   long int nSize;
   PDEVMODE pdm;

   if( !hPrinter )
   {
      if( OpenPrinter( ( LPTSTR ) lpPrinterName, &hPrinter, NULL ) )
         bOpenedHere = TRUE;
   }

   if( hPrinter )
   {
      /* Determine the size of DEVMODE structure */
      nSize =
            DocumentProperties( NULL, hPrinter, ( LPTSTR ) lpPrinterName,
            NULL, NULL, 0 );
      
      if( nSize == 0 )
      {
         if( bOpenedHere )
            ClosePrinter( hPrinter );
         hb_strfree( hPrinterName );
         HB_RETHANDLE( NULL );
         return;
      }

      pdm = ( PDEVMODE ) GlobalAlloc( GPTR, nSize );
      if( pdm == NULL )
      {
         if( bOpenedHere )
            ClosePrinter( hPrinter );
         hb_strfree( hPrinterName );
         HB_RETHANDLE( NULL );
         return;
      }

      /* Get the printer mode */
      DocumentProperties( NULL, hPrinter, ( LPTSTR ) lpPrinterName, pdm, NULL,
            DM_OUT_BUFFER );

      /* Changing of values */
      if( !HB_ISNIL( 3 ) )
      {
         pdm->dmOrientation = hb_parni( 3 );
         pdm->dmFields = pdm->dmFields | DM_ORIENTATION;
      }
      if( !HB_ISNIL( 4 ) )
      {
         pdm->dmDuplex = hb_parni( 4 );
         pdm->dmFields = pdm->dmFields | DM_DUPLEX;
      }

      // Call DocumentProperties() to change the values
      DocumentProperties( NULL, hPrinter, ( LPTSTR ) lpPrinterName,
            pdm, pdm, DM_OUT_BUFFER | DM_IN_BUFFER );

      // Return the new DC
      HB_RETHANDLE( CreateDC( NULL, lpPrinterName, NULL, pdm ) );
      HB_STOREHANDLE( hPrinter, 2 );
      GlobalFree( pdm );
   }
   else
   {
      HB_RETHANDLE( NULL );
   }

   hb_strfree( hPrinterName );
}

/*=============================================================================
 * HWG_CLOSEPRINTER()
 * Closes a printer handle
 * Param 1: Printer handle
 *===========================================================================*/
HB_FUNC( HWG_CLOSEPRINTER )
{
   HANDLE hPrinter = ( HANDLE ) HB_PARHANDLE( 1 );
   if( hPrinter )
      ClosePrinter( hPrinter );
}

/*=============================================================================
 * HWG_STARTDOC()
 * Starts a print job
 * Param 1: Printer DC
 * Param 2: Document name
 * Returns: Job ID or 0 on error
 *===========================================================================*/
HB_FUNC( HWG_STARTDOC )
{
   void *hText;
   DOCINFO di;

   di.cbSize = sizeof( DOCINFO );
   di.lpszDocName = HB_PARSTR( 2, &hText, NULL );
   di.lpszOutput = NULL;
   di.lpszDatatype = NULL;
   di.fwType = 0;

   hb_retnl( ( LONG ) StartDoc( ( HDC ) HB_PARHANDLE( 1 ), &di ) );
   hb_strfree( hText );
}

/*=============================================================================
 * HWG_ENDDOC()
 * Ends a print job
 * Param 1: Printer DC
 * Returns: 1 on success, 0 on error
 *===========================================================================*/
HB_FUNC( HWG_ENDDOC )
{
   hb_retnl( ( LONG ) EndDoc( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_ABORTDOC()
 * Aborts a print job
 * Param 1: Printer DC
 *===========================================================================*/
HB_FUNC( HWG_ABORTDOC )
{
   AbortDoc( ( HDC ) HB_PARHANDLE( 1 ) );
}

/*=============================================================================
 * HWG_STARTPAGE()
 * Starts a new page
 * Param 1: Printer DC
 * Returns: 1 on success, 0 on error
 *===========================================================================*/
HB_FUNC( HWG_STARTPAGE )
{
   hb_retnl( ( LONG ) StartPage( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_ENDPAGE()
 * Ends current page
 * Param 1: Printer DC
 * Returns: 1 on success, 0 on error
 *===========================================================================*/
HB_FUNC( HWG_ENDPAGE )
{
   hb_retnl( ( LONG ) EndPage( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_GETDEVICEAREA()
 * Gets printer device capabilities
 * Param 1: Printer DC
 * Returns: Array with printer metrics
 *===========================================================================*/
HB_FUNC( HWG_GETDEVICEAREA )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   PHB_ITEM temp;
   PHB_ITEM aMetr = hb_itemArrayNew( 11 );

   temp = hb_itemPutNL( NULL, GetDeviceCaps( hDC, HORZRES ) );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, GetDeviceCaps( hDC, VERTRES ) );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, GetDeviceCaps( hDC, HORZSIZE ) );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, GetDeviceCaps( hDC, VERTSIZE ) );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, GetDeviceCaps( hDC, LOGPIXELSX ) );
   hb_itemArrayPut( aMetr, 5, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, GetDeviceCaps( hDC, LOGPIXELSY ) );
   hb_itemArrayPut( aMetr, 6, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, GetDeviceCaps( hDC, RASTERCAPS ) );
   hb_itemArrayPut( aMetr, 7, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, GetDeviceCaps( hDC, PHYSICALWIDTH ) );
   hb_itemArrayPut( aMetr, 8, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, GetDeviceCaps( hDC, PHYSICALHEIGHT ) );
   hb_itemArrayPut( aMetr, 9, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, GetDeviceCaps( hDC, PHYSICALOFFSETY ) );
   hb_itemArrayPut( aMetr, 10, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, GetDeviceCaps( hDC, PHYSICALOFFSETX ) );
   hb_itemArrayPut( aMetr, 11, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

/*=============================================================================
 * HWG_CREATEENHMETAFILE()
 * Creates an enhanced metafile
 * Param 1: Window handle
 * Param 2: Filename (optional)
 * Returns: Metafile DC handle
 *===========================================================================*/
HB_FUNC( HWG_CREATEENHMETAFILE )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HDC hDCref = GetDC( hWnd ), hDCmeta = NULL;
   void *hFileName;
   int iWidthMM, iHeightMM, iWidthPels, iHeightPels;
   RECT rc = { 0, 0, 0, 0 };

   if( hDCref == NULL )
   {
      /* GetDC() falhou: nao ha DC valido para criar o metafile */
      HB_RETHANDLE( NULL );
      return;
   }

   iWidthMM = GetDeviceCaps( hDCref, HORZSIZE );
   iHeightMM = GetDeviceCaps( hDCref, VERTSIZE );
   iWidthPels = GetDeviceCaps( hDCref, HORZRES );
   iHeightPels = GetDeviceCaps( hDCref, VERTRES );

   GetClientRect( hWnd, &rc );

   /* Convert client coordinates to .01-mm units
    * (protege contra divisao por zero se o driver retornar 0 pels) */
   if( iWidthPels != 0 && iHeightPels != 0 )
   {
      rc.left = ( rc.left * iWidthMM * 100 ) / iWidthPels;
      rc.top = ( rc.top * iHeightMM * 100 ) / iHeightPels;
      rc.right = ( rc.right * iWidthMM * 100 ) / iWidthPels;
      rc.bottom = ( rc.bottom * iHeightMM * 100 ) / iHeightPels;
   }

   hDCmeta = CreateEnhMetaFile( hDCref, HB_PARSTR( 2, &hFileName, NULL ),
         &rc, NULL );
   ReleaseDC( hWnd, hDCref );
   HB_RETHANDLE( hDCmeta );
   hb_strfree( hFileName );
}

/*=============================================================================
 * HWG_CREATEMETAFILE()
 * Creates a metafile
 * Param 1: Reference DC
 * Param 2: Filename (optional)
 * Returns: Metafile DC handle
 *===========================================================================*/
HB_FUNC( HWG_CREATEMETAFILE )
{
   HDC hDCref = ( HDC ) HB_PARHANDLE( 1 ), hDCmeta;
   void *hFileName;
   int iWidthMM, iHeightMM;
   RECT rc;

   iWidthMM = GetDeviceCaps( hDCref, HORZSIZE );
   iHeightMM = GetDeviceCaps( hDCref, VERTSIZE );

   rc.left = 0;
   rc.top = 0;
   rc.right = iWidthMM * 100;
   rc.bottom = iHeightMM * 100;

   hDCmeta = CreateEnhMetaFile( hDCref, HB_PARSTR( 2, &hFileName, NULL ),
         &rc, NULL );
   HB_RETHANDLE( hDCmeta );
   hb_strfree( hFileName );
}

/*=============================================================================
 * HWG_CLOSEENHMETAFILE()
 * Closes an enhanced metafile
 * Param 1: Metafile DC
 * Returns: Metafile handle
 *===========================================================================*/
HB_FUNC( HWG_CLOSEENHMETAFILE )
{
   HB_RETHANDLE( CloseEnhMetaFile( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

/*=============================================================================
 * HWG_DELETEENHMETAFILE()
 * Deletes an enhanced metafile
 * Param 1: Metafile handle
 * Returns: TRUE on success
 *===========================================================================*/
HB_FUNC( HWG_DELETEENHMETAFILE )
{
   hb_retl( DeleteEnhMetaFile( ( HENHMETAFILE ) HB_PARHANDLE( 1 ) ) != 0 );
}

/*=============================================================================
 * HWG_PLAYENHMETAFILE()
 * Plays an enhanced metafile
 * Param 1: Destination DC
 * Param 2: Metafile handle
 * Param 3-6: Rectangle coordinates (optional)
 * Returns: TRUE on success
 *===========================================================================*/
HB_FUNC( HWG_PLAYENHMETAFILE )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   RECT rc = { 0, 0, 0, 0 };

   if( hb_pcount() > 2 )
   {
      rc.left = hb_parni( 3 );
      rc.top = hb_parni( 4 );
      rc.right = hb_parni( 5 );
      rc.bottom = hb_parni( 6 );
   }
   else if( !GetClientRect( WindowFromDC( hDC ), &rc ) )
   {
      /* hDC nao pertence a uma janela (ex.: DC de metafile/impressora)
       * ou WindowFromDC() falhou: usar a area do proprio dispositivo
       * como retangulo de destino, em vez de deixar rc indeterminado. */
      SetRect( &rc, 0, 0, GetDeviceCaps( hDC, HORZRES ),
            GetDeviceCaps( hDC, VERTRES ) );
   }
   hb_retnl( ( LONG ) PlayEnhMetaFile( hDC,
               ( HENHMETAFILE ) HB_PARHANDLE( 2 ), &rc ) );
}

/*=============================================================================
 * HWG_PRINTENHMETAFILE()
 * Prints an enhanced metafile
 * Param 1: Printer DC
 * Param 2: Metafile handle
 * Returns: TRUE on success
 *===========================================================================*/
HB_FUNC( HWG_PRINTENHMETAFILE )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   RECT rc;

   SetRect( &rc, 0, 0, GetDeviceCaps( hDC, HORZRES ), GetDeviceCaps( hDC,
               VERTRES ) );

   StartPage( hDC );
   hb_retnl( ( LONG ) PlayEnhMetaFile( hDC,
               ( HENHMETAFILE ) HB_PARHANDLE( 2 ), &rc ) );
   EndPage( hDC );
}

/*=============================================================================
 * HWG_SETDOCUMENTPROPERTIES()
 * Sets printer document properties
 *===========================================================================*/
HB_FUNC( HWG_SETDOCUMENTPROPERTIES )
{
   BOOL Result = FALSE;
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   if( hDC )
   {
      HANDLE hPrinter;
      void *hPrinterName;
      LPCTSTR lpPrinterName = HB_PARSTR( 2, &hPrinterName, NULL );

      if( OpenPrinter( ( LPTSTR ) lpPrinterName, &hPrinter, NULL ) )
      {
         PDEVMODE pDevMode = NULL;
         LONG lSize =
               DocumentProperties( 0, hPrinter, ( LPTSTR ) lpPrinterName,
                     pDevMode, pDevMode, 0 );

         if( lSize > 0 )
         {
            pDevMode = ( PDEVMODE ) hb_xgrab( lSize );

            if( pDevMode && DocumentProperties( 0, hPrinter, ( LPTSTR ) lpPrinterName,
                  pDevMode, pDevMode, DM_OUT_BUFFER ) != IDOK )
            {
               hb_xfree( pDevMode );
               pDevMode = NULL;
            }

            if( pDevMode )
            {
               BOOL bAskUser = HB_ISBYREF( 3 ) || HB_ISBYREF( 4 ) ||
                     HB_ISBYREF( 5 ) || HB_ISBYREF( 6 ) || HB_ISBYREF( 7 ) ||
                     HB_ISBYREF( 8 ) || HB_ISBYREF( 9 ) || HB_ISBYREF( 10 );
               DWORD dInit = 0;
               DWORD fMode;
               BOOL bCustomFormSize = ( HB_ISNUM( 9 ) && hb_parnl( 9 ) > 0 ) &&
                     ( HB_ISNUM( 10 ) && hb_parnl( 10 ) > 0 );

               if( bCustomFormSize )
               {
                  pDevMode->dmPaperLength = ( short ) hb_parnl( 9 );
                  dInit |= DM_PAPERLENGTH;
                  pDevMode->dmPaperWidth = ( short ) hb_parnl( 10 );
                  dInit |= DM_PAPERWIDTH;
                  pDevMode->dmPaperSize = DMPAPER_USER;
                  dInit |= DM_PAPERSIZE;
               }
               else
               {
                  if( HB_ISCHAR( 3 ) )
                  {
                     void *hFormName;
                     HB_SIZE len;
                     LPCTSTR lpFormName = HB_PARSTR( 3, &hFormName, &len );

                     if( lpFormName && len && len < CCHFORMNAME )
                     {
                        memcpy( pDevMode->dmFormName, lpFormName,
                              ( len + 1 ) * sizeof( TCHAR ) );
                        dInit |= DM_FORMNAME;
                     }
                     hb_strfree( hFormName );
                  }
                  else if( HB_ISNUM( 3 ) && hb_parnl( 3 ) )
                  {
                     pDevMode->dmPaperSize = ( short ) hb_parnl( 3 );
                     dInit |= DM_PAPERSIZE;
                  }
               }

               if( HB_ISLOG( 4 ) )
               {
                  pDevMode->dmOrientation = ( short ) ( hb_parl( 4 ) ? 2 : 1 );
                  dInit |= DM_ORIENTATION;
               }

               if( HB_ISNUM( 5 ) && hb_parnl( 5 ) > 0 )
               {
                  pDevMode->dmCopies = ( short ) hb_parnl( 5 );
                  dInit |= DM_COPIES;
               }

               if( HB_ISNUM( 6 ) && hb_parnl( 6 ) )
               {
                  pDevMode->dmDefaultSource = ( short ) hb_parnl( 6 );
                  dInit |= DM_DEFAULTSOURCE;
               }

               if( HB_ISNUM( 7 ) && hb_parnl( 7 ) )
               {
                  pDevMode->dmDuplex = ( short ) hb_parnl( 7 );
                  dInit |= DM_DUPLEX;
               }

               if( HB_ISNUM( 8 ) && hb_parnl( 8 ) )
               {
                  pDevMode->dmPrintQuality = ( short ) hb_parnl( 8 );
                  dInit |= DM_PRINTQUALITY;
               }

               fMode = DM_IN_BUFFER | DM_OUT_BUFFER;

               if( bAskUser )
                  fMode |= DM_IN_PROMPT;

               pDevMode->dmFields = dInit;

               if( DocumentProperties( 0, hPrinter, ( LPTSTR ) lpPrinterName,
                     pDevMode, pDevMode, fMode ) == IDOK )
               {
                  if( HB_ISBYREF( 3 ) && !bCustomFormSize )
                  {
                     if( HB_ISCHAR( 3 ) )
                        HB_STORSTR( ( LPCTSTR ) pDevMode->dmFormName, 3 );
                     else
                        hb_stornl( ( LONG ) pDevMode->dmPaperSize, 3 );
                  }
                  if( HB_ISBYREF( 4 ) )
                     hb_storl( pDevMode->dmOrientation == 2, 4 );
                  if( HB_ISBYREF( 5 ) )
                     hb_stornl( ( LONG ) pDevMode->dmCopies, 5 );
                  if( HB_ISBYREF( 6 ) )
                     hb_stornl( ( LONG ) pDevMode->dmDefaultSource, 6 );
                  if( HB_ISBYREF( 7 ) )
                     hb_stornl( ( LONG ) pDevMode->dmDuplex, 7 );
                  if( HB_ISBYREF( 8 ) )
                     hb_stornl( ( LONG ) pDevMode->dmPrintQuality, 8 );
                  if( HB_ISBYREF( 9 ) )
                     hb_stornl( ( LONG ) pDevMode->dmPaperLength, 9 );
                  if( HB_ISBYREF( 10 ) )
                     hb_stornl( ( LONG ) pDevMode->dmPaperWidth, 10 );

                  Result = ( ResetDC( hDC, pDevMode ) != NULL );
               }

               hb_xfree( pDevMode );
            }
         }
         ClosePrinter( hPrinter );
      }
      hb_strfree( hPrinterName );
   }
   hb_retl( Result );
}


/* ======================== EOF of wprint.c ============================= */
