{
  pkgs,
  lib,
  cfg,
  ...
}:
with lib; let
  # Define gRPC-specific options
  grpcOptions = cfg.options or [];
  inherit (cfg) javaOutputPath;
  inherit (cfg) kotlinOutputPath;

  # Create wrapper script for grpc-kotlin plugin
  grpcKotlinPlugin =
    if cfg.enable
    then
      pkgs.writeShellScriptBin "protoc-gen-grpckt" ''
        #!/usr/bin/env sh
        # Wrapper script for gRPC Kotlin plugin JAR
        if [ -n "$GRPC_KOTLIN_JAR" ]; then
          ${cfg.jdk}/bin/java -jar "$GRPC_KOTLIN_JAR" "$@"
        else
          ${cfg.jdk}/bin/java -jar ${
          if cfg.grpcKotlinJar != null
          then cfg.grpcKotlinJar
          else ".bufrnix-cache/protoc-gen-grpc-kotlin.jar"
        } "$@"
        fi
      ''
    else null;

  # For Java gRPC, we'll download the platform-specific executable
  grpcJavaPlugin =
    if cfg.enable
    then
      pkgs.stdenv.mkDerivation {
        pname = "protoc-gen-grpc-java";
        version = "${cfg.grpcVersion}-bufrnix4";

        src = let
          inherit (pkgs.stdenv) isDarwin;
          inherit (pkgs.stdenv.hostPlatform) isAarch64;
          platform =
            if isDarwin && isAarch64
            then "osx-aarch_64"
            else if isDarwin
            then "osx-x86_64"
            else if pkgs.stdenv.isLinux && isAarch64
            then "linux-aarch_64"
            else "linux-x86_64";
        in
          pkgs.fetchurl {
            url = "https://repo1.maven.org/maven2/io/grpc/protoc-gen-grpc-java/${cfg.grpcVersion}/protoc-gen-grpc-java-${cfg.grpcVersion}-${platform}.exe";
            sha256 =
              if pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64
              then "sha256-HVRJbxa4aJy/WMTTnP4ne1Mi2gpy9YZlzWDhHX3kfis=" # macOS ARM64
              else if pkgs.stdenv.isDarwin
              then "sha256-HVRJbxa4aJy/WMTTnP4ne1Mi2gpy9YZlzWDhHX3kfis=" # macOS x86_64
              else if pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isAarch64
              then "" # Linux AArch - needs actual hashk
              else if pkgs.stdenv.isLinux
              then "sha256-NIskxLJM2MVRdCFzCfJrb29tNohJL+dj1IoVV7UV6Lw="
              else builtins.trace "Unknown platform" null;
          };

        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/bin

          # On macOS ARM64, we need to use Rosetta 2 for the x86_64 binary
          ${
            if pkgs.stdenv.isDarwin && pkgs.stdenv.hostPlatform.isAarch64
            then ''
                # Create a wrapper script that uses arch -x86_64
                cat > $out/bin/protoc-gen-grpc-java << 'EOF'
              #!/bin/bash
              exec arch -x86_64 ${placeholder "out"}/libexec/protoc-gen-grpc-java "$@"
              EOF
                chmod +x $out/bin/protoc-gen-grpc-java

                # Put the actual binary in libexec
                mkdir -p $out/libexec
                cp $src $out/libexec/protoc-gen-grpc-java
                chmod +x $out/libexec/protoc-gen-grpc-java
            ''
            else ''
              # For other platforms, just copy the binary
              cp $src $out/bin/protoc-gen-grpc-java
              chmod +x $out/bin/protoc-gen-grpc-java
            ''
          }
        '';
      }
    else null;
in {
  # Runtime dependencies for gRPC Kotlin code generation
  runtimeInputs = optionals cfg.enable [
    grpcJavaPlugin
    grpcKotlinPlugin
  ];

  # Protoc plugin configuration for gRPC Kotlin
  protocPlugins = optionals cfg.enable ([
      # Generate Java gRPC stubs (required for Kotlin)
      "--grpc-java_out=${javaOutputPath}"
      "--plugin=protoc-gen-grpc-java=${grpcJavaPlugin}/bin/protoc-gen-grpc-java"

      # Generate Kotlin gRPC stubs
      "--grpckt_out=${kotlinOutputPath}"
      "--plugin=protoc-gen-grpckt=${grpcKotlinPlugin}/bin/protoc-gen-grpckt"
    ]
    ++ (optionals (grpcOptions != []) [
      "--grpckt_opt=${concatStringsSep "," grpcOptions}"
    ]));

  # Initialization hook for gRPC Kotlin
  initHooks = optionalString cfg.enable ''
    # gRPC Kotlin specific initialization
    echo "Initializing gRPC Kotlin code generation..."

    # Download gRPC Kotlin plugin JAR if not provided
    ${optionalString (cfg.grpcKotlinJar == null) ''
      echo "Downloading gRPC Kotlin plugin JAR..."
      mkdir -p .bufrnix-cache
      ${pkgs.curl}/bin/curl -L -o .bufrnix-cache/protoc-gen-grpc-kotlin.jar \
        "https://repo1.maven.org/maven2/io/grpc/protoc-gen-grpc-kotlin/${cfg.grpcKotlinVersion}/protoc-gen-grpc-kotlin-${cfg.grpcKotlinVersion}-jdk8.jar"
      export GRPC_KOTLIN_JAR=".bufrnix-cache/protoc-gen-grpc-kotlin.jar"
    ''}
  '';

  # Code generation hook for gRPC Kotlin
  generateHooks = optionalString cfg.enable ''
    # gRPC Kotlin specific code generation
    echo "Generated gRPC Kotlin service code"

    # Create service implementations if enabled
    ${optionalString cfg.generateServiceImpl ''
      echo "Generating gRPC service implementations..."
      # This would generate base service implementations
      # Implementation depends on specific requirements
    ''}
  '';
}
