#!/bin/bash
# Special for LINUXMint
export PWD=`pwd` 
# echo $PWD > pwd.txt
# lxterminal --geometry=80x25 -e "cd $PWD ; ./helloworld 1>&2 2>mist.txt"
gnome-terminal -- "$PWD/helloworld" 
# ./helloworld   # This does not work
# Use this for debugging (e.g. no start)
# ./log 1>&2 2>mist.txt
