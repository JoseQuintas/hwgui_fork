*
* Ticket27.prg
*
* $Id$
*
* HWGUI - Harbour Win32 and Linux (GTK) GUI library
*
* Test program for support Ticket #27:
* Multithread sample
*

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No


#include "hwgui.ch"

STATIC mutex1
THREAD STATIC cGetRx

FUNCTION Main()

   LOCAL  oMainW
   PUBLIC nCont

* MEMVAR nCont


   INIT WINDOW oMainW  ;
   TITLE "Ticket #27 test sample" AT 0,0 SIZE 0 , 0

   * Check for multithread support of used Harbour release
   IF ! hb_mtvm()
     hwg_msginfo("No multithread support")
     oMainW:Close()
     QUIT
   ENDIF
   mutex1 := hb_mutexCreate()

      hb_ThreadStart( @Test1() )
      hb_ThreadStart( @Test2() )

   hb_ThreadWaitForAll()

   * Display get inputs:

   hwg_msginfo("Get #1 : " + cgetrx1 + CHR(10) + ;
               "Get #2 : " + cgetrx2 + CHR(10))

   oMainW:Close()

   RETURN Nil

* To avoid adress conflict at call of functions for multithread
* you must clone the same function with a new name.
* Test2() has the same implementation as Test1(),
* but the title and the static target variable differs.
* or declare as THREAD STATIC

FUNCTION Test1()

   LOCAL oDlg
   LOCAL cTexto := Space(20), cTexto2 := Space(20), GetList := {}

   hb_mutexLock( mutex1 )

   INIT DIALOG oDlg ;
    TITLE "Multithread dialog #1" ;
    AT 0 , 0  SIZE 600, 500

   @ 20 , 80 GET cTexto   SIZE 260, 25
   @ 20 , 180 GET cTexto2 SIZE 260, 25


   @ 20 , 350  BUTTON "OK" SIZE 100, 32 ON CLICK {|| oDlg:Close() }

   hb_mutexUnLock( mutex1 )

    ACTIVATE DIALOG oDlg

    * copy input from get 1 to global var:
    hb_mutexLock( mutex1 )
    cGetRx := cTexto
    hb_mutexUnLock( mutex1 )

   RETURN Nil

FUNCTION Test2()

   LOCAL oDlg
   LOCAL cTexto := Space(20), cTexto2 := Space(20), GetList := {}

   hb_mutexLock( mutex1 )

   INIT DIALOG oDlg ;
    TITLE "Multithread dialog #2" ;
    AT 30 , 30  SIZE 600, 500

   @ 20 , 80 GET cTexto   SIZE 260, 25
   @ 20 , 180 GET cTexto2 SIZE 260, 25


   @ 20 , 350  BUTTON "OK" SIZE 100, 32 ON CLICK {|| oDlg:Close() }

    hb_mutexUnLock( mutex1 )

    ACTIVATE DIALOG oDlg

    hb_mutexLock( mutex1 )
    cGetRx := cTexto
    hb_mutexUnLock( mutex1 )


   RETURN Nil

* ====================== EOF of Ticket27.prg ==========================
