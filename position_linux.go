//go:build linux

package main

/*
#cgo LDFLAGS: -lX11
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

// find_window locates an X11 window by WM_NAME from _NET_CLIENT_LIST.
static Window find_window(Display *dpy, const char *target) {
    Atom prop = XInternAtom(dpy, "_NET_CLIENT_LIST", False);
    Atom actual_type;
    int format;
    unsigned long nitems, remaining;
    unsigned char *data = NULL;
    Window root = DefaultRootWindow(dpy);

    if (XGetWindowProperty(dpy, root, prop, 0, 4096, False,
            XA_WINDOW, &actual_type, &format, &nitems, &remaining, &data) != Success)
        return 0;
    if (!data) return 0;

    Window *wins = (Window*)data;
    Window found = 0;
    for (unsigned long i = 0; i < nitems; i++) {
        char *name = NULL;
        if (XFetchName(dpy, wins[i], &name) && name) {
            if (strcmp(name, target) == 0) {
                found = wins[i];
            }
            XFree(name);
            if (found) break;
        }
    }
    XFree(data);
    return found;
}

// send_wm_state sends a _NET_WM_STATE client message (action: 0=remove, 1=add).
static void send_wm_state(Display *dpy, Window win, int action, Atom state) {
    XEvent ev;
    memset(&ev, 0, sizeof(ev));
    ev.type = ClientMessage;
    ev.xclient.window = win;
    ev.xclient.message_type = XInternAtom(dpy, "_NET_WM_STATE", False);
    ev.xclient.format = 32;
    ev.xclient.data.l[0] = action;
    ev.xclient.data.l[1] = (long)state;
    ev.xclient.data.l[2] = 0;
    ev.xclient.data.l[3] = 1;
    XSendEvent(dpy, DefaultRootWindow(dpy), False,
        SubstructureRedirectMask | SubstructureNotifyMask, &ev);
}

// reposition_window moves a window to (x,y) and requests fullscreen there.
// Returns: 1=ok, 0=not found, -1=no display.
static int reposition_window(const char *title, int x, int y, int w, int h) {
    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) return -1;

    Window win = find_window(dpy, title);
    if (!win) { XCloseDisplay(dpy); return 0; }

    Atom fs = XInternAtom(dpy, "_NET_WM_STATE_FULLSCREEN", False);

    // 1) Remove fullscreen so WM allows the move
    send_wm_state(dpy, win, 0, fs);
    XFlush(dpy);
    usleep(50000);

    // 2) Move window to the target monitor coordinates
    XMoveResizeWindow(dpy, win, x, y, (unsigned int)w, (unsigned int)h);
    XFlush(dpy);
    XSync(dpy, False);
    usleep(150000);

    // 3) Request fullscreen on current monitor
    send_wm_state(dpy, win, 1, fs);
    XFlush(dpy);

    XCloseDisplay(dpy);
    return 1;
}
*/
import "C"

import (
	"fmt"
	"log"
	"time"
	"unsafe"
)

// positionWindowsOnMonitors uses Xlib to move each window to its target
// monitor and then request fullscreen there. Fyne v2 does not expose a
// window positioning API, so we call X11 directly (libX11 is already
// required for the Fyne/GLFW build).
func positionWindowsOnMonitors(windows []ScreensaverWindow) error {
	time.Sleep(800 * time.Millisecond) // wait for windows to be mapped

	for _, sw := range windows {
		mon := sw.Monitor
		title := sw.Window.Title()
		cTitle := C.CString(title)

		var result C.int
		for attempt := 0; attempt < 30; attempt++ {
			result = C.reposition_window(cTitle, C.int(mon.X), C.int(mon.Y),
				C.int(mon.Width), C.int(mon.Height))
			if result == 1 {
				log.Printf("Positioned '%s' on %s at %d,%d (%dx%d)",
					title, mon.Name, mon.X, mon.Y, mon.Width, mon.Height)
				break
			}
			if result == -1 {
				C.free(unsafe.Pointer(cTitle))
				return fmt.Errorf("cannot open X11 display")
			}
			time.Sleep(100 * time.Millisecond)
		}

		C.free(unsafe.Pointer(cTitle))

		if result != 1 {
			log.Printf("Failed to position '%s' on %s (code: %d)", title, mon.Name, result)
		}
	}

	return nil
}
