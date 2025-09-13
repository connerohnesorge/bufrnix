{
  pkgs,
  lib,
  cfg,
  ...
}:
with lib; let
  outputPath = cfg.outputPath;
  grpcOptions = cfg.options or [];
in
  if (cfg.enable or false) then {
    # Runtime dependencies for Elixir gRPC
    runtimeInputs = [
      cfg.package or pkgs.protoc-gen-elixir
    ];

    # Protoc plugin configuration for Elixir gRPC
    protocPlugins =
      [
        "--elixir_out=plugins=grpc:${outputPath}"
      ]
      ++ (optionals (grpcOptions != []) [
        "--elixir_opt=${concatStringsSep " --elixir_opt=" grpcOptions}"
      ]);

    # Initialization hook for Elixir gRPC
    initHooks = ''
      echo "Enabling Elixir gRPC generation..."
    '';

    # Code generation hook for Elixir gRPC
    generateHooks = ''
      echo "Generated Elixir gRPC services in ${outputPath}"
    '';
  } else {
    runtimeInputs = [];
    protocPlugins = [];
    initHooks = "";
    generateHooks = "";
  }