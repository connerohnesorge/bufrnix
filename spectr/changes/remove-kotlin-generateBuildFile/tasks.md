# Task Breakdown: Remove cfg.generateBuildFile from Kotlin

## Overview
Remove the `generateBuildFile` configuration option and all build file generation logic from the Kotlin language module and all references.

## Ordered Task List

### Phase 1: Schema Removal (Foundation)

**Task 1.1**: Remove `generateBuildFile` option from configuration schema
- **File**: `src/lib/bufrnix-options.nix`
- **Change**: Remove lines 2139-2143 (the `generateBuildFile` mkOption definition)
- **Validation**: Schema still compiles; no syntax errors in modified file
- **Depends on**: None

### Phase 2: Module Simplification (Core Implementation)

**Task 2.1**: Remove build file generation from Kotlin module
- **File**: `src/languages/kotlin/default.nix`
- **Change**:
  - Remove all `optionalString cfg.generateBuildFile` blocks from `initHooks`
  - Keep directory creation (`mkdir -p "${javaOutputPath}"` and `mkdir -p "${kotlinOutputPath}"`)
  - Remove lines 80-154 (entire build file generation section)
- **Validation**:
  - Module syntax is valid
  - `nix develop` still works in kotlin examples
  - No reference to `generateBuildFile` remains in the file
- **Depends on**: Task 1.1

**Task 2.2**: Verify no dangling references in module
- **File**: `src/languages/kotlin/default.nix`
- **Validation**: Run `grep -n "generateBuildFile" src/languages/kotlin/default.nix` returns no results
- **Depends on**: Task 2.1

### Phase 3: Example Updates (User-Facing)

**Task 3.1**: Update kotlin-basic example configuration
- **File**: `examples/kotlin-basic/flake.nix`
- **Change**: Remove line with `generateBuildFile = true;`
- **Validation**:
  - `nix flake check` in the example directory succeeds
  - Configuration is still valid
- **Depends on**: Task 1.1

**Task 3.2**: Update kotlin-grpc example configuration
- **File**: `examples/kotlin-grpc/flake.nix`
- **Change**: Remove line with `generateBuildFile = true;`
- **Validation**:
  - `nix flake check` in the example directory succeeds
  - Configuration is still valid
- **Depends on**: Task 1.1

**Task 3.3**: Update kotlin example README documentation
- **File**: `examples/kotlin-basic/README.md` (if present)
- **Change**: Remove any references to `generateBuildFile` configuration
- **Validation**: README is still valid Markdown; no broken references
- **Depends on**: Task 3.1

### Phase 4: Documentation Updates (Reference)

**Task 4.1**: Update Kotlin configuration reference documentation
- **File**: `doc/src/content/docs/reference/languages/kotlin.x-basic-configuration.nix`
- **Change**: Remove `generateBuildFile = true;` from the example configuration
- **Validation**:
  - File is valid Nix syntax
  - Example configuration is complete and functional
  - No reference to removed option remains
- **Depends on**: Task 1.1

**Task 4.2**: Update Kotlin language reference guide (if exists)
- **File**: `doc/src/content/docs/reference/languages/kotlin.md` (if present)
- **Change**: Remove any mentions of `generateBuildFile` feature
- **Validation**: Documentation builds without errors; no broken links to removed feature
- **Depends on**: Task 4.1

### Phase 5: Testing & Validation (Verification)

**Task 5.1**: Run Kotlin basic example test
- **Command**: `cd examples/kotlin-basic && nix develop && nix run`
- **Validation**:
  - Example builds without errors
  - Proto files are generated correctly
  - No build.gradle.kts is generated (expected behavior)
  - Java and Kotlin output directories exist
- **Depends on**: Tasks 2.1, 3.1

**Task 5.2**: Run Kotlin gRPC example test
- **Command**: `cd examples/kotlin-grpc && nix develop && nix run`
- **Validation**:
  - Example builds without errors
  - Proto files with gRPC are generated correctly
  - Java and Kotlin output directories exist
- **Depends on**: Tasks 2.1, 3.2

**Task 5.3**: Run comprehensive example test suite
- **Command**: `./test-examples.sh` (filter for kotlin examples)
- **Validation**:
  - All Kotlin examples pass
  - kotlin-basic and kotlin-grpc pass specifically
  - No test failures related to missing generateBuildFile
- **Depends on**: Tasks 5.1, 5.2

**Task 5.4**: Run full nix flake checks
- **Command**: `nix flake check`
- **Validation**:
  - All flake checks pass
  - No lint errors in modified files
  - Schema validation passes
- **Depends on**: All Phase 1-4 tasks

### Phase 6: Final Verification

**Task 6.1**: Search for any remaining references
- **Command**: `grep -r "generateBuildFile" --include="*.nix" --include="*.md" . 2>/dev/null`
- **Validation**:
  - No matches in Kotlin-related files
  - Only matches should be in Scala module (expected)
- **Depends on**: All Phase 1-4 tasks

**Task 6.2**: Verify configuration schema documentation
- **Validation**: Documentation reflects that `kotlin.generateBuildFile` no longer exists
- **Depends on**: Task 4.2 (if applicable)

## Task Dependencies Graph

```
Phase 1: Schema Removal
  └─ Task 1.1: Remove schema option

Phase 2: Module Simplification
  └─ Task 2.1: Remove build generation (depends: 1.1)
    └─ Task 2.2: Verify no references (depends: 2.1)

Phase 3: Example Updates
  ├─ Task 3.1: kotlin-basic config (depends: 1.1)
  ├─ Task 3.2: kotlin-grpc config (depends: 1.1)
  └─ Task 3.3: README update (depends: 3.1)

Phase 4: Documentation
  ├─ Task 4.1: Config reference (depends: 1.1)
  └─ Task 4.2: Language guide (depends: 4.1)

Phase 5: Testing
  ├─ Task 5.1: Basic example test (depends: 2.1, 3.1)
  ├─ Task 5.2: gRPC example test (depends: 2.1, 3.2)
  ├─ Task 5.3: Full test suite (depends: 5.1, 5.2)
  └─ Task 5.4: Flake checks (depends: all Phase 1-4)

Phase 6: Final Verification
  ├─ Task 6.1: Search remaining refs (depends: all Phase 1-4)
  └─ Task 6.2: Documentation check (depends: 4.2)
```

## Parallelizable Work

These tasks can be executed in parallel:
- Phase 2.1 and all Phase 3 tasks (after 1.1 completes)
- Phase 3 tasks (3.1, 3.2 can run together after 1.1)
- Phase 4 tasks (4.1 can run independently after 1.1)

## Estimated Effort

| Phase | Complexity | Time |
|-------|-----------|------|
| Phase 1 | Low | 5 min |
| Phase 2 | Low-Medium | 10 min |
| Phase 3 | Low | 5 min |
| Phase 4 | Low | 10 min |
| Phase 5 | Medium | 15 min |
| Phase 6 | Low | 5 min |
| **Total** | **Low-Medium** | **~50 min** |

## Success Criteria

✅ All 6 tasks must be completed
✅ All validations must pass
✅ No remaining references to `cfg.generateBuildFile` in Kotlin-related code
✅ All example tests pass
✅ Nix flake checks pass
✅ Documentation updated and consistent

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Missing a reference location | Task 6.1 verification search catches missed updates |
| Example tests fail | Phase 5 testing validates functionality before final merge |
| Schema validation failure | Task 1.1 validation ensures schema correctness immediately |
| Documentation inconsistency | Task 6.2 final verification ensures docs match code |
