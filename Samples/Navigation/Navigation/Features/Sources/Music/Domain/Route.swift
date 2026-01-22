public enum Route: Hashable, Equatable, Sendable, CustomStringConvertible {
  case album(id: String)

  // MARK: - Properties

  // MARK: Public

  public var description: String {
    switch self {
    case .album(let id): "album(id: \(id))"
    }
  }
}
