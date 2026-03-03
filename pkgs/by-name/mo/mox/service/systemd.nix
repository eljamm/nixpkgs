{
  lib,
  options,
  ...
}:
{
  config = lib.mkIf (options ? systemd) {
    services.setup.systemd.service = {
      description = "Mox Setup";
      wantedBy = [ "multi-user.target" ];
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      # TODO: name of the service varies depending on the user?
      before = [ "mox.service" ];
      serviceConfig = {
        WorkingDirectory = "/var/lib/mox";
        Type = "oneshot";
        RemainAfterExit = true;
        User = "mox";
        Group = "mox";
        # TODO: no idea who set it to always
        Restart = "no";
      };
    };

    systemd.service = {
      wantedBy = [ "multi-user.target" ];
      # TODO: name of the service varies depending on the user?
      after = [ "mox-setup.service" ];
      requires = [ "mox-setup.service" ];
      serviceConfig = {
        WorkingDirectory = "/var/lib/mox";
        Restart = "always";
      };
    };
  };
}
