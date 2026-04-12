#!/bin/bash
#lxterminal --geometry=80x25  --working-directory=/home/afu/hwgui_icon -e "/home/afu/hwgui_icon/helloworld"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/afu/Harbour/core-master/lib/linux/gcc:/home/afu/local/lib
cd /home/afu/hwgui_icon 
lxterminal - e ./helloworld
# Call this for getting an error protokoll
# 1>mist.txt 2>&1
#lxterminal -e "$HOME/Desktop/term_apps/helloworld.sh"

