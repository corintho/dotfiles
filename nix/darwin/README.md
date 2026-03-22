Initial run.

1. Setup environment variable for company certificate:
```
sudo rm /etc/ssl/certs/ca-certificates.crt
sudo ln -s /etc/ssl/certs/corporate.crt /etc/ssl/certs/ca-certificates.crt
```

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
