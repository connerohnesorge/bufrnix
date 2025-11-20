# Specification: Remove Kotlin Build File Generation

**Capability**: Remove automatic `build.gradle.kts` generation from Kotlin language module

**Status**: Proposed

## Overview

This specification defines the removal of the `generateBuildFile` configuration option and all related build file generation logic from the Kotlin language module in Bufrnix.

## Current Behavior

### What Currently Exists

1. **Configuration Option**: `languages.kotlin.generateBuildFile` (boolean, default: true)
2. **Generated Files**:
   - `build.gradle.kts` (Gradle build file with Kotlin configuration)
   - `settings.gradle.kts` (Gradle settings file)
3. **Features**:
   - Automatic inclusion of protobuf-gradle plugin configuration
   - Conditional inclusion of gRPC plugin configuration
   - Conditional inclusion of Connect RPC plugin configuration
   - Management of Kotlin and Protobuf dependency versions

### Code Locations

- **Schema Definition**: `src/lib/bufrnix-options.nix:2139-2143`
- **Implementation**: `src/languages/kotlin/default.nix:80-154`
- **Examples Using Feature**:
  - `examples/kotlin-basic/flake.nix`
  - `examples/kotlin-grpc/flake.nix`

## Desired Behavior

### REMOVED Requirements

#### Requirement: Automatic Build File Generation
The system shall **NOT** automatically generate `build.gradle.kts` files during Kotlin code generation.

**Rationale**:
- Build file management is outside Bufrnix's core responsibility (protocol buffer code generation)
- Users prefer explicit control over build configuration
- Automatic generation complicates the module interface
- Reduces maintenance burden of keeping Gradle syntax current

#### Scenario: User attempts to use generateBuildFile option
```nix
languages.kotlin = {
  enable = true;
  generateBuildFile = true;  # This option no longer exists
};
```
**Expected**: Configuration validation error indicating `generateBuildFile` is not a valid option

#### Scenario: Code generation without build files
```nix
languages.kotlin = {
  enable = true;
  outputPath = "gen/kotlin";
  javaOutputPath = "gen/kotlin/java";
  kotlinOutputPath = "gen/kotlin/kotlin";
  # generateBuildFile option not specified
};
```
**Expected**:
- Proto files are successfully compiled to Java and Kotlin
- Output directories are created as configured
- No `build.gradle.kts` or `settings.gradle.kts` files are generated
- Generation completes without warnings

#### Scenario: Users managing their own build files
```
project/
├── build.gradle.kts        (user-created)
├── settings.gradle.kts     (user-created)
├── flake.nix
└── proto/
    └── example.proto
```
**Expected**:
- Bufrnix generates only proto code (Java/Kotlin files)
- User's existing build files remain untouched
- No conflicts or file overwrites

### RETAINED Requirements

The following Kotlin features are **NOT** affected and continue to work:

#### Requirement: Proto Code Generation
Proto files shall still be compiled to Java and Kotlin output.

**Rationale**: This is Bufrnix's core responsibility

#### Scenario: Basic Kotlin generation
```nix
languages.kotlin = {
  enable = true;
  outputPath = "gen/kotlin";
  javaOutputPath = "gen/kotlin/java";
  kotlinOutputPath = "gen/kotlin/kotlin";
};
```
**Expected**: Proto files compiled to both Java and Kotlin

#### Requirement: gRPC Support
Kotlin gRPC code generation shall continue to work when enabled.

**Scenario**: gRPC Kotlin generation
```nix
languages.kotlin = {
  enable = true;
  grpc.enable = true;
};
```
**Expected**: gRPC Kotlin code is generated alongside proto messages

#### Requirement: Connect RPC Support
Kotlin Connect RPC code generation shall continue to work when enabled.

**Scenario**: Connect RPC Kotlin generation
```nix
languages.kotlin = {
  enable = true;
  connect.enable = true;
};
```
**Expected**: Connect RPC Kotlin code is generated alongside proto messages

## Breaking Changes

### Configuration Option Removal

The `languages.kotlin.generateBuildFile` configuration option is **completely removed**.

**Impact Level**: Low
- Default was `true`, but most users don't explicitly set this option
- Users relying on this feature can manually create `build.gradle.kts` files
- No proto code generation is affected

**Migration Path for Affected Users**:
1. Remove `generateBuildFile` from flake.nix configuration
2. Create `build.gradle.kts` manually with desired Gradle configuration
3. Re-run `nix run` to generate proto code (now only)

## Implementation Details

### Files to Modify

1. **`src/lib/bufrnix-options.nix`**
   - Remove: `kotlin.generateBuildFile` option definition (lines 2139-2143)

2. **`src/languages/kotlin/default.nix`**
   - Simplify: `initHooks` section
   - Remove: All `optionalString cfg.generateBuildFile` blocks (lines 80-154)
   - Keep: Directory creation logic (`mkdir -p` commands)

3. **`examples/kotlin-basic/flake.nix`**
   - Remove: `generateBuildFile = true;` configuration line

4. **`examples/kotlin-grpc/flake.nix`**
   - Remove: `generateBuildFile = true;` configuration line

5. **`doc/src/content/docs/reference/languages/kotlin.x-basic-configuration.nix`**
   - Remove: `generateBuildFile = true;` from example configuration

6. **`examples/kotlin-basic/README.md`** (if exists)
   - Update: Remove any mention of automatic build file generation

### Module Structure After Change

**Before**: initHooks includes ~75 lines of build file template generation

**After**: initHooks only includes:
```bash
mkdir -p "${javaOutputPath}"
mkdir -p "${kotlinOutputPath}"
```

This simplifies the module from 195 lines to approximately 120 lines.

## Validation Criteria

### Schema Validation
- [ ] `src/lib/bufrnix-options.nix` contains no reference to `kotlin.generateBuildFile`
- [ ] Schema compiles without errors
- [ ] Configuration validation rejects `generateBuildFile` option

### Module Validation
- [ ] `src/languages/kotlin/default.nix` contains no reference to `generateBuildFile`
- [ ] Module syntax is valid Nix
- [ ] Output structure remains compatible with existing code

### Example Validation
- [ ] `examples/kotlin-basic` builds successfully with `nix run`
- [ ] `examples/kotlin-grpc` builds successfully with `nix run`
- [ ] Both examples generate proto code correctly
- [ ] Neither example generates build files

### Integration Validation
- [ ] `nix flake check` passes
- [ ] `./test-examples.sh` passes for Kotlin examples
- [ ] `./check-examples.sh` passes
- [ ] All references to `generateBuildFile` are removed

## Related Specifications

### Not Affected
- **Scala Language Module**: Scala's `generateBuildFile` is **retained** (separate decision)
- **Other Languages**: No other language modules use this pattern

### Future Considerations
- Build file generation could be implemented as optional post-generation hooks
- Users needing auto-generation can create wrapper Nix functions

## Design Rationale

### Why Remove Instead of Deprecate?

1. **Minimal Impact**: Very few users rely on this feature
2. **Clear Benefits**: Simplifies module interface significantly
3. **Design Alignment**: Bufrnix's core mission is protobuf code generation
4. **Low Migration Cost**: Users can easily create build files manually

### Why Not Use Post-Generation Hooks?

While post-generation hooks could theoretically generate build files, this approach:
- Overcomplicates the hook system with template logic
- Doesn't improve the user experience significantly
- Still requires managing Gradle syntax in Nix code

### Why Not Follow Scala's Pattern?

Scala's use case is different:
- Scala traditionally relies on build configuration via `build.sbt`
- The Scala ecosystem has stronger patterns for build automation
- ScalaPB generates configuration directly into `build.sbt`
- Kotlin/Gradle workflows are typically more manual

Kotlin is better served by allowing users explicit control.

## Questions and Answers

**Q: What about users who depend on automatic build file generation?**
A: They can manually create `build.gradle.kts` files following Gradle's standard patterns. The generated proto code will work with any valid build configuration.

**Q: Why not deprecate first?**
A: The feature is rarely used (minimal examples don't rely on it), and Bufrnix is pre-1.0, so breaking changes are acceptable for design improvements.

**Q: Could this be added back as an optional plugin?**
A: Potentially, but it's outside Bufrnix's core scope. Users needing this can create their own wrapper tooling.

**Q: Does this affect proto code generation quality?**
A: No. Only the build file generation is removed. Proto compilation is unaffected.

## Success Criteria (For Merging)

All of the following must be true:

1. ✅ No reference to `generateBuildFile` remains in Kotlin code
2. ✅ All Kotlin examples pass `./test-examples.sh`
3. ✅ Schema validation passes
4. ✅ `nix flake check` passes
5. ✅ Documentation is updated
6. ✅ Generated proto code is identical (before/after)
7. ✅ No unintended changes to other language modules
