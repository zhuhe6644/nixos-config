{ pkgs, username, ... }:

let
  email = "zhuhe6644@outlook.com";

  githubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPselmLhR1E39duYo8Ep5Bp6EAMS3+6nQeKaPuWn3+yB";
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHnOGvsJiAk9oEtprg97qBpTXNiDWLiH6tT5s/FN4fF";
in
{
  environment.systemPackages = with pkgs; [
    git
  ];

  home-manager.users.${username} = {
    programs.git = {
      enable = true;
      settings = {
        user.name = "He Zhu";
        user.email = email;
      };

      signing = {
        format = "ssh";
        key = "key::${signingKey}";
        allowedSigners = "${email} ${signingKey}\n";
        signByDefault = true;
      };
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."github.com" = {
        IdentityFile = toString (pkgs.writeText "github-auth.pub" "${githubKey}\n");
        IdentitiesOnly = true;
      };
    };
  };
}
