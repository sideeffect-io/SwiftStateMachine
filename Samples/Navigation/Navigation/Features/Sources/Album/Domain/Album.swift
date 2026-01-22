public struct Album: Equatable, Sendable, Codable, Hashable {
  public let id: String
  public let title: String
  public let author: String
  public let dateOfRelease: String
  public let producer: String
  public let songs: [Song]

  public init(
    id: String,
    title: String,
    author: String,
    dateOfRelease: String,
    producer: String,
    songs: [Song]
  ) {
    self.id = id
    self.title = title
    self.author = author
    self.dateOfRelease = dateOfRelease
    self.producer = producer
    self.songs = songs
  }

  public static let empty = Self(id: "", title: "", author: "", dateOfRelease: "", producer: "", songs: [])
  public static let fake = Self(
    id: "0",
    title: "Scenes from a memory",
    author: "Dream Theater",
    dateOfRelease: "1999, Oct 26",
    producer: "Portnoy & Petrucci",
    songs: [.fake]
  )
}
