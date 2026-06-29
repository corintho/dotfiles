Initial run.

1. Setup environment variable for company certificate:
```
sudo rm /etc/ssl/certs/ca-certificates.crt
sudo ln -s /etc/ssl/certs/corporate.crt /etc/ssl/certs/ca-certificates.crt
```

1. Disable network sleep while on lock: `sudo pmset -a networkoversleep 1`. This way you can leave the bootstrap running, lock your computer, and go for a coffee.

1. Setup git user email (stored locally, not in dotfiles):
```
mkdir -p ~/.config/git
cat > ~/.config/git/local << 'EOF'
[user]
	email = user@corporate.domain
EOF
```
Replace `user@corporate.domain` with your actual git email.

1. Bootstrap: `sudo -E nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch --flake .`
This bootstrap will fail, due to detected manual changes in the `ca-certifactes` above. But it will already download everything that is needed.

1. Undo the manual ca-certificates changes:
```
sudo rm /etc/ssl/certs/ca-certificates.crt
sudo ln -s /etc/static/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
```

1. Bootstrap again: `sudo -E nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch --flake .`

After that

1. Run `just deploy` for future deployments
