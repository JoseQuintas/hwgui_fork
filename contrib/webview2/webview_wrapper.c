#include <webview/webview.h>
#include <stdint.h>
#include <windows.h>
#include <commctrl.h>
#include <stdlib.h>
#include <string.h>

/* FIXED: SetWindowSubclass()/RemoveWindowSubclass() (comctl32, Common
 * Controls v6) require comctl32.dll v6 to be loaded - normally already
 * the case for any app with a modern manifest (comctl32 v6 is what
 * themed controls need anyway). No extra initialization call is
 * required beyond that. */

#define WM_HWGUI_WEBVIEW_MSG (WM_USER + 100)
#define MAX_WEBVIEWS         16

//-----------------------------------------------------------------------------
// Auxiliary structure to hold the JS function name alongside the context
// (passed as "arg" to webview_bind). Forward-declared here so it can be
// referenced from WebViewContext below.
//-----------------------------------------------------------------------------
typedef struct {
      void  *ctx;        /* WebViewContext* - void* to avoid a forward-declare cycle */
      char  *func_name;
} FuncBinding;

//-----------------------------------------------------------------------------
// Per-WebView context — one instance per WebView
//-----------------------------------------------------------------------------
typedef struct {
      webview_t     w;
      HWND          parent;
      char         *pending_id;
      char         *pending_data;
      char         *pending_func;
      int           id;
      int           used;
      /* FIXED: track every FuncBinding allocated by bind_webview() so
       * destroy_webview() can webview_unbind() and free() them instead
       * of leaking one FuncBinding (+ its func_name string) per bound
       * JS function name, for the lifetime of the process. */
      FuncBinding **bindings;
      int           bindings_count;
      int           bindings_cap;
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
// the WebView accordingly.
//
// FIXED: previously this replaced the parent window's GWLP_WNDPROC
// directly and stashed the single associated context in one
// fixed-name window property ("HwguiTurboCtx"). That only supports ONE
// embedded WebView per parent HWND: a second create_webview_embedded()
// call on the same parent silently overwrote the property (orphaning
// the first WebView's resize handling) and captured SubclassProc
// itself as "old_proc" (so destroy_webview() on the first context
// could never restore the real original WndProc). Using
// SetWindowSubclass()/RemoveWindowSubclass() (comctl32) instead lets
// any number of contexts subclass the same parent independently, each
// identified by its own uIdSubclass (the context pointer) and carrying
// its own dwRefData (also the context pointer) - no shared state, no
// clobbering.
//-----------------------------------------------------------------------------
static LRESULT CALLBACK SubclassProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp,
                                      UINT_PTR uIdSubclass, DWORD_PTR dwRefData) {
      WebViewContext *ctx = (WebViewContext*)dwRefData;

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

      if (msg == WM_NCDESTROY) {
            /* The parent window itself is going away - detach cleanly
             * so we never process further messages through a dead
             * subclass. */
            RemoveWindowSubclass(hwnd, SubclassProc, uIdSubclass);
      }

      return DefSubclassProc(hwnd, msg, wp, lp);
}

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

      WebViewContext *ctx = (WebViewContext*)fb->ctx;
      free_pending(ctx);

      /* FIXED: check every malloc() before strcpy() - a failed
       * allocation used to be passed straight into strcpy(NULL, ...),
       * crashing instead of just dropping that piece of the message. */
      if (id) {
            ctx->pending_id = (char*)malloc(strlen(id)+1);
            if (ctx->pending_id) strcpy(ctx->pending_id, id);
      }
      if (req) {
            ctx->pending_data = (char*)malloc(strlen(req)+1);
            if (ctx->pending_data) strcpy(ctx->pending_data, req);
      }
      if (fb->func_name) {
            ctx->pending_func = (char*)malloc(strlen(fb->func_name)+1);
            if (ctx->pending_func) strcpy(ctx->pending_func, fb->func_name);
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
            int slot = -1;
            int i;

            // Check if the ID already exists
            if (find_context(id) != NULL) return NULL;

            /* FIXED: reserve a free slot in g_contexts BEFORE doing any of
             * the heavy/side-effecting setup below (webview_create,
             * reparenting, subclassing). The old code only tried to
             * register at the very end, after everything else succeeded;
             * if all MAX_WEBVIEWS slots were already taken it silently
             * dropped the fully-initialized context on the floor while
             * still returning it as if successful - get_context_by_id()
             * could never find it again, and a later call with the same
             * id would pass the duplicate check and create yet another
             * unreachable context. */
            for (i = 0; i < MAX_WEBVIEWS; i++) {
                  if (!g_contexts[i]) { slot = i; break; }
            }
            if (slot < 0) return NULL;   // no room for another WebView

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

            // FIXED: SetWindowSubclass() (comctl32) instead of manually
            // swapping GWLP_WNDPROC + a single fixed-name window property.
            // uIdSubclass and dwRefData are both the context pointer, so
            // any number of WebViews embedded in the same parent HWND get
            // their own independent subclass entry - no shared state, no
            // clobbering between them (see SubclassProc's comment above).
            SetWindowSubclass(hwnd_parent, SubclassProc, (UINT_PTR)ctx, (DWORD_PTR)ctx);

            // Register in the global array (slot reserved above)
            g_contexts[slot] = ctx;

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
                                          if (!fb) return -1;
                                          fb->func_name = (char*)malloc(strlen(name)+1);
                                          if (!fb->func_name) { free(fb); return -1; }
                                          fb->ctx = ctx;
                                          strcpy(fb->func_name, name);

                                          // FIXED: keep a reference to fb so destroy_webview() can
                                          // webview_unbind()/free() it - previously every bind_webview()
                                          // call leaked its FuncBinding (and func_name string)
                                          // permanently, since nothing tracked it for later release.
                                          if (ctx->bindings_count == ctx->bindings_cap) {
                                                int newCap = ctx->bindings_cap ? ctx->bindings_cap * 2 : 4;
                                                FuncBinding **newArr = (FuncBinding**)realloc(
                                                      ctx->bindings, newCap * sizeof(FuncBinding*) );
                                                if (!newArr) { free(fb->func_name); free(fb); return -1; }
                                                ctx->bindings     = newArr;
                                                ctx->bindings_cap = newCap;
                                          }
                                          ctx->bindings[ctx->bindings_count++] = fb;

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

                                          // FIXED: detach via RemoveWindowSubclass() - matches the
                                          // SetWindowSubclass() install in create_webview_embedded()
                                          // and only ever affects THIS context's own subclass entry,
                                          // never another WebView's (or an unrelated subclass chain)
                                          // sharing the same parent window.
                                          if (ctx->parent)
                                                RemoveWindowSubclass(ctx->parent, SubclassProc, (UINT_PTR)ctx);

                                          // Destroy the WebView (this also tears down whatever
                                          // internal bookkeeping webview_bind() created on the
                                          // library's side for every binding).
                                          if (ctx->w)
                                                webview_destroy(ctx->w);

                                          free_pending(ctx);

                                          // FIXED: release every FuncBinding registered by bind_webview()
                                          // - previously these were never freed, leaking one FuncBinding
                                          // + its func_name string per bound JS function name on every
                                          // destroy_webview() call. Only OUR OWN heap allocations need
                                          // freeing here - webview_destroy() above already tore down
                                          // the library's internal binding state, so calling
                                          // webview_unbind() at this point would touch an
                                          // already-destroyed ctx->w and must not be done.
                                          if (ctx->bindings) {
                                                int i;
                                                for (i = 0; i < ctx->bindings_count; i++) {
                                                      FuncBinding *fb = ctx->bindings[i];
                                                      if (fb) {
                                                            free(fb->func_name);
                                                            free(fb);
                                                      }
                                                }
                                                free(ctx->bindings);
                                          }

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
