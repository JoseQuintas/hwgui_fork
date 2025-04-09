#
# build HWGUI hwreport for GCC on LINUX/GTK
# $Id$
# by DF7BE
# 2025-04-09
# Based on bldmngw.bat from
# 2020-07-01


# Ignore warning:
# Warning! W1008: cannot open hbactivex.lib : No such file or directory

# Some images lost (not checked in)
# See resource file:
# PIM.ICO ==> use ok.ico instead
# BUILD.BMP ==> use next.bmp



# %XHB%

# Resource file not compatible for windres of GCC and multi platform purposes
# hbmk2 hwreport2.hbp repbuild2.rc -I%HWGUI_INSTALL%\include -L%HWGUI_INSTALL%\lib %HWG_LIBS% -gui
# hbmk2 hwreport.hbp -I%HWGUI_INSTALL%\include -L%HWGUI_INSTALL%\lib -L%HRB_LIB_DIR% %HWG_LIBS% -gui
hbmk2 hwreport.hbp
hbmk2 example.hbp 

# ======= EOF of make_linux.sh =========
