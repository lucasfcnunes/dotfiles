# TODO: revise this configuration for the specific hardware and requirements of the AW16 system
{
  self,
  ...
}:
{
  flake.nixosModules.aw16lucasfcnunes-specifics =
    {
      config,
      lib,
      modulesPath,
      pkgs,
      ...
    }:
    {
      imports = [
        # (modulesPath + "/installer/scan/not-detected.nix")
        self.nixosModules.dell-oem-firmware
        self.nixosModules.wifi
      ];

      boot.initrd.availableKernelModules = [
        "nvme"
        "thunderbolt"
        "xhci_pci"
        "usbhid"
        "rtsx_pci_sdmmc"
      ];
      boot.kernelModules = [
        "kvm-intel"
        "mt7925e"
        # "nomodeset"
        # "btmtk" "btusb"
      ];
      hardware.enableRedistributableFirmware = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      # Kernel 6.12+ / latest recommended for MediaTek MT7925 & Intel Core 7 240H
      # boot.kernelPackages = pkgs.linuxPackages_latest;

      # NVIDIA RTX & Hybrid Graphics
      hardware.graphics.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        open = true; # Required for RTX 50-series; works on RTX 30/40-series
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      services.thermald.enable = true;
      services.power-profiles-daemon.enable = true;

      # 4. Bluetooth 5.4 hardware + GUI/CLI management (Blueman / bluetoothctl)
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Experimental = true; # Enables battery level reporting for BT peripherals
            FastConnectable = true;
          };
        };
      };

      services.keybase.enable = true;
      services.kbfs.enable = true;
    };

  flake.nixosModules.dell-oem-firmware =
    { pkgs, lib, ... }:
    let
      # Pulls Canonical's Ubuntu 24.04 (Noble) linux-firmware package with Dell OEM MT7925 blobs
      ubuntuOemFirmware = pkgs.stdenvNoCC.mkDerivation {
        pname = "ubuntu-dell-oem-firmware";
        version = "2024.03.18.noble1.22";

        src = pkgs.fetchurl {
          # Check https://launchpad.net/ubuntu/noble/+package/linux-firmware for the latest .deb URL if hash updates
          # url = "http://archive.ubuntu.com/ubuntu/pool/main/l/linux-firmware/linux-firmware_20240318.git3b128b60-0ubuntu2.9_all.deb";
          url = "http://launchpadlibrarian.net/723979360/linux-firmware_20240318.git3b128b60-0ubuntu2_amd64.deb";
          hash = "sha256-ey2b31pLSU1iAPa5JVCFMPbI5n7m4uTV3NebjS8oH18=";
        };
        # src = /home/lucasfcnunes/Downloads/linux-firmware_20240318.git3b128b60-0ubuntu2_amd64.deb;
        # src = ./linux-firmware_20240318.git3b128b60-0ubuntu2_amd64.deb;

        nativeBuildInputs = [ pkgs.dpkg ];
        unpackPhase = "dpkg-deb -x $src .";

        installPhase = ''
          mkdir -p $out/lib/firmware
          cp -r lib/firmware/mediatek $out/lib/firmware/
        '';
      };
    in
    {
      # Prepend Canonical's MediaTek firmware ahead of standard pkgs.linux-firmware
      hardware.firmware = lib.mkBefore [ ubuntuOemFirmware ];

      # Avoid 7.1.x xHCI setup-device timeout regression on Intel 8086:51ed + MT7925
      boot.kernelPackages = pkgs.linuxPackages_6_12;
      boot.kernelParams = [
        "usbcore.autosuspend=-1"
        "usbcore.old_scheme_first=1"
        "pcie_aspm=off"
      ];

      # Keep MT7925 and btusb from entering aggressive power states during probe.
      boot.extraModprobeConfig = ''
        options mt7925e disable_aspm=Y
        options btusb enable_autosuspend=n reset=y
      '';

      # Load Dell EC/ACPI wireless & MediaTek Bluetooth drivers explicitly
      # boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.kernelModules = [
        "dell-laptop"
        "dell-rbtn"
        "btmtk"
        "btusb"
        "mt7925e"
      ];

      hardware.enableRedistributableFirmware = true;
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      # Bind common Dell OEM Foxconn (0489) / AzureWave (13d3) MT7925 Bluetooth USB IDs & disable autosuspend
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0489", TEST=="power/control", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="13d3", TEST=="power/control", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", TEST=="power/control", ATTR{power/control}="on"
      '';
    };

  flake.homeModules.aw16lucasfcnunes-hmod-specifics =
    # TODO: maybe this is not the best design
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options = {
        aw16lucasfcnunes-hmod-specifics.enable = lib.mkEnableOption "Enable AW16-specific home module settings";
      };
      config = lib.mkIf config.aw16lucasfcnunes-hmod-specifics.enable {
        services.tailscale-systray.enable = true;
        services.gpg-agent = {
          enable = true;
          enableSshSupport = true;
          pinentry.package = pkgs.pinentry-qt;
          sshKeys = [
            # "YOUR_40_CHAR_AUTH_SUBKEY_KEYGRIP"
            "AD9B5630DC626C6BF33DF09CA3314B9C9563D4E4" # gpg-ssh (ed25519)
            "7CEA90F018B46A548D6D245ACC4BB5777D111F44" # gpg-ssh (rsa)
            "A5B50C3410C142735D957C096B002B1BB8AA185B 0" # personal old ssh
          ];
        };
        programs.vscode.enable = true;
        programs.docker-cli.enable = true;
        programs.discord.enable = true;
        # services.remmina.enable = true;
        # services.keybase.enable = true;
        # services.kbfs.enable = true;
      };
    };
}
