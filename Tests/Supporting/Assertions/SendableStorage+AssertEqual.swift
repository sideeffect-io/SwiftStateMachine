import StateMachineShared
import XCTest

extension SendableStorage {
  func assertEqual(expected: Any, file _: StaticString = #filePath, line _: UInt = #line) {
    XCTAssertEqual(anyLhs: get(), anyRhs: expected)
  }
}
