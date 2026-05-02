#!/usr/bin/env bash
# Multi-platform clipboard copy
# Usage: clipboard-copy.sh <text-to-copy>

set -euo pipefail

TEXT="$1"

if command -v pbcopy &> /dev/null; then
    # macOS
    echo "$TEXT" | pbcopy
    echo "✓ Copied to clipboard (pbcopy)" >&2
elif command -v wl-copy &> /dev/null; then
    # Wayland
    echo "$TEXT" | wl-copy
    echo "✓ Copied to clipboard (wl-copy)" >&2
elif command -v xclip &> /dev/null; then
    # X11
    echo "$TEXT" | xclip -selection clipboard
    echo "✓ Copied to clipboard (xclip)" >&2
else
    echo "⚠️ Could not copy to clipboard (no copy tool available on this system)" >&2
    echo "Please copy manually: $TEXT" >&2
fi
