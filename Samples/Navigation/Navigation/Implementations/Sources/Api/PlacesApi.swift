// MARK: - Star

public struct Star {
  public let value: Int
}

// MARK: - Owner

public struct Owner {
  public let id: String
  public let firstName: String
  public let lastName: String
  public let address: String
  public let age: String
}

// MARK: - Place

public struct Place {
  public let id: String
  public let name: String
  public let description: String
  public let address: String
  public let phone: String
  public let owner: Owner
  public let stars: [Star]
}

// MARK: - PlacesResponse

public struct PlacesResponse {
  public let places: [Place]
}

// MARK: - PlaceResponse

public struct PlaceResponse {
  public let place: Place
}

// MARK: - OwnerResponse

public struct OwnerResponse {
  public let owner: Owner
}

let fakeDescription =
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In non augue at enim volutpat pharetra. Phasellus a ultrices sapien, a pharetra quam."
let fakeAddress = "Petite Italie"
let fakePhone = "(514) 345 123 5432"
let fakeOwners = [
  Owner(id: "0", firstName: "Patrick", lastName: "Stewart", address: fakeAddress, age: "\(Int.random(in: 18...99))"),
  Owner(id: "1", firstName: "Jonathan", lastName: "Frakes", address: fakeAddress, age: "\(Int.random(in: 18...99))"),
  Owner(id: "2", firstName: "William", lastName: "Shatner", address: fakeAddress, age: "\(Int.random(in: 18...99))"),
  Owner(id: "3", firstName: "Leonard", lastName: "Nimoy", address: fakeAddress, age: "\(Int.random(in: 18...99))"),
  Owner(id: "4", firstName: "DeForest", lastName: "Kelley", address: fakeAddress, age: "\(Int.random(in: 18...99))"),
  Owner(id: "5", firstName: "Georges", lastName: "Takei", address: fakeAddress, age: "\(Int.random(in: 18...99))"),
  Owner(id: "6", firstName: "Zoe", lastName: "Saldaña", address: fakeAddress, age: "\(Int.random(in: 18...99))"),
  Owner(id: "7", firstName: "Nichel", lastName: "Nichols", address: fakeAddress, age: "\(Int.random(in: 18...99))"),
  Owner(id: "8", firstName: "Walter", lastName: "Koenig", address: fakeAddress, age: "\(Int.random(in: 18...99))"),
  Owner(id: "9", firstName: "James", lastName: "Doohan", address: fakeAddress, age: "\(Int.random(in: 18...99))")
]
let fakePlaces = [
  Place(
    id: "0",
    name: "Hard Rock Café",
    description: fakeDescription,
    address: fakeAddress,
    phone: fakePhone,
    owner: fakeOwners.randomElement()!,
    stars: []
  ),
  Place(
    id: "1",
    name: "Birra",
    description: fakeDescription,
    address: fakeAddress,
    phone: fakePhone,
    owner: fakeOwners.randomElement()!,
    stars: []
  ),
  Place(
    id: "2",
    name: "Harricana",
    description: fakeDescription,
    address: fakeAddress,
    phone: fakePhone,
    owner: fakeOwners.randomElement()!,
    stars: []
  ),
  Place(
    id: "3",
    name: "Le Lab",
    description: fakeDescription,
    address: fakeAddress,
    phone: fakePhone,
    owner: fakeOwners.randomElement()!,
    stars: []
  ),
  Place(
    id: "4",
    name: "Saint Houblon",
    description: fakeDescription,
    address: fakeAddress,
    phone: fakePhone,
    owner: fakeOwners.randomElement()!,
    stars: []
  ),
  Place(
    id: "5",
    name: "Les 3 Brasseurs",
    description: fakeDescription,
    address: fakeAddress,
    phone: fakePhone,
    owner: fakeOwners.randomElement()!,
    stars: []
  ),
  Place(
    id: "6",
    name: "Vice Versa",
    description: fakeDescription,
    address: fakeAddress,
    phone: fakePhone,
    owner: fakeOwners.randomElement()!,
    stars: []
  ),
  Place(
    id: "7",
    name: "Brewsky",
    description: fakeDescription,
    address: fakeAddress,
    phone: fakePhone,
    owner: fakeOwners.randomElement()!,
    stars: []
  ),
  Place(
    id: "8",
    name: "Wills",
    description: fakeDescription,
    address: fakeAddress,
    phone: fakePhone,
    owner: fakeOwners.randomElement()!,
    stars: []
  ),
  Place(
    id: "9",
    name: "Kabinet",
    description: fakeDescription,
    address: fakeAddress,
    phone: fakePhone,
    owner: fakeOwners.randomElement()!,
    stars: []
  )
]

func makeFakePlaces() -> [Place] {
  // add some randomness
  fakePlaces.map {
    Place(
      id: $0.id,
      name: $0.name,
      description: $0.description,
      address: $0.address,
      phone: $0.phone,
      owner: $0.owner,
      stars: (1...Int.random(in: 1...5)).map { Star(value: $0) }
    )
  }
}

public func fetchPlaces() async throws -> PlacesResponse {
  try await Task.sleep(for: .seconds(1))

  let places = makeFakePlaces()
  return PlacesResponse(places: places)
}

public func fetchPlace(id: String) async throws -> PlaceResponse {
  try await Task.sleep(for: .seconds(1))

  let place = fakePlaces.first(where: { $0.id == id })!
  return PlaceResponse(place: place)
}

public func fetchOwner(id: String) async throws -> OwnerResponse {
  try await Task.sleep(for: .seconds(1))

  let owner = fakeOwners.first(where: { $0.id == id })!
  return OwnerResponse(owner: owner)
}
