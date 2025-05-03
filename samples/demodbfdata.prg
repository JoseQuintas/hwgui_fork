/*
 *
 * Demo for Edit using command NOEXIT
 *
 * HwGUI by Alexander Kresin
 *
 * Copyright (c)
 * Data 01/07/2003 - Sandro Freire <sandrorrfreire@yahoo.com.br>
 *
 */

#include "hwgui.ch"

#define VAR_GET_MAIL       1
#define VAR_GET_CODE       2
#define VAR_GET_NAME       3
#define VAR_GET_ADDRESS    4
#define VAR_GET_PHONE      5
#define VAR_OCODE          6
#define VAR_ONAME          7
#define VAR_OADDRESS       8
#define VAR_OPHONE         9
#define VAR_OMAIL         10
#define VAR_OOPER         11
#define VAR_CPATH         12
#define VAR_BUTTON_NEW    13
#define VAR_BUTTON_EDIT   14
#define VAR_BUTTON_RET    15
#define VAR_BUTTON_NEXT   16
#define VAR_BUTTON_SAVE   17
#define VAR_BUTTON_TOP    18
#define VAR_BUTTON_BOTT   19
#define VAR_BUTTON_DELETE 20
#define VAR_BUTTON_CLOSE  21
#define VAR_BUTTON_PRINT  22

STATIC aVar

FUNCTION DemoDbfData( lWithDialog, oDlg, aEndList )

   //Local oFontBtn
   LOCAL oFont := Nil
   LOCAL cDirSep
   LOCAL oFontBtn

   hb_Default( @lWithDialog, .T. )
   hb_Default( @aEndList, {} )

   aVar := Array(25)
   aVar[ VAR_OOPER ] := 1

   SET DELETED ON
   SET DATE    BRITISH
   SET CENTURY ON

   cDirSep := hwg_GetDirSep()
   aVar[ VAR_CPATH ]   := cDirSep + Curdir() + cDirSep
   //   PREPARE FONT oFontBtn NAME "MS Sans Serif" WIDTH 0 HEIGHT -12

   PREPARE FONT oFontBtn NAME "Arial" WIDTH 0 HEIGHT -12

   IF lWithDialog

      INIT DIALOG oDlg ;
         CLIPPER ;
         NOEXIT ;
         TITLE "demodbfdata.prg - data entry" ;
         SIZE 800, 600 ;
         Font oFontBtn
   ENDIF

// on demo.ch
   ButtonForSample( "demodbfdata.prg" )

   OpenDbf()

   SELECT dbfdata
   SET ORDER TO 1
   GO TOP
   GetVars() //Inicializa as variaveis

   CreateGets()

   @  2, 113 OWNERBUTTON aVar[ VAR_BUTTON_NEW ] ;
      OF oDlg  ;
      ON CLICK { || CreateVariable(), CloseBotons(), aVar[ VAR_GET_CODE ]:Setfocus() } ;
      SIZE 44,38 FLAT ;
      TEXT "New"

   @  46, 113 OWNERBUTTON aVar[ VAR_BUTTON_EDIT ] ;
      OF oDlg ;
      ON CLICK { || EditRecord() } ;
      SIZE 44,38 FLAT ;
      TEXT "Edit"

   @  89, 113 OWNERBUTTON aVar[ VAR_BUTTON_SAVE ] ;
      OF oDlg ;
      ON CLICK { || OpenBotons(), SaveTab() } ;
      SIZE 44,38 FLAT ;
      TEXT "Save"

   @ 132, 113 OWNERBUTTON aVar[ VAR_BUTTON_RET ] ;
      OF oDlg  ;
      ON CLICK { || SkipTab(1) } ;
      SIZE 44,38 FLAT ;
      TEXT "<--"

   @ 175, 113 OWNERBUTTON aVar[ VAR_BUTTON_NEXT ] ;
      OF oDlg  ;
      ON CLICK { || SkipTab(2) } ;
      SIZE 44,38 FLAT ;
      TEXT "-->"

   @ 218, 113 OWNERBUTTON aVar[ VAR_BUTTON_TOP ] ;
      OF oDlg  ;
      ON CLICK { || SkipTab(3) } ;
      SIZE 44,38 ;
      FLAT ;
      TEXT "<-|"

   @ 261, 113 OWNERBUTTON aVar[ VAR_BUTTON_BOTT ] ;
      OF oDlg  ;
      ON CLICK { || SkipTab(4) } ;
      SIZE 44,38 ;
      FLAT ;
      TEXT "|->"

   @ 304, 113 OWNERBUTTON aVar[ VAR_BUTTON_PRINT ] ;
      OF oDlg  ;
      ON CLICK { || hwg_Msginfo("In development" ) } ;
      SIZE 44,38 ;
      FLAT ;
      TEXT "Print"

   @ 347, 113 OWNERBUTTON aVar[ VAR_BUTTON_DELETE ] ;
      OF oDlg ;
      ON CLICK { || DeleteRecord() } ;
      SIZE 54, 38 FLAT ;
      TEXT "Delete"

   @ 400, 113 OWNERBUTTON aVar[ VAR_BUTTON_CLOSE ] ;
      OF oDlg  ;
      ON CLICK { || iif( lWithDialog, oDlg:Close(), hwg_MsgInfo( "no action here" ) ) } ;
      SIZE 44, 38 ;
      FLAT ;
      TEXT "Close"

   IF lWithDialog
      ACTIVATE DIALOG oDlg CENTER
#ifndef DEMOALL
      CLOSE DATABASES
      fErase( "tmpdbfdata.dbf" )
      fErase( "tmpdbfdata.ntx" )
#endif
   ELSE
      Aadd( aEndList, { || fErase( "tmpdbfdata.dbf" ) } )
      Aadd( aEndList, { || fErase( "tmpdbfdata.ntx" ) } )
   ENDIF

RETURN Nil

FUNCTION OpenBotons()

   ControlEnable( ;
      aVar[ VAR_BUTTON_NEW ], ;
      aVar[ VAR_BUTTON_EDIT ], ;
      aVar[ VAR_BUTTON_RET ], ;
      aVar[ VAR_BUTTON_NEXT ], ;
      aVar[ VAR_BUTTON_TOP ], ;
      aVar[ VAR_BUTTON_BOTT ], ;
      aVar[ VAR_BUTTON_DELETE ], ;
      aVar[ VAR_BUTTON_CLOSE ], ;
      aVar[ VAR_BUTTON_PRINT ] )
   ControlDisable( ;
      aVar[ VAR_BUTTON_SAVE ] )

RETURN Nil

FUNCTION CloseBotons()

   ControlDisable( ;
      aVar[ VAR_BUTTON_NEW ], ;
      aVar[ VAR_BUTTON_EDIT ], ;
      aVar[ VAR_BUTTON_RET ], ;
      aVar[ VAR_BUTTON_NEXT ], ;
      aVar[ VAR_BUTTON_TOP ], ;
      aVar[ VAR_BUTTON_BOTT ], ;
      aVar[ VAR_BUTTON_DELETE ], ;
      aVar[ VAR_BUTTON_PRINT ] )
   ControlEnable( ;
      aVar[ VAR_BUTTON_SAVE ], ;
      aVar[ VAR_BUTTON_CLOSE ] )

RETURN Nil

FUNCTION CreateGets()

   @  2, 220 Say "Cod"  SIZE 40,20
   @ 65, 220 Get aVar[ VAR_GET_CODE ] ;
      VAR aVar[ VAR_OCODE ] ;
      PICTURE "999" ;
      STYLE WS_DISABLED  ;
      SIZE 100, 20

   @  2, 245 Say "Name" ;
      SIZE 50, 20

   @ 65, 245 Get aVar[ VAR_GET_NAME ] ;
      VAR aVar[ VAR_ONAME ]  ;
      PICTURE REPLICATE("X",50)  ;
      STYLE WS_DISABLED  ;
      SIZE 310, 20

   @  2, 270 Say "Adress" ;
      SIZE 50, 20

   @ 65, 270 Get aVar[ VAR_GET_ADDRESS ] ;
      VAR aVar[ VAR_OADDRESS ]  ;
      PICTURE REPLICATE("X",50) ;
      STYLE WS_DISABLED ;
      SIZE 310, 20

   @  2, 295 Say "Fone" ;
      SIZE 50, 20

   @ 65, 295 Get aVar[ VAR_GET_PHONE ] ;
      VAR aVar[ VAR_OPHONE ] ;
      PICTURE REPLICATE("X",50) ;
      STYLE WS_DISABLED  ;
      SIZE 310, 20

   @  2, 320 Say "e_Mail" ;
      SIZE 50, 20

   @ 65, 320 Get aVar[ VAR_GET_MAIL ] ;
      VAR aVar[ VAR_OMAIL ] ;
      PICTURE REPLICATE("X",30)  ;
      STYLE WS_DISABLED  ;
      SIZE 190, 20

RETURN Nil

FUNCTION EditRecord()

   CloseBotons()
   OpenGets()
   aVar[ VAR_GET_NAME ]:Setfocus()

RETURN Nil

FUNCTION CreateVariable()

   aVar[ VAR_OCODE ]    := SPACE(5)
   aVar[ VAR_ONAME ]    := SPACE(50)
   aVar[ VAR_OADDRESS ] := SPACE(50)
   aVar[ VAR_OPHONE ]   := SPACE(50)
   aVar[ VAR_OMAIL ]    := SPACE(30)
   GetRefresh()
   OpenGets()
   aVar[ VAR_OOPER ]:=1 //Operacao para Inclusao

RETURN Nil

FUNCTION GetRefresh()

   aVar[ VAR_GET_CODE ]:Refresh()
   aVar[ VAR_GET_NAME ]:Refresh()
   aVar[ VAR_GET_ADDRESS ]:Refresh()
   aVar[ VAR_GET_PHONE ]:Refresh()
   aVar[ VAR_GET_MAIL ]:Refresh()

RETURN Nil

FUNCTION GetVars()

   aVar[ VAR_OCODE ]    := dbfdata->Cod
   aVar[ VAR_ONAME ]    := dbfdata->Name
   aVar[ VAR_OADDRESS ] := dbfdata->Adress
   aVar[ VAR_OPHONE ]   := dbfdata->Fone
   aVar[ VAR_OMAIL ]    := dbfdata->e_Mail

RETURN Nil

FUNCTION SaveTab()

   SELECT dbfdata
   IF aVar[ VAR_OOPER ] = 1
      aVar[ VAR_OCODE ] := StrZero( val( aVar[ VAR_OCODE ] ), 3 )
      SEEK aVar[ VAR_OCODE ]
      If Found()
         hwg_Msginfo( "Cod." + aVar[ VAR_OCODE ] + " no valid...", "Mensagem" )
         RETURN Nil
      ENDIF
      APPEND BLANK
      REPLACE ;
         dbfdata->Cod    WITH aVar[ VAR_OCODE ], ;
         dbfdata->Name   WITH aVar[ VAR_ONAME ], ;
         dbfdata->Adress WITH aVar[ VAR_OADDRESS ], ;
         dbfdata->Fone   WITH aVar[ VAR_OPHONE ], ;
         dbfdata->e_Mail WITH aVar[ VAR_OMAIL ]
      UNLOCK
   ELSE
      RLock()
      REPLACE ;
         dbfdata->Name    WITH aVar[ VAR_ONAME ], ;
         dbfdata->Adress  WITH aVar[ VAR_OADDRESS ], ;
         dbfdata->Fone    WITH aVar[ VAR_OPHONE ], ;
         dbfdata->e_Mail  WITH aVar[ VAR_OMAIL ]
      UNLOCK
   ENDIF
   CloseGets()
   aVar[ VAR_OOPER ] := 1

RETURN Nil

FUNCTION SkipTab( oSalto )

   CloseGets()
   SELECT dbfdata
   IF oSalto = 1
      SKIP -1
   ELSEIF oSalto = 2
      SKIP
   ELSEIF oSalto = 3
      GOTO TOP
   ELSE
      GO BOTTOM
   ENDIF
   GetVars()
   GetRefresh()

RETURN Nil

FUNCTION DeleteRecord()

   SELECT dbfdata
   SEEK aVar[ VAR_OCODE ]
   IF Found()
      IF hwg_Msgyesno( "Delete Cod " + aVar[ VAR_OCODE ], "Mensagem" )
         RLock()
         DELETE
         UNLOCK
      ENDIF
   ENDIF
   GO BOTTOM
   GetVars()
   GetRefresh()

RETURN Nil

FUNCTION OpenDbf()

   LOCAL vTab:={}
   LOCAL vArq  := aVar[ VAR_CPATH ] + "tmpdbfdata.dbf"
   LOCAL vInd1 := aVar[ VAR_CPATH ] + "tmpdbfdata.ntx"

   SELECT ( Select( "dbfdata" ) ) // if already open
   USE
   IF ! File( vArq )
      AADD( vTab, { "Cod",    "C", 3, 0 } )
      AADD( vTab, { "Name",   "C",50, 0 } )
      AADD( vTab, { "Adress", "C",50, 0 } )
      AADD( vTab, { "Fone",   "C",50, 0 } )
      AADD( vTab, { "e_Mail", "C",30, 0 } )
      dBCreate(vArq, vTab)
   ENDIF
   USE ( vArq ) SHARED ALIAS dbfdata
   IF ! File( vInd1 )
      // fLock()
      INDEX ON field->Cod  TO ( vInd1 )
      // UNLOCK
   ELSE
      SET INDEX TO ( vInd1 )
   ENDIF

RETURN Nil

FUNCTION OpenGets()

   ControlEnable( ;
      aVar[ VAR_GET_CODE ], ;
      aVar[ VAR_GET_NAME ], ;
      aVar[ VAR_GET_ADDRESS ], ;
      aVar[ VAR_GET_PHONE ], ;
      aVar[ VAR_GET_MAIL ] )

RETURN Nil

FUNCTION CloseGets()

   ControlDisable( ;
      aVar[ VAR_GET_CODE ], ;
      aVar[ VAR_GET_NAME ], ;
      aVar[ VAR_GET_ADDRESS ], ;
      aVar[ VAR_GET_PHONE ], ;
      aVar[ VAR_GET_MAIL ] )

RETURN Nil

FUNCTION ControlEnable( ... )

   LOCAL aItem, aList

   aList := hb_AParams()

   FOR EACH aItem IN aList
      aItem:Enable()
   NEXT

   RETURN Nil

FUNCTION ControlDisable( ... )

   LOCAL aItem, aList

   aList := hb_AParams()

   FOR EACH aItem IN aList
      aItem:Disable()
   NEXT

   RETURN Nil

// show buttons and source code
#include "demo.ch"
