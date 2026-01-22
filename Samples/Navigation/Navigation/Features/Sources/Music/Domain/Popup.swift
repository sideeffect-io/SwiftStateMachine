public enum Popup: Hashable, Equatable, Sendable, Identifiable, CustomStringConvertible {
  case song(id: String)

  // MARK: - Properties

  // MARK: Public

  public var description: String {
    switch self {
    case .song(let id): "song(id: \(id))"
    }
  }

  public var id: Int {
    switch self {
    case .song: 1
    }
  }
}
