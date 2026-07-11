*
* tstcombovals.prg
*
* $Id$
*
* 
* This test and demo program
* shows the correct usage of
* @ <x>,<y> GET COMBOBOX ...
* for presetting and storing 
* values of a combobox selection
* as string ready for storing
* in a ini file or database.
*
* 
* The new simple functions
* hwg_STRI2COMB() and
* hwg_CCOMB2STRI()
* helps to convert the combobox
* (numerical) values to string
* and opposite.
*
* Read and write of inifile parameters:
* Instructions see HWGUI function documentation
* of function Hwg_WriteIni() ==> Windows only.
* There is mentioned a multi platform solution
* to handle Windows like ini files
* with section and parameters.
*


#include "hwgui.ch"


FUNCTION MAIN
Local frm_test_combobox

LOCAL oLabel1, oCombobox1, oButton1, oButton2, oButton3
LOCAL acomboitems1
LOCAL lCancel, ccomboitems1,  cocomboitems1, ncomboval1,  ncomboold1

PUBLIC inipar_ADIFEXQRGMk
* The value may come with an extry in an inifile or a database
inipar_ADIFEXQRGMk := "Hz"

// Sample for reading a C value from inifile
// inipar_ADIFEXQRGMk := RDSTR_INI(cinifilename, "FREQUENCY", "ADIFEXQRGMk" , "MHz")

* the strategy with this variable (almost used in CLLOG)
* has the advantage, that the ESC key, the cross button
* or Alt+F4 is handled as "Cancel" and the
* modification(s) is/are dismissed.
* We think, that is user friendly.
lCancel := .T.

acomboitems1 := {"MHz", "kHz", "GHz", "Hz"} 

* Now convert the value delivered by ini file
* into a numerical value:
  ccomboitems1 := inipar_ADIFEXQRGMk
  ncomboval1 := hwg_STRI2COMB(ccomboitems1,acomboitems1)

* Remember previous value as Type N
  ncomboold1 := ncomboval1 

  
  INIT DIALOG frm_test_combobox TITLE "Test GET COMBOBOX" ;
    AT 254,240 SIZE 516,336 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 29,26 SAY oLabel1 CAPTION "Select a frequency range in the combobox"  SIZE 443,22

   * At first, the initialization of the combobox position
   * starts with element 1 = "MHz" of the ITEM array:
   @ 279,81 GET COMBOBOX oCombobox1 VAR ccomboitems1 ITEMS acomboitems1 SIZE 110,96
   * Be shure, that your command is written like this,
   * otherwise programm crashes with NOT EXPORTED METHOD SETITEM !   

   
   * Now preset to the value from ini file
    oCombobox1:Setitem(ncomboval1)
    oCombobox1:Refresh(ncomboval1)

   @ 42,155 BUTTON oButton3 CAPTION "Set Default"   SIZE 173,32 ;
        STYLE WS_TABSTOP+BS_FLAT ; 
        ON CLICK { || oCombobox1:Setitem( 1 ) ,  oCombobox1:Refresh( 1 ) }
     * Concatinate more default settings separated by ","
 
   @ 54,202 BUTTON oButton1 CAPTION "OK"   SIZE 156,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK { || lCancel := .F. , frm_test_combobox:Close() }

   @ 304,202 BUTTON oButton2 CAPTION "Cancel"   SIZE 130,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
       ON CLICK { || frm_test_combobox:Close() }


   ACTIVATE DIALOG frm_test_combobox
   
    * Store settings in inifile, if not cancelled
    IF .NOT. lCancel 
      * Because COMBOBOX comes as N values, convert them
      cocomboitems1 := hwg_CCOMB2STRI(ccomboitems1,acomboitems1 )
      * Now store cocomboitems1 into ini file
      * ...
      //  WRSTR_INI(cinifilename, "ADIF", "FREQUENCY"  , cocomboitems1 )
      * Update the PUBLIC variable with the selected value
      * (no need to reread the ini file after modification)
      //  inipar_ADIFEXQRGMk := cocomboitems1
      hwg_MsgInfo("New combobox value selected :" + cocomboitems1 )
    ELSE
      hwg_MsgInfo("Combobox seledtion cancelled, set old value: " + ;
      hwg_CCOMB2STRI(ncomboold1,acomboitems1 ) )
    ENDIF  

   
   
// RETURN frm_test_combobox:lresult

RETURN NIL





* ======================= EOF of tstcombovals.prg ========================
