#!/bin/bash
# Omarchy Game Mode — Optional CLI, Gamepad Home listener, Hyprland rules & keybindings installer
set -e

BIN_DIR="$HOME/.local/bin"
HYPR_DIR="$HOME/.config/hypr"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$BIN_DIR" "$SYSTEMD_USER_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Omarchy Game Mode..."
cp "$SCRIPT_DIR/bin/omarchy-game-mode" "$BIN_DIR/omarchy-game-mode"
cp "$SCRIPT_DIR/bin/omarchy-gamepad-home" "$BIN_DIR/omarchy-gamepad-home"
chmod +x "$BIN_DIR/omarchy-game-mode" "$BIN_DIR/omarchy-gamepad-home"
echo "✓ Installed omarchy-game-mode and omarchy-gamepad-home into $BIN_DIR"

# Install and enable the lightweight gamepad Home button user service
cp "$SCRIPT_DIR/systemd/omarchy-gamepad-home.service" "$SYSTEMD_USER_DIR/omarchy-gamepad-home.service"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload >/dev/null 2>&1 || true
  systemctl --user enable --now omarchy-gamepad-home.service >/dev/null 2>&1 || true
  echo "✓ Enabled omarchy-gamepad-home.service (press Guide/Home on your controller from desktop to enter Game Mode)"
fi

HYPRLAND_LUA="$HYPR_DIR/hyprland.lua"
if [[ -f "$HYPRLAND_LUA" ]]; then
  if ! grep -q "special:gaming" "$HYPRLAND_LUA"; then
    cat <<'EOF' >> "$HYPRLAND_LUA"

-- Dedicated gaming special workspace rules:
o.window({ class = "^gamescope$" }, { workspace = "special:gaming", fullscreen = true, idle_inhibit = "always" })
o.window({ class = "steam", title = "Steam Big Picture Mode" }, { workspace = "special:gaming", fullscreen = true, idle_inhibit = "always" })
o.window({ class = "^steam_app_.*$" }, { workspace = "special:gaming", idle_inhibit = "always" })

-- Keep Steam Big Picture Mode fullscreen whenever it regains focus (e.g. after closing a game)
hl.on("window.active", function(win)
  if win and win.class == "steam" and win.title == "Steam Big Picture Mode" and not win.fullscreen then
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "set" }))
  end
end)

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
    echo "✓ Added special:gaming rules & hooks to ~/.config/hypr/hyprland.lua"
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
echo "Tip: Install 'gamescope' (omarchy pkg add gamescope) for isolated single-window Steam Deck console mode."
echo "Press Super + G (or your controller's Home button) to enter Game Mode, or Super + Ctrl + G for the menu."
