public enum WhenComponent<S, SuperState, SuperEvent> {
  case on(On<S, SuperState, SuperEvent>)
  case composite(AnyCompositeDefinition<SuperState, SuperEvent>)
}
