{
  lib,
  pkgs,
  config,
  ...
}:

let
  settingsFormat = pkgs.formats.ini { };
  this = config.services.taler;
in

{
  imports = [
    # This should be in the respective modules
    ./config.nix
    ./exchange.nix
  ];

  # turn this into a generic taler-like service thingy?
  options.services.taler = {
    enable = lib.mkEnableOption "the GNU Taler system" // lib.mkOption {
      internal = true;
    };
    includes = lib.mkOption {
      type = with lib.types; listOf path;
      default = [ ];
      description = ''
        Files to include into the config file using Taler's `@inline@` directive.

        This allows including arbitrary INI files, including imperatively managed ones.
      '';
    };
    configFile = lib.mkOption {
      internal = true;
      default =
        let
          includes = pkgs.writers.writeText "includes.conf" (
            lib.concatStringsSep "\n" (map (include: "@inline@ ${include}") this.includes)
          );
          generatedConfig = settingsFormat.generate "generated-taler.conf" this.settings;
        in
        pkgs.runCommand "taler.conf" { } ''
          cat ${includes} > $out
          echo >> $out
          echo >> $out
          cat ${generatedConfig} >> $out
        '';
    };
  };

  config = lib.mkIf (this.enable) {
    environment.etc."taler/taler.conf".source = this.configFile;
  };
}
