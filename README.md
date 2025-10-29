# Nix(OS) + macOS configuration with secrets, Home Manager, nix-darwin, disko, and Homebrew

This repository contains a flake-based configuration for both NixOS (x86_64 and aarch64) and macOS (Intel and Apple Silicon). It integrates:

- home-manager for per-user configuration
- nix-darwin for macOS system management
- disko for declarative disk partitioning during NixOS installs
- agenix + age (optionally YubiKey via age-plugin-yubikey) for secret management
- nix-homebrew for managing Homebrew alongside Nix on macOS
- Convenience “apps” to install, switch, manage keys, and more

See the main flake for details: [flake.nix](https://github.com/TingRubato/nixos-config/blob/4d03ccf11223c3acd54835fadc6f4dc1810c0204/flake.nix)

- NixOS host modules: [hosts/nixos](https://github.com/TingRubato/nixos-config/tree/main/hosts)
- macOS host modules: [hosts/darwin](https://github.com/TingRubato/nixos-config/tree/main/hosts)
- Common modules: [modules/](https://github.com/TingRubato/nixos-config/tree/main/modules)
- Overlays: [overlays/](https://github.com/TingRubato/nixos-config/tree/main/overlays)
- Secrets mapping: [secrets.nix](https://github.com/TingRubato/nixos-config/blob/main/secrets.nix)
- Secrets repo (git submodule): `secrets` (see .gitmodules)

The flake currently sets the user to `"timmy"`. Change this to your local username before applying.

---

## Requirements

- Nix with flakes enabled (Nix 2.18+ recommended)
  - Add to `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`:
    ```
    experimental-features = nix-command flakes
    ```
- Git (with SSH access to your secrets repo)
- macOS:
  - Nix installed (daemon mode recommended)
  - On Apple Silicon, Rosetta will be enabled automatically by nix-homebrew module
- NixOS:
  - NixOS install ISO and a target disk you are willing to wipe when using disko

Optional but recommended:
- age and age-plugin-yubikey (provided via `nix develop`)
- A YubiKey if you plan to use age-plugin-yubikey for secrets

---

## Quick start

### 1) Clone and initialize submodules

You need access to the `secrets` submodule (default points to `git@github.com:TingRubato/secrets.git`). If you’re using your own secrets repo, update `.gitmodules` first.

```bash
git clone git@github.com:TingRubato/nixos-config.git
cd nixos-config
git submodule update --init --recursive
```

Optionally enter the development shell (provides `age`, `age-plugin-yubikey`, etc.):

```bash
nix develop
```

### 2) Customize for your machine(s)

- Edit the username in [flake.nix](https://github.com/TingRubato/nixos-config/blob/4d03ccf11223c3acd54835fadc6f4dc1810c0204/flake.nix):
  ```nix
  user = "timmy";  # change to your local username
  ```
- Review and adjust host modules under:
  - macOS: [hosts/darwin](https://github.com/TingRubato/nixos-config/tree/main/hosts)
  - NixOS: [hosts/nixos](https://github.com/TingRubato/nixos-config/tree/main/hosts)
- Review [modules/](https://github.com/TingRubato/nixos-config/tree/main/modules) and [overlays/](https://github.com/TingRubato/nixos-config/tree/main/overlays) as needed.
- Review [secrets.nix](https://github.com/TingRubato/nixos-config/blob/main/secrets.nix) and ensure recipients are correct for your age keys.

### 3) Set up secrets (agenix + age)

If you don’t already have an age key:

```bash
# In or out of `nix develop`:
age-keygen -o ~/.config/age/keys.txt
```

Convenience apps in this flake help with keys (see “Available apps” below). Typical flow:

```bash
# Create keys (e.g., for this machine or YubiKey)
nix run .#create-keys

# Copy public keys where they need to be (e.g., into secrets repo or config)
nix run .#copy-keys

# Verify keys are set up correctly
nix run .#check-keys
```

To edit or rekey a secret with agenix:

```bash
# Edit a secret (opens your $EDITOR)
agenix -e path/to/secret.age

# Rekey secrets for updated recipients
agenix -r
```

Recipients and secret paths are organized via [secrets.nix](https://github.com/TingRubato/nixos-config/blob/main/secrets.nix). Ensure your public key(s) are listed appropriately.

---

## macOS setup (nix-darwin + home-manager + nix-homebrew)

1) Install Nix on macOS (daemon mode). Follow the official instructions.

2) From this repo directory, apply the configuration:

```bash
# Apply default macOS configuration for your architecture
nix run .#apply
# or build and switch
nix run .#build-switch
```

You can also run directly from GitHub without cloning:

```bash
nix run github:TingRubato/nixos-config#apply
```

Notes:
- `nix-homebrew` will be enabled and configured with taps:
  - homebrew-core, homebrew-cask, homebrew-bundle
- On Apple Silicon, Rosetta is enabled automatically.
- A rollback app is provided:
  ```bash
  nix run .#rollback
  ```

---

## NixOS setup (installer + disko + home-manager)

Warning: The disko-based install will ERASE the target disk. Review and edit the disko/host files under [hosts/nixos](https://github.com/TingRubato/nixos-config/tree/main/hosts) before proceeding.

1) Boot into a NixOS installer ISO and get network access (e.g., `wifi` or `nmcli`, or wired).

2) Clone this repo and init submodules:

```bash
git clone git@github.com:TingRubato/nixos-config.git
cd nixos-config
git submodule update --init --recursive
```

3) Install:

```bash
# Run the installer (may prompt for the target device configuration)
nix run .#install

# Or, if you want to include secrets during install:
nix run .#install-with-secrets
```

4) Reboot into the installed system. After logging in as your user:

```bash
# Build and switch to the latest configuration
nix run .#build-switch
```

---

## Daily usage

- Update inputs and switch:

```bash
# Update flake inputs to latest
nix flake update

# Apply updated configuration
nix run .#build-switch
# or on macOS, you can also:
nix run .#apply
```

- Run any app by name (see below). From GitHub directly:

```bash
nix run github:TingRubato/nixos-config#<app>
```

---

## Available apps

The flake exposes convenience apps that adapt to your current system:

- Linux (NixOS):
  - `apply`
  - `build-switch`
  - `copy-keys`
  - `create-keys`
  - `check-keys`
  - `install`
  - `install-with-secrets`

- macOS (nix-darwin):
  - `apply`
  - `build`
  - `build-switch`
  - `copy-keys`
  - `create-keys`
  - `check-keys`
  - `rollback`

List the flake outputs (apps, packages, etc.):

```bash
nix flake show
```

---

## Repository layout

- [flake.nix](https://github.com/TingRubato/nixos-config/blob/4d03ccf11223c3acd54835fadc6f4dc1810c0204/flake.nix): main flake; inputs, apps, and system definitions
- [hosts/darwin](https://github.com/TingRubato/nixos-config/tree/main/hosts): macOS host modules
- [hosts/nixos](https://github.com/TingRubato/nixos-config/tree/main/hosts): NixOS host modules (including disko definitions)
- [modules/](https://github.com/TingRubato/nixos-config/tree/main/modules): shared modules (and NixOS home-manager module import)
- [overlays/](https://github.com/TingRubato/nixos-config/tree/main/overlays): nixpkgs overlays
- [secrets.nix](https://github.com/TingRubato/nixos-config/blob/main/secrets.nix): agenix recipients and secret mapping
- `secrets/`: git submodule pointing to your encrypted secrets repository

---

## Customization tips

- Change the `user` in the flake to match your local username on both macOS and NixOS.
- Add per-host overrides or hardware-specific configs under `hosts/<platform>/`.
- Put personal overlays in `overlays/` and import them in your modules as needed.
- Keep secrets encrypted with agenix and commit only the `.age` files (not plaintext).
- Consider pinning inputs to specific revisions for reproducibility (`nix flake lock`).

---

## Troubleshooting

- “Flakes are disabled”: set `experimental-features = nix-command flakes` in `nix.conf`.
- Submodule errors: ensure you have SSH read access to the `secrets` repo or update `.gitmodules` to your fork.
- age key not found: ensure your private key exists at `~/.config/age/keys.txt` or your YubiKey is connected.
- On macOS, first apply may prompt for privileged actions (daemon setup, Rosetta enablement on Apple Silicon, etc.).

---

## License

This repository’s license (if any) applies. If forking, add your own license as appropriate.
