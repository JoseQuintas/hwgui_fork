/*
 *$Id: initools.prg 3205 2023-01-26 12:33:44Z josequintas $
 *
 * HWGUI - Harbour Linux GUI library
 *
 * HwMake
 * Copyright 2004 Sandro R. R. Freire <sandrorrfreire@yahoo.com.br>
 * www - http://www.hwgui.net
 *
 * Linux version Alain Aupeix <alain.aupeix@wanadoo.fr>
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It is a pure Harbour utility
 * module — INI file reading and writing — with no GTK API calls at all.
 * The only external HWGUI dependency is hwg_MsgExclamation(), which
 * lives elsewhere in the tree and is not part of the GTK migration.
 *
 * Harbour core helpers used:
 *   MemoRead / hb_memowrit / hb_iniread / hb_FNameNameExt /
 *   hb_i18n_gettext / MLCount / MemoLine
 */

#include "hwgui.ch"
REQUEST HB_CODEPAGE_UTF8
#define _( x ) hb_i18n_gettext(x)
#ifndef __XHARBOUR__
#xcommand TRY              => s_bError := errorBlock( {|oErr| break( oErr ) } ) ;;
      BEGIN SEQUENCE
#xcommand CATCH [<!oErr!>] => errorBlock( s_bError ) ;;
      RECOVER [USING <oErr>] <- oErr -> ;;
      ErrorBlock( s_bError )
#command FINALLY           => ALWAYS
#endif
MEMVAR inierror, delmarker

FUNCTION Hwg_GetIni( rubrique, param, defaut, inifile )

   LOCAL hini, inivalue, aSect, inicontent

   inicontent = MemoRead( inifile )
   hini = hb_iniread( inifile )
   IF At( "[" + rubrique + "]", inicontent ) == 0
      IF defaut == NIL
         inivalue = ""
      ELSE
         inivalue = defaut
      ENDIF
      IF !iniError
         iniError = .T.
         hwg_MsgExclamation( _( "Section" ) + " " + rubrique + _( "not found or incorrect ..." ) + Chr( 10 ) + _( "Please, verify !!!" ), _( "File" ) + " " + hb_FNameNameExt( inifile ) + " " + _( "incorrect" ) )
      ENDIF
      RETURN inivalue
   ENDIF
   aSect = hini[rubrique]
   IF At( param, inicontent ) > 0
      inivalue = aSect[param]
   ENDIF
   IF inivalue == NIL
      IF defaut == NIL
         inivalue = ""
      ELSE
         inivalue = defaut
      ENDIF
   ENDIF

   RETURN inivalue

FUNCTION Hwg_WriteIni( rubrique, param, value , inifile )

   LOCAL rg, rga, rgb, txt, newcontent := "", myrubrique := .F. , inicontent, nblines, delmarker := "$*$"

   inicontent = MemoRead( inifile )
   nblines = MLCount( inicontent, 150 )
   FOR rg = 1 TO nblines
      txt = Trim( MemoLine( inicontent,150,rg ) )
      DO CASE
      CASE At( "[", txt ) > 0
         myrubrique = iif( "[" + rubrique + "]" == txt, .T. , .F. )
         newcontent += txt + Chr( 10 )
      CASE At( param, txt ) > 0 .AND. myrubrique .AND. ValType( value ) == "C"
         newcontent += param + "=" + value + Chr( 10 )
      CASE ValType( value ) == "A" .AND. myrubrique
         DO WHILE Len( Trim( MemoLine(inicontent,150,rg ) ) ) > 0
            rg ++
         ENDDO
         rgb = 1
         FOR rga = 1 TO Len( value )
            IF !Empty( value[rga] ) .AND. Left( value[rga], 3 ) != delmarker
               newcontent += param + AllTrim( Str( rgb ) ) + "=" + value[rga] + Chr( 10 )
               rgb ++
            ENDIF
         next
         newcontent += Chr( 10 )
         OTHERWISE
         newcontent += txt + Chr( 10 )
      ENDCASE
   NEXT
   IF Right( newcontent, 2 ) == Chr( 10 ) + Chr( 10 )
      newcontent = Left( newcontent, Len( newcontent ) - 2 )
   ENDIF
   hb_memowrit( inifile, newcontent, .F. )

   RETURN NIL
