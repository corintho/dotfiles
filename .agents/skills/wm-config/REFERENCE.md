# WM Config Reference

Detailed platform-specific syntax, matching methods, and full workspace registry.

## Platform Comparison

| Aspect | AeroSpace (macOS) | Hyprland (NixOS) | Niri (NixOS) |
|---|---|---|---|
| **Config format** | TOML | Nix | KDL |
| **App matching** | `app-id` (macOS bundle ID) or `app-name-regex-substring` | `class:` (X11/Wayland app_id) with glob regex | `app-id=` with Rust regex anchored |
| **Rule block syntax** | `[[on-window-detected]]` array-of-tables | List entry string in `windowrulev2` list | `window-rule {}` block |
| **Workspace reference** | Named string in `run` array | Named string in rule string | Named string in `open-on-workspace` |
| **Regex support** | `app-name-regex-substring` for name matching | `class:Pattern.*` glob syntax | `app-id=r#"^Pattern$"#` Rust regex |
| **Floating** | `run = ['layout floating']` | `float, class:...` | `open-floating true` |

---

## AeroSpace (macOS)

**File**: `nix/modules/home/darwin/wm/aerospace/aerospace.toml`

**Format**: TOML

### Workspace assignment rule

```toml
[[on-window-detected]]
if.app-id = 'com.microsoft.edgemac'
run = ['move-node-to-workspace Browsers']
```

**Key points**:
- Use exact macOS bundle ID (reverse DNS format)
- `run` is a TOML array of strings
- Workspace name matches registry exactly (case-sensitive)
- Multiple `[[on-window-detected]]` blocks can target same workspace

### Floating rule

```toml
[[on-window-detected]]
if.app-id = 'org.videolan.vlc'
run = ['layout floating']
```

### App-name regex (fallback when bundle ID unreliable)

```toml
[[on-window-detected]]
if.app-name-regex-substring = 'cbg'
run = ['layout floating']
```

Uses substring match on app display name. Less precise than bundle ID.

### Existing examples

From `aerospace.toml`:
```toml
# Browsers
[[on-window-detected]]
if.app-id = 'company.thebrowser.Browser'
run = ['move-node-to-workspace Browsers']

[[on-window-detected]]
if.app-id = 'com.microsoft.edgemac'
run = ['move-node-to-workspace Browsers']

# Comms
[[on-window-detected]]
if.app-id = 'com.microsoft.Outlook'
run = ['move-node-to-workspace cOmms']

# Misc
[[on-window-detected]]
if.app-id = 'md.obsidian'
run = ['move-node-to-workspace Misc']
```

---

## Hyprland (NixOS/Linux)

**File**: `nix/modules/home/hyprland.nix`

**Format**: Nix attribute set (list of strings)

### Workspace assignment rule

```nix
"workspace name:Browsers, class:zen"
```

**Key points**:
- Rule is a single string in the `windowrulev2` list
- Format: `"workspace name:<name>, class:<class>"`
- Class name is X11/Wayland app_id, case-sensitive
- No quotes around workspace name or class name within the rule string

### Floating rule

```nix
"float, class:steam"
```

Format: `"float, class:<class>"` or `"size <W> <H>, class:<class>"` etc.

### Regex support (glob syntax)

```nix
"workspace name:Gaming, class:Minecraft.*"
```

Use `.*` for suffix match, `.+` for one-or-more, `?` for optional, `|` for OR.

### Special workspace (scratchpad)

```nix
"workspace special:magic, class:Proton Pass"
```

Prefix with `special:` for scratchpad-style workspace. Toggle with `SUPER+S`.

### Existing examples

From `hyprland.nix` `windowrulev2`:
```nix
windowrulev2 = [
  "workspace name:Browsers, class:zen"
  "workspace name:cOmms, class:discord"
  "workspace name:cOmms, class:Proton Mail"
  "workspace name:cOmms, class:org.telegram.desktop"
  "workspace name:Dev, class:neovide"
  "workspace name:Dev, class:kitty"
  "workspace name:Dev, class:com.mitchellh.ghostty"
  "workspace name:Gaming, class:steam"
  "workspace name:Gaming, class:heroic"
  "workspace name:Gaming, class:itch"
  "workspace name:Gaming, class:net.lutris.Lutris"
  "workspace name:Gaming, class:net.davidotek.pupgui2"
  "workspace name:Gaming, class:org.prismlauncher.PrismLauncher"
  "workspace name:Gaming, class:Minecraft.*"
  "workspace name:Misc, class:Bazecor"
  "workspace special:magic, class:Proton Pass"
];
```

### Finding correct class name

```bash
# Window already open:
hyprctl clients | grep -A5 '<appname>'

# Look for: "class: <exact-class-name>"
```

---

## Niri (NixOS/Linux)

**File**: `nix/modules/home/niri/config.kdl`

**Format**: KDL (configuration description language)

### Workspace assignment rule

```kdl
window-rule {
    match app-id=r#"^zen$"#
    open-on-workspace "Browsers"
}
```

**Key points**:
- Each rule is a `window-rule {}` block
- `match app-id=` uses Rust regex, must be anchored with `^` and `$`
- Multiple `match` lines in one block act as OR (any match triggers the rule)
- Workspace name matches registry exactly
- Regex literals use raw string syntax: `r#"..."#`

### Prefix match (unanchored end)

```kdl
window-rule {
    match app-id=r#"^Minecraft"#
    open-on-workspace "Gaming"
}
```

Matches any app_id starting with "Minecraft". The missing `$` anchor allows suffix.

### Floating rule

```kdl
window-rule {
    match app-id=r#"^org\.videolan\.VLC$"#
    open-floating true
    geometry-corner-radius 4
}
```

`open-floating true` for floating windows. Can combine with other properties.

### Multiple matches (OR condition)

```kdl
window-rule {
    match app-id=r#"^kitty$"#
    match app-id=r#"^com\.mitchellh\.ghostty$"#
    match app-id=r#"^neovide$"#
    open-on-workspace "Dev"
}
```

Multiple `match` lines = OR. This rule sends any of the 3 terminals to Dev workspace.

### Existing examples

From `config.kdl`:
```kdl
// Workspace assignments
window-rule {
    match app-id=r#"^zen$"#
    open-on-workspace "Browsers"
}

window-rule {
    match app-id=r#"^kitty$"#
    match app-id=r#"^com\.mitchellh\.ghostty$"#
    open-on-workspace "Dev"
}

window-rule {
    match app-id=r#"^obsidian$"#
    match app-id=r#"^Bazecor$"#
    open-on-workspace "Misc"
}

window-rule {
    match app-id=r#"^discord$"#
    match app-id=r#"^org\.telegram\.desktop$"#
    match app-id=r#"^Proton Mail$"#
    open-on-workspace "cOmms"
}

window-rule {
    match app-id=r#"^steam$"#
    match app-id=r#"^heroic$"#
    match app-id=r#"^itch$"#
    match app-id=r#"^net\.lutris\.Lutris$"#
    match app-id=r#"^net\.davidotek\.pupgui2$"#
    match app-id=r#"^Minecraft"#
    match app-id=r#"^org\.prismlauncher\.PrismLauncher$"#
    open-on-workspace "Gaming"
}

// Floating
window-rule {
    match app-id=r#"^Rofi$"#
    open-floating true
    geometry-corner-radius 4
}

// Block screen capture (privacy)
window-rule {
    match app-id=r#"^org\.keepassxc\.KeePassXC$"#
    match app-id=r#"^org\.gnome\.World\.Secrets$"#
    match app-id=r#"^Proton Pass$"#
    block-out-from "screen-capture"
}
```

### Finding correct app_id

```bash
# Window already open:
niri msg windows

# Look for: "app_id: '<exact-app-id>'"
```

### Regex escaping

Dots in reverse DNS bundle IDs must be escaped with backslash:
```kdl
r#"^org\.telegram\.desktop$"#   # correct (escape dots)
r#"^org.telegram.desktop$"#     # wrong (unescaped regex metachar)
```

---

## Cross-Platform Add App Example

Adding Firefox to Browsers workspace across all three WMs:

**Step 1: Identify app-ids**
```bash
# macOS
aerospace list-apps | grep -i firefox    # → org.mozilla.firefox

# Hyprland
hyprctl clients | grep -i firefox        # → class: firefox

# Niri
niri msg windows | grep -i firefox       # → app_id: "firefox"
```

**Step 2: Add to each WM**

**AeroSpace** (`aerospace.toml`):
```toml
[[on-window-detected]]
if.app-id = 'org.mozilla.firefox'
run = ['move-node-to-workspace Browsers']
```

**Hyprland** (`hyprland.nix`):
```nix
"workspace name:Browsers, class:firefox"
```

**Niri** (`config.kdl`):
```kdl
window-rule {
    match app-id=r#"^firefox$"#
    open-on-workspace "Browsers"
}
```

**Step 3: Validate**
```bash
just check
```

---

## Debugging Mismatches

**Issue**: App not going to expected workspace

1. **Verify app-id is correct** — run lookup command for your WM
2. **Check case sensitivity** — Hyprland class names are exact case
3. **Check regex anchoring** (Niri) — missing `^` or `$` can cause unexpected matches
4. **Verify workspace name exists** — typo in workspace name (e.g., `browswers` vs `Browsers`)
5. **Check rule is active** — rule may be after conflicting rule or commented out

**Cross-check**:
- macOS: `aerospace list-apps` shows running app's bundle ID
- Hyprland: `hyprctl clients` active window `class:` field
- Niri: `niri msg windows` focused window `app_id` field

---

## Workspace Consistency Rule

**All workspace names must be identical across AeroSpace, Hyprland, and Niri**:

| Registry Name | AeroSpace | Hyprland | Niri |
|---|---|---|---|
| Browsers | `Browsers` | `name:Browsers` | `"Browsers"` |
| cOmms | `cOmms` | `name:cOmms` | `"cOmms"` |
| Dev | `Dev` | `name:Dev` | `"Dev"` |
| Gaming | `Gaming` | `name:Gaming` | `"Gaming"` |
| Misc | `Misc` | `name:Misc` | `"Misc"` |

**Why**: Allows seamless switching between WMs. User expects same workspace name on any platform.

**Keybind consistency**:
- AeroSpace: `alt+B` (Browsers), `alt+O` (cOmms), `alt+D` (Dev), `alt+G` (Gaming), `alt+M` (Misc)
- Hyprland: `SUPER+B`, `SUPER+O`, `SUPER+D`, `SUPER+G`, `SUPER+M`
- Niri: `Super+B`, `Super+O`, `Super+D`, `Super+G`, `Super+M`

All map the same semantic operation to the same key (modulo platform modifier name conventions).
