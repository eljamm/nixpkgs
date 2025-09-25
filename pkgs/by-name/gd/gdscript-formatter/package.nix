{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "gdscript-formatter";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "GDQuest";
    repo = "GDScript-formatter";
    tag = version;
    hash = "sha256-2xbsQUt5jfWEvhOix+WEK9rP7tb2DZ0BX35YqPpdyuc=";
  };

  cargoHash = "sha256-RqNgPEP/phhobwAl8a3sm5iaiwdTpwdJ8NtnzJPd6uQ=";

  cargoBuildFlags = [
    "--bin=gdscript-formatter"
  ];

  meta = with lib; {
    description = "A fast code formatter for GDScript and Godot 4, written in Rust";
    homepage = "https://github.com/GDQuest/GDScript-formatter";
    license = licenses.mit;
    mainProgram = "gdscript-formatter";
    maintainers = with maintainers; [ squarepear ];
  };
}
