import StateMachineShared
import XCTest
@testable import StateMachineCore

extension Output {
  static func makeAssertable(event: some Event<SuperEvent>) -> Assertable {
    Assertable(event: event)
  }

  struct Assertable {
    let spy: SendableStorage<Bool>
    let output: Output<SuperState, SuperEvent>

    init(event: some Event<SuperEvent>) {
      let spy = SendableStorage(value: false)
      output = Output<SuperState, SuperEvent> {
        spy.set(value: true)
        return event
      }
      self.spy = spy
    }
  }
}

func XCTAssert<SuperState, SuperEvent>(
  received: Output<SuperState, SuperEvent>?,
  isFrom assertable: Output<SuperState, SuperEvent>.Assertable,
  file: StaticString = #filePath,
  line: UInt = #line
) async {
  guard let sequence = await received?.sideEffect() else {
    XCTFail(
      "Expected a non `nil` sequence, but the side effect produced a `nil` sequence",
      file: file,
      line: line
    )
    return
  }

  for await _ in sequence { }
  assertable.spy.assertEqual(
    expected: true,
    file: file,
    line: line
  )
}
