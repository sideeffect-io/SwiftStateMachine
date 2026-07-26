/// A strongly typed reference to a concrete ``Event`` type.
///
/// `EventType` enables contextual member syntax in the DSL while preserving
/// the concrete event type inferred by ``On``.
public struct EventType<EventValue: Event>: Sendable {
  let type: EventValue.Type

  public init(_ type: EventValue.Type) {
    self.type = type
  }
}

/// A type-erased event reference accepted by ``OneOfEventsBuilder``.
///
/// Result builders intentionally erase grouped events, so their contextual
/// members use this super-event-scoped reference instead of ``EventType``.
public struct EventSetType<SuperEvent>: Sendable {
  let type: any Event<SuperEvent>.Type

  public init<E: Event<SuperEvent>>(_ type: E.Type) {
    self.type = type
  }
}
