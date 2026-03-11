import Foundation

class EventQueue {
    private let lock = NSLock()
    private var queue: [Event] = []
    let capacity: Int

    init(capacity: Int) {
        self.capacity = capacity
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return queue.count
    }

    func offer(_ event: Event) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard queue.count < capacity else { return false }
        queue.append(event)
        return true
    }

    @discardableResult
    func removeOldest() -> Event? {
        lock.lock()
        defer { lock.unlock() }
        guard !queue.isEmpty else { return nil }
        return queue.removeFirst()
    }

    func drainAll() -> [Event] {
        lock.lock()
        defer { lock.unlock() }
        let events = queue
        queue.removeAll()
        return events
    }
}
