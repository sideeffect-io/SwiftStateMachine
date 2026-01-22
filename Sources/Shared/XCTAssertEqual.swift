#if DEBUG
import XCTestDynamicOverlay

public func XCTAssertEqual(
  anyLhs: Any,
  anyRhs: Any,
  fail: (String, StaticString, UInt) -> Void = XCTFail(_:file:line:),
  file: StaticString = #filePath,
  line: UInt = #line
) {
  guard let lhsEquatable = anyLhs as? any Equatable, let rhsEquatable = anyRhs as? any Equatable else {
    fail("Expected \(anyRhs) to be equal to \(anyLhs)", file, line)
    return
  }

  guard lhsEquatable.isEqual(rhsEquatable) else {
    fail("Expected \(lhsEquatable) to be equal to \(rhsEquatable)", file, line)
    return
  }
}
#endif

extension Equatable {
  public func isEqual(_ other: Any) -> Bool {
    guard let other = other as? Self else {
      return false
    }

    return other == self
  }
}
