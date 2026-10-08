/*
 * sidebar.prg — HPanel collapse / expand demo (WinAPI / GTK)
 *
 * Collapse / expand a left sidebar with:
 *   - a floating "«" / "»" button that follows the panel,
 *   - hover auto-collapse (mouse away from the panel for ~0.8 s),
 *   - auto-expand when the cursor returns to the left edge of the
 *     main window (not the screen, so it works with a centred form),
 *   - owned module dialogs shifted / restored with the panel.
 *
 * Auto-collapse is driven by a Windows timer installed through
 * hwg_SetTimer() with a codeblock.  The codeblock is registered in
 * a C-level table and evaluated by s_timerProcBlock on every tick,
 * which avoids both the "global dispatcher name" lookup that used
 * to fail silently and the WM_TIMER routing that this HWGUI build
 * does not deliver to HPanel:onEvent.
 */

#include "hwgui.ch"

#define SIDEBAR_W   220
#define SIDEBAR_BTN  52

STATIC oPanel
STATIC oBtnTog

FUNCTION Main()

   LOCAL oForm, oStyle, oFont

   PREPARE FONT oFont NAME "Segoe UI" WIDTH 0 HEIGHT -14
   oStyle := HStyle():New( {15658734, 15658734}, 1 )

   INIT WINDOW oForm MAIN ;
      TITLE "Sidebar demo" ;
      AT 0, 0 SIZE 900, 600 ;
      FONT oFont

   ADD LEFT PANEL oPanel TO oForm ;
       WIDTH SIDEBAR_W ;
       HSTYLE oStyle

   /* --- Sidebar buttons --------------------------------------------- */

   @ 6,  6 OWNERBUTTON OF oPanel ;
       FLAT TEXT "Menu" ;
       SIZE SIDEBAR_W - 12, SIDEBAR_BTN ;
       ON CLICK {|| hwg_MsgInfo( "Menu clicked" ) }

   @ 6, SIDEBAR_BTN + 10 OWNERBUTTON OF oPanel ;
       FLAT TEXT "Estoques" ;
       SIZE SIDEBAR_W - 12, SIDEBAR_BTN ;
       ON CLICK {|| AbrirModulo( oForm ) }

   @ 6, SIDEBAR_BTN * 2 + 14 OWNERBUTTON OF oPanel ;
       FLAT TEXT "Clientes" ;
       SIZE SIDEBAR_W - 12, SIDEBAR_BTN ;
       ON CLICK {|| AbrirModulo( oForm ) }

   /* --- Floating toggle button -------------------------------------- */

   /* Positioned just outside the right edge of the panel so it is not
    * clipped by the panel background.  bOnCollapse / bOnExpand move it
    * to x = 0 when the panel is collapsed, and back to x = SIDEBAR_W+6
    * when the panel is expanded, so it stays reachable in both states. */
   @ SIDEBAR_W + 6, 6 OWNERBUTTON oBtnTog OF oForm ;
       FLAT TEXT "«" ;
       SIZE 24, 44 ;
       ON CLICK {|| oPanel:ToggleCollapse() } ;
       TOOLTIP "Recolher / expandir painel"

   /* --- Wire up collapse / expand ----------------------------------- */

   /* Called by HPanel every time its state changes, whatever the
    * trigger (button click, hover auto-collapse, programmatic call).
    * Keeping the button reposition here means the hover path also
    * moves it without extra bookkeeping. */
   oPanel:bOnCollapse := {|| ReposTogBtn() }
   oPanel:bOnExpand   := {|| ReposTogBtn() }

   /* Enable hover auto-collapse.  The timer is installed inside
    * HPanel:SetAutoCollapse once ::handle is valid. */
   oPanel:SetAutoCollapse( .T. )

   ACTIVATE WINDOW oForm CENTER

RETURN Nil

/*===========================================================================
 * ReposTogBtn
 *
 * Re-anchors the floating button to the outer edge of the sidebar:
 * right of the panel when expanded, left of the window when collapsed.
 * The caption flips accordingly.  Reads ::lCollapsed straight from the
 * panel, so the same function serves bOnCollapse, bOnExpand and the
 * button's own click handler.
 *=========================================================================*/
STATIC FUNCTION ReposTogBtn()

   LOCAL lC := oPanel:lCollapsed

   hwg_MoveWindow( oBtnTog:handle, ;
                   iif( lC, 0, SIDEBAR_W + 6 ), 6, ;
                   24, 44, .T. )
   oBtnTog:SetText( iif( lC, "»", "«" ) )

RETURN Nil

/*===========================================================================
 * AbrirModulo
 *
 * Opens a module dialog owned by oForm.  Marking oForm as the owner
 * lets HPanel:SyncTrackedWindows() find this dialog and shift it left
 * by the panel width when the sidebar collapses, restoring its
 * position when it expands again.
 *=========================================================================*/
STATIC FUNCTION AbrirModulo( oForm )

   LOCAL oDlg

   INIT DIALOG oDlg ;
      TITLE "Módulo" ;
      AT 300, 200 SIZE 500, 350 ;
      STYLE WS_POPUP + WS_CAPTION + WS_SYSMENU

   oDlg:oParent := oForm
   hwg_SetWindowLong( oDlg:handle, GWLP_HWNDPARENT, oForm:handle )

   @ 20, 20 SAY "Este diálogo desloca-se com o painel." ;
       SIZE 460, 30

   ACTIVATE DIALOG oDlg CENTER

RETURN Nil
