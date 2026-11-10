import Foundation
import WMFComponents

/// Feeds the Saved tab's download pill from the reading list sync state and the shared article
/// fetcher progress. While the first sync after sign-in runs, the pill shows with an empty bar.
/// When the sync ends, the bar fills with the download progress. The pill shows only after
/// `WMFMinProgressDurationBeforeShowingProgressUI`, so a short sync or download does not flash it.
@MainActor
final class SavedArticleDownloadProgressObserver {

    private let viewModel: WMFSavedProgressViewModel
    private let isInitialSyncPending: @MainActor () -> Bool
    private let isServerBusy: @MainActor () -> Bool
    private var progressObjectWasSetObservation: NSKeyValueObservation?
    private var progressObservation: NSKeyValueObservation?
    private var syncObservations: [NSObjectProtocol] = []
    private var showTask: Task<Void, Never>?

    private var syncIsPending = false
    private var downloadShouldShow = false
    private var downloadFractionCompleted: Double = 0

    /// - Parameters:
    ///   - isInitialSyncPending: True while the first sync after sign-in has not completed.
    ///   - isServerBusy: True while the server asked the app to wait. A sync that stops for this
    ///     reason runs again on its own, so the pill stays.
    init(viewModel: WMFSavedProgressViewModel, isInitialSyncPending: @escaping @MainActor () -> Bool = { false }, isServerBusy: @escaping @MainActor () -> Bool = { false }) {
        self.viewModel = viewModel
        self.isInitialSyncPending = isInitialSyncPending
        self.isServerBusy = isServerBusy
        syncIsPending = isInitialSyncPending()
        beginSyncObservations()
        beginProgressObservations()
    }

    deinit {
        for observation in syncObservations {
            NotificationCenter.default.removeObserver(observation)
        }
    }

    // MARK: - Reading list sync

    private func beginSyncObservations() {
        let center = NotificationCenter.default
        syncObservations.append(center.addObserver(forName: ReadingListsController.syncDidStartNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncDidStart()
            }
        })
        syncObservations.append(center.addObserver(forName: ReadingListsController.syncDidFinishNotification, object: nil, queue: .main) { [weak self] notification in
            let didFail = notification.userInfo?[ReadingListsController.syncDidFinishErrorKey] != nil
            Task { @MainActor [weak self] in
                self?.syncDidFinish(didFail: didFail)
            }
        })
    }

    private func syncDidStart() {
        syncIsPending = isInitialSyncPending()
        refresh()
    }

    /// A sync that fails for another reason than a busy server, for example without network, waits
    /// for the next sync. The pill hides until that sync starts.
    private func syncDidFinish(didFail: Bool) {
        syncIsPending = isInitialSyncPending() && (!didFail || isServerBusy())
        refresh()
    }

    // MARK: - Article downloads

    private func beginProgressObservations() {
        // A Progress is not reusable, so track each one the container publishes.
        progressObjectWasSetObservation = ProgressContainer.shared.observe(\ProgressContainer.articleFetcherProgress, options: [.new, .initial]) { [weak self] progressContainer, _ in
            let progress = progressContainer.articleFetcherProgress
            Task { @MainActor [weak self] in
                self?.track(progress)
            }
        }
    }

    private func track(_ progress: Progress?) {
        progressObservation?.invalidate()
        progressObservation = nil
        downloadShouldShow = false
        downloadFractionCompleted = 0
        refresh()

        guard let progress else {
            return
        }

        progressObservation = progress.observe(\Progress.fractionCompleted, options: [.new, .initial]) { [weak self] progress, _ in
            let shouldShow = progress.wmf_shouldShowProgressUI()
            let fractionCompleted = progress.fractionCompleted
            Task { @MainActor [weak self] in
                self?.downloadShouldShow = shouldShow
                self?.downloadFractionCompleted = fractionCompleted
                self?.refresh()
            }
        }
    }

    // MARK: - Pill state

    private func refresh() {
        // The download total grows while the sync creates the articles, so the fraction means nothing yet.
        viewModel.fractionCompleted = syncIsPending ? 0 : downloadFractionCompleted

        guard syncIsPending || downloadShouldShow else {
            hide()
            return
        }

        guard showTask == nil, !viewModel.isVisible else {
            return
        }

        showTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(WMFMinProgressDurationBeforeShowingProgressUI))
            guard !Task.isCancelled else {
                return
            }
            self?.viewModel.isVisible = true
            self?.showTask = nil
        }
    }

    private func hide() {
        showTask?.cancel()
        showTask = nil
        viewModel.isVisible = false
    }
}
