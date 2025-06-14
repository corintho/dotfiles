Initial run.

1. Setup environment variable for company certificate: `export NIX_SSL_CERT_FILE=/etc/ssl/certs/corporate.crt`
1. Bootstrap: `sudo -E nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch --flake .`

After that

1. Run `sudo nix run nix-darwin -- switch --flake .`
