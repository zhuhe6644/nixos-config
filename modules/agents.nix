{
  inputs,
  lib,
  pkgs,
  username,
  ...
}:

let
  chatgpt = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.chatgpt.override {
    commandLineArgs = "--password-store=gnome-libsecret";
  };

  # The downloaded agent runtime expects conventional Linux paths. Keep these
  # adaptations on the app and its children, including non-login agent shells.
  agentChatgpt = chatgpt.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      wrapProgram "$out/bin/chatgpt" \
        --prefix PATH : ${lib.makeBinPath [ pkgs.bubblewrap ]} \
        --set-default SSL_CERT_FILE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
        --set-default FONTCONFIG_FILE /etc/fonts/fonts.conf
    '';
  });

  # Cowork probes fixed distro paths. These must be part of Claude's FHS
  # environment: host /usr links are hidden by its private /usr mount.
  coworkRuntime = pkgs.runCommand "claude-cowork-runtime" { } ''
    test -r ${pkgs.OVMF.firmware}
    test -r ${pkgs.OVMF.variables}
    test -x ${lib.getExe pkgs.virtiofsd}
    mkdir -p "$out/share/OVMF" "$out/libexec"
    ln -s ${pkgs.OVMF.firmware} "$out/share/OVMF/OVMF_CODE_4M.fd"
    ln -s ${pkgs.OVMF.variables} "$out/share/OVMF/OVMF_VARS_4M.fd"
    ln -s ${lib.getExe pkgs.virtiofsd} "$out/libexec/virtiofsd"
  '';

  claudeDesktop =
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop.override
      {
        commandLineArgs = "--password-store=gnome-libsecret";
        buildFHSEnv =
          args:
          pkgs.buildFHSEnv (
            args
            // {
              targetPkgs =
                p:
                args.targetPkgs p
                ++ [
                  p.qemu_kvm
                  coworkRuntime
                ];
            }
          );
      };
in
{
  environment.systemPackages = with pkgs; [
    agentChatgpt
    claudeDesktop
    bubblewrap

    # Common command-line tools for working with repositories and files.
    ripgrep
    jq
    file
    unzip
    zip
    gh

    # Keep language runtimes available; install project-specific libraries and
    # build tools through development shells or project environments.
    python3
    uv
    nodejs
    pnpm
  ];

  # Cowork's KVM micro-VM uses the vhost-vsock transport on the host.
  boot.kernelModules = [ "vhost_vsock" ];
  users.users.${username}.extraGroups = [ "kvm" ];
}
