QR encode library ready for integration into HWGUI
--------------------------------------------------


"QR-Code-generator"


2025-02-07   DF7BE   Project "qrencode" now finished.
2025-02-01   DF7BE   Port of qrcodegenerator.c for non C99 standard compiler started.
                     The committed version is only ready for C99, be patient,
                     if the project "qrencode" is finished.  
2025-01-17   DF7BE   Added sample for bat generation of QR codes
2024-12-12   DF7BE   Corrections  
2022-09-07   DF7BE   First creation

Contents:

1.)     Copyright of this library
2.)     Installation instructions.
2.1)    Supported compiler
2.2)    Steps to install QR-Code-Generator
2.3)    Steps to build HWGUI interface module
2.4)    Test with sample program
2.5)    Final instructions
2.6)    Extra instructions for non C99 standard Compiler
2.6.1)  Borland C
2.7)    Integration of qrencode as static link into exe of your HWGUI application
3.)     Generate QR code by bat oder sh calls
4.)     File list
5.)     Further instructions




1.) Copyright of this library

"QR-Code-generator-master.zip"

Copyright (c) Project Nayuki. (MIT License)

The version in the "Files" section is tested with HWGUI.
Optional get recent version from:


https://www.nayuki.io/page/qr-code-generator-library

https://github.com/nayuki/QR-Code-generator

For file:
 stdbool.h
    Author    - Bill Chatfield
    Copyright - You are free to use for any purpose except illegal acts

The QR code was returned as pure text and 
it is converted to a bitmap with extra HWGUI functions.
See format description in 
hwgdoc_functions.html, "QR code functions" ==> "Format description".


Now the modified code for non C99 standard support compiler also 
found in the HWGUI repository.
So no DLL is needed and the feature can be now statically linked
into a HWGUI program.
Compile all needed components to integrate the QR encoding feature
in  a few steps. 


2.) Installation instructions.

2.1) Supported compiler

At this time only the following compiler are supported:
- MinGW32
- MinGW64 (also with Msys2 environment)
- GTK/LINUX and MacOS with gcc
- Borland C, Watcom C and Pelles C under construction. 
- Borland C with DLL, see extra instructions
  (may be run with other Windows C compiler, optional)
- Microsoft Visual C, tested with 2022 release.  


Build scripts for other compilers are delivered 
as soon as possible.

 
2.2) Steps to install QR-Code-generator
 
- On Windows, start path script concerning the used compiler,
  for example (for MingW 32):
  pfad.bat
 
- make command reachable ?
  make --version
  GNU Make 3.81
  Copyright (C) 2006  Free Software Foundation, Inc.
  This is free software; see the source for copying conditions.
  There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
  PARTICULAR PURPOSE.

  If not, see HWGUI installation instruction for Windows.
  
- Compile Harbour and HWGUI with the desired compiler.  


2.3) Steps to build all programs and libraries

     - Change to HWGUI directory "contrib/qrencode"
     - build.bat or LINUX/MacOS: ./build.sh
     - Check, that all libraries for the HWGUI interface module
       are present, they are created in the HWGUI "lib" directory:
       "libqrcodegen.<ext>"
       "libhbqrencode.<ext>"

       <ext>: a, or lib or ? (depends of the used compiler)

2.4) Test with sample program
   
     cd samples
     hbmk2 qrencode.hbp
     qrencode.exe or ./qrencode
     Press button "Test":
     At first, the size of the QR code image is displayed, press "OK".
     Read the generated QR code with the smart (mobile) phone,
     the HWGUI project site must be opened.
     Quit by "OK", if ready.
     A second run with another QR code follows.
     The "Enter Text" allows to enter a text for generation of
     a QR code.
     On Windows, the non ASCII characters are translated to UTF-8.

    

2.5) Final instructions

Be shure, that the following options are inserted in 
the *.hbp file or Makefile of your application:

-L../lib (or path to HWGUI library directory)

-lqrcodegen
-lhbqrencode

Copy also the generated libraries and the header file
to reach the path's by compile or running task.


2.6) Extra instructions for non C99 standard compiler

    In this case, the library "contrib\qrencode\qrcodegenerator.c"
    of the original archive
    cannot be compiled with the compiler not supporting
    the C99 standard.
    In the HWGUI repository, qrencode.c and qrencode.h
    are modified and tested with non C99 C compilers.

    Alternative method is the the usage of a DLL (qrcodegen.dll)
    is another way to get a running QR code generator.
    The ready to use DLL (compiled with MinGW32)
    can be downloaded from the files section of
    the HWGUI project site a sourceforge.net.

    The sample program "qrencodedll.prg"
    demonstrates the usage of the DLL.

    
2.6.1) Borland C

   After the port of "qrcodegenerator.c" is done,
   you can compile it also with Borland C.
   
   Nevertheless, if you want to use an external DLL,
   follow these instructions:   

   - Download the DLL (location see above)
   - Set environment for Borland C, for example:
      C:\hwgui\hwgui-bcc\samples\dev\env\pfad_bc.bat 
   - Compile the sample qrencodedll.prg:
      hbmk2 qrencodedll.hbp
   - Copy the DLL into the sample directory	  
     and run the sample program.
   - Copy the DLL into the directory running your HWGUI application.


Some restrictions of Borland C:

Set variable declarations only at begin of a function:

 void xyz()
 {
   char c;
   int i,j;
   ...
   <code>
   i = 0
   j = 1
   c = 0   
   ...
 }

Not allowed:
  
 Variable declaration within a for statement: 
 for (int i = 0; i < textLen; i++)
 
 so say:
 
 int i;
 
 for (i = 0; i < textLen; i++)

Enumerations are not allowed as function parameters:
(simple example)

enum Ex{
  VAL_1 = 0,
  VAL_2,
  VAL_3
};

void foo(Ex e){   /* or "enum Ex e" */
  switch(e){
  case VAL_1: ... break;
  case VAL_2: ... break;
  case VAL_3: ... break;
  }
}

int main(){
  foo(VAL_2);
}

fires 2 error messages:
Error E2238 ..\include\qrcodegen.h 62: Multiple declaration for 'qrcodegen_Ecc'
Error E2344 ..\include\qrcodegen.h 62: Earlier declaration of 'qrcodegen_Ecc'

bool qrcodegen_encodeText(const char *text, uint8_t tempBuffer[], uint8_t qrcode[],
     enum qrcodegen_Ecc ecl, int minVersion, int maxVersion, enum qrcodegen_Mask mask,
     bool boostEcl);

Solution:
 
Check for type of enumeration (here: int)

and say very simple:

bool qrcodegen_encodeText(const char *text, uint8_t tempBuffer[], uint8_t qrcode[],
     int ecl, int minVersion, int maxVersion, int mask, bool boostEcl);

Ignore warning:
Warning W8084 yyy nnn: Suggest parentheses to clarify precedence in function xxx
 
All the modifications are also tested with other compilers
(see prerequisites) 

2.7) Integration of qrencode as static link into exe of your HWGUI application


As alternative methode for linking with the libraries compiled in
contrib/qrencode, you can copy and compile the source code
together with your HWGUI program (as inline C compile by Harbour). 
Follow these instructions:

- Copy qrcodegen.h and "stdbool.h" into your local include directory.
  Be shure, that they are reachable by -I compiler option
- Copy files
    qrcodegenerator.c
    libqrencode.prg
    qrencode.c
  into your local source directory
- Rename it to qrcodegenerator.prg
- Insert at beginning of qrcodegenerator.prg:
  #pragma BEGINDUMP
  and at end:
  #pragma ENDDUMP
- Rename qrencode.c to qrencode.prg and insert the #pragma
  statements also here.  
- Insert qrcodegenerator.prg and qrencode.prg in your local hbp file.
  Here the -I compiler option must be inserted for
  qrcodegen.h.
- Look into sample program samples\qrencode.prg for how to insert the
  function calls into your application. 
  The main function is here HWG_QRENCODE().
  At your option, use HB_TRANSLATE() on Windows
  to convert the Windows charset to UTF-8.
  Not necessary, if the text to be converted into
  QR code is pure ASCII.  
 
Important:
Don't forget to add the Copyright notice of
the QR code generator into 
your program documentation
and respect the copyright conditions.


   
3.) Generate QR code by bat oder sh calls

  The file libqrcode_hb.prg is a collection of HWGUI
  functions needed to make the QR encode feature available
  for Harbour console programs.

  The (sample) program hb_qrencode.prg is a full application to
  generate QR codes from command line.


   Scripts build.bat or build.sh builds now also the sample program.

   Now start the console program
  
   Synopsis:
   
   hb_qrencode <text convert to QR code> , <bitmap file name with QRcode,
     add extension ".bmp"> [,<zoom factor>]

   Default value for zoom factor is 3
 
   Sample calls:
   hb_qrencode "https://sourceforge.net/projects/hwgui" hwgui_sf.bmp
   hb_qrencode "https://www.darc.de" darc.bmp
   
   For LINUX and MacOS say ./hb_qrencode !
 
   Trouble with Euro currency sign:
   (Windows only)
   * Euro = 3f (63 dec) = ?
   ==> Instead of the Euro sign a "?" appears.
   It seems, that is a problem by passing the character €
   on the command line interface.
   The Euro sign is passed and visible, but not passed to the program.
   See image:
   command_with_Euro.png
   (in subdirectory "img")
   On LINUX, no trouble to write any UTF-8 into the QR code.


4.) File list

 build.bat                  Build all libraries and sample programs for QR encode uitility              
 hb_qrencode.hbp            Compile hb_qrencode.prg
 hb_qrencode.prg            Sample program creating QR codes by Harbour console program (for BAT purposes)
 img\command_with_Euro.png  Image shows the not accepted Euro currency sign on Windows command line.
 include\qrcodegen.h        The include file for qrcodegenerator.c
 libqrcode_hb.prg           Collection of functions encoding QR codes in a
                            Harbour console application (for example for batch usage)
 libqrencode.prg            Collection of functions encoding QR codes (if not implemented in other HWGUI modules)
 Makefile.mingw             Original Makefile from Project Nayuki modified for MinGW
 make_mingwdll.bat          Creates a dll with functions of qrcodegen.c
 qrencode.c                 C level QR encode functions, interface module to HWGUI
 qrencode.hbp               Makefile for hbmk2 utility to compile qrencode.c to a static library  
 qrencodedll.c              C code with special modification for build a DLL creating
                            a text file with the QRCode.
 qrcodegenerator.c          C code for library encoding to QR code as text image,
                            modified for also non C99 standard compiler.
 qrcodegenerator.hbp        Build static library from qrcodegenerator.c (not with Makefile.mingw)
 stdbool.h                  Substitute for BOOL types of C99 standard for other compiler (for example Borland C)
 Readme.txt                 This file containing installation instructions and more descriptions.

 
 
5.) Further instructions

===================================================================
Important !
Now the QR-Code-Generator is part of the HWGUI contrib source.
Need not to extract it from the original archive, because it is
modified for all compilers supporting HWGUI.
A lot of modification are needed for old Windows compiler like
Borland C, but the GCC or MinGW have not problems to understand
the modified code.
But if a new release of the QR code generator is published, feel free to compile it with
a C99 standard compiler.
If we have time, we insert all new code differences into the existing files. 

 Extract the archive "QR-Code-generator-master.zip" in an temporary directory.

-  Change to build directory:
    cd QR-Code-generator-master
    cd c
  
- All Windows platforms:
   Copy the desired build script from HWGUI environment
   in directory "contrib\qrencode" into the temporary directory
   above.
   For example: Makefile.mingw

- Start build process:
  
   MinGW: make -f Makefile.mingw *)
   LINUX: make (usage of the Makefile delivered by archive of QR code generator)
  
   *) Build script only builds  the library and the demo program in C, but not the
    sample and demo program of HWGUI.  

- Copy header file "qrcodegen.h" to contrib\qrencode\include 
  
- copy library "libqrcodegen.a" or "libqrcodegen.lib"
   to the HWGUI "lib" directory.
 

   The file extension depends of the used compiler.

- Optional: the temporary build directory is not needed any more,
   delete it.
 
For archive:   
   
Steps to build HWGUI interface module
     - Change to HWGUI directory "contrib/qrencode"
     - hbmk2 qrencode.hbp
     - Check, that the library for the HWGUI interface module
       "libqrcodegen.<ext> "is created in the HWGUI "lib" directory.
       <ext>: a, or lib or ? (depends of the used compiler)   

=============== EOF of Readme.txt ======================== 
