# Proposal: Remove cfg.generateTsConfig from ts-proto.nix

**Change ID**: `remove-ts-proto-generatetsconfig`

**Status**: Draft

**Author**: Claude Code

**Date**: 2025-11-13

## Why

The `generateTsConfig` option violates architectural principles by:

1. **Scope mismatch**: Configuration belongs with source code, not generated code
2. **Poor defaults**: Generic template doesn't adapt to project-specific needs
3. **Maintenance burden**: Unnecessary configuration option with low utility
4. **Better alternatives**: Modern options (protobuf-es) eliminate the need

## Executive Summary

Remove the `generateTsConfig` configuration option from the ts-proto language module. This option generates a basic `tsconfig.json` file in the generated code output directory, but:

1. **Scope mismatch**: Generating configuration files belongs with the source project, not the generated code
2. **User control**: Developers should maintain their own `tsconfig.json` in their source
3. **Simplification**: Reduces configuration surface area with minimal user impact
4. **Alternative exists**: Users can easily create their own `tsconfig.json` or use ts-proto's existing TypeScript options

## Problem Statement

The `generateTsConfig` option in ts-proto encourages putting configuration in generated code, which violates separation of concerns:

- Generated code should be ephemeral and replaceable
- TypeScript configuration belongs in the source project root
- The generated `tsconfig.json` is a generic template that doesn't account for project-specific needs
- Users can already rely on protobuf-es or other TypeScript generators that don't need this option

## What Changes

**Fully remove** the `generateTsConfig` option by:

1. Removing the option definition from `src/lib/bufrnix-options.nix` (lines 1080-1084)
2. Removing the conditional generation block from `src/languages/js/ts-proto.nix` (lines 88-109)
3. Updating the README example in `examples/js-es-modules/README.md` to remove references
4. Verifying all tests pass without the option

## Impact Analysis

### Breaking Change
**Yes** - This removes a public configuration option. Users who rely on `generateTsConfig = true` will need to:
- Remove that line from their Nix configuration
- Create their own `tsconfig.json` in their project root if needed

### Affected Areas
- **Configuration**: 1 option definition (in bufrnix-options.nix)
- **Implementation**: 1 conditional block (in ts-proto.nix)
- **Documentation**: 1 README file with example usage
- **Tests**: No dedicated tests found for this option

### User Impact
- Low impact overall since this is an optional feature (default: `false`)
- Users actively using this option will need to add their own `tsconfig.json`
- Alternative: Use protobuf-es or other generators (already available in Bufrnix)

## Rationale

1. **Principle of Least Surprise**: Generated code shouldn't generate non-code configuration
2. **Maintainability**: One less configuration option to maintain and document
3. **Best Practices**: Encourages proper project structure with source-level configuration
4. **User Agency**: Developers should control their own TypeScript configuration
5. **Language Alignment**: Matches approach of other language modules (Go, Python, etc.)

## Migration Path

Users with `generateTsConfig = true` in their flake.nix can:

```nix
# Before (will no longer work)
tsProto = {
  enable = true;
  generateTsConfig = true;
};

# After (recommended)
# Create tsconfig.json in your project root with appropriate settings
# Or use protobuf-es instead, which is the modern recommended approach
es = {
  enable = true;
  target = "ts";
};
```

## Acceptance Criteria

- [ ] Option removed from `bufrnix-options.nix`
- [ ] Conditional block removed from `ts-proto.nix`
- [ ] README example updated or removed
- [ ] All tests pass (`./test-examples.sh` and `./check-examples.sh`)
- [ ] No compilation errors in Nix
- [ ] No validation errors with `openspec validate`

## See Also

- Related change: `remove-es-generatepackagejson` (similar cleanup for protobuf-es)
- Related change: `remove-js-grpc-web` (archived language module)
- Configuration reference: `src/lib/bufrnix-options.nix`
- Implementation reference: `src/languages/js/ts-proto.nix`
