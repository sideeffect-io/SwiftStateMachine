actor CompositeRuntime2<
  ParentSuperState,
  ParentSuperEvent,
  Child1SuperState,
  Child1SuperEvent,
  Child2SuperState,
  Child2SuperEvent
> {

  // MARK: - Lifecycle

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
    joinDidFire = Array(repeating: false, count: definition.joinRules.count)
  }

  // MARK: - Properties

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
  private var child1Task: Task<Void, Never>?
  private var child2Task: Task<Void, Never>?
  private var child1LastState: (any State<Child1SuperState>)?
  private var child2LastState: (any State<Child2SuperState>)?
  private var joinDidFire: [Bool]
  private var isActive = false

  // MARK: - Methods

  func activate() async {
    guard !isActive else { return }
    isActive = true
    await startChild1()
    await startChild2()
  }

  func deactivate() async {
    guard isActive else { return }
    isActive = false
    await stopChildren()
    child1LastState = nil
    child2LastState = nil
    joinDidFire = Array(repeating: false, count: definition.joinRules.count)
  }

  func handleParentEvent(
    currentState: any State<ParentSuperState>,
    event: any Event<ParentSuperEvent>,
    newState _: (any State<ParentSuperState>)?
  ) async {
    guard isActive else { return }

    for handler in definition.parentHandlers where handler.oneOfEvents.contains(event: event) {
      let effect = await handler.handler(currentState, event)
      await apply(effect)
    }
  }

  // MARK: - Private

  private func startChild1() async {
    let child = AsyncStateMachine(stateMachine: definition.child1.stateMachine)
    child.onInitialState { [weak self] _, state in
      await self?.handleChild1InitialState(state: state)
    }
    child.onTransition { [weak self] _, currentState, event, newState in
      await self?.handleChild1Transition(
        currentState: currentState,
        event: event,
        newState: newState
      )
    }

    child1StateMachine = child
    child1Task = Task {
      for await _ in child { }
    }
  }

  private func startChild2() async {
    let child = AsyncStateMachine(stateMachine: definition.child2.stateMachine)
    child.onInitialState { [weak self] _, state in
      await self?.handleChild2InitialState(state: state)
    }
    child.onTransition { [weak self] _, currentState, event, newState in
      await self?.handleChild2Transition(
        currentState: currentState,
        event: event,
        newState: newState
      )
    }

    child2StateMachine = child
    child2Task = Task {
      for await _ in child { }
    }
  }

  private func stopChildren() async {
    child1StateMachine?.finish()
    child2StateMachine?.finish()
    child1Task?.cancel()
    child2Task?.cancel()
    child1Task = nil
    child2Task = nil
    child1StateMachine = nil
    child2StateMachine = nil
  }

  private func handleChild1InitialState(state: any State<Child1SuperState>) async {
    child1LastState = state
    await evaluateJoin()
  }

  private func handleChild2InitialState(state: any State<Child2SuperState>) async {
    child2LastState = state
    await evaluateJoin()
  }

  private func handleChild1Transition(
    currentState: any State<Child1SuperState>,
    event: any Event<Child1SuperEvent>,
    newState: any State<Child1SuperState>
  ) async {
    child1LastState = newState
    for handler in definition.child1Handlers where handler.oneOfEvents.contains(event: event) {
      let effect = await handler.handler(currentState, event)
      await apply(effect)
    }
    await evaluateJoin()
  }

  private func handleChild2Transition(
    currentState: any State<Child2SuperState>,
    event: any Event<Child2SuperEvent>,
    newState: any State<Child2SuperState>
  ) async {
    child2LastState = newState
    for handler in definition.child2Handlers where handler.oneOfEvents.contains(event: event) {
      let effect = await handler.handler(currentState, event)
      await apply(effect)
    }
    await evaluateJoin()
  }

  private func evaluateJoin() async {
    guard let child1State = child1LastState, let child2State = child2LastState else { return }

    for index in definition.joinRules.indices where !joinDidFire[index] {
      let rule = definition.joinRules[index]
      let child1Matches = ObjectIdentifier(type(of: child1State)) == rule.child1StateId
      let child2Matches = ObjectIdentifier(type(of: child2State)) == rule.child2StateId

      if child1Matches, child2Matches {
        let effect = await rule.handler()
        await apply(effect)
        joinDidFire[index] = true
      }
    }
  }

  private func apply(_ effect: CompositeEffect<ParentSuperEvent>) async {
    for action in effect.actions {
      switch action {
      case let .forward(childId, event):
        if childId == definition.child1.id {
          sendToChild1(event: event)
        } else if childId == definition.child2.id {
          sendToChild2(event: event)
        }
      case let .raise(event):
        sendToParent(event)
      }
    }
  }

  private func sendToChild1(event: any Sendable) {
    guard let child = child1StateMachine else { return }
    if let event = event as? any Event<Child1SuperEvent> {
      child.send(event: event)
    }
  }

  private func sendToChild2(event: any Sendable) {
    guard let child = child2StateMachine else { return }
    if let event = event as? any Event<Child2SuperEvent> {
      child.send(event: event)
    }
  }
}
