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
deploy: && optimise
  systemd-inhibit nixos-rebuild --sudo switch --flake ./nix --impure
  @just workaround-waybar

# Standard deploy with extended debug enabled
[group('build')]
[linux]
verbose:
  nixos-rebuild --sudo switch --flake ./nix --show-trace --verbose

#TODO: Only needed for waybar because of a bug
[private]
workaround-waybar:
  -@killall -SIGUSR2 -r waybar

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
  DIRTY_GENS="$(just list |  grep '[0-9]' | grep --invert-match 'current' | grep 'dirty' | awk '{ print $1; }' | tr '\n' ' ')"
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

#
# Darwin specific
#

# Standard deploy for MacOS
[group('build')]
[macos]
deploy: && optimise
  sudo darwin-rebuild switch --flake ./nix --impure

# Standard deploy with extended debug enabled
[group('build')]
[macos]
verbose:
  sudo darwin-rebuild switch --flake ./nix --impure --show-trace --verbose

# Dry run. Makes it easy to catch errors without generating a new profile
[group('build')]
[macos]
check:
  sudo darwin-rebuild check --flake ./nix --impure

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
up:
  nix flake update --flake ./nix 

# Update secrets. Remember to redeploy
[group('maintenance')]
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

# Optimises store usage
[group('maintenance')]
optimise:
  nix store optimise

# Shows a searcheable dependency tree
[group('info')]
tree:
  nix-tree

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
  sudo nix store gc
  nix store gc
  @printf "\nRemember to run \"deploy\" again to remove old entries from the boot menu\n"

# Prune all other generations and reclaim their space
[group('cleanup')]
[confirm("This will remove all other generations. Are you sure?")]
prune:
  # garbage collect all unused nix store generations
  sudo nix-collect-garbage --delete-old
