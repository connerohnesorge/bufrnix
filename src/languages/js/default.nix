{
  pkgs,
  config,
  lib,
  cfg ? config.languages.js,
  ...
}:
with lib; let
  # Define output path and options
  outputPath = cfg.outputPath;
  jsOptions = cfg.options;

  # Import JS-specific sub-modules
  grpcWebModule = import ./grpc-web.nix {
    inherit pkgs lib;
    cfg =
      cfg.grpcWeb
      // {
        outputPath = outputPath;
      };
  };

  twirpModule = import ./twirp.nix {
    inherit pkgs lib;
    cfg =
      cfg.twirp
      // {
        outputPath = outputPath;
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
        outputPath = outputPath;
      };
  };

  # ts-proto for TypeScript-first development
  tsProtoModule = import ./ts-proto.nix {
    inherit pkgs lib;
    cfg =
      cfg.tsProto
      // {
        outputPath = outputPath;
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
      esOptions =
        cfg.es.options
        ++ (optional (cfg.es.target != "") "target=${cfg.es.target}")
        ++ (optional (cfg.es.importExtension != "") "import_extension=${cfg.es.importExtension}");
    in [
      "--plugin=protoc-gen-es=${cfg.es.package}/bin/protoc-gen-es"
      "--es_out=${outputPath}"
      (optionalString (esOptions != []) "--es_opt=${concatStringsSep "," esOptions}")
    ]))
    ++ (optionals cfg.tsProto.enable (tsProtoModule.protocPlugins or []))
    ++ (combineModuleAttrs "protocPlugins");

  # Initialization hook for JS
  initHooks =
    ''
      # Create js-specific directories
      mkdir -p "${outputPath}"
      ${optionalString (cfg.packageName != "") ''
        echo "Creating JS package: ${cfg.packageName}"
      ''}
    ''
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

      # Generate package.json for ES modules if requested
      ${optionalString (cfg.es.enable && cfg.es.generatePackageJson) ''
                cat > ${outputPath}/package.json <<EOF
        {
          "name": "${
          if cfg.es.packageName != ""
          then cfg.es.packageName
          else "generated-protobuf-es"
        }",
          "version": "1.0.0",
          "type": "module",
          "main": "./index.js",
          "types": "./index.d.ts",
          "exports": {
            ".": {
              "import": "./index.js",
              "types": "./index.d.ts"
            },
            "./*": {
              "import": "./*.js",
              "types": "./*.d.ts"
            }
          },
          "dependencies": {
            "@bufbuild/protobuf": "^1.10.0"
          },
          "devDependencies": {
            "typescript": "^5.3.0"
          }
        }
        EOF
                echo "Generated package.json for ES modules"
      ''}
    ''
    + concatStrings (catAttrs "generateHooks" [
      grpcWebModule
      twirpModule
      protovalidateModule
      tsProtoModule
    ]);
}
