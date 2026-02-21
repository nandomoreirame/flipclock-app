package main

import (
	"log"

	"github.com/go-gl/glfw/v3.3/glfw"
)

// MonitorInfo holds position and size information for a monitor
type MonitorInfo struct {
	Name   string
	X      int
	Y      int
	Width  int
	Height int
}

// detectMonitors queries GLFW for all connected monitors
// Returns empty slice if detection fails (graceful degradation)
func detectMonitors() []MonitorInfo {
	// Initialize GLFW if not already done
	err := glfw.Init()
	if err != nil {
		log.Printf("GLFW init failed: %v (falling back to single-monitor mode)", err)
		return []MonitorInfo{}
	}

	// Get all monitors
	monitors := glfw.GetMonitors()
	if len(monitors) == 0 {
		log.Println("No monitors detected (falling back to single-monitor mode)")
		return []MonitorInfo{}
	}

	// Extract monitor information
	result := make([]MonitorInfo, 0, len(monitors))
	for i, mon := range monitors {
		if mon == nil {
			log.Printf("Monitor %d is nil, skipping", i)
			continue
		}

		// Get monitor position and video mode
		x, y := mon.GetPos()
		mode := mon.GetVideoMode()
		if mode == nil {
			log.Printf("Monitor %d has no video mode, skipping", i)
			continue
		}

		name := mon.GetName()
		result = append(result, MonitorInfo{
			Name:   name,
			X:      x,
			Y:      y,
			Width:  mode.Width,
			Height: mode.Height,
		})

		log.Printf("Detected monitor: %s (%dx%d at %d,%d)", name, mode.Width, mode.Height, x, y)
	}

	return result
}
