import Darwin

// MARK: - LockedBuffer

final class LockedBuffer<Value>: ManagedBuffer<Value, os_unfair_lock> {
  deinit {
    _ = withUnsafeMutablePointerToElements { lock in
      lock.deinitialize(count: 1)
    }
  }
}

// MARK: - SendableStorage

/// @unchecked Sendable is justified by internal locking.
public struct SendableStorage<Value: Sendable>: @unchecked Sendable {

  // MARK: - Lifecycle

  // MARK: Internal

  public init(value: Value) {
    buffer = LockedBuffer.create(minimumCapacity: 1) { buffer in
      buffer.withUnsafeMutablePointerToElements { lock in
        lock.initialize(to: os_unfair_lock())
      }
      return value
    }
  }

  // MARK: - Properties

  // MARK: Internal

  let buffer: ManagedBuffer<Value, os_unfair_lock>

  // MARK: - Methods

  // MARK: Internal

  @discardableResult
  public func apply<R>(_ critical: (inout Value) throws -> R) rethrows -> R {
    try buffer.withUnsafeMutablePointers { header, lock in
      os_unfair_lock_lock(lock)
      defer { os_unfair_lock_unlock(lock) }
      return try critical(&header.pointee)
    }
  }

  public func get() -> Value {
    apply { $0 }
  }

  public func set(value: Value) {
    apply { current in
      current = value
    }
  }
}
