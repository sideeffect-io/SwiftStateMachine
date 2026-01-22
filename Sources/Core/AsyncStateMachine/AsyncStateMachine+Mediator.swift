import Foundation

extension AsyncStateMachine {
  // MARK: - Methods

  // MARK: Public

  /// Connects the ``AsyncStateMachine`` to a ``Mediator`` as a receiver.
  /// The ``AsyncStateMachine`` can receive events from the ``Mediator``. Those events will be pushed to the internal event stream.
  /// A ``Mediator`` does not keep a strong reference on the receiver ``AsyncStateMachine``.
  /// If the ``AsyncStateMachine`` is dealloc then the senders will send messages in the void.
  /// - Parameter mediator: The ``Mediator`` to be connected to as a receiver of events
  /// - Returns: The ``AsyncStateMachine``
  @discardableResult
  public func connectAsReceiver(
    to mediator: Mediator<SuperEvent>
  ) -> Self {
    mediator.register(receiver: self)
    return self
  }

  /// Connects the ``AsyncStateMachine`` to a ``Mediator`` as a sender.
  /// Events sent through this ``Mediator`` will be pushed to the receiver's internal events stream.
  /// If the provided `send` closure returns `nil` then no event is sent to the receiver.
  /// - Parameters:
  ///   - mediator: The ``Mediator`` to be connected to as a sender of events
  ///   - send: The closure that makes receiver events according to the current state, an event and the new state
  /// - Returns: The ``AsyncStateMachine``
  @discardableResult
  public func connectAsSender<ReceiverSuperEvent>(
    to mediator: Mediator<ReceiverSuperEvent>,
    sending send: @Sendable @escaping (
      UUID,
      any State<SuperState>,
      any Event<SuperEvent>,
      any State<SuperState>
    ) async -> (any Event<ReceiverSuperEvent>)?
  ) -> Self {
    mediator.register(sender: self, sending: send)
    return self
  }

  /// Connects the ``AsyncStateMachine`` to a ``Mediator`` as a sender.
  /// Events sent through this ``Mediator`` will be pushed to the receiver's internal events stream.
  /// If the provided `send` closure returns `nil` then no event is sent to the receiver.
  /// - Parameters:
  ///   - mediator: The ``Mediator`` to be connected to as a sender of events
  ///   - whenCurrentState: The type of current state that will trigger the sending
  ///   - send: The closure that makes receiver events according to the current state, an event and the new state
  /// - Returns: The ``AsyncStateMachine``
  @discardableResult
  public func connectAsSender<ReceiverSuperEvent, S: State<SuperState>>(
    to mediator: Mediator<ReceiverSuperEvent>,
    whenCurrentState _: S.Type,
    sending send: @Sendable @escaping (S, any Event<SuperEvent>, any State<SuperState>) async
      -> (any Event<ReceiverSuperEvent>)?
  ) -> Self {
    connectAsSender(to: mediator) { _, anySenderCurrentState, anySenderEvent, anySenderNewState in
      guard let currentState = anySenderCurrentState as? S else { return nil }
      return await send(
        currentState,
        anySenderEvent,
        anySenderNewState
      )
    }
  }

  /// Connects the ``AsyncStateMachine`` to a ``Mediator`` as a sender.
  /// Events sent through this ``Mediator`` will be pushed to the receiver's internal events stream.
  /// If the provided `send` closure returns `nil` then no event is sent to the receiver.
  /// - Parameters:
  ///   - mediator: The ``Mediator`` to be connected to as a sender of events
  ///   - event: The type of event that will trigger the sending
  ///   - send: The closure that makes receiver events according to the current state, an event and the new state
  /// - Returns: The ``AsyncStateMachine``
  @discardableResult
  public func connectAsSender<ReceiverSuperEvent, E: Event<SuperEvent>>(
    to mediator: Mediator<ReceiverSuperEvent>,
    on _: E.Type,
    sending send: @Sendable @escaping (any State<SuperState>, E, any State<SuperState>) async
      -> (any Event<ReceiverSuperEvent>)?
  ) -> Self {
    connectAsSender(to: mediator) { _, anySenderCurrentState, anySenderEvent, anySenderNewState in
      guard let event = anySenderEvent as? E else { return nil }
      return await send(
        anySenderCurrentState,
        event,
        anySenderNewState
      )
    }
  }

  /// Connects the ``AsyncStateMachine`` to a ``Mediator`` as a sender.
  /// Events sent through this ``Mediator`` will be pushed to the receiver's internal events stream.
  /// If the provided `send` closure returns `nil` then no event is sent to the receiver.
  /// - Parameters:
  ///   - mediator: The ``Mediator`` to be connected to as a sender of events
  ///   - whenCurrentState: The type of the current state that will trigger the sending
  ///   - event: The type of event that will trigger the sending
  ///   - send: The closure that makes receiver events according to the current state, an event and the new state
  /// - Returns: The ``AsyncStateMachine``
  @discardableResult
  public func connectAsSender<ReceiverSuperEvent, S: State<SuperState>, E: Event<SuperEvent>>(
    to mediator: Mediator<ReceiverSuperEvent>,
    whenCurrentState _: S.Type,
    on _: E.Type,
    sending send: @Sendable @escaping (S, E, any State<SuperState>) async -> (any Event<ReceiverSuperEvent>)?
  ) -> Self {
    connectAsSender(to: mediator) { _, anySenderCurrentState, anySenderEvent, anySenderNewState in
      guard let state = anySenderCurrentState as? S else { return nil }
      guard let event = anySenderEvent as? E else { return nil }
      return await send(
        state,
        event,
        anySenderNewState
      )
    }
  }

  /// Connects the ``AsyncStateMachine`` to a ``Mediator`` as a sender.
  /// Events sent through this ``Mediator`` will be pushed to the receiver's internal events stream.
  /// If the provided `send` closure returns `nil` then no event is sent to the receiver.
  /// - Parameters:
  ///   - mediator: The ``Mediator`` to be connected to as a sender of events
  ///   - whenNewState: The type of new state that will trigger the sending
  ///   - send: The closure that makes receiver events according to the current state, an event and the new state
  /// - Returns: The ``AsyncStateMachine``
  @discardableResult
  public func connectAsSender<ReceiverSuperEvent, S: State<SuperState>>(
    to mediator: Mediator<ReceiverSuperEvent>,
    whenNewState _: S.Type,
    sending send: @Sendable @escaping (any State<SuperState>, any Event<SuperEvent>, S) async
      -> (any Event<ReceiverSuperEvent>)?
  ) -> Self {
    connectAsSender(to: mediator) { _, anySenderCurrentState, anySenderEvent, anySenderNewState in
      guard let newState = anySenderNewState as? S else { return nil }
      return await send(
        anySenderCurrentState,
        anySenderEvent,
        newState
      )
    }
  }
}
