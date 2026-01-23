extension AsyncStateMachine {
  public struct Iterator: AsyncIteratorProtocol {
    // MARK: - Lifecycle

    // MARK: Internal

    init(asyncStateMachine: AsyncStateMachine<SuperState, SuperEvent>) {
      self.asyncStateMachine = asyncStateMachine
      eventIterator = asyncStateMachine.eventStream.makeAsyncIterator()
    }

    // MARK: - Properties

    // MARK: Internal

    let asyncStateMachine: AsyncStateMachine<SuperState, SuperEvent>
    var eventIterator: AsyncUnicastChannel<EventToken>.AsyncIterator

    // MARK: - Methods

    // MARK: Public

    public mutating func next() async -> Element? {
      guard !Task.isCancelled else {
        await asyncStateMachine.runtime.cancelAll()
        await asyncStateMachine.compositeCoordinator?.deactivateAll()
        return nil
      }

      // handle the initial state
      guard let currentState = asyncStateMachine.currentState.get() else {
        // set the initial state as the current state
        asyncStateMachine.currentState.set(value: asyncStateMachine.stateMachine.initial)
        // process the initial state
        await processInitialState()
        return asyncStateMachine.stateMachine.initial
      }

      // handle the subsequent states
      var newState: (any State<SuperState>)?
      while newState == nil {
        // extract the next event token from the event queue
        guard let eventToken = await eventIterator.next() else {
          // no more possible events, the state machine ends
          await asyncStateMachine.runtime.cancelAll()
          await asyncStateMachine.compositeCoordinator?.deactivateAll()
          return nil
        }

        // resolve the transition according to the current state and the event
        let mealyTransition = await asyncStateMachine.stateMachine.transition(
          state: currentState,
          event: eventToken.event
        )

        // extract and process the new state
        newState = await mealyTransition?.transition?.state()
        await processNewState(
          newState: newState,
          currentState: currentState,
          event: eventToken.event
        )

        // extract and process the output if any,
        // otherwise directly resume the continuation (if any) from the event token
        if let output = mealyTransition?.output {
          await executeOutput(
            output: output,
            eventToken: eventToken
          )
        } else {
          eventToken.continuation?.resume()
        }
      }

      asyncStateMachine.currentState.set(value: newState)
      return newState
    }

    // MARK: Private

    private func processInitialState() async {
      // calls the `onInitialStates` callbacks with the initial state
      let onInitialStates = asyncStateMachine.onInitialStates.get()
      if !onInitialStates.isEmpty {
        await asyncStateMachine.runtime.execute(
          onInitialStates: onInitialStates,
          id: asyncStateMachine.id,
          initialState: asyncStateMachine.stateMachine.initial
        )
      }
      await asyncStateMachine.compositeCoordinator?
        .handleInitialState(state: asyncStateMachine.stateMachine.initial)
    }

    private func processNewState(
      newState: (any State<SuperState>)?,
      currentState: some State<SuperState>,
      event: some Event<SuperEvent>
    ) async {
      // cancel the tasks in progress for which the tuple current state/event/new state is a trigger for cancellation
      // the new state can be nil, still we might want to cancel some outputs for the tuple current state / event
      await asyncStateMachine.runtime.cancel(currentState: currentState, event: event, newState: newState)

      await asyncStateMachine.compositeCoordinator?
        .handleTransition(currentState: currentState, event: event, newState: newState)

      guard let newState else { return }

      // log the transition
      if asyncStateMachine.shouldLog.get() {
        await log(
          title: "\(SuperState.self)",
          currentState: currentState,
          event: event,
          newState: newState
        )
      }

      // execute the `onTransitions` callbacks with the current state, the received event and the new state
      let onTransitions = asyncStateMachine.onTransitions.get()
      if !onTransitions.isEmpty {
        await asyncStateMachine.runtime.execute(
          onTransitions: onTransitions,
          id: asyncStateMachine.id,
          currentState: currentState,
          on: event,
          newState: newState
        )
      }
    }

    private func executeOutput(
      output: Output<SuperState, SuperEvent>,
      eventToken: EventToken
    ) async {
      // execute the related output if any. if the eventTokan has an associated continuation, we wait for the output
      // to be completed before resuming the send operation.
      // if there is no output, we immediately resume the continuation so the sending operation
      // is not suspended for ever
      let endOfWorkTask = await asyncStateMachine.runtime.execute(
        output: output
      ) { [eventStream = self.asyncStateMachine.eventStream] event in
        eventStream.send(EventToken(event: event, continuation: nil))
      }
      if let continuation = eventToken.continuation {
        // in order to avoid blocking the state machine while the output is executing
        // we wait for its completion in a dedicated Task
        Task {
          await endOfWorkTask.value
          continuation.resume()
        }
      }
    }
  }
}
