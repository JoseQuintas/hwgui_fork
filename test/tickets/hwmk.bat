@echo off
REM
REM hwmk2.bat
REM $Id$
REM Batch file compiling single prg with HWGUI
REM
REM Parameters:
REM %1: Name of prg files (with or without extension)
REM ================================
REM remove file extension
SET PRGNAME=%~n1
REM === Modify to your own needs ===
SET HWGUI_INSTALL=C:\hwgui\hwgui
REM SET MINGW=C:\hmg.3.3.1\MINGW
SET MINGW=C:\MINGW32
REM SET HRB_DIR=C:\hmg.3.3.1\HARBOUR
REM SET HRB_LIB_DIR=%HRB_DIR%\lib\win\mingw
REM For cross development environment on Windows
SET GTK_DIR=C:\gtk
REM ================================
REM Generate build date
echo #define BUILD_DATE "%DATE%" > build_date.ch
REM


REM compile with Harbour and HWGUI 


hbmk2 %PRGNAME%.prg -I%HWGUI_INSTALL%\include -L%HWGUI_INSTALL%\lib -lgdiplus -lhwgui -lprocmisc -lhbxml -lhwgdebug -gui
if errorlevel 1 goto abbruch
GOTO ENDE

:ABBRUCH
REM Abort
echo === Error creating %PRGNAME%.EXE ===
echo ... Abort

:ENDE

REM ---- EOF of hwmk2.bat ----
