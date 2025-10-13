{
  description = "JavaScript ES Modules Example with Protobuf-ES";

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

      # Configure bufrnix for JavaScript ES modules with all modern features
      protoGenerated = bufrnix.lib.mkBufrnixPackage {
        inherit pkgs;

        config = {
          src = ./.;
          protoSourcePaths = ["proto"];

          languages = {
            js = {
              enable = true;
              # Protobuf-ES is enabled by default with TypeScript output
              es = {
                enable = true; # This is now default true
                target = "ts"; # Generate TypeScript by default
                generatePackageJson = true;
                packageName = "@example/proto";
                importExtension = ".js"; # For Node.js ES modules compatibility
              };
              # TypeScript validation support
              protovalidate = {
                enable = true;
                generateValidationHelpers = true;
              };
            };
          };
        };
      };
    in {
      packages.default = protoGenerated;

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nodejs_20
          nodePackages.typescript
          nodePackages.tsx
        ];

        shellHook = ''
          echo "🚀 JavaScript ES Modules Example with Protobuf-ES"
          echo ""
          echo "Commands:"
          echo "  nix build         - Generate TypeScript code from proto files"
          echo "  npm install       - Install dependencies after code generation"
          echo "  npm run dev       - Run the development server"
          echo "  npm run test      - Run tests"
          echo ""
          echo "Generated code locations:"
          echo "  proto/gen/js/     - Protobuf-ES generated messages"
          echo ""
          echo "Features enabled:"
          echo "  ✅ Protobuf-ES (default TypeScript generator)"
          echo "  ✅ Protovalidate-ES (validation support)"
        '';
      };
    });
}
