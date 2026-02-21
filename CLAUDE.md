# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FlipClock is a minimal desktop flip clock widget built with Go and the Fyne v2 GUI toolkit. It renders a dark-mode window with large hour/minute flip-card digits (24-hour format), a seconds label, flip animation, responsive layout, fullscreen mode, and system tray integration.

## Tech Stack

| Component | Technology | Version | Notes |
|-----------|-----------|---------|-------|
| Language | Go | 1.22+ | |
| GUI Framework | Fyne | v2.5.1 | |
| Font | Bebas Neue Regular | embedded via `go:embed` | |
| System Tray | fyne.io/systray | v1.11.0 (indirect) | |
| OpenGL | go-gl/gl + go-gl/glfw | for hardware-accelerated rendering | |
| **Multi-Monitor** | **go-gl/glfw** | **v3.3.8** | **Monitor detection for screensaver mode** |

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

```bash
# Run all tests
go test -v ./...

# Run specific test
go test -v -run TestDetectMonitors

# Check test coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

**Current test coverage:** 21 tests covering monitor detection, window creation, synchronization, and CLI parsing.

## Project Structure

```
flipclock/
├── main.go                  # Application code (widgets, layout, tray, main loop)
├── monitors.go              # Multi-monitor detection using GLFW
├── font.go                  # Embedded font resource (BebasNeue via go:embed)
├── bundled.go               # Embedded icon resources
├── monitors_test.go         # Monitor detection tests
├── window_test.go           # Multi-window screensaver tests
├── sync_test.go             # Clock synchronization tests
├── screensaver_test.go      # CLI argument parsing tests
├── fonts/
│   └── BebasNeue-Regular.ttf   # Custom display font (61KB, OFL license)
├── docs/                    # SDLC documentation (PRD, ADR, User Stories, Tasks)
├── go.mod                   # Module definition (flipclock)
├── go.sum                   # Dependency checksums
├── CLAUDE.md                # This file
└── README.md                # User-facing documentation
```

## Architecture

The codebase follows a modular structure with clear separation of concerns.

### Core Files

**font.go**

- Embeds BebasNeue-Regular.ttf font into binary using `go:embed`
- Exports `fontBold` as `fyne.Resource` for custom theme

**monitors.go** (NEW - multi-monitor support)

- `MonitorInfo` struct: holds Name, X, Y, Width, Height for each display
- `detectMonitors()`: queries GLFW for connected monitors, returns slice
- Graceful degradation: returns empty slice on GLFW failure (fallback to single-monitor)
- Logs monitor detection for debugging

**main.go sections**

1. **Colors** - Dark mode palette (`#000`, `#1A1A1A`, `#FFF`, `#555`)
2. **flipTheme** - Custom Fyne theme with BebasNeue font
3. **FlipCard widget** - Custom widget with two-phase flip animation (300ms ease-in-out)
4. **clockLayout** - Responsive layout maintaining 5:6 card aspect ratio
5. **Clock** - State struct with `Update()` method and `pad2` helper
6. **Screensaver Mode** - Multi-monitor window creation:
   - `ScreensaverWindow` struct: pairs Window with Clock
   - `setupScreensaverWindows()`: creates one fullscreen window per monitor
   - `startSharedTicker()`: synchronizes clock updates across all windows
   - `setupUnifiedExit()`: registers input handlers on all windows
7. **main()** - Two modes:
   - **Screensaver:** Multi-monitor detection → window creation → unified ticker
   - **Normal:** Single window with tray integration and shortcuts

### Key Patterns

**Custom widget rendering**

- FlipCard implements `CreateRenderer()` returning `flipCardRenderer`
- Manual canvas object positioning in `Layout()` - standard Fyne pattern

**Two-phase flip animation**

- `fyne.NewAnimation()` with 300ms duration, ease-in-out curve
- Phase 1 (0-50%): top flap shrinks from top toward hinge
- Phase 2 (50-100%): bottom flap shrinks from bottom toward hinge

**Multi-monitor synchronization** (NEW)

- GLFW monitor detection via `glfw.GetMonitors()`
- One Fyne window created per detected monitor
- Shared `time.Ticker` updates all Clock instances simultaneously
- Unified exit: any input closes all windows via channel signal

**Responsive layout**

- `clockLayout` calculates card dimensions from height (78%) and width constraints
- Minimum dimension prevents overflow
- Seconds label scales proportionally (8% of card height, min 14px)

**System tray**

- Close-intercept hides window instead of quitting (normal mode only)
- Linux GNOME requires AppIndicator extension

**Embedded resources**

- `go:embed` for BebasNeue TTF font (zero runtime I/O)
- `fyne bundle` for app icon resources

### Keyboard shortcuts

| Key | Action |
|-----|--------|
| `Esc` | Exit fullscreen, or hide to tray if not fullscreen |
| `Q` | Hide to tray |
| `F` / `F11` | Toggle fullscreen |

### System tray menu

| Item | Action |
|------|--------|
| Show | Show and focus window |
| Fullscreen | Toggle fullscreen |
| Quit | Quit application |

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
