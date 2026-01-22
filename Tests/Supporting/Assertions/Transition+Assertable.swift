import StateMachineCore
import StateMachineShared
import XCTest

extension Transition {
  static func makeAssertable(state: some State<SuperState>) -> Assertable {
    Assertable(state: state)
  }

  struct Assertable {
    let spy: SendableStorage<Bool>
    let transition: Transition<SuperState>

    init(state: some State<SuperState>) {
      let spy = SendableStorage(value: false)
      transition = Transition {
        spy.set(value: true)
        return state
      }
      self.spy = spy
    }
  }
}

func XCTAssert<SuperState>(
  received: Transition<SuperState>?,
  isFrom assertable: Transition<SuperState>.Assertable,
  file: StaticString = #filePath,
  line: UInt = #line
) async {
  _ = await received?.state()
  assertable.spy.assertEqual(
    expected: true,
    file: file,
    line: line
  )
}
