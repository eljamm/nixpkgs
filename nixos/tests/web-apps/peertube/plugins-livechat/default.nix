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
        ];

        services.peertube.plugins.packages = lib.mkForce [
          (pkgs.callPackage ../livechat.nix { })
        ];

        # Needed to get output detected by test
        services.peertube.settings.log.level = "debug";

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

      # Wait until we can get through to the instance and trigger some initial loading
      server.wait_until_succeeds("curl -Ls ${url}")

      server.wait_for_console_text("loading peertube admins and moderators")
    '';
}
