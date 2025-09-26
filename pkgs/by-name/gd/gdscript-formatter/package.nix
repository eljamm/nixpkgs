{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "gdscript-formatter";
  version = "0.9.1";

  src = fetchFromGitHub {
    owner = "eljamm";
    repo = "GDScript-formatter";
    rev = "b394f9a47a85cd68051e6a1360f6ce0b97e9ed8d";
    hash = "sha256-5nKXs1aY54pYtWAYYzlhxE+5rGxMv02/Cxm2NeioVTs=";
  };

  cargoHash = "sha256-MGN/l12UOOkMYhowDM3hQfqouEmDCzUosNwKtvTIzx8=";

  cargoBuildFlags = [
    "--bin=gdscript-formatter"
  ];

  meta = {
    description = "A fast code formatter for GDScript and Godot 4, written in Rust";
    homepage = "https://github.com/GDQuest/GDScript-formatter";
    license = lib.licenses.mit;
    mainProgram = "gdscript-formatter";
    maintainers = with lib.maintainers; [ squarepear ];
  };
})
