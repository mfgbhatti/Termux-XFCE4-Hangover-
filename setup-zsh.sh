#!/data/data/com.termux/files/usr/bin/bash
set -e

PREFIX="/data/data/com.termux/files/usr"
BIN_DIR="$PREFIX/bin"

# backup/ is copied into $HOME (not alongside the script).
BACKUP_DIR="$HOME/backup"

# Clean
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

echo "Creating xdg custom dirs"
cat > "$XDG_CONFIG_HOME/user-dirs.dirs" << 'EOF'
XDG_DESKTOP_DIR="$HOME/Desktop"
EOF

echo "Creating xdg default dirs"
xdg-user-dirs-update

echo "Creating XDG directories for zsh"
mkdir -p "$XDG_CACHE_HOME/zsh"
mkdir -p "$XDG_STATE_HOME/zsh"
mkdir -p "$XDG_DATA_HOME/zsh"
mkdir -p "$XDG_CONFIG_HOME/zsh"
mkdir -p "$XDG_CONFIG_HOME/npm"
mkdir -p "$XDG_CONFIG_HOME/wget"
mkdir -p "$XDG_DATA_HOME/wineprefixes"

cat > "$XDG_CONFIG_HOME/npm/npmrc" << 'EOF'
prefix=${XDG_DATA_HOME}/npm
cache=${XDG_CACHE_HOME}/npm
init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js
logs-dir=${XDG_STATE_HOME}/npm/logs
EOF

echo "hsts-file \= "$XDG_STATE_HOME"/wget-hsts" >> "$XDG_CONFIG_HOME/wget/wgetrc"

echo "Restoring zsh config from backup"
if [ -d "$BACKUP_DIR/config/zsh" ]; then
  cp -rf "$BACKUP_DIR/config/zsh/." "$HOME/.config/zsh/"
else
  echo "Warning: $BACKUP_DIR/config/zsh not found, skipping"
fi

echo "Restoring .zshenv from backup"
if [ -f "$BACKUP_DIR/.zshenv" ]; then
  cp -f "$BACKUP_DIR/.zshenv" "$HOME/.zshenv"
else
  echo "Warning: $BACKUP_DIR/.zshenv not found, skipping"
fi

echo "Configuring starship with the pure preset"
starship preset pure-preset -o "$HOME/.config/starship.toml"

echo "Setting zsh as default shell"
chsh -s zsh

echo "done....."
