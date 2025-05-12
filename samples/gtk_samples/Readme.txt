List of HWGUI sample programs for GTK
=====================================

$Id$

Created by DF7BE

1.) Learn more about HWGUI with this sample programs.
    Read also instructions in file (WinAPI):
     samples\Readme.txt


2.) Build-Scripts:
     - build.sh      LINUX
     - bldgw.bat     old version for MinGW, better use hwmingnw.bat !
     - hwmingnw.bat  GTK/Windows (Cross development environment,
       read instructions for use in file samples\dev\MingW-GTK\Readme.txt)
     - sample.hbp    Sample skript for hbmk2 utility, modify to your own needs
                     (works for Windows and LINUX)

3.) List of GTK sample programs

    The list contains only the main programs.
    Some of the programs are also ready for WinAPI, they are marked in the WinAPI column with "Y".

    Some samples could not be compiled or are crashing, hope that we can fix the bugs if we have time,
    see remarks in "Purpose" column, marked with # sign (Test with MingW, recent Harbour Code snapshot).


 Sample program     GTK/LINUX GTK/Win  WinAPI    Purpose
 =================  ========= =======  ======    ===================


a.prg    2)         Y         Y        N         Some HWGUI basics (Open DBF's, GET's, ...)
dbview.prg          Y         Y        N         DBF access (Browse, Indexing, Codepages, Structure, ... )
escrita.prg 3)      Y         Y        N         "Teste da Acentuação", tool buttons with bitmaps
example.prg         Y         Y        Y         HFormTmpl: Load forms from xml file.
graph.prg           Y         Y        Y         Paint graphs (Sinus, Bar diagram)
hexbincnt.prg  11)  Y         Y        Y         Handling of binary resources with hex values.
icons.prg    5)     Y         Y        Y      #  Icons and background bitmaps
progbars.prg 12)    Y         Y        Y         Progress bar
pseudocm.prg        Y         Y        Y         Pseudo context menu
qoutcolor.prg       Y         N        N         Sample to colorize qout()
stretch.prg         Y         Y        Y         Sample for resizing bitmaps (background), some bugs (as test program)
testget2.prg        Y         Y        Y         Get system: several edit fields (date, password, ...), time display
winprn.prg   1)     Y         N        Y         Printing via Windows GDI Interface

1)  Because recent computer systems have no printer interfaces any more, it is strictly recommended,
    to use the Winprn class for Windows and Linux/GTK for all printing actions. The Winprn class contains a good
    print preview dialog. If you have a valid printer driver for your printer model installed,
    your printing job is done easy (printer connection via USB or LAN).

2)  a.prg: Browse problem with Char field

3)  escrita.prg: Text in toolbuttons not visible

5)  Crashes at calling DIALOG, will be fixed as soon as possible.

11) Read more about the handling of hex value resources in file "utils/bincnt/Readme.txt".

12) progbars.prg: Little modifications for WinAPI needed (use compiler switch "#ifdef __GTK__").
    Extra sample program with same filename in directory "samples" for WinAPI.

    So that the progress window is not hidden by the main window and the focus will
    set to it if progress bar is increased by steps, it is necessary to install the
    command "wmctrl" with "sudo apt install wmctrl" as system adminstrator.
    It no problem to switch the main windows to full screen display.


* =================== EOF of Readme.txt ========================


