import SwiftUI

// MARK: - View + redacted

extension View {
  public func redacted(when condition: Bool) -> some View {
    modifier(ConditionalRedactedModifier(isRedacted: condition))
  }
}

// MARK: - ConditionalRedactedModifier

public struct ConditionalRedactedModifier: ViewModifier {
  let isRedacted: Bool

  public func body(content: Content) -> some View {
    if isRedacted {
      content.redacted(reason: .placeholder)
    } else {
      content
    }
  }
}
