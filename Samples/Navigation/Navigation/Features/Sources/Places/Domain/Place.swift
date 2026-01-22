public struct Place: Sendable, Hashable, Equatable {
  public let id: String
  public let name: String
  public let stars: Int

  public init(id: String, name: String, stars: Int) {
    self.id = id
    self.name = name
    self.stars = stars
  }

  public static let fake = Self(id: "1", name: "Birra", stars: 5)
}
