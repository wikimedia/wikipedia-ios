import Foundation
import Testing
@testable import WMF

/// A `PathMonitoring` that lets a test drive connectivity transitions directly,
/// standing in for one `NWPathMonitor`.
///
/// Like the real monitor, an instance is started at most once and is dead after
/// `cancel()`. The notifier creates a new one per session through the factory.
private final class FakePathMonitor: PathMonitoring {

    private(set) var isStarted = false
    private(set) var isCancelled = false

    /// The handler the notifier registered, kept so a test can fire it after cancel.
    private(set) var registeredHandler: (@Sendable (Bool) -> Void)?

    func start(onUpdate: @escaping @Sendable (Bool) -> Void) {
        isStarted = true
        registeredHandler = onUpdate
    }

    func cancel() {
        isCancelled = true
        registeredHandler = nil
    }

    /// Simulates the system reporting a new network path.
    func send(reachable: Bool) {
        registeredHandler?(reachable)
    }
}

/// Hands out `FakePathMonitor`s and records how many sessions were created.
private final class FakeMonitorFactory {

    private(set) var created: [FakePathMonitor] = []

    var createdCount: Int { created.count }
    var latest: FakePathMonitor? { created.last }

    func make() -> any PathMonitoring {
        let fake = FakePathMonitor()
        created.append(fake)
        return fake
    }
}

/// Collects the values the notifier delivers to its callback.
@MainActor
private final class CallbackRecorder {

    private(set) var values: [Bool] = []

    func record(_ value: Bool) {
        values.append(value)
    }

    /// Waits for at least `count` values, giving the notifier's main-actor hop a
    /// chance to run. Returns early on a deadline so a failure reports rather than hangs.
    func wait(forValueCount count: Int) async {
        let deadline = Date().addingTimeInterval(2)
        while values.count < count && Date() < deadline {
            await Task.yield()
        }
    }

    /// Lets any pending callback run, for asserting that nothing further is delivered.
    func drain() async {
        for _ in 0..<10 {
            await Task.yield()
        }
    }
}

@MainActor
struct ReachabilityNotifierTests {

    /// Builds a notifier wired to a fake factory and recorder.
    private func makeSUT() -> (ReachabilityNotifier, FakeMonitorFactory, CallbackRecorder) {
        let factory = FakeMonitorFactory()
        let recorder = CallbackRecorder()
        let notifier = ReachabilityNotifier(makeMonitor: { factory.make() }) { reachable in
            recorder.record(reachable)
        }
        return (notifier, factory, recorder)
    }

    // MARK: - Initial state

    @Test("Reachability is optimistic before monitoring starts, so nothing is gated on an unknown state")
    func isReachableIsTrueBeforeStart() {
        let (notifier, factory, _) = makeSUT()

        #expect(notifier.isReachable)
        #expect(factory.createdCount == 0)
    }

    @Test("Reachability stays optimistic between start and the first path update")
    func isReachableIsTrueAfterStartBeforeFirstUpdate() {
        let (notifier, factory, _) = makeSUT()

        notifier.start()

        // A caller reading `isReachable` right after `start()` — which several view
        // controllers do in `viewDidAppear` — must not see a false offline.
        #expect(notifier.isReachable)
        #expect(factory.createdCount == 1)
    }

    @Test("The first path update sets reachability, which previously never changed")
    func firstUpdateSetsIsReachable() async {
        let (notifier, factory, _) = makeSUT()

        notifier.start()
        factory.latest?.send(reachable: false)
        await Task.yield()

        #expect(notifier.isReachable == false)
    }

    // MARK: - Connectivity transitions

    @Test("The first update is delivered even when it matches the optimistic initial state")
    func firstUpdateIsAlwaysDelivered() async {
        let (notifier, factory, recorder) = makeSUT()

        notifier.start()
        factory.latest?.send(reachable: true)
        await recorder.wait(forValueCount: 1)

        #expect(recorder.values == [true])
    }

    @Test("Going offline and back online delivers each transition in order")
    func transitionsAreDelivered() async {
        let (notifier, factory, recorder) = makeSUT()

        notifier.start()
        let monitor = factory.latest

        monitor?.send(reachable: true)
        await recorder.wait(forValueCount: 1)

        monitor?.send(reachable: false)
        await recorder.wait(forValueCount: 2)
        #expect(notifier.isReachable == false)

        monitor?.send(reachable: true)
        await recorder.wait(forValueCount: 3)
        #expect(notifier.isReachable)

        #expect(recorder.values == [true, false, true])
    }

    @Test("Repeated updates with the same state are not redelivered")
    func unchangedUpdatesAreNotRedelivered() async {
        let (notifier, factory, recorder) = makeSUT()

        notifier.start()
        let monitor = factory.latest

        monitor?.send(reachable: false)
        await recorder.wait(forValueCount: 1)

        // An interface change that does not change connectivity — Wi-Fi to cellular,
        // for example — must not re-trigger the caller's offline/online handling.
        monitor?.send(reachable: false)
        monitor?.send(reachable: false)
        await recorder.drain()

        #expect(recorder.values == [false])
    }

    // MARK: - Monitor lifecycle

    @Test("Starting twice creates one monitor")
    func startIsIdempotent() {
        let (notifier, factory, _) = makeSUT()

        notifier.start()
        notifier.start()

        #expect(factory.createdCount == 1)
    }

    @Test("Stopping cancels the monitor")
    func stopCancelsMonitor() {
        let (notifier, factory, _) = makeSUT()

        notifier.start()
        notifier.stop()

        #expect(factory.latest?.isCancelled == true)
    }

    @Test("Stopping without starting does nothing")
    func stopWithoutStartDoesNothing() {
        let (notifier, factory, _) = makeSUT()

        notifier.stop()

        #expect(factory.createdCount == 0)
    }

    @Test("Restarting builds a fresh monitor, because a cancelled one cannot be reused")
    func restartCreatesNewMonitor() async {
        let (notifier, factory, recorder) = makeSUT()

        notifier.start()
        let first = factory.latest
        notifier.stop()
        notifier.start()
        let second = factory.latest

        #expect(factory.createdCount == 2)
        #expect(first !== second)
        #expect(first?.isCancelled == true)
        #expect(second?.isCancelled == false)
        #expect(second?.isStarted == true)

        second?.send(reachable: false)
        await recorder.wait(forValueCount: 1)
        #expect(recorder.values == [false])
    }

    @Test("Restarting returns reachability to optimistic rather than reusing a stale state")
    func restartDoesNotReuseStaleState() async {
        let (notifier, factory, _) = makeSUT()

        notifier.start()
        factory.latest?.send(reachable: false)
        await Task.yield()
        notifier.stop()

        // Connectivity may have changed while monitoring was stopped, so the old state
        // must not be reported to a caller reading `isReachable` on the next appearance.
        notifier.start()
        #expect(notifier.isReachable)

        factory.latest?.send(reachable: false)
        await Task.yield()
        #expect(notifier.isReachable == false)
    }

    @Test("Updates sent after stop are ignored")
    func updatesAfterStopAreIgnored() async {
        let (notifier, factory, recorder) = makeSUT()

        notifier.start()
        let monitor = factory.latest
        monitor?.send(reachable: true)
        await recorder.wait(forValueCount: 1)

        notifier.stop()
        monitor?.send(reachable: false)
        await recorder.drain()

        #expect(recorder.values == [true])
    }

    @Test("A callback already queued when stop() runs is not delivered")
    func queuedCallbackIsDroppedWhenStoppedBeforeDelivery() async {
        let (notifier, factory, recorder) = makeSUT()

        notifier.start()

        // `send` returns once the update has been handed to the notifier but before the
        // main-actor hop has run, so stopping here races exactly the way a view
        // controller disappearing mid-update does.
        factory.latest?.send(reachable: false)
        notifier.stop()
        await recorder.drain()

        #expect(recorder.values.isEmpty)
    }

    @Test("An update in flight from the previous monitor is not credited to the new one")
    func inFlightUpdateFromPreviousMonitorIsRejected() async {
        let (notifier, factory, recorder) = makeSUT()

        notifier.start()
        let first = factory.latest
        // Capture the handler the first session registered, before it is cancelled.
        let staleHandler = first?.registeredHandler

        notifier.stop()
        notifier.start()

        // The first monitor fires an update that was already on its way when it was
        // cancelled. It carries the previous generation, so it must be discarded even
        // though a session is active again.
        if let staleHandler {
            staleHandler(false)
        }
        await recorder.drain()

        #expect(recorder.values.isEmpty)
        #expect(notifier.isReachable)

        // The current session still reports normally.
        factory.latest?.send(reachable: false)
        await recorder.wait(forValueCount: 1)
        #expect(recorder.values == [false])
    }

    @Test("Releasing the notifier cancels the monitor")
    func deinitCancelsMonitor() async {
        let factory = FakeMonitorFactory()

        var notifier: ReachabilityNotifier? = ReachabilityNotifier(makeMonitor: { factory.make() }) { _ in }
        notifier?.start()
        #expect(factory.latest?.isCancelled == false)

        notifier = nil

        // `isolated deinit` hops to the main actor, so the cancel may land after this
        // statement rather than during it.
        let deadline = Date().addingTimeInterval(2)
        while factory.latest?.isCancelled == false && Date() < deadline {
            await Task.yield()
        }

        #expect(factory.latest?.isCancelled == true)
    }
}

/// Covers the real `NWPathMonitor`-backed adapter.
@MainActor
struct NWPathMonitorAdapterTests {

    @Test("A real monitor reports a state on start and stops reporting after cancel")
    func realMonitorStartsAndCancels() async {
        let adapter = NWPathMonitorAdapter()
        let received = Box<Bool?>(nil)

        adapter.start { reachable in
            received.value = reachable
        }

        // `NWPathMonitor` calls its update handler with the current path on start, so a
        // value arrives without waiting for a connectivity change.
        let deadline = Date().addingTimeInterval(5)
        while received.value == nil && Date() < deadline {
            await Task.yield()
        }

        #expect(received.value != nil)

        adapter.cancel()
        received.value = nil
        await Task.yield()

        #expect(received.value == nil)
    }
}

/// Minimal thread-safe box for observing a value written from the monitor's queue.
private final class Box<Value>: @unchecked Sendable {

    private let lock = NSLock()
    private var _value: Value

    init(_ value: Value) {
        self._value = value
    }

    var value: Value {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
}
