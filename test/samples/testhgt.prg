/*

 testhgt.prg

 $Id$

 HWGUI Sample program for usage of
 class HGT for combined usage of HWGUI control elements in
 Harbour gtwvg programs in multithread mode.

 Delivered by José M. C. Quintas (TNX)

NOTE:
hbgt shows a possibility, but it is not a ready to use solution,
Create dialogs on each library is a better solution
demomenumt.prg can be an example about this.

*/

   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No

/*

 Additional instructions:
 - Pressing the "Close" button the hwg_MsgInfo() dialog appears.
 - Only pressing the <ESC> key terminates the program
 - on click {||hwg_EndWindow() does noz close a windows.
 - The cross in the header bar normally termines the program.
   This does not work here.

*/


#include "hbclass.ch"
#include "hbgtinfo.ch"
#include "hwgui.ch"

#define HB_GTI_EXTENDED                   1000
#define HB_GTI_NOTIFIERBLOCKGUI           ( HB_GTI_EXTENDED + 10 )

//ANNOUNCE HB_GTSYS
REQUEST HB_GT_WVG_DEFAULT

THREAD STATIC MainWVT

CLASS HGT INHERIT HWindow
   METHOD New() INLINE ::Super:New() , ::Handle := hb_gtInfo(HB_GTI_WINHANDLE), Self
ENDCLASS

PROCEDURE Main

   hb_ThreadStart( { || Test() } )
   hb_ThreadWaitForAll()

RETURN

FUNCTION Test()

   LOCAL nKey := 0, hgt, oFont

   hb_gtReload( "WVG" )
   hb_gtSelect()
   SetMode(40,100)
   SetColor( "W/B" )
   CLS
   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT 20 WEIGHT 400
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Hello"
   ? "Press <ESC> key to terminate program"
   hgt := Maingt()
   @   1,2 nicebutton [ola]    of hgt id 100 size 40,40 red 52  green 10  blue 60
   @ 50,20 nicebutton [Rafael] of hgt id 101 size 60,40 red 215 green 76  blue 108
   @ 80,40 nicebutton [Culik]  of hgt id 102 size 40,40 red 136 green 157 blue 234 on click {||hwg_EndWindow()}
   @ 80,80 nicebutton [guimaraes]  of hgt id 102 size 60,60 red 198 green 045 blue 215 on click {||hwg_EndWindow()}
   @ 200,100 SAY "um teste" SIZE 100, 25
   @ 230,90 SHADEBUTTON SIZE 100,40 FLAT ;
         EFFECT SHS_VSHADE  PALETTE PAL_METAL HIGHLIGHT 12
   @ 230,130 SHADEBUTTON SIZE 100,40 FLAT TEXT "Flat" COLOR 4259584 FONT oFont ;
         EFFECT SHS_VSHADE  PALETTE PAL_METAL HIGHLIGHT 12

   @ 340,10 SHADEBUTTON SIZE 100,36 EFFECT SHS_METAL  PALETTE PAL_METAL GRANULARITY 33 ;
         HIGHLIGHT 20 TEXT "Close" FONT oFont ;
     ON CLICK {|| hwg_msginfo("Close Button pressed") }
     *
   @ 340,50 SHADEBUTTON SIZE 100,36 EFFECT SHS_SOFTBUMP  PALETTE PAL_METAL GRANULARITY 33 HIGHLIGHT 20

   DO WHILE nKey != 27
      nKey := Inkey(1)
   ENDDO

RETURN Nil

//PROCEDURE HB_GTSYS
//   REQUEST HB_GT_WVG_DEFAULT
//   RETURN

FUNCTION MainGT()

   IF Empty( MainWVT )
      MainWVT := HGT():New()
      MainWVT:Handle := hb_gtInfo( HB_GTI_WINHANDLE )
      hb_gtInfo( HB_GTI_NOTIFIERBLOCKGUI, { | nEvent, ... | MainWVT:OnEvent( nEvent, ... ) } )
      //MainWVT:IsGT := .T.
   ENDIF

RETURN MainWVT

* ===================== EOF of testhgt.prg ======================
