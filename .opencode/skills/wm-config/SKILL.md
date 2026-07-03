---
name: wm-config
description: Update window manager rules across AeroSpace (macOS), Hyprland (NixOS), and Niri (NixOS). Use when assigning apps to workspaces, adding floating rules, or moving apps between workspaces.
license: MIT
compatibility: opencode
metadata:
  platforms: darwin, nixos
  window-managers: aerospace, hyprland, niri
  primary-focus: window-rule-management
---

# WM Config

Update window manager window rules for app-to-workspace assignment and floating rules across macOS (AeroSpace) and NixOS (Hyprland, Niri).

## File Locations

| Platform | WM | File | Format |
|---|---|---|---|
| macOS (Darwin) | AeroSpace | `nix/modules/home/darwin/wm/aerospace/aerospace.toml` | TOML |
| NixOS (Linux) | Hyprland | `nix/modules/home/hyprland.nix` | Nix |
| NixOS (Linux) | Niri | `nix/modules/home/niri/config.kdl` | KDL |

## Workspace Registry

All three WMs use identical workspace names and consistent keybinds:

| Workspace | Apps | Key | Usage |
|---|---|---|---|
| `Browsers` | zen, Arc, Edge | `alt+B` (AeroSpace), `SUPER+B` (Hyprland/Niri) | Web browsing |
| `cOmms` | Discord, Telegram, Proton Mail, Outlook | `alt+O` / `SUPER+O` | Communications |
| `Dev` | kitty, ghostty, neovide | `alt+D` / `SUPER+D` | Development |
| `Gaming` | Steam, Heroic, Lutris, Itch, PrismLauncher | `alt+G` / `SUPER+G` | Gaming |
| `Misc` | Obsidian, Bazecor | `alt+M` / `SUPER+M` | Miscellaneous |

## App-ID Lookup (read-only, safe in plan mode)

Run these commands while target app is open — **no side effects, can be done during agent planning**.

**macOS (AeroSpace):**
```bash
aerospace list-apps
```
Look for bundle ID in output (e.g., `com.microsoft.edgemac`).

**NixOS — Hyprland:**
```bash
hyprctl clients
```
Extract `class:` value from output (e.g., `class:zen`). Case-sensitive.

**NixOS — Niri:**
```bash
niri msg windows
```
Extract `app_id` field (e.g., `app_id: "Discord"`). Anchored regex required in config.

## Workflows

### 1. Add app to workspace

**Step 1:** Identify the app (plan mode — read-only)
- Run lookup command above for your platform
- Note exact app-id/class/bundle-id

**Step 2:** Add rule to your platform's WM
- **Darwin**: AeroSpace only — Add `[[on-window-detected]]` block to `aerospace.toml`
- **NixOS**: Hyprland + Niri — Add line to `windowrulev2` in `hyprland.nix` and `window-rule {}` block in `config.kdl`

See [REFERENCE.md](REFERENCE.md) for syntax per platform.

**Step 3:** Validate
```bash
just check
```

### 2. Move app between workspaces

**Step 1:** Find existing rule
- Search your platform's WM config file(s) for the app-id
- Note current workspace assignment

**Step 2:** Update workspace value for your platform
- **Darwin**: AeroSpace — Update `run = ['move-node-to-workspace <name>']` value in `aerospace.toml`
- **NixOS**: Hyprland — Update `"workspace name:<name>, class:..."` in `hyprland.nix`. Niri — Update `open-on-workspace "<name>"` in `config.kdl`

**Step 3:** Validate
```bash
just check
```

### 3. Add floating rule

**Step 1:** Identify the app (plan mode)
- Run lookup command for your platform

**Step 2:** Add floating rule for your platform
- **Darwin**: AeroSpace — Add block with `run = ['layout floating']`
- **NixOS**: Hyprland — Add line like `"float, class:appname"`. Niri — Add block with `open-floating true`

See [REFERENCE.md](REFERENCE.md) for exact syntax.

**Step 3:** Validate
```bash
just check
```

## Platform Scope

Update only the WM(s) for your current platform:

| Platform | Update | Skip |
|---|---|---|
| **Darwin (macOS)** | AeroSpace | Hyprland, Niri |
| **NixOS (Linux)** | Hyprland, Niri | AeroSpace |

Workspace names and app-ids remain consistent across all three WMs, so configs can be kept in sync without updating all files every time. Update only the WM you're actively using.

## Advanced: Platform Syntax Reference

See [REFERENCE.md](REFERENCE.md) for detailed platform-specific syntax, existing rule examples, and regex patterns.
