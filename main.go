package main

import (
	"image/color"
	"log"
	"os"
	"strings"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/driver/desktop"
	"fyne.io/fyne/v2/theme"
	"fyne.io/fyne/v2/widget"
)

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────

var (
	colorBG    = color.NRGBA{R: 0x00, G: 0x00, B: 0x00, A: 0xFF} // #000000
	colorCard  = color.NRGBA{R: 0x1A, G: 0x1A, B: 0x1A, A: 0xFF} // #1A1A1A
	colorDigit = color.NRGBA{R: 0xFF, G: 0xFF, B: 0xFF, A: 0xFF} // #FFFFFF
	colorLine  = color.NRGBA{R: 0x00, G: 0x00, B: 0x00, A: 0xFF} // #000000
	colorSmall = color.NRGBA{R: 0x55, G: 0x55, B: 0x55, A: 0xFF} // #555555
)

// ─────────────────────────────────────────────
// CUSTOM THEME
// ─────────────────────────────────────────────

type flipTheme struct{}

func (flipTheme) Color(n fyne.ThemeColorName, v fyne.ThemeVariant) color.Color {
	switch n {
	case theme.ColorNameBackground:
		return colorBG
	case theme.ColorNameForeground:
		return colorDigit
	}
	return theme.DefaultTheme().Color(n, v)
}

func (flipTheme) Font(s fyne.TextStyle) fyne.Resource {
	if s.Bold {
		return fontBold
	}
	return theme.DefaultTheme().Font(s)
}

func (flipTheme) Icon(n fyne.ThemeIconName) fyne.Resource {
	return theme.DefaultTheme().Icon(n)
}

func (flipTheme) Size(n fyne.ThemeSizeName) float32 {
	return theme.DefaultTheme().Size(n)
}

// ─────────────────────────────────────────────
// FLIP CARD WIDGET
// ─────────────────────────────────────────────

type FlipCard struct {
	widget.BaseWidget
	value        string  // "00".."59" or "00".."12"
	animating    bool    // prevents overlapping animations
	flipProgress float32 // 0.0 → 1.0 during animation
}

func NewFlipCard(value string) *FlipCard {
	c := &FlipCard{value: value}
	c.ExtendBaseWidget(c)
	return c
}

func (c *FlipCard) SetValue(v string) {
	if v == c.value || c.animating {
		return
	}
	c.value = v
	c.animating = true
	c.flipProgress = 0
	c.Refresh()

	anim := fyne.NewAnimation(time.Millisecond*300, func(progress float32) {
		c.flipProgress = progress
		c.Refresh()
		if progress >= 1.0 {
			c.animating = false
			c.flipProgress = 0
			c.Refresh()
		}
	})
	anim.Curve = fyne.AnimationEaseInOut
	anim.Start()
}

func (c *FlipCard) CreateRenderer() fyne.WidgetRenderer {
	bg := canvas.NewRectangle(colorCard)
	bg.CornerRadius = 16

	line := canvas.NewRectangle(colorLine)

	digit := canvas.NewText(c.value, colorDigit)
	digit.TextStyle = fyne.TextStyle{Bold: true}
	digit.TextSize = 96

	topFlap := canvas.NewRectangle(colorCard)
	bottomFlap := canvas.NewRectangle(colorCard)

	return &flipCardRenderer{
		card:       c,
		bg:         bg,
		line:       line,
		digit:      digit,
		topFlap:    topFlap,
		bottomFlap: bottomFlap,
	}
}

type flipCardRenderer struct {
	card       *FlipCard
	bg         *canvas.Rectangle
	line       *canvas.Rectangle
	digit      *canvas.Text
	topFlap    *canvas.Rectangle
	bottomFlap *canvas.Rectangle
}

func (r *flipCardRenderer) Layout(size fyne.Size) {
	r.bg.Resize(size)
	r.bg.Move(fyne.NewPos(0, 0))
	r.bg.CornerRadius = size.Width * 0.04

	// Horizontal hinge line at vertical center (3x thicker)
	lineH := float32(6)
	hinge := size.Height / 2
	r.line.Resize(fyne.NewSize(size.Width, lineH))
	r.line.Move(fyne.NewPos(0, hinge-lineH/2))

	// Center digit equally distributed (no offset)
	r.digit.TextSize = size.Height * 0.82
	r.digit.Refresh()
	dSize := fyne.MeasureText(r.digit.Text, r.digit.TextSize, r.digit.TextStyle)
	r.digit.Move(fyne.NewPos(
		(size.Width-dSize.Width)/2,
		(size.Height-dSize.Height)/2+size.Height*0.04,
	))

	r.layoutFlaps(size)
}

func (r *flipCardRenderer) layoutFlaps(size fyne.Size) {
	halfH := size.Height / 2
	p := r.card.flipProgress

	if p <= 0 || p >= 1 {
		r.topFlap.Resize(fyne.NewSize(0, 0))
		r.bottomFlap.Resize(fyne.NewSize(0, 0))
		return
	}

	if p <= 0.5 {
		// Phase 1: top flap shrinks from top toward hinge (reveals new top digit)
		phase := p * 2 // 0→1
		flapH := halfH * (1 - phase)
		r.topFlap.Resize(fyne.NewSize(size.Width, flapH))
		r.topFlap.Move(fyne.NewPos(0, 0))

		// Bottom flap covers entire bottom half
		r.bottomFlap.Resize(fyne.NewSize(size.Width, halfH))
		r.bottomFlap.Move(fyne.NewPos(0, halfH))
	} else {
		// Phase 2: bottom flap shrinks from bottom toward hinge (reveals new bottom digit)
		phase := (p - 0.5) * 2 // 0→1
		flapH := halfH * (1 - phase)
		r.bottomFlap.Resize(fyne.NewSize(size.Width, flapH))
		r.bottomFlap.Move(fyne.NewPos(0, size.Height-flapH))

		// Top flap fully retracted
		r.topFlap.Resize(fyne.NewSize(0, 0))
	}
}

func (r *flipCardRenderer) MinSize() fyne.Size {
	return fyne.NewSize(80, 100)
}

func (r *flipCardRenderer) Refresh() {
	r.digit.Text = r.card.value
	r.digit.Refresh()
	r.layoutFlaps(r.card.Size())
	canvas.Refresh(r.card)
}

func (r *flipCardRenderer) Objects() []fyne.CanvasObject {
	return []fyne.CanvasObject{r.bg, r.digit, r.topFlap, r.bottomFlap, r.line}
}

func (r *flipCardRenderer) Destroy() {}

// ─────────────────────────────────────────────
// RESPONSIVE CLOCK LAYOUT
// ─────────────────────────────────────────────
//
// Custom layout that sizes all clock elements proportionally
// to the available window space. Objects order:
//   [0] hourCard  [1] minCard  [2] secLabel

type clockLayout struct {
	secLabel *canvas.Text
}

func (l *clockLayout) MinSize(_ []fyne.CanvasObject) fyne.Size {
	return fyne.NewSize(300, 200)
}

func (l *clockLayout) Layout(objects []fyne.CanvasObject, size fyne.Size) {
	if len(objects) < 3 {
		return
	}

	// Card aspect ratio 5:6 (width:height)
	const cardRatio = 5.0 / 6.0

	// Derive card size from height constraint
	cardH := size.Height * 0.78
	cardW := cardH * cardRatio

	// Derive card size from width constraint
	// Reserve horizontal padding so cards don't touch window edges
	padding := size.Width * 0.06
	gap := size.Width * 0.05
	usableW := size.Width - 2*padding
	maxCardW := (usableW - gap) / 2
	if cardW > maxCardW {
		cardW = maxCardW
		cardH = cardW / cardRatio
	}

	totalW := cardW*2 + gap
	startX := (size.Width - totalW) / 2
	startY := (size.Height - cardH) / 2 * 0.9

	// Hour card
	objects[0].Resize(fyne.NewSize(cardW, cardH))
	objects[0].Move(fyne.NewPos(startX, startY))

	// Min card
	objects[1].Resize(fyne.NewSize(cardW, cardH))
	objects[1].Move(fyne.NewPos(startX+cardW+gap, startY))

	// Seconds label - bottom right
	labelSize := cardH * 0.08
	if labelSize < 14 {
		labelSize = 14
	}
	bottomY := startY + cardH + size.Height*0.02

	l.secLabel.TextSize = labelSize
	l.secLabel.Refresh()
	secSize := fyne.MeasureText(l.secLabel.Text, labelSize, l.secLabel.TextStyle)
	objects[2].Resize(secSize)
	objects[2].Move(fyne.NewPos(startX+totalW-secSize.Width, bottomY))
}

// ─────────────────────────────────────────────
// CLOCK STATE
// ─────────────────────────────────────────────

type Clock struct {
	hourCard *FlipCard
	minCard  *FlipCard
	secLabel *canvas.Text
}

func (cl *Clock) Update() {
	now := time.Now()
	cl.hourCard.SetValue(pad2(now.Hour()))
	cl.minCard.SetValue(pad2(now.Minute()))
	cl.secLabel.Text = pad2(now.Second())
	cl.secLabel.Refresh()
}

func pad2(n int) string {
	if n < 10 {
		return "0" + string(rune('0'+n))
	}
	return string(rune('0'+n/10)) + string(rune('0'+n%10))
}

// ─────────────────────────────────────────────
// SCREENSAVER MODE
// ─────────────────────────────────────────────

// ScreensaverWindow holds a window and its associated clock for multi-monitor screensaver
type ScreensaverWindow struct {
	Window  fyne.Window
	Clock   *Clock
	Monitor MonitorInfo
}

// setupScreensaverWindows creates windows for all monitors in screensaver mode
func setupScreensaverWindows(a fyne.App, monitors []MonitorInfo) []ScreensaverWindow {
	if len(monitors) == 0 {
		log.Println("No monitors detected, falling back to single window")
		monitors = []MonitorInfo{{Name: "Primary", Width: 800, Height: 600}}
	}

	windows := make([]ScreensaverWindow, 0, len(monitors))

	// Create one Clock instance per window (can't reuse Canvas content)
	for i, mon := range monitors {
		log.Printf("Creating window %d/%d for monitor: %s", i+1, len(monitors), mon.Name)

		// Create Clock widget components
		hourCard := NewFlipCard("00")
		minCard := NewFlipCard("00")

		// Seconds label (small, bottom-right)
		secLabel := canvas.NewText("00", colorSmall)
		secLabel.TextSize = 36
		secLabel.TextStyle = fyne.TextStyle{Monospace: true}

		clock := &Clock{
			hourCard: hourCard,
			minCard:  minCard,
			secLabel: secLabel,
		}

		// Initial render
		clock.Update()

		// Create window
		windowTitle := "FlipClock"
		if len(monitors) > 1 {
			windowTitle = "FlipClock - " + mon.Name
		}
		w := a.NewWindow(windowTitle)

		// Create layout and set content
		content := container.New(
			&clockLayout{secLabel: secLabel},
			hourCard, minCard, secLabel,
		)
		w.SetContent(content)

		// Size window to monitor resolution (positioning happens after Show via xdotool)
		w.Resize(fyne.NewSize(float32(mon.Width), float32(mon.Height)))

		windows = append(windows, ScreensaverWindow{
			Window:  w,
			Clock:   clock,
			Monitor: mon,
		})
	}

	return windows
}

// startSharedTicker creates a ticker that updates all clocks simultaneously
func startSharedTicker(clocks []*Clock, quit chan bool) {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-quit:
			log.Println("Ticker stopped")
			return
		case <-ticker.C:
			// Update all clocks with the same time
			for _, clock := range clocks {
				clock.Update()
			}
		}
	}
}

// setupUnifiedExit registers input handlers on all windows that trigger global exit
func setupUnifiedExit(a fyne.App, windows []ScreensaverWindow, quit chan bool, onExit func()) {
	exitFunc := func() {
		log.Println("Input detected, exiting screensaver")
		close(quit) // Signal ticker to stop
		if onExit != nil {
			onExit()
		} else {
			a.Quit() // Default behavior: close all windows and exit
		}
	}

	for i, sw := range windows {
		log.Printf("Registering exit handlers on window %d", i+1)

		w := sw.Window

		// Exit on any keyboard press
		w.Canvas().SetOnTypedKey(func(ev *fyne.KeyEvent) {
			exitFunc()
		})

		// Exit on any rune typed (letters, numbers, etc.)
		w.Canvas().SetOnTypedRune(func(_ rune) {
			exitFunc()
		})

		// Note: Fyne v2.5 doesn't expose mouse movement/click events on Canvas
		// Exit is triggered by keyboard input only
	}
}

// launchScreensaverFromTray launches multi-monitor screensaver mode from the system tray.
// When user exits screensaver (keypress), it closes screensaver windows and shows the main window.
func launchScreensaverFromTray(a fyne.App, mainWindow fyne.Window) {
	log.Println("Launching screensaver from tray menu")

	// Hide main window
	mainWindow.Hide()

	// Detect monitors and create fullscreen window on each
	monitors := detectMonitors()
	screensaverWindows := setupScreensaverWindows(a, monitors)

	// Extract clocks for synchronized ticker
	clocks := make([]*Clock, len(screensaverWindows))
	for i, sw := range screensaverWindows {
		clocks[i] = sw.Clock
	}

	// Setup unified exit handler that returns to main window
	quit := make(chan bool)
	setupUnifiedExit(a, screensaverWindows, quit, func() {
		// Close all screensaver windows
		for i, sw := range screensaverWindows {
			log.Printf("Closing screensaver window %d/%d", i+1, len(screensaverWindows))
			sw.Window.Close()
		}
		// Show main window again
		mainWindow.Show()
		mainWindow.RequestFocus()
		log.Println("Returned to normal mode")
	})

	// Show all windows (not fullscreen yet - need to position first)
	for i, sw := range screensaverWindows {
		log.Printf("Showing screensaver window %d/%d", i+1, len(screensaverWindows))
		sw.Window.Show()
	}

	// Position windows on correct monitors and fullscreen them
	go func() {
		if len(monitors) > 1 {
			if err := positionWindowsOnMonitors(screensaverWindows); err != nil {
				log.Printf("Window positioning: %v", err)
				// Fallback: use Fyne's native fullscreen (all on primary)
				for _, sw := range screensaverWindows {
					sw.Window.SetFullScreen(true)
				}
			}
			// X11 positioning already requests fullscreen per monitor
		} else {
			// Single monitor: use Fyne's native fullscreen
			for _, sw := range screensaverWindows {
				sw.Window.SetFullScreen(true)
			}
		}
	}()

	// Start shared ticker in goroutine
	go startSharedTicker(clocks, quit)
}

// parseScreensaverArgs checks CLI arguments for screensaver mode activation.
// Returns (screensaverMode, shouldExit).
// shouldExit is true for unsupported Windows .scr arguments (/c, /p).
func parseScreensaverArgs(args []string) (bool, bool) {
	for _, arg := range args {
		lower := strings.ToLower(arg)
		switch lower {
		case "--screensaver", "-screensaver":
			return true, false
		case "/s":
			return true, false
		case "/c":
			return false, true
		case "/p":
			return false, true
		}
	}
	return false, false
}

// ─────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────

func main() {
	screensaverMode, shouldExit := parseScreensaverArgs(os.Args[1:])
	if shouldExit {
		return
	}
	a := app.NewWithID("com.flipclock.app")
	a.SetIcon(resourceIconPng)
	a.Settings().SetTheme(flipTheme{})

	if screensaverMode {
		// ── Multi-Monitor Screensaver Mode ──────────────
		//
		// Detect monitors and create fullscreen window on each

		monitors := detectMonitors()
		screensaverWindows := setupScreensaverWindows(a, monitors)

		// Extract clocks for synchronized ticker
		clocks := make([]*Clock, len(screensaverWindows))
		for i, sw := range screensaverWindows {
			clocks[i] = sw.Clock
		}

		// Setup unified exit handler (CLI mode: exit app on keypress)
		quit := make(chan bool)
		setupUnifiedExit(a, screensaverWindows, quit, nil)

		// Show all windows (not fullscreen yet - need to position first)
		for i, sw := range screensaverWindows {
			log.Printf("Showing window %d/%d", i+1, len(screensaverWindows))
			sw.Window.Show()
		}

		// Position windows on correct monitors and fullscreen them
		go func() {
			if len(monitors) > 1 {
				if err := positionWindowsOnMonitors(screensaverWindows); err != nil {
					log.Printf("Window positioning: %v", err)
					// Fallback: use Fyne's native fullscreen (all on primary)
					for _, sw := range screensaverWindows {
						sw.Window.SetFullScreen(true)
					}
				}
				// X11 positioning already requests fullscreen per monitor
			} else {
				// Single monitor: use Fyne's native fullscreen
				for _, sw := range screensaverWindows {
					sw.Window.SetFullScreen(true)
				}
			}
		}()

		// Start shared ticker in goroutine
		go startSharedTicker(clocks, quit)

		// Run app (blocks until quit)
		a.Run()
		return
	}

	// ── Normal Mode (Single Window) ──────────────────────

	w := a.NewWindow("FlipClock")
	w.SetIcon(resourceIconPng)
	w.Resize(fyne.NewSize(800, 500))

	// ── Clock widgets ──────────────────────────

	hourCard := NewFlipCard("00")
	minCard := NewFlipCard("00")

	// Seconds (small, bottom-right)
	secLabel := canvas.NewText("00", colorSmall)
	secLabel.TextSize = 36
	secLabel.TextStyle = fyne.TextStyle{Monospace: true}

	cl := &Clock{
		hourCard: hourCard,
		minCard:  minCard,
		secLabel: secLabel,
	}
	cl.Update() // initial render

	// ── Layout ────────────────────────────────
	//
	//  ┌──────────┐   ┌──────────┐
	//  │    HH    │ : │    MM    │
	//  └──────────┘   └──────────┘
	//  AM              00  (sec)

	content := container.New(
		&clockLayout{secLabel: secLabel},
		hourCard, minCard, secLabel,
	)

	// ── Window setup ─────────────────────────

	w.SetContent(content)
	w.SetPadded(true)
	w.SetTitle("") // minimal title bar

	// ── Tray state ──────────────────────

	windowVisible := true
	showHideItem := fyne.NewMenuItem("Hide", nil)
	var trayMenu *fyne.Menu

	updateShowHide := func(visible bool) {
		windowVisible = visible
		if windowVisible {
			showHideItem.Label = "Hide"
		} else {
			showHideItem.Label = "Show"
		}
		if trayMenu != nil {
			trayMenu.Refresh()
		}
	}

	showHideItem.Action = func() {
		if windowVisible {
			w.Hide()
			updateShowHide(false)
		} else {
			w.Show()
			w.RequestFocus()
			updateShowHide(true)
		}
	}

	// ── Keyboard shortcuts ───────────────

	toggleFullscreen := func() {
		w.SetFullScreen(!w.FullScreen())
	}

	w.Canvas().SetOnTypedKey(func(ev *fyne.KeyEvent) {
		switch ev.Name {
		case fyne.KeyEscape:
			if w.FullScreen() {
				w.SetFullScreen(false)
			} else {
				w.Hide()
				updateShowHide(false)
			}
		case fyne.KeyQ:
			w.Hide()
			updateShowHide(false)
		case fyne.KeyF, fyne.KeyF11:
			toggleFullscreen()
		}
	})

	// ── System Tray ──────────────────────
	//
	// Vanilla GNOME: install gnome-shell-extension-appindicator
	// Ubuntu 22+ / KDE / macOS / Windows: works natively.

	if desk, ok := a.(desktop.App); ok {
		trayMenu = fyne.NewMenu("FlipClock",
			showHideItem,
			fyne.NewMenuItem("Fullscreen", func() {
				toggleFullscreen()
			}),
			fyne.NewMenuItem("Screensaver", func() {
				launchScreensaverFromTray(a, w)
			}),
		)
		desk.SetSystemTrayMenu(trayMenu)
		desk.SetSystemTrayIcon(resourceIconPng)
	}

	// Intercept window close → minimize to tray instead of quit
	w.SetCloseIntercept(func() {
		w.Hide()
		updateShowHide(false)
	})

	// ── Tick loop ─────────────────────────────

	go func() {
		ticker := time.NewTicker(time.Second)
		defer ticker.Stop()
		for range ticker.C {
			cl.Update()
		}
	}()

	// ── Show ─────────────────────────────────

	w.ShowAndRun()
}
