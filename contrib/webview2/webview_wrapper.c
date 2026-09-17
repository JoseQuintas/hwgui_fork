#include <webview/webview.h>
#include <stdint.h>
#include <windows.h>
#include <stdlib.h>
#include <string.h>

#define WM_HWGUI_WEBVIEW_MSG (WM_USER + 100)
#define MAX_WEBVIEWS         16

//-----------------------------------------------------------------------------
// Per-WebView context — one instance per WebView
//-----------------------------------------------------------------------------
typedef struct {
      webview_t w;
      WNDPROC   old_proc;
      HWND      parent;
      char     *pending_id;
      char     *pending_data;
      char     *pending_func;
      int       id;
      int       used;
} WebViewContext;

static WebViewContext *g_contexts[MAX_WEBVIEWS] = { NULL };

//-----------------------------------------------------------------------------
// Find a context by its ID
//-----------------------------------------------------------------------------
static WebViewContext* find_context(int id) {
      for (int i = 0; i < MAX_WEBVIEWS; i++) {
            if (g_contexts[i] && g_contexts[i]->used && g_contexts[i]->id == id)
                  return g_contexts[i];
      }
      return NULL;
}

//-----------------------------------------------------------------------------
// Free the pending buffers of a context
//-----------------------------------------------------------------------------
static void free_pending(WebViewContext *ctx) {
      if (!ctx) return;
      if (ctx->pending_id)   { free(ctx->pending_id);   ctx->pending_id   = NULL; }
      if (ctx->pending_data) { free(ctx->pending_data); ctx->pending_data = NULL; }
      if (ctx->pending_func) { free(ctx->pending_func); ctx->pending_func = NULL; }
}

//-----------------------------------------------------------------------------
// SubclassProc — intercepts WM_SIZE from the parent window and resizes
// the WebView accordingly. Uses a window property (not GWLP_USERDATA)
// to retrieve the context associated with the window, so it does not
// conflict with Hwgui's own use of GWLP_USERDATA.
//-----------------------------------------------------------------------------
static LRESULT CALLBACK SubclassProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
      WebViewContext *ctx = (WebViewContext*)GetPropA(hwnd, "HwguiTurboCtx");

      if (msg == WM_SIZE && ctx && ctx->w) {
            int w = LOWORD(lp);
            int h = HIWORD(lp);
            if (w > 0 && h > 0) {
                  webview_set_size(ctx->w, w, h, WEBVIEW_HINT_NONE);
                  HWND hwnd_wv = (HWND)webview_get_window(ctx->w);
                  if (hwnd_wv)
                        SetWindowPos(hwnd_wv, HWND_TOP, 0, 0, w, h,
                                     SWP_NOACTIVATE | SWP_SHOWWINDOW);
            }
      }

      if (ctx && ctx->old_proc)
            return CallWindowProc(ctx->old_proc, hwnd, msg, wp, lp);

      return DefWindowProc(hwnd, msg, wp, lp);
}

//-----------------------------------------------------------------------------
// Auxiliary structure to hold the JS function name alongside the context
// (passed as "arg" to webview_bind)
//-----------------------------------------------------------------------------
typedef struct {
      WebViewContext *ctx;
      char           *func_name;
} FuncBinding;

//-----------------------------------------------------------------------------
// Callback invoked by JavaScript (through webview_bind).
// Receives a FuncBinding as "arg" so it knows which context and which
// JS function triggered the call.
//-----------------------------------------------------------------------------
static void hwgui_bridge(const char *id, const char *req, void *arg) {
      FuncBinding *fb = (FuncBinding*)arg;
      if (!fb || !fb->ctx) {
            MessageBoxA(NULL, "C: bridge - fb NULL or ctx NULL", "Debug C", MB_OK);
            return;
      }

      WebViewContext *ctx = fb->ctx;
      free_pending(ctx);

      if (id)  { ctx->pending_id   = (char*)malloc(strlen(id)+1);  strcpy(ctx->pending_id,   id);  }
      if (req) { ctx->pending_data = (char*)malloc(strlen(req)+1); strcpy(ctx->pending_data, req); }
      if (fb->func_name) {
            ctx->pending_func = (char*)malloc(strlen(fb->func_name)+1);
            strcpy(ctx->pending_func, fb->func_name);
      }

      if (ctx->parent) {
            PostMessage(ctx->parent, WM_HWGUI_WEBVIEW_MSG, (WPARAM)ctx->id, 0);
      } else {
            MessageBoxA(NULL, "C: bridge - ctx->parent is NULL", "Debug C", MB_OK);
      }
}

//-----------------------------------------------------------------------------
extern "C" {

      //-----------------------------------------------------------------------------
      // Create an embedded WebView and return a pointer to its context.
      // parent_title : title of the Hwgui parent window
      // title        : title of the WebView window
      // width/height : initial size
      // id           : context ID (1..MAX_WEBVIEWS)
      //-----------------------------------------------------------------------------
      __declspec(dllexport)
      void* create_webview_embedded(const char* parent_title, const char* title,
                                    int width, int height, int id) {
            WebViewContext *ctx = NULL;

            // Check if the ID already exists
            if (find_context(id) != NULL) return NULL;

            // Allocate a new context
            ctx = (WebViewContext*)calloc(1, sizeof(WebViewContext));
            if (!ctx) return NULL;

            ctx->id   = id;
            ctx->used = 1;

            HWND hwnd_parent = NULL;
            if (parent_title && parent_title[0]) hwnd_parent = FindWindowA(NULL, parent_title);
            if (!hwnd_parent) hwnd_parent = GetActiveWindow();
            if (!hwnd_parent) hwnd_parent = GetForegroundWindow();
            if (!hwnd_parent) { free(ctx); return NULL; }

            webview_t w = webview_create(0, NULL);
            if (!w) { free(ctx); return NULL; }

            webview_set_title(w, title);

            HWND hwnd_wv = (HWND)webview_get_window(w);
            if (!hwnd_wv) { webview_destroy(w); free(ctx); return NULL; }

            // Strip top-level window styles and turn it into a child window
            LONG_PTR style = GetWindowLongPtr(hwnd_wv, GWL_STYLE);
            style &= ~(WS_POPUP | WS_CAPTION | WS_THICKFRAME | WS_OVERLAPPED |
            WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
            style |= WS_CHILD;
            SetWindowLongPtr(hwnd_wv, GWL_STYLE, style);

            // Remove extended border styles
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

            ctx->w      = w;
            ctx->parent = hwnd_parent;

            // Store the context on the window using a named property (NOT GWLP_USERDATA,
            // which is used by Hwgui for its own purposes)
            SetPropA(hwnd_parent, "HwguiTurboCtx", (HANDLE)ctx);

            // Install the subclass
            ctx->old_proc = (WNDPROC)SetWindowLongPtr(hwnd_parent, GWLP_WNDPROC,
                                                      (LONG_PTR)SubclassProc);

            // Register in the global array
            for (int i = 0; i < MAX_WEBVIEWS; i++) {
                  if (!g_contexts[i]) { g_contexts[i] = ctx; break; }
            }

            return (void*)ctx;
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    void navigate_webview(void* w, const char* url) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          if (ctx && ctx->w) webview_navigate(ctx->w, url);
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    void resize_webview(void* w, int width, int height) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          if (!ctx || !ctx->w || width <= 0 || height <= 0) return;
                                          webview_set_size(ctx->w, width, height, WEBVIEW_HINT_NONE);
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    int bind_webview(void *w, const char *name) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          if (!ctx || !ctx->w || !name) return -1;

                                          // Allocate a FuncBinding passed as "arg" to webview_bind
                                          FuncBinding *fb = (FuncBinding*)malloc(sizeof(FuncBinding));
                                          fb->ctx       = ctx;
                                          fb->func_name = (char*)malloc(strlen(name)+1);
                                          strcpy(fb->func_name, name);

                                          return webview_bind(ctx->w, name, hwgui_bridge, fb);
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    const char* get_message_id(void* w) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          return ctx ? ctx->pending_id : NULL;
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    const char* get_message_data(void* w) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          return ctx ? ctx->pending_data : NULL;
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    const char* get_message_func(void* w) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          return ctx ? ctx->pending_func : NULL;
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    int reply_webview(void *w, const char *result) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          if (!ctx || !ctx->w || !ctx->pending_id) {
                                                return -1;   // sem MessageBox
                                          }
                                          int rc = webview_return(ctx->w, ctx->pending_id, 0, result);
                                          free_pending(ctx);
                                          return rc;
                                    }
                                    // ============ HB_WebView PARITY ============

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    int eval_webview(void *w, const char *js) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          if (!ctx || !ctx->w || !js) return -1;
                                          return webview_eval(ctx->w, js);
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    int init_webview(void *w, const char *js) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          if (!ctx || !ctx->w || !js) return -1;
                                          return webview_init(ctx->w, js);
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    int set_html_webview(void *w, const char *html) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          if (!ctx || !ctx->w || !html) return -1;
                                          return webview_set_html(ctx->w, html);
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    int terminate_webview(void *w) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          if (!ctx || !ctx->w) return -1;
                                          return webview_terminate(ctx->w);
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    void* get_native_handle_webview(void *w, int kind) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          if (!ctx || !ctx->w) return NULL;
                                          return webview_get_native_handle(ctx->w,
                                                                           (webview_native_handle_kind_t)kind);
                                    }

                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    void destroy_webview(void* w) {
                                          WebViewContext *ctx = (WebViewContext*)w;
                                          if (!ctx) return;

                                          // Restore the original WndProc and remove the property
                                          if (ctx->parent && ctx->old_proc) {
                                                RemovePropA(ctx->parent, "HwguiTurboCtx");
                                                SetWindowLongPtr(ctx->parent, GWLP_WNDPROC, (LONG_PTR)ctx->old_proc);
                                          }

                                          // Destroy the WebView
                                          if (ctx->w)
                                                webview_destroy(ctx->w);

                                          free_pending(ctx);

                                          // Remove from the global array
                                          for (int i = 0; i < MAX_WEBVIEWS; i++) {
                                                if (g_contexts[i] == ctx) { g_contexts[i] = NULL; break; }
                                          }

                                          free(ctx);
                                    }

                                    //-----------------------------------------------------------------------------
                                    // Utility: return the context pointer by ID (used by Harbour for dispatch)
                                    //-----------------------------------------------------------------------------
                                    __declspec(dllexport)
                                    void* get_context_by_id(int id) {
                                          return (void*)find_context(id);
                                    }

}
