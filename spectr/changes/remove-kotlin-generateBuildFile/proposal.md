# Proposal: Remove cfg.generateBuildFile from Kotlin Language Module

**Change ID**: `remove-kotlin-generateBuildFile`

**Status**: Proposed

**Date**: 2025-11-13

## Summary

Remove the `generateBuildFile` configuration option from the Kotlin language module (`src/languages/kotlin/default.nix`) and all references in configuration schemas, examples, and documentation. This simplifies the Kotlin configuration by eliminating the automatic build file generation feature that is rarely used and adds maintenance complexity.

## Problem Statement

The Kotlin language module currently includes a `generateBuildFile` option that:
- Automatically generates `build.gradle.kts` and `settings.gradle.kts` files
- Requires maintaining complex template logic within the Nix module
- Adds configuration state that complicates the module interface
- Is duplicated across Kotlin and Scala language modules
- Provides limited value since users typically manage their build files directly

Users prefer to manage Gradle build configuration themselves, making this automatic generation feature rarely used and a source of potential maintenance burden.

## Scope

### Affected Components

1. **Configuration Schema** (`src/lib/bufrnix-options.nix`):
   - Remove `kotlin.generateBuildFile` option definition (line 2139-2143)

2. **Kotlin Language Module** (`src/languages/kotlin/default.nix`):
   - Remove `generateBuildFile` condition from `initHooks` (lines 80-154)
   - Remove `cat > build.gradle.kts` template generation
   - Remove `cat > settings.gradle.kts` template generation

3. **Examples**:
   - `examples/kotlin-basic/flake.nix`: Remove `generateBuildFile = true;` configuration
   - `examples/kotlin-grpc/flake.nix`: Remove `generateBuildFile = true;` configuration

4. **Documentation**:
   - `doc/src/content/docs/reference/languages/kotlin.x-basic-configuration.nix`: Update example configuration
   - `examples/kotlin-basic/README.md`: Update documentation reference if present

## Rationale

### Why Remove This Feature

1. **Limited Usage**: The automatic build file generation is rarely used by practitioners who prefer explicit control
2. **Maintenance Burden**: Requires keeping Gradle template syntax current across Kotlin/Gradle versions
3. **Design Clarity**: Bufrnix's core responsibility is protobuf code generation, not build system management
4. **Consistency**: Users already manage their project structure; auto-generation creates inconsistency
5. **Simplification**: Reduces configuration options and module complexity

### Why This Change Is Safe

1. **Backward-Compatible Alternative**: Users can easily create their own `build.gradle.kts` files
2. **No Generated Code Loss**: Proto files are still generated; only build template generation is removed
3. **Clear Migration Path**: Examples can document manual build file setup instead
4. **Isolated Impact**: Only affects Kotlin; doesn't impact other languages (Scala retains its option by choice)

## Detailed Changes

### 1. Configuration Schema Change

**File**: `src/lib/bufrnix-options.nix`

Remove the `generateBuildFile` mkOption definition from the `kotlin` configuration section.

### 2. Kotlin Module Simplification

**File**: `src/languages/kotlin/default.nix`

Simplify the `initHooks` section by removing all conditional blocks guarded by `optionalString cfg.generateBuildFile`.

**Before**: 83 lines of template-based build file generation
**After**: Minimal initialization hook focused only on creating output directories

### 3. Example Updates

**Files**:
- `examples/kotlin-basic/flake.nix`
- `examples/kotlin-grpc/flake.nix`

Remove the `generateBuildFile = true;` line from each Kotlin example configuration.

### 4. Documentation Updates

**Files**:
- `doc/src/content/docs/reference/languages/kotlin.x-basic-configuration.nix`
- Update any README references

Update code examples and configuration snippets to remove `generateBuildFile` references.

## Dependencies and Constraints

- **No external dependencies**: This is a purely internal change
- **No breaking changes for users who don't use generateBuildFile**: Unaffected
- **Minimal migration for users using generateBuildFile**: Simply remove the option and provide custom build files

## Validation Plan

1. **Schema Validation**: Run `openspec validate remove-kotlin-generateBuildFile --strict`
2. **Example Validation**: Run `./check-examples.sh` to ensure Kotlin examples still work
3. **Comprehensive Testing**: Run `./test-examples.sh` to validate all Kotlin variants
4. **Manual Testing**: Verify that Kotlin examples generate code correctly without build files

## Related Changes

- **Not affected**: Scala module retains its `generateBuildFile` option (different design decision)
- **Not affected**: Other language modules (no similar feature)

## Future Considerations

- Users needing auto-generated build files can create wrapper tools or Nix functions
- Build file generation could be added as an optional post-generation hook in the future if demand warrants
- This sets precedent for removing rarely-used configuration complexity

## Questions for Stakeholders

1. Are there known users relying on the `generateBuildFile` option?
2. Should we provide migration documentation for existing users?
3. Would a deprecation period be beneficial before removal?

## Notes

- This proposal focuses solely on Kotlin's `generateBuildFile` option
- Scala's `generateBuildFile` is retained because it serves a different role in that ecosystem
- The change aligns Bufrnix with its core responsibility: protocol buffer code generation
