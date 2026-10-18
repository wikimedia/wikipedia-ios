import Foundation

/// A minimal lock-guarded box for mutable state on classes that must stay
/// `NSObject`-based (Obj-C visible singletons) and therefore cannot become actors.
/// Holding all mutable stored properties in `WMFLockIsolated` boxes is what makes
/// those classes' `@unchecked Sendable` conformances sound — every read/write is
/// serialized behind the lock. Keep accesses coarse: read once into a local,
/// compute, then write back, rather than many fine-grained hops.
final class WMFLockIsolated<Value>: @unchecked Sendable {

    private let lock = NSLock()
    private var _value: Value

    init(_ value: Value) {
        self._value = value
    }

    var value: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }

    /// Perform a read-modify-write (or any compound access) atomically.
    @discardableResult
    func withLock<T>(_ body: (inout Value) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body(&_value)
    }
}
