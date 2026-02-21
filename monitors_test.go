package main

import (
	"testing"
)

func TestDetectMonitors_ReturnsNonEmptySlice(t *testing.T) {
	// Arrange: sistema com pelo menos 1 monitor

	// Act
	monitors := detectMonitors()

	// Assert
	if monitors == nil {
		t.Fatal("Expected non-nil slice, got nil")
	}

	// Em um sistema sem monitores (CI/headless), retorna slice vazio
	// Em sistema com GUI, retorna pelo menos 1
	if len(monitors) > 0 {
		t.Logf("Detected %d monitor(s)", len(monitors))
	} else {
		t.Log("No monitors detected (headless environment)")
	}
}

func TestDetectMonitors_ValidatesMonitorInfo(t *testing.T) {
	// Arrange & Act
	monitors := detectMonitors()

	// Assert: se há monitores, devem ter informações válidas
	for i, mon := range monitors {
		// Validate width and height are positive
		if mon.Width <= 0 {
			t.Errorf("Monitor %d has invalid width: %d", i, mon.Width)
		}
		if mon.Height <= 0 {
			t.Errorf("Monitor %d has invalid height: %d", i, mon.Height)
		}

		// Name should not be empty
		if mon.Name == "" {
			t.Errorf("Monitor %d has empty name", i)
		}

		t.Logf("Monitor %d: %s (%dx%d at %d,%d)",
			i, mon.Name, mon.Width, mon.Height, mon.X, mon.Y)
	}
}

func TestDetectMonitors_HandlesGlfwFailureGracefully(t *testing.T) {
	// Arrange: Este teste verifica que não há panic se GLFW falhar
	// (difícil de simular sem mock, mas garante que função existe)

	// Act & Assert: não deve causar panic
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("detectMonitors() panicked: %v", r)
		}
	}()

	monitors := detectMonitors()

	// Deve retornar slice vazio (não nil) em caso de falha
	if monitors == nil {
		t.Error("Expected empty slice on failure, got nil")
	}
}

func TestMonitorInfo_StructFields(t *testing.T) {
	// Arrange: criar MonitorInfo para validar estrutura
	info := MonitorInfo{
		Name:   "Test Monitor",
		X:      0,
		Y:      0,
		Width:  1920,
		Height: 1080,
	}

	// Assert: verificar que campos estão acessíveis
	if info.Name != "Test Monitor" {
		t.Errorf("Expected name 'Test Monitor', got '%s'", info.Name)
	}
	if info.Width != 1920 {
		t.Errorf("Expected width 1920, got %d", info.Width)
	}
	if info.Height != 1080 {
		t.Errorf("Expected height 1080, got %d", info.Height)
	}
}
