# Agents Overview — SwiftStateMachine

This repository implements a **Swift Package** that allows to create asynchronous Mealy extented state machines.
Agents working with this repo (AI assistants, automation tools, or new team members) should understand:

- Functional design principles (immutability, pure functions, side effects, composition)
- How we structure side effects via dependency injection
- SOLID principles applied in a Swift + functional programming context
- Testability via injecting functions and capabilities
- Our Git workflow (linear history, feature branches, fast-forward merges)

> This high-level overview provides context. Detailed procedural steps and examples are available through dedicated **Agent Skills** in `skills/`.

Read the `README.md` file at the root of the repo for more context.

---

## Plan

For long reasoning operations and complex tasks we do an execution plan upfront and ask for validation.

---

## Functional Architecture Philosophy

**North Star**  
We partition code into:

1. **Inert Domain** — immutable data (`struct`/`enum`), no side effects  
2. **Pure Computations** — deterministic pure functions (input → output)  
3. **Actions/Effects** — side effects (network, hardware, IO) at the edges

**Key Concepts**  
- Immutability by default  
- Pure functions everywhere possible  
- Composition over inheritance  
- Higher-order functions and partial application (or curry when this apply)
- Lazy/thunked dependencies for expensive resources

We apply SOLID in a Swift FP context:

- **S**ingle Responsibility: small functions that performs one thing, narrow types
- **O**pen/Closed: extend via composition, not inheritance (when possible)
- **L**iskov: injected functions uphold contracts
- **I**nterface Segregation: tiny capability structs or functions, not fat protocols
- **D**ependency Inversion: domain depends on capabilities, not implementations

These emphasize modularity without unnecessary abstractions.

This aligns with modern functional design patterns that emphasize clarity, testability, and correctness.

Use Enums as a namespace for related free functions.

---

## Testability Patterns

We favor **function injection instead of object mocking**:

- Capability structs of closures (e.g., network client, clock, logger)
- Inject only what a unit needs (small slices)
- Pure core logic that can be tested with no environment dependencies

We focus on unit tests (not integration tests). Always use the Swift Testing framework.
---

## Git Workflow Summary

We use the Git CLI.

We adopt a **GitHub Flow** style:

- One long-lived `main` branch
- Short-lived feature/fix branches
- Frequent rebasing from `main`
- Fast-forward merges only
- Destructive operations are forbidden unless explicit (reset --hard, clean, restore, rm, …)

This yields a clean, linear history and makes `git bisect` and blame more effective.

--

## How to run and test

In the context of a Swift package, we use the Swift CLI with commands like `swift build` or `swift test`
If this does not apply, we can use the XCodeBuildMCP server

Don't wait for approval when you need to execute commands to build and test the projet.

--

## Swift documentation

When needed we can use the Cupertino MCP to access the officiel Swift documentation and Apple coding guides.

---

## Composite DSL (two-child prototype)

See `.codex/docs/composite-dsl.md` for a summary of the new Composite DSL, its semantics, and usage examples.
