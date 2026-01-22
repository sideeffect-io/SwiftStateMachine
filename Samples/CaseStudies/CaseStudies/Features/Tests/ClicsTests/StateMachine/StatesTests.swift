import StateMachineCore
import XCTest
@testable import Clics

// swiftlint:disable implicitly_unwrapped_optional

final class StatesTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
    expected = nil
    received = nil
  }

  // MARK: - Types

  private enum TestedState {
    static let idle = ClicsState(
      numberOfLoads: 0,
      isLoading: false,
      canLoad: true,
      canReset: false
    )

    static let loading = ClicsState(
      numberOfLoads: 0,
      isLoading: true,
      canLoad: true,
      canReset: false
    )

    static let loaded = ClicsState(
      numberOfLoads: StatesTests.numberOfLoads,
      isLoading: false,
      canLoad: false,
      canReset: true
    )
  }

  // MARK: - Properties

  static let numberOfLoads = Int.random(in: 0...100)

  var sut: (any StateMachineCore.State)!
  var expected: ClicsState!
  var received: ClicsState!

  // MARK: - Methods

  func test_idleState_derivesExpectedSuperState() {
    // Given
    sut = DataIsIdle()

    // When
    received = sut.superState as? ClicsState

    // Then
    expected = TestedState.idle
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the super state derived from the idle state to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }

  func test_loadingState_derivesExpectedSuperState() {
    // Given
    sut = DataIsLoading()

    // When
    received = sut.superState as? ClicsState

    // Then
    expected = TestedState.loading
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the super state derived from the loading state to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }

  func test_loadedState_derivesExpectedSuperstate() {
    // Given
    sut = DataIsLoaded(numberOfLoads: Self.numberOfLoads)

    // When
    received = sut.superState as? ClicsState

    // Then
    expected = TestedState.loaded
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the super state derived from the loaded state to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }
}
