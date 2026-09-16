#include <webview/webview.h>
#include <stdint.h>
#include <windows.h>

static webview_t g_webview = NULL;
static WNDPROC   g_old_proc = NULL;
static HWND      g_parent   = NULL;

static LRESULT CALLBACK SubclassProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
   if (msg == WM_SIZE && g_webview != NULL) {
      int w = LOWORD(lp);
      int h = HIWORD(lp);
      if (w > 0 && h > 0)
         webview_set_size(g_webview, w, h, WEBVIEW_HINT_NONE);
   }
   return CallWindowProc(g_old_proc, hwnd, msg, wp, lp);
}

extern "C" {

   __declspec(dllexport) void* create_webview_embedded(const char* parent_title, const char* title, int width, int height) {
      HWND hwnd_parent = NULL;
      if (parent_title && parent_title[0]) hwnd_parent = FindWindowA(NULL, parent_title);
      if (!hwnd_parent) hwnd_parent = GetActiveWindow();
      if (!hwnd_parent) hwnd_parent = GetForegroundWindow();
      if (!hwnd_parent) return NULL;

      webview_t w = webview_create(0, NULL);
      if (!w) return NULL;

      webview_set_title(w, title);

      HWND hwnd_wv = (HWND)webview_get_window(w);
      if (!hwnd_wv) { webview_destroy(w); return NULL; }

      LONG_PTR style = GetWindowLongPtr(hwnd_wv, GWL_STYLE);
      style &= ~(WS_POPUP | WS_CAPTION | WS_THICKFRAME | WS_OVERLAPPED |
      WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
      style |= WS_CHILD;
      SetWindowLongPtr(hwnd_wv, GWL_STYLE, style);

      LONG_PTR exstyle = GetWindowLongPtr(hwnd_wv, GWL_EXSTYLE);
      exstyle &= ~(WS_EX_CLIENTEDGE | WS_EX_WINDOWEDGE |
      WS_EX_DLGMODALFRAME | WS_EX_STATICEDGE);
      SetWindowLongPtr(hwnd_wv, GWL_EXSTYLE, exstyle);

      SetParent(hwnd_wv, hwnd_parent);

      RECT rc;
      GetClientRect(hwnd_parent, &rc);
      int cw = rc.right  > 0 ? rc.right  : width;
      int ch = rc.bottom > 0 ? rc.bottom : height;

      webview_set_size(w, cw, ch, WEBVIEW_HINT_NONE);
      SetWindowPos(hwnd_wv, HWND_TOP, 0, 0, cw, ch,
                   SWP_FRAMECHANGED | SWP_NOACTIVATE | SWP_SHOWWINDOW);

      g_webview = w;
      g_parent  = hwnd_parent;
      g_old_proc = (WNDPROC)SetWindowLongPtr(hwnd_parent, GWLP_WNDPROC, (LONG_PTR)SubclassProc);

      return (void*)w;
   }

   __declspec(dllexport) void navigate_webview(void* w, const char* url) {
      if (!w) return;
      webview_navigate((webview_t)w, url);
   }

   __declspec(dllexport) void resize_webview(void* w, int width, int height) {
      if (!w || width <= 0 || height <= 0) return;
      webview_set_size((webview_t)w, width, height, WEBVIEW_HINT_NONE);
   }

   __declspec(dllexport) void destroy_webview(void* w) {
      if (!w) return;
      if (g_parent && g_old_proc) {
         SetWindowLongPtr(g_parent, GWLP_WNDPROC, (LONG_PTR)g_old_proc);
         g_old_proc = NULL;
         g_parent   = NULL;
      }
      g_webview = NULL;
      webview_destroy((webview_t)w);
   }

}
