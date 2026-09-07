/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level common dialogs functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#define OEMRESOURCE
#include "hwingui.h"
#include "hbapiitm.h"
#include "hbvm.h"

/*=============================================================================
 * HWG_SELECTFONT()
 * Displays font selection dialog
 * 
 * Parameters:
 *   1 - Optional font object to initialize dialog
 * 
 * Returns:
 *   Array with font properties, or NIL on cancel
 *===========================================================================*/
HB_FUNC( HWG_SELECTFONT )
{
   CHOOSEFONT cf;
   LOGFONT lf;
   HFONT hfont;
   PHB_ITEM pObj = ( HB_ISNIL( 1 ) ) ? NULL : hb_param( 1, HB_IT_OBJECT );
   PHB_ITEM temp1;
   PHB_ITEM aMetr = hb_itemArrayNew( 9 ), temp;

   if( pObj )
   {
      memset( &lf, 0, sizeof( LOGFONT ) );
      temp1 = GetObjectVar( pObj, "NAME" );
      if( temp1 && HB_IS_STRING( temp1 ) )
         HB_ITEMCOPYSTR( temp1, lf.lfFaceName, HB_SIZEOFARRAY( lf.lfFaceName ) );
      lf.lfFaceName[HB_SIZEOFARRAY( lf.lfFaceName ) - 1] = '\0';
      
      temp1 = GetObjectVar( pObj, "WIDTH" );
      if( temp1 && HB_IS_NUMERIC( temp1 ) )
         lf.lfWidth = hb_itemGetNI( temp1 );
      temp1 = GetObjectVar( pObj, "HEIGHT" );
      if( temp1 && HB_IS_NUMERIC( temp1 ) )
         lf.lfHeight = hb_itemGetNI( temp1 );
      temp1 = GetObjectVar( pObj, "WEIGHT" );
      if( temp1 && HB_IS_NUMERIC( temp1 ) )
         lf.lfWeight = hb_itemGetNI( temp1 );
      temp1 = GetObjectVar( pObj, "CHARSET" );
      if( temp1 && HB_IS_NUMERIC( temp1 ) )
         lf.lfCharSet = (BYTE) hb_itemGetNI( temp1 );
      temp1 = GetObjectVar( pObj, "ITALIC" );
      if( temp1 && HB_IS_NUMERIC( temp1 ) )
         lf.lfItalic = (BYTE) hb_itemGetNI( temp1 );
      temp1 = GetObjectVar( pObj, "UNDERLINE" );
      if( temp1 && HB_IS_NUMERIC( temp1 ) )
         lf.lfUnderline = (BYTE) hb_itemGetNI( temp1 );
      temp1 = GetObjectVar( pObj, "STRIKEOUT" );
      if( temp1 && HB_IS_NUMERIC( temp1 ) )
         lf.lfStrikeOut = (BYTE) hb_itemGetNI( temp1 );
   }

   cf.lStructSize = sizeof( CHOOSEFONT );
   cf.hwndOwner = ( HWND ) NULL;
   cf.hDC = ( HDC ) NULL;
   cf.lpLogFont = &lf;
   cf.iPointSize = 0;
   cf.Flags = CF_SCREENFONTS | ( ( pObj ) ? CF_INITTOLOGFONTSTRUCT : 0 );
   cf.rgbColors = RGB( 0, 0, 0 );
   cf.lCustData = 0L;
   cf.lpfnHook = ( LPCFHOOKPROC ) NULL;
   cf.lpTemplateName = NULL;
   cf.hInstance = ( HINSTANCE ) NULL;
   cf.lpszStyle = NULL;
   cf.nFontType = SCREEN_FONTTYPE;
   cf.nSizeMin = 0;
   cf.nSizeMax = 0;

   if( !ChooseFont( &cf ) )
   {
      hb_itemRelease( aMetr );
      hb_ret();
      return;
   }

   hfont = CreateFontIndirect( cf.lpLogFont );

   temp = HB_PUTHANDLE( NULL, hfont );
   hb_itemArrayPut( aMetr, 1, temp );

   HB_ITEMPUTSTR( temp, lf.lfFaceName );
   hb_itemArrayPut( aMetr, 2, temp );

   hb_itemPutNL( temp, lf.lfWidth );
   hb_itemArrayPut( aMetr, 3, temp );

   hb_itemPutNL( temp, lf.lfHeight );
   hb_itemArrayPut( aMetr, 4, temp );

   hb_itemPutNL( temp, lf.lfWeight );
   hb_itemArrayPut( aMetr, 5, temp );

   hb_itemPutNI( temp, lf.lfCharSet );
   hb_itemArrayPut( aMetr, 6, temp );

   hb_itemPutNI( temp, lf.lfItalic );
   hb_itemArrayPut( aMetr, 7, temp );

   hb_itemPutNI( temp, lf.lfUnderline );
   hb_itemArrayPut( aMetr, 8, temp );

   hb_itemPutNI( temp, lf.lfStrikeOut );
   hb_itemArrayPut( aMetr, 9, temp );

   hb_itemRelease( temp );
   hb_itemReturn( aMetr );
}

/*=============================================================================
 * HWG_SELECTFILE()
 * Displays file open dialog
 *===========================================================================*/
HB_FUNC( HWG_SELECTFILE )
{
   OPENFILENAME ofn;
   TCHAR buffer[2048];  /* Increased buffer size */
   LPTSTR lpFilter;
   void *hTitle, *hInitDir;

   if( HB_ISCHAR( 1 ) && HB_ISCHAR( 2 ) )
   {
      void *hStr1, *hStr2;
      LPCTSTR lpStr1, lpStr2;
      HB_SIZE nLen1, nLen2;

      lpStr1 = HB_PARSTR( 1, &hStr1, &nLen1 );
      lpStr2 = HB_PARSTR( 2, &hStr2, &nLen2 );

      lpFilter = ( LPTSTR ) hb_xgrab( ( nLen1 + nLen2 + 4 ) * sizeof( TCHAR ) );
      memset( lpFilter, 0, ( nLen1 + nLen2 + 4 ) * sizeof( TCHAR ) );
      memcpy( lpFilter, lpStr1, nLen1 * sizeof( TCHAR ) );
      memcpy( lpFilter + nLen1 + 1, lpStr2, nLen2 * sizeof( TCHAR ) );

      hb_strfree( hStr1 );
      hb_strfree( hStr2 );
   }
   else if( HB_ISARRAY( 1 ) && HB_ISARRAY( 2 ) )
   {
      struct _hb_arrStr
      {
         void *hStr1;
         LPCTSTR lpStr1;
         HB_SIZE nLen1;
         void *hStr2;
         LPCTSTR lpStr2;
         HB_SIZE nLen2;
      } *pArrStr;
      PHB_ITEM pArr1 = hb_param( 1, HB_IT_ARRAY );
      PHB_ITEM pArr2 = hb_param( 2, HB_IT_ARRAY );
      HB_SIZE n, nArrLen = hb_arrayLen( pArr1 ), nSize;
      LPTSTR ptr;

      pArrStr = ( struct _hb_arrStr * )
            hb_xgrab( nArrLen * sizeof( struct _hb_arrStr ) );
      nSize = 4;
      for( n = 0; n < nArrLen; n++ )
      {
         pArrStr[n].lpStr1 = HB_ARRAYGETSTR( pArr1, n + 1,
               &pArrStr[n].hStr1, &pArrStr[n].nLen1 );
         pArrStr[n].lpStr2 = HB_ARRAYGETSTR( pArr2, n + 1,
               &pArrStr[n].hStr2, &pArrStr[n].nLen2 );
         nSize += pArrStr[n].nLen1 + pArrStr[n].nLen2 + 2;
      }
      lpFilter = ( LPTSTR ) hb_xgrab( nSize * sizeof( TCHAR ) );
      ptr = lpFilter;
      for( n = 0; n < nArrLen; n++ )
      {
         memcpy( ptr, pArrStr[n].lpStr1, pArrStr[n].nLen1 * sizeof( TCHAR ) );
         ptr += pArrStr[n].nLen1;
         *ptr++ = 0;
         memcpy( ptr, pArrStr[n].lpStr2, pArrStr[n].nLen2 * sizeof( TCHAR ) );
         ptr += pArrStr[n].nLen2;
         *ptr++ = 0;
         hb_strfree( pArrStr[n].hStr1 );
         hb_strfree( pArrStr[n].hStr2 );
      }
      *ptr++ = 0;
      *ptr = 0;
      hb_xfree( pArrStr );
   }
   else
   {
      hb_retc( NULL );
      return;
   }

   memset( ( void * ) &ofn, 0, sizeof( OPENFILENAME ) );
   ofn.lStructSize = sizeof( ofn );
   ofn.hwndOwner = GetActiveWindow();
   ofn.lpstrFilter = lpFilter;
   ofn.lpstrFile = buffer;
   buffer[0] = 0;
   ofn.nMaxFile = HB_SIZEOFARRAY( buffer );
   ofn.lpstrInitialDir = HB_PARSTR( 3, &hInitDir, NULL );
   ofn.lpstrTitle = HB_PARSTR( 4, &hTitle, NULL );
   ofn.Flags = OFN_FILEMUSTEXIST | OFN_EXPLORER;

   if( GetOpenFileName( &ofn ) )
      HB_RETSTR( ofn.lpstrFile );
   else
      hb_retc( NULL );
      
   hb_xfree( lpFilter );
   hb_strfree( hInitDir );
   hb_strfree( hTitle );
}

/*=============================================================================
 * HWG_SAVEFILE()
 * Displays file save dialog
 *===========================================================================*/
HB_FUNC( HWG_SAVEFILE )
{
   OPENFILENAME ofn;
   TCHAR buffer[2048];  /* Increased buffer size */
   void *hFileName, *hStr1, *hStr2, *hTitle, *hInitDir;
   LPCTSTR lpFileName, lpStr1, lpStr2;
   HB_SIZE nSize, nLen1, nLen2;
   LPTSTR lpFilter, lpFileBuff;

   lpFileName = HB_PARSTR( 1, &hFileName, &nSize );
   if( nSize < HB_SIZEOFARRAY( buffer ) )
   {
      memcpy( buffer, lpFileName, nSize * sizeof( TCHAR ) );
      memset( &buffer[nSize], 0, ( HB_SIZEOFARRAY( buffer ) - nSize ) * sizeof( TCHAR ) );
      lpFileBuff = buffer;
      nSize = HB_SIZEOFARRAY( buffer );
   }
   else
      lpFileBuff = HB_STRUNSHARE( &hFileName, lpFileName, nSize );

   lpStr1 = HB_PARSTR( 2, &hStr1, &nLen1 );
   lpStr2 = HB_PARSTR( 3, &hStr2, &nLen2 );

   lpFilter = ( LPTSTR ) hb_xgrab( ( nLen1 + nLen2 + 4 ) * sizeof( TCHAR ) );
   memset( lpFilter, 0, ( nLen1 + nLen2 + 4 ) * sizeof( TCHAR ) );
   memcpy( lpFilter, lpStr1, nLen1 * sizeof( TCHAR ) );
   memcpy( lpFilter + nLen1 + 1, lpStr2, nLen2 * sizeof( TCHAR ) );

   hb_strfree( hStr1 );
   hb_strfree( hStr2 );

   memset( ( void * ) &ofn, 0, sizeof( OPENFILENAME ) );
   ofn.lStructSize = sizeof( ofn );
   ofn.hwndOwner = GetActiveWindow();
   ofn.lpstrFilter = lpFilter;
   ofn.lpstrFile = lpFileBuff;
   ofn.nMaxFile = nSize;
   ofn.lpstrInitialDir = HB_PARSTR( 4, &hInitDir, NULL );
   ofn.lpstrTitle = HB_PARSTR( 5, &hTitle, NULL );
   ofn.Flags = OFN_FILEMUSTEXIST | OFN_EXPLORER;
   if( HB_ISLOG( 6 ) && hb_parl( 6 ) )
      ofn.Flags = ofn.Flags | OFN_OVERWRITEPROMPT;

   if( GetSaveFileName( &ofn ) )
      HB_RETSTR( ofn.lpstrFile );
   else
      hb_retc( NULL );
      
   hb_xfree( lpFilter );
   hb_strfree( hFileName );
   hb_strfree( hInitDir );
   hb_strfree( hTitle );
}

/*=============================================================================
 * HWG_PRINTSETUP()
 * Displays print setup dialog
 *===========================================================================*/
HB_FUNC( HWG_PRINTSETUP )
{
   PRINTDLG pd;

   memset( ( void * ) &pd, 0, sizeof( PRINTDLG ) );

   pd.lStructSize = sizeof( PRINTDLG );
   pd.Flags = PD_RETURNDC;
   pd.hwndOwner = GetActiveWindow();
   pd.nFromPage = 1;
   pd.nToPage = 1;
   pd.nCopies = 1;

   if( PrintDlg( &pd ) )
   {
      if( pd.hDevNames )
      {
         LPDEVNAMES lpdn = ( LPDEVNAMES ) GlobalLock( pd.hDevNames );
         if( lpdn && hb_pcount() > 0 )
         {
            HB_STORSTR( ( LPCTSTR ) lpdn + lpdn->wDeviceOffset, 1 );
         }
         GlobalUnlock( pd.hDevNames );
         GlobalFree( pd.hDevNames );
         GlobalFree( pd.hDevMode );
      }
      HB_RETHANDLE( pd.hDC );
   }
   else
      HB_RETHANDLE( 0 );
}

/*=============================================================================
 * HWG_CHOOSECOLOR()
 * Displays color selection dialog
 *===========================================================================*/
HB_FUNC( HWG_CHOOSECOLOR )
{
   CHOOSECOLOR cc;
   COLORREF rgb[16];
   DWORD nStyle = ( HB_ISLOG( 2 ) && hb_parl( 2 ) ) ? CC_FULLOPEN : 0;

   memset( ( void * ) &cc, 0, sizeof( CHOOSECOLOR ) );

   cc.lStructSize = sizeof( CHOOSECOLOR );
   cc.hwndOwner = GetActiveWindow();
   cc.lpCustColors = rgb;
   if( HB_ISNUM( 1 ) )
   {
      cc.rgbResult = ( COLORREF ) hb_parnl( 1 );
      nStyle |= CC_RGBINIT;
   }
   cc.Flags = nStyle;

   if( ChooseColor( &cc ) )
      hb_retnl( ( LONG ) cc.rgbResult );
   else
      hb_ret();
}

/*=============================================================================
 * HWG_HDGETSERIAL()
 * Gets volume serial number
 *===========================================================================*/
HB_FUNC( HWG_HDGETSERIAL )
{
   DWORD dwSerial = 0;
   void *hDrive;
   HB_SIZE nLen;
   LPCTSTR lpRootPath = HB_PARSTR( 1, &hDrive, &nLen );

   if( GetVolumeInformation( nLen > 0 ? lpRootPath : NULL,
                             NULL,
                             0,
                             &dwSerial,
                             NULL,
                             NULL,
                             NULL,
                             0 ) )
      hb_retnint( dwSerial );
   else 
      hb_retni( -1 );

   hb_strfree( hDrive );
}

/*=============================================================================
 * HWG_GETPRIVATEPROFILESTRING()
 * Reads from INI file
 *===========================================================================*/
HB_FUNC( HWG_GETPRIVATEPROFILESTRING )
{
   TCHAR buffer[1024];
   DWORD dwLen;
   void *hSection, *hEntry, *hDefault, *hFileName;
   LPCTSTR lpDefault = HB_PARSTR( 3, &hDefault, NULL );

   dwLen = GetPrivateProfileString( HB_PARSTR( 1, &hSection, NULL ),
         HB_PARSTR( 2, &hEntry, NULL ),
         lpDefault, buffer, HB_SIZEOFARRAY( buffer ),
         HB_PARSTR( 4, &hFileName, NULL ) );
   if( dwLen )
      HB_RETSTRLEN( buffer, dwLen );
   else
      HB_RETSTR( lpDefault );

   hb_strfree( hSection );
   hb_strfree( hEntry );
   hb_strfree( hDefault );
   hb_strfree( hFileName );
}

/*=============================================================================
 * HWG_WRITEPRIVATEPROFILESTRING()
 * Writes to INI file
 *===========================================================================*/
HB_FUNC( HWG_WRITEPRIVATEPROFILESTRING )
{
   void *hSection, *hEntry, *hData, *hFileName;

   hb_retl( WritePrivateProfileString( HB_PARSTR( 1, &hSection, NULL ),
               HB_PARSTR( 2, &hEntry, NULL ),
               HB_PARSTR( 3, &hData, NULL ),
               HB_PARSTR( 4, &hFileName, NULL ) ) ? TRUE : FALSE );

   hb_strfree( hSection );
   hb_strfree( hEntry );
   hb_strfree( hData );
   hb_strfree( hFileName );
}

/*=============================================================================
 * HWG_PRINTPORTNAME()
 * Gets printer port name
 *===========================================================================*/
HB_FUNC( HWG_PRINTPORTNAME )
{
   static PRINTDLG s_pd;
   static BOOL s_fInit = FALSE;
   static BOOL s_fPName = FALSE;

   if( !s_fInit )
   {
      s_fInit = TRUE;
      memset( &s_pd, 0, sizeof( PRINTDLG ) );
      s_pd.lStructSize = sizeof( PRINTDLG );
      s_pd.hwndOwner = GetActiveWindow();
      s_pd.Flags = PD_RETURNDEFAULT;
      s_pd.nMinPage = 1;
      s_pd.nMaxPage = 65535;
      PrintDlg( &s_pd );
   }

   if( !s_fPName && s_pd.hDevNames )
   {
      LPDEVNAMES lpDevNames;
      s_fPName = TRUE;
      lpDevNames = ( LPDEVNAMES ) GlobalLock( s_pd.hDevNames );
      if( lpDevNames )
      {
         HB_RETSTR( ( LPCTSTR ) lpDevNames + lpDevNames->wOutputOffset );
         GlobalUnlock( s_pd.hDevNames );
      }
   }
}

/*=============================================================================
 * HWG_PRINTSETUPDOS()
 * Print setup dialog (DOS style)
 *===========================================================================*/
HB_FUNC( HWG_PRINTSETUPDOS )
{
   static PRINTDLG s_pd;
   static BOOL s_fInit = FALSE;

   if( !s_fInit )
   {
      s_fInit = TRUE;
      memset( &s_pd, 0, sizeof( PRINTDLG ) );
      s_pd.lStructSize = sizeof( PRINTDLG );
      s_pd.Flags = PD_RETURNDC;
      s_pd.hwndOwner = GetActiveWindow();
      s_pd.nFromPage = 0xFFFF;
      s_pd.nToPage = 0xFFFF;
      s_pd.nMinPage = 1;
      s_pd.nMaxPage = 0xFFFF;
      s_pd.nCopies = 1;

      if( PrintDlg( &s_pd ) )
      {
         hb_stornl( s_pd.nFromPage, 1 );
         hb_stornl( s_pd.nToPage, 2 );
         hb_stornl( s_pd.nCopies, 3 );
         HB_RETHANDLE( s_pd.hDC );
      }
      else
      {
         HB_RETHANDLE( 0 );
      }
   }
}

/*=============================================================================
 * HWG_PRINTSETUPEX()
 * Extended print setup
 *===========================================================================*/
HB_FUNC( HWG_PRINTSETUPEX )
{
   PRINTDLG pd;
   DEVMODE *pDevMode;

   memset( ( void * ) &pd, 0, sizeof( PRINTDLG ) );

   pd.lStructSize = sizeof( PRINTDLG );
   pd.Flags = PD_RETURNDC;
   pd.hwndOwner = GetActiveWindow();
   pd.nFromPage = 1;
   pd.nToPage = 1;
   pd.nCopies = 1;

   if( PrintDlg( &pd ) )
   {
      pDevMode = ( LPDEVMODE ) GlobalLock( pd.hDevMode );
      if( pDevMode )
      {
         HB_RETSTR( ( LPCTSTR ) pDevMode->dmDeviceName );
         GlobalUnlock( pd.hDevMode );
      }
   }
}

/*=============================================================================
 * HWG_GETOPENFILENAME()
 * Extended file open dialog
 *===========================================================================*/
HB_FUNC( HWG_GETOPENFILENAME )
{
   OPENFILENAME ofn;
   TCHAR buffer[2048];  /* Increased buffer size */
   void *hFileName, *hTitle, *hFilter, *hInitDir, *hDefExt;
   HB_SIZE nSize;
   LPCTSTR lpFileName = HB_PARSTR( 2, &hFileName, &nSize );
   LPTSTR lpFileBuff;

   if( nSize < HB_SIZEOFARRAY( buffer ) )
   {
      memcpy( buffer, lpFileName, nSize * sizeof( TCHAR ) );
      memset( &buffer[nSize], 0, ( HB_SIZEOFARRAY( buffer ) - nSize ) * sizeof( TCHAR ) );
      lpFileBuff = buffer;
      nSize = HB_SIZEOFARRAY( buffer );
   }
   else
      lpFileBuff = HB_STRUNSHARE( &hFileName, lpFileName, nSize );

   ZeroMemory( &ofn, sizeof( ofn ) );
   ofn.hInstance = GetModuleHandle( NULL );
   ofn.lStructSize = sizeof( ofn );
   ofn.hwndOwner = ( HB_ISNIL( 1 ) ? GetActiveWindow() : ( HWND ) HB_PARHANDLE( 1 ) );
   ofn.lpstrTitle = HB_PARSTR( 3, &hTitle, NULL );
   ofn.lpstrFilter = HB_PARSTR( 4, &hFilter, NULL );
   ofn.Flags = OFN_EXPLORER | OFN_ALLOWMULTISELECT;
   ofn.lpstrInitialDir = HB_PARSTR( 6, &hInitDir, NULL );
   ofn.lpstrDefExt = HB_PARSTR( 7, &hDefExt, NULL );
   ofn.nFilterIndex = hb_parni( 8 );
   ofn.lpstrFile = lpFileBuff;
   ofn.nMaxFile = nSize;

   if( GetOpenFileName( &ofn ) )
   {
      hb_stornl( ofn.nFilterIndex, 8 );
      HB_STORSTRLEN( lpFileBuff, nSize, 2 );
      HB_RETSTR( ofn.lpstrFile );
   }
   else
      hb_retc( NULL );

   hb_strfree( hFileName );
   hb_strfree( hTitle );
   hb_strfree( hFilter );
   hb_strfree( hInitDir );
   hb_strfree( hDefExt );
}
