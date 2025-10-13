# Bufrnix

<p align="center">
  <img src="assets/bufrnix.png" alt="Bufrnix Logo" width="600">
</p>

<p align="center">
  <strong>Nix-powered Protocol Buffers with declarative code generation and comprehensive developer tooling</strong>
</p>

<p align="center">
  <a href="https://github.com/conneroisu/bufr.nix/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License">
  </a>
  <a href="https://nixos.org">
    <img src="https://img.shields.io/badge/Built%20with-Nix-5277C3.svg?logo=nixos&logoColor=white" alt="Built with Nix">
  </a>
  <a href="https://protobuf.dev/">
    <img src="https://img.shields.io/badge/Protocol-Buffers-00ADD8.svg?logo=google" alt="Protocol Buffers">
  </a>
  <a href="https://conneroisu.github.io/bufrnix/">
    <img src="https://img.shields.io/badge/docs-available-brightgreen.svg" alt="Documentation">
  </a>
</p>

<p align="center">
  <a href="#-key-features">Features</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-language-support">Languages</a> •
  <a href="#-examples">Examples</a> •
  <a href="https://conneroisu.github.io/bufrnix/">Documentation</a>
</p>

## 📋 Overview

Bufrnix provides a **declarative, reproducible way** to generate Protocol Buffer code for multiple languages through Nix flakes. It eliminates the complexity of managing protoc plugins, dependencies, and build environments by leveraging Nix's deterministic package management.

> 📚 See the [quick start guide](https://conneroisu.github.io/bufrnix/guides/getting-started/) for a quick introduction to Bufrnix.

### Table of Contents

- [🎯 Why Bufrnix?](#-why-bufrnix)
  - [The Problems with Remote Plugin Systems](#the-problems-with-remote-plugin-systems)
  - [How Bufrnix Solves These Problems](#how-bufrnix-solves-these-problems)
- [✨ Key Features](#-key-features)
- [🚀 Quick Start](#-quick-start)
- [📖 Comprehensive Examples](#-comprehensive-examples)
- [🌍 Language Support](#-language-support)
- [💡 Examples](#-examples)
- [🛠️ Development Environment](#️-development-environment)
- [⚙️ Configuration Reference](#️-configuration-reference)
- [🔧 Advanced Usage](#-advanced-usage)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

## 🎯 Why Bufrnix?

Protocol Buffer tooling has traditionally suffered from **dependency hell**, **network dependencies**, and **non-reproducible builds**. While Buf's remote plugin system simplifies initial setup, it introduces critical limitations that become deal-breakers for production teams:

### The Problems with Remote Plugin Systems

**🌐 Network Dependency Friction**
- Remote plugins require constant internet connectivity, breaking offline development
- Corporate firewalls and air-gapped environments can't access remote plugin execution  
- Network latency and rate limiting slow down development workflows
- Timeout errors (`context deadline exceeded`) and service interruptions disrupt CI/CD pipelines
- Geographic latency affects teams in regions distant from Buf's servers

**🔒 Security and Compliance Concerns**
- Proprietary Protocol Buffer schemas must be sent to external servers for processing
- Financial services, healthcare, and government contractors can't share sensitive API definitions
- Intellectual property concerns prevent many organizations from using remote execution
- Compliance requirements (SOX, HIPAA, FedRAMP) demand local processing of technical specifications
- Supply chain security policies prohibit external dependency on third-party infrastructure

**⚡ Technical Limitations**
- **64KB response size limits** cause silent failures with large generated outputs (affects protoc-gen-grpc-swift and other plugins)
- Plugins requiring file system access or multi-stage generation cannot function remotely
- **"All" strategy requirement** prevents efficient directory-based generation optimizations
- Custom plugins require expensive Pro/Enterprise subscriptions
- Plugin ecosystem growth is bottlenecked by centralized approval processes
- Cross-plugin dependencies (like protoc-gen-gotag modifying generated Go code) are impossible

**🔄 Reproducibility Challenges**
- Network variability introduces non-determinism in generated code
- Plugin version updates can break existing workflows without warning
- Cache invalidation and remote infrastructure changes affect build consistency
- Migration between plugin versions often requires extensive code modifications
- Alpha-to-stable transitions have caused breaking changes requiring full codebase updates
- Remote caching can mask non-deterministic plugin behavior until production

### How Bufrnix Solves These Problems

**🏠 Local, Deterministic Execution**
```nix
# All plugins execute locally with dependencies managed by Nix
languages.go = {
  enable = true;
  grpc.enable = true;     # No network calls, no timeouts
  validate.enable = true; # Full plugin ecosystem available
  # Exact plugin versions cryptographically pinned
  grpc.package = pkgs.protoc-gen-go-grpc; # v1.3.0 always
};
```

**🔐 Complete Privacy and Control**
- All processing happens on your machines - schemas never leave your environment
- No external dependencies for code generation workflows
- Full control over plugin versions, updates, and security patches
- Compliance-friendly for regulated industries (SOX, HIPAA, FedRAMP)
- Supply chain integrity through cryptographic verification

**⚡ Performance and Flexibility**
- **60x faster builds** in some cases (20 minutes → 20 seconds in CI)
- No artificial size limits (64KB) or plugin capability restrictions
- Support for custom plugins, multi-stage generation, and complex workflows
- Plugin chaining and file system access work seamlessly
- Directory-based generation strategies for optimal performance
- Parallel execution across multiple languages and plugins

**🎯 True Reproducibility**
```nix
# Same inputs = identical outputs, always
config = {
  languages.go.grpc.package = pkgs.protoc-gen-go-grpc; # Exact version pinned
  # Cryptographic hashes ensure supply chain integrity
  # Content-addressed storage prevents version drift
  # Hermetic builds with no external state
};
```

**🛠 Developer Experience**
- **Offline-first**: Development continues without internet connectivity
- **Zero setup**: `nix develop` provides complete toolchain in seconds
- **Type-safe configuration**: Catch errors before generation runs
- **Multi-language**: Generate for 8+ languages simultaneously from one config
- **Plugin ecosystem**: Access to all community plugins, not just Buf-approved ones

### Real-World Impact

Teams using Bufrnix report:
- **Eliminated "works on my machine" problems** with reproducible Nix environments
- **Simplified CI/CD pipelines** with deterministic, cacheable builds
- **Improved security posture** by keeping sensitive schemas internal
- **Faster iteration** without network latency and rate limiting
- **Better compliance** with local processing requirements
- **Cost savings** by eliminating Pro/Enterprise subscriptions for custom plugins
- **Increased developer productivity** with offline-capable workflows

### The Broader Ecosystem: Buf vs. Bufrnix

Bufrnix doesn't compete with Buf - it **complements** the Protocol Buffer ecosystem by addressing different use cases:

**Buf excels at:**
- Schema management and breaking change detection
- Collaborative protobuf development with buf.build registry
- Getting started quickly with zero local setup
- Managed plugin ecosystem with security guarantees
- Remote code generation for simple workflows

**Bufrnix excels at:**
- Local, offline-first development workflows
- Complex multi-language, multi-plugin scenarios
- Regulated environments with compliance requirements
- High-performance build pipelines at scale
- Custom plugin development and integration
- Supply chain security with cryptographic verification

**The hybrid approach** many teams adopt:
1. **Use Buf for** schema validation, breaking change detection, and collaboration
2. **Use Bufrnix for** actual code generation in production environments
3. **Combine both** for comprehensive Protocol Buffer development workflows

This pattern maximizes the benefits of both tools while avoiding their respective limitations.

### When to Choose Bufrnix

**Choose Bufrnix if you need:**
- Offline development capabilities
- Corporate firewall/air-gapped environment support
- Sensitive schema privacy and compliance
- Custom or community plugins not in Buf's registry
- Reproducible builds with version pinning
- High-performance local execution
- Multi-language code generation workflows

**Buf's remote plugins work well for:**
- Quick experimentation and getting started
- Simple, single-language projects
- Teams comfortable with external processing
- Workflows fitting within remote plugin limitations

Bufrnix doesn't replace Buf - it **extends** the Protocol Buffer ecosystem with local, reproducible alternatives for teams that need them.

### ✨ Key Features

<table>
<tr>
<td>🚀 <strong>Multi-language Support</strong></td>
<td>13+ languages: Go, JS/TS, Python, Java, C++, C#, Kotlin, Scala, Dart, PHP, Swift, C, and documentation generation</td>
</tr>
<tr>
<td>🔧 <strong>Rich Plugin Ecosystem</strong></td>
<td>gRPC, gRPC-Web, gRPC-Gateway, Twirp, and validation</td>
</tr>
<tr>
<td>📦 <strong>Zero Setup</strong></td>
<td>All dependencies managed through Nix</td>
</tr>
<tr>
<td>🎯 <strong>Declarative Configuration</strong></td>
<td>Type-safe configuration with clear error messages</td>
</tr>
<tr>
<td>🔄 <strong>Reproducible Builds</strong></td>
<td>Same output across all machines and CI/CD</td>
</tr>
<tr>
<td>⚡ <strong>Developer Experience</strong></td>
<td>Comprehensive tooling, formatting, linting, and language servers included</td>
</tr>
</table>

## 🚀 Quick Start

### Prerequisites

- [Nix](https://nixos.org/download.html) with [flakes enabled](https://nixos.wiki/wiki/Flakes)
- That's it! All other dependencies are managed by Nix

### 1. Basic Usage

Create a `flake.nix` in your project root:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    bufrnix.url = "github:conneroisu/bufr.nix";
    bufrnix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, bufrnix, ... }: 
  let
    system = "x86_64-linux";  # or your system
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.default = bufrnix.lib.mkBufrnixPackage {
      inherit (pkgs) lib;
      inherit pkgs;
      config = {
        root = ./.;
        protoc = {
          files = ["./proto/user/v1/user.proto"];
        };
        languages.go = {
          enable = true;
          outputPath = "gen/go";
          grpc.enable = true;
        };
      };
    };
  };
}
```

### 2. Create Your Proto Files

```protobuf
// proto/user/v1/user.proto
syntax = "proto3";

package user.v1;

option go_package = "example.com/user/v1;userv1";

service UserService {
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
}

message CreateUserRequest {
  string name = 1;
  string email = 2;
}

message CreateUserResponse {
  User user = 1;
}

message GetUserRequest {
  string id = 1;
}

message GetUserResponse {
  User user = 1;
}

message User {
  string id = 1;
  string name = 2;
  string email = 3;
  int64 created_at = 4;
}
```

### 3. Generate Code

```bash
nix run
```

Generated code will appear in `gen/go/user/v1/`:
- `user.pb.go` - Protocol Buffer messages
- `user_grpc.pb.go` - gRPC service definitions

## 📖 Comprehensive Examples

### Multi-Language Project

Generate code for multiple languages simultaneously:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    bufrnix.url = "github:conneroisu/bufr.nix";
    bufrnix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, bufrnix, ... }: {
    packages.default = bufrnix.lib.mkBufrnixPackage {
      inherit (nixpkgs.legacyPackages.x86_64-linux) lib pkgs;
      config = {
        root = ./.;
        protoc = {
          sourceDirectories = ["./proto"];
          includeDirectories = ["./proto"];
          files = [
            "./proto/user/v1/user.proto"
            "./proto/product/v1/product.proto"
          ];
        };
        
        # Go with full gRPC ecosystem
        languages.go = {
          enable = true;
          outputPath = "gen/go";
          options = ["paths=source_relative"];
          grpc.enable = true;
          gateway.enable = true;      # HTTP/JSON transcoding
          validate.enable = true;     # Message validation
        };
        
        # Dart for Flutter applications
        languages.dart = {
          enable = true;
          outputPath = "lib/proto";
          packageName = "my_app_proto";
          grpc.enable = true;
        };
        
        # JavaScript for web and Node.js
        languages.js = {
          enable = true;
          outputPath = "src/proto";
          packageName = "my-proto";
          es.enable = true;           # Modern ECMAScript modules
          grpcWeb.enable = true;      # Browser-compatible gRPC
          twirp.enable = true;        # Twirp RPC framework
        };
        
        # PHP with Twirp support
        languages.php = {
          enable = true;
          outputPath = "gen/php";
          namespace = "MyApp\\Proto";
          twirp.enable = true;
        };
        
        # Swift for iOS/macOS applications
        languages.swift = {
          enable = true;
          outputPath = "Sources/Generated";
          packageName = "MyAppProto";
        };
      };
    };
  };
}
```

### Advanced Go Configuration

For Go projects requiring the full ecosystem:

```nix
languages.go = {
  enable = true;
  outputPath = "internal/proto";
  packagePrefix = "github.com/myorg/myproject";
  options = [
    "paths=source_relative"
    "require_unimplemented_servers=false"
  ];
  
  # Core gRPC support
  grpc = {
    enable = true;
    options = [
      "paths=source_relative"
      "require_unimplemented_servers=false"
    ];
  };
  
  # HTTP/JSON gateway for REST APIs
  gateway = {
    enable = true;
    options = [
      "paths=source_relative"
      "generate_unbound_methods=true"
    ];
  };
  
  # Message validation
  validate = {
    enable = true;
    options = ["lang=go"];
  };
};
```

### Modern JavaScript/TypeScript Setup

For modern web applications:

```nix
languages.js = {
  enable = true;
  outputPath = "src/generated";
  packageName = "@myorg/proto";
  
  # Modern ECMAScript modules
  es = {
    enable = true;
    options = [
      "target=ts"                    # Generate TypeScript
      "import_extension=.js"         # ES module extensions
    ];
  };

  # gRPC-Web for browser compatibility
  grpcWeb = {
    enable = true;
    options = [
      "import_style=typescript"
      "mode=grpcwebtext"
    ];
  };
};
```

## 🌍 Language Support

| Language | Status | Plugins & Features | Output |
|----------|---------|-------------------|--------|
| **Go** | ✅ Full | `protoc-gen-go`, gRPC, Gateway, Validation, VTProtobuf, Struct Transformer | Standard Go packages with comprehensive ecosystem |
| **JavaScript/TypeScript** | ✅ Full | ES modules, gRPC-Web, Twirp, ts-proto, Protovalidate | Modern JS/TS with type definitions |
| **Python** | ✅ Full | Standard protoc, gRPC, mypy, betterproto, type stubs | Python packages with optional typing |
| **Dart** | ✅ Full | `protoc-gen-dart`, gRPC support | Flutter/server Dart classes with type safety |
| **PHP** | ✅ Full | Standard protoc, Twirp, Async, Laravel, Symfony, gRPC, RoadRunner | PSR-4 compatible classes with framework integration |
| **Java** | ✅ Full | `protoc-gen-java`, gRPC, Protovalidate | Standard Java classes with build system integration |
| **C++** | ✅ Full | `protoc-gen-cpp`, gRPC, CMake helpers | Native C++ classes with CMake integration |
| **Swift** | ✅ Full | `protoc-gen-swift` | iOS/macOS Swift classes with SwiftProtobuf |
| **C#** | ✅ Full | `protoc-gen-csharp`, gRPC | .NET compatible classes with gRPC support |
| **Kotlin** | ✅ Full | `protoc-gen-kotlin`, gRPC | JVM Kotlin classes with modern RPC support |
| **Scala** | ✅ Full | `protoc-gen-scala`, gRPC | Scala classes with functional programming patterns |
| **C** | ✅ Full | protobuf-c, nanopb | Embedded-friendly C implementations |
| **Documentation** | ✅ Full | HTML/SVG generation, MDX templates | Rich documentation output formats |

## 💡 Examples

Explore complete working examples in the [`examples/`](examples/) directory:

### 🟦 [Simple Go gRPC Example](examples/simple-flake/)
```bash
cd examples/simple-flake
nix develop
go run main.go
```
- Basic gRPC server and client
- User management service
- Error handling and validation

### 🎯 [Comprehensive Dart Example](examples/dart-example/) 
```bash
cd examples/dart-example
nix develop
dart pub get
dart run lib/main.dart
dart test
```
- Complex protobuf messages with all field types
- Complete gRPC client implementation 
- Comprehensive test suite

### 🟨 [Modern JavaScript Example](examples/js-example/)
```bash
cd examples/js-example
nix develop
npm install && npm run build && npm start
```
- Multiple JavaScript output formats
- gRPC-Web and Twirp clients
- TypeScript integration

### 🐘 [PHP Twirp Example](examples/php-twirp/)
```bash
cd examples/php-twirp
nix develop
composer install
php -S localhost:8080 -t src/
```
- Twirp RPC server and client
- PSR-4 autoloading
- JSON-over-HTTP communication

### 🍎 [Swift Example](examples/swift-example/)
```bash
cd examples/swift-example
nix develop
bufrnix_init
bufrnix
swift build && swift run
```
- Protocol Buffer messages for iOS/macOS
- Type-safe Swift code generation
- SwiftProtobuf integration

## 🛠️ Development Environment

### Prerequisites

- [Nix](https://nixos.org/download.html) with [flakes enabled](https://nixos.wiki/wiki/Flakes)
- That's it! All other dependencies are managed by Nix

### Setup

```bash
# Clone the repository
git clone https://github.com/conneroisu/bufr.nix.git
cd bufrnix

# Enter development environment  
nix develop

# Available commands:
dx        # Edit flake.nix
lint      # Run Nix linting (statix + deadnix)
nix fmt   # Format all files (Nix, Markdown, TypeScript, YAML)
```

### Documentation Development

The documentation is built with Astro and uses MDX format for enhanced content capabilities:

```bash
cd doc
nix develop
bun install
bun run dev     # http://localhost:4321
bun run build   # Build static site
```

## ⚙️ Configuration Reference

### Root Configuration

```nix
config = {
  # Required: Root directory containing proto files
  root = "./proto";
  
  # Protoc configuration
  protoc = {
    sourceDirectories = ["./proto"];      # Where to find .proto files
    includeDirectories = ["./proto"];     # Include path for imports
    files = [                             # Optional: specific files to compile
      "./proto/user/v1/user.proto"      # If empty, compiles all .proto files
    ];
  };
  
  # Debug configuration
  debug = {
    enable = false;                       # Enable debug output
    verbosity = 1;                        # 1-3, higher = more verbose
    logFile = "";                         # Empty = stdout, or path to file
  };
  
  # Language configurations (see language-specific docs)
  languages = { ... };
};
```

### Language-Specific Options

Each language module supports:

- `enable`: Boolean to enable/disable the language
- `outputPath`: Where to place generated files (relative to root)
- `options`: Array of options passed to the base protoc plugin
- Plugin-specific configuration (e.g., `grpc.enable`, `validate.enable`)

See the [Language Modules Documentation](src/languages/README.md) for complete details.

## 🔧 Advanced Usage

### Custom Proto Dependencies

```nix
protoc = {
  includeDirectories = [
    "./proto"
    "${pkgs.protobuf}/include"           # Include well-known types
    "${googleapis}/google/api"           # Google API protos
  ];
};
```

### CI/CD Integration

```yaml
# .github/workflows/protobuf.yml
name: Generate Protobuf Code
on: [push, pull_request]
jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v22
        with:
          extra_nix_config: |
            experimental-features = nix-command flakes
      - run: nix build
      - run: git diff --exit-code  # Ensure generated code is up-to-date
```

### Multiple Output Configurations

Generate different outputs for different environments:

```nix
{
  packages = {
    # Production build with optimizations
    prod = bufrnix.lib.mkBufrnixPackage {
      inherit (pkgs) lib;
      inherit pkgs;
      config = {
        languages.go = {
          enable = true;
          options = ["paths=source_relative" "Mgrpc/service_config/service_config.proto=google.golang.org/grpc/serviceconfig"];
        };
      };
    };
    
    # Development build with validation and debugging
    dev = bufrnix.lib.mkBufrnixPackage {
      inherit (pkgs) lib;  
      inherit pkgs;
      config = {
        debug.enable = true;
        languages.go = {
          enable = true;
          validate.enable = true;
          gateway.enable = true;
        };
      };
    };
  };
}
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork and clone** the repository
2. **Make changes** to language modules or core functionality
3. **Test** with the example projects
4. **Update documentation** as needed
5. **Submit a pull request**

### Adding Language Support

1. Create a new module in `src/languages/`
2. Add configuration options to `src/lib/bufrnix-options.nix`
3. Create a working example in `examples/`
4. Update documentation

See the [Language Modules README](src/languages/README.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [Protocol Buffers](https://developers.google.com/protocol-buffers) - Google's language-neutral data serialization
- [Nix](https://nixos.org/) - Reproducible package management and builds
- [gRPC](https://grpc.io/) - High-performance RPC framework
- [Twirp](https://github.com/twitchtv/twirp) - Simple RPC framework for service-to-service communication

---

<p align="center">
  <strong>Questions?</strong> Check out the <a href="https://conneroisu.github.io/bufrnix/">documentation</a>, browse the <a href="examples/">examples</a>, or <a href="https://github.com/conneroisu/bufr.nix/issues/new">open an issue</a>!
</p>

<p align="center">
  Made with ❤️ by the Bufrnix community
</p>
