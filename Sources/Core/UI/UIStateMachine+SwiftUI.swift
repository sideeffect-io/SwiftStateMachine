#if canImport(SwiftUI)
import SwiftUI

extension UIStateMachine {
  // MARK: - Methods

  // MARK: Public

  /// Creates a ``Binding`` on a sub part of the state machine state.
  /// The binding sends an event in the state machine when a new value is set.
  /// - Parameters:
  ///   - subStateFactory: The closure building the sub part from the state
  ///   - eventFactory: The closure building the event from the new value
  /// - Returns: a ``Binding`` reading the sub part and sending the event
  public func binding<SubState>(
    get subStateFactory: @escaping (UIState) -> SubState,
    send eventFactory: @escaping (SubState) -> (any Event<SuperEvent>)?
  ) -> Binding<SubState> {
    Binding {
      subStateFactory(self.state)
    } set: { [send] subState in
      if let event = eventFactory(subState) {
        send(event)
      }
    }
  }

  /// Creates a ``Binding`` on a sub part of the state machine state.
  /// The binding sends an event in the state machine when a new value is set.
  /// - Parameters:
  ///   - keypath: The keypath accessing the sub part from the state
  ///   - eventFactory: The closure building the event from the new value
  /// - Returns: a ``Binding`` reading the sub part and sending the event
  public func binding<SubState>(
    _ keypath: KeyPath<UIState, SubState>,
    send eventFactory: @escaping (SubState) -> (any Event<SuperEvent>)?
  ) -> Binding<SubState> {
    Binding {
      self.state[keyPath: keypath]
    } set: { [send] subState in
      if let event = eventFactory(subState) {
        send(event)
      }
    }
  }

  /// Creates a ``Binding`` on a sub part of the state machine state.
  /// The binding sends an event in the state machine when a new value is set.
  /// - Parameters:
  ///   - keypath: The keypath accessing the sub part from the state
  ///   - event: The event to send to the state machine when the value is set
  /// - Returns: a ``Binding`` reading the sub part and sending the event
  public func binding<SubState>(
    _ keypath: KeyPath<UIState, SubState>,
    send event: some Event<SuperEvent>
  ) -> Binding<SubState> {
    Binding {
      self.state[keyPath: keypath]
    } set: { [send] _ in
      send(event)
    }
  }

  /// Creates a ``Binding`` on a sub part of the state machine state.
  /// - Parameters:
  ///   - keypath: The keypath accessing the sub part from the state
  /// - Returns: a ``Binding`` reading the sub part
  public func binding<SubState>(
    _ keypath: KeyPath<UIState, SubState>
  ) -> Binding<SubState> {
    Binding {
      self.state[keyPath: keypath]
    } set: { _ in
    }
  }
}
#endif
