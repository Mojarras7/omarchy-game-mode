#!/bin/bash
# Omarchy Game Mode — Optional CLI, Hyprland rules & keybindings installer
set -e

BIN_DIR="$HOME/.local/bin"
HYPR_DIR="$HOME/.config/hypr"
mkdir -p "$BIN_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Omarchy Game Mode..."
cp "$SCRIPT_DIR/bin/omarchy-game-mode" "$BIN_DIR/omarchy-game-mode"
chmod +x "$BIN_DIR/omarchy-game-mode"
echo "✓ Installed $BIN_DIR/omarchy-game-mode"

HYPRLAND_LUA="$HYPR_DIR/hyprland.lua"
if [[ -f "$HYPRLAND_LUA" ]]; then
  if ! grep -q "special:gaming" "$HYPRLAND_LUA"; then
    cat <<'EOF' >> "$HYPRLAND_LUA"

-- Dedicated gaming special workspace rules:
o.window({ class = "steam", title = "Steam Big Picture Mode" }, { workspace = "special:gaming", fullscreen = true, idle_inhibit = "always" })
o.window({ class = "^steam_app_.*$" }, { workspace = "special:gaming", idle_inhibit = "always" })

-- Keep the top bar in sync if you leave special:gaming via any workspace key (e.g. Super+1)
local gaming_active_file = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/omarchy/game-mode/active"
local function sync_gaming_bar()
  local f = io.open(gaming_active_file, "r")
  if f then
    f:close()
    hl.exec_cmd("omarchy-game-mode --sync-bar")
  end
end
hl.on("workspace.special_active", sync_gaming_bar)
hl.on("workspace.active", sync_gaming_bar)
EOF
    echo "✓ Added special:gaming rules & bar sync hook to ~/.config/hypr/hyprland.lua"
  else
    echo "✓ special:gaming rules already present in ~/.config/hypr/hyprland.lua"
  fi
fi

BINDINGS_LUA="$HYPR_DIR/bindings.lua"
if [[ -f "$BINDINGS_LUA" ]]; then
  if ! grep -q "omarchy-game-mode" "$BINDINGS_LUA"; then
    cat <<'EOF' >> "$BINDINGS_LUA"

-- Instant Game Mode toggle & control menu
o.rebind("SUPER + G", "Game mode", "omarchy-game-mode")
o.bind("SUPER + CTRL + G", "Game mode menu", "omarchy-game-mode --menu")
EOF
    echo "✓ Added Super+G and Super+Ctrl+G bindings to ~/.config/hypr/bindings.lua"
  else
    echo "✓ Game Mode bindings already present in ~/.config/hypr/bindings.lua"
  fi
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

echo "✓ Omarchy Game Mode installed successfully!"
echo "Press Super + G to enter/toggle Game Mode, or Super + Ctrl + G for the control menu."
