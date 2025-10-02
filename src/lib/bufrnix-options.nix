/* Bufrnix Configuration Options Schema
   This file defines the complete, type-safe configuration schema for Bufrnix
   using Nix's module system options. Every configurable parameter is defined
   here with a type, a default value, and a description. This ensures that user
   configurations are validated, and it serves as the primary source of truth
   for all available settings.

   The schema covers:
   - Core project settings (e.g., proto file locations).
   - Debugging and logging controls.
   - `protoc` compiler settings.
   - A comprehensive set of options for each supported programming language.
   - Nested options for language-specific plugins (e.g., gRPC, validation).

   This structured approach provides a robust and maintainable way to manage
   the complexity of multi-language Protocol Buffer generation.
   
   Type: BufrnixOptions :: { lib, ... } -> { options :: AttrSet; }
*/
{lib, ...}:
with lib; {
  options = {
    # --- Root Configuration ---
    # `root`: The primary directory where your `.proto` files are located.
    # This path is used as the base for discovering proto files when `protoc.files` is empty.
    root = mkOption {
      type = types.str;
      default = "./proto";
      description = "The root directory where `.proto` source files are located. This is the primary search path.";
    };

    # --- Debugging ---
    # `debug`: A set of options to control debugging and logging output.
    # Useful for troubleshooting the code generation process.
    debug = {
      # `debug.enable`: Master switch to turn on debugging.
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable or disable all debug logging. Can be overridden by the `BUFRNIX_DEBUG` environment variable.";
      };

      # `debug.verbosity`: Controls the level of detail in logs.
      # 1 (INFO): High-level status messages.
      # 2 (DEBUG): Detailed execution flow and commands.
      # 3 (TRACE): Fine-grained performance timing.
      verbosity = mkOption {
        type = types.int;
        default = 1;
        description = "Sets the debug verbosity level (1=INFO, 2=DEBUG, 3=TRACE). Higher levels include more detail.";
      };

      # `debug.logFile`: Redirects debug output to a file instead of stderr.
      logFile = mkOption {
        type = types.str;
        default = "";
        description = "Path to a file for debug logs. If empty, logs are printed to stderr.";
      };
    };

    # --- Protoc Compiler Settings ---
    # `protoc`: Configuration for the Protocol Buffer compiler itself.
    protoc = {
      # `protoc.sourceDirectories`: Directories to search for `.proto` files to compile.
      sourceDirectories = mkOption {
        type = types.listOf types.str;
        default = ["./proto"];
        description = "A list of directories to search for `.proto` files to compile.";
      };

      # `protoc.includeDirectories`: Directories passed to `protoc` with the `-I` flag.
      # This is crucial for resolving `import` statements in your proto files.
      includeDirectories = mkOption {
        type = types.listOf types.str;
        default = ["./proto"];
        description = "A list of directories to add to the `protoc` include path (`-I`). Necessary for resolving imports.";
      };

      # `protoc.files`: A specific list of `.proto` files to compile.
      # If this is empty, Bufrnix will compile all `.proto` files found in `sourceDirectories`.
      files = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "An explicit list of `.proto` files to compile. If empty, all `.proto` files in `sourceDirectories` will be used.";
      };
    };

    # --- Language-Specific Configurations ---
    # `languages`: A container for all language-specific settings.
    # Each attribute under `languages` corresponds to a programming language (e.g., `go`, `python`).
    languages = {
      # --- Go Language Options ---
      # `languages.go`: Configuration for generating Go code.
      go = {
        # `go.enable`: Enables code generation for Go.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the Go language.";
        };

        # `go.package`: The Nix package that provides the `protoc-gen-go` compiler plugin.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.protoc-gen-go";
          description = "The Nix package for the core `protoc-gen-go` plugin.";
        };

        # `go.files`: A language-specific list of `.proto` files to compile.
        # This overrides the global `protoc.files` setting for this language only.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for Go. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/internal/v1/user_service.proto"
            "./proto/common/v1/types.proto"
          ];
        };

        # `go.additionalFiles`: Extra `.proto` files to compile for this language.
        # These are appended to the main list of files being compiled.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for Go, appended to the main file list.";
          example = [
            "./proto/google/grpc/gateway/protoc-gen-openapiv2/options/annotations.proto"
            "./proto/buf/validate/validate.proto"
          ];
        };

        # `go.outputPath`: The directory (or directories) where generated Go files will be placed.
        # Can be a single string or a list of strings for multiple output locations.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/go";
          description = "The output directory or directories for the generated Go code.";
          example = literalExpression ''
            [
              "gen/go"
              "pkg/proto"
              "internal/shared/proto"
            ]
          '';
        };

        # `go.options`: A list of command-line options passed directly to the `protoc-gen-go` plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = ["paths=source_relative"];
          description = "A list of strings representing command-line options for `protoc-gen-go`.";
        };

        # `go.packagePrefix`: A prefix to prepend to the `go_package` option in generated files.
        # Useful for monorepos or complex project structures.
        packagePrefix = mkOption {
          type = types.str;
          default = "";
          description = "A prefix to apply to the Go package path for all generated files.";
        };

        # `go.plugins`: A list of plugins to enable from the Buf Schema Registry.
        # This is a higher-level abstraction for managing plugins.
        plugins = mkOption {
          type = types.listOf (types.either types.str (types.attrsOf types.anything));
          default = [];
          example = literalExpression ''
            [
              "buf.build/protocolbuffers/go",
              {
                plugin = "buf.build/community/planetscale-vtprotobuf";
                opt = ["features=marshal+unmarshal+size+pool"];
              }
            ]
          '';
          description = ''
            A list of Go plugins to enable from the Buf Schema Registry.
            Can be a simple string for default options or an attribute set
            with `plugin` and `opt` fields for customization.
          '';
        };

        # --- Go gRPC Plugin ---
        # `go.grpc`: Configuration for the standard Go gRPC plugin.
        grpc = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable gRPC service and client code generation for Go.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-go-grpc";
            description = "The Nix package for the `protoc-gen-go-grpc` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = ["paths=source_relative"];
            description = "A list of command-line options for `protoc-gen-go-grpc`.";
          };
        };

        # --- Go gRPC-Gateway Plugin ---
        # `go.gateway`: Generates a reverse-proxy server that translates a RESTful JSON API into gRPC.
        gateway = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable gRPC-Gateway (REST/JSON to gRPC proxy) code generation for Go.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.grpc-gateway";
            description = "The Nix package for the `protoc-gen-grpc-gateway` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = ["paths=source_relative"];
            description = "A list of command-line options for `protoc-gen-grpc-gateway`.";
          };
        };

        # --- Go Validation Plugin (protoc-gen-validate) ---
        # `go.validate`: Generates validation logic for protobuf messages (legacy).
        validate = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable message validation code generation using the legacy `protoc-gen-validate` for Go.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-validate";
            description = "The Nix package for the `protoc-gen-validate` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = ["lang=go"];
            description = "A list of command-line options for `protoc-gen-validate`.";
          };
        };

        # --- Go Connect RPC Plugin ---
        # `go.connect`: Generates code for the Connect RPC framework, a modern alternative to gRPC.
        connect = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation for the Connect RPC framework for Go.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-connect-go";
            description = "The Nix package for the `protoc-gen-connect-go` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = ["paths=source_relative"];
            description = "A list of command-line options for `protoc-gen-connect-go`.";
          };
        };

        # --- Go Protovalidate Plugin ---
        # `go.protovalidate`: Modern, CEL-based validation framework.
        protovalidate = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable modern, CEL-based message validation with `protovalidate-go`.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protovalidate-go";
            description = "The Nix package for the `protovalidate-go` plugin.";
          };
        };

        # --- Go OpenAPIv2 Plugin ---
        # `go.openapiv2`: Generates OpenAPI v2 (Swagger) documentation from your protobuf definitions.
        openapiv2 = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable generation of OpenAPI v2 (Swagger) documentation from protobuf services.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-openapiv2";
            description = "The Nix package for the `protoc-gen-openapiv2` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = ["logtostderr=true"];
            description = "A list of command-line options for `protoc-gen-openapiv2`.";
          };
        };

        # --- Go vtprotobuf Plugin ---
        # `go.vtprotobuf`: A high-performance protobuf plugin for Go.
        vtprotobuf = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable high-performance serialization code generation with `vtprotobuf`.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-go-vtproto";
            description = "The Nix package for the `protoc-gen-go-vtproto` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = ["paths=source_relative" "features=marshal+unmarshal+size"];
            description = "A list of command-line options for `protoc-gen-go-vtproto`.";
          };
        };

        # --- Go JSON Plugin ---
        # `go.json`: Generates `MarshalJSON` and `UnmarshalJSON` methods for better integration with Go's `encoding/json`.
        json = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable generation of `MarshalJSON` and `UnmarshalJSON` methods for standard Go JSON integration.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-go-json";
            description = "The Nix package for the `protoc-gen-go-json` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = ["paths=source_relative" "orig_name=true"];
            description = "A list of command-line options for `protoc-gen-go-json`.";
          };
        };

        # --- Go gRPC Federation Plugin ---
        # `go.federation`: An experimental plugin for building a BFF (Backend-for-Frontend) layer.
        federation = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable experimental gRPC Federation for generating BFF servers.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-grpc-federation";
            description = "The Nix package for the `protoc-gen-grpc-federation` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = ["paths=source_relative"];
            description = "A list of command-line options for `protoc-gen-grpc-federation`.";
          };
        };

        # --- Go Struct Transformer Plugin ---
        # `go.structTransformer`: Generates functions to transform data between protobuf messages and Go business logic structs.
        structTransformer = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable generation of transformation functions between protobuf messages and Go business structs.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-struct-transformer";
            description = "The Nix package for the `protoc-gen-struct-transformer` plugin.";
          };

          goRepoPackage = mkOption {
            type = types.str;
            default = "models";
            description = "The Go package name of your business logic models.";
          };

          goProtobufPackage = mkOption {
            type = types.str;
            default = "proto";
            description = "The Go package name of your generated protobuf code.";
          };

          goModelsFilePath = mkOption {
            type = types.str;
            default = "models/models.go";
            description = "The file path containing your business logic Go struct definitions.";
          };

          outputPackage = mkOption {
            type = types.str;
            default = "transform";
            description = "The package name for the generated transformation functions.";
          };
        };
      };

      # --- C++ Language Options ---
      # `languages.cpp`: Configuration for generating C++ code.
      cpp = {
        # `cpp.enable`: Enables code generation for C++.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the C++ language.";
        };

        # `cpp.package`: The Nix package that provides the C++ `protoc` plugin.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.protobuf";
          description = "The Nix package for the core `protoc` C++ plugin.";
        };

        # `cpp.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for C++. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/internal/v1/service.proto"
            "./proto/common/v1/types.proto"
          ];
        };

        # `cpp.additionalFiles`: Extra `.proto` files for C++.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for C++, appended to the main file list.";
          example = [
            "./proto/buf/validate/validate.proto"
          ];
        };

        # `cpp.protobufVersion`: The version of the Protobuf library to use.
        protobufVersion = mkOption {
          type = types.enum ["3.21" "3.25" "3.27" "4.25" "5.29" "latest"];
          default = "latest";
          description = "The version of the Protocol Buffers library to use for C++ generation.";
        };

        # `cpp.outputPath`: The directory for generated C++ files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/cpp";
          description = "The output directory or directories for the generated C++ code.";
          example = literalExpression ''
            [
              "gen/cpp"
              "src/proto"
            ]
          '';
        };

        # `cpp.options`: Command-line options for the C++ plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for the C++ `protoc` plugin.";
        };

        # `cpp.standard`: The C++ language standard to target.
        standard = mkOption {
          type = types.enum ["c++17" "c++20" "c++23"];
          default = "c++17";
          description = "The C++ language standard to be used for the generated code.";
        };

        # `cpp.optimizeFor`: Optimization preference for the generated code.
        optimizeFor = mkOption {
          type = types.enum ["SPEED" "CODE_SIZE" "LITE_RUNTIME"];
          default = "SPEED";
          description = "The optimization mode for the generated C++ code (SPEED, CODE_SIZE, or LITE_RUNTIME).";
        };

        # `cpp.runtime`: The type of Protobuf runtime library to use.
        runtime = mkOption {
          type = types.enum ["full" "lite"];
          default = "full";
          description = "The type of Protobuf runtime to link against (full or lite).";
        };

        # `cpp.cmakeIntegration`: Whether to generate CMake integration files.
        cmakeIntegration = mkOption {
          type = types.bool;
          default = true;
          description = "If true, generates CMake files to simplify integration with CMake-based projects.";
        };

        # `cpp.pkgConfigIntegration`: Whether to generate pkg-config files.
        pkgConfigIntegration = mkOption {
          type = types.bool;
          default = true;
          description = "If true, generates `.pc` files for integration with pkg-config.";
        };

        # `cpp.includePaths`: Additional include paths for C++ compilation.
        includePaths = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional include paths to use during C++ compilation of generated code.";
        };

        # `cpp.arenaAllocation`: Enable arena allocation for performance.
        arenaAllocation = mkOption {
          type = types.bool;
          default = false;
          description = "Enable arena allocation for messages to improve performance and reduce memory fragmentation.";
        };

        # --- C++ gRPC Plugin ---
        # `cpp.grpc`: Generates C++ gRPC service and client code.
        grpc = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable gRPC service and client code generation for C++.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.grpc";
            description = "The Nix package for the C++ gRPC plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the C++ gRPC plugin.";
          };

          generateMockCode = mkOption {
            type = types.bool;
            default = false;
            description = "If true, generates mock client and server classes for use in tests.";
          };
        };

        # --- C++ Nanopb Plugin ---
        # `cpp.nanopb`: For generating C/C++ code suitable for embedded systems.
        nanopb = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation with `nanopb` for embedded C/C++ systems.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.nanopb";
            description = "The Nix package for the `nanopb` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = ["max_size=1024" "max_count=16"];
            description = "A list of command-line options for the `nanopb` plugin.";
          };
        };

        # --- C++ Protobuf-C Plugin ---
        # `cpp.protobuf-c`: For generating pure C code.
        protobuf-c = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable pure C code generation using the `protobuf-c` plugin.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protobuf-c";
            description = "The Nix package for the `protobuf-c` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the `protobuf-c` plugin.";
          };
        };
      };

      # --- PHP Language Options ---
      # `languages.php`: Configuration for generating PHP code.
      php = {
        # `php.enable`: Enables code generation for PHP.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the PHP language.";
        };

        # `php.package`: The Nix package providing the PHP interpreter and necessary extensions.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.php.withExtensions ({ enabled, all }: enabled ++ [ all.grpc all.protobuf ])";
          description = "The Nix package for PHP, including the `grpc` and `protobuf` extensions.";
        };

        # `php.outputPath`: The directory for generated PHP files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/php";
          description = "The output directory or directories for the generated PHP code.";
          example = literalExpression ''
            [
              "gen/php",
              "src/Proto",
              "app/Proto"
            ]
          '';
        };

        # `php.options`: Command-line options for the PHP plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for the PHP `protoc` plugin.";
        };

        # `php.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for PHP. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/api/v1/user_service.proto",
            "./proto/common/v1/types.proto"
          ];
        };

        # `php.additionalFiles`: Extra `.proto` files for PHP.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for PHP, appended to the main file list.";
          example = [
            "./proto/php/v1/laravel_extensions.proto",
            "./proto/web/v1/session_management.proto"
          ];
        };

        # `php.namespace`: The base PHP namespace for the generated classes.
        namespace = mkOption {
          type = types.str;
          default = "Generated";
          description = "The base PHP namespace to be used for all generated classes.";
        };

        # `php.metadataNamespace`: The namespace for generated metadata classes.
        metadataNamespace = mkOption {
          type = types.str;
          default = "GPBMetadata";
          description = "The PHP namespace for the generated Protocol Buffer metadata classes.";
        };

        # `php.classPrefix`: A prefix to add to all generated class names.
        classPrefix = mkOption {
          type = types.str;
          default = "";
          description = "An optional prefix to be added to the names of all generated PHP classes.";
        };

        # `php.composer`: Settings related to Composer integration.
        composer = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable integration with Composer for dependency management.";
          };

          autoInstall = mkOption {
            type = types.bool;
            default = false;
            description = "If true, automatically runs `composer install` after code generation.";
          };
        };

        # --- PHP gRPC Plugin ---
        # `php.grpc`: Generates PHP gRPC client and server code.
        grpc = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable gRPC client and server code generation for PHP.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.grpc";
            description = "The Nix package for the PHP gRPC plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the PHP gRPC plugin.";
          };

          clientOnly = mkOption {
            type = types.bool;
            default = false;
            description = "If true, generates only client-side code and omits server stubs.";
          };

          serviceNamespace = mkOption {
            type = types.str;
            default = "Services";
            description = "A namespace suffix to be applied to generated service classes.";
          };
        };

        # --- PHP RoadRunner Plugin ---
        # `php.roadrunner`: Integration with the RoadRunner high-performance PHP application server.
        roadrunner = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable generation of gRPC server code compatible with RoadRunner.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.roadrunner";
            description = "The Nix package for the RoadRunner application server.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the RoadRunner plugin.";
          };

          workers = mkOption {
            type = types.int;
            default = 4;
            description = "The number of worker processes for the RoadRunner server.";
          };

          maxJobs = mkOption {
            type = types.int;
            default = 64;
            description = "The maximum number of jobs a worker can handle before being restarted.";
          };

          maxMemory = mkOption {
            type = types.int;
            default = 128;
            description = "The maximum memory per worker in megabytes (MB).";
          };

          tlsEnabled = mkOption {
            type = types.bool;
            default = false;
            description = "Enable TLS encryption for the RoadRunner gRPC server.";
          };
        };

        # --- PHP Framework Integrations ---
        # `php.frameworks`: Settings for integrating with popular PHP frameworks.
        frameworks = {
          laravel = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable generation of integration code for the Laravel framework.";
            };

            serviceProvider = mkOption {
              type = types.bool;
              default = true;
              description = "If true, generates a Laravel Service Provider.";
            };

            artisanCommands = mkOption {
              type = types.bool;
              default = true;
              description = "If true, generates Artisan console commands for protobuf tasks.";
            };
          };

          symfony = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable generation of integration code for the Symfony framework.";
            };

            bundle = mkOption {
              type = types.bool;
              default = true;
              description = "If true, generates a Symfony Bundle.";
            };

            messengerIntegration = mkOption {
              type = types.bool;
              default = true;
              description = "If true, generates integration code for the Symfony Messenger component.";
            };
          };
        };

        # --- Async PHP Support ---
        # `php.async`: Configuration for various asynchronous PHP runtimes.
        async = {
          reactphp = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable integration with the ReactPHP asynchronous framework.";
            };

            version = mkOption {
              type = types.str;
              default = "^1.0";
              description = "The version constraint for the ReactPHP dependency.";
            };
          };

          swoole = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable integration with the Swoole/OpenSwoole asynchronous framework.";
            };

            coroutines = mkOption {
              type = types.bool;
              default = true;
              description = "Enable support for Swoole coroutines.";
            };
          };

          fibers = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable support for PHP 8.1+ Fibers.";
            };
          };
        };

        # --- PHP Twirp Plugin ---
        # `php.twirp`: Legacy support for the Twirp RPC framework.
        twirp = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation for the Twirp RPC framework (legacy).";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-twirp_php";
            description = "The Nix package for the `protoc-gen-twirp_php` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for `protoc-gen-twirp_php`.";
          };
        };
      };

      # --- JavaScript/TypeScript Language Options ---
      # `languages.js`: Configuration for generating JavaScript and TypeScript code.
      js = {
        # `js.enable`: Enables code generation for JavaScript/TypeScript.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the JavaScript/TypeScript language.";
        };

        # `js.package`: The Nix package for the legacy `protoc-gen-js` plugin.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.protoc-gen-js";
          description = "The Nix package for the legacy `protoc-gen-js` plugin. Modern projects should prefer `protoc-gen-es`.";
        };

        # `js.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for JS/TS. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/api/v1/user_api.proto",
            "./proto/common/v1/types.proto",
            "./proto/google/api/annotations.proto"
          ];
        };

        # `js.additionalFiles`: Extra `.proto` files for JS/TS.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for JS/TS, appended to the main file list.";
          example = [
            "./proto/google/api/annotations.proto",
            "./proto/google/api/http.proto",
            "./proto/buf/validate/validate.proto"
          ];
        };

        # `js.outputPath`: The directory for generated JS/TS files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/js";
          description = "The output directory or directories for the generated JS/TS code.";
          example = literalExpression ''
            [
              "gen/js",
              "src/proto",
              "packages/frontend/src/proto",
              "packages/backend/src/proto"
            ]
          '';
        };

        # `js.options`: Command-line options for JS/TS plugins.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for the JS/TS `protoc` plugins.";
        };

        # `js.packageName`: The name for the generated JavaScript package.
        packageName = mkOption {
          type = types.str;
          default = "";
          description = "The package name to use if `generatePackageJson` is true in any sub-option.";
        };

        # --- Protobuf-ES Plugin ---
        # `js.es`: The modern, recommended plugin for generating ES modules and TypeScript.
        es = {
          enable = mkOption {
            type = types.bool;
            default = true; # Enabled by default for a modern JS/TS workflow.
            description = "Enable code generation with `protoc-gen-es` for modern ECMAScript and TypeScript output.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-es";
            description = "The Nix package for the `protoc-gen-es` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = ["target=ts"]; # Default to TypeScript for type safety.
            description = "A list of command-line options for `protoc-gen-es`, e.g., `target=ts`.";
          };

          target = mkOption {
            type = types.enum ["js" "ts" "dts"];
            default = "ts";
            description = "The target output format: `js` for JavaScript, `ts` for TypeScript, or `dts` for declaration files only.";
          };

          importExtension = mkOption {
            type = types.str;
            default = ""; # Let the plugin decide the default.
            description = "The file extension to use for module imports (e.g., `.js` for Node.js ESM).";
          };

          generatePackageJson = mkOption {
            type = types.bool;
            default = false;
            description = "If true, generates a `package.json` file for the generated code.";
          };

          packageName = mkOption {
            type = types.str;
            default = "";
            description = "The name for the generated `package.json` file (if enabled).";
          };
        };

        # --- Connect-ES RPC Plugin ---
        # `js.connect`: Generates code for the Connect RPC framework.
        connect = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation for the Connect RPC framework (requires `js.es.enable`).";
          };

          package = mkOption {
            type = types.nullOr types.package;
            default = null;
            defaultText = literalExpression "null";
            description = "The Nix package for `protoc-gen-connect-es` (deprecated; now integrated into `protoc-gen-es`).";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the Connect plugin.";
          };

          generatePackageJson = mkOption {
            type = types.bool;
            default = false;
            description = "If true, generates a `package.json` file for the generated Connect code.";
          };

          packageName = mkOption {
            type = types.str;
            default = "";
            description = "The name for the generated `package.json` file (if enabled).";
          };
        };

        # --- gRPC-Web Plugin ---
        # `js.grpcWeb`: Generates code for gRPC-Web, for use in browsers.
        grpcWeb = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation for gRPC-Web, for browser-based gRPC communication.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-grpc-web";
            description = "The Nix package for the `protoc-gen-grpc-web` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for `protoc-gen-grpc-web`.";
          };

          importStyle = mkOption {
            type = types.enum ["typescript" "commonjs" "closure"];
            default = "commonjs";
            description = "The module import style for the generated gRPC-Web code.";
          };

          mode = mkOption {
            type = types.enum ["grpcweb" "grpcwebtext"];
            default = "grpcweb";
            description = "The wire format mode for gRPC-Web (`grpcweb` for binary, `grpcwebtext` for Base64-encoded text).";
          };
        };

        # --- Twirp RPC Plugin ---
        # `js.twirp`: Generates code for the Twirp RPC framework.
        twirp = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation for the Twirp RPC framework.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-twirp_js";
            description = "The Nix package for the `protoc-gen-twirp_js` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for `protoc-gen-twirp_js`.";
          };
        };

        # --- Protovalidate-ES Plugin ---
        # `js.protovalidate`: Modern, CEL-based validation for JS/TS.
        protovalidate = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable modern, CEL-based message validation with `protovalidate-es`.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-es";
            description = "The Nix package for `protovalidate-es`, which uses `protoc-gen-es` as its generator.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for `protovalidate-es`.";
          };

          generateValidationHelpers = mkOption {
            type = types.bool;
            default = true;
            description = "If true, generates helper functions for validation.";
          };

          target = mkOption {
            type = types.enum ["js" "ts" "dts"];
            default = "ts";
            description = "The target output format for validation code (`js`, `ts`, or `dts`).";
          };
        };

        # --- ts-proto Plugin ---
        # `js.tsProto`: An alternative TypeScript generator focused on idiomatic code.
        tsProto = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation with `ts-proto` for highly idiomatic TypeScript interfaces.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-ts_proto";
            description = "The Nix package for the `ts-proto` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for `ts-proto` (e.g., `esModuleInterop=true`).";
          };

          generatePackageJson = mkOption {
            type = types.bool;
            default = false;
            description = "If true, generates a `package.json` file for the `ts-proto` output.";
          };

          generateTsConfig = mkOption {
            type = types.bool;
            default = false;
            description = "If true, generates a `tsconfig.json` file for the `ts-proto` output.";
          };

          packageName = mkOption {
            type = types.str;
            default = "";
            description = "The name for the generated `package.json` file (if enabled).";
          };
        };
      };

      # --- Java Language Options ---
      # `languages.java`: Configuration for generating Java code.
      java = {
        # `java.enable`: Enables code generation for Java.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the Java language.";
        };

        # `java.package`: The Nix package for the core Java `protoc` plugin.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.protobuf";
          description = "The Nix package for the core Java `protoc` plugin.";
        };

        # `java.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for Java. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/api/v1/user_api.proto",
            "./proto/common/v1/types.proto"
          ];
        };

        # `java.additionalFiles`: Extra `.proto` files for Java.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for Java, appended to the main file list.";
          example = [
            "./proto/buf/validate/validate.proto",
            "./proto/google/api/annotations.proto"
          ];
        };

        # `java.outputPath`: The directory for generated Java files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/java";
          description = "The output directory or directories for the generated Java code.";
          example = literalExpression ''
            [
              "gen/java",
              "src/main/java"
            ]
          '';
        };

        # `java.options`: Command-line options for the Java plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for the Java `protoc` plugin.";
        };

        # `java.packageName`: The base Java package name for the generated code.
        packageName = mkOption {
          type = types.str;
          default = "";
          description = "The base Java package name to be used for the generated classes.";
        };

        # `java.jdk`: The JDK to use for running Java-based plugins.
        jdk = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.jdk17";
          description = "The Nix package for the JDK, used to run Java-based compiler plugins.";
        };

        # --- Java gRPC Plugin ---
        # `java.grpc`: Generates Java gRPC service and client code.
        grpc = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable gRPC service and client code generation for Java.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.grpc-java";
            description = "The Nix package for the Java gRPC plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the Java gRPC plugin.";
          };
        };

        # --- Java Protovalidate Plugin ---
        # `java.protovalidate`: Modern, CEL-based validation for Java.
        protovalidate = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable modern, CEL-based message validation with `protovalidate-java`.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-validate-java";
            description = "The Nix package for the `protovalidate-java` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the `protovalidate-java` plugin.";
          };
        };
      };

      # --- Dart Language Options ---
      # `languages.dart`: Configuration for generating Dart code, primarily for Flutter and web apps.
      dart = {
        # `dart.enable`: Enables code generation for Dart.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the Dart language.";
        };

        # `dart.package`: The Nix package for the `protoc-gen-dart` plugin.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.protoc-gen-dart";
          description = "The Nix package for the `protoc-gen-dart` plugin.";
        };

        # `dart.outputPath`: The directory for generated Dart files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "lib/proto";
          description = "The output directory or directories for the generated Dart code.";
          example = literalExpression ''
            [
              "lib/proto",
              "lib/generated"
            ]
          '';
        };

        # `dart.options`: Command-line options for the Dart plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for `protoc-gen-dart`.";
        };

        # `dart.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for Dart. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/mobile/v1/flutter_app.proto",
            "./proto/common/v1/types.proto"
          ];
        };

        # `dart.additionalFiles`: Extra `.proto` files for Dart.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for Dart, appended to the main file list.";
          example = [
            "./proto/dart/v1/dart_extensions.proto",
            "./proto/mobile/v1/push_notifications.proto"
          ];
        };

        # `dart.packageName`: The name of the Dart package for the generated code.
        packageName = mkOption {
          type = types.str;
          default = "";
          description = "The name of the Dart package to be used for the generated code.";
        };

        # --- Dart gRPC Plugin ---
        # `dart.grpc`: Generates Dart gRPC service and client code.
        grpc = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable gRPC service and client code generation for Dart.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-dart";
            description = "The Nix package for the Dart gRPC plugin (which is the same as the base Dart plugin).";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for Dart gRPC generation (passed to `protoc-gen-dart`).";
          };
        };
      };

      # --- Elixir Language Options ---
      # `languages.elixir`: Configuration for generating Elixir code.
      elixir = {
        # `elixir.enable`: Enables code generation for Elixir.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the Elixir language.";
        };

        # `elixir.package`: The Nix package for the `protoc-gen-elixir` plugin.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.protoc-gen-elixir";
          description = "The Nix package for the `protoc-gen-elixir` plugin.";
        };

        # `elixir.outputPath`: The directory for generated Elixir files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "lib";
          description = "The output directory or directories for the generated Elixir code.";
          example = literalExpression ''
            [
              "lib/proto",
              "lib/generated"
            ]
          '';
        };

        # `elixir.options`: Command-line options for the Elixir plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for `protoc-gen-elixir`.";
        };

        # `elixir.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for Elixir. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/services/v1/user_service.proto",
            "./proto/common/v1/types.proto"
          ];
        };

        # `elixir.additionalFiles`: Extra `.proto` files for Elixir.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for Elixir, appended to the main file list.";
          example = [
            "./proto/elixir/v1/elixir_extensions.proto",
            "./proto/services/v1/notification_service.proto"
          ];
        };

        # `elixir.namespace`: The base Elixir module namespace for the generated code.
        namespace = mkOption {
          type = types.str;
          default = "";
          description = "The base Elixir module namespace to be used for the generated code.";
          example = "MyApp.Proto";
        };

        # --- Elixir gRPC Plugin ---
        # `elixir.grpc`: Generates Elixir gRPC service and client code.
        grpc = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable gRPC service and client code generation for Elixir.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-elixir";
            description = "The Nix package for the Elixir gRPC plugin (same as the base plugin).";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for Elixir gRPC generation (passed to `protoc-gen-elixir`).";
          };
        };

        # `elixir.validate`: Validation support for Elixir.
        validate = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable message validation support for Elixir.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "null";
            description = "The Nix package for the Elixir validation plugin (if available).";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the Elixir validation plugin.";
          };
        };
      };

      # --- Documentation Generation Options ---
      # `languages.doc`: Configuration for generating human-readable documentation from `.proto` files.
      doc = {
        # `doc.enable`: Enables documentation generation.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable documentation generation using `protoc-gen-doc`.";
        };

        # `doc.package`: The Nix package for the `protoc-gen-doc` plugin.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.protoc-gen-doc";
          description = "The Nix package for the `protoc-gen-doc` plugin.";
        };

        # `doc.outputPath`: The directory for generated documentation files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/doc";
          description = "The output directory or directories for the generated documentation.";
          example = literalExpression ''
            [
              "gen/doc",
              "docs/api"
            ]
          '';
        };

        # `doc.options`: Command-line options for the documentation plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = ["html,index.html"];
          description = "A list of strings representing command-line options for `protoc-gen-doc` (e.g., 'html,index.html').";
        };

        # `doc.files`: Language-specific list of `.proto` files for documentation.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to use for documentation. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/api/v1/user_service.proto",
            "./proto/api/v1/auth_service.proto"
          ];
        };

        # `doc.additionalFiles`: Extra `.proto` files for documentation.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to include only for documentation generation.";
          example = [
            "./proto/docs/v1/examples.proto",
            "./proto/third_party/google/api/annotations.proto"
          ];
        };

        # `doc.format`: The output format for the documentation.
        format = mkOption {
          type = types.enum ["html" "markdown" "json" "docbook" "mdx"];
          default = "html";
          description = "The output format for the generated documentation.";
        };

        # `doc.outputFile`: The name of the main output file.
        outputFile = mkOption {
          type = types.str;
          default = "index.html";
          description = "The filename for the main output documentation file.";
        };

        # `doc.customTemplate`: Path to a custom template for documentation.
        customTemplate = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "An optional path to a custom Go template file to control the documentation output.";
        };

        # --- MDX Documentation Generation ---
        # `doc.mdx`: Specific settings for generating MDX (Markdown with JSX) for documentation sites like Astro.
        mdx = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable generation of MDX-formatted documentation, suitable for sites like Astro or Next.js.";
          };

          outputFile = mkOption {
            type = types.str;
            default = "api-reference.mdx";
            description = "The filename for the generated MDX documentation.";
          };

          title = mkOption {
            type = types.str;
            default = "API Reference";
            description = "The main title used in the MDX frontmatter.";
          };

          description = mkOption {
            type = types.str;
            default = "Generated API documentation from Protocol Buffers";
            description = "The description text used in the MDX frontmatter.";
          };

          frontmatter = mkOption {
            type = types.attrs;
            default = {};
            example = literalExpression ''
              {
                title = "API Reference";
                description = "Protocol Buffer API documentation";
                sidebar.order = 3;
              }
            '';
            description = "A set of additional attributes to be included in the MDX frontmatter.";
          };

          outputPath = mkOption {
            type = types.either types.str (types.listOf types.str);
            default = "./doc/src/content/docs/reference";
            description = "The output directory or directories for the generated MDX documentation.";
            example = literalExpression ''
              [
                "./doc/src/content/docs/reference",
                "./docs/api"
              ]
            '';
          };
        };
      };

      # --- SVG Diagram Generation ---
      # `languages.svg`: Configuration for generating SVG diagrams from `.proto` files using `protoc-gen-d2`.
      svg = {
        # `svg.enable`: Enables SVG diagram generation.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable SVG diagram generation using `protoc-gen-d2`.";
        };

        # `svg.package`: The Nix package for the `protoc-gen-d2` plugin.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.protoc-gen-d2";
          description = "The Nix package for the `protoc-gen-d2` diagram generation plugin.";
        };

        # `svg.outputPath`: The directory for generated SVG files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/svg";
          description = "The output directory or directories for the generated SVG diagrams.";
          example = literalExpression ''
            [
              "gen/svg",
              "docs/diagrams"
            ]
          '';
        };

        # `svg.options`: Command-line options for the SVG plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for `protoc-gen-d2`.";
        };

        # `svg.files`: Language-specific list of `.proto` files for diagram generation.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to use for diagram generation. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/architecture/v1/system_design.proto",
            "./proto/api/v1/user_service.proto"
          ];
        };

        # `svg.additionalFiles`: Extra `.proto` files for diagram generation.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to include only for diagram generation.";
          example = [
            "./proto/diagrams/v1/data_flow.proto",
            "./proto/internal/v1/service_dependencies.proto"
          ];
        };
      };

      # --- Python Language Options ---
      # `languages.python`: Configuration for generating Python code.
      python = {
        # `python.enable`: Enables code generation for Python.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the Python language.";
        };

        # `python.package`: The Nix package for the core Python `protoc` plugin.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.protobuf";
          description = "The Nix package for the core Python `protoc` plugin.";
        };

        # `python.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for Python. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/api/v1/user_api.proto",
            "./proto/common/v1/types.proto"
          ];
        };

        # `python.additionalFiles`: Extra `.proto` files for Python.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for Python, appended to the main file list.";
          example = [
            "./proto/buf/validate/validate.proto",
            "./proto/google/api/annotations.proto"
          ];
        };

        # `python.outputPath`: The directory for generated Python files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/python";
          description = "The output directory or directories for the generated Python code.";
          example = literalExpression ''
            [
              "gen/python",
              "src/proto",
              "dist/mypackage/proto",
              "tests/fixtures/proto"
            ]
          '';
        };

        # `python.options`: Command-line options for Python plugins.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for Python `protoc` plugins.";
        };

        # --- Python gRPC Plugin ---
        # `python.grpc`: Generates Python gRPC service and client code.
        grpc = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable gRPC service and client code generation for Python.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.python3Packages.grpcio-tools";
            description = "The Nix package for the Python gRPC tools.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the Python gRPC plugin.";
          };
        };

        # --- Python MyPy Stubs Plugin ---
        # `python.pyi`: Generates `.pyi` type stub files for static analysis.
        pyi = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable generation of `.pyi` type stub files for better static analysis with tools like MyPy.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protobuf";
            description = "The Nix package for the `.pyi` stub generator (part of the main protobuf package).";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the `.pyi` stub generator.";
          };
        };

        # --- Python Betterproto Plugin ---
        # `python.betterproto`: An alternative Python generator that creates more idiomatic, dataclass-based code.
        betterproto = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation with `betterproto` for modern, idiomatic Python dataclasses.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.python3Packages.betterproto";
            description = "The Nix package for the `betterproto` plugin.";
          };

          pydantic = mkOption {
            type = types.bool;
            default = false;
            description = "If true, generates Pydantic-compatible dataclasses for validation.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the `betterproto` plugin.";
          };
        };

        # --- Python MyPy Protobuf Plugin ---
        # `python.mypy`: Generates type stubs specifically for use with the MyPy type checker.
        mypy = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable generation of MyPy-specific type stubs for protobuf-generated code.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.python3Packages.mypy-protobuf";
            description = "The Nix package for the `mypy-protobuf` plugin.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the `mypy-protobuf` plugin.";
          };
        };
      };

      # --- Swift Language Options ---
      # `languages.swift`: Configuration for generating Swift code, primarily for iOS, macOS, and server-side Swift.
      swift = {
        # `swift.enable`: Enables code generation for Swift.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the Swift language.";
        };

        # `swift.package`: The Nix package for the `protoc-gen-swift` plugin.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.protoc-gen-swift";
          description = "The Nix package for the `protoc-gen-swift` plugin.";
        };

        # `swift.outputPath`: The directory for generated Swift files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/swift";
          description = "The output directory or directories for the generated Swift code.";
          example = literalExpression ''
            [
              "gen/swift",
              "Sources/Proto"
            ]
          '';
        };

        # `swift.options`: Command-line options for the Swift plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for `protoc-gen-swift`.";
        };

        # `swift.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for Swift. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/mobile/v1/ios_app.proto",
            "./proto/common/v1/types.proto"
          ];
        };

        # `swift.additionalFiles`: Extra `.proto` files for Swift.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for Swift, appended to the main file list.";
          example = [
            "./proto/swift/v1/swift_extensions.proto",
            "./proto/mobile/v1/apple_push_notifications.proto"
          ];
        };

        # `swift.packageName`: The name of the Swift package for the generated code.
        packageName = mkOption {
          type = types.str;
          default = "";
          description = "The name of the Swift package to be used for the generated code.";
        };
      };

      # --- C# Language Options ---
      # `languages.csharp`: Configuration for generating C# code for the .NET ecosystem.
      csharp = {
        # `csharp.enable`: Enables code generation for C#.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the C# language.";
        };

        # `csharp.sdk`: The .NET SDK to use for C# tools.
        sdk = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.dotnetCorePackages.sdk_8_0";
          description = "The Nix package for the .NET SDK to be used.";
        };

        # `csharp.outputPath`: The directory for generated C# files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/csharp";
          description = "The output directory or directories for the generated C# code.";
          example = literalExpression ''
            [
              "gen/csharp",
              "src/Proto"
            ]
          '';
        };

        # `csharp.options`: Command-line options for the C# plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for the C# `protoc` plugin.";
        };

        # `csharp.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for C#. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/api/v1/user_service.proto",
            "./proto/common/v1/types.proto"
          ];
        };

        # `csharp.additionalFiles`: Extra `.proto` files for C#.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for C#, appended to the main file list.";
          example = [
            "./proto/dotnet/v1/aspnet_extensions.proto",
            "./proto/web/v1/blazor_components.proto"
          ];
        };

        # `csharp.namespace`: The base C# namespace for the generated code.
        namespace = mkOption {
          type = types.str;
          default = "";
          description = "The base C# namespace to be used for all generated classes.";
        };

        # `csharp.targetFramework`: The .NET target framework for the generated project.
        targetFramework = mkOption {
          type = types.str;
          default = "net8.0";
          description = "The target framework moniker (e.g., 'net8.0') for the generated `.csproj` file.";
        };

        # `csharp.langVersion`: The C# language version to target.
        langVersion = mkOption {
          type = types.str;
          default = "latest";
          description = "The C# language version to be used (e.g., '12.0', 'latest').";
        };

        # `csharp.nullable`: Enable nullable reference types in the generated code.
        nullable = mkOption {
          type = types.bool;
          default = true;
          description = "If true, enables nullable reference types in the generated C# project.";
        };

        # `csharp.fileExtension`: The file extension for generated C# files.
        fileExtension = mkOption {
          type = types.str;
          default = ".cs";
          description = "The file extension to use for the generated C# source files.";
        };

        # `csharp.generateProjectFile`: Whether to generate a `.csproj` file.
        generateProjectFile = mkOption {
          type = types.bool;
          default = true;
          description = "If true, generates a `.csproj` file alongside the C# code.";
        };

        # `csharp.projectName`: The name for the generated `.csproj` file.
        projectName = mkOption {
          type = types.str;
          default = "GeneratedProtos";
          description = "The name of the generated C# project and `.csproj` file.";
        };

        # `csharp.packageId`: The NuGet package ID.
        packageId = mkOption {
          type = types.str;
          default = "";
          description = "The package ID to be used if generating a NuGet package.";
        };

        # `csharp.packageVersion`: The version for the generated NuGet package.
        packageVersion = mkOption {
          type = types.str;
          default = "1.0.0";
          description = "The version number for the generated NuGet package.";
        };

        # `csharp.generatePackageOnBuild`: Whether to generate a NuGet package on build.
        generatePackageOnBuild = mkOption {
          type = types.bool;
          default = false;
          description = "If true, configures the `.csproj` to generate a NuGet package on build.";
        };

        # `csharp.generateAssemblyInfo`: Whether to generate an `AssemblyInfo.cs` file.
        generateAssemblyInfo = mkOption {
          type = types.bool;
          default = false;
          description = "If true, generates an `AssemblyInfo.cs` file with assembly metadata.";
        };

        # `csharp.assemblyVersion`: The assembly version for the generated code.
        assemblyVersion = mkOption {
          type = types.str;
          default = "1.0.0.0";
          description = "The assembly version to be embedded in the generated assembly.";
        };

        # `csharp.protobufVersion`: The version of the `Google.Protobuf` NuGet package to reference.
        protobufVersion = mkOption {
          type = types.str;
          default = "3.31.0";
          description = "The version of the `Google.Protobuf` NuGet package to reference in the `.csproj` file.";
        };

        # --- C# gRPC Plugin ---
        # `csharp.grpc`: Generates C# gRPC service and client code.
        grpc = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable gRPC service and client code generation for C#.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the C# gRPC plugin.";
          };

          grpcVersion = mkOption {
            type = types.str;
            default = "2.72.0";
            description = "The version of the `Grpc.Net.Client` NuGet package to reference.";
          };

          grpcCoreVersion = mkOption {
            type = types.str;
            default = "2.72.0";
            description = "The version of the `Grpc.Core.Api` NuGet package to reference.";
          };

          generateClientFactory = mkOption {
            type = types.bool;
            default = false;
            description = "If true, generates gRPC client factory classes.";
          };

          generateServerBase = mkOption {
            type = types.bool;
            default = false;
            description = "If true, generates base classes for gRPC service implementations.";
          };
        };
      };

      # --- Kotlin Language Options ---
      # `languages.kotlin`: Configuration for generating Kotlin code.
      kotlin = {
        # `kotlin.enable`: Enables code generation for Kotlin.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the Kotlin language. Requires `java.enable` to be true.";
        };

        # `kotlin.jdk`: The JDK to use for running Kotlin's Java-based plugins.
        jdk = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.jdk17";
          description = "The Nix package for the JDK, used to run Kotlin's compiler plugins.";
        };

        # `kotlin.outputPath`: The base directory for all generated Kotlin and Java code.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/kotlin";
          description = "The base output directory or directories for all generated Kotlin-related code.";
          example = literalExpression ''
            [
              "gen/kotlin",
              "src/main/proto"
            ]
          '';
        };

        # `kotlin.javaOutputPath`: The directory for the Java code required by Kotlin.
        javaOutputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/kotlin/java";
          description = "The output directory for the generated Java code, which is a required dependency for Kotlin protobufs.";
          example = literalExpression ''
            [
              "gen/kotlin/java",
              "src/main/java"
            ]
          '';
        };

        # `kotlin.kotlinOutputPath`: The directory for the generated Kotlin code.
        kotlinOutputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/kotlin/kotlin";
          description = "The output directory or directories for the generated Kotlin code.";
          example = literalExpression ''
            [
              "gen/kotlin/kotlin",
              "src/main/kotlin"
            ]
          '';
        };

        # `kotlin.options`: Command-line options for the Kotlin plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for the Kotlin `protoc` plugin.";
        };

        # `kotlin.projectName`: The name for the generated Kotlin project.
        projectName = mkOption {
          type = types.str;
          default = "GeneratedProtos";
          description = "The name of the generated Kotlin project, used in build files.";
        };

        # `kotlin.kotlinVersion`: The version of Kotlin to use.
        kotlinVersion = mkOption {
          type = types.str;
          default = "2.1.20";
          description = "The version of the Kotlin language to target.";
        };

        # `kotlin.protobufVersion`: The version of the Google Protobuf library to use.
        protobufVersion = mkOption {
          type = types.str;
          default = "4.28.2";
          description = "The version of the Google Protobuf library to use as a dependency.";
        };

        # `kotlin.jvmTarget`: The JVM target version for the generated code.
        jvmTarget = mkOption {
          type = types.int;
          default = 17;
          description = "The target version of the JVM for the compiled Kotlin code.";
        };

        # `kotlin.coroutinesVersion`: The version of Kotlin coroutines to use.
        coroutinesVersion = mkOption {
          type = types.str;
          default = "1.8.0";
          description = "The version of the Kotlin coroutines library to use as a dependency.";
        };

        # `kotlin.generateBuildFile`: Whether to generate a `build.gradle.kts` file.
        generateBuildFile = mkOption {
          type = types.bool;
          default = true;
          description = "If true, generates a `build.gradle.kts` file for the Kotlin project.";
        };

        # `kotlin.generatePackageInfo`: Whether to generate `package-info.java` files.
        generatePackageInfo = mkOption {
          type = types.bool;
          default = false;
          description = "If true, generates `package-info.java` files.";
        };

        # `kotlin.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for Kotlin. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/android/v1/kotlin_app.proto",
            "./proto/common/v1/types.proto"
          ];
        };

        # `kotlin.additionalFiles`: Extra `.proto` files for Kotlin.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for Kotlin, appended to the main file list.";
          example = [
            "./proto/kotlin/v1/kotlin_extensions.proto",
            "./proto/mobile/v1/android_services.proto"
          ];
        };

        # --- Kotlin gRPC Plugin ---
        # `kotlin.grpc`: Generates Kotlin gRPC service and client code.
        grpc = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable gRPC service and client code generation for Kotlin.";
          };

          grpcVersion = mkOption {
            type = types.str;
            default = "1.62.2";
            description = "The version of the gRPC Java library to use as a dependency.";
          };

          grpcKotlinVersion = mkOption {
            type = types.str;
            default = "1.4.2";
            description = "The version of the gRPC Kotlin library to use as a dependency.";
          };

          grpcKotlinJar = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "An optional path to a local gRPC Kotlin plugin JAR. If null, it will be downloaded.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the Kotlin gRPC plugin.";
          };

          generateServiceImpl = mkOption {
            type = types.bool;
            default = false;
            description = "If true, generates service implementation stubs.";
          };
        };

        # --- Kotlin Connect RPC Plugin ---
        # `kotlin.connect`: Generates code for the Connect RPC framework in Kotlin.
        connect = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation for the Connect RPC framework for Kotlin.";
          };

          connectVersion = mkOption {
            type = types.str;
            default = "0.7.3";
            description = "The version of the Connect Kotlin library to use as a dependency.";
          };

          connectKotlinJar = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "An optional path to a local Connect Kotlin plugin JAR. If null, it will be downloaded.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the Connect Kotlin plugin.";
          };

          packageName = mkOption {
            type = types.str;
            default = "com.example.connect";
            description = "The package name for the generated Connect configuration files.";
          };

          generateClientConfig = mkOption {
            type = types.bool;
            default = false;
            description = "If true, generates a Connect client configuration helper class.";
          };
        };
      };

      # --- C Language Options ---
      # `languages.c`: Configuration for generating C code.
      c = {
        # `c.enable`: Enables code generation for C.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the C language.";
        };

        # `c.outputPath`: The directory for generated C files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/c";
          description = "The output directory or directories for the generated C code.";
          example = literalExpression ''
            [
              "gen/c",
              "src/proto"
            ]
          '';
        };

        # `c.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for C. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/embedded/v1/sensor_data.proto",
            "./proto/common/v1/types.proto"
          ];
        };

        # `c.additionalFiles`: Extra `.proto` files for C.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for C, appended to the main file list.";
          example = [
            "./proto/c/v1/c_extensions.proto",
            "./proto/system/v1/kernel_messages.proto"
          ];
        };

        # --- Protobuf-C Plugin ---
        # `c.protobuf-c`: The standard plugin for generating C code.
        protobuf-c = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation using the standard `protobuf-c` plugin.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protobuf-c";
            description = "The Nix package for the `protobuf-c` plugin.";
          };

          outputPath = mkOption {
            type = types.either types.str (types.listOf types.str);
            default = "gen/c/protobuf-c";
            description = "The output directory for code generated by `protobuf-c`.";
            example = literalExpression ''
              [
                "gen/c/protobuf-c",
                "src/proto/c"
              ]
            '';
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the `protobuf-c` plugin.";
          };
        };

        # --- Nanopb Plugin ---
        # `c.nanopb`: A plugin for generating lightweight C code for embedded systems.
        nanopb = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation with `nanopb` for embedded systems.";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.nanopb";
            description = "The Nix package for the `nanopb` plugin.";
          };

          outputPath = mkOption {
            type = types.either types.str (types.listOf types.str);
            default = "gen/c/nanopb";
            description = "The output directory for code generated by `nanopb`.";
            example = literalExpression ''
              [
                "gen/c/nanopb",
                "embedded/proto"
              ]
            '';
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the `nanopb` plugin.";
          };

          # --- Nanopb-Specific Options ---
          maxSize = mkOption {
            type = types.int;
            default = 1024;
            description = "The maximum size for dynamically allocated fields in `nanopb`.";
          };

          fixedLength = mkOption {
            type = types.bool;
            default = false;
            description = "If true, use fixed-length arrays for repeated fields in `nanopb`.";
          };

          noUnions = mkOption {
            type = types.bool;
            default = false;
            description = "If true, disables the use of C unions for `oneof` fields in `nanopb`.";
          };

          msgidType = mkOption {
            type = types.str;
            default = "";
            description = "The C type to use for message IDs in `nanopb`.";
          };
        };

        # --- UPB Plugin ---
        # `c.upb`: Google's modern C implementation for protobuf.
        upb = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable code generation with `upb`, Google's modern C protobuf implementation (experimental).";
          };

          package = mkOption {
            type = types.package;
            defaultText = literalExpression "pkgs.protoc-gen-upb";
            description = "The Nix package for the `protoc-gen-upb` plugin.";
          };

          outputPath = mkOption {
            type = types.either types.str (types.listOf types.str);
            default = "gen/c/upb";
            description = "The output directory for code generated by `upb`.";
            example = literalExpression ''
              [
                "gen/c/upb",
                "src/proto/upb"
              ]
            '';
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of command-line options for the `upb` plugin.";
          };
        };
      };

      # --- Scala Language Options ---
      # `languages.scala`: Configuration for generating Scala code.
      scala = {
        # `scala.enable`: Enables code generation for Scala.
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable or disable all code generation for the Scala language.";
        };

        # `scala.package`: The Nix package for the ScalaPB plugin.
        package = mkOption {
          type = types.package;
          defaultText = literalExpression "pkgs.scalapb";
          description = "The Nix package for the ScalaPB (Scala Protocol Buffers) plugin.";
        };

        # `scala.outputPath`: The directory for generated Scala files.
        outputPath = mkOption {
          type = types.either types.str (types.listOf types.str);
          default = "gen/scala";
          description = "The output directory or directories for the generated Scala code.";
          example = literalExpression ''
            [
              "gen/scala",
              "src/main/scala"
            ]
          '';
        };

        # `scala.options`: Command-line options for the ScalaPB plugin.
        options = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of strings representing command-line options for the ScalaPB plugin.";
        };

        # `scala.files`: Language-specific list of `.proto` files.
        files = mkOption {
          type = types.nullOr (types.listOf types.str);
          default = null;
          description = "A specific list of `.proto` files to compile for Scala. If null, uses the global `protoc.files` list.";
          example = [
            "./proto/api/v1/user_service.proto",
            "./proto/common/v1/types.proto"
          ];
        };

        # `scala.additionalFiles`: Extra `.proto` files for Scala.
        additionalFiles = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "A list of additional `.proto` files to compile only for Scala, appended to the main file list.";
          example = [
            "./proto/scala/v1/scala_extensions.proto",
            "./proto/akka/v1/actor_messages.proto"
          ];
        };

        # `scala.scalaVersion`: The version of Scala to target.
        scalaVersion = mkOption {
          type = types.str;
          default = "3.3.3";
          description = "The version of the Scala language to target in the generated build file.";
        };

        # `scala.scalapbVersion`: The version of the ScalaPB library.
        scalapbVersion = mkOption {
          type = types.str;
          default = "1.0.0-alpha.1";
          description = "The version of the ScalaPB library to use as a dependency.";
        };

        # `scala.sbtVersion`: The version of SBT for the generated build file.
        sbtVersion = mkOption {
          type = types.str;
          default = "1.10.5";
          description = "The version of the SBT (Scala Build Tool) to specify in the generated build file.";
        };

        # `scala.sbtProtocVersion`: The version of the `sbt-protoc` plugin.
        sbtProtocVersion = mkOption {
          type = types.str;
          default = "1.0.7";
          description = "The version of the `sbt-protoc` plugin to use in the generated build file.";
        };

        # `scala.projectName`: The name for the generated Scala project.
        projectName = mkOption {
          type = types.str;
          default = "generated-protos";
          description = "The name of the generated Scala project, used in the build file.";
        };

        # `scala.projectVersion`: The version for the generated Scala project.
        projectVersion = mkOption {
          type = types.str;
          default = "0.1.0";
          description = "The version number for the generated Scala project.";
        };

        # `scala.organization`: The organization for the generated Scala project.
        organization = mkOption {
          type = types.str;
          default = "com.example";
          description = "The organization name to be used in the generated Scala build file.";
        };

        # `scala.generateBuildFile`: Whether to generate a `build.sbt` file.
        generateBuildFile = mkOption {
          type = types.bool;
          default = false;
          description = "If true, generates a `build.sbt` file for the Scala project.";
        };

        # `scala.generatePackageObject`: Whether to generate package objects for proto packages.
        generatePackageObject = mkOption {
          type = types.bool;
          default = false;
          description = "If true, generates package objects for each protobuf package.";
        };

        # --- Scala gRPC Plugin ---
        # `scala.grpc`: Generates Scala gRPC service and client code.
        grpc = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable gRPC service and client code generation for Scala.";
          };

          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "A list of additional command-line options for Scala gRPC generation.";
          };
        };

        # --- Scala JSON Plugin ---
        # `scala.json`: Generates JSON serializers for ScalaPB.
        json = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable JSON serialization support for ScalaPB-generated classes.";
          };

          json4sVersion = mkOption {
            type = types.str;
            default = "0.7.0";
            description = "The version of the `scalapb-json4s` library to use.";
          };
        };

        # --- Scala Validation Plugin ---
        # `scala.validate`: Enables validation support for ScalaPB.
        validate = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable message validation support using the `scalapb-validate` library.";
          };
        };
      };
    };
  };
}
