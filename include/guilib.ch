/*
 *$Id$
 */
/*
  ========== Define HWGUI release version ============
*/
/* For note of latest official release version number */
#define HWG_VERSION         "2.23 dev"
/* For note of latest official release build */
#define HWG_BUILD               8
/* ----- End of HWGUI version definition ----- */

#define	WND_MAIN                1
#define	WND_MDI                 2
#define WND_MDICHILD            3
#define WND_CHILD               4
#define	WND_DLG_RESOURCE       10
#define	WND_DLG_NORESOURCE     11

#define WND_NOTITLE            -1
#define WND_NOSYSMENU          -2
#define WND_NOSIZEBOX          -4

#define	OBTN_INIT               0
#define	OBTN_NORMAL             1
#define	OBTN_MOUSOVER           2
#define	OBTN_PRESSED            3

#define	BMP_DRAW_SPREAD         0
#define	BMP_DRAW_CENTER         1
#define	BMP_DRAW_FULL           2

#define CHART_BAR               1
#define CHART_LINE              2
#define CHART_PIE               3

#define SHS_NOISE               0
#define SHS_DIAGSHADE           1
#define SHS_HSHADE              2
#define SHS_VSHADE              3
#define SHS_HBUMP               4
#define SHS_VBUMP               5
#define SHS_SOFTBUMP            6
#define SHS_HARDBUMP            7
#define SHS_METAL               8

#define PAL_DEFAULT             0
#define PAL_METAL               1

#define	BRW_ARRAY               1
#define	BRW_DATABASE            2

#define	PAINT_LINE_ALL          0
#define	PAINT_LINE_BACK         1
#define	PAINT_HEAD_ALL          2
#define	PAINT_HEAD_BACK         3
#define	PAINT_FOOT_ALL          4
#define	PAINT_FOOT_BACK         5
#define	PAINT_LINE_ITEM        11
#define	PAINT_HEAD_ITEM        12
#define	PAINT_FOOT_ITEM        13
#define	PAINT_BACK              1
#define	PAINT_ITEM             11

#define	PAGE_FIRST              1
#define	PAGE_LAST               2

#define ANCHOR_TOPLEFT         0   // Anchors control to the top and left borders of the container and does not change the distance between the top and left borders. (Default)
#define ANCHOR_TOPABS          1   // Anchors control to top border of container and does not change the distance between the top border.
#define ANCHOR_LEFTABS         2   // Anchors control to left border of container and does not change the distance between the left border.
#define ANCHOR_BOTTOMABS       4   // Anchors control to bottom border of container and does not change the distance between the bottom border.
#define ANCHOR_RIGHTABS        8   // Anchors control to right border of container and does not change the distance between the right border.
#define ANCHOR_TOPREL          16  // Anchors control to top border of container and maintains relative distance between the top border.
#define ANCHOR_LEFTREL         32  // Anchors control to left border of container and maintains relative distance between the left border.
#define ANCHOR_BOTTOMREL       64  // Anchors control to bottom border of container and maintains relative distance between the bottom border.
#define ANCHOR_RIGHTREL        128 // Anchors control to right border of container and maintains relative distance between the right border.
#define ANCHOR_HORFIX          256 // Anchors center of control relative to left and right borders but remains fixed in size.
#define ANCHOR_VERTFIX         512 // Anchors center of control relative to top and bottom borders but remains fixed in size.

#define HORZ_PTS                9
#define VERT_PTS               12

#ifdef __LINUX__
   /* for some ancient [x]Harbour versions which do not set __PLATFORM__UNIX */
   #ifndef __PLATFORM__UNIX
      #define  __PLATFORM__UNIX
   #endif
#endif

#ifndef __GTK__
   #ifdef __PLATFORM__UNIX
      #define __GTK__
   #endif
#endif

#ifdef __XHARBOUR__
  #ifndef HB_SYMBOL_UNUSED
     #define HB_SYMBOL_UNUSED( x )    ( (x) := (x) )
  #endif
#endif

#xtranslate hwg_Rgb([<n,...>])                    => hwg_ColorRGB2N(<n>)
#xtranslate hwg_VColor([<n,...>])                 => hwg_ColorC2N(<n>)
#xtranslate hwg_ParentGetDialog([<n,...>])        => hwg_getParentForm(<n>)

// Allow the definition of different classes without defining a new command

#xtranslate __IIF(.T., [<true>], [<false>]) => <true>
#xtranslate __IIF(.F., [<true>], [<false>]) => <false>

// Commands for windows, dialogs handling

#xcommand INIT WINDOW <oWnd>                ;
             [ MAIN ]                       ;
             [<lMdi: MDI>]                  ;
             [ APPNAME <appname> ]          ;
             [ TITLE <cTitle> ]             ;
             [ AT <x>, <y> ]                ;
             [ SIZE <width>, <height> ]     ;
             [ ICON <ico> ]                 ;
             [ SYSCOLOR <clr> ]             ;
             [ <bclr: BACKCOLOR, COLOR> <bcolor> ] ;
             [ BACKGROUND BITMAP <oBmp> ]   ;
             [ STYLE <nStyle> ]             ;
             [ EXCLUDE <nExclude> ]         ;
             [ FONT <oFont> ]               ;
             [ MENU <cMenu> ]               ;
             [ MENUPOS <nPos> ]             ;
             [ ON INIT <bInit> ]            ;
             [ ON SIZE <bSize> ]            ;
             [ ON PAINT <bPaint> ]          ;
             [ ON GETFOCUS <bGfocus> ]      ;
             [ ON LOSTFOCUS <bLfocus> ]     ;
             [ ON OTHER MESSAGES <bOther> ] ;
             [ ON EXIT <bExit> ]            ;
             [ HELP <cHelp> ]               ;
             [ HELPID <nHelpId> ]           ;
          => ;
   <oWnd> := HMainWindow():New( Iif(<.lMdi.>,WND_MDI,WND_MAIN), ;
                   <ico>,<clr>,<nStyle>,<x>,<y>,<width>,<height>,<cTitle>, ;
                   <cMenu>,<nPos>,<oFont>,<bInit>,<bExit>,<bSize>,<bPaint>,;
                   <bGfocus>,<bLfocus>,<bOther>,<appname>,<oBmp>,<cHelp>,<nHelpId>,<bcolor>,<nExclude> )

#xcommand INIT WINDOW <oWnd> MDICHILD       ;
             [ APPNAME <appname> ]          ;
             [ TITLE <cTitle> ]             ;
             [ AT <x>, <y> ]                ;
             [ SIZE <width>, <height> ]     ;
             [ ICON <ico> ]                 ;
             [ <bclr: BACKCOLOR, COLOR> <bColor> ] ;
             [ BACKGROUND BITMAP <oBmp> ]   ;
             [ STYLE <nStyle> ]             ;
             [ FONT <oFont> ]               ;
             [ MENU <cMenu> ]               ;
             [ ON INIT <bInit> ]            ;
             [ ON SIZE <bSize> ]            ;
             [ ON PAINT <bPaint> ]          ;
             [ ON GETFOCUS <bGfocus> ]      ;
             [ ON LOSTFOCUS <bLfocus> ]     ;
             [ ON OTHER MESSAGES <bOther> ] ;
             [ ON EXIT <bExit> ]            ;
             [ HELP <cHelp> ]               ;
             [ HELPID <nHelpId> ]           ;
          => ;
   <oWnd> := HMdiChildWindow():New( ;
                   <ico>,,<nStyle>,<x>,<y>,<width>,<height>,<cTitle>, ;
                   <cMenu>,<oFont>,<bInit>,<bExit>,<bSize>,<bPaint>, ;
                   <bGfocus>,<bLfocus>,<bOther>,<appname>,<oBmp>,<cHelp>,<nHelpId>,<bColor> )

#xcommand INIT WINDOW <oWnd> CHILD          ;
             APPNAME <appname>              ;
             [ TITLE <cTitle> ]             ;
             [ AT <x>, <y> ]                ;
             [ SIZE <width>, <height> ]     ;
             [ ICON <ico> ]                 ;
             [ SYSCOLOR <clr> ]             ;
             [ <bclr: BACKCOLOR, COLOR> <bColor> ] ;
             [ BACKGROUND BITMAP <oBmp> ]   ;
             [ STYLE <nStyle> ]             ;
             [ FONT <oFont> ]               ;
             [ MENU <cMenu> ]               ;
             [ ON INIT <bInit> ]            ;
             [ ON SIZE <bSize> ]            ;
             [ ON PAINT <bPaint> ]          ;
             [ ON GETFOCUS <bGfocus> ]      ;
             [ ON LOSTFOCUS <bLfocus> ]     ;
             [ ON OTHER MESSAGES <bOther> ] ;
             [ ON EXIT <bExit> ]            ;
             [ HELP <cHelp> ]               ;
             [ HELPID <nHelpId> ]           ;
          => ;
   <oWnd> := HChildWindow():New( ;
                   <ico>,<clr>,<nStyle>,<x>,<y>,<width>,<height>,<cTitle>, ;
                   <cMenu>,<oFont>,<bInit>,<bExit>,<bSize>,<bPaint>, ;
                   <bGfocus>,<bLfocus>,<bOther>,<appname>,<oBmp>,<cHelp>,<nHelpId>,<bColor> )

#xcommand INIT DIALOG <oDlg>                ;
             [<res: FROM RESOURCE> <Resid> ]         ;
             [ TITLE <cTitle> ]             ;
             [ AT <x>, <y> ]                ;
             [ SIZE <width>, <height> ]     ;
             [ ICON <ico> ]                 ;
             [ BACKGROUND BITMAP <oBmp> ]   ;
             [ STYLE <nStyle> ]             ;
             [ FONT <oFont> ]               ;
             [ <bclr: BACKCOLOR, COLOR> <bColor> ] ;
             [<lClipper: CLIPPER>]          ;
             [<lExitOnEnter: NOEXIT>]       ; //Modified By Sandro
             [<lExitOnEsc: NOEXITESC>]      ; //Modified By Sandro
             [ <lnoClosable: NOCLOSABLE> ]  ;
             [ ON INIT <bInit> ]            ;
             [ ON SIZE <bSize> ]            ;
             [ ON PAINT <bPaint> ]          ;
             [ ON GETFOCUS <bGfocus> ]      ;
             [ ON LOSTFOCUS <bLfocus> ]     ;
             [ ON OTHER MESSAGES <bOther> ] ;
             [ ON EXIT <bExit> ]            ;
             [ HELPID <nHelpId> ]           ;
          => ;
   <oDlg> := HDialog():New( Iif(<.res.>,WND_DLG_RESOURCE,WND_DLG_NORESOURCE), ;
                   <nStyle>,<x>,<y>,<width>,<height>,<cTitle>,<oFont>,;
                   <bInit>,<bExit>,<bSize>, <bPaint>,<bGfocus>,<bLfocus>,;
                   <bOther>,<.lClipper.>,<oBmp>,<ico>,<.lExitOnEnter.>,<nHelpId>,<Resid>,<.lExitOnEsc.>,<bColor>,<.lnoClosable.> )

#xcommand ACTIVATE WINDOW <oWnd> ;
               [<lNoShow: NOSHOW>] ;
               [<lMaximized: MAXIMIZED>] ;
               [<lMinimized: MINIMIZED>] ;
               [<lCenter: CENTER>]       ;
               [ ON ACTIVATE <bInit> ]   ;
           => ;
      <oWnd>:Activate( !<.lNoShow.>, <.lMaximized.>, <.lMinimized.>, <.lCenter.>, <bInit> )

#xcommand CENTER WINDOW <oWnd> ;
	=>;
        <oWnd>:Center()

#xcommand MAXIMIZE WINDOW <oWnd> ;
	=>;
        <oWnd>:Maximize()

#xcommand MINIMIZE WINDOW <oWnd> ;
	=>;
        <oWnd>:Minimize()

#xcommand RESTORE WINDOW <oWnd> ;
	=>;
        <oWnd>:Restore()

#xcommand SHOW WINDOW <oWnd> ;
	=>;
        <oWnd>:Show()

#xcommand HIDE WINDOW <oWnd> ;
	=>;
        <oWnd>:Hide()

#xcommand ACTIVATE DIALOG <oDlg>       ;
             [ <lNoModal: NOMODAL> ]   ;
             [<lMaximized: MAXIMIZED>] ;
             [<lMinimized: MINIMIZED>] ;
             [<lCenter: CENTER>]       ;
             [ ON ACTIVATE <bInit> ]   ;
          => ;
          <oDlg>:Activate( <.lNoModal.>, <.lMaximized.>, <.lMinimized.>, <.lCenter.>, <bInit> )

#xcommand MENU FROM RESOURCE OF <oWnd> ON <id1> ACTION <b1>  ;
                                 [ ON <idn> ACTION <bn> ]    ;
          => ;
   <oWnd>:aEvents := \{ \{ 0,<id1>, <{b1}> \} [ , \{ 0,<idn>, <{bn}> \} ] \}

#xcommand DIALOG ACTIONS OF <oWnd> ON <id1>,<id2> ACTION <b1>      ;
                                 [ ON <idn1>,<idn2> ACTION <bn> ]  ;
          => ;
   <oWnd>:aEvents := \{ \{ <id1>,<id2>, <b1> \} [ , \{ <idn1>,<idn2>, <bn> \} ] \}


// Commands for control handling

// Contribution ATZCT" <atzct@obukhov.kiev.ua
#xcommand @ <x>,<y> PROGRESSBAR <oPBar>       ;
            [ OF <oWnd> ]                       ;
            [ ID <nId> ]                        ;
            [ SIZE <nWidth>,<nHeight> ]         ;
            [ BARWIDTH <maxpos> ]               ;
            [ QUANTITY <nRange> ]               ;
            =>                                  ;
            <oPBar> :=  HProgressBar():New( <oWnd>,<nId>,<x>,<y>,<nWidth>, ;
                       <nHeight>,<maxpos>,<nRange> );
            [; hwg_SetCtrlName( <oPBar>,<(oPBar)> )]


#xcommand REDEFINE progress  [ <oBmp>  ] ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ TOOLTIP <ctoolt> ]       ;
            [ MAXPOS <mpos> ] ;
            [ RANGE <nRange> ] ;
          => ;
    [<oBmp> := ] HProgressBar():Redefine( <oWnd>,<nId>,<mpos>,<nRange>, ;
        <bInit>,<bSize>,,<ctoolt> );
    [; hwg_SetCtrlName( <oBmp>,<(oBmp)> )]


#xcommand ADD STATUS [<oStat>] [ TO <oWnd> ] ;
            [ ID <nId> ]           ;
            [ ON INIT <bInit> ]    ;
            [ ON SIZE <bSize> ]    ;
            [ ON PAINT <bDraw> ]   ;
            [ STYLE <nStyle> ]     ;
            [ FONT <oFont> ]       ;
            [ PARTS <aparts,...> ] ;
          => ;
            [ <oStat> := ] HStatus():New( <oWnd>,<nId>,<nStyle>,<oFont>,\{<aparts>\},<bInit>,;
                                          <bSize>,<bDraw> );
            [; hwg_SetCtrlName( <oStat>,<(oStat)> )]


#xcommand @ <x>,<y> SAY [ <oSay> CAPTION ] <caption> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [<lTransp: TRANSPARENT>]   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oSay> := ] HStatic():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
        <height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<ctoolt>,<color>,<bcolor>,<.lTransp.> );
    [; hwg_SetCtrlName( <oSay>,<(oSay)> )]

#xcommand REDEFINE SAY   [ <oSay> CAPTION ] <cCaption>   ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [<lTransp: TRANSPARENT>]   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oSay> := ] HStatic():Redefine( <oWnd>,<nId>,<cCaption>, ;
        <oFont>,<bInit>,<bSize>,<bDraw>,<ctoolt>,<color>,<bcolor>,<.lTransp.> );
    [; hwg_SetCtrlName( <oSay>,<(oSay)> )]


#xcommand @ <x>,<y> BITMAP [ <oBmp> SHOW ] <bitmap> ;
            [<res: FROM RESOURCE>]     ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ BACKCOLOR <bcolor> ]     ;
            [ STRETCH <nStretch>]      ;
            [<lTransp: TRANSPARENT> [COLOR  <trcolor> ]] ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON CLICK <bClick> ]      ;
            [ ON DBLCLICK <bDblClick> ];
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oBmp> := ] HSayBmp():New( <oWnd>,<nId>,<x>,<y>,<width>, ;
        <height>,<bitmap>,<.res.>,<bInit>,<bSize>,<ctoolt>,<bClick>,<bDblClick>,<.lTransp.>,<nStretch>,<trcolor>,<bcolor> );
    [; hwg_SetCtrlName( <oBmp>,<(oBmp)> )]

#xcommand REDEFINE BITMAP [ <oBmp> SHOW ] <bitmap> ;
            [<res: FROM RESOURCE>]     ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oBmp> := ] HSayBmp():Redefine( <oWnd>,<nId>,<bitmap>,<.res.>, ;
        <bInit>,<bSize>,<ctoolt> );
    [; hwg_SetCtrlName( <oBmp>,<(oBmp)> )]

#xcommand @ <x>,<y> ICON [ <oIco> SHOW ] <icon> ;
            [<res: FROM RESOURCE>]     ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON CLICK <bClick> ]      ;
            [ ON DBLCLICK <bDblClick> ];
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oIco> := ] HSayIcon():New( <oWnd>,<nId>,<x>,<y>,<width>, ;
        <height>,<icon>,<.res.>,<bInit>,<bSize>,<ctoolt>,,<bClick>,<bDblClick> );
    [; hwg_SetCtrlName( <oIco>,<(oIco)> )]

#xcommand REDEFINE ICON [ <oIco> SHOW ] <icon> ;
            [<res: FROM RESOURCE>]     ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oIco> := ] HSayIcon():Redefine( <oWnd>,<nId>,<icon>,<.res.>, ;
        <bInit>,<bSize>,<ctoolt> );
    [; hwg_SetCtrlName( <oIco>,<(oIco)> )]

#xcommand @ <x>,<y> IMAGE [ <oImage> SHOW ] <image> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ TOOLTIP <ctoolt> ]       ;
            [ TYPE <ctype>     ]       ;
          => ;
    [<oImage> := ] HSayFImage():New( <oWnd>,<nId>,<x>,<y>,<width>, ;
        <height>,<image>,<bInit>,<bSize>,<ctoolt>,<ctype> );
    [; hwg_SetCtrlName( <oImage>,<(oImage)> )]

#xcommand REDEFINE IMAGE [ <oImage> SHOW ] <image> ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oImage> := ] HSayFImage():Redefine( <oWnd>,<nId>,<image>, ;
        <bInit>,<bSize>,<ctoolt> );
    [; hwg_SetCtrlName( <oImage>,<(oImage)> )]


#xcommand @ <x>,<y> LINE [ <oLine> ]   ;
            [ LENGTH <length> ]        ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [<lVert: VERTICAL>]        ;
            [ ON SIZE <bSize> ]        ;
          => ;
    [<oLine> := ] HLine():New( <oWnd>,<nId>,<.lVert.>,<x>,<y>,<length>,<bSize> );
    [; hwg_SetCtrlName( <oLine>,<(oLine)> )]

#xcommand @ <x>,<y> EDITBOX [ <oEdit> CAPTION ] <caption> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ PICTURE <cPicture> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ ON KEYDOWN <bKeyDown>]   ;
            [ ON CHANGE <bChange> ]    ;
            [ STYLE <nStyle> ]         ;
            [<lnoborder: NOBORDER>]    ;
            [<lPassword: PASSWORD>]    ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oEdit> := ] HEdit():New( <oWnd>,<nId>,<caption>,,<nStyle>,<x>,<y>,<width>, ;
                    <height>,<oFont>,<bInit>,<bSize>,<bGfocus>, ;
                    <bLfocus>,<ctoolt>,<color>,<bcolor>,<cPicture>,<.lnoborder.>,,<.lPassword.>, <bKeyDown>, <bChange> );
    [; hwg_SetCtrlName( <oEdit>,<(oEdit)> )]


#xcommand REDEFINE EDITBOX [ <oEdit> ] ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ FONT <oFont> ]           ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oEdit> := ] HEdit():Redefine( <oWnd>,<nId>,,,<oFont>,<bInit>,<bSize>, ;
                   <bGfocus>,<bLfocus>,<ctoolt>,<color>,<bcolor> );
    [; hwg_SetCtrlName( <oEdit>,<(oEdit)> )]

#xcommand @ <x>,<y> RICHEDIT [ <oEdit> TEXT ] <vari> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [<lallowtabs: ALLOWTABS>]  ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ ON CHANGE <bChange>]     ;
            [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oEdit> := ] HRichEdit():New( <oWnd>,<nId>,<vari>,<nStyle>,<x>,<y>,<width>, ;
                    <height>,<oFont>,<bInit>,<bSize>,<bGfocus>, ;
                    <bLfocus>,<ctoolt>,<color>,<bcolor>,<bOther>,<.lallowtabs.>,<bChange> );
    [; hwg_SetCtrlName( <oEdit>,<(oEdit)> )]


#xcommand @ <x>,<y> BUTTON [ <oBut> CAPTION ] <caption> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bClick> ]      ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ IMAGE <oImg> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oBut> := ] HButton():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<bClick>,<ctoolt>,<color>,<bcolor>,<oImg> );
    [; hwg_SetCtrlName( <oBut>,<(oBut)> )]

#xcommand REDEFINE BUTTON [ <oBut> ]   ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ CAPTION <cCaption> ]     ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ FONT <oFont> ]           ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bClick> ]      ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oBut> := ] HButton():Redefine( <oWnd>,<nId>,<oFont>,<bInit>,<bSize>,<bDraw>, ;
                    <bClick>,<ctoolt>,<color>,<bcolor>,<cCaption> );
    [; hwg_SetCtrlName( <oBut>,<(oBut)> )]

#xcommand @ <x>,<y> GROUPBOX [ <oGroup> CAPTION ] <caption> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ FONT <oFont> ]           ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ STYLE <nStyle> ]         ;
          => ;
    [<oGroup> := ] HGroup():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<color>,<bcolor> );
    [; hwg_SetCtrlName( <oGroup>,<(oGroup)> )]

#xcommand @ <x>,<y> TREE [ <oTree> ]   ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ FONT <oFont> ]           ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON CLICK <bClick> ]      ;
            [ STYLE <nStyle> ]         ;
            [<lEdit: EDITABLE>]        ;
            [ BITMAP <aBmp>  [<res: FROM RESOURCE>] [ BITCOUNT <nBC> ] ]  ;
          => ;
    [<oTree> := ] HTree():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<oFont>,<bInit>,<bSize>,<color>,<bcolor>,<aBmp>,<.res.>,<.lEdit.>,<bClick>,<nBC> );
    [; hwg_SetCtrlName( <oTree>,<(oTree)> )]

#xcommand INSERT NODE [ <oNode> CAPTION ] <cTitle>  ;
            TO <oTree>                            ;
            [ AFTER <oPrev> ]                     ;
            [ BEFORE <oNext> ]                    ;
            [ BITMAP <aBmp> ]                     ;
            [ ON CLICK <bClick> ]                 ;
          => ;
    [<oNode> := ] <oTree>:AddNode( <cTitle>,<oPrev>,<oNext>,<bClick>,<aBmp> )

#xcommand @ <x>,<y> TAB [ <oTab> ITEMS ] <aItems> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CHANGE <bChange> ]    ;
            [ ON CLICK <bClick> ]      ;
            [ ON GETFOCUS <bGetFocus> ];
            [ ON LOSTFOCUS <bLostFocus>];
            [ BITMAP <aBmp>  [<res: FROM RESOURCE>] [ BITCOUNT <nBC> ] ]  ;
          => ;
    [<oTab> := ] HTab():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<oFont>,<bInit>,<bSize>,<bDraw>,<aItems>,<bChange>, <aBmp>, <.res.>,<nBC>,;
             <bClick>, <bGetFocus>, <bLostFocus> );
    [; hwg_SetCtrlName( <oTab>,<(oTab)> )]

#xcommand BEGIN PAGE <cname> OF <oTab> ;
          => ;
    <oTab>:StartPage( <cname> )

#ifdef __GTK__

#xcommand BEGIN PAGE <cname> OF <oTab> TOOLTIP <ctooltip>;
          => ;
    <oTab>:StartPage( <cname> , <ctooltip> )

#else

#xcommand BEGIN PAGE <cname> OF <oTab> TOOLTIP <ctooltip>;
          => ;
    <oTab>:StartPage( <cname> , , <ctooltip> )

#endif

#xcommand END PAGE OF <oTab> ;
          => ;
    <oTab>:EndPage()

#xcommand ENDPAGE OF <oTab> ;
          => ;
    <oTab>:EndPage()


#xcommand @ <x>,<y> CHECKBOX [ <oCheck> CAPTION ] <caption> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ INIT <lInit> ]           ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [<lTransp: TRANSPARENT>]   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bClick> ]      ;
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oCheck> := ] HCheckButton():New( <oWnd>,<nId>,<lInit>,,<nStyle>,<x>,<y>, ;
         <width>,<height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<bClick>,<ctoolt>,<color>,<bcolor>,<bGfocus>,<.lTransp.>,<bLfocus> );
    [; hwg_SetCtrlName( <oCheck>,<(oCheck)> )]

#xcommand REDEFINE CHECKBOX [ <oCheck> ] ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ INIT <lInit>    ]        ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bClick> ]      ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oCheck> := ] HCheckButton():Redefine( <oWnd>,<nId>,<lInit>,,<oFont>, ;
          <bInit>,<bSize>,<bDraw>,<bClick>,<ctoolt>,<color>,<bcolor> );
    [; hwg_SetCtrlName( <oCheck>,<(oCheck)> )]


#xcommand RADIOGROUP  ;
          => HRadioGroup():New()

#xcommand GET RADIOGROUP [ <ogr> VAR ] <vari>  ;
          => [<ogr> := ] HRadioGroup():New( <vari>, {|v|Iif(v==Nil,<vari>,<vari>:=v)} )

#xcommand @ <x>,<y> GET RADIOGROUP [ <ogr> VAR ] <vari>  ;
             [ CAPTION  <caption> ];
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ FONT <oFont> ]           ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ STYLE <nStyle> ]         ;
          => [<ogr> := ] HRadioGroup():NewRG( <oWnd>,<nId>,<nStyle>,<vari>,;
                  {|v|Iif(v==Nil,<vari>,<vari>:=v)},<x>,<y>,<width>,<height>,<caption>,<oFont>,;
                  <bInit>,<bSize>,<color>,<bcolor> );;

#xcommand END RADIOGROUP [ SELECTED <nSel> ] ;
          => HRadioGroup():EndGroup( <nSel> )

#xcommand @ <x>,<y> RADIOBUTTON [ <oRadio> CAPTION ] <caption> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bClick> ]      ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
            [<lTransp: TRANSPARENT>]   ;
          => ;
    [<oRadio> := ] HRadioButton():New( <oWnd>,<nId>,<nStyle>,<x>,<y>, ;
         <width>,<height>,<caption>,<oFont>,<bInit>,<bSize>,<bDraw>,<bClick>,<ctoolt>,<color>,<bcolor>,<.lTransp.> );
    [; hwg_SetCtrlName( <oRadio>,<(oRadio)> )]

#xcommand REDEFINE RADIOBUTTON [ <oRadio> ] ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bClick> ]      ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oRadio> := ] HRadioButton():Redefine( <oWnd>,<nId>,<oFont>,<bInit>,<bSize>, ;
          <bDraw>,<bClick>,<ctoolt>,<color>,<bcolor> );
    [; hwg_SetCtrlName( <oRadio>,<(oRadio)> )]


#xcommand @ <x>,<y> COMBOBOX [ <oCombo> ITEMS ] <aItems> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ INIT <nInit> ]           ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CHANGE <bChange> ]    ;
            [ ON GETFOCUS <bWhen> ]    ;
            [ ON LOSTFOCUS <bValid> ]  ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
            [ <edit: EDIT> ]           ;
            [ <text: TEXT> ]           ;
            [ DISPLAYCOUNT <nDisplay>] ;
          => ;
    [<oCombo> := ] HComboBox():New( <oWnd>,<nId>,<nInit>,,<nStyle>,<x>,<y>,<width>, ;
                  <height>,<aItems>,<oFont>,<bInit>,<bSize>,<bDraw>,<bChange>,<ctoolt>,;
                  <.edit.>,<.text.>,<bWhen>,<color>,<bcolor>,<bValid>,<nDisplay> );
    [; hwg_SetCtrlName( <oCombo>,<(oCombo)> )]

#xcommand REDEFINE COMBOBOX [ <oCombo> ITEMS ] <aItems> ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ INIT <nInit>    ]        ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CHANGE <bChange> ]    ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oCombo> := ] HComboBox():Redefine( <oWnd>,<nId>,<nInit>,,<aItems>,<oFont>,<bInit>, ;
             <bSize>,<bDraw>,<bChange>,<ctoolt> );
    [; hwg_SetCtrlName( <oCombo>,<(oCombo)> )]


#xcommand @ <x>,<y> UPDOWN [ <oUpd> INIT ] <nInit> ;
            RANGE <nLower>,<nUpper>    ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ WIDTH <nUpDWidth> ]      ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oUpd> := ] HUpDown():New( <oWnd>,<nId>,<nInit>,,<nStyle>,<x>,<y>,<width>, ;
                    <height>,<oFont>,<bInit>,<bSize>,<bDraw>,<bGfocus>,         ;
                    <bLfocus>,<ctoolt>,<color>,<bcolor>,<nUpDWidth>,<nLower>,<nUpper> );
    [; hwg_SetCtrlName( <oUpd>,<(oUpd)> )]


#xcommand @ <x>,<y> PANEL [ <oPanel> ] ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ BACKCOLOR <bcolor> ]     ;
            [ HSTYLE <oStyle> ]        ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ STYLE <nStyle> ]         ;
          => ;
    [<oPanel> :=] HPanel():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>,<height>,<bInit>,<bSize>,<bDraw>,<bcolor>,<oStyle> );
    [; hwg_SetCtrlName( <oPanel>,<(oPanel)> )]

#xcommand REDEFINE PANEL [ <oPanel> ]  ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ HEIGHT <nHeight> ]       ;
          => ;
    [<oPanel> :=] HPanel():Redefine( <oWnd>,<nId>,<nHeight>,<bInit>,<bSize>,<bDraw> );
    [; hwg_SetCtrlName( <oPanel>,<(oPanel)> )]

#xcommand ADD TOP PANEL [ <oPanel> ] TO <oWnd> ;
            [ ID <nId> ]               ;
            HEIGHT <height>            ;
            [ BACKCOLOR <bcolor> ]     ;
            [ HSTYLE <oStyle> ]        ;
            [ ON INIT <bInit> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ STYLE <nStyle> ]         ;
          => ;
    [<oPanel> :=] HPanel():New( <oWnd>,<nId>,<nStyle>,0,0,<oWnd>:nWidth,<height>,<bInit>,ANCHOR_TOPABS+ANCHOR_LEFTABS+ANCHOR_RIGHTABS,<bDraw>,<bcolor>,<oStyle> );
    [; hwg_SetCtrlName( <oPanel>,<(oPanel)> )]

#xcommand ADD LEFT PANEL [ <oPanel> ] TO <oWnd> ;
            [ ID <nId> ]               ;
            WIDTH <width>              ;
            [ BACKCOLOR <bcolor> ]     ;
            [ HSTYLE <oStyle> ]        ;
            [ ON INIT <bInit> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ STYLE <nStyle> ]         ;
          => ;
    [<oPanel> :=] HPanel():New( <oWnd>,<nId>,<nStyle>,0,0,<width>,<oWnd>:nHeight,<bInit>,ANCHOR_LEFTABS+ANCHOR_TOPABS+ANCHOR_BOTTOMABS,<bDraw>,<bcolor>,<oStyle> );
    [; hwg_SetCtrlName( <oPanel>,<(oPanel)> )]

#xcommand ADD RIGHT PANEL [ <oPanel> ] TO <oWnd> ;
            [ ID <nId> ]               ;
            WIDTH <width>              ;
            [ BACKCOLOR <bcolor> ]     ;
            [ HSTYLE <oStyle> ]        ;
            [ ON INIT <bInit> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ STYLE <nStyle> ]         ;
          => ;
    [<oPanel> :=] HPanel():New( <oWnd>,<nId>,<nStyle>,<oWnd>:nWidth-<width>,0,<width>,<oWnd>:nHeight,<bInit>,ANCHOR_RIGHTABS+ANCHOR_TOPABS+ANCHOR_BOTTOMABS,<bDraw>,<bcolor>,<oStyle> );
    [; hwg_SetCtrlName( <oPanel>,<(oPanel)> )]

#xcommand ADD STATUS PANEL [ <oPanel> ] TO <oWnd> ;
            [ ID <nId> ]               ;
            HEIGHT <height>            ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ FONT <oFont> ]           ;
            [ HSTYLE <oStyle> ]        ;
            [ PARTS <aparts,...> ]     ;
          => ;
    [<oPanel> :=] HPanelSts():New( <oWnd>,<nId>,<height>,<oFont>,<bInit>,<bDraw>,<bcolor>,<oStyle>,\{<aparts>\} );
    [; hwg_SetCtrlName( <oPanel>,<(oPanel)> )]

#xcommand ADD HEADER PANEL [ <oPanel> ] [ TO <oWnd> ] ;
            [ ID <nId> ]               ;
            HEIGHT <height>            ;
            [ TEXTCOLOR <tcolor> ]     ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ FONT <oFont> ]           ;
            [ HSTYLE <oStyle> ]        ;
            [ TEXT <cText> [COORS <xt>[,<yt>] ] ] ;
            [ <lBtnClose: BTN_CLOSE> ] ;
            [ <lBtnMax: BTN_MAXIMIZE> ];
            [ <lBtnMin: BTN_MINIMIZE> ];
          => ;
    [<oPanel> :=] HPanelHea():New( <oWnd>,<nId>,<height>,<oFont>,<bInit>,<bDraw>, ;
       <tcolor>,<bcolor>,<oStyle>,<cText>,<xt>,<yt>,<.lBtnClose.>,<.lBtnMax.>,<.lBtnMin.> );
    [; hwg_SetCtrlName( <oPanel>,<(oPanel)> )]

#xcommand @ <x>,<y> BROWSE [ <oBrw> ]  ;
            [ <lArr: ARRAY> ]          ;
            [ <lDb: DATABASE> ]        ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bEnter> ]      ;
            [ ON RIGHTCLICK <bRClick> ];
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ STYLE <nStyle> ]         ;
            [ <lNoVScr: NO VSCROLL> ]  ;
            [ <lNoBord: NOBORDER> ]    ;
            [ FONT <oFont> ]           ;
            [ <lAppend: APPEND> ]      ;
            [ <lAutoedit: AUTOEDIT> ]  ;
            [ ON UPDATE <bUpdate> ]    ;
            [ ON KEYDOWN <bKeyDown> ]  ;
            [ ON POSCHANGE <bPosChg> ] ;
            [ <lMulti: MULTISELECT> ]  ;
          => ;
    [<oBrw> :=] HBrowse():New( Iif(<.lDb.>,BRW_DATABASE,Iif(<.lArr.>,BRW_ARRAY,0)),;
        <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>,<height>,<oFont>,<bInit>,<bSize>, ;
        <bDraw>,<bEnter>,<bGfocus>,<bLfocus>,<.lNoVScr.>,<.lNoBord.>, <.lAppend.>,;
        <.lAutoedit.>, <bUpdate>, <bKeyDown>, <bPosChg>, <.lMulti.>, <bRClick> );
    [; hwg_SetCtrlName( <oBrw>,<(oBrw)> )]

#xcommand REDEFINE BROWSE [ <oBrw> ]   ;
            [ <lArr: ARRAY> ]          ;
            [ <lDb: DATABASE> ]        ;
            [ <lFlt: FILTER> ]        ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bEnter> ]      ;
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ FONT <oFont> ]           ;
          => ;
    [<oBrw> :=] HBrowse():Redefine( Iif(<.lDb.>,BRW_DATABASE,Iif(<.lArr.>,BRW_ARRAY,Iif(<.lFlt.>,BRW_FILTER,0))),;
        <oWnd>,<nId>,<oFont>,<bInit>,<bSize>,<bDraw>,<bEnter>,<bGfocus>,<bLfocus> );
    [; hwg_SetCtrlName( <oBrw>,<(oBrw)> )]

#xcommand ADD COLUMN <block> TO <oBrw> ;
            [ HEADER <cHeader> ]       ;
            [ TYPE <cType> ]           ;
            [ LENGTH <nLen> ]          ;
            [ DEC <nDec>    ]          ;
            [ <lEdit: EDITABLE> ]      ;
            [ JUSTIFY HEAD <nJusHead> ];
            [ JUSTIFY LINE <nJusLine> ];
            [ PICTURE <cPict> ]        ;
            [ VALID <bValid> ]         ;
            [ ON KEYDOWN <bKeyDown> ]  ;
            [ WHEN <bWhen> ]           ;
            [ ITEMS <aItem> ]          ;
            [ COLORBLOCK <bClrBlck> ]  ;
            [ BHEADCLICK <bHeadClick> ]  ;
          => ;
    <oBrw>:AddColumn( HColumn():New( <cHeader>,<block>,<cType>,<nLen>,<nDec>,<.lEdit.>,;
                      <nJusHead>, <nJusLine>, <cPict>, <{bValid}>, <{bKeyDown}>, <{bWhen}>, <aItem>, <{bClrBlck}>, <{bHeadClick}> ) )

#xcommand INSERT COLUMN <block> TO <oBrw> ;
            [ HEADER <cHeader> ]       ;
            [ TYPE <cType> ]           ;
            [ LENGTH <nLen> ]          ;
            [ DEC <nDec>    ]          ;
            [ <lEdit: EDITABLE> ]      ;
            [ JUSTIFY HEAD <nJusHead> ];
            [ JUSTIFY LINE <nJusLine> ];
            [ PICTURE <cPict> ]        ;
            [ VALID <bValid> ]         ;
            [ ON KEYDOWN <bKeyDown> ]  ;
            [ WHEN <bWhen> ]           ;
            [ ITEMS <aItem> ]          ;
            [ BITMAP <oBmp> ]          ;
            [ COLORBLOCK <bClrBlck> ]  ;
            INTO <nPos>                ;
          => ;
    <oBrw>:InsColumn( HColumn():New( <cHeader>,<block>,<cType>,<nLen>,<nDec>,<.lEdit.>,;
                      <nJusHead>, <nJusLine>, <cPict>, <{bValid}>, <{bKeyDown}>, <{bWhen}>, <aItem>, <oBmp>, <{bClrBlck}> ),<nPos> )

#xcommand @ <x>,<y> BROWSE [ <oBrw> ] FILTER ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bEnter> ]      ;
            [ ON RIGHTCLICK <bRClick> ];
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ STYLE <nStyle> ]         ;
            [ <lNoVScr: NO VSCROLL> ]  ;
            [ <lNoBord: NOBORDER> ]    ;
            [ FONT <oFont> ]           ;
            [ <lAppend: APPEND> ]      ;
            [ <lAutoedit: AUTOEDIT> ]  ;
            [ ON UPDATE <bUpdate> ]    ;
            [ ON KEYDOWN <bKeyDown> ]  ;
            [ ON POSCHANGE <bPosChg> ] ;
            [ <lMulti: MULTISELECT> ]  ;
            [ <lDescend: DESCEND> ]    ; // By Marcelo Sturm (marcelo.sturm@gmail.com)
            [ WHILE <bWhile> ]         ; // By Luiz Henrique dos Santos (luizhsantos@gmail.com)
            [ FIRST <bFirst> ]         ; // By Luiz Henrique dos Santos (luizhsantos@gmail.com)
            [ LAST <bLast> ]           ; // By Marcelo Sturm (marcelo.sturm@gmail.com)
            [ FOR <bFor> ]             ; // By Luiz Henrique dos Santos (luizhsantos@gmail.com)
          => ;
    [<oBrw> :=] HBrwflt():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>,<height>,<oFont>,<bInit>,<bSize>, ;
        <bDraw>,<bEnter>,<bGfocus>,<bLfocus>,<.lNoVScr.>,<.lNoBord.>, <.lAppend.>,;
        <.lAutoedit.>, <bUpdate>, <bKeyDown>, <bPosChg>, <.lMulti.>, <.lDescend.>,;
        <bWhile>, <bFirst>, <bLast>, <bFor>, <bRClick> );
    [; hwg_SetCtrlName( <oBrw>,<(oBrw)> )]

#xcommand @ <x>,<y> GRID <oGrid>        ;
            [ OF <oWnd> ]               ;
            [ ID <nId> ]                ;
            [ STYLE <nStyle> ]          ;
            [ SIZE <width>, <height> ]  ;
            [ FONT <oFont> ]            ;
            [ ON INIT <bInit> ]         ;
            [ ON SIZE <bSize> ]         ;
            [ ON PAINT <bPaint> ]       ;
            [ ON CLICK <bEnter> ]       ;
            [ ON GETFOCUS <bGfocus> ]   ;
            [ ON LOSTFOCUS <bLfocus> ]  ;
            [ ON KEYDOWN <bKeyDown> ]   ;
            [ ON POSCHANGE <bPosChg> ]  ;
            [ ON DISPINFO <bDispInfo> ] ;
            [ ITEMCOUNT <nItemCount> ]  ;
            [ <lNoScroll: NOSCROLL> ]   ;
            [ <lNoBord: NOBORDER> ]     ;
            [ <lNoLines: NOGRIDLINES> ] ;
            [ COLOR <color> ]           ;
            [ BACKCOLOR <bkcolor> ]     ;
            [ <lNoHeader: NO HEADER> ]  ;
            [BITMAP <aBit>];
          => ;
    <oGrid> := HGrid():New( <oWnd>, <nId>, <nStyle>, <x>, <y>, <width>, <height>,;
                            <oFont>, <{bInit}>, <{bSize}>, <{bPaint}>, <{bEnter}>,;
                            <{bGfocus}>, <{bLfocus}>, <.lNoScroll.>, <.lNoBord.>,;
                            <{bKeyDown}>, <{bPosChg}>, <{bDispInfo}>, <nItemCount>,;
                             <.lNoLines.>, <color>, <bkcolor>, <.lNoHeader.> ,<aBit>);
    [; hwg_SetCtrlName( <oGrid>,<(oGrid)> )]

#xcommand ADD COLUMN TO GRID <oGrid>    ;
            [ HEADER <cHeader> ]        ;
            [ WIDTH <nWidth> ]          ;
            [ JUSTIFY HEAD <nJusHead> ] ;
            [ BITMAP <n> ]              ;
          => ;
    <oGrid>:AddColumn( <cHeader>, <nWidth>, <nJusHead> ,<n>)


#xcommand @ <x>,<y> OWNERBUTTON [ <oOwnBtn> ]  ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bPaint> ]      ;
            [ ON CLICK <bClick> ]      ;
            [ HSTYLES <aStyles,...> ]  ;
            [ <flat: FLAT> ]           ;
            [ <enable: DISABLED> ]     ;
            [ TEXT <cText>             ;
                 [ COLOR <color>] [ FONT <font> ] ;
                 [ COORDINATES  <xt>, <yt>, <widtht>, <heightt> ] ;
            ] ;
            [ BITMAP <bmp>  [<res: FROM RESOURCE>] [<ltr: TRANSPARENT> [COLOR  <trcolor> ]] ;
                 [ COORDINATES  <xb>, <yb>, <widthb>, <heightb> ] ;
            ] ;
            [ TOOLTIP <ctoolt> ]    ;
            [ <lCheck: CHECK> ]     ;
          => ;
    [<oOwnBtn> :=] HOWNBUTTON():New( <oWnd>,<nId>,\{<aStyles>\},<x>,<y>,<width>, ;
          <height>,<bInit>,<bSize>,<bPaint>, ;
          <bClick>,<.flat.>, ;
              <cText>,<color>,<font>,<xt>, <yt>,<widtht>,<heightt>, ;
              <bmp>,<.res.>,<xb>,<yb>,<widthb>,<heightb>,<.ltr.>,<trcolor>, <ctoolt>,!<.enable.>,<.lCheck.>,<bcolor> );
    [; hwg_SetCtrlName( <oOwnBtn>,<(oOwnBtn)> )]


#xcommand REDEFINE OWNERBUTTON [ <oOwnBtn> ]  ;
            [ OF <oWnd> ]                     ;
            ID <nId>                          ;
            [ ON INIT <bInit> ]     ;
            [ ON SIZE <bSize> ]     ;
            [ ON PAINT <bPaint> ]   ;
            [ ON CLICK <bClick> ]   ;
            [ <flat: FLAT> ]        ;
            [ TEXT <cText>          ;
                 [ COLOR <color>] [ FONT <font> ] ;
                 [ COORDINATES  <xt>, <yt>, <widtht>, <heightt> ] ;
            ] ;
            [ BITMAP <bmp>  [<res: FROM RESOURCE>] [<ltr: TRANSPARENT>] ;
                 [ COORDINATES  <xb>, <yb>, <widthb>, <heightb> ] ;
            ] ;
            [ TOOLTIP <ctoolt> ]    ;
            [ <enable: DISABLED> ]        ;
          => ;
    [<oOwnBtn> :=] HOWNBUTTON():Redefine( <oWnd>,<nId>, ;
          <bInit>,<bSize>,<bPaint>, ;
          <bClick>,<.flat.>, ;
              <cText>,<color>,<font>,<xt>, <yt>,<widtht>,<heightt>, ;
              <bmp>,<.res.>,<xb>, <yb>,<widthb>,<heightb>,<.ltr.>, <ctoolt>, !<.enable.>);
    [; hwg_SetCtrlName( <oOwnBtn>,<(oOwnBtn)> )]

#xcommand @ <x>,<y> SHADEBUTTON [ <oShBtn> ]  ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ EFFECT <shadeID>  [ PALETTE <palet> ]             ;
                 [ GRANULARITY <granul> ] [ HIGHLIGHT <highl> ] ;
                 [ COLORING <coloring> ] [ SHCOLOR <shcolor> ] ];
            [ ON INIT <bInit> ]     ;
            [ ON SIZE <bSize> ]     ;
            [ ON PAINT <bPaint> ]    ;
            [ ON CLICK <bClick> ]   ;
            [ STYLE <nStyle> ]      ;
            [ <flat: FLAT> ]        ;
            [ <enable: DISABLED> ]  ;
            [ TEXT <cText>          ;
                 [ COLOR <color>] [ FONT <font> ] ;
                 [ COORDINATES  <xt>, <yt> ] ;
            ] ;
            [ BITMAP <bmp>  [<res: FROM RESOURCE>] [<ltr: TRANSPARENT> [COLOR  <trcolor> ]] ;
                 [ COORDINATES  <xb>, <yb>, <widthb>, <heightb> ] ;
            ] ;
            [ TOOLTIP <ctoolt> ]    ;
          => ;
    [<oShBtn> :=] HSHADEBUTTON():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
          <height>,<bInit>,<bSize>,<bPaint>, ;
          <bClick>,<.flat.>, ;
              <cText>,<color>,<font>,<xt>, <yt>, ;
              <bmp>,<.res.>,<xb>,<yb>,<widthb>,<heightb>,<.ltr.>,<trcolor>, ;
              <ctoolt>,!<.enable.>,<shadeID>,<palet>,<granul>,<highl>,<coloring>,<shcolor> );
    [; hwg_SetCtrlName( <oShBtn>,<(oShBtn)> )]

#xcommand @ <x>,<y> DATEPICKER [ <oPick> ]  ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ INIT <dInit> ]           ;
            [ ON INIT <bInit> ]        ;
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ ON CHANGE <bChange> ]    ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oPick> :=] HDatePicker():New( <oWnd>,<nId>,<dInit>,,<nStyle>,<x>,<y>, ;
        <width>,<height>,<oFont>,<bInit>,<bGfocus>,<bLfocus>,<bChange>,<ctoolt>, ;
        <color>,<bcolor> );
    [; hwg_SetCtrlName( <oPick>,<(oPick)> )]

#xcommand @ <x>,<y> DATESELECT [ <oDate> ] ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ FONT <oFont> ]           ;
            [ INIT  <dValue> ]         ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CHANGE <bChange> ]    ;
          => ;
    [<oDate> := ] HDateSelect():New( <oWnd>,<nId>,<x>,<y>,<width>,<height>,<color>,<bcolor>, ;
        <oFont>,<dValue>,,<bLfocus>,<bSize>,<bDraw>,<bChange> );
    [; hwg_SetCtrlName( <oDate>,<(oDate)> )]

#xcommand @ <x>,<y> SPLITTER [ <oSplit> ] ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ HSTYLE <oStyle> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ DIVIDE <aLeft> FROM <aRight> ] ;
            [ LIMITS [<nFrom>][,<nTo>] ]   ;
          => ;
    [<oSplit> :=] HSplitter():New( <oWnd>,<nId>,<x>,<y>,<width>,<height>,<bSize>,<bDraw>,<color>,<bcolor>,<aLeft>,<aRight>,<nFrom>,<nTo>,<oStyle> );
    [; hwg_SetCtrlName( <oSplit>,<(oSplit)> )]


#xcommand PREPARE FONT <oFont>       ;
             NAME <cName>            ;
             [ WIDTH <nWidth> ]      ;
             [ HEIGHT <nHeight> ]    ;
             [ WEIGHT <nWeight> ]    ;
             [ CHARSET <charset> ]   ;
             [ <ita: ITALIC> ]       ;
             [ <under: UNDERLINE> ]  ;
             [ <strike: STRIKEOUT> ] ;
          => ;
    <oFont> := HFont():Add( <cName>, <nWidth>, <nHeight>, <nWeight>, <charset>, ;
                iif( <.ita.>,1,0 ), iif( <.under.>,1,0 ), iif( <.strike.>,1,0 ) )

/* Print commands */

#xcommand START PRINTER DEFAULT    ;
          => ;
    OpenDefaultPrinter(); StartDoc()

/* SAY ... GET system     */

#xcommand @ <x>,<y> GET [ <oEdit> VAR ]  <vari>  ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ PICTURE <cPicture> ]     ;
            [ WHEN  <bGfocus> ]        ;
            [ VALID <bLfocus> ]        ;
            [ ON KEYDOWN <bKeyDown>]   ;
            [ ON CHANGE <bChange> ]    ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [<lPassword: PASSWORD>]    ;
            [ MAXLENGTH <nMaxLength> ] ;
            [ STYLE <nStyle> ]         ;
            [<lnoborder: NOBORDER>]    ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oEdit> := ] HEdit():New( <oWnd>,<nId>,<vari>,               ;
                   {|v|Iif(v==Nil,<vari>,<vari>:=v)},             ;
                   <nStyle>,<x>,<y>,<width>,<height>,<oFont>,<bInit>,<bSize>,  ;
                   <bGfocus>,<bLfocus>,<ctoolt>,<color>,<bcolor>,<cPicture>,<.lnoborder.>,<nMaxLength>,<.lPassword.>,<bKeyDown>,<bChange> );
    [; hwg_SetCtrlName( <oEdit>,<(oEdit)> )]

#xcommand REDEFINE GET [ <oEdit> VAR ] <vari>  ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ PICTURE <cPicture> ]     ;
            [ WHEN  <bGfocus> ]        ;
            [ VALID <bLfocus> ]        ;
            [ MAXLENGTH <nMaxLength> ] ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oEdit> := ] HEdit():Redefine( <oWnd>,<nId>,<vari>, ;
                   {|v|Iif(v==Nil,<vari>,<vari>:=v)},    ;
                   <oFont>,,,<{bGfocus}>,<{bLfocus}>,<ctoolt>,<color>,<bcolor>,<cPicture>,<nMaxLength>,<(vari)> );
    [; hwg_SetCtrlName( <oEdit>,<(oEdit)> )]


#xcommand @ <x>,<y> GET CHECKBOX [ <oCheck> VAR ] <vari>  ;
            CAPTION  <caption>         ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [<lTransp: TRANSPARENT>]   ;
            [ <valid: VALID, ON CLICK> <bClick> ]     ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
            [ WHEN <bWhen> ]           ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON LOSTFOCUS <bLfocus> ] ;
          => ;
    [<oCheck> := ] HCheckButton():New( <oWnd>,<nId>,<vari>,              ;
                    {|v|Iif(v==Nil,<vari>,<vari>:=v)},                   ;
                    <nStyle>,<x>,<y>,<width>,<height>,<caption>,<oFont>, ;
                    <bInit>,<bSize>,,<bClick>,<ctoolt>,<color>,<bcolor>,<bWhen>,<.lTransp.>,<bLfocus> );
    [; hwg_SetCtrlName( <oCheck>,<(oCheck)> )]

#xcommand REDEFINE GET CHECKBOX [ <oCheck> VAR ] <vari>  ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ <valid: VALID, ON CLICK> <bClick> ] ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
            [ WHEN <bWhen> ]           ;
          => ;
    [<oCheck> := ] HCheckButton():Redefine( <oWnd>,<nId>,<vari>, ;
                    {|v|Iif(v==Nil,<vari>,<vari>:=v)},           ;
                    <oFont>,,,,<bClick>,<ctoolt>,<color>,<bcolor>,<bWhen> );
    [; hwg_SetCtrlName( <oCheck>,<(oCheck)> )]

#xcommand @ <x>,<y> GET COMBOBOX [ <oCombo> VAR ] <vari> ;
            ITEMS  <aItems>            ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON CHANGE <bChange> ]    ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
            [ <edit: EDIT> ]           ;
            [ <text: TEXT> ]           ;
            [ WHEN <bWhen> ]           ;
            [ VALID <bValid> ]         ;
            [ DISPLAYCOUNT <nDisplay>] ;
          => ;
    [<oCombo> := ] HComboBox():New( <oWnd>,<nId>,<vari>,    ;
                    {|v|Iif(v==Nil,<vari>,<vari>:=v)},      ;
                    <nStyle>,<x>,<y>,<width>,<height>,      ;
                    <aItems>,<oFont>,<bInit>,<bSize>,,<bChange>,<ctoolt>, ;
                    <.edit.>,<.text.>,<bWhen>,<color>,<bcolor>,<bValid>,<nDisplay> );
    [; hwg_SetCtrlName( <oCombo>,<(oCombo)> )]

#xcommand REDEFINE GET COMBOBOX [ <oCombo> VAR ] <vari> ;
            ITEMS  <aItems>            ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ ON CHANGE <bChange> ]    ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
            [ WHEN <bWhen> ]           ;
          => ;
    [<oCombo> := ] HComboBox():Redefine( <oWnd>,<nId>,<vari>, ;
                    {|v|Iif(v==Nil,<vari>,<vari>:=v)},        ;
                    <aItems>,<oFont>,,,,<bChange>,<ctoolt>, <bWhen> );
    [; hwg_SetCtrlName( <oCombo>,<(oCombo)> )]

#xcommand @ <x>,<y> CHECKLIST [ <oChk> ] ;
            [ ITEMS <aItems> ]           ;
            [ OF <oWnd> ]                ;
            [ ID <nId> ]                 ;
            [ SIZE <width>, <height> ]   ;
            [ COLOR <color> ]            ;
            [ BACKCOLOR <bcolor> ]       ;
            [ ON INIT <bInit> ]          ;
            [ ON SIZE <bSize> ]          ;
            [ ON CHANGE <bChange> ]      ;
            [ STYLE <nStyle> ]           ;
            [ FONT <oFont> ]             ;
            [ TOOLTIP <ctoolt> ]         ;
            [ VALID <bValid> ]           ;
          => ;
    [<oChk> := ] HCheckList():New( <oWnd>,<nId>,<nStyle>,    ;
                    <x>,<y>,<width>,<height>,                ;
                    <aItems>,<oFont>,<bInit>,<bSize>,,       ;
                    <bChange>,<ctoolt>,<color>,<bcolor>,<bValid> );
    [; hwg_SetCtrlName( <oChk>, <(oChk)> )]

#xcommand @ <x>,<y> GET UPDOWN [ <oUpd> VAR ]  <vari>  ;
            RANGE <nLower>,<nUpper>    ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ WIDTH <nUpDWidth> ]      ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ WHEN  <bGfocus> ]        ;
            [ VALID <bLfocus> ]        ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oUpd> := ] HUpDown():New( <oWnd>,<nId>,<vari>,               ;
                   {|v|Iif(v==Nil,<vari>,<vari>:=v)},              ;
                    <nStyle>,<x>,<y>,<width>,<height>,<oFont>,<bInit>,<bSize>,,  ;
                    <bGfocus>,<bLfocus>,<ctoolt>,<color>,<bcolor>, ;
                    <nUpDWidth>,<nLower>,<nUpper> );
    [; hwg_SetCtrlName( <oUpd>,<(oUpd)> )]


#xcommand @ <x>,<y> GET DATEPICKER [ <oPick> VAR ] <vari> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ WHEN <bGfocus> ]         ;
            [ VALID <bLfocus> ]        ;
            [ ON INIT <bInit> ]        ;
            [ ON CHANGE <bChange> ]    ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oPick> :=] HDatePicker():New( <oWnd>,<nId>,<vari>,    ;
                    {|v|Iif(v==Nil,<vari>,<vari>:=v)},      ;
                    <nStyle>,<x>,<y>,<width>,<height>,      ;
                    <oFont>,<bInit>,<bGfocus>,<bLfocus>,<bChange>,<ctoolt>,<color>,<bcolor> );
    [; hwg_SetCtrlName( <oPick>,<(oPick)> )]

#xcommand @ <x>,<y> GET DATESELECT [ <oDate> VAR ] <vari> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ FONT <oFont> ]           ;
            [ VALID <bLfocus> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CHANGE <bChange> ]    ;
          => ;
    [<oDate> := ] HDateSelect():New( <oWnd>,<nId>,<x>,<y>,<width>,<height>,<color>,<bcolor>, ;
        <oFont>,<vari>,{|v|Iif(v==Nil,<vari>,<vari>:=v)},<bLfocus>,<bSize>,<bDraw>,<bChange> );
    [; hwg_SetCtrlName( <oDate>,<(oDate)> )]

#xcommand SAY <value> TO <oDlg> ID <id> ;
          => ;
    hwg_SetDlgItemText( <oDlg>:handle, <id>, <value> )

/*   Menu system     */

#xcommand MENU [ OF <oWnd> ] [ ID <nId> ] [ TITLE <cTitle> ] ;
          => ;
    Hwg_BeginMenu( <oWnd>, <nId>, <cTitle> )

#xcommand CONTEXT MENU <oMenu> ;
          => ;
    <oMenu> := Hwg_ContextMenu()

#xcommand ENDMENU           => Hwg_EndMenu()

#xcommand MENUITEM <item> [ ID <nId> ]    ;
            ACTION <act>                  ;
            [ BITMAP <bmp> ]               ; //ADDED by Sandro Freire
            [<res: FROM RESOURCE>]        ; //true use image from resource
            [ ACCELERATOR <flag>, <key> ] ;
            [<lDisabled: DISABLED>]       ;
          => ;
    Hwg_DefineMenuItem( <item>, <nId>, <{act}>, <.lDisabled.>, <flag>, <key>, <bmp>, <.res.>, .f. )

#xcommand MENUITEMCHECK <item> [ ID <nId> ]    ;
            [ ACTION <act> ]              ;
            [ ACCELERATOR <flag>, <key> ] ;
            [<lDisabled: DISABLED>]       ;
          => ;
    Hwg_DefineMenuItem( <item>, <nId>, <{act}>, <.lDisabled.>, <flag>, <key>,,, .t. )

#xcommand MENUITEMBITMAP <oMain>  ID <nId> ;
            BITMAP <bmp>                  ;
            [<res: FROM RESOURCE>]         ;
          => ;
    Hwg_InsertBitmapMenu( <oMain>:menu, <nId>, <bmp>, <.res.>)

#xcommand ACCELERATOR <flag>, <key>       ;
            [ ID <nId> ]                  ;
            ACTION <act>                  ;
          => ;
    Hwg_DefineAccelItem( <nId>, <{act}>, <flag>, <key> )

#xcommand SEPARATOR         => Hwg_DefineMenuItem()

#xcommand SET TIMER <oTimer> [ OF <oWnd> ] [ ID <id> ] ;
             VALUE <value> ACTION <bAction> [<lOnce: ONCE>];
          => ;
    <oTimer> := HTimer():New( <oWnd>, <id>, <value>, <bAction>, <.lOnce.> );
    [; hwg_SetCtrlName( <oTimer>,<(oTimer)> )]


#xcommand SET KEY [<lGlobal: GLOBAL>] <nctrl>,<nkey> [ OF <oDlg> ] TO [ <func> ] ;
          => ;
    hwg_SetDlgKey( <oDlg>, <nctrl>, <nkey>, <{func}>, <.lGlobal.> )

/*             */
#xcommand @ <x>,<y> GRAPH [ <oGraph> DATA ] <aData> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON SIZE <bSize> ]        ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oGraph> := ] HGraph():New( <oWnd>,<nId>,<aData>,<x>,<y>,<width>, ;
        <height>,<oFont>,<bSize>,<ctoolt>,<color>,<bcolor> );
    [; hwg_SetCtrlName( <oGraph>,<(oGraph)> )]

/* open an .dll resource */
#xcommand SET RESOURCES TO [<cName1>]  =>  hwg_LoadResource( <cName1> )

/* open a binary container as resource */
#xcommand SET RESOURCES CONTAINER TO [<cName>]  =>  hwg_SetResContainer( <cName> )

// Addded by jamaj
#xcommand DEFAULT <uVar1> := <uVal1> ;
               [, <uVarN> := <uValN> ] => ;
                  <uVar1> := IIf( <uVar1> == nil, <uVal1>, <uVar1> ) ;;
                [ <uVarN> := IIf( <uVarN> == nil, <uValN>, <uVarN> ); ]

#xcommand @ <x>,<y> GET IPADDRESS [ <oIp> VAR ] <vari> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ BACKCOLOR <bcolor> ]     ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ ON GETFOCUS <bGfocus> ]      ;
            [ ON LOSTFOCUS <bLfocus> ]     ;
          => ;
    [<oIp> := ] HIpEdit():New( <oWnd>,<nId>,<vari>,{|v| iif(v==Nil,<vari>,<vari>:=v)},<nStyle>,<x>,<y>,<width>,<height>,<oFont>, <bGfocus>, <bLfocus> );
    [; hwg_SetCtrlName( <oIp>,<(oIp)> )]

#define ISOBJECT(c)    ( Valtype(c) == "O" )
#define ISBLOCK(c)    ( Valtype(c) == "B" )
#define ISARRAY(c)    ( Valtype(c) == "A" )
#define ISNUMBER(c)    ( Valtype(c) == "N" )
#define ISLOGICAL(c)    ( Valtype(c) == "L" )


/* Commands for PrintDos Class*/

#xcommand SET PRINTER TO <oPrinter> OF <oPtrObj>     ;
           => ;
      <oPtrObj>:=Printdos():New( <oPrinter>)

#xcommand @ <x>,<y> PSAY  <vari>  ;
            [ PICTURE <cPicture> ] OF <oPtrObj>   ;
          => ;
          <oPtrObj>:Say(<x>, <y>, <vari>, <cPicture>)

#xcommand  EJECT OF <oPtrObj> => <oPtrObj>:Eject()

#xcommand  END PRINTER <oPtrObj> => <oPtrObj>:End()

/* Hprinter */

#xcommand  INIT PRINTER <oPrinter>   ;
             [ NAME <cPrinter> ]     ;
             [ <lPixel: PIXEL> ]     ;
          =>  ;
          <oPrinter> := HPrinter():New( <cPrinter>,!<.lPixel.> )

#xcommand  INIT DEFAULT PRINTER <oPrinter>   ;
             [ <lPixel: PIXEL> ]             ;
          =>  ;
          <oPrinter> := HPrinter():New( "",!<.lPixel.> )

/*
Command for MonthCalendar Class
Added by Marcos Antonio Gambeta
*/

#xcommand @ <x>,<y> MONTHCALENDAR [ <oMonthCalendar> ] ;
            [ OF <oWnd> ]                              ;
            [ ID <nId> ]                               ;
            [ SIZE <nWidth>,<nHeight> ]                ;
            [ INIT <dInit> ]                           ;
            [ ON INIT <bInit> ]                        ;
            [ ON CHANGE <bChange> ]                    ;
            [ STYLE <nStyle> ]                         ;
            [ FONT <oFont> ]                           ;
            [ TOOLTIP <cTooltip> ]                     ;
            [ < notoday : NOTODAY > ]                  ;
            [ < notodaycircle : NOTODAYCIRCLE > ]      ;
            [ < weeknumbers : WEEKNUMBERS > ]          ;
          => ;
    [<oMonthCalendar> :=] HMonthCalendar():New( <oWnd>,<nId>,<dInit>,<nStyle>,;
        <x>,<y>,<nWidth>,<nHeight>,<oFont>,<bInit>,<bChange>,<cTooltip>,;
        <.notoday.>,<.notodaycircle.>,<.weeknumbers.>);
    [; hwg_SetCtrlName( <oMonthCalendar>,<(oMonthCalendar)> )]

/*By Vitor Maclung */
// Commands for Listbox handling

#xcommand @ <x>,<y> LISTBOX [ <oListbox> ITEMS ] <aItems> ;
             [ OF <oWnd> ]                 ;
             [ ID <nId> ]                  ;
             [ INIT <nInit> ]              ;
             [ SIZE <width>, <height> ]    ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]           ;
             [ ON SIZE <bSize> ]           ;
             [ ON PAINT <bDraw> ]          ;
             [ ON CHANGE <bChange> ]       ;
             [ STYLE <nStyle> ]            ;
             [ FONT <oFont> ]              ;
             [ TOOLTIP <ctoolt> ]          ;
             [ ON GETFOCUS <bGfocus> ]     ;
             [ ON LOSTFOCUS <bLfocus> ]    ;
             [ ON KEYDOWN <bKeyDown> ]  ;
             [ ON DBLCLICK <bDblClick> ];
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
          => ;
          [<oListbox> := ] HListBox():New( <oWnd>,<nId>,<nInit>,,<nStyle>,<x>,<y>,<width>, ;
             <height>,<aItems>,<oFont>,<bInit>,<bSize>,<bDraw>,<bChange>,<ctoolt>,;
             <color>,<bcolor>, <bGfocus>,<bLfocus>,<bKeyDown>,<bDblClick>,<bOther> ) ;;
          [; hwg_SetCtrlName( <oListbox>,<(oListbox)> )]

#xcommand REDEFINE LISTBOX [ <oListbox> ITEMS ] <aItems> ;
             [ OF <oWnd> ]                 ;
             ID <nId>                      ;
             [ INIT <nInit>    ]           ;
             [ ON INIT <bInit> ]           ;
             [ ON SIZE <bSize> ]           ;
             [ ON PAINT <bDraw> ]          ;
             [ ON CHANGE <bChange> ]       ;
             [ FONT <oFont> ]              ;
             [ TOOLTIP <ctoolt> ]          ;
             [ ON GETFOCUS <bGfocus> ]     ;
             [ ON LOSTFOCUS <bLfocus> ]    ;
             [ ON KEYDOWN <bKeyDown> ]     ;
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
          => ;
          [<oListbox> := ] HListBox():Redefine( <oWnd>,<nId>,<nInit>,,<aItems>,<oFont>,<bInit>, ;
             <bSize>,<bDraw>,<bChange>,<ctoolt>,<bGfocus>,<bLfocus>, <bKeyDown>,<bOther> ) ;;
          [; hwg_SetCtrlName( <oListbox>,<(oListbox)> )]

#xcommand @ <x>,<y> GET LISTBOX [ <oListbox> VAR ]  <vari> ;
             ITEMS  <aItems>            ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ ON CHANGE <bChange> ]    ;
             [ STYLE <nStyle> ]         ;
             [ FONT <oFont> ]           ;
             [ TOOLTIP <ctoolt> ]       ;
             [ WHEN <bGFocus> ]         ;
             [ VALID <bLFocus> ]        ;
             [ ON KEYDOWN <bKeyDown> ]  ;
             [ ON DBLCLICK <bDblClick> ];
             [[ON OTHER MESSAGES <bOther>][ON OTHERMESSAGES <bOther>]] ;
          => ;
          [<oListbox> := ] HListBox():New( <oWnd>,<nId>,<vari>,;
             {|v|Iif(v==Nil,<vari>,<vari>:=v)},;
             <nStyle>,<x>,<y>,<width>,<height>,<aItems>,<oFont>,<bInit>,<bSize>,<bDraw>, ;
             <bChange>,<ctoolt>,<color>,<bcolor>,<bGFocus>,<bLFocus>,<bKeyDown>,<bDblClick>,<bOther>);;
          [; hwg_SetCtrlName( <oListbox>,<(oListbox)> )]

/* Add Sandro R. R. Freire */

#xcommand SPLASH [<osplash> TO]  <oBitmap> ;
            [<res: FROM RESOURCE>]         ;
            [ TIME <otime> ]               ;
            [WIDTH <w>];
            [HEIGHT <h>];
          => ;
   [ <osplash> := ] HSplash():Create(<oBitmap>,<otime>,<.res.>,<w>,<h>);

// Nice Buttons by Luiz Rafael
#xcommand @ <x>,<y> NICEBUTTON [ <oBut> CAPTION ] <caption> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ ON INIT <bInit> ]        ;
            [ ON CLICK <bClick> ]      ;
            [ STYLE <nStyle> ]         ;
            [ EXSTYLE <nStyleEx> ]         ;
            [ TOOLTIP <ctoolt> ]       ;
            [ RED <r> ] ;
            [ GREEN <g> ];
            [ BLUE <b> ];
          => ;
    [<oBut> := ] HNicebutton():New( <oWnd>,<nId>,<nStyle>,<nStyleEx>,<x>,<y>,<width>, ;
             <height>,<bInit>,<bClick>,<caption>,<ctoolt>,<r>,<g>,<b> );
    [; hwg_SetCtrlName( <oBut>,<(oBut)> )]


#xcommand REDEFINE NICEBUTTON [ <oBut> CAPTION ] <caption> ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ ON INIT <bInit> ]        ;
            [ ON CLICK <bClick> ]      ;
            [ EXSTYLE <nStyleEx> ]         ;
            [ TOOLTIP <ctoolt> ]       ;
            [ RED <r> ] ;
            [ GREEN <g> ];
            [ BLUE <b> ];
          => ;
    [<oBut> := ] HNicebutton():Redefine( <oWnd>,<nId>,<nStyleEx>, ;
             <bInit>,<bClick>,<caption>,<ctoolt>,<r>,<g>,<b> );
    [; hwg_SetCtrlName( <oBut>,<(oBut)> )]

// trackbar control (deprecated)
#xcommand @ <x>,<y> TRACKBAR [ <oTrackBar> ]  ;
            [ OF <oWnd> ]                 ;
            [ ID <nId> ]                  ;
            [ SIZE <width>, <height> ]    ;
            [ RANGE <nLow>,<nHigh> ]      ;
            [ INIT <nInit> ]              ;
            [ ON INIT <bInit> ]           ;
            [ ON SIZE <bSize> ]           ;
            [ ON PAINT <bDraw> ]          ;
            [ ON CHANGE <bChange> ]       ;
            [ ON DRAG <bDrag> ]           ;
            [ STYLE <nStyle> ]            ;
            [ TOOLTIP <cTooltip> ]        ;
            [ < vertical : VERTICAL > ]   ;
            [ < autoticks : AUTOTICKS > ] ;
            [ < noticks : NOTICKS > ]     ;
            [ < both : BOTH > ]           ;
            [ < top : TOP > ]             ;
            [ < left : LEFT > ]           ;
          => ;
    [<oTrackBar> :=] HTrackBar():New( <oWnd>,<nId>,<nInit>,<nStyle>,<x>,<y>,      ;
        <width>,<height>,<bInit>,<bSize>,<bDraw>,<cTooltip>,<bChange>,<bDrag>,<nLow>,<nHigh>,<.vertical.>,;
        Iif(<.autoticks.>,1,Iif(<.noticks.>,16,0)), ;
        Iif(<.both.>,8,Iif(<.top.>.or.<.left.>,4,0)) );
    [; hwg_SetCtrlName( <oTrackBar>,<(oTrackBar)> )]

// trackbar control
#xcommand @ <x>,<y> TRACK [ <oTrack> ]    ;
            [ OF <oWnd> ]                 ;
            [ ID <nId> ]                  ;
            [ SIZE <width>, <height> ]    ;
            [ COLOR <color> ]             ;
            [ BACKCOLOR <bcolor> ]        ;
            [ SLIDER SIZE <nsize> ]       ;
            [ SLIDER HSTYLE <ostyles> ]   ;
            [ BAR HSTYLE <ostyleb> ]      ;
            [<laxis: AXIS>]               ;
            [ ON SIZE <bSize> ]           ;
            [ ON PAINT <bDraw> ]          ;
          => ;
    [<oTrack> :=] HTrack():New( <oWnd>,<nId>,<x>,<y>, ;
        <width>,<height>,<bSize>,<bDraw>,<color>, <bcolor>, <nsize>, <ostyleb>, <ostyles>, <.laxis.> );
    [; hwg_SetCtrlName( <oTrack>,<(oTrack)> )]

// animation control
#xcommand @ <x>,<y>  ANIMATION [ <oAnimation> ] ;
            [ OF <oWnd> ]                       ;
            [ ID <nId> ]                        ;
            [ STYLE <nStyle> ]                  ;
            [ SIZE <nWidth>, <nHeight> ]        ;
            [ FILE <cFile> ]                    ;
            [ < autoplay: AUTOPLAY > ]          ;
            [ < center : CENTER > ]             ;
            [ < transparent: TRANSPARENT > ]    ;
	=>;
    [<oAnimation> :=] HAnimation():New( <oWnd>,<nId>,<nStyle>,<x>,<y>, ;
        <nWidth>,<nHeight>,<cFile>,<.autoplay.>,<.center.>,<.transparent.>);
    [; hwg_SetCtrlName( <oAnimation>,<(oAnimation)> )]

//Contribution   Ricardo de Moura Marques
#xcommand @ <X>, <Y>, <X2>, <Y2> RECT <oRect> [<lPress: PRESS>] [OF <oWnd>] [RECT_STYLE <nST>];
          => <oRect> := HRect():New(<oWnd>,<X>,<Y>,<X2>,<Y2>, <.lPress.>, <nST> );
          [; hwg_SetCtrlName( <oRect>,<(oRect)> )]

//New Control
#xcommand @ <x>,<y> SAY [ <oSay> CAPTION ] <caption> ;
            [ OF <oWnd> ]              ;
            LINK <cLink>               ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [<lTransp: TRANSPARENT>]   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ STYLE <nStyle> ]         ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
            [ VISITCOLOR <vcolor> ]    ;
            [ LINKCOLOR <lcolor> ]     ;
            [ HOVERCOLOR <hcolor> ]    ;
          => ;
    [<oSay> := ] HStaticLink():New( <oWnd>, <nId>, <nStyle>, <x>, <y>, <width>, ;
        <height>, <caption>, <oFont>, <bInit>, <bSize>, <bDraw>, <ctoolt>, ;
        <color>, <bcolor>, <.lTransp.>, <cLink>, <vcolor>, <lcolor>, <hcolor> );
    [; hwg_SetCtrlName( <oSay>,<(oSay)> )]


#xcommand REDEFINE SAY [ <oSay> CAPTION ] <cCaption>      ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            LINK <cLink>               ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [<lTransp: TRANSPARENT>]   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
            [ VISITCOLOR <vcolor> ]    ;
            [ LINKCOLOR <lcolor> ]     ;
            [ HOVERCOLOR <hcolor> ]    ;
          => ;
    [<oSay> := ] HStaticLink():Redefine( <oWnd>, <nId>, <cCaption>, ;
        <oFont>, <bInit>, <bSize>, <bDraw>, <ctoolt>, <color>, <bcolor>,;
        <.lTransp.>, <cLink>, <vcolor>, <lcolor>, <hcolor> );
    [; hwg_SetCtrlName( <oSay>,<(oSay)> )]

#xcommand TOOLBUTTON  <O> ;
          ID <nId> ;
          [ BITMAP <nBitIp> ];
          [ STYLE <bstyle> ];
          [ STATE <bstate>];
          [ TEXT <ctext> ] ;
          [ TOOLTIP <c> ];
          [ MENU <d>];
           ON CLICK <bclick>;
          =>;
          <O>:AddButton(<nBitIp>,<nId>,<bstate>,<bstyle>,<ctext>,<bclick>,<c>,<d>)

#xcommand @ <x>,<y> TOOLBAR [ <oTool> ] ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ STYLE <nStyle> ]         ;
            [ ITEMS <aItems> ] ;
          => ;
    [<oTool> := ] Htoolbar():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, <height>,,,,,,,,,,,<aItems>  );
    [; hwg_SetCtrlName( <oTool>,<(oTool)> )]

#xcommand REDEFINE TOOLBAR  <oTool>    ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ITEM <aitem>];
          => ;
    [<oTool> := ] Htoolbar():Redefine( <oWnd>,<nId>,,  ,<bInit>,<bSize>,<bDraw>, , , , ,<aitem> );
    [; hwg_SetCtrlName( <oTool>,<(oTool)> )]

#xcommand CREATE MENUBAR <o> => <o> := \{ \}

#xcommand MENUBARITEM  <oWnd> CAPTION <c> ON <id1> ACTION <b1>      ;
          => ;
          Aadd( <oWnd>, \{ <c>, <id1>, <{b1}> \})

#xcommand ADD TOOLBUTTON  <O> ;
          ID <nId> ;
          [ BITMAP <nBitIp> ];
          [ STYLE <bstyle> ];
          [ STATE <bstate>];
          [ TEXT <ctext> ] ;
          [ TOOLTIP <c> ];
          [ MENU <d>];
           ON CLICK <bclick>;
          =>;
          aadd(<O> ,\{<nBitIp>,<nId>,<bstate>,<bstyle>,,<ctext>,<bclick>,<c>,<d>,\})

#xcommand ADDROW TO GRID <oGrid>    ;
            [ HEADER <cHeader> ]        ;
            [ JUSTIFY HEAD <nJusHead> ] ;
            [ BITMAP <n> ]              ;
            [ HEADER <cHeadern> ]        ;
            [ JUSTIFY HEAD <nJusHeadn> ] ;
            [ BITMAP <nn> ]              ;
            => <oGrid>:AddRow(<cHeader>,<nJusHead>,<n>) [;<oGrid>:AddRow(<cHeadern>,<nJusHeadn>,<nn>)]


#xcommand REDEFINE TAB  <oTab>  ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
          => ;
    [<oTab> := ] Htab():Redefine( <oWnd>,<nId>,,  ,<bInit>,<bSize>,<bDraw>, ,<color>,<bcolor>, , );
    [; hwg_SetCtrlName( <oTab>,<(oTab)> )]


#xcommand REDEFINE STATUS  <oSay>  ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ PARTS <bChange,...> ]    ;
          => ;
    [<oSay> := ] HStatus():Redefine( <oWnd>,<nId>,,  ,<bInit>,<bSize>,<bDraw>, , , , ,\{<bChange>\} ) ;
    [; hwg_SetCtrlName( <oSay>,<(oSay)> )]


#xcommand REDEFINE GRID  <oSay>  ;
            [ OF <oWnd> ]              ;
            ID <nId>                   ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ITEM <aitem>];
          => ;
    [<oSay> := ] HGRIDex():Redefine( <oWnd>,<nId>,,  ,<bInit>,<bSize>,<bDraw>, , , , ,<aitem> );
    [; hwg_SetCtrlName( <oSay>,<(oSay)> )]


#xcommand @ <x>,<y> PAGER [ <oTool> ] ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ STYLE <nStyle> ]         ;
            [ <lVert: VERTICAL> ] ;
          => ;
    [<oTool> := ] HPager():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, <height>,,,,,,,,,<.lVert.>);
    [; hwg_SetCtrlName( <oTool>,<(oTool)> )]

#xcommand @ <x>,<y> REBAR [ <oTool> ] ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ STYLE <nStyle> ]         ;
          => ;
    [<oTool> := ] HREBAR():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, <height>,,,,,,,,);
    [; hwg_SetCtrlName( <oTool>,<(oTool)> )]

#xcommand ADDBAND <hWnd> to <opage> ;
          [BACKCOLOR <b> ] [FORECOLOR <f>] ;
          [STYLE <nstyle>] [TEXT <t>] ;
          => <opage>:ADDBARColor(<hWnd>,<f>,<b>,<t>,<nstyle>)

#xcommand ADDBAND <hWnd> to <opage> ;
          [BITMAP <b> ]  ;
          [STYLE <nstyle>] [TEXT <t>] ;
          => <opage>:ADDBARBITMAP(<hWnd>,<b>,<t>,<nstyle>)


#xcommand @ <x>, <y>  SHAPE [<oShape>] [OF <oWnd>] ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ BORDERWIDTH <nBorder> ]  ;
             [ CURVATURE <nCurvature>]  ;
             [ COLOR <tcolor> ]         ;
             [ BACKCOLOR <bcolor> ]     ;
             [ BORDERSTYLE <nbStyle>]   ;
             [ FILLSTYLE <nfStyle>]     ;
             [ BACKSTYLE <nbackStyle>]  ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
          => ;
          [ <oShape> := ] HShape():New(<oWnd>, <nId>, <x>, <y>, <width>, <height>, ;
             <nBorder>, <nCurvature>, <nbStyle>,<nfStyle>, <tcolor>, <bcolor>, <bSize>,<bInit>,<nbackStyle>);
          [; hwg_SetCtrlName( <oShape>,<(oShape)> )]

#xcommand @ <x>,<y> HCEDIT [ <oTEdit> ] ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON GETFOCUS <bGfocus> ]  ;
            [ ON LOSTFOCUS <bLfocus> ] ;
            [ STYLE <nStyle> ]         ;
            [ <lNoVScr: NO VSCROLL> ]  ;
            [ <lNoBord: NO BORDER> ]   ;
            [ FONT <oFont> ]           ;
          => ;
    [<oTEdit> :=] HCEdit():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>,<height>, ;
       <oFont>,<bInit>,<bSize>,<bDraw>,<color>,<bcolor>,<bGfocus>,<bLfocus>, ;
       <.lNoVScr.>,<.lNoBord.> );
    [; hwg_SetCtrlName( <oTEdit>,<(oTEdit)> )]

#xcommand @ <x>,<y> LENTA [ <oLenta> ] ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bClick> ]      ;
            [ FONT <oFont> ]           ;
            [ ITEMS <aItems> ]         ;
            [ ITEMSIZE <nItemSize> ]   ;
            [ HSTYLES <aItemStyle> ]   ;
          => ;
    [<oLenta> := ] HLenta():New( <oWnd>,<nId>,<x>,<y>,<width>, ;
        <height>,<oFont>,<bSize>,<bDraw>,<bClick>,<color>,<bcolor>,<aItems>,<nItemSize>,<aItemStyle> );
    [; hwg_SetCtrlName( <oLenta>,<(oLenta)> )]

#xcommand @ <x>,<y> BOARD [ <oBoard> ] ;
            [ OF <oWnd> ]              ;
            [ ID <nId> ]               ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON INIT <bInit> ]        ;
            [ ON SIZE <bSize> ]        ;
            [ ON PAINT <bDraw> ]       ;
            [ FONT <oFont> ]           ;
            [ TOOLTIP <ctoolt> ]       ;
          => ;
    [<oBoard> := ] HBoard():New( <oWnd>,<nId>,<x>,<y>,<width>, ;
        <height>,<oFont>,<bInit>,<bSize>,<bDraw>,<ctoolt>,<color>,<bcolor> );
    [; hwg_SetCtrlName( <oBoard>,<(oBoard)> )]

#xcommand @ <x>,<y> DRAWN [ <oDrawn> ] ;
            [ OF <oWnd> ]              ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ HSTYLES <aStyles> ]      ;
            [ TEXT <cText> ]           ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bClick> ]      ;
            [ ON CHANGESTATE <bChg> ]  ;
            [ FONT <oFont> ]           ;
          => ;
    [<oDrawn> := ] HDrawn():New( <oWnd>,<x>,<y>,<width>,<height>,<color>,<bcolor>, ;
        <aStyles>,<cText>,<oFont>,<bDraw>,<bClick>,<bChg> );
    [; hwg_SetCtrlName( <oDrawn>,<(oDrawn)> )]

#xcommand @ <x>,<y> DRAWN CHECK [ <oDrawn> ] ;
            [ OF <oWnd> ]              ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ HSTYLES <aStyles> ]      ;
            [ TEXT <cText> ]           ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bClick> ]      ;
            [ ON CHANGESTATE <bChg> ]  ;
            [ FONT <oFont> ]           ;
          => ;
    [<oDrawn> := ] HDrawnCheck():New( <oWnd>,<x>,<y>,<width>,<height>,<color>,<bcolor>, ;
        <aStyles>,<cText>,<oFont>,<bDraw>,<bClick>,<bChg> );
    [; hwg_SetCtrlName( <oDrawn>,<(oDrawn)> )]

#xcommand @ <x>,<y> DRAWN RADIO [ <oDrawn> ] ;
            [ OF <oWnd> ]              ;
            GROUP <xGroup>             ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ HSTYLES <aStyles> ]      ;
            [ TEXT <cText> ]           ;
            [ INIT <lInit> ]           ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bClick> ]      ;
            [ ON CHANGESTATE <bChg> ]  ;
            [ FONT <oFont> ]           ;
          => ;
    [<oDrawn> := ] HDrawnRadio():New( <oWnd>,<x>,<y>,<width>,<height>,<color>,<bcolor>, ;
        <aStyles>,<cText>,<oFont>,<bDraw>,<bClick>,<bChg>,<xGroup>,<lInit> );
    [; hwg_SetCtrlName( <oDrawn>,<(oDrawn)> )]

#xcommand @ <x>,<y> DRAWN TRACK [ <oTrack> ]    ;
            [ OF <oWnd> ]                 ;
            [ SIZE <width>, <height> ]    ;
            [ COLOR <color> ]             ;
            [ BACKCOLOR <bcolor> ]        ;
            [ SLIDER SIZE <nsize> ]       ;
            [ SLIDER HSTYLE <ostyles> ]   ;
            [ BAR HSTYLE <ostyleb> ]      ;
            [<laxis: AXIS>]               ;
            [ ON PAINT <bDraw> ]          ;
          => ;
    [<oTrack> :=] HDrawnTrack():New( <oWnd>,<x>,<y>, ;
        <width>,<height>,<bDraw>,<color>, <bcolor>, <nsize>, <ostyleb>, <ostyles>, <.laxis.> );
    [; hwg_SetCtrlName( <oTrack>,<(oTrack)> )]

#xcommand @ <x>,<y> DRAWN EDIT [ <oEdit> CAPTION ] <caption> ;
            [ OF <oWnd> ]              ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CHANGESTATE <bChg> ]  ;
            [ FONT <oFont> ]           ;
            [ PICTURE <cPicture> ]     ;
          => ;
    [<oEdit> := ] HDrawnEdit():New( <oWnd>,<x>,<y>,<width>,<height>,<color>,<bcolor>, ;
        <oFont>,<caption>,<cPicture>,<bDraw>,<bChg> );
    [; hwg_SetCtrlName( <oEdit>,<(oEdit)> )]

#xcommand @ <x>,<y> DRAWN LENTA [ <oLenta> ] ;
            [ OF <oWnd> ]              ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CLICK <bClick> ]      ;
            [ FONT <oFont> ]           ;
            [ ITEMS <aItems> ]         ;
            [ ITEMSIZE <nItemSize> ]   ;
            [ HSTYLES <aItemStyle> ]   ;
          => ;
    [<oLenta> := ] HDrawnLenta():New( <oWnd>,<x>,<y>,<width>, ;
        <height>,<oFont>,<bDraw>,<bClick>,<color>,<bcolor>,<aItems>,<nItemSize>,<aItemStyle> );
    [; hwg_SetCtrlName( <oLenta>,<(oLenta)> )]

#xcommand @ <x>,<y> DRAWN COMBO [ <oDrawn> ITEMS ] <aItems> ;
            [ OF <oWnd> ]              ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ HSTYLES <aStyles> ]      ;
            [ INIT  <xValue> ]         ;
            [ <lText: TEXT> ]          ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CHANGE <bChange> ]    ;
            [ ON CHANGESTATE <bChg> ]  ;
            [ FONT <oFont> ]           ;
            [ DISPLAYCOUNT <nRows>]    ;
          => ;
    [<oDrawn> := ] HDrawnCombo():New( <oWnd>,<x>,<y>,<width>,<height>,<color>,<bcolor>, ;
        <aStyles>,<oFont>,<aItems>,<xValue>,<.lText.>,<bDraw>,<bChange>,<bChg>,<nRows> );
    [; hwg_SetCtrlName( <oDrawn>,<(oDrawn)> )]

#xcommand @ <x>,<y> DRAWN UPDOWN [ <oDrawn> ] ;
            [ OF <oWnd> ]              ;
            [ SIZE <width>, <height> ] ;
            [ INIT <xInit> ]           ;
            [ ARRAY <arr> ]            ;
            [ RANGE <nLower>,<nUpper>] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ HSTYLES <aStyles> ]      ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CHANGESTATE <bChg> ]  ;
            [ FONT <oFont> ]           ;
          => ;
    [<oDrawn> := ] HDrawnUpDown():New( <oWnd>,<x>,<y>,<width>,<height>,<color>,<bcolor>, ;
        <aStyles>,<oFont>,<xInit>,<nLower>,<nUpper>,<bDraw>,<bChg>,<arr> );
    [; hwg_SetCtrlName( <oDrawn>,<(oDrawn)> )]

#xcommand @ <x>,<y> DRAWN BROWSE [ <oDrawn> ] ;
            [ OF <oWnd> ]              ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CHANGESTATE <bChg> ]  ;
            [ FONT <oFont> ]           ;
            [ <lVscroll: VSCROLL> ]    ;
            [ <lHscroll: HSCROLL> ]    ;
          => ;
    [<oDrawn> := ] HDrawnBrw():New( <oWnd>,<x>,<y>,<width>,<height>,<color>,<bcolor>, ;
        <oFont>,<bDraw>,<bChg>,<.lVscroll.>,<.lHscroll.> );
    [; hwg_SetCtrlName( <oDrawn>,<(oDrawn)> )]

#xcommand @ <x>,<y> DRAWN DATE [ <oDrawn> ] ;
            [ OF <oWnd> ]              ;
            [ SIZE <width>, <height> ] ;
            [ COLOR <color> ]          ;
            [ BACKCOLOR <bcolor> ]     ;
            [ HSTYLES <aStyles> ]      ;
            [ FONT <oFont> ]           ;
            [ INIT  <dValue> ]         ;
            [ ON PAINT <bDraw> ]       ;
            [ ON CHANGE <bChange> ]    ;
            [ ON CHANGESTATE <bChg> ]  ;
          => ;
    [<oDrawn> := ] HDrawnDate():New( <oWnd>,<x>,<y>,<width>,<height>,<color>,<bcolor>, ;
        <aStyles>,<oFont>,<dValue>,<bDraw>,<bChange>,<bChg> );
    [; hwg_SetCtrlName( <oDrawn>,<(oDrawn)> )]

#xcommand @ <x>,<y> CHART [ <oChart> ]       ;
            TYPE <nType>                     ;
            ITEMS <aData>                    ;
            [ TITLE <cTitle> ]               ;
            [ OF <oWnd> ]                    ;
            [ ID <nId> ]                     ;
            [ SIZE <width>, <height> ]       ;
            [ STYLE <nStyle> ]               ;
            [ FONT <oFont> ]                 ;
            [ COLOR <tcolor> ]               ;
            [ BACKCOLOR <bcolor> ]           ;
            [ COLORS <aColors> ]             ;
            [ <nogrid: NOGRID> ]             ;
            [ <novalue: NOVALUE> ]           ;
          => ;
    [<oChart> := ] HChart():New( <oWnd>, <nId>, <nStyle>,       ;
                    <x>, <y>, <width>, <height>,                ;
                    <nType>, <aData>, <cTitle>, <oFont>,        ;
                    , , , <tcolor>, <bcolor>, <aColors>,        ;
                    !<.nogrid.>, !<.novalue.> )

#xcommand @ <x>,<y> WEBCHART [ <oChart> ]       ;
              TYPE <nType>                       ;
              ITEMS <aData>                      ;
              [ TITLE <cTitle> ]                 ;
              [ COLORS <aColors> ]               ;
              [ OF <oWnd> ]                      ;
              [ ID <nId> ]                       ;
              [ SIZE <width>, <height> ]         ;
              [ STYLE <nStyle> ]                 ;
              [ <light: LIGHT> ]                 ;
          => ;
    [<oChart> := ] HWebChart():New( <oWnd>, <nId>, <nStyle>, ;
                    <x>, <y>, <width>, <height>,             ;
                    <nType>, <aData>, <cTitle>, <aColors>,   ;
                    , !<.light.> )

/* ================= EOF of guilib.ch ==================== */
