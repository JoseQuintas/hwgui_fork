#!/bin/bash
#
# build.sh — HWGUI GTK4 build wrapper
#
# Notes
# -----
#  - Keeps the original log redirection to a1.log / a2.log.
#  - Adds proper error propagation: the script exits non-zero if make fails.
#  - Uses `set -u` and `set -o pipefail` for safe variable / pipeline handling.
#    `set -e` is intentionally NOT used so the error-handling block below
#    still runs after a failed `make`.
#
#  - The relative paths ../../lib and ../../obj are preserved from the
#    original script.  They assume the current working directory is a
#    subdirectory of source/ (e.g. source/gtk/) that sits two levels
#    below the repository root.
#

set -u
set -o pipefail

# Resolve the repo root relative to *this script* so the script works
# regardless of the current working directory.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../../lib"
OBJ_DIR="${SCRIPT_DIR}/../../obj"

# --- lib/ ---------------------------------------------------------------
if [ ! -d "${LIB_DIR}" ]; then
   mkdir -p "${LIB_DIR}"
   chmod a+w+r+x "${LIB_DIR}"
fi

# --- obj/ ---------------------------------------------------------------
if [ ! -d "${OBJ_DIR}" ]; then
   mkdir -p "${OBJ_DIR}"
   chmod a+w+r+x "${OBJ_DIR}"
fi

# Optional: allow overriding HB_ROOT from the environment.
# Uncomment if the Makefile consumes it.
# export HB_ROOT="${HB_ROOT:-${SCRIPT_DIR}/../../..}"

# --- make ---------------------------------------------------------------
LOG_OUT="${SCRIPT_DIR}/a1.log"
LOG_ERR="${SCRIPT_DIR}/a2.log"

if make -fMakefile.linux >"${LOG_OUT}" 2>"${LOG_ERR}"; then
   echo "Build OK    (stdout: ${LOG_OUT##*/}, stderr: ${LOG_ERR##*/})"
   exit 0
else
   rc=$?
   echo "Build FAILED (exit ${rc})" >&2
   echo "--- last 40 lines of ${LOG_ERR##*/} ---" >&2
   tail -n 40 "${LOG_ERR}" >&2
   echo "-------------------------------------" >&2
   echo "Full logs: ${LOG_OUT}, ${LOG_ERR}" >&2
   exit "${rc}"
fi
