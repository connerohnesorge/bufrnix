# Specification: ts-proto Configuration Cleanup

## REMOVED Requirements

### Requirement: ts-proto tsconfig.json generation option

**Capability**: `generateTsConfig`

**Status**: REMOVED

**Reason**: Configuration files belong in the source project, not in generated code. This option violated separation of concerns and provided minimal value over users creating their own TypeScript configuration.

**Removed From**:
- Configuration schema: `src/lib/bufrnix-options.nix` (lines 1080-1084)
- Implementation: `src/languages/js/ts-proto.nix` (lines 88-109)
- Documentation: `examples/js-es-modules/README.md` (lines 142-145)

**Details**:
The `cfg.generateTsConfig` boolean option allowed automatic generation of a basic `tsconfig.json` file in the output directory when enabled. This has been completely removed because:

1. **Architectural concern**: Generated code should be ephemeral; configuration belongs with source
2. **Limited flexibility**: The generated template couldn't adapt to project-specific needs
3. **Maintenance cost**: Unnecessary configuration surface area for limited utility
4. **Modern alternatives**: Developers now prefer protobuf-es or manual TypeScript configuration

**Affected Configuration Paths**:
```nix
# No longer valid:
languages.js.tsProto.generateTsConfig = true/false

# Alternative 1: Use protobuf-es (recommended)
languages.js.es = { enable = true; target = "ts"; };

# Alternative 2: Create tsconfig.json in project root manually
# (Users are responsible for their own TypeScript configuration)
```

#### Scenario: User with existing generateTsConfig configuration

**Given**: A user has `languages.js.tsProto.generateTsConfig = true;` in their `flake.nix`

**When**: They update Bufrnix after this change is deployed

**Then**:
1. Nix evaluation fails with an unknown option error
2. User must remove the line from their configuration
3. User can either:
   - Switch to protobuf-es for modern TypeScript generation
   - Create their own `tsconfig.json` in project root
   - Use TypeScript with default settings from the language tool

**Accepted by**: Any user willing to remove one configuration line and potentially create their own tsconfig.json

#### Scenario: User relying on generated tsconfig.json

**Given**: A user relied on auto-generated `tsconfig.json` in `gen/js/` output directory

**When**: They regenerate code after this change

**Then**:
1. The `gen/js/tsconfig.json` file is no longer created
2. User must manually create `tsconfig.json` if needed in project root
3. TypeScript tools work with configuration from source project, not generated directory

**Accepted by**: Users willing to follow best practices of keeping config with source code

## Impact on Other Requirements

### No Impact On
- ✓ `languages.js.tsProto.enable` - Still required to enable ts-proto
- ✓ `languages.js.tsProto.options` - Configuration options still available
- ✓ `languages.js.tsProto.outputPath` - Output path configuration unchanged
- ✓ `languages.js.tsProto.generatePackageJson` - Separate independent option
- ✓ `languages.js.es` - Protobuf-ES generation unaffected
- ✓ `languages.js.connect` - Connect-ES generation unaffected
- ✓ `languages.js.grpcWeb` - gRPC-Web generation unaffected

### Breaking Change Scope
- **Severity**: Low (feature disabled by default)
- **Affected Users**: Only those with `generateTsConfig = true` in their config
- **Adoption Rate**: Low (minimal usage found in codebase)
- **Migration Effort**: Minimal (remove one config line, optionally create tsconfig.json)

## Validation Criteria

✓ Configuration option no longer appears in schema
✓ Code generation doesn't reference `cfg.generateTsConfig`
✓ No conditional blocks for tsconfig.json generation
✓ Example documentation reflects new reality
✓ All tests pass without the feature
✓ Nix evaluation succeeds without errors

## Specification Type

- **Change Category**: Configuration simplification / Technical debt reduction
- **Breaking**: Yes (removes public API option)
- **Feature Addition**: No (removal only)
- **Architecture Change**: No (simplification)
