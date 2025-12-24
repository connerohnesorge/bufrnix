# JavaScript ES Modules Example with Protobuf-ES

This example demonstrates the modern JavaScript/TypeScript Protocol Buffer stack using Bufrnix with:

- **Protobuf-ES**: The only fully conformant JavaScript protobuf library
- **Connect-ES**: Modern RPC framework supporting Connect, gRPC, and gRPC-Web protocols
- **Protovalidate-ES**: Runtime validation for Protocol Buffers
- **TypeScript-first**: Full type safety and excellent IDE support

## Features

- ✅ TypeScript code generation by default
- ✅ ES modules with proper import/export
- ✅ Runtime validation with buf.validate annotations
- ✅ Modern Connect protocol for efficient RPC
- ✅ Full type safety and autocompletion
- ✅ Tree-shakeable output for optimal bundle sizes

## Quick Start

1. Generate the TypeScript code from proto files:

   ```bash
   nix build
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Run the server:

   ```bash
   npm run server
   ```

4. In another terminal, run the client:
   ```bash
   npm run client
   ```

## Project Structure

```
js-es-modules/
├── proto/
│   ├── buf.yaml              # Buf configuration
│   ├── user.proto            # User service with validation rules
│   └── product.proto         # Product service example
├── src/
│   ├── server-example.ts     # Connect-ES server implementation
│   ├── client-example.ts     # Type-safe client example
│   └── index.ts              # Main entry point
├── flake.nix                 # Bufrnix configuration
├── package.json              # Node.js dependencies
└── tsconfig.json             # TypeScript configuration
```

## Generated Code

After running `nix build`, the generated TypeScript code will be in:

```
proto/gen/js/
├── example/
│   ├── user/
│   │   └── v1/
│   │       ├── user_pb.ts         # Message types
│   │       └── user_connect.ts    # Service definitions
│   └── product/
│       └── v1/
│           ├── product_pb.ts      # Message types
│           └── product_connect.ts # Service definitions
```

## Validation Example

The `user.proto` file includes validation rules using `buf.validate`:

```protobuf
message User {
  string id = 1 [(buf.validate.field).string = {
    min_len: 1,
    max_len: 36,
    pattern: "^[a-zA-Z0-9-_]+$"
  }];

  string email = 2 [(buf.validate.field).string.email = true];

  string name = 3 [(buf.validate.field).string = {
    min_len: 1,
    max_len: 100
  }];
}
```

These validation rules are enforced at runtime:

```typescript
const validator = await createValidator();
const violations = await validator.validate(user);
if (violations.length > 0) {
  throw new Error(`Validation failed: ${violations.join(", ")}`);
}
```

## Configuration Options

The `flake.nix` demonstrates various configuration options:

```nix
languages = {
  js = {
    enable = true;
    es = {
      enable = true;               # Enabled by default
      target = "ts";               # Generate TypeScript
      importExtension = ".js";     # For Node.js compatibility
    };
    protovalidate = {
      enable = true;               # Enable validation
    };
    tsProto = {
      enable = false;              # Alternative generator
    };
  };
};
```

**Note**: You must manage your own `package.json` file with the appropriate dependencies for your project. See the example `package.json` in this directory.

## Alternative: ts-proto

You can also enable ts-proto for a different style of TypeScript generation:

```nix
tsProto = {
  enable = true;
  options = [
    "esModuleInterop=true"
    "outputServices=nice-grpc"
    "useOptionals=messages"
  ];
};
```

This generates plain TypeScript interfaces instead of classes, which some developers prefer.

## Testing

Run the test suite:

```bash
npm test
```

This will:

1. Build the protobuf files with Nix
2. Type-check all TypeScript code
3. Ensure everything compiles correctly

## What Gets Generated

### Message Classes (Protobuf-ES)

```typescript
import { User, Role } from "./proto/gen/js/example/user/v1/user_pb.js";

// Create messages with type safety
const user = new User({
  id: "user-123",
  email: "alice@example.com",
  name: "Alice",
  role: Role.ADMIN,
});

// Serialize to binary
const bytes = user.toBinary();

// Parse from binary
const decoded = User.fromBinary(bytes);

// JSON serialization
const json = user.toJson();
const fromJson = User.fromJson(json);
```

### Service Definitions (Connect-ES)

```typescript
import { UserService } from "./proto/gen/js/example/user/v1/user_connect.js";
import { ConnectRouter } from "@connectrpc/connect";

// Server implementation
const userServiceImpl: typeof UserService = {
  async createUser(req) {
    /* ... */
  },
  async getUser(req) {
    /* ... */
  },
  async updateUser(req) {
    /* ... */
  },
  async listUsers(req) {
    /* ... */
  },
};

// Client usage
const client = createPromiseClient(UserService, transport);
const user = await client.getUser({ id: "user-123" });
```

## Development Workflow

1. **Modify proto files** in the `proto/` directory
2. **Regenerate code** with `nix build`
3. **Type-check** with `npm run typecheck`
4. **Test changes** with server and client examples

## Learn More

- [Protobuf-ES Documentation](https://github.com/bufbuild/protobuf-es)
- [Connect-ES Documentation](https://connectrpc.com/docs/es)
- [Protovalidate Documentation](https://github.com/bufbuild/protovalidate)
- [Bufrnix Documentation](../../doc/)
