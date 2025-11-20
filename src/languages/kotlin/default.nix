{
  pkgs,
  config,
  lib,
  cfg ? config.languages.kotlin,
  ...
}:
with lib; let
  # Define output paths
  inherit (cfg) javaOutputPath;
  inherit (cfg) kotlinOutputPath;
  kotlinOptions = cfg.options;

  # Import Kotlin-specific sub-modules
  grpcModule = import ./grpc.nix {
    inherit pkgs lib;
    cfg =
      (cfg.grpc or {enable = false;})
      // {
        inherit javaOutputPath;
        inherit kotlinOutputPath;
        inherit (cfg) jdk;
        grpcKotlinJar = cfg.grpc.grpcKotlinJar or null;
        grpcKotlinVersion = cfg.grpc.grpcKotlinVersion or "1.4.2";
        grpcJavaJar = cfg.grpc.grpcJavaJar or null;
        grpcVersion = cfg.grpc.grpcVersion or "1.62.2";
      };
  };

  connectModule = import ./connect.nix {
    inherit pkgs lib;
    cfg =
      (cfg.connect or {enable = false;})
      // {
        inherit javaOutputPath;
        inherit kotlinOutputPath;
        inherit (cfg) jdk;
        connectKotlinJar = cfg.connect.connectKotlinJar or null;
        connectVersion = cfg.connect.connectVersion or "0.7.3";
      };
  };

  # Combine all sub-modules
  combineModuleAttrs = attr:
    concatLists (catAttrs attr [
      grpcModule
      connectModule
    ]);
in {
  # Runtime dependencies for Kotlin code generation
  runtimeInputs =
    [
      pkgs.protobuf # Contains protoc with built-in Kotlin support
      cfg.jdk # JDK for running Java-based plugins
    ]
    ++ (combineModuleAttrs "runtimeInputs");

  # Protoc plugin configuration for Kotlin
  # Note: Kotlin requires both Java and Kotlin outputs
  protocPlugins =
    [
      # Java output is required for Kotlin
      "--java_out=${javaOutputPath}"
      # Kotlin output (built into protoc)
      "--kotlin_out=${kotlinOutputPath}"
    ]
    ++ (optionals (kotlinOptions != []) [
      "--kotlin_opt=${concatStringsSep "," kotlinOptions}"
    ])
    ++ (combineModuleAttrs "protocPlugins");

  # Initialization hook for Kotlin
  initHooks =
    ''
      # Create Kotlin-specific directories
      mkdir -p "${javaOutputPath}"
      mkdir -p "${kotlinOutputPath}"

      # Create build.gradle.kts if enabled
      ${optionalString cfg.generateBuildFile ''
        echo "Creating Kotlin build file..."
        cat > "${cfg.outputPath}/build.gradle.kts" <<EOF
        import com.google.protobuf.gradle.*

        plugins {
            kotlin("jvm") version "${cfg.kotlinVersion}"
            id("com.google.protobuf") version "0.9.5"
        }

        repositories {
            mavenCentral()
        }

        dependencies {
            implementation("com.google.protobuf:protobuf-java:${cfg.protobufVersion}")
            implementation("com.google.protobuf:protobuf-kotlin:${cfg.protobufVersion}")
            ${optionalString cfg.grpc.enable ''
          implementation("io.grpc:grpc-kotlin-stub:${cfg.grpc.grpcKotlinVersion}")
          implementation("io.grpc:grpc-protobuf:${cfg.grpc.grpcVersion}")
          implementation("io.grpc:grpc-netty-shaded:${cfg.grpc.grpcVersion}")
          implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:${cfg.coroutinesVersion}")
        ''}
            ${optionalString cfg.connect.enable ''
          implementation("com.connectrpc:connect-kotlin:${cfg.connect.connectVersion}")
          implementation("com.connectrpc:connect-kotlin-okhttp:${cfg.connect.connectVersion}")
        ''}
        }

        kotlin {
            jvmToolchain(${toString cfg.jvmTarget})
        }

        protobuf {
            protoc {
                artifact = "com.google.protobuf:protoc:${cfg.protobufVersion}"
            }
            ${optionalString cfg.grpc.enable ''
          plugins {
              create("grpc") {
                  artifact = "io.grpc:protoc-gen-grpc-java:${cfg.grpc.grpcVersion}"
              }
              create("grpckt") {
                  artifact = "io.grpc:protoc-gen-grpc-kotlin:${cfg.grpc.grpcKotlinVersion}:jdk8@jar"
              }
          }
        ''}
            ${optionalString cfg.connect.enable ''
          plugins {
              create("connect") {
                  artifact = "com.connectrpc:protoc-gen-connect-kotlin:${cfg.connect.connectVersion}"
              }
          }
        ''}
            generateProtoTasks {
                all().forEach { task ->
                    task.builtins {
                        create("kotlin")
                    }
                    ${optionalString cfg.grpc.enable ''
          task.plugins {
              create("grpc")
              create("grpckt")
          }
        ''}
                    ${optionalString cfg.connect.enable ''
          task.plugins {
              create("connect")
          }
        ''}
                }
            }
        }
        EOF
      ''}

      # Create settings.gradle.kts if enabled
      ${optionalString cfg.generateBuildFile ''
        cat > "${cfg.outputPath}/settings.gradle.kts" <<EOF
        rootProject.name = "${cfg.projectName}"
        EOF
      ''}
    ''
    + concatStrings (catAttrs "initHooks" [
      grpcModule
      connectModule
    ]);

  # Code generation hook for Kotlin
  generateHooks =
    ''
      # Kotlin-specific code generation steps
      echo "Generating Kotlin code..."
      echo "Note: Both Java and Kotlin outputs are generated as Kotlin extends Java protobuf classes"

      # Ensure both output directories exist
      mkdir -p ${javaOutputPath}
      mkdir -p ${kotlinOutputPath}

      # Post-process if needed
      ${optionalString cfg.generatePackageInfo ''
        echo "Generating package-info.java files..."
        find ${javaOutputPath} -type d -name "*" -exec sh -c '
          dir="$1"
          if [ -n "$(find "$dir" -maxdepth 1 -name "*.java" -print -quit)" ]; then
            pkg=$(echo "$dir" | sed "s|${javaOutputPath}/||" | tr "/" ".")
            echo "package $pkg;" > "$dir/package-info.java"
          fi
        ' _ {} \;
      ''}
    ''
    + concatStrings (catAttrs "generateHooks" [
      grpcModule
      connectModule
    ]);
}
