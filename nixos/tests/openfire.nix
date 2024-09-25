import ./make-test-python.nix (
  { pkgs, ... }:
  {
    name = "openfire";
    meta = {
      maintainers = [ ];
    };

    nodes = {
      server =
        { config, ... }:
        {
          services.openfire-server = {
            enable = true;
            openFirewall = true;
          };

          services.openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "yes";
              PermitEmptyPasswords = "yes";
            };
          };
          security.pam.services.sshd.allowNullPassword = true;
          virtualisation.forwardPorts = [
            {
              from = "host";
              host.port = 2222;
              guest.port = 22;
            }
            {
              from = "host";
              host.port = 9090;
              guest.port = 9090;
            }
            {
              from = "host";
              host.port = 9091;
              guest.port = 9091;
            }
          ];
        };
    };

    testScript = ''
      start_all()
      server.wait_for_unit("openfire-server.service")
      server.wait_for_open_port(9090)

      breakpoint()
    '';
  }
)
