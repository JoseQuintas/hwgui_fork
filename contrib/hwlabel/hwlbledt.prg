*
* hwlbledt.prg
*
*
* $Id$
*
* HWGUI - Harbour Win32 and Linux (GTK) GUI library
*
* Label editor for HWGUI
*
* Copyright 2022 Wilfried Brunken, DF7BE
* https://sourceforge.net/projects/cllog/
*
* License:
* GNU General Public License
* with special exceptions of HWGUI.
* See file "license.txt" for details of
* HWGUI project at
*  https://sourceforge.net/projects/hwgui/
*
* This is the port of a label editor to HWGUI.
* The label editor is almost implememented in Clipper
* in the utility RL.EXE, in S'87 as LABEL.EXE.
* This work based on the label editor of project "CLLOG"
* which is written for Harbour as a console application.
*
* Codepages stored in label:
* Recent setting of codepage is IBM DE858.
* (OK for most european countries with Euro currency sign)
*
* The following C structure presents the structure of a *.LBL-File
* ( total size fixed 1034 bytes )
* Die folgende C-Struktur gibt den Inhalt einer LBL-Datei wieder
* (ingesamt 1034 Bytes fix)
*
* #define INFO_COUNT 16
* #define INFO_SIZE 60

* LBL file structure *
* typedef struct
* {
*  char sign1;
*  char remarks[60];
*  short height;
*  short width;
*  short left_marg;
*  short label_line;
*  short label_space;      (spaces between labels, vert. Abstand)
*  short label_across;
*  char info[INFO_COUNT][INFO_SIZE]; (16 x 60 = 960 bytes)
*  char sign2;
* } LABEL_STRUC;

* #define INFO_COUNT 16
* #define INFO_SIZE 60
*
* Offset                            Hex   /  Dec
* typedef struct
* {
*   char sign1;                   /* 0000  /  0     */
*   char remarks[60];             /* 0001  /  1     */  /* Not NULL terminated */
*   short height;                 /* 003D  /  61    */
*   short width;                  /* 003F  /  63    */
*   short left_marg;              /* 0041  /  65    */  (left margin, linker Rand)
*   short label_line;             /* 0043  /  67    */  (lines between labels,  horiz.Abstand)
*   short label_space;            /* 0045  /  69    */  (Spaces between labels, vert. Abstand  0 .. 120 )
*   short label_across;           /* 0047  /  71    */
*   char info[INFO_COUNT][INFO_SIZE]; /* 16 x 60 = 960 bytes */ /* 0049 / 73  */
*   char sign2;                   /* 0409  / 1033   */
* } LABEL_STRUC;  /* Total 1034 bytes */

/*
 Offset for contents  (Hex / Dec )
 Line 1  : 0049 / 73
 Line 2  : 0085 / 133
 Line 3  : 00C1 / 193
 Line 4  : 00FD / 253
 Line 5  : 0139 / 313
 Line 6  : 0175 / 373
 Line 7  : 01B1 / 433
 Line 8  : 01ED / 493
 Line 9  : 0229 / 553
 Line 10 : 0265 / 613
 Line 11 : 02A1 / 673
 Line 12 : 02DD / 733
 Line 13 : 0319 / 793
 Line 14 : 0355 / 853
 Line 15 : 0391 / 913
 Line 16 : 03CD / 973
*/

*
* For better return of a value of a complete label by a function,
* the complete label structure is stored in a 2 dimensional
* array as "STATIC alabelmem".
* The structure of this array is detailed in inline comments of
* FUNCTION hwlabel__LBL_READ().
*
* This source can be used as a standalone program or
* as a "library" to integrate the label editor in your own application.
* For this case add switch
* -dHWLBLEDIT into your compile script
* and call the main dialog in your app by
* HWLBLEDIT() .

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*  Supported languages:
*  - English
*  - German
* * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* =========================================================================================
* Function list
* ~~~~~~~~~~~~~
*
* ~~~~~~~~~~~~~~ MAIN section ~~~~~~~~~~~~~~~~~~~
* For standalone label editor program.
* (deactivate them by compiler switch "HWLBLEDIT" for integration in your own HWGUI application)
*
* FUNCTION HWLBLEDIT()              && Additional pre dialog (optional)
* FUNCTION hwlabel_maininit()       && Init all variables for main function

* ~~~~~~ Functions for label editor ~~~~~~~~~~
* FUNCTION hwlabel_lbledit          && Dialog label editor
* FUNCTION hwlabel_langinit         && Initializes the language settings
* FUNCTION hwlabel_resetdefs        && Reset all label parameters
* FUNCTION hwlabel_LOAD_LABEL       && Dialog load label
* FUNCTION hwlabel_SAVE_LABEL       && Dialog save label
* FUNCTION hwlabel_newlbl           && New label, clean edit area
* FUNCTION hwlabel__LBL_READ        && Read the label file and copy the contents into label array
* FUNCTION hwlabel_LBL_WRITE        && Write label file
* FUNCTION hwlabel_LBL_DEFAULTS     && Set the default values of the variables
* FUNCTION hwlabel__LBL_LINES       && Returns the number of lines (heigth of label)
* FUNCTION hwlabel_countcont        && Count the filled contents of a label.
* FUNCTION hwlabel_mod              && Interface function for modified label.
* FUNCTION hwlbledit_exit           && Exit dialog check for modified label and query
* FUNCTION hwlabel_reset_mod        && Reset modified
* FUNCTION hwlabel_str_nolabel      && Returns string for "no label set"
* FUNCTION hwlabel_warncont()       && Warnung query message, if height reduced
* FUNCTION hwlabel_ccontents        && Clean unused contents
* FUNCTION hwlabel_addextens        && Add file extension, if not passed with file name
* FUNCTION hwlabel_translcp         && Translates codepages for label file
* FUNCTION hwlabel_Check_lnc        && Check length of contents lines
* FUNCTION hwlbledit_contlwarn      && Displays warning of contents length greater than width of label
*
* Store and read language setting from file
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* (can be used optional)
* STATIC FUNCTION READ_LANGINI      && Read language setting from language.ini
* STATIC FUNCTION LANG_READ_TEXT    && Reads a text record from a binary file
* STATIC FUNCTION WRIT_LANGINI      && Write language setting to language.ini
* STATIC FUNCTION Select_LangDia && Dialog for select a language.
* STATIC FUNCTION __frm_CcomboSelect && Common Combobox Selection
*
* NLS support
* ~~~~~~~~~~~
* FUNCTION hwlabel_NLS_SetLang      && Sets the desired language for NLS
* FUNCTION hwlabel_DOS_INIT_DE      && Initialisation sequence for DOS / CP437 and CP858
* FUNCTION hwlabel_MSGS_EN          && Set Message array for english language
* FUNCTION hwlabel_MSGS_DE          && Set message array for german language
* FUNCTION hwlabel_MSGS_FR          && Set message array for french language
* FUNCTION XWIN_FR                  && Translates UTF8 to Windows charset (French)
*
* =========================================================================================
*
* Add the label editor into your own HWGUI application:
*
* - Copy this file into the source code directory of your application.
* - Add this source code file to your makefile (Makefile or *.hbp) or
*   by command "SET PROCEDURE TO ...".
* - Add -d__LINUX__ to your options for hbmk2 utility into makefile for LINUX or in *.hbp file.
* - Free "#define HWLBLEDIT" in the header of this source file to deactivate
*   the MAIN function.
* - Add the call of FUNCTION hwlabel_lbledit(clangf)
*   in the menu of your application.
*   If you have your own language selection dialog,
*   pass the language value to parameter "clangf".
*   Valid values of clangf see array initilization of "aLanguages"
*   in the function code of FUNCTION hwlabel_lbledinit().
*   If clangf is NIL, the default language "English" is selected.
*
*   Samples for *.hbp files in the HWGUI directory "samples":
*    samples\demodbfdata.hbp
*   and many more.
*
* =========================================================================================
*
* This version of "hwlabel" supports the english (default), german and french languages.
* Feel free to extend the source code of hwlabel with your language.
* Here the instructions to add a new language.
* Send us the modified source code to commit it in the subversion repository to add
* it into the next HWGUI release.
*
* Values for name and abbreviation of the new language (only ASCII characters):
* Default is:
*   clangset := "English"
*   clang    := "EN"   && only in upper case
* For example german:
*   clangset := "Deutsch"
*   clang    := "DE"
* For example french:
*   clangset := "Français"
*   clang    := "FR"
* For example russian:
*   clangset := "Russian"
*   clang    := "RU"
*
*
* - Add REQUEST command(s) needed for codepage(s) for the language to add.
*   (For Windows and LINUX, mostly UTF-8 an xxWIN  )
*
* - hwlabel_helptxt_xx()
*   Create a new function and fill it with help text,
*   For example: hwlabel_helptxt_RU()
*   Dont't forget to handle both, Windows codepages and UTF-8 character set
*   (In german only 8 characters differs, the rest is ASCII)
*   Also for all other functions !
*
* - hwlabel_Mainhlp()
*   Add block for new language.
*
*   Use function hwg__isUnicode() to decide for Windows or UTF-8 codepages.
*   Some editors like Notepad++ support Windows and UTF-8 codepages.
*
* - Extend array with name of language in FUNCTION hwlabel_langinit():
*   aLanguages := { "English", "Deutsch" , "Russian" }
*   Please in alphabetical order, but English at the beginning.
*
* - Extend CASE block with new language in FUNCTION hwlabel_NLS_SetLang(cname,omain)
*
* - FUNCTION hwlabel_MSGS_xx:
*   Create a new function and fill it with messages text, for example
*   hwlabel_MSGS_RU().
*   Copy the english version "hwlabel_MSGS_EN" as template.
*
* - FUNCTION hwlabel_DOS_INIT_xx:
*   Create a new function and initialisize special characters outside ASCII
*   for Windows codepages and UTF-8, optional
*
* - FUNCTION XWIN_xx
*   Copy the FUNCTION XWIN_FR() as template
*   Call this function before displaying a message text in your language
*
* - Add the new functions to the function list.
*
* - Add the language in comment line in the header of this file:
*   "Supported languages:"
*
*   Hint: Some editors like Notepadd++ handle UTF-8 and Windows character sets
*   by switching via the main menu.
*   For Windows and DOS characters it is strictly recomended, to set
*   your preferred editor to UTF-8 and code the special characters
*   for Windows and MS-DOS with the CHR() function.
*
* Additional information:
* - Use hwg_Array_Len() for check of empty array. The function LEN() crashes,
*   if the array to check is empty, for example:
*    atestarray := {}
*    n := LEN(atestarray)             && crashes here
*    n := hwg_Array_Len(atestarray)   && OK
*    IF n < 1
*     * Empty array ...
*     ....
*    ENDIF
* ============================================================================================
*
* #define HWLBLEDIT

#include "hwgui.ch"
#ifdef __GTK__
#include "gtk.ch"
#endif
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif
#include "hbclass.ch"
#include "hwgextern.ch"

* Free this for adding the label editor in an
* own HWGUI application (deactivate MAIN function)
* #define HWLBLEDIT


* ==== REQUESTs =====
#ifdef __LINUX__
* LINUX Codepage
REQUEST HB_CODEPAGE_UTF8
REQUEST HB_CODEPAGE_UTF8EX
#endif

* Other languages

* ==== German ====
REQUEST HB_LANG_DE
* Windows codepages
#ifndef __PLATFORM__WINDOWS
REQUEST HB_CODEPAGE_DEWIN   && German
REQUEST HB_CODEPAGE_FRWIN   && French
#endif
* For label with Euro currency sign
REQUEST HB_CODEPAGE_DE858

* ==== ???? =====


* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
* STATIC variables
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~

  STATIC aLanguages ,  clangset , clang , aMsg
  *      Marker for new label
  *      v
*  STATIC blbl_neu


* === NLS German ===
* Special signs german and Euro currency sign
*        AE      OE       UE       ae      oe       ue       sz
  STATIC CAGUML, COGUML , CUGUML , CAKUML, COKUML , CUKUML , CSZUML , EURO
* Code for variable name
*        !----- C for char-Variable, fixed
*        !+---- A = AE , O = OE , U = UE , SZ = see above
*        !!+--- G = gross / upper case  K = klein / lower case
*        !!!+-- UML for "Umlaut"
*        !!!!
*       CAGUML
*        !!
*        ++ "SZ" for ss (sharp "s", ss is not greek beta sign !!!)
* ==================
*

* Label file name

STATIC  lblname


* Variables with recent label values for editing (edit area)
*       (is filled with load from file and saved to label file)
STATIC c_REM,n_NUMZ,n_BR,n_LM,n_HZR,N_VZR,n_LPZ, ;
c_INH1, c_INH2, c_INH3, c_INH4 , c_INH5 , c_INH6, ;
c_INH7, c_INH8, c_INH9, c_INH10 , c_INH11, c_INH12 , c_INH13, c_INH14, c_INH15, c_INH16

* Variables save old edit area
STATIC c_REM_old,n_NUMZ_old,n_BR_old,n_LM_old,n_HZR_old,N_VZR_old,n_LPZ_old, ;
c_INH1_old, c_INH2_old, c_INH3_old, c_INH4_old , c_INH5_old , c_INH6_old, ;
c_INH7_old, c_INH8_old, c_INH9_old, c_INH10_old , c_INH11_old, c_INH12_old , ;
c_INH13_old, c_INH14_old, c_INH15_old, c_INH16_old



* ==============================================
#ifdef HWLBLEDIT
FUNCTION HWLBLEDIT()
#else
FUNCTION MAIN()
#endif
* FUNCTION Label_Editor
* (modify, if the label editor is called
*  by your application)
* ==============================================

LOCAL olbleditMain , oFontMain
LOCAL cValicon , oIcon

cValicon     := hwg_cHex2Bin ( hwlbl_IconHex() )
oIcon        := HIcon():AddString( "hwlabel" , cValicon )

hwlabel_maininit()

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFontMain NAME "MS Sans Serif" WIDTH 0 HEIGHT -14
#else
   PREPARE FONT oFontMain NAME "Sans" WIDTH 0 HEIGHT 12
#endif

#ifdef HWLBLEDIT
        INIT DIALOG olbleditMain TITLE aMsg[1] ;
        ICON oIcon ;
        FONT oFontMain SIZE 350, 100
#else
        INIT WINDOW olbleditMain MAIN TITLE aMsg[1] ;
        ICON oIcon ;
        FONT oFontMain SIZE 350, 100
#endif


* Main Menu
        MENU OF olbleditMain
         MENU TITLE aMsg[4]  && "&File"
             MENUITEM aMsg[5]  ACTION {|| olbleditMain:Close() } && "&Quit"
         ENDMENU
         MENU TITLE aMsg[29] && "&Label"
             MENUITEM aMsg[8] ACTION hwlabel_lbledit() && "&Edit", Start the label editor
         ENDMENU
         MENU TITLE aMsg[14]  && Configuration
            MENUITEM aMsg[13] ACTION  Select_LangDia(aLanguages,olbleditMain)  && Language
         ENDMENU
        ENDMENU

#ifdef HWLBLEDIT
        ACTIVATE DIALOG olbleditMain
#else
        ACTIVATE WINDOW olbleditMain
#endif

RETURN NIL

* ======================================================
*  FUNCTIONS
* ======================================================

* ==============================================
FUNCTION hwlabel_maininit()
* Init all variables for main function
* ==============================================
 hwlabel_langinit()
RETURN NIL

* ==============================================
FUNCTION hwlabel_lbledinit(clangf)
* Initialize the static variables of
* the label editor and
* reads language.ini for language selection.
* This function is called at the beginning
* of the function for the main dialog
* of the label editor: hwlabel_lbledit()
*
* Language setting procedure:
* If file not exists, the default values
* for english language are initialized.
* clangf:
* Force this language setting with
* reading setting from file "language.ini".
* This is useful, if you want to call
* the label from your own HWGUI application
* with an own language settings dialog.
* Valid values of clangf
* see array initilization of "aLanguages"
* in this function code.
* ==============================================
SET EXACT ON

SET DATE GERMAN  // DD.MM.YYYY also OK for Russian
SET CENTURY ON

READINSERT(.T.)


* Preset default values
hwlabel_LBL_DEFAULTS()
* For remembering old values
hwlabel_reset_mod()

* blbl_neu := .F.  && Kennzeichnung fuer ein neues Label
                 && marker for new label

 hwlabel_langinit(clangf)



* String for "No label" dependant on language setting
lblname := hwlabel_str_nolabel()

RETURN NIL


* ============================================================
FUNCTION hwlabel_langinit(clangf)
* Initializes the language settings
* clangf : Sets the language,
* if label editor is integrated in an own application.
* Values valid see preset of array "aLanguages".
* If NIL:
* Try to get language from file "language.ini",
* if not existing, set to default "English".
* ============================================================

LOCAL cfrancais :=  XWIN_FR("Français")

/* Names of supported languages, use only ANSI charset, displayed in language selection dialog */
   aLanguages := { "English", "Deutsch", cfrancais }

/* Initialization with default language english */

   clangset := "English"
   clang    := "EN"

* Load default messages in english
aMsg := hwlabel_MSGS_EN()

IF clangf == NIL
* Read ini file for recent language setting
  clangset := READ_LANGINI()
ELSE
  clangset := clangf
ENDIF
  * hwg_msginfo(clangset)  && Debug
  hwlabel_NLS_SetLang(clangset)

RETURN NIL

* ============================================================
FUNCTION hwlabel_lbledit(clangf,cCpLocWin,cCpLocLINUX,cCpLabel)
* Dialog label editor
* === This is the main dialog function of the label editor ===
* clangf : Set Dialog language:
*         "English" (Default)
*         "Deutsch" : German
*         "Français" : French
*         "??" : Feel free to add your language,
*                see for instructions in the
*                inline comments.
*
* This is the complete label editor.
* You can call this code in your
* application.
*
* Parameters for codepage:
* See description of function hwlabel_translcp()
*
*
* ============================================================
LOCAL cValicon , oIcon
LOCAL olbldlg , oFontMain, oSay
*

hwlabel_lbledinit(clangf)

cValicon     := hwg_cHex2Bin ( hwlbl_IconHex() )
oIcon        := HIcon():AddString( "hwlabel" , cValicon )

lblname := aMsg[26]   && "<NO LABEL>"


#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFontMain NAME "MS Sans Serif" WIDTH 0 HEIGHT -14
#else
   PREPARE FONT oFontMain NAME "Sans" WIDTH 0 HEIGHT 12
#endif

       INIT DIALOG olbldlg TITLE aMsg[1] ;
        FONT oFontMain SIZE 500, 300 ;
        ICON oIcon
//        ON EXIT {|| hwlbledit_exit() }

        MENU OF olbldlg
         MENU TITLE aMsg[4]    && File
             MENUITEM aMsg[6] ACTION  {|| lblname := hwlabel_LOAD_LABEL(lblname,cCpLocWin,cCpLocLINUX,cCpLabel) , ;
                oSay:SetText(lblname) }  && Load
             MENUITEM aMsg[32] ACTION  {|| hwlabel_newlbl() , ;
                lblname := aMsg[26] ,  oSay:SetText(lblname)  }  && New
             SEPARATOR
             MENUITEM aMsg[7] ACTION  {|| lblname := hwlabel_SAVE_LABEL(lblname,cCpLocWin,cCpLocLINUX,cCpLabel) , ;
                oSay:SetText(lblname) }  && Save
             SEPARATOR
             MENUITEM aMsg[5] ACTION  {|| olbldlg:Close() }  && Quit
         ENDMENU

         MENU TITLE aMsg[8]    && Edit
             MENUITEM aMsg[9]  ACTION _frm_hwlabel_par()  && Parameters
             SEPARATOR
             MENUITEM aMsg[10] ACTION ;
             hwlabel_frm_lbl_contents(hwlabel__LBL_LINES(),"")  && Contents
                                                                        &&  cHelp added later
         ENDMENU


         MENU TITLE aMsg[11]  && Help
             MENUITEM aMsg[15] ACTION  hwlabel_Mainhlp(clangset,0) && Help
             SEPARATOR
             MENUITEM aMsg[12] ACTION  hwlabel_About()          && About
        ENDMENU

       ENDMENU

   @ 5, 50 SAY oSay CAPTION lblname SIZE 450, 90

   ACTIVATE DIALOG olbldlg

   * Modified ?

   IF hwlabel_mod() .OR. lblname == hwlabel_str_nolabel()
     IF  hwg_Msgyesno(aMsg[44],aMsg[28])   && 44= "Parameter(s) are modified, Save ?" 28 = "Label Editor"
       hwlabel_SAVE_LABEL(cCpLocWin,cCpLocLINUX,cCpLabel)
     ENDIF
   ENDIF


RETURN NIL

* ============================================================
FUNCTION hwlabel_resetdefs()
* Reset all label parameters
* ============================================================

 hwlabel_LBL_DEFAULTS()
 hwlabel_reset_mod()
RETURN NIL

* ==============================================
FUNCTION hwlabel_LOAD_LABEL(clblfile,cCpLocWin,cCpLocLINUX,cCpLabel)
* Dialog load label
* Returns name of labelfile,
* if cancel or error,
* otherwise old name returned
* clblfile : Name of previous label file name
*
* ==============================================
LOCAL cfilename , mypath , lsucc

* Old parameters modified ?
* Then they must be saved before (or dismiss)
IF hwlabel_mod()
  IF .NOT. hwg_Msgyesno(aMsg[55],aMsg[56])
   * Cancel
   RETURN ""
  ENDIF
ENDIF

* Preset with current directory
mypath := hwg_CurDir()

#ifdef __GTK__
*                                                   v "Label files( *.lbl )"
*                                                   v                v All files
 cfilename := hwg_SelectFileEx(,,{{ aMsg[31] ,"*.lbl" },{ aMsg[30] ,"*"}} )

#else
*                                           v "Label files( *.lbl )"
cfilename := hwg_Selectfile( aMsg[31] ,"*.lbl", mypath )
#endif
* Check for cancel
 IF EMPTY(cfilename)
  * Cancel
  cfilename := clblfile
  RETURN hwlabel_LBL_DEFAULTS()
 ENDIF
* Read label file and return array with label contents
 lsucc := hwlabel__LBL_READ(cfilename,cCpLocWin,cCpLocLINUX,cCpLabel)
* In case of error : set the label array with default values

IF .NOT. lsucc
 hwg_MsgStop( aMsg[37] , aMsg[1] )       && Error loading lbl file
 cfilename := clblfile
 hwlabel_LBL_DEFAULTS()
 RETURN hwlabel_str_nolabel()
ENDIF


hwlabel_reset_mod()

* Set new filename in STATIC for display
lblname := cfilename

RETURN cfilename


* ==============================================
FUNCTION hwlabel_SAVE_LABEL(clblfile,cCpLocWin,cCpLocLINUX,cCpLabel)
* Dialog save label
* Return the name of the label file written
* ==============================================
LOCAL cnewfn

IF lblname == hwlabel_str_nolabel()  && "<NO LABEL>"
 * Ask for new label file name
  cnewfn := hwlabel_selfilenew(aMsg[47],aMsg[48],aMsg[49],aMsg[50],aMsg[51])
 * 47  = cloctext  := "Label files ( *.lbl )"
 * 48  = clocmsk   := "*.lbl"
 * 49  = clocallf  := "All files" (GTK)
 * 50  = cTextadd1 := "Enter name of new label file"  (Windows)
 * 51  = cTextadd2 := "Save Label File" (Windows)
  IF EMPTY(cnewfn)   && Cancelled
   RETURN hwlabel_str_nolabel()
  ENDIF
   * Set new filename
   lblname := cnewfn
     * Add extension, if not exist
#ifdef __PLATFORM__WINDOWS
   lblname := hwlabel_addextens(lblname,"lbl")
#else
   lblname := hwlabel_addextens(lblname,"lbl",.T.)
#endif
ELSE
    IF .NOT. hwlabel_mod()
       hwg_MsgInfo(aMsg[46],aMsg[28])  &&  28  = "Label Editor", 46 = "Nothing to save"
       RETURN hwlabel_str_nolabel()
    ENDIF
ENDIF


 IF hwlabel_LBL_WRITE(lblname,aMsg,cCpLocWin,cCpLocLINUX,cCpLabel)
  * Reset modified
   hwlabel_reset_mod()
 ENDIF


RETURN lblname

* ==============================================
FUNCTION hwlabel_selfilenew(cloctext,clocmsk,clocallf,cTextadd1,cTextadd2)
* Interface funktion for selecting a new file
* independant of GTK or not
*
* Sample for passing parameters:
* cloctext  := "XBase source code( *.prg )"
* clocmsk   := "*.prg"
* clocallf  := "All files" (GTK)
* cTextadd1 := "Enter name of new file"  (Windows)
* cTextadd2 := "Save File" (Windows)
* ==============================================
LOCAL fname , cstartvz
* Get current directory as start directory
cstartvz := Curdir()

IF cloctext == NIL
  cloctext  := "Text files( *.txt )"
ENDIF
IF clocmsk == NIL
  clocmsk   := "*.txt"
ENDIF
IF clocallf == NIL
  clocallf  := "All files" && (GTK)
ENDIF
IF cTextadd1 == NIL
  cTextadd1 := "Enter name of new file" &&  (Windows)
ENDIF
IF cTextadd2 == NIL
  cTextadd2 := "Save File" && (Windows)
ENDIF

#ifdef __GTK__
 fname := hwg_SelectFileEx(,,{{ cloctext,clocmsk },{ clocallf ,"*"}} )
#else
  fname := hwg_SaveFile( cTextadd1,cloctext,clocmsk,cstartvz,cTextadd2 )
#endif
* Check for cancel
 IF EMPTY(fname)
 * Cancel
  RETURN ""
 ENDIF
 RETURN  fname

* ==============================================
FUNCTION hwlabel_addextens(cfilename,cext,lcs)
* Add file extension "cext",
* if not passed with "cfilename"
* If cext NIL, original name is returned
* Pass "cext" without previous ".".
* It is recommended, to pass cext in lower case.
* lcs : Set to .T., if case sensitive.
*       This is recommended for LINUX/UNIX.
*       On Windows set to .F. (Default).
* For example:
* #ifdef __PLATFORM__WINDOWS
*   lblname := hwlabel_addextens(lblname,"lbl")
* #else
*   lblname := hwlabel_addextens(lblname,"lbl",.T.)
* #endif
* ==============================================
LOCAL nposi , fna , ce
IF cfilename == NIL
 cfilename := ""
ENDIF
IF cext == NIL
 RETURN cfilename
ENDIF
IF EMPTY(cext)
 RETURN cfilename
ENDIF
IF lcs == NIL
  lcs := .F.
ENDIF
 fna := cfilename
IF lcs
 cfilename := UPPER(cfilename)
 ce := "." + UPPER(cext)
ELSE
  ce := "." + cext
ENDIF
nposi := RAT(ce,cfilename)
IF nposi == 0
 fna := fna + "." + cext
ENDIF
RETURN fna


* ==============================================
FUNCTION hwlabel_reset_mod()
* Reset modified
* (Copy new values to old values)
* ==============================================

c_REM_old := c_REM
n_NUMZ_old := n_NUMZ
n_BR_old := n_BR
n_LM_old := n_LM
n_HZR_old := n_HZR
n_VZR_old := n_VZR
n_LPZ_old := n_LPZ
* Contents
c_INH1_old := c_INH1
c_INH2_old := c_INH2
c_INH3_old := c_INH3
c_INH4_old := c_INH4
c_INH5_old := c_INH5
c_INH6_old := c_INH6
c_INH7_old := c_INH7
c_INH8_old := c_INH8
c_INH9_old := c_INH9
c_INH10_old := c_INH10
c_INH11_old := c_INH11
c_INH12_old := c_INH12
c_INH13_old := c_INH13
c_INH14_old := c_INH14
c_INH15_old := c_INH15
c_INH16_old := c_INH16


RETURN NIL

* ==============================================
FUNCTION hwlabel_mod()
* Interface function for modified label.
* Access to static variables.
* Return values see
* FUNCTION hwlabel_modx()
* ==============================================
LOCAL lmod

lmod := .F.


 IF c_REM   != c_REM_old
   lmod := .T.
 ENDIF
 IF n_NUMZ  != n_NUMZ_old
   lmod := .T.
 ENDIF
 IF n_BR    != n_BR_old
   lmod := .T.
 ENDIF
 IF n_LM    != n_LM_old
   lmod := .T.
 ENDIF
 IF n_HZR   != n_HZR_old
   lmod := .T.
 ENDIF
 IF n_VZR   != n_VZR_old
   lmod := .T.
 ENDIF
 IF n_LPZ   != n_LPZ_old
   lmod := .T.
 ENDIF




 IF c_INH1  != c_INH1_old
   lmod := .T.
 ENDIF
 IF c_INH2  != c_INH2_old
   lmod := .T.
 ENDIF
 IF c_INH3  != c_INH3_old
   lmod := .T.
 ENDIF
 IF c_INH4  != c_INH4_old
   lmod := .T.
 ENDIF
 IF c_INH5  != c_INH5_old
   lmod := .T.
 ENDIF
 IF c_INH6  != c_INH6_old
   lmod := .T.
 ENDIF
 IF c_INH7  != c_INH7_old
   lmod := .T.
 ENDIF
 IF c_INH8  != c_INH8_old
   lmod := .T.
 ENDIF
 IF c_INH9  != c_INH9_old
   lmod := .T.
 ENDIF
 IF c_INH10 != c_INH10_old
   lmod := .T.
 ENDIF
 IF c_INH11 != c_INH11_old
   lmod := .T.
 ENDIF
 IF c_INH12 != c_INH12_old
   lmod := .T.
 ENDIF
 IF c_INH13 != c_INH13_old
   lmod := .T.
 ENDIF
 IF c_INH14 != c_INH14_old
   lmod := .T.
 ENDIF
 IF c_INH15 != c_INH15_old
   lmod := .T.
 ENDIF
 IF c_INH16 != c_INH16_old
   lmod := .T.
 ENDIF

RETURN lmod




* ==============================================
FUNCTION hwlabel__LBL_READ(clblfname,cCpLocWin,cCpLocLINUX,cCpLabel)
* Read the label file and copy the contents into
* static variables
* Label lesen und Inhalte auf Label Array verteilen
* Returns .T., if success,
* Returns .F. in case of error
* or cancel.
*
* Parameters for codepages:
* See description of function hwlabel_translcp()
* ==============================================
LOCAL handle
*     Index variable
*     !  Buffer (1034 bytes)
*     !  !        Number of bytes
*     !  !        !
*     v  v        v
LOCAL I, Puffer , anzbytes
* Puffer : the file buffer for label file
* anzbytes : byte counter

LOCAL Z1, Z2
* this array stores the contents of a label, 16 elements
LOCAL MINH,INH


* A label have a fixed size of 1034
* so fill buffer with spaces before reading

Puffer := SPACE(1034)

* Open label file

handle := FOPEN(clblfname,2)
IF handle == -1
 hwg_MsgStop(aMsg[37],aMsg[3])  && 37 = Error reading label file, 3 = File access error
 FCLOSE(handle)
  RETURN .F.
ENDIF

anzbytes := FREAD(handle,@Puffer,1034)  && Read complete label file
// hwg_MsgInfo("Bytes read: " + STR(anzbytes),"Debug")
IF anzbytes != 1034
* "Error reading label file, not 1034 bytes","File error"
 hwg_MsgStop(aMsg[24],aMsg[3])  && 24 = Error reading label file, not 1034 bytes,  3 = File access error
 FCLOSE(handle)
 RETURN .F.
ENDIF

* Create empty array for label contents
MINH := {}
FOR I := 1 TO 16
 AADD(MINH,SPACE(60))
NEXT

Z1 := SUBSTR(Puffer,1,1)           && Markierung CHR(2) / Mark CHR(2)
c_REM := SUBSTR(Puffer,2,60)         && Bemerkung  L=60  / Remarks length=60
n_NUMZ := ASC(SUBSTR(Puffer,62,2))   && Zeilenanzahl (height of label, number of lines) 1..16
n_BR := ASC(SUBSTR(Puffer,64,2))     && Spaltenbreite (width of label) 1..120
n_LM := ASC(SUBSTR(Puffer,66,2))     && Linker Rand (left margin)      0..250
n_HZR := ASC(SUBSTR(Puffer,68,2))    && Horiz. Abst. (lines between labels)  0..16
n_VZR := ASC(SUBSTR(Puffer,70,2))    && Vert. Abstand (spaces between labels ) 0 ... 120
n_LPZ := ASC(SUBSTR(Puffer,72,2))    && Anzahl Label/Zeile  (number of labels across) 1 .. 5
INH := SUBSTR(Puffer,74,960)       && Labelinhalte / Contents of label (16 * 60 = 960)   >  NUMZ * 60
Z2 := SUBSTR(Puffer,1034,1)        && Endemarkierung CHR(2) / Mark of end CHR(2)


* Extract the contents
* Inhalte aufteilen

* First fill empty
c_INH1 := SPACE(60)
c_INH2 := SPACE(60)
c_INH3 := SPACE(60)
c_INH4 := SPACE(60)
c_INH5 := SPACE(60)
c_INH6 := SPACE(60)
c_INH7 := SPACE(60)
c_INH8 := SPACE(60)
c_INH9 := SPACE(60)
c_INH10 := SPACE(60)
c_INH11 := SPACE(60)
c_INH12 := SPACE(60)
c_INH13 := SPACE(60)
c_INH14 := SPACE(60)
c_INH15 := SPACE(60)
c_INH16 := SPACE(60)

IF n_NUMZ > 16
 n_NUMZ := 16
ENDIF

FOR I := 1 TO n_NUMZ && 16
  MINH[I] := SUBSTR(INH,IIF(I == 1, ( I - 1 ) * 60,((I - 1) * 60) + 1 ), 60)
NEXT

* Use SUBSTR(), because translated characters from UTF-8 could be longer than 1 byte,
* so the total length of every contents line must be trimmed to exact 60 bytes

c_INH1   := SUBSTR(hwlabel_translcp(MINH[1],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH2   := SUBSTR(hwlabel_translcp(MINH[2],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH3   := SUBSTR(hwlabel_translcp(MINH[3],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH4   := SUBSTR(hwlabel_translcp(MINH[4],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH5   := SUBSTR(hwlabel_translcp(MINH[5],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH6   := SUBSTR(hwlabel_translcp(MINH[6],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH7   := SUBSTR(hwlabel_translcp(MINH[7],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH8   := SUBSTR(hwlabel_translcp(MINH[8],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH9   := SUBSTR(hwlabel_translcp(MINH[9],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH10  := SUBSTR(hwlabel_translcp(MINH[10],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH11  := SUBSTR(hwlabel_translcp(MINH[11],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH12  := SUBSTR(hwlabel_translcp(MINH[12],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH13  := SUBSTR(hwlabel_translcp(MINH[13],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH14  := SUBSTR(hwlabel_translcp(MINH[14],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH15  := SUBSTR(hwlabel_translcp(MINH[15],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)
c_INH16  := SUBSTR(hwlabel_translcp(MINH[16],0,cCpLocWin,cCpLocLINUX,cCpLabel),1,60)

  IF LEN(Puffer) != 1034
   hwg_MsgStop(aMsg[59],aMsg[60])  && 59 = "Error: Buffer size not 1034 bytes", 60 =  "Load label file"
   RETURN .F.
  ENDIF

* Codepage conversion
 c_REM := hwlabel_translcp(c_REM,0,cCpLocWin,cCpLocLINUX,cCpLabel)
 * ... and for label contents, see above

  FCLOSE(handle)

RETURN .T.


* ==============================================
FUNCTION hwlabel_LBL_WRITE(dateiname,aMsg,cCpLocWin,cCpLocLINUX,cCpLabel)
* Write label file
* aMsg : Array with messages, language specific
* The label file name was passed by
* "dateiname".
* Returns:
* .T., if file accessfull written
* .F., if cancelled or file error
* Parameters for codepages:
* See description of function hwlabel_translcp()
* ==============================================

LOCAL Z1,Z2,INH
LOCAL REM, NUMZ, BR, LM , HZR , VZR , LPZ
LOCAL I , MINH , handle
LOCAL Pu  && Output file buffer



* Values to local variables

 Z1   := CHR(2)
 REM  := c_REM
 NUMZ := n_NUMZ
 BR   := n_BR
 LM   := n_LM
 HZR  := n_HZR
 VZR  := n_VZR
 LPZ  := n_LPZ
 Z2   := CHR(2)

 * Codepage conversion for remarks

 REM  := hwlabel_translcp(REM,1,cCpLocWin,cCpLocLINUX,cCpLabel)


 MINH := {}    && Array with 16 elements

 AADD(MINH,c_INH1)
 AADD(MINH,c_INH2)
 AADD(MINH,c_INH3)
 AADD(MINH,c_INH4)
 AADD(MINH,c_INH5)
 AADD(MINH,c_INH6)
 AADD(MINH,c_INH7)
 AADD(MINH,c_INH8)
 AADD(MINH,c_INH9)
 AADD(MINH,c_INH10)
 AADD(MINH,c_INH11)
 AADD(MINH,c_INH12)
 AADD(MINH,c_INH13)
 AADD(MINH,c_INH14)
 AADD(MINH,c_INH15)
 AADD(MINH,c_INH16)

* Copy array with contents into one variable (60 x 16 = 960)
* + Codepage conversion
INH := ""
FOR I := 1 TO 16
 INH := INH + PADR( hwlabel_translcp(MINH[I],1,cCpLocWin,cCpLocLINUX,cCpLabel) ,60)
NEXT



* Assemble the complete file buffer
* 1034 chars

Pu := Z1 + REM + I2BIN(NUMZ) + I2BIN(BR) + I2BIN(LM) + ;
  I2BIN(HZR) + I2BIN(VZR) + I2BIN(LPZ) + ;
  PADR(INH,960) + Z2

IF LEN(Pu) != 1034
  hwg_MsgStop(aMsg[59],aMsg[51])  && 59 = "Error: Buffer size not 1034 bytes", 51 =  "Save Label File")
  RETURN .F.
ENDIF

 IF FILE(dateiname)
   IF .NOT. hwg_Msgyesno(aMsg[43],dateiname)   && "File exists, overwrite ?"
    RETURN .F.
   ENDIF
  ERASE &dateiname
 ENDIF

  handle := FCREATE(dateiname,0)

  IF handle == -1
   * cannot create
   * Error writing label file
   hwg_MsgStop( aMsg[2], aMsg[3] + ": " + dateiname)
   FCLOSE(handle)
   RETURN .F.
  ELSE
   FSEEK(handle,0,0)
  ENDIF

  FWRITE(handle,Pu,1034)

  FCLOSE(handle)

RETURN .T.

* ------------------------------------------
FUNCTION hwlabel_LBL_DEFAULTS()
* Set the default values of the variables
* (e.g. for init or new label)
* Returns a label array with default values
* and empty contents
* ------------------------------------------
* LOCAL Z1,Z2
* LOCAL I



 * Z1 := CHR(2)
 c_REM := SPACE(60)   && Bemerkung (Remarks)  L=60
 n_NUMZ := 5          && Zeilenanzahl (height of label) 1..16
 n_BR := 35           && Spaltenbreite (width of label) 1..120
 n_LM := 0            && Linker Rand (left margin)      0..250
 n_HZR := 1           && Horizontaler Abstand  (lines between labels)  0..16
 n_VZR := 0           && Vertikaler Abstand (spaces between labels ) 0 ... 120
 n_LPZ := 1           && Anzahl Label/Zeile  (number of labels across) 1 ..5
 * Z2 := CHR(2)       && Abschlussbyte ( byte at EOF )

 * Contents: Lines with 16 elements, size 60, empty

c_INH1 := SPACE(60)
c_INH2 := SPACE(60)
c_INH3 := SPACE(60)
c_INH4 := SPACE(60)
c_INH5 := SPACE(60)
c_INH6 := SPACE(60)
c_INH7 := SPACE(60)
c_INH8 := SPACE(60)
c_INH9 := SPACE(60)
c_INH10 := SPACE(60)
c_INH11 := SPACE(60)
c_INH12 := SPACE(60)
c_INH13 := SPACE(60)
c_INH14 := SPACE(60)
c_INH15 := SPACE(60)
c_INH16 := SPACE(60)


RETURN NIL


* ==============================================
FUNCTION hwlabel_newlbl()
* New label, clean edit area
* Before cleaning edit area,
* check for modified contents and
* ask for saving, if modified.
* ==============================================

 IF hwlabel_mod()
  IF .NOT. hwg_Msgyesno(aMsg[57],aMsg[58])
  * Cancel
   RETURN ""
  ENDIF
ENDIF

//alabelmem := hwlabel_LBL_DEFAULTS()
hwlabel_resetdefs()
lblname := hwlabel_str_nolabel()
// hwlabel_reset_mod()

RETURN NIL


* ==============================================
FUNCTION _frm_hwlabel_par()
* Dialog edit label parameters
* and contents
* ==============================================
LOCAL frm_hwlabel_par

LOCAL oLabel1  , oLabel2,  oLabel3  ,  oLabel4 ,  oLabel5
LOCAL oLabel6  , oLabel7,  oLabel8 ,  oLabel9 ,   oLabel10
LOCAL oLabel11 , oLabel12, oLabel13 , oLabel14 , oLabel15
LOCAL oLabel16 , oLabel17, oLabel18 , oLabel19 , oLabel20
LOCAL oLabel21 , oLabel22 , oLabel23 , oLabel24
LOCAL oButton1 , oButton2, oButton3, oButton4
LOCAL oEditbox1, oEditbox2, oEditbox3, oEditbox4, oEditbox5
LOCAL oEditbox6, oEditbox7
LOCAL REM , NUMZ , BR , LM , HZR , VZR , LPZ
LOCAL labbruch
LOCAL ngetlmr, ngetlmr2 , nwithtxtdes, noldheigth


* Save old settings
//  alabel_old := alabelmem

labbruch := .T.  && Allow cancel with ESC key

ngetlmr     := 300               && left margin of GET field (started with 220)
ngetlmr2    := ngetlmr + 105     && Additional info (started with 325 = 220 + 105 )
nwithtxtdes := 250              && width of desciptive text before edit box  20 ==> 15

#ifdef __GTK__
     SET KEY 0,VK_ESCAPE TO hwg_KEYESCCLDLG(frm_hwlabel_par)
#endif

* Copy parameter values into local variables

 REM   := hwg_GET_Helper(c_REM,60)
 NUMZ  := n_NUMZ
 BR    := n_BR
 LM    := n_LM
 HZR   := n_HZR
 VZR   := n_VZR
 LPZ   := n_LPZ

* Remember old label height for warning lost of contents

noldheigth := NUMZ


  INIT DIALOG frm_hwlabel_par TITLE aMsg[39] ;  && "Label parameters"
    AT 439,33 SIZE 946,543 NOEXIT;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 30,24 SAY oLabel1 CAPTION aMsg[40] + " :"  SIZE 208,22   && "Edit parameters for
   @ 30,53 SAY oLabel2 CAPTION lblname  SIZE 530,22 ;         && "filename"
        STYLE WS_BORDER

   @ ngetlmr,84 GET oEditbox1 VAR REM SIZE 587,24 ;
        STYLE WS_BORDER
   @ 30,87 SAY oLabel3 CAPTION aMsg[16] + ":"  SIZE nwithtxtdes,22           && "Remarks"
   @ 30,114 SAY oLabel11 CAPTION "(" + aMsg[41] + ")" SIZE 285,22   && "(Maximal 60 characters)"

   @ ngetlmr2,151 SAY oLabel10 CAPTION "(" + aMsg[42] + ")" SIZE 250,22  && "(Range, default in brackets)"
                                                                              && Width: 316 ==> 250

* Numerical parameters
   @ ngetlmr,195 GET oEditbox2 VAR NUMZ SIZE 85,24 ;
        STYLE WS_BORDER ;
        PICTURE "99" VALID {|| hwlabel_valid_num(NUMZ,1,16) }
   @ ngetlmr2,195 SAY oLabel12 CAPTION "1..16 (5)"  SIZE 80,22
   @ 30,196 SAY oLabel4 CAPTION aMsg[17] + ":" SIZE nwithtxtdes,22    && "Heigth of label:"


   @ ngetlmr,230 GET oEditbox3 VAR BR SIZE 85,24 ;
        STYLE WS_BORDER ;
        PICTURE "999" VALID {|| hwlabel_valid_num(BR,1,120) }

   @ 30,231 SAY oLabel5 CAPTION aMsg[18] + ":"  SIZE 121,22   && "Width of label:"
   @ ngetlmr2,231 SAY oLabel13 CAPTION "1..120 (35)"  SIZE 87,22


   @ ngetlmr,265 GET oEditbox4 VAR LM SIZE 85,24 ;
        STYLE WS_BORDER ;
        PICTURE "999" VALID {|| hwlabel_valid_num(LM,0,250) }
   @ 30,266 SAY oLabel6 CAPTION aMsg[19] + ":"  SIZE 120,22    && "Left margin:" more X size for french (old 94)
   @ ngetlmr2,266 SAY oLabel14 CAPTION "0..250 (0)"  SIZE 80,22


   @ ngetlmr,300 GET oEditbox5 VAR HZR SIZE 85,24 ;
        STYLE WS_BORDER ;
        PICTURE "99" VALID {|| hwlabel_valid_num(HZR,0,16) }
   @ 30,301 SAY oLabel7 CAPTION aMsg[20] + ":" SIZE 163,22   && "Lines between labels:"
   @ ngetlmr2,301 SAY oLabel15 CAPTION "0..16 (1)"  SIZE 80,22


   @ ngetlmr,335 GET oEditbox6 VAR VZR SIZE 85,24 ;
        STYLE WS_BORDER ;
        PICTURE "999" VALID {|| hwlabel_valid_num(VZR,0,120) }
   @ 30,336 SAY oLabel8 CAPTION aMsg[21] + ":" SIZE 169,22   && "Spaces between labels:"
   @ ngetlmr2,336 SAY oLabel16 CAPTION "0 ... 120 (0)"  SIZE 91,22


   @ ngetlmr,370 GET oEditbox7 VAR LPZ SIZE 85,24 ;
        STYLE WS_BORDER ;
        PICTURE "9" VALID {|| hwlabel_valid_num(LPZ,1,5) }
   @ 30,371 SAY oLabel9 CAPTION aMsg[22] + ":"  SIZE 200,22  && "Number of label across:" more X size for french (old 166)
   @ ngetlmr2,371 SAY oLabel17 CAPTION "1 .. 5 (1)"  SIZE 89,22

IF clangset <> "English"
* Additional english desription of parameters
  @ 665,151 SAY oLabel18 CAPTION "English:"  SIZE 80,22
  @ 600,196 SAY oLabel19 CAPTION "Heigth of label"  SIZE 166,22
  @ 600,231 SAY oLabel20 CAPTION "Width of label"  SIZE 166,22
  @ 600,266 SAY oLabel21 CAPTION "Left margin"  SIZE 166,22
  @ 600,301 SAY oLabel22 CAPTION "Lines between labels"  SIZE 166,22
  @ 600,336 SAY oLabel23 CAPTION "Spaces between labels"  SIZE 166,22
  @ 600,371 SAY oLabel24 CAPTION "Number of label across"  SIZE 166,22
ENDIF

* Buttons

* If new heigt lower than the warning query appeared:
* No  : Set height to prevous value and stay in parameter edit dialog
* Yes : Accept new value and leave edit dialog
   @ 34,415 BUTTON oButton1 CAPTION aMsg[34]   SIZE 80,32 ;     && OK ("Continue")
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK { | | ;
         IIF(NUMZ < noldheigth , IIF(hwlabel_warncont(), ;
           (  labbruch := .F. , frm_hwlabel_par:Close() ) ,  ;
           (  NUMZ := noldheigth  , oEditbox2:Value(NUMZ) )  ) ;
        ,  ( labbruch := .F. , frm_hwlabel_par:Close() ) ) }

   @ 165,415 BUTTON oButton2 CAPTION aMsg[35]   SIZE 80,32 ;    && "Cancel"
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK { | | frm_hwlabel_par:Close() }

   @ 336,415 BUTTON oButton4 CAPTION aMsg[54]    SIZE 250,32 ;  && "Set default values" more X size for french (old 200
        STYLE WS_TABSTOP+BS_FLAT  ;
        ON CLICK { | | ;
         REM   := Space(60) , ;
         oEditbox1:Value(REM) , ;
         NUMZ  := 5 , ;
         oEditbox2:Value(NUMZ) , ;
         BR    := 35 , ;
         oEditbox3:Value(BR) , ;
         LM    := 0 , ;
         oEditbox4:Value(LM) , ;
         HZR   := 1 , ;
         oEditbox5:Value(HZR) , ;
         VZR   := 0 , ;
         oEditbox6:Value(VZR) , ;
         LPZ   := 1 , ;
         oEditbox7:Value(LPZ)   ;
        }

   @ 668,415 BUTTON oButton3 CAPTION aMsg[15]   SIZE 80,32 ;    && "Help"
        STYLE WS_TABSTOP+BS_FLAT  ;
        ON CLICK { | | hwlabel_Mainhlp(clangset,1) }


   ACTIVATE DIALOG frm_hwlabel_par

#ifdef __GTK__
 SET KEY 0,VK_ESCAPE TO
#endif


 IF labbruch
   * Check for modifications
   // alabel_old
   // ==> Executed at close of edit dialog
   RETURN .F.
 ENDIF


* Store parameters back to STATIC vars

 c_REM := PADR(REM,60)
 n_NUMZ := NUMZ
 n_BR := BR
 n_LM := LM
 n_HZR := HZR
 n_VZR := VZR
 n_LPZ := LPZ

* Clean unused contents
  hwlabel_ccontents(NUMZ)

//  hwg_MsgInfo("Parameter stored","Debug")



RETURN frm_hwlabel_par:lresult


* ==============================================
FUNCTION hwlabel_ccontents(nnumz)
* Clean unused contents
* nnumz : The recent height of label,
*         all lines above this position
*         are cleared with 60 spaces.
* ==============================================
LOCAL iconut
IF nnumz == NIL
 RETURN NIL
ENDIF

IF nnumz > 15
 * Nothing to do
 RETURN NIL
ENDIF
IF nnumz > 14
 c_INH16 := SPACE(60)
  RETURN NIL
ENDIF
IF nnumz > 13
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 12
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 11
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 10
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 c_INH12 := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 9
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 c_INH12 := SPACE(60)
 c_INH11 := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 8
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 c_INH12 := SPACE(60)
 c_INH11 := SPACE(60)
 c_INH10 := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 7
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 c_INH12 := SPACE(60)
 c_INH11 := SPACE(60)
 c_INH10 := SPACE(60)
 c_INH9  := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 6
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 c_INH12 := SPACE(60)
 c_INH11 := SPACE(60)
 c_INH10 := SPACE(60)
 c_INH9  := SPACE(60)
 c_INH8  := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 5
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 c_INH12 := SPACE(60)
 c_INH11 := SPACE(60)
 c_INH10 := SPACE(60)
 c_INH9  := SPACE(60)
 c_INH8  := SPACE(60)
 c_INH7  := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 4
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 c_INH12 := SPACE(60)
 c_INH11 := SPACE(60)
 c_INH10 := SPACE(60)
 c_INH9  := SPACE(60)
 c_INH8  := SPACE(60)
 c_INH7  := SPACE(60)
 c_INH6  := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 3
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 c_INH12 := SPACE(60)
 c_INH11 := SPACE(60)
 c_INH10 := SPACE(60)
 c_INH9  := SPACE(60)
 c_INH8  := SPACE(60)
 c_INH7  := SPACE(60)
 c_INH6  := SPACE(60)
 c_INH5  := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 2
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 c_INH12 := SPACE(60)
 c_INH11 := SPACE(60)
 c_INH10 := SPACE(60)
 c_INH9  := SPACE(60)
 c_INH8  := SPACE(60)
 c_INH7  := SPACE(60)
 c_INH6  := SPACE(60)
 c_INH5  := SPACE(60)
 c_INH4 := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 1
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 c_INH12 := SPACE(60)
 c_INH11 := SPACE(60)
 c_INH10 := SPACE(60)
 c_INH9  := SPACE(60)
 c_INH8  := SPACE(60)
 c_INH7  := SPACE(60)
 c_INH6  := SPACE(60)
 c_INH5  := SPACE(60)
 c_INH4  := SPACE(60)
 c_INH3  := SPACE(60)
 RETURN NIL
ENDIF
IF nnumz > 0
 c_INH16 := SPACE(60)
 c_INH15 := SPACE(60)
 c_INH14 := SPACE(60)
 c_INH13 := SPACE(60)
 c_INH12 := SPACE(60)
 c_INH11 := SPACE(60)
 c_INH10 := SPACE(60)
 c_INH9  := SPACE(60)
 c_INH8  := SPACE(60)
 c_INH7  := SPACE(60)
 c_INH6  := SPACE(60)
 c_INH5  := SPACE(60)
 c_INH4  := SPACE(60)
 c_INH3  := SPACE(60)
 c_INH2  := SPACE(60)
ENDIF

RETURN NIL


* ==============================================
FUNCTION hwlabel_warncont()
* Warnung query message, if height reduced
* ==============================================
RETURN hwg_MsgYesNo(aMsg[53],aMsg[52])  && 52 = Warning



* ==============================================
FUNCTION hwlabel_valid_num(nvalchk,nfromval,ntoval)
* VALID function for checking numeric value ranges.
*
* nvalchk  : value to check
* nfromval : range from
* ntoval   : range to
*
* ==============================================
LOCAL cfr,cto
cfr := ALLTRIM(STR(nfromval)) && for displayed message
cto := ALLTRIM(STR(ntoval))
IF (nvalchk >= nfromval) .AND. (nvalchk <= ntoval)
 RETURN .T.
ENDIF
hwg_MsgStop("Range from " + cfr + " to " + cto)
RETURN .F.


* ==============================================
FUNCTION hwlabel_frm_lbl_contents(nLines, cHelp)
* Dialog edit label contents
* nLines : Number of lines for edit
*          Depends on parameter
* aCnt   : Array with contents of label,
*          NIL for new label
* cHelp  : Help text
* ==============================================
LOCAL frm_lbl_contents

LOCAL oLabel1, oLabel2, oLabel3, oLabel4, oLabel5
LOCAL oLabel6, oLabel7, oLabel8, oLabel9, oLabel10
LOCAL oLabel11, oLabel12, oLabel13, oLabel14, oLabel15
LOCAL oLabel16, oLabel17
LOCAL oEditbox1, oEditbox2, oEditbox3, oEditbox4, oEditbox5
LOCAL oEditbox6, oEditbox7, oEditbox8, oEditbox9, oEditbox10
LOCAL oEditbox11, oEditbox12, oEditbox13, oEditbox14, oEditbox15
LOCAL oEditbox16
LOCAL oButton1, oButton2, oButton3
LOCAL i , iconut, bCancel
LOCAL nlauf2 , lmod

LOCAL cCnt1, cCnt2, cCnt3, cCnt4, cCnt5, cCnt6, cCnt7, cCnt8, ;
     cCnt9, cCnt10, cCnt11, cCnt12, cCnt13, cCnt14, cCnt15, cCnt16


bCancel := .T.
lmod := .F.

IF nLines == NIL
  nLines := 1
ENDIF

   IF nLines > 16
     nLines := 16
   ENDIF

* Copy label contents from static buffer to local varianles

cCnt1 := PADR(c_INH1,60)
cCnt2 := PADR(c_INH2,60)
cCnt3 := PADR(c_INH3,60)
cCnt4 := PADR(c_INH4,60)
cCnt5 := PADR(c_INH5,60)
cCnt6 := PADR(c_INH6,60)
cCnt7 := PADR(c_INH7,60)
cCnt8 := PADR(c_INH8,60)
cCnt9 := PADR(c_INH9,60)
cCnt10 := PADR(c_INH10,60)
cCnt11 := PADR(c_INH11,60)
cCnt12 := PADR(c_INH12,60)
cCnt13 := PADR(c_INH13,60)
cCnt14 := PADR(c_INH14,60)
cCnt15 := PADR(c_INH15,60)
cCnt16 := PADR(c_INH16,60)


* The hwg_GET_Helper() for GTK

cCnt1  :=  hwg_GET_Helper(cCnt1,60)
cCnt2  :=  hwg_GET_Helper(cCnt2,60)
cCnt3  :=  hwg_GET_Helper(cCnt3,60)
cCnt4  :=  hwg_GET_Helper(cCnt4,60)
cCnt5  :=  hwg_GET_Helper(cCnt5,60)
cCnt6  :=  hwg_GET_Helper(cCnt6,60)
cCnt7  :=  hwg_GET_Helper(cCnt7,60)
cCnt8  :=  hwg_GET_Helper(cCnt8,60)
cCnt9  :=  hwg_GET_Helper(cCnt9,60)
cCnt10 :=  hwg_GET_Helper(cCnt10,60)
cCnt11 :=  hwg_GET_Helper(cCnt11,60)
cCnt12 :=  hwg_GET_Helper(cCnt12,60)
cCnt13 :=  hwg_GET_Helper(cCnt13,60)
cCnt14 :=  hwg_GET_Helper(cCnt14,60)
cCnt15 :=  hwg_GET_Helper(cCnt15,60)
cCnt16 :=  hwg_GET_Helper(cCnt16,60)



  INIT DIALOG frm_lbl_contents TITLE "Edit contents of label" ;
    AT 443,0 SIZE 734,783 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 5,19 SAY oLabel1 CAPTION aMsg[33]  SIZE 707,22 ;   && "Contents of label"
        STYLE SS_CENTER

IF nLines > 0
   @ 110,60 GET oEditbox1 VAR cCnt1  SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,61 SAY oLabel2 CAPTION "1:"  SIZE 45,22
ENDIF
IF nLines > 1
   @ 110,95 GET oEditbox2 VAR cCnt2  SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,96 SAY oLabel3 CAPTION "2:"  SIZE 45,22
ENDIF
IF nLines > 2
   @ 110,130 GET oEditbox3 VAR cCnt3  SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,131 SAY oLabel4 CAPTION "3:"  SIZE 45,22
ENDIF
IF nLines > 3
   @ 110,165 GET oEditbox4 VAR cCnt4  SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,166 SAY oLabel5 CAPTION "4:"  SIZE 45,22
ENDIF
IF nLines > 4
   @ 110,200 GET oEditbox5 VAR cCnt5  SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,201 SAY oLabel6 CAPTION "5:"  SIZE 45,22
ENDIF
IF nLines > 5
   @ 110,235 GET oEditbox6 VAR cCnt6  SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,236 SAY oLabel7 CAPTION "6:"  SIZE 45,22
ENDIF
IF nLines > 6
   @ 110,271 GET oEditbox7 VAR cCnt7  SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,271 SAY oLabel8 CAPTION "7:"  SIZE 45,22
ENDIF
IF nLines > 7
   @ 110,305 GET oEditbox8 VAR cCnt8  SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,306 SAY oLabel9 CAPTION "8:"  SIZE 45,22
ENDIF
IF nLines > 8
   @ 110,340 GET oEditbox9 VAR cCnt9  SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,341 SAY oLabel10 CAPTION "9:"  SIZE 45,22
ENDIF
IF nLines > 9
   @ 110,375 GET oEditbox10 VAR cCnt10 SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,376 SAY oLabel11 CAPTION "10:"  SIZE 45,22
ENDIF
IF nLines > 10
   @ 110,410 GET oEditbox11 VAR cCnt11 SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,411 SAY oLabel12 CAPTION "11:"  SIZE 45,22
ENDIF
IF nLines > 11
   @ 110,445 GET oEditbox12 VAR cCnt12 SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,446 SAY oLabel13 CAPTION "12:"  SIZE 45,22
ENDIF
IF nLines > 12
   @ 110,480 GET oEditbox13 VAR cCnt13 SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,481 SAY oLabel14 CAPTION "13:"  SIZE 45,22
ENDIF
IF nLines > 13
   @ 110,515 GET oEditbox14 VAR cCnt14 SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,516 SAY oLabel15 CAPTION "14:"  SIZE 45,22
ENDIF
IF nLines > 14
   @ 110,550 GET oEditbox15 VAR cCnt15 SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,551 SAY oLabel16 CAPTION "15:"  SIZE 45,22
ENDIF
IF nLines > 15
   @ 110,585 GET oEditbox16 VAR cCnt16 SIZE 550,24 ;
        STYLE WS_BORDER
   @ 50,586 SAY oLabel17 CAPTION "16:"  SIZE 45,22
ENDIF

* --- Buttons ---
   @ 528,640 BUTTON oButton3 CAPTION aMsg[15]   SIZE 80,32 ;  && "Help"
        STYLE WS_TABSTOP+BS_FLAT ;
                ON CLICK {|| hwlabel_Mainhlp(clangset,2) }
   @ 112,641 BUTTON oButton1 CAPTION aMsg[34]   SIZE 80,32 ;  && "OK"
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| bCancel := .F. , hwlabel_Check_lnc( cCnt1, cCnt2, cCnt3, cCnt4, cCnt5, cCnt6, cCnt7, cCnt8, ;
     cCnt9, cCnt10, cCnt11, cCnt12, cCnt13, cCnt14, cCnt15, cCnt16 ) ;
        , frm_lbl_contents:Close() }
   @ 245,643 BUTTON oButton2 CAPTION aMsg[35]   SIZE 80,32 ; && "Cancel"
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| frm_lbl_contents:Close() }

   ACTIVATE DIALOG frm_lbl_contents

   * Trim edited fields

   cCnt1 := PADR(cCnt1,60)
   cCnt2 := PADR(cCnt2,60)
   cCnt3 := PADR(cCnt3,60)
   cCnt4 := PADR(cCnt4,60)
   cCnt5 := PADR(cCnt5,60)
   cCnt6 := PADR(cCnt6,60)
   cCnt7 := PADR(cCnt7,60)
   cCnt8 := PADR(cCnt8,60)
   cCnt9 := PADR(cCnt9,60)
   cCnt10 := PADR(cCnt10,60)
   cCnt11 := PADR(cCnt11,60)
   cCnt12 := PADR(cCnt12,60)
   cCnt13 := PADR(cCnt13,60)
   cCnt14 := PADR(cCnt14,60)
   cCnt15 := PADR(cCnt15,60)
   cCnt16 := PADR(cCnt16,60)


   IF .NOT. bCancel
   * Store contents back

  c_INH1  := cCnt1
  c_INH2  := cCnt2
  c_INH3  := cCnt3
  c_INH4  := cCnt4
  c_INH5  := cCnt5
  c_INH6  := cCnt6
  c_INH7  := cCnt7
  c_INH8  := cCnt8
  c_INH9  := cCnt9
  c_INH10 := cCnt10
  c_INH11 := cCnt11
  c_INH12 := cCnt12
  c_INH13 := cCnt13
  c_INH14 := cCnt14
  c_INH15 := cCnt15
  c_INH16 := cCnt16


 ENDIF

RETURN frm_lbl_contents:lresult

* ==============================================
FUNCTION hwlabel_Check_lnc( cCnt1, cCnt2, cCnt3, cCnt4, cCnt5, cCnt6, cCnt7, cCnt8, ;
     cCnt9, cCnt10, cCnt11, cCnt12, cCnt13, cCnt14, cCnt15, cCnt16 )
* Check length of contents line
* ==============================================

IF n_NUMZ < 1
 RETURN NIL
ENDIF

 IF LEN(ALLTRIM(cCnt1)) >  n_BR
   hwlbledit_contlwarn(1,cCnt1)
 ENDIF

IF n_NUMZ > 1
 IF LEN(ALLTRIM(cCnt2)) >  n_BR
   hwlbledit_contlwarn(2,cCnt2)
 ENDIF
ENDIF

IF n_NUMZ > 2
 IF LEN(ALLTRIM(cCnt3)) >  n_BR
   hwlbledit_contlwarn(3,cCnt3)
 ENDIF
ENDIF

IF n_NUMZ > 3
 IF LEN(ALLTRIM(cCnt4)) >  n_BR
   hwlbledit_contlwarn(4,cCnt4)
 ENDIF
ENDIF


IF n_NUMZ > 4
 IF LEN(ALLTRIM(cCnt5)) >  n_BR
   hwlbledit_contlwarn(5,cCnt5)
 ENDIF
ENDIF


IF n_NUMZ > 5
 IF LEN(ALLTRIM(cCnt6)) >  n_BR
   hwlbledit_contlwarn(6,cCnt6)
 ENDIF
ENDIF

IF n_NUMZ > 6
 IF LEN(ALLTRIM(cCnt7)) >  n_BR
   hwlbledit_contlwarn(7,cCnt7)
 ENDIF
ENDIF

IF n_NUMZ > 7
 IF LEN(ALLTRIM(cCnt8)) >  n_BR
   hwlbledit_contlwarn(8,cCnt8)
 ENDIF
ENDIF

IF n_NUMZ > 8
 IF LEN(ALLTRIM(cCnt9)) >  n_BR
   hwlbledit_contlwarn(9,cCnt9)
 ENDIF
ENDIF

IF n_NUMZ > 9
 IF LEN(ALLTRIM(cCnt10)) >  n_BR
   hwlbledit_contlwarn(10,cCnt10)
 ENDIF
ENDIF

IF n_NUMZ > 10
 IF LEN(ALLTRIM(cCnt11)) >  n_BR
   hwlbledit_contlwarn(11,cCnt11)
 ENDIF
ENDIF


IF n_NUMZ > 11
 IF LEN(ALLTRIM(cCnt12)) >  n_BR
   hwlbledit_contlwarn(12,cCnt12)
 ENDIF
ENDIF

IF n_NUMZ > 12
 IF LEN(ALLTRIM(cCnt13)) >  n_BR
   hwlbledit_contlwarn(13,cCnt13)
 ENDIF
ENDIF

IF n_NUMZ > 13
 IF LEN(ALLTRIM(cCnt14)) >  n_BR
   hwlbledit_contlwarn(14,cCnt14)
 ENDIF
ENDIF

IF n_NUMZ > 14
 IF LEN(ALLTRIM(cCnt15)) >  n_BR
   hwlbledit_contlwarn(15,cCnt15)
  ENDIF
ENDIF

IF n_NUMZ > 15
 IF LEN(ALLTRIM(cCnt16)) >  n_BR
   hwlbledit_contlwarn(16,cCnt16)
 ENDIF
ENDIF

RETURN NIL


* ==============================================
FUNCTION hwlbledit_contlwarn(nzeile,czeile)
* Displays warning of contents length greater
* than width of label
* ==============================================
    hwg_MsgInfo(aMsg[63] + ALLTRIM(STR(nzeile)) + CHR(10) + aMsg[64] + CHR(10) + ;
    aMsg[65] + ALLTRIM(STR(LEN(ALLTRIM(czeile)))) ;
    ,aMsg[1])
RETURN NIL

* ==============================================
FUNCTION hwlbledit_exit()
* Exit dialog check for modified label and query
* ==============================================
IF hwlabel_mod()
RETURN hwg_MsgYesNo(aMsg[45],aMsg[28])  && 28 = Label Editor , 45 = Label is modified, ignore modifications ?
ENDIF
RETURN .T.

* ==============================================
FUNCTION hwlabel_translcp(cInput,nmode,cCpLocWin,cCpLocLINUX,cCpLabel)
* Translates codepages for label file
*
* Parameters:
* Default values in ()
*
* cInput      : The Input String to translate ("")
* nmode       : Direction of translation (0):
*               0 = Label to local (Windows,LINUX)
*               1 = Local (Windows,LINUX) to label
* cCpLocWin   : Name of local codepage for display and printing
*               on Windows OS ("DEWIN")
* cCpLocLINUX : Name of local codepage for display and printing
*               on LINUX OS ("UTF8EX")
* cCpLabel    : Name of codepage for label file
*               ("DE858")
*
* The used operating system is automatically
* detected by compiler switch.
* ==============================================
LOCAL cOutput, cloccp

cOutput := ""

IF nmode == NIL
  nmode := 0
ENDIF

IF cInput == NIL
 cInput := ""
ENDIF

IF cCpLocWin == NIL
   cCpLocWin := "DEWIN"
ENDIF
IF cCpLocLINUX == NIL
   cCpLocLINUX := "UTF8EX"
ENDIF
IF cCpLabel == NIL
   cCpLabel := "DE858"
ENDIF

#ifdef __PLATFORM__WINDOWS
 cloccp := cCpLocWin
#else
 cloccp := cCpLocLINUX
#endif

IF nmode == 0
  cOutput := hb_Translate( cInput, cCpLabel , cloccp   )
ELSE
  cOutput := hb_Translate( cInput, cloccp   , cCpLabel )
ENDIF



RETURN cOutput

* ==============================================
FUNCTION hwlabel_countcont()
* Count the filled contents of a label.
* aforcount : Can be an array with full contents
*             or only an array of 16 elements with
*             label contents.
* ==============================================


IF EMPTY(c_INH1)
 RETURN 0
ENDIF
IF EMPTY(c_INH2)
 RETURN 1
ENDIF
IF EMPTY(c_INH3)
 RETURN 2
ENDIF
IF EMPTY(c_INH4)
 RETURN 3
ENDIF
IF EMPTY(c_INH5)
 RETURN 4
ENDIF
IF EMPTY(c_INH6)
 RETURN 5
ENDIF
IF EMPTY(c_INH7)
 RETURN 6
ENDIF
IF EMPTY(c_INH8)
 RETURN 7
ENDIF
IF EMPTY(c_INH9)
 RETURN 8
ENDIF
IF EMPTY(c_INH10)
 RETURN 9
ENDIF
IF EMPTY(c_INH11)
 RETURN 10
ENDIF
IF EMPTY(c_INH12)
 RETURN 11
ENDIF
IF EMPTY(c_INH13)
 RETURN 12
ENDIF
IF EMPTY(c_INH14)
 RETURN 13
ENDIF
IF EMPTY(c_INH15)
 RETURN 14
ENDIF
IF EMPTY(c_INH16)
 RETURN 15
ENDIF

RETURN 16

* === Functions for hmisc.prg ===




* ------------------------------------------------
* ---- Messages ( National language support ) ----
* ----- Internationalization ---------------------
* ------------------------------------------------



* ==============================================
FUNCTION hwlabel_DOS_INIT_DE()
* Initialisation sequence for DOS / CP437 and CP858
* Also for english
* Returns the Values in an array.
* Umlaute and Euro Currency sign
* ==============================================


* The output array is filled with this sheme:
* aUmlaute[1] : CAGUML && AE Upper
* aUmlaute[2] : COGUML && OE
* aUmlaute[3] : CUGUML && UE
* aUmlaute[4] : CAKUML && AE Lower
* aUmlaute[5] : COKUML && OE
* aUmlaute[6] : CUKUML && UE
* aUmlaute[7] : CSZUML && SZ Sharp "S"
* aUmlaute[8] : Euro   && Euro currency sign
*
* ==============================================
LOCAL aUmlaute := {}

CAGUML := CHR(142)  && AE
COGUML := CHR(153)  && OE
CUGUML := CHR(154)  && UE
CAKUML := CHR(132)  && AE
COKUML := CHR(148)  && OE
CUKUML := CHR(129)  && UE
CSZUML := CHR(225)  && SZ
EURO   := CHR(213)  && CP858 : xD5 or 213

* Create array with special signs
/* 1 */ AADD(aUmlaute, CAGUML )  && AE Upper
/* 2 */ AADD(aUmlaute, COGUML )  && OE
/* 3 */ AADD(aUmlaute, CUGUML )  && UE
/* 4 */ AADD(aUmlaute, CAKUML )  && AE Lower
/* 5 */ AADD(aUmlaute, COKUML )  && OE
/* 6 */ AADD(aUmlaute, CUKUML )  && UE
/* 7 */ AADD(aUmlaute, CSZUML )  && SZ  Sharp "S"
/* 8 */ AADD(aUmlaute, EURO   )  && Euro currency sign


RETURN aUmlaute

* ==============================================
FUNCTION hwlabel_GUI_INIT_DE()
* Initialisation sequence for GUI (messages)
* Umlaute and Euro Currency sign
* ==============================================
LOCAL aUmlaute := {}
#ifdef __LINUX__
* Linux / UTF8
CAGUML := "Ä"  && AE
COGUML := "Ö"  && OE
CUGUML := "Ü"  && UE
CAKUML := "ä"  && AE
COKUML := "ö"  && OE
CUKUML := "ü"  && UE
CSZUML := "ß"  && SZ
EURO   := "€"
#else
* Windows (WIN1252)
CAGUML := CHR(196)  && AE
COGUML := CHR(214)  && OE
CUGUML := CHR(220)  && UE
CAKUML := CHR(228)  && AE
COKUML := CHR(246)  && OE
CUKUML := CHR(252)  && UE
CSZUML := CHR(223)  && SZ
EURO   := CHR(128)
#endif

AADD(aUmlaute, CAGUML )  && AE
AADD(aUmlaute, COGUML )  && OE
AADD(aUmlaute, CUGUML )  && UE
AADD(aUmlaute, CAKUML )  && AE
AADD(aUmlaute, COKUML )  && OE
AADD(aUmlaute, CUKUML )  && UE
AADD(aUmlaute, CSZUML )  && SZ
AADD(aUmlaute, EURO )


RETURN aUmlaute

* ------------------------------------------
FUNCTION hwlabel_MSGS_EN()
* Set message array for english language
* Total number of messages: 33, reserved: 0
* ------------------------------------------
* Don't forget, that strings containing "&" are part of a menu system.
LOCAL aMsg
aMsg := {}

/*  1  */ AADD(aMsg,"HWLABEL Label Editor")     && Title of main window
/*  2  */ AADD(aMsg,"Error writing label file")
/*  3  */ AADD(aMsg,"File access error")
* Main Menu
/*  4  */ AADD(aMsg,"&File")
/*  5  */ AADD(aMsg,"&Quit")
/*  6  */ AADD(aMsg,"&Load")
/*  7  */ AADD(aMsg,"&Save")
/*  8  */ AADD(aMsg,"&Edit")
/*  9  */ AADD(aMsg,"&Parameters")
/* 10  */ AADD(aMsg,"&Contents")
/* 11  */ AADD(aMsg,"&Help")
/* 12  */ AADD(aMsg,"&About")
/* 13  */ AADD(aMsg,"&Language")
/* 14  */ AADD(aMsg,"&Configuration")
/* 15  */ AADD(aMsg,"Help")
* Label Parameters  / Range as comment
/* 16  */ AADD(aMsg,"Remarks")                  && L=60
/* 17  */ AADD(aMsg,"Height of label")          && 1..16
/* 18  */ AADD(aMsg,"Width of label")           && 1..120
/* 19  */ AADD(aMsg,"Left margin")              && 0..250
/* 20  */ AADD(aMsg,"Lines between labels")     && 0..16
/* 21  */ AADD(aMsg,"Spaces between labels")    && 0 ... 120
/* 22  */ AADD(aMsg,"Number of labels across")  && 1 .. 5
* Other messages
/* 23  */ AADD(aMsg,"Close")
/* 24  */ AADD(aMsg,"Error reading label file, not 1034 bytes")
/* 25  */ AADD(aMsg,"Label files")
/* 26  */ AADD(aMsg,"<NO LABEL>")
/* 27  */ AADD(aMsg,"After changing language restart of program is required")
/* 28  */ AADD(aMsg,"Label Editor")
/* 29  */ AADD(aMsg,"&Label")
/* 30  */ AADD(aMsg,"All Files")
/* 31  */ AADD(aMsg,"Label files")
/* 32  */ AADD(aMsg,"&New")
/* 33  */ AADD(aMsg,"Contents of label")
/* 34  */ AADD(aMsg,"OK")
/* 35  */ AADD(aMsg,"Cancel")
/* 36  */ AADD(aMsg,"Continue")
/* 37  */ AADD(aMsg,"Error reading label file")
/* 38  */ AADD(aMsg,"Open error label file")
/* 39  */ AADD(aMsg,"Label parameters")
/* 40  */ AADD(aMsg,"Edit parameters for")
/* 41  */ AADD(aMsg,"Maximal 60 characters" )
/* 42  */ AADD(aMsg,"Range, default in brackets" )
/* 43  */ AADD(aMsg,"File exists, overwrite ?")
/* 44  */ AADD(aMsg,"Parameter(s) are modified, Save ?")
/* 45  */ AADD(aMsg,"Label is modified, ignore modifications ?")
/* 46  */ AADD(aMsg,"Nothing to save")
/* 47  */ AADD(aMsg,"Label files ( *.lbl )")         && cloctext
/* 48  */ AADD(aMsg,"*.lbl")                          && clocmsk
/* 49  */ AADD(aMsg,"All files")                      && clocallf (GTK)
/* 50  */ AADD(aMsg,"Enter name of new label file")  && cTextadd1 (Windows)
/* 51  */ AADD(aMsg,"Save Label File")                && cTextadd2 (Windows)
/* 52  */ AADD(aMsg,"Warning")
/* 53  */ AADD(aMsg,"If height is reduced, the corresponding contents is lost" + CHR(10) + "No = Cancel")
/* 54  */ AADD(aMsg,"Set default values")
/* 55  */ AADD(aMsg,"Recent label not saved, yes=dismiss and load, no=cancel")
/* 56  */ AADD(aMsg,"Load label file")
/* 57  */ AADD(aMsg,"Recent label not saved, yes=dismiss, no=cancel")
/* 58  */ AADD(aMsg,"New Label")
/* 59  */ AADD(aMsg,"Error: Buffer size not 1034 bytes")
/* 60  */ AADD(aMsg,"Load label file")
/* 61  */ AADD(aMsg,"HWLABEL Help")
/* 62  */ AADD(aMsg,"No help available")
/* 63  */ AADD(aMsg,"Warning !" + CHR(10) + "Length of line  ")
/* 64  */ AADD(aMsg," could exceed the width of label.")
/* 65  */ AADD(aMsg,"Recent length is : ")


RETURN aMsg


* ------------------------------------------
FUNCTION hwlabel_MSGS_FR()
* Set message array for french language
* Total number of messages: 33, reserved: 0
* ------------------------------------------
* Don't forget, that strings containing "&" are part of a menu system.
LOCAL aMsg
aMsg := {}

/*  1  */ AADD(aMsg,"HWLABEL Editeur de label")     && Title of main window
/*  2  */ AADD(aMsg,XWIN_FR("Erreur d'écriture"))
/*  3  */ AADD(aMsg,XWIN_FR("Erreur d'accès fichier"))
* Main Menu
/*  4  */ AADD(aMsg,"&Fichier")
/*  5  */ AADD(aMsg,"&Quitter")
/*  6  */ AADD(aMsg,"&Ouvrir")
/*  7  */ AADD(aMsg,"&Enregistrer")
/*  8  */ AADD(aMsg,"&Edition")
/*  9  */ AADD(aMsg,XWIN_FR("&Paramètres"))
/* 10  */ AADD(aMsg,"&Contenus")
/* 11  */ AADD(aMsg,"&Aide")
/* 12  */ AADD(aMsg,"&A propos")
/* 13  */ AADD(aMsg,"&Langue")
/* 14  */ AADD(aMsg,"&Configuration")
/* 15  */ AADD(aMsg,"Aide")
* Label Parameters  / Range as comment
/* 16  */ AADD(aMsg,"Remarques")                   && L=60
/* 17  */ AADD(aMsg,"Hauteur du label")            && 1..16
/* 18  */ AADD(aMsg,"Largeur du label")            && 1..120
/* 19  */ AADD(aMsg,"Marge gauche")                && 0..250
/* 20  */ AADD(aMsg,"Lignes entre labels")         && 0..16
/* 21  */ AADD(aMsg,"Espaces entre labels")        && 0 ... 120
/* 22  */ AADD(aMsg,XWIN_FR("Nombre de labels parallèles")) && 1 .. 5
* Other messages
/* 23  */ AADD(aMsg,"Fermer")
/* 24  */ AADD(aMsg,"Erreur de lecture du label, != 1034 octets")
/* 25  */ AADD(aMsg,"Fichiers label")
/* 26  */ AADD(aMsg,"<AUCUN LABEL>")
/* 27  */ AADD(aMsg,XWIN_FR("Après le changement de langue, relancer le programme"))
/* 28  */ AADD(aMsg,"Editeur de Label")
/* 29  */ AADD(aMsg,"&Label")
/* 30  */ AADD(aMsg,"Tous les fichiers")
/* 31  */ AADD(aMsg,"Fichiers Label")
/* 32  */ AADD(aMsg,"&Nouveau")
/* 33  */ AADD(aMsg,"Contenus du label")
/* 34  */ AADD(aMsg,"OK")
/* 35  */ AADD(aMsg,"Annuler")
/* 36  */ AADD(aMsg,"Continuer")
/* 37  */ AADD(aMsg,"Erreur de lecture du fichier label")
/* 38  */ AADD(aMsg,"Erreur d'ouverture du fichier label")
/* 39  */ AADD(aMsg,XWIN_FR("Paramètres du label"))
/* 40  */ AADD(aMsg,XWIN_FR("Editer les paramètres"))
/* 41  */ AADD(aMsg,XWIN_FR("60 caractères maximum" ))
/* 42  */ AADD(aMsg,XWIN_FR("Plage, défaut entre crochets" ))
/* 43  */ AADD(aMsg,XWIN_FR("Fichier existant, l'écraser ?"))
/* 44  */ AADD(aMsg,XWIN_FR("Des paramètre(s) ont été modifiés, Enregistrer ?"))
/* 45  */ AADD(aMsg,XWIN_FR("Le label a été modifié, ignorer les modifications ?"))
/* 46  */ AADD(aMsg,XWIN_FR("Rien à sauver"))
/* 47  */ AADD(aMsg,"Fichiers label (*.lbl)")                  && cloctext
/* 48  */ AADD(aMsg,"*.lbl")                                   && clocmsk
/* 49  */ AADD(aMsg,"Tous les fichiers (*.*)")                 && clocallf (GTK)
/* 50  */ AADD(aMsg,"Donnez le nom du nouveau fichier label")  && cTextadd1 (Windows)
/* 51  */ AADD(aMsg,"Enregistrer le fichier label")            && cTextadd2 (Windows)
/* 52  */ AADD(aMsg,"Attention")
/* 53  */ AADD(aMsg,XWIN_FR("Si la hauteur est réduite, le contenu correspondant est perdu" + CHR(10) + "Non = Annuler"))
/* 54  */ AADD(aMsg,XWIN_FR("Restaurer les valeurs par défaut"))
/* 55  */ AADD(aMsg,"Dernier label non sauvé, Oui=Ignorer et recharger, non=Annuler")
/* 56  */ AADD(aMsg,"Charger le fichier label")
/* 57  */ AADD(aMsg,"Dernier label non sauvé, Oui=défaire, non=annuler")
/* 58  */ AADD(aMsg,"Nouveau Label")
/* 59  */ AADD(aMsg,"Erreur: Taille du buffer non de 1034 bytes")
/* 60  */ AADD(aMsg,"Charger le fichier label")
/* 61  */ AADD(aMsg,"Aide HWLABEL")
/* 62  */ AADD(aMsg,"Aucune aide disponible")
/* 63  */ AADD(aMsg,"Attention !" + CHR(10) + "Longeur de ligne  ")
/* 64  */ AADD(aMsg," pourrait dépasser la largeur du label.")
/* 65  */ AADD(aMsg,"La longueur actuelle est de : ")


RETURN aMsg


* ------------------------------------------
FUNCTION hwlabel_MSGS_DE()
* Set message array for german language
*
* ------------------------------------------
* aUmlaute[1] : CAGUML && AE Upper
* aUmlaute[2] : COGUML && OE
* aUmlaute[3] : CUGUML && UE
* aUmlaute[4] : CAKUML && AE Lower
* aUmlaute[5] : COKUML && OE
* aUmlaute[6] : CUKUML && UE
* aUmlaute[7] : CSZUML && SZ Sharp "S"
* aUmlaute[8] : Euro   && Euro currency sign
* ------------------------------------------
LOCAL aMsg , aUmlaute
aMsg := {}
aUmlaute := hwlabel_GUI_INIT_DE()

/*  1  */ AADD(aMsg,"HWLABEL Label Editor")     && Title of main window
/*  2  */ AADD(aMsg,"Schreibfehler Label-Datei")
/*  3  */ AADD(aMsg,"Dateizugriffsfehler")
* Main Menu / Hauptmenue
/*  4  */ AADD(aMsg,"&Datei")
/*  5  */ AADD(aMsg,"&Beenden")
/*  6  */ AADD(aMsg,"&Laden")
/*  7  */ AADD(aMsg,"&Speichern")
/*  8  */ AADD(aMsg,"&Bearbeiten")
/*  9  */ AADD(aMsg,"&Parameter")
/* 10  */ AADD(aMsg,"&Inhalt")
/* 11  */ AADD(aMsg,"&Hilfe")
/* 12  */ AADD(aMsg,"&" + aUmlaute[3] + "ber")
/* 13  */ AADD(aMsg,"&Sprache")
/* 14  */ AADD(aMsg,"&Einstellungen")
/* 15  */ AADD(aMsg,"&Hilfe")
* Label Parameters  / english / Range as comment
/* 16  */ AADD(aMsg,"Bemerkung (remarks)")                                      && Remarks L=60
/* 17  */ AADD(aMsg,"Zeilenanzahl (H" + aUmlaute[5] + "he)")                  && Height of label 1..16
/* 18  */ AADD(aMsg,"Spaltenbreite")                                           && Width of label 1..120
/* 19  */ AADD(aMsg,"Linker Rand")                                             && Left margin 0..250
/* 20  */ AADD(aMsg,"Horizontaler Abstand")       && (Zeilen)                    && Lines between labels 0..16
/* 21  */ AADD(aMsg,"Vertikaler Abstand")    && (Leerzeichen)                     && Spaces between labels 0 ... 120
/* 22  */ AADD(aMsg,"Anzahl Label/Zeile ")                                     && Number of labels across 1 .. 5
* Other messages
/* 23  */ AADD(aMsg,"Schlie" + aUmlaute[7] + "en")
/* 24  */ AADD(aMsg,"Lesefehler: Label-Datei, nicht 1034 Bytes")
/* 25  */ AADD(aMsg,"Label-Dateien")
/* 26  */ AADD(aMsg,"<KEIN LABEL>")
/* 27  */ AADD(aMsg,"Bei " + aUmlaute[1] + ;
                    "nderung der Sprache ist ein Neustart des Programms erforderlich")
/* 28  */ AADD(aMsg,"Label Editor")
/* 29  */ AADD(aMsg,"&Aufkleber")
/* 30  */ AADD(aMsg,"Alle Dateien")
/* 31  */ AADD(aMsg,"Label-Dateien")
/* 32  */ AADD(aMsg,"&Neu")
/* 33  */ AADD(aMsg,"Label-Inhalt")
/* 34  */ AADD(aMsg,"OK")
/* 35  */ AADD(aMsg,"Abbruch")
/* 36  */ AADD(aMsg,"Weiter")
/* 37  */ AADD(aMsg,"Lesefehler Label-Datei")
/* 38  */ AADD(aMsg,"Fehler beim " + aUmlaute[2] + "ffnen der Label-Datei")
/* 39  */ AADD(aMsg,"Label Parameter")
/* 40  */ AADD(aMsg,"Bearbeite Parameter f" + aUmlaute[6] + "r")
/* 41  */ AADD(aMsg,"Maximal 60 Zeichen" )
/* 42  */ AADD(aMsg,"Wertebereich, Default in Klammern" )
/* 43  */ AADD(aMsg,"Datei existiert, " + aUmlaute[3] + "berschreiben ?")
/* 44  */ AADD(aMsg,"Parameter wurden ge" + aUmlaute[4] + "ndert, Speichern ?")
/* 45  */ AADD(aMsg,"Label wurde ge" + aUmlaute[4] + "ndert,  ?")
/* 46  */ AADD(aMsg,"Keine " + aUmlaute[1]  + "nderung abzuspeichern")
/* 47  */ AADD(aMsg,"Label-Dateien ( *.lbl )")             && cloctext
/* 48  */ AADD(aMsg,"*.lbl")                                 && clocmsk
/* 49  */ AADD(aMsg,"Alle Dateien")                         && clocallf (GTK)
/* 50  */ AADD(aMsg,"Geben Sie einen Namen f"+ aUmlaute[6] + "r eine neue Label-Datei ein")  && cTextadd1 (Windows)
/* 51  */ AADD(aMsg,"Label-Datei sichern")                 && cTextadd2 (Windows)
/* 52  */ AADD(aMsg,"Warnung")
/* 53  */ AADD(aMsg,"Wird die H" + aUmlaute[5] + "he verringert, so gehen betroffene Inhalte verloren" + CHR(10) + "Nein=Abbruch")
/* 54  */ AADD(aMsg,"Setze Standardwerte")
/* 55  */ AADD(aMsg,"Aktuelles Label nicht gesichert, Ja=Verwerfen und laden, Nein=Abbruch")
/* 56  */ AADD(aMsg,"Label-Datei laden")
/* 57  */ AADD(aMsg,"Aktuelles Label nicht gesichert, Ja=Verwerfen, Nein=Abbruch")
/* 58  */ AADD(aMsg,"Neues Label")
/* 59  */ AADD(aMsg,"Fehler: Puffer-Gr" + aUmlaute[5] + aUmlaute[7] + "e nicht 1034 Bytes")
/* 60  */ AADD(aMsg,"Label-Datei laden")
/* 61  */ AADD(aMsg,"HWLABEL Hilfe")
/* 62  */ AADD(aMsg,"Keine Hilfe verf" + aUmlaute[6] + "gbar")
/* 63  */ AADD(aMsg,"Warnung !" + CHR(10) + "L" + CAKUML + "nge der Zeile ")
/* 64  */ AADD(aMsg," " + CUKUML + "berschreitet m" + COKUML + "glicherweise die" +CHR(10) + ;
                     "Breite des Aufklebers.")
/* 65  */ AADD(aMsg,"Aktuelle L" + CAKUML + "nge ist : ")

* aUmlaute[1]  = AE
* aUmlaute[2]  = OE
* aUmlaute[3]  = UE
* aUmlaute[4]  = ae
* aUmlaute[5]  = oe
* aUmlaute[6]  = ue
* aUmlaute[7]  = sz
* aUmlaute[8]  = EURO

RETURN aMsg

* ------------------------------------------
FUNCTION hwlabel_helptxt_EN(ntopic)
* Help text for label contents
* ntopic : A numeric value for specifying
* the displayed help text.
* 0 : (Default) Main menu of label editor
* 1 : Label parameter
* 2 : Label contents
* ------------------------------------------
LOCAL lf := CHR(13) + CHR(10)

IF ntopic == NIL
  ntopic := 0
ENDIF

IF ntopic == 0

 RETURN "The HWGUI label editor" + lf + ;
 "Copyright 2022 Wilfried Brunken, DF7BE" + lf + ;
 "https://sourceforge.net/projects/cllog/" + lf + ;
 "License:" + lf + ;
 "GNU General Public License" + lf + ;
 "with special exceptions of HWGUI." + lf + ;
 "See file " + CHR(34) + "license.txt" + CHR(34) + " for details of" + lf + ;
 "HWGUI project at" + lf + ;
 "https://sourceforge.net/projects/hwgui/" + lf + ;
 lf + ;
 CHR(34) + "Label" + CHR(34) + " is an important feature in business applications for" + lf + ;
 "example to label envelopes of letters to customers." + lf + ;
 lf + ;
 "The label editor is almost implememented in Clipper" + lf + ;
 "in the utility RL.EXE, in Summer 87 release as LABEL.EXE." + lf + ;
 lf + ;
 CHR(34) + "hwlabel" + CHR(34) + " is the port of this feature to HWGUI by using the WinPrn class," + lf + ;
 "so it is ready for multi platform usage and independent from" + lf + ;
 "the used printer model." + lf + ;
 lf + ;
 "For details, read the file " + CHR(34) + "Readme.txt" + CHR(34) + " and the other help information."

ENDIF

IF ntopic == 1
 RETURN "Edit Parameter for labels." + lf + ;
    "The following parameters are served for editing:" + lf + lf + ;
    "Left margin:" + lf +  ;
    "Defines the start position for the printout of " + lf + ;
    "the first label. At print of labels, this value is " + lf + ;
    "added to the value of SET MARGIN." ;
     + lf +  ;
     "Range is 0 to 250." + lf + lf +  ;
     "Spaces between labels:" ;
       + lf +  ;
      "For use with a set of labels with multible lanes :" ;
       + lf +  ;
      "This parameter defines the spaces between vertical lanes." ;
       + lf +  ;
      "This option could be used also to set left margin " + ;
      "for labels" + lf + "following the first label."  ;
       + lf  +  ;
      "Range is 0 to 16, default is 0." ;
       + lf + lf + ;
      "Set to 0 if using labels with only one lane."  ;
      + lf + lf + ;
      "Lines between labels: " + lf +  ;
      "Defines the number of blank lines between horizontal series" + ;
      " of labels." + lf +  ;
      "Range is 0 to 120" + lf + lf + ;
      "Number of labels across :"  + lf +  ;
      "Number of lanes in parallel." + lf + ;
      "If more than one lane, the printout" + ;
      " of the last line was adjusted automatically." ;
       + lf +  ;
      "Range is 1 to 5"
ENDIF

IF ntopic == 2
RETURN  "Contents of label:" + lf + lf + ;
     "Like your setting for the heigth of " + ;
     "label, here is an" + lf + "identical number of " + ;
     "lines served for editing. " + lf + ;
     "In this area it is necessary to insert Clipper " + lf + ;
     "expressions for creating the contents " + ;
     "of this label." + lf + ;
     "The maximum number of lines is 16. " + lf + ;
     "In the left columns the line number is displayed. " + lf + ;
     "Please take care of a valid syntax. Errors in the expressions " + lf + ;
     "causes a runtime error ! " + lf + ;
     "The label editor can not check " + lf + ;
     "the correctness of your expressions. " + lf + ;
     "The result of the expression in a line must be" + lf + ;
     "a string (Type = C !)" + ;
     + lf + lf + ;
     "Examples : " + ;
      lf +  ;
      lf +  ;
      "TRIM(VORNAME)+" + CHR(34) + " " + CHR(34) + "+NACHNAME" + ;
      lf +  ;
      "STRASSE" + ;
      lf +  ;
      "PLZ" + ;
      lf +  ;
      "ORT" +;
      lf +  ;
      lf +  ;
      "You can use standard Clipper functions. " + lf + ;
      "These functions are discribed in the Harbour Language Reference " + lf + ;
      "( e.g.. TRANSFORM() or TRIM() ). Also allowed are user defined functions of the " + lf + ;
      "program in use, if they are documentated by the developer team and  " + lf +;
      "implementated in the program." + ;
      lf +  ;
      "Although one line have only 60 characters, " + lf + ;
      "it is possible, that the printing output could be " + lf + ;
      "much longer. The recent " + lf + ;
      "maximum output length is limited by the attribute " + lf +;
      " >Width<, exceeded characters are omitted." + lf + ;
      + lf +  ;
      "Normally blank lines are visible on the label print. " + lf + ;
      "Example:" + ;
      lf +  ;
      lf +  ;
      "TRIM(VORNAME)+" + CHR(34) + " " + CHR(34) + "+NACHNAME" + ;
      lf +  ;
      "STRASSE" + ;
      lf +  ;
      lf +  ;
      "PLZ" + ;
      lf +  ;
      "ORT" +;
      lf +  ;
      lf +  ;
      "In this example the line between STRASSE and PLZ is empty." + lf + ;
      "If an expression returns in effect an empty string, " + lf + ;
      "( in this case expressed by " + lf + ;
      CHR(34) + CHR(34) + " or a database field is empty), so the complete " + lf + ;
      "line is omitted. There are " + lf + ;
      "different methods to avoid this empty string. " + lf + ;
      "It must be sent a non printing character, " + lf + ;
      "at its best is CHR(255). " + lf + ;
      "Using an IF expression the output of CHR(255)" + lf + "can be forced by " + ;
      "following:" + ;
      lf +  ;
      "  IF(!EMPTY(<stringfield>),<stringfield>,CHR(255) )" + ;
      lf +  ;
      "Sample:" + ;
      lf +  ;
      "  IF(!EMPTY(ADRESSE),ADRESSE,CHR(255) )" + ;
      lf +  ;
      lf +  ;
      "The developer can create a user defined function (UDF)" + lf + "handling this case " + ;
      "very easy: " + ;
      lf +  ;
      " FUNCTION NOSKIP(e)" + ;
      lf +  ;
      "   RETURN IF(!EMPTY(e),e,CHR(255) )" + ;
      lf +  ;
      lf +  ;
      "Now call this function by: NOSKIP(ADRESSE). This saves " + lf + ;
      "many space in the contents section." + ;
      lf +  ;
     "The function NOSKIP() ist also available in library module" + CHR(34) + "libhwlabel.prg" + CHR(34) + "." + ;
      lf + lf + ;
      lf +  ;
      "If your modifcation of the contents section is complete," + lf + "you can save the label file, " + lf + ;
      "(except you habe pressed the ESC key or the cancel button)." + ;
      lf +  ;
      "The following code snippet shows, how a label" + lf +  "is printed. Like this snippet you find such" + ;
      " a code in every Clipper application:" + ;
      lf +  ;
      "USE <database> INDEX <indexfile>" + ;
      lf +  ;
      "LABEL FORM <label file> TO PRINTER" + ;
      lf + lf + ;
      "Usage of variables in label:" + ;
      lf +  ;
      "You can read variables:" + ;
      lf + lf +  ;
      " - Database fields in aktive database" + ;
      lf +  ;
      " - all PUBLIC variables"  + ;
      lf +  ;
      " - all current valid LOCAL or PRIVATE" +  ;
      lf + ;
      "   variables" + ;
      lf + lf + ;
      "The usable variables are described " + lf + ;
      "in the related program documentation."
ENDIF

* Not specified topic
* No help available
hwg_MsgStop(aMsg[62],aMsg[61])

RETURN ""


* ------------------------------------------
FUNCTION hwlabel_helptxt_FR(ntopic)
* Help text for label contents
* ntopic : A numeric value for specifying
* the displayed help text.
* 0 : (Default) Main menu of label editor
* 1 : Label parameter
* 2 : Label contents
* ------------------------------------------
LOCAL lf := CHR(13) + CHR(10)

IF ntopic == NIL
  ntopic := 0
ENDIF

IF ntopic == 0

 RETURN XWIN_FR("L'éditeur de label par HWGUI" + lf + ;
 "Copyright 2022 Wilfried Brunken, DF7BE" + lf + ;
 "https://sourceforge.net/projects/cllog/" + lf +;
 lf +;
 "License:  GNU General Public License avec quelques exceptions liées à HWGUI." + lf + ;
 "Voir le fichier " + CHR(34) + "license.txt" + CHR(34) + " pour plus de détails du projet HwGUI à" + lf + ;
 "https://sourceforge.net/projects/hwgui/" + lf + ;
 lf + ;
 CHR(34) + "Label" + CHR(34) + " est une fonctionnalité importante dans les applications professionnelles" + lf + ;
 "par exemple pour les enveloppes de lettres aux clients." + lf + ;
 lf + ;
 "L'éditeur de label est aussi implémementé dans Clipper avec l'utilitaire RL.EXE,"+ lf +;
 "de la version Summer 87 en LABEL.EXE." + lf + ;
 lf + ;
 CHR(34) + "hwlabel" + CHR(34) + " est le portage de cette fonctionnalité pour HwGUI en utilisant la classe" + lf + ;
 "WinPrn," + lf + ;
 "aussi, il est multi platform et indépendant du modèle d'imprimante utilisé." + lf + ;
 lf + ;
 "Pour plus de détails, lire le fichier " + CHR(34) + "Readme.txt" + CHR(34) + " ainsi que les informations" ;
 + lf + "des autres aides." )

ENDIF

IF ntopic == 1
 RETURN XWIN_FR("Parametres de l'éditeur de label." + lf + ;
    "Les paramètres suivants servent pour l'édition:" + lf + lf + ;
    "Marge gauche:" + lf +  ;
    "Définie la position de départ lors de l'impression du" + lf + ;
    "premier label. Cette valeur est ajoutée à la valeur de SET MARGIN." + lf +  ;
     "La plage va de 0 à 250." + lf + lf +  ;
     "Espaces entre labels:" ;
       + lf +  ;
      "A utiliser lors d'utilisation de labels à plusieurs colonnes :" ;
       + lf +  ;
      "Ce paramètre définie l'espace entre deux colonnes verticales." ;
       + lf +  ;
      "Cette option pourrait aussi être utilisée pour définir la marge gauche " + lf + ;
      "des labels fsuivant le premier label."  ;
       + lf  +  ;
      "La plage va de 0 à 16, la valeur par défaut est 0." ;
       + lf + lf + ;
      "Définie à 0 si les labels n'utilisent qu'une seule colonne."  ;
      + lf + lf + ;
      "Nombre de lignes entre les labels: " + lf +  ;
      "Définit le nombre de lignes vierges entre" + lf + ;
      "des series horizontales de labels." + lf + ;
      "La plage va de 0 à 120" + lf + lf + ;
      "Nombre d'étiquettes sur :" + lf + ;
      "Nombre de voies en parallèle."  + lf + ;
      "S'il y a plus d'une voie, l'impression de la dernière" + lf + ;
      "ligne a été ajustée automatiquement." + lf + ;
      "La plage est de 1 à 5" )
ENDIF

IF ntopic == 2
RETURN  XWIN_FR("Contenus du label:" + lf + lf + ;
     "Conformement à votre réglage pour la hauteur" + ;
     "d'étiquette, voici un nombre identique" + lf + ;
     "de lignes servies pour l'édition. " + lf + ;
     "Dans cette zone, il est nécessaire d'insérer des" + lf + ;
     "expressions clipper pour créer le contenu" + ;
     "de cette étiquette." + lf + ;
     "Le nombre maximum de lignes est de 16. " + lf + ;
     "Dans les colonnes de gauche, le numéro de ligne est affiché. " + lf + ;
     "Veuillez faire attention à une syntaxe valide." + lf + ;
     "Les erreurs dans les expressions provoque des erreurs d'exécution !" + lf + ;
     "L'éditeur d'étiquettes ne peut pas vérifier la justesse de vos expressions." + lf + ;
     "Le résultat de l'expression dans une ligne doit être une chaîne (Type = C !)" + ;
     + lf + lf + ;
     "Exemples : " + ;
      lf +  ;
      lf +  ;
      "TRIM(VORNAME)+" + CHR(34) + " " + CHR(34) + "+NACHNAME" + ;
      lf +  ;
      "STRASSE" + ;
      lf +  ;
      "PLZ" + ;
      lf +  ;
      "ORT" +;
      lf +  ;
      lf +  ;
      "Vous pouvez utiliser les fonctions standard de Clipper." + lf + ;
      "Ces fonctions sont décrites dans 'Harbour Language Reference'" + lf + ;
      "( par exemple, TRANSFORM() ou TRIM() ). Sont également autorisées"+lf +;
      "les fonctions définies par l'utilisateur du " + lf + ;
      "programme en cours d'utilisation, s'ils sont documentés" ;
      + lf + "par l'équipe de développeurs et " + ;
      "mis en œuvre dans le programme." + lf + ;
      "Bien qu'une ligne ne comporte que 60 caractères, " + lf + ;
      "il est possible que la sortie d'impression soit " + lf + ;
      "beaucoup plus longue." + lf + ;
      "La longueur maximale de sortie est limitée par l'attribut " + lf + ;
      "[Largeur], les caractères dépassés sont omis." + lf + ;
       lf + ;
      "Normalement, des lignes vierges sont visibles sur l'impression de l'étiquette. " + lf + ;
      "Exemple :" + ;
      lf +  ;
      lf +  ;
      "TRIM(VORNAME)+" + CHR(34) + " " + CHR(34) + "+NACHNAME" + ;
      lf +  ;
      "STRASSE" + ;
      lf +  ;
      lf +  ;
      "PLZ" + ;
      lf +  ;
      "ORT" +;
      lf +  ;
      lf +  ;
      "Dans cet exemple, la ligne entre STRASSE et PLZ est vide." + lf + ;
      "Si une expression renvoie en effet une chaîne vide, " + lf + ;
      "( dans ce cas exprimé par " + lf + ;
      CHR(34) + CHR(34) + " ou un champ de la base de données est vide), donc la " + lf + ;
      "ligne est omise. Il y a " + lf + ;
      "différentes méthodes pour éviter cette chaîne vide. " + lf + ;
      "Il doit être envoyé un caractère non imprimable, " + lf + ;
      "le plus indiqué étant CHR(255). " + lf + ;
      "En utilisant une expression IF, la sortie de CHR(255)" + lf + ;
      "peut être forcée par ce qui suit :" + ;
      lf +  ;
      "  IF(!EMPTY(<stringfield>),<stringfield>,CHR(255) )" + ;
      lf +  ;
      "Sample:" + ;
      lf +  ;
      "  IF(!EMPTY(ADRESSE),ADRESSE,CHR(255) )" + ;
      lf +  ;
      lf +  ;
      "Le développeur peut créer une fonction définie par l'utilisateur (UDF)" + lf +;
      "gestion très facile de ce cas : " + ;
      lf +  ;
      " FUNCTION NOSKIP(e)" + ;
      lf +  ;
      "   RETURN IF(!EMPTY(e),e,CHR(255) )" + ;
      lf +  ;
      lf +  ;
      "Appelez maintenant cette fonction par : NOSKIP(ADRESSE). Cela économise " + lf + ;
      "beaucoup d'espace dans la section contenu." + ;
      lf + ;
     "La fonction NOSKIP() est aussi disponible dans le module bibliothèque" ;
       + lf  + CHR(34) + "libhwlabel.prg" + CHR(34) + "." + lf + lf + ;
      lf + ;
      "Si votre modification de la section de contenu est terminée," +lf + ;
      "vous pouvez enregistrer le fichier d'étiquette, " +lf+ ;
      "(sauf si vous avez appuyé sur la touche ESC ou sur le bouton d'annulation)." + ;
      lf + ;
      "L'extrait de code suivant montre comment une étiquette est imprimée." + lf + ;
      "Comme cet extrait que vous pouvez trouver dans chaque application Clipper" + ;
      lf +  ;
      "USE <database> INDEX <indexfile>" + ;
      lf +  ;
      "LABEL FORM <label file> TO PRINTER" + ;
      lf + lf + ;
      "Utilisation de variables dans le label:" + ;
      lf +  ;
      "Vous pouvez utiliser des variables:" + ;
      lf + lf +  ;
      " - Champs de la base active" + ;
      lf +  ;
      " - toute variable PUBLIC"  + ;
      lf +  ;
      " - toute courante variable LOCAL ou PRIVATE" +  ;
      lf + lf + ;
      "Les variables utilisables sont décrites " + lf + ;
      "dans la documentation du programme concerné.")
ENDIF

* Not specified topic
* No help available
hwg_MsgStop(aMsg[62],aMsg[61])

RETURN ""


* ------------------------------------------
FUNCTION hwlabel_helptxt_DE(ntopic)
* Help text for label contents (German)
* ------------------------------------------
LOCAL lf := CHR(13) + CHR(10)
LOCAL aUmlaute
LOCAL CAGUML, COGUML , CUGUML , CAKUML, COKUML , CUKUML , CSZUML , EURO
aUmlaute := hwlabel_GUI_INIT_DE()
CAGUML := aUmlaute[1]  && AE
COGUML := aUmlaute[2]  && OE
CUGUML := aUmlaute[3]  && UE
CAKUML := aUmlaute[4]  && ae
COKUML := aUmlaute[5]  && oe
CUKUML := aUmlaute[6]  && ue
CSZUML := aUmlaute[7]  && sz
EURO   := aUmlaute[8]

IF ntopic == NIL
  ntopic := 0
ENDIF

IF ntopic == 0

 RETURN "Der HWGUI Label Editor" + lf + ;
 "Copyright 2022 Wilfried Brunken, DF7BE" + lf + ;
 "https://sourceforge.net/projects/cllog/" + lf + ;
 "Lizenz:" + lf + ;
 "GNU General Public License" + lf + ;
 "mit speziellen Ausnahmen von HWGUI." + lf + ;
 "Siehe Datei " + CHR(34) + "license.txt" + CHR(34) + " f" + CUKUML + "r" + lf + ;
 "Details (in englischer Sprache) auf der Webseite des" + lf + ;
 "HWGUI Projektes auf" + lf + ;
 "https://sourceforge.net/projects/hwgui/" + lf + ;
 lf + ;
 CHR(34) + "Label" + CHR(34) + " ist ein wichtiges Leistungsmerkmal f" + CUKUML + "r" + lf + ;
 "gesch" + CAKUML + "ftliche Anwendungen. Es wird h" + CAKUML + "ufig daf" + CUKUML + "r" + lf + ;
 "genutzt, um Adressaufkleber f" + CUKUML + "r Briefe an Kunden" + lf + ;
 "auszudrucken." + lf + ;
 lf + ;
 "Der Label-Editor ist grunds" + CAKUML + "tzlich implemementiert in Clipper" + lf + ;
 "im Utility RL.EXE, in der Sommmer 87 Version als LABEL.EXE." + lf + ;
 lf + ;
 CHR(34) + "hwlabel" + CHR(34) + " ist die Portierung dieses Leistungsmerkmales zu HWGUI" + lf + ;
 "unter Nutzung der " + CHR(34) + "HWinPrn"  + CHR(34) + " Klasse," + lf + ;
 "damit ist es bereit f" + CUKUML + "r eine " + CHR(34) + "Multi Platform" + CHR(34) + " Anwendung und" + lf + ;
 "unabh" + CAKUML + "ngig vom verwendeten Drucker-Modell." + lf + ;
 lf + ;
 "F" + CUKUML + "r mehr Details, lies die Datei " + CHR(34) + "Readme_de.txt" + CHR(34) + " und die anderen" + lf + ;
 "Hilfe-Informationen."

ENDIF

IF ntopic == 1
 RETURN "Eingabe der Parameter f" + CUKUML + "r die Aufkleber." + lf + ;
  "Die folgenden Parameter werden zur Eingabe angeboten:" + lf + lf + ;
  "Linker Rand (left margin):" + lf +  ;
  "Legt die Anfangsposition f" + CUKUML + "r die Ausgabe auf dem " + ;
  "ersten Aufkleber fest." + lf + "Beim Ausdruck der Etiketten wird dieser " + ;
  "Wert" + ;
     + lf + ;
  "zu dem " + CUKUML + "ber SET MARGIN angegeben Wert hinzuaddiert." ;
     + lf +  ;
  "Wertebereich 0 bis 250." ;
     + lf + lf + ;
  "Vertikaler Abstand (spaces between labels):" ;
     + lf +  ;
  "Bei der Ausgabe von mehreren Etiketten nebeneinander " + lf + ;
  "(mehrere Bahnen) bestimmt" + ;
  " dieser Parameter den Abstand zwischen den einzelnen" + lf + ;
  "Etiketten." + lf + ;
  "Diese Option kann auch zum Festlegen des linken Randes f" + ;
  CUKUML + "r die dem" + ;
     + lf +  ;
  "ersten Etikett folgenden Etiketten verwendet werden." ;
   + lf +  ;
  "Wertebereich 0 bis 16, Default ist 0." + ;
     + lf +  ;
  "W" + CAKUML + "hlen Sie in jedem Fall den " + ;
  "Wert 0, wenn Sie einreihige Klebeetiketten verwenden."  + lf + lf + ;
  "Horizontaler Abstand (lines between labels) : " + lf +  ;
  "Legt die Anzahl der Leerzeilen zwischen den einzelnen Reihen" + ;
  " der Etiketten fest." + lf +  ;
  "Wertebereich ist 0 bis 120" + lf + lf +;
  "Label pro Zeile (number of lab. across) : "  + lf +  ;
  "Ist die Anzahl der Bahnen, der nebeneinander zu druckenden" + ;
  " Etiketten." + ;
  + lf +  ;
  "Falls mehrere Etiketten nebeneinander liegen," + ;
  " wird die Ausgabe auf der letzten Zeile automatisch angepa" + ;
  CSZUML + "t." + ;
  + lf +  ;
  "Wertebereich ist 1 bis 5"
ENDIF

IF ntopic == 2
RETURN "Label-Inhalt:" + lf + lf + ;
      "Abh" + CAKUML + "ngig von der ausgew" + CAKUML + "hlten H" + ;
      COKUML + "he wird Ihnen eine identische Anzahl " + ;
     "Zeilen" + lf + "angeboten. " + lf + ;
     "Hier m" + CUKUML + "ssen entsprechende Clipper-Ausdr" + ;
     CUKUML + "cke eingegeben werden," + lf + "um den" + ;
     " Inhalt des Aufklebers darzustellen." + lf + ;
     "Es sind h" +  COKUML + "chstens 16 Zeilen "  + ;
     "m" + COKUML + "glich. Die Zeilennummern werden in der linken Spalte" + lf + "angezeigt." + lf + ;
     "Bitte beachten, da" + CSZUML + " Fehler in der Formulierung" + lf + "der Anweisungen bei der " + ;
     "Ausf" + CUKUML + "hrung zu einem Laufzeitfehler" + lf + "f" + ;
     CUKUML + "hren. Der Label-Editor kann diese Pr" + CUKUML + "fung nicht " + ;
     CUKUML + "bernehmen. " + lf + ;
     "Der R" + CUKUML + "ckgabewert des gesamten Ausdrucks in einer Zeile" + lf + ;
     "mu" + CSZUML + " einen String ergeben (Typ = C !)" + ;
     lf + lf + ;
     "Beispiele : " + ;
      lf +  ;
      lf +  ;
      "TRIM(VORNAME)+" + CHR(34) + " " + CHR(34) + "+NACHNAME" + ;
      lf +  ;
      "STRASSE" + ;
      lf +  ;
      "PLZ" + ;
      lf +  ;
      "ORT" + ;
      lf +  ;
      lf +  ;
      "Weiterhin k" + COKUML + "nnen auch Clipper-Funktionen verwendet werden. " + lf + ;
      "Dieses k" + COKUML + "nnen zum Beispiel Funktionen aus den Clipper-Bibliotheken " + lf + ;
      "( z.B. TRANSFORM() oder TRIM() ) oder auch benutzerdefinierte Funktionen sein," + lf + "wenn" + ;
      " diese vom Programmierer bekannt gegeben wurden" + lf + "und entsprechend " + ;
      "im Programm implementiert sind." + ;
      lf +  ;
     "Obwohl eine Zeile nur 60 Zeichen zul" + ;
     CAKUML + CSZUML + "t," + lf + "kann die Druckausgabe " + ;
     "weitaus l" + CAKUML + "nger sein." + lf + "Die tats" + ;
     CAKUML + "chliche maximale Ausgabel" + CAKUML + "nge wird durch das " + ;
     "Attribut >Breite< festgelegt," + lf + CUKUML + "berstehene Zeichen werden " + ;
     "unterdr" + CUKUML + "ckt."  ;
     + lf +  ;
     "Leerzeilen f" + CUKUML + "hren normalerweise auch zu einer tats" + ;
     CAKUML + "chlichen " + lf + ;
     "Leerzeile auf dem Etikett." + lf + "Dazu das Beispiel." + ;
     lf +  ;
     lf +  ;
      "TRIM(VORNAME)+" + CHR(34) + " " + CHR(34) + "+NACHNAME" + ;
      lf + ;
      "STRASSE" + ;
      lf + ;
      lf +  ;
      "PLZ" + ;
      lf +  ;
      "ORT" +;
      lf +  ;
      lf +  ;
     "Hier bleibt die Zeile zwischen Strasse und Postleitzahl leer." + lf + ;
     "Liefert ein Ausdruck jedoch einen " + ;
     "richtigen Leerstring" + lf + "( im einfachsten Fall durch formulieren von " + ;
     CHR(34) + CHR(34) + " oder wenn das Feld in der Datenbank" + lf + "leer ist), so wird diese Leerzeile" + ;
     " unterdr" + CUKUML + "ckt. Es gibt " + ;
     "verschiedene Methoden," + lf + ;
     "diesen Leerstring zu unterdr" + CUKUML + "cken." + lf + ;
     "Es muss in jedem Falle daf" + CUKUML + "r gesorgt werden," + ;
     "dass ein nichtabdruckbares " + lf + ;
     "Zeichen gesendet wird, am besten CHR(255). " + lf + ;
     "Mit Hilfe eines IF-Ausdruckes kann die Ausgabe von CHR(255) " + lf + " wie " + ;
     "folgt erzwungen werden:" + ;
      lf +  ;
     "  IF(!EMPTY(<zeichenkettenfeld>),<zeichenkettenfeld>,CHR(255) )" + ;
      lf +  ;
     "Beispiel:" + ;
      lf +  ;
     "  IF(!EMPTY(ADRESSE),ADRESSE,CHR(255) )" + ;
      lf +  ;
      lf +  ;
     "Zus" + CAKUML + "tzlich kann dieses vom Programmierer durch eine anwenderdefinierte " + lf + ;
     "Funktion (UDF) realisiert werden: " + ;
      lf +  ;
     " FUNCTION NOSKIP(e)" + ;
      lf +  ;
     "   RETURN IF(!EMPTY(e),e,CHR(255) )" + ;
      lf +  ;
      lf +  ;
     "Dann rufe man einfach auf :" + lf + "NOSKIP(ADRESSE)" + lf +  "Man kann dadurch viel " + ;
     "Platz einsparen." + ;
      lf +  ;
     "Die Funktion NOSKIP() ist bereits in der Bibliothek " + CHR(34) + "libhwlabel.prg" + CHR(34) + ;
     "implementiert." + ;
      lf + lf + ;
     "Wenn Sie nun alle Eingaben gemacht haben, wird das Label gespeichert, " + lf + ;
     "(au" + CSZUML + "er Sie haben die ESC-Taste gedr" + CUKUML + "ckt oder" + lf + ;
      "den " + CHR(34) + "Abbruch" + CHR(34) + " Knopf bet" + CAKUML + "tigt)." + ;
      lf +  ;
     "Der folgende Programmteil druckt dann Ihr Label aus und ist in etwa dieser Form " + lf + ;
     "in jeder Clipper Anwendung formuliert:" + ;
      lf +  ;
      "USE <datenbank> INDEX <indexdatei>" + ;
      lf +  ;
      "LABEL FORM <label-Datei> TO PRINTER" + ;
      lf + lf + ;
      "Variablenangaben im Label:" + ;
      lf +  ;
      "Sie k" + COKUML + "nnen als Variablen angeben:" + ;
      lf +  lf +  ;
      " - Felder in der aktiven Datenbank" + ;
      lf +  ;
      " - alle PUBLIC-Variablen"  + ;
      lf +  ;
      " - alle momentan g" + CUKUML + "ltigen LOCAL- oder PRIVATE-" +  ;
      lf + ;
      "   Variablen" + ;
      lf + lf + ;
      "Welche dieses sind, entnehmen Sie der " + ;
      "zugeh" + COKUML + "rigen Programmdokumentation. " ;
      + lf  + ;
      "Es sollte m" + COKUML + "glich sein, da" + CSZUML + " das Euro-Zeichen (" + EURO + ")" + lf + ;
      "auch ausgedruckt werden kann." + CHR(32)

ENDIF

* Nicht benanntes Hilfe-Thema
* Keine Hilfe verfuegbar
hwg_MsgStop(aMsg[62],aMsg[61])
RETURN ""

* ------------------------------------------
FUNCTION hwlabel_About()
* ------------------------------------------
Hwg_MsgInfo("HWGUI label editor Version 1.0" + CHR(10) + ;
"Copyright 2022 W.Brunken, DF7BE","About")
RETURN NIL

* ------------------------------------------
FUNCTION hwlabel_Mainhlp(clang,ndlg)
* Shows the help window by dialog.
*
* ndlg:
* The topic of help text displayed
* 0 : Main dialog (Default)
* 1 : Parameters
* 2 : Contents
* clang :
* Language to display.
* Pass here the value of the static
* variable "clangset".
* Default is English.
* For valid value see
* FUNCTION hwlabel_langinit()
* ------------------------------------------
LOCAL lnmodal

#ifdef __PLATFORM__WINDOWS
lnmodal := .T.
#else
lnmodal := .F.
#endif

* Trouble with NOMODAL on LINUX:
* The window with help text freezes, it closes
* only, if the calling dialog is closed.
* For example:
* Pressing the "Close" button or the cross in the header bar
* has no effect.

IF clang == NIL
 clang := "English"
ENDIF

* Default
IF clang == "English"
* 61 = "HWLABEL Help" , 23 = "Close"
hwg_ShowHelp(hwlabel_helptxt_EN(ndlg),aMsg[61],aMsg[23],,lnmodal)
ENDIF
* Other languages
IF clang == "Deutsch"
* 61 =  "HWLABEL Hilfe" , 23 = "Schliessen"
hwg_ShowHelp(hwlabel_helptxt_DE(ndlg),aMsg[61],aMsg[23],,lnmodal)
ENDIF
* Other languages
IF clang == XWIN_FR("Français")
* 61 =  "Aide HwLabel" , 23 = "Fermer"
hwg_ShowHelp(hwlabel_helptxt_FR(ndlg),aMsg[61],aMsg[23],,lnmodal)
ENDIF


RETURN NIL

* ------------------------------------------
FUNCTION hwlabel_str_nolabel()
* Returns string for "no label set"
RETURN aMsg[26]
* ------------------------------------------


* =========== FUNCTIONS for MAIN ==================================

* ---------------------------------------------
STATIC FUNCTION hwlabel_NLS_SetLang(cname)
* Sets the desired language for NLS
* Default: "English"
* Additional languages:
* "Deutsch" Germany @ Euro
* "Français" France @ Euro
* ---------------------------------------------

/* Add case block for every new language */
  DO CASE
   CASE cname == "Deutsch"  && Germany @ Euro
      clangset := "Deutsch"
      clang    := "DE"
      aMsg     := hwlabel_MSGS_DE()
   CASE cname == XWIN_FR("Français")  && France @ Euro
      clangset := XWIN_FR("Français")
      clang    := "FR"
      aMsg     := hwlabel_MSGS_FR()
   * Add here more languages
   *  CASE cname == "xxxxxx"
   OTHERWISE                && Default EN
      clangset := "English"
      clang    := "EN"
      aMsg     := hwlabel_MSGS_EN()
 ENDCASE

RETURN NIL


* ---------------------------------------------
* STATIC FUNCTION CONV_NLS_Value()



* --------------------------------------------
STATIC FUNCTION Select_LangDia(acItems,omlblmnu)
* Dialog for select a language.
* acItems : List of languages, pass STATIC array aLanguages
* omlblmnu : Obeject of calling dialog.
* --------------------------------------------
LOCAL result
 result := __frm_CcomboSelect(acItems,"Language","Please Select a language", ;
   200 , "OK" , "Cancel", "Help" , "Need Help : " , "HELP !" )
 IF result != 0
  * set to new language, if modified
  clangset := aLanguages[result]
//  hwg_Msginfo("clangset=" + clangset)
  hwlabel_NLS_SetLang(clangset)
  hwg_MsgInfo("Language set to " + clangset,"Language Setting")
  * Write to ini file, if modified
  WRIT_LANGINI(clangset)
  hwg_MsgInfo(aMsg[27],aMsg[28])
  omlblmnu:Close()
 ENDIF
RETURN NIL

* ==========================================
STATIC FUNCTION __frm_CcomboSelect(apItems, cpTitle, cpLabel, npOffset, cpOK, cpCancel, cpHelp , cpHTopic , cpHVar , npreset)
* Common Combobox Selection
* One combobox flexible.
* Parameters: (Default values in brackets)
* apItems  : Array with items (empty)
* cpTitle  : Title for dialog ("Select Item")
* cpLabel  : Headline         ("Select Item")
* npOffset : Number of pixels for windows size offset, y axis (0)
*            recommended value: depends of number of items:
*            npOffset = (n - 1) * 30 (not exact)
* cpOK     : Button caption   ("OK")
* cpCancel : Button caption   ("Cancel")
* cpHelp   : Button caption   ("Help")
* cpHTopic : HELP() : Topic   ("")
* cpHVar   : HELP() : Variable Name ("")
* npreset  : Preserve position (1)
*
* Sample call :
*
* LOCAL result,acItems
* acItems := {"One","Two","Three"}
* result := __frm_CcomboSelect(acItems,"Combo selection","Please Select an item", ;
*  0 , "OK" , "Cancel", "Help" , "Need Help : " , "HELP !" )
* returns: index number of item, if cancel: 0
* ============================================
LOCAL oDlgcCombo1
LOCAL aITEMS , cTitle, cLabel, nOffset, cOK, cCancel, cHelp , cHTopic , cHVar
LOCAL oLabel1, oCombobox1, oButton1, oButton2, oButton3 , nType , yofs, bcancel ,nRetu

* Parameter check
 cTitle  := "Select Item"
 cLabel  := "Select Item"
 nOffset := 0
 cOK     := "OK"
 cCancel := "Cancel"
 cHelp   := "Help"
 cHTopic := ""
 cHVar   := ""
 nRetu   := 0

aITEMS := {}
IF .NOT. apItems == NIL
 aITEMS := apItems
ENDIF
IF .NOT. cpTitle == NIL
 cTitle := cpTitle
ENDIF
IF .NOT. cpLabel == NIL
 cLabel :=  cpLabel
ENDIF
IF .NOT. npOffset == NIL
 nOffset :=  npOffset
ENDIF
IF .NOT. cpOK == NIL
 cOK  :=  cpOK
ENDIF
IF .NOT. cpCancel == NIL
 cCancel :=  cpCancel
ENDIF
IF .NOT. cpHelp == NIL
 cHelp :=  cpHelp
ENDIF
IF .NOT. cpHTopic == NIL
 cHTopic  := cpHTopic
ENDIF
IF .NOT. cpHVar == NIL
 cHVar  := cpHVar
ENDIF
nType := 1
IF .NOT. npreset == NIL
 nType := npreset
ENDIF

bcancel := .T.
yofs := nOffset + 120
* y positions of elements:
* Label1       : 44
* Buttons      : 445  : ==> yofs
* Combobox     : 84   :
* Dialog size  : 565  : ==> yofs + 60
*
  INIT DIALOG oDlgcCombo1 TITLE cTitle ;
    AT 578,79 SIZE 516, yofs + 80;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 67,44 SAY oLabel1 CAPTION cLabel SIZE 378,22 ;
        STYLE SS_CENTER
   @ 66,84 GET COMBOBOX oCombobox1 VAR nType ITEMS aITEMS SIZE 378,96
   @ 58 , yofs  BUTTON oButton1 CAPTION cOK SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || nRetu := nType , bcancel := .F. , oDlgcCombo1:Close() }
   @ 175, yofs  BUTTON oButton2 CAPTION cCancel SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || oDlgcCombo1:Close() }
//   @ 375, yofs  BUTTON oButton3 CAPTION cHelp SIZE 80,32 ;
//        STYLE WS_TABSTOP+BS_FLAT ON CLICK { || HELP( cHTopic ,PROCLINE(), cHVar ) }

   ACTIVATE DIALOG oDlgcCombo1
* RETURN oDlgcCombo1:lresult
//  hwg_MsgInfo("Result=" + STR(nRetu))
RETURN nRetu

* ================================= *
FUNCTION hwlabel_debug(varname,xv1,xv2)
* Display debug info.
* 1 or 2 variables of same type.
* (type of xv1 was autmatically detected,
*  so xv2 must be of same type, if
*  passed)
* xv2 could be NIL
* ================================= *
LOCAL ctype, coutput, lxv2nil
lxv2nil := .F.
IF varname == NIL
  varname := ""
ELSE
  varname := ALLTRIM(varname) + " : "
ENDIF
IF xv2 == NIL
  lxv2nil := .T.
ENDIF
ctype := VALTYPE(xv1)
  IF ctype == "B"
    hwg_MsgInfo("Block","Debug")
  ELSEIF ctype == "N"
    IF lxv2nil
     coutput := varname + ">" + ALLTRIM(STR(xv1)) + "<"
    ELSE
     coutput := varname + ">" + ALLTRIM(STR(xv1)) + "<"  + CHR(10) + ">" + ALLTRIM(STR(xv2)) + "<"
    ENDIF
    hwg_MsgInfo(coutput,"Debug")
  ELSEIF ctype == "D"
    IF lxv2nil
      coutput := varname + "ANSI: " + DTOS(xv1) + "<"
    ELSE
      coutput := varname + "ANSI: " + DTOS(xv1) + "<"  + CHR(10) + ">" +  DTOS(xv2)+ "<"
    ENDIF
    hwg_MsgInfo(coutput,"Debug")
  ELSEIF ctype == "L"
    IF lxv2nil
     coutput := varname + ">" + IIF(xv1,".T.",".F." ) + "<"
    ELSE
     coutput := varname + ">" + IIF(xv1,".T.",".F." ) + "<"  + CHR(10) + ">" + IIF(xv2,".T.",".F." ) + "<"
    ENDIF
    hwg_MsgInfo(coutput,"Debug")
  ELSEIF ctype == "C"
    IF lxv2nil
     coutput := varname + ">" + xv1 + "<"
    ELSE
     coutput := varname + ">" + xv1 + "<"  + CHR(10) + ">" + xv2 + "<"
    ENDIF
    hwg_MsgInfo(coutput,"Debug")
  ENDIF


RETURN NIL

* ================================= *
STATIC FUNCTION READ_LANGINI()
*  Read language setting from language.ini
*  If file not exists, the function
*  returns as default value
*  "English"
* ================================= *
LOCAL clangdef, csprach
*               read buffer
*               !                file name
*               !                !
*               v                v
LOCAL handle, puffer, eBlock, dateiname
 dateiname := "language.ini"
 puffer = ""
 clangdef := "English"  && Default

IF FILE(dateiname)
* Read from file
 handle := FOPEN(dateiname,0)     && FO_READ
 IF FERROR() <> 0
    * RETURN ""
    * File error: return the default value
    FCLOSE(handle)
    RETURN clangdef
  ENDIF
 * FSEEK(handle,0,2)
  puffer := LANG_READ_TEXT(handle)  && 1. Satz lesen, read first record
  * hwg_msginfo("puffer=" + puffer,"Debug")
  FCLOSE(handle)
ENDIF

 IF .NOT. EMPTY(puffer)
   clangdef := puffer
 ENDIF


RETURN clangdef

* ================================= *
STATIC FUNCTION LANG_READ_TEXT(h)
* Reads a text record from a binary file
* h : file handle
*
* ================================= *
 LOCAL p , p1 , se , r

 p := ""
 p1 := " "
 se := 1
 r := ""

 DO WHILE ( se == 1 )
  p1 :=  FREADSTR(h , 1 )
  IF p1 == ""
   se := 0
  ENDIF

  p := p + p1
  && Detect end of line
  IF ( p1 == CHR(10) )
   se := 0
  ENDIF
 ENDDO
*  Remove "Return" from String
 p := STRTRAN(p,CHR(10),"")
 r := STRTRAN(p,CHR(13),"")
RETURN r

* ================================= *
STATIC FUNCTION WRIT_LANGINI(cplang)
*  Write language setting to language.ini
* cplang : Value to write into file,
* for example :
*  "English"  (Default)
*  "Deutsch"
* Returns forever NIL
* ================================= *
LOCAL clang, Puffer, Laenge, dat_handle , dateiname
dateiname := "language.ini"  && file name
clang :=  "English"          && Default language
IF cplang != NIL
  clang := ALLTRIM(cplang)
ENDIF

* Write to file
 IF .NOT. FILE(dateiname)
   dat_handle := FCREATE(dateiname,0)  && FC_NORMAL
 ELSE
   Erase &dateiname
   dat_handle := FCREATE(dateiname,0)
 ENDIF
 IF dat_handle != -1
  FSEEK (dat_handle,0,2)
 ENDIF
 * Write record
 Puffer := clang + CHR(13) + CHR(10)
 Laenge := LEN(Puffer)
 FWRITE(dat_handle,Puffer, Laenge)

* Optional: here output of error message at file IO error possible
*  IF FWRITE(dat_handle,Puffer, Laenge) != Laenge
*  * Error message
*  ENDIF
 FCLOSE(dat_handle)
RETURN NIL


* ==============================================
FUNCTION hwlabel__LBL_LINES()
* Returns the number of lines (heigth of label)
* of recent label in the edit buffer
* (type = N)
* ==============================================
RETURN n_NUMZ


FUNCTION XWIN_FR(clang)
* ~~~~~~~~~~ French ~~~~~~~~~~~~~~~~~~~~~~~~~~
* Translates UTF8 to Windows charset
* ---------------------------------------------
#ifdef __PLATFORM__WINDOWS
// The function HB_TRANSLATE() crashes with "Argument Error", but i don't
// know, why ?
// RETURN HB_TRANSLATE( clang, "UTF8", "DEWIN" )
// So own solution for translation
// This runs OK also on Windows
LOCAL cltxt
cltxt := clang

cltxt := STRTRAN(cltxt,"à",CHR(224))
cltxt := STRTRAN(cltxt,"é",CHR(233))
cltxt := STRTRAN(cltxt,"è",CHR(232))
cltxt := STRTRAN(cltxt,"ê",CHR(234))
cltxt := STRTRAN(cltxt,"î",CHR(238))
cltxt := STRTRAN(cltxt,"œ",CHR(156))    && oe
cltxt := STRTRAN(cltxt,"ç",CHR(231))
cltxt := STRTRAN(cltxt,"€",CHR(128))   && EURO
RETURN cltxt
#else
* On LINUX using UTF-8
RETURN clang
#endif

* ================================= *
FUNCTION hwlbl_IconHex()
* Hex value for icon "hwlabel.ico"
* Size 48x48
* ================================= *
RETURN ;
"00 00 01 00 01 00 30 30 00 00 01 00 08 00 A8 0E " + ;
"00 00 16 00 00 00 28 00 00 00 30 00 00 00 60 00 " + ;
"00 00 01 00 08 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 FF FF FF 00 14 FF FF 00 00 FF FF 00 5B FF " + ;
"FF 00 B4 B4 B4 00 00 35 35 00 00 CD CD 00 00 0B " + ;
"0B 00 00 F3 F3 00 00 09 09 00 00 CE CE 00 00 C5 " + ;
"C5 00 00 1C 1C 00 00 E9 E9 00 00 0D 0D 00 00 EC " + ;
"EC 00 00 18 18 00 00 E3 E3 00 00 C2 C2 00 00 41 " + ;
"41 00 00 D2 D2 00 00 DD DD 00 00 0E 0E 00 00 5E " + ;
"5E 00 00 9E 9E 00 00 2E 2E 00 00 3C 3C 00 00 10 " + ;
"10 00 00 2B 2B 00 00 37 37 00 00 02 02 00 00 7B " + ;
"7B 00 00 69 69 00 00 8A 8A 00 00 9C 9C 00 00 51 " + ;
"51 00 00 A2 A2 00 00 59 59 00 00 05 05 00 00 C1 " + ;
"C1 00 00 DB DB 00 00 C9 C9 00 00 EE EE 00 00 E8 " + ;
"E8 00 00 25 25 00 00 A3 A3 00 00 DE DE 00 00 CB " + ;
"CB 00 00 D4 D4 00 00 3B 3B 00 00 B7 B7 00 00 54 " + ;
"54 00 00 99 99 00 00 E2 E2 00 00 1A 1A 00 00 95 " + ;
"95 00 00 90 90 00 00 6C 6C 00 00 FA FA 00 00 23 " + ;
"23 00 00 72 72 00 00 42 42 00 00 B9 B9 00 00 78 " + ;
"78 00 00 7C 7C 00 00 0F 0F 00 00 E5 E5 00 00 DC " + ;
"DC 00 00 26 26 00 00 C7 C7 00 00 D8 D8 00 00 CA " + ;
"CA 00 00 AA AA 00 00 76 76 00 00 A7 A7 00 00 82 " + ;
"82 00 00 3F 3F 00 00 D9 D9 00 00 5C 5C 00 00 92 " + ;
"92 00 00 6E 6E 00 00 44 44 00 00 62 62 00 00 15 " + ;
"15 00 00 71 71 00 00 E7 E7 00 00 34 34 00 00 F1 " + ;
"F1 00 00 3E 3E 00 00 F2 F2 00 00 77 77 00 00 F8 " + ;
"F8 00 00 8D 8D 00 00 47 47 00 00 D0 D0 00 00 17 " + ;
"17 00 00 6B 6B 00 00 4B 4B 00 00 CC CC 00 00 28 " + ;
"28 00 00 9A 9A 00 00 BF BF 00 00 32 32 00 00 B6 " + ;
"B6 00 00 87 87 00 00 97 97 00 00 63 63 00 00 74 " + ;
"74 00 00 12 12 00 00 BD BD 00 00 36 36 00 00 AC " + ;
"AC 00 00 70 70 00 00 B1 B1 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"64 65 00 00 00 64 65 00 00 1D 66 1C 00 00 67 68 " + ;
"00 00 0A 66 66 66 66 25 1F 69 66 6A 6B 6C 6D 25 " + ;
"3D 6E 3A 00 00 6F 70 6E 71 00 0A 72 00 00 00 00 " + ;
"06 07 00 00 00 06 07 00 00 55 56 26 00 00 4C 56 " + ;
"57 00 0F 58 59 59 59 06 34 0B 3E 21 5A 5B 11 5C " + ;
"5D 5E 5F 53 60 2B 61 62 63 61 0F 10 00 00 00 00 " + ;
"06 07 00 00 00 06 07 00 00 33 4A 4B 00 00 46 4C " + ;
"20 00 0F 10 00 00 00 00 4D 4E 4F 1E 50 51 11 0E " + ;
"00 00 52 3F 53 25 00 00 54 08 0F 10 00 00 00 00 " + ;
"06 07 00 00 00 06 07 00 27 12 42 43 1F 1C 44 45 " + ;
"46 00 0F 10 00 00 00 00 00 34 25 46 3B 3A 11 47 " + ;
"00 00 1A 48 3A 03 03 03 03 49 0F 10 00 00 00 00 " + ;
"06 03 03 03 03 03 07 00 32 33 00 33 32 34 35 00 " + ;
"36 1C 0F 10 00 00 00 00 37 38 00 00 39 3A 11 3B " + ;
"3C 00 3D 19 3E 3F 1F 00 40 41 0F 10 00 00 00 00 " + ;
"06 07 00 00 00 06 07 00 20 20 00 21 22 23 24 00 " + ;
"25 26 0F 10 00 00 00 00 27 28 29 2A 09 1D 11 2B " + ;
"15 0C 2C 2D 00 2E 2F 30 31 1C 0F 10 00 00 00 00 " + ;
"06 07 00 00 00 06 07 00 13 14 00 0D 15 16 17 00 " + ;
"18 19 0F 10 00 00 00 00 00 00 1A 1B 1C 00 11 12 " + ;
"17 1B 08 00 00 00 1D 1E 1F 00 0F 10 00 00 00 00 " + ;
"06 07 00 00 00 06 07 08 09 0A 00 00 0B 0C 00 00 " + ;
"0D 0E 0F 10 00 00 00 00 00 00 00 00 00 00 11 12 " + ;
"00 00 00 00 00 00 00 00 00 00 0F 10 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 00 00 00 00 " + ;
"00 00 05 00 00 00 00 00 00 00 00 00 00 00 00 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 00 00 00 00 " + ;
"05 00 00 00 00 00 00 00 00 00 00 00 00 00 05 00 " + ;
"00 00 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 00 00 00 00 " + ;
"00 00 05 00 00 00 00 00 00 00 00 00 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 00 00 00 00 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 " + ;
"05 05 05 05 05 05 05 05 05 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 04 04 04 04 04 " + ;
"04 04 04 04 04 04 04 04 04 04 04 04 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 00 00 00 00 00 01 00 00 00 00 00 00 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 00 00 00 00 00 00 00 00 01 00 00 00 01 00 00 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 00 00 00 00 00 00 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 03 03 03 03 03 " + ;
"03 03 03 03 03 03 03 03 03 03 03 03 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 02 02 02 02 02 " + ;
"02 02 02 02 02 02 02 02 02 02 02 02 01 00 00 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 " + ;
"01 01 01 01 01 01 01 01 01 01 01 01 01 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 "

* ======================= EOF of hwlbledt.prg ==================

