# Composite DSL (two-child prototype)

This repository now includes a **Composite DSL** that lets a parent state machine run two child state machines in parallel (orthogonal regions) while staying close to the existing `When / On / Transition / Output` style.

The current implementation is intentionally minimal and supports **two child state machines**. It is designed so we can later extend to variadic generics once we decide on the final API shape.

## What was added

- A `Composite` DSL block that can be used **inside a `When(state:)` block** to attach two child state machines to that parent state.
- Bidirectional routing:
  - `Forward(...)` to send parent events to a child.
  - `Raise(...)` to send child events to the parent.
- A `join(whenChildStates: ...)` rule that fires **once** when both child machines are in the specified states.
- A `StateMachine(id:initial:)` initializer to make child machines identifiable inside the composite.

## Key semantics

- A `Composite` is **active only while the parent is in the owning state**.
- Entering the parent state starts the two child machines.
- Leaving the parent state stops the two child machines and deactivates routing.
- `join(whenChildStates:)` triggers once per composite activation (it resets when the parent leaves and re-enters).
- Child machines must be defined with `StateMachine(id:initial:)` so they can be addressed by `Forward`.

## Usage example

```swift
let stateMachine = StateMachine<RootState, RootEvent>(initial: RootIdle()) {
  When(state: RootRunning.self) {
    Composite {
      StateMachine<AuthState, AuthEvent>(id: AuthMachine.self, initial: AuthIdle()) {
        // ... child auth transitions
      }

      StateMachine<SyncState, SyncEvent>(id: SyncMachine.self, initial: SyncIdle()) {
        // ... child sync transitions
      }
    }
    .on(parentEvent: RootCancellationWasRequested.self) { _, _ in
      Forward(to: AuthMachine.self, event: AuthCancel())
      Forward(to: SyncMachine.self, event: SyncCancel())
    }
    .on(childEvent: AuthEvent.Success.self) { _, event in
      Raise(event: RootEvent.auth(event))
    }
    .on(childEvent: SyncEvent.Success.self) { _, event in
      Raise(event: RootEvent.sync(event))
    }
    .join(whenChildStates: AuthFinished.self, SyncFinished.self) {
      Raise(event: RootWasSuccessful())
    }
  }
}
```

## Constraints (current prototype)

- Only **two child state machines** are supported.
- `Composite` must appear inside a `When(state: ...)` with a **single state** (not `When(states: ...)`).
- `join(whenChildStates: ...)` expects state types in the **same order as the children** in the `Composite` block.
- `on(childEvent: ...)` uses overloads for each child's `SuperEvent` type (so keep child super-event types distinct).

## Extending later

When we move to variadic generics, the current two-child structure can become a more general `Composite` with N children and more flexible `join` rules without changing the calling style too much.
