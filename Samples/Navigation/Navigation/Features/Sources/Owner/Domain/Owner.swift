public struct Owner: Equatable, Sendable {
  public let id: String
  public let name: String
  public let age: Int
  public let address: String

  public init(id: String, name: String, age: Int, address: String) {
    self.id = id
    self.name = name
    self.age = age
    self.address = address
  }

  public static let empty = Self(id: "", name: "", age: 0, address: "")
  public static let fake = Self(id: "1", name: "William Shatner", age: 105, address: "Iowa")
}
