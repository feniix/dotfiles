{ ... }:

{
  programs.ssh = {
    enable = true;
    # Opt out of HM's built-in defaults; we manage "*" ourselves below.
    enableDefaultConfig = false;
    includes = [ "~/.orbstack/ssh/config" ];

    settings = {
      # Global defaults — tuned for jittery Wi-Fi + fast reuse.
      # SSH config is first-match-wins; HM emits "*" last in the generated file.
      "*" = {
        Compression = true;
        HashKnownHosts = false;
        ServerAliveInterval = 10;
        ServerAliveCountMax = 3;
        TCPKeepAlive = true;
        IPQoS = "lowdelay throughput";
        ControlMaster = "auto";
        ControlPersist = "10m";
        ControlPath = "~/.ssh/controlmasters/%C";
        ConnectTimeout = 5;
        ConnectionAttempts = 2;
        ForwardAgent = true;
        AddKeysToAgent = true;
      };

      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };

      "github-gatx" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_gatx";
        IdentitiesOnly = true;
      };

      "wsl-dev" = {
        HostName = "192.168.1.99";
        User = "feniix";
        Port = 22;
        ForwardAgent = true;
      };

      "feniixhq-lan" = {
        HostName = "192.168.4.67";
        User = "feniix";
        ServerAliveInterval = 5;
        ServerAliveCountMax = 2;
        TCPKeepAlive = true;
        IPQoS = "lowdelay throughput";
      };

      "feniixhq" = {
        HostName = "100.113.48.101";
        User = "feniix";
        ServerAliveInterval = 10;
        ServerAliveCountMax = 3;
        TCPKeepAlive = true;
      };
    };
  };
}
