cd /c/dev/webview
clang++ -shared -O2 -std=c++17 -static -x c++ \
  -Wl,--strip-all -Wl,--gc-sections \
  -ffunction-sections -fdata-sections \
  -o /c/dev/hwgui/bin/webview_wrapper.dll \
  webview_wrapper.c \
  /c/dev/webview/core/src/webview.cc \
  -I/c/dev/webview/core/include \
  -I/c/dev/webview2/build/native/include \
  -DUNICODE -D_UNICODE \
  -luser32 -lole32 -loleaut32 -lshlwapi \
  -ladvapi32 -lversion -lcomctl32 -lntdll -ldwmapi \
  -fuse-ld=lld
