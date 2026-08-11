# List all commands
[private]
default:
  @just --list --unsorted

#
# NixOS specific
#

# Standard deploy for Linux
[group('build')]
[linux]
deploy:
  systemd-inhibit nixos-rebuild --sudo switch --flake ./nix --impure

# Standard deploy with extended debug enabled
[group('build')]
[linux]
verbose:
  nixos-rebuild --sudo switch --flake ./nix --show-trace --verbose

# Dry run. Makes it easy to catch errors without generating a new profile and boot entry
[group('build')]
[linux]
check:
  nixos-rebuild dry-build --flake ./nix --impure

# Remove dirty generations, except the current one
[group('cleanup')]
[linux]
sanitize:
  #!/usr/bin/env bash
  DIRTY_GENS="$(just list |  grep '[0-9]' | grep --invert-match 'True$' | grep 'dirty' | awk '{ print $1; }' | tr '\n' ' ')"
  if [ -z "${DIRTY_GENS}" ];
  then echo "No dirty generations to clean up";
  else
    sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations $DIRTY_GENS;
  fi

# All steps for full sanitization
[group('cleanup')]
[linux]
sanitize-all: check-git-status sanitize keep5 gc deploy

# List all current available generations
[group('info')]
[linux]
list:
  @nixos-rebuild list-generations

# Update brew. The Linux version only updates the flakes
[group('maintenance')]
[private]
[linux]
update-brew:
  nix flake update homebrew-bundle --flake ./nix 
  nix flake update homebrew-cask --flake ./nix 
  nix flake update homebrew-core --flake ./nix 
  nix flake update homebrew-xcodesorg --flake ./nix 

#
# Darwin specific
#

# Boot out the Emacs LaunchAgent
[group('build')]
[macos]
launchctl-stop:
  sudo launchctl bootout gui/$(id -u)/org.nix-community.home.emacs 2>/dev/null || true

# Bootstrap the Emacs LaunchAgent
[group('build')]
[macos]
launchctl-start:
  sudo launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nix-community.home.emacs.plist 2>/dev/null || true

# Standard deploy for MacOS
[group('build')]
[macos]
deploy: launchctl-stop && launchctl-start
  sudo -E darwin-rebuild switch --flake ./nix --impure

# Standard deploy with extended debug enabled
[group('build')]
[macos]
verbose:
  sudo -E darwin-rebuild switch --flake ./nix --impure --show-trace --verbose

# Dry run. Makes it easy to catch errors without generating a new profile
[group('build')]
[macos]
check:
  sudo -E darwin-rebuild build --flake ./nix --impure

# List all current available generations
[group('info')]
[macos]
list:
  sudo darwin-rebuild --list-generations

# Update brew. Remember to redeploy
[group('maintenance')]
[macos]
update-brew:
  nix flake update homebrew-bundle --flake ./nix
  nix flake update homebrew-cask --flake ./nix
  nix flake update homebrew-core --flake ./nix
  nix flake update homebrew-xcodesorg --flake ./nix
  brew update

# All steps for full sanitization - as far as Darwin allows
[group('cleanup')]
[macos]
sanitize-all: check-git-status keep5 gc deploy
#
# Universal commands
#

# Loads up the current flake in the repl
[group('debug')]
repl:
  nix repl -f flake:nixpkgs

# Update flake lock file. Remember to redeploy
[group('maintenance')]
up: && up-secrets update-brew
  nix flake update stylix nix-darwin agenix zen-browser doom emacs-overlay --flake ./nix 

# Update flake lock file, fixing unstable to the specified commit. Remember to redeploy. Look at: https://status.nixos.org/ for the current build status
[group('maintenance')]
up-unstable-to hash:
  nix flake update nixpkgs --override-input nixpkgs github:nixos/nixpkgs/{{hash}} --flake ./nix
  nix flake update nixpkgs-unstable --override-input nixpkgs-unstable github:nixos/nixpkgs/{{hash}} --flake ./nix
# Update secrets - macOS version (uses HTTPS via override to bypass SSH blockage)
[group('maintenance')]
[macos]
up-secrets:
  nix flake update secrets --override-input secrets 'git+https://github.com/corintho/nix-secrets.git?ref=main' --flake ./nix

# Update secrets - NixOS version (uses SSH directly)
[group('maintenance')]
[linux]
up-secrets:
  nix flake update secrets --flake ./nix

# Check if git status is clean before deploying
[private]
check-git-status:
  #!/usr/bin/env bash
  changes=$(git status --porcelain | wc -l)
  if [ 0 -eq $changes ]; then
    exit 0
  else
    echo "Git status is not clean. Please commit or stash your changes before deploying."
    exit 1
  fi

# Commit after updating
[private]
update-commit:
  git add .
  git commit -m "chore: update dependencies"

# Update flake lock file, commit changes and redeploy
[group('maintenance')]
update: check-git-status up update-commit deploy update-comma

# Update comma index information
[group('maintenance')]
update-comma:
  #!/usr/bin/env bash
  filename="index-$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr A-Z a-z)"
  mkdir -p ~/.cache/nix-index && cd ~/.cache/nix-index
  wget -q -N https://github.com/nix-community/nix-index-database/releases/latest/download/$filename
  ln -f $filename files

# Install Doom at the locked revision (packages into DOOMLOCALDIR)
[group('maintenance')]
emacs-setup:
  #!/usr/bin/env bash
  set -euo pipefail
  # Run after deploying, in a fresh shell. First run seeds files/doom; commit
  # it once. Doom advances via `just up` + this recipe, never `doom upgrade`.
  emacs_dir="$HOME/.config/emacs"
  rev="$(jq -r '.nodes.doom.locked.rev' nix/flake.lock)"
  if [ -L "${emacs_dir}" ]; then
    rm "${emacs_dir}"
  fi
  if [ ! -d "${emacs_dir}" ]; then
    git clone https://github.com/doomemacs/doomemacs "${emacs_dir}"
  fi
  git -C "${emacs_dir}" fetch origin
  git -C "${emacs_dir}" checkout "${rev}"
  git -C "${emacs_dir}" submodule update --init --recursive
  "${emacs_dir}/bin/doom" install
  "${emacs_dir}/bin/doom" sync --env

# Optimises store usage
[group('maintenance')]
optimise:
  nix store optimise

# Shows a searcheable dependency tree
[group('info')]
tree:
  nix-tree

#
# Formatting
#

# Format all Nix files using the flake formatter
[group('formatting')]
fmt:
  cd nix && nix fmt

# Check Nix formatting without modifying files
[group('formatting')]
fmt-check:
  nixfmt --check nix devenv.nix

# Keep only 5 generations
[group('cleanup')]
keep5:
  sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5

# Remove all generations older than 7 days
[group('cleanup')]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# Reclaim unused space after removing older generations. This one is slow to run
[group('cleanup')]
gc:
  #!/usr/bin/env bash
  set -euo pipefail
  # Safeguard: verify home-manager profile is valid before GC to prevent dangling symlinks
  hm_profile="$HOME/.local/state/nix/profiles/home-manager"
  if [[ -L "$hm_profile" ]]; then
    if ! nix-store --verify-path "$(readlink -f "$hm_profile")" 2>/dev/null; then
      echo "ERROR: home-manager profile is dangling/invalid. Run 'just deploy' to fix before gc." >&2
      exit 1
    fi
  fi
  sudo nix store gc
  nix store gc
  @printf "\nRemember to run \"deploy\" again to remove old entries from the boot menu\n"

# Prune all other generations and reclaim their space
[group('cleanup')]
[confirm("This will remove all other generations. Are you sure?")]
prune:
  # garbage collect all unused nix store generations
  sudo nix-collect-garbage --delete-old
