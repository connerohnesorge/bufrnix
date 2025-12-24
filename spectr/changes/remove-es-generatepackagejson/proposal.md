# Proposal: Remove `js.es.generatePackageJson` Feature (Hard Break)

**Change ID:** `remove-es-generatepackagejson`

**Status:** Pending Review

**Priority:** Medium

**Impact:** Breaking change - users relying on auto-generated `package.json` for ES modules will need to manage this manually

## Why

The `generatePackageJson` feature in JavaScript/TypeScript language modules creates unnecessary complexity and maintenance burden:

1. **Out of scope** - Bufrnix should focus exclusively on protobuf code generation, not package management
2. **Hard-coded versions** - Dependency versions in templates quickly become stale and unmaintainable
3. **Opinionated defaults** - Auto-generated package.json doesn't fit all project structures
4. **Code duplication** - Same package.json logic exists in multiple modules (es, ts-proto, connect)
5. **Single responsibility** - Users already manage package.json in their projects; Bufrnix should stay focused

By removing this feature, we:

- Reduce maintenance burden
- Simplify the codebase
- Give users full control over package management
- Clarify Bufrnix's single responsibility (protobuf generation)

## What Changes

Fully remove the `generatePackageJson` configuration option and related code from:

- Configuration schema (`bufrnix-options.nix`)
- Language implementations (ES modules, ts-proto, Connect)
- Example projects
- Documentation

## Impact

**Breaking Change**: Users using `generatePackageJson = true` will need to:

1. Remove the configuration option
2. Create their own package.json files
3. Update example references if applicable

This is a hard break - no deprecation period. Clear migration documentation will guide the transition.

## Problem Statement

The `js.es.generatePackageJson` feature (and similar options in `ts-proto` and `connect`) automatically generates a `package.json` file in the output directory during code generation. This feature:

1. **Creates opinionated defaults** that don't match all project structures
2. **Increases maintenance burden** - keeping JSON template strings in sync with modern package.json best practices
3. **Duplicates responsibility** - most projects already have their own `package.json` management
4. **Complicates the codebase** - adds conditional hooks and special-case handling in multiple language modules
5. **Locks versioning decisions** - hard-coded dependency versions in generation templates quickly become stale

### Current Usage

The feature is currently used in:

- `js.es.generatePackageJson` (ES modules via protoc-gen-es)
- `js.connect.generatePackageJson` (Connect protocol)
- `js.tsProto.generatePackageJson` (ts-proto TypeScript generation)

## Solution

**Fully remove** the `generatePackageJson` feature and related configuration options from:

1. **Configuration Schema** (`src/lib/bufrnix-options.nix`)

   - Remove `js.es.generatePackageJson` option
   - Remove `js.es.packageName` option
   - Remove `js.connect.generatePackageJson` option
   - Remove `js.connect.packageName` option
   - Remove `js.tsProto.generatePackageJson` option
   - Remove `js.tsProto.packageName` option

2. **Language Module Implementation** (`src/languages/js/default.nix`)

   - Remove ES modules package.json generation logic
   - Simplify generateHooks (remove package.json creation)

3. **ts-proto Module** (`src/languages/js/ts-proto.nix`)

   - Remove ts-proto package.json generation logic
   - Remove packageName configuration

4. **connect Module** (`src/languages/js/connect.nix`)

   - Remove connect package.json generation logic
   - Remove packageName configuration

5. **Example Projects**

   - Update `examples/js-es-modules/flake.nix` - remove generatePackageJson and packageName
   - Update `examples/ts-flake-parts/flake.nix` - remove generatePackageJson and packageName
   - Add migration guidance in README files

6. **Documentation**
   - Remove all references to `generatePackageJson` and `packageName` from:
     - `doc/src/content/docs/reference/configuration.mdx`
     - `doc/src/content/docs/reference/languages.mdx`
     - `doc/src/content/docs/guides/troubleshooting.mdx`
   - Add migration guide explaining the change and how to manage package.json manually

## Rationale

**Why remove this feature?**

1. **Scope creep prevention** - Bufrnix should focus on protobuf generation, not package management
2. **Flexibility** - Users have total control over their package.json structure and dependencies
3. **Maintenance reduction** - Less code to maintain, fewer template strings to keep current
4. **Standard practice** - Most build systems (yarn, npm, pnpm) expect projects to manage package.json directly
5. **Dependency management** - Hard-coded versions in templates become outdated; users should manage this

## Impact Analysis

### Breaking Change

This is a **hard breaking change**. Users currently using these options will need to:

1. Remove configuration from their Nix configs
2. Create/maintain their own `package.json` files
3. Update example code if they use the provided examples

### Migration Path

- Clear documentation showing before/after configuration
- Example package.json templates for common scenarios
- Gradual deprecation not needed - remove in one release with clear messaging

### Affected Users

- Projects using `js.es` with `generatePackageJson = true`
- Projects using `js.tsProto` with `generatePackageJson = true`
- Projects using `js.connect` with `generatePackageJson = true`
- Users following the bundled examples (js-es-modules, ts-flake-parts)

## Implementation Strategy

1. **Phase 1**: Remove configuration options and implementation
2. **Phase 2**: Update example projects
3. **Phase 3**: Update documentation with migration guide
4. **Phase 4**: Update tests to verify removal

## Timeline

- **Implementation**: Single PR with all changes
- **Release**: Next minor version bump (breaking change)
- **Announcement**: Changelog entry explaining removal and migration
