# Design Document: Kotlin Build File Generation Removal

## Context

Bufrnix is a protocol buffer code generation framework. The Kotlin language module currently includes automatic `build.gradle.kts` generation as a feature. This document explains why removing this feature improves the overall system design.

## Problem Analysis

### Current Situation

The Kotlin module (`src/languages/kotlin/default.nix`) contains approximately 75 lines of template-based build file generation logic:

```nix
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
      # ... conditional plugin dependencies ...
  }
  # ... rest of template ...
  EOF
''}
```

**Key Issues**:

1. **Template Maintenance**: Keeping Gradle syntax current requires ongoing maintenance
   - Breaking Gradle API changes would require immediate updates
   - Plugin version discovery is hardcoded
   - Kotlin version compatibility must be managed

2. **Scope Creep**: Build system configuration is outside protocol buffer generation
   - Gradle is a complex system with many configuration patterns
   - Users have varying preferences for build organization
   - Template can't accommodate all use cases

3. **Testability**: Complex string interpolation is hard to test
   - No way to verify generated Gradle syntax is correct
   - Integration testing requires actual Gradle invocation
   - Changes are brittle and error-prone

4. **User Experience Mismatch**:
   - Most users already have `build.gradle.kts` in their projects
   - Auto-generation often overwrites user configuration
   - Creates cognitive overhead ("should I edit generated files?")

### Root Cause

Bufrnix expanded beyond its core mission:
- **Core Mission**: Compile `.proto` files to target language code
- **Scope Creep**: Generate build system configuration

This violates the Single Responsibility Principle.

## Design Goals

### Primary Goals

1. **Simplify Module Interface**: Reduce configuration options
2. **Focus on Core Mission**: Protocol buffer code generation only
3. **Improve Maintainability**: Remove template management burden
4. **Clarify Responsibility Boundaries**: Bufrnix ≠ build system manager

### Secondary Goals

1. **Reduce Code Complexity**: Remove 75 lines of template logic
2. **Improve User Experience**: Remove confusion about generated files
3. **Set Architectural Precedent**: Establish scope boundaries for future features

## Solution Design

### Remove `generateBuildFile` Option

**Scope**: Limit Kotlin language module to its core responsibility

**Changes**:
- Remove from schema (`bufrnix-options.nix`)
- Remove from module implementation (`kotlin/default.nix`)
- Update all examples and documentation

**Rationale**:
- Users maintain their own `build.gradle.kts` files
- Bufrnix handles proto compilation
- Clear separation of concerns

### What Remains

The Kotlin module still provides:
- Proto code generation (Java output)
- Kotlin-specific code generation
- gRPC support
- Connect RPC support
- Output directory creation
- Plugin orchestration

**This is sufficient** for most users' needs.

### What Gets Removed

Only automatic build file generation:
- `build.gradle.kts` template
- `settings.gradle.kts` template
- Gradle configuration option handling
- Template interpolation logic

**Impact**: Users manually create these files (which they often already have)

## Alternative Solutions Considered

### Alternative 1: Keep as Deprecated Option

**Pros**:
- Gradual migration path
- Users have time to adapt

**Cons**:
- Extends maintenance burden for 2+ releases
- Code remains cluttered during deprecation period
- False signal that feature might return

**Decision**: Rejected - pre-1.0 project can make breaking changes

### Alternative 2: Move to Post-Generation Hook

**Pros**:
- Separates template from core logic
- More flexible

**Cons**:
- Hook system becomes cluttered with build logic
- Still requires maintaining Gradle templates
- Doesn't solve scope creep problem
- Complicates hook implementation

**Decision**: Rejected - doesn't address root cause

### Alternative 3: Generic Template System

**Pros**:
- Could support multiple build systems
- More flexible for power users

**Cons**:
- Significantly increases complexity
- Requires template engine integration
- Over-engineers the solution
- Still outside Bufrnix's core mission

**Decision**: Rejected - too complex for marginal benefit

### Alternative 4: Remove Completely (Selected)

**Pros**:
- Simplifies architecture immediately
- Clear scope boundaries
- Reduces maintenance burden
- Users maintain their own build files (which they prefer)

**Cons**:
- Breaking change for users relying on this feature
- Users need to create build files manually (not difficult)

**Decision**: Selected - aligns with core mission, marginal migration cost

## Impact Analysis

### User Impact

**Affected Users**: Only those with `generateBuildFile = true` in their config

**Estimated Impact**: Low
- Feature is not mentioned prominently in documentation
- Kotlin examples don't rely on it
- Most users already maintain build files

**Migration Path**:
1. Remove `generateBuildFile = true;` from flake.nix
2. Create/maintain `build.gradle.kts` manually
3. No changes to proto code generation

**Time to Migrate**: 5-15 minutes per project

### System Impact

**Code Changes**:
- `-` 75 lines (build file template)
- `-` 5 lines (schema option)
- `-` 5 references in examples/docs
- `~` 85 lines total removed
- `~` 0 new lines added

**Test Impact**:
- No new tests needed
- Existing tests become simpler
- Examples still pass with fewer files generated

**Documentation Impact**:
- Remove build file generation mention
- Simplify configuration examples
- Add note about manual build file creation

## Implementation Strategy

### Phase 1: Remove from Core (Schema + Module)
- Update schema
- Update module implementation
- Ensure examples still validate

### Phase 2: Update Examples and Docs
- Remove options from all examples
- Update configuration reference
- Update any guides that mention the feature

### Phase 3: Testing and Validation
- Run full test suite
- Verify Kotlin examples work
- Check for any lingering references

### Phase 4: Documentation Pass
- Review all documentation
- Ensure consistency
- Add migration notes if needed

## Architectural Principles This Reinforces

### Single Responsibility Principle
Bufrnix should focus on protocol buffer code generation, not build system configuration.

### Tool Composition Pattern
Users should compose Bufrnix with their own build tools rather than Bufrnix including them.

### Explicit Over Implicit
Build configuration should be explicit (user-created files) rather than implicit (auto-generated).

## Future Implications

### What This Establishes

1. **Scope Boundary**: Bufrnix generates code, users configure builds
2. **Feature Bar**: New features must align with core mission
3. **Complexity Threshold**: Remove low-value complex features
4. **User Preference**: Users prefer explicit control

### If Similar Issues Arise

Future scope-creep decisions should reference this precedent:
- "Bufrnix focuses on code generation, not build system management"
- "Users should maintain system configuration files explicitly"
- "Remove features that complicate the module interface"

## Open Questions

1. **Scala Module**: Should Scala's `generateBuildFile` also be removed?
   - Currently retained because Scala ecosystem handles this differently
   - Decision: Keep for now, revisit separately if needed

2. **User Feedback**: Would deprecation be better than immediate removal?
   - Answer: Pre-1.0 allows breaking changes; immediate removal is acceptable

3. **Post-Generation Hooks**: Should we enhance these for build file generation?
   - Answer: Users can create wrapper scripts if needed; out of scope

4. **Documentation**: How much migration guide is needed?
   - Answer: Brief note; migration is straightforward

## Success Metrics

### Technical Success
- ✅ Module size reduced by ~80 lines
- ✅ Configuration options reduced by 1
- ✅ No references to removed feature remain
- ✅ All tests pass

### User Experience Success
- ✅ Documentation is clear about expectations
- ✅ Migration path is obvious
- ✅ Kotlin code generation still works perfectly
- ✅ No unexpected file deletions or overwrites

### Architectural Success
- ✅ Scope boundary is clear
- ✅ Single Responsibility Principle is respected
- ✅ System is simpler to maintain
- ✅ Future features align with core mission

## Conclusion

Removing `generateBuildFile` from the Kotlin module improves Bufrnix's architecture by:

1. **Clarifying Scope**: Bufrnix = proto code generation, not build system management
2. **Reducing Complexity**: 80 fewer lines of template logic to maintain
3. **Improving Maintainability**: No Gradle syntax to keep current
4. **Better User Experience**: Clear expectations about what Bufrnix does

The marginal cost to users (creating their own build files) is outweighed by the architectural benefits and long-term maintainability gains.

This sets a healthy precedent for keeping Bufrnix focused on its core mission.
