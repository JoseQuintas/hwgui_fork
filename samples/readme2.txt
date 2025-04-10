#
# $Id$
#

# Use this as a template for building your application with HWGUI
# and the hbmk2 utility of Harbour.
# Remove comment lines (#), if you want

# Modify "sample" ( 2 x ) to the name of program to compile

-b
-n -w3 -es0

# Special parameters for LINUX/GTK
{linux}-lm
{linux}-static
{linux}-d__LINUX__
{linux}-d__GTK__

# Use -mt for multithread program
#-mt

# For GTK samples (directory samples/gtk_samples)
#-L../..
# The -L parameter declares the search path for libraries and makefiles for hbmk2 utility (*.hb?)

#I../include
# The -I parameter declares the search path for include files (*.ch, *.h)
# Some path values and other common parameters are declared in the common file
# "hwgui.hbc" of HWGUI, so that this file could be very small.

-L..
hwgui.hbc
#../hwgui.hbc
# -L parameter is not necessary, if relative or absolute path values for files are declared.

# ==== Name of exe file (on LINUX without any extension) ====
# This parameter is optional, can be deleted, if only one
# prg file is necessary for building (==> sample.exe).
# Mandatory, if more than one prg file needed.
-osample

# List of prg file(s), start with file containing the MAIN() function or procedure
sample.prg


# ===================== EOF of sample.hbp ====================

