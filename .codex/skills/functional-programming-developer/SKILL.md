---
name: functional-programming-developer
description: Guidance for applying functional architecture (immutability, pure functions, composition) in this Swift package with testability in mind.
---

# Functional Architecture in Swift

Use this skill when you structure code following functional design patterns and SOLID principles.

## When to use
Use this skill when an agent must generate, review, or refactor code for the domain and core logic of this package.
Think functional programming first, object oriented programming next.

## Core Tenets
- **Inert Domain**: Use `struct`/`enum` with `let` fields (immutable). Avoid global shared mutable state.
- **Pure Computations**: Functions should be deterministic, highly testable and side-effect–free.
- **Combinators**: Compose small functions to build pipelines.
- **Higher order functions and Partial Application**: Inject dependencies as first-class functions.
- **Declarative code** over Imperative code.

## How to do dependency injection in the context of functional programming

- Pass only necessary functions into pure core logic instead of protocols. Use lazy closures for expensive resources.
- Define small capability structs of closures as an encapsulation mechanism when too many functions should be passed
- Avoid large mock protocols; use closures for easy test fakes.

## How to apply SOLID principles in the context of functional programming

- **Single Responsibility**: One reason to change; small focused types.
- **Open/Closed**: Extend via composition, not modification.
- **Liskov Substitution**: Functions uphold expected contracts.
- **Interface Segregation**: Inject minimal capabilities.
- **Dependency Inversion**: Domain depends on abstract functions, not concrete implementations.

## How to test

- Focus on unit tests (not integration tests)
- Inject fake closures that record invocations
- Use in-memory stores and fake clocks
- Never rely on hard coded timers or sleep durations

## Edge Cases
- If performance demands localized mutation, confine it and return a value.
- When using object oriented programming and shared references makes sens then use it.

## References

Read `references/functional-programming-samples.md` for simple examples of functional programming usages.
