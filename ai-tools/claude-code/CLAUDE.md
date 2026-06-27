# Development Guidelines

## Principles

1. No assumptions. Surface confusion. Surface tradeoffs.
2. Minimum code. Nothing speculative.
3. Touch only what must be touched. Clean own mess only.
4. Define success criteria. Loop until verified.

## Philosophy

- Small changes that compile and pass tests. No big bangs.
- Study and plan before implementing.
- Adapt to project reality. Not dogmatic.
- Boring and obvious over clever.
- Single responsibility per function/class.
- No premature abstractions.
- No clever tricks. If you need to explain it, too complex.

## Technical Standards

- Composition over inheritance. Dependency injection.
- Interfaces over singletons. Enables testing.
- Explicit over implicit. Clear data flow.
- Test-driven. Never disable tests — fix them.
- Fail fast with descriptive messages.
- Include context for debugging.
- Handle errors at appropriate level.
- Never silently swallow exceptions.

## Project Integration

- Find similar features/components first.
- Use same libraries/utilities as project.
- Follow existing test patterns.
- Use project's build system, test framework, formatter/linter.
- No new tools without strong justification.
- Follow existing code conventions.
- Check linter config and .editorconfig if present.
- Text files end with empty line.

## MCP Tool Use


## Rules

**NEVER**:
- `--no-verify` to bypass commit hooks
- Disable tests instead of fixing
- Commit code that doesn't compile
- Assume — verify with existing code

**ALWAYS**:
- Commit working code incrementally
- Update plan docs as you go
- Learn from existing implementations
- Stop after 3 failed attempts and reassess
- Prefer LSP (`goToDefinition`, `findReferences`) over grep for code navigation. Grep/glob only for discovery or when LSP can't help.
