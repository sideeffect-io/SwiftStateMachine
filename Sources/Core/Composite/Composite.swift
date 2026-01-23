public struct AnyCompositeDefinition<ParentSuperState, ParentSuperEvent>: Sendable {
  let makeRuntime: @Sendable (
    @escaping @Sendable (any Event<ParentSuperEvent>) -> Void
  ) -> AnyCompositeRuntime<ParentSuperState, ParentSuperEvent>
}

struct AnyCompositeRuntime<ParentSuperState, ParentSuperEvent>: Sendable {
  let activate: @Sendable () async -> Void
  let deactivate: @Sendable () async -> Void
  let handleParentEvent: @Sendable (
    any State<ParentSuperState>,
    any Event<ParentSuperEvent>,
    (any State<ParentSuperState>)?
  ) async -> Void
}

struct CompositeParentEventHandler<ParentSuperState, ParentSuperEvent>: Sendable {
  let oneOfEvents: OneOfEvents<ParentSuperEvent>
  let handler: @Sendable (
    any State<ParentSuperState>,
    any Event<ParentSuperEvent>
  ) async -> CompositeEffect<ParentSuperEvent>
}

struct CompositeChildEventHandler<
  ParentSuperState,
  ParentSuperEvent,
  ChildSuperState,
  ChildSuperEvent
>: Sendable {
  let oneOfEvents: OneOfEvents<ChildSuperEvent>
  let handler: @Sendable (
    any State<ChildSuperState>,
    any Event<ChildSuperEvent>
  ) async -> CompositeEffect<ParentSuperEvent>
}

struct CompositeJoinRule<
  ParentSuperState,
  ParentSuperEvent,
  Child1SuperState,
  Child2SuperState
>: Sendable {
  let child1StateId: ObjectIdentifier
  let child2StateId: ObjectIdentifier
  let handler: @Sendable () async -> CompositeEffect<ParentSuperEvent>
}

struct CompositeDefinition2<
  ParentSuperState,
  ParentSuperEvent,
  Child1SuperState,
  Child1SuperEvent,
  Child2SuperState,
  Child2SuperEvent
>: Sendable {
  let child1: CompositeChild<Child1SuperState, Child1SuperEvent>
  let child2: CompositeChild<Child2SuperState, Child2SuperEvent>
  var parentHandlers: [CompositeParentEventHandler<ParentSuperState, ParentSuperEvent>]
  var child1Handlers: [
    CompositeChildEventHandler<ParentSuperState, ParentSuperEvent, Child1SuperState, Child1SuperEvent>
  ]
  var child2Handlers: [
    CompositeChildEventHandler<ParentSuperState, ParentSuperEvent, Child2SuperState, Child2SuperEvent>
  ]
  var joinRules: [
    CompositeJoinRule<ParentSuperState, ParentSuperEvent, Child1SuperState, Child2SuperState>
  ]

  func eraseToAny() -> AnyCompositeDefinition<ParentSuperState, ParentSuperEvent> {
    AnyCompositeDefinition { sendToParent in
      let runtime = CompositeRuntime2(sendToParent: sendToParent, definition: self)
      return AnyCompositeRuntime(
        activate: { await runtime.activate() },
        deactivate: { await runtime.deactivate() },
        handleParentEvent: { state, event, newState in
          await runtime.handleParentEvent(
            currentState: state,
            event: event,
            newState: newState
          )
        }
      )
    }
  }
}

public struct Composite<
  ParentSuperState,
  ParentSuperEvent,
  Child1SuperState,
  Child1SuperEvent,
  Child2SuperState,
  Child2SuperEvent
>: Sendable {

  // MARK: - Lifecycle

  public init(
    @CompositeBuilder _ builder: () -> CompositeChildren2<
      Child1SuperState,
      Child1SuperEvent,
      Child2SuperState,
      Child2SuperEvent
    >
  ) {
    let children = builder()
    definition = CompositeDefinition2(
      child1: children.child1,
      child2: children.child2,
      parentHandlers: [],
      child1Handlers: [],
      child2Handlers: [],
      joinRules: []
    )
  }

  // MARK: - Properties

  let definition: CompositeDefinition2<
    ParentSuperState,
    ParentSuperEvent,
    Child1SuperState,
    Child1SuperEvent,
    Child2SuperState,
    Child2SuperEvent
  >

  // MARK: - Public

  public func on<E: Event<ParentSuperEvent>>(
    parentEvent _: E.Type,
    @CompositeEffectBuilder<ParentSuperEvent> _ handler: @Sendable @escaping (
      any State<ParentSuperState>,
      E
    ) async -> CompositeEffect<ParentSuperEvent>
  ) -> Self {
    let wrappedHandler = CompositeParentEventHandler<ParentSuperState, ParentSuperEvent>(
      oneOfEvents: OneOfEvents(E.self),
      handler: { state, event in
        guard let event = event as? E else { return CompositeEffect(actions: []) }
        return await handler(state, event)
      }
    )
    return updating { $0.parentHandlers.append(wrappedHandler) }
  }

  public func on<ChildEvent: Event<Child1SuperEvent>>(
    childEvent _: ChildEvent.Type,
    @CompositeEffectBuilder<ParentSuperEvent> _ handler: @Sendable @escaping (
      any State<Child1SuperState>,
      ChildEvent
    ) async -> CompositeEffect<ParentSuperEvent>
  ) -> Self {
    let wrappedHandler = CompositeChildEventHandler<
      ParentSuperState,
      ParentSuperEvent,
      Child1SuperState,
      Child1SuperEvent
    >(
      oneOfEvents: OneOfEvents(ChildEvent.self),
      handler: { state, event in
        guard let event = event as? ChildEvent else { return CompositeEffect(actions: []) }
        return await handler(state, event)
      }
    )

    return updating { $0.child1Handlers.append(wrappedHandler) }
  }

  public func on<ChildEvent: Event<Child2SuperEvent>>(
    childEvent _: ChildEvent.Type,
    @CompositeEffectBuilder<ParentSuperEvent> _ handler: @Sendable @escaping (
      any State<Child2SuperState>,
      ChildEvent
    ) async -> CompositeEffect<ParentSuperEvent>
  ) -> Self {
    let wrappedHandler = CompositeChildEventHandler<
      ParentSuperState,
      ParentSuperEvent,
      Child2SuperState,
      Child2SuperEvent
    >(
      oneOfEvents: OneOfEvents(ChildEvent.self),
      handler: { state, event in
        guard let event = event as? ChildEvent else { return CompositeEffect(actions: []) }
        return await handler(state, event)
      }
    )

    return updating { $0.child2Handlers.append(wrappedHandler) }
  }

  public func on<ChildEvent: Event<Child1SuperEvent>>(
    childEvent _: ChildEvent.Type,
    from child: Any.Type,
    @CompositeEffectBuilder<ParentSuperEvent> _ handler: @Sendable @escaping (
      any State<Child1SuperState>,
      ChildEvent
    ) async -> CompositeEffect<ParentSuperEvent>
  ) -> Self {
    let childId = ObjectIdentifier(child)
    precondition(childId == definition.child1.id, "Child id does not match the first composite child.")

    let wrappedHandler = CompositeChildEventHandler<
      ParentSuperState,
      ParentSuperEvent,
      Child1SuperState,
      Child1SuperEvent
    >(
      oneOfEvents: OneOfEvents(ChildEvent.self),
      handler: { state, event in
        guard let event = event as? ChildEvent else { return CompositeEffect(actions: []) }
        return await handler(state, event)
      }
    )

    return updating { $0.child1Handlers.append(wrappedHandler) }
  }

  public func on<ChildEvent: Event<Child2SuperEvent>>(
    childEvent _: ChildEvent.Type,
    from child: Any.Type,
    @CompositeEffectBuilder<ParentSuperEvent> _ handler: @Sendable @escaping (
      any State<Child2SuperState>,
      ChildEvent
    ) async -> CompositeEffect<ParentSuperEvent>
  ) -> Self {
    let childId = ObjectIdentifier(child)
    precondition(childId == definition.child2.id, "Child id does not match the second composite child.")

    let wrappedHandler = CompositeChildEventHandler<
      ParentSuperState,
      ParentSuperEvent,
      Child2SuperState,
      Child2SuperEvent
    >(
      oneOfEvents: OneOfEvents(ChildEvent.self),
      handler: { state, event in
        guard let event = event as? ChildEvent else { return CompositeEffect(actions: []) }
        return await handler(state, event)
      }
    )

    return updating { $0.child2Handlers.append(wrappedHandler) }
  }

  public func join<S1: State<Child1SuperState>, S2: State<Child2SuperState>>(
    whenChildStates _: S1.Type,
    _ _: S2.Type,
    @CompositeEffectBuilder<ParentSuperEvent> _ handler: @Sendable @escaping () async
      -> CompositeEffect<ParentSuperEvent>
  ) -> Self {
    let joinRule = CompositeJoinRule<
      ParentSuperState,
      ParentSuperEvent,
      Child1SuperState,
      Child2SuperState
    >(
      child1StateId: ObjectIdentifier(S1.self),
      child2StateId: ObjectIdentifier(S2.self),
      handler: handler
    )

    return updating { $0.joinRules.append(joinRule) }
  }

  // MARK: - Internal

  func eraseToAny() -> AnyCompositeDefinition<ParentSuperState, ParentSuperEvent> {
    definition.eraseToAny()
  }

  private func updating(
    _ update: (inout CompositeDefinition2<
      ParentSuperState,
      ParentSuperEvent,
      Child1SuperState,
      Child1SuperEvent,
      Child2SuperState,
      Child2SuperEvent
    >) -> Void
  ) -> Self {
    var updatedDefinition = definition
    update(&updatedDefinition)
    return Composite(definition: updatedDefinition)
  }

  private init(
    definition: CompositeDefinition2<
      ParentSuperState,
      ParentSuperEvent,
      Child1SuperState,
      Child1SuperEvent,
      Child2SuperState,
      Child2SuperEvent
    >
  ) {
    self.definition = definition
  }
}
