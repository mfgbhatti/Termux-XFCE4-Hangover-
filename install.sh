#!/data/data/com.termux/files/usr/bin/bash
set -e

PREFIX="/data/data/com.termux/files/usr"
BIN_DIR="$PREFIX/bin"
APP_DIR="$HOME/Desktop"

# Resolve the directory this script lives in, so relative files
# (packages, hangover-wine, mason-installer) work no matter how/where
# the script is invoked from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

USE_PACMAN=true
DESKTOP="plasma"
INSTALL_WINE=true

if [ "$USE_PACMAN" = true ]; then
  UPDATE="pacman -Syu"
  PKG_INSTALL="pacman -S --noconfirm --needed"
else
  UPDATE="pkg update -y && pkg upgrade -y"
  PKG_INSTALL="pkg install -y"
fi

install() {
  echo
  echo "==> Installing: $*"
  $PKG_INSTALL "$@"
}

# if [ "$USE_PACMAN" = true ]; then
#     pacman-key --init
#     pacman-key --populate
#
#     "$UPDATE"
# else
#     "$UPDATE"
# fi

echo "Sourcing packages file"
source "$SCRIPT_DIR/packages"

# On pacman, repos are assumed to already be enabled in pacman.conf
# (handled separately during pacman-key init/setup).
# On pkg (Termux's apt wrapper), x11-repo/tur-repo are meta-packages —
# installing them is what enables the repo, so it must happen here,
# before anything that depends on packages from those repos.
if [ "$USE_PACMAN" != true ]; then
  echo "Enabling repos: ${REPOS[*]}"
  install "${REPOS[@]}"
fi

case "$DESKTOP" in
  "plasma")
    install "${PLASMA_PKGS[@]}"
    SESSION_CMD="startplasma-x11"
    NAME="KDE"
    ;;
  "mate")
    install "${MATE_PKGS[@]}"
    SESSION_CMD="mate-session"
    NAME="MATE"
    ;;
  "xfce")
    install "${XFCE_PKGS[@]}"
    SESSION_CMD="startxfce4"
    NAME="XFCE"
    ;;
  *)
    echo "Unknown desktop environment: $DESKTOP"
    exit 1
    ;;
esac

install "${BASE_PKGS[@]}"
install "${GUI_PKGS[@]}"
install "${GPU_PKGS[@]}"

if [ "$INSTALL_WINE" = true ]; then
  install "${HANGOVER_PKGS[@]}"
  source "$SCRIPT_DIR/hangover-wine"
fi

echo "Creating X11start and X11stop files"
cat << EOF > "$BIN_DIR/tx11start"
#!/data/data/com.termux/files/usr/bin/env sh

# Mesa / Zink
export MESA_NO_ERROR=1
export vblank_mode=0
# export TU_DEBUG=noconform
# export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
# Vulkan
# export VK_ICD_FILENAMES=$PREFIX/share/vulkan/icd.d/turnip_icd.aarch64.json
# export MESA_GL_VERSION_OVERRIDE=4.6
# export MESA_GLSL_VERSION_OVERRIDE=460
# Disable software rendering
export LIBGL_ALWAYS_SOFTWARE=0

kill -9 \$(pgrep -f termux.x11) 2>/dev/null
kill -9 \$(pgrep -x pulseaudio) 2>/dev/null
kill -9 \$(pgrep -x "$SESSION_CMD") 2>/dev/null

pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
export XDG_RUNTIME_DIR="\$TMPDIR"
termux-x11 :0 >/dev/null 2>&1 &
sleep 3

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
sleep 1

export DISPLAY=:0
export PULSE_SERVER=127.0.0.1

dbus-launch --exit-with-session "$SESSION_CMD" >/dev/null 2>&1 &
EOF
chmod +x "$BIN_DIR/tx11start"

cat << EOF > "$BIN_DIR/tx11stop"
#!/data/data/com.termux/files/usr/bin/env sh
kill -9 \$(pgrep -f termux.x11) 2>/dev/null
kill -9 \$(pgrep -x pulseaudio) 2>/dev/null
kill -9 \$(pgrep -x "$SESSION_CMD") 2>/dev/null
EOF
chmod +x "$BIN_DIR/tx11stop"

echo "Creating desktop entries"
mkdir -p "$APP_DIR"
cat > "$APP_DIR/tx11stop.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Stop $NAME
Comment=Kill or stop Termux GUI
Exec=tx11stop
Icon=system-shutdown
Categories=System;
Path=
Terminal=false
StartupNotify=false
EOF
chmod +x "$APP_DIR/tx11stop.desktop"

echo "writing fontconfig file"
mkdir -p "$HOME/.config/fontconfig"
cat << EOF > "$HOME/.config/fontconfig/fonts.conf"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>

<!-- Reset the font search path -->
<reset-dirs/>

<!-- Only search this directory -->
<dir>/data/data/com.termux/files/usr/share/fonts</dir>

<!-- Optional: user-installed fonts -->
<dir>/data/data/com.termux/files/home/.local/share/fonts</dir>

<!-- Cache location -->
<cachedir>/var/cache/fontconfig</cachedir>

</fontconfig>
EOF

echo "Copying mason-installer"
cp "$SCRIPT_DIR/mason-installer" "$BIN_DIR/mason-installer"
chmod +x "$BIN_DIR/mason-installer"

echo "Changing termux extra keys"
cat > "$HOME/.termux/termux.properties" << 'EOF'
extra-keys = [ \
    ['ESC', 'CTRL', ':', '$', 'UP', 'BACKSLASH', 'HOME', 'END'], \
    ['TAB', {key: '-', popup: '|'}, '/', 'LEFT', 'DOWN', 'RIGHT', 'BACKSPACE', {key: KEYBOARD, popup: DRAWER}] \
]
EOF

# echo "Changing termux-x11-prefernces"
# termux-x11 &
# termux-x11-preference < "$HOME"/backup/termux/termx-x11-preferences

echo "Runing zsh setup"
source "$SCRIPT_DIR/setup-zsh.sh"
echo "done....."
