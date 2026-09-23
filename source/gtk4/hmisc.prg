/*
 *$Id: hmisc.prg 3492 2024-11-18 14:57:01Z df7be $
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Misc functions
 *
 * This is a container for several useful functions.
 * Don't forget to add the desription in the function docu, if
 * a new function is added.
 * Try to make versions for WinAPI and GTK equal.
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2020-2024 Wilfried Brunken, DF7BE
 *
 * November 2024:
 * All multi platform functions of this module are moved to
 * source/cross/hmisccross.prg
 * Add here only functions platform dependant.
 * (DF7BE)
 *
 * GTK4 port
 *
 * NOTE
 * ----
 * This file needs no changes for GTK4.  It is entirely platform-
 * agnostic: no Gtk/Gdk symbols, no hwg_* widget calls.
 */

#include "hwgui.ch"
#include "hbclass.ch"



* This function for WinAPI found in guimain.prg
FUNCTION hwg_HdSerial( cDrive )

   HB_SYMBOL_UNUSED(cDrive)

   RETURN ""


FUNCTION hwg_Has_Win_Euro_Support()

#if ( HB_VER_REVID - 0 ) >= 2002101634
   RETURN .T.
#else
   RETURN .F.
#endif

* ======================= EOF of hmisc.prg ===========================
