---
name: nix-unstable-commit
description: Get latest nixpkgs-unstable commit with verified binary cache from Hydra
license: MIT
compatibility: opencode
metadata:
  platform: multi-arch
  package-manager: nix
  primary-focus: hydra-verified-cache
---

## What I do

I find the most recent successfully built nixpkgs commit from Hydra that has **verified binary cache availability** via cachix. Unlike channel-based approaches, I query Hydra's actual build results to guarantee the commit has built successfully and has binary caches ready.

I will:
1. **Detect your configuration** by reading your `nix/flake.nix` and `nix/flake.lock`
2. **Query Hydra API** for the correct jobset (nixos-unstable or nixpkgs-unstable)
3. **Find the most recent successful build with cache** (checking up to 5 recent builds)
4. **Verify cache availability** by checking cachix constituent builds
5. **Retrieve commit metadata** from GitHub (date, message)
6. **Display results** with Hydra build links for verification
7. **Automatically copy the commit hash** to your clipboard (multi-platform support)

## When to use me

Use me when the user asks for:
- "find an unstable commit"
- "get a working unstable commit"
- "latest nixos-unstable"
- "find a commit with cache"
- "get the latest working unstable"
- "unstable commit that has binary cache"
- Any similar variation asking for a verified working unstable commit

**IMPORTANT**: Execute immediately without asking any questions. The user wants the result, not a conversation.

## How I work

### Step 1: Detect Your Configuration

1. **Read `nix/flake.nix`** to determine which unstable branch you're tracking
   - Looks for: `nixpkgs-unstable.url = "github:nixos/nixpkgs/<branch>"`
   - Maps to Hydra jobset: `nixos-unstable` → `nixpkgs/unstable/unstable`
   - Maps to Hydra jobset: `nixpkgs-unstable` → `nixpkgs/trunk/tested`

2. **Parse `nix/flake.lock`** to extract your current commit hash and date

3. **Default to `nixos-unstable`** if detection fails

### Step 2: Query Hydra for Successful Builds with Cache

1. **Fetch the latest successful build** using Hydra JSON API:
   ```bash
   GET https://hydra.nixos.org/job/{project}/{jobset}/{job}/latest
   ```

2. **Get evaluation details** to extract the exact nixpkgs revision:
   ```bash
   GET https://hydra.nixos.org/eval/{eval-id}
   ```
   Extract: `jobsetevalinputs.nixpkgs.revision`

3. **Verify cache availability** by checking build constituents:
   ```bash
   GET https://hydra.nixos.org/build/{build-id}/constituents
   ```
   Look for successful cachix builds across platforms

4. **If cache NOT available on latest build:**
   - Go back up to 5 recent successful builds
   - Check each one's cache status
   - Return the most recent with cache available

5. **If none of last 5 have cache:**
   - Display error: "None of the last 5 successful builds have cachix available"
   - Suggest manual check at Hydra URL

### Step 3: Retrieve Commit Metadata

- **Fetch GitHub commit info** for the selected revision:
  ```bash
  GET https://api.github.com/repos/nixos/nixpkgs/commits/{revision}
  ```
- Extract: commit date, author, message

### Step 4: Display Results & Copy to Clipboard

- Display selected commit with full details
- Show Hydra build/eval links for verification
- **Automatically copy the commit hash to clipboard** (multi-platform: pbcopy, wl-copy, xclip)
- Provide Hydra URL for manual verification

### Error Handling

**If Hydra API unavailable:**
- Display error message with jobset URL
- Suggest manual navigation to: `https://hydra.nixos.org/job/{project}/{jobset}/{job}#tabs-status`
- Do NOT copy anything to clipboard

**If GitHub API rate-limited:**
- Still display the commit hash from Hydra
- Show "metadata unavailable (GitHub rate limited)" for date/message
- Continue with clipboard copy

**If clipboard copy fails:**
- Display the commit hash
- Show message: "⚠️ Could not copy to clipboard (tool not available on this system)"
- Suggest manual copy

**If none of last 5 builds have cache:**
- Error message: "Could not find a recent successful build with cachix available"
- Show what was checked
- Provide Hydra jobset URL for manual investigation

## Output Format

### Successful Result

```
Latest nixos-unstable commit with verified cache:

Commit: c6d65881c5624c9cae5ea6cedef24699b0c0a4c0
Date: 2026-05-01 13:14:57 UTC
Message: fishPlugins.forgit: 26.04.2 -> 26.05.0 (#515264)

Hydra Build: #327834473 (✅ Successful)
Hydra Eval: #1824939
Cache Status: ✅ cachix builds successful (aarch64-darwin, x86_64-darwin, x86_64-linux)

Your current: 0f7663154ff2fec150f9dbf5f81ec2785dc1e0db (2026-04-09)
Difference: +13080 commits ahead

✓ Copied commit hash to clipboard

Verify: https://hydra.nixos.org/build/327834473
```

### Error: No Recent Build with Cache

```
❌ Error: None of the last 5 successful builds have cachix available

Checked evaluations:
  - Eval #1824939: No cachix constituent
  - Eval #1824938: No cachix constituent
  - Eval #1824937: No cachix constituent
  - Eval #1824936: No cachix constituent
  - Eval #1824935: No cachix constituent

Manual check: https://hydra.nixos.org/job/nixpkgs/unstable/unstable#tabs-status
```

### Error: Hydra Unavailable

```
❌ Error: Unable to reach Hydra API

The Hydra API at https://hydra.nixos.org is currently unavailable.

To find a working commit manually:
1. Visit: https://hydra.nixos.org/job/nixpkgs/unstable/unstable#tabs-status
2. Find the last successful build
3. Click on it and go to "Build inputs"
4. Copy the nixpkgs revision
```

## Important Notes

### Why Hydra-Based Verification?

Unlike channel-based approaches, this skill queries **actual Hydra build results**, which guarantees:
- The commit **has successfully built** (not just pointed to by a channel)
- **Binary caches are verified** by checking cachix constituent builds
- **All platforms pass** (if cachix built successfully across x86_64/aarch64 Darwin/Linux)
- **No surprises** like the build failing on your system

### Cache Availability Check

The skill checks for successful `cachix.*` constituent builds:
- `cachix.aarch64-darwin` (macOS ARM64)
- `cachix.x86_64-darwin` (macOS Intel)
- `cachix.x86_64-linux` (Linux Intel)
- `cachix.aarch64-linux` (Linux ARM64)

If cachix jobs don't exist or failed, the commit likely doesn't have cache available.

### Why Check Up to 5 Builds?

Sometimes a very recent build might not have all cachix jobs built yet (they're slower). By checking the last 5 successful builds, we find the most recent one that definitely has cache available, rather than settling for an older build immediately.

### No Questions Policy

**CRITICAL**: When invoked, execute immediately. Do NOT:
- Ask which jobset to use
- Ask whether to copy to clipboard
- Ask if user wants more details
- Ask about platform preferences

The user expects immediate results with automatic clipboard copy and zero interaction.
