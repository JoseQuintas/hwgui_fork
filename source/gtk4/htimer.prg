/*
 *$Id: htimer.prg 3346 2023-10-03 13:27:29Z alkresin $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HTimer class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4 *provided* that HWG_KILLTIMER in
 * control.c is a real implementation (it was left as a stub in the
 * previous iteration).
 *
 * Required fix in control.c:
 *
 *     HB_FUNC( HWG_KILLTIMER )
 *     {
 *        guint tag = (guint) hb_parni( 1 );
 *        if( tag > 0 )
 *           g_source_remove( tag );
 *     }
 *
 * GSource ids returned by g_timeout_add() are still valid in GTK4 and
 * g_source_remove() is still the canonical way to cancel them.
 *
 * Pre-existing bug (not GTK4-related): HTimer:Interval() overwrites
 * ::tag without killing the previous GSource.  The old timer keeps
 * firing.  See the optional patch in the message accompanying this
 * conversion.
 */

#include "hwgui.ch"
#include "hbclass.ch"

#define  TIMER_FIRST_ID   33900

CLASS HTimer INHERIT HObject

   CLASS VAR aTimers   INIT {}
   DATA id, tag
   DATA value
   DATA lOnce          INIT .F.
   DATA oParent
   DATA bAction
   DATA name

   METHOD Interval( n ) SETGET
   METHOD New( oParent, nId, value, bAction, lOnce )
   METHOD End()

ENDCLASS

METHOD New( oParent, nId, value, bAction, lOnce ) CLASS HTimer

   ::oParent := iif( oParent == Nil, HWindow():GetMain(), oParent )
   IF nId == Nil
      nId := TIMER_FIRST_ID
      DO WHILE AScan( ::aTimers, { |o| o:id == nId } ) !=  0
         nId ++
      ENDDO
   ENDIF
   ::Id := nId

   ::value   := iif( ValType( value ) == "N", value, 1000 )
   ::bAction := bAction
   ::lOnce := !Empty( lOnce )

   ::tag := hwg_SetTimer( ::id, ::value )
   AAdd( ::aTimers, Self )

   RETURN Self

METHOD Interval( n ) CLASS HTimer

   LOCAL nOld := ::value, nId

   IF n != Nil
      IF n > 0
         nId := TIMER_FIRST_ID
         DO WHILE AScan( ::aTimers, { |o| o:id == nId } ) !=  0
            nId ++
         ENDDO
         ::id := nId
         ::tag := hwg_SetTimer( ::id, ::value := n )
      ENDIF
   ENDIF

   RETURN nOld

METHOD End() CLASS HTimer

   LOCAL i

   //hwg_KillTimer( ::tag )
   ::bAction := Nil
   i := Ascan( ::aTimers, { |o|o:id == ::id } )
   IF i != 0
      ADel( ::aTimers, i )
      ASize( ::aTimers, Len( ::aTimers ) - 1 )
   ENDIF

   RETURN Nil

FUNCTION hwg_TimerProc( idTimer )

   LOCAL i := Ascan( HTimer():aTimers, { |o|o:id == idTimer } ), b, oParent

   IF i != 0 .AND. ValType( HTimer():aTimers[i]:bAction ) == "B"
      b := HTimer():aTimers[i]:bAction
      oParent := HTimer():aTimers[i]:oParent
      IF HTimer():aTimers[i]:lOnce
         HTimer():aTimers[i]:End()
      ENDIF
      Eval( b, oParent )
      RETURN 1
   ENDIF

   RETURN 0

FUNCTION hwg_ReleaseTimers()
   LOCAL oTimer, i

   For i := 1 TO Len( HTimer():aTimers )
      oTimer := HTimer():aTimers[i]
      hwg_KillTimer( oTimer:tag )
   NEXT

   RETURN Nil

   EXIT PROCEDURE CleanTimers
   hwg_ReleaseTimers()

   RETURN
