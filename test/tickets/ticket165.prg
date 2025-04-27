
* #165 Progress Bar 'G_IS_OBJECT (object)' failed (GTK)
* (Ticket closed 2015-03-17)

#include "hwgui.ch"

FUNCTION MAIN

Test()

RETURN NIL

Function Test()
Local oDlg, oBar

   INIT DIALOG oDlg TITLE "Progress Bar Demo";
         AT 0, 0 SIZE 320, 120 ;
         FONT HFont():Add( "MS Sans Serif",0,-13 ) ;
         ON EXIT {||Iif(oBar==Nil,.T.,(oBar:Close(),.T.))}

   @ 20, 30 BUTTON 'Step' SIZE 80,28 ;
         ON CLICK {|| Iif(oBar==Nil,.F.,oBar:Step() ) }
   @ 120,30 BUTTON 'Create Bar' SIZE 80,28 ;
         ON CLICK {|| oBar := HProgressBar():NewBox( "Testing ...",,,,, 10,10 ) }
   @ 220,30 BUTTON 'Close' SIZE 80,28 ON CLICK {|| oBar:Close() , oDlg:Close() } //Here if put oBar:Close(), return error, if use oBar:End() run ok! Default i get this error below.

   // DF7BE:
   // Program runs on Windows 11 OK
   // Ubuntu LINUX:
   // Close: crashes with
   // Speicherzugriffsfehler (Speicherabzug geschrieben) (access violation)
   // (in both cases oBar:Close() or oBar:End()
   // The GTK message above do not appear any more

   // Attention !
   // See closed Bug ticket #52:
   // "demoprogbar doesn't work under Linux"
   // A working solution for progress bars
   // delivered by Alain Aupeix
   // to be found in:
   // samples/progressbar
   // For details see the Readme file in this directory.

   ACTIVATE DIALOG oDlg
RETURN NIL

* =================== EOF of Ticket165.prg ======================
