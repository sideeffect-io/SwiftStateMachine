public enum CompositeAction<ParentSuperEvent>: Sendable {
  case forward(childId: ObjectIdentifier, event: any Sendable)
  case raise(event: any Event<ParentSuperEvent>)
}

public struct CompositeEffect<ParentSuperEvent>: Sendable {
  let actions: [CompositeAction<ParentSuperEvent>]

  static func merge(_ effects: [CompositeEffect<ParentSuperEvent>]) -> CompositeEffect<ParentSuperEvent> {
    CompositeEffect(actions: effects.flatMap(\.actions))
  }
}

@resultBuilder
public enum CompositeEffectBuilder<ParentSuperEvent> {
  public static func buildExpression(
    _ effect: CompositeEffect<ParentSuperEvent>
  ) -> CompositeEffect<ParentSuperEvent> {
    effect
  }

  public static func buildBlock(
    _ effects: CompositeEffect<ParentSuperEvent>...
  ) -> CompositeEffect<ParentSuperEvent> {
    CompositeEffect.merge(effects)
  }
}

public func Forward<ParentSuperEvent, ChildEvent: Event>(
  to child: Any.Type,
  event: ChildEvent
) -> CompositeEffect<ParentSuperEvent> {
  CompositeEffect(actions: [
    .forward(childId: ObjectIdentifier(child), event: event)
  ])
}

public func Raise<ParentSuperEvent, ParentEvent: Event>(
  event: ParentEvent
) -> CompositeEffect<ParentSuperEvent> where ParentEvent.SuperEvent == ParentSuperEvent {
  CompositeEffect(actions: [
    .raise(event: event)
  ])
}
