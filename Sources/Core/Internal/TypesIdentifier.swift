/// Uniquely identifies a pair of values thanks to their type
public struct TypesIdentifier: Hashable, Sendable {

  // MARK: - Lifecycle

  // MARK: Internal

  public init(lhsIdentifier: ObjectIdentifier, rhsIdentifier: ObjectIdentifier) {
    self.lhsIdentifier = lhsIdentifier
    self.rhsIdentifier = rhsIdentifier
  }

  public init(lhsValue: Any, rhsValue: Any) {
    lhsIdentifier = ObjectIdentifier(type(of: lhsValue))
    rhsIdentifier = ObjectIdentifier(type(of: rhsValue))
  }

  public init(lhsType: Any.Type, rhsType: Any.Type) {
    lhsIdentifier = ObjectIdentifier(lhsType)
    rhsIdentifier = ObjectIdentifier(rhsType)
  }

  // MARK: - Properties

  // MARK: Internal

  let lhsIdentifier: ObjectIdentifier
  let rhsIdentifier: ObjectIdentifier

  // MARK: - Methods

  // MARK: Internal

  public func hash(into hasher: inout Hasher) {
    hasher.combine(lhsIdentifier)
    hasher.combine(rhsIdentifier)
  }
}
