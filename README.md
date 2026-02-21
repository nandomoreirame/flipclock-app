# FlipClock

Minimal desktop flip clock widget built with Go and Fyne v2.

![FlipClock Screenshot](images/screenshot.png)

## Features

- Hour and minute flip cards with animation (300ms, ease-in-out, two phases)
- Responsive layout that adapts to the window size
- Fullscreen mode (`F` / `F11` keys)
- **Multi-monitor support** - Screensaver mode covers all connected displays
- System tray with menu (Show / Fullscreen / Quit)
- Closing the window minimizes to tray (app keeps running)
- Bebas Neue font embedded in the binary (zero external file dependencies)
- Dark mode theme with minimalist palette
- 24-hour format

## Multi-Monitor Support

FlipClock automatically detects and covers all connected monitors when running in screensaver mode.

### Usage

```bash
# Launch screensaver on all monitors
./flipclock --screensaver
```

### Behavior

- **Automatic detection:** FlipClock queries your system for connected monitors at startup
- **Synchronized time:** All windows display the same time, updated every second
- **Unified exit:** Pressing any key closes all screensaver windows instantly

### Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **Linux X11** | ✅ Full support | All monitors detected, correct positioning |
| **Linux Wayland** | ⚠️ Partial | Monitors detected, but compositor controls window positioning |
| **Windows** | ✅ Full support | All monitors supported |
| **macOS** | ✅ Expected to work | (Not tested - community feedback welcome) |

### Known Limitations

- **Wayland positioning:** Window positions are controlled by the compositor, not the application. Windows will appear fullscreen but may not be in the expected monitor order.
- **Hot-plug:** Monitors must be connected before starting screensaver. Hot-plugging monitors during execution is not supported.
- **Preview mode:** Windows screensaver preview mode (small window in settings dialog) is not supported due to Fyne framework limitations.

### Troubleshooting

**Issue:** Only one window appears on multi-monitor setup

**Solution:** Check console output for error messages. GLFW monitor detection may fail in headless environments or if OpenGL drivers are not properly installed. Try:

```bash
DISPLAY=:0 ./flipclock --screensaver
```

**Issue:** Windows appear on wrong monitors (Wayland only)

**Expected behavior:** Wayland protocol doesn't allow applications to position windows. Use X11 for precise monitor control if needed.

**Issue:** Screensaver doesn't exit on input

**Solution:** Press any key directly. Mouse movement detection is not supported in Fyne v2.5.

## Stack

| Component | Technology |
|-----------|-----------|
| Language | [Go](https://go.dev/) 1.22+ |
| GUI | [Fyne](https://fyne.io/) v2.5.1 |
| Font | [Bebas Neue](https://fonts.google.com/specimen/Bebas+Neue) (OFL) |
| System Tray | [fyne.io/systray](https://github.com/nicoria/systray) |
| Rendering | OpenGL (via go-gl) |

## Download

Pre-built binaries are available on the [Releases](https://github.com/nandomoreirame/flipclock-app/releases/latest) page.

| Platform | Architecture | File |
|----------|-------------|------|
| Linux (.deb) | x86_64 | `flipclock_X.X.X-1_amd64.deb` |
| Linux (.deb) | ARM64 | `flipclock_X.X.X-1_arm64.deb` |
| Linux (.zip) | x86_64 | `FlipClock-X.X.X-linux-amd64.zip` |
| Linux (.zip) | ARM64 | `FlipClock-X.X.X-linux-arm64.zip` |
| Windows (.zip) | x64 | `FlipClock-X.X.X-windows-amd64.zip` |

## Installation

### Debian/Ubuntu (.deb)

```bash
# Download the .deb package from the releases page, then:
sudo dpkg -i flipclock_X.X.X-1_amd64.deb

# If there are missing dependencies:
sudo apt-get install -f
```

### Linux (zip with Makefile)

```bash
# Download and extract the .zip from the releases page, then:
unzip FlipClock-X.X.X-linux-amd64.zip
sudo make install
```

To uninstall:

```bash
sudo make uninstall
```

### Windows

1. Download `FlipClock-X.X.X-windows-amd64.zip` from the releases page
2. Extract the zip file
3. Run `FlipClock.exe`

### Build from source

Requires **Go 1.22+** and a **C/C++ compiler** with OpenGL libraries:

```bash
# Linux (Debian/Ubuntu)
sudo apt install gcc libgl1-mesa-dev xorg-dev

# macOS
xcode-select --install

# Windows: install TDM-GCC or MSYS2
```

```bash
# Clone the repository
git clone https://github.com/nandomoreirame/flipclock-app.git
cd flipclock-app

# Download dependencies
go mod tidy

# Run directly
go run .

# Build optimized binary
go build -ldflags "-s -w" -o flipclock .

# Windows (no console window)
go build -ldflags "-s -w -H windowsgui" -o flipclock.exe .
```

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `Esc` | Exit fullscreen, or minimize to tray |
| `Q` | Minimize to tray |
| `F` or `F11` | Toggle fullscreen |

## System Tray menu

| Item | Action |
|------|--------|
| Show | Display and focus the window |
| Fullscreen | Toggle fullscreen |
| Quit | Close the application |

### Tray on Linux (GNOME)

Vanilla GNOME does not display tray icons natively. Install the AppIndicator extension:

```bash
sudo apt install gnome-shell-extension-appindicator
# Restart the session or GNOME Shell
```

KDE, XFCE, macOS and Windows work out-of-the-box.

## Project structure

```
flipclock-app/
├── main.go                      # Application (widgets, layout, tray, loop)
├── font.go                      # Embedded font via go:embed
├── bundled.go                   # Embedded icon via fyne bundle
├── fonts/
│   └── BebasNeue-Regular.ttf    # Display font (61KB, OFL license)
├── images/
│   ├── flipclock.png            # App icon (256x256)
│   ├── flipclock@2x.png         # Retina icon (512x512)
│   └── flipclock.svg            # Vector icon
├── install.sh                   # Automatic installer (Linux/macOS/Windows)
├── flipclock.desktop            # Desktop entry for Linux
├── FyneApp.toml                 # App metadata for fyne package
├── go.mod                       # Go module definition
├── go.sum                       # Dependency checksums
├── CLAUDE.md                    # Claude Code instructions
└── README.md                    # This file
```

### main.go sections

| Section | Lines | Description |
|---------|-------|-------------|
| Colors | 16-26 | Dark mode palette (`#000`, `#1A1A1A`, `#FFF`, `#555`) |
| flipTheme | 28-57 | Custom Fyne theme (colors + BebasNeue font) |
| FlipCard | 59-200 | Custom widget with renderer and flip animation |
| clockLayout | 202-265 | Responsive layout with 5:6 card aspect ratio |
| Clock | 267-290 | Clock state + `Update()` method + `pad2` helper |
| main() | 292-402 | App setup, tray, shortcuts, 1-second ticker loop |

## Flip animation

The animation uses `fyne.NewAnimation()` with a 300ms duration and ease-in-out curve, split into two phases:

1. **Phase 1 (0-50%):** The top flap shrinks from the top toward the central hinge, revealing the new digit above
2. **Phase 2 (50-100%):** The bottom flap shrinks from the bottom toward the hinge, revealing the new digit below

The flaps use the same color as the card (`#1A1A1A`), simulating the mechanical effect of a real flip clock.

## Install from source

You can also install directly from source using the automatic script:

```bash
./install.sh
```

The script detects the OS (Linux, macOS, Windows), installs required dependencies, compiles the optimized binary, and registers the app in the system launcher. Run `./install.sh --uninstall` to remove.

## Roadmap

- [x] Flip animation (two-phase, 300ms ease-in-out)
- [x] Responsive layout (proportional to window size)
- [x] Fullscreen (F/F11 + tray menu)
- [x] Embedded custom font (Bebas Neue)
- [x] Custom icon for app, window, and tray
- [ ] 12h/24h toggle (via tray menu)
- [ ] Always-on-top
- [ ] Light theme
- [ ] Persistent settings (JSON)

## Contributing

1. Fork the repository
2. Create a branch for your feature (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m "feat: feature description"`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

### Conventions

- Commits follow [Conventional Commits](https://www.conventionalcommits.org/)
- Code, variables, and comments in English
- Tests with `go test ./...`

## Credits

- **Font:** [Bebas Neue](https://fonts.google.com/specimen/Bebas+Neue) by Ryoichi Tsunekawa (SIL Open Font License)
- **GUI:** [Fyne](https://fyne.io/) toolkit for Go

## License

MIT
