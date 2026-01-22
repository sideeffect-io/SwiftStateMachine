public struct Album: Sendable, Equatable, Hashable, Identifiable, Codable {
  public let id: String
  public let title: String
  public let author: String
  public let numberOfSongs: Int

  public init(
    id: String,
    title: String,
    author: String,
    numberOfSongs: Int
  ) {
    self.id = id
    self.title = title
    self.author = author
    self.numberOfSongs = numberOfSongs
  }

  public static let fake = Self(id: "1", title: "Scenes from a memory", author: "Dream Theater", numberOfSongs: 12)
}
