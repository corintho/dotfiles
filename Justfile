# List all commands
[private]
default:
  @just --list --unsorted

#
# NixOS specific
#

# Standard deploy
[group('build')]
[linux]
deploy:
  nixos-rebuild switch --flake ./nix --use-remote-sudo
  @just workaround-waybar

# Standard deploy with extended debug enabled
[group('build')]
[linux]
verbose:
  nixos-rebuild switch --flake ./nix --use-remote-sudo --show-trace --verbose

#TODO: Only needed for waybar because of a bug
[private]
workaround-waybar:
  @killall -SIGUSR2 -r waybar

# Dry run. Makes it easy to catch errors without generating a new profile and boot entry
[group('build')]
[linux]
check:
  nixos-rebuild dry-build --flake ./nix

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

# List all current available generations
[group('info')]
[linux]
list:
  @nixos-rebuild list-generations

# Keep only 5 generations
[group('cleanup')]
[linux]
keep5:
  sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5

# Remove all generations older than 7 days
[group('cleanup')]
[linux]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

#
# Darwin specific
#

# Standard deploy
[group('build')]
[macos]
deploy:
  sudo darwin-rebuild switch --flake ./nix

# Dry run. Makes it easy to catch errors without generating a new profile
[group('build')]
[macos]
check:
  sudo darwin-rebuild check --flake ./nix

# List all current available generations
[group('info')]
[macos]
list:
  sudo darwin-rebuild --list-generations

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

# Commit after updating
[private]
update-commit:
  git add .
  git commit -m "chore: update dependencies"

# Update flake lock file, commit changes and redeploy
[group('maintenance')]
update: up update-commit deploy

# Shows a searcheable dependency tree
[group('info')]
tree:
  nix-tree

# Reclaim unused space after removing older generations. This one is slow to run
[group('cleanup')]
gc:
  sudo nix store gc
  @printf "\nRemember to run \"deploy\" again to remove old entries from the boot menu\n"

# Prune all other generations and reclaim their space
[group('cleanup')]
[confirm("This will remove all other generations. Are you sure?")]
prune:
  # garbage collect all unused nix store generations
  sudo nix-collect-garbage --delete-old
