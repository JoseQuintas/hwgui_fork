#!/bin/bash
#
# Simple script to wait until successful decoded QR code
# Parameter added: $1 : pass with numbers of tries to avoid
# endlees loop, if no QR code is available.
# Default value is 1.
#
function scan_qr() {
  local result=""
  while true
  do
    imagesnap -q -w 1 /tmp/snap.jpg
    result="$(zbarimg -1 --raw -q -Sbinary /tmp/snap.jpg)"
    [[ -n $result ]] && break
    sleep 1
    # count tries
    # echo $LOOPING
    LOOPING=$((LOOPING+1))
    if [[ "$LOOPING" -gt $TRIES ]]
    then
      break
    fi
  done
  echo "${result}"
}

TRIES=${1:-1}
# echo $TRIES
LOOPING=0

scan_qr


# --------------- EOF of qrdecode_mac.sh --------------------