public struct Song: Equatable, Sendable {
  public let title: String
  public let author: String
  public let duration: String

  public init(
    title: String,
    author: String,
    duration: String
  ) {
    self.title = title
    self.author = author
    self.duration = duration
  }

  public static let empty = Self(title: "", author: "", duration: "")
  public static let fake = Self(title: "Strange deja vu", author: "Mike Portnoy", duration: "5:12")
}
