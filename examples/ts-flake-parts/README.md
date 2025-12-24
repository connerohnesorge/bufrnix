# TypeScript Flake-Parts Example

This example demonstrates how to use [Bufrnix](https://github.com/conneroisu/bufrnix) with [flake-parts](https://flake.parts/) to generate TypeScript protobuf code. It showcases modern TypeScript development with protobuf generation in a declarative, reproducible way.

## Features

- 🔧 **Flake-Parts Integration**: Demonstrates how to integrate Bufrnix with flake-parts for modular Nix configuration
- 📦 **TypeScript Code Generation**: Generates type-safe TypeScript code from protobuf definitions
- 🚀 **Protobuf-ES**: Uses the modern Protobuf-ES library for TypeScript/JavaScript protobuf support
- 🌐 **Connect-ES**: Includes Connect-ES for modern RPC client/server implementation
- ✅ **Validation**: Integrates protovalidate-ES for message validation
- 🧪 **Testing**: Comprehensive test suite demonstrating generated code functionality
- 📖 **Documentation**: Clear examples and usage patterns

## What's Generated

Bufrnix generates the following TypeScript files from the protobuf definitions:

```
gen/
├── example/
│   └── v1/
│       ├── user_pb.ts          # Message definitions and types
│       └── user_connect.ts     # Connect-ES service definitions
```

## Quick Start

### Prerequisites

- [Nix](https://nixos.org/) with flakes enabled
- [Node.js](https://nodejs.org/) (provided by the dev shell)

### 1. Enter Development Environment

```bash
nix develop
```

This provides:

- Node.js 20
- TypeScript compiler
- npm package manager
- tsx for running TypeScript directly

### 2. Generate TypeScript Code

```bash
nix build
# or
nix build .#proto
```

This runs Bufrnix to generate TypeScript files from the protobuf definitions in `proto/`.

### 3. Install Dependencies

```bash
npm install
```

### 4. Build TypeScript Project

```bash
npm run build
```

### 5. Run Examples

```bash
# Run the main example
npm run dev

# Run individual examples
npm run server  # Start Connect-ES server
npm run client  # Run Connect-ES client (requires server)

# Run tests
npm test
```

## Project Structure

```
.
├── flake.nix              # Flake-parts configuration with Bufrnix
├── package.json           # Node.js dependencies and scripts
├── tsconfig.json          # TypeScript configuration
├── proto/                 # Protocol buffer definitions
│   └── example/v1/
│       └── user.proto     # User service definition
├── src/                   # TypeScript source code
│   ├── index.ts           # Main example demonstrating features
│   ├── server.ts          # Connect-ES server implementation
│   ├── client.ts          # Connect-ES client implementation
│   └── test.ts            # Test suite for generated code
├── gen/                   # Generated TypeScript code (after nix build)
└── dist/                  # Compiled JavaScript (after npm run build)
```

## Examples

### Basic Message Usage

```typescript
import { User, Role } from "../gen/example/v1/user_pb.js";
import { Timestamp } from "@bufbuild/protobuf";

// Create a new user
const user = new User({
  id: "user-123",
  email: "john@example.com",
  name: "John Doe",
  role: Role.ADMIN,
  isActive: true,
  createdAt: Timestamp.now(),
});

// Serialize to binary
const bytes = user.toBinary();

// Deserialize from binary
const deserialized = User.fromBinary(bytes);

// Convert to/from JSON
const json = user.toJson();
const fromJson = User.fromJson(json);
```

### Connect-ES Server

```typescript
import { fastify } from "fastify";
import { fastifyConnectPlugin } from "@connectrpc/connect-fastify";
import { UserService } from "../gen/example/v1/user_pb.js";

const server = fastify();

await server.register(fastifyConnectPlugin, {
  routes: (router) => {
    router.service(UserService, {
      async createUser(request) {
        // Implementation
      },
      async getUser(request) {
        // Implementation
      },
      // ... other methods
    });
  },
});

await server.listen({ port: 3000 });
```

### Connect-ES Client

```typescript
import { createPromiseClient } from "@connectrpc/connect";
import { createConnectTransport } from "@connectrpc/connect-node";
import { UserService } from "../gen/example/v1/user_pb.js";

const transport = createConnectTransport({
  baseUrl: "http://localhost:3000",
});

const client = createPromiseClient(UserService, transport);

const response = await client.createUser({
  user: new User({
    email: "test@example.com",
    name: "Test User",
    role: Role.USER,
  }),
});
```

## Flake-Parts Configuration

The `flake.nix` demonstrates how to integrate Bufrnix with flake-parts:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    bufrnix.url = "github:conneroisu/bufrnix";
  };

  outputs = inputs @ { flake-parts, bufrnix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

      perSystem = { pkgs, ... }: let
        protoGenerated = bufrnix.lib.mkBufrnixPackage {
          inherit pkgs;
          config = {
            src = ./.;
            protoSourcePaths = ["proto"];
            languages = {
              js = {
                enable = true;
                es = {
                  enable = true;
                  target = "ts";
                };
                connect.enable = true;
                protovalidate.enable = true;
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
        };
      };
    };
}
```

**Note**: You must manage your own `package.json` file with the appropriate dependencies. See the example `package.json` in this directory.

## Commands

### Development

```bash
nix develop          # Enter development environment
nix build            # Generate TypeScript code
npm install          # Install Node.js dependencies
npm run build        # Compile TypeScript to JavaScript
```

### Running Examples

```bash
npm run dev          # Run main example
npm run server       # Start Connect-ES server
npm run client       # Run Connect-ES client
npm test             # Run test suite
```

### Utilities

```bash
npm run clean        # Clean generated and compiled files
npm run typecheck    # Run TypeScript type checking
```

## Generated Code Features

### Type Safety

All generated TypeScript code is fully type-safe:

- Strong typing for all message fields
- Enum type safety
- Optional field handling
- Generic type support for collections

### Modern ES Modules

Generated code uses modern ES module syntax:

- ES2022 target
- Tree-shakeable exports
- Native import/export
- Browser and Node.js compatibility

### Protobuf-ES Features

- Fast binary serialization/deserialization
- JSON serialization with proper type handling
- Message cloning and equality checking
- Efficient memory usage
- Support for all protobuf features

### Connect-ES Integration

- Type-safe RPC client generation
- Server implementation helpers
- Support for streaming (if needed)
- HTTP/1.1 and HTTP/2 support
- Browser and Node.js compatibility

## Testing

The example includes a comprehensive test suite that validates:

- Message creation and field access
- Serialization/deserialization (binary and JSON)
- Type safety and enum handling
- Service request/response messages
- Generated code functionality

Run tests with:

```bash
npm test
```

## Benefits of This Approach

### Reproducibility

- Nix ensures identical builds across all environments
- Flake lock file pins all dependencies
- No network dependencies during build

### Developer Experience

- Zero setup with `nix develop`
- Comprehensive tooling included
- Modern TypeScript development environment
- Hot reloading and fast iteration

### Integration

- Seamless integration with existing TypeScript projects
- Compatible with popular frameworks (React, Vue, Angular, etc.)
- Works with bundlers (Webpack, Vite, esbuild, etc.)
- CI/CD friendly

### Type Safety

- Compile-time checking of protobuf usage
- IntelliSense and autocompletion support
- Refactoring safety
- Better development experience

## Troubleshooting

### Common Issues

1. **Missing generated files**: Run `nix build` to generate TypeScript code
2. **TypeScript errors**: Ensure generated files are present and run `npm run typecheck`
3. **Runtime errors**: Check that server is running for client examples
4. **Import errors**: Verify file extensions in imports (`.js` for ES modules)

### Debug Mode

Enable debug output in `flake.nix`:

```nix
config = {
  # ... other config
  debug = {
    enable = true;
    verbosity = 2;
  };
};
```

## Related Examples

- [js-es-modules](../js-es-modules/) - JavaScript ES modules without flake-parts
- [js-grpc-web](../js-grpc-web/) - gRPC-Web example
- [go-advanced](../go-advanced/) - Go with advanced features

## Learn More

- [Bufrnix Documentation](https://bufrnix.dev)
- [Flake-Parts Documentation](https://flake.parts/)
- [Protobuf-ES Documentation](https://github.com/bufbuild/protobuf-es)
- [Connect-ES Documentation](https://connectrpc.com/docs/node/getting-started)
