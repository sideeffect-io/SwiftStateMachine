public enum Route: Hashable, Sendable, CustomStringConvertible {
  case place(id: String)
  case owner(id: String)

  // MARK: - Properties

  // MARK: Public

  public var description: String {
    switch self {
    case .place(let id): "place(id: \(id))"
    case .owner(let id): "owner(id: \(id))"
    }
  }
}
