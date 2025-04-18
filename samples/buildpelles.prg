/*
 *$Id: buildpelles.prg,v 1.5 2006/09/13 15:47:24 alkresin Exp $
 *
 * HWGUI - Harbour Win32 GUI library
 *
 * File to Build APP using Pelles C Compiler
 * Copyright 2004 Sandro R. R. Freire <sandrorrfreire@yahoo.com.br>
 * www - http://www.lumainformatica.com.br
*/

#include "hwgui.ch"

#DEFINE  ID_EXENAME     10001
#DEFINE  ID_LIBFOLDER   10002
#DEFINE  ID_INCFOLDER   10003
#DEFINE  ID_PRGFLAG     10004
#DEFINE  ID_CFLAG       10005
#DEFINE  ID_PRGMAIN     10006

MEMVAR oDirec , lSaved
MEMVAR oBrowse1, oBrowse2, oBrowse3
MEMVAR oDlg
MEMVAR oButton1, oExeName, oLabel1, oLibFolder, oButton4, oLabel2, oIncFolder, oLabel3, oButton3, oPrgFlag, oLabel4, oCFlag, oLabel5, oButton2, oMainPrg, oLabel6, oTab
MEMVAR oBrowse4
MEMVAR CRF

FUNCTION Main()

   Local oFont
   //Local aBrowse1, aBrowse2, aBrowse3, aBrowse4
   //LOCAL oPasta  := DiskName()+":\"+CurDir()+"\"
   Local vGt1:=Space(80)
   Local vGt2:=Space(80)
   Local vGt3:=Space(80)
   Local vGt4:=Space(80)
   Local vGt5:=Space(80)
   Local vGt6:=Space(80)
   Local aFiles1:={""}, aFiles2:={""}, aFiles3:={""}, aFiles4:={""}

   PRIVATE oBrowse4
   PRIVATE oDirec := DiskName()+":\"+CurDir()+"\"
   PRIVATE CRF    := CHR(13)+CHR(10)
   If !File(oDirec+"BuildPelles.Ini")
      Hwg_WriteIni( 'Config', 'Dir_HwGUI', "C:\HwGUI", oDirec+"BuildPelles.Ini" )
      Hwg_WriteIni( 'Config', 'Dir_HARBOUR', "C:\xHARBOUR", oDirec+"BuildPelles.Ini" )
      Hwg_WriteIni( 'Config', 'Dir_PELLES', "C:\POCC", oDirec+"BuildPelles.Ini" )
   EndIf

   Private lSaved:=.F.
   Private oBrowse1, oBrowse2, oBrowse3
   Private oDlg
   PRIVATE oButton1, oExeName, oLabel1, oLibFolder, oButton4, oLabel2, oIncFolder, oLabel3, oButton3, oPrgFlag, oLabel4, oCFlag, oLabel5, oButton2, oMainPrg, oLabel6, oTab

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -12

   INIT DIALOG oDlg ;
      CLIPPER ;
      NOEXIT ;
      TITLE "HwGUI Build For Pelles C Compiler" ;
      AT 213,195 ;
      SIZE 513,265  ;
      font oFont

   @ 14,16 TAB oTAB ;
      ITEMS {} ;
      SIZE 391,242

   BEGIN PAGE "Config" Of oTAB

      @  20,44 SAY oLabel1 CAPTION "Exe Name" SIZE 80,22
      @ 136,44 GET oExeName VAR vGt1 ID ID_EXENAME  SIZE 206,24

      @  20,74 SAY oLabel2 CAPTION "Lib Folder" SIZE 80,22
      @ 136,74 GET oLibFolder  VAR vGt2 ID ID_LIBFOLDER SIZE 234,24

      @  20,104 SAY oLabel3 CAPTION "Include Folder" SIZE 105,22
      @ 136,104 GET oIncFolder VAR vGt3 ID ID_INCFOLDER   SIZE 234,24

      @  20,134 SAY oLabel4 CAPTION "PRG Flags" SIZE 80,22
      @ 136,134 GET oPrgFlag VAR vGt4 ID ID_PRGFLAG  SIZE 230,24

      @  20,164 SAY oLabel5 CAPTION "C Flags" SIZE 80,22
      @ 136,164 GET oCFlag VAR vGt5  ID ID_CFLAG SIZE 230,24

      @  20,194 SAY oLabel6 CAPTION "Main PRG" SIZE 80,22
      @ 136,194 GET oMainPrg VAR vGt6 ID ID_PRGMAIN  SIZE 206,24
      @ 347,194 OWNERBUTTON    SIZE 24,24   ;
          ON CLICK {||searchFileName("xBase Files *.prg ", oMainPrg, "*.prg")};//       FLAT;
          TEXT "..." ;//BITMAP "SEARCH" FROM RESOURCE TRANSPARENT COORDINATES 0,0,0,0 ;
          TOOLTIP "Search main file"

   END PAGE of oTAB
   BEGIN PAGE "Prg (Files)" of oTAB
      @ 21,29 BROWSE oBrowse1 ARRAY of oTAB ON CLICK {||SearchFile(oBrowse1,"*.prg")};
              STYLE WS_VSCROLL + WS_HSCROLL   SIZE 341,170
      hwg_CREATEARLIST(oBrowse1,aFiles1)
      obrowse1:acolumns[1]:heading := "File Names"
      obrowse1:acolumns[1]:length := 50
      oBrowse1:bcolorSel := hwg_ColorC2N( "800080" )
      oBrowse1:ofont := HFont():Add( 'Arial',0,-12 )
      @ 10, 205 BUTTON "Add"     SIZE 60,25  on click {||SearchFile(oBrowse1, "*.prg")}
      @ 70, 205 BUTTON "Delete"  SIZE 60,25  on click {||Adel(oBrowse1:aArray, oBrowse1:nCurrent),oBrowse1:Refresh()}

   END PAGE of oTAB
   BEGIN PAGE "C (Files)" of oTAB
      @ 21,29 BROWSE oBrowse2 ;
         ARRAY ;
         of oTAB ;
         ON CLICK {||SearchFile(oBrowse2, "*.c")};
         STYLE WS_VSCROLL + WS_HSCROLL   SIZE 341,170

      hwg_CREATEARLIST(oBrowse2,aFiles2)
      obrowse2:acolumns[1]:heading := "File Names"
      obrowse2:acolumns[1]:length := 50
      oBrowse2:bcolorSel := hwg_ColorC2N( "800080" )
      oBrowse2:ofont := HFont():Add( 'Arial',0,-12 )

      @ 10, 205 BUTTON "Add"     SIZE 60,25  on click {||SearchFile(oBrowse2, "*.c")}

      @ 70, 205 BUTTON "Delete"  SIZE 60,25  on click {||Adel(oBrowse1:aArray, oBrowse2:nCurrent),oBrowse2:Refresh()}
   END PAGE of oTAB
   BEGIN PAGE "Lib (Files)" of oTAB
      @ 21,29 BROWSE oBrowse3 ARRAY of oTAB ON CLICK {||SearchFile(oBrowse3, "*.lib")};
               STYLE WS_VSCROLL + WS_HSCROLL   SIZE 341,170
      hwg_CREATEARLIST(oBrowse3,aFiles3)
      obrowse3:acolumns[1]:heading := "File Names"
      obrowse3:acolumns[1]:length := 50
      oBrowse3:bcolorSel := hwg_ColorC2N( "800080" )
      oBrowse3:ofont := HFont():Add( 'Arial',0,-12 )
      @ 10, 205 BUTTON "Add"     SIZE 60,25  on click {||SearchFile(oBrowse3, "*.lib")}
      @ 70, 205 BUTTON "Delete"  SIZE 60,25  on click {||Adel(oBrowse3:aArray, oBrowse3:nCurrent),oBrowse3:Refresh()}
   END PAGE of oTAB
   BEGIN PAGE "Resource (Files)" of oTAB
      @ 21,29 BROWSE oBrowse4 ARRAY of oTAB ON CLICK {||SearchFile(oBrowse3, "*.rc")};
              STYLE WS_VSCROLL + WS_HSCROLL   SIZE 341,170
      hwg_CREATEARLIST(oBrowse4,aFiles4)
      obrowse4:acolumns[1]:heading := "File Names"
      obrowse4:acolumns[1]:length := 50
      oBrowse4:bcolorSel := hwg_ColorC2N( "800080" )
      oBrowse4:ofont := HFont():Add( 'Arial',0,-12 )
      @ 10, 205 BUTTON "Add"     SIZE 60,25  on click {||SearchFile(oBrowse4, "*.rc")}
      @ 70, 205 BUTTON "Delete"  SIZE 60,25  on click {||Adel(oBrowse4:aArray, oBrowse4:nCurrent),oBrowse4:Refresh()}
   END PAGE of oTAB

   @ 419, 20 BUTTON oButton1 CAPTION "Build" on Click {||BuildApp()} SIZE 78,52
   @ 419, 80 BUTTON oButton2 CAPTION "Exit" on Click {||hwg_EndDialog()}  SIZE 78,52
   @ 419,140 BUTTON oButton3 CAPTION "Open" on Click {||ReadBuildFile()}  SIZE 78,52
   @ 419,200 BUTTON oButton4 CAPTION "Save" on Click {||SaveBuildFile()}  SIZE 78,52

   ACTIVATE DIALOG oDlg

RETURN Nil

STATIC FUNCTION SearchFile(oBrow, oFile)

   LOCAL oTotReg:={}, i
   LOCAL aSelect:=hwg_SelectMultipleFiles("xBase Files ("+oFile+")", oFile )

   IF len( aSelect ) ==0
      return Nil
   ENDIF
   IF LEN( oBrow:aArray ) == 1 .and. obrow:aArray[ 1 ] == ""
      obrow:aArray := {}
   ENDIF
   FOR i := 1 TO Len( oBrow:aArray )
      AADD( oTotReg, oBrow:aArray[ i ] )
   NEXT
   FOR i := 1 to Len( aSelect )
      AADD( oTotReg, aSelect[ i ] )
   NEXT
   obrow:aArray := oTotReg
   obrow:refresh()

RETURN Nil

STATIC FUNCTION SearchFileName(nName, oGet, oFile)

   LOCAL oTextAnt:=oGet:GetText()
   LOCAL fFile:=hwg_Selectfile(nName+" ("+oFile+")", oFile,,,.T. )

   IF !Empty( oTextAnt )
      fFile := oTextAnt //
   ENDIF
   oGet:SetText(fFile)
   oGet:Refresh()

RETURN Nil

FUNCTION ReadBuildFile()

   LOCAL oBr1:={}, oBr2:={}, oBr3:={}, oBr4:={}, oSel1, oSel2, oSel3, i, oSel4 // oLibFiles
   //LOCAL aPal:=""
   LOCAL oFolderFile:=hwg_Selectfile("HwGUI File Build (*.bld)", "*.bld" )

   IF empty( oFolderFile )
      RETURN Nil
   ENDIF

   oExeName:SetText( Hwg_GetIni( 'Config', 'ExeName' , , oFolderFile ))
   oLibFolder:SetText(Hwg_GetIni( 'Config', 'LibFolder' , , oFolderFile ))
   oIncFolder:SetText(Hwg_GetIni( 'Config', 'IncludeFolder' , , oFolderFile ))
   oPrgFlag:SetText(Hwg_GetIni( 'Config', 'PrgFlags' , , oFolderFile ))
   oCFlag:SetText(Hwg_GetIni( 'Config', 'CFlags' , , oFolderFile ))
   oMainPrg:SetText(Hwg_GetIni( 'Config', 'PrgMain' , , oFolderFile ))

   FOR i := 1 to 300
      oSel1:=Hwg_GetIni( 'FilesPRG', Alltrim(Str(i)) , , oFolderFile )
      IF !empty(oSel1) //.or. oSel1#Nil
         AADD(oBr1, oSel1)
      ENDIF
   NEXT

   FOR i := 1 TO 300
      oSel2 := Hwg_GetIni( 'FilesC', Alltrim(Str(i)) , , oFolderFile )
      IF !empty(oSel2) //.or. oSel2#Nil
         AADD(oBr2, oSel2)
      ENDIF
   NEXT

   FOR i := 1 TO 300
      oSel3 := Hwg_GetIni( 'FilesLIB', Alltrim(Str(i)) , , oFolderFile )
      IF !empty(oSel3) //.or. oSel3#Nil
         AADD(oBr3, oSel3)
      ENDIF
   NEXT

   FOR i:=1 to 300
      oSel4:=Hwg_GetIni( 'FilesRES', Alltrim(Str(i)) , , oFolderFile )
      IF !empty(oSel4) //.or. oSel4#Nil
         AADD(oBr4, oSel4)
      ENDIF
   NEXT

   oBrowse1:aArray:=oBr1
   oBrowse2:aArray:=oBr2
   oBrowse3:aArray:=oBr3
   oBrowse4:aArray:=oBr4
   oBrowse1:Refresh()
   oBrowse2:Refresh()
   oBrowse3:Refresh()
   oBrowse4:Refresh()

RETURN Nil

FUNCTION SaveBuildFile()

   LOCAL i //, oNome // , g // oLibFiles
   LOCAL oFolderFile:=hwg_Savefile("*.bld", "HwGUI File Build (*.bld)", "*.bld" )

   IF empty(oFolderFile)
      RETURN Nil
   ENDIF
   IF file(oFolderFile)
      IF hwg_Msgyesno("File "+oFolderFile+" EXIT ..Replace?")
         Erase( oFolderFile )
      ELSE
         hwg_Msginfo("No file SAVED.")
         RETURN Nil
      ENDIF
   ENDIF
   Hwg_WriteIni( 'Config', 'ExeName'       ,oExeName:GetText(), oFolderFile )
   Hwg_WriteIni( 'Config', 'LibFolder'     ,oLibFolder:GetText(), oFolderFile )
   Hwg_WriteIni( 'Config', 'IncludeFolder' ,oIncFolder:GetText(), oFolderFile )
   Hwg_WriteIni( 'Config', 'PrgFlags'      ,oPrgFlag:GetText(), oFolderFile )
   Hwg_WriteIni( 'Config', 'CFlags'        ,oCFlag:GetText(), oFolderFile )
   Hwg_WriteIni( 'Config', 'PrgMain'       ,oMainPrg:GetText(), oFolderFile )
   //oNome:=""

   IF Len(oBrowse1:aArray)>=1
      FOR i := 1 TO Len(oBrowse1:aArray)
         IF !empty(oBrowse1:aArray[i])
            Hwg_WriteIni( 'FilesPRG', Alltrim(Str(i)),oBrowse1:aArray[i], oFolderFile )
         ENDIF
      NEXT
   ENDIF

   IF Len(oBrowse2:aArray)>=1
      FOR i := 1 to Len(oBrowse2:aArray)
         IF !empty(oBrowse2:aArray[i])
            Hwg_WriteIni( 'FilesC', Alltrim(Str(i)),oBrowse2:aArray[i], oFolderFile )
         ENDIF
      NEXT
   ENDIF

   IF Len(oBrowse3:aArray)>=1
      FOR i:=1 TO Len(oBrowse3:aArray)
         IF !empty(oBrowse3:aArray[i])
            Hwg_WriteIni( 'FilesLIB', Alltrim(Str(i)),oBrowse3:aArray[i], oFolderFile )
         ENDIF
      NEXT
   ENDIF

   IF Len(oBrowse4:aArray)>=1
      FOR i := 1 TO Len(oBrowse4:aArray)
         IF !empty(oBrowse4:aArray[i])
            Hwg_WriteIni( 'FilesRES', Alltrim(Str(i)),oBrowse4:aArray[i], oFolderFile )
         ENDIF
      NEXT
   ENDIF

   hwg_Msginfo("File "+oFolderFile+" saved","HwGUI Build")

RETURN Nil

FUNCTION BuildApp()

   IF hwg_Msgyesno("Yes Compile to BAT, No compile to PoMake")
      BuildBat()
   ELSE
      BuildPoMake()
   ENDIF

RETURN NIL

FUNCTION BuildBat()

   LOCAL voExeName, voIncFolder, voPrgFlag, voCFlag, voPrgMain, voPrgFiles, voCFiles,voResFiles // voLibFolder,
   LOCAL oName, oInc, lName // , gDir // oLibFiles
   LOCAL oArq:=fCreate("Hwg_Build.bat"),i, vHwGUI, vHarbour, vPelles
   //LOCAL \
   LOCAL g

   IF File(oDirec+"BuildPelles.Ini")
      vHwGUI:=Hwg_GetIni( 'Config', 'DIR_HwGUI' , , oDirec+"BuildPelles.Ini" )
      vHarbour:=Hwg_GetIni( 'Config', 'DIR_HARBOUR' , , oDirec+"BuildPelles.Ini")
      vPelles:=Hwg_GetIni( 'Config', 'DIR_PELLES' , , oDirec+"BuildPelles.Ini" )
   ELSE
      vHwGUI:="C:\HWGUI"
      vHarbour:="C:\Harbour"
      vPelles:="C:\Pocc"
   ENDIF
   voExeName  :=oExeName:GetText()
   //voLibFolder:=oLibFolder:GetText()
   voIncFolder:=oIncFolder:GetText()
   voPrgFlag  :=oPrgFlag:GetText()
   voCFlag    :=oCFlag:GetText()
   voPrgMain  :=oMainPrg:GetText()

   voPrgFiles :=oBrowse1:aArray
   voCFiles   :=oBrowse2:aArray
   //voLibFiles :=oBrowse3:aArray
   voResFiles :=oBrowse4:aArray

   fwrite(oArq,"@echo off"+CRF)

   oName:=Substr(voPrgMain,1,Len(voPrgMain)-4)
   lName:=""
   FOR i:=1 to Len(oName)
      IF Substr(oName, -i, 1)="\"
         EXIT
      ENDIF
      lName+=Substr(oName, -i, 1)
   NEXT
   oName:=""
   FOR i:=1 to Len(lName)
      oName+=Substr(lName, -i, 1)
   NEXT
   fwrite(oArq,"ECHO "+oName+".obj > make.tmp "+CRF)

   IF Len(voPrgFiles)>0

      FOR i:=1 to Len(voPrgFiles)

         IF !empty( voPrgFiles[i] )
            oName:=Substr(voPrgFiles[i],1,Len(voPrgFiles[i])-4)
            lName:=""
            FOR g:=1 TO Len(oName)
               IF Substr(oName, -g, 1)="\"
                  EXIT
               ENDIF
               lName+=Substr(oName, -g, 1)
            NEXT
            oName:=""
            FOR g:=1 TO Len(lName)
               oName+=Substr(lName, -g, 1)
            NEXT
            fwrite(oArq,"ECHO "+oName+".obj >> make.tmp "+CRF)
         ENDIF

      NEXT
   ENDIF

   //fwrite(oArq,"ECHO "+voExeName+".obj > make.tmp "+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\rtl%HB_MT%.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\vm%HB_MT%.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\gtwin.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\lang.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\codepage.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\macro%HB_MT%.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\rdd%HB_MT%.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\dbfntx%HB_MT%.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\dbfcdx%HB_MT%.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\dbfdbt%HB_MT%.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\common.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\debug.lib  >> make.tmp"+CRF)
   fwrite(oArq,"echo "+vHarbour+"\lib\pp.lib  >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vHarbour+"\LIB\optcon.lib>> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vHarbour+"\LIB\optgui.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vHarbour+"\LIB\nulsys.lib  >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vHarbour+"\LIB\hbodbc.lib   >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vHarbour+"\LIB\samples.lib   >> make.tmp"+CRF)

   fwrite(oArq,"ECHO "+vHwGUI+"\LIB\hwgui.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vHwGUI+"\LIB\procmisc.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vHwGUI+"\LIB\hbxml.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vHwGUI+"\LIB\hwg_qhtm.lib >> make.tmp"+CRF)

   fwrite(oArq,"ECHO "+vPelles+"\LIB\kernel32.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vPelles+"\LIB\comctl32.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vPelles+"\LIB\comdlg32.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vPelles+"\LIB\delayimp.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vPelles+"\LIB\ole32.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vPelles+"\LIB\shell32.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vPelles+"\LIB\oleaut32.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vPelles+"\LIB\user32.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vPelles+"\LIB\gdi32.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vPelles+"\LIB\winspool.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vPelles+"\LIB\uuid.lib >> make.tmp"+CRF)
   fwrite(oArq,"ECHO "+vPelles+"\LIB\portio.lib >> make.tmp"+CRF)
   fwrite(oArq,"IF EXIST "+voExeName+".res echo "+voExeName+".res  >> make.tmp"+CRF)

   oName:=Substr(voPrgMain,1,Len(voPrgMain)-4)

   fwrite(oArq,vHarbour+"\BIN\HARBOUR "+voPrgMain+;
      " -o"+oName+;
      " -i"+vPelles+"\INCLUDE;"+vHarbour+"\INCLUDE;"+vHwGUI+"\INCLUDE"+iif(!empty(voIncFolder),";","")+voIncFolder+" "+voPrgFlag+" -n -q0 -es2 -gc0"+CRF)

   IF Len(voPrgFiles)>0
      FOR i:=1 to Len(voPrgFiles)
         IF !empty( voPrgFiles[i] )
            oName:=Substr(voPrgFiles[i],1,Len(voPrgFiles[i])-4)
            fwrite(oArq,vHarbour+"\BIN\HARBOUR "+voPrgFiles[i]+;
               " -o"+oName+;
               " -i"+vPelles+"\INCLUDE;"+vHarbour+"\INCLUDE;"+vHwGUI+"\INCLUDE"+iif(!empty(voIncFolder),";","")+voIncFolder+" "+voPrgFlag+" -n -q0 -es2 -gc0"+CRF)
         ENDIF
      NEXT
   ENDIF

   oName:=Substr(voPrgMain,1,Len(voPrgMain)-4)
   fwrite(oArq,vPelles+'\bin\pocc '+oName+'.c '+voCFlag+' /Ze /D"NEED_DUMMY_RETURN" /D"__XCC__" /I"INCLUDE" /I"'+vHarbour+'\INCLUDE" /I"'+vPelles+'\INCLUDE" /I"'+vPelles+'\INCLUDE\WIN" /I"'+vPelles+'\INCLUDE\MSVC" /D"HB_STATIC_STARTUP" /c'+CRF)


   IF Len(voPrgFiles)>0
      FOR i:=1 TO Len(voPrgFiles)
         IF !empty( voPrgFiles[i] )
            oName:=Substr(voPrgFiles[i],1,Len(voPrgFiles[i])-4)
            fwrite(oArq,vPelles+'\bin\pocc '+oName+'.c '+voCFlag+' /Ze /D"NEED_DUMMY_RETURN" /D"__XCC__" /I"INCLUDE" /I"'+vHarbour+'\INCLUDE" /I"'+vPelles+'\INCLUDE" /I"'+vPelles+'\INCLUDE\WIN" /I"'+vPelles+'\INCLUDE\MSVC" /D"HB_STATIC_STARTUP" /c'+CRF)
         ENDIF
      NEXT
   ENDIF

   if Len(voCFiles)>0
      oInc:=""
      FOR i:=1 to Len(voCFiles)
         IF !empty(voCFiles[i])
            IF !empty(oIncFolder)
               oInc:='/I"'+voIncFolder+'"'
            ENDIF
            fwrite(oArq,vPelles+'\bin\pocc '+voCFiles[i]+' /Ze /D"NEED_DUMMY_RETURN" /D"__XCC__" /I"INCLUDE" /I""+vHarbour+"\INCLUDE" /I""+vPelles+"\INCLUDE" /I""+vPelles+"\INCLUDE\WIN" /I"'+vPelles+'\INCLUDE\MSVC" '+oInc+' /D"HB_STATIC_STARTUP" /c'+CRF)
         ENDIF
      NEXT
   ENDIF

   IF Len(voResFiles)>0
      //oInc:=""
      FOR i:=1 TO Len(voResFiles)
         IF !Empty(voResFiles[i])
            fwrite(oArq,vPelles+'\BIN\porc -r '+voResFiles[i]+' -foobj\'+voExeName+CRF)
         ENDIF
      NEXT
   ENDIF

   fwrite(oArq,vPelles+'\bin\POLINK /LIBPATH:'+vPelles+'\lib /OUT:'+voExeName+'.EXE /MACHINE:IX86 /OPT:WIN98 /SUBSYSTEM:WINDOWS /FORCE:MULTIPLE @make.tmp >error.log'+CRF)
   fwrite(oArq,'DEL make.tmp'+CRF)

   oName:=Substr(voPrgMain,1,Len(voPrgMain)-4)
   /*
   fwrite(oArq,'Del '+oName+'.c '+CRF)
   fwrite(oArq,'Del '+oName+'.map'+CRF)
   fwrite(oArq,'Del '+oName+'.obj'+CRF)

   for i:=1 to Len(voPrgFiles)
      if !empty( voPrgFiles[i] )
         oName:=Substr(voPrgFiles[i],1,Len(voPrgFiles[i])-4)
         fwrite(oArq,'Del '+oName+'.c '+CRF)
         fwrite(oArq,'Del '+oName+'.map'+CRF)
         fwrite(oArq,'Del '+oName+'.obj'+CRF)
     endif
   next
   */
   fClose(oArq)

   __Run("Hwg_Build.bat>Error.log")

   IF file(voExeName+".exe")
      hwg_Msginfo("File "+ voExeName+".exe Build correct")
   ELSE
      hwg_Shellexecute("NotePad error.log")
   ENDIF

RETURN Nil

FUNCTION BuildPoMake()

   LOCAL voExeName, voIncFolder, voPrgMain, voPrgFiles, voCFiles //,voResFiles, voCFlag, voLibFolder, voPrgFlag
   LOCAL oName //, oInc //, lName //, gDir, oLibFiles, CRF:=CHR(13)+CHR(10)
   LOCAL oArq:=fCreate("Makefile.pc"),i, vHwGUI, vHarbour, vPelles
   //LOCAL voLibFiles

   If File(oDirec+"BuildPelles.Ini")
      vHwGUI:=Hwg_GetIni( 'Config', 'DIR_HwGUI' , , oDirec+"BuildPelles.Ini" )
      vHarbour:=Hwg_GetIni( 'Config', 'DIR_HARBOUR' , , oDirec+"BuildPelles.Ini")
      vPelles:=Hwg_GetIni( 'Config', 'DIR_PELLES' , , oDirec+"BuildPelles.Ini" )
   ELSE
      vHwGUI:="C:\HWGUI"
      vHarbour:="C:\Harbour"
      vPelles:="C:\Pocc"
   ENDIF

   voExeName  :=oExeName:GetText()
   //voLibFolder:=oLibFolder:GetText()
   voIncFolder:=oIncFolder:GetText()
   //voPrgFlag  :=oPrgFlag:GetText()
   //voCFlag    :=oCFlag:GetText()
   voPrgMain  :=oMainPrg:GetText()

   voPrgFiles :=oBrowse1:aArray
   voCFiles   :=oBrowse2:aArray
   //voLibFiles :=oBrowse3:aArray
   //voResFiles :=oBrowse4:aArray

   fwrite(oArq,"# makefile for Pelles C 32 bits"+CRF)
   fwrite(oArq,"# Building of App Using Pomake"+CRF)

   fwrite(oArq,"# Comment the following for HARBOUR"+CRF)
   fwrite(oArq,"__XHARBOUR__ = 1"+CRF)

   fwrite(oArq,"HRB_DIR = "+vHarbour+CRF)
   fwrite(oArq,"POCCMAIN = "+vPelles+CRF)
   fwrite(oArq,"INCLUDE_DIR = include;"+vHarbour+"\include"+;
      iif(!empty(voIncFolder),";"+voIncFolder,"")+CRF)
   fwrite(oArq,"OBJ_DIR = obj"+CRF)
   fwrite(oArq,"LIB_DIR = "+vHwGUI+"\lib"+CRF)
   fwrite(oArq,"SRC_DIR = source"+CRF+CRF)

   fwrite(oArq,"HARBOUR_EXE = HARBOUR "+CRF)
   fwrite(oArq,"CC_EXE = $(POCCMAIN)\BIN\POCC.EXE "+CRF)
   fwrite(oArq,"LIB_EXE = $(POCCMAIN)\BIN\POLINK.EXE "+CRF)
   fwrite(oArq,"HARBOURFLAGS = -i$(INCLUDE_DIR) -n1 -q0 -w -es2 -gc0"+CRF)
   fwrite(oArq,'CFLAGS = /Ze /I"INCLUDE" /I"$(HRB_DIR)\INCLUDE" /I"$(POCCMAIN)\INCLUDE" /I"$(POCCMAIN)\INCLUDE\WIN" /I"$(POCCMAIN)\INCLUDE\MSVC" /D"HB_STATIC_STARTUP" /c'+CRF)

   //# Please Note that /Op and /Go requires POCC version 2.80 or later
   fwrite(oArq,'CFLAGS = $(CFLAGS) /Op /Go'+CRF)

   fwrite(oArq,'!ifdef __XHARBOUR__ '+CRF)
   fwrite(oArq,'CFLAGS = $(CFLAGS) /D"XHBCVS" '+CRF)
   fwrite(oArq,'!endif '+CRF)

   fwrite(oArq,'!ifndef ECHO'+CRF)
   fwrite(oArq,'ECHO = echo.'+CRF)
   fwrite(oArq,'!endif'+CRF)
   fwrite(oArq,'!ifndef DEL'+CRF)
   fwrite(oArq,'DEL = del'+CRF)
   fwrite(oArq,'!endif'+CRF+CRF)

   fwrite(oArq,'HWGUI_LIB = $(LIB_DIR)\hwgui.lib'+CRF)
   fwrite(oArq,'PROCMISC_LIB = $(LIB_DIR)\procmisc.lib'+CRF)
   fwrite(oArq,'XML_LIB = $(LIB_DIR)\hbxml.lib'+CRF)
   fwrite(oArq,'QHTM_LIB = $(LIB_DIR)\hwg_qhtm.lib'+CRF+CRF)

   fwrite(oArq,'all: \'+CRF)
   fwrite(oArq,'   $(HWGUI_LIB) \'+CRF)
   fwrite(oArq,'   $(PROCMISC_LIB) \'+CRF)
   fwrite(oArq,'   $(XML_LIB) \'+CRF)
   fwrite(oArq,'   $(QHTM_LIB)'+CRF+CRF)

   fwrite(oArq,'FILE_OBJS = \'+CRF)
   oName:=Substr(voPrgMain,1,Len(voPrgMain)-4)
   /*lName:=""
   for i:=1 to Len(oName)
      if Substr(oName, -i, 1)="\"
         Exit
      Endif
      lName+=Substr(oName, -i, 1)
   Next
   oName:=""
   for i:=1 to Len(lName)
      oName+=Substr(lName, -i, 1)
   Next
   */
   fwrite(oArq,oName+".obj \ "+CRF)

   if Len(voPrgFiles)>0

      for i:=1 to Len(voPrgFiles)

         if !empty( voPrgFiles[i] )

            oName:=Substr(voPrgFiles[i],1,Len(voPrgFiles[i])-4)
            /*
            lName:=""
            for g:=1 to Len(oName)
               if Substr(oName, -g, 1)="\"
                  Exit
               Endif
               lName+=Substr(oName, -g, 1)
            Next
            oName:=""
            for g:=1 to Len(lName)
               oName+=Substr(lName, -g, 1)
            Next
            fwrite(oArq,"$(OBJ_DIR)\"+oName+".obj ")
            */
            fwrite(oArq,oName+".obj ")

            IF i<len(voPrgFiles)
               fwrite(oArq,"\"+CRF)
            ELSE
               fwrite(oArq,CRF+CRF)
            ENDIF
         ENDIF
      NEXT
   ENDIF

   fwrite(oArq,voExeName+ ": $(FILE_OBJS)"+CRF)
   fwrite(oArq,"   $(LIB_EXE) /out:$@ $** "+CRF+CRF)

   oName:=Substr(voPrgMain,1,Len(voPrgMain)-4)

   fwrite(oArq,oName+".c : "+voPrgMain+CRF)
   fwrite(oArq,"   $(HARBOUR_EXE) $(HARBOURFLAGS) $** -o$@"+CRF+CRF)

   IF Len(voPrgFiles)>0
      FOR i:=1 to Len(voPrgFiles)
         IF !empty( voPrgFiles[i] )
            oName:=Substr(voPrgFiles[i],1,Len(voPrgFiles[i])-4)
            fwrite(oArq,oName+".c : "+voPrgFiles[i]+CRF)
            fwrite(oArq,"   $(HARBOUR_EXE) $(HARBOURFLAGS) $** -o$@"+CRF+CRF)
         ENDIF
      NEXT
   ENDIF
   oName:=Substr(voPrgMain,1,Len(voPrgMain)-4)
   fwrite(oArq,oName+".obj : "+oName+".c"+CRF)
   fwrite(oArq,"   $(CC_EXE) $(CFLAGS) /Fo$@ $** "+CRF+CRF)

   IF Len(voPrgFiles)>0
      FOR i:=1 to Len(voPrgFiles)
         IF !empty( voPrgFiles[i] )
            oName:=Substr(voPrgFiles[i],1,Len(voPrgFiles[i])-4)
            fwrite(oArq,oName+".obj : "+oName+".c"+CRF)
            fwrite(oArq, "   $(CC_EXE) $(CFLAGS) /Fo$@ $** "+CRF+CRF)
         ENDIF
      NEXT
   ENDIF

   IF Len(voCFiles)>0
      //oInc:=""
      FOR i:=1 to Len(voCFiles)
         IF !empty(voCFiles[i])
            //IF !empty(oIncFolder)
               //oInc:='/I"'+voIncFolder+'"'
            //ENDIF
            oName:=Substr(voCFiles[i],1,Len(voCFiles[i])-4)
            fwrite(oArq,oName+".obj : "+voCFiles[i]+CRF)
            fwrite(oArq, "   $(CC_EXE) $(CFLAGS) /Fo$@ $** "+CRF)
         ENDIF
      NEXT
   ENDIF

   fClose(oName)

RETURN Nil
