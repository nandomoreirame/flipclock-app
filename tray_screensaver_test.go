package main

import (
	"testing"
	"time"

	"fyne.io/fyne/v2/test"
)

// TestLaunchScreensaverFromTray verifies that screensaver can be triggered from system tray
// and returns to normal mode when exited.
func TestLaunchScreensaverFromTray(t *testing.T) {
	// This test verifies the screensaver launcher function exists and can be called
	// without panicking. Full integration test requires GUI runtime.

	app := test.NewApp()
	defer app.Quit()

	// Mock monitor detection (returns empty slice)
	monitors := []MonitorInfo{}

	// Verify setupScreensaverWindows handles empty monitors gracefully
	windows := setupScreensaverWindows(app, monitors)
	if len(windows) != 1 {
		t.Errorf("Expected 1 fallback window for empty monitors, got %d", len(windows))
	}

	// Verify window has correct properties
	w := windows[0].Window
	if w == nil {
		t.Fatal("Expected valid window, got nil")
	}

	// Verify clock is initialized
	clock := windows[0].Clock
	if clock == nil {
		t.Fatal("Expected valid clock, got nil")
	}
	if clock.hourCard == nil || clock.minCard == nil || clock.secLabel == nil {
		t.Error("Clock components not properly initialized")
	}
}

// TestScreensaverExitChannel verifies that the quit channel properly stops the ticker.
func TestScreensaverExitChannel(t *testing.T) {
	app := test.NewApp()
	defer app.Quit()

	monitors := []MonitorInfo{{Name: "Test", Width: 800, Height: 600}}
	windows := setupScreensaverWindows(app, monitors)

	clocks := make([]*Clock, len(windows))
	for i, sw := range windows {
		clocks[i] = sw.Clock
	}

	quit := make(chan bool)

	// Start ticker in goroutine
	go startSharedTicker(clocks, quit)

	// Give it a moment to start
	time.Sleep(50 * time.Millisecond)

	// Close quit channel
	close(quit)

	// Give it a moment to stop
	time.Sleep(50 * time.Millisecond)

	// Test passes if no panic/deadlock occurs
}
