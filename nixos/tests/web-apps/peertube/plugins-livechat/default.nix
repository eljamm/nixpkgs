{
  sources,
  pkgs,
  lib,
  ...
}:
{
  name = "peertube-plugin-livechat";

  nodes = {
    server =
      { config, ... }:
      {
        imports = [
          ../config.nix

          # enable graphical session + users (alice, bob)
          ../../../common/x11.nix
          ../../../common/user-account.nix
        ];

        services.peertube.plugins.packages = lib.mkForce [
          (pkgs.callPackage ../livechat.nix { })
        ];

        test-support.displayManager.auto.user = "alice";

        # Needed to get output detected by test
        # services.peertube.settings.log.level = "debug";

        boot.kernelPackages = pkgs.linuxPackages_latest;
      };
  };

  testScript =
    { nodes, ... }:
    let
      cfg = nodes.server.services.peertube;
      url = "http://${cfg.localDomain}:${toString cfg.listenWeb}";
    in
    # py
    ''
      start_all()

      #server.wait_for_console_text("Linking plugin: peertube-plugin-livechat")

      # Wait until we can get through to the instance and trigger some initial loading
      server.wait_until_succeeds("curl -Ls ${url}")
    '';

  interactive.sshBackdoor.enable = true;
  interactive.nodes.server = {
    environment.systemPackages = with pkgs; [
      chromium
    ];

    # forward ports from VM to host
    virtualisation.forwardPorts =
      lib.mapAttrsToList
        (_: port: {
          from = "host";
          host = { inherit port; };
          guest = { inherit port; };
        })
        {
          peertube = 9000;
        };
  };
}
