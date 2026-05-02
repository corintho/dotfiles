# Nix Unstable Commit Skill

This skill finds the most recent successfully built nixpkgs commit from Hydra that has **verified binary cache availability**.

## Overview

Instead of relying on channel pointers or channel APIs, this skill:
1. **Queries Hydra's JSON API** for actual build results
2. **Verifies cache availability** by checking successful cachix constituent builds
3. **Searches up to 5 recent builds** to find the most recent with cache
4. **Retrieves commit metadata** from GitHub
5. **Displays full details** and automatically copies to clipboard

## Usage

When the user asks for an unstable commit, the skill executes:

```bash
WORKDIR=/your/dotfiles \
  /path/to/.opencode/skills/nix-unstable-commit/scripts/run.sh
```

## Script Components

### 1. `parse-flake-config.sh`

**Purpose:** Detect user's configuration and current commit

**Input:** Environment variable `WORKDIR` (path to dotfiles repo)

**Output:** Pipe-separated values: `jobset|current_commit|branch`

**Example output:**
```
nixpkgs/unstable/unstable|0f7663154ff2fec150f9dbf5f81ec2785dc1e0db|nixos-unstable
```

**Key steps:**
- Reads `nix/flake.nix` to find `nixpkgs-unstable.url` branch
- Maps branch to Hydra jobset:
  - `nixos-unstable` → `nixpkgs/unstable/unstable`
  - `nixpkgs-unstable` → `nixpkgs/trunk/tested`
- Reads `nix/flake.lock` to extract current commit hash

### 2. `fetch-hydra-builds.sh`

**Purpose:** Query Hydra API for successful builds with cache

**Input:** 
- `JOBSET`: Hydra jobset path (e.g., `nixpkgs/unstable/unstable`)
- `CURRENT_COMMIT`: User's current commit (for reference)
- `MAX_BUILDS` (optional): Number of builds to check (default: 5)

**Output:** JSON with build details

**Example output:**
```json
{
  "revision": "c6d65881c5624c9cae5ea6cedef24699b0c0a4c0",
  "build_id": "327834473",
  "eval_id": "1824939",
  "commit_date": "2026-05-01T13:14:57Z",
  "commit_message": "fishPlugins.forgit: 26.04.2 -> 26.05.0 (#515264)",
  "cachix_platforms": "aarch64-darwin, x86_64-darwin, x86_64-linux"
}
```

**Key steps:**
1. Fetches latest successful build from jobset using Hydra API
2. Gets evaluation details to extract nixpkgs revision
3. Checks build constituents for successful cachix builds
4. If no cachix found, goes back up to 5 evaluations looking for one with cache
5. Retrieves commit metadata from GitHub API
6. Returns JSON with all details

**Hydra API endpoints used:**
- `GET /job/{project}/{jobset}/{job}/latest` - Get latest build
- `GET /eval/{eval-id}` - Get evaluation details
- `GET /build/{build-id}/constituents` - Get constituent jobs

### 3. `clipboard-copy.sh`

**Purpose:** Copy text to clipboard (multi-platform)

**Input:** Text to copy as argument

**Output:** Status message to stderr, nothing to stdout

**Example usage:**
```bash
./clipboard-copy.sh "c6d65881c5624c9cae5ea6cedef24699b0c0a4c0"
```

**Supported clipboard tools (in priority order):**
1. `pbcopy` (macOS)
2. `wl-copy` (Wayland/Linux)
3. `xclip` (X11/Linux)

## Workflow

```
User requests unstable commit
        ↓
parse-flake-config.sh
  ├─ Read nix/flake.nix → branch
  ├─ Map to Hydra jobset
  └─ Get current commit from nix/flake.lock
        ↓
fetch-hydra-builds.sh
  ├─ Query Hydra API for latest build
  ├─ Check up to 5 builds for cachix
  ├─ Get GitHub commit metadata
  └─ Return JSON with details
        ↓
Format & display results
        ↓
clipboard-copy.sh
  └─ Copy commit hash to clipboard
```

## Error Handling

### Error: No recent build with cache
```
❌ Error: None of the last 5 successful builds have cachix available

Checked evaluations:
  - Eval #1824939: No cachix constituent
  - Eval #1824938: No cachix constituent
  - ...

Manual check: https://hydra.nixos.org/job/nixpkgs/unstable/unstable#tabs-status
```

### Error: Hydra API unreachable
```
❌ Error: Unable to reach Hydra API

The Hydra API at https://hydra.nixos.org is currently unavailable.

To find a working commit manually:
1. Visit: https://hydra.nixos.org/job/nixpkgs/unstable/unstable#tabs-status
2. Find the last successful build
3. Click on it and go to "Build inputs"
4. Copy the nixpkgs revision
```

## Testing

Test the entire workflow:

```bash
#!/usr/bin/env bash
WORKDIR=/path/to/dotfiles
SKILL_DIR="$WORKDIR/.opencode/skills/nix-unstable-commit"

# Parse config
CONFIG=$(WORKDIR="$WORKDIR" "$SKILL_DIR/scripts/parse-flake-config.sh")

# Get builds
BUILD_JSON=$("$SKILL_DIR/scripts/fetch-hydra-builds.sh" \
  "$(echo $CONFIG | cut -d'|' -f1)" \
  "$(echo $CONFIG | cut -d'|' -f2)")

# Copy to clipboard
REVISION=$(echo "$BUILD_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['revision'])")
"$SKILL_DIR/scripts/clipboard-copy.sh" "$REVISION"
```

## Performance

- **Parse flake config:** ~10ms
- **Fetch Hydra latest build:** ~200-500ms
- **Check one build's cache:** ~200-300ms
- **Get GitHub metadata:** ~300-500ms
- **Total time:** ~1-2 seconds (or up to 5-10 seconds if checking multiple builds)

## Requirements

- `bash` (4.0+)
- `python3`
- `curl`
- `jq` (optional, for pretty-printing)
- Clipboard tool: `pbcopy` (macOS), `wl-copy` (Wayland), or `xclip` (X11)

## References

- [Hydra API OpenAPI spec](https://raw.githubusercontent.com/NixOS/hydra/refs/heads/master/hydra-api.yaml)
- [Hydra Build System](https://hydra.nixos.org)
- [GitHub API - Commits](https://docs.github.com/en/rest/commits/commits)
