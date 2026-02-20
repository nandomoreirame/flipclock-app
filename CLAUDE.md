# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FlipClock is a minimal desktop flip clock widget built with Go and the Fyne v2 GUI toolkit. It renders a dark-mode window with large hour/minute flip-card digits (24-hour format), a seconds label, flip animation, responsive layout, fullscreen mode, and system tray integration.

## Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Language | Go | 1.22+ |
| GUI Framework | Fyne | v2.5.1 |
| Font | Bebas Neue Regular | embedded via `go:embed` |
| System Tray | fyne.io/systray | v1.11.0 (indirect) |
| OpenGL | go-gl/gl + go-gl/glfw | for hardware-accelerated rendering |

## Build and Run

```bash
# Install dependencies (requires Go 1.22+)
go mod tidy

# Run directly
go run .

# Build binary
go build -o flipclock .

# Build stripped binary (smaller, no debug symbols)
go build -ldflags "-s -w" -o flipclock .

# Windows (hide console window)
go build -ldflags "-s -w -H windowsgui" -o flipclock.exe .
```

**System prerequisites (Fyne needs a C compiler and OpenGL):**

- Linux: `sudo apt install gcc libgl1-mesa-dev xorg-dev`
- macOS: `xcode-select --install`
- Windows: TDM-GCC or MSYS2

## Testing

No tests exist yet. When adding tests, use standard `go test ./...`.

## Project Structure

```
flipclock/
├── main.go          # Application code (widgets, layout, tray, main loop)
├── font.go          # Embedded font resource (BebasNeue via go:embed)
├── fonts/
│   └── BebasNeue-Regular.ttf   # Custom display font (61KB, OFL license)
├── docs/
│   └── BRIEF.md     # Project brief and scope definition
├── go.mod           # Module definition (flipclock)
├── go.sum           # Dependency checksums
├── CLAUDE.md        # This file
└── README.md        # User-facing documentation (Portuguese)
```

## Architecture

The codebase is split across two Go files in a single `main` package (module `flipclock`).

### font.go

Embeds the BebasNeue-Regular.ttf font into the binary using `go:embed`. Exports `fontBold` as a `fyne.Resource` used by the custom theme for bold text rendering.

### main.go sections (in order)

1. **Colors** (lines 16-26) - NRGBA color palette: background `#000000`, card `#1A1A1A`, digits `#FFFFFF`, hinge line `#000000`, seconds text `#555555`
2. **flipTheme** (lines 28-57) - Custom `fyne.Theme` implementation overriding background/foreground colors and bold font (BebasNeue)
3. **FlipCard widget** (lines 59-200) - Custom widget (`widget.BaseWidget`) with `flipCardRenderer`. Features rounded card background, horizontal hinge line, centered digit text, and a two-phase flip animation (300ms ease-in-out)
4. **clockLayout** (lines 202-265) - Custom responsive layout manager maintaining 5:6 card aspect ratio with proportional sizing, horizontal padding (6%), gap (5%), and dynamic seconds label sizing
5. **Clock** (lines 267-290) - State struct holding FlipCard widgets and seconds label; `Update()` reads `time.Now()` and refreshes display (24-hour format). Includes `pad2` helper for zero-padding without `fmt.Sprintf`
6. **main()** (lines 292-402) - App setup (`com.flipclock.app`), layout composition, keyboard shortcuts (Esc/Q/F/F11), system tray menu, close-intercept for tray minimization, 1-second ticker goroutine

### Key patterns

- **Custom widget rendering**: FlipCard implements `CreateRenderer()` returning a `flipCardRenderer` that manually positions canvas objects in `Layout()`. This is the Fyne pattern for custom draw logic.
- **Two-phase flip animation**: `fyne.NewAnimation()` with 300ms duration. Phase 1 (0-50%): top flap shrinks from top toward hinge. Phase 2 (50-100%): bottom flap shrinks from bottom toward hinge. Both flaps use card background color to simulate mechanical flip.
- **Responsive layout**: `clockLayout` implements `fyne.Layout` to calculate card dimensions from both height (78% of window) and width constraints, taking the minimum to prevent overflow. Seconds label scales proportionally (8% of card height, min 14px).
- **System tray**: Close-intercept hides the window instead of quitting; the app stays alive in the system tray. Linux GNOME needs the AppIndicator extension.
- **Embedded font**: `go:embed` directive in `font.go` bakes BebasNeue TTF into the binary at compile time for zero runtime file I/O.
- **`pad2` helper**: Manual int-to-2-digit-string conversion without `fmt.Sprintf`.

### Keyboard shortcuts

| Key | Action |
|-----|--------|
| `Esc` | Exit fullscreen, or hide to tray if not fullscreen |
| `Q` | Hide to tray |
| `F` / `F11` | Toggle fullscreen |

### System tray menu

| Item | Action |
|------|--------|
| Mostrar | Show and focus window |
| Tela Cheia | Toggle fullscreen |
| Fechar | Quit application |

## Roadmap

- [x] Flip animation (two-phase, 300ms ease-in-out)
- [x] Responsive layout (proportional card sizing)
- [x] Fullscreen toggle (F/F11 keys + tray menu)
- [x] Embedded custom font (BebasNeue)
- [ ] 12h/24h toggle
- [ ] Always-on-top
- [ ] Light theme
- [ ] Persistent settings (JSON)
- [ ] Custom tray icon

## Bundle a tray icon

```bash
go install fyne.io/fyne/v2/cmd/fyne@latest
fyne bundle icon.png > bundled.go
# Then uncomment in main.go: desk.SetSystemTrayIcon(resourceIconPng)
```
