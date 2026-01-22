import Foundation
import StateMachineShared

/// A ``Mediator`` aims to allow several ``AsyncStateMachine`` to communicate without being coupled.
/// A ``Mediator`` can have 1 receiver and several senders.
/// A ``Mediator`` does not keep a strong reference on the receiver. If the receiver is dealloc then the senders will
/// send messages in the void. A new receiver can be set again in the future.
/// A reference to a mediator should be maintained as long as the mediator is used
public final class Mediator<SuperEvent>: Sendable {

  // MARK: - Lifecycle

  // MARK: Public

  public init() {
    receiversStorage = SendableStorage(value: [UUID: SendEventToReceiver]())
  }

  // MARK: - Typealiases

  // MARK: Internal

  typealias SendEventToReceiver = @Sendable (any Event<SuperEvent>) -> Void

  // MARK: - Properties

  // MARK: Internal

  let receiversStorage: SendableStorage<[UUID: SendEventToReceiver]>

  // MARK: - Methods

  // MARK: Public

  /// Send an ``Event`` to the state machines registered as a receivers of the ``Mediator``
  /// - Parameter event: The event to send
  public func sendToReceivers(event: some Event<SuperEvent>) {
    receiversStorage.apply { receivers in
      receivers.values.forEach { sendAction in
        sendAction(event)
      }
    }
  }

  // MARK: Internal

  @discardableResult
  func register<SuperState>(receiver: AsyncStateMachine<SuperState, SuperEvent>) -> Self {
    receiversStorage.apply { receiversMap in
      receiversMap[receiver.id] = { [weak receiver] event in
        receiver?.send(event: event)
      }
    }

    receiver.onDeinit { [weak self] id in
      self?.receiversStorage.apply { receivers in
        receivers.removeValue(forKey: id)
      }
    }

    return self
  }

  @discardableResult
  func register<SenderSuperState, SenderSuperEvent>(
    sender: AsyncStateMachine<SenderSuperState, SenderSuperEvent>,
    sending makeEvent: @Sendable @escaping (
      UUID,
      any State<SenderSuperState>,
      any Event<SenderSuperEvent>,
      any State<SenderSuperState>
    ) async -> (any Event<SuperEvent>)?
  ) -> Self {
    sender.onTransition { [weak self] stateMachineId, currentSenderState, senderEvent, newSenderState in
      guard
        let eventToSend = await makeEvent(
          stateMachineId,
          currentSenderState,
          senderEvent,
          newSenderState
        ) else { return }

      self?.sendToReceivers(event: eventToSend)
    }
    return self
  }
}
