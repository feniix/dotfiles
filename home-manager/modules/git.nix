{ ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    signing = {
      key = "~/.ssh/id_ed25519";
      signByDefault = true;
      format = "ssh";
    };

    settings = {
      user = {
        name = "Sebastian Otaegui";
        email = "feniix@gmail.com";
      };

      alias = {
        s = "status";
        ci = "commit";
        br = "branch";
        co = "checkout";
        d = "diff";
        lg = "log";
        l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        ld = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit -p";
        append = "commit --amend -C HEAD";
      };

      credential.helper = "osxkeychain";

      push.default = "current";
      pull.rebase = false;

      rebase.autosquash = true;
      branch.autosetupmerge = "always";

      core = {
        autocrlf = "input";
        excludesfile = "~/.config/git/ignore";
        quotepath = false;
        pager = "diff-so-fancy | less --tabs=4 -RFX";
        ignorecase = false;
      };

      diff = {
        renames = "copies";
        mnemonicprefix = true;
      };

      color = {
        ui = true;
        branch = {
          current = "yellow black";
          local = "yellow";
          remote = "magenta";
        };
        diff = {
          meta = "yellow bold";
          frag = "magenta bold";
          old = "red reverse";
          new = "green reverse";
          whitespace = "white reverse";
        };
        status = {
          added = "green";
          changed = "yellow";
          untracked = "cyan reverse";
          branch = "magenta";
        };
        "diff-highlight" = {
          oldNormal = "red bold";
          oldHighlight = "red bold 52";
          newNormal = "green bold";
          newHighlight = "green bold 22";
        };
      };

      interactive = {
        added = "green";
        changed = "yellow";
        untracked = "cyan reverse";
        branch = "magenta";
      };

      pager = {
        log = "diff-so-fancy | less";
        show = "diff-so-fancy | less";
        diff = "diff-so-fancy | less";
      };

      init.defaultBranch = "main";
      github.user = "feniix";

      gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers";

      "http \"https://gopkg.in\"".followRedirects = true;

      "diff \"sopsdiffer\"".textconv = "sops -d";

      url = {
        "git@github-gatx:GATX-Corp/".insteadOf = [
          "https://github.com/GATX-Corp/"
          "git@github.com:GATX-Corp/"
        ];
        "git@github.com:feniix/".insteadOf = "https://github.com/feniix/";
        "git@github.com:spantree/".insteadOf = "https://github.com/spantree/";
      };
    };
  };
}
