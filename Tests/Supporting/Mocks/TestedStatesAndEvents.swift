// MARK: - TestedState

enum TestedState {
  static let idle = Idle()
  static let loading = Loading()
  static let loaded = Loaded(value: 1701)
  static let failed = Failed(error: MockError())

  static let senderIdle = SenderIdle()
  static let senderLoading = SenderLoading()
  static let senderLoaded = SenderLoaded()
}

// MARK: - TestedEvent

enum TestedEvent {
  static let loadingRequestedWithValue1701 = LoadingWasRequested(id: 1701)

  static let reloadingRequestedWithValue1701 = ReloadingWasRequested(id: 1701)
  static let reloadingRequestedWithValue1702 = ReloadingWasRequested(id: 1702)

  static let loadingSucceededWithValue1 = LoadingHasSucceeded(value: 1)
  static let loadingSucceededWithValue1701 = LoadingHasSucceeded(value: 1701)
  static let loadingSucceededWithValue1702 = LoadingHasSucceeded(value: 1702)
  static let loadingSucceededWithValue1703 = LoadingHasSucceeded(value: 1703)

  static let loadingFailed = LoadingHasFailed(error: MockError())

  static let senderLoadingRequested = SenderLoadingWasRequested(id: 1701)
  static let senderReloadingRequested = SenderReloadingWasRequested(id: 1701)

  static let senderLoadingSucceeded = SenderLoadingHasSucceeded(id: 1701)
}
