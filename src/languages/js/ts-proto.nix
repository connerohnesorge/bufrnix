{
  pkgs,
  lib,
  cfg ? {},
  ...
}:
with lib;
# Only activate if ts-proto is enabled
  if cfg.enable or false
  then let
    outputPath = cfg.outputPath or "gen/js";
    tsProtoOptions = cfg.options or [];

    # Package ts-proto since it's not in nixpkgs yet
    protoc-gen-ts_proto = pkgs.buildNpmPackage rec {
      pname = "ts-proto";
      version = "1.181.1";

      src = pkgs.fetchFromGitHub {
        owner = "stephenh";
        repo = "ts-proto";
        rev = "v${version}";
        hash = "sha256-6Jvx6b1SMhGN9DNKFLvYvGrSdTXiPtz4fqnLZjjQCYI=";
      };

      npmDepsHash = "sha256-0FchqLDG6pHFB1nZ3dSvRRUzVyZqbShZPMBT8RZVz4o=";

      postInstall = ''
        # Create wrapper for protoc compatibility
        mkdir -p $out/bin
        makeWrapper $out/lib/node_modules/ts-proto/protoc-gen-ts_proto \
          $out/bin/protoc-gen-ts_proto \
          --prefix PATH : ${lib.makeBinPath [pkgs.nodejs]}
      '';

      meta = with lib; {
        description = "An idiomatic protobuf generator for TypeScript";
        homepage = "https://github.com/stephenh/ts-proto";
        license = licenses.asl20;
        maintainers = [];
      };
    };

    # Use provided package or fall back to our derivation
    tsProtoPackage = cfg.package or protoc-gen-ts_proto;

    # Default options for ts-proto
    defaultOptions = [
      "esModuleInterop=true"
      "outputServices=nice-grpc"
      "outputClientImpl=false"
      "useOptionals=messages"
      "useDate=date"
      "forceLong=string"
    ];

    # Merge default options with user options
    finalOptions =
      if tsProtoOptions == []
      then defaultOptions
      else tsProtoOptions;
  in {
    # Runtime dependencies for ts-proto code generation
    runtimeInputs = [
      tsProtoPackage
      pkgs.nodePackages.typescript
    ];

    # Protoc plugin configuration for ts-proto
    protocPlugins = [
      "--plugin=protoc-gen-ts_proto=${tsProtoPackage}/bin/protoc-gen-ts_proto"
      "--ts_proto_out=${outputPath}"
      (optionalString (finalOptions != []) "--ts_proto_opt=${concatStringsSep "," finalOptions}")
    ];

    # Initialization hook for ts-proto
    initHooks = ''
      # Create ts-proto specific directories
      mkdir -p "${outputPath}"
      echo "Initializing ts-proto code generation..."
    '';

    # Code generation hook for ts-proto
    generateHooks = ''
      # ts-proto specific generation steps
      echo "Generated ts-proto TypeScript interfaces to ${outputPath}"

      # Note: package.json should be managed by the project itself
      # Users should create their own package.json with appropriate dependencies:
      # - @grpc/grpc-js (for gRPC support)
      # - nice-grpc and nice-grpc-common (if using nice-grpc service output)
      # - typescript (for compilation)
    '';
  }
  else {}
