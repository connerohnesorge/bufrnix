{
  description = "TypeScript Flake-Parts Example with Bufrnix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # bufrnix.url = "github:conneroisu/bufrnix";
    bufrnix.url = "path:../..";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    bufrnix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        # Configure bufrnix for TypeScript generation with modern features
        protoGenerated = bufrnix.lib.mkBufrnixPackage {
          inherit pkgs;

          config = {
            src = ./.;
            protoSourcePaths = ["proto"];

            languages = {
              js = {
                enable = true;
                # Protobuf-ES with TypeScript output
                es = {
                  enable = true;
                  target = "ts";
                  generatePackageJson = true;
                  packageName = "@example/proto-ts";
                  importExtension = ".js";
                };
                # TypeScript validation support (disabled for now)
                # protovalidate = {
                #   enable = true;
                #   generateValidationHelpers = true;
                # };
              };
            };

            debug = {
              enable = true;
              verbosity = 1;
            };
          };
        };
      in {
        packages = {
          default = protoGenerated;
          proto = protoGenerated;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs_20
            nodePackages.typescript
            nodePackages.npm
          ];

          shellHook = ''
            echo "🚀 TypeScript Flake-Parts Example with Bufrnix"
            echo ""
            echo "This example demonstrates:"
            echo "  • Flake-parts integration with bufrnix"
            echo "  • TypeScript protobuf generation with Protobuf-ES"
            echo "  • Protovalidate-ES for validation"
            echo ""
            echo "Commands:"
            echo "  nix build                    - Generate TypeScript code from proto files"
            echo "  nix build .#proto           - Same as above (explicit proto package)"
            echo "  npm install                 - Install dependencies after generation"
            echo "  npm run build               - Build TypeScript project"
            echo "  npm run dev                 - Run development server"
            echo "  npm test                    - Run tests"
            echo ""
            echo "Generated code locations:"
            echo "  gen/                        - Generated TypeScript files"
            echo ""
            echo "Features enabled:"
            echo "  ✅ Protobuf-ES (TypeScript generator)"
            echo "  ✅ Protovalidate-ES (validation support)"
            echo "  ✅ Flake-parts integration"
          '';
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.nodejs_20}/bin/node";
            args = ["dist/index.js"];
          };

          dev = {
            type = "app";
            program = "${pkgs.writeShellScript "ts-dev" ''
              set -e
              echo "🏗️  Building TypeScript project..."
              ${pkgs.nodePackages.npm}/bin/npm run build
              echo "🚀 Starting TypeScript application..."
              ${pkgs.nodejs_20}/bin/node dist/index.js
            ''}";
          };
        };

        checks = {
          build-typescript =
            pkgs.runCommand "build-typescript-check" {
              buildInputs = [pkgs.nodejs_20 pkgs.nodePackages.npm pkgs.nodePackages.typescript];
              src = ./.;
            } ''
              cp -r $src ./source
              chmod -R +w ./source
              cd ./source

              # Generate proto files first
              cp -r ${protoGenerated}/gen ./

              # Install dependencies and build
              npm install
              npm run build

              # Verify output files exist
              [ -f "dist/index.js" ] || (echo "Missing dist/index.js" && exit 1)
              [ -f "dist/client.js" ] || (echo "Missing dist/client.js" && exit 1)

              touch $out
            '';
        };
      };
    };
}
