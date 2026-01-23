actor CompositeCoordinator<ParentSuperState, ParentSuperEvent> {

  // MARK: - Lifecycle

  init(
    sendToParent: @escaping @Sendable (any Event<ParentSuperEvent>) -> Void,
    compositesByState: [ObjectIdentifier: [AnyCompositeDefinition<ParentSuperState, ParentSuperEvent>]]
  ) {
    self.sendToParent = sendToParent
    self.compositesByState = compositesByState
  }

  // MARK: - Properties

  private let sendToParent: @Sendable (any Event<ParentSuperEvent>) -> Void
  private let compositesByState: [ObjectIdentifier: [AnyCompositeDefinition<ParentSuperState, ParentSuperEvent>]]
  private var activeByState:
    [ObjectIdentifier: [AnyCompositeRuntime<ParentSuperState, ParentSuperEvent>]] = [:]

  // MARK: - Methods

  func handleInitialState(state: any State<ParentSuperState>) async {
    let stateId = ObjectIdentifier(type(of: state))
    await activateIfNeeded(stateId: stateId)
  }

  func handleTransition(
    currentState: any State<ParentSuperState>,
    event: any Event<ParentSuperEvent>,
    newState: (any State<ParentSuperState>)?
  ) async {
    let currentStateId = ObjectIdentifier(type(of: currentState))

    if let runtimes = activeByState[currentStateId] {
      for runtime in runtimes {
        await runtime.handleParentEvent(currentState, event, newState)
      }
    }

    guard let newState else { return }
    let newStateId = ObjectIdentifier(type(of: newState))
    guard newStateId != currentStateId else { return }

    await deactivate(stateId: currentStateId)
    await activateIfNeeded(stateId: newStateId)
  }

  func deactivateAll() async {
    let stateIds = Array(activeByState.keys)
    for stateId in stateIds {
      guard let runtimes = activeByState[stateId] else { continue }
      for runtime in runtimes {
        await runtime.deactivate()
      }
      activeByState.removeValue(forKey: stateId)
    }
  }

  // MARK: - Private

  private func activateIfNeeded(stateId: ObjectIdentifier) async {
    guard activeByState[stateId] == nil else { return }
    guard let definitions = compositesByState[stateId] else { return }
    var runtimes: [AnyCompositeRuntime<ParentSuperState, ParentSuperEvent>] = []
    for definition in definitions {
      let runtime = definition.makeRuntime(sendToParent)
      await runtime.activate()
      runtimes.append(runtime)
    }
    activeByState[stateId] = runtimes
  }

  private func deactivate(stateId: ObjectIdentifier) async {
    guard let runtimes = activeByState[stateId] else { return }
    for runtime in runtimes {
      await runtime.deactivate()
    }
    activeByState.removeValue(forKey: stateId)
  }
}
