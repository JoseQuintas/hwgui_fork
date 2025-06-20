#!/bin/bash
#
# $Id$
#
# This script installs a workaround for missing sys/io.h
# (by DF7BE) 
#
# This include file is part of old versions of GLIBC and is now removed.
# Instead, the file <unistd.h> must be included.
#
# The origin location of include files.
SYS_INCLUDEDIR=/usr/include
# 
# On some *NIX sytems the location may be here,
# so activate this setting.
# SYS_INCLUDEDIR=/usr/local/include
#
# It checks the existance of sys/io.h,
# if not, it copies the unistd.h as io.h
# into the HWGUI directory include/sys
#  into the HWGUI directory include/sys,
# so no modification of HWGUI build scripts
# are necessary.
# For more information see the installation instructions
# of HWGUI.
if [ ! -d include/sys ]
 then
   mkdir -p include/sys
 fi 
if [ ! -f $SYS_INCLUDEDIR/sys/io.h ]
  then
  if [ ! -f include/sys/io.h ]
  then
   echo "Start workaround ..."
   cp $SYS_INCLUDEDIR/unistd.h include/sys/io.h
   if [ $? -ne 0 ]
   then
     echo "Error"
   else  
     echo "Done"
   fi
   else
    echo "OK: Nothing to do !"
   fi
else
 echo "OK: sys/io.h on system found"
fi

# ===================== EOF of missingioh.sh ===============================

