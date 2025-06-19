#!/run/current-system/sw/bin/bash

{ 
  echo "{ outputs = { ... }: { rootPath = \"$PWD\"; }; }"
} > ./nix/paths/flake.nix

# This marks the file to be skipped in the worktree. Effectively ignoring changes to it.
git update-index --skip-worktree ./nix/paths/flake.nix
