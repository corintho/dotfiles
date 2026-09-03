#!/usr/bin/env bash
# omp always persists a live /model or /settings change to the shared
# global file (files/omp/config.yml) -- that's hardcoded omp behavior,
# not something this script controls. Corintho wants that shared file to
# stay static/clean of modelRoles permanently: per-host PI_CONFIG_FILES
# overlays (omp_darwin_config.yml / omp_nixos_config.yml) are the sole
# source of truth for models. This script copies any modelRoles value it
# finds in the shared file onto this host's overlay, then deletes
# modelRoles from the shared file entirely -- so the shared file always
# returns to holding no modelRoles at all. Because this script always
# empties modelRoles back out before exiting, ANY modelRoles presence it
# finds on a subsequent run is -- by construction -- a fresh write since
# the last cleanup pass, never a stale value to second-guess. That
# invariant is what makes a baseline/diff-against-last-seen-snapshot
# mechanism unnecessary here (an earlier version of this script had one;
# it existed to protect a deliberately-diverged override value from a
# merely-static mismatch against a shared file that used to persist
# model values long-term -- that concern no longer applies once the
# shared file is never allowed to hold a lingering value).
set -euo pipefail

: "${DEVENV_ROOT:?DEVENV_ROOT not set; run inside the devenv shell}"
: "${PI_CONFIG_FILES:?PI_CONFIG_FILES not set; add it to this hosts home.sessionVariables}"

GLOBAL="$DEVENV_ROOT/files/omp/config.yml"
OVERRIDE="${PI_CONFIG_FILES%%:*}"

[ -f "$GLOBAL" ] || { echo "omp-model-sync: $GLOBAL missing" >&2; exit 1; }
[ -f "$OVERRIDE" ] || { echo "omp-model-sync: $OVERRIDE missing" >&2; exit 1; }

# A write in progress may leave the file briefly unparsable; skip this
# pass, the next file-change event retries once the write settles.
yq eval '.' "$GLOBAL" >/dev/null 2>&1 || exit 0

ROLE_COUNT=$(yq eval '(.modelRoles // {}) | length' "$GLOBAL")
[ "$ROLE_COUNT" = "0" ] && exit 0

CURRENT_KEYS=$(yq eval '(.modelRoles // {}) | keys | .[]' "$GLOBAL")
while IFS= read -r key; do
  [ -z "$key" ] && continue
  val=$(KEY="$key" yq eval '.modelRoles[env(KEY)]' "$GLOBAL")
  KEY="$key" VAL="$val" yq eval -i '.modelRoles[env(KEY)] = env(VAL)' "$OVERRIDE"
  echo "omp-model-sync: propagated modelRoles.$key -> $OVERRIDE"
done <<< "$CURRENT_KEYS"

yq eval -i 'del(.modelRoles)' "$GLOBAL"
echo "omp-model-sync: cleared modelRoles from $GLOBAL"
