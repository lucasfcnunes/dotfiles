{
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.gpu =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      gpuVendors = (config.hardware.facter.report.hardware.graphics_card or [ ]) |> map (e: e.vendor.hex);
      isHyperVGpuPV = gpuVendors |> builtins.elem "1414";
    in
    {
      config = lib.mkIf isHyperVGpuPV {
        virtualisation.hypervGuest.dxgkrnl.enable = lib.mkDefault true;
        environment.sessionVariables = {
          LD_LIBRARY_PATH = [
            # AMD "CUDA"
            "${pkgs.zluda}/lib"
            # opencl/clinfo
            "${pkgs.ocl-icd}/lib"
            "${pkgs.pocl}/lib"
            # AMD driver needs this
            "${pkgs.openssl.out}/lib" # or (lib.makeLibraryPath [ pkgs.openssl ])
            # libx11
            # "${pkgs.libx11}/lib"
          ];
          OCL_ICD_VENDORS = "${pkgs.pocl}/etc/OpenCL/vendors";
          GALLIUM_DRIVER = "d3d12";
          # MESA_D3D12_DEFAULT_ADAPTER_NAME = "Nvidia";
        };
        # programs.nix-ld.libraries = [
        #   pkgs.zluda
        #   pkgs.openssl
        # ];
        # /dev/dxg is owned by the video group
        users.users =
          let
            extraGroups = [
              "video"
              # "render" # ?
            ];
          in
          {
            root.extraGroups = extraGroups;
            lucasfcnunes.extraGroups = extraGroups;
          };
        environment.systemPackages = with pkgs; [
          vulkan-tools
          lshw
          clinfo
          # amd
          rocmPackages.amdsmi
          zluda
        ];
        # TODO: enable rocm support at nixpkgs.config level
        # nixpkgs.config.rocmSupport = true;
        # hardware.facter.detected.graphics.amd.enable = true;
        # hardware.graphics = {
        #   enable = true;
        #   # enable32Bit = true;
        # };
        # # boot.kernelParams = [
        # #   "video=DP-1:2560x1440@144"
        # #   "video=DP-2:2560x1440@144"
        # # ];
        # hardware.amdgpu.initrd.enable = true;
        # # hardware.amdgpu.zluda.enable = true;
        # boot.kernelModules = [
        #   "amdgpu"
        # ];
        # hardware.amdgpu.opencl.enable = true;
        # services.lact.enable = true;
      };
    };
}
