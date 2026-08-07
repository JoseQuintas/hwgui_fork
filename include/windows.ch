/*
 *$Id$
 */

// HBMK_HAS_* are automatically created by HBMK when use HBC files, no extra setup

#define WM_CREATE                       1
#define WM_DESTROY                      2
#define WM_MOVE                         3
#define WM_SIZE                         5
#define WM_ACTIVATE                     6
#define WM_SETFOCUS                     7
#define WM_KILLFOCUS                    8
#define WM_ENABLE                       10
#define WM_SETREDRAW                    11
#define WM_SETTEXT                      12
#define WM_GETTEXT                      13
#define WM_GETTEXTLENGTH                14
#define WM_PAINT                        15
#define WM_CLOSE                        16   // 0x0010

#define WM_ERASEBKGND                   20   // 0x0014
#define WM_ENDSESSION                   22   // 0x0016
#define WM_ACTIVATEAPP                  28
#define WM_GETMINMAXINFO                36   // 0x0024
#define WM_NEXTDLGCTL                   40   // 0x0028
#define WM_DRAWITEM                     43   // 0x002B

#define WM_MEASUREITEM                  0x002C
#define WM_SETFONT                      48   // 0x0030

#define WM_WINDOWPOSCHANGING            70   // 0x0046

#define WM_NOTIFY                       78   // 0x004E
#define WM_HELP                         83
#define WM_SETICON                      128    // 0x0080

#define WM_NCCREATE                     129
#define WM_NCDESTROY                    130
#define WM_NCCALCSIZE                   131
#define WM_NCHITTEST                    132
#define WM_NCPAINT                      133
#define WM_NCACTIVATE                   134
#define WM_GETDLGCODE                   135

#define WM_KEYDOWN                      256    // 0x0100
#define WM_KEYUP                        257    // 0x0101
#define WM_CHAR                         258    // 0x0102

#define WM_SYSKEYDOWN                   260    // 0x0104
#define WM_SYSKEYUP                     261    // 0x0105
   // #define WM_SYSCHAR                      = &H106

#define WM_INITDIALOG                   272
#define WM_COMMAND                      273
#define WM_SYSCOMMAND                   274
#define WM_TIMER                        275
#define WM_HSCROLL                      276
#define WM_VSCROLL                      277

#define WM_INITMENU                     278    //= $0116
#define WM_INITMENUPOPUP                279    //= $0117
#define WM_MENUSELECT                   287    //= $011F

#define WM_MENUCHAR                     288    //= $0120

#define WM_ENTERIDLE                    289
#define WM_CHANGEUISTATE                295   //0x127
#define WM_UPDATEUISTATE                296   //0x128

#define WM_CTLCOLORMSGBOX               306     // 0x0132
#define WM_CTLCOLOREDIT                 307     // 0x0133
#define WM_CTLCOLORLISTBOX              308     // 0x0134
#define WM_CTLCOLORBTN                  309     // 0x0135
#define WM_CTLCOLORDLG                  310     // 0x0136
#define WM_CTLCOLORSCROLLBAR            311     // 0x0137
#define WM_CTLCOLORSTATIC               312     // 0x0138

#define WM_MOUSEMOVE                    512    // 0x0200
#define WM_LBUTTONDOWN                  513    // 0x0201
#define WM_LBUTTONUP                    514    // 0x0202
#define WM_LBUTTONDBLCLK                515    // 0x0203
#define WM_RBUTTONDOWN                  516    // 0x0204
#define WM_RBUTTONUP                    517    // 0x0205
#define WM_MBUTTONUP	                520    // 0x0208
#define WM_PARENTNOTIFY                 528    // 0x0210
#define WM_MDICREATE                    544     // 0x0220
#define WM_MDIDESTROY                   545     // 0x0221
#define WM_MDIACTIVATE                  546     // 0x0222
#define WM_MDIRESTORE                   547     // 0x0223
#define WM_MDINEXT                      548     // 0x0224
#define WM_MDIMAXIMIZE                  549     // 0x0225
#define WM_MDITILE                      550     // 0x0226
#define WM_MDICASCADE                   551     // 0x0227
#define WM_MDIICONARRANGE               552     // 0x0228
#define WM_MDIGETACTIVE                 553     // 0x0229
#define WM_MDISETMENU                   560     // 0x0230
#define WM_ENTERSIZEMOVE                561     // 0x0231
#define WM_EXITSIZEMOVE                 562     // 0x0232

#define WM_CUT                          768     // 0x0300
#define WM_COPY                         769     // 0x0301
#define WM_PASTE                        770     // 0x0302
#define WM_CLEAR                        771     // 0x0303

#define WM_USER                        1024    // 0x0400

#define SC_MINIMIZE                   61472   // 0xF020
#define SC_MAXIMIZE                   61488   // 0xF030
#define SC_CLOSE                      61536   // 0xF060
#define SC_RESTORE                    61728   // 0xF120

/*
* CONSTANTS TO   WM_CHANGEUISTATE
*/
#define UIS_CLEAR          2
#define UIS_INITIALIZE     3
#define UISF_HIDEACCEL     2
#define UISF_HIDEFOCUS     3

/*
 * Dialog Box Command IDs
 */

#define IDOK                1
#define IDCANCEL            2
#define IDABORT             3
#define IDRETRY             4
#define IDIGNORE            5
#define IDYES               6
#define IDNO                7

#define DS_ABSALIGN         1        // 0x01L
#define DS_SYSMODAL         2        // 0x02L
#define DS_SETFOREGROUND    512      // 0x200L
#define DS_CENTER           2048     // 0x0800L
#define DS_MODALFRAME       0x80

/*
 * Static Control Notification Codes
 */
#define STN_CLICKED    0
#define STN_DBLCLK     1
#define STN_ENABLE     3

/*
 * User Button Notification Codes
 */
#define BN_CLICKED          0
#define BN_PAINT            1
#define BN_HILITE           2
#define BN_UNHILITE         3
#define BN_DISABLE          4
#define BN_DOUBLECLICKED    5
#define BN_PUSHED           BN_HILITE
#define BN_UNPUSHED         BN_UNHILITE
#define BN_DBLCLK           BN_DOUBLECLICKED
#define BN_SETFOCUS         6
#define BN_KILLFOCUS        7

/*
 * Edit Control Notification Codes
 */
#define EN_SETFOCUS         256    // 0x0100
#define EN_KILLFOCUS        512    // 0x0200
#define EN_CHANGE           768    // 0x0300
#define EN_UPDATE           1024   // 0x0400
#define EN_ERRSPACE         1280   // 0x0500
#define EN_MAXTEXT          1281   // 0x0501
#define EN_HSCROLL          1537   // 0x0601
#define EN_VSCROLL          1538   // 0x0602

#define EN_SELCHANGE        1794   // 0x0702
#define EN_PROTECTED        1796   // 0x0702

/*
 * Combo Box messages
 */

#define CB_GETEDITSEL               320
#define CB_LIMITTEXT                321
#define CB_SETEDITSEL               322
#define CB_ADDSTRING                323
#define CB_DELETESTRING             324
#define CB_DIR                      325
#define CB_GETCOUNT                 326
#define CB_GETCURSEL                327
#define CB_GETLBTEXT                328
#define CB_GETLBTEXTLEN             329
#define CB_INSERTSTRING             330
#define CB_RESETCONTENT             331
#define CB_FINDSTRING               332
#define CB_SELECTSTRING             333
#define CB_SETCURSEL                334
#define CB_SETITEMHEIGHT            0x0153
#define CB_GETITEMHEIGHT            0x0154

/* Brush Styles */
#define BS_SOLID            0
#define BS_NULL             1
#define BS_HOLLOW           BS_NULL
#define BS_HATCHED          2
#define BS_PATTERN          3
#define BS_INDEXED          4
#define BS_DIBPATTERN       5
#define BS_DIBPATTERNPT     6
#define BS_PATTERN8X8       7
#define BS_DIBPATTERN8X8    8
#define BS_MONOPATTERN      9

/* Pen Styles */
#define PS_SOLID            0
#define PS_DASH             1       /* -------  */
#define PS_DOT              2       /* .......  */
#define PS_DASHDOT          3       /* _._._._  */
#define PS_DASHDOTDOT       4       /* _.._.._  */
#define PS_NULL             5
#define PS_INSIDEFRAME      6
#define PS_USERSTYLE        7
#define PS_ALTERNATE        8
#define PS_STYLE_MASK       15

#define COLOR_SCROLLBAR                 0
#define COLOR_BACKGROUND                1
#define COLOR_ACTIVECAPTION             2
#define COLOR_INACTIVECAPTION           3
#define COLOR_MENU                      4
#define COLOR_WINDOW                    5
#define COLOR_WINDOWFRAME               6
#define COLOR_MENUTEXT                  7
#define COLOR_WINDOWTEXT                8
#define COLOR_CAPTIONTEXT               9
#define COLOR_ACTIVEBORDER              10
#define COLOR_INACTIVEBORDER            11
#define COLOR_APPWORKSPACE              12
#define COLOR_HIGHLIGHT                 13
#define COLOR_HIGHLIGHTTEXT             14
#define COLOR_BTNFACE                   15
#define COLOR_BTNSHADOW                 16
#define COLOR_GRAYTEXT                  17
#define COLOR_BTNTEXT                   18
#define COLOR_INACTIVECAPTIONTEXT       19
#define COLOR_BTNHIGHLIGHT              20

#define COLOR_3DDKSHADOW                21
#define COLOR_3DLIGHT                   22
#define COLOR_INFOTEXT                  23
#define COLOR_INFOBK                    24

#define COLOR_HOTLIGHT                  26
#define COLOR_GRADIENTACTIVECAPTION     27
#define COLOR_GRADIENTINACTIVECAPTION   28

#define COLOR_DESKTOP                   COLOR_BACKGROUND
#define COLOR_3DFACE                    COLOR_BTNFACE
#define COLOR_3DSHADOW                  COLOR_BTNSHADOW
#define COLOR_3DHIGHLIGHT               COLOR_BTNHIGHLIGHT
#define COLOR_3DHILIGHT                 COLOR_BTNHIGHLIGHT
#define COLOR_BTNHILIGHT                COLOR_BTNHIGHLIGHT

/*
 * DrawText() Format Flags
 */
#define DT_TOP                      0
#define DT_LEFT                     0
#define DT_CENTER                   1
#define DT_RIGHT                    2
#define DT_VCENTER                  4
#define DT_BOTTOM                   8
#define DT_WORDBREAK                16
#define DT_SINGLELINE               32
#define DT_EXPANDTABS               64
#define DT_TABSTOP                  128
#define DT_NOCLIP                   256
#define DT_EXTERNALLEADING          512
#define DT_CALCRECT                 1024
#define DT_NOPREFIX                 2048
#define DT_INTERNAL                 4096

#define DT_EDITCONTROL              8192
#define DT_PATH_ELLIPSIS            16384
#define DT_END_ELLIPSIS             32768
#define DT_MODIFYSTRING             65536
#define DT_RTLREADING               131072
#define DT_WORD_ELLIPSIS            262144
#define DT_NOFULLWIDTHCHARBREAK     524288
#define DT_HIDEPREFIX               1048576
#define DT_PREFIXONLY               2097152

/*
 * Scroll Bar Commands
 */
#define SB_HORZ             0
#define SB_VERT             1
#define SB_CTL              2
#define SB_BOTH             3
#define SB_LINEUP           0
#define SB_LINELEFT         0
#define SB_LINEDOWN         1
#define SB_LINERIGHT        1
#define SB_PAGEUP           2
#define SB_PAGELEFT         2
#define SB_PAGEDOWN         3
#define SB_PAGERIGHT        3
#define SB_THUMBPOSITION    4
#define SB_THUMBTRACK       5
#define SB_TOP              6
#define SB_LEFT             6
#define SB_BOTTOM           7
#define SB_RIGHT            7
#define SB_ENDSCROLL        8

/*
 * Edit Control Styles
 */
#define ES_LEFT             0
#define ES_CENTER           1
#define ES_RIGHT            2
#define ES_MULTILINE        4
#define ES_UPPERCASE        8
#define ES_LOWERCASE        16
#define ES_PASSWORD         32
#define ES_AUTOVSCROLL      64
#define ES_AUTOHSCROLL      128
#define ES_NOHIDESEL        256
#define ES_OEMCONVERT       1024
#define ES_READONLY         2048       // 0x0800L
#define ES_WANTRETURN       4096       // 0x1000L
#define ES_NUMBER           8192       // 0x2000L
#define ES_NUMINVERT        16384      // 0x4000
#define ES_CLEARTYPE        512        // 0x0200

/*
 * DatePicker Control Styles
*/

#define DTS_SHOWNONE        2          // 0x0002

/*
 * Window Styles
 */

  #define WS_OVERLAPPED       0
#define WS_POPUP            2147483648 // 0x80000000L
#define WS_CHILD            1073741824 // 0x40000000L
#define WS_MINIMIZE         536870912  // 0x20000000L
#define WS_VISIBLE          268435456  // 0x10000000L
#define WS_DISABLED         134217728  // 0x08000000L
#define WS_CLIPSIBLINGS     67108864   // 0x04000000L
#define WS_CLIPCHILDREN     33554432
#define WS_MAXIMIZE         16777216   // 0x01000000L
#define WS_CAPTION          12582912   // 0x00C00000L

#define WS_BORDER           8388608    // 0x00800000L
#define WS_VSCROLL          2097152    // 0x00200000L
#define WS_HSCROLL          1048576    // 0x00100000L

#define WS_DLGFRAME         4194304    // 0x00400000L
#define WS_EX_STATICEDGE    131072     // 0x00020000L
#define WS_SYSMENU          524288     // 0x00080000L
#define WS_THICKFRAME       262144     // 0x00040000L
#define WS_GROUP            131072     // 0x00020000L
#define WS_TABSTOP          65536      // 0x00010000L
#define WS_MINIMIZEBOX      131072     // 0x00020000L
#define WS_MAXIMIZEBOX      65536      // 0x00010000L
#define WS_SIZEBOX          WS_THICKFRAME
#define WS_OVERLAPPEDWINDOW WS_OVERLAPPED + WS_CAPTION + WS_SYSMENU + WS_THICKFRAME + WS_MINIMIZEBOX + WS_MAXIMIZEBOX

#define WS_EX_DLGMODALFRAME     1      // 0x00000001L
#define WS_EX_NOPARENTNOTIFY    4      // 0x00000004L
#define WS_EX_TOPMOST           8      // 0x00000008L
#define WS_EX_ACCEPTFILES      16      // 0x00000010L
#define WS_EX_TRANSPARENT      32      // 0x00000020L
#define WS_EX_TOOLWINDOW      128

#define RDW_INVALIDATE          1      // 0x0001
#define RDW_INTERNALPAINT       2      // 0x0002
#define RDW_ERASE               4      // 0x0004
#define RDW_VALIDATE            8      // 0x0008
#define RDW_NOINTERNALPAINT     16     // 0x0010
#define RDW_NOERASE             32     // 0x0020
#define RDW_NOCHILDREN          64     // 0x0040
#define RDW_ALLCHILDREN         128    // 0x0080
#define RDW_UPDATENOW           256    // 0x0100
#define RDW_ERASENOW            512    // 0x0200
#define RDW_FRAME              1024    // 0x0400
#define RDW_NOFRAME            2048    // 0x0800

/*
 * Window States
 */

#define WA_INACTIVE               0
#define WA_ACTIVE                 1
#define WA_CLICKACTIVE            2

/*
 * Static Control Constants
 */

#define SS_LEFT                   0    // 0x00000000L
#define SS_CENTER                 1    // 0x00000001L
#define SS_RIGHT                  2    // 0x00000002L
#define SS_ICON                   3    // 0x00000003L
#define SS_BLACKRECT              4    // 0x00000004L
#define SS_GRAYRECT               5    // 0x00000005L
#define SS_WHITERECT              6    // 0x00000006L
#define SS_BLACKFRAME             7    // 0x00000007L
#define SS_GRAYFRAME              8    // 0x00000008L
#define SS_WHITEFRAME             9    // 0x00000009L
#define SS_USERITEM              10    // 0x0000000AL
#define SS_SIMPLE                11    // 0x0000000BL
#define SS_LEFTNOWORDWRAP        12    // 0x0000000CL
#define SS_OWNERDRAW             13    // 0x0000000DL
#define SS_BITMAP                14    // 0x0000000EL
#define SS_ENHMETAFILE           15    // 0x0000000FL
#define SS_ETCHEDHORZ            16    // 0x00000010L
#define SS_ETCHEDVERT            17    // 0x00000011L
#define SS_ETCHEDFRAME           18    // 0x00000012L
#define SS_TYPEMASK              31    // 0x0000001FL
#define SS_NOTIFY               256    // 0x00000100L
#define SS_CENTERIMAGE          512    // 0x00000200L
#define SS_RIGHTJUST           1024    // 0x00000400L
#define SS_REALSIZEIMAGE       2048    // 0x00000800L
#define SS_SUNKEN              4096    // 0x00001000L

/*
 * Status bar Constants
 */
#define SB_SETTEXT              (WM_USER+1)
#define SB_GETTEXT              (WM_USER+2)
#define SB_GETTEXTLENGTH        (WM_USER+3)
#define SB_SETPARTS             (WM_USER+4)
#define SB_GETPARTS             (WM_USER+6)
#define SB_GETBORDERS           (WM_USER+7)
#define SB_SETMINHEIGHT         (WM_USER+8)
#define SB_SIMPLE               (WM_USER+9)
#define SB_GETRECT              (WM_USER+10)
#define SB_SETICON              (WM_USER+15)

/*
 * Button Control Styles
 */
#define BS_PUSHBUTTON       0       // 0x00000000L
#define BS_DEFPUSHBUTTON    1       // 0x00000001L
#define BS_CHECKBOX         2       // 0x00000002L
#define BS_AUTOCHECKBOX     3       // 0x00000003L
#define BS_RADIOBUTTON      4       // 0x00000004L
#define BS_3STATE           5       // 0x00000005L
#define BS_AUTO3STATE       6       // 0x00000006L
#define BS_GROUPBOX         7       // 0x00000007L
#define BS_USERBUTTON       8       // 0x00000008L
#define BS_AUTORADIOBUTTON  9       // 0x00000009L
#define BS_OWNERDRAW        11      // 0x0000000BL
#define BS_LEFTTEXT         32      // 0x00000020L

#define BS_SPLITBUTTON      12        // 0x0000000C
#define BS_COMMANDLINK      14        // 0x0000000E

#define BCM_SETNOTE         5641     // 0x00001609

/*
 * Key State Masks for Mouse Messages
 */
#define MK_LBUTTON          1       // 0x0001
#define MK_RBUTTON          2       // 0x0002
#define MK_SHIFT            4       // 0x0004
#define MK_CONTROL          8       // 0x0008
#define MK_MBUTTON          16      // 0x0010
#define MK_XBUTTON1         32      // 0x0020
#define MK_XBUTTON2         64      // 0x0040

/* Ternary raster operations */

#define SRCCOPY             13369376   /* 0x00CC0020  dest = source          */
#define SRCPAINT            0          /* 0x00EE0086  dest = source OR dest  */
#define SRCAND              8913094    /* 0x008800C6  dest = source AND dest */
   // #define SRCINVERT           0          /* 0x00660046  dest = source XOR dest */
   // #define SRCERASE            0x00440328 /* dest = source AND (NOT dest )   */
   // #define NOTSRCCOPY          0x00330008 /* dest = (NOT source)             */
   // #define NOTSRCERASE         0x001100A6 /* dest = (NOT src) AND (NOT dest) */
#define MERGECOPY           12583114      /* 0x00C000CA dest = (source AND pattern) */
#define MERGEPAINT          12255782      /* 0x00BB0226 dest = (NOT source) OR dest */
   // #define PATCOPY             0x00F00021 /* dest = pattern                  */
   // #define PATPAINT            0x00FB0A09 /* dest = DPSnoo                   */
   // #define PATINVERT           0x005A0049 /* dest = pattern XOR dest         */
   // #define DSTINVERT           0x00550009 /* dest = (NOT dest)               */
   // #define BLACKNESS           0x00000042 /* dest = BLACK                    */
   // #define WHITENESS           0x00FF0062 /* dest = WHITE                    */

#define PSN_SETACTIVE           -200   // (PSN_FIRST-0)
#define PSN_KILLACTIVE          -201   // (PSN_FIRST-1)
#define PSN_APPLY               -202   // (PSN_FIRST-2)
#define PSN_RESET               -203   // (PSN_FIRST-3)
#define PSN_HELP                -205   // (PSN_FIRST-5)
#define PSN_WIZBACK             -206   // (PSN_FIRST-6)
#define PSN_WIZNEXT             -207   // (PSN_FIRST-7)
#define PSN_WIZFINISH           -208   // (PSN_FIRST-8)
#define PSN_QUERYCANCEL         -209   // (PSN_FIRST-9)

#define TCN_FIRST               -550       // tab control
#define TCN_SELCHANGE           -551   //(TCN_FIRST - 1)
#define TCN_SELCHANGING         -552   //(TCN_FIRST - 2)
#define TCN_GETOBJECT           -553   //(TCN_FIRST - 3)
#define TCN_FOCUSCHANGE         -554   //(TCN_FIRST - 4)
#define TCN_CLICK               -2
#define TCN_RCLICK              -5
#define TCN_SETFOCUS            -550
#define TCN_GETFOCUS            -552
#define TCN_KILLFOCUS           -552
#define TCN_KEYDOWN             -550   //(TCN_FIRST - 0)

#define TCM_FIRST               4864     // Tab control messages
#define TCM_SETIMAGELIST        4867     // (TCM_FIRST + 3)
#define TCM_GETITEMCOUNT        4868     // (TCM_FIRST + 4)
#define TCM_GETCURSEL           4875		 // TCM_FIRST + 11)
#define TCM_SETCURSEL           4876     // (TCM_FIRST + 12)
#define TCM_GETCURFOCUS         4911     // (TCM_FIRST + 47)
#define TCM_SETCURFOCUS         4912     // (TCM_FIRST + 48)
#define TCM_DESELECTALL         4914        //(TCM_FIRST + 50)


/*
 * Combo Box styles
 */

#define CBS_SIMPLE            1        // 0x0001L
#define CBS_DROPDOWN          2        // 0x0002L
#define CBS_DROPDOWNLIST      3        // 0x0003L
#define CBS_OWNERDRAWFIXED    0x0010
#define CBS_OWNERDRAWVARIABLE 0x0020
#define CBS_AUTOHSCROLL       0x0040
#define CBS_OEMCONVERT        0x0080
#define CBS_SORT              0x0100
#define CBS_HASSTRINGS        0x0200
#define CBS_NOINTEGRALHEIGHT  0x0400
#define CBS_DISABLENOSCROLL   0x0800
#define CBS_UPPERCASE         8192 //$2000
#define CBS_LOWERCASE         16384 //$4000

/*
 * MessageBox() Flags
 */
#define MB_OK                 0        // 0x00000000L
#define MB_OKCANCEL           1        // 0x00000001L
#define MB_ABORTRETRYIGNORE   2        // 0x00000002L
#define MB_YESNOCANCEL        3        // 0x00000003L
#define MB_YESNO              4        // 0x00000004L
#define MB_RETRYCANCEL        5        // 0x00000005L
#define MB_ICONHAND           16       // 0x00000010L
#define MB_ICONQUESTION       32       // 0x00000020L
#define MB_ICONEXCLAMATION    48       // 0x00000030L
#define MB_ICONASTERISK       64       // 0x00000040L

#define MB_USERICON           128      // 0x00000080L
#define MB_NOFOCUS            32768    // 0x00008000L
#define MB_SETFOREGROUND      65536    // 0x00010000L
#define MB_DEFAULT_DESKTOP_ONLY  131072 // 0x00020000L

#define MB_TOPMOST            262144   // 0x00040000L
#define MB_RIGHT              524288   // 0x00080000L
#define MB_RTLREADING         1048576  // 0x00100000L

#define HKEY_CLASSES_ROOT     2147483648       // 0x80000000
#define HKEY_CURRENT_USER     2147483649       // 0x80000001
#define HKEY_LOCAL_MACHINE    2147483650       // 0x80000002
#define HKEY_USERS            2147483651       // 0x80000003
#define HKEY_PERFORMANCE_DATA 2147483652       // 0x80000004
#define HKEY_CURRENT_CONFIG   2147483653       // 0x80000005
#define HKEY_DYN_DATA         2147483654       // 0x80000006

#define MDITILE_VERTICAL       0
#define MDITILE_HORIZONTAL     1

/*
 * OEM Resource Ordinal Numbers
 */
#define OBM_CLOSE           32754
#define OBM_UPARROW         32753
#define OBM_DNARROW         32752
#define OBM_RGARROW         32751
#define OBM_LFARROW         32750
#define OBM_REDUCE          32749
#define OBM_ZOOM            32748
#define OBM_RESTORE         32747
#define OBM_REDUCED         32746
#define OBM_ZOOMD           32745
#define OBM_RESTORED        32744
#define OBM_UPARROWD        32743
#define OBM_DNARROWD        32742
#define OBM_RGARROWD        32741
#define OBM_LFARROWD        32740
#define OBM_MNARROW         32739
#define OBM_COMBO           32738
#define OBM_UPARROWI        32737
#define OBM_DNARROWI        32736
#define OBM_RGARROWI        32735
#define OBM_LFARROWI        32734

#define OBM_OLD_CLOSE       32767
#define OBM_SIZE            32766
#define OBM_OLD_UPARROW     32765
#define OBM_OLD_DNARROW     32764
#define OBM_OLD_RGARROW     32763
#define OBM_OLD_LFARROW     32762
#define OBM_BTSIZE          32761
#define OBM_CHECK           32760
#define OBM_CHECKBOXES      32759
#define OBM_BTNCORNERS      32758
#define OBM_OLD_REDUCE      32757
#define OBM_OLD_ZOOM        32756
#define OBM_OLD_RESTORE     32755

#define TCS_SCROLLOPPOSITE      1       // 0x0001   // assumes multiline tab
#define TCS_BOTTOM              2       // 0x0002
#define TCS_RIGHT               2       // 0x0002
#define TCS_MULTISELECT         4       // 0x0004  // allow multi-select in button mode
#define TCS_FLATBUTTONS         8       // 0x0008
#define TCS_FORCEICONLEFT       16      // 0x0010
#define TCS_FORCELABELLEFT      32      // 0x0020
#define TCS_HOTTRACK            64      // 0x0040
#define TCS_VERTICAL            128     // 0x0080
#define TCS_TABS                0       // 0x0000
#define TCS_BUTTONS             256     // 0x0100
#define TCS_SINGLELINE          0       // 0x0000
#define TCS_MULTILINE           512     // 0x0200
#define TCS_RIGHTJUSTIFY        0       // 0x0000
#define TCS_FIXEDWIDTH          1024    // 0x0400
#define TCS_RAGGEDRIGHT         2048    // 0x0800
#define TCS_FOCUSONBUTTONDOWN   4096    // 0x1000
#define TCS_OWNERDRAWFIXED      8192    // 0x2000
#define TCS_TOOLTIPS            16384   // 0x4000
#define TCS_FOCUSNEVER          32768   // 0x8000

#define EM_GETSEL               176     // 0x00B0
#define EM_SETSEL               177     // 0x00B1
#define EM_GETRECT              178     // 0x00B2
#define EM_SETRECT              179     // 0x00B3
#define EM_SETRECTNP            180     // 0x00B4
#define EM_SCROLL               181     // 0x00B5
#define EM_LINESCROLL           182     // 0x00B6
#define EM_SCROLLCARET          183     // 0x00B7
#define EM_GETMODIFY            184     // 0x00B8
#define EM_SETMODIFY            185     // 0x00B9
#define EM_GETLINECOUNT         186     // 0x00BA
#define EM_LINEINDEX            187     // 0x00BB
#define EM_SETHANDLE            188     // 0x00BC
#define EM_GETHANDLE            189     // 0x00BD
#define EM_GETTHUMB             190     // 0x00BE
#define EM_LINELENGTH           193     // 0x00C1
#define EM_REPLACESEL           194     // 0x00C2
#define EM_GETLINE              196     // 0x00C4
#define EM_LIMITTEXT            197     // 0x00C5
#define EM_CANUNDO              198     // 0x00C6
#define EM_UNDO                 199     // 0x00C7

#define EM_CANREDO   EM_CANUNDO      // 0x00C6
#define EM_REDO      EM_UNDO         // 0x00C7

#define EM_FMTLINES             200     // 0x00C8
#define EM_LINEFROMCHAR         201     // 0x00C9
#define EM_SETTABSTOPS          203     // 0x00CB
#define EM_SETPASSWORDCHAR      204     // 0x00CC
#define EM_EMPTYUNDOBUFFER      205     // 0x00CD
#define EM_GETFIRSTVISIBLELINE  206     // 0x00CE
#define EM_SETREADONLY          207     // 0x00CF
#define EM_SETWORDBREAKPROC     208     // 0x00D0
#define EM_GETWORDBREAKPROC     209     // 0x00D1
#define EM_GETPASSWORDCHAR      210     // 0x00D2
#define EM_SETMARGINS           211     // 0x00D3
#define EM_GETMARGINS           212     // 0x00D4
#define EM_SETLIMITTEXT         EM_LIMITTEXT
#define EM_GETLIMITTEXT         213     // 0x00D5
#define EM_POSFROMCHAR          214     // 0x00D6
#define EM_CHARFROMPOS          215     // 0x00D7

#define EM_SETBKGNDCOLOR       1091
#define EM_SETEVENTMASK        1093     // (WM_USER + 69)

#define ENM_CHANGE             1        // 0x00000001
#define ENM_SELCHANGE          524288   // 0x00080000
#define ENM_PROTECTED          0x00200000

#define IMAGE_BITMAP        0
#define IMAGE_ICON          1
#define IMAGE_CURSOR        2

#define LR_DEFAULTCOLOR         0
#define LR_MONOCHROME           1
#define LR_COLOR                2
#define LR_COPYRETURNORG        4
#define LR_COPYDELETEORG        8
#define LR_LOADFROMFILE        16       // 0x0010
#define LR_LOADTRANSPARENT     32       // 0x0020
#define LR_DEFAULTSIZE         64       // 0x0040
#define LR_VGACOLOR           128       // 0x0080
#define LR_LOADMAP3DCOLORS   4096       // 0x1000
#define LR_CREATEDIBSECTION  8192       // 0x2000
#define LR_COPYFROMRESOURCE 16384       // 0x4000
#define LR_SHARED           32768       // 0x8000

/* Stock Logical Objects */

#define WHITE_BRUSH         0
#define LTGRAY_BRUSH        1
#define GRAY_BRUSH          2
#define DKGRAY_BRUSH        3
#define BLACK_BRUSH         4
#define NULL_BRUSH          5
#define WHITE_PEN           6
#define BLACK_PEN           7
#define NULL_PEN            8
#define OEM_FIXED_FONT      10
#define ANSI_FIXED_FONT     11
#define ANSI_VAR_FONT       12
#define SYSTEM_FONT         13
#define DEVICE_DEFAULT_FONT 14
#define DEFAULT_PALETTE     15
#define SYSTEM_FIXED_FONT   16
#define DEFAULT_GUI_FONT    17

/* 3D border styles */
#define BDR_RAISEDOUTER     1           // 0x0001
#define BDR_SUNKENOUTER     2           // 0x0002
#define BDR_RAISEDINNER     4           // 0x0004
#define BDR_SUNKENINNER     8           // 0x0008

#define BDR_OUTER       (BDR_RAISEDOUTER + BDR_SUNKENOUTER)
#define BDR_INNER       (BDR_RAISEDINNER + BDR_SUNKENINNER)
#define BDR_RAISED      (BDR_RAISEDOUTER + BDR_RAISEDINNER)
#define BDR_SUNKEN      (BDR_SUNKENOUTER + BDR_SUNKENINNER)


#define EDGE_RAISED     (BDR_RAISEDOUTER + BDR_RAISEDINNER)
#define EDGE_SUNKEN     (BDR_SUNKENOUTER + BDR_SUNKENINNER)
#define EDGE_ETCHED     (BDR_SUNKENOUTER + BDR_RAISEDINNER)
#define EDGE_BUMP       (BDR_RAISEDOUTER + BDR_SUNKENINNER)

/* Border flags */
#define BF_LEFT             1           // 0x0001
#define BF_TOP              2           // 0x0002
#define BF_RIGHT            4           // 0x0004
#define BF_BOTTOM           8           // 0x0008

#define BF_TOPLEFT      (BF_TOP + BF_LEFT)
#define BF_TOPRIGHT     (BF_TOP + BF_RIGHT)
#define BF_BOTTOMLEFT   (BF_BOTTOM + BF_LEFT)
#define BF_BOTTOMRIGHT  (BF_BOTTOM + BF_RIGHT)
#define BF_RECT         (BF_LEFT + BF_TOP + BF_RIGHT + BF_BOTTOM)

#define BF_DIAGONAL        16           // 0x0010

// For diagonal lines, the BF_RECT flags specify the end point of the
// vector bounded by the rectangle parameter.
#define BF_DIAGONAL_ENDTOPRIGHT     (BF_DIAGONAL + BF_TOP + BF_RIGHT)
#define BF_DIAGONAL_ENDTOPLEFT      (BF_DIAGONAL + BF_TOP + BF_LEFT)
#define BF_DIAGONAL_ENDBOTTOMLEFT   (BF_DIAGONAL + BF_BOTTOM + BF_LEFT)
#define BF_DIAGONAL_ENDBOTTOMRIGHT  (BF_DIAGONAL + BF_BOTTOM + BF_RIGHT)


#define BF_MIDDLE        2048           // 0x0800  /* Fill in the middle */
#define BF_SOFT          4096           // 0x1000  /* For softer buttons */
#define BF_ADJUST        8192           // 0x2000  /* Calculate the space left over */
#define BF_FLAT         16384           // 0x4000  /* For flat rather than 3D borders */
#define BF_MONO         32768           // 0x8000  /* For monochrome borders */


#define FSHIFT    4   // 0x04
#define FCONTROL  8   // 0x08
#define FALT     16   // 0x10

#ifdef __GTK__

#define GDK_BackSpace       0xFF08
#define GDK_Tab             0xFF09
#define GDK_ISO_Left_Tab    0xFE20
#define GDK_Return          0xFF0D
#define GDK_Escape          0xFF1B
#define GDK_Delete          0xFFFF
#define GDK_Home            0xFF50
#define GDK_Left            0xFF51
#define GDK_Up              0xFF52
#define GDK_Right           0xFF53
#define GDK_Down            0xFF54
#define GDK_Page_Up         0xFF55
#define GDK_Page_Down       0xFF56
#define GDK_End             0xFF57
#define GDK_Insert          0xFF63
#define GDK_Control_L       0xFFE3
#define GDK_Control_R       0xFFE4
#define GDK_Shift_L         0xffe1
#define GDK_Shift_R         0xffe2
#define GDK_Alt_L           0xFFE9
#define GDK_Alt_R           0xFFEA
#define GDK_Menu            0xff67
#define GDK_Caps_Lock       0xffe5
#define GDK_Pause           0xff13
#define GDK_Help            0xff6a
#define GDK_Scroll_Lock     0xff14
#define GDK_Select          0xff60
#define GDK_Print           0xff61
#define GDK_Execute         0xff62

#define GDK_F1     0xffbe
#define GDK_F2     0xffbf
#define GDK_F3     0xffc0
#define GDK_F4     0xffc1
#define GDK_F5     0xffc2
#define GDK_F6     0xffc3
#define GDK_F7     0xffc4
#define GDK_F8     0xffc5
#define GDK_F9     0xffc6
#define GDK_F10    0xffc7
#define GDK_F11    0xffc8
#define GDK_F12    0xffc9

#define GDK_Num_Lock  0xff7f
#define GDK_KP_0   0xffb0
#define GDK_KP_1   0xffb1
#define GDK_KP_2   0xffb2
#define GDK_KP_3   0xffb3
#define GDK_KP_4   0xffb4
#define GDK_KP_5   0xffb5
#define GDK_KP_6   0xffb6
#define GDK_KP_7   0xffb7
#define GDK_KP_8   0xffb8
#define GDK_KP_9   0xffb9
#define GDK_KP_Divide    0xffaf
#define GDK_KP_Multiply  0xffaa
#define GDK_KP_Add       0xffab
#define GDK_KP_Separator 0xffac
#define GDK_KP_Subtract  0xffad
#define GDK_KP_Decimal   0xffae
#define GDK_KP_Enter     0xff8d

#define  VK_RIGHT   GDK_Right
#define  VK_LEFT    GDK_Left
#define  VK_HOME    GDK_Home
#define  VK_END     GDK_End
#define  VK_DOWN    GDK_Down
#define  VK_UP      GDK_Up
#define  VK_NEXT    GDK_Page_Down
#define  VK_PRIOR   GDK_Page_Up
#define  VK_INSERT  GDK_Insert
#define  VK_RETURN  GDK_Return
#define  VK_TAB     GDK_Tab
#define  VK_ESCAPE  GDK_Escape
#define  VK_BACK    GDK_BackSpace
#define  VK_DELETE  GDK_Delete
#define  VK_F1      GDK_F1
#define  VK_F2      GDK_F2
#define  VK_F3      GDK_F3
#define  VK_F4      GDK_F4
#define  VK_F5      GDK_F5
#define  VK_F6      GDK_F6
#define  VK_F7      GDK_F7
#define  VK_F8      GDK_F8
#define  VK_F9      GDK_F9
#define  VK_F10     GDK_F10
#define  VK_F11     GDK_F11
#define  VK_F12     GDK_F12

#define  VK_SHIFT   GDK_Shift_L
#define  VK_CONTROL GDK_Control_L
#define  VK_MENU    GDK_Menu
#define  VK_HELP    GDK_Help
#define  VK_PAUSE   GDK_Pause
#define  VK_CAPITAL GDK_Caps_Lock

#define VK_SCROLL   GDK_Scroll_Lock
#define VK_SELECT   GDK_Select
#define VK_PRINT    GDK_Print
#define VK_EXECUTE  GDK_Execute

#define VK_NUMLOCK  GDK_Num_Lock
#define VK_NUMPAD0  GDK_KP_0
#define VK_NUMPAD1  GDK_KP_1
#define VK_NUMPAD2  GDK_KP_2
#define VK_NUMPAD3  GDK_KP_3
#define VK_NUMPAD4  GDK_KP_4
#define VK_NUMPAD5  GDK_KP_5
#define VK_NUMPAD6  GDK_KP_6
#define VK_NUMPAD7  GDK_KP_7
#define VK_NUMPAD8  GDK_KP_8
#define VK_NUMPAD9  GDK_KP_9
#define VK_MULTIPLY  GDK_KP_Multiply
#define VK_ADD       GDK_KP_Add
#define VK_SEPARATOR GDK_KP_Separator
#define VK_SUBTRACT  GDK_KP_Subtract
#define VK_DECIMAL   GDK_KP_Decimal
#define VK_DIVIDE    GDK_KP_Divide

// https://developer-old.gnome.org/gdk3/stable/gdk3-Cursors.html
#define GDK_X_CURSOR            0
#define GDK_ARROW               2
#define GDK_BASED_ARROW_DOWN    4
#define GDK_BASED_ARROW_UP      6
#define GDK_BOAT                8
#define GDK_BOGOSITY            10
#define GDK_BOTTOM_LEFT_CORNER  12
#define GDK_BOTTOM_RIGHT_CORNER 14
#define GDK_BOTTOM_SIDE         16
#define GDK_BOTTOM_TEE          18
#define GDK_BOX_SPIRAL          20
#define GDK_CENTER_PTR          22
#define GDK_CIRCLE              24
#define GDK_CLOCK               26
#define GDK_COFFEE_MUG          28
#define GDK_CROSS               30
#define GDK_CROSS_REVERSE       32
#define GDK_CROSSHAIR           34
#define GDK_DIAMOND_CROSS       36
#define GDK_DOT                 38
#define GDK_DOTBOX              40
#define GDK_DOUBLE_ARROW        42
#define GDK_DRAFT_LARGE         44
#define GDK_DRAFT_SMALL         46
#define GDK_DRAPED_BOX          48
#define GDK_EXCHANGE            50
#define GDK_FLEUR               52
#define GDK_GOBBLER             54
#define GDK_GUMBY               56
#define GDK_HAND1               58
#define GDK_HAND2               60
#define GDK_HEART               62
#define GDK_ICON                64
#define GDK_IRON_CROSS          66
#define GDK_LEFT_PTR            68
#define GDK_LEFT_SIDE           70
#define GDK_LEFT_TEE            72
#define GDK_LEFTBUTTON          74
#define GDK_LL_ANGLE            76
#define GDK_LR_ANGLE            78
#define GDK_MAN                 80
#define GDK_MIDDLEBUTTON        82
#define GDK_MOUSE               84
#define GDK_PENCIL              86
#define GDK_PIRATE              88
#define GDK_PLUS                90
#define GDK_QUESTION_ARROW      92
#define GDK_RIGHT_PTR           94
#define GDK_RIGHT_SIDE          96
#define GDK_RIGHT_TEE           98
#define GDK_RIGHTBUTTON         100
#define GDK_RTL_LOGO            102
#define GDK_SAILBOAT            104
#define GDK_SB_DOWN_ARROW       106
#define GDK_SB_H_DOUBLE_ARROW   108
#define GDK_SB_LEFT_ARROW       110
#define GDK_SB_RIGHT_ARROW      112
#define GDK_SB_UP_ARROW         114
#define GDK_SB_V_DOUBLE_ARROW   116
#define GDK_SHUTTLE             118
#define GDK_SIZING              120
#define GDK_SPIDER              122
#define GDK_SPRAYCAN            124
#define GDK_STAR                126
#define GDK_TARGET              128
#define GDK_TCROSS              130
#define GDK_TOP_LEFT_ARROW      132
#define GDK_TOP_LEFT_CORNER     134
#define GDK_TOP_RIGHT_CORNER    136
#define GDK_TOP_SIDE            138
#define GDK_TOP_TEE             140
#define GDK_TREK                142
#define GDK_UL_ANGLE            144
#define GDK_UMBRELLA            146
#define GDK_UR_ANGLE            148
#define GDK_WATCH               150
#define GDK_XTERM               152

#define IDC_ARROW           GDK_LEFT_PTR
#define IDC_IBEAM           GDK_XTERM
#define IDC_WAIT            GDK_CIRCLE
#define IDC_CROSS           GDK_CROSS
#define IDC_SIZEWE          GDK_SB_H_DOUBLE_ARROW
#define IDC_SIZENS          GDK_SB_V_DOUBLE_ARROW
#define IDC_UPARROW         GDK_SB_UP_ARROW
#define IDC_HAND            GDK_HAND1

#else

#define  VK_RETURN        0x0D
#define  VK_RIGHT         0x27
#define  VK_LEFT          0x25
#define  VK_HOME          0x24
#define  VK_END           0x23
#define  VK_DOWN          0x28
#define  VK_UP            0x26
#define  VK_NEXT          0x22
#define  VK_PRIOR         0x21
#define  VK_INSERT        0x2D
#define  VK_TAB           0x09
#define  VK_ESCAPE        0x1B
#define  VK_BACK          0x08
#define  VK_DELETE        0x2E
#define  VK_F1            0x70
#define  VK_F2            0x71
#define  VK_F3            0x72
#define  VK_F4            0x73
#define  VK_F5            0x74
#define  VK_F6            0x75
#define  VK_F7            0x76
#define  VK_F8            0x77
#define  VK_F9            0x78
#define  VK_F10           0x79
#define  VK_F11           0x7A
#define  VK_F12           0x7B

#define  VK_SHIFT          0x10
#define  VK_CONTROL        0x11
#define  VK_MENU           0x12
#define  VK_HELP           0x2F
#define  VK_PAUSE          0x13
#define  VK_CAPITAL        0x14

#define VK_SCROLL         0x91
#define VK_SELECT         0x29
#define VK_PRINT          0x2A
#define VK_EXECUTE        0x2B

#define VK_NUMLOCK        0x90
#define VK_NUMPAD0        0x60
#define VK_NUMPAD1        0x61
#define VK_NUMPAD2        0x62
#define VK_NUMPAD3        0x63
#define VK_NUMPAD4        0x64
#define VK_NUMPAD5        0x65
#define VK_NUMPAD6        0x66
#define VK_NUMPAD7        0x67
#define VK_NUMPAD8        0x68
#define VK_NUMPAD9        0x69
#define VK_MULTIPLY       0x6A
#define VK_ADD            0x6B
#define VK_SEPARATOR      0x6C
#define VK_SUBTRACT       0x6D
#define VK_DECIMAL        0x6E
#define VK_DIVIDE         0x6F

#define IDC_ARROW           32512
#define IDC_IBEAM           32513
#define IDC_WAIT            32514
#define IDC_CROSS           32515
#define IDC_SIZEWE          32644
#define IDC_SIZENS          32645
#define IDC_UPARROW         32516
#define IDC_HAND            32649

#endif

#define VK_SPACE          0x20
#define VK_SNAPSHOT       0x2C

/*
 * VK_0 - VK_9 are the same as ASCII '0' - '9' (0x30 - 0x39)
 * 0x40 : unassigned
 * VK_A - VK_Z are the same as ASCII 'A' - 'Z' (0x41 - 0x5A)
 */

#define VK_LWIN           0x5B
#define VK_RWIN           0x5C
#define VK_APPS           0x5D

/*
 * 0x5E : reserved
 */

#define VK_SLEEP          0x5F
#define SW_HIDE             0
#define SW_SHOWNORMAL       1
#define SW_NORMAL           1
#define SW_SHOWMINIMIZED    2
#define SW_SHOWMAXIMIZED    3
#define SW_MAXIMIZE         3
#define SW_SHOWNOACTIVATE   4
#define SW_SHOW             5
#define SW_MINIMIZE         6
#define SW_SHOWMINNOACTIVE  7
#define SW_SHOWNA           8
#define SW_RESTORE          9
#define SW_SHOWDEFAULT      10

#define TVHT_NOWHERE            1       // 0x0001
#define TVHT_ONITEMICON         2       // 0x0002
#define TVHT_ONITEMLABEL        4       // 0x0004
#define TVHT_ONITEM             (TVHT_ONITEMICON + TVHT_ONITEMLABEL + TVHT_ONITEMSTATEICON)
#define TVHT_ONITEMINDENT       8       // 0x0008
#define TVHT_ONITEMBUTTON       16      // 0x0010
#define TVHT_ONITEMRIGHT        32      // 0x0020
#define TVHT_ONITEMSTATEICON    64      // 0x0040

#define TVHT_ABOVE              256     // 0x0100
#define TVHT_BELOW              512     // 0x0200
#define TVHT_TORIGHT            1024    // 0x0400
#define TVHT_TOLEFT             2048    // 0x0800

/* For video controls */
#define WIN_CHARPIX_H   16
#define WIN_CHARPIX_W    8
#define VID_CHARPIX_H   14
#define VID_CHARPIX_W    8
#define CS_VREDRAW                 1  // 0x0001
#define CS_HREDRAW                 2  // 0x0002

/* By Vitor McLung */
/*
 * Listbox Styles
 */

#define LBS_NOTIFY            0x0001
#define LBS_SORT              0x0002
#define LBS_NOREDRAW          0x0004
#define LBS_MULTIPLESEL       0x0008
#define LBS_OWNERDRAWFIXED    0x0010
#define LBS_OWNERDRAWVARIABLE 0x0020
#define LBS_HASSTRINGS        0x0040
#define LBS_USETABSTOPS       0x0080
#define LBS_NOINTEGRALHEIGHT  0x0100
#define LBS_MULTICOLUMN       0x0200
#define LBS_WANTKEYBOARDINPUT 0x0400
#define LBS_EXTENDEDSEL       0x0800
#define LBS_DISABLENOSCROLL   0x1000
#define LBS_NODATA            0x2000
#define LBS_NOSEL             0x4000
#define LBS_STANDARD          (LBS_NOTIFY+LBS_SORT+WS_VSCROLL+WS_BORDER)

/*
 * Listbox messages
 */

#define LB_ADDSTRING            0x0180
#define LB_INSERTSTRING         0x0181
#define LB_DELETESTRING         0x0182
#define LB_SELITEMRANGEEX       0x0183
#define LB_RESETCONTENT         0x0184
#define LB_SETSEL               0x0185
#define LB_SETCURSEL            0x0186
#define LB_GETSEL               0x0187
#define LB_GETCURSEL            0x0188
#define LB_GETTEXT              0x0189
#define LB_GETTEXTLEN           0x018A
#define LB_GETCOUNT             0x018B
#define LB_SELECTSTRING         0x018C
#define LB_DIR                  0x018D
#define LB_GETTOPINDEX          0x018E
#define LB_FINDSTRING           0x018F
#define LB_GETSELCOUNT          0x0190
#define LB_GETSELITEMS          0x0191
#define LB_SETTABSTOPS          0x0192
#define LB_GETHORIZONTALEXTENT  0x0193
#define LB_SETHORIZONTALEXTENT  0x0194
#define LB_SETCOLUMNWIDTH       0x0195
#define LB_ADDFILE              0x0196
#define LB_SETTOPINDEX          0x0197
#define LB_GETITEMRECT          0x0198
#define LB_GETITEMDATA          0x0199
#define LB_SETITEMDATA          0x019A
#define LB_SELITEMRANGE         0x019B
#define LB_SETANCHORINDEX       0x019C
#define LB_GETANCHORINDEX       0x019D
#define LB_SETCARETINDEX        0x019E
#define LB_GETCARETINDEX        0x019F
#define LB_SETITEMHEIGHT        0x01A0
#define LB_GETITEMHEIGHT        0x01A1
#define LB_FINDSTRINGEXACT      0x01A2
#define LB_SETLOCALE            0x01A5
#define LB_GETLOCALE            0x01A6
#define LB_SETCOUNT             0x01A7

#define DS_3DLOOK               4       // 0x4L

   // #define BS_NOTIFY               16384   // 0x00004000L

// more messages
#define WM_NEXTMENU                     0x0213
#define WM_SIZING                       0x0214
#define WM_CAPTURECHANGED               0x0215
#define WM_MOVING                       0x0216
#define GWL_ID (-12)

#define WM_MOUSEWHEEL  0x020A

#define TB_LINEUP               0
#define TB_LINEDOWN             1
#define TB_PAGEUP               2
#define TB_PAGEDOWN             3
#define TB_THUMBPOSITION        4
#define TB_THUMBTRACK           5
#define TB_TOP                  6
#define TB_BOTTOM               7
#define TB_ENDTRACK             8

#define TBM_GETPOS              (WM_USER)
#define TBM_GETTIC              (WM_USER+3)
#define TBM_SETPOS              (WM_USER+5)
#define TBM_GETTICPOS           (WM_USER+15)
#define TBM_GETNUMTICS          (WM_USER+16)

#define CW_USEDEFAULT           2147483648          // 0x80000000
#define CCM_FIRST               0x2000      // Common control shared messages
#define CCM_LAST                (CCM_FIRST + 0x200)

#define CCM_SETBKCOLOR          (CCM_FIRST + 1) // lParam is bkColor
#define PBM_SETBARCOLOR         (WM_USER+9)             // lParam = bar color
#define PBM_SETBKCOLOR          CCM_SETBKCOLOR  // lParam = bkColor
#define DEFAULT_QUALITY         0
#define DRAFT_QUALITY           1
#define PROOF_QUALITY           2
#define WM_SETCURSOR                    0x0020

#define WM_REFLECT_BASE 0xBC00
#define WM_CTLCOLOR     0x0019
#define WM_CTLCOLOR_REFLECT  WM_CTLCOLOR+WM_REFLECT_BASE

#define MM_TEXT             1
#define MM_LOMETRIC         2
#define MM_HIMETRIC         3
#define MM_LOENGLISH        4
#define MM_HIENGLISH        5
#define MM_TWIPS            6
#define MM_ISOTROPIC        7
#define MM_ANISOTROPIC      8
#define AD_COUNTERCLOCKWISE 1
#define AD_CLOCKWISE        2
#define PS_COSMETIC         0x00000000
#define PS_GEOMETRIC        0x00010000
#define PS_TYPE_MASK        0x000F0000
#define R2_BLACK            1   /*  0       */
#define R2_NOTMERGEPEN      2   /* DPon     */
#define R2_MASKNOTPEN       3   /* DPna     */
#define R2_NOTCOPYPEN       4   /* PN       */
#define R2_MASKPENNOT       5   /* PDna     */
#define R2_NOT              6   /* Dn       */
#define R2_XORPEN           7   /* DPx      */
#define R2_NOTMASKPEN       8   /* DPan     */
#define R2_MASKPEN          9   /* DPa      */
#define R2_NOTXORPEN        10  /* DPxn     */
#define R2_NOP              11  /* D        */
#define R2_MERGENOTPEN      12  /* DPno     */
#define R2_COPYPEN          13  /* P        */
#define R2_MERGEPENNOT      14  /* PDno     */
#define R2_MERGEPEN         15  /* DPo      */
#define R2_WHITE            16  /*  1       */
#define R2_LAST             16

// States for tool Buttons

#define TBSTATE_CHECKED         0x01
#define TBSTATE_PRESSED         0x02
#define TBSTATE_ENABLED         0x04
#define TBSTATE_HIDDEN          0x08
#define TBSTATE_INDETERMINATE   0x10
#define TBSTATE_WRAP            0x20

// Styles for button

#define TBSTYLE_BUTTON          0x0000
#define TBSTYLE_SEP             0x0001
#define TBSTYLE_CHECK           0x0002
#define TBSTYLE_GROUP           0x0004
#define TBSTYLE_CHECKGROUP      0x0006

#define BTNS_BUTTON     TBSTYLE_BUTTON      // 0x0000
#define BTNS_SEP        TBSTYLE_SEP         // 0x0001
#define BTNS_CHECK      TBSTYLE_CHECK       // 0x0002
#define BTNS_GROUP      TBSTYLE_GROUP       // 0x0004
#define BTNS_CHECKGROUP TBSTYLE_CHECKGROUP  // (TBSTYLE_GROUP | TBSTYLE_CHECK)
#define BTNS_WHOLEDROPDOWN      0x0080

#define TB_ENABLEBUTTON         (WM_USER + 1)
#define TB_HIDEBUTTON           (WM_USER + 4)
#define TB_SETSTATE             (WM_USER + 17)
#define TB_GETSTATE             (WM_USER + 18)
#define TB_SETBUTTONSIZE        (WM_USER + 31)
#define TB_SETBITMAPSIZE        (WM_USER + 32)
#define TB_SETINDENT            (WM_USER + 47)
#define TB_SETSTYLE             (WM_USER + 56)
#define TB_GETSTYLE             (WM_USER + 57)
#define TB_GETBUTTONSIZE        (WM_USER + 58)
#define TB_SETBUTTONWIDTH       (WM_USER + 59)

#define TTN_FIRST -520
#define TTN_LAST  -549
#define TTN_GETDISPINFOA        (TTN_FIRST - 0)
#define TTN_GETDISPINFOW        (TTN_FIRST - 10)
#define TTN_SHOW                (TTN_FIRST - 1)
#define TTN_POP                 (TTN_FIRST - 2)
#define TTN_GETDISPINFO         TTN_GETDISPINFOA
#define TB_SETTOOLTIPS          (WM_USER + 36)
#define TBSTYLE_DROPDOWN        0x0008
#define BTNS_DROPDOWN           TBSTYLE_DROPDOWN
#define TBSTYLE_EX_DRAWDDARROWS 0x00000001
#define TBSTYLE_EX_MIXEDBUTTONS 0x00000008
#define TB_SETEXTENDEDSTYLE     (WM_USER + 84)  // For TBSTYLE_EX_*
#define TB_GETEXTENDEDSTYLE     (WM_USER + 85)  // For TBSTYLE_EX_*
#define TBN_FIRST               (-700)       // toolbar
#define TBN_LAST                (-720)
#define TBN_DROPDOWN            (TBN_FIRST - 10)
#define TBN_GETINFOTIPA         (TBN_FIRST - 18)
#define TBN_HOTITEMCHANGE       (TBN_FIRST - 13)
#define TBN_GETINFOTIP          TBN_GETINFOTIPA
#define NM_FIRST                0
#define NM_TOOLTIPSCREATED      (NM_FIRST-19)   // notify of when the tooltips window is create
#define NM_CUSTOMDRAW           (NM_FIRST-12)
#define ILC_MASK                0x0001
#define ILC_COLOR               0x0000
#define ILC_COLORDDB            0x00FE
#define ILC_COLOR4              0x0004
#define ILC_COLOR8              0x0008
#define ILC_COLOR16             0x0010
#define ILC_COLOR24             0x0018
#define ILC_COLOR32             0x0020
#define TB_SETIMAGELIST         (WM_USER + 48)
#define TB_GETIMAGELIST         (WM_USER + 49)
#define TB_LOADIMAGES           (WM_USER + 50)
#define TB_GETRECT              (WM_USER + 51) // wParam is the Cmd instead of index
#define TB_SETHOTIMAGELIST      (WM_USER + 52)
#define TB_GETHOTIMAGELIST      (WM_USER + 53)

//--------------
// Font Weights
//--------------

#define FW_DONTCARE    0
#define FW_THIN        100
#define FW_EXTRALIGHT  200
#define FW_LIGHT       300
#define FW_NORMAL      400
#define FW_MEDIUM      500
#define FW_SEMIBOLD    600
#define FW_BOLD        700
#define FW_EXTRABOLD   800
#define FW_HEAVY       900
#define FW_ULTRALIGHT  FW_EXTRALIGHT
#define FW_REGULAR     FW_NORMAL
#define FW_DEMIBOLD    FW_SEMIBOLD
#define FW_ULTRABOLD   FW_EXTRABOLD
#define FW_BLACK       FW_HEAVY

#define PGN_FIRST               -900       // Pager Control
#define PGN_LAST                -950

#define PGN_CALCSIZE            (PGN_FIRST-2)
#define PGS_VERT                0x00000000
#define PGS_HORZ                0x00000001
#define PGS_AUTOSCROLL          0x00000002
#define PGS_DRAGNDROP           0x00000004
#define PGN_SCROLL              (PGN_FIRST-1)

#define PGF_SCROLLUP        1
#define PGF_SCROLLDOWN      2
#define PGF_SCROLLLEFT      4
#define PGF_SCROLLRIGHT     8

#define CCS_TOP                 0x00000001
#define CCS_NOMOVEY             0x00000002
#define CCS_BOTTOM              0x00000003
#define CCS_NORESIZE            0x00000004
#define CCS_NOPARENTALIGN       0x00000008
#define CCS_ADJUSTABLE          0x00000020
#define CCS_NODIVIDER           0x00000040
#define CCS_VERT                0x00000080
#define CCS_LEFT                (CCS_VERT + CCS_TOP)
#define CCS_RIGHT               (CCS_VERT + CCS_BOTTOM)
#define CCS_NOMOVEX             (CCS_VERT + CCS_NOMOVEY)

#define TBSTYLE_AUTOSIZE        0x0010  // obsolete; use BTNS_AUTOSIZE instead
#define TBSTYLE_NOPREFIX        0x0020  // obsolete; use BTNS_NOPREFIX instead
#define TBSTYLE_TOOLTIPS        0x0100
#define TBSTYLE_WRAPABLE        0x0200
#define TBSTYLE_ALTDRAG         0x0400
#define TBSTYLE_FLAT            0x0800
#define TBSTYLE_LIST            0x1000
#define TBSTYLE_CUSTOMERASE     0x2000
#define TBSTYLE_REGISTERDROP    0x4000
#define TBSTYLE_TRANSPARENT     0x8000
#define NM_CLICK                (NM_FIRST-2)    // uses NMCLICK struct
#define LVM_FIRST               0x1000      // ListView messages

#define LVM_DELETEITEM          (LVM_FIRST + 8)
#define LVM_DELETEALLITEMS      (LVM_FIRST + 9)
#define LVM_GETNEXTITEM         (LVM_FIRST + 12)
#define LVNI_ALL                0x0000
#define LVNI_FOCUSED            0x0001
#define LVNI_SELECTED           0x0002
#define LVNI_CUT                0x0004
#define LVNI_DROPHILITED        0x0008

#define LVNI_ABOVE              0x0100
#define LVNI_BELOW              0x0200
#define LVNI_TOLEFT             0x0400
#define LVNI_TORIGHT            0x0800

#define HWND_TOP                  0
#define HWND_BOTTOM               1
#define HWND_TOPMOST             -1
#define HWND_NOTOPMOST           -2

#define SWP_NOSIZE          0x0001
#define SWP_NOMOVE          0x0002
#define SWP_NOZORDER        0x0004
#define SWP_NOREDRAW        0x0008
#define SWP_NOACTIVATE      0x0010
#define SWP_FRAMECHANGED    0x0020  /* The frame changed: send WM_NCCALCSIZE */
#define SWP_SHOWWINDOW      0x0040
#define SWP_HIDEWINDOW      0x0080
#define SWP_NOCOPYBITS      0x0100
#define SWP_NOOWNERZORDER   0x0200  /* Don't do owner Z ordering */
#define SWP_NOSENDCHANGING  0x0400  /* Don't send WM_WINDOWPOSCHANGING */

#define SWP_DRAWFRAME       SWP_FRAMECHANGED
#define SWP_NOREPOSITION    SWP_NOOWNERZORDER

#define MCN_FIRST (-750)
#define MCN_SELCHANGE (MCN_FIRST + 1)
#define MCN_SELECT (MCN_FIRST + 4)

#define RBS_TOOLTIPS        0x0100
#define RBS_VARHEIGHT       0x0200
#define RBS_BANDBORDERS     0x0400
#define RBS_FIXEDORDER      0x0800
#define RBS_REGISTERDROP    0x1000
#define RBS_AUTOSIZE        0x2000
#define RBS_VERTICALGRIPPER 0x4000  // this always has the vertical gripper (default for horizontal mode)
#define RBS_DBLCLKTOGGLE    0x8000
#define RBBS_BREAK          0x00000001  // break to new line
#define RBBS_FIXEDSIZE      0x00000002  // band can't be sized
#define RBBS_CHILDEDGE      0x00000004  // edge around top & bottom of child window
#define RBBS_HIDDEN         0x00000008  // don't show
#define RBBS_NOVERT         0x00000010  // don't show when vertical
#define RBBS_FIXEDBMP       0x00000020  // bitmap doesn't move during band resize
#define RBBS_VARIABLEHEIGHT 0x00000040  // allow autosizing of this child vertically
#define RBBS_GRIPPERALWAYS  0x00000080  // always show the gripper
#define RBBS_NOGRIPPER      0x00000100  // never show the gripper
#define RBBS_USECHEVRON     0x00000200  // display drop-down button for this band if it's sized smaller than ideal width
#define RBBS_HIDETITLE      0x00000400  // keep band title hidden

#define ODS_SELECTED        0x0001
#define ODS_GRAYED          0x0002
#define ODS_DISABLED        0x0004
#define ODS_CHECKED         0x0008
#define ODS_FOCUS           0x0010
#define ODS_NOFOCUSRECT     0x0200
#define BM_CLICK            0x00F5
#define BM_GETIMAGE         0x00F6
#define BM_SETIMAGE         0x00F7
#define BM_GETCHECK         0x00F0
#define BM_SETCHECK         0x00F1
#define BM_GETSTATE         0x00F2
#define BM_SETSTATE         0x00F3
#define BM_SETSTYLE         0x00F4

#define BS_TEXT             0x00000000
#define BS_ICON             0x00000040
#define BS_BITMAP           0x00000080
#define BS_LEFT             0x00000100
#define BS_RIGHT            0x00000200
#define BS_CENTER           0x00000300
#define BS_TOP              0x00000400
#define BS_BOTTOM           0x00000800
#define BS_VCENTER          0x00000C00
#define BS_PUSHLIKE         0x00001000
#define BS_MULTILINE        0x00002000
#define BS_NOTIFY           0x00004000
#define BS_FLAT             0x00008000
#define BS_RIGHTBUTTON      BS_LEFTTEXT

#define BP_PUSHBUTTON 1
#define PBS_NORMAL    1
#define PBS_HOT       2
#define PBS_PRESSED   3
#define PBS_DISABLED  4
#define PBS_DEFAULTED 5

#define PBS_SMOOTH       1
#define PBS_VERTICAL     4
#define PBS_MARQUEE      8
#define PBM_SETRANGE     WM_USER+1
#define PBM_SETPOS       WM_USER+2
#define PBM_DELTAPOS     WM_USER+3
#define PBM_SETSTEP      WM_USER+4
#define PBM_SETRANGE32   WM_USER+6
#define PBM_SETMARQUEE   WM_USER+10

#define TMT_CONTENTMARGINS 3602

#define DFC_CAPTION             1
#define DFC_MENU                2
#define DFC_SCROLL              3
#define DFC_BUTTON              4

#define DFC_POPUPMENU           5

#define DFCS_CAPTIONCLOSE        0x0000
#define DFCS_CAPTIONMIN          0x0001
#define DFCS_CAPTIONMAX          0x0002
#define DFCS_CAPTIONRESTORE      0x0003
#define DFCS_CAPTIONHELP         0x0004

#define DFCS_MENUARROW           0x0000
#define DFCS_MENUCHECK           0x0001
#define DFCS_MENUBULLET          0x0002
#define DFCS_MENUARROWRIGHT      0x0004
#define DFCS_SCROLLUP            0x0000
#define DFCS_SCROLLDOWN          0x0001
#define DFCS_SCROLLLEFT          0x0002
#define DFCS_SCROLLRIGHT         0x0003
#define DFCS_SCROLLCOMBOBOX      0x0005
#define DFCS_SCROLLSIZEGRIP      0x0008
#define DFCS_SCROLLSIZEGRIPRIGHT 0x0010

#define DFCS_BUTTONCHECK         0x0000
#define DFCS_BUTTONRADIOIMAGE    0x0001
#define DFCS_BUTTONRADIOMASK     0x0002
#define DFCS_BUTTONRADIO         0x0004
#define DFCS_BUTTON3STATE        0x0008
#define DFCS_BUTTONPUSH          0x0010

#define DFCS_INACTIVE            0x0100
#define DFCS_PUSHED              0x0200
#define DFCS_CHECKED             0x0400


#define DFCS_TRANSPARENT         0x0800
#define DFCS_HOT                 0x1000


#define DFCS_ADJUSTRECT          0x2000
#define DFCS_FLAT                0x4000
#define DFCS_MONO                0x8000

// Defines for the new buttons
#define ST_ALIGN_HORIZ       0           // Icon/bitmap on the left, text on the right
#define ST_ALIGN_VERT        1           // Icon/bitmap on the top, text on the bottom
#define ST_ALIGN_HORIZ_RIGHT 2           // Icon/bitmap on the right, text on the left
#define ST_ALIGN_OVERLAP     3           // Icon/bitmap on the same space as text

#define WM_THEMECHANGED     0x031

#define TPM_LEFTALIGN       0x0000
#define TPM_CENTERALIGN     0x0004
#define TPM_RIGHTALIGN      0x0008
#define DS_CONTROL          0x0400

#define BUTTON_UNCHECKED       0x00
#define BUTTON_CHECKED         0x01
#define BUTTON_3STATE          0x02
#define BUTTON_HIGHLIGHTED     0x04
#define BUTTON_HASFOCUS        0x08
#define BUTTON_NSTATES         0x0F
#define BUTTON_BTNPRESSED      0x40
#define BUTTON_UNKNOWN2        0x20
#define BUTTON_UNKNOWN3        0x10

#define ODA_DRAWENTIRE  0x0001
#define ODA_SELECT      0x0002
#define ODA_FOCUS       0x0004

#define WM_NCMOUSEMOVE                  0x00A0
#define WM_NCLBUTTONDOWN                0x00A1
#define WM_NCLBUTTONUP                  0x00A2
#define WM_NCLBUTTONDBLCLK              0x00A3
#define WM_NCRBUTTONDOWN                0x00A4
#define WM_NCRBUTTONUP                  0x00A5
#define WM_NCRBUTTONDBLCLK              0x00A6
#define WM_NCMBUTTONDOWN                0x00A7
#define WM_NCMBUTTONUP                  0x00A8
#define WM_NCMBUTTONDBLCLK              0x00A9
#define WM_MOUSEHOVER                   0x02A1
#define WM_MOUSELEAVE                   0x02A3

#define WM_NCMOUSEHOVER                 0x02A0
#define WM_NCMOUSELEAVE                 0x02A2

#define LVM_COLUMNCLICK         (LVM_FIRST-8)
#define LVN_FIRST               -100       // listview

#define LVN_COLUMNCLICK         (LVN_FIRST-8)
#define HOLLOW_BRUSH            NULL_BRUSH
#define TTM_SETMAXTIPWIDTH      (WM_USER + 24)

#define _SRCCOPY                0x00CC0020 /* dest = source                   */
#define _SRCPAINT               0x00EE0086 /* dest = source OR dest           */

#define CB_SETDROPPEDWIDTH      0x0160

#define DLGC_WANTARROWS      0x0001      /* Control wants arrow keys         */
#define DLGC_WANTTAB         0x0002      /* Control wants tab keys           */
#define DLGC_WANTALLKEYS     0x0004      /* Control wants all keys           */
#define DLGC_WANTMESSAGE     0x0004      /* Pass message to control          */
#define DLGC_HASSETSEL       0x0008      /* Understands EM_SETSEL message    */
#define DLGC_DEFPUSHBUTTON   0x0010      /* Default pushbutton               */
#define DLGC_UNDEFPUSHBUTTON 0x0020      /* Non-default pushbutton           */
#define DLGC_RADIOBUTTON     0x0040      /* Radio button                     */
#define DLGC_WANTCHARS       0x0080      /* Want WM_CHAR messages            */
#define DLGC_STATIC          0x0100      /* Static item: don't include       */
#define DLGC_BUTTON          0x2000      /* Button item: can be checked      */

/*
Animation class defines
*/
#define ACS_CENTER              1
#define ACS_TRANSPARENT         2
#define ACS_AUTOPLAY            4

/*
Ancestor() const defines
*/
#define     GA_PARENT       1
#define     GA_ROOT         2
#define     GA_ROOTOWNER    3

/*
Brush fill Styles
*/
#define HS_HORIZONTAL    0
#define HS_VERTICAL      1
#define HS_BDIAGONAL     2
#define HS_FDIAGONAL     3
#define HS_CROSS         4
#define HS_DIAGCROSS     5
#define HS_SOLID         8
#define BS_TRANSPARENT  10

/*
Up-Down const defines
*/
#define UDS_WRAP                0x0001
#define UDS_SETBUDDYINT         0x0002
#define UDS_ALIGNRIGHT          0x0004
#define UDS_ALIGNLEFT           0x0008
#define UDS_AUTOBUDDY           0x0010
#define UDS_ARROWKEYS           0x0020
#define UDS_HORZ                0x0040
#define UDS_NOTHOUSANDS         0x0080
#define UDS_HOTTRACK            0x0100

/*
Check button
*/
#define BST_UNCHECKED      0x0000
#define BST_CHECKED        0x0001
#define BST_INDETERMINATE  0x0002
#define BST_PUSHED         0x0004
#define BST_FOCUS          0x0008

/*
ListBox
*/
#define LBN_SELCHANGE        1
#define LBN_DBLCLK           2
#define LBN_SELCANCEL        3
#define LBN_SETFOCUS         4
#define LBN_KILLFOCUS        5
#define LBN_ERRSPACE       255
#define LBN_CLICKCHECKMARK   6
#define LBN_CLICKED          7
#define LBN_ENTER            8

/*
ComboBox
*/
#define CBN_SELCHANGE       1
#define CBN_DBLCLK          2
#define CBN_SETFOCUS        3
#define CBN_KILLFOCUS       4
#define CBN_EDITCHANGE      5
#define CBN_EDITUPDATE      6
#define CBN_DROPDOWN        7
#define CBN_CLOSEUP         8
#define CBN_SELENDOK        9
#define CBN_SELENDCANCEL   10

// GETSYSTEMMETRICS constants
//--------------------------

#define SM_CXFIXEDFRAME 7
#define SM_CYFIXEDFRAME 8
#define SM_CXSCREEN 0
#define SM_CYSCREEN 1
#define SM_CXVSCROLL 2
#define SM_CYHSCROLL 3
#define SM_CYCAPTION 4
#define SM_CXBORDER 5
#define SM_CYBORDER 6
#define SM_CYDLGFRAME 8
#define SM_CXDLGFRAME 7
#define SM_CYVTHUMB 9
#define SM_CXHTHUMB 10
#define SM_CXICON 11
#define SM_CYICON 12
#define SM_CXCURSOR 13
#define SM_CYCURSOR 14
#define SM_CYMENU 15
#define SM_CXFULLSCREEN 16
#define SM_CYFULLSCREEN 17
#define SM_CYKANJIWINDOW 18
#define SM_MOUSEPRESENT 19
#define SM_CYVSCROLL 20
#define SM_CXHSCROLL 21
#define SM_DEBUG 22
#define SM_SWAPBUTTON 23
#define SM_RESERVED1 24
#define SM_RESERVED2 25
#define SM_RESERVED3 26
#define SM_RESERVED4 27
#define SM_CXMIN 28
#define SM_CYMIN 29
#define SM_CXSIZE 30
#define SM_CYSIZE 31
#define SM_CXSIZEFRAME 32
#define SM_CXFRAME 32
#define SM_CYSIZEFRAME 33
#define SM_CYFRAME 33
#define SM_CXMINTRACK 34
#define SM_CYMINTRACK 35
#define SM_CXDOUBLECLK 36
#define SM_CYDOUBLECLK 37
#define SM_CXICONSPACING 38
#define SM_CYICONSPACING 39
#define SM_MENUDROPALIGNMENT 40
#define SM_PENWINDOWS 41
#define SM_DBCSENABLED 42
#define SM_CMOUSEBUTTONS 43
#define SM_SECURE 44
#define SM_CXEDGE 45
#define SM_CYEDGE 46
#define SM_CXMINSPACING 47
#define SM_CYMINSPACING 48
#define SM_CXSMICON 49
#define SM_CYSMICON 50
#define SM_CYSMCAPTION 51
#define SM_CXSMSIZE 52
#define SM_CYSMSIZE 53
#define SM_CXMENUSIZE 54
#define SM_CYMENUSIZE 55
#define SM_ARRANGE 56
#define SM_CXMINIMIZED 57
#define SM_CYMINIMIZED 58
#define SM_CXMAXTRACK 59
#define SM_CYMAXTRACK 60
#define SM_CXMAXIMIZED 61
#define SM_CYMAXIMIZED 62
#define SM_NETWORK 63
#define SM_CLEANBOOT 67
#define SM_CXDRAG 68
#define SM_CYDRAG 69
#define SM_SHOWSOUNDS 70
#define SM_CXMENUCHECK 71
#define SM_CYMENUCHECK 72
#define SM_SLOWMACHINE 73
#define SM_MIDEASTENABLED 74
#define SM_MOUSEWHEELPRESENT 75
#define SM_XVIRTUALSCREEN 76
#define SM_YVIRTUALSCREEN 77
#define SM_CXVIRTUALSCREEN 78
#define SM_CYVIRTUALSCREEN 79
#define SM_CMONITORS 80
#define SM_SAMEDISPLAYFORMAT 81
#define SM_IMMENABLED 82
#define SM_CXFOCUSBORDER 83
#define SM_CYFOCUSBORDER 84
#define SM_TABLETPC 86
#define SM_MEDIACENTER 87
#define SM_STARTER 88
#define SM_SERVERR2 89

#define OPAQUE 2

#define DMPAPER_A3                   8  /* DIN A3 297 x 420 mm  */
#define DMPAPER_A4                   9  /* DIN A4 210 x 297 mm  */
#define DMPAPER_A5                  11  /* DIN A5 148 x 210 mm  */
#define DMPAPER_A6                  70  /* DIN A6 105 x 148 mm  */

/* CONSTANTS TO TRACKMOUSEEVENT */
#define  TME_CANCEL            0x80000000
#define  TME_HOVER             1
#define  TME_LEAVE             2

#define HDM_GETITEMCOUNT    4608

/* ======================= EOF of windows.ch ======================= */
