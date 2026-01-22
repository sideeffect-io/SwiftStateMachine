import SwiftUI

// MARK: - UnitsUIState

public struct UnitsUIState: Equatable {
  let unitsState: UnitsState
  let color: Color
}

@Sendable
public func makeUIState(state: UnitsState) -> UnitsUIState {
  var color = Color.accentColor
  if state.isIncreasing {
    color = .green
  } else if state.isDecreasing {
    color = .red
  }
  return UnitsUIState(unitsState: state, color: color)
}
