# Tasks: Remove cfg.generateTsConfig from ts-proto.nix

## Execution Order and Dependencies

All tasks are **independent** and can be executed in parallel after the initial review.

---

## Task 1: Remove option definition from bufrnix-options.nix

**Status**: Pending

**Priority**: High

**Verification**:
- [ ] Lines 1080-1084 removed from `src/lib/bufrnix-options.nix`
- [ ] No syntax errors when running `nix flake show`
- [ ] Schema validation passes: `nix eval .#schemaOutputs` (if applicable)

**Changes**:
```nix
// File: src/lib/bufrnix-options.nix
// REMOVE these lines (1080-1084):
          generateTsConfig = mkOption {
            type = types.bool;
            default = false;
            description = "Generate tsconfig.json for the generated code";
          };
```

**Notes**: This removes the configuration option from the schema, preventing users from specifying it.

---

## Task 2: Remove conditional generation block from ts-proto.nix

**Status**: Pending

**Priority**: High

**Verification**:
- [ ] Lines 88-109 removed from `src/languages/js/ts-proto.nix`
- [ ] File syntax valid: `nix eval src/languages/js/ts-proto.nix`
- [ ] No unintended whitespace changes

**Changes**:
```nix
// File: src/languages/js/ts-proto.nix
// REMOVE this entire block (lines 88-109):
      # Generate tsconfig.json if needed
      ${optionalString (cfg.generateTsConfig or false) ''
              cat > ${outputPath}/tsconfig.json <<EOF
        {
          "compilerOptions": {
            "target": "ES2020",
            "module": "ESNext",
            "moduleResolution": "node",
            "strict": true,
            "esModuleInterop": true,
            "skipLibCheck": true,
            "forceConsistentCasingInFileNames": true,
            "declaration": true,
            "declarationMap": true,
            "sourceMap": true,
            "outDir": "./dist"
          },
          "include": ["./**/*.ts"],
          "exclude": ["node_modules", "dist"]
        }
        EOF
      ''}
```

**Notes**: This removes the implementation that actually generates the file during code generation.

---

## Task 3: Update documentation in README

**Status**: Pending

**Priority**: Medium

**Verification**:
- [ ] Example block updated or removed from `examples/js-es-modules/README.md` (lines 142-145)
- [ ] Markdown syntax valid
- [ ] Context still makes sense in documentation flow

**Changes**:
```markdown
// File: examples/js-es-modules/README.md
// REMOVE or update the example showing generateTsConfig

// Current lines 142-145 show:
generateTsConfig = true;

// Either remove this from the example, or replace the entire Alternative section
// with guidance to use protobuf-es instead.
```

**Notes**:
- Current example on lines 142-145 uses `generateTsConfig = true`
- Consider adding a note that protobuf-es is the modern recommended approach
- Keep the comment about ts-proto as an alternative generator

---

## Task 4: Run test suite

**Status**: Pending

**Priority**: High

**Verification**:
- [ ] `./test-examples.sh` passes completely
- [ ] `./check-examples.sh` passes completely
- [ ] No generation errors in ts-proto examples
- [ ] No errors with `nix fmt` and `lint` commands

**Commands**:
```bash
cd /home/connerohnesorge/Documents/001Repos/bufrnix

# Format code
nix fmt

# Run lint checks
lint

# Run comprehensive tests (25+ language combinations)
./test-examples.sh

# Quick validation
./check-examples.sh
```

**Expected Output**: All tests pass, no regressions

**Notes**: Must run after all file modifications to ensure no breakage

---

## Task 5: Validate with openspec

**Status**: Pending

**Priority**: Medium

**Verification**:
- [ ] `openspec validate remove-ts-proto-generatetsconfig --strict` passes
- [ ] No specification errors reported
- [ ] Change is properly formatted

**Commands**:
```bash
cd /home/connerohnesorge/Documents/001Repos/bufrnix

# Validate the change proposal
openspec validate remove-ts-proto-generatetsconfig --strict

# Show detailed output if needed
openspec show remove-ts-proto-generatetsconfig --json
```

**Expected Output**: Validation passes with no errors

---

## Summary

| Task | File | Lines | Type | Risk |
|------|------|-------|------|------|
| 1 | `src/lib/bufrnix-options.nix` | 1080-1084 | Remove option | Low |
| 2 | `src/languages/js/ts-proto.nix` | 88-109 | Remove implementation | Low |
| 3 | `examples/js-es-modules/README.md` | 142-145 | Update docs | Low |
| 4 | Test suite | - | Validation | Critical |
| 5 | OpenSpec validation | - | Validation | Low |

**Total Lines Changed**: ~30 lines removed

**Complexity**: Low (straightforward deletions)

**Risk Level**: Low (unused by default, alternative exists)

## Rollback Plan

If issues arise:
1. Revert all file changes
2. Keep ts-proto.nix and bufrnix-options.nix from main branch
3. Rerun tests to confirm restoration
