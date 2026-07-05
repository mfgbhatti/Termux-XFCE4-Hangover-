#!/data/data/com.termux/files/usr/bin/bash
set -e

PREFIX="/data/data/com.termux/files/usr"
BIN_DIR="$PREFIX/bin"

# backup/ is copied into $HOME (not alongside the script).
BACKUP_DIR="$HOME/backup"

echo "Creating XDG directories for zsh"
mkdir -p "$HOME/.cache/zsh"
mkdir -p "$HOME/.local/state/zsh"
mkdir -p "$HOME/.local/share/zsh"
mkdir -p "$HOME/.config/zsh"

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
mkdir -p "$HOME/.config"
starship preset pure-preset -o "$HOME/.config/starship.toml"

echo "Setting zsh as default shell"
chsh -s zsh

echo "done....."
