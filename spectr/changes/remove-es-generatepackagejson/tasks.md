# Implementation Tasks: Remove generatePackageJson Feature

## Task Breakdown

### Phase 1: Schema and Implementation Removal

#### Task 1.1: Remove configuration options from bufrnix-options.nix
- **Status**: Pending
- **Description**: Remove the following options from `src/lib/bufrnix-options.nix`:
  - `languages.js.es.generatePackageJson` boolean option
  - `languages.js.es.packageName` string option
  - `languages.js.connect.generatePackageJson` boolean option
  - `languages.js.connect.packageName` string option
  - `languages.js.tsProto.generatePackageJson` boolean option
  - `languages.js.tsProto.packageName` string option
- **Verification**: Run `nix flake check` to ensure schema is valid
- **Duration**: 30 minutes
- **Dependencies**: None

#### Task 1.2: Remove package.json generation from src/languages/js/default.nix
- **Status**: Pending
- **Description**:
  - Remove the `optionalString (cfg.es.enable && cfg.es.generatePackageJson)` block from generateHooks
  - Simplify the ES modules initialization and generation logic
  - Add comment explaining that package.json should be managed by project
- **Verification**:
  - Syntax check with `nix fmt`
  - Build check: `nix build .#packages.x86_64-linux.default`
- **Duration**: 20 minutes
- **Dependencies**: Task 1.1

#### Task 1.3: Remove package.json generation from src/languages/js/ts-proto.nix
- **Status**: Pending
- **Description**:
  - Remove the `optionalString (cfg.generatePackageJson or false)` block from generateHooks
  - Remove any references to `cfg.packageName` from package.json template
  - Simplify hook logic
- **Verification**:
  - Syntax check with `nix fmt`
  - Module loads without errors
- **Duration**: 15 minutes
- **Dependencies**: Task 1.1

#### Task 1.4: Check connect.nix for similar changes
- **Status**: Pending
- **Description**:
  - Review `src/languages/js/connect.nix`
  - If it has generatePackageJson logic, remove it following the same pattern
  - If it doesn't exist yet, create a note
- **Verification**: Identify if changes needed
- **Duration**: 10 minutes
- **Dependencies**: None

### Phase 2: Example Projects Update

#### Task 2.1: Update examples/js-es-modules/flake.nix
- **Status**: Pending
- **Description**:
  - Remove `generatePackageJson = true;` from es config
  - Remove `packageName = "@example/proto";` from es config
  - Keep other ES module configuration intact
- **Verification**: Config syntax valid
- **Duration**: 10 minutes
- **Dependencies**: Task 1.1

#### Task 2.2: Create/Update examples/js-es-modules/package.json
- **Status**: Pending
- **Description**:
  - Create or update `examples/js-es-modules/package.json` with proper ES modules configuration
  - Include @bufbuild/protobuf as dependency
  - Ensure "type": "module" is set
- **Verification**: File exists and has valid JSON
- **Duration**: 10 minutes
- **Dependencies**: Task 2.1

#### Task 2.3: Update examples/js-es-modules/README.md
- **Status**: Pending
- **Description**:
  - Add section explaining that package.json is now user-managed
  - Reference migration guide
  - Show package.json structure
- **Verification**: Markdown renders correctly
- **Duration**: 10 minutes
- **Dependencies**: Task 2.2

#### Task 2.4: Update examples/ts-flake-parts/flake.nix
- **Status**: Pending
- **Description**:
  - Remove `generatePackageJson = true;` from es config
  - Remove `packageName = "@example/proto-ts";` from es config
- **Verification**: Config syntax valid
- **Duration**: 10 minutes
- **Dependencies**: Task 1.1

#### Task 2.5: Create/Update examples/ts-flake-parts/package.json
- **Status**: Pending
- **Description**:
  - Create or update `examples/ts-flake-parts/package.json`
  - Include proper TypeScript build configuration
  - Include Protobuf-ES dependencies
- **Verification**: File exists and has valid JSON
- **Duration**: 10 minutes
- **Dependencies**: Task 2.4

#### Task 2.6: Update examples/ts-flake-parts/README.md
- **Status**: Pending
- **Description**:
  - Add explanation of user-managed package.json
  - Reference migration guide
- **Verification**: Documentation complete
- **Duration**: 10 minutes
- **Dependencies**: Task 2.5

### Phase 3: Documentation Updates

#### Task 3.1: Remove generatePackageJson from reference/configuration.mdx
- **Status**: Pending
- **Description**:
  - Search for all instances of `generatePackageJson` in configuration.mdx
  - Remove lines showing this option in examples
  - Update configuration structure documentation if needed
- **Verification**:
  - No remaining references to `generatePackageJson`
  - Documentation builds successfully
- **Duration**: 15 minutes
- **Dependencies**: Task 1.1

#### Task 3.2: Remove generatePackageJson from reference/languages.mdx
- **Status**: Pending
- **Description**:
  - Search for all instances of `generatePackageJson` in languages.mdx
  - Remove from all language examples (es, connect, tsProto)
  - Remove packageName references
- **Verification**:
  - No remaining references to `generatePackageJson`
  - Language documentation is still complete
- **Duration**: 15 minutes
- **Dependencies**: Task 1.1

#### Task 3.3: Remove generatePackageJson from guides/troubleshooting.mdx
- **Status**: Pending
- **Description**:
  - Remove references to generatePackageJson in troubleshooting guide
  - Remove packageName examples
- **Verification**: No stale references remain
- **Duration**: 10 minutes
- **Dependencies**: Task 1.1

#### Task 3.4: Create migration guide
- **Status**: Pending
- **Description**:
  - Create `doc/src/content/docs/guides/migrating-from-generatepackagejson.mdx`
  - Document the change and why it was made
  - Provide before/after examples
  - Show how to create package.json files for different scenarios:
    - Protobuf-ES
    - ts-proto
    - Connect protocol
- **Verification**:
  - Guide is comprehensive
  - Examples are valid JSON/Nix
  - Documentation builds
- **Duration**: 30 minutes
- **Dependencies**: Task 3.1, Task 3.2

#### Task 3.5: Update main configuration guide
- **Status**: Pending
- **Description**:
  - Review main configuration documentation
  - Add note that package.json is user-managed
  - Link to migration guide if applicable
- **Verification**: Documentation is accurate
- **Duration**: 10 minutes
- **Dependencies**: Task 3.4

### Phase 4: Testing and Validation

#### Task 4.1: Run test-examples.sh to verify no breakage
- **Status**: Pending
- **Description**:
  - Run `./test-examples.sh` to test all 25+ examples
  - Verify js-es-modules example works
  - Verify ts-flake-parts example works
  - Ensure no generated package.json files appear
- **Verification**:
  - All examples pass
  - No package.json files in generated output
- **Duration**: 45 minutes (depends on system performance)
- **Dependencies**: All previous phases

#### Task 4.2: Run nix fmt and lint
- **Status**: Pending
- **Description**:
  - Run `nix fmt` to ensure all files are properly formatted
  - Run `lint` command to check for Nix issues
- **Verification**:
  - No formatting issues
  - No linting errors
- **Duration**: 10 minutes
- **Dependencies**: All previous phases

#### Task 4.3: Build documentation
- **Status**: Pending
- **Description**:
  - Run `cd doc && bun run build` to build documentation
  - Verify no broken links or errors
- **Verification**:
  - Documentation builds successfully
  - Migration guide is accessible
- **Duration**: 5 minutes
- **Dependencies**: Phase 3

#### Task 4.4: Create git commit with all changes
- **Status**: Pending
- **Description**:
  - Stage all changes
  - Create commit with descriptive message
  - Follow project commit conventions
  - Reference this change ID in commit message
- **Verification**:
  - Commit is successful
  - Commit message is clear
- **Duration**: 5 minutes
- **Dependencies**: Task 4.1, 4.2, 4.3

### Phase 5: Release and Communication

#### Task 5.1: Document breaking change in CHANGELOG
- **Status**: Pending (post-implementation)
- **Description**:
  - Add entry to CHANGELOG documenting removal
  - Note migration path
  - Link to migration guide
- **Verification**: CHANGELOG updated
- **Duration**: 10 minutes
- **Dependencies**: Task 4.4

#### Task 5.2: Create GitHub release notes
- **Status**: Pending (post-implementation)
- **Description**:
  - Prepare release notes highlighting the breaking change
  - Include migration instructions
  - Mention benefits of the change
- **Duration**: 15 minutes
- **Dependencies**: Task 5.1

---

## Summary Statistics

- **Total Tasks**: 25
- **Estimated Time**: ~4 hours
- **Critical Path**: Task 1.1 → 1.2 → 1.3 → Tests → Commit
- **Parallelizable**:
  - Phase 2 tasks can run in parallel (after Task 1.1)
  - Phase 3 tasks can run in parallel (after Task 1.1)
  - Task 4.1 must run sequentially (depends on all others)

## Rollout Strategy

1. **All-at-once**: Complete all tasks in single PR
2. **Rationale**: This is a hard breaking change; better to communicate clearly with one comprehensive update
3. **Release**: Include in next minor version bump with migration guide
