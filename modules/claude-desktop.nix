{
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

let
  base = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop.override {
    # Pinned to the Secret Service for the reason described in apps.nix.
    commandLineArgs = "--password-store=gnome-libsecret";
  };
in
{
  # llm-agents.nix ships packages only, so everything Cowork's micro-VM sandbox
  # needs from the host is spelled out here rather than coming from the flake.
  environment.systemPackages = [
    # Cowork drives its VMs with qemu, which this package's wrapper leaves off
    # the app's PATH.
    (pkgs.symlinkJoin {
      name = "claude-desktop-with-qemu";
      paths = [ base ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/claude-desktop \
          --prefix PATH : ${lib.makeBinPath [ pkgs.qemu ]}
      '';
    })
  ];

  # The app's capability check probes these absolute paths and takes no env
  # overrides, so they have to exist on the real filesystem. It also refuses the
  # virtiofsd it bundles and insists on a distro one.
  systemd.tmpfiles.rules = [
    "L+ /usr/share/OVMF/OVMF_CODE_4M.fd - - - - ${pkgs.OVMF.firmware}"
    "L+ /usr/share/OVMF/OVMF_VARS_4M.fd - - - - ${pkgs.OVMF.variables}"
    "L+ /usr/libexec/virtiofsd - - - - ${pkgs.virtiofsd}/bin/virtiofsd"
  ];

  # The micro-VM needs the vhost-vsock transport, and /dev/kvm to run at all.
  boot.kernelModules = [ "vhost_vsock" ];
  users.users.${username}.extraGroups = [ "kvm" ];
}
