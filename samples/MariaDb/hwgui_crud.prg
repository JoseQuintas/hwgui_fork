#require "rddsql"
#require "sddodbc" //SQLMIX

#include "hwgui.ch"
#include "set.ch"
#include "dbinfo.ch"

REQUEST HB_CODEPAGE_UTF8EX
REQUEST DBFCDX, DBFFPT

//For MariaDB via SQLMIX
REQUEST SQLMIX, SDDODBC

MEMVAR cName, nIdContact, cPhantom
MEMVAR oName, oIdContact, oPhantom
MEMVAR lAdd

Function Test
   Local oMain


   INIT WINDOW oMain MAIN TITLE "GRUD DBF - MariaDB" AT 100, 100 SIZE 400, 300

   MENU OF oMain

      MENU TITLE "&Files"
         MENUITEM "&Contacts DBF" ACTION Contacts_DBF()
         SEPARATOR
         MENUITEM "&Contacts MariaDB" ACTION Contacts_MariaDB()
         SEPARATOR

      MENUITEM "&Exit" ACTION oMain:Close()
      ENDMENU

      MENU TITLE "&Help"
         MENUITEM "&About" ACTION hwg_Msginfo( HwG_Version(), "About" )
      ENDMENU

   ENDMENU

   ACTIVATE WINDOW oMain CENTER

Return Nil

Function Contacts_DBF
   Local oDlg, oBrw, oTab, oFontDlg, oFontBrw //Controls of Dialog
   Local oBtnDel, oBtnSave, oBtnAdd, oBtnOnOff //Controls of Dialog
   Local aStructure, lSQL := .F.

   Private nIdContact, cName, cPhantom := space(1)  //Fields of DataBase
   Private lAdd := .F.

   rddSetDefault("DBFCDX")
   Set Autopen On
   hb_cdpSelect("UTF8EX")

   aStructure := { { "idcontact" ,"+",04,0} ,; //Auto increment
                   { "name"      ,"c",60,0} }

   If !hb_vfexists("contacts.dbf")
      If dbcreate("contacts.dbf",aStructure,"DBFCDX",.t.,"ctc") //Create and open with shared mode
         index on field->name tag tgName
         ctc->( dbappend() )
         ctc->name := "JOSÉ DE ASSUMPÇÃO"
         ctc->( dbappend() )
         ctc->name := "MARIA ANTONIETA"
         ctc->( dbappend() )
         ctc->name := "SNOOPY"
         ctc->( dbappend() )
         ctc->name := "POPEYE"
         ctc->(DbDelete())

         ctc->( dbCloseArea() )
      Else
         hwg_MsgStop("Error Creating DBF")
         cancel
      EndIf
   EndIf

   PREPARE FONT oFontDlg NAME "Z003" Width 0 Height 16
   PREPARE FONT oFontBrw NAME "Courier" Width 0 Height 14

   Use contacts new shared alias "ctc"

INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Contacts Via DBFCDX" AT 0,0 size 1024,500 Font oFontDlg STYLE DS_CENTER
   @ 10,080 browse oBrw DataBase Of oDlg size 360,400 Font oFontBrw ;
   On PosChange {|| UpdateGets() }

   oBrw:Alias:="ctc"

   Add Column {||iif(ctc->(Deleted()),"Yes","No" ) } to oBrw ;
   Header "Del" Length 3

   Add Column FieldBlock("idcontact") to oBrw ;
   Header "Cont_ID" Length 10

   Add Column FieldBlock("name") to oBrw ;
   Header "Name" length 100

   @ 370,005 Tab oTab Items {} size 600,430 of oDlg

      BEGIN PAGE "Contacts" of oTab

         FieldsGet()

         @ 010,010 GroupBox "ID" size 120,60
         @ 020,030 Get oIdContact var nIdContact Picture "9999999999" size 090,30 STYLE ES_RIGHT

         @ 010,080 GroupBox "Name" size 500,60
         @ 020,100 Get oName var cName size 470,30 //ToolTip "Name of contact"

         @ 020,160 Get oPhantom var cPhantom size 0,0 //Phantom get to validate last get

      END Page Of oTab

   @ 370,440 button oBtnSave   Caption "Save"   on click {||SaveContact(oDlg,lSQL)} size 90,50
   @ 470,440 button oBtnAdd    Caption "Add"    on click {||NewContact()}           size 90,50
   @ 570,440 button oBtnDel    Caption "Del"    on click {||DelContact(oDlg,lSQL)}  size 90,50
   @ 670,440 button oBtnOnOff  Caption "On Off" on click {||DelOnOff(oDlg)}         size 90,50

oDlg:Activate()

ctc->( dbCloseArea() )
Return nil

Static Function MakeVars()
   nIdContact := 0 //Auto increment
   cName      := space(60)
return .T.

Static Function FieldsGet()
   nIdContact := ctc->idcontact
   cName      := ctc->name
   lAdd       := .F.
return .T.

Static function RefreshGets()
   oIdContact : Refresh()
   oName      : Refresh()
return .T.

Static function UpdateGets()
   FieldsGet()
   RefreshGets()
return .T.

Static function DelContact(oDlg,lSQL)
Local cSQl

   If lSQL
      cSQL := "DELETE FROM contacts WHERE idcontact = " + hb_ntos(ctc->idcontact)
      If rddInfo( RDDI_EXECUTE, cSQL )
         Hwg_msgInfo("Record deleted.")
         ctc->(dbCloseArea())
         dbUseArea( .T., , "SELECT * FROM contacts", "ctc" )
      Else
         Hwg_MsgStop("Fail erase record.")
      EndIf
   Else
      IF ctc->( RLOCK() )
         If ctc->(deleted())
            ctc->(dbRecall())
            hwg_MsgInfo("Record recovered.")
         Else
            ctc->(DbDelete())
            hwg_MsgInfo("Record deleted.")
         EndIf
      EndIf
   EndIf

   oDlg:oBrw:Refresh()

return .T.

Static Function NewContact()
   lAdd := .T.
   MakeVars()
   oIdContact:SetGet("New Contact")
   oIdContact:Refresh()
   oName:SetGet(cName)
   oName:SetFocus()
   hwg_edit_SetPos( oName:Handle, 1 ) //Set 1 position edit of get

return .T.

Static function SaveContact(oDlg,lSQL)
Local cSQL
   cName := oName:Value

   If empty(cName)
      hwg_msgStop("Please enter with a name")
      oName:SetFocus()
      hwg_edit_SetPos( oName:Handle, 1 ) //Set 1 position edit of get
      return .t.
   EndIf

   If lAdd

      If lSQL

         cSQL := "INSERT INTO contacts (name) values ('" + cName + "')"
         If rddInfo( RDDI_EXECUTE, cSQL  )
            ctc->(dbCloseArea())  //Close table contact
            dbUseArea( .T., , "SELECT * FROM contacts", "ctc" ) //need open contacts table becouse new data.
         Else
            hwg_msginfo('Fail to add data')
         EndIF

      Else

         ctc->( dbappend() )
         If NetErr()
            hwg_MsgStop("Error on append.")
            return .F.
         EndIf

      EndIf

   Else

      If lSQL
      Else
         If !ctc->(dbRLock())
            hwg_MsgStop("Error on replace.")
         EndIf
      EndIf

   EndIf

   If lSQL
      If lAdd
      Else
         cSQL := "UPDATE contacts SET name = '" + cName + "' WHERE idcontact = " + hb_ntos(ctc->idcontact)
         If rddInfo( RDDI_EXECUTE, cSQL  )
            Hwg_MsgInfo("contact: " + hb_ntos(ctc->idcontact) + " updated.")
            ctc->(dbCloseArea())
            dbUseArea( .T., , "SELECT * FROM contacts", "ctc" )
         Else
            Hwg_MsgStop("Fail contact update.")
         EndIf
      EndIf
   Else
      ctc->name := cName
   EndIf

   lAdd := .F.
   oDlg:oBrw:Refresh()

return .T.

Static Function DelOnOff(oDlg)
   Local lSetDeleted := Set( _SET_DELETED )
   iif(lSetDeleted, Set( _SET_DELETED, .F.), Set( _SET_DELETED, .T.) )
   oDlg:oBrw:Refresh()

return .T.

Function Contacts_MariaDB
   Local oDlg, oBrw, oTab, oFontDlg, oFontBrw //Controls of Dialog
   Local oBtnDel, oBtnSave, oBtnAdd, oBtnOnOff //Controls of Dialog
   Local nTab, lSQL := .T., nConnection
   Private nIdContact, cName, cPhantom := space(1)  //Fields of DataBase
   Private lAdd := .F.

   rddSetDefault( "SQLMIX" )
   nConnection := rddInfo( RDDI_CONNECT, { "ODBC", "Server=127.0.0.1;Driver={MariaDB};dsn=;User=itamar;password=@itamar;database=test;" } )

   IF nConnection == 0
      hwg_msgstop("Unable connect to server" +hb_eol() + rddInfo( RDDI_ERRORNO ) + hb_eol() + rddInfo( RDDI_ERROR ) )
      RETURN .F.
   ENDIF

    //hwg_msginfo("Number of conection:" + hb_ntos(nConnection))
    If !rddInfo( RDDI_EXECUTE, "CREATE DATABASE IF NOT EXISTS `test`" )
       Hwg_msginfo("Fail to create database test of MariaDB")
    EndIf
    If !rddInfo( RDDI_EXECUTE, "USE `test`" )
       Hwg_msginfo("Fail to conect on database test of MariaDB")
    EndIF

    dbUseArea( , , "SELECT COUNT(*) as nTot FROM information_schema.tables WHERE table_schema = 'test' AND table_name = 'contacts' ",'RS' )
    nTab := rs->nTot
    rs->(dbCloseArea())

    If nTab > 0
       If hwg_MsgYesNo("Erase table contacts ?")
          If rddInfo( RDDI_EXECUTE, "DROP TABLE contacts" )
             nTab := 0
          Else
             hwg_MsgStop("Fail to erase table contacts.")
          EndIF
       EndIf
    EndIf

    If empty(nTab) //make table contacts
       If rddInfo( RDDI_EXECUTE, "CREATE TABLE contacts ( idcontact MEDIUMINT NOT NULL AUTO_INCREMENT, NAME CHAR(60) NOT NULL, PRIMARY KEY (idcontact) )" )
          Hwg_msginfo("Table contacts create on MariaDB")
       Else
          Hwg_msginfo("Fail to make table contacts")
       EndIf

       If rddInfo( RDDI_EXECUTE, "INSERT INTO contacts (name) values ('JOSÉ DE ASSUMPÇÃO'),('MARIA ANTONIETA'), ('SNOOPY'), ('POPEYE')" )
          Hwg_MsgInfo("Data add")
       Else
          Hwg_MsgInfo("Fail to add data.")
       EndIf
    EndIf

    dbUseArea( .T., , "SELECT * FROM contacts", "ctc" )

   PREPARE FONT oFontDlg NAME "Z003" Width 0 Height 16
   PREPARE FONT oFontBrw NAME "Courier" Width 0 Height 14

INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Contacts using SQLMIX and MariaDB" AT 0,0 size 1024,500 Font oFontDlg STYLE DS_CENTER

   @ 10,080 browse oBrw DataBase Of oDlg size 360,400 Font oFontBrw ;
   On PosChange {|| UpdateGets() }

   oBrw:Alias:="ctc"

   Add Column {||iif(ctc->(Deleted()),"Yes","No" ) } to oBrw ;
   Header "Del" Length 3

   Add Column FieldBlock("idcontact") to oBrw ;
   Header "Cont_ID" Length 10

   Add Column FieldBlock("name") to oBrw ;
   Header "Name" length 100

   @ 370,005 Tab oTab Items {} size 600,430 of oDlg

      BEGIN PAGE "Contacts" of oTab

         FieldsGet()

         @ 010,010 GroupBox "ID" size 120,60
         @ 020,030 Get oIdContact var nIdContact Picture "9999999999" size 090,30 STYLE ES_RIGHT

         @ 010,080 GroupBox "Name" size 500,60
         @ 020,100 Get oName var cName size 470,30 //ToolTip "Name of contact"

         @ 020,160 Get oPhantom var cPhantom size 0,0 //Phantom get to validate last get

      END Page Of oTab

   @ 370,440 button oBtnSave   Caption "Save"   on click {||SaveContact(oDlg,lSQL)} size 90,50
   @ 470,440 button oBtnAdd    Caption "Add"    on click {||NewContact()}           size 90,50
   @ 570,440 button oBtnDel    Caption "Del"    on click {||DelContact(oDlg,lSQL)}  size 90,50
   @ 670,440 button oBtnOnOff  Caption "On Off" on click {||DelOnOff(oDlg)}         size 90,50

   oDlg:bActivate:={||oBrw:top(),oBrw:Refresh() }

oDlg:Activate()

ctc->( dbCloseArea() )
Return nil
