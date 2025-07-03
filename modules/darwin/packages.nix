{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  dockutil
  pkgs.awscli  # ✅ use as a Homebrew Formula
  pkgs.spotify
]
