{
  pkgs,
  config,
  lib,
  cfg ? config.languages.js,
  ...
}:
with lib; let
  # Define output path and options
  inherit (cfg) outputPath;
  jsOptions = cfg.options;

  # Import JS-specific sub-modules
  # Use plugin-specific outputPath if set, otherwise fall back to parent outputPath
  grpcWebModule = import ./grpc-web.nix {
    inherit pkgs lib;
    cfg =
      cfg.grpcWeb
      // {
        outputPath =
          if (cfg.grpcWeb.outputPath or null) != null
          then cfg.grpcWeb.outputPath
          else outputPath;
      };
  };

  twirpModule = import ./twirp.nix {
    inherit pkgs lib;
    cfg =
      cfg.twirp
      // {
        outputPath =
          if (cfg.twirp.outputPath or null) != null
          then cfg.twirp.outputPath
          else outputPath;
      };
  };

  # protovalidate-es support for runtime validation
  # Note: This doesn't add a separate code generator, but configures
  # protoc-gen-es to properly handle buf.validate options in proto files
  protovalidateModule = import ./protovalidate.nix {
    inherit pkgs lib;
    cfg =
      cfg.protovalidate
      // {
        inherit outputPath;
      };
  };

  # ts-proto for TypeScript-first development
  tsProtoModule = import ./ts-proto.nix {
    inherit pkgs lib;
    cfg =
      cfg.tsProto
      // {
        outputPath =
          if (cfg.tsProto.outputPath or null) != null
          then cfg.tsProto.outputPath
          else outputPath;
      };
  };

  # Combine all sub-modules
  combineModuleAttrs = attr:
    concatLists (catAttrs attr [
      grpcWebModule
      twirpModule
      protovalidateModule
      tsProtoModule
    ]);
in {
  # Runtime dependencies for JS code generation
  runtimeInputs =
    [
      # Base JS dependencies
      pkgs.protobuf
      pkgs.nodePackages.typescript
    ]
    ++ (optional (cfg.package != null) cfg.package)
    ++ (optionals cfg.es.enable [cfg.es.package])
    ++ (optionals cfg.tsProto.enable (tsProtoModule.runtimeInputs or []))
    ++ (combineModuleAttrs "runtimeInputs");

  # Protoc plugin configuration for JS
  protocPlugins =
    # Only add JS output if package is available
    (optional (cfg.package != null)
      "--js_out=import_style=commonjs,binary:${outputPath}")
    ++ (optionals cfg.es.enable (let
      esOutputPath =
        if (cfg.es.outputPath != null)
        then cfg.es.outputPath
        else outputPath;
      esOptions =
        cfg.es.options
        ++ (optional (cfg.es.target != "") "target=${cfg.es.target}")
        ++ (optional (cfg.es.importExtension != "") "import_extension=${cfg.es.importExtension}");
    in [
      "--plugin=protoc-gen-es=${cfg.es.package}/bin/protoc-gen-es"
      "--es_out=${esOutputPath}"
      (optionalString (esOptions != []) "--es_opt=${concatStringsSep "," esOptions}")
    ]))
    ++ (optionals cfg.tsProto.enable (tsProtoModule.protocPlugins or []))
    ++ (combineModuleAttrs "protocPlugins");

  # Initialization hook for JS
  initHooks =
    (let
      esOutputPath =
        if (cfg.es.outputPath != null)
        then cfg.es.outputPath
        else outputPath;
    in ''
      # Create js-specific directories
      mkdir -p "${outputPath}"
      ${optionalString cfg.es.enable ''
        mkdir -p "${esOutputPath}"
      ''}
    '')
    + concatStrings (catAttrs "initHooks" [
      grpcWebModule
      twirpModule
      protovalidateModule
    ]);

  # Code generation hook for JS
  generateHooks =
    ''
      # JS-specific code generation steps
      echo "Generating JavaScript code..."
      mkdir -p ${outputPath}
      ${optionalString (cfg.package == null && pkgs.stdenv.isDarwin) ''
        echo "Note: protoc-gen-js is not available on macOS due to build issues."
        echo "Using ES modules (protoc-gen-es) or other alternatives instead."
      ''}

      # Note: package.json should be managed by the project itself, not auto-generated.
      # Users should maintain their own package.json with appropriate dependencies
      # for their specific use case (e.g., @bufbuild/protobuf, typescript, etc.).
    ''
    + concatStrings (catAttrs "generateHooks" [
      grpcWebModule
      twirpModule
      protovalidateModule
      tsProtoModule
    ]);
}
