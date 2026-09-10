# Steam client reads ~/.steam/steam/env.txt at launch to set client env vars.
# Here: force Steam UI (Vulkan/GL) onto the NVIDIA dGPU via PRIME render
# offload. Bus ID is hardware-specific and cannot be probed at Nix build
# time (derivations have no hardware access; host has two NVIDIA GPUs, so
# the target GPU is a choice, not a discoverable fact). Verify with:
#   lspci | grep -i nvidia
#   nvidia-smi --query-gpu=bus_id --format=csv
{ ... }:

let
  renderGpuBusId = "0000:01:00.0";
in
{
  home.file.".steam/steam/env.txt".text = ''
    __NV_PRIME_RENDER_OFFLOAD=1
    __VK_LAYER_NV_optimus=NVIDIA_only
    VK_DEVICE_SELECT_PCI_BUS_ID=${renderGpuBusId}
  '';
}
