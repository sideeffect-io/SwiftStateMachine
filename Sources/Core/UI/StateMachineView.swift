#if canImport(SwiftUI)
import SwiftUI

/// A ``StateMachineView`` is a SwiftUI View that wraps an ``AsyncStateMachine`` with a ``UIStateMachine`` and exposes it in the form of
/// a @StateObject that is given as a parameter to the content.
/// The ``StateMachineView`` starts the iteration over the ``AsyncStateMachine`` in a `.task` modifier.
/// The ``UIStateMachine`` lifecycle is independant from its parent view Task. The ``UIStateMachine`` iterates over its
/// ``AsyncStateMachine`` in the context of an internal ``Task`` and will iterate over it until it is deallocated.
public struct StateMachineView<UIState: Equatable & Sendable, SuperEvent, Content: View>: View {
  let content: (UIStateMachine<UIState, SuperEvent>) -> Content
  @StateObject var uiStateMachine: UIStateMachine<UIState, SuperEvent>

  /// Creates a ``StateMachineView`` from an ``UIStateMachine``  and the content which depends on the state machine updates.
  /// - Parameters:
  ///   - uiStateMachine: the ``UIStateMachine``
  ///   - content: the content to add to the view hierarchy
  public init(
    uiStateMachine: UIStateMachine<UIState, SuperEvent>,
    @ViewBuilder content: @escaping (UIStateMachine<UIState, SuperEvent>) -> Content
  ) {
    _uiStateMachine = StateObject(wrappedValue: uiStateMachine)
    self.content = content
  }

  /// Creates a ``StateMachineView`` from an ``AsyncStateMachine`` factory and the content which depends on the state machine updates.
  /// - Parameters:
  ///   - factory: the ``AsyncStateMachine`` factory
  ///   - content: the content to add to the view hierarchy
  public init(
    factory: AsyncStateMachineFactory<UIState, SuperEvent>,
    @ViewBuilder content: @escaping (UIStateMachine<UIState, SuperEvent>) -> Content
  ) {
    _uiStateMachine = StateObject(wrappedValue: UIStateMachine(asyncStateMachineFactory: factory))
    self.content = content
  }

  // swiftlint:disable attributes
  /// Creates a ``StateMachineView`` from an ``AsyncStateMachine`` factory, a mapping function and the content which depends on
  /// the state machine updates. The mapping is used to create a UIState from the published state.
  /// - Parameters:
  ///   - factory: the ``AsyncStateMachine`` factory
  ///   - mapping: the mapping to transform a state into a UIState
  ///   - content: the content to add to the view hierarchy
  public init<SuperState: Sendable>(
    factory: AsyncStateMachineFactory<SuperState, SuperEvent>,
    mapping: @Sendable @escaping (SuperState) -> UIState,
    @ViewBuilder content: @escaping (UIStateMachine<UIState, SuperEvent>) -> Content
  ) {
    _uiStateMachine = StateObject(wrappedValue: UIStateMachine(asyncStateMachineFactory: factory, mapping: mapping))
    self.content = content
  }

  public var body: some View {
    content(uiStateMachine)
      .task {
        uiStateMachine.start()
      }
  }
}
#endif
