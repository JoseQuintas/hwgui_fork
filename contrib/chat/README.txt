================================================================================
 HwguiTurbo Chat - LAN Corporate Chat
================================================================================
 Version : 1.0.0
 License : MIT
 Author  : Itamar M. Lins Jr.
 Date    : 2026-09-20
================================================================================


1. OVERVIEW
--------------------------------------------------------------------------------
HwguiTurbo Chat is a peer-to-peer corporate chat application for local area
networks (LAN), designed for small teams (up to ~30 simultaneous users).

It uses a central TCP server to route messages between clients. Each client
runs a Windows GUI application built with Harbour + HWGUI, embedding a
WebView2 (Chromium) browser to render a modern HTML/CSS/JS interface.

The user interface is WhatsApp-style: sidebar with online users, chat area
with message bubbles, support for text messages, emojis and file transfer
(images, PDFs and other files up to 50 MB).


2. FEATURES
--------------------------------------------------------------------------------
  - Central TCP server (port 9999, multithreaded)
  - Windows system tray icon on the server with context menu
  - Hidden server window (runs in background)
  - Online users list (server admin view)
  - Real-time text chat between clients
  - 40 selectable avatars (emoji picker at login)
  - Unread message badges in the sidebar
  - File transfer (images, PDFs, generic files up to 50 MB)
  - Inline image preview, download link for other file types
  - Upload progress bar and drag-and-drop support
  - Toast notification + taskbar flash on incoming message
  - Sound beep on incoming message
  - HTML cache-busting (auto-reload updated user.html)
  - Detailed operation logs for debugging


3. REQUIREMENTS
--------------------------------------------------------------------------------
  Operating System
    - Windows 10 or Windows 11
    - WebView2 Runtime installed (usually shipped with Edge)

  Development Environment (to build from source)
    - Harbour 3.2.1dev or later
    - HWGUI 2.23 or later
    - Clang 22 (MSYS2 CLANG64 recommended) or MSVC
    - hbmk2 build tool

  Runtime Dependencies (must be in the same folder as the .exe)
    - WebView2Loader.dll    (Microsoft WebView2 SDK)
    - webview.dll           (lib webview/webview)
    - webview_wrapper.dll   (project's C wrapper, compiled with Clang)
    - server.ico            (tray icon for the server)


4. FILE STRUCTURE
--------------------------------------------------------------------------------
  server.prg              TCP server source (Harbour + HWGUI)
  user.prg                Client source (Harbour + HWGUI + WebView2)
  user.html               Client UI (HTML/CSS/JS)
  user.ini                Client configuration (server IP and port)

  server.exe              Compiled server
  user.exe                Compiled client

  WebView2Loader.dll      Microsoft WebView2 loader
  webview.dll             lib webview/webview
  webview_wrapper.dll     Project's C wrapper
  server.ico              Tray icon

  srv_debug.log           Server operation log (generated at runtime)
  user_debug_<id>.log     Client operation log (generated at runtime)

  LICENSE                 MIT license
  README.txt              This file


5. BUILD
--------------------------------------------------------------------------------
From the project folder, run:

  hbmk2 server.prg -mt
  hbmk2 user.prg   -mt

  -mt enables multithreading (required for both server and client).

No external library is needed for sockets: hb_inet* functions come from
the Harbour core, already available in any standard installation.


6. CONFIGURATION
--------------------------------------------------------------------------------
Server:
  The server listens on port 9999 by default. To change it, edit the
  static variable nPort at the top of server.prg and recompile.

Client:
  Edit user.ini to point to the server's IP address and port:

    [SERVER]
    IP=127.0.0.1
    PORT=9999

  For local testing, use 127.0.0.1.
  For LAN deployment, use the server machine's real IP
  (e.g. 192.168.1.100).


7. HOW TO RUN
--------------------------------------------------------------------------------
Step 1 - Start the server
  Run server.exe on the machine that will act as the server.
  The main window stays hidden; an icon appears in the system tray.

  Right-click the tray icon for options:
    - Open Window  : show the online users list
    - Exit         : stop the server
    - About        : version and port info

Step 2 - Start the clients
  Run user.exe on each client machine.

  At the login screen:
    1. Type your display name (e.g. John)
    2. Pick an avatar from the emoji picker
    3. Click Enter

  The sidebar will show all online users. Click a name to open the chat,
  type a message and press Enter (or click the arrow button).

Step 3 - Send files
  Click the paperclip button (or drag a file onto the chat window) to
  send a file to the current contact. Supported file types include
  images (inline preview), PDFs, office documents and archives.


8. PROTOCOL (JSON over TCP)
--------------------------------------------------------------------------------
Each message is a single JSON object terminated by a newline (Chr(10)).
File chunks use a special format: JSON + \x01 (Chr(1)) + raw base64.

Client -> Server:
  {"cmd":"login","user":"...","maquina":"...","emoji":"..."}
  {"cmd":"msg","to":"...","text":"..."}
  {"cmd":"file.start","to":"...","id":"...","name":"...","size":N,"mime":"..."}
  {"cmd":"file.chunk","to":"...","id":"...","i":N}\x01<base64>
  {"cmd":"file.end","to":"...","id":"..."}

Server -> Client:
  {"cmd":"list","users":[{nome,emoji},...]}
  {"cmd":"presence","user":"...","on":bool,"emoji":"..."}
  {"cmd":"msg","from":"...","text":"..."}
  {"cmd":"sent","to":"..."}
  {"cmd":"file.start","from":"...","id":"...","name":"...","size":N,"mime":"..."}
  {"cmd":"file.chunk","id":"...","i":N}\x01<base64>
  {"cmd":"file.end","id":"..."}
  {"cmd":"file.sent","id":"..."}
  {"cmd":"error","msg":"..."}


9. ARCHITECTURE
--------------------------------------------------------------------------------
                        TCP/IP (LAN)
  +-------------+          |          +-------------+
  |   user.exe  | <--------+--------> |   user.exe  |
  |  (client)   |                     |  (client)   |
  +------+------+                     +------+------+
         |                                   |
         |  WebView2 (Chromium)              |
         |  HTML/CSS/JS  <->  Harbour        |
         |                                   |
         +--------------- TCP ---------------+
                        |
                 +------+------+
                 |  server.exe |   (tray icon, hidden window)
                 |  port 9999  |
                 +-------------+

  - Threads on server: one for accept(), one per connected client.
  - Thread-safe hash tables (hUsers, hSockets) protected by mutex.
  - UI marshaling: worker thread posts WM_REFRESH via HWG_POSTMESSAGE.
  - Client receives socket events on a worker thread, queues them
    with a mutex, and drains the queue from the GUI idle loop.


10. TROUBLESHOOTING
--------------------------------------------------------------------------------
Problem: "Could not connect to <IP>:9999"
  - Check that server.exe is running.
  - Check user.ini points to the correct IP and port.
  - Check Windows Firewall: allow inbound TCP port 9999.
  - Check the network: ping the server machine.

Problem: Listbox on the server is empty
  - Check srv_debug.log for "client connected" and "login OK" lines.
  - If the log shows activity but the list stays empty, the UI
    refresh chain (PostMessage -> WM_REFRESH) may be broken.

Problem: WebView is detached from the window
  - The C function create_webview_embedded() finds the parent window
    by exact title match (FindWindowA). The window title must be
    exactly the string passed as the first argument.
  - Kill all pending instances and restart.

Problem: HTML changes do not appear
  - WebView2 caches file:// URLs. The client already appends
    ?v=<timestamp> to the URL, but if an old instance is still
    running, close it first.

Problem: File transfer fails or stalls
  - Check user_debug_<id>.log for "FileChunk i=N" lines.
  - If chunks are sent but never received, reduce CHUNK_RAW in
    user.html (currently 1 KB) to a smaller value.

Problem: "Undefined symbol HB_INET*"
  - hb_inet* functions are part of the Harbour core. They do not
    require hbnetio. Make sure you are using -mt on the build line.


11. KNOWN LIMITATIONS
--------------------------------------------------------------------------------
  - Received files are held in memory only (not saved to disk).
  - Chat history is not persisted between sessions.
  - No automatic server discovery (user.ini must be configured).
  - No offline messaging (messages to offline users are lost).
  - No group chat (1-to-1 conversations only).
  - No message encryption (plain text over LAN).
  - No reconnection logic if the server goes down.


12. ROADMAP / PENDING ITEMS
--------------------------------------------------------------------------------
  - Save received files to disk (e.g. Documents\ChatReceived\)
  - Persist conversation history (DBF or SQLite)
  - Automatic server discovery via UDP broadcast
  - Server as Windows service (NSSM)
  - Client auto-start + minimize to tray
  - Group chat
  - Message search
  - Acknowledgment of delivery/read (proper ACK)


13. LICENSE
--------------------------------------------------------------------------------
  MIT License

  Copyright (c) 2026 Itamar M. Lins Jr.

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject
  to the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  See the LICENSE file in the project root for the full text.


14. CONTACT
--------------------------------------------------------------------------------
  Author  : Itamar M. Lins Jr.
  Email   : itamarlins@gmail.com
================================================================================
