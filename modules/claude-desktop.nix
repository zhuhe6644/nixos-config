{ inputs, username, ... }:

{
  imports = [ inputs.claude-desktop.nixosModules.default ];

  programs.claude-desktop.enable = true;
  programs.claude-desktop.cowork.kvmUsers = [ username ];
}
