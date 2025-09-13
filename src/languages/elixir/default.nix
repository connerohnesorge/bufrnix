{
  pkgs,
  config,
  lib,
  cfg ? config.languages.elixir,
  ...
}:
with lib; let
  # Define output path and options
  outputPath = cfg.outputPath;
  elixirOptions = cfg.options;

  # Import Elixir-specific sub-modules
  grpcModule = import ./grpc.nix {
    inherit pkgs lib;
    cfg =
      (cfg.grpc or {enable = false;})
      // {
        outputPath = outputPath;
      };
  };

  validateModule = import ./validate.nix {
    inherit pkgs lib;
    cfg =
      (cfg.validate or {enable = false;})
      // {
        outputPath = outputPath;
      };
  };

  # Combine all sub-modules
  combineModuleAttrs = attr:
    concatLists (catAttrs attr [
      grpcModule
      validateModule
    ]);
in {
  # Runtime dependencies for Elixir code generation
  runtimeInputs =
    [
      cfg.package
    ]
    ++ (combineModuleAttrs "runtimeInputs");

  # Protoc plugin configuration for Elixir
  protocPlugins =
    # Only add the base plugin if gRPC is not handling it
    (if (cfg.grpc.enable or false) then [] else [
      "--elixir_out=${outputPath}"
    ])
    ++ (optionals (elixirOptions != []) [
      "--elixir_opt=${concatStringsSep " --elixir_opt=" elixirOptions}"
    ])
    ++ (combineModuleAttrs "protocPlugins");

  # Initialization hook for Elixir
  initHooks =
    ''
      # Create elixir-specific directories
      mkdir -p "${outputPath}"
      ${optionalString (cfg.namespace != "") ''
        echo "Creating Elixir modules with namespace: ${cfg.namespace}"
      ''}
    ''
    + concatStrings (catAttrs "initHooks" [
      grpcModule
      validateModule
    ]);

  # Code generation hook for Elixir
  generateHooks =
    ''
      # Elixir-specific code generation steps
      echo "Generating Elixir code..."
      mkdir -p ${outputPath}

      # Add .formatter.exs if it doesn't exist
      if [ ! -f "${outputPath}/.formatter.exs" ]; then
        cat > "${outputPath}/.formatter.exs" << 'EOF'
[
  inputs: ["*.{ex,exs}", "{lib,test}/**/*.{ex,exs}"],
  line_length: 120
]
EOF
      fi
    ''
    + concatStrings (catAttrs "generateHooks" [
      grpcModule
      validateModule
    ]);
}