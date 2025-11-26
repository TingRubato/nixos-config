# NixOS Configuration

A comprehensive NixOS and macOS configuration with secrets management, supporting both Linux and Darwin systems.

## Overview

This repository contains a flake-based configuration for both NixOS (x86_64 and aarch64) and macOS (Intel and Apple Silicon). It integrates:

- **home-manager** for per-user configuration
- **nix-darwin** for macOS system management
- **disko** for declarative disk partitioning during NixOS installs
- **agenix + age** (optionally YubiKey via age-plugin-yubikey) for secret management
- **nix-homebrew** for managing Homebrew alongside Nix on macOS
- **Convenience apps** to install, switch, manage keys, and more

This configuration provides:
- **Cross-platform support**: NixOS (Linux) and macOS (Darwin) configurations
- **Secrets management**: Age-encrypted secrets with agenix
- **Home Manager integration**: User-level package and configuration management
- **Modular design**: Shared modules across platforms
- **Automated setup**: Helper scripts for easy installation and configuration

## Architecture

```
├── flake.nix                 # Main flake configuration
├── hosts/                    # System-specific configurations
│   ├── darwin/              # macOS configuration
│   ├── nixos/               # NixOS configuration
│   └── vmware/              # VMware-specific configuration
├── modules/                 # Reusable configuration modules
│   ├── darwin/              # macOS-specific modules
│   ├── nixos/               # NixOS-specific modules
│   └── shared/              # Cross-platform modules
├── apps/                    # Helper scripts for each platform
│   ├── aarch64-darwin/      # Apple Silicon macOS scripts
│   ├── x86_64-darwin/       # Intel macOS scripts
│   ├── aarch64-linux/       # ARM64 Linux scripts
│   └── x86_64-linux/        # x86_64 Linux scripts
├── overlays/                # Nix package overlays
├── secrets/                 # Age-encrypted secrets (git submodule)
└── secrets.nix              # Secrets mapping and recipients
```

## Prerequisites

### Requirements

- **Nix with flakes enabled** (Nix 2.18+ recommended)
  - Add to `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`:
    ```
    experimental-features = nix-command flakes
    ```
- **Git** (with SSH access to your secrets repo)
- **SSH client** and SSH key pair for secrets access
- **Age** (for secrets management, provided via `nix develop`)

### For NixOS Installation
- A computer with UEFI firmware
- Internet connection
- USB drive with NixOS installer
- NixOS install ISO and a target disk you are willing to wipe when using disko

### For macOS Setup
- macOS system with admin privileges
- Xcode Command Line Tools installed
- Nix installed (daemon mode recommended)
- On Apple Silicon, Rosetta will be enabled automatically by nix-homebrew module

### Optional but Recommended
- **age-plugin-yubikey** (provided via `nix develop`)
- A **YubiKey** if you plan to use age-plugin-yubikey for secrets

## Quick Start

### 1) Clone and Initialize Submodules

You need access to the `secrets` submodule (default points to `git@github.com:TingRubato/secrets.git`). If you're using your own secrets repo, update `.gitmodules` first.

```bash
git clone git@github.com:TingRubato/nixos-config.git
cd nixos-config
git submodule update --init --recursive
```

Optionally enter the development shell (provides `age`, `age-plugin-yubikey`, etc.):

```bash
nix develop
```

You can also run directly from GitHub without cloning:

```bash
nix run github:TingRubato/nixos-config#apply
```

### 2) Customize for Your Machine(s)

- **Edit the username** in `flake.nix`:
  ```nix
  user = "tingxu";  # change to your local username
  ```
- **Review and adjust host modules** under:
  - macOS: `hosts/darwin`
  - NixOS: `hosts/nixos`
- **Review modules** in `modules/` and `overlays/` as needed
- **Review secrets.nix** and ensure recipients are correct for your age keys

## Implementation Steps

### Step 1: Set Up Secrets (agenix + age)

If you don't already have an age key:

```bash
# In or out of `nix develop`:
age-keygen -o ~/.config/age/keys.txt
```

Convenience apps in this flake help with keys (see "Available Commands" below). Typical flow:

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

Recipients and secret paths are organized via `secrets.nix`. Ensure your public key(s) are listed appropriately.

### Step 2: Platform-Specific Setup

#### For macOS Setup (nix-darwin + home-manager + nix-homebrew)

1. **Install Nix on macOS** (daemon mode). Follow the official instructions.

2. **From this repo directory, apply the configuration**:
   ```bash
   # Apply default macOS configuration for your architecture
   nix run .#apply
   # or build and switch
   nix run .#build-switch
   ```

Notes:
- `nix-homebrew` will be enabled and configured with taps:
  - homebrew-core, homebrew-cask, homebrew-bundle
- On Apple Silicon, Rosetta is enabled automatically.
- A rollback app is provided:
  ```bash
  nix run .#rollback
  ```

#### For NixOS Installation (installer + disko + home-manager)

**Warning**: The disko-based install will ERASE the target disk. Review and edit the disko/host files under `hosts/nixos` before proceeding.

1. **Boot from NixOS installer** and connect to internet

2. **Clone your configuration**:
   ```bash
   git clone git@github.com:TingRubato/nixos-config.git
   cd nixos-config
   git submodule update --init --recursive
   ```

3. **Install NixOS**:
   ```bash
   # Run the installer (may prompt for the target device configuration)
   nix run .#install
   
   # Or, if you want to include secrets during install:
   nix run .#install-with-secrets
   ```

4. **Reboot and enjoy your new system!**

   After logging in as your user:
   ```bash
   # Build and switch to the latest configuration
   nix run .#build-switch
   ```

### Step 3: Post-Installation Configuration

#### Configure Secrets

1. **Add secrets to your repository**:
   ```bash
   cd secrets
   
   # Example: Add SSH private key
   cp ~/.ssh/id_ed25519 id_ed25519.age
   age -e -i ~/.ssh/id_ed25519.pub id_ed25519.age
   
   # Example: Add API keys
   echo "your-api-key" | age -e -i ~/.ssh/id_ed25519.pub > api-key.age
   
   git add .
   git commit -m "Add additional secrets"
   git push
   ```

2. **Update secrets configuration** in `modules/*/secrets.nix`:
   ```nix
   {
     "wifi-password.age".path = "/etc/wifi-password";
     "id_ed25519.age".path = "/home/tingxu/.ssh/id_ed25519";
     "api-key.age".path = "/home/tingxu/.config/api-key";
   }
   ```

#### Customize Configuration

1. **Edit packages** in `modules/*/packages.nix`:
   ```nix
   with pkgs; [
     # Add your favorite packages
     neovim
     firefox
     vscode
   ]
   ```

2. **Modify system settings** in `hosts/*/default.nix`:
   - Change hostname
   - Adjust timezone
   - Configure network settings
   - Modify security settings

3. **Customize user programs** in `modules/*/home-manager.nix`:
   - Shell configuration
   - Editor settings
   - Desktop environment preferences

## Daily Usage

- **Update inputs and switch**:
  ```bash
  # Update flake inputs to latest
  nix flake update
  
  # Apply updated configuration
  nix run .#build-switch
  # or on macOS, you can also:
  nix run .#apply
  ```

- **Run any app by name** (see below). From GitHub directly:
  ```bash
  nix run github:TingRubato/nixos-config#<app>
  ```

## Available Commands

The flake exposes convenience apps that adapt to your current system:

### NixOS Commands
- `nix run .#apply` - Configure system with user details
- `nix run .#build-switch` - Build and switch to new configuration
- `nix run .#copy-keys` - Copy SSH keys to system
- `nix run .#create-keys` - Generate new SSH keys
- `nix run .#check-keys` - Verify SSH key configuration
- `nix run .#install` - Install NixOS (erases target disk)
- `nix run .#install-with-secrets` - Install NixOS with secrets

### macOS Commands
- `nix run .#apply` - Configure system with user details
- `nix run .#build` - Build configuration without switching
- `nix run .#build-switch` - Build and switch to new configuration
- `nix run .#rollback` - Rollback to previous configuration
- `nix run .#copy-keys` - Copy SSH keys to system
- `nix run .#create-keys` - Generate new SSH keys
- `nix run .#check-keys` - Verify SSH key configuration

List the flake outputs (apps, packages, etc.):
```bash
nix flake show
```

## Configuration Features

### NixOS Features
- **Window Manager**: BSPWM with Polybar
- **Display Manager**: LightDM with Slick greeter
- **Compositor**: Picom with animations and effects
- **File Sync**: Syncthing for cross-device synchronization
- **Security**: Firewall, SSH, and encrypted secrets
- **Docker**: Container runtime support
- **Fonts**: Comprehensive font collection

### macOS Features
- **Package Management**: Homebrew integration via nix-homebrew
- **System Configuration**: Dock, Finder, and trackpad settings
- **Security**: Encrypted secrets management
- **Development**: Complete development environment

### Shared Features
- **Shell**: Zsh with Oh My Zsh and Powerlevel10k
- **Editor**: Emacs configuration
- **Git**: Comprehensive Git setup
- **Secrets**: Age-encrypted secrets with agenix

## Repository Layout

- `flake.nix`: main flake; inputs, apps, and system definitions
- `hosts/darwin`: macOS host modules
- `hosts/nixos`: NixOS host modules (including disko definitions)
- `modules/`: shared modules (and NixOS home-manager module import)
- `overlays/`: nixpkgs overlays
- `secrets.nix`: agenix recipients and secret mapping
- `secrets/`: git submodule pointing to your encrypted secrets repository

## Customization Tips

- Change the `user` in the flake to match your local username on both macOS and NixOS.
- Add per-host overrides or hardware-specific configs under `hosts/<platform>/`.
- Put personal overlays in `overlays/` and import them in your modules as needed.
- Keep secrets encrypted with agenix and commit only the `.age` files (not plaintext).
- Consider pinning inputs to specific revisions for reproducibility (`nix flake lock`).

## Troubleshooting

### Common Issues

1. **"Flakes are disabled"**:
   - Set `experimental-features = nix-command flakes` in `nix.conf`.

2. **SSH Key Not Found**:
   ```bash
   ssh-add ~/.ssh/id_ed25519
   ```

3. **Secrets Repository Access Denied**:
   - Verify SSH key is added to GitHub
   - Check repository permissions
   - Ensure SSH agent is running
   - Ensure you have SSH read access to the `secrets` repo or update `.gitmodules` to your fork

4. **Build Failures**:
   ```bash
   # Clean build cache
   nix-collect-garbage -d
   
   # Rebuild with verbose output
   nix run .#build-switch --verbose
   ```

5. **Disk Partitioning Issues**:
   - Verify disk selection in `modules/nixos/disk-config.nix`
   - Check disk space requirements
   - Ensure UEFI compatibility

6. **age key not found**:
   - Ensure your private key exists at `~/.config/age/keys.txt` or your YubiKey is connected

7. **On macOS, first apply may prompt** for privileged actions (daemon setup, Rosetta enablement on Apple Silicon, etc.)

### Getting Help

- Check the [NixOS Manual](https://nixos.org/manual/nixos/)
- Review [Home Manager documentation](https://nix-community.github.io/home-manager/)
- Consult [nix-darwin documentation](https://github.com/LnL7/nix-darwin)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on your system
5. Submit a pull request

## License

This configuration is provided as-is for educational and personal use. Please review and modify according to your needs and security requirements.

If forking, add your own license as appropriate.

## Security Notes

- **Never commit unencrypted secrets** to version control
- **Use strong SSH keys** (Ed25519 recommended)
- **Regularly rotate secrets** and SSH keys
- **Review security settings** before deployment
- **Keep systems updated** with latest security patches

---

**Happy Nixing!** 🦊