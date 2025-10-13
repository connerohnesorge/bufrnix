{
  pkgs,
  config,
  lib,
  cfg ? config.languages.proto,
  ...
}:
with lib; let
  # Define output path and options
  outputPath = cfg.outputPath or "proto";

  # Import proto-specific sub-modules
  copierModule = import ./copier.nix {
    inherit pkgs lib;
    cfg =
      cfg.copier
      // {
        outputPath = cfg.copier.outputPath or outputPath;
      };
    config = config;
  };

  # Combine all sub-modules
  combineModuleAttrs = attr:
    concatLists (catAttrs attr [
      copierModule
    ]);
in {
  # Runtime dependencies for proto operations
  runtimeInputs =
    [
      # Base dependencies (none needed for proto copying)
    ]
    ++ (combineModuleAttrs "runtimeInputs");

  # Protoc plugin configuration for proto operations
  protocPlugins =
    [
      # Dummy protoc plugin to avoid "Missing output directives" error
      # We don't actually want protoc to generate anything, just copy files
      "--descriptor_set_out=/tmp/bufrnix-proto-dummy/descriptor.pb"
    ]
    ++ (combineModuleAttrs "protocPlugins");

  # Initialization hook for proto operations
  initHooks =
    ''
      # Create proto-specific directories
      mkdir -p "${outputPath}"
      echo "Initializing proto operations..."
      
      # Create temporary directory for dummy protoc output
      mkdir -p "/tmp/bufrnix-proto-dummy"
    ''
    + concatStrings (catAttrs "initHooks" [
      copierModule
    ])
    + (copierModule.copyInInitHooks or "");

  # Code generation hook for proto operations
  generateHooks =
    ''
      # Proto-specific operations
      echo "Starting proto operations..."
      mkdir -p ${outputPath}
    ''
    + concatStrings (catAttrs "generateHooks" [
      copierModule
    ])
    + ''
      
      # Cleanup dummy protoc output
      echo "Cleaning up temporary protoc output..."
      rm -rf "/tmp/bufrnix-proto-dummy"
    '';
}