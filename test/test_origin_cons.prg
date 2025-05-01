*
* test_origin_cons.prg
*
* Test for origin path handling on
* Harbour console application
* (this is also realized in sample program
*   "samples\demofunc.prg")
*
* compile with:
* hbmk2 test_origin_cons.prg
*
* The following steps are done in this
* program:
* 1.) display the recent directory:
*     (use the absolute path to call this application in
*      a Windows console or LINUX/MacOS terminal )
* 2.) Get the origin path an name and display it
* 3.) extract the origin path and display it
* 4.) Change directory to it
* 5.) Display the directory where changed to
*
* Checked with following OS an compiler:
* - Windows: MinGW and BCC
* - LINUX  : GCC
* - MacOS  : GCC
*

FUNCTION MAIN
LOCAL coriginp, coriginchdir

? "Start directory is : " + PWD()


* Get the origin path and name
coriginp := hb_argV( 0 )
? "Origin path and name is : " + coriginp


* Change to origin directory
IF .NOT. EMPTY(coriginp)
coriginchdir := hwg_Dirname(coriginp)

? "Origin path is : " + coriginchdir

//ft_ChDir( coriginp )
hwg_CHDIR(coriginchdir)
ENDIF

? "Changed to directory : " + PWD()

WAIT "Quit: Press any key ==>"
RETURN NIL




* ================================================================= *
FUNCTION PWD()
* Returns the curent directory with trailing \ or /
* so you can add a file name after the returned value:
* fullpath := PWD() + "FILE.EXT"
* ================================================================= *

LOCAL oDir
#ifdef __PLATFORM__WINDOWS
  * Usage of hwg_CleanPathname() avoids C:\\
  oDir := hwg_CleanPathname(HB_curdrive() + ":\" + Curdir() + "\")
#else
  oDir := hwg_CleanPathname("/"+Curdir()+"/")
#endif

RETURN oDir

* ~~~~~ Copied functions from HWGUI source ~~~~~

* From source\gtk\hmisc.prg
FUNCTION hwg_Dirname( pFullpath )

   LOCAL nPosidirna , sFilePath , cseparator , sFullpath

   * avoid crash
   IF PCOUNT() == 0
      RETURN ""
   ENDIF
   IF EMPTY(pFullpath)
      RETURN ""
   ENDIF

   cseparator := hwg_GetDirSep()
   *  Reduce \\ to \  or // to /
   sFullpath := ALLTRIM(hwg_CleanPathname(pFullpath))

   * Search separator backwards
   nPosidirna := RAT(cseparator,sFullpath)

   IF nPosidirna == 1
      * Special case:  /name  or  \name
      *   is "root" ==> directory separator
      sFilePath := cseparator
   ELSE
      IF nPosidirna != 0
         sFilePath := SUBSTR(sFullpath,1,nPosidirna - 1)
      ELSE
         * Special case:
         * recent directory (only filename)
         * or only drive letter
         * for example C:name
         * ==> set directory with "cd".
         IF SUBSTR(sFullpath,2,1) == ":"
            * Only drive letter with ":" (for example C: )
            sFilePath := SUBSTR(sFullpath,1,2)
         ELSE
            sFilePath = "."
         ENDIF
      ENDIF
   ENDIF

   RETURN sFilePath

FUNCTION hwg_CleanPathname( pSwithdbl )

   LOCAL sSwithdbl , bready , cseparator

   * avoid crash
   IF PCOUNT() == 0
      RETURN ""
   ENDIF
   IF EMPTY(pSwithdbl)
      RETURN ""
   ENDIF
   cseparator = hwg_GetDirSep()
   bready := .F.
   sSwithdbl = ALLTRIM(pSwithdbl)
   DO WHILE .NOT. bready
      * Loop until
      * multi separators (for example "///") are reduced to "/"
      sSwithdbl := STRTRAN(sSwithdbl , cseparator + cseparator , cseparator)
      * Done, if // does not apear any more
      IF AT(cseparator + cseparator, sSwithdbl) == 0
         bready := .T.
      ENDIF
   ENDDO

   RETURN sSwithdbl

* From C:\hwgui\hwgui\source\common\procmisc\procs7.prg
FUNCTION hwg_GetDirSep()
* returns the directory seperator character OS dependant
#ifdef __PLATFORM__WINDOWS
 RETURN "\"
#else
 RETURN "/"
#endif


#pragma BEGINDUMP

#if defined(__linux__) || defined(__unix__)
#include <unistd.h>
#else
#ifdef __APPLE__
#include <unistd.h>
#else
#include <io.h>
#endif
#endif


#include "hbapi.h"
#include "hbapifs.h"

/* Copied from source\common\procmisc\cfuncs.c */
HB_FUNC( HWG_CHDIR )
{
   hb_retl( HB_ISCHAR( 1 ) && chdir( hb_parc( 1 ) ) );
}

#pragma ENDDUMP


* =============== EOF of test_origin_cons.prg ==================
