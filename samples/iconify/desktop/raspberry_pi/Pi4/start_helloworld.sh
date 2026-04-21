#!/bin/bash
# export PWD=`pwd` 
# echo $PWD > pwd.txt
# lxterminal --geometry=80x25 -e "cd $PWD ; ./helloworld 1>&2 2>mist.txt" 
export LD_LIBRARY_PATH=:/home/logger/Harbour/core-master/lib/linux/gcc:/usr/local/lib
cd $HOME/hwgui_icon
./helloworld
# Use this for debugging (e.g. no start)
# ./helloworld 1>&2 2>mist.txt
