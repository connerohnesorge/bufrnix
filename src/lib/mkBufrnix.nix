/* Bufrnix Main Derivation Builder
   This file contains the core logic for Bufrnix. It defines a function that
   takes a user's configuration and produces a Nix derivation. This derivation
   is a shell script that, when executed, runs the `protoc` compiler with all
   the necessary plugins, options, and paths for the configured languages.

   Key Responsibilities:
   - Merging user configuration with default settings.
   - Loading language-specific modules.
   - Assembling `protoc` command-line arguments.
   - Handling complex scenarios like multiple output paths per language.
   - Generating a runnable shell script (`bufrnix`) that performs the code generation.

   Type: mkBufrnix :: { pkgs, self, config } -> Derivation
*/
{
  pkgs,
  self ? null,
  config ? {},
  ...
}:
with pkgs.lib; let
  # Import shared modules: option definitions and debug utilities.
  optionsDef = import ./bufrnix-options.nix {inherit (pkgs) lib;};
  debug = import ./utils/debug.nix {inherit (pkgs) lib;};

  /* Extract default values from option definitions recursively.
  
     This function traverses the nested attribute set of option definitions
     (from `bufrnix-options.nix`) and constructs a corresponding attribute set
     containing only the `default` value for each option. This is used to build
     the base configuration before merging user-provided settings.
     
     Type: extractDefaults :: AttrSet -> AttrSet
     
     Example:
       extractDefaults { 
         foo.default = "bar"; 
         nested = { baz.default = 42; }; 
       }
       => { foo = "bar"; nested = { baz = 42; }; }
  */
  extractDefaults = options:
    if isOption options
    then options.default or null
    else if isAttrs options
    then mapAttrs (_: extractDefaults) options
    else options;

  /* Compute the final list of proto files for a specific language.
     
     This function determines which proto files should be compiled for a given
     language. It prioritizes the language-specific `files` list if it is defined.
     If not, it falls back to the global `protoc.files`. In both cases, it appends
     any `additionalFiles` specified for the language.
     
     Type: getFilesForLanguage :: String -> AttrSet -> AttrSet -> [String]
     
     Args:
       langName: The name of the language (e.g., "go", "js").
       langConfig: The configuration for the specific language (e.g., `cfg.languages.go`).
       cfg: The full, merged bufrnix configuration.
       
     Returns: A list of absolute paths to proto files.
  */
  getFilesForLanguage = langName: langConfig: cfg:
    let
      baseFiles = if langConfig.files != null
                  then langConfig.files
                  else cfg.protoc.files;
      allFiles = baseFiles ++ langConfig.additionalFiles;
    in allFiles;

  # `defaultConfig`: The base configuration created from the default values in `bufrnix-options.nix`.
  defaultConfig = extractDefaults optionsDef.options;

  # `jsPackage`: A special case for `protoc-gen-js`.
  # There are known build issues on macOS (Darwin), so we set its package to `null`
  # on that platform to avoid build failures. The user can override this if needed.
  jsPackage =
    if pkgs.stdenv.isDarwin
    then null
    else pkgs.protoc-gen-js;

  # `packageDefaults`: Defines the default Nix package for each protoc plugin.
  # This provides a sensible default for every supported plugin, which users can override
  # in their configuration if they need a specific version or a custom package.
  packageDefaults = {
    languages = {
      go = {
        package = pkgs.protoc-gen-go;
        grpc.package = pkgs.protoc-gen-go-grpc;
        gateway.package = pkgs.grpc-gateway;
        validate.package = pkgs.protoc-gen-validate;
        connect.package = pkgs.protoc-gen-connect-go;
        protovalidate.package = pkgs.protovalidate-go or null; # Not yet in nixpkgs
        openapiv2.package = pkgs.protoc-gen-openapiv2 or (pkgs.callPackage ../packages/protoc-gen-openapiv2 {});
        vtprotobuf.package = pkgs.protoc-gen-go-vtproto or (pkgs.callPackage ../packages/protoc-gen-go-vtproto {});
        json.package = pkgs.protoc-gen-go-json or (pkgs.callPackage ../packages/protoc-gen-go-json {});
        federation.package = pkgs.protoc-gen-grpc-federation or null; # Not yet in nixpkgs
        structTransformer.package = pkgs.protoc-gen-struct-transformer or (pkgs.callPackage ../languages/go/protoc-gen-struct-transformer.nix {});
      };
      php = {
        package = pkgs.protobuf;
        twirp.package = pkgs.protoc-gen-twirp_php;
      };
      js = {
        package = jsPackage;
        es.package = pkgs.protoc-gen-es;
        connect.package = pkgs.protoc-gen-connect-es;
        grpcWeb.package = pkgs.protoc-gen-grpc-web;
        twirp.package = pkgs.protoc-gen-twirp_js;
      };
      dart = {
        package = pkgs.protoc-gen-dart;
        grpc.package = pkgs.protoc-gen-dart;
      };
      elixir = {
        package = pkgs.protoc-gen-elixir;
        grpc.package = pkgs.protoc-gen-elixir;
        validate.package = null; # Not yet in nixpkgs
      };
      doc = {
        package = pkgs.protoc-gen-doc;
      };
      python = {
        package = pkgs.protobuf;
        grpc.package = pkgs.python3Packages.grpcio-tools;
        pyi.package = pkgs.protobuf;
        betterproto.package = pkgs.callPackage ../packages/betterproto {};
        mypy.package = pkgs.python3Packages.mypy-protobuf;
      };
      swift = {
        package = pkgs.protoc-gen-swift;
      };
      c = {
        protobuf-c.package = pkgs.protobufc;
        nanopb.package = pkgs.nanopb;
      };
      csharp = {
        sdk = pkgs.dotnetCorePackages.sdk_8_0;
      };
      java = {
        package = pkgs.protobuf;
        jdk = pkgs.jdk17;
        grpc.package = pkgs.callPackage ../packages/grpc-java {};
        protovalidate.package = pkgs.callPackage ../packages/protoc-gen-validate-java {};
      };
      kotlin = {
        jdk = pkgs.jdk17;
      };
      cpp = {
        package = pkgs.protobuf;
        grpc.package = pkgs.grpc;
        nanopb.package = pkgs.nanopb;
        protobuf-c.package = pkgs.protobufc;
      };
      svg = {
        package = pkgs.protoc-gen-d2 or null; # Will need to be provided by user until in nixpkgs
      };
      scala = {
        package = pkgs.callPackage ../packages/scalapb {};
      };
    };
  };

  # `cfg`: The final, merged configuration.
  # This is the single source of truth for the build script. It is created by
  # recursively merging the `defaultConfig`, `packageDefaults`, and the user-provided `config`.
  # The user's configuration takes precedence.
  cfg = recursiveUpdate (recursiveUpdate defaultConfig packageDefaults) config;

  /* Normalize a language's output path to a list of strings.
  
     Bufrnix allows `outputPath` to be a single string or a list of strings.
     This function ensures that the path is always a list, simplifying iteration
     and processing in the rest of the script.
     
     Type: normalizeOutputPath :: (String | [String]) -> [String]
     
     Example:
       normalizeOutputPath "gen/go" => ["gen/go"]
       normalizeOutputPath ["gen/go", "pkg/proto"] => ["gen/go", "pkg/proto"]
  */
  normalizeOutputPath = path:
    if builtins.isList path
    then path
    else [path];

  # `languageNames`: A list of all available languages defined in the configuration.
  languageNames = attrNames cfg.languages;

  /* Load a language module if it is enabled in the configuration.
  
     This function dynamically imports and instantiates a language module (from `../languages/`)
     if `cfg.languages.<language>.enable` is true. The module is passed the full
     configuration, allowing it to generate the correct `protoc` plugins, runtime inputs,
     and shell hooks based on the user's settings.
     
     Type: loadLanguageModule :: String -> AttrSet
     
     Example:
       loadLanguageModule "go" 
       => { runtimeInputs = [pkgs.protoc-gen-go]; protocPlugins = ["--go_out=."]; ... }
  */
  loadLanguageModule = language:
    if cfg.languages.${language}.enable
    then
      import ../languages/${language}
      {
        inherit pkgs;
        inherit (pkgs) lib;
        config = cfg;
        cfg = cfg.languages.${language};
      }
    else {};

  # `loadedLanguageModulesForInputs`: A list of all enabled language modules.
  # This list is specifically created to aggregate the `runtimeInputs` from all
  # enabled languages. `runtimeInputs` are needed globally for the top-level
  # shell derivation, so we collect them here before handling path-specific logic.
  # We normalize the output path to a single path to avoid module evaluation errors.
  loadedLanguageModulesForInputs =
    map (
      language:
        if cfg.languages.${language}.enable
        then let
          langCfg = cfg.languages.${language};
          # Normalize to a single path just for this extraction.
          normalizedLangCfg =
            langCfg
            // {
              outputPath =
                if builtins.isList langCfg.outputPath
                then builtins.head langCfg.outputPath
                else langCfg.outputPath;
            };
        in
          import ../languages/${language} {
            inherit pkgs;
            inherit (pkgs) lib;
            config = cfg;
            cfg = normalizedLangCfg;
          }
        else {}
    )
    languageNames;

  # `languageRuntimeInputs`: The flattened list of all Nix packages required at runtime.
  # This is created by concatenating the `runtimeInputs` from all modules loaded above.
  languageRuntimeInputs = concatMap (module: module.runtimeInputs or []) loadedLanguageModulesForInputs;

  /* Generate the full command structure for all enabled languages and output paths.
  
     This is a critical function that orchestrates the generation process. It iterates
     through each enabled language and each of its configured `outputPaths`. For each
     combination, it re-evaluates the language module with a modified configuration
     specific to that path. This allows hooks and plugins to be tailored to each
     output directory.
     
     Returns: A list of language command objects.
     Type: `[{ language :: String; commands :: [{ outputPath, runtimeInputs, ... }]; }]`
     
     Example Return Structure:
       [
         { language = "go"; commands = [ { outputPath = "gen/go"; ... } ]; }
         { language = "js"; commands = [ { outputPath = "web/src"; ... }, { outputPath = "api/src"; ... } ]; }
       ]
  */
  generateProtocCommands = let
    enabledLanguages = filter (lang: cfg.languages.${lang}.enable) languageNames;

    # For each enabled language, generate a list of commands for its output paths.
    languageCommands =
      map (
        language: let
          langCfg = cfg.languages.${language};
          outputPaths = normalizeOutputPath langCfg.outputPath;

          # Generate a command object for each unique output path.
          pathCommands =
            map (
              outputPath: let
                # Create a temporary, modified config with just this single output path.
                # This ensures the language module generates hooks and plugins correctly for this path.
                modifiedLangCfg = langCfg // {outputPath = outputPath;};
                modifiedCfg =
                  cfg
                  // {
                    languages =
                      cfg.languages
                      // {
                        ${language} = modifiedLangCfg;
                      };
                  };

                # Load the language module with the path-specific configuration.
                modifiedModule = import ../languages/${language} {
                  inherit pkgs;
                  inherit (pkgs) lib;
                  config = modifiedCfg;
                  cfg = modifiedLangCfg;
                };
              in {
                # Collect all the outputs from the module for this path.
                inherit outputPath;
                runtimeInputs = modifiedModule.runtimeInputs or [];
                protocPlugins = modifiedModule.protocPlugins or [];
                initHooks = modifiedModule.initHooks or "";
                generateHooks = modifiedModule.generateHooks or "";
              }
            )
            outputPaths;
        in {
          inherit language;
          commands = pathCommands;
        }
      )
      enabledLanguages;
  in
    languageCommands;
in
  # The final output: a shell application derivation named "bufrnix".
  pkgs.writeShellApplication {
    name = "bufrnix";

    # All required packages (protoc, plugins, etc.) are added to the runtime environment.
    runtimeInputs = with pkgs;
      [
        bash
        protobuf
      ]
      ++ languageRuntimeInputs;

    # The core of the derivation: the generated shell script.
    text = ''
      # --- Bufrnix Generation Script ---

      ${debug.log 1 "Starting code generation with per-language file support" cfg}

      # --- Initial Setup ---
      protoc_cmd="${pkgs.protobuf}/bin/protoc"
      base_protoc_args="-I ${concatStringsSep " -I " cfg.protoc.includeDirectories}"

      # --- Special Handlers ---
      # Handle `.options` files for nanopb if it's enabled for the C language.
      nanopb_opts=""
      ${optionalString (cfg.languages.c.enable && cfg.languages.c.nanopb.enable) ''
        # Find a nanopb options file and add it to the protoc arguments.
        options_file=$(find . -name "*.options" -type f 2>/dev/null | head -1)
        if [ -n "$options_file" ]; then
          echo "Found nanopb options file: $options_file"
          nanopb_opts="--nanopb_opt=-f$options_file"
        fi
      ''}

      # --- Main Generation Loop ---
      # This section is generated by Nix by iterating over the `generateProtocCommands` structure.
      # It creates a block of shell code for each language and each output path.
      ${concatMapStrings (
          langCmd:
            concatMapStrings (pathCmd: ''
              # Generating for language: ${langCmd.language}, Path: ${pathCmd.outputPath}
              echo "Generating ${langCmd.language} code for output path: ${pathCmd.outputPath}"

              # Step 1: Compute the list of .proto files for this specific language.
              lang_proto_files=""
              ${
                let
                  langConfig = cfg.languages.${langCmd.language};
                  languageFiles = getFilesForLanguage langCmd.language langConfig cfg;
                in
                  # If the file list is empty, find all .proto files in the source directories.
                  if (languageFiles == [])
                  then
                    if (cfg.protoc.sourceDirectories == [])
                    then ''
                      # Fallback to finding all proto files from the configured root.
                      lang_proto_files=$(find "${cfg.root}" -name "*.proto" -type f)
                    ''
                    else ''
                      # Find proto files from the specified source directories.
                      ${concatMapStrings (dir: ''
                          lang_proto_files="$lang_proto_files $(find "${dir}" -name "*.proto" -type f)"
                        '')
                        cfg.protoc.sourceDirectories}
                    ''
                  else ''
                    # Use the specific list of files computed for this language.
                    lang_proto_files="${concatStringsSep " " languageFiles}"
                  ''
              }

              echo "Proto files for ${langCmd.language}: $lang_proto_files"

              # Step 2: Run pre-generation hooks for this path.
              ${pathCmd.initHooks}

              # Step 3: Ensure the output directory exists.
              mkdir -p "${pathCmd.outputPath}"

              # Step 4: Build the full protoc command with all plugins for this path.
              protoc_args="$base_protoc_args $nanopb_opts"
              ${concatMapStrings (plugin: ''
                  protoc_args="$protoc_args ${plugin}"
                '')
                pathCmd.protocPlugins}

              # Step 5: Execute the protoc compiler.
              eval "$protoc_cmd $protoc_args $lang_proto_files"

              # Step 6: Run post-generation hooks for this path.
              ${pathCmd.generateHooks}

            '')
            langCmd.commands
        )
        generateProtocCommands}

      ${debug.log 1 "Multiple output path code generation completed successfully" cfg}
    '';
  }
