import XCTest
@testable import WMF

final class WMFAuthenticationManagerTests: XCTestCase {

    func testTemporaryAccountUsernameStartsWithTilde() {
        XCTAssertTrue(WMFAuthenticationManager.isTemporaryAccountUsername("~2026-12345-6"))
    }

    func testPermanentUsernameIsNotTemporary() {
        // A permanent username left in the centralauth_User cookie by an unfinished logout (T430460)
        XCTAssertFalse(WMFAuthenticationManager.isTemporaryAccountUsername("Reedy"))
        XCTAssertFalse(WMFAuthenticationManager.isTemporaryAccountUsername("User~WithTildeInside"))
        XCTAssertFalse(WMFAuthenticationManager.isTemporaryAccountUsername(""))
    }

    func testLoggedOutAlertShowsAfterLogoutWhileLoggedOut() {
        XCTAssertTrue(WMFAuthenticationManager.shouldShowLoggedOutAlert(isUserUnawareOfLogout: true, isPermanentAccountLoggedIn: false))
    }

    func testLoggedOutAlertIsSkippedOnceLoggedInAgain() {
        // The alert was dismissed by a link, then the user logged in from Settings.
        XCTAssertFalse(WMFAuthenticationManager.shouldShowLoggedOutAlert(isUserUnawareOfLogout: true, isPermanentAccountLoggedIn: true))
    }

    func testLoggedOutAlertNeedsAnUnacknowledgedLogout() {
        XCTAssertFalse(WMFAuthenticationManager.shouldShowLoggedOutAlert(isUserUnawareOfLogout: false, isPermanentAccountLoggedIn: false))
        XCTAssertFalse(WMFAuthenticationManager.shouldShowLoggedOutAlert(isUserUnawareOfLogout: false, isPermanentAccountLoggedIn: true))
    }
}

/// The user fetch that the Year in Review report build waits for: one request for each host, the
/// reset rule and the timeout.
@MainActor
final class WMFAuthenticationManagerUserFetchTests: XCTestCase {

    private let siteURL = URL(string: "https://en.wikipedia.org")!
    private let host = "en.wikipedia.org"
    private var fetcher: StubCurrentUserFetcher!
    private var manager: WMFAuthenticationManager!

    override func setUp() async throws {
        let session = Session(configuration: .current)
        fetcher = StubCurrentUserFetcher(session: session, configuration: .current)
        manager = WMFAuthenticationManager(session: session, configuration: .current, currentUserFetcher: fetcher)
    }

    override func tearDown() async throws {
        // Never leave a fetch suspended.
        fetcher.releaseAll(nil)
    }

    func testTwoCallersShareOneRequest() async {
        let first = Task { await manager.fetchUserIntoCache(siteURL: siteURL, host: host) }
        let second = Task { await manager.fetchUserIntoCache(siteURL: siteURL, host: host) }
        await waitUntil { self.fetcher.pendingCount == 1 }
        await yieldToMainActor()

        fetcher.releaseOldest(user(named: "Reader"))
        await first.value
        await second.value

        XCTAssertEqual(fetcher.fetchCount, 1)
        XCTAssertEqual(manager.permanentUser(siteURL: siteURL)?.name, "Reader")
    }

    func testAResetDuringTheFetchDropsTheUser() async {
        let fetch = Task { await manager.fetchUserIntoCache(siteURL: siteURL, host: host) }
        await waitUntil { self.fetcher.pendingCount == 1 }

        manager.resetUserCache()
        fetcher.releaseOldest(user(named: "Logged out"))
        await fetch.value

        XCTAssertNil(manager.user(siteURL: siteURL))
    }

    /// A caller after a reset must not join the fetch of the old generation: that fetch caches
    /// nothing, so the caller would get no user.
    func testACallerAfterAResetStartsANewFetch() async {
        let oldFetch = Task { await manager.fetchUserIntoCache(siteURL: siteURL, host: host) }
        await waitUntil { self.fetcher.pendingCount == 1 }

        manager.resetUserCache()
        let newFetch = Task { await manager.fetchUserIntoCache(siteURL: siteURL, host: host) }
        await waitUntil { self.fetcher.pendingCount == 2 }

        fetcher.releaseOldest(user(named: "Logged out"))
        await oldFetch.value
        XCTAssertNil(manager.user(siteURL: siteURL))

        fetcher.releaseOldest(user(named: "Logged in again"))
        await newFetch.value
        XCTAssertEqual(fetcher.fetchCount, 2)
        XCTAssertEqual(manager.permanentUser(siteURL: siteURL)?.name, "Logged in again")
    }

    func testASlowFetchTimesOutWithoutTheUserAndReportsWhenItFinishes() async {
        let finishedLate = expectation(description: "the fetch finished after the timeout")
        let finishedInTime = await manager.fetchUserIntoCache(siteURL: siteURL, host: host, timeout: .milliseconds(50)) {
            finishedLate.fulfill()
        }

        XCTAssertFalse(finishedInTime)
        XCTAssertNil(manager.permanentUser(siteURL: siteURL), "the caller goes on without the user")

        fetcher.releaseOldest(user(named: "Reader"))
        await fulfillment(of: [finishedLate], timeout: 2)
        XCTAssertEqual(manager.permanentUser(siteURL: siteURL)?.name, "Reader", "the fetch keeps going and fills the cache")
    }

    func testAFetchThatFinishesInTimeDoesNotReportLate() async {
        let finishedLate = expectation(description: "the fetch finished after the timeout")
        finishedLate.isInverted = true
        let fetch = Task {
            await manager.fetchUserIntoCache(siteURL: siteURL, host: host, timeout: .seconds(10)) {
                finishedLate.fulfill()
            }
        }
        await waitUntil { self.fetcher.pendingCount == 1 }

        fetcher.releaseOldest(user(named: "Reader"))
        let finishedInTime = await fetch.value

        XCTAssertTrue(finishedInTime)
        XCTAssertEqual(manager.permanentUser(siteURL: siteURL)?.name, "Reader")
        await fulfillment(of: [finishedLate], timeout: 0.2)
    }

    // MARK: - Helpers

    private func user(named name: String) -> WMFCurrentUser {
        WMFCurrentUser(userID: 1, globalUserID: 2, name: name, groups: [], editCount: 0, isBlocked: false, isIP: false, isTemp: false, registrationDateString: nil)
    }

    /// Lets the tasks that are queued on the main actor run.
    private func yieldToMainActor() async {
        for _ in 0..<20 {
            await Task.yield()
        }
    }

    private func waitUntil(_ condition: @MainActor () -> Bool, file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0..<200 {
            if condition() {
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("The condition did not become true", file: file, line: line)
    }
}

/// Holds each fetch until the test releases it.
private final class StubCurrentUserFetcher: WMFCurrentUserFetcher, @unchecked Sendable {
    // Read and written on the main actor only.
    @MainActor private(set) var fetchCount = 0
    @MainActor private var pending: [CheckedContinuation<WMFCurrentUser?, Never>] = []

    @MainActor var pendingCount: Int {
        pending.count
    }

    override func fetch(siteURL: URL) async throws -> WMFCurrentUser {
        guard let user = await waitForRelease() else {
            throw WMFUserFetcherError.cannotExtractUserInfo
        }
        return user
    }

    @MainActor private func waitForRelease() async -> WMFCurrentUser? {
        fetchCount += 1
        return await withCheckedContinuation { pending.append($0) }
    }

    /// Ends the oldest fetch with `user`, or with an error when `user` is `nil`.
    @MainActor func releaseOldest(_ user: WMFCurrentUser?) {
        guard !pending.isEmpty else {
            return
        }
        pending.removeFirst().resume(returning: user)
    }

    @MainActor func releaseAll(_ user: WMFCurrentUser?) {
        while !pending.isEmpty {
            releaseOldest(user)
        }
    }
}
