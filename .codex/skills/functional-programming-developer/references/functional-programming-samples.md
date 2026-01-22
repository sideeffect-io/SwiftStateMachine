# Functional programming samples

This file describes the functional programming approach when it comes to modeling data, passing side effect functions to a use case and unit testing it.

## Feature level

### Domain

- Domain is done at the feature level.
- It uses immutable data types
- It uses composition of immutable data types to achieve larger data types

```
enum Sex {
    case male
    case female
}

struct Person: Sendable {
    let id: String
    let name: String
    let lastName: String
    let sex: Sex
}
```

### Business

- Business is done at the feature level and describes the rules of performing an action.
- It uses function injection to compose a more complex behaviour.
- It is unit testable.
- Functions contain no implementation details, only orchestration.

```
@concurrent
func savePerson(
    person: Person,
    save: sending (Person) async throws -> (),
    onError: sending (Person, Error) async -> ()
) async {
    do {
        try await save(person)
    } catch {
        await onError(person, error)
    }
}

@concurrent
func deletePerson(
    person: Person,
    isAuthorized: sending () async -> Bool,
    delete: sending (Person) async throws -> (),
    onError: sending (Person, Error) async -> ()
) async {
    guard await isAuthorized() else { return }
    
    do {
        try await delete(person)
    } catch {
        await onError(person, error)
    }
}
```

## App Level / Dependency injection

- Dependency injection happens at the App top level where concrete implementations are allowed
- it uses factory functions to create concrete implementations of the features

```
func makeSavePersonUseCase() -> sending (Person) async -> () {
    return { (person: Person) async in
        await savePerson(
            person: person,
            save: { try await DataAcessObject().save(entity: $0) },
            onError: { print("Error while saving \($0) : \($1)")})
    }
}

func makeDeletePersonUseCase() -> sending (Person) async -> () {
    return { (person: Person) async in
        await deletePerson(
            person: person,
            isAuthorized: { await Permissions().hasPermissions() },
            delete: { try await DataAcessObject().delete(entity: $0) },
            onError: { print("Error while deleting \($0) : \($1)")})
    }
}

let savePersonUsageCase: (Person) async -> () = makeSavePersonUseCase()
let deletePersonUsageCase: (Person) async -> () = makeDeletePersonUseCase()


```

## Unit tests

- It tests the feature by passing fake functions that records the execution

```
@Test func testWhenNoErrorThenSaveIsCalled() async {
    // Given
    let expectedPerson = Person(id: "1", name: "2", lastName: "3", sex: .male)
    var receivedPerson: Person? = nil
    var receivedError: Error? = nil
    
    // When
    await savePerson(
        person: person,
        save: { receivedPerson = $0 },
        onError: { receivedError = $1 }
    )
    
    // Then
    XCTAssertEqual(receivedPerson, expectedPerson)
    XCTAssertNil(receivedError)
}

@Test func testWhenErrorThenOnErrorIsCalled() async {
    // Given
    let expectedPerson = Person(id: "1", name: "2", lastName: "3", sex: .male)
    let expectedError = SaveError.dbError
    var receivedPerson: Person? = nil
    var receivedError: SaveError? = nil
    
    // When
    await savePerson(
        person: person,
        save: { _ in throw expectedError },
        onError: {
            receivedPerson = $0
            receivedError = $1 as? SaveError
        }
    )
    
    // Then
    XCTAssertEqual(receivedPerson, expectedPerson)
    XCTAssertEqual(receivedError, expectedError)
}
```