package main

import (
	"testing"
)

func TestParseScreensaverArgs(t *testing.T) {
	tests := []struct {
		name     string
		args     []string
		wantMode bool
		wantExit bool
	}{
		{
			name:     "no args returns normal mode",
			args:     []string{},
			wantMode: false,
			wantExit: false,
		},
		{
			name:     "--screensaver flag enables screensaver mode",
			args:     []string{"--screensaver"},
			wantMode: true,
			wantExit: false,
		},
		{
			name:     "-screensaver flag enables screensaver mode",
			args:     []string{"-screensaver"},
			wantMode: true,
			wantExit: false,
		},
		{
			name:     "Windows /s enables screensaver mode",
			args:     []string{"/s"},
			wantMode: true,
			wantExit: false,
		},
		{
			name:     "Windows /S (uppercase) enables screensaver mode",
			args:     []string{"/S"},
			wantMode: true,
			wantExit: false,
		},
		{
			name:     "Windows /c exits gracefully (config not supported)",
			args:     []string{"/c"},
			wantMode: false,
			wantExit: true,
		},
		{
			name:     "Windows /C (uppercase) exits gracefully",
			args:     []string{"/C"},
			wantMode: false,
			wantExit: true,
		},
		{
			name:     "Windows /p exits gracefully (preview not supported)",
			args:     []string{"/p"},
			wantMode: false,
			wantExit: true,
		},
		{
			name:     "Windows /p with HWND exits gracefully",
			args:     []string{"/p", "12345"},
			wantMode: false,
			wantExit: true,
		},
		{
			name:     "unknown args return normal mode",
			args:     []string{"--unknown"},
			wantMode: false,
			wantExit: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gotMode, gotExit := parseScreensaverArgs(tt.args)
			if gotMode != tt.wantMode {
				t.Errorf("parseScreensaverArgs(%v) mode = %v, want %v", tt.args, gotMode, tt.wantMode)
			}
			if gotExit != tt.wantExit {
				t.Errorf("parseScreensaverArgs(%v) exit = %v, want %v", tt.args, gotExit, tt.wantExit)
			}
		})
	}
}
