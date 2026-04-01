#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# FlipClock Installer
# Detects OS and distro, installs dependencies,
# compiles and installs the app per platform.
# ─────────────────────────────────────────────

APP_NAME="FlipClock"
APP_ID="com.flipclock.app"
BIN_NAME="flipclock"
VERSION="0.1.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SOURCE="$SCRIPT_DIR/images/flipclock.png"
ICON_SVG_SOURCE="$SCRIPT_DIR/images/flipclock.svg"

# ─── Colors ──────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[info]${NC}  $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }
step()  { echo -e "\n${BOLD}>>> $*${NC}"; }

# ─── Platform Detection ─────────────────────

PLATFORM=""
ARCH=""

detect_platform() {
    local kernel arch
    kernel="$(uname -s)"
    arch="$(uname -m)"

    case "$kernel" in
        Darwin)
            PLATFORM="macos"
            if [[ "$arch" == "arm64" ]]; then
                ARCH="arm64"
            else
                ARCH="x64"
            fi
            ;;
        Linux)
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                DISTRO_ID="${ID:-unknown}"
                DISTRO_ID_LIKE="${ID_LIKE:-}"
            else
                DISTRO_ID="unknown"
                DISTRO_ID_LIKE=""
            fi

            if [[ "$DISTRO_ID" == "debian" || "$DISTRO_ID" == "ubuntu" || \
                  "$DISTRO_ID" == "pop" || "$DISTRO_ID" == "linuxmint" || \
                  "$DISTRO_ID_LIKE" == *"debian"* || "$DISTRO_ID_LIKE" == *"ubuntu"* ]]; then
                PLATFORM="debian"
            else
                PLATFORM="linux"
            fi
            ARCH="x64"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            PLATFORM="windows"
            ARCH="x64"
            ;;
        *)
            error "Unsupported OS: $kernel"
            exit 1
            ;;
    esac

    info "Detected platform: ${PLATFORM} (${ARCH})"
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

install_deps() {
    case "$PLATFORM" in
        debian)
            if check_gcc; then
                info "Build dependencies appear to be installed already."
                return 0
            fi
            step "Installing build dependencies"
            info "Detected Debian/Ubuntu-based distro ($DISTRO_ID)"
            echo -e "${YELLOW}The following command requires sudo:${NC}"
            echo "  sudo apt install -y gcc libgl1-mesa-dev xorg-dev"
            read -rp "Proceed? [Y/n] " confirm
            if [[ "${confirm:-Y}" =~ ^[Yy]?$ ]]; then
                sudo apt update -qq
                sudo apt install -y gcc libgl1-mesa-dev xorg-dev
            else
                warn "Skipped. You may need to install dependencies manually."
            fi
            ;;
        linux)
            if check_gcc; then
                info "Build dependencies appear to be installed already."
                return 0
            fi
            step "Installing build dependencies"
            if [[ "${DISTRO_ID:-}" == "fedora" || "${DISTRO_ID:-}" == "rhel" || \
                  "${DISTRO_ID:-}" == "centos" || "${DISTRO_ID_LIKE:-}" == *"fedora"* ]]; then
                info "Detected Fedora/RHEL-based distro ($DISTRO_ID)"
                echo -e "${YELLOW}The following command requires sudo:${NC}"
                echo "  sudo dnf install -y gcc mesa-libGL-devel libXcursor-devel libXrandr-devel libXinerama-devel libXi-devel libXxf86vm-devel"
                read -rp "Proceed? [Y/n] " confirm
                if [[ "${confirm:-Y}" =~ ^[Yy]?$ ]]; then
                    sudo dnf install -y gcc mesa-libGL-devel libXcursor-devel \
                        libXrandr-devel libXinerama-devel libXi-devel libXxf86vm-devel
                else
                    warn "Skipped."
                fi
            elif [[ "${DISTRO_ID:-}" == "arch" || "${DISTRO_ID:-}" == "manjaro" || \
                    "${DISTRO_ID:-}" == "endeavouros" || "${DISTRO_ID_LIKE:-}" == *"arch"* ]]; then
                info "Detected Arch-based distro ($DISTRO_ID)"
                echo -e "${YELLOW}The following command requires sudo:${NC}"
                echo "  sudo pacman -S --needed gcc mesa libxcursor libxrandr libxinerama libxi"
                read -rp "Proceed? [Y/n] " confirm
                if [[ "${confirm:-Y}" =~ ^[Yy]?$ ]]; then
                    sudo pacman -S --needed --noconfirm gcc mesa libxcursor \
                        libxrandr libxinerama libxi
                else
                    warn "Skipped."
                fi
            else
                warn "Unknown distro (${DISTRO_ID:-unknown}). Install gcc and OpenGL dev libraries manually."
                warn "Fyne requires: gcc, OpenGL headers, X11 dev headers."
            fi
            ;;
        macos)
            if xcode-select -p &>/dev/null; then
                ok "Xcode CLI tools detected"
            else
                step "Installing Xcode Command Line Tools"
                info "A system dialog will appear. Click 'Install' and wait."
                xcode-select --install 2>/dev/null || true
                warn "Run this script again after Xcode CLI tools finish installing."
                exit 0
            fi
            ;;
        windows)
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
            ;;
    esac
}

# ─── Build ───────────────────────────────────

build() {
    step "Building $APP_NAME v$VERSION"

    cd "$SCRIPT_DIR"

    info "Downloading dependencies..."
    go mod download

    local ldflags="-s -w"
    local output="$BIN_NAME"

    if [[ "$PLATFORM" == "windows" ]]; then
        ldflags="-s -w -H windowsgui"
        output="${BIN_NAME}.exe"
    fi

    info "Compiling (optimized)..."
    go build -ldflags "$ldflags" -o "$output" .

    ok "Built: $output ($(du -h "$output" | cut -f1))"
}

# ─── Kill running processes ──────────────────

kill_running() {
    local pids
    # Use -x for exact binary name match (not substring of paths like install.sh)
    pids=$(pgrep -x "$BIN_NAME" 2>/dev/null || true)

    if [[ -z "$pids" ]]; then
        return
    fi

    warn "Running $APP_NAME process(es) detected: $pids"
    info "Stopping them before install..."

    for pid in $pids; do
        kill "$pid" 2>/dev/null || true
    done

    local waited=0
    while pgrep -x "$BIN_NAME" &>/dev/null && [[ $waited -lt 5 ]]; do
        sleep 1
        waited=$((waited + 1))
    done

    for pid in $pids; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
            warn "Force-killed PID $pid"
        fi
    done

    ok "$APP_NAME processes stopped"
}

# ─── Install: Debian (.deb-like) ─────────────

install_debian() {
    step "Installing on Debian/Ubuntu"

    local bin_dir="$HOME/.local/bin"
    local icon_dir="$HOME/.local/share/icons"
    local desktop_dir="$HOME/.local/share/applications"
    local bin_path="$bin_dir/$BIN_NAME"
    local icon_path="$icon_dir/${APP_ID}.png"

    mkdir -p "$bin_dir" "$icon_dir" "$desktop_dir"

    # Binary
    cp "$SCRIPT_DIR/$BIN_NAME" "$bin_path"
    chmod +x "$bin_path"
    ok "Binary installed: $bin_path"

    # Icon (single PNG in icons dir - absolute path in .desktop)
    cp "$ICON_SOURCE" "$icon_path"
    ok "Icon installed: $icon_path"

    # Desktop entry (absolute icon path for reliable resolution)
    cat > "$desktop_dir/${APP_ID}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
GenericName=Clock Widget
Comment=Minimal desktop flip clock widget
Exec=$bin_path
Icon=$icon_path
Categories=Utility;Clock;
StartupWMClass=$APP_ID
Terminal=false
Keywords=clock;flip;time;widget;
EOF
    ok "Desktop entry installed: $desktop_dir/${APP_ID}.desktop"

    update-desktop-database "$desktop_dir" 2>/dev/null || true

    # Check PATH
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        warn "$bin_dir is not in your PATH."
        warn "Add this to your shell config (~/.bashrc or ~/.zshrc):"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# ─── Install: Generic Linux (AppImage-style) ─

install_linux_generic() {
    step "Installing on Linux (${DISTRO_ID:-generic})"

    local install_dir="$HOME/.local/opt/$BIN_NAME"
    local bin_link="$HOME/.local/bin/$BIN_NAME"
    local icon_dir="$HOME/.local/share/icons"
    local desktop_dir="$HOME/.local/share/applications"
    local icon_path="$icon_dir/${APP_ID}.png"

    mkdir -p "$install_dir" "$HOME/.local/bin" "$icon_dir" "$desktop_dir"

    # Binary to opt dir
    cp "$SCRIPT_DIR/$BIN_NAME" "$install_dir/$BIN_NAME"
    chmod +x "$install_dir/$BIN_NAME"
    ok "Binary installed: $install_dir/$BIN_NAME"

    # Symlink
    ln -sf "$install_dir/$BIN_NAME" "$bin_link"
    ok "Symlink created: $bin_link -> $install_dir/$BIN_NAME"

    # Icon (absolute path in .desktop for reliable resolution)
    cp "$ICON_SOURCE" "$icon_path"
    ok "Icon installed: $icon_path"

    # Desktop entry with absolute paths
    cat > "$desktop_dir/${APP_ID}.desktop" << EOF
[Desktop Entry]
Type=Application
Version=${VERSION}
Name=$APP_NAME
GenericName=Clock Widget
Comment=Minimal desktop flip clock widget
Exec=${install_dir}/${BIN_NAME}
Icon=${icon_path}
Categories=Utility;Clock;
StartupWMClass=$APP_ID
Terminal=false
Keywords=clock;flip;time;widget;
StartupNotify=true
EOF
    ok "Desktop entry installed: $desktop_dir/${APP_ID}.desktop"

    update-desktop-database "$desktop_dir" 2>/dev/null || true

    # Check PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        warn "$HOME/.local/bin is not in your PATH."
        warn "Add this to your shell config (~/.bashrc or ~/.zshrc):"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# ─── Install: macOS (.app bundle) ────────────

install_macos() {
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
    local icon_file="flipclock.png"
    if command -v sips &>/dev/null && command -v iconutil &>/dev/null; then
        local iconset_dir
        iconset_dir="$(mktemp -d)/flipclock.iconset"
        mkdir -p "$iconset_dir"

        sips -z 16 16     "$ICON_SOURCE" --out "$iconset_dir/icon_16x16.png"       &>/dev/null
        sips -z 32 32     "$ICON_SOURCE" --out "$iconset_dir/icon_16x16@2x.png"    &>/dev/null
        sips -z 32 32     "$ICON_SOURCE" --out "$iconset_dir/icon_32x32.png"       &>/dev/null
        sips -z 64 64     "$ICON_SOURCE" --out "$iconset_dir/icon_32x32@2x.png"    &>/dev/null
        sips -z 128 128   "$ICON_SOURCE" --out "$iconset_dir/icon_128x128.png"     &>/dev/null
        sips -z 256 256   "$ICON_SOURCE" --out "$iconset_dir/icon_128x128@2x.png"  &>/dev/null
        sips -z 256 256   "$ICON_SOURCE" --out "$iconset_dir/icon_256x256.png"     &>/dev/null
        sips -z 512 512   "$ICON_SOURCE" --out "$iconset_dir/icon_256x256@2x.png"  &>/dev/null

        iconutil -c icns "$iconset_dir" -o "$app_bundle/Contents/Resources/flipclock.icns"
        rm -rf "$(dirname "$iconset_dir")"
        icon_file="flipclock.icns"
        ok "Icon converted to .icns"
    else
        cp "$ICON_SOURCE" "$app_bundle/Contents/Resources/flipclock.png"
        warn "sips/iconutil not found, using PNG icon (may not show in Dock)"
    fi

    # Info.plist
    cat > "$app_bundle/Contents/Info.plist" << EOF
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
}

# ─── Install: Windows ────────────────────────

install_windows() {
    step "Installing on Windows"

    local install_dir="$LOCALAPPDATA/FlipClock"
    local exe_name="${BIN_NAME}.exe"

    mkdir -p "$install_dir"

    cp "$SCRIPT_DIR/$exe_name" "$install_dir/$exe_name"
    ok "Binary installed: $install_dir/$exe_name"

    # Copy icon
    cp "$ICON_SOURCE" "$install_dir/flipclock.png"

    # Create Start Menu shortcut via PowerShell
    info "Creating Start Menu shortcut..."
    local start_menu
    start_menu="$(powershell.exe -NoProfile -Command '[Environment]::GetFolderPath("StartMenu")' 2>/dev/null | tr -d '\r')"

    if [ -n "$start_menu" ]; then
        local shortcut_dir
        shortcut_dir="$(wslpath "$start_menu" 2>/dev/null || echo "$start_menu")/Programs"
        mkdir -p "$shortcut_dir" 2>/dev/null || true

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

do_uninstall() {
    step "Uninstalling $APP_NAME"

    case "$PLATFORM" in
        debian)
            rm -f "$HOME/.local/bin/$BIN_NAME"
            rm -f "$HOME/.local/share/icons/${APP_ID}.png"
            rm -f "$HOME/.local/share/applications/${APP_ID}.desktop"
            update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
            ok "Removed from Linux (Debian)"
            ;;
        linux)
            local install_dir="$HOME/.local/opt/$BIN_NAME"
            local bin_link="$HOME/.local/bin/$BIN_NAME"
            local desktop_file="$HOME/.local/share/applications/${APP_ID}.desktop"

            [[ -L "$bin_link" ]] && rm "$bin_link" && ok "Removed symlink $bin_link"
            [[ -f "$desktop_file" ]] && rm "$desktop_file" && ok "Removed desktop entry"
            [[ -d "$install_dir" ]] && rm -rf "$install_dir" && ok "Removed install dir $install_dir"
            rm -f "$HOME/.local/share/icons/${APP_ID}.png"
            update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
            ok "Removed from Linux"
            ;;
        macos)
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

    ok "$APP_NAME uninstalled."
    exit 0
}

# ─── Clean previous installation ─────────────

do_clean_previous() {
    local found=false

    case "$PLATFORM" in
        debian)
            [[ -f "$HOME/.local/bin/$BIN_NAME" ]] && found=true
            ;;
        linux)
            [[ -d "$HOME/.local/opt/$BIN_NAME" ]] && found=true
            ;;
        macos)
            [[ -d "$HOME/Applications/${APP_NAME}.app" ]] && found=true
            ;;
        windows)
            [[ -d "$LOCALAPPDATA/FlipClock" ]] && found=true
            ;;
    esac

    if [[ "$found" == false ]]; then
        return
    fi

    info "Removing previous installation..."

    case "$PLATFORM" in
        debian)
            rm -f "$HOME/.local/bin/$BIN_NAME"
            rm -f "$HOME/.local/share/icons/${APP_ID}.png"
            rm -f "$HOME/.local/share/applications/${APP_ID}.desktop"
            ;;
        linux)
            rm -f "$HOME/.local/bin/$BIN_NAME"
            rm -rf "$HOME/.local/opt/$BIN_NAME"
            rm -f "$HOME/.local/share/icons/${APP_ID}.png"
            rm -f "$HOME/.local/share/applications/${APP_ID}.desktop"
            ;;
        macos)
            rm -rf "$HOME/Applications/${APP_NAME}.app"
            ;;
        windows)
            rm -rf "$LOCALAPPDATA/FlipClock"
            ;;
    esac

    ok "Previous installation removed"
}

# ─── Flags ───────────────────────────────────

SKIP_BUILD=false
UNINSTALL=false

for arg in "$@"; do
    case "$arg" in
        --skip-build) SKIP_BUILD=true ;;
        --uninstall)  UNINSTALL=true ;;
        --help|-h)
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo ""
            echo "Build and install ${APP_NAME} for the current platform."
            echo ""
            echo "Supported platforms:"
            echo "  Linux (Debian/Ubuntu)   Build and install binary + .desktop"
            echo "  Linux (Arch/other)      Build and install to ~/.local/opt/ + symlink"
            echo "  macOS                   Build and install .app bundle"
            echo "  Windows                 Build and install to AppData + Start Menu shortcut"
            echo ""
            echo "Options:"
            echo "  --skip-build   Skip build, install existing binary from source dir"
            echo "  --uninstall    Remove installed app"
            echo "  -h, --help     Show this help"
            exit 0
            ;;
        *)
            error "Unknown option: $arg"
            exit 1
            ;;
    esac
done

# ─── Main ────────────────────────────────────

echo -e "${BOLD}"
echo "  _____ _ _       ____ _            _    "
echo " |  ___| (_)_ __ / ___| | ___   ___| | __"
echo " | |_  | | | '_ \| |   | |/ _ \ / __| |/ /"
echo " |  _| | | | |_) | |___| | (_) | (__|   < "
echo " |_|   |_|_| .__/ \____|_|\___/ \___|_|\_\\"
echo "            |_|          Installer v$VERSION"
echo -e "${NC}"

detect_platform

if [[ "$UNINSTALL" == true ]]; then
    do_uninstall
fi

# Install dependencies
install_deps

# Check Go
check_go

# Build
if [[ "$SKIP_BUILD" == true ]]; then
    info "Skipping build (--skip-build)"
else
    build
fi

# Stop running instances and remove previous installation
kill_running
do_clean_previous

# Install per platform
case "$PLATFORM" in
    debian)  install_debian ;;
    linux)   install_linux_generic ;;
    macos)   install_macos ;;
    windows) install_windows ;;
esac

# Clean up build artifact
rm -f "$SCRIPT_DIR/$BIN_NAME" "$SCRIPT_DIR/${BIN_NAME}.exe"

# ─── Done ────────────────────────────────────

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} ${APP_NAME} v${VERSION} installed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

case "$PLATFORM" in
    debian)
        echo "  Run:           $BIN_NAME"
        echo "  App launcher:  Search for '$APP_NAME'"
        ;;
    linux)
        echo "  Run:           $BIN_NAME"
        echo "  App launcher:  Search for '$APP_NAME'"
        ;;
    macos)
        echo "  Open:          open ~/Applications/${APP_NAME}.app"
        echo "  Or search:     Spotlight > '$APP_NAME'"
        ;;
    windows)
        echo "  Run:           Search for '$APP_NAME' in Start Menu"
        ;;
esac

echo "  Uninstall:     $0 --uninstall"
echo ""
