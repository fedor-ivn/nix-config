```bash
nix shell nixpkgs#sops -c sops --decrypt --output secrets.nix secrets.nix.enc
```

```bash
nix shell nixpkgs#sops -c sops --encrypt --output secrets.nix.enc secrets.nix
```

```bash
sudo darwin-rebuild switch --flake path:.#fedorivns-mbp
```
