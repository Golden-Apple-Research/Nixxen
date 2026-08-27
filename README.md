# Nixxen

NixOS Flake Skeleton für Desktop, Server und k3s-Cluster.

## Hosts

### Main Desktop tsathoggua

Desktop mit Hyprland Desktop, eigentlich ein Lenovo Thinkpad mit AMD Ryzen 7 5700U / 16GB RAM mit Dockingstation

### Main Server nixda

Headless Machine i8400T 4Core / 32 GB RAM auf dem die builds erstellt werden, dient auch als k3s Server und fuer andere "experimente"

### Raspberries 4th gen

Sollen als k3s Worker fuer Main Server konfiguriert werden je 1x 4GB / 1x 8GB

### Xiaomi

Altes Xiaomi Redmi Note 8 Pro (Codename `begonia`), 2xA76, 6xA5x CPU / 6GB RAM, connected via Ethernet over USB on nixda. Soll ebenfalls als k3s Worker fuer nixda konfiguriert werden

**Ansatz:** Kernel ist der pmOS Mainline-Fork 6.16.4 (MT6785, `CONFIG_KEXEC=y`),
Boot läuft über ein selbst gebautes Android-boot.img (`mkbootimg`, siehe
`modules/hardware/xiaomi-begonia/boot.nix`). Installiert wird vom laufenden
postmarketOS aus via **nixos-anywhere**.

#### Xiaomi: Bauen

Der Kernel wird auf **nixda** gebaut (32 GB RAM, Cross-Compile x86_64 → aarch64):

```bash
# Nur der Kernel (Cross-Build, schnell):
nix build .#packages.x86_64-linux.xiaomi-begonia-kernel

# Komplettes System remote auf nixda bauen und auf das Handy deployen:
nixos-rebuild switch --flake .#xiaomi-begonia \
  --target-host root@begonia --build-host nx@nixda
```

Alternativ nixda als distributed Builder eintragen (Client `nix.conf`):

```
builders = ssh://nx@nixda x86_64-linux,aarch64-linux
```

#### Xiaomi: Installation vom laufenden pmOS

1. Auf dem pmOS prüfen: `zcat /proc/config.gz | grep KEXEC` (sollte `y` sein)
   und `ls /dev/disk/by-partlabel/` (Partitionen: `boot`, `userdata`, ...)
2. Leeres recovery-DTBO vom Handy ins Repo kopieren:
   ```bash
   scp root@begonia:/boot/empty.dtbo modules/hardware/xiaomi-begonia/empty.dtbo
   # danach in hosts/xiaomi-begonia/default.nix aktivieren:
   #   hardware.xiaomiBegonia.recoveryDtbo = ./empty.dtbo;
   ```
3. Kernel-Hash ermitteln (erster Build bricht mit erwartetem Hash ab):
   ```bash
   nix build .#packages.x86_64-linux.xiaomi-begonia-kernel
   # hash aus der Fehlermeldung in modules/hardware/xiaomi-begonia/kernel-pkg.nix
   # bei `hash = lib.fakeHash;` eintragen
   ```
4. Root-Dateisystem auf `userdata` (ext4) anlegen – disko oder manuell –
   und `fileSystems."/"` in `hosts/xiaomi-begonia/default.nix` setzen
5. Installieren (von einem Rechner mit dem Flake):
   ```bash
   nixos-anywhere --flake .#xiaomi-begonia root@begonia
   ```
6. Nach dem ersten erfolgreichen Boot in `hosts/xiaomi-begonia/default.nix`
   `hardware.xiaomiBegonia.flashBoot = true;` setzen – danach wird die
   boot.img bei jedem Kernel-/initrd-Update automatisch geflasht

## Struktur

```
flake.nix                  Alle nixosConfigurations + Inputs
hosts/
  common/default.nix       Gemeinsame Basis (SSH, User, Locale, Nix, sops-nix)
  tsathoggua/              Desktop (Hyprland, Home Manager, hardware-config)
  nixda/                   Server (k3s Server, aarch64-Binfmt, USB-Ethernet)
  rpi4-4g/                 k3s Worker
  rpi4-8g/                 k3s Worker
  xiaomi-begonia/           k3s Worker (pmOS-Mainline-Kernel, boot.img-Boot)
modules/
  desktop/hyprland.nix     Hyprland + PipeWire + Wayland-Tools
  hardware/rpi4.nix        Raspberry-Pi-4-Basis (Boot, cgroups, Firmware)
  hardware/xiaomi-begonia/ Kernel (pmOS MT6785-Fork, Config eingecheckt),
                           boot.img-Generierung + Flash-Logik
  k3s/server.nix           k3s Control Plane (nixda)
  k3s/agent.nix            k3s Worker (alle Agents)
```

## Benutzung

```bash
# System bauen/deployen (auf dem jeweiligen Host oder remote mit --target-host)
sudo nixos-rebuild switch --flake .#tsathoggua
sudo nixos-rebuild switch --flake .#nixda
sudo nixos-rebuild switch --flake .#rpi4-4g
sudo nixos-rebuild switch --flake .#rpi4-8g

# Formatieren
nix fmt
```

### Raspberry-Pi-SD-Karten bauen

In `hosts/rpi4-4g/default.nix` (bzw. `-8g`) den auskommentierten sd-image-Import aktivieren, dann auf nixda (hat aarch64-Binfmt) oder direkt aarch64 bauen:

```bash
nix build .#nixosConfigurations.rpi4-4g.config.system.build.sdImage
# Ergebnis mit zstd/`dd` auf die SD-Karte schreiben
```

### k3s-Cluster in Betrieb nehmen

1. **nixda zuerst deployen** – startet den k3s-Server.
2. Node-Token auslesen:
   ```bash
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```
3. Token auf jedem Worker unter `/var/lib/secrets/k3s/token` ablegen
   (siehe TODO in `modules/k3s/agent.nix` – Ziel: Ausrollung per sops-nix).
4. Worker deployen und prüfen:
   ```bash
   sudo k3s kubectl get nodes   # auf nixda
   ```

### TODOs im Skeleton

- [ ] Echte `hardware-configuration.nix` für tsathoggua erzeugen
      (`nixos-generate-config --show-hardware-config`) – nixda ist erledigt
- [ ] SSH-Key(s) in `hosts/common/default.nix` hinterlegen
      (SSH-Login ist nur per Key erlaubt!)
- [ ] `initialPassword` ersetzen (besser: `hashedPasswordFile` via sops-nix)
- [ ] Feste IP/DNS für `nixda` – k3s `serverAddr` in `modules/k3s/agent.nix`
- [ ] k3s-Token per sops-nix ausrollen (`.sops.yaml` anlegen)
- [ ] Xiaomi: Kernel-Hash in kernel-pkg.nix eintragen (erster Build zeigt ihn)
- [ ] Xiaomi: empty.dtbo vom pmOS kopieren, `recoveryDtbo` setzen
- [ ] Xiaomi: userdata partitionieren (disko), `fileSystems."/"` setzen,
      danach `nixos-anywhere` und `flashBoot = true`

## Dev

```bash
nix develop        # nixfmt, sops, age
```
