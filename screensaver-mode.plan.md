# Screensaver Mode Implementation Plan

## Overview

Add screensaver mode to FlipClock with cross-platform support (Linux X11 and Windows). In screensaver mode, the app launches fullscreen with hidden cursor and exits on any keyboard/mouse input.

## Goals

1. Launch FlipClock in screensaver mode via CLI flag
2. Exit on any mouse movement or keyboard press
3. Hide cursor and system tray in screensaver mode
4. Windows: Support `.scr` arguments (`/s`, `/p`, `/c`)
5. Linux: Provide XScreenSaver configuration

## Tasks

### Task 1: Add CLI flag parsing and screensaver mode detection

**Steps:**

1. Add `flag` import to main.go
2. Define `screensaverMode` boolean flag before `main()`
3. Parse CLI flags in `main()` before app creation
4. Handle Windows `.scr` arguments: map `/s` → screensaver mode, `/c` → config (no-op), `/p` → preview (no-op)
5. Store screensaver mode state in a global or pass to window setup

**Acceptance:**

- `--screensaver` or `-screensaver` flag sets screensaver mode
- Windows: `flipclock.scr /s` launches in screensaver mode
- Windows: `/c` and `/p` exit gracefully (preview not supported)

**Verification:**

```bash
go run . --screensaver  # should launch fullscreen
go run . -screensaver   # should launch fullscreen
# Windows test (manual): flipclock.scr /s
```

---

### Task 2: Implement screensaver mode window setup

**Steps:**

1. After window creation (`w := a.NewWindow(...)`), check if screensaver mode is active
2. If screensaver mode:
   - Call `w.SetFullScreen(true)` before showing window
   - Disable system tray setup (skip `desk.SetSystemTrayMenu()`)
   - Disable close intercept (skip `w.SetCloseIntercept()`)
3. Hide cursor in screensaver mode using Fyne driver API:
   - Check if `w.Canvas()` supports cursor hiding (may need type assertion)
   - Call cursor hide method if available

**Acceptance:**

- Screensaver mode launches directly in fullscreen
- System tray icon does not appear
- Window closes immediately on close button (no tray intercept)

**Verification:**

```bash
go run . --screensaver
# Verify: fullscreen launch, no tray icon, cursor hidden
```

---

### Task 3: Add input detection for screensaver exit

**Steps:**

1. Create `setupScreensaverExit()` function that takes window as parameter
2. Register keyboard handler that exits on ANY key press:
   - `w.Canvas().SetOnTypedKey(func(ev *fyne.KeyEvent) { a.Quit() })`
3. Register mouse movement handler (if Fyne v2.5 supports it):
   - Check Fyne docs/API for mouse move events
   - If available: `w.Canvas().SetOnMouseMoved(func(ev *fyne.PointEvent) { a.Quit() })`
   - If not available: document limitation (mouse click will still exit via keyboard handler or window close)
4. Call `setupScreensaverExit(w)` only when screensaver mode is active

**Acceptance:**

- Any keyboard press exits the screensaver
- Mouse movement exits the screensaver (if supported by Fyne)
- App quits cleanly without hanging

**Verification:**

```bash
go run . --screensaver
# Test: press any key → should exit
# Test: move mouse → should exit (if supported)
```

---

### Task 4: Create XScreenSaver configuration file for Linux

**Steps:**

1. Create `xscreensaver/flipclock.xml` in project root
2. Write XScreenSaver hack XML with:
   - `<screensaver>` root element
   - `name="FlipClock"`
   - `_label="FlipClock - Minimalist flip clock display"`
   - `<command>` pointing to binary: `flipclock --screensaver`
3. Add installation instructions to README for XScreenSaver integration:
   - Copy XML to `~/.config/xscreensaver/hacks/` or `/usr/share/xscreensaver/config/`
   - Binary must be in PATH or use absolute path in XML

**Acceptance:**

- Valid XScreenSaver XML file created
- XML contains correct binary invocation with `--screensaver` flag
- README documents installation steps

**Verification:**

```bash
# Validate XML syntax
xmllint --noout xscreensaver/flipclock.xml
# Manual test: configure in xscreensaver-settings
```

---

### Task 5: Add Windows .scr build instructions and documentation

**Steps:**

1. Add Windows build section to README with `.scr` compilation:

   ```bash
   GOOS=windows GOARCH=amd64 go build -ldflags "-s -w -H windowsgui" -o flipclock.scr .
   ```

2. Document `.scr` installation:
   - Right-click flipclock.scr → Install (copies to System32/SysWOW64)
   - Or manually copy to `C:\Windows\System32\`
3. Document supported arguments: `/s` (screensaver), `/c` (config - no-op), `/p` (preview - no-op)
4. Add note about preview mode limitation (Fyne cannot render into external HWND)

**Acceptance:**

- README contains Windows screensaver build command
- README documents installation and testing steps
- README explains preview mode limitation

**Verification:**

- Build Windows .scr binary (cross-compile from Linux if needed)
- Manual test on Windows: install and test via screensaver settings

---

### Task 6: Test end-to-end screensaver behavior

**Steps:**

1. Build Linux binary: `go build -ldflags "-s -w" -o flipclock .`
2. Test normal mode still works: `./flipclock` (should show window with tray icon)
3. Test screensaver mode: `./flipclock --screensaver`
   - Verify fullscreen launch
   - Verify cursor hidden
   - Verify no tray icon
   - Verify exit on keypress
   - Verify exit on mouse movement (if supported)
4. Test XScreenSaver integration (if XScreenSaver installed):
   - Copy XML to `~/.config/xscreensaver/hacks/flipclock.xml`
   - Run `xscreensaver-settings`, enable FlipClock
   - Test screensaver activation
5. Document any platform-specific issues found

**Acceptance:**

- Normal mode unchanged (regression test)
- Screensaver mode works as specified
- XScreenSaver integration functional (Linux)

**Verification:**

```bash
# Normal mode
./flipclock
# Screensaver mode
./flipclock --screensaver
# XScreenSaver test (manual)
```

---

## Notes

- **Cursor hiding**: Fyne v2.5 may not expose cursor control API directly. Check documentation and use desktop driver if needed.
- **Mouse movement detection**: Fyne's mouse event API may be limited. If `SetOnMouseMoved` not available, mouse clicks on window will still trigger exit via window focus/keyboard handler.
- **Preview mode**: Windows screensaver preview (small window in settings) requires rendering into parent HWND. Fyne does not support this - preview mode will be no-op (exit gracefully).
- **Git**: Do NOT commit changes. Leave all changes unstaged for orchestrator.

## Dependencies

- Go 1.22+
- Fyne v2.5.1 (already in go.mod)
- No additional dependencies needed

## Testing Strategy

1. Manual testing on Linux (native)
2. Cross-compile test for Windows (if possible)
3. XScreenSaver integration test (manual, requires XScreenSaver installed)
4. Regression test: ensure normal mode still works

## Rollback Plan

If implementation blocked:

- Revert changes to main.go
- Keep documentation for future implementation
- Report blocker to user for guidance
