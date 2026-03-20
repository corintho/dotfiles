---
name: nix-unstable-commit
description: Get latest nixpkgs-unstable commit with Darwin binary cache
license: MIT
compatibility: opencode
metadata:
  platform: multi-arch
  package-manager: nix
  primary-focus: darwin-cache
---

## What I do

I fetch the latest official nixpkgs-unstable commit that has been blessed by Hydra and has full binary cache availability. My primary focus is ensuring Darwin binary caches are available, as these typically take the longest to build.

I will:
- Fetch the latest nixpkgs-unstable channel commit from the official Nix channels
- Retrieve commit metadata (date, commit message)
- Verify that it has passed Hydra evaluation and has binary cache coverage
- Display formatted output with the commit hash, dates, and cache status
- **Automatically copy ONLY the commit hash to your clipboard** using `pbcopy`

## When to use me

Use me when the user asks for:
- "unstable commit"
- "nixpkgs-unstable commit" 
- "latest nix unstable"
- "nix commit with cache"
- "get the commit for unstable"
- "latest unstable with darwin cache"
- Any similar variation asking for the latest nixpkgs-unstable commit

**IMPORTANT**: Execute immediately without asking any questions. The user wants the result, not a conversation.

## How I work

### Primary Method

1. **Fetch the official channel commit**:
   ```bash
   curl -sL "https://channels.nixos.org/nixpkgs-unstable/git-revision"
   ```

2. **Get commit metadata from GitHub**:
   ```bash
   curl -sL "https://api.github.com/repos/nixos/nixpkgs/commits/<hash>"
   ```
   Extract the commit date and message from the JSON response.

3. **Display formatted output**:
   ```
   Latest nixpkgs-unstable commit with binary cache:

   Commit: <hash>
   Date: <commit-date>
   Released: <channel-release-date>
   Status: ✅ Binary cache available (Darwin + all platforms)

   ✓ Copied commit hash to clipboard
   ```

4. **Copy ONLY the hash to clipboard**:
   ```bash
   echo "<hash>" | pbcopy
   ```

### Fallback Method (if channel API fails)

If the primary method fails, try querying Hydra directly:

1. **Check Hydra jobset**:
   ```bash
   curl -sL "https://hydra.nixos.org/jobset/nixpkgs/trunk/latest-eval"
   ```

2. Parse the latest successful evaluation and extract the commit hash

3. Follow the same display and clipboard workflow as above

### Error Handling

If both methods fail:
- Display a clear error message: "Unable to fetch nixpkgs-unstable commit. The Nix channels and Hydra APIs are currently unavailable."
- Suggest manual fallback: "Please check https://channels.nixos.org/nixpkgs-unstable directly or try again later."
- Do NOT copy anything to clipboard

If GitHub API is rate-limited or unavailable:
- Still display the commit hash
- Show a simplified output without commit date/message
- Continue with clipboard copy

If `pbcopy` is not available (non-macOS systems):
- Display the commit hash and metadata as usual
- Show a warning: "⚠️ Could not copy to clipboard (pbcopy not available). Please copy manually."

## Output Format

Always use this format for successful results:

```
Latest nixpkgs-unstable commit with binary cache:

Commit: <full-40-char-hash>
Date: <YYYY-MM-DD HH:MM:SS UTC>
Released: <YYYY-MM-DD HH:MM:SS UTC>
Status: ✅ Binary cache available (Darwin + all platforms)

✓ Copied commit hash to clipboard
```

## Important Notes

### Why Darwin Cache Matters

The nixpkgs-unstable channel only advances when builds succeed across all major platforms. Darwin (macOS) builds typically take the longest, so if a commit is in the official channel, it means:
- Darwin binary caches are available
- All other platforms (x86_64-linux, aarch64-linux, aarch64-darwin) also have caches
- The commit has passed Hydra's quality gates

### Multi-Architecture Support

While this skill works for all Nix architectures, the emphasis is on Darwin because:
- Darwin builds are typically the bottleneck
- Darwin users need cache availability the most to avoid long local compilations
- Other platforms (Linux) usually get caches faster

### No Questions Policy

**CRITICAL**: When invoked, execute immediately. Do NOT ask the user:
- Which architecture they want
- If they want to see more details
- If they want to copy to clipboard
- Any other clarifying questions

The user expects immediate results with automatic clipboard copy.

## Technical Context

### What is the nixpkgs-unstable channel?

The nixpkgs-unstable channel is a rolling release of Nixpkgs that tracks the master branch but only advances when:
1. Hydra successfully evaluates the commit
2. A sufficient percentage of packages build successfully across all platforms
3. Binary caches are available for the majority of packages

This makes channel commits safe choices for flake inputs, as they guarantee binary cache availability.

### Why not use the latest master commit?

Using the absolute latest commit from nixos/nixpkgs master may not have binary caches ready yet. This means:
- Long compilation times (especially on Darwin)
- Potential build failures
- Wasted time and resources

By using the official channel commit, you ensure maximum cache hits and minimal local compilation.
