import Foundation

/// Bounds how many permanent-cache download requests are in flight for one group.
///
/// A group is an article. Saving a single article fans out into a mobile-html
/// request, one request per offline resource, one `imageinfo` call per image and one
/// download per image — previously all issued at once, from two `finishDBAdd` runs
/// sharing the same group key (`ArticleCacheDBWriter.add` kicks off
/// `imageController.add(urls:)` alongside its own requests). One throttle instance is
/// shared by the article and image controllers so a group's budget covers both.
///
/// Non-blocking by construction. On the article path `finishDBAdd` runs on the cache
/// managed object context's private queue, and the completion it would be waiting on
/// hops back onto that same context via `markDownloaded`, so a blocking wait here
/// would deadlock. All state is mutated inside `queue.async` and no caller ever waits.
final class CacheRequestThrottle {

    /// Requests in flight per group. Images share this budget with the metadata calls
    /// that are the actual rate-limit pressure, so setting it too low slows saving
    /// without reducing load on the throttled endpoints.
    static let defaultMaxConcurrentRequestsPerGroup = 6

    let maxConcurrentRequestsPerGroup: Int

    private let queue = DispatchQueue(label: "org.wikimedia.cache.throttle")
    private var inFlightByGroup: [CacheController.GroupKey: Int] = [:]
    private var pendingByGroup: [CacheController.GroupKey: [Work]] = [:]

    /// Work handed to the throttle. It is given a `done` block and must call it once
    /// its request has finished, whether it succeeded or failed.
    typealias Work = (@escaping () -> Void) -> Void

    init(maxConcurrentRequestsPerGroup: Int = CacheRequestThrottle.defaultMaxConcurrentRequestsPerGroup) {
        self.maxConcurrentRequestsPerGroup = max(1, maxConcurrentRequestsPerGroup)
    }

    /// Runs `work` as soon as a slot is free for `groupKey`, or immediately if one is.
    ///
    /// The `done` block `work` receives is safe to call from any thread and more than
    /// once — only the first call releases the slot. Success and failure arrive on
    /// different queues here, and a doubled release would let the group exceed its
    /// budget while a dropped one would leak a slot and stall the group for good.
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

    /// Number of requests currently in flight for a group. Test seam.
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
            // Hopping onto the queue is what makes `released` safe to read and write
            // from whichever thread the request completed on.
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

        // A later change will also need to drop this group's pending work on
        // cancellation; that is what keeping it in a per-group list buys.
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
