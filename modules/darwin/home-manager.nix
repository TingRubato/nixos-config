{ config, pkgs, lib, home-manager, ... }:

let
  user = "timmy";

  # 启动 Emacs 的脚本 - commented out to avoid building Emacs
  # myEmacsLauncher = pkgs.writeScript "emacs-launcher.command" ''
  #   #!/bin/sh
  #   emacsclient -c -n &
  # '';

  # 引入共享文件
  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  additionalFiles = import ./files.nix { inherit user config pkgs; };
in
{
  # 导入 Dock 配置模块
  imports = [ ./dock ];

  # 系统级用户定义（非 home-manager）
  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  # 配置 Homebrew 及 MAS App
  homebrew = {
    enable = true;
    # Use the correct Homebrew path for ARM Macs
    brewPrefix = "/opt/homebrew/bin";
    casks = pkgs.callPackage ./casks.nix {};
    brews = [
      "node"           # Node.js runtime
      "npm"            # Node package manager
      "prettier"       # Code formatter
      "aws-cdk"        # AWS CDK
      "terrastruct/tap/tala"
    ];
    taps = [
      "terrastruct/tap"
    ];
    masApps = {
      "wireguard" = 1451685025;
    };
  };

  # Home Manager 用户配置
  home-manager = {
    useGlobalPkgs = true;
    users.${user} = { pkgs, config, lib, ... }: {
      home = {
        enableNixpkgsReleaseCheck = false;

        packages = with pkgs; [
          # nodePackages.aws-cdk  # 安装 AWS CDK - moved to Homebrew
        ];

        file = lib.mkMerge [
          sharedFiles
          additionalFiles
          # { "emacs-launcher.command".source = myEmacsLauncher; }  # Commented out
        ];

        stateVersion = "23.11";
      };

      manual.manpages.enable = false;
    };
  };

  # MacOS Dock 配置
  local.dock = {
    enable = true;
    username = user;
    entries = [
      { path = "/System/Applications/Messages.app/"; }
      { path = "/System/Applications/Facetime.app/"; }
      { path = "${pkgs.alacritty}/Applications/Alacritty.app/"; }
      { path = "/System/Applications/Music.app/"; }
      { path = "/System/Applications/News.app/"; }
      { path = "/System/Applications/Photos.app/"; }
      { path = "/System/Applications/Photo Booth.app/"; }
      { path = "/System/Applications/TV.app/"; }
      { path = "/System/Applications/Home.app/"; }
      # {
      #   path = toString myEmacsLauncher;
      #   section = "others";
      # }
      {
        path = "${config.users.users.${user}.home}/.local/share/";
        section = "others";
        options = "--sort name --view grid --display folder";
      }
      {
        path = "${config.users.users.${user}.home}/.local/share/downloads";
        section = "others";
        options = "--sort name --view grid --display stack";
      }
    ];
  };
}
