# AGENTS.md - Guidelines for AI Coding Agents

This document provides guidelines for AI coding agents operating in the dotfiles repository. This is a Nix-based configuration management system for macOS (Darwin) and NixOS systems.

## Project Overview

- **Primary Language**: Nix (functional configuration language)
- **Secondary Languages**: Bash, Shell scripts
- **Configuration Framework**: NixOS / home-manager (NixOS declarative system configuration)
- **Task Runner**: `just` (command runner with recipes in Justfile)
- **Package Manager**: Nix Flakes, Homebrew (macOS)
- **Secrets Management**: agenix (encrypted secrets)

## Build/Lint/Test Commands

### Dry Run Validation
```bash
# NixOS - check configuration without applying changes
just check

# macOS - check configuration without applying changes
just check
```

### Deploy Configuration
```bash
# NixOS - apply system configuration
just deploy

# macOS - apply system configuration
just deploy
```

### With Verbose Output
```bash
# NixOS - deploy with debug trace information
just verbose

# macOS - deploy with debug trace information
just verbose
```

### Maintenance Commands
```bash
# Update all flake inputs (lock file)
just up

# Update flake inputs and redeploy
just update

# Perform full sanitization (cleanup and rebuild)
just sanitize-all
```

### Validation Commands
```bash
# Check if git status is clean before deploying
git status

# Test flake integrity
nix flake check ./nix
```

### Formatting Validation
```bash
# Check Nix code formatting without modifying files
nix fmt --check
```

## Code Style Guidelines

### Nix Code Style

**Formatting & Indentation**:
- Use 2-space indentation (standard Nix convention)
- Keep lines reasonably short (80-100 characters)
- Use `nixfmt` or `nix fmt` for automatic formatting

**File Organization and Structure**:
```nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
  # Add any custom inputs here
}:

let
  # Local functions and helper definitions
  myFunction = ...;
in
{
  # Configuration and module content
}
```

**Imports & Declarations**:
- Destructure inputs at the top of modules: `{ config, lib, pkgs, inputs, ... }`
- Group imports logically (system imports, home-manager, custom modules)
- Use relative paths for local imports: `../../modules/home/example.nix`

**Naming Conventions**:
- Module names: kebab-case (e.g., `oh_my_posh.nix`, `hyprland.nix`)
- Directory names: kebab-case (e.g., `nix/modules/home/`)
- Option names: camelCase (e.g., `enableSomething`, `myPackages`)
- Constants: camelCase or UPPER_CASE

**Package Management**:
- Pin packages to specific versions when required for stability
- Use `pkgs.unstable.*` for packages needing newer versions
- Reference packages from appropriate inputs: `pkgs`, `pkgs.unstable`
- Group related packages in logical sections with comments

**Configuration Structure**:
```nix
{
  imports = [ /* modules */ ];
  
  # Option overrides first
  options = { /* custom options */ };
  
  # Configuration comes next, grouped by concern
  programs.foo.enable = true;
  home.packages = with pkgs; [ ... ];
  
  # Services and system configuration
  services.bar.enable = true;
}
```

### Bash/Shell Script Style

**Format & Structure**:
- Use `#!/usr/bin/env bash` shebang
- Set options like `set -euo pipefail` for safety
- Indent with 2 spaces
- Quote all variable references: `"${variable}"`

**Naming**:
- Function names: snake_case
- Constants: UPPER_CASE
- Local variables: lowercase

**Error Handling**:
- Use error exit codes appropriately
- Check git status before dangerous operations
- Add user-friendly error messages
- Exit with clear status codes (0 = success, 1 = error)

### Comments & Documentation

**Nix Comments**:
- Use `#` for single-line comments
- Group related configuration with section comments
- Document non-obvious configuration choices
- Link to external references or TODOs when relevant

**Bash Comments**:
- Explain the "why" not just "what"
- Document complex logic
- Add headers for major sections

## Testing Tools

- `nix-tree`: Shows searchable dependency tree (run with `just tree`)

## Git Conventions

### Commit Messages

Follow Conventional Commit format:
```
<type>(<scope>): <description>
```

**IMPORTANT**: 
- Commit messages MUST be a single line
- Do NOT include a body or additional lines
- **Exception**: Breaking changes may include a body explaining the breaking change and migration path

Breaking change format (rare):
```
<type>(<scope>)!: <description>

BREAKING CHANGE: Explanation of what breaks and how to migrate
```

**Types**:
- `feat`: New feature or configuration
- `fix`: Bug fix or configuration correction
- `chore`: Maintenance, dependency updates
- `refactor`: Code restructuring without changing behavior
- `docs`: Documentation updates
- `style`: Formatting, linting fixes

**Scopes** (examples):
- `home`: Changes to home-manager configuration
- `nix`: Core Nix configuration files
- `nixos`: NixOS-specific changes
- `darwin`: macOS-specific changes
- `shell`: Shell/bash scripts
- `test`: Test files and test infrastructure
- `deps`: Dependency updates

### Workflow

**IMPORTANT**: AI agents must ALWAYS ask for explicit permission before committing or pushing changes.

#### Making Changes
1. Make file changes as requested
2. Run `just check` to validate system changes
3. Run `nix fmt --check` to validate formatting (or run `nixfmt` to fix)
4. Show git diff/status to demonstrate what changed

#### Committing Changes
5. **Draft a commit message** following the conventional commit format
6. **Show the commit message to the user** and ask for approval
7. **Wait for explicit confirmation** before running `git commit`
8. Only commit after receiving user approval

#### Pushing Changes
9. **NEVER push automatically** - always ask first
10. **Wait for explicit "yes" or "push it"** confirmation
11. Only run `git push` after receiving clear permission
12. Always ensure git status is clean before deploying

**Exception**: If the user explicitly asks you to "commit and push" in a single request, you may do both, but still show what you're committing first.

## File Locations & Organization

```
nix/
├── flake.nix                 # Main flake configuration
├── devenv.nix                # Development environment configuration
├── features.nix              # Feature flags
├── modules/                  # Reusable modules
│   ├── home/                 # Home-manager modules
│   └── nixos/                # NixOS modules
├── hosts/                    # System-specific configurations
├── options/                  # Nix option definitions
├── users/
│   └── corintho/             # User-specific configs
│       ├── home.nix          # Home configuration
│       └── nixos.nix         # NixOS configuration
└── README.md                 # Nix-specific documentation

bin/                           # Custom scripts
lib/                          # Library functions
files/                        # Configuration files to deploy
```

## Key Tools & Technologies

- **home-manager**: User-level configuration management
- **agenix**: Encrypted secrets management
- **stylix**: System-wide color/styling theme
- **nix-tree**: Dependency tree visualization
- **nixpkgs**: Official Nix packages repository
- **nix-darwin**: macOS configuration framework
- **nix-homebrew**: Homebrew integration for macOS

## Testing & Validation

Before making changes:
1. Run `just check` for dry-run validation
2. Verify changes don't break imports
3. Test configuration compiles with `nix flake check ./nix`
4. Run `nix fmt --check` to validate formatting
5. Ensure git status is clean

## Additional Resources

- Run `just` to see all available commands
- See `Justfile` for task definitions
- See `nix/README.md` for Nix-specific documentation
- See `README.md` for general project documentation

## Quick Reference: Validation Commands

- `just check`: Platform-specific dry-run (NixOS/macOS)
- `nix fmt --check`: Nix code formatting validation
- `nix flake check ./nix`: Flake integrity check
- `just tree`: View dependency tree
