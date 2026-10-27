import XCTest
@testable import Wikipedia
import WMFComponents

@MainActor
final class SavedArticleDownloadProgressObserverTests: XCTestCase {

    private var viewModel: WMFSavedProgressViewModel!
    private var observer: SavedArticleDownloadProgressObserver!

    override func setUp() async throws {
        ProgressContainer.shared.articleFetcherProgress = nil
        viewModel = WMFSavedProgressViewModel()
        observer = SavedArticleDownloadProgressObserver(viewModel: viewModel)
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
}
