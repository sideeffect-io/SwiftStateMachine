import StateMachineCore

// swiftlint:disable no_directStandardOutLogs

/// Dumps the current tracked states thanks to the provided `export` function.
/// - Parameters:
///   - dumpStateMachine: The state machine connected to the `dumpMediator`
///   as a receiver when calling `startCollecting()`. By default we will use an internal global ``AsyncStateMachine``.
///   - export: The function used to dump all the states currently tracked.
public func dump(
  dumpStateMachine: AsyncStateMachine<DumpState, DumpEvent> = defaultDumpStateMachine,
  export: @Sendable @escaping ([StateContext]) async -> Void
) {
  dumpStateMachine.send(event: DidRequestDump(dumpStateContexts: export))
}
