# JavaScript ES Modules with Custom Output Path

This example demonstrates using a custom `outputPath` specifically for the ES modules plugin.

## Overview

This example shows how to configure JavaScript/TypeScript code generation with a plugin-specific output path, which is useful in monorepo scenarios where different code generation plugins need to output to different locations.

## Configuration

```nix
languages.js = {
  enable = true;
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
```

## Key Features

- **Plugin-specific output paths**: Set different output directories for different plugins
- **TypeScript target**: Generates `.ts` files with type definitions
- **ES modules**: Modern JavaScript with import/export syntax
- **JSON types**: Includes JSON type definitions for serialization

## Usage

```bash
# Generate TypeScript code
nix run

# View generated files
ls proto/gen/js/example/v1/
```

## Generated Files

- `proto/gen/js/example/v1/example_pb.ts` - Generated TypeScript protobuf messages

## Use Cases

This pattern is especially useful when:
- Working with monorepos where frontend and backend have different structure requirements
- Using multiple JS plugins (ES, gRPC-Web, Twirp) that need separate output locations
- Integrating with existing project structures that have specific directory conventions

## See Also

- [js-example](../js-example/) - Basic JavaScript example with default paths
- [js-grpc-web](../js-grpc-web/) - gRPC-Web example
