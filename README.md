# NixOS Configuration

A comprehensive NixOS and macOS configuration with secrets management, supporting both Linux and Darwin systems.

## Overview

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
└── secrets/                 # Age-encrypted secrets
```

## Prerequisites

### For NixOS Installation
- A computer with UEFI firmware
- Internet connection
- USB drive with NixOS installer
- SSH key pair for secrets access

### For macOS Setup
- macOS system with admin privileges
- Xcode Command Line Tools installed
- SSH key pair for secrets access

### Required Tools
- Git
- SSH client
- Age (for secrets management)

## Implementation Steps

### Step 1: Clone the Configuration

```bash
git clone https://github.com/your-username/nixos-config.git
cd nixos-config
```

### Step 2: Set Up Secrets Repository

1. Create a private GitHub repository for your secrets:
   ```bash
   # Create a new private repository on GitHub
   # Name it something like "my-secrets" or "nixos-secrets"
   ```

2. Initialize the secrets repository:
   ```bash
   mkdir secrets
   cd secrets
   git init
   git remote add origin git@github.com:your-username/your-secrets-repo.git
   ```

3. Create your first secret file:
   ```bash
   # Example: Create a WiFi password secret
   echo "my-wifi-password" | age -e -i ~/.ssh/id_ed25519.pub > wifi-password.age
   git add wifi-password.age
   git commit -m "Add WiFi password secret"
   git push -u origin main
   ```

### Step 3: Configure SSH Keys

Ensure your SSH key is added to your GitHub account and loaded in your SSH agent:

```bash
# Add your SSH key to the agent
ssh-add ~/.ssh/id_ed25519

# Test GitHub access
ssh -T git@github.com
```

### Step 4: Platform-Specific Setup

#### For NixOS Installation

1. **Boot from NixOS installer** and connect to internet

2. **Clone your configuration**:
   ```bash
   git clone https://github.com/your-username/nixos-config.git
   cd nixos-config
   ```

3. **Run the apply script**:
   ```bash
   nix run .#apply
   ```
   
   This script will:
   - Ask for your username, email, and GitHub details
   - Configure the secrets repository URL
   - Set up disk partitioning
   - Replace placeholders in configuration files

4. **Install NixOS**:
   ```bash
   nix run .#install
   ```

5. **Reboot and enjoy your new system!**

#### For macOS Setup

1. **Install Nix** (if not already installed):
   ```bash
   sh <(curl -L https://nixos.org/nix/install)
   ```

2. **Clone your configuration**:
   ```bash
   git clone https://github.com/your-username/nixos-config.git
   cd nixos-config
   ```

3. **Run the apply script**:
   ```bash
   nix run .#apply
   ```

4. **Build and switch to the configuration**:
   ```bash
   nix run .#build-switch
   ```

### Step 5: Post-Installation Configuration

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
     "id_ed25519.age".path = "/home/timmy/.ssh/id_ed25519";
     "api-key.age".path = "/home/timmy/.config/api-key";
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

### Step 6: Regular Maintenance

#### Update Configuration

```bash
# Update flake inputs
nix flake update

# Rebuild system
nix run .#build-switch
```

#### Manage Secrets

```bash
# Add new secret
echo "new-secret" | age -e -i ~/.ssh/id_ed25519.pub > new-secret.age

# Edit existing secret
age -d -i ~/.ssh/id_ed25519 new-secret.age | $EDITOR
age -e -i ~/.ssh/id_ed25519.pub > new-secret.age
```

## Available Commands

### NixOS Commands
- `nix run .#apply` - Configure system with user details
- `nix run .#build-switch` - Build and switch to new configuration
- `nix run .#copy-keys` - Copy SSH keys to system
- `nix run .#create-keys` - Generate new SSH keys
- `nix run .#check-keys` - Verify SSH key configuration

### macOS Commands
- `nix run .#apply` - Configure system with user details
- `nix run .#build` - Build configuration without switching
- `nix run .#build-switch` - Build and switch to new configuration
- `nix run .#rollback` - Rollback to previous configuration
- `nix run .#copy-keys` - Copy SSH keys to system
- `nix run .#create-keys` - Generate new SSH keys
- `nix run .#check-keys` - Verify SSH key configuration

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

## Troubleshooting

### Common Issues

1. **SSH Key Not Found**:
   ```bash
   ssh-add ~/.ssh/id_ed25519
   ```

2. **Secrets Repository Access Denied**:
   - Verify SSH key is added to GitHub
   - Check repository permissions
   - Ensure SSH agent is running

3. **Build Failures**:
   ```bash
   # Clean build cache
   nix-collect-garbage -d
   
   # Rebuild with verbose output
   nix run .#build-switch --verbose
   ```

4. **Disk Partitioning Issues**:
   - Verify disk selection in `modules/nixos/disk-config.nix`
   - Check disk space requirements
   - Ensure UEFI compatibility

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

## Security Notes

- **Never commit unencrypted secrets** to version control
- **Use strong SSH keys** (Ed25519 recommended)
- **Regularly rotate secrets** and SSH keys
- **Review security settings** before deployment
- **Keep systems updated** with latest security patches

---

**Happy Nixing!** 🦊
