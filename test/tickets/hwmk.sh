#!/bin/bash
#
# $Id$
#
# Script building single application
# for HWGUI
#
# #######################################
# configure Harbour installation path
#export HB_ROOT=../../..
export HB_ROOT=$HOME/Harbour/core-master
# #######################################
export HRB_EXE=$HB_ROOT/bin/linux/gcc/harbour
# #######################################
# configure HWGUI installation path
#export HWGUI_ROOT=$HOME/hwgui
export HWGUI_ROOT=$HOME/svnwork/hwgui-code/hwgui
# #######################################
#
# Create file build_date.ch with build date
echo "#define BUILD_DATE "\"`date +"%d.%m.%Y"`\" 1> build_date.ch

if [ "$1" == "" ]; then
  echo "Usage: $0 <filename without extension .prg>"
  exit
fi
# remove file extension
FILENAME=$1
PGM_NAME="${FILENAME%.*}" 

if [ "x$HB_ROOT" = x ]; then
export HRB_BIN=/usr/local/bin
export HRB_INC=/usr/local/include/harbour
export HRB_LIB=/usr/local/lib/harbour
else
export HRB_BIN=$HB_ROOT/bin/linux/gcc
export HRB_INC=$HB_ROOT/include
export HRB_LIB=$HB_ROOT/lib/linux/gcc
fi


export SYSTEM_LIBS="-lm -lpcre"
export HARBOUR_LIBS="-lhbdebug -lhbvm -lhbrtl -lgtcgi -lhbdebug -lhblang -lhbrdd -lhbmacro -lhbpp -lrddntx -lrddcdx -lrddfpt -lhbsix -lhbcommon -lhbcpage -lgttrm"
export HWGUI_LIBS="-lhwgui -lprocmisc -lhbxml -lhwgdebug"

# export HWGUI_INC=../../include
# export HWGUI_LIB=../../lib
export HWGUI_INC=$HWGUI_ROOT/include
#export HWGUI_LIB=$HWGUI_ROOT/gtk/lib
export HWGUI_LIB=$HWGUI_ROOT/lib

# -w2 : too much warnings  -w0 : no warnungs 
$HRB_BIN/harbour $PGM_NAME -n -i$HRB_INC -i$HWGUI_INC -i../include -w0 -d__LINUX__ -d__GTK__ $2
gcc $PGM_NAME.c -o$PGM_NAME -I $HRB_INC -L $HRB_LIB -L $HWGUI_LIB -Wl,--start-group $HWGUI_LIBS $HARBOUR_LIBS -Wl,--end-group `pkg-config --cflags gtk+-2.0` `pkg-config gtk+-2.0 --libs` $SYSTEM_LIBS

# Remark:
# Bugfixing of error message "fmod@@GLIBC_2.2.5" :
# => the system libs must be at the end of die library list. (Variable SYSTEM_LIBS)
# See also ==> hwgui/samples/gtk_samples/build.sh

# ------------ EOF of hwmk.sh --------------------
