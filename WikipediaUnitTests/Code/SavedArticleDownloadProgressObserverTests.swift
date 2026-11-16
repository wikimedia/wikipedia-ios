import XCTest
@testable import Wikipedia
import WMFComponents

@MainActor
final class SavedArticleDownloadProgressObserverTests: XCTestCase {

    private var viewModel: WMFSavedProgressViewModel!
    private var observer: SavedArticleDownloadProgressObserver!
    private var initialSyncIsPending = false
    private var serverIsBusy = false

    override func setUp() async throws {
        ProgressContainer.shared.articleFetcherProgress = nil
        initialSyncIsPending = false
        serverIsBusy = false
        viewModel = WMFSavedProgressViewModel()
        observer = makeObserver()
    }

    override func tearDown() async throws {
        observer = nil
        ProgressContainer.shared.articleFetcherProgress = nil
    }

    /// Mirrors `SavedArticlesFetcher`: a fresh progress has `totalUnitCount == -1` until the
    /// first fetch starts.
    private func startBatch(of count: Int64) -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: -1)
        ProgressContainer.shared.articleFetcherProgress = progress
        progress.totalUnitCount = count
        progress.completedUnitCount = 0
        return progress
    }

    private func wait(seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    private func makeObserver() -> SavedArticleDownloadProgressObserver {
        SavedArticleDownloadProgressObserver(
            viewModel: viewModel,
            isInitialSyncPending: { [unowned self] in self.initialSyncIsPending },
            isServerBusy: { [unowned self] in self.serverIsBusy }
        )
    }

    private func postSyncDidStart() {
        NotificationCenter.default.post(name: ReadingListsController.syncDidStartNotification, object: nil)
    }

    private func postSyncDidFinish(error: Error? = nil) {
        var userInfo: [AnyHashable: Any] = [:]
        if let error {
            userInfo[ReadingListsController.syncDidFinishErrorKey] = error
        }
        NotificationCenter.default.post(name: ReadingListsController.syncDidFinishNotification, object: nil, userInfo: userInfo)
    }

    func testPillShowsOnlyAfterTheMinimumDuration() async {
        let progress = startBatch(of: 3)
        await wait(seconds: 0.5)
        XCTAssertFalse(viewModel.isVisible, "too early")

        await wait(seconds: WMFMinProgressDurationBeforeShowingProgressUI)
        XCTAssertTrue(viewModel.isVisible, "a download still running after the minimum duration shows the pill")

        progress.completedUnitCount = 2
        await wait(seconds: 0.1)
        XCTAssertEqual(viewModel.fractionCompleted, 2.0 / 3.0, accuracy: 0.001)
        XCTAssertTrue(viewModel.isVisible)

        progress.completedUnitCount = 3
        await wait(seconds: 0.1)
        XCTAssertFalse(viewModel.isVisible, "a finished download hides the pill")
    }

    func testPillStaysHiddenWhenTheDownloadFinishesEarly() async {
        let progress = startBatch(of: 1)
        await wait(seconds: 0.3)
        progress.completedUnitCount = 1
        await wait(seconds: WMFMinProgressDurationBeforeShowingProgressUI + 0.3)
        XCTAssertFalse(viewModel.isVisible)
    }

    func testANewProgressObjectHidesThePillAndRestartsTheClock() async {
        _ = startBatch(of: 2)
        await wait(seconds: WMFMinProgressDurationBeforeShowingProgressUI + 0.3)
        XCTAssertTrue(viewModel.isVisible)

        ProgressContainer.shared.articleFetcherProgress = Progress.discreteProgress(totalUnitCount: -1)
        await wait(seconds: 0.1)
        XCTAssertFalse(viewModel.isVisible, "the fetcher resets its progress when a batch ends")
    }

    // MARK: - First reading list sync

    func testPillShowsWithAnEmptyBarWhileTheFirstSyncRuns() async {
        initialSyncIsPending = true
        observer = makeObserver()
        await wait(seconds: 0.5)
        XCTAssertFalse(viewModel.isVisible, "too early")

        await wait(seconds: WMFMinProgressDurationBeforeShowingProgressUI)
        XCTAssertTrue(viewModel.isVisible, "a pending first sync shows the pill without a download")
        XCTAssertEqual(viewModel.fractionCompleted, 0)
    }

    func testBarStaysEmptyUntilTheFirstSyncEnds() async {
        initialSyncIsPending = true
        observer = makeObserver()
        let progress = startBatch(of: 4)
        progress.completedUnitCount = 2
        await wait(seconds: WMFMinProgressDurationBeforeShowingProgressUI + 0.3)
        XCTAssertTrue(viewModel.isVisible)
        XCTAssertEqual(viewModel.fractionCompleted, 0, "the total still grows while the sync creates articles")

        initialSyncIsPending = false
        postSyncDidFinish()
        await wait(seconds: 0.1)
        XCTAssertTrue(viewModel.isVisible, "the download keeps the pill")
        XCTAssertEqual(viewModel.fractionCompleted, 0.5, accuracy: 0.001)
    }

    func testPillHidesWhenTheFirstSyncEndsWithoutADownload() async {
        initialSyncIsPending = true
        observer = makeObserver()
        await wait(seconds: WMFMinProgressDurationBeforeShowingProgressUI + 0.3)
        XCTAssertTrue(viewModel.isVisible)

        initialSyncIsPending = false
        postSyncDidFinish()
        await wait(seconds: 0.1)
        XCTAssertFalse(viewModel.isVisible)
    }

    func testPillStaysWhenTheFirstSyncStopsForABusyServer() async {
        initialSyncIsPending = true
        serverIsBusy = true
        observer = makeObserver()
        await wait(seconds: WMFMinProgressDurationBeforeShowingProgressUI + 0.3)
        XCTAssertTrue(viewModel.isVisible)

        postSyncDidFinish(error: URLError(.unknown))
        await wait(seconds: 0.1)
        XCTAssertTrue(viewModel.isVisible, "the sync runs again on its own, so the pill stays")
    }

    func testPillHidesWhenTheFirstSyncFailsForAnotherReasonUntilTheNextSync() async {
        initialSyncIsPending = true
        observer = makeObserver()
        await wait(seconds: WMFMinProgressDurationBeforeShowingProgressUI + 0.3)
        XCTAssertTrue(viewModel.isVisible)

        postSyncDidFinish(error: URLError(.notConnectedToInternet))
        await wait(seconds: 0.1)
        XCTAssertFalse(viewModel.isVisible, "an offline sync waits for the next sync")

        postSyncDidStart()
        await wait(seconds: WMFMinProgressDurationBeforeShowingProgressUI + 0.3)
        XCTAssertTrue(viewModel.isVisible, "the next sync shows the pill again")
    }
}
