import StateMachineCore
import StateMachineShared
import XCTest

// MARK: - ThroughputMetric

final class ThroughputMetric: NSObject, XCTMetric, @unchecked
Sendable {
  var eventCount = 0

  override init() { }

  func reportMeasurements(
    from startTime: XCTPerformanceMeasurementTimestamp,
    to endTime: XCTPerformanceMeasurementTimestamp
  ) throws -> [XCTPerformanceMeasurement] {
    [
      XCTPerformanceMeasurement(
        identifier: "com.touchtunes",
        displayName: "Throughput",
        doubleValue: Double(eventCount) /
          (endTime.date.timeIntervalSinceReferenceDate - startTime.date.timeIntervalSinceReferenceDate),
        unitSymbol: " Events/sec",
        polarity: .prefersLarger
      ),
    ]
  }

  func copy(with _: NSZone? = nil) -> Any {
    self
  }

  func willBeginMeasuring() {
    eventCount = 0
  }

  func didStopMeasuring() { }
}

// MARK: - AsyncStateMachineThroughputTests

final class AsyncStateMachineThroughputTests: XCTestCase {
  // Should be executed with macOS as a destination since the iOS simulator collaborative thread pool is limited to 1 thread.
  #if os(macOS)
  func test_throughput_whenSimpleStateMachine_isPerformant() {
    let metric = ThroughputMetric()
    let iterations = 2_000

    // Given
    let stateMachine = StateMachine(initial: Idle()) {
      When(
        states:
        Idle.self,
        Loaded.self
      ) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: Loading())
        }
      }

      When(state: Loading.self) {
        On(event: LoadingHasSucceeded.self, guard: { _, event in event.value > 1700 }) { _, event in
          Transition(state: Loaded(value: event.value))
        }
      }
    }

    measure(metrics: [metric]) {
      let sut = AsyncStateMachine(stateMachine: stateMachine)
      let sequenceIsFinished = expectation(description: "The sequence is finished")
      let receivedStates = SendableStorage(value: 0)

      let iteratorTask = Task {
        for await _ in sut {
          receivedStates.apply { $0 += 1 }
        }
        metric.eventCount = receivedStates.get()
        sequenceIsFinished.fulfill()
      }

      Task {
        for _ in 0..<iterations {
          sut.send(event: LoadingWasRequested(id: 1701))
          sut.send(event: LoadingHasSucceeded(value: 1701))
        }
        sut.finish()
      }

      wait(for: [sequenceIsFinished], timeout: 5.0)
      iteratorTask.cancel()
    }
  }
  #endif
}
