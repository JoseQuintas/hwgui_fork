
  $Id$

Extra information about HWGUI sample programs
=============================================

This directory contains additional information about
sample programs.
The information in this file is useful for the HWGUI user
and contains also reports about bugs or
to do's for port to GTK/LINUX.

It is recommended to delete files or information,
if the program is successfully ported or
a bug is fixed.
Then put the description about the way of fix or port as
inline comment into the source code,
if this information is helpful for the user.

The subdirectory "image" contains screenshots of
sample programs.


1.) propsh.prg:

    Solved at 2025-03-29
    Checked with MinGW and Borland C.

    Property sheet, freezes at hwg_PropertySheet(),
    the sheet is not visible.
    The property sheet feature is Windows only,
    so a special solution for LINUX/GTK is necessary.
    The resources are only build with the
    Borland C resource workshop, so
    the port of this resources is done.
    The line with hwg_PropertySheet() is deactived
    by commenting out and the two dialog windows
    are activated with ACTIVATE DIALOG in sequence
    to check the design of the Borland resources.
    The subdirectory contains 4 files with
    screen snapshot of the design,
    2 compiled with Borland, the other ones
    with MinGW and ported HWGUI commands.
     propsh_bcc_c1.png  propsh_bcc_c2.png
     propsh_mingw_c1.png  propsh_mingw_c2.png

    The recent sample program contains now the
    port of Borland resources to HWGUI commands,
    so the bugfixing process can be continued
    on all compilers, preferred is MinGW.
    The contents of the old rc file was preserved
    as inline comment.




2.) grid_5.prg
    Grid Editor (crashes, if click on button "Insert","Change","Delete")


3.) escrita.prg:
    This sample program is derived from the sample in
    directory "gtk_samples" with same name.
    It is an alternative for multi platform usage.
    The commands "TOOLBAR" and "TOOLBUTTON" are GTK only, so they are
    substituted by "PANEL" and "OWNERBUTTON".
    The behaviour on LINUX/GTK is preserved by usage
    of the compiler switch "#ifdef __GTK__".
    Compiling of this program on Windows
    and GTK/LINUX, you can see the diffences
    in design and behavior.


Some information for port to GTK/LINUX
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

buildpelles.prg:
    Port of this sample to GTK make no sense, because
    the Pelles C compiler is only for Windows.

- demogrid1.prg  grid_2.prg  grid_3.prg  grid_4.prg  grid_5.prg
     The grid feature is available with GTK4,
     first released in 2020. Port of HWGUI to GTK4 needed.

a.prg : Need for full port TO GTK:
       HWG_GETCURRENTDIR(), HMDICHILDWINDOW(), HRECT(),
       HWG_RECT()
       Program gtk_samples/a.prg is a reduced version:
       Removed calls of "Windows only" functions by
       compiler switch.
       HDATEPICKER() convert to multi platform substitute.

hello.prg : Need for full port TO GTK:
       HRICHEDIT(),
       HWG_RE_SETCHARFORMAT(), HWG_SETTABSIZE(), HWG_MSGTEMP(),
       HWG_GETEDITTEXT(), HWG_SETDLGITEMTEXT(), HWG_PROPERTYSHEET()
       State: removed calls of "Windows only" functions by
       compiler switch
       screenshots:
       Windows:
        samples/doc/image/Hello_InfoDlg_Win.png
        samples/doc/image/Hello_main_Win.png
       LINUX:
       The differences of design must be fixed,
       so that the GTK version of this sample is
       displayed in the correct way.
       Lot of extra information in the inline comments.
        samples/doc/image/Hello_GTK_main.png
        ==> this was the screenshot with the further design
            on Windows.

testbrw.prg:
Crash on GTK fixed,
(crashes with no PROPS2ARR at ENTER or click)
==>
Method Add Standard of HBITMAP class does not work,
so the image was delivered by hex dump.

HBROWSE class:
Obscure behavior on editable field "Age" need to fix !
The modified value not accepted.





List of sample programs with bugs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
(Handle it as a "TO-DO list")


grid_5.prg    (Windows only)
nice2.prg     (Windows only)
tab.prg
testbrw.prg
testchild.prg (Windows only) - movewd to test/samples/
testrtf.prg   (Windows only)


====================== EOF of Readme.txt =======================================



