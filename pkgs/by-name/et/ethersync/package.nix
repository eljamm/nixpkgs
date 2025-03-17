{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ethersync";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "ethersync";
    repo = "ethersync";
    rev = "v${finalAttrs.version}";
    hash = "sha256-dHV4+WxNdEvRZK8WNK0qp9f43Y9oSUtlXrq/mI0yWls=";
  };

  sourceRoot = "${finalAttrs.src.name}/daemon";

  useFetchCargoVendor = true;
  cargoHash = "sha256-uKtJp4RD0YbOmtzbxebpYQxlBmP+5k88d+76hT4cTI8=";

  meta = {
    description = "System for editor-agnostic, real-time collaborative editing of local text files";
    homepage = "https://github.com/ethersync/ethersync";
    changelog = "https://github.com/ethersync/ethersync/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    maintainers = lib.teams.ngi.members;
    mainProgram = "ethersync";
    platforms = lib.platforms.all;
  };
})
