{
  description = "JavaScript ES modules example with custom outputPath - tests plugin-specific output paths";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # bufrnix.url = "github:conneroisu/bufrnix";
    bufrnix.url = "path:../..";
    bufrnix.inputs.nixpkgs.follows = "nixpkgs";
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
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.nodejs
          pkgs.nodePackages.typescript
        ];
      };
      packages = {
        default = bufrnix.lib.mkBufrnixPackage {
          inherit pkgs;

          config = {
            root = ./.;
            protoc = {
              sourceDirectories = ["./proto"];
              includeDirectories = ["./proto"];
              files = ["./proto/example/v1/example.proto"];
            };
            languages.js = {
              enable = true;
              # This demonstrates the bug: setting outputPath at ES plugin level
              # Currently this gets ignored and uses the default "gen/js" instead
              es = {
                enable = true;
                outputPath = "proto/gen/js";  # Custom path for ES modules
                options = [
                  "target=ts"
                  "import_extension=.js"
                  "json_types=true"
                ];
              };
            };
          };
        };
      };
    });
}
