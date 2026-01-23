public struct CompositeChild<ChildSuperState, ChildSuperEvent>: Sendable {
  let id: ObjectIdentifier
  let stateMachine: StateMachine<ChildSuperState, ChildSuperEvent>
  let superStateId: ObjectIdentifier
  let superEventId: ObjectIdentifier

  init(stateMachine: StateMachine<ChildSuperState, ChildSuperEvent>) {
    guard let id = stateMachine.id else {
      preconditionFailure("Composite child state machines must provide an id.")
    }
    self.id = id
    self.stateMachine = stateMachine
    superStateId = ObjectIdentifier(ChildSuperState.self)
    superEventId = ObjectIdentifier(ChildSuperEvent.self)
  }
}

public struct CompositeChildren2<C1SuperState, C1SuperEvent, C2SuperState, C2SuperEvent>: Sendable {
  let child1: CompositeChild<C1SuperState, C1SuperEvent>
  let child2: CompositeChild<C2SuperState, C2SuperEvent>
}

@resultBuilder
public enum CompositeBuilder {
  public static func buildExpression<C1SuperState, C1SuperEvent>(
    _ stateMachine: StateMachine<C1SuperState, C1SuperEvent>
  ) -> CompositeChild<C1SuperState, C1SuperEvent> {
    CompositeChild(stateMachine: stateMachine)
  }

  public static func buildBlock<C1SuperState, C1SuperEvent, C2SuperState, C2SuperEvent>(
    _ child1: CompositeChild<C1SuperState, C1SuperEvent>,
    _ child2: CompositeChild<C2SuperState, C2SuperEvent>
  ) -> CompositeChildren2<C1SuperState, C1SuperEvent, C2SuperState, C2SuperEvent> {
    CompositeChildren2(child1: child1, child2: child2)
  }
}
