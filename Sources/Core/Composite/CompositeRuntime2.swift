actor CompositeRuntime2<
  ParentSuperState,
  ParentSuperEvent,
  Child1SuperState,
  Child1SuperEvent,
  Child2SuperState,
  Child2SuperEvent
> {
  private enum JoinState {
    case available
    case firing
    case fired
  }

  init(
    sendToParent: @escaping @Sendable (any Event<ParentSuperEvent>) -> Void,
    definition: CompositeDefinition2<
      ParentSuperState,
      ParentSuperEvent,
      Child1SuperState,
      Child1SuperEvent,
      Child2SuperState,
      Child2SuperEvent
    >
  ) {
    self.sendToParent = sendToParent
    self.definition = definition
    joinStates = Array(repeating: .available, count: definition.joinRules.count)
  }

  private let sendToParent: @Sendable (any Event<ParentSuperEvent>) -> Void
  private let definition: CompositeDefinition2<
    ParentSuperState,
    ParentSuperEvent,
    Child1SuperState,
    Child1SuperEvent,
    Child2SuperState,
    Child2SuperEvent
  >

  private var child1StateMachine: AsyncStateMachine<Child1SuperState, Child1SuperEvent>?
  private var child2StateMachine: AsyncStateMachine<Child2SuperState, Child2SuperEvent>?
  private var child1LastState: (any State<Child1SuperState>)?
  private var child2LastState: (any State<Child2SuperState>)?
  private var joinStates: [JoinState]
  private var isActive = false
  private var activationGeneration: UInt64 = 0

  func activate() async {
    guard !isActive else { return }
    activationGeneration &+= 1
    isActive = true
    joinStates = Array(repeating: .available, count: definition.joinRules.count)
    let generation = activationGeneration
    await startChild1(generation: generation)
    await startChild2(generation: generation)
  }

  func deactivate() async {
    guard isActive else { return }
    // Invalidate callbacks before awaiting shutdown. Child lifecycle handlers
    // may already be queued and must not mutate a later activation.
    isActive = false
    activationGeneration &+= 1
    await stopChildren()
    child1LastState = nil
    child2LastState = nil
    joinStates = Array(repeating: .available, count: definition.joinRules.count)
  }

  func handleParentEvent(
    currentState: any State<ParentSuperState>,
    event: any Event<ParentSuperEvent>,
    newState _: (any State<ParentSuperState>)?
  ) async {
    guard isActive else { return }
    let generation = activationGeneration

    for handler in definition.parentHandlers where handler.oneOfEvents.contains(event: event) {
      let effect = await handler.handler(currentState, event)
      guard isCurrent(generation) else { return }
      apply(effect, generation: generation)
    }
  }

  private func startChild1(generation: UInt64) async {
    let child = AsyncStateMachine(stateMachine: definition.child1.stateMachine)
    child.onInitialState { [weak self] _, state in
      await self?.handleChild1InitialState(state: state, generation: generation)
    }
    child.onTransition { [weak self] _, currentState, event, newState in
      await self?.handleChild1Transition(
        currentState: currentState,
        event: event,
        newState: newState,
        generation: generation
      )
    }
    child1StateMachine = child
    child.execution.startIfNeeded()
  }

  private func startChild2(generation: UInt64) async {
    let child = AsyncStateMachine(stateMachine: definition.child2.stateMachine)
    child.onInitialState { [weak self] _, state in
      await self?.handleChild2InitialState(state: state, generation: generation)
    }
    child.onTransition { [weak self] _, currentState, event, newState in
      await self?.handleChild2Transition(
        currentState: currentState,
        event: event,
        newState: newState,
        generation: generation
      )
    }
    child2StateMachine = child
    child.execution.startIfNeeded()
  }

  private func stopChildren() async {
    let child1 = child1StateMachine
    let child2 = child2StateMachine
    child1StateMachine = nil
    child2StateMachine = nil

    child1?.finish()
    child2?.finish()
    if let child1 {
      await child1.finishAndWait()
    }
    if let child2 {
      await child2.finishAndWait()
    }
  }

  private func handleChild1InitialState(
    state: any State<Child1SuperState>,
    generation: UInt64
  ) async {
    guard isCurrent(generation) else { return }
    child1LastState = state
    await evaluateJoin(generation: generation)
  }

  private func handleChild2InitialState(
    state: any State<Child2SuperState>,
    generation: UInt64
  ) async {
    guard isCurrent(generation) else { return }
    child2LastState = state
    await evaluateJoin(generation: generation)
  }

  private func handleChild1Transition(
    currentState: any State<Child1SuperState>,
    event: any Event<Child1SuperEvent>,
    newState: any State<Child1SuperState>,
    generation: UInt64
  ) async {
    guard isCurrent(generation) else { return }
    child1LastState = newState
    for handler in definition.child1Handlers where handler.oneOfEvents.contains(event: event) {
      let effect = await handler.handler(currentState, event)
      guard isCurrent(generation) else { return }
      apply(effect, generation: generation)
    }
    await evaluateJoin(generation: generation)
  }

  private func handleChild2Transition(
    currentState: any State<Child2SuperState>,
    event: any Event<Child2SuperEvent>,
    newState: any State<Child2SuperState>,
    generation: UInt64
  ) async {
    guard isCurrent(generation) else { return }
    child2LastState = newState
    for handler in definition.child2Handlers where handler.oneOfEvents.contains(event: event) {
      let effect = await handler.handler(currentState, event)
      guard isCurrent(generation) else { return }
      apply(effect, generation: generation)
    }
    await evaluateJoin(generation: generation)
  }

  private func evaluateJoin(generation: UInt64) async {
    guard isCurrent(generation) else { return }
    guard let child1State = child1LastState, let child2State = child2LastState else { return }

    for index in definition.joinRules.indices where joinStates[index] == .available {
      let rule = definition.joinRules[index]
      let child1Matches = ObjectIdentifier(type(of: child1State)) == rule.child1StateId
      let child2Matches = ObjectIdentifier(type(of: child2State)) == rule.child2StateId
      guard child1Matches, child2Matches else { continue }

      // Reserve before awaiting user code so another child callback cannot fire
      // the same join while this actor is re-entrant.
      joinStates[index] = .firing
      let effect = await rule.handler()
      guard isCurrent(generation), joinStates[index] == .firing else { return }
      apply(effect, generation: generation)
      joinStates[index] = .fired
    }
  }

  private func apply(_ effect: CompositeEffect<ParentSuperEvent>, generation: UInt64) {
    guard isCurrent(generation) else { return }
    for action in effect.actions {
      switch action {
      case let .forward(childID, event):
        if childID == definition.child1.id {
          sendToChild1(event: event, generation: generation)
        } else if childID == definition.child2.id {
          sendToChild2(event: event, generation: generation)
        }
      case let .raise(event):
        sendToParent(event)
      }
    }
  }

  private func sendToChild1(event: any Sendable, generation: UInt64) {
    guard isCurrent(generation), let child = child1StateMachine else { return }
    guard let event = event as? any Event<Child1SuperEvent> else { return }
    child.send(event: event)
  }

  private func sendToChild2(event: any Sendable, generation: UInt64) {
    guard isCurrent(generation), let child = child2StateMachine else { return }
    guard let event = event as? any Event<Child2SuperEvent> else { return }
    child.send(event: event)
  }

  private func isCurrent(_ generation: UInt64) -> Bool {
    isActive && activationGeneration == generation
  }
}
