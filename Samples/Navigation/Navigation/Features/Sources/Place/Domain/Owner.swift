public struct Owner: Equatable, Sendable, Hashable {
  public let id: String
  public let name: String

  public init(id: String, name: String) {
    self.id = id
    self.name = name
  }

  static let empty = Self(id: "", name: "")
  static let fake = Self(id: "1", name: "William Shatner")
}
