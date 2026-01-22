import StateMachineCore
import StateMachineShared

func suspendedSideEffect<SuperEvent>(
  onSuspended: () -> Void,
  onCancel: @Sendable () -> Void,
  resumeWith: @Sendable () -> (any Event<SuperEvent>)?
) async -> (any Event<SuperEvent>)? {
  let suspendedContinuation: SendableStorage<UnsafeContinuation<(any Event<SuperEvent>)?, Never>?> =
    SendableStorage(value: nil)
  return await withTaskCancellationHandler {
    await withUnsafeContinuation { (continuation: UnsafeContinuation<(any Event<SuperEvent>)?, Never>) in
      suspendedContinuation.set(value: continuation)
      onSuspended()
    }
  } onCancel: { [suspendedContinuation] in
    onCancel()
    let toReturn = resumeWith()
    suspendedContinuation.get()?.resume(returning: toReturn)
  }
}

func makeResumableSideEffect<SuperEvent>(
  onSuspended: @Sendable @escaping () -> Void,
  resumeWith: (any Event<SuperEvent>)?
) -> (
  sideEffect: @Sendable () async -> (any Event<SuperEvent>)?,
  continuation: SendableStorage<UnsafeContinuation<Void, Never>?>
) {
  let continuation = SendableStorage<UnsafeContinuation<Void, Never>?>(value: nil)

  let sideEffect = { @Sendable in
    await withUnsafeContinuation { cont in
      continuation.set(value: cont)
      onSuspended()
    }
    return resumeWith
  }

  return (sideEffect, continuation)
}
