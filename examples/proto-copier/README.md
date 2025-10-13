# Proto Copier Example

This example demonstrates the **Proto Copier** functionality in Bufrnix, which allows you to declaratively copy Protocol Buffer files to multiple destinations without code generation. This is useful for:

- **Distributing proto files** to different services or teams
- **Creating client SDKs** with proto definitions
- **Synchronizing proto files** across microservices
- **Building proto file packages** for different environments
- **Organizing proto files** by access level or team

## 🏗️ Project Structure

```
proto-copier/
├── proto/                          # Source proto files
│   ├── api/v1/                     # Public API definitions
│   │   └── user_service.proto      # User service API
│   ├── common/v1/                  # Shared type definitions  
│   │   └── types.proto             # Common enums and messages
│   ├── external/v1/                # External integration APIs
│   │   └── webhook.proto           # Webhook service definitions
│   ├── internal/v1/                # Internal-only APIs
│   │   └── admin_service.proto     # Admin service (excluded from public copies)
│   └── test/                       # Test proto files
│       └── test_user.proto         # Test utilities (excluded from production)
├── flake.nix                       # Multiple example configurations
└── README.md                       # This file
```

## 📦 Available Examples

### 1. **Default** - Basic Proto Copying
```bash
nix run
```

**Configuration:**
- **Preserve structure**: ✅ Maintains directory hierarchy
- **Multiple destinations**: `backend/proto` and `frontend/src/proto`
- **Filters**: Excludes `test/**` and `internal/**` directories
- **Files**: All `.proto` files in the source directory

### 2. **Advanced Copy** - Multiple Destinations with Fine-Grained Control
```bash
nix run .#advanced-copy
```

**Configuration:**
- **Three destinations**: `public-api`, `shared-types`, `mobile-client`
- **Specific patterns**: Only API, common, and external proto files
- **Debug mode**: Enabled with verbose output
- **Smart filtering**: Excludes internal and test files

### 3. **Flattened Copy** - Single Directory with Transformations
```bash
nix run .#flattened-copy
```

**Configuration:**
- **Flattened structure**: All files copied to single directory
- **File transformations**: Adds `proto_` prefix and `_v1` suffix
- **Example**: `user_service.proto` → `proto_user_service_v1.proto`

### 4. **API-Only Copy** - Selective File Copying
```bash
nix run .#api-only-copy
```

**Configuration:**
- **Specific files**: Only `user_service.proto` and `types.proto`
- **Multiple destinations**: `api-client` and `sdk-generator`
- **Use case**: Creating minimal client libraries

### 5. **Proto + Go** - Multi-Language Generation
```bash
nix run .#proto-and-go
```

**Configuration:**
- **Proto copying**: Distributes proto files to multiple locations
- **Go code generation**: Generates gRPC Go code simultaneously
- **Demonstrates**: How proto copying works alongside other language modules

## 🚀 Quick Start

1. **Enter development environment:**
   ```bash
   nix develop
   ```

2. **Run basic example:**
   ```bash
   nix run
   ```

3. **View copied files:**
   ```bash
   tree output/
   ```

4. **Try different examples:**
   ```bash
   nix run .#advanced-copy
   nix run .#flattened-copy
   nix run .#api-only-copy
   nix run .#proto-and-go
   ```

## ⚙️ Configuration Reference

### Proto Copier Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Enable proto file copying |
| `outputPath` | `string \| string[]` | `["proto/copy"]` | Output destination(s) |
| `preserveStructure` | `bool` | `true` | Maintain directory hierarchy |
| `flattenFiles` | `bool` | `false` | Copy all files to output root |
| `includePatterns` | `string[]` | `["*.proto"]` | File patterns to include |
| `excludePatterns` | `string[]` | `[]` | File patterns to exclude |
| `filePrefix` | `string` | `""` | Prefix for copied file names |
| `fileSuffix` | `string` | `""` | Suffix for copied file names |

### Example Configuration

```nix
languages.proto = {
  enable = true;
  copier = {
    enable = true;
    outputPath = [
      "backend/proto"
      "frontend/src/proto"
      "mobile/proto"
    ];
    preserveStructure = true;
    includePatterns = [
      "api/**/*.proto"
      "common/**/*.proto"
    ];
    excludePatterns = [
      "**/internal/**"
      "**/test/**"
      "**/*_test.proto"
    ];
    filePrefix = "";
    fileSuffix = "_copy";
  };
};
```

## 📁 Output Examples

### Preserved Structure (Default)
```
output/backend/proto/
├── api/v1/
│   └── user_service.proto
├── common/v1/
│   └── types.proto
└── external/v1/
    └── webhook.proto
```

### Flattened Structure
```
output/flattened/
├── proto_user_service_v1.proto
├── proto_types_v1.proto
└── proto_webhook_v1.proto
```

## 🎯 Use Cases

### 1. **Microservice Proto Distribution**
Copy public API definitions to multiple services while excluding internal APIs.

### 2. **Client SDK Generation**
Distribute proto files to client teams for SDK generation in different languages.

### 3. **Mobile Development**
Copy mobile-relevant proto files to mobile development environments.

### 4. **Third-Party Integration**
Provide external partners with webhook and integration proto definitions.

### 5. **Multi-Environment Deployment**
Copy proto files with different filtering rules for development, staging, and production.

## 🔧 Advanced Features

### Pattern Matching
- **Glob patterns**: Use `**` for recursive matching
- **Negation**: Exclude patterns override include patterns
- **Flexible**: Support standard shell glob syntax

### File Transformations
- **Prefixes**: Add consistent prefixes to all copied files
- **Suffixes**: Add version or environment suffixes
- **Combine**: Use both prefixes and suffixes together

### Multiple Outputs
- **Different rules**: Each output can have different filtering
- **Parallel copying**: All destinations copied in single operation
- **Independent**: Each destination maintains separate directory structure

## 🧪 Testing

### Verify Basic Functionality
```bash
# Run basic copy
nix run

# Check output structure
tree output/backend/proto
tree output/frontend/src/proto

# Verify file content
cat output/backend/proto/api/v1/user_service.proto
```

### Test Advanced Features
```bash
# Test flattened copy with transformations
nix run .#flattened-copy
ls output/flattened/

# Test selective copying
nix run .#api-only-copy
find output/api-client -name "*.proto"
```

### Debug Mode
```bash
# Enable debug output
nix run .#advanced-copy
# Check for debug messages in output
```

## 🤝 Integration with Other Languages

The proto copier works seamlessly with other Bufrnix language modules:

```nix
languages = {
  # Copy proto files for distribution
  proto.copier = {
    enable = true;
    outputPath = ["clients/proto"];
  };
  
  # Generate Go code
  go = {
    enable = true;
    outputPath = "gen/go";
    grpc.enable = true;
  };
  
  # Generate TypeScript code
  js = {
    enable = true;
    outputPath = "gen/js";
    es.enable = true;
  };
};
```

## 🔍 Troubleshooting

### Common Issues

1. **No files copied**: Check `includePatterns` and `excludePatterns`
2. **Wrong directory structure**: Verify `preserveStructure` setting
3. **File not found**: Ensure source files exist in `sourceDirectories`
4. **Permission errors**: Check output directory permissions

### Debug Tips

1. **Enable debug mode**: Set `debug.enable = true`
2. **Use verbose output**: Set `debug.verbosity = 3`
3. **Check patterns**: Test glob patterns with standard shell tools
4. **Verify paths**: Ensure all paths are relative to project root

---

## 📚 Further Reading

- [Bufrnix Documentation](https://conneroisu.github.io/bufrnix/)
- [Language Modules Reference](https://conneroisu.github.io/bufrnix/reference/languages/)
- [Configuration Guide](https://conneroisu.github.io/bufrnix/reference/configuration/)
- [More Examples](https://github.com/conneroisu/bufrnix/tree/main/examples)

This example demonstrates the power and flexibility of Bufrnix's proto copier functionality. Use it as a starting point for your own proto file distribution needs!