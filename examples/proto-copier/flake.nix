{
  description = "Proto Copier Example - Demonstrating proto file copying with various configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
        # bufrnix.url = "github:conneroisu/bufrnix";
    bufrnix.url = "path:../..";
    bufrnix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    bufrnix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = {
        # Basic proto copying - preserve structure, copy all proto files
        default = bufrnix.lib.mkBufrnixPackage {
          inherit pkgs;
          config = {
            root = ./.;
            protoc = {
              sourceDirectories = ["./proto"];
              includeDirectories = ["./proto"];
              files = [
                "./proto/api/v1/user_service.proto"
                "./proto/common/v1/types.proto"
                "./proto/external/v1/webhook.proto"
                "./proto/internal/v1/admin_service.proto"
                "./proto/test/test_user.proto"
              ];
            };
            languages.proto = {
              enable = true;
              copier = {
                enable = true;
                outputPath = [
                  "output/backend/proto"
                  "output/frontend/src/proto"
                ];
                preserveStructure = true;
                includePatterns = ["*.proto"];
                excludePatterns = [
                  "**/test/**"
                  "**/internal/**"
                ];
              };
            };
          };
        };

        # Advanced example: Multiple output destinations with different configurations
        advanced-copy = bufrnix.lib.mkBufrnixPackage {
          inherit pkgs;
          config = {
            root = ./.;
            debug = {
              enable = true;
              verbosity = 2;
            };
            protoc = {
              sourceDirectories = ["./proto"];
              includeDirectories = ["./proto"];
            };
            languages.proto = {
              enable = true;
              copier = {
                enable = true;
                outputPath = [
                  "output/public-api"     # For external-facing APIs
                  "output/shared-types"   # For shared type definitions
                  "output/mobile-client"  # For mobile app development
                ];
                preserveStructure = true;
                includePatterns = [
                  "api/v1/*.proto"
                  "common/v1/*.proto"
                  "external/v1/*.proto"
                ];
                excludePatterns = [
                  "**/internal/**"
                  "**/test/**"
                  "**/*_internal.proto"
                ];
                filePrefix = "";
                fileSuffix = "";
              };
            };
          };
        };

        # Flattened copy example: Copy all files to single directory
        flattened-copy = bufrnix.lib.mkBufrnixPackage {
          inherit pkgs;
          config = {
            root = ./.;
            protoc = {
              sourceDirectories = ["./proto"];
              includeDirectories = ["./proto"];
            };
            languages.proto = {
              enable = true;
              copier = {
                enable = true;
                outputPath = ["output/flattened"];
                preserveStructure = false;
                flattenFiles = true;
                includePatterns = ["*.proto"];
                excludePatterns = ["**/test/**"];
                filePrefix = "proto_";
                fileSuffix = "_v1";
              };
            };
          };
        };

        # Selective copying: Only API and common types
        api-only-copy = bufrnix.lib.mkBufrnixPackage {
          inherit pkgs;
          config = {
            root = ./.;
            protoc = {
              sourceDirectories = ["./proto"];
              includeDirectories = ["./proto"];
              files = [
                "./proto/api/v1/user_service.proto"
                "./proto/common/v1/types.proto"
              ];
            };
            languages.proto = {
              enable = true;
              copier = {
                enable = true;
                outputPath = [
                  "output/api-client"
                  "output/sdk-generator"
                ];
                preserveStructure = true;
                includePatterns = ["*.proto"];
                excludePatterns = [];
              };
            };
          };
        };

        # Multi-language example: Proto copying + Go generation
        proto-and-go = bufrnix.lib.mkBufrnixPackage {
          inherit pkgs;
          config = {
            root = ./.;
            protoc = {
              sourceDirectories = ["./proto"];
              includeDirectories = ["./proto"];
            };
            languages = {
              # Copy proto files for distribution
              proto.copier = {
                enable = true;
                outputPath = [
                  "output/proto-dist"
                  "clients/proto"
                ];
                preserveStructure = true;
                includePatterns = ["*.proto"];
                excludePatterns = [
                  "**/internal/**"
                  "**/test/**"
                ];
              };
              
              # Generate Go code from the same proto files
              go = {
                enable = true;
                outputPath = "output/go";
                grpc = {
                  enable = true;
                };
                options = [
                  "paths=source_relative"
                  "module=github.com/example/proto-go"
                ];
              };
            };
          };
        };
      };

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          # Development tools
          protobuf
          buf
          
          # For testing the examples
          tree
          fd
          
          # For Go development (if using the multi-language example)
          go
        ];
        
        shellHook = ''
          echo "🚀 Proto Copier Example Development Environment"
          echo ""
          echo "Available packages:"
          echo "  default          - Basic proto copying with structure preservation"
          echo "  advanced-copy    - Multiple destinations with filtering"
          echo "  flattened-copy   - Flatten all proto files with prefixes/suffixes"
          echo "  api-only-copy    - Copy only API and common types"
          echo "  proto-and-go     - Proto copying + Go code generation"
          echo ""
          echo "Usage:"
          echo "  nix run                    # Run default package"
          echo "  nix run .#advanced-copy    # Run advanced copy example"
          echo "  nix run .#flattened-copy   # Run flattened copy example"
          echo "  tree output/               # View copied files"
          echo ""
          echo "Proto files available:"
          find proto -name "*.proto" -type f | head -10
        '';
      };
    });
}