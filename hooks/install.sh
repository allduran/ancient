#!/usr/bin/env bash
# Instalación de ancient: lo que no son paquetes (los instala `duran install` desde shell.toml).
set -euo pipefail

step() { printf '  \e[1;34m·\e[0m %s\n' "$*"; }
warn() { printf '  \e[1;33m!\e[0m %s\n' "$*"; }
root="$(dirname "$(realpath "$0")")/.."

step "scripts ejecutables"
chmod +x "$root"/scripts/*.sh

step "carpetas"
mkdir -p "$HOME/Pictures/Screenshots" "$HOME/Videos/Recordings" "$HOME/Pictures/Wallpapers" "$HOME/.local/state/ancient"

step "Hyprland"
duran hypr init || warn "actualiza duran: falta 'duran hypr init'"

step "bluetooth"
sudo systemctl enable --now bluetooth.service 2>/dev/null || warn "no se pudo activar bluetooth.service"

# ancient pinta su propio fondo
step "hyprpaper desactivado"
systemctl --user disable --now hyprpaper.service 2>/dev/null || true
pkill -x hyprpaper 2>/dev/null || true

# Otro demonio de notificaciones impide que ancient muestre las suyas
for d in mako dunst swaync; do
    pgrep -x "$d" >/dev/null && warn "$d está corriendo: quítalo del autostart o ancient no mostrará notificaciones"
done

# Fondos: wallpaper-dota-1.jpg, wallpaper-dota-2.png…
ls "$HOME"/Pictures/Wallpapers/wallpaper-dota-* >/dev/null 2>&1 ||
    warn "sin fondos: añade ~/Pictures/Wallpapers/wallpaper-dota-1.jpg (y -2, -3…)"

# Foto del HUD
[ -e "$HOME/.face" ] || warn "sin ~/.face: el HUD mostrará tu inicial (cp tu-foto.png ~/.face)"

# ¿Tu Hyprland carga la parte del shell?
grep -rqsE 'require[ (,]*"shell"' "$HOME/.config/hypr" ||
    warn "tu hyprland.lua no carga shell.lua: añade pcall(require, \"shell\") (README → Hyprland)"

step "ancient instalado"