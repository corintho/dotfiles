#!/usr/bin/env bash
# Parse user's flake configuration to determine jobset and current commit
# Output: jobset|current_commit|branch_name

set -euo pipefail

# Determine the directory containing nix files
if [[ -z "${WORKDIR:-}" ]]; then
  WORKDIR="$(pwd)"
fi

FLAKE_FILE="${WORKDIR}/nix/flake.nix"
FLAKE_LOCK="${WORKDIR}/nix/flake.lock"

# Check if files exist
if [[ ! -f "$FLAKE_FILE" ]]; then
  echo "Error: $FLAKE_FILE not found" >&2
  exit 1
fi

if [[ ! -f "$FLAKE_LOCK" ]]; then
  echo "Error: $FLAKE_LOCK not found" >&2
  exit 1
fi

# Extract unstable branch from flake.nix
# Looking for: nixpkgs-unstable.url = "github:nixos/nixpkgs/<branch>";
BRANCH=$(grep -oP 'nixpkgs-unstable\.url\s*=\s*"github:nixos/nixpkgs/\K[^"]+' "$FLAKE_FILE" | head -1 || echo "")

# If branch not found, default to nixos-unstable
if [[ -z "$BRANCH" ]]; then
  BRANCH="nixos-unstable"
fi

# Map branch to Hydra jobset
case "$BRANCH" in
  "nixos-unstable")
    JOBSET="nixpkgs/unstable/unstable"
    ;;
  "nixpkgs-unstable"|"trunk")
    JOBSET="nixpkgs/trunk/tested"
    ;;
  *)
    # Default to nixos-unstable
    JOBSET="nixpkgs/unstable/unstable"
    ;;
esac

# Extract current commit from flake.lock
CURRENT_COMMIT=$(python3 -c "
import json
with open('$FLAKE_LOCK') as f:
    lock = json.load(f)

if 'nodes' in lock and 'nixpkgs-unstable' in lock['nodes']:
    node_data = lock['nodes']['nixpkgs-unstable']
    if 'locked' in node_data and 'rev' in node_data['locked']:
        print(node_data['locked']['rev'])
" 2>/dev/null || echo "")

if [[ -z "$CURRENT_COMMIT" ]]; then
  echo "Error: Could not extract current nixpkgs-unstable commit from flake.lock" >&2
  exit 1
fi

# Output as pipe-separated values for easy parsing
echo "$JOBSET|$CURRENT_COMMIT|$BRANCH"
