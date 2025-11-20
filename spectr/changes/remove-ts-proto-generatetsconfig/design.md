# Design: Remove cfg.generateTsConfig from ts-proto.nix

## Architecture Context

### Current State

The ts-proto language module in `src/languages/js/ts-proto.nix` includes an optional feature that generates a `tsconfig.json` file in the output directory when `cfg.generateTsConfig` is enabled.

**Current Flow**:
```
User Config (flake.nix)
    ↓
    └→ languages.js.tsProto.generateTsConfig = true/false
           ↓
           └→ bufrnix-options.nix (defines option)
                  ↓
                  └→ ts-proto.nix (uses option in line 89)
                         ↓
                         └→ generateHooks writes tsconfig.json to output
```

**Current Implementation** (ts-proto.nix lines 88-109):
```nix
# Generate tsconfig.json if needed
${optionalString (cfg.generateTsConfig or false) ''
  cat > ${outputPath}/tsconfig.json <<EOF
  {
    "compilerOptions": { ... },
    "include": ["./**/*.ts"],
    "exclude": ["node_modules", "dist"]
  }
  EOF
''}
```

### Proposed State

Remove all traces of the `generateTsConfig` option, leaving only the unconditional generation hooks that don't depend on this configuration.

**After Removal**:
```
User Config (flake.nix)
    ↓
    └→ languages.js.tsProto.options = [...]
           ↓
           └→ bufrnix-options.nix (WITHOUT generateTsConfig option)
                  ↓
                  └→ ts-proto.nix (WITHOUT generateTsConfig conditional)
                         ↓
                         └→ generateHooks only for ts-proto-specific steps
```

## Rationale for Complete Removal

### 1. **Violation of Separation of Concerns**

The option blurs the line between:
- **Code generation** (what Bufrnix should do): Generate `.proto` files → `.ts` files
- **Project configuration** (what developers should do): Set up `tsconfig.json`, `package.json`, build tools

**Principle**: Generated code should be ephemeral and replaceable. Configuration files belong with the source project.

### 2. **Poor Default Configuration**

The generated `tsconfig.json` is a generic template that:
- Uses hardcoded settings (`target: "ES2020"`, `strict: true`)
- Doesn't adapt to project-specific needs
- Can't be regenerated without overwriting user changes
- Creates version control ambiguity (should it be committed?)

**Example Issue**:
```nix
# User's flake.nix
tsProto.generateTsConfig = true;

# First generation creates gen/js/tsconfig.json
# User modifies it for their needs
# Next build overwrites their changes → Lost configuration

# Better approach:
# Create src/tsconfig.json in the source project with desired settings
```

### 3. **Modern Alternatives**

Users have better options already available in Bufrnix:

**Option A: Use Protobuf-ES** (Recommended modern approach)
```nix
es = {
  enable = true;
  target = "ts";
};
```
- Protobuf-ES is the official conformant implementation
- Better integration with TypeScript
- Active maintenance by Buf
- No need for separate `tsconfig.json` generation

**Option B: Manual Configuration** (Explicit and controllable)
```bash
# Create in project root (version controlled)
cat > tsconfig.json <<EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "strict": true
  },
  "include": ["src/**/*.ts", "gen/js/**/*.ts"]
}
EOF
```

**Option C: Framework Integration**
- Next.js, Vite, etc. generate their own `tsconfig.json`
- Bufrnix shouldn't override framework tooling

### 4. **Configuration Surface Area**

Every configuration option adds:
- Maintenance burden
- Documentation overhead
- Testing requirements
- User decision fatigue

This option provides limited value (one generic template) compared to its maintenance cost.

### 5. **No Dependency Chain**

The option doesn't enable or require other features:
- Independent boolean flag
- Not required by Connect-ES, gRPC-Web, or other features
- Can be safely removed without cascading impacts

## Implementation Strategy

### Changes Summary

| File | Change | Impact |
|------|--------|--------|
| `src/lib/bufrnix-options.nix` | Remove option definition (5 lines) | Option unavailable in schema |
| `src/languages/js/ts-proto.nix` | Remove conditional block (22 lines) | No tsconfig.json generation |
| `examples/js-es-modules/README.md` | Update example (4 lines) | Docs reflect reality |

### No Changes Needed

- ✓ `src/languages/js/default.nix` - doesn't reference generateTsConfig
- ✓ `src/languages/js/es.nix` - independent implementation
- ✓ `src/languages/js/grpc-web.nix` - independent implementation
- ✓ Other language modules - unaffected
- ✓ Core library (`mkBufrnix.nix`) - option purely ts-proto concern

### Backward Compatibility Handling

This is a **breaking change** for the minority of users using `generateTsConfig = true`.

**Mitigation Strategy**:
1. **Release notes**: Clearly document the breaking change
2. **Migration guide**: Provide template for users to create their own tsconfig.json
3. **Recommendation**: Point users to protobuf-es as modern alternative
4. **Deprecation timeline**: If possible in future, deprecate before removal (here we're being direct)

## Testing Strategy

### Unit Tests
- Nix syntax validation of modified files
- Schema validation with `nix eval`

### Integration Tests
- Run `./test-examples.sh` - verifies ts-proto examples still generate correctly
- Run `./check-examples.sh` - faster validation
- Verify `js-es-modules` example still builds

### Regression Tests
- Ensure other ts-proto functionality (Connect, gRPC-Web) still works
- Verify package.json generation (separate option) still works
- Check other JS generators (es, protoc-gen-js, grpc-web) unaffected

### Manual Verification
```bash
# These should all succeed
nix fmt
lint
./test-examples.sh
./check-examples.sh
openspec validate remove-ts-proto-generatetsconfig --strict
```

## Risk Assessment

### Low Risk Factors
1. **Default disabled**: Feature disabled by default (`false`)
2. **Limited usage**: Only one example references it (js-es-modules README)
3. **No dependencies**: No other features depend on this option
4. **Simple cleanup**: Straightforward deletions, no complex logic changes

### Mitigation for Users
1. Users with `generateTsConfig = true` will see Nix evaluation error
2. Error message directs to Bufrnix docs
3. Simple fix: Remove the line or create own tsconfig.json
4. Alternative: Switch to protobuf-es

### Revert Strategy
If unforeseen issues arise:
```bash
git revert <commit-hash>
```
- Clean rollback due to isolated changes
- No dependency chains to untangle

## Design Trade-offs

### Decision: Complete Removal vs. Deprecation

**Chosen**: Complete removal

**Rationale**:
- Small feature with minimal adoption (default false)
- Minimal breakage expected
- Cleaner than deprecation warning that would persist in docs
- Modern alternatives exist (protobuf-es)

### Decision: No Replacement Auto-generation

**Chosen**: Users manually create `tsconfig.json`

**Rationale**:
- Config belongs in source, not generated code
- Users have framework-specific needs
- Manual creation promotes configuration awareness
- Aligns with 12-factor app principles

## Future Considerations

### Related Cleanups
1. **`generatePackageJson`**: Consider similar cleanup (already partially done in separate change)
2. **Configuration options review**: Periodically audit for unused options

### Lessons Learned
1. Generated code should never generate non-code files
2. Keep configuration schema focused on core functionality
3. Prefer language-native configuration over custom generation

## Compatibility Matrix

### TypeScript Ecosystem Impact
- **ts-proto**: No longer generates base config (users must create own)
- **protobuf-es**: Unaffected, recommended modern alternative
- **Connect-ES**: Works with user-provided or framework tsconfig.json
- **TypeScript compiler**: Requires tsconfig.json but doesn't care where it comes from

### Bufrnix Ecosystem Impact
- **Other language modules**: No changes needed
- **Examples**: js-es-modules needs documentation update
- **Core library**: No changes to mkBufrnix.nix

## Success Criteria

✅ Removal complete when:
1. Option removed from schema (bufrnix-options.nix)
2. Implementation removed (ts-proto.nix)
3. Documentation updated (README)
4. All tests pass (`./test-examples.sh`)
5. OpenSpec validation passes
6. No unintended changes to other files
7. Nix formatting correct (`nix fmt`)

## Implementation Checklist

- [ ] Review design with team (if applicable)
- [ ] Create tasks.md with specific change lines
- [ ] Execute Task 1: Remove option definition
- [ ] Execute Task 2: Remove implementation
- [ ] Execute Task 3: Update documentation
- [ ] Execute Task 4: Run test suite
- [ ] Execute Task 5: OpenSpec validation
- [ ] Commit changes with clear message
- [ ] Close related issues/discussions
- [ ] Update changelog/release notes
