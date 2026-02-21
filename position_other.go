//go:build !linux

package main

import "log"

// positionWindowsOnMonitors is a no-op on non-Linux platforms.
// Multi-monitor positioning currently requires X11.
func positionWindowsOnMonitors(_ []ScreensaverWindow) error {
	log.Println("Multi-monitor positioning is only supported on Linux/X11")
	return nil
}
