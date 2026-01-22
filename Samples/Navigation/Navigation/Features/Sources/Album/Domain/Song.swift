// MARK: - Song

public struct Song: Equatable, Hashable, Identifiable, Sendable, Codable {
  public let id: String
  public let title: String

  public init(
    id: String,
    title: String
  ) {
    self.id = id
    self.title = title
  }

  public static let empty = Self(id: "", title: "")
  public static let fake = Self(id: "0", title: "Strange deja vu")
}
