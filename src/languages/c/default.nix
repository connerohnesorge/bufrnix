{
  pkgs,
  config,
  lib,
  cfg ? config.languages.c,
  ...
}:
with lib; let
  inherit (cfg) outputPath;

  # Import C-specific sub-modules
  protobufCModule = import ./protobuf-c.nix {
    inherit pkgs lib;
    cfg = cfg.protobuf-c // {outputPath = "${outputPath}/protobuf-c";};
  };

  nanopbModule = import ./nanopb.nix {
    inherit pkgs lib;
    cfg = cfg.nanopb // {outputPath = "${outputPath}/nanopb";};
  };

  # Combine all sub-modules
  combineModuleAttrs = attr:
    concatLists (catAttrs attr [
      protobufCModule
      nanopbModule
    ]);
in {
  runtimeInputs = combineModuleAttrs "runtimeInputs";
  protocPlugins = combineModuleAttrs "protocPlugins";

  initHooks =
    ''
      mkdir -p "${outputPath}"
    ''
    + concatStrings (catAttrs "initHooks" [protobufCModule nanopbModule]);

  generateHooks =
    ''
      echo "Generating C code..."
    ''
    + concatStrings (catAttrs "generateHooks" [protobufCModule nanopbModule]);
}
