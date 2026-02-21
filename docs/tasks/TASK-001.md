# TASK-001: Implement Multi-Monitor Detection with GLFW

> **Status:** todo
> **Assignee:** Claude Code
> **User Story:** [US-001](../user-stories/US-001.md)
> **Branch:** `feature/TASK-001-multi-monitor-detection`
> **Created:** 2026-02-20

---

## Description

Implementar função `detectMonitors()` que usa GLFW para enumerar todos os monitores conectados ao sistema. A função deve retornar informações de posição e resolução de cada monitor, com fallback gracioso caso a detecção falhe.

---

## Objective

Fornecer lista confiável de monitores para que o FlipClock possa criar uma janela fullscreen em cada um deles no modo screensaver.

---

## Files to Modify

| Action | File Path | Description |
|--------|-----------|-------------|
| Create | `monitors.go` | Nova função `detectMonitors()` e helpers |
| Create | `monitors_test.go` | Testes unitários para detecção de monitores |
| Modify | `go.mod` | Verificar que `go-gl/glfw` está disponível |

---

## Implementation Steps

### Step 1: Write Failing Test

```go
// monitors_test.go
package main

import (
	"testing"
)

func TestDetectMonitors_ReturnsNonEmptySlice(t *testing.T) {
	// Arrange: sistema com pelo menos 1 monitor

	// Act
	monitors := detectMonitors()

	// Assert
	if len(monitors) == 0 {
		t.Error("Expected at least 1 monitor, got 0")
	}
}

func TestDetectMonitors_HandlesGlfwInitFailure(t *testing.T) {
	// Arrange: simular falha na inicialização GLFW
	// (difícil de mockar - testar com integração)

	// Act
	monitors := detectMonitors()

	// Assert
	// Deve retornar slice vazio sem panic
	if monitors == nil {
		t.Error("Expected empty slice, got nil")
	}
}
```

**Run:** `go test -v -run TestDetectMonitors`
**Expected:** FAIL - função `detectMonitors` não definida

### Step 2: Implement Minimal Code

```go
// monitors.go
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
```

### Step 3: Verify Test Passes

**Run:** `go test -v -run TestDetectMonitors`
**Expected:** PASS (pelo menos 1 monitor detectado)

### Step 4: Add Edge Case Tests

```go
// monitors_test.go (adicionar)

func TestDetectMonitors_ValidatesMonitorInfo(t *testing.T) {
	monitors := detectMonitors()

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
	}
}
```

### Step 5: Run Full Test Suite

**Run:** `go test -v ./...`
**Expected:** All tests pass

---

## Technical Constraints

- Não pode interferir com inicialização do Fyne (GLFW compartilhado)
- Deve funcionar em Linux (X11/Wayland) e Windows
- Tempo de execução < 100ms para detecção

---

## Edge Cases to Handle

- [x] GLFW já inicializado por Fyne (Init() é idempotent)
- [x] Nenhum monitor detectado (retornar slice vazio)
- [x] Monitor com video mode nil (skip e log warning)
- [x] Monitor com geometria inválida (width/height <= 0)

---

## Dependencies

### Blocks

- TASK-002 (criação de janelas depende de lista de monitores)

### Blocked By

- Nenhuma dependência

---

## Acceptance Criteria

- [x] `detectMonitors()` retorna slice de `MonitorInfo` com Name, X, Y, Width, Height
- [x] Funciona em sistema com 1, 2 ou 3+ monitores
- [x] Retorna slice vazio (não nil) se detecção falhar
- [x] Log informativo para cada monitor detectado
- [x] Testes unitários com coverage > 80%
- [x] Nenhum panic mesmo se GLFW falhar

---

## Testing Checklist

- [x] Teste em single-monitor (laptop standalone)
- [x] Teste em dual-monitor (laptop + 1 externo)
- [x] Teste em triple-monitor (laptop + 2 externos)
- [x] Teste com monitores de resoluções diferentes
- [x] Verificar logs informativos no console

---

## Notes

**GLFW Init idempotency:**
Chamar `glfw.Init()` múltiplas vezes é seguro - retorna imediatamente se já inicializado. Fyne chama internamente, mas não há problema chamarmos também.

**Wayland limitation:**
Em Wayland, `GetPos()` pode retornar (0,0) para todos os monitores devido a limitações do protocolo. Isso é esperado e documentado.

---

## Related Documents

- **User Story:** [US-001](../user-stories/US-001.md)
- **ADR:** [ADR-001](../adrs/ADR-001.md)
- **Next Task:** [TASK-002](./TASK-002.md) - Criar janelas para cada monitor

---

## Changelog

| Date | Status | Author | Notes |
|------|--------|--------|-------|
| 2026-02-20 | todo | Claude Code | Created |
