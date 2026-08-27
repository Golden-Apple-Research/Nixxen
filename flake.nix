{
  description = "Nixxen – NixOS Flake: Desktop (Hyprland), k3s-Server & -Worker";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Home Manager (Desktop-User tsathoggua)
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware-Module (v. a. Raspberry Pi)
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Secrets-Management (k3s-Token, Passwort-Hashes, SSH-Keys)
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      sops-nix,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Baustein für die beiden Raspberry-Pi-4-Worker
      # (unterscheiden sich nur im Hostnamen / RAM)
      mkRpi4 =
        name:
        nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit
              sops-nix
              nixos-hardware
              nixpkgs
              ;
          };
          modules = [ (./hosts + "/${name}") ];
        };
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nixfmt-rfc-style
              sops
              age
            ];
          };
        }
      );

      # Cross-Kernel für das Xiaomi: nativ auf nixda bauen (x86_64 -> aarch64),
      # deutlich schneller als Emulation und RAM ist dort genug vorhanden:
      #   nix build .#packages.x86_64-linux.xiaomi-begonia-kernel
      packages.x86_64-linux.xiaomi-begonia-kernel =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        pkgs.pkgsCross.aarch64-multiplatform.callPackage ./modules/hardware/xiaomi-begonia/kernel-pkg.nix { };

      nixosConfigurations = {
        # Main Desktop: ThinkPad, AMD Ryzen 7 5700U, 16 GB, Dockingstation, Hyprland
        tsathoggua = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              sops-nix
              home-manager
              ;
          };
          modules = [ ./hosts/tsathoggua ];
        };

        # Main Server: headless, Build-Server, k3s-Server (Control Plane)
        nixda = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit sops-nix; };
          modules = [ ./hosts/nixda ];
        };

        # k3s-Worker: Raspberry Pi 4, 4 GB
        rpi4-4g = mkRpi4 "rpi4-4g";

        # k3s-Worker: Raspberry Pi 4, 8 GB
        rpi4-8g = mkRpi4 "rpi4-8g";

        # k3s-Worker: Xiaomi Redmi Note 8 Pro ("begonia"), USB-Ethernet an nixda.
        # Kernel/Boot via modules/hardware/xiaomi-begonia/ (pmOS Mainline-Fork)
        xiaomi-begonia = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit sops-nix; };
          modules = [ ./hosts/xiaomi-begonia ];
        };
      };
    };
}
