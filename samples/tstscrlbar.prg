/*

 $Id$

Additional information about scollbars for GTK on main window:
The style constants
WS_VSCROLL + WS_HSCROLL + ES_AUTOHSCROLL
are ignored.

The sample is compilable and running on GTK, but
the main window could not more minimized than the
displayed data needed.

The widget "GtkScrollbar" is described here and in any other places:
https://www.manpagez.com/html/gtk2/gtk2-2.24.28/GtkScrollbar.php

In other dialogs, the scrollbars appeared correct, for example in BROWSE window.

*/

#include "hwgui.ch"

FUNCTION main()

   LOCAL oMain, i

#ifdef __GTK__
   INIT WINDOW oMain ;
      MAIN ;
      TITLE "Scrollbar example"  ;
      AT    200, 100 ;
      SIZE  400, 250 ;
      STYLE WS_VSCROLL + WS_HSCROLL + ES_AUTOHSCROLL
#else

   INIT WINDOW oMain ;
      MAIN ;
      TITLE "Scrollbar example"  ;
      AT    200, 100 ;
      SIZE  400, 250 ;
      STYLE WS_VSCROLL + WS_HSCROLL
#endif

   FOR i := 0 TO 200 STEP 20
      @ 0, i  say StrZero( i, 3 ) + "  -  " + "01234567890123456789012345678901234567890" + "  -  " + StrZero( i, 3 ) size 420, 20
   NEXT

   ACTIVATE window oMain CENTER

RETURN Nil

* =============================== EOF of stscrlbar.prg ===============================

