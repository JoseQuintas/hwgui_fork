*
* testfilehex.prg
*
* Test program for for all modes of function
* hwg_HEX_DUMP()
*

#include "hwgui.ch"

FUNCTION MAIN
LOCAL cBinVal

cBinVal := CHR(0) + CHR(1) + CHR(2) + CHR(3)+ CHR(4)

hwg_MsgInfo(hwg_HEX_DUMP(cBinVal,1) ,"Hexdump mode = 1")
hwg_MsgInfo(hwg_HEX_DUMP(cBinVal,2,"cNewVar") ,"Hexdump mode = 2")
hwg_MsgInfo(hwg_HEX_DUMP(cBinVal,3) ,"Hexdump mode = 3")
hwg_MsgInfo(hwg_HEX_DUMP(cBinVal,4) ,"Hexdump mode = 4")
hwg_MsgInfo(hwg_HEX_DUMP(cBinVal,5) ,"Hexdump mode = 5")

RETURN NIL


* ===================== EOF of testfilehex.prg ===================================
