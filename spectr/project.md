# Project Context

## Purpose
Bufrnix is a Nix-powered Protocol Buffers code generation framework that provides declarative, reproducible protobuf compilation for multiple programming languages. The project eliminates dependency hell and network requirements by leveraging Nix's deterministic package management.

**Core Philosophy:**
- **Local-first**: All code generation happens locally without network dependencies
- **Reproducible**: Same inputs produce identical outputs across all environments
- **Multi-language**: Support for Go, Dart, JavaScript/TypeScript, PHP, Swift, Java, C/C++, Kotlin, C#, Python, and Scala
- **Developer-friendly**: Zero setup with comprehensive tooling included

## Tech Stack
- **Nix**: Package management, build system, and development environment
- **Protocol Buffers (protoc)**: Core code generation engine
- **Supported Languages**: Go, Dart, JavaScript/TypeScript, PHP, Swift, Java, C/C++, Kotlin, C#, Python, Scala
- **Documentation**: Astro-based static site with Markdown
- **Build Tools**:
  - Bash scripts for testing and validation
  - Nix flakes for reproducible builds
  - Language-specific tools (npm, composer, cargo as needed)

## Project Conventions

### Code Style
- **Nix Files**: Format with `nix fmt` (enforced via pre-commit hooks)
- **Markdown**: Consistent formatting for documentation
- **File Organization**:
  - Language modules in `src/languages/[language]/`
  - Examples follow `examples/[language]-[type]/` pattern
  - Documentation in `doc/src/content/docs/`
- **Naming Conventions**:
  - Language modules: kebab-case (e.g., `protoc-gen-go`, `grpc-web`)
  - Change IDs: kebab-case, verb-led (e.g., `add-`, `update-`, `remove-`, `refactor-`)
  - Variables/functions in Nix: camelCase for functions, kebab-case for attributes

### Architecture Patterns
- **Modular Language System**: Each language is a composable Nix module with:
  - Base configuration (`default.nix`)
  - Plugin modules (e.g., `grpc.nix`, `validate.nix`)
  - Framework modules (e.g., `laravel.nix` for PHP)
- **Plugin System**: Composable protoc plugin configurations via module composition
- **Hook-based Processing**: Pre and post-generation hooks for language-specific processing
- **Core Libraries**:
  - `src/lib/mkBufrnix.nix`: Main function for package creation
  - `src/lib/bufrnix-options.nix`: Configuration schema and validation
- **Single Responsibility**: Each capability should focus on one language/plugin feature

### Testing Strategy
**Multi-layered approach**:
1. **Nix Flake Checks** (`nix flake check`):
   - Example validation and consistency checks
   - Configuration type validation
   - Build verification

2. **Comprehensive Example Testing** (`./test-examples.sh`):
   - Tests 25+ language/plugin combinations
   - Validates actual code generation output
   - Colored output with detailed error reporting
   - Verbose mode for debugging plugin execution

3. **Quick Validation** (`./check-examples.sh`):
   - Faster validation for CI/CD pipelines
   - Basic structural checks

4. **Integration Testing**:
   - Each example is a complete, runnable project
   - Real protocol definitions with services, messages, enums
   - Language-specific best practices demonstration

**Requirements**:
- All tests MUST pass before merge
- New language support requires working example
- Plugin changes need validation across affected examples
- Breaking changes require specification updates

### Git Workflow
- **Main Branch**: `main` (production-ready code)
- **Feature Branches**: Create descriptive branches for work
- **Commit Message Format**:
  - Clear, descriptive commit messages
  - Reference issue/PR numbers when applicable
  - Include scope when relevant (e.g., "feat(go): add custom struct transformer")
- **PR Process**:
  1. Create feature branch from `main`
  2. Update documentation as needed
  3. Ensure all examples pass `./test-examples.sh`
  4. Run `nix fmt` and `lint` commands
  5. Submit PR with clear description
  6. Await review and testing approval

## Domain Context
**Protocol Buffers Expertise**:
- Deep understanding of protoc plugin system
- Knowledge of language-specific code generation patterns
- Awareness of version compatibility across language versions
- Understanding of proto3 syntax and features

**Nix Expertise**:
- Flake-based package management
- Module system and composition patterns
- Derivation building and output handling
- Input handling for reproducibility

**Multi-Language Support**:
- Each language has different code generation needs
- Some languages require post-processing (file organization, imports)
- Plugin compatibility varies between languages
- Performance and output structure differ by language

## Important Constraints
1. **Reproducibility**: All generated code must be deterministic with same inputs
2. **No Network Requirements**: Package fetching happens during Nix evaluation, not generation
3. **Local Generation**: All protobuf compilation happens in user's environment
4. **Plugin Compatibility**: Some plugins work only with specific language versions
5. **Output Structure**: Generated files must follow language-specific conventions
6. **Determinism**: Use fixed versions for all external tools and dependencies
7. **Security**: Protobuf schemas never leave user's environment

## External Dependencies
- **Nix Package Repository**: Provides all language toolchains and dependencies
- **Protocol Buffers**: Official protoc compiler from Google
- **Language-Specific Tools**:
  - Go: `protoc-gen-go`, `protoc-gen-go-grpc`, plugins from community
  - JavaScript: `protoc-gen-js`, Connect-ES, grpc-web, etc.
  - PHP: Composer and language-specific protoc plugins
  - Others: Language package managers and official/community plugins
- **Documentation**: Astro (static site generator), Markdown processor
- **No Runtime Network**: All dependencies resolved at build time via Nix
