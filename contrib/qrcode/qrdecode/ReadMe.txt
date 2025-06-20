ReadMe file for QR code and EAN bar codes decoding
 from HWGUI program by using a camera.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
 
History: 

2025-06-20  DF7BE  Support for ZBarcam on Raspberry Pi 400
2025-04-19  DF7BE  Project moved from contrib/qrdecode to contrib/qrcode/qrdecode by Jose M. Quintas
2025-01-14  DF7BE  Project qrdecode completed
2025-01-13  DF7BE  Now running on MacOS by using shell script.
2025-01-13  DF7BE  Also instruction for LINUXMint
2025-01-07  DF7BE  First tries with MacOS 
2025-01-03  DF7BE  LINUX now running, continue with MacOS 
2025-01-02  DF7BE  Error on LINUX need to be fixed   
2024-12-29  DF7BE  First creation


Contents:

1. Prerequisites
2. HWGUI test program
Appendix 1: Installation instructions for MacOS
Appendix 2: Compile ZBar 0.10 on Raspberry Pi 400




Supported platforms:
- Windows 10/11 (32 bit)
- LINUX (Ubuntu/LINUXMint)
- MacOS
- Raspberry Pi 400


1. Prerequisites
----------------

1.1. A full operating HWGUI system on your computer

1.2. A working computer camera
     Check it with your camera app delivered by the
     operating system.
     If not, you find many troubleshooting procedures in
     the internet (camera device driver update, device manager, ...) 
     Also be shure, that the camera is not used by another
     application.
     Usually, a little LED nearby the lens indicates, that
     the camera is activated.
     On LINUXMint, the camera application must be installed by
      sudo apt-get install cheese
     for pre camera test.

1.3  Install ZBar

     Get source code from
     https://sourceforge.net/projects/zbar
     
     Source code archives with bugfixes are available at Debian:
     https://packages.debian.org/source/sid/zbar
     (zbar_0.23.93.orig.tar.gz)
     but the the zbarcam app crashes on LINUX (see above).

     Optional these files are also available in the "Files"
     section of the HWGUI project site.

     Windows:

     The easy way is to install the prebuild setup
     for ZBar. 
     (File name is zbar-0.10-setup.exe , tested with Windows 10 and 11)
    
     LINUX:
     
     Tested under Ubuntu 24.04.1 LTS

     
     At first, install following packges:
     sudo apt-get install libv4l-utils
     sudo apt-get install libv4l-dev
     sudo ln -s /usr/include/libv4l1-videodev.h /usr/include/linux/videodev.h 
     sudo apt-get install imagemagick
     sudo apt-get install python-is-python3
     Install optional: 
     sudo apt-get install libzbar-dev
     sudo apt-get install zbarcam-gtk
     sudo apt-get install zbar-tools
     sudo apt-get install python3-zbar
     
 
     
     The zbarcam-gtk from installed package runs without error,
     but need to redirect result into a file
     (displayed in camera window)
     The "zbarcam" program from package crashes with
     "Error:
     zbarcam
      WARNING: no compatible input to output format
      ...trying again with output disabled
      ERROR: zbar processor in zbar_processor_init():
      unsupported request: no compatible image format
      "
      So need to compile the zbarcam program with patch (all LINUX).
      
      On LINUXMint the following steps for prerequites are enough:
        sudo apt-get install libv4l-dev
        sudo ln -s /usr/include/libv4l1-videodev.h /usr/include/linux/videodev.h 
        sudo apt-get install imagemagick      
      
 
     ~~~~ How to compile ZBar from source ~~~~
     - Create compile directory:
       mkdir zbar
     - Extract the archive into 
        $HOME/zbar/zbar-0.10
     - Read generic installation instructions in file INSTALL
     - Copy the patched file "v4l2.c" from contrib/qrcode/qrdecode to
       "~/zbar/zbar-0.10/zbar/video". 
     - export CFLAGS=""
     - ./configure --prefix=$HOME/local --without-imagemagick --without-python -without-qt
     - make check
     - make
     - make install
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      
     zbarcam-gtk runs at it best, the result is displayed in the
     camera window. But not written in file for processing afterwards. 

      
     MacOS:
  
     The installation and usage on MacOS  is more complicated.
     The reason: zbarcam is not available on MacOS,
     but instead you can use imagesnap and then combine it with zbarimg (from zbar package).
     See Appendix 1 for detailed installation and usage information. 



     Rasberry Pi 400:
     
     (June 2025)
     
     A ready to install package for using an USB camera is available.
     Older revisions of the Pi needed an extra camera module, this
     is not tested here.
     
     In the appendix 2 instructions for compiling the ZBar from source is also available.
     This can also be helpfull instlling ZBar on ther operating systems.
     
     Install the package:
     sudo apt install zbar-tools
     
     The command "zbarcam" must be rechable in the PATH.
     
     In old versions a command "rpicam-hello" is available for
     testing the camera, but not for 400.
     
     So plug in the camera into the USB port and look for
     existing device file:
     ls -l /dev/video*
       /dev/video0
     
     Now start ZBar by
      zbarcam
     
     and try to scan some QR codes.
     Look for response in the terminal window.
      

1.4 Pre-check of Zbar
    Open a console or terminal and insert the following command:
    Windows:
     "C:\Program Files (x86)\Zbar\bin\zbarcam.exe"
    (with "").
    LINUX: 
      cd ~/local/bin
     ./zbarcam

    First the splash window of ZBar appeared, then a window
    shows the camera image.
    Take now QR codes or bar codes.
    If a QR or bar code is detected, the code image is
    marked by red frame. If the code is successfully decoded,
    the color of the frame is turned to green.
    Also a short beep is sounded.
    The result text is sent to the console or terminal.
    You can take more than one QR or bar code in one session
    (mixed codes possible).
    If finished, close the Zbar program by clicking to the "X" field.
    Now the output file (here STDIN, later the redirected output
    file of the hwg_RunConsoleApp() function call (2nd parameter),
    so all results can be seen or processed.
    

    Get help info by typing:
     zbarcam --help  
    (if zbarcam is in PATH, otherwise add full path in .profile)
    
    

2. HWGUI test program

2.1 Compile the sample program

    CD to directory contrib\qrcode\qrdecode
    and enter:
     hbmk2 qrdecode.hbp

2.2 Run the sample program
      qrdecode.exe
    or
      ./qrdecode
 
 
    Start the scan process by pressing the "Scan" button.
    The behavior is described in chapter 1.4
    If finished, the output file "output.txt" is closed
    and contains the complete result.

2.3 Your job

    Process the result by reading the output file
    line by line in your HWGUI app to your own needs.
    The following HWGUI function helps to read
    a text file with the result of the scan:
    hwg_RdLn().
    It has as autodetect for line endings
    for Windows/DOS, UNIX/LINUX and MacOS. 

3. Output format:

   Every scan operation starts with a string
   for example "QR-Code:" or "EAN-13:".
   QR codes may be have more than one line, they are
   delimited by the line ending of the operating system.
   For every decoded issue the ASCII character BEL = 0x07
   is appended at the end of the output file 
   (for every beep).

   For example:
QR-Code:TO:DF7BE/M
VIA:
FRM:DK0YLO
QR-Code:OPERATOR;QSO_DATE;TIME_ON;BAND;MODE;RST_SENT;QSL_RCVD;
DK0YLO;11.07.17;17:23;70CM;FM;59;PSE;

EAN-13:4190784301991
QR-Code:https://

   
   Both QR-Codes at top: Sample printed on a QSL card.
   The 1st line is a header to explain the data fields.
   The 2nd line is data of a radio contact in CSV format +
   a blank line.
   
   
Have fun decoding lot's of QR or bar codes in your HWGUI
application.

73 es 55 de
DF7BE, Wilfried    

Appendix:
########

Appendix 1: Installation instructions for MacOS
--------------------------------------------------------------
1.) Install zbar:
 To install zbar, paste this in macOS terminal after installing macports
https://www.macports.org/install.php

The installations needs some time do get and install all dependencies.

sudo port install zbar
Password:
Warning: port definitions are more than two weeks old, consider updating them by running 'port selfupdate'.
--->  Computing dependencies for zbar
The following dependencies will be installed: 
 ImageMagick
...
Continue? [Y/n]: y
...
--->  Attempting to fetch zbar-0.23.92_1.darwin_23.x86_64.tbz2.rmd160 from https://nue.de.packages.macports.org/zbar
--->  Installing zbar @0.23.92_1
--->  Activating zbar @0.23.92_1
--->  Cleaning zbar
--->  Updating database of binaries
--->  Scanning binaries for linking errors
--->  No broken files found.                             
--->  No broken ports found.
--->  Some of the ports you installed have notes:
  cmake has the following notes:
    The CMake GUI and Docs are now provided as subports 'cmake-gui' and
    'cmake-docs', respectively.
  libheif has the following notes:
    Support for rav1e now disabled by default; enable via +rav1e
  libidn has the following notes:
    GNU libidn2 is the successor of GNU libidn. It comes with IDNA 2008 and TR46
    implementations and also provides a compatibility layer for GNU libidn.
  libpsl has the following notes:
    libpsl API documentation is provided by the libpsl-docs port.
    
   
   
To see what files were installed by zbar, run:
port contents zbar 
To later upgrade zbar, run:
sudo port selfupdate && sudo port upgrade zbar 

The needed program "zbarcam" is not installed, so compile so see:
https://apple.stackexchange.com/questions/403022/is-it-possible-to-read-qr-code-on-macos-using-webcam
The solution is:
zbarcam is not available on MacOS, but instead you can use imagesnap and then combine it with zbarimg (from zbar package).

2.) Install imagesnap

Instructions from
https://macappstore.org/imagesnap/

Three steps , insert this commands by copy and paste it into terminal:
  1.) /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  2.) echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  3.) brew install imagesnap

3.) Get snapashot and decode the QR code:

3.1.) Check camera  position
- Start a camera app, for example "FaceTime"
- Hold the document with the QR code in front to the camera and be shure that it is complete visible and focused.
  (don't matter about, that the image in this windows is mirrored).
- Hold the in the realized position 
- Terminate the camera app, so that the camera is not locked any more 

3.2) Test a QR code:
The simplest possible solution would be:

imagesnap -w 1 snap.jpg
zbarimg -1 --raw -q -Sbinary snap.jpg
Look for message in terminal (for example):
Capturing image from device "FaceTime HD-Kamera (integriert)"...snap.jpg

Advice: the default file name of image is: snapshot.jpg

Shell script (for test).
You can automate it to wait for first successful reading:
./qrdecode_mac.sh <number of tries>

Be shure, that this script file has execute permission,
other set with
chmod 755 qrdecode_mac.sh
This command is also executed in the HWGUI sample program,
so no "permission denied" message should not be appeared.

Parameter <number of tries> limits the number of tries
to read a valid QR code and to avoid an endeless loop.
We suggest to start a test with 10 tries.
You can increase the number of tries in the HWGUI sample program.

The script terminates, if the QR or bar code is successfully read.

The difference:
On WIndows and LINUX the decode action is closed, if the
"X" icon is pressed. There mutliple decode actions are possible
and the results are collected in the output file. 
Here on MacOS, only one decode session per start by the "Scan"
button of the sample program is possible. 
The action stops with successfull scan.
If you want to scan more than one OR or bar code,
add a loop around the decoding action.
  

3.3) Compile HWGUI sample program

See LINUX instructions.

You can modify the number of tries in the "ccommand"
line of the source code to your own needs.

...
#ifdef ___MACOSX___
 lnmodal := .F.
  ccommand := "./qrdecode_mac.sh 10"
  * Set execute permission
  hwg_RunConsoleApp("chmod 755 qrdecode_mac.sh")  
  rc := hwg_RunConsoleApp(ccommand,outfilename)
 ... 
  
  
Additional information:
------------------------------
 
Ready to go script, using the same mechanism, you can find HERE.
==> https://github.com/rynkowsg/scripts/blob/master/macos/scan-qrcode.sh

At the top of the file you can find usage info:

#
# EXAMPLES:
#
#  Just print the QR code
#
#    ./scan-qrcode.sh
#
#  Copy QR code to clipboard
#
#    ./scan-qrcode.sh | pbcopy
#
#  Import paper secret key from QR code:
#
#    ./scan-qrcode.sh | paperkey --pubring public-key.asc | gpg --import
#


Appendix 2: Compile ZBar 0.10 on Raspberry Pi 400
-------------------------------------------------

The problem is, that the conigure script (too old) does not support
the ARM processors, so use the automake feature to create a new one.

Extract the source code archive with patch "v4l2.c",
concerning the instructions for LINUX

Copy header file
contrib/qrcode/qrdecode/raspbian/config.h
to include directory of zbar

# Be shure, that the automake package in installed,
otherwise:
sudo apt-get automake

# Create aclocal.m4
aclocal

# create confgure
autoconf

# create include/config.h.in
# autoheader
# Skip this step, because of errors
# the config.h is not created.
# See copy of this file in the instructions above.

# create Makefile.in
automake
#
./configure --build=arm --prefix=$HOME/local --without-imagemagick --without-python -without-qt

make -k check
make -k

Both make's ended with errors, but the needed program
"zbarcam" is created in diretory zbar

Copy zbarcam to $HOME/local/bin

Plug the USB camera into an open USB port and check
for existing device file:

ls -l /dev/video*
crw-rw----+ 1 root video 81, 0 Jun 20 15:10 /dev/video0


Start the zbarcam program
$HOME/local/bin/zbarcam
and try to decode some QR codes.
The result is displayed in the terminal windows.

if the message 
  unsupported request: no compatible image format
apprears, the patch "v4l2.c" was forgotten.

So patch the source and repeat both make's.

Compile the HWGUI sample program:

Modify the line at about 95 of contrib/qrcode/qrdecode/qrdecode.prg:

* All other LINUXe
 lnmodal := .F.
  ccommand := "~/local/bin/zbarcam" 
  
to

 ccommand := "zbarcam"
 
 if zbarcam can be reached by PATH.

================= EOF of ReadMe.txt =======================
