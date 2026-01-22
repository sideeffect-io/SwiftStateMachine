struct MockError: Error, Equatable {
  let seed = Int.random(in: 0...100)
}
