#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# FlipClock Installer
# Detects OS, installs dependencies, compiles
# and installs the app in the system launcher.
# ─────────────────────────────────────────────

APP_NAME="FlipClock"
APP_ID="com.flipclock.app"
BIN_NAME="flipclock"
VERSION="1.0.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors ──────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step()  { echo -e "\n${BOLD}>>> $*${NC}"; }

# ─── OS Detection ────────────────────────────

detect_os() {
    case "$(uname -s)" in
        Linux*)  OS="linux" ;;
        Darwin*) OS="darwin" ;;
        MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
        *)
            error "OS not supported: $(uname -s)"
            exit 1
            ;;
    esac
}

detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_ID_LIKE="${ID_LIKE:-}"
    else
        DISTRO_ID="unknown"
        DISTRO_ID_LIKE=""
    fi
}

is_debian_based() {
    [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" || \
       "$DISTRO_ID" == "pop" || "$DISTRO_ID" == "linuxmint" || \
       "$DISTRO_ID_LIKE" == *"debian"* || "$DISTRO_ID_LIKE" == *"ubuntu"* ]]
}

is_fedora_based() {
    [[ "$DISTRO_ID" == "fedora" || "$DISTRO_ID" == "rhel" || \
       "$DISTRO_ID" == "centos" || "$DISTRO_ID_LIKE" == *"fedora"* ]]
}

is_arch_based() {
    [[ "$DISTRO_ID" == "arch" || "$DISTRO_ID" == "manjaro" || \
       "$DISTRO_ID" == "endeavouros" || "$DISTRO_ID_LIKE" == *"arch"* ]]
}

# ─── Dependency Checks ──────────────────────

check_go() {
    if ! command -v go &>/dev/null; then
        error "Go not found. Install Go 1.22+ from https://go.dev/dl/"
        exit 1
    fi

    local go_version
    go_version="$(go version | grep -oP '\d+\.\d+' | head -1)"
    local go_major go_minor
    go_major="$(echo "$go_version" | cut -d. -f1)"
    go_minor="$(echo "$go_version" | cut -d. -f2)"

    if (( go_major < 1 || (go_major == 1 && go_minor < 22) )); then
        error "Go $go_version found, but 1.22+ is required."
        exit 1
    fi

    ok "Go $go_version detected"
}

check_gcc() {
    if command -v gcc &>/dev/null; then
        ok "gcc detected: $(gcc --version | head -1)"
        return 0
    fi
    return 1
}

# ─── Install System Dependencies ─────────────

install_deps_linux() {
    detect_linux_distro

    if check_gcc; then
        info "Build dependencies appear to be installed already."
        return 0
    fi

    step "Installing build dependencies"

    if is_debian_based; then
        info "Detected Debian/Ubuntu-based distro ($DISTRO_ID)"
        echo -e "${YELLOW}The following command requires sudo:${NC}"
        echo "  sudo apt install -y gcc libgl1-mesa-dev xorg-dev"
        read -rp "Proceed? [Y/n] " confirm
        if [[ "${confirm:-Y}" =~ ^[Yy]?$ ]]; then
            sudo apt update -qq
            sudo apt install -y gcc libgl1-mesa-dev xorg-dev
        else
            warn "Skipped. You may need to install dependencies manually."
            return 0
        fi

    elif is_fedora_based; then
        info "Detected Fedora/RHEL-based distro ($DISTRO_ID)"
        echo -e "${YELLOW}The following command requires sudo:${NC}"
        echo "  sudo dnf install -y gcc mesa-libGL-devel libXcursor-devel libXrandr-devel libXinerama-devel libXi-devel libXxf86vm-devel"
        read -rp "Proceed? [Y/n] " confirm
        if [[ "${confirm:-Y}" =~ ^[Yy]?$ ]]; then
            sudo dnf install -y gcc mesa-libGL-devel libXcursor-devel \
                libXrandr-devel libXinerama-devel libXi-devel libXxf86vm-devel
        else
            warn "Skipped. You may need to install dependencies manually."
            return 0
        fi

    elif is_arch_based; then
        info "Detected Arch-based distro ($DISTRO_ID)"
        echo -e "${YELLOW}The following command requires sudo:${NC}"
        echo "  sudo pacman -S --needed gcc mesa libxcursor libxrandr libxinerama libxi"
        read -rp "Proceed? [Y/n] " confirm
        if [[ "${confirm:-Y}" =~ ^[Yy]?$ ]]; then
            sudo pacman -S --needed --noconfirm gcc mesa libxcursor \
                libxrandr libxinerama libxi
        else
            warn "Skipped. You may need to install dependencies manually."
            return 0
        fi

    else
        warn "Unknown distro ($DISTRO_ID). Install gcc and OpenGL dev libraries manually."
        warn "Fyne requires: gcc, OpenGL headers, X11 dev headers."
        return 0
    fi

    ok "Build dependencies installed"
}

install_deps_darwin() {
    if xcode-select -p &>/dev/null; then
        ok "Xcode CLI tools detected"
    else
        step "Installing Xcode Command Line Tools"
        info "A system dialog will appear. Click 'Install' and wait."
        xcode-select --install 2>/dev/null || true
        warn "Run this script again after Xcode CLI tools finish installing."
        exit 0
    fi
}

install_deps_windows() {
    if check_gcc; then
        return 0
    fi

    warn "A C compiler (gcc) is required but was not found."
    warn "Install one of the following:"
    echo "  - TDM-GCC: https://jmeubank.github.io/tdm-gcc/"
    echo "  - MSYS2:   https://www.msys2.org/ (then: pacman -S mingw-w64-x86_64-gcc)"
    echo ""
    warn "After installing, restart your terminal and run this script again."
    exit 1
}

# ─── Build ───────────────────────────────────

build() {
    step "Building $APP_NAME v$VERSION"

    cd "$SCRIPT_DIR"

    info "Downloading dependencies..."
    go mod download

    local ldflags="-s -w"
    local output="$BIN_NAME"

    if [[ "$OS" == "windows" ]]; then
        ldflags="-s -w -H windowsgui"
        output="${BIN_NAME}.exe"
    fi

    info "Compiling (optimized)..."
    go build -ldflags "$ldflags" -o "$output" .

    ok "Built: $output ($(du -h "$output" | cut -f1))"
}

# ─── Install (Linux) ────────────────────────

install_linux() {
    step "Installing on Linux"

    local bin_dir="$HOME/.local/bin"
    local icon_dir="$HOME/.local/share/icons/hicolor/256x256/apps"
    local desktop_dir="$HOME/.local/share/applications"
    local bin_path="$bin_dir/$BIN_NAME"

    mkdir -p "$bin_dir" "$icon_dir" "$desktop_dir"

    # Binary
    cp "$SCRIPT_DIR/$BIN_NAME" "$bin_path"
    chmod +x "$bin_path"
    ok "Binary installed: $bin_path"

    # Icon
    cp "$SCRIPT_DIR/images/flipclock.png" "$icon_dir/flipclock.png"
    cp "$SCRIPT_DIR/images/flipclock.png" "$icon_dir/${APP_ID}.png"
    ok "Icon installed: $icon_dir/flipclock.png"

    # Desktop entry (with absolute Exec path)
    cat > "$desktop_dir/${APP_ID}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=Minimal flip clock desktop widget
Exec=$bin_path
Icon=flipclock
Categories=Utility;Clock;
StartupWMClass=$APP_ID
Terminal=false
EOF
    ok "Desktop entry installed: $desktop_dir/${APP_ID}.desktop"

    # Update caches
    gtk-update-icon-cache "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
    update-desktop-database "$desktop_dir" 2>/dev/null || true
    ok "Icon and desktop caches updated"

    # Check PATH
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        warn "$bin_dir is not in your PATH."
        warn "Add this to your shell config (~/.bashrc or ~/.zshrc):"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# ─── Install (macOS) ─────────────────────────

install_darwin() {
    step "Installing on macOS"

    local app_dir="$HOME/Applications"
    local app_bundle="$app_dir/${APP_NAME}.app"

    mkdir -p "$app_bundle/Contents/MacOS"
    mkdir -p "$app_bundle/Contents/Resources"

    # Binary
    cp "$SCRIPT_DIR/$BIN_NAME" "$app_bundle/Contents/MacOS/$BIN_NAME"
    chmod +x "$app_bundle/Contents/MacOS/$BIN_NAME"
    ok "Binary installed: $app_bundle/Contents/MacOS/$BIN_NAME"

    # Icon (convert PNG to ICNS if sips is available)
    if command -v sips &>/dev/null && command -v iconutil &>/dev/null; then
        local iconset_dir
        iconset_dir="$(mktemp -d)/flipclock.iconset"
        mkdir -p "$iconset_dir"

        sips -z 16 16     "$SCRIPT_DIR/images/flipclock.png" --out "$iconset_dir/icon_16x16.png"    &>/dev/null
        sips -z 32 32     "$SCRIPT_DIR/images/flipclock.png" --out "$iconset_dir/icon_16x16@2x.png" &>/dev/null
        sips -z 32 32     "$SCRIPT_DIR/images/flipclock.png" --out "$iconset_dir/icon_32x32.png"    &>/dev/null
        sips -z 64 64     "$SCRIPT_DIR/images/flipclock.png" --out "$iconset_dir/icon_32x32@2x.png" &>/dev/null
        sips -z 128 128   "$SCRIPT_DIR/images/flipclock.png" --out "$iconset_dir/icon_128x128.png"  &>/dev/null
        sips -z 256 256   "$SCRIPT_DIR/images/flipclock.png" --out "$iconset_dir/icon_128x128@2x.png" &>/dev/null
        sips -z 256 256   "$SCRIPT_DIR/images/flipclock.png" --out "$iconset_dir/icon_256x256.png"  &>/dev/null
        sips -z 512 512   "$SCRIPT_DIR/images/flipclock.png" --out "$iconset_dir/icon_256x256@2x.png" &>/dev/null

        iconutil -c icns "$iconset_dir" -o "$app_bundle/Contents/Resources/flipclock.icns"
        rm -rf "$(dirname "$iconset_dir")"
        ok "Icon converted to .icns"
    else
        cp "$SCRIPT_DIR/images/flipclock.png" "$app_bundle/Contents/Resources/flipclock.png"
        warn "sips/iconutil not found, using PNG icon (may not show in Dock)"
    fi

    # Info.plist
    local icon_file="flipclock"
    if [ -f "$app_bundle/Contents/Resources/flipclock.icns" ]; then
        icon_file="flipclock.icns"
    else
        icon_file="flipclock.png"
    fi

    cat > "$app_bundle/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$BIN_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$APP_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleIconFile</key>
    <string>$icon_file</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF
    ok "Info.plist created"
    ok "App bundle installed: $app_bundle"

    info "You can find $APP_NAME in ~/Applications or Launchpad."
}

# ─── Install (Windows) ───────────────────────

install_windows() {
    step "Installing on Windows"

    local install_dir="$LOCALAPPDATA/FlipClock"
    local exe_name="${BIN_NAME}.exe"

    mkdir -p "$install_dir"

    cp "$SCRIPT_DIR/$exe_name" "$install_dir/$exe_name"
    ok "Binary installed: $install_dir/$exe_name"

    # Copy icon
    cp "$SCRIPT_DIR/images/flipclock.png" "$install_dir/flipclock.png"

    # Create Start Menu shortcut via PowerShell
    info "Creating Start Menu shortcut..."
    local start_menu
    start_menu="$(powershell.exe -NoProfile -Command '[Environment]::GetFolderPath("StartMenu")' 2>/dev/null | tr -d '\r')"

    if [ -n "$start_menu" ]; then
        local shortcut_dir
        shortcut_dir="$(wslpath "$start_menu" 2>/dev/null || echo "$start_menu")/Programs"
        mkdir -p "$shortcut_dir" 2>/dev/null || true

        # Use PowerShell to create .lnk shortcut
        local win_install_dir
        win_install_dir="$(cygpath -w "$install_dir" 2>/dev/null || echo "$install_dir")"

        if powershell.exe -NoProfile -Command "
            \$ws = New-Object -ComObject WScript.Shell;
            \$s = \$ws.CreateShortcut('$shortcut_dir\\FlipClock.lnk');
            \$s.TargetPath = '$win_install_dir\\$exe_name';
            \$s.WorkingDirectory = '$win_install_dir';
            \$s.Description = 'Minimal flip clock desktop widget';
            \$s.Save()
        " 2>/dev/null; then
            ok "Start Menu shortcut created"
        else
            warn "Could not create Start Menu shortcut."
        fi
    else
        warn "Could not detect Start Menu path. Add a shortcut manually."
        info "Binary location: $install_dir/$exe_name"
    fi
}

# ─── Uninstall ───────────────────────────────

uninstall() {
    step "Uninstalling $APP_NAME"

    case "$OS" in
        linux)
            rm -f "$HOME/.local/bin/$BIN_NAME"
            rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/flipclock.png"
            rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/${APP_ID}.png"
            rm -f "$HOME/.local/share/applications/${APP_ID}.desktop"
            gtk-update-icon-cache "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
            update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
            ok "Removed from Linux"
            ;;
        darwin)
            rm -rf "$HOME/Applications/${APP_NAME}.app"
            ok "Removed from macOS"
            ;;
        windows)
            local install_dir="$LOCALAPPDATA/FlipClock"
            rm -rf "$install_dir"
            info "Start Menu shortcut may need to be removed manually."
            ok "Removed from Windows"
            ;;
    esac

    ok "$APP_NAME uninstalled successfully."
}

# ─── Main ────────────────────────────────────

main() {
    echo -e "${BOLD}"
    echo "  _____ _ _       ____ _            _    "
    echo " |  ___| (_)_ __ / ___| | ___   ___| | __"
    echo " | |_  | | | '_ \| |   | |/ _ \ / __| |/ /"
    echo " |  _| | | | |_) | |___| | (_) | (__|   < "
    echo " |_|   |_|_| .__/ \____|_|\___/ \___|_|\_\\"
    echo "            |_|          Installer v$VERSION"
    echo -e "${NC}"

    detect_os
    info "Detected OS: $OS"

    # Handle --uninstall flag
    if [[ "${1:-}" == "--uninstall" ]]; then
        uninstall
        exit 0
    fi

    # Install dependencies
    case "$OS" in
        linux)   install_deps_linux ;;
        darwin)  install_deps_darwin ;;
        windows) install_deps_windows ;;
    esac

    # Check Go
    check_go

    # Build
    build

    # Install
    case "$OS" in
        linux)   install_linux ;;
        darwin)  install_darwin ;;
        windows) install_windows ;;
    esac

    # Clean up build artifact
    rm -f "$SCRIPT_DIR/$BIN_NAME" "$SCRIPT_DIR/${BIN_NAME}.exe"

    echo ""
    echo -e "${GREEN}${BOLD}$APP_NAME installed successfully!${NC}"
    echo ""

    case "$OS" in
        linux)
            info "Launch from your app launcher or run: $BIN_NAME"
            ;;
        darwin)
            info "Launch from ~/Applications or Spotlight."
            ;;
        windows)
            info "Launch from the Start Menu or run the exe directly."
            ;;
    esac
}

main "$@"
