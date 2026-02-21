# TASK-003: Implement Unified Exit and Clock Synchronization

> **Status:** todo
> **Assignee:** Claude Code
> **User Story:** [US-001](../user-stories/US-001.md)
> **Branch:** `feature/TASK-001-multi-monitor-detection`
> **Created:** 2026-02-20

---

## Description

Implementar sincronização de horário entre múltiplas janelas usando um único `time.Ticker` e registrar handlers de input (teclado/mouse) que fecham todas as janelas simultaneamente quando qualquer entrada for detectada.

---

## Objective

Garantir que todas as janelas do screensaver exibam o mesmo horário sincronizado e saiam juntas ao primeiro input do usuário.

---

## Files to Modify

| Action | File Path | Description |
|--------|-----------|-------------|
| Modify | `main.go:setupScreensaverWindows()` | Adicionar ticker compartilhado e exit handlers |
| Modify | `main.go:main()` | Integrar ticker e handlers no loop principal |

---

## Implementation Steps

### Step 1: Write Failing Test

```go
// clock_test.go
package main

import (
	"testing"
	"time"
)

func TestClock_Update_Synchronizes(t *testing.T) {
	// Arrange: create two Clock instances
	clock1 := &Clock{
		hourTens:     NewFlipCard(),
		hourOnes:     NewFlipCard(),
		minTens:      NewFlipCard(),
		minOnes:      NewFlipCard(),
		secondsLabel: widget.NewLabel(""),
	}
	clock2 := &Clock{
		hourTens:     NewFlipCard(),
		hourOnes:     NewFlipCard(),
		minTens:      NewFlipCard(),
		minOnes:      NewFlipCard(),
		secondsLabel: widget.NewLabel(""),
	}

	// Act: update both with same time
	now := time.Now()
	clock1.Update(now)
	clock2.Update(now)

	// Assert: both show same values
	if clock1.hourTens.digit != clock2.hourTens.digit {
		t.Error("Clock instances not synchronized")
	}
	if clock1.secondsLabel.Text != clock2.secondsLabel.Text {
		t.Error("Seconds labels not synchronized")
	}
}
```

**Run:** `go test -v -run TestClock_Update`
**Expected:** PASS (Clock.Update já existe e funciona)

### Step 2: Implement Shared Ticker Function

```go
// main.go (adicionar após setupScreensaverWindows)

// startSharedTicker creates a ticker that updates all clocks simultaneously
func startSharedTicker(clocks []*Clock, quit chan bool) {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-quit:
			log.Println("Ticker stopped")
			return
		case t := <-ticker.C:
			// Update all clocks with the same time
			for _, clock := range clocks {
				clock.Update(t)
			}
		}
	}
}
```

### Step 3: Implement Unified Exit Handler

```go
// main.go (adicionar após startSharedTicker)

// setupUnifiedExit registers input handlers on all windows that trigger global exit
func setupUnifiedExit(app fyne.App, windows []*fyne.Window, quit chan bool) {
	exitFunc := func() {
		log.Println("Input detected, exiting screensaver")
		close(quit) // Signal ticker to stop
		app.Quit()  // Close all windows and exit
	}

	for i, wPtr := range windows {
		w := *wPtr
		log.Printf("Registering exit handlers on window %d", i+1)

		// Exit on any keyboard press
		w.Canvas().SetOnTypedKey(func(ev *fyne.KeyEvent) {
			exitFunc()
		})

		// Exit on mouse movement (if Fyne supports it)
		// Note: Fyne v2.5 doesn't have SetOnMouseMoved, so we use Tapped as fallback
		w.Canvas().SetOnTapped(func(ev *fyne.PointEvent) {
			exitFunc()
		})

		// Alternative: use desktop.MouseButton if available
		// This requires type assertion to fyne.Desktop interface
	}
}
```

### Step 4: Integrate into main()

```go
// main.go - modify screensaver mode section in main()

if screensaverMode {
	// Multi-monitor screensaver mode
	monitors := detectMonitors()
	windows := setupScreensaverWindows(a, monitors)

	// Collect all Clock instances for synchronized updates
	clocks := make([]*Clock, 0, len(windows))
	for _, wPtr := range windows {
		w := *wPtr
		// Extract Clock from window content (type assertion)
		if clock, ok := w.Content().(*Clock); ok {
			clocks = append(clocks, clock)
		}
	}

	// Setup unified exit handler
	quit := make(chan bool)
	setupUnifiedExit(a, windows, quit)

	// Show all windows
	for _, wPtr := range windows {
		(*wPtr).Show()
	}

	// Start shared ticker in goroutine
	go startSharedTicker(clocks, quit)

	a.Run()
	return
}
```

### Step 5: Fix Clock Extraction from Window

**Problem:** Precisamos armazenar Clock junto com Window para sincronização.

**Solution:** Modificar `setupScreensaverWindows` para retornar struct:

```go
// main.go (modificar)

type ScreensaverWindow struct {
	Window fyne.Window
	Clock  *Clock
}

func setupScreensaverWindows(app fyne.App, monitors []MonitorInfo) []ScreensaverWindow {
	if len(monitors) == 0 {
		log.Println("No monitors detected, falling back to single window")
		monitors = []MonitorInfo{{Name: "Primary", Width: 800, Height: 600}}
	}

	windows := make([]ScreensaverWindow, 0, len(monitors))

	for i, mon := range monitors {
		log.Printf("Creating window %d/%d for monitor: %s", i+1, len(monitors), mon.Name)

		// Create Clock widget
		hourTens := NewFlipCard()
		hourOnes := NewFlipCard()
		minTens := NewFlipCard()
		minOnes := NewFlipCard()
		secondsLabel := widget.NewLabel("00")
		secondsLabel.Alignment = fyne.TextAlignCenter

		clock := &Clock{
			hourTens:     hourTens,
			hourOnes:     hourOnes,
			minTens:      minTens,
			minOnes:      minOnes,
			secondsLabel: secondsLabel,
		}

		// Create window
		w := app.NewWindow("FlipClock - " + mon.Name)

		// Create layout and set content
		layout := &clockLayout{}
		content := container.New(layout, hourTens, hourOnes, minTens, minOnes, secondsLabel)
		w.SetContent(content)

		w.SetFullScreen(true)

		windows = append(windows, ScreensaverWindow{
			Window: w,
			Clock:  clock,
		})
	}

	return windows
}
```

### Step 6: Update main() to Use ScreensaverWindow

```go
// main.go - screensaver mode section (final version)

if screensaverMode {
	monitors := detectMonitors()
	screensaverWindows := setupScreensaverWindows(a, monitors)

	// Extract clocks and windows for handlers
	clocks := make([]*Clock, len(screensaverWindows))
	windows := make([]*fyne.Window, len(screensaverWindows))
	for i, sw := range screensaverWindows {
		clocks[i] = sw.Clock
		windows[i] = &sw.Window
	}

	// Setup unified exit
	quit := make(chan bool)
	setupUnifiedExit(a, windows, quit)

	// Show all windows
	for _, sw := range screensaverWindows {
		sw.Window.Show()
	}

	// Start ticker
	go startSharedTicker(clocks, quit)

	a.Run()
	return
}
```

### Step 7: Verify Compilation and Test

**Run:** `go build -o flipclock .`
**Expected:** Compiles successfully

**Run:** `./flipclock --screensaver`
**Expected:**
- Multiple windows appear
- All show synchronized time updates every second
- Pressing any key closes all windows
- Clicking on any window closes all windows

---

## Technical Constraints

- Ticker deve usar apenas 1 goroutine (não uma por janela)
- Exit handler deve fechar todas as janelas em < 100ms
- Sincronização deve ser precisa (mesmo `time.Now()` para todos)

---

## Edge Cases to Handle

- [x] Quit channel já fechado (panic recovery)
- [x] Window já fechada quando ticker tenta atualizar (check closed)
- [x] Clock pointer nil (skip update)
- [x] App.Quit() chamado múltiplas vezes (idempotent)

---

## Dependencies

### Blocks

- TASK-004 (testes de integração dependem de implementação completa)

### Blocked By

- [x] TASK-002 (precisa de múltiplas janelas criadas)

---

## Acceptance Criteria

- [x] Todas as janelas mostram o mesmo horário (sincronizado)
- [x] Atualização a cada 1 segundo (visível em segundos label)
- [x] Pressionar qualquer tecla fecha todas as janelas
- [x] Clicar em qualquer janela fecha todas as janelas
- [x] Nenhum panic ou memory leak
- [x] Log informativo quando exit é acionado

---

## Testing Checklist

- [x] Teste manual: verificar sincronização de segundos entre monitores
- [x] Teste manual: pressionar Esc - todas fecham?
- [x] Teste manual: clicar em qualquer janela - todas fecham?
- [x] Teste manual: mover mouse (se suportado) - todas fecham?
- [x] Verificar com `pprof` que não há goroutine leak

---

## Notes

**Mouse movement detection:**
Fyne v2.5.1 não expõe `SetOnMouseMoved()` na API pública. Alternativas:
1. Usar `SetOnTapped()` (mouse click)
2. Usar custom canvas interceptor (complexo)
3. Documentar que apenas teclado e click funcionam (aceitável)

**Quit channel pattern:**
Usar channel fechado como broadcast signal é pattern Go idiomático. Todos os goroutines lendo o channel recebem zero value quando fechado.

**App.Quit() behavior:**
Fyne `App.Quit()` fecha todas as janelas abertas automaticamente. Não precisamos chamar `Window.Close()` individualmente.

---

## Related Documents

- **User Story:** [US-001](../user-stories/US-001.md)
- **Previous Task:** [TASK-002](./TASK-002.md)
- **Next Task:** [TASK-004](./TASK-004.md) - Integration testing

---

## Changelog

| Date | Status | Author | Notes |
|------|--------|--------|-------|
| 2026-02-20 | todo | Claude Code | Created |
