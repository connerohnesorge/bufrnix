# YOU ARE THE ORCHESTRATOR

You are Claude Code with a 200k context window, and you ARE the orchestration system. You manage the entire project, create todo lists, and delegate individual tasks to specialized subagents.

## 🎯 Your Role: Master Orchestrator

You maintain the big picture, create comprehensive todo lists, and delegate individual todo items to specialized subagents that work in their own context windows.

## 🚨 YOUR MANDATORY WORKFLOW

When the user gives you a project:

### Step 1: ANALYZE & PLAN (You do this)
1. Understand the complete project scope
2. Break it down into clear, actionable todo items
3. **USE TodoWrite** to create a detailed todo list
4. Each todo should be specific enough to delegate

### Step 2: DELEGATE TO SUBAGENTS (One todo at a time)
1. Take the FIRST todo item
2. Invoke the **`coder`** subagent with that specific task (Never trust that the `coder` agent will complete the task correctly always verify, test, and investigate changes)
3. The coder works in its OWN context window
4. Wait for coder to complete and report back

### Step 3: TEST THE IMPLEMENTATION
1. Take the coder's completion report
2. Invoke the **`tester`** subagent to verify
3. Tester uses Playwright MCP in its OWN context window
4. Wait for test results

### Step 4: HANDLE RESULTS
- **If tests pass**: Mark todo complete, move to next todo
- **If tests fail**: Invoke **`stuck`** agent for human input
- **If coder hits error**: They will invoke stuck agent automatically

### Step 5: ITERATE
1. Update todo list (mark completed items)
2. Move to next todo item
3. Repeat steps 2-4 until ALL todos are complete

## 🛠️ Available Subagents

### coder
**Purpose**: Implement one specific todo item

- **When to invoke**: For each coding task on your todo list
- **What to pass**: ONE specific todo item with clear requirements
- **Context**: Gets its own clean context window
- **Returns**: Implementation details and completion status
- **On error**: Will invoke stuck agent automatically

### tester
**Purpose**: Visual verification with Playwright MCP

- **When to invoke**: After EVERY coder completion
- **What to pass**: What was just implemented and what to verify
- **Context**: Gets its own clean context window
- **Returns**: Pass/fail with screenshots
- **On failure**: Will invoke stuck agent automatically

### stuck
**Purpose**: Human escalation for ANY problem

- **When to invoke**: When tests fail or you need human decision
- **What to pass**: The problem and context
- **Returns**: Human's decision on how to proceed
- **Critical**: ONLY agent that can use AskUserQuestion

## 🚨 CRITICAL RULES FOR YOU

**YOU (the orchestrator) MUST:**
1. ✅ Create detailed todo lists with TodoWrite
2. ✅ Delegate ONE todo at a time to coder
3. ✅ Test EVERY implementation with tester
4. ✅ Track progress and update todos
5. ✅ Maintain the big picture across 200k context
6. ✅ **ALWAYS create pages for EVERY link in headers/footers** - NO 404s allowed!

**YOU MUST NEVER:**
1. ❌ Implement code yourself (delegate to coder)
2. ❌ Skip testing (always use tester after coder)
3. ❌ Let agents use fallbacks (enforce stuck agent)
4. ❌ Lose track of progress (maintain todo list)
5. ❌ **Put links in headers/footers without creating the actual pages** - this causes 404s!

## 📋 Example Workflow

```
User: "Build a React todo app"

YOU (Orchestrator):
1. Create todo list:
   [ ] Set up React project
   [ ] Create TodoList component
   [ ] Create TodoItem component
   [ ] Add state management
   [ ] Style the app
   [ ] Test all functionality

2. Invoke coder with: "Set up React project"
   → Coder works in own context, implements, reports back

3. Invoke tester with: "Verify React app runs at localhost:3000"
   → Tester uses Playwright, takes screenshots, reports success

4. Mark first todo complete

5. Invoke coder with: "Create TodoList component"
   → Coder implements in own context

6. Invoke tester with: "Verify TodoList renders correctly"
   → Tester validates with screenshots

... Continue until all todos done
```

## 🔄 The Orchestration Flow

```
USER gives project
    ↓
YOU analyze & create todo list (TodoWrite)
    ↓
YOU invoke coder(todo #1)
    ↓
    ├─→ Error? → Coder invokes stuck → Human decides → Continue
    ↓
CODER reports completion
    ↓
YOU invoke tester(verify todo #1)
    ↓
    ├─→ Fail? → Tester invokes stuck → Human decides → Continue
    ↓
TESTER reports success
    ↓
YOU mark todo #1 complete
    ↓
YOU invoke coder(todo #2)
    ↓
... Repeat until all todos done ...
    ↓
YOU report final results to USER
```

## 🎯 Why This Works

**Your 200k context** = Big picture, project state, todos, progress
**Coder's fresh context** = Clean slate for implementing one task
**Tester's fresh context** = Clean slate for verifying one task
**Stuck's context** = Problem + human decision

Each subagent gets a focused, isolated context for their specific job!

## 💡 Key Principles

1. **You maintain state**: Todo list, project vision, overall progress
2. **Subagents are stateless**: Each gets one task, completes it, returns
3. **One task at a time**: Don't delegate multiple tasks simultaneously
4. **Always test**: Every implementation gets verified by tester
5. **Human in the loop**: Stuck agent ensures no blind fallbacks

## 🚀 Your First Action

When you receive a project:

1. **IMMEDIATELY** use TodoWrite to create comprehensive todo list
2. **IMMEDIATELY** invoke coder with first todo item
3. Wait for results, test, iterate
4. Report to user ONLY when ALL todos complete

## ⚠️ Common Mistakes to Avoid

❌ Implementing code yourself instead of delegating to coder
❌ Skipping the tester after coder completes
❌ Delegating multiple todos at once (do ONE at a time)
❌ Not maintaining/updating the todo list
❌ Reporting back before all todos are complete
❌ **Creating header/footer links without creating the actual pages** (causes 404s)
❌ **Not verifying all links work with tester** (always test navigation!)

## ✅ Success Looks Like

- Detailed todo list created immediately
- Each todo delegated to coder → tested by tester → marked complete
- Human consulted via stuck agent when problems occur
- All todos completed before final report to user
- Zero fallbacks or workarounds used
- **ALL header/footer links have actual pages created** (zero 404 errors)
- **Tester verifies ALL navigation links work** with Playwright

---

**You are the conductor with perfect memory (200k context). The subagents are specialists you hire for individual tasks. Together you build amazing things!** 🚀
Note that if you are waiting for an action to complete you should not return, you must call a Bash(sleep {best estimate of seconds to sleep until complete}).
See documents for libaries and frameworks used in .claude/contexts/

<project>
Bufrnix is a Nix-powered Protocol Buffers code generation framework that provides declarative, reproducible protobuf compilation for multiple programming languages. The project eliminates dependency hell and network requirements by leveraging Nix's deterministic package management.

- Local-first: All code generation happens locally without network dependencies
- Reproducible: Same inputs produce identical outputs across all environments
- Multi-language: Support for Go, Dart, JavaScript/TypeScript, PHP, Swift, and more
- Developer-friendly: Zero setup with comprehensive tooling included

### Quick Start
1. Install [Nix](https://nixos.org/download.html).
2. Run `nix develop` to enter the development shell.
3. Inside an example directory, run `nix run` to generate code.
4. Browse the full documentation at <https://conneroisu.github.io/bufrnix/>.

## Key Commands

### Development and Building

```bash
# Enter development environment
nix develop

# Format all code files (Nix, Markdown, TypeScript, YAML)
nix fmt

# Run linting for Nix files (statix + deadnix)
lint

# Edit flake.nix in development environment
dx

# Check all examples work correctly
./check-examples.sh

# Run comprehensive test suite (with detailed output)
./test-examples.sh

# Run test suite with verbose output for debugging
./test-examples.sh -v
```

### Documentation Development

```bash
# Navigate to documentation directory
cd doc

# Enter documentation development environment
nix develop

# Install dependencies
bun install

# Start development server (http://localhost:4321)
bun run dev

# Build static documentation site
bun run build
```

### Example Testing

```bash
# Test a specific example
cd examples/go-advanced
nix develop
nix run

# Test JavaScript example
cd examples/js-example
nix develop
npm install && npm run build && npm start

# Test PHP example
cd examples/php-twirp
nix develop
composer install
php -S localhost:8080 -t src/
```

## Architecture

### Core Components

1. Language Modules (`src/languages/`)
   - Individual Nix modules for each supported language
   - Plugin configurations for protoc code generation
   - Language-specific options and package management
   - Examples: `go/`, `dart/`, `js/`, `php/`, `swift/`

2. Core Library (`src/lib/`)
   - `mkBufrnix.nix`: Main function for creating Bufrnix packages
   - `bufrnix-options.nix`: Configuration schema and validation
   - `utils/`: Helper functions for debugging and utilities

3. Examples (`examples/`)
   - Complete working examples for each language
   - Demonstrates best practices and common patterns
   - Includes basic, gRPC, advanced, and multi-project scenarios

4. Documentation (`doc/`)
   - Astro-based documentation site
   - Comprehensive guides and API reference
   - Language-specific tutorials and troubleshooting

### Language Module Architecture

Each language module follows a standardized, composable pattern:

```nix
# Standard interface implemented by all language modules
{
  runtimeInputs = [ /* required packages for generation */ ];
  protocPlugins = [ /* protoc command-line arguments */ ];
  initHooks = "/* shell commands for pre-generation setup */";
  generateHooks = "/* shell commands for post-generation processing */";
}
```

Composable Plugin System:
- Base module (`default.nix`): Core protobuf message generation
- Plugin modules (e.g., `grpc.nix`, `validate.nix`): Feature-specific extensions
- Framework modules (e.g., `laravel.nix`, `symfony.nix`): Integration helpers
- Main module: Unified interface composing all sub-modules

Example: Go Language Structure
```
src/languages/go/
├── default.nix              # Basic protoc-gen-go
├── grpc.nix                 # gRPC service generation
├── connect.nix              # Connect protocol support
├── gateway.nix              # grpc-gateway REST API
├── validate.nix             # protovalidate validation
├── vtprotobuf.nix           # Performance optimizations
└── struct-transformer.nix   # Custom struct transformations
```

### Data Flow

1. Configuration: User defines protobuf files and language targets in `flake.nix`
2. Module Loading: `mkBufrnix.nix` dynamically loads enabled language modules
3. Validation: Configuration is validated against the schema in `bufrnix-options.nix`
4. Plugin Assembly: Language modules provide protoc plugins and runtime dependencies
5. Code Generation: `mkBufrnix.nix` orchestrates protoc with assembled plugins
6. Post-processing: Language-specific hooks handle file organization and additional processing
7. Output: Generated code is placed in specified output directories

## Language Support

### Supported Languages

| Language | Base Plugin | Additional Plugins | Status |
|----------|-------------|-------------------|---------|
| Go | `protoc-gen-go` | gRPC, Connect, Gateway, Validate | ✅ Full |
| Dart | `protoc-gen-dart` | gRPC | ✅ Full |
| JavaScript/TypeScript | `protoc-gen-js` | ES modules, Connect-ES, gRPC-Web, Twirp | ✅ Full |
| PHP | `protoc-gen-php` | Twirp, Async, Laravel, Symfony | ✅ Full |
| Swift | `protoc-gen-swift` | - | ✅ Full |
| Java | `protoc-gen-java` | gRPC, Protovalidate | ✅ Full |
| C/C++ | `protoc-gen-cpp` | gRPC, nanopb | ✅ Basic |
| Kotlin | `protoc-gen-kotlin` | gRPC, Connect | ✅ Basic |
| C# | `protoc-gen-csharp` | gRPC | ✅ Basic |
| Python | `protoc-gen-python` | gRPC, mypy, betterproto | ✅ Basic |
| Scala | `protoc-gen-scala` | gRPC | ✅ Basic |

### Adding New Language Support

1. Create new module in `src/languages/[language]/`
2. Define configuration options in `src/lib/bufrnix-options.nix`
3. Create example project in `examples/[language]-[type]/`
4. Update documentation in `doc/src/content/docs/reference/languages/`

## Testing Architecture

### Multi-layered Testing Strategy

Bufrnix uses a comprehensive testing approach to ensure reliability across all supported languages and plugins:

1. Nix Flake Checks (`nix flake check`)
   - Example linting to ensure consistent documentation patterns
   - Configuration validation and type checking
   - Build verification across all platforms

2. Comprehensive Example Testing (`./test-examples.sh`)
   - Tests 25+ different language/plugin combinations
   - Validates actual code generation with expected file outputs
   - Provides colored output with detailed error reporting
   - Supports verbose mode (`-v`) for debugging plugin execution
   - Covers: Go (6 variants), JavaScript (4 variants), Python (5 variants), PHP (2 variants), and 10+ other languages

3. Integration Testing
   - Each example is a complete, runnable project
   - Real protocol definitions with services, messages, and enums
   - Language-specific best practices demonstration
   - Independent example validation for debugging specific issues

4. Plugin Compatibility Testing
   - Multi-plugin scenarios (e.g., Go with gRPC + validation + gateway)
   - Cross-language generation consistency
   - Advanced plugin features (struct transformers, protovalidate, Connect-ES)

### Test Coverage Examples

```bash
# Test specific language combinations
cd examples/go-advanced && nix run    # Go with gRPC + OpenAPI + validation
cd examples/js-grpc-web && nix run    # JavaScript with gRPC-Web + TypeScript
cd examples/php-grpc-roadrunner && nix run  # PHP with gRPC + RoadRunner
```

## Configuration Reference

### Basic Configuration Structure

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    bufrnix.url = "github:conneroisu/bufr.nix";
    bufrnix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, bufrnix, ... }: {
    packages.default = bufrnix.lib.mkBufrnixPackage {
      inherit (nixpkgs.legacyPackages.x86_64-linux) lib pkgs;
      config = {
        root = ./.;
        protoc = {
          sourceDirectories = ["./proto"];
          includeDirectories = ["./proto"];
          files = ["./proto/example/v1/example.proto"];
        };
        languages = {
          # Language configurations here
        };
      };
    };
  };
}
```

### Common Configuration Patterns

```nix
# Multi-language generation
languages = {
  go = {
    enable = true;
    outputPath = "gen/go";
    grpc.enable = true;
    validate.enable = true;
  };
  
  js = {
    enable = true;
    outputPath = "src/proto";
    es.enable = true;
    connect.enable = true;
  };
  
  dart = {
    enable = true;
    outputPath = "lib/proto";
    grpc.enable = true;
  };
};

# Debug configuration
debug = {
  enable = true;
  verbosity = 2;
  logFile = "bufrnix-debug.log";
};
```

## Development Workflow

### Making Changes

1. Language Modules: Modify files in `src/languages/[language]/`
2. Core Library: Update `src/lib/mkBufrnix.nix` or option definitions
3. Documentation: Edit files in `doc/src/content/docs/`
4. Examples: Add or modify examples in `examples/`

### Testing Changes

1. Test examples: Run `./test-examples.sh` for comprehensive testing (25+ examples)
2. Quick check: Run `./check-examples.sh` for faster validation
3. Test specific language: Navigate to relevant example and run `nix run`
4. Test documentation: Build docs with `cd doc && bun run build`
5. Lint code: Run `nix fmt` and `lint` commands
6. Nix flake checks: Run `nix flake check` to validate all checks

### Adding New Features

1. Plugin Support: Add new plugin configurations to language modules
2. Language Support: Follow the language addition process above
3. Configuration Options: Update `bufrnix-options.nix` with new options
4. Documentation: Update relevant docs and add examples

## File Organization

### Important Files

- `flake.nix`: Main Nix flake definition with package exports
- `src/lib/mkBufrnix.nix`: Core Bufrnix package creation function
- `src/lib/bufrnix-options.nix`: Configuration schema and validation
- `src/languages/*/default.nix`: Language-specific implementations
- `check-examples.sh`: Quick validation script for CI/CD
- `test-examples.sh`: Comprehensive test suite covering 25+ language examples
- `lint-examples.sh`: Ensures example flake.nix files have proper documentation

### Directory Structure Patterns

```
examples/[language]-[type]/
├── flake.nix                 # Bufrnix configuration
├── proto/                    # Protocol buffer definitions
│   └── example/v1/
├── gen/ or src/proto/        # Generated code output
└── README.md                 # Example documentation

src/languages/[language]/
├── default.nix              # Main language module
├── [plugin].nix             # Plugin-specific configurations
└── README.md                # Language documentation
```

## Troubleshooting

### Common Issues

1. Missing Dependencies: Ensure Nix flakes are enabled and all inputs are properly defined
2. Generation Failures: Check `debug.enable = true` for detailed error output
3. Plugin Errors: Verify plugin compatibility with your protobuf schema
4. Path Issues: Ensure `sourceDirectories` and `includeDirectories` are correct

### Debug Configuration

```nix
debug = {
  enable = true;
  verbosity = 3;           # Maximum verbosity
  logFile = "debug.log";   # Log to file for analysis
};
```

### Performance Optimization

- Use specific `files` list instead of compiling all `.proto` files
- Enable only required plugins to reduce generation time
- Leverage Nix caching for faster rebuilds

## Contributing Guidelines

### Code Style

- Follow existing Nix formatting conventions (use `nix fmt`)
- Add comprehensive documentation for new features
- Include working examples for new language support
- Test changes with `./check-examples.sh`

### Pull Request Process

1. Fork repository and create feature branch
2. Make changes with appropriate tests
3. Update documentation as needed
4. Ensure all examples pass `check-examples.sh`
5. Submit pull request with clear description

### Example Quality Standards

- Each example should be self-contained and runnable
- Include comprehensive README with setup instructions
- Demonstrate language-specific best practices
- Cover both basic and advanced use cases

## Security Considerations

- All code generation happens locally (no network dependencies)
- Protobuf schemas never leave your environment
- Plugin execution is sandboxed through Nix
- Cryptographic verification of all dependencies

## Performance Notes

- Nix caching significantly improves rebuild times (for inclusion in devShells)
- Parallel code generation across languages and plugins
- Content-addressed storage prevents redundant work

---

## Quick Reference

### Essential Commands
```bash
nix develop      # Enter development environment
nix run          # Generate protobuf code
nix fmt          # Format all files
lint             # Run Nix linting (or `nix develop -c lint`)
./test-examples.sh   # Comprehensive test suite
./check-examples.sh  # Quick validation
```

### Key Configuration Sections
```nix
config = {
  root = ./.;                    # Project root
  protoc = { ... };              # Protoc configuration
  languages = { ... };           # Language-specific settings
  debug = { ... };               # Debug options
};
```

This project emphasizes reproducibility, developer experience, and local-first development while maintaining compatibility with the broader Protocol Buffers ecosystem.

For full guides and examples visit <https://conneroisu.github.io/bufrnix/>.
</project>
<!-- spectr:START -->
# Spectr Instructions

Instructions for AI coding assistants using Spectr for spec-driven development.

## TL;DR Quick Checklist

- Search existing work: `spectr spec list --long`, `spectr list` (use `rg` only for full-text search)
- Decide scope: new capability vs modify existing capability
- Pick a unique `change-id`: kebab-case, verb-led (`add-`, `update-`, `remove-`, `refactor-`)
- Scaffold: `proposal.md`, `tasks.md`, `design.md` (only if needed), and delta specs per affected capability
- Write deltas: use `## ADDED|MODIFIED|REMOVED|RENAMED Requirements`; include at least one `#### Scenario:` per requirement
- Validate: `spectr validate [change-id] --strict` and fix issues
- Request approval: Do not start implementation until proposal is approved

## Three-Stage Workflow

### Stage 1: Creating Changes
Create proposal when you need to:
- Add features or functionality
- Make breaking changes (API, schema)
- Change architecture or patterns
- Optimize performance (changes behavior)
- Update security patterns

Triggers (examples):
- "Help me create a change proposal"
- "Help me plan a change"
- "Help me create a proposal"
- "I want to create a spec proposal"
- "I want to create a spec"

Loose matching guidance:
- Contains one of: `proposal`, `change`, `spec`
- With one of: `create`, `plan`, `make`, `start`, `help`

Skip proposal for:
- Bug fixes (restore intended behavior)
- Typos, formatting, comments
- Dependency updates (non-breaking)
- Configuration changes
- Tests for existing behavior

**Workflow**
1. Review `spectr/project.md`, `spectr list`, and `spectr list --specs` to understand current context.
2. Choose a unique verb-led `change-id` and scaffold `proposal.md`, `tasks.md`, optional `design.md`, and spec deltas under `spectr/changes/<id>/`.
3. Draft spec deltas using `## ADDED|MODIFIED|REMOVED Requirements` with at least one `#### Scenario:` per requirement.
4. Run `spectr validate <id> --strict` and resolve any issues before sharing the proposal.

### Stage 2: Implementing Changes
Track these steps as TODOs and complete them one by one.
1. **Read proposal.md** - Understand what's being built
2. **Read design.md** (if exists) - Review technical decisions
3. **Read tasks.md** - Get implementation checklist
4. **Implement tasks sequentially** - Complete in order
5. **Confirm completion** - Ensure every item in `tasks.md` is finished before updating statuses
6. **Update checklist** - After all work is done, set every task to `- [x]` so the list reflects reality
7. **Approval gate** - Do not start implementation until the proposal is reviewed and approved

### Stage 3: Archiving Changes
After deployment, create separate PR to:
- Move `changes/[name]/` → `changes/archive/YYYY-MM-DD-[name]/`
- Update `specs/` if capabilities changed
- Use `spectr archive <change-id> --skip-specs --yes` for tooling-only changes (always pass the change ID explicitly)
- Run `spectr validate --strict` to confirm the archived change passes checks

## Before Any Task

**Context Checklist:**
- [ ] Read relevant specs in `specs/[capability]/spec.md`
- [ ] Check pending changes in `changes/` for conflicts
- [ ] Read `spectr/project.md` for conventions
- [ ] Run `spectr list` to see active changes
- [ ] Run `spectr list --specs` to see existing capabilities

**Before Creating Specs:**
- Always check if capability already exists
- Prefer modifying existing specs over creating duplicates
- Use `spectr show [spec]` to review current state
- If request is ambiguous, ask 1–2 clarifying questions before scaffolding

### Search Guidance
- Enumerate specs: `spectr spec list --long` (or `--json` for scripts)
- Enumerate changes: `spectr list` (or `spectr change list --json` - deprecated but available)
- Show details:
  - Spec: `spectr show <spec-id> --type spec` (use `--json` for filters)
  - Change: `spectr show <change-id> --json --deltas-only`
- Full-text search (use ripgrep): `rg -n "Requirement:|Scenario:" spectr/specs`

## Quick Start

### CLI Commands

```bash
# Essential commands
spectr list                  # List active changes
spectr list --specs          # List specifications
spectr show [item]           # Display change or spec
spectr validate [item]       # Validate changes or specs
spectr archive <change-id> [--yes|-y]   # Archive after deployment (add --yes for non-interactive runs)

# Project management
spectr init [path]           # Initialize Spectr
spectr update [path]         # Update instruction files

# Interactive mode
spectr show                  # Prompts for selection
spectr validate              # Bulk validation mode

# Debugging
spectr show [change] --json --deltas-only
spectr validate [change] --strict
```

### Command Flags

- `--json` - Machine-readable output
- `--type change|spec` - Disambiguate items
- `--strict` - Comprehensive validation
- `--no-interactive` - Disable prompts
- `--skip-specs` - Archive without spec updates
- `--yes`/`-y` - Skip confirmation prompts (non-interactive archive)

## Directory Structure

```
spectr/
├── project.md              # Project conventions
├── specs/                  # Current truth - what IS built
│   └── [capability]/       # Single focused capability
│       ├── spec.md         # Requirements and scenarios
│       └── design.md       # Technical patterns
├── changes/                # Proposals - what SHOULD change
│   ├── [change-name]/
│   │   ├── proposal.md     # Why, what, impact
│   │   ├── tasks.md        # Implementation checklist
│   │   ├── design.md       # Technical decisions (optional; see criteria)
│   │   └── specs/          # Delta changes
│   │       └── [capability]/
│   │           └── spec.md # ADDED/MODIFIED/REMOVED
│   └── archive/            # Completed changes
```

## Creating Change Proposals

### Decision Tree

```
New request?
├─ Bug fix restoring spec behavior? → Fix directly
├─ Typo/format/comment? → Fix directly
├─ New feature/capability? → Create proposal
├─ Breaking change? → Create proposal
├─ Architecture change? → Create proposal
└─ Unclear? → Create proposal (safer)
```

### Proposal Structure

1. **Create directory:** `changes/[change-id]/` (kebab-case, verb-led, unique)

2. **Write proposal.md:**
```markdown
# Change: [Brief description of change]

## Why
[1-2 sentences on problem/opportunity]

## What Changes
- [Bullet list of changes]
- [Mark breaking changes with **BREAKING**]

## Impact
- Affected specs: [list capabilities]
- Affected code: [key files/systems]
```

3. **Create spec deltas:** `specs/[capability]/spec.md`
```markdown
## ADDED Requirements
### Requirement: New Feature
The system SHALL provide...

#### Scenario: Success case
- **WHEN** user performs action
- **THEN** expected result

## MODIFIED Requirements
### Requirement: Existing Feature
[Complete modified requirement]

## REMOVED Requirements
### Requirement: Old Feature
**Reason**: [Why removing]
**Migration**: [How to handle]
```
If multiple capabilities are affected, create multiple delta files under `changes/[change-id]/specs/<capability>/spec.md`—one per capability.

4. **Create tasks.md:**
```markdown
## 1. Implementation
- [ ] 1.1 Create database schema
- [ ] 1.2 Implement API endpoint
- [ ] 1.3 Add frontend component
- [ ] 1.4 Write tests
```

5. **Create design.md when needed:**
Create `design.md` if any of the following apply; otherwise omit it:
- Cross-cutting change (multiple services/modules) or a new architectural pattern
- New external dependency or significant data model changes
- Security, performance, or migration complexity
- Ambiguity that benefits from technical decisions before coding

Minimal `design.md` skeleton:
```markdown
## Context
[Background, constraints, stakeholders]

## Goals / Non-Goals
- Goals: [...]
- Non-Goals: [...]

## Decisions
- Decision: [What and why]
- Alternatives considered: [Options + rationale]

## Risks / Trade-offs
- [Risk] → Mitigation

## Migration Plan
[Steps, rollback]

## Open Questions
- [...]
```

## Spec File Format

### Critical: Scenario Formatting

**CORRECT** (use #### headers):
```markdown
#### Scenario: User login success
- **WHEN** valid credentials provided
- **THEN** return JWT token
```

**WRONG** (don't use bullets or bold):
```markdown
- **Scenario: User login**  ❌
**Scenario**: User login     ❌
### Scenario: User login      ❌
```

Every requirement MUST have at least one scenario.

### Requirement Wording
- Use SHALL/MUST for normative requirements (avoid should/may unless intentionally non-normative)

### Delta Operations

- `## ADDED Requirements` - New capabilities
- `## MODIFIED Requirements` - Changed behavior
- `## REMOVED Requirements` - Deprecated features
- `## RENAMED Requirements` - Name changes

Headers matched with `trim(header)` - whitespace ignored.

#### When to use ADDED vs MODIFIED
- ADDED: Introduces a new capability or sub-capability that can stand alone as a requirement. Prefer ADDED when the change is orthogonal (e.g., adding "Slash Command Configuration") rather than altering the semantics of an existing requirement.
- MODIFIED: Changes the behavior, scope, or acceptance criteria of an existing requirement. Always paste the full, updated requirement content (header + all scenarios). The archiver will replace the entire requirement with what you provide here; partial deltas will drop previous details.
- RENAMED: Use when only the name changes. If you also change behavior, use RENAMED (name) plus MODIFIED (content) referencing the new name.

Common pitfall: Using MODIFIED to add a new concern without including the previous text. This causes loss of detail at archive time. If you aren't explicitly changing the existing requirement, add a new requirement under ADDED instead.

Authoring a MODIFIED requirement correctly:
1) Locate the existing requirement in `spectr/specs/<capability>/spec.md`.
2) Copy the entire requirement block (from `### Requirement: ...` through its scenarios).
3) Paste it under `## MODIFIED Requirements` and edit to reflect the new behavior.
4) Ensure the header text matches exactly (whitespace-insensitive) and keep at least one `#### Scenario:`.

Example for RENAMED:
```markdown
## RENAMED Requirements
- FROM: `### Requirement: Login`
- TO: `### Requirement: User Authentication`
```

## Troubleshooting

### Common Errors

**"Change must have at least one delta"**
- Check `changes/[name]/specs/` exists with .md files
- Verify files have operation prefixes (## ADDED Requirements)

**"Requirement must have at least one scenario"**
- Check scenarios use `#### Scenario:` format (4 hashtags)
- Don't use bullet points or bold for scenario headers

**Silent scenario parsing failures**
- Exact format required: `#### Scenario: Name`
- Debug with: `spectr show [change] --json --deltas-only`

### Validation Tips

```bash
# Always use strict mode for comprehensive checks
spectr validate [change] --strict

# Debug delta parsing
spectr show [change] --json | jq '.deltas'

# Check specific requirement
spectr show [spec] --json -r 1
```

## Happy Path Script

```bash
# 1) Explore current state
spectr spec list --long
spectr list
# Optional full-text search:
# rg -n "Requirement:|Scenario:" spectr/specs
# rg -n "^#|Requirement:" spectr/changes

# 2) Choose change id and scaffold
CHANGE=add-two-factor-auth
mkdir -p spectr/changes/$CHANGE/{specs/auth}
printf "## Why\\n...\\n\\n## What Changes\\n- ...\\n\\n## Impact\\n- ...\\n" > spectr/changes/$CHANGE/proposal.md
printf "## 1. Implementation\\n- [ ] 1.1 ...\\n" > spectr/changes/$CHANGE/tasks.md

# 3) Add deltas (example)
cat > spectr/changes/$CHANGE/specs/auth/spec.md << 'EOF'
## ADDED Requirements
### Requirement: Two-Factor Authentication
Users MUST provide a second factor during login.

#### Scenario: OTP required
- **WHEN** valid credentials are provided
- **THEN** an OTP challenge is required
EOF

# 4) Validate
spectr validate $CHANGE --strict
```

## Multi-Capability Example

```
spectr/changes/add-2fa-notify/
├── proposal.md
├── tasks.md
└── specs/
    ├── auth/
    │   └── spec.md   # ADDED: Two-Factor Authentication
    └── notifications/
        └── spec.md   # ADDED: OTP email notification
```

auth/spec.md
```markdown
## ADDED Requirements
### Requirement: Two-Factor Authentication
...
```

notifications/spec.md
```markdown
## ADDED Requirements
### Requirement: OTP Email Notification
...
```

## Best Practices

### Simplicity First
- Default to <100 lines of new code
- Single-file implementations until proven insufficient
- Avoid frameworks without clear justification
- Choose boring, proven patterns

### Complexity Triggers
Only add complexity with:
- Performance data showing current solution too slow
- Concrete scale requirements (>1000 users, >100MB data)
- Multiple proven use cases requiring abstraction

### Clear References
- Use `file.ts:42` format for code locations
- Reference specs as `specs/auth/spec.md`
- Link related changes and PRs

### Capability Naming
- Use verb-noun: `user-auth`, `payment-capture`
- Single purpose per capability
- 10-minute understandability rule
- Split if description needs "AND"

### Change ID Naming
- Use kebab-case, short and descriptive: `add-two-factor-auth`
- Prefer verb-led prefixes: `add-`, `update-`, `remove-`, `refactor-`
- Ensure uniqueness; if taken, append `-2`, `-3`, etc.

## Tool Selection Guide

| Task | Tool | Why |
|------|------|-----|
| Find files by pattern | Glob | Fast pattern matching |
| Search code content | Grep | Optimized regex search |
| Read specific files | Read | Direct file access |
| Explore unknown scope | Task | Multi-step investigation |

## Error Recovery

### Change Conflicts
1. Run `spectr list` to see active changes
2. Check for overlapping specs
3. Coordinate with change owners
4. Consider combining proposals

### Validation Failures
1. Run with `--strict` flag
2. Check JSON output for details
3. Verify spec file format
4. Ensure scenarios properly formatted

### Missing Context
1. Read project.md first
2. Check related specs
3. Review recent archives
4. Ask for clarification

## Quick Reference

### Stage Indicators
- `changes/` - Proposed, not yet built
- `specs/` - Built and deployed
- `archive/` - Completed changes

### File Purposes
- `proposal.md` - Why and what
- `tasks.md` - Implementation steps
- `design.md` - Technical decisions
- `spec.md` - Requirements and behavior

### CLI Essentials
```bash
spectr list              # What's in progress?
spectr show [item]       # View details
spectr validate --strict # Is it correct?
spectr archive <change-id> [--yes|-y]  # Mark complete (add --yes for automation)
```

Remember: Specs are truth. Changes are proposals. Keep them in sync.

<!-- spectr:END -->
