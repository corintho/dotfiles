# List all commands
[private]
default:
  @just --list --unsorted

# Standard deploy
[group('build')]
[linux]
deploy:
  nixos-rebuild switch --flake ./nix --use-remote-sudo
  @just workaround-waybar

# Dry run. Makes it easy to catch errors without generating a new profile and boot entry
[group('build')]
[linux]
dry-build:
  nixos-rebuild dry-build --flake ./nix

# Standard deploy with extended debug enabled
[group('build')]
[linux]
verbose:
  nixos-rebuild switch --flake ./nix --use-remote-sudo --show-trace --verbose

#TODO: Only needed for waybar because of a bug
[private]
workaround-waybar:
  @killall -SIGUSR2 -r waybar

# Loads up the current flake in the repl
[group('debug')]
repl:
  nix repl -f flake:nixpkgs

# Update flake lock file. Remember to redeploy
[group('maintenance')]
up:
  nix flake update --flake ./nix 

# Update flake lock file and redeploy
[group('maintenance')]
update: up deploy

# Shows a searcheable dependency tree
[group('info')]
tree:
  nix-tree

# List all current available generations
[group('info')]
list:
  nixos-rebuild list-generations

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

# Prune all other generations and reclaim their space
[group('cleanup')]
[confirm("This will remove all other generations. Are you sure?")]
prune:
  # garbage collect all unused nix store generations
  sudo nix-collect-garbage --delete-old

