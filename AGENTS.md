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

### Dry Run (Safe Check)
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

### Validation
```bash
# Check if git status is clean before deploying
git status

# Test flake integrity
nix flake check ./nix
```

## Code Style Guidelines

### Nix Code Style

**Formatting & Indentation**:
- Use 2-space indentation (standard Nix convention)
- Keep lines reasonably short (80-100 characters)
- Use `nixfmt` or `nix fmt` for automatic formatting

**File Organization**:
```nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
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

## Git Conventions

### Commit Messages

Follow Conventional Commit format:
```
<type>(<scope>): <description>

[optional body explaining what and why]
[optional footers]
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
- `deps`: Dependency updates

### Workflow

1. Always ensure git status is clean before deploying
2. Commit changes with meaningful messages
3. Run `just check` before committing system changes
4. Push changes after local testing

## File Locations & Organization

```
nix/
├── flake.nix                 # Main flake configuration
├── features.nix              # Feature flags
├── modules/                  # Reusable modules
│   ├── home/                 # Home-manager modules
│   └── nixos/                # NixOS modules
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
- **nixpkgs**: Official Nix packages repository
- **nix-darwin**: macOS configuration framework
- **nix-homebrew**: Homebrew integration for macOS

## Testing & Validation

Before making changes:
1. Run `just check` for dry-run validation
2. Verify changes don't break imports
3. Test configuration compiles with `nix flake check ./nix`
4. Ensure git status is clean

## Additional Resources

- Run `just` to see all available commands
- See `Justfile` for task definitions
- See `nix/README.md` for Nix-specific documentation
- See `README.md` for general project documentation
