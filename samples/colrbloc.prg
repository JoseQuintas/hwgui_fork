/*
 *
 * colrbloc.prg
 *
 * $Id$
 *
 * Demo by HwGUI Alexander Kresin
 *  http://kresin.belgorod.su/
 *
 *
 * Paulo Flecha <pfflecha@yahoo.com>
 * 07/07/2005
 * Demo for Browse using bColorBlock
 *
 *       oBrowse:aColumns[1]:bColorBlock := {|| IF (nNumber < 0, ;
 *       {textColor, backColor, textColorSel, backColorSel} ,;
 *       {textColor, backColor, textColorSel, backColorSel} ) }
 *
 *       bColorBlock must return an array containing four colors values
 *
 * Modifications by DF7BE:
 * - BUTTON ... CAPTION "&OK " does not work correct on GTK ==> "OK" only
 * - Added valid ressources from ../../image
 * - Ready for LINUX (case dependent file names), TSTBRW.DBF ==> tstbrw.dbf
 * - Edit error LINUX
 */

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  No
    *  GTK/Win  :  No


* DF7BE: Changed to valid image files
* Home.bmp ==> top.bmp
* End.bmp  ==> bottom.bmp
* Up.bmp   ==> previous.bmp
* Down.bmp ==> next.bmp

#define x_BLUE       16711680
#define x_DARKBLUE   10027008
#define x_WHITE      16777215
#define x_CYAN       16776960
#define x_BLACK             0
#define x_RED             255
#define x_GREEN         32768
#define x_GRAY        8421504
#define x_YELLOW        65535

#include "hwgui.ch"

MEMVAR cImgTop , cImgBottom , cImgPrev, cImgNext

FUNCTION Main()

   LOCAL oWinMain , cImageDir
   //LOCAL cDirSep := hwg_GetDirSep()

   PUBLIC cImgTop , cImgBottom , cImgPrev, cImgNext

   * Image dir
#ifdef __GTK__
   cImageDir := ".." + hwg_GetDirSep() + "image" + hwg_GetDirSep()
// cImageDir := ".." + hwg_GetDirSep() + ".." + hwg_GetDirSep() + "image" + hwg_GetDirSep()
#else
   cImageDir := ".." + hwg_GetDirSep() + "image" + hwg_GetDirSep()
#endif

   SET(_SET_DATEFORMAT, "dd/mm/yyyy")
   SET(_SET_EPOCH, 1950)

   REQUEST DBFCDX                      // Causes DBFCDX RDD to be linked in
   rddSetDefault( "DBFCDX" )           // Set up DBFCDX as default driver

   *FERASE("tstbrw.dbf")

   * Image files
   cImgTop    := cImageDir + "top.bmp"
   cImgBottom := cImageDir + "bottom.bmp"
   cImgPrev   := cImageDir + "previous.bmp"
   cImgNext   := cImageDir + "next.bmp"
   * Check for extisting image files
   CHECK_FILE(cImgTop)
   CHECK_FILE(cImgBottom)
   CHECK_FILE(cImgPrev)
   CHECK_FILE(cImgNext)

   IF !FILE("tstbrw.dbf")
      CriaDbf()
   ELSE
      DBUSEAREA(.T., "DBFCDX", "tstbrw", "TSTB")
   ENDIF

   INIT WINDOW oWinMain MAIN  ;
      TITLE "Teste" AT 0, 0 SIZE 600,400;
      FONT HFont():Add( 'Arial',0,-13,400,,,) ;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER


   MENU OF oWinMain
      MENU TITLE "&File"   && "&Arquivo"
          MENUITEM "&Exit"              ACTION hwg_EndWindow()  && "&Sair"
      ENDMENU
      MENU TITLE "&Browse"
         MENUITEM "&Database"           ACTION BrwDbs(.f.)
         MENUITEM "Database &EDITABLE"  ACTION BrwDbs(.t.)
         MENUITEM "Database &Zebra"     ACTION BrwDbs(.f., .T.)
         SEPARATOR
         MENUITEM "&Array"              ACTION BrwArr(.f.)
         MENUITEM "Array E&DITABLE"     ACTION BrwArr(.t.)
         MENUITEM "Array Ze&bra"        ACTION BrwArr(.f., .T.)
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oWinMain CENTER

RETURN Nil

STATIC FUNCTION BrwDbs( lEdit, lZebra )

   LOCAL oEdGoto
   LOCAL oBrwDb
   LOCAL o_Obtn1, o_Obtn2, o_Obtn3, o_Obtn4
   //LOCAL oTbar
   LOCAL nRec := 1
   LOCAL nLast := 0
   LOCAL nI , oDlg , oTbar1 , oLbl1 , oLbl2 , oBtn1

   lZebra := IF(lZebra == NIL, .F., lZebra)
   DBSELECTAR("TSTB")
   nLast := LASTREC()
   dbGoTop()

   INIT DIALOG oDlg TITLE "Browse DataBase" ;
      AT 0,0 SIZE 600, 500 NOEXIT ;
      FONT HFont():Add( 'Arial',0,-13,400,,,) ;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   IF lEdit
      @ 10 ,10 BROWSE oBrwDb DATABASE SIZE 580, 385  ;
         STYLE  WS_VSCROLL + WS_HSCROLL ;
         AUTOEDIT ;
         APPEND ;
         ON UPDATE {|| oBrwDb:REFRESH() } ;
         ON KEYDOWN {|oBrwDb, nKey| BrowseDbKey(oBrwDb, nKey, @nLast, oLbl2, "") } ;
         ON POSCHANGE {|| BrowseMove(oBrwDb, "NIL", oEdGoto, "Dbs" ) }
   ELSE
      @ 10 ,10 BROWSE oBrwDb DATABASE SIZE 580, 385  ;
         STYLE  WS_VSCROLL + WS_HSCROLL ;
         ON UPDATE {|| oBrwDb:REFRESH() } ;
         ON KEYDOWN {|oBrwDb, nKey| BrowseDbKey(oBrwDb, nKey, @nLast, oLbl2, "") } ;
         ON POSCHANGE {|| BrowseMove(oBrwDb, "NIL", oEdGoto, "Dbs" ) }
   ENDIF

   @ 260,410 BUTTON oBtn1 CAPTION "OK " SIZE 80,26 ; && "&OK " does not work correct on GTK
         ON CLICK {|| hwg_EndDialog()}

   @ 0, 445 PANEL oTbar1 SIZE 600, 26

   @ 17,10 SAY oLbl1 CAPTION "Records :" OF oTbar1 SIZE 70,22

   @ 85,5 OWNERBUTTON o_Obtn1 OF oTbar1 SIZE 20,20     ;
        BITMAP cImgTop ;// TRANSPARENT COORDINATES 0,2,0,0 ;  && Home.bmp
        ON CLICK {|| BrowseMove(oBrwDb, "Home", oEdGoto, "Dbs" ) };
        TOOLTIP "First Record"

   @ 105,5 OWNERBUTTON o_Obtn2 OF oTbar1 SIZE 20,20    ;
        BITMAP cImgPrev ;// TRANSPARENT COORDINATES 0,2,0,0 ;  && Up.bmp
        ON CLICK {|| BrowseMove(oBrwDb, "Up", oEdGoto, "Dbs" ) } ;
        TOOLTIP "Prior"

   @ 130,4 GET oEdGoto VAR nRec OF oTbar1 SIZE 80,22 ;
        MAXLENGTH 09 PICTURE "999999999" ;
        STYLE WS_BORDER + ES_LEFT ;
        VALID {||GoToRec(oBrwDb, @nRec, nLast, "Dbs")}

   @ 270,7 SAY oLbl2 CAPTION " of  " + ALLTRIM(STR(nLast)) OF oTbar1 SIZE 70,22

   @ 215,5 OWNERBUTTON o_Obtn3 OF oTbar1 SIZE 20,20   ;
        BITMAP cImgNext ;// TRANSPARENT COORDINATES 0,2,0,0 ; && Down.bmp
        ON CLICK {|| BrowseMove(oBrwDb, "Down", oEdGoto, "Dbs" ) } ;
        TOOLTIP "Next"

   @ 235,5 OWNERBUTTON o_Obtn4 OF oTbar1 SIZE 20,20   ;
        BITMAP cImgBottom ;// TRANSPARENT COORDINATES 0,2,0,0 ; && End.bmp
        ON CLICK {|| BrowseMove(oBrwDb, "End", oEdGoto, "Dbs" ) } ;
        TOOLTIP "Last Record"

   oBrwDb:bcolorSel := x_DARKBLUE
   oBrwDb:alias := 'TSTB'
   oBrwDb:AddColumn( HColumn():New( "Field1" , FieldBlock(Fieldname(1)),"N", 10,02) )
   oBrwDb:AddColumn( HColumn():New( "Field2" , FieldBlock(Fieldname(2)),"C", 11,00) )
   oBrwDb:AddColumn( HColumn():New( "Field3" , FieldBlock(Fieldname(3)),"D", 10,00) )
   oBrwDb:AddColumn( HColumn():New( "Field4" , FieldBlock(Fieldname(4)),"C", 31,00) )
   oBrwDb:AddColumn( HColumn():New( "Field5" , FieldBlock(Fieldname(5)),"C", 05,00) )

   oBrwDb:aColumns[1]:nJusHead := DT_CENTER
   oBrwDb:aColumns[2]:nJusHead := DT_CENTER
   oBrwDb:aColumns[3]:nJusHead := DT_CENTER
   oBrwDb:aColumns[4]:nJusHead := DT_CENTER
   oBrwDb:aColumns[5]:nJusHead := DT_CENTER

   IF lEdit
      oBrwDb:aColumns[1]:lEditable := .T.
      oBrwDb:aColumns[2]:lEditable := .T.
      oBrwDb:aColumns[3]:lEditable := .T.
      oBrwDb:aColumns[4]:lEditable := .T.
      oBrwDb:aColumns[5]:lEditable := .T.
   ENDIF

   // {|| IF (nNumber < 0, ;
   // {tColor, bColor, tColorSel, bColorSel} ,;
   // {tColor, bColor, tColorSel, bColorSel}) }

   IF lEdit
      oBrwDb:aColumns[1]:bColorBlock := {|| IF(TSTB->FIELD1 < 0 , ;
         {x_RED, x_WHITE, x_CYAN, x_GRAY} , ;
         {x_BLUE, x_WHITE , x_BLACK, x_YELLOW })}
   ELSE
      oBrwDb:aColumns[1]:bColorBlock := {|| IF(TSTB->FIELD1 < 0 , ;
         {x_RED, x_WHITE, x_CYAN, x_DARKBLUE} , ;
         {x_BLACK, x_WHITE , x_WHITE, x_DARKBLUE })}
      IF lZebra
         FOR nI := 2 TO 5
            oBrwDB:aColumns[nI]:bColorBlock := {|| IF(MOD(oBrwDB:nPaintRow, 2) = 0,;
               {x_BLACK, x_GRAY, x_CYAN, x_DARKBLUE} , ;
               {x_BLACK, x_WHITE , x_WHITE, x_DARKBLUE })}
         NEXT
      ENDIF
   ENDIF
   oDlg:Activate()

RETURN Nil

STATIC FUNCTION BrowseMove(oBrw, cPar, oEdGoto, cType )

   IF cPar == "Home"
      oBrw:TOP()
   ELSEIF cPar == "Up"
      oBrw:LineUp()
   ELSEIF cPar == "Down"
      oBrw:LineDown()
   ELSEIF cPar == "End"
      oBrw:BOTTOM()
   ENDIF

   IF cType == "Dbs"
      oEdGoto:SetText(oBrw:recCurr)
   ELSEIF cType == "Array"
      oEdGoto:SetText(oBrw:nCurrent)
   ENDIF
   oBrw:Refresh()

RETURN Nil

STATIC FUNCTION GoToRec(oBrw, nRec, nLast, cType)

   IF nRec == 0
      nRec := 1
   ENDIF

   IF nRec > nLast
      nRec := nlast
   ENDIF

   oBrw:TOP()
   IF cType == "Dbs"
      dbGoto( nRec )
   ELSEIF cType == "Array"
      oBrw:nCurrent := nRec
   ENDIF
   oBrw:Refresh()

   hwg_Setfocus(oBrw:handle)

RETURN .T.

STATIC FUNCTION BrowseDbKey(oBrwDb, nKey, nLast, oLbl2, cPar)

   (oBrwDB); (nLast); (oLbl2); (cPar) // -w3 -es2

   IF nKey == 46   // DEL

   ELSEIF nKey == VK_RETURN

   ENDIF

RETURN .T.

STATIC FUNCTION CriaDbf()

   LOCAL Estrutura := {}
   LOCAL i
   LOCAL nIncrement := 10

   IF ! FILE( "tstbrw.dbf" )
      AADD(Estrutura, {"FIELD1", "N", 10, 02})
      AADD(Estrutura, {"FIELD2", "C", 11, 00})
      AADD(Estrutura, {"FIELD3", "D", 08, 00})
      AADD(Estrutura, {"FIELD4", "C", 30, 00})
      AADD(Estrutura, {"FIELD5", "C", 05, 00})

      DBCREATE("tstbrw.dbf", Estrutura)
      DBCLOSEAREA()
   ENDIF

   DBUSEAREA(.T., "DBFCDX", "tstbrw", "TSTB")

   FOR i := 1 TO 200
      APPEND BLANK
      IF i == nIncrement
         nIncrement += 10
         FIELD->FIELD1 := -i
      ELSE
         IF i == 1
            FIELD->FIELD1 := -i
         ELSE
             FIELD->FIELD1 := i
         ENDIF
      ENDIF
      FIELD->FIELD2 := "Field2 " + STRZERO(i,4)
      FIELD->FIELD3 := DATE() + i
      FIELD->FIELD4 := "jg" + CHR(231) + "pqy " + STRZERO(i, 23)  && 0xE7 = 231 &ccedil;
      FIELD->FIELD5 := STRZERO(i, 5)
  NEXT

RETURN .T.

STATIC FUNCTION BrwArr(lEdit, lZebra)

   LOCAL oEdGoto
   LOCAL oBrwArr
   LOCAL o_Obtn1, o_Obtn2, o_Obtn3, o_Obtn4
   //LOCAL oTbar
   LOCAL nRec := 1
   LOCAL aArrayTst := Create_Array()
   LOCAL nLast := LEN(aArrayTst)
   LOCAL nI , oDlg , oBtn1 , oLbl1 , oLbl2 , oTbar1

   lZebra := IF(lZebra == NIL, .F., lZebra)
   INIT DIALOG oDlg TITLE "Browse Array" ;
        AT 0,0 SIZE 600, 500 NOEXIT ;
        FONT HFont():Add( 'Arial',0,-13,400,,,) ;
        STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   IF lEdit
      @ 10 ,10 BROWSE oBrwArr ARRAY SIZE 580, 385  ;
           STYLE  WS_VSCROLL + WS_HSCROLL ;
           AUTOEDIT ;
           APPEND ;
           ON UPDATE {|| oBrwArr:REFRESH() } ;
           ON KEYDOWN {|oBrwArr, nKey| BrowseDbKey(oBrwArr, nKey, @nLast, oLbl2, "") } ;
           ON POSCHANGE {|| BrowseMove(oBrwArr, "NIL", oEdGoto, "Array" ) }
  ELSE
      @ 10 ,10 BROWSE oBrwArr ARRAY SIZE 580, 385  ;
           STYLE  WS_VSCROLL + WS_HSCROLL ;
           ON UPDATE {|| oBrwArr:REFRESH() } ;
           ON KEYDOWN {|oBrwArr, nKey| BrowseDbKey(oBrwArr, nKey, @nLast, oLbl2, "") } ;
           ON POSCHANGE {|| BrowseMove(oBrwArr, "NIL", oEdGoto, "Array" ) }
   ENDIF

   @ 260,410 BUTTON oBtn1 CAPTION "OK " SIZE 80,26 ;  && "&OK " does not work correct on GTK
         ON CLICK {|| hwg_EndDialog()}

   @ 0, 445 PANEL oTbar1 SIZE 600, 26

   @ 17,10 SAY oLbl1 CAPTION "Elements :" OF oTbar1 SIZE 70,22

   @ 85,5 OWNERBUTTON o_Obtn1 OF oTbar1 SIZE 20,20     ;
        BITMAP cImgTop ;// TRANSPARENT COORDINATES 0,2,0,0 ; && Home.bmp
        ON CLICK {|| BrowseMove(oBrwArr, "Home", oEdGoto, "Array" ) };
        TOOLTIP "First Record"

   @ 105,5 OWNERBUTTON o_Obtn2 OF oTbar1 SIZE 20,20    ;
        BITMAP cImgPrev ;// TRANSPARENT COORDINATES 0,2,0,0 ;  && Up.bmp
        ON CLICK {|| BrowseMove(oBrwArr, "Up", oEdGoto, "Array" ) } ;
        TOOLTIP "Prior"

   @ 130,4 GET oEdGoto VAR nRec OF oTbar1 SIZE 80,22 ;
        MAXLENGTH 09 PICTURE "999999999" ;
        STYLE WS_BORDER + ES_LEFT ;
        VALID {||GoToRec(oBrwArr, @nRec, nLast, "Array")}

   @ 270,7 SAY oLbl2 CAPTION " of  " + ALLTRIM(STR(nLast)) OF oTbar1 SIZE 70,22

   @ 215,5 OWNERBUTTON o_Obtn3 OF oTbar1 SIZE 20,20   ;
        BITMAP cImgNext ;// TRANSPARENT COORDINATES 0,2,0,0 ;  && Down.bmp
        ON CLICK {|| BrowseMove(oBrwArr, "Down", oEdGoto, "Array" ) } ;
        TOOLTIP "Next"

   @ 235,5 OWNERBUTTON o_Obtn4 OF oTbar1 SIZE 20,20   ;
        BITMAP cImgBottom ;// TRANSPARENT COORDINATES 0,2,0,0 ; && End.bmp
        ON CLICK {|| BrowseMove(oBrwArr, "End", oEdGoto, "Array" ) } ;
        TOOLTIP "Last Record"

   hwg_CREATEARLIST( oBrwArr, aArrayTst )

   oBrwArr:bcolorSel := x_BLUE

   oBrwArr:aColumns[1]:length := 10
   oBrwArr:aColumns[2]:length := 11
   oBrwArr:aColumns[3]:length := 10
   oBrwArr:aColumns[4]:length := 31
   oBrwArr:aColumns[5]:length := 05

   oBrwArr:aColumns[1]:heading := "Column[1]"
   oBrwArr:aColumns[2]:heading := "Column[2]"
   oBrwArr:aColumns[3]:heading := "Column[3]"
   oBrwArr:aColumns[4]:heading := "Column[4]"
   oBrwArr:aColumns[5]:heading := "Column[5]"

   oBrwArr:aColumns[1]:nJusHead := DT_CENTER
   oBrwArr:aColumns[2]:nJusHead := DT_CENTER
   oBrwArr:aColumns[3]:nJusHead := DT_CENTER
   oBrwArr:aColumns[4]:nJusHead := DT_CENTER
   oBrwArr:aColumns[5]:nJusHead := DT_CENTER

   IF lEdit
       oBrwArr:aColumns[1]:lEditable := .T.
       oBrwArr:aColumns[2]:lEditable := .T.
       oBrwArr:aColumns[3]:lEditable := .T.
       oBrwArr:aColumns[4]:lEditable := .T.
       oBrwArr:aColumns[5]:lEditable := .T.
   ENDIF

   // {|| IF (nNumber < 0, ;
   // {tColor, bColor, tColorSel, bColorSel} ,;
   // {tColor, bColor, tColorSel, bColorSel}) }
   IF lEdit
      oBrwArr:aColumns[1]:bColorBlock := {|n| (n), IF(aArrayTst[oBrwArr:nCurrent][1] < 0 , ;
         {x_RED, x_WHITE, x_CYAN, x_BLUE} , ;
         {x_BLUE, x_WHITE , x_WHITE, x_BLUE })}
   ELSE
      oBrwArr:aColumns[1]:bColorBlock := {|n| (n), IF(aArrayTst[oBrwArr:nCurrent][1] < 0 , ;
         {x_RED, x_WHITE, x_CYAN, x_DARKBLUE} , ;
         {x_BLUE, x_WHITE , x_WHITE, x_BLUE })}
      IF lZebra
         FOR nI := 2 TO 5
            oBrwArr:aColumns[nI]:bColorBlock := {|| IF(MOD(oBrwArr:nCurrent, 2) = 0,;
               {x_BLACK, x_GRAY, x_CYAN, x_DARKBLUE} , ;
               {x_BLACK, x_WHITE , x_WHITE, x_DARKBLUE })}
         NEXT
      ENDIF
   ENDIF

   /*
   oBrwDb:aColumns[1]:bColorBlock := {|| IF(TSTB->FIELD1 < 0 , ;
   {x_VERMELHO, x_BRANCO, x_CYAN, x_CINZA50} , ;
   {x_AZUL, x_BRANCO , x_LARANJA, x_AMARELO })}
   */
   oDlg:Activate()

RETURN .T.

STATIC FUNCTION Create_Array()

   LOCAL i
   LOCAL n
   LOCAL nIncrement := 10
   LOCAL aArray := {}

   FOR i := 1 TO 200
      //n := i
      IF i == nIncrement
         nIncrement += 10
         n := -i
      ELSE
         IF i == 1
            n := -i
         ELSE
            n := i
         ENDIF
      ENDIF
      AADD(aArray, { n, STRZERO(i,4), DATE() + i, "jg" + CHR(231) + "pqy " + STRZERO(i, 23), STRZERO(i, 5)})
   NEXT

RETURN aArray

#Ifdef __XHARBOUR__
 #XTRANSLATE HB_PVALUE(<var>)  => PVALUE(<var>)
#endif

FUNCTION MsgD( cV1, cV2, cV3, cV4, cV5, cV6, cV7, cV8, cV9, cV10 )

   LOCAL nI, nLen := PCOUNT(), cVar := ""

   FOR nI := 1 TO nLen
       IF HB_PVALUE(nI) == NIL
         cVar += "NIL"
       ELSEIF VALTYPE(HB_PVALUE(nI)) == "B"
         cVar += "CODEBLOCK"
       ELSEIF VALTYPE(HB_PVALUE(nI)) == "N"
         cVar += STR(HB_PVALUE(nI))
       ELSEIF VALTYPE(HB_PVALUE(nI)) == "D"
         cVar += DTOS(HB_PVALUE(nI))
       ELSEIF VALTYPE(HB_PVALUE(nI)) == "L"
         cVar += IF(HB_PVALUE(nI), ".T.", ".F.")
       ELSEIF VALTYPE(HB_PVALUE(nI)) == "C"
         cVar += HB_PVALUE(nI)
       ENDIF
       cVar += "/"
   NEXT
   hwg_Msginfo(LEFT(cVar, LEN(cVar) - 1))

   // remarks: values used by hb_PValue(), do not remove names
   // can be changed to ... and hb_AParams() but do not know if exists on xharbour
   (cV1); (cV2); (cV3); (cV4); (cV5); (cV6); (cV7); (cV8); (cV9); (cV10) // -w3 -es2

RETURN Nil

FUNCTION CHECK_FILE ( cfi )

   * Check, if file exist,
   * otherwise terminate program
   ******************************

   IF .NOT. FILE( cfi )
      Hwg_MsgStop("File >" + cfi + "< not found, program terminated","File ERROR !")
      QUIT
   ENDIF

RETURN Nil

* =================================== EOF of colrbloc.prg ==============================
