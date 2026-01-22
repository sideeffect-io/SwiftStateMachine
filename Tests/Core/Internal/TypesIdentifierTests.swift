import StateMachineCore
import XCTest

// MARK: - TypeA

private struct TypeA { }

// MARK: - TypeB

private struct TypeB { }

// MARK: - TypesIdentifierTests

final class TypesIdentifierTests: XCTestCase {
  func test_typesAndValues_haveSameHash() {
    // Given: values with types
    let lhs = TypeA()
    let rhs = TypeB()

    // When: making their TypesIdentifiers based on their values and their types
    let sutValues = TypesIdentifier(lhsValue: lhs, rhsValue: rhs)
    let sutTypes = TypesIdentifier(lhsType: TypeA.self, rhsType: TypeB.self)
    let sutIdentifiers = TypesIdentifier(
      lhsIdentifier: ObjectIdentifier(TypeA.self),
      rhsIdentifier: ObjectIdentifier(TypeB.self)
    )

    // Then: TypesIdentifier share the same hash
    let sutValuesHashValue = sutValues.hashValue
    let sutTypesHashValue = sutTypes.hashValue
    let sutIdentifiersHashValue = sutIdentifiers.hashValue

    XCTAssertEqual(
      sutValuesHashValue,
      sutTypesHashValue,
      """
      Expected values and types to have an identical hash value,
      but got a hash value of \(sutValuesHashValue) for values and of \(sutTypesHashValue) for types.
      """
    )

    XCTAssertEqual(
      sutTypesHashValue,
      sutIdentifiersHashValue,
      """
      Expected types and identifiers to have an identical hash value,
      but got a hash value of \(sutTypesHashValue) for values and of \(sutIdentifiersHashValue) for types.
      """
    )
  }
}
