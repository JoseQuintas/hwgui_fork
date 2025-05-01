
  Readme File for printing adress labels with "hwlabel".
  By Wilfried Brunken, DF7BE
  Created July 2022.

  $Id$

  Deutsche Beschreibung in Datei "Readme_de.txt" !


Contents
--------

1.  Preface
1.1 Prerequisites
2.  The Label Editor
2.1 Design rules
3.  Sample program
4.  Build programs
5.  Additional information
6.  References
7.  Appendix


1. Preface
----------
"Label" is an important feature in business applications for
example to label envelopes of letters to customers.
In CLLOG [1] it is necessary for labelling QSL cards.
The label feature is supported by Harbour for console
applications and needs direct access to the printer port.
Also it is necessary, to write printer control sequences
only for your used printer model into the label file.
In some implementations, the printer control codes are
stored in a printer database, this is implemented in CLLOG [1].
So this strategy is outdated.

The label editor is almost implememented in Clipper
in the utility RL.EXE, in S'87 as LABEL.EXE.
You can find an open source implementation for a Harbour
console application in the application "CLLOG",
file "lbledit.prg" in directory "src".
Link to CLLOG [1] see chapter "Internet links"

"hwlabel" is the port of this feature to HWGUI by using the WinPrn class,
so it is ready for multi platform usage and independent from
the used printer model.


1.1 Prerequisites
-----------------

For using this module you need a Harbour release supporting
the codepage "CP858" for Euro currency sign. This codepage
supports latin for most western countries like codepages
CP 437 and CP850.

It is very easy to check for this:
Compile and run the following HWGUI sample:
hwgui\samples\demofunc.prg

Then press button "hwg_Has_Win_Euro_Support":
If the value "True" is returned, the used Harbour version is OK.
Otherwise you need to get the recent Harbour version.

On LINUX there must be the same prerequisite, because this
codepage is used for the coding in the label file.


2. The Label Editor
-------------------

The Label Editor utility is needed to create and edit label files.
This utility is a "designer" for labels.
Label files have the extension ".lbl" and a fixed size of 1034 bytes.
The source code for the label editor is found in file "hwlbledt.prg".


For compatibility to Clipper, the codepage for label files is CP858DE.
It is the same as CP850 with one exception:
The Euro currency sign is 0xD5 or CHR(213).
This is suitable for most western languages.
More codepage support is planned for future versions of HWLABEL.
CP850/CP858 is more compatible as the early used CP437 for multi language use.

The basic version of "hwlabel" supports the english (default) and german language.
Feel free to extend the source code of hwlabel with new languages.
You can send us the extended code via a new support ticket or E-mail.

The label editor contains a help function, with
references for parameters and contents.

You can insert the label editor in your own HWGUI application.
The instructions are found in the inline comment of hwlbledt.prg.

A console version of the label editor is also available as
"lbledit.prg", compile it with
hbmk2 lbledit.prg.

Also an additional advice:
The used codepages and language setting must be passed in the main program of the label editor:
FUNCTION hwlabel_lbledit(clangf,cCpLocWin,cCpLocLINUX,cCpLabel)
The description of these parameters and the default values can be found in the inline comments of
function "hwlabel_translcp()".


2.1 Design rules
----------------

1.) In the recent issue of the HWLABEL utility the length beetween labels across is not
    correct. This bug will bee fixed as soon as possible.
    We recommend to use only labels with one lane (Number of labels across = 1 ).

2.) The result of a contents line may not exceed the width of label.
    The output of the macro and function calls may be shorter than defined
    in the contents line, so if the result on the printer or the printer preview
    is OK to you, than you can ignore the following warning of the label editor
    finishing the contents edit:

Warning !
Length of line nn
could exceed the width of label.
Recent length is : nn


3. Sample program
-----------------

The sample database "customer.dbf" contains 1 record with typical
data for customer contact:
Title, Name, Street, Postcode, Town , State , Country , Account

A sample label file "sample.lbl" is used for print an
adress from the database "customer.dbf".


Der following sample call show, how to print out a label of the recent
database record redirected into a file:

   LABEL FORM (l_lbl);
      TO FILE (ctempoutfile) ;    && .txt
      RECORD RECNO()

Function reference for use in label file see Appendix, Table 3

Print preview of sample program see image file:
contrib\hwlabel\image\Hwlabel_Win PrView.png


4. Build programs
-----------------

You need two build calls for label editor and sample program:

MinGW32:
  hwmk.bat hwlbledt.prg
  hwmk.bat hwlblsample.prg

With the "hbmk2" utility (LINUX and Windows):
 hbmk2 hwlbledt.hbp
 hbmk2 hwlblsample.hbp



5. Additional information
-------------------------

You can integrate the HWLABEL feature with the label editor in your
own HWGUI application. Read the instructions in the inline comment line
of the source code files.

For the next issue of hwlabel:

- More than 1 lane (Number of labels across > 2)




6. References
-------------

  [1] Project "CLLOG":
      https://sourceforge.net/projects/cllog/

  [2] Spence, Rick (Co-Developer of Clipper):
       Clipper Programming Guide, Second Edition Version 5.
       Microtrend Books, Slawson Communication Inc., San Marcos, CA, 1991
       ISBN 0-915391-41-4


7. Appendix
-----------

Table 1:
--------

American standard label formats


 Bahnen  Zoll            mm       Breite Hoehe  l.Rand        horz.A vert.A. <== German description
         size in inch   in mm     width  height left margin

 1      3 1/2 x 15/16  88,9x23,8  35     5       0               1      0
 2      3 1/2 x 15/16  88,9x23,8  35     5       0               1      2
 3      3 1/2 x 15/16  88,9x23,8  35     5       0               1      2
 1      4 x 17/16      101,6x26,9 40     8       0               1      0
 3      3 2/10 x 11/12 81,3x23,3  32     5       0               1      2 (Cheshire)
 !                                                               !      !
 !                                                               !      v
 v                                                               v      spaces between labels
 number of labels across                                         lines between labels


 Table 2:
 --------

** structure of database customer.dbf ***
Last update 22 06 09

Data offset 290
Record size 156
Number of records 4

Number of fields 8
NAME        TYPE LEN DEC

TITLE       C    10
NAME        C    20
STREET      C    30
POSTCODE    C    10
TOWN        C    25
STATE       C    25
COUNTRY     C    25
ACCOUNT     N    10



Table 3:
--------

Functions for label printing
(Function reference for use in label file)

 Shortened functions for label printing and filter strings
 (saves space):

 FUNCTION   A                 && (C)  ALLTRIM(s)
 FUNCTION   S                 && (C)  SPACE(n)
 FUNCTION   P                 && (C)  PADRIGHT(s,n)
 FUNCTION   C                 && (C)  CHR(n)
 FUNCTION   R                 && (C)  REPLICATE(s,n)
 FUNCTION   T                 && (C)  TRANSFORM(s,p)
 FUNCTION   NOSKIP            && (C)  gibt ein Zeichen 255 aus, wenn leer


FUNCTION NOSKIP(e):

Returns CHR(255), not printable,
if e (a string) is empty.
Otherwise the value of e is returned
is passed.

Reason:
Lines defined in label file, but
left empty are not printed.
It seems, that this line is not
existing. This causes an
misfunction in the design,
the following lines are moved to top.


Table 4:
--------

Printer character sets:


 0   : ANSI               CP1252, ansi-0, iso8859-{1,15}
 1   : DEFAULT
 2   : SYMBOL
 77  : MAC
 128 : SHIFTJIS           CP932
 129 : HANGEUL            CP949, ksc5601.1987-0
       HANGUL
 130 : JOHAB              korean (johab) CP1361
 134 : GB2312             CP936, gb2312.1980-0
 136 : CHINESEBIG5        CP950, big5.et-0
 161 : GREEK              CP1253
 162 : TURKISH            CP1254, -iso8859-9
 163 : VIETNAMESE         CP1258
 177 : HEBREW             CP1255, -iso8859-8
 178 : ARABIC             CP1256, -iso8859-6
 186 : BALTIC             CP1257, -iso8859-13
 204 : RUSSIAN            CP1251, -iso8859-5
 222 : THAI               CP874,  -iso8859-11
 238 : EAST EUROPE        EE_CHARSET
 255 : OEM

 The number of the left column is the numerical value
 for method SetMode() of the HWinPrn class,
 parameter nCharset.


 Escape sequences of macro interpreter
 -------------------------------------

  The PUBLIC Variable "EC" stands for CHR(27) (Escape),
 saves space in the label file.

 So a function call is written like this:
  EC+"&SMA(); Small"


 Table 5:
 --------

Reference of set modes called by macro interpreter:

FUNCTION MDE(lElite, lCond, nLineInch, lBold, lItalic, lUnder, nLineMax , nCharset)  Call METHOD SetMode()
FUNCTION NCH(nChars)        Set Charset
FUNCTION DEF()              Default
FUNCTION SMA()              Small
FUNCTION SML()              Smaller
FUNCTION VSM()              Very small
FUNCTION E()                Print Euro currency sign

 Table 6:
 --------

Reference of printouts called by macro interpreter:
(only for internal use)

FUNCTION O_NEWLINE()        New line
FUNCTION O_PRTTXT(ctext)    PrintText(ctext)
FUNCTION O_NPG()            NextPage



 Internet links
 --------------

 See "6. References"



 Modification summary
 --------------------

  Date (YYYY-MM-DD)  SVN     Description
  ----------         ------- ----------------------------------------------------------------
  2022-07-04         r3095   Second issue with macro interpeter
  2022-06-16         r3079   First issue

================================= EOF of Readme.txt ================================================


