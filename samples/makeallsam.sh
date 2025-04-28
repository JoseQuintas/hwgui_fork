#!/bin/bash
#
# makeallsam.sh
#
# $Id$
#
# This sh builds all HWGUI sample programs
# by using the hbmk2 utility.
#
# If a sample program is "Windows only",
# the stop option in the *.hbp may be skip
# the build.
#
# Be sure, that all prerequisites are available
# and the PATH is set
#
# If creating a new sample program,
# don't forget to add it here.
#
hbmk2 a.hbp
hbmk2 allhbp.hbp
hbmk2 demoall.hbp
hbmk2 testbrowsearr.hbp
hbmk2 bincnts.hbp
hbmk2 bindbf.hbp
hbmk2 bitmapbug.hbp
hbmk2 buildpelles.hbp
hbmk2 colrbloc.hbp
hbmk2 dbview.hbp
hbmk2 demodbf.hbp
hbmk2 Dialogboxes.hbp
hbmk2 escrita.hbp
hbmk2 fileselect.hbp
hbmk2 GetWinVers.hbp
hbmk2 graph.hbp
hbmk2 hello.hbp
hbmk2 helpdemo.hbp
hbmk2 helpstatic.hbp
hbmk2 hexbincnt.hbp
hbmk2 hole.hbp
hbmk2 icons.hbp
hbmk2 icons2.hbp
hbmk2 iesample.hbp
hbmk2 imageview.hbp
hbmk2 memocmp.hbp
hbmk2 menumod.hbp
hbmk2 modtitle.hbp
hbmk2 nice.hbp
hbmk2 nice2.hbp
hbmk2 night.hbp
hbmk2 propsh.hbp
hbmk2 pseudocm.hbp
hbmk2 qrencode.hbp
hbmk2 qrencodedll.hbp
hbmk2 simpleedit.hbp
hbmk2 stretch.hbp
hbmk2 tab.hbp
hbmk2 tabs_toolt.hbp
hbmk2 testalert.hbp
hbmk2 testbmpcr.hbp
hbmk2 testbrw.hbp
hbmk2 testfunc.hbp
hbmk2 testget1.hbp
hbmk2 testhgt.hbp
hbmk2 testimage.hbp
hbmk2 testmenubitmap.hbp
hbmk2 testrtf.hbp
hbmk2 testtray.hbp
hbmk2 demoonother.hbp
hbmk2 tstscrlbar.hbp
hbmk2 tstsplash.hbp
hbmk2 tststconsapp.hbp
hbmk2 TwoListbox.hbp
hbmk2 TwoLstSub.hbp
hbmk2 winprn.hbp

# ================= EOF of makeallsam.sh ==================
