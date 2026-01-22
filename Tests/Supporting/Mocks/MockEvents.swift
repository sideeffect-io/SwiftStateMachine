import StateMachineCore

// MARK: - LoadingWasRequested

struct LoadingWasRequested { let id: Int }

// MARK: - ReloadingWasRequested

struct ReloadingWasRequested { let id: Int }

// MARK: - LoadingHasSucceeded

struct LoadingHasSucceeded { let value: Int }

// MARK: - LoadingHasFailed

struct LoadingHasFailed { let error: MockError }

// MARK: - MockSuperEvent

enum MockSuperEvent: Equatable { }

// MARK: - LoadingWasRequested + Event, Equatable

extension LoadingWasRequested: Event, Equatable {
  typealias SuperEvent = MockSuperEvent
}

// MARK: - LoadingHasSucceeded + Event, Equatable

extension LoadingHasSucceeded: Event, Equatable {
  typealias SuperEvent = MockSuperEvent
}

// MARK: - LoadingHasFailed + Event, Equatable

extension LoadingHasFailed: Event, Equatable {
  typealias SuperEvent = MockSuperEvent
}

// MARK: - ReloadingWasRequested + Event, Equatable

extension ReloadingWasRequested: Event, Equatable {
  typealias SuperEvent = MockSuperEvent
}

// MARK: - SenderLoadingWasRequested

struct SenderLoadingWasRequested { let id: Int }

// MARK: - SenderLoadingHasSucceeded

struct SenderLoadingHasSucceeded { let id: Int }

// MARK: - SenderReloadingWasRequested

struct SenderReloadingWasRequested { let id: Int }

// MARK: - SenderMockSuperEvent

enum SenderMockSuperEvent: Equatable { }

// MARK: - SenderLoadingWasRequested + Event, Equatable

extension SenderLoadingWasRequested: Event, Equatable {
  typealias SuperEvent = SenderMockSuperEvent
}

// MARK: - SenderLoadingHasSucceeded + Event, Equatable

extension SenderLoadingHasSucceeded: Event, Equatable {
  typealias SuperEvent = SenderMockSuperEvent
}

// MARK: - SenderReloadingWasRequested + Event, Equatable

extension SenderReloadingWasRequested: Event, Equatable {
  typealias SuperEvent = SenderMockSuperEvent
}
