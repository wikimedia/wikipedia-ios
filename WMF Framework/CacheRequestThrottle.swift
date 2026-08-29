import Foundation

/// Bounds how many permanent-cache download requests are in flight for one group (an article).
///
/// Non-blocking by design: finishDBAdd runs on the cache moc's private queue and the completion it would
/// wait on hops back onto that same context via markDownloaded, so a blocking wait here would deadlock.
final class CacheRequestThrottle {

    static let defaultMaxConcurrentRequestsPerGroup = 6

    let maxConcurrentRequestsPerGroup: Int

    private let queue = DispatchQueue(label: "org.wikimedia.cache.throttle")
    private var inFlightByGroup: [CacheController.GroupKey: Int] = [:]
    private var pendingByGroup: [CacheController.GroupKey: [Work]] = [:]

    /// Work given a `done` block, which it must call once its request has finished.
    typealias Work = (@escaping () -> Void) -> Void

    init(maxConcurrentRequestsPerGroup: Int = CacheRequestThrottle.defaultMaxConcurrentRequestsPerGroup) {
        self.maxConcurrentRequestsPerGroup = max(1, maxConcurrentRequestsPerGroup)
    }

    /// Runs `work` as soon as a slot is free for `groupKey`. Its `done` block is safe to call
    /// from any thread and more than once - only the first call releases the slot.
    func enqueue(groupKey: CacheController.GroupKey, work: @escaping Work) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            guard self.inFlightByGroup[groupKey, default: 0] < self.maxConcurrentRequestsPerGroup else {
                self.pendingByGroup[groupKey, default: []].append(work)
                return
            }

            self.startOnQueue(groupKey: groupKey, work: work)
        }
    }

    // test seam
    func inFlightCount(for groupKey: CacheController.GroupKey) -> Int {
        queue.sync { inFlightByGroup[groupKey] ?? 0 }
    }

    // MARK: - Private, all called on `queue`

    private func startOnQueue(groupKey: CacheController.GroupKey, work: @escaping Work) {
        inFlightByGroup[groupKey, default: 0] += 1
        work(makeDoneBlock(for: groupKey))
    }

    private func makeDoneBlock(for groupKey: CacheController.GroupKey) -> () -> Void {
        var released = false
        return { [weak self] in
            guard let self = self else {
                return
            }
            // note, hopping onto the queue is what makes `released` safe from whichever thread completed
            self.queue.async {
                guard !released else {
                    return
                }
                released = true
                self.releaseSlotOnQueue(groupKey: groupKey)
            }
        }
    }

    private func releaseSlotOnQueue(groupKey: CacheController.GroupKey) {
        inFlightByGroup[groupKey] = max(0, (inFlightByGroup[groupKey] ?? 0) - 1)

        if var pending = pendingByGroup[groupKey], !pending.isEmpty {
            let next = pending.removeFirst()
            pendingByGroup[groupKey] = pending.isEmpty ? nil : pending
            startOnQueue(groupKey: groupKey, work: next)
            return
        }

        pendingByGroup[groupKey] = nil
        if inFlightByGroup[groupKey] == 0 {
            inFlightByGroup[groupKey] = nil
        }
    }
}
