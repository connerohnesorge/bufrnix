{
  description = "Multiple Output Paths Example - Demonstrates generating protobuf code to multiple directories";

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
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        packages = {
          default = bufrnix.lib.mkBufrnixPackage {
            inherit pkgs;
            config = {
              root = ".";
              protoc = {
                sourceDirectories = ["proto"];
                includeDirectories = ["proto"];
              };

              languages = {
                # Go with multiple output paths for different use cases
                go = {
                  enable = true;
                  outputPath = [
                    "gen/go" # Main generated code
                    "pkg/shared/proto" # Shared package location
                    "vendor/proto" # Vendor directory for dependencies
                    "services/common/proto" # Microservices shared proto
                  ];
                  grpc = {
                    enable = true;
                    outputPath = [
                      "gen/go/grpc" # Generated gRPC code
                      "pkg/shared/proto/grpc" # Shared gRPC services
                      "vendor/proto/grpc" # Vendor gRPC dependencies
                    ];
                  };
                  validate.enable = true;
                };

                # JavaScript with multiple output paths for different modules
                js = {
                  enable = true;
                  outputPath = [
                    "packages/frontend/src/proto" # Frontend package
                    "packages/backend/src/proto" # Backend package
                    "packages/shared/proto" # Shared utilities
                    "dist/npm-package/proto" # Distribution package
                  ];
                  es = {
                    enable = true;
                    target = "ts";
                  };
                };

                # Python with multiple output paths for development and distribution
                python = {
                  enable = true;
                  outputPath = [
                    "gen/python" # Main development location
                    "src/mypackage/proto" # Package source location
                    "dist/mypackage/proto" # Distribution package
                    "tests/fixtures/proto" # Test fixtures
                  ];
                  grpc.enable = true;
                  pyi.enable = true;
                };
              };

              debug = {
                enable = true;
                verbosity = 2;
              };
            };
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            go
            nodejs
            python3
            protobuf
          ];

          shellHook = ''
            echo "Multi-Output Paths Example Environment"
            echo "======================================"
            echo ""
            echo "This example demonstrates Bufrnix's multiple output paths feature."
            echo ""
            echo "Available commands:"
            echo "  nix run     - Generate protobuf code to multiple output directories"
            echo "  nix develop - Enter development environment"
            echo ""
            echo "The configuration generates code to multiple paths for each language:"
            echo "- Go: gen/go, pkg/shared/proto, vendor/proto, services/common/proto"
            echo "- JavaScript: packages/frontend/src/proto, packages/backend/src/proto, packages/shared/proto, dist/npm-package/proto"
            echo "- Python: gen/python, src/mypackage/proto, dist/mypackage/proto, tests/fixtures/proto"
            echo ""
          '';
        };
      }
    );
}
