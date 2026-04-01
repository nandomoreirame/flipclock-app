# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

## [0.1.1] - 2026-04-01

### Changed

- Rewrite install.sh with platform detection (Debian, Arch/generic Linux, macOS, Windows).
- Use absolute icon path in .desktop entry for reliable icon resolution across launchers.
- Add previous installation cleanup before reinstalling.
- Add `--skip-build` and `--help` flags to installer.
- Fix process detection to use exact binary name match (prevents killing installer).

---

## [0.1.0] - 2026-04-01

### Added

- Add flip clock application with two-phase flip animation, responsive layout, fullscreen mode, system tray integration, and embedded BebasNeue font.
- Add multi-monitor screensaver mode with CLI argument parsing (--screensaver, /s, /c, /p), shared ticker synchronization, and unified exit handling.
- Add multi-monitor detection using GLFW with graceful degradation for unsupported platforms.
- Add XScreensaver integration configuration for Linux desktop environments.
- Add cross-platform installer script and desktop integration (.desktop file, AppStream metadata).
- Add application icon in PNG and SVG formats with window and system tray support.
- Add nfpm, Flatpak, and AppStream packaging configurations for Linux distribution.
- Add comprehensive test suite covering monitor detection, window creation, clock synchronization, and CLI parsing.
- Add GitHub Actions CI pipeline for automated testing on push and PR.
- Add GitHub Actions release pipeline triggered by tag creation with binary builds and automatic changelog.

### Changed

- Translate system tray labels from Portuguese to English (Show, Fullscreen, Quit).
- Translate README and CLAUDE.md to English for codebase consistency.
- Promote GLFW to direct dependency for multi-monitor detection.

### Fixed

- Replace deprecated libgl1-mesa-glx with libgl1 for Ubuntu compatibility.

---

