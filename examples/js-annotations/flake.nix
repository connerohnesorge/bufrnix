{
  description = "JavaScript/TypeScript with Google API annotations example using Connect-ES";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # bufrnix.url = "github:conneroisu/bufrnix";
    bufrnix.url = "path:../..";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    bufrnix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = {
        default = bufrnix.lib.mkBufrnixPackage {
          inherit pkgs;

          config = {
            root = ./.;
            protoc = {
              sourceDirectories = ["./proto"];
              includeDirectories = ["./proto"];
              files = [
                "./proto/example/v1/user_service.proto"
                "./proto/google/api/annotations.proto" 
                "./proto/google/api/http.proto"
              ];
            };

            # Enable debug mode to see detailed output
            debug = {
              enable = true;
              verbosity = 2;
              logFile = "bufrnix-debug.log";
            };

            languages.js = {
              enable = true;
              outputPath = "proto/gen/ts";

              # Enable Protobuf-ES with TypeScript generation
              # This is the modern approach for JavaScript/TypeScript protobuf
              es = {
                enable = true;
                options = [
                  "target=ts"
                  "import_extension=.js"
                  "json_types=true"
                  "keep_empty_files=true"
                ];
              };
            };
          };
        };
      };

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nodejs_20
          typescript
          tsx
        ];

        shellHook = ''
          echo "🚀 JavaScript/TypeScript with Google API Annotations Example"
          echo ""
          echo "This example demonstrates generating TypeScript client code from protobuf"
          echo "definitions that include Google API annotations for HTTP/REST mapping."
          echo ""
          echo "Key Features:"
          echo "  ✅ Google API annotations (google.api.http) for REST endpoints"
          echo "  ✅ Protobuf-ES for modern TypeScript message generation"
          echo "  ✅ Complete user management service example"
          echo ""
          echo "Available commands:"
          echo "  nix build              - Generate TypeScript code from proto files"
          echo "  npm install            - Install TypeScript dependencies"
          echo "  npm run build          - Build the TypeScript project"
          echo "  npm run dev            - Run development server"
          echo "  npm run lint           - Run ESLint on generated code"
          echo "  npm run type-check     - Run TypeScript type checking"
          echo ""
          echo "Generated code locations:"
          echo "  ./gen/ts/              - All generated TypeScript files"
          echo "  ./gen/ts/google/       - Google API annotations as TypeScript"
          echo "  ./gen/ts/example/      - User service messages and clients"
          echo ""
        '';
      };
    });
}