{ inputs, pkgs, ... }:

let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # The agent runtime the app downloads looks for CA certificates and fontconfig
  # in paths NixOS lacks. Setting them on the app's wrapper reaches its children
  # too, including non-login agent shells.
  chatgptDesktop =
    (llmAgents.chatgpt.override {
      commandLineArgs = "--password-store=gnome-libsecret";
    }).overrideAttrs
      (old: {
        postFixup = (old.postFixup or "") + ''
          wrapProgram "$out/bin/chatgpt" \
            --set-default SSL_CERT_FILE ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
            --set-default FONTCONFIG_FILE /etc/fonts/fonts.conf
        '';
      });

  # Cowork starts its VM with qemu from PATH, which llm-agents leaves to the
  # host. Adding it to Claude's FHS environment keeps it off the system PATH.
  claudeDesktop = llmAgents.claude-desktop.override {
    commandLineArgs = "--password-store=gnome-libsecret";
    buildFHSEnv =
      args:
      pkgs.buildFHSEnv (
        args
        // {
          targetPkgs = p: args.targetPkgs p ++ [ p.qemu_kvm ];
        }
      );
  };
in
{
  environment.systemPackages = with pkgs; [
    chatgptDesktop
    claudeDesktop

    # Claude Code's sandbox.
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
}
