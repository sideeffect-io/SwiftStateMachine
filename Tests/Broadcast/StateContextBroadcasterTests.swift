import StateMachineBroadcast
import StateMachineCore
import StateMachineShared
import XCTest

final class StateContextBroadcasterTests: XCTestCase, @unchecked Sendable {
  func test_activeSubscriber_receivesInitialAndTransitionContextsInOrder() async {
    let receivedContexts = SendableStorage<[StateContext]>(value: [])
    let receivedBothContexts = expectation(description: "The subscriber received both lifecycle contexts")
    let broadcaster = makeStateContextBroadcaster()

    let machine = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: Loading())
        }
      }
    }
    .activateBroadcast()

    let consumer = Task {
      var iterator = broadcaster.stream.makeAsyncIterator()
      for _ in 0..<2 {
        guard let context = await iterator.next() else { return }
        receivedContexts.apply { $0.append(context) }
      }
      receivedBothContexts.fulfill()
    }

    await machine.sendAndWait(
      event: LoadingWasRequested(id: 1701),
      until: .transitionCommitted
    )
    await fulfillment(of: [receivedBothContexts], timeout: 1.0)

    let contexts = receivedContexts.get()
    XCTAssertTrue(contexts[0].currentState is Idle)
    XCTAssertNil(contexts[0].event)
    XCTAssertNil(contexts[0].newState)
    XCTAssertTrue(contexts[1].currentState is Idle)
    XCTAssertTrue(contexts[1].event is LoadingWasRequested)
    XCTAssertTrue(contexts[1].newState is Loading)

    broadcaster.stop()
    await consumer.value
    await machine.finishAndWait()
  }
}
