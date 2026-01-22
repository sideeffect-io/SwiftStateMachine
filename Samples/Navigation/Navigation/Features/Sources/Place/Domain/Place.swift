public struct Place: Equatable, Sendable {
  public let id: String
  public let name: String
  public let address: String
  public let telephone: String
  public let description: String
  public let owner: Owner

  public init(id: String, name: String, address: String, telephone: String, description: String, owner: Owner) {
    self.id = id
    self.name = name
    self.address = address
    self.telephone = telephone
    self.description = description
    self.owner = owner
  }

  public static let empty = Self(id: "", name: "", address: "", telephone: "", description: "", owner: .empty)
  public static let fake = Self(
    id: "1",
    name: "Birra",
    address: "Petite Italie",
    telephone: "(514) 304 241 3456",
    description: "Best place ever!",
    owner: .fake
  )
}
