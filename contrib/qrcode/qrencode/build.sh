#!/bin/bash
#
# build.sh
#
# $Id$
#
# Build libraries and sample program for 
# QR encoding feature with the hbmk2 utility
#
 
# qrcodegenerator.c to library libqrcodegen.a
hbmk2 qrcodegenerator.hbp
# Batch sample (static link)
hbmk2 hb_qrencode.hbp
# qrencode.c and libqrencode.prg to libhbqrencode.a
hbmk2 qrencode.hbp 

# ================ EOF of build.sh ====================