#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "fvwm/fvwm.h"
#include "fvwm/module.h"

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'C':
	if (strEQ(name, "C_ALL"))
#ifdef C_ALL
	    return C_ALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_FRAME"))
#ifdef C_FRAME
	    return C_FRAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_ICON"))
#ifdef C_ICON
	    return C_ICON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_L1"))
#ifdef C_L1
	    return C_L1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_L2"))
#ifdef C_L2
	    return C_L2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_L3"))
#ifdef C_L3
	    return C_L3;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_L4"))
#ifdef C_L4
	    return C_L4;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_L5"))
#ifdef C_L5
	    return C_L5;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_LALL"))
#ifdef C_LALL
	    return C_LALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_NO_CONTEXT"))
#ifdef C_NO_CONTEXT
	    return C_NO_CONTEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_R1"))
#ifdef C_R1
	    return C_R1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_R2"))
#ifdef C_R2
	    return C_R2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_R3"))
#ifdef C_R3
	    return C_R3;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_R4"))
#ifdef C_R4
	    return C_R4;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_R5"))
#ifdef C_R5
	    return C_R5;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_RALL"))
#ifdef C_RALL
	    return C_RALL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_ROOT"))
#ifdef C_ROOT
	    return C_ROOT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_SIDEBAR"))
#ifdef C_SIDEBAR
	    return C_SIDEBAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_TITLE"))
#ifdef C_TITLE
	    return C_TITLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "C_WINDOW"))
#ifdef C_WINDOW
	    return C_WINDOW;
#else
	    goto not_there;
#endif
	break;
    case 'F':
	if (strEQ(name, "F_STARTICONIC"))
#ifdef STARTICONIC
	    return STARTICONIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_ONTOP"))
#ifdef ONTOP
	    return ONTOP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_STICKY"))
#ifdef STICKY
	    return STICKY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_WINDOWLISTSKIP"))
#ifdef WINDOWLISTSKIP
	    return WINDOWLISTSKIP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_SUPPRESSICON"))
#ifdef SUPPRESSICON
	    return ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_NOICON_TITLE"))
#ifdef NOICON_TITLE
	    return ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_Lenience"))
#ifdef Lenience
	    return Lenience;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_StickyIcon"))
#ifdef StickyIcon
	    return StickyIcon;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_CirculateSkipIcon"))
#ifdef CirculateSkipIcon
	    return CirculateSkipIcon;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_CirculateSkip"))
#ifdef CirculateSkip
	    return CirculateSkip;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_ClickToFocus"))
#ifdef ClickToFocus
	    return ClickToFocus;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_SloppyFocus"))
#ifdef SloppyFocus
	    return SloppyFocus;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_SHOW_ON_MAP"))
#ifdef SHOW_ON_MAP
	    return SHOW_ON_MAP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_ALL_COMMON_FLAGS"))
#ifdef ALL_COMMON_FLAGS
	    return ALL_COMMON_FLAGS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_BORDER"))
#ifdef BORDER
	    return BORDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_TITLE"))
#ifdef TITLE
	    return TITLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_MAPPED"))
#ifdef MAPPED
	    return MAPPED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_ICONIFIED"))
#ifdef ICONIFIED
	    return ICONIFIED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_TRANSIENT"))
#ifdef TRANSIENT
	    return TRANSIENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_RAISED"))
#ifdef RAISED
	    return RAISED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_VISIBLE"))
#ifdef VISIBLE
	    return VISIBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_ICON_OURS"))
#ifdef ICON_OURS
	    return ICON_OURS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_PIXMAP_OURS"))
#ifdef PIXMAP_OURS
	    return PIXMAP_OURS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_SHAPED_ICON"))
#ifdef SHAPED_ICON
	    return SHAPED_ICON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_MAXIMIZED"))
#ifdef MAXIMIZED
	    return MAXIMIZED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_DoesWmTakeFocus"))
#ifdef DoesWmTakeFocus
	    return DoesWmTakeFocus;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_DoesWmDeleteWindow"))
#ifdef DoesWmDeleteWindow
	    return DoesWmDeleteWindow;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_ICON_MOVED"))
#ifdef ICON_MOVED
	    return ICON_MOVED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_ICON_UNMAPPED"))
#ifdef ICON_UNMAPPED
	    return ICON_UNMAPPED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_MAP_PENDING"))
#ifdef MAP_PENDING
	    return MAP_PENDING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_HintOverride"))
#ifdef HintOverride
	    return HintOverride;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_MWMButtons"))
#ifdef MWMButtons
	    return MWMButtons;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_MWMBorders"))
#ifdef MWMBorders
	    return MWMBorders;
#else
	    goto not_there;
#endif
    case 'H':
	if (strEQ(name, "HEADER_SIZE"))
#ifdef HEADER_SIZE
	    return HEADER_SIZE;
#else
	    goto not_there;
#endif
	break;
    case 'M':
	if (strEQ(name, "MAX_BODY_SIZE"))
#ifdef MAX_BODY_SIZE
	    return MAX_BODY_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAX_MASK"))
#ifdef MAX_MASK
	    return MAX_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAX_PACKET_SIZE"))
#ifdef MAX_PACKET_SIZE
	    return MAX_PACKET_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_ADD_WINDOW"))
#ifdef M_ADD_WINDOW
	    return M_ADD_WINDOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_CONFIGURE_WINDOW"))
#ifdef M_CONFIGURE_WINDOW
	    return M_CONFIGURE_WINDOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_CONFIG_INFO"))
#ifdef M_CONFIG_INFO
	    return M_CONFIG_INFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_DEFAULTICON"))
#ifdef M_DEFAULTICON
	    return M_DEFAULTICON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_DEICONIFY"))
#ifdef M_DEICONIFY
	    return M_DEICONIFY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_DESTROY_WINDOW"))
#ifdef M_DESTROY_WINDOW
	    return M_DESTROY_WINDOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_DEWINDOWSHADE"))
#ifdef M_DEWINDOWSHADE
	    return M_DEWINDOWSHADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_END_CONFIG_INFO"))
#ifdef M_END_CONFIG_INFO
	    return M_END_CONFIG_INFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_END_WINDOWLIST"))
#ifdef M_END_WINDOWLIST
	    return M_END_WINDOWLIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_ERROR"))
#ifdef M_ERROR
	    return M_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_FOCUS_CHANGE"))
#ifdef M_FOCUS_CHANGE
	    return M_FOCUS_CHANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_ICONIFY"))
#ifdef M_ICONIFY
	    return M_ICONIFY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_ICON_FILE"))
#ifdef M_ICON_FILE
	    return M_ICON_FILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_ICON_LOCATION"))
#ifdef M_ICON_LOCATION
	    return M_ICON_LOCATION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_ICON_NAME"))
#ifdef M_ICON_NAME
	    return M_ICON_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_LOWER_WINDOW"))
#ifdef M_LOWER_WINDOW
	    return M_LOWER_WINDOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_MAP"))
#ifdef M_MAP
	    return M_MAP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_MINI_ICON"))
#ifdef M_MINI_ICON
	    return M_MINI_ICON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_NEW_DESK"))
#ifdef M_NEW_DESK
	    return M_NEW_DESK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_NEW_PAGE"))
#ifdef M_NEW_PAGE
	    return M_NEW_PAGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_RAISE_WINDOW"))
#ifdef M_RAISE_WINDOW
	    return M_RAISE_WINDOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_RES_CLASS"))
#ifdef M_RES_CLASS
	    return M_RES_CLASS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_RES_NAME"))
#ifdef M_RES_NAME
	    return M_RES_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_STRING"))
#ifdef M_STRING
	    return M_STRING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_WINDOWSHADE"))
#ifdef M_WINDOWSHADE
	    return M_WINDOWSHADE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "M_WINDOW_NAME"))
#ifdef M_WINDOW_NAME
	    return M_WINDOW_NAME;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "START_FLAG"))
#ifdef START_FLAG
	    return START_FLAG;
#else
	    goto not_there;
#endif
	break;
    default:
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = X11::Fvwm		PACKAGE = X11::Fvwm		


double
constant(name,arg)
	char *		name
	int		arg

