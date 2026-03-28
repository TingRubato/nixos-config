# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### macOS (Darwin)
```bash
# Build and switch to new configuration (requires sudo)
nix run .#build-switch

# Build only (without switching)
nix run .#build

# Apply configuration with user details
nix run .#apply

# Rollback to previous generation
nix run .#rollback
```

### NixOS
```bash
# Build and switch to new configuration
nix run .#build-switch

# Install NixOS (WARNING: erases target disk)
nix run .#install

# Install with secrets
nix run .#install-with-secrets
```

### Secrets Management
```bash
# Create new age keys
nix run .#create-keys

# Copy keys to system
nix run .#copy-keys

# Verify key configuration
nix run .#check-keys

# Edit a secret (uses $EDITOR)
agenix -e path/to/secret.age

# Rekey secrets after changing recipients
agenix -r
```

### Development Shell
```bash
# Enter dev shell with age, age-plugin-yubikey, git
nix develop
```

### Update and Maintenance
```bash
# Update flake inputs
nix flake update

# Show available flake outputs
nix flake show
```

## Architecture

This is a flake-based Nix configuration supporting both NixOS (Linux) and macOS (Darwin) with shared modules.

### Key Files
- `flake.nix` - Main entry point defining inputs, outputs, and system configurations. Sets `user = "tingxu"` used throughout.
- `secrets.nix` - Agenix recipients and secret path mappings

### Module Structure
- `hosts/darwin/default.nix` - macOS host configuration (nix settings, system defaults, imports modules)
- `hosts/nixos/default.nix` - NixOS host configuration (boot, networking, services, users)
- `modules/shared/` - Cross-platform modules (nixpkgs config, overlays, packages)
- `modules/darwin/` - macOS-specific (homebrew, dock config, casks)
- `modules/nixos/` - NixOS-specific (disk config, services like picom/bspwm)

### Configuration Flow

**Darwin:** `flake.nix` → `hosts/darwin/default.nix` → imports `modules/darwin/secrets.nix`, `modules/darwin/home-manager.nix`, `modules/shared/`

**NixOS:** `flake.nix` → `hosts/nixos/default.nix` → imports `modules/nixos/secrets.nix`, `modules/nixos/disk-config.nix`, `modules/shared/`

### Home Manager Integration
- Darwin: configured in `modules/darwin/home-manager.nix` with Homebrew brews/casks/masApps
- NixOS: user config in `modules/nixos/home-manager.nix`
- Shared programs (zsh, git, vim, alacritty, tmux, ssh): `modules/shared/home-manager.nix`

### Package Layers
1. `modules/shared/packages.nix` - Common packages for all systems
2. `modules/darwin/packages.nix` - macOS-only packages (if any)
3. `modules/nixos/packages.nix` - NixOS-only packages
4. `modules/darwin/casks.nix` - Homebrew casks for macOS
5. Homebrew brews defined inline in `modules/darwin/home-manager.nix`

### Overlays
Overlays in `overlays/` are auto-imported by `modules/shared/default.nix`. An Emacs overlay is also fetched from a remote tarball.

### Secrets (Agenix)
- Private secrets stored in `secrets/` git submodule
- Age keys expected at `~/.config/age/keys.txt` or via YubiKey
- Secret mappings in `modules/darwin/secrets.nix` and `modules/nixos/secrets.nix`
