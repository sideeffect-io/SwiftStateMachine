// swiftformat:disable:next wrapAttributes
public typealias Load = @Sendable () async -> [Place]

public func makeLoad(
  getData: @escaping @Sendable () async throws -> [Place],
  saveData: @escaping @Sendable ([Place]) async throws -> Void
) -> Load {
  {
    do {
      let data = try await getData()
      try await saveData(data)
      return data.filter { $0.stars > 2 }
    } catch {
      return []
    }
  }
}
