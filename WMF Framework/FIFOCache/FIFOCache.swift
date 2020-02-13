import Foundation

/// In-Memory cache
struct FIFOCache<Key: Equatable & Hashable> {
    // MARK: - Public properties

    /// Limit of keys enabled save to cache
    var limit: Int = 10 // TODO: Maybe in `didSet` remove keys and values when decrese this number

    // MARK: - Private properties

    /// Keys for currently stored values
    private var keys = [Key]()
    /// Cached values
    private var values = [Key: Any]()
    /// Semaphore for disable append or remove new values from 2 different threads in same time
    private let semaphore = DispatchSemaphore(value: 1)

    // MARK: - Public cache method

    /// Subscript for Read and Set new value or Remove value from Cache
    /// For set new value use `cahce["your_key"] = value`
    /// For read value use `value = cache["your_key"]`
    /// For remove value  use `cahce["your_key"] = nil`
    subscript<T>(key: Key) -> T? {
        get {
            defer { semaphore.signal() }
            semaphore.wait()

            return value(for: key)
        }
        set {
            defer { semaphore.signal() }
            semaphore.wait()

            guard let value = newValue else {
                remove(for: key)
                return
            }
            set(value: value, for: key)
        }
    }

    /// Clear `cache` remove all In-Memory stored values
    mutating func clear() {
        defer { semaphore.signal() }
        semaphore.wait()

        keys = []
        values = [:]
    }

    // MARK: - Private helpers for Cahce

    /// Add new value to cache.
    /// - Parameters:
    ///   - value: New value for store.
    ///   - key: Key to store value in In-Memory storage
    private mutating func set<T>(value: T, for key: Key) {
        keys.appendUniqe(key)
        values[key] = value

        if keys.count > limit, let firstKey = keys.first {
            values[firstKey] = nil
            keys.remove(at: 0) // Drop first key (FIFO)
        }
    }

    /// Fetter for stored values
    /// - Parameter key: Key for value in In-Memory storage
    private func value<T>(for key: Key) -> T? {
        return values[key] as? T
    }

    /// Remove value for key
    /// - Parameter key: Key for value in In-Memory storage
    private mutating func remove(for key: Key) {
        values[key] = nil
        keys.removeAll(key)
    }
}

// MARK: - Array helper extension

private extension Array where Iterator.Element: Equatable {
    /// Append element to array, if same element array in array will be removed and insert on end of array
    /// - Parameter newElement: New element for inset to array.
    mutating func appendUniqe(_ newElement: Element) {
        removeAll(newElement)
        append(newElement)
    }

    /// Remove all eqaul elements in array
    /// - Parameter element: Element for remove from array.
    mutating func removeAll(_ element: Element) {
        removeAll { $0 == element }
    }
}
