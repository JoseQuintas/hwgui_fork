#!/bin/bash
#
# This script creates an icon set for MacOS.
# Run this script in a terminal.
# For more information see instructios in the
# Readme file.
#
# <under costruction>
#
# Created 2026-03-28 by DF7BE
#
# "convert" is from "imagemagick".
#
# Configure this script to your own needs
#
# The source image file created first at bitmap format
# and converted to PNG with size 1024x1024
SOURCEIMG=./hwgui_1024x1024.png
# Here the icon set is stored
OUTPUT_PATH=./hwgui.iconset
# 
#
# Create all by resize the basic png
#
# 16x16
  convert $SOURCEIMG -resize 16 $output_path/icon_16x16.png
# 32x32
  convert $SOURCEIMG -resize 32 $output_path/icon_16x16@2x.png
  convert $SOURCEIMG -resize 32 $output_path/icon_32x32.png  
# 64x64
  convert $SOURCEIMG -resize 64 $output_path/icon_32x32@2x.png
# 128x128
  convert $SOURCEIMG -resize 128 $output_path/icon_128x128.png
# 256x256
  convert $SOURCEIMG -resize 256 $output_path/icon_128x128@2x.png
  convert $SOURCEIMG -resize 256 $output_path/icon_256x256.png
# 512x512
  convert $SOURCEIMG -resize 512 $output_path/icon_256x256@2x.png
  convert $SOURCEIMG -resize 512 $output_path/icon_512x512.png
# 1024x1024
  convert $SOURCEIMG -resize 1024 $output_path/icon_512x512@2x.png
#
# Now create the .incs file for insert into the program (icon.icns).
iconutil -c icns $output_path
#
# --------------------- EOF of hwg_icons_macos.sh ---------
  
  
