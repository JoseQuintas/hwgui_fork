@echo off
REM
REM make_mingwdll.bat
REM
REM $Id$
REM
REM Creates a dll with functions of qrcodegen.c
REM for usage with other compilers like 
REM Borland C not supportimg the
REM C99 standard.
REM 

gcc -Wall -std=c99 -O -shared qrencodedll.c -o qrcodegen.dll

REM =================== EOF of make_mingwdll.bat ========================
