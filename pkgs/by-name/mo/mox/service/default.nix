{
  lib,
  config,
  ...
}:
let
  cfg = config.mox;
in
{
  _class = "service";

  meta.maintainers = with lib.maintainers; [ prince213 ];

  imports = [
    ./systemd.nix
  ];

  options.mox = {
    package = lib.mkOption {
      description = "Package to use for mox";
      defaultText = "The mox package that provided this module.";
      type = lib.types.package;
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "mail";
      description = "Hostname for the Mox Mail Server";
    };
    user = lib.mkOption {
      type = lib.types.str;
      description = "*Required* Email user as (user@domain) to be created.";
    };
  };

  config = {
    process.argv = [
      (lib.getExe cfg.package)
      "-config"
      # TODO: use configData
      "/var/lib/mox/config/mox.conf"
      "serve"
    ];

    services.setup = {
      process.argv = [
        (lib.getExe cfg.package)
        "quickstart"
        "-hostname"
        cfg.hostname
        cfg.user
      ];
    };
  };
}
