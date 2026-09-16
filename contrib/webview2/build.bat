@echo off
setlocal

REM ===================================================================
REM  build.bat - Compile webview_wrapper.dll  (pure CMD, no MSYS2 shell)
REM  Optimized for small output size.
REM ===================================================================

set MSYS=C:\msys64
set CLANG64=%MSYS%\clang64
set PATH=%CLANG64%\bin;%PATH%

cd /d C:\dev\hwgui\contrib\webview2

echo Compiling webview_wrapper.dll...

clang++.exe -shared -Os -std=c++17 -static -x c++ ^
  -flto ^
  -ffunction-sections -fdata-sections ^
  -Wl,--gc-sections ^
  -Wl,--strip-all ^
  -o webview_wrapper.dll ^
  webview_wrapper.c ^
  C:\dev\webview\core\src\webview.cc ^
  -IC:\dev\webview\core\include ^
  -IC:\dev\webview2\build\native\include ^
  -I%CLANG64%\include ^
  -L%CLANG64%\lib ^
  -DUNICODE -D_UNICODE ^
  -luser32 -lole32 -loleaut32 -lshlwapi ^
  -ladvapi32 -lversion -lcomctl32 -lntdll -ldwmapi ^
  -fuse-ld=lld

if errorlevel 1 (
    echo.
    echo *** BUILD FAILED ***
    pause
    exit /b 1
)

echo.
echo *** OK - webview_wrapper.dll ***
echo.
for %%A in (webview_wrapper.dll) do echo Size: %%~zA bytes
pause
endlocal
