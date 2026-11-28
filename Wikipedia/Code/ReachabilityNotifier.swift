import Foundation
import Network

/// One monitoring session: the part of `NWPathMonitor` that `ReachabilityNotifier` uses.
///
/// An instance is started at most once and is not reused after `cancel()`, mirroring
/// `NWPathMonitor`, whose `cancel()` is terminal. Tests substitute their own instance
/// through `ReachabilityNotifier`'s monitor factory.
///
/// Instances are created, started and cancelled entirely on the main actor, so this is
/// deliberately not `Sendable`. Only `onUpdate` crosses to another thread.
protocol PathMonitoring: AnyObject {

    /// Begins delivering connectivity updates.
    ///
    /// `onUpdate` is called once with the current state shortly after this call, and
    /// again every time that state changes. It may be called on any thread.
    func start(onUpdate: @escaping @Sendable (Bool) -> Void)

    /// Stops delivery permanently.
    func cancel()
}

/// A `PathMonitoring` backed by one `NWPathMonitor`.
final class NWPathMonitorAdapter: PathMonitoring {

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "org.wikimedia.reachability.path-monitor")

    func start(onUpdate: @escaping @Sendable (Bool) -> Void) {
        monitor.pathUpdateHandler = { path in
            onUpdate(Self.isReachable(path))
        }

        // `NWPathMonitor` calls the update handler with the current path when it is
        // started, so `onUpdate` always fires once without waiting for a change.
        monitor.start(queue: queue)
    }

    func cancel() {
        monitor.cancel()
    }

    private static func isReachable(_ path: NWPath) -> Bool {
        switch path.status {
        case .satisfied:
            return true
        case .requiresConnection:
            // There is no usable route yet, but attempting a connection brings one up
            // (an on-demand VPN, for example), so requests are still expected to work.
            return true
        case .unsatisfied:
            return false
        @unknown default:
            // Stay optimistic, so that an unrecognized status never makes the app
            // claim to be offline.
            return true
        }
    }
}

/// Observes whether the device has a usable route to the network and reports changes.
///
/// `isReachable` is a hint for user-facing state — offline toasts, offline empty
/// states — and nothing more. It must not be used to decide whether to send a request:
/// connectivity can change between the check and the request, and the check can be
/// wrong in both directions. Always attempt the request and handle the error instead.
@MainActor
public final class ReachabilityNotifier {

    private let makeMonitor: () -> any PathMonitoring
    private let callback: (Bool) -> Void

    private var monitor: (any PathMonitoring)?

    /// Bumped by every `start()` and `stop()`. Each monitor's update closure captures
    /// the value from when it was registered, so an update still in flight from a
    /// previous monitor cannot be mistaken for one from the current session.
    private var generation: UInt64 = 0

    private var hasReceivedUpdate = false

    /// Whether the device currently has a usable route to the network.
    ///
    /// This is optimistically `true` from every `start()` until that session's first
    /// update arrives, so reading it right after `start()` reports neither a false
    /// offline nor a state left over from before the last `stop()`.
    public private(set) var isReachable: Bool = true

    /// - Parameter callback: Called with the new connectivity state, once after each
    ///   `start()` and thereafter only when the state actually changes.
    public convenience init(callback: @escaping (Bool) -> Void) {
        self.init(makeMonitor: { NWPathMonitorAdapter() }, callback: callback)
    }

    /// - Parameters:
    ///   - makeMonitor: Creates the monitor for a session. Called once per `start()`,
    ///     because a cancelled monitor cannot be restarted. Injectable for testing.
    ///   - callback: Called with the new connectivity state, once after each `start()`
    ///     and thereafter only when the state actually changes.
    init(
        makeMonitor: @escaping () -> any PathMonitoring,
        callback: @escaping (Bool) -> Void
    ) {
        self.makeMonitor = makeMonitor
        self.callback = callback
    }

    isolated deinit {
        monitor?.cancel()
    }

    /// Begins monitoring. Does nothing if already monitoring.
    public func start() {
        guard monitor == nil else {
            return
        }

        generation &+= 1
        hasReceivedUpdate = false
        isReachable = true

        let generation = self.generation
        let monitor = makeMonitor()
        self.monitor = monitor

        monitor.start { [weak self] reachable in
            Task { @MainActor in
                self?.handle(reachable, generation: generation)
            }
        }
    }

    /// Stops monitoring. Does nothing if not monitoring.
    public func stop() {
        guard let monitor else {
            return
        }

        self.monitor = nil
        generation &+= 1
        monitor.cancel()
    }

    private func handle(_ reachable: Bool, generation: UInt64) {
        // The session this update belongs to has been stopped, or stopped and started
        // again, while the update was on its way to the main actor.
        guard generation == self.generation, monitor != nil else {
            return
        }

        let isFirstUpdate = !hasReceivedUpdate
        let didChange = isReachable != reachable
        hasReceivedUpdate = true
        isReachable = reachable

        guard isFirstUpdate || didChange else {
            return
        }

        callback(reachable)
    }
}
