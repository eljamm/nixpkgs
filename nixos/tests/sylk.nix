{
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;
in
{
  name = "systemd-lock-handler";

  nodes.machine =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      systemd.services.sylk = {
        serviceConfig = {
          DynamicUser = true;
          CacheDirectory = "sylk";
          ExecStart = "${lib.getExe pkgs.sylk-webrtc}";
          workingDirectory = pkgs.sylk-webrtc;
        };
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
      };
    };

  testScript = ''
    start_all()
  '';

  interactive.sshBackdoor.enable = true;
}
