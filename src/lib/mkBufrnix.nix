{
  pkgs,
  self ? null,
  config ? {},
  ...
}:
with pkgs.lib; let
  # Import our modules
  optionsDef = import ./bufrnix-options.nix {inherit (pkgs) lib;};
  debug = import ./utils/debug.nix {inherit (pkgs) lib;};

  /* Extract default values from option definitions recursively.
  
     This function traverses option definitions and extracts their default values,
     handling both simple options and nested attribute sets of options.
     
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

  /* Compute proto files for a specific language
     
     This function determines which proto files should be compiled for a given language
     by checking the language's files and additionalFiles configuration.
     
     Type: getFilesForLanguage :: String -> AttrSet -> Config -> [String]
     
     Args:
       - langName: The name of the language (e.g., "go", "js", "python")
       - langConfig: The language configuration from cfg.languages.<lang>
       - cfg: The full bufrnix configuration
       
     Returns:
       - List of proto files to compile for this language
       
     Logic:
       - If langConfig.files is not null: use langConfig.files + langConfig.additionalFiles
       - If langConfig.files is null: use cfg.protoc.files + langConfig.additionalFiles
  */
  getFilesForLanguage = langName: langConfig: cfg:
    let
      baseFiles = if langConfig.files != null
                  then langConfig.files
                  else cfg.protoc.files;
      allFiles = baseFiles ++ langConfig.additionalFiles;
    in allFiles;

  defaultConfig = extractDefaults optionsDef.options;

  # Add package defaults
  # For protoc-gen-js on macOS, we have build issues
  # Set to null on Darwin to avoid build failures
  jsPackage =
    if pkgs.stdenv.isDarwin
    then null
    else pkgs.protoc-gen-js;

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
        # connect.package removed - Connect functionality integrated into protoc-gen-es v2
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
      proto = {
        # Proto operations don't need special packages - just coreutils
        # Package defaults are handled by the copier sub-module
      };
    };
  };

  # Merge defaults with user config
  cfg = recursiveUpdate (recursiveUpdate defaultConfig packageDefaults) config;

  /* Normalize output path from string or array to consistent array format.
  
     Bufrnix supports both single output paths (as strings) and multiple output paths
     (as arrays) for each language. This function ensures all paths are represented
     as arrays for consistent processing.
     
     Type: normalizeOutputPath :: (String | [String]) -> [String]
     
     Example:
       normalizeOutputPath "gen/go" => ["gen/go"]
       normalizeOutputPath ["gen/go", "pkg/proto"] => ["gen/go", "pkg/proto"]
  */
  normalizeOutputPath = path:
    if builtins.isList path
    then path
    else [path];

  # Load language modules based on configuration
  languageNames = attrNames cfg.languages;

  /* Load a language module if enabled in the configuration.
  
     Conditionally imports and instantiates a language module based on whether
     the language is enabled in the configuration. Language modules provide
     protoc plugins, runtime inputs, and generation hooks.
     
     Type: loadLanguageModule :: String -> AttrSet
     
     Example:
       loadLanguageModule "go" 
       => { runtimeInputs = [protoc-gen-go]; protocPlugins = ["--go_out=."]; ... }
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

  # Load all enabled language modules for extracting runtime inputs only
  # We need runtime inputs globally, but hooks will be handled per output path
  loadedLanguageModulesForInputs =
    map (
      language:
        if cfg.languages.${language}.enable
        then let
          langCfg = cfg.languages.${language};
          # Normalize to single path for runtime input extraction
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

  # Extract runtime inputs from language modules
  languageRuntimeInputs = concatMap (module: module.runtimeInputs or []) loadedLanguageModulesForInputs;

  /* Generate protoc commands for each enabled language with multiple output paths.
  
     This function creates the command structure for protoc code generation across
     all enabled languages and their configured output paths. It handles multi-output
     scenarios where a single language can generate code to multiple directories.
     
     Returns a list of language command objects, each containing:
     - language: The language name
     - commands: List of path-specific command objects with:
       * outputPath: Target directory for generated code
       * runtimeInputs: Required packages for generation
       * protocPlugins: protoc command-line plugin arguments
       * initHooks: Shell commands run before generation
       * generateHooks: Shell commands run after generation
     
     Type: generateProtocCommands :: [{ language :: String; commands :: [Command]; }]
  */
  generateProtocCommands = let
    enabledLanguages = filter (lang: cfg.languages.${lang}.enable) languageNames;

    # For each enabled language, get the normalized output paths and generate commands
    languageCommands =
      map (
        language: let
          langCfg = cfg.languages.${language};
          module = loadLanguageModule language;
          outputPaths = normalizeOutputPath langCfg.outputPath;

          # Generate a command for each output path
          pathCommands =
            map (
              outputPath: let
                # Create modified cfg with single outputPath for this iteration
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

                # Load module with modified config
                modifiedModule = import ../languages/${language} {
                  inherit pkgs;
                  inherit (pkgs) lib;
                  config = modifiedCfg;
                  cfg = modifiedLangCfg;
                };
              in {
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
  pkgs.writeShellApplication {
    name = "bufrnix";

    runtimeInputs = with pkgs;
      [
        bash
        protobuf
      ]
      ++ languageRuntimeInputs;

    text = ''
      ${debug.log 1 "Starting code generation with per-language file support" cfg}

      protoc_cmd="${pkgs.protobuf}/bin/protoc"
      base_protoc_args="-I ${concatStringsSep " -I " cfg.protoc.includeDirectories}"

      # Handle nanopb options files if nanopb is enabled
      nanopb_opts=""
      ${optionalString (cfg.languages.c.enable && cfg.languages.c.nanopb.enable) ''
        # Find nanopb options files and add them to protoc_args
        options_file=$(find . -name "*.options" -type f 2>/dev/null | head -1)
        if [ -n "$options_file" ]; then
          nanopb_opts="--nanopb_opt=-f$options_file"
        fi
      ''}

      # Generate protoc commands for each unique output path combination
      ${concatMapStrings (
          langCmd:
            concatMapStrings (pathCmd: ''
              # Compute proto files for this specific language
              lang_proto_files=""
              ${
                let
                  # Get the language configuration
                  langConfig = cfg.languages.${langCmd.language};
                  # Compute files for this language
                  languageFiles = getFilesForLanguage langCmd.language langConfig cfg;
                in
                  if (languageFiles == [])
                  then
                    # Fallback to finding files from source directories
                    if (cfg.protoc.sourceDirectories == [])
                    then ''
                      # Find all proto files from root
                      lang_proto_files=$(find "${cfg.root}" -name "*.proto" -type f)
                    ''
                    else ''
                      # Find proto files from specified directories
                      ${concatMapStrings (dir: ''
                          lang_proto_files="$lang_proto_files $(find "${dir}" -name "*.proto" -type f)"
                        '')
                        cfg.protoc.sourceDirectories}
                    ''
                  else ''
                    # Use computed language-specific files
                    lang_proto_files="${concatStringsSep " " languageFiles}"
                  ''
              }

              # Run initialization hooks for this path
              ${pathCmd.initHooks}

              # Create directory for this output path
              mkdir -p "${pathCmd.outputPath}"

              # Build protoc command for this specific output path
              protoc_args="$base_protoc_args $nanopb_opts"
              ${concatMapStrings (plugin: ''
                  protoc_args="$protoc_args ${plugin}"
                '')
                pathCmd.protocPlugins}

              # Execute protoc for this output path with language-specific files
              eval "$protoc_cmd $protoc_args $lang_proto_files"

              # Run generation hooks for this path
              ${pathCmd.generateHooks}

            '')
            langCmd.commands
        )
        generateProtocCommands}

      ${debug.log 1 "Multiple output path code generation completed successfully" cfg}

      # Execute post-generation hooks if configured
      ${optionalString (cfg.hooks.postGeneration != "") ''
        ${debug.log 1 "Executing post-generation hooks..." cfg}

        # Set environment variables for hooks
        export BUFRNIX_ROOT="${cfg.root}"
        export BUFRNIX_ENABLED_LANGUAGES="${concatStringsSep " " (filter (lang: cfg.languages.${lang}.enable) languageNames)}"
        export BUFRNIX_DEBUG_ENABLE="${if cfg.debug.enable then "true" else "false"}"
        export BUFRNIX_DEBUG_VERBOSITY="${toString cfg.debug.verbosity}"

        # Execute post-generation hooks
        echo "🚀 Running post-generation hooks..."
        ${cfg.hooks.postGeneration}
        echo "✅ Post-generation hooks completed successfully"
        ${debug.log 1 "Post-generation hooks completed successfully" cfg}
      ''}
    '';
  }
