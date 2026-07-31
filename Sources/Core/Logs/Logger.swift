import OSLog
import StateMachineShared
#if DEBUG
import XCTestDynamicOverlay
#endif

// MARK: - Typealiases

// MARK: Public

/// (Title, CurrentState, Event, NewState) -> Void
public typealias LogFunction = @Sendable (
  String,
  any State,
  any Event,
  any State
) async -> Void

// MARK: - Variables

// MARK: Internal

/// default ooutput for logs is Apple Unified Logging system
let osLogger = os.Logger(subsystem: "io.sideeffect", category: "StateMachine")

let logger: SendableStorage<LogFunction> = SendableStorage(value: { @Sendable title, currentState, event, newState in
  let currentStateStr = String(describing: currentState)
  let eventStr = String(describing: event)
  let newStateStr = String(describing: newState)
  osLogger
    .info(
      "[\(title)] \(currentStateStr, privacy: .private) + \(eventStr, privacy: .private) => \(newStateStr, privacy: .private)"
    )
})

// MARK: - Functions

// MARK: Public

/// Allows to change the log function to adapt to the client stack.
/// The log function is called for every transition: current state + event => new state, and takes those 3 parameters as inputs.
/// - Parameter function: the client log function
public func setLogger(function: @escaping LogFunction) {
  logger.set(value: function)
}

// MARK: Internal

@Sendable
func log(
  title: String,
  currentState: some State,
  event: some Event,
  newState: some State,
  forceLogging: Bool = false
) async {
  #if DEBUG
  guard !(_XCTIsTesting && !forceLogging) else { return }
  #endif
  await logger.get()(title, currentState, event, newState)
}
