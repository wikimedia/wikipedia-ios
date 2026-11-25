import Foundation
import WMFData

#if DEBUG

/// A feed data controller whose fetches can be held, so that a test can change state while a fetch
/// is in flight and then let it finish. The first `holdCount` calls that `shouldHold` matches wait
/// until `releaseHeld()`. Every other call returns at once.
public actor WMFMockGatedFeedDataController: WMFFeedDataControlling {

    public struct Call: Sendable {
        public let project: WMFProject
        public let date: Date
    }

    private let response: WMFFeedAPIResponse
    private let shouldHold: @Sendable (WMFProject, Date) -> Bool
    private var remainingHolds: Int
    private var held: [CheckedContinuation<Void, Never>] = []
    public private(set) var calls: [Call] = []

    public var heldCount: Int { held.count }

    public init(response: WMFFeedAPIResponse, holdCount: Int = 1, shouldHold: @escaping @Sendable (WMFProject, Date) -> Bool) {
        self.response = response
        self.remainingHolds = holdCount
        self.shouldHold = shouldHold
    }

    public func fetchFeed(project: WMFProject, date: Date) async throws -> WMFFeedAPIResponse {
        calls.append(Call(project: project, date: date))
        if remainingHolds > 0, shouldHold(project, date) {
            remainingHolds -= 1
            await withCheckedContinuation { held.append($0) }
        }
        return response
    }

    public func releaseHeld() {
        let continuations = held
        held = []
        continuations.forEach { $0.resume() }
    }

    /// Waits until `count` fetches are held. Gives up after about a second, so a broken test
    /// fails instead of hanging the suite.
    public func waitUntilHeld(_ count: Int = 1) async -> Bool {
        for _ in 0..<1000 {
            if held.count >= count { return true }
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
        return held.count >= count
    }
}

#endif
